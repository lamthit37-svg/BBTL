// Harness libFuzzer cho metrics::parse_snapshot, bộ đọc ảnh chụp số đo nhận byte từ socket và tệp.
// Có răng: văn bản nào đọc được thì ghi lại (write_snapshot) phải đọc lại được và ghi ra đúng từng
// byte của lần ghi trước, không dài quá kSnapshotMaxBytes; sai là __builtin_trap. Dựng và chạy:
//   clang++ -std=c++23 -g -O1 -fsanitize=fuzzer,address,undefined -fno-sanitize-recover=undefined
//     -D_DISABLE_STRING_ANNOTATION -D_DISABLE_VECTOR_ANNOTATION -D_MSVC_STL_HARDENING=1 -I SRC -I tests
//     tests/fuzz/fuzz_metrics_snapshot.cpp SRC/metrics/metrics.cpp -o <exe>
//   <exe> -runs=1000000 -seed=20261008 -max_len=896847 <thư mục corpus>
// (-max_len là kSnapshotMaxBytes + 1; hai định nghĩa _DISABLE_* vì libFuzzer dựng sẵn trên Windows
// tắt chú thích ASan của string và vector, xem TOOLS/server/fuzz_protocol.py.)
// _MSVC_STL_HARDENING là bắt buộc: ảnh chụp là một khối nhớ lớn, ghi lệch chỉ số cột rơi vào dòng
// kế của chính khối đó nên ASan không thấy; đo 2026-10-09, bỏ phép kiểm chỉ số cột khỏi bộ đọc thì
// không có cờ này một triệu vòng vẫn thoát 0, có cờ thì dừng sau khoảng 47.000 vòng.
#include "metrics/metrics.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace {

// Cấp một lần: mỗi ảnh chụp khoảng 280 KB, cấp lại ở từng đầu vào thì phần lớn thời gian là xoá bộ nhớ.
struct Arena {
    std::unique_ptr<game::metrics::Snapshot> first = std::make_unique<game::metrics::Snapshot>();
    std::unique_ptr<game::metrics::Snapshot> second = std::make_unique<game::metrics::Snapshot>();
    std::vector<char> once = std::vector<char>(game::metrics::kSnapshotMaxBytes);
    std::vector<char> twice = std::vector<char>(game::metrics::kSnapshotMaxBytes);
    std::string text;
};

void check_one(Arena& arena, std::span<const std::uint8_t> raw) {
    arena.text.resize(raw.size());
    std::ranges::transform(raw, arena.text.begin(), [](std::uint8_t one) { return static_cast<char>(one); });
    if (!game::metrics::parse_snapshot(arena.text, *arena.first)) return;
    const std::size_t wrote = game::metrics::write_snapshot(*arena.first, arena.once);
    if (wrote > game::metrics::kSnapshotMaxBytes) __builtin_trap();
    const std::string_view canonical{arena.once.data(), wrote};
    if (!game::metrics::parse_snapshot(canonical, *arena.second)) __builtin_trap();
    const std::size_t again = game::metrics::write_snapshot(*arena.second, arena.twice);
    if (std::string_view{arena.twice.data(), again} != canonical) __builtin_trap();
}

} // namespace

// Điểm vào libFuzzer gọi cho từng đầu vào.
// NOLINTNEXTLINE(readability-identifier-naming): tên do libFuzzer đòi (DD-02)
extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size);

// NOLINTNEXTLINE(readability-identifier-naming): tên do libFuzzer đòi (DD-02)
extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    static Arena arena;
    check_one(arena, std::span<const std::uint8_t>{data, size});
    return 0;
}
