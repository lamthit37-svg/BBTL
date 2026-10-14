// Bản Windows của cửa sổ xem cảnh: một cửa sổ của module window, phần hiển thị của nó
// (client/display.hpp) và vòng thông điệp. Luồng vẽ nằm trong Display, tự vẽ lấy; luồng này chỉ
// đọc sự kiện rồi chuyển cỡ vùng vẽ cho nó, nên kéo hay đổi cỡ cửa sổ không bao giờ đứng chờ GPU.
// Người dùng đóng cửa sổ thì pump_messages trả Quit; phần hiển thị bị huỷ trước cửa sổ: luồng vẽ
// dừng hẳn và GPU rỗi trước khi HWND biến mất.
#include "audio/engine.hpp"
#include "client/viewer/viewer.hpp"
#include "client/world/world.hpp"

#include "client/display/display.hpp"
#include "client/viewer/client_size.hpp"
#include "client/viewer/cursors.hpp"
#include "client/viewer/sdl_input.hpp"
#include "control/cursor_rules.hpp"
#include "control/input.hpp"
#include "core/clock.hpp"
#include "core/error.hpp"
#include "core/timeline.hpp"
#include "io/platform.hpp"
#include "window/cursor.hpp"
#include "window/system.hpp"
#include "window/types.hpp"
#include "window/window.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <functional>
#include <memory>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <string_view>
#include <thread>
#include <vector>

