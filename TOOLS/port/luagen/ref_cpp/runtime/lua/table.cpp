#include "lua/table.hpp"

#include "core/check.hpp"
#include "lua/element.hpp"
#include "lua/number.hpp"
#include "lua/string.hpp"
#include "lua/vm.hpp"

#include <algorithm>
#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <utility>
#include <vector>

namespace game::lua {
namespace {

// luaO_log2: phần nguyên của log2, -1 cho 0 (lobject.c; bảng log_8 của gốc cho đúng giá trị này).
[[nodiscard]] constexpr std::int32_t log2_floor(std::uint32_t value) noexcept {
    return value == 0 ? -1 : std::bit_width(value) - 1;
}
static_assert(log2_floor(0) == -1 && log2_floor(1) == 0 && log2_floor(2) == 1 && log2_floor(3) == 1);
static_assert(log2_floor(4) == 2 && log2_floor(255) == 7 && log2_floor(256) == 8 && log2_floor(0xFFFFFFFFU) == 31);

// Hash của số (hashnum): n + 1 để -0 thành 1, rồi cộng hai nửa 32 bit (nửa thấp trước, như gốc trên máy little-endian).
[[nodiscard]] std::uint32_t number_hash(double number) noexcept {
    const auto bits = std::bit_cast<std::uint64_t>(number + 1.0);
    return static_cast<std::uint32_t>(bits) + static_cast<std::uint32_t>(bits >> 32);
}

constexpr std::int32_t twoto(std::int32_t power) noexcept {
    return std::int32_t{1} << power;
}

// Chỉ số mảng của khoá nếu nó đáng nằm trong phần mảng, -1 nếu không (arrayindex; toobig của gốc: quá 2^MAXBITS).
[[nodiscard]] std::int32_t array_index_of(Value key) noexcept {
    if (key.type() != Type::kNumber) return -1;
    const std::optional<std::int32_t> whole = exact_int32(key.as_number());
    if (!whole || *whole < 1 || *whole > twoto(Table::kMaxBits)) return -1;
    return *whole;
}

using Counts = std::array<std::int32_t, Table::kMaxBits + 1>;

// computesizes: nums[i] là số khoá nguyên trong (2^(i-1), 2^i]. narray vào là số khoá nguyên, ra là cỡ mảng; nhash ra là
// số phần tử còn lại cho phần băm.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): hai tham số ra, tên như computesizes của gốc.
void compute_sizes(const Counts& nums, std::int32_t total, std::int32_t& narray, std::int32_t& nhash) noexcept {
    std::int32_t accumulated = nums[0];
    std::int32_t in_array = accumulated;
    std::int32_t best = in_array == 0 ? -1 : 0;
    for (std::int32_t bit = 1; accumulated < narray && narray >= twoto(bit - 1); ++bit) {
        const std::int32_t here = element(nums, static_cast<std::size_t>(bit));
        if (here > 0) {
            accumulated += here;
            if (accumulated >= twoto(bit - 1)) {
                best = bit;
                in_array = accumulated;
            }
        }
    }
    nhash = total - in_array;
    // `best == -1 ? 0 : twoto(best)` bị MSVC 14.51 /O2 dịch sai (ra INT32_MIN, tức 1 << -1, ở nhánh lẽ ra là 0): viết điều kiện
    // theo `best < 0` (docs/BAY-DA-BIET.md, nhóm "Trình dịch, cờ và cổng kiểm").
    narray = best < 0 ? 0 : twoto(best);
}

} // namespace

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): luaH_new(narray, lnhash) của gốc.
Table::Table(std::uint32_t serial, std::size_t* heap_bytes, std::int32_t array_size, std::int32_t log2_nodes)
    : heap_bytes_(heap_bytes), serial_(serial) {
    core::check(array_size >= 0 && array_size <= twoto(kMaxBits), "Table: cỡ mảng ngoài miền");
    array_.assign(static_cast<std::size_t>(array_size), Value());
    set_node_vector(log2_nodes);
    *heap_bytes_ += sizeof(Table);
    account();
}

Table::~Table() {
    *heap_bytes_ -= sizeof(Table) + accounted_;
}

void Table::account() {
    const std::size_t now = array_.size() * sizeof(Value) + nodes_.size() * sizeof(Node);
    *heap_bytes_ = *heap_bytes_ - accounted_ + now;
    accounted_ = now;
}

std::size_t Table::main_position(Value key) const noexcept {
    const std::size_t size = nodes_.size();
    // hashmod của gốc: tránh chia dư cho luỹ thừa của hai vì số, con trỏ hay có nhiều thừa số 2.
    const auto by_modulus = [size](std::uint32_t hash) noexcept { return static_cast<std::size_t>(hash) % ((size - 1) | 1); };
    switch (key.type()) {
    case Type::kNumber: return by_modulus(number_hash(key.as_number()));
    case Type::kString: return static_cast<std::size_t>(key.as_string().hash()) & (size - 1);
    case Type::kBoolean: return static_cast<std::size_t>(key.as_boolean() ? 1 : 0) & (size - 1);
    case Type::kTable: return by_modulus(key.as_table().serial());
    case Type::kFunction: return by_modulus(function_serial(key.as_function()));
    case Type::kNil: break;
    }
    core::fail("Table::main_position: khoá nil không có vị trí");
}

