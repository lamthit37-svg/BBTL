// Lối tắt cho đường lỗi của module shader. Không phải API của module: chỉ tệp .cpp trong src/shader
// include nó. Vị trí lỗi là chỗ gọi, vì core::Message chụp source_location tại chỗ chuỗi được
// chuyển thành Message.
// Nguồn: Forge2 src/shader/failure.hpp@d7fcd76. Khác gốc: không.
#pragma once

#include "shader/types.hpp"

#include <expected>
#include <utility>

namespace game::shader {

// Chuyển lỗi của một Result hay Status lên hàm gọi: `if (!value) return pass(value);`.
template <class T>
[[nodiscard]] core::Failure pass(std::expected<T, Error>& result) noexcept {
    return core::Failure(std::move(result).error());
}

// Gói shader, phản chiếu hay SPIR-V đọc vào không hợp lệ. Dữ liệu ấy đến từ đĩa nên là thù địch.
[[nodiscard]] inline core::Failure corrupt(core::Message message) noexcept {
    return fail(ErrorCode::kCorrupt, message);
}

// Slang hay DXC trả về thứ mà hợp đồng của nó không cho phép, hoặc hai bản dịch của cùng một nguồn
// lệch nhau: lỗi của công cụ, không phải của nguồn shader.
[[nodiscard]] inline core::Failure internal(core::Message message) noexcept {
    return fail(ErrorCode::kInternal, message);
}

} // namespace game::shader
