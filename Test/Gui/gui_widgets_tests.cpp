// Danh sách, thanh cuộn, cửa sổ phức hợp và ô action của bộ dàn trang (gui/widgets.cpp) trên layout
// thật của bảng nhiệm vụ (CLIENT/data/Interface/QuestLog), đối chiếu các ví dụ số tính từ mã máy
// CEGUIBase.dll và CEGUIFalagard.dll 2026 (docs/GIAO-DIEN-2026.md, màn hình 1280x720, phông cỡ 14:
// cao phông 16, mục danh sách cao 19). Số đo chữ là một bộ đo giả cỡ cố định để ca test không phụ
// thuộc phông. Chỉ đăng ký khi đã gom dữ liệu giao diện.
#include "core/check.hpp"
#include "gui/asset.hpp"
#include "gui/content.hpp"
#include "gui/loader.hpp"
#include "gui/scroll.hpp"
#include "gui/sheet.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <format>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

namespace fs = std::filesystem;

using gui::Box;
using gui::Hub;
using gui::Override;
using gui::Place;
using gui::Pointer;
using gui::Quad;
using gui::TextRun;

#ifdef GAME_CLIENT_DATA
constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
constexpr std::string_view kClientData;
#endif

constexpr std::string_view kRoot = "QuestLog_Frame";
constexpr std::string_view kList = "QuestLog_Listbox";
constexpr std::string_view kDesc = "QuestLog_Desc";
constexpr std::string_view kListBar = "QuestLog_Listbox__auto_vscrollbar__";
constexpr std::string_view kListThumb = "QuestLog_Listbox__auto_vscrollbar____auto_thumb__";
constexpr std::string_view kListUp = "QuestLog_Listbox__auto_vscrollbar____auto_decbtn__";
constexpr std::string_view kListDown = "QuestLog_Listbox__auto_vscrollbar____auto_incbtn__";
constexpr std::string_view kDescBody = "QuestLog_Desc__auto_parent__";
constexpr std::string_view kDescBar = "QuestLog_Desc__auto_vscrollbar__";

// Bộ đo giả của phông bitmap cỡ 14: cao phông và bước dòng 16, mỗi byte của chuỗi rộng 7, khối n
// dòng cao n x 16 + 3 x (n - 1) như Font::getFormattedSize.
class FixedMeter final : public gui::TextMeter {
public:
    [[nodiscard]] float font_height() const override { return kHeight; }
    [[nodiscard]] float line_spacing() const override { return kHeight; }
    [[nodiscard]] gui::TextSize line_size(std::string_view text) const override {
        return gui::TextSize{.width = kAdvance * static_cast<float>(text.size()), .height = kHeight};
    }
    [[nodiscard]] gui::TextSize formatted_size(std::string_view text, float width, std::uint8_t horz) const override {
        const float whole = kAdvance * static_cast<float>(text.size());
        const bool is_wrapped = horz >= 4 && width > 0.0F && whole > width;
        const float lines = is_wrapped ? std::ceil(whole / width) : 1.0F;
        return gui::TextSize{.width = is_wrapped ? width : whole, .height = (lines * kHeight) + (3.0F * (lines - 1.0F))};
    }

private:
    static constexpr float kHeight = 16.0F;
    static constexpr float kAdvance = 7.0F;
};

bool near_value(float value, float expect) {
    return std::fabs(value - expect) < 0.01F;
}

bool same_box(const Box& box, const Box& want) {
    const bool is_same_place = near_value(box.x, want.x) && near_value(box.y, want.y);
    return is_same_place && near_value(box.w, want.w) && near_value(box.h, want.h);
}

// Ô cắt của một dòng chữ có đúng là want không (dòng không có ô cắt thì không).
bool is_box(const std::optional<Box>& got, const Box& want) {
    return got.has_value() && same_box(*got, want);
}

std::string box_text(const Box& box) {
    return std::format("({}, {}, {}, {})", box.x, box.y, box.w, box.h);
}

// Bảng nhiệm vụ đã nạp và một Hub trên nó; hai con trỏ có giá trị sau khi open_stage trả true.
struct Stage {
    gui::DiskSource files{fs::path(std::string(kClientData)) / "Interface"};
    std::unique_ptr<gui::GuiLoader> loader;
    std::unique_ptr<Hub> hub;
    FixedMeter meter;
    std::array<std::string_view, 1> roots = {kRoot};
};

