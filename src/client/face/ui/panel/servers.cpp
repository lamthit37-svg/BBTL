// Danh sách máy chủ đăng nhập (xem servers.hpp).
#include "ui/panel/servers.hpp"

#include "core/number.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::ui::panel {
namespace {

constexpr char kDash = '-';
constexpr std::size_t kColumnCount = 9;

struct PrefixRow {
    std::string_view prefix;
    BigArea area;
};

// Các tiền tố mà script nhận ra khi gom vùng vào đại khu (SelectServer_Data_GetAreaInfoAndRecommendServerInfo).
constexpr std::array<PrefixRow, 10> kPrefixes = {{
    {.prefix = "电信", .area = BigArea::kTelecom},
    {.prefix = "网通", .area = BigArea::kUnicom},
    {.prefix = "争霸赛", .area = BigArea::kContest},
    {.prefix = "双线", .area = BigArea::kDual},
    {.prefix = "轻享", .area = BigArea::kLight},
    {.prefix = "特色服", .area = BigArea::kSpecial},
    {.prefix = "至尊帮派邀请赛", .area = BigArea::kBraveGathering},
    {.prefix = "天下会武", .area = BigArea::kWorldMartial},
    {.prefix = "巅峰赛", .area = BigArea::kPeak},
    {.prefix = "WG独立大区", .area = BigArea::kWeGameOnly},
}};

// Tiền tố mà mục đề cử cắt khỏi tên vùng (SelectServer_Data_ShowRecommendServer, dòng 997).
constexpr std::array<std::string_view, 7> kRecommendCut = {
    "双线", "网通", "电信", "争霸赛", "特色服", "轻享", "WG独立大区"};

[[nodiscard]] std::string_view prefix_of(std::string_view area_name) noexcept {
    const std::size_t dash = area_name.find(kDash);
    if (dash == std::string_view::npos) return {};
    return area_name.substr(0, dash);
}

// Các ô của một dòng TSV, không cấp phát.
struct Cells {
    std::array<std::string_view, kColumnCount> fields{};
    std::size_t count = 0;
    bool is_overfull = false;
};

[[nodiscard]] Cells split_cells(std::string_view line) {
    Cells cells;
    while (true) {
        const std::size_t tab = line.find('\t');
        const std::string_view field = tab == std::string_view::npos ? line : line.substr(0, tab);
        if (cells.count == cells.fields.size()) {
            cells.is_overfull = true;
            return cells;
        }
        cells.fields.at(cells.count) = field;
        ++cells.count;
        if (tab == std::string_view::npos) return cells;
        line = line.substr(tab + 1);
    }
}

// Số nguyên không dấu trong [0, top] chiếm hết ô; ô rỗng cho `empty`.
[[nodiscard]] std::optional<std::uint8_t> small_number(std::string_view cell, std::uint8_t top) noexcept {
    const core::OptionalUnsigned parsed = core::parse_unsigned(cell, 10);
    if (!parsed || parsed->length != cell.size() || parsed->value > top) return std::nullopt;
    return static_cast<std::uint8_t>(parsed->value);
}

struct Row {
    LoginArea area;
    std::optional<LoginServer> server;
};

[[nodiscard]] std::optional<LoginServer> read_server(const Cells& cells) {
    const std::optional<std::uint8_t> status = small_number(cells.fields.at(4), kStatusHidden);
    const std::optional<std::uint8_t> recommend = small_number(cells.fields.at(5), UINT8_MAX);
    const std::optional<std::uint8_t> is_new = small_number(cells.fields.at(6), 1);
    const std::optional<std::uint8_t> prize = small_number(cells.fields.at(7), kPrizeLevels);
    const std::optional<std::uint8_t> has_arena = small_number(cells.fields.at(8), 1);
    if (!status || !recommend || !is_new || !prize || !has_arena) return std::nullopt;
    LoginServer server;
    server.name = std::string(cells.fields.at(3));
    server.status = *status;
    server.recommend = *recommend;
    server.is_new = *is_new != 0;
    server.prize = *prize;
    server.has_arena = *has_arena != 0;
    return server;
}

// Dòng hỏng (thiếu cột, số ngoài miền) trả nullopt; dòng chỉ có vùng trả Row không có server.
[[nodiscard]] std::optional<Row> read_row(std::string_view line) {
    const Cells cells = split_cells(line);
    if (cells.count != kColumnCount || cells.is_overfull || cells.fields.front().empty()) return std::nullopt;
    const std::optional<std::uint8_t> area_recommend = small_number(cells.fields.at(2), UINT8_MAX);
    if (!area_recommend) return std::nullopt;
    Row row;
    row.area.name = std::string(cells.fields.front());
    row.area.tip = std::string(cells.fields.at(1));
    row.area.recommend = *area_recommend;
    if (cells.fields.at(3).empty()) return row;
    row.server = read_server(cells);
    if (!row.server) return std::nullopt;
    return row;
}

[[nodiscard]] LoginArea* area_named(ServerDirectory& directory, std::string_view name) noexcept {
    const auto found = std::ranges::find(directory.areas, name, &LoginArea::name);
    return found == directory.areas.end() ? nullptr : std::to_address(found);
}

void add_row(ServerDirectory& directory, Row row) {
    LoginArea* area = area_named(directory, row.area.name);
    if (area == nullptr) {
        if (directory.areas.size() >= kAreaCap) return;
        directory.areas.push_back(std::move(row.area));
        area = &directory.areas.back();
    }
    if (!row.server || area->servers.size() >= kServersPerArea) return;
    area->servers.push_back(std::move(*row.server));
}

[[nodiscard]] std::string_view next_line(std::string_view& text) noexcept {
    const std::size_t end = text.find('\n');
    std::string_view line = end == std::string_view::npos ? text : text.substr(0, end);
    text = end == std::string_view::npos ? std::string_view{} : text.substr(end + 1);
    if (!line.empty() && line.back() == '\r') line.remove_suffix(1);
    return line;
}

} // namespace

