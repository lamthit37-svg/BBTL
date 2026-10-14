// Giao diện gốc của client 2026 trên dữ liệu thật trong CLIENT/data/Interface (TOOLS/content/
// collect_ui.py gom): nạp scheme, looknfeel, imageset rồi mọi layout đã gom, kiểm không layout nào
// lỗi, mọi tham chiếu ảnh giải được (ghi chú chỉ gồm ảnh thiếu có chủ đích của dữ liệu gốc), mọi
// texture có tệp PNG, và dàn trang ra quad hợp lệ ở ba cỡ màn hình. Chỉ đăng ký khi đã gom dữ liệu.
// Ca so golden đối chiếu ô của mọi cửa sổ với tests/golden/ui_rects.tsv: bản tính độc lập
// (TOOLS/content/ui_rects.py) theo Window::setWindowArea_impl và getUnclippedPixelRect của
// CEGUIBase.dll 2026, ở bốn cỡ màn hình.
#include "core/check.hpp"
#include "gui/asset.hpp"
#include "gui/loader.hpp"
#include "gui/sheet.hpp"
#include "gui/value.hpp"
#include "io/file.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <fstream>
#include <ios>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <filesystem>
#include <optional>
#include <ranges>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

namespace fs = std::filesystem;

// Thư mục dữ liệu client mà bản dựng biết; rỗng thì các ca tự bỏ qua.
#ifdef GAME_CLIENT_DATA
constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
constexpr std::string_view kClientData;
#endif

// Thư mục chứa ui_rects.tsv; rỗng thì ca so golden tự bỏ qua.
#ifdef GAME_UI_GOLDEN
constexpr std::string_view kGoldenFolder = GAME_UI_GOLDEN;
#else
constexpr std::string_view kGoldenFolder;
#endif

// Thư mục Interface đã gom của bản dựng.
fs::path interface_root() {
    return fs::path(std::string(kClientData)) / "Interface";
}

// Đường dẫn tương đối (dấu /) của mọi layout đã gom, theo thứ tự tên.
std::vector<std::string> collected_layouts() {
    const fs::path root = interface_root();
    std::vector<std::string> layouts;
    if (kClientData.empty()) return layouts;
    for (const fs::directory_entry& entry : fs::recursive_directory_iterator(root))
        layouts.push_back(fs::relative(entry.path(), root).generic_string());
    std::erase_if(layouts, [](const std::string& name) { return !name.ends_with(".layout.xml"); });
    std::ranges::sort(layouts);
    return layouts;
}

// Bộ nạp đã mở và nạp mọi layout đã gom; lỗi nạp từng layout ghi vào failures.
struct Loaded {
    std::optional<gui::GuiLoader> loader;
    std::vector<std::string> failures;
};

void add_one(
    gui::GuiLoader& loader, std::vector<std::string>& failures, const std::string& layout) {
    const auto added = loader.add_layout(layout);
    if (!added) failures.push_back(layout + ": " + added.error());
}

// Layout điện thoại (phone/) dự án tự dựng: không có bản gốc, cửa sổ trùng tên cửa sổ PC.
bool is_phone_layout(std::string_view layout) {
    return layout.starts_with("phone/");
}

Loaded load_all(const gui::FileSource& files, bool with_phone = true) {
    Loaded loaded;
    gui::GuiSources sources;
    sources.files = &files;
    auto opened = gui::GuiLoader::open(sources);
    if (!opened) {
        loaded.failures.push_back(opened.error());
        return loaded;
    }
    loaded.loader.emplace(std::move(*opened));
    for (const std::string& layout : collected_layouts())
        if (with_phone || !is_phone_layout(layout)) add_one(*loaded.loader, loaded.failures, layout);
    return loaded;
}

