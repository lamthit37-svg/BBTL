// Đặt cửa sổ và đo kích thước của dàn trang Falagard. Công thức chép từ CEGUI của _ref: cửa sổ đặt
// theo UDim như Window::setWindowArea_impl chế độ Inherited (PixelAligned(cha * scale) + offset);
// kích thước của vùng thành phần theo BaseDim, UnifiedDim, ImageDim, WidgetDim và DimOperator.
// Phần đặt cửa sổ đã đối chiếu mã máy CEGUIBase.dll của client 2026 (setWindowArea_impl RVA
// 0xa7e10, windowToScreen 0xa9090, GUISheet::initialise 0x8a840, các hàm set của WindowProperties);
// ba chỗ bản 2026 khác mã 2008: không kẹp cỡ theo Min/MaxSize, bỏ qua Size và AbsoluteSize âm, và
// ô nhớ của setSize (không đổi kết quả của layout gốc nên không dựng lại).
// tests/golden/ui_rects.tsv là ô của mọi cửa sổ HUD tính độc lập theo các hàm đó. Nguồn: TLBB Dev
// src/gui/sheet.cpp@e0d89a6 (phần đặt cửa sổ và đo kích thước). Khác gốc: vòng lặp tìm thuộc tính
// viết bằng thuật toán thay cho `if` trong vòng; bảng tra kind_of thay chuỗi if; dim_value gấp
// chuỗi DimOperator bằng vòng lặp thay cho đệ quy (cùng trần 9 mức).
#include "gui/asset.hpp"
#include "gui/detail/draw.hpp"
#include "gui/scroll.hpp"
#include "gui/sheet.hpp"
#include "gui/value.hpp"

#include <algorithm>
#include <array>
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

// Số mức nối bằng DimOperator tối đa; sâu hơn thì toán hạng coi là 0.
constexpr std::size_t kDimLinks = 9;

// InfoList: Khác gốc, chưa vẽ từng dòng AddInfo; chữ Text vẽ như SimpleText để lời
// PushDebugMessage của DebugListBox hiện được. Ô trống không có Text thì không thêm chữ.
constexpr std::array<std::pair<std::string_view, Kind>, 11> kKinds = {{
    // Có dấu gạch chéo để không nhận nhầm hai widget họ hàng chưa port (SFZSoftKeyWindow,
    // PhoneSoftKeyWindow).
    {"/SoftKeyWindow", Kind::kSoftKeys},
    {"SuperProgress", Kind::kProgress},
    {"SceneMap", Kind::kRadar},
    {"MapImage", Kind::kMapImage},
    {"MeshWindow/ParentWindow", Kind::kMaskHost},
    {"MeshWindow", Kind::kMesh},
    {"CheckBox", Kind::kCheck},
    {"EditBox", Kind::kEdit},
    {"SimpleText", Kind::kText},
    {"InfoList", Kind::kText},
    {"Button", Kind::kButton},
}};

// TargetType nhận theo đúng tên, xét trước bảng chuỗi con: nhiều tên họ hàng chứa nhau
// (ActionButtonWindow, ComplexWindow/ParentWindow, ListBoxEx) mà bộ vẽ khác hẳn. DragTitle và
// SelfFitWindow kế thừa FalagardSimpleText nên vẽ chữ như nó (cỡ của SelfFitWindow do người gọi đặt:
// gốc tự co theo chữ bằng FalagardSelfFitWindow::getRenderSize, bản này để bảng tính và đưa qua Override).
// Falagard/Editbox (chữ b thường) là ô nhập của Combobox, vẽ như EditBox của bản TLBB.
constexpr std::array<std::pair<std::string_view, Kind>, 12> kExactKinds = {{
    {"Falagard/ActionButton", Kind::kAction},
    {"Falagard/Listbox", Kind::kList},
    {"Falagard/ComplexWindow", Kind::kComplex},
    {"Falagard/ComplexWindow/ParentWindow", Kind::kPlain},
    {"Falagard/AchievementWindow", Kind::kCatalog},
    {"Falagard/SelfFitWindow", Kind::kText},
    {"Falagard/Scrollbar", Kind::kScrollbar},
    {"Falagard/Thumb", Kind::kThumb},
    {"Falagard/DragTitle", Kind::kText},
    {"Falagard/Editbox", Kind::kEdit},
    {"Falagard/Money", Kind::kMoney},
    {"Falagard/WorldMap", Kind::kWorld},
}};

