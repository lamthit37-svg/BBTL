#include "ui/script/pool_image.hpp"

#include <algorithm>
#include <cstdint>
#include <span>

namespace game::ui::script {
namespace {

// Cắt giá trị thô về độ rộng của bộ nhớ rồi mở rộng theo dấu, như một lần đọc *(T *)(pool + offset).
std::int64_t narrow(std::int64_t raw, Width width) noexcept {
    switch (width) {
    case Width::kI8: return static_cast<std::int8_t>(raw);
    case Width::kU8: return static_cast<std::uint8_t>(raw);
    case Width::kI16: return static_cast<std::int16_t>(raw);
    case Width::kU16: return static_cast<std::uint16_t>(raw);
    case Width::kI32: return static_cast<std::int32_t>(raw);
    case Width::kU32: return static_cast<std::uint32_t>(raw);
    }
    return 0;
}

} // namespace

bool PoolImage::write(std::uint32_t offset, std::int64_t value) {
    if (!values_.contains(offset) && values_.size() >= kLimit) return false;
    values_.insert_or_assign(offset, value);
    return true;
}

std::int64_t PoolImage::read(PoolField field, std::span<const PoolInitial> initial) const noexcept {
    if (const auto written = values_.find(field.offset); written != values_.end()) return narrow(written->second, field.width);
    const auto found = std::ranges::find_if(initial, [field](const PoolInitial& entry) { return entry.offset == field.offset && entry.width == field.width; });
    return found == initial.end() ? 0 : narrow(found->value, field.width);
}

} // namespace game::ui::script
