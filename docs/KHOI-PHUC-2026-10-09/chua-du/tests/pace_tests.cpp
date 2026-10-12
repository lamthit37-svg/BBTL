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
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
