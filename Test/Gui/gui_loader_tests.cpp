// Nạp giao diện gốc (gui/loader.hpp) trên một kho tí hon trong bộ nhớ: scheme hai ánh xạ, looknfeel
// ba look (Section trỏ sang look khác, PropertyDefinition, lớp có màu đè, DimOperator), imageset co
// giãn có độ phân giải gốc, và layout hai cửa sổ lồng nhau. Kiểm cửa sổ, kiểu, look, section, ảnh,
// texture, và tham chiếu hỏng thành ghi chú chứ không làm hỏng lượt nạp.
// Nguồn: TLBB Dev tests/bake/gui_cook_test.cpp@e0d89a6. Khác gốc: khung test của dự án; kho trong
// bộ nhớ là FileSource; đường dẫn là tên gốc (tra không phân biệt hoa thường) thay cho tên sạch;
// thêm ca thứ tự cửa sổ, gốc <Window> và nạp lặp.
#include "core/check.hpp"
#include "gui/asset.hpp"
#include "gui/loader.hpp"
#include "test.hpp"

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <map>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::test {
namespace {

constexpr std::string_view kScheme = R"(<?xml version="1.0" ?>
<GUIScheme Name="S">
  <LookNFeel Filename="Schema/Look.looknfeel.xml" />
  <FalagardMapping WindowType="TLBB_StaticImageNULL" TargetType="Falagard/StaticImage" LookNFeel="Look_Static" />
  <FalagardMapping WindowType="TLBB_Button" TargetType="Falagard/Button" LookNFeel="Look_Button" />
</GUIScheme>)";

constexpr std::string_view kLooks = R"(<?xml version="1.0" ?>
<Falagard>
  <WidgetLook name="Look_Common">
    <ImagerySection name="frame">
      <FrameComponent>
        <Area>
          <Dim type="LeftEdge"><AbsoluteDim value="2" /></Dim>
          <Dim type="TopEdge"><AbsoluteDim value="0" /></Dim>
          <Dim type="Width">
            <UnifiedDim scale="1" type="Width">
              <DimOperator op="Subtract"><AbsoluteDim value="4" /></DimOperator>
            </UnifiedDim>
          </Dim>
          <Dim type="Height"><ImageDim imageset="Btn" image="TL" dimension="Height" /></Dim>
        </Area>
        <Image type="TopLeftCorner" imageset="Btn" image="TL" />
        <Image type="Background" imageset="Btn" image="Missing" />
      </FrameComponent>
    </ImagerySection>
  </WidgetLook>
  <WidgetLook name="Look_Button">
    <PropertyDefinition name="HorzLabelFormatting" initialValue="CentreAligned" />
    <Property name="ClickSound" value="17" />
    <ImagerySection name="own">
      <ImageryComponent>
        <Area><AreaProperty name="IconArea" /></Area>
        <ImageProperty name="NormalImage" />
        <HorzFormat type="Tiled" />
        <VertFormatProperty name="VertImageFormatting" />
      </ImageryComponent>
    </ImagerySection>
    <StateImagery name="Normal">
      <Layer><Section look="Look_Common" section="frame" /></Layer>
    </StateImagery>
    <StateImagery name="Hover" clipped="false">
      <Layer priority="2"><Section section="own" /></Layer>
      <Layer priority="1">
        <Section section="own"><Colours topLeft="FF00FF00" topRight="FF00FF00" bottomLeft="FF00FF00" bottomRight="FF00FF00" /></Section>
      </Layer>
    </StateImagery>
  </WidgetLook>
  <WidgetLook name="Look_Static">
    <StateImagery name="Enabled" />
  </WidgetLook>
</Falagard>)";

constexpr std::string_view kImagesets = R"(<?xml version="1.0" ?>
<allImageset>
<Imageset Name="Btn" Imagefile="Common/Button.dds" AutoScaled="true" NativeHorzRes="1024" NativeVertRes="768">
  <Image Name="TL" XPos="1" YPos="2" Width="3" Height="4" />
  <Image Name="Icon" XPos="5" YPos="6" Width="7" Height="8" XOffset="-1" />
</Imageset>
<Imageset Name="Back" Imagefile="Bg/Back.dds">
  <Image Name="Left" XPos="0" YPos="0" Width="512" Height="512" />
  <Image Name="Right" XPos="512" YPos="0" Width="512" Height="512" />
</Imageset>
</allImageset>)";

constexpr std::string_view kLayout = R"(<?xml version="1.0" ?>
<GUILayout>
  <Window Type="TLBB_StaticImageNULL" Name="Bar">
    <Property Name="UnifiedSize" Value="{{0,100},{0,20}}" />
    <Property Name="Image" Value="set:Btn image:Icon" />
    <Window Type="TLBB_Button" Name="Bar_Close" />
  </Window>
