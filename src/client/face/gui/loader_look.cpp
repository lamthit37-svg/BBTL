// Đổi look Falagard (WidgetLook, StateImagery, ImagerySection, kích thước) từ XML sang các mảng
// phẳng của GuiAsset. Công thức đọc theo Falagard_xmlHandler của _ref; tên enum theo
// CEGUIFalXMLEnumHelper.
// Nguồn: TLBB Dev tools/bake/gui_cook.cpp@e0d89a6 (phần dim, area, section, look, type). Khác gốc:
// cây XML của game::xml (Node) thay xml_tree; chuỗi DimOperator đổi bằng vòng lặp và kiểu của
// Child đi qua hàng đợi (settle_types) thay cho đệ quy; vòng lặp viết theo luật độ lồng. Chỉ số
// kiểu và look có thể khác thứ tự của Dev, nội dung giống nhau.
#include "core/number.hpp"
#include "gui/asset.hpp"
#include "gui/detail/cook.hpp"
#include "gui/detail/names.hpp"
#include "gui/value.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <format>
#include <iterator>
#include <optional>
#include <ranges>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::gui::detail {
namespace {

// Tên của các enum theo CEGUIFalXMLEnumHelper; chỉ số trong mảng là giá trị enum.
constexpr std::array<std::string_view, 10> kDimTypes = {"LeftEdge", "XPosition", "TopEdge", "YPosition", "RightEdge",
    "BottomEdge", "Width", "Height", "XOffset", "YOffset"};
constexpr std::array<std::string_view, 5> kDimOps = {"Noop", "Add", "Subtract", "Multiply", "Divide"};
constexpr std::array<std::string_view, 3> kMetrics = {"LineSpacing", "Baseline", "HorzExtent"};
constexpr std::array<std::string_view, 3> kHorzAligns = {"LeftAligned", "CentreAligned", "RightAligned"};
constexpr std::array<std::string_view, 3> kVertAligns = {"TopAligned", "CentreAligned", "BottomAligned"};
// FrameImageComponent theo thứ tự GuiFramePart.
constexpr std::array<std::string_view, 9> kFrameParts = {"Background", "TopLeftCorner", "TopRightCorner",
    "BottomLeftCorner", "BottomRightCorner", "LeftEdge", "RightEdge", "TopEdge", "BottomEdge"};

template <std::size_t N>
std::optional<std::size_t> index_of(const std::array<std::string_view, N>& names, std::string_view name) {
    const auto found = std::ranges::find(names, name);
    if (found == names.end()) return std::nullopt;
    return static_cast<std::size_t>(std::distance(names.begin(), found));
}

template <std::size_t N>
std::uint8_t enum_attribute(const Node& node, std::string_view key, const std::array<std::string_view, N>& names) {
    const auto found = index_of(names, node.attr(key, ""));
    return static_cast<std::uint8_t>(found.value_or(0));
}

// "FFFFFFFF" hay "ff00ff00" (AARRGGBB) như PropertyHelper::stringToColour.
std::uint32_t argb_of(std::string_view hex) {
    const core::OptionalUnsigned parsed = core::parse_unsigned(hex, 16);
    return parsed ? parsed->value : kWhiteArgb;
}

std::int32_t index_for(std::size_t size) {
    return static_cast<std::int32_t>(size);
}

// Kích thước

GuiDimType dim_type_of(Cook& cook, std::string_view name) {
    const auto found = index_of(kDimTypes, name);
    if (!found) note(cook, std::format("kiểu kích thước lạ {}", name));
    if (!found) return GuiDimType::kInvalid;
    return static_cast<GuiDimType>(*found);
}

// UnifiedDim ghi kiểu ở "type", ImageDim và WidgetDim ở "dimension"; "type" của FontDim là thước
// đo.
GuiDim base_dim(Cook& cook, const Node& element) {
    const bool is_unified = element.name() == "UnifiedDim";
    const bool is_font = element.name() == "FontDim";
    const std::string_view what = element.attr(is_unified ? "type" : "dimension", "Width");
    const std::string_view metric = element.attr("type", "LineSpacing");
    GuiDim dim;
    dim.what = dim_type_of(cook, what);
    dim.value = number_attribute(element, is_font ? "padding" : "value", 0.0F);
    dim.unified.scale = number_attribute(element, "scale", 0.0F);
    dim.unified.offset = number_attribute(element, "offset", 0.0F);
    dim.widget = element.attr("widget", "");
    dim.property = element.attr("name", "");
    dim.font = element.attr("font", "");
    dim.text = element.attr("string", "");
    dim.metric = static_cast<GuiFontMetric>(index_of(kMetrics, metric).value_or(0));
    return dim;
}

std::optional<GuiDimKind> dim_kind(std::string_view tag) {
    if (tag == "AbsoluteDim") return GuiDimKind::kAbsolute;
    if (tag == "ImageDim") return GuiDimKind::kImage;
    if (tag == "WidgetDim") return GuiDimKind::kWidget;
    if (tag == "UnifiedDim") return GuiDimKind::kUnified;
    if (tag == "FontDim") return GuiDimKind::kFont;
    if (tag == "PropertyDim") return GuiDimKind::kProperty;
    return std::nullopt;
}

// Ảnh ghi bằng hai thuộc tính imageset và image, như <Image> và <ImageDim>.
std::int32_t image_ref(Cook& cook, const Node& element) {
    return image_of(cook, element.attr("imageset", ""), element.attr("image", ""));
}

// DimOperator là con của Dim cơ sở và chứa Dim toán hạng (có thể lại có DimOperator): Dim toán hạng
// của element, nếu có.
std::optional<Node> operand_of(const Node& element) {
    const std::optional<Node> operation = element.first_child("DimOperator");
    if (!operation || !operation->has_children()) return std::nullopt;
    return operation->children().front();
}

// Thêm một Dim của chuỗi, trả chỉ số; operand là chỉ số Dim toán hạng đã thêm (-1 khi không có).
std::int32_t push_dim(Cook& cook, const Node& element, std::int32_t operand) {
    const std::optional<GuiDimKind> kind = dim_kind(element.name());
    if (!kind) note(cook, std::format("thẻ kích thước lạ {}", element.name()));
    if (!kind) return -1;
    GuiDim dim = base_dim(cook, element);
    dim.kind = *kind;
    if (*kind == GuiDimKind::kImage) dim.image = image_ref(cook, element);
    const std::optional<Node> operation = element.first_child("DimOperator");
    const bool is_chained = operation && operation->has_children();
    if (is_chained) dim.op = static_cast<GuiDimOp>(enum_attribute(*operation, "op", kDimOps));
    if (is_chained) dim.operand = operand;
    const std::int32_t index = index_for(cook.asset.dims.size());
    cook.asset.dims.push_back(std::move(dim));
    return index;
}

// Chuỗi Dim nối bằng DimOperator, từ Dim ngoài cùng tới toán hạng sâu nhất.
std::vector<Node> dim_chain(const Node& element) {
    std::vector<Node> chain{element};
    std::optional<Node> next = operand_of(element);
    while (next) {
        chain.push_back(*next);
        next = operand_of(*next);
    }
    return chain;
}

// Thêm cả chuỗi từ toán hạng sâu nhất lên, nên chỉ số toán hạng luôn nhỏ hơn chỉ số Dim chứa nó.
std::int32_t dim_of(Cook& cook, const Node& element) {
    std::int32_t operand = -1;
    for (const Node& link : dim_chain(element) | std::views::reverse)
        operand = push_dim(cook, link, operand);
    return operand;
}

// Ô của ComponentArea theo kiểu: trái, trên, phải hay rộng, dưới hay cao.
std::size_t area_slot(GuiDimType type) {
    if (type == GuiDimType::kLeftEdge || type == GuiDimType::kXPosition) return 0;
    if (type == GuiDimType::kTopEdge || type == GuiDimType::kYPosition) return 1;
    if (type == GuiDimType::kRightEdge || type == GuiDimType::kWidth) return 2;
    return 3;
}

// <Dim type="..."> bọc một Dim cơ sở.
void area_dim(Cook& cook, GuiArea& area, const Node& wrapper) {
    if (wrapper.name() != "Dim" || !wrapper.has_children()) return;
    const GuiDimType type = dim_type_of(cook, wrapper.attr("type", ""));
    const std::size_t slot = area_slot(type);
    area.types.at(slot) = type;
    area.dims.at(slot) = dim_of(cook, wrapper.children().front());
}

GuiArea area_of(Cook& cook, const std::optional<Node>& element) {
    GuiArea area;
    if (!element) return area;
    const std::optional<Node> source = element->first_child("AreaProperty");
    if (source) area.property = source->attr("name", "");
    for (const Node child : element->children())
        area_dim(cook, area, child);
    return area;
}

// Màu và định dạng của một thành phần

GuiColourSource colours_of(const Node& element) {
    GuiColourSource colour;
    const std::optional<Node> fixed = element.first_child("Colours");
    const std::optional<Node> single = element.first_child("ColourProperty");
    const std::optional<Node> rect = element.first_child("ColourRectProperty");
    if (fixed) {
        colour.colours = {argb_of(fixed->attr("topLeft", "FFFFFFFF")), argb_of(fixed->attr("topRight", "FFFFFFFF")),
            argb_of(fixed->attr("bottomLeft", "FFFFFFFF")), argb_of(fixed->attr("bottomRight", "FFFFFFFF"))};
    }
    if (single) colour.property = single->attr("name", "");
    if (rect) colour.property = rect->attr("name", "");
    colour.is_rect = rect.has_value();
    return colour;
}

// Định dạng cố định (thẻ tag) hay theo thuộc tính của cửa sổ (thẻ tag + "Property").
struct FormatAsk {
    std::string_view tag;
    std::uint8_t fallback = 0;
};

template <std::size_t N>
GuiFormat format_of(const Node& element, const FormatAsk& ask, const std::array<std::string_view, N>& names) {
    GuiFormat format{.value = ask.fallback, .property = {}};
    const std::optional<Node> fixed = element.first_child(ask.tag);
    const std::string property_tag = std::format("{}Property", ask.tag);
    const std::optional<Node> named = element.first_child(property_tag);
    if (fixed) format.value = enum_attribute(*fixed, "type", names);
    if (named) format.property = named->attr("name", "");
    return format;
}

// Thành phần

GuiImagery imagery_of(Cook& cook, const Node& element) {
    GuiImagery imagery;
    imagery.area = area_of(cook, element.first_child("Area"));
    imagery.colour = colours_of(element);
    const std::optional<Node> image = element.first_child("Image");
    const std::optional<Node> property = element.first_child("ImageProperty");
    if (image) imagery.image = image_ref(cook, *image);
    if (property) imagery.image_property = property->attr("name", "");
    const auto left = std::to_underlying(GuiHorz::kLeftAligned);
    const auto top = std::to_underlying(GuiVert::kTopAligned);
    imagery.horz = format_of(element, FormatAsk{.tag = "HorzFormat", .fallback = left}, kImageHorz);
    imagery.vert = format_of(element, FormatAsk{.tag = "VertFormat", .fallback = top}, kImageVert);
    return imagery;
}

void frame_image(Cook& cook, GuiFrame& frame, const Node& child) {
    if (child.name() != "Image") return;
    // Thiếu type thì CEGUI coi là nền (stringToFrameImageComponent rơi về FIC_BACKGROUND).
    const auto part = index_of(kFrameParts, child.attr("type", ""));
    const std::size_t index = part.value_or(std::to_underlying(GuiFramePart::kBackground));
    frame.images.at(index) = image_ref(cook, child);
}

GuiFrame frame_of(Cook& cook, const Node& element) {
    GuiFrame frame;
    frame.area = area_of(cook, element.first_child("Area"));
    frame.colour = colours_of(element);
    for (const Node child : element.children())
        frame_image(cook, frame, child);
    const auto stretched = std::to_underlying(GuiHorz::kStretched);
    frame.horz = format_of(element, FormatAsk{.tag = "HorzFormat", .fallback = stretched}, kImageHorz);
    frame.vert = format_of(element, FormatAsk{.tag = "VertFormat", .fallback = stretched}, kImageVert);
    return frame;
}

GuiText text_of(Cook& cook, const Node& element) {
    GuiText text;
    text.area = area_of(cook, element.first_child("Area"));
    text.colour = colours_of(element);
    const std::optional<Node> body = element.first_child("Text");
    if (body) text.text = body->attr("string", "");
    if (body) text.font = body->attr("font", "");
    text.horz = format_of(element, FormatAsk{.tag = "HorzFormat", .fallback = 0}, kTextHorz);
    text.vert = format_of(element, FormatAsk{.tag = "VertFormat", .fallback = 0}, kTextVert);
    return text;
}

// Section

std::optional<Node> section_element(const Node& look, std::string_view name) {
    const auto kids = look.children();
    const auto matches = [name](const Node& child) {
        return child.name() == "ImagerySection" && child.attr("name", "") == name;
    };
    const auto found = std::ranges::find_if(kids, matches);
    if (found == kids.end()) return std::nullopt;
    return *found;
}

struct SectionParts {
    std::vector<GuiFrame> frames;
    std::vector<GuiImagery> imageries;
    std::vector<GuiText> texts;
};

void section_part(Cook& cook, SectionParts& parts, const Node& child) {
    if (child.name() == "FrameComponent") parts.frames.push_back(frame_of(cook, child));
    if (child.name() == "ImageryComponent") parts.imageries.push_back(imagery_of(cook, child));
    if (child.name() == "TextComponent") parts.texts.push_back(text_of(cook, child));
}

// Nối items vào cuối target (chuyển phần tử đi), trả khoảng chúng chiếm.
template <class Item>
GuiRange append(std::vector<Item>& target, std::vector<Item>& items) {
    const GuiRange range{
        .first = static_cast<std::uint32_t>(target.size()), .count = static_cast<std::uint32_t>(items.size())};
    std::ranges::move(items, std::back_inserter(target));
    return range;
}

std::int32_t section_of(Cook& cook, std::string_view owner, std::string_view name) {
    const std::string key = std::format("{}/{}", owner, name);
    const auto known = cook.sections.find(key);
    if (known != cook.sections.end()) return known->second;
    const auto look = cook.look_xml.find(owner);
    const bool has_look = look != cook.look_xml.end();
    const std::optional<Node> element = has_look ? section_element(look->second, name) : std::nullopt;
    if (!element) note(cook, std::format("không có section {}", key));
    if (!element) return -1;
    SectionParts parts;
    for (const Node child : element->children())
        section_part(cook, parts, child);
    GuiSection section;
    section.name = std::string(name);
    section.master = colours_of(*element);
    section.frames = append(cook.asset.frames, parts.frames);
    section.imageries = append(cook.asset.imageries, parts.imageries);
    section.texts = append(cook.asset.texts, parts.texts);
    const std::int32_t index = index_for(cook.asset.sections.size());
    cook.asset.sections.push_back(std::move(section));
    cook.sections.emplace(key, index);
    return index;
}

// Look

struct LayerDraft {
    GuiLayer layer;
    std::vector<GuiSpec> specs;
};

struct StateDraft {
    GuiState state;
    std::vector<LayerDraft> layers;
};

GuiSpec spec_of(Cook& cook, std::string_view look, const Node& element) {
    GuiSpec spec;
    const std::string_view owner = element.attr("look", look);
    spec.section = section_of(cook, owner, element.attr("section", ""));
    spec.colour = colours_of(element);
    spec.overrides = element.first_child("Colours").has_value() || !spec.colour.property.empty();
    return spec;
}

void layer_spec(Cook& cook, std::string_view look, LayerDraft& draft, const Node& child) {
    if (child.name() == "Section") draft.specs.push_back(spec_of(cook, look, child));
}

LayerDraft layer_of(Cook& cook, std::string_view look, const Node& element) {
    LayerDraft draft;
    draft.layer.priority = static_cast<std::uint32_t>(number_attribute(element, "priority", 0.0F));
    for (const Node child : element.children())
        layer_spec(cook, look, draft, child);
    return draft;
}

void state_layer(Cook& cook, std::string_view look, StateDraft& draft, const Node& child) {
    if (child.name() == "Layer") draft.layers.push_back(layer_of(cook, look, child));
}

StateDraft state_of(Cook& cook, std::string_view look, const Node& element) {
    StateDraft draft;
    draft.state.name = element.attr("name", "");
    draft.state.clip_to_display = lower(element.attr("clipped", "true")) == "false";
    for (const Node child : element.children())
        state_layer(cook, look, draft, child);
    // Layer vẽ theo độ ưu tiên tăng dần như multiset của StateImagery.
    const auto by_priority = [](const LayerDraft& left, const LayerDraft& right) {
        return left.layer.priority < right.layer.priority;
    };
    std::ranges::stable_sort(draft.layers, by_priority);
    return draft;
}

GuiLayer commit_layer(Cook& cook, LayerDraft& draft) {
    draft.layer.specs = append(cook.asset.specs, draft.specs);
    return draft.layer;
}

GuiState commit_state(Cook& cook, StateDraft& draft) {
    std::vector<GuiLayer> layers;
    layers.reserve(draft.layers.size());
    for (LayerDraft& layer : draft.layers)
        layers.push_back(commit_layer(cook, layer));
    draft.state.layers = append(cook.asset.layers, layers);
    return draft.state;
}

GuiProperty property_of(const Node& element) {
    const bool is_definition = element.name() == "PropertyDefinition";
    const std::string_view value = element.attr(is_definition ? "initialValue" : "value", "");
    return GuiProperty{.name = std::string(element.attr("name", "")), .value = std::string(value)};
}

struct ChildDraft {
    GuiChild child;
    std::vector<GuiProperty> properties;
};

void child_property(ChildDraft& draft, const Node& child) {
    if (child.name() == "Property") draft.properties.push_back(property_of(child));
}

// Child: cửa sổ con mà look tự dựng. Kiểu của nó chỉ được đăng ký (type_of), look của kiểu ấy được
// dựng sau ở settle_types.
ChildDraft child_of(Cook& cook, const Node& element) {
    ChildDraft draft;
    draft.child.type = element.attr("type", "");
    draft.child.suffix = element.attr("nameSuffix", "");
    draft.child.area = area_of(cook, element.first_child("Area"));
    const std::optional<Node> horz = element.first_child("HorzAlignment");
    const std::optional<Node> vert = element.first_child("VertAlignment");
    if (horz) draft.child.horz_align = enum_attribute(*horz, "type", kHorzAligns);
    if (vert) draft.child.vert_align = enum_attribute(*vert, "type", kVertAligns);
    for (const Node child : element.children())
        child_property(draft, child);
    [[maybe_unused]] const std::int32_t type = type_of(cook, draft.child.type);
    return draft;
}

struct LookDraft {
    std::vector<StateDraft> states;
    std::vector<GuiNamedArea> areas;
    std::vector<GuiProperty> properties;
    std::vector<ChildDraft> children;
};

void named_area(Cook& cook, LookDraft& draft, const Node& child) {
    GuiNamedArea named;
    named.name = child.attr("name", "");
    named.area = area_of(cook, child.first_child("Area"));
    draft.areas.push_back(std::move(named));
}

// Thứ mà một thuộc tính của look nhắc tới phải có trong asset để bộ vẽ tra được: ảnh "set:...
// image:..." (SelectBrush của danh sách, ảnh nút của thanh cuộn) và kiểu cửa sổ của ChildItem
// ("key:<khoá> name:<kiểu>": nút action, ô tiền mà cửa sổ phức hợp dựng lúc chạy).
void take_look_value(Cook& cook, const GuiProperty& property) {
    const std::optional<ImageName> image = tagged_image(property.value);
    if (image) [[maybe_unused]]
        const std::int32_t index = image_of(cook, image->set, image->image);
    if (property.name != "ChildItem") return;
    const TagValue type = tagged_value(property.value, "name:");
    if (type) [[maybe_unused]]
        const std::int32_t index = type_of(cook, *type);
}

// Section sáng lên khi trỏ vào mà nút của cửa sổ thành tích gọi theo tên (SetHoverSection: Fal
// 0x1800420b0, 0x180042110): nó không nằm trong StateImagery nào, nên đưa vào look như một state
// cùng tên với một layer một section để bộ vẽ vẽ được bằng render_state.
void hover_state(Cook& cook, std::string_view look, LookDraft& draft, const Node& element) {
    const std::string_view name = element.attr("name", "");
    if (element.name() != "ImagerySection" || !name.ends_with("HoverSection")) return;
    LayerDraft layer;
    GuiSpec spec;
    spec.section = section_of(cook, look, name);
    layer.specs.push_back(spec);
    StateDraft state;
    state.state.name = std::string(name);
    state.layers.push_back(std::move(layer));
    draft.states.push_back(std::move(state));
}

void look_part(Cook& cook, std::string_view name, LookDraft& draft, const Node& child) {
    hover_state(cook, name, draft, child);
    if (child.name() == "StateImagery") draft.states.push_back(state_of(cook, name, child));
    if (child.name() == "NamedArea") named_area(cook, draft, child);
    const bool is_property = child.name() == "Property" || child.name() == "PropertyDefinition";
    if (is_property) draft.properties.push_back(property_of(child));
    if (is_property) take_look_value(cook, draft.properties.back());
    if (child.name() == "Child") draft.children.push_back(child_of(cook, child));
}

GuiChild commit_child(Cook& cook, ChildDraft& draft) {
    draft.child.properties = append(cook.asset.properties, draft.properties);
    return draft.child;
}

// Gắn phần đã đổi của look vào asset, theo thứ tự trạng thái, vùng, thuộc tính, con.
void commit_look(Cook& cook, std::int32_t index, LookDraft& draft) {
    std::vector<GuiState> states;
    states.reserve(draft.states.size());
    for (StateDraft& state : draft.states)
        states.push_back(commit_state(cook, state));
    std::vector<GuiChild> children;
    children.reserve(draft.children.size());
    for (ChildDraft& child : draft.children)
        children.push_back(commit_child(cook, child));
    GuiLook& look = cook.asset.looks.at(static_cast<std::size_t>(index));
    look.states = append(cook.asset.states, states);
    look.areas = append(cook.asset.areas, draft.areas);
    look.properties = append(cook.asset.properties, draft.properties);
    look.children = append(cook.asset.children, children);
}

std::int32_t look_of(Cook& cook, std::string_view name) {
    const auto known = cook.looks.find(name);
    if (known != cook.looks.end()) return known->second;
    const auto element = cook.look_xml.find(name);
    if (element == cook.look_xml.end()) note(cook, std::format("không có look {}", name));
    if (element == cook.look_xml.end()) return -1;
    const std::int32_t index = index_for(cook.asset.looks.size());
    GuiLook look;
    look.name = std::string(name);
    cook.asset.looks.push_back(std::move(look));
    cook.looks.emplace(std::string(name), index);
    LookDraft draft;
    for (const Node child : element->second.children())
        look_part(cook, name, draft, child);
    commit_look(cook, index, draft);
    return index;
}

} // namespace

std::int32_t type_of(Cook& cook, std::string_view name) {
    const auto known = cook.types.find(name);
    if (known != cook.types.end()) return known->second;
    const std::int32_t index = index_for(cook.asset.types.size());
    const auto mapping = cook.mappings.find(name);
    const bool is_plain = name == "DefaultWindow" || mapping == cook.mappings.end();
    GuiType type;
    type.name = std::string(name);
    type.renderer = is_plain ? std::string{} : mapping->second.renderer;
    cook.asset.types.push_back(std::move(type));
    cook.types.emplace(std::string(name), index);
    if (!is_plain) cook.pending.push_back(PendingType{.type = index, .look = mapping->second.look});
    return index;
}

void settle_types(Cook& cook) {
    while (!cook.pending.empty()) {
        const PendingType item = std::move(cook.pending.back());
        cook.pending.pop_back();
        const std::int32_t look = look_of(cook, item.look);
        cook.asset.types.at(static_cast<std::size_t>(item.type)).look = look;
    }
}

} // namespace game::gui::detail
