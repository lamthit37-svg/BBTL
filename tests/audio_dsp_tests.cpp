// Test của phần xử lý tín hiệu trong audio, không cần thiết bị. Bộ đổi tần số phải giữ một sin
// thuần là sin thuần: phần không phải sin (ảnh phổ gập về, méo) đo bằng khớp bình phương tối thiểu
// và phải dưới -90 dB. Nội suy tuyến tính, thứ bộ này thay, cho -20 dB với sin 10 kHz ở 44,1 kHz.
#include "audio/detail/codec.hpp"
#include "audio/engine.hpp"
#include "audio/limiter.hpp"
#include "audio/limits.hpp"
#include "audio/pack.hpp"
#include "audio/resample.hpp"
#include "core/check.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <numbers>
#include <span>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using game::audio::EncodedView;
using game::audio::Engine;
using game::audio::Limiter;
using game::audio::MusicBytes;
using game::audio::OpenRequest;
using game::audio::RateChange;
using game::audio::resample_all;
using game::audio::Resampler;

constexpr double kTurn = 2.0 * std::numbers::pi;
constexpr double kAmplitude = 0.5;
constexpr std::size_t kSecond = 44100;
constexpr std::uint32_t kBlock = 256;

struct Wave {
    std::uint32_t rate = 44100;
    double hertz = 1000.0;
    std::size_t frames = 0;
};

[[nodiscard]] std::vector<float> tone_of(Wave wave) {
    std::vector<float> samples(wave.frames);
    const double step = kTurn * wave.hertz / static_cast<double>(wave.rate);
    for (std::size_t frame = 0; frame < wave.frames; ++frame) {
        const double value = kAmplitude * std::sin(step * static_cast<double>(frame));
        samples[frame] = static_cast<float>(value);
    }
    return samples;
}

struct Fit {
    double gain = 0.0;
    double residual_db = 0.0;
};

struct Sums {
    double cos_cos = 0.0;
    double sin_sin = 0.0;
    double cos_sin = 0.0;
    double value_cos = 0.0;
    double value_sin = 0.0;
    double value_value = 0.0;
};

// Khớp a*cos + b*sin ở đúng tần số của sin gốc vào đoạn mẫu; phần dư là mọi thứ không phải nó.
[[nodiscard]] Fit fit_tone(std::span<const float> mono, double step) {
    Sums sums;
    for (std::size_t frame = 0; frame < mono.size(); ++frame) {
        const double angle = step * static_cast<double>(frame);
        const double wave_cos = std::cos(angle);
        const double wave_sin = std::sin(angle);
        const auto value = static_cast<double>(mono[frame]);
        sums.cos_cos += wave_cos * wave_cos;
        sums.sin_sin += wave_sin * wave_sin;
        sums.cos_sin += wave_cos * wave_sin;
        sums.value_cos += value * wave_cos;
        sums.value_sin += value * wave_sin;
        sums.value_value += value * value;
    }
    const double determinant = (sums.cos_cos * sums.sin_sin) - (sums.cos_sin * sums.cos_sin);
    const double along_cos = ((sums.value_cos * sums.sin_sin) - (sums.value_sin * sums.cos_sin)) / determinant;
    const double along_sin = ((sums.value_sin * sums.cos_cos) - (sums.value_cos * sums.cos_sin)) / determinant;
    const double fitted = (along_cos * sums.value_cos) + (along_sin * sums.value_sin);
    const double residual = std::max(sums.value_value - fitted, 1.0e-30);
    const double level = std::sqrt((along_cos * along_cos) + (along_sin * along_sin));
    return Fit{.gain = level / kAmplitude, .residual_db = 10.0 * std::log10(residual / fitted)};
}

struct Trial {
    std::uint32_t source_rate = 44100;
    std::uint32_t target_rate = 48000;
    double hertz = 1000.0;
};

// Nửa giây sin, đo ở nửa giữa của kết quả để tránh hai đầu (bộ lọc còn đang vào và ra).
[[nodiscard]] Fit measure(Trial trial) {
    const Wave wave{.rate = trial.source_rate, .hertz = trial.hertz, .frames = trial.source_rate / 2};
    const std::vector<float> source = tone_of(wave);
    const RateChange change{.source_rate = trial.source_rate, .target_rate = trial.target_rate, .channels = 1};
    const std::vector<float> made = resample_all(source, change);
    const std::span<const float> all(made);
    const std::span<const float> middle = all.subspan(made.size() / 4, made.size() / 2);
    const double step = kTurn * trial.hertz / static_cast<double>(trial.target_rate);
    return fit_tone(middle, step);
}

