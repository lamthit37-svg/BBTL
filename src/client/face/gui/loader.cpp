// Nạp tệp XML của giao diện gốc: scheme, looknfeel, imageset và layout; phần đổi look sang mảng
// phẳng nằm ở loader_look.cpp. Công thức đọc theo Falagard_xmlHandler, Imageset_xmlHandler và
// GUILayout_xmlHandler của _ref.
// Nguồn: TLBB Dev tools/bake/gui_cook.cpp@e0d89a6 (phần tệp, ảnh, layout). Khác gốc: nạp lúc chạy
// qua FileSource thay vì nấu offline; không cần manifest vì đường dẫn là tên gốc; cây cửa sổ duyệt
// bằng ngăn xếp thay cho đệ quy (cùng thứ tự cha trước con).
#include "gui/loader.hpp"

#include "core/number.hpp"
#include "gui/asset.hpp"
#include "gui/detail/cook.hpp"
#include "gui/value.hpp"
#include "io/file.hpp"
#include "xml/document.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <filesystem>
#include <format>
#include <iterator>
#include <memory>
#include <optional>
#include <ranges>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::gui {

using detail::Cook;
using detail::Mapping;
using detail::Node;

namespace {

std::optional<std::string> read_at(const std::filesystem::path& root, std::string_view clean) {
    io::TextResult text = io::read_text(root / io::path_from_utf8(clean));
    if (!text) return std::nullopt;
    return std::move(*text);
}

} // namespace

std::optional<std::string> DiskSource::read(std::string_view path) const {
    std::string clean(path);
    std::ranges::replace(clean, '\\', '/');
    const bool is_layout = clean.ends_with(".layout.xml") && !clean.starts_with("phone/");
    if (phone_ && is_layout) {
        const std::string over = std::string("phone/") + clean;
        std::optional<std::string> found = read_at(root_, over);
        if (found) return found;
    }
    std::optional<std::string> direct = read_at(root_, clean);
    if (direct) return direct;
    // Bản PC của layout không có trong kho này: dùng bản điện thoại tạm cùng tên.
    if (!phone_ && is_layout) return read_at(root_, std::string("phone/") + clean);
    return std::nullopt;
}

namespace detail {

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): khoá và mặc định là chuỗi hằng.
std::string_view Node::attr(std::string_view key, std::string_view fallback) const {
    const xml::OptionalText value = xml::attribute(element(), key);
    return value.value_or(fallback);
}

std::optional<Node> Node::first_child(std::string_view tag) const {
    const auto kids = children();
    const auto matches = [tag](const Node& child) { return child.name() == tag; };
    const auto found = std::ranges::find_if(kids, matches);
    if (found == kids.end()) return std::nullopt;
    return *found;
}

void note(Cook& cook, std::string text) {
    cook.notes.push_back(std::move(text));
}

std::string lower(std::string_view text) {
    std::string out(text);
    const auto fold = [](char letter) {
        const bool is_upper = letter >= 'A' && letter <= 'Z';
        return is_upper ? static_cast<char>(letter - 'A' + 'a') : letter;
    };
    std::ranges::transform(out, out.begin(), fold);
    return out;
}

float number_attribute(const Node& node, std::string_view key, float fallback) {
    const xml::OptionalText value = xml::attribute(node.element(), key);
    if (!value) return fallback;
    const core::OptionalDouble parsed = core::parse_double(*value);
    return parsed ? static_cast<float>(parsed->value) : 0.0F;
}

