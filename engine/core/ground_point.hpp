/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/ground_point.hpp
 *  PHÂN HỆ   : Core / Ground Point
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Điểm trên mặt đất theo toạ độ game: x và z, đơn vị game (một đơn vị là một
 *    ô lưới của map). Game đi trên mặt phẳng x-z; độ cao y lấy từ địa hình.
 *    Dùng chung cho đường đi, chọn bằng tia, va chạm.
 *  - Nguồn: TLBB Dev src/protocol/protocol.hpp@e0d89a6 (GroundPoint). Khác gốc:
 *    chỉ giữ hai trường và phép so sánh; phần serialize trên dây của protocol
 *    không thuộc client này.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

namespace game::core {

struct GroundPoint {
    float x = 0.0F;
    float z = 0.0F;

    friend constexpr bool operator==(const GroundPoint&, const GroundPoint&) = default;
};

} // namespace game::core
