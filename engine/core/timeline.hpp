// Mốc nạp: mỗi mốc là một dòng log "Mốc <ms> ms  <tên>", ms tính từ lúc hệ điều hành tạo tiến trình
// (core::process_age), nên cộng được với phần nạp thư viện và đọc trực tiếp so với số đo từ ngoài của
// TOOLS/run/launch_timeline.py. Các mốc là bảng đo của đường nạp (AGENTS.md, mục Ngân sách): đổi tên mốc thì đổi
// cả công cụ đọc chúng (TOOLS/run/bench_load.py).
#pragma once

#include "core/clock.hpp"

#include <chrono>
#include <print>
#include <string_view>

namespace game::core {

[[nodiscard]] inline double age_ms() noexcept {
    return std::chrono::duration<double, std::milli>(core::process_age()).count();
}

inline void mark(std::string_view what) {
    std::println("Mốc {:8.1f} ms  {}", age_ms(), what);
}

} // namespace game::core
