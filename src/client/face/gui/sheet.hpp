/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/gui/sheet.hpp
 *  PHÂN HỆ   : Face / Gui / Sheet
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Dàn trang giao diện gốc (CEGUI 0.4.1 và Falagard của _ref) từ GuiAsset.
 *    Cửa sổ đặt theo UDim như Window::setWindowArea_impl chế độ Inherited:
 *    PixelAligned(cha * scale) + offset, gốc trái trên. Ảnh tĩnh và nút kéo
 *    giãn cả cửa sổ (StaticImage, FalagardButton::drawNormal). Nút còn vẽ state
 *    BackgroundImage (ActionBK) trước icon. Khung và ảnh của look vẽ theo
 *    FrameComponent và ImageryComponent.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Thanh máu là Falagard/SuperProgress: rộng bằng CurrentProgress nhân rộng cửa sổ. Radar là FalagardSceneMap không
// toàn màn hình, tỉ lệ 4 điểm ảnh một đơn vị cảnh, tâm là người chơi. RoundEnabled vẽ quạt 16 miếng (LookLikeRound).
// Chữ là TextComponent; #{id} tra bảng chuỗi (strings.hpp), không có thì bỏ. Bộ vẽ có ba bộ phụ: Falagard/CheckBox
// (FalagardCheckButton: đang chọn mà không bị nhấn thì vẽ Pushed), Falagard/SimpleText (chữ của cửa sổ, màu
// TextColor, canh HorzFormatting và VertFormatting) và các EditBox (khung Enabled hoặc Normal, chữ trong vùng
// TextArea); thêm bàn phím ảo Falagard/SoftKeyWindow (gui/softkey.hpp). Lua của client gốc đặt chữ, ảnh, ẩn hiện lúc
// chạy; bản này bỏ Lua nên người gọi đưa Override. Nguồn: TLBB Dev src/gui/sheet.hpp@e0d89a6. Khác gốc: namespace
// game::gui; hoạt ảnh Animate (ngoài mũi tên của radar) và gợi ý chưa có. Danh sách, cửa sổ phức hợp, ô action, thanh
// cuộn và MeshWindow đã có: bảng loại widget ở gui/layout.cpp (làm dần cho tới đủ mọi widget của client).

#pragma once

#include "gui/asset.hpp"
#include "gui/scroll.hpp"
#include "gui/strings.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <deque>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::gui {

// Hình chữ nhật theo điểm ảnh, gốc trái trên.
struct Box {
    float x = 0.0F;
    float y = 0.0F;
    float w = 0.0F;
    float h = 0.0F;
};

// texture -1 là màu đặc (source bỏ qua). -2 là ảnh bản đồ cảnh, uv là phần đang thấy. -3 là atlas
// chữ. -4 là ảnh của một fake object (mô hình 3D vẽ ra texture, tên ở Quad::view), phủ cả texture.
// -5 là ảnh bản đồ lớn (SceneMap_Board), uv như -2 nhưng theo atlas riêng của bản đồ lớn.
// -6 là ảnh nền của bản đồ thế giới (WorldMap), uv là phần của ảnh nguyên.
// Từ 0 trở đi là chỉ số texture của GuiAsset; source là ô điểm ảnh trong texture đó.
inline constexpr std::int32_t kSolid = -1;
inline constexpr std::int32_t kSceneMap = -2;
inline constexpr std::int32_t kFont = -3;
inline constexpr std::int32_t kMeshView = -4;
inline constexpr std::int32_t kSceneBoard = -5;
inline constexpr std::int32_t kWorldBoard = -6;
// -7 là chùm sáng hướng nhìn của radar (MapSearchLight.tga): Quad::turn xoay ảnh quanh tâm ô
// source.
inline constexpr std::int32_t kMapLight = -7;

