// Mỗi đoạn rỗi nằm trong một ngăn theo cỡ: ngăn là số thực nhỏ 8 bit (3 bit phần định trị, 5 bit số
// mũ) nên sai số tương đối tối đa 12,5% và 256 ngăn phủ cả dải 32 bit. Bitmask hai tầng (32 ngăn
// trên, 8 ngăn lá mỗi tầng) cho phép tìm ngăn không rỗng nhỏ nhất đủ chỗ bằng hai lần đếm bit. Cấp
// phát làm tròn cỡ yêu cầu LÊN để mọi đoạn trong ngăn tìm được đều đủ; chèn đoạn rỗi làm tròn
// XUỐNG để đoạn luôn nằm đúng ngăn của cỡ mình.
// Nguồn: Forge2 src/core/range.cpp@d7fcd76. Khác gốc: check là bản của THIENLONG (thông điệp cố
// định, không kèm số); vòng for của fit_below thành while; lệnh return kèm lời gọi hàm void tách
// làm hai.
#include "core/range.hpp"

#include "core/check.hpp"

#include <algorithm>
#include <bit>
#include <cstdint>
#include <limits>
#include <memory>
#include <mutex>
#include <new>
#include <optional>
#include <utility>

namespace game::core {

namespace {

constexpr std::uint32_t kMantissaBits = 3;
constexpr std::uint32_t kMantissaValue = 1U << kMantissaBits;
constexpr std::uint32_t kMantissaMask = kMantissaValue - 1;

// Ngăn của một cỡ. Cỡ dưới 8 là số mũ 0 (mỗi cỡ một ngăn); từ 8 trở lên số mũ tăng theo bit cao
// nhất. Làm tròn lên cộng một vào ngăn khi còn bit lẻ; phép cộng tràn phần định trị sang số mũ đúng
// chỗ vì hai trường nằm liền nhau.
[[nodiscard]] constexpr std::uint32_t bin_of(std::uint32_t size, bool round_up) noexcept {
    if (size < kMantissaValue) return size;
    const auto width = static_cast<std::uint32_t>(std::bit_width(size));
    const std::uint32_t shift = width - 1 - kMantissaBits;
    const std::uint32_t mantissa = (size >> shift) & kMantissaMask;
    const std::uint32_t bin = ((shift + 1) << kMantissaBits) + mantissa;
    const bool has_rest = (size & ((1U << shift) - 1)) != 0;
    return round_up && has_rest ? bin + 1 : bin;
}

// Bit thấp nhất đang bật từ vị trí from trở lên; 0xFFFFFFFF khi không có.
[[nodiscard]] constexpr std::uint32_t lowest_from(std::uint32_t mask, std::uint32_t from) noexcept {
    if (from >= 32) return 0xFFFF'FFFFU;
    const std::uint32_t kept = mask & (~std::uint32_t{0} << from);
    return kept == 0 ? 0xFFFF'FFFFU : static_cast<std::uint32_t>(std::countr_zero(kept));
}

} // namespace

// NOLINTBEGIN(bugprone-easily-swappable-parameters): số đơn vị rồi số nút quản lý nó (lệch API-03)
RangeAllocator::RangeAllocator(std::uint32_t total, std::uint32_t max_nodes) : total_(total), nodes_(max_nodes) {
    check(max_nodes >= 1, "RangeAllocator: cần ít nhất một nút");
    spare_.reserve(max_nodes);
    reset();
}
// NOLINTEND(bugprone-easily-swappable-parameters)

// noexcept chủ ý: spare_ đã reserve đủ max_nodes nên push_back không cấp phát; at() ném nghĩa là
// bất biến đã hỏng và đích duy nhất là std::terminate (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
void RangeAllocator::reset() noexcept {
    free_size_ = 0;
    free_regions_ = 0;
    used_top_ = 0;
    used_leaf_.fill(0);
    heads_.fill(kUnused);
    spare_.clear();
    for (auto index = static_cast<std::uint32_t>(nodes_.size()); index-- > 0;) {
        spare_.push_back(index);
    }
    if (total_ > 0) static_cast<void>(insert(total_, 0));
}

void RangeAllocator::fill_bin(std::uint32_t bin) noexcept {
    const std::uint32_t top = bin >> kLeafShift;
    used_leaf_.at(top) = static_cast<std::uint8_t>(used_leaf_.at(top) | (1U << (bin & (kLeafBins - 1))));
    used_top_ |= 1U << top;
}

void RangeAllocator::empty_bin(std::uint32_t bin) noexcept {
    const std::uint32_t top = bin >> kLeafShift;
    used_leaf_.at(top) = static_cast<std::uint8_t>(used_leaf_.at(top) & ~(1U << (bin & (kLeafBins - 1))));
    if (used_leaf_.at(top) == 0) used_top_ &= ~(1U << top);
}

// Ngăn không rỗng nhỏ nhất từ minimum trở lên: trước hết trong cùng hàng, rồi sang hàng cao hơn.
std::uint32_t RangeAllocator::find_bin(std::uint32_t minimum) const noexcept {
    const std::uint32_t top = minimum >> kLeafShift;
    const std::uint32_t in_row = lowest_from(used_leaf_.at(top), minimum & (kLeafBins - 1));
    if (in_row != kUnused) return (top << kLeafShift) | in_row;
    const std::uint32_t next_top = lowest_from(used_top_, top + 1);
    if (next_top == kUnused) return kUnused;
    const auto leaf = static_cast<std::uint32_t>(std::countr_zero(std::uint32_t{used_leaf_.at(next_top)}));
    return (next_top << kLeafShift) | leaf;
}

// Đoạn rỗi mới vào đầu danh sách của ngăn cỡ mình. Người gọi bảo đảm còn nút rỗi.
std::uint32_t RangeAllocator::insert(std::uint32_t size, std::uint32_t offset) noexcept {
    const std::uint32_t bin = bin_of(size, false);
    const std::uint32_t index = spare_.back();
    spare_.pop_back();
    const std::uint32_t head = heads_.at(bin);
    nodes_.at(index) = Node{.offset = offset, .size = size, .bin_next = head};
    if (head == kUnused) fill_bin(bin);
    if (head != kUnused) nodes_.at(head).bin_prev = index;
    heads_.at(bin) = index;
    free_size_ += size;
    ++free_regions_;
    return index;
}

void RangeAllocator::take_head(std::uint32_t bin, std::uint32_t next) noexcept {
    heads_.at(bin) = next;
    if (next == kUnused) {
        empty_bin(bin);
        return;
    }
    nodes_.at(next).bin_prev = kUnused;
}

// Gỡ nút khỏi danh sách ngăn của nó; đầu danh sách thì ngăn nhận nút kế làm đầu.
void RangeAllocator::unbin(const Node& node) noexcept {
    if (node.bin_prev == kUnused) {
        take_head(bin_of(node.size, false), node.bin_next);
        return;
    }
    nodes_.at(node.bin_prev).bin_next = node.bin_next;
    if (node.bin_next != kUnused) nodes_.at(node.bin_next).bin_prev = node.bin_prev;
}

// Đoạn rỗi biến mất (đã gộp vào đoạn khác): nút về kho nút rỗi.
// noexcept chủ ý, cùng lý do với reset: spare_ không bao giờ vượt sức chứa đã reserve (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
void RangeAllocator::remove(std::uint32_t index) noexcept {
    const Node node = nodes_.at(index);
    unbin(node);
    spare_.push_back(index);
    free_size_ -= node.size;
    --free_regions_;
}

// Phần thừa của đoạn vừa cắt thành một đoạn rỗi nằm ngay sau nó trong thứ tự địa chỉ.
void RangeAllocator::split_rest(std::uint32_t index, std::uint32_t rest) noexcept {
    const std::uint32_t after = nodes_.at(index).near_next;
    const std::uint32_t added = insert(rest, nodes_.at(index).offset + nodes_.at(index).size);
    nodes_.at(added).near_prev = index;
    nodes_.at(added).near_next = after;
    if (after != kUnused) nodes_.at(after).near_prev = added;
    nodes_.at(index).near_next = added;
}

// Tìm theo ngăn làm-tròn-lên chỉ thấy các ngăn mà MỌI đoạn đều đủ. Đoạn rỗi nằm ở ngăn
// làm-tròn-xuống của cỡ yêu cầu (ngăn chứa cỡ lớn hơn mốc dưới của nó) vẫn có thể đủ: đoạn 1000 nằm
// ở ngăn 960..1023, còn yêu cầu 1000 làm tròn lên tới ngăn 1024 nên không bao giờ thấy nó. Không có
// bước này bộ cấp phát có thể từ chối trong khi còn đoạn đủ chỗ, kể cả đoạn duy nhất của cả dải.
// Duyệt riêng ngăn đó là đủ: ngăn thấp hơn chỉ chứa đoạn nhỏ hơn mốc, ngăn cao hơn đã thuộc đường
// O(1).
std::uint32_t RangeAllocator::fit_below(std::uint32_t size) const noexcept {
    // Khác gốc: gốc là vòng for có câu if (cỡ đủ) return node trong thân; ở đây điều kiện dừng gộp
    // vào vòng while, hết danh sách thì node đã là kUnused.
    std::uint32_t node = heads_.at(bin_of(size, false));
    while (node != kUnused && nodes_.at(node).size < size) {
        node = nodes_.at(node).bin_next;
    }
    return node;
}

// Cắt size đơn vị đầu của đoạn rỗi index (đã chắc đủ chỗ); phần thừa thành đoạn rỗi mới.
Range RangeAllocator::carve(std::uint32_t index, std::uint32_t size) noexcept {
    Node& node = nodes_.at(index);
    const std::uint32_t whole = node.size;
    unbin(node);
    free_size_ -= whole;
    --free_regions_;
    node.size = size;
    node.used = true;
    if (whole > size) split_rest(index, whole - size);
    return Range{.offset = node.offset, .size = size, .node = index};
}

std::optional<Range> RangeAllocator::allocate(std::uint32_t size) noexcept {
    if (size == 0 || spare_.empty()) return std::nullopt;
    const std::uint32_t wanted = bin_of(size, true);
    const std::uint32_t bin = wanted < kBins ? find_bin(wanted) : kUnused;
    const std::uint32_t index = bin != kUnused ? heads_.at(bin) : fit_below(size);
    if (index == kUnused) return std::nullopt;
    return carve(index, size);
}

// Gộp đoạn rỗi liền trước vào span: span nuốt offset, cỡ và hàng xóm trước của nó.
void RangeAllocator::absorb_before(Node& span) noexcept {
    const std::uint32_t before = span.near_prev;
    if (before == kUnused || nodes_.at(before).used) return;
    const Node gone = nodes_.at(before);
    remove(before);
    span.offset = gone.offset;
    span.size += gone.size;
    span.near_prev = gone.near_prev;
}

void RangeAllocator::absorb_after(Node& span) noexcept {
    const std::uint32_t after = span.near_next;
    if (after == kUnused || nodes_.at(after).used) return;
    const Node gone = nodes_.at(after);
    remove(after);
    span.size += gone.size;
    span.near_next = gone.near_next;
}

// noexcept chủ ý, cùng lý do với reset: nút vừa trả về kho luôn còn chỗ đã reserve (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
void RangeAllocator::free(const Range& range) noexcept {
    const bool is_live =
        range.node < nodes_.size() && nodes_.at(range.node).used && nodes_.at(range.node).offset == range.offset;
    // Khác gốc: check của THIENLONG không định dạng, nên thông điệp không kèm offset của đoạn.
    check(is_live, "RangeAllocator: đoạn không hợp lệ hay đã trả");
    Node span = nodes_.at(range.node);
    nodes_.at(range.node).used = false;
    spare_.push_back(range.node);
    absorb_before(span);
    absorb_after(span);
    const std::uint32_t merged = insert(span.size, span.offset);
    nodes_.at(merged).near_prev = span.near_prev;
    nodes_.at(merged).near_next = span.near_next;
    if (span.near_next != kUnused) nodes_.at(span.near_next).near_prev = merged;
    if (span.near_prev != kUnused) nodes_.at(span.near_prev).near_next = merged;
}

RangeReport RangeAllocator::report() const noexcept {
    RangeReport result{.free_total = free_size_, .largest_free = 0, .free_regions = free_regions_};
    if (used_top_ == 0) return result;
    const auto top = static_cast<std::uint32_t>(std::bit_width(used_top_)) - 1;
    const auto leaf = static_cast<std::uint32_t>(std::bit_width(std::uint32_t{used_leaf_.at(top)})) - 1;
    for (std::uint32_t node = heads_.at((top << kLeafShift) | leaf); node != kUnused; node = nodes_.at(node).bin_next) {
        result.largest_free = std::max(result.largest_free, nodes_.at(node).size);
    }
    return result;
}

// PageAllocator

struct PageAllocator::Allocation::Lease {
    std::shared_ptr<State> state;
    Range range;
    std::uint32_t page_size = 0;