void expect_pure(Context& context, Trial trial) {
    const Fit fit = measure(trial);
    context.expect(fit.residual_db < -90.0, "phần không phải sin dưới -90 dB");
    context.expect(std::abs(20.0 * std::log10(fit.gain)) < 0.1, "biên độ lệch dưới 0,1 dB");
}

void music_rate_stays_pure(Context& context) {
    constexpr std::array<double, 5> kTones{1000.0, 5000.0, 10000.0, 15000.0, 19000.0};
    for (const double hertz : kTones) {
        expect_pure(context, Trial{.source_rate = 44100, .target_rate = 48000, .hertz = hertz});
    }
}

void effect_rate_stays_pure(Context& context) {
    constexpr std::array<double, 4> kTones{1000.0, 5000.0, 8000.0, 9500.0};
    for (const double hertz : kTones) {
        expect_pure(context, Trial{.source_rate = 22050, .target_rate = 48000, .hertz = hertz});
    }
    expect_pure(context, Trial{.source_rate = 11025, .target_rate = 48000, .hertz = 3000.0});
}

void output_rate_stays_pure(Context& context) {
    expect_pure(context, Trial{.source_rate = 48000, .target_rate = 44100, .hertz = 10000.0});
    expect_pure(context, Trial{.source_rate = 48000, .target_rate = 96000, .hertz = 15000.0});
}

// 44056 Hz (tần số NTSC cũ) không rút gọn được về ít pha: đi đường trộn hai hàng kề nhau.
void odd_rate_blends_rows(Context& context) {
    const Fit fit = measure(Trial{.source_rate = 44056, .target_rate = 48000, .hertz = 5000.0});
    context.expect(fit.residual_db < -80.0, "tỉ số lạ vẫn dưới -80 dB");
}

// Sin 30 kHz ở 96 kHz nằm trên Nyquist của 48 kHz: phải bị chặn, không được gập về 18 kHz.
void downsampling_blocks_the_fold(Context& context) {
    const std::vector<float> source = tone_of(Wave{.rate = 96000, .hertz = 30000.0, .frames = 48000});
    const RateChange change{.source_rate = 96000, .target_rate = 48000, .channels = 1};
    const std::vector<float> made = resample_all(source, change);
    const std::span<const float> all(made);
    const std::span<const float> middle = all.subspan(made.size() / 4, made.size() / 2);
    double energy = 0.0;
    for (const float value : middle) {
        energy += static_cast<double>(value) * static_cast<double>(value);
    }
    const double mean = energy / static_cast<double>(middle.size());
    const double reference = 0.5 * kAmplitude * kAmplitude;
    context.expect(10.0 * std::log10((mean + 1.0e-30) / reference) < -90.0, "30 kHz bị chặn 90 dB");
}

void frame_count_follows_the_ratio(Context& context) {
    const std::vector<float> second(kSecond, 1.F);
    const RateChange change{.source_rate = 44100, .target_rate = 48000, .channels = 1};
    const std::vector<float> made = resample_all(second, change);
    context.expect(made.size() == 48000, "một giây vào là một giây ra");
    context.expect(std::abs(made[24000] - 1.F) < 1.0e-4F, "mức một chiều giữ nguyên");
    const std::vector<float> one(1, 1.F);
    context.expect(resample_all(one, change).size() == 2, "một khung vào làm tròn lên hai khung ra");
}

struct Chunked {
    std::vector<float> made;
    bool kept_promise = true;
};

// Rút theo khối như bộ trộn: mỗi lần nạp đúng số khung needed() báo (hoặc hết nguồn).
void pull_block(Chunked& result, Resampler& resampler, std::span<const float>& left) {
    std::array<float, static_cast<std::size_t>(kBlock) * 2> block{};
    const std::size_t asked = resampler.needed(kBlock);
    const std::size_t frames = std::min(asked, left.size() / 2);
    resampler.push(left.first(frames * 2));
    left = left.subspan(frames * 2);
    const std::uint32_t got = resampler.pull(block);
    const bool is_full = frames < asked || got == kBlock;
    result.kept_promise = result.kept_promise && is_full;
    const std::span<const float> written = std::span<const float>(block).first(std::size_t{got} * 2);
    result.made.insert(result.made.end(), written.begin(), written.end());
}

