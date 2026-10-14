// Bộ viết chữ của giao diện (ui/text.hpp) so với mã máy của client 2026: dãy mã mà bộ phân tích thẻ
// # sinh (UI_CEGUI.dll 0x18004b170), số đo của Font (CEGUIBase.dll) và toạ độ đỉnh của chữ vẽ bằng
// phông VTNAM14, GBK12 thật của kho dữ liệu. Ví dụ số lấy từ docs/GIAO-DIEN-2026.md: mục 5 E.1
// (QuestLog_Amount), E.2 (ActionSkill_EffectNotice) và mục 9.1 đến 9.3; chỗ bẻ dòng đối chiếu với
// bộ mô phỏng viết riêng từ mã máy, TOOLS/port/text_wrap_sim.py.
#include "ui/text.hpp"

#include "core/check.hpp"
#include "core/error.hpp"
#include "gui/sheet.hpp"
#include "gui/strings.hpp"
#include "render/ui.hpp"
#include "table/tsv.hpp"
#include "test.hpp"
#include "ui/pace.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <initializer_list>
#include <iterator>
#include <limits>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

// Thư mục dữ liệu client mà bản dựng biết; rỗng thì các ca cần phông tự bỏ qua.
#ifdef GAME_CLIENT_DATA
constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
constexpr std::string_view kClientData;
#endif

constexpr std::uint32_t kBase = 0xFF112233U;
// Ô cắt rộng hơn mọi ô chữ của test: chữ bẻ dòng dời lên hai điểm ảnh nên vượt mép trên ô của nó.
constexpr gui::Box kOpen{.x = -1000.0F, .y = -1000.0F, .w = 100000.0F, .h = 100000.0F};
constexpr std::string_view kNotice =
    "Hiệu quả cấp tu luyện bảo thạch hiện tại: tăng tối đa hiệu quả khống chế của tâm pháp thứ tám 3 giây, "
    "giảm tối đa 2 giây.";

using Vertices = std::vector<render::UiVertex>;

bool near_value(float value, float expect) {
    return std::fabs(value - expect) < 0.01F;
}

// VTNAM14 của kho dữ liệu, cỡ 14 (bước dòng 19). Chưa có kho thì ca tự bỏ qua; có kho mà không mở
// được phông là lỗi của ca.
std::optional<ui::BitmapFont> open_font(Context& context) {
    if (kClientData.empty()) return std::nullopt;
    const std::filesystem::path file = std::filesystem::path(kClientData) / "Interface" / "Schema" / "VTNAM14.bin";
    core::Result<ui::BitmapFont> font = ui::BitmapFont::open(file);
    context.expect(font.has_value(), "mở được VTNAM14");
    if (!font) return std::nullopt;
    return std::move(*font);
}

gui::TextRun run_of(std::string_view text, gui::Box box, gui::TextRule rule) {
    gui::TextRun run;
    run.text = text;
    run.box = box;
    run.rule = rule;
    run.colour = kBase;
    return run;
}

// Như run_of nhưng ô cắt rộng vô hạn, để ca chỉ đo vị trí chữ mà không bị cắt ở mép ô.
gui::TextRun open_run(std::string_view text, gui::Box box, gui::TextRule rule) {
    gui::TextRun run = run_of(text, box, rule);
    run.clip = kOpen;
    return run;
}

Vertices drawn(ui::TextWriter& writer, const gui::TextRun& run) {
    Vertices out;
    static_cast<void>(writer.write(run, out));
    return out;
}

// Bốn đỉnh một quad, đỉnh đầu là góc trái trên.
bool quad_at(const Vertices& out, std::size_t index, float x, float y) {
    const std::size_t first = index * 4;
    if (first + 3 >= out.size()) return false;
    return near_value(out[first].x, x) && near_value(out[first].y, y);
}

// Các hàng của chữ: cạnh trên của quad theo thứ tự xuất hiện, mỗi hàng một lần.
std::vector<float> rows_of(const Vertices& out) {
    std::vector<float> rows;
    for (std::size_t first = 0; first + 3 < out.size(); first += 4) {
        const float top = out[first].y;
        const auto same = [top](float row) { return near_value(row, top); };
        if (std::ranges::none_of(rows, same)) rows.push_back(top);
    }
    std::ranges::sort(rows);
    return rows;
}

