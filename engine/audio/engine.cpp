// Bộ trộn của client. Khác AudioSystem Loong: không FMOD, không khoá, fade theo số mẫu đã render.
// Bộ trộn chạy ngay trong callback của thiết bị: mỗi lần gọi được chia thành khối không quá
// kBlockFrames khung, đầu mỗi khối nhận lệnh của luồng game qua hàng đợi một ghi một đọc. Bản
// trước trộn ở luồng riêng vào vòng đệm 4096 khung; tablet GE8320 xin 4104 khung mỗi lần nên mỗi
// 85 ms hụt 8 khung (tiếng rè). Callback không cấp phát và không giải phóng: mẫu của clip do
// luồng API giữ và chỉ xoá sau khi bộ trộn báo đã thôi dùng; nhạc do audio/detail/music giải mã ở
// luồng riêng. Không có thiết bị (test) thì render() chạy đúng các khối ấy trên luồng gọi.
// Tắt: đóng thiết bị (hết callback), dừng luồng giải mã, rồi mới xoá mẫu.
#include "audio/engine.hpp"

#include "audio/catalog.hpp"
#include "audio/detail/codec.hpp"
#include "audio/detail/music.hpp"
#include "audio/detail/native.hpp"
#include "audio/gain.hpp"
#include "audio/limiter.hpp"
#include "audio/limits.hpp"
#include "audio/pack.hpp"
#include "audio/resample.hpp"
#include "core/check.hpp"
#include "core/error.hpp"
#include "io/file.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <filesystem>
#include <format>
#include <fstream>
#include <ios>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <thread>
#include <utility>
#include <vector>

// Mảng tiếng, clip và hàng lệnh có sức chứa cố định; chỉ số đã so với sức chứa trước khi lấy.
// Con trỏ PCM và khối float là vùng đã biết số mẫu. .at() ném exception nên không dùng trong
// callback. NOLINTBEGIN(cppcoreguidelines-pro-bounds-constant-array-index,
// cppcoreguidelines-pro-bounds-pointer-arithmetic)

