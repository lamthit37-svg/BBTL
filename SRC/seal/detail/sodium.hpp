#pragma once
// Lời gọi libsodium. File này không kéo sodium.h, để header_check không cần include của thư viện.
#include <cstddef>
#include <cstdint>
#include <span>

namespace game::seal::detail {

using Secret = std::span<const std::byte, 32>;
using SecretOut = std::span<std::byte, 32>;
using HashOut = std::span<std::byte, 16>;
using HashIn = std::span<const std::byte, 16>;

struct Box {
    std::span<std::byte> destination;
    std::span<const std::byte> source;
    std::span<const std::byte> extra;
    Secret key;
};

[[nodiscard]] bool ready() noexcept;
void wipe(std::span<std::byte> region) noexcept;
[[nodiscard]] bool fill_random(std::span<std::byte> out) noexcept;
[[nodiscard]] bool derive(SecretOut out, Secret root, std::uint64_t subkey_id) noexcept;
[[nodiscard]] bool blake16(HashOut out, Secret key, std::span<const std::byte> message) noexcept;
[[nodiscard]] bool equal16(HashIn left, HashIn right) noexcept;
[[nodiscard]] bool seal_box(const Box& box) noexcept;
[[nodiscard]] bool open_box(const Box& box) noexcept;

} // namespace game::seal::detail