// Nạp layout của bảng nhiệm vụ; false (kèm một dòng báo) khi dữ liệu thiếu.
bool open_stage(Context& context, Stage& stage) {
    gui::GuiSources sources;
    sources.files = &stage.files;
    auto opened = gui::GuiLoader::open(sources);
    context.expect(opened.has_value(), "mở được giao diện gốc");
    if (!opened) return false;
    stage.loader = std::make_unique<gui::GuiLoader>(std::move(*opened));
    const auto added = stage.loader->add_layout("QuestLog/QuestLog.layout.xml");
    context.expect(added.has_value(), "nạp được layout bảng nhiệm vụ");
    if (!added) return false;
    stage.hub = std::make_unique<Hub>(stage.loader->asset());
    return true;
}

// Dàn bảng nhiệm vụ ở 1280x720 với các thuộc tính đặt lúc chạy overrides.
void update(Stage& stage, std::span<const Override> overrides) {
    Place place;
    place.width = 1280.0F;
    place.height = 720.0F;
    place.roots = stage.roots;
    place.overrides = overrides;
    place.meter = &stage.meter;
    stage.hub->update(place);
}

// Nội dung "Items" của count mục, mục thứ i mang chữ "muc<i>" và màu colour.
std::string items_of(std::size_t count, std::string_view colour) {
    std::string blob;
    for (std::size_t index = 0; index < count; ++index) {
        if (index > 0) blob += gui::kRecordMark;
        blob += std::format("{}{}muc{}", colour, gui::kFieldMark, index);
    }
    return blob;
}

const TextRun* run_of(std::span<const TextRun> runs, std::string_view text) {
    const auto found = std::ranges::find(runs, text, &TextRun::text);
    return found == runs.end() ? nullptr : &*found;
}

bool has_window(const gui::GuiAsset& asset, std::string_view name) {
    return std::ranges::contains(asset.windows, name, &gui::GuiWindow::name);
}

void look_children_are_built(Context& context) {
    Stage stage;
    if (!open_stage(context, stage)) return;
    const gui::GuiAsset& asset = stage.loader->asset();
    const std::array<std::string_view, 6> wanted = {kListBar, kListThumb, kListUp, kListDown, kDescBody, kDescBar};
    for (const std::string_view name : wanted) {
        context.expect(has_window(asset, name), std::format("có cửa sổ con {}", name));
    }
    const auto is_layout_window = [](const gui::GuiWindow& window) { return window.child < 0; };
    const auto first_child = std::ranges::find_if_not(asset.windows, is_layout_window);
    const auto stray = std::ranges::find_if(first_child, asset.windows.end(), is_layout_window);
    context.expect(stray == asset.windows.end(), "con tự dựng đứng sau mọi cửa sổ của layout");
}

// Ba mục, chưa cuộn, chưa có thanh cuộn: ô mục (228, 170.66 + 19 x i, 231, 19), chữ dời xuống 2.
void list_rows_sit_in_item_area(Context& context) {
    Stage stage;
    if (!open_stage(context, stage)) return;
    const std::string items = items_of(3, "FF00FF00");
    const std::array<Override, 1> overrides = {{{.window = kList, .name = gui::kItemsProperty, .value = items}}};
    update(stage, overrides);
    const std::span<const TextRun> runs = stage.hub->texts();
    for (std::size_t index = 0; index < 3; ++index) {
        const TextRun* run = run_of(runs, std::format("muc{}", index));
        context.expect(run != nullptr, std::format("mục {} có dòng chữ", index));
        if (run == nullptr) continue;
        const float top = 170.66F + (19.0F * static_cast<float>(index));
        const Box box{.x = 228.0F, .y = top + 2.0F, .w = 231.0F, .h = 17.0F};
        context.expect(same_box(run->box, box), std::format("ô chữ mục {}: {}", index, box_text(run->box)));
        const Box clip{.x = 228.0F, .y = top, .w = 231.0F, .h = 19.0F};
        context.expect(is_box(run->clip, clip), "cắt theo ô mục trong vùng mục");
        context.expect(run->rule == gui::TextRule::kRaw && run->horz == 0, "drawText thẳng, canh trái");
        context.expect(run->colour == 0xFF00FF00U, "màu của mục");
    }
    context.expect(!stage.hub->box(kListBar), "ba mục thì thanh cuộn ẩn");
    const std::optional<Box> area = stage.hub->content(kList);
    const Box wanted{.x = 228.0F, .y = 170.66F, .w = 231.0F, .h = 376.0F};
    context.expect(area && same_box(*area, wanted), "vùng mục khi chưa có thanh cuộn");
}