struct Quad {
    std::int32_t texture = kSolid;
    Box dest;
    Box source;
    float u0 = 0.0F;
    float v0 = 0.0F;
    float u1 = 1.0F;
    float v1 = 1.0F;
    // ARGB thẳng, như ColourRect của CEGUI.
    std::uint32_t colour = kWhiteArgb;
    // LookLikeRound: quạt 16 tam giác, không phải hình chữ nhật.
    bool is_round = false;
    // Số thứ tự vẽ của cửa sổ gốc chứa quad này (0 là gốc vẽ đầu tiên).
    std::uint16_t layer = 0;
    // Mặt nạ của cửa sổ tổ tiên gần nhất có MaskImage (Falagard/MeshWindow/ParentWindow của client
    // 2026): chỉ số texture trong GuiAsset, -1 là không có. Cả texture mặt nạ phủ kín mask_box (ô
    // màn hình của cửa sổ đó); bộ vẽ nhân alpha của quad với alpha của mặt nạ theo từng điểm ảnh.
    std::int32_t mask = -1;
    Box mask_box;
    // Tên fake object của quad kMeshView (thuộc tính FakeObject); mượn như TextRun::text.
    std::string_view view;
    // Góc xoay (radian, thuận chiều kim đồng hồ trên màn hình) của ảnh quanh tâm ô chưa cắt.
    // kMapLight: source là ô chưa cắt, dest là phần của ô đó nằm trong cửa sổ cha. Mũi tên của
    // radar (texture >= 0): source là ô ảnh khung, dest là ô nguyên chưa cắt (chỉ xoay khi nó nằm
    // trọn trong cửa sổ cha).
    float turn = 0.0F;
    // Khe động của minimap (kSlot*): quad mà Hub::minimap dựng lại mỗi khung, nên Painter ghi chỗ
    // đỉnh của nó để vá tại chỗ, không dựng lại cả trang. 0 là quad thường.
    std::uint8_t slot = 0;
};

// Khe động của minimap theo thứ tự vẽ: nền, chùm sáng, mũi tên (hay chấm khi thiếu hoạt ảnh).
inline constexpr std::uint8_t kSlotMap = 1;
inline constexpr std::uint8_t kSlotLight = 2;
inline constexpr std::uint8_t kSlotArrow = 3;
inline constexpr std::size_t kSlotCount = 4;

// Lớp CEGUI ra dòng chữ, tức cách đặt khối chữ theo chiều dọc trong ô trước khi gọi Font::drawText
// (mã máy CEGUIBase.dll và CEGUIFalagard.dll 2026, docs/GIAO-DIEN-2026.md mục chữ).
enum class TextRule : std::uint8_t {
    // TextComponent của look (nhãn nút): trên giữ nguyên, giữa cộng nửa phần thừa không làm tròn,
    // dưới là đáy trừ cao khối.
    kComponent,
    // FalagardSimpleText: trên cộng 1, giữa cộng nửa phần thừa đã làm tròn, dưới là đáy trừ cao khối.
    kSimpleText,
    // drawText thẳng vào ô (mục danh sách, phần tử chữ của cửa sổ phức hợp): không canh dọc.
    kRaw,
    // Ô nhập (FalagardIMEEditBox): một dòng canh giữa theo chiều dọc, có con nháy.
    kEdit,
};

// Một dòng chữ. text mượn GuiAsset, bảng chuỗi hoặc bản chép Override của Hub: còn đúng tới lần
// update kế của Hub đó.
struct TextRun {
    std::string_view text;
    // Ô đưa cho Font::drawText (trước bước canh dọc của rule).
    Box box;
    // Ô cắt trên màn hình; rỗng thì cắt theo box.
    std::optional<Box> clip;
    TextRule rule = TextRule::kComponent;
    std::uint32_t colour = kWhiteArgb;
    // GuiTextHorz và GuiTextVert.
    std::uint8_t horz = 0;
    std::uint8_t vert = 0;
    // Ô nhập đang nhận phím: vẽ con nháy sau chữ cuối.
    bool has_caret = false;
    // Chữ nguyên văn do người chơi gõ hay của mặt phím: bộ viết chữ không dò thẻ #, mọi ký tự là
    // chữ (gõ "#c" vào ô tài khoản không được thành thẻ màu).
    bool is_plain = false;
    // Tên phông (thuộc tính Font hay phông của TextComponent); rỗng là phông mặc định của scheme.
    std::string_view font;
    // Số thứ tự vẽ của cửa sổ gốc chứa dòng chữ, cùng nghĩa với Quad::layer.
    std::uint16_t layer = 0;
};