// Bộ vẽ theo tên TargetType: đúng tên trong kExactKinds, không thì tên đầu tiên trong kKinds mà
// TargetType chứa; không có thì cửa sổ trơn.
Kind kind_of(std::string_view renderer) noexcept {
    const auto exact = std::ranges::find(kExactKinds, renderer, &std::pair<std::string_view, Kind>::first);
    if (exact != kExactKinds.end()) return exact->second;
    const auto contained = [renderer](const auto& entry) { return renderer.contains(entry.first); };
    const auto found = std::ranges::find_if(kKinds, contained);
    return found == kKinds.end() ? Kind::kPlain : found->second;
}

bool is_listed(std::span<const std::string_view> names, std::string_view name) noexcept {
    return std::ranges::contains(names, name);
}

// Neo của cửa sổ trong cha: trái hay trên, giữa, phải hay dưới (HA_* và VA_* của CEGUI).
enum class Anchor : std::uint8_t { kStart, kCentre, kEnd };

// Vị trí, kích thước và căn lề của cửa sổ cùng các cờ hiện, khung, nền, luôn trên cùng.
struct Metrics {
    GuiUDim x;
    GuiUDim y;
    GuiUDim w;
    GuiUDim h;
    Anchor across = Anchor::kStart;
    Anchor down = Anchor::kStart;
    bool is_visible = true;
    bool has_frame = false;
    bool has_background = false;
    bool is_on_top = false;
};

// Một thuộc tính: tên và giá trị.
struct Setting {
    std::string_view name;
    std::string_view value;
};

// Hai thành viên UDim của Metrics đi cùng nhau: vị trí (x, y) hay kích thước (w, h).
struct UDimSlot {
    GuiUDim Metrics::* across;
    GuiUDim Metrics::* down;
};

constexpr UDimSlot kPosition{.across = &Metrics::x, .down = &Metrics::y};
constexpr UDimSlot kSize{.across = &Metrics::w, .down = &Metrics::h};

std::span<const GuiProperty> properties_in(const GuiAsset& asset, GuiRange range) noexcept {
    if (!in_range(asset.properties.size(), range)) return {};
    return std::span(asset.properties).subspan(range.first, range.count);
}

// Gán cặp từ chuỗi "{{s,o},{s,o}}"; hỏng thì giữ nguyên.
void set_vector(Metrics& metrics, UDimSlot slot, const std::optional<UVector>& vector) noexcept {
    if (!vector) return;
    metrics.*slot.across = vector->x;
    metrics.*slot.down = vector->y;
}

void set_area_rect(Metrics& metrics, const std::optional<URect>& rect) noexcept {
    if (!rect) return;
    metrics.x = rect->min.x;
    metrics.y = rect->min.y;
    metrics.w.scale = rect->max.x.scale - rect->min.x.scale;
    metrics.w.offset = rect->max.x.offset - rect->min.x.offset;
    metrics.h.scale = rect->max.y.scale - rect->min.y.scale;
    metrics.h.offset = rect->max.y.offset - rect->min.y.offset;
}

// AbsolutePosition, AbsoluteSize ghi điểm ảnh; Position, Size ghi tỉ lệ 0..1 của cha.
void set_pair(Metrics& metrics, UDimSlot slot, std::string_view text, bool is_absolute) noexcept {
    const std::optional<GuiUDim> pair = parse_udim(text);
    if (!pair) return;
    if (is_absolute) {
        metrics.*slot.across = GuiUDim{.scale = 0.0F, .offset = pixel_align(pair->scale)};
        metrics.*slot.down = GuiUDim{.scale = 0.0F, .offset = pixel_align(pair->offset)};
        return;
    }
    metrics.*slot.across = GuiUDim{.scale = pair->scale, .offset = 0.0F};
    metrics.*slot.down = GuiUDim{.scale = pair->offset, .offset = 0.0F};
}

