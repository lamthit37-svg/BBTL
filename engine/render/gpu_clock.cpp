/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/render/gpu_clock.cpp
 *  PHÂN HỆ   : Render / GpuClock
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt GpuClock (render/gpu_clock.hpp): vòng ô truy vấn dấu thời gian,
 *    đọc không chờ, đổi khoảng nano giây giữa hai mốc liền nhau ra ms của
 *    chặng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "render/gpu_clock.hpp"

#include "core/error.hpp"
#include "gpu/barrier.hpp"
#include "gpu/types.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <utility>

namespace game::render {
namespace {

// Ô chờ quá chừng ấy khung thì coi như lần nộp chứa nó đã hỏng: bỏ để vòng không kẹt mãi.
constexpr std::uint32_t kGiveUpFrames = GpuClock::kRing * 4;
// Mốc trước và sau lượt vẽ: mọi việc trước đó đã xong. Một giai đoạn duy nhất như Vulkan đòi.
constexpr gpu::SyncStage kStampStage = gpu::SyncStage::kAll;
constexpr gpu::QueryPoolHandle kNoPool{};

[[nodiscard]] double span_ms(std::uint64_t from_ns, std::uint64_t until_ns) noexcept {
    if (until_ns <= from_ns) return 0.0;
    return static_cast<double>(until_ns - from_ns) / 1.0e6;
}

} // namespace

core::Result<GpuClock> GpuClock::create(gpu::Device& device, std::uint32_t stages) {
    const auto graphics = static_cast<std::size_t>(gpu::QueueType::kGraphics);
    const bool has_stamps = device.caps().has_timestamps.at(graphics);
    const core::ErrorCode unsupported = core::ErrorCode::kUnsupported;
    if (!has_stamps) return core::fail(unsupported, "GPU không ghi dấu thời gian");
    if (stages == 0) return core::fail(core::ErrorCode::kInvalidArgument, "GpuClock cần một chặng");
    gpu::QueryPoolDesc desc;
    desc.name = "render.gpu_clock";
    desc.kind = gpu::QueryKind::kTimestamp;
    desc.count = kRing * (stages + 1);
    const core::Result<gpu::QueryPoolHandle> pool = device.create_query_pool(desc);
    if (!pool) return std::unexpected(pool.error());
    return GpuClock(device, *pool, stages);
}

GpuClock::GpuClock(gpu::Device& device, gpu::QueryPoolHandle pool, std::uint32_t stages)
    : device_(&device),
      pool_(pool),
      stages_(stages),
      stamps_(stages + 1, 0),
      laps_(stages, 0.0),
      stats_(stages) {}

GpuClock::GpuClock(GpuClock&& other) noexcept
    : device_(std::exchange(other.device_, nullptr)),
      pool_(std::exchange(other.pool_, kNoPool)),
      stages_(other.stages_),
      cells_(other.cells_),
      cursor_(other.cursor_),
      is_recording_(other.is_recording_),
      stamps_(std::move(other.stamps_)),
      laps_(std::move(other.laps_)),
      stats_(std::move(other.stats_)) {}

GpuClock& GpuClock::operator=(GpuClock&& other) noexcept {
    if (this == &other) return *this;
    if (device_ != nullptr) device_->destroy(pool_);
    device_ = std::exchange(other.device_, nullptr);
    pool_ = std::exchange(other.pool_, kNoPool);
    stages_ = other.stages_;
    cells_ = other.cells_;
    cursor_ = other.cursor_;
    is_recording_ = other.is_recording_;
    stamps_ = std::move(other.stamps_);
    laps_ = std::move(other.laps_);
    stats_ = std::move(other.stats_);
    return *this;
}

GpuClock::~GpuClock() {
    if (device_ != nullptr) device_->destroy(pool_);
}

std::uint32_t GpuClock::first_query(std::uint32_t index) const noexcept {
    return index * (stages_ + 1);
}

// Đọc kết quả của ô nếu GPU đã xong; mốc đọc ra là nano giây, chặng là hiệu hai mốc liền nhau.
// Mốc lùi (GPU chia ô ghi mốc giữa lượt theo cách riêng) tính là 0 thay vì bỏ cả khung.
bool GpuClock::collect(Cell& cell, std::uint32_t index) {
    if (!cell.is_pending) return true;
    const core::Status read = device_->read_queries(pool_, first_query(index), stamps_);
    const bool is_busy = !read && read.error().code() == core::ErrorCode::kWouldBlock;
    if (is_busy && ++cell.busy_frames < kGiveUpFrames) return false;
    cell.is_pending = false;
    cell.busy_frames = 0;
    if (!read) return true;
    for (std::uint32_t stage = 0; stage < stages_; ++stage) {
        laps_[stage] = span_ms(stamps_[stage], stamps_[stage + 1]);
    }
    stats_.add(laps_);
    return true;
}

void GpuClock::start(gpu::CommandList& list) {
    Cell& cell = cells_.at(cursor_);
    is_recording_ = collect(cell, cursor_);
    if (!is_recording_) return;
    const std::uint32_t first = first_query(cursor_);
    list.reset_queries(pool_, first, stages_ + 1);
    list.write_timestamp(pool_, first, kStampStage);
    cell.marks = 1;
}

void GpuClock::mark(gpu::CommandList& list) {
    if (!is_recording_) return;
    Cell& cell = cells_.at(cursor_);
    // Mốc thừa không được ghi: ô chỉ có stages + 1 chỗ, ghi lại chỗ đã ghi mà chưa đặt lại là sai.
    const std::uint32_t query = first_query(cursor_) + cell.marks;
    if (cell.marks < stages_) list.write_timestamp(pool_, query, kStampStage);
    ++cell.marks;
}

void GpuClock::finish(gpu::CommandList& list) {
    if (!is_recording_) return;
    is_recording_ = false;
    Cell& cell = cells_.at(cursor_);
    if (cell.marks != stages_) return;
    const std::uint32_t first = first_query(cursor_);
    list.write_timestamp(pool_, first + stages_, kStampStage);
    list.resolve_queries(pool_, first, stages_ + 1);
    cell.is_pending = true;
    cell.busy_frames = 0;
    cursor_ = (cursor_ + 1) % kRing;
}

// Ô cũ nhất trước: ô ngay sau cursor_ là ô được ghi sớm nhất trong vòng.
void GpuClock::drain() {
    for (std::uint32_t step = 1; step <= kRing; ++step) {
        const std::uint32_t index = (cursor_ + step) % kRing;
        Cell& cell = cells_.at(index);
        static_cast<void>(collect(cell, index));
    }
}

} // namespace game::render
