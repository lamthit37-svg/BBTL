/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/shader/dxil.hpp
 *  PHÂN HỆ   : Shader / Dxil
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Phản chiếu DXIL qua giao diện ID3D12ShaderReflection của DXC. Không phải
 *    API của module: chỉ compiler.cpp gọi, ngay sau khi Slang dịch ra DXIL, vì
 *    đối tượng phản chiếu sống nhờ dxcompiler.dll. Kết quả đi vào gói shader,
 *    nên lúc chạy không cần DXC để biết bố cục tài nguyên. Chuẩn hoá về cùng
 *    cấu trúc với bộ đọc SPIR-V (shader/spirv.hpp); shader/detail/reconcile.cpp
 *    ghép hai bên. Nguồn: Forge2 src/shader/dxil.hpp@d7fcd76.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Khác gốc: tham số locations (location theo semantic cho bộ shader chuyển từ client gốc).

#pragma once

#include "shader/reflection.hpp"

#include <string_view>

// Giao diện COM của Windows SDK, khai trước để header này không kéo d3d12shader.h; chúng huỷ qua
// Release chứ không qua destructor.
// NOLINTBEGIN(cppcoreguidelines-virtual-class-destructor)
struct ID3D12ShaderReflection;
// NOLINTEND(cppcoreguidelines-virtual-class-destructor)

namespace game::shader {

// Unsupported khi shader dùng tbuffer hay feedback texture; InvalidArgument khi một chỉ số register
// không dưới kShiftRange, hoặc khi locations là kSemantic mà một semantic không có trong bảng.
[[nodiscard]] Result<StageReflection> reflect_dxil(ID3D12ShaderReflection& shader, Stage stage,
    std::string_view entry, Locations locations);

} // namespace game::shader
