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
#include "test.hpp"

#include <algorithm>
#include <array>
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

Loaded load_all(const gui::FileSource& files) {
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
        add_one(*loaded.loader, loaded.failures, layout);
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

// Ghi chú chỉ được là chỗ hỏng có sẵn trong dữ liệu gốc: vài tên ảnh không tồn tại trong imageset,
// và hoạt ảnh CoolDownEnd2 mà ô kỹ năng của các thanh phụ nhắc tới nhưng wowanimate.xml của client
// 2026 không còn.
void notes_are_known_gaps(Context& context) {
    const gui::DiskSource files(interface_root());
    const Loaded loaded = load_all(files);
    if (!loaded.loader) return;
    const auto is_known = [](std::string_view note) {
        return note.starts_with("không có ảnh ") || note == "không có hoạt ảnh CoolDownEnd2";
    };
    for (const std::string_view note : loaded.loader->notes())
        context.expect(is_known(note), note);
    context.expect(loaded.loader->notes().size() < 20, "ít tham chiếu hỏng");
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

void every_texture_has_png(Context& context) {
    const gui::DiskSource files(interface_root());
    const Loaded loaded = load_all(files);
    if (!loaded.loader) return;
    for (const std::string& texture : loaded.loader->asset().textures)
        context.expect(fs::exists(interface_root() / (texture + ".png")), texture);
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
    std::string window;
    gui::Box box;
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
    row.window = std::string(cells.at(3));
    row.box.x = number_of(cells.at(4));
    row.box.y = number_of(cells.at(5));
    row.box.w = number_of(cells.at(6));
    row.box.h = number_of(cells.at(7));
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

// Số dòng đã so và mô tả từng dòng lệch.
struct Tally {
    std::size_t compared = 0;
    std::vector<std::string> misses;
};

void compare_row(const gui::Hub& hub, const GoldenRow& row, Tally& tally) {
    const std::optional<gui::Box> got = hub.box(row.window);
    ++tally.compared;
    if (got && is_same_box(*got, row.box)) return;
    const std::string screen = std::to_string(static_cast<int>(row.screen.width));
    const std::string found = got ? box_text(*got) : std::string("không có");
    tally.misses.push_back(
        screen + " " + row.window + ": golden " + box_text(row.box) + ", Hub " + found);
}

// Buộc mọi cửa sổ hiện để Hub::box trả ô của cả cửa sổ mà layout khai Visible=False.
std::vector<gui::Override> show_all(const gui::GuiAsset& asset) {
    std::vector<gui::Override> shown;
    shown.reserve(asset.windows.size());
    for (const gui::GuiWindow& window : asset.windows)
        shown.push_back(gui::Override{.window = window.name, .name = "Visible", .value = "True"});
    return shown;
}

};

void compare_screen(const GoldenPass& pass, Tally& tally) {
    const std::vector<gui::Override> shown = show_all(*pass.asset);
    gui::Hub hub(*pass.asset);
    gui::Place place;
    place.width = pass.size.width;
    place.height = pass.size.height;
    place.overrides = shown;
    hub.update(place);
    const ScreenSize size = pass.size;
    const auto is_on_screen = [size](const GoldenRow& row) { return row.screen == size; };
    for (const GoldenRow& row : pass.rows | std::views::filter(is_on_screen))
        compare_row(hub, row, tally);
}

void window_boxes_match_golden(Context& context) {
    if (kGoldenFolder.empty()) return;
    const std::vector<GoldenRow> rows = golden_rows();
    const gui::DiskSource files(interface_root());
    const Loaded loaded = load_all(files);
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
    const std::string total = std::to_string(tally.misses.size()) + " ô lệch golden";
    context.expect(tally.misses.empty(), total);
    for (const std::string& miss : tally.misses | std::views::take(kShownMisses))
        context.expect(false, miss);
}

constexpr std::array kCases{
    Case{.name = "loads_every_layout", .body = &loads_every_layout},
    Case{.name = "notes_are_known_gaps", .body = &notes_are_known_gaps},
    Case{.name = "arrow_animate_is_collected", .body = &arrow_animate_is_collected},
    Case{.name = "every_texture_has_png", .body = &every_texture_has_png},
    Case{.name = "lays_out_at_three_sizes", .body = &lays_out_at_three_sizes},
    Case{.name = "window_boxes_match_golden", .body = &window_boxes_match_golden},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "gui_real_tests: mọi ca phải qua");
    return 0;
}

int main() {
    game::core::check(
        game::test::run_all(game::test::kCases) == 0, "gui_real_tests: mọi ca phải qua");
    return 0;
}
⟪thiếu dòng này⟫