// Thuộc tính đặt lúc chạy, thay SetText, SetProperty, SetCheck, Show và Hide của Lua gốc. Thắng
// thuộc tính của layout và của look; trùng (window, name) thì dòng sau thắng. Ba tên riêng của
// bản viết lại: Selected (nút chọn đang bật), Caret (ô nhập đang nhận phím) và Keys (ký tự của từng
// ô phím của bàn phím ảo).
struct Override {
    std::string_view window;
    std::string_view name;
    std::string_view value;
};

// Cỡ một khối chữ, điểm ảnh.
struct TextSize {
    float width = 0.0F;
    float height = 0.0F;
};

// Số đo chữ mà dàn trang cần để xếp mục danh sách, phần tử của cửa sổ phức hợp, ô tiền và thanh
// cuộn; bộ viết chữ của module ui hiện thực bằng đúng phông và bộ đọc thẻ nó dùng để vẽ. Tên hàm
// gốc của lớp Font (CEGUIBase.dll 2026) ghi ở từng hàm.
class TextMeter {
public:
    // getFontHeight: ascender trừ descender (cỡ phông cộng 2 với phông bitmap).
    [[nodiscard]] virtual float font_height() const = 0;
    // getLineSpacing: bước dòng khai của phông (cỡ phông cộng 2 với phông bitmap).
    [[nodiscard]] virtual float line_spacing() const = 0;
    // getLineSize: bề rộng và bề cao của text trên một dòng, đã đọc thẻ.
    [[nodiscard]] virtual TextSize line_size(std::string_view text) const = 0;
    // getFormattedSize: cỡ khối chữ khi vẽ text vào ô rộng width với kiểu canh horz (GuiTextHorz;
    // từ 4 trở lên là bẻ dòng).
    [[nodiscard]] virtual TextSize formatted_size(std::string_view text, float width, std::uint8_t horz) const = 0;

protected:
    TextMeter() = default;
    TextMeter(const TextMeter&) = default;
    TextMeter& operator=(const TextMeter&) = default;
    TextMeter(TextMeter&&) = default;
    TextMeter& operator=(TextMeter&&) = default;
    ~TextMeter() = default;
};

// Chuột trên khung, điểm ảnh. Có thì nút dưới chuột dùng Hover hoặc Pushed.
struct Pointer {
    float x = 0.0F;
    float y = 0.0F;
    bool is_down = false;
    // Nút phải đang giữ: kéo bản đồ lớn (FalagardSceneMap::onMouseButtonDown nhận nút phải).
    bool is_right_down = false;
};

// Phần ảnh bản đồ đang thấy trong radar, toạ độ 0..1 của cả ảnh cảnh.
struct Radar {
    float u0 = 0.0F;
    float v0 = 0.0F;
    float u1 = 1.0F;
    float v1 = 1.0F;
    // Chỗ người chơi trong cửa sổ radar, điểm ảnh từ góc trái trên, tính từ gốc nhìn đã làm tròn
    // nguyên. Chỗ vẽ mũi tên lấy thẳng số này, không suy lại từ tỉ số u0, u1: phép suy có sai số số
    // thực, quanh nửa điểm ảnh nó làm phép làm tròn lật qua lại. Chỉ minimap đặt (radar_uv); bản đồ
    // lớn để 0 và suy từ uv.
    float mark_x = 0.0F;
    float mark_y = 0.0F;
};

// Mức muốn tới của một thanh, như SetProgress của script gốc. Hub trượt mức đang vẽ tới đó theo
// MoveSpeed của cửa sổ; cửa sổ không có dòng nào thì vẽ CurrentProgress của nó, mặc định 1.
struct Bar {
    std::string_view window;
    float amount = 1.0F;
};

