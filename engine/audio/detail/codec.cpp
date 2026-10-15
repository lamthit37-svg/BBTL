/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/audio/detail/codec.cpp
 *  PHÂN HỆ   : Audio / Codec
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt mã hoá/giải mã Opus và PCM cho tệp cook.
 *  - pre_skip = lookahead của bộ mã + phần dẫn 80 ms; gói cuối đệm im lặng,
 *    PackInfo::frames cho biết chỗ dừng chính xác.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "audio/detail/codec.hpp"

#include "audio/detail/native.hpp"
#include "audio/limits.hpp"
#include "audio/pack.hpp"
#include "core/bits.hpp"
#include "core/error.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>
#include <vector>

#if defined(GAME_AUDIO_OPUS)
#include <array>
#include <memory>
#include <utility>

#include <opus/opus.h>
#include <opus/opus_defines.h>
#include <opus/opus_types.h>
#endif

namespace game::audio::detail {
namespace {

constexpr float kPcmScale = 1.F / 32768.F;

#if defined(GAME_AUDIO_OPUS)

// Phần dẫn trước khung đầu: 80 ms, mức libopus khuyên để bộ giải mã hội tụ sau khi tua.
constexpr std::uint32_t kLeadFrames = 3840;
// Một khung Opus không quá 1275 byte.
constexpr std::size_t kPacketRoom = 1500;
constexpr int kComplexity = 10;

struct EncoderCloser {
    void operator()(OpusEncoder* encoder) const noexcept { opus_encoder_destroy(encoder); }
};
using EncoderHandle = std::unique_ptr<OpusEncoder, EncoderCloser>;

// opus_encoder_ctl nhận tham số qua macro biến số của libopus; không có dạng nào khác.
// NOLINTBEGIN(cppcoreguidelines-pro-type-vararg)
[[nodiscard]] std::uint32_t configure(OpusEncoder* encoder, const OpusPlan& plan) noexcept {
    const bool is_voice = plan.kind == OpusKind::kVoice;
    opus_encoder_ctl(encoder, OPUS_SET_BITRATE(static_cast<opus_int32>(plan.bitrate)));
    opus_encoder_ctl(encoder, OPUS_SET_COMPLEXITY(kComplexity));
    opus_encoder_ctl(encoder, OPUS_SET_SIGNAL(is_voice ? OPUS_SIGNAL_VOICE : OPUS_SIGNAL_MUSIC));
    opus_int32 lookahead = 0;
    opus_encoder_ctl(encoder, OPUS_GET_LOOKAHEAD(&lookahead));
    return static_cast<std::uint32_t>(lookahead);
}

void reset(OpusDecoder* decoder) noexcept {
    if (decoder == nullptr) return;
    opus_decoder_ctl(decoder, OPUS_RESET_STATE);
}
// NOLINTEND(cppcoreguidelines-pro-type-vararg)

// Đầu vào của bộ mã: phần dẫn (đuôi của bài nếu là nhạc lặp), âm thanh, rồi im lặng tới hết gói.
[[nodiscard]] std::vector<float> staged(std::span<const float> interleaved, const OpusPlan& plan,
    std::uint32_t packets) {
    const std::size_t samples = std::size_t{packets} * kPacketFrames * plan.channels;
    std::vector<float> input(samples, 0.F);
    const std::size_t lead = std::size_t{kLeadFrames} * plan.channels;
    const std::span<float> all(input);
    const bool has_tail = plan.is_loop && interleaved.size() >= lead;
    if (has_tail) std::ranges::copy(interleaved.last(lead), all.begin());
    std::ranges::copy(interleaved, all.subspan(lead).begin());
    return input;
}

// Mã hoá một gói 20 ms. false khi libopus báo lỗi.
[[nodiscard]] bool encode_one(OpusEncoder* encoder, std::span<const float> block, OpusPackets& out) {
    std::array<unsigned char, kPacketRoom> room{};
    const auto limit = static_cast<opus_int32>(room.size());
    const opus_int32 size =
        opus_encode_float(encoder, block.data(), static_cast<int>(kPacketFrames), room.data(), limit);
    if (size <= 0) return false;
    const std::span<const unsigned char> written(room.data(), static_cast<std::size_t>(size));
    const std::span<const std::byte> bytes = std::as_bytes(written);
    out.packets.emplace_back(bytes.begin(), bytes.end());
    return true;
}

#endif

core::Failure unsupported() {
    return core::fail(core::ErrorCode::kUnsupported, "bản build này không có Opus");
}

} // namespace

#if defined(GAME_AUDIO_OPUS)

void DecoderCloser::operator()(OpusDecoder* decoder) const noexcept {
    opus_decoder_destroy(decoder);
}

core::Result<OpusPackets> encode_opus(std::span<const float> interleaved, const OpusPlan& plan) {
    const bool has_shape = plan.channels == 1 || plan.channels == 2;
    if (!has_shape || interleaved.empty() || interleaved.size() % plan.channels != 0) {
        return core::fail(core::ErrorCode::kInvalidArgument, "mẫu đưa vào bộ mã Opus sai hình dạng");
    }
    int error = OPUS_OK;
    const EncoderHandle encoder(opus_encoder_create(static_cast<opus_int32>(kSampleRate),
        static_cast<int>(plan.channels), OPUS_APPLICATION_AUDIO, &error));
    if (!encoder || error != OPUS_OK) {
        return core::fail(core::ErrorCode::kUnsupported, "không tạo được bộ mã Opus");
    }
    OpusPackets out;
    out.channels = plan.channels;
    out.frames = static_cast<std::uint32_t>(interleaved.size() / plan.channels);
    out.pre_skip = configure(encoder.get(), plan) + kLeadFrames;
    const std::uint32_t packets = (out.pre_skip + out.frames + kPacketFrames - 1) / kPacketFrames;
    const std::vector<float> input = staged(interleaved, plan, packets);
    const std::span<const float> all(input);
    const std::size_t block = std::size_t{kPacketFrames} * plan.channels;
    bool is_ok = true;
    for (std::uint32_t packet = 0; packet < packets && is_ok; ++packet) {
        is_ok = encode_one(encoder.get(), all.subspan(packet * block, block), out);
    }
    if (!is_ok) return core::fail(core::ErrorCode::kCorrupt, "bộ mã Opus từ chối một gói");
    return out;
}

bool PackStream::decode_opus() {
    if (packet_ >= view_.info.packet_count) return false;
    const std::uint32_t size = packet_size(view_, packet_);
    const std::span<const std::byte> packet = view_.payload.subspan(payload_at_, size);
    // libopus nhận unsigned char; std::byte và unsigned char được phép trỏ cùng vùng nhớ.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
    const auto* data = reinterpret_cast<const unsigned char*>(packet.data());
    const int got = opus_decode_float(decoder_.get(), data, static_cast<opus_int32>(size), ready_.data(),
        static_cast<int>(kPacketFrames), 0);
    packet_ += 1;
    payload_at_ += size;
    if (std::cmp_not_equal(got, kPacketFrames)) return false;
    ready_count_ = kPacketFrames;
    ready_at_ = std::min(skip_left_, ready_count_);
    skip_left_ -= ready_at_;
    return true;
}

#else

void DecoderCloser::operator()(OpusDecoder* /*decoder*/) const noexcept {}

core::Result<OpusPackets> encode_opus(std::span<const float> /*interleaved*/, const OpusPlan& /*plan*/) {
    return unsupported();
}

#endif

core::Result<PackStream> PackStream::open(std::span<const std::byte> bytes) {
    const core::Result<PackView> view = read_pack(bytes);
    if (!view) return std::unexpected(view.error());
    PackStream stream;
    stream.view_ = *view;
#if defined(GAME_AUDIO_OPUS)
    if (view->info.codec == PackCodec::kOpus) {
        int error = OPUS_OK;
        stream.decoder_.reset(opus_decoder_create(static_cast<opus_int32>(kSampleRate),
            static_cast<int>(view->info.channels), &error));
    }
#endif
    if (view->info.codec == PackCodec::kOpus && !stream.decoder_) return unsupported();
    stream.rewind();
    return stream;
}

void PackStream::rewind() noexcept {
    ready_at_ = 0;
    ready_count_ = 0;
    packet_ = 0;
    payload_at_ = 0;
    skip_left_ = view_.info.pre_skip;
    frames_left_ = view_.info.frames;
#if defined(GAME_AUDIO_OPUS)
    reset(decoder_.get());
#endif
}

bool PackStream::decode_pcm() {
    const std::size_t frame_bytes = std::size_t{view_.info.channels} * sizeof(std::int16_t);
    const std::size_t left = (view_.payload.size() - payload_at_) / frame_bytes;
    const auto count = static_cast<std::uint32_t>(std::min<std::size_t>(left, kPacketFrames));
    if (count == 0) return false;
    const std::span<const std::byte> chunk = view_.payload.subspan(payload_at_, count * frame_bytes);
    const std::span<float> ready(ready_);
    const std::size_t samples = std::size_t{count} * view_.info.channels;
    for (std::size_t sample = 0; sample < samples; ++sample) {
        const std::span<const std::byte> two = chunk.subspan(sample * sizeof(std::int16_t));
        ready[sample] = static_cast<float>(core::read_little_endian<std::int16_t>(two)) * kPcmScale;
    }
    payload_at_ += chunk.size();
    ready_at_ = 0;
    ready_count_ = count;
    return true;
}

bool PackStream::refill() {
    if (ready_at_ < ready_count_) return true;
#if defined(GAME_AUDIO_OPUS)
    if (view_.info.codec == PackCodec::kOpus) return decode_opus();
#endif
    return decode_pcm();
}

std::uint32_t PackStream::take(std::span<float> interleaved) noexcept {
    const std::uint32_t channels = view_.info.channels;
    const auto room = static_cast<std::uint32_t>(interleaved.size() / channels);
    const std::uint32_t count = std::min({room, ready_count_ - ready_at_, frames_left_});
    const std::span<const float> ready(ready_);
    const std::size_t from = std::size_t{ready_at_} * channels;
    std::ranges::copy(ready.subspan(from, std::size_t{count} * channels), interleaved.begin());
    ready_at_ += count;
    frames_left_ -= count;
    return count;
}

std::uint32_t PackStream::read(std::span<float> interleaved) {
    const std::uint32_t channels = view_.info.channels;
    const auto wanted = static_cast<std::uint32_t>(interleaved.size() / channels);
    std::uint32_t filled = 0;
    while (filled < wanted && frames_left_ > 0 && refill()) {
        filled += take(interleaved.subspan(std::size_t{filled} * channels));
    }
    return filled;
}

core::Result<Decoded> decode_pack(std::span<const std::byte> bytes, std::uint32_t max_frames) {
    core::Result<PackStream> opened = PackStream::open(bytes);
    if (!opened) return std::unexpected(opened.error());
    PackStream& stream = *opened;
    Decoded decoded;
    decoded.channels = stream.channels();
    decoded.rate = kSampleRate;
    const std::uint32_t frames = std::min(stream.frames(), max_frames);
    decoded.samples.resize(std::size_t{frames} * decoded.channels);
    const std::uint32_t got = stream.read(decoded.samples);
    decoded.samples.resize(std::size_t{got} * decoded.channels);
    if (got == 0) return core::fail(core::ErrorCode::kCorrupt, "tệp âm thanh cook không có mẫu");
    return decoded;
}

} // namespace game::audio::detail
