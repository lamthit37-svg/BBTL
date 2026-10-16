/*==============================================================================
 *  THIENLONG  |  BẦU TRỜI ENSCENE
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/place/ensky/sky.hpp
 *  PHÂN HỆ   : Place / Ensky
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Mô phỏng bầu trời theo từng khung: đồng hồ ngày, nội suy TimeNode tuần
 *    hoàn 24 giờ, mây trôi, mây vòng xoay, hướng trăng và mặt trời, EnvKey.
 *    Không đụng GPU: lớp vẽ đọc kết quả ở đây.
 *  - Đồng hồ ngày chạy tự do một ngày 60 giây từ 0 (Render.dll 0x1800ddf40);
 *    Game.exe dừng và đặt phần ngày bằng +0x350 (xem docs/TAILIEU).
 *  - TimeNode chỉ tính lại khi giờ lệch quá 0,01 so với lần tính trước, như bản
 *    gốc (hằng ở 0x1802c757c).
 *  - Nguồn: Render.dll 2026. Khác gốc: không có Ogre nên nút cảnh là quaternion
 *    và vị trí, giữ nguyên thứ tự nhân của Node::rotate(TS_LOCAL).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon          TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "ensky/scene.hpp"
#include "ensky/star.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"

#include <cstdint>
#include <span>
#include <vector>

namespace game::ensky {

// Một ngày của trò chơi chạy hết trong chừng này giây thật.
inline constexpr float kDaySeconds = 60.0F;
// Giờ lớn nhất mà bản gốc cho phép (24 giờ sẽ quấn về 0 và làm nội suy nhảy).
inline constexpr float kLastHour = 23.999F;
// TimeNode chỉ tính lại khi giờ đổi hơn mức này.
inline constexpr float kHourStep = 0.01F;
// Khoảng cách của vật con tới nút gốc của trăng và mặt trời; chỉ hướng được dùng.
inline constexpr float kBodyDistance = 9000.0F;

class DayClock {
public:
    void advance(float seconds) noexcept;
    // Dừng đồng hồ ở phần ngày này (0..1), như +0x350 của đối tượng engine.
    void pin(float fraction) noexcept;
    void run() noexcept { is_pinned_ = false; }
    [[nodiscard]] float fraction() const noexcept { return fraction_; }
    [[nodiscard]] bool is_pinned() const noexcept { return is_pinned_; }
    // fraction * 24, kẹp ở kLastHour.
    [[nodiscard]] float hour() const noexcept;

private:
    float fraction_ = 0.0F;
    bool is_pinned_ = false;
};

// Pha của trăng hay mặt trời trong ngày, đơn vị vòng quay (p * 360 độ). Trăng dùng
// (start = down_time, end = up_time), mặt trời dùng (start = up_time, end = down_time).
[[nodiscard]] float phase_of(float hour, float start, float end) noexcept;

struct Pose {
    ogre::Quat orientation;
    // Hướng tới vật, vector đơn vị.
    ogre::Vec3 toward;
};

[[nodiscard]] Pose moon_pose(const Moon& moon, float hour) noexcept;
[[nodiscard]] Pose sun_pose(const Sun& sun, float hour) noexcept;

// Nội suy EnvKey tuần hoàn. keys phải xếp theo time và khác rỗng.
[[nodiscard]] EnvKey env_at(std::span<const EnvKey> keys, float hour) noexcept;

struct CloudLive {
    float fog = 0.0F;
    float alpha = 0.0F;
    float speed = 0.0F;
    float ambient_blend = 0.0F;
    // Tích luỹ cloudspeed * dt * 0,1: cuộn V của ảnh mây.
    float wind = 0.0F;
};

struct RingLive {
    float fog_blend = 0.0F;
    float ambient_blend = 0.0F;
    float alpha = 0.0F;
    float fade_range = 0.0F;
    float roll_speed = 0.0F;
    float vertical_speed = 0.0F;
    // Cuộn V của ảnh mây, quấn trong [-1, 1].
    float v_offset = 0.0F;
    // Hướng của nút (yaw, rồi roll PI khi lật), giữ qua các khung vì mây xoay là cộng dồn.
    ogre::Quat orientation;
    // Trạng thái lật đã áp lên orientation.
    bool is_flipped = false;
};

// Một khung: seconds là thời gian trôi, hour lấy từ DayClock.
struct Tick {
    float seconds = 0.0F;
    float hour = 0.0F;
};

// Trạng thái động của một Sky. Sky phải sống lâu hơn Playback.
class Playback {
public:
    explicit Playback(const Sky& sky);

    void update(Tick tick);

    [[nodiscard]] const Sky& sky() const noexcept { return *sky_; }
    [[nodiscard]] float hour() const noexcept { return hour_; }
    [[nodiscard]] std::span<const CloudLive> clouds() const noexcept { return clouds_; }
    [[nodiscard]] std::span<const RingLive> rings() const noexcept { return rings_; }
    [[nodiscard]] const Pose& moon() const noexcept { return moon_; }
    [[nodiscard]] const Pose& sun() const noexcept { return sun_; }
    [[nodiscard]] const StarField& star() const noexcept { return star_; }
    // Môi trường tại giờ hiện tại; mặc định khi Sky không có EnvKey.
    [[nodiscard]] const EnvKey& env() const noexcept { return env_; }
    [[nodiscard]] bool has_env() const noexcept { return !sky_->env.empty(); }
    // Số lần TimeNode đã tính lại (retime): đổi khi env() hay trạng thái mây có thể đã đổi.
    [[nodiscard]] std::uint32_t retimes() const noexcept { return retimes_; }

private:
    void retime(float hour);
    void turn_rings(float seconds);

    const Sky* sky_;
    std::vector<CloudLive> clouds_;
    std::vector<RingLive> rings_;
    Pose moon_;
    Pose sun_;
    StarField star_;
    EnvKey env_;
    float hour_ = 0.0F;
    std::uint32_t retimes_ = 0;
    float timed_hour_ = -1.0e9F;
};

} // namespace game::ensky
