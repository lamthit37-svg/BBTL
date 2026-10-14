// Đối chiếu phản chiếu SPIR-V với phản chiếu DXIL của cùng một nguồn Slang, rồi hợp hai bên thành
// một phản chiếu chuẩn cho cả ba đích. Slang ghi vào SPIR-V đủ tên sạch và bố cục byte nhưng không
// ghi semantic của HLSL; ngược lại DXIL mang semantic nhưng đặt hậu tố `_0` sau mọi tên. Hợp hai
// bên thì được tên sạch của SPIR-V cùng semantic của DXIL, và mọi chỗ hai bên bất đồng về bố cục
// (vị trí, kiểu, offset, cỡ) thành lỗi lúc dựng gói thay vì lỗi tạo pipeline lúc chạy.
#pragma once

#include "shader/reflection.hpp"

namespace game::shader::detail {

// Internal khi hai bên không cùng bố cục; chi tiết nêu tài nguyên, biến hay chữ ký lệch và trường
// lệch. Cả hai đầu vào đã qua normalize().
[[nodiscard]] Result<StageReflection> reconcile(StageReflection spirv, const StageReflection& dxil);

} // namespace game::shader::detail
