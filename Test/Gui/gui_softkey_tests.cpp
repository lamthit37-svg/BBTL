// Bàn phím ảo của dàn trang (gui/softkey.cpp) trên GuiAsset dựng tay: ô phím nằm đúng lưới 15 x 5
// với bước cỡ phím cộng 1, ảnh nền của từng loại phím phủ đúng ô, chữ của phím theo Override
// "Keys", ảnh trỏ và ảnh nhấn đi theo phím dưới chuột, và Hub::soft_key đổi điểm ra đúng chỉ số ô.
// Số đối chiếu lấy từ setKeyPosition, resetAllPosition và populateRenderCache của
// CEGUIFalagard.dll bản 2026 (địa chỉ ở đầu gui/softkey.cpp).
#include "core/check.hpp"
#include "gui/asset.hpp"
#include "gui/sheet.hpp"
#include "gui/softkey.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>

namespace game::test {
namespace {

using gui::Box;
using gui::GuiAsset;
using gui::Hub;
using gui::Place;
using gui::Pointer;
using gui::Quad;
using gui::Sheet;
using gui::TextRun;

constexpr std::string_view kBoard = "Board";
constexpr std::string_view kPlain = "Plain";
// Góc trái trên của bàn phím trên màn hình thử và bước lưới của phím 30 x 30.
constexpr float kLeft = 100.0F;
constexpr float kTop = 50.0F;
constexpr float kStep = 31.0F;
constexpr float kKey = 30.0F;

// Ảnh của bàn phím thử: chỉ số trong asset.images cũng là số texture, để nhận ra quad theo texture.
enum class Art : std::uint8_t {
    kKeyNormal,
    kKeyHover,
    kKeyPushed,
    kBackNormal,
    kBackHover,
    kShiftNormal,
    kReturnNormal,
    kReturnHover,
    kReturnPushed,
};

// Tên thuộc tính, số loại phím và ảnh của từng dòng ảnh mà layout thử khai.
struct ArtLine {
    std::string_view property;
    std::string_view type;
    Art art = Art::kKeyNormal;
};

constexpr std::array<ArtLine, 9> kArtLines = {{
    {.property = "NormalImage", .type = "0", .art = Art::kKeyNormal},
    {.property = "HoverImage", .type = "0", .art = Art::kKeyHover},
    {.property = "PushedImage", .type = "0", .art = Art::kKeyPushed},
    {.property = "NormalImage", .type = "1", .art = Art::kBackNormal},
    {.property = "HoverImage", .type = "1", .art = Art::kBackHover},
    {.property = "NormalImage", .type = "2", .art = Art::kShiftNormal},
    {.property = "NormalImage", .type = "3", .art = Art::kReturnNormal},
    {.property = "HoverImage", .type = "3", .art = Art::kReturnHover},
    {.property = "PushedImage", .type = "3", .art = Art::kReturnPushed},
}};

bool near_value(float value, float expect) {
    return std::fabs(value - expect) < 0.01F;
}

bool same_box(const Box& box, const Box& want) {
    const bool is_same_place = near_value(box.x, want.x) && near_value(box.y, want.y);
    return is_same_place && near_value(box.w, want.w) && near_value(box.h, want.h);
}

// Ô của phím ở cột column, hàng row.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): cột rồi hàng, nơi gọi viết số cụ thể (DD-08).
Box cell_at(int column, int row) {
    const float left = kLeft + (static_cast<float>(column) * kStep);
    const float top = kTop + (static_cast<float>(row) * kStep);
    return {.x = left, .y = top, .w = kKey, .h = kKey};
}

// Điểm cách góc trái trên của ô (column, row) một khoảng inset theo cả hai trục.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): cột rồi hàng, nơi gọi viết số cụ thể (DD-08).
Pointer point_in(int column, int row, float inset) {
    const Box cell = cell_at(column, row);
    return {.x = cell.x + inset, .y = cell.y + inset, .is_down = false};
}

void add_window(GuiAsset& asset, std::string_view name, std::int32_t type) {
    gui::GuiWindow window;
    window.name = name;
    window.type = type;
    window.properties.first = static_cast<std::uint32_t>(asset.properties.size());
    asset.windows.push_back(std::move(window));
}

// Thêm một thuộc tính cho cửa sổ vừa thêm (thuộc tính của một cửa sổ nằm liền nhau).
void add_property(GuiAsset& asset, std::string_view name, std::string value) {
    core::check(!asset.windows.empty(), "thuộc tính phải theo sau một cửa sổ");
    gui::GuiProperty added;
    added.name = name;
    added.value = std::move(value);
    asset.properties.push_back(std::move(added));
    ++asset.windows.back().properties.count;
}

void add_art(GuiAsset& asset, const ArtLine& line) {
    const auto index = static_cast<std::int32_t>(line.art);
    const std::string name = "art" + std::to_string(index);
    gui::GuiImage image;
    image.imageset = "Keys";
    image.name = name;
    image.texture = index;
    image.width = 29.0F;
    image.height = 29.0F;
    asset.images.push_back(std::move(image));
    asset.textures.push_back(name + ".png");
    std::string value = "type:";
    value += line.type;
    value += " set:Keys image:";
    value += name;
    add_property(asset, line.property, std::move(value));
}

// Một bàn phím ảo đặt ở (kLeft, kTop) với phím key_size, và một cửa sổ trơn bên cạnh.
GuiAsset board_asset(std::string_view key_size) {
    GuiAsset asset;
    asset.types.push_back(gui::GuiType{.name = "TLBB_SoftKeyWindow", .renderer = "Falagard/SoftKeyWindow"});
    asset.types.push_back(gui::GuiType{.name = "DefaultWindow", .renderer = ""});
    add_window(asset, kBoard, 0);
    add_property(asset, "UnifiedPosition", "{{0,100},{0,50}}");
    add_property(asset, "UnifiedSize", "{{0,466},{0,159}}");
    if (!key_size.empty()) add_property(asset, "KeySize", std::string(key_size));
    for (const ArtLine& line : kArtLines) {
        add_art(asset, line);
    }
    add_window(asset, kPlain, 1);
    add_property(asset, "UnifiedPosition", "{{0,600},{0,50}}");
    add_property(asset, "UnifiedSize", "{{0,100},{0,100}}");
    return asset;
}

Place screen() {
    Place input;
    input.width = 800.0F;
    input.height = 600.0F;
    return input;
}

std::ptrdiff_t count_of(const Sheet& sheet, Art art) {
    const auto is_art = [art](const Quad& quad) { return quad.texture == static_cast<std::int32_t>(art); };
    return std::ranges::count_if(sheet.quads, is_art);
}

bool has_quad(const Sheet& sheet, Art art, const Box& want) {
    const auto is_wanted = [art, &want](const Quad& quad) {
        return quad.texture == static_cast<std::int32_t>(art) && same_box(quad.dest, want);
    };
    return std::ranges::any_of(sheet.quads, is_wanted);
}

// Chỉ số ô của Hub cho một điểm trên bàn phím thử, sau một lần update không chuột.
std::optional<std::size_t> cell_under(const GuiAsset& asset, Pointer pointer) {
    Hub hub(asset);
    hub.update(screen());
    return hub.soft_key(kBoard, pointer);
}

// setKeyPosition: ô (cột, hàng) nằm tại cột x (cỡ phím + 1); thứ tự ô theo resetAllPosition.
void points_map_to_cells(Context& context) {
    const GuiAsset asset = board_asset("w:30 h:30");
    context.expect(cell_under(asset, point_in(1, 1, 0.0F)) == gui::kSoftNumbers.first, "phím số đầu ở cột 1 hàng 1");
    context.expect(cell_under(asset, point_in(10, 1, 29.0F)) == 9U, "phím số cuối ở cột 10 hàng 1");
    context.expect(cell_under(asset, point_in(0, 2, 5.0F)) == gui::kSoftLetters.first, "phím chữ đầu ở hàng 2");
    context.expect(cell_under(asset, point_in(6, 4, 5.0F)) == 35U, "phím chữ cuối ở cột 6 hàng 4");
    context.expect(cell_under(asset, point_in(0, 0, 0.0F)) == gui::kSoftMarks.first, "phím dấu đầu ở góc trái trên");
    context.expect(cell_under(asset, point_in(13, 2, 5.0F)) == 55U, "ô cột 13 hàng 2 là phím dấu, không phải Return");
    context.expect(cell_under(asset, point_in(14, 4, 5.0F)) == 67U, "phím dấu cuối ở góc phải dưới");
    context.expect(cell_under(asset, point_in(13, 0, 5.0F)) == gui::kSoftBack.first, "ô đầu của xoá lùi");
    context.expect(cell_under(asset, point_in(14, 0, 5.0F)) == gui::kSoftBack.first + 1, "ô thứ hai của xoá lùi");
    context.expect(cell_under(asset, point_in(14, 1, 5.0F)) == gui::kSoftShift.first + 1, "ô thứ hai của Shift");
    context.expect(cell_under(asset, point_in(13, 3, 5.0F)) == gui::kSoftReturn.first, "ô đầu của Return");
    context.expect(cell_under(asset, point_in(14, 2, 5.0F)) == gui::kSoftReturn.first + 1, "ô trên của Return");
    context.expect(cell_under(asset, point_in(14, 3, 5.0F)) == gui::kSoftReturn.first + 2, "ô cuối của Return");
}

// getKeyByPosition: mép trái và trên thuộc ô, mép phải và dưới không; khe 1 điểm ảnh không thuộc ô nào.
void gaps_and_outside_hit_nothing(Context& context) {
    const GuiAsset asset = board_asset("w:30 h:30");
    context.expect(!cell_under(asset, point_in(0, 0, 30.0F)), "điểm trên khe giữa hai phím");
    context.expect(!cell_under(asset, point_in(0, 0, -1.0F)), "điểm ngoài góc trái trên");
    context.expect(cell_under(asset, point_in(0, 0, 29.9F)).has_value(), "sát mép phải dưới vẫn thuộc ô");
    context.expect(!cell_under(asset, point_in(14, 4, 30.0F)), "ngay ngoài góc phải dưới của ô cuối");
    context.expect(!cell_under(asset, point_in(15, 0, 5.0F)), "cột 15 nằm ngoài lưới");
    context.expect(!cell_under(asset, point_in(0, 5, 5.0F)), "hàng 5 nằm ngoài lưới");
    Hub hub(asset);
    hub.update(screen());
    const Pointer inside = point_in(1, 1, 5.0F);
    context.expect(!hub.soft_key("NoSuchWindow", inside), "cửa sổ không có thì không có ô nào");
    context.expect(!hub.soft_key(kPlain, Pointer{.x = 610.0F, .y = 60.0F}), "cửa sổ trơn không phải bàn phím ảo");
    Place hidden = screen();
    const std::array<std::string_view, 1> names = {kBoard};
    hidden.hidden = names;
    hub.update(hidden);
    context.expect(!hub.soft_key(kBoard, inside), "bàn phím đang ẩn thì không có ô nào");
}

// setKeySize: cỡ phím theo KeySize của layout; layout không nêu thì 30 x 30.
void key_size_follows_the_layout(Context& context) {
    const GuiAsset wide = board_asset("w:20 h:10");
    const Pointer second_column{.x = kLeft + 21.0F, .y = kTop};
    context.expect(cell_under(wide, second_column) == gui::kSoftMarks.first + 1, "phím rộng 20 thì bước ngang 21");
    const Pointer second_row{.x = kLeft + 21.0F, .y = kTop + 11.0F};
    context.expect(cell_under(wide, second_row) == gui::kSoftNumbers.first, "phím cao 10 thì bước dọc 11");
    const GuiAsset bare = board_asset("");
    context.expect(cell_under(bare, point_in(1, 1, 29.0F)) == gui::kSoftNumbers.first, "không nêu KeySize thì 30 x 30");
}

// populateRenderCache: mỗi phím ký tự một ảnh nền kín ô; ba phím lớn mỗi phím một ảnh rộng hai phím,
// Return nhô lên một hàng phím trên ô đầu của nó.
void plates_cover_every_key(Context& context) {
    const GuiAsset asset = board_asset("w:30 h:30");
    const Sheet sheet = gui::place(asset, screen());
    context.expect(count_of(sheet, Art::kKeyNormal) == 68, "68 phím ký tự, mỗi phím một ảnh nền");
    context.expect(has_quad(sheet, Art::kKeyNormal, cell_at(1, 1)), "ảnh nền của phím số đầu");
    context.expect(has_quad(sheet, Art::kKeyNormal, cell_at(14, 4)), "ảnh nền của phím dấu cuối");
    context.expect(has_quad(sheet, Art::kKeyNormal, cell_at(13, 2)), "ảnh nền của phím dấu cạnh Return");
    const Box back{.x = kLeft + (13.0F * kStep), .y = kTop, .w = 60.0F, .h = 30.0F};
    const Box shift{.x = back.x, .y = kTop + kStep, .w = 60.0F, .h = 30.0F};
    const Box enter{.x = back.x, .y = kTop + (3.0F * kStep) - 30.0F, .w = 60.0F, .h = 60.0F};
    context.expect(count_of(sheet, Art::kBackNormal) == 1 && has_quad(sheet, Art::kBackNormal, back), "xoá lùi");
    context.expect(count_of(sheet, Art::kShiftNormal) == 1 && has_quad(sheet, Art::kShiftNormal, shift), "Shift");
    const bool is_one_enter = count_of(sheet, Art::kReturnNormal) == 1;
    context.expect(is_one_enter && has_quad(sheet, Art::kReturnNormal, enter), "Return cao hai hàng phím");
    context.expect(count_of(sheet, Art::kKeyHover) == 0, "không chuột thì không có ảnh trỏ");
}

// Chữ của phím: mỗi ô một ký tự của Override "Keys", canh giữa ô, nguyên văn.
void faces_follow_the_keys_override(Context& context) {
    const GuiAsset asset = board_asset("w:30 h:30");
    Place input = screen();
    context.expect(gui::place(asset, input).texts.empty(), "không có Keys thì phím không có chữ");
    const std::array<gui::Override, 1> said = {{{.window = kBoard, .name = "Keys", .value = "7#b"}}};
    input.overrides = said;
    const Sheet sheet = gui::place(asset, input);
    context.expect(sheet.texts.size() == 3, "chuỗi ba ký tự thì ba dòng chữ");
    if (sheet.texts.size() != 3) return;
    const TextRun& first = sheet.texts.at(0);
    context.expect(first.text == "7" && same_box(first.box, cell_at(1, 1)), "ký tự đầu ở phím số đầu");
    context.expect(first.horz == 2 && first.vert == 1, "chữ canh giữa ô theo cả hai chiều");
    const TextRun& hash = sheet.texts.at(1);
    context.expect(hash.text == "#" && hash.is_plain, "dấu # của mặt phím là chữ nguyên văn");
    context.expect(same_box(sheet.texts.at(2).box, cell_at(3, 1)), "ký tự thứ ba ở phím số thứ ba");
    const std::string all(100, 'x');
    const std::array<gui::Override, 1> many = {{{.window = kBoard, .name = "Keys", .value = all}}};
    input.overrides = many;
    context.expect(gui::place(asset, input).texts.size() == gui::kSoftCharCells, "ký tự thừa ngoài 68 ô bị bỏ");
}

// Phím dưới chuột vẽ HoverImage, đang nhấn thì PushedImage, cùng ô với ảnh nền; phím lớn sáng cả phím.
void hot_key_shows_hover_then_pushed(Context& context) {
    const GuiAsset asset = board_asset("w:30 h:30");
    Place input = screen();
    input.pointer = point_in(2, 2, 5.0F);
    const Sheet hover = gui::place(asset, input);
    context.expect(count_of(hover, Art::kKeyHover) == 1, "một ảnh trỏ cho phím dưới chuột");
    context.expect(has_quad(hover, Art::kKeyHover, cell_at(2, 2)), "ảnh trỏ nằm đúng ô của phím");
    context.expect(count_of(hover, Art::kKeyNormal) == 68, "ảnh nền của mọi phím vẫn còn");
    input.pointer->is_down = true;
    const Sheet pushed = gui::place(asset, input);
    context.expect(has_quad(pushed, Art::kKeyPushed, cell_at(2, 2)), "đang nhấn thì ảnh nhấn");
    context.expect(count_of(pushed, Art::kKeyHover) == 0, "đang nhấn thì không còn ảnh trỏ");
    input.pointer = point_in(14, 2, 5.0F);
    const Sheet enter = gui::place(asset, input);
    const Box whole{.x = kLeft + (13.0F * kStep), .y = kTop + (2.0F * kStep) + 1.0F, .w = 60.0F, .h = 60.0F};
    context.expect(has_quad(enter, Art::kReturnHover, whole), "trỏ ô trên của Return thì sáng cả phím Return");
    input.pointer = point_in(14, 0, 5.0F);
    const Sheet back = gui::place(asset, input);
    const Box back_box{.x = kLeft + (13.0F * kStep), .y = kTop, .w = 60.0F, .h = 30.0F};
    context.expect(has_quad(back, Art::kBackHover, back_box), "trỏ ô thứ hai của xoá lùi thì sáng cả phím");
    input.pointer = point_in(2, 2, 30.0F);
    const Sheet gap = gui::place(asset, input);
    context.expect(count_of(gap, Art::kKeyHover) == 0, "chuột trên khe thì không phím nào sáng");
    input.pointer = point_in(13, 1, 5.0F);
    const Sheet shift = gui::place(asset, input);
    context.expect(count_of(shift, Art::kShiftNormal) == 1, "layout không khai ảnh trỏ của Shift thì chỉ còn ảnh nền");
}

// Chuột dời sang phím khác trong cùng bàn phím thì Hub phải vẽ lại trang động.
void hub_follows_the_pointer_between_keys(Context& context) {
    const GuiAsset asset = board_asset("w:30 h:30");
    Hub hub(asset);
    Place input = screen();
    input.pointer = point_in(2, 2, 5.0F);
    hub.update(input);
    const std::uint64_t first_stamp = hub.live_stamp();
    const auto is_hover = [](const Quad& quad) { return quad.texture == static_cast<std::int32_t>(Art::kKeyHover); };
    const auto first = std::ranges::find_if(hub.live(), is_hover);
    context.expect(first != hub.live().end() && same_box(first->dest, cell_at(2, 2)), "ảnh trỏ ở phím thứ nhất");
    hub.update(input);
    context.expect(hub.live_stamp() == first_stamp, "chuột đứng yên thì không vẽ lại");
    input.pointer = point_in(3, 2, 5.0F);
    hub.update(input);
    const auto second = std::ranges::find_if(hub.live(), is_hover);
    context.expect(hub.live_stamp() != first_stamp, "chuột sang phím khác thì trang động đổi");
    context.expect(second != hub.live().end() && same_box(second->dest, cell_at(3, 2)), "ảnh trỏ sang phím thứ hai");
    input.pointer = point_in(3, 2, 9.0F);
    const std::uint64_t second_stamp = hub.live_stamp();
    hub.update(input);
    context.expect(hub.live_stamp() == second_stamp, "chuột nhích trong cùng một phím thì không vẽ lại");
}

constexpr std::array kCases{
    Case{.name = "points_map_to_cells", .body = &points_map_to_cells},
    Case{.name = "gaps_and_outside_hit_nothing", .body = &gaps_and_outside_hit_nothing},
    Case{.name = "key_size_follows_the_layout", .body = &key_size_follows_the_layout},
    Case{.name = "plates_cover_every_key", .body = &plates_cover_every_key},
    Case{.name = "faces_follow_the_keys_override", .body = &faces_follow_the_keys_override},
    Case{.name = "hot_key_shows_hover_then_pushed", .body = &hot_key_shows_hover_then_pushed},
    Case{.name = "hub_follows_the_pointer_between_keys", .body = &hub_follows_the_pointer_between_keys},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "gui_softkey_tests: mọi ca phải qua");
    return 0;
}