</GUILayout>)";

// Cây cửa sổ thứ tự: A có con B và C (C có con D), rồi E. Gốc là chính <Window> ở tệp khác.
constexpr std::string_view kTree = R"(<GUILayout>
  <Window Type="DefaultWindow" Name="A">
    <Window Type="DefaultWindow" Name="B" />
    <Window Type="DefaultWindow" Name="C"><Window Type="DefaultWindow" Name="D" /></Window>
  </Window>
  <Window Type="DefaultWindow" Name="E" />
</GUILayout>)";

constexpr std::string_view kBareWindow = R"(<Window Type="DefaultWindow" Name="Solo">
  <Window Type="DefaultWindow" Name="Solo_Child" />
</Window>)";

// Bảng hoạt ảnh: mũi tên ba khung (một ảnh không có trong imageset), nháy có độ đục, và một hoạt
// ảnh không cửa sổ nào nhắc tới.
constexpr std::string_view kAnimates = R"(<?xml version="1.0" ?>
<AnimateManager>
  <Animate Name="Arrow" Loop="false">
    <Image ImageName="set:Back image:Right"/>
    <Image ImageName="set:Back image:KhongCo"/>
    <Image ImageName="set:Back image:Left"/>
  </Animate>
  <Animate Name="Flash" Loop="true" AlphaMode="true" PlayTime="800" AlphaType ="2">
    <Image ImageName="set:Btn image:TL"/>
  </Animate>
  <Animate Name="Unused" Loop="true" PlayTime="100">
    <Image ImageName="set:Btn image:Icon"/>
  </Animate>
</AnimateManager>)";

// Radar mang mũi tên, cửa sổ nháy, cửa sổ nhắc hoạt ảnh lạ, và ảnh con của MapImage.
constexpr std::string_view kMapLayout = R"(<GUILayout>
  <Window Type="DefaultWindow" Name="Map">
    <Property Name="AnimateImage" Value="type:Animate10 animate:Arrow" />
    <Property Name="ChildImage" Value="name:Time1 set:Btn image:Icon" />
    <Property Name="MaskImage" Value="Back" />
    <Window Type="DefaultWindow" Name="Map_Flash">
      <Property Name="Animate" Value="Flash" />
    </Window>
    <Window Type="DefaultWindow" Name="Map_Lost">
      <Property Name="Animate" Value="KhongCo" />
    </Window>
    <Window Type="DefaultWindow" Name="Map_Empty">
      <Property Name="Animate" Value="" />
    </Window>
  </Window>
</GUILayout>)";

// Kho trong bộ nhớ; khoá viết thường nên tra không phân biệt hoa thường.
class MemorySource final : public gui::FileSource {
public:
    MemorySource() {
        add("Schema/WoWLookSkin.scheme.xml", kScheme);
        add("Schema/Look.looknfeel.xml", kLooks);
        add("Schema/all.imageset.xml", kImagesets);
        add("Bar/Bar.layout.xml", kLayout);
        add("Tree/Tree.layout.xml", kTree);
        add("Solo/Solo.layout.xml", kBareWindow);
        add("Schema/wowanimate.xml", kAnimates);
        add("Map/Map.layout.xml", kMapLayout);
    }

    [[nodiscard]] std::optional<std::string> read(std::string_view path) const override {
        std::string key(path);
        std::ranges::transform(key, key.begin(), [](char letter) {
            const bool is_upper = letter >= 'A' && letter <= 'Z';
            return is_upper ? static_cast<char>(letter - 'A' + 'a') : letter;
        });
        const auto found = files_.find(key);
        if (found == files_.end()) return std::nullopt;
        return found->second;
    }

private:
    void add(std::string name, std::string_view text) {
        std::ranges::transform(name, name.begin(), [](char letter) {
            const bool is_upper = letter >= 'A' && letter <= 'Z';
            return is_upper ? static_cast<char>(letter - 'A' + 'a') : letter;
        });
        files_.emplace(std::move(name), std::string(text));
    }

    std::map<std::string, std::string> files_;
};

constexpr std::string_view kBarLayout = "Bar/Bar.layout.xml";

// Mở bộ nạp trên kho tí hon; kho phải sống lâu hơn bộ nạp.
std::expected<gui::GuiLoader, std::string> open_tiny(const MemorySource& store) {
    gui::GuiSources sources;
    sources.files = &store;
    return gui::GuiLoader::open(sources);
}

