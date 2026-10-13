// Bộ viết chữ của giao diện: đọc thẻ # của chuỗi, đo, bẻ dòng, canh trong ô của gui::TextRun và ra
// quad chữ từ phông bitmap AXFT. Port từ mã máy của client 2026 (docs/GIAO-DIEN-2026.md mục 5):
// bộ phân tích chuỗi của UI_CEGUI.dll (0x18004b170) và lớp Font của CEGUIBase.dll
// (drawText 0x18004aa60, drawTextLine 0x18004b250, drawWrappedText 0x18004cf40, getTextExtent
// 0x18004f530, getLineSize 0x18004f050, getFormattedSize 0x18004e7f0, getWrappedSize 0x18004fd90).
// Mã 2008 (_ref/.../UIString.cpp, CEGUIFontBase.cpp) chỉ còn dùng để gọi tên hàm.
// Quyết định: phông của dự án là dòng CodePage khác 936 của scheme (VTNAM14, cỡ 14), nên bẻ dòng
// theo luật "lùi tới ký tự ngắt" của trang mã khác 936; client 2026 thật chạy trang mã 936 và bẻ
// theo từng ký tự. Mọi phép tính chạy trên toạ độ của TextRun::box như được đưa (bản gốc chạy
// trên toạ độ cục bộ của cửa sổ).
// Khác gốc: nháy (#b) không vẽ, chữ hiện đều; biểu cảm và hoạt ảnh (#N, #-NN, #vNNNN, #+NNNN) đọc
// đúng độ dài nhưng không vẽ và rộng 0 (bản gốc cộng bề rộng hoạt ảnh và nâng cao dòng theo nó);
// #vNNNN luôn coi là có hoạt ảnh (bản gốc hỏi AnimateManager); viền #e vẽ bằng tám bản lệch một
// điểm ảnh thay cho vòng viền ghi sẵn trong ô glyph (cùng điểm ảnh khi màu viền đặc); quad gradient
// #g phủ ô bitmap chứ không phủ cả ô glyph nên màu hai mép nội suy sẵn, lệch tối đa một mức; #{ID}
// lồng dừng sau bốn mức và mỗi chuỗi có trần phần tử, trần lần tra (bản gốc đệ quy không trần);
// tham số nhị phân sau dấu * của #{ID*...} và các tiền tố #{_XXX} ngoài _INFOAIM, _INFOMAP chưa
// làm (thẻ bị bỏ); $N và các biến $ khác không thay; kiểu Justified (3) bản gốc ném lỗi, ở đây
// dừng vẽ từ chỗ đó; ô nhập (TextRule::kEdit) giữ cách dàn của mã 2008.
#pragma once

#include "gui/sheet.hpp"
#include "gui/strings.hpp"
#include "render/ui.hpp"
#include "ui/pace.hpp"

#include <cstdint>
#include <optional>
#include <span>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace game::ui {

// Đỉnh của các quad giao diện, bốn đỉnh một quad.
using Vertices = std::vector<render::UiVertex>;

// Một phần tử của chuỗi đã đọc thẻ, như String32 của bản gốc: byte cao bằng 0 là mã ký tự Unicode,
// byte cao khác 0 là mã điều khiển với tham số ở 24 bit thấp (FB màu chữ, FC màu viền, D0 gradient,
// E0 và E1 nháy, E2 alpha, E6 và E7 gạch chân, E8 màu liên kết, FD và FE liên kết, E3, E9 và FA
// hoạt ảnh). Phép bẻ dòng đếm cả mã điều khiển như một ký tự rộng 0.
using Code = std::uint32_t;

struct MarkupAsk {
    std::string_view text;
    // Bảng tra #{ID}; nullptr thì thẻ đó bị bỏ.
    const gui::StringBook* strings = nullptr;
    // Chữ nguyên văn (gui::TextRun::is_plain): không dò thẻ, dấu # cũng là một ký tự.
    bool is_plain = false;
};

// Đọc thẻ # của ask.text (trừ khi ask.is_plain) và thêm các phần tử vào out, đúng dãy mà bộ phân
// tích gốc sinh, kể cả mã tự đóng ở cuối chuỗi (E1 khi còn nháy, E2FF0000 khi đã đặt alpha, E7 khi
// còn gạch chân). Byte UTF-8 hỏng thành U+FFFD. Tuyến tính theo độ dài chuỗi và các chuỗi tra được;
// mỗi lời gọi thêm tối đa 16 384 phần tử và tra bảng tối đa 256 lần, phần vượt trần bị bỏ.
void scan_markup(const MarkupAsk& ask, std::vector<Code>& out);

