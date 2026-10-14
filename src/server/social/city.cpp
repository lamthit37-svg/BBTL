#include "social/city.hpp"

#include "protocol/wire.hpp"
#include "social/codec.hpp"
#include "social/guild.hpp"
#include "social/limits.hpp"
#include "social/text.hpp"
#include "social/types.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <map>
#include <optional>
#include <set>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::social {
namespace {

constexpr std::uint16_t kCityVersion = 1;
constexpr std::size_t kMaxCities = 1024;
constexpr std::size_t kMaxBuildingRows = 20'000;
constexpr std::size_t kMaxBuildingsPerCity = 256;
constexpr std::uint8_t kMaxBuildingLevel = 5;
constexpr std::uint8_t kCountyBuildingType = 0;
constexpr std::size_t kMaxNameBytes = 63;

[[nodiscard]] CityResult reject(CityError error) {
    CityResult result;
    result.error = error;
    return result;
}

[[nodiscard]] BuildingLevel* find_level(std::vector<BuildingLevel>& levels, std::uint32_t building) noexcept {
    const auto found = std::ranges::lower_bound(levels, building, {}, &BuildingLevel::building);
    return found == levels.end() || found->building != building ? nullptr : &*found;
}

[[nodiscard]] const BuildingLevel* find_level(const std::vector<BuildingLevel>& levels, std::uint32_t building) noexcept {
    const auto found = std::ranges::lower_bound(levels, building, {}, &BuildingLevel::building);
    return found == levels.end() || found->building != building ? nullptr : &*found;
}

[[nodiscard]] const CityBuildingInfo* find_info(const std::vector<CityBuildingInfo>& infos, std::uint32_t building) noexcept {
    const auto found = std::ranges::find(infos, building, &CityBuildingInfo::id);
    return found == infos.end() ? nullptr : &*found;
}

// Mã của công trình nha môn trong một thành phố, nếu danh mục có.
[[nodiscard]] std::optional<std::uint32_t> county_building(const std::vector<CityBuildingInfo>& infos) noexcept {
    const auto found = std::ranges::find(infos, kCountyBuildingType, &CityBuildingInfo::type);
    if (found == infos.end()) return std::nullopt;
    return found->id;
}

} // namespace

std::string_view describe(CityError error) noexcept {
    switch (error) {
    case CityError::kNotInGuild: return "chưa vào bang";
    case CityError::kNotChief: return "chỉ bang chủ làm được";
    case CityError::kUnknownCity: return "thành phố không tồn tại";
    case CityError::kTaken: return "thành phố đã có chủ";
    case CityError::kHasCity: return "bang đã có thành phố";
    case CityError::kNoCity: return "bang chưa có thành phố";
    case CityError::kNotEnoughMoney: return "quỹ bang không đủ";
    case CityError::kMaxLevel: return "đã đạt cấp tối đa";
    case CityError::kUnknownBuilding: return "công trình không tồn tại hoặc không nâng cấp được";
    case CityError::kCountyLevelTooLow: return "cấp nha môn chưa đủ";
    case CityError::kBadValue: return "giá trị không hợp lệ";
    }
    return "lỗi thành phố lạ";
}

// ---------------------------------------------------------------------------------------------
// CityCatalog
// ---------------------------------------------------------------------------------------------

