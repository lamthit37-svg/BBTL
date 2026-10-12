// Chuỗi đăng nhập: vào game ở bảng tài khoản không ra client; chỉ ra khi đã chọn nhân vật. Ở bước
// tạo, chuỗi lưu nhân vật với đúng mặt, tóc, ảnh chân dung và bộ đồ mà bảng tạo đã đặt cho game.
#include "ui/panel/login_flow.hpp"
#include "ui/panel/role_pose.hpp"

#include "core/check.hpp"
#include "table/tsv.hpp"
#include "test.hpp"
#include "ui/panel/create_role.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/logon.hpp"
#include "ui/panel/portraits.hpp"
#include "ui/panel/role_cast.hpp"
#include "ui/panel/roles.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::test {
namespace {

using ui::panel::FlowStep;
using ui::panel::LoginFacts;
using ui::panel::LoginFlow;
using ui::panel::LogonAction;
using ui::panel::Portraits;
using ui::panel::Role;
using ui::panel::RoleCast;
using ui::panel::ShownModel;

constexpr std::string_view kPortraits = "id\trace\timage\tchoice\torder\n"
                                        "1\t0\tset:Face image:Girl_1\t3\t1\n"
                                        "2\t0\tset:Face image:Girl_2\t3\t1\n"
                                        "13\t1\tset:Face image:Man_1\t3\t1\n";
constexpr std::string_view kFaces = "id\trace\tmesh\tname\tchoice\n"
                                    "1\t0\tf1.mesh\tMặt Một\t3\n"
                                    "100\t1\tm1.mesh\tMặt Nam\t3\n"
                                    "10001\t0\tf1_hi.mesh\tMặt Một Cao\t-1\n";
constexpr std::string_view kHairs = "id\trace\tmesh\taccessory\tname\tchoice\n"
                                    "4\t0\th4.mesh\t\tTóc Nữ\t3\n"
                                    "7\t1\th7.mesh\t\tTóc Nam\t3\n";
constexpr std::string_view kOutfits = "id\tname\tbody\tfoot\tarm\n"
                                      "0\tBộ Một\t437\t440\t443\n"
                                      "1\tBộ Hai\t438\t441\t444\n"
                                      "2\tBộ Ba\t439\t442\t445\n";

[[nodiscard]] table::Tsv parsed(std::string_view text) {
    table::TsvResult table = table::parse_tsv(text);
    core::check(table.has_value(), "bảng mẫu phải đọc được");
    return std::move(*table);
}

// Dữ liệu mẫu của game và điều chuỗi đọc từ nó.
struct World {
    Portraits portraits;
    RoleCast cast;