void streaming_matches_one_shot(Context& context) {
    std::vector<float> stereo(kSecond * 2);
    const std::vector<float> left_tone = tone_of(Wave{.rate = 44100, .hertz = 440.0, .frames = kSecond});
    const std::vector<float> right_tone = tone_of(Wave{.rate = 44100, .hertz = 3000.0, .frames = kSecond});
    for (std::size_t frame = 0; frame < kSecond; ++frame) {
        stereo[frame * 2] = left_tone[frame];
        stereo[(frame * 2) + 1] = right_tone[frame];
    }
    const RateChange change{.source_rate = 44100, .target_rate = 48000, .channels = 2};
    const std::vector<float> whole = resample_all(stereo, change);
    Resampler resampler(change);
    Chunked chunked;
    std::span<const float> left(stereo);
    for (int block = 0; block < 180; ++block) {
        pull_block(chunked, resampler, left);
    }
    context.expect(chunked.kept_promise, "nạp đủ needed() thì pull trả đủ một khối");
    context.expect(chunked.made.size() >= kSecond * 2, "đã rút ít nhất 0,9 giây");
    const std::size_t shared = std::min(chunked.made.size(), whole.size());
    const std::span<const float> streamed = std::span<const float>(chunked.made).first(shared);
    const std::span<const float> at_once = std::span<const float>(whole).first(shared);
    context.expect(std::ranges::equal(streamed, at_once), "rút theo khối cho đúng từng mẫu");
}

[[nodiscard]] std::vector<float> both_ears(std::span<const float> mono, float scale) {
    std::vector<float> stereo(mono.size() * 2);
    for (std::size_t frame = 0; frame < mono.size(); ++frame) {
        stereo[frame * 2] = mono[frame] * scale;
        stereo[(frame * 2) + 1] = mono[frame] * scale;
    }
    return stereo;
}

[[nodiscard]] std::vector<float> left_ear(std::span<const float> stereo) {
    std::vector<float> mono(stereo.size() / 2);
    for (std::size_t frame = 0; frame < mono.size(); ++frame) {
        mono[frame] = stereo[frame * 2];
    }
    return mono;
}

void limiter_passes_quiet_untouched(Context& context) {
    const std::vector<float> tone = tone_of(Wave{.rate = 48000, .hertz = 1000.0, .frames = 4800});
    std::vector<float> stereo = both_ears(tone, 1.F);
    const std::vector<float> before = stereo;
    Limiter limiter;
    limiter.process(stereo);
    context.expect(stereo == before, "tín hiệu dưới trần đi qua nguyên vẹn từng bit");
    context.expect(limiter.gain() == 1.F && limiter.deepest() == 1.F, "không ép");
}

// Sin gấp đôi trần. Cắt cụt cho phần không phải sin khoảng -10 dB; bộ hạn biên phải giữ dạng sóng.
void limiter_keeps_the_wave_shape(Context& context) {
    const std::vector<float> tone = tone_of(Wave{.rate = 48000, .hertz = 1000.0, .frames = 24000});
    std::vector<float> stereo = both_ears(tone, 4.F);
    Limiter limiter;
    limiter.process(stereo);
    const auto [low, high] = std::ranges::minmax_element(stereo);
    const float ceiling = game::audio::kLimiterCeiling + 1.0e-6F;
    context.expect(*low >= -ceiling && *high <= ceiling, "không mẫu nào vượt trần");
    const std::vector<float> mono = left_ear(stereo);
    const std::span<const float> settled = std::span<const float>(mono).subspan(12000);
    const Fit fit = fit_tone(settled, kTurn * 1000.0 / 48000.0);
    context.expect(fit.residual_db < -80.0, "sau khi ép vẫn là sin thuần");
    const double level = fit.gain * kAmplitude;
    context.expect(std::abs(level - 0.985) < 0.005, "biên độ nằm ở trần");
}

