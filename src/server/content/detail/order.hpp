#pragma once
// So sánh byte và số để xếp giá trị thiếu. Tách khỏi coverage.cpp cho tệp đó dưới 500 dòng.

#include "content/detail/scan.hpp"

#include <charconv>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <string>
#include <system_error>

namespace game::content {

struct RefPair {
    std::string capture;
    std::string value;
};

struct BytePair {
    TextView left;
    TextView right;
};

[[nodiscard]] inline int compare_at(const BytePair& bytes, std::size_t index) noexcept {
    const int left_byte = static_cast<unsigned char>(bytes.left[index]);
    const int right_byte = static_cast<unsigned char>(bytes.right[index]);
    if (left_byte < right_byte) return -1;
    if (left_byte > right_byte) return 1;
    return 0;
}

struct ByteWalk {
    int order = 0;
    std::size_t index = 0;
};

inline void step_bytes(ByteWalk& walk, const BytePair& bytes) noexcept {
    if (walk.order != 0) return;
    walk.order = compare_at(bytes, walk.index);
    walk.index += 1;
}

[[nodiscard]] inline int compare_bytes(const BytePair& bytes) noexcept {
    const std::size_t count = std::min(bytes.left.size(), bytes.right.size());
    ByteWalk walk;
    while (walk.index < count && walk.order == 0)
        step_bytes(walk, bytes);
    if (walk.order != 0) return walk.order;
    if (bytes.left.size() < bytes.right.size()) return -1;
    if (bytes.left.size() > bytes.right.size()) return 1;
    return 0;
}

[[nodiscard]] inline bool bytes_less(const BytePair& bytes) noexcept {
    return compare_bytes(bytes) < 0;
}

struct MissLess {
    bool as_int = false;

    [[nodiscard]] bool operator()(const RefPair& left, const RefPair& right) const {
        const BytePair captures{.left = left.capture, .right = right.capture};
        const int capture = compare_bytes(captures);
        if (capture != 0) return capture < 0;
        const BytePair values{.left = left.value, .right = right.value};
        if (!as_int) return bytes_less(values);
        return value_less(values);
    }

    [[nodiscard]] static bool value_less(const BytePair& values) {
        const std::int64_t lvalue = int_key(values.left);
        const std::int64_t rvalue = int_key(values.right);
        if (lvalue != rvalue) return lvalue < rvalue;
        return bytes_less(values);
    }

    [[nodiscard]] static std::int64_t int_key(TextView text) noexcept {
        std::int64_t value = 0;
        const CharSpan chars = chars_of(text);
        const auto result = std::from_chars(chars.begin, chars.end, value);
        if (result.ec != std::errc{} || result.ptr != chars.end) return std::numeric_limits<std::int64_t>::max();
        return value;
    }
};

} // namespace game::content
