/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/audio/limits.hpp
 *  PHÂN HỆ   : Audio / Limits
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hằng của bộ trộn: tần số 48 kHz stereo cho cả PC và mobile, giới hạn
 *    voice, khối, lệnh, clip, bàn nhạc, ambience và cỡ vòng đệm.
 *  - Tệp ở tần số khác được đổi bằng audio/resample.hpp lúc nạp (hiệu ứng) hoặc
 *    ở luồng giải mã (nhạc).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include <cstdint>

namespace game::audio {

inline constexpr std::uint32_t kSampleRate = 48000;
inline constexpr std::uint32_t kVoiceCap = 32;
// Bộ trộn chạy trong callback của thiết bị, chia mỗi lần gọi thành khối không quá ngần này khung.
// Lệnh của game và hệ số âm lượng được nhận ở đầu mỗi khối (5,3 ms).
inline constexpr std::uint32_t kBlockFrames = 256;
inline constexpr std::uint32_t kOrderCap = 128;
inline constexpr std::uint32_t kClipCap = 64;
inline constexpr std::uint32_t kRampFrames = 64;
// Ba bàn nhạc: bài đang phát, bài đang chờ, và bài vừa dừng còn chờ luồng giải mã thu dọn.
inline constexpr std::uint32_t kMusicSlots = 3;
// Vòng đệm của mỗi bàn nhạc: 0,68 giây đã giải mã. Thiết bị xin một lần bao nhiêu khung cũng
// không vượt được (tablet GE8320 xin 4104 khung mỗi lần).
inline constexpr std::uint32_t kMusicRingFrames = 32768;
inline constexpr std::uint32_t kAmbienceCap = 8;
// Trần của bộ hạn biên ở đầu ra, -0,13 dBFS.
inline constexpr float kLimiterCeiling = 0.985F;
// Vận tốc theo cm/s. 343 m/s là tốc độ âm trong không khí.
inline constexpr float kSoundSpeed = 34300.F;
inline constexpr std::int32_t kPriorityMusic = 0;
inline constexpr std::int32_t kPrioritySpatial = 32;
inline constexpr std::int32_t kPriorityFlat = 64;
inline constexpr std::int32_t kPriorityAmbience = 128;
inline constexpr std::uint32_t kNoSound = 0;

} // namespace game::audio
