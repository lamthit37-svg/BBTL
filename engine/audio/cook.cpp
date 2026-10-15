/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/audio/cook.cpp
 *  PHÂN HỆ   : Audio / Cook
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt cook: giải mã, đổi tần số về 48 kHz, chọn PCM16 hay Opus và ghi
 *    gói .tla.
 *  - Bitrate chọn theo hướng giữ tiếng: nguồn đã là MP3 (192 kbit/s) nên mã lại
 *    thấp sẽ cộng méo hai bộ mã; sin thuần qua Opus 160 kbit/s đo phần lạ -44
 *    dB, 96 kbit/s là -38 dB.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "audio/cook.hpp"

#include "audio/detail/codec.hpp"
#include "audio/detail/native.hpp"
#include "audio/limits.hpp"
#include "audio/pack.hpp"
#include "audio/resample.hpp"
#include "core/error.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace game::audio {
namespace {

// Tệp gốc dài nhất được cook: 30 phút, cùng trần với tệp .tla.
constexpr std::uint32_t kSourceSeconds = 30 * 60;
// Dưới 0,4 giây thì PCM: tiếng bấm, tiếng bước chân. Opus có phần dẫn 80 ms nên không lợi.
constexpr std::size_t kPcmFrames = 19200;

// Bit mỗi giây theo lớp, cho một kênh và cho hai kênh.
struct Rate {
    CookClass kind = CookClass::kEffect;
    std::uint32_t mono = 64000;
    std::uint32_t stereo = 96000;
};

constexpr std::array<Rate, 4> kRates{{
    {.kind = CookClass::kEffect, .mono = 64000, .stereo = 96000},
    {.kind = CookClass::kVoice, .mono = 48000, .stereo = 72000},
    {.kind = CookClass::kAmbience, .mono = 64000, .stereo = 112000},
    {.kind = CookClass::kMusic, .mono = 96000, .stereo = 144000},
}};

struct Folder {
    std::string_view prefix;
    CookClass kind = CookClass::kEffect;
};

constexpr std::array<Folder, 3> kFolders{{
    {.prefix = "music/", .kind = CookClass::kMusic},
    {.prefix = "ambience/", .kind = CookClass::kAmbience},
    {.prefix = "Dial_", .kind = CookClass::kVoice},
}};

[[nodiscard]] std::uint32_t bitrate_of(CookClass kind, std::uint32_t channels) noexcept {
    const auto is_kind = [kind](const Rate& rate) { return rate.kind == kind; };
    const auto found = std::ranges::find_if(kRates, is_kind);
    return channels == 2 ? found->stereo : found->mono;
}

[[nodiscard]] std::int16_t to_pcm16(float sample) noexcept {
    const float scaled = std::round(sample * 32768.F);
    return static_cast<std::int16_t>(std::clamp(scaled, -32768.F, 32767.F));
}

[[nodiscard]] Cooked pcm_cooked(std::span<const float> samples, std::uint32_t channels) {
    std::vector<std::int16_t> whole(samples.size());
    std::ranges::transform(samples, whole.begin(), &to_pcm16);
    Cooked cooked;
    cooked.bytes = write_pcm_pack(whole, channels);
    cooked.codec = PackCodec::kPcm16;
    cooked.channels = channels;
    cooked.frames = static_cast<std::uint32_t>(samples.size() / channels);
    return cooked;
}

struct OpusJob {
    std::uint32_t channels = 1;
    CookClass kind = CookClass::kEffect;
};

[[nodiscard]] core::Result<Cooked> opus_cooked(std::span<const float> samples, OpusJob job) {
    detail::OpusPlan plan;
    plan.channels = job.channels;
    plan.bitrate = bitrate_of(job.kind, job.channels);
    plan.kind = job.kind == CookClass::kVoice ? detail::OpusKind::kVoice : detail::OpusKind::kMusic;
    plan.is_loop = job.kind == CookClass::kMusic || job.kind == CookClass::kAmbience;
    const core::Result<OpusPackets> encoded = detail::encode_opus(samples, plan);
    if (!encoded) return std::unexpected(encoded.error());
    Cooked cooked;
    cooked.bytes = write_opus_pack(*encoded);
    cooked.codec = PackCodec::kOpus;
    cooked.channels = job.channels;
    cooked.frames = encoded->frames;
    return cooked;
}

} // namespace

CookClass classify(std::string_view relative_path) noexcept {
    const auto is_inside = [relative_path](const Folder& folder) { return relative_path.starts_with(folder.prefix); };
    const auto found = std::ranges::find_if(kFolders, is_inside);
    return found == kFolders.end() ? CookClass::kEffect : found->kind;
}

core::Result<Cooked> cook_sound(std::span<const std::byte> encoded, CookClass kind) {
    core::Result<detail::Decoded> decoded = detail::decode_all(encoded, kSourceSeconds);
    if (!decoded) return std::unexpected(decoded.error());
    const RateChange change{.source_rate = decoded->rate, .target_rate = kSampleRate, .channels = decoded->channels};
    const bool is_native = decoded->rate == kSampleRate;
    const std::vector<float> converted =
        is_native ? std::move(decoded->samples) : resample_all(decoded->samples, change);
    const std::size_t frames = converted.size() / decoded->channels;
    if (frames == 0) return core::fail(core::ErrorCode::kCorrupt, "tệp âm thanh gốc không có mẫu");
    if (frames <= kPcmFrames) return pcm_cooked(converted, decoded->channels);
    return opus_cooked(converted, OpusJob{.channels = decoded->channels, .kind = kind});
}

} // namespace game::audio
