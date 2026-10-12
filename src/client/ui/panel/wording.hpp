// Điền mẫu chuỗi của từ điển, như ScriptGlobal_Format("#{khoá}", ...) mà script của client 2026
// gọi: mẫu viết chỗ điền là %s0, %s1... (CTPK_251016_1 của StrDictionary là "#cC8B88E%s0级").
// Khác gốc: ScriptGlobal_Format nằm trong Game.exe và chưa tháo mã; quy tắc "%s rồi một chữ số,
// số đó là thứ tự đối số tính từ 0" suy từ các mẫu của từ điển và cách script gọi.
#pragma once

#include "gui/strings.hpp"

#include <span>
#include <string>
#include <string_view>

namespace game::ui::panel {

// Các đối số cho chỗ điền, theo thứ tự %s0, %s1...
using Slots = std::span<const std::string_view>;

// Nối vào out một mẫu đã có chữ, mỗi %s0, %s1... thay bằng đối số cùng số. Thiếu đối số thì chỗ
// ấy để trống. pattern là mẫu, không phải tag "#{khoá}".
void format_pattern(std::string& out, std::string_view pattern, Slots slots);

// Nối vào out mẫu của tag, mỗi chỗ điền thay bằng đối số cùng số (không có thì để trống). tag
// viết như script gọi, "#{khoá}"; không đúng dạng đó hay khoá không có trong bảng thì out giữ
// nguyên.
void format_key(std::string& out, const gui::StringBook& book, std::string_view tag, Slots slots);

} // namespace game::ui::panel

