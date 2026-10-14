#include "ui/panel/action_bar.hpp"

#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/events.hpp"
#include "ui/panel/widgets.hpp"

#include <algorithm>
#include <cerrno>
#include <cmath>
#include <compare>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <format>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::ui::panel {
namespace {

// Gói tin và chuỗi trên dây là số nguyên; id lớn hơn miền int32 thì ép về cận (game ép (int) lên số thực).
constexpr double kInt32Min = static_cast<double>(std::numeric_limits<std::int32_t>::min());
constexpr double kInt32Max = static_cast<double>(std::numeric_limits<std::int32_t>::max());
// Số thú cưng tối đa (pet_num < 6).
constexpr std::size_t kPetCount = 6;
// Chỉ số ô gói hành động chat lớn nhất mà script nhận (index > 10 thì bỏ).
constexpr double kLastChatPack = 10.0;

// Nhãn của hai cửa sổ nháy.
constexpr std::string_view kJuniorTail = "_junior_Flash";
constexpr std::string_view kSeniorTail = "_senior_Flash";
// Lời nhắc khi hành động bị chặn ("你不能这么做。").
constexpr std::string_view kCannotDo = "你不能这么做。";
// Cờ nháy của FLASH_COMBOSKILL.
constexpr double kJuniorFlash = 1.0;
constexpr double kSeniorFlash = 2.0;

// tonumber(text) của Lua 5.0: nhận khoảng trắng hai đầu, dấu +/-, "5.", ".5", số mũ e hoặc d; không nhận
// thập lục phân, "inf", "nan", chuỗi rỗng. nullopt là nil. Số tràn thành vô cực, số quá nhỏ thành +0 (strtod của
// MSVCR110 mà LuaPlus gọi).
[[nodiscard]] std::optional<double> parse_number(std::string_view raw) {
    constexpr std::string_view kSpace = " \t\n\v\f\r";
    const std::size_t first = raw.find_first_not_of(kSpace);
    if (first == std::string_view::npos) return std::nullopt;
    std::string_view text = raw.substr(first, raw.find_last_not_of(kSpace) - first + 1);
    const bool is_negative = text.starts_with('-');
    if (is_negative || text.starts_with('+')) text.remove_prefix(1);
    // Chỉ chữ số, một dấu chấm và số mũ; strtod còn nhận thập lục phân, inf, nan nên lọc trước.
    std::string clean;
    std::size_t digits = 0;
    bool has_dot = false;
    bool has_exponent = false;
    for (std::size_t at = 0; at < text.size(); ++at) {
        const char letter = text[at];
        if (letter >= '0' && letter <= '9') {
            ++digits;
            clean.push_back(letter);
        } else if (letter == '.' && !has_dot && !has_exponent) {
            has_dot = true;
            clean.push_back(letter);
        } else if ((letter == 'e' || letter == 'E' || letter == 'd' || letter == 'D') && !has_exponent && digits > 0) {
            has_exponent = true;
            clean.push_back('e');
            if (at + 1 < text.size() && (text[at + 1] == '+' || text[at + 1] == '-')) clean.push_back(text[++at]);
            if (at + 1 >= text.size()) return std::nullopt;
        } else {
            return std::nullopt;
        }
    }
    if (digits == 0) return std::nullopt;
    errno = 0;
    char* stop = nullptr;
    double value = std::strtod(clean.c_str(), &stop);
    if (stop == nullptr || *stop != '\0') return std::nullopt;
    if (errno == ERANGE && std::fabs(value) < 1.0) value = 0.0;
    return is_negative ? -value : value;
}

// tonumber(arg<k>): nil khi chưa có đối số hay không đọc được thành số.
[[nodiscard]] std::optional<double> to_number(std::optional<std::string_view> text) {
    if (!text) return std::nullopt;
    return parse_number(*text);
}

// Số trong chuỗi mà script ghép vào lời gọi ("%.14g"): số nguyên in không dấu chấm.
[[nodiscard]] std::string number_text(double value) {
    return std::format("{:.14g}", value);
}

[[nodiscard]] std::int32_t to_int(double value) noexcept {
    if (std::isnan(value)) return 0;
    return static_cast<std::int32_t>(std::clamp(std::trunc(value), kInt32Min, kInt32Max));
}

// Vị trí 0.. của ô mang id trong các dãy BUTTONS và FLASH của script; nullopt khi bảng không có khoá đó (id ngoài
// dải hay không nguyên: script gọi phương thức lên nil và dừng).
[[nodiscard]] std::optional<std::size_t> slot_of(const BarSpec& spec, double id) noexcept {
    const double first = spec.first_id;
    if (!(id >= first && id < first + spec.count)) return std::nullopt;
    const auto whole = static_cast<std::int32_t>(id);
    if (!std::is_eq(id <=> static_cast<double>(whole))) return std::nullopt;
    return static_cast<std::size_t>(whole - spec.first_id);
}

// IsVisible() của một cửa sổ con: hiện cả chuỗi cha. Hai khung bọc (ActionButton, junior/senior_Flash) và cửa sổ
// gốc là hai tầng cha; khung bọc không bao giờ đổi, nên chỉ còn cờ của cửa sổ gốc.
[[nodiscard]] bool is_visible(const ActionBar& bar, std::string_view window) {
    return bar.is_shown && bar.widgets.is_shown(window);
}

[[nodiscard]] ActionFace face_of(std::span<const ActionFace> actions, std::int32_t id) {
    const auto found = std::ranges::find(actions, id, &ActionFace::id);
    return found == actions.end() ? ActionFace{.id = id, .icon = {}} : *found;
}

// Ô trong nhánh "đặt" hay "dọn" có id (CHANGE_BAR): SetActionItem rồi Bright. id -1 là ô trống.
void put_action(ActionBar& bar, std::size_t slot, ActionFace face) {
    const std::string& button = bar.buttons.at(slot);
    bar.widgets.set_action(button, std::move(face));
    bar.widgets.gloom(button, false);
}

// Nếu ô id đang hiện (BUTTONS[id]:IsVisible()) thì gỡ hai cửa sổ nháy của nó nếu chúng đang hiện. false: script
// dừng vì lỗi (khoá không có trong bảng).
[[nodiscard]] bool clear_flashes_of_visible(ActionBar& bar, double id) {
    if (!bar.spec->seen_range.contains(id)) return true;
    const std::optional<std::size_t> slot = slot_of(*bar.spec, id);
    if (!slot) return false;
    if (!is_visible(bar, bar.buttons.at(*slot))) return true;
    if (is_visible(bar, bar.juniors.at(*slot))) bar.widgets.hide(bar.juniors.at(*slot));
    if (is_visible(bar, bar.seniors.at(*slot))) bar.widgets.hide(bar.seniors.at(*slot));
    return true;
}

// Pet:IsPresent(n) và Pet:GetIsFighting(n) cùng đúng; nullopt khi n ngoài 0..5 (script không hỏi).
[[nodiscard]] std::optional<bool> is_pet_fighting(const BarFacts& facts, double pet) noexcept {
    if (!(pet >= 0.0 && pet < static_cast<double>(kPetCount))) return std::nullopt;
    return facts.pet_is_fighting.at(static_cast<std::size_t>(pet));
}

// CHANGE_BAR với arg0 == "main": ô arg1 nhận action arg2, tô sáng hay mờ theo thú cưng arg3 nếu có.
void place_action(ActionBar& bar, const UiEvent& event, const BarFacts& facts, std::vector<Call>& calls) {
    const BarSpec& spec = *bar.spec;
    const auto refresh = [&calls] { calls.push_back(Call{.ask = Ask::kUpdateActionButton, .text = {}}); };
    if (spec.is_refresh_always) refresh();
    const std::optional<double> id = to_number(event.arg(1));
    if (!id) return;
    if (spec.set_range.contains(*id)) {
        if (!spec.is_refresh_always) refresh();
        const std::optional<std::size_t> slot = slot_of(spec, *id);
        const std::optional<double> action = to_number(event.arg(2));
        if (!slot || !action) return;
        put_action(bar, *slot, face_of(facts.actions, to_int(*action)));
        if (const std::optional<std::string_view> pet_text = event.arg(3)) {
            const std::optional<double> pet = to_number(pet_text);
            if (!pet) return;
            // Thú cưng đang chiến đấu thì ô sáng, không thì mờ.
            if (const std::optional<bool> is_fighting = is_pet_fighting(facts, *pet)) {
                bar.widgets.gloom(bar.buttons.at(*slot), !*is_fighting);
            }
        }
    }
    // Ô vừa đặt hay không: ô đang hiện thì gỡ nháy; khoá không có trong bảng là lỗi cuối script, không còn gì để dừng.
    static_cast<void>(clear_flashes_of_visible(bar, *id));
}

// CHANGE_BAR với arg0 == "mainreset": arg1 là số ô cần dọn, id các ô là eventTable[3..arg1 + 2].
void reset_actions(ActionBar& bar, const UiEvent& event) {
    const BarSpec& spec = *bar.spec;
    const std::optional<double> amount = to_number(event.arg(1));
    if (!amount) return;
    // for i = 3, arg1 + 2: eventTable chỉ có bấy nhiêu phần tử, gặp phần tử nil thì script dừng với lỗi, nên vòng
    // lặp không cần chạy quá số phần tử đang giữ.
    const double last = std::min(*amount + 2.0, static_cast<double>(event.values.size()));
    if (!(last >= 3.0)) return;
    for (auto position = static_cast<std::size_t>(3); position <= static_cast<std::size_t>(last); ++position) {
        const std::optional<double> id = to_number(event.table(position));
        if (!id) return;
        if (spec.set_range.contains(*id)) {
            const std::optional<std::size_t> slot = slot_of(spec, *id);
            if (!slot) return;
            put_action(bar, *slot, ActionFace{.id = kEmptyAction, .icon = {}});
        }
        if (!clear_flashes_of_visible(bar, *id)) return;
    }
}

void change_bar(ActionBar& bar, const UiEvent& event, const BarFacts& facts, std::vector<Call>& calls) {
    const std::optional<std::string_view> mode = event.arg(0);
    if (mode == "main") {
        place_action(bar, event, facts, calls);
    } else if (mode == "mainreset") {
        reset_actions(bar, event);
    }
}

// <Tên>_ActionUpdate / NewSkillStudy: mọi ô nhắc nháy mới.
void refresh_flashes(ActionBar& bar) {
    for (const std::string& button : bar.buttons)
        bar.widgets.flash(button);
}

// FLASH_COMBOSKILL(arg0 = id ô, arg1 = cờ): <Tên>_UpdateComboFlash. Cờ 1 nháy cấp thấp, 2 nháy cấp cao, còn lại tắt.
void combo_flash(ActionBar& bar, const UiEvent& event) {
    const std::optional<double> id = to_number(event.arg(0));
    const std::optional<double> flash = to_number(event.arg(1));
    if (!id || !bar.spec->seen_range.contains(*id)) return;
    const std::optional<std::size_t> slot = slot_of(*bar.spec, *id);
    if (!slot) return;
    const std::string& junior = bar.juniors.at(*slot);
    const std::string& senior = bar.seniors.at(*slot);
    const auto is_flash = [&flash](double wanted) { return flash && std::is_eq(*flash <=> wanted); };
    if (is_flash(kJuniorFlash)) {
        if (!is_visible(bar, junior)) {
            bar.widgets.show(junior);
            bar.widgets.hide(senior);
        }
    } else if (is_flash(kSeniorFlash)) {
        if (!is_visible(bar, senior)) {
            bar.widgets.hide(junior);
            bar.widgets.show(senior);
        }
    } else {
        bar.widgets.hide(junior);
        bar.widgets.hide(senior);
    }
}

// Danh sách mood mà gói loại kind tra: id action thứ i là Talk:EnumChatMood(i):GetID() (gói đơn) hay
// Talk:EnumDoubleChatMood(i):GetID() (gói đôi); chỉ số ngoài danh sách là action rỗng, id 0.
[[nodiscard]] const std::vector<std::int32_t>& mood_list(const ChatBook& book, std::int32_t kind) noexcept {
    return kind == kDoubleChatPack ? book.double_moods : book.moods;
}

// Phần chung của gỡ gói và dọn gói: gói ở ô index nếu đã cài thì ô nào của thanh đang giữ action của gói bị trống và
// bản ghi ô bị xoá (UnInstall_RMB_ChatAction_BarItem). index đã nằm trong 0..10.
void unlink_pack(ActionBar& bar, double index, const BarFacts& facts, std::vector<Call>& calls) {
    const ChatPack& pack = facts.chat.packs.at(static_cast<std::size_t>(index));
    if (pack.real_id <= 0 || pack.count <= 0 || pack.min_index <= 0 || pack.kind <= 0) return;
    const BarSpec& spec = *bar.spec;
    // Script xét j = 1..count ứng chỉ số min_index + j - 2; chỉ số ngoài danh sách là action rỗng (id 0, bỏ), nên chỉ
    // duyệt phần giao với danh sách.
    const auto size = static_cast<std::int64_t>(mood_list(facts.chat, pack.kind).size());
    const std::int64_t first = std::max<std::int64_t>(static_cast<std::int64_t>(pack.min_index) - 1, 0);
    const std::int64_t last = std::min<std::int64_t>(static_cast<std::int64_t>(pack.min_index) + pack.count - 2, size - 1);
    for (std::size_t slot = 0; slot < bar.buttons.size(); ++slot) {
        const std::string& button = bar.buttons.at(slot);
        // tmpItem được lấy một lần: ô đã trống vẫn bị so tiếp với các hành động còn lại của gói.
        const std::int32_t held = bar.widgets.action_item(button);
        if (held == kEmptyAction) continue;
        for (std::int64_t at = first; at <= last; ++at) {
            const std::int32_t id = mood_list(facts.chat, pack.kind)[static_cast<std::size_t>(at)];
            if (id == 0 || id != held) continue;
            bar.widgets.set_action(button, ActionFace{.id = kEmptyAction, .icon = {}});
            calls.push_back(Call{.ask = Ask::kUninstallChatActionBarItem,
                .text = std::format("{}", spec.first_id + static_cast<std::int32_t>(slot) - 1)});
        }
    }
}

// <Tên>_UnInstallChatActionButton(arg0).
void uninstall_chat_action(ActionBar& bar, const UiEvent& event, const BarFacts& facts, std::vector<Call>& calls) {
    const std::optional<double> index = to_number(event.arg(0));
    if (!index || *index < 0.0 || *index > kLastChatPack) return;
    unlink_pack(bar, *index, facts, calls);
    calls.push_back(Call{.ask = Ask::kUninstallChatAction,
        .text = std::format("{}\t{}", number_text(*index), bar.spec->uninstall_level)});
}

// CLEAR_CHAT_ACTION_BAR(arg0 = tên thanh, arg1 = ô gói, arg2 = id, arg3 = dữ liệu): <Tên>_ClearChatActionButton.
// Thanh nào không phải arg0 bỏ qua. Dọn xong chuyển tiếp cho thanh kế, hay ghi vào kho nếu là thanh cuối.
void clear_chat_action(ActionBar& bar, const UiEvent& event, const BarFacts& facts, std::vector<Call>& calls) {
    if (event.arg(0) != bar.spec->name) return;
    const std::optional<double> index = to_number(event.arg(1));
    const std::optional<double> id = to_number(event.arg(2));
    const std::optional<double> data = to_number(event.arg(3));
    if (!index || *index < 0.0 || *index > kLastChatPack) return;
    unlink_pack(bar, *index, facts, calls);
    // DataPool nhận đối số sai kiểu thì dừng script với lỗi (tThrowStringException).
    if (!id || !data) return;
    const std::string numbers = std::format("{}\t{}\t{}", number_text(*index), number_text(*id), number_text(*data));
    if (bar.spec->forward.empty()) {
        calls.push_back(Call{.ask = Ask::kSetChatAction, .text = numbers});
    } else {
        calls.push_back(Call{.ask = Ask::kClearChatActionBar, .text = std::format("{}\t{}", bar.spec->forward, numbers)});
    }
}

} // namespace

