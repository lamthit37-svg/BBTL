// Đọc tệp cấu hình từ đĩa rồi giao chữ cho module config. Tệp là dữ liệu ngoài: tệp thiếu, tệp
// hỏng, khoá lạ đều thành dòng lỗi `tệp:dòng: câu`, gom đủ rồi mới trả về.
#include "service/detail/load.hpp"

#include "config/admin.hpp"
#include "config/auth.hpp"
#include "config/billing.hpp"
#include "config/cluster.hpp"
#include "config/gate.hpp"
#include "config/issue.hpp"
#include "config/log.hpp"
#include "config/startup.hpp"
#include "config/store.hpp"
#include "config/supervisor.hpp"
#include "config/types.hpp"
#include "config/world.hpp"
#include "config/zone.hpp"
#include "io/file.hpp"
#include "service/detail/request.hpp"
#include "service/service.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <filesystem>
#include <format>
#include <optional>
#include <string_view>
#include <utility>

namespace game::service::detail {
namespace {

using Path = std::filesystem::path;

template <typename Value>
using Reader = config::ReadResult<Value> (*)(std::string_view);

// Thư mục đang đọc và các dòng lỗi gom được.
class Loader {
public:
    explicit Loader(Path dir) : dir_(std::move(dir)) {}

    // Giá trị đã kiểm của một tệp; rỗng khi tệp không đọc được hoặc có lỗi (lỗi đã ghi lại).
    template <typename Value>
    [[nodiscard]] std::optional<Value> read(std::string_view name, Reader<Value> reader);

    // Chỉ kiểm, không cần giá trị.
    template <typename Value>
    void check(std::string_view name, Reader<Value> reader) {
        static_cast<void>(read(name, reader));
    }

    void report(std::string_view name, const config::IssueList& issues);
    void report(std::string_view name, std::size_t line, std::string_view message) {
        errors_.push_back(std::format("{}:{}: {}", name, line, message));
    }

    [[nodiscard]] bool is_clean() const noexcept { return errors_.empty(); }
    [[nodiscard]] ErrorLines take_errors() noexcept { return std::move(errors_); }

private:
    Path dir_;
    ErrorLines errors_;
};

template <typename Value>
std::optional<Value> Loader::read(std::string_view name, Reader<Value> reader) {
    const io::TextResult text = io::read_text(dir_ / io::path_from_utf8(name));
    if (!text) {
        report(name, 1, io::describe(text.error()));
        return std::nullopt;
    }
    config::ReadResult<Value> value = reader(*text);
    if (value) return std::move(*value);
    report(name, value.error());
    return std::nullopt;
}

void Loader::report(std::string_view name, const config::IssueList& issues) {
    for (const config::Issue& issue : issues) {
        report(name, issue.line, issue.message);
    }
}

// Tệp riêng của một loại tiến trình con.
void check_own(Loader& loader, Kind kind) {
    if (kind == Kind::kStore) loader.check("store.toml", config::read_store);
    if (kind == Kind::kAuth) loader.check("auth.toml", config::read_auth);
    if (kind == Kind::kBilling) loader.check("billing.toml", config::read_billing);
    if (kind == Kind::kWorld) loader.check("world.toml", config::read_world);
    if (kind == Kind::kZone) loader.check("zone.toml", config::read_zone);
    if (kind == Kind::kGate) loader.check("gate.toml", config::read_gate);
}

struct Instance {
    std::string_view kind;
    std::int32_t id = 0;

    [[nodiscard]] bool is(const config::ProcessBlock& block) const {
        return config::name_of(block.kind) == kind && block.id.value() == id;
    }
};

// Con chạy với một --id mà cluster.toml không khai thì không có cổng ipc nào cho nó.
void check_instance(Loader& loader, const config::Cluster& cluster, const Instance& wanted) {
    const auto is_wanted = [&](const config::ProcessBlock& block) { return wanted.is(block); };
    if (std::ranges::any_of(cluster.processes, is_wanted)) return;
    constexpr std::string_view kMissing = "không có khối [[process]] kind = \"{}\", id = {}";
    loader.report("cluster.toml", 1, std::format(kMissing, wanted.kind, wanted.id));
}

} // namespace

ClusterResult load_cluster(const Path& config_dir) {
    Loader loader{config_dir};
    std::optional cluster = loader.read("cluster.toml", config::read_cluster);
    loader.check("log.toml", config::read_log);
    std::optional plan = loader.read("supervisor.toml", config::read_supervisor);
    loader.check("admin.toml", config::read_admin);
    check_own(loader, Kind::kStore);
    check_own(loader, Kind::kAuth);
    check_own(loader, Kind::kBilling);
    check_own(loader, Kind::kWorld);
    check_own(loader, Kind::kZone);
    check_own(loader, Kind::kGate);
    // Thiếu một trong hai thì lỗi của nó đã nằm trong loader; hai tệp đủ mới so chéo được.
    if (!cluster || !plan) return std::unexpected(loader.take_errors());
    const config::StartupResult startup = config::check_startup(*cluster, *plan);
    if (!startup) loader.report("supervisor.toml", startup.error());
    if (!loader.is_clean()) return std::unexpected(loader.take_errors());
    return ClusterFiles{.cluster = std::move(*cluster), .supervisor = std::move(*plan)};
}

ErrorLines check_child(Kind kind, const Request& request) {
    Loader loader{request.config_dir};
    const std::optional cluster = loader.read("cluster.toml", config::read_cluster);
    loader.check("log.toml", config::read_log);
    check_own(loader, kind);
    const bool is_numbered = cluster.has_value() && request.id.has_value();
    if (!is_numbered) return loader.take_errors();
    check_instance(loader, *cluster, Instance{.kind = kind_name(kind), .id = *request.id});
    return loader.take_errors();
}

} // namespace game::service::detail
