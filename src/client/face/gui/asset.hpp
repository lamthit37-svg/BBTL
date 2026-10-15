// Mô hình dữ liệu của giao diện gốc (CEGUI 0.4.1 cùng Falagard của client 2026): scheme, looknfeel,
// imageset và layout đã gom vào các mảng phẳng của GuiAsset. Mọi tham chiếu là chỉ số vào mảng
// phẳng, -1 là không có; khoảng (GuiRange) là phần tử liền nhau của một mảng. Tên kiểu và giá trị
// enum theo đúng CEGUIFalEnums.h để đọc đối chiếu với ref.
// loader.hpp dựng GuiAsset thẳng từ XML gốc lúc chạy; sheet.hpp dàn trang và ra lệnh vẽ.
// Nguồn: TLBB Dev src/cooked/gui_asset.hpp@e0d89a6. Khác gốc: namespace game::gui; enumerator mang
// tiền tố k; textures giữ tên Imagefile của imageset (client nạp thẳng, chưa nấu .ttex); thêm
// GuiLayout để biết cửa sổ nào thuộc layout nào; chưa có đọc và ghi nhị phân (nấu sau khi chạy
// hoàn hảo).
#pragma once

#include <array>
#include <cstdint>
#include <string>
#include <utility>
#include <vector>

