// Chuỗi đăng nhập (xem login_flow.hpp). Việc của từng bảng được lấy ngay trong lần nhấn hay lần
// gõ, trước khi vẽ, nên khung đó đã hiện bảng kế.
#include "ui/panel/login_flow.hpp"

#include "gui/sheet.hpp"
#include "hero/hero.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/create_role.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/logon.hpp"
#include "ui/panel/portraits.hpp"
#include "ui/panel/role_cast.hpp"
#include "ui/panel/role_pose.hpp"
#include "ui/panel/roles.hpp"
#include "ui/panel/select_role.hpp"
#include "ui/panel/select_server.hpp"
#include "ui/panel/servers.hpp"
#include "ui/panel/system_info.hpp"
#include "ui/panel/wording.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <iterator>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::ui::panel {
namespace {

constexpr std::int32_t kMaxShort = 65535;

// Id của bảng ngoại hình (0..65535) từ số mà bảng tạo giữ; số ngoài miền thì kẹp vào miền.
[[nodiscard]] std::uint16_t short_of(std::int32_t id) noexcept {
    return static_cast<std::uint16_t>(std::clamp(id, 0, kMaxShort));
}

// Một bước xorshift32 rồi lấy số trong [0, top]; top không âm.
[[nodiscard]] std::int32_t roll_dice(std::uint32_t& state, std::int32_t top) noexcept {
    state ^= state << 13U;
    state ^= state >> 17U;
    state ^= state << 5U;
    if (state == 0) state = kDiceSeed;
    const std::uint32_t span = static_cast<std::uint32_t>(std::max(top, 0)) + 1U;
    return static_cast<std::int32_t>(state % span);
}

// Điều bảng tạo đọc của game: bảng, bản dịch và xúc xắc của chuỗi (trộn muối của sự kiện trước).
[[nodiscard]] CreateFacts create_facts(LoginFlow& flow, const LoginFacts& facts) {
    flow.dice ^= facts.salt;
    if (flow.dice == 0) flow.dice = kDiceSeed;
    CreateFacts made;
    made.cast = facts.cast;
    made.words = facts.words;
    made.roll = [state = &flow.dice](std::int32_t top) { return roll_dice(*state, top); };
    return made;
}

void show_roles(LoginFlow& flow, std::uint8_t selected) {
    if (flow.step == FlowStep::kCreate) close_create(flow.create);
    flow.step = FlowStep::kRoles;
    flow.enter_game = false;
    const Roster roster = roster_of(flow.book, flow.account);
    open_select(flow.select, roster, selected);
}

void apply_delete(LoginFlow& flow) {
    const bool erased = erase_role(flow.book, flow.account, flow.select.selected);
    if (!erased) return;
    flow.dirty = true;
    show_roles(flow, flow.select.selected);
}

// Bộ đồ tân thủ mà bảng tạo đã đặt cho game, dưới dạng ba id hình của nhân vật.
void wear_outfit(Role& role, const CreateRole& panel, const LoginFacts& facts) {
    const NewbieOutfit* outfit = facts.cast == nullptr ? nullptr : facts.cast->outfit(panel.game.outfit);
    if (outfit == nullptr) return;
    role.body = outfit->body;
    role.arm = outfit->arm;
    role.foot = outfit->foot;
}

// Nhân vật sẽ lưu: tên trong ô tên, giới của bảng, và mặt, tóc, ảnh chân dung, bộ đồ mà bảng đã
// đặt cho game. Nhân vật mới là cấp 1, chưa nhập môn.
[[nodiscard]] Role drafted_role(const CreateRole& panel, const LoginFacts& facts) {
    Role made;
    made.name = std::string(create_name(panel));
    made.sex = panel.sex == kMale ? std::uint8_t{1} : std::uint8_t{0};
    made.face = short_of(panel.game.face);
    made.hair = short_of(panel.game.hair);
    wear_outfit(made, panel, facts);
    made.level = kNewLevel;
    made.sect = kNewSect;
    made.portrait = panel.game.portrait;
    if (facts.portraits != nullptr) made.icon = std::string(facts.portraits->image_of(hero::PortraitId{made.portrait}));
    return made;
}

// Việc CreateRole của bảng tạo: thêm nhân vật vào sổ rồi về bảng chọn ở nhân vật mới; tên không
// được nhận thì ở lại bảng tạo với lời nhắn.
void accept_create(LoginFlow& flow, const LoginFacts& facts) {
    const Role role = drafted_role(flow.create, facts);
    const NameFault fault = add_role(flow.book, flow.account, role);
    if (fault != NameFault::kOk) {
        notify_create(flow.create, name_fault_text(fault));
        return;
    }
    flow.dirty = true;
    const Roster roster = roster_of(flow.book, flow.account);
    const auto last = static_cast<std::uint8_t>(roster.count - 1U);
    show_roles(flow, last);
}

// Làm các việc bảng tạo vừa nhờ game. Bảng đã rời bước tạo thì việc còn lại bỏ.
void settle_create(LoginFlow& flow, const LoginFacts& facts, const std::vector<Call>& calls) {
    for (const Call& call : calls) {
        if (flow.step != FlowStep::kCreate) return;
        if (call.ask == Ask::kShowSystemInfo) notify_create(flow.create, call.text);
        if (call.ask == Ask::kCreateRole) accept_create(flow, facts);
        if (call.ask == Ask::kChangeToSelectRole) show_roles(flow, flow.select.selected);
    }
}

void apply_create(LoginFlow& flow, const LoginFacts& facts) {
    if (flow.select.count >= kRoleCap) return;
    flow.step = FlowStep::kCreate;
    flow.pose = {};
    std::vector<Call> calls;
    open_create(flow.create, create_facts(flow, facts), calls);
    settle_create(flow, facts, calls);
}

void apply_enter(LoginFlow& flow) {
    const Role* role = chosen_role(flow.select);
    if (role == nullptr) return;
    flow.entering = *role;
    flow.enter_game = true;
    if (flow.chosen && flow.last != flow.chosen) {
        flow.last = flow.chosen;
        flow.is_last_dirty = true;
    }
}

void apply_back(LoginFlow& flow) {
    flow.step = FlowStep::kAccount;
    flow.enter_game = false;
    open_logon(flow.logon);
}

void apply_select(LoginFlow& flow, SelectAction action, const LoginFacts& facts) {
    if (action == SelectAction::kDelete) apply_delete(flow);
    if (action == SelectAction::kCreate) apply_create(flow, facts);
    if (action == SelectAction::kEnter) apply_enter(flow);
    if (action == SelectAction::kBack) apply_back(flow);
}

void press_roles(LoginFlow& flow, std::string_view window, const LoginFacts& facts) {
    press_select(flow.select, window);
    const std::optional<SelectAction> action = take_select(flow.select);
    if (!action) return;
    apply_select(flow, *action, facts);
}

void press_making(LoginFlow& flow, std::string_view window, const LoginFacts& facts) {
    std::vector<Call> calls;
    press_create(flow.create, window, create_facts(flow, facts), calls);
    settle_create(flow, facts, calls);
}

// Mở lại bảng chọn máy chủ (ExitToSelectServer, FUN_14062c450 của Game.exe): máy chủ đã chọn được
// chọn lại, chữ tài khoản giữ nguyên.
void go_to_servers(LoginFlow& flow) {
    flow.step = FlowStep::kServers;
    flow.enter_game = false;
    flow.pose = {};
    open_servers(flow.servers, flow.directory, flow.last, flow.chosen);
}

void pull_logon(LoginFlow& flow) {
    const std::optional<LogonAction> action = take_request(flow.logon);
    if (!action) return;
    if (*action == LogonAction::kLeave && !flow.directory.areas.empty()) {
        go_to_servers(flow);
        return;
    }
    if (*action != LogonAction::kEnterGame) {
        flow.pending = action;
        return;
    }
    flow.account.assign(account_text(flow.logon));
    show_roles(flow, 0);
}

// Dòng "sắp đăng nhập: <máy chủ>" của bảng tài khoản (SeverSituation_InfoWindow).
void note_situation(LoginFlow& flow, ServerRef chosen, const LoginFacts& facts) {
    flow.logon.situation.clear();
    const LoginServer* server = server_at(flow.directory, chosen);
    if (server == nullptr || facts.words == nullptr) return;
    const std::array<std::string_view, 1> slots = {std::string_view(server->name)};
    format_key(flow.logon.situation, *facts.words, "#{FWQWL_201130_03}", slots);
}

// SelectLoginServer đã nhận máy chủ: sang bảng tài khoản.
void enter_account(LoginFlow& flow, ServerRef server, const LoginFacts& facts) {
    flow.chosen = server;
    flow.step = FlowStep::kAccount;
    flow.enter_game = false;
    open_logon(flow.logon);
    note_situation(flow, server, facts);
}

// Việc bảng chọn máy chủ vừa nhờ: sang bảng tài khoản, mở trang, thoát. Bấm xác nhận khi chưa chọn gì
// thì hiện hộp thông báo "phải chọn một máy chủ" (MUST_SELECTSERVER).
void pull_servers(LoginFlow& flow, const LoginFacts& facts) {
    const std::optional<ServerRequest> request = take_server_request(flow.servers);
    if (!request) return;
    if (request->work == ServerWork::kEnter) enter_account(flow, request->server, facts);
    if (request->work == ServerWork::kOpenTopUp) flow.pending = LogonAction::kOpenTopUp;
    if (request->work == ServerWork::kOpenRegister) flow.pending = LogonAction::kOpenRegister;
    if (request->work == ServerWork::kLeave) flow.pending = LogonAction::kLeave;
    if (request->work == ServerWork::kMustPick) show_system_info(flow.system_info, "#{MUST_SELECTSERVER}");
}

void press_servers(LoginFlow& flow, std::string_view window, const LoginFacts& facts) {
    press_server(flow.servers,
        ServerPress{.window = window, .element = facts.element, .is_double = facts.is_double, .words = facts.words});
    pull_servers(flow, facts);
}

void press_account(LoginFlow& flow, std::string_view window) {
    press_logon(flow.logon, window);
    pull_logon(flow);
}

void type_account(LoginFlow& flow, char32_t code) {
    if (code == kEscapeKey && !flow.directory.areas.empty()) {
        go_to_servers(flow);
        return;
    }
    type_logon(flow.logon, code);
    pull_logon(flow);
}

void type_servers(LoginFlow& flow, char32_t code, const LoginFacts& facts) {
    type_server(flow.servers, code);
    pull_servers(flow, facts);
}

void type_making(LoginFlow& flow, char32_t code, const LoginFacts& facts) {
    std::vector<Call> calls;
    type_create(flow.create, code, create_facts(flow, facts), calls);
    settle_create(flow, facts, calls);
}

[[nodiscard]] float spin_of(std::string_view window) noexcept {
    if (window == kSelectTurnLeft) return kSpinLeft;
    if (window == kSelectTurnRight) return kSpinRight;
    return 0.0F;
}

// Hướng phóng đưa cho camera. Màn tạo lấy số đã chốt lúc nhấn; chuột còn nằm trên nút thì vẫn
// phóng dù lần nhấn không kịp ghi. Bảng chọn chỉ có nút đang giữ.
[[nodiscard]] std::int8_t held_zoom(const LoginFlow& flow, std::string_view window) noexcept {
    const std::int8_t under = zoom_of(window);
    if (flow.step != FlowStep::kCreate) return under != 0 ? under : flow.pose.zoom;
    if (flow.create.game.zoom != 0) return static_cast<std::int8_t>(flow.create.game.zoom);
    return under;
}

void fill_model(ShownModel& model, const Role& role) {
    model.sex = role.sex;
    model.face = role.face;
    model.hair = role.hair;
    model.body = role.body;
    model.arm = role.arm;
    model.foot = role.foot;
}

// Người mẫu của bảng tạo: giới và bộ đồ mà ChangeNewRoleEquipSet đã đặt, mặt và tóc là dòng cao
// mô của kiểu đã chọn.
void fill_create_model(ShownModel& model, const CreateRole& panel, const LoginFacts& facts, std::int8_t flow_zoom) {
    const CreateGame& game = panel.game;
    ModelLook look{.sex = game.sex, .face = game.face, .hair = game.hair};
    const NewbieOutfit* outfit = nullptr;
    if (facts.cast != nullptr) {
        look = facts.cast->model_look(look);
        outfit = facts.cast->outfit(game.outfit);
    }
    model.sex = game.sex == kMale ? std::uint8_t{1} : std::uint8_t{0};
    model.face = short_of(look.face);
    model.hair = short_of(look.hair);
    if (outfit != nullptr) {
        model.body = outfit->body;
        model.arm = outfit->arm;
        model.foot = outfit->foot;
    }
    // Giới chưa có người mẫu hiện tại thì cảnh trống, như lúc ShowModel chưa dựng được người mẫu.
    const std::size_t sex = game.sex == kMale ? 1 : 0;
    const std::int32_t current = *std::next(game.shown.begin(), static_cast<std::ptrdiff_t>(sex));
    model.in_world = current != kNoModel;
    if (current >= kMenpaiModel) model.sect = static_cast<std::int8_t>(current - kMenpaiModel);
    model.is_creating = true;
    model.entries = game.entries;
    model.entry_sex = game.entry_sex == kMale ? std::uint8_t{1} : std::uint8_t{0};
    model.outfit_calls = game.outfit_calls;
    model.zoom = flow_zoom;
}

// Hướng mặt của người mẫu màn tạo, mỗi giới một số: người mẫu vừa thành hiện tại thì quay về 0
// (SetRotation trong ShowModel), và chỉ người mẫu hiện tại của giới game đang nhớ mới quay theo nút.
void turn_create_model(LoginFlow& flow, float seconds) noexcept {
    const CreateGame& game = flow.create.game;
    for (std::size_t sex = 0; sex < flow.create_yaw.size(); ++sex) {
        const auto at = static_cast<std::ptrdiff_t>(sex);
        std::uint32_t& seen = *std::next(flow.seen_turns.begin(), at);
        const std::uint32_t turns = *std::next(game.turns_back.begin(), at);
        if (seen == turns) continue;
        seen = turns;
        *std::next(flow.create_yaw.begin(), at) = 0.0F;
    }
    const auto mine = static_cast<std::ptrdiff_t>(game.sex == kMale ? 1 : 0);
    if (*std::next(game.shown.begin(), mine) == kNoModel) return;
    *std::next(flow.create_yaw.begin(), mine) += flow.pose.spin * kFullTurn * seconds;
}

} // namespace

