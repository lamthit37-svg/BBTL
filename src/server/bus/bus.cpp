#include "bus/bus.hpp"

#include <algorithm>
#include <cstddef>
#include <span>

namespace game::bus {

Bus::Bus(std::size_t capacity) : capacity_(capacity) {
    pending_.reserve(capacity);
    batch_.reserve(capacity);
}

bool Bus::publish(const Event& event) {
    if (static_cast<std::size_t>(event.kind) >= kKindCount || pending_.size() >= capacity_) {
        ++dropped_;
        return false;
    }
    pending_.push_back(event);
    return true;
}

std::span<const Event> Bus::take() {
    batch_.assign(pending_.begin(), pending_.end());
    pending_.clear();
    // Ổn định: cùng loại giữ nguyên thứ tự phát.
    std::ranges::stable_sort(batch_, {}, &Event::kind);
    return batch_;
}

}  // namespace game::bus
