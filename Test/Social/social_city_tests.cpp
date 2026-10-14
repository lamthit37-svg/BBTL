// Thành phố của bang: danh mục từ bảng, chiếm/trả, nâng nha môn và công trình, khối lưu bền. Sai thì tiền
// bang biến mất hoặc hai bang cùng giữ một thành phố, nên mỗi ca gọi validate() ở cả hai sổ.
#include "ids/ids.hpp"
#include "social/city.hpp"
#include "social/codec.hpp"
#include "social/guild.hpp"
#include "social/policy.hpp"
#include "social/types.hpp"
#include "social_support.hpp"
#include "test.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using social::CityBook;
using social::CityCatalog;
using social::CityError;
using social::CityId;
using social::CityState;
using social::GuildBook;
using social::GuildId;
using social::Tick;

constexpr Tick kNow{1000};

constexpr std::string_view kCities =
    "# schema 1\nid\tscene_id\tname\n"
    "1\t205\tNhạn Nam\n"
    "2\t206\tNhạn Bắc\n";
constexpr std::string_view kBuildings =
    "# schema 1\ncity_id\tname\tbuilding_type\tbuilding_id\tinitial_level\n"
    "205\tNha môn\t0\t1\t0\n"
    "205\tCờ lớn\t17\t2\t0\n"
    "205\tVõ phường\t11\t4\t0\n"
    "206\tNha môn\t0\t1\t0\n";

struct World {
    FakeDirectory directory;
    social::AllowAllText policy;
    GuildBook guilds;
    CityCatalog catalog;
    CityBook cities;

    explicit World(std::uint64_t players)
        : guilds(sample_limits(), sample_guild_rules(), policy),
          catalog(CityCatalog::parse({.cities_tsv = kCities, .buildings_tsv = kBuildings}).value_or(CityCatalog{})),
          cities(sample_guild_rules(), catalog) {
        for (std::uint64_t id = 1; id <= players; ++id) directory.add(id, "p" + std::to_string(id), 50);
    }

    // Người `chief` lập bang rồi nộp `funds` vào quỹ.
    GuildId found(std::uint64_t chief, std::string_view name, social::Copper funds) {
        const auto made = guilds.create(kNow, directory, cid(chief), name, "", 1'000'000);
        if (!made.ok() || made.events.empty()) return GuildId{};
        if (funds > 0 && !guilds.deposit(cid(chief), funds, funds).ok()) return GuildId{};
        return made.events.front().guild;
    }
};

void expect_valid(Context& context, const World& world) {
    context.expect(world.guilds.validate().has_value(), "GuildBook::validate() đạt");
    context.expect(world.cities.validate(world.guilds).has_value(), "CityBook::validate() đạt");
}

void catalog_parse(Context& context) {
    const auto catalog = CityCatalog::parse({.cities_tsv = kCities, .buildings_tsv = kBuildings});
    context.expect(catalog.has_value() && catalog->size() == 2 && catalog->building_count() == 4, "đọc được danh mục");
    if (!catalog) return;
    context.expect(catalog->find(CityId{1}) != nullptr && catalog->find(CityId{1})->scene == 205, "scene_id");
    context.expect(catalog->buildings_of(CityId{1})->size() == 3 && catalog->buildings_of(CityId{9}) == nullptr, "công trình theo thành phố");
    const auto parse = [](std::string_view cities, std::string_view buildings) {
        return CityCatalog::parse({.cities_tsv = cities, .buildings_tsv = buildings}).has_value();
    };
    context.expect(!parse("id\tscene_id\tname\n1\t205\tA\n1\t206\tB\n", kBuildings), "trùng id thành phố");
    context.expect(!parse("id\tscene_id\tname\n1\t205\tA\n2\t205\tB\n", kBuildings), "trùng cảnh");
    context.expect(!parse("id\tscene_id\tname\n1\t205\t\n", kBuildings), "tên rỗng");
    context.expect(!parse(kCities, "city_id\tname\tbuilding_type\tbuilding_id\tinitial_level\n999\tx\t0\t1\t0\n"), "công trình trỏ vào cảnh lạ");
    context.expect(!parse(kCities, "city_id\tname\tbuilding_type\tbuilding_id\tinitial_level\n205\tx\t0\t1\t6\n"), "cấp ban đầu 6");
    context.expect(!parse(kCities, "city_id\tname\tbuilding_type\tbuilding_id\tinitial_level\n205\tx\t0\t1\t0\n205\ty\t3\t1\t0\n"), "trùng mã công trình");
    context.expect(!parse(kCities, "city_id\tname\tbuilding_type\tbuilding_id\tinitial_level\n205\tx\t0\t1\t0\n205\ty\t0\t2\t0\n"), "hai nha môn");
    context.expect(!parse("id\tscene_id\n1\t205\n", kBuildings), "thiếu cột tên");
}

