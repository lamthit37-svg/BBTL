// Kiểm tra nền tảng dùng chung cho vỏ Android và iOS: đổi mã, đồng hồ, luồng, log, CPU.
#pragma once

#include <string>

namespace game::client {

struct ProbeReport {
    bool passed = false;
    std::string detail;
};

// Ghi detail. Không mở cửa sổ.
[[nodiscard]] ProbeReport mobile_probe();

// Cùng luật với client Windows: bản debug bật lớp kiểm tra, bản phát hành tắt vì tốn CPU mỗi khung.
[[nodiscard]] constexpr bool validation_by_build() noexcept {
#ifdef GAME_DEBUG_CHECKS
    return true;
#else
    return false;
#endif
}

} // namespace game::client
