// Chia các khối bộ nhớ GPU lớn thành vùng cho từng tài nguyên, dùng chung cho hai backend (khối là
// VkDeviceMemory hay ID3D12Heap, do backend dựng). Platium xin hệ điều hành một lần cấp phát cho
// MỖI buffer và texture: Vulkan chỉ bảo đảm 4096 lần cấp phát cùng lúc, và mỗi lần là một lời gọi
// xuống trình điều khiển. _Ref và Wicked dùng VMA và D3D12MA (hai thư viện ngoài, khoảng 20.000
// dòng). Ở đây vùng lấy từ core::RangeAllocator (TLSF, cấp và trả O(1)); tài nguyên lớn hơn nửa
// khối nhận một khối riêng; khối trống hẳn được trả lại, giữ một khối dự phòng. An toàn đa luồng.
// Nguồn: Forge2 src/gpu/memory.hpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; câu if trong vòng
// for của allocate chuyển thành điều kiện dừng của vòng.
#pragma once

#include "core/error.hpp"
#include "core/range.hpp"

#include <algorithm>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <optional>
#include <utility>
#include <vector>

namespace game::gpu {

struct MemoryConfig {
    // Cỡ một khối chung.
    std::uint64_t block_bytes = std::uint64_t{64} << 20U;
    // Đơn vị chia; mọi vùng là bội của nó. D3D12 cần 64 KiB; Vulkan dùng 256 byte.
    std::uint32_t unit_bytes = 256;
    // Số vùng (đang cấp cộng đang rỗi) tối đa trong một khối; mỗi nút tốn 32 byte.
    std::uint32_t max_nodes = 8192;
};

// Một vùng đã cấp. Trả bằng MemoryPool::free đúng một lần.
struct MemorySpan {
    static constexpr std::uint32_t kNoBlock = ~std::uint32_t{0};

    std::uint32_t block = kNoBlock;
    // Byte từ đầu khối, đã căn theo yêu cầu.
    std::uint64_t offset = 0;
    std::uint64_t size = 0;
    core::Range range{};

    [[nodiscard]] bool valid() const noexcept { return block != kNoBlock; }
};

template <class Block>
class MemoryPool {
public:
    // Dựng một khối bytes byte.
    using Factory = std::function<core::Result<Block>(std::uint64_t bytes)>;

    MemoryPool(const MemoryConfig& config, Factory factory) : config_(config), factory_(std::move(factory)) {}

    // alignment là luỹ thừa của 2. OutOfMemory khi không dựng được khối mới.
    [[nodiscard]] core::Result<MemorySpan> allocate(std::uint64_t size, std::uint64_t alignment) {
        const std::scoped_lock lock(mutex_);
        const bool is_large = size > config_.block_bytes / 2;
        if (is_large) return allocate_dedicated(size);
        // Vùng xin dư phần căn lề vì RangeAllocator không biết căn.
        const std::uint64_t unit = config_.unit_bytes;
        const std::uint64_t slack = alignment > unit ? alignment - unit : 0;
        const auto units = static_cast<std::uint32_t>((size + slack + unit - 1) / unit);
        // Khác gốc: gốc có câu if (span) return *span trong thân vòng for; ở đây vòng dừng ở khối
        // đầu tiên còn chỗ rồi mới trả.
        std::optional<MemorySpan> found;
        for (std::uint32_t index = 0; index < blocks_.size() && !found; ++index) {
            found = take(index, units, size, alignment);
        }
        if (found) return *found;
        const core::Status grown = add_block(config_.block_bytes, false);
        if (!grown) return std::unexpected(grown.error());
        const auto last = static_cast<std::uint32_t>(blocks_.size() - 1);
        const std::optional<MemorySpan> span = take(last, units, size, alignment);
        if (span) return *span;
        return core::fail(core::ErrorCode::kInternal, "khối bộ nhớ GPU mới không chứa nổi vùng");
    }

    void free(const MemorySpan& span) noexcept {
        if (!span.valid()) return;
        const std::scoped_lock lock(mutex_);
        Entry* const entry = blocks_.at(span.block).get();
        if (entry == nullptr) return;
        entry->ranges.free(span.range);
        --entry->live;
        if (entry->live != 0) return;
        // Khối chung trống hẳn: giữ lại một khối làm dự phòng, các khối khác trả cho hệ thống.
        const bool is_kept = !entry->is_dedicated && !std::exchange(has_spare_, true);
        if (is_kept) return;
        reserved_ -= entry->bytes;
        blocks_.at(span.block).reset();
    }

