// Phông AXFT VTNAM14 và bảng nhịp: chữ Việt có glyph, phần trăm khung khớp cách lấy lúc thoát.
#ifndef GAME_CLIENT_DATA
#define GAME_CLIENT_DATA "CLIENT/data"
#endif
#include "ui/pace.hpp"

#include "core/check.hpp"
#include "render/ui.hpp"
#include "test.hpp"

#include <array>
#include <filesystem>

namespace game::test {
namespace {

void font_vietnamese(Context& context) {
    const std::filesystem::path file = std::filesystem::path(GAME_CLIENT_DATA) / "Interface" / "Schema" / "VTNAM14.bin";
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
    const std::filesystem::path file = std::filesystem::path(GAME_CLIENT_DATA) / "Interface" / "Schema" / name;
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
    for (std::size_t row = 0; row < static_cast<std::size_t>(size); ++row) {
        for (std::size_t column = 0; column < static_cast<std::size_t>(size); ++column) {
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
}

void pace_table(Context& context) {
    const std::filesystem::path file = std::filesystem::path(GAME_CLIENT_DATA) / "Interface" / "Schema" / "VTNAM14.bin";
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
    Case{.name = "pace_rank", .body = &pace_rank},
    Case{.name = "pace_table", .body = &pace_table},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "pace_tests: mọi ca phải qua");
    return 0;
}
