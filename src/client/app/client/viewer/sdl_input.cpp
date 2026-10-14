// Dịch sự kiện SDL3 sang SdlAction. Toạ độ chuột chia cho cỡ cửa sổ SDL, gốc trái trên.
#include "client/viewer/sdl_input.hpp"

#include <SDL3/SDL.h>

#include <cmath>
#include <memory>
#include <string_view>
#include <utility>
#include <vector>

namespace game::client {
namespace {

struct Pad {
    SDL_Gamepad* device = nullptr;
    SDL_JoystickID id = 0;
    float forward = 0.0F;
    float right = 0.0F;
};

struct Utf8 {
    char32_t point = 0;
    std::size_t units = 0;
};

[[nodiscard]] Utf8 read_utf8(std::string_view bytes) noexcept {
    Utf8 out;
    if (bytes.empty()) return out;
    const auto lead = static_cast<unsigned char>(bytes[0]);
    if (lead < 0x80U) return Utf8{.point = lead, .units = 1};
    std::size_t need = 0;
    char32_t point = 0;
    if (lead >= 0xC2U && lead <= 0xDFU) {
        need = 2;
        point = lead & 0x1FU;
    }
    if (lead >= 0xE0U && lead <= 0xEFU) {
        need = 3;
        point = lead & 0x0FU;
    }
    if (lead >= 0xF0U && lead <= 0xF4U) {
        need = 4;
        point = lead & 0x07U;
    }
    if (need == 0 || bytes.size() < need) return out;
    for (std::size_t index = 1; index < need; ++index) {
        const auto next = static_cast<unsigned char>(bytes[index]);
        if ((next & 0xC0U) != 0x80U) return out;
        point = (point << 6U) | (next & 0x3FU);
    }
    out.point = point;
    out.units = need;
    return out;
}

[[nodiscard]] float stick_unit(std::int16_t value) noexcept {
    const float unit = static_cast<float>(value) / 32767.0F;
    if (unit > -0.2F && unit < 0.2F) return 0.0F;
    if (unit < -1.0F) return -1.0F;
    if (unit > 1.0F) return 1.0F;
    return unit;
}

[[nodiscard]] SdlKey key_of(SDL_Keycode code) noexcept {
    if (code == SDLK_W) return SdlKey::kW;
    if (code == SDLK_A) return SdlKey::kA;
    if (code == SDLK_S) return SdlKey::kS;
    if (code == SDLK_D) return SdlKey::kD;
    if (code == SDLK_LEFT) return SdlKey::kLeft;
    if (code == SDLK_RIGHT) return SdlKey::kRight;
    if (code == SDLK_UP) return SdlKey::kUp;
    if (code == SDLK_DOWN) return SdlKey::kDown;
    if (code == SDLK_PAGEUP) return SdlKey::kPageUp;
    if (code == SDLK_PAGEDOWN) return SdlKey::kPageDown;
    if (code == SDLK_V) return SdlKey::kV;
    if (code == SDLK_F3) return SdlKey::kF3;
    if (code == SDLK_SPACE) return SdlKey::kSpace;
    if (code == SDLK_BACKSPACE) return SdlKey::kBackspace;
    if (code == SDLK_TAB) return SdlKey::kTab;
    if (code == SDLK_RETURN || code == SDLK_KP_ENTER) return SdlKey::kEnter;
    if (code == SDLK_ESCAPE) return SdlKey::kEscape;
    return SdlKey::kNone;
}

[[nodiscard]] SdlKey dpad_of(Uint8 button) noexcept {
    if (button == SDL_GAMEPAD_BUTTON_DPAD_LEFT) return SdlKey::kLeft;
    if (button == SDL_GAMEPAD_BUTTON_DPAD_RIGHT) return SdlKey::kRight;
    if (button == SDL_GAMEPAD_BUTTON_DPAD_UP) return SdlKey::kUp;
    if (button == SDL_GAMEPAD_BUTTON_DPAD_DOWN) return SdlKey::kDown;
    return SdlKey::kNone;
}

[[nodiscard]] control::MouseButton button_of(Uint8 button) noexcept {
    if (button == SDL_BUTTON_LEFT) return control::MouseButton::kLeft;
    if (button == SDL_BUTTON_RIGHT) return control::MouseButton::kRight;
    if (button == SDL_BUTTON_MIDDLE) return control::MouseButton::kMiddle;
    return control::MouseButton::kOther;
}

void place(SDL_Window* window, control::InputEvent& event, float x, float y) noexcept {
    int width = 0;
    int height = 0;
    SDL_GetWindowSize(window, &width, &height);
    if (width <= 0 || height <= 0) return;
    event.x = x / static_cast<float>(width);
    event.y = y / static_cast<float>(height);
}

void push_event(std::vector<SdlAction>& out, control::InputEvent event) {
    SdlAction action;
    action.kind = SdlAction::Kind::kEvent;
    action.event = event;
    out.push_back(action);
}

void push_key(std::vector<SdlAction>& out, SdlKey key, bool is_down, bool is_repeat) {
    if (key == SdlKey::kNone) return;
    SdlAction action;
    action.kind = SdlAction::Kind::kKey;
    action.key = key;
    action.is_down = is_down;
    action.is_repeat = is_repeat;
    out.push_back(action);
}

void push_text(std::vector<SdlAction>& out, std::string_view bytes) {
    std::size_t at = 0;
    while (at < bytes.size()) {
        const Utf8 code = read_utf8(bytes.substr(at));
        if (code.units == 0) return;
        at += code.units;
        control::InputEvent typed;
        typed.kind = control::InputKind::kText;
        typed.text = code.point;
        push_event(out, typed);
    }
}

[[nodiscard]] Pad* find_pad(std::vector<Pad>& pads, SDL_JoystickID id) noexcept {
    for (Pad& pad : pads) {
        if (pad.id == id) return &pad;
    }
    return nullptr;
}

void push_stick(std::vector<SdlAction>& out, const Pad& pad) {
    SdlAction action;
    action.kind = SdlAction::Kind::kStick;
    action.stick_forward = pad.forward;
    action.stick_right = pad.right;
    const bool is_moved = pad.forward != 0.0F || pad.right != 0.0F;
    action.stick_active = is_moved;
    out.push_back(action);
}

void on_axis(std::vector<Pad>& pads, std::vector<SdlAction>& out, const SDL_GamepadAxisEvent& axis) {
    Pad* pad = find_pad(pads, axis.which);
    if (pad == nullptr) return;
    if (axis.axis == SDL_GAMEPAD_AXIS_LEFTX) pad->right = stick_unit(axis.value);
    if (axis.axis == SDL_GAMEPAD_AXIS_LEFTY) pad->forward = -stick_unit(axis.value);
    if (axis.axis == SDL_GAMEPAD_AXIS_LEFTX || axis.axis == SDL_GAMEPAD_AXIS_LEFTY) push_stick(out, *pad);
}

void on_pad_button(std::vector<SdlAction>& out, const SDL_GamepadButtonEvent& button) {
    if (!button.down) return;
    push_key(out, dpad_of(button.button), true, false);
}

void add_pad(std::vector<Pad>& pads, SDL_JoystickID id) {
    if (find_pad(pads, id) != nullptr) return;
    SDL_Gamepad* device = SDL_OpenGamepad(id);
    if (device == nullptr) return;
    Pad pad;
    pad.device = device;
    pad.id = id;
    pads.push_back(pad);
}

void drop_pad(std::vector<Pad>& pads, SDL_JoystickID id) {
    for (std::size_t index = 0; index < pads.size(); ++index) {
        if (pads[index].id != id) continue;
        SDL_CloseGamepad(pads[index].device);
        pads.erase(pads.begin() + static_cast<std::ptrdiff_t>(index));
        return;
    }
}

void on_motion(SDL_Window* window, std::vector<SdlAction>& out, const SDL_MouseMotionEvent& motion) {
    control::InputEvent event;
    event.kind = control::InputKind::kMove;
    place(window, event, motion.x, motion.y);
    event.dx = motion.xrel;
    event.dy = motion.yrel;
    push_event(out, event);
}

void on_button(SDL_Window* window, std::vector<SdlAction>& out, const SDL_MouseButtonEvent& button) {
    control::InputEvent event;
    event.kind = button.down ? control::InputKind::kPress : control::InputKind::kRelease;
    event.button = button_of(button.button);
    place(window, event, button.x, button.y);
    push_event(out, event);
}

void on_wheel(std::vector<SdlAction>& out, const SDL_MouseWheelEvent& wheel) {
    if ((SDL_GetModState() & SDL_KMOD_SHIFT) != 0) return;
    control::InputEvent event;
    event.kind = control::InputKind::kWheel;
    event.wheel = wheel.y;
    push_event(out, event);
}

void on_keyboard(std::vector<SdlAction>& out, const SDL_KeyboardEvent& key) {
    push_key(out, key_of(key.key), key.down, key.repeat);
}

[[nodiscard]] bool is_ours(SDL_Window* window, SDL_WindowID id) noexcept {
    return id == 0 || id == SDL_GetWindowID(window);
}

void take(SDL_Window* window, std::vector<Pad>& pads, std::vector<SdlAction>& out, const SDL_Event& event) {
    if (event.type == SDL_EVENT_GAMEPAD_ADDED) add_pad(pads, event.gdevice.which);
    if (event.type == SDL_EVENT_GAMEPAD_REMOVED) drop_pad(pads, event.gdevice.which);
    if (event.type == SDL_EVENT_GAMEPAD_AXIS_MOTION) on_axis(pads, out, event.gaxis);
    if (event.type == SDL_EVENT_GAMEPAD_BUTTON_DOWN || event.type == SDL_EVENT_GAMEPAD_BUTTON_UP)
        on_pad_button(out, event.gbutton);
    if (event.type == SDL_EVENT_MOUSE_MOTION && is_ours(window, event.motion.windowID))
        on_motion(window, out, event.motion);
    if ((event.type == SDL_EVENT_MOUSE_BUTTON_DOWN || event.type == SDL_EVENT_MOUSE_BUTTON_UP) &&
        is_ours(window, event.button.windowID))
        on_button(window, out, event.button);
    if (event.type == SDL_EVENT_MOUSE_WHEEL && is_ours(window, event.wheel.windowID)) on_wheel(out, event.wheel);
    if ((event.type == SDL_EVENT_KEY_DOWN || event.type == SDL_EVENT_KEY_UP) && is_ours(window, event.key.windowID))
        on_keyboard(out, event.key);
    if (event.type == SDL_EVENT_TEXT_INPUT && event.text.text != nullptr && is_ours(window, event.text.windowID))
        push_text(out, event.text.text);
    if (event.type != SDL_EVENT_WINDOW_FOCUS_LOST || !is_ours(window, event.window.windowID)) return;
    SdlAction blur;
    blur.kind = SdlAction::Kind::kBlur;
    out.push_back(blur);
}

} // namespace

struct SdlInput::Holder {
    SDL_Window* window = nullptr;
    std::vector<Pad> pads;
    bool relative = false;