// Hai mươi mục cao 19 là 380 > 376: thanh cuộn hiện, vùng mục hẹp còn 215, con chạy theo vị trí.
void scrollbar_shows_when_list_overflows(Context& context) {
    Stage stage;
    if (!open_stage(context, stage)) return;
    const std::string items = items_of(20, "");
    const std::array<Override, 1> still = {{{.window = kList, .name = gui::kItemsProperty, .value = items}}};
    update(stage, still);
    const std::optional<Box> bar = stage.hub->box(kListBar);
    context.expect(bar && same_box(*bar, Box{.x = 446.0F, .y = 168.66F, .w = 16.0F, .h = 380.0F}), "ô thanh cuộn");
    const std::optional<Box> upper = stage.hub->box(kListUp);
    context.expect(upper && same_box(*upper, Box{.x = 446.0F, .y = 168.66F, .w = 15.0F, .h = 15.0F}), "nút lên");
    const std::optional<Box> lower = stage.hub->box(kListDown);
    context.expect(lower && same_box(*lower, Box{.x = 446.0F, .y = 533.66F, .w = 15.0F, .h = 15.0F}), "nút xuống");
    const std::optional<Box> thumb = stage.hub->box(kListThumb);
    const Box at_top{.x = 446.0F, .y = 183.66F, .w = 15.0F, .h = 18.0F};
    context.expect(thumb && same_box(*thumb, at_top), "con chạy ở đầu rãnh");
    const TextRun* first = run_of(stage.hub->texts(), "muc0");
    context.expect(first != nullptr && near_value(first->box.w, 215.0F), "ô mục hẹp lại theo thanh cuộn");
    const std::optional<gui::ThumbTrack> track = stage.hub->track(kListBar);
    context.expect(track && near_value(track->top, 183.66F) && near_value(track->slide, 332.0F), "rãnh con chạy");
    const std::array<Override, 2> scrolled = {{
        {.window = kList, .name = gui::kItemsProperty, .value = items},
        {.window = kList, .name = gui::kScrollProperty, .value = "9999"},
    }};
    update(stage, scrolled);
    const std::optional<Box> moved = stage.hub->box(kListThumb);
    const Box at_end{.x = 446.0F, .y = 515.66F, .w = 15.0F, .h = 18.0F};
    context.expect(moved && same_box(*moved, at_end), "vị trí quá cuối kẹp về cuối: con chạy ở cuối rãnh");
    const TextRun* top = run_of(stage.hub->texts(), "muc0");
    context.expect(top != nullptr && near_value(top->box.y, 170.66F - 4.0F + 2.0F), "mục 0 dời lên 4");
    const Box top_clip = top == nullptr ? Box{} : top->clip.value_or(Box{});
    context.expect(near_value(top_clip.y, 170.66F), "và bị vùng mục cắt mép trên");
}

const Quad* quad_at(std::span<const Quad> quads, const Box& dest) {
    const auto is_there = [&dest](const Quad& quad) { return same_box(quad.dest, dest); };
    const auto found = std::ranges::find_if(quads, is_there);
    return found == quads.end() ? nullptr : &*found;
}

void selected_row_gets_brush(Context& context) {
    Stage stage;
    if (!open_stage(context, stage)) return;
    const std::string items = items_of(3, "");
    const std::array<Override, 2> overrides = {{
        {.window = kList, .name = gui::kItemsProperty, .value = items},
        {.window = kList, .name = gui::kSelectedProperty, .value = "1"},
    }};
    update(stage, overrides);
    const Box row{.x = 228.0F, .y = 189.66F, .w = 231.0F, .h = 19.0F};
    const Quad* brush = quad_at(stage.hub->still(), row);
    context.expect(brush != nullptr, "nền chọn phủ đúng ô mục 1");
    context.expect(brush != nullptr && near_value(brush->source.w, 60.0F), "là ảnh CommonEditBoxBK 60x15 kéo giãn");
    const std::array<std::string_view, 4> bad = {"", "abc", "-1", "3"};
    for (const std::string_view value : bad) {
        const std::array<Override, 2> wrong = {{
            {.window = kList, .name = gui::kItemsProperty, .value = items},
            {.window = kList, .name = gui::kSelectedProperty, .value = value},
        }};
        update(stage, wrong);
        const bool has_brush = quad_at(stage.hub->still(), row) != nullptr;
        context.expect(!has_brush, std::format("chỉ số chọn hỏng [{}] thì không có nền chọn", value));
    }
}

