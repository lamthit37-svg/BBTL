#pragma once
// Trạng thái vật phẩm và tiền của một nhân vật: ba túi, ô trang bị, kho và ví. Chỉ có đọc và `apply` một Plan;
// mọi thao tác nghiệp vụ (cất, chia, mặc, mua, bán...) nằm ở Planner (planner.hpp) và chỉ dựng Plan, không đụng
// Inventory. Thiết kế "dựng kế hoạch rồi áp dụng" cho hai điều: (1) thao tác hỏng thì trạng thái giữ NGUYÊN từng
// byte vì chưa có gì bị ghi; (2) kế hoạch chính là danh sách thay đổi có kiểu để zone gửi cho client.
//
// Nguồn: ItemContainer/HumanItemContainer của 2008 (ô theo chỉ số, ô trống = id 0), và các Packet GC* cho danh
// sách thay đổi. Khác gốc: 2008 sửa thẳng vào container và hoàn tác bằng tay khi hỏng giữa chừng; bản này
// không bao giờ ghi nửa chừng. Ví có kiểu tiền theo CU_* của client 2026 thay cho bảy kiểu ngầm của Obj_Human.

#include "item/instance.hpp"
#include "item/limits.hpp"
#include "item/types.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <vector>

namespace game::item {

// Một ô: nơi chứa và chỉ số trong nơi chứa (với kEquip là điểm lắp).
struct SlotRef {
    Place place = Place::kBaseBag;
    std::uint16_t index = 0;

    friend constexpr bool operator==(const SlotRef&, const SlotRef&) noexcept = default;
    friend constexpr auto operator<=>(const SlotRef&, const SlotRef&) noexcept = default;
};

// Trạng thái TUYỆT ĐỐI của một ô sau kế hoạch; nullopt = ô trống. Tuyệt đối thay vì "thêm/bớt" để áp dụng là
// phép gán, không thể cộng lệch, và client chỉ cần ghi đè ô.
struct SlotChange {
    SlotRef where;
    std::optional<Instance> after;

    friend bool operator==(const SlotChange&, const SlotChange&) noexcept = default;
};

// Tài khoản tiền: 0 là vàng gửi trong kho, 1..16 là loại tiền theo Currency.
enum class Account : std::uint8_t { kBankGold = 0 };
inline constexpr std::size_t kAccountSlots = kCurrencySlots;

[[nodiscard]] constexpr Account account_of(Currency c) noexcept { return static_cast<Account>(c); }

struct BalanceChange {
    Account account = Account::kBankGold;
    std::int64_t before = 0;  // số dư lúc dựng kế hoạch: apply từ chối nếu ví đã đổi
    std::int64_t after = 0;

    friend constexpr bool operator==(const BalanceChange&, const BalanceChange&) noexcept = default;
};

struct Plan {
    std::uint64_t revision = 0;  // revision của Inventory lúc dựng
    std::vector<SlotChange> slots;
    std::vector<BalanceChange> balances;

    [[nodiscard]] bool empty() const noexcept { return slots.empty() && balances.empty(); }

    friend bool operator==(const Plan&, const Plan&) noexcept = default;
};

// Ví: số dư nguyên có trần cho từng loại tiền và vàng trong kho. Số âm không bao giờ xuất hiện, phép cộng
// không tràn (so với phần còn lại của trần, không cộng rồi so).
class Wallet {
public:
    Wallet() = default;
    explicit Wallet(const Limits& limits) noexcept;

    [[nodiscard]] std::int64_t balance(Currency c) const noexcept;
    [[nodiscard]] std::int64_t bank_gold() const noexcept { return balance_.at(0); }
    [[nodiscard]] std::int64_t balance(Account a) const noexcept { return balance_.at(static_cast<std::size_t>(a)); }
    [[nodiscard]] std::int64_t cap(Account a) const noexcept { return cap_.at(static_cast<std::size_t>(a)); }

    [[nodiscard]] std::expected<void, Error> earn(Account a, std::int64_t amount) noexcept;
    [[nodiscard]] std::expected<void, Error> spend(Account a, std::int64_t amount) noexcept;