// Màn hình và những cửa sổ được hiện. roots rỗng là hiện mọi cửa sổ gốc. Client gốc giấu hết lúc
// nạp rồi mới mở từng bảng, nên lúc chơi phải kê tên gốc; thứ tự kê là thứ tự vẽ, gốc kê sau nằm
// trên (bảng vừa mở hay vừa bấm vào thì đưa xuống cuối). hidden là tên bị giấu thêm lúc vào game.
struct Place {
    float width = 0.0F;
    float height = 0.0F;
    std::span<const std::string_view> roots;
    std::span<const std::string_view> hidden;
    std::span<const Bar> bars;
    float scene_width = 0.0F;
    float scene_depth = 0.0F;
    float player_x = 0.0F;
    float player_z = 0.0F;
    // Hướng mặt của người chơi theo radian, 0 là +z và tăng về +x (atan2(dx, dz) như client gốc):
    // radar chọn khung của mũi tên theo nó.
    float player_facing = 0.0F;
    // Hướng camera nhìn trên mặt đất, cùng quy ước với player_facing: chùm sáng của radar xoay theo
    // nó (UpdateFlag của UI_CEGUI 0x18003de10 xoay MapLight một góc đối của Camera_GetDirection).
    float view_facing = 0.0F;
    // Minimap dính nền vào lưới điểm ảnh (gốc nhìn nguyên, như PixelAligned của CEGUI) thay vì
    // trượt lẻ mỗi khung. Mặc định trượt lẻ: nền mượt từng khung, mũi tên ở tâm.
    bool is_radar_snapped = false;
    // Thời điểm của lần update trên một đồng hồ đơn điệu: Hub trượt thanh theo khoảng giữa hai lần
    // update liền nhau.
    std::chrono::milliseconds clock{0};
    std::optional<Pointer> pointer;
    std::span<const Override> overrides;
    // Bảng tra #{ID}; nullptr thì chữ #{ID} không vẽ. Phải sống lâu hơn Hub dùng nó.
    const StringBook* strings = nullptr;
    // Số đo chữ; nullptr thì danh sách và cửa sổ phức hợp không có mục nào (không biết cao dòng).
    // Phải sống tới hết lời gọi update.
    const TextMeter* meter = nullptr;
};

// Một chỗ bấm được trên bản đồ thế giới: thành phố và ô của nút hay nhãn của nó, đã cắt theo cửa sổ.
struct WorldHit {
    std::int32_t city = -1;
    Box box;
};

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương của STL MSVC (HP-07)
struct Sheet {
    std::vector<Quad> quads;
    std::vector<TextRun> texts;
    // Chuỗi do bộ vẽ dựng (số trong ô tiền) mà texts mượn. Deque để địa chỉ phần tử không đổi khi thêm
    // và khi di chuyển cả Sheet: chỉ di chuyển, không chép (bản chép trỏ TextRun vào bản gốc).
    std::deque<std::string> made;
    std::optional<Box> radar;
    Radar uv;
    // Bản đồ lớn: ô của cửa sổ, ô vẽ ảnh và phần ảnh cả cảnh đang thấy (board_view).
    std::optional<Box> board;
    Box board_dest;
    Radar board_uv;
    // Bản đồ thế giới (trang tĩnh): ô cửa sổ và các chỗ bấm, cái vẽ sau nằm cuối.
    std::optional<Box> world;
    std::vector<WorldHit> world_hits;
    // Bản chép Override (window, name, value) mà texts mượn chuỗi: sống cùng Sheet.
    std::vector<std::array<std::string, 3>> kept;
};

// Một đỉnh của quạt tròn. kRoundCount là 16 tam giác như VERTEX_PER_ROUND của OgreCEGUIRenderer.
struct Fan {
    float x = 0.0F;
    float y = 0.0F;
    float u = 0.0F;
    float v = 0.0F;
};

inline constexpr std::size_t kRoundCount = 48;

// Cạnh một ô radar theo đơn vị cảnh. createBackground của CEGUIFalagard.dll, SCENE_MAP_PER_PIC.
inline constexpr int kRadarTile = 64;

// Khung của quạt tròn: nửa kính và hệ số lượng giác của LookLikeRound.
struct FanView {
    Box dest;
    float u0 = 0.0F;
    float v0 = 0.0F;
    float u1 = 1.0F;
    float v1 = 1.0F;
};

// LookLikeRound: cùng tâm, bán kính và hệ số sin/cos 22,5 độ với OgreCEGUIRenderer::doRender.
void round_fan(const FanView& view, std::span<Fan, kRoundCount> out) noexcept;

// Cỡ và vị trí của cửa sổ radar trên màn hình cùng cỡ ảnh cảnh, cho radar_uv.
struct RadarAsk {
    float scene_width = 0.0F;
    float scene_depth = 0.0F;
    float window_width = 0.0F;
    float window_height = 0.0F;
    float player_x = 0.0F;
    float player_z = 0.0F;
    // Gốc nhìn làm tròn nguyên điểm ảnh (Place::is_radar_snapped).
    bool is_snapped = false;
};