namespace game::audio {
namespace {

constexpr std::uint64_t kPcmBudget = 32ULL * 1024ULL * 1024ULL;
constexpr std::uint64_t kMaxFileBytes = 16ULL * 1024ULL * 1024ULL;
// Clip nằm trọn trong bộ nhớ nên dài không quá 30 giây; dài hơn là nhạc, đi đường luồng.
constexpr std::uint32_t kClipSeconds = 30;
constexpr std::uint32_t kClipFrames = kSampleRate * kClipSeconds;
constexpr float kPcmScale = 1.F / 32768.F;
constexpr float kWorldLimit = 10000000.F;
constexpr std::uint8_t kFlagLoop = 1;
constexpr std::uint8_t kFlagSpatial = 2;
constexpr std::uint8_t kFlagAmbience = 4;
constexpr std::uint8_t kRetireFree = 1;
constexpr std::uint8_t kRetireBusy = 2;
constexpr int kNoDeck = -1;

enum class OrderKind : std::uint8_t {
    kPlay,
    kStop,
    kListener,
    kEffectGain,
    kMusicGain,
    kMusic,
    kMusicStop,
    kRetire,
};

struct Order {
    OrderKind kind = OrderKind::kStop;
    SoundId sound_id = kNoSound;
    std::uint32_t clip_index = 0;
    std::uint32_t generation = 0;
    std::uint32_t frames = 0;
    std::uint32_t channels = 1;
    std::int32_t priority = kPriorityFlat;
    float gain = 1.F;
    float fade_seconds = 0.F;
    float interval = 0.F;
    float near_distance = 100.F;
    float far_distance = 5000.F;
    float x = 0.F;
    float y = 0.F;
    float z = 0.F;
    float velocity_x = 0.F;
    float velocity_y = 0.F;
    float velocity_z = 0.F;
    float forward_x = 0.F;
    float forward_y = 0.F;
    float forward_z = -1.F;
    float up_x = 0.F;
    float up_y = 1.F;
    float up_z = 0.F;
    float listener_vx = 0.F;
    float listener_vy = 0.F;
    float listener_vz = 0.F;
    const std::int16_t* samples = nullptr;
    std::uint8_t flags = 0;
    std::uint8_t deck = 0;
};

struct Voice {
    SoundId sound_id = kNoSound;
    const std::int16_t* samples = nullptr;
    std::uint32_t frames = 0;
    std::uint32_t channels = 1;
    std::uint32_t clip_index = 0;
    // double: float chỉ còn bước 1/32 mẫu sau 10 giây, đủ làm Doppler rung.
    double cursor = 0.0;
    float rate = 1.F;
    // Hệ số mỗi tai: đích của khối này, giá trị đang áp, và bước mỗi khung để tới đích ở cuối
    // khối. Đổi hệ số theo bậc mỗi khối nghe thành tiếng rè khi tai hay nguồn di chuyển.
    Stereo goal{};
    Stereo now{};
    Stereo step{};
    float gain = 1.F;
    float attack = 0.F;
    float release = 0.F;
    std::int32_t priority = kPriorityFlat;
    bool is_loop = false;
    bool is_spatial = false;
    bool is_alive = false;
    bool is_stopping = false;
    bool is_fresh = true;
    bool holds_clip = false;
    std::uint32_t ambience_index = kAmbienceCap;
    Place place{};
    DistanceSpan reach{};
};

struct Ambience {
    bool is_used = false;
    bool is_playing = false;
    SoundId sound_id = kNoSound;
    std::uint32_t clip_index = 0;
    std::uint32_t generation = 0;
    float interval = 0.F;
    float wait = 0.F;
    float gain = 1.F;
    std::int32_t priority = kPriorityAmbience;
    Place place{};
    DistanceSpan reach{};
};

// owned thuộc luồng API; bộ trộn chỉ đọc samples và ba trường mô tả do chính nó ghi.
struct Clip {
    // Số mẫu chỉ biết sau khi giải mã, nên không dùng std::array.
    // NOLINTNEXTLINE(cppcoreguidelines-avoid-c-arrays, modernize-avoid-c-arrays)
    std::unique_ptr<std::int16_t[]> owned;
    std::atomic<const std::int16_t*> samples{nullptr};
    std::atomic<std::uint32_t> users{0};
    std::atomic<std::uint8_t> retire_ack{0};
    std::uint32_t frames = 0;
    std::uint32_t channels = 1;
    std::uint32_t generation = 0;
};

struct Cached {
    std::string key;
    std::uint32_t generation = 0;
    std::uint32_t frames = 0;
    std::uint32_t channels = 1;
    std::uint64_t stamp = 0;
    bool is_pinned = false;
    bool is_live = false;
};

struct SamplePair {
    float left = 0.F;
    float right = 0.F;
};

struct Choice {
    int free_index = -1;
    int worst_index = -1;
    std::int32_t worst_priority = -1;
    double worst_cursor = -1.0;
};

struct Victim {
    int index = -1;
    std::uint64_t stamp = 0;
    bool has = false;
};

struct SlotRelease {
    std::uint32_t index = 0;
    std::uint64_t bytes = 0;
};

struct PlayPlan {
    Cue cue{};
    std::string key;
    std::uint8_t flags = 0;
    float interval = 0.F;
};

struct HeldClip {
    // Số mẫu chỉ biết sau khi giải mã, nên không dùng std::array.
    // NOLINTNEXTLINE(cppcoreguidelines-avoid-c-arrays, modernize-avoid-c-arrays)
    std::unique_ptr<std::int16_t[]> samples;
    std::uint32_t frames = 0;
    std::uint32_t channels = 1;
};

struct RetireWait {
    bool is_finished = false;
    bool is_freed = false;
};

// Hai mức âm lượng nhạc ở đầu và cuối một khối; giữa hai mức là đường thẳng.
struct Ramp {
    float from = 0.F;
    float to = 0.F;
};

float unit_gain(float gain) noexcept {
    if (gain < 0.F) return 0.F;
    if (gain > 1.F) return 1.F;
    return gain;
}

float clamp_world(float value) noexcept {
    if (value < -kWorldLimit) return -kWorldLimit;
    if (value > kWorldLimit) return kWorldLimit;
    return value;
}

void slash_one(char& letter) noexcept {
    if (letter == '\\') letter = '/';
}

void slash_all(std::string& text) noexcept {
    for (char& letter : text) {
        slash_one(letter);
    }
}

std::string strip_data(std::string text) {
    slash_all(text);
    constexpr std::string_view kPrefix = "data/";
    if (text.starts_with(kPrefix)) text.erase(0, kPrefix.size());
    return text;
}

bool is_direct_path(std::string_view name) noexcept {
    if (name.contains('/')) return true;
    if (name.contains('\\')) return true;
    if (name.size() < 4) return false;
    if (name.ends_with(".wav") || name.ends_with(".mp3")) return true;
    if (name.ends_with(".WAV") || name.ends_with(".MP3")) return true;
    return false;
}

core::Result<std::vector<std::byte>> read_bytes(const std::filesystem::path& path) {
    const std::filesystem::path found = io::find_ignoring_case(path);
    if (found.empty()) return core::fail(core::ErrorCode::kNotFound, "không thấy tệp âm thanh");
    std::ifstream input(found, std::ios::binary | std::ios::ate);
    if (!input) return core::fail(core::ErrorCode::kIo, "không đọc được tệp âm thanh");
    const auto end = input.tellg();
    if (end < 0) return core::fail(core::ErrorCode::kIo, "không đọc được tệp âm thanh");
    const auto size = static_cast<std::uint64_t>(end);
    if (size == 0) return core::fail(core::ErrorCode::kCorrupt, "tệp âm thanh rỗng");
    if (size > kMaxFileBytes) return core::fail(core::ErrorCode::kOverflow, "tệp âm thanh quá lớn");
    input.seekg(0);
    std::vector<std::byte> bytes(static_cast<std::size_t>(size));
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
    input.read(reinterpret_cast<char*>(bytes.data()), static_cast<std::streamsize>(size));
    if (!input) return core::fail(core::ErrorCode::kIo, "không đọc được tệp âm thanh");
    return bytes;
}

std::uint64_t pcm_bytes_of(std::uint32_t frames, std::uint32_t channels) noexcept {
    return static_cast<std::uint64_t>(frames) * channels * sizeof(std::int16_t);
}

// Float [-1, 1] về int16 theo thang 32768 của bộ trộn: mẫu int16 của tệp WAV về đúng giá trị cũ.
std::int16_t to_pcm16(float sample) noexcept {
    const float scaled = std::round(sample * 32768.F);
    const float held = std::clamp(scaled, -32768.F, 32767.F);
    return static_cast<std::int16_t>(held);
}

// Tệp đã giải mã thành clip 48 kHz int16. Tệp ở tần số khác được đổi một lần ở đây.
HeldClip clip_of(const detail::Decoded& decoded) {
    const RateChange change{.source_rate = decoded.rate, .target_rate = kSampleRate, .channels = decoded.channels};
    const bool is_native = decoded.rate == kSampleRate;
    const std::vector<float> converted = is_native ? std::vector<float>{} : resample_all(decoded.samples, change);
    const std::span<const float> samples = is_native ? decoded.samples : converted;
    const std::size_t most = std::size_t{kClipFrames} * decoded.channels;
    const std::span<const float> kept = samples.first(std::min(samples.size(), most));
    HeldClip held;
    // Số mẫu theo tệp, không phải mảng cố định.
    // NOLINTNEXTLINE(cppcoreguidelines-avoid-c-arrays, modernize-avoid-c-arrays)
    held.samples = std::make_unique<std::int16_t[]>(kept.size());
    std::ranges::transform(kept, held.samples.get(), &to_pcm16);
    held.frames = static_cast<std::uint32_t>(kept.size() / decoded.channels);
    held.channels = decoded.channels;
    return held;
}

// Tệp cook đã ở 48 kHz; tệp gốc giải mã bằng miniaudio. Cả hai cắt ở độ dài của một clip.
core::Result<detail::Decoded> decode_any(std::span<const std::byte> bytes) {
    if (is_pack(bytes)) return detail::decode_pack(bytes, kClipFrames);
    return detail::decode_all(bytes, kClipSeconds);
}

// Bản cook của một tệp gốc nằm cùng chỗ, cùng tên, đuôi .tla.
std::filesystem::path cooked_of(std::filesystem::path path) {
    path.replace_extension(".tla");
    return path;
}

// Có bản cook thì đọc bản cook; không thì đọc tệp gốc.
core::Result<std::vector<std::byte>> read_sound(const std::filesystem::path& path) {
    core::Result<std::vector<std::byte>> cooked = read_bytes(cooked_of(path));
    if (cooked) return cooked;
    return read_bytes(path);
}

void consider_free(Choice& choice, const Voice& voice, int index) noexcept {
    if (voice.is_alive) return;
    if (choice.free_index >= 0) return;
    choice.free_index = index;
}

void consider_worst(Choice& choice, const Voice& voice, int index) noexcept {
    if (!voice.is_alive) return;
    const bool is_worse = voice.priority > choice.worst_priority;
    const bool is_tie = voice.priority == choice.worst_priority && voice.cursor > choice.worst_cursor;
    if (!is_worse && !is_tie) return;
    choice.worst_index = index;
    choice.worst_priority = voice.priority;
    choice.worst_cursor = voice.cursor;
}

void consider_victim(Victim& victim, const Cached& cached, const Clip& clip, int index) noexcept {
    if (!cached.is_live || cached.is_pinned) return;
    if (clip.users.load(std::memory_order_acquire) != 0) return;
    if (victim.has && cached.stamp >= victim.stamp) return;
    victim.index = index;
    victim.stamp = cached.stamp;
    victim.has = true;
}

float envelope_of(const Voice& voice) noexcept {
    const float risen = voice.attack / static_cast<float>(kRampFrames);
    const float attack = std::min(risen, 1.F);
    if (!voice.is_stopping) return attack;
    const float fall = voice.release / static_cast<float>(kRampFrames);
    const float release = std::max(0.F, 1.F - fall);
    return attack * release;
}

bool cursor_ready(Voice& voice) noexcept {
    if (voice.frames == 0) {
        voice.is_alive = false;
        return false;
    }
    if (voice.cursor < static_cast<double>(voice.frames)) return true;
    if (!voice.is_loop) {
        voice.is_alive = false;
        return false;
    }
    voice.cursor = 0.0;
    return true;
}

SamplePair sample_at(const Voice& voice) noexcept {
    const auto frame = static_cast<std::uint32_t>(voice.cursor);
    const std::uint32_t ahead = frame + 1;
    const std::uint32_t next = ahead < voice.frames ? ahead : frame;
    const auto fraction = static_cast<float>(voice.cursor - static_cast<double>(frame));
    const std::size_t base = static_cast<std::size_t>(frame) * voice.channels;
    const std::size_t next_base = static_cast<std::size_t>(next) * voice.channels;
    const auto left0 = static_cast<float>(voice.samples[base]);
    const auto left1 = static_cast<float>(voice.samples[next_base]);
    const float left_step = (left1 - left0) * fraction;
    float right = left0 + left_step;
    const float left = right;
    if (voice.channels == 2) {
        const auto right0 = static_cast<float>(voice.samples[base + 1]);
        const auto right1 = static_cast<float>(voice.samples[next_base + 1]);
        const float right_step = (right1 - right0) * fraction;
        right = right0 + right_step;
    }
    const float scaled_left = left * kPcmScale;
    const float scaled_right = right * kPcmScale;
    return SamplePair{.left = scaled_left, .right = scaled_right};
}

SamplePair take_sample(Voice& voice) noexcept {
    if (!cursor_ready(voice) || voice.samples == nullptr) return {};
    const SamplePair sample = sample_at(voice);
    voice.cursor += static_cast<double>(voice.rate);
    return sample;
}

// Tiếng đã được lệnh dừng và đã hạ hết đoạn nhả thì chết: trả chỗ và thôi giữ clip.
void advance_envelope(Voice& voice) noexcept {
    if (!voice.is_stopping) {
        voice.attack += 1.F;
        return;
    }
    voice.release += 1.F;
    if (voice.release >= static_cast<float>(kRampFrames)) voice.is_alive = false;
}

void wrap_cursor(Voice& voice) noexcept {
    if (!voice.is_loop || voice.frames == 0) return;
    voice.cursor = std::fmod(voice.cursor, static_cast<double>(voice.frames));
}

float distance_between(const Ear& ear, const Place& place) noexcept {
    const float offset_x = place.x - ear.x;
    const float offset_y = place.y - ear.y;
    const float offset_z = place.z - ear.z;
    const float square_x = offset_x * offset_x;
    const float square_y = offset_y * offset_y;
    const float square_z = offset_z * offset_z;
    return std::sqrt((square_x + square_y) + square_z);
}

bool is_silent(const Stereo& level) noexcept {
    return level.left == 0.F && level.right == 0.F;
}

void zero_span(std::span<float> samples) noexcept {
    std::ranges::fill(samples, 0.F);
}

float peak_of(std::span<const float> samples) noexcept {
    float peak = 0.F;
    for (const float sample : samples) {
        peak = std::max(peak, std::abs(sample));
    }
    return peak;
}

// Cộng nhạc vào khối với âm lượng đi thẳng từ ramp.from tới ramp.to.
void add_ramped(std::span<float> mix, std::span<const float> music, Ramp ramp) noexcept {
    const std::size_t frames = mix.size() / 2;
    const float step = (ramp.to - ramp.from) / static_cast<float>(frames);
    float level = ramp.from;
    for (std::size_t frame = 0; frame < frames; ++frame) {
        level += step;
        mix[frame * 2] += music[frame * 2] * level;
        mix[(frame * 2) + 1] += music[(frame * 2) + 1] * level;
    }
}

} // namespace

struct Engine::Body {
    Catalog catalog;
    std::filesystem::path root;
    std::array<Voice, kVoiceCap> voices{};
    std::array<Ambience, kAmbienceCap> ambience{};
    std::array<Clip, kClipCap> clips{};
    std::array<Cached, kClipCap> cache{};
    std::array<bool, kClipCap> slot_free{};
    std::array<std::uint32_t, kClipCap> issued{};
    std::array<Order, kOrderCap> orders{};
    detail::MusicDecks decks;
    detail::Device device{};
    // Chỉ có khi thiết bị không chạy 48 kHz: đổi đầu ra của bộ trộn sang tần số thiết bị.
    std::optional<Resampler> output;
    Limiter limiter;
    Ear ear{};
    MusicPhase phase = MusicPhase::kNone;
    std::atomic<std::uint32_t> order_write{0};
    std::atomic<std::uint32_t> order_read{0};
    std::atomic<float> level_now{0.F};
    std::atomic<std::uint8_t> phase_now{0};
    std::atomic<std::uint64_t> stat_callbacks{0};
    std::atomic<std::uint64_t> stat_frames{0};
    std::atomic<std::uint64_t> stat_starved{0};
    std::atomic<std::uint32_t> stat_burst{0};
    std::atomic<std::uint32_t> stat_voices{0};
    std::atomic<float> stat_peak{0.F};
    std::atomic<float> stat_limit{1.F};
    // Bàn nhạc bộ trộn đang phát và bàn chờ tới lượt (kNoDeck là không có).
    int playing_deck = kNoDeck;
    int waiting_deck = kNoDeck;
    float waiting_fade = 0.F;
    float level = 0.F;
    float fade_seconds = 0.F;
    float elapsed = 0.F;
    float fade_from = 1.F;
    float effect_gain = 1.F;
    float music_gain = 1.F;
    // Âm lượng nhạc thực áp ở cuối khối trước; khối sau nối từ đây.
    float music_applied = 0.F;
    std::uint64_t pcm_bytes = 0;
    std::uint64_t stamp = 1;
    SoundId next_id = 1;
    bool last_accepted = false;
    // Thiết bị đang gọi callback: lệnh phải đi qua hàng đợi. Đặt trước khi thiết bị chạy.
    bool is_live = false;
    bool device_open = false;
    bool opened = false;

