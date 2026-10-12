// Harness libFuzzer của bộ mở bản ghi đã mã hoá. Khoá phiên tạo một lần từ hạt cố định.
// Mỗi đầu vào là byte trên dây sau bắt tay. Dựng bằng TOOLS/server/fuzz_secure.py.
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

struct SavedKeys {
    std::array<std::byte, game::secure::kSessionBytes> send{};
    std::array<std::byte, game::secure::kSessionBytes> receive{};
};

[[nodiscard]] std::array<std::byte, game::secure::kEphemeralBytes> seed_of() {
    std::array<std::byte, game::secure::kEphemeralBytes> seed{};
    seed.fill(std::byte{0x3C});
    return seed;
}

[[nodiscard]] SavedKeys make_keys() {
    game::secure::Result<game::secure::Identity> identity = game::secure::Identity::from_seed(seed_of());
    if (!identity) __builtin_trap();
    game::secure::Result<game::secure::ClientHandshake> client = game::secure::ClientHandshake::begin();
    if (!client) __builtin_trap();
    game::secure::ServerHandshake server{*identity};
    const game::secure::AbsorbResult absorbed = server.absorb(client->hello());
    if (!absorbed || !server.is_done()) __builtin_trap();
    game::secure::Result<game::secure::SessionKeys> keys = client->finish(server.reply(), identity->public_key());
    if (!keys) __builtin_trap();
    SavedKeys saved;
    saved.send = keys->send;
    saved.receive = keys->receive;
    return saved;
}

[[nodiscard]] game::secure::RecordPipe pipe_of() {
    static const SavedKeys saved = make_keys();
    game::secure::SessionKeys keys;
    keys.send = saved.send;
    keys.receive = saved.receive;
    return game::secure::RecordPipe{std::move(keys)};
}

[[nodiscard]] bool open_one(game::secure::RecordPipe& pipe, game::secure::ByteView& rest) {
    if (rest.empty() || pipe.is_broken()) return false;
    std::array<std::byte, game::secure::kMaxPlainBytes> plain{};
    const game::secure::OpenResult opened = pipe.open_bytes(rest, plain);
    if (!opened) {
        keep(static_cast<std::uint64_t>(opened.error()));
        return false;
    }
    if (opened->consumed == 0) return false;
    rest = rest.subspan(opened->consumed);
    keep(opened->written);
    if (opened->written > 0) keep(static_cast<unsigned>(plain.front()));
    return true;
}

void open_input(game::secure::ByteView bytes) {
    game::secure::RecordPipe pipe = pipe_of();
    game::secure::ByteView rest = bytes;
    int left = 8;
    while (left > 0 && open_one(pipe, rest)) {
        --left;
    }
    keep(static_cast<std::uint64_t>(pipe.error()));
}

} // namespace

// Điểm vào libFuzzer gọi cho từng đầu vào.
// NOLINTNEXTLINE(readability-identifier-naming): tên do libFuzzer đòi (DD-02)
extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size);

// NOLINTNEXTLINE(readability-identifier-naming): tên do libFuzzer đòi (DD-02)
extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    const std::span<const std::uint8_t> raw{data, size};
    open_input(std::as_bytes(raw));
    return static_cast<int>(mix_slot() == 0);
}
