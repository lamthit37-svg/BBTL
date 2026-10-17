#pragma once
// Năm bảng ngoại hình người chơi (Table/*.tsv do TOOLS/content/export_look.py sinh): player_bodies
// (mỗi giới một skeleton chính và bộ mặc định), faces, hairs, outfits (lưới bộ phận theo id hình),
// anim_sets (clip theo hành động và loại vũ khí, đã giải hết chuỗi action set lúc xuất). Id giữ số
// của Config client; giới là race của CharRace (0 nữ, 1 nam); tên tệp là tên gốc dưới Model/.
// Nguồn: TLBB Dev src/tables/appearance.hpp@e0d89a6. Khác gốc: giới thay bằng Race theo CharRace;
// khoá của faces, hairs là (id, race) vì id của hai giới có thể trùng; bảng vũ khí ở look/weapon.hpp,
// chưa có model_anims (làm cùng NPC); bộ đọc dựa trên table::Tsv của dự án.

#include "table/tsv.hpp"

#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::look {

// Giới của người chơi theo race của CharRace.
enum class Race : std::uint8_t { kFemale = 0, kMale = 1 };

// Hành động cơ sở (ENUM_BASE_ACTION của ref, chỉ những cái có clip). kIdleAlt và kIdleAlt2 là hai
// động tác nghỉ nhỏ N_IDLE_EX0 và N_IDLE_EX1 mà FreshAnimation chọn ngẫu nhiên. Không có "đi": di
// chuyển luôn là chạy, cả người chơi lẫn NPC. kJumpStand và kJumpRun là BASE_ACTION_N_JUMP_N (9) và
// BASE_ACTION_N_JUMP_R (12) mà CObject_Character::Jump chọn.
enum class Action : std::uint8_t { kIdle, kIdleAlt, kIdleAlt2, kRun, kJumpStand, kJumpRun, kCombatIdle, kCombatRun };

// Loại vũ khí theo thứ tự ENUM_WEAPON_TYPE của ref.
enum class Weapon : std::uint8_t { kNone, kSpear, kBlade, kDualShort, kShort, kFan, kRing };

struct PlayerBody {
    Race race = Race::kFemale;
    std::string name;
    // Mẫu của Model/all.obj (CharModelEx): chứa locator và khối Skeletons.
    std::string template_name;
    // Tệp .skeleton chính dưới Model/.
    std::string skeleton;
    std::uint16_t face = 0;
    std::uint16_t hair = 0;
    std::uint16_t body = 0;
    std::uint16_t arm = 0;
    std::uint16_t foot = 0;
    std::uint32_t anim_set = 0;
    float height = 0.0F;
};

struct FaceRow {
    std::uint16_t id = 0;
    Race race = Race::kFemale;
    std::string mesh;
    bool is_creatable = false;
};

struct HairRow {
    std::uint16_t id = 0;
    Race race = Race::kFemale;
    // Rỗng: kiểu tóc không có lưới (trọc).
    std::string mesh;
    // Rỗng: không có phụ kiện.
    std::string accessory;
    bool is_creatable = false;
};

struct OutfitRow {
    std::uint16_t id = 0;
    Race race = Race::kFemale;
    std::string mesh;
    // Tên material theo thứ tự submesh; rỗng là giữ material của lưới.
    std::vector<std::string> materials;
};

struct AnimRow {
    std::uint32_t set = 0;
    Action action = Action::kIdle;
    Weapon weapon = Weapon::kNone;
    // Tệp .skeleton chứa clip, dưới Model/.
    std::string anim;
    std::string clip;
};

// Dòng clip có giới: bộ động tác mà hai giới cùng dùng ra clip khác nhau trên skeleton mỗi giới.
struct RacedAnimRow {
    Race race = Race::kFemale;
    AnimRow anim;
};

// Câu lỗi tiếng Việt kèm số dòng; mỗi bộ đọc dừng ở dòng sai đầu tiên.
template <typename Row>
using Rows = std::expected<std::vector<Row>, std::string>;

// Cột: race (0, 1), name, template, skeleton, face, hair (0..65535), body, arm, foot (1..65535),
// anim_set (0..2^32-1), height (dương). Khoá race. Ít nhất một dòng.
[[nodiscard]] Rows<PlayerBody> read_player_bodies(const table::Tsv& table);

// Cột: id (0..65535), race, mesh, creatable (0, 1). Khoá (id, race).
[[nodiscard]] Rows<FaceRow> read_faces(const table::Tsv& table);

// Cột: id (0..65535), race, mesh và accessory (được rỗng), creatable. Khoá (id, race).
[[nodiscard]] Rows<HairRow> read_hairs(const table::Tsv& table);

// Cột: id (1..65535), race, mesh, materials (tên cách nhau bằng ";", được rỗng). Khoá (id, race).
[[nodiscard]] Rows<OutfitRow> read_outfits(const table::Tsv& table);

// Cột: set, action (idle, idle_alt, idle_alt2, run, combat_idle, combat_run), weapon (none, spear,
// blade, dual_short, short, fan, ring), anim, clip. Khoá (set, action, weapon). Ít nhất một dòng.
[[nodiscard]] Rows<AnimRow> read_anim_sets(const table::Tsv& table);

// Cột của read_anim_sets thêm race (0, 1). Khoá (race, set, action, weapon). Ít nhất một dòng.
[[nodiscard]] Rows<RacedAnimRow> read_raced_anims(const table::Tsv& table);

// Loại vũ khí theo tên trong bảng (none, spear, blade, dual_short, short, fan, ring); nullopt khi tên lạ.
[[nodiscard]] std::optional<Weapon> weapon_named(std::string_view name);

// Tra theo khoá; nullptr khi không có. Con trỏ mượn vào rows.
[[nodiscard]] const PlayerBody* find_body(std::span<const PlayerBody> rows, Race race);
[[nodiscard]] const FaceRow* find_face(std::span<const FaceRow> rows, std::uint16_t id, Race race);
[[nodiscard]] const HairRow* find_hair(std::span<const HairRow> rows, std::uint16_t id, Race race);
[[nodiscard]] const OutfitRow* find_outfit(std::span<const OutfitRow> rows, std::uint16_t id, Race race);
[[nodiscard]] const AnimRow* find_anim(std::span<const AnimRow> rows, std::uint32_t set,
    Action action, Weapon weapon);
[[nodiscard]] const AnimRow* find_raced_anim(std::span<const RacedAnimRow> rows, Race race,
    std::uint32_t set, Action action, Weapon weapon);

} // namespace game::look
