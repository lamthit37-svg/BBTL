// Bàn phím ảo (ui/panel/softkey): mở, đóng, ký tự của từng ô phím theo ô bắt đầu và Shift, và việc
// của từng loại phím phải đúng như FalagardSoftKeyBoard của CEGUIFalagard.dll bản 2026; mọi tên cửa
// sổ bảng nêu phải có thật trong layout của client 2026.
#include "ui/panel/softkey.hpp"

#include "core/check.hpp"
#include "gui/asset.hpp"
#include "gui/loader.hpp"
#include "gui/sheet.hpp"
#include "gui/softkey.hpp"
#include "test.hpp"
#include "ui/panel/deck.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <functional>
#include <optional>
#include <string>
#include <string_view>

namespace game::test {
namespace {

using ui::panel::Deck;
using ui::panel::SoftKeys;

// Thư mục dữ liệu client mà bản dựng biết; rỗng thì ca đối chiếu layout thật tự bỏ qua.
#ifdef GAME_CLIENT_DATA
constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
constexpr std::string_view kClientData;
#endif

constexpr std::string_view kRoot = "SoftKeyBoard_Back";
constexpr std::string_view kCloseButton = "SoftKeyBoard_SoftKey_Close";
constexpr std::array<std::string_view, 2> kLabels = {"SoftKeyBoard_SoftKey_Text", "SoftKeyBoard_SoftKey_Text1"};

// Bốn dải ký tự của initialise: số, chữ thường, chữ hoa, và dấu (33..47, 58..64, 91..96, 123..126).
constexpr std::string_view kDigits = "0123456789";
constexpr std::string_view kLower = "abcdefghijklmnopqrstuvwxyz";
constexpr std::string_view kUpper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
constexpr std::string_view kMarks = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~";

constexpr std::size_t kFirstBack = gui::kSoftBack.first;
constexpr std::size_t kFirstShift = gui::kSoftShift.first;
constexpr std::size_t kFirstReturn = gui::kSoftReturn.first;

SoftKeys opened(std::uint32_t salt) {
    SoftKeys keys;
    ui::panel::toggle_soft_keys(keys, salt);
    return keys;
}

// Ký tự của 68 ô theo chỉ thị "Keys" của khung này; rỗng khi bảng không ghi.
std::string faces_of(const SoftKeys& keys) {
    Deck deck;
    ui::panel::paint_soft_keys(deck, keys);
    const auto is_faces = [](const gui::Override& item) { return item.name == "Keys"; };
    const auto overrides = deck.overrides();
    const auto found = std::ranges::find_if(overrides, is_faces);
    return found == overrides.end() ? std::string{} : std::string(found->value);
}

// Dải ký tự alphabet sau khi xoay vòng cho ô đầu mang ký tự thứ start.
std::string turned(std::string_view alphabet, std::size_t start) {
    std::string out(alphabet);
    std::ranges::rotate(out, out.begin() + static_cast<std::ptrdiff_t>(start));
    return out;
}

// Chuỗi "Keys" phải có với ba ô bắt đầu starts: nhóm số, nhóm chữ (dải letters), nhóm dấu.
std::string expected_faces(const ui::panel::SoftKeyStarts& starts, std::string_view letters) {
    return turned(kDigits, starts.numbers) + turned(letters, starts.letters) + turned(kMarks, starts.marks);
}

void toggle_opens_then_closes(Context& context) {
    SoftKeys keys;
    Deck closed;
    ui::panel::paint_soft_keys(closed, keys);
    context.expect(closed.roots().empty() && closed.overrides().empty(), "đang đóng thì không ghi chỉ thị nào");
    ui::panel::toggle_soft_keys(keys, 7);
    context.expect(keys.is_open, "ToggleWindow lúc đang đóng thì mở");
    Deck deck;
    ui::panel::paint_soft_keys(deck, keys);
    context.expect(deck.is_shown(kRoot), "đang mở thì kê gốc của bàn phím");
    context.expect(faces_of(keys).size() == gui::kSoftCharCells, "mỗi ô ký tự có đúng một ký tự");
    ui::panel::toggle_soft_keys(keys, 7);
    context.expect(!keys.is_open, "ToggleWindow lúc đang mở thì đóng");
}

void close_button_closes(Context& context) {
    SoftKeys keys = opened(1);
    keys.is_shifted = true;
    ui::panel::press_soft_keys(keys, "LogOn_Frame");
    context.expect(keys.is_open, "nhấn cửa sổ khác thì bàn phím còn mở");
    ui::panel::press_soft_keys(keys, kCloseButton);
    context.expect(!keys.is_open, "nút đóng gọi this:Hide()");
    context.expect(keys.is_shifted, "đóng không đổi Shift");
    ui::panel::toggle_soft_keys(keys, 1);
    ui::panel::close_soft_keys(keys);
    context.expect(!keys.is_open, "CloseWindow đóng bàn phím");
}

// ResetAllKey: ô thứ i của nhóm mang ký tự thứ (i + nStart) của nhóm, quay vòng.
void faces_follow_the_starts(Context& context) {
    SoftKeys keys = opened(1);
    keys.starts = {.numbers = 3, .letters = 1, .marks = 31};
    const std::string faces = faces_of(keys);
    context.expect(faces == expected_faces(keys.starts, kLower), "mỗi nhóm xoay vòng từ ô bắt đầu của nó");
    context.expect(faces.starts_with("3456789012"), "phím số bắt đầu từ 3, hết 9 thì về 0");
    context.expect(faces.substr(10, 26) == "bcdefghijklmnopqrstuvwxyza", "phím chữ bắt đầu từ b, ô cuối là a");
    context.expect(faces.at(36) == '~' && faces.at(37) == '!', "phím dấu bắt đầu từ dấu ngã rồi về chấm than");
    keys.is_shifted = true;
    context.expect(faces_of(keys) == expected_faces(keys.starts, kUpper), "Shift chỉ đổi phím chữ sang chữ hoa");
}

// Mỗi lần mở, ô bắt đầu của ba nhóm nằm trong nhóm và ba nhóm đều là phép xoay vòng, dù muối nào.
void every_opening_is_a_rotation(Context& context) {
    for (std::uint32_t salt = 0; salt < 64; ++salt) {
        const SoftKeys keys = opened(salt * 2654435761U);
        const bool is_in_range = keys.starts.numbers < 10 && keys.starts.letters < 26 && keys.starts.marks < 32;
        context.expect(is_in_range, "ô bắt đầu nằm trong nhóm của nó");
        context.expect(faces_of(keys) == expected_faces(keys.starts, kLower), "ba nhóm đều là phép xoay vòng");
        context.expect(keys.dice != 0, "bộ sinh không bao giờ về 0");
    }
}

void salts_change_the_layout(Context& context) {
    std::array<bool, 10> seen{};
    for (std::uint32_t salt = 0; salt < 200; ++salt) {
        const SoftKeys keys = opened(salt);
        seen.at(keys.starts.numbers) = true;
    }
    const bool is_all_seen = std::ranges::all_of(seen, std::identity{});
    context.expect(is_all_seen, "muối khác nhau cho đủ mười ô bắt đầu");
}

// onMouseButtonUp, phím ký tự: gõ ký tự đang ở ô đó rồi ResetAllKey.
void char_key_types_its_face_then_reshuffles(Context& context) {
    SoftKeys keys = opened(5);
    const std::string before = faces_of(keys);
    const std::uint32_t dice = keys.dice;
    const std::optional<char32_t> digit = ui::panel::strike_soft_key(keys, 4);
    context.expect(digit == static_cast<char32_t>(before.at(4)), "phím số gõ ký tự đang ở ô của nó");
    context.expect(keys.dice != dice, "gõ xong thì xoay vòng lại các phím");
    const std::string next = faces_of(keys);
    const std::optional<char32_t> mark = ui::panel::strike_soft_key(keys, 67);
    context.expect(mark == static_cast<char32_t>(next.at(67)), "phím dấu cuối gõ ký tự đang ở ô của nó");
    keys.is_shifted = true;
    const std::string upper = faces_of(keys);
    const std::optional<char32_t> letter = ui::panel::strike_soft_key(keys, 10);
    context.expect(letter == static_cast<char32_t>(upper.at(10)), "đang Shift thì phím chữ gõ chữ hoa");
}

void shift_flips_case_and_reshuffles(Context& context) {
    SoftKeys keys = opened(5);
    const std::uint32_t dice = keys.dice;
    const std::optional<char32_t> typed = ui::panel::strike_soft_key(keys, kFirstShift);
    context.expect(!typed, "Shift không gõ ký tự nào");
    context.expect(keys.is_shifted, "Shift bật chữ hoa");
    context.expect(keys.dice != dice, "Shift xoay vòng lại các phím");
    const std::optional<char32_t> again = ui::panel::strike_soft_key(keys, kFirstShift + 1);
    context.expect(!again && !keys.is_shifted, "ô thứ hai của Shift tắt chữ hoa");
}

void back_types_backspace_and_return_does_nothing(Context& context) {
    SoftKeys keys = opened(5);
    const SoftKeys before = keys;
    context.expect(ui::panel::strike_soft_key(keys, kFirstBack) == U'\b', "ô đầu của phím xoá lùi");
    context.expect(ui::panel::strike_soft_key(keys, kFirstBack + 1) == U'\b', "ô thứ hai của phím xoá lùi");
    context.expect(!ui::panel::strike_soft_key(keys, kFirstReturn), "Return không gõ gì");
    context.expect(!ui::panel::strike_soft_key(keys, kFirstReturn + 2), "ô cuối của Return không gõ gì");
    context.expect(!ui::panel::strike_soft_key(keys, gui::kSoftCells), "ô ngoài bàn phím không gõ gì");
    const bool is_same = keys.dice == before.dice && keys.is_shifted == before.is_shifted && keys.is_open;
    context.expect(is_same, "xoá lùi, Return và ô lạ không xoay vòng, không đổi Shift");
}

void closed_board_ignores_keys(Context& context) {
    SoftKeys keys;
    const std::uint32_t dice = keys.dice;
    context.expect(!ui::panel::strike_soft_key(keys, 3), "đang đóng thì phím số không gõ gì");
    context.expect(!ui::panel::strike_soft_key(keys, kFirstBack), "đang đóng thì xoá lùi không gõ gì");
    context.expect(!ui::panel::strike_soft_key(keys, kFirstShift), "đang đóng thì Shift không gõ gì");
    context.expect(!keys.is_shifted && keys.dice == dice, "đang đóng thì không đổi trạng thái");
}

void faces_are_the_key_window_and_its_labels(Context& context) {
    context.expect(ui::panel::is_soft_key_face(ui::panel::kSoftKeysWindow), "cửa sổ phím là mặt phím");
    context.expect(std::ranges::all_of(kLabels, ui::panel::is_soft_key_face), "hai nhãn đè lên phím là mặt phím");
    context.expect(!ui::panel::is_soft_key_face(kRoot), "khung bàn phím không phải mặt phím");
    context.expect(!ui::panel::is_soft_key_face(kCloseButton), "nút đóng không phải mặt phím");
}

bool has_window(const gui::GuiAsset& asset, std::string_view name) {
    const auto is_named = [name](const gui::GuiWindow& window) { return window.name == name; };
    return std::ranges::any_of(asset.windows, is_named);
}

// Gõ sai một tên cửa sổ thì chỉ thị hay lần nhấn đó mất mà không báo gì.
void names_exist_in_layout(Context& context) {
    if (kClientData.empty()) return;
    const std::filesystem::path root = std::filesystem::path(kClientData) / "Interface";
    const gui::DiskSource files(root);
    gui::GuiSources sources;
    sources.files = &files;
    auto loader = gui::GuiLoader::open(sources);
    context.expect(loader.has_value(), "mở được giao diện của kho");
    if (!loader) return;
    const auto added = loader->add_layout(ui::panel::kSoftKeysLayout);
    context.expect(added.has_value(), "nạp được layout bàn phím ảo");
    const gui::GuiAsset& asset = loader->asset();
    context.expect(has_window(asset, kRoot), kRoot);
    context.expect(has_window(asset, ui::panel::kSoftKeysWindow), ui::panel::kSoftKeysWindow);
    context.expect(has_window(asset, kCloseButton), kCloseButton);
    for (const std::string_view label : kLabels) {
        context.expect(has_window(asset, label), label);
    }
}

constexpr std::array kCases{
    Case{.name = "toggle_opens_then_closes", .body = &toggle_opens_then_closes},
    Case{.name = "close_button_closes", .body = &close_button_closes},
    Case{.name = "faces_follow_the_starts", .body = &faces_follow_the_starts},
    Case{.name = "every_opening_is_a_rotation", .body = &every_opening_is_a_rotation},
    Case{.name = "salts_change_the_layout", .body = &salts_change_the_layout},
    Case{.name = "char_key_types_its_face_then_reshuffles", .body = &char_key_types_its_face_then_reshuffles},
    Case{.name = "shift_flips_case_and_reshuffles", .body = &shift_flips_case_and_reshuffles},
    Case{.name = "back_types_backspace_and_return_does_nothing", .body = &back_types_backspace_and_return_does_nothing},
    Case{.name = "closed_board_ignores_keys", .body = &closed_board_ignores_keys},
    Case{.name = "faces_are_the_key_window_and_its_labels", .body = &faces_are_the_key_window_and_its_labels},
    Case{.name = "names_exist_in_layout", .body = &names_exist_in_layout},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_softkey_tests: mọi ca phải qua");
    return 0;
}