    Body() { slot_free.fill(true); }

    ~Body() { shutdown(); }
    Body(const Body&) = delete;
    Body& operator=(const Body&) = delete;
    Body(Body&&) = delete;
    Body& operator=(Body&&) = delete;

    void shutdown() noexcept {
        detail::device_close(device);
        is_live = false;
        device_open = false;
        decks.stop();
        for (Clip& clip : clips) {
            clip.samples.store(nullptr, std::memory_order_release);
            clip.owned.reset();
        }
        opened = false;
    }

    // --- lệnh -----------------------------------------------------------------

    bool push(const Order& order) {
        if (!is_live) {
            apply(order);
            return true;
        }
        const std::uint32_t write = order_write.load(std::memory_order_relaxed);
        const std::uint32_t read = order_read.load(std::memory_order_acquire);
        if (write - read >= kOrderCap) return false;
        orders[write & (kOrderCap - 1)] = order;
        order_write.store(write + 1, std::memory_order_release);
        return true;
    }

    bool pop(Order& order) noexcept {
        const std::uint32_t read = order_read.load(std::memory_order_relaxed);
        const std::uint32_t write = order_write.load(std::memory_order_acquire);
        if (read == write) return false;
        order = orders[read & (kOrderCap - 1)];
        order_read.store(read + 1, std::memory_order_release);
        return true;
    }

    void drain_orders() noexcept {
        Order order;
        while (pop(order)) {
            apply(order);
        }
    }

    void apply(const Order& order) noexcept {
        switch (order.kind) {
        case OrderKind::kPlay: apply_play(order); break;
        case OrderKind::kStop: apply_stop(order); break;
        case OrderKind::kListener: apply_listener(order); break;
        case OrderKind::kEffectGain: effect_gain = order.gain; break;
        case OrderKind::kMusicGain: music_gain = order.gain; break;
        case OrderKind::kMusic: apply_music(order); break;
        case OrderKind::kMusicStop: apply_music_stop(order); break;
        case OrderKind::kRetire: apply_retire(order); break;
        }
        publish_music();
    }

    void publish_music() noexcept {
        phase_now.store(static_cast<std::uint8_t>(phase), std::memory_order_relaxed);
        level_now.store(level, std::memory_order_relaxed);
    }

    void apply_listener(const Order& order) noexcept {
        ear.x = order.x;
        ear.y = order.y;
        ear.z = order.z;
        ear.forward_x = order.forward_x;
        ear.forward_y = order.forward_y;
        ear.forward_z = order.forward_z;
        ear.up_x = order.up_x;
        ear.up_y = order.up_y;
        ear.up_z = order.up_z;
        ear.velocity_x = order.listener_vx;
        ear.velocity_y = order.listener_vy;
        ear.velocity_z = order.listener_vz;
    }

