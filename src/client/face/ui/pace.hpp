// Bảng đo nhịp khung trên màn hình (F3), bố cục theo bảng thông số dev của Crazy: ba cột nhãn /
// giá trị căn phải / đơn vị, chia nhóm (nhịp, chặng của khung, tải, đích vẽ), kèm phán quyết so với
// ngân sách khung của tần số quét (120 Hz là 8,3 ms). Phông bitmap AXFT (VTNAM14, có dấu tiếng
// Việt); atlas dựng một lần lúc mở, mỗi khung chỉ ghép quad.
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
// với dòng tổng kết lúc thoát (chỉ số part * (số mẫu - 1)). Nhóm cuối (chặng, tải, đích vẽ) do chỗ
// gọi điền; pace_of chỉ tính nhóm nhịp từ các khoảng khung.
struct PaceNumbers {
    float last_ms = 0.0F;
    float median_ms = 0.0F;
    float p95_ms = 0.0F;
    // Trung bình, lớn nhất và số khung mỗi giây trên cùng các mẫu.
    float average_ms = 0.0F;
    float worst_ms = 0.0F;
    float fps = 0.0F;
    // Phần trăm mẫu vượt ngân sách (kể cả dung sai kBudgetSlack).
    float over_percent = 0.0F;
    // Ngân sách một khung, 1000 / tần số quét mục tiêu; 0 là chưa có mục tiêu.
    float budget_ms = 0.0F;
    float acquire_ms = 0.0F;
    float draw_ms = 0.0F;
    float submit_ms = 0.0F;
    // Dựng quad giao diện của khung (Hud::prepare).
    float prepare_ms = 0.0F;
    std::uint32_t draws = 0;
    std::uint32_t ui_quads = 0;
    std::uint32_t output_width = 0;
    std::uint32_t output_height = 0;
    std::uint32_t samples = 0;
};

// Dung sai của ngân sách: khoảng giữa hai lần present dao động quanh chu kỳ vblank, nên khung dài
// hơn ngân sách dưới chừng này không tính là trượt.
inline constexpr float kBudgetSlack = 1.10F;

// Tỉ lệ khung vượt ngân sách còn chấp nhận được.
inline constexpr float kMaxOverPercent = 5.0F;

// Điền nhóm nhịp (last, median, p95, average, worst, fps, over_percent) từ các khoảng khung (ms);
// các trường còn lại, kể cả budget_ms, giữ nguyên từ phases. O(n log n), n là số mẫu (chỗ gọi giữ
// n <= 90).
[[nodiscard]] PaceNumbers pace_of(std::span<const float> samples, const PaceNumbers& phases);

// Đạt ngân sách khi có mục tiêu, có mẫu và không quá kMaxOverPercent phần trăm khung vượt ngân sách
// (tức p95 nằm trong ngân sách kèm dung sai).
[[nodiscard]] bool meets_budget(const PaceNumbers& pace) noexcept;

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
    // Bề rộng của chuỗi UTF-8 theo đúng bước tiến append_text đi (mã không có trong phông không tính).
    [[nodiscard]] float width_of(std::string_view text) const noexcept;
    // Thêm quad của chuỗi UTF-8. Mã không có trong phông thì bỏ qua.
    void append_text(std::string_view text, float pen_x, float pen_y, std::uint32_t colour,
        std::vector<render::UiVertex>& out) const;
    // Thêm quad của ô vuông rỗng mà client gốc vẽ thay cho mã phông không có (ô cuối của atlas);
    // góc trái trên của ô bitmap ở (pen_x, pen_y).
    void append_missing(float pen_x, float pen_y, std::uint32_t colour, std::vector<render::UiVertex>& out) const;
    // Mã có nét riêng, không phải ô vuông giữ chỗ dùng chung cho cả dải mã thiếu.
    [[nodiscard]] bool paints(char32_t code) const;

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
    // Ô atlas mà nhiều mã cùng trỏ tới (ô giữ chỗ). 0 khi chưa tính.
    mutable std::uint32_t blank_cell_ = 0;
    mutable bool blank_known_ = false;

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

// Chỗ vẽ bảng. font phải sống lâu hơn lần ghi. screen_width > 0: bảng bám mép phải của vùng vẽ rộng
// screen_width, cách mép origin_x (bảng rộng hơn vùng vẽ thì bám mép trái); bằng 0: origin_x là mép
// trái.
struct PacePlace {
    const BitmapFont* font = nullptr;
    std::uint32_t texture = render::kUiWhite;
    float origin_x = 16.0F;
    float origin_y = 16.0F;
    float screen_width = 0.0F;
};

// Xoá overlay rồi ghi bảng ở chỗ place. font rỗng thì overlay rỗng. Nhãn là tiếng Việt: phông phải
// có glyph của chúng (VTNAM14 có; mã thiếu thì bị bỏ, không vẽ ô vuông rỗng).
void write_pace(const PacePlace& place, const PaceNumbers& pace, PaceOverlay& overlay);

} // namespace game::ui