void claim_and_release(Context& context) {
    World world(4);
    const GuildId a = world.found(1, "Thiên Long", 10'000'000);
    const GuildId b = world.found(2, "Địa Phủ", 10'000'000);
    context.expect(a.value() != 0 && b.value() != 0, "dựng hai bang");
    const auto claimed = world.cities.claim(world.guilds, cid(1), CityId{1});
    context.expect(claimed.ok() && claimed.events[0].value == 10'000'000, "chiếm thành phố, phí 10 triệu");
    context.expect(world.guilds.find(a)->funds == 0 && world.guilds.find(a)->level == 1 && world.guilds.find(a)->city == CityId{1}, "trừ quỹ, cấp 1, ghi thành phố");
    context.expect(world.cities.owner_of(CityId{1}) == a && world.cities.city_of(a) == CityId{1}, "chỉ mục chủ - thành phố");
    context.expect(world.cities.building_level(CityId{1}, 1) == 1, "nha môn cấp 1 theo bang");
    context.expect(world.cities.building_level(CityId{1}, 2) == 0 && !world.cities.building_level(CityId{1}, 99).has_value(), "công trình khác cấp ban đầu");
    context.expect(world.cities.claim(world.guilds, cid(2), CityId{1}).error == CityError::kTaken, "thành phố đã có chủ");
    context.expect(world.cities.claim(world.guilds, cid(1), CityId{2}).error == CityError::kHasCity, "bang đã có thành phố");
    context.expect(world.cities.claim(world.guilds, cid(2), CityId{99}).error == CityError::kUnknownCity, "thành phố lạ");
    context.expect(world.cities.claim(world.guilds, cid(3), CityId{2}).error == CityError::kNotInGuild, "chưa vào bang");
    // Thiếu tiền: không đổi gì.
    const GuildId poor = world.found(3, "Nghèo", 9'999'999);
    context.expect(poor.value() != 0, "bang nghèo");
    context.expect(world.cities.claim(world.guilds, cid(3), CityId{2}).error == CityError::kNotEnoughMoney, "thiếu 1 đồng");
    context.expect(world.guilds.find(poor)->funds == 9'999'999 && world.guilds.find(poor)->city.value() == 0, "không trừ quỹ khi lỗi");
    // Thành viên thường không chiếm được.
    context.expect(world.guilds.apply(kNow, world.directory, cid(4), b).ok() && world.guilds.answer_application(kNow, world.directory, cid(2), cid(4), true).ok(), "4 vào bang b");
    context.expect(world.cities.claim(world.guilds, cid(4), CityId{2}).error == CityError::kNotChief, "chỉ bang chủ");
    // Trả thành phố.
    context.expect(world.cities.release(world.guilds, cid(2)).error == CityError::kNoCity, "bang b chưa có thành phố");
    context.expect(world.cities.release(world.guilds, cid(1)).ok(), "trả thành phố");
    context.expect(!world.cities.owner_of(CityId{1}).has_value() && world.guilds.find(a)->city.value() == 0 && world.guilds.find(a)->level == 0, "về trạng thái chưa có thành phố");
    context.expect(world.cities.building_level(CityId{1}, 1) == 0, "công trình về cấp ban đầu");
    context.expect(world.cities.claim(world.guilds, cid(2), CityId{1}).ok(), "bang b chiếm được sau khi trả");
    expect_valid(context, world);
}