namespace {

std::int32_t next_index(std::size_t size) {
    return static_cast<std::int32_t>(size);
}

// Texture

std::int32_t texture_of(Cook& cook, std::string_view imagefile) {
    const std::string key = lower(imagefile);
    const auto known = cook.textures.find(key);
    if (known != cook.textures.end()) return known->second;
    const std::int32_t index = next_index(cook.asset.textures.size());
    cook.asset.textures.emplace_back(imagefile);
    cook.textures.emplace(key, index);
    return index;
}

// Ảnh

std::optional<Node> image_element(const Node& imageset, std::string_view name) {
    const auto kids = imageset.children();
    const auto matches = [name](const Node& child) {
        return child.name() == "Image" && child.attr("Name", "") == name;
    };
    const auto found = std::ranges::find_if(kids, matches);
    if (found == kids.end()) return std::nullopt;
    return *found;
}

GuiImage image_record(Cook& cook, const Node& set, const Node& image) {
    GuiImage record;
    record.imageset = set.attr("Name", "");
    record.name = image.attr("Name", "");
    record.texture = texture_of(cook, set.attr("Imagefile", ""));
    record.x = number_attribute(image, "XPos", 0.0F);
    record.y = number_attribute(image, "YPos", 0.0F);
    record.width = number_attribute(image, "Width", 0.0F);
    record.height = number_attribute(image, "Height", 0.0F);
    record.offset_x = number_attribute(image, "XOffset", 0.0F);
    record.offset_y = number_attribute(image, "YOffset", 0.0F);
    record.auto_scaled = lower(set.attr("AutoScaled", "false")) == "true";
    record.native_width = number_attribute(set, "NativeHorzRes", kNativeWidth);
    record.native_height = number_attribute(set, "NativeVertRes", kNativeHeight);
    return record;
}

} // namespace

std::int32_t image_of(Cook& cook, std::string_view imageset, std::string_view name) {
    const std::string key = std::format("{}/{}", imageset, name);
    const auto known = cook.images.find(key);
    if (known != cook.images.end()) return known->second;
    const auto set = cook.imageset_xml.find(imageset);
    const bool has_set = set != cook.imageset_xml.end();
    const std::optional<Node> image = has_set ? image_element(set->second, name) : std::nullopt;
    if (!image) note(cook, std::format("không có ảnh {}", key));
    if (!image) return -1;
    const std::int32_t index = next_index(cook.asset.images.size());
    cook.asset.images.push_back(image_record(cook, set->second, *image));
    cook.images.emplace(key, index);
    return index;
}

} // namespace detail