void start_login(LoginFlow& flow) {
    open_logon(flow.logon);
    flow.step = FlowStep::kAccount;
    flow.enter_game = false;
    flow.pending.reset();
    flow.pose = {};
    flow.chosen.reset();
    if (!flow.directory.areas.empty()) go_to_servers(flow);
}

bool recall_directory(LoginFlow& flow, std::string_view text) {
    flow.directory = {};
    std::optional<ServerDirectory> directory = decode_servers(text);
    if (!directory) return false;
    flow.directory = std::move(*directory);
    return true;
}

void recall_last(LoginFlow& flow, std::string_view text) {
    flow.last = decode_last(flow.directory, text);
    flow.is_last_dirty = false;
}

std::optional<std::string> last_text(const LoginFlow& flow) {
    if (!flow.is_last_dirty || !flow.last) return std::nullopt;
    return encode_last(flow.directory, *flow.last);
}

void mark_last_saved(LoginFlow& flow) noexcept {
    flow.is_last_dirty = false;
}

bool on_account(const LoginFlow& flow) noexcept {
    return flow.step == FlowStep::kAccount;
}

void release_flow(LoginFlow& flow) {
    flow.pose.zoom = 0;
    if (flow.step != FlowStep::kCreate) return;
    std::vector<Call> calls;
    release_create(flow.create, calls);
}

