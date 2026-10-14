// Đọc giá trị thuộc tính CEGUI (gui/value.hpp) bằng đúng các chuỗi của layout gốc 2026, kể cả chuỗi
// thiếu ngoặc đóng cuối của MainMenuBar mà sscanf của PropertyHelper vẫn đọc được.
// Nguồn: TLBB Dev tests/gui/gui_value_test.cpp@e0d89a6. Khác gốc: khung test của dự án
// (Context::expect).
#include "core/check.hpp"
#include "gui/asset.hpp"
#include "gui/value.hpp"
#include "test.hpp"

#include <array>
#include <cstdint>
#include <string_view>

namespace game::test {
namespace {

using gui::GuiUDim;

bool same(GuiUDim value, float scale, float offset) {
    return value.scale == scale && value.offset == offset;
}

void unified_values(Context& context) {
    const auto position = gui::parse_uvector("{{0.500000,-431.000000},{1.000000,-84.000000}");
    context.expect(position.has_value(), "UVector2 thiếu ngoặc đóng cuối vẫn đọc được");
    if (!position) return;
    const bool is_position = same(position->x, 0.5F, -431.0F) && same(position->y, 1.0F, -84.0F);
    context.expect(is_position, "số của UVector2");
    const auto size = gui::parse_uvector("{{0.000000,862.000000},{0.000000,84.000000}}");
    const bool is_size = size && same(size->x, 0.0F, 862.0F) && same(size->y, 0.0F, 84.0F);
    context.expect(is_size, "cỡ tuyệt đối");
    const auto area = gui::parse_urect("{{0,5},{0,6},{1,-5},{1,-6}}");
    const bool is_area = area && same(area->min.x, 0.0F, 5.0F) && same(area->max.y, 1.0F, -6.0F);
    context.expect(is_area, "URect");
    const GuiUDim spaced = gui::parse_udim(" { 1 , -2.5 } ").value_or(GuiUDim{});
    context.expect(same(spaced, 1.0F, -2.5F), "UDim có dấu cách");
    context.expect(!gui::parse_uvector("{{0.5,1}}"), "thiếu số thì hỏng");
}

void plain_values(Context& context) {
    const bool is_bool =
        gui::parse_bool("True") && gui::parse_bool("true") && !gui::parse_bool("False") && !gui::parse_bool("1");
    context.expect(is_bool, "bool như stringToBool");
    context.expect(gui::parse_float("0.75") == 0.75F, "số thực");
    const auto image = gui::parse_image("set:Button12 image:MainMenuBar_LeftBlock");
    const bool is_named = image && image->set == "Button12" && image->image == "MainMenuBar_LeftBlock";
    context.expect(is_named, "ảnh set:image");
    context.expect(!gui::parse_image("Button12/MainMenuBar"), "ảnh sai dạng");
    // NewExterior_PetPossJian.layout.xml ngắt dòng (CR LF rồi thụt lề) giữa hai nửa; sscanf vẫn tách đúng.
    const auto broken = gui::parse_image("set:NewExterior5\r\n             image:TouShi_Img_Normal");
    const bool is_split = broken && broken->set == "NewExterior5" && broken->image == "TouShi_Img_Normal";
    context.expect(is_split, "xuống dòng giữa set: và image: vẫn là một ảnh");
    const auto padded = gui::parse_image("  set:A \t image:B  ");
    context.expect(padded && padded->set == "A" && padded->image == "B", "khoảng trắng thừa hai đầu và giữa");
    context.expect(!gui::parse_image("set:A image:"), "thiếu tên ảnh");
    context.expect(!gui::parse_image("set:A B image:C"), "tên bộ có dấu cách thì không khớp mẫu");
}

void colour_values(Context& context) {
    context.expect(gui::parse_colour("FF00FF80") == 0xFF00FF80U, "màu ARGB");
    const auto corners = gui::parse_colours("tl:FF000001 tr:FF000002 bl:FF000003 br:FF000004");
    const std::array<std::uint32_t, 4> expected = {0xFF000001U, 0xFF000002U, 0xFF000003U, 0xFF000004U};
    context.expect(corners == expected, "ColourRect bốn góc");
    const auto single = gui::parse_colours("80FFFFFF");
    context.expect(single && single->at(3) == 0x80FFFFFFU, "một màu áp cả bốn góc");
}

// Chuỗi nhiều thẻ của radar và MapImage bản 2026.
void tagged_values(Context& context) {
    const std::string_view arrow = "type:Animate10 animate:Minimap_arrow";
    context.expect(gui::tagged_value(arrow, "type:") == "Animate10", "thẻ đầu");
    context.expect(gui::tagged_value(arrow, "animate:") == "Minimap_arrow", "thẻ cuối");
    context.expect(!gui::tagged_value(arrow, "name:"), "không có thẻ");
    context.expect(!gui::tagged_value("type: animate:X", "type:"), "giá trị rỗng");
    // "mate:" nằm giữa "animate:" nên không phải đầu một thẻ.
    context.expect(!gui::tagged_value(arrow, "mate:"), "khoá phải đứng đầu thẻ");
    const auto child = gui::tagged_image("name:Time3 set:CommonStaticImage image:Minimap_Time3");
    const bool is_child = child && child->set == "CommonStaticImage" && child->image == "Minimap_Time3";
    context.expect(is_child, "ảnh đứng sau thẻ name");
    const auto plain = gui::tagged_image("set:UIIcons image:Map_NPC");
    context.expect(plain && plain->image == "Map_NPC", "ảnh không có thẻ trước");
    context.expect(!gui::tagged_image("type:Animate10 animate:Minimap_arrow"), "không có ảnh");
    context.expect(!gui::tagged_image("reset:A image:B"), "set: phải đứng đầu thẻ");
}

constexpr std::array kCases{
    Case{.name = "unified_values", .body = &unified_values},
    Case{.name = "plain_values", .body = &plain_values},
    Case{.name = "colour_values", .body = &colour_values},
    Case{.name = "tagged_values", .body = &tagged_values},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "gui_value_tests: mọi ca phải qua");
    return 0;
}
