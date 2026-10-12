// Phần chung của bốn trang sách võ công (CommonSkill, ActionSkill, ZhenfaSkill, LifeSkill): điều
// các trang đọc của game, trạng thái chung của cả sách (trang cuối, hai biến của hệ Variable), sự
// kiện mà các trang nghe, sáu thẻ chuyển trang, các hàm mở trang của Game.exe và hai hàm chữ của hệ
// chuỗi UI_CEGUI.dll.
// Nguồn: phần giống nhau của bốn script Interface/{CommonSkill,ActionSkill,ZhenfaSkill,LifeSkill}
// của client 2026 (các hàm *_ShowPage, *_OnPageClicked, *_CheckPage, *_ClearPage và sáu hàm
// *_Page_Switch), và mã máy Game.exe, UI_CEGUI.dll (docs/NHIEM-VU-VO-CONG-2026.md; địa chỉ ghi ở
// từng hàm).
// Khác gốc: chưa có chỉ dẫn tân thủ (GetFreshManGuideOwner coi như rỗng); TLCJ:IsInTLCJScene coi
// như 0; không đẩy sự kiện VARIABLE_CHANGED khi một biến đổi giá trị (không script nào của sách
// nghe nó); cờ chỉ số 3022 mà DataPool:Lua_CheckOpenTalent hỏi máy chủ coi như tắt, nên thẻ tuyệt
// học không bao giờ mở trang của nó; ScriptGlobal_Format và thông báo của Lua_CheckOpenTalent điền
// ngay mẫu của từ điển (ui/panel/wording) thay vì đóng gói đối số để bộ phân tích chữ của cửa sổ
// điền lúc hiện.
#pragma once

#include "gui/strings.hpp"
#include "skill/actions.hpp"
#include "skill/book.hpp"
#include "skill/tables.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/widgets.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui::panel {

// Sáu trang của sách theo thứ tự thẻ (g_*_Page của script): phổ thông, môn phái, trận pháp, kỹ năng
// sống, chiến đấu tự động, tuyệt học. Số của thẻ trong script là số thứ tự ở đây cộng 1.
enum class BookPage : std::uint8_t { kCommon, kSect, kFormation, kLife, kAutoFight, kTalent };

inline constexpr std::size_t kBookPages = 6;

// Sự kiện của game mà các trang nghe.
enum class BookEvent : std::uint8_t {
    kToggleCommon,
    kToggleSect,
    kToggleLife,
    kOpenFormation,
    kCloseBook,
    kSkillUpdate,
    kLifeUpdate,
    kBrotherhoodUpdate,
    kGemScoreChange,
};

// Tên sự kiện như script đăng ký (RegisterEvent) và như PushEvent ghi vào danh sách việc.
[[nodiscard]] constexpr std::string_view name_of(BookEvent event) noexcept {
    switch (event) {
    case BookEvent::kToggleCommon: return "TOGLE_COMMONSKILL_PAGE";
    case BookEvent::kToggleSect: return "TOGLE_SKILL_BOOK";
    case BookEvent::kToggleLife: return "TOGLE_LIFE_PAGE";
    case BookEvent::kOpenFormation: return "OPEN_ZHENFAFREAM";
    case BookEvent::kCloseBook: return "CLOSE_SKILL_BOOK";
    case BookEvent::kSkillUpdate: return "SKILL_UPDATE";
    case BookEvent::kLifeUpdate: return "UPDATE_LIFESKILL_PAGE";
    case BookEvent::kBrotherhoodUpdate: return "UPDATE_BROTHERSHIP";
    case BookEvent::kGemScoreChange: return "EQUIPGEM_XIULIAN_SCORE_CHANGE";
    }
    return {};
}

// Mã "trang sách cuối" của Game.exe ([data pool + 0x1f8]): 1 phổ thông, 2 môn phái, 3 kỹ năng sống,
// 4 trận pháp, 5 tuyệt học, 6 chiến đấu tự động; bộ dựng đặt -1.
inline constexpr std::int32_t kNoLastPage = -1;

[[nodiscard]] constexpr std::int32_t last_code(BookPage page) noexcept {
    switch (page) {
    case BookPage::kCommon: return 1;
    case BookPage::kSect: return 2;
    case BookPage::kLife: return 3;
    case BookPage::kFormation: return 4;
    case BookPage::kTalent: return 5;
    case BookPage::kAutoFight: return 6;
    }
    return kNoLastPage;
}

