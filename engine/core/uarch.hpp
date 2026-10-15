/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/uarch.hpp
 *  PHÂN HỆ   : Core / Uarch
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Tên vi kiến trúc từ họ, model, stepping của CPUID —
 *    GetX86Microarchitecture của cpu_features mà CPUConfig (_Ref) chép vào gốc.
 *    Bảng của _Ref dừng ở Zen 3 và Raptor Lake đời đầu; bảng ở đây theo
 *    arch/x86/include/asm/intel-family.h và arch/x86/kernel/cpu/amd.c của Linux
 *    cùng cpu_features bản 2026, tra ngày 2026-10-01.
 *  - Nguồn: Forge2 src/core/uarch.hpp@d7fcd76. Khác gốc: không.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include <cstdint>
#include <string_view>

namespace game::core {

// Chuỗi hãng như lá CPUID 0 trả ("GenuineIntel", "AuthenticAMD"); họ và model đã cộng phần mở
// rộng. Rỗng khi không có trong bảng.
[[nodiscard]] std::string_view microarchitecture(std::string_view vendor, std::uint32_t family, std::uint32_t model,
    std::uint32_t stepping) noexcept;

} // namespace game::core