void apply_flag(Metrics& metrics, const Setting& setting) noexcept {
    if (setting.name == "Visible") metrics.is_visible = parse_bool(setting.value);
    if (setting.name == "FrameEnabled") metrics.has_frame = parse_bool(setting.value);
    if (setting.name == "BackgroundEnabled") metrics.has_background = parse_bool(setting.value);
    if (setting.name == "AlwaysOnTop") metrics.is_on_top = parse_bool(setting.value);
}

void set_position(Metrics& metrics, std::string_view text) noexcept {
    set_vector(metrics, kPosition, parse_uvector(text));
}

void set_size(Metrics& metrics, std::string_view text) noexcept {
    set_vector(metrics, kSize, parse_uvector(text));
}

// UnifiedXPosition, UnifiedYPosition: một UDim "{s,o}"; hỏng thì giữ nguyên.
void set_across(Metrics& metrics, std::string_view text) noexcept {
    metrics.x = parse_udim(text).value_or(metrics.x);
}

void set_down(Metrics& metrics, std::string_view text) noexcept {
    metrics.y = parse_udim(text).value_or(metrics.y);
}

void set_area(Metrics& metrics, std::string_view text) noexcept {
    set_area_rect(metrics, parse_urect(text));
}

void set_pixel_position(Metrics& metrics, std::string_view text) noexcept {
    set_pair(metrics, kPosition, text, true);
}

void set_ratio_position(Metrics& metrics, std::string_view text) noexcept {
    set_pair(metrics, kPosition, text, false);
}

void set_ratio_size(Metrics& metrics, std::string_view text) noexcept {
    set_pair(metrics, kSize, text, false);
}

// Size và AbsoluteSize của CEGUIBase.dll 2026 (RVA 0xb4c90, 0xb4270) bỏ qua khi rộng hay cao âm;
// RelativeSize thì không chặn.
bool is_negative_pair(std::string_view text) noexcept {
    const std::optional<GuiUDim> pair = parse_udim(text);
    return pair && (pair->scale < 0.0F || pair->offset < 0.0F);
}

void set_pixel_size(Metrics& metrics, std::string_view text) noexcept {
    if (is_negative_pair(text)) return;
    set_pair(metrics, kSize, text, true);
}

void set_plain_size(Metrics& metrics, std::string_view text) noexcept {
    if (is_negative_pair(text)) return;
    set_pair(metrics, kSize, text, false);
}

// "Centre" là giữa, last ("Right" hay "Bottom") là cuối, chuỗi khác là đầu.
Anchor anchor_of(std::string_view text, std::string_view last) noexcept {
    if (text == "Centre") return Anchor::kCentre;
    return text == last ? Anchor::kEnd : Anchor::kStart;
}

void set_horizontal(Metrics& metrics, std::string_view text) noexcept {
    metrics.across = anchor_of(text, "Right");
}

void set_vertical(Metrics& metrics, std::string_view text) noexcept {
    metrics.down = anchor_of(text, "Bottom");
}

// AbsoluteWidth và AbsoluteHeight: script đổi cỡ một chiều bằng điểm ảnh (Window::setWidth, setHeight
// với Absolute); chiều kia giữ nguyên. Không đọc được số thì bỏ.
void set_absolute_width(Metrics& metrics, std::string_view text) noexcept {
    if (const std::optional<float> value = parse_float(text)) metrics.w = GuiUDim{.scale = 0.0F, .offset = *value};
}

void set_absolute_height(Metrics& metrics, std::string_view text) noexcept {
    if (const std::optional<float> value = parse_float(text)) metrics.h = GuiUDim{.scale = 0.0F, .offset = *value};
}

using Apply = void (*)(Metrics&, std::string_view) noexcept;

// Một thuộc tính hình học của Window và hàm ghi nó vào Metrics.
struct Rule {
    std::string_view name;
    Apply apply = nullptr;
};