    // Khối chứa span; hợp lệ tới khi span được trả.
    [[nodiscard]] Block& block(const MemorySpan& span) noexcept {
        const std::scoped_lock lock(mutex_);
        return blocks_.at(span.block)->block;
    }

    // Tổng số byte của các khối đang giữ.
    [[nodiscard]] std::uint64_t reserved_bytes() const {
        const std::scoped_lock lock(mutex_);
        return reserved_;
    }

private:
    struct Entry {
        // Constructor nội bộ, chỉ add_block gọi; tham số theo thứ tự thành viên (lệch API-03).
        // NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
        Entry(Block held, std::uint32_t units, std::uint32_t nodes, std::uint64_t size, bool alone)
            : block(std::move(held)), ranges(units, nodes), bytes(size), is_dedicated(alone) {}
        ~Entry() = default;
        Entry(const Entry&) = delete;
        Entry& operator=(const Entry&) = delete;
        Entry(Entry&&) = delete;
        Entry& operator=(Entry&&) = delete;

        Block block;
        core::RangeAllocator ranges;
        std::uint64_t bytes;
        std::uint32_t live = 0;
        bool is_dedicated;
    };

    // Ô trống của blocks_ (khối đã trả) được dùng lại để chỉ số của các khối khác không đổi.
    [[nodiscard]] core::Status add_block(std::uint64_t bytes, bool is_dedicated) {
        const std::uint64_t unit = config_.unit_bytes;
        const std::uint64_t rounded = (bytes + unit - 1) / unit * unit;
        core::Result<Block> block = factory_(rounded);
        if (!block) return std::unexpected(std::move(block).error());
        const auto units = static_cast<std::uint32_t>(rounded / unit);
        const std::uint32_t nodes = is_dedicated ? 4 : config_.max_nodes;
        auto entry = std::make_unique<Entry>(std::move(*block), units, nodes, rounded, is_dedicated);
        reserved_ += rounded;
        // find_if thay find với nullptr_t: libc++ của NDK không nhận nullptr làm giá trị so
        // sánh của ranges::find với unique_ptr, MSVC STL thì nhận.
        const auto is_empty = [](const std::unique_ptr<Entry>& slot) noexcept { return slot == nullptr; };
        const auto empty = std::ranges::find_if(blocks_, is_empty);
        const auto index = static_cast<std::uint32_t>(empty - blocks_.begin());
        if (index == blocks_.size()) blocks_.emplace_back();
        blocks_.at(index) = std::move(entry);
        last_added_ = index;
        return core::ok();
    }

    [[nodiscard]] core::Result<MemorySpan> allocate_dedicated(std::uint64_t size) {
        const core::Status grown = add_block(size, true);
        if (!grown) return std::unexpected(grown.error());
        Entry& entry = *blocks_.at(last_added_);
        const std::optional<core::Range> range = entry.ranges.allocate(entry.ranges.total());
        if (!range) return core::fail(core::ErrorCode::kInternal, "khối riêng không cấp được vùng");
        ++entry.live;
        return MemorySpan{.block = last_added_, .offset = 0, .size = size, .range = *range};
    }

    // Vùng units đơn vị trong khối index, căn theo alignment; rỗng khi khối không còn chỗ.
    // NOLINTBEGIN(bugprone-easily-swappable-parameters): hàm nội bộ, chỉ allocate gọi (lệch API-03)
    [[nodiscard]] std::optional<MemorySpan> take(std::uint32_t index, std::uint32_t units, std::uint64_t size,
        std::uint64_t alignment) noexcept {
        Entry* const entry = blocks_.at(index).get();
        if (entry == nullptr || entry->is_dedicated) return std::nullopt;
        const std::optional<core::Range> range = entry->ranges.allocate(units);
        if (!range) return std::nullopt;
        const bool was_spare = entry->live == 0;
        if (was_spare) has_spare_ = false;
        ++entry->live;
        const std::uint64_t start = std::uint64_t{range->offset} * config_.unit_bytes;
        const std::uint64_t aligned = (start + alignment - 1) & ~(alignment - 1);
        return MemorySpan{.block = index, .offset = aligned, .size = size, .range = *range};
    }
    // NOLINTEND(bugprone-easily-swappable-parameters)

    MemoryConfig config_;
    Factory factory_;
    // Bảo vệ mọi thành viên bên dưới.
    mutable std::mutex mutex_;
    std::vector<std::unique_ptr<Entry>> blocks_;
    std::uint64_t reserved_ = 0;
    std::uint32_t last_added_ = 0;
    // Đang có một khối chung trống hẳn được giữ lại làm dự phòng.
    bool has_spare_ = false;
};

} // namespace game::gpu