void hover_flow(LoginFlow& flow, std::string_view window, std::optional<std::size_t> element) {
    if (flow.step == FlowStep::kCreate) hover_create(flow.create, window);
    if (flow.step == FlowStep::kServers) hover_server(flow.servers, window, element);
}

void hold_flow(LoginFlow& flow, std::string_view window) noexcept {
    const bool is_making = flow.step == FlowStep::kCreate;
    hold_turn(flow.pose, is_making ? static_cast<float>(flow.create.game.spin) : spin_of(window));
    flow.pose.zoom = held_zoom(flow, window);
}

void advance_flow(LoginFlow& flow, float seconds) noexcept {
    if (flow.step == FlowStep::kCreate) {
        turn_create_model(flow, seconds);
        return;
    }
    advance_yaw(flow.pose, seconds);
}

void roll_flow(LoginFlow& flow, const DetailRoll& roll) noexcept {
    if (flow.step == FlowStep::kCreate) roll_detail(flow.create, roll);
}

ShownModel shown_model(const LoginFlow& flow, const LoginFacts& facts) {
    ShownModel model;
    model.yaw = flow.pose.yaw;
    if (flow.step == FlowStep::kRoles) {
        model.on_role_scene = true;
        model.zoom = flow.pose.zoom;
        const Role* role = chosen_role(flow.select);
        if (role == nullptr) return model;
        fill_model(model, *role);
        model.in_world = true;
        model.slot = flow.select.selected;
        model.zoom = flow.pose.zoom;
        return model;
    }
    if (flow.step != FlowStep::kCreate) return model;
    model.on_role_scene = true;
    std::int8_t zoom = flow.pose.zoom;
    if (zoom == 0) zoom = static_cast<std::int8_t>(flow.create.game.zoom);
    fill_create_model(model, flow.create, facts, zoom);
    model.yaw = *std::next(flow.create_yaw.begin(), static_cast<std::ptrdiff_t>(model.sex));
    return model;
}