namespace game::client {
namespace {

// Nhịp vòng thông điệp khi Windows giữ vòng kéo hoặc đổi cỡ, cỡ một khung hình.
// Luồng thông điệp nghỉ 8 ms: đủ thưa để không chiếm một lõi, đủ mau cho trần 120 khung/giây.
constexpr std::chrono::milliseconds kFramePause{8};
struct LoopStats {
    std::uint32_t frames = 0;
    std::uint32_t resizes = 0;
};

[[nodiscard]] PixelSize pixels(window::Size size) noexcept {
    return {.width = size.width, .height = size.height};
}

// Cỡ vùng vẽ mà phần hiển thị phải theo sau sự kiện này; không có khi sự kiện không đổi cỡ. Thu
// nhỏ và khôi phục không sinh Resized (vùng vẽ ghi nhớ không đổi) nhưng bề mặt thì về cỡ 0 rồi trở
// lại: thiếu hai nhánh ấy phần hiển thị dựng swapchain cỡ 0 và báo lỗi (đã gặp khi thu nhỏ).
[[nodiscard]] std::optional<PixelSize> size_after(const window::Window& opened, const window::Event& event) noexcept {
    if (event.kind == window::EventKind::kResized) return pixels(event.size);
    if (event.kind == window::EventKind::kMinimized) return PixelSize{};
    if (event.kind == window::EventKind::kRestored) return pixels(opened.client_size());
    return std::nullopt;
}

// Gom tham số của một lượt đọc sự kiện.
struct Frame {
    window::Window* opened = nullptr;
    Display* display = nullptr;
    LoopStats* stats = nullptr;
};

void note_event(const Frame& frame, const window::Event& event) noexcept {
    if (event.kind == window::EventKind::kResized) ++frame.stats->resizes;
    const std::optional<PixelSize> size = size_after(*frame.opened, event);
    if (size) frame.display->notify_resized(*size);
}

// Một lượt vòng: đọc hết sự kiện rồi chuyển cỡ vùng vẽ cho luồng vẽ; không chạm GPU ở đây.
void step(window::Window& opened, Display& display, LoopStats& stats) {
    const Frame frame{.opened = &opened, .display = &display, .stats = &stats};
    for (const window::Event& event : opened.poll_events()) {
        note_event(frame, event);
    }
    ++stats.frames;
}

[[nodiscard]] bool is_done(const ViewerDesc& desc, const Display& display, const LoopStats& stats) {
    if (!display.is_spinning()) return true;
    return desc.frames.has_value() && stats.frames >= *desc.frames;
}

void finish_if_done(window::Window& opened, const ViewerDesc& desc, const Display& display, const LoopStats& stats) {
    if (!is_done(desc, display, stats)) return;
    window::request_quit();
    opened.cancel_size_move();
}

// Mọi thứ của một lần chạy vòng lặp; các hàm dưới cùng nhận một tham chiếu tới nó.
struct Controls;

struct Session {
    window::Window* opened = nullptr;
    Display* display = nullptr;
    const ViewerDesc* desc = nullptr;
    // Đang ở màn chơi: cảnh của playing được đưa cho phần hiển thị mỗi vòng. Màn đăng nhập thì chưa.
    std::atomic<bool>* is_playing = nullptr;
    int shown_id = -1;
    // Loa của lần chạy: vào cảnh mới thì đổi sang nhạc nền của cảnh. nullptr khi chưa mở.
    audio::Engine* speaker = nullptr;
    // Tra tên cảnh theo ngôn ngữ của bản dựng, cho tiêu đề cửa sổ.
    SceneTitle scene_title;
    LoopStats stats;
    GameCursors cursors;
    std::optional<control::CursorKind> shown_kind;
    SdlInput* input = nullptr;
    Controls* controls = nullptr;
    std::vector<SdlAction> actions;
};

[[nodiscard]] int direction_of(SdlKey key) noexcept {
    if (key == SdlKey::kPageDown) return 1;
    if (key == SdlKey::kPageUp) return -1;
    return 0;
}

[[nodiscard]] std::size_t pick_index(std::size_t found, std::size_t index, bool is_match) noexcept {
    if (is_match) return index;
    return found;
}

[[nodiscard]] std::size_t index_of(const world::World& playing, int id) noexcept {
    std::size_t found = 0;
    const std::size_t count = playing.book.rows.size();
    for (std::size_t index = 0; index < count; ++index) {
        found = pick_index(found, index, playing.book.rows[index].id == id);
    }
    return found;
}

struct Place {
    std::size_t index = 0;
    std::size_t count = 0;
};

[[nodiscard]] std::size_t neighbor(Place place, int step) noexcept {
    if (place.count == 0) return 0;
    if (step > 0) return (place.index + 1) % place.count;
    if (place.index == 0) return place.count - 1;
    return place.index - 1;
}

enum class Hop : std::uint8_t { kStop, kSkip };

[[nodiscard]] Hop when_failed(const world::EnterResult& entered) {
    if (entered.error() == world::EnterError::kMissingFile) return Hop::kSkip;
    std::println(stderr, "Lỗi: {}", world::describe(entered.error()));
    return Hop::kStop;
}

Hop hop(world::World& playing, const std::filesystem::path& folder, int id) {
    const world::EnterResult entered = world::enter(playing, id, folder);
    if (!entered) return when_failed(entered);
    return Hop::kStop;
}

struct Cursor {
    std::size_t index = 0;
    std::size_t left = 0;
    int step = 0;
};

[[nodiscard]] bool step_cursor(Cursor& cursor, std::size_t count) noexcept {
    if (cursor.left == 0 || count == 0) return false;
    --cursor.left;
    const Place place{.index = cursor.index, .count = count};
    cursor.index = neighbor(place, cursor.step);
    return true;
}

[[nodiscard]] Hop after_step(world::World& playing, const std::filesystem::path& folder, Cursor& cursor) {
    const std::size_t count = playing.book.rows.size();
    if (!step_cursor(cursor, count)) return Hop::kStop;
    return hop(playing, folder, playing.book.rows[cursor.index].id);
}

void change_map(world::World& playing, const std::filesystem::path& folder, int step) {
    if (playing.book.rows.empty()) return;
    const std::shared_ptr<const world::ShownScene> scene = world::current_scene(playing);
    const int id = scene ? scene->id : -1;
    Cursor cursor;
    cursor.index = index_of(playing, id);
    cursor.left = playing.book.rows.size();
    cursor.step = step;
    while (after_step(playing, folder, cursor) == Hop::kSkip) {
    }
}

// Số bước đổi map còn chờ. Luồng phím cộng vào; luồng nạp lấy ra. Không đụng cửa sổ.
struct MapRequest {
    std::atomic<int> pending{0};
    std::atomic<bool> stop{false};
};

void serve_one(world::World& playing, const std::filesystem::path& folder, MapRequest& request) {
    const int pending = request.pending.exchange(0, std::memory_order_relaxed);
    if (pending == 0) {
        std::this_thread::sleep_for(std::chrono::milliseconds(2));
        return;
    }
    const int one = pending > 0 ? 1 : -1;
    change_map(playing, folder, one);
    if (pending == one) return;
    request.pending.fetch_add(pending - one, std::memory_order_relaxed);
}

void serve_maps(world::World& playing, const std::filesystem::path& folder, MapRequest& request) {
    while (!request.stop.load(std::memory_order_relaxed)) {
        serve_one(playing, folder, request);
    }
}

struct MapLoader {
    MapRequest request;
    std::jthread thread;
    ~MapLoader() {
        request.stop.store(true, std::memory_order_relaxed);
        if (thread.joinable()) thread.join();
    }
    MapLoader() = default;
    MapLoader(const MapLoader&) = delete;
    MapLoader& operator=(const MapLoader&) = delete;
    MapLoader(MapLoader&&) = delete;
    MapLoader& operator=(MapLoader&&) = delete;
};

// Phím đi bộ đang giữ; luồng cửa sổ là luồng duy nhất đọc và ghi nên không cần khoá.
struct Held {
    bool is_forward = false;
    bool is_back = false;
    bool is_left = false;
    bool is_right = false;
};

// Con trỏ theo SDL: vị trí đã chuẩn hoá và nút viewer đã gửi. Độ dời lấy từ xrel/yrel.
struct Pointer {
    float x = 0.0F;
    float y = 0.0F;
    bool is_left_down = false;
    bool is_right_down = false;
    bool is_middle_down = false;
};

// Mọi thứ mà luồng cửa sổ cần để dịch thông điệp thành điều khiển. Chỉ luồng cửa sổ chạm vào.
struct Controls {
    window::Window* opened = nullptr;
    const ViewerDesc* desc = nullptr;
    MapRequest* maps = nullptr;
    Display* display = nullptr;
    // Đang ở màn chơi; màn đăng nhập không đổi map bằng phím.
    const std::atomic<bool>* is_playing = nullptr;
    Held held;
    Pointer pointer;
};

[[nodiscard]] float axis_of(bool is_positive, bool is_negative) noexcept {
    return (is_positive ? 1.0F : 0.0F) - (is_negative ? 1.0F : 0.0F);
}

// Chỉ phần đi bộ của điều khiển: ghi đè hai trục, không cộng thêm xoay hay zoom.
void send_walk(const Controls& controls) {
    Steering input;
    input.has_walk = true;
    input.walk_forward = axis_of(controls.held.is_forward, controls.held.is_back);
    input.walk_right = axis_of(controls.held.is_right, controls.held.is_left);
    controls.display->steer(input);
}

// Phím đi bộ và cờ giữ tương ứng.
struct WalkKey {
    SdlKey key = SdlKey::kNone;
    bool Held::* flag = nullptr;
};

constexpr std::array<WalkKey, 4> kWalkKeys{{
    {.key = SdlKey::kW, .flag = &Held::is_forward},
    {.key = SdlKey::kS, .flag = &Held::is_back},
    {.key = SdlKey::kA, .flag = &Held::is_left},
    {.key = SdlKey::kD, .flag = &Held::is_right},
}};

// Trả true khi phím là phím đi bộ và đã ghi nhận trạng thái.
bool note_walk_key(Held& held, SdlKey key, bool is_down) noexcept {
    const auto found = std::ranges::find(kWalkKeys, key, &WalkKey::key);
    if (found == kWalkKeys.end()) return false;
    held.*(found->flag) = is_down;
    return true;
}

// Phím xoay và zoom kính theo GamePro_Main.cpp: mỗi sự kiện phím (kể cả lặp) một bước.
struct CameraKeyStep {
    SdlKey key = SdlKey::kNone;
    int turn = 0;
    int zoom = 0;
};

constexpr std::array<CameraKeyStep, 4> kCameraKeys{{
    {.key = SdlKey::kLeft, .turn = 1, .zoom = 0},
    {.key = SdlKey::kRight, .turn = -1, .zoom = 0},
    {.key = SdlKey::kUp, .turn = 0, .zoom = 1},
    {.key = SdlKey::kDown, .turn = 0, .zoom = -1},
}};

[[nodiscard]] Steering camera_key_steering(SdlKey key) noexcept {
    Steering input;
    input.is_home = key == SdlKey::kV;
    const auto found = std::ranges::find(kCameraKeys, key, &CameraKeyStep::key);
    if (found == kCameraKeys.end()) return input;
    input.turn_keys = found->turn;
    input.zoom_keys = found->zoom;
    return input;
}

void on_key_down(Controls& controls, SdlKey key, bool is_repeat) {
    if (note_walk_key(controls.held, key, true)) {
        send_walk(controls);
        return;
    }
    Steering input = camera_key_steering(key);
    input.toggles_pace = key == SdlKey::kF3 && !is_repeat;
    controls.display->steer(input);
    if (key == SdlKey::kSpace && !is_repeat) controls.display->act(PlayAct::kJump);
    const int step = direction_of(key);
    const bool has_world = controls.desc->playing != nullptr && controls.is_playing->load(std::memory_order_relaxed);
    const bool can_change = has_world && step != 0 && !is_repeat;
    if (!can_change || controls.desc->playing->book.rows.empty()) return;
    controls.maps->pending.fetch_add(step, std::memory_order_relaxed);
}

void send_event(const Controls& controls, const control::InputEvent& event) {
    const std::array<control::InputEvent, 1> one{event};
    controls.display->input(one);
}

void remember_button(Pointer& pointer, control::MouseButton button, bool is_down) noexcept {
    if (button == control::MouseButton::kLeft) pointer.is_left_down = is_down;
    if (button == control::MouseButton::kRight) pointer.is_right_down = is_down;
    if (button == control::MouseButton::kMiddle) pointer.is_middle_down = is_down;
}

void apply_event(Controls& controls, const control::InputEvent& event) {
    const bool is_press = event.kind == control::InputKind::kPress;
    const bool is_release = event.kind == control::InputKind::kRelease;
    if (is_press || is_release) remember_button(controls.pointer, event.button, is_press);
    if (event.kind == control::InputKind::kMove || is_press || is_release) {
        controls.pointer.x = event.x;
        controls.pointer.y = event.y;
    }
    send_event(controls, event);
}

[[nodiscard]] char32_t control_char(SdlKey key) noexcept {
    if (key == SdlKey::kBackspace) return 8;
    if (key == SdlKey::kTab) return 9;
    if (key == SdlKey::kEnter) return 13;
    if (key == SdlKey::kEscape) return 27;
    return 0;
}

void apply_key(Controls& controls, SdlKey key, bool is_down, bool is_repeat) {
    const char32_t typed = control_char(key);
    if (is_down && typed != 0) {
        control::InputEvent text;
        text.kind = control::InputKind::kText;
        text.text = typed;
        send_event(controls, text);
    }
    if (!is_down) {
        if (note_walk_key(controls.held, key, false)) send_walk(controls);
        return;
    }
    on_key_down(controls, key, is_repeat);
}

void release_held(Controls& controls, bool Pointer::* flag, control::MouseButton button) {
    if (!(controls.pointer.*flag)) return;
    controls.pointer.*flag = false;
    control::InputEvent release;
    release.kind = control::InputKind::kRelease;
    release.button = button;
    release.x = controls.pointer.x;
    release.y = controls.pointer.y;
    send_event(controls, release);
}

// Mất focus: thả phím đi bộ, huỷ thao tác trái, nhả nút đang kéo camera.
void apply_blur(Controls& controls) {
    controls.held = Held{};
    send_walk(controls);
    controls.pointer.is_left_down = false;
    control::InputEvent cancel;
    cancel.kind = control::InputKind::kCancel;
    cancel.x = controls.pointer.x;
    cancel.y = controls.pointer.y;
    send_event(controls, cancel);
    release_held(controls, &Pointer::is_right_down, control::MouseButton::kRight);
    release_held(controls, &Pointer::is_middle_down, control::MouseButton::kMiddle);
    controls.opened->capture_cursor(false);
}

void apply_stick(const Controls& controls, const SdlAction& action) {
    if (!action.stick_active) {
        send_walk(controls);
        return;
    }
    Steering input;
    input.has_walk = true;
    input.walk_forward = action.stick_forward;
    input.walk_right = action.stick_right;
    controls.display->steer(input);
}

void apply_action(Controls& controls, const SdlAction& action) {
    if (action.kind == SdlAction::Kind::kEvent) apply_event(controls, action.event);
    if (action.kind == SdlAction::Kind::kKey) apply_key(controls, action.key, action.is_down, action.is_repeat);
    if (action.kind == SdlAction::Kind::kBlur) apply_blur(controls);
    if (action.kind == SdlAction::Kind::kStick) apply_stick(controls, action);
}

void drain_input(SdlInput& input, Controls& controls, std::vector<SdlAction>& actions) {
    const bool is_held = controls.opened->is_cursor_captured();
    input.set_relative(is_held);
    input.drain(actions);
    for (const SdlAction& action : actions)
        apply_action(controls, action);
}

// Thời gian chuyển nhạc khi đổi cảnh, giây: nhạc cũ nhỏ dần trong lúc nhạc mới lên.
constexpr float kSceneMusicFade = 1.0F;

// Nhạc nền của cảnh theo cột 9 của bảng cảnh, id tra trong sound_table.xml. Cảnh không có nhạc
// riêng thì giữ bài đang phát. Lỗi (thiếu id, thiếu tệp) chỉ ghi log: không chặn việc vào cảnh.
void play_scene_music(audio::Engine* speaker, const world::ShownScene& scene) {
    if (speaker == nullptr || !speaker->device_is_open() || scene.music <= 0) return;
    const std::string id = std::to_string(scene.music);
    const core::Status played = speaker->play_music(id, kSceneMusicFade);
    if (played) {
        std::println("Âm thanh: nhạc nền cảnh {} là id {}", scene.id, id);
        return;
    }
    std::println(stderr, "Âm thanh: nhạc nền cảnh {} (id {}): {}", scene.id, id, played.error());
}

// Cảnh đang chơi đổi thì in một dòng và đặt lại tiêu đề cửa sổ, tên cảnh theo ngôn ngữ của bản dựng.
void note_scene(Session& session) {
    const std::shared_ptr<const world::ShownScene> scene = world::current_scene(*session.desc->playing);
    if (!scene || scene->id == session.shown_id) return;
    session.shown_id = scene->id;
    std::println("Vào cảnh resid {} ({})", scene->id, scene->scene_file);
    session.opened->set_title(std::string(kGameTitle) + " — " + session.scene_title(scene->name));
    play_scene_music(session.speaker, *scene);
}

// Ảnh lấy từ Interface/cursor. Ô trống thì mũi tên hệ thống.
void apply_picture(window::Window& opened, const GameCursors& cursors, control::CursorKind kind) {
    const auto slot = static_cast<std::size_t>(kind);
    const std::optional<window::Cursor>& picture = cursors.pictures.at(slot);
    if (picture) {
        opened.set_cursor(*picture);
        return;
    }
    opened.set_cursor(window::Cursor{});
}

// Màn chơi không chọn con trỏ nào nghĩa là camera đang được kéo: ẩn và giữ con trỏ như client gốc
// (ShowCursor(FALSE) cùng SetCapture); thôi kéo thì con trỏ hiện lại ở chỗ nó bị giữ. Cửa sổ không
// có focus thì không giữ: sự kiện nhả do mất focus có thể còn nằm trong hàng chờ của màn chơi.
void apply_game_cursor(Session& session) {
    window::Window& opened = *session.opened;
    const std::optional<control::CursorKind> choice = session.display->cursor_choice();
    const bool is_shown = choice.has_value();
    if (opened.is_cursor_visible() != is_shown) opened.set_cursor_visible(is_shown);
    opened.capture_cursor(!is_shown && opened.is_focused());
    if (!choice) {
        session.shown_kind.reset();
        return;
    }
    if (session.shown_kind == choice) return;
    session.shown_kind = choice;
    apply_picture(opened, session.cursors, *choice);
}

// Tên của từng trang web, cho dòng log; cùng thứ tự với WebLink.
constexpr std::array<std::string_view, 6> kWebLinkNames = {
    "nạp thẻ", "đăng ký tài khoản", "quên mật khẩu", "thẻ bảo mật", "trợ giúp", "diễn đàn"};

// Trang web của một nút. Chưa có trang thật nào (chủ dự án chốt ngày 2026-10-08): mọi liên kết mở
// trang "Coming soon" đi kèm bản dựng, do build_i18n.py đặt vào Web/ của thư mục dữ liệu.
void open_web(const ViewerDesc& desc, WebLink link) {
    const std::filesystem::path page = desc.data_folder / "Web" / "coming_soon.html";
    const bool is_opened = io::open_in_browser(page);
    const std::string_view outcome = is_opened ? "đã mở trang Coming soon" : "không mở được trang Coming soon";
    std::println("Trang web {}: {}", kWebLinkNames.at(static_cast<std::size_t>(link)), outcome);
}

// Rời màn đăng nhập sang màn chơi: bảng chọn đã chốt nhân vật. Khác gốc: CheckAccount gửi tài
// khoản cho máy chủ đăng nhập; client chưa nối máy chủ nào nên vào thẳng cảnh (docs/NGHI-NGO.md).
void enter_game(const Session& session) {
    const ViewerDesc& desc = *session.desc;
    if (session.is_playing->load(std::memory_order_relaxed)) return;
    if (desc.playing == nullptr || !desc.first_scene) {
        std::println(stderr, "Vào game: thư mục dữ liệu không có bảng cảnh hay cảnh đầu tiên");
        return;
    }
    const std::filesystem::path folder = desc.data_folder / "Scene";
    const world::EnterResult entered = world::enter(*desc.playing, *desc.first_scene, folder);
    if (!entered) {
        std::println(stderr, "Vào game: {}", world::describe(entered.error()));
        return;
    }
    session.is_playing->store(true, std::memory_order_relaxed);
    session.display->play(world::current_scene(*desc.playing));
}

void serve_request(const Session& session, Request request) {
    if (request.kind == RequestKind::kOpenWeb) open_web(*session.desc, request.link);
    if (request.kind == RequestKind::kLeave) window::request_quit();
    if (request.kind == RequestKind::kEnterGame) enter_game(session);
}

// Việc giao diện nhờ từ vòng trước (nút của bảng đăng nhập).
void serve_requests(const Session& session) {
    for (const Request request : session.display->take_requests()) {
        serve_request(session, request);
    }
}

void one_frame(Session& session) {
    if (session.input != nullptr && session.controls != nullptr)
        drain_input(*session.input, *session.controls, session.actions);
    apply_game_cursor(session);
    serve_requests(session);
    const bool has_world = session.desc->playing != nullptr && session.is_playing->load(std::memory_order_relaxed);
    if (has_world) {
        note_scene(session);
        const auto scene = world::current_scene(*session.desc->playing);
        session.display->show(scene);
    }
    step(*session.opened, *session.display, session.stats);
    finish_if_done(*session.opened, *session.desc, *session.display, session.stats);
}

// Chưa tới lúc dừng (đủ số vòng, luồng vẽ ngừng) và vòng thông điệp chưa nhận lệnh thoát.
[[nodiscard]] bool pumps_on(const Session& session) {
    if (is_done(*session.desc, *session.display, session.stats)) return false;
    return window::pump_messages() == window::Flow::kRunning;
}

void pump_until_done(Session& session) {
    window::Window& opened = *session.opened;
    opened.set_modal_tick([&session] { one_frame(session); }, kFramePause);
    while (pumps_on(session)) {
        one_frame(session);
        // Luồng vẽ tự vẽ lấy; luồng này không còn bị present chặn, nên tự nhịp nghỉ một khung
        // hình (trước đây 67 triệu vòng bão hoà một lõi — đã đo bằng drive_window.py).
        core::sleep_for(kFramePause);
    }
    // Nhịp modal giữ tham chiếu tới session và phần hiển thị, cả hai chết trước cửa sổ: gỡ nó ra.
    opened.set_modal_tick({}, kFramePause);
}

// Dừng luồng vẽ, in tóm tắt, và đổi kết quả của lần chạy thành mã thoát.
[[nodiscard]] int report(const Session& session) {
    const core::Status finished = session.display->finish();
    const LoopStats& stats = session.stats;
    const window::Size size = session.opened->client_size();
    const std::uint64_t faults = session.display->validation_errors();
    std::println("Cửa sổ đóng sau {} vòng lặp, {} lần đổi cỡ, vùng vẽ cuối {}x{}", stats.frames, stats.resizes,
        size.width, size.height);
    std::println("{} lệnh vẽ của khung cuối, lớp kiểm tra của GPU báo {} lỗi", session.display->draw_count(), faults);
    if (!finished) std::println(stderr, "Lỗi khi vẽ: {}", finished.error());
    const bool is_clean = finished.has_value() && faults == 0;
    return is_clean ? 0 : 1;
}

void begin_speaker(audio::Engine& speaker, const std::filesystem::path& data_root) {
    audio::OpenRequest request;
    request.data_root = data_root;
    const core::Status opened = speaker.open(request);
    if (!opened) {
        const core::Error& fault = opened.error();
        std::println("Âm thanh: {}", fault);
        return;
    }
    const core::Status music = speaker.play_music(audio::kLoginMusicId, 0.F);
    const audio::SoundResult effect = speaker.play_flat(audio::kButtonClickId, 1.F);
    const char* device_text = "không mở";
    if (speaker.device_is_open()) device_text = "mở";
    std::println("Âm thanh: thiết bị {}", device_text);
    if (!music) {
        const core::Error& fault = music.error();
        std::println("Âm thanh: nhạc {}", fault);
    }
    if (!effect) {
        const core::Error& fault = effect.error();
        std::println("Âm thanh: hiệu ứng {}", fault);
    }
}

[[nodiscard]] int present(window::Window& opened, Display& display, const ViewerDesc& desc) {
    std::println("Hiển thị: {}", display.description());
    std::println("Đổi map: Page Up/Page Down. Camera: kéo chuột phải để xoay và ngẩng cúi, kéo nút giữa "
                 "để ngẩng cúi, lăn chuột hoặc mũi tên lên/xuống để zoom, mũi tên trái/phải để xoay, V "
                 "quay về hướng ban đầu. Đi: nhấp chuột trái, W A S D, hoặc cần trái tay cầm");
    const std::filesystem::path scene_folder = desc.data_folder / "Scene";
    MapLoader maps;
    if (desc.playing != nullptr) {
        world::World& playing = *desc.playing;
        maps.thread = std::jthread(serve_maps, std::ref(playing), scene_folder, std::ref(maps.request));
    }
    std::atomic<bool> is_playing{desc.procedure == Procedure::kPlay};
    Controls controls;
    controls.opened = &opened;
    controls.desc = &desc;
    controls.maps = &maps.request;
    controls.display = &display;
    controls.is_playing = &is_playing;
    core::Result<SdlInput> input = SdlInput::open(opened.native_handle());
    if (!input) {
        std::println(stderr, "SDL: {}", input.error());
        return 1;
    }
    Session session;
    session.opened = &opened;
    session.display = &display;
    session.desc = &desc;
    session.scene_title = scene_title_lookup(desc.data_folder);
    session.is_playing = &is_playing;
    session.input = &*input;
    session.controls = &controls;
    session.cursors = load_game_cursors(desc.data_folder);
    audio::Engine speaker;
    begin_speaker(speaker, desc.data_folder);
    session.speaker = &speaker;
    pump_until_done(session);
    const audio::Stats heard = speaker.stats();
    std::println("Âm thanh: {}", audio::describe(heard));
    speaker.close();
    return report(session);
}

// Cửa sổ theo chuẩn client 2026: vùng chơi đúng View_Resoution (mặc định 1280x720) và khung cố
// định kiểu 0xCA0000, không viền kéo, không nút phóng to, nên tỉ lệ khung chơi không bị méo.
[[nodiscard]] window::WindowConfig window_config_of(const ViewerDesc& desc) {
    const ClientSize wanted = client_size_of(desc);
    window::WindowConfig config;
    config.title = desc.title;
    config.client_size = {.width = wanted.width, .height = wanted.height};
    config.is_resizable = false;
    return config;
}

} // namespace

int run_viewer(const ViewerDesc& desc) {
    const window::WindowConfig config = window_config_of(desc);
    core::Result<window::Window> opened = window::Window::create(config);
    if (!opened) {
        std::println(stderr, "Lỗi: không mở được cửa sổ: {}", opened.error());
        return 1;
    }
    core::mark("cửa sổ mở");
    const window::Size initial = opened->client_size();
    DisplayDesc shown;
    shown.window = opened->native_handle();
    shown.size = {.width = initial.width, .height = initial.height};
    shown.stage = desc.stage;
    shown.ground = desc.ground;
    const bool is_login = desc.procedure == Procedure::kLogin;
    shown.scene = is_login || desc.playing == nullptr ? desc.backdrop : world::current_scene(*desc.playing);
    if (is_login) shown.role_scene = desc.role_scene;
    shown.data_root = desc.data_folder;
    shown.shot_path = desc.shot;
    shown.is_bare = desc.is_bare;
    shown.shows_pace = desc.shows_pace;
    shown.is_validated = desc.is_validated;
    shown.backend = desc.backend;
    shown.procedure = desc.procedure;
    shown.preload = desc.preload;
    core::Result<Display> display = Display::create(shown);
    if (!display) {
        std::println(stderr, "Lỗi: không khởi tạo được phần hiển thị: {}", display.error());
        return 1;
    }
    core::mark("Display::create xong");
    return present(*opened, *display, desc);
}

} // namespace game::client
