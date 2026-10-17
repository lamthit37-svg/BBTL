/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Look/mount_tests.cpp
 *  PHÂN HỆ   : Look / Ride Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Kiểm luật thú cưỡi: neo chủ và khách, động tác theo mã giới, chiều cao giữ
 *    nguyên số gốc, lệch quầng chỉ khi effect_id có dòng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "core/check.hpp"
#include "look/mount.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <cstdint>
#include <initializer_list>
#include <string>
#include <string_view>

namespace game::test {
namespace {

using look::RideTexts;

[[nodiscard]] std::string row(std::initializer_list<std::string_view> cells) {
    std::string line;
    bool is_first = true;
    for (const std::string_view cell : cells) {
        if (!is_first) line.push_back('\t');
        is_first = false;
        line.append(cell);
    }
    line.push_back('\n');
    return line;
}

constexpr std::string_view kRideHead =
    "id\tname\tpassenger_capacity\tmodel_id\tadd_height\tride_recipe\t"
    "driver_action_0\tdriver_action_1\tanchor_0\tpassenger_action_0\tpassenger_action_1\t"
    "anchor_1\tanchor_2\tanchor_3\tanchor_4\tanchor_5\t"
    "extra_16\textra_17\textra_18\textra_19\textra_20\textra_21\tcamera_y\teffect_id\t"
    "speed_percent\n";
constexpr std::string_view kModelHead = "model\tmesh\tscale\taction_set\n";
constexpr std::string_view kOffsetHead = "id\tx\ty\tz\taxis_x\taxis_y\taxis_z\tangle\tlabel\n";
constexpr std::string_view kEffectHead = "object\tslot\teffect\tlocator\ttranslate_all\n";
constexpr std::string_view kEntityHead = "object\tslot\tfile\tmaterials\tcondition\n";

[[nodiscard]] std::string tiger() {
    return row({"0", "虎", "1", "1010", "0.5", "447", "839", "1435", "attach1", "839", "1435", "attach1", "attach1",
        "attach1", "attach1", "attach1", "-1", "1", "-1", "-1", "0", "-1", "0", "-1", "40"});
}

[[nodiscard]] std::string elephant() {
    return row({"23", "象", "2", "1027", "0.6", "1", "10", "11", "attach1", "20", "21", "attach2", "decoy", "decoy",
        "decoy", "decoy", "-1", "1", "-1", "-1", "0", "-1", "0.25", "4", "70"});
}

[[nodiscard]] std::string wagon() {
    return row({"40", "马车", "6", "200", "0", "1", "1", "2", "a0", "3", "4", "a1", "a2", "a3", "a4", "a5", "-1", "-1",
        "-1", "-1", "-1", "-1", "0", "99", "80"});
}

[[nodiscard]] std::string fallback() {
    return row({"7", "rơi", "1", "9", "0", "1", "-1", "8", "bone", "-1", "9", "p", "p", "p", "p", "p", "-1", "-1", "-1",
        "-1", "-1", "-1", "0", "-1", "0"});
}

[[nodiscard]] std::string bare() {
    return row({"8", "trống", "1", "-1", "0", "1", "1", "1", "bone", "1", "1", "p", "p", "p", "p", "p", "-1", "-1", "-1",
        "-1", "-1", "-1", "0", "-1", "0"});
}

struct Fixture {
    std::string rides;
    std::string models;
    std::string offsets;

