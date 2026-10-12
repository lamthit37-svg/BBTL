// Bộ vẽ bàn phím ảo của client 2026 (Falagard/SoftKeyWindow, lớp FalagardSoftKeyBoard của
// CEGUIFalagard.dll). Lưới 15 cột, 5 hàng: ô ở cột c, hàng r nằm tại (c x (rộng phím + 1), r x (cao
// phím + 1)) tính từ góc trái trên cửa sổ. Mỗi phím ký tự vẽ ảnh NormalImage loại 0 kín ô của nó;
// ba phím lớn (xoá lùi loại 1, Shift loại 2, Return loại 3) vẽ một ảnh từ ô đầu của nhóm, rộng hai
// phím, riêng Return nhô lên thêm một hàng phím. Phím dưới chuột vẽ đè HoverImage, đang nhấn thì
// PushedImage, cùng ô với ảnh nền của nó. Chữ của phím ký tự canh giữa ô.
// Nguồn: setKeyPosition 0x180080d90, resetAllPosition 0x18007eb80, getKeyByPosition 0x18007dd80 và
// populateRenderCache 0x18007e220 của CEGUIFalagard.dll; tên hàm theo
// CEGUIFalagardEx/FalagardSoftKeyBoard.cpp của mã 2008. Khác mã 2008: bước lưới có thêm 1 điểm ảnh,
// và có ảnh nền riêng cho từng phím (bản 2008 chỉ vẽ ảnh của phím dưới chuột).
// Khác gốc: ảnh nhấn hiện khi chuột đang nhấn trên phím (bản gốc chỉ khi lần nhấn bắt đầu ở chính
// phím đó); chưa kiểm bản gốc vẽ ký tự # của mặt phím thế nào, ở đây chữ của phím là nguyên văn.
#include "gui/detail/softkey.hpp"

#include "gui/asset.hpp"
#include "gui/detail/draw.hpp"
#include "gui/sheet.hpp"
#include "gui/softkey.hpp"
#include "gui/value.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <iterator>
#include <optional>
#include <span>
#include <string_view>

namespace game::gui::detail {
namespace {

// Cỡ phím khi layout không nêu KeySize (hàm dựng của FalagardSoftKeyBoard đặt 30 x 30).
constexpr float kDefaultKey = 30.0F;
// Khe giữa hai phím liền nhau.
constexpr float kGap = 1.0F;

constexpr auto kCentredHorz = static_cast<std::uint8_t>(GuiTextHorz::kCentreAligned);
constexpr auto kCentredVert = static_cast<std::uint8_t>(GuiTextVert::kCentreAligned);

// Cột và hàng của một ô phím trong lưới.
struct KeySpot {
    std::uint8_t column = 0;
    std::uint8_t row = 0;

    [[nodiscard]] constexpr bool operator==(const KeySpot&) const noexcept = default;
};

// Một dãy ô liền nhau trên một hàng, từ trái sang phải.
struct KeyRun {
    KeySpot first;
    std::uint8_t count = 0;
};

// Các dãy ô theo đúng thứ tự resetAllPosition thêm vào từng nhóm: 10 phím số; 26 phím chữ; 32 phím
// dấu; rồi hai ô xoá lùi, hai ô Shift và ba ô Return (ô đầu của Return là ô góc dưới trái của nó).
constexpr std::array<KeyRun, 15> kRuns = {{
    {.first = {.column = 1, .row = 1}, .count = 10},
    {.first = {.column = 0, .row = 2}, .count = 10},
    {.first = {.column = 0, .row = 3}, .count = 9},
    {.first = {.column = 0, .row = 4}, .count = 7},
    {.first = {.column = 0, .row = 0}, .count = 13},
    {.first = {.column = 0, .row = 1}, .count = 1},
    {.first = {.column = 11, .row = 1}, .count = 2},
    {.first = {.column = 10, .row = 2}, .count = 4},
    {.first = {.column = 9, .row = 3}, .count = 4},
    {.first = {.column = 7, .row = 4}, .count = 8},
    {.first = {.column = 13, .row = 0}, .count = 2},
    {.first = {.column = 13, .row = 1}, .count = 2},
    {.first = {.column = 13, .row = 3}, .count = 1},
    {.first = {.column = 14, .row = 2}, .count = 1},
    {.first = {.column = 14, .row = 3}, .count = 1},
}};

// Danh sách ô đang dựng: at() ngoài biên lúc đánh giá hằng là lỗi biên dịch, nên bảng dãy thừa ô
// thì không dịch được.
struct SpotList {
    std::array<KeySpot, kSoftCells> spots{};
    std::size_t used = 0;

