#pragma once
// Các thay đổi đang chờ của MỘT thao tác Planner, dùng chung giữa planner.cpp và planner_equip.cpp (module khác
// không include). Đọc thấy chính chúng trước, nên thao tác nhiều bước nhìn đúng trạng thái giữa chừng mà lớp phủ của
// Planner chưa bị đụng; thao tác hỏng thì bỏ cả Edits, lớp phủ nguyên vẹn.

#include "item/instance.hpp"
#include "item/inventory.hpp"
#include "item/planner.hpp"

#include <optional>
#include <vector>

namespace game::item {

class Planner::Edits {
public:
    explicit Edits(const Planner& owner) noexcept : owner_(&owner) {}

    [[nodiscard]] const std::optional<Instance>& get(SlotRef where) const noexcept {
        for (const SlotChange& change : list_) {
            if (change.where == where) return change.after;
        }
        return owner_->cell(where);
    }
    void set(SlotRef where, const std::optional<Instance>& value) {
        for (SlotChange& change : list_) {
            if (change.where == where) {
                change.after = value;
                return;
            }
        }
        list_.push_back(SlotChange{.where = where, .after = value});
    }
    [[nodiscard]] const std::vector<SlotChange>& list() const noexcept { return list_; }

private:
    const Planner* owner_;
    std::vector<SlotChange> list_;
};

} // namespace game::item
