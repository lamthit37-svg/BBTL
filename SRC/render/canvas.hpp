// Đích vẽ ngoài màn hình mà shader lấy mẫu lại được: một ảnh màu một mẫu, một ảnh độ sâu, và khi
// đa mẫu thì thêm ảnh màu đa mẫu được resolve xuống ảnh màu lúc kết thúc lượt vẽ. Dùng cho mô hình
// 3D hiện trong giao diện (đầu nhân vật ở ô chân dung, như render texture của fake object trong
// client gốc): vẽ vào Canvas trước lượt vẽ màn hình, rồi lượt giao diện lấy mẫu color_view.
// Khác render::Target (đích chụp hình): không đọc ngược về CPU; cùng số mẫu với pipeline sẽ vẽ vào.
// Vòng dùng mỗi khung: begin, ghi lệnh vẽ, end; sau end ảnh màu ở bố cục ShaderRead.
// Nguồn: bản mới của dự án, theo mẫu render/target.cpp và render/screen.cpp.
#pragma once

#include "core/error.hpp"
#include "gpu/command.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "gpu/types.hpp"

#include <cstdint>
#include <memory>

namespace game::render {

struct CanvasDesc {
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    gpu::Format color_format = gpu::Format::kRgba8UnormSrgb;
    gpu::Format depth_format = gpu::Format::kD32Float;
    // Số mẫu của lượt vẽ; phải trùng số mẫu của pipeline vẽ vào đây. 1 là không khử răng cưa.
    std::uint32_t samples = 1;
    // Màu xoá đầu mỗi lượt; mặc định trong suốt để phần không có hình không che giao diện.
    gpu::ClearColor clear{.red = 0.0F, .green = 0.0F, .blue = 0.0F, .alpha = 0.0F};
};

class Canvas {
public:
    // InvalidArgument khi cỡ hay số mẫu bằng 0. Mượn device: Canvas phải bị huỷ trước nó.
    [[nodiscard]] static core::Result<Canvas> create(gpu::Device& device, const CanvasDesc& desc);

    Canvas(Canvas&&) noexcept;
    Canvas& operator=(Canvas&&) noexcept;
    Canvas(const Canvas&) = delete;
    Canvas& operator=(const Canvas&) = delete;
    ~Canvas();

    [[nodiscard]] const CanvasDesc& desc() const noexcept;
    // Ảnh màu một mẫu để gắn vào bind group; nội dung là của lần end gần nhất.
    [[nodiscard]] gpu::TextureViewHandle color_view() const noexcept;
    // true khi hàng đầu của ảnh màu là hàng DƯỚI cùng của hình đã vẽ (OpenGL: gốc toạ độ của
    // framebuffer ở dưới trái). Nơi lấy mẫu phải lật trục v thì hình mới đứng đúng chiều.
    [[nodiscard]] bool is_bottom_up() const noexcept;

    // Đưa các ảnh về bố cục vẽ rồi mở lượt vẽ, xoá màu về desc().clear và độ sâu về 0 (xa nhất).
    void begin(gpu::CommandList& list);
    // Đóng lượt vẽ (resolve nếu đa mẫu) rồi đưa ảnh màu về bố cục cho shader lấy mẫu.
    void end(gpu::CommandList& list);

private:
    struct State;

    explicit Canvas(std::unique_ptr<State> state) noexcept;

    std::unique_ptr<State> state_;
};

} // namespace game::render