    constexpr void add(const KeyRun& run) {
        for (std::uint8_t step = 0; step < run.count; ++step) {
            const auto column = static_cast<std::uint8_t>(run.first.column + step);
            spots.at(used + step) = {.column = column, .row = run.first.row};
        }
        used += run.count;
    }
};

[[nodiscard]] constexpr SpotList listed_spots() {
    SpotList list;
    for (const KeyRun& run : kRuns) {
        list.add(run);
    }
    return list;
}

constexpr SpotList kListed = listed_spots();
constexpr std::array<KeySpot, kSoftCells> kSpots = kListed.spots;

static_assert(kListed.used == kSoftCells);
static_assert(kSpots.at(kSoftNumbers.first) == KeySpot{.column = 1, .row = 1});
static_assert(kSpots.at(kSoftLetters.first) == KeySpot{.column = 0, .row = 2});
static_assert(kSpots.at(kSoftMarks.first) == KeySpot{.column = 0, .row = 0});
static_assert(kSpots.at(kSoftCharCells - 1) == KeySpot{.column = 14, .row = 4});
static_assert(kSpots.at(kSoftBack.first) == KeySpot{.column = 13, .row = 0});
static_assert(kSpots.at(kSoftShift.first) == KeySpot{.column = 13, .row = 1});
static_assert(kSpots.at(kSoftReturn.first) == KeySpot{.column = 13, .row = 3});

// Phím lớn chiếm nhiều ô: ảnh của nó vẽ một lần từ ô đầu của nhóm, rộng hai phím; rise là số hàng
// phím nó nhô lên trên ô đầu. type là số loại trong thuộc tính ảnh ("type:1 set:... image:...").
struct BigKey {
    SoftKeySpan cells;
    std::string_view type;
    float rise = 0.0F;
};

constexpr std::array<BigKey, 3> kBigKeys = {{
    {.cells = kSoftBack, .type = "1", .rise = 0.0F},
    {.cells = kSoftShift, .type = "2", .rise = 0.0F},
    {.cells = kSoftReturn, .type = "3", .rise = 1.0F},
}};
constexpr std::string_view kCharType = "0";

// Lưới phím của một cửa sổ bàn phím: góc trái trên của cửa sổ trên màn hình và cỡ một phím.
struct KeyGrid {
    float left = 0.0F;
    float top = 0.0F;
    float key_width = kDefaultKey;
    float key_height = kDefaultKey;
};

// Số sau thẻ key trong text; thiếu hay hỏng thì cỡ phím mặc định.
[[nodiscard]] float key_side(std::string_view text, std::string_view key) noexcept {
    const TagValue value = tagged_value(text, key);
    if (!value) return kDefaultKey;
    return parse_float(*value).value_or(kDefaultKey);
}

// KeySize "w:30 h:30" của layout (setKeySize); layout không nêu thì cỡ mặc định.
[[nodiscard]] KeyGrid grid_of(const GuiAsset& asset, const Placed& self) {
    KeyGrid grid;
    grid.left = self.screen.x;
    grid.top = self.screen.y;
    const auto size = last_prop(asset, self.window->properties, "KeySize");
    if (!size) return grid;
    grid.key_width = key_side(*size, "w:");
    grid.key_height = key_side(*size, "h:");
    return grid;
}

[[nodiscard]] Box cell_box(const KeyGrid& grid, KeySpot spot) noexcept {
    Box box;
    box.x = grid.left + (static_cast<float>(spot.column) * (grid.key_width + kGap));
    box.y = grid.top + (static_cast<float>(spot.row) * (grid.key_height + kGap));
    box.w = grid.key_width;
    box.h = grid.key_height;
    return box;
}

[[nodiscard]] Box big_box(const KeyGrid& grid, const BigKey& key) {
    Box box = cell_box(grid, kSpots.at(key.cells.first));
    const float lift = key.rise * grid.key_height;
    box.y -= lift;
    box.h += lift;
    box.w = 2.0F * grid.key_width;
    return box;
}

[[nodiscard]] bool has_point(const Box& box, Pointer pointer) noexcept {
    const bool is_in_columns = pointer.x >= box.x && pointer.x < box.x + box.w;
    return is_in_columns && pointer.y >= box.y && pointer.y < box.y + box.h;
}

// Một ảnh của bàn phím: tên thuộc tính (NormalImage, HoverImage, PushedImage) và số loại phím.
struct KeyArt {
    std::string_view property;
    std::string_view type;
};

// Ảnh mà layout khai cho art; nullptr khi layout không khai hay bộ ảnh không có.
[[nodiscard]] const GuiImage* art_image(const Ctx& ctx, const Placed& self, const KeyArt& art) {
    const auto is_wanted = [&art](const GuiProperty& item) {
        return item.name == art.property && tagged_value(item.value, "type:") == art.type;
    };
    const std::span<const GuiProperty> properties = window_properties(*ctx.asset, self);
    const auto found = std::ranges::find_if(properties, is_wanted);
    if (found == properties.end()) return nullptr;
    const std::optional<ImageName> name = tagged_image(found->value);
    return name ? named_image(ctx, *name) : nullptr;
}

// Ảnh nền hay ảnh trạng thái của một phím: số loại và ô nó phủ.
struct Plate {
    std::string_view type;
    Box box;
};

// Phím chứa ô cell: phím lớn thì cả phím, không thì chính ô đó.
[[nodiscard]] Plate plate_of(const KeyGrid& grid, std::size_t cell) {
    const auto owns = [cell](const BigKey& key) { return holds(key.cells, cell); };
    const auto big = std::ranges::find_if(kBigKeys, owns);
    if (big != kBigKeys.end()) return {.type = big->type, .box = big_box(grid, *big)};
    return {.type = kCharType, .box = cell_box(grid, kSpots.at(cell))};
}

void put_art(const Ctx& ctx, const Placed& self, std::string_view property, const Plate& plate) {
    const KeyArt art{.property = property, .type = plate.type};
    const GuiImage* image = art_image(ctx, self, art);
    if (image != nullptr) push_whole(*ctx.sheet, *image, plate.box, kWhiteArgb);
}

void draw_char_plates(const Ctx& ctx, const Placed& self, const KeyGrid& grid) {
    const KeyArt art{.property = "NormalImage", .type = kCharType};
    const GuiImage* image = art_image(ctx, self, art);
    if (image == nullptr) return;
    for (const KeySpot spot : std::span(kSpots).first(kSoftCharCells)) {
        push_whole(*ctx.sheet, *image, cell_box(grid, spot), kWhiteArgb);
    }
}

// Ảnh trỏ hay ảnh nhấn của phím dưới chuột, khi self là cửa sổ dưới chuột.
void draw_hot_key(const Ctx& ctx, const Placed& self, const KeyGrid& grid) {
    if (ctx.hot != &self || !ctx.input->pointer) return;
    const std::optional<std::size_t> cell = soft_key_under(*ctx.asset, self, *ctx.input->pointer);
    if (!cell) return;
    const std::string_view property = ctx.is_down ? "PushedImage" : "HoverImage";
    put_art(ctx, self, property, plate_of(grid, *cell));
}

// Dòng chữ một ký tự của một mặt phím, canh giữa ô box.
[[nodiscard]] TextRun face_run(std::string_view face, const Box& box, std::string_view font) noexcept {
    TextRun run;
    run.text = face;
    run.box = box;
    run.horz = kCentredHorz;
    run.vert = kCentredVert;
    run.is_plain = true;
    run.font = font;
    return run;
}

} // namespace

std::optional<std::size_t> soft_key_under(const GuiAsset& asset, const Placed& self, Pointer pointer) {
    const KeyGrid grid = grid_of(asset, self);
    const auto is_under = [&grid, pointer](KeySpot spot) { return has_point(cell_box(grid, spot), pointer); };
    const auto found = std::ranges::find_if(kSpots, is_under);
    if (found == kSpots.end()) return std::nullopt;
    return static_cast<std::size_t>(std::distance(kSpots.begin(), found));
}

void draw_soft_keys(const Ctx& ctx, const Placed& self) {
    const KeyGrid grid = grid_of(*ctx.asset, self);
    draw_char_plates(ctx, self, grid);
    for (const BigKey& key : kBigKeys) {
        put_art(ctx, self, "NormalImage", Plate{.type = key.type, .box = big_box(grid, key)});
    }
    draw_hot_key(ctx, self, grid);
}

void soft_key_texts(const Ctx& ctx, const Placed& self) {
    const auto faces = effective(ctx, self, "Keys");
    if (!faces) return;
    const KeyGrid grid = grid_of(*ctx.asset, self);
    const std::string_view font = effective(ctx, self, "Font").value_or(std::string_view{});
    const std::size_t count = std::min(faces->size(), kSoftCharCells);
    for (std::size_t cell = 0; cell < count; ++cell) {
        const Box box = cell_box(grid, kSpots.at(cell));
        ctx.sheet->texts.push_back(face_run(faces->substr(cell, 1), box, font));
    }
}

} // namespace game::gui::detail
