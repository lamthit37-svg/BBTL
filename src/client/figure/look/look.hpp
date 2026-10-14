#pragma once
// Giải ngoại hình người chơi: từ giới và khối Look ra skeleton chính, các lưới bộ phận kèm
// material, và clip đứng, nghỉ, chạy theo loại vũ khí. Luật mặc định giữ ngữ nghĩa ref
// (CObject_PlayerOther::UnEquipItem, _setEntityMaterial): áo, tay, giày 0 hay không có thì dùng bộ
// mặc định của giới; mũ 0 hay không có thì không vẽ; mặt, tóc không có hay khác giới thì dùng mặc
// định. Logic thuần, không I/O: client chọn lưới để vẽ.
// Nguồn: TLBB Dev src/look/look.hpp@e0d89a6. Khác gốc: giới là Race của CharRace; Look.weapon là
// loại vũ khí cầm (Weapon) thay cho id hình vũ khí vì dự án chưa có bảng vũ khí; chưa có vũ khí mỗi
// tay và clip NPC (làm cùng NPC và vũ khí). Cột creatable của mặt và tóc dùng khi nạp danh sách
// của màn tạo nhân vật.

#include "look/appearance.hpp"

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
};

// Khối ngoại hình của một người chơi: id hình từng khe (0 là mặc định với mặt, tóc, áo, tay, giày;
// với mũ là không có) và loại vũ khí đang cầm.
struct Look {
    std::uint16_t face = 0;
    std::uint16_t hair = 0;
    std::uint16_t cap = 0;
    std::uint16_t body = 0;
    std::uint16_t arm = 0;
    std::uint16_t foot = 0;
    Weapon weapon = Weapon::kNone;
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

struct Figure {
    std::string skeleton;
    // Mẫu nhân vật chính trong Model/all.obj.
    std::string template_name;
    float height = 0.0F;
    // Thứ tự vẽ: phần đặc trước, tóc (trộn alpha) sau cùng.
    std::vector<Part> parts;
    Clip idle;
    // Hai động tác nghỉ nhỏ N_IDLE_EX0 và N_IDLE_EX1; rỗng khi bảng không có dòng.
    std::optional<Clip> idle_alt;
    std::optional<Clip> idle_alt2;
    Clip run;
    // Clip nhảy của BASE_ACTION_N_JUMP_N và N_JUMP_R; rỗng khi bảng không có dòng (ChangeAction của gốc
    // khi đó giữ nguyên clip đang phát).
    std::optional<Clip> jump_stand;
    std::optional<Clip> jump_run;
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

} // namespace game::look
