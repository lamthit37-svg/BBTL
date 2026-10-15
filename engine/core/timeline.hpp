/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/timeline.hpp
 *  PHÂN HỆ   : Core / Timeline
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Mốc nạp: mỗi mốc là một dòng log "Mốc <ms> ms  <tên>", ms tính từ lúc hệ
 *    điều hành tạo tiến trình (core::process_age), nên cộng được với phần nạp
 *    thư viện và đọc trực tiếp so với số đo từ ngoài của
 *    TOOLS/run/launch_timeline.py. Các mốc là bảng đo của đường nạp (AGENTS.md,
 *    mục Ngân sách): đổi tên mốc thì đổi cả công cụ đọc chúng
 *    (TOOLS/run/bench_load.py).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "core/clock.hpp"

#include <chrono>
#include <cstdio>
#include <print>
#include <string_view>

namespace game::core {

[[nodiscard]] inline double age_ms() noexcept {
    return std::chrono::duration<double, std::milli>(core::process_age()).count();
}

#if defined(__linux__)
// Bộ nhớ thường trú của tiến trình theo /proc/self/status, KiB: anon (heap, texture giải nén) và file (thư viện, tệp ánh xạ).
// Đọc không được thì cả hai là 0. Điện thoại giết tiến trình khi MemAvailable cạn nên đường nạp phải thấy được số này.
struct ResidentKib {
    unsigned long anon = 0;
    unsigned long file = 0;
};

[[nodiscard]] inline ResidentKib resident_kib() noexcept {
    ResidentKib out;
    std::FILE* const status = std::fopen("/proc/self/status", "r");
    if (status == nullptr) return out;
    char line[160];
    while (std::fgets(line, sizeof line, status) != nullptr) {
        // sscanf không ghi quá %lu; tiền tố khớp đúng từng chữ nên dòng khác bị bỏ.
        if (std::sscanf(line, "RssAnon: %lu kB", &out.anon) == 1) continue;
        if (std::sscanf(line, "RssFile: %lu kB", &out.file) == 1) continue;
    }
    std::fclose(status);
    return out;
}
#endif

inline void mark(std::string_view what) {
    std::println("Mốc {:8.1f} ms  {}", age_ms(), what);
#if defined(__linux__)
    const ResidentKib memory = resident_kib();
    // Dòng riêng ngay sau dòng mốc và không lặp tên mốc: bench_load.py khớp dòng theo tên mốc rồi đọc "Mốc <ms> ms" ở chính dòng đó.
    std::println("Bộ nhớ {:7.1f} MB anon, {:6.1f} MB file", static_cast<double>(memory.anon) / 1024.0,
        static_cast<double>(memory.file) / 1024.0);
#endif
}

} // namespace game::core
