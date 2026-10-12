// Bầu trời .skysphere của cảnh: lớp đang dùng của thời tiết hiện tại và bảng môi trường theo giờ
// (SkyEnviromentList) của thời tiết ấy. Mặt trăng, sao và nắng chỉ vẽ khi SkyEffectParams bật;
// huoyangu để cả bốn tắt.
// Bảng môi trường đọc theo client 2026 (Render.dll: đọc EnvKey ở 0xEA430, nội suy ở 0xF1E50, áp
// vào cảnh ở 0xF4260): khi cảnh có bầu trời, ambient, màu và tầm sương, màu hai đèn chính và ánh
// sáng riêng của nhân vật lấy từ bảng này theo giờ, đè lên số ghi trong tệp cảnh.
#pragma once

#include "client/stage/stage.hpp"

#include <cstdint>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::client {

// Một dải trên vòm. pitch 0 là đỉnh, pi/2 là chân trời. repeats là số lần texture quấn quanh.
struct SkyBand {
    std::string texture;
    float pitch_start = 0.0F;
    float pitch_end = 0.0F;
    int repeats = 1;
    bool blends = false;
};

struct SkyDome {
    std::vector<SkyBand> bands;
    // Xếp theo time tăng dần. Rỗng khi thời tiết hiện tại không khai mốc nào.
    std::vector<DayKey> days;
};

struct SkyVertex {
    float x = 0.0F;
    float y = 0.0F;
    float z = 0.0F;
    float u = 0.0F;
    float v = 0.0F;
};

// Vòm đơn vị. Display đặt tâm vào mắt camera và phóng vừa trong gần–xa.
struct SkyMesh {
    std::vector<SkyVertex> vertices;
    std::vector<std::uint32_t> indices;
};

// Rỗng khi XML hỏng hoặc thời tiết không có lớp nào có texture.
[[nodiscard]] SkyDome read_sky(std::string_view text);

// Dải trên hình cầu đơn vị. Rỗng khi pitch không có bề rộng.
[[nodiscard]] SkyMesh sky_band(const SkyBand& band);

// Môi trường tại thời điểm time (phần của ngày): nội suy thẳng giữa hai mốc kề, mốc cuối nối vòng
// về mốc đầu qua nửa đêm. days phải khác rỗng và đã xếp theo time.
[[nodiscard]] DayKey day_at(std::span<const DayKey> days, float time) noexcept;

} // namespace game::client
