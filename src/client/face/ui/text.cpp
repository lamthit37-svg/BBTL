#include "ui/text.hpp"

#include "core/text.hpp"
#include "gui/sheet.hpp"
#include "gui/strings.hpp"
#include "render/ui.hpp"
#include "resource/image.hpp"
#include "ui/pace.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <format>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui {

// Ô chữ, bút và màu. Nằm ngoài namespace ẩn: chữ ký của Typesetter dùng chúng, mà lớp đó là bạn
// của TextWriter nên phải có liên kết ngoài.
struct Area {
    float top = 0.0F;
    float bottom = 0.0F;
    float left = 0.0F;
    float right = 0.0F;
};

struct Corner {
    float x = 0.0F;
    float y = 0.0F;
};

struct Tint {
    std::uint32_t top = 0;
    std::uint32_t bottom = 0;
};

struct Stamp {
    float left = 0.0F;
    float top = 0.0F;
    float size = 0.0F;
    const GlyphCell* cell = nullptr;
    Tint tint;
};

namespace {

constexpr std::uint32_t kAlphaMask = 0xFF000000U;
constexpr std::uint32_t kRgbMask = 0x00FFFFFFU;

// Mã điều khiển của chuỗi đã đọc thẻ: bộ phân tích UI_CEGUI.dll 0x18004b170 sinh, drawTextLine
// CEGUIBase.dll 0x18004b250 đọc qua bảng nhảy 0x18004ced0 (byte cao trừ 0xD0).
constexpr Code kKindMask = 0xFF000000U;
constexpr Code kParamMask = 0x00FFFFFFU;
constexpr Code kGradient = 0xD0000000U;
constexpr Code kBlinkOn = 0xE0000000U;
constexpr Code kBlinkOff = 0xE1000000U;
constexpr Code kAlpha = 0xE2000000U;
constexpr Code kMotion = 0xE3000000U;
constexpr Code kUnderlineOn = 0xE6000000U;
constexpr Code kUnderlineOff = 0xE7000000U;
constexpr Code kLinkColour = 0xE8000000U;
constexpr Code kEffect = 0xE9000000U;
constexpr Code kFace = 0xFA000000U;
constexpr Code kColour = 0xFB000000U;
constexpr Code kEdge = 0xFC000000U;
constexpr Code kLinkOn = 0xFD000000U;
constexpr Code kLinkOff = 0xFE000000U;
// Tham số lớn hơn FF của mã alpha là "thôi ép alpha"; bộ phân tích sinh đúng số này ở cuối chuỗi.
constexpr Code kAlphaOff = kAlpha | 0x00FF0000U;
// Màu liên kết quanh #{_INFOMAP...} (UI_CEGUI.dll 0x18004e80f, 0x18004e82d); 00CCFF cũng là màu
// drawTextLine tự đặt khi chưa mã nào đặt màu liên kết (CEGUIBase.dll 0x18004b80c).
constexpr Code kMapLink = kLinkColour | 0x000099E5U;
constexpr Code kPlainLink = kLinkColour | 0x0000CCFFU;
constexpr std::uint32_t kDefaultLink = 0xFF00CCFFU;
constexpr Code kWhiteMark = kColour | 0x00FFFFFFU;

// Trần của một lần scan_markup. Khác gốc: bản gốc đệ quy và nối chuỗi không trần.
constexpr std::size_t kMaxDepth = 4;
constexpr std::size_t kMaxCodes = 16384;
constexpr std::size_t kMaxLookups = 256;

// Hằng của Font (CEGUIBase.dll .rdata 0x1801e7354, 0x1801e7358) và của phép bẻ dòng (0x1801e7368,
// 0x1801e737c).
constexpr float kLineSpace = 3.0F;
constexpr float kGlyphPad = 2.0F;
constexpr std::size_t kLookBack = 12;
constexpr std::array<Code, 5> kBreakers = {U' ', U',', U'.', U'?', U'!'};
// Bước dời của phông bitmap trong drawText (0x18004aacb) và độ lệch của ô bitmap trong ô glyph.
constexpr float kBitmapShift = 1.0F;
constexpr float kBitmapDrop = 1.0F;
constexpr float kHalf = 0.5F;
constexpr float kCaretWidth = 1.0F;
// GuiTextHorz: 0 trái, 1 phải, 2 giữa, 3 justified; cộng 4 là cùng kiểu có bẻ dòng.
constexpr std::uint8_t kRightAligned = 1;
constexpr std::uint8_t kCentreAligned = 2;
constexpr std::uint8_t kJustified = 3;
constexpr std::uint8_t kWrapFirst = 4;
constexpr std::uint8_t kWrapLast = 7;
constexpr std::uint8_t kVertCentre = 1;
constexpr std::uint8_t kVertBottom = 2;

struct ColourKey {
    char key = '\0';
    Code mark = 0;
};

// Mười hai thẻ màu một chữ cái của bản 2026 (0x18004b4d5..0x18004b932).
constexpr std::array<ColourKey, 12> kColourKeys = {{
    {.key = 'R', .mark = 0xFBFFC0CBU},
    {.key = 'G', .mark = 0xFB00FF00U},
    {.key = 'B', .mark = 0xFB00B4FFU},
    {.key = 'K', .mark = 0xFB000000U},
    {.key = 'P', .mark = 0xFBFF99CCU},
    {.key = 'H', .mark = 0xFB00FFFFU},
    {.key = 'I', .mark = 0xFBFFFFCCU},
    {.key = 'Y', .mark = 0xFBFFFF00U},
    {.key = 'W', .mark = 0xFBFFFFFFU},
    {.key = 'L', .mark = 0xFB6A3906U},
    {.key = 'M', .mark = 0xFB1F941EU},
    {.key = 'N', .mark = 0xFBE4007FU},
}};

// Đọc thẻ

[[nodiscard]] constexpr bool is_space(char letter) noexcept {
    return letter == ' ' || (letter >= '\t' && letter <= '\r');
}

[[nodiscard]] constexpr bool is_digit(char letter) noexcept {
    return letter >= '0' && letter <= '9';
}

[[nodiscard]] constexpr std::optional<std::uint32_t> hex_digit(char letter) noexcept {
    if (is_digit(letter)) return static_cast<std::uint32_t>(letter - '0');
    if (letter >= 'a' && letter <= 'f') return static_cast<std::uint32_t>(letter - 'a') + 10U;
    if (letter >= 'A' && letter <= 'F') return static_cast<std::uint32_t>(letter - 'A') + 10U;
    return std::nullopt;
}

// sscanf(" %6X") và sscanf(" %2X") của bản gốc trên một trường đã cắt đúng bề rộng: bỏ khoảng trắng
// đầu, nhận một dấu và tiền tố 0x, đọc chữ số hex tới ký tự lạ; không chữ số nào thì 0.
[[nodiscard]] constexpr std::uint32_t scan_hex(std::string_view field) noexcept {
    while (!field.empty() && is_space(field.front()))
        field.remove_prefix(1);
    const bool is_negative = field.starts_with('-');
    if (is_negative || field.starts_with('+')) field.remove_prefix(1);
    if (field.starts_with("0x") || field.starts_with("0X")) field.remove_prefix(2);
    std::uint32_t value = 0;
    for (const char letter : field) {
        const std::optional<std::uint32_t> digit = hex_digit(letter);
        if (!digit) break;
        value = (value << 4U) | *digit;
    }
    return is_negative ? 0U - value : value;
}
static_assert(scan_hex("00FF00") == 0x00FF00U && scan_hex("FFxyzw") == 0xFFU && scan_hex("ZZZZZZ") == 0U);
static_assert(scan_hex(" 12345") == 0x12345U && scan_hex("0x12AB") == 0x12ABU && scan_hex("-1") == 0xFFFFFFFFU);
static_assert(scan_hex("") == 0U && scan_hex("12") == 0x12U && scan_hex("0x") == 0U);

// Số thập phân của một dãy đã kiểm là toàn chữ số, dài tối đa bốn.
[[nodiscard]] constexpr std::uint32_t decimal(std::string_view digits) noexcept {
    std::uint32_t value = 0;
    for (const char letter : digits)
        value = (value * 10U) + static_cast<std::uint32_t>(letter - '0');
    return value;
}

// %d của sscanf ở đầu rest: bỏ khoảng trắng, nhận một dấu rồi chữ số; số quá lớn quấn 32 bit như
// MSVCR110. Không có chữ số thì nullopt.
[[nodiscard]] constexpr std::optional<std::int32_t> take_int(std::string_view& rest) noexcept {
    while (!rest.empty() && is_space(rest.front()))
        rest.remove_prefix(1);
    const bool is_negative = rest.starts_with('-');
    if (is_negative || rest.starts_with('+')) rest.remove_prefix(1);
    if (rest.empty() || !is_digit(rest.front())) return std::nullopt;
    std::uint32_t value = 0;
    for (; !rest.empty() && is_digit(rest.front()); rest.remove_prefix(1)) {
        value = (value * 10U) + static_cast<std::uint32_t>(rest.front() - '0');
    }
    return static_cast<std::int32_t>(is_negative ? 0U - value : value);
}

[[nodiscard]] constexpr bool take_comma(std::string_view& rest) noexcept {
    if (!rest.starts_with(',')) return false;
    rest.remove_prefix(1);
    return true;
}

// Toạ độ, cảnh và tên của #{_INFOAIMx,z,cảnh,tên}, đọc như sscanf("%d,%d,%d,%s").
struct Aim {
    std::int32_t across = 0;
    std::int32_t down = 0;
    std::int32_t scene = 0;
    std::string_view name;
};

// %s của sscanf: bỏ khoảng trắng rồi lấy tới khoảng trắng kế (tên có dấu cách chỉ còn từ đầu).
[[nodiscard]] constexpr std::string_view take_word(std::string_view rest) noexcept {
    while (!rest.empty() && is_space(rest.front()))
        rest.remove_prefix(1);
    const auto stop = std::ranges::find_if(rest, is_space);
    return rest.substr(0, static_cast<std::size_t>(stop - rest.begin()));
}

// Khác gốc: thiếu một trong ba số thì bỏ thẻ; bản gốc không kiểm kết quả sscanf và dùng số chưa
// khởi tạo.
[[nodiscard]] constexpr std::optional<Aim> parse_aim(std::string_view fields) noexcept {
    const std::optional<std::int32_t> across = take_int(fields);
    if (!across || !take_comma(fields)) return std::nullopt;
    const std::optional<std::int32_t> down = take_int(fields);
    if (!down || !take_comma(fields)) return std::nullopt;
    const std::optional<std::int32_t> scene = take_int(fields);
    if (!scene) return std::nullopt;
    const std::string_view name = take_comma(fields) ? take_word(fields) : std::string_view{};
    return Aim{.across = *across, .down = *down, .scene = *scene, .name = name};
}
static_assert(parse_aim("160,157,2,Ai đó").value_or(Aim{}).name == "Ai");
static_assert(parse_aim("-1, 20,3,").value_or(Aim{}).down == 20 && !parse_aim("12,x").has_value());

// Một lần gọi bộ phân tích gốc: chuỗi đang đọc và trạng thái riêng của lần gọi đó (chuỗi tra từ
// #{ID} được đọc bằng một lần gọi mới, màu và cờ không mang sang).
struct Frame {
    // Chuỗi sinh tại chỗ (liên kết _INFOAIM, _INFOMAP); rỗng khi text mượn chuỗi nguồn hay bảng chuỗi.
    std::string own;
    std::string_view text;
    std::size_t at = 0;
    // Mã màu đang dùng và mã màu ngay trước lần đổi gần nhất, cho thẻ #l ([rsp+0x64], [rsp+0x70]).
    Code colour = kWhiteMark;
    Code colour_before = kWhiteMark;
    // Ba cờ quyết định mã tự đóng ở cuối chuỗi ([rbp+0x30], [rbp-0x20], [rbp-0x68]).
    bool is_blinking = false;
    bool has_alpha = false;
    bool is_underlined = false;
    // Mã chèn sau khi đọc xong chuỗi này; 0 là không.
    Code after = 0;
};

struct Scan {
    // frames[depth] đang đọc; các ô trước nó chờ chuỗi lồng đọc xong.
    std::array<Frame, kMaxDepth + 1> frames;
    std::size_t depth = 0;
    const gui::StringBook* strings = nullptr;
    std::vector<Code>* out = nullptr;
    // out không được dài quá số này.
    std::size_t limit = 0;
    std::size_t lookups_left = kMaxLookups;
};

[[nodiscard]] bool is_full(const Scan& scan) noexcept {
    return scan.out->size() >= scan.limit;
}

void push(const Scan& scan, Code code) {
    if (!is_full(scan)) scan.out->push_back(code);
}

void push_chars(const Scan& scan, std::string_view chunk) {
    while (!chunk.empty() && !is_full(scan)) {
        const core::Utf8Step step = core::utf8_step(chunk);
        scan.out->push_back(step.code);
        chunk.remove_prefix(step.length);
    }
}

void set_colour(const Scan& scan, Frame& frame, Code mark) {
    frame.colour_before = frame.colour;
    frame.colour = mark;
    push(scan, mark);
}

// Tối đa count byte của text kể từ start; start ở cuối chuỗi hay quá cuối thì rỗng.
struct Cut {
    std::size_t start = 0;
    std::size_t count = 0;
};

[[nodiscard]] constexpr std::string_view field_of(std::string_view text, Cut cut) noexcept {
    if (cut.start >= text.size()) return {};
    return text.substr(cut.start, cut.count);
}

// Mở một lượt đọc lồng. Quá kMaxDepth mức thì nullptr và thẻ bị bỏ.
[[nodiscard]] Frame* open_frame(Scan& scan) {
    if (scan.depth >= kMaxDepth) return nullptr;
    ++scan.depth;
    Frame& frame = scan.frames.at(scan.depth);
    frame = Frame{};
    return &frame;
}

// #{_INFOAIMx,z,cảnh,tên} và #{_INFOMAP...} (0x18004e446, 0x18004e64e): bộ phân tích sinh chuỗi
// "#aB{x,z,cảnh,0,tên}#u[x,z]#u#aE" rồi đọc chuỗi đó bằng một lần gọi mới; _INFOMAP bọc thêm màu
// liên kết 0099E5 và trả về 00CCFF. Phần {…} là khoá liên kết, lúc vẽ không hiện.
// Khác gốc: tên bằng "0" bản gốc viết thêm tên cảnh trước dấu [ (tra bảng cảnh của game, ở đây
// chưa có); chuỗi sinh không bị cắt ở 128 byte; tên không qua hàm lọc của game.
void expand_aim(Scan& scan, const Aim& aim, bool is_map) {
    Frame* frame = open_frame(scan);
    if (frame == nullptr) return;
    if (is_map) push(scan, kMapLink);
    // Tên trong #{_INFOAIM...,tên} là tham số chữ Hán. Bảng chuỗi có bản dịch nguyên văn thì vẽ bản đó.
    std::string_view shown = aim.name;
    if (scan.strings != nullptr) {
        const std::optional<std::string_view> literal = scan.strings->find_literal(aim.name);
        const std::optional<std::string_view> entry = literal ? std::nullopt : scan.strings->find(aim.name);
        if (literal) shown = *literal;
        if (entry) shown = *entry;
    }
    frame->own = std::format("#aB{{{},{},{},0,{}}}#u[{},{}]#u#aE", aim.across, aim.down, aim.scene, shown, aim.across,
        aim.down);
    frame->text = frame->own;
    frame->after = is_map ? kPlainLink : Code{0};
}

// Tra từ điển (0x18005388c): khoá là ID tới trước dấu * đầu tiên. Có thì đọc chuỗi tra được bằng
// một lần gọi mới; không có thì thẻ bị bỏ.
void expand_entry(Scan& scan, std::string_view id) {
    if (scan.strings == nullptr || scan.lookups_left == 0) return;
    --scan.lookups_left;
    const std::optional<std::string_view> found = scan.strings->find(id.substr(0, id.find('*')));
    if (!found) return;
    Frame* frame = open_frame(scan);
    if (frame != nullptr) frame->text = *found;
}

constexpr std::string_view kAimPrefix = "_INFOAIM";
constexpr std::string_view kMapPrefix = "_INFOMAP";

// #{ID} với open là vị trí dấu {. Thiếu dấu đóng thì bỏ "#{" và một ký tự sau nó (0x180053bdf).
[[nodiscard]] std::size_t take_id(Scan& scan, std::string_view text, std::size_t open) {
    const std::size_t close = text.find('}', open + 1);
    if (close == std::string_view::npos) return open + 2;
    const std::string_view id = text.substr(open + 1, close - open - 1);
    const bool is_map = id.starts_with(kMapPrefix);
    const bool is_aim = is_map || id.starts_with(kAimPrefix);
    const std::optional<Aim> aim = is_aim ? parse_aim(id.substr(kAimPrefix.size())) : std::nullopt;
    if (aim) {
        expand_aim(scan, *aim, is_map);
    } else {
        expand_entry(scan, id);
    }
    return close + 1;
}
static_assert(kAimPrefix.size() == kMapPrefix.size());

// #N, #NN, #NNN với first là vị trí chữ số đầu (0x180053cfd): đọc tham lam tối đa ba chữ số; số
// trong 1..100 hoặc 801..804 là biểu cảm, số khác thì chỉ mất dấu #.
[[nodiscard]] std::size_t take_face(const Scan& scan, std::string_view text, std::size_t first) {
    const std::string_view next = field_of(text, {.start = first + 1, .count = 2});
    const auto extra = static_cast<std::size_t>(std::ranges::find_if_not(next, is_digit) - next.begin());
    const std::uint32_t number = decimal(text.substr(first, 1 + extra));
    const bool is_face = (number >= 1 && number <= 100) || (number >= 801 && number <= 804);
    if (!is_face) return first;
    push(scan, kFace | number);
    return first + 1 + extra;
}

// #-NN với key là vị trí dấu - (0x180053c03): đúng hai chữ số và khác 01 là hoạt ảnh id âm.
[[nodiscard]] std::size_t take_motion(const Scan& scan, std::string_view text, std::size_t key) {
    const std::string_view pair = field_of(text, {.start = key + 1, .count = 2});
    const bool is_pair = pair.size() == 2 && std::ranges::all_of(pair, is_digit);
    if (!is_pair || decimal(pair) == 1) return key + 1;
    push(scan, kMotion | decimal(pair));
    return key + 3;
}

// #vNNNN với key là vị trí chữ v (0x180053e08): đủ bốn chữ số là hoạt ảnh, không thì chỉ mất dấu #.
// Khác gốc: bản gốc còn hỏi AnimateManager::isAnimatePresent, không có thì cũng chỉ mất dấu #.
[[nodiscard]] std::size_t take_named(const Scan& scan, std::string_view text, std::size_t key) {
    const std::string_view four = field_of(text, {.start = key + 1, .count = 4});
    if (four.size() != 4 || !std::ranges::all_of(four, is_digit)) return key;
    push(scan, kFace | decimal(four));
    return key + 5;
}

// #+NNNN với key là vị trí dấu + (0x180053ecd): bốn chữ số, chữ số đầu khác 0; sai dạng thì mất "#+".
[[nodiscard]] std::size_t take_effect(const Scan& scan, std::string_view text, std::size_t key) {
    const std::string_view four = field_of(text, {.start = key + 1, .count = 4});
    const bool is_effect = four.size() == 4 && std::ranges::all_of(four, is_digit) && four.front() != '0';
    if (!is_effect) return key + 1;
    push(scan, kEffect | decimal(four));
    return key + 5;
}

// Thẻ có sáu chữ số hex theo sau: #c màu chữ, #g gradient (cả hai ghi vào cặp màu của #l), #e viền.
[[nodiscard]] std::size_t take_hex(const Scan& scan, Frame& frame, std::size_t key) {
    const Code value = scan_hex(field_of(frame.text, {.start = key + 1, .count = 6})) & kParamMask;
    const char letter = frame.text[key];
    if (letter == 'e') {
        push(scan, kEdge | value);
    } else {
        set_colour(scan, frame, (letter == 'c' ? kColour : kGradient) | value);
    }
    return key + 7;
}

// ## là dấu #; ngay sau nó là { thì dấu # thứ hai còn mở thẻ #{ID} (0x18004bfe8).
[[nodiscard]] std::size_t take_hash(const Scan& scan, std::string_view text, std::size_t key) {
    push(scan, U'#');
    const bool is_id = key + 1 < text.size() && text[key + 1] == '{';
    return is_id ? key : key + 1;
}

// #aB mở liên kết, #aE đóng; chữ khác sau #a thì ba ký tự mất không (0x18004c07e).
[[nodiscard]] std::size_t take_link(const Scan& scan, std::string_view text, std::size_t key) {
    const std::string_view which = field_of(text, {.start = key + 1, .count = 1});
    if (which == "B") push(scan, kLinkOn);
    if (which == "E") push(scan, kLinkOff);
    return key + 2;
}

// #iHH: alpha ép cho màu chữ và viền (0x18004b9b5).
[[nodiscard]] std::size_t take_alpha(const Scan& scan, Frame& frame, std::size_t key) {
    push(scan, kAlpha | (scan_hex(field_of(frame.text, {.start = key + 1, .count = 2})) & 0xFFU));
    frame.has_alpha = true;
    return key + 3;
}

// #u bật rồi tắt gạch chân xen kẽ (0x18004bd83).
[[nodiscard]] std::size_t take_underline(const Scan& scan, Frame& frame, std::size_t key) {
    push(scan, frame.is_underlined ? kUnderlineOff : kUnderlineOn);
    frame.is_underlined = !frame.is_underlined;
    return key + 1;
}

// Thẻ không phải màu một chữ cái; key là vị trí ký tự ngay sau dấu # (bằng cỡ chuỗi khi dấu # đứng
// cuối). Trả vị trí đọc tiếp. Ký tự lạ thì chỉ mất dấu #, ký tự đó vẫn là chữ (0x180053f8e).
[[nodiscard]] std::size_t take_other(Scan& scan, Frame& frame, std::size_t key) {
    const std::string_view text = frame.text;
    const char letter = key < text.size() ? text[key] : '\0';
    if (is_digit(letter)) return take_face(scan, text, key);
    switch (letter) {
    case 'c':
    case 'g':
    case 'e': return take_hex(scan, frame, key);
    case 'i': return take_alpha(scan, frame, key);
    case 'u': return take_underline(scan, frame, key);
    case '#': return take_hash(scan, text, key);
    case 'a': return take_link(scan, text, key);
    case '{': return take_id(scan, text, key);
    case '-': return take_motion(scan, text, key);
    case 'v': return take_named(scan, text, key);
    case '+': return take_effect(scan, text, key);
    case 'b':
        push(scan, kBlinkOn);
        frame.is_blinking = true;
        return key + 1;
    // #l lặp lại mã màu trước lần đổi gần nhất; cặp màu không lùi thêm (0x18004bc5c).
    case 'l':
        frame.colour = frame.colour_before;
        push(scan, frame.colour);
        return key + 1;
    // #n tắt nháy và gạch chân nhưng không đụng màu, cũng không đụng cờ của #u (0x18004bdd9).
    case 'n':
        push(scan, kBlinkOff);
        push(scan, kUnderlineOff);
        return key + 1;
    case 'r': push(scan, U'\n'); return key + 1;
    default: return key;
    }
}

[[nodiscard]] std::size_t take_tag(Scan& scan, Frame& frame, std::size_t key) {
    const char letter = key < frame.text.size() ? frame.text[key] : '\0';
    const auto found = std::ranges::find(kColourKeys, letter, &ColourKey::key);
    if (found == kColourKeys.end()) return take_other(scan, frame, key);
    set_colour(scan, frame, found->mark);
    return key + 1;
}

// Chuỗi hết: mã tự đóng theo thứ tự của bản gốc (0x1800540f5), rồi mã của nơi mở lượt đọc này.
void close_frame(const Scan& scan, const Frame& frame) {
    if (frame.is_blinking) push(scan, kBlinkOff);
    if (frame.has_alpha) push(scan, kAlphaOff);
    if (frame.is_underlined) push(scan, kUnderlineOff);
    if (frame.after != 0) push(scan, frame.after);
}

// Chữ tới dấu # kế rồi một thẻ. Thẻ có thể mở lượt đọc lồng: lượt đó chạy trước khi frame đọc tiếp.
void scan_step(Scan& scan, Frame& frame) {
    const std::size_t hash = frame.text.find('#', frame.at);
    if (hash == std::string_view::npos) {
        push_chars(scan, frame.text.substr(frame.at));
        frame.at = frame.text.size();
        return;
    }
    push_chars(scan, frame.text.substr(frame.at, hash - frame.at));
    frame.at = take_tag(scan, frame, hash + 1);
}

void scan_all(Scan& scan) {
    while (!is_full(scan)) {
        Frame& frame = scan.frames.at(scan.depth);
        if (frame.at < frame.text.size()) {
            scan_step(scan, frame);
            continue;
        }
        close_frame(scan, frame);
        if (scan.depth == 0) return;
        --scan.depth;
    }
}

// Hình học

// Phép đổi float sang int tự viết của CEGUIBase.dll (ví dụ 0x18004ab33): cắt về 0, nên với toạ độ
// âm thì "cộng 0,5 rồi cắt" không còn là làm tròn xuống.
[[nodiscard]] float cut(float value) noexcept {
    return std::trunc(value);
}

// Đầu drawText (0x18004aadc): dời ô lên một điểm ảnh rồi đưa bốn mép về số nguyên.
[[nodiscard]] Area snapped(const Area& area) noexcept {
    Area whole;
    whole.top = cut((area.top - kBitmapShift) + kHalf);
    whole.bottom = cut((area.bottom - kBitmapShift) + kHalf);
    whole.left = cut(area.left + kHalf);
    whole.right = cut(area.right + kHalf);
    return whole;
}

// Vị trí bút: x là cột bitmap đầu của ký tự kế, y là mép trên ô glyph của dòng.
// Màu hai đỉnh trên và hai đỉnh dưới của một quad.

[[nodiscard]] constexpr Tint flat(std::uint32_t colour) noexcept {
    return {.top = colour, .bottom = colour};
}

// Trạng thái vẽ, là các biến toàn cục của CEGUIBase.dll (màu chữ 0x1802e9090, viền 0x1802e9050,
// gradient trên 0x1802e9038 và dưới 0x1802e9020, màu liên kết 0x1802e90a8, alpha ép 0x1802e9011 và
// 0x1802e9014, gạch chân 0x1802e9012, liên kết 0x1802e9008, trong khoá 0x1802e900c). Màu là ARGB.
// Khác gốc: mỗi lần write bắt đầu bằng trạng thái mới; bản gốc chỉ đặt lại màu chữ, viền và
// gradient, phần còn lại do mã tự đóng cuối chuỗi của bộ phân tích trả về.
struct Ink {
    std::uint32_t text = 0;
    std::uint32_t edge = 0;
    std::uint32_t top = 0;
    std::uint32_t bottom = 0;
    // 0 là chưa mã nào đặt: lúc dùng lấy kDefaultLink.
    std::uint32_t link = 0;
    // Alpha của màu dòng, đã ở byte cao; và alpha ép của #i khi đang bật.
    std::uint32_t base_alpha = kAlphaMask;
    std::optional<std::uint32_t> forced_alpha;
    bool is_underlined = false;
    bool in_link = false;
    bool in_key = false;
};

[[nodiscard]] constexpr std::uint32_t alpha_of(const Ink& ink) noexcept {
    return ink.forced_alpha.value_or(ink.base_alpha);
}

// Ba nibble thấp của bits thành R, G, B tám bit, mỗi nibble nhân 0x11 (0x18004cbd5).
[[nodiscard]] constexpr std::uint32_t wide_rgb(std::uint32_t bits) noexcept {
    return (((bits >> 8U) & 0xFU) * 0x110000U) | (((bits >> 4U) & 0xFU) * 0x1100U) | ((bits & 0xFU) * 0x11U);
}
static_assert(wide_rgb(0xFF0U) == 0xFFFF00U && wide_rgb(0xFA0U) == 0xFFAA00U);

// Màu ở tỉ lệ part trên đường từ from tới into, từng kênh, làm tròn gần nhất.
struct Mix {
    std::uint32_t from = 0;
    std::uint32_t into = 0;
};

[[nodiscard]] std::uint32_t mixed(Mix mix, float part) noexcept {
    std::uint32_t colour = 0;
    for (unsigned shift = 0; shift < 32U; shift += 8U) {
        const auto low = static_cast<float>((mix.from >> shift) & 0xFFU);
        const auto high = static_cast<float>((mix.into >> shift) & 0xFFU);
        const auto channel = static_cast<std::uint32_t>(low + ((high - low) * part) + kHalf);
        colour |= (channel & 0xFFU) << shift;
    }
    return colour;
}

// Một mã điều khiển đổi trạng thái vẽ (các nhánh của bảng nhảy 0x18004ced0). Nháy và hoạt ảnh
// không có nhánh: chưa vẽ.
void apply(Ink& ink, Code code) noexcept {
    const std::uint32_t param = code & kParamMask;
    switch (code & kKindMask) {
    case kColour: ink.text = alpha_of(ink) | param; break;
    // Màu viền mới xoá luôn gradient (0x18004cb60).
    case kEdge:
        ink.edge = alpha_of(ink) | param;
        ink.top = 0;
        ink.bottom = 0;
        break;
    case kGradient:
        ink.top = alpha_of(ink) | wide_rgb(param >> 12U);
        ink.bottom = alpha_of(ink) | wide_rgb(param);
        break;
    // Alpha ép đổi ngay màu chữ và màu viền đang dùng; gradient đã đặt thì giữ (0x18004cd12).
    case kAlpha:
        ink.forced_alpha = param > 0xFFU ? std::nullopt : std::optional<std::uint32_t>(param << 24U);
        ink.text = alpha_of(ink) | (ink.text & kRgbMask);
        ink.edge = alpha_of(ink) | (ink.edge & kRgbMask);
        break;
    case kLinkColour: ink.link = alpha_of(ink) | param; break;
    case kUnderlineOn: ink.is_underlined = true; break;
    case kUnderlineOff: ink.is_underlined = false; break;
    case kLinkOn: ink.in_link = true; break;
    case kLinkOff: ink.in_link = false; break;
    default: break;
    }
}

// Một cạnh của ô chữ sau khi cắt: toạ độ và toạ độ ảnh tương ứng.
struct Edge {
    float place = 0.0F;
    float texel = 0.0F;
};

// Đoạn [low, high] của ô chữ trên một trục.
struct Span {
    Edge low;
    Edge high;
};

// Khoảng của ô cắt trên một trục.
struct Limits {
    float low = 0.0F;
    float high = 0.0F;
};

// Cắt đoạn span vào limits, nội suy toạ độ ảnh theo. span dài khác 0.
[[nodiscard]] Span clip_span(Span span, Limits limits) noexcept {
    const float length = span.high.place - span.low.place;
    const float texels = span.high.texel - span.low.texel;
    const float start = std::max(span.low.place, limits.low);
    const float stop = std::min(span.high.place, limits.high);
    Span clipped;
    clipped.low.place = start;
    clipped.high.place = stop;
    clipped.low.texel = span.low.texel + (texels * (start - span.low.place) / length);
    clipped.high.texel = span.low.texel + (texels * (stop - span.low.place) / length);
    return clipped;
}

// Đoạn dài size bắt đầu ở start, trải từ toạ độ ảnh first tới last.
struct Stretch {
    float start = 0.0F;
    float size = 0.0F;
    float first = 0.0F;
    float last = 0.0F;
};

[[nodiscard]] Span span_of(const Stretch& stretch) noexcept {
    Span span;
    span.low = {.place = stretch.start, .texel = stretch.first};
    span.high = {.place = stretch.start + stretch.size, .texel = stretch.last};
    return span;
}

void push_corner(Vertices& out, const Edge& along, const Edge& upright, std::uint32_t colour) {
    render::UiVertex corner;
    corner.x = along.place;
    corner.y = upright.place;
    corner.u = along.texel;
    corner.v = upright.texel;
    corner.colour = colour;
    out.push_back(corner);
}

// Quad của stamp cắt theo clip. Khác gốc chưa kiểm: màu hai mép giữ nguyên khi quad bị cắt, như
// Imageset::draw của CEGUI 0.4; Image::draw bản 2026 (0x180056c40) chưa tháo.
void push_stamp(const Stamp& stamp, const gui::Box& clip, Vertices& out) {
    const GlyphCell& cell = *stamp.cell;
    const Span wide = span_of({.start = stamp.left, .size = stamp.size, .first = cell.u0, .last = cell.u1});
    const Span tall = span_of({.start = stamp.top, .size = stamp.size, .first = cell.v0, .last = cell.v1});
    const Span across = clip_span(wide, Limits{.low = clip.x, .high = clip.x + clip.w});
    const Span down = clip_span(tall, Limits{.low = clip.y, .high = clip.y + clip.h});
    if (across.high.place <= across.low.place || down.high.place <= down.low.place) return;
    push_corner(out, across.low, down.low, stamp.tint.top);
    push_corner(out, across.high, down.low, stamp.tint.top);
    push_corner(out, across.high, down.high, stamp.tint.bottom);
    push_corner(out, across.low, down.high, stamp.tint.bottom);
}

// Tám hướng lệch một điểm ảnh của viền.
struct Nudge {
    float across = 0.0F;
    float down = 0.0F;
};

constexpr std::array<Nudge, 8> kEdgeNudges = {{
    {.across = -1.0F, .down = -1.0F},
    {.across = 0.0F, .down = -1.0F},
    {.across = 1.0F, .down = -1.0F},
    {.across = -1.0F, .down = 0.0F},
    {.across = 1.0F, .down = 0.0F},
    {.across = -1.0F, .down = 1.0F},
    {.across = 0.0F, .down = 1.0F},
    {.across = 1.0F, .down = 1.0F},
}};

[[nodiscard]] constexpr bool is_breaker(Code code) noexcept {
    return std::ranges::find(kBreakers, code) != kBreakers.end();
}

// Phần tử là ký tự có glyph: điều kiện mở đầu của mọi vòng đọc chuỗi trong Font (0x18004b570).
// Phông bitmap trải mọi mã dưới 0x10000 (mã không có bản ghi thành ô vuông rỗng), nên nhánh "dấu
// cách không có ảnh" của bản gốc không bao giờ chạy với phông AXFT và không có ở đây.
[[nodiscard]] constexpr bool is_glyph(Code code) noexcept {
    return code < 0x10000U && code != U'\r' && code != U'\n';
}

// Chữ cái chỉ có ở tiếng Việt (cùng chữ Latin có dấu của Latin-1 mà văn bản Hán dùng cho bính âm thì
// phông Hán vẽ được, nhưng cả run đã là tiếng Việt thì vẽ chung một phông): Ă ă Đ đ Ĩ ĩ Ũ ũ Ơ ơ Ư ư, các chữ
// Latin-1 có dấu (trừ × và ÷) và cả khối Latin mở rộng bổ sung U+1EA0..U+1EF9.
[[nodiscard]] constexpr bool is_vietnamese_letter(Code code) noexcept {
    constexpr std::array<Code, 12> kSingles{
        0x102, 0x103, 0x110, 0x111, 0x128, 0x129, 0x168, 0x169, 0x1A0, 0x1A1, 0x1AF, 0x1B0};
    if (code >= 0x1EA0U && code <= 0x1EF9U) return true;
    if (code >= 0xC0U && code <= 0xFFU) return code != 0xD7U && code != 0xF7U;
    return std::ranges::find(kSingles, code) != kSingles.end();
}

// Đoạn của text từ first tới trước dấu xuống dòng kế, như vòng tìm '\n' của drawText (0x18004ae11).
// is_last sai khi sau đoạn còn một dấu xuống dòng: đoạn kế bắt đầu ở first + codes.size() + 1 (có
// thể rỗng, khi dấu xuống dòng đứng cuối chuỗi).
struct Segment {
    std::span<const Code> codes;
    bool is_last = true;
};

[[nodiscard]] Segment segment_at(std::span<const Code> text, std::size_t first) noexcept {
    const auto rest = text.subspan(first);
    const auto stop = static_cast<std::size_t>(std::ranges::find(rest, Code{U'\n'}) - rest.begin());
    return {.codes = rest.first(stop), .is_last = first + stop >= text.size()};
}

[[nodiscard]] bool is_finite(const gui::Box& box) noexcept {
    return std::isfinite(box.x) && std::isfinite(box.y) && std::isfinite(box.w) && std::isfinite(box.h);
}

// Mã UTF-8 của một điểm mã dưới 0x10000, để hỏi BitmapFont (nó nhận chuỗi).
struct Utf8 {
    std::array<char, 3> bytes{};
    std::size_t size = 0;
};

[[nodiscard]] constexpr Utf8 encode(Code code) noexcept {
    const auto tail = [](Code bits) { return static_cast<char>(0x80U | (bits & 0x3FU)); };
    if (code < 0x80U) return {.bytes = {static_cast<char>(code)}, .size = 1};
    if (code < 0x800U) return {.bytes = {static_cast<char>(0xC0U | (code >> 6U)), tail(code)}, .size = 2};
    return {.bytes = {static_cast<char>(0xE0U | ((code >> 12U) & 0x0FU)), tail(code >> 6U), tail(code)}, .size = 3};
}

} // namespace

