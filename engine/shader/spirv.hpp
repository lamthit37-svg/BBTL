// Phản chiếu SPIR-V do Slang sinh từ nguồn .slang. _Ref không đọc SPIR-V: bố cục descriptor của nó khai tay
// bằng macro SRT; Wicked và axmol dùng SPIRV-Reflect (6.000 dòng C). Bộ đọc này chỉ hiểu phần mà
// tầng đồ hoạ cần — biến tài nguyên, bố cục khối, chữ ký vào ra, cỡ nhóm — và coi module là dữ liệu
// thù địch: mọi chỉ số id, độ dài lệnh và độ sâu kiểu đều được chặn, module hỏng trả Corrupt chứ
// không đọc ra ngoài vùng nhớ. Nó giả định quy ước của module này: binding đã cộng độ dịch theo lớp
// register (shader/reflection.hpp). Slang không ghi semantic của HLSL vào SPIR-V nên chữ ký vào ra
// ở đây để semantic trống; shader/detail/reconcile.cpp lấy nó từ DXIL cùng nguồn. Cbuffer std140 của
// Slang bọc mỗi mảng vào một struct `_Array_*` một thành viên; bộ đọc bóc lớp bọc ấy.
// Nguồn: Forge2 src/shader/spirv.hpp@d7fcd76. Khác gốc: nguồn là Slang thay DXC, bỏ đoán semantic
// từ tên biến "in.var.TEXCOORD0", bóc lớp bọc mảng của Slang.
#pragma once

#include "shader/reflection.hpp"

#include <cstddef>
#include <span>
#include <string_view>

namespace game::shader {

// Bốn byte đầu là magic của SPIR-V theo thứ tự byte của máy.
[[nodiscard]] bool is_spirv(std::span<const std::byte> code) noexcept;

// Phản chiếu entry point tên entry của module. Stage::kLibrary gộp tài nguyên của mọi entry point
// và bỏ qua entry. Corrupt khi module hỏng; NotFound khi không có entry point ấy; InvalidArgument
// khi entry point thuộc stage khác; Unsupported khi gặp combined image sampler hay kiểu tài nguyên
// lạ.
[[nodiscard]] Result<StageReflection> reflect_spirv(std::span<const std::byte> code, Stage stage,
    std::string_view entry);

} // namespace game::shader
