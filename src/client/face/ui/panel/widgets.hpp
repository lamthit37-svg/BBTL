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

// Một cột của bảng nhiều cột (MultiColumnList::addColumn): chữ đầu cột, id do script đặt và bề rộng.
struct GridColumn {
    std::string title;
    std::int32_t id = 0;
    float width = 0.0F;
};

// Một ô của bảng nhiều cột (ListboxTextItem do CtrlList:AddNewItem dựng).
struct GridCell {
    std::string text;
    std::string tooltip;
    // id của mục: id cột khi ô vào một hàng có sẵn, số hàng script đưa khi ô mở hàng mới (GetSelectItem trả số này).
    std::int32_t id = 0;
    // Màu chữ "AARRGGBB" (rỗng khi script không nêu).
    std::string colour;
    // SetRowUserData cất giá trị cộng một, nên 0 là chưa đặt (GetRowUserData trả -1).
    std::int32_t user = 0;
};

// id của hàng (GetSelectItem, GetRowUserData) khi không có.
inline constexpr std::int32_t kNoRow = -1;

// SetRowUserData: số hàng và giá trị script đưa.
struct GridRowData {
    std::int32_t row = 0;
    std::int32_t value = 0;
};

// Một hàm Lua mà script nối vào sự kiện CEGUI của cửa sổ lúc chạy (SetEvent): tên sự kiện, tên hàm và số nguyên đi kèm.
struct EventBinding {
    std::string event;
    std::string handler;
    std::int32_t flag = 0;
};

// Tuổi thọ của một mục InfoList (FalagardInfoList::AddInfo): thời gian sống còn lại (ms, âm là đang mờ), tốc độ mờ
// (thuộc tính FadeSpeed của layout) và độ trong 1..0.
struct InfoLife {
    std::int32_t life_ms = 0;
    std::int32_t fade_speed = 0;
    float alpha = 1.0F;
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
    // SetFadeState(total) của thanh tiến trình (FalagardSuperProgress): total > 0 mở đoạn mờ dần total giây, ngược lại xoá nó.
    void set_fade(std::string_view window, float total);
    // Tên các cửa sổ đang có đoạn mờ dần.
    [[nodiscard]] std::vector<std::string> fading() const;
    // Nhịp thời gian của FalagardSuperProgress::updateSelf cho một cửa sổ đang mờ dần: trừ seconds khỏi thời gian còn, ghi
    // Alpha = còn / tổng; còn nhỏ hơn 0 (bằng 0 chưa tính) thì giấu cửa sổ và trả true. Cửa sổ không mờ dần: false.
    bool step_fade(std::string_view window, float seconds);

    // ClearListBox: bỏ mọi mục, bỏ mục đang chọn, về đầu danh sách.
    void clear_list(std::string_view window);
    // AddItem(text, id, colour).
    void add_item(std::string_view window, ListItem item);
    // AddInfo(text) của danh sách TLBB_InfoList (FalagardInfoList::AddInfo, CEGUIFalagard.dll 0x18006b940): thêm mục info (script
    // đưa chữ, id 0, không màu) mang tuổi thọ life, bỏ mục cũ nhất cho tới khi còn tối đa limit mục (mục đang chọn dời theo, mất
    // khi bị bỏ), rồi hiện chính danh sách. Từ đây cửa sổ là danh sách có tuổi thọ: tick_info làm các mục già đi và paint nối
    // chữ các mục thành thuộc tính Text.
    void add_info(std::string_view window, ListItem info, InfoLife life, std::size_t limit);
    // Tên các cửa sổ là danh sách có tuổi thọ (đã AddInfo ít nhất một lần).
    [[nodiscard]] std::vector<std::string> aging() const;
    // Một nhịp FalagardInfoList::updateSelf (0x18006bd60) trong seconds giây: mỗi mục có tuổi thọ bị trừ; tuổi thọ âm thì độ
    // trong giảm fade_speed / 255 mỗi giây; độ trong âm thì bỏ mục. Bỏ một mục thì mục kế dồn vào chỗ đó và bị bỏ qua tới nhịp
    // sau. Thời gian âm hay NaN tính là 0, vô hạn hay quá lớn tính là mức int32 lớn nhất. Cửa sổ không phải danh sách có tuổi
    // thọ: không làm gì.
    void tick_info(std::string_view window, float seconds);
    // SetEvent(sự kiện, hàm, số): nối thêm một hàm vào sự kiện của cửa sổ (Window::setdEvent). Chưa kiểm xem gốc có thay hay cộng dồn
    // khi nối hai lần cùng sự kiện nên giữ cả hai theo thứ tự nối.
    void bind_event(std::string_view window, EventBinding binding);
    // RemoveEvent(sự kiện): bỏ sự kiện (name của event) của cửa sổ (window của event) cùng mọi hàm đã nối vào nó (EventSet::removeEvent); true khi có hàm bị bỏ.
    bool unbind_event(const Key& event);
    // Các hàm đã nối vào cửa sổ theo thứ tự nối; rỗng khi chưa có.
    [[nodiscard]] std::span<const EventBinding> event_bindings(std::string_view window) const noexcept;
    // SetItemSelectByItemID: chọn mục đầu tiên mang id; không có mục nào mang id thì giữ nguyên.
    void select_item(std::string_view window, std::int32_t id);
    // Người chơi bấm mục mang id: mục đó thành mục đang chọn (không có thì bỏ chọn) và mục vừa
    // bấm.
    void pick_item(std::string_view window, std::int32_t id);
    // SetCurrentFirstItem(index).
    void set_first_item(std::string_view window, std::int32_t index);