void limiter_lets_go_after_the_burst(Context& context) {
    const std::vector<float> tone = tone_of(Wave{.rate = 48000, .hertz = 500.0, .frames = 96000});
    std::vector<float> stereo = both_ears(tone, 0.2F);
    for (std::size_t sample = 0; sample < 9600; ++sample) {
        stereo[sample] *= 20.F;
    }
    const std::vector<float> before = stereo;
    Limiter limiter;
    limiter.process(stereo);
    context.expect(limiter.deepest() < 0.6F, "đoạn to bị ép");
    context.expect(limiter.gain() == 1.F, "hai giây sau thì nhả hẳn");
    const std::span<const float> tail = std::span<const float>(stereo).last(4800);
    const std::span<const float> tail_before = std::span<const float>(before).last(4800);
    context.expect(std::ranges::equal(tail, tail_before), "đoạn cuối lại nguyên vẹn");
}

void put_u16(std::vector<std::byte>& bytes, std::uint32_t value) {
    bytes.push_back(static_cast<std::byte>(value & 0xffU));
    bytes.push_back(static_cast<std::byte>((value >> 8U) & 0xffU));
}

void put_u32(std::vector<std::byte>& bytes, std::uint32_t value) {
    put_u16(bytes, value & 0xffffU);
    put_u16(bytes, value >> 16U);
}

void put_text(std::vector<std::byte>& bytes, std::string_view text) {
    for (const char letter : text) {
        bytes.push_back(static_cast<std::byte>(letter));
    }
}

// WAV 16 bit một kênh chứa sin biên độ 0,5 ở tần số lấy mẫu của wave.
[[nodiscard]] std::vector<std::byte> wav_of(Wave wave) {
    const std::vector<float> tone = tone_of(wave);
    const auto data_bytes = static_cast<std::uint32_t>(tone.size() * 2);
    std::vector<std::byte> bytes;
    put_text(bytes, "RIFF");
    put_u32(bytes, 36 + data_bytes);
    put_text(bytes, "WAVEfmt ");
    put_u32(bytes, 16);
    put_u16(bytes, 1);
    put_u16(bytes, 1);
    put_u32(bytes, wave.rate);
    put_u32(bytes, wave.rate * 2);
    put_u16(bytes, 2);
    put_u16(bytes, 16);
    put_text(bytes, "data");
    put_u32(bytes, data_bytes);
    for (const float value : tone) {
        const auto sample = static_cast<std::int16_t>(std::lround(value * 32767.F));
        put_u16(bytes, static_cast<std::uint16_t>(sample));
    }
    return bytes;
}

[[nodiscard]] Engine silent_engine() {
    Engine engine;
    OpenRequest request;
    request.use_device = false;
    game::core::check(engine.open(request).has_value(), "mở bộ trộn không thiết bị");
    return engine;
}

// Nửa giây qua bộ phát, đo một phần tư giây ở giữa.
[[nodiscard]] Fit rendered_fit(Engine& engine, double hertz) {
    std::vector<float> mixed(48000);
    engine.render(mixed);
    const std::vector<float> mono = left_ear(mixed);
    const std::span<const float> middle = std::span<const float>(mono).subspan(6000, 12000);
    return fit_tone(middle, kTurn * hertz / 48000.0);
}

// Nhạc 44,1 kHz đi qua luồng giải mã, bộ đổi tần số theo khối và vòng đệm của bàn nhạc.
void engine_keeps_music_pure(Context& context) {
    Engine engine = silent_engine();
    const std::vector<std::byte> wav = wav_of(Wave{.rate = 44100, .hertz = 5000.0, .frames = 44100});
    MusicBytes music;
    music.bytes = wav;
    context.expect(engine.play_music_bytes(music).has_value(), "nhận nhạc 44,1 kHz");
    const Fit fit = rendered_fit(engine, 5000.0);
    context.expect(fit.residual_db < -80.0, "nhạc 44,1 kHz ra 48 kHz vẫn là sin thuần");
    context.expect(std::abs(20.0 * std::log10(fit.gain)) < 0.1, "đúng biên độ");
    context.expect(engine.stats().music_starved == 0, "bộ trộn không hụt khung nhạc nào");
}

