// Bộ phát nhạc và hiệu ứng. Một luồng gọi API. Bộ trộn chạy ngay trong callback của thiết bị nên
// thiết bị xin bao nhiêu khung cũng có đủ; callback không khoá, không cấp phát, không giải mã.
// Nhạc giải mã ở luồng riêng vào vòng đệm. Mọi thứ trộn ở 48 kHz; tệp và thiết bị ở tần số khác
// đi qua audio/resample.hpp. Đầu ra qua bộ hạn biên, không cắt cụt.
// Thiết bị lỗi thì open vẫn thành công: client chạy tiếp, device_is_open báo không có loa.
#pragma once

#include "audio/gain.hpp"
#include "audio/limits.hpp"
#include "core/error.hpp"

#include <cstdint>
#include <filesystem>
#include <memory>
#include <span>
#include <string>
#include <string_view>

namespace game::audio {

using SoundId = std::uint32_t;
using SoundResult = core::Result<SoundId>;

// Id cột đầu của Config/SoundInfo.txt. 3253 là nhạc đăng nhập, 435 là tiếng bấm nút.
inline constexpr std::string_view kLoginMusicId = "3253";
inline constexpr std::string_view kButtonClickId = "435";

enum class MusicPhase : std::uint8_t { kNone, kFadeIn, kPlay, kFadeOut };

struct OpenRequest {
    std::filesystem::path data_root;
    bool use_device = true;
};

// priority mặc định là tiếng 2D. play_spatial nâng lên tiếng 3D nếu người gọi không đổi.
struct Cue {
    float gain = 1.F;
    bool is_loop = false;
    std::int32_t priority = kPriorityFlat;
    Place place{};
    DistanceSpan reach{.near_distance = 100.F, .far_distance = 5000.F};
};

struct PcmView {
    std::span<const std::int16_t> samples;
    std::uint32_t channels = 1;
    bool is_spatial = false;
    Cue cue{};
};

struct EncodedView {
    std::span<const std::byte> bytes;
    Cue cue{};
};

struct MusicBytes {
    std::span<const std::byte> bytes;
    float fade_seconds = 0.F;
};

struct AmbienceCue {
    Cue cue{};
    float interval_seconds = 0.F;
};

// Số đo của đường phát để client ghi log và test soi. Đọc từ luồng nào cũng được.
struct Stats {
    // Số lần thiết bị gọi và tổng số khung đã trộn.
    std::uint64_t callbacks = 0;
    std::uint64_t frames = 0;
    // Số khung nhạc bộ trộn cần mà luồng giải mã chưa kịp đưa. Khác 0 là nghe được.
    std::uint64_t music_starved = 0;
    // Số khung lớn nhất thiết bị xin trong một lần gọi.
    std::uint32_t largest_burst = 0;
    // Số tiếng còn sống sau khối vừa trộn.
    std::uint32_t voices = 0;
    // Tần số thật của thiết bị; 0 khi không mở thiết bị.
    std::uint32_t device_rate = 0;
    // Đỉnh của tổng trước bộ hạn biên, và hệ số nhỏ nhất bộ hạn biên từng áp (1 là chưa ép).
    float peak = 0.F;
    float deepest_limit = 1.F;
};

// Một dòng cho log: tần số thiết bị, cỡ khối, số khung nhạc bị hụt, mức ép của bộ hạn biên.
[[nodiscard]] std::string describe(const Stats& stats);

// Trộn cố định 32 tiếng, nhạc một luồng riêng, fade theo số mẫu đã render.
class Engine {
public:
    Engine();
    ~Engine();
    Engine(Engine&&) noexcept;
    Engine& operator=(Engine&&) noexcept;
    Engine(const Engine&) = delete;
    Engine& operator=(const Engine&) = delete;

    [[nodiscard]] core::Status open(const OpenRequest& request);
    void close() noexcept;

    [[nodiscard]] bool is_open() const noexcept;
    [[nodiscard]] bool device_is_open() const noexcept;

    void set_listener(const Ear& ear);
    void set_effect_gain(float gain);
    void set_music_gain(float gain);

    [[nodiscard]] core::Status play_music(std::string_view name, float fade_seconds);
    [[nodiscard]] core::Status play_music_bytes(const MusicBytes& music);
    void stop_music(float fade_seconds);

    [[nodiscard]] SoundResult play_flat(std::string_view name, float gain);
    [[nodiscard]] SoundResult play_spatial(std::string_view name, const Cue& cue);
    [[nodiscard]] SoundResult play_pcm(const PcmView& view);
    [[nodiscard]] SoundResult play_encoded(const EncodedView& view);
    [[nodiscard]] SoundResult add_ambience(std::string_view name, const AmbienceCue& cue);

    void stop(SoundId sound_id);

    // Stereo xen kẽ. Chỉ gọi khi không mở thiết bị; luồng trộn đang chạy thì đây là lỗi lập trình.
    void render(std::span<float> interleaved_stereo);

    [[nodiscard]] MusicPhase music_phase() const noexcept;
    [[nodiscard]] float music_level() const noexcept;
    [[nodiscard]] std::uint32_t loaded_clips() const noexcept;
    [[nodiscard]] Stats stats() const noexcept;

private:
    struct Body;
    std::unique_ptr<Body> body_;
};

} // namespace game::audio