    // ---- Hộp thả (Combobox): danh sách thả dùng lại items/selected của danh sách thường ----
    // SetCurrentSelect: chọn mục thứ index (từ 0); false khi index ngoài danh sách, khi đó không đổi gì.
    bool select_index(std::string_view window, std::size_t index);
    // ClearAllSelections: bỏ dấu chọn, giữ mục.
    void clear_selection(std::string_view window);
    // SetTextItemText: đổi chữ của mục thứ index; false khi index ngoài danh sách.
    bool set_item_text(std::string_view window, std::size_t index, std::string text);
    // Số mục (GetListCount), mục thứ index và mục đang chọn (GetTextItemId, GetCurrentSelect); nullptr khi không có.
    [[nodiscard]] std::size_t item_count(std::string_view window) const noexcept;
    [[nodiscard]] const ListItem* item_at(std::string_view window, std::size_t index) const noexcept;
    [[nodiscard]] const ListItem* chosen_item(std::string_view window) const noexcept;

    // ---- Bảng nhiều cột (MultiColumnList của CtrlList) ----
    // AddColumn (position rỗng: thêm cuối) và InsertColumn (position vượt số cột thì thêm cuối); hàng có sẵn nhận ô trống ở cột mới.
    void add_column(std::string_view window, GridColumn column, std::optional<std::size_t> position);
    // RemoveColumnByPos; false khi index ngoài các cột.
    bool remove_column(std::string_view window, std::size_t index);
    // AddNewItem: cell.id là id cột. Hàng row đã có ô ở cột 0 thì ô vào hàng đó ở cột mang id cell.id; không thì mở hàng
    // mới (ô đổi sang id row). false khi không có cột mang id cell.id (CEGUI ném ngoại lệ, script gốc dừng ở lời gọi).
    bool put_cell(std::string_view window, GridCell cell, std::int32_t row);
    // SetItemText(row, column index, text) và GetItemText; nullopt khi ô không có.
    bool set_cell_text(std::string_view window, std::int32_t row, std::int32_t column, std::string text);
    [[nodiscard]] std::optional<std::string_view> cell_text(std::string_view window, std::int32_t row,
        std::int32_t column) const noexcept;
    // SetRowUserData, GetRowUserData (kNoRow khi hàng không có ô ở cột 0 hay chưa đặt) và SetRowTooltip: đều theo ô cột 0.
    bool set_row_data(std::string_view window, GridRowData data);
    [[nodiscard]] std::int32_t row_data(std::string_view window, std::int32_t row) const noexcept;
    bool set_row_tooltip(std::string_view window, std::int32_t row, std::string text);
    // DeleteItem (false khi row ngoài các hàng), RemoveAllItem (bỏ hàng, giữ cột và vị trí cuộn về 0).
    bool remove_row(std::string_view window, std::int32_t row);
    void clear_rows(std::string_view window);
    // SetSelectItem: chọn hàng row khi ô cột 0 của nó có; GetSelectItem trả id của ô cột 0 hàng đang chọn (kNoRow khi
    // không có).
    bool select_row(std::string_view window, std::int32_t row);
    [[nodiscard]] std::int32_t selected_row(std::string_view window) const noexcept;
    // SetVertScollPosition (0..số hàng).
    bool scroll_rows(std::string_view window, std::int32_t row);
    [[nodiscard]] std::size_t row_count(std::string_view window) const noexcept;
    [[nodiscard]] std::size_t column_count(std::string_view window) const noexcept;

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

    // Bảng nhiều cột: mỗi hàng giữ một ô (hoặc trống) cho từng cột theo thứ tự cột.
    struct Grid {
        std::vector<GridColumn> columns;
        std::vector<std::vector<std::optional<GridCell>>> rows;
        std::optional<std::size_t> selected;
        std::int32_t scroll = 0;
    };

    // Đoạn mờ dần của thanh tiến trình: tổng và thời gian còn (giây).
    struct Fade {
        float total = 0.0F;
        float left = 0.0F;
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
        std::optional<Grid> grid;
        std::optional<Fade> fade;
        // Danh sách có tuổi thọ (AddInfo đã gọi): mỗi mục của items có đúng một ô ở đây, nullopt là mục thêm bằng AddItem
        // (không già đi). Rỗng khi không phải danh sách ấy.
        std::vector<std::optional<InfoLife>> lives;
        bool is_info = false;
        std::vector<EventBinding> bindings;
    };

    [[nodiscard]] Entry& entry_of(std::string_view window);
    [[nodiscard]] const Entry* find(std::string_view window) const noexcept;
    // Bỏ mục thứ index của danh sách (cùng ô tuổi thọ); mục đang chọn dời theo, mất khi chính nó bị bỏ.
    static void erase_item(Entry& entry, std::size_t index);
    // id của mục đang chọn; nullopt khi không có danh sách hay không có mục nào được chọn.
    [[nodiscard]] static std::optional<std::int32_t> chosen_id(const Entry& entry) noexcept;
    static void describe_properties(const Entry& entry, std::vector<std::string>& lines);
    static void describe_entry(const Entry& entry, std::vector<std::string>& lines);
    static void paint_entry(const Entry& entry, Deck& deck);
    // Bảng nhiều cột của cửa sổ; nullptr khi chưa có (chưa thêm cột hay hàng nào).
    [[nodiscard]] Grid* grid_of(std::string_view window) noexcept;
    [[nodiscard]] const Grid* grid_of(std::string_view window) const noexcept;
    // Ô ở hàng row, cột chỉ số column; nullptr khi ngoài bảng hay ô trống.
    [[nodiscard]] static GridCell* cell_at(Grid& grid, std::int32_t row, std::int32_t column) noexcept;
    [[nodiscard]] static const GridCell* cell_at(const Grid& grid, std::int32_t row, std::int32_t column) noexcept;

    std::vector<Entry> entries_;
};

} // namespace game::ui::panel
