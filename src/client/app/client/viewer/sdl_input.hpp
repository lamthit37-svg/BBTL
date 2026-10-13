// Nguồn nhập của client trên Windows: SDL3 bọc HWND sẵn có. Chuột, bàn phím, chữ gõ và
// tay cầm chỉ đến từ hàng sự kiện SDL. Cửa sổ vẫn do module window giữ cho swapchain.
#pragma once

#include "control/input.hpp"
#include "core/error.hpp"

#include <cstdint>
#include <memory>
#include <vector>

namespace game::client {

// Phím mà vòng cửa sổ hiểu. Giá trị là của SDL, không phải mã ảo Win32.
enum class SdlKey : std::uint8_t {
    kNone,
    kW,
    kA,
    kS,
    kD,
    kLeft,
    kRight,
    kUp,
    kDown,
    kPageUp,
    kPageDown,
    kV,
    kF11,
    kSpace,
    kBackspace,
    kTab,
    kEnter,
    kEscape,
};

// Một việc SDL vừa báo, theo thứ tự PollEvent.
struct SdlAction {
    enum class Kind : std::uint8_t { kEvent, kKey, kBlur, kStick };
    Kind kind = Kind::kEvent;
    control::InputEvent event;
    SdlKey key = SdlKey::kNone;
    bool is_down = false;
    bool is_repeat = false;
    // Cần trái của tay cầm, -1..1. forward dương là tiến. stick_active sai thì trả về phím.
    float stick_forward = 0.0F;
    float stick_right = 0.0F;
    bool stick_active = false;
};

// Một cửa sổ SDL gắn vào HWND. Huỷ thì gỡ tay cầm, cửa sổ SDL và SDL_Quit.
class SdlInput {
public:
    SdlInput() = default;
    SdlInput(SdlInput&&) noexcept;
    SdlInput& operator=(SdlInput&&) noexcept;
    SdlInput(const SdlInput&) = delete;
    SdlInput& operator=(const SdlInput&) = delete;
    ~SdlInput();

    [[nodiscard]] static core::Result<SdlInput> open(void* native_window);

    // Bật chế độ chuột tương đối của SDL khi camera đang giữ con trỏ.
    void set_relative(bool is_relative) noexcept;
    // Lấy hết sự kiện đang chờ. out bị xoá rồi ghi lại.
    void drain(std::vector<SdlAction>& out);

private:
    struct Holder;
    std::unique_ptr<Holder> holder_;
};

} // namespace game::client