void loads_every_layout(Context& context) {
    const gui::DiskSource files(interface_root());
    const Loaded loaded = load_all(files);
    context.expect(loaded.loader.has_value(), "mở được scheme, looknfeel, imageset");
    context.expect(loaded.failures.empty(), loaded.failures.empty() ? "" : loaded.failures.front());
    if (!loaded.loader) return;
    const gui::GuiAsset& asset = loaded.loader->asset();
    context.expect(asset.layouts.size() == collected_layouts().size(), "mọi layout vào asset");
    context.expect(asset.windows.size() > 500, "HUD có hàng trăm cửa sổ");
    const auto is_root = [](const gui::GuiWindow& window) { return window.parent < 0; };
    context.expect(std::ranges::count_if(asset.windows, is_root) >= 15, "mỗi layout có cửa sổ gốc");
}

// Ghi chú chỉ được là chỗ hỏng có sẵn trong dữ liệu gốc, kê đủ từng cái: 52 ảnh và 7 hoạt ảnh mà layout
// gốc nhắc tới nhưng client 2026 không nạp được (F:\tl 2026\_goc, đối chiếu 2026-10-14). Thêm một chỗ
// hỏng mới (loader bỏ sót tệp, đổi tên khoá ảnh) làm ca đỏ, không bị trần số lượng nuốt mất.
constexpr auto kMissingImages = std::to_array<std::string_view>({
    // Hai mươi ảnh của bộ ảnh không có tệp imageset nào (scheme không kê, all.imageset.xml không khai).
    "Announce6/Bhsc_Title_Monster", "BaseInterface/Red_Dot", "Chat/CommonEditBoxBK", "DaHuaQiXi_Shop/YuanYe_Mid",
    "HSLJ_01/HSLJ_One", "LongZhengHandBook3/HandBook_Title11", "MainMenuBar/EXPBar_3",
    "MenPaiWar_TopList/MenPaiWar_TopListBK1", "Peak_Second/Peak_Second_MainBK", "PlayerFrame/10PX_Bar_Blue",
    "PlayerFrame/10PX_Bar_Yellow", "Redenvelope/History_BK", "SeventhFestivalTopList/SeventhFestivalTopList_1",
    "ShaXing_TopList/ShaXing_TopListTop1", "SongLiao02/Down_Disabled", "SongLiao02/Down_Hover",
    "SongLiao02/Down_Normal", "SongLiao02/Down_Pushed", "Thanksgiving_FeedBack/Thanksgiving_FeedBack_Line",
    "ZhengTaoPVP/ZhengTaoPVP_MenPaiLine",
    // Hai mươi ba ảnh của ba bộ (chunfen, chunfen1, WeixinHongbaoPaisong) có tệp riêng ở Common/ nhưng
    // WoWLookSkin.scheme.xml gốc kê chúng trong chú thích XML (hoạt động đã ngừng), nên client gốc không nạp.
    "chunfen/chunfen_bk", "chunfen/chunfenbutton1_Disabled", "chunfen/chunfenbutton1_Hover",
    "chunfen/chunfenbutton1_Normal", "chunfen/chunfenbutton1_Pushed", "chunfen/chunfenclose_Disabled",
    "chunfen/chunfenclose_Hover", "chunfen/chunfenclose_Normal", "chunfen/chunfenclose_Pushed",
    "chunfen/chunfenget1_Disabled", "chunfen/chunfenget1_Hover", "chunfen/chunfenget1_Normal",
    "chunfen/chunfenget1_Pushed", "chunfen1/chunfen1_bk", "chunfen1/chunfenbutton2_Disabled",
    "chunfen1/chunfenbutton2_Hover", "chunfen1/chunfenbutton2_Normal", "chunfen1/chunfenbutton2_Pushed",
    "chunfen1/chunfenget2_Disabled", "chunfen1/chunfenget2_Hover", "chunfen1/chunfenget2_Normal",
    "chunfen1/chunfenget2_Pushed", "WeixinHongbaoPaisong/WeixinHongbaoPaisong",
    // Chín ảnh thiếu trong bộ ảnh có tệp.
    "Anniversary2/Anniversary_Left_Pic", "Pretty01/MbuySmall_Pushed.png",
    "QiXi_StoryLetter_2/QiXi_StoryLetter_QZ_2", "QiXi_StoryLetter_2/QiXi_StoryLetter_QZ_4",
    "QiXi_StoryLetter_2/QiXi_StoryLetter_QZ_5", "XSYNew02/HXL_Disabled", "XSYNew02/HXL_Hover",
    "XSYNew02/HXL_Normal", "XSYNew02/HXL_Pushed"});

