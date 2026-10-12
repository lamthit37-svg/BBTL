// Giữ các gói shader đã nạp và nạp lại khi tệp nguồn đổi.
// Gói do chính Library ghi ra không tính là thay đổi của nguồn.
// Watcher đứng cuối State để bị hủy trước, lúc signal còn sống.
#include "shader/library.hpp"

#include "core/log.hpp"
#include "fs/disk.hpp"
#include "fs/path.hpp"
#include "fs/watcher.hpp"
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

// Thư mục cần theo dõi: thư mục của danh sách, cộng mỗi thư mục include không nằm trong nó
// (Watcher đã theo dõi cả thư mục con).
[[nodiscard]] std::vector<std::string> watch_roots(const Manifest& manifest) {
    std::vector<std::string> roots{manifest.directory};
    for (const std::string& directory : manifest.include_dirs) {
        const bool covered = directory.starts_with(manifest.directory);
        const bool known = std::ranges::find(roots, directory) != roots.end();
        if (!covered && !known) roots.push_back(directory);
    }
    return roots;
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

void reload_manifest(Reload& reload) {
    Result<Manifest> manifest = Manifest::load(reload.manifest_path);
    if (!manifest) core::error("Danh sách shader không đọc lại được: {}", manifest.error());
    if (manifest) reload.manifest = std::move(*manifest);
}

// Dịch lại spec nếu đã cũ; gói mới đọc từ đĩa, đúng thứ lần chạy sau sẽ đọc. nullptr khi gói còn
// mới hoặc dịch hỏng.
[[nodiscard]] std::shared_ptr<const Package> rebuild(const Reload& reload, const ShaderSpec& spec) {
    if (is_fresh(reload.compiler, reload.manifest, spec, reload.options)) return nullptr;
    BuildOptions options = reload.options;
    options.force = true;
    const BuildResult result = build_shader(reload.compiler, reload.manifest, spec, options);
    if (result.outcome != Outcome::kBuilt) {
        core::error("Shader {} không dịch lại được: {}", spec.name, result.messages);
        return nullptr;
    }
    Result<Package> package = Package::load(package_path(options.output, spec.name));
    if (!package) core::error("Gói shader {} không đọc lại được: {}", spec.name, package.error());
    if (!package) return nullptr;
    return std::make_shared<const Package>(std::move(*package));
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
    std::vector<fs::Watcher> watchers;
    for (const std::string& root : watch_roots(*manifest)) {
        const auto raise = [signal](std::string_view path, fs::Change) {
            if (!is_package(path)) signal->raise(Clock::now());
        };
        const fs::Change events = fs::Change::kModified | fs::Change::kCreated | fs::Change::kDeleted;
        Result<fs::Watcher> watcher = fs::Watcher::start(root, events, raise);
        if (!watcher) return pass(watcher);
        watchers.push_back(std::move(*watcher));
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
    std::vector<std::string> changed;
    for (const ShaderSpec& spec : state.reload->manifest.shaders) {
        std::shared_ptr<const Package> package = rebuild(*state.reload, spec);
        if (package == nullptr) continue;
        state.packages.insert_or_assign(spec.name, std::move(package));
        changed.push_back(spec.name);
    }
    return changed;
}

} // namespace game::shader
