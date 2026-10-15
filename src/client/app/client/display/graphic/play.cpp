// Camera, đi lại và người mẫu. Đăng nhập dùng camera cố định hoặc camera chọn nhân vật.
// Màn chơi dùng camera bám đất của client 2026.
#include "client/display/graphic/state.hpp"

#include "client/display/display.hpp"

#include <utility>
namespace game::client {

void Display::State::ensure_gates() {
    if (gates_ready || data_root.empty()) return;
    gates_ready = true;
    const std::filesystem::path file = data_root / "Config" / "ScenePosDefineEx.txt";
    const io::TextResult text = io::read_text(file);
    if (!text) {
        const std::string_view reason = io::describe(text.error());
        const std::string name = io::utf8_of(file);
        std::println(stderr, "Bảng cổng: {} ({})", reason, name);
        return;
    }
    map::GateResult read = map::read_gates(*text);
    if (!read) {
        const std::string_view reason = map::describe(read.error());
        std::println(stderr, "Bảng cổng: {}", reason);
        return;
    }
    gates = std::move(*read);
}

void Display::State::place_at(int scene_id) {
    ensure_gates();
    std::optional<EntryPoint> entry;
    {
        const std::scoped_lock<std::mutex> locked(spawn_guard);
        entry = std::exchange(entry_spot, std::nullopt);
    }
    map::SceneStep step;
    step.previous = walk.scene_id;
    step.scene = scene_id;
    map::GateStand stand = map::arrival_at(gates, step);
    // Chỗ đứng máy chủ đặt thắng điểm đến mặc định, nhưng chỉ cho đúng cảnh nó nói tới.
    if (entry && entry->scene == scene_id) stand = map::GateStand{.x = entry->x, .z = entry->z, .has = true};
    place_walk(walk, *ground, scene_id, stand);
}

// Khung không có người chơi (thủ tục đăng nhập, cảnh không có địa hình): camera là tư thế cố định
// của màn đăng nhập, hoặc xoay quanh hộp bao thế giới; nút và vị trí chuột vẫn tới giao diện. Phím
// và thao tác của màn chơi không có camera cảnh nào nhận nên bị bỏ; trước đây cả hàng chờ nằm lại,
// giao diện không thấy cú bấm nào.
render::Camera Display::State::idle_view(FrameAsk ask) {
    const Taken taken = take_steering();
    view_size = ask.size;
    take_events(taken.events);
    publish_cursor();
    if (procedure == Procedure::kLogin) step_role_stage();
    close_mouse_frame();
    if (procedure == Procedure::kLogin && shows_role_scene()) {
        clip_near = control::kRoleNear;
        clip_far = control::kRoleFar;
        return role_scene_camera(ask.size);
    }
    if (procedure == Procedure::kLogin) {
        clip_near = control::kLoginView.near_plane;
        clip_far = control::kLoginView.far_plane;
        return login_camera(ask.size);
    }
    clip_near = 0.25F;
    clip_far = 150.0F;
    return orbit_view(ask.elapsed, world, ask.size);
}

// Thủ tục đăng nhập có cảnh nền và mặt đất nhưng không có người chơi: không dựng mặt đất cho camera
// bám theo, nên compose_frame cũng không đặt nhân vật vào cảnh.
render::Camera Display::State::frame_camera(FrameAsk ask) {
    if (procedure == Procedure::kLogin) return idle_view(ask);
    if (ground == nullptr || ground->heights.samples.empty()) return idle_view(ask);
    const int scene_id = held ? held->id : -1;
    if (walk.scene_id != scene_id) place_at(scene_id);
    if (terrain_scene != scene_id) rebuild_terrain(scene_id);
    if (!terrain) return idle_view(ask);
    const core::Clock::time_point now = frame_time;
    const Taken taken = take_steering();
    view_size = ask.size;
    take_events(taken.events);
    const float delta_seconds = step_clock(ask.elapsed);
    enter_camera(scene_id);
    Steering keys = is_auto_walk ? auto_walk(taken.keys, delta_seconds) : taken.keys;
    if (auto_strike_from != 0) note_auto_strike(keys);
    steer_camera(keys);
    pilot_frame(now, delta_seconds);
    hold_stick_frame(now);
    publish_cursor();
    simulate_motion(keys, now);
    note_walk_step();
    // NOLINTNEXTLINE(bugprone-unchecked-optional-access): terrain đã kiểm ở đầu hàm
    follow.set_look_at(*terrain, foot());
    const control::CameraPose& pose = follow.pose();
    clip_near = pose.near_plane;
    clip_far = pose.far_plane;
    lens = lens_of(pose, aspect_of(ask.size));
    has_lens = true;
    return camera_of(pose, ask.size);
}

// Sự kiện tới theo thứ tự; cái nào chưa dùng được ở khung này thì nó và mọi cái sau nó quay lại
// đầu hàng chờ.
void Display::State::take_events(std::span<const control::InputEvent> events) {
    std::size_t used = 0;
    while (used < events.size() && absorb(events[used])) {
        ++used;
    }
    if (used == events.size()) return;
    const std::span<const control::InputEvent> rest = events.subspan(used);
    const std::scoped_lock<std::mutex> locked(steer_guard);
    queued.insert(queued.begin(), rest.begin(), rest.end());
}

// Lần đầu có mặt đất của một cảnh, như CGamePro_Enter: hướng 3,1415, zoom đã lưu, pitch theo zoom.
void Display::State::enter_camera(int scene_id) {
    if (camera_scene == scene_id || !terrain) return;
    camera_scene = scene_id;
    follow = control::FollowCamera{rules_of(held.get())};
    follow.enter(*terrain, foot(), saved_zoom);
    pilot.enter(saved_zoom);
}

// Phím của cửa sổ: lên xuống là lệnh phím zoom của bản gốc, V là ResetCamera; trái phải là phím
// xoay của bản 2008, bản 2026 không còn.
void Display::State::steer_camera(const Steering& keys) {
    if (!terrain) return;
    if (keys.turn_keys != 0) control::key_turn(follow, *terrain, keys.turn_keys);
    const control::ZoomWay way = keys.zoom_keys > 0 ? control::ZoomWay::kCloser : control::ZoomWay::kFarther;
    for (int press = 0; press < std::abs(keys.zoom_keys); ++press) {
        control::key_zoom(follow, *terrain, way);
    }
    if (keys.is_home) pilot.reset_camera(follow, *terrain);
}

control::MouseSample Display::State::mouse_sample() const noexcept {
    const auto width = static_cast<float>(view_size.width);
    const auto height = static_cast<float>(view_size.height);
    control::MouseSample mouse;
    mouse.x = static_cast<int>(pointer.x * width);
    mouse.y = static_cast<int>(pointer.y * height);
    mouse.dx = drag_x;
    mouse.dy = drag_y;
    mouse.is_left_down = is_button_down[static_cast<std::size_t>(control::MouseButton::kLeft)];
    mouse.is_middle_down = is_button_down[static_cast<std::size_t>(control::MouseButton::kMiddle)];
    mouse.is_right_down = is_button_down[static_cast<std::size_t>(control::MouseButton::kRight)];
    mouse.is_wheel_up = is_wheel_up;
    mouse.is_wheel_down = is_wheel_down;
    return mouse;
}

// Một khung của CGamePro_Main: chuột thành lệnh đi và chỉnh camera, rồi phần camera tự động.
void Display::State::pilot_frame(core::Clock::time_point now, float seconds) {
    if (!terrain) return;
    control::PilotFrame frame;
    frame.mouse = mouse_sample();
    frame.now = now;
    frame.seconds = seconds;
    frame.is_over_ui = is_hud_press || is_on_hud(pointer);
    frame.is_player_moving = is_player_running;
    frame.under_cursor = pick_at(pointer);
    const control::PilotStep step = pilot.frame(follow, *terrain, frame);
    order_move(step.move_to, pilot.auto_run() ? nav::MoveMode::kStraight : nav::MoveMode::kFind);
    close_mouse_frame();
}

// Hết một khung chuột: độ dời, cờ lăn và dấu "nút đã đổi" chỉ sống một khung; nút trái đã nhả
// thì lần nhấn không còn thuộc về giao diện.
void Display::State::close_mouse_frame() noexcept {
    drag_x = 0;
    drag_y = 0;
    is_wheel_up = false;
    is_wheel_down = false;
    has_button_changed = {};
    if (!is_button_down[static_cast<std::size_t>(control::MouseButton::kLeft)]) is_hud_press = false;
}

// Mặt đất để camera bám theo và để chọn điểm bằng tia: cùng gốc, tỉ lệ, độ cao và đường chéo với
// lưới đã vẽ. Đổi cảnh thì bỏ lệnh đi và cần gạt của cảnh cũ, và giữ lại zoom như
// CGamePro_Main::Release ghi biến Camera_Zoom; Camera_SetZoom bỏ qua số ngoài [0, 1] nên kẹp ở đây.
void Display::State::rebuild_terrain(int scene_id) {
    if (terrain && camera_scene) saved_zoom = std::clamp(follow.zoom(*terrain), 0.0F, 1.0F);
    pilot.leave();
    terrain_scene = scene_id;
    terrain.reset();
    order.reset();
    tilt.reset();
    static_cast<void>(stick.release());
    control::GroundShape shape;
    const map::TerrainFile& file = ground->file;
    shape.position = ogre::Vec3{.x = file.origin.x, .y = file.origin.y, .z = file.origin.z};
    shape.scale = ogre::Vec3{.x = file.scale.x, .y = file.scale.y, .z = file.scale.z};
    shape.x_size = file.x_size;
    shape.z_size = file.z_size;
    shape.heights = ground->heights.samples;
    const auto is_flipped = [](const map::Cell& cell) { return (cell.flags & map::kFlipDiagonal) != 0; };
    shape.flipped.reserve(ground->grid.cells.size());
    std::ranges::transform(ground->grid.cells, std::back_inserter(shape.flipped), is_flipped);
    terrain = control::Ground::create(std::move(shape));
}

// false khi sự kiện phải chờ khung sau.
bool Display::State::absorb(const control::InputEvent& event) {
    using Kind = control::InputKind;
    switch (event.kind) {
    case Kind::kPress:
    case Kind::kRelease: return flip_button(event);
    case Kind::kMove: move_pointer(event); break;
    case Kind::kWheel: turn_wheel(event.wheel); break;
    case Kind::kCancel: cancel_left(); break;
    case Kind::kStick: tilt = control::Tilt{.x = event.dx, .y = event.dy}; break;
    case Kind::kStickEnd: release_stick(); break;
    case Kind::kText: typed.push_back(event.text); break;
    }
    return true;
}

// Nhấn hay nhả một nút. Bản gốc đọc nút mỗi nhịp một lần (GetAsyncKeyState), nên một nút chỉ đổi
// trạng thái một lần mỗi khung: lần đổi thứ hai, như cú bấm ngắn hơn một khung, chờ khung sau để
// không mất. Nhấn trái bắt đầu trên HUD thì thuộc về giao diện tới khi nhả.
bool Display::State::flip_button(const control::InputEvent& event) {
    const auto slot = static_cast<std::size_t>(event.button);
    const bool is_down = event.kind == control::InputKind::kPress;
    if (is_button_down.at(slot) == is_down) return true;
    if (has_button_changed.at(slot)) return false;
    pointer = control::ScreenPoint{.x = event.x, .y = event.y};
    is_button_down.at(slot) = is_down;
    has_button_changed.at(slot) = true;
    const bool is_left_press = is_down && event.button == control::MouseButton::kLeft;
    if (is_left_press) is_hud_press = is_on_hud(pointer);
    return true;
}

// Thao tác trái bị huỷ (ngón thứ hai chạm xuống, mất focus): không thành lệnh đi và không còn giữ
// nút. Còn để nút trái là đang giữ thì giao diện bỏ qua lần bấm kế tiếp.
void Display::State::cancel_left() noexcept {
    pilot.cancel_left();
    is_button_down[static_cast<std::size_t>(control::MouseButton::kLeft)] = false;
    is_hud_press = false;
}

// Độ dời cộng dồn cho cả khung, như MouseTick lấy vị trí nhịp này trừ nhịp trước.
void Display::State::move_pointer(const control::InputEvent& event) {
    pointer = control::ScreenPoint{.x = event.x, .y = event.y};
    drag_x += static_cast<int>(event.dx);
    drag_y += static_cast<int>(event.dy);
}

// Nấc lăn nguyên thành cờ lăn lên hay xuống của nhịp, như WM_MOUSEWHEEL đặt cờ cho MouseTick: lăn
// mấy nấc trong một khung cũng chỉ là một sự kiện. Phần lẻ (bàn rê) để dành cho lần sau. Giao diện
// nhận mỗi sự kiện một nấc, dồn không quá kHudWheelCap nấc giữa hai khung.
void Display::State::turn_wheel(float notches) {
    wheel_carry += notches;
    const float whole = std::trunc(wheel_carry);
    wheel_carry -= whole;
    if (whole > 0.0F) is_wheel_up = true;
    if (whole < 0.0F) is_wheel_down = true;
    if (whole != 0.0F) hud_wheel = std::clamp(hud_wheel + (whole > 0.0F ? 1 : -1), -kHudWheelCap, kHudWheelCap);
}

void Display::State::release_stick() {
    tilt.reset();
    apply_stick_step(stick.release());
}

// Hover để trống: chưa có danh sách NPC. Cửa sổ đọc loại này rồi gắn ảnh Interface/cursor; nullopt
// là đang kéo camera, cửa sổ ẩn và giữ con trỏ. Chạy cả ở thủ tục đăng nhập (idle_view). Con trỏ thường
// đổi sang con trỏ đang nhấn mỗi khi nút chính đang giữ, trên giao diện cũng vậy: CCursorMng::GetCursor
// (Game.exe 0x14007b550) chỉ xét chỉ số con trỏ và GetAsyncKeyState, không xét có đang trên cửa sổ không.
void Display::State::publish_cursor() noexcept {
    control::CursorState state;
    state.auto_run = pilot.auto_run();
    state.primary_down = is_button_down[static_cast<std::size_t>(control::MouseButton::kLeft)];
    state.camera_held = pilot.holds_cursor();
    const std::optional<control::CursorKind> kind = control::choose_cursor(state);
    const auto hidden = static_cast<std::uint8_t>(control::kCursorKinds);
    const std::uint8_t bits = kind ? static_cast<std::uint8_t>(*kind) : hidden;
    cursor_bits.store(bits, std::memory_order_relaxed);
}

// Hướng của cần là hướng camera nhìn chiếu xuống mặt đất, từ mắt tới chân nhân vật, toạ độ game.
void Display::State::hold_stick_frame(core::Clock::time_point now) {
    if (!tilt || !terrain || !has_lens) return;
    const core::GroundPoint feet = terrain->to_game(foot());
    const core::GroundPoint eye = terrain->to_game(lens.eye);
    const core::GroundPoint ahead{.x = feet.x - eye.x, .z = feet.z - eye.z};
    const control::StickStep sample = stick.hold(feet, ahead, *tilt, now);
    apply_stick_step(sample);
}

void Display::State::apply_stick_step(const control::StickStep& step) {
    if (step.order == control::StickOrder::kMove) order_move(step.target, nav::MoveMode::kStraight);
    if (step.order == control::StickOrder::kStop) order.reset();
}

// Nhấp trái lên bản đồ lớn (SceneMap_GotoDirectly gọi AutoRunToTarget): đi tới điểm đó như nhấp chuột lên mặt
// đất, tìm đường vòng qua vật cản. Điểm của bản đồ lớn tính theo đơn vị cảnh, cũng là đơn vị game.
void Display::State::run_to_scene_point(ui::RunTo target) {
    order_move(core::GroundPoint{.x = target.x, .z = target.z}, nav::MoveMode::kFind);
}

// Lệnh đi tới một điểm, đơn vị game, theo luật của client 2026 (nav::Field::plan_move): nhấp chuột
// thì tìm đường vòng qua vật cản, giữ chuột hay cần gạt thì đi thẳng tới sát vật cản. Lệnh bị luật
// từ chối thì lệnh đang chạy giữ nguyên, như bản gốc. Cảnh không có lưới đi thì đi thẳng tới điểm.
void Display::State::order_move(std::optional<core::GroundPoint> target, nav::MoveMode mode) {
    if (!target || !terrain || ground == nullptr || !scale_ok(ground->file)) return;
    const nav::Segment walk_line{.start = game_of(ground->file, walk), .end = *target};
    const nav::MoveAsk ask{.walk = walk_line, .mode = mode};
    WalkOrder given;
    if (walk_field == nullptr) given.path.push_back(*target);
    if (walk_field != nullptr) given.path = walk_field->plan_move(ask, scratch);
    if (given.path.empty()) return;
    order = std::move(given);
}

// Mặt đất dưới con trỏ, theo thông số nhìn của khung trước.
std::optional<core::GroundPoint> Display::State::pick_at(control::ScreenPoint point) const {
    if (!terrain || !has_lens) return std::nullopt;
    if (view_size.width == 0 || view_size.height == 0) return std::nullopt;
    return control::pick_ground(*terrain, lens, point);
}

// Chân nhân vật trên mặt đất, cùng tam giác với lưới đã vẽ.
ogre::Vec3 Display::State::foot() const {
    const float x = has_shown ? shown_x : walk.x;
    const float z = has_shown ? shown_z : walk.z;
    const float terrain_y = terrain ? terrain->height_at(x, z) : 0.0F;
    const float height = surface_y(held.get(), ground, x, z, terrain_y);
    return ogre::Vec3{.x = x, .y = jump_lift(height), .z = z};
}

void Display::State::ensure_sim() {
    if (sim_clock) return;
    const core::LoopPlan plan = core::loop_plan(core::cpu_count());
    render_hz = plan.render_hz;
    core::TickConfig config;
    config.hz = plan.sim_hz;
    config.max_steps = 4;
    core::Result<core::FixedStep> made = core::FixedStep::create(config);
    if (!made) return;
    sim_clock = *made;
    prev_x = walk.x;
    prev_z = walk.z;
}

void Display::State::simulate_motion(const Steering& keys, core::Clock::time_point now) {
    ensure_sim();
    if (!sim_clock) return;
    begin_strike(keys.strike_slot);
    const std::uint32_t due = sim_clock->advance(now);
    const float step = static_cast<float>(sim_clock->step_seconds());
    std::uint32_t index = 0;
    while (index < due) {
        prev_x = walk.x;
        prev_z = walk.z;
        move_player(keys, step);
        step_jump(keys.wants_jump && index == 0, step);
        ++index;
    }
    const float alpha = sim_clock->alpha();
    shown_x = prev_x + ((walk.x - prev_x) * alpha);
    shown_z = prev_z + ((walk.z - prev_z) * alpha);
    has_shown = true;
}

// Phím ô thao tác: skill ở ô đó (hero.skills), bước chọn ngẫu nhiên rand() % số bước như Start_MagicSend với skill
// kiểu NONE. Đang đi, nhảy hay đang trong đòn chưa tới BreakTime thì không ra đòn (DoSimulantCommand trả RC_WAIT; gốc
// xếp lệnh vào hàng chờ, ở đây bỏ). Ô trống, skill không có clip cho giới và loại vũ khí này thì không làm gì.
// Khác gốc: gốc nhận lệnh từ máy chủ và chọn bước liên hoàn theo lệnh nối tiếp (docs/NGHI-NGO.md).
void Display::State::begin_strike(std::optional<std::uint32_t> slot) {
    if (!slot || !player || is_player_running || jump.is_jumping || player->is_locked(frame_time)) return;
    if (*slot >= hero.skills.size()) return;
    const std::uint32_t skill = hero.skills.at(*slot);
    const std::vector<std::uint32_t> steps = player->steps_of(skill);
    if (steps.empty()) return;
    strike_begun = StrikeCall{.skill = skill, .step = steps.at(strike_dice() % steps.size())};
}

// Công cụ đo: ô cuối của hero.skills được nhấn ở khung màn chơi auto_strike_from rồi mỗi 180 khung.
void Display::State::note_auto_strike(Steering& keys) {
    constexpr std::uint32_t kPeriod = 180;
    ++play_frames;
    const bool is_due = play_frames >= auto_strike_from && (play_frames - auto_strike_from) % kPeriod == 0;
    if (is_due && !hero.skills.empty()) keys.strike_slot = static_cast<std::uint32_t>(hero.skills.size() - 1);
}

// Giữ W suốt, hướng nhìn quay đều theo thời gian khung: nhân vật chạy vòng tròn thay vì đứng ì trước
// vật cản đầu tiên, và camera vừa trôi vừa xoay như lúc người chơi chạy thật.
Steering Display::State::auto_walk(const Steering& keys, float seconds) {
    Steering walking = keys;
    walking.walk_forward = 1.0F;
    walking.walk_right = 0.0F;
    if (terrain) follow.add_direction(*terrain, kWalkTurnPerSecond * seconds);
    return walking;
}

void Display::State::note_walk_step() {
    if (!is_auto_walk) return;
    const ogre::Vec3 here = foot();
    if (walk_last_foot && walk_steps.size() < kMaxWalkSamples) {
        const float across = here.x - walk_last_foot->x;
        const float along = here.z - walk_last_foot->z;
        walk_steps.push_back(std::hypot(across, along));
    }
    walk_last_foot = here;
}

// Bước chân mỗi khung là thứ mắt thấy khi camera bám nhân vật: Fifo hiện mỗi khung đúng một nhịp quét,
// nên bước không đều là cảnh trôi giật. Khung "đứng" (dưới nửa trung vị) là vật cản chặn hay khung lặp;
// khung "gấp" (trên 1,5 lần) là khung bị trễ một nhịp quét rồi bù.
void Display::State::report_walk() const {
    if (!is_auto_walk || walk_steps.size() < 8) return;
    std::vector<float> sorted = walk_steps;
    std::ranges::sort(sorted);
    const auto rank = [&sorted](double part) {
        const auto last = static_cast<double>(sorted.size() - 1);
        return sorted.at(static_cast<std::size_t>(std::lround(last * part)));
    };
    const float median = rank(0.5);
    const auto stalled = std::ranges::count_if(walk_steps, [median](float step) { return step < median * 0.5F; });
    const auto doubled = std::ranges::count_if(walk_steps, [median](float step) { return step > median * 1.5F; });
    std::println("Bước chân mỗi khung lúc tự chạy: {} khung, trung vị {:.2f} cm, p5 {:.2f}, p95 {:.2f}, max {:.2f}; "
                 "{} khung đứng, {} khung bước gấp",
        walk_steps.size(), median, rank(0.05), rank(0.95), sorted.back(), stalled, doubled);
}

// Một bước mô phỏng của cú nhảy: phím nhảy thành CAI_MySelf::Jump (CObject_Character::Jump), rồi
// CObject_Phy::Tick với mặt đất (đơn vị game) dưới chỗ đứng. Đang chạy là logic MOVE. Hành động 9/12
// và lần chạm đất đưa sang Gait của người chơi (ChangeAction, NotifyPhyEvent). Chưa có máy chủ nên không
// gửi CGCharJump.
void Display::State::step_jump(bool wants_jump, float dt) {
    sim_ms += static_cast<std::uint32_t>(std::lround(dt * 1000.0F));
    if (ground == nullptr || !scale_ok(ground->file) || !(ground->file.scale.y > 0.0F)) return;
    const map::TerrainFile& file = ground->file;
    const float terrain_y = terrain ? terrain->height_at(walk.x, walk.z) : 0.0F;
    const float surface = surface_y(held.get(), ground, walk.x, walk.z, terrain_y);
    const float ground_game = (surface - file.origin.y) / file.scale.y;
    // Cú nhảy cũng là lệnh: chờ tới BreakTime của đòn đang phát (RC_WAIT), bấm trong lúc chờ thì bỏ.
    const bool is_waiting = player && player->is_locked(frame_time);
    if (wants_jump && !is_waiting) {
        motion::JumpGate gate;
        gate.is_moving = is_player_running;
        const motion::JumpStart leap =
            motion::start_jump(jump, gate, ground_game, jump_dice());
        if (leap.has_started) {
            jump_begun = leap.action == motion::JumpAction::kJumpRun ? avatar::Stance::kJumpRun
                                                                         : avatar::Stance::kJumpStand;
            jump_landed = false;
        }
    }
    if (motion::tick_jump(jump, sim_ms, ground_game)) jump_landed = true;
}

// Độ cao thế giới của chân: mặt đất, hay thân đang bay khi cao hơn (Axis_Trans GAME sang GFX theo Y).
float Display::State::jump_lift(float surface) const noexcept {
    if (!jump.is_jumping || ground == nullptr) return surface;
    const map::TerrainFile& file = ground->file;
    const float flying = file.origin.y + (jump.height * file.scale.y);
    return flying > surface ? flying : surface;
}

// Phím đi bộ thắng lệnh nhấp chuột; không có phím thì đi tiếp theo lệnh (nếu có).
void Display::State::move_player(const Steering& keys, float dt) {
    // DoSimulantCommand trả RC_WAIT tới BreakTime của đòn đang phát: không đi, lệnh đi còn nguyên chờ sau đòn.
    if (player && player->is_locked(frame_time)) {
        is_player_running = false;
        return;
    }
    const bool is_asked = keys.walk_forward != 0.0F || keys.walk_right != 0.0F;
    if (is_asked) order.reset();
    if (is_asked) walk_free(keys, dt);
    if (!is_asked) walk_order(dt);
}

// Một khung Tick_Move rồi Map::VerifyPos. Chỗ đứng thế giới là Axis_Trans GAME sang GFX.
void Display::State::apply_tick(motion::MoveAsk ask) {
    const motion::MoveStep step = motion::move_tick(ask);
    if (!step.moved) is_player_running = false;
    if (step.moved) place_step(step, ask.here);
    if (step.arrived) finish_leg();
}

// Tới điểm đang hướng tới: lệnh còn điểm sau thì đi tiếp và vẫn tính là đang chạy, hết điểm thì
// xong lệnh.
void Display::State::finish_leg() {
    if (!order) return;
    ++order->next;
    const bool has_more = order->next < order->path.size();
    if (has_more) is_player_running = true;
    if (!has_more) order.reset();
}

void Display::State::place_step(const motion::MoveStep& step, core::GroundPoint from) {
    if (ground == nullptr || !scale_ok(ground->file)) return;
    const map::TerrainFile& file = ground->file;
    motion::MapLimit limit;
    limit.width = static_cast<float>(file.x_size);
    limit.depth = static_cast<float>(file.z_size);
    const core::GroundPoint clamped = motion::verify_pos(step.position, limit);
    walk.x = file.origin.x + (clamped.x * file.scale.x);
    walk.z = file.origin.z + (clamped.z * file.scale.z);
    facing = step.facing;
    const bool is_shifted = clamped.x != from.x || clamped.z != from.z;
    is_player_running = is_shifted && !step.arrived;
}

// Đi theo phím W A S D so với hướng nhìn của camera. Tốc độ là chạy (MOVE_MODE_RUN).
void Display::State::walk_free(const Steering& keys, float dt) {
    if (ground == nullptr || !scale_ok(ground->file)) return;
    const map::TerrainFile& file = ground->file;
    const float direction = follow.direction();
    const float ahead_x = std::sin(direction);
    const float ahead_z = std::cos(direction);
    const float world_x = (ahead_x * keys.walk_forward) - (ahead_z * keys.walk_right);
    const float world_z = (ahead_z * keys.walk_forward) + (ahead_x * keys.walk_right);
    const float game_x = world_x / file.scale.x;
    const float game_z = world_z / file.scale.z;
    const float length = std::sqrt((game_x * game_x) + (game_z * game_z));
    if (!(length > 0.0F)) {
        is_player_running = false;
        return;
    }
    const float speed = motion::human_speed(motion::MoveMode::kRun);
    const float reach = (speed * dt) + 1.0F;
    const core::GroundPoint here = game_of(file, walk);
    motion::MoveAsk ask;
    ask.here = here;
    ask.target.x = here.x + ((game_x / length) * reach);
    ask.target.z = here.z + ((game_z / length) * reach);
    // Phím đi không có ở bản gốc: bước dừng trước vật cản đầu tiên, không bao giờ kết thúc trong nó.
    if (walk_field != nullptr) ask.target = walk_field->step_reach(nav::Segment{.start = here, .end = ask.target});
    ask.speed = speed;
    ask.seconds = dt;
    apply_tick(ask);
}

// Đi theo lệnh: một khung Tick_Move tới điểm đang hướng tới của lệnh, tốc độ chạy.
void Display::State::walk_order(float dt) {
    is_player_running = false;
    if (!order || ground == nullptr || !scale_ok(ground->file)) return;
    motion::MoveAsk ask;
    ask.here = game_of(ground->file, walk);
    ask.target = order->path[order->next];
    ask.speed = motion::human_speed(motion::MoveMode::kRun);
    ask.seconds = dt;
    apply_tick(ask);
}

void Display::State::load_player() {
    if (catalog) {
        const core::Status tier = catalog->prepare(render::Tier::kEssential);
        if (!tier) std::println(stderr, "Pipeline: tầng chơi: {}", tier.error());
    }
    if (data_root.empty()) return;
    PlayerDesc desc;
    desc.data_root = data_root;
    if (has_role_look) desc.race = role_race;
    if (has_role_look) desc.look = role_look;
    desc.weapon_item = hero.equipment.at(hero::EquipPoint::kWeapon);
    desc.weapon_gem = hero.equipment.gem_at(hero::EquipPoint::kWeapon).value_or(0);
    desc.skills = hero.skills;
    if (tables_job.valid()) desc.tables = tables_job.get();
    const MeshLoader loader = [this](const std::string& mesh) -> const render::Drawable* {
        const std::size_t index = load_mesh(mesh);
        return index == kMissing ? nullptr : &kept.at(index).loaded.drawable;
    };
    auto made = PlayerActor::create(desc, loader);
    if (!made) {
        std::println(stderr, "Không có người chơi: {}", made.error());
        return;
    }
    player.emplace(std::move(*made));
    follow_handles.clear();
    std::println("Người chơi: {} bộ phận", player->figure().parts.size());
    load_head(desc, loader);
}

// Ảnh đầu 3D cho ô chân dung: một bản mô hình cùng ngoại hình với người chơi. Không dựng được thì
// ghi một dòng và bỏ qua.
void Display::State::keep_view(HeadShot& shot, std::string_view name) {
    const core::Result<std::uint32_t> texture = ui_pass->add_view(shot.view());
    if (!texture) {
        std::println(stderr, "Chân dung: không gắn được ảnh {}: {}", name, texture.error());
        return;
    }
    ui::ViewPaint& view = head_views.at(view_count);
    view.name = name;
    view.texture = *texture;
    view.is_bottom_up = shot.is_bottom_up();
    ++view_count;
}

void Display::State::load_head(const PlayerDesc& desc, const MeshLoader& loader) {
    if (!ui_pass || head) return;
    HeadShotDesc shot;
    shot.player = desc;
    // Ảnh chân dung không ra đòn: không nạp bảng skill và clip đòn cho chúng (ngân sách nạp đầu).
    shot.player.skills.clear();
    shot.forward = forward.get();
    shot.color_format = screen->color_format();
    shot.depth_format = screen->depth_format();
    shot.samples = screen->samples();
    core::Result<HeadShot> made = HeadShot::create(*device, shot, loader);
    if (!made) {
        std::println(stderr, "Chân dung: không dựng được đầu 3D: {}", made.error());
        return;
    }
    head.emplace(std::move(*made));
    keep_view(*head, ui::kPlayerHead);
    shot.is_body = true;
    // Cửa sổ ảnh toàn thân của bảng nhân vật rộng 246 điểm ảnh, client gốc dùng texture 256 (cỡ cửa sổ làm tròn lên luỹ
    // thừa 2) và giao diện phủ cả texture lên cửa sổ, nên mô hình bị lấy mẫu lại và mờ. 512 là vẽ gấp đôi mỗi chiều rồi
    // lấy mẫu tuyến tính xuống gần đúng 2:1, tức khử răng cưa tại chỗ.
    shot.pixels = 512;
    core::Result<HeadShot> whole = HeadShot::create(*device, shot, loader);
    if (!whole) {
        std::println(stderr, "Chân dung: không dựng được toàn thân: {}", whole.error());
        return;
    }
    body.emplace(std::move(*whole));
    keep_view(*body, ui::panel::kEquipModel);
}

// Vẽ ảnh đầu vào đích riêng của nó, sau khi lượt vẽ màn hình đã đóng: giao diện của khung kế lấy
// mẫu ảnh này. Ghi ở cuối khung để khung bị bỏ (bề mặt đổi cỡ) không để lại ảnh đích dở dang.
void Display::State::record_head(gpu::CommandList& list) {
    if (!head && !body) return;
    const std::uint32_t count = screen->image_count();
    const std::uint32_t turn = head_turns % count;
    if (head) {
        const core::Status drawn = head->record(list, count + turn);
        if (!drawn) std::println(stderr, "Chân dung: {}", drawn.error());
    }
    if (body) {
        const core::Status drawn = body->record(list, (count * 2U) + turn);
        if (!drawn) std::println(stderr, "Toàn thân: {}", drawn.error());
    }
    ++head_turns;
}

namespace {

// Ngoại hình mà mô hình của giao diện đòi, để so với thứ RoleShot đang vẽ.
[[nodiscard]] RoleLook role_look_of(const ui::panel::ShownModel& model) noexcept {
    RoleLook look;
    look.sex = model.sex;
    look.face = model.face;
    look.hair = model.hair;
    look.body = model.body;
    look.arm = model.arm;
    look.foot = model.foot;
    look.sect = model.sect;
    return look;
}

} // namespace

PlayerDesc Display::State::role_player(const ui::panel::ShownModel& model) const {
    PlayerDesc desc;
    desc.data_root = data_root;
    desc.race = model.sex == 0 ? look::Race::kFemale : look::Race::kMale;
    look::Look worn;
    worn.face = model.face;
    worn.hair = model.hair;
    worn.body = model.body;
    worn.arm = model.arm;
    worn.foot = model.foot;
    desc.look = worn;
    if (model.sect >= 0) desc.sect = static_cast<std::uint8_t>(model.sect);
    return desc;
}

MeshLoader Display::State::meshes() {
    return [this](const std::string& mesh) -> const render::Drawable* {
        const std::size_t index = load_mesh(mesh);
        return index == kMissing ? nullptr : &kept.at(index).loaded.drawable;
    };
}

// Người mẫu dựng một lần; đổi mặt, tóc hay bộ đồ thì nạp lại lưới (RoleShot::retarget).
void Display::State::open_role(const ui::panel::ShownModel& model) {
    if (role_shot) return;
    core::Result<RoleShot> made = RoleShot::create(role_player(model), meshes());
    if (!made) {
        std::println(stderr, "Nhân vật: không dựng được mô hình: {}", made.error());
        return;
    }
    role_shot.emplace(std::move(*made));
}

bool Display::State::shows_world_role() const {
    if (procedure != Procedure::kLogin || !hud) return false;
    return hud->role_model().in_world;
}

bool Display::State::shows_role_scene() const {
    if (procedure != Procedure::kLogin || !hud) return false;
    return hud->role_model().on_role_scene;
}

// Camera của cảnh chọn nhân vật: tư thế mà phần thủ tục (role_stage) vừa tính ở khung này.
render::Camera Display::State::role_scene_camera(render::ViewSize size) const {
    const std::optional<control::TrackPose> pose = role_stage.camera();
    if (!pose) return login_camera(size);
    return role_pose_camera(pose->eye, pose->look, size);
}

// Một nhịp của thủ tục chọn hay tạo nhân vật phía camera. Gọi trước khi xoá cờ lăn của khung.
void Display::State::step_role_stage() {
    if (!hud || !shows_role_scene()) {
        role_stamp.reset();
        return;
    }
    const core::Clock::time_point now = frame_time;
    StageFrame frame;
    frame.now_ms =
        static_cast<std::uint32_t>(std::chrono::duration_cast<std::chrono::milliseconds>(now - started).count());
    if (role_stamp) frame.seconds = std::chrono::duration<float>(now - *role_stamp).count();
    // Chuột nằm trên khung cuộn chữ của giao diện thì nấc lăn thuộc về khung đó, camera không phóng.
    const bool is_ui_wheel = hud->takes_wheel(pointer.x * static_cast<float>(screen->width()),
        pointer.y * static_cast<float>(screen->height()));
    frame.is_wheel_up = is_wheel_up && !is_ui_wheel;
    frame.is_wheel_down = is_wheel_down && !is_ui_wheel;
    role_stamp = now;
    role_stage.step(hud->role_model(), frame);
}

void Display::State::append_login_role() {
    if (!shows_world_role()) return;
    const ui::panel::ShownModel& model = hud->role_model();
    open_role(model);
    if (!role_shot) return;
    RoleShot& shot = *role_shot;
    const RoleLook look = role_look_of(model);
    const bool is_ready = shot.matches(look) || shot.retarget(role_player(model), meshes());
    if (!is_ready) return;
    Stand stand;
    stand.foot = point_of(model.is_creating ? control::kCreateFeet : control::role_place(model.slot).feet);
    stand.scale = model.is_creating ? control::kCreateScale : 1.0F;
    stand.facing = model.yaw;
    const core::Status posed = shot.pose(stand);
    if (!posed) {
        std::println(stderr, "Nhân vật: {}", posed.error());
        return;
    }
    shot.append(frame_instances);
}
} // namespace game::client
