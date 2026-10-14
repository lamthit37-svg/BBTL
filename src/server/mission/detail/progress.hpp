#pragma once
// Nội bộ mission: tiến độ của nhiệm vụ BẢNG. Quy ước tham số của ô (khớp book.hpp): tham số 0 = cờ đủ điều kiện nộp, tham số
// 1 + chỉ số mục tiêu = tiến độ. Mục tiêu giết quái, nói chuyện, vào vùng tăng tham số theo sự kiện; mục tiêu loot và giao
// vật phẩm lấy tiến độ từ số vật phẩm trong túi (nên mất đồ thì tiến độ tụt, đúng bản gốc).

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