    // Bộ trộn bắt đầu thấy mẫu của clip. Vùng nhớ vẫn thuộc luồng API (Clip::owned).
    void adopt(const Order& order) noexcept {
        if (order.clip_index >= kClipCap || order.samples == nullptr) return;
        Clip& clip = clips[order.clip_index];
        clip.frames = order.frames;
        clip.channels = order.channels;
        clip.generation = order.generation;
        clip.samples.store(order.samples, std::memory_order_release);
    }

    void release_voice(Voice& voice) noexcept {
        voice.is_alive = false;
        voice.samples = nullptr;
        if (voice.ambience_index < kAmbienceCap) ambience[voice.ambience_index].is_playing = false;
        if (!voice.holds_clip) return;
        voice.holds_clip = false;
        if (voice.clip_index >= kClipCap) return;
        clips[voice.clip_index].users.fetch_sub(1, std::memory_order_acq_rel);
    }

    void start_voice(Voice& voice, const Order& order, const std::int16_t* samples) noexcept {
        if (voice.holds_clip) release_voice(voice);
        voice = Voice{};
        voice.sound_id = order.sound_id;
        voice.samples = samples;
        voice.frames = clips[order.clip_index].frames;
        voice.channels = clips[order.clip_index].channels;
        voice.clip_index = order.clip_index;
        voice.gain = order.gain;
        voice.priority = order.priority;
        voice.is_loop = (order.flags & kFlagLoop) != 0;
        voice.is_spatial = (order.flags & kFlagSpatial) != 0;
        Place place;
        place.x = order.x;
        place.y = order.y;
        place.z = order.z;
        place.velocity_x = order.velocity_x;
        place.velocity_y = order.velocity_y;
        place.velocity_z = order.velocity_z;
        voice.place = place;
        DistanceSpan reach;
        reach.near_distance = order.near_distance;
        reach.far_distance = order.far_distance;
        voice.reach = reach;
        voice.holds_clip = true;
        voice.is_alive = true;
        clips[order.clip_index].users.fetch_add(1, std::memory_order_acq_rel);
        if ((order.flags & kFlagAmbience) == 0 || order.interval <= 0.F) return;
        bind_ambience(voice, order);
    }

    void bind_ambience(Voice& voice, const Order& order) noexcept {
        for (std::uint32_t index = 0; index < kAmbienceCap; ++index) {
            take_ambience(voice, order, index);
        }
    }

    void take_ambience(Voice& voice, const Order& order, std::uint32_t index) noexcept {
        if (voice.ambience_index < kAmbienceCap) return;
        if (ambience[index].is_used) return;
        Ambience& slot = ambience[index];
        slot.is_used = true;
        slot.is_playing = true;
        slot.sound_id = order.sound_id;
        slot.clip_index = order.clip_index;
        slot.generation = order.generation;
        slot.interval = order.interval;
        slot.wait = 0.F;
        slot.gain = order.gain;
        slot.priority = order.priority;
        slot.place = voice.place;
        slot.reach = voice.reach;
        voice.ambience_index = index;
        voice.is_loop = false;
    }

    int pick_voice(std::int32_t priority) const noexcept {
        Choice choice;
        for (std::uint32_t index = 0; index < kVoiceCap; ++index) {
            const int slot = static_cast<int>(index);
            consider_free(choice, voices[index], slot);
            consider_worst(choice, voices[index], slot);
        }
        if (choice.free_index >= 0) return choice.free_index;
        if (choice.worst_index < 0) return -1;
        if (choice.worst_priority < priority) return -1;
        return choice.worst_index;
    }

    void release_pin(const Order& order) noexcept {
        if (order.samples == nullptr || order.clip_index >= kClipCap) return;
        clips[order.clip_index].users.fetch_sub(1, std::memory_order_acq_rel);
    }

    void apply_play(const Order& order) noexcept {
        if (order.samples != nullptr) adopt(order);
        if (order.clip_index >= kClipCap) {
            release_pin(order);
            return;
        }
        const Clip& clip = clips[order.clip_index];
        const std::int16_t* samples = clip.samples.load(std::memory_order_acquire);
        if (samples == nullptr || clip.generation != order.generation) {
            release_pin(order);
            return;
        }
        const int slot = pick_voice(order.priority);
        if (slot < 0) {
            release_pin(order);
            return;
        }
        start_voice(voices[static_cast<std::uint32_t>(slot)], order, samples);
        release_pin(order);
        last_accepted = true;
    }

    static void note_stop(Voice& voice, SoundId sound_id) noexcept {
        if (!voice.is_alive) return;
        if (voice.sound_id != sound_id) return;
        voice.is_stopping = true;
    }

    void apply_stop(const Order& order) noexcept {
        for (Voice& voice : voices) {
            note_stop(voice, order.sound_id);
        }
        for (Ambience& slot : ambience) {
            clear_ambience(slot, order.sound_id);
        }
    }

    static void clear_ambience(Ambience& slot, SoundId sound_id) noexcept {
        if (!slot.is_used || slot.sound_id != sound_id) return;
        slot.is_used = false;
        slot.is_playing = false;
    }

    // Bộ trộn thôi nhìn clip rồi báo lại; luồng API thấy kRetireFree mới xoá vùng nhớ.
    void apply_retire(const Order& order) noexcept {
        if (order.clip_index >= kClipCap) return;
        Clip& clip = clips[order.clip_index];
        const bool is_busy = clip.users.load(std::memory_order_acquire) != 0;
        const bool is_stale = clip.generation != order.generation;
        if (is_busy || is_stale) {
            clip.retire_ack.store(kRetireBusy, std::memory_order_release);
            return;
        }
        clip.samples.store(nullptr, std::memory_order_release);
        clip.frames = 0;
        clip.generation = 0;
        clip.retire_ack.store(kRetireFree, std::memory_order_release);
    }

    // --- nhạc -----------------------------------------------------------------

    void release_deck(int deck) noexcept {
        if (deck == kNoDeck) return;
        decks.release(static_cast<std::uint32_t>(deck));
    }

    void start_music(int deck, float fade) noexcept {
        release_deck(playing_deck);
        playing_deck = deck;
        fade_seconds = fade;
        elapsed = 0.F;
        fade_from = 1.F;
        music_applied = 0.F;
        const bool is_instant = fade <= 0.F;
        phase = is_instant ? MusicPhase::kPlay : MusicPhase::kFadeIn;
        level = is_instant ? 1.F : 0.F;
        if (is_instant) music_applied = music_gain;
    }

    void finish_music() noexcept {
        release_deck(playing_deck);
        playing_deck = kNoDeck;
        phase = MusicPhase::kNone;
        level = 0.F;
        music_applied = 0.F;
        if (waiting_deck == kNoDeck) return;
        const int next = waiting_deck;
        waiting_deck = kNoDeck;
        start_music(next, waiting_fade);
    }

    // Chưa có nhạc hoặc bài hiện tại mới đang vào thì thay ngay; đang phát thì bài mới chờ tới
    // khi bài hiện tại dừng. Bài chờ cũ hơn bị bài chờ mới thay.
    void apply_music(const Order& order) noexcept {
        const bool is_now = phase == MusicPhase::kNone || phase == MusicPhase::kFadeIn;
        if (is_now) {
            start_music(static_cast<int>(order.deck), order.fade_seconds);
            return;
        }
        release_deck(waiting_deck);
        waiting_deck = static_cast<int>(order.deck);
        waiting_fade = order.fade_seconds;
    }