// Trạng thái chung của cả sách, sống qua các lần mở đóng trong một phiên chạy (client gốc không
// ghi thứ nào ra tệp): trang cuối, và hai biến mà script cất vào hệ Variable với cờ "tạm".
struct BookMemo {
    std::int32_t last_page = kNoLastPage;
    // "SkillUnionPos": vị trí khung (thuộc tính UnifiedPosition) của trang vừa đóng; trang mở sau
    // đặt khung của mình vào đó. Chưa đặt lần nào thì rỗng.
    std::optional<std::string> union_pos;
    // "SkillPageNumber": vị trí (1..6) của nút thẻ vừa bấm, 0 khi đã dùng xong; chưa đặt thì rỗng.
    std::optional<std::int32_t> page_number;
};

// Điều các trang đọc của game khi xử lý một sự kiện, thay Player, DataPool và hệ action của script.
// Con trỏ mượn phải sống tới hết lời gọi; con trỏ nullptr là "không có" (bảng rỗng, sách rỗng, không
// action nào, chữ để trống, thay đổi của memo bị bỏ).
struct SkillFacts {
    // Player:GetData("LEVEL"), "MEMPAI", "Is2606S" (máy chủ nhẹ).
    std::int32_t level = 1;
    std::int32_t sect = skill::kNoSect;
    bool is_light = false;
    // "XINFASCORE", "XIULIANSCORE", "EQUIPGEMXIULIANSCORE".
    std::int32_t inner_art_score = 0;
    std::int32_t practice_score = 0;
    std::int32_t gem_score = 0;
    // "ZHENFAINFO": cấp của bốn trận pháp (bậc x 1000 + cấp); Player:GetBrotherShip và
    // GetWeekBrotherShip: điểm tình nghĩa đang có và đã nhận trong tuần.
    // Khác gốc: chưa có máy chủ thì bốn cấp trận pháp là 0; client gốc để vùng nhớ đó chưa khởi tạo.
    std::array<std::int32_t, skill::kFormations> formations{};
    std::int32_t brotherhood = 0;
    std::int32_t week_brotherhood = 0;
    // id cảnh đang chơi (cột 0 của SceneDefineEx); -1 là không có cảnh.
    std::int32_t scene = -1;
    const skill::Tables* tables = nullptr;
    const skill::Book* book = nullptr;
    const skill::Actions* actions = nullptr;
    // Từ điển chữ của giao diện (StrDictionary kèm bản dịch), và bản dịch của chuỗi bảng theo khoá
    // nguyên văn.
    const gui::StringBook* words = nullptr;
    BookMemo* memo = nullptr;
};

// Dữ liệu mà một lần xử lý sự kiện đọc, đã thay con trỏ thiếu của facts bằng bản rỗng của chính nó.
// Chỉ sống trong một lời gọi; facts phải sống lâu hơn.
class Shelf {
public:
    explicit Shelf(const SkillFacts& facts);
    Shelf(const Shelf&) = delete;
    Shelf& operator=(const Shelf&) = delete;
    Shelf(Shelf&&) = delete;
    Shelf& operator=(Shelf&&) = delete;
    ~Shelf() = default;

    [[nodiscard]] const SkillFacts& facts() const noexcept { return *facts_; }
    [[nodiscard]] const skill::Tables& tables() const noexcept { return *tables_; }
    [[nodiscard]] const skill::Book& book() const noexcept { return *book_; }
    [[nodiscard]] const skill::Actions& actions() const noexcept { return *actions_; }
    [[nodiscard]] BookMemo& memo() noexcept { return *memo_; }

private:
    skill::Tables no_tables_;
    skill::Book no_book_;
    skill::Actions no_actions_;
    BookMemo no_memo_;
    const SkillFacts* facts_ = nullptr;
    const skill::Tables* tables_ = nullptr;
    const skill::Book* book_ = nullptr;
    const skill::Actions* actions_ = nullptr;
    BookMemo* memo_ = nullptr;
};

// Bỏ mã màu và mã định dạng khỏi một chuỗi, như bộ lọc của UI_CEGUI.dll (0x1800498b0, nhánh
// bControl bằng 0) mà GetDictionaryString, tên bốn action thú cưng và PushDebugMessage đi qua: bỏ
// #R #G #B #P #H #I #K #Y #W #l, bỏ #c, #e, #g kèm sáu ký tự màu, bỏ "#{" không có "}", thay
// "#{_INFOUSRtên}" bằng tên, giữ "#{khoá}" khác, giữ mã biểu cảm #0..#100 và #801..#804 (số khác bị
// bỏ), giữ "#v" kèm đúng bốn chữ số (ít hơn thì bỏ), và giữ mọi dấu # còn lại (#r, #n, #b, #u...).
// Khác gốc: "#{_INFOID số}" giữ nguyên; mã gốc thay bằng tên tra theo số ở một hệ chưa đọc. Mã gốc
// quét byte GBK, bản này quét byte UTF-8: chỉ khác khi byte sau của một chữ Hán trùng "}".
[[nodiscard]] std::string plain_text(std::string_view text);