std::optional<BigArea> big_area_of(std::string_view area_name) noexcept {
    if (area_name.find(kDash) == std::string_view::npos) return BigArea::kTelecom;
    const std::string_view prefix = prefix_of(area_name);
    const auto found = std::ranges::find(kPrefixes, prefix, &PrefixRow::prefix);
    if (found == kPrefixes.end()) return std::nullopt;
    return found->area;
}

std::string_view area_title(std::string_view area_name) noexcept {
    if (!big_area_of(area_name) || area_name.find(kDash) == std::string_view::npos) return area_name;
    return area_name.substr(area_name.find(kDash) + 1);
}

std::string_view recommend_label(std::string_view area_name) noexcept {
    const std::size_t dash = area_name.find(kDash);
    if (dash == std::string_view::npos || dash + 1 >= area_name.size()) return area_name;
    if (!std::ranges::contains(kRecommendCut, area_name.substr(0, dash))) return area_name;
    return area_name.substr(dash + 1);
}

std::vector<ServerRef> recommended(const ServerDirectory& directory) {
    std::vector<ServerRef> picked;
    for (std::size_t area = 0; area < directory.areas.size() && picked.size() < kRecommendCap; ++area) {
        const std::vector<LoginServer>& servers = directory.areas.at(area).servers;
        for (std::size_t server = 0; server < servers.size() && picked.size() < kRecommendCap; ++server) {
            const LoginServer& entry = servers.at(server);
            if (entry.recommend == 0 || entry.status == kStatusHidden) continue;
            picked.push_back(ServerRef{.area = area, .server = server});
        }
    }
    const auto level_of = [&directory](ServerRef ref) { return directory.areas.at(ref.area).servers.at(ref.server).recommend; };
    std::ranges::stable_sort(picked, {}, level_of);
    return picked;
}

std::vector<ServerRef> search(const ServerDirectory& directory, std::string_view keyword) {
    std::vector<ServerRef> found;
    if (keyword.empty()) return found;
    for (std::size_t area = 0; area < directory.areas.size(); ++area) {
        const std::vector<LoginServer>& servers = directory.areas.at(area).servers;
        for (std::size_t server = 0; server < servers.size(); ++server) {
            const LoginServer& entry = servers.at(server);
            if (entry.status != kStatusHidden && entry.name.contains(keyword)) {
                found.push_back(ServerRef{.area = area, .server = server});
            }
        }
    }
    return found;
}

const LoginServer* server_at(const ServerDirectory& directory, ServerRef ref) noexcept {
    if (ref.area >= directory.areas.size()) return nullptr;
    const std::vector<LoginServer>& servers = directory.areas.at(ref.area).servers;
    return ref.server < servers.size() ? &servers.at(ref.server) : nullptr;
}

std::optional<ServerDirectory> decode_servers(std::string_view text) {
    ServerDirectory directory;
    bool has_header = false;
    while (!text.empty()) {
        const std::string_view line = next_line(text);
        if (line.empty() || line.front() == '#') continue;
        if (!has_header) {
            if (line != kServerColumns) return std::nullopt;
            has_header = true;
            continue;
        }
        std::optional<Row> row = read_row(line);
        if (row) add_row(directory, std::move(*row));
    }
    if (!has_header) return std::nullopt;
    return directory;
}

std::string encode_last(const ServerDirectory& directory, ServerRef server) {
    const LoginServer* entry = server_at(directory, server);
    if (entry == nullptr) return {};
    std::string text = "1\n";
    text.append(directory.areas.at(server.area).name);
    text.push_back('\t');
    text.append(entry->name);
    text.push_back('\n');
    return text;
}

std::optional<ServerRef> decode_last(const ServerDirectory& directory, std::string_view text) {
    if (next_line(text) != "1") return std::nullopt;
    const std::string_view line = next_line(text);
    const std::size_t tab = line.find('\t');
    if (tab == std::string_view::npos) return std::nullopt;
    const std::string_view area_name = line.substr(0, tab);
    const std::string_view server_name = line.substr(tab + 1);
    const auto area = std::ranges::find(directory.areas, area_name, &LoginArea::name);
    if (area == directory.areas.end()) return std::nullopt;
    const auto server = std::ranges::find(area->servers, server_name, &LoginServer::name);
    if (server == area->servers.end()) return std::nullopt;
    return ServerRef{.area = static_cast<std::size_t>(area - directory.areas.begin()),
        .server = static_cast<std::size_t>(server - area->servers.begin())};
}

} // namespace game::ui::panel
