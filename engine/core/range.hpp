/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/range.hpp
 *  PHÂN HỆ   : Core / Range
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Chia một dải đơn vị liên tục thành các đoạn: RangeAllocator (TLSF hai
 *    tầng, cấp và trả O(1), gộp đoạn rỗi kề nhau, không cấp phát khi chạy) và
 *    PageAllocator dựng trên nó (tính theo byte và trang, an toàn đa luồng,
 *    đoạn đếm tham chiếu, trả hoãn theo khung cho bộ nhớ GPU). Nguồn:
 *    PageAllocator của Wicked (bọc OffsetAllocator của Aaltonen); thuật toán
 *    TLSF dựng lại từ mô tả của nó, không chép mã. Dùng để chia nhỏ một khối bộ
 *    nhớ GPU lớn, một buffer staging hay một tệp ánh xạ thành vùng cho từng tài
 *    nguyên: khác Arena ở chỗ trả lẻ được, khác Pool ở chỗ cỡ tuỳ ý.
 *    RangeAllocator không an toàn đa luồng; PageAllocator có mutex riêng.
 *  - Nguồn: Forge2 src/core/range.hpp@d7fcd76. Khác gốc: constructor của
 *    PageAllocator thêm explicit.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <deque>
#include <memory>
#include <mutex>
#include <optional>
#include <utility>
#include <vector>

namespace game::core {

// Đoạn đã cấp: [offset, offset + size) tính theo đơn vị của bộ cấp phát; node là khoá để trả.
struct Range {
    std::uint32_t offset = 0;
    std::uint32_t size = 0;
    std::uint32_t node = 0;
};

struct RangeReport {
    std::uint32_t free_total = 0;
    std::uint32_t largest_free = 0;
    std::uint32_t free_regions = 0;
};

class RangeAllocator {
public:
    static constexpr std::uint32_t kDefaultNodes = 128 * 1024;

    // total đơn vị; max_nodes là số đoạn (đang cấp cộng đang rỗi) tối đa cùng lúc, mỗi nút tốn 32
    // byte nên hạ xuống khi biết số đoạn ít.
    explicit RangeAllocator(std::uint32_t total, std::uint32_t max_nodes = kDefaultNodes);

    // size bằng 0, hết chỗ hay hết nút: nullopt. Đoạn được cấp luôn đúng size đơn vị, phần thừa của
    // ngăn quay lại danh sách rỗi. Còn đoạn rỗi đủ lớn thì không bao giờ thất bại (O(1) khi ngăn
    // làm-tròn-lên có đoạn; không thì duyệt một ngăn).
    [[nodiscard]] std::optional<Range> allocate(std::uint32_t size) noexcept;

    // Trả đoạn do chính bộ cấp phát này cấp và chưa trả (kiểm ở mọi cấu hình: trả hai lần làm hỏng
    // danh sách rỗi). Đoạn rỗi kề hai bên được gộp lại.
    void free(const Range& range) noexcept;

    // Trả mọi đoạn về một khối rỗi duy nhất.
    void reset() noexcept;

    [[nodiscard]] std::uint32_t total() const noexcept { return total_; }
    [[nodiscard]] std::uint32_t free_size() const noexcept { return free_size_; }
    // Đếm đoạn rỗi và tìm đoạn lớn nhất (duyệt ngăn cao nhất còn đoạn): chẩn đoán, không dùng ở
    // đường nóng.
    [[nodiscard]] RangeReport report() const noexcept;

private:
    static constexpr std::uint32_t kUnused = 0xFFFF'FFFF;
    static constexpr std::uint32_t kLeafShift = 3;
    static constexpr std::uint32_t kLeafBins = 1U << kLeafShift;
    static constexpr std::uint32_t kTopBins = 32;
    static constexpr std::uint32_t kBins = kTopBins * kLeafBins;

    struct Node {
        std::uint32_t offset = 0;
        std::uint32_t size = 0;
        std::uint32_t bin_prev = kUnused;
        std::uint32_t bin_next = kUnused;
        std::uint32_t near_prev = kUnused;
        std::uint32_t near_next = kUnused;
        bool used = false;
    };

