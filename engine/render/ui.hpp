// Lượt vẽ 2D của giao diện: các quad có ảnh (do gui::Hub ra, bộ vẽ chữ ghép thêm) đã gom thành lô
// theo texture, vẽ bằng một pipeline trộn alpha không độ sâu. Đỉnh của cả khung nằm trong một
// buffer Upload chia theo slot (cùng quy ước với Forward: slot là chỉ số ảnh swapchain vừa
// acquire), chỉ số quad cố định dùng chung. Texture là ảnh RGBA8 đã giải mã, tải lên bằng
// resource::upload_queued ở dạng sRGB; màu đỉnh sRGB của CEGUI được shader đổi sang tuyến tính
// (ui.vs.slang) nên pha màu cho cùng kết quả với client gốc chạy trong không gian gamma, trừ chỗ
// trộn alpha (client gốc trộn trong gamma, ở đây trộn tuyến tính).
// Nguồn shader ở src/client/render/shaders, dịch lúc build thành gói ui.vs.f2s và
// ui.ps.f2s cho mọi backend (Vulkan, D3D12, D3D11, GLES).
// Nguồn: bản mới của dự án, theo mẫu render/forward (gói shader, nhóm gắn, slot); tương ứng
// ui_painter.cpp của TLBB Dev (bgfx).
#pragma once

#include "core/error.hpp"
#include "gpu/device.hpp"
#include "gpu/handle.hpp"
#include "resource/image.hpp"

#include <cstdint>
#include <memory>
#include <span>
#include <string>

namespace game::render {

// Một đỉnh của quad giao diện: toạ độ điểm ảnh của vùng vẽ (gốc trái trên), toạ độ ảnh 0..1, màu
// ARGB thẳng đóng trong một số 32 bit (byte cao là alpha).
struct UiVertex {
    float x = 0.0F;
    float y = 0.0F;
    float u = 0.0F;
    float v = 0.0F;
    std::uint32_t colour = 0xFFFFFFFFU;
};
static_assert(sizeof(UiVertex) == 20);

// Texture số 0 luôn là một điểm ảnh trắng, cho quad màu đặc.
inline constexpr std::uint32_t kUiWhite = 0;

// Hình chữ nhật theo điểm ảnh của vùng vẽ, gốc trái trên.
struct UiRect {
    float x = 0.0F;
    float y = 0.0F;
    float width = 1.0F;
    float height = 1.0F;
};

// Một lô quad liền nhau cùng texture và cùng mặt nạ. Quad n của UiDraw::vertices ứng với đỉnh 4n
// tới 4n + 3, theo thứ tự trên trái, trên phải, dưới phải, dưới trái.
struct UiBatch {
    std::uint32_t texture = kUiWhite;
    std::uint32_t first_quad = 0;
    std::uint32_t quad_count = 0;
    // Mặt nạ của lô, như MaskImage của client 2026: cả texture mask phủ kín ô mask_box, mỗi điểm
    // ảnh của quad ra rgb = c.rgb * m.a + m.rgb * (1 - m.a), a = c.a * m.a (c là màu của quad, m là
    // mặt nạ tại điểm đó). kUiWhite là không mặt nạ. Ô có cạnh không dương thì lô không vẽ.
    std::uint32_t mask = kUiWhite;
    UiRect mask_box{};
};

struct UiDesc {
    // Định dạng của đích vẽ; phải trùng định dạng của begin_rendering sẽ gọi draw.
    gpu::Format color_format = gpu::Format::kRgba8UnormSrgb;
    gpu::Format depth_format = gpu::Format::kD32Float;
    // Số bộ buffer mỗi khung: số ảnh của swapchain.
    std::uint32_t slots = 1;
    std::uint32_t samples = 1;
    // Thư mục chứa ui.vs.f2s và ui.ps.f2s; rỗng thì lấy thư mục shaders cạnh exe.
    std::string shader_dir;
};

// Cỡ vùng vẽ theo điểm ảnh.
struct UiScreen {
    float width = 0.0F;
    float height = 0.0F;
};

struct UiDraw {
    // Danh sách lệnh đang ghi trong begin_rendering; không rỗng.
    gpu::CommandList* list = nullptr;
    std::uint32_t slot = 0;
    UiScreen screen;
    std::span<const UiVertex> vertices;
    std::span<const UiBatch> batches;
};

class UiPass {
public:
    // pipeline là PSO giao diện của Catalog. UiPass không huỷ nó: Catalog phải sống lâu hơn.
    // InvalidArgument khi handle rỗng. Mượn device: UiPass phải bị huỷ trước device.
    [[nodiscard]] static core::Result<UiPass> create(gpu::Device& device, const UiDesc& desc,
        gpu::PipelineHandle pipeline);

    UiPass(UiPass&&) noexcept;
    UiPass& operator=(UiPass&&) noexcept;
    UiPass(const UiPass&) = delete;
    UiPass& operator=(const UiPass&) = delete;
    ~UiPass();

    // Tải một ảnh RGBA8 lên GPU và trả chỉ số dùng trong UiBatch. Gọi ngoài begin_rendering.
    [[nodiscard]] core::Result<std::uint32_t> add_texture(const resource::Image& image);

    // Đăng ký một ảnh đã nằm trên GPU (ảnh màu của một render::Canvas) làm texture của giao diện
    // và trả chỉ số của nó; lấy mẫu kẹp mép, lọc tuyến tính. view phải sống tới khi UiPass bị huỷ,
    // và phải ở bố cục ShaderRead lúc draw. Gọi ngoài begin_rendering. Ảnh Canvas có nền trong suốt
    // chứa màu đã nhân alpha (pipeline trộn của forward ghi src * a + dst * (1 - a)), nên pixel
    // shader giải nhân trước khi trộn alpha thẳng; ảnh đặc (alpha 1) không đổi.
    [[nodiscard]] core::Result<std::uint32_t> add_view(gpu::TextureViewHandle view);

    // Thay ảnh của texture index (cỡ mới tuỳ ý), cho ảnh đổi lúc chạy như minimap. Gọi ngoài
    // begin_rendering. Ảnh cũ huỷ hoãn nên khung GPU đang vẽ dở vẫn đúng. Chỉ số 0 (điểm trắng),
    // chỉ số chưa cấp hay chỉ số của add_view là lỗi; tải hỏng thì ảnh cũ còn nguyên.
    [[nodiscard]] core::Status replace_texture(std::uint32_t index, const resource::Image& image);

    // Ghi đỉnh của khung vào buffer của slot rồi ghi lệnh vẽ mọi lô. Gọi giữa begin_rendering và
    // end_rendering của đích vẽ đúng định dạng đã khai, một lần mỗi slot mỗi khung, sau các lượt vẽ
    // 3D. Quá kMaxQuads quad trong khung là lỗi.
    [[nodiscard]] core::Status draw(const UiDraw& frame);

    // Số quad tối đa trong một khung.
    [[nodiscard]] static std::uint32_t max_quads() noexcept;

    // Số lô đã vẽ ở lần draw gần nhất (lô bị bỏ vì mặt nạ hỏng không tính).
    [[nodiscard]] std::uint32_t draw_count() const noexcept;

private:
    struct State;

    explicit UiPass(std::unique_ptr<State> state) noexcept;

    std::unique_ptr<State> state_;
};

} // namespace game::render
