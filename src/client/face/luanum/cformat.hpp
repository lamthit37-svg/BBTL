// sprintf của MSVCR110 (CRT mà LuaPlus.dll trong client 2026 gọi cho string.format, tostring và phép nối số), viết lại
// bằng chuẩn C++ cho đúng từng ký tự của nó. Mọi điểm lệch khỏi C chuẩn dưới đây đã đo trên LuaPlus.dll bằng
// TOOLS/port/lua_oracle.py (kịch bản TOOLS/port/oracle/lua_rt_format.lua):
// - Số thực: CRT sinh đúng 17 chữ số có nghĩa của giá trị (làm tròn đúng), rồi làm tròn tiếp về số chữ số cần in theo
//   quy tắc "chữ số kế >= 5 thì tăng" (không phải làm tròn theo giá trị nhị phân chính xác), chữ số sau vị trí thứ 17 là
//   '0'. Vì thế %.0f của 0.5 ra "1", %.2f của 0.125 ra "0.13", %.20f của 0.1 ra "0.10000000000000001000".
// - Số mũ của %e, %g luôn có ít nhất ba chữ số ("1e+006", "1e-005").
// - Vô cực và NaN đi qua cùng đường làm tròn với chuỗi chữ số giả "1#INF", "1#QNAN", "1#IND": %f ra "1.#INF00", %.2f ra
//   "1.#J", %g ra "1.#INF".
// - %#g của 0 in P chữ số sau dấu chấm (không phải P - 1).
// - Cờ '0' còn đệm số không cho %s và %c.
// - Chữ ra là chuỗi C: %c của byte 0 cắt kết quả tại đó.
#pragma once

#include <cstdint>
#include <string>
#include <string_view>

namespace game::luanum {

// Phần cờ, độ rộng, độ chính xác của một đặc tả %[cờ][rộng][.chính xác]kiểu.
struct FormatSpec {
    bool left = false;
    bool sign = false;
    bool blank = false;
    bool alternate = false;
    bool zero = false;
    int width = 0;
    // Âm là không khai báo.
    int precision = -1;
};

// %e %E %f %g %G.
[[nodiscard]] std::string format_double(char conversion, const FormatSpec& spec, double value);
// %d %i.
[[nodiscard]] std::string format_signed(const FormatSpec& spec, std::int32_t value);
// %o %u %x %X.
[[nodiscard]] std::string format_unsigned(char conversion, const FormatSpec& spec, std::uint32_t value);
// %c: byte thấp của value.
[[nodiscard]] std::string format_char(const FormatSpec& spec, std::int32_t value);
// %s: text là chuỗi C (đã cắt ở byte 0 đầu tiên).
[[nodiscard]] std::string format_text(const FormatSpec& spec, std::string_view text);

} // namespace game::luanum