void press_flow(LoginFlow& flow, std::string_view window, const LoginFacts& facts) {
    press_system_info(flow.system_info, window);
    if (flow.step == FlowStep::kServers) {
        press_servers(flow, window, facts);
        return;
    }
    if (flow.step == FlowStep::kAccount) {
        press_account(flow, window);
        return;
    }
    if (flow.step == FlowStep::kRoles) {
        press_roles(flow, window, facts);
        return;
    }
    press_making(flow, window, facts);
}

void type_flow(LoginFlow& flow, char32_t code, const LoginFacts& facts) {
    if (flow.step == FlowStep::kServers) {
        type_servers(flow, code, facts);
        return;
    }
    if (flow.step == FlowStep::kAccount) {
        type_account(flow, code);
        return;
    }
    if (flow.step == FlowStep::kCreate) type_making(flow, code, facts);
}

void key_flow(LoginFlow& flow, char32_t code) {
    if (flow.step != FlowStep::kAccount) return;
    key_logon(flow.logon, code);
}

void paint_flow(Deck& deck, const LoginFlow& flow, const gui::TextMeter* meter) {
    if (flow.step == FlowStep::kServers) paint_server(deck, flow.servers);
    if (flow.step == FlowStep::kAccount) paint_logon(deck, flow.logon);
    if (flow.step == FlowStep::kRoles) paint_select(deck, flow.select);
    if (flow.step == FlowStep::kCreate) paint_create(deck, flow.create);
    paint_system_info(deck, flow.system_info, meter);
}

std::optional<LogonAction> take_flow(LoginFlow& flow) noexcept {
    if (flow.enter_game) {
        flow.enter_game = false;
        return LogonAction::kEnterGame;
    }
    const std::optional<LogonAction> pending = flow.pending;
    flow.pending.reset();
    return pending;
}

bool recall_book(LoginFlow& flow, std::string_view text) {
    flow.dirty = false;
    flow.book = {};
    if (text.empty()) return true;
    const std::optional<Book> book = decode_book(text);
    if (!book) return false;
    flow.book = *book;
    return true;
}

std::optional<std::string> book_text(const LoginFlow& flow) {
    if (!flow.dirty) return std::nullopt;
    return encode_book(flow.book);
}

void mark_saved(LoginFlow& flow) noexcept {
    flow.dirty = false;
}

const Role* entering_role(const LoginFlow& flow) noexcept {
    if (!flow.entering) return nullptr;
    return &*flow.entering;
}

} // namespace game::ui::panel
