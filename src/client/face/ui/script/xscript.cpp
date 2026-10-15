#include "ui/script/xscript.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <iterator>
#include <string_view>
#include <utility>

namespace game::ui::script {

void XScript::set_function(std::string_view name) noexcept {
    const std::size_t length = std::min({name.find('\0'), name.size(), kXScriptNameLimit});
    record_.name.fill('\0');
    std::copy_n(name.begin(), length, record_.name.begin());
    record_.name_length = static_cast<std::uint8_t>(length);
}

void XScript::set_param(std::uint8_t slot, std::int32_t value) noexcept {
    if (slot < record_.params.size()) *std::next(record_.params.begin(), slot) = value;
}

// Cấp phát vector thất bại thì dừng tiến trình: hàm này chạy dưới hàm C mà Lua gọi, ngoại lệ C++ không được thoát qua khung C của LuaPlus.
// NOLINTNEXTLINE(bugprone-exception-escape)
void XScript::send() noexcept {
    if (sent_.size() >= kXScriptOutboxLimit) {
        ++dropped_;
        return;
    }
    sent_.push_back(record_);
}

std::int32_t XParamRecord::int_at(std::int32_t index) const noexcept {
    if (index < 0 || std::cmp_greater_equal(index, std::min<std::size_t>(int_count, ints.size()))) return 0;
    return *std::next(ints.begin(), index);
}

std::string_view XParamRecord::string_at(std::int32_t index) const noexcept {
    if (index < 0 || std::cmp_greater_equal(index, std::min<std::size_t>(string_count, strings.size()))) return {};
    return *std::next(strings.begin(), index);
}

} // namespace game::ui::script