void pointer_finds_list_row(Context& context) {
    Stage stage;
    if (!open_stage(context, stage)) return;
    const std::string items = items_of(3, "");
    const std::array<Override, 1> overrides = {{{.window = kList, .name = gui::kItemsProperty, .value = items}}};
    update(stage, overrides);
    const auto row_under = [&stage](Pointer pointer) { return stage.hub->list_item(kList, pointer); };
    context.expect(row_under({.x = 300.0F, .y = 171.0F}) == std::size_t{0}, "ngay dưới mép trên vùng là mục 0");
    context.expect(row_under({.x = 300.0F, .y = 192.66F}) == std::size_t{1}, "22 điểm ảnh dưới mép vùng là mục 1");
    context.expect(!row_under({.x = 300.0F, .y = 228.16F}), "dưới mục cuối là chỗ trống");
    context.expect(!row_under({.x = 225.0F, .y = 180.0F}), "lề trái của danh sách không thuộc vùng mục");
    context.expect(!row_under({.x = 300.0F, .y = 100.0F}), "ngoài danh sách");
    context.expect(!stage.hub->list_item(kDesc, Pointer{.x = 500.0F, .y = 220.0F, .is_down = false}),
        "cửa sổ không phải danh sách");
    context.expect(!stage.hub->list_item("KhongCo", Pointer{}), "cửa sổ không có");
}

std::string element(std::string_view kind, std::string_view body) {
    return std::format("{}{}{}", kind, gui::kFieldMark, body);
}

std::string joined(std::span<const std::string> records) {
    std::string blob;
    for (const std::string& record : records) {
        if (!blob.empty()) blob += gui::kRecordMark;
        blob += record;
    }
    return blob;
}

// Vùng nội dung của QuestLog_Desc là (478, 197.66, 238, 337). Chữ một dòng, chữ ba dòng (100 ký tự
// rộng 700 trong 238), ô tiền, rồi hai nút action cùng hàng: như ví dụ của đặc tả với cỡ 14.
void complex_parts_stack_downwards(Context& context) {
    Stage stage;
    if (!open_stage(context, stage)) return;
    const std::string long_text(100, 'a');
    const std::array<std::string, 5> records = {element(gui::kTextElement, "mot dong"),
        element(gui::kTextElement, long_text), element(gui::kMoneyElement, "12345"),
        element(gui::kActionElement, ""), element(gui::kActionElement, "")};
    const std::string blob = joined(records);
    const std::array<Override, 1> overrides = {{{.window = kDesc, .name = gui::kElementsProperty, .value = blob}}};
    update(stage, overrides);
    const std::optional<Box> area = stage.hub->content(kDesc);
    const Box wanted{.x = 478.0F, .y = 197.66F, .w = 238.0F, .h = 337.0F};
    context.expect(area && same_box(*area, wanted), "vùng nội dung của cửa sổ phức hợp");
    const TextRun* one = run_of(stage.hub->texts(), "mot dong");
    const Box one_box{.x = 478.0F, .y = 197.66F, .w = 238.0F, .h = 16.0F};
    context.expect(one != nullptr && same_box(one->box, one_box), "chữ một dòng ở đầu vùng");
    context.expect(one != nullptr && one->horz == 4 && one->rule == gui::TextRule::kRaw, "bẻ dòng canh trái");
    context.expect(one != nullptr && is_box(one->clip, wanted), "chữ cắt theo vùng nội dung");
    const TextRun* three = run_of(stage.hub->texts(), long_text);
    const Box three_box{.x = 478.0F, .y = 197.66F + 19.0F, .w = 238.0F, .h = 54.0F};
    context.expect(three != nullptr && same_box(three->box, three_box), "chữ ba dòng cách dòng trước 19");
    // Sau chữ: y = 19 + 57 = 76; ô tiền cao 22,4 nên y = 98,4; nút đầu cách thêm 10: y = 108,4,
    // đặt ở trunc(108,4 + 0,5) = 108.
    const Quad* first = quad_at(stage.hub->still(), Box{.x = 478.0F, .y = 305.66F, .w = 35.0F, .h = 35.0F});
    const Quad* second = quad_at(stage.hub->still(), Box{.x = 523.0F, .y = 305.66F, .w = 35.0F, .h = 35.0F});
    context.expect(first != nullptr, "nút action đầu: nền ActionBK 35x35 dưới ô tiền");
    context.expect(second != nullptr, "nút action thứ hai cùng hàng, cách 45");
    context.expect(!stage.hub->box(kDescBar), "tổng cao 143,4 chưa quá 337: thanh cuộn ẩn");
}