    [[nodiscard]] LoginFacts facts() const noexcept {
        LoginFacts facts;
        facts.cast = &cast;
        facts.portraits = &portraits;
        return facts;
    }
};

[[nodiscard]] World sample_world() {
    const table::Tsv portraits = parsed(kPortraits);
    const table::Tsv faces = parsed(kFaces);
    const table::Tsv hairs = parsed(kHairs);
    const table::Tsv outfits = parsed(kOutfits);
    ui::panel::CastTables tables;
    tables.portraits = &portraits;
    tables.faces = &faces;
    tables.hairs = &hairs;
    tables.outfits = &outfits;
    World world;
    world.portraits = Portraits::from_table(portraits);
    world.cast = RoleCast::from_tables(tables);
    return world;
}

void type_text(LoginFlow& flow, std::u32string_view text, const LoginFacts& facts) {
    for (const char32_t code : text) ui::panel::type_flow(flow, code, facts);
}

void sign_in(LoginFlow& flow) {
    ui::panel::reset_account(flow);
    type_text(flow, U"a\tb", {});
    ui::panel::press_flow(flow, "LogOn_LogOnGame", {});
}

void logon_enter_opens_roles(Context& context) {
    LoginFlow flow;
    ui::panel::press_flow(flow, "LogOn_LogOnGame", {});
    context.expect(flow.step == FlowStep::kAccount && !ui::panel::take_flow(flow), "thiếu chữ thì chưa đi");
    sign_in(flow);
    context.expect(flow.step == FlowStep::kRoles, "sang bảng chọn");
    context.expect(!ui::panel::take_flow(flow), "không đưa vào game ra client");
    context.expect(ui::panel::account_text(flow.logon) == "a", "giữ tên tài khoản");
}

void web_and_leave_pass_through(Context& context) {
    LoginFlow flow;
    ui::panel::reset_account(flow);
    ui::panel::press_flow(flow, "LogOn_payment", {});
    context.expect(ui::panel::take_flow(flow) == LogonAction::kOpenTopUp, "nút nạp thẻ đi ra");
    ui::panel::press_flow(flow, "LogOn_Last", {});
    context.expect(ui::panel::take_flow(flow) == LogonAction::kLeave, "nút quay lại của bảng tài khoản là thoát");
}

void back_keeps_the_typed_account(Context& context) {
    LoginFlow flow;
    sign_in(flow);
    ui::panel::press_flow(flow, "SelectRole_Last", {});
    context.expect(ui::panel::on_account(flow), "về bảng tài khoản");
    context.expect(flow.logon.account == "a" && flow.logon.password == "b", "còn chữ đã gõ");
}

void create_then_play_enters_that_role(Context& context) {
    const World world = sample_world();
    const LoginFacts facts = world.facts();
    LoginFlow flow;
    sign_in(flow);
    ui::panel::press_flow(flow, "SelectRole_Create", facts);
    context.expect(flow.step == FlowStep::kCreate && flow.create.is_shown, "mở tạo");
    type_text(flow, U"Huyền", facts);
    ui::panel::press_flow(flow, "CreateRole_Select_Head2", facts);
    ui::panel::press_flow(flow, "CreateRole_Author", facts);
    context.expect(flow.step == FlowStep::kRoles && flow.dirty, "lưu người mới");
    context.expect(!flow.create.is_shown, "bảng tạo đã đóng");
    context.expect(flow.select.count == 1 && flow.select.selected == 0, "chọn người vừa tạo");
    ui::panel::press_flow(flow, "SelectRole_Play", facts);
    context.expect(ui::panel::take_flow(flow) == LogonAction::kEnterGame, "vào game");
    context.expect(!ui::panel::take_flow(flow), "lấy rồi thì hết");
    const Role* role = ui::panel::entering_role(flow);
    context.expect(role != nullptr && role->name == "Huyền", "vẫn giữ người sau khi lấy");
    if (role == nullptr) return;
    context.expect(role->sect == 9 && role->sex == 0 && role->level == 1, "vô phái, nữ, cấp 1");
    context.expect(role->face == 1 && role->hair == 4, "mặt và tóc là id thường của kiểu đã chọn");
    context.expect(role->portrait == 2 && role->icon == "set:Face image:Girl_2", "ảnh chân dung của ô đã chọn");
    const ui::panel::NewbieOutfit* outfit = world.cast.outfit(flow.create.game.outfit);
    const bool is_worn = outfit != nullptr && role->body == outfit->body && role->arm == outfit->arm;
    context.expect(is_worn && role->foot == outfit->foot && role->body >= 437, "mặc bộ đồ tân thủ đã gieo");
}

void created_man_keeps_his_look(Context& context) {
    const World world = sample_world();
    const LoginFacts facts = world.facts();
    LoginFlow flow;
    sign_in(flow);
    ui::panel::press_flow(flow, "SelectRole_Create", facts);
    ui::panel::press_flow(flow, "CreateRole_SelectSex_Boy", facts);
    type_text(flow, U"Nam", facts);
    ui::panel::press_flow(flow, "CreateRole_Author", facts);
    const ui::panel::Roster roster = ui::panel::roster_of(flow.book, flow.account);
    context.expect(roster.count == 1, "một nhân vật trong sổ");
    const Role& role = roster.roles.front();
    context.expect(role.sex == 1 && role.face == 100 && role.hair == 7, "mặt tóc nam");
    context.expect(role.portrait == 13 && role.icon == "set:Face image:Man_1", "chân dung nam");
}

void name_faults_stay_on_create(Context& context) {
    const World world = sample_world();
    const LoginFacts facts = world.facts();
    LoginFlow flow;
    sign_in(flow);
    ui::panel::press_flow(flow, "SelectRole_Create", facts);
    ui::panel::press_flow(flow, "CreateRole_Author", facts);
    const ui::panel::Key info{.window = "CreateRole_Info", .name = "Text"};
    context.expect(flow.step == FlowStep::kCreate && !flow.dirty, "tên trống thì ở lại, chưa ghi sổ");
    context.expect(flow.create.widgets.value(info) == "#{Login_Create_Role_Info_Name_Is_Empty}", "lời nhắn tên trống");
    type_text(flow, U"Mai", facts);
    ui::panel::press_flow(flow, "CreateRole_Author", facts);
    context.expect(flow.step == FlowStep::kRoles && flow.select.count == 1, "tên hợp lệ thì tạo");
    ui::panel::press_flow(flow, "SelectRole_Create", facts);
    type_text(flow, U"Mai", facts);
    ui::panel::press_flow(flow, "CreateRole_Author", facts);
    context.expect(flow.step == FlowStep::kCreate, "tên trùng thì ở lại");
    context.expect(flow.create.widgets.value(info) == "#{Login_Create_Role_Name_Exist}", "lời nhắn tên trùng");
    ui::panel::press_flow(flow, "CreateRole_Last", facts);
    context.expect(flow.step == FlowStep::kRoles && flow.select.count == 1, "quay lại không tạo thêm");
}

void missing_portrait_does_not_create(Context& context) {
    LoginFlow flow;
    sign_in(flow);
    ui::panel::press_flow(flow, "SelectRole_Create", {});
    type_text(flow, U"Mai", {});
    ui::panel::press_flow(flow, "CreateRole_Author", {});
    const ui::panel::Key info{.window = "CreateRole_Info", .name = "Text"};
    context.expect(flow.step == FlowStep::kCreate && !flow.dirty, "không có dữ liệu chân dung thì không tạo");
    context.expect(flow.create.widgets.value(info) == "#{DLXZ_090711_1}", "lời nhắn của game hiện ở dòng mô tả");
}

void other_account_does_not_see_the_role(Context& context) {
    const World world = sample_world();
    const LoginFacts facts = world.facts();
    LoginFlow flow;
    sign_in(flow);
    ui::panel::press_flow(flow, "SelectRole_Create", facts);
    type_text(flow, U"M", facts);
    ui::panel::press_flow(flow, "CreateRole_Author", facts);
    const std::optional<std::string> text = ui::panel::book_text(flow);
    context.expect(text.has_value() && !text->contains("matkhau"), "sổ không có mật khẩu");
    ui::panel::mark_saved(flow);
    context.expect(!ui::panel::book_text(flow), "đã lưu thì không ghi lại");
    ui::panel::press_flow(flow, "SelectRole_Last", facts);
    flow.logon.account = "khac";
    ui::panel::press_flow(flow, "LogOn_LogOnGame", facts);
    context.expect(flow.select.count == 0, "tài khoản khác không thấy");
}

void delete_removes_only_after_the_second_press(Context& context) {
    const World world = sample_world();
    const LoginFacts facts = world.facts();
    LoginFlow flow;
    sign_in(flow);
    ui::panel::press_flow(flow, "SelectRole_Create", facts);
    type_text(flow, U"M", facts);
    ui::panel::press_flow(flow, "CreateRole_Author", facts);
    ui::panel::press_flow(flow, "SelectRole_Delete", facts);
    context.expect(flow.select.confirming && flow.select.count == 1, "lần đầu chỉ hỏi");
    ui::panel::press_flow(flow, "SelectRole_Play", facts);
    context.expect(!flow.select.confirming && !ui::panel::take_flow(flow), "nút khác chỉ huỷ");
    ui::panel::press_flow(flow, "SelectRole_Delete", facts);
    ui::panel::press_flow(flow, "SelectRole_Delete", facts);
    context.expect(flow.select.count == 0 && flow.dirty, "lần hai mới xoá");
}

void held_turn_spins_one_revolution_per_second(Context& context) {
    const World world = sample_world();
    const LoginFacts facts = world.facts();
    LoginFlow flow;
    sign_in(flow);
    ui::panel::press_flow(flow, "SelectRole_Create", facts);
    ui::panel::press_flow(flow, "CreateRole_Role2_Model_TurnLeft", facts);
    ui::panel::hold_flow(flow, "CreateRole_Role2_Model_TurnLeft");
    ui::panel::advance_flow(flow, 0.5F);
    const ShownModel model = ui::panel::shown_model(flow, facts);
    const float turned = -0.5F * ui::panel::kFullTurn;
    const float gap = model.yaw - turned;
    context.expect(model.is_creating && model.in_world && model.sex == 0, "nữ đứng trong cảnh của màn tạo");
    context.expect(model.on_role_scene, "tạo nhân vật đứng trên cảnh chọn");
    context.expect(gap > -0.001F && gap < 0.001F, "nửa giây là nửa vòng sang trái");
    // Chuột trượt khỏi nút mà chưa nhả: nút vẫn giữ chuột nên người mẫu còn quay.
    ui::panel::hold_flow(flow, "");
    ui::panel::advance_flow(flow, 0.5F);
    const float full = ui::panel::shown_model(flow, facts).yaw + ui::panel::kFullTurn;
    context.expect(full > -0.001F && full < 0.001F, "giữ chuột thì quay tiếp dù đã trượt khỏi nút");
    ui::panel::release_flow(flow);
    ui::panel::hold_flow(flow, "");
    ui::panel::advance_flow(flow, 1.0F);
    const float rest = ui::panel::shown_model(flow, facts).yaw + ui::panel::kFullTurn;
    context.expect(rest > -0.001F && rest < 0.001F, "nhả nút thì đứng yên");
}

void create_model_wears_the_chosen_look(Context& context) {
    const World world = sample_world();
    const LoginFacts facts = world.facts();
    LoginFlow flow;
    sign_in(flow);
    ui::panel::press_flow(flow, "SelectRole_Create", facts);
    const ShownModel woman = ui::panel::shown_model(flow, facts);
    context.expect(woman.sex == 0 && woman.face == 10001, "người mẫu nữ dùng dòng mặt cao mô");
    context.expect(woman.hair == 4, "tóc không có dòng cao mô thì giữ id thường");
    const ui::panel::NewbieOutfit* outfit = world.cast.outfit(flow.create.game.outfit);
    const bool is_worn = outfit != nullptr && woman.body == outfit->body && woman.arm == outfit->arm;
    context.expect(is_worn && woman.foot == outfit->foot, "người mẫu mặc bộ đồ tân thủ đang chọn");
    ui::panel::press_flow(flow, "CreateRole_SelectSex_Boy", facts);
    const ShownModel man = ui::panel::shown_model(flow, facts);
    context.expect(man.sex == 1 && man.is_creating && man.in_world, "nam đứng trong cảnh của màn tạo");
    context.expect(man.face == 100 && man.hair == 7, "mặt tóc nam");
    const ShownModel bare = ui::panel::shown_model(flow, {});
    context.expect(bare.is_creating && bare.face == 100 && bare.body == 0, "không có bảng thì giữ id của game, không bộ đồ");
}

void hover_reaches_the_create_panel(Context& context) {
    const World world = sample_world();
    const LoginFacts facts = world.facts();
    LoginFlow flow;
    sign_in(flow);
    ui::panel::hover_flow(flow, "CreateRole_Author");
    ui::panel::release_flow(flow);
    ui::panel::press_flow(flow, "SelectRole_Create", facts);
    ui::panel::hover_flow(flow, "CreateRole_Author");
    const ui::panel::Key info{.window = "CreateRole_Info", .name = "Text"};
    context.expect(flow.create.widgets.value(info) == "#{DLJM_XML_22}", "rê vào nút tạo thì hiện mô tả");
    ui::panel::Deck deck;
    ui::panel::paint_flow(deck, flow);
    context.expect(deck.is_shown("CreateRole_Frame"), "bước tạo vẽ bảng tạo");
}

void select_puts_the_role_in_the_world(Context& context) {
    const World world = sample_world();
    const LoginFacts facts = world.facts();
    LoginFlow flow;
    sign_in(flow);
    ui::panel::press_flow(flow, "SelectRole_Create", facts);
    type_text(flow, U"L", facts);
    ui::panel::press_flow(flow, "CreateRole_Author", facts);
    const ShownModel model = ui::panel::shown_model(flow, facts);
    context.expect(flow.step == FlowStep::kRoles && model.in_world, "bảng chọn đặt nhân vật vào cảnh");
    context.expect(model.on_role_scene && model.slot == 0, "nhân vật mới nằm ở ô đầu");
    context.expect(!model.is_creating, "bảng chọn không phải màn tạo");
    context.expect(model.face == 1 && model.hair == 4 && model.body >= 437, "nhân vật trong cảnh mang mặt, tóc, bộ đồ đã lưu");
    ui::panel::hold_flow(flow, "SelectRole_Role2_Model_TurnRight");
    ui::panel::advance_flow(flow, 0.25F);
    const float gap = ui::panel::shown_model(flow, facts).yaw - (0.25F * ui::panel::kFullTurn);
    context.expect(gap > -0.001F && gap < 0.001F, "nút xoay của bảng chọn quay theo lúc giữ");
}

void dice_changes_with_the_salt(Context& context) {
    const World world = sample_world();
    LoginFacts facts = world.facts();
    std::array<bool, 3> seen{};
    for (std::uint32_t salt = 1; salt <= 64; ++salt) {
        LoginFlow flow;
        sign_in(flow);
        facts.salt = salt;
        ui::panel::press_flow(flow, "SelectRole_Create", facts);
        const std::int32_t outfit = flow.create.game.outfit;
        context.expect(outfit >= 0 && outfit <= 2, "bộ đồ gieo nằm trong ba bộ");
        if (outfit >= 0 && outfit <= 2) seen.at(static_cast<std::size_t>(outfit)) = true;
    }
    context.expect(seen[0] && seen[1] && seen[2], "muối khác nhau thì gieo ra đủ ba bộ");
}

constexpr std::array kCases{
    Case{.name = "logon_enter_opens_roles", .body = &logon_enter_opens_roles},
    Case{.name = "web_and_leave_pass_through", .body = &web_and_leave_pass_through},
    Case{.name = "back_keeps_the_typed_account", .body = &back_keeps_the_typed_account},
    Case{.name = "create_then_play_enters_that_role", .body = &create_then_play_enters_that_role},
    Case{.name = "created_man_keeps_his_look", .body = &created_man_keeps_his_look},
    Case{.name = "name_faults_stay_on_create", .body = &name_faults_stay_on_create},
    Case{.name = "missing_portrait_does_not_create", .body = &missing_portrait_does_not_create},
    Case{.name = "other_account_does_not_see_the_role", .body = &other_account_does_not_see_the_role},
    Case{.name = "delete_removes_only_after_the_second_press", .body = &delete_removes_only_after_the_second_press},
    Case{.name = "held_turn_spins_one_revolution_per_second", .body = &held_turn_spins_one_revolution_per_second},
    Case{.name = "create_model_wears_the_chosen_look", .body = &create_model_wears_the_chosen_look},
    Case{.name = "hover_reaches_the_create_panel", .body = &hover_reaches_the_create_panel},
    Case{.name = "select_puts_the_role_in_the_world", .body = &select_puts_the_role_in_the_world},
    Case{.name = "dice_changes_with_the_salt", .body = &dice_changes_with_the_salt},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_flow_tests: mọi ca phải qua");
    return 0;
}
