#include "ui/panel/softkey.hpp"

#include "gui/softkey.hpp"
#include "ui/panel/deck.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>

namespace game::ui::panel {
namespace {

constexpr std::string_view kRoot = "SoftKeyBoard_Back";
// Hai nhãn chữ con của cửa sổ phím, nằm đè lên phím xoá lùi và Shift (MouseHollow False).
constexpr std::array<std::string_view, 2> kFaceLabels = {"SoftKeyBoard_SoftKey_Text", "SoftKeyBoard_SoftKey_Text1"};

// Thuộc tính riêng của bản viết lại mang ký tự của 68 ô ký tự (gui/softkey.hpp).
constexpr Key kFacesKey{.window = kSoftKeysWindow, .name = "Keys"};

constexpr char32_t kBackspace = U'\b';

// Một nhóm phím ký tự: các ô của nó, dải ký tự khi không Shift và khi Shift (initialise của bản
// gốc: số 48..57, chữ thường 97..122, chữ hoa 65..90, dấu 33..47 rồi 58..64, 91..96, 123..126), và
// ô bắt đầu của nhóm trong SoftKeyStarts.
struct Bank {
    gui::SoftKeySpan cells;
    std::string_view plain;
    std::string_view shifted;
    std::uint8_t SoftKeyStarts::* start = nullptr;
};

constexpr std::string_view kDigits = "0123456789";
constexpr std::string_view kLower = "abcdefghijklmnopqrstuvwxyz";
constexpr std::string_view kUpper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
constexpr std::string_view kMarks = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~";

constexpr std::array<Bank, 3> kBanks = {{
    {.cells = gui::kSoftNumbers, .plain = kDigits, .shifted = kDigits, .start = &SoftKeyStarts::numbers},
    {.cells = gui::kSoftLetters, .plain = kLower, .shifted = kUpper, .start = &SoftKeyStarts::letters},
    {.cells = gui::kSoftMarks, .plain = kMarks, .shifted = kMarks, .start = &SoftKeyStarts::marks},
}};

static_assert(kDigits.size() == gui::kSoftNumbers.count && kMarks.size() == gui::kSoftMarks.count);
static_assert(kLower.size() == gui::kSoftLetters.count && kUpper.size() == gui::kSoftLetters.count);

// Một bước xorshift32 (Marsaglia 2003): trạng thái khác 0 thì không bao giờ về 0.
[[nodiscard]] std::uint32_t roll(std::uint32_t& dice) noexcept {
    dice ^= dice << 13U;
    dice ^= dice >> 17U;
    dice ^= dice << 5U;
    return dice;
}

// ResetAllKey: mỗi nhóm ký tự lấy một ô bắt đầu ngẫu nhiên mới.
void shuffle(SoftKeys& keys) noexcept {
    for (const Bank& bank : kBanks) {
        keys.starts.*bank.start = static_cast<std::uint8_t>(roll(keys.dice) % bank.cells.count);
    }
}

// Ký tự đang nằm ở ô thứ ordinal của nhóm bank.
[[nodiscard]] char face_of(const SoftKeys& keys, const Bank& bank, std::size_t ordinal) noexcept {
    const std::string_view alphabet = keys.is_shifted ? bank.shifted : bank.plain;
    const std::size_t start = keys.starts.*bank.start;
    return alphabet[(ordinal + start) % alphabet.size()];
}

void append_faces(std::string& faces, const SoftKeys& keys, const Bank& bank) {
    for (std::size_t ordinal = 0; ordinal < bank.cells.count; ++ordinal) {
        faces.push_back(face_of(keys, bank, ordinal));
    }
}

} // namespace

void open_soft_keys(SoftKeys& keys, std::uint32_t salt) noexcept {
    keys.is_open = true;
    keys.dice = (keys.dice ^ salt) | 1U;
    shuffle(keys);
}

void close_soft_keys(SoftKeys& keys) noexcept {
    keys.is_open = false;
}

bool is_soft_key_face(std::string_view window) noexcept {
    return window == kSoftKeysWindow || std::ranges::contains(kFaceLabels, window);
}

std::optional<char32_t> strike_soft_key(SoftKeys& keys, std::size_t cell) noexcept {
    if (!keys.is_open) return std::nullopt;
    if (gui::holds(gui::kSoftBack, cell)) return kBackspace;
    const bool is_shift = gui::holds(gui::kSoftShift, cell);
    if (is_shift) keys.is_shifted = !keys.is_shifted;
    if (is_shift) shuffle(keys);
    const auto owns = [cell](const Bank& bank) { return gui::holds(bank.cells, cell); };
    const auto bank = std::ranges::find_if(kBanks, owns);
    if (bank == kBanks.end()) return std::nullopt;
    const char face = face_of(keys, *bank, cell - bank->cells.first);
    shuffle(keys);
    return static_cast<char32_t>(static_cast<unsigned char>(face));
}

void paint_soft_keys(Deck& deck, const SoftKeys& keys) {
    if (!keys.is_open) return;
    deck.show(kRoot);
    std::string& faces = deck.compose(kFacesKey);
    for (const Bank& bank : kBanks) {
        append_faces(faces, keys, bank);
    }
}

} // namespace game::ui::panel
