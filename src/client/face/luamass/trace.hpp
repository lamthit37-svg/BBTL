// Phía C++ của đối soát hàng loạt LUA-GEN (docs/giao-viec/LUA-GEN/THIET-KE.md): chạy một đơn vị (các chunk do bộ dịch
// sinh từ đúng danh sách của TOOLS/port/luagen/mass_units.py) trên runtime lua cùng bản dịch của world.lua, và ghi vết
// từng byte như trace() của TOOLS/port/luagen/mass_oracle.py:
//     unit<TAB><đơn vị>
//     load<TAB><chunk>     rồi !syntax nếu chunk lỗi cú pháp, !err nếu chạy thân chunk lỗi
//     drive                rồi các dòng mà __drive của world.lua ghi qua __emit
//     end
// Phía gốc chạy thêm một chunk "hook" (móc đếm lệnh của trọng tài) không ghi gì; phía này không có nó.
#pragma once

#include "lua/vm.hpp"

#include <span>
#include <string>
#include <string_view>

namespace game::luamass {

// Một đơn vị như bộ dịch đưa ra: tên và các chunk theo thứ tự nạp.
struct UnitChunks {
    std::string_view name;
    std::span<const lua::Chunk> chunks;
};

// Vết của một đơn vị, mỗi dòng kết thúc bằng '\n'. Mỗi lần gọi dùng một State mới, nên các đơn vị không ảnh hưởng nhau.
[[nodiscard]] std::string trace_unit(const UnitChunks& unit, const lua::Chunk& world);

} // namespace game::luamass
