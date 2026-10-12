#pragma once
// Cần gạt ảo của máy cảm ứng. Client gốc chỉ có bấm để đi trên PC, nên luật dưới đây là của bản
// viết lại (bộ lọc theo thời gian và độ dời của TLBB Dev), không có trong client 2026:
// - độ gạt theo màn hình, x sang phải, y xuống, độ dài từ 0 tới 1; dưới kStickDeadZone là đứng yên;
// - đẩy lên là đi theo hướng camera nhìn chiếu xuống mặt đất, đẩy sang phải là sang phải của
//   camera;
// - lệnh đi nhắm điểm cách nhân vật kStickReach đơn vị game theo hướng đó. Lệnh đầu ra ngay; sau
//   đó ra lại khi hướng đổi quá kStickTurnDegrees và đã cách lệnh trước kStickGap, hay khi đã qua
//   kStickRepeat và đích dời ít nhất kStickSlide đơn vị, để xoay cần nhanh cũng không ra hàng chục
//   lệnh mỗi giây;
// - nhả cần, hay kéo về vùng chết, sau khi đã ra lệnh đi thì dừng (lệnh Stop).
// Logic thuần: chỗ gọi truyền độ gạt, chỗ đứng, hướng camera và đồng hồ.
// Nguồn: TLBB Dev src/control/stick.hpp và stick.cpp@e0d89a6. Khác gốc: namespace game::control,
// GroundPoint của core, Clock của core; enumerator theo kCamelCase.

#include "core/clock.hpp"
#include "core/ground_point.hpp"

#include <chrono>
#include <cstdint>

namespace game::control {

inline constexpr float kStickDeadZone = 0.2F;
inline constexpr float kStickReach = 4.0F;
inline constexpr float kStickTurnDegrees = 10.0F;
inline constexpr std::chrono::milliseconds kStickGap{100};
inline constexpr std::chrono::milliseconds kStickRepeat{250};
inline constexpr float kStickSlide = 0.5F;

// Độ gạt của cần theo màn hình: x sang phải, y xuống, độ dài từ 0 tới 1.
struct Tilt {
    float x = 0.0F;
    float y = 0.0F;
};

enum class StickOrder : std::uint8_t { kNone, kMove, kStop };

// Việc phải làm sau một khung của cần gạt: target chỉ có nghĩa với kMove.
struct StickStep {
    StickOrder order = StickOrder::kNone;
    core::GroundPoint target;
};

// Hướng đơn vị và đích của một lệnh đi.
struct Aim {
    core::GroundPoint heading;
    core::GroundPoint target;
};

class StickMove {
public:
    using Clock = core::Clock;

    // Gọi mỗi khung khi cần đang giữ. self là chỗ đứng của nhân vật, forward là hướng camera nhìn
    // trên mặt đất theo toạ độ game (không cần độ dài 1; độ dài 0 thì không đi được).
    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters): chữ ký của TLBB Dev (HP-07)
    [[nodiscard]] StickStep hold(core::GroundPoint self, core::GroundPoint forward, Tilt tilt,
        Clock::time_point now) noexcept;
    // Nhả cần: Stop khi cần đã ra lệnh đi.
    [[nodiscard]] StickStep release() noexcept;

    [[nodiscard]] bool is_moving() const noexcept { return is_moving_; }

private:
    [[nodiscard]] bool is_due(const Aim& aim, Clock::time_point now) const noexcept;

    bool is_moving_ = false;
    // Lệnh cuối: hướng đơn vị và đích.
    Aim sent_;
    Clock::time_point sent_at_;
};

} // namespace game::control