// FalagardSceneMap::UpdateAllWindow và SetViewByCenter, SCENE_MAP_ZOOMSCALE = 4. Cửa sổ thấy
// window/4 đơn vị cảnh, kẹp sát mép ảnh khi người chơi đứng gần biên.
[[nodiscard]] Radar radar_uv(const RadarAsk& ask) noexcept;

// Bản đồ lớn (Falagard/SceneMap của SceneMap_Board). Cỡ một đơn vị cảnh theo điểm ảnh của từng chế độ
// SceneMapZoom (FalagardSceneMap::UpdateAllWindow, CEGUIFalagard.dll 0x1800c73b0): 1 là 4 x 0,8; 2 là 4;
// 3 là 4 x 2; 4 là 4 x 0,9; 0 là vừa khít cả cảnh (cạnh dài của cảnh bằng chiều cao cửa sổ) khi cảnh ở
// mức 4 điểm ảnh một đơn vị còn lớn hơn cửa sổ, không thì như 2.
struct BoardAsk {
    float scene_width = 0.0F;
    float scene_depth = 0.0F;
    float window_width = 0.0F;
    float window_height = 0.0F;
    std::int32_t mode = 2;
    // Tâm vùng thấy theo đơn vị cảnh; board_view kẹp lại.
    float centre_x = 0.0F;
    float centre_z = 0.0F;
};

struct BoardView {
    // Phần ảnh cả cảnh (0..1) hiện ra, và ô vẽ nó trong cửa sổ (nhỏ hơn cửa sổ khi ảnh nhỏ hơn).
    Radar uv;
    Box dest;
    // Tâm sau khi kẹp (ảnh nhỏ hơn cửa sổ thì là tâm cảnh) và điểm ảnh một đơn vị cảnh.
    float centre_x = 0.0F;
    float centre_z = 0.0F;
    float pixels = 0.0F;
};

// SetViewByCenter rồi UpdateAllWindow: tâm vào giữa cửa sổ, kẹp sát mép ảnh; ảnh nhỏ hơn cửa sổ thì nằm
// giữa cửa sổ. Cảnh hay cửa sổ không có cỡ thì trả BoardView rỗng.
[[nodiscard]] BoardView board_view(const BoardAsk& ask) noexcept;

// Điểm chuột trong cửa sổ radar, gốc ở góc trái trên của cửa sổ.
struct SceneCursor {
    float local_x = 0.0F;
    float local_y = 0.0F;
};

// Toạ độ cảnh dưới chuột. is_on_scene sai khi phép ra ngoài [0, cỡ cảnh] hay cửa sổ không có cỡ.
struct SceneHit {
    float x = 0.0F;
    float z = 0.0F;
    bool is_on_scene = false;
};

// ScreenPosToScenePos rồi chia cho m_fZoomValue, như onMouseMove của FalagardSceneMap.
[[nodiscard]] SceneHit scene_at(const RadarAsk& ask, SceneCursor cursor) noexcept;

// Toạ độ cảnh dưới chuột trên bản đồ lớn; is_on_scene sai khi chuột ngoài ô vẽ ảnh.
[[nodiscard]] SceneHit board_scene_at(const BoardAsk& ask, const BoardView& view, SceneCursor cursor) noexcept;

// Số ô một cạnh: trunc(scene) / kRadarTile, có dư thì cộng một. Scene không dương thì 0.
// Khác gốc: scene >= 2^24 trả 0 để khỏi ép int tràn; DLL không trần.
[[nodiscard]] int radar_tiles(float scene) noexcept;

// true khi phần nguyên của scene chia hết cho kRadarTile. UV 0..1 của radar_uv chỉ khớp lúc đó.
[[nodiscard]] bool radar_grid_exact(float scene) noexcept;

// Đường dẫn ảnh một ô minimap của cảnh, tương đối với thư mục dữ liệu; token là cột szSceneMap
// của bảng cảnh. Rỗng khi token rỗng hay cột, hàng âm.
[[nodiscard]] std::string radar_tile_path(std::string_view token, int column, int row);

