#include "ui/panel/main_menu_bar_3.hpp"

#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/events.hpp"
#include "ui/panel/widgets.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <format>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::ui::panel {
namespace {

// Số ô của thanh (MAIN_3_BUTTON_NUM, MAIN_3_ANIMATE_NUM).
constexpr std::size_t kButtonCount = kPetButtons.size();
// Lời nhắc khi hành động bị chặn ("你不能这么做。").
constexpr std::string_view kCannotDo = "你不能这么做。";

// MainMenuBar_3_ShowItems(idx): hiện các nút từ 1 tới idx, giấu phần còn lại.
void show_items(MainMenuBar3& bar, std::size_t shown) {
    for (std::size_t slot = 0; slot < kButtonCount; ++slot) {
        if (slot < shown) {
            bar.widgets.show(kPetButtons.at(slot));
        } else {
            bar.widgets.hide(kPetButtons.at(slot));
        }
    }
}

// MainMenuBar_3_PlayAnimate(idx): cửa sổ hoạt ảnh của các nút từ 1 tới idx hiện và chạy lặp, phần còn lại giấu.
void play_animate(MainMenuBar3& bar, std::size_t shown) {
    for (std::size_t slot = 0; slot < kButtonCount; ++slot) {
        if (slot < shown) {
            bar.widgets.show(kPetMasks.at(slot));
            bar.widgets.play(kPetMasks.at(slot), true);
        } else {
            bar.widgets.hide(kPetMasks.at(slot));
        }
    }
}

// Nhánh CHANGE_PETSKILL_BAR: giấu thanh, rồi đặt tối đa hai action không rỗng đầu tiên của thanh thú cưng
// vào hai nút và hiện lại thanh nếu có action nào.
void change_pet_skill_bar(MainMenuBar3& bar, PetSkillBar pet_bar) {
    bar.is_shown = false;
    const std::size_t count = std::min(pet_bar.size(), kButtonCount);
    std::size_t next = 0;
    for (std::size_t index = 0; index < count; ++index) {
        const ActionFace& action = pet_bar[index];
        if (action.id == 0) continue;
        bar.widgets.set_action(kPetButtons.at(next), action);
        ++next;
        if (next >= kButtonCount) break;
    }
    if (next == 0) return;
    bar.is_shown = true;
    show_items(bar, next);
    play_animate(bar, next);
}

// Nhánh HIDE_THIS_UI: đảo trạng thái hiện của thanh.
void toggle_hidden(MainMenuBar3& bar) noexcept {
    bar.is_shown = !bar.is_shown;
}

} // namespace

void on_main_menu_bar_3_event(MainMenuBar3& bar, const UiEvent& event, PetSkillBar pet_bar) {
    if (event.name == "CHANGE_PETSKILL_BAR") {
        change_pet_skill_bar(bar, pet_bar);
        return;
    }
    // CHAT_ADJUST_MOVE_CTL gọi MainMenuBar_3_AdjustMoveCtl(arg0, arg1), hàm có thân toàn chú thích: không
    // đổi gì (xem "Khác gốc" ở đầu .hpp).
    if (event.name == "HIDE_THIS_UI") toggle_hidden(bar);
}

void press_pet_skill_button(const MainMenuBar3& bar, std::int32_t index, bool can_do, std::vector<Call>& calls) {
    if (index < 1 || std::cmp_greater(index, kButtonCount)) return;
    if (!can_do) {
        calls.push_back(Call{.ask = Ask::kPushDebugMessage, .text = std::string(kCannotDo)});
        return;
    }
    const std::string_view button = kPetButtons.at(static_cast<std::size_t>(index) - 1);
    // ActionButton:DoAction (UI_CEGUI 0x180028c00): ô trống thì không làm gì.
    const std::int32_t action = bar.widgets.action_item(button);
    if (action == kEmptyAction) return;
    calls.push_back(Call{.ask = Ask::kDoAction, .text = std::format("{}\t{}", button, action)});
}

void paint_main_menu_bar_3(Deck& deck, const MainMenuBar3& bar) {
    if (!bar.is_shown) return;
    deck.show(kMainMenuBar3Root);
    bar.widgets.paint(deck);
}

} // namespace game::ui::panel