    void apply_music_stop(const Order& order) noexcept {
        if (phase == MusicPhase::kNone) return;
        fade_from = level;
        elapsed = 0.F;
        fade_seconds = order.fade_seconds;
        if (order.fade_seconds <= 0.F) {
            finish_music();
            return;
        }
        phase = MusicPhase::kFadeOut;
    }

    void advance_in(float seconds) noexcept {
        elapsed += seconds;
        const FadeSpan span{.elapsed_seconds = elapsed, .duration_seconds = fade_seconds};
        level = fade_in(span);
        if (level < 1.F) return;
        phase = MusicPhase::kPlay;
        elapsed = 0.F;
        level = 1.F;
    }

    void advance_out(float seconds) noexcept {
        elapsed += seconds;
        const FadeSpan span{.elapsed_seconds = elapsed, .duration_seconds = fade_seconds};
        level = fade_from * fade_out(span);
    }

    void advance_music(std::uint32_t frames) noexcept {
        const float seconds = static_cast<float>(frames) / static_cast<float>(kSampleRate);
        if (phase == MusicPhase::kFadeIn) advance_in(seconds);
        if (phase == MusicPhase::kFadeOut) advance_out(seconds);
        if (phase == MusicPhase::kPlay) level = 1.F;
    }

    // Một khối nhạc. Bàn còn đang mở thì chờ, chưa tính fade; bàn hỏng thì bỏ bài.
    void mix_music(std::span<float> mix) noexcept {
        if (playing_deck == kNoDeck) return;
        const auto deck = static_cast<std::uint32_t>(playing_deck);
        const detail::DeckState state = decks.state(deck);
        if (state == detail::DeckState::kLoading) return;
        if (state != detail::DeckState::kReady) {
            finish_music();
            return;
        }
        const auto frames = static_cast<std::uint32_t>(mix.size() / 2);
        std::array<float, static_cast<std::size_t>(kBlockFrames) * 2> music{};
        const std::span<float> wanted = std::span<float>(music).first(mix.size());
        const std::uint32_t got = decks.read(deck, wanted);
        const std::uint64_t starved = stat_starved.load(std::memory_order_relaxed);
        stat_starved.store(starved + (frames - got), std::memory_order_relaxed);
        advance_music(frames);
        const Ramp ramp{.from = music_applied, .to = level * music_gain};
        add_ramped(mix, wanted, ramp);
        music_applied = ramp.to;
        if (phase == MusicPhase::kFadeOut && level <= 0.F) finish_music();
    }

    // --- tiếng ----------------------------------------------------------------

    void prepare(Voice& voice, float block_frames) const noexcept {
        if (!voice.is_alive) return;
        float spatial = 1.F;
        Stereo pan{.left = 1.F, .right = 1.F};
        voice.rate = 1.F;
        if (voice.is_spatial) {
            const float distance = distance_between(ear, voice.place);
            spatial = distance_gain(distance, voice.reach);
            pan = pan_of(ear, voice.place);
            voice.rate = doppler_rate(ear, voice.place);
        }
        const float shaped = voice.gain * effect_gain * spatial;
        voice.goal = Stereo{.left = shaped * pan.left, .right = shaped * pan.right};
        // Tiếng mới vào đã có đoạn dâng của envelope; hệ số không cần dốc từ 0.
        if (voice.is_fresh) voice.now = voice.goal;
        voice.is_fresh = false;
        voice.step.left = (voice.goal.left - voice.now.left) / block_frames;
        voice.step.right = (voice.goal.right - voice.now.right) / block_frames;
    }

    void prepare_all(std::uint32_t frames) noexcept {
        const auto block_frames = static_cast<float>(frames);
        for (Voice& voice : voices) {
            prepare(voice, block_frames);
        }
    }

    void add_one(Voice& voice, float* destination, std::uint32_t index) noexcept {
        if (!voice.is_alive || voice.samples == nullptr) return;
        const float envelope = envelope_of(voice);
        const SamplePair sample = take_sample(voice);
        advance_envelope(voice);
        if (!voice.is_alive) release_voice(voice);
        voice.now.left += voice.step.left;
        voice.now.right += voice.step.right;
        const std::size_t offset = static_cast<std::size_t>(index) * 2;
        const float left_mix = (sample.left * voice.now.left) * envelope;
        const float right_mix = (sample.right * voice.now.right) * envelope;
        destination[offset] += left_mix;
        destination[offset + 1] += right_mix;
    }

    void mix_voice(Voice& voice, float* destination, std::uint32_t frames) noexcept {
        for (std::uint32_t index = 0; index < frames; ++index) {
            add_one(voice, destination, index);
        }
        voice.now = voice.goal;
    }

    void skip_voice(Voice& voice, std::uint32_t frames) noexcept {
        const auto count = static_cast<float>(frames);
        voice.cursor += static_cast<double>(voice.rate) * static_cast<double>(frames);
        voice.attack += count;
        if (voice.is_stopping) voice.release += count;
        wrap_cursor(voice);
        const bool is_ended = !voice.is_loop && voice.cursor >= static_cast<double>(voice.frames);
        const bool is_faded = voice.is_stopping && voice.release >= static_cast<float>(kRampFrames);
        if (is_ended || is_faded) release_voice(voice);
    }

    void render_voice(Voice& voice, float* destination, std::uint32_t frames) noexcept {
        if (!voice.is_alive) return;
        if (is_silent(voice.goal) && is_silent(voice.now)) {
            skip_voice(voice, frames);
            return;
        }
        mix_voice(voice, destination, frames);
    }

    void mix_voices(float* destination, std::uint32_t frames) noexcept {
        for (Voice& voice : voices) {
            render_voice(voice, destination, frames);
        }
    }

    void restart_ambience(Ambience& slot) noexcept {
        if (!slot.is_used || slot.interval <= 0.F || slot.is_playing) return;
        const std::int16_t* samples = clips[slot.clip_index].samples.load(std::memory_order_acquire);
        if (samples == nullptr || clips[slot.clip_index].generation != slot.generation) return;
        Order order;
        order.sound_id = slot.sound_id;
        order.clip_index = slot.clip_index;
        order.generation = slot.generation;
        order.gain = slot.gain;
        order.priority = slot.priority;
        order.flags = static_cast<std::uint8_t>(kFlagSpatial | kFlagAmbience);
        order.interval = slot.interval;
        order.x = slot.place.x;
        order.y = slot.place.y;
        order.z = slot.place.z;
        order.near_distance = slot.reach.near_distance;
        order.far_distance = slot.reach.far_distance;
        const int picked = pick_voice(slot.priority);
        if (picked < 0) return;
        start_voice(voices[static_cast<std::uint32_t>(picked)], order, samples);
        slot.is_playing = true;
        slot.wait = 0.F;
    }

    void service_one(Ambience& slot, float seconds) noexcept {
        if (!slot.is_used || slot.interval <= 0.F) return;
        if (slot.is_playing) return;
        slot.wait += seconds;
        if (slot.wait < slot.interval) return;
        restart_ambience(slot);
    }

    void service_ambience(std::uint32_t frames) noexcept {
        const float seconds = static_cast<float>(frames) / static_cast<float>(kSampleRate);
        for (Ambience& slot : ambience) {
            service_one(slot, seconds);
        }
    }

    // --- khối và thiết bị -------------------------------------------------------

