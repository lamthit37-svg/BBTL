// Điều game biết về chiến đấu mà hàm native của làn kỹ năng/chiến đấu đọc (native_battle.cpp): hiệu ứng đang mang trên nhân vật
// người chơi và số ô hành động theo loại. Phía game ghi (chưa có đường mạng: test đặt thẳng), script chỉ đọc.
#pragma once

#include "ui/script/action_type.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace game::ui::script {

// Trần số hiệu ứng khác nhau trên một nhân vật. Khác gốc: gốc là std::map không trần (CObject_Character + 0x180).
inline constexpr std::size_t kImpactLimit = 256;

// Tập id hiệu ứng (impact) đang mang, như std::map<int, ...> ở CObject_Character + 0x180 mà FUN_1405dfc60 tra.
class ImpactSet {
public:
    // Thêm id; false khi đã đủ kImpactLimit id khác nhau (không thêm). Thêm id đã có là đúng.
    bool add(const std::int32_t id) {
        const auto at = std::ranges::lower_bound(ids_, id);
        if (at != ids_.end() && *at == id) return true;
        if (ids_.size() >= kImpactLimit) return false;
        ids_.insert(at, id);
        return true;
    }
    void remove(const std::int32_t id) {
        const auto at = std::ranges::lower_bound(ids_, id);
        if (at != ids_.end() && *at == id) ids_.erase(at);
    }
    void clear() noexcept { ids_.clear(); }
    [[nodiscard]] bool contains(const std::int32_t id) const noexcept { return std::ranges::binary_search(ids_, id); }
    [[nodiscard]] std::size_t size() const noexcept { return ids_.size(); }

private:
    std::vector<std::int32_t> ids_;
};

// Một buff của nhân vật người chơi trong kho của gốc (std::map ở CDataPool + 0x5b94e0, cỡ ở + 0x5b94e8; FUN_1400d2d40 lấy phần tử thứ i
// theo thứ tự khoá của map): id hiệu ứng là short ở + 8, thời gian còn lại (ms) là int ở + 0x18.
struct SelfBuff {
    std::int16_t impact = 0;
    std::int32_t remain_ms = 0;
};

// Trần số buff giữ; Khác gốc: map của gốc không trần.
inline constexpr std::size_t kBuffLimit = 256;

// Danh sách buff theo đúng thứ tự khoá map của gốc (phía mạng xếp sẵn). Thêm quá trần thì bỏ.
class BuffList {
public:
    bool push(const SelfBuff buff) {
        if (buffs_.size() >= kBuffLimit) return false;
        buffs_.push_back(buff);
        return true;
    }
    void clear() noexcept { buffs_.clear(); }
    [[nodiscard]] const std::vector<SelfBuff>& items() const noexcept { return buffs_; }

private:
    std::vector<SelfBuff> buffs_;
};

struct CombatFacts {
    // Buff của nhân vật người chơi (Player:GetBuffNumber, Player:CheckBuffImpactExist).
    BuffList self_buffs;
    // Hiệu ứng của nhân vật người chơi (đối tượng ObjectManager + 0xb8 của gốc); rỗng khi chưa vào cảnh.
    ImpactSet self_impacts;
    // Số CActionItem đang có theo mã loại (action_type.hpp), cái mà GetActionNum đếm bằng cách duyệt map hành động; chỉ số là mã loại.
    std::array<std::int32_t, kActionTypeLimit> action_counts{};
};

} // namespace game::ui::script
