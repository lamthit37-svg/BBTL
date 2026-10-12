// Cấu trúc và hàm dùng chung của dàn trang: layout.cpp đặt cửa sổ và đo kích thước, paint.cpp ra
// lệnh vẽ ảnh, text.cpp ra dòng chữ, hub.cpp giữ bộ nhớ đệm và thăm dò chuột. Nội bộ module gui.
#pragma once

#include "gui/asset.hpp"
#include "gui/detail/name_map.hpp"
#include "gui/scroll.hpp"
#include "gui/sheet.hpp"
#include "gui/value.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <iterator>
#include <optional>
#include <span>
#include <string_view>
#include <vector>

namespace game::gui::detail {

// Bộ vẽ của một kiểu cửa sổ (TargetType của FalagardMapping), gom theo cách vẽ.
enum class Kind : std::uint8_t {
    kPlain,
    kButton,
    kCheck,
    kEdit,
    kText,
    kProgress,
    kRadar,
    kMapImage,
    // Falagard/MeshWindow/ParentWindow: cha của cửa sổ mô hình, mang mặt nạ cho con cháu.
    kMaskHost,
    // Falagard/MeshWindow: ảnh của một fake object.
    kMesh,
    // Falagard/SoftKeyWindow: bàn phím ảo, bộ vẽ ở softkey.cpp.
    kSoftKeys,
    // Falagard/ActionButton: ô action vẽ chồng lớp (nền, icon trong ActionArea, lớp phủ).
    kAction,
    // Falagard/Listbox: danh sách mục chữ có thanh cuộn dọc.
    kList,
    // Falagard/ComplexWindow: các phần tử xếp dọc (chữ, tiền, nút action) có thanh cuộn dọc.
    kComplex,
    // Falagard/Scrollbar và Falagard/Thumb: thanh cuộn (con của look) và con chạy của nó.
    kScrollbar,
    kThumb,
};

// Chỉ số ảnh theo "imageset/tên".
using ImageIndex = NameMap<std::int32_t>;

// Một cửa sổ đã đặt: ô trên màn hình, hiện hay ẩn, và kiểu cùng look của nó.
struct Placed {
    Box screen;
    bool is_visible = false;
    const GuiWindow* window = nullptr;
    const GuiType* type = nullptr;
    const GuiLook* look = nullptr;
    Kind kind = Kind::kPlain;
    bool is_on_top = false;
    // Cuộn của danh sách, cửa sổ phức hợp và của thanh cuộn thuộc về chúng: cỡ tài liệu, cỡ trang
    // và vị trí đã kẹp. Cửa sổ khác để 0.
    ScrollSpan span;
    float scroll = 0.0F;
    // Cao một mục của danh sách (0 khi lần dàn trang không có số đo chữ).
    float row = 0.0F;
};

// Mọi thứ một lượt vẽ cần: asset, đầu vào, các cửa sổ đã đặt, nơi ghi lệnh, và trạng thái chuột.
struct Ctx {
    const GuiAsset* asset = nullptr;
    const Place* input = nullptr;
    std::span<const Placed> placed;
    Sheet* sheet = nullptr;
    const ImageIndex* images = nullptr;
    const Placed* hot = nullptr;
    // Mức đang vẽ của từng thanh trong input->bars (cùng thứ tự), sau khi Hub trượt.
    std::span<const float> bar_fills;
    bool is_live_pass = false;
    bool is_down = false;
};

// Một GuiFormat đã đọc trên một cửa sổ, chưa đổi ra chỉ số: tên mà thuộc tính của cửa sổ nêu
// (nullopt khi format không đọc thuộc tính hay cửa sổ không đặt nó) và giá trị cố định của look.
struct FormatValue {
    std::optional<std::string_view> name;
    std::uint8_t fixed = 0;

