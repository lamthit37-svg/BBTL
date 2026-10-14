#pragma once
// Hằng số và kiểu nền của lõi rơi đồ: trần của một lần quái chết, cách chia đồ giữa những người có quyền.
//
// Nguồn: ItemTypes.h và GameDefine.h của GameServer 2008 (MAX_MONSTER_DROPBOX = 20 gói mỗi quái, MAX_BOXITEM_NUMBER = 10 vật
// phẩm mỗi hộp, MAX_MONSTER_KILLER_NUM = 18 người chia, MAX_MONSTER_DROP_TASK_ITEM = 5 đồ nhiệm vụ mỗi người), BOX_DISTRIBUTE_RULER của
// GameDefine_Item.h (BDR_COMMON = 0, BDR_BOSS = 1). Số gói và số cặp (vật phẩm, cấp) mỗi gói của bảng XJL7457 lớn hơn 2008
// (256 cặp thay vì 100); các trần ở đây là trần của hộp và của người chia, không phải trần của bảng.

#include "ids/ids.hpp"

#include <cstddef>
#include <cstdint>

namespace game::loot {

inline constexpr std::size_t kBoxCapacity = 10;         // vật phẩm tối đa trong một hộp rơi
inline constexpr std::size_t kMaxPacksPerMonster = 20;  // số gói tối đa ở một dòng MonsterDropBoxs
inline constexpr std::size_t kMaxClaimants = 18;        // người có quyền chia tối đa cho một con quái
inline constexpr std::size_t kMaxQuestDrops = 5;        // đồ nhiệm vụ tối đa cho mỗi người chia

inline constexpr std::uint32_t kPpm = 1'000'000;        // 1,0 theo phần triệu

// Cách chia hộp giữa những người có quyền (cột drop_type của monster_drops).
enum class Ruler : std::uint8_t {
    kCommon = 0,  // BDR_COMMON: một người được chọn ngẫu nhiên nhận đồ, mọi người khác chỉ nhận đồ nhiệm vụ
    kBoss = 1,    // BDR_BOSS: mỗi người có quyền tự cuộn một hộp riêng
};

using PackId = ids::StrongId<struct PackTag, std::uint32_t>;

} // namespace game::loot
