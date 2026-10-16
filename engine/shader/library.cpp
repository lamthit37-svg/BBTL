/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/shader/library.cpp
 *  PHÂN HỆ   : Shader / Library
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Giữ các gói shader đã nạp và nạp lại khi tệp nguồn đổi. Gói do chính
 *    Library ghi ra không tính là thay đổi của nguồn. Watcher đứng cuối State
 *    để bị hủy trước, lúc signal còn sống.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "shader/library.hpp"

#include "core/log.hpp"
#include "fs/disk.hpp"
#include "fs/path.hpp"
#include "fs/watcher.hpp"
#include "shader/detail/roots.hpp"
#include "shader/failure.hpp"

#include <algorithm>
#include <map>
#include <mutex>
#include <optional>
#include <utility>

namespace game::shader {

namespace {

using Clock = std::chrono::steady_clock;

// Cờ "nguồn đã đổi". Luồng theo dõi tệp gọi raise, luồng của Library gọi take.
class Signal {
public:
    void raise(Clock::time_point when) {
        const std::scoped_lock lock(mutex_);
        dirty_ = true;
        changed_at_ = when;
    }

    // true đúng một lần cho mỗi đợt thay đổi, khi đợt ấy đã yên settle.
    [[nodiscard]] bool take(std::chrono::milliseconds settle) {
        const std::scoped_lock lock(mutex_);
        const bool settled = dirty_ && Clock::now() - changed_at_ >= settle;
        if (settled) dirty_ = false;
        return settled;
    }

private:
    // Bảo vệ dirty_ và changed_at_.
    std::mutex mutex_;
    bool dirty_ = false;
    Clock::time_point changed_at_{};
};

// Phần chỉ có khi nạp nóng đang bật.
struct Reload {
    std::string manifest_path{};
    Manifest manifest{};
    Compiler compiler;
    BuildOptions options{};
};

// Gói do chính Library ghi ra không phải thay đổi của nguồn.
[[nodiscard]] bool is_package(std::string_view path) noexcept {
    return fs::extension(path) == kPackageExtension;
}

// Tên gói thành tên tệp. Dấu phân cách hay ".." thoát khỏi thư mục gói qua package_path.
[[nodiscard]] bool is_package_file_name(std::string_view name) noexcept {
    if (name.empty() || name.contains("..")) return false;
    const auto escapes = [](char unit) noexcept { return unit == '/' || unit == '\\' || unit == ':'; };
    return std::ranges::none_of(name, escapes);
}

void note_source(Signal* signal, std::string_view path) {
    if (is_package(path)) return;
    signal->raise(Clock::now());
}

[[nodiscard]] fs::Watcher::Callback on_source(Signal* signal) {
    return [signal](std::string_view path, fs::Change) { note_source(signal, path); };
}

[[nodiscard]] Status start_root(std::vector<fs::Watcher>& watchers, const std::string& root, Signal* signal,
    fs::Change events) {
    Result<fs::Watcher> watcher = fs::Watcher::start(root, events, on_source(signal));
    if (!watcher) return pass(watcher);
    watchers.push_back(std::move(*watcher));
    return ok();
}

} // namespace

struct Library::State {
    std::string directory{};
    std::map<std::string, std::shared_ptr<const Package>, std::less<>> packages{};
    std::optional<Reload> reload{};
    Signal signal{};
    // Khai sau cùng để huỷ trước tiên: luồng theo dõi dừng rồi signal mới biến mất.
    std::vector<fs::Watcher> watchers{};
};

namespace {

// Đọc hỏng thì giữ danh sách đang dùng: một lần ghi dở của trình soạn không xoá shader đang chạy.
void reload_manifest(Reload& reload) {
    Result<Manifest> manifest = Manifest::load(reload.manifest_path);
    if (!manifest) {
        core::error("Danh sách shader không đọc lại được: {}", manifest.error());
        return;
    }
    reload.manifest = std::move(*manifest);
}

[[nodiscard]] std::shared_ptr<const Package> load_built(std::string_view output, std::string_view name) {
    Result<Package> package = Package::load(package_path(output, name));
    if (!package) {
        core::error("Gói shader {} không đọc lại được: {}", name, package.error());
        return nullptr;
    }
    return std::make_shared<const Package>(std::move(*package));
}

// nullptr khi gói còn mới hoặc dịch hỏng. is_fresh xem options gốc; forced.force đã bật để
// build_shader không đọc gói thêm một lần nữa.
[[nodiscard]] std::shared_ptr<const Package> rebuild(const Reload& reload, const BuildOptions& forced,
    const ShaderSpec& spec) {
    if (is_fresh(reload.compiler, reload.manifest, spec, reload.options)) return nullptr;
    const BuildResult result = build_shader(reload.compiler, reload.manifest, spec, forced);
    if (result.outcome == Outcome::kBuilt) return load_built(forced.output, spec.name);
    core::error("Shader {} không dịch lại được: {}", spec.name, result.messages);
    return nullptr;
}

} // namespace

Library::Library(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}
Library::Library(Library&&) noexcept = default;
Library& Library::operator=(Library&&) noexcept = default;
Library::~Library() = default;

Result<Library> Library::open(std::string_view directory) {
    if (!fs::is_directory(directory)) {
        return fail(ErrorCode::kNotFound, "không có thư mục gói shader", directory);
    }
    auto state = std::make_unique<State>();
    state->directory = fs::normalize(directory);
    return Library(std::move(state));
}

Result<std::shared_ptr<const Package>> Library::get(std::string_view name) {
    const auto found = state_->packages.find(name);
    if (found != state_->packages.end()) return found->second;
    if (!is_package_file_name(name)) return fail(ErrorCode::kInvalidArgument, "tên gói sai", name);
    Result<Package> package = Package::load(package_path(state_->directory, name));
    if (!package) return pass(package);
    auto shared = std::make_shared<const Package>(std::move(*package));
    state_->packages.emplace(std::string(name), shared);
    return shared;
}

Result<std::string> Library::install(fs::Bytes bytes) {
    Result<Package> package = Package::parse(std::move(bytes));
    if (!package) return pass(package);
    std::string name(package->name());
    auto shared = std::make_shared<const Package>(std::move(*package));
    state_->packages.insert_or_assign(name, std::move(shared));
    return name;
}

Status Library::watch(std::string_view manifest_path, Compiler compiler, BuildOptions options) {
    Result<Manifest> manifest = Manifest::load(manifest_path);
    if (!manifest) return pass(manifest);
    options.output = state_->directory;
    Signal* signal = &state_->signal;
    const std::vector<std::string> roots = detail::watch_roots(*manifest);
    std::vector<fs::Watcher> watchers;
    watchers.reserve(roots.size());
    const fs::Change events = fs::Change::kModified | fs::Change::kCreated | fs::Change::kDeleted;
    for (const std::string& root : roots) {
        if (Status started = start_root(watchers, root, signal, events); !started) return started;
    }
    state_->watchers = std::move(watchers);
    state_->reload.emplace(std::string(manifest_path), std::move(*manifest), std::move(compiler), std::move(options));
    // Mốc xa trong quá khứ: lần refresh đầu chạy ngay, không chờ kSettle.
    signal->raise(Clock::time_point{});
    return ok();
}

bool Library::watching() const noexcept {
    return state_->reload.has_value();
}

std::vector<std::string> Library::refresh() {
    State& state = *state_;
    if (!state.reload || !state.signal.take(kSettle)) return {};
    reload_manifest(*state.reload);
    BuildOptions forced = state.reload->options;
    forced.force = true;
    std::vector<std::string> changed;
    changed.reserve(state.reload->manifest.shaders.size());
    for (const ShaderSpec& spec : state.reload->manifest.shaders) {
        std::shared_ptr<const Package> package = rebuild(*state.reload, forced, spec);
        if (!package) continue;
        state.packages.insert_or_assign(spec.name, std::move(package));
        changed.push_back(spec.name);
    }
    return changed;
}

} // namespace game::shader
