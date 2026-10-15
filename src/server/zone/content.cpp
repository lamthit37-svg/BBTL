/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/zone/content.cpp
 *  PHÂN HỆ   : Server / Zone / Content
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt đọc dữ liệu cảnh cho zone: bảng mẫu quái, bảng loại AI, bảng id
 *    cảnh, luật đi, đổi dòng spawns thành Seed.
 *  - Đổi đơn vị một chỗ: bảng cảnh tính bằng đơn vị game (1 = 100 cm), AI tính
 *    bằng mili giây thành tick.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "zone/content.hpp"

#include "core/ground_point.hpp"
#include "ids/ids.hpp"
#include "io/file.hpp"
#include "protocol/messages.hpp"
#include "scenedata/disk.hpp"
#include "scenedata/types.hpp"
#include "table/tsv.hpp"
#include "zone/mind.hpp"
#include "zone/scene.hpp"

#include <algorithm>
#include <charconv>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <expected>
#include <format>
#include <iterator>
#include <memory>
#include <optional>
#include <print>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

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
    std::size_t ai_at = 0;
    std::size_t speed_at = 0;
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
            ai_at = find("base_ai");
            speed_at = find("move_speed");
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
        TemplateInfo info{.level = static_cast<std::uint16_t>(*level), .interactive = *interact == 1};
        // Hai cột làm giàu có thể vắng hoặc có ô lạ: khi đó quái không có AI, không phải lỗi bảng.
        if (ai_at < columns) {
            if (const auto ai = whole_number(cells[ai_at]); ai && *ai >= -1 && *ai <= 0x7FFFFFFFLL) {
                info.base_ai = static_cast<std::int32_t>(*ai);
            }
        }
        if (speed_at < columns) {
            if (const auto speed = whole_number(cells[speed_at]); speed && *speed >= 0 && *speed <= 0xFFFFLL * 1000) {
                info.move_speed = static_cast<std::int32_t>(*speed);
            }
        }
        const bool fresh = table.by_id_.try_emplace(static_cast<std::uint32_t>(*id), info).second;
        if (!fresh) return std::unexpected(template_fault(line_number, "monster_id trùng"));
    }
    if (columns == 0) return std::unexpected(template_fault(line_number, "không có dòng tên cột"));
    return table;
}

const TemplateInfo* TemplateTable::find(std::uint32_t template_id) const noexcept {
    const auto found = by_id_.find(template_id);
    return found == by_id_.end() ? nullptr : &found->second;
}

std::expected<AiTypeTable, std::string> AiTypeTable::parse(std::string_view text) {
    const table::TsvResult parsed = table::parse_tsv(text);
    if (!parsed) return std::unexpected(parsed.error());
    AiTypeTable result;
    constexpr std::int32_t kLow = -1;
    constexpr std::int32_t kHigh = 100'000'000;
    for (std::size_t row = 0; row < parsed->rows.size(); ++row) {
        table::RowReader reader{*parsed, row};
        const std::int32_t ai_id = reader.integer("ai_id", 0, 0x7FFFFFFF);
        const AiType type{.scan_ms = reader.integer("aiparam0", kLow, kHigh),
            .wander_ms = reader.integer("aiparam1", kLow, kHigh),
            .return_mm = reader.integer("aiparam3", kLow, kHigh),
            .scan_mm = reader.integer("aiparam4", kLow, kHigh)};
        if (reader.error()) return std::unexpected(*reader.error());
        if (!result.by_id_.try_emplace(ai_id, type).second) return std::unexpected("monster_ai_types: ai_id trùng");
    }
    return result;
}

const AiType* AiTypeTable::find(std::int32_t ai_id) const noexcept {
    const auto found = by_id_.find(ai_id);
    return found == by_id_.end() ? nullptr : &found->second;
}

namespace {

[[nodiscard]] std::uint32_t ticks_of(std::int32_t milliseconds) noexcept {
    return static_cast<std::uint32_t>(ids::to_ticks(milliseconds, kTickHz).count);
}

// Tính nết của một quái/NPC đặt sẵn, hoặc nullopt khi thiếu bảng AI hay chẳng có hành vi nào (đứng yên mãi).
[[nodiscard]] std::optional<Temperament> nature_of(const scenedata::Spawn& row, protocol::EntityKind kind,
    const TemplateInfo* info, const AiTypeTable* ai_types) {
    if (info == nullptr || ai_types == nullptr || info->move_speed <= 0) return std::nullopt;
    const AiType* const type = ai_types->find(row.base_ai.value_or(info->base_ai));
    if (type == nullptr) return std::nullopt;
    Temperament nature;
    nature.walk_cm = static_cast<std::uint16_t>(std::min<std::int32_t>(info->move_speed / 10, 0xFFFF));
    nature.wander_ticks = ticks_of(type->wander_ms);
    nature.range_cm = kWanderRangeCm;
    // Chỉ quái mới tự đuổi người; NPC và thú cưng nhiều lắm chỉ đi lang thang.
    if (kind == protocol::EntityKind::kMonster) {
        nature.scan_ticks = ticks_of(type->scan_ms);
        nature.scan_cm = static_cast<std::uint32_t>(std::max(type->scan_mm, 0) / 10);
        nature.return_cm = static_cast<std::uint32_t>(std::max(type->return_mm, 0) / 10);
    }
    return nature;
}

} // namespace

Seeding seeds_of(const scenedata::Scene& scene, std::size_t cap, const SeedTables& tables) {
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
        const TemplateInfo* const info = tables.templates == nullptr ? nullptr : tables.templates->find(row.type.value());
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
        what.nature = nature_of(row, what.kind, info, tables.ai_types);
        if (what.nature) what.speed_cm = what.nature->walk_cm;
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
    AiTypeTable ai_types;
    bool has_ai_types = false;

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
        open_ai_types();
    }

    // Như bảng mẫu: vắng thì im lặng, có mà hỏng thì nói.
    void open_ai_types() {
        if (paths.ai_types.empty()) return;
        const io::TextResult text = io::read_text(paths.ai_types);
        if (!text) return;
        if (std::expected<AiTypeTable, std::string> parsed = AiTypeTable::parse(*text)) {
            ai_types = std::move(*parsed);
            has_ai_types = true;
        } else {
            std::println(stderr, "zone: {}: {}", paths.ai_types.string(), parsed.error());
        }
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
        const SeedTables tables{.templates = &templates, .ai_types = has_ai_types ? &ai_types : nullptr};
        Seeding seeding = seeds_of(*loaded, cap, tables);
        if (seeding.over_cap > 0) {
            std::println(stderr, "zone: cảnh {} ({}): bỏ {} thực thể vượt trần {}", scene, name, seeding.over_cap, cap);
        }
        Walkable walkable = walkable_of(std::make_shared<const scenedata::Walk>(std::move(loaded->walk)));
        return SceneContent{.seeds = std::move(seeding.seeds), .walkable = std::move(walkable)};
    }
};

} // namespace

Seeder disk_seeder(const DiskPaths& paths, std::size_t cap) {
    const auto state = std::make_shared<DiskState>(paths, cap);
    return [state](std::uint16_t scene) { return state->content(scene); };
}

} // namespace game::zone
