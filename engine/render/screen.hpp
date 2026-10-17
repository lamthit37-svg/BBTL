/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/render/screen.hpp
 *  PHÂN HỆ   : Render / Screen
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đích vẽ lên cửa sổ: swapchain của gpu kèm ảnh độ sâu cùng cỡ, và vòng
 *    acquire, vẽ, present của một khung. Gom phần mà _Ref rải trong từng ví dụ
 *    (acquireNextImage, cmdBindRenderTargets, cmdResourceBarrier về PRESENT,
 *    queuePresent, rồi tự dựng lại depth buffer khi đổi cỡ).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Vòng dùng mỗi khung: begin (trả slot), ghi lệnh vẽ, end, Device::submit với present_target là
// swapchain(), present. begin trả InvalidState khi bề mặt đã đổi cỡ: gọi resize rồi bỏ khung ấy.
// Nguồn: Forge2 src/render/screen.hpp@d7fcd76. Khác gốc: enumerator mang tiền tố k.

#pragma once

#include "core/error.hpp"
#include "gpu/device.hpp"

#include <cstdint>
#include <memory>

namespace game::render {

struct ScreenDesc {
    // HWND của cửa sổ (window::Window::native_handle).
    void* window = nullptr;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    gpu::PresentMode present_mode = gpu::PresentMode::kFifo;
    gpu::Format depth_format = gpu::Format::kD32Float;
    // Số mẫu khử răng cưa (1, 2, 4, 8). Vulkan và D3D resolve trên chip. GLES bị kẹp về 1
    // trong Screen::create: resolve đa mẫu trên PowerVR GE8320 không ra cảnh.
    std::uint32_t samples = 1;
    gpu::ClearColor clear{};
};

// Hình chữ nhật con của ảnh swapchain, điểm ảnh, gốc ở góc trên trái.
struct ScreenView {
    std::uint32_t x = 0;
    std::uint32_t y = 0;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
};

// Ảnh của khung sau lượt vẽ: trình bày thẳng, hoặc chép ra trước (ảnh chụp). Chép thẳng từ bố cục
// vẽ, không vòng qua Present: D3D12 cấm chạm ảnh sau rào cuối về Present trong cùng lần nộp.
enum class ScreenHandoff : std::uint8_t { kPresent, kCopy };

class Screen {
public:
    // Mượn device: Screen phải bị huỷ trước nó.
    [[nodiscard]] static core::Result<Screen> create(gpu::Device& device, const ScreenDesc& desc);

    Screen(Screen&&) noexcept;
    Screen& operator=(Screen&&) noexcept;
    Screen(const Screen&) = delete;
    Screen& operator=(const Screen&) = delete;
    ~Screen();

    // Định dạng màu mà bề mặt đã chốt: renderer vẽ lên Screen phải tạo pipeline theo nó.
    [[nodiscard]] gpu::Format color_format() const noexcept;
    [[nodiscard]] gpu::Format depth_format() const noexcept;
    [[nodiscard]] std::uint32_t width() const noexcept;
    [[nodiscard]] std::uint32_t height() const noexcept;
    // Số ảnh của swapchain: số slot dữ liệu mỗi khung mà renderer cần.
    [[nodiscard]] std::uint32_t image_count() const noexcept;
    // Số mẫu khử răng cưa đang vẽ (1 khi tắt); pipeline vẽ lên màn hình phải khai đúng số này.
    [[nodiscard]] std::uint32_t samples() const noexcept;
    // Đặt vào SubmitDesc::present_target của lần nộp chứa lệnh của khung.
    [[nodiscard]] gpu::Swapchain* swapchain() noexcept;
    // Màu xoá của các lần begin kế tiếp (cảnh đổi thì nền đổi theo màu sương của nó).
    void set_clear(const gpu::ClearColor& clear) noexcept;
    // Khung con mà các lần begin kế tiếp vẽ vào (viewport và scissor); phần ngoài khung là dải đen. Rộng hoặc
    // cao bằng 0, hoặc khung vượt ảnh swapchain, là trọn ảnh và màu xoá của set_clear. Có khung con thì cả ảnh
    // xoá đen: nền cảnh nào không có gì phủ lên cũng đen, nên cảnh phải tự vẽ trời.
    void set_view(const ScreenView& view) noexcept;

    // Lấy ảnh của khung, đưa nó và ảnh độ sâu về bố cục vẽ, mở lượt vẽ và xoá cả hai. Trả chỉ số
    // ảnh, dùng làm slot của renderer.
    [[nodiscard]] core::Result<std::uint32_t> begin(gpu::CommandList& list);
    // Đóng lượt vẽ và đưa ảnh về bố cục Present, hoặc CopySource khi khung được chép ra (kCopy):
    // khi đó người gọi chép xong tự rào ảnh về Present trước khi nộp.
    void end(gpu::CommandList& list, ScreenHandoff handoff);
    // Đưa ảnh lên màn hình; gọi sau Device::submit.
    [[nodiscard]] core::Status present();
    // Dựng lại swapchain và ảnh độ sâu theo cỡ mới; chờ GPU rỗi. Cỡ 0 (cửa sổ thu nhỏ) bị từ chối.
    [[nodiscard]] core::Status resize(std::uint32_t width, std::uint32_t height);

private:
    struct State;

    explicit Screen(std::unique_ptr<State> state) noexcept;

    std::unique_ptr<State> state_;
};

} // namespace game::render
