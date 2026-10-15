// Trạng thái giữ lại của các cửa sổ một bảng, cho những bảng mà script gốc lái bằng sự kiện (bảng
// nhiệm vụ, sách võ công): client gốc giữ chữ, cờ hiện, dấu chọn, mục danh sách... ngay trong cửa sổ
// CEGUI, script Lua chỉ gọi SetText, Show, SetCheck, AddItem khi có sự kiện. Bản này bỏ CEGUI và
// Lua, nên mỗi bảng giữ một Widgets: hàm xử lý sự kiện của bảng (bản dịch từng hàm của script) ghi
// vào đây đúng những lời gọi script làm, và mỗi khung paint chép trạng thái đang giữ sang Deck.
// Chỉ thứ đã được đặt ít nhất một lần mới có mặt (cửa sổ chưa đụng tới giữ nguyên như layout);
// describe ghi đúng tập đó theo dạng dòng của TOOLS/port/lua_oracle.py, để test so từng byte với
// trạng thái mà script gốc để lại trên LuaPlus.dll của client 2026.
// Tên phương thức gốc ghi ở từng hàm. Thuần logic, không đụng GPU: dựng và test được ở mọi preset.
#pragma once

#include "gui/sheet.hpp"
#include "ui/panel/deck.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::ui::panel {

// Một mục của danh sách (ListBox:AddItem): chữ, id do script đặt và màu chữ "AARRGGBB" (rỗng khi
// script không nêu).
struct ListItem {
    std::string text;
    std::int32_t id = 0;
    std::string colour;
};

// id của ListBox:GetFirstSelectItem và GetClickItem khi không có mục nào.
inline constexpr std::int32_t kNoItem = -1;
// id action của ô nút trống (SetActionItem(-1), GetActionItem khi ô chưa giữ action).
inline constexpr std::int32_t kEmptyAction = -1;

// Action nằm trong một ô nút (ActionButton:SetActionItem): id của action trong hệ action, -1 là ô
// trống, và tên đầy đủ của icon ("set:<bộ ảnh> image:<tên ảnh>", như IconManager của Game.exe đổi
// từ tên icon của bảng). Client gốc để nút tự hỏi action lấy icon; bản này bảng đưa luôn.
struct ActionFace {
    std::int32_t id = -1;
    std::string icon;
};

class Widgets {
public:
    // SetProperty(name, value) của cửa sổ said.window; SetToolTip là thuộc tính "Tooltip".
    void set(const gui::Override& said);
    // SetText.
    void set_text(std::string_view window, std::string_view text);
    // Show và Hide của một cửa sổ con.
    void show(std::string_view window);
    void hide(std::string_view window);
    // Enable và Disable.
    void enable(std::string_view window);
    void disable(std::string_view window);
    // SetCheck(1 hay 0) của nút đánh dấu; người chơi bấm nút cũng đi qua đây (CEGUI bật dấu trước
    // khi gọi hàm của script).
    void check(std::string_view window, bool is_on);
    // SetCheck(1) của một nút đánh dấu CheckMode 1, và cũng là lần người chơi bấm nó: nút này bật,
    // mọi nút đánh dấu cùng cha tắt (FalagardCheckButton::setCheck và onMouseButtonUp của
    // CEGUIFalagard.dll, docs/GIAO-DIEN-2026.md). group là các nút đánh dấu cùng cha, kể cả window;
    // nút nào trong group cũng thành "đã đụng tới". Bấm nút đang bật thì nó vẫn bật.
    void check_one(std::string_view window, std::span<const std::string_view> group);
    // SetPushed(1 hay 0) của nút action.
    void push(std::string_view window, bool is_on);
    // SetActionItem(face.id); id -1 là ô trống.
    void set_action(std::string_view window, ActionFace face);
    // SetProgress(current, total) của thanh: mức thanh là float(current) / float(total) (UI_CEGUI.dll
    // 0x18003a390). Giữ nguyên hai số vì trọng tài ghi "current/total"; paint kẹp mức vào 0..1.
    void set_progress(std::string_view window, double current, double total);
    // SetNewFlash() của nút action: ô có action thì bật cờ nháy theo action, ô trống thì không làm gì (UI_CEGUI
    // 0x180029060, docs/GIAO-DIEN-2026.md 2.7).
    void flash(std::string_view window);
    // Play(is_looping) của cửa sổ hoạt ảnh TLBB_Animate.
    void play(std::string_view window, bool is_looping);
    // Gloom() (is_dim) và Bright() của nút action: thuộc tính Gloom True và False (UI_CEGUI 0x180028cf0, 0x180028970).
    void gloom(std::string_view window, bool is_dim);

