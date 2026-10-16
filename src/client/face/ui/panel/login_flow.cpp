// Chuỗi đăng nhập (xem login_flow.hpp). Việc của từng bảng được lấy ngay trong lần nhấn hay lần
// gõ, trước khi vẽ, nên khung đó đã hiện bảng kế.
#include "ui/panel/login_flow.hpp"

#include "gui/sheet.hpp"
#include "hero/hero.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/create_role.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/logon.hpp"
#include "ui/panel/online.hpp"
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
#include <span>
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

// Sổ đang dùng: nhân vật của máy chủ khi trực tuyến, sổ cục bộ khi không.
[[nodiscard]] Book& book_of(LoginFlow& flow) noexcept {
    return flow.is_online ? flow.remote : flow.book;
}

void show_roles(LoginFlow& flow, std::uint8_t selected) {
    if (flow.step == FlowStep::kCreate) close_create(flow.create);
    flow.step = FlowStep::kRoles;
    flow.enter_game = false;
    const Roster roster = roster_of(book_of(flow), flow.account);
    open_select(flow.select, roster, selected);
}

// Nhờ phần nối máy chủ một việc rồi chờ trả lời, hộp thông báo hiện câu "đang nối". Việc vượt trần hàng chờ bị bỏ
// (không xảy ra: chuỗi chỉ nhờ khi không còn việc nào đang chờ).
void request_online(LoginFlow& flow, OnlineAsk&& ask) {
    if (flow.asks.size() >= kAskCap) return;
    flow.asks.push_back(std::move(ask));
    flow.is_waiting = true;
    show_system_info(flow.system_info, kOnlineWaiting);
}

// Trả phiên khi rời nhân vật của máy chủ (về bảng tài khoản hay bảng chọn máy chủ): không đợi trả lời.
void drop_online(LoginFlow& flow) {
    if (!flow.is_online) return;
    flow.remote = {};
    if (flow.asks.size() >= kAskCap) return;
    flow.asks.push_back(OnlineAsk{.work = OnlineWork::kDrop});
}

// Việc đăng nhập của bảng tài khoản ở chế độ trực tuyến.
void sign_in_online(LoginFlow& flow) {
    OnlineAsk ask{.work = OnlineWork::kSignIn};
    if (!flow.chosen) return;
    const std::size_t area = flow.chosen->area;
    if (area >= flow.directory.areas.size()) return;
    const LoginArea& where = *std::next(flow.directory.areas.begin(), static_cast<std::ptrdiff_t>(area));
    const LoginServer* server = server_at(flow.directory, *flow.chosen);
    if (server == nullptr) return;
    ask.server = ServerName{.area = where.name, .server = server->name};
    ask.account = flow.account;
    ask.password = flow.logon.password;
    request_online(flow, std::move(ask));
}

void apply_delete(LoginFlow& flow) {
    if (flow.is_online) {
        const Role* role = chosen_role(flow.select);
        if (role == nullptr) return;
        request_online(flow, OnlineAsk{.work = OnlineWork::kDelete, .role = *role});
        return;
    }
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
    if (flow.is_online) {
        // Máy chủ giữ luật tên cuối cùng; kiểm trước ở đây chỉ để khỏi gửi tên rỗng, dài hay trùng đã biết.
        const NameFault online_fault = admit_name(flow.remote, flow.account, role.name);
        if (online_fault != NameFault::kOk) {
            notify_create(flow.create, name_fault_text(online_fault));
            return;
        }
        request_online(flow, OnlineAsk{.work = OnlineWork::kCreate, .role = role});
        return;
    }
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
    if (flow.chosen && flow.last != flow.chosen) {
        flow.last = flow.chosen;
        flow.is_last_dirty = true;
    }
    // Trực tuyến: vào game khi máy chủ đã nhận (deliver_online kEntered), không phải lúc nhấn.
    if (flow.is_online) {
        request_online(flow, OnlineAsk{.work = OnlineWork::kEnter, .role = *role});
        return;
    }
    flow.enter_game = true;
}

