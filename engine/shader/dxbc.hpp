// Dịch HLSL đã định nghĩa F2_DXBC bằng D3DCompile ra bytecode shader model 5.
// Phản chiếu không nằm ở đây: DXC dịch cùng nguồn không có F2_DXBC ra DXIL, rồi compiler.cpp
// giữ phản chiếu ấy và thay bytecode. fxc không có register space; macro F2_DXBC trong shader
// hạ space về slot D3D11 (gpu/d3d11/binding_map.hpp).
// Khác gốc: Forge2 không có đích DXBC.
#pragma once

#include "shader/compiler.hpp"

#include <vector>

namespace game::shader {

struct BytecodeIn {
    std::string_view path;
    std::string_view text;
    const CompileOptions* options = nullptr;
};

using ByteCode = Result<std::vector<std::byte>>;

// Unsupported khi stage không có profile 5.0. InvalidArgument khi nguồn sai, kèm báo của fxc.
[[nodiscard]] ByteCode compile_bytecode(const BytecodeIn& input);

} // namespace game::shader
