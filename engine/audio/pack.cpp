// Xem pack.hpp. Đầu tệp 24 byte, rồi bảng cỡ gói (Opus, mỗi gói một uint16), rồi vùng tải.
#include "audio/pack.hpp"

#include "audio/limits.hpp"
#include "core/bits.hpp"
#include "core/check.hpp"
#include "core/error.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <span>
#include <vector>

namespace game::audio {
namespace {

constexpr std::array<std::byte, 4> kMagic{std::byte{'T'}, std::byte{'L'}, std::byte{'A'}, std::byte{'1'}};
constexpr std::size_t kHeaderBytes = 24;
constexpr std::size_t kCodecAt = 4;
constexpr std::size_t kChannelsAt = 5;
constexpr std::size_t kPreSkipAt = 6;
constexpr std::size_t kRateAt = 8;
constexpr std::size_t kFramesAt = 12;
constexpr std::size_t kPacketCountAt = 16;
constexpr std::size_t kPacketFramesAt = 20;
constexpr std::size_t kMaxPacketBytes = std::numeric_limits<std::uint16_t>::max();

core::Failure corrupt() {
    return core::fail(core::ErrorCode::kCorrupt, "tệp âm thanh cook hỏng");
}

template <typename T>
[[nodiscard]] T field(std::span<const std::byte> bytes, std::size_t offset) noexcept {
    return core::read_little_endian<T>(bytes.subspan(offset, sizeof(T)));
}

template <typename T>
void append(std::vector<std::byte>& bytes, T value) {
    const std::size_t before = bytes.size();
    bytes.resize(before + sizeof(T));
    core::write_little_endian(std::span(bytes).subspan(before), value);
}

[[nodiscard]] PackInfo info_of(std::span<const std::byte> bytes) noexcept {
    PackInfo info;
    info.codec = static_cast<PackCodec>(field<std::uint8_t>(bytes, kCodecAt));
    info.channels = field<std::uint8_t>(bytes, kChannelsAt);
    info.pre_skip = field<std::uint16_t>(bytes, kPreSkipAt);
    info.frames = field<std::uint32_t>(bytes, kFramesAt);
    info.packet_count = field<std::uint32_t>(bytes, kPacketCountAt);
    return info;
}

[[nodiscard]] bool is_sane(const PackInfo& info, std::span<const std::byte> bytes) noexcept {
    const bool is_known = info.codec == PackCodec::kPcm16 || info.codec == PackCodec::kOpus;
    const bool has_channels = info.channels == 1 || info.channels == 2;
    const bool is_48k = field<std::uint32_t>(bytes, kRateAt) == kSampleRate;
    const bool has_frames = info.frames > 0 && info.frames <= kPackMaxFrames;
    return is_known && has_channels && is_48k && has_frames;
}

[[nodiscard]] core::Result<PackView> pcm_view(const PackInfo& info, std::span<const std::byte> body) {
    const std::size_t wanted = std::size_t{info.frames} * info.channels * sizeof(std::int16_t);
    if (info.packet_count != 0 || body.size() != wanted) return corrupt();
    return PackView{.info = info, .sizes = {}, .payload = body};
}

// Tổng cỡ các gói phải khít vùng tải, và số gói phải đủ cho pre_skip + frames khung.
[[nodiscard]] core::Result<PackView> opus_view(const PackInfo& info, std::span<const std::byte> body) {
    const std::size_t table_bytes = std::size_t{info.packet_count} * sizeof(std::uint16_t);
    if (info.packet_count == 0 || body.size() < table_bytes) return corrupt();
    const std::uint64_t decoded = std::uint64_t{info.packet_count} * kPacketFrames;
    if (decoded < std::uint64_t{info.pre_skip} + info.frames) return corrupt();
    PackView view{.info = info, .sizes = body.first(table_bytes), .payload = body.subspan(table_bytes)};
    std::size_t total = 0;
    for (std::uint32_t index = 0; index < info.packet_count; ++index) {
        total += packet_size(view, index);
    }
    if (total != view.payload.size()) return corrupt();
    return view;
}

void append_header(std::vector<std::byte>& bytes, const PackInfo& info) {
    bytes.insert(bytes.end(), kMagic.begin(), kMagic.end());
    append(bytes, static_cast<std::uint8_t>(info.codec));
    append(bytes, static_cast<std::uint8_t>(info.channels));
    append(bytes, static_cast<std::uint16_t>(info.pre_skip));
    append(bytes, kSampleRate);
    append(bytes, info.frames);
    append(bytes, info.packet_count);
    const bool is_opus = info.codec == PackCodec::kOpus;
    append(bytes, static_cast<std::uint16_t>(is_opus ? kPacketFrames : 0));
    append(bytes, std::uint16_t{0});
}

} // namespace

bool is_pack(std::span<const std::byte> bytes) noexcept {
    if (bytes.size() < kMagic.size()) return false;
    return std::ranges::equal(bytes.first(kMagic.size()), kMagic);
}

core::Result<PackView> read_pack(std::span<const std::byte> bytes) {
    if (bytes.size() < kHeaderBytes || !is_pack(bytes)) return corrupt();
    const PackInfo info = info_of(bytes);
    if (!is_sane(info, bytes)) return corrupt();
    const std::span<const std::byte> body = bytes.subspan(kHeaderBytes);
    if (info.codec == PackCodec::kPcm16) return pcm_view(info, body);
    if (field<std::uint16_t>(bytes, kPacketFramesAt) != kPacketFrames) return corrupt();
    return opus_view(info, body);
}

std::uint32_t packet_size(const PackView& view, std::uint32_t index) noexcept {
    return field<std::uint16_t>(view.sizes, std::size_t{index} * sizeof(std::uint16_t));
}

std::vector<std::byte> write_pcm_pack(std::span<const std::int16_t> samples, std::uint32_t channels) {
    core::check(channels == 1 || channels == 2, "tệp cook chỉ có một hoặc hai kênh");
    core::check(!samples.empty() && samples.size() % channels == 0, "mẫu PCM phải chia hết số kênh");
    PackInfo info;
    info.codec = PackCodec::kPcm16;
    info.channels = channels;
    info.frames = static_cast<std::uint32_t>(samples.size() / channels);
    std::vector<std::byte> bytes;
    bytes.reserve(kHeaderBytes + (samples.size() * sizeof(std::int16_t)));
    append_header(bytes, info);
    for (const std::int16_t sample : samples) {
        append(bytes, sample);
    }
    return bytes;
}

std::vector<std::byte> write_opus_pack(const OpusPackets& encoded) {
    core::check(!encoded.packets.empty(), "tệp Opus phải có ít nhất một gói");
    core::check(encoded.pre_skip <= kMaxPacketBytes, "pre_skip phải vừa 16 bit");
    PackInfo info;
    info.codec = PackCodec::kOpus;
    info.channels = encoded.channels;
    info.frames = encoded.frames;
    info.pre_skip = encoded.pre_skip;
    info.packet_count = static_cast<std::uint32_t>(encoded.packets.size());
    std::vector<std::byte> bytes;
    append_header(bytes, info);
    for (const std::vector<std::byte>& packet : encoded.packets) {
        core::check(!packet.empty() && packet.size() <= kMaxPacketBytes, "cỡ gói Opus ngoài khoảng");
        append(bytes, static_cast<std::uint16_t>(packet.size()));
    }
    for (const std::vector<std::byte>& packet : encoded.packets) {
        bytes.insert(bytes.end(), packet.begin(), packet.end());
    }
    return bytes;
}

} // namespace game::audio
