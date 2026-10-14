#pragma once
// Xác suất rơi đồ bằng số nguyên: tỉ lệ num/den không tràn dù bảng đưa số lớn, và đọc số thập phân của bảng ra phần triệu.
//
// Công thức (ItemBoxRuler::CreateItemFromMonsterDrop của 2008):
//     p = (giá trị quái / giá trị gói) x hệ số chênh cấp x DropParam x hệ số chống nghiện
// 2008 tính bằng double rồi so với một số ngẫu nhiên trong [0, 1). Bản này giữ nguyên công thức nhưng mọi thừa số là số
// nguyên phần triệu: tích được tính trên 128 bit rồi tỉ lệ co về dưới 2^62, nên không phép nào tràn và kết quả không phụ thuộc
// kiểu dấu phẩy động của máy. Sai số tuyệt đối của mỗi phép co dưới 2^-61 (xác suất nhỏ nhất của bảng thật khoảng 4 / 10^8
// nên sai số tương đối dưới 10^-10).

#include "loot/types.hpp"

#include "dice/dice.hpp"

#include <cstdint>
#include <optional>
#include <string_view>

namespace game::loot {

// Phân số num/den với den >= 1 và cả hai dưới 2^62. num >= den nghĩa là chắc chắn.
struct Ratio {
    std::uint64_t num = 0;
    std::uint64_t den = 1;

    friend constexpr bool operator==(const Ratio&, const Ratio&) noexcept = default;
};

// Đọc số thập phân không dấu ("0.05", "1", "12.5") ra phần triệu. nullopt khi rỗng, có ký tự lạ, quá 6 chữ số thập phân
// khác 0, hay lớn hơn max_ppm.
[[nodiscard]] std::optional<std::uint32_t> parse_ppm(std::string_view text, std::uint32_t max_ppm) noexcept;

// Các thừa số của công thức, đặt tên từng trường để lúc gọi không nhầm thứ tự các số cùng kiểu.
struct DropFactors {
    std::int64_t monster_value = 0;   // mvalue của quái
    std::int64_t box_value = 1;       // box_value của gói
    std::uint32_t gap_ppm = kPpm;     // hệ số chênh cấp (phần triệu: 1'000'000 là 1,0)
    std::uint32_t param_ppm = kPpm;   // DropParam
    std::uint32_t wallow_ppm = kPpm;  // hệ số chống nghiện
};

// Xác suất rơi của một gói. monster_value hay box_value <= 0 cho 0 (quái không mang giá trị thì không rơi gì; gói không
// giá trị bị bảng từ chối từ lúc nạp).
[[nodiscard]] Ratio drop_ratio(const DropFactors& factors) noexcept;

// Một lần thử: luôn hỏi dice một lần (kể cả khi chắc chắn hay không thể) để dòng ngẫu nhiên không phụ thuộc giá trị bảng.
[[nodiscard]] bool succeeds(const Ratio& ratio, dice::Dice& dice) noexcept;

} // namespace game::loot