std::int32_t Table::find_node(Value key) const noexcept {
    if (nodes_.empty()) return -1;
    auto at = static_cast<std::int32_t>(main_position(key));
    do {
        const Node& node = nodes_[static_cast<std::size_t>(at)];
        if (raw_equal(node.key, key)) return at;
        at = node.next;
    } while (at >= 0);
    return -1;
}

template <class Self>
auto* Table::locate_int(Self& self, std::int32_t key) noexcept {
    if (key >= 1 && static_cast<std::size_t>(key) <= self.array_.size()) return &self.array_[static_cast<std::size_t>(key) - 1];
    const std::int32_t at = self.find_node(Value::number(static_cast<double>(key)));
    return at >= 0 ? &self.nodes_[static_cast<std::size_t>(at)].value : nullptr;
}

template <class Self>
auto* Table::locate_string(Self& self, const String& key) noexcept {
    using Slot = decltype(&self.nodes_[0].value);
    if (self.nodes_.empty()) return Slot(nullptr);
    auto at = static_cast<std::int32_t>(static_cast<std::size_t>(key.hash()) & (self.nodes_.size() - 1));
    do {
        auto& node = self.nodes_[static_cast<std::size_t>(at)];
        if (node.key.type() == Type::kString && &node.key.as_string() == &key) return &node.value;
        at = node.next;
    } while (at >= 0);
    return Slot(nullptr);
}

template <class Self>
auto* Table::locate(Self& self, Value key) noexcept {
    using Slot = decltype(&self.nodes_[0].value);
    switch (key.type()) {
    case Type::kNil: return Slot(nullptr);
    case Type::kString: return locate_string(self, key.as_string());
    case Type::kNumber:
        if (const std::optional<std::int32_t> whole = exact_int32(key.as_number())) return locate_int(self, *whole);
        break;
    default: break;
    }
    const std::int32_t at = self.find_node(key);
    return at >= 0 ? &self.nodes_[static_cast<std::size_t>(at)].value : Slot(nullptr);
}

const Value* Table::find(Value key) const noexcept {
    return locate(*this, key);
}

const Value* Table::find_int(std::int32_t key) const noexcept {
    return locate_int(*this, key);
}

const Value* Table::find_string(const String& key) const noexcept {
    return locate_string(*this, key);
}

// set_slot, set_slot_int, new_key và rehash gọi nhau (chèn khoá mới đầy thì rehash rồi chèn lại); mỗi vòng mở rộng bảng
// nên có hạn.
// NOLINTBEGIN(misc-no-recursion)
Table::Slot Table::set_slot(Value key) {
    if (Value* const found = locate(*this, key)) return {.value = found, .fault = Fault::kNone};
    if (key.is_nil()) return {.value = nullptr, .fault = Fault::kNilKey};
    if (key.type() == Type::kNumber && key.as_number() != key.as_number()) return {.value = nullptr, .fault = Fault::kNanKey};
    return {.value = new_key(key), .fault = Fault::kNone};
}

Value* Table::set_slot_int(std::int32_t key) {
    if (Value* const found = locate_int(*this, key)) return found;
    return new_key(Value::number(static_cast<double>(key)));
}

void Table::set_node_vector(std::int32_t log2_nodes) {
    core::check(log2_nodes >= 0 && log2_nodes <= kMaxBits, "Table: phần băm vượt MAXBITS (trần heap của State phải chặn)");
    if (log2_nodes == 0) {
        nodes_ = std::vector<Node>();
        first_free_ = 0;
    } else {
        const auto size = static_cast<std::size_t>(twoto(log2_nodes));
        nodes_.assign(size, Node());
        first_free_ = size - 1;
    }
}

Value* Table::new_key(Value key) {
    if (nodes_.empty()) {
        // Phần băm rỗng của gốc là nút chung `dummynode`: chèn vào đó làm nó đầy ngay rồi rehash. Dựng tạm một nút để
        // chạy đúng mã của gốc.
        nodes_.assign(1, Node());
        first_free_ = 0;
    }
    std::size_t at = main_position(key);
    if (!nodes_[at].value.is_nil()) {
        // Vị trí chính đã có người. Xem người đó có đang ở vị trí chính của nó không.
        std::size_t other = main_position(nodes_[at].key);
        const std::size_t free_node = first_free_;
        if (other != at) {
            // Không: dời nó sang nút trống rồi đặt khoá mới vào vị trí chính.
            while (std::cmp_not_equal(nodes_[other].next, at))
                other = static_cast<std::size_t>(nodes_[other].next);
            nodes_[other].next = static_cast<std::int32_t>(free_node);
            nodes_[free_node] = nodes_[at];
            nodes_[at].next = -1;
            nodes_[at].value = Value();
        } else {
            // Có: khoá mới vào nút trống, nối sau nút chính.
            nodes_[free_node].next = nodes_[at].next;
            nodes_[at].next = static_cast<std::int32_t>(free_node);
            at = free_node;
        }
    }
    nodes_[at].key = key;
    for (;;) {
        if (nodes_[first_free_].key.is_nil()) return &nodes_[at].value;
        if (first_free_ == 0) break;
        --first_free_;
    }
    // Hết nút trống: đánh dấu giá trị khác nil để rehash không bỏ khoá mới, rồi mở rộng.
    nodes_[at].value = Value::boolean(false);
    rehash();
    Value* const moved = locate(*this, key);
    core::check(moved != nullptr && moved->type() == Type::kBoolean, "Table::new_key: khoá mới mất sau rehash");
    *moved = Value();
    return moved;
}