void scan_markup(const MarkupAsk& ask, std::vector<Code>& out) {
    Scan scan;
    scan.strings = ask.strings;
    scan.out = &out;
    scan.limit = out.size() + kMaxCodes;
    if (ask.is_plain) {
        push_chars(scan, ask.text);
        return;
    }
    scan.frames.front().text = ask.text;
    scan_all(scan);
}

// Đo và vẽ một chuỗi đã đọc thẻ bằng phông của một TextWriter: các hàm của lớp Font bản 2026, tỉ lệ
// ngang dọc đều 1. Dựng mới cho mỗi lời gọi.
class Typesetter {
public:
    explicit Typesetter(const TextWriter& writer) noexcept
        : writer_(&writer), size_(static_cast<float>(writer.font_->pixel_size())), height_(size_ + kGlyphPad) {}

    [[nodiscard]] float extent(std::span<const Code> text) const;
    [[nodiscard]] gui::TextSize line_size(std::span<const Code> text) const;
    [[nodiscard]] gui::TextSize formatted_size(std::span<const Code> text, const Area& area, std::uint8_t format) const;
    [[nodiscard]] std::optional<gui::Box> write(const gui::TextRun& run, std::span<const Code> text, Vertices& out);

private:
    // getTextExtent đang cộng dở: bề rộng và hai cờ của khoá liên kết (riêng cho mỗi lần đo).
    struct Tally {
        float width = 0.0F;
        bool in_link = false;
        bool in_key = false;
    };

