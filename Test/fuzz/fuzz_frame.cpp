// Harness libFuzzer tầng hai cho đích frame (DE-BAI P2 đợt 2 §3.8). Dựng và chạy bằng
// TOOLS/server/fuzz_protocol.py với clang++ -fsanitize=fuzzer,address,undefined, không qua CMake.
#include "fuzz/targets.hpp"

#include <cstddef>
#include <cstdint>
#include <span>

// Điểm vào libFuzzer gọi cho từng đầu vào.
// NOLINTNEXTLINE(readability-identifier-naming): tên do libFuzzer đòi (DD-02)
extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size);

// NOLINTNEXTLINE(readability-identifier-naming): tên do libFuzzer đòi (DD-02)
extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    const std::span<const std::uint8_t> raw{data, size};
    if (game::fuzz::frame(std::as_bytes(raw)) == game::fuzz::Verdict::kBroken) __builtin_trap();
    return 0;
}
