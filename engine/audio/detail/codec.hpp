// Mã hoá và giải mã tệp cook (audio/pack.hpp). libopus chỉ có trong codec.cpp. Bản build không có
// libopus (GAME_AUDIO_OPUS không được định nghĩa: preset GCC không lấy được gói vcpkg) vẫn đọc được
// tệp PCM; tệp Opus báo kUnsupported.
#pragma once

#include "audio/detail/native.hpp"
#include "audio/pack.hpp"
#include "core/error.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <span>

struct OpusDecoder;

namespace game::audio::detail {

enum class OpusKind : std::uint8_t {
    kMusic,
    kVoice,
};

struct OpusPlan {
    std::uint32_t channels = 2;
    // Bit mỗi giây cho cả luồng.
    std::uint32_t bitrate = 96000;
    OpusKind kind = OpusKind::kMusic;
    // Nhạc lặp: phần dẫn là đuôi của chính bài, để chỗ quay vòng liền mạch.
    bool is_loop = false;
};

// Mã hoá trọn một đoạn float 48 kHz xen kẽ theo kênh thành các gói 20 ms. Chỉ công cụ cook gọi.
[[nodiscard]] core::Result<OpusPackets> encode_opus(std::span<const float> interleaved, const OpusPlan& plan);

struct DecoderCloser {
    void operator()(OpusDecoder* decoder) const noexcept;
};

// Đọc tuần tự một tệp cook ra float 48 kHz. bytes phải sống lâu hơn PackStream.
class PackStream {
public:
    [[nodiscard]] static core::Result<PackStream> open(std::span<const std::byte> bytes);

    [[nodiscard]] std::uint32_t channels() const noexcept { return view_.info.channels; }
    [[nodiscard]] std::uint32_t frames() const noexcept { return view_.info.frames; }

    // Float xen kẽ theo kênh. Trả số khung đã đọc; ít hơn số xin nghĩa là hết tệp.
    [[nodiscard]] std::uint32_t read(std::span<float> interleaved);

    // Về khung đầu tiên.
    void rewind() noexcept;

private:
    [[nodiscard]] bool refill();
    // Chỉ có định nghĩa khi dựng với libopus; open() đã từ chối tải Opus ở bản không có.
    [[nodiscard]] bool decode_opus();
    [[nodiscard]] bool decode_pcm();
    [[nodiscard]] std::uint32_t take(std::span<float> interleaved) noexcept;

    PackView view_;
    std::unique_ptr<OpusDecoder, DecoderCloser> decoder_;
    // Một gói đã giải mã: ready_count_ khung, đã giao tới ready_at_.
    std::array<float, static_cast<std::size_t>(kPacketFrames) * 2> ready_{};
    std::uint32_t ready_at_ = 0;
    std::uint32_t ready_count_ = 0;
    std::uint32_t packet_ = 0;
    std::size_t payload_at_ = 0;
    std::uint32_t skip_left_ = 0;
    std::uint32_t frames_left_ = 0;
};

// Trọn một tệp cook thành mẫu float 48 kHz, không quá max_frames khung.
[[nodiscard]] core::Result<Decoded> decode_pack(std::span<const std::byte> bytes, std::uint32_t max_frames);

} // namespace game::audio::detail
