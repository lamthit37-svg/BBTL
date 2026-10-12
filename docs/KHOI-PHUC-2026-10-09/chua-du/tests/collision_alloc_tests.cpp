// Đếm cấp phát cho module collision (DE-BAI DH đợt 1, mục 3 và tiêu chí G3, H1, H2). Exe này thay
// operator new và operator delete toàn cục, nên đứng riêng: mọi exe khác giữ bộ cấp phát chuẩn.
// Cách đếm theo mục 3 của đề: thay mọi biến thể operator new (thường, [], nothrow,
// std::align_val_t), đếm số lần gọi và số byte xin trong lúc gọi mã cần soi; delete không tính.
// Ba ca tự kiểm chứng minh bộ đếm đúng trước khi tin nó: duyệt vector có sẵn đọc 0, một push_back
// vào vector rỗng đọc 1, bản căn lề và bản mảng cũng được đếm. Con trỏ vừa cấp phát được ghi ra
// biến atomic toàn cục để trình dịch không được xoá cặp new/delete (C++14 cho phép gộp hay bỏ).
// G3 soi collision::detail::parse_building_file trên 69 ca của tests/collision_hostile.hpp (byte trong mã; bảng ở
// docs/giao-viec/DH-DOT-1/so-do/a-g3-tep-sinh-3.md): 56 ca G3 (52 bị từ chối, 4 nạp được; g3-20 nạp theo R2-1), 9
// ca nạp như bản gốc (không tính vào G3, so với log oracle ở tests/collision_nap_goc.hpp) và 4 tệp gốc. Byte của
// mỗi ca là mảng constexpr của header
// (không cấp phát); mọi ca, kể cả ca nạp được, parse phải ra đúng lỗi hay đúng "nạp được" với 0 lần cấp phát.
// H1, H2 chờ Model của vai C: mỗi ca in "chờ Model" ra stderr và được đếm là ca chờ; main trả 77 khi không có kỳ
// vọng nào hỏng (tests/collision_report.hpp).
#include "collision/building_file.hpp"
#include "collision_hostile.hpp"
#include "collision_report.hpp"
#include "core/check.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <functional>
#include <limits>
#include <memory>
#include <new>
#include <numeric>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace {

using Size = std::size_t;
using Align = std::align_val_t;
using NoThrow = std::nothrow_t;

// operator new thay thế không nhận ngữ cảnh nào, nên bộ đếm và chỗ giữ con trỏ phải là trạng thái
// toàn cục ghi được; chỉ exe test này có chúng, atomic nên đếm đúng cả khi test có luồng.
// NOLINTBEGIN(cppcoreguidelines-avoid-non-const-global-variables) bộ đếm của operator new thay thế (HP-12)
constinit std::atomic<std::uint64_t> allocation_calls{0};
constinit std::atomic<std::uint64_t> allocation_bytes{0};
constinit std::atomic<const void*> pointer_sink{nullptr};
constinit std::atomic<std::int64_t> number_sink{0};
// NOLINTEND(cppcoreguidelines-avoid-non-const-global-variables)

void note_allocation(Size size) noexcept {
    allocation_calls.fetch_add(1, std::memory_order_relaxed);
    allocation_bytes.fetch_add(size, std::memory_order_relaxed);
}

⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
[[nodiscard]] std::optional<LoadError> outcome(const ParseResult& parsed) noexcept {
    if (parsed) return std::nullopt;
    return parsed.error();
}

// Một ca G3: byte là mảng constexpr của header (không cấp phát); chỉ lời gọi parse nằm trong cửa sổ đếm, kết quả
// đúng bảng và 0 lần, 0 byte cấp phát. Trả số lần cấp phát đếm được trong cửa sổ.
[[nodiscard]] std::uint64_t check_hostile(Context& context, const HostileCase& item) {
    const Tally start = tally_now();
    const ParseResult parsed = collision::detail::parse_building_file(item.bytes);
    const Tally spent = tally_since(start);
    const std::optional<LoadError> got = outcome(parsed);
    context.expect(got == item.expected, "parse ra đúng kết quả của bảng");
    context.expect(spent.calls == 0 && spent.bytes == 0, "parse: 0 lần cấp phát, 0 byte");
    if (got != item.expected) report(item.name, got ? collision::describe(*got) : "nạp được");
    if (spent.calls != 0) report(item.name, "parse có cấp phát");
    return spent.calls;
}

// G3: tệp hỏng (số đếm 0xFFFFFFFF, chỉ số vượt mảng, số không hữu hạn, mã bản lạ, cắt cụt, đuôi
// thừa) bị từ chối, tệp hợp lệ ra view, đều không cấp phát: view chỉ giữ số và span.
void hostile_files_fail_before_alloc(Context& context) {
    std::uint64_t calls = 0;
    std::size_t g3_cases = 0;
    std::size_t oracle = 0;
    std::size_t rejected = 0;
    for (const HostileCase& item : collision::test::hostile_cases()) {
        calls += check_hostile(context, item);
        g3_cases += static_cast<std::size_t>(collision::test::is_g3(item));
        rejected += static_cast<std::size_t>(collision::test::is_g3(item) && collision::test::is_rejected(item));
        oracle += static_cast<std::size_t>(collision::test::is_oracle_load(item));
    }
    const std::size_t bases = collision::test::hostile_cases().size() - g3_cases - oracle;
    const std::string g3_text = std::to_string(g3_cases) + " ca G3 (" + std::to_string(rejected) + " từ chối), ";
    const std::string cases = g3_text + std::to_string(oracle) + " ca nạp như bản gốc và ";
    const std::string checked = "đã kiểm " + cases + std::to_string(bases) + " tệp gốc";
    report("hostile_files_fail_before_alloc (G3)", checked + ", cấp phát khi parse: " + std::to_string(calls));
}

// H1 chờ Model của vai C: nạp tệp tự vẽ của mỗi mã bản và ba cảnh của H3 khi có GAME_CLIENT_DATA,
// rồi 10.000 lời gọi mỗi truy vấn height(x, z), raycast(origin, dir), bounds() (đều const noexcept,
// điểm sinh từ hạt giống cố định trong bounds()); tally_since đọc 0 lần cho cả lô của mỗi truy vấn.
void queries_allocate_nothing(Context&) {
    say_skipped(kProgram, "queries_allocate_nothing (H1)", "chờ Model của C");
}

// H2 chờ Model của vai C: collision::load thành công cấp phát đúng N = 3 lần (đỉnh, chỉ số, cây);
// với mỗi mã bản, tệp tự vẽ nhỏ và tệp lớn nhất (fenghuang mã 1, bianjing mã 2) ra cùng con số.
void loading_allocates_a_fixed_count(Context&) {
    say_skipped(kProgram, "loading_allocates_a_fixed_count (H2)", "chờ Model của C");
}

constexpr std::array kCases{
    Case{.name = "reading_a_vector_allocates_nothing", .body = &reading_a_vector_allocates_nothing},
    Case{.name = "first_push_back_allocates_once", .body = &first_push_back_allocates_once},
    Case{.name = "aligned_and_array_new_are_counted", .body = &aligned_and_array_new_are_counted},
    Case{.name = "hostile_files_fail_before_alloc", .body = &hostile_files_fail_before_alloc},
    Case{.name = "queries_allocate_nothing", .body = &queries_allocate_nothing},
    Case{.name = "loading_allocates_a_fixed_count", .body = &loading_allocates_a_fixed_count},
};

} // namespace
} // namespace game::test

int main() {
    return game::test::exit_code(game::test::run_all(game::test::kCases));
}
