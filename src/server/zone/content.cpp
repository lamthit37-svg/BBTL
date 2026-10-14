#include "zone/content.hpp"

#include "core/ground_point.hpp"
#include "io/file.hpp"
#include "scenedata/disk.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <charconv>
#include <cstdio>
#include <expected>
#include <format>
#include <iterator>
#include <memory>
#include <optional>
#include <print>
#include <utility>

namespace game::zone {
namespace {

// Độ đổi sang đơn vị 0..65535 của EntityAppear.direction; bảng cảnh luôn ghi 0..360 (heading_degrees).
[[nodiscard]] std::uint16_t direction_of_degrees(std::int32_t degrees) noexcept {
    const std::int32_t wrapped = ((degrees % 360) + 360) % 360;
    return static_cast<std::uint16_t>((wrapped * 65536) / 360);
}

[[nodiscard]] protocol::EntityKind kind_of(const scenedata::Spawn& row, const TemplateInfo* info) noexcept {
    if (row.is_pet) return protocol::EntityKind::kPet;
    const bool talks = row.is_npc || (info != nullptr && info->interactive);
    return talks ? protocol::EntityKind::kNpc : protocol::EntityKind::kMonster;
}

// Trần của bảng mẫu: bảng thật 8 MiB, 29 nghìn dòng.
constexpr std::size_t kTemplateBytesMax = std::size_t{64} * 1024 * 1024;
constexpr std::size_t kTemplateColumnsMax = 256;

[[nodiscard]] std::optional<std::int64_t> whole_number(std::string_view text) noexcept {
    std::int64_t value = 0;
    const char* const first = text.data();
    const char* const last = std::next(first, static_cast<std::ptrdiff_t>(text.size()));
    const std::from_chars_result parsed = std::from_chars(first, last, value);
    if (parsed.ec != std::errc{} || parsed.ptr != last) return std::nullopt;
    return value;
}

// Tách `line` theo tab vào `cells` (dùng lại bộ nhớ). Trần số cột chặn dòng thù địch.
[[nodiscard]] bool split_tabs(std::string_view line, std::vector<std::string_view>& cells) {
    cells.clear();
    while (true) {
        const std::size_t tab = line.find('\t');
        cells.push_back(line.substr(0, tab));
        if (cells.size() > kTemplateColumnsMax) return false;
        if (tab == std::string_view::npos) return true;
        line.remove_prefix(tab + 1);
    }
}

[[nodiscard]] std::string template_fault(std::size_t line_number, std::string_view what) {
    return std::format("monsters.tsv:{}: {}", line_number, what);
}

// Tên thư mục là một thành phần đường dẫn, không phải đường dẫn: bảng bị sửa tay không được dẫn ra ngoài scenes/.
[[nodiscard]] bool is_plain_name(std::string_view name) noexcept {
    if (name.empty() || name == "." || name == "..") return false;
    return std::ranges::none_of(name, [](char letter) { return letter == '/' || letter == '\\' || letter == ':'; });
}

} // namespace

std::expected<TemplateTable, std::string> TemplateTable::parse(std::string_view text) {
    if (text.size() > kTemplateBytesMax) return std::unexpected(template_fault(0, "bảng quá lớn"));
    TemplateTable table;
    std::vector<std::string_view> cells;
    std::size_t id_at = 0;
    std::size_t level_at = 0;
    std::size_t interact_at = 0;
    std::size_t columns = 0;
    std::size_t line_number = 0;
    while (!text.empty()) {
        const std::size_t end = text.find('\n');
        std::string_view line = text.substr(0, end);
        text.remove_prefix(end == std::string_view::npos ? text.size() : end + 1);
        ++line_number;
        if (line.ends_with('\r')) line.remove_suffix(1);
        if (line.empty() || line.starts_with('#')) continue;
        if (!split_tabs(line, cells)) return std::unexpected(template_fault(line_number, "quá nhiều cột"));
        if (columns == 0) {
            columns = cells.size();
            const auto find = [&](std::string_view name) {
                return static_cast<std::size_t>(std::ranges::find(cells, name) - cells.begin());
            };
            id_at = find("monster_id");
            level_at = find("level");
            interact_at = find("can_interact");
            if (std::max({id_at, level_at, interact_at}) >= columns) {
                return std::unexpected(template_fault(line_number, "thiếu cột monster_id, level hoặc can_interact"));
            }
            continue;
        }
        if (cells.size() != columns) return std::unexpected(template_fault(line_number, "số ô khác dòng tên cột"));
        const std::optional<std::int64_t> id = whole_number(cells[id_at]);
        const std::optional<std::int64_t> level = whole_number(cells[level_at]);
        const std::optional<std::int64_t> interact = whole_number(cells[interact_at]);
        if (!id || *id < 0 || *id > 0xFFFFFFFFLL || !level || *level < 0 || *level > 0xFFFF || !interact) {
            return std::unexpected(template_fault(line_number, "id, level hoặc can_interact không phải số hợp lệ"));
        }
        const bool fresh = table.by_id_
                               .try_emplace(static_cast<std::uint32_t>(*id),
                                   TemplateInfo{.level = static_cast<std::uint16_t>(*level), .interactive = *interact == 1})
                               .second;
        if (!fresh) return std::unexpected(template_fault(line_number, "monster_id trùng"));
    }
    if (columns == 0) return std::unexpected(template_fault(line_number, "không có dòng tên cột"));
    return table;
}

const TemplateInfo* TemplateTable::find(std::uint32_t template_id) const noexcept {
    const auto found = by_id_.find(template_id);
    return found == by_id_.end() ? nullptr : &found->second;
}

Seeding seeds_of(const scenedata::Scene& scene, std::size_t cap, const TemplateTable& templates) {
    Seeding result;
    result.seeds.reserve(std::min(scene.spawns.size(), cap));
    for (const scenedata::Spawn& row : scene.spawns) {
        if (!row.position_given) {
            ++result.unplaced;
            continue;
        }
        if (result.seeds.size() >= cap) {
            ++result.over_cap;
            continue;
        }
        const TemplateInfo* const info = templates.find(row.type.value());
        Spawn what;
        what.kind = kind_of(row, info);
        what.template_id = row.type.value();
        what.name = row.name;
        // Cấp trong bảng cảnh ghi đè cấp của mẫu; 0 nghĩa là client lấy theo mẫu (Spawn mặc định cấp 1).
        what.level = 0;
        if (row.level > 0) {
            what.level = static_cast<std::uint16_t>(std::min<std::int32_t>(row.level, 0xFFFF));
        } else if (info != nullptr) {
            what.level = info->level;
        }
        what.x_cm = row.position.x * 100.0F;
        what.z_cm = row.position.z * 100.0F;
        what.direction = direction_of_degrees(row.heading_degrees());
        result.seeds.push_back(Seed{.what = std::move(what), .respawn_ms = row.respawn_ms});
    }
    return result;
}

std::expected<SceneDirectory, std::string> SceneDirectory::parse(std::string_view text) {
    const table::TsvResult parsed = table::parse_tsv(text);
    if (!parsed) return std::unexpected(parsed.error());
    SceneDirectory directory;
    for (std::size_t row = 0; row < parsed->rows.size(); ++row) {
        table::RowReader reader{*parsed, row};
        const std::uint32_t first = reader.number("client_id_first", 0, 0xFFFF);
        const std::uint32_t last = reader.number("client_id_last", 0, 0xFFFF);
        const std::string_view dir = reader.text("scene_dir");
        if (!reader.error() && (first > last || !is_plain_name(dir))) reader.reject("scene_dir", "khoảng id hay tên thư mục sai");
        if (reader.error()) return std::unexpected(*reader.error());
        const auto id_first = static_cast<std::uint16_t>(first);
        // Khoảng sau không được nằm đè khoảng trước: tra cứu theo id đầu sẽ trả nhầm thư mục.
        const auto next = directory.ranges_.lower_bound(id_first);
        const bool overlaps_next = next != directory.ranges_.end() && next->first <= last;
        const bool overlaps_prev = next != directory.ranges_.begin() && std::prev(next)->second.last >= id_first;
        if (overlaps_next || overlaps_prev) {
            return std::unexpected("scene_ids: khoảng id chồng nhau ở thư mục " + std::string{dir});
        }
        directory.ranges_.emplace(id_first, Range{.last = static_cast<std::uint16_t>(last), .dir = std::string{dir}});
    }
    return directory;
}

std::string_view SceneDirectory::dir_of(std::uint16_t scene) const noexcept {
    const auto above = ranges_.upper_bound(scene);
    if (above == ranges_.begin()) return {};
    const auto& [first, range] = *std::prev(above);
    return scene <= range.last ? std::string_view{range.dir} : std::string_view{};
}

Walkable walkable_of(std::shared_ptr<const scenedata::Walk> walk) {
    if (!walk || walk->source == scenedata::WalkSource::kNone) return {};
    // Bảng cảnh tính bằng đơn vị game, zone bằng centimet (1 đơn vị = 100 cm).
    constexpr float kUnitsPerCm = 0.01F;
    return [grid = std::move(walk)](float x_cm, float z_cm) {
        const auto stands = [&](float dx, float dz) {
            return grid->walkable(core::GroundPoint{.x = (x_cm + dx) * kUnitsPerCm, .z = (z_cm + dz) * kUnitsPerCm});
        };
        return stands(0.0F, 0.0F) || stands(kWalkSlackCm, 0.0F) || stands(-kWalkSlackCm, 0.0F) ||
            stands(0.0F, kWalkSlackCm) || stands(0.0F, -kWalkSlackCm);
    };
}

namespace {

// Trạng thái của DiskSeeder. Bảng id đọc ở lần hỏi đầu, không phải lúc dựng: cụm khởi động (và test cụm với thư mục
// cấu hình tạm) không đọc đĩa khi chưa có cảnh nào. Chỉ luồng tick của zone gọi, nên không cần khoá.
struct DiskState {
    DiskState(DiskPaths where, std::size_t limit) : paths(std::move(where)), cap(limit) {}

