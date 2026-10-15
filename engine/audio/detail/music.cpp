/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/audio/detail/music.cpp
 *  PHÂN HỆ   : Audio / Music
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt nhạc luồng lặp vô hạn: hết tệp tua về đầu, dòng mẫu qua bộ đổi tần
 *    số không ngắt nên chỗ nối không lách tách.
 *  - Luồng giải mã ngủ 5 ms giữa hai lượt; vòng đệm 0,68 giây nên ngủ dài gấp
 *    chục lần vẫn chưa làm bộ trộn đói.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "audio/detail/music.hpp"

#include "audio/detail/codec.hpp"
#include "audio/detail/native.hpp"
#include "audio/limits.hpp"
#include "audio/pack.hpp"
#include "audio/resample.hpp"
#include "audio/ring.hpp"
#include "core/error.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <stop_token>
#include <thread>
#include <utility>
#include <vector>

namespace game::audio::detail {
namespace {

constexpr std::uint32_t kChunkFrames = 1024;
constexpr std::chrono::milliseconds kNap{5};

// Tiến độ của một lần đọc có tua: tua về đầu mà vẫn không đọc được khung nào thì tệp hỏng.
struct LoopRead {
    std::uint32_t filled = 0;
    bool is_rewound = false;
    bool is_dry = false;
};

// Nguồn mẫu của một bàn: tệp cook đọc bằng PackStream (đã ở 48 kHz), tệp gốc bằng miniaudio.
struct Source {
    Stream raw;
    std::optional<PackStream> cooked;
    std::uint32_t channels = 1;
    std::uint32_t rate = kSampleRate;

    [[nodiscard]] core::Status open_raw(std::span<const std::byte> bytes) {
        const core::Status opened = stream_open(raw, bytes);
        if (!opened) return opened;
        channels = raw.channels;
        rate = raw.rate;
        return core::ok();
    }

    // bytes phải sống tới khi close.
    [[nodiscard]] core::Status open(std::span<const std::byte> bytes) {
        close();
        if (!is_pack(bytes)) return open_raw(bytes);
        core::Result<PackStream> opened = PackStream::open(bytes);
        if (!opened) return std::unexpected(opened.error());
        channels = opened->channels();
        rate = kSampleRate;
        cooked.emplace(std::move(*opened));
        return core::ok();
    }

    [[nodiscard]] std::uint32_t read(std::span<float> interleaved) {
        if (cooked) return cooked->read(interleaved);
        return stream_read(raw, interleaved);
    }

    void rewind() noexcept {
        if (cooked) cooked->rewind();
        stream_rewind(raw);
    }

    void close() noexcept {
        cooked.reset();
        stream_close(raw);
    }
};

void read_more(Source& stream, std::span<float> interleaved, LoopRead& progress) {
    const std::size_t taken = static_cast<std::size_t>(progress.filled) * stream.channels;
    const std::uint32_t got = stream.read(interleaved.subspan(taken));
    progress.filled += got;
    if (got > 0) {
        progress.is_rewound = false;
        return;
    }
    if (progress.is_rewound) {
        progress.is_dry = true;
        return;
    }
    stream.rewind();
    progress.is_rewound = true;
}

// Đọc đủ số khung của interleaved, tua về đầu mỗi khi hết tệp. Trả ít hơn chỉ khi tệp hỏng.
[[nodiscard]] std::uint32_t read_looped(Source& stream, std::span<float> interleaved) {
    const auto frames = static_cast<std::uint32_t>(interleaved.size() / stream.channels);
    LoopRead progress;
    while (progress.filled < frames && !progress.is_dry) {
        read_more(stream, interleaved, progress);
    }
    return progress.filled;
}

// Một kênh thì chép sang cả hai tai; hai kênh thì giữ nguyên.
void spread(std::span<const float> made, std::uint32_t channels, std::span<float> stereo) noexcept {
    const std::size_t frames = stereo.size() / 2;
    const std::size_t second = channels - 1;
    for (std::size_t frame = 0; frame < frames; ++frame) {
        stereo[frame * 2] = made[frame * channels];
        stereo[(frame * 2) + 1] = made[(frame * channels) + second];
    }
}

} // namespace

struct MusicDecks::Deck {
    std::vector<std::byte> bytes;
    Source stream;
    std::optional<Resampler> resampler;
    FrameRing ring{kMusicRingFrames};
    // Khung nguồn vừa đọc và khung 48 kHz theo số kênh của tệp; giữ lại để không cấp phát mỗi lượt.
    std::vector<float> source;
    std::vector<float> made;
    std::atomic<DeckState> state{DeckState::kFree};

    // Đổi tần số: đọc đúng số khung nguồn bộ lọc cần cho frames khung ra.
    [[nodiscard]] std::uint32_t converted(Resampler& changer, std::uint32_t frames) {
        const std::uint32_t need = changer.needed(frames);
        source.resize(static_cast<std::size_t>(need) * stream.channels);
        const std::uint32_t read = read_looped(stream, source);
        const std::span<const float> fresh(source);
        changer.push(fresh.first(static_cast<std::size_t>(read) * stream.channels));
        return changer.pull(made);
    }