    void add(Tally& tally, Code code) const;
    [[nodiscard]] gui::TextSize wrapped_size(std::span<const Code> text, float width) const;
    [[nodiscard]] float sealed(float total) const noexcept;
    void settle(Area& area, const gui::TextRun& run, std::span<const Code> text) const;
    [[nodiscard]] float draw_text(std::span<const Code> text, const Area& area, std::uint8_t format);
    [[nodiscard]] float draw_rows(std::span<const Code> text, const Area& whole, std::uint8_t format);
    [[nodiscard]] float draw_wrapping(std::span<const Code> text, Area whole, std::uint8_t format);
    [[nodiscard]] float draw_wrapped(std::span<const Code> text, const Area& area, std::uint8_t format);
    [[nodiscard]] float draw_line(std::span<const Code> text, Corner pen);
    void draw_glyph(Code code, Corner& pen);
    void draw_edge(const Stamp& stamp) const;
    void draw_underline(const Corner& pen, float advance);
    [[nodiscard]] bool is_key(Code code) noexcept;
    [[nodiscard]] Tint tint_now() noexcept;
    [[nodiscard]] std::optional<gui::Box> write_edit(const gui::TextRun& run, std::span<const Code> text) const;
    [[nodiscard]] float edit_row(std::span<const Code> row, Corner pen, std::uint32_t colour) const;
    [[nodiscard]] float edit_width(std::span<const Code> row) const;

