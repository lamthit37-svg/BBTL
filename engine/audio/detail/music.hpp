// Nhạc luồng. Mỗi bàn giữ một tệp nén, bộ giải mã, bộ đổi tần số và một vòng đệm 48 kHz stereo.
// Ba vai, mỗi vai một luồng: luồng gọi API nạp byte vào bàn trống; luồng giải mã (hoặc pump() gọi
// thẳng khi không có thiết bị) mở bộ giải mã, giữ vòng đệm đầy và thu dọn bàn đã trả; bộ trộn chỉ
// đọc vòng đệm và trả bàn. Trạng thái bàn là một atomic và mỗi bước chuyển chỉ một vai được làm,
// nên không cần khoá và bộ trộn không bao giờ chờ việc giải mã.
#pragma once

#include <cstddef>
#include <cstdint>
#include <span>
#include <stop_token>
#include <thread>
#include <vector>

namespace game::audio::detail {

enum class DeckState : std::uint8_t {
    // Trống: luồng API được nạp.
    kFree,
    // Đã có byte nén, chờ luồng giải mã mở.
    kLoading,
    // Vòng đệm đang được giữ đầy, bộ trộn đọc.
    kReady,
    // Không giải mã được: bộ trộn trả bàn.
    kFailed,
    // Bộ trộn đã trả: luồng giải mã thu dọn rồi đưa về kFree.
    kDone,
};

class MusicDecks {
public:
    MusicDecks();
    ~MusicDecks();
    MusicDecks(const MusicDecks&) = delete;
    MusicDecks& operator=(const MusicDecks&) = delete;
    MusicDecks(MusicDecks&&) = delete;
    MusicDecks& operator=(MusicDecks&&) = delete;

    // Luồng API. Chép byte nén vào một bàn trống; trả chỉ số bàn, hoặc -1 khi mọi bàn đang bận.
    [[nodiscard]] int load(std::span<const std::byte> encoded);

    // Luồng API. Chạy và dừng luồng giải mã; không chạy thì người dùng tự gọi pump().
    void start();
    void stop() noexcept;
    [[nodiscard]] bool is_threaded() const noexcept;

    // Bộ trộn.
    [[nodiscard]] DeckState state(std::uint32_t deck) const noexcept;
    // Đọc tối đa stereo.size() / 2 khung; trả số khung có thật (ít hơn là giải mã chưa kịp).
    [[nodiscard]] std::uint32_t read(std::uint32_t deck, std::span<float> stereo) noexcept;
    // Trả bàn: luồng giải mã sẽ đóng bộ giải mã và giải phóng byte nén.
    void release(std::uint32_t deck) noexcept;

    // Một lượt việc của luồng giải mã trên mọi bàn.
    void pump();

private:
    struct Deck;

    void run(const std::stop_token& token);
    static void pump_one(Deck& deck);
    static void open(Deck& deck);
    static void close(Deck& deck) noexcept;
    // Giữ vòng đệm đầy; false khi tệp không còn cho ra khung nào.
    [[nodiscard]] static bool top_up(Deck& deck);
    static void fill(Deck& deck);

    std::vector<Deck> decks_;
    std::jthread worker_;
};

} // namespace game::audio::detail
