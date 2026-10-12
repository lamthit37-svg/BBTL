// Chỉ thị của một khung cho gui::Hub. Client gốc để script Lua của từng cửa sổ gọi Show, Hide,
// SetText, SetProperty và SetProgress; bản này bỏ Lua, nên mỗi bảng (các tệp khác của ui/panel) ghi
// những lời gọi đó vào một Deck mỗi khung, rồi HUD đưa Deck cho Hub. Hub tự so với khung trước, nên
// ghi lại y nguyên mỗi khung không tốn lượt dàn trang nào. Deck giữ bộ đệm của khung trước: ghi lại
// cùng số dòng với chuỗi không dài hơn thì không cấp phát.
// Thuần logic, không đụng GPU: dựng và test được ở mọi preset.
#pragma once

#include "gui/sheet.hpp"

#include <cstddef>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui::panel {

// Một thuộc tính của một cửa sổ. Hai tên phải sống tới hết khung (hằng của bảng).
struct Key {
    std::string_view window;
    std::string_view name;
};

class Deck {
public:
    // Bỏ mọi chỉ thị, giữ bộ nhớ đã cấp.
    void clear() noexcept;

    // Hiện một cửa sổ gốc. Gốc kê sau nằm trên; kê lại một gốc đã có thì không đổi chỗ.
    void show(std::string_view root);
    // Giấu một cửa sổ (gốc hay con) dù layout để hiện.
    void hide(std::string_view window);
    // Hiện một cửa sổ con mà layout để ẩn (Visible=False), như Show của script gốc.
    void reveal(std::string_view window);
    // Đặt thuộc tính lúc chạy, như SetText và SetProperty. window và name của said phải sống tới
    // hết khung (tên cửa sổ và tên thuộc tính là hằng của bảng); value được chép.
    void set(const gui::Override& said);
    // Như set cho chuỗi dựng lúc chạy: thêm dòng của key rồi trả bộ đệm giá trị (đã xoá, giữ sức
    // chứa) để người gọi ghi thẳng vào. Tham chiếu còn đúng tới lần set, compose hay clear kế.
    [[nodiscard]] std::string& compose(const Key& key);
    // Đặt thanh, như SetProgress: amount trong 0..1.
    void bar(std::string_view window, float amount);

    [[nodiscard]] bool is_shown(std::string_view root) const noexcept;
    [[nodiscard]] std::span<const std::string_view> roots() const noexcept { return roots_; }
    [[nodiscard]] std::span<const std::string_view> hidden() const noexcept { return hidden_; }
    [[nodiscard]] std::span<const gui::Bar> bars() const noexcept { return bars_; }
    // Dựng lại các dòng Override trỏ vào giá trị đã chép; còn đúng tới lần set, compose hay clear
    // kế.
    [[nodiscard]] std::span<const gui::Override> overrides();

private:
    struct Entry {
        std::string_view window;
        std::string_view name;
        std::string value;
    };

    std::vector<std::string_view> roots_;
    std::vector<std::string_view> hidden_;
    std::vector<gui::Bar> bars_;
    std::vector<Entry> entries_;
    // Số dòng đầu của entries_ đang dùng: clear chỉ đặt về 0 để giữ bộ đệm của từng chuỗi.
    std::size_t used_ = 0;
    std::vector<gui::Override> views_;
};

} // namespace game::ui::panel
