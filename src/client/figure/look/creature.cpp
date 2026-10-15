/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/figure/look/creature.cpp
 *  PHÂN HỆ   : Figure / Look / Creature
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hình của quái và NPC (xem creature.hpp).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "look/creature.hpp"

#include "look/look.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <optional>
#include <ranges>
#include <span>
#include <string>
#include <string_view>
#include <tuple>
#include <utility>
#include <vector>

namespace game::look {
namespace {

constexpr char kListMark = '|';
constexpr std::int32_t kMostModel = 100'000'000;
constexpr std::uint32_t kMostTemplate = 100'000'000;
// Trần số dòng mỗi bảng: bảng của 325 cảnh có chừng một vạn dòng clip; quá xa mức đó là bảng hỏng, không phải dữ liệu.
constexpr std::size_t kMostRows = 1'000'000;

constexpr std::array<std::string_view, 8> kTemplateColumns{
    "template", "name", "model", "plate_height", "ring_size", "shadow_size", "scale", "kind"};
constexpr std::array<std::string_view, 8> kModelColumns{"model", "meshes", "skeleton", "sx", "sy", "sz", "height", "materials"};
constexpr std::array<std::string_view, 5> kClipColumns{"model", "kind", "action", "anim", "clip"};
constexpr std::array<std::string_view, 6> kMaterialColumns{"material", "texture", "alpha", "cutoff", "double_sided", "unlit"};

struct ActionName {
    std::string_view name;
    CreatureAction action;
};

constexpr std::array kActions{
    ActionName{.name = "idle", .action = CreatureAction::kIdle},
    ActionName{.name = "idle_alt", .action = CreatureAction::kIdleAlt},
    ActionName{.name = "idle_alt2", .action = CreatureAction::kIdleAlt2},
    ActionName{.name = "walk", .action = CreatureAction::kWalk},
    ActionName{.name = "run", .action = CreatureAction::kRun},
    ActionName{.name = "combat_idle", .action = CreatureAction::kCombatIdle},
    ActionName{.name = "combat_walk", .action = CreatureAction::kCombatWalk},
    ActionName{.name = "combat_run", .action = CreatureAction::kCombatRun},
    ActionName{.name = "hit", .action = CreatureAction::kHit},
    ActionName{.name = "death", .action = CreatureAction::kDeath},
    ActionName{.name = "corpse", .action = CreatureAction::kCorpse},
    ActionName{.name = "attack", .action = CreatureAction::kAttack},
    ActionName{.name = "attack_alt", .action = CreatureAction::kAttackAlt},
    ActionName{.name = "attack_alt2", .action = CreatureAction::kAttackAlt2},
    ActionName{.name = "default", .action = CreatureAction::kDefault},
};

[[nodiscard]] std::vector<std::string> split_list(std::string_view cell) {
    std::vector<std::string> items;
    for (const auto part : cell | std::views::split(kListMark)) {
        items.emplace_back(part.begin(), part.end());
    }
    return items;
}

// Cả bảng, hoặc lỗi có tên bảng. Cột bắt buộc kiểm ngay cả khi bảng không có dòng nào: RowReader chỉ phát hiện cột thiếu
// khi đọc một dòng.
struct TableSpec {
    std::string_view name;
    std::span<const std::string_view> columns;
};

[[nodiscard]] std::expected<table::Tsv, std::string> parse_named(const TableSpec& spec, std::string_view text) {
    table::TsvResult parsed = table::parse_tsv(text);
    if (!parsed) return std::unexpected(std::format("bảng {} sai, {}", spec.name, parsed.error()));
    for (const std::string_view column : spec.columns) {
        if (!table::column_of(*parsed, column)) {
            return std::unexpected(std::format("bảng {} thiếu cột {}", spec.name, column));
        }
    }
    if (parsed->rows.size() > kMostRows) {
        return std::unexpected(std::format("bảng {} có {} dòng, quá trần {}", spec.name, parsed->rows.size(), kMostRows));
    }
    return std::move(*parsed);
}

// Lỗi đầu tiên của dòng đang đọc, kèm tên bảng. Chỉ gọi khi reader.error() có giá trị (reject luôn ghi lỗi).
[[nodiscard]] std::string row_failure(std::string_view name, const table::RowReader& reader) {
    return std::format("bảng {} sai, {}", name, reader.error().value_or("lỗi không rõ"));
}

[[nodiscard]] std::optional<CreatureKind> kind_of(std::string_view cell) noexcept {
    if (cell == "npc") return CreatureKind::kNpc;
    if (cell == "monster") return CreatureKind::kMonster;
    return std::nullopt;
}

[[nodiscard]] std::optional<CreatureAction> action_of(std::string_view cell) noexcept {
    const auto found = std::ranges::find(kActions, cell, &ActionName::name);
    if (found == kActions.end()) return std::nullopt;
    return found->action;
}

[[nodiscard]] std::optional<OverlayAlpha> alpha_of(std::string_view cell) noexcept {
    if (cell == "OPAQUE") return OverlayAlpha::kOpaque;
    if (cell == "MASK") return OverlayAlpha::kMask;
    if (cell == "BLEND") return OverlayAlpha::kBlend;
    return std::nullopt;
}

[[nodiscard]] std::expected<std::vector<CreatureTemplate>, std::string> read_templates(std::string_view text) {
    const auto table = parse_named({.name = "creature_templates", .columns = kTemplateColumns}, text);
    if (!table) return std::unexpected(table.error());
    std::vector<CreatureTemplate> rows;
    rows.reserve(table->rows.size());
    for (std::size_t at = 0; at < table->rows.size(); ++at) {
        table::RowReader reader(*table, at);
        CreatureTemplate row;
        row.id = reader.number("template", 0, kMostTemplate);
        row.name = reader.text("name");
        row.model = reader.integer("model", -1, kMostModel);
        row.plate_height = reader.real("plate_height");
        row.ring_size = reader.real("ring_size");
        row.shadow_size = reader.real("shadow_size");
        row.scale = reader.positive("scale");
        const std::optional<CreatureKind> kind = kind_of(reader.text("kind"));
        if (!kind) reader.reject("kind", "chỉ nhận npc hay monster");
        if (reader.error() || !kind) return std::unexpected(row_failure("creature_templates", reader));
        row.kind = *kind;
        rows.push_back(std::move(row));
    }
    std::ranges::sort(rows, {}, &CreatureTemplate::id);
    const auto twin = std::ranges::adjacent_find(rows, {}, &CreatureTemplate::id);
    if (twin != rows.end()) return std::unexpected(std::format("bảng creature_templates trùng template {}", twin->id));
    return rows;
}

[[nodiscard]] std::expected<std::vector<CreatureModel>, std::string> read_models(std::string_view text) {
    const auto table = parse_named({.name = "creatures", .columns = kModelColumns}, text);
    if (!table) return std::unexpected(table.error());
    std::vector<CreatureModel> rows;
    rows.reserve(table->rows.size());
    for (std::size_t at = 0; at < table->rows.size(); ++at) {
        table::RowReader reader(*table, at);
        CreatureModel row;
        row.id = reader.integer("model", 0, kMostModel);
        row.meshes = split_list(reader.text("meshes"));
        const std::string_view overlays = reader.text("materials");
        // Ô rỗng là không lưới nào có material chồng (split_view của chuỗi rỗng không cho phần tử nào).
        row.materials = overlays.empty() ? std::vector<std::string>(row.meshes.size()) : split_list(overlays);
        row.skeleton = reader.text("skeleton");
        row.scale = {reader.positive("sx"), reader.positive("sy"), reader.positive("sz")};
        row.height = reader.real("height");
        if (!reader.error() && row.materials.size() != row.meshes.size()) {
            reader.reject("materials", "số material khác số lưới");
        }
        if (reader.error()) return std::unexpected(row_failure("creatures", reader));
        rows.push_back(std::move(row));
    }
    std::ranges::sort(rows, {}, &CreatureModel::id);
    const auto twin = std::ranges::adjacent_find(rows, {}, &CreatureModel::id);
    if (twin != rows.end()) return std::unexpected(std::format("bảng creatures trùng model {}", twin->id));
    return rows;
}

[[nodiscard]] std::expected<std::vector<CreatureClip>, std::string> read_clips(std::string_view text) {
    const auto table = parse_named({.name = "creature_clips", .columns = kClipColumns}, text);
    if (!table) return std::unexpected(table.error());
    std::vector<CreatureClip> rows;
    rows.reserve(table->rows.size());
    for (std::size_t at = 0; at < table->rows.size(); ++at) {
        table::RowReader reader(*table, at);
        CreatureClip row;
        row.model = reader.integer("model", 0, kMostModel);
        const std::optional<CreatureKind> kind = kind_of(reader.text("kind"));
        if (!kind) reader.reject("kind", "chỉ nhận npc hay monster");
        const std::optional<CreatureAction> action = action_of(reader.text("action"));
        if (!action) reader.reject("action", "hành động lạ");
        row.clip.anim = reader.text("anim");
        row.clip.name = reader.text("clip");
        if (!reader.error() && (row.clip.anim.empty() || row.clip.name.empty())) {
            reader.reject("clip", "thiếu tệp hay tên animation");
        }
        if (reader.error() || !kind || !action) return std::unexpected(row_failure("creature_clips", reader));
        row.kind = *kind;
        row.action = *action;
        rows.push_back(std::move(row));
    }
    const auto key = [](const CreatureClip& clip) {
        return std::tuple{clip.model, static_cast<std::uint8_t>(clip.kind), static_cast<std::uint8_t>(clip.action)};
    };
    std::ranges::sort(rows, {}, key);
    const auto twin = std::ranges::adjacent_find(rows, [&](const CreatureClip& left, const CreatureClip& right) {
        return key(left) == key(right);
    });
    if (twin != rows.end()) {
        return std::unexpected(std::format("bảng creature_clips trùng dòng của mô hình {}", twin->model));
    }
    return rows;
}

[[nodiscard]] std::expected<std::vector<CreatureMaterial>, std::string> read_materials(std::string_view text) {
    const auto table = parse_named({.name = "creature_materials", .columns = kMaterialColumns}, text);
    if (!table) return std::unexpected(table.error());
    std::vector<CreatureMaterial> rows;
    rows.reserve(table->rows.size());
    for (std::size_t at = 0; at < table->rows.size(); ++at) {
        table::RowReader reader(*table, at);
        CreatureMaterial row;
        row.name = reader.text("material");
        row.texture = reader.text("texture");
        const std::optional<OverlayAlpha> alpha = alpha_of(reader.text("alpha"));
        if (!alpha) reader.reject("alpha", "chỉ nhận OPAQUE, MASK hay BLEND");
        row.double_sided = reader.flag("double_sided");
        row.unlit = reader.flag("unlit");
        if (!reader.error() && alpha == OverlayAlpha::kMask) row.cutoff = reader.positive("cutoff");
        if (!reader.error() && (row.name.empty() || row.texture.empty())) {
            reader.reject("material", "thiếu tên hay ảnh");
        }
        if (reader.error() || !alpha) return std::unexpected(row_failure("creature_materials", reader));
        row.alpha = *alpha;
        rows.push_back(std::move(row));
    }
    std::ranges::sort(rows, {}, &CreatureMaterial::name);
    const auto twin = std::ranges::adjacent_find(rows, {}, &CreatureMaterial::name);
    if (twin != rows.end()) return std::unexpected(std::format("bảng creature_materials trùng {}", twin->name));
    return rows;
}

[[nodiscard]] std::optional<Clip> clip_of(const CreatureTables& tables, std::int32_t model, CreatureKind kind,
    CreatureAction action) {
    const CreatureClip* found = tables.find_clip(model, kind, action);
    if (found == nullptr) return std::nullopt;
    return found->clip;
}

} // namespace

const CreatureTemplate* CreatureTables::find_template(std::uint32_t id) const noexcept {
    const auto found = std::ranges::lower_bound(templates, id, {}, &CreatureTemplate::id);
    return found != templates.end() && found->id == id ? &*found : nullptr;
}

const CreatureModel* CreatureTables::find_model(std::int32_t id) const noexcept {
    const auto found = std::ranges::lower_bound(models, id, {}, &CreatureModel::id);
    return found != models.end() && found->id == id ? &*found : nullptr;
}

const CreatureMaterial* CreatureTables::find_material(std::string_view name) const noexcept {
    const auto found = std::ranges::lower_bound(materials, name, {}, &CreatureMaterial::name);
    return found != materials.end() && found->name == name ? &*found : nullptr;
}

const CreatureClip* CreatureTables::find_clip(std::int32_t model, CreatureKind kind,
    CreatureAction action) const noexcept {
    const auto key = [](const CreatureClip& clip) {
        return std::tuple{clip.model, static_cast<std::uint8_t>(clip.kind), static_cast<std::uint8_t>(clip.action)};
    };
    const std::tuple wanted{model, static_cast<std::uint8_t>(kind), static_cast<std::uint8_t>(action)};
    const auto found = std::ranges::lower_bound(clips, wanted, {}, key);
    return found != clips.end() && key(*found) == wanted ? &*found : nullptr;
}

std::expected<CreatureTables, std::string> parse_creature_tables(const CreatureTexts& texts) {
    CreatureTables tables;
    auto templates = read_templates(texts.templates);
    if (!templates) return std::unexpected(templates.error());
    tables.templates = std::move(*templates);
    auto models = read_models(texts.models);
    if (!models) return std::unexpected(models.error());
    tables.models = std::move(*models);
    auto clips = read_clips(texts.clips);
    if (!clips) return std::unexpected(clips.error());
    tables.clips = std::move(*clips);
    auto materials = read_materials(texts.materials);
    if (!materials) return std::unexpected(materials.error());
    tables.materials = std::move(*materials);
    return tables;
}

std::expected<CreatureFigure, std::string> creature_figure(const CreatureTables& tables, std::uint32_t template_id) {
    const CreatureTemplate* row = tables.find_template(template_id);
    if (row == nullptr) return std::unexpected(std::format("template {} không có trong bảng quái", template_id));
    const CreatureModel* model = tables.find_model(row->model);
    if (model == nullptr) return std::unexpected(std::format("template {} trỏ mô hình {} không có", template_id, row->model));
    if (model->meshes.empty()) return std::unexpected(std::format("mô hình {} không có lưới", model->id));

    CreatureFigure made;
    made.kind = row->kind;
    made.plate_height = row->plate_height;
    made.height = model->height;
    for (std::size_t axis = 0; axis < made.scale.size(); ++axis) made.scale.at(axis) = row->scale * model->scale.at(axis);
    for (std::size_t at = 0; at < model->meshes.size(); ++at) {
        if (model->meshes.at(at).empty()) continue;
        Part part;
        part.mesh = model->meshes.at(at);
        if (!model->materials.at(at).empty()) part.materials.push_back(model->materials.at(at));
        made.figure.parts.push_back(std::move(part));
    }
    if (made.figure.parts.empty()) return std::unexpected(std::format("mô hình {} chỉ có lưới rỗng", model->id));

    made.figure.skeleton = model->skeleton;
    const std::int32_t id = model->id;
    const CreatureKind kind = row->kind;
    std::optional<Clip> idle = clip_of(tables, id, kind, CreatureAction::kIdle);
    if (!idle) idle = clip_of(tables, id, kind, CreatureAction::kDefault);
    made.is_animated = !model->skeleton.empty() && idle.has_value();
    if (!made.is_animated) return made;
    made.figure.idle = *idle;
    made.figure.idle_alt = clip_of(tables, id, kind, CreatureAction::kIdleAlt);
    made.figure.idle_alt2 = clip_of(tables, id, kind, CreatureAction::kIdleAlt2);
    made.walk = clip_of(tables, id, kind, CreatureAction::kWalk);
    const std::optional<Clip> run = clip_of(tables, id, kind, CreatureAction::kRun);
    made.figure.run = run ? *run : (made.walk ? *made.walk : *idle);
    made.death = clip_of(tables, id, kind, CreatureAction::kDeath);
    made.corpse = clip_of(tables, id, kind, CreatureAction::kCorpse);
    return made;
}

std::expected<CreatureTables, std::string> load_creature_tables(std::string_view folder, const ReadFile& read) {
    const auto text_of = [&](std::string_view name) -> std::expected<std::string, std::string> {
        const std::string path = std::format("{}/{}", folder, name);
        return read(path);
    };
    auto templates = text_of("creature_templates.tsv");
    if (!templates) return std::unexpected(templates.error());
    auto models = text_of("creatures.tsv");
    if (!models) return std::unexpected(models.error());
    auto clips = text_of("creature_clips.tsv");
    if (!clips) return std::unexpected(clips.error());
    auto materials = text_of("creature_materials.tsv");
    if (!materials) return std::unexpected(materials.error());
    return parse_creature_tables(
        CreatureTexts{.templates = *templates, .models = *models, .clips = *clips, .materials = *materials});
}

} // namespace game::look
