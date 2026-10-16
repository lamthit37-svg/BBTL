#pragma once
// Giải ngoại hình người chơi: từ giới và khối Look ra skeleton chính, các lưới bộ phận kèm
// material, và clip đứng, nghỉ, chạy theo loại vũ khí. Luật mặc định giữ ngữ nghĩa ref
// (CObject_PlayerOther::UnEquipItem, _setEntityMaterial): áo, tay, giày 0 hay không có thì dùng bộ
// mặc định của giới; mũ 0 hay không có thì không vẽ; mặt, tóc không có hay khác giới thì dùng mặc
// định. Logic thuần, không I/O: client chọn lưới để vẽ.
// Nguồn: TLBB Dev src/look/look.hpp@e0d89a6. Khác gốc: giới là Race của CharRace; Look.weapon là
// loại vũ khí cầm (Weapon, của vật phẩm) và Look.weapon_visual là id hình (của vật phẩm) vì một hình
// do nhiều loại dùng chung; vũ khí đi theo bảy khe (Hold) chứ không chỉ hai tay; chưa có clip NPC.
// Cột creatable của mặt và tóc dùng khi nạp danh sách của màn tạo nhân vật.

#include "look/appearance.hpp"
#include "look/weapon.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <functional>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::look {

// Năm bảng ngoại hình đã đọc.
struct Tables {
    std::vector<PlayerBody> bodies;
    std::vector<FaceRow> faces;
    std::vector<HairRow> hairs;
    std::vector<OutfitRow> outfits;
    std::vector<AnimRow> anims;
    // Rỗng: mọi người chơi tay không (load_weapon_tables điền).
    WeaponTables weapons;
};

// Khối ngoại hình của một người chơi: id hình từng khe (0 là mặc định với mặt, tóc, áo, tay, giày;
// với mũ là không có), loại vũ khí đang cầm (chọn clip) và id hình vũ khí (chọn mẫu gắn tay; 0 là
// không có). Hai giá trị cùng lấy từ vật phẩm khe 0: equip_weapon.
struct Look {
    std::uint16_t face = 0;
    std::uint16_t hair = 0;
    std::uint16_t cap = 0;
    std::uint16_t body = 0;
    std::uint16_t arm = 0;
    std::uint16_t foot = 0;
    Weapon weapon = Weapon::kNone;
    std::uint16_t weapon_visual = 0;
    // Vật phẩm đá quý gắn vào vũ khí (Get_EquipGem(HEQUIP_WEAPON) của ref); 0 là không có. Cho hiệu ứng đồ (gem_effect).
    std::uint32_t weapon_gem = 0;
};

enum class Slot : std::uint8_t { kBody, kArm, kFoot, kFace, kCap, kHair, kHairAccessory };

struct Part {
    Slot slot = Slot::kBody;
    std::string mesh;
    // Tên material theo thứ tự submesh; rỗng là giữ material của lưới.
    std::vector<std::string> materials;
};

// Một clip trong một tệp .skeleton; đánh giá trên skeleton chính, không trên skeleton của tệp.
struct Clip {
    std::string anim;
    std::string name;
};

// Chỉnh riêng của dự án lên một xương lúc phát clip đứng: xoay thêm turn radian quanh trục z của
// chính xương đó (với xương đầu của người chơi, trục ấy nằm ngang qua hai tai; dương là cúi mặt).
struct BoneTrim {
    std::string bone;
    float turn = 0.0F;
};

// Một mẫu vũ khí đã giải: khe nó đứng, mẫu .obj, các lưới (tệp .mesh), tỉ lệ của mẫu và locator của
// mẫu nhân vật giữ khe đó. Vị trí thật theo xương mỗi khung do avatar tính (avatar/locator.hpp).
struct Held {
    Hold hold = Hold::kRight;
    std::string object;
    std::vector<std::string> meshes;
    std::array<float, 3> scale{1.0F, 1.0F, 1.0F};
    LocatorRow locator;
    // Hiệu ứng đá quý của khe (gem_effect): tên effect gắn vào locator 武器特效点 của mẫu và màu RRGGBBAA; rỗng là không có.
    std::string effect;
    std::uint32_t effect_colour = 0;
};

