// Cook một tệp âm thanh gốc (WAV, MP3) thành tệp .tla (audio/pack.hpp). Chạy lúc build, trong công
// cụ thienlong_audio; client không gọi. Mọi tệp ra đều ở 48 kHz: việc đổi tần số làm một lần ở
// đây bằng audio/resample.hpp. Tệp ngắn giữ PCM16 (nạp là dùng, không tốn giải mã); tệp dài thành
// Opus với bitrate theo lớp. Nhạc và ambience được cook như vòng lặp (phần dẫn là đuôi của bài).
// Tệp gốc của client là MP3 và WAV đã qua nén hoặc hạ tần số từ trước: cook không lấy lại được
// thứ đã mất, chỉ không làm mất thêm ở khâu đổi tần số và giữ bitrate đủ cao.
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