void windows_and_types(Context& context) {
    const MemorySource store;
    auto loader = open_tiny(store);
    context.expect(loader.has_value(), "mở được bộ nạp");
    if (!loader) return;
    const auto added = loader->add_layout(kBarLayout);
    context.expect(added.has_value(), "nạp được layout");
    const gui::GuiAsset& asset = loader->asset();
    context.expect(asset.windows.size() == 2, "hai cửa sổ");
    if (asset.windows.size() != 2) return;
    context.expect(asset.windows.at(0).name == "Bar" && asset.windows.at(0).parent == -1, "gốc");
    context.expect(asset.windows.at(1).name == "Bar_Close" && asset.windows.at(1).parent == 0, "con về cha");
    const gui::GuiType& bar = asset.types.at(static_cast<std::size_t>(asset.windows.at(0).type));
    context.expect(bar.renderer == "Falagard/StaticImage", "bộ vẽ theo FalagardMapping");
    const bool has_look = bar.look >= 0 && asset.looks.at(static_cast<std::size_t>(bar.look)).name == "Look_Static";
    context.expect(has_look, "look");
    context.expect(asset.layouts.size() == 1 && asset.layouts.at(0).windows.count == 2, "layout");
}

void images_and_textures(Context& context) {
    const MemorySource store;
    auto loader = open_tiny(store);
    if (!loader) {
        context.expect(false, "mở được bộ nạp");
        return;
    }
    const auto added = loader->add_layout(kBarLayout);
    context.expect(added.has_value(), "nạp được layout");
    const gui::GuiAsset& asset = loader->asset();
    const bool is_texture = asset.textures.size() == 1 && asset.textures.at(0) == "Common/Button.dds";
    context.expect(is_texture, "texture theo Imagefile của imageset");
    context.expect(asset.images.size() == 2, "ảnh của thuộc tính Image và của khung, không thừa");
    const auto icon = std::ranges::find(asset.images, "Icon", &gui::GuiImage::name);
    const bool has_icon = icon != asset.images.end();
    context.expect(has_icon && icon->offset_x == -1.0F && icon->native_width == 1024.0F,
        "toạ độ, độ lệch và độ phân giải gốc");
    context.expect(has_icon && icon->auto_scaled, "imageset co giãn");
    context.expect(loader->notes().size() == 1, "ảnh Missing thành một ghi chú");
}

// Look_Button: Normal trỏ section frame của Look_Common; Hover có hai lớp xếp theo độ ưu tiên, lớp
// thấp mang màu đè. frame có Dim nối bằng Subtract.
void looks_and_sections(Context& context) {
    const MemorySource store;
    auto loader = open_tiny(store);
    if (!loader) {
        context.expect(false, "mở được bộ nạp");
        return;
    }
    const auto added = loader->add_layout(kBarLayout);
    context.expect(added.has_value(), "nạp được layout");
    const gui::GuiAsset& asset = loader->asset();
    const auto button = std::ranges::find(asset.looks, "Look_Button", &gui::GuiLook::name);
    context.expect(button != asset.looks.end() && button->states.count == 2, "hai trạng thái");
    if (button == asset.looks.end() || button->states.count != 2) return;
    const gui::GuiState& hover = asset.states.at(button->states.first + 1);
    context.expect(hover.name == "Hover" && hover.clip_to_display, "clipped=false là cắt theo màn");
    context.expect(hover.layers.count == 2, "Hover có hai lớp");
    const gui::GuiLayer& first = asset.layers.at(hover.layers.first);
    context.expect(first.priority == 1 && asset.specs.at(first.specs.first).overrides, "lớp thấp vẽ trước, có màu đè");
    const gui::GuiState& normal = asset.states.at(button->states.first);
    const gui::GuiLayer& layer = asset.layers.at(normal.layers.first);
    const auto section_at = static_cast<std::size_t>(asset.specs.at(layer.specs.first).section);
    const gui::GuiSection& frame = asset.sections.at(section_at);
    context.expect(frame.name == "frame" && frame.frames.count == 1, "section của look khác");
    const gui::GuiFrame& component = asset.frames.at(frame.frames.first);
    const gui::GuiDim& width = asset.dims.at(static_cast<std::size_t>(component.area.dims.at(2)));
    context.expect(width.op == gui::GuiDimOp::kSubtract && width.operand >= 0, "DimOperator");
    context.expect(button->properties.count == 2, "PropertyDefinition và Property");
}

void missing_layout(Context& context) {
    const MemorySource store;
    auto loader = open_tiny(store);
    if (!loader) {
        context.expect(false, "mở được bộ nạp");
        return;
    }
    context.expect(!loader->add_layout("Khong/Co.layout.xml").has_value(), "thiếu layout là lỗi");
    context.expect(loader->asset().layouts.empty(), "layout lỗi không để lại gì");
}