std::expected<CityCatalog, std::string> CityCatalog::parse(const CitySources& sources) {
    CityCatalog out;
    auto cities = table::parse_tsv(sources.cities_tsv);
    if (!cities) return std::unexpected(std::move(cities.error()));
    if (cities->rows.size() > kMaxCities) return std::unexpected("bảng thành phố quá trần");
    std::map<std::uint32_t, CityId> by_scene;
    std::set<CityId> seen_ids;
    for (std::size_t row = 0; row < cities->rows.size(); ++row) {
        table::RowReader reader(*cities, row);
        CityInfo info;
        info.id = CityId{reader.number("id", 1, 1'000'000)};
        info.scene = reader.number("scene_id", 0, 10'000'000);
        const std::string_view name = reader.text("name");
        if (reader.error()) return std::unexpected(*reader.error());
        if (!is_plain_text(name, kMaxNameBytes) || name.empty()) {
            return std::unexpected(std::format("dòng {}: tên thành phố sai", cities->lines[row]));
        }
        info.name = std::string(name);
        if (!seen_ids.insert(info.id).second || by_scene.contains(info.scene)) {
            return std::unexpected(std::format("dòng {}: trùng id hoặc cảnh thành phố", cities->lines[row]));
        }
        by_scene.emplace(info.scene, info.id);
        out.cities_.push_back(std::move(info));
    }
    std::ranges::sort(out.cities_, {}, &CityInfo::id);
    std::map<CityId, std::vector<CityBuildingInfo>> grouped;
    auto buildings = table::parse_tsv(sources.buildings_tsv);
    if (!buildings) return std::unexpected(std::move(buildings.error()));
    if (buildings->rows.size() > kMaxBuildingRows) return std::unexpected("bảng công trình quá trần");
    for (std::size_t row = 0; row < buildings->rows.size(); ++row) {
        table::RowReader reader(*buildings, row);
        const std::uint32_t scene = reader.number("city_id", 0, 10'000'000);
        CityBuildingInfo info;
        info.id = reader.number("building_id", 0, 1'000'000);
        info.type = static_cast<std::uint8_t>(reader.number("building_type", 0, 255));
        info.initial_level = static_cast<std::uint8_t>(reader.number("initial_level", 0, kMaxBuildingLevel));
        const std::string_view name = reader.text("name");
        if (reader.error()) return std::unexpected(*reader.error());
        const auto city = by_scene.find(scene);
        if (city == by_scene.end()) {
            return std::unexpected(std::format("dòng {}: công trình trỏ vào cảnh {} không phải thành phố", buildings->lines[row], scene));
        }
        info.name = std::string(name);
        std::vector<CityBuildingInfo>& list = grouped[city->second];
        if (list.size() >= kMaxBuildingsPerCity) return std::unexpected("thành phố có quá nhiều công trình");
        if (find_info(list, info.id) != nullptr) {
            return std::unexpected(std::format("dòng {}: trùng mã công trình {}", buildings->lines[row], info.id));
        }
        list.push_back(std::move(info));
    }
    for (auto& [id, list] : grouped) {
        std::ranges::sort(list, {}, &CityBuildingInfo::id);
        if (std::ranges::count(list, kCountyBuildingType, &CityBuildingInfo::type) > 1) {
            return std::unexpected(std::format("thành phố {} có nhiều hơn một nha môn", id.value()));
        }
        out.buildings_.emplace_back(id, std::move(list));
    }
    return out;
}

const CityInfo* CityCatalog::find(CityId id) const {
    const auto found = std::ranges::lower_bound(cities_, id, {}, &CityInfo::id);
    return found == cities_.end() || found->id != id ? nullptr : &*found;
}

const std::vector<CityBuildingInfo>* CityCatalog::buildings_of(CityId id) const {
    const auto found = std::ranges::lower_bound(buildings_, id, {}, &std::pair<CityId, std::vector<CityBuildingInfo>>::first);
    return found == buildings_.end() || found->first != id ? nullptr : &found->second;
}

std::size_t CityCatalog::building_count() const noexcept {
    std::size_t total = 0;
    for (const auto& entry : buildings_) total += entry.second.size();
    return total;
}

// ---------------------------------------------------------------------------------------------
// CityBook
// ---------------------------------------------------------------------------------------------

CityBook::CityBook(const GuildRules& rules, const CityCatalog& catalog) : rules_(rules), catalog_(&catalog) {}

