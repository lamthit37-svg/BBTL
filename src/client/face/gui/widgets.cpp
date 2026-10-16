/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/gui/widgets.cpp
 *  PHÂN HỆ   : Face / Gui / Widgets
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bộ vẽ danh sách, cửa sổ phức hợp và ô action của gui (port từ CEGUI của
 *    client 2026).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Bộ vẽ của danh sách (Falagard/Listbox), cửa sổ phức hợp (Falagard/ComplexWindow) và ô action
// (Falagard/ActionButton), cùng phần cuộn của chúng. Port từ mã máy CEGUIBase.dll và
// CEGUIFalagard.dll của client 2026 (docs/GIAO-DIEN-2026.md; địa chỉ hàm gốc ghi ở từng hàm).
// Nội dung (mục, phần tử, vị trí cuộn) đi vào qua Override theo gui/content.hpp; số đo chữ lấy ở
// Place::meter, không có thì danh sách và cửa sổ phức hợp không có mục nào.
// Khác gốc: mục danh sách chỉ có kiểu một dòng (tham số định dạng thứ tư của AddItem chưa có nơi
// dùng); cửa sổ phức hợp mới có phần tử chữ, tiền, giao tử, nút action và Option (Item, ChatBoard,
// HyperLink chưa có script nào trong phạm vi gọi); ô tiền mới giữ chỗ, chưa vẽ; nút action vẽ bốn
// chữ góc qua thuộc tính CornerTopLeft/TopRight/BotLeft/BotRight (bản gốc giữ chuỗi trong widget,
// kèm mã 0xFB/0xFC). Bộ vẽ chữ không nhận mã đã quét đó, nên bóng là một dòng lệch 1px màu 010101
// rồi chữ trắng. Hoạt ảnh hồi chiêu và nháy chưa có. Ô trống chỉ vẽ góc trên phải (drawAcceCorner).

#include "core/number.hpp"
#include "gui/asset.hpp"
#include "gui/content.hpp"
#include "gui/detail/draw.hpp"
#include "gui/scroll.hpp"
#include "gui/sheet.hpp"
#include "gui/value.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <format>
#include <optional>
#include <ranges>
#include <span>
#include <string>
#include <string_view>
#include <type_traits>
#include <utility>
#include <vector>