    // Hạn biên và ghi số đo của một khối đã trộn xong.
    void finish_block(std::span<float> mix) noexcept {
        const float peak = peak_of(mix);
        limiter.process(mix);
        if (peak > stat_peak.load(std::memory_order_relaxed)) {
            stat_peak.store(peak, std::memory_order_relaxed);
        }
        stat_limit.store(limiter.deepest(), std::memory_order_relaxed);
        const std::uint64_t frames = stat_frames.load(std::memory_order_relaxed);
        stat_frames.store(frames + (mix.size() / 2), std::memory_order_relaxed);
        const auto is_alive = [](const Voice& voice) { return voice.is_alive; };
        const auto alive = static_cast<std::uint32_t>(std::ranges::count_if(voices, is_alive));
        stat_voices.store(alive, std::memory_order_relaxed);
    }

    // Một khối không quá kBlockFrames khung. Không thiết bị thì việc của luồng giải mã làm tại đây.
    void mix_block(float* destination, std::uint32_t frames) {
        const std::span<float> mix{destination, static_cast<std::size_t>(frames) * 2};
        zero_span(mix);
        drain_orders();
        if (!decks.is_threaded()) decks.pump();
        service_ambience(frames);
        prepare_all(frames);
        mix_voices(destination, frames);
        mix_music(mix);
        finish_block(mix);
        publish_music();
    }

    void mix_span(float* destination, std::uint32_t frames) {
        std::uint32_t done = 0;
        while (done < frames) {
            const std::uint32_t count = std::min(kBlockFrames, frames - done);
            mix_block(destination + (static_cast<std::size_t>(done) * 2), count);
            done += count;
        }
    }

    // Trộn một khối 48 kHz rồi nạp vào bộ đổi tần số của đầu ra.
    void feed_output(std::uint32_t frames) {
        std::array<float, static_cast<std::size_t>(kBlockFrames) * 2> mixed{};
        mix_block(mixed.data(), frames);
        const std::span<const float> block(mixed);
        output->push(block.first(static_cast<std::size_t>(frames) * 2));
    }

    // Thiết bị không chạy 48 kHz: trộn đủ số khung 48 kHz mà frames khung của thiết bị cần.
    void convert_block(float* destination, std::uint32_t frames) {
        std::uint32_t need = output->needed(frames);
        while (need > 0) {
            feed_output(std::min(need, kBlockFrames));
            need = output->needed(frames);
        }
        const std::span<float> out{destination, static_cast<std::size_t>(frames) * 2};
        const std::uint32_t made = output->pull(out);
        zero_span(out.subspan(static_cast<std::size_t>(made) * 2));
    }

    void convert_span(float* destination, std::uint32_t frames) {
        std::uint32_t done = 0;
        while (done < frames) {
            const std::uint32_t count = std::min(kBlockFrames, frames - done);
            convert_block(destination + (static_cast<std::size_t>(done) * 2), count);
            done += count;
        }
    }

    void note_burst(std::uint32_t frames) noexcept {
        const std::uint64_t calls = stat_callbacks.load(std::memory_order_relaxed);
        stat_callbacks.store(calls + 1, std::memory_order_relaxed);
        if (frames <= stat_burst.load(std::memory_order_relaxed)) return;
        stat_burst.store(frames, std::memory_order_relaxed);
    }

    // Callback của thiết bị. Khi có thiết bị thì luồng giải mã đang chạy nên pump() không được
    // gọi ở đây, và bộ đổi tần số đã đặt trước chỗ: không còn gì cấp phát hay ném.
    // NOLINTNEXTLINE(bugprone-exception-escape)
    static void fill_device(void* user, float* destination, std::uint32_t frames) noexcept {
        auto* self = static_cast<Body*>(user);
        self->note_burst(frames);
        if (self->output) {
            self->convert_span(destination, frames);
            return;
        }
        self->mix_span(destination, frames);
    }

    // --- nạp ------------------------------------------------------------------

    void load_table() {
        const std::filesystem::path path = root / "sound" / "sound_table.xml";
        const std::filesystem::path found = io::find_ignoring_case(path);
        if (found.empty()) return;
        const io::TextResult text = io::read_text(found);
        if (!text) return;
        const core::Status loaded = catalog.load(*text);
        static_cast<void>(loaded);
    }

    core::Result<std::string> resolve(std::string_view name) const {
        if (name.empty()) return core::fail(core::ErrorCode::kNotFound, "thiếu tên âm thanh");
        if (is_direct_path(name)) return strip_data(std::string(name));
        const std::string_view found = catalog.find(name);
        if (found.empty()) return core::fail(core::ErrorCode::kNotFound, "không có trong bảng âm thanh");
        return strip_data(std::string(found));
    }

    void note_key(int* slot, std::string_view key, std::uint32_t index) const noexcept {
        if (slot == nullptr || *slot >= 0 || key.empty()) return;
        if (!cache[index].is_live) return;
        if (cache[index].key != key) return;
        *slot = static_cast<int>(index);
    }

    int find_key(std::string_view key) const noexcept {
        int slot = -1;
        for (std::uint32_t index = 0; index < kClipCap; ++index) {
            note_key(&slot, key, index);
        }
        return slot;
    }

    int oldest_idle() const noexcept {
        Victim victim;
        for (std::uint32_t index = 0; index < kClipCap; ++index) {
            const int slot = static_cast<int>(index);
            consider_victim(victim, cache[index], clips[index], slot);
        }
        return victim.index;
    }

    static void wait_ack(const Clip& clip, RetireWait& wait) {
        const std::uint8_t ack = clip.retire_ack.load(std::memory_order_acquire);
        if (ack == 0) {
            std::this_thread::sleep_for(std::chrono::milliseconds(1));
            return;
        }
        wait.is_finished = true;
        wait.is_freed = ack == kRetireFree;
    }

    // Bộ trộn nhận lệnh ở đầu khối kế tiếp: chờ tối đa 200 ms cho nó báo đã thôi dùng clip.
    bool evict_oldest() {
        const int victim = oldest_idle();
        if (victim < 0) return false;
        const auto index = static_cast<std::uint32_t>(victim);
        Clip& clip = clips[index];
        clip.retire_ack.store(0, std::memory_order_relaxed);
        Order order;
        order.kind = OrderKind::kRetire;
        order.clip_index = index;
        order.generation = cache[index].generation;
        cache[index].is_live = false;
        if (!push(order)) {
            cache[index].is_live = true;
            return false;
        }
        RetireWait wait;
        for (std::uint32_t spin = 0; spin < 200 && !wait.is_finished; ++spin) {
            wait_ack(clip, wait);
        }
        if (!wait.is_freed) {
            cache[index].is_live = true;
            return false;
        }
        clip.owned.reset();
        pcm_bytes -= pcm_bytes_of(cache[index].frames, cache[index].channels);
        slot_free[index] = true;
        cache[index] = Cached{};
        return true;
    }

    void drop_one_if_needed(std::uint64_t need) {
        if (pcm_bytes + need <= kPcmBudget) return;
        static_cast<void>(evict_oldest());
    }

    bool enough_room(std::uint64_t need) {
        for (std::uint32_t pass = 0; pass < kClipCap; ++pass) {
            drop_one_if_needed(need);
        }
        return pcm_bytes + need <= kPcmBudget;
    }

    void take_free(int* slot, std::uint32_t index) const noexcept {
        if (slot == nullptr || *slot >= 0) return;
        if (!slot_free[index]) return;
        *slot = static_cast<int>(index);
    }

    int first_free() const noexcept {
        int slot = -1;
        for (std::uint32_t index = 0; index < kClipCap; ++index) {
            take_free(&slot, index);
        }
        return slot;
    }

    int reserve_index(std::uint64_t need) {
        if (!enough_room(need)) return -1;
        const int slot = first_free();
        if (slot >= 0) return slot;
        if (!evict_oldest()) return -1;
        return first_free();
    }