// Mọi thuộc tính hình học có trong 2.034 layout gốc, cộng AbsoluteWidth và AbsoluteHeight mà script gọi
// SetProperty (không layout nào ghi). Position và Size đọc theo MetricsMode mặc
// định Relative (không layout nào đổi). Min/MaxSize vắng mặt có chủ đích: bản 2026 không kẹp cỡ.
constexpr std::array<Rule, 15> kRules = {{
    {.name = "UnifiedPosition", .apply = &set_position},
    {.name = "UnifiedSize", .apply = &set_size},
    {.name = "UnifiedXPosition", .apply = &set_across},
    {.name = "UnifiedYPosition", .apply = &set_down},
    {.name = "UnifiedAreaRect", .apply = &set_area},
    {.name = "AbsolutePosition", .apply = &set_pixel_position},
    {.name = "Position", .apply = &set_ratio_position},
    {.name = "RelativePosition", .apply = &set_ratio_position},
    {.name = "AbsoluteSize", .apply = &set_pixel_size},
    {.name = "Size", .apply = &set_plain_size},
    {.name = "RelativeSize", .apply = &set_ratio_size},
    {.name = "HorizontalAlignment", .apply = &set_horizontal},
    {.name = "VerticalAlignment", .apply = &set_vertical},
    {.name = "AbsoluteWidth", .apply = &set_absolute_width},
    {.name = "AbsoluteHeight", .apply = &set_absolute_height},
}};

void apply_one(Metrics& metrics, const Setting& setting) noexcept {
    apply_flag(metrics, setting);
    const auto is_named = [&setting](const Rule& rule) { return rule.name == setting.name; };
    const auto found = std::ranges::find_if(kRules, is_named);
    if (found == kRules.end()) return;
    found->apply(metrics, setting.value);
}

void apply_range(const GuiAsset& asset, GuiRange range, Metrics& metrics) noexcept {
    for (const GuiProperty& prop : properties_in(asset, range)) {
        apply_one(metrics, Setting{.name = prop.name, .value = prop.value});
    }
}

void apply_forced(const Place& input, std::string_view window, Metrics& metrics) noexcept {
    const auto for_window = [window](const Override& item) { return item.window == window; };
    for (const Override& item : input.overrides | std::views::filter(for_window)) {
        apply_one(metrics, Setting{.name = item.name, .value = item.value});
    }
}

// GUISheet::initialise của CEGUIBase.dll 2026 (RVA 0x8a840) đặt cỡ {1,1} của cha cho DefaultWindow
// (tên cũ DefaultGUISheet); kiểu khác bắt đầu từ cỡ 0.
bool is_sheet(const GuiType* type) noexcept {
    if (type == nullptr) return false;
    return type->name == "DefaultWindow" || type->name == "DefaultGUISheet";
}

// Thuộc tính của look thua của layout, rồi tới giá trị đặt lúc chạy. placed đã có window, type và
// look.
Metrics metrics_of(const GuiAsset& asset, const Placed& placed, const Place& input) {
    Metrics metrics;
    const float whole = is_sheet(placed.type) ? 1.0F : 0.0F;
    metrics.w.scale = whole;
    metrics.h.scale = whole;
    if (placed.look != nullptr) apply_range(asset, placed.look->properties, metrics);
    apply_range(asset, placed.window->properties, metrics);
    apply_forced(input, placed.window->name, metrics);
    return metrics;
}

// Một trục của cửa sổ trong cha: cỡ cha, cỡ mình và neo.
struct Reach {
    float parent = 0.0F;
    float own = 0.0F;
    Anchor anchor = Anchor::kStart;
};

// Phần dời thêm khi căn giữa hay căn cuối, như Window::windowToScreen: (cha - mình) x 0,5 hoặc
// (cha - mình), không làm tròn nên căn giữa có thể ra nửa điểm ảnh.
float anchor_shift(const Reach& reach) noexcept {
    if (reach.anchor == Anchor::kStart) return 0.0F;
    const float gap = reach.parent - reach.own;
    return reach.anchor == Anchor::kCentre ? gap * 0.5F : gap;
}

Box box_of(Box parent, const Metrics& metrics) noexcept {
    Box box;
    box.w = abs_of(metrics.w, parent.w);
    box.h = abs_of(metrics.h, parent.h);
    const Reach across{.parent = parent.w, .own = box.w, .anchor = metrics.across};
    const Reach down{.parent = parent.h, .own = box.h, .anchor = metrics.down};
    const float left = abs_of(metrics.x, parent.w) + anchor_shift(across);
    const float top = abs_of(metrics.y, parent.h) + anchor_shift(down);
    box.x = parent.x + left;
    box.y = parent.y + top;
    return box;
}