namespace {

using detail::image_of;
using detail::lower;
using detail::note;
using detail::type_of;

// Đọc và phân tích một tệp XML; cây giữ trong cook.files nên Node trỏ vào nó sống hết lượt.
std::expected<Node, std::string> load_xml(Cook& cook, std::string_view path) {
    const std::optional<std::string> text = cook.sources.files->read(path);
    if (!text) return std::unexpected(std::format("không có tệp {}", path));
    xml::ParseResult parsed = xml::parse(*text);
    if (!parsed) {
        const std::size_t offset = parsed.error().offset;
        return std::unexpected(std::format("{}: XML hỏng ở byte {}", path, offset));
    }
    cook.files.push_back(std::move(*parsed));
    return Node(cook.files.back(), 0);
}

// Scheme, looknfeel, imageset

void scheme_mapping(Cook& cook, const Node& child) {
    if (child.name() != "FalagardMapping") return;
    Mapping mapping{
        .renderer = std::string(child.attr("TargetType", "")), .look = std::string(child.attr("LookNFeel", ""))};
    cook.mappings.insert_or_assign(std::string(child.attr("WindowType", "")), std::move(mapping));
}

void index_look(Cook& cook, const Node& child) {
    if (child.name() != "WidgetLook") return;
    cook.look_xml.emplace(std::string(child.attr("name", "")), child);
}

void index_imageset(Cook& cook, const Node& child) {
    if (child.name() != "Imageset") return;
    cook.imageset_xml.emplace(std::string(child.attr("Name", "")), child);
}

std::expected<void, std::string> load_looknfeel(Cook& cook, const Node& child) {
    if (child.name() != "LookNFeel") return {};
    const std::string path(child.attr("Filename", ""));
    const auto root = load_xml(cook, path);
    if (!root) return std::unexpected(root.error());
    for (const Node look : root->children())
        index_look(cook, look);
    return {};
}

std::expected<void, std::string> load_scheme(Cook& cook) {
    const auto root = load_xml(cook, cook.sources.scheme);
    if (!root) return std::unexpected(root.error());
    for (const Node child : root->children())
        scheme_mapping(cook, child);
    std::expected<void, std::string> loaded;
    for (const Node child : root->children())
        loaded = loaded ? load_looknfeel(cook, child) : loaded;
    return loaded;
}

std::expected<void, std::string> load_imagesets(Cook& cook) {
    const auto root = load_xml(cook, cook.sources.imagesets);
    if (!root) return std::unexpected(root.error());
    for (const Node set : root->children())
        index_imageset(cook, set);
    return {};
}

void index_animate(Cook& cook, const Node& child) {
    if (child.name() != "Animate") return;
    std::string name(child.attr("Name", ""));
    cook.animate_xml.emplace(std::move(name), child);
}

// Bảng hoạt ảnh là phần thêm: không có tệp thì bỏ qua (cửa sổ nhắc tới hoạt ảnh sẽ ra ghi chú),
// tệp hỏng thì là lỗi như các tệp khác.
std::expected<void, std::string> load_animates(Cook& cook) {
    if (!cook.sources.files->read(cook.sources.animates)) return {};
    const auto root = load_xml(cook, cook.sources.animates);
    if (!root) return std::unexpected(root.error());
    for (const Node child : root->children())
        index_animate(cook, child);
    return {};
}

// Hoạt ảnh

// getValueAsBool của CEGUI: "true" hay "1" là đúng; vắng thì sai.
bool flag_attribute(const Node& node, std::string_view key) {
    const std::string_view text = node.attr(key, "");
    return lower(text) == "true" || text == "1";
}

// AlphaType: 0 mờ lên, 2 mờ xuống, còn lại (mặc định 1) mờ lên rồi xuống.
GuiFade fade_of(std::string_view text) noexcept {
    if (text == "0") return GuiFade::kRise;
    return text == "2" ? GuiFade::kFall : GuiFade::kRiseFall;
}

// Thêm ảnh của một <Image ImageName="set:... image:..."> vào frames; ảnh không có thì bỏ, như
// Animate_xmlHandler.
void take_frame(Cook& cook, std::vector<std::int32_t>& frames, const Node& child) {
    if (child.name() != "Image") return;
    const std::string_view value = child.attr("ImageName", "");
    const std::optional<ImageName> name = tagged_image(value);
    if (!name) return;
    const std::int32_t image = image_of(cook, name->set, name->image);
    if (image >= 0) frames.push_back(image);
}

GuiAnimate animate_record(Cook& cook, const Node& element) {
    std::vector<std::int32_t> frames;
    for (const Node child : element.children())
        take_frame(cook, frames, child);
    GuiAnimate animate;
    animate.name = element.attr("Name", "");
    animate.frames.first = static_cast<std::uint32_t>(cook.asset.animate_frames.size());
    animate.frames.count = static_cast<std::uint32_t>(frames.size());
    const std::string_view time = element.attr("PlayTime", "");
    const std::string_view fade = element.attr("AlphaType", "1");
    animate.total_ms = core::parse_whole_int(time).value_or(-1);
    animate.is_looped = flag_attribute(element, "Loop");
    animate.has_alpha = flag_attribute(element, "AlphaMode");
    animate.fade = fade_of(fade);
    std::ranges::copy(frames, std::back_inserter(cook.asset.animate_frames));
    return animate;
}

// Đưa hoạt ảnh name vào asset lần đầu nó được nhắc; không có thì ghi chú một lần.
void take_animate(Cook& cook, std::string_view name) {
    if (name.empty() || cook.animates.contains(name)) return;
    const auto found = cook.animate_xml.find(name);
    const bool is_known = found != cook.animate_xml.end();
    std::string key(name);
    if (!is_known) {
        std::string text = std::format("không có hoạt ảnh {}", name);
        note(cook, std::move(text));
        cook.animates.emplace(std::move(key), -1);
        return;
    }
    const auto index = static_cast<std::int32_t>(cook.asset.animates.size());
    GuiAnimate record = animate_record(cook, found->second);
    cook.asset.animates.push_back(std::move(record));
    cook.animates.emplace(std::move(key), index);
}

// Layout

// Ảnh trong giá trị thuộc tính: "set:<imageset> image:<ảnh>" (PropertyHelper::stringToImage), kể
// cả khi đứng sau thẻ khác như ChildImage "name:... set:... image:..." và IconImage "type:...".
void take_image_value(Cook& cook, std::string_view value) {
    const std::optional<ImageName> name = tagged_image(value);
    if (!name) return;
    [[maybe_unused]] const std::int32_t index = image_of(cook, name->set, name->image);
}

// Thuộc tính mà giá trị là thẳng tên một hoạt ảnh (cửa sổ nháy, nút ô kỹ năng, đồng hồ đếm, nút
// có hoạt ảnh).
constexpr std::array<std::string_view, 4> kAnimateNames = {
    "Animate", "FlashAnimate", "WarningAnimation", "BtnAnimation"};

// Hoạt ảnh mà thuộc tính nhắc tới: tên thẳng (kAnimateNames), hay thẻ "animate:<tên>" như
// AnimateImage và FlashAnimateImage của radar.
void take_animate_value(Cook& cook, const GuiProperty& property) {
    if (std::ranges::contains(kAnimateNames, property.name)) take_animate(cook, property.value);
    const TagValue tagged = tagged_value(property.value, "animate:");
    if (tagged) take_animate(cook, *tagged);
}

void take_image(Cook& cook, std::string_view imageset, const Node& child) {
    if (child.name() != "Image") return;
    [[maybe_unused]] const std::int32_t index = image_of(cook, imageset, child.attr("Name", ""));
}

// Đưa mọi ảnh của imageset name vào asset; không có bộ đó thì ghi chú.
void take_imageset(Cook& cook, std::string_view name) {
    const auto set = cook.imageset_xml.find(name);
    if (set == cook.imageset_xml.end()) {
        std::string text = std::format("không có bộ ảnh {}", name);
        note(cook, std::move(text));
        return;
    }
    for (const Node child : set->second.children())
        take_image(cook, name, child);
}

// MaskImage mang tên một imageset: mặt nạ là cả texture của bộ đó, nên bộ phải có mặt trong asset.
void take_mask_value(Cook& cook, const GuiProperty& property) {
    if (property.name != "MaskImage" || property.value.empty()) return;
    take_imageset(cook, property.value);
}

// Thuộc tính và sự kiện khai trong một <Window> của layout.
struct WindowParts {
    std::vector<GuiProperty> properties;
    std::vector<GuiEvent> events;
};

void window_part(Cook& cook, WindowParts& parts, const Node& child) {
    if (child.name() == "Event") {
        parts.events.push_back(GuiEvent{.name = std::string(child.attr("Name", "")),
                                        .function = std::string(child.attr("Function", ""))});
        return;
    }
    if (child.name() != "Property") return;
    GuiProperty property;
    property.name = child.attr("Name", "");
    property.value = child.attr("Value", "");
    take_image_value(cook, property.value);
    take_animate_value(cook, property);
    take_mask_value(cook, property);
    parts.properties.push_back(std::move(property));
}

// Thêm một cửa sổ cùng thuộc tính của nó (chưa thêm con); trả chỉ số.
std::int32_t add_window(Cook& cook, const Node& element, std::int32_t parent) {
    GuiWindow window;
    window.name = element.attr("Name", "");
    window.parent = parent;
    window.type = type_of(cook, element.attr("Type", "DefaultWindow"));
    WindowParts parts;
    for (const Node child : element.children())
        window_part(cook, parts, child);
    window.properties.first = static_cast<std::uint32_t>(cook.asset.properties.size());
    window.properties.count = static_cast<std::uint32_t>(parts.properties.size());
    std::ranges::move(parts.properties, std::back_inserter(cook.asset.properties));
    window.events.first = static_cast<std::uint32_t>(cook.asset.events.size());
    window.events.count = static_cast<std::uint32_t>(parts.events.size());
    std::ranges::move(parts.events, std::back_inserter(cook.asset.events));
    const auto index = static_cast<std::int32_t>(cook.asset.windows.size());
    cook.asset.windows.push_back(std::move(window));
    return index;
}

// Cửa sổ chờ thêm: phần tử XML và chỉ số cửa sổ cha.
struct WindowTask {
    Node element;
    std::int32_t parent;
};

// Đẩy các <Window> con của element lên ngăn xếp theo thứ tự ngược, để con đầu tiên ra trước.
void push_windows(std::vector<WindowTask>& stack, const Node& element, std::int32_t parent) {
    const auto is_window = [](const Node& child) { return child.name() == "Window"; };
    stack.reserve(stack.size() + element.element().children.size());
    for (const Node child : element.children() | std::views::reverse | std::views::filter(is_window))
        stack.push_back(WindowTask{.element = child, .parent = parent});
}

// Gốc layout là <GUILayout> chứa các <Window>; 32 tệp của client có gốc là chính <Window>. Cha
// luôn đứng trước con, con theo thứ tự trong tệp.
void add_windows(Cook& cook, const Node& root) {
    std::vector<WindowTask> stack;
    if (root.name() == "Window")
        stack.push_back(WindowTask{.element = root, .parent = -1});
    else
        push_windows(stack, root, -1);
    while (!stack.empty()) {
        const WindowTask task = stack.back();
        stack.pop_back();
        const std::int32_t index = add_window(cook, task.element, task.parent);
        push_windows(stack, task.element, index);
    }
}

// TargetType mà bản này dựng cửa sổ con của look: bộ vẽ của chúng cần thanh cuộn và vùng nội dung.
// Combobox dựng ô nhập chữ, nút xổ và danh sách thả của nó (danh sách thả luôn bị giấu: bản này chưa
// mở danh sách). Kiểu khác có <Child> (ChatHistory, Star) chưa có bộ vẽ nên con của chúng chưa dựng.
constexpr std::array<std::string_view, 6> kChildHosts = {"Falagard/Listbox", "Falagard/ListBoxEx",
    "Falagard/ComplexWindow", "Falagard/StaticText", "Falagard/Scrollbar", "Falagard/Combobox"};

// Các <Child> của look mà cửa sổ index dùng; rỗng khi kiểu của nó không thuộc kChildHosts.
GuiRange look_children(const GuiAsset& asset, std::size_t index) {
    const std::int32_t type = asset.windows.at(index).type;
    if (type < 0 || std::cmp_greater_equal(type, asset.types.size())) return {};
    const GuiType& kind = asset.types.at(static_cast<std::size_t>(type));
    const bool is_host = std::ranges::contains(kChildHosts, kind.renderer);
    if (!is_host || kind.look < 0 || std::cmp_greater_equal(kind.look, asset.looks.size())) return {};
    const GuiRange range = asset.looks.at(static_cast<std::size_t>(kind.look)).children;
    const bool is_inside = std::size_t{range.first} + range.count <= asset.children.size();
    return is_inside ? range : GuiRange{};
}

// Ảnh và hoạt ảnh mà các thuộc tính trong khoảng range nhắc tới (NormalImage của nút thanh cuộn...)
// phải có trong asset, như thuộc tính của cửa sổ layout.
void take_property_values(Cook& cook, GuiRange range) {
    for (std::uint32_t slot = 0; slot < range.count; ++slot) {
        const GuiProperty property = cook.asset.properties.at(std::size_t{range.first} + slot);
        take_image_value(cook, property.value);
        take_animate_value(cook, property);
    }
}

// Một <Child> của look và cửa sổ sẽ làm cha của cửa sổ dựng từ nó.
struct ChildSeat {
    std::size_t parent = 0;
    std::uint32_t slot = 0;
};

// Một <Child> của look thành cửa sổ con của cửa sổ seat.parent, như WidgetComponent::create.
void add_look_child(Cook& cook, ChildSeat seat) {
    const GuiChild& child = cook.asset.children.at(seat.slot);
    const auto type = cook.types.find(child.type);
    GuiWindow made;
    made.name = cook.asset.windows.at(seat.parent).name + child.suffix;
    made.type = type == cook.types.end() ? -1 : type->second;
    made.parent = static_cast<std::int32_t>(seat.parent);
    made.properties = child.properties;
    made.child = static_cast<std::int32_t>(seat.slot);
    take_property_values(cook, made.properties);
    cook.asset.windows.push_back(std::move(made));
}

// Dựng cửa sổ con của look cho mọi cửa sổ từ chỉ số first, kể cả con của con vừa dựng (nút và thumb
// của thanh cuộn): danh sách dài ra trong lúc duyệt.
void add_look_children(Cook& cook, std::size_t first) {
    for (std::size_t index = first; index < cook.asset.windows.size(); ++index) {
        const GuiRange range = look_children(cook.asset, index);
        for (std::uint32_t slot = 0; slot < range.count; ++slot) {
            add_look_child(cook, ChildSeat{.parent = index, .slot = range.first + slot});
        }
    }
}

std::expected<void, std::string> load_layout(Cook& cook, std::string_view path) {
    const auto root = load_xml(cook, path);
    if (!root) return std::unexpected(root.error());
    const auto first = static_cast<std::uint32_t>(cook.asset.windows.size());
    add_windows(cook, *root);
    detail::settle_types(cook);
    add_look_children(cook, first);
    const auto count = static_cast<std::uint32_t>(cook.asset.windows.size()) - first;
    GuiLayout layout;
    layout.file = path;
    layout.windows = GuiRange{.first = first, .count = count};
    cook.asset.layouts.push_back(std::move(layout));
    return {};
}

} // namespace

