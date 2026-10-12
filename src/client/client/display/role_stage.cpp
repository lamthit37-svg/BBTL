// Thủ tục chọn và tạo nhân vật phía camera (xem role_stage.hpp).
#include "client/display/role_stage.hpp"

#include "control/char_camera.hpp"
#include "ui/panel/role_pose.hpp"

#include <cstdint>
#include <optional>

namespace game::client {
namespace {

// Bộ đếm một nấc lăn cộng vào và tốc độ phóng nó đặt.
constexpr std::int32_t kWheelTicks = 5;
constexpr float kZoomIn = 1.0F;
constexpr float kZoomOut = -1.0F;

// Track và chiều chạy khi rời ô from sang ô khác (bảng nhánh của 0x14063bb70).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): from rồi to, hai ô của bảng chọn
[[nodiscard]] control::TrackPlay leg(std::uint8_t from, std::uint8_t to) noexcept {
    control::TrackPlay play;
    play.is_forward = false;
    play.track = control::CameraTrack::kRole0To1;
    if (from == 0) {
        play.is_forward = to == 1;
        play.track = to == 1 ? control::CameraTrack::kRole0To1 : control::CameraTrack::kRole2To0;
    }
    if (from == 1) {
        play.is_forward = to == 2;
        play.track = to == 2 ? control::CameraTrack::kRole1To2 : control::CameraTrack::kRole0To1;
    }
    if (from == 2) {
        play.is_forward = to == 0;
        play.track = to == 0 ? control::CameraTrack::kRole2To0 : control::CameraTrack::kRole1To2;
    }
    return play;
}

// Track kết thúc ở ô slot khi chạy xuôi: tư thế nghỉ của ô là khoá cuối của nó.
[[nodiscard]] control::CameraTrack track_into(std::uint8_t slot) noexcept {
    if (slot == 1) return control::CameraTrack::kRole0To1;
    if (slot == 2) return control::CameraTrack::kRole1To2;
    return control::CameraTrack::kRole2To0;
}

} // namespace

std::optional<control::TrackPose> RoleStage::camera() const noexcept {
    return camera_.pose();
}

void RoleStage::roll(Wheel& wheel, const StageFrame& frame) noexcept {
    if (frame.is_wheel_up) {
        camera_.set_zoom_speed(kZoomIn);
        wheel.ticks += kWheelTicks;
        wheel.is_rolling = true;
    }
    if (frame.is_wheel_down) {
        camera_.set_zoom_speed(kZoomOut);
        wheel.ticks -= kWheelTicks;
        wheel.is_rolling = true;
    }
    if (!wheel.is_rolling) return;
    if (wheel.ticks > 0) {
        --wheel.ticks;
        if (wheel.ticks > 0) return;
    } else {
        if (wheel.ticks == 0) return;
        ++wheel.ticks;
        if (wheel.ticks < 0) return;
    }
    wheel.is_rolling = false;
    wheel.ticks = 0;
    camera_.set_zoom_speed(0.0F);
}

void RoleStage::rest_at(std::uint8_t slot) noexcept {
    control::TrackPlay play;
    play.is_forward = true;
    play.is_held = true;
    play.track = track_into(slot);
    camera_.play(play);
    slot_ = slot;
    previous_ = slot;
    wanted_ = slot;
    pending_.reset();
}

void RoleStage::select_slot(std::uint8_t slot) noexcept {
    if (slot > 2) return;
    if (slot == slot_) {
        pending_.reset();
        return;
    }
    if (camera_.is_transitioning()) {
        pending_ = slot;
        if (slot != previous_) return;
        pending_.reset();
    }
    previous_ = slot_;
    camera_.play(leg(slot_, slot));
    slot_ = slot;
}

void RoleStage::step_create(const ui::panel::ShownModel& model, const StageFrame& frame) noexcept {
    if (scene_ != Scene::kCreate || model.entries != entries_) {
        camera_.set_mode(model.entry_sex == 0 ? control::CameraMode::kCreateFemale : control::CameraMode::kCreateMale);
        entries_ = model.entries;
        scene_ = Scene::kCreate;
    }
    if (model.outfit_calls != outfit_calls_) {
        control::TrackPlay play;
        play.is_forward = model.sex == 0;
        play.track = control::CameraTrack::kCreate;
        camera_.play(play);
        outfit_calls_ = model.outfit_calls;
    }
    if (model.zoom != zoom_) {
        camera_.set_zoom_speed(static_cast<float>(model.zoom));
        zoom_ = model.zoom;
    }
    camera_.update(frame.now_ms);
    roll(create_wheel_, frame);
}

void RoleStage::step_select(const ui::panel::ShownModel& model, const StageFrame& frame) noexcept {
    if (scene_ != Scene::kSelect) {
        camera_.set_mode(control::CameraMode::kSelect);
        rest_at(model.slot);
        scene_ = Scene::kSelect;
    }
    if (model.in_world && model.slot != wanted_) {
        wanted_ = model.slot;
        select_slot(model.slot);
    }
    camera_.update(frame.now_ms);
    const bool is_moving = camera_.is_transitioning();
    roll(select_wheel_, frame);
    if (is_moving || !pending_) return;
    const std::uint8_t waiting = *pending_;
    select_slot(waiting);
    pending_.reset();
}

void RoleStage::step(const ui::panel::ShownModel& model, const StageFrame& frame) noexcept {
    if (model.is_creating) {
        step_create(model, frame);
    } else {
        step_select(model, frame);
    }
    camera_.advance(frame.seconds);
}

} // namespace game::client
