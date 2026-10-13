// Phông AXFT VTNAM14 và bảng nhịp: chữ Việt có glyph, phần trăm khung khớp cách lấy lúc thoát.
#include "ui/pace.hpp"

#include "core/check.hpp"
#include "core/error.hpp"
#include "render/ui.hpp"
#include "resource/image.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <cstddef>
#include <filesystem>
#include <span>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

// CMake đưa GAME_CLIENT_DATA (dev/client/assets) khi thư mục ấy có phông giao diện.
#ifdef GAME_CLIENT_DATA
constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
constexpr std::string_view kClientData = "CLIENT/data";
#endif

// Mọi chữ có dấu mà bảng đo dùng trong nhãn và phán quyết: thiếu glyph là mất chữ lặng lẽ.
void pace_labels_have_glyphs(Context& context) {
    const std::filesystem::path file = std::filesystem::path(kClientData) / "Interface" / "Schema" / "VTNAM14.bin";
    const core::Result<ui::BitmapFont> font = ui::BitmapFont::open(file);
    context.expect(font.has_value(), "mở được VTNAM14 cho nhãn bảng đo");
    if (!font) return;
    for (const char32_t code : std::u32string_view(U"Mục tiêu Kết luận ĐẠT TRƯỢT Khung Trung vị Chậm nhất "
                                                  U"Vượt ngân sách Xin ảnh Ghi lệnh Nộp Dựng UI Lệnh vẽ Màn hình")) {
        context.expect(font->has_code(code), "phông có glyph của nhãn bảng đo");
    }
}

void font_vietnamese(Context& context) {
    const std::filesystem::path file = std::filesystem::path(kClientData) / "Interface" / "Schema" / "VTNAM14.bin";
    const core::Result<ui::BitmapFont> font = ui::BitmapFont::open(file);
    context.expect(font.has_value(), "mở được VTNAM14");
    if (!font) return;
    context.expect(font->pixel_size() == 14, "cỡ 14");
    context.expect(font->has_code(U'đ'), "có chữ đ");
    context.expect(font->has_code(U'ị'), "có chữ ị");
    context.expect(font->advance_of(U'A') > 0, "A có bước ngang");
    const resource::Image& atlas = font->atlas();
    const std::size_t bytes = static_cast<std::size_t>(atlas.width) * atlas.height * 4;
    context.expect(atlas.rgba.size() == bytes, "atlas đủ byte");
}

// Ô vuông rỗng của mã phông không có: khung 7 x 8 điểm ảnh ở cột 2..8, hàng 2..9 của ô bitmap, như
// bộ trải AXFT của CEGUIBase.dll 2026 (cỡ 14: 0x180132e3b; cỡ 12: 0x180132a06).
void font_missing_box(Context& context, std::string_view name, int size) {
    const std::filesystem::path file = std::filesystem::path(kClientData) / "Interface" / "Schema" / name;
    const core::Result<ui::BitmapFont> font = ui::BitmapFont::open(file);
    context.expect(font.has_value(), "mở được phông");
    if (!font) return;
    std::vector<render::UiVertex> quad;
    font->append_missing(30.0F, 40.0F, 0xFF010203U, quad);
    context.expect(quad.size() == 4, "một quad");
    if (quad.size() != 4) return;
    const auto side = static_cast<float>(size);
    context.expect(quad[0].x == 30.0F && quad[0].y == 40.0F && quad[0].colour == 0xFF010203U, "góc trái trên và màu");
    context.expect(quad[2].x == 30.0F + side && quad[2].y == 40.0F + side, "ô bitmap vuông cạnh cỡ phông");
    const resource::Image& atlas = font->atlas();
    const auto left = static_cast<std::size_t>(std::lround(quad[0].u * static_cast<float>(atlas.width)));
    const auto top = static_cast<std::size_t>(std::lround(quad[0].v * static_cast<float>(atlas.height)));
    const bool is_inside = left + static_cast<std::size_t>(size) <= atlas.width &&
        top + static_cast<std::size_t>(size) <= atlas.height;
    context.expect(is_inside, "ô nằm trọn trong atlas");
    if (!is_inside) return;
    const auto is_lit = [&atlas, left, top](std::size_t column, std::size_t row) {
        return atlas.rgba.at(((((top + row) * atlas.width) + left + column) * 4) + 3) == 255;
    };
    std::size_t lit = 0;
    const auto edge = static_cast<std::size_t>(size);
    for (std::size_t row = 0; row < edge; ++row) {
        for (std::size_t column = 0; column < edge; ++column) {
            if (is_lit(column, row)) ++lit;
        }
    }
    context.expect(lit == 26, "khung 7 x 8 có 26 điểm");
    context.expect(is_lit(2, 2) && is_lit(8, 2) && is_lit(2, 9) && is_lit(8, 9), "bốn góc khung");
    context.expect(is_lit(5, 2) && is_lit(5, 9) && is_lit(2, 5) && is_lit(8, 5), "bốn cạnh khung");
    context.expect(!is_lit(5, 5) && !is_lit(1, 2) && !is_lit(9, 9) && !is_lit(2, 10), "trong và ngoài khung trống");
}