// Bảy hoạt ảnh layout gốc nhắc tới mà không tệp XML nào của Interface 2026 khai `<Animate Name=...>`:
// đếm lại 2026-10-13, wowanimate.xml giống từng byte bản đã gom.
constexpr auto kMissingAnimates = std::to_array<std::string_view>({"CoolDownEnd2", "ChatSignMini_MPMJ_1", "HZJYR_Luck",
    "HZJYR_Success", "ShuangDan_Huoguo_Counting_Light", "BaoJian1", "XinShouNew_SheJiaoDaRen_RewardFrame_Flash"});

bool is_known_gap(std::string_view note) {
    constexpr std::string_view kNoImage = "không có ảnh ";
    constexpr std::string_view kNoAnimate = "không có hoạt ảnh ";
    if (note.starts_with(kNoImage)) return std::ranges::contains(kMissingImages, note.substr(kNoImage.size()));
    if (note.starts_with(kNoAnimate)) return std::ranges::contains(kMissingAnimates, note.substr(kNoAnimate.size()));
    return false;
}

void notes_are_known_gaps(Context& context) {
    const gui::DiskSource files(interface_root());
    const Loaded loaded = load_all(files);
    if (!loaded.loader) return;
    for (const std::string_view note : loaded.loader->notes())
        context.expect(is_known_gap(note), note);
}

// Bảng hoạt ảnh đã gom đủ cho radar: mũi tên người chơi có đủ 30 khung như tệp gốc.
void arrow_animate_is_collected(Context& context) {
    const gui::DiskSource files(interface_root());
    const Loaded loaded = load_all(files);
    if (!loaded.loader) return;
    const gui::GuiAsset& asset = loaded.loader->asset();
    const auto is_arrow = [](const gui::GuiAnimate& item) { return item.name == "Minimap_arrow"; };
    const auto arrow = std::ranges::find_if(asset.animates, is_arrow);
    context.expect(arrow != asset.animates.end(), "có hoạt ảnh Minimap_arrow");
    if (arrow == asset.animates.end()) return;
    context.expect(arrow->frames.count == 30, "mũi tên 30 khung");
    const std::int32_t first = asset.animate_frames.at(arrow->frames.first);
    const gui::GuiImage& image = asset.images.at(static_cast<std::size_t>(first));
    context.expect(image.name == "Arrow_00015", "khung đầu là mũi tên chỉ xuống (+z)");
    context.expect(image.width == 32.0F && image.height == 32.0F, "ảnh 32 x 32");
}

// Bộ vẽ mở đúng tệp Imagefile gốc (dds, tga, png, jpg) dưới Interface, không nối ".png" (ui/painter.cpp).
void every_texture_has_file(Context& context) {
    const gui::DiskSource files(interface_root());
    const Loaded loaded = load_all(files);
    if (!loaded.loader) return;
    for (const std::string& texture : loaded.loader->asset().textures)
        context.expect(fs::exists(interface_root() / io::path_from_utf8(texture)), texture);
}

// Quad hợp lệ: texture trong miền, ô đích có diện tích dương.
bool is_valid_quad(const gui::Quad& quad, std::size_t textures) {
    const bool is_solid = quad.texture >= gui::kFont && quad.texture < 0;
    const bool is_image = quad.texture >= 0 && std::cmp_less(quad.texture, textures);
    const bool is_sized = quad.dest.w > 0.0F && quad.dest.h > 0.0F;
    return (is_solid || is_image) && is_sized;
}

// Cỡ màn hình để dàn trang thử.
struct ScreenSize {
    float width = 0.0F;
    float height = 0.0F;

    friend constexpr bool operator==(const ScreenSize&, const ScreenSize&) = default;
};

