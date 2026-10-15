/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/play/world.cpp
 *  PHÂN HỆ   : Server / Play / World
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Nạp dữ liệu chơi từ dev/server/tables một lần lúc zone khởi động: nhiệm
 *    vụ, hội thoại, chữ, thân thể, vật phẩm.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "play/world.hpp"

#include "actor/body.hpp"
#include "actor/rules.hpp"
#include "handlers/registry.hpp"
#include "io/file.hpp"
#include "item/catalog.hpp"
#include "item/limits.hpp"
#include "mission/catalog.hpp"
#include "ops/ops.hpp"
#include "play/text.hpp"
#include "table/tsv.hpp"
#include "talk/handler.hpp"
#include "talk/script.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <filesystem>
#include <memory>
#include <span>
#include <string>
#include <string_view>
#include <utility>

namespace game::play {

namespace fs = std::filesystem;

struct World::Data {
    // Các phần chỉ có sau khi nạp xong, nên giữ bằng con trỏ: World dựng được thì chúng luôn có.
    std::unique_ptr<mission::Catalog> catalog;
    std::unique_ptr<talk::Script> script;
    TextBook text;
    std::unique_ptr<actor::Rules> rules;
    actor::BodyLimits body_limits;
    std::unique_ptr<item::Catalog> items;
    item::Limits item_limits;
};

namespace {

[[nodiscard]] std::expected<std::string, std::string> read(const fs::path& dir, std::string_view relative) {
    const fs::path path = dir / fs::path{std::string{relative}};
    io::TextResult text = io::read_text(path);
    if (!text) return std::unexpected(std::string{relative} + ": " + std::string{io::describe(text.error())});
    return std::move(*text);
}

[[nodiscard]] std::expected<table::Tsv, std::string> read_table(const fs::path& dir, std::string_view relative) {
    std::expected<std::string, std::string> text = read(dir, relative);
    if (!text) return std::unexpected(text.error());
    table::TsvResult parsed = table::parse_tsv(*text);
    if (!parsed) return std::unexpected(std::string{relative} + ": " + parsed.error());
    return std::move(*parsed);
}

// Nạp các bảng chữ theo thứ tự đè nhau. Bảng vắng thì bỏ qua (nhà phát hành có thể không có tệp đè); bảng hỏng thì lỗi.
[[nodiscard]] std::expected<void, std::string> load_text(TextBook& book, const Paths& paths) {
    const std::string name = "dialogue." + paths.language + ".txt";
    const std::array<fs::path, 3> sources{paths.tables / "client" / "StrDictionary.tsv", paths.tables / "server" / name,
        paths.text_override.empty() ? fs::path{} : paths.text_override / name};
    for (const fs::path& source : sources) {
        if (source.empty()) continue;
        io::TextResult text = io::read_text(source);
        if (!text) continue;
        const table::TsvResult parsed = table::parse_tsv(*text);
        if (!parsed) return std::unexpected(io::utf8_of(source) + ": " + parsed.error());
        book.add(*parsed);
    }
    return {};
}

} // namespace

World::World(std::unique_ptr<Data> data) noexcept : data_(std::move(data)) {}
World::World(World&&) noexcept = default;
World& World::operator=(World&&) noexcept = default;
World::~World() = default;

std::expected<World, std::string> World::load(const Paths& paths) {
    auto data = std::make_unique<Data>();
    const fs::path server = paths.tables / "server";

    // ---- nhiệm vụ và hội thoại: 14 bảng do lua_extract.py trích ----
    struct Named {
        table::Tsv blocks, entries, roles, events, quests, objectives, rewards, prereqs, hooks, npcs, autos, groups, conditions,
            effects;
    } all;
    const std::array<std::pair<table::Tsv*, std::string_view>, 14> files{{{&all.blocks, "talk_blocks.tsv"},
        {&all.entries, "talk_entries.tsv"}, {&all.roles, "talk_npc_roles.tsv"}, {&all.events, "talk_npc_events.tsv"},
        {&all.quests, "mission_quests.tsv"}, {&all.objectives, "mission_objectives.tsv"},
        {&all.rewards, "mission_rewards.tsv"}, {&all.prereqs, "mission_prereqs.tsv"}, {&all.hooks, "mission_hooks.tsv"},
        {&all.npcs, "mission_npcs.tsv"}, {&all.autos, "mission_auto.tsv"}, {&all.groups, "mission_name_groups.tsv"},
        {&all.conditions, "ops_conditions.tsv"}, {&all.effects, "ops_effects.tsv"}}};
    for (const auto& [target, relative] : files) {
        std::expected<table::Tsv, std::string> loaded = read_table(server, relative);
        if (!loaded) return std::unexpected(loaded.error());
        *target = std::move(*loaded);
    }
    auto program = ops::Program::load(all.conditions, all.effects);
    if (!program) return std::unexpected("ops: " + program.error().detail);
    const mission::Tables mission_tables{.quests = all.quests, .objectives = all.objectives, .rewards = all.rewards,
        .prereqs = all.prereqs, .hooks = all.hooks, .npcs = all.npcs, .autos = all.autos, .name_groups = all.groups};
    auto catalog = mission::Catalog::load(std::move(*program), mission_tables, {});
    if (!catalog) return std::unexpected("mission_" + catalog.error().table + ": " + catalog.error().detail);
    data->catalog = std::make_unique<mission::Catalog>(std::move(*catalog));
    auto script = talk::Script::load(data->catalog->program(),
        talk::Tables{.blocks = all.blocks, .entries = all.entries, .roles = all.roles, .events = all.events});
    if (!script) return std::unexpected("talk_" + script.error().table + ": " + script.error().detail);
    data->script = std::make_unique<talk::Script>(std::move(*script));

    // ---- chữ ----
    if (std::expected<void, std::string> texts = load_text(data->text, paths); !texts) return std::unexpected(texts.error());

    // ---- thân thể: 9 bảng của actor::RulesText ----
    const std::array<std::string_view, 9> actor_files{"server/sect_base_values.tsv", "server/sect_attribute_growth.tsv",
        "server/sect_templates.tsv", "server/sect_rage_rules.tsv", "shared/player_exp_levels.tsv",
        "server/exp_level_gap_factors.tsv", "server/death_penalties.tsv", "shared/monsters.tsv", "shared/inner_arts.tsv"};
    std::array<std::string, 9> actor_text;
    for (std::size_t at = 0; at < actor_files.size(); ++at) {
        std::expected<std::string, std::string> text = read(paths.tables, actor_files.at(at));
        if (!text) return std::unexpected(text.error());
        actor_text.at(at) = std::move(*text);
    }
    auto rules = actor::load_rules(actor::RulesText{.sect_base_values = actor_text[0], .sect_growth = actor_text[1],
        .sect_templates = actor_text[2], .sect_rage_rules = actor_text[3], .player_exp_levels = actor_text[4],
        .exp_level_gap = actor_text[5], .death_penalties = actor_text[6], .monsters = actor_text[7],
        .inner_arts = actor_text[8]});
    if (!rules) return std::unexpected("actor: " + rules.error().what);
    data->rules = std::make_unique<actor::Rules>(std::move(*rules));

    // ---- vật phẩm ----
    const std::array<std::string_view, 6> item_files{"shared/item_rules.tsv", "shared/items_common.tsv",
        "shared/equipment.tsv", "shared/gems.tsv", "shared/pet_equipment_base.tsv", "shared/money_caps_by_level.tsv"};
    std::array<std::string, 6> item_text;
    for (std::size_t at = 0; at < item_files.size(); ++at) {
        std::expected<std::string, std::string> text = read(paths.tables, item_files.at(at));
        if (!text) return std::unexpected(text.error());
        item_text.at(at) = std::move(*text);
    }
    auto items = item::Catalog::load(item::CatalogSources{.rules = item_text[0], .common = item_text[1],
        .equipment = item_text[2], .gems = item_text[3], .pet_equipment = item_text[4], .extra_attributes = {}});
    if (!items) return std::unexpected("item: " + items.error());
    data->items = std::make_unique<item::Catalog>(std::move(*items));
    std::expected<std::string, std::string> limits_text = read(paths.tables, "server/item_limits.tsv");
    if (!limits_text) return std::unexpected(limits_text.error());
    auto limits = item::Limits::load(item::LimitSources{.limits = *limits_text, .gold_caps = item_text[5]});
    if (!limits) return std::unexpected("item_limits: " + limits.error());
    data->item_limits = std::move(*limits);

    return World{std::move(data)};
}

const mission::Catalog& World::catalog() const noexcept { return *data_->catalog; }
const talk::Script& World::script() const noexcept { return *data_->script; }
const TextBook& World::text() const noexcept { return data_->text; }
const actor::Rules& World::rules() const noexcept { return *data_->rules; }
const actor::BodyLimits& World::body_limits() const noexcept { return data_->body_limits; }
const item::Catalog& World::items() const noexcept { return *data_->items; }
const item::Limits& World::item_limits() const noexcept { return data_->item_limits; }
bool World::speaks(std::uint32_t script) const noexcept {
    // Chỉ NPC có hộp thoại gốc chạy được mới bấm được: điểm vào gốc chưa trích được thì Talk chỉ trả "không có hội thoại".
    const talk::Entry* const root = data_->script->entry(script, -1);
    return root != nullptr && root->status == talk::EntryStatus::kOk;
}
std::span<const talk::HandlerSpec> World::handlers() const noexcept { return handlers::registry(); }

} // namespace game::play
