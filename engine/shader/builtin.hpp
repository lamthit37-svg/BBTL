// Phần dùng chung mà trình dịch luôn cung cấp: `#include "f2/shader.inc.slang"` trả về chuỗi dưới
// đây từ bộ nhớ, không cần tệp nào trên đĩa. Nó thay các header d3d.h, vulkan.h của FSL (_Ref, gần
// 1.800 dòng macro giấu khác biệt giữa HLSL và GLSL); cả ba đích đều là mã Slang/HLSL nên chỉ còn
// một chỗ khác nhau thật: khối push constant. Trình dịch còn tự định nghĩa F2_DXIL, F2_SPIRV hoặc
// F2_DXBC, F2_STAGE_<TÊN> (VS, PS, CS...) và F2_DEBUG ở bản debug.
// Nguồn: Forge2 src/shader/builtin.hpp@d7fcd76. Khác gốc: thêm nhánh F2_DXBC, cbuffer b1, vì fxc
// không dịch được ConstantBuffer và register space; nhánh Vulkan rẽ theo F2_SPIRV thay cho
// __spirv__ (Slang không định nghĩa macro của DXC).
#pragma once

#include <string_view>

namespace game::shader {

// Tên dùng trong #include. Tệp cùng tên trên đĩa không thay được bản này.
inline constexpr std::string_view kBuiltinName = "f2/shader.inc.slang";

// F2_PUSH_CONSTANTS(Kiểu, tên): một khối hằng nhỏ đổi theo từng lệnh vẽ. Vulkan nhận nó làm push
// constant; D3D12 nhận nó làm cbuffer ở b0 của register space 127 (kPushSpace). D3D11 nhận cbuffer
// b1 (kPushRegister): b0 là hằng khung hình. Phản chiếu giữ bản DXIL, kể cả khi bytecode là DXBC.
inline constexpr std::string_view kBuiltinText =
    "#ifndef F2_SHADER_INC\n"
    "#define F2_SHADER_INC\n"
    "#ifdef F2_DXBC\n"
    "#define F2_PUSH_CONSTANTS(Type, name) cbuffer F2Push : register(b1) { Type name; }\n"
    "#elif defined(F2_SPIRV)\n"
    "#define F2_PUSH_CONSTANTS(Type, name) [[vk::push_constant]] ConstantBuffer<Type> name\n"
    "#else\n"
    "#define F2_PUSH_CONSTANTS(Type, name) ConstantBuffer<Type> name : register(b0, space127)\n"
    "#endif\n"
    "#endif\n";

} // namespace game::shader