    Lease(std::shared_ptr<State> owner, Range pages) noexcept
        : state(std::move(owner)), range(pages), page_size(state->page_size) {}
    ~Lease() { state->release(range); }
    Lease(const Lease&) = delete;
    Lease& operator=(const Lease&) = delete;
    Lease(Lease&&) = delete;
    Lease& operator=(Lease&&) = delete;
};

std::uint64_t PageAllocator::Allocation::offset() const noexcept {
    if (lease_ == nullptr) return 0;
    return std::uint64_t{lease_->range.offset} * lease_->page_size;
}

std::uint64_t PageAllocator::Allocation::size() const noexcept {
    if (lease_ == nullptr) return 0;
    return std::uint64_t{lease_->range.size} * lease_->page_size;
}

// Chạy trong destructor của Lease nên không được ném. Hết bộ nhớ khi xếp hàng chờ trả hoãn thì giải
// phóng ngay: đoạn có thể còn được GPU đọc, nhưng tiến trình đã cạn bộ nhớ và dừng chắc chắn tệ
// hơn.
void PageAllocator::State::release(const Range& range) noexcept {
    const std::scoped_lock hold(lock);
    if (!deferred) {
        ranges.free(range);
        return;
    }
    try {
        pending.emplace_back(range, frame);
    } catch (const std::bad_alloc&) {
        ranges.free(range);
    }
}

PageAllocator::PageAllocator(std::uint64_t total_bytes, std::uint32_t page_size, bool deferred) {
    check(page_size > 0, "PageAllocator: page_size bằng 0");
    // total_bytes + (page_size - 1) tràn uint64 khi tổng gần max: chặn trước khi cộng.
    check(total_bytes <= (std::numeric_limits<std::uint64_t>::max)() - (page_size - 1U),
        "PageAllocator: tổng byte tràn");
    const std::uint64_t pages = (total_bytes + page_size - 1) / page_size;
    // Khác gốc: check của THIENLONG không định dạng, nên thông điệp không kèm số trang.
    const bool is_in_range = pages > 0 && pages <= std::numeric_limits<std::uint32_t>::max();
    check(is_in_range, "PageAllocator: số trang ngoài khoảng 1..2^32-1");
    state_ = std::make_shared<State>(static_cast<std::uint32_t>(pages), page_size, deferred);
}

PageAllocator::Allocation PageAllocator::allocate(std::uint64_t bytes) {
    if (bytes == 0) return {};
    // bytes + (page_size - 1) tràn uint64 khi bytes gần max: phép cộng quấn làm số trang tính ra
    // 0. Chặn tường minh trước khi cộng thay vì trông chờ allocate(0) trả rỗng.
    if (bytes > (std::numeric_limits<std::uint64_t>::max)() - (state_->page_size - 1U)) return {};
    const std::uint64_t pages = (bytes + state_->page_size - 1) / state_->page_size;
    if (pages > state_->total_pages) return {};
    const std::scoped_lock hold(state_->lock);
    const std::optional<Range> range = state_->ranges.allocate(static_cast<std::uint32_t>(pages));
    if (!range) return {};
    try {
        return Allocation(std::make_shared<Allocation::Lease>(state_, *range));
    } catch (...) {
        state_->ranges.free(*range);
        throw;
    }
}

void PageAllocator::collect(std::uint64_t frame, std::uint32_t latency) {
    const std::scoped_lock hold(state_->lock);
    state_->frame = frame;
    while (!state_->pending.empty() && state_->pending.front().second + latency < frame) {
        state_->ranges.free(state_->pending.front().first);
        state_->pending.pop_front();
    }
}

bool PageAllocator::empty() const {
    const std::scoped_lock hold(state_->lock);
    return state_->ranges.free_size() == state_->ranges.total();
}

} // namespace game::core
