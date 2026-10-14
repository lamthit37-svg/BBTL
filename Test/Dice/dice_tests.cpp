// Bộ ngẫu nhiên tất định: kết quả sai thì mọi bảng rơi đồ và xác suất lệch thầm mà nhìn không ra, nên
// ghim bốn từ đầu của một hạt giống với bản tính độc lập bằng Python (cùng thuật toán), và kiểm các
// biên của below, between, pick_weighted.
#include "dice/dice.hpp"
#include "test.hpp"

#include <array>
#include <cstdint>
#include <limits>
#include <optional>

namespace game::test {
namespace {

using dice::Dice;

void first_words_match_reference(Context& context) {
    Dice one(12345);
    context.expect(one.next_u64() == 0xbe6a36374160d49bULL, "từ 1");
    context.expect(one.next_u64() == 0x214aaa0637a688c6ULL, "từ 2");
    context.expect(one.next_u64() == 0xf69d16de9954d388ULL, "từ 3");
    context.expect(one.next_u64() == 0x0c60048c4e96e033ULL, "từ 4");
}

void same_seed_replays(Context& context) {
    Dice left(7);
    Dice right(7);
    bool same = true;
    for (int i = 0; i < 1000; ++i) {
        same = same && left.next_u64() == right.next_u64();
    }
    context.expect(same, "cùng hạt giống ra cùng dãy");
    context.expect(Dice(1).next_u64() != Dice(2).next_u64(), "khác hạt giống ra khác dãy");
}

void below_stays_in_range_and_covers(Context& context) {
    Dice one(99);
    std::array<int, 7> seen{};
    for (int i = 0; i < 7000; ++i) {
        const std::uint64_t value = one.below(7);
        context.expect(value < 7, "below(7) < 7");
        if (value < 7) ++seen[value];
    }
    for (const int count : seen) {
        context.expect(count > 800 && count < 1200, "mỗi giá trị khoảng 1000 lần");
    }
    context.expect(one.below(0) == 0, "below(0) = 0");
    context.expect(one.below(1) == 0, "below(1) = 0");
}

void between_covers_edges(Context& context) {
    Dice one(5);
    bool low_seen = false;
    bool high_seen = false;
    for (int i = 0; i < 400; ++i) {
        const std::int64_t value = one.between(-2, 2);
        context.expect(value >= -2 && value <= 2, "trong [-2, 2]");
        low_seen = low_seen || value == -2;
        high_seen = high_seen || value == 2;
    }
    context.expect(low_seen && high_seen, "chạm cả hai đầu");
    context.expect(one.between(3, 3) == 3, "một giá trị");
    const std::int64_t swapped = one.between(10, 4);
    context.expect(swapped >= 4 && swapped <= 10, "đầu ngược được đổi chỗ");
    constexpr std::int64_t kMin = std::numeric_limits<std::int64_t>::min();
    constexpr std::int64_t kMax = std::numeric_limits<std::int64_t>::max();
    static_cast<void>(one.between(kMin, kMax));
    context.expect(true, "cả miền int64 không tràn");
}

void chance_edges(Context& context) {
    Dice one(11);
    context.expect(!one.chance_permille(0), "0 luôn sai");
    context.expect(one.chance_permille(1000), "1000 luôn đúng");
    context.expect(one.chance_permille(5000), "quá 1000 luôn đúng");
    context.expect(!one.chance_ppm(0), "ppm 0");
    context.expect(one.chance_ppm(1'000'000), "ppm đầy");
    int hits = 0;
    for (int i = 0; i < 10000; ++i) {
        if (one.chance_permille(250)) ++hits;
    }
    context.expect(hits > 2300 && hits < 2700, "250 phần nghìn ≈ 2500 trên 10000");
}

void weighted_pick(Context& context) {
    Dice one(21);
    context.expect(!one.pick_weighted({}).has_value(), "rỗng");
    constexpr std::array<std::uint32_t, 3> kZero{0, 0, 0};
    context.expect(!one.pick_weighted(kZero).has_value(), "tổng 0");
    constexpr std::array<std::uint32_t, 3> kOnly{0, 5, 0};
    for (int i = 0; i < 50; ++i) {
        context.expect(one.pick_weighted(kOnly) == std::optional<std::size_t>{1}, "chỉ ô có trọng số");
    }
    constexpr std::array<std::uint32_t, 2> kSplit{1, 3};
    int second = 0;
    for (int i = 0; i < 8000; ++i) {
        if (one.pick_weighted(kSplit) == std::optional<std::size_t>{1}) ++second;
    }
    context.expect(second > 5700 && second < 6300, "tỉ lệ 1:3 ≈ 6000 trên 8000");
}

constexpr std::array kCases{
    Case{"first_words_match_reference", first_words_match_reference},
    Case{"same_seed_replays", same_seed_replays},
    Case{"below_stays_in_range_and_covers", below_stays_in_range_and_covers},
    Case{"between_covers_edges", between_covers_edges},
    Case{"chance_edges", chance_edges},
    Case{"weighted_pick", weighted_pick},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
