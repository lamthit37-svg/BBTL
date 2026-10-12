#pragma once

// AArch64 không có xmmintrin. sse2neon v1.9.1 ánh xạ SSE4.1 sang NEON để math giữ
// nguyên toán tử. MINMAX và DP bật để NaN khớp SSE. RSQRT và RCP giữ ước lượng
// như lệnh x86: bật precise làm rsqrt đúng hơn RSQRTSS, sai hợp đồng của hàm.
// Nguồn: Forge2 src/math/sse.hpp@d7fcd76. Khác gốc: nội dung nằm trong #if defined(__aarch64__)
// để header tự đủ trên x64 (header_check dịch riêng từng header ở mọi nền, x64 không có
// sse2neon.h); NOLINT cho hai macro cấu hình của sse2neon.
#if defined(__aarch64__)
// sse2neon đọc hai macro này
// bằng #if (lệch DD-10).
// NOLINTBEGIN(cppcoreguidelines-macro-usage)
#define SSE2NEON_PRECISE_MINMAX 1
#define SSE2NEON_PRECISE_DP 1
// NOLINTEND(cppcoreguidelines-macro-usage)
#include <sse2neon.h>
#endif
