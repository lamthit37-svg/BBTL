#pragma once
// Nội bộ mission: một giao dịch đang dựng. Work giữ BẢN NHÁP của Book và danh sách dòng sổ cái; hiệu ứng của ops::Plan được áp
// dụng lên bản nháp, finish() chạy sổ cái rồi mới thay Book thật. Module khác không include tệp này.

#include "ledger/ledger.hpp"
#include "mission/book.hpp"
#include "mission/catalog.hpp"
#include "mission/engine.hpp"
#include "mission/hero.hpp"
#include "ops/ops.hpp"

#include <cstdint>
#include <optional>
#include <vector>

namespace game::mission::detail {

class Work {
public:
    Work(Character& who, const Catalog& catalog, const ops::Calendar& calendar);

    // Áp dụng kế hoạch hiệu ứng (điều kiện từng hiệu ứng đã được đánh giá lúc dựng Plan).
    void apply(const ops::Plan& plan);
    void apply(const ops::Effect& effect);

    void entry(ledger::EntryKind kind, std::uint32_t item, std::int64_t amount, bool bound);
    void notice(NoticeKind kind, std::int32_t quest, std::int64_t value = 0, std::int32_t ref = 0);
    void add_quest(std::int32_t quest, std::uint32_t script, std::uint8_t watch);
    void remove_quest(std::int32_t quest);
    // Cộng/trừ bộ đếm quan hệ có kẹp [0, kMaxRelationship].
    void add_relation(std::int32_t index, std::int64_t delta);
    void fail_with(Error error) noexcept;

    // Ghi `source` (id nhiệm vụ) vào nhật ký kiểm toán. Có dòng sổ cái thì chạy sổ cái; thành công thì Book thật = bản nháp.
    [[nodiscard]] Result finish(std::uint32_t source);

    // Số vật phẩm sẽ có trong túi sau các dòng sổ cái đã dựng (túi hiện tại + nhận - thu).
    [[nodiscard]] std::int64_t projected_items(std::uint32_t item) const noexcept;
    [[nodiscard]] Character& who() noexcept { return who_; }
    [[nodiscard]] const Catalog& catalog() const noexcept { return catalog_; }
    [[nodiscard]] const ops::Calendar& calendar() const noexcept { return calendar_; }
    [[nodiscard]] Book& draft() noexcept { return draft_; }
    [[nodiscard]] Outcome& outcome() noexcept { return out_; }
    [[nodiscard]] bool failed() const noexcept { return failed_.has_value(); }

private:
    // NOLINTBEGIN(cppcoreguidelines-avoid-const-or-ref-data-members): Work sống trong một lần gọi của Engine, ba thứ này sống lâu hơn nó, không sở hữu, không giữ qua tick (SH-04)
    Character& who_;
    const Catalog& catalog_;
    const ops::Calendar& calendar_;
    // NOLINTEND(cppcoreguidelines-avoid-const-or-ref-data-members)
    Book draft_;
    std::vector<ledger::Entry> entries_;
    Outcome out_;
    std::optional<Failure> failed_;
};

// Giá trị tham số ô lưu dạng u32: kẹp vào [0, UINT32_MAX] khi cộng.
[[nodiscard]] std::uint32_t saturating_param(std::int64_t value) noexcept;

// Ngữ cảnh đánh giá điều kiện cho một nhân vật tại một thời điểm.
[[nodiscard]] ops::Context make_context(const HeroFacade& hero, const ops::Calendar& calendar) noexcept;

}  // namespace game::mission::detail