const GuiType* type_at(const GuiAsset& asset, std::int32_t index) noexcept {
    if (index < 0 || static_cast<std::size_t>(index) >= asset.types.size()) return nullptr;
    return &asset.types.at(static_cast<std::size_t>(index));
}

const GuiLook* look_at(const GuiAsset& asset, std::int32_t index) noexcept {
    if (index < 0 || static_cast<std::size_t>(index) >= asset.looks.size()) return nullptr;
    return &asset.looks.at(static_cast<std::size_t>(index));
}

bool is_root_open(const Place& input, std::string_view name) noexcept {
    if (input.roots.empty()) return true;
    return is_listed(input.roots, name);
}

// Kiểu, look và bộ vẽ của cửa sổ window; ô và cờ hiện chưa đặt.
Placed typed_window(const GuiAsset& asset, const GuiWindow& window) {
    Placed placed;
    placed.window = &window;
    placed.type = type_at(asset, window.type);
    placed.look = placed.type == nullptr ? nullptr : look_at(asset, placed.type->look);
    placed.kind = placed.type == nullptr ? Kind::kPlain : kind_of(placed.type->renderer);
    return placed;
}

// Cửa sổ ở chỉ số index khi các cửa sổ đứng trước (before) đã đặt.
Placed place_window(const GuiAsset& asset, const Place& input, std::span<const Placed> before, std::size_t index) {
    const GuiWindow& window = asset.windows.at(index);
    Placed placed = typed_window(asset, window);
    const Metrics metrics = metrics_of(asset, placed, input);
    const bool is_root = window.parent < 0;
    const Box screen{.x = 0.0F, .y = 0.0F, .w = input.width, .h = input.height};
    const Placed* parent = is_root ? nullptr : &before[static_cast<std::size_t>(window.parent)];
    placed.screen = box_of(is_root ? screen : parent->screen, metrics);
    const bool is_parent_on = is_root || parent->is_visible;
    const bool is_opened = !is_root || is_root_open(input, window.name);
    const bool is_hidden = is_listed(input.hidden, window.name);
    placed.is_visible = is_parent_on && is_opened && metrics.is_visible && !is_hidden;
    placed.is_on_top = metrics.is_on_top;
    return placed;
}

// Phần dời của một con tự dựng theo HorzAlignment hay VertAlignment (0 đầu, 1 giữa, 2 cuối), như
// Window::windowToScreen.
float child_shift(std::uint8_t align, Reach reach) noexcept {
    reach.anchor = align == 1 ? Anchor::kCentre : (align == 2 ? Anchor::kEnd : Anchor::kStart);
    return anchor_shift(reach);
}

// Con chạy của thanh cuộn bar: FalagardScrollbar::updateThumb (Fal 0x1800468c0) đặt nó ở mép trái
// của ThumbTrackArea, mép trên theo vị trí cuộn (làm tròn trong toạ độ của thanh cuộn).
void settle_thumb(const Ctx& ctx, const Placed& bar, Placed& thumb) {
    const std::optional<Box> area = named_area(ctx, bar, "ThumbTrackArea");
    if (!area) return;
    const ThumbTrack local{.top = area->y - bar.screen.y, .slide = area->h - thumb.screen.h};
    thumb.screen.x = area->x;
    thumb.screen.y = bar.screen.y + thumb_top(local, bar.span, bar.scroll);
}

