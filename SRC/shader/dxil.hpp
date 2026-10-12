// Phản chiếu DXIL qua giao diện ID3D12ShaderReflection của DXC. Không phải API của module: chỉ
// compiler.cpp gọi, ngay sau khi dịch, vì đối tượng phản chiếu sống nhờ dxcompiler.dll. Kết quả đi
// vào gói shader, nên lúc chạy không cần DXC để biết bố cục tài nguyên. Chuẩn hoá về cùng cấu trúc
// với bộ đọc SPIR-V (shader/spirv.hpp): cùng một nguồn HLSL phải ra hai phản chiếu bằng nhau.
// Nguồn: Forge2 src/shader/dxil.hpp@d7fcd76. Khác gốc: không.
#pragma once

#include "shader/reflection.hpp"

#include <string_view>

// Giao diện COM của Windows SDK, khai trước để header này không kéo d3d12shader.h; chúng huỷ qua
// Release chứ không qua destructor.
// NOLINTBEGIN(cppcoreguidelines-virtual-class-destructor)
struct ID3D12ShaderReflection;
struct ID3D12LibraryReflection;
// NOLINTEND(cppcoreguidelines-virtual-class-destructor)

namespace game::shader {

// Unsupported khi shader dùng tbuffer hay feedback texture; InvalidArgument khi một chỉ số register
// không dưới kShiftRange.
[[nodiscard]] Result<StageReflection> reflect_dxil(ID3D12ShaderReflection& shader, Stage stage, std::string_view entry);

// Thư viện nhiều hàm: hợp tài nguyên của mọi hàm.
[[nodiscard]] Result<StageReflection> reflect_dxil(ID3D12LibraryReflection& library);

} // namespace game::shader