    [[nodiscard]] std::uint32_t find_bin(std::uint32_t minimum) const noexcept;
    [[nodiscard]] std::uint32_t fit_below(std::uint32_t size) const noexcept;
    [[nodiscard]] Range carve(std::uint32_t index, std::uint32_t size) noexcept;
    [[nodiscard]] std::uint32_t insert(std::uint32_t size, std::uint32_t offset) noexcept;
    void remove(std::uint32_t index) noexcept;
    void unbin(const Node& node) noexcept;
    void take_head(std::uint32_t bin, std::uint32_t next) noexcept;
    void fill_bin(std::uint32_t bin) noexcept;
    void empty_bin(std::uint32_t bin) noexcept;
    void split_rest(std::uint32_t index, std::uint32_t rest) noexcept;
    void absorb_before(Node& span) noexcept;
    void absorb_after(Node& span) noexcept;

    std::uint32_t total_ = 0;
    std::uint32_t free_size_ = 0;
    std::uint32_t free_regions_ = 0;
    std::uint32_t used_top_ = 0;
    std::array<std::uint8_t, kTopBins> used_leaf_{};
    std::array<std::uint32_t, kBins> heads_{};
    std::vector<Node> nodes_;
    std::vector<std::uint32_t> spare_;
};

// Bộ cấp phát theo trang cho bộ nhớ chia sẻ giữa nhiều luồng (GPU heap, vùng staging). Allocation
// là tay cầm đếm tham chiếu: bản sao dùng chung một đoạn, bản cuối huỷ thì đoạn trở về bộ cấp phát
// (ngay, hay sau latency khung nếu bật trả hoãn, để GPU còn đọc xong khung đang bay). Allocation
// giữ bộ cấp phát sống, nên huỷ PageAllocator trước các Allocation của nó là hợp lệ.
class PageAllocator {
public:
    class Allocation {
    public:
        Allocation() noexcept = default;

        [[nodiscard]] bool valid() const noexcept { return lease_ != nullptr; }
        // Byte từ đầu vùng quản lý; 0 khi không hợp lệ.
        [[nodiscard]] std::uint64_t offset() const noexcept;
        // Số byte đã cấp, là bội của page_size, không nhỏ hơn yêu cầu.
        [[nodiscard]] std::uint64_t size() const noexcept;

    private:
        friend class PageAllocator;
        struct Lease;
        explicit Allocation(std::shared_ptr<Lease> lease) noexcept : lease_(std::move(lease)) {}

        std::shared_ptr<Lease> lease_;
    };

    // total_bytes làm tròn lên bội của page_size. deferred bật thì đoạn trả về chỉ được tái dùng
    // sau collect.
    // Khác gốc: thêm explicit, vì hai tham số sau có mặc định nên gọi được với một đối số (API-04).
    explicit PageAllocator(std::uint64_t total_bytes, std::uint32_t page_size = 64 * 1024, bool deferred = false);

    // Không hợp lệ (valid() false) khi hết chỗ hay bytes bằng 0.
    [[nodiscard]] Allocation allocate(std::uint64_t bytes);

    // Gọi mỗi khung khi trả hoãn bật: đoạn trả ở khung f được giải phóng khi frame > f + latency.
    void collect(std::uint64_t frame, std::uint32_t latency);

    // Không còn đoạn nào đang giữ, kể cả đoạn chờ trả hoãn.
    [[nodiscard]] bool empty() const;
    [[nodiscard]] std::uint64_t total_bytes() const noexcept { return state_->total_pages * state_->page_size; }
    [[nodiscard]] std::uint32_t page_size() const noexcept { return state_->page_size; }

private:
    struct State {
        std::mutex lock;
        RangeAllocator ranges;
        std::uint32_t page_size;
        std::uint64_t total_pages;
        bool deferred;
        std::uint64_t frame = 0;
        std::deque<std::pair<Range, std::uint64_t>> pending;

        State(std::uint32_t pages, std::uint32_t page, bool defer)
            : ranges(pages), page_size(page), total_pages(pages), deferred(defer) {}
        void release(const Range& range) noexcept;
    };

    std::shared_ptr<State> state_;
};

} // namespace game::core
