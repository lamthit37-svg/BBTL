/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/zone/gates.hpp
 *  PHÂN HỆ   : Server / Zone / Gates
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cổng đi bộ giữa các cảnh. Vùng kích hoạt là hình chữ nhật areas của mã
 *    2008 (AreaManager.h: x >= left && x < right && z >= top && z < bottom).
 *    Điểm đến lấy từ ScenePosDefineEx của client 2026, chỉ dòng field_nine == 0
 *    (cổng bản đồ; field_nine == 1 là dịch chuyển qua NPC, không bước vào là
 *    đi).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Khác gốc: script /event/chuansong/ của 2008 không có trong cây này, nên đích là dòng cổng gần vùng
// nhất trong 24 m, không phải toạ độ cứng trong file lua. Guid của nhiều vùng Đại Lý cùng bằng 0;
// ta phân biệt vùng bằng chỉ số dòng. Client 2026 đặt chân đúng điểm cổng, mà điểm ấy nằm trong vùng
// về của cảnh đích (Kiếm Các 36,286 nằm trong [31,38) x [285,293)), nên lần đặt chân không chạy
// chuyển cảnh — chỉ chạy khi vùng đang đứng đổi. 2008 thì OnEnterArea chạy cả lúc m_uAreaID còn
// UINT_MAX. Cùng một zone giữ cả hai cảnh (MMO-23 là chuyển giữa hai tiến trình).

#pragma once

#include <cstdint>
#include <expected>
#include <functional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::zone {

// 1 đơn vị game của bảng cảnh = 100 cm, cùng phép với điểm sinh (content.hpp).
inline constexpr float kCmPerGameUnit = 100.0F;
inline constexpr float kGameUnitsPerCm = 0.01F;
// Vùng cổng Đại Lý cách điểm ScenePosDefineEx tới khoảng 8 m (vô lượng: điểm x=304, cạnh phải 296).
inline constexpr float kGateBindMetres = 24.0F;

// Một dòng ScenePosDefineEx đã đọc. kind là cột field_nine.
struct WalkGate {
    std::int32_t id = 0;
    std::int32_t source_scene = 0;
    std::int32_t source_x = 0;
    std::int32_t source_z = 0;
    std::int32_t dest_scene = 0;
    std::int32_t dest_x = 0;
    std::int32_t dest_z = 0;
    std::int32_t kind = 0;
};

// Một vùng của cảnh, mét. crossing là cổng đã buộc được vào một WalkGate.
struct AreaRect {
    float left = 0.0F;
    float top = 0.0F;
    float right = 0.0F;
    float bottom = 0.0F;
    bool crossing = false;
    std::uint16_t dest_scene = 0;
    float dest_x_cm = 0.0F;
    float dest_z_cm = 0.0F;
};

// Vùng chứa điểm, theo thứ tự dòng (Zone::GetCurrentArea trả vùng đầu tiên).
struct AreaStand {
    bool inside = false;
    std::uint32_t index = 0;
    bool crossing = false;
    std::uint16_t dest_scene = 0;
    float dest_x_cm = 0.0F;
    float dest_z_cm = 0.0F;
};

// Nguồn vùng lúc buộc cổng. script_id âm là không script.
struct AreaSource {
    std::int32_t script_id = -1;
    float left = 0.0F;
    float top = 0.0F;
    float right = 0.0F;
    float bottom = 0.0F;
};

// Bảng cổng. Dòng sai kiểu thì bỏ dòng đó; thiếu cột thì lỗi cả bảng.
[[nodiscard]] std::expected<std::vector<WalkGate>, std::string> parse_gates(std::string_view text);

// script_id của các dòng path chứa "/event/chuansong/", sắp tăng, không trùng.
[[nodiscard]] std::expected<std::vector<std::int32_t>, std::string> parse_chuansong(std::string_view text);

// Mọi vùng của cảnh, đúng thứ tự. Vùng script chuansong được buộc vào cổng đi bộ gần nhất của
// cùng cảnh nguồn nếu cách hình chữ nhật không quá kGateBindMetres và `known` nhận cảnh đích.
// `known` rỗng nghĩa là mọi cảnh đích uint16 đều nhận. `chuansong` phải đã sắp tăng.
[[nodiscard]] std::vector<AreaRect> area_rects(std::int32_t scene, std::span<const AreaSource> areas,
    std::span<const WalkGate> gates, std::span<const std::int32_t> chuansong,
    const std::function<bool(std::uint16_t)>& known);

// Điểm (x, z) tính bằng mét. NaN không thuộc vùng nào. O(số vùng của một cảnh).
[[nodiscard]] AreaStand area_stand(std::span<const AreaRect> areas, float x, float z) noexcept;

} // namespace game::zone