void upgrade_rules(Context& context) {
    World world(2);
    const GuildId a = world.found(1, "Thiên Long", 10'000'000);
    context.expect(world.cities.upgrade_county(world.guilds, cid(1)).error == CityError::kNoCity, "chưa có thành phố");
    context.expect(world.cities.claim(world.guilds, cid(1), CityId{1}).ok(), "chiếm");
    // Quỹ chuẩn cấp 1 = 1666667: quỹ đang 0.
    context.expect(world.cities.upgrade_county(world.guilds, cid(1)).error == CityError::kNotEnoughMoney, "quỹ chưa đủ để lên cấp 2");
    context.expect(world.guilds.deposit(cid(1), 1'666'666, 2'000'000).ok(), "nộp thiếu 1 đồng");
    context.expect(world.cities.upgrade_county(world.guilds, cid(1)).error == CityError::kNotEnoughMoney, "thiếu 1 đồng");
    context.expect(world.guilds.deposit(cid(1), 1, 2).ok(), "đủ quỹ chuẩn");
    const auto up = world.cities.upgrade_county(world.guilds, cid(1));
    context.expect(up.ok() && up.events[0].value == 2, "lên cấp 2");
    context.expect(world.guilds.find(a)->level == 2 && world.guilds.member_cap(*world.guilds.find(a)) == 80, "trần thành viên cấp 2 = 80");
    context.expect(world.guilds.find(a)->funds == 1'666'667, "quỹ chuẩn không bị trừ (giả định đã ghi)");
    context.expect(world.cities.building_level(CityId{1}, 1) == 2, "nha môn theo cấp bang");
    // Công trình thường: từng cấp một, không vượt cấp nha môn.
    context.expect(world.cities.upgrade_building(world.guilds, cid(1), 1).error == CityError::kUnknownBuilding, "nha môn không nâng như công trình");
    context.expect(world.cities.upgrade_building(world.guilds, cid(1), 99).error == CityError::kUnknownBuilding, "công trình lạ");
    context.expect(world.cities.upgrade_building(world.guilds, cid(1), 2).ok() && world.cities.upgrade_building(world.guilds, cid(1), 2).ok(), "lên cấp 2 theo nha môn");
    context.expect(world.cities.upgrade_building(world.guilds, cid(1), 2).error == CityError::kCountyLevelTooLow, "không vượt cấp nha môn");
    context.expect(world.cities.building_level(CityId{1}, 2) == 2, "cấp công trình");
    // Lên tới cấp 5 rồi dừng.
    for (std::uint8_t level = 2; level < 5; ++level) {
        const social::Copper need = sample_guild_rules().county_standard_money.at(level - 1U);
        const social::Copper have = world.guilds.find(a)->funds;
        if (have < need) context.expect(world.guilds.deposit(cid(1), need - have, need - have).ok(), "nộp đủ quỹ chuẩn");
        context.expect(world.cities.upgrade_county(world.guilds, cid(1)).ok(), "lên cấp kế");
    }
    context.expect(world.guilds.find(a)->level == 5, "cấp 5");
    context.expect(world.cities.upgrade_county(world.guilds, cid(1)).error == CityError::kMaxLevel, "đã tối đa");
    context.expect(world.cities.upgrade_building(world.guilds, cid(1), 4).ok(), "công trình khác");
    expect_valid(context, world);
}

[[nodiscard]] std::vector<std::byte> from_hex(std::string_view hex) {
    std::vector<std::byte> bytes;
    for (std::size_t index = 0; index + 1 < hex.size(); index += 2) {
        const auto digit = [](char c) { return c <= '9' ? c - '0' : c - 'a' + 10; };
        bytes.push_back(static_cast<std::byte>((digit(hex[index]) * 16) + digit(hex[index + 1])));
    }
    return bytes;
}