// Layout nạp hai lần (kể cả viết hoa thường khác) chỉ vào asset một lần.
void layout_loaded_once(Context& context) {
    const MemorySource store;
    auto loader = open_tiny(store);
    if (!loader) {
        context.expect(false, "mở được bộ nạp");
        return;
    }
    context.expect(loader->add_layout(kBarLayout).has_value(), "lần một");
    context.expect(loader->add_layout("bar/BAR.layout.xml").has_value(), "lần hai khác hoa thường");
    context.expect(loader->asset().windows.size() == 2, "không nạp trùng cửa sổ");
    context.expect(loader->asset().layouts.size() == 1, "một layout");
}

// Cha đứng trước con, con theo thứ tự trong tệp, gốc <Window> cũng nạp được.
void window_order(Context& context) {
    const MemorySource store;
    auto loader = open_tiny(store);
    if (!loader) {
        context.expect(false, "mở được bộ nạp");
        return;
    }
    context.expect(loader->add_layout("Tree/Tree.layout.xml").has_value(), "nạp cây");
    const gui::GuiAsset& asset = loader->asset();
    constexpr std::array<std::string_view, 5> kNames = {"A", "B", "C", "D", "E"};
    constexpr std::array<int, 5> kParents = {-1, 0, 0, 2, -1};
    context.expect(asset.windows.size() == kNames.size(), "năm cửa sổ");
    if (asset.windows.size() != kNames.size()) return;
    for (std::size_t index = 0; index < kNames.size(); ++index) {
        context.expect(asset.windows.at(index).name == kNames.at(index), "tên theo thứ tự");
        context.expect(asset.windows.at(index).parent == kParents.at(index), "cha theo thứ tự");
    }
    context.expect(loader->add_layout("Solo/Solo.layout.xml").has_value(), "nạp gốc <Window>");
    const gui::GuiLayout& solo = loader->asset().layouts.at(1);
    context.expect(solo.windows.first == 5 && solo.windows.count == 2, "khoảng cửa sổ của Solo");
}

// Ảnh mà mã gán lúc chạy không hiện trong layout: đưa cả bộ ảnh theo tên.
void extra_sets(Context& context) {
    const MemorySource store;
    auto loader = open_tiny(store);
    if (!loader) {
        context.expect(false, "mở được bộ nạp");
        return;
    }
    context.expect(loader->add_layout(kBarLayout).has_value(), "nạp được layout");
    loader->add_imageset("Back");
    loader->add_imageset("KhongCo");
    const gui::GuiAsset& asset = loader->asset();
    context.expect(asset.images.size() == 4, "hai ảnh của layout cộng hai ảnh của bộ Back");
    const bool is_texture = asset.textures.size() == 2 && asset.textures.at(1) == "Bg/Back.dds";
    context.expect(is_texture, "texture của bộ thêm");
    context.expect(loader->notes().size() == 2, "bộ ảnh lạ thành một ghi chú nữa");
}

const gui::GuiAnimate* animate_named(const gui::GuiAsset& asset, std::string_view name) {
    const auto is_named = [name](const gui::GuiAnimate& animate) { return animate.name == name; };
    const auto found = std::ranges::find_if(asset.animates, is_named);
    return found == asset.animates.end() ? nullptr : &*found;
}

