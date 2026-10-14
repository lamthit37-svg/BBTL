#pragma once
// Clip của một nhân vật theo trạng thái, port từ client ref (Obj_Character_Logic.cpp), chung cho
// người chơi và NPC. Đi là clip chạy, lặp (CHARACTER_LOGIC_MOVE, BASE_ACTION_N_RUN). Dừng thì
// Start_Idle: phát clip đứng một lần, ghi mốc động tác nghỉ là lúc đó và rút khoảng
// CalcIdleRandInterval. Hết clip thì FreshAnimation: quá mốc cộng khoảng thì dời mốc, rút khoảng
// mới rồi rand() % 2 + BASE_ACTION_N_IDLE_EX0 chọn một trong hai động tác nghỉ, không thì phát lại
// clip đứng. Động tác không có clip thì phát clip đứng (ref về tư thế bind). Khoảng là
// GetIdleInterval của đối tượng. Logic thuần, không I/O; mỗi nhân vật một Gait.
// Nhảy theo CObject_Character::Jump và NotifyPhyEvent của ref, đối chiếu Game.exe 2026 (0x1405ea2b0,
// ChangeAction 0x1405e2740): ChangeAction(N_JUMP_N hay N_JUMP_R, 1.f, FALSE) phát clip nhảy một lần từ
// đầu, cờ nhảy bật. Lúc cờ bật, Start_Idle và Start_Move đổi logic nhưng không đổi clip. Hết clip nhảy
// mà chưa chạm đất thì OnAnimationEnd gọi FreshAnimation: logic MOVE thì chạy lại từ đầu, IDLE thì như
// lúc hết clip đứng. Chạm đất (PE_COLLISION_WITH_GROUND) thì tắt cờ rồi FreshAnimation một lần nữa.
// Hành động không có clip thì ChangeAction của gốc bỏ qua: clip đang phát giữ nguyên.
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
    // BASE_ACTION_N_JUMP_N và N_JUMP_R.
    std::optional<float> jump_stand;
    std::optional<float> jump_run;
};

enum class Stance : std::uint8_t { kIdle = 1, kIdleAlt, kIdleAlt2, kRun, kJumpStand, kJumpRun };

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
    // CObject_Character::Jump lúc now: stance là kJumpStand hay kJumpRun; stance khác thì không làm gì.
    void jump(core::Clock::time_point now, Stance stance, const ClipLengths& lengths);
    // Chạm đất lúc now: hết nhảy rồi FreshAnimation. Không đang nhảy thì không làm gì.
    void land(core::Clock::time_point now, const ClipLengths& lengths);
    [[nodiscard]] bool is_jumping() const noexcept { return is_jumping_; }
    // Phát stance ở khung kế, rồi về đứng. Dùng cho bài múa lúc người mẫu môn phái hiện.
    void cue(Stance stance) noexcept;
    // Sai thì hết bài không chọn động tác nghỉ. Mười hai môn đầu vẫn nghỉ bằng bài múa.
    void set_fidget(bool enabled) noexcept;

private:
    void enter(core::Clock::time_point now, bool is_moving);
    void take_cue(core::Clock::time_point now);
    [[nodiscard]] Playing running(core::Clock::time_point now, const ClipLengths& lengths) const;
    void start_idle(core::Clock::time_point now);
    void fresh(core::Clock::time_point now, const ClipLengths& lengths);
    void fresh_logic(core::Clock::time_point now, const ClipLengths& lengths);
    [[nodiscard]] float elapsed(core::Clock::time_point now) const;
    [[nodiscard]] static float length_of(Stance stance, const ClipLengths& lengths);

    // minstd_rand với kiểu kết quả đúng 32 bit trên mọi nền, nên cùng dãy số ở mọi trình dịch.
    std::linear_congruential_engine<std::uint32_t, 48271U, 0U, 2147483647U> random_;
    std::chrono::milliseconds idle_ms_;
    // Sai trước lần update đầu: lúc đó chưa có clip nào.
    bool is_started_ = false;
    bool fidget_ = true;
    // Logic MOVE (đang đi) và m_bJumping của ref; clip đang phát là stance_.
    bool is_moving_ = false;
    bool is_jumping_ = false;
    std::optional<Stance> cued_;
    Stance stance_ = Stance::kIdle;
    core::Clock::time_point clip_started_;
    core::Clock::time_point last_motion_;
    std::chrono::milliseconds interval_{};
};

} // namespace game::avatar