    // Một khối 48 kHz theo số kênh của tệp vào made; trả số khung có được.
    [[nodiscard]] std::uint32_t next_frames() {
        made.resize(static_cast<std::size_t>(kChunkFrames) * stream.channels);
        if (!resampler) return read_looped(stream, made);
        return converted(*resampler, kChunkFrames);
    }

    // Một khối 48 kHz stereo vào vòng đệm. false khi tệp không còn cho ra khung nào.
    [[nodiscard]] bool feed_chunk() {
        std::array<float, static_cast<std::size_t>(kChunkFrames) * 2> stereo{};
        const std::uint32_t got = next_frames();
        if (got == 0) return false;
        const std::span<float> block = std::span<float>(stereo).first(std::size_t{got} * 2);
        spread(made, stream.channels, block);
        static_cast<void>(ring.write(block));
        return true;
    }
};

MusicDecks::MusicDecks() : decks_(kMusicSlots) {}

MusicDecks::~MusicDecks() {
    stop();
    for (Deck& deck : decks_) {
        deck.stream.close();
    }
}

int MusicDecks::load(std::span<const std::byte> encoded) {
    const auto is_free = [](const Deck& deck) {
        return deck.state.load(std::memory_order_acquire) == DeckState::kFree;
    };
    const auto found = std::ranges::find_if(decks_, is_free);
    if (found == decks_.end()) return -1;
    found->bytes.assign(encoded.begin(), encoded.end());
    found->state.store(DeckState::kLoading, std::memory_order_release);
    return static_cast<int>(found - decks_.begin());
}

void MusicDecks::run(const std::stop_token& token) {
    while (!token.stop_requested()) {
        pump();
        std::this_thread::sleep_for(kNap);
    }
}

void MusicDecks::start() {
    if (worker_.joinable()) return;
    worker_ = std::jthread([this](const std::stop_token& token) { run(token); });
}

// join có thể ném system_error; lúc tắt không còn ai xử lý được nó.
// NOLINTNEXTLINE(bugprone-exception-escape)
void MusicDecks::stop() noexcept {
    if (!worker_.joinable()) return;
    worker_.request_stop();
    worker_.join();
}

bool MusicDecks::is_threaded() const noexcept {
    return worker_.joinable();
}

DeckState MusicDecks::state(std::uint32_t deck) const noexcept {
    return decks_[deck].state.load(std::memory_order_acquire);
}

std::uint32_t MusicDecks::read(std::uint32_t deck, std::span<float> stereo) noexcept {
    return decks_[deck].ring.read(stereo);
}

void MusicDecks::release(std::uint32_t deck) noexcept {
    decks_[deck].state.store(DeckState::kDone, std::memory_order_release);
}

void MusicDecks::pump() {
    for (Deck& deck : decks_) {
        pump_one(deck);
    }
}

void MusicDecks::pump_one(Deck& deck) {
    const DeckState state = deck.state.load(std::memory_order_acquire);
    if (state == DeckState::kLoading) open(deck);
    if (state == DeckState::kDone) close(deck);
    if (state == DeckState::kReady) fill(deck);
}

void MusicDecks::open(Deck& deck) {
    const core::Status opened = deck.stream.open(deck.bytes);
    if (!opened) {
        deck.state.store(DeckState::kFailed, std::memory_order_release);
        return;
    }
    deck.resampler.reset();
    const RateChange change{
        .source_rate = deck.stream.rate, .target_rate = kSampleRate, .channels = deck.stream.channels};
    if (deck.stream.rate != kSampleRate) deck.resampler.emplace(change);
    // Nạp đầy vòng đệm rồi mới báo sẵn sàng: bộ trộn không gặp vòng đệm rỗng ở khối đầu. Bộ trộn
    // có thể đã trả bàn (kDone) trong lúc mở: khi đó giữ nguyên để lượt sau thu dọn.
    const DeckState next = top_up(deck) ? DeckState::kReady : DeckState::kFailed;
    DeckState expected = DeckState::kLoading;
    static_cast<void>(deck.state.compare_exchange_strong(expected, next, std::memory_order_acq_rel));
}

void MusicDecks::close(Deck& deck) noexcept {
    deck.stream.close();
    deck.resampler.reset();
    deck.ring.clear();
    deck.bytes.clear();
    deck.state.store(DeckState::kFree, std::memory_order_release);
}

bool MusicDecks::top_up(Deck& deck) {
    bool is_alive = true;
    while (is_alive && deck.ring.writable() >= kChunkFrames) {
        is_alive = deck.feed_chunk();
    }
    return is_alive;
}

void MusicDecks::fill(Deck& deck) {
    if (top_up(deck)) return;
    // Bộ trộn có thể vừa trả bàn (kDone): khi đó giữ nguyên, không ghi đè thành kFailed.
    DeckState expected = DeckState::kReady;
    static_cast<void>(deck.state.compare_exchange_strong(expected, DeckState::kFailed, std::memory_order_acq_rel));
}

} // namespace game::audio::detail
