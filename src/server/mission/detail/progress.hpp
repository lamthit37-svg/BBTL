/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/mission/detail/progress.hpp
 *  PHÂN HỆ   : Mission / Detail / Progress
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Tiến độ nhiệm vụ bảng: đếm vật phẩm, ghi 0 hoặc 1 cho nói chuyện, học và
 *    cấp.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Nội bộ mission: tiến độ của nhiệm vụ BẢNG. Quy ước tham số của ô (khớp book.hpp): tham số 0 = cờ
// đủ điều kiện nộp, tham số 1 + chỉ số mục tiêu = tiến độ. Mục tiêu giết quái, nói chuyện, vào vùng
// tăng tham số theo sự kiện; mục tiêu loot và giao vật phẩm lấy tiến độ từ số vật phẩm trong túi
// (nên mất đồ thì tiến độ tụt, đúng bản gốc). Học kỹ năng và đạt cấp ghi 0/1 theo trạng thái nhân
// vật lúc sync, không đếm số lần sự kiện.

#pragma once

#include "ledger/ledger.hpp"
#include "mission/catalog.hpp"
#include "mission/detail/work.hpp"

#include <cstddef>
#include <cstdint>

namespace game::mission::detail {

[[nodiscard]] constexpr std::size_t param_of(const Objective& objective) noexcept {
    return static_cast<std::size_t>(objective.index) + 1;
}

// Mục tiêu đã đạt chưa, với số vật phẩm `items` (dùng cho loot/deliver).
[[nodiscard]] bool objective_met(const Objective& objective, const Slot& slot, std::int64_t items) noexcept;

// Cả nhiệm vụ bảng đã đủ điều kiện nộp chưa, theo túi hiện tại.
[[nodiscard]] bool table_ready(const Quest& quest, const Slot& slot, const ledger::ItemPort& items) noexcept;

// Đồng bộ tham số tiến độ vật phẩm và cờ sẵn sàng trên bản nháp của `work`; báo kReady khi cờ bật lên.
void sync_table(Work& work, const Quest& quest);

}  // namespace game::mission::detail
