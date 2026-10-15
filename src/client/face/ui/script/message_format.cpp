#include "ui/script/message_format.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string_view>

namespace game::ui::script {
namespace {

constexpr char kStar = '*';
constexpr char kEnd = '}';
// Tổng độ dài đối số mà gốc thêm một dấu cách (byte tổng + 3 sẽ là 0x3b, ';').
constexpr std::size_t kPadAt = 0x38;
constexpr std::size_t kHeader = 3;

// Chuỗi C của gốc: dừng ở byte NUL đầu tiên.
[[nodiscard]] std::string_view c_text(std::string_view text) noexcept { return text.substr(0, text.find('\0')); }

} // namespace

std::optional<std::size_t> pack_message(std::string_view pattern, std::span<const std::string_view> args,
    std::span<char, kMessageBufferSize> out) {
    pattern = c_text(pattern);
    if (pattern.empty() || args.size() > kMessageArgLimit) return std::nullopt;

    std::size_t size = 0;
    for (const std::string_view arg : args) size += 2 + c_text(arg).size();
    const std::size_t pad = size == kPadAt ? 1 : 0;
    // Chỗ cho tiêu đề (n + 2 byte), đối số, dấu cách đệm, '}' và NUL cuối.
    if (pattern.size() + 2 + size + pad + 2 > kMessageBufferSize) return std::nullopt;

    std::ranges::fill(out, '\0');
    auto cursor = out.begin();
    cursor = std::ranges::copy(pattern.substr(0, pattern.size() - 1), cursor).out;
    *cursor++ = kStar;
    *cursor++ = static_cast<char>(args.size());
    const auto size_byte = cursor++;
    for (const std::string_view raw : args) {
        const std::string_view arg = c_text(raw);
        *cursor++ = kStar;
        *cursor++ = static_cast<char>(static_cast<std::uint8_t>(arg.size()));
        cursor = std::ranges::copy(arg, cursor).out;
    }
    if (pad != 0) *cursor++ = ' ';
    *cursor = kEnd;
    *size_byte = static_cast<char>(static_cast<std::uint8_t>(size + pad + kHeader));

    const std::string_view whole(out.data(), out.size());
    return whole.find('\0');
}

} // namespace game::ui::script