    const TextWriter* writer_;
    // Cỡ phông S và cao phông S + 2 (ascender trừ descender, cũng là cạnh ô glyph của bản gốc).
    float size_;
    float height_;
    Vertices* out_ = nullptr;
    gui::Box clip_;
    Ink ink_;
    // Bút sau ký tự cuối của dòng vừa vẽ, cho con nháy.
    Corner last_;
    // Gặp kiểu canh mà drawText gốc ném lỗi: thôi vẽ phần còn lại.
    bool is_aborted_ = false;
};

// Một phần tử của getTextExtent (0x18004f790). Trong liên kết, chữ từ dấu { tới dấu } là khoá,
// không tính bề rộng. Hoạt ảnh rộng 0 (Khác gốc).
void Typesetter::add(Tally& tally, Code code) const {
    if (!is_glyph(code)) {
        if ((code & kKindMask) == kLinkOn) tally.in_link = true;
        if ((code & kKindMask) == kLinkOff) tally.in_link = false;
        return;
    }
    if (tally.in_link && (code == U'{' || code == U'}')) {
        tally.in_key = code == U'{';
        return;
    }
    if (tally.in_link && tally.in_key) return;
    tally.width += writer_->cell_of(code).advance;
}

float Typesetter::extent(std::span<const Code> text) const {
    Tally tally;
    for (const Code code : text)
        add(tally, code);
    return std::max(0.0F, tally.width);
}