void lay_out_once(Context& context, const gui::GuiAsset& asset, const ScreenSize& size) {
    gui::Hub hub(asset);
    gui::Place place;
    place.width = size.width;
    place.height = size.height;
    hub.update(place);
    const std::size_t textures = asset.textures.size();
    const auto is_bad = [textures](
                            const gui::Quad& quad) { return !is_valid_quad(quad, textures); };
    context.expect(!hub.still().empty(), "có quad tĩnh");
    context.expect(std::ranges::none_of(hub.still(), is_bad), "quad tĩnh hợp lệ");
    context.expect(std::ranges::none_of(hub.live(), is_bad), "quad động hợp lệ");
}

void lays_out_at_three_sizes(Context& context) {
    const gui::DiskSource files(interface_root());
    const Loaded loaded = load_all(files);
    if (!loaded.loader) return;
    const std::array<ScreenSize, 3> sizes = {ScreenSize{.width = 1024.0F, .height = 768.0F},
        ScreenSize{.width = 1280.0F, .height = 720.0F},
        ScreenSize{.width = 1920.0F, .height = 1080.0F}};
    for (const ScreenSize& size : sizes)
        lay_out_once(context, loaded.loader->asset(), size);
}

// Bốn cỡ màn hình của golden, như SCREENS trong ui_rects.py.
constexpr std::array<ScreenSize, 4> kGoldenScreens = {
    ScreenSize{.width = 1024.0F, .height = 768.0F}, ScreenSize{.width = 1280.0F, .height = 720.0F},
    ScreenSize{.width = 1920.0F, .height = 1080.0F},
    ScreenSize{.width = 2560.0F, .height = 1600.0F}};
// Số cột của ui_rects.tsv và sai lệch cho phép, điểm ảnh (golden in bốn chữ số thập phân).
constexpr std::size_t kGoldenColumns = 9;
constexpr float kBoxTolerance = 0.001F;
// Số dòng lệch in ra tối đa; phần còn lại chỉ đếm.
constexpr std::size_t kShownMisses = 12;

// Một dòng golden: ô getUnclippedPixelRect của một cửa sổ ở một cỡ màn hình.
struct GoldenRow {
    ScreenSize screen;
    std::string layout;
    std::string window;
    gui::Box box;
    // Tên cửa sổ xuất hiện nhiều lần trong các layout (cột is_duplicate của ui_rects.tsv).
    bool is_duplicate = false;
};

std::vector<std::string_view> split(std::string_view text, char mark) {
    std::vector<std::string_view> parts;
    for (const auto part : text | std::views::split(mark))
        parts.emplace_back(part.begin(), part.end());
    return parts;
}

float number_of(std::string_view cell) {
    return gui::parse_float(cell).value_or(0.0F);
}

// Dòng dữ liệu của tsv; dòng chú thích "#", dòng tiêu đề và dòng thiếu cột thì không có.
std::optional<GoldenRow> golden_row(std::string_view line) {
    const std::vector<std::string_view> cells = split(line, '\t');
    if (cells.size() != kGoldenColumns || cells.front() == "screen_w") return std::nullopt;
    GoldenRow row;
    row.screen = ScreenSize{.width = number_of(cells.at(0)), .height = number_of(cells.at(1))};
    row.layout = std::string(cells.at(2));
    row.window = std::string(cells.at(3));
    row.box.x = number_of(cells.at(4));
    row.box.y = number_of(cells.at(5));
    row.box.w = number_of(cells.at(6));
    row.box.h = number_of(cells.at(7));
    row.is_duplicate = cells.at(8) == "1";
    return row;
}

void add_row(std::vector<GoldenRow>& rows, std::string_view line) {
    const std::optional<GoldenRow> row = golden_row(line);
    if (row) rows.push_back(*row);
}