bool rows_are(const Vertices& out, std::initializer_list<float> want) {
    const std::vector<float> rows = rows_of(out);
    if (rows.size() != want.size()) return false;
    return std::ranges::equal(rows, want, [](float row, float expect) { return near_value(row, expect); });
}

// Mép trái của quad trái nhất ở hàng có cạnh trên bằng row; hàng không có thì NaN (so sánh luôn sai).
float left_of_row(const Vertices& out, float row) {
    float left = std::numeric_limits<float>::quiet_NaN();
    for (std::size_t first = 0; first + 3 < out.size(); first += 4) {
        if (!near_value(out[first].y, row)) continue;
        if (std::isnan(left) || out[first].x < left) left = out[first].x;
    }
    return left;
}

// Mục 5 E.1: QuestLog_Amount, TextArea (7, 3, 53, 21), HorzCentred, VertCentred, chữ "12/20".
void writer_amount(Context& context) {
    const std::optional<ui::BitmapFont> font = open_font(context);
    if (!font) return;
    ui::TextWriter writer(*font, nullptr);
    gui::TextRun run = run_of(kNotice, {.x = 7.0F, .y = 3.0F, .w = 348.0F, .h = 47.0F}, gui::TextRule::kSimpleText);
    run.horz = 4;
    run.vert = 1;
    const Vertices out = drawn(writer, run);
    context.expect(rows_are(out, {8.0F, 27.0F}), "E.2: y0 = 7, y1 = 26, bitmap thấp hơn 1");
    context.expect(near_value(left_of_row(out, 8.0F), 7.0F), "dòng 0 bắt đầu ở mép trái");
    context.expect(near_value(left_of_row(out, 27.0F), 11.0F), "dòng 1 mở đầu bằng dấu cách rộng 4");
}

// Luật bẻ dòng của trang mã khác 936 (drawWrappedText CEGUIBase.dll 0x18004cf40), ô rộng 60.
void writer_wraps(Context& context) {
    const std::optional<ui::BitmapFont> font = open_font(context);
    if (!font) return;
    ui::TextWriter writer(*font, nullptr);
    const gui::Box box{.x = 10.0F, .y = 20.0F, .w = 60.0F, .h = 200.0F};
    gui::TextRun run = open_run("một hai ba bốn năm sáu", box, gui::TextRule::kRaw);
    run.horz = 4;
    const Vertices words = drawn(writer, run);
    context.expect(rows_are(words, {19.0F, 38.0F, 57.0F}), "ba dòng, bước 19, dời đúp 2 rồi bitmap thấp hơn 1");
    context.expect(near_value(left_of_row(words, 38.0F), 14.0F), "dấu cách mở đầu dòng sau, không bị nuốt");
    run.text = "abcdefghijklmnopqrstuvwxyz";
    const Vertices word = drawn(writer, run);
    context.expect(rows_are(word, {19.0F, 38.0F, 57.0F}), "từ dài hơn 12 ký tự bị bẻ giữa từ");
    context.expect(word.size() == 26 * 4, "không ký tự nào mất");
    context.expect(quad_at(word, 10, 10.0F, 38.0F), "klmnopqrst rộng đúng 60 vẫn nằm một dòng");
    context.expect(quad_at(word, 20, 10.0F, 57.0F), "dòng ba từ chữ u");
    run.text = "xin chào, bạn! ổn?";
    run.box.w = 30.0F;
    context.expect(rows_are(drawn(writer, run), {19.0F, 38.0F, 57.0F, 76.0F}), "dấu phẩy, chấm than mở đầu dòng sau");
}