// getLineSize (0x18004f050): bề rộng là mép phải xa nhất của các ô glyph (ô rộng S + 2, lệch trái
// 1) hoặc tổng bước ngang, số nào lớn hơn.
gui::TextSize Typesetter::line_size(std::span<const Code> text) const {
    Tally tally;
    float reach = 0.0F;
    for (const Code code : text) {
        const float before = tally.width;
        add(tally, code);
        const bool is_drawn = is_glyph(code) && !(tally.in_link && (tally.in_key || code == U'}'));
        if (is_drawn) reach = std::max(reach, (height_ - kBitmapDrop) + before);
    }
    return {.width = std::max(reach, tally.width), .height = height_};
}

// getWrappedSize (0x18004fd90), cùng luật bẻ với draw_wrapped: phần tử làm tràn đã nằm trong dòng
// lúc đo, nên trần lùi là 13 và ngưỡng "dòng dài hơn 1" thành "hơn 2". Mỗi lần bẻ cộng cao dòng
// và 3, kể cả khi dòng vẽ ra rỗng (lúc vẽ dòng rỗng chỉ cao font_height).
gui::TextSize Typesetter::wrapped_size(std::span<const Code> text, float width) const {
    if (text.empty()) return {};
    gui::TextSize size;
    std::size_t first = 0;
    Tally tally;
    // Khác gốc: tiếng Việt không cắt giữa từ. Không có dấu ngắt từ đầu dòng tới chỗ tràn thì giữ
    // nguyên từ (dòng được phép rộng hơn ô). Tiếng Trung không có dấu cách nên vẫn ngắt từng ký tự.
    const bool is_vietnamese = std::ranges::any_of(text, [](Code code) { return is_vietnamese_letter(code); });
    for (std::size_t index = 0; index < text.size(); ++index) {
        add(tally, text[index]);
        const float reached = std::max(0.0F, tally.width);
        size.width = std::max(size.width, reached);
        if (!(reached > width)) continue;
        const auto earlier = text.subspan(first, index - first);
        const bool can_split = !is_vietnamese || std::ranges::find_if(earlier, is_breaker) != earlier.end();
        if (!can_split) continue;
        std::size_t count = (index - first) + 1;
        const std::size_t reach = is_vietnamese ? count : std::min(count, kLookBack + 1);
        const auto tail = text.subspan(first + count - reach, reach);
        const auto found = std::ranges::find_if(tail.rbegin(), tail.rend(), is_breaker);
        const auto back = found == tail.rend() ? std::size_t{0} : static_cast<std::size_t>(found - tail.rbegin());
        count -= back;
        index -= back;
        size.height += height_ + kLineSpace;
        size.width = width;
        if (count > 2) --index;
        first = index + 1;
        tally = {};
    }
    size.height += height_;
    return size;
}

