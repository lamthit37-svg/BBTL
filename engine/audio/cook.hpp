/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/audio/cook.hpp
 *  PHÂN HỆ   : Audio / Cook
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cook một tệp âm thanh gốc (WAV, MP3) thành tệp .tla (audio/pack.hpp); chạy
 *    lúc build trong công cụ thienlong_audio, client không gọi.
 *  - Mọi tệp ra ở 48 kHz, đổi tần số một lần tại đây bằng audio/resample.hpp.
 *    Tệp ngắn giữ PCM16, tệp dài thành Opus với bitrate theo lớp; nhạc và
 *    ambience cook như vòng lặp (phần dẫn là đuôi bài).
 *  - Tệp gốc của client là MP3 và WAV đã qua nén hoặc hạ tần số từ trước: cook
 *    không lấy lại được thứ đã mất, chỉ không làm mất thêm ở khâu đổi tần số và
 *    giữ bitrate đủ cao.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "audio/pack.hpp"
#include "core/error.hpp"

#include <cstddef>
#include <cstdint>
#include <span>
#include <string_view>
#include <vector>

namespace game::audio {

enum class CookClass : std::uint8_t {
    kEffect,
    kVoice,
    kAmbience,
    kMusic,
};

// Lớp theo thư mục đầu của đường dẫn tương đối trong cây sound/ (music, ambience, Dial_*).
[[nodiscard]] CookClass classify(std::string_view relative_path) noexcept;

struct Cooked {
    std::vector<std::byte> bytes;
    PackCodec codec = PackCodec::kPcm16;
    std::uint32_t channels = 1;
    std::uint32_t frames = 0;
};

// kCorrupt khi không giải mã được tệp gốc; kUnsupported khi bản build không có Opus mà tệp cần
// Opus.
[[nodiscard]] core::Result<Cooked> cook_sound(std::span<const std::byte> encoded, CookClass kind);

} // namespace game::audio