ActionBar make_action_bar(const BarSpec& spec) {
    ActionBar bar;
    bar.spec = &spec;
    bar.root = std::format("{}_Frame", spec.name);
    for (std::int32_t number = 1; number <= spec.count; ++number) {
        bar.buttons.push_back(std::format("{}_Button_Action{}", spec.name, number));
        bar.juniors.push_back(std::format("{}{}{}{}", spec.name, spec.flash_infix, number, kJuniorTail));
        bar.seniors.push_back(std::format("{}{}{}{}", spec.name, spec.flash_infix, number, kSeniorTail));
        bar.widgets.seed_hidden(bar.juniors.back());
        bar.widgets.seed_hidden(bar.seniors.back());
    }
    return bar;
}

bool on_bar_event(ActionBar& bar, const UiEvent& event, const BarFacts& facts, std::vector<Call>& calls) {
    if (event.name == "CHANGE_BAR") {
        change_bar(bar, event, facts, calls);
    } else if (event.name == "ACTION_UPDATE") {
        refresh_flashes(bar);
    } else if (event.name == bar.spec->uninstall_event) {
        uninstall_chat_action(bar, event, facts, calls);
    } else if (event.name == "CLEAR_CHAT_ACTION_BAR") {
        clear_chat_action(bar, event, facts, calls);
    } else if (event.name == "FLASH_COMBOSKILL") {
        combo_flash(bar, event);
    } else if (event.name == "HIDE_THIS_UI") {
        bar.is_shown = !bar.is_shown;
    } else {
        return false;
    }
    return true;
}

