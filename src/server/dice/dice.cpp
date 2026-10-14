#include "dice/dice.hpp"

#include <bit>
#include <limits>
#include <utility>

namespace game::dice {
namespace {

constexpr std::uint64_t kSplitGamma = 0x9E3779B97F4A7C15ULL;
constexpr std::uint64_t kSplitMulA = 0xBF58476D1CE4E5B9ULL;
constexpr std::uint64_t kSplitMulB = 0x94D049BB133111EBULL;
constexpr std::uint32_t kPermilleFull = 1000;
constexpr std::uint32_t kPpmFull = 1'000'000;

[[nodiscard]] std::uint64_t split_next(std::uint64_t& seed) noexcept {
    seed += kSplitGamma;
    std::uint64_t mixed = seed;
    mixed = (mixed ^ (mixed >> 30U)) * kSplitMulA;
    mixed = (mixed ^ (mixed >> 27U)) * kSplitMulB;
    return mixed ^ (mixed >> 31U);
}

} // namespace

Dice::Dice(std::uint64_t seed) noexcept {
    // splitmix64 không sinh bốn từ cùng 0 từ bất kỳ hạt giống nào, nên xoshiro không rơi vào trạng thái chết.
    for (std::uint64_t& word : state_) {
        word = split_next(seed);
    }
}

std::uint64_t Dice::next_u64() noexcept {
    const std::uint64_t result = std::rotl(state_[1] * 5U, 7) * 9U;
    const std::uint64_t shifted = state_[1] << 17U;
    state_[2] ^= state_[0];
    state_[3] ^= state_[1];
    state_[1] ^= state_[2];
    state_[0] ^= state_[3];
    state_[2] ^= shifted;
    state_[3] = std::rotl(state_[3], 45);
    return result;
}

std::uint64_t Dice::below(std::uint64_t bound) noexcept {
    if (bound == 0) return 0;
    // Loại phần dư để mọi giá trị có cùng số mẫu: 2^64 mod bound = (-bound) mod bound.
    const std::uint64_t reject_below = (~bound + 1U) % bound;
    std::uint64_t draw = next_u64();
    while (draw < reject_below) {
        draw = next_u64();
    }
    return draw % bound;
}

std::int64_t Dice::between(std::int64_t low, std::int64_t high) noexcept {
    if (low > high) std::swap(low, high);
    const auto width = static_cast<std::uint64_t>(high) - static_cast<std::uint64_t>(low);
    // Cả miền int64: width + 1 tràn về 0, below(0) trả 0 nên phải lấy thẳng một từ.
    const std::uint64_t offset = width == std::numeric_limits<std::uint64_t>::max() ? next_u64() : below(width + 1U);
    return static_cast<std::int64_t>(static_cast<std::uint64_t>(low) + offset);
}

bool Dice::chance_permille(std::uint32_t permille) noexcept {
    if (permille == 0) return false;
    if (permille >= kPermilleFull) return true;
    return below(kPermilleFull) < permille;
}

bool Dice::chance_ppm(std::uint32_t ppm) noexcept {
    if (ppm == 0) return false;
    if (ppm >= kPpmFull) return true;
    return below(kPpmFull) < ppm;
}

std::optional<std::size_t> Dice::pick_weighted(std::span<const std::uint32_t> weights) noexcept {
    std::uint64_t total = 0;
    for (const std::uint32_t weight : weights) {
        total += weight;
    }
    // 2^32 phần tử mới tràn u64; vẫn kiểm vì độ dài do bên ngoài quyết định.
    if (total == 0 || weights.size() > std::numeric_limits<std::uint32_t>::max()) return std::nullopt;
    std::uint64_t ticket = below(total);
    for (std::size_t index = 0; index < weights.size(); ++index) {
        if (ticket < weights[index]) return index;
        ticket -= weights[index];
    }
    return std::nullopt;
}

} // namespace game::dice
