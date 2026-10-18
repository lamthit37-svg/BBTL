/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/guard/pace.cpp
 *  PHÂN HỆ   : Server / Guard / Pace
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt guard::Pace: quỹ quãng đường nạp theo tick máy chủ, đi dọc hàng
 *    đợi các chỗ client đã khai và ghi các điểm đi qua để báo zone.
 *  - Quyết định đã chốt (H1-B): không phạt, không đóng phiên vì tốc độ; lệch
 *    quá xa thì kResync.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "guard/pace.hpp"

#include <algorithm>
#include <cmath>

namespace game::guard {
namespace {

constexpr float kRefillCmPerTick = kRunCmPerSec * kSlack * kTickSeconds;
// Chặn số tick cộng một lần: máy chủ đứng rất lâu cũng chỉ đầy quỹ, và phép nhân float không tràn.
constexpr std::int32_t kMaxRefillTicks = 1 << 20;

// Hiệu có dấu theo modulo 2^32: tick quay vòng vẫn là tiến, tick lùi là âm.
[[nodiscard]] std::int32_t ticks_between(std::uint32_t from, std::uint32_t to) noexcept {
    return static_cast<std::int32_t>(to - from);
}

[[nodiscard]] float distance_cm(Anchor from, Anchor to) noexcept {
    const float dx = to.x_cm - from.x_cm;
    const float dz = to.z_cm - from.z_cm;
    return std::sqrt(dx * dx + dz * dz);
}

// Điểm báo cho zone; đầy chỗ thì đè điểm cuối (điểm cuối luôn là mốc mới nhất).
void note(Trail& trail, Anchor at) noexcept {
    if (trail.count == trail.points.size()) --trail.count;
    trail.points[trail.count] = at;
    ++trail.count;
}

// Cộng quãng vừa đi; đủ kTrailCm thì ghi điểm và đếm lại từ 0.
[[nodiscard]] float mark(Trail& trail, Anchor at, float walked_cm) noexcept {
    if (walked_cm < kTrailCm) return walked_cm;
    note(trail, at);
    return 0.0F;
}

} // namespace

void Pace::reset(Anchor at, std::uint32_t client_tick, std::uint32_t server_tick,
    float resync_cm) noexcept {
    has_anchor_ = true;
    x_cm_ = at.x_cm;
    z_cm_ = at.z_cm;
    client_tick_ = client_tick;
    server_tick_ = server_tick;
    bank_cm_ = 0;
    resync_cm_ = std::max(resync_cm, 2.0F * kBankCm);
    head_ = 0;
    count_ = 0;
    queued_cm_ = 0;
}

Anchor Pace::tail() const noexcept {
    if (count_ == 0) return anchor();
    return nodes_[(head_ + count_ - 1) % kNodes];
}

void Pace::push(Anchor at) noexcept {
    nodes_[(head_ + count_) % kNodes] = at;
    ++count_;
}

void Pace::pop() noexcept {
    head_ = (head_ + 1) % kNodes;
    --count_;
    if (count_ == 0) queued_cm_ = 0;
}

Verdict Pace::refuse(Verdict verdict) noexcept {
    head_ = 0;
    count_ = 0;
    queued_cm_ = 0;
    return verdict;
}

Verdict Pace::observe(Step step) noexcept {
    if (!has_anchor_) return Verdict::kNoAnchor;
    if (ticks_between(client_tick_, step.tick) < 0) return refuse(Verdict::kRejected);
    const Anchor at{.x_cm = step.x_cm, .z_cm = step.z_cm};
    const float gap_cm = distance_cm(tail(), at);
    if (!std::isfinite(gap_cm)) return refuse(Verdict::kRejected);
    const float queued_cm = queued_cm_ + gap_cm;
    const bool is_far = queued_cm > resync_cm_ || count_ == kNodes;
    if (is_far) return refuse(Verdict::kResync);
    push(at);
    queued_cm_ = queued_cm;
    client_tick_ = step.tick;
    return Verdict::kOk;
}

void Pace::refill(std::uint32_t server_tick) noexcept {
    const std::int32_t passed = ticks_between(server_tick_, server_tick);
    if (passed <= 0) return;
    server_tick_ = server_tick;
    const float ticks = static_cast<float>(std::min(passed, kMaxRefillTicks));
    bank_cm_ = std::min(kBankCm, bank_cm_ + ticks * kRefillCmPerTick);
}

// Tiến một đoạn về `next` với quỹ hiện có: tới nơi thì đặt mốc đúng chỗ, không thì đi một phần.
Pace::Leg Pace::go_to(Anchor next) noexcept {
    const float gap_cm = distance_cm(anchor(), next);
    if (gap_cm <= bank_cm_) {
        x_cm_ = next.x_cm;
        z_cm_ = next.z_cm;
        return Leg{.moved_cm = gap_cm, .reached = true};
    }
    const float share = bank_cm_ / gap_cm;
    x_cm_ += (next.x_cm - x_cm_) * share;
    z_cm_ += (next.z_cm - z_cm_) * share;
    return Leg{.moved_cm = bank_cm_, .reached = false};
}

void Pace::walk(Trail& trail) noexcept {
    float since_mark_cm = 0;
    while (bank_cm_ > 0 && count_ > 0) {
        const Leg leg = go_to(nodes_[head_]);
        bank_cm_ = leg.reached ? bank_cm_ - leg.moved_cm : 0.0F;
        queued_cm_ = std::max(0.0F, queued_cm_ - leg.moved_cm);
        if (leg.reached) pop();
        since_mark_cm = mark(trail, anchor(), since_mark_cm + leg.moved_cm);
    }
    if (since_mark_cm > 0) note(trail, anchor());
}

Trail Pace::advance(std::uint32_t server_tick) noexcept {
    Trail trail;
    if (!has_anchor_) return trail;
    refill(server_tick);
    walk(trail);
    return trail;
}

} // namespace game::guard
