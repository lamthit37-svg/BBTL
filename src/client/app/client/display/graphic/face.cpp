/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/graphic/face.cpp
 *  PHÂN HỆ   : Display / Graphic / Face
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Giao diện 2D trên khung: bảng đăng nhập, nhịp khung và việc nút nhờ vòng
 *    cửa sổ.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/display/graphic/state.hpp"

#include "client/display/creature.hpp"
#include "client/display/display.hpp"
#include "client/display/graphic/prelude.hpp"
#include "ui/panel/online.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <iterator>
#include <limits>
#include <optional>
#include <utility>
#include <vector>
namespace game::client {

// Mở giao diện nếu đủ shader và dữ liệu; thiếu thì ghi một dòng và bỏ qua, không làm hỏng game.
void Display::State::open_hud(const DisplayDesc& desc) {
    const gpu::PipelineHandle pipeline = catalog->get(render::Pso::kUi);
    if (!pipeline) {
        const core::Error* fault = catalog->fault(render::Pso::kUi);
        if (fault != nullptr) std::println(stderr, "Giao diện: bỏ qua, không dựng được lượt vẽ 2D: {}", *fault);
        if (fault == nullptr) std::println(stderr, "Giao diện: bỏ qua, không dựng được lượt vẽ 2D");
        return;
    }
    std::string shaders = shader_dir_of(desc.data_root);
    core::Result<render::UiPass> made = make_ui(*device, *screen, std::move(shaders), pipeline);
    if (!made) {
        std::println(stderr, "Giao diện: bỏ qua, không dựng được lượt vẽ 2D: {}", made.error());
        return;
    }
    ui_pass = std::make_unique<render::UiPass>(std::move(*made));
    ui::HudDesc hud_desc;
    hud_desc.data_root = desc.data_root;
    hud_desc.texture_tier = texture_tier;
    hud_desc.uses_phone_layout = desc.uses_phone_layout;
    // Phần đọc đĩa đã chạy từ trước thiết bị (kick_loading); chưa có thì Hud::open tự bắt đầu.
    core::Result<ui::Hud> opened =
        hud_prep ? ui::Hud::open(*ui_pass, hud_desc, std::move(*hud_prep)) : ui::Hud::open(*ui_pass, hud_desc);
    hud_prep.reset();
    if (!opened) {
        std::println(stderr, "Giao diện: bỏ qua, không mở được dữ liệu: {}", opened.error());
        return;
    }
    hud = std::make_unique<ui::Hud>(std::move(*opened));
    hud->set_online_servers(desc.online_servers);
    const std::filesystem::path font_file = desc.data_root / "Interface" / "Schema" / "VTNAM14.bin";
    core::Result<ui::BitmapFont> font = ui::BitmapFont::open(font_file);
    if (!font) {
        std::println(stderr, "Nhịp: không có phông bảng số: {}", font.error());
        return;
    }
    const core::Result<std::uint32_t> texture = ui_pass->add_texture(font->atlas());
    if (!texture) {
        std::println(stderr, "Nhịp: không tải được phông: {}", texture.error());
        return;
    }
    pace_font = std::move(*font);
    pace_texture = *texture;
}

void Display::State::kick_loading(const DisplayDesc& desc) {
    if (feeder || desc.data_root.empty()) return;
    hud_prep = take_early_hud(desc);
    tables_job = take_early_tables(desc);
    if (!tables_job.valid()) tables_job = start_player_tables(desc.data_root);
    if (!hud_prep) {
        ui::HudDesc hud_desc;
        hud_desc.data_root = desc.data_root;
        hud_desc.uses_phone_layout = desc.uses_phone_layout;
        hud_prep.emplace(ui::HudPrep::start(hud_desc));
    }
    // Cảnh đầu: lập bảng mesh rồi giao luồng đọc ngay. arm_scene chỉ còn dựng pipeline của cảnh (warm_scene) và
    // phần dựng GPU; mesh đọc xong trong lúc thiết bị còn đang tạo.
    held = desc.scene;
    data_root = desc.data_root;
    feeder = std::make_unique<Feed>();
    if (held) post_load(held, false);
}

void Display::State::arm_scene(const DisplayDesc& desc) {
    held = desc.scene;
    role_scene = desc.role_scene;
    {
        const std::scoped_lock<std::mutex> locked(pending_guard);
        pending = held;
    }
    data_root = desc.data_root;
    save_root = desc.save_root;
    shot_path = desc.shot_path;
    is_bare = desc.is_bare;
    frames_login = !desc.uses_phone_layout;
    ui_density = desc.ui_density > 0.0F ? desc.ui_density : 1.0F;
    is_auto_walk = desc.is_auto_walk;
    auto_strike_from = desc.auto_strike_from;
    seed_ui_events(desc.ui_events);
    arm_auto_login(desc);
    creature_demo = desc.creatures;
    pet_demo = desc.pets;
    impact_demo = desc.impact_id;
    peer_demo = desc.peer_count;
    // Bảng quái đọc vài chục ms. Bắt đầu ngay để khung đầu của --pet/--creature đã có mẫu.
    if ((!creature_demo.empty() || !pet_demo.empty()) && !data_root.empty() && !creature_job.valid()) {
        creature_job = start_creature_tables(data_root);
    }
    talk_demo = desc.talk_demo;
    weapon_item = desc.weapon_item;
    ride_id = desc.ride_id;
    weapon_gem = desc.weapon_gem;
    skill_id = desc.skill_id;
    seed_equipment();
    procedure = desc.procedure;
    if (!feeder) feeder = std::make_unique<Feed>();
    if (!held) {
        stage = desc.stage;
        ground = desc.ground;
        light = stage != nullptr ? light_of(*stage) : SceneLight{};
        load_stage();
    }
    // Gốc của đồng hồ khung đặt trước mọi lần dựng giao diện: open_login và prepare_board đã gọi
    // prepare_hud, trước đây chúng đọc một gốc chưa đặt và đưa cho giao diện một mốc rất lớn rồi
    // mốc tụt về 0 ở khung thật đầu tiên.
    started = core::Clock::now();
    frame_time = started;
    // Nướng địa hình bắt đầu trước khi dựng giao diện và người chơi, để ba việc chạy cùng lúc.
    // Lượt đọc của cảnh đầu đã giao ở kick_loading: ở đây chỉ còn pipeline và hiệu ứng của cảnh.
    if (held && arrival.has_value()) warm_scene();
    if (held && !arrival.has_value()) begin_load(held);
    if (!held && stage != nullptr) warm_scene();
    // Màn đăng nhập chưa có nhân vật nào: không nạp mô hình. Sổ và danh sách tạo đọc trước khung đầu.
    if (desc.restored.has) apply_kept(desc.restored);
    if (procedure == Procedure::kLogin) open_login();
    if (procedure == Procedure::kPlay) load_player();
    prepare_board();
    const gpu::AdapterInfo& adapter = device->adapter();
    const gpu::PresentMode shown = screen->swapchain()->present_mode();
    const std::string_view api = gpu::name(adapter.backend);
    const std::string_view mode = gpu::name(shown);
    reported_description = std::format("{} trên {}, trình {}, có forward", api, adapter.name, mode);
    posted_size.store(pack(desc.size), std::memory_order_relaxed);
}

// Rời thủ tục đăng nhập: từ khung này camera, người chơi và giao diện là của màn chơi. Người chơi
// lấy mặt, tóc và giới của nhân vật vừa chọn; chưa chọn thì là nhân vật mới mặc định.
void Display::State::start_play() {
    if (procedure == Procedure::kPlay) return;
    procedure = Procedure::kPlay;
    if (sky_view) sky_view->pin_day(kOfflineDayTime);
    typed.clear();
    apply_role();
    load_player();
}

void Display::State::open_login() {
    if (!hud || roles_loaded) return;
    roles_loaded = true;
    const std::filesystem::path root = save_root.empty() ? data_root : save_root;
    const std::filesystem::path file = root / "Save" / "roles.tsv";
    const std::string text = read_save_text(file);
    if (!hud->recall_roles(text)) std::println(stderr, "Nhân vật: sổ hỏng phiên bản, bắt đầu sổ trống");
    static_cast<void>(hud->recall_last_server(read_save_text(root / "Save" / "last_server.tsv")));
}

void Display::State::store_roles() const {
    if (!hud) return;
    const std::filesystem::path root = save_root.empty() ? data_root : save_root;
    if (const std::optional<std::string> text = hud->roles_text()) {
        if (write_save_text(root / "Save" / "roles.tsv", *text)) hud->mark_roles_saved();
    }
    if (const std::optional<std::string> text = hud->last_server_text()) {
        if (write_save_text(root / "Save" / "last_server.tsv", *text)) hud->mark_last_server_saved();
    }
}

void Display::State::seed_equipment() {
    if (weapon_item) hero.equipment.wear(hero::EquipPoint::kWeapon, *weapon_item);
    if (weapon_gem) hero.equipment.socket(hero::EquipPoint::kWeapon, *weapon_gem);
    const bool is_known = skill_id && std::ranges::find(hero.skills, *skill_id) != hero.skills.end();
    if (skill_id && !is_known) hero.skills.push_back(*skill_id);
}

void Display::State::apply_role() {
    const ui::panel::Role* role = hud ? hud->entering_role() : nullptr;
    if (role == nullptr) return;
    hero = hero::newcomer();
    seed_equipment();
    show_fight();
    hero.name = role->name;
    hero.level = role->level;
    hero.portrait = hero::PortraitId{role->portrait};
    hero.sect = static_cast<hero::Sect>(role->sect);
    // Trần kinh nghiệm theo cấp thật của nhân vật (Config/PlayerExpLevel.txt), không giữ số của cấp 1.
    if (const std::optional<std::int64_t> need = exp_need_at(hero.level)) hero.experience.top = *need;
    role_look = {};
    role_look.face = role->face;
    role_look.hair = role->hair;
    role_look.body = role->body;
    role_look.arm = role->arm;
    role_look.foot = role->foot;
    const bool is_female = role->sex == 0;
    role_race = is_female ? look::Race::kFemale : look::Race::kMale;
    has_role_look = true;
    KeptRole copy;
    copy.has = true;
    copy.sex = role->sex;
    copy.face = role->face;
    copy.hair = role->hair;
    copy.body = role->body;
    copy.arm = role->arm;
    copy.foot = role->foot;
    const std::scoped_lock<std::mutex> locked(kept_guard);
    played_role = std::move(copy);
}

std::optional<std::int64_t> Display::State::exp_need_at(std::int32_t level) {
    if (!exp_table && !has_exp_table_failed) {
        const std::filesystem::path levels = data_root / "Config" / "PlayerExpLevel.txt";
        auto table = hero::read_exp_table(read_save_text(levels));
        if (table) {
            exp_table = std::move(*table);
        } else {
            has_exp_table_failed = true;
            std::println(stderr, "Nhân vật: {}: {}", io::utf8_of(levels), table.error());
        }
    }
    if (!exp_table) return std::nullopt;
    const std::optional<std::int64_t> need = hero::exp_need(*exp_table, level);
    if (!need) std::println(stderr, "Nhân vật: cấp {} không có trong bảng kinh nghiệm", level);
    return need;
}

// Số máy chủ gửi là u64; ô tiền của client gốc chỉ nhận int (FalagardMoney::setMoneyNumber) nên kẹp về trần int32.
void Display::State::apply_stats(const ui::panel::talk::Stats& stats) {
    constexpr auto kMoneyCap = static_cast<std::uint64_t>(std::numeric_limits<std::int32_t>::max());
    hero.level = stats.level;
    hero.experience.now = static_cast<std::int64_t>(std::min<std::uint64_t>(stats.exp, std::numeric_limits<std::int64_t>::max()));
    if (const std::optional<std::int64_t> need = exp_need_at(hero.level)) hero.experience.top = *need;
    hero.purse.money = static_cast<std::int32_t>(std::min(stats.money, kMoneyCap));
    hero.purse.money_voucher = static_cast<std::int32_t>(std::min(stats.bound_money, kMoneyCap));
}

void Display::State::apply_kept(const KeptRole& restored) {
    if (!restored.has) return;
    role_look = {};
    role_look.face = restored.face;
    role_look.hair = restored.hair;
    role_look.body = restored.body;
    role_look.arm = restored.arm;
    role_look.foot = restored.foot;
    const bool is_female = restored.sex == 0;
    role_race = is_female ? look::Race::kFemale : look::Race::kMale;
    has_role_look = true;
}

// Giao diện của khung: đưa đầu vào (kể cả ký tự vừa gõ) rồi lấy việc nó nhờ vòng cửa sổ làm.
void Display::State::prepare_hud() {
    if (!hud) return;
    // Sự kiện thử chờ khung màn chơi đầu tiên; HUD nhận chúng đúng một lần (posted_events rỗng từ khung sau).
    if (procedure == Procedure::kPlay) hud_events.swap(posted_events);
    start_auto_login();
    pump_online();
    pump_talk();
    fill_bar_cooldown();
    hud->prepare(hud_view());
    drain_says();
    hud_events.clear();
    typed.clear();
    hud_wheel = 0;
    const std::optional<ui::Action> action = hud->take_action();
    if (action) post_request(*action);
    if (const std::optional<std::uint32_t> slot = hud->take_skill_slot()) press_slot(*slot);
    if (const std::optional<ui::panel::talk::Place> place = hud->take_revive()) {
        send_say(ui::panel::talk::Revive{.place = *place});
    }
    std::vector<ui::panel::OnlineAsk> asks = hud->take_online_asks();
    if (!asks.empty()) {
        const std::scoped_lock<std::mutex> locked(online_guard);
        std::ranges::move(asks, std::back_inserter(online_asks));
    }
    if (const std::optional<ui::RunTo> run = hud->take_run_to()) run_to_scene_point(*run);
    if (body) body->set_spin(hud->equip_spin());
    store_roles();
}

// --ui-event: phân tích từng sự kiện giao diện; sự kiện sai dạng thì ghi một dòng và bỏ.
void Display::State::seed_ui_events(std::span<const std::string> texts) {
    for (const std::string& text : texts) {
        std::optional<ui::panel::PostedEvent> event = ui::panel::PostedEvent::parse(text);
        if (!event) {
            std::println(stderr, "--ui-event: bỏ sự kiện sai dạng: {}", text);
            continue;
        }
        posted_events.push_back(std::move(*event));
    }
}

// Trả lời của phần nối máy chủ vào chuỗi đăng nhập trước khung này. Chỗ vào game ghi nhớ để đi kèm nút vào game mà
// chuỗi đăng nhập phát ngay sau đó (post_request).
void Display::State::pump_online() {
    std::vector<ui::panel::OnlineReply> replies;
    {
        const std::scoped_lock<std::mutex> locked(online_guard);
        replies = std::exchange(online_replies, {});
    }
    for (const ui::panel::OnlineReply& reply : replies) {
        if (reply.kind == ui::panel::OnlineReply::Kind::kEntered) {
            online_entry = EntryPoint{.scene = reply.scene, .x = reply.x_cm / kCmPerUnit, .z = reply.z_cm / kCmPerUnit};
            is_online_play = true;
        }
        if (reply.kind == ui::panel::OnlineReply::Kind::kLost) {
            is_online_play = false;
            chase_leg.reset();
            combat.leave();
        }
        hud->deliver_online(reply);
        drive_auto_login(reply);
    }
}

// Đăng nhập tự động (auto_login.hpp): chỉ khi có tài khoản thử và có máy chủ thật để nối.
void Display::State::arm_auto_login(const DisplayDesc& desc) {
    if (!desc.auto_account || desc.online_servers.empty()) return;
    auto_login = AutoLogin{.account = *desc.auto_account};
    auto_server = desc.online_servers.front();
    shot_waits_online = true;
    std::println("Đăng nhập tự động: tài khoản {} vào máy chủ {}", *desc.auto_account, auto_server.server);
}

// Gửi SignIn ở khung đầu của màn đăng nhập, đúng một lần.
void Display::State::start_auto_login() {
    const bool is_waiting = auto_login && auto_login->step == AutoLogin::Step::kSignIn;
    if (!is_waiting || procedure != Procedure::kLogin) return;
    queue_online(auto_sign_in(*auto_login, auto_server));
}

void Display::State::drive_auto_login(const ui::panel::OnlineReply& reply) {
    if (!auto_login) return;
    std::optional<ui::panel::OnlineAsk> next = auto_next(*auto_login, reply);
    if (next) queue_online(std::move(*next));
    const AutoLogin::Step step = auto_login->step;
    const auto kind = static_cast<int>(reply.kind);
    const auto fault = static_cast<int>(reply.fault);
    if (step == AutoLogin::Step::kStopped) std::println(stderr, "Đăng nhập tự động: dừng, trả lời {} lỗi {}", kind, fault);
    // Máy chủ đã nhận EnterGame: bấm "vào game" thay người chơi; online_entry vừa được pump_online ghi.
    constexpr std::uint64_t kShotDelayFrames = 300;
    if (step == AutoLogin::Step::kPlay) online_shot_from = frame_serial + kShotDelayFrames;
    if (step == AutoLogin::Step::kPlay) post_request(ui::Action::kEnterGame);
    if (step == AutoLogin::Step::kPlay || step == AutoLogin::Step::kStopped) auto_login.reset();
}

void Display::State::queue_online(ui::panel::OnlineAsk ask) {
    const std::scoped_lock<std::mutex> locked(online_guard);
    online_asks.push_back(std::move(ask));
}

void Display::State::post_request(ui::Action action) {
    const auto found = std::ranges::find(kActionRequests, action, &ActionRequest::action);
    if (found == kActionRequests.end()) return;
    Request request = found->request;
    if (request.kind == RequestKind::kEnterGame) request.entry = std::exchange(online_entry, std::nullopt);
    const std::scoped_lock<std::mutex> locked(request_guard);
    requests.push_back(request);
}

// Đầu vào của HUD ở khung này: cỡ khung, chuột theo điểm ảnh, nhân vật, đồng hồ, và cảnh cùng chỗ
// đứng, hướng mặt cho minimap.
FrameRect Display::State::frame_rect() const noexcept {
    const FrameRect whole{.x = 0, .y = 0, .width = screen->width(), .height = screen->height()};
    const bool is_login = procedure == Procedure::kLogin;
    if (!is_login || !frames_login) return whole;
    return placed_frame(whole.width, whole.height, ui_density);
}

// Chuột của sự kiện tính theo cả màn; khi bảng đăng nhập nằm trong khung tham chiếu thì phải tính lại theo khung,
// nếu không nút nằm lệch đúng bằng phần màn ngoài khung.
control::ScreenPoint Display::State::framed_point(const control::InputEvent& event) const noexcept {
    const FrameRect frame = frame_rect();
    const FrameSpan across{.origin = frame.x, .length = frame.width};
    const FrameSpan down{.origin = frame.y, .length = frame.height};
    return control::ScreenPoint{.x = unit_in_frame(event.x, screen->width(), across),
        .y = unit_in_frame(event.y, screen->height(), down)};
}

ui::HudView Display::State::hud_view() const {
    const FrameRect frame = frame_rect();
    const auto width = static_cast<float>(frame.width);
    const auto height = static_cast<float>(frame.height);
    ui::HudView view;
    view.phase = procedure == Procedure::kLogin ? ui::Phase::kLogin : ui::Phase::kPlay;
    view.width = width;
    view.height = height;
    view.density = ui_density;
    view.hero = &hero;
    if (view_count > 0) view.views = std::span(head_views).first(view_count);
    view.clock = std::chrono::duration_cast<std::chrono::milliseconds>(frame_time - started);
    view.pointer.emplace();
    view.pointer->x = pointer.x * width;
    view.pointer->y = pointer.y * height;
    view.pointer->is_down = is_button_down[static_cast<std::size_t>(control::MouseButton::kLeft)];
    view.pointer->is_right_down = is_button_down[static_cast<std::size_t>(control::MouseButton::kRight)];
    view.typed = typed;
    view.wheel = hud_wheel;
    view.loading = scene_load();
    view.events = hud_events;
    view.talk_title = talk_title;
    view.bar_left_ms = bar_left_ms;
    view.is_dead = combat.is_dead();
    if (const std::optional<ui::panel::talk::Slain> slain = combat.loss()) {
        view.loss = ui::panel::DeathLoss{.exp = slain->exp_lost, .money = slain->money_lost};
    }
    hud_target_name.clear();
    const std::optional<std::uint32_t> chosen = combat.target();
    const cast::Actor* actor = chosen ? people.find(*chosen) : nullptr;
    if (actor != nullptr && actor->pose != cast::Pose::kDead) {
        if (!actor->name.empty()) hud_target_name = actor->name;
        else if (creature_tables) {
            const look::CreatureTemplate* row = creature_tables->find_template(actor->template_id);
            if (row != nullptr) hud_target_name = row->name;
        }
        ui::panel::Target mark;
        mark.name = hud_target_name;
        mark.level = actor->level;
        mark.player_level = hero.level;
        mark.hp = std::min(static_cast<float>(actor->hp_percent), 100.0F) / 100.0F;
        mark.is_hostile = actor->kind == cast::Kind::kMonster;
        view.target = mark;
    }
    if (!held || !terrain) return view;
    const core::GroundPoint feet = terrain->to_game(foot());
    view.scene.radar = held->radar;
    view.scene.width = static_cast<float>(held->x_size);
    view.scene.depth = static_cast<float>(held->z_size);
    view.scene.player_x = feet.x;
    view.scene.player_z = feet.z;
    view.scene.name = held->name;
    view.scene.facing = facing;
    view.scene.id = held->id;
    return view;
}

// Việc nạp cảnh mà bảng chuyển cảnh của giao diện báo cho người chơi: cảnh của màn chơi đang được
// nạp, kèm phần mesh đã đặt xong. Chỉ báo khi RỜI một cảnh của thế giới: bản gốc phát
// PLAYER_LEAVE_WORLD ở GCNotifyChangeScene (Game.exe 0x1405493da), còn lần vào đầu từ bảng chọn
// (LCRetCharLogin -> ChangeScene -> Enter) và thủ tục đăng nhập đổi cảnh nền không phát. Trước khi
// mặt đất sẵn thì phần trăm là 0.
std::optional<ui::SceneLoad> Display::State::scene_load() const {
    if (procedure != Procedure::kPlay || !has_entered_world) return std::nullopt;
    if (!arrival.has_value() || !arrival->scene) return std::nullopt;
    ui::SceneLoad load;
    load.name = arrival->scene->name;
    const std::size_t total = arrival->table.meshes.size();
    if (!arrival->ground_done || total == 0) return load;
    const std::size_t settled = std::min(arrival->settled, total);
    load.percent = static_cast<std::int32_t>((settled * 100U) / total);
    return load;
}

namespace {

constexpr float kRidePad = 8.0F;
constexpr float kRideGap = 8.0F;
constexpr std::uint32_t kRideFill = 0xE0202018U;
constexpr std::uint32_t kRideInk = 0xFFFFFFFFU;

[[nodiscard]] float ride_row_top(int height) noexcept {
    const float room = static_cast<float>(height) - 72.0F;
    if (room < 16.0F) return 16.0F;
    return room;
}

void push_fill(std::vector<render::UiVertex>& out, const RideBox& box, std::uint32_t colour) {
    out.push_back({.x = box.left, .y = box.top, .u = 0.0F, .v = 0.0F, .colour = colour});
    out.push_back({.x = box.right, .y = box.top, .u = 1.0F, .v = 0.0F, .colour = colour});
    out.push_back({.x = box.right, .y = box.bottom, .u = 1.0F, .v = 1.0F, .colour = colour});
    out.push_back({.x = box.left, .y = box.bottom, .u = 0.0F, .v = 0.0F, .colour = colour});
}

void push_batch(ui::PaceOverlay& board, std::size_t first, std::uint32_t texture) {
    if (board.vertices.size() < first) return;
    const std::size_t count = board.vertices.size() - first;
    if (count == 0 || count % 4 != 0) return;
    render::UiBatch batch;
    batch.texture = texture;
    batch.first_quad = static_cast<std::uint32_t>(first / 4);
    batch.quad_count = static_cast<std::uint32_t>(count / 4);
    board.batches.push_back(batch);
}

[[nodiscard]] RideBox button_box(const ui::BitmapFont& font, std::string_view label, float left,
    float top) {
    const float text_w = font.width_of(label);
    const auto size = static_cast<float>(font.pixel_size());
    RideBox box;
    box.left = left;
    box.top = top;
    box.right = left + text_w + (kRidePad * 2.0F);
    box.bottom = top + size + (kRidePad * 2.0F);
    return box;
}

void paint_label(ui::PaceOverlay& board, const ui::BitmapFont& font, std::string_view label,
    const RideBox& box, std::uint32_t texture) {
    const std::size_t panel = board.vertices.size();
    push_fill(board.vertices, box, kRideFill);
    push_batch(board, panel, render::kUiWhite);
    const std::size_t text = board.vertices.size();
    const float pen_x = box.left + kRidePad;
    const float pen_y = box.top + kRidePad;
    font.append_text(label, pen_x, pen_y, kRideInk, board.vertices);
    push_batch(board, text, texture);
}

} // namespace

bool Display::State::is_on_hud(control::ScreenPoint point) const {
    const FrameRect frame = frame_rect();
    const float x = point.x * static_cast<float>(frame.width);
    const float y = point.y * static_cast<float>(frame.height);
    if (hits_ride(x, y, ride_prev)) return true;
    if (hits_ride(x, y, ride_next)) return true;
    if (!hud) return false;
    return hud->contains(x, y);
}

void Display::State::paint_ride_switch() {
    ride_buttons_live = false;
    const bool hides = is_bare || procedure != Procedure::kPlay;
    if (hides || !pace_font) return;
    if (!ensure_ride_catalog()) return;
    const ui::BitmapFont& font = *pace_font;
    const FrameRect frame = frame_rect();
    const float top = ride_row_top(frame.height);
    const RideBox prev = button_box(font, "Thú trước", 16.0F, top);
    paint_label(pace_board, font, "Thú trước", prev, pace_texture);
    const float next_left = prev.right + kRideGap;
    const RideBox next = button_box(font, "Thú sau", next_left, top);
    paint_label(pace_board, font, "Thú sau", next, pace_texture);
    ride_prev = prev;
    ride_next = next;
    const std::string line = ride_caption();
    const std::size_t text = pace_board.vertices.size();
    const float caption_y = prev.bottom + 4.0F;
    font.append_text(line, prev.left, caption_y, kRideInk, pace_board.vertices);
    push_batch(pace_board, text, pace_texture);
    ride_buttons_live = true;
}

void Display::State::fill_pace_board() {
    pace_board.vertices.clear();
    pace_board.batches.clear();
    ride_buttons_live = false;
    if (!pace_font) return;
    ui::PacePlace place;
    place.font = &*pace_font;
    place.texture = pace_texture;
    // Góc phải, dưới bản đồ nhỏ: bên trái là khung chat, bên trên là khung nhân vật.
    place.origin_x = 16.0F;
    place.origin_y = 240.0F;
    place.screen_width = static_cast<float>(frame_rect().width);
    ui::write_pace(place, pace_shown, pace_board);
    paint_ride_switch();
}

void Display::State::prepare_board() {
    prepare_hud();
    fill_pace_board();
}

void Display::State::stamp_phases(const FrameMarks& marks) {
    pace_last.acquire_ms = static_cast<float>(shown_wait_ms + millis_between(marks.asked, marks.acquired));
    pace_last.draw_ms = static_cast<float>(millis_between(marks.acquired, marks.recorded));
    pace_last.submit_ms = static_cast<float>(millis_between(marks.recorded, core::Clock::now()));
    pace_last.draws = scene_draws;
    const std::size_t quads = hud ? hud->quad_count() : 0;
    pace_last.quads = static_cast<std::uint32_t>(quads);
    phase_ms.acquire += static_cast<double>(pace_last.acquire_ms);
    phase_ms.draw += static_cast<double>(pace_last.draw_ms);
    phase_ms.submit += static_cast<double>(pace_last.submit_ms);
    ++phase_ms.frames;
}

void Display::State::ensure_clock() {
    if (frame_clock) return;
    core::TickConfig config;
    config.hz = render_hz;
    config.max_steps = 1;
    core::Result<core::FixedStep> made = core::FixedStep::create(config);
    if (!made) return;
    frame_clock = *made;
}

// Điện thoại không có ngân sách cố định: màn 120 Hz không bảo đảm máy vẽ nổi 120 khung. Trần bắt đầu ở mức vững rồi
// tự nâng khi khung còn dư sức (core/governor.hpp). Chưa biết tần số quét thì không giới hạn, Fifo tự khoá nhịp.
void Display::State::govern_rate(double interval_ms) {
    const double refresh = refresh_hz.load(std::memory_order_relaxed);
    if (refresh <= 0.0) return;
    const bool is_changed = governed_refresh != refresh || governed_ceiling != render_hz;
    if (!governor || is_changed) {
        governed_refresh = refresh;
        governed_ceiling = render_hz;
        governor.emplace(core::GovernorConfig{.refresh_hz = refresh, .ceiling_hz = render_hz});
        governed_deadline = core::Clock::now();
        pace_swapchain();
        return;
    }
    // Khung nạp cảnh dài theo thiết kế (mesh vào dần), không nói gì về sức máy: không vào cửa sổ.
    // Đo 2026-10-17: cửa sổ đầu trùng lúc nạp (trễ 92%) và đẩy máy về 30 ngay khi vào cảnh.
    if (arrival.has_value()) return;
    // Việc thật của khung: nạp, dựng bảng, ghi lệnh và nộp. Nộp tính vào vì ở mức đầy nhịp quét
    // driver chặn ở đó khi GPU tụt lại. Không chờ GPU để đo: chờ là bắt CPU và GPU chạy nối nhau
    // (đo 2026-10-17 trên TB-X306F: CPU 15 ms cộng GPU 24 ms thành khung 40 ms, rớt nhịp đều đặn).
    const double cpu_ms = last_load_ms + last_prepare_ms + static_cast<double>(pace_last.draw_ms);
    const double busy_ms = cpu_ms + static_cast<double>(pace_last.submit_ms);
    if (!governor->note_frame({.interval_ms = interval_ms, .busy_ms = busy_ms})) return;
    governed_deadline = core::Clock::now();
    const double ceiling = governor->target_hz();
    std::println(stderr, "Điều tốc: trần {:.0f} Hz trên màn {:.0f} Hz", ceiling, refresh);
    pace_swapchain();
}

// Trần thấp hơn nhịp quét trên bề mặt hẹn được lúc trình: mỗi ảnh nằm đúng refresh / trần nhịp
// quét, tính theo mốc trình thật nên không trôi khỏi nhịp như đồng hồ CPU (gpu/pacer.hpp).
void Display::State::pace_swapchain() {
    if (!governor || governed_refresh <= 0.0) return;
    gpu::Swapchain& chain = *screen->swapchain();
    if (!chain.paces_present()) return;
    const double ratio = governed_refresh / governor->target_hz();
    const long rounded = std::lround(ratio);
    const auto refreshes = static_cast<std::uint32_t>(std::max(rounded, 1L));
    chain.set_present_interval(refreshes);
}

// Trần đang thấp hơn nhịp quét và swapchain đang giữ nhịp theo mốc trình thật. Có tiện ích mà
// driver không báo mốc (TB-X306F) thì sai: đồng hồ CPU giữ nhịp như khi không có tiện ích.
bool Display::State::is_display_paced() const noexcept {
    if (!governor || !policy.adapts_rate) return false;
    const bool is_below = governor->target_hz() < governed_refresh * 0.99;
    return is_below && screen->swapchain()->holds_cadence();
}

// Điện thoại: chi tiết hình học của cảnh theo sức máy. Khung chậm hơn 30 khung/giây thì Forward chuyển lưới sang mức thô
// hơn (trần tam giác hạ), máy dư sức thì trần nâng dần (render/detail_governor.hpp).
void Display::State::adapt_detail(double interval_ms) {
    if (!forward) return;
    if (!detail) detail.emplace(render::DetailConfig{.start_cap = forward->triangle_cap()});
    if (detail->note_frame(interval_ms)) forward->set_triangle_cap(detail->cap());
}

// Trần thấp hơn nhịp quét: hoặc swapchain giữ nhịp (acquire chặn tới khi màn nhả ảnh), hoặc ngủ
// tới mốc kế tiếp theo đồng hồ CPU (lưới đều, không trôi). Bằng nhịp quét thì để Fifo khoá nhịp.
void Display::State::hold_governed_rate() {
    if (!governor) return;
    const double target = governor->target_hz();
    if (target >= governed_refresh * 0.99) return;
    if (is_display_paced()) return;
    const core::Clock::time_point now = core::Clock::now();
    const auto period = std::chrono::duration_cast<core::Clock::duration>(std::chrono::duration<double>(1.0 / target));
    governed_deadline += period;
    // Khung trễ quá một chu kỳ: bắt đầu lưới mới từ bây giờ, không ngủ bù để đuổi.
    if (governed_deadline + period < now) governed_deadline = now;
    if (governed_deadline > now) core::sleep_until(governed_deadline);
}

void Display::State::hold_pace(double spent_ms) {
    if (policy.adapts_rate) {
        hold_governed_rate();
        return;
    }
    // Fifo đã chờ nhịp quét trong lúc xin ảnh và trình: ngủ thêm theo đồng hồ riêng chỉ làm khung trượt
    // khỏi nhịp quét. Đồng hồ trần chỉ còn cho bề mặt không có Fifo (driver từ chối, trình ngay).
    if (screen->swapchain()->present_mode() == gpu::PresentMode::kFifo) return;
    // Việc của khung đã nuốt hết một nhịp 120 Hz thì trình ngay. Ngủ thêm biến khung nạp thành
    // hai nhịp (đo: đưa đất 15 ms rồi ngủ 8 ms thành khung 26 ms).
    if (spent_ms >= 1000.0 / static_cast<double>(render_hz)) return;
    ensure_clock();
    if (!frame_clock) return;
    static_cast<void>(frame_clock->advance(core::Clock::now()));
    const std::optional<core::Clock::time_point> next = frame_clock->next_tick();
    if (!next) return;
    core::sleep_until(*next);
}

// Fifo khoá khung vào nhịp quét: trên màn 60 Hz không khung nào đạt ngân sách 8,3 ms của trần 120 Hz,
// nên bảng từng báo TRƯỢT ở đúng 60,0 FPS (docs/BAY-DA-BIET.md). Bề mặt Fifo mà biết tần số quét thì
// ngân sách là một nhịp quét; không Fifo hoặc chưa biết thì là trần render_hz như trước.
float Display::State::frame_budget_ms() const noexcept {
    const double rate = refresh_hz.load(std::memory_order_relaxed);
    const bool is_fifo = screen != nullptr && screen->swapchain()->present_mode() == gpu::PresentMode::kFifo;
    // Trần nhịp tự chọn (GraphicsPolicy::adapts_rate): khung đạt ngân sách khi giữ được trần đó, không phải mọi nhịp quét.
    if (policy.adapts_rate && governor) return static_cast<float>(1000.0 / governor->target_hz());
    if (is_fifo && rate > 0.0) return static_cast<float>(1000.0 / rate);
    return render_hz > 0 ? 1000.0F / static_cast<float>(render_hz) : 0.0F;
}

// Điện thoại trình Fifo: hàng chờ trình nuốt dao động của vòng lặp (đo 2026-10-17 trên TB-X306F:
// 64 ms từ lúc nộp tới lúc lên màn), nên khoảng vòng lặp báo 16% khung trễ trong khi màn không lặp
// ảnh nào, và điều tốc đẩy máy về 30 Hz oan. Lưới nhịp trình (core/cadence.hpp) khớp SurfaceFlinger
// từng cửa sổ 10 giây. PC giữ khoảng vòng lặp: chưa đối chiếu acquire ở đó có chờ ảnh nhả không.
double Display::State::shown_interval(double loop_ms) {
    const double refresh = refresh_hz.load(std::memory_order_relaxed);
    const bool is_fifo = screen->swapchain()->present_mode() == gpu::PresentMode::kFifo;
    const bool is_modeled = policy.adapts_rate && is_fifo && refresh > 0.0;
    shown_step_ms.reset();
    if (!is_modeled) return loop_ms;
    const double nominal_ms = 1000.0 / refresh;
    const bool is_other_rate = cadence && std::abs(cadence->nominal_ms() - nominal_ms) > 1e-6;
    if (!cadence || is_other_rate) cadence.emplace(refresh);
    shown_step_ms = cadence->note(acquire_note).interval_ms;
    return *shown_step_ms;
}

void Display::State::rest(core::Clock::time_point& previous) {
    nap(previous);
    if (cadence) cadence->reset();
    shown_step_ms.reset();
    paced.reset();
}

// Fifo mà bề mặt không báo lúc trình (TB-X306F): luồng vẽ thức lệch ±6 ms quanh nhịp quét trong
// khi màn vẫn đổi ảnh đều 16,7 ms (đo 2026-10-17: khoảng vòng lặp p95 22,7 ms, SurfaceFlinger p95
// 16,77 ms). Hoạt hoạ theo lúc thức làm camera, nhân vật, mây nhích lúc ngắn lúc dài dù không lặp
// ảnh nào. Bề mặt báo lúc trình thì await_shown đã thức theo nhịp màn: không có bước lưới, đồng hồ
// neo vào lúc thức.
core::Clock::time_point Display::State::pace_frame(core::Clock::time_point woke) {
    const bool is_reported = screen->swapchain()->reports_shown();
    const std::optional<double> step = is_reported ? std::nullopt : shown_step_ms;
    const double woke_ms = std::chrono::duration<double, std::milli>(woke - started).count();
    const double paced_ms = paced.next(woke_ms, step);
    const std::chrono::duration<double, std::milli> since{paced_ms};
    return started + std::chrono::duration_cast<core::Clock::duration>(since);
}

void Display::State::record_interval(IntervalNote note) {
    frame_ms.push_back(note.interval);
    note_pace(note.interval);
    SpikeParts spike;
    spike.interval = note.interval;
    spike.loop_ms = note.loop_ms;
    spike.load_ms = last_load_ms;
    spike.render_ms = note.render_ms;
    spike.pace_ms = note.pace_ms;
    spike.acquire_ms = pace_last.acquire_ms;
    spike.draw_ms = pace_last.draw_ms;
    spike.submit_ms = pace_last.submit_ms;
    spike.prepare_ms = last_prepare_ms;
    spike.budget_ms = static_cast<double>(frame_budget_ms());
    spike.frame = frame_serial;
    spike.gpu_behind = shown_gpu_behind;
    report_spike(spike);
}

// Trung bình bốn chặng trên các khung đã có trong cửa sổ; rỗng thì toàn số không.
Display::State::StageSample Display::State::stage_mean() const noexcept {
    const std::span<const StageSample> window(stage_ring.data(), pace_filled);
    StageSample sum;
    for (const StageSample& item : window) {
        sum.acquire_ms += item.acquire_ms;
        sum.draw_ms += item.draw_ms;
        sum.submit_ms += item.submit_ms;
        sum.prepare_ms += item.prepare_ms;
    }
    if (window.empty()) return sum;
    const auto count = static_cast<float>(window.size());
    sum.acquire_ms /= count;
    sum.draw_ms /= count;
    sum.submit_ms /= count;
    sum.prepare_ms /= count;
    return sum;
}

void Display::State::note_pace(double interval) {
    constexpr std::size_t kPaceWindow = 90;
    pace_ring.at(pace_cursor) = static_cast<float>(interval);
    StageSample now_stages;
    now_stages.acquire_ms = pace_last.acquire_ms;
    now_stages.draw_ms = pace_last.draw_ms;
    now_stages.submit_ms = pace_last.submit_ms;
    now_stages.prepare_ms = static_cast<float>(last_prepare_ms);
    stage_ring.at(pace_cursor) = now_stages;
    pace_cursor = (pace_cursor + 1) % kPaceWindow;
    if (pace_filled < kPaceWindow) ++pace_filled;
    const StageSample mean = stage_mean();
    ui::PaceNumbers phases;
    phases.acquire_ms = mean.acquire_ms;
    phases.draw_ms = mean.draw_ms;
    phases.submit_ms = mean.submit_ms;
    phases.draws = pace_last.draws;
    phases.ui_quads = pace_last.quads;
    phases.prepare_ms = mean.prepare_ms;
    phases.budget_ms = frame_budget_ms();
    phases.output_width = screen->width();
    phases.output_height = screen->height();
    phases.samples = screen->samples();
    const std::span<const float> samples(pace_ring.data(), pace_filled);
    pace_shown = ui::pace_of(samples, phases);
    pace_shown.last_ms = static_cast<float>(interval);
}

core::Status Display::State::paint_hud(gpu::CommandList& list, std::uint32_t slot) const {
    if (!hud || is_bare) return core::ok();
    ui::Hud::HudExtra extra;
    extra.vertices = pace_board.vertices;
    extra.batches = pace_board.batches;
    return hud->draw(list, slot, extra);
}
} // namespace game::client
