/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/host/play_sound.hpp
 *  PHÂN HỆ   : Client / Host / Sound
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Phát khối Sound của kịch bản đòn: bản 2008 tạo nguồn 3D tại chỗ đánh
 *    (PlaySoundFunc, b3DMode). Khác gốc: FMOD đặt rolloff factor 0 nên chỉ
 *    lệch trái phải; ở đây tiếng nhỏ dần từ 2 mét tới 40 mét.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "audio/engine.hpp"
#include "client/display/display.hpp"

#include <string>
#include <utility>

namespace game::client {

[[nodiscard]] inline audio::Ear ear_of(const Display::HeardEar& heard) {
    audio::Ear ear;
    ear.x = heard.x;
    ear.y = heard.y;
    ear.z = heard.z;
    ear.forward_x = heard.forward_x;
    ear.forward_y = heard.forward_y;
    ear.forward_z = heard.forward_z;
    ear.up_x = heard.up_x;
    ear.up_y = heard.up_y;
    ear.up_z = heard.up_z;
    return ear;
}

[[nodiscard]] inline audio::Cue spatial_cue(const Display::HeardSound& sound) {
    audio::Cue cue;
    cue.place.x = sound.x;
    cue.place.y = sound.y;
    cue.place.z = sound.z;
    cue.reach.near_distance = 200.0F;
    cue.reach.far_distance = 4000.0F;
    return cue;
}

template <typename Note>
void play_heard(audio::Engine& speaker, const Display::SoundBatch& batch, Note&& note) {
    if (batch.ear.has_value()) speaker.set_listener(ear_of(*batch.ear));
    for (const Display::HeardSound& sound : batch.due) {
        const std::string path = "sound/" + sound.name;
        const audio::SoundResult played = sound.is_spatial ? speaker.play_spatial(path, spatial_cue(sound))
                                                            : speaker.play_flat(path, 1.0F);
        if (!played) note(path, played.error());
    }
}

} // namespace game::client