// Cửa sổ con mà look của cha tự dựng (WidgetComponent::layout): ô theo <Area> của <Child> trong cha
// rồi dời theo căn lề. Thanh cuộn của danh sách và cửa sổ phức hợp chỉ hiện khi nội dung dài hơn
// vùng; con chạy đứng theo vị trí cuộn. Panel giấu được một con theo tên (danh sách thả của
// Combobox: "<tên cha>__auto_droplist__").
Placed place_child(const Ctx& ctx, std::size_t index) {
    const GuiWindow& window = ctx.asset->windows.at(index);
    Placed placed = typed_window(*ctx.asset, window);
    const Placed& parent = ctx.placed[static_cast<std::size_t>(window.parent)];
    const GuiChild& child = ctx.asset->children.at(static_cast<std::size_t>(window.child));
    Box local = area_box(ctx, parent, child.area, parent.screen);
    local.x += child_shift(child.horz_align, Reach{.parent = parent.screen.w, .own = local.w});
    local.y += child_shift(child.vert_align, Reach{.parent = parent.screen.h, .own = local.h});
    placed.screen = Box{.x = parent.screen.x + local.x, .y = parent.screen.y + local.y, .w = local.w, .h = local.h};
    const bool is_shown = parent.is_visible && !is_listed(ctx.input->hidden, window.name);
    placed.is_visible = is_shown;
    if (placed.kind == Kind::kScrollbar) {
        placed.span = parent.span;
        placed.scroll = parent.scroll;
        placed.is_visible = is_shown && is_scrollable(parent.span);
    }
    if (placed.kind == Kind::kThumb && parent.kind == Kind::kScrollbar) settle_thumb(ctx, parent, placed);
    return placed;
}

// Cửa sổ index là con tự dựng hợp lệ (cha đứng trước, <Child> có trong asset) không.
bool is_look_child(const GuiAsset& asset, std::size_t index) noexcept {
    const GuiWindow& window = asset.windows.at(index);
    const bool has_parent = window.parent >= 0 && std::cmp_less(window.parent, index);
    return has_parent && window.child >= 0 && std::cmp_less(window.child, asset.children.size());
}

bool is_horizontal(GuiDimType what) noexcept {
    switch (what) {
    case GuiDimType::kLeftEdge:
    case GuiDimType::kRightEdge:
    case GuiDimType::kXPosition:
    case GuiDimType::kXOffset:
    case GuiDimType::kWidth: return true;
    default: return false;
    }
}

float image_dim(const GuiImage& image, GuiDimType what) noexcept {
    switch (what) {
    case GuiDimType::kWidth: return image.width;
    case GuiDimType::kHeight: return image.height;
    case GuiDimType::kXOffset: return image.offset_x;
    case GuiDimType::kYOffset: return image.offset_y;
    case GuiDimType::kRightEdge: return image.x + image.width;
    case GuiDimType::kBottomEdge: return image.y + image.height;
    case GuiDimType::kTopEdge:
    case GuiDimType::kYPosition: return image.y;
    default: return image.x;
    }
}

// Cạnh của cửa sổ con widget trong toạ độ của cửa sổ self.
float widget_edge(const Placed& self, const Placed& widget, GuiDimType what) noexcept {
    const float left = widget.screen.x - self.screen.x;
    const float top = widget.screen.y - self.screen.y;
    switch (what) {
    case GuiDimType::kWidth: return widget.screen.w;
    case GuiDimType::kHeight: return widget.screen.h;
    case GuiDimType::kRightEdge: return left + widget.screen.w;
    case GuiDimType::kBottomEdge: return top + widget.screen.h;
    case GuiDimType::kTopEdge:
    case GuiDimType::kYPosition: return top;
    case GuiDimType::kXOffset:
    case GuiDimType::kYOffset: return 0.0F;
    default: return left;
    }
}

float widget_dim(const Ctx& ctx, const Placed& self, const GuiDim& dim) {
    const std::string name = self.window->name + dim.widget;
    const Placed* widget = dim.widget.empty() ? &self : find_placed(ctx, name);
    if (widget == nullptr) return 0.0F;
    return widget_edge(self, *widget, dim.what);
}

float image_measure(const GuiAsset& asset, std::int32_t index, GuiDimType what) noexcept {
    const GuiImage* image = image_at(asset, index);
    if (image == nullptr) return 0.0F;
    return image_dim(*image, what);
}

float dim_base(const Ctx& ctx, const Placed& self, const GuiDim& dim, Box local) {
    switch (dim.kind) {
    case GuiDimKind::kAbsolute: return dim.value;
    case GuiDimKind::kUnified: return abs_of(dim.unified, is_horizontal(dim.what) ? local.w : local.h);
    case GuiDimKind::kImage: return image_measure(*ctx.asset, dim.image, dim.what);
    case GuiDimKind::kWidget: return widget_dim(ctx, self, dim);
    default: return 0.0F;
    }
}

