// Sổ nhiệm vụ của người chơi như client 2026 giữ trong CDetailAttrib_Player (Game.exe, đọc từ mã
// máy; docs/NHIEM-VU-VO-CONG-2026.md): 20 ô nhiệm vụ đang giữ (_OWN_MISSION: id nhiệm vụ, id script,
// cờ, 8 tham số) và 4096 bit "đã xong" đánh theo id nhiệm vụ. Máy chủ ghi sổ này bằng gói tin; chưa
// có máy chủ thì sổ rỗng. Giá trị thuần, không I/O: dựng và test được ở mọi preset.
#pragma once

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace game::quest {

// Số ô nhiệm vụ đang giữ (g_nMissionNum của QuestLog.lua, vòng 20 ô của Game.exe).
inline constexpr std::size_t kSlotCount = 20;
// Số tham số của một ô.
inline constexpr std::size_t kParamCount = 8;
// Số từ 32 bit của mảng cờ "đã xong": id nhiệm vụ 0..4095.
inline constexpr std::size_t kDoneWords = 128;
inline constexpr std::int32_t kDoneBits = 32;
// id của ô trống.
inline constexpr std::int32_t kNoMission = -1;

// Một ô nhiệm vụ đang giữ.
struct Slot {
    std::int32_t mission = kNoMission;
    std::int32_t script = kNoMission;
    std::uint8_t flags = 0;
    std::array<std::uint32_t, kParamCount> params{};
};

struct Log {
    std::array<Slot, kSlotCount> slots{};
    std::array<std::uint32_t, kDoneWords> done{};
};

// Nhiệm vụ mission đã xong chưa, như IsMissionHaveDone của Game.exe 2026 (0x14009e790): từ thứ
// mission / 32, bit mission % 32; id từ 4096 trở lên là chưa xong.
// Khác gốc: id âm trả false; mã gốc dịch số học rồi đọc ra trước mảng.
[[nodiscard]] constexpr bool is_done(const Log& log, std::int32_t mission) noexcept {
    if (mission < 0) return false;
    const auto word = static_cast<std::size_t>(mission / kDoneBits);
    if (word >= kDoneWords) return false;
    return ((log.done.at(word) >> static_cast<unsigned>(mission % kDoneBits)) & 1U) != 0U;
}

// Đánh dấu mission đã xong; id ngoài 0..4095 thì bỏ qua (máy chủ gốc không gửi id như vậy).
constexpr void mark_done(Log& log, std::int32_t mission) noexcept {
    if (mission < 0) return;
    const auto word = static_cast<std::size_t>(mission / kDoneBits);
    if (word >= kDoneWords) return;
    log.done.at(word) |= 1U << static_cast<unsigned>(mission % kDoneBits);
}

// Đang giữ mission không, như HaveMission của Game.exe 2026 (0x14009e1e0): id âm là không; không
// xét cờ của ô.
[[nodiscard]] constexpr bool holds(const Log& log, std::int32_t mission) noexcept {
    if (mission < 0) return false;
    return std::ranges::contains(log.slots, mission, &Slot::mission);
}

} // namespace game::quest
