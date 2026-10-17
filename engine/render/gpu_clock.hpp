/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/render/gpu_clock.hpp
 *  PHÂN HỆ   : Render / GpuClock
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Thời gian GPU theo chặng của khung, đọc bằng dấu thời gian: mỗi khung ghi
 *    stages + 1 mốc vào một ô của vòng; ô chỉ được ghi lại khi kết quả cũ đã
 *    đọc, và đọc không bao giờ chờ GPU (chưa xong thì khung ấy không đo).
 *  - GPU chia ô (PowerVR, Mali, Adreno) chạy mọi lệnh của một lượt vẽ theo từng
 *    ô màn hình ở cuối lượt: trên đó chỉ tổng khung (mốc đầu trước lượt vẽ, mốc
 *    cuối sau lượt vẽ) là đúng, mốc giữa lượt chỉ có nghĩa trên GPU máy bàn.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "core/error.hpp"
#include "core/stages.hpp"
#include "gpu/command.hpp"
#include "gpu/device.hpp"
#include "gpu/handle.hpp"

#include <array>
#include <cstdint>
#include <vector>

namespace game::render {

class GpuClock {
public:
    // Số khung có thể đang chờ kết quả cùng lúc; lớn hơn số ảnh swapchain đang bay.
    static constexpr std::uint32_t kRing = 8;

    // stages >= 1. Unsupported khi hàng Graphics không ghi được dấu thời gian (GLES, vài thiết bị).
    // Mượn device: GpuClock phải bị huỷ trước device.
    [[nodiscard]] static core::Result<GpuClock> create(gpu::Device& device, std::uint32_t stages);

    GpuClock(GpuClock&& other) noexcept;
    GpuClock& operator=(GpuClock&& other) noexcept;
    GpuClock(const GpuClock&) = delete;
    GpuClock& operator=(const GpuClock&) = delete;
    ~GpuClock();

    // Ngoài begin_rendering: thu kết quả cũ của ô kế, đặt lại ô và ghi mốc đầu. Ô chưa đọc được
    // thì khung này không đo (mark và finish thành không làm gì).
    void start(gpu::CommandList& list);
    // Mốc cuối của chặng đang chạy, cũng là mốc đầu của chặng kế.
    void mark(gpu::CommandList& list);
    // Ngoài begin_rendering: mốc cuối và chốt kết quả. Khung có số lần mark khác stages - 1 bị bỏ.
    void finish(gpu::CommandList& list);
    // Sau Device::wait_idle: đọc mọi ô còn chờ.
    void drain();

    [[nodiscard]] const core::StageStats& stats() const noexcept { return stats_; }

private:
    struct Cell {
        // Số mốc đã ghi của khung đang ghi vào ô.
        std::uint32_t marks = 0;
        // Số khung liền nhau ô này còn chờ GPU; quá trần là khung ấy không bao giờ chạy (nộp hỏng).
        std::uint32_t busy_frames = 0;
        bool is_pending = false;
    };

    GpuClock(gpu::Device& device, gpu::QueryPoolHandle pool, std::uint32_t stages);

    // True khi ô rảnh để ghi: không chờ, hoặc đã đọc xong kết quả cũ.
    [[nodiscard]] bool collect(Cell& cell, std::uint32_t index);
    [[nodiscard]] std::uint32_t first_query(std::uint32_t index) const noexcept;

    gpu::Device* device_ = nullptr;
    gpu::QueryPoolHandle pool_{};
    std::uint32_t stages_ = 0;
    std::array<Cell, kRing> cells_{};
    std::uint32_t cursor_ = 0;
    bool is_recording_ = false;
    // Chỗ đọc mốc (stages + 1, nano giây) và chặng (stages, ms) dùng lại mỗi khung, không cấp phát.
    std::vector<std::uint64_t> stamps_;
    std::vector<double> laps_;
    core::StageStats stats_;
};

} // namespace game::render