CityState CityBook::fresh_state(CityId city) const {
    CityState state;
    state.id = city;
    if (const auto* infos = catalog_->buildings_of(city)) {
        state.buildings.reserve(infos->size());
        for (const CityBuildingInfo& info : *infos) state.buildings.push_back(BuildingLevel{.building = info.id, .level = info.initial_level});
    }
    return state;
}

std::optional<GuildId> CityBook::owner_of(CityId city) const {
    const auto found = states_.find(city);
    if (found == states_.end() || found->second.owner.value() == 0) return std::nullopt;
    return found->second.owner;
}

std::optional<CityId> CityBook::city_of(GuildId guild) const {
    const auto found = by_guild_.find(guild);
    if (found == by_guild_.end()) return std::nullopt;
    return found->second;
}

const CityState* CityBook::state(CityId city) const {
    const auto found = states_.find(city);
    return found == states_.end() ? nullptr : &found->second;
}

std::optional<std::uint8_t> CityBook::building_level(CityId city, std::uint32_t building) const {
    const CityState* held = state(city);
    if (held == nullptr) {
        const auto* infos = catalog_->buildings_of(city);
        const CityBuildingInfo* info = infos == nullptr ? nullptr : find_info(*infos, building);
        if (info == nullptr) return std::nullopt;
        return info->initial_level;
    }
    const BuildingLevel* level = find_level(held->buildings, building);
    if (level == nullptr) return std::nullopt;
    return level->level;
}

CityResult CityBook::claim(GuildBook& guilds, CharacterId actor, CityId city) {
    const auto guild_id = guilds.guild_of(actor);
    if (!guild_id) return reject(CityError::kNotInGuild);
    const GuildMember* self = guilds.member(actor);
    if (self == nullptr || self->position != GuildPosition::kChief) return reject(CityError::kNotChief);
    const Guild* guild = guilds.find(*guild_id);
    if (guild == nullptr) return reject(CityError::kNotInGuild);
    if (guild->city.value() != 0 || by_guild_.contains(*guild_id)) return reject(CityError::kHasCity);
    if (catalog_->find(city) == nullptr) return reject(CityError::kUnknownCity);
    if (owner_of(city)) return reject(CityError::kTaken);
    if (guild->funds < rules_.city_cost) return reject(CityError::kNotEnoughMoney);
    // Phí lập thành trừ thẳng quỹ bang (không về túi ai). Kiểm đủ ở trên nên lệnh rút không thất bại.
    if (rules_.city_cost > 0 && !guilds.withdraw(actor, rules_.city_cost).ok()) return reject(CityError::kNotEnoughMoney);
    if (!guilds.set_county(*guild_id, 1, city)) return reject(CityError::kBadValue);
    CityState fresh = fresh_state(city);
    fresh.owner = *guild_id;
    if (const auto* infos = catalog_->buildings_of(city)) {
        if (const auto county = county_building(*infos)) {
            if (BuildingLevel* level = find_level(fresh.buildings, *county)) level->level = 1;
        }
    }
    states_.insert_or_assign(city, std::move(fresh));
    by_guild_.insert_or_assign(*guild_id, city);
    CityResult result;
    result.events.push_back(CityEvent{.kind = CityEventKind::kClaimed, .city = city, .guild = *guild_id, .subject = actor, .value = rules_.city_cost});
    return result;
}

CityResult CityBook::release(GuildBook& guilds, CharacterId actor) {
    const auto guild_id = guilds.guild_of(actor);
    if (!guild_id) return reject(CityError::kNotInGuild);
    const GuildMember* self = guilds.member(actor);
    if (self == nullptr || self->position != GuildPosition::kChief) return reject(CityError::kNotChief);
    const auto held = city_of(*guild_id);
    if (!held) return reject(CityError::kNoCity);
    if (!guilds.set_county(*guild_id, 0, CityId{})) return reject(CityError::kBadValue);
    states_.insert_or_assign(*held, fresh_state(*held));
    by_guild_.erase(*guild_id);
    CityResult result;
    result.events.push_back(CityEvent{.kind = CityEventKind::kReleased, .city = *held, .guild = *guild_id, .subject = actor});
    return result;
}