void font_missing_14(Context& context) {
    font_missing_box(context, "VTNAM14.bin", 14);
}

void font_missing_12(Context& context) {
    font_missing_box(context, "GBK12.bin", 12);
}

void pace_rank(Context& context) {
    const std::array<float, 5> samples{10.0F, 20.0F, 30.0F, 40.0F, 100.0F};
    ui::PaceNumbers phases;
    phases.draws = 7;
    const ui::PaceNumbers pace = ui::pace_of(samples, phases);
    context.expect(pace.last_ms == 100.0F, "mẫu cuối");
    context.expect(pace.median_ms == 30.0F, "trung vị");
    context.expect(pace.p95_ms == 40.0F, "p95 là mẫu thứ 4");
    context.expect(pace.draws == 7, "giữ số lệnh");
    context.expect(pace.worst_ms == 100.0F, "khung dài nhất");
    context.expect(std::abs(pace.average_ms - 40.0F) < 1e-3F, "trung bình 40 ms");
    context.expect(std::abs(pace.fps - 25.0F) < 1e-3F, "5 khung trong 200 ms là 25 fps");
    context.expect(pace.over_percent == 0.0F, "chưa có ngân sách thì không đếm vượt");
}

// Ngân sách 120 Hz: 8,333 ms, dung sai 10%, tối đa 5% khung vượt. Một mẫu 20 ms trên hai mươi vượt
// đúng 5%: còn đạt; hai mẫu thì trượt.
void pace_budget(Context& context) {
    constexpr float kBudget = 1000.0F / 120.0F;
    ui::PaceNumbers phases;
    phases.budget_ms = kBudget;
    std::array<float, 20> hiccup{};
    hiccup.fill(8.3F);
    hiccup.back() = 20.0F;
    const ui::PaceNumbers one = ui::pace_of(hiccup, phases);
    context.expect(std::abs(one.over_percent - 5.0F) < 1e-3F, "một mẫu trên hai mươi vượt ngân sách");
    context.expect(one.budget_ms == kBudget, "giữ ngân sách");
    context.expect(ui::meets_budget(one), "đúng 5% vượt còn đạt");
    hiccup.at(3) = 20.0F;
    const ui::PaceNumbers two = ui::pace_of(hiccup, phases);
    context.expect(std::abs(two.over_percent - 10.0F) < 1e-3F, "hai mẫu trên hai mươi là 10%");
    context.expect(!ui::meets_budget(two), "10% vượt thì trượt");
    const std::array<float, 4> slow{12.0F, 12.0F, 12.0F, 12.0F};
    context.expect(!ui::meets_budget(ui::pace_of(slow, phases)), "12 ms trượt ngân sách 120 Hz");
    const std::array<float, 4> edge{9.1F, 9.1F, 9.1F, 9.1F};
    context.expect(ui::meets_budget(ui::pace_of(edge, phases)), "9,1 ms còn trong dung sai 10%");
    context.expect(!ui::meets_budget(ui::pace_of(std::span<const float>{}, phases)), "không mẫu thì chưa đạt");
    context.expect(!ui::meets_budget(ui::pace_of(edge, ui::PaceNumbers{})), "không ngân sách thì chưa đạt");
}

void pace_table(Context& context) {
    const std::filesystem::path file = std::filesystem::path(kClientData) / "Interface" / "Schema" / "VTNAM14.bin";
    const core::Result<ui::BitmapFont> font = ui::BitmapFont::open(file);
    context.expect(font.has_value(), "mở được phông để vẽ bảng");
    if (!font) return;
    ui::PacePlace place;
    place.font = &*font;
    place.texture = 3;
    ui::PaceOverlay overlay;
    ui::write_pace(place, ui::PaceNumbers{}, overlay);
    context.expect(overlay.batches.size() == 2, "nền rồi chữ");
    context.expect(overlay.batches.front().texture == render::kUiWhite, "nền là texture trắng");
    context.expect(overlay.batches.back().texture == 3, "chữ dùng atlas");
    context.expect(overlay.vertices.size() > 8, "có glyph");
}

constexpr std::array kCases{
    Case{.name = "font_vietnamese", .body = &font_vietnamese},
    Case{.name = "pace_labels_have_glyphs", .body = &pace_labels_have_glyphs},
    Case{.name = "font_missing_14", .body = &font_missing_14},
    Case{.name = "font_missing_12", .body = &font_missing_12},
    Case{.name = "pace_rank", .body = &pace_rank},
    Case{.name = "pace_budget", .body = &pace_budget},
    Case{.name = "pace_table", .body = &pace_table},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "pace_tests: mọi ca phải qua");
    return 0;
}
