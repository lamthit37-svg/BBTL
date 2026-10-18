/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/script/mission_data.hpp
 *  PHÂN HỆ   : Client / Giao diện / Script
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Dữ liệu nhiệm vụ cho hàm native của script: kho định nghĩa nhiệm vụ
 *    (quest::DefBook) và chữ theo dõi (MissionTrack.txt).
 *  - Script.dat và tệp event nằm dưới Script/Config/ (stage_scripts.py), chữ
 *    theo dõi ở Table/mission_track.tsv (export_config.py).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "quest/defs.hpp"

#include <cstdint>
#include <expected>
#include <filesystem>
#include <map>
#include <string>
#include <string_view>

namespace game::ui::script {

// Chữ theo dõi theo id script: cột id và text của Table/mission_track.tsv.
using TrackTexts = std::map<std::int32_t, std::string>;

[[nodiscard]] std::expected<TrackTexts, std::string> parse_track_texts(std::string_view text);

struct MissionData {
    quest::DefBook defs;
    TrackTexts track_texts;
};

using OpenedMission = std::expected<MissionData, std::string>;

// Đọc <data_root>/Script/Config/Script.dat và Table/mission_track.tsv. Tệp event của một nhiệm vụ
// chỉ được đọc khi script gọi GetPlayerMission_Description cho nó. Lỗi (thiếu hay hỏng một trong
// hai tệp) là một câu cho log; host vẫn chạy được, getter nhiệm vụ khi đó thấy bản ghi mặc định.
[[nodiscard]] OpenedMission open_mission_data(const std::filesystem::path& data_root);

} // namespace game::ui::script