    ~Holder() {
        for (const Pad& pad : pads)
            SDL_CloseGamepad(pad.device);
        if (window != nullptr) SDL_DestroyWindow(window);
        SDL_Quit();
    }
};

SdlInput::SdlInput(SdlInput&&) noexcept = default;

SdlInput& SdlInput::operator=(SdlInput&&) noexcept = default;

SdlInput::~SdlInput() = default;

core::Result<SdlInput> SdlInput::open(void* native_window) {
    if (native_window == nullptr) return core::fail(core::ErrorCode::kInvalidArgument, "không có HWND");
    if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD))
        return core::fail(core::ErrorCode::kIo, "SDL không khởi tạo", SDL_GetError());
    const SDL_PropertiesID props = SDL_CreateProperties();
    if (props == 0) {
        SDL_Quit();
        return core::fail(core::ErrorCode::kIo, "SDL không tạo được thuộc tính", SDL_GetError());
    }
    SDL_SetPointerProperty(props, SDL_PROP_WINDOW_CREATE_WIN32_HWND_POINTER, native_window);
    SDL_SetBooleanProperty(props, SDL_PROP_WINDOW_CREATE_EXTERNAL_GRAPHICS_CONTEXT_BOOLEAN, true);
    SDL_Window* window = SDL_CreateWindowWithProperties(props);
    SDL_DestroyProperties(props);
    if (window == nullptr) {
        SDL_Quit();
        return core::fail(core::ErrorCode::kIo, "SDL không bọc được cửa sổ", SDL_GetError());
    }
    SDL_StartTextInput(window);
    auto holder = std::make_unique<Holder>();
    holder->window = window;
    SdlInput input;
    input.holder_ = std::move(holder);
    return input;
}

void SdlInput::set_relative(bool is_relative) noexcept {
    if (holder_ == nullptr || holder_->relative == is_relative) return;
    holder_->relative = is_relative;
    SDL_SetWindowRelativeMouseMode(holder_->window, is_relative);
}

void SdlInput::drain(std::vector<SdlAction>& out) {
    out.clear();
    if (holder_ == nullptr) return;
    SDL_Event event{};
    while (SDL_PollEvent(&event))
        take(holder_->window, holder_->pads, out, event);
}

} // namespace game::client