    // Chỉ số của name trong names, bảng tên của enum (names.hpp); fixed khi không có tên hay tên lạ.
    [[nodiscard]] constexpr std::uint8_t index_in(std::span<const std::string_view> names) const noexcept {
        if (!name) return fixed;
        const auto found = std::ranges::find(names, *name);
        if (found == names.end()) return fixed;
        return static_cast<std::uint8_t>(std::distance(names.begin(), found));
    }
};

// layout.cpp

// PixelAligned của CEGUI: (int)(x + 0,5), cắt về 0 nên số âm lệch làm tròn thường (-4 ra -3).
[[nodiscard]] float pixel_align(float value) noexcept;
// UDim đổi ra điểm ảnh trên cỡ cha base.
[[nodiscard]] float abs_of(GuiUDim dim, float base) noexcept;
[[nodiscard]] bool in_range(std::size_t size, GuiRange range) noexcept;
[[nodiscard]] bool is_pressable(Kind kind) noexcept;
// Các thuộc tính của layout cho cửa sổ, theo thứ tự trong tệp (một tên có thể lặp, như ChildImage).
[[nodiscard]] std::span<const GuiProperty> window_properties(const GuiAsset& asset, const Placed& placed) noexcept;
// Thuộc tính cuối cùng mang tên name trong khoảng của asset.properties.
[[nodiscard]] std::optional<std::string_view> last_prop(const GuiAsset& asset, GuiRange range, std::string_view name);
// Giá trị đặt lúc chạy cho thuộc tính name của cửa sổ placed; dòng sau thắng.
[[nodiscard]] std::optional<std::string_view> forced(const Place& input, const Placed& placed, std::string_view name);
// Giá trị hiệu lực: Override thắng thuộc tính của layout, rồi tới thuộc tính của look.
[[nodiscard]] std::optional<std::string_view> effective(const Ctx& ctx, const Placed& placed, std::string_view name);
// Cờ true của thuộc tính hiệu lực, như Disabled, Selected, Caret.
[[nodiscard]] bool flag(const Ctx& ctx, const Placed& self, std::string_view name);
[[nodiscard]] const GuiImage* image_at(const GuiAsset& asset, std::int32_t index) noexcept;
// Đặt mọi cửa sổ của asset theo UDim, cha trước con.
[[nodiscard]] std::vector<Placed> layout(const GuiAsset& asset, const Place& input);
// Ô của một vùng thành phần (ComponentArea) theo cửa sổ self, trong ô local của cha.
[[nodiscard]] Box area_box(const Ctx& ctx, const Placed& self, const GuiArea& area, Box local);
// Cửa sổ đã đặt mang tên name; nullptr khi không có.
[[nodiscard]] const Placed* find_placed(const Ctx& ctx, std::string_view name) noexcept;
// Ô trên màn hình của NamedArea name của look; nullopt khi cửa sổ không có look hay look không có
// vùng ấy.
[[nodiscard]] std::optional<Box> named_area(const Ctx& ctx, const Placed& self, std::string_view name);
// <Child> của look mà cửa sổ self dùng, theo hậu tố tên; nullptr khi không có.
[[nodiscard]] const GuiChild* look_child(const GuiAsset& asset, const Placed& self, std::string_view suffix);

// paint.cpp

// Ô local dời theo gốc origin.
[[nodiscard]] Box shift(Box local, Box origin) noexcept;
[[nodiscard]] std::uint32_t colour_of(const GuiColourSource& source) noexcept;
// Màu vẽ của một thành phần (khung, ảnh, chữ) trong section đi qua spec: màu của thành phần, nhân
// với Colours của spec khi spec có (SectionSpecification::render rồi initColoursRect của CEGUI).
[[nodiscard]] std::uint32_t tinted(const GuiSpec& spec, const GuiColourSource& part) noexcept;
// format đọc trên cửa sổ self; đổi ra giá trị enum bằng index_in với bảng tên của enum đó.
[[nodiscard]] FormatValue format_value(const Ctx& ctx, const Placed& self, const GuiFormat& format);
// Cả ảnh image kéo kín ô dest trên màn hình, nhân màu colour; ô không có diện tích thì không vẽ.
void push_whole(Sheet& sheet, const GuiImage& image, Box dest, std::uint32_t colour);
// Ảnh mang tên name (bộ ảnh và tên ảnh) theo chỉ số ảnh của ctx; nullptr khi lượt vẽ không có chỉ
// số ảnh hay asset không có ảnh ấy.
[[nodiscard]] const GuiImage* named_image(const Ctx& ctx, const ImageName& name);
[[nodiscard]] const GuiState* state_named(const GuiAsset& asset, const GuiLook& look, std::string_view name);
// State của look mà nút đang vẽ theo trạng thái của nó (khoá, nhấn, đang chọn, dưới chuột);
// nullptr khi cửa sổ không có look hay look không có state nào dùng được.
[[nodiscard]] const GuiState* button_look_state(const Ctx& ctx, const Placed& self);
// Vẽ state name của look vào ô local; false khi cửa sổ không có look hay look không có state ấy.
bool render_state(const Ctx& ctx, const Placed& self, std::string_view name, Box local);
// Vẽ các ảnh của cửa sổ (nền, khung, ảnh trơn, nút, thanh, radar).
void draw_images(const Ctx& ctx, const Placed& self);

// Phần của các quad từ chỉ số first trở đi nằm trong ô clip (cắt cả ô nguồn theo tỉ lệ); quad nằm
// hẳn ngoài thì bỏ.
void clip_quads(Sheet& sheet, std::size_t first, const Box& clip);

// widgets.cpp

// Cuộn của một cửa sổ có thanh cuộn (danh sách, cửa sổ phức hợp): cỡ tài liệu và trang theo nội dung
// đang giữ, vị trí của thuộc tính ScrollPosition đã kẹp. Kiểu khác thì 0.
struct ScrollView {
    ScrollSpan span;
    float position = 0.0F;
    // Cao một mục, chỉ với danh sách.
    float row = 0.0F;
};
[[nodiscard]] ScrollView scroll_view(const Ctx& ctx, const Placed& self);
// Rãnh của con chạy trong thanh cuộn bar, toạ độ màn hình: mép trên ThumbTrackArea và quãng chạy.
[[nodiscard]] ThumbTrack thumb_track(const Ctx& ctx, const Placed& bar);
// Vùng nội dung trên màn hình của một danh sách (ItemRenderingArea, hẹp lại khi thanh cuộn hiện)
// hay của một cửa sổ phức hợp (ô của __auto_parent__); nullopt với kiểu khác.
[[nodiscard]] std::optional<Box> content_area(const Ctx& ctx, const Placed& self);
// Chỉ số mục của danh sách self dưới điểm pointer; nullopt khi điểm nằm ngoài vùng mục hay trên
// chỗ trống.
[[nodiscard]] std::optional<std::size_t> list_item_under(const Ctx& ctx, const Placed& self, Pointer pointer);
void draw_list(const Ctx& ctx, const Placed& self);
void list_texts(const Ctx& ctx, const Placed& self);
void draw_complex(const Ctx& ctx, const Placed& self);
void complex_texts(const Ctx& ctx, const Placed& self);
void draw_action(const Ctx& ctx, const Placed& self);

// text.cpp

// Ra các dòng chữ của cửa sổ.
void texts_of(const Ctx& ctx, const Placed& self);

} // namespace game::gui::detail
