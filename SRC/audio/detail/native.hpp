// Giải mã WAV/MP3 và thiết bị phát. Header này không kéo miniaudio.h: header_check dịch mọi
// header trong SRC, còn miniaudio chỉ nằm trong bản dịch native.cpp. Mọi thứ ở đây giữ tần số gốc
// của tệp và của thiết bị: đổi tần số là việc của audio/resample.hpp, không phải của miniaudio
// (bộ đổi tuyến tính của nó để ảnh phổ gập vào dải nghe).
#pragma once

#include "audio/limits.hpp"
#include "core/error.hpp"

#include <cstdint>
#include <span>
#include <vector>

namespace game::audio::detail {

// Trọn một tệp đã giải mã: float xen kẽ theo kênh, ở tần số gốc.
struct Decoded {
    std::vector<float> samples;
    std::uint32_t channels = 1;
    std::uint32_t rate = kSampleRate;
};

// Một hoặc hai kênh, cắt ở max_seconds giây. Bộ trộn chỉ giữ hiệu ứng ngắn trong bộ nhớ; nhạc
// đi đường Stream. Công cụ cook đọc cả bài.
[[nodiscard]] core::Result<Decoded> decode_all(std::span<const std::byte> encoded, std::uint32_t max_seconds);

struct Stream {
    void* decoder = nullptr;
    std::uint32_t channels = 1;
    std::uint32_t rate = kSampleRate;
};

// Giữ byte nén sống đến stream_close. Luồng giải mã là người duy nhất gọi các hàm stream_*.
[[nodiscard]] core::Status stream_open(Stream& stream, std::span<const std::byte> encoded);

// Float xen kẽ ở tần số gốc. Trả số khung đã đọc; ít hơn số xin nghĩa là hết tệp.
[[nodiscard]] std::uint32_t stream_read(Stream& stream, std::span<float> interleaved);

void stream_rewind(Stream& stream) noexcept;

void stream_close(Stream& stream) noexcept;

// rate là tần số thật của thiết bị sau khi mở.
struct Device {
    void* machine = nullptr;
    std::uint32_t rate = kSampleRate;
};

using Fill = void (*)(void* user, float* interleaved, std::uint32_t frame_count);

// Mở phát stereo float ở tần số riêng của thiết bị, chưa chạy: device.rate đã có để người gọi
// chuẩn bị trước khi callback đầu tiên tới.
[[nodiscard]] core::Status device_open(Device& device, Fill fill, void* user);

// Bắt đầu gọi Fill trên luồng âm thanh của hệ điều hành, mỗi lần một số khung tuỳ thiết bị. Fill
// không khoá, không cấp phát, không đọc tệp.
[[nodiscard]] core::Status device_start(Device& device);

void device_close(Device& device) noexcept;

} // namespace game::audio::detail
