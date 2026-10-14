// Vẽ hạt và effect của cảnh: mô phỏng ở fx/, ảnh PNG theo bảng material của thư viện hiệu ứng.
// Pipeline cộng sáng (One + One) cho "one one" và "src_alpha one". Pipeline trộn alpha
// (src_alpha, one_minus_src_alpha) cho sương trời và bọt suối. Cùng shader fx; mode.x của push
// chọn công thức. "one one" không cho alpha tham gia nên alpha đỉnh và ảnh đặt về 1.
// Billboad hai ảnh, cuộn UV và affector lạ thì fx::Cast không dựng. Hạt mesh trộn alpha thì nhận
// và Display tô mesh bằng material hạt. adopt đếm lý do phần còn bỏ.
// Bộ đệm đỉnh riêng cho từng slot (ảnh swapchain) và lớn dần theo số quad của khung: không có trần
// cắt bớt hạt, và khung đang nằm ở GPU không bị ghi đè.
#pragma once

#include "client/stage/stage.hpp"
#include "fx/cast.hpp"
#include "fx/field.hpp"
#include "gpu/handle.hpp"
#include "render/camera.hpp"

#include <cstdint>
#include <filesystem>
#include <memory>
#include <string_view>
#include <vector>

namespace game::fx {
struct Paint;
}

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

    // nullptr kèm một dòng log khi pipeline cộng sáng rỗng. blend rỗng thì bỏ lô trộn alpha.
    // Handle thuộc Catalog, FxView không huỷ nó.
    [[nodiscard]] static std::unique_ptr<FxView> open(gpu::Device& device, gpu::PipelineHandle pipeline,
        gpu::PipelineHandle blend);

    // Nạp thư viện hiệu ứng của thư mục dữ liệu: effect/all.particle, all.effect, materials.tsv. Gọi
    // một lần sau open. Thiếu tệp thì ghi một dòng log và bộ vẽ không vẽ gì.
    void load(const std::filesystem::path& data_root);
    // Nhận cảnh mới: bỏ hiệu ứng của cảnh cũ rồi dựng hiệu ứng của stage.
    void adopt(const Stage& stage);
    // Dựng thêm một hệ hạt hay effect giữa cảnh (hiệu ứng đòn đánh, hiệu ứng đồ của người chơi); thứ chưa vẽ đúng được
    // thì bị bỏ và đếm như lúc adopt. Trả handle (khác 0) khi spawn.is_tracked và dựng được. Gọi từ luồng vẽ.
    std::uint32_t spawn(const fx::Spawn& spawn);
    // Dời hay dừng hiệu ứng theo dõi (fx::Cast::move, release).
    void move(std::uint32_t handle, const fx::Node& node);
    void release(std::uint32_t handle);
    // Hiệu ứng theo dõi còn chạy (fx::Cast::is_live); cảnh mới (adopt) làm mọi handle hết sống.
    [[nodiscard]] bool is_live(std::uint32_t handle) const;
    // Bước mô phỏng. Gọi trước lượt vẽ model để hạt mesh kịp vào cùng pass.
    void advance(float seconds);
    [[nodiscard]] std::vector<const fx::Field*> fields() const;
    // nullptr khi thư viện chưa nạp hoặc bảng không có tên. Con trỏ sống cùng thư viện.
    [[nodiscard]] const fx::Paint* paint(std::string_view material) const;
    void draw(gpu::CommandList& list, std::uint32_t slot, const render::Camera& camera);

private:
    struct Body;
    explicit FxView(std::unique_ptr<Body> body);
    std::unique_ptr<Body> body_;
};

} // namespace game::client
