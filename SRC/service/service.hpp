#pragma once
// Khung chung của một tiến trình máy chủ. Bảy exe chỉ khác nhau ở Kind: main gọi run rồi trả mã
// thoát. Ở mốc P2 tiến trình con mới kiểm cấu hình, in `ready` ra stdout rồi chờ yêu cầu dừng;
// trình giám sát chạy các bước [[start]] của supervisor.toml và dừng theo thứ tự ngược.
// Giao kèo dòng lệnh, stdout và mã thoát: docs/KE-HOACH-SERVER.md mục 3.1.

#include <cstdint>

namespace game::service {

enum class Kind : std::uint8_t {
    kSupervisor,
    kStore,
    kAuth,
    kBilling,
    kWorld,
    kZone,
    kGate,
};

// Mã thoát của tiến trình: 0 dừng theo yêu cầu, 1 lỗi lúc chạy, 2 dòng lệnh hoặc cấu hình sai.
[[nodiscard]] int run(Kind kind, int argc, const char* const* argv);

} // namespace game::service
