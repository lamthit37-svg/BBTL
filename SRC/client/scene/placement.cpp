#include "scene/placement.hpp"

#include "core/number.hpp"
#include "scene/scene_file.hpp"

#include <algorithm>
#include <cstddef>
#include <string_view>

namespace game::scene {
namespace {

// Dấu tách của StringUtil::split trong OGRE.
constexpr std::string_view kDelimiters = "\t\n ";
// Khoảng trắng mà atof bỏ qua ở đầu chuỗi (isspace của locale "C").
constexpr std::string_view kLeadingSpaces = " \t\n\v\f\r";

// Cắt token kế tiếp khỏi đầu rest; rỗng khi rest không còn token nào.
[[nodiscard]] std::string_view take_token(std::string_view& rest) noexcept {
    const std::size_t start = std::min(rest.find_first_not_of(kDelimiters), rest.size());
    const std::size_t stop = std::min(rest.find_first_of(kDelimiters, start), rest.size());
    const std::string_view token = rest.substr(start, stop - start);
    rest.remove_prefix(stop);
    return token;
}

} // namespace

float parse_real(std::string_view text) noexcept {
    const std::size_t first = text.find_first_not_of(kLeadingSpaces);
    if (first == std::string_view::npos) return 0.0F;
    std::string_view digits = text.substr(first);
    // atof nhận dấu cộng đứng đầu, from_chars thì không.
    if (digits.starts_with('+')) digits.remove_prefix(1);
    const auto number = core::parse_double(digits);
    if (!number) return 0.0F;
    return static_cast<float>(number->value);
}

Vector3 parse_vector3(std::string_view text) noexcept {
    const std::string_view first = take_token(text);
    const std::string_view second = take_token(text);
    const std::string_view third = take_token(text);
    const bool is_three = !third.empty() && take_token(text).empty();
    if (!is_three) return {};
    Vector3 vector;
    vector.x = parse_real(first);
    vector.y = parse_real(second);
    vector.z = parse_real(third);
    return vector;
}

Quaternion parse_quaternion(std::string_view text) noexcept {
    const std::string_view first = take_token(text);
    const std::string_view second = take_token(text);
    const std::string_view third = take_token(text);
    const std::string_view fourth = take_token(text);
    const bool is_four = !fourth.empty() && take_token(text).empty();
    if (!is_four) return {};
    Quaternion turn;
    turn.w = parse_real(first);
    turn.x = parse_real(second);
    turn.y = parse_real(third);
    turn.z = parse_real(fourth);
    return turn;
}

Placement placement_of(const Object& object) noexcept {
    Placement placement;
    const auto position = property(object, "position");
    const auto orientation = property(object, "orientation");
    const auto scale = property(object, "scale");
    if (position) placement.position = parse_vector3(*position);
    if (orientation) placement.orientation = parse_quaternion(*orientation);
    if (scale) placement.scale = parse_vector3(*scale);
    return placement;
}

} // namespace game::scene