// GetDictionaryString(khoá) (0x140248800) và tên action lấy theo khoá (0x14061ebd0): chữ của khoá
// trong từ điển đã qua plain_text; không có khoá hay không có từ điển thì rỗng.
// Khác gốc: không chạy chữ qua vsnprintf (mã gốc coi nó là mẫu printf với đối số rác; chữ mà sách
// võ công tra không có "%").
[[nodiscard]] std::string dictionary_text(const gui::StringBook* words, std::string_view key);

// Bản dịch của một chuỗi bảng (tên, mô tả) theo khoá nguyên văn; chưa dịch thì chính chuỗi gốc.
[[nodiscard]] std::string_view translated(const gui::StringBook* words, std::string_view text) noexcept;

// Cảnh "địa phủ" (0x1402297a0): ở ba cảnh 77, 578, 823 sách không mở được.
[[nodiscard]] constexpr bool is_underworld(std::int32_t scene) noexcept {
    return scene == 77 || scene == 578 || scene == 823;
}

// OpenCommonSkillPage (0x140233230), OpenSkillBook (0x1402323e0), OpenLifePage (0x1402331e0),
// OpenZhenfaFream (0x140232430), ToggleTalentPage (0x140232500): ngoài cảnh địa phủ thì đẩy sự kiện
// mở trang rồi ghi trang cuối. Trang chiến đấu tự động không có hàm mở riêng: không làm gì.
void open_page(BookPage page, Shelf& shelf, std::vector<Call>& calls);

// Sáu nút thẻ của một trang theo vị trí 1..6 từ trên xuống, chấm nhắc của thẻ tuyệt học, khung của
// trang, vị trí khung trong layout (thuộc tính UnifiedPosition, nguyên văn) và trang của chính nó.
struct TabBar {
    std::array<std::string_view, kBookPages> buttons;
    std::string_view tips;
    std::string_view frame;
    std::string_view layout_position;
    BookPage own = BookPage::kCommon;
};

// g_*_PageOrder của script: trang nằm ở từng vị trí nút sau lượt xếp thẻ gần nhất.
struct TabOrder {
    std::array<std::optional<BookPage>, kBookPages> pages{};
};

// *_ShowPage: giấu sáu nút, đánh dấu nút mà SkillPageNumber nhớ (rồi xoá biến đó), rồi xếp các
// trang được hiện lên các nút đầu (máy chủ nhẹ không có trang trận pháp), tô vàng thẻ của trang
// đang mở và dời chấm nhắc theo thẻ tuyệt học.
void show_tabs(Widgets& widgets, const TabBar& bar, TabOrder& order, Shelf& shelf);

// Vị trí 1..6 của nút thẻ mang tên window; nullopt khi window không phải nút thẻ của bar.
[[nodiscard]] std::optional<std::size_t> tab_position(const TabBar& bar, std::string_view window) noexcept;

// Điều một lần bấm thẻ đòi trang đang mở làm tiếp: ở lại, hay đóng (cất vị trí khung rồi giấu).
enum class TabOutcome : std::uint8_t { kStay, kLeave };

// Một lần bấm thẻ: nút ở vị trí position (1..6) của bar với thứ tự thẻ order.
struct TabPress {
    const TabBar* bar = nullptr;
    const TabOrder* order = nullptr;
    std::size_t position = 0;
};

// *_OnPageClicked: người chơi bấm nút thẻ (CEGUI đã bật dấu của nút). Nhớ vị trí vào
// SkillPageNumber, rồi theo trang nằm ở nút đó: thẻ của chính trang chỉ xoá biến; thẻ khác mở trang
// của nó (thẻ môn phái đòi đã nhập môn, thẻ chiến đấu đòi đủ cấp và đã nhập môn, thẻ tuyệt học xem
// khác gốc ở đầu tệp), không mở được thì bỏ dấu của nút và nhắc người chơi. press.bar hay
// press.order thiếu, hay vị trí ngoài 1..6, thì không làm gì.
[[nodiscard]] TabOutcome press_tab(Widgets& widgets, const TabPress& press, Shelf& shelf, std::vector<Call>& calls);

// Cất vị trí khung của trang vào SkillUnionPos (giá trị script đã đặt, chưa đặt thì vị trí của
// layout), và đặt khung vào vị trí đã cất khi có.
void save_position(const Widgets& widgets, const TabBar& bar, BookMemo& memo);
void restore_position(Widgets& widgets, const TabBar& bar, const BookMemo& memo);

// Icon và id của một action cho ô nút; action nullptr (action rỗng của mã gốc) là id 0 không icon.
[[nodiscard]] ActionFace face_of(const skill::Action* action, const skill::Tables& tables);
// Mặt của ô khi script đặt thẳng một id action: -1 là ô trống.
[[nodiscard]] ActionFace face_of_id(const Shelf& shelf, std::int32_t action_id);

} // namespace game::ui::panel