// Chỉ hoạt ảnh được cửa sổ nhắc tới mới vào asset; khung thiếu ảnh bị bỏ như Animate_xmlHandler.
void animates_of_windows(Context& context) {
    const MemorySource store;
    auto loader = open_tiny(store);
    if (!loader) {
        context.expect(false, "mở được bộ nạp");
        return;
    }
    context.expect(loader->add_layout("Map/Map.layout.xml").has_value(), "nạp được layout");
    const gui::GuiAsset& asset = loader->asset();
    context.expect(asset.animates.size() == 2, "hai hoạt ảnh được nhắc tới");
    const gui::GuiAnimate* arrow = animate_named(asset, "Arrow");
    const gui::GuiAnimate* flash = animate_named(asset, "Flash");
    context.expect(arrow != nullptr && flash != nullptr, "mũi tên và nháy");
    if (arrow == nullptr || flash == nullptr) return;
    context.expect(arrow->frames.count == 2, "khung thiếu ảnh bị bỏ");
    context.expect(!arrow->is_looped && arrow->total_ms == -1, "không lặp, không PlayTime");
    const bool is_default_fade = !arrow->has_alpha && arrow->fade == gui::GuiFade::kRiseFall;
    context.expect(is_default_fade, "AlphaType mặc định 1");
    const auto first = static_cast<std::size_t>(arrow->frames.first);
    const std::int32_t right = asset.animate_frames.at(first);
    const std::int32_t left = asset.animate_frames.at(first + 1);
    const bool is_ordered = asset.images.at(static_cast<std::size_t>(right)).name == "Right" &&
        asset.images.at(static_cast<std::size_t>(left)).name == "Left";
    context.expect(is_ordered, "khung giữ thứ tự của tệp");
    context.expect(flash->is_looped && flash->total_ms == 800, "lặp, 800 ms");
    context.expect(flash->has_alpha && flash->fade == gui::GuiFade::kFall, "AlphaType 2");
    const auto is_icon = [](const gui::GuiImage& image) { return image.name == "Icon"; };
    context.expect(std::ranges::any_of(asset.images, is_icon), "ảnh con của ChildImage vào asset");
    const auto is_back = [](const gui::GuiImage& image) { return image.imageset == "Back"; };
    context.expect(std::ranges::count_if(asset.images, is_back) == 2, "MaskImage kéo cả imageset");
    const auto notes = loader->notes();
    const auto is_lost = [](const std::string& note) { return note.contains("hoạt ảnh KhongCo"); };
    context.expect(std::ranges::count_if(notes, is_lost) == 1, "hoạt ảnh lạ thành một ghi chú");
}

// Không có tệp hoạt ảnh thì vẫn mở được; cửa sổ nhắc tới hoạt ảnh ra ghi chú.
void animates_optional(Context& context) {
    const MemorySource store;
    gui::GuiSources sources;
    sources.files = &store;
    sources.animates = "Schema/khong_co.xml";
    auto loader = gui::GuiLoader::open(sources);
    context.expect(loader.has_value(), "thiếu bảng hoạt ảnh vẫn mở được");
    if (!loader) return;
    context.expect(loader->add_layout("Map/Map.layout.xml").has_value(), "nạp được layout");
    context.expect(loader->asset().animates.empty(), "không có hoạt ảnh nào");
    context.expect(loader->notes().size() == 3, "ba hoạt ảnh được nhắc mà không có");
}

void missing_scheme(Context& context) {
    const gui::GuiSources sources;
    context.expect(!gui::GuiLoader::open(sources).has_value(), "thiếu nguồn tệp là lỗi");
}

void phone_layout_overrides_pc(Context& context) {
    namespace files = std::filesystem;
    std::filesystem::path root = files::temp_directory_path() / "tl_phone_layout";
    files::create_directories(root / "PlayerFrame");
    files::create_directories(root / "phone" / "PlayerFrame");
    files::create_directories(root / "MiniMap");
    std::ofstream pc(root / "PlayerFrame" / "PlayerFrame.layout.xml");
    pc << "pc";
    pc.close();
    std::ofstream phone(root / "phone" / "PlayerFrame" / "PlayerFrame.layout.xml");
    phone << "phone";
    phone.close();
    std::ofstream only_pc(root / "MiniMap" / "MiniMap.layout.xml");
    only_pc << "map";
    only_pc.close();
    const gui::DiskSource mobile(root, true);
    const gui::DiskSource desk(root, false);
    const auto over = mobile.read("PlayerFrame/PlayerFrame.layout.xml");
    const auto kept = desk.read("PlayerFrame/PlayerFrame.layout.xml");
    const auto fallback = mobile.read("MiniMap/MiniMap.layout.xml");
    context.expect(over.has_value() && *over == "phone", "điện thoại lấy bản phone/");
    context.expect(kept.has_value() && *kept == "pc", "PC giữ layout gốc");
    context.expect(fallback.has_value() && *fallback == "map", "thiếu bản phone thì dùng PC");
    files::remove_all(root);
}

constexpr std::array kCases{
    Case{.name = "windows_and_types", .body = &windows_and_types},
    Case{.name = "images_and_textures", .body = &images_and_textures},
    Case{.name = "looks_and_sections", .body = &looks_and_sections},
    Case{.name = "missing_layout", .body = &missing_layout},
    Case{.name = "layout_loaded_once", .body = &layout_loaded_once},
    Case{.name = "window_order", .body = &window_order},
    Case{.name = "extra_sets", .body = &extra_sets},
    Case{.name = "animates_of_windows", .body = &animates_of_windows},
    Case{.name = "animates_optional", .body = &animates_optional},
    Case{.name = "missing_scheme", .body = &missing_scheme},
    Case{.name = "phone_layout_overrides_pc", .body = &phone_layout_overrides_pc},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "gui_loader_tests: mọi ca phải qua");
    return 0;
}
