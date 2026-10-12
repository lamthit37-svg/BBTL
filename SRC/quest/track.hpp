// Trạng thái theo dõi nhiệm vụ của người chơi. Client 2026 giữ nó trong CVariableSystem và ghi ra
// tệp ..\Accounts\#<tài khoản>\#<nhân vật>.trk, mục [Variable], khoá State_1 (khung theo dõi nhiệm
// vụ), State_2 (khung theo dõi hoạt động) và MissionVar_<idScript> (từng nhiệm vụ); đọc từ mã máy
// Game.exe, docs/NHIEM-VU-VO-CONG-2026.md. Khoá chưa có thì mỗi câu hỏi có một mặc định riêng.
// Khác gốc: chưa ghi ra tệp, trạng thái chỉ sống trong phiên chạy (docs/NGHI-NGO.md).
#pragma once

#include <cstdint>
#include <optional>

namespace game::quest {

// Hai khung theo dõi mà DataPool:IsTrackFuncShow và SetTrackFuncShow nhận (số 1 và 2 của script).
enum class TrackFrame : std::uint8_t { kMissions = 1, kCampaigns = 2 };

struct Tracking {
    // Khoá State_1 và State_2; nullopt là tệp chưa có khoá.
    std::optional<bool> shows_missions;
    std::optional<bool> shows_campaigns;
};

// DataPool:IsTrackFuncShow (0x1400f4e60, 0x1400f4fe0): chưa có khoá thì khung nhiệm vụ bật, khung
// hoạt động tắt.
[[nodiscard]] constexpr bool is_frame_shown(const Tracking& tracking, TrackFrame frame) noexcept {
    if (frame == TrackFrame::kMissions) return tracking.shows_missions.value_or(true);
    return tracking.shows_campaigns.value_or(false);
}

// DataPool:SetTrackFuncShow(n, v): ghi v > 0.
constexpr void show_frame(Tracking& tracking, TrackFrame frame, bool is_shown) noexcept {
    if (frame == TrackFrame::kMissions) tracking.shows_missions = is_shown;
    if (frame == TrackFrame::kCampaigns) tracking.shows_campaigns = is_shown;
}

} // namespace game::quest