float apply_op(float value, GuiDimOp operation, float other) noexcept {
    switch (operation) {
    case GuiDimOp::kAdd: return value + other;
    case GuiDimOp::kSubtract: return value - other;
    case GuiDimOp::kMultiply: return value * other;
    case GuiDimOp::kDivide: return other == 0.0F ? value : value / other;
    default: return value;
    }
}

bool is_dim_index(const Ctx& ctx, std::int32_t index) noexcept {
    return index >= 0 && static_cast<std::size_t>(index) < ctx.asset->dims.size();
}

// Dim kế tiếp của chuỗi DimOperator; -1 khi dim không nối thêm.
std::int32_t next_link(const GuiDim& dim) noexcept {
    const bool is_chained = dim.operand >= 0 && dim.op != GuiDimOp::kNone;
    return is_chained ? dim.operand : -1;
}

// Một lần đo trong vùng: dim bắt đầu chuỗi và ô local của cha.
struct DimAsk {
    std::int32_t first = -1;
    Box local;
};

// Giá trị của chuỗi Dim nối bằng DimOperator: thu các mắt xích rồi gấp từ cuối. Toán hạng hỏng hay
// vượt kDimLinks mức thì coi là 0, như bản đệ quy của Dev.
float dim_value(const Ctx& ctx, const Placed& self, const DimAsk& ask) {
    std::array<std::int32_t, kDimLinks> links{};
    std::size_t count = 0;
    std::int32_t next = ask.first;
    while (count < links.size() && is_dim_index(ctx, next)) {
        links.at(count) = next;
        next = next_link(ctx.asset->dims.at(static_cast<std::size_t>(next)));
        ++count;
    }
    float result = 0.0F;
    for (std::size_t link = count; link > 0; --link) {
        const GuiDim& dim = ctx.asset->dims.at(static_cast<std::size_t>(links.at(link - 1)));
        const float value = dim_base(ctx, self, dim, ask.local);
        result = next_link(dim) < 0 ? value : apply_op(value, dim.op, result);
    }
    return result;
}

// Vùng cho bởi thuộc tính URect của cửa sổ (AreaProperty).
Box property_box(const Ctx& ctx, const Placed& self, const GuiArea& area, Box local) {
    const auto text = effective(ctx, self, area.property);
    const auto rect = text ? parse_urect(*text) : std::nullopt;
    if (!rect) return {};
    Box box;
    box.x = abs_of(rect->min.x, local.w);
    box.y = abs_of(rect->min.y, local.h);
    box.w = abs_of(rect->max.x, local.w) - box.x;
    box.h = abs_of(rect->max.y, local.h) - box.y;
    return box;
}

} // namespace

float pixel_align(float value) noexcept {
    // NOLINTNEXTLINE(bugprone-incorrect-roundings): (int)(x + 0.5f) của CEGUI, giữ đúng ref.
    return static_cast<float>(static_cast<int>(value + 0.5F));
}

float abs_of(GuiUDim dim, float base) noexcept {
    return pixel_align(base * dim.scale) + dim.offset;
}

bool in_range(std::size_t size, GuiRange range) noexcept {
    return static_cast<std::size_t>(range.first) + range.count <= size;
}

bool is_pressable(Kind kind) noexcept {
    return kind == Kind::kButton || kind == Kind::kCheck || kind == Kind::kAction || kind == Kind::kThumb;
}

std::span<const GuiProperty> window_properties(const GuiAsset& asset, const Placed& placed) noexcept {
    return properties_in(asset, placed.window->properties);
}

std::optional<std::string_view> last_prop(const GuiAsset& asset, GuiRange range, std::string_view name) {
    const auto matches = [name](const GuiProperty& prop) { return prop.name == name; };
    const auto backwards = properties_in(asset, range) | std::views::reverse;
    const auto found = std::ranges::find_if(backwards, matches);
    if (found == backwards.end()) return std::nullopt;
    return std::string_view((*found).value);
}

