/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/account/starter.hpp
 *  PHÂN HỆ   : Server / Account / Starter
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hồ sơ nhân vật mới, chép từ dev/server/config/rules/new_character.toml
 *    schema 1. Giới tính, tên, mặt và tóc do client gửi. sex = 0 trong tệp toml
 *    không phải giới tính trên dây (protocol: nữ = 1, nam = 2). Môn 9 là Vô
 *    Phái của client 2026.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/
#pragma once

#include <array>
#include <cstdint>
#include <string_view>

namespace game::account::starter {

inline constexpr std::int32_t kScene = 2;
inline constexpr double kPositionX = 165.0;
// Khác gốc: DefaultChar.ini ghi 169.0, nhưng (165; 169) là tam giác vật cản của lưới đi 2026 nên
// nhân vật mới bị kéo về ngay bước đầu. 169.71 là điểm đi được gần nhất, liền với 赵天师 (160; 159)
// và cách mọi cạnh ràng buộc ít nhất 20 cm (kWalkSlackCm của zone). Đo trên walk.path của Đại Lý,
// xem docs/giao-viec/HOAN-THIEN/G1-M.md mục D4. Cảnh 71 và 72 chưa có lưới, giữ 169.
inline constexpr double kPositionZ = 169.71;
inline constexpr std::int32_t kHp = 999;
inline constexpr std::int32_t kMp = 999;
inline constexpr std::int32_t kLevel = 1;
inline constexpr std::int64_t kExp = 0;
inline constexpr std::int32_t kCamp = 0;
inline constexpr std::int32_t kSchool = 9;
inline constexpr std::int64_t kMoney = 0;
inline constexpr std::int32_t kActualAge = 18;
inline constexpr std::string_view kMotto = "这家伙很懒，什么都没留下！";
inline constexpr std::int32_t kVigor = 10;
inline constexpr std::int32_t kMaxVigor = 50;
inline constexpr std::int32_t kEnergy = 10;
inline constexpr std::int32_t kMaxEnergy = 50;
inline constexpr std::int32_t kStrength = 7;
inline constexpr std::int32_t kSpirit = 6;
inline constexpr std::int32_t kConstitution = 5;
inline constexpr std::int32_t kIntellect = 5;
inline constexpr std::int32_t kDexterity = 2;

inline constexpr std::array<std::int64_t, 6> kSkills{0, 1, 21, 22, 34, 35};

struct LifeSkill {
    std::int64_t id = 0;
    std::int32_t level = 1;
    std::int64_t exp = 0;
};

inline constexpr std::array<LifeSkill, 5> kLifeSkills{{
    {.id = 1},
    {.id = 26},
    {.id = 38},
    {.id = 50},
    {.id = 51},
}};

inline constexpr std::array<std::int64_t, 4> kRecipes{398, 558, 559, 560};

struct Setting {
    std::int32_t index = 0;
    std::int32_t kind = 0;
    std::int64_t data = 0;
};

inline constexpr std::array<Setting, 6> kSettings{{
    {.index = 2, .kind = 1, .data = 0},
    {.index = 8, .kind = 1, .data = 22},
    {.index = 9, .kind = 1, .data = 35},
    {.index = 10, .kind = 2, .data = 1},
    {.index = 11, .kind = 1, .data = 1},
    {.index = 1, .kind = 0, .data = 4},
}};

} // namespace game::account::starter