// Hai chỗ bản gốc xử lý lạ: lùi tới dấu cách đầu dòng thì ra một dòng rỗng cao 16; dòng chỉ còn
// một ký tự thì ký tự ngắt sau nó bị bỏ.
void writer_wrap_quirks(Context& context) {
    const std::optional<ui::BitmapFont> font = open_font(context);
    if (!font) return;
    ui::TextWriter writer(*font, nullptr);
    const gui::Box box{.x = 10.0F, .y = 20.0F, .w = 60.0F, .h = 200.0F};
    gui::TextRun run = open_run("ab cdefghijklm", box, gui::TextRule::kRaw);
    run.horz = 4;
    context.expect(rows_are(drawn(writer, run), {19.0F, 54.0F, 73.0F}), "ab, dòng rỗng 16, cdefghijkl, m");
    run.text = "a bcdefghijkl mn";
    const Vertices dropped = drawn(writer, run);
    context.expect(rows_are(dropped, {19.0F, 38.0F, 57.0F}), "ba dòng");
    context.expect(near_value(left_of_row(dropped, 38.0F), 10.0F), "dấu cách sau chữ a bị bỏ");
    context.expect(near_value(left_of_row(dropped, 57.0F), 14.0F), "dòng ba mở đầu bằng dấu cách");
    run.text = "abc";
    run.box.w = 5.0F;
    context.expect(drawn(writer, run).empty(), "ô hẹp hơn mọi chữ: chữ nào cũng bị bỏ");
    run.box.w = 0.0F;
    context.expect(drawn(writer, run).empty(), "ô rộng 0");
}

// Canh của từng dòng đã bẻ: phải không làm tròn, giữa cộng 1.
void writer_wrap_aligns(Context& context) {
    const std::optional<ui::BitmapFont> font = open_font(context);
    if (!font) return;
    ui::TextWriter writer(*font, nullptr);
    const gui::Box box{.x = 10.0F, .y = 20.0F, .w = 60.0F, .h = 200.0F};
    gui::TextRun run = open_run("abcdefghijklmnopqrstuvwxyz", box, gui::TextRule::kRaw);
    run.horz = 5;
    const Vertices right = drawn(writer, run);
    context.expect(quad_at(right, 0, 14.0F, 19.0F), "dòng rộng 56 canh phải: 70 - 56");
    context.expect(quad_at(right, 20, 30.0F, 57.0F), "dòng rộng 40 canh phải: 70 - 40");
    run.horz = 6;
    const Vertices centred = drawn(writer, run);
    context.expect(quad_at(centred, 0, 13.0F, 19.0F), "giữa: trunc(10 + 2 + 0,5) + 1");
    context.expect(quad_at(centred, 20, 21.0F, 57.0F), "giữa: trunc(10 + 10 + 0,5) + 1");
}

// Mục 9.3 và phép cắt về 0: ô chữ ở y = 0 không dời lên được, ô ở y = 19 dời đúp.
void writer_wrap_tops(Context& context) {
    const std::optional<ui::BitmapFont> font = open_font(context);
    if (!font) return;
    ui::TextWriter writer(*font, nullptr);
    gui::TextRun run = open_run("ab", {.x = 0.0F, .y = 0.0F, .w = 238.0F, .h = 16.0F}, gui::TextRule::kRaw);
    run.horz = 4;
    context.expect(quad_at(drawn(writer, run), 0, 0.0F, 1.0F), "9.3: trunc(-0,5) là 0 hai lần, bitmap từ hàng 1");
    run.box = {.x = 0.0F, .y = 19.0F, .w = 60.0F, .h = 54.0F};
    run.text = "một hai ba bốn năm sáu";
    context.expect(rows_are(drawn(writer, run), {18.0F, 37.0F, 56.0F}), "9.3 cỡ 14: y_k = 17, 36, 55");
    run.box = {.x = 0.0F, .y = -5.0F, .w = 238.0F, .h = 16.0F};
    run.text = "ab";
    run.horz = 0;
    context.expect(quad_at(drawn(writer, run), 0, 0.0F, -4.0F), "toạ độ âm: trunc(-5,5) là -5, bước dời 1 mất");
}