// Hiệu ứng 22,05 kHz được đổi một lần lúc nạp rồi nằm trong bộ nhớ ở 48 kHz.
void engine_keeps_effects_pure(Context& context) {
    Engine engine = silent_engine();
    const std::vector<std::byte> wav = wav_of(Wave{.rate = 22050, .hertz = 5000.0, .frames = 22050});
    EncodedView view;
    view.bytes = wav;
    context.expect(engine.play_encoded(view).has_value(), "nhận hiệu ứng 22,05 kHz");
    const Fit fit = rendered_fit(engine, 5000.0);
    context.expect(fit.residual_db < -80.0, "hiệu ứng 22,05 kHz ra 48 kHz vẫn là sin thuần");
    context.expect(std::abs(20.0 * std::log10(fit.gain)) < 0.1, "đúng biên độ");
}

void pcm_pack_round_trips(Context& context) {
    constexpr std::array<std::int16_t, 6> kSamples{-32768, -1, 0, 1, 12345, 32767};
    const std::vector<std::byte> file = game::audio::write_pcm_pack(kSamples, 2);
    context.expect(game::audio::is_pack(file), "có dấu của tệp cook");
    const auto view = game::audio::read_pack(file);
    context.expect(view.has_value(), "đọc lại được");
    if (!view) return;
    context.expect(view->info.frames == 3 && view->info.channels == 2, "ba khung hai kênh");
    const auto decoded = game::audio::detail::decode_pack(file, 48000);
    context.expect(decoded.has_value(), "giải mã được");
    if (!decoded) return;
    context.expect(decoded->samples.size() == kSamples.size(), "đủ sáu mẫu");
    context.expect(decoded->samples.front() == -1.F, "-32768 về đúng -1");
    context.expect(decoded->samples[4] == 12345.F / 32768.F, "mẫu giữ đúng giá trị");
}

struct Poke {
    std::size_t at = 0;
    std::uint8_t value = 0;
};

// Bản chép của file với một byte bị đổi.
[[nodiscard]] std::vector<std::byte> with_byte(std::span<const std::byte> file, Poke poke) {
    game::core::check(poke.at < file.size(), "byte cần đổi phải nằm trong tệp");
    std::vector<std::byte> changed(file.begin(), file.end());
    const std::span<std::byte> view(changed);
    view[poke.at] = std::byte{poke.value};
    return changed;
}

void expect_corrupt(Context& context, std::span<const std::byte> file, std::string_view what) {
    const auto view = game::audio::read_pack(file);
    context.expect(!view.has_value(), what);
}

// Tệp đọc từ đĩa: mỗi trường sai phải thành lỗi, không phải thành đọc lố.
void broken_packs_are_rejected(Context& context) {
    constexpr std::array<std::int16_t, 4> kSamples{1, 2, 3, 4};
    const std::vector<std::byte> good = game::audio::write_pcm_pack(kSamples, 2);
    const std::span<const std::byte> all(good);
    expect_corrupt(context, all.first(10), "đầu tệp cụt");
    expect_corrupt(context, all.first(good.size() - 1), "vùng tải thiếu một byte");
    expect_corrupt(context, with_byte(good, Poke{.at = 0, .value = 0x58}), "sai dấu");
    expect_corrupt(context, with_byte(good, Poke{.at = 5, .value = 3}), "ba kênh");
    const std::vector<std::byte> huge = with_byte(good, Poke{.at = 15, .value = 0x7f});
    expect_corrupt(context, huge, "số khung vượt vùng tải");
    const std::vector<std::byte> fake_opus = with_byte(good, Poke{.at = 4, .value = 1});
    expect_corrupt(context, fake_opus, "khai Opus mà không có bảng gói");
}

