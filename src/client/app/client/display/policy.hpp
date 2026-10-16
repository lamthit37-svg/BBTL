// Chính sách đồ hoạ: mọi khác biệt giữa PC và điện thoại trên đường vẽ chỉ là giá trị ở đây, không phải mã rẽ nhánh. Mã vẽ
// đọc chính sách rồi chạy một đường duy nhất, nên PC chạy được đúng chính sách của điện thoại (--quality mobile) để chụp,
// so ảnh và đo mà không cần máy thật. Chỗ duy nhất hỏi nền tảng là default_quality.
// Thứ phần cứng tự khai (cỡ texture tối đa, định dạng nén được hỗ trợ, màu thô của GLES) thì hỏi thiết bị lúc chạy, không
// ghi ở đây. Mỗi số của mobile là số đã đo trên tablet Lenovo TB-X306F (PowerVR GE8320); đổi số là đổi hình hay nhịp khung.
#pragma once

#include "resource/tier.hpp"
#include "ui/phone.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string_view>

namespace game::client {

enum class QualityClass : std::uint8_t { kDesktop, kMobile };

struct GraphicsPolicy {
    // Số mẫu khử răng cưa. 4 trên PC: cảnh đá chi tiết quay chậm mà không có nó thì cạnh và hoạ tiết lăn tăn từng khung.
    // Đo 2026-10-16 trên tablet GE8320 Vulkan (cảnh đăng nhập 1280x800): 4 mẫu đẩy khung từ 33,3 ms lên 40 ms.
    std::uint32_t samples = 4;
    // Màu thô như GLES: bỏ pow gamma từng điểm ảnh, shader tự mã hoá (DeviceDesc::is_raw_color).
    bool is_raw_color = false;
    // Ánh sáng tính ở đỉnh thay vì ở điểm ảnh, để giữ nhịp khung trên GPU yếu. Backend GLES luôn bật, theo khả năng.
    bool lights_at_vertices = false;
    // Trần tam giác khởi đầu mỗi khung, 0 là không giới hạn. Đo 2026-10-16 trên tablet (cảnh đăng nhập, 1,05 triệu tam giác
    // khi không giới hạn): trần 150 nghìn giữ 30 Hz, trần 200 nghìn đã 40 đến 46 ms một khung.
    std::uint32_t triangle_cap = 0;
    // DetailGovernor chỉnh trần tam giác theo thời gian khung thật (render/detail_governor.hpp). Cần triangle_cap khác 0.
    bool adapts_detail = false;
    // Sinh mức chi tiết thấp cho lưới tĩnh của vật thể cảnh (resource/lod.hpp), để trần tam giác có mức mà chọn.
    bool builds_lods = false;
    // Cạnh lớn nhất của texture vật thể, 0 là giữ cỡ gốc. Đo 2026-10-15 trên tablet, cảnh erengu_DL: 136 texture ASTC
    // 1024x1024 chiếm 181 trong 313 MB và máy 2 GB bị lmkd giết; 512 bằng một phần tư số byte.
    std::uint32_t texture_edge = 0;
    // Trần byte của mesh đã đọc mà luồng vẽ chưa lấy. Đo 2026-10-15: 170 mesh cùng giữ bản nướng là 830 MB anon sau 2,3 giây.
    std::size_t pending_bytes = std::size_t{1} << 30U;
    // Mặt đất xong là vẽ khung đầu, mesh vào dần. Đo 2026-10-15: tablet mất hơn 10 giây đặt 170 mesh, suốt lúc đó màn trắng.
    bool shows_first_frame_early = false;
    // Trần nhịp khung tự chỉnh theo sức máy (core/governor.hpp) thay vì khoá theo nhịp quét: màn 120 Hz không bảo đảm máy
    // vẽ nổi 120 khung.
    bool adapts_rate = false;
    // Loại texture nén biết trước khi có thiết bị, để việc đọc đĩa chạy song song với lúc tạo thiết bị. Rỗng thì hỏi thiết
    // bị: ASTC nếu đọc được, không thì ETC2.
    std::optional<resource::TextureTier> fixed_tier = resource::TextureTier::kBc;
};

[[nodiscard]] constexpr GraphicsPolicy policy_of(QualityClass quality) noexcept {
    GraphicsPolicy policy;
    if (quality == QualityClass::kDesktop) return policy;
    policy.samples = 1;
    policy.is_raw_color = true;
    policy.lights_at_vertices = true;
    policy.triangle_cap = 150'000;
    policy.adapts_detail = true;
    policy.builds_lods = true;
    policy.texture_edge = 512;
    policy.pending_bytes = std::size_t{96} << 20U;
    policy.shows_first_frame_early = true;
    policy.adapts_rate = true;
    policy.fixed_tier = std::nullopt;
    return policy;
}

// Hạng máy mặc định của bản dựng: chỗ duy nhất của đường vẽ hỏi nền tảng.
[[nodiscard]] constexpr QualityClass default_quality() noexcept {
    return ui::kPhone ? QualityClass::kMobile : QualityClass::kDesktop;
}

// Tên dùng ở --quality và thuộc tính debug.thienlong.quality; tên lạ là rỗng.
[[nodiscard]] constexpr std::optional<QualityClass> quality_class_of(std::string_view name) noexcept {
    if (name == "desktop") return QualityClass::kDesktop;
    if (name == "mobile") return QualityClass::kMobile;
    return std::nullopt;
}

[[nodiscard]] constexpr std::string_view quality_name(QualityClass quality) noexcept {
    switch (quality) {
    case QualityClass::kDesktop: return "desktop";
    case QualityClass::kMobile: return "mobile";
    }
    return "desktop";
}

} // namespace game::client