// Xuống dòng: mỗi dòng S + 5 = 19; ở kiểu bẻ dòng, dòng trống chỉ cao S + 2 = 16.
void writer_breaks(Context& context) {
    const std::optional<ui::BitmapFont> font = open_font(context);
    if (!font) return;
    ui::TextWriter writer(*font, nullptr);
    gui::TextRun run = open_run("a#r#rb", {.x = 0.0F, .y = 10.0F, .w = 100.0F, .h = 100.0F}, gui::TextRule::kRaw);
    context.expect(rows_are(drawn(writer, run), {10.0F, 48.0F}), "không bẻ dòng: dòng trống cũng 19");
    run.horz = 4;
    context.expect(rows_are(drawn(writer, run), {9.0F, 44.0F}), "bẻ dòng: 19 rồi dòng trống 16");
    std::string many;
    for (int line = 0; line < 2000; ++line) many += "a#r";
    run.text = many;
    run.horz = 0;
    const Vertices tall = drawn(writer, run);
    context.expect(tall.size() == 2000 * 4, "hai nghìn dòng");
    context.expect(quad_at(tall, 1999, 0.0F, 10.0F + (1999.0F * 19.0F)), "dòng cuối ở 10 + 1999 x 19");
}

// Màu của bảng thẻ 2026, alpha lấy từ màu của dòng, #i ép alpha; mỗi lần write bắt đầu lại.
void writer_colours(Context& context) {
    const std::optional<ui::BitmapFont> font = open_font(context);
    if (!font) return;
    ui::TextWriter writer(*font, nullptr);
    gui::TextRun run = run_of("a#Rb#Bc#nd", {.x = 0.0F, .y = 0.0F, .w = 200.0F, .h = 20.0F}, gui::TextRule::kRaw);
    run.colour = 0x80112233U;
    const Vertices out = drawn(writer, run);
    context.expect(out.size() == 16, "bốn chữ");
    if (out.size() != 16) return;
    context.expect(out[0].colour == 0x80112233U, "chưa đổi màu thì màu của dòng");
    context.expect(out[4].colour == 0x80FFC0CBU, "#R là FFC0CB, alpha của dòng");
    context.expect(out[8].colour == 0x8000B4FFU, "#B là 00B4FF");
    context.expect(out[12].colour == 0x8000B4FFU, "#n không trả màu về mặc định");
    run.text = "e";
    context.expect(drawn(writer, run).at(0).colour == 0x80112233U, "lần viết sau không mang màu của lần trước");
    run.text = "#i40a#Rb";
    const Vertices faded = drawn(writer, run);
    context.expect(faded.size() == 8 && faded[0].colour == 0x40112233U, "#i ép alpha của màu đang dùng");
    context.expect(faded.size() == 8 && faded[4].colour == 0x40FFC0CBU, "và của màu đặt sau đó");
}

// Màu kéo dài qua chỗ bẻ dòng (các drawText lồng không đặt lại trạng thái).
void writer_colour_carries(Context& context) {
    const std::optional<ui::BitmapFont> font = open_font(context);
    if (!font) return;
    ui::TextWriter writer(*font, nullptr);
    const gui::Box box{.x = 10.0F, .y = 20.0F, .w = 60.0F, .h = 200.0F};
    gui::TextRun run = open_run("ab#Gcdefghijklmnopqrstuvwxyz", box, gui::TextRule::kRaw);
    run.horz = 4;
    const Vertices out = drawn(writer, run);
    context.expect(out.size() == 26 * 4, "đủ chữ");
    if (out.size() != 26 * 4) return;
    context.expect(out[4].colour == kBase && out[8].colour == 0xFF00FF00U, "đổi màu giữa dòng đầu");
    context.expect(out[100].colour == 0xFF00FF00U, "dòng ba vẫn màu đó");
}