    // Bộ trộn chưa từng thấy clip này (lệnh không tới nơi hoặc không được nhận).
    void drop_slot(SlotRelease release) {
        Clip& clip = clips[release.index];
        clip.samples.store(nullptr, std::memory_order_release);
        clip.users.store(0, std::memory_order_release);
        clip.owned.reset();
        slot_free[release.index] = true;
        cache[release.index] = Cached{};
        pcm_bytes -= release.bytes;
    }

    SoundResult play_cached(int slot, const PlayPlan& plan) {
        const auto index = static_cast<std::uint32_t>(slot);
        Order order = make_order(plan);
        order.clip_index = index;
        order.generation = cache[index].generation;
        order.frames = cache[index].frames;
        order.channels = cache[index].channels;
        cache[index].stamp = stamp;
        stamp += 1;
        last_accepted = false;
        if (!push(order)) return core::fail(core::ErrorCode::kExhausted, "hàng lệnh âm thanh đầy");
        if (is_live) return order.sound_id;
        if (!last_accepted) return core::fail(core::ErrorCode::kExhausted, "không còn tiếng nào để chiếm");
        return order.sound_id;
    }

    Order make_order(const PlayPlan& plan) {
        Order order;
        order.kind = OrderKind::kPlay;
        order.sound_id = next_id;
        next_id += 1;
        order.gain = unit_gain(plan.cue.gain);
        order.priority = plan.cue.priority;
        order.flags = plan.flags;
        if (plan.cue.is_loop) order.flags = static_cast<std::uint8_t>(order.flags | kFlagLoop);
        order.interval = plan.interval;
        order.x = plan.cue.place.x;
        order.y = plan.cue.place.y;
        order.z = plan.cue.place.z;
        order.velocity_x = plan.cue.place.velocity_x;
        order.velocity_y = plan.cue.place.velocity_y;
        order.velocity_z = plan.cue.place.velocity_z;
        order.near_distance = plan.cue.reach.near_distance;
        order.far_distance = plan.cue.reach.far_distance;
        return order;
    }

    void note_cached(std::uint32_t index, const HeldClip& held, const PlayPlan& plan) {
        const std::uint32_t generation = issued[index] + 1;
        issued[index] = generation;
        slot_free[index] = false;
        cache[index].key = plan.key;
        cache[index].generation = generation;
        cache[index].frames = held.frames;
        cache[index].channels = held.channels;
        cache[index].stamp = stamp;
        cache[index].is_pinned = (plan.flags & kFlagAmbience) != 0;
        cache[index].is_live = true;
        stamp += 1;
    }

    SoundResult commit(HeldClip held, const PlayPlan& plan) {
        const std::uint64_t need = pcm_bytes_of(held.frames, held.channels);
        const int slot = reserve_index(need);
        if (slot < 0) return core::fail(core::ErrorCode::kExhausted, "hết chỗ mẫu âm thanh");
        const auto index = static_cast<std::uint32_t>(slot);
        note_cached(index, held, plan);
        pcm_bytes += need;
        Order order = make_order(plan);
        order.clip_index = index;
        order.generation = cache[index].generation;
        order.frames = held.frames;
        order.channels = held.channels;
        order.samples = held.samples.get();
        clips[index].owned = std::move(held.samples);
        clips[index].users.fetch_add(1, std::memory_order_acq_rel);
        last_accepted = false;
        const SlotRelease release{.index = index, .bytes = need};
        if (!push(order)) {
            drop_slot(release);
            return core::fail(core::ErrorCode::kExhausted, "hàng lệnh âm thanh đầy");
        }
        if (is_live || last_accepted) return order.sound_id;
        drop_slot(release);
        return core::fail(core::ErrorCode::kExhausted, "không còn tiếng nào để chiếm");
    }

    SoundResult play_encoded_key(std::span<const std::byte> bytes, const PlayPlan& plan) {
        const int cached = find_key(plan.key);
        if (cached >= 0) return play_cached(cached, plan);
        const core::Result<detail::Decoded> decoded = decode_any(bytes);
        if (!decoded) return std::unexpected(decoded.error());
        return commit(clip_of(*decoded), plan);
    }

    SoundResult play_named(std::string_view name, const PlayPlan& plan) {
        if (!opened) return core::fail(core::ErrorCode::kInvalidState, "bộ âm thanh chưa mở");
        const core::Result<std::string> relative = resolve(name);
        if (!relative) return std::unexpected(relative.error());
        PlayPlan keyed = plan;
        keyed.key = *relative;
        const int cached = find_key(keyed.key);
        if (cached >= 0) return play_cached(cached, keyed);
        const std::filesystem::path full = root / io::path_from_utf8(*relative);
        const core::Result<std::vector<std::byte>> bytes = read_sound(full);
        if (!bytes) return std::unexpected(bytes.error());
        return play_encoded_key(*bytes, keyed);
    }

    core::Status play_music_span(std::span<const std::byte> bytes, float fade) {
        if (!opened) return core::fail(core::ErrorCode::kInvalidState, "bộ âm thanh chưa mở");
        if (bytes.empty()) return core::fail(core::ErrorCode::kCorrupt, "nhạc rỗng");
        if (!decks.is_threaded()) decks.pump();
        const int deck = decks.load(bytes);
        if (deck < 0) return core::fail(core::ErrorCode::kBusy, "đang phát và đã có bài chờ");
        Order order;
        order.kind = OrderKind::kMusic;
        order.deck = static_cast<std::uint8_t>(deck);
        order.fade_seconds = fade;
        if (push(order)) return core::ok();
        decks.release(static_cast<std::uint32_t>(deck));
        return core::fail(core::ErrorCode::kExhausted, "hàng lệnh âm thanh đầy");
    }

    void prepare_output() {
        output.reset();
        if (device.rate == kSampleRate) return;
        const RateChange change{.source_rate = kSampleRate, .target_rate = device.rate, .channels = 2};
        output.emplace(change);
        output->reserve(kBlockFrames);
    }

    // Không có loa thì vẫn mở: lệnh được áp thẳng, client chạy tiếp không tiếng.
    core::Status open_with(const OpenRequest& request) {
        root = request.data_root;
        load_table();
        opened = true;
        if (!request.use_device) return core::ok();
        const core::Status ready = detail::device_open(device, &Body::fill_device, this);
        if (!ready) return core::ok();
        prepare_output();
        decks.start();
        is_live = true;
        const core::Status started = detail::device_start(device);
        device_open = started.has_value();
        if (device_open) return core::ok();
        detail::device_close(device);
        is_live = false;
        decks.stop();
        return core::ok();
    }

    std::uint32_t clip_count() const noexcept {
        const auto is_loaded = [](const Clip& clip) { return clip.samples.load(std::memory_order_acquire) != nullptr; };
        return static_cast<std::uint32_t>(std::ranges::count_if(clips, is_loaded));
    }