namespace game::gui::detail {
namespace {

// Font::LineSpace của CEGUIBase.dll 2026 (.rdata 0x1801e7354): cộng vào cao mỗi mục danh sách và
// giữa hai phần tử chữ.
constexpr float kLineSpace = 3.0F;
// ListboxTextItem::draw dời chữ xuống (int)(LineSpace * 0,5 + 0,5) = 2 (Base 0x1800d8f29).
constexpr float kItemTextDrop = 2.0F;
// Khoảng chừa dưới danh sách thả tới đáy màn hình (hằng 20 của ComboDropList::resizeSelf).
constexpr float kDropListBottom = 20.0F;
// GuiTextHorz::kWordWrapLeftAligned: định dạng lớp nối truyền cho AddTextElement.
constexpr std::uint8_t kWrapLeft = 4;
// Ô tiền cao lineSpacing x 1,4 (Fal 0x180137e60).
constexpr float kMoneyRatio = 1.4F;
constexpr std::string_view kParentSuffix = "__auto_parent__";
// Nút Option của cửa sổ phức hợp (FalagardComplexWindow::performWindowLayout, nhánh CT_Option; đọc từ mã nguồn client 2008 cùng
// dòng, chưa đối chiếu mã máy 2026): nút cao lineSpacing x 1,7, mục kế cách (int)(cao x 1,08), và sau phần tử không phải
// Option thì chừa thêm lineSpacing x 2.
constexpr float kOptionRatio = 1.7F;
constexpr float kOptionPitch = 1.08F;
constexpr float kOptionGapRatio = 2.0F;
// Lề trái của nhãn trong look TLBB_Look_QuestButton (AbsoluteDim 10), và bề ngang chừa cho biểu tượng khi look không cho ảnh.
// Khác gốc: chỗ đặt biểu tượng trong nút chưa đo trên mã máy, biểu tượng nằm sát lề trái và chữ dời sang phải bằng bề ngang của nó.
constexpr float kOptionLabelLeft = 10.0F;
constexpr float kOptionIconLeft = 2.0F;

// Các bản ghi của một thuộc tính nội dung; chuỗi rỗng là không có bản ghi nào.
std::vector<std::string_view> records_of(std::string_view blob) {
    std::vector<std::string_view> records;
    if (blob.empty()) return records;
    for (const auto part : blob | std::views::split(kRecordMark)) {
        records.emplace_back(part.begin(), part.end());
    }
    return records;
}

// Trường thứ index của một bản ghi; rỗng khi bản ghi không có đủ trường.
std::string_view field_of(std::string_view record, std::size_t index) noexcept {
    for (std::size_t passed = 0; passed < index; ++passed) {
        const std::size_t mark = record.find(kFieldMark);
        if (mark == std::string_view::npos) return {};
        record.remove_prefix(mark + 1);
    }
    return record.substr(0, record.find(kFieldMark));
}

// Phần còn lại của bản ghi sau trường đầu (chữ của một mục hay một phần tử có thể chứa mọi ký tự).
std::string_view tail_of(std::string_view record) noexcept {
    const std::size_t mark = record.find(kFieldMark);
    return mark == std::string_view::npos ? std::string_view{} : record.substr(mark + 1);
}

std::vector<std::string_view> content_of(const Ctx& ctx, const Placed& self, std::string_view property) {
    return records_of(effective(ctx, self, property).value_or(std::string_view{}));
}

float number_of(const Ctx& ctx, const Placed& self, std::string_view property) {
    const auto text = effective(ctx, self, property);
    return text ? parse_float(*text).value_or(0.0F) : 0.0F;
}

Box intersect(const Box& one, const Box& other) noexcept {
    const float left = std::max(one.x, other.x);
    const float top = std::max(one.y, other.y);
    const float right = std::min(one.x + one.w, other.x + other.w);
    const float bottom = std::min(one.y + one.h, other.y + other.h);
    return Box{.x = left, .y = top, .w = std::max(right - left, 0.0F), .h = std::max(bottom - top, 0.0F)};
}

bool contains(const Box& box, Pointer pointer) noexcept {
    const bool is_across = pointer.x >= box.x && pointer.x < box.x + box.w;
    return is_across && pointer.y >= box.y && pointer.y < box.y + box.h;
}

std::string_view window_font(const Ctx& ctx, const Placed& self) {
    return effective(ctx, self, "Font").value_or(std::string_view{});
}

// Danh sách

// Cao một mục một dòng: cao phông cộng LineSpace (ListboxTextItem::getPixelSize, Base 0x1800d9080);
// 0 khi không có số đo chữ.
float row_height(const Ctx& ctx) noexcept {
    const TextMeter* meter = ctx.input->meter;
    return meter == nullptr ? 0.0F : meter->font_height() + kLineSpace;
}

ListSpan list_span(const Ctx& ctx, const Placed& self) {
    const std::optional<Box> area = named_area(ctx, self, "ItemRenderingArea");
    ListSpan list;
    list.page = area ? area->h : 0.0F;
    list.row = row_height(ctx);
    list.count = list.row > 0.0F ? content_of(ctx, self, kItemsProperty).size() : 0;
    return list;
}

// FalagardListbox::getListRenderArea (Fal 0x180006ae0): thanh cuộn dọc hiện thì dùng vùng
// ItemRenderingAreaVScroll khi look có.
std::optional<Box> list_area(const Ctx& ctx, const Placed& self) {
    if (is_scrollable(self.span)) {
        const std::optional<Box> narrow = named_area(ctx, self, "ItemRenderingAreaVScroll");
        if (narrow) return narrow;
    }
    return named_area(ctx, self, "ItemRenderingArea");
}

// Bề rộng thanh cuộn dọc của cửa sổ self khi nó đang hiện; 0 khi không.
float bar_width(const Ctx& ctx, const Placed& self) {
    if (!is_scrollable(self.span)) return 0.0F;
    const std::string name = self.window->name + "__auto_vscrollbar__";
    const Placed* bar = find_placed(ctx, name);
    return bar == nullptr ? 0.0F : bar->screen.w;
}

// Listbox::populateRenderCache (Base 0x1800d7560): ô mục rộng max(rộng vùng, mục rộng nhất trừ bề
// rộng thanh cuộn đang hiện).
float row_width(const Ctx& ctx, const Placed& self, std::span<const std::string_view> rows, const Box& area) {
    const TextMeter* meter = ctx.input->meter;
    if (meter == nullptr) return area.w;
    float widest = 0.0F;
    for (const std::string_view row : rows) {
        widest = std::max(widest, meter->line_size(tail_of(row)).width);
    }
    return std::max(area.w, widest - bar_width(ctx, self));
}

// Các số chung của mọi ô mục trong một lượt vẽ: vùng mục, vị trí cuộn, cao và rộng một mục.
struct RowFrame {
    Box area;
    float scroll = 0.0F;
    float row = 0.0F;
    float width = 0.0F;
};

// Ô của mục thứ index trên màn hình (itemRect của Listbox::populateRenderCache).
Box row_box(const RowFrame& frame, std::size_t index) noexcept {
    const float top = frame.area.y - frame.scroll + (frame.row * static_cast<float>(index));
    return Box{.x = frame.area.x, .y = top, .w = frame.width, .h = frame.row};
}

// Mục đang chọn: chỉ số trong thuộc tính SelectedItem; nullopt khi vắng, hỏng hay ngoài danh sách.
std::optional<std::size_t> selected_row(const Ctx& ctx, const Placed& self, std::size_t count) {
    const auto text = effective(ctx, self, kSelectedProperty);
    const std::optional<float> number = text ? parse_float(*text) : std::nullopt;
    if (!number || *number < 0.0F || *number >= static_cast<float>(count)) return std::nullopt;
    return static_cast<std::size_t>(*number);
}

// Màu của SelectColour (ColourRect, lấy góc trên trái như mọi ảnh của bản này); vắng thì trắng.
std::uint32_t select_colour(const Ctx& ctx, const Placed& self) {
    const auto text = effective(ctx, self, "SelectColour");
    const std::optional<GuiColours> colours = text ? parse_colours(*text) : std::nullopt;
    return colours ? colours->at(0) : kWhiteArgb;
}

const GuiImage* property_image(const Ctx& ctx, const Placed& self, std::string_view property) {
    const auto text = effective(ctx, self, property);
    const std::optional<ImageName> name = text ? parse_image(*text) : std::nullopt;
    return name ? named_image(ctx, *name) : nullptr;
}

// Cửa sổ phức hợp

// Ô của vùng nội dung (__auto_parent__) trên màn hình, tính thẳng từ <Child> của look để dùng được
// cả lúc con ấy chưa đặt.
std::optional<Box> complex_area(const Ctx& ctx, const Placed& self) {
    const GuiChild* child = look_child(*ctx.asset, self, kParentSuffix);
    if (child == nullptr) return std::nullopt;
    const Box local = area_box(ctx, self, child->area, self.screen);
    return Box{.x = self.screen.x + local.x, .y = self.screen.y + local.y, .w = local.w, .h = local.h};
}

enum class PartKind : std::uint8_t { kText, kMoney, kAction, kOption, kOther };

// Một phần tử đã xếp: ô trong vùng nội dung khi chưa cuộn (d_rectClient), và đối số đầu của nó (chữ
// của phần tử chữ, tên icon của nút action).
struct Part {
    PartKind kind = PartKind::kOther;
    Box box;
    std::string_view body;
    // Chỉ với Option: số lựa chọn trả về cho nơi gọi và chỉ số biểu tượng.
    std::uint32_t option = 0;
    std::int32_t icon = 0;
    // Chỉ với ô tiền: giao tử (AddJiaoZiElement) thay vì tiền thường.
    bool is_jiaozi = false;
};

struct ComplexPlan {
    std::vector<Part> parts;
    float total = 0.0F;
};

PartKind part_kind(std::string_view name) noexcept {
    if (name == kTextElement) return PartKind::kText;
    if (name == kMoneyElement || name == kJiaoZiElement) return PartKind::kMoney;
    if (name == kOptionElement) return PartKind::kOption;
    return name == kActionElement ? PartKind::kAction : PartKind::kOther;
}

// Cỡ "w:<rộng> h:<cao>" của một thuộc tính look (ActionButtonSize, ActionButtonDistance).
struct Extent {
    float w = 0.0F;
    float h = 0.0F;
};

Extent extent_of(const Ctx& ctx, const Placed& self, std::string_view property) {
    const std::string_view text = effective(ctx, self, property).value_or(std::string_view{});
    const TagValue width = tagged_value(text, "w:");
    const TagValue height = tagged_value(text, "h:");
    Extent extent;
    extent.w = width ? parse_float(*width).value_or(0.0F) : 0.0F;
    extent.h = height ? parse_float(*height).value_or(0.0F) : 0.0F;
    return extent;
}

// Trạng thái chạy của performWindowLayout: bút dọc, bút ngang của hàng nút, và loại phần tử trước.
struct Flow {
    float down = 0.0F;
    float across = 0.0F;
    PartKind before = PartKind::kOther;
    bool has_before = false;
    Extent button;
    Extent gap;
    float width = 0.0F;
};

// Một phần tử chữ: cao khối chữ bẻ dòng trong bề rộng vùng, rồi cộng LineSpace (Fal 0x18007450e).
Box flow_text(const TextMeter& meter, Flow& flow, std::string_view text) {
    const float height = meter.formatted_size(text, flow.width, kWrapLeft).height;
    const Box box{.x = 0.0F, .y = flow.down, .w = flow.width, .h = height};
    flow.across = 0.0F;
    flow.down += height + kLineSpace;
    return box;
}

Box flow_money(const TextMeter& meter, Flow& flow) {
    const float height = meter.line_spacing() * kMoneyRatio;
    const Box box{.x = 0.0F, .y = flow.down, .w = flow.width, .h = height};
    flow.across = 0.0F;
    flow.down += height;
    return box;
}

// Số nguyên của một trường bản ghi; 0 khi trường rỗng hay hỏng.
template <typename Number>
Number number_field(std::string_view field) noexcept {
    if constexpr (std::is_signed_v<Number>) {
        const core::OptionalSigned parsed = core::parse_signed(field);
        return parsed && parsed->length == field.size() ? static_cast<Number>(parsed->value) : Number{};
    } else {
        const core::OptionalUnsigned parsed = core::parse_unsigned(field, 10);
        return parsed && parsed->length == field.size() ? static_cast<Number>(parsed->value) : Number{};
    }
}

// Một nút Option: cao lineSpacing x 1,7, xuống hàng; sau phần tử khác loại thì chừa lineSpacing x 2 phía trên.
Box flow_option(const TextMeter& meter, Flow& flow) {
    if (flow.has_before && flow.before != PartKind::kOption) flow.down += meter.line_spacing() * kOptionGapRatio;
    const float height = meter.line_spacing() * kOptionRatio;
    const Box box{.x = 0.0F, .y = flow.down, .w = flow.width, .h = height};
    flow.across = 0.0F;
    flow.down += std::floor(height * kOptionPitch);
    return box;
}

// Một nút action: nối hàng với nút trước khi còn chỗ, không thì xuống hàng; nút cuối cùng của cả
// cửa sổ bỏ khoảng cách thừa bên dưới.
Box flow_action(Flow& flow, std::string_view record, bool is_last) {
    const bool is_after_button = flow.has_before && flow.before == PartKind::kAction;
    if (flow.has_before && !is_after_button) flow.down += flow.gap.h;
    const bool is_rearranged = field_of(record, 2) == "1";
    const bool is_full = flow.across + flow.gap.w + flow.button.w > flow.width;
    if (is_rearranged || is_full) flow.across = 0.0F;
    if (!is_rearranged && !is_full && flow.across != 0.0F) flow.down -= flow.gap.h + flow.button.h;
    const Box box{.x = flow.across, .y = flow.down, .w = flow.button.w, .h = flow.button.h};
    flow.down += flow.gap.h + flow.button.h;
    flow.across += flow.gap.w + flow.button.w;
    if (is_last) flow.down -= flow.gap.h;
    return box;
}

// Xếp một phần tử vào dòng chảy; loại lạ thì không chiếm chỗ (kind là kOther).
Part flow_part(const TextMeter& meter, Flow& flow, std::string_view record, bool is_last) {
    Part part;
    part.kind = part_kind(field_of(record, 0));
    part.body = part.kind == PartKind::kText ? tail_of(record) : field_of(record, 1);
    if (part.kind == PartKind::kText) part.box = flow_text(meter, flow, part.body);
    if (part.kind == PartKind::kMoney) {
        part.box = flow_money(meter, flow);
        part.is_jiaozi = field_of(record, 0) == kJiaoZiElement;
    }
    if (part.kind == PartKind::kAction) part.box = flow_action(flow, record, is_last);
    if (part.kind == PartKind::kOption) {
        part.box = flow_option(meter, flow);
        part.option = number_field<std::uint32_t>(field_of(record, 2));
        part.icon = number_field<std::int32_t>(field_of(record, 3));
    }
    if (part.kind == PartKind::kOther) return part;
    flow.before = part.kind;
    flow.has_before = true;
    return part;
}

// FalagardComplexWindow::performWindowLayout (Fal 0x180074360): xếp dọc các phần tử trong vùng rộng
// area.w. Không có số đo chữ thì không xếp gì.
ComplexPlan plan_complex(const Ctx& ctx, const Placed& self, const Box& area) {
    ComplexPlan plan;
    const TextMeter* meter = ctx.input->meter;
    if (meter == nullptr) return plan;
    const std::vector<std::string_view> records = content_of(ctx, self, kElementsProperty);
    Flow flow;
    flow.button = extent_of(ctx, self, "ActionButtonSize");
    flow.gap = extent_of(ctx, self, "ActionButtonDistance");
    flow.width = area.w;
    plan.parts.reserve(records.size());
    for (std::size_t index = 0; index < records.size(); ++index) {
        const Part part = flow_part(*meter, flow, records[index], index + 1 == records.size());
        if (part.kind != PartKind::kOther) plan.parts.push_back(part);
    }
    plan.total = flow.down;
    return plan;
}

// Ô action

// Trạng thái của một ô action lúc vẽ.
struct ActionFlags {
    bool is_empty = true;
    bool is_disabled = false;
    bool is_gloomy = false;
    bool is_checked = false;
    bool is_hovering = false;
    bool is_pushed = false;
};

// Một lớp phủ của nút: state của look và thuộc tính ảnh đi cùng.
struct Cover {
    std::string_view state;
    std::string_view image;
};

constexpr Cover kHoverCover{.state = "Hover", .image = "HoverImage"};
constexpr Cover kPushedCover{.state = "Pushed", .image = "PushedImage"};
constexpr Cover kDisabledCover{.state = "Disabled", .image = "DisabledImage"};

// doButtonRender(state) rồi ảnh của thuộc tính tương ứng kín ô cửa sổ (FalagardButton::drawHover,
// drawPushed, drawDisabled: Fal 0x1800029c0, 0x180002c70, 0x1800028e0). Look không có state ấy thì
// vẽ Normal.
void overlay(const Ctx& ctx, const Placed& self, const Cover& cover) {
    if (!render_state(ctx, self, cover.state, self.screen)) render_state(ctx, self, "Normal", self.screen);
    const GuiImage* image = property_image(ctx, self, cover.image);
    if (image != nullptr) push_whole(*ctx.sheet, *image, self.screen, kWhiteArgb);
}

// FalagardButton::drawNormal (Fal 0x180002aa0): state Normal rồi icon kéo giãn vào ActionArea của
// look (cả cửa sổ khi look không khai).
void draw_icon(const Ctx& ctx, const Placed& self) {
    render_state(ctx, self, "Normal", self.screen);
    const GuiImage* icon = property_image(ctx, self, "NormalImage");
    if (icon == nullptr) return;
    push_whole(*ctx.sheet, *icon, named_area(ctx, self, "ActionArea").value_or(self.screen), kWhiteArgb);
}

// Các lớp phủ của ô đang giữ action (bước 6 của drawSelf).
void draw_covers(const Ctx& ctx, const Placed& self, const ActionFlags& flags) {
    const bool is_held = flags.is_pushed || flags.is_checked;
    if (flags.is_disabled || flags.is_gloomy) {
        overlay(ctx, self, kDisabledCover);
        if (is_held) overlay(ctx, self, kPushedCover);
        return;
    }
    if (is_held) overlay(ctx, self, kPushedCover);
    if (flags.is_hovering && !flags.is_checked) overlay(ctx, self, kHoverCover);
}

// Bốn góc của drawCorner (docs/GIAO-DIEN-2026.md mục 2.5). on_empty: ô trống chỉ vẽ TopRight.
struct CornerPlace {
    std::string_view property;
    bool is_right = false;
    bool is_bottom = false;
    bool on_empty = false;
};

constexpr std::array<CornerPlace, 4> kCorners{{
    {.property = "CornerTopLeft", .is_right = false, .is_bottom = false, .on_empty = false},
    {.property = "CornerTopRight", .is_right = true, .is_bottom = false, .on_empty = true},
    {.property = "CornerBotLeft", .is_right = false, .is_bottom = true, .on_empty = false},
    {.property = "CornerBotRight", .is_right = true, .is_bottom = true, .on_empty = false},
}};

constexpr std::uint32_t kCornerShadow = 0xFF010101U;
constexpr float kCornerInset = 2.0F;

// Chữ góc khi thuộc tính khác rỗng. Không có số đo chữ thì bỏ, cùng danh sách. Thuộc tính trống thì không vẽ.
void draw_corners(const Ctx& ctx, const Placed& self, bool is_empty) {
    const TextMeter* meter = ctx.input->meter;
    if (meter == nullptr) return;
    const float height = meter->font_height();
    const std::string_view font = window_font(ctx, self);
    const auto right = static_cast<std::uint8_t>(GuiTextHorz::kRightAligned);
    const auto left = static_cast<std::uint8_t>(GuiTextHorz::kLeftAligned);
    for (const CornerPlace& corner : kCorners) {
        if (is_empty && !corner.on_empty) continue;
        const auto text = effective(ctx, self, corner.property);
        if (!text || text->empty()) continue;
        const float edge = corner.is_right ? 0.0F : kCornerInset;
        const float far = corner.is_right ? self.screen.w - kCornerInset : self.screen.w;
        const float top = corner.is_bottom ? self.screen.h - height - kCornerInset : kCornerInset;
        const float width = far - edge;
        const float box_height = self.screen.h - top;
        if (width <= 0.0F || box_height <= 0.0F) continue;
        TextRun shadow;
        shadow.text = *text;
        shadow.box = Box{.x = self.screen.x + edge + 1.0F, .y = self.screen.y + top + 1.0F, .w = width, .h = box_height};
        shadow.rule = TextRule::kRaw;
        shadow.colour = kCornerShadow;
        shadow.horz = corner.is_right ? right : left;
        shadow.is_plain = true;
        shadow.font = font;
        ctx.sheet->texts.push_back(shadow);
        TextRun ink = shadow;
        ink.box.x -= 1.0F;
        ink.box.y -= 1.0F;
        ink.colour = kWhiteArgb;
        ctx.sheet->texts.push_back(ink);
    }
}

// FalagardActionButton::drawSelf (Fal 0x1800abac0) cho cửa sổ self với trạng thái flags.
void paint_action(const Ctx& ctx, const Placed& self, const ActionFlags& flags) {
    render_state(ctx, self, "BackgroundImage", self.screen);
    const GuiImage* back = property_image(ctx, self, "BackImage");
    if (back != nullptr) push_whole(*ctx.sheet, *back, self.screen, kWhiteArgb);
    if (flags.is_empty) {
        const bool is_touched = (flags.is_hovering || flags.is_pushed) && !flags.is_disabled;
        if (is_touched) overlay(ctx, self, kHoverCover);
        draw_corners(ctx, self, true);
        return;
    }
    draw_icon(ctx, self);
    draw_covers(ctx, self, flags);
    draw_corners(ctx, self, false);
}

// Kiểu cửa sổ của một khoá ChildItem ("key:<khoá> name:<kiểu>") trong look của cửa sổ phức hợp.
const GuiType* child_item_type(const Ctx& ctx, const Placed& self, std::string_view key) {
    if (self.look == nullptr || !in_range(ctx.asset->properties.size(), self.look->properties)) return nullptr;
    const GuiRange range = self.look->properties;
    const auto properties = std::span(ctx.asset->properties).subspan(range.first, range.count);
    const auto is_item = [key](const GuiProperty& property) {
        return property.name == "ChildItem" && tagged_value(property.value, "key:") == key;
    };
    const auto found = std::ranges::find_if(properties, is_item);
    if (found == properties.end()) return nullptr;
    const TagValue name = tagged_value(found->value, "name:");
    const auto type = std::ranges::find(ctx.asset->types, name.value_or(std::string_view{}), &GuiType::name);
    return type == ctx.asset->types.end() ? nullptr : &*type;
}

// Nút action của một phần tử (AddChildElement_Action, Fal 0x1800707a0): cửa sổ kiểu của khoá
// ActionButton cỡ box, Empty = False, NormalImage = icon; vẽ bằng look của kiểu đó.
void draw_part_button(const Ctx& ctx, const Placed& self, const Part& part, const Box& box) {
    const GuiType* type = child_item_type(ctx, self, "ActionButton");
    const bool has_look = type != nullptr && type->look >= 0 && std::cmp_less(type->look, ctx.asset->looks.size());
    if (!has_look) return;
    Placed button;
    button.window = self.window;
    button.type = type;
    button.look = &ctx.asset->looks.at(static_cast<std::size_t>(type->look));
    button.kind = Kind::kAction;
    button.screen = box;
    button.is_visible = true;
    render_state(ctx, button, "BackgroundImage", box);
    render_state(ctx, button, "Normal", box);
    const std::optional<ImageName> name = parse_image(part.body);
    const GuiImage* icon = name ? named_image(ctx, *name) : nullptr;
    if (icon != nullptr) push_whole(*ctx.sheet, *icon, named_area(ctx, button, "ActionArea").value_or(box), kWhiteArgb);
}

// Cửa sổ thành tích

// Phần còn lại của bản ghi sau count trường đầu; rỗng khi bản ghi không đủ trường.
std::string_view after_fields(std::string_view record, std::size_t count) noexcept {
    for (std::size_t passed = 0; passed < count; ++passed) {
        const std::size_t mark = record.find(kFieldMark);
        if (mark == std::string_view::npos) return {};
        record.remove_prefix(mark + 1);
    }
    return record;
}

// Ảnh biểu tượng của nút Option theo chỉ số (thuộc tính QuestButtonImage "index:<n> set:<bộ> image:<tên>" của look cửa sổ
// phức hợp); nullptr khi look không khai chỉ số đó.
const GuiImage* option_icon(const Ctx& ctx, const Placed& self, std::int32_t index) {
    if (self.look == nullptr || !in_range(ctx.asset->properties.size(), self.look->properties)) return nullptr;
    const GuiRange range = self.look->properties;
    const auto properties = std::span(ctx.asset->properties).subspan(range.first, range.count);
    for (const GuiProperty& property : properties) {
        if (property.name != "QuestButtonImage") continue;
        const TagValue wanted = tagged_value(property.value, "index:");
        if (!wanted || number_field<std::int32_t>(*wanted) != index) continue;
        const std::size_t set_at = property.value.find("set:");
        if (set_at == std::string::npos) return nullptr;
        const std::optional<ImageName> name = parse_image(std::string_view(property.value).substr(set_at));
        return name ? named_image(ctx, *name) : nullptr;
    }
    return nullptr;
}

// Cửa sổ giả đứng cho nút của phần tử: look của kiểu ChildItem, ô đã xếp. Look vắng thì look
// nullptr và mọi lệnh vẽ trên nó không làm gì.
Placed button_of(const Ctx& ctx, const Placed& self, std::string_view key, const Box& box) {
    Placed button;
    button.window = self.window;
    button.screen = box;
    button.is_visible = true;
    const GuiType* type = child_item_type(ctx, self, key);
    const bool has_look = type != nullptr && type->look >= 0 && std::cmp_less(type->look, ctx.asset->looks.size());
    if (!has_look) return button;
    button.type = type;
    button.look = &ctx.asset->looks.at(static_cast<std::size_t>(type->look));
    return button;
}

// Nhãn cờ của bản ghi: có ký tự flag không.
bool has_flag(std::string_view flags, char flag_mark) noexcept {
    return flags.contains(flag_mark);
}

// Ô của nút phần tử: vùng tên khoá của look cửa sổ cho vị trí ngang, cao và rộng; mép trên của vùng
// cộng với chỗ đã đi qua (updateItemPos của FalagardAchievementWindow, Fal 0x1800d7e60).
struct CatalogSlot {
    Box area;
    float top = 0.0F;
};

std::optional<CatalogSlot> slot_of(const Ctx& ctx, const Placed& self, std::string_view key) {
    const std::optional<Box> area = named_area(ctx, self, key);
    if (!area) return std::nullopt;
    return CatalogSlot{.area = *area, .top = area->y - self.screen.y};
}

// Ô tiền (FalagardMoney::populateRenderCache, Fal 0x180082510)

// Lề phải khi canh phải (.rdata 0x1801319c0).
constexpr float kMoneyEdge = 4.0F;
// Vàng = số / 10000, bạc = (số % 10000) / 100, đồng = số % 100.
constexpr std::int32_t kCopperPerGold = 10000;
constexpr std::int32_t kCopperPerSilver = 100;
// HorzFormatting của CEGUI: 1 là RightAligned.
constexpr std::string_view kRightAligned = "RightAligned";

// Một phần của số tiền: số và icon đứng ngay sau nó, đều chạm đáy cửa sổ.
struct MoneyPiece {
    std::string text;
    Box text_box;
    const GuiImage* icon = nullptr;
    Box icon_box;
};

struct MoneyPlan {
    std::vector<MoneyPiece> pieces;
    std::uint32_t colour = kWhiteArgb;
};

// Ba đồng tiền theo thứ tự vàng, bạc, đồng: chỉ số vào MoneyLayout::icons và tên thuộc tính giữ icon của chúng.
inline constexpr std::size_t kGoldCoin = 0;
inline constexpr std::size_t kSilverCoin = 1;
inline constexpr std::size_t kCopperCoin = 2;
inline constexpr std::array<std::string_view, 3> kCoinProperties = {"GoldIcon", "SilverIcon", "CopperIcon"};
// Icon mặc định của look TLBB_Look_Money (TLBBLook_StaticText.looknfeel.xml:259) và TLBB_Look_JiaoZi (dòng 809), cho ô tiền
// con của cửa sổ phức hợp (AddMoneyElement, AddJiaoZiElement).
inline constexpr std::array<std::string_view, 3> kMoneyLookIcons = {
    "set:Button2 image:Icon_GoldCoin", "set:Button2 image:Icon_SilverCoin", "set:Button2 image:Icon_CopperCoin"};
inline constexpr std::array<std::string_view, 3> kJiaoZiLookIcons = {
    "set:Button6 image:Lace_JiaoziJin", "set:Button6 image:Lace_JiaoziYin", "set:Button6 image:Lace_JiaoziTong"};

// Một phần chưa đặt chỗ: giá trị đã đổi thành chữ và đồng tiền của nó.
struct MoneyShare {
    std::int32_t value = 0;
    bool is_padded = false;
    std::size_t coin = kCopperCoin;
};

// Phần vàng chỉ hiện khi dương, bạc khi bạc hay vàng dương, đồng luôn hiện. AlignFix đệm bạc và đồng
// cho rộng hai chữ số ("%2d"), vàng thì không.
std::vector<MoneyShare> money_shares(std::int32_t money, bool is_aligned) {
    const std::int32_t gold = money / kCopperPerGold;
    const std::int32_t silver = (money % kCopperPerGold) / kCopperPerSilver;
    const std::int32_t copper = money % kCopperPerSilver;
    std::vector<MoneyShare> shares;
    if (gold > 0) shares.push_back(MoneyShare{.value = gold, .is_padded = false, .coin = kGoldCoin});
    if (gold > 0 || silver > 0) shares.push_back(MoneyShare{.value = silver, .is_padded = is_aligned, .coin = kSilverCoin});
    shares.push_back(MoneyShare{.value = copper, .is_padded = is_aligned, .coin = kCopperCoin});
    return shares;
}

// Màu số: MoneyColor, hay MoneyMaxColour khi MoneyMaxNumber không âm mà nhỏ hơn số tiền (modifyFinalColor).
std::uint32_t money_colour(const Ctx& ctx, const Placed& self, std::int32_t money) {
    const auto max_text = effective(ctx, self, "MoneyMaxNumber");
    const std::optional<int> most = max_text ? core::parse_whole_int(*max_text) : std::nullopt;
    const bool is_over = most && *most >= 0 && *most < money;
    const auto tint = effective(ctx, self, is_over ? "MoneyMaxColour" : "MoneyColor");
    return tint ? parse_colour(*tint).value_or(kWhiteArgb) : kWhiteArgb;
}

// Mọi thứ phần xếp ô tiền cần: số tiền, kiểu canh và đệm, màu, ô màn hình của cửa sổ tiền và ba icon.
struct MoneyLayout {
    std::int32_t money = 0;
    bool is_aligned = false;
    bool is_right = false;
    std::uint32_t colour = kWhiteArgb;
    Box area;
    std::array<const GuiImage*, 3> icons{};
};

// Xếp các phần từ trái sang phải trong ô area, chạm đáy.
MoneyPlan lay_money(const TextMeter& meter, const MoneyLayout& layout) {
    MoneyPlan plan;
    plan.colour = layout.colour;
    const std::vector<MoneyShare> shares = money_shares(layout.money, layout.is_aligned);
    const Box& screen = layout.area;
    const float window_height = screen.h;
    float total = 0.0F;
    plan.pieces.reserve(shares.size());
    for (const MoneyShare& share : shares) {
        MoneyPiece piece;
        piece.text = share.is_padded ? std::format("{:2}", share.value) : std::format("{}", share.value);
        piece.icon = layout.icons.at(share.coin);
        const TextSize size = meter.formatted_size(piece.text, screen.w, 0);
        const float icon_w = piece.icon != nullptr ? piece.icon->width : 0.0F;
        const float icon_h = piece.icon != nullptr ? piece.icon->height : 0.0F;
        piece.text_box = Box{.x = total, .y = window_height - size.height, .w = size.width, .h = size.height};
        piece.icon_box = Box{.x = total + size.width, .y = window_height - icon_h, .w = icon_w, .h = icon_h};
        total += size.width + icon_w;
        plan.pieces.push_back(std::move(piece));
    }
    const float start = layout.is_right ? screen.w - total - kMoneyEdge : 0.0F;
    const auto place = [&screen, start](Box& box) {
        box.x += screen.x + start;
        box.y += screen.y;
    };
    for (MoneyPiece& piece : plan.pieces) {
        place(piece.text_box);
        place(piece.icon_box);
    }
    return plan;
}

// Ô tiền của một cửa sổ Falagard/Money: số, màu, canh và icon đều là thuộc tính của cửa sổ. Không có số đo chữ thì không xếp gì.
MoneyPlan plan_money(const Ctx& ctx, const Placed& self) {
    const TextMeter* meter = ctx.input->meter;
    if (meter == nullptr) return {};
    const auto number = effective(ctx, self, "MoneyNumber");
    MoneyLayout layout;
    layout.money = number ? core::parse_whole_int(*number).value_or(0) : 0;
    layout.is_aligned = flag(ctx, self, "AlignFix");
    const auto horz = effective(ctx, self, "HorzFormatting");
    layout.is_right = horz && *horz == kRightAligned;
    layout.colour = money_colour(ctx, self, layout.money);
    layout.area = self.screen;
    for (std::size_t coin = 0; coin < kCoinProperties.size(); ++coin) {
        layout.icons.at(coin) = property_image(ctx, self, kCoinProperties.at(coin));
    }
    return lay_money(*meter, layout);
}

} // namespace

float drop_list_height(const Ctx& ctx, const Placed& self) {
    const std::size_t rows = content_of(ctx, self, kItemsProperty).size();
    const std::optional<Box> area = named_area(ctx, self, "ItemRenderingArea");
    const float margin = area ? area->y - self.screen.y : 0.0F;
    const float wanted = (static_cast<float>(rows) * row_height(ctx)) + (margin * 2.0F);
    const float room = ctx.input->height - self.screen.y - kDropListBottom;
    return std::min(wanted, room);
}

ScrollView scroll_view(const Ctx& ctx, const Placed& self) {
    ScrollView view;
    if (self.kind == Kind::kList) {
        const ListSpan list = list_span(ctx, self);
        view.span = list.scroll();
        view.row = list.row;
    }
    if (self.kind == Kind::kComplex) {
        const std::optional<Box> area = complex_area(ctx, self);
        const Box content = area.value_or(Box{});
        view.span = ScrollSpan{.document = plan_complex(ctx, self, content).total, .page = content.h};
    }
    view.position = clamp_scroll(view.span, number_of(ctx, self, kScrollProperty));
    return view;
}

ThumbTrack thumb_track(const Ctx& ctx, const Placed& bar) {
    const std::optional<Box> area = named_area(ctx, bar, "ThumbTrackArea");
    const std::string name = bar.window->name + "__auto_thumb__";
    const Placed* thumb = find_placed(ctx, name);
    if (!area || thumb == nullptr) return {};
    return ThumbTrack{.top = area->y, .slide = area->h - thumb->screen.h};
}

std::optional<Box> content_area(const Ctx& ctx, const Placed& self) {
    if (self.kind == Kind::kList) return list_area(ctx, self);
    if (self.kind == Kind::kComplex) return complex_area(ctx, self);
    return std::nullopt;
}

std::optional<std::size_t> list_item_under(const Ctx& ctx, const Placed& self, Pointer pointer) {
    if (self.kind != Kind::kList) return std::nullopt;
    const std::optional<Box> area = list_area(ctx, self);
    if (!area || !contains(*area, pointer)) return std::nullopt;
    const ListProbe probe{.position = self.scroll, .down = pointer.y - area->y};
    const std::size_t count = content_of(ctx, self, kItemsProperty).size();
    return item_at(ListSpan{.page = area->h, .row = self.row, .count = count}, probe);
}

// Listbox::populateRenderCache (Base 0x1800d7560), phần ảnh: nền của look rồi nền của mục đang chọn
// (SelectBrush kéo giãn kín ô mục, nhân SelectColour, cắt theo vùng mục).
void draw_list(const Ctx& ctx, const Placed& self) {
    render_state(ctx, self, flag(ctx, self, "Disabled") ? "Disabled" : "Enabled", self.screen);
    const std::vector<std::string_view> rows = content_of(ctx, self, kItemsProperty);
    const std::optional<std::size_t> chosen = selected_row(ctx, self, rows.size());
    const std::optional<Box> area = list_area(ctx, self);
    const GuiImage* brush = property_image(ctx, self, "SelectBrush");
    if (!chosen || !area || brush == nullptr || self.row <= 0.0F) return;
    const float width = row_width(ctx, self, rows, *area);
    const RowFrame frame{.area = *area, .scroll = self.scroll, .row = self.row, .width = width};
    const std::size_t first = ctx.sheet->quads.size();
    push_whole(*ctx.sheet, *brush, row_box(frame, *chosen), select_colour(ctx, self));
    clip_quads(*ctx.sheet, first, *area);
}

// Listbox::populateRenderCache, phần chữ (ListboxTextItem::draw, Base 0x1800d8e00): mỗi mục một lời
// drawText canh trái vào ô mục dời xuống 2, màu của mục, cắt theo phần ô mục nằm trong vùng mục.
void list_texts(const Ctx& ctx, const Placed& self) {
    const std::vector<std::string_view> rows = content_of(ctx, self, kItemsProperty);
    const std::optional<Box> area = list_area(ctx, self);
    if (!area || self.row <= 0.0F) return;
    const float width = row_width(ctx, self, rows, *area);
    const RowFrame frame{.area = *area, .scroll = self.scroll, .row = self.row, .width = width};
    const std::string_view font = window_font(ctx, self);
    for (std::size_t index = 0; index < rows.size(); ++index) {
        const Box box = row_box(frame, index);
        const Box clip = intersect(box, *area);
        if (clip.w <= 0.0F || clip.h <= 0.0F) continue;
        TextRun run;
        run.text = tail_of(rows[index]);
        run.box = Box{.x = box.x, .y = box.y + kItemTextDrop, .w = box.w, .h = box.h - kItemTextDrop};
        run.clip = clip;
        run.rule = TextRule::kRaw;
        run.colour = parse_colour(field_of(rows[index], 0)).value_or(kWhiteArgb);
        run.font = font;
        ctx.sheet->texts.push_back(run);
    }
}

namespace {

// Ô trên màn hình của một phần tử đã xếp, sau khi cuộn.
Box part_screen_box(const Box& area, const Part& part, float scroll) {
    return Box{.x = area.x + pixel_align(part.box.x),
        .y = area.y + pixel_align(part.box.y - scroll),
        .w = part.box.w,
        .h = part.box.h};
}

// Ô tiền con của cửa sổ phức hợp (AddMoneyElement): cửa sổ TLBB_Money với icon mặc định của look, canh trái, chữ trắng.
MoneyPlan plan_part_money(const Ctx& ctx, const Box& content, const Part& part, float scroll) {
    const TextMeter* meter = ctx.input->meter;
    if (meter == nullptr) return {};
    MoneyLayout layout;
    layout.money = core::parse_whole_int(part.body).value_or(0);
    layout.area = part_screen_box(content, part, scroll);
    const std::array<std::string_view, 3>& look = part.is_jiaozi ? kJiaoZiLookIcons : kMoneyLookIcons;
    for (std::size_t coin = 0; coin < look.size(); ++coin) {
        const std::optional<ImageName> name = parse_image(look.at(coin));
        layout.icons.at(coin) = name ? named_image(ctx, *name) : nullptr;
    }
    return lay_money(*meter, layout);
}

// Nút Option: state Normal, Hover khi trỏ vào, Pushed khi đang nhấn (look TLBB_Look_QuestButton), rồi biểu tượng.
void draw_option_button(const Ctx& ctx, const Placed& self, const Part& part, const Box& box) {
    const Placed button = button_of(ctx, self, "Option", box);
    const bool is_hot = ctx.input->pointer && contains(box, *ctx.input->pointer);
    const std::string_view state = is_hot ? (ctx.is_down ? "Pushed" : "Hover") : "Normal";
    if (!render_state(ctx, button, state, box)) render_state(ctx, button, "Normal", box);
    const GuiImage* icon = option_icon(ctx, self, part.icon);
    if (icon == nullptr) return;
    const float height = std::min(icon->height, box.h);
    const Box dest{.x = box.x + kOptionIconLeft,
        .y = box.y + ((box.h - height) * 0.5F),
        .w = icon->width,
        .h = height};
    push_whole(*ctx.sheet, *icon, dest, kWhiteArgb);
}

} // namespace

// Cửa sổ phức hợp không có nền riêng; ảnh của nó là các nút action và nút Option của phần tử, đặt ở vị trí đã làm
// tròn như Window::setPosition chế độ Absolute và cắt theo vùng nội dung.
void draw_complex(const Ctx& ctx, const Placed& self) {
    const std::optional<Box> area = complex_area(ctx, self);
    if (!area) return;
    const ComplexPlan plan = plan_complex(ctx, self, *area);
    const std::size_t first = ctx.sheet->quads.size();
    for (const Part& part : plan.parts) {
        if (part.kind == PartKind::kMoney) {
            for (const MoneyPiece& piece : plan_part_money(ctx, *area, part, self.scroll).pieces) {
                if (piece.icon != nullptr) push_whole(*ctx.sheet, *piece.icon, piece.icon_box, kWhiteArgb);
            }
            continue;
        }
        if (part.kind != PartKind::kAction && part.kind != PartKind::kOption) continue;
        const Box box = part_screen_box(*area, part, self.scroll);
        if (part.kind == PartKind::kAction) draw_part_button(ctx, self, part, box);
        if (part.kind == PartKind::kOption) draw_option_button(ctx, self, part, box);
    }
    clip_quads(*ctx.sheet, first, *area);
}

std::optional<std::uint32_t> complex_option_under(const Ctx& ctx, const Placed& self, Pointer pointer) {
    if (self.kind != Kind::kComplex) return std::nullopt;
    const std::optional<Box> area = complex_area(ctx, self);
    if (!area || !contains(*area, pointer)) return std::nullopt;
    const ComplexPlan plan = plan_complex(ctx, self, *area);
    for (const Part& part : plan.parts) {
        if (part.kind == PartKind::kOption && contains(part_screen_box(*area, part, self.scroll), pointer)) {
            return part.option;
        }
    }
    return std::nullopt;
}

namespace {

// Nhãn của nút Option: một dòng canh trái vào ô nút (lề trái của section label), canh giữa theo chiều dọc, chừa chỗ cho biểu
// tượng; trắng khi thường, màu HoverTextColour của look nút khi trỏ vào hay đang nhấn.
void option_text(const Ctx& ctx, const Placed& self, const Part& part, const Box& area, std::string_view font) {
    const Box box = part_screen_box(area, part, self.scroll);
    const Placed button = button_of(ctx, self, "Option", box);
    const bool is_hot = ctx.input->pointer && contains(box, *ctx.input->pointer);
    std::uint32_t colour = kWhiteArgb;
    if (is_hot && button.look != nullptr) {
        const auto tint = effective(ctx, button, ctx.is_down ? "PushedTextColour" : "HoverTextColour");
        if (tint) colour = parse_colour(*tint).value_or(kWhiteArgb);
    }
    const GuiImage* icon = option_icon(ctx, self, part.icon);
    const float left = kOptionLabelLeft + (icon != nullptr ? icon->width : 0.0F);
    TextRun run;
    run.text = part.body;
    run.box = Box{.x = box.x + left, .y = box.y, .w = std::max(box.w - left, 0.0F), .h = box.h};
    run.clip = intersect(box, area);
    // Nhãn của nút là TextComponent của look: canh giữa theo chiều dọc ngang tâm biểu tượng (kRaw sẽ vẽ từ mép trên của ô).
    run.rule = TextRule::kComponent;
    run.horz = kWrapLeft;
    run.vert = std::to_underlying(GuiTextVert::kCentreAligned);
    run.colour = colour;
    run.font = font;
    ctx.sheet->texts.push_back(run);
}

} // namespace

// ParentWindow::populateRenderCache (Fal 0x180074c70): mỗi phần tử chữ một lời drawText bẻ dòng
// canh trái, màu TextColor; chỉ mép trên của ô dời theo vị trí cuộn. Chữ cắt theo vùng nội dung.
void complex_texts(const Ctx& ctx, const Placed& self) {
    const std::optional<Box> area = complex_area(ctx, self);
    if (!area) return;
    const ComplexPlan plan = plan_complex(ctx, self, *area);
    const auto tint = effective(ctx, self, "TextColor");
    const std::uint32_t colour = tint ? parse_colour(*tint).value_or(kWhiteArgb) : kWhiteArgb;
    const std::string_view font = window_font(ctx, self);
    for (const Part& part : plan.parts) {
        const float top = part.box.y - self.scroll;
        const bool is_seen = top < area->h && part.box.y + part.box.h - self.scroll > 0.0F;
        if (!is_seen) continue;
        if (part.kind == PartKind::kMoney) {
            const MoneyPlan money = plan_part_money(ctx, *area, part, self.scroll);
            for (const MoneyPiece& piece : money.pieces) {
                ctx.sheet->made.push_back(piece.text);
                TextRun number;
                number.text = ctx.sheet->made.back();
                number.box = piece.text_box;
                number.clip = *area;
                number.rule = TextRule::kRaw;
                number.colour = money.colour;
                number.is_plain = true;
                number.font = font;
                ctx.sheet->texts.push_back(number);
            }
            continue;
        }
        if (part.kind != PartKind::kText && part.kind != PartKind::kOption) continue;
        if (part.kind == PartKind::kOption) {
            option_text(ctx, self, part, *area, font);
            continue;
        }
        TextRun run;
        run.text = part.body;
        run.box = Box{.x = area->x, .y = area->y + top, .w = part.box.w, .h = part.box.h + self.scroll};
        run.clip = *area;
        run.rule = TextRule::kRaw;
        run.horz = kWrapLeft;
        run.colour = colour;
        run.font = font;
        ctx.sheet->texts.push_back(run);
    }
}

// FalagardActionButton::drawSelf cho một cửa sổ của layout: ô trống cho tới khi thuộc tính Empty
// là False (SetActionItem), Checked là SetPushed, Gloom là action đang bị khoá.
void draw_action(const Ctx& ctx, const Placed& self) {
    const auto empty = effective(ctx, self, "Empty");
    const bool is_hot = ctx.hot == &self;
    ActionFlags flags;
    flags.is_empty = !empty || parse_bool(*empty);
    flags.is_disabled = flag(ctx, self, "Disabled");
    flags.is_gloomy = flag(ctx, self, "Gloom");
    flags.is_checked = flag(ctx, self, "Checked");
    flags.is_pushed = is_hot && ctx.is_down;
    flags.is_hovering = is_hot && !ctx.is_down;
    paint_action(ctx, self, flags);
}

std::vector<CatalogItem> catalog_items(const Ctx& ctx, const Placed& self) {
    std::vector<CatalogItem> items;
    const std::vector<std::string_view> records = content_of(ctx, self, kElementsProperty);
    float down = 0.0F;
    for (std::size_t index = 0; index < records.size(); ++index) {
        const std::string_view record = records[index];
        const std::string_view flags = field_of(record, 1);
        if (has_flag(flags, kHiddenFlag)) continue;
        const std::string_view key = field_of(record, 0);
        const std::optional<CatalogSlot> slot = slot_of(ctx, self, key);
        if (!slot) continue;
        CatalogItem item;
        item.index = index;
        item.key = key;
        item.hover = field_of(record, 2);
        item.text = after_fields(record, 3);
        item.is_selected = has_flag(flags, kSelectedFlag);
        item.box = Box{.x = slot->area.x, .y = self.screen.y + slot->top + down, .w = slot->area.w, .h = slot->area.h};
        items.push_back(item);
        down += slot->top + slot->area.h;
    }
    return items;
}

Placed catalog_button(const Ctx& ctx, const Placed& self, const CatalogItem& item) {
    return button_of(ctx, self, item.key, item.box);
}

std::optional<std::size_t> catalog_item_under(const Ctx& ctx, const Placed& self, Pointer pointer) {
    if (!contains(self.screen, pointer)) return std::nullopt;
    const std::vector<CatalogItem> items = catalog_items(ctx, self);
    const auto found =
        std::ranges::find_if(items, [pointer](const CatalogItem& item) { return contains(item.box, pointer); });
    if (found == items.end()) return std::nullopt;
    return found->index;
}

// Ảnh của các nút: section "background" của look nút (state EnabledBackground) rồi section sáng khi
// trỏ vào hay đang chọn (FalagardAchievementWindowCatalogButton::populateRenderCache, Fal
// 0x1800e1bb0; TextButton tương tự ở 0x18004fa90). Cắt theo ô cửa sổ vì phần tử dài hơn ô thì chỉ
// thấy phần trong ô.
void draw_catalog(const Ctx& ctx, const Placed& self) {
    const std::vector<CatalogItem> items = catalog_items(ctx, self);
    const std::optional<std::size_t> under =
        ctx.input->pointer ? catalog_item_under(ctx, self, *ctx.input->pointer) : std::nullopt;
    const std::size_t first = ctx.sheet->quads.size();
    for (const CatalogItem& item : items) {
        const Placed button = catalog_button(ctx, self, item);
        render_state(ctx, button, "EnabledBackground", item.box);
        const bool is_lit = item.is_selected || (under && *under == item.index);
        if (is_lit && !item.hover.empty()) render_state(ctx, button, item.hover, item.box);
    }
    clip_quads(*ctx.sheet, first, self.screen);
}

// Icon vàng, bạc, đồng đứng sau từng số, ở kích cỡ gốc của ảnh.
void draw_money(const Ctx& ctx, const Placed& self) {
    const MoneyPlan plan = plan_money(ctx, self);
    for (const MoneyPiece& piece : plan.pieces) {
        if (piece.icon != nullptr) push_whole(*ctx.sheet, *piece.icon, piece.icon_box, kWhiteArgb);
    }
}

// Các số của ô tiền, mỗi số một ô vừa khít chữ, thẳng vào Font::drawText không canh dọc.
void money_texts(const Ctx& ctx, const Placed& self) {
    const MoneyPlan plan = plan_money(ctx, self);
    for (const MoneyPiece& piece : plan.pieces) {
        ctx.sheet->made.push_back(piece.text);
        TextRun run;
        run.text = ctx.sheet->made.back();
        run.box = piece.text_box;
        run.rule = TextRule::kRaw;
        run.colour = plan.colour;
        run.is_plain = true;
        run.font = window_font(ctx, self);
        ctx.sheet->texts.push_back(run);
    }
}

} // namespace game::gui::detail