    DiskPaths paths;
    std::size_t cap = 0;
    bool tried = false;
    std::optional<SceneDirectory> directory;
    TemplateTable templates;

    void open() {
        tried = true;
        const io::TextResult text = io::read_text(paths.ids_table);
        if (!text) {
            std::println(stderr, "zone: không đọc được {}: cảnh không có quái và NPC", paths.ids_table.string());
            return;
        }
        std::expected<SceneDirectory, std::string> parsed = SceneDirectory::parse(*text);
        if (!parsed) {
            std::println(stderr, "zone: {}: {}", paths.ids_table.string(), parsed.error());
            return;
        }
        directory = std::move(*parsed);
        open_templates();
    }

    // Bảng mẫu là phần làm giàu, không bắt buộc: vắng thì im lặng, có mà hỏng thì nói.
    void open_templates() {
        if (paths.templates.empty()) return;
        const io::TextResult text = io::read_text(paths.templates);
        if (!text) return;
        // Dạng if có khởi tạo: với dạng "parsed rồi if (!parsed)" GCC 16 báo nhầm -Wfree-nonheap-object ở destructor của
        // parsed khi open() được inline vào content().
        if (std::expected<TemplateTable, std::string> parsed = TemplateTable::parse(*text)) {
            templates = std::move(*parsed);
        } else {
            std::println(stderr, "zone: {}: {}", paths.templates.string(), parsed.error());
        }
    }

    [[nodiscard]] SceneContent content(std::uint16_t scene) {
        if (!tried) open();
        if (!directory) return {};
        const std::string_view name = directory->dir_of(scene);
        if (name.empty()) return {};
        scenedata::Loaded<scenedata::Scene> loaded = scenedata::load_scene(paths.scenes / std::string{name});
        if (!loaded) {
            std::println(stderr, "zone: cảnh {} ({}): {}", scene, name, loaded.error().what);
            return {};
        }
        Seeding seeding = seeds_of(*loaded, cap, templates);
        if (seeding.over_cap > 0) {
            std::println(stderr, "zone: cảnh {} ({}): bỏ {} thực thể vượt trần {}", scene, name, seeding.over_cap, cap);
        }
        return SceneContent{.seeds = std::move(seeding.seeds),
            .walkable = walkable_of(std::make_shared<const scenedata::Walk>(std::move(loaded->walk)))};
    }
};

} // namespace

Seeder disk_seeder(const DiskPaths& paths, std::size_t cap) {
    auto state = std::make_shared<DiskState>(paths, cap);
    return [state](std::uint16_t scene) { return state->content(scene); };
}

} // namespace game::zone
