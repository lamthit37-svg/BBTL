// Bảng băm khoá chuỗi tra được bằng string_view mà không dựng std::string. Dùng chung trong module
// gui (bảng chuỗi, chỉ mục tên của bộ nạp). Nội bộ module.
#pragma once

#include <cstddef>
#include <functional>
#include <string>
#include <string_view>
#include <unordered_map>

namespace game::gui::detail {

struct NameHash {
    // NOLINTNEXTLINE(readability-identifier-naming): tên do unordered_map đòi.
    using is_transparent = void;
    [[nodiscard]] static std::size_t operator()(std::string_view text) noexcept {
        return std::hash<std::string_view>{}(text);
    }
};

template <class Value>
using NameMap = std::unordered_map<std::string, Value, NameHash, std::equal_to<>>;

} // namespace game::gui::detail
