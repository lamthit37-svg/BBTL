/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/pacer.hpp
 *  PHÂN HỆ   : Gpu / Pacer
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hẹn lúc trình cho bề mặt báo được mốc trình thật (Vulkan:
 *    VK_GOOGLE_display_timing, có trên Android và MoltenVK): mỗi ảnh lên màn
 *    không sớm hơn interval nhịp quét sau ảnh trước, neo vào lần trình thật
 *    mới nhất nên không trôi theo đồng hồ CPU.
 *  - Logic thuần, không gọi API đồ hoạ: swapchain cấp mốc và lấy lịch hẹn.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include <algorithm>
#include <cstdint>

namespace game::gpu {

// Một lần trình đã lên màn: presentID và lúc lên màn, ns theo đồng hồ của bề mặt.
struct ShownPresent {
    std::uint32_t id = 0;
    std::uint64_t shown_ns = 0;
};

// Đơn vị nano giây theo đồng hồ của bề mặt; chỉ số là presentID 32 bit, so theo hiệu không dấu
// nên đếm vòng qua 2^32 vẫn đúng. Vì sao không giữ nhịp bằng đồng hồ CPU: đo 2026-10-17 trên
// TB-X306F, giữ 30 khung theo CPU cho 7,6% khung một nhịp và 3% khung ba nhịp quét.
class PresentPacer {
public:
    // Chu kỳ quét của màn, ns; 0 là chưa biết, khi ấy không hẹn. Chu kỳ quá một giây là số hỏng
    // của driver: coi như chưa biết, để phép nhân trong desired không tràn.
    void set_refresh(std::uint64_t refresh_ns) noexcept {
        refresh_ns_ = refresh_ns <= kMostRefreshNs ? refresh_ns : 0;
    }

    // Số nhịp quét mỗi ảnh, kẹp vào [1, kMostInterval]. Đổi số nhịp thì bỏ mốc neo: các lần trình
    // giữa mốc neo và hiện tại đi theo số nhịp cũ, tính tiếp từ đó là hẹn sai.
    void set_interval(std::uint32_t refreshes) noexcept {
        const std::uint32_t kept = std::clamp<std::uint32_t>(refreshes, 1, kMostInterval);
        if (kept == interval_) return;
        interval_ = kept;
        has_anchor_ = false;
    }

    [[nodiscard]] std::uint32_t interval() const noexcept { return interval_; }
    [[nodiscard]] std::uint64_t refresh_ns() const noexcept { return refresh_ns_; }

    // Swapchain dựng lại: presentID đếm lại từ đầu, mốc neo và chu kỳ cũ vô nghĩa.
    void reset() noexcept {
        refresh_ns_ = 0;
        has_anchor_ = false;
    }

    // Bề mặt báo một lần trình đã lên màn. Mốc không mới hơn mốc neo thì bỏ.
    void note_shown(ShownPresent shown) noexcept {
        if (shown.shown_ns == 0) return;
        const std::uint32_t ahead = shown.id - anchor_id_;
        const bool is_older = has_anchor_ && (ahead == 0 || ahead > kNewest);
        if (is_older) return;
        anchor_id_ = shown.id;
        anchor_ns_ = shown.shown_ns;
        has_anchor_ = true;
    }

    // Hẹn được lần trình id: nhiều nhịp mỗi ảnh, biết chu kỳ, và có mốc neo trong kMostAhead lần
    // trình. Sai thì bề mặt không báo mốc (có tiện ích mà driver không trả, đo 2026-10-17 trên
    // TB-X306F) hay đã ngừng báo: chỗ gọi phải giữ nhịp bằng đồng hồ CPU.
    [[nodiscard]] bool is_locked(std::uint32_t id) const noexcept {
        const bool is_free = interval_ <= 1 || refresh_ns_ == 0 || !has_anchor_;
        if (is_free) return false;
        const std::uint32_t ahead = id - anchor_id_;
        return ahead != 0 && ahead <= kMostAhead;
    }

    // Lúc sớm nhất cho lần trình id; 0 là không ràng buộc (khi !is_locked).
    [[nodiscard]] std::uint64_t desired(std::uint32_t id) const noexcept {
        if (!is_locked(id)) return 0;
        const std::uint32_t ahead = id - anchor_id_;
        // Không tràn: chu kỳ tối đa 1 giây, nhân tối đa 8 nhịp và 16 lần trình.
        const std::uint64_t step = refresh_ns_ * interval_;
        const std::uint64_t span = step * ahead;
        // Hẹn sớm nửa nhịp quét: ảnh rơi đúng nhịp quét đầu tiên sau mốc hẹn, sai số giữa mốc báo
        // và nhịp quét thật (dưới nửa nhịp) không đẩy nó sang nhịp sau. span không nhỏ hơn một chu
        // kỳ nên phép trừ không âm.
        const std::uint64_t slack = refresh_ns_ / 2;
        return anchor_ns_ + (span - slack);
    }

private:
    static constexpr std::uint64_t kMostRefreshNs = 1'000'000'000;
    static constexpr std::uint32_t kMostInterval = 8;
    static constexpr std::uint32_t kMostAhead = 16;
    // Hiệu id lớn hơn nửa vòng 32 bit là id đứng trước mốc neo.
    static constexpr std::uint32_t kNewest = 0x7FFF'FFFFU;

    std::uint64_t refresh_ns_ = 0;
    std::uint64_t anchor_ns_ = 0;
    std::uint32_t anchor_id_ = 0;
    std::uint32_t interval_ = 1;
    bool has_anchor_ = false;
};

} // namespace game::gpu