CityResult CityBook::upgrade_county(GuildBook& guilds, CharacterId actor) {
    const auto guild_id = guilds.guild_of(actor);
    if (!guild_id) return reject(CityError::kNotInGuild);
    const GuildMember* self = guilds.member(actor);
    if (self == nullptr || self->position != GuildPosition::kChief) return reject(CityError::kNotChief);
    const Guild* guild = guilds.find(*guild_id);
    const auto held = city_of(*guild_id);
    if (guild == nullptr || !held || guild->level == 0) return reject(CityError::kNoCity);
    if (guild->level >= kMaxBuildingLevel) return reject(CityError::kMaxLevel);
    if (guild->funds < rules_.county_standard_money.at(std::size_t{guild->level} - 1U)) return reject(CityError::kNotEnoughMoney);
    const auto next = static_cast<std::uint8_t>(guild->level + 1U);
    if (!guilds.set_county(*guild_id, next, *held)) return reject(CityError::kBadValue);
    CityState& held_state = states_.at(*held);
    if (const auto* infos = catalog_->buildings_of(*held)) {
        if (const auto county = county_building(*infos)) {
            if (BuildingLevel* level = find_level(held_state.buildings, *county)) level->level = next;
        }
    }
    CityResult result;
    result.events.push_back(CityEvent{
        .kind = CityEventKind::kCountyUpgraded, .city = *held, .guild = *guild_id, .subject = actor, .value = next});
    return result;
}

CityResult CityBook::upgrade_building(GuildBook& guilds, CharacterId actor, std::uint32_t building) {
    const auto guild_id = guilds.guild_of(actor);
    if (!guild_id) return reject(CityError::kNotInGuild);
    const GuildMember* self = guilds.member(actor);
    if (self == nullptr || self->position != GuildPosition::kChief) return reject(CityError::kNotChief);
    const Guild* guild = guilds.find(*guild_id);
    const auto held = city_of(*guild_id);
    if (guild == nullptr || !held) return reject(CityError::kNoCity);
    const auto* infos = catalog_->buildings_of(*held);
    const CityBuildingInfo* info = infos == nullptr ? nullptr : find_info(*infos, building);
    if (info == nullptr || info->type == kCountyBuildingType) return reject(CityError::kUnknownBuilding);
    CityState& held_state = states_.at(*held);
    BuildingLevel* level = find_level(held_state.buildings, building);
    if (level == nullptr) return reject(CityError::kUnknownBuilding);
    if (level->level >= kMaxBuildingLevel) return reject(CityError::kMaxLevel);
    if (level->level + 1U > guild->level) return reject(CityError::kCountyLevelTooLow);
    ++level->level;
    CityResult result;
    result.events.push_back(CityEvent{.kind = CityEventKind::kBuildingUpgraded,
        .city = *held,
        .guild = *guild_id,
        .subject = actor,
        .building = building,
        .value = level->level});
    return result;
}

std::expected<void, std::string> CityBook::load(CityState incoming) {
    const auto* infos = catalog_->buildings_of(incoming.id);
    if (catalog_->find(incoming.id) == nullptr) return std::unexpected("thành phố không có trong danh mục");
    if (states_.contains(incoming.id)) return std::unexpected("trùng thành phố");
    if (incoming.owner.value() != 0 && by_guild_.contains(incoming.owner)) return std::unexpected("bang đã giữ thành phố khác");
    std::uint32_t previous = 0;
    bool first = true;
    for (const BuildingLevel& level : incoming.buildings) {
        if (!first && level.building <= previous) return std::unexpected("công trình không xếp tăng hoặc trùng");
        first = false;
        previous = level.building;
        if (infos == nullptr || find_info(*infos, level.building) == nullptr) return std::unexpected("công trình không có trong danh mục");
        if (level.level > kMaxBuildingLevel) return std::unexpected("cấp công trình ngoài miền");
    }
    if (infos != nullptr && incoming.buildings.size() != infos->size()) return std::unexpected("thiếu công trình so với danh mục");
    if (incoming.owner.value() != 0) by_guild_.insert_or_assign(incoming.owner, incoming.id);
    const CityId id = incoming.id;
    states_.insert_or_assign(id, std::move(incoming));
    return {};
}