std::optional<std::string_view> forced(const Place& input, const Placed& placed, std::string_view name) {
    const std::string_view window = placed.window->name;
    const auto matches = [window, name](const Override& item) { return item.window == window && item.name == name; };
    const auto backwards = input.overrides | std::views::reverse;
    const auto found = std::ranges::find_if(backwards, matches);
    if (found == backwards.end()) return std::nullopt;
    return (*found).value;
}

std::optional<std::string_view> effective(const Ctx& ctx, const Placed& placed, std::string_view name) {
    const auto set = forced(*ctx.input, placed, name);
    if (set) return set;
    const auto own = last_prop(*ctx.asset, placed.window->properties, name);
    if (own) return own;
    if (placed.look == nullptr) return std::nullopt;
    return last_prop(*ctx.asset, placed.look->properties, name);
}

bool flag(const Ctx& ctx, const Placed& self, std::string_view name) {
    const auto text = effective(ctx, self, name);
    return text && parse_bool(*text);
}

const GuiImage* image_at(const GuiAsset& asset, std::int32_t index) noexcept {
    if (index < 0 || static_cast<std::size_t>(index) >= asset.images.size()) return nullptr;
    return &asset.images.at(static_cast<std::size_t>(index));
}

const Placed* find_placed(const Ctx& ctx, std::string_view name) noexcept {
    const auto matches = [name](const Placed& placed) { return placed.window->name == name; };
    const auto found = std::ranges::find_if(ctx.placed, matches);
    return found == ctx.placed.end() ? nullptr : &*found;
}

std::optional<Box> named_area(const Ctx& ctx, const Placed& self, std::string_view name) {
    if (self.look == nullptr || !in_range(ctx.asset->areas.size(), self.look->areas)) return std::nullopt;
    const auto areas = std::span(ctx.asset->areas).subspan(self.look->areas.first, self.look->areas.count);
    const auto found = std::ranges::find(areas, name, &GuiNamedArea::name);
    if (found == areas.end()) return std::nullopt;
    const Box local = area_box(ctx, self, found->area, self.screen);
    return Box{.x = self.screen.x + local.x, .y = self.screen.y + local.y, .w = local.w, .h = local.h};
}

const GuiChild* look_child(const GuiAsset& asset, const Placed& self, std::string_view suffix) {
    if (self.look == nullptr || !in_range(asset.children.size(), self.look->children)) return nullptr;
    const auto children = std::span(asset.children).subspan(self.look->children.first, self.look->children.count);
    const auto found = std::ranges::find(children, suffix, &GuiChild::suffix);
    return found == children.end() ? nullptr : &*found;
}

// Cha luôn đứng trước con, nên một lượt xuôi là đủ; windows đã giữ chỗ đủ nên span của các cửa sổ
// đã đặt còn đúng trong lúc thêm.
std::vector<Placed> layout(const GuiAsset& asset, const Place& input) {
    std::vector<Placed> windows;
    windows.reserve(asset.windows.size());
    for (std::size_t index = 0; index < asset.windows.size(); ++index) {
        Ctx ctx;
        ctx.asset = &asset;
        ctx.input = &input;
        ctx.placed = windows;
        const bool is_child = is_look_child(asset, index);
        Placed placed = is_child ? place_child(ctx, index) : place_window(asset, input, windows, index);
        if (placed.kind == Kind::kList || placed.kind == Kind::kComplex) {
            const ScrollView view = scroll_view(ctx, placed);
            placed.span = view.span;
            placed.scroll = view.position;
            placed.row = view.row;
        }
        windows.push_back(placed);
    }
    return windows;
}

Box area_box(const Ctx& ctx, const Placed& self, const GuiArea& area, Box local) {
    if (!area.property.empty()) return property_box(ctx, self, area, local);
    const auto measure = [&](std::size_t slot) {
        return dim_value(ctx, self, DimAsk{.first = area.dims.at(slot), .local = local});
    };
    const float left = measure(0);
    const float top = measure(1);
    const float across = measure(2);
    const float down = measure(3);
    Box box;
    box.x = left;
    box.y = top;
    box.w = area.types.at(2) == GuiDimType::kWidth ? across : across - left;
    box.h = area.types.at(3) == GuiDimType::kHeight ? down : down - top;
    return box;
}

} // namespace game::gui::detail