    Stats read_stats() const noexcept {
        Stats stats;
        stats.callbacks = stat_callbacks.load(std::memory_order_relaxed);
        stats.frames = stat_frames.load(std::memory_order_relaxed);
        stats.music_starved = stat_starved.load(std::memory_order_relaxed);
        stats.largest_burst = stat_burst.load(std::memory_order_relaxed);
        stats.voices = stat_voices.load(std::memory_order_relaxed);
        stats.device_rate = device_open ? device.rate : 0;
        stats.peak = stat_peak.load(std::memory_order_relaxed);
        stats.deepest_limit = stat_limit.load(std::memory_order_relaxed);
        return stats;
    }
};

std::string describe(const Stats& stats) {
    const std::string device = std::format("thiết bị {} Hz, {} lần gọi, khối lớn nhất {} khung", stats.device_rate,
        stats.callbacks, stats.largest_burst);
    const std::string health = std::format("hụt {} khung nhạc, đỉnh {:.2f}, ép thấp nhất {:.2f}", stats.music_starved,
        stats.peak, stats.deepest_limit);
    return device + ", " + health;
}

Engine::Engine() = default;

Engine::Engine(Engine&&) noexcept = default;

Engine& Engine::operator=(Engine&&) noexcept = default;

Engine::~Engine() {
    close();
}

core::Status Engine::open(const OpenRequest& request) {
    if (body_) return core::fail(core::ErrorCode::kAlreadyExists, "bộ âm thanh đã mở");
    auto created = std::make_unique<Body>();
    const core::Status started = created->open_with(request);
    if (!started) return std::unexpected(started.error());
    body_ = std::move(created);
    return core::ok();
}

void Engine::close() noexcept {
    if (!body_) return;
    body_->shutdown();
    body_.reset();
}

bool Engine::is_open() const noexcept {
    return body_ != nullptr && body_->opened;
}

bool Engine::device_is_open() const noexcept {
    return body_ != nullptr && body_->device_open;
}

void Engine::set_listener(const Ear& ear) {
    if (!body_) return;
    Order order;
    order.kind = OrderKind::kListener;
    order.x = clamp_world(ear.x);
    order.y = clamp_world(ear.y);
    order.z = clamp_world(ear.z);
    order.forward_x = ear.forward_x;
    order.forward_y = ear.forward_y;
    order.forward_z = ear.forward_z;
    order.up_x = ear.up_x;
    order.up_y = ear.up_y;
    order.up_z = ear.up_z;
    order.listener_vx = ear.velocity_x;
    order.listener_vy = ear.velocity_y;
    order.listener_vz = ear.velocity_z;
    static_cast<void>(body_->push(order));
}

void Engine::set_effect_gain(float gain) {
    if (!body_) return;
    Order order;
    order.kind = OrderKind::kEffectGain;
    order.gain = unit_gain(gain);
    static_cast<void>(body_->push(order));
}

void Engine::set_music_gain(float gain) {
    if (!body_) return;
    Order order;
    order.kind = OrderKind::kMusicGain;
    order.gain = unit_gain(gain);
    static_cast<void>(body_->push(order));
}

core::Status Engine::play_music(std::string_view name, float fade_seconds) {
    if (!body_) return core::fail(core::ErrorCode::kInvalidState, "bộ âm thanh chưa mở");
    const core::Result<std::string> relative = body_->resolve(name);
    if (!relative) return std::unexpected(relative.error());
    const std::filesystem::path full = body_->root / io::path_from_utf8(*relative);
    const core::Result<std::vector<std::byte>> bytes = read_sound(full);
    if (!bytes) return std::unexpected(bytes.error());
    return body_->play_music_span(*bytes, fade_seconds);
}

core::Status Engine::play_music_bytes(const MusicBytes& music) {
    if (!body_) return core::fail(core::ErrorCode::kInvalidState, "bộ âm thanh chưa mở");
    return body_->play_music_span(music.bytes, music.fade_seconds);
}

void Engine::stop_music(float fade_seconds) {
    if (!body_) return;
    Order order;
    order.kind = OrderKind::kMusicStop;
    order.fade_seconds = fade_seconds;
    static_cast<void>(body_->push(order));
}

SoundResult Engine::play_flat(std::string_view name, float gain) {
    if (!body_) return core::fail(core::ErrorCode::kInvalidState, "bộ âm thanh chưa mở");
    PlayPlan plan;
    plan.cue.gain = gain;
    plan.cue.priority = kPriorityFlat;
    return body_->play_named(name, plan);
}

SoundResult Engine::play_spatial(std::string_view name, const Cue& cue) {
    if (!body_) return core::fail(core::ErrorCode::kInvalidState, "bộ âm thanh chưa mở");
    PlayPlan plan;
    plan.cue = cue;
    plan.flags = kFlagSpatial;
    if (plan.cue.priority == kPriorityFlat) plan.cue.priority = kPrioritySpatial;
    return body_->play_named(name, plan);
}

SoundResult Engine::play_pcm(const PcmView& view) {
    if (!body_) return core::fail(core::ErrorCode::kInvalidState, "bộ âm thanh chưa mở");
    if (view.channels == 0 || view.channels > 2) {
        return core::fail(core::ErrorCode::kUnsupported, "chỉ nhận một hoặc hai kênh");
    }
    if (view.samples.empty() || view.samples.size() % view.channels != 0) {
        return core::fail(core::ErrorCode::kCorrupt, "mẫu âm thanh rỗng");
    }
    const auto frames = static_cast<std::uint32_t>(view.samples.size() / view.channels);
    HeldClip held;
    // Số mẫu theo view, không phải mảng cố định.
    // NOLINTNEXTLINE(cppcoreguidelines-avoid-c-arrays, modernize-avoid-c-arrays)
    held.samples = std::make_unique<std::int16_t[]>(view.samples.size());
    std::ranges::copy(view.samples, held.samples.get());
    held.frames = frames;
    held.channels = view.channels;
    PlayPlan plan;
    plan.cue = view.cue;
    if (view.is_spatial) plan.flags = kFlagSpatial;
    return body_->commit(std::move(held), plan);
}

SoundResult Engine::play_encoded(const EncodedView& view) {
    if (!body_) return core::fail(core::ErrorCode::kInvalidState, "bộ âm thanh chưa mở");
    PlayPlan plan;
    plan.cue = view.cue;
    return body_->play_encoded_key(view.bytes, plan);
}

SoundResult Engine::add_ambience(std::string_view name, const AmbienceCue& cue) {
    if (!body_) return core::fail(core::ErrorCode::kInvalidState, "bộ âm thanh chưa mở");
    PlayPlan plan;
    plan.cue = cue.cue;
    plan.cue.priority = kPriorityAmbience;
    plan.interval = cue.interval_seconds;
    plan.flags = static_cast<std::uint8_t>(kFlagSpatial | kFlagAmbience);
    if (cue.interval_seconds <= 0.F) {
        plan.cue.is_loop = true;
        plan.flags = kFlagSpatial;
        plan.interval = 0.F;
    }
    return body_->play_named(name, plan);
}

void Engine::stop(SoundId sound_id) {
    if (!body_) return;
    Order order;
    order.kind = OrderKind::kStop;
    order.sound_id = sound_id;
    static_cast<void>(body_->push(order));
}

void Engine::render(std::span<float> interleaved_stereo) {
    const bool is_live = body_ != nullptr && body_->is_live;
    if (body_ == nullptr || is_live) {
        zero_span(interleaved_stereo);
        core::check(!is_live, "render chỉ gọi khi không mở thiết bị");
        return;
    }
    const auto frames = static_cast<std::uint32_t>(interleaved_stereo.size() / 2);
    body_->mix_span(interleaved_stereo.data(), frames);
}

MusicPhase Engine::music_phase() const noexcept {
    if (!body_) return MusicPhase::kNone;
    return static_cast<MusicPhase>(body_->phase_now.load(std::memory_order_relaxed));
}

float Engine::music_level() const noexcept {
    if (!body_) return 0.F;
    return body_->level_now.load(std::memory_order_relaxed);
}

std::uint32_t Engine::loaded_clips() const noexcept {
    if (!body_) return 0;
    return body_->clip_count();
}

Stats Engine::stats() const noexcept {
    if (!body_) return {};
    return body_->read_stats();
}

// NOLINTEND(cppcoreguidelines-pro-bounds-constant-array-index,
// cppcoreguidelines-pro-bounds-pointer-arithmetic)

} // namespace game::audio
