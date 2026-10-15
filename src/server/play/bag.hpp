/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/play/bag.hpp
 *  PHÂN HỆ   : Server / Play / Bag
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Túi đạo cụ của người chơi cho cổng vật phẩm của sổ cái (ledger::ItemPort):
 *    danh sách ô, mỗi ô một mẫu với số lượng và cờ khoá. Đây là túi TẠM của
 *    bước nhiệm vụ: chưa có thuộc tính ngẫu nhiên, trang bị hay nhiều túi
 *    (thuộc item::Inventory, bước chiến đấu). Khối lưu có phiên bản riêng nên
 *    đổi sang item::Inventory sau này là một phiên bản mới của khối, không phải
 *    đổi cột.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Chồng: số lượng tối đa mỗi ô là stack_max của mẫu trong item::Catalog; mẫu không có trong danh mục không bao giờ vào túi (dữ liệu
// hỏng không được cho qua). Thứ tự ô tất định: chồng còn chỗ trước, rồi ô mới ở cuối; lấy ra từ ô đầu.

#pragma once

#include "item/catalog.hpp"
#include "ledger/ledger.hpp"
#include "protocol/wire.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>
#include <vector>

namespace game::play {

inline constexpr std::uint16_t kBagKind = 0x7302;
inline constexpr std::uint16_t kBagVersion = 1;
// Trần cứng của khối lưu, bất kể số ô mở: dữ liệu thù địch không phình bộ nhớ.
inline constexpr std::size_t kMaxBagSlots = 512;

struct BagSlot {
    std::uint32_t item = 0;
    std::uint32_t count = 0;
    bool bound = false;

    friend bool operator==(const BagSlot&, const BagSlot&) noexcept = default;
};

enum class [[nodiscard]] BagError : std::uint8_t { kBadFrame = 1, kBadValue, kTooLarge };

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương của STL (HP-07)
class Bag final : public ledger::ItemPort {
public:
    // `catalog` có thể rỗng (thử nhỏ): khi đó mọi mẫu coi như không chồng được. Phải sống lâu hơn Bag.
    Bag(const item::Catalog* catalog, std::uint16_t capacity) noexcept : catalog_(catalog), capacity_(capacity) {}

    // ledger::ItemPort
    [[nodiscard]] std::int64_t count(std::uint32_t item) const noexcept override;
    [[nodiscard]] bool fits(std::span<const ledger::Stack> removes, std::span<const ledger::Stack> gives) const noexcept override;
    [[nodiscard]] std::int32_t free_slots() const noexcept override;
    bool remove(std::uint32_t item, std::int64_t count) noexcept override;
    bool give(std::uint32_t item, std::int64_t count, bool bound) noexcept override;
    void checkpoint() override { saved_ = slots_; }
    // NOLINTNEXTLINE(bugprone-exception-escape): chép vector có thể ném bad_alloc; dự án không dùng ngoại lệ nên dừng tiến trình (LH-07)
    void rollback() noexcept override { slots_ = saved_; }

    [[nodiscard]] std::span<const BagSlot> slots() const noexcept { return slots_; }
    [[nodiscard]] std::uint16_t capacity() const noexcept { return capacity_; }

    [[nodiscard]] std::vector<std::byte> encode() const;
    // Thay toàn bộ túi bằng khối đã lưu; lỗi thì túi giữ nguyên. Khối rỗng là túi trống.
    [[nodiscard]] std::expected<void, BagError> restore(protocol::ByteView blob);

private:
    [[nodiscard]] std::uint32_t stack_max(std::uint32_t item) const noexcept;
    // Một lần gửi vào túi: `limit` là stack_max của mẫu.
    struct Add {
        std::uint32_t item = 0;
        std::uint32_t count = 0;
        std::uint32_t limit = 0;
        bool bound = false;
    };
    [[nodiscard]] static bool put(std::vector<BagSlot>& slots, std::uint16_t capacity, const Add& what) noexcept;

    const item::Catalog* catalog_;
    std::uint16_t capacity_;
    std::vector<BagSlot> slots_;
    std::vector<BagSlot> saved_;
};

} // namespace game::play