// getFormattedSize (0x18004e7f0): các đoạn giữa hai dấu xuống dòng; đoạn không mở đầu chuỗi cộng
// 3, đoạn rỗng cao font_height. Chỉ bề rộng của area được dùng.
gui::TextSize Typesetter::formatted_size(std::span<const Code> text, const Area& area, std::uint8_t format) const {
    if (text.empty() || format > kWrapLast) return {};
    const float width = cut(area.right + kHalf) - cut(area.left + kHalf);
    gui::TextSize size;
    for (std::size_t first = 0;;) {
        const Segment part = segment_at(text, first);
        const gui::TextSize one = format >= kWrapFirst ? wrapped_size(part.codes, width) : line_size(part.codes);
        size.height += (first != 0 ? kLineSpace : 0.0F) + std::max(one.height, height_);
        size.width = std::max(size.width, one.width);
        if (part.is_last) break;
        first += part.codes.size() + 1;
    }
    return size;
}

// Kết quả của drawText (0x18004b1b3): cao khối không nhỏ hơn cao phông, kể cả khi chuỗi rỗng.
float Typesetter::sealed(float total) const noexcept {
    return height_ <= total ? total : height_;
}

// Canh dọc trước drawText. TextComponent của look (CEGUIBase.dll 0x180128453): giữa cộng nửa phần
// thừa, không làm tròn. FalagardSimpleText (CEGUIFalagard.dll 0x18004e552): trên cộng 1, giữa cộng
// nửa phần thừa đã cộng 0,5 và cắt. Cả hai: dưới là đáy trừ cao khối. Chuỗi rỗng không vẽ gì.
void Typesetter::settle(Area& area, const gui::TextRun& run, std::span<const Code> text) const {
    if (run.rule == gui::TextRule::kRaw || text.empty()) return;
    const bool is_simple = run.rule == gui::TextRule::kSimpleText;
    const float height = formatted_size(text, area, run.horz).height;
    const float spare = ((area.bottom - area.top) - height) * kHalf;
    if (run.vert == kVertBottom) {
        area.top = area.bottom - height;
    } else if (run.vert == kVertCentre) {
        area.top = is_simple ? area.top + cut(spare + kHalf) : spare + area.top;
    } else if (is_simple && run.vert == 0) {
        area.top += 1.0F;
    }
}

// drawText (0x18004aa60) của lời gọi ngoài: ô dời lên 1 và làm nguyên, rồi theo kiểu canh. Trạng
// thái màu đã được write đặt lại (tham số reset = true của bản gốc).
float Typesetter::draw_text(std::span<const Code> text, const Area& area, std::uint8_t format) {
    const Area whole = snapped(area);
    if (format >= kWrapFirst && format <= kWrapLast) {
        return sealed(draw_wrapping(text, whole, static_cast<std::uint8_t>(format - kWrapFirst)));
    }
    return sealed(draw_rows(text, whole, format));
}

// Các đoạn giữa hai dấu xuống dòng của một kiểu không bẻ dòng, mỗi đoạn một dòng (0x18004adf0).
// whole là ô đã dời và làm nguyên. Trả tổng cao: mỗi dòng cao phông cộng 3, kể cả dòng rỗng. Canh
// giữa cộng thêm 1 sau khi cắt (0x18004afdb); canh phải không làm tròn thêm. Kiểu 3 và kiểu lạ:
// bản gốc ném lỗi ngay ở đoạn đầu.
float Typesetter::draw_rows(std::span<const Code> text, const Area& whole, std::uint8_t format) {
    if (text.empty() || is_aborted_) return 0.0F;
    if (format >= kJustified) {
        is_aborted_ = true;
        return 0.0F;
    }
    Corner pen{.x = whole.left, .y = whole.top};
    float total = 0.0F;
    for (std::size_t first = 0;;) {
        const Segment part = segment_at(text, first);
        const float spare = (whole.right - whole.left) - extent(part.codes);
        pen.x = whole.left;
        if (format == kRightAligned) pen.x = whole.right - extent(part.codes);
        if (format == kCentreAligned) pen.x = cut((spare * kHalf) + whole.left + kHalf) + 1.0F;
        const float drawn = draw_line(part.codes, pen);
        pen.y += drawn;
        total += drawn;
        if (part.is_last) break;
        first += part.codes.size() + 1;
    }
    return total;
}

// Nhánh bẻ dòng của drawText: từng đoạn giữa hai dấu xuống dòng, ô tụt theo cao đoạn vừa vẽ.
float Typesetter::draw_wrapping(std::span<const Code> text, Area whole, std::uint8_t format) {
    if (text.empty() || is_aborted_) return 0.0F;
    float total = 0.0F;
    for (std::size_t first = 0;;) {
        const Segment part = segment_at(text, first);
        const float drawn = draw_wrapped(part.codes, whole, format);
        whole.top += drawn;
        whole.bottom += drawn;
        total += drawn;
        if (part.is_last) break;
        first += part.codes.size() + 1;
    }
    return total;
}

