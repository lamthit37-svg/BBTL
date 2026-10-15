/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/play/bag.cpp
 *  PHÂN HỆ   : Server / Play / Bag
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt túi đạo cụ tạm của người chơi: chồng, lấy ra, kiểm chỗ, mã hoá và
 *    nạp khối lưu.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "play/bag.hpp"

#include "ids/ids.hpp"
#include "item/catalog.hpp"
#include "ledger/ledger.hpp"
#include "protocol/wire.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>
#include <utility>
#include <vector>

namespace game::play {

namespace {

// Số lượng một lần gửi vào túi tối đa; ledger cho tới 2^40 nhưng một túi thật không chứa nổi.
constexpr std::int64_t kCountLimit = std::int64_t{1} << 28U;

[[nodiscard]] std::int64_t total_of(const std::vector<BagSlot>& slots, std::uint32_t item) noexcept {
    std::int64_t total = 0;
    for (const BagSlot& slot : slots) {
        if (slot.item == item) total += slot.count;
    }
    return total;
}

// Lấy `count` cái của `item` từ các ô, ô khoá trước rồi ô thường, mỗi nhóm từ ô đầu. false (không đổi gì) khi không đủ.
[[nodiscard]] bool take(std::vector<BagSlot>& slots, std::uint32_t item, std::int64_t count) noexcept {
    if (count <= 0 || total_of(slots, item) < count) return false;
    std::int64_t left = count;
    for (const bool bound : {true, false}) {
        for (BagSlot& slot : slots) {
            if (left == 0) break;
            if (slot.item != item || slot.bound != bound) continue;
            const std::int64_t used = std::min<std::int64_t>(left, slot.count);
            slot.count -= static_cast<std::uint32_t>(used);
            left -= used;
        }
    }
    std::erase_if(slots, [](const BagSlot& slot) { return slot.count == 0; });
    return true;
}

} // namespace

std::uint32_t Bag::stack_max(std::uint32_t item) const noexcept {
    if (catalog_ == nullptr) return 0;
    const item::Template* const found = catalog_->find(ids::ItemTemplateId{item});
    return found == nullptr ? 0 : found->stack_max;
}

// NOLINTNEXTLINE(bugprone-exception-escape): push_back có thể ném bad_alloc; dự án không dùng ngoại lệ nên dừng tiến trình (LH-07)
bool Bag::put(std::vector<BagSlot>& slots, std::uint16_t capacity, const Add& what) noexcept {
    if (what.limit == 0 || what.count == 0) return false;
    std::uint32_t pending = what.count;
    for (BagSlot& slot : slots) {
        if (pending == 0) break;
        if (slot.item != what.item || slot.bound != what.bound || slot.count >= what.limit) continue;
        const std::uint32_t vacant = what.limit - slot.count;
        const std::uint32_t added = std::min(pending, vacant);
        slot.count += added;
        pending -= added;
    }
    while (pending > 0) {
        if (slots.size() >= capacity) return false;
        const std::uint32_t added = std::min(pending, what.limit);
        slots.push_back(BagSlot{.item = what.item, .count = added, .bound = what.bound});
        pending -= added;
    }
    return true;
}

std::int64_t Bag::count(std::uint32_t item) const noexcept { return total_of(slots_, item); }

std::int32_t Bag::free_slots() const noexcept {
    return static_cast<std::int32_t>(capacity_) - static_cast<std::int32_t>(slots_.size());
}

// NOLINTNEXTLINE(bugprone-exception-escape,bugprone-easily-swappable-parameters): chép vector có thể ném bad_alloc (LH-07); chữ ký do ledger::ItemPort quy định
bool Bag::fits(std::span<const ledger::Stack> removes, std::span<const ledger::Stack> gives) const noexcept {
    std::vector<BagSlot> trial = slots_;
    for (const ledger::Stack& one : removes) {
        if (!take(trial, one.item, one.count)) return false;
    }
    for (const ledger::Stack& one : gives) {
        if (one.count <= 0 || one.count > kCountLimit) return false;
        const Add what{.item = one.item, .count = static_cast<std::uint32_t>(one.count), .limit = stack_max(one.item),
            .bound = one.bound};
        if (!put(trial, capacity_, what)) return false;
    }
    return true;
}

bool Bag::remove(std::uint32_t item, std::int64_t count) noexcept { return take(slots_, item, count); }

// NOLINTNEXTLINE(bugprone-exception-escape): chép vector có thể ném bad_alloc; dự án không dùng ngoại lệ nên dừng tiến trình (LH-07)
bool Bag::give(std::uint32_t item, std::int64_t count, bool bound) noexcept {
    if (count <= 0 || count > kCountLimit) return false;
    std::vector<BagSlot> trial = slots_;
    const Add what{.item = item, .count = static_cast<std::uint32_t>(count), .limit = stack_max(item), .bound = bound};
    if (!put(trial, capacity_, what)) return false;
    slots_ = std::move(trial);
    return true;
}

std::vector<std::byte> Bag::encode() const {
    std::vector<std::byte> out;
    protocol::Writer writer(out);
    writer.u16(kBagVersion);
    writer.count(slots_.size(), kMaxBagSlots);
    for (const BagSlot& slot : slots_) {
        writer.u32(slot.item);
        writer.u32(slot.count);
        writer.boolean(slot.bound);
    }
    if (!writer.finish(kBagKind)) return {};
    return out;
}

std::expected<void, BagError> Bag::restore(protocol::ByteView blob) {
    if (blob.empty()) {
        slots_.clear();
        return {};
    }
    const protocol::FrameResult frame = protocol::peek_frame(blob, protocol::kMaxBodyBytes);
    if (!frame || !frame->has_value() || (*frame)->kind != kBagKind ||
        protocol::kHeaderBytes + (*frame)->body_bytes != blob.size()) {
        return std::unexpected(BagError::kBadFrame);
    }
    protocol::Reader reader(blob.subspan(protocol::kHeaderBytes));
    if (reader.u16() != kBagVersion) return std::unexpected(BagError::kBadFrame);
    const std::size_t size = reader.count(kMaxBagSlots);
    std::vector<BagSlot> loaded;
    loaded.reserve(size);
    for (std::size_t at = 0; at < size && reader.is_ok(); ++at) {
        BagSlot slot;
        slot.item = reader.u32();
        slot.count = reader.u32();
        slot.bound = reader.boolean();
        // Ô quá chồng tối đa của mẫu hay mẫu đã biến mất khỏi danh mục vẫn nạp được: bỏ ô của người chơi vì dữ liệu đổi là mất đồ.
        if (slot.item == 0 || slot.count == 0) return std::unexpected(BagError::kBadValue);
        loaded.push_back(slot);
    }
    if (!reader.finish() || loaded.size() > capacity_) return std::unexpected(BagError::kBadValue);
    slots_ = std::move(loaded);
    return {};
}

} // namespace game::play
