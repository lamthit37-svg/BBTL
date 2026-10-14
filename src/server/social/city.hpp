#pragma once
// Thành phố và nha môn của bang: danh mục thành phố/công trình từ bảng, bang chiếm và trả thành phố,
// nâng cấp nha môn (quyết định trần thành viên và trần quỹ của bang) và nâng cấp công trình. Lõi thuần.
//
// Nguồn: CityInfo.txt và CityBuilding.txt của client 2026 (dev/server/tables/shared/guild_cities.tsv và
// city_buildings.tsv); phí lập thành (city_cost) và quỹ chuẩn từng cấp nha môn (standard_money) theo
// dev/server/config/rules/guild.toml.
// Khác gốc / giả định (ghi ở docs/SERVER-SOCIAL.md): (1) cột city_id của CityBuilding là SCENE id của
// thành phố (khớp scene_id của CityInfo), không phải id của CityInfo; (2) cấp nha môn = cấp của bang
// (1..5), công trình loại 0 là nha môn; (3) nâng nha môn lên cấp kế cần quỹ bang có ít nhất standard_money
// của cấp hiện tại (đặt giả định, quỹ không bị trừ); (4) công trình thường chỉ nâng từng cấp và không cao
// hơn cấp nha môn; chi phí nâng công trình và nghiên cứu (level_require, research_item, maintain) chưa
// rõ nghĩa các cột nên chưa làm.

#include "social/codec.hpp"
#include "social/guild.hpp"
#include "social/limits.hpp"
#include "social/types.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <map>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::social {

// Nội dung hai bảng đã nạp vào bộ nhớ.
struct CitySources {
    std::string_view cities_tsv;     // guild_cities.tsv
    std::string_view buildings_tsv;  // city_buildings.tsv
};

struct CityInfo {
    CityId id{};
    std::uint32_t scene = 0;
    std::string name;
};

struct CityBuildingInfo {
    std::uint32_t id = 0;
    std::uint8_t type = 0;           // 0 = nha môn
    std::uint8_t initial_level = 0;  // 0..5
    std::string name;
};

class CityCatalog {
public:
    [[nodiscard]] static std::expected<CityCatalog, std::string> parse(const CitySources& sources);

    [[nodiscard]] const CityInfo* find(CityId id) const;
    [[nodiscard]] const std::vector<CityBuildingInfo>* buildings_of(CityId id) const;
    [[nodiscard]] std::size_t size() const noexcept { return cities_.size(); }
    [[nodiscard]] std::size_t building_count() const noexcept;

private:
    std::vector<CityInfo> cities_;  // xếp tăng theo id
    std::vector<std::pair<CityId, std::vector<CityBuildingInfo>>> buildings_;  // xếp tăng theo id thành phố
};

enum class CityError : std::uint8_t {
    kNotInGuild = 1,
    kNotChief,
    kUnknownCity,
    kTaken,
    kHasCity,
    kNoCity,
    kNotEnoughMoney,
    kMaxLevel,
    kUnknownBuilding,
    kCountyLevelTooLow,
    kBadValue,
};

[[nodiscard]] std::string_view describe(CityError error) noexcept;

struct BuildingLevel {
    std::uint32_t building = 0;
    std::uint8_t level = 0;
};

struct CityState {
    CityId id{};
    GuildId owner{};                      // 0 = chưa có chủ
    std::vector<BuildingLevel> buildings;  // xếp tăng theo mã công trình
};

enum class CityEventKind : std::uint8_t {
    kClaimed,         // city, guild; subject = bang chủ; value = phí
    kReleased,        // city, guild
    kCountyUpgraded,  // city, guild; value = cấp mới
    kBuildingUpgraded // city, guild; value = cấp mới; building
};

struct CityEvent {
    CityEventKind kind = CityEventKind::kClaimed;
    CityId city{};
    GuildId guild{};
    CharacterId subject{};
    std::uint32_t building = 0;
    std::int64_t value = 0;
};

using CityResult = Outcome<CityEvent, CityError>;

class CityBook {
public:
    // `catalog` phải sống lâu hơn CityBook.
    CityBook(const GuildRules& rules, const CityCatalog& catalog);

    // Bang chủ cho bang chiếm một thành phố trống, trả city_cost bằng quỹ bang. Cấp nha môn thành 1.
    [[nodiscard]] CityResult claim(GuildBook& guilds, CharacterId actor, CityId city);
    // Bang chủ trả thành phố; công trình về cấp ban đầu.
    [[nodiscard]] CityResult release(GuildBook& guilds, CharacterId actor);
    // Nâng nha môn lên cấp kế (tối đa 5).
    [[nodiscard]] CityResult upgrade_county(GuildBook& guilds, CharacterId actor);
    // Nâng một công trình thường lên một cấp, không cao hơn cấp nha môn.
    [[nodiscard]] CityResult upgrade_building(GuildBook& guilds, CharacterId actor, std::uint32_t building);

    [[nodiscard]] std::optional<GuildId> owner_of(CityId city) const;
    [[nodiscard]] std::optional<CityId> city_of(GuildId guild) const;
    [[nodiscard]] std::optional<std::uint8_t> building_level(CityId city, std::uint32_t building) const;
    [[nodiscard]] const CityState* state(CityId city) const;
    [[nodiscard]] std::size_t owned_count() const noexcept { return by_guild_.size(); }

    // Nạp trạng thái đọc từ kho (đã qua decode_city). Lỗi: thành phố lạ, công trình lạ, cấp quá trần,
    // bang đã giữ thành phố khác.
    [[nodiscard]] std::expected<void, std::string> load(CityState incoming);
    // Mọi thành phố có chủ: bang có thật, cấp nha môn của bang khớp công trình nha môn, chỉ mục khớp.
    [[nodiscard]] std::expected<void, std::string> validate(const GuildBook& guilds) const;

private:
    [[nodiscard]] CityState fresh_state(CityId city) const;

    GuildRules rules_;
    const CityCatalog* catalog_;
    std::map<CityId, CityState> states_;
    std::map<GuildId, CityId> by_guild_;
};

// Mã hoá/giải mã trạng thái một thành phố (blob::kCity, phiên bản 1).
[[nodiscard]] CodecResult encode_city(const CityState& state, Bytes& out);
[[nodiscard]] std::expected<CityState, CodecError> decode_city(std::span<const std::byte> bytes);

} // namespace game::social