// Hướng mặt (radian, như Place::player_facing) và số khung của hoạt ảnh mũi tên.
struct ArrowTurn {
    float facing = 0.0F;
    std::size_t frames = 0;
};

// Khung của mũi tên người chơi trên radar: hướng mặt đổi ra độ nguyên 0..359 rồi nhân số khung
// chia 360, như FalagardSceneMap::setMyselfDir và FalagardRadar::updateMyselfDir. Hướng không hữu
// hạn thì 0.
[[nodiscard]] std::size_t arrow_frame(const ArrowTurn& turn) noexcept;

// Tư thế mũi tên liên tục: khung gần hướng mặt nhất và góc lẻ còn thiếu (radian, thuận chiều kim
// đồng hồ trên màn hình, tối đa nửa bước khung). Khác gốc: gốc chọn khung theo độ nguyên rồi dừng;
// ở đây khung gần nhất xoay nốt phần lẻ để mũi tên quay liền, không nhảy từng nấc 12 độ.
struct ArrowPose {
    std::size_t frame = 0;
    float spin = 0.0F;
};

[[nodiscard]] ArrowPose arrow_pose(const ArrowTurn& turn) noexcept;

// Một bước làm mượt thanh: đang hiện shown, muốn tới target (cùng trong 0..1), tối đa speed mỗi
// giây (mặc định 1, tức đầy thanh trong một giây), trong seconds giây.
struct BarMove {
    float shown = 0.0F;
    float target = 0.0F;
    float speed = 1.0F;
    float seconds = 0.0F;
};

// FalagardSuperProgress::updateSelf: tiến tới target tối đa speed mỗi giây.
[[nodiscard]] float bar_step(const BarMove& move) noexcept;

// Dàn một lần, không giữ trạng thái: thanh nằm ngay ở mức muốn tới (trang đã yên).
[[nodiscard]] Sheet place(const GuiAsset& asset, const Place& input);

// Loại thao tác chuột khi dò cửa sổ, như nEventType của Window::getChildAtPosition: kAny là 0 (dò
// thường), kLeftButton là 1 (nhấn hay nhả nút trái).
enum class Probe : std::uint8_t { kAny, kLeftButton };

// Minimap dựng lại cho một khung: các quad mang khe động (kSlot*) theo thứ tự vẽ và phần ảnh cảnh
// đang thấy. quads sống tới lần Hub::minimap kế.
struct MiniView {
    std::span<const Quad> quads;
    Radar uv;
};

// Trung tâm dàn trang. Chỉ số ảnh dựng một lần. Trang tĩnh giữ khi chỉ thanh máu, radar hay chữ
// động đổi. asset phải sống lâu hơn Hub. Hồ sơ hot của vòng vẽ: không dàn lại cửa sổ mỗi khung.
class Hub {
public:
    explicit Hub(const GuiAsset& asset);
    ~Hub();
    Hub(Hub&&) noexcept;
    Hub& operator=(Hub&&) noexcept;
    Hub(const Hub&) = delete;
    Hub& operator=(const Hub&) = delete;