// Các đoạn giữa hai dấu xuống dòng của một kiểu bẻ dòng (nhánh 4..7 của drawText, 0x18004b01f):
// mỗi đoạn qua drawWrappedText, ô tụt xuống theo cao đoạn vừa vẽ. format là kiểu trong (0..3).
// dòng rỗng vẫn chiếm font_height. Mỗi dòng vẽ bằng một drawText lồng: ô lại dời lên 1 (dời đúp).
// Kết thúc: đầu dòng tăng nghiêm ngặt sau mỗi lần cắt, nên số lần cắt không quá số phần tử.
float Typesetter::draw_wrapped(std::span<const Code> text, const Area& area, std::uint8_t format) {
    const float width = area.right - area.left;
    Area dest = area;
    float total = 0.0F;
    std::size_t first = 0;
    Tally tally;
    const bool is_vietnamese = std::ranges::any_of(text, [](Code code) { return is_vietnamese_letter(code); });
    for (std::size_t index = 0; index < text.size(); ++index) {
        Tally tried = tally;
        add(tried, text[index]);
        if (!(std::max(0.0F, tried.width) > width)) {
            tally = tried;
            continue;
        }
        const auto earlier = text.subspan(first, index - first);
        const bool can_split = !is_vietnamese || std::ranges::find_if(earlier, is_breaker) != earlier.end();
        if (!can_split) {
            tally = tried;
            continue;
        }
        std::size_t count = index - first;
        const std::size_t look = is_vietnamese ? count : std::min(count, kLookBack);
        const auto tail = text.subspan(first + count - look, look);
        const auto found = std::ranges::find_if(tail.rbegin(), tail.rend(), is_breaker);
        const bool is_backed = !is_breaker(text[index]) && found != tail.rend();
        const auto back = is_backed ? static_cast<std::size_t>(found - tail.rbegin()) + 1 : std::size_t{0};
        count -= back;
        index -= back;
        const float drawn = sealed(draw_rows(text.subspan(first, count), snapped(dest), format));
        dest.top += drawn;
        dest.bottom += drawn;
        total += drawn;
        if (count > 1) --index;
        first = index + 1;
        tally = {};
    }
    const std::uint8_t last = format == kJustified ? std::uint8_t{0} : format;
    return total + sealed(draw_rows(text.subspan(first), snapped(dest), last));
}

// drawTextLine (0x18004b250): pen.y là mép trên ô glyph, pen.x là cột bitmap đầu. Trả cao dòng cộng
// 3; với phông bitmap mọi ô glyph cao bằng cao phông nên bước dòng là S + 5.
float Typesetter::draw_line(std::span<const Code> text, Corner pen) {
    for (const Code code : text) {
        if (is_glyph(code)) {
            draw_glyph(code, pen);
        } else {
            apply(ink_, code);
        }
    }
    last_ = pen;
    return height_ + kLineSpace;
}

// Trong liên kết, dấu { mở khoá, dấu } đóng, chữ ở giữa là khoá: không vẽ, bút không tiến
// (0x18004b62b..0x18004b704).
bool Typesetter::is_key(Code code) noexcept {
    if (!ink_.in_link) return false;
    if (code == U'{' || code == U'}') {
        ink_.in_key = code == U'{';
        return true;
    }
    return ink_.in_key;
}

// Màu của glyph kế: trong liên kết là màu liên kết (0x18004b825); hai màu gradient khác nhau thì
// gradient dọc (0x18004c5c0), không thì màu chữ. Ô bitmap là hàng 1..S của ô glyph cao S + 2 mà
// gradient trải trên đó, nên hai mép lấy màu ở 1/(S + 2) và (S + 1)/(S + 2).
Tint Typesetter::tint_now() noexcept {
    if (ink_.in_link) {
        if (ink_.link == 0) ink_.link = kDefaultLink;
        return flat(ink_.link);
    }
    if (ink_.top == ink_.bottom) return flat(ink_.text);
    const Mix mix{.from = ink_.top, .into = ink_.bottom};
    return {.top = mixed(mix, kBitmapDrop / height_), .bottom = mixed(mix, (size_ + kBitmapDrop) / height_)};
}

// Một glyph (0x18004b59b..0x18004be1c): viền khi màu viền có RGB khác 0, chữ, gạch chân, rồi bút
// tiến đúng bước ngang. Ô glyph gốc có mép trên ở pen.y và mép trái ở pen.x - 1; ô bitmap của atlas
// này là phần trong của nó, từ (pen.x, pen.y + 1).
void Typesetter::draw_glyph(Code code, Corner& pen) {
    if (is_key(code)) return;
    const GlyphCell& cell = writer_->cell_of(code);
    const Stamp stamp{.left = pen.x, .top = pen.y + kBitmapDrop, .size = size_, .cell = &cell, .tint = tint_now()};
    if (cell.has_ink && (ink_.edge & kRgbMask) != 0) draw_edge(stamp);
    if (cell.has_ink) push_stamp(stamp, clip_, *out_);
    if (ink_.is_underlined) draw_underline(pen, cell.advance);
    pen.x += cell.advance;
}

// Viền (0x18004a730 và cờ 0x1802e9013): bản gốc tô vòng viền ghi sẵn quanh từng điểm chữ trong ô
// glyph, tám hướng, bằng màu viền. Khác gốc: ở đây là tám bản của ô bitmap lệch một điểm ảnh, vẽ
// trước chữ; cùng điểm ảnh khi màu viền đặc, chồng đậm hơn khi màu viền trong suốt một phần.
void Typesetter::draw_edge(const Stamp& stamp) const {
    for (const Nudge& nudge : kEdgeNudges) {
        Stamp shifted = stamp;
        shifted.left += nudge.across;
        shifted.top += nudge.down;
        shifted.tint = flat(ink_.edge);
        push_stamp(shifted, clip_, *out_);
    }
}

// Gạch chân (0x18004bc33): bản gốc kéo ảnh "view" của phông (0x18004a120: S x S, chỉ hàng cuối
// sáng) vào ô rộng bằng bước ngang và cao bằng ô glyph, tức một nét ở hàng cuối của ô glyph. Màu:
// màu liên kết, màu dưới của gradient, hoặc màu chữ.
// Chưa kiểm: với lấy mẫu tuyến tính nét gốc nhoè sang hàng trên; ở đây là đúng một hàng điểm ảnh.
void Typesetter::draw_underline(const Corner& pen, float advance) {
    if (!writer_->solid_) return;
    const std::uint32_t colour = ink_.in_link || ink_.top == ink_.bottom ? tint_now().bottom : ink_.bottom;
    const Limits wide{.low = std::max(pen.x, clip_.x), .high = std::min(pen.x + advance, clip_.x + clip_.w)};
    const Limits tall{
        .low = std::max(pen.y + height_ - 1.0F, clip_.y), .high = std::min(pen.y + height_, clip_.y + clip_.h)};
    if (wide.high <= wide.low || tall.high <= tall.low) return;
    const TextWriter::Texel& dot = *writer_->solid_;
    out_->push_back({.x = wide.low, .y = tall.low, .u = dot.u, .v = dot.v, .colour = colour});
    out_->push_back({.x = wide.high, .y = tall.low, .u = dot.u, .v = dot.v, .colour = colour});
    out_->push_back({.x = wide.high, .y = tall.high, .u = dot.u, .v = dot.v, .colour = colour});
    out_->push_back({.x = wide.low, .y = tall.high, .u = dot.u, .v = dot.v, .colour = colour});
}

std::optional<gui::Box> Typesetter::write(const gui::TextRun& run, std::span<const Code> text, Vertices& out) {
    out_ = &out;
    clip_ = run.clip.value_or(run.box);
    // Bẻ dòng dời chữ lên 2 điểm so với ô. Dấu thanh nằm ở hàng trên ô glyph; cắt đúng ô thì mất
    // dấu. Khác gốc: chỉ khi ô cắt là chính box và chữ có dấu tiếng Việt; ô cắt riêng, chữ Hán và
    // ASCII giữ đúng clip của client gốc.
    const bool is_vietnamese =
        std::ranges::any_of(text, [](Code code) { return is_vietnamese_letter(code); });
    if (is_vietnamese && !run.clip) {
        clip_.y -= 2.0F;
        clip_.h += 3.0F;
    }
    if (run.rule == gui::TextRule::kEdit) return write_edit(run, text);
    Area area{.top = run.box.y, .bottom = run.box.y + run.box.h, .left = run.box.x, .right = run.box.x + run.box.w};
    settle(area, run, text);
    ink_ = Ink{};
    ink_.text = run.colour;
    ink_.base_alpha = run.colour & kAlphaMask;
    const Area whole = snapped(area);
    last_ = {.x = whole.left, .y = whole.top};
    static_cast<void>(draw_text(text, area, run.horz));
    if (!run.has_caret) return std::nullopt;
    return gui::Box{.x = last_.x, .y = last_.y, .w = kCaretWidth, .h = height_};
}