std::expected<void, std::string> CityBook::validate(const GuildBook& guilds) const {
    std::size_t owned = 0;
    for (const auto& [id, held] : states_) {
        if (held.id != id) return std::unexpected("khoá thành phố lệch id");
        if (held.owner.value() == 0) continue;
        ++owned;
        const Guild* guild = guilds.find(held.owner);
        if (guild == nullptr) return std::unexpected(std::format("thành phố {} thuộc bang không có", id.value()));
        if (guild->city != id || guild->level < 1 || guild->level > kMaxBuildingLevel) {
            return std::unexpected(std::format("bang {} và thành phố {} lệch nhau", held.owner.value(), id.value()));
        }
        const auto indexed = by_guild_.find(held.owner);
        if (indexed == by_guild_.end() || indexed->second != id) return std::unexpected("chỉ mục bang - thành phố lệch");
        if (const auto* infos = catalog_->buildings_of(id)) {
            if (const auto county = county_building(*infos)) {
                const BuildingLevel* level = find_level(held.buildings, *county);
                if (level == nullptr || level->level != guild->level) {
                    return std::unexpected(std::format("nha môn thành phố {} lệch cấp bang", id.value()));
                }
            }
        }
    }
    if (owned != by_guild_.size()) return std::unexpected("chỉ mục bang - thành phố thừa mục");
    return {};
}

// ---------------------------------------------------------------------------------------------
// Mã hoá
// ---------------------------------------------------------------------------------------------

CodecResult encode_city(const CityState& state, Bytes& out) {
    protocol::Writer writer(out);
    writer.u16(kCityVersion);
    writer.u32(state.id.value());
    writer.u64(state.owner.value());
    writer.count(state.buildings.size(), kMaxBuildingsPerCity);
    for (const BuildingLevel& level : state.buildings) {
        writer.u32(level.building);
        writer.u8(level.level);
    }
    return finish_blob(writer, blob::kCity);
}

std::expected<CityState, CodecError> decode_city(std::span<const std::byte> bytes) {
    const auto body = open_blob(bytes, blob::kCity);
    if (!body) return std::unexpected(body.error());
    protocol::Reader reader(*body);
    const std::uint16_t version = reader.u16();
    if (!reader.is_ok()) return std::unexpected(CodecError::kTruncated);
    if (version != kCityVersion) return std::unexpected(CodecError::kBadVersion);
    CityState state;
    state.id = CityId{reader.u32()};
    state.owner = GuildId{reader.u64()};
    const std::size_t count = reader.count(kMaxBuildingsPerCity);
    if (!reader.is_ok()) return std::unexpected(CodecError::kTruncated);
    state.buildings.reserve(count);
    for (std::size_t index = 0; index < count && reader.is_ok(); ++index) {
        BuildingLevel level;
        level.building = reader.u32();
        level.level = reader.u8();
        state.buildings.push_back(level);
    }
    if (const auto done = finish_read(reader); !done) return std::unexpected(done.error());
    if (state.id.value() == 0) return std::unexpected(CodecError::kBadValue);
    std::uint32_t previous = 0;
    bool first = true;
    for (const BuildingLevel& level : state.buildings) {
        if (level.level > kMaxBuildingLevel || (!first && level.building <= previous)) return std::unexpected(CodecError::kBadValue);
        first = false;
        previous = level.building;
    }
    return state;
}

} // namespace game::social