    // Đổi trần (đổi cấp làm đổi trần vàng). Không cắt số dư đang vượt trần: mất tiền người chơi là việc của
    // luật game, ví chỉ chặn không cho tăng thêm.
    void set_cap(Account a, std::int64_t cap) noexcept;
    // Nạp số dư đã giải mã; false khi âm hoặc loại không dùng.
    [[nodiscard]] bool set_balance(Account a, std::int64_t value) noexcept;

    friend bool operator==(const Wallet&, const Wallet&) noexcept = default;

private:
    std::array<std::int64_t, kAccountSlots> balance_{};
    std::array<std::int64_t, kAccountSlots> cap_{};
};

class Inventory {
public:
    explicit Inventory(const Limits& limits);

    // ---- đọc
    [[nodiscard]] const Instance* get(SlotRef where) const noexcept;
    [[nodiscard]] std::span<const std::optional<Instance>> view(Place place) const noexcept;
    [[nodiscard]] std::uint16_t unlocked(Place place) const noexcept;
    [[nodiscard]] std::uint16_t capacity(Place place) const noexcept;
    [[nodiscard]] const Wallet& wallet() const noexcept { return wallet_; }
    [[nodiscard]] const Limits& limits() const noexcept { return limits_; }
    [[nodiscard]] std::uint64_t revision() const noexcept { return revision_; }
    [[nodiscard]] bool locked(SlotRef where) const noexcept;
    // Tổng số lượng một mẫu ở mọi nơi chứa (túi, trang bị, kho).
    [[nodiscard]] std::uint64_t count_of(TemplateId tmpl) const noexcept;

    // ---- ghi
    // Áp dụng kế hoạch: kiểm TẤT CẢ trước (revision, biên, trùng ô, số dư, trần) rồi mới gán. Lỗi thì không đổi gì.
    // Không kiểm luật vật phẩm (đó là việc của Planner): một Plan do Planner dựng luôn qua được nếu revision khớp.
    [[nodiscard]] std::expected<void, Error> apply(const Plan& plan);
    // Khoá hay mở một ô (đang giao dịch, đang trong cửa hàng). Planner từ chối đụng ô khoá.
    [[nodiscard]] std::expected<void, Error> set_lock(SlotRef where, bool value);
    // Mở thêm ô túi hay kho (mở rộng túi); không quá capacity.
    [[nodiscard]] std::expected<void, Error> unlock_slots(Place place, std::uint16_t more);
    // Đổi trần ví theo cấp mới (vàng).
    void set_level_cap(std::uint32_t level) noexcept;

    // Nạp từ bản ghi (codec). Bên gọi đã kiểm biên; hàm vẫn kiểm lại và trả false nếu ô ngoài miền.
    [[nodiscard]] bool restore(SlotRef where, const Instance& item);
    // Xoá sạch một nơi chứa về trạng thái nhân vật mới (số ô mở theo Limits); trước khi nạp lại từ bản ghi. Tăng revision.
    void clear(Place place);
    // Nạp số dư; thành công thì revision tăng (như clear) để kế hoạch dựng trước khi nạp lại không áp dụng được.
    [[nodiscard]] bool restore_balance(Account a, std::int64_t value) noexcept {
        if (!wallet_.set_balance(a, value)) return false;
        ++revision_;
        return true;
    }
    [[nodiscard]] bool restore_unlocked(Place place, std::uint16_t value) noexcept;

private:
    [[nodiscard]] std::size_t offset(SlotRef where) const noexcept;
    [[nodiscard]] bool in_range(SlotRef where) const noexcept;

    Limits limits_;
    std::array<std::vector<std::optional<Instance>>, kPlaceCount> slots_;
    std::array<std::vector<bool>, kPlaceCount> locks_;
    std::array<std::uint16_t, kPlaceCount> unlocked_{};
    Wallet wallet_;
    std::uint64_t revision_ = 0;
};

} // namespace game::item