void complex_scrolls_when_content_overflows(Context& context) {
    Stage stage;
    if (!open_stage(context, stage)) return;
    std::vector<std::string> records;
    records.reserve(20);
    for (std::size_t index = 0; index < 20; ++index) {
        records.push_back(element(gui::kTextElement, std::format("dong {}", index)));
    }
    const std::string blob = joined(records);
    const std::array<Override, 2> overrides = {{
        {.window = kDesc, .name = gui::kElementsProperty, .value = blob},
        {.window = kDesc, .name = gui::kScrollProperty, .value = "19"},
    }};
    update(stage, overrides);
    const std::optional<Box> bar = stage.hub->box(kDescBar);
    context.expect(bar && same_box(*bar, Box{.x = 717.0F, .y = 192.66F, .w = 16.0F, .h = 347.0F}), "ô thanh cuộn");
    const TextRun* second = run_of(stage.hub->texts(), "dong 1");
    context.expect(second != nullptr && near_value(second->box.y, 197.66F), "cuộn 19 thì dòng 1 lên đầu vùng");
    context.expect(second != nullptr && near_value(second->box.h, 16.0F + 19.0F), "chỉ mép trên dời theo cuộn");
    context.expect(run_of(stage.hub->texts(), "dong 0") == nullptr, "dòng đã cuộn khỏi vùng thì không ra");
    context.expect(run_of(stage.hub->texts(), "dong 19") == nullptr, "dòng nằm dưới vùng cũng không ra");
}

// Không có số đo chữ, nội dung hỏng: không có mục nào và không hỏng gì.
void hostile_content_draws_nothing(Context& context) {
    Stage stage;
    if (!open_stage(context, stage)) return;
    const std::string marks(5, gui::kRecordMark);
    const std::string odd = std::format("la{}gi do{}action", gui::kFieldMark, gui::kRecordMark);
    const std::array<Override, 4> overrides = {{
        {.window = kList, .name = gui::kItemsProperty, .value = marks},
        {.window = kList, .name = gui::kScrollProperty, .value = "nan"},
        {.window = kDesc, .name = gui::kElementsProperty, .value = odd},
        {.window = kDesc, .name = gui::kScrollProperty, .value = "-inf"},
    }};
    update(stage, overrides);
    context.expect(run_of(stage.hub->texts(), "gi do") == nullptr, "loại phần tử lạ không ra chữ");
    Place bare;
    bare.width = 1280.0F;
    bare.height = 720.0F;
    bare.roots = stage.roots;
    bare.overrides = overrides;
    stage.hub->update(bare);
    const auto is_list_run = [](const TextRun& run) { return run.rule == gui::TextRule::kRaw; };
    context.expect(std::ranges::none_of(stage.hub->texts(), is_list_run), "không có số đo chữ thì không có mục");
    context.expect(!stage.hub->list_item(kList, Pointer{.x = 300.0F, .y = 180.0F, .is_down = false}),
        "và không dò ra mục nào");
}

constexpr std::array<Case, 7> kCases = {{
    {.name = "look_children_are_built", .body = look_children_are_built},
    {.name = "list_rows_sit_in_item_area", .body = list_rows_sit_in_item_area},
    {.name = "scrollbar_shows_when_list_overflows", .body = scrollbar_shows_when_list_overflows},
    {.name = "selected_row_gets_brush", .body = selected_row_gets_brush},
    {.name = "pointer_finds_list_row", .body = pointer_finds_list_row},
    {.name = "complex_parts_stack_downwards", .body = complex_parts_stack_downwards},
    {.name = "complex_scrolls_when_content_overflows", .body = complex_scrolls_when_content_overflows},
}};

constexpr std::array<Case, 1> kHostileCases = {{
    {.name = "hostile_content_draws_nothing", .body = hostile_content_draws_nothing},
}};

} // namespace
} // namespace game::test

int main() {
    if (game::test::kClientData.empty()) return 0;
    const int failed = game::test::run_all(game::test::kCases) + game::test::run_all(game::test::kHostileCases);
    game::core::check(failed == 0, "gui_widgets_tests: mọi ca phải qua");
    return 0;
}