namespace game::gui {

// UDim: scale nhân cỡ cha cộng offset điểm ảnh.
struct GuiUDim {
    float scale = 0.0F;
    float offset = 0.0F;
};

// ARGB trắng đục: màu mặc định của ảnh và chữ khi XML không nêu, như colour của CEGUI.
inline constexpr std::uint32_t kWhiteArgb = 0xFFFFFFFFU;

// ColourRect: ARGB bốn góc, thứ tự trên trái, trên phải, dưới trái, dưới phải.
using GuiColours = std::array<std::uint32_t, 4>;
inline constexpr GuiColours kGuiWhite = {kWhiteArgb, kWhiteArgb, kWhiteArgb, kWhiteArgb};

// Độ phân giải gốc của Imageset khi XML không nêu NativeHorzRes, NativeVertRes (CEGUI 0.4).
inline constexpr float kNativeWidth = 640.0F;
inline constexpr float kNativeHeight = 480.0F;

enum class GuiDimType : std::uint8_t {
    kLeftEdge,
    kXPosition,
    kTopEdge,
    kYPosition,
    kRightEdge,
    kBottomEdge,
    kWidth,
    kHeight,
    kXOffset,
    kYOffset,
    kInvalid,
};

enum class GuiDimKind : std::uint8_t { kAbsolute, kImage, kWidget, kUnified, kFont, kProperty };
enum class GuiDimOp : std::uint8_t { kNone, kAdd, kSubtract, kMultiply, kDivide };
enum class GuiFontMetric : std::uint8_t { kLineSpacing, kBaseline, kHorzExtent };

// Một BaseDim của Falagard. operand là Dim kế tiếp nối bằng op (DimOperator), -1 là hết.
struct GuiDim {
    GuiDimKind kind = GuiDimKind::kAbsolute;
    // Dùng cho ImageDim, WidgetDim, UnifiedDim.
    GuiDimType what = GuiDimType::kInvalid;
    GuiDimOp op = GuiDimOp::kNone;
    GuiFontMetric metric = GuiFontMetric::kLineSpacing;
    // AbsoluteDim; với FontDim là padding.
    float value = 0.0F;
    GuiUDim unified;
    std::int32_t image = -1;
    // Hậu tố tên cửa sổ con của WidgetDim, rồi tên thuộc tính, phông và chuỗi của FontDim.
    std::string widget;
    std::string property;
    std::string font;
    std::string text;
    std::int32_t operand = -1;
};

// ComponentArea: bốn Dimension (trái, trên, phải hay rộng, dưới hay cao) hay một thuộc tính URect.
struct GuiArea {
    std::array<std::int32_t, 4> dims = {-1, -1, -1, -1};
    std::array<GuiDimType, 4> types = {
        GuiDimType::kLeftEdge, GuiDimType::kTopEdge, GuiDimType::kWidth, GuiDimType::kHeight};
    std::string property;
};

enum class GuiHorz : std::uint8_t {
    kLeftAligned,
    kCentreAligned,
    kRightAligned,
    kStretched,
    kTiled,
};
enum class GuiVert : std::uint8_t {
    kTopAligned,
    kCentreAligned,
    kBottomAligned,
    kStretched,
    kTiled,
};
enum class GuiTextHorz : std::uint8_t {
    kLeftAligned,
    kRightAligned,
    kCentreAligned,
    kJustified,
    kWordWrapLeftAligned,
    kWordWrapRightAligned,
    kWordWrapCentreAligned,
    kWordWrapJustified,
};
enum class GuiTextVert : std::uint8_t { kTopAligned, kCentreAligned, kBottomAligned };

// Nguồn màu của một thành phần: màu cố định, hay tên thuộc tính của cửa sổ (một màu hay
// ColourRect).
struct GuiColourSource {
    GuiColours colours = kGuiWhite;
    std::string property;
    bool is_rect = false;
};

// Định dạng lấy từ thuộc tính của cửa sổ khi tên khác rỗng, không thì giá trị cố định.
struct GuiFormat {
    std::uint8_t value = 0;
    std::string property;
};

struct GuiImagery {
    GuiArea area;
    GuiColourSource colour;
    std::int32_t image = -1;
    std::string image_property;
    GuiFormat horz{.value = std::to_underlying(GuiHorz::kLeftAligned), .property = {}};
    GuiFormat vert{.value = std::to_underlying(GuiVert::kTopAligned), .property = {}};
};

// Chỗ của từng ảnh trong FrameComponent, như FrameImageComponent.
enum class GuiFramePart : std::uint8_t {
    kBackground,
    kTopLeft,
    kTopRight,
    kBottomLeft,
    kBottomRight,
    kLeftEdge,
    kRightEdge,
    kTopEdge,
    kBottomEdge,
};

struct GuiFrame {
    GuiArea area;
    GuiColourSource colour;
    std::array<std::int32_t, 9> images = {-1, -1, -1, -1, -1, -1, -1, -1, -1};
    GuiFormat horz{.value = std::to_underlying(GuiHorz::kStretched), .property = {}};
    GuiFormat vert{.value = std::to_underlying(GuiVert::kStretched), .property = {}};
};

struct GuiText {
    GuiArea area;
    GuiColourSource colour;
    std::string text;
    std::string font;
    GuiFormat horz{.value = std::to_underlying(GuiTextHorz::kLeftAligned), .property = {}};
    GuiFormat vert{.value = std::to_underlying(GuiTextVert::kTopAligned), .property = {}};
};

struct GuiRange {
    std::uint32_t first = 0;
    std::uint32_t count = 0;
};

struct GuiSection {
    std::string name;
    GuiColourSource master;
    GuiRange frames;
    GuiRange imageries;
    GuiRange texts;
};

// SectionSpecification: section là chỉ số vào sections của asset (đã giải look và tên lúc nạp).
struct GuiSpec {
    std::int32_t section = -1;
    bool overrides = false;
    GuiColourSource colour;
};

struct GuiLayer {
    std::uint32_t priority = 0;
    GuiRange specs;
};

struct GuiState {
    std::string name;
    bool clip_to_display = false;
    GuiRange layers;
};

struct GuiNamedArea {
    std::string name;
    GuiArea area;
};

struct GuiProperty {
    std::string name;
    std::string value;
};

// WidgetComponent (<Child>): cửa sổ con mà look tự dựng, tên là tên cha cộng hậu tố.
struct GuiChild {
    std::string type;
    std::string suffix;
    GuiArea area;
    // HA_LEFT, HA_CENTRE, HA_RIGHT.
    std::uint8_t horz_align = 0;
    // VA_TOP, VA_CENTRE, VA_BOTTOM.
    std::uint8_t vert_align = 0;
    GuiRange properties;
};

// properties gồm cả Property (giá trị khởi tạo) lẫn initialValue của PropertyDefinition.
struct GuiLook {
    std::string name;
    GuiRange states;
    GuiRange areas;
    GuiRange properties;
    GuiRange children;
};

// Kiểu cửa sổ (WindowType của layout) đổi sang bộ vẽ (TargetType của FalagardMapping) và look.
struct GuiType {
    std::string name;
    std::string renderer;
    std::int32_t look = -1;
};

struct GuiImage {
    std::string imageset;
    std::string name;
    std::int32_t texture = -1;
    float x = 0.0F;
    float y = 0.0F;
    float width = 0.0F;
    float height = 0.0F;
    float offset_x = 0.0F;
    float offset_y = 0.0F;
    // Ba trường dưới chỉ ghi thuộc tính của imageset; dàn trang không co ảnh theo chúng vì
    // Imageset::notifyDisplaySizeChanged của CEGUIBase.dll 2026 (RVA 0x59b30) luôn đặt hệ số
    // co 1,0 (mã 2008 chia theo độ phân giải). Cỡ của 117 611 ảnh imageset đều là số nguyên.
    bool auto_scaled = false;
    float native_width = kNativeWidth;
    float native_height = kNativeHeight;
};

// Cách độ đục đổi theo thời gian của một hoạt ảnh có AlphaMode (AlphaType của XML): mờ lên, mờ lên
// rồi mờ xuống, hay mờ xuống (Animate::getFrameAlpha).
enum class GuiFade : std::uint8_t { kRise, kRiseFall, kFall };

// Một hoạt ảnh của AnimateManager (Schema/wowanimate.xml): dãy ảnh phát đều trong total_ms. Radar
// dùng dãy ảnh theo hướng mặt thay cho thời gian.
struct GuiAnimate {
    std::string name;
    // Khoảng trong GuiAsset::animate_frames; ảnh không có trong imageset đã bị bỏ lúc nạp.
    GuiRange frames;
    // PlayTime theo mili giây; -1 khi XML không nêu.
    std::int32_t total_ms = -1;
    bool is_looped = false;
    bool has_alpha = false;
    GuiFade fade = GuiFade::kRiseFall;
};

// Đoạn Lua mà layout nối vào một sự kiện CEGUI của cửa sổ (<Event Name="Clicked" Function="..."/>): name là tên sự
// kiện, function là đoạn Lua nguyên văn (đã giải thực thể XML). Client gốc chạy đoạn đó trong môi trường của cửa sổ chủ
// (CUIWindowItem::FireUIEvent), phần chủ của giao diện Lua (ui/script) làm như vậy.
struct GuiEvent {
    std::string name;
    std::string function;
};

// Cửa sổ của layout, cha đứng trước con; properties là nguyên văn các <Property> của layout.
// Cửa sổ con mà look tự dựng (WidgetComponent: thanh cuộn, nút và thumb của nó, vùng nội dung của
// cửa sổ phức hợp) cũng nằm ở đây, sau các cửa sổ của layout chứa cha nó: tên là tên cha cộng hậu
// tố, properties là các <Property> của <Child>, child là chỉ số của <Child> trong GuiAsset::children.
struct GuiWindow {
    std::string name;
    std::int32_t type = -1;
    std::int32_t parent = -1;
    GuiRange properties;
    // Các <Event> của cửa sổ theo thứ tự trong tệp, trong GuiAsset::events; cửa sổ dựng từ <Child> của look không có.
    GuiRange events;
    // -1 là cửa sổ khai trong layout.
    std::int32_t child = -1;
};

// Một tệp layout đã nạp: đường dẫn tương đối với thư mục Interface và các cửa sổ của nó.
struct GuiLayout {
    std::string file;
    GuiRange windows;
};

struct GuiAsset {
    // Imagefile của imageset (như "Common/png_CornerMark.dds"), tương đối với thư mục Interface.
    std::vector<std::string> textures;
    std::vector<GuiImage> images;
    std::vector<GuiDim> dims;
    std::vector<GuiFrame> frames;
    std::vector<GuiImagery> imageries;
    std::vector<GuiText> texts;
    std::vector<GuiSection> sections;
    std::vector<GuiSpec> specs;
    std::vector<GuiLayer> layers;
    std::vector<GuiState> states;
    std::vector<GuiNamedArea> areas;
    std::vector<GuiProperty> properties;
    std::vector<GuiChild> children;
    std::vector<GuiLook> looks;
    std::vector<GuiType> types;
    std::vector<GuiWindow> windows;
    std::vector<GuiEvent> events;
    std::vector<GuiLayout> layouts;
    std::vector<GuiAnimate> animates;
    // Chỉ số ảnh của từng khung hình, nối liền theo từng hoạt ảnh.
    std::vector<std::int32_t> animate_frames;
};

} // namespace game::gui
