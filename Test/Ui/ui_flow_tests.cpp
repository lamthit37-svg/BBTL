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
#include "ui/panel/online.hpp"
#include "ui/panel/portraits.hpp"
#include "ui/panel/role_cast.hpp"
#include "ui/panel/roles.hpp"
#include "ui/panel/select_role.hpp"
#include "ui/panel/servers.hpp"
#include "ui/panel/system_info.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

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
    ui::panel::start_login(flow);
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
    ui::panel::start_login(flow);
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
    ui::panel::release_flow(flow, {});
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
    ui::panel::hover_flow(flow, "CreateRole_Author", std::nullopt, false);
    ui::panel::release_flow(flow, {});
    ui::panel::press_flow(flow, "SelectRole_Create", facts);
    ui::panel::hover_flow(flow, "CreateRole_Author", std::nullopt, false);
    const ui::panel::Key info{.window = "CreateRole_Info", .name = "Text"};
    context.expect(flow.create.widgets.value(info) == "#{DLJM_XML_22}", "rê vào nút tạo thì hiện mô tả");
    ui::panel::Deck deck;
    ui::panel::paint_flow(deck, flow, nullptr);
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

void zoom_buttons_set_the_shown_speed(Context& context) {
    const World world = sample_world();
    const LoginFacts facts = world.facts();
    LoginFlow flow;
    sign_in(flow);
    ui::panel::press_flow(flow, "SelectRole_Create", facts);
    type_text(flow, U"L", facts);
    ui::panel::press_flow(flow, "CreateRole_Author", facts);
    ui::panel::hold_flow(flow, "SelectRole_ModelZoomIn");
    context.expect(ui::panel::shown_model(flow, facts).zoom == 1, "bảng chọn giữ nút cộng thì phóng tới");
    ui::panel::hold_flow(flow, "");
    context.expect(ui::panel::shown_model(flow, facts).zoom == 1, "trượt khỏi nút mà chưa nhả thì còn phóng");
    ui::panel::release_flow(flow, {});
    ui::panel::hold_flow(flow, "");
    context.expect(ui::panel::shown_model(flow, facts).zoom == 0, "nhả nút bảng chọn thì thôi phóng");
    ui::panel::hold_flow(flow, "SelectRole_ModelZoomOut");
    context.expect(ui::panel::shown_model(flow, facts).zoom == -1, "bảng chọn giữ nút trừ thì lùi ra");
    ui::panel::release_flow(flow, {});
    ui::panel::press_flow(flow, "SelectRole_Create", facts);
    ui::panel::press_flow(flow, "CreateRole_ModelZoomIn", facts);
    ui::panel::hold_flow(flow, "");
    context.expect(ui::panel::shown_model(flow, facts).zoom == 1, "màn tạo giữ phóng dù chuột đã trượt");
    ui::panel::release_flow(flow, {});
    ui::panel::hold_flow(flow, "");
    context.expect(ui::panel::shown_model(flow, facts).zoom == 0, "nhả nút màn tạo thì thôi phóng");
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

// ---------------------------------------------------------------------------------------------------------------
// Chế độ trực tuyến: chuỗi chỉ nhờ và nhận trả lời, không biết socket (phần nối máy chủ là việc của client/online).

using ui::panel::OnlineAsk;
using ui::panel::OnlineFault;
using ui::panel::OnlineReply;
using ui::panel::OnlineWork;

// Chuỗi đã chọn một máy chủ có cổng thật và đang ở bảng tài khoản, như sau khi người chơi bấm vào máy chủ đó.
[[nodiscard]] LoginFlow online_flow() {
    LoginFlow flow;
    const bool loaded = ui::panel::recall_directory(flow, std::string{ui::panel::kServerColumns} + "\nVùng\tchú thích\t0\tMáy\t2\t0\t0\t0\t0\n");
    core::check(loaded, "danh sách máy chủ mẫu phải đọc được");
    const std::array names{ui::panel::ServerName{.area = "Vùng", .server = "Máy"}};
    ui::panel::mark_online(flow, names);
    ui::panel::start_login(flow);
    flow.chosen = ui::panel::ServerRef{.area = 0, .server = 0};
    flow.is_online = true;
    flow.step = FlowStep::kAccount;
    return flow;
}

enum class RoleSex : std::uint8_t { kFemale = 0, kMale = 1 };

[[nodiscard]] OnlineReply roster_reply(std::uint64_t id, RoleSex sex) {
    OnlineReply reply;
    reply.kind = OnlineReply::Kind::kRoster;
    Role role;
    role.name = "Lam";
    role.sex = static_cast<std::uint8_t>(sex);
    role.id = id;
    role.portrait = 0;
    reply.roles.push_back(role);
    return reply;
}

void online_sign_in_asks_instead_of_opening_roles(Context& context) {
    LoginFlow flow = online_flow();
    type_text(flow, U"a\tb", {});
    ui::panel::press_flow(flow, "LogOn_LogOnGame", {});
    context.expect(flow.step == FlowStep::kAccount && flow.is_waiting, "chờ máy chủ, chưa sang bảng chọn");
    context.expect(flow.system_info.is_open && flow.system_info.text == ui::panel::kOnlineWaiting, "hộp báo đang nối");
    std::vector<OnlineAsk> asks = ui::panel::take_asks(flow);
    context.expect(asks.size() == 1 && asks.front().work == OnlineWork::kSignIn, "một việc đăng nhập");
    if (!asks.empty()) {
        context.expect(asks.front().server.area == "Vùng" && asks.front().server.server == "Máy", "đúng máy chủ đã chọn");
        context.expect(asks.front().account == "a" && asks.front().password == "b", "tài khoản và mật khẩu đã gõ");
    }
    context.expect(ui::panel::take_asks(flow).empty(), "lấy rồi thì hết");
    context.expect(!ui::panel::take_flow(flow), "đăng nhập chưa đưa gì ra client");
}

void online_waiting_blocks_input(Context& context) {
    LoginFlow flow = online_flow();
    type_text(flow, U"a\tb", {});
    ui::panel::press_flow(flow, "LogOn_LogOnGame", {});
    static_cast<void>(ui::panel::take_asks(flow));
    type_text(flow, U"zzz", {});
    ui::panel::key_flow(flow, U'q');
    ui::panel::press_flow(flow, "LogOn_LogOnGame", {});
    context.expect(flow.logon.account == "a" && flow.logon.password == "b", "đang chờ thì không nhận chữ");
    context.expect(ui::panel::take_asks(flow).empty(), "đang chờ thì không nhờ lần hai");
    ui::panel::press_flow(flow, "LogOn_Last", {});
    context.expect(!ui::panel::take_flow(flow), "đang chờ thì nút thoát không đi ra");
}

void online_roster_opens_the_select_panel(Context& context) {
    const World world = sample_world();
    const LoginFacts facts = world.facts();
    LoginFlow flow = online_flow();
    type_text(flow, U"a\tb", facts);
    ui::panel::press_flow(flow, "LogOn_LogOnGame", facts);
    static_cast<void>(ui::panel::take_asks(flow));
    ui::panel::deliver_online(flow, roster_reply(5, RoleSex::kMale), facts);
    context.expect(flow.step == FlowStep::kRoles && !flow.is_waiting, "danh sách mở bảng chọn");
    context.expect(!flow.system_info.is_open, "hộp 'đang nối' đã đóng");
    const Role* shown = ui::panel::chosen_role(flow.select);
    context.expect(shown != nullptr && shown->id == 5 && shown->name == "Lam", "nhân vật của máy chủ ở ô đầu");
    context.expect(shown != nullptr && shown->portrait == ui::panel::kMalePortrait, "chân dung đầu của giới nam");
    context.expect(flow.book.rows.empty(), "không ghi vào sổ cục bộ");
    context.expect(!ui::panel::book_text(flow), "sổ cục bộ không đổi nên không có gì để ghi tệp");
}

// Chân dung và bộ đồ máy chủ lưu (v9) được giữ và đổi ra ảnh cùng ba id hình trang phục; chân dung 0 mới
// lấy chân dung đầu của giới.
void online_roster_keeps_portrait_and_outfit(Context& context) {
    const World world = sample_world();
    const LoginFacts facts = world.facts();
    LoginFlow flow = online_flow();
    type_text(flow, U"a	b", facts);
    ui::panel::press_flow(flow, "LogOn_LogOnGame", facts);
    static_cast<void>(ui::panel::take_asks(flow));
    OnlineReply reply = roster_reply(5, RoleSex::kFemale);
    reply.roles.front().portrait = 2;
    reply.roles.front().outfit = 1;
    ui::panel::deliver_online(flow, reply, facts);
    const Role* shown = ui::panel::chosen_role(flow.select);
    context.expect(shown != nullptr && shown->portrait == 2, "giữ chân dung máy chủ lưu");
    context.expect(shown != nullptr && shown->icon == "set:Face image:Girl_2", "ảnh theo chân dung");
    const bool is_outfit = shown != nullptr && shown->outfit == 1 && shown->body == 438;
    context.expect(is_outfit && shown->foot == 441 && shown->arm == 444, "bộ đồ 1 thành ba id hình");
}

// CharacterList::can_create tắt thì bảng chọn không mở bảng tạo, dù còn dưới ba nhân vật.
void online_create_follows_the_server_flag(Context& context) {
    const World world = sample_world();
    const LoginFacts facts = world.facts();
    LoginFlow flow = online_flow();
    type_text(flow, U"a	b", facts);
    ui::panel::press_flow(flow, "LogOn_LogOnGame", facts);
    static_cast<void>(ui::panel::take_asks(flow));
    OnlineReply reply = roster_reply(5, RoleSex::kMale);
    reply.can_create = false;
    ui::panel::deliver_online(flow, reply, facts);
    ui::panel::press_flow(flow, "SelectRole_TargetInfo_Button2", facts);
    context.expect(flow.step == FlowStep::kRoles, "máy chủ không cho tạo thì ở lại bảng chọn");
    reply.can_create = true;
    flow.is_waiting = true;
    ui::panel::deliver_online(flow, reply, facts);
    ui::panel::press_flow(flow, "SelectRole_TargetInfo_Button2", facts);
    context.expect(flow.step == FlowStep::kCreate, "máy chủ cho tạo thì mở bảng tạo");
}

[[nodiscard]] std::vector<std::string> names_of(const std::vector<ui::panel::PostedEvent>& events) {
    std::vector<std::string> names;
    for (const ui::panel::PostedEvent& event : events) names.push_back(event.name);
    return names;
}

[[nodiscard]] OnlineReply two_role_reply() {
    OnlineReply reply = roster_reply(5, RoleSex::kMale);
    Role second = reply.roles.front();
    second.name = "Hai";
    second.id = 6;
    reply.roles.push_back(second);
    return reply;
}

// Chuỗi đẩy cho script GAMELOGIN_*: đóng bước cũ, mở bước mới, làm tươi danh sách khi ở lại bảng chọn.
void flow_events_follow_the_steps(Context& context) {
    const World world = sample_world();
    const LoginFacts facts = world.facts();
    LoginFlow flow = online_flow();
    static_cast<void>(ui::panel::take_flow_events(flow));
    type_text(flow, U"a	b", facts);
    ui::panel::press_flow(flow, "LogOn_LogOnGame", facts);
    static_cast<void>(ui::panel::take_asks(flow));
    ui::panel::deliver_online(flow, two_role_reply(), facts);
    const std::vector<std::string> opened = names_of(ui::panel::take_flow_events(flow));
    const std::vector<std::string> want_open = {
        "GAMELOGIN_CLOSE_SYSTEM_INFO", "GAMELOGIN_CLOSE_COUNT_INPUT", "GAMELOGIN_OPEN_SELECT_CHARACTOR"};
    context.expect(opened == want_open, "vào bảng chọn: đóng hộp, đóng bảng tài khoản, mở bảng chọn");
    context.expect(ui::panel::take_flow_events(flow).empty(), "lấy rồi thì hết");
    ui::panel::deliver_online(flow, two_role_reply(), facts);
    static_cast<void>(ui::panel::take_flow_events(flow));
    flow.is_waiting = true;
    ui::panel::deliver_online(flow, two_role_reply(), facts);
    const std::vector<std::string> kept = names_of(ui::panel::take_flow_events(flow));
    const std::vector<std::string> want_refresh = {
        "GAMELOGIN_CLOSE_SYSTEM_INFO", "GAMELOGIN_REFRESH_ROLE_SELECT_CHARACTOR"};
    context.expect(kept == want_refresh, "ở lại bảng chọn thì làm tươi danh sách");
}

// Việc GameProduceLogin:* của script: chọn ô bắn GAMELOGIN_SELECTCHARACTER, vào game nhờ máy chủ, đủ ba
// nhân vật hay máy chủ không cho tạo thì hiện hộp đầy, ô sai và bước sai bị bỏ.
void script_calls_drive_the_select_step(Context& context) {
    const World world = sample_world();
    const LoginFacts facts = world.facts();
    LoginFlow flow = online_flow();
    type_text(flow, U"a	b", facts);
    ui::panel::press_flow(flow, "LogOn_LogOnGame", facts);
    static_cast<void>(ui::panel::take_asks(flow));
    ui::panel::deliver_online(flow, two_role_reply(), facts);
    static_cast<void>(ui::panel::take_flow_events(flow));
    using ui::panel::Ask;
    using ui::panel::Call;
    context.expect(ui::panel::apply_script_call(flow, Call{.ask = Ask::kMoveToCharacter, .text = "1"}, facts),
        "MoveToCharacter là việc của chuỗi đăng nhập");
    const std::vector<ui::panel::PostedEvent> moved = ui::panel::take_flow_events(flow);
    const bool is_moved = moved.size() == 1 && moved.front().name == "GAMELOGIN_SELECTCHARACTER" &&
        moved.front().args.size() == 1 && moved.front().args.front() == "1";
    context.expect(is_moved && flow.select.selected == 1, "chọn ô 1 bắn GAMELOGIN_SELECTCHARACTER(1)");
    static_cast<void>(ui::panel::apply_script_call(flow, Call{.ask = Ask::kMoveToCharacter, .text = "1"}, facts));
    context.expect(ui::panel::take_flow_events(flow).empty(), "chọn lại ô đang chọn không bắn gì");
    static_cast<void>(ui::panel::apply_script_call(flow, Call{.ask = Ask::kMoveToCharacter, .text = "2"}, facts));
    static_cast<void>(ui::panel::apply_script_call(flow, Call{.ask = Ask::kMoveToCharacter, .text = "x"}, facts));
    context.expect(ui::panel::take_flow_events(flow).empty() && flow.select.selected == 1, "ô ngoài số nhân vật hay không phải số bị bỏ");
    context.expect(!ui::panel::apply_script_call(flow, Call{.ask = Ask::kPushEvent, .text = "X"}, facts),
        "việc không thuộc chuỗi đăng nhập thì trả false");

    static_cast<void>(ui::panel::apply_script_call(flow, Call{.ask = Ask::kEnterGame, .text = "0"}, facts));
    std::vector<OnlineAsk> asks = ui::panel::take_asks(flow);
    context.expect(asks.size() == 1 && asks.front().work == OnlineWork::kEnter && asks.front().role.id == 5,
        "SendEnterGameMsg(0) nhờ vào game với nhân vật ô 0");

    OnlineReply closed = two_role_reply();
    closed.can_create = false;
    flow.is_waiting = true;
    ui::panel::deliver_online(flow, closed, facts);
    flow.system_info.is_open = false;
    static_cast<void>(ui::panel::apply_script_call(flow, Call{.ask = Ask::kOpenCreateRole}, facts));
    context.expect(flow.step == FlowStep::kRoles && flow.system_info.is_open, "máy chủ không cho tạo: hộp 'đầy', ở lại bảng chọn");
}

void online_enter_waits_for_the_server(Context& context) {
    const World world = sample_world();
    const LoginFacts facts = world.facts();
    LoginFlow flow = online_flow();
    type_text(flow, U"a\tb", facts);
    ui::panel::press_flow(flow, "LogOn_LogOnGame", facts);
    static_cast<void>(ui::panel::take_asks(flow));
    ui::panel::deliver_online(flow, roster_reply(5, RoleSex::kFemale), facts);
    ui::panel::press_flow(flow, "SelectRole_Play", facts);
    context.expect(!ui::panel::take_flow(flow), "bấm vào game chưa vào ngay: máy chủ chưa nhận");
    std::vector<OnlineAsk> asks = ui::panel::take_asks(flow);
    context.expect(asks.size() == 1 && asks.front().work == OnlineWork::kEnter && asks.front().role.id == 5, "nhờ EnterGame với id của máy chủ");

    OnlineReply entered;
    entered.kind = OnlineReply::Kind::kEntered;
    entered.scene = 2;
    ui::panel::deliver_online(flow, entered, facts);
    context.expect(ui::panel::take_flow(flow) == LogonAction::kEnterGame, "máy chủ nhận rồi mới ra lệnh vào game");
    const Role* going = ui::panel::entering_role(flow);
    context.expect(going != nullptr && going->id == 5, "nhân vật vào game là nhân vật máy chủ");
}

void online_refusal_shows_the_reason_and_unblocks(Context& context) {
    LoginFlow flow = online_flow();
    type_text(flow, U"a\tb", {});
    ui::panel::press_flow(flow, "LogOn_LogOnGame", {});
    static_cast<void>(ui::panel::take_asks(flow));
    OnlineReply refused;
    refused.kind = OnlineReply::Kind::kRefused;
    refused.fault = OnlineFault::kBadLogin;
    ui::panel::deliver_online(flow, refused, {});
    context.expect(flow.step == FlowStep::kAccount && !flow.is_waiting, "từ chối: ở lại bảng tài khoản, hết chờ");
    context.expect(flow.system_info.is_open && flow.system_info.text == ui::panel::online_text(OnlineFault::kBadLogin), "hộp nêu lý do");
    ui::panel::press_flow(flow, ui::panel::kSystemInfoClose, {});
    type_text(flow, U"x", {});
    context.expect(flow.logon.password == "bx", "gõ lại được sau khi bị từ chối");
}

void online_lost_session_returns_to_the_account_panel(Context& context) {
    const World world = sample_world();
    const LoginFacts facts = world.facts();
    LoginFlow flow = online_flow();
    type_text(flow, U"a\tb", facts);
    ui::panel::press_flow(flow, "LogOn_LogOnGame", facts);
    static_cast<void>(ui::panel::take_asks(flow));
    ui::panel::deliver_online(flow, roster_reply(5, RoleSex::kMale), facts);
    OnlineReply lost;
    lost.kind = OnlineReply::Kind::kLost;
    lost.fault = OnlineFault::kTimeout;
    ui::panel::deliver_online(flow, lost, facts);
    context.expect(flow.step == FlowStep::kAccount && !flow.is_waiting, "mất phiên: về bảng tài khoản");
    context.expect(flow.remote.rows.empty(), "nhân vật của phiên đã mất bị bỏ");
    context.expect(flow.system_info.is_open && flow.system_info.text == ui::panel::online_text(OnlineFault::kTimeout), "nêu lý do");
}

void online_back_drops_the_session(Context& context) {
    const World world = sample_world();
    const LoginFacts facts = world.facts();
    LoginFlow flow = online_flow();
    type_text(flow, U"a\tb", facts);
    ui::panel::press_flow(flow, "LogOn_LogOnGame", facts);
    static_cast<void>(ui::panel::take_asks(flow));
    ui::panel::deliver_online(flow, roster_reply(5, RoleSex::kMale), facts);
    ui::panel::press_flow(flow, "SelectRole_Last", facts);
    context.expect(flow.step == FlowStep::kAccount, "về bảng tài khoản");
    const std::vector<OnlineAsk> asks = ui::panel::take_asks(flow);
    context.expect(asks.size() == 1 && asks.front().work == OnlineWork::kDrop, "trả phiên cho máy chủ");
    context.expect(flow.remote.rows.empty(), "bỏ nhân vật của máy chủ");
}

void online_unsolicited_reply_is_ignored(Context& context) {
    LoginFlow flow = online_flow();
    ui::panel::deliver_online(flow, roster_reply(5, RoleSex::kMale), {});
    context.expect(flow.step == FlowStep::kAccount && flow.remote.rows.empty(), "trả lời không ai hỏi bị bỏ");
    LoginFlow offline;
    ui::panel::start_login(offline);
    ui::panel::deliver_online(offline, roster_reply(5, RoleSex::kMale), {});
    context.expect(offline.step == FlowStep::kAccount, "chế độ cục bộ không nhận trả lời của máy chủ");
}

void online_create_and_delete_ask_the_server(Context& context) {
    const World world = sample_world();
    const LoginFacts facts = world.facts();
    LoginFlow flow = online_flow();
    type_text(flow, U"a\tb", facts);
    ui::panel::press_flow(flow, "LogOn_LogOnGame", facts);
    static_cast<void>(ui::panel::take_asks(flow));
    ui::panel::deliver_online(flow, roster_reply(5, RoleSex::kMale), facts);

    ui::panel::press_flow(flow, "SelectRole_Delete", facts);
    ui::panel::press_flow(flow, "SelectRole_Delete", facts);
    std::vector<OnlineAsk> asks = ui::panel::take_asks(flow);
    context.expect(asks.size() == 1 && asks.front().work == OnlineWork::kDelete && asks.front().role.id == 5, "xoá nhờ máy chủ, không xoá ở sổ cục bộ");
    context.expect(!flow.remote.rows.empty(), "nhân vật còn cho tới khi máy chủ trả danh sách mới");

    OnlineReply emptied;
    emptied.kind = OnlineReply::Kind::kRoster;
    ui::panel::deliver_online(flow, emptied, facts);
    context.expect(flow.step == FlowStep::kRoles && flow.select.count == 0, "danh sách rỗng sau khi xoá");

    ui::panel::press_flow(flow, "SelectRole_Create", facts);
    type_text(flow, U"Huyền", facts);
    ui::panel::press_flow(flow, "CreateRole_Author", facts);
    asks = ui::panel::take_asks(flow);
    context.expect(asks.size() == 1 && asks.front().work == OnlineWork::kCreate && asks.front().role.name == "Huyền", "tạo nhờ máy chủ");
    context.expect(flow.step == FlowStep::kCreate && flow.is_waiting, "chờ máy chủ nhận tên");
}

constexpr std::array kCases{
    Case{.name = "online_sign_in_asks_instead_of_opening_roles", .body = &online_sign_in_asks_instead_of_opening_roles},
    Case{.name = "online_waiting_blocks_input", .body = &online_waiting_blocks_input},
    Case{.name = "online_roster_opens_the_select_panel", .body = &online_roster_opens_the_select_panel},
    Case{.name = "online_roster_keeps_portrait_and_outfit", .body = &online_roster_keeps_portrait_and_outfit},
    Case{.name = "online_create_follows_the_server_flag", .body = &online_create_follows_the_server_flag},
    Case{.name = "flow_events_follow_the_steps", .body = &flow_events_follow_the_steps},
    Case{.name = "script_calls_drive_the_select_step", .body = &script_calls_drive_the_select_step},
    Case{.name = "online_enter_waits_for_the_server", .body = &online_enter_waits_for_the_server},
    Case{.name = "online_refusal_shows_the_reason_and_unblocks", .body = &online_refusal_shows_the_reason_and_unblocks},
    Case{.name = "online_lost_session_returns_to_the_account_panel", .body = &online_lost_session_returns_to_the_account_panel},
    Case{.name = "online_back_drops_the_session", .body = &online_back_drops_the_session},
    Case{.name = "online_unsolicited_reply_is_ignored", .body = &online_unsolicited_reply_is_ignored},
    Case{.name = "online_create_and_delete_ask_the_server", .body = &online_create_and_delete_ask_the_server},
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
    Case{.name = "zoom_buttons_set_the_shown_speed", .body = &zoom_buttons_set_the_shown_speed},
    Case{.name = "dice_changes_with_the_salt", .body = &dice_changes_with_the_salt},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_flow_tests: mọi ca phải qua");
    return 0;
}
