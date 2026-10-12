// Harness libFuzzer của máy bắt tay. Dựng bằng TOOLS/server/fuzz_secure.py, không qua CMake.
// Hạt danh tính cố định để mỗi lần chạy đi cùng một khoá. Đầu vào là byte của kẻ lạ.
#include "secure/secure.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <span>
#include <utility>

namespace {

[[nodiscard]] std::uint64_t& mix_slot() {
    static std::uint64_t value = 0;
    return value;
}

void keep(std::uint64_t value) { mix_slot() ^= value; }

[[nodiscard]] std::array<std::byte, game::secure::kEphemeralBytes> seed_of() {
    std::array<std::byte, game::secure::kEphemeralBytes> seed{};
    seed.fill(std::byte{0xA5});
    return seed;
}

[[nodiscard]] game::secure::Identity load_identity() {
    game::secure::Result<game::secure::Identity> made = game::secure::Identity::from_seed(seed_of());
    if (!made) __builtin_trap();
    return std::move(*made);
}

[[nodiscard]] game::secure::Identity& identity() {
    // Khoá một lần, huỷ khi tiến trình fuzz thoát. Clang cấm destructor lúc thoát.
#if defined(__clang__)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wexit-time-destructors"
#endif
    static game::secure::Identity kept = load_identity();
#if defined(__clang__)
#pragma clang diagnostic pop
#endif
    return kept;
}

void note_server(const game::secure::ServerHandshake& server, const game::secure::AbsorbResult& got) {
    if (!got) {
        keep(static_cast<std::uint64_t>(server.error()));
        return;
    }
    keep(got->consumed);
    if (!server.is_done()) return;
    keep(server.reply().size());
    keep(static_cast<unsigned>(server.reply().front()));
}

void absorb_all(game::secure::ByteView bytes) {
    game::secure::ServerHandshake server{identity()};
    const game::secure::AbsorbResult got = server.absorb(bytes);
    note_server(server, got);
    if (!server.is_done()) return;
    game::secure::SessionKeys keys = server.take_keys();
    keep(static_cast<unsigned>(keys.send.front()));
}

void absorb_split(game::secure::ByteView bytes) {
    if (bytes.size() < 2) return;
    const std::size_t cut = bytes.size() / 2;
    game::secure::ServerHandshake server{identity()};
    const game::secure::AbsorbResult first = server.absorb(bytes.first(cut));
    note_server(server, first);
    if (!first || server.is_broken() || server.is_done()) return;
    const game::secure::AbsorbResult second = server.absorb(bytes.subspan(cut));
    note_server(server, second);
    if (!server.is_done()) return;
    game::secure::SessionKeys keys = server.take_keys();
    keep(static_cast<unsigned>(keys.receive.front()));
}

void finish_client(game::secure::ByteView bytes) {
    game::secure::Result<game::secure::ClientHandshake> client = game::secure::ClientHandshake::begin();
    if (!client) {
        keep(static_cast<std::uint64_t>(client.error()));
        return;
    }
    game::secure::Result<game::secure::SessionKeys> keys = client->finish(bytes, identity().public_key());
    if (!keys) {
        keep(static_cast<std::uint64_t>(keys.error()));
        return;
    }
    keep(static_cast<unsigned>(keys->send.front()));
}

} // namespace

// Điểm vào libFuzzer gọi cho từng đầu vào.
// NOLINTNEXTLINE(readability-identifier-naming): tên do libFuzzer đòi (DD-02)
extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size);

// NOLINTNEXTLINE(readability-identifier-naming): tên do libFuzzer đòi (DD-02)
extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    const std::span<const std::uint8_t> raw{data, size};
    const game::secure::ByteView bytes = std::as_bytes(raw);
    absorb_all(bytes);
    absorb_split(bytes);
    finish_client(bytes);
    return static_cast<int>(mix_slot() == 0);
}