struct GuiLoader::State {
    Cook cook;
};

GuiLoader::GuiLoader(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}
GuiLoader::GuiLoader(GuiLoader&&) noexcept = default;
GuiLoader& GuiLoader::operator=(GuiLoader&&) noexcept = default;
GuiLoader::~GuiLoader() = default;

std::expected<GuiLoader, std::string> GuiLoader::open(const GuiSources& sources) {
    if (sources.files == nullptr) return std::unexpected("không có nguồn tệp giao diện");
    auto state = std::make_unique<State>();
    state->cook.sources = sources;
    const auto scheme = load_scheme(state->cook);
    if (!scheme) return std::unexpected(scheme.error());
    const auto imagesets = load_imagesets(state->cook);
    if (!imagesets) return std::unexpected(imagesets.error());
    const auto animates = load_animates(state->cook);
    if (!animates) return std::unexpected(animates.error());
    return GuiLoader(std::move(state));
}

std::expected<void, std::string> GuiLoader::add_layout(std::string_view path) {
    Cook& cook = state_->cook;
    const std::string key = lower(path);
    if (std::ranges::contains(cook.loaded, key)) return {};
    const auto loaded = load_layout(cook, path);
    if (!loaded) return loaded;
    cook.loaded.push_back(key);
    return {};
}

void GuiLoader::add_imageset(std::string_view name) {
    take_imageset(state_->cook, name);
}

const GuiAsset& GuiLoader::asset() const noexcept {
    return state_->cook.asset;
}

std::span<const std::string> GuiLoader::notes() const noexcept {
    return state_->cook.notes;
}

} // namespace game::gui
