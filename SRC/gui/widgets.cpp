// Bộ vẽ của danh sách (Falagard/Listbox), cửa sổ phức hợp (Falagard/ComplexWindow) và ô action
// (Falagard/ActionButton), cùng phần cuộn của chúng. Port từ mã máy CEGUIBase.dll và
// CEGUIFalagard.dll của client 2026 (docs/GIAO-DIEN-2026.md; địa chỉ hàm gốc ghi ở từng hàm).
// Nội dung (mục, phần tử, vị trí cuộn) đi vào qua Override theo gui/content.hpp; số đo chữ lấy ở
// Place::meter, không có thì danh sách và cửa sổ phức hợp không có mục nào.
// Khác gốc: mục danh sách chỉ có kiểu một dòng (tham số định dạng thứ tư của AddItem chưa có nơi
// dùng); cửa sổ phức hợp mới có phần tử chữ, tiền, giao tử và nút action (Option, Item, ChatBoard,
// HyperLink chưa có script nào trong phạm vi gọi); ô tiền mới giữ chỗ, chưa vẽ; nút action chưa có
// chữ góc, hoạt ảnh hồi chiêu và nháy.
#include "gui/asset.hpp"
#include "gui/content.hpp"
#include "gui/detail/draw.hpp"
#include "gui/scroll.hpp"
#include "gui/sheet.hpp"
#include "gui/value.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <ranges>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::gui::detail {
namespace {

// Font::LineSpace của CEGUIBase.dll 2026 (.rdata 0x1801e7354): cộng vào cao mỗi mục danh sách và
// giữa hai phần tử chữ.
constexpr float kLineSpace = 3.0F;
// ListboxTextItem::draw dời chữ xuống (int)(LineSpace * 0,5 + 0,5) = 2 (Base 0x1800d8f29).
constexpr float kItemTextDrop = 2.0F;
// GuiTextHorz::kWordWrapLeftAligned: định dạng lớp nối truyền cho AddTextElement.
constexpr std::uint8_t kWrapLeft = 4;
// Ô tiền cao lineSpacing x 1,4 (Fal 0x180137e60).
constexpr float kMoneyRatio = 1.4F;
constexpr std::string_view kParentSuffix = "__auto_parent__";

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

enum class PartKind : std::uint8_t { kText, kMoney, kAction, kOther };

// Một phần tử đã xếp: ô trong vùng nội dung khi chưa cuộn (d_rectClient), và đối số đầu của nó (chữ
// của phần tử chữ, tên icon của nút action).
struct Part {
    PartKind kind = PartKind::kOther;
    Box box;
    std::string_view body;
};

struct ComplexPlan {
    std::vector<Part> parts;
    float total = 0.0F;
};

PartKind part_kind(std::string_view name) noexcept {
    if (name == kTextElement) return PartKind::kText;
    if (name == kMoneyElement || name == kJiaoZiElement) return PartKind::kMoney;
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
    if (part.kind == PartKind::kMoney) part.box = flow_money(meter, flow);
    if (part.kind == PartKind::kAction) part.box = flow_action(flow, record, is_last);
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

// FalagardActionButton::drawSelf (Fal 0x1800abac0) cho cửa sổ self với trạng thái flags.
void paint_action(const Ctx& ctx, const Placed& self, const ActionFlags& flags) {
    render_state(ctx, self, "BackgroundImage", self.screen);
    const GuiImage* back = property_image(ctx, self, "BackImage");
    if (back != nullptr) push_whole(*ctx.sheet, *back, self.screen, kWhiteArgb);
    if (flags.is_empty) {
        const bool is_touched = (flags.is_hovering || flags.is_pushed) && !flags.is_disabled;
        if (is_touched) overlay(ctx, self, kHoverCover);
        return;
    }
    draw_icon(ctx, self);
    draw_covers(ctx, self, flags);
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

} // namespace

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

// Cửa sổ phức hợp không có nền riêng; ảnh của nó là các nút action của phần tử, đặt ở vị trí đã làm
// tròn như Window::setPosition chế độ Absolute và cắt theo vùng nội dung.
void draw_complex(const Ctx& ctx, const Placed& self) {
    const std::optional<Box> area = complex_area(ctx, self);
    if (!area) return;
    const ComplexPlan plan = plan_complex(ctx, self, *area);
    const std::size_t first = ctx.sheet->quads.size();
    for (const Part& part : plan.parts) {
        if (part.kind != PartKind::kAction) continue;
        Box box = part.box;
        box.x = area->x + pixel_align(part.box.x);
        box.y = area->y + pixel_align(part.box.y - self.scroll);
        draw_part_button(ctx, self, part, box);
    }
    clip_quads(*ctx.sheet, first, *area);
}

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
        if (part.kind != PartKind::kText || !is_seen) continue;
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

} // namespace game::gui::detail