// Ô của một mã trong atlas phông và bước ngang của nó.
struct GlyphCell {
    float u0 = 0.0F;
    float v0 = 0.0F;
    float u1 = 0.0F;
    float v1 = 0.0F;
    // Bước ngang theo BitmapFont::rasterise bản 2026 (CEGUIBase.dll 0x18003bda4): số ghi trong
    // tệp, mã không có bản ghi lấy cỡ phông; đúng bằng cỡ phông thì cộng 1.
    float advance = 0.0F;
    // Bước ngang ghi trong tệp, 0 khi phông không có mã: ô nhập còn dàn theo số này.
    float file_advance = 0.0F;
    // Phông có mã này. Sai thì ô là ô vuông rỗng của bản gốc.
    bool is_known = false;
    // Ô có ít nhất một điểm sáng; không có thì khỏi ra quad (dấu cách).
    bool has_ink = false;
};

// Kết quả của TextWriter::fit_of.
struct RunFit {
    std::size_t unknown = 0;
    bool has_vietnamese = false;
};

class Typesetter;

// Viết chữ bằng một phông, và là số đo chữ (gui::TextMeter) của chính phông và bộ đọc thẻ đó. Giữ
// bảng ô chữ dựng dần theo mã gặp (BitmapFont tra tuyến tính, nên mỗi mã chỉ hỏi một lần) và bộ
// đệm của phép đọc thẻ, để mỗi khung không cấp phát lại. Các hàm const cũng ghi vào hai thứ đó:
// một TextWriter chỉ dùng trên một luồng.
class TextWriter final : public gui::TextMeter {
public:
    // font và strings (bảng tra #{ID}, nullptr được) phải sống lâu hơn TextWriter.
    TextWriter(const BitmapFont& font, const gui::StringBook* strings);

    // Thêm quad chữ của run vào out theo run.rule, cắt theo run.clip (rỗng thì theo run.box). Trả
    // ô con nháy (sau chữ cuối của dòng cuối) khi run.has_caret. Ô có toạ độ không hữu hạn thì
    // không vẽ gì. Tuyến tính theo số phần tử của chuỗi (trần ở scan_markup).
    [[nodiscard]] std::optional<gui::Box> write(const gui::TextRun& run, Vertices& out);

    // getFontHeight và getLineSpacing của phông bitmap: cỡ phông cộng 2. Bước dòng lúc vẽ là số
    // này cộng 3 (Font::LineSpace).
    [[nodiscard]] float font_height() const override;
    [[nodiscard]] float line_spacing() const override;
    // getLineSize: bề rộng tới mép phải ô glyph xa nhất (lớn hơn width_of khi chữ cuối hẹp) và
    // bề cao một dòng.
    [[nodiscard]] gui::TextSize line_size(std::string_view text) const override;
    // getFormattedSize cho ô có mép trái ở 0 và mép phải ở width: n dòng cao n lần font_height
    // cộng 3 cho mỗi chỗ nối. Chuỗi rỗng và horz ngoài 0..7 (bản gốc ném lỗi) trả (0, 0).
    [[nodiscard]] gui::TextSize formatted_size(std::string_view text, float width, std::uint8_t horz) const override;

    // Bằng font_height; giữ cho nơi gọi cũ.
    [[nodiscard]] float line_height() const noexcept;
    // Run này hợp phông ra sao: số ký tự phông không có bản ghi, và có chữ tiếng Việt có dấu không. Để chọn
    // phông cho cả run: GBK12 có bản ghi cho các mã tiếng Việt nhưng đó là ô giữ chỗ chứ không phải chữ,
    // nên tiếng Việt có dấu ra ô vuông ở phông Hán và đủ chữ ở phông Việt (VTNAM14).
    [[nodiscard]] RunFit fit_of(const gui::TextRun& run) const;

    // getTextExtent: tổng bước ngang của text trên một dòng, đã đọc thẻ; khoá {…} của liên kết
    // không tính.
    [[nodiscard]] float width_of(std::string_view text) const;

private:
    friend class Typesetter;

    // Toạ độ ảnh của tâm một điểm sáng trong atlas: quad lấy mẫu ở đó là quad một màu.
    struct Texel {
        float u = 0.0F;
        float v = 0.0F;
    };

    [[nodiscard]] const GlyphCell& cell_of(Code code) const;
    [[nodiscard]] GlyphCell probe(Code code) const;
    [[nodiscard]] std::optional<Texel> lit_texel(const GlyphCell& cell) const;
    [[nodiscard]] std::span<const Code> scanned(std::string_view text) const;

    const BitmapFont* font_;
    const gui::StringBook* strings_;
    // Điểm sáng của ô vuông rỗng, cho nét gạch chân; rỗng khi atlas không có điểm nào.
    std::optional<Texel> solid_;
    mutable std::unordered_map<Code, GlyphCell> cells_;
    mutable Vertices probe_;
    mutable std::vector<Code> codes_;
};

} // namespace game::ui