// Một giây sin 1 kHz stereo qua Opus 160 kbit/s. Sin thuần là ca khó nhất của bộ mã biến đổi (đo:
// phần không phải sin -44 dB, nằm sát hai bên sin gốc); số khung thì phải đúng tuyệt đối.
void opus_keeps_length_and_tone(Context& context) {
    const std::vector<float> tone = tone_of(Wave{.rate = 48000, .hertz = 1000.0, .frames = 48000});
    const std::vector<float> stereo = both_ears(tone, 1.F);
    const game::audio::detail::OpusPlan plan{.channels = 2, .bitrate = 160000};
    const auto encoded = game::audio::detail::encode_opus(stereo, plan);
    if (!encoded) return;
    const std::vector<std::byte> file = game::audio::write_opus_pack(*encoded);
    context.expect(file.size() < 30000, "một giây dưới 30 KB");
    const auto decoded = game::audio::detail::decode_pack(file, 480000);
    context.expect(decoded.has_value(), "giải mã được");
    if (!decoded) return;
    context.expect(decoded->samples.size() == stereo.size(), "đúng 48000 khung");
    const std::vector<float> mono = left_ear(decoded->samples);
    const std::span<const float> middle = std::span<const float>(mono).subspan(12000, 24000);
    const Fit fit = fit_tone(middle, kTurn * 1000.0 / 48000.0);
    context.expect(fit.residual_db < -36.0, "sin vẫn là sin sau Opus");
    context.expect(std::abs(20.0 * std::log10(fit.gain)) < 0.3, "biên độ giữ trong 0,3 dB");
}

// Nhạc lặp: phần dẫn là đuôi của bài nên bộ giải mã đã hội tụ khi tới khung đầu. Đo quanh chỗ nối
// (0,9 tới 1,1 giây của bài dài một giây): một tiếng tách sẽ đẩy phần không phải sin lên hẳn.
void cooked_music_loops_without_a_click(Context& context) {
    const std::vector<float> tone = tone_of(Wave{.rate = 48000, .hertz = 1000.0, .frames = 48000});
    const std::vector<float> stereo = both_ears(tone, 1.F);
    const game::audio::detail::OpusPlan plan{.channels = 2, .bitrate = 160000, .is_loop = true};
    const auto encoded = game::audio::detail::encode_opus(stereo, plan);
    if (!encoded) return;
    const std::vector<std::byte> file = game::audio::write_opus_pack(*encoded);
    Engine engine = silent_engine();
    MusicBytes music;
    music.bytes = file;
    context.expect(engine.play_music_bytes(music).has_value(), "nhận nhạc cook");
    std::vector<float> mixed(std::size_t{72000} * 2);
    engine.render(mixed);
    const std::vector<float> mono = left_ear(mixed);
    const std::span<const float> seam = std::span<const float>(mono).subspan(43200, 9600);
    const Fit fit = fit_tone(seam, kTurn * 1000.0 / 48000.0);
    context.expect(fit.residual_db < -36.0, "qua chỗ nối vòng vẫn là sin liền");
    context.expect(engine.stats().music_starved == 0, "không hụt khung nào");
}

constexpr std::array kCases{
    Case{.name = "music_rate_stays_pure", .body = &music_rate_stays_pure},
    Case{.name = "effect_rate_stays_pure", .body = &effect_rate_stays_pure},
    Case{.name = "output_rate_stays_pure", .body = &output_rate_stays_pure},
    Case{.name = "odd_rate_blends_rows", .body = &odd_rate_blends_rows},
    Case{.name = "downsampling_blocks_the_fold", .body = &downsampling_blocks_the_fold},
    Case{.name = "frame_count_follows_the_ratio", .body = &frame_count_follows_the_ratio},
    Case{.name = "streaming_matches_one_shot", .body = &streaming_matches_one_shot},
    Case{.name = "limiter_passes_quiet_untouched", .body = &limiter_passes_quiet_untouched},
    Case{.name = "limiter_keeps_the_wave_shape", .body = &limiter_keeps_the_wave_shape},
    Case{.name = "limiter_lets_go_after_the_burst", .body = &limiter_lets_go_after_the_burst},
    Case{.name = "engine_keeps_music_pure", .body = &engine_keeps_music_pure},
    Case{.name = "engine_keeps_effects_pure", .body = &engine_keeps_effects_pure},
    Case{.name = "pcm_pack_round_trips", .body = &pcm_pack_round_trips},
    Case{.name = "broken_packs_are_rejected", .body = &broken_packs_are_rejected},
    Case{.name = "opus_keeps_length_and_tone", .body = &opus_keeps_length_and_tone},
    Case{.name = "cooked_music_loops_without_a_click", .body = &cooked_music_loops_without_a_click},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "audio_dsp_tests: mọi ca phải qua");
    return 0;
}
