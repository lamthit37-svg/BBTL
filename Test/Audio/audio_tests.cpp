// Bộ trộn im (không thiết bị) phải đúng gain, fade theo số mẫu, chiếm tiếng và tắt sạch.
#include "audio/catalog.hpp"
#include "audio/engine.hpp"
#include "audio/gain.hpp"
#include "audio/limits.hpp"
#include "core/check.hpp"
#include "core/error.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <span>
#include <string_view>
#include <thread>
#include <vector>

namespace game::test {
namespace {

static_assert(__cplusplus >= 202302L, "dự án cần C++23");

using game::audio::Catalog;
using game::audio::distance_gain;
using game::audio::DistanceSpan;
using game::audio::doppler_rate;
using game::audio::Ear;
using game::audio::EncodedView;
using game::audio::Engine;
using game::audio::fade_in;
using game::audio::fade_out;
using game::audio::FadeSpan;
using game::audio::kButtonClickId;
using game::audio::kPriorityAmbience;
using game::audio::kPrioritySpatial;
using game::audio::kSampleRate;
using game::audio::kVoiceCap;
using game::audio::MusicBytes;
using game::audio::MusicPhase;
using game::audio::OpenRequest;
using game::audio::pan_of;
using game::audio::PcmView;
using game::audio::Place;
using game::audio::SoundResult;
using game::core::Error;
using game::core::ErrorCode;

struct Band {
    float low = 0.F;
    float high = 0.F;
};

struct SampleAt {
    std::uint32_t frame = 0;
    std::uint32_t channel = 0;
};

struct Tone {
    std::int16_t sample = 0;
    std::int32_t priority = game::audio::kPriorityFlat;
    bool is_loop = true;
    bool is_spatial = false;
    Place place{};
    DistanceSpan reach{.near_distance = 1.F, .far_distance = 100000.F};
};

void expect_inside(Context& context, float got, Band band, std::string_view what) {
    const bool is_inside = got >= band.low && got <= band.high;
    context.expect(is_inside, what);
}

float channel_at(std::span<const float> samples, SampleAt point) {
    const std::size_t base = static_cast<std::size_t>(point.frame) * 2;
    const std::size_t offset = base + point.channel;
    return samples[offset];
}

Engine silent_engine() {
    Engine engine;
    OpenRequest request;
    request.use_device = false;
    const game::core::Status opened = engine.open(request);
    game::core::check(opened.has_value(), "mở bộ trộn không thiết bị");
    return engine;
}

std::vector<float> render_frames(Engine& engine, std::uint32_t frames) {
    std::vector<float> mixed(static_cast<std::size_t>(frames) * 2);
    engine.render(mixed);
    return mixed;
}

SoundResult play_tone(Engine& engine, const Tone& tone) {
    std::array<std::int16_t, 4> samples{tone.sample, tone.sample, tone.sample, tone.sample};
    PcmView view;
    view.samples = samples;
    view.channels = 1;
    view.is_spatial = tone.is_spatial;
    view.cue.is_loop = tone.is_loop;
    view.cue.priority = tone.priority;
    view.cue.gain = 1.F;
    view.cue.place = tone.place;
    view.cue.reach = tone.reach;
    return engine.play_pcm(view);
}

struct Crowd {
    std::int16_t sample = 0;
    std::int32_t priority = game::audio::kPriorityFlat;
};

struct WavTone {
    std::int16_t sample = 0;
    std::uint32_t frames = 0;
};

void fill_voices(Engine& engine, Crowd crowd) {
    for (std::uint32_t index = 0; index < kVoiceCap; ++index) {
        Tone tone;
        tone.sample = crowd.sample;
        tone.priority = crowd.priority;
        const SoundResult played = play_tone(engine, tone);
        game::core::check(played.has_value(), "32 tiếng đầu phải vào");
    }
}

void push_u16(std::vector<std::byte>& bytes, std::uint16_t value) {
    bytes.push_back(static_cast<std::byte>(value & 0xffU));
    bytes.push_back(static_cast<std::byte>((value >> 8) & 0xffU));
}

void push_u32(std::vector<std::byte>& bytes, std::uint32_t value) {
    push_u16(bytes, static_cast<std::uint16_t>(value & 0xffffU));
    push_u16(bytes, static_cast<std::uint16_t>(value >> 16));
}

void push_text(std::vector<std::byte>& bytes, std::string_view text) {
    for (char letter : text)
        bytes.push_back(static_cast<std::byte>(letter));
}

void push_sample(std::vector<std::byte>& bytes, std::int16_t sample) {
    push_u16(bytes, static_cast<std::uint16_t>(sample));
}

std::vector<std::byte> constant_wav(WavTone tone) {
    const std::uint32_t data_bytes = tone.frames * 2;
    std::vector<std::byte> bytes;
    const std::size_t total = static_cast<std::size_t>(data_bytes) + 44;
    bytes.reserve(total);
    push_text(bytes, "RIFF");
    push_u32(bytes, 36 + data_bytes);
    push_text(bytes, "WAVEfmt ");
    push_u32(bytes, 16);
    push_u16(bytes, 1);
    push_u16(bytes, 1);
    push_u32(bytes, kSampleRate);
    push_u32(bytes, kSampleRate * 2);
    push_u16(bytes, 2);
    push_u16(bytes, 16);
    push_text(bytes, "data");
    push_u32(bytes, data_bytes);
    for (std::uint32_t index = 0; index < tone.frames; ++index)
        push_sample(bytes, tone.sample);
    return bytes;
}

[[maybe_unused]] float peak_of(std::span<const float> samples) {
    float peak = 0.F;
    for (const float sample : samples) {
        const float magnitude = std::fabs(sample);
        peak = std::max(peak, magnitude);
    }
    return peak;
}

void rolloff_is_linear(Context& context) {
    const DistanceSpan span{.near_distance = 100.F, .far_distance = 5000.F};
    const float near = distance_gain(100.F, span);
    const float mid = distance_gain(2550.F, span);
    const float far = distance_gain(5000.F, span);
    context.expect(near == 1.F, "sát gần là 1");
    context.expect(far == 0.F, "tới xa là 0");
    const Band mid_band{.low = 0.49F, .high = 0.51F};
    expect_inside(context, mid, mid_band, "giữa đường là nửa");
}

void equal_reach_is_safe(Context& context) {
    const DistanceSpan span{.near_distance = 10.F, .far_distance = 10.F};
    const float at_near = distance_gain(10.F, span);
    const float at_next = distance_gain(11.F, span);
    context.expect(at_near == 1.F, "đúng mép gần là 1");
    context.expect(at_next == 0.F, "thêm 1 là hết");
    context.expect(at_near == at_near, "không phải NaN");
}

void fade_zero_is_instant(Context& context) {
    const FadeSpan instant{};
    const float risen = fade_in(instant);
    const float fallen = fade_out(instant);
    context.expect(risen == 1.F, "fade vào 0 giây là mức đầy");
    context.expect(fallen == 0.F, "fade ra 0 giây là tắt");
}

void pan_center_and_right(Context& context) {
    const Ear ear{};
    Place front;
    front.z = -100.F;
    const game::audio::Stereo center = pan_of(ear, front);
    const float delta = std::fabs(center.left - center.right);
    context.expect(delta < 0.001F, "phía trước hai tai bằng nhau");
    Place right_place;
    right_place.x = 1000.F;
    const game::audio::Stereo side = pan_of(ear, right_place);
    context.expect(side.left < 0.001F, "nguồn bên phải tắt tai trái");
    context.expect(side.right > 0.99F, "nguồn bên phải đầy tai phải");
}

void doppler_hears_motion(Context& context) {
    const Ear still_ear{};
    Place still;
    still.z = -1000.F;
    const float parked = doppler_rate(still_ear, still);
    const Band parked_band{.low = 0.999F, .high = 1.001F};
    expect_inside(context, parked, parked_band, "đứng yên thì tỷ lệ 1");
    Place coming = still;
    coming.velocity_z = 1000.F;
    const float faster = doppler_rate(still_ear, coming);
    context.expect(faster > 1.F, "nguồn lao tới thì cao hơn 1");
    Ear moving = still_ear;
    moving.velocity_z = -1000.F;
    const float chasing = doppler_rate(moving, still);
    context.expect(chasing > 1.F, "tai lao tới nguồn thì cao hơn 1");
}

void flat_reaches_full_scale(Context& context) {
    Engine engine = silent_engine();
    Tone tone;
    tone.sample = 32767;
    const SoundResult played = play_tone(engine, tone);
    context.expect(played.has_value(), "phát 2D");
    const std::vector<float> mixed = render_frames(engine, 128);
    const float left = channel_at(mixed, SampleAt{.frame = 127, .channel = 0});
    const float right = channel_at(mixed, SampleAt{.frame = 127, .channel = 1});
    const Band full{.low = 0.97F, .high = 1.F};
    expect_inside(context, left, full, "kênh trái đầy");
    expect_inside(context, right, full, "kênh phải đầy");
}

void spatial_goes_right(Context& context) {
    Engine engine = silent_engine();
    Tone tone;
    tone.sample = 32767;
    tone.is_spatial = true;
    tone.priority = kPrioritySpatial;
    tone.place.x = 1000.F;
    tone.reach.near_distance = 1.F;
    tone.reach.far_distance = 100000.F;
    const SoundResult played = play_tone(engine, tone);
    context.expect(played.has_value(), "phát 3D");
    const std::vector<float> mixed = render_frames(engine, 128);
    const float left = channel_at(mixed, SampleAt{.frame = 127, .channel = 0});
    const float right = channel_at(mixed, SampleAt{.frame = 127, .channel = 1});
    const float left_level = std::fabs(left);
    context.expect(left_level < 0.02F, "tai trái gần như tắt");
    const Band right_band{.low = 0.95F, .high = 1.F};
    expect_inside(context, right, right_band, "tai phải gần đầy");
}

void loop_keeps_fourth_sample(Context& context) {
    Engine engine = silent_engine();
    std::array<std::int16_t, 4> samples{1000, 2000, 3000, 4000};
    PcmView view;
    view.samples = samples;
    view.cue.is_loop = true;
    const SoundResult played = engine.play_pcm(view);
    context.expect(played.has_value(), "phát vòng");
    const std::vector<float> mixed = render_frames(engine, 8);
    const float got = channel_at(mixed, SampleAt{.frame = 7, .channel = 0});
    const float want = (4000.F / 32768.F) * (7.F / 64.F);
    const float low = want - 0.002F;
    const float high = want + 0.002F;
    const Band band{.low = low, .high = high};
    expect_inside(context, got, band, "mẫu thứ tư còn sau khi lặp");
    context.expect(got > 0.01F, "attack làm nhỏ nhưng chưa tắt");
}

void oneshot_ends(Context& context) {
    Engine engine = silent_engine();
    std::array<std::int16_t, 4> samples{1000, 2000, 3000, 4000};
    PcmView view;
    view.samples = samples;
    view.cue.is_loop = false;
    const SoundResult played = engine.play_pcm(view);
    context.expect(played.has_value(), "phát một lần");
    const std::vector<float> mixed = render_frames(engine, 8);
    const float got = channel_at(mixed, SampleAt{.frame = 7, .channel = 0});
    context.expect(got == 0.F, "hết mẫu thì im");
}

void steal_replaces_quiet(Context& context) {
    Engine engine = silent_engine();
    const Crowd quiet{.sample = 100, .priority = kPriorityAmbience};
    fill_voices(engine, quiet);
    Tone loud;
    loud.sample = 8000;
    loud.priority = kPrioritySpatial;
    const SoundResult played = play_tone(engine, loud);
    context.expect(played.has_value(), "tiếng quan trọng chiếm chỗ");
    const std::vector<float> mixed = render_frames(engine, 128);
    const float got = channel_at(mixed, SampleAt{.frame = 127, .channel = 0});
    const float want = ((31.F * 100.F) + 8000.F) / 32768.F;
    const float low = want - 0.02F;
    const float high = want + 0.02F;
    const Band band{.low = low, .high = high};
    expect_inside(context, got, band, "đã thế chỗ tiếng yếu");
}

void full_important_rejects(Context& context) {
    Engine engine = silent_engine();
    const Crowd loud{.sample = 100, .priority = kPrioritySpatial};
    fill_voices(engine, loud);
    Tone weak;
    weak.sample = 8000;
    weak.priority = kPriorityAmbience;
    const SoundResult played = play_tone(engine, weak);
    context.expect(!played.has_value(), "tiếng yếu hơn thì bị từ chối");
    if (!played) {
        const Error& fault = played.error();
        context.expect(fault.code() == ErrorCode::kExhausted, "mã hết chỗ");
    }
    const std::vector<float> mixed = render_frames(engine, 128);
    const float got = channel_at(mixed, SampleAt{.frame = 127, .channel = 0});
    const float want = (32.F * 100.F) / 32768.F;
    const float low = want - 0.01F;
    const float high = want + 0.01F;
    const Band band{.low = low, .high = high};
    expect_inside(context, got, band, "các tiếng cũ giữ nguyên");
}

void music_fades_by_frames(Context& context) {
    Engine engine = silent_engine();
    const WavTone tone{.sample = 10000, .frames = 4800};
    const std::vector<std::byte> wav = constant_wav(tone);
    MusicBytes music;
    music.bytes = wav;
    music.fade_seconds = 1.F;
    const game::core::Status started = engine.play_music_bytes(music);
    context.expect(started.has_value(), "nhận nhạc");
    const std::vector<float> mixed = render_frames(engine, 4800);
    const float first = channel_at(mixed, SampleAt{.frame = 0, .channel = 0});
    const float late = channel_at(mixed, SampleAt{.frame = 4700, .channel = 0});
    context.expect(first < 0.02F, "khung đầu còn nhỏ");
    const Band late_band{.low = 0.02F, .high = 0.05F};
    expect_inside(context, late, late_band, "gần cuối một giây thì khoảng 0.03");
    const float level = engine.music_level();
    const Band level_band{.low = 0.08F, .high = 0.12F};
    expect_inside(context, level, level_band, "mức nhạc khoảng 0.1");
    context.expect(engine.music_phase() == MusicPhase::kFadeIn, "đang fade vào");
}

void music_fade_zero_is_full(Context& context) {
    Engine engine = silent_engine();
    const WavTone tone{.sample = 10000, .frames = 256};
    const std::vector<std::byte> wav = constant_wav(tone);
    MusicBytes music;
    music.bytes = wav;
    music.fade_seconds = 0.F;
    const game::core::Status started = engine.play_music_bytes(music);
    context.expect(started.has_value(), "nhận nhạc tức thì");
    const std::vector<float> mixed = render_frames(engine, 256);
    const float got = channel_at(mixed, SampleAt{.frame = 128, .channel = 0});
    const Band full{.low = 0.28F, .high = 0.33F};
    expect_inside(context, got, full, "biên độ đầy sau fade 0");
    context.expect(engine.music_phase() == MusicPhase::kPlay, "đang phát");
    const float level = engine.music_level();
    const Band level_band{.low = 0.99F, .high = 1.01F};
    expect_inside(context, level, level_band, "mức 1");
}

void first_name_wins(Context& context) {
    constexpr std::string_view kTable = "<root><item name=\"a\" value=\"data\\one.wav\"/>"
                                        "<item name=\"a\" value=\"data\\two.wav\"/>"
                                        "<item name=\"b\" value=\"data\\three.wav\"/></root>";
    Catalog catalog;
    const game::core::Status loaded = catalog.load(kTable);
    context.expect(loaded.has_value(), "bảng hợp lệ");
    context.expect(catalog.find("a") == "data\\one.wav", "tên lặp giữ mục đầu");
    context.expect(catalog.size() == 2, "hai tên");
}

void garbage_does_not_cache(Context& context) {
    Engine engine = silent_engine();
    std::array<std::byte, 16> junk{};
    EncodedView view;
    view.bytes = junk;
    const SoundResult played = engine.play_encoded(view);
    context.expect(!played.has_value(), "byte rác không phát");
    context.expect(engine.loaded_clips() == 0, "rác không vào cache");
}

void shutdown_is_quiet(Context& context) {
    Engine engine;
    OpenRequest request;
    request.use_device = false;
    const game::core::Status opened = engine.open(request);
    context.expect(opened.has_value(), "mở lần đầu");
    engine.close();
    std::array<float, 8> block{};
    block.fill(1.F);
    engine.render(block);
    context.expect(block[0] == 0.F, "sau khi đóng thì render im");
    engine.close();
    const SoundResult played = engine.play_flat(kButtonClickId, 1.F);
    context.expect(!played.has_value(), "phát sau khi đóng là lỗi");
    if (played) return;
    const Error& fault = played.error();
    context.expect(fault.code() == ErrorCode::kInvalidState, "chưa mở");
}

void listener_clamps_world(Context& context) {
    Engine engine = silent_engine();
    Ear ear;
    ear.x = 20000000.F;
    engine.set_listener(ear);
    Tone tone;
    tone.sample = 32767;
    tone.is_spatial = true;
    tone.place.x = 10000000.F;
    tone.reach.near_distance = 0.F;
    tone.reach.far_distance = 100.F;
    const SoundResult played = play_tone(engine, tone);
    context.expect(played.has_value(), "phát để đo tai");
    const std::vector<float> mixed = render_frames(engine, 128);
    const float left = channel_at(mixed, SampleAt{.frame = 127, .channel = 0});
    context.expect(left > 0.5F, "tai bị kẹp nên nguồn vẫn nghe");
}

// Nhạc có mẫu đổi liên tục, để một khung thiếu hay lệch là thấy ngay.
std::vector<std::byte> ramp_wav(std::uint32_t frames) {
    const WavTone shape{.sample = 0, .frames = frames};
    std::vector<std::byte> bytes = constant_wav(shape);
    bytes.resize(44);
    for (std::uint32_t index = 0; index < frames; ++index) {
        const std::uint32_t step = (index * 37U) % 20000U;
        push_sample(bytes, static_cast<std::int16_t>(static_cast<std::int32_t>(step) - 10000));
    }
    return bytes;
}

// Dựng cùng một nội dung, mỗi lần gọi render xin burst khung như thiết bị xin.
std::vector<float> render_in_bursts(std::uint32_t burst) {
    Engine engine = silent_engine();
    const std::vector<std::byte> wav = ramp_wav(5000);
    MusicBytes music;
    music.bytes = wav;
    game::core::check(engine.play_music_bytes(music).has_value(), "nhận nhạc");
    Tone tone;
    tone.sample = 3000;
    game::core::check(play_tone(engine, tone).has_value(), "phát tiếng lặp");
    constexpr std::uint32_t kTotal = 4104 * 4;
    std::vector<float> mixed(static_cast<std::size_t>(kTotal) * 2);
    const std::span<float> all(mixed);
    for (std::uint32_t done = 0; done < kTotal; done += burst) {
        const std::uint32_t count = std::min(burst, kTotal - done);
        engine.render(all.subspan(std::size_t{done} * 2, std::size_t{count} * 2));
    }
    return mixed;
}

// Tablet GE8320 xin 4104 khung mỗi lần, PC xin 480. Bản trước hụt 8 khung mỗi lần trên tablet.
void burst_size_does_not_change_the_mix(Context& context) {
    const std::vector<float> small = render_in_bursts(256);
    const std::vector<float> desktop = render_in_bursts(480);
    const std::vector<float> tablet = render_in_bursts(4104);
    context.expect(small == desktop, "480 khung mỗi lần cho đúng từng mẫu như 256");
    context.expect(small == tablet, "4104 khung mỗi lần cho đúng từng mẫu như 256");
    const auto is_zero = [](float sample) { return sample == 0.F; };
    const auto zeros = std::ranges::count_if(std::span<const float>(tablet).subspan(512), is_zero);
    context.expect(zeros == 0, "không khung nào bị bỏ trống");
}

void stopped_loop_frees_its_voice(Context& context) {
    Engine engine = silent_engine();
    Tone tone;
    tone.sample = 3000;
    const SoundResult played = play_tone(engine, tone);
    context.expect(played.has_value(), "phát tiếng lặp");
    if (!played) return;
    static_cast<void>(render_frames(engine, 128));
    context.expect(engine.stats().voices == 1, "một tiếng đang sống");
    engine.stop(*played);
    const std::vector<float> mixed = render_frames(engine, 256);
    context.expect(engine.stats().voices == 0, "dừng xong thì trả chỗ");
    context.expect(channel_at(mixed, SampleAt{.frame = 255, .channel = 0}) == 0.F, "đã im");
}

// Ba tiếng đầy thang cộng lại gấp ba trần: phải bị kéo xuống trần, số đo ghi lại mức ép.
void overload_is_limited(Context& context) {
    Engine engine = silent_engine();
    Tone tone;
    tone.sample = 32767;
    for (int voice = 0; voice < 3; ++voice) {
        game::core::check(play_tone(engine, tone).has_value(), "phát tiếng đầy thang");
    }
    const std::vector<float> mixed = render_frames(engine, 256);
    const float got = channel_at(mixed, SampleAt{.frame = 255, .channel = 0});
    const Band ceiling{.low = 0.98F, .high = 0.99F};
    expect_inside(context, got, ceiling, "tổng nằm ở trần của bộ hạn biên");
    const game::audio::Stats stats = engine.stats();
    const Band tripled{.low = 2.9F, .high = 3.01F};
    expect_inside(context, stats.peak, tripled, "đỉnh trước khi ép là ba lần");
    const Band third{.low = 0.32F, .high = 0.34F};
    expect_inside(context, stats.deepest_limit, third, "hệ số ép khoảng một phần ba");
    context.expect(stats.frames == 256, "đếm đủ số khung đã trộn");
}

void client_files_decode(Context& context) {
#ifndef GAME_CLIENT_DATA
    context.expect(true, "không có thư mục data trong bản build này");
#else
    Engine engine;
    OpenRequest request;
    request.data_root = GAME_CLIENT_DATA;
    request.use_device = false;
    const game::core::Status opened = engine.open(request);
    context.expect(opened.has_value(), "mở được thư mục data");
    if (!opened) return;
    const game::core::Status music = engine.play_music(game::audio::kLoginMusicId, 0.F);
    context.expect(music.has_value(), "phát được nhạc đăng nhập");
    const SoundResult effect = engine.play_flat(kButtonClickId, 1.F);
    context.expect(effect.has_value(), "phát được tiếng bấm nút");
    // click_common_1.wav dài khoảng 0,05 giây. Render đủ để gặp tiếng click.
    const std::vector<float> mixed = render_frames(engine, 12000);
    const float peak = peak_of(mixed);
    context.expect(peak > 0.2F, "nhạc hoặc hiệu ứng có mẫu");
#endif
}

void device_reports(Context& context) {
    Engine engine;
    OpenRequest request;
    request.use_device = true;
#ifdef GAME_CLIENT_DATA
    request.data_root = GAME_CLIENT_DATA;
#else
    request.data_root = ".";
#endif
    const game::core::Status opened = engine.open(request);
    context.expect(opened.has_value(), "lỗi thiết bị không làm hỏng open");
    if (!opened) return;
    const bool is_live = engine.device_is_open();
    if (!is_live) static_cast<void>(std::fputs("âm thanh: thiết bị không mở\n", stdout));
    if (!is_live) return;
    static_cast<void>(std::fputs("âm thanh: thiết bị mở\n", stdout));
#ifdef GAME_CLIENT_DATA
    static_cast<void>(engine.play_music(game::audio::kLoginMusicId, 0.F));
    static_cast<void>(engine.play_flat(kButtonClickId, 1.F));
#endif
    std::this_thread::sleep_for(std::chrono::milliseconds(400));
    engine.close();
}

constexpr std::array kCases{
    Case{.name = "rolloff_is_linear", .body = &rolloff_is_linear},
    Case{.name = "equal_reach_is_safe", .body = &equal_reach_is_safe},
    Case{.name = "fade_zero_is_instant", .body = &fade_zero_is_instant},
    Case{.name = "pan_center_and_right", .body = &pan_center_and_right},
    Case{.name = "doppler_hears_motion", .body = &doppler_hears_motion},
    Case{.name = "flat_reaches_full_scale", .body = &flat_reaches_full_scale},
    Case{.name = "spatial_goes_right", .body = &spatial_goes_right},
    Case{.name = "loop_keeps_fourth_sample", .body = &loop_keeps_fourth_sample},
    Case{.name = "oneshot_ends", .body = &oneshot_ends},
    Case{.name = "steal_replaces_quiet", .body = &steal_replaces_quiet},
    Case{.name = "full_important_rejects", .body = &full_important_rejects},
    Case{.name = "music_fades_by_frames", .body = &music_fades_by_frames},
    Case{.name = "music_fade_zero_is_full", .body = &music_fade_zero_is_full},
    Case{.name = "first_name_wins", .body = &first_name_wins},
    Case{.name = "garbage_does_not_cache", .body = &garbage_does_not_cache},
    Case{.name = "shutdown_is_quiet", .body = &shutdown_is_quiet},
    Case{.name = "listener_clamps_world", .body = &listener_clamps_world},
    Case{.name = "burst_size_does_not_change_the_mix",
        .body = &burst_size_does_not_change_the_mix},
    Case{.name = "stopped_loop_frees_its_voice", .body = &stopped_loop_frees_its_voice},
    Case{.name = "overload_is_limited", .body = &overload_is_limited},
    Case{.name = "client_files_decode", .body = &client_files_decode},
    Case{.name = "device_reports", .body = &device_reports},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "audio_tests: mọi ca phải qua");
    return 0;
}