struct Figure {
    std::string skeleton;
    // Mẫu nhân vật chính trong Model/all.obj.
    std::string template_name;
    float height = 0.0F;
    // Thứ tự vẽ: phần đặc trước, tóc (trộn alpha) sau cùng.
    std::vector<Part> parts;
    // Vũ khí và đồ gắn theo khe, theo thứ tự Hold; khe trống hay mẫu thiếu thì không có phần tử.
    std::vector<Held> held;
    Clip idle;
    // Hai động tác nghỉ nhỏ N_IDLE_EX0 và N_IDLE_EX1; rỗng khi bảng không có dòng.
    std::optional<Clip> idle_alt;
    std::optional<Clip> idle_alt2;
    Clip run;
    // Clip nhảy của BASE_ACTION_N_JUMP_N và N_JUMP_R; rỗng khi bảng không có dòng (ChangeAction của gốc
    // khi đó giữ nguyên clip đang phát).
    std::optional<Clip> jump_stand;
    std::optional<Clip> jump_run;
    // Clip chết và xác của quái, NPC, trân thú. Người chơi không có dòng trong anim_sets.
    std::optional<Clip> death;
    std::optional<Clip> corpse;
    // Có thì áp lên clip đứng (xem resolve); người mẫu môn phái và nữ không có.
    std::optional<BoneTrim> idle_trim;
};

// Bảng thiếu thứ mà mọi người chơi của giới đó cần.
enum class LookError : std::uint8_t {
    kNoBody,
    kNoDefaultFace,
    kNoDefaultHair,
    kNoDefaultOutfit,
    kNoIdle,
    kNoRun,
};

// Câu tiếng Việt cho log.
[[nodiscard]] std::string_view describe(LookError error);

// Đặt loại vũ khí và id hình của look theo vật phẩm khe 0 (GetWeaponType và GetVisualID của ref). Sai
// (trả false, look không đổi) khi bảng vật phẩm không có item. Vật phẩm không hình thì chỉ đặt loại.
[[nodiscard]] bool equip_weapon(Look& look, const WeaponTables& tables, std::uint32_t item);

// Hình của người chơi giới race mang look, ngoài chiến đấu. Clip theo loại vũ khí cầm; loại không
// có dòng cho một hành động thì dùng dòng tay không của hành động đó.
[[nodiscard]] std::expected<Figure, LookError> resolve(const Tables& tables, Race race, const Look& look);

// Cả tệp ở path dưới dạng chữ, hay câu lỗi tiếng Việt khi không đọc được. Bên gọi quyết nguồn: đĩa,
// assets của APK; module này không làm I/O.
using ReadFile = std::function<std::expected<std::string, std::string>(const std::string& path)>;

// Các bảng trong thư mục folder: player_bodies.tsv, faces.tsv, hairs.tsv, outfits.tsv,
// anim_sets.tsv, theo thứ tự đó, dừng ở bảng hỏng đầu tiên. Lỗi là câu tiếng Việt có đường dẫn tệp,
// và dòng, cột khi bảng sai.
[[nodiscard]] std::expected<Tables, std::string> load_tables(std::string_view folder, const ReadFile& read);

// Bốn bảng vũ khí trong folder: weapons.tsv, weapon_items.tsv, objects.tsv, locators.tsv, theo thứ
// tự đó, dừng ở bảng hỏng đầu tiên. Tách khỏi load_tables vì người chơi tay không không cần chúng.
[[nodiscard]] std::expected<WeaponTables, std::string> load_weapon_tables(std::string_view folder,
    const ReadFile& read);

} // namespace game::look