void press_bar_button(const ActionBar& bar, std::int32_t id, bool can_do, std::vector<Call>& calls) {
    const std::optional<std::size_t> slot = slot_of(*bar.spec, id);
    if (!slot) return;
    if (!can_do) {
        calls.push_back(Call{.ask = Ask::kPushDebugMessage, .text = std::string(kCannotDo)});
        return;
    }
    const std::string& button = bar.buttons.at(*slot);
    // ActionButton:DoAction (UI_CEGUI 0x180028c00): ô trống thì không làm gì.
    const std::int32_t action = bar.widgets.action_item(button);
    if (action == kEmptyAction) return;
    calls.push_back(Call{.ask = Ask::kDoAction, .text = std::format("{}\t{}", button, action)});
}

std::optional<std::int32_t> bar_button_id(const ActionBar& bar, std::string_view window) noexcept {
    const auto found = std::ranges::find(bar.buttons, window);
    if (found == bar.buttons.end()) return std::nullopt;
    return bar.spec->first_id + static_cast<std::int32_t>(found - bar.buttons.begin());
}

void paint_action_bar(Deck& deck, const ActionBar& bar) {
    if (!bar.is_shown) return;
    deck.show(bar.root);
    bar.widgets.paint(deck);
}

} // namespace game::ui::panel
