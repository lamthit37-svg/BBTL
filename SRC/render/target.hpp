// Đích vẽ ngoài màn hình: một ảnh màu, một ảnh độ sâu và một buffer đọc ngược. Dùng để chụp khung
// hình ra tệp (capture) và để kiểm thử renderer mà không cần cửa sổ. _Ref chụp màn hình bằng một
// compute shader chép swapchain rồi chờ fence ngay trên luồng vẽ (Screenshot.cpp); ở đây đọc ngược
// là một lệnh chép vào buffer Readback, và nơi gọi tự chọn lúc chờ.
// Vòng dùng: begin, ghi lệnh vẽ, end, nộp danh sách lệnh, chờ GPU, read.
// Nguồn: Forge2 src/render/target.hpp@d7fcd76. Khác gốc: enumerator mang tiền tố k.
#pragma once

#include "capture/frame.hpp"
#include "core/error.hpp"
#include "gpu/device.hpp"

#include <cstdint>
#include <memory>

namespace game::render {

struct TargetDesc {
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    // Rgba8 hoặc Bgra8, thường hay sRGB: bốn định dạng đọc ngược được thành capture::Frame.
    gpu::Format color_format = gpu::Format::kRgba8UnormSrgb;
    gpu::Format depth_format = gpu::Format::kD32Float;
    gpu::ClearColor clear{};
};

class Target {
public:
    // InvalidArgument khi cỡ bằng 0 hoặc định dạng màu không đọc ngược được. Mượn device: Target
    // phải bị huỷ trước nó.
    [[nodiscard]] static core::Result<Target> create(gpu::Device& device, const TargetDesc& desc);

    Target(Target&&) noexcept;
    Target& operator=(Target&&) noexcept;
    Target(const Target&) = delete;
    Target& operator=(const Target&) = delete;
    ~Target();

    [[nodiscard]] const TargetDesc& desc() const noexcept;

    // Đưa hai ảnh về bố cục vẽ rồi mở lượt vẽ, xoá màu về desc().clear và độ sâu về 0 (xa nhất).
    void begin(gpu::CommandList& list);
    // Đóng lượt vẽ rồi chép ảnh màu vào buffer đọc ngược.
    void end(gpu::CommandList& list);

    // Khung hình của lần end gần nhất, hàng 0 trên cùng. Gọi sau khi lần nộp chứa end đã chạy xong
    // (Device::wait_idle hoặc một Timeline); gọi sớm hơn là đọc dữ liệu của khung trước.
    [[nodiscard]] core::Result<capture::Frame> read() const;

private:
    struct State;

    explicit Target(std::unique_ptr<State> state) noexcept;

    std::unique_ptr<State> state_;
};

} // namespace game::render