// #g: gradient dọc trên ô glyph cao 16; ô bitmap lấy màu ở 1/16 và 15/16. #c không tắt, #e thì tắt.
void writer_gradient(Context& context) {
    const std::optional<ui::BitmapFont> font = open_font(context);
    if (!font) return;
    ui::TextWriter writer(*font, nullptr);
    gui::TextRun run = open_run("#gFF0FA0A", {.x = 0.0F, .y = 10.0F, .w = 100.0F, .h = 20.0F}, gui::TextRule::kRaw);
    const Vertices out = drawn(writer, run);
    context.expect(out.size() == 4, "một chữ");
    if (out.size() != 4) return;
    context.expect(out[0].colour == 0xFFFFFA00U && out[1].colour == 0xFFFFFA00U, "trên: FFFF00 ngả 1/16 về FFAA00");
    context.expect(out[2].colour == 0xFFFFAF00U && out[3].colour == 0xFFFFAF00U, "dưới: 15/16");
    run.text = "#gFF0FA0#RA";
    context.expect(drawn(writer, run).at(0).colour == 0xFFFFFA00U, "#c sau #g không tắt gradient");
    run.text = "#gFF0FA0#e000000A";
    const Vertices flat = drawn(writer, run);
    context.expect(flat.size() == 4 && flat[0].colour == kBase && flat[2].colour == kBase, "#e xoá gradient");
    run.text = "#g123123A";
    context.expect(drawn(writer, run).at(2).colour == kBase, "hai màu gradient bằng nhau thì dùng màu chữ");
}

// Viền #e: vòng tám hướng một điểm ảnh; màu viền có RGB bằng 0 thì không vẽ.
void writer_edge(Context& context) {
    const std::optional<ui::BitmapFont> font = open_font(context);
    if (!font) return;
    ui::TextWriter writer(*font, nullptr);
    const gui::Box box{.x = 100.0F, .y = 100.0F, .w = 100.0F, .h = 40.0F};
    const Vertices edged = drawn(writer, open_run("#e010203A", box, gui::TextRule::kRaw));
    context.expect(edged.size() == 36, "tám bản viền rồi một bản chữ");
    if (edged.size() != 36) return;
    const auto is_edge = [](const render::UiVertex& vertex) { return vertex.colour == 0xFF010203U; };
    context.expect(std::ranges::all_of(edged.begin(), edged.begin() + 32, is_edge), "viền mang màu #e");
    context.expect(edged[32].colour == kBase && quad_at(edged, 8, 100.0F, 100.0F), "chữ vẽ sau viền");
    std::array<bool, 9> seen{};
    seen[4] = true;
    for (std::size_t quad = 0; quad < 8; ++quad) {
        const auto slot = std::lround(((edged[quad * 4].y - 99.0F) * 3.0F) + (edged[quad * 4].x - 99.0F));
        if (slot >= 0 && slot < 9) seen.at(static_cast<std::size_t>(slot)) = true;
    }
    context.expect(std::ranges::all_of(seen, [](bool hit) { return hit; }), "đủ tám hướng, kể cả bốn góc chéo");
    context.expect(drawn(writer, open_run("#e000000A", box, gui::TextRule::kRaw)).size() == 4, "viền 000000 không vẽ");
    context.expect(drawn(writer, open_run("#e010203 ", box, gui::TextRule::kRaw)).empty(), "dấu cách không ra quad");
}

// Ô cắt riêng: quad cắt theo clip chứ không theo box.
void writer_clip(Context& context) {
    const std::optional<ui::BitmapFont> font = open_font(context);
    if (!font) return;
    ui::TextWriter writer(*font, nullptr);
    gui::TextRun run = run_of("Thiên Long", {.x = 30.0F, .y = 40.0F, .w = 10.0F, .h = 16.0F}, gui::TextRule::kRaw);
    run.clip = gui::Box{.x = 20.0F, .y = 45.0F, .w = 30.0F, .h = 6.0F};
    const Vertices out = drawn(writer, run);
    context.expect(!out.empty(), "còn chữ trong ô cắt");
    const auto inside = [](const render::UiVertex& vertex) {
        return vertex.x >= 19.99F && vertex.x <= 50.01F && vertex.y >= 44.99F && vertex.y <= 51.01F;
    };
    context.expect(std::ranges::all_of(out, inside), "mọi đỉnh nằm trong clip");
    const auto by_x = [](const render::UiVertex& left, const render::UiVertex& right) { return left.x < right.x; };
    const bool is_past_box = !out.empty() && std::ranges::max_element(out, by_x)->x > 40.5F;
    context.expect(is_past_box, "chữ tràn khỏi box vẫn vẽ tới mép clip");
    if (out.size() < 4) return;
    context.expect(near_value(out[0].y, 45.0F) && near_value(out[2].y, 51.0F), "cắt trên và dưới");
    context.expect(out[2].v - out[1].v > 0.0F && out[2].y - out[1].y < 14.0F, "toạ độ ảnh co theo");
}

