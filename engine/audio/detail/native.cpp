// Giải mã và thiết bị. miniaudio chỉ có trong tệp này. Header ấy là include SYSTEM.
// Bộ giải mã và thiết bị đều chạy ở tần số riêng của chúng (sampleRate = 0): miniaudio không đổi
// tần số ở đâu cả.
#include "audio/detail/native.hpp"

#include "audio/limits.hpp"

#include <algorithm>
#include <array>
#include <memory>
#include <utility>
#include <vector>

// libstdc++ của MinGW đã định nghĩa NOMINMAX là 1. Định nghĩa lại là cảnh báo.
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#define MA_NO_FLAC
#define MA_NO_GENERATION
#define MA_NO_RESOURCE_MANAGER
#define MA_NO_NODE_GRAPH
#define MA_NO_ENGINE
#define MA_NO_ENCODING
#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"

namespace game::audio::detail {
namespace {

constexpr std::uint32_t kChunkFrames = 4096;

struct HeldDecoder {
    ma_decoder decoder{};
    bool is_open = false;
};

struct Binding {
    Fill fill = nullptr;
    void* user = nullptr;
    ma_device device{};
};

void on_data(ma_device* device, void* output, const void* /*input*/, ma_uint32 frame_count) {
    if (device == nullptr || output == nullptr) return;
    auto* binding = static_cast<Binding*>(device->pUserData);
    if (binding == nullptr || binding->fill == nullptr) return;
    binding->fill(binding->user, static_cast<float*>(output), frame_count);
}

bool pull_chunk(ma_decoder& decoder, Decoded& decoded, std::uint64_t most) {
    const std::uint64_t held = decoded.samples.size() / decoded.channels;
    if (held >= most) return false;
    std::array<float, static_cast<std::size_t>(kChunkFrames) * 2> chunk{};
    ma_uint64 read = 0;
    const ma_result result = ma_decoder_read_pcm_frames(&decoder, chunk.data(), kChunkFrames, &read);
    if (read == 0) return false;
    const std::size_t count = static_cast<std::size_t>(read) * decoded.channels;
    decoded.samples.insert(decoded.samples.end(), chunk.begin(), chunk.begin() + static_cast<std::ptrdiff_t>(count));
    return result == MA_SUCCESS && read == kChunkFrames;
}

void drain_decoder(ma_decoder& decoder, Decoded& decoded, std::uint32_t max_seconds) {
    const std::uint64_t most = std::uint64_t{max_seconds} * decoded.rate;
    while (pull_chunk(decoder, decoded, most)) {
    }
    const std::size_t kept = static_cast<std::size_t>(most) * decoded.channels;
    if (decoded.samples.size() > kept) decoded.samples.resize(kept);
}

core::Failure fail_corrupt() {
    return core::fail(core::ErrorCode::kCorrupt, "không giải mã được âm thanh");
}

bool is_playable(std::uint32_t channels, std::uint32_t rate) noexcept {
    return (channels == 1 || channels == 2) && rate > 0;
}

} // namespace

core::Result<Decoded> decode_all(std::span<const std::byte> encoded, std::uint32_t max_seconds) {
    if (encoded.empty()) return fail_corrupt();
    const ma_decoder_config config = ma_decoder_config_init(ma_format_f32, 0, 0);
    ma_decoder decoder;
    const ma_result opened = ma_decoder_init_memory(encoded.data(), encoded.size(), &config, &decoder);
    if (opened != MA_SUCCESS) return fail_corrupt();
    Decoded decoded;
    decoded.channels = decoder.outputChannels;
    decoded.rate = decoder.outputSampleRate;
    if (!is_playable(decoded.channels, decoded.rate)) {
        ma_decoder_uninit(&decoder);
        return core::fail(core::ErrorCode::kUnsupported, "chỉ nhận âm thanh một hoặc hai kênh");
    }
    drain_decoder(decoder, decoded, max_seconds);
    ma_decoder_uninit(&decoder);
    if (decoded.samples.empty()) return fail_corrupt();
    return decoded;
}

core::Status stream_open(Stream& stream, std::span<const std::byte> encoded) {
    stream_close(stream);
    if (encoded.empty()) return fail_corrupt();
    auto held = std::make_unique<HeldDecoder>();
    const ma_decoder_config config = ma_decoder_config_init(ma_format_f32, 0, 0);
    const ma_result opened = ma_decoder_init_memory(encoded.data(), encoded.size(), &config, &held->decoder);
    if (opened != MA_SUCCESS) return fail_corrupt();
    held->is_open = true;
    const std::uint32_t channels = held->decoder.outputChannels;
    const std::uint32_t rate = held->decoder.outputSampleRate;
    if (!is_playable(channels, rate)) {
        ma_decoder_uninit(&held->decoder);
        return core::fail(core::ErrorCode::kUnsupported, "chỉ nhận nhạc một hoặc hai kênh");
    }
    stream.channels = channels;
    stream.rate = rate;
    stream.decoder = held.release();
    return core::ok();
}

std::uint32_t stream_read(Stream& stream, std::span<float> interleaved) {
    if (stream.decoder == nullptr || interleaved.empty()) return 0;
    auto* held = static_cast<HeldDecoder*>(stream.decoder);
    const ma_uint64 frames = interleaved.size() / stream.channels;
    ma_uint64 read = 0;
    static_cast<void>(ma_decoder_read_pcm_frames(&held->decoder, interleaved.data(), frames, &read));
    return static_cast<std::uint32_t>(read);
}

void stream_rewind(Stream& stream) noexcept {
    if (stream.decoder == nullptr) return;
    auto* held = static_cast<HeldDecoder*>(stream.decoder);
    static_cast<void>(ma_decoder_seek_to_pcm_frame(&held->decoder, 0));
}

void stream_close(Stream& stream) noexcept {
    if (stream.decoder == nullptr) return;
    auto* held = static_cast<HeldDecoder*>(stream.decoder);
    if (held->is_open) ma_decoder_uninit(&held->decoder);
    delete held;
    stream.decoder = nullptr;
    stream.channels = 1;
    stream.rate = kSampleRate;
}

core::Status device_open(Device& device, Fill fill, void* user) {
    device_close(device);
    if (fill == nullptr) return core::fail(core::ErrorCode::kInvalidArgument, "thiếu hàm đổ mẫu");
    auto binding = std::make_unique<Binding>();
    binding->fill = fill;
    binding->user = user;
    ma_device_config config = ma_device_config_init(ma_device_type_playback);
    config.playback.format = ma_format_f32;
    config.playback.channels = 2;
    // 0: tần số riêng của thiết bị. Bộ trộn tự đổi từ 48 kHz khi thiết bị chạy tần số khác.
    config.sampleRate = 0;
    config.dataCallback = on_data;
    config.pUserData = binding.get();
    // Fill ghi đủ mọi khung, và nhận đúng cỡ khối hệ điều hành đưa (không thêm vùng đệm trung gian).
    config.noPreSilencedOutputBuffer = MA_TRUE;
    config.noFixedSizedCallback = MA_TRUE;
    config.aaudio.usage = ma_aaudio_usage_game;
    const ma_result created = ma_device_init(nullptr, &config, &binding->device);
    if (created != MA_SUCCESS) {
        return core::fail(core::ErrorCode::kUnsupported, "không mở được thiết bị âm thanh");
    }
    device.rate = binding->device.sampleRate;
    device.machine = binding.release();
    return core::ok();
}

core::Status device_start(Device& device) {
    if (device.machine == nullptr) {
        return core::fail(core::ErrorCode::kInvalidState, "thiết bị âm thanh chưa mở");
    }
    auto* binding = static_cast<Binding*>(device.machine);
    if (ma_device_start(&binding->device) == MA_SUCCESS) return core::ok();
    return core::fail(core::ErrorCode::kUnsupported, "không chạy được thiết bị âm thanh");
}

void device_close(Device& device) noexcept {
    if (device.machine == nullptr) return;
    auto* binding = static_cast<Binding*>(device.machine);
    ma_device_stop(&binding->device);
    ma_device_uninit(&binding->device);
    delete binding;
    device.machine = nullptr;
}

} // namespace game::audio::detail