// Ô nhập (TextRule::kEdit): giữ cách dàn của bản viết trước, theo FalagardIMEEditBox của mã 2008
// (bản 2026 chưa tháo). Dòng cao S + 2, mép trái và mép trên làm tròn nửa lên, ô bitmap thấp hơn
// mép dòng 1, bước ngang lấy thẳng từ tệp phông, mã phông không có thì bỏ, mã điều khiển bỏ qua.
// Không bẻ dòng: gui chỉ đưa kiểu canh một dòng cho ô nhập.
float Typesetter::edit_width(std::span<const Code> row) const {
    float width = 0.0F;
    for (const Code code : row) {
        if (is_glyph(code)) width += writer_->cell_of(code).file_advance;
    }
    return width;
}

float Typesetter::edit_row(std::span<const Code> row, Corner pen, std::uint32_t colour) const {
    for (const Code code : row) {
        if (!is_glyph(code)) continue;
        const GlyphCell& cell = writer_->cell_of(code);
        const Stamp stamp{
            .left = pen.x, .top = pen.y + kBitmapDrop, .size = size_, .cell = &cell, .tint = flat(colour)};
        if (cell.is_known && cell.has_ink) push_stamp(stamp, clip_, *out_);
        pen.x += cell.file_advance;
    }
    return pen.x;
}

std::optional<gui::Box> Typesetter::write_edit(const gui::TextRun& run, std::span<const Code> text) const {
    const auto round_half_up = [](float value) { return std::floor(value + kHalf); };
    const float block = height_ * static_cast<float>(std::ranges::count(text, Code{U'\n'}) + 1);
    const std::uint8_t align = run.horz % kWrapFirst;
    Corner pen{.x = round_half_up(run.box.x), .y = round_half_up(run.box.y)};
    if (run.vert == kVertCentre) pen.y = round_half_up(run.box.y + ((run.box.h - block) * kHalf));
    if (run.vert == kVertBottom) pen.y = round_half_up(run.box.y + run.box.h - block);
    float stop = pen.x;
    for (std::size_t first = 0;;) {
        const Segment part = segment_at(text, first);
        const float width = edit_width(part.codes);
        pen.x = round_half_up(run.box.x);
        if (align == kCentreAligned) pen.x = round_half_up(run.box.x + ((run.box.w - width) * kHalf));
        if (align == kRightAligned) pen.x = round_half_up(run.box.x + run.box.w - width);
        stop = edit_row(part.codes, pen, run.colour);
        pen.y += height_;
        if (part.is_last) break;
        first += part.codes.size() + 1;
    }
    if (!run.has_caret) return std::nullopt;
    return gui::Box{.x = stop, .y = pen.y - height_, .w = kCaretWidth, .h = height_};
}

TextWriter::TextWriter(const BitmapFont& font, const gui::StringBook* strings) : font_(&font), strings_(strings) {
    GlyphCell missing;
    probe_.clear();
    font_->append_missing(0.0F, 0.0F, 0xFFFFFFFFU, probe_);
    if (probe_.size() != 4) return;
    missing.u0 = probe_[0].u;
    missing.v0 = probe_[0].v;
    missing.u1 = probe_[2].u;
    missing.v1 = probe_[2].v;
    solid_ = lit_texel(missing);
}

// Tâm của điểm sáng đầu tiên trong ô cell của atlas; rỗng khi ô trống hay nằm ngoài atlas.
std::optional<TextWriter::Texel> TextWriter::lit_texel(const GlyphCell& cell) const {
    const resource::Image& atlas = font_->atlas();
    const auto side = static_cast<std::size_t>(font_->pixel_size());
    const auto left = static_cast<std::size_t>(std::lround(cell.u0 * static_cast<float>(atlas.width)));
    const auto top = static_cast<std::size_t>(std::lround(cell.v0 * static_cast<float>(atlas.height)));
    const bool is_inside = left + side <= atlas.width && top + side <= atlas.height &&
        atlas.rgba.size() >= static_cast<std::size_t>(atlas.width) * atlas.height * 4;
    if (!is_inside) return std::nullopt;
    for (std::size_t dot = 0; dot < side * side; ++dot) {
        const std::size_t across = left + (dot % side);
        const std::size_t down = top + (dot / side);
        if (atlas.rgba[(((down * atlas.width) + across) * 4) + 3] == 0) continue;
        const float u = (static_cast<float>(across) + kHalf) / static_cast<float>(atlas.width);
        const float v = (static_cast<float>(down) + kHalf) / static_cast<float>(atlas.height);
        return Texel{.u = u, .v = v};
    }
    return std::nullopt;
}

// Hỏi phông một lần: quad của mã ở gốc toạ độ cho biết ô trong atlas. Mã không có trong phông lấy
// ô vuông rỗng và bước ngang bằng cỡ phông (0x180133440).
GlyphCell TextWriter::probe(Code code) const {
    GlyphCell cell;
    const int size = font_->pixel_size();
    cell.is_known = font_->has_code(code);
    cell.file_advance = static_cast<float>(font_->advance_of(code));
    const int raw = cell.is_known ? font_->advance_of(code) : size;
    cell.advance = static_cast<float>(raw == size ? raw + 1 : raw);
    const Utf8 utf8 = encode(code);
    probe_.clear();
    if (cell.is_known) {
        font_->append_text(std::string_view(utf8.bytes.data(), utf8.size), 0.0F, 0.0F, 0xFFFFFFFFU, probe_);
    } else {
        font_->append_missing(0.0F, 0.0F, 0xFFFFFFFFU, probe_);
    }
    if (probe_.size() != 4) return cell;
    cell.u0 = probe_[0].u;
    cell.v0 = probe_[0].v;
    cell.u1 = probe_[2].u;
    cell.v1 = probe_[2].v;
    cell.has_ink = lit_texel(cell).has_value();
    return cell;
}

// code phải dưới 0x10000 (is_glyph).
const GlyphCell& TextWriter::cell_of(Code code) const {
    const auto known = cells_.find(code);
    if (known != cells_.end()) return known->second;
    return cells_.emplace(code, probe(code)).first->second;
}

std::span<const Code> TextWriter::scanned(std::string_view text) const {
    codes_.clear();
    scan_markup(MarkupAsk{.text = text, .strings = strings_}, codes_);
    return codes_;
}

std::optional<gui::Box> TextWriter::write(const gui::TextRun& run, Vertices& out) {
    if (!is_finite(run.box) || !is_finite(run.clip.value_or(run.box))) return std::nullopt;
    codes_.clear();
    scan_markup(MarkupAsk{.text = run.text, .strings = strings_, .is_plain = run.is_plain}, codes_);
    return Typesetter(*this).write(run, codes_, out);
}

RunFit TextWriter::fit_of(const gui::TextRun& run) const {
    codes_.clear();
    scan_markup(MarkupAsk{.text = run.text, .strings = strings_, .is_plain = run.is_plain}, codes_);
    RunFit fit;
    for (const Code code : codes_) {
        if (!is_glyph(code)) continue;
        if (!font_->has_code(static_cast<char32_t>(code))) ++fit.unknown;
        if (is_vietnamese_letter(code)) fit.has_vietnamese = true;
    }
    return fit;
}

float TextWriter::font_height() const {
    return static_cast<float>(font_->pixel_size()) + kGlyphPad;
}

float TextWriter::line_spacing() const {
    return font_height();
}

float TextWriter::line_height() const noexcept {
    return static_cast<float>(font_->pixel_size()) + kGlyphPad;
}

gui::TextSize TextWriter::line_size(std::string_view text) const {
    return Typesetter(*this).line_size(scanned(text));
}

gui::TextSize TextWriter::formatted_size(std::string_view text, float width, std::uint8_t horz) const {
    return Typesetter(*this).formatted_size(scanned(text), Area{.right = width}, horz);
}

float TextWriter::width_of(std::string_view text) const {
    return Typesetter(*this).extent(scanned(text));
}

} // namespace game::ui
