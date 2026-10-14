#pragma once
// Sổ cái nguyên tử của thưởng, thu và trả: một Request là MỘT giao dịch — hoặc mọi dòng đều áp dụng, hoặc không dòng nào.
// Nguồn thiết kế: TLBB Dev ADR-002 (sổ cái nguyên tử, idempotent theo mã yêu cầu).
//
// Khác gốc: lõi không biết túi, ví hay kinh nghiệm cụ thể (module `item` thuộc vai khác); nó nói chuyện với ba cổng trừu
// tượng ItemPort, WalletPort, ExpPort của MỘT nhân vật. Cổng cho phép chụp trạng thái và quay lại, nên "áp dụng rồi
// quay lui" chính xác kể cả cờ khoá của vật phẩm (không tự suy ngược bằng phép đối).
//
// Thứ tự: kiểm hợp lệ trước (đủ vật phẩm, đủ tiền, còn chỗ túi, còn chỗ ví) rồi mới áp dụng; áp dụng theo giai đoạn cố
// định (thu vật phẩm, thu tiền, nhận vật phẩm, nhận tiền, nhận kinh nghiệm) nên kết quả không phụ thuộc thứ tự dòng.
// Kinh nghiệm đứng cuối vì lên cấp không quay lui được: nếu nó thất bại thì mọi thứ trước đó được trả về.
//
// Idempotent: Journal nhớ kết quả của các mã yêu cầu gần nhất; gửi lại cùng mã trả đúng biên nhận cũ (replayed) và không
// đổi gì. Mã nhỏ hơn mốc đã quên và không còn trong nhật ký bị từ chối (kStale) vì không chứng minh được chưa từng chạy.
// Mã yêu cầu do bên gọi cấp, tăng ngặt từ 1 (mission dùng bộ đếm lưu cùng sổ nhiệm vụ).

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string_view>
#include <vector>

namespace game::ledger {

inline constexpr std::size_t kMaxEntries = 64;               // số dòng tối đa một giao dịch
inline constexpr std::size_t kJournalSize = 64;              // số biên nhận nhớ lại để chặn gửi lại
inline constexpr std::int64_t kMaxAmount = std::int64_t{1} << 40;  // trần một dòng, cùng trần số dư của item::codec

enum class EntryKind : std::uint8_t {
    kTakeItem,   // thu vật phẩm (item, amount)
    kGiveItem,   // nhận vật phẩm (item, amount, bound)
    kTakeMoney,  // thu tiền (amount, bound)
    kGiveMoney,  // nhận tiền (amount, bound)
    kGiveExp,    // nhận kinh nghiệm (amount)
};

struct Entry {
    EntryKind kind = EntryKind::kGiveExp;
    std::uint32_t item = 0;  // mẫu vật phẩm; 0 với dòng tiền và kinh nghiệm
    std::int64_t amount = 0;
    bool bound = false;      // vật phẩm nhận về bị khoá, hoặc loại tiền là tiền khoá
};

enum class [[nodiscard]] Reason : std::uint8_t {
    kCommitted = 0,
    kBadRequest,      // mã yêu cầu 0
    kEmpty,           // không có dòng nào
    kTooManyEntries,
    kBadEntry,        // số lượng ngoài (0, kMaxAmount], vật phẩm 0, tổng tràn
    kMissingItems,
    kMissingMoney,
    kNoRoom,          // túi không đủ chỗ
    kWalletFull,      // ví chạm trần
    kPortFailure,     // cổng báo lỗi lúc áp dụng; đã quay về trạng thái trước
    kStale,           // mã cũ hơn mốc nhật ký và không còn trong nhật ký
};

[[nodiscard]] std::string_view describe(Reason reason) noexcept;

struct Request {
    std::uint64_t id = 0;
    std::uint32_t source = 0;  // nguồn ghi vào nhật ký kiểm toán (id nhiệm vụ, id script...)
    std::span<const Entry> entries;
};

struct Receipt {
    std::uint64_t request = 0;
    Reason reason = Reason::kCommitted;
    bool replayed = false;  // biên nhận cũ của lần gửi trước