void apply_back(LoginFlow& flow) {
    drop_online(flow);
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
    drop_online(flow);
    flow.is_online = false;
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
    if (flow.is_online) {
        sign_in_online(flow);
        return;
    }
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
    const LoginServer* picked = server_at(flow.directory, server);
    flow.is_online = picked != nullptr && picked->is_online;
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

// Danh sách đuôi đang mở thì nó chiếm chuột: lần nhấn chỉ dành cho nó (facts.element là mục dưới chuột).
void press_account(LoginFlow& flow, std::string_view window, const LoginFacts& facts) {
    if (is_suffix_open(flow.logon)) {
        press_suffix_list(flow.logon, window, facts.element);
        return;
    }
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
    drop_online(flow);
    flow.is_online = false;
    flow.is_waiting = false;
    open_logon(flow.logon);
    flow.step = FlowStep::kAccount;
    flow.enter_game = false;
    flow.pending.reset();
    flow.pose = {};
    flow.chosen.reset();
    if (!flow.directory.areas.empty()) go_to_servers(flow);
}

void mark_online(LoginFlow& flow, std::span<const ServerName> names) {
    for (LoginArea& area : flow.directory.areas) {
        for (LoginServer& server : area.servers) {
            const auto is_named = [&](const ServerName& name) { return name.area == area.name && name.server == server.name; };
            server.is_online = std::ranges::any_of(names, is_named);
        }
    }
}

std::vector<OnlineAsk> take_asks(LoginFlow& flow) noexcept {
    return std::exchange(flow.asks, {});
}

namespace {

// Nhân vật của máy chủ thành nhân vật của sổ. Máy chủ chưa lưu chân dung nên lấy chân dung đầu của giới.
void admit_remote(LoginFlow& flow, const OnlineReply& reply, const LoginFacts& facts) {
    flow.remote = {};
    for (Role role : reply.roles) {
        role.portrait = role.sex == 1 ? kMalePortrait : kFemalePortrait;
        if (facts.portraits != nullptr) role.icon = std::string(facts.portraits->image_of(hero::PortraitId{role.portrait}));
        flow.remote.rows.push_back(StoredRole{.account = flow.account, .role = std::move(role)});
    }
}

void settle_roster(LoginFlow& flow, const OnlineReply& reply, const LoginFacts& facts) {
    const FlowStep was = flow.step;
    admit_remote(flow, reply, facts);
    const Roster roster = roster_of(flow.remote, flow.account);
    const auto newest = static_cast<std::uint8_t>(roster.count == 0 ? 0 : roster.count - 1U);
    show_roles(flow, was == FlowStep::kCreate ? newest : (was == FlowStep::kAccount ? std::uint8_t{0} : flow.select.selected));
}

void settle_refused(LoginFlow& flow, OnlineFault fault) {
    const std::string_view text = online_text(fault);
    if (flow.step == FlowStep::kCreate) {
        notify_create(flow.create, text);
        return;
    }
    show_system_info(flow.system_info, text);
}

// Mất phiên: về bảng tài khoản (máy chủ vẫn là máy chủ đã chọn, nên nhập lại là đăng nhập lại) kèm lý do.
void settle_lost(LoginFlow& flow, OnlineFault fault) {
    flow.remote = {};
    if (flow.step == FlowStep::kCreate) close_create(flow.create);
    flow.step = FlowStep::kAccount;
    flow.enter_game = false;
    flow.pose = {};
    open_logon(flow.logon);
    show_system_info(flow.system_info, online_text(fault));
}

} // namespace

void deliver_online(LoginFlow& flow, const OnlineReply& reply, const LoginFacts& facts) {
    if (!flow.is_online) return;
    using Kind = OnlineReply::Kind;
    if (reply.kind == Kind::kLost) {
        flow.is_waiting = false;
        settle_lost(flow, reply.fault);
        return;
    }
    if (!flow.is_waiting) return;
    if (reply.kind == Kind::kStyle) return;
    flow.is_waiting = false;
    flow.system_info.is_open = false;
    if (reply.kind == Kind::kRoster) settle_roster(flow, reply, facts);
    if (reply.kind == Kind::kRefused) settle_refused(flow, reply.fault);
    if (reply.kind == Kind::kEntered && flow.entering) flow.enter_game = true;
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

bool suffix_list_open(const LoginFlow& flow) noexcept {
    return flow.step == FlowStep::kAccount && is_suffix_open(flow.logon);
}

void dismiss_flow(LoginFlow& flow) noexcept {
    if (flow.step == FlowStep::kAccount) dismiss_suffix_list(flow.logon);
}

void release_flow(LoginFlow& flow, std::string_view window) {
    flow.pose.zoom = 0;
    if (flow.step == FlowStep::kAccount) release_suffix_list(flow.logon, window);
    if (flow.step != FlowStep::kCreate) return;
    std::vector<Call> calls;
    release_create(flow.create, calls);
}

void hover_flow(LoginFlow& flow, std::string_view window, std::optional<std::size_t> element, bool is_down) {
    if (flow.step == FlowStep::kAccount) move_suffix_list(flow.logon, window, element, is_down);
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
    if (flow.is_waiting) return;
    if (flow.step == FlowStep::kServers) {
        press_servers(flow, window, facts);
        return;
    }
    if (flow.step == FlowStep::kAccount) {
        press_account(flow, window, facts);
        return;
    }
    if (flow.step == FlowStep::kRoles) {
        press_roles(flow, window, facts);
        return;
    }
    press_making(flow, window, facts);
}

void type_flow(LoginFlow& flow, char32_t code, const LoginFacts& facts) {
    if (flow.is_waiting) return;
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
    if (flow.step != FlowStep::kAccount || flow.is_waiting) return;
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