    // ClearListBox: bỏ mọi mục, bỏ mục đang chọn, về đầu danh sách.
    void clear_list(std::string_view window);
    // AddItem(text, id, colour).
    void add_item(std::string_view window, ListItem item);
    // AddInfo(text) của danh sách TLBB_InfoList (FalagardInfoList::AddInfo, CEGUIFalagard.dll 0x18006b940): thêm mục info (script
    // đưa chữ, id 0, không màu), bỏ mục cũ nhất cho tới khi còn tối đa limit mục (mục đang chọn dời theo, mất khi bị bỏ), rồi
    // hiện chính danh sách.
    void add_info(std::string_view window, ListItem info, std::size_t limit);
    // SetItemSelectByItemID: chọn mục đầu tiên mang id; không có mục nào mang id thì giữ nguyên.
    void select_item(std::string_view window, std::int32_t id);
    // Người chơi bấm mục mang id: mục đó thành mục đang chọn (không có thì bỏ chọn) và mục vừa
    // bấm.
    void pick_item(std::string_view window, std::int32_t id);
    // SetCurrentFirstItem(index).
    void set_first_item(std::string_view window, std::int32_t index);

    // ClearAllElement của cửa sổ phức hợp.
    void clear_elements(std::string_view window);
    // Một phần tử thêm vào cuối: line là loại và các đối số cách nhau bằng tab ("text<tab>chữ",
    // "money<tab>số", "jiaozi<tab>số", "action<tab>id<tab>số lượng<tab>...").
    void add_element(std::string_view window, std::string line);
    // SetScrollPosition (giữ chỗ cuộn) và ResetScrollPosition (về đầu).
    void keep_scroll(std::string_view window);
    void reset_scroll(std::string_view window);

    // GetCheck: chưa đặt lần nào thì false.
    [[nodiscard]] bool is_checked(std::string_view window) const noexcept;
    // Cửa sổ đang khoá (Disable gọi sau cùng); chưa đặt lần nào thì false. CEGUI không phát Clicked
    // cho cửa sổ khoá, nên bảng hỏi ở đây trước khi chạy hàm của script.
    [[nodiscard]] bool is_disabled(std::string_view window) const noexcept;
    // Cửa sổ đang giấu (Hide gọi sau cùng); chưa đặt lần nào thì false. Cửa sổ giấu không nhận
    // chuột hay phím.
    [[nodiscard]] bool is_hidden(std::string_view window) const noexcept;
    // GetFirstSelectItem: id của mục đang chọn, kNoItem khi không có.
    [[nodiscard]] std::int32_t selected_item(std::string_view window) const noexcept;
    // GetClickItem: id của mục vừa bấm, kNoItem khi chưa bấm mục nào.
    [[nodiscard]] std::int32_t clicked_item(std::string_view window) const noexcept;
    // GetCurrentFirstItem: 0 khi chưa đặt.
    [[nodiscard]] std::int32_t first_item(std::string_view window) const noexcept;
    // id của mục thứ index (từ 0, theo thứ tự AddItem) của danh sách window; nullopt khi chưa có danh
    // sách hay index vượt số mục. Hub::list_item cho index của mục dưới chuột.
    [[nodiscard]] std::optional<std::int32_t> item_id(std::string_view window, std::size_t index) const noexcept;
    // Giá trị đã đặt của một thuộc tính; nullopt khi chưa đặt.
    [[nodiscard]] std::optional<std::string_view> value(const Key& key) const noexcept;
    // id của action đang nằm trong ô của một nút; nullopt khi chưa đặt.
    [[nodiscard]] std::optional<std::int32_t> action(std::string_view window) const noexcept;
    // Mức thanh theo SetProgress, đã kẹp vào 0..1 (ProgressBar::setProgress); nullopt khi chưa đặt.
    [[nodiscard]] std::optional<float> progress(std::string_view window) const noexcept;
    // GetActionItem() của nút action: id action đang giữ, -1 khi ô trống hay chưa đặt (UI_CEGUI 3.71.9509
    // 0x180028f00 đẩy -1 khi con trỏ action null).
    [[nodiscard]] std::int32_t action_item(std::string_view window) const noexcept;
    // Layout khai cửa sổ là Visible=False: trạng thái nền cho IsVisible() tới khi script gọi Show hay
    // Hide. Không vào describe (trọng tài chỉ ghi cờ hiện khi script đã gọi) và không vẽ (layout đã giấu).
    void seed_hidden(std::string_view window);
    // IsVisible() của một cửa sổ con: cờ Show/Hide đã đặt, chưa đặt thì theo layout (hiện, trừ cửa sổ đã
    // seed_hidden).
    [[nodiscard]] bool is_shown(std::string_view window) const noexcept;

