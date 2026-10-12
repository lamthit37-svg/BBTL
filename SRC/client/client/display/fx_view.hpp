// Vẽ hạt và effect của cảnh: mô phỏng ở fx/, ảnh PNG theo bảng material của thư viện hiệu ứng, một
// pipeline cộng sáng (shader fx: ảnh nhân màu đỉnh nhân alpha, trộn One + One).
// Hai kiểu trộn của kho gốc đi qua pipeline ấy mà không sai (MaterialTemplates/Particle_ps.hlsl,
// ShaderLib/Diffuse.inc của client 2026): "src_alpha one" dùng nguyên; "one one" không cho alpha
// tham gia, nên alpha của đỉnh và của ảnh được đặt về 1. Hệ số ColorX2, ColorX4 nhân vào màu đỉnh
// đã kẹp trong 0..1, như bản gốc gói màu đỉnh 8 bit rồi shader mới nhân hệ số.
// Thứ pipeline này chưa vẽ đúng (trộn alpha, hai ảnh, hạt mesh, affector lạ) thì fx::Cast không dựng
// từ lúc nhận cảnh; adopt ghi một dòng log đếm theo lý do.
// Bộ đệm đỉnh riêng cho từng slot (ảnh swapchain) và lớn dần theo số quad của khung: không có trần
// cắt bớt hạt, và khung đang nằm ở GPU không bị ghi đè.
#pragma once

#include "client/stage/stage.hpp"
#include "fx/field.hpp"
#include "gpu/handle.hpp"
#include "render/camera.hpp"

#include <cstdint>
#include <filesystem>
#include <memory>
#include <vector>

namespace game::gpu {
class CommandList;
class Device;
} // namespace game::gpu

namespace game::client {

class FxView {
public:
    FxView(const FxView&) = delete;
    FxView& operator=(const FxView&) = delete;
    FxView(FxView&&) noexcept;
    FxView& operator=(FxView&&) noexcept;
    ~FxView();

    // nullptr kèm một dòng log khi pipeline rỗng. Handle thuộc Catalog, FxView không huỷ nó.
    [[nodiscard]] static std::unique_ptr<FxView> open(gpu::Device& device, gpu::PipelineHandle pipeline);

    // Nạp thư viện hiệu ứng của thư mục dữ liệu: effect/all.particle, all.effect, materials.tsv. Gọi
    // một lần sau open. Thiếu tệp thì ghi một dòng log và bộ vẽ không vẽ gì.
    void load(const std::filesystem::path& data_root);
    // Nhận cảnh mới: bỏ hiệu ứng của cảnh cũ rồi dựng hiệu ứng của stage.
    void adopt(const Stage& stage);
    // Bước mô phỏng. Gọi trước lượt vẽ model để hạt mesh kịp vào cùng pass.
    void advance(float seconds);
    [[nodiscard]] std::vector<const fx::Field*> fields() const;
    void draw(gpu::CommandList& list, std::uint32_t slot, const render::Camera& camera);

private:
    struct Body;
    explicit FxView(std::unique_ptr<Body> body);
    std::unique_ptr<Body> body_;
};

} // namespace game::client