void Table::rehash() {
    // numuse: đếm phần tử theo khoảng (2^(i-1), 2^i] của khoá nguyên để tính cỡ mảng tối ưu.
    Counts nums{};
    std::int32_t total = 0;
    const auto array_len = static_cast<std::int32_t>(array_.size());
    std::int32_t index = 0;
    for (std::int32_t slice = 0; slice <= kMaxBits; ++slice) {
        std::int32_t limit = twoto(slice);
        if (limit > array_len) {
            limit = array_len;
            if (index >= limit) break;
        }
        for (; index < limit; ++index) {
            if (!array_[static_cast<std::size_t>(index)].is_nil()) {
                ++element(nums, static_cast<std::size_t>(slice));
                ++total;
            }
        }
    }
    std::int32_t narray = total;
    for (std::size_t node = nodes_.size(); node-- > 0;) {
        if (nodes_[node].value.is_nil()) continue;
        const std::int32_t key = array_index_of(nodes_[node].key);
        if (key >= 0) {
            const std::int32_t slice = log2_floor(static_cast<std::uint32_t>(key - 1)) + 1;
            ++element(nums, static_cast<std::size_t>(slice));
            ++narray;
        }
        ++total;
    }
    std::int32_t nhash = 0;
    compute_sizes(nums, total, narray, nhash);
    resize(narray, log2_floor(static_cast<std::uint32_t>(nhash)) + 1);
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): resize(t, nasize, nhsize) của gốc.
void Table::resize(std::int32_t new_array_size, std::int32_t new_log2_nodes) {
    const std::size_t old_array_size = array_.size();
    const auto new_array_len = static_cast<std::size_t>(new_array_size);
    std::vector<Node> old_nodes = std::move(nodes_);
    if (new_array_len > old_array_size) array_.resize(new_array_len);
    set_node_vector(new_log2_nodes);
    std::vector<Value> vanishing;
    if (new_array_len < old_array_size) {
        // Phần mảng teo đi: các ô từ new_array_size trở lên đi vào phần băm theo thứ tự tăng dần.
        vanishing.assign(array_.begin() + new_array_size, array_.end());
        array_.resize(new_array_len);
        array_.shrink_to_fit();
    }
    for (std::size_t i = 0; i < vanishing.size(); ++i) {
        if (!vanishing[i].is_nil()) *set_slot_int(static_cast<std::int32_t>(new_array_len + i + 1)) = vanishing[i];
    }
    // Chèn lại phần băm cũ từ nút cuối về nút đầu.
    for (std::size_t i = old_nodes.size(); i-- > 0;) {
        if (old_nodes[i].value.is_nil()) continue;
        const Slot slot = set_slot(old_nodes[i].key);
        core::check(slot.fault == Fault::kNone, "Table::resize: khoá cũ bị từ chối");
        *slot.value = old_nodes[i].value;
    }
    account();
}
// NOLINTEND(misc-no-recursion)

Table::Advance Table::next(Value key) const noexcept {
    // luaH_index: vị trí của khoá trong dãy "mảng rồi nút" (-1 là bắt đầu).
    std::int64_t position = -1;
    if (!key.is_nil()) {
        const std::int32_t whole = array_index_of(key);
        if (whole >= 1 && static_cast<std::size_t>(whole) <= array_.size()) {
            position = whole - 1;
        } else {
            const std::int32_t at = find_node(key);
            if (at < 0) return {.step = Step::kBadKey, .key = Value(), .value = Value()};
            position = at + static_cast<std::int64_t>(array_.size());
        }
    }
    for (auto i = static_cast<std::size_t>(position + 1); i < array_.size(); ++i) {
        if (!array_[i].is_nil()) return {.step = Step::kFound, .key = Value::number(static_cast<double>(i + 1)), .value = array_[i]};
    }
    const std::int64_t first_node = std::max<std::int64_t>(position + 1 - static_cast<std::int64_t>(array_.size()), 0);
    for (auto i = static_cast<std::size_t>(first_node); i < nodes_.size(); ++i) {
        if (!nodes_[i].value.is_nil()) return {.step = Step::kFound, .key = nodes_[i].key, .value = nodes_[i].value};
    }
    return {.step = Step::kEnd, .key = Value(), .value = Value()};
}

} // namespace game::lua
