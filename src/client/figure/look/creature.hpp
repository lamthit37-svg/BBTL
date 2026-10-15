/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/figure/look/creature.hpp
 *  PHÂN HỆ   : Figure / Look / Creature
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hình của quái và NPC: từ id mẫu máy chủ gửi (EntityAppear.template_id) ra
 *    mô hình, lưới, xương, clip và tỉ lệ vẽ. Logic thuần như look/sect.hpp:
 *    không I/O, bên gọi đưa chữ của bảng. Bốn bảng do
 *    TOOLS/content/export_creatures.py sinh từ MonsterAttrExTable, CharModelEx
 *    và Model/all.obj của client 2026 (lược đồ ở dòng chú thích đầu mỗi bảng):
 *  - creature_templates.tsv  template -> model, tỉ lệ, loại (npc hay monster)
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

//   creatures.tsv           model -> lưới, xương, Scale của mẫu, material chồng lên lưới
//   creature_clips.tsv      (model, loại, hành động) -> clip
//   creature_materials.tsv  material chồng -> ảnh nền và cách trộn alpha
//
// Cách hỏng đã tính trước (CL-03):
//   bảng thiếu cột, ô sai kiểu hay ngoài miền -> lỗi kèm tên bảng, số dòng và tên cột; không dựng nửa chừng.
//   template không có trong bảng              -> lỗi; nơi vẽ ghi log một lần và bỏ thực thể đó.
//   mô hình thiếu hành động nào               -> hành động đó rỗng, không bịa clip (đứng là bắt buộc để có xương).
//   mô hình không xương                       -> hình tĩnh (is_animated sai): nơi vẽ không dựng avatar.
//   dòng trùng khoá                           -> lỗi, vì tra theo khoá sẽ chọn dòng sai mà nhìn không lộ.
// Độ phức tạp: dựng bảng O(n log n) theo số dòng; creature_figure O(log n + số clip của mô hình).

#pragma once

#include "look/look.hpp"

#include <array>
#include <cstdint>
#include <expected>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::look {

// Quái bị đánh, hay NPC (MonsterAttrExTable cột 2 lớn hơn 0): chọn cột clip của bộ hành động.
enum class CreatureKind : std::uint8_t { kMonster, kNpc };

// Hành động cơ sở của bộ hành động (ActionSetLine) mà client dùng cho quái và NPC.
enum class CreatureAction : std::uint8_t {
    kIdle,
    kIdleAlt,
    kIdleAlt2,
    kWalk,
    kRun,
    kCombatIdle,
    kCombatWalk,
    kCombatRun,
    kHit,
    kDeath,
    kCorpse,
    kAttack,
    kAttackAlt,
    kAttackAlt2,
    kDefault,
};

struct CreatureTemplate {
    std::uint32_t id = 0;
    std::string name;
    // Id CharModelEx; -1 là không có mô hình.
    std::int32_t model = -1;
    // Độ cao bảng tên (mét của game); âm là để nơi vẽ tính theo chiều cao mô hình.
    float plate_height = -1.0F;
    float ring_size = 0.0F;
    float shadow_size = 0.0F;
    // Hệ số tỉ lệ đều của mô hình (CharModelEx cột 5), nhân với Scale của mẫu.
    float scale = 1.0F;
    CreatureKind kind = CreatureKind::kMonster;
};

struct CreatureModel {
    std::int32_t id = 0;
    // Tệp .mesh dưới Model/, theo thứ tự entity của mẫu.
    std::vector<std::string> meshes;
    // Material chồng lên từng lưới, cùng số phần tử với meshes; rỗng là dùng material của lưới.
    std::vector<std::string> materials;
    // Tệp .skeleton chính; rỗng là mô hình tĩnh.
    std::string skeleton;
    std::array<float, 3> scale{1.0F, 1.0F, 1.0F};
    // Chiều cao BoundingBox của mẫu; 0 là không khai.
    float height = 0.0F;
};