std::vector<GoldenRow> golden_rows() {
    std::vector<GoldenRow> rows;
    const fs::path folder = std::string(kGoldenFolder);
    const gui::DiskSource files(folder);
    const std::optional<std::string> text = files.read("ui_rects.tsv");
    if (!text) return rows;
    for (const std::string_view line : split(*text, '\n'))
        add_row(rows, line);
    return rows;
}

bool is_near(float left, float right) {
    return std::abs(left - right) <= kBoxTolerance;
}

bool is_same_box(const gui::Box& got, const gui::Box& want) {
    const bool is_placed = is_near(got.x, want.x) && is_near(got.y, want.y);
    return is_placed && is_near(got.w, want.w) && is_near(got.h, want.h);
}

std::string box_text(const gui::Box& box) {
    const std::string place = std::to_string(box.x) + "," + std::to_string(box.y);
    return place + " " + std::to_string(box.w) + "x" + std::to_string(box.h);
}

// Số dòng đã so, số dòng không tra được theo tên, và mô tả từng dòng lệch.
struct Tally {
    std::size_t compared = 0;
    // Cửa sổ không có Name (Hub::box tra theo tên nên không chỉ tới được).
    std::size_t unnamed = 0;
    std::vector<std::string> misses;
};

void add_miss(Tally& tally, const GoldenRow& row, const std::optional<gui::Box>& got) {
    const std::string screen = std::to_string(static_cast<int>(row.screen.width));
    const std::string found = got ? box_text(*got) : std::string("không có");
    tally.misses.push_back(
        screen + "\t" + row.layout + "\t" + row.window + "\tgolden " + box_text(row.box) + "\tHub " + found);
}

void compare_row(const gui::Hub& hub, const GoldenRow& row, Tally& tally) {
    ++tally.compared;
    if (row.window.empty()) {
        ++tally.unnamed;
        return;
    }
    const std::optional<gui::Box> got = hub.box(row.window);
    if (!got || !is_same_box(*got, row.box)) add_miss(tally, row, got);
}

// Tên khai ở nhiều layout: Hub::box tra theo tên nên chỉ trả một cửa sổ trong số đó. Ô của nó phải
// trùng ô golden của một cửa sổ cùng tên; so từng dòng thì dòng của layout kia luôn lệch.
void compare_duplicates(const gui::Hub& hub, std::span<const GoldenRow* const> rows, Tally& tally) {
    for (const GoldenRow* row : rows) {
        const std::string_view name = row->window;
        const std::optional<gui::Box> got = hub.box(name);
        const auto is_same_name = [name](const GoldenRow* other) { return other->window == name; };
        const auto is_match = [&got](const GoldenRow* other) { return got && is_same_box(*got, other->box); };
        ++tally.compared;
        if (std::ranges::any_of(rows | std::views::filter(is_same_name), is_match)) continue;
        add_miss(tally, *row, got);
    }
}

// Một lượt so golden: asset, mọi dòng golden và cỡ màn hình đang so.
struct GoldenPass {
    const gui::GuiAsset* asset = nullptr;
    std::span<const GoldenRow> rows;
    ScreenSize size;
};

// Layout khai cửa sổ này Visible=False (thuộc tính khai sau cùng thắng, như Hub).
bool is_hidden_by_layout(const gui::GuiAsset& asset, const gui::GuiWindow& window) {
    const gui::GuiRange range = window.properties;
    const std::size_t total = asset.properties.size();
    if (range.first > total || range.count > total - range.first) return false;
    const auto own = std::span(asset.properties).subspan(range.first, range.count);
    const auto is_visible_prop = [](const gui::GuiProperty& prop) { return prop.name == "Visible"; };
    const auto backwards = own | std::views::reverse;
    const auto last = std::ranges::find_if(backwards, is_visible_prop);
    return last != backwards.end() && !gui::parse_bool((*last).value);
}