    void update(const Place& given);
    // Dựng riêng radar nhỏ (minimap) theo input, không đụng trang đã dàn: chỗ đứng và hướng nhìn
    // đổi mỗi khung thì Painter vá đỉnh của các quad khe động thay vì dựng lại cả trang. Gọi sau
    // update; nullopt khi không có radar nhỏ nào đang hiện hay cảnh chưa có cỡ.
    [[nodiscard]] std::optional<MiniView> minimap(const Place& input);
    [[nodiscard]] std::span<const Quad> still() const noexcept;
    [[nodiscard]] std::span<const Quad> live() const noexcept;
    [[nodiscard]] std::span<const TextRun> texts() const noexcept;
    [[nodiscard]] std::optional<Box> radar() const noexcept;
    [[nodiscard]] Radar uv() const noexcept;
    [[nodiscard]] std::uint64_t still_stamp() const noexcept;
    [[nodiscard]] std::uint64_t live_stamp() const noexcept;
    [[nodiscard]] std::uint64_t text_stamp() const noexcept;
    // Số lần dàn lại bố cục từ khi dựng. Override chỉ đổi chữ, ảnh hay màu thì vẽ lại trang tĩnh mà
    // không dàn lại, nên số này không tăng.
    [[nodiscard]] std::uint64_t layout_count() const noexcept;
    // Cửa sổ trên cùng chứa điểm mà loại dò probe chạm được: bỏ qua MouseHollow, nút trái bỏ qua
    // thêm MouseLButtonHollow. nullopt khi trượt hết.
    [[nodiscard]] std::optional<std::string_view> hit(float across, float down, Probe probe) const;
    // Ô trên màn hình của cửa sổ name theo lần update gần nhất; nullopt khi không có hay đang ẩn.
    [[nodiscard]] std::optional<Box> box(std::string_view name) const;
    // Cỡ tài liệu và cỡ trang của danh sách hoặc cửa sổ phức hợp name sau lần update gần nhất.
    // nullopt khi cửa sổ không có, đang ẩn, hoặc không phải hai kiểu ấy.
    [[nodiscard]] std::optional<ScrollSpan> text_span(std::string_view name) const;
    // Ô phím của bàn phím ảo window (Falagard/SoftKeyWindow) dưới điểm pointer theo lần update gần
    // nhất, chỉ số theo gui/softkey.hpp; nullopt khi cửa sổ không có, đang ẩn, không phải bàn phím
    // ảo, hay điểm không nằm trên phím nào.
    [[nodiscard]] std::optional<std::size_t> soft_key(std::string_view window, Pointer pointer) const;
    // Chỉ số (từ 0) của mục danh sách window (Falagard/Listbox) dưới điểm pointer theo lần update
    // gần nhất; nullopt khi cửa sổ không có, đang ẩn, không phải danh sách, hay điểm nằm ngoài vùng
    // mục hoặc trên chỗ trống.
    [[nodiscard]] std::optional<std::size_t> list_item(std::string_view window, Pointer pointer) const;
    // Số lựa chọn (trường thứ hai của phần tử "option" trong thuộc tính Elements) của nút Option dưới điểm pointer trong cửa
    // sổ phức hợp window (Falagard/ComplexWindow) theo lần update gần nhất; nullopt khi cửa sổ không có, đang ẩn, không phải
    // cửa sổ phức hợp, hay điểm không nằm trên nút Option nào.
    [[nodiscard]] std::optional<std::uint32_t> option_at(std::string_view window, Pointer pointer) const;
    // Chỉ số bản ghi (trong thuộc tính Elements, tính cả bản ghi ẩn) của nút phần tử dưới điểm pointer
    // trong cửa sổ thành tích window (Falagard/AchievementWindow) theo lần update gần nhất; nullopt
    // khi cửa sổ không có, đang ẩn, không phải kiểu ấy, hay điểm nằm trên chỗ trống.
    [[nodiscard]] std::optional<std::size_t> element_at(std::string_view window, Pointer pointer) const;
    // Vùng nội dung trên màn hình của danh sách hay cửa sổ phức hợp name theo lần update gần nhất,
    // kể cả khi nó đang ẩn (kho trạng thái của bảng cần cỡ vùng để tính cuộn trước khi bảng mở);
    // nullopt khi không có cửa sổ ấy hay nó thuộc kiểu khác.
    [[nodiscard]] std::optional<Box> content(std::string_view name) const;
    // Rãnh con chạy của thanh cuộn name (toạ độ màn hình) theo lần update gần nhất; nullopt khi cửa
    // sổ không có, đang ẩn hay không phải thanh cuộn.
    [[nodiscard]] std::optional<ThumbTrack> track(std::string_view name) const;
    // Bản đồ lớn theo lần update gần nhất: ô cửa sổ, ô vẽ ảnh và phần ảnh cả cảnh đang thấy. nullopt khi
    // không có cửa sổ bản đồ lớn nào đang hiện.
    [[nodiscard]] std::optional<Box> board() const noexcept;
    [[nodiscard]] Box board_dest() const noexcept;
    [[nodiscard]] Radar board_uv() const noexcept;
    // Bản đồ thế giới theo lần dàn trang tĩnh gần nhất: ô cửa sổ và các chỗ bấm (cái vẽ sau nằm cuối).
    [[nodiscard]] std::optional<Box> world() const noexcept;
    [[nodiscard]] std::span<const WorldHit> world_hits() const noexcept;

private:
    struct Body;
    friend struct HubOps;
    std::unique_ptr<Body> body_;
};

} // namespace game::gui
