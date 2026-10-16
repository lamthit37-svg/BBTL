/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/panel/skill_bar.hpp
 *  PHÂN HỆ   : Ui / Panel / SkillBar
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Mười ô Button_Action1..10 của MainMenuBar: icon và tên từ
 *    Table/skills.tsv, tối khi còn hồi chiêu. Khác gốc: client 2026 để người
 *    chơi kéo chiêu vào thanh và máy chủ nhớ bố cục; dây v6 chỉ có danh sách đã
 *    học, nên ô k là kỹ năng thứ k của danh sách đó (cùng thứ tự phím 1..9 và
 *    phím 0).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Chưa có: kéo thả, trang 2 và 3, hàng biến thân, vệt hồi chiêu (CoolDownEnd2 chưa nạp;
// đang hồi thì Gloom). Tooltip chỉ là thuộc tính, bộ vẽ chưa đọc.

#pragma once

#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <unordered_map>

namespace game::ui::panel {

class Deck;
class ItemNames;

// Mười ô trang 1 của MainMenuBar (Button_Action1..10). Trang 2, 3 và hàng biến thân do show_start giấu.
inline constexpr std::size_t kSkillBarSlots = 10;
// Trần dòng của Table/skills.tsv. Bảng thật 4586 dòng; dòng vượt trần bị bỏ, không cấp phát theo tệp.
inline constexpr std::size_t kSkillBookRows = 8192;

// id, tên và icon ngắn của Table/skills.tsv. Tra theo id: kết quả không phụ thuộc thứ tự băm.
class SkillBook {
public:
    // Đọc cột id, name, icon. Thiếu id hoặc name thì giữ sách rỗng và trả false. Id lặp giữ dòng đầu.
    bool load(std::string_view tsv_text);
    [[nodiscard]] std::string_view name(std::int32_t skill) const noexcept;
    [[nodiscard]] std::string_view icon(std::int32_t skill) const noexcept;
    // "set:<imageset> image:<icon>" qua icons. Id vượt int32, thiếu icon hoặc thiếu imageset thì "set:X image:X".
    [[nodiscard]] std::string face(std::uint32_t skill, const ItemNames& icons) const;
    [[nodiscard]] bool is_loaded() const noexcept { return is_loaded_; }

private:
    struct Entry {
        std::string name;
        std::string icon;
    };

    std::unordered_map<std::int32_t, Entry> rows_;
    bool is_loaded_ = false;
};

// Button_Action1 là ô 0. Button_Action11 và tên khác không phải ô của trang này.
[[nodiscard]] std::optional<std::uint32_t> skill_slot_of(std::string_view window) noexcept;

// Vẽ mười ô. skills[i] lên Button_Action(i+1); ô không có kỹ năng thì trống. left_ms cùng chỉ số, thiếu thì coi là đã hồi.
// O(kSkillBarSlots) mỗi khung; skills do máy chủ chặn ở fight::kMaxKnown, left_ms dài hơn mười ô thì bỏ phần dư.
void paint_skill_bar(Deck& deck, std::span<const std::uint32_t> skills, std::span<const std::uint32_t> left_ms,
    const SkillBook& book, const ItemNames& icons);

} // namespace game::ui::panel