void codec_and_load(Context& context) {
    CityState state;
    state.id = CityId{1};
    state.owner = GuildId{3};
    state.buildings = {{.building = 1, .level = 2}, {.building = 2, .level = 0}, {.building = 4, .level = 1}};
    social::Bytes bytes;
    context.expect(social::encode_city(state, bytes).has_value(), "mã hoá");
    // Số vàng tính tay: đầu khung (thân 2+4+8+2+3*5 = 31 byte, kind 0x5106), phiên bản 1, thành phố 1, bang 3,
    // ba công trình (1,2) (2,0) (4,1).
    const auto golden = from_hex(
        "1f000000" "0651" "0000"
        "0100" "01000000" "0300000000000000" "0300"
        "0100000002" "0200000000" "0400000001");
    context.expect(bytes == golden, "khớp số vàng");
    const auto back = social::decode_city(bytes);
    context.expect(back.has_value() && back->owner == GuildId{3} && back->buildings.size() == 3 && back->buildings[2].level == 1, "giải mã");
    bool every_cut_rejected = true;
    for (std::size_t cut = 0; cut < bytes.size(); ++cut) {
        every_cut_rejected = every_cut_rejected && !social::decode_city(std::span<const std::byte>(bytes.data(), cut)).has_value();
    }
    context.expect(every_cut_rejected, "mọi bản cụt bị từ chối");
    social::Bytes extra = bytes;
    extra.push_back(std::byte{0});
    context.expect(!social::decode_city(extra).has_value(), "byte thừa");
    CityState unordered = state;
    unordered.buildings.at(1).building = 1;
    social::Bytes bad;
    context.expect(social::encode_city(unordered, bad).has_value(), "mã hoá bản sai thứ tự");
    context.expect(!social::decode_city(bad).has_value(), "công trình không tăng dần bị từ chối");
    CityState high = state;
    high.buildings.at(0).level = 6;
    bad.clear();
    context.expect(social::encode_city(high, bad).has_value(), "mã hoá bản cấp 6");
    context.expect(!social::decode_city(bad).has_value(), "cấp 6 bị từ chối");
    // Nạp vào sổ: bang phải khớp (validate bắt lệch).
    World world(3);
    const GuildId a = world.found(1, "Thiên Long", 0);
    CityState loaded = state;
    loaded.owner = a;
    loaded.buildings = {{.building = 1, .level = 1}, {.building = 2, .level = 0}, {.building = 4, .level = 0}};
    context.expect(world.cities.load(loaded).has_value(), "nạp trạng thái thành phố");
    context.expect(!world.cities.load(loaded).has_value(), "nạp lại bị từ chối");
    context.expect(!world.cities.validate(world.guilds).has_value(), "bang chưa biết thành phố: validate báo lệch");
    context.expect(world.guilds.set_county(a, 1, CityId{1}).has_value(), "bang đặt cấp 1 và thành phố");
    context.expect(world.cities.validate(world.guilds).has_value(), "hết lệch");
    CityState wrong_building = state;
    wrong_building.id = CityId{2};
    wrong_building.owner = GuildId{};
    wrong_building.buildings = {{.building = 7, .level = 0}};
    context.expect(!world.cities.load(wrong_building).has_value(), "công trình ngoài danh mục");
    CityState unknown_city = state;
    unknown_city.id = CityId{50};
    context.expect(!world.cities.load(unknown_city).has_value(), "thành phố ngoài danh mục");
}

constexpr std::array kCases{
    Case{.name = "catalog_parse", .body = catalog_parse},
    Case{.name = "claim_and_release", .body = claim_and_release},
    Case{.name = "upgrade_rules", .body = upgrade_rules},
    Case{.name = "codec_and_load", .body = codec_and_load},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
