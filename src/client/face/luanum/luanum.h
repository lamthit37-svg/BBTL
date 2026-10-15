/* Số của script giao diện theo đúng MSVCR110, độc lập với CRT và nền tảng. LuaPlus.dll của client 2026 gọi sprintf, strtod,
** rand và các phép ép double sang số nguyên của CRT Visual C++ 2012 (MSVCR110) trên x64; PC (UCRT), Android (bionic) và iOS
** (libSystem) làm các việc ấy khác nhau, nên mọi chỗ của LuaPlus mà kết quả lộ ra cho script đều gọi các hàm dưới đây
** (third_party/luaplus/NGUON.txt, mục "Khác gốc"). Mọi điểm lệch của MSVCR110 khỏi C chuẩn ở đây đã đo trên chính
** LuaPlus.dll; chi tiết ở cformat.hpp, number.hpp.
**
** Tệp C thuần (gồm được từ C11 và C++): LuaPlus là mã C, phần còn lại của client là C++.
*/
#ifndef LUANUM_H
#define LUANUM_H

/* Tệp C (LuaPlus là mã C) gồm được từ C++: cờ, macro, kiểu liệt kê trần và tên theo C ở đây không theo quy cách C++ của dự án. */
// NOLINTBEGIN(modernize-deprecated-headers,cppcoreguidelines-macro-usage,cppcoreguidelines-use-enum-class,readability-identifier-naming)
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
/* Trong C++ các hàm ép là constexpr để number.hpp dùng được trong hằng. */
#define LUANUM_INLINE constexpr
#define LUANUM_CAST(type, value) static_cast<type>(value)
extern "C" {
#else
#define LUANUM_INLINE static inline
#define LUANUM_CAST(type, value) ((type)(value))
#endif

/* (int)n của C trên x64: cvttsd2si 32 bit. Ngoài miền int32 và NaN cho INT32_MIN (ARM64 dồn về hai đầu miền), nên mọi
** luaL_checkint, luaL_checklong của LuaPlus đi qua đây (long của Windows là 32 bit, của Android và iOS là 64 bit). */
LUANUM_INLINE int32_t luanum_to_int32(double n) {
    /* So sánh viết theo chiều "phải đúng": NaN làm cả hai sai nên rơi vào nhánh INT32_MIN. */
    if (n > -2147483649.0 && n < 2147483648.0) return LUANUM_CAST(int32_t, n);
    return INT32_MIN;
}

/* (unsigned int)n của MSVC x64: cvttsd2si 64 bit rồi lấy 32 bit thấp ("5^-1" ra 4294967290 như script gốc). Ngoài miền int64
** và NaN cho 0 (INT64_MIN có 32 bit thấp bằng 0). */
LUANUM_INLINE uint32_t luanum_to_uint32(double n) {
    if (n >= -9223372036854775808.0 && n < 9223372036854775808.0) return LUANUM_CAST(uint32_t, LUANUM_CAST(uint64_t, LUANUM_CAST(int64_t, n)));
    return 0;
}

/* a << b và a >> b của x64: số đếm dịch lấy 5 bit thấp (C để số đếm từ 32 trở lên là hành vi không xác định). */
LUANUM_INLINE uint32_t luanum_shl(uint32_t value, uint32_t count) { return value << (count & 31U); }
LUANUM_INLINE uint32_t luanum_shr(uint32_t value, uint32_t count) { return value >> (count & 31U); }

/* NaN âm mặc định của x86 ("real indefinite", 0xFFF8000000000000), chuỗi "-1.#IND" của MSVCR110. */
double luanum_indefinite(void);

/* Kết quả NaN của một phép toán hay hàm toán: nếu result là NaN thì NaN của đối số thắng (đối số đầu trước), không đối số nào là
** NaN thì NaN âm mặc định. x64 sinh đúng như vậy bằng phần cứng; ARM64 sinh NaN dương, nên mọi phép toán của máy ảo và mọi
** hàm của thư viện toán đi qua đây để cùng một chuỗi in ra trên mọi nền tảng. */
LUANUM_INLINE double luanum_settle2(double result, double first, double second) {
    if (result == result) return result;
    if (first != first) return first;
    if (second != second) return second;
    return luanum_indefinite();
}
LUANUM_INLINE double luanum_settle1(double result, double first) { return luanum_settle2(result, first, 0.0); }

/* lua_number2str: "%.14g" của MSVCR110. buffer cần ít nhất 32 byte; trả độ dài chuỗi (không tính byte 0). */
int luanum_number2str(char* buffer, double n);

/* lua_str2number: strtod của MSVCR110 (bỏ khoảng trắng đầu, dấu, số thập phân, số mũ e/E/d/D; không nhận thập lục phân,
** "inf", "nan"). Không chuyển được thì trả 0 và *end = text. */
double luanum_strtod(const char* text, char** end);

/* strtoul của MSVCR110: unsigned long là 32 bit (tràn trả 0xFFFFFFFF, "-1" ra 0xFFFFFFFF), ở mọi nền tảng. */
uint32_t luanum_strtoul(const char* text, char** end, int base);

/* rand, srand của MSVCR110: LCG 214013, 2531011, lấy 15 bit giữa; hạt khởi đầu 1; mỗi luồng một hạt như CRT gốc. */
enum { LUANUM_RAND_MAX = 32767 };
int luanum_rand(void);
void luanum_srand(uint32_t seed);

/* sprintf của string.format. form là đặc tả "%[cờ][rộng][.chính xác]kiểu" mà scanformat của lstrlib.c đã kiểm (cờ trong
** "-+ #0", rộng và chính xác tối đa hai chữ số). Ghi tối đa capacity - 1 byte rồi byte 0; trả số byte đã ghi. */
size_t luanum_format_int(char* out, size_t capacity, const char* form, int32_t value);     /* c d i */
size_t luanum_format_uint(char* out, size_t capacity, const char* form, uint32_t value);   /* o u x X */
size_t luanum_format_double(char* out, size_t capacity, const char* form, double value);  /* e E f g G */
size_t luanum_format_text(char* out, size_t capacity, const char* form, const char* text); /* s */

#ifdef __cplusplus
}
#endif

// NOLINTEND(modernize-deprecated-headers,cppcoreguidelines-macro-usage,cppcoreguidelines-use-enum-class,readability-identifier-naming)
#endif
