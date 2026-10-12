// Bảng nhịp khung trên màn hình: phông bitmap AXFT (VTNAM14, có dấu tiếng Việt) và các dòng số
// của khung vừa xong. Atlas dựng một lần lúc mở; mỗi khung chỉ ghép quad.
// Nguồn bố cục AXFT: TOOLS/content/ui_font.py (CEGUIBase.dll, Bin/CEGUIFont_Bitmap.cpp 2008).
#pragma once

#include "core/error.hpp"
#include "render/ui.hpp"
#include "resource/image.hpp"

#include <cstdint>
#include <filesystem>
#include <span>
#include <string_view>
#include <vector>

namespace game::ui {

// Số của khung vừa trình bày. median và p95 lấy trên các mẫu đã gom, cùng cách lấy phần trăm
// với dòng tổng kết lúc thoát (chỉ số part * (số mẫu - 1)).
struct PaceNumbers {
    float last_ms = 0.0F;
    float median_ms = 0.0F;
    float p95_ms = 0.0F;
    float acquire_ms = 0.0F;
    float draw_ms = 0.0F;
    float submit_ms = 0.0F;
    std::uint32_t draws = 0;
    std::uint32_t ui_quads = 0;
};

// Điền last, median, p95 từ các khoảng khung (ms). Ba chặng và số lệnh giữ nguyên từ phases.
[[nodiscard]] PaceNumbers pace_of(std::span<const float> samples, const PaceNumbers& phases);

// Phông AXFT đã trải thành một atlas RGBA8. Không sao chép: atlas nặng.
class BitmapFont {
public:
    [[nodiscard]] static core::Result<BitmapFont> open(const std::filesystem::path& file);

    BitmapFont(BitmapFont&&) noexcept = default;
    BitmapFont& operator=(BitmapFont&&) noexcept = default;
    BitmapFont(const BitmapFont&) = delete;
    BitmapFont& operator=(const BitmapFont&) = delete;
    ~BitmapFont() = default;

    [[nodiscard]] const resource::Image& atlas() const noexcept { return atlas_; }
    [[nodiscard]] int pixel_size() const noexcept { return pixel_size_; }
    [[nodiscard]] bool has_code(char32_t code) const noexcept;
    [[nodiscard]] int advance_of(char32_t code) const noexcept;
    // Thêm quad của chuỗi UTF-8. Mã không có trong phông thì bỏ qua.
    void append_text(std::string_view text, float pen_x, float pen_y, std::uint32_t colour,
        std::vector<render::UiVertex>& out) const;
    // Thêm quad của ô vuông rỗng mà client gốc vẽ thay cho mã phông không có (ô cuối của atlas);
    // góc trái trên của ô bitmap ở (pen_x, pen_y).
    void append_missing(float pen_x, float pen_y, std::uint32_t colour, std::vector<render::UiVertex>& out) const;

private:
    struct Glyph {
        char32_t code = 0;
        std::uint16_t advance = 0;
        std::uint16_t column = 0;
        std::uint16_t row = 0;
    };

    BitmapFont() = default;

    int pixel_size_ = 0;
    int columns_ = 0;
    resource::Image atlas_;
    std::vector<Glyph> glyphs_;

    // Một ô atlas đặt lên màn hình: cột và hàng của ô, góc trái trên và màu của quad.
    struct Placed {
        int column = 0;
        int row = 0;
        float pen_x = 0.0F;
        float pen_y = 0.0F;
        std::uint32_t colour = 0xFFFFFFFFU;
    };

    [[nodiscard]] const Glyph* find(char32_t code) const noexcept;
    void append_one(char32_t code, float& pen_x, float pen_y, std::uint32_t colour,
        std::vector<render::UiVertex>& out) const;
    void append_cell(const Placed& placed, std::vector<render::UiVertex>& out) const;
};

// Quad của bảng: lô nền (texture trắng) rồi lô chữ.
struct PaceOverlay {
    std::vector<render::UiVertex> vertices;
    std::vector<render::UiBatch> batches;
};

// Chỗ vẽ bảng. font phải sống lâu hơn lần ghi.
struct PacePlace {
    const BitmapFont* font = nullptr;
    std::uint32_t texture = render::kUiWhite;
    float origin_x = 16.0F;
    float origin_y = 16.0F;
};

// Xoá overlay rồi ghi bảng tại gốc trái trên. font rỗng thì overlay rỗng.
void write_pace(const PacePlace& place, const PaceNumbers& pace, PaceOverlay& overlay);

} // namespace game::ui
