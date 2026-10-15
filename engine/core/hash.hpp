/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/hash.hpp
 *  PHÂN HỆ   : Core / Hash
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Băm không mật mã cho bảng băm, khoá tài nguyên và phát hiện thay đổi.
 *    Không dùng cho chữ ký hay mật khẩu: việc đó của sha256.hpp và siphash.hpp.
 *    Nguồn: core/hash của No1, trùng từng bit với bản transport/wire đã dùng
 *    (fnv1a, mix64, hash_combine) nên dữ liệu đã băm vẫn khớp. fnv1_hash 32 bit
 *    của _Ref (tf_mem_hash) ở math/scalar.hpp, vì nó giữ đúng giá trị cũ cho dữ
 *    liệu đã có.
 *  - Nguồn: Forge2 src/core/hash.hpp@d7fcd76. Khác gốc: bỏ phép ép std::size_t
 *    trong std::hash của NameId mà GCC báo thừa (kèm static_assert nền 64 bit).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include <cstddef>
#include <cstdint>
#include <functional>
#include <span>
#include <string_view>

namespace game::core {

inline constexpr std::uint64_t kFnvOffsetBasis = 0xcbf29ce484222325ULL;
inline constexpr std::uint64_t kFnvPrime = 0x100000001b3ULL;

// FNV-1a 64 bit. Chậm hơn xxHash trên dữ liệu lớn nhưng constexpr được, nên tên tài nguyên băm được
// ngay lúc biên dịch và trở thành một hằng số nguyên trong mã máy. seed để băm nối nhiều đoạn.
[[nodiscard]] constexpr std::uint64_t fnv1a(std::string_view text, std::uint64_t seed = kFnvOffsetBasis) noexcept {
    std::uint64_t hash = seed;
    for (const char character : text) {
        hash ^= static_cast<std::uint64_t>(static_cast<std::uint8_t>(character));
        hash *= kFnvPrime;
    }
    return hash;
}

[[nodiscard]] constexpr std::uint64_t fnv1a(std::span<const std::byte> bytes,
    std::uint64_t seed = kFnvOffsetBasis) noexcept {
    std::uint64_t hash = seed;
    for (const std::byte value : bytes) {
        hash ^= static_cast<std::uint64_t>(value);
        hash *= kFnvPrime;
    }
    return hash;
}

// Bộ trộn bit cuối của SplitMix64: song ánh, đảo được, nên không bao giờ là hàm có khoá. Biến một
// bộ đếm tăng đều thành dãy bit rải đều; dùng để trộn khoá trước khi vào bảng băm và làm nguồn cho
// bộ sinh số giả ngẫu nhiên.
[[nodiscard]] constexpr std::uint64_t mix64(std::uint64_t value) noexcept {
    value ^= value >> 30;
    value *= 0xbf58476d1ce4e5b9ULL;
    value ^= value >> 27;
    value *= 0x94d049bb133111ebULL;
    value ^= value >> 31;
    return value;
}

// Gộp thêm một giá trị băm vào giá trị đã có. Không đối xứng: đổi thứ tự cho ra kết quả khác, đúng
// ý cho việc băm một bộ trường có thứ tự.
// NOLINTBEGIN(bugprone-easily-swappable-parameters): giá trị đã gộp rồi giá trị thêm (lệch API-03)
[[nodiscard]] constexpr std::uint64_t hash_combine(std::uint64_t accumulated, std::uint64_t value) noexcept {
    const std::uint64_t spread = value + 0x9e3779b97f4a7c15ULL;
    return mix64(accumulated ^ (spread + (accumulated << 6) + (accumulated >> 2)));
}
// NOLINTEND(bugprone-easily-swappable-parameters)

// Tên đã băm sẵn làm khoá. Giá trị 0 là "chưa đặt tên": chuỗi rỗng cho NameId không hợp lệ (băm FNV
// của nó là kFnvOffsetBasis, khác 0, nên phải loại tường minh).
class NameId {
public:
    constexpr NameId() noexcept = default;
    constexpr explicit NameId(std::string_view text) noexcept : value_(text.empty() ? 0 : fnv1a(text)) {}

    [[nodiscard]] constexpr std::uint64_t value() const noexcept { return value_; }
    [[nodiscard]] constexpr bool valid() const noexcept { return value_ != 0; }
    [[nodiscard]] constexpr bool operator==(const NameId&) const noexcept = default;
    [[nodiscard]] constexpr auto operator<=>(const NameId&) const noexcept = default;

private:
    std::uint64_t value_ = 0;
};

} // namespace game::core

// Khác gốc: gốc ép kết quả mix64 sang std::size_t. Trên nền 64 bit hai kiểu cùng độ rộng (GCC báo
// -Wuseless-cast), nên bỏ phép ép và chặn nền 32 bit ngay tại đây.
static_assert(sizeof(std::size_t) == sizeof(std::uint64_t), "NameId cần nền 64 bit");

template <>
struct std::hash<game::core::NameId> {
    [[nodiscard]] std::size_t operator()(const game::core::NameId& id) const noexcept {
        return game::core::mix64(id.value());
    }
};