enum class OverlayAlpha : std::uint8_t { kOpaque, kMask, kBlend };

// Material chồng lên lưới: ảnh nền và cách trộn, cùng luật mà bộ đổi GLB dùng.
struct CreatureMaterial {
    std::string name;
    // Đường dẫn từ gốc dữ liệu.
    std::string texture;
    OverlayAlpha alpha = OverlayAlpha::kOpaque;
    float cutoff = 0.5F;
    bool double_sided = false;
    bool unlit = false;
};

struct CreatureClip {
    std::int32_t model = 0;
    CreatureKind kind = CreatureKind::kMonster;
    CreatureAction action = CreatureAction::kIdle;
    // Tệp .skeleton chứa clip và tên animation trong đó.
    Clip clip;
};

// Chữ của bốn bảng, đúng như tệp.
struct CreatureTexts {
    std::string_view templates;
    std::string_view models;
    std::string_view clips;
    std::string_view materials;
};

// Bốn bảng đã đọc, sắp theo khoá để tra O(log n).
struct CreatureTables {
    std::vector<CreatureTemplate> templates;
    std::vector<CreatureModel> models;
    std::vector<CreatureClip> clips;
    std::vector<CreatureMaterial> materials;

    [[nodiscard]] const CreatureTemplate* find_template(std::uint32_t id) const noexcept;
    [[nodiscard]] const CreatureModel* find_model(std::int32_t id) const noexcept;
    [[nodiscard]] const CreatureMaterial* find_material(std::string_view name) const noexcept;
    // Clip của hành động action của mô hình model với loại kind; rỗng khi bảng không có dòng đó.
    [[nodiscard]] const CreatureClip* find_clip(std::int32_t model, CreatureKind kind,
        CreatureAction action) const noexcept;
};

// Câu lỗi tiếng Việt kèm tên bảng và dòng. O(n log n) theo số dòng.
[[nodiscard]] std::expected<CreatureTables, std::string> parse_creature_tables(const CreatureTexts& texts);

// Hình của một template, sẵn để dựng avatar và nạp lưới.
struct CreatureFigure {
    // parts: lưới theo thứ tự entity, Part::materials mang material chồng (nếu có) làm phần tử duy nhất.
    // skeleton, idle, idle_alt, idle_alt2: động tác của mô hình; run là chạy, hoặc đi bộ khi mô hình không chạy, hoặc
    // chính clip đứng khi mô hình không di chuyển được. Rỗng cả skeleton khi is_animated sai.
    Figure figure;
    // Clip đi bộ riêng (khác run) để nơi vẽ chọn theo tốc độ; rỗng khi mô hình không có.
    std::optional<Clip> walk;
    std::optional<Clip> death;
    std::optional<Clip> corpse;
    // Tỉ lệ vẽ ba trục: tỉ lệ của template nhân Scale của mẫu.
    std::array<float, 3> scale{1.0F, 1.0F, 1.0F};
    // Chiều cao của mô hình ở tỉ lệ 1 (mét của game); 0 là mẫu không khai.
    float height = 0.0F;
    float plate_height = -1.0F;
    CreatureKind kind = CreatureKind::kMonster;
    // Có xương và clip đứng. Sai thì hình tĩnh.
    bool is_animated = false;
};

// Hình của template id; lỗi khi template hay mô hình không có trong bảng, hay mô hình không lưới.
[[nodiscard]] std::expected<CreatureFigure, std::string> creature_figure(const CreatureTables& tables,
    std::uint32_t template_id);

// Bốn bảng trong thư mục folder (creature_templates.tsv, creatures.tsv, creature_clips.tsv, creature_materials.tsv);
// thiếu tệp là lỗi có đường dẫn.
[[nodiscard]] std::expected<CreatureTables, std::string> load_creature_tables(std::string_view folder,
    const ReadFile& read);

} // namespace game::look