// Buộc hiện các cửa sổ mà layout khai Visible=False để Hub::box trả ô của cả chúng. Chỉ ép những cái
// ấy: layout quét cả danh sách Override cho từng cửa sổ, nên ép hết hàng chục nghìn cửa sổ thì
// Hub::update thành bậc hai và mất hơn một phút mỗi cỡ màn hình (đo 2026-10-14).
std::vector<gui::Override> show_hidden(const gui::GuiAsset& asset) {
    std::vector<gui::Override> shown;
    for (const gui::GuiWindow& window : asset.windows) {
        if (is_hidden_by_layout(asset, window))
            shown.push_back(gui::Override{.window = window.name, .name = "Visible", .value = "True"});
    }
    return shown;
}

void compare_screen(const GoldenPass& pass, Tally& tally) {
    const std::vector<gui::Override> shown = show_hidden(*pass.asset);
    gui::Hub hub(*pass.asset);
    gui::Place place;
    place.width = pass.size.width;
    place.height = pass.size.height;
    place.overrides = shown;
    hub.update(place);
    const ScreenSize size = pass.size;
    const auto is_on_screen = [size](const GoldenRow& row) { return row.screen == size; };
    std::vector<const GoldenRow*> duplicates;
    for (const GoldenRow& row : pass.rows | std::views::filter(is_on_screen)) {
        if (row.is_duplicate && !row.window.empty())
            duplicates.push_back(&row);
        else
            compare_row(hub, row, tally);
    }
    compare_duplicates(hub, duplicates, tally);
}

void window_boxes_match_golden(Context& context) {
    if (kGoldenFolder.empty()) return;
    const std::vector<GoldenRow> rows = golden_rows();
    const gui::DiskSource files(interface_root());
    // Golden chỉ có layout PC có bản gốc (TOOLS/content/ui_rects.py bỏ phone/), nên chỉ nạp các layout đó.
    const Loaded loaded = load_all(files, false);
    if (!loaded.loader) return;
    const gui::GuiAsset& asset = loaded.loader->asset();
    // Golden chỉ có cửa sổ khai trong layout; con mà look tự dựng (thanh cuộn...) không nằm trong đó.
    const auto is_declared = [](const gui::GuiWindow& window) { return window.child < 0; };
    const auto declared = static_cast<std::size_t>(std::ranges::count_if(asset.windows, is_declared));
    const std::size_t wanted = declared * kGoldenScreens.size();
    context.expect(rows.size() == wanted, "golden có đủ mọi cửa sổ ở bốn cỡ màn hình");
    Tally tally;
    for (const ScreenSize& size : kGoldenScreens)
        compare_screen(GoldenPass{.asset = &asset, .rows = rows, .size = size}, tally);
    context.expect(tally.compared == rows.size(), "mọi dòng golden thuộc bốn cỡ màn hình");
    const std::string total = std::to_string(tally.misses.size()) + " ô lệch golden (bỏ qua " +
                              std::to_string(tally.unnamed) + " dòng của cửa sổ không có tên)";
    if (!tally.misses.empty()) {
        // Ghi đủ mọi dòng lệch (cỡ màn hình, layout, cửa sổ, golden, Hub) để soát theo layout.
        std::ofstream dump(fs::current_path() / "gui_real_misses.tsv", std::ios::binary);
        dump << "screen\tlayout\twindow\tgolden\thub\n";
        for (const std::string& miss : tally.misses)
            dump << miss << '\n';
        context.expect(static_cast<bool>(dump), "ghi gui_real_misses.tsv");
    }
    context.expect(tally.misses.empty(), total);
    for (const std::string& miss : tally.misses | std::views::take(kShownMisses))
        context.expect(false, miss);
}

constexpr std::array kCases{
    Case{.name = "loads_every_layout", .body = &loads_every_layout},
    Case{.name = "notes_are_known_gaps", .body = &notes_are_known_gaps},
    Case{.name = "arrow_animate_is_collected", .body = &arrow_animate_is_collected},
    Case{.name = "every_texture_has_file", .body = &every_texture_has_file},
    Case{.name = "lays_out_at_three_sizes", .body = &lays_out_at_three_sizes},
    Case{.name = "window_boxes_match_golden", .body = &window_boxes_match_golden},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "gui_real_tests: mọi ca phải qua");
    return 0;
}