    [[nodiscard]] RideTexts texts() const { return RideTexts{rides, models, offsets}; }
};

[[nodiscard]] Fixture good() {
    Fixture fixture;
    fixture.rides = std::string(kRideHead) + tiger() + elephant() + wagon() + fallback() + bare();
    fixture.models = std::string(kModelHead) + row({"1010", "虎.mesh", "1", "1638"}) + row({"1027", "象.mesh", "1", "100"}) +
                     row({"200", "xe.mesh", "1", "50"}) + row({"9", "roi.mesh", "1.3", "77"});
    fixture.offsets = std::string(kOffsetHead) + row({"4", "0", "-90", "0", "1", "0", "0", "0", "骑马"});
    return fixture;
}

[[nodiscard]] bool near_value(float left, float right) {
    return std::fabs(left - right) < 1e-4F;
}

void tiger_ignores_sex(Context& context) {
    const Fixture fixture = good();
    const auto tables = look::parse_ride_tables(fixture.texts());
    context.expect(tables.has_value(), "bảng đúng thì đọc được");
    if (!tables) return;
    const auto male = look::ride_figure(*tables, 0, 0, 0, look::kRideOwner);
    const auto female = look::ride_figure(*tables, 0, 1, 1, look::kRideOwner);
    context.expect(male.has_value() && female.has_value(), "hổ giải được");
    if (!male || !female) return;
    context.expect(male->anchor == "attach1" && female->anchor == "attach1", "thú một chỗ neo chính");
    context.expect(male->rider_action == 839 && female->rider_action == 1435, "động tác theo mã giới");
    context.expect(male->model_action == 1638 && male->mesh == "虎.mesh", "bộ của mô hình và lưới");
    context.expect(near_value(male->add_height, 0.5F) && near_value(male->camera_y, 0.0F), "cao và camera giữ số gốc");
    context.expect(!male->offset.has_value(), "effect -1 không lệch quầng");
    context.expect(look::kHaloSlot == "脚下光圈点偏移", "tên điểm quầng");
}

void double_ride_swaps_anchor(Context& context) {
    const auto tables = look::parse_ride_tables(good().texts());
    context.expect(tables.has_value(), "đọc được");
    if (!tables) return;
    const auto owner_zero = look::ride_figure(*tables, 23, 0, 0, 0);
    const auto owner_other = look::ride_figure(*tables, 23, 2, 2, 0);
    const auto guest_zero = look::anchor_of(*tables->find_ride(23), 0, 1);
    const auto guest_other = look::anchor_of(*tables->find_ride(23), 2, 3);
    context.expect(owner_zero && owner_zero->anchor == "attach1", "chủ giới 0 neo chính");
    context.expect(owner_other && owner_other->anchor == "attach2", "chủ giới khác 0 neo phụ");
    context.expect(guest_zero == "attach2" && guest_other == "attach1", "khách thú đôi đổi neo, không lấy ghế");
    context.expect(owner_zero && owner_zero->offset && near_value(owner_zero->offset->y, -90.0F), "lệch y của 骑马");
    context.expect(owner_zero && owner_zero->offset && near_value(owner_zero->offset->axis_x, 1.0F), "trục x");
    context.expect(owner_zero && near_value(owner_zero->camera_y, 0.25F), "camera +0x78");
    context.expect(look::rider_action_of(*tables->find_ride(23), 0, 1) == 20, "động tác khách cột giới 0");
}

void wide_ride_uses_seat(Context& context) {
    const auto tables = look::parse_ride_tables(good().texts());
    context.expect(tables.has_value(), "đọc được");
    if (!tables) return;
    const look::RideRow* row = tables->find_ride(40);
    context.expect(row != nullptr, "có xe");
    if (row == nullptr) return;
    context.expect(look::anchor_of(*row, 1, 0) == "a0", "chủ xe neo chính");
    context.expect(look::anchor_of(*row, 0, 3) == "a3", "ghế 3 lấy neo của ghế");
    context.expect(look::anchor_of(*row, 0, 6).empty(), "ghế ngoài 0..5 không có neo");
    context.expect(look::halo_of(*tables, *row) == nullptr, "id lệch lạ thì không áp");
}

void action_falls_back(Context& context) {
    const auto tables = look::parse_ride_tables(good().texts());
    context.expect(tables.has_value(), "đọc được");
    if (!tables) return;
    const auto fell = look::ride_figure(*tables, 7, 0, 0, 0);
    context.expect(fell && fell->rider_action == 77 && near_value(fell->model_scale, 1.3F), "cột -1 lấy bộ mô hình");
    context.expect(!look::ride_figure(*tables, 8, 0, 0, 0), "model -1 là không có thú");
    context.expect(!look::ride_figure(*tables, 99, 0, 0, 0), "id lạ");
}

void keeps_speed_percent(Context& context) {
    const auto tables = look::parse_ride_tables(good().texts());
    context.expect(tables.has_value(), "đọc được");
    if (!tables) return;
    const look::RideRow* tiger_row = tables->find_ride(0);
    const look::RideRow* elephant_row = tables->find_ride(23);
    const look::RideRow* wagon_row = tables->find_ride(40);
    const look::RideRow* plain_row = tables->find_ride(7);
    context.expect(tiger_row != nullptr && tiger_row->speed_percent == 40, "hổ +40%");
    context.expect(elephant_row != nullptr && elephant_row->speed_percent == 70, "voi +70%");
    context.expect(wagon_row != nullptr && wagon_row->speed_percent == 80, "xe +80%");
    context.expect(plain_row != nullptr && plain_row->speed_percent == 0, "không có dòng thì 0");
    const auto figure = look::ride_figure(*tables, 0, 0, 0, 0);
    context.expect(figure.has_value() && figure->speed_percent == 40, "hình mang phần trăm");
}

void reads_ride_effects(Context& context) {
    const std::string text = std::string(kEffectHead) + row({"HJ.obj", "a", "qc_a", "mat", "1"}) +
                             row({"HJ.obj", "b", "qc_b", "chuong", "0"}) + row({"ho.obj", "c", "qc_c", "chan", "1"});
    const auto rows = look::parse_ride_effects(text);
    context.expect(rows.has_value(), "đọc được");
    if (!rows) return;
    context.expect(rows->size() == 3, "ba dòng");
    context.expect(rows->at(0).translate_all && !rows->at(1).translate_all, "cờ translateAll");
    const std::vector<const look::RideEffect*> bear = look::effects_of(*rows, "HJ.obj");
    context.expect(bear.size() == 2 && bear[0]->slot == "a" && bear[1]->effect == "qc_b", "đúng mẫu, đúng thứ tự");
    context.expect(look::effects_of(*rows, "khong.obj").empty(), "mẫu không có thì rỗng");
    const std::string doubled = text + row({"HJ.obj", "a", "qc_a", "mat", "1"});
    context.expect(!look::parse_ride_effects(doubled), "trùng slot");
    context.expect(!look::parse_ride_effects(std::string(kEffectHead) + row({"o", "s", "", "diem", "1"})), "thiếu tên effect");
    context.expect(!look::parse_ride_effects("object\tslot\n"), "thiếu cột");
}

void reads_ride_entities(Context& context) {
    const std::string lion_body = row({"lion.obj", "0", "body.mesh", "a;a半透", ""});
    const std::string lion_card = row({"lion.obj", "1", "card.mesh", "", ""});
    const std::string tiger = row({"tiger.obj", "0", "ho.mesh", "", ""});
    const std::string text = std::string(kEntityHead) + lion_body + lion_card + tiger;
    const auto rows = look::parse_ride_entities(text);
    context.expect(rows.has_value(), "đọc được");
    if (!rows) return;
    context.expect(rows->size() == 3, "ba lưới");
    context.expect(rows->at(0).materials == "a;a半透", "giữ dấu chấm phẩy");
    const std::vector<const look::RideEntity*> lion = look::entities_of(*rows, "lion.obj");
    context.expect(lion.size() == 2 && lion[0]->file == "body.mesh", "đúng mẫu, đúng thứ tự");
    context.expect(lion[1]->file == "card.mesh" && lion[1]->materials.empty(), "tấm sau không chồng");
    context.expect(look::entities_of(*rows, "khong.obj").empty(), "mẫu không có thì rỗng");
    const std::string doubled = text + row({"lion.obj", "0", "body.mesh", "", ""});
    context.expect(!look::parse_ride_entities(doubled), "trùng slot");
    const std::string bare = std::string(kEntityHead) + row({"o", "0", "", "", ""});
    context.expect(!look::parse_ride_entities(bare), "thiếu lưới");
    context.expect(!look::parse_ride_entities("object\tslot\n"), "thiếu cột");
}

void rejects_a_bad_table(Context& context) {
    Fixture fixture = good();
    fixture.rides += tiger();
    context.expect(!look::parse_ride_tables(fixture.texts()), "trùng id");
    fixture = good();
    fixture.models = "model\tmesh\n";
    context.expect(!look::parse_ride_tables(fixture.texts()), "thiếu cột");
    const look::ReadFile read = [](const std::string& path) -> std::expected<std::string, std::string> {
        if (path == "dir/rides.tsv") return std::unexpected("mất");
        return std::string{};
    };
    const auto lost = look::load_ride_tables("dir", read);
    context.expect(!lost && lost.error().find("rides.tsv") != std::string::npos, "thiếu tệp nêu tên");
}

constexpr std::array kCases{
    Case{.name = "tiger_ignores_sex", .body = &tiger_ignores_sex},
    Case{.name = "double_ride_swaps_anchor", .body = &double_ride_swaps_anchor},
    Case{.name = "wide_ride_uses_seat", .body = &wide_ride_uses_seat},
    Case{.name = "action_falls_back", .body = &action_falls_back},
    Case{.name = "keeps_speed_percent", .body = &keeps_speed_percent},
    Case{.name = "reads_ride_effects", .body = &reads_ride_effects},
    Case{.name = "reads_ride_entities", .body = &reads_ride_entities},
    Case{.name = "rejects_a_bad_table", .body = &rejects_a_bad_table},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "mount_tests: mọi ca phải qua");
    return 0;
}
