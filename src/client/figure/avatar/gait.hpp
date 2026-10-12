#pragma once
// Clip của một nhân vật theo trạng thái, port từ client ref (Obj_Character_Logic.cpp), chung cho
// người chơi và NPC. Đi là clip chạy, lặp (CHARACTER_LOGIC_MOVE, BASE_ACTION_N_RUN). Dừng thì
// Start_Idle: phát clip đứng một lần, ghi mốc động tác nghỉ là lúc đó và rút khoảng
// CalcIdleRandInterval. Hết clip thì FreshAnimation: quá mốc cộng khoảng thì dời mốc, rút khoảng
// mới rồi rand() % 2 + BASE_ACTION_N_IDLE_EX0 chọn một trong hai động tác nghỉ, không thì phát lại
// clip đứng. Động tác không có clip thì phát clip đứng (ref về tư thế bind). Khoảng là
// GetIdleInterval của đối tượng. Logic thuần, không I/O; mỗi nhân vật một Gait.
// Nguồn: TLBB Dev src/client_app/gait.hpp@e0d89a6. Khác gốc: namespace game::avatar; đồng hồ là
// core::Clock; enumerator mang tiền tố k.

#include "core/clock.hpp"

#include <chrono>
#include <cstdint>
#include <optional>
#include <random>

namespace game::avatar {

// CharRace.nIdleInterval × 1000 của người chơi (CObject_PlayerOther::GetIdleInterval); NPC dùng
// khoảng riêng của mẫu.
inline constexpr std::chrono::milliseconds kIdleInterval{10000};

// CalcIdleRandInterval với roll là giá trị rand(): interval × (64 − roll % 16) / 64 tính bằng
// float, cắt phần lẻ như (UINT) của ref.
[[nodiscard]] std::chrono::milliseconds idle_interval(unsigned roll, std::chrono::milliseconds interval);

// Độ dài clip, giây; động tác nghỉ không có clip thì nhánh đó phát clip đứng.
struct ClipLengths {
    float idle = 0.0F;
    // N_IDLE_EX0
    std::optional<float> idle_alt;
    // N_IDLE_EX1
    std::optional<float> idle_alt2;
    float run = 0.0F;
};

enum class Stance : std::uint8_t { kIdle = 1, kIdleAlt, kIdleAlt2, kRun };

// Clip đang phát và thời điểm trong clip, giây, trong [0, độ dài).
struct Playing {
    Stance stance = Stance::kIdle;
    float time = 0.0F;
};

class Gait {
public:
    // seed cho rand() của riêng nhân vật này, để hai người đứng cạnh nhau không nghỉ cùng lúc;
    // interval là GetIdleInterval của nó.
    Gait(std::uint32_t seed, std::chrono::milliseconds interval);

    // Clip lúc now khi đang đi hay đứng. now không được lùi.
    [[nodiscard]] Playing update(core::Clock::time_point now, bool is_moving, const ClipLengths& lengths);

private:
    void enter(core::Clock::time_point now, bool is_moving);
    [[nodiscard]] Playing running(core::Clock::time_point now, const ClipLengths& lengths) const;
    void start_idle(core::Clock::time_point now);
    void fresh(core::Clock::time_point now, const ClipLengths& lengths);
    [[nodiscard]] float elapsed(core::Clock::time_point now) const;
    [[nodiscard]] static float length_of(Stance stance, const ClipLengths& lengths);

    // minstd_rand với kiểu kết quả đúng 32 bit trên mọi nền, nên cùng dãy số ở mọi trình dịch.
    std::linear_congruential_engine<std::uint32_t, 48271U, 0U, 2147483647U> random_;
    std::chrono::milliseconds idle_ms_;
    // Sai trước lần update đầu: lúc đó chưa có clip nào.
    bool is_started_ = false;
    Stance stance_ = Stance::kIdle;
    core::Clock::time_point clip_started_;
    core::Clock::time_point last_motion_;
    std::chrono::milliseconds interval_{};
};

} // namespace game::avatar
