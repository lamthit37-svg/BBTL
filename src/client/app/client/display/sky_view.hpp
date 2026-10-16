/*==============================================================================
 *  THIENLONG  |  BẦU TRỜI ENSCENE
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/sky_view.hpp
 *  PHÂN HỆ   : Client / Display
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Vẽ bầu trời .EnScene của Render.dll: vòm trước thế giới (nhóm hàng đợi 5), sao
 *    (nhóm 57), lớp mây, mây vòng, trăng và mặt trời sau hiệu ứng (nhóm 59). Mô phỏng nằm ở
 *    ensky/; ở đây chỉ nạp ảnh và mesh, gói lệnh vẽ vào một cbuffer cho cả khung
 *    (mỗi slot swapchain một buffer) và ghi lệnh.
 *  - Ảnh nạp thô (không giải mã sRGB) vì shader tính trong không gian gamma như
 *    bản gốc. Ảnh hay mesh thiếu thì lớp đó bị bỏ, ghi log một lần.
 *  - Đồng hồ ngày chạy tự do một ngày 60 giây từ 0 như màn đăng nhập của Game.exe;
 *    pin_day đặt cố định cho các thủ tục khác.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon          TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "client/stage/stage.hpp"
#include "ensky/scene.hpp"
#include "gpu/handle.hpp"
#include "render/camera.hpp"
#include "resource/tier.hpp"

#include <cstdint>
#include <filesystem>
#include <memory>
#include <optional>
#include <span>
#include <string>

namespace game::gpu {
class CommandList;
class Device;
} // namespace game::gpu

namespace game::client {

// PSO của bầu trời (render::Pso::kSkyDome, kSkyCloud, kSkyBody, kSkyStar); handle thuộc
// Catalog. Sao là tuỳ chọn: thiếu thì cảnh vẫn có trời, chỉ không có sao.
struct SkyPipelines {
    gpu::PipelineHandle dome{};
    gpu::PipelineHandle cloud{};
    gpu::PipelineHandle body{};
    gpu::PipelineHandle star{};
};

class SkyView {
public:
    SkyView(const SkyView&) = delete;
    SkyView& operator=(const SkyView&) = delete;
    SkyView(SkyView&&) noexcept;
    SkyView& operator=(SkyView&&) noexcept;
    ~SkyView();

    // nullptr khi thiếu một trong ba pipeline.
    [[nodiscard]] static std::unique_ptr<SkyView> open(gpu::Device& device,
        const SkyPipelines& pipelines);

    // Thư mục dữ liệu (Material/, Model/, Scene/) và bản ảnh của thiết bị. Gọi một lần sau open.
    void load(const std::filesystem::path& data_root, resource::TextureTier tier);
    // Nhận cảnh mới: đọc Scene/<stage.en_scene>. Không có tệp thì không vẽ gì. Trả bảng EnvKey đã
    // nội suy theo giờ đầu tiên; false khi cảnh không có bầu trời EnScene.
    bool adopt(const Stage& stage);
    // Đồng hồ ngày. pin_day dừng ở phần ngày này; run_day cho chạy tự do từ giá trị hiện có.
    void pin_day(float fraction);
    void run_day();
    [[nodiscard]] float day_fraction() const;
    // Bước mô phỏng của khung: đồng hồ, mây trôi, mây vòng xoay, hướng trăng và mặt trời.
    void advance(float seconds);
    [[nodiscard]] bool has_sky() const;
    // Môi trường (EnvKey) tại giờ hiện tại; nullopt khi cảnh không có bầu trời hay không khai
    // EnvKey.
    [[nodiscard]] std::optional<ensky::EnvKey> env() const;
    // Đổi mỗi lần môi trường tính lại (TimeNode đổi hơn 0,01 giờ); 0 khi chưa có. Dùng để dựng
    // lại ánh sáng.
    [[nodiscard]] std::uint32_t env_serial() const;
    // Tên effect của khối Effects của EnSky: Render.dll gắn chúng vào nút en_effect, mỗi khung
    // đặt tại camera (0x1801e7d50, 0x1801ea1xx), hướng đơn vị. Bên ngoài tạo hiệu ứng và dời
    // theo camera.
    [[nodiscard]] std::span<const std::string> effects() const;

    // Gói lệnh vẽ của khung vào cbuffer của slot. Gọi một lần mỗi khung, trước draw_dome.
    void prepare(std::uint32_t slot, const render::Camera& camera);
    // Vòm: trước thế giới. Sau prepare.
    void draw_dome(gpu::CommandList& list, std::uint32_t slot);
    // Sao rồi mây, mây vòng, trăng, mặt trời: sau thế giới và hiệu ứng. Sau prepare.
    void draw_layers(gpu::CommandList& list, std::uint32_t slot);

private:
    struct Body;
    explicit SkyView(std::unique_ptr<Body> body);
    std::unique_ptr<Body> body_;
};

} // namespace game::client