    [[nodiscard]] bool committed() const noexcept { return reason == Reason::kCommitted; }
    friend bool operator==(const Receipt&, const Receipt&) noexcept = default;
};

// ----- Cổng của một nhân vật --------------------------------------------------------------------------------------
struct Stack {
    std::uint32_t item = 0;
    std::int64_t count = 0;
    bool bound = false;
};

class Port {
public:
    Port() = default;
    Port(const Port&) = delete;
    Port& operator=(const Port&) = delete;
    Port(Port&&) = delete;
    Port& operator=(Port&&) = delete;
    virtual ~Port() = default;

    // checkpoint ghi trạng thái, rollback trả về đúng trạng thái đó. Ledger luôn gọi cặp này quanh phần áp dụng.
    virtual void checkpoint() = 0;
    virtual void rollback() noexcept = 0;
};

class ItemPort : public Port {
public:
    [[nodiscard]] virtual std::int64_t count(std::uint32_t item) const noexcept = 0;
    // Thu hết `removes` rồi nhận hết `gives` có vừa túi không (mô phỏng, không đổi trạng thái).
    [[nodiscard]] virtual bool fits(std::span<const Stack> removes, std::span<const Stack> gives) const noexcept = 0;
    [[nodiscard]] virtual std::int32_t free_slots() const noexcept = 0;
    virtual bool remove(std::uint32_t item, std::int64_t count) noexcept = 0;
    virtual bool give(std::uint32_t item, std::int64_t count, bool bound) noexcept = 0;
};

class WalletPort : public Port {
public:
    [[nodiscard]] virtual std::int64_t balance(bool bound) const noexcept = 0;
    [[nodiscard]] virtual std::int64_t room(bool bound) const noexcept = 0;  // còn nhận thêm được tối đa bao nhiêu
    virtual bool take(std::int64_t amount, bool bound) noexcept = 0;
    virtual bool give(std::int64_t amount, bool bound) noexcept = 0;
};

class ExpPort : public Port {
public:
    virtual bool give(std::int64_t amount) noexcept = 0;
};

// NOLINTBEGIN(cppcoreguidelines-avoid-const-or-ref-data-members): ba cổng do nơi gọi sở hữu, luôn có, không sở hữu, không giữ qua tick (SH-04)
struct Ports {
    ItemPort& items;
    WalletPort& wallet;
    ExpPort& exp;
};
// NOLINTEND(cppcoreguidelines-avoid-const-or-ref-data-members)

// ----- Nhật ký chống gửi lại ---------------------------------------------------------------------------------------
class Journal {
public:
    struct Record {
        std::uint64_t request = 0;
        Reason reason = Reason::kCommitted;
        friend bool operator==(const Record&, const Record&) noexcept = default;
    };

    // Biên nhận đã ghi (replayed = true), hoặc kStale nếu mã không chứng minh được là mới, hoặc nullopt nếu là mã mới.
    [[nodiscard]] std::optional<Receipt> seen(std::uint64_t request) const noexcept;
    void record(std::uint64_t request, Reason reason);

    [[nodiscard]] std::uint64_t floor() const noexcept { return floor_; }
    [[nodiscard]] std::span<const Record> records() const noexcept { return records_; }

    // Khôi phục từ bản lưu. Sai (quá cỡ, mã không tăng ngặt hoặc không lớn hơn mốc) thì không đổi gì và trả false.
    [[nodiscard]] bool restore(std::uint64_t floor, std::span<const Record> records);

    friend bool operator==(const Journal&, const Journal&) noexcept = default;

private:
    std::uint64_t floor_ = 0;
    std::vector<Record> records_;  // cũ nhất trước; mã tăng ngặt
};

// ----- Kiểm toán ----------------------------------------------------------------------------------------------------
struct AuditRecord {
    std::uint64_t request = 0;
    std::uint32_t source = 0;
    Reason reason = Reason::kCommitted;
    bool replayed = false;
    std::span<const Entry> entries;
};

class AuditSink {
public:
    AuditSink() = default;
    AuditSink(const AuditSink&) = delete;
    AuditSink& operator=(const AuditSink&) = delete;
    AuditSink(AuditSink&&) = delete;
    AuditSink& operator=(AuditSink&&) = delete;
    virtual ~AuditSink() = default;

    virtual void record(const AuditRecord& record) noexcept = 0;
};

// Chạy một giao dịch. Độ phức tạp O(n log n) với n <= kMaxEntries; không cấp phát ngoài vài vector nhỏ trần kMaxEntries.
[[nodiscard]] Receipt commit(Journal& journal, const Request& request, const Ports& ports, AuditSink* audit = nullptr);

}  // namespace game::ledger