// Liên kết _INFOAIM: khoá không vẽ và không chiếm chỗ; "[x,z]" màu liên kết 00CCFF, mỗi chữ kèm
// một nét gạch chân ở hàng cuối của ô glyph; chữ sau liên kết về màu cũ.
void writer_link(Context& context) {
    const std::optional<ui::BitmapFont> font = open_font(context);
    if (!font) return;
    ui::TextWriter writer(*font, nullptr);
    const gui::Box box{.x = 0.0F, .y = 10.0F, .w = 300.0F, .h = 20.0F};
    const Vertices out = drawn(writer, open_run("x#{_INFOAIM160,157,2,N}y", box, gui::TextRule::kRaw));
    context.expect(out.size() == 20 * 4, "x, chín chữ kèm chín nét gạch chân, y");
    if (out.size() != 20 * 4) return;
    context.expect(quad_at(out, 0, 0.0F, 10.0F) && out[0].colour == kBase, "chữ trước liên kết");
    context.expect(quad_at(out, 1, 6.0F, 10.0F) && out[4].colour == 0xFF00CCFFU, "dấu [ ngay sau x, màu liên kết");
    context.expect(quad_at(out, 2, 6.0F, 24.0F) && out[8].colour == 0xFF00CCFFU, "nét gạch chân ở hàng 9 + 15");
    context.expect(near_value(out[10].x, 11.0F) && near_value(out[10].y, 25.0F), "nét dài bằng bước ngang, cao 1");
    context.expect(quad_at(out, 19, 62.0F, 10.0F) && out[76].colour == kBase, "chữ sau liên kết: 6 + 56, màu cũ");
    const Vertices map = drawn(writer, open_run("#{_INFOMAP1,2,3,N}", box, gui::TextRule::kRaw));
    context.expect(!map.empty() && map[0].colour == 0xFF0099E5U, "INFOMAP: màu liên kết 0099E5");
}

// Mã phông không có: ô vuông rỗng của phông, bút tiến cỡ phông cộng 1.
void writer_missing(Context& context) {
    const std::optional<ui::BitmapFont> font = open_font(context);
    if (!font) return;
    ui::TextWriter writer(*font, nullptr);
    const gui::Box box{.x = 0.0F, .y = 10.0F, .w = 300.0F, .h = 20.0F};
    const Vertices out = drawn(writer, open_run("当a", box, gui::TextRule::kRaw));
    Vertices want;
    font->append_missing(0.0F, 10.0F, kBase, want);
    context.expect(out.size() == 8 && want.size() == 4, "ô vuông rồi chữ a");
    if (out.size() != 8 || want.size() != 4) return;
    context.expect(quad_at(out, 0, 0.0F, 10.0F) && quad_at(out, 1, 15.0F, 10.0F), "chữ a sau ô vuông 15 điểm ảnh");
    context.expect(near_value(out[0].u, want[0].u) && near_value(out[2].v, want[2].v), "đúng ô vuông rỗng của atlas");
}

