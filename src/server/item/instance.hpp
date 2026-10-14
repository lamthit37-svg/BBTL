#pragma once
// Một thể hiện vật phẩm: thứ nằm trong túi, kho hay ô trang bị của một nhân vật.
//
// Nguồn: _ITEM của 2008 (GameStruct_Item.h: serial, mã mẫu, số lượng, độ bền hiện tại và tối đa, số lần sửa
// hỏng m_FaileTimes, danh sách thuộc tính, đá gắn, cờ giám định). Khác gốc: 2008 giữ một union theo lớp; bản này
// dùng một struct phẳng cho mọi lớp vì số liệu ít và bản ghi nhị phân có phiên bản (codec.hpp) đã chọn trường theo
// lớp, đổi sang thay thế kiểu biến thể khi cần mà không phải đổi bố cục bộ nhớ.

#include "item/types.hpp"

#include <array>
#include <cstdint>

namespace game::item {

struct Instance {
    Serial serial;
    TemplateId tmpl;
    std::uint16_t count = 1;
    bool bound = false;        // đã khoá: không giao dịch, không bán chợ
    bool identified = true;    // đồ lam chưa giám định thì chưa tính thuộc tính ngẫu nhiên và bán giá thấp
    std::uint16_t durability = 0;
    std::uint16_t wear = 0;          // điểm hao mòn tích luỹ tới ngưỡng thì mất 1 độ bền (m_CurDamagePoint của 2008)
    std::uint8_t repair_fails = 0;   // số lần sửa đã dùng (m_FaileTimes của 2008)
    std::uint8_t enhance = 0;        // cấp cường hoá
    std::uint8_t aptitude = 0;       // điểm tư chất 0..255, 0 = không có
    std::uint8_t gem_slots = 0;      // số ô đá thực của thể hiện này
    std::array<TemplateId, kMaxGemSlots> gems{};  // id 0 = ô trống
    std::uint8_t attr_count = 0;
    std::array<AttrValue, kMaxAttrs> attrs{};
    std::uint64_t expires_at = 0;    // Tick hết hạn, 0 = vĩnh viễn

    friend bool operator==(const Instance&, const Instance&) noexcept = default;
};

} // namespace game::item
