#include "lua/string.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <string_view>
#include <utility>
#include <vector>

namespace game::lua {
namespace {

constexpr std::size_t kInitialBuckets = 64;

// FNV-1a 64 bit.
[[nodiscard]] std::uint64_t table_hash_of(std::string_view bytes) noexcept {
    std::uint64_t hash = 14'695'981'039'346'656'037ULL;
    for (const char letter : bytes) {
        hash ^= static_cast<std::uint8_t>(letter);
        hash *= 1'099'511'628'211ULL;
    }
    return hash;
}

} // namespace

std::uint32_t string_hash(std::string_view bytes) noexcept {
    const std::size_t length = bytes.size();
    // Khác gốc: gốc ép độ dài sang lu_hash (unsigned int); static_cast ở đây chỉ làm điều đó tường minh.
    auto hash = static_cast<std::uint32_t>(length);
    const std::size_t step = (length >> 5) + 1;
    for (std::size_t at = length; at >= step; at -= step)
        hash ^= (hash << 5) + (hash >> 2) + static_cast<std::uint8_t>(bytes[at - 1]);
    return hash;
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): hàm dựng chỉ StringTable gọi, hai băm có kiểu khác nhau về cỡ.
String::String(std::string_view bytes, std::uint32_t lua_hash, std::uint64_t table_hash)
    : text_(bytes), table_hash_(table_hash), lua_hash_(lua_hash) {}

StringTable::StringTable() : buckets_(kInitialBuckets, nullptr) {}

StringTable::Interned StringTable::intern(std::string_view bytes) {
    const std::uint64_t key = table_hash_of(bytes);
    const std::size_t bucket = static_cast<std::size_t>(key) & (buckets_.size() - 1);
    for (String* found = buckets_[bucket]; found != nullptr; found = found->chain_) {
        if (found->table_hash_ == key && found->text_ == bytes) return {.string = found, .created = false};
    }
    auto made = std::make_unique<String>(bytes, string_hash(bytes), key);
    String* const raw = made.get();
    owned_.push_back(std::move(made));
    raw->chain_ = buckets_[bucket];
    buckets_[bucket] = raw;
    bytes_ += raw->footprint();
    // Như luaS_newlstr: nhiều chuỗi hơn ngăn thì nhân đôi số ngăn.
    if (owned_.size() > buckets_.size()) grow();
    return {.string = raw, .created = true};
}

void StringTable::grow() {
    std::vector<String*> wider(buckets_.size() * 2, nullptr);
    for (const std::unique_ptr<String>& one : owned_) {
        const std::size_t bucket = static_cast<std::size_t>(one->table_hash_) & (wider.size() - 1);
        one->chain_ = wider[bucket];
        wider[bucket] = one.get();
    }
    buckets_ = std::move(wider);
}

std::size_t StringTable::sweep() {
    std::size_t freed = 0;
    const auto dead = std::ranges::partition(owned_, [](const std::unique_ptr<String>& one) { return one->marked_; });
    for (const std::unique_ptr<String>& one : dead)
        freed += one->footprint();
    owned_.erase(dead.begin(), dead.end());
    bytes_ -= freed;
    std::ranges::fill(buckets_, nullptr);
    for (const std::unique_ptr<String>& one : owned_) {
        one->marked_ = false;
        const std::size_t bucket = static_cast<std::size_t>(one->table_hash_) & (buckets_.size() - 1);
        one->chain_ = buckets_[bucket];
        buckets_[bucket] = one.get();
    }
    return freed;
}

} // namespace game::lua