// Ô nhập (kEdit) giữ cách dàn cũ: mép làm tròn nửa lên, bitmap thấp hơn mép dòng 1, không cộng 1
// khi canh giữa, con nháy cao một dòng ngay sau chữ cuối; chữ là nguyên văn.
void writer_edit(Context& context) {
    const std::optional<ui::BitmapFont> font = open_font(context);
    if (!font) return;
    ui::TextWriter writer(*font, nullptr);
    gui::TextRun run = run_of("A", {.x = 100.0F, .y = 100.0F, .w = 100.0F, .h = 24.0F}, gui::TextRule::kEdit);
    run.horz = 2;
    run.vert = 1;
    run.has_caret = true;
    run.is_plain = true;
    Vertices out;
    const std::optional<gui::Box> caret = writer.write(run, out);
    context.expect(quad_at(out, 0, 146.0F, 105.0F), "floor(100 + 46 + 0,5) và floor(104,5) + 1");
    context.expect(caret.has_value(), "ô đang nhận phím có con nháy");
    if (!caret) return;
    context.expect(near_value(caret->x, 154.0F) && near_value(caret->y, 104.0F), "con nháy sau chữ A");
    context.expect(near_value(caret->w, 1.0F) && near_value(caret->h, 16.0F), "rộng 1, cao một dòng");
    run.text = "#R";
    run.has_caret = false;
    Vertices typed;
    context.expect(!writer.write(run, typed).has_value() && typed.size() == 8, "gõ #R ra hai chữ, không nháy");
}

// Con nháy của dòng không phải ô nhập, chuỗi rỗng, chuỗi chỉ có thẻ, ô không hữu hạn, kiểu canh mà
// drawText gốc ném lỗi (3 và trên 7; kiểu 7 chỉ vẽ được khi không phải bẻ dòng).
void writer_edges(Context& context) {
    const std::optional<ui::BitmapFont> font = open_font(context);
    if (!font) return;
    ui::TextWriter writer(*font, nullptr);
    const gui::Box box{.x = 100.0F, .y = 100.0F, .w = 60.0F, .h = 16.0F};
    gui::TextRun run = open_run("A", box, gui::TextRule::kComponent);
    run.has_caret = true;
    Vertices out;
    const std::optional<gui::Box> caret = writer.write(run, out);
    context.expect(caret && near_value(caret->x, 108.0F) && near_value(caret->y, 99.0F), "con nháy sau chữ, ở mép ô glyph");
    run.has_caret = false;
    run.text = "";
    context.expect(drawn(writer, run).empty(), "chuỗi rỗng");
    run.text = "#R#G#u#b#e010203";
    context.expect(drawn(writer, run).empty(), "chỉ có thẻ");
    run.text = "ab";
    run.horz = 3;
    context.expect(drawn(writer, run).empty(), "Justified: bản gốc ném lỗi, không vẽ");
    run.horz = 7;
    context.expect(drawn(writer, run).size() == 8, "WordWrapJustified một dòng vẽ như canh trái");
    run.text = "một hai ba bốn năm sáu";
    context.expect(drawn(writer, run).empty(), "WordWrapJustified phải bẻ dòng: ném lỗi ở dòng đầu");
    run.horz = 9;
    context.expect(drawn(writer, run).empty(), "kiểu canh lạ");
    run.horz = 0;
    run.box.y = std::numeric_limits<float>::quiet_NaN();
    context.expect(drawn(writer, run).empty(), "ô không hữu hạn");
}

constexpr std::array kCases{
    Case{.name = "writer_amount", .body = &writer_amount},
    Case{.name = "writer_wraps", .body = &writer_wraps},
    Case{.name = "writer_wrap_quirks", .body = &writer_wrap_quirks},
    Case{.name = "writer_wrap_aligns", .body = &writer_wrap_aligns},
    Case{.name = "writer_wrap_tops", .body = &writer_wrap_tops},
    Case{.name = "writer_breaks", .body = &writer_breaks},
    Case{.name = "writer_colours", .body = &writer_colours},
    Case{.name = "writer_colour_carries", .body = &writer_colour_carries},
    Case{.name = "writer_gradient", .body = &writer_gradient},
    Case{.name = "writer_edge", .body = &writer_edge},
    Case{.name = "writer_clip", .body = &writer_clip},
    Case{.name = "writer_link", .body = &writer_link},
    Case{.name = "writer_missing", .body = &writer_missing},
    Case{.name = "writer_edit", .body = &writer_edit},
    Case{.name = "writer_edges", .body = &writer_edges},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_text_tests: mọi ca phải qua");
    return 0;
}