    // Chép trạng thái đang giữ sang deck của khung: thuộc tính đã đặt, cờ hiện, khoá, dấu chọn,
    // dấu nhấn (thuộc tính Disabled, Selected, Pushed của bộ dàn trang), icon của ô action
    // (thuộc tính NormalImage; ô trống không đặt gì) và mức thanh. Cửa sổ có thuộc tính Alpha bằng "0" (mờ hẳn
    // sau StartFade) được giấu: bộ dàn trang không có độ trong của từng cửa sổ.
    void paint(Deck& deck) const;
    // Trạng thái đang giữ theo dạng dòng của trọng tài: "cửa sổ<tab>thuộc tính<tab>giá trị", các
    // cửa sổ theo thứ tự đụng tới lần đầu. Xuống dòng trong giá trị viết thành "\n" hai ký tự.
    void describe(std::vector<std::string>& lines) const;

private:
    struct Property {
        std::string name;
        std::string value;
    };

    // Trạng thái của một cửa sổ; trường optional là "chưa đụng tới".
    struct Entry {
        std::string window;
        std::vector<Property> properties;
        std::optional<bool> is_visible;
        std::optional<bool> is_disabled;
        std::optional<bool> is_checked;
        std::optional<bool> is_pushed;
        std::optional<ActionFace> action;
        // SetProgress: tử và mẫu của lần gọi cuối.
        std::optional<std::pair<double, double>> progress;
        bool is_flashing = false;
        // Layout khai Visible=False (xem seed_hidden).
        bool is_layout_hidden = false;
        std::optional<bool> is_playing;
        std::optional<std::vector<ListItem>> items;
        // Chỉ số trong items của mục đang chọn.
        std::optional<std::size_t> selected;
        std::optional<std::int32_t> clicked;
        std::optional<std::int32_t> first;
        std::optional<std::vector<std::string>> elements;
        // true là giữ chỗ cuộn, false là về đầu.
        std::optional<bool> keeps_scroll;
    };

    [[nodiscard]] Entry& entry_of(std::string_view window);
    [[nodiscard]] const Entry* find(std::string_view window) const noexcept;
    // id của mục đang chọn; nullopt khi không có danh sách hay không có mục nào được chọn.
    [[nodiscard]] static std::optional<std::int32_t> chosen_id(const Entry& entry) noexcept;
    static void describe_properties(const Entry& entry, std::vector<std::string>& lines);
    static void describe_entry(const Entry& entry, std::vector<std::string>& lines);
    static void paint_entry(const Entry& entry, Deck& deck);

    std::vector<Entry> entries_;
};

} // namespace game::ui::panel
