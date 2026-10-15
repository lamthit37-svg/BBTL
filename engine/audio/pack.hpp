/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/audio/pack.hpp
 *  PHÂN HỆ   : Audio / Pack
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Định dạng tệp âm thanh đã cook (.tla), một miền 48 kHz: lúc chạy không đổi
 *    tần số. Hai kiểu tải: PCM16 (hiệu ứng ngắn) và Opus (hiệu ứng dài, lời
 *    thoại, nhạc, ambience).
 *  - Opus nằm trong bảng gói riêng thay Ogg: gói n bắt đầu ở khung n *
 *    packet_frames nên tua/lặp không cần dò, lúc chạy chỉ cần libopus; lead_in
 *    khung dẫn giúp quay vòng không lách tách.
 *  - Bố cục nhị phân little-endian ở docs/DINH-DANG-TLA.md; mọi trường đọc từ
 *    đĩa được kiểm trước khi dùng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "audio/limits.hpp"
#include "core/error.hpp"

#include <cstddef>
#include <cstdint>
#include <span>
#include <vector>

namespace game::audio {

enum class PackCodec : std::uint8_t {
    kPcm16 = 0,
    kOpus = 1,
};

// Số khung của một gói Opus: 20 ms ở 48 kHz.
inline constexpr std::uint32_t kPacketFrames = 960;
// Trần của một tệp cook: 30 phút, để một tệp hỏng không khiến bộ nạp xin vài GB.
inline constexpr std::uint32_t kPackMaxFrames = kSampleRate * 60 * 30;

struct PackInfo {
    PackCodec codec = PackCodec::kPcm16;
    std::uint32_t channels = 1;
    // Số khung PCM của âm thanh, không tính phần dẫn và phần đệm cuối gói.
    std::uint32_t frames = 0;
    // Opus: số khung đầu ra của bộ giải mã phải bỏ trước khung đầu tiên (trễ của bộ mã cộng phần
    // dẫn).
    std::uint32_t pre_skip = 0;
    std::uint32_t packet_count = 0;
};

// Tệp đã phân tích: info, bảng cỡ gói (Opus) và vùng tải. Các span trỏ vào bytes của người gọi.
struct PackView {
    PackInfo info;
    std::span<const std::byte> sizes;
    std::span<const std::byte> payload;
};

// true khi bytes mở đầu bằng dấu của tệp cook.
[[nodiscard]] bool is_pack(std::span<const std::byte> bytes) noexcept;

// Kiểm đầu tệp, bảng cỡ gói và độ dài vùng tải. Lỗi kCorrupt khi bất kỳ trường nào không khớp.
[[nodiscard]] core::Result<PackView> read_pack(std::span<const std::byte> bytes);

// Cỡ của gói thứ index (Opus). index phải nhỏ hơn packet_count.
[[nodiscard]] std::uint32_t packet_size(const PackView& view, std::uint32_t index) noexcept;

// Ghi tệp PCM16: samples là int16 xen kẽ theo kênh.
[[nodiscard]] std::vector<std::byte> write_pcm_pack(std::span<const std::int16_t> samples, std::uint32_t channels);

// Các gói Opus đã mã hoá, theo thứ tự phát.
struct OpusPackets {
    std::vector<std::vector<std::byte>> packets;
    std::uint32_t channels = 1;
    std::uint32_t frames = 0;
    std::uint32_t pre_skip = 0;
};

// Ghi tệp Opus. Gói rỗng hoặc dài quá 65535 byte là lỗi lập trình của bộ cook.
[[nodiscard]] std::vector<std::byte> write_opus_pack(const OpusPackets& encoded);

} // namespace game::audio
