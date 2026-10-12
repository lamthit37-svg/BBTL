// Hệ số khoảng cách, fade, pan và Doppler. Hàm thuần, không chạm thiết bị.
// Rolloff tuyến tính như Loong. min >= max thì đẩy max thêm 1 để không chia cho 0.
#pragma once

namespace game::audio {

struct DistanceSpan {
    float near_distance = 0.F;
    float far_distance = 1.F;
};

struct FadeSpan {
    float elapsed_seconds = 0.F;
    float duration_seconds = 0.F;
};

// Tai nghe. Đơn vị vị trí là cm, vận tốc là cm/s. Hướng mặc định nhìn xuống -Z, lên +Y.
struct Ear {
    float x = 0.F;
    float y = 0.F;
    float z = 0.F;
    float forward_x = 0.F;
    float forward_y = 0.F;
    float forward_z = -1.F;
    float up_x = 0.F;
    float up_y = 1.F;
    float up_z = 0.F;
    float velocity_x = 0.F;
    float velocity_y = 0.F;
    float velocity_z = 0.F;
};

struct Place {
    float x = 0.F;
    float y = 0.F;
    float z = 0.F;
    float velocity_x = 0.F;
    float velocity_y = 0.F;
    float velocity_z = 0.F;
};

struct Stereo {
    float left = 0.F;
    float right = 0.F;
};

// 1 ở gần, 0 ở xa.
[[nodiscard]] float distance_gain(float distance, DistanceSpan span) noexcept;

// Thời lượng 0 nghĩa là vào ngay mức cuối.
[[nodiscard]] float fade_in(FadeSpan span) noexcept;

// Thời lượng 0 nghĩa là tắt ngay.
[[nodiscard]] float fade_out(FadeSpan span) noexcept;

// Pan cân bằng năng lượng theo hướng phải của tai.
[[nodiscard]] Stereo pan_of(const Ear& ear, const Place& place) noexcept;

// Tai và nguồn đứng yên thì đúng 1.
[[nodiscard]] float doppler_rate(const Ear& ear, const Place& place) noexcept;

} // namespace game::audio
