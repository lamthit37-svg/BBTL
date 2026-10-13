// Bảng chọn máy chủ (xem select_server.hpp). Mỗi hàm dưới đây là bản dịch của một hàm trong
// SelectServer.lua; tên hàm gốc ghi ở đầu từng hàm.
#include "ui/panel/select_server.hpp"

#include "gui/content.hpp"
#include "gui/sheet.hpp"
#include "gui/strings.hpp"
#include "ui/panel/code_text.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/names.hpp"
#include "ui/panel/servers.hpp"
#include "ui/panel/wording.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::ui::panel {
namespace {

constexpr std::string_view kRoot = "SelectServer_Frame";
constexpr std::string_view kRecommendFrame = "SelectServer_Frame2_Sub1";
constexpr std::string_view kFluencyFrame = "SelectServer_Frame2_Sub4";
constexpr std::string_view kAreaFrame = "SelectServer_Frame2_Sub2";
constexpr std::string_view kTitle = "SelectServer_Server_AreaNameShow";
constexpr std::string_view kHelp = "SelectServer_Help2_Text";
constexpr std::string_view kInfo = "SelectServer_Info";
constexpr std::string_view kLastButton = "SelectServer_Server_Last";
constexpr std::string_view kLastImage = "SelectServer_Server_Last_Img";
constexpr std::string_view kUpPage = "SelectServer_UpPage";
constexpr std::string_view kDownPage = "SelectServer_DownPage";
constexpr std::string_view kLineEdit = "SelectServer_LineSelect__auto_editbox__";
constexpr std::string_view kLineList = "SelectServer_LineSelect__auto_droplist__";
constexpr std::string_view kAccept = "SelectServer_Accept";
constexpr std::string_view kRegister = "SelectServer_Regist";
constexpr std::string_view kCharge = "SelectServer_Charge";
constexpr std::string_view kCancel = "SelectServer_Cancel";
constexpr std::string_view kWeGameCancel = "SelectServer_WeGame_Cancel";
constexpr std::string_view kRoleInquiry = "SelectServer_RoleInquiry";
constexpr std::string_view kBack = "SelectServer_shangyibu";
constexpr std::string_view kSearchOk = "SelectServer_Server_SearchBtOK";

constexpr std::string_view kCatalogKey = "SelectServerCatalog";
constexpr std::string_view kTextKey = "SelectServerText";
constexpr std::string_view kHoverSection = "SelectServerHoverSection";

// Số máy chủ trên một trang kết quả tìm: g_ServerBn.MAX_SERVER_COUNT - 1 (nút cuối dành cho trường
// hợp đúng 85 kết quả, khi cả 85 hiện trên một trang).
constexpr std::size_t kSearchPageSize = kServersPerArea - 1;
// MaxTextLength của ô tìm trong layout.
constexpr std::size_t kSearchLimit = 12;
// Trần chữ của một trang kết quả tìm và số nhà mạng trong ô chọn.
constexpr std::size_t kLineCount = 4;

constexpr char32_t kBackspace = U'\b';
constexpr char32_t kEnter = U'\r';

constexpr auto kServerButtons = numbered<kServersPerArea>({.prefix = "SelectServer_Server", .suffix = ""});
constexpr auto kServerImages = numbered<kServersPerArea>({.prefix = "SelectServer_Server", .suffix = "_Img"});
constexpr auto kRecommendButtons =
    numbered<kRecommendCap>({.prefix = "SelectServer_Commendable_Subarea", .suffix = ""});
constexpr auto kRecommendImages =
    numbered<kRecommendCap>({.prefix = "SelectServer_Commendable_Subarea", .suffix = "_Img"});

// Số thứ tự (từ 1) khi window là prefix cộng một số và không còn gì nữa; số ngoài [1, count] thì
// không có.
[[nodiscard]] std::optional<std::size_t> ordinal_of(std::string_view window, std::string_view prefix, std::size_t count) noexcept {
    if (!window.starts_with(prefix)) return std::nullopt;
    const std::string_view digits = window.substr(prefix.size());
    if (digits.empty() || digits.size() > 3) return std::nullopt;
    std::size_t value = 0;
    for (const char letter : digits) {
        if (letter < '0' || letter > '9') return std::nullopt;
        value = (value * 10) + static_cast<std::size_t>(letter - '0');
    }
    if (value < 1 || value > count) return std::nullopt;
    return value;
}

// Đại khu: tên hiện, hai chú thích (mở và đóng), có luôn hiện không (MustShow) và có danh sách vùng
// con không (ShowList), theo g_AreaUI.AreaCtrlInfo.
struct BigInfo {
    std::string_view name;
    std::string_view open_tip;
    std::string_view close_tip;
    bool must_show = false;
    bool shows_list = false;
};

constexpr std::array<BigInfo, kBigAreaSlots> kBigInfo = {{
    {},
    {.name = "#{DLYHQF_12121301}", .open_tip = "#{DLYHQF_12121307}", .close_tip = "#{DLYHQF_12121307}",
        .must_show = true, .shows_list = false},
    {.name = "#{DLYHQF_12121303}", .open_tip = "#{DLYHQF_12121309}", .close_tip = "#{DLYHQF_12121309}",
        .must_show = false, .shows_list = false},
    {.name = "#{DLYHQF_12121304}", .open_tip = "#{DLYHQF_12121310}", .close_tip = "#{DLYHQF_12121311}",
        .must_show = true, .shows_list = true},
    {.name = "#{DLYHQF_12121305}", .open_tip = "#{DLYHQF_12121312}", .close_tip = "#{DLYHQF_12121313}",
        .must_show = true, .shows_list = true},
    {.name = "#{DLYHQF_12121306}", .open_tip = "#{DLYHQF_12121314}", .close_tip = "#{DLYHQF_12121315}",
        .must_show = true, .shows_list = true},
    {.name = "#{DLYHQF_12121362}", .open_tip = "#{DLYHQF_12121363}", .close_tip = "#{DLYHQF_12121364}",
        .must_show = false, .shows_list = true},
    {.name = "#{DLYHQF_12121365}", .open_tip = "#{DLYHQF_12121366}", .close_tip = "#{DLYHQF_12121367}",
        .must_show = false, .shows_list = false},
    {.name = "#{BHKF_150323_198}", .open_tip = "#{BHKF_150323_199}", .close_tip = "#{BHKF_150323_199}",
        .must_show = false, .shows_list = false},
    {.name = "#{WCJS_180521_71}", .open_tip = "#{WCJS_180521_72}", .close_tip = "#{WCJS_180521_72}",
        .must_show = false, .shows_list = false},
    {.name = "#{SJDF_190603_194}", .open_tip = "#{SJDF_190603_195}", .close_tip = "#{SJDF_190603_196}",
        .must_show = false, .shows_list = false},
    {.name = "#{WEJR_251216_03}", .open_tip = "#{WEJR_251216_04}", .close_tip = "#{WEJR_251216_05}",
        .must_show = false, .shows_list = false},
}};

// Khi vùng đầu của đại khu tranh bá tên "tổng quyết đấu" thì nhãn và chú thích đổi (g_ZBS_STRING).
constexpr std::string_view kContestFinalName = "全球争霸赛总决赛";
constexpr std::string_view kContestFinalAlias = "全服争霸赛总决赛";
constexpr std::string_view kContestFinalLabel = "#{DLYHQF_12121302}";
constexpr std::string_view kContestFinalTip = "#{DLYHQF_12121308}";

// Chữ thưởng của máy chủ theo mức (g_ThreePrizeTip); mức 15 tới 18 và mức 0 không có chữ.
constexpr std::array<std::string_view, kPrizeLevels + 1> kPrizeTips = {"", "#{WJZH_100910_20}", "#{WJZH_100910_18}",
    "#{WJZH_100910_17}", "#{CLCZ_101207_03}", "#{CLCZ_101207_02}", "#{CLCZ_101207_01}", "#{KFZB_110628_205}",
    "#{KFZB_110628_206}", "#{KFZB_110628_207}", "#{KFZB_110628_208}", "#{KFZB_110628_251}", "#{WJZH_100910_19}",
    "#{WJZH_100910_18}", "#{WJZH_100910_17}", "", "", "", ""};

// Chữ nhà mạng trong ô chọn: bốn AddTextItem của OnLoad (电信, 网通, 教育网, 默认).
constexpr std::array<std::string_view, kLineCount> kLineNames = {
    "#{DLJM_XML_46}", "#{DLJM_XML_48}", "#{DLJM_XML_50}", "#{DLYHQF_12121344}"};

constexpr std::string_view kHelpDefault = "#{FWQWL_201130_01}";
constexpr std::string_view kHelpPicked = "#{FWQWL_201130_02}";
constexpr std::string_view kNewMark = "#{DLYHQF_12121324}";
constexpr std::string_view kServerWord = "#{DLYHQF_12121333}";
constexpr std::string_view kArenaMark = "#{GJHC_260424_18}";
constexpr std::string_view kNoLast = "无";

[[nodiscard]] constexpr std::size_t slot(BigArea big) noexcept {
    return std::to_underlying(big);
}

[[nodiscard]] const BigInfo& info_of(BigArea big) noexcept {
    return kBigInfo.at(slot(big));
}

[[nodiscard]] bool is_valid_big(std::size_t big) noexcept {
    return big > slot(BigArea::kRecommend) && big < kBigAreaSlots;
}

// Đại khu có nút ở cột trái: luôn hiện hoặc có ít nhất một vùng (điều kiện AddAllAreaButton).
[[nodiscard]] bool has_row(const SelectServer& panel, BigArea big) noexcept {
    return info_of(big).must_show || !panel.groups.at(slot(big)).empty();
}

[[nodiscard]] bool is_contest_final(const SelectServer& panel) {
    const std::vector<std::size_t>& group = panel.groups.at(slot(BigArea::kContest));
    if (group.empty()) return false;
    const std::string_view first = area_title(panel.directory.areas.at(group.front()).name);
    return first == kContestFinalName || first == kContestFinalAlias;
}

[[nodiscard]] std::string_view big_label(const SelectServer& panel, BigArea big) {
    if (big == BigArea::kContest && is_contest_final(panel)) return kContestFinalLabel;
    return info_of(big).name;
}

[[nodiscard]] std::string_view big_tip(const SelectServer& panel, BigArea big, bool is_opened) {
    if (big == BigArea::kContest && is_contest_final(panel)) return kContestFinalTip;
    return is_opened ? info_of(big).close_tip : info_of(big).open_tip;
}

[[nodiscard]] const LoginArea& area_of_sub(const SelectServer& panel, BigArea big, std::size_t sub) {
    return panel.directory.areas.at(panel.groups.at(slot(big)).at(sub));
}

[[nodiscard]] std::string_view sub_title(const SelectServer& panel, BigArea big, std::size_t sub) {
    if (big == BigArea::kContest && sub == 0 && is_contest_final(panel)) return kContestFinalName;
    return area_title(area_of_sub(panel, big, sub).name);
}

[[nodiscard]] bool is_sub_valid(const SelectServer& panel, BigArea big, std::size_t sub) {
    return sub < panel.groups.at(slot(big)).size();
}

// Vùng và vị trí vùng trong đại khu cho chỉ số vùng area của danh sách; từ đại khu 2 trở đi, theo
// thứ tự mà script duyệt.
struct SubFind {
    BigArea big = BigArea::kRecommend;
    std::size_t sub = 0;
};

[[nodiscard]] std::optional<SubFind> find_sub(const SelectServer& panel, std::size_t area) {
    for (std::size_t big = slot(BigArea::kContest); big < kBigAreaSlots; ++big) {
        const std::vector<std::size_t>& group = panel.groups.at(big);
        const auto found = std::ranges::find(group, area);
        if (found == group.end()) continue;
        return SubFind{.big = static_cast<BigArea>(big), .sub = static_cast<std::size_t>(found - group.begin())};
    }
    return std::nullopt;
}

// Dựng các nhóm vùng và các nút của cột trái (SelectServer_Data_GetAreaInfoAndRecommendServerInfo
// và SelectServer_AddAllAreaButton).
void build_rows(SelectServer& panel) {
    for (std::vector<std::size_t>& group : panel.groups) group.clear();
    for (std::size_t area = 0; area < panel.directory.areas.size(); ++area) {
        const std::optional<BigArea> big = big_area_of(panel.directory.areas.at(area).name);
        if (big) panel.groups.at(slot(*big)).push_back(area);
    }
    panel.rows.clear();
    for (std::size_t index = slot(BigArea::kRecommend); index < kBigAreaSlots; ++index) {
        const auto big = static_cast<BigArea>(index);
        if (!has_row(panel, big)) continue;
        panel.rows.push_back(AreaRow{.big = big, .sub = std::nullopt});
        if (!info_of(big).shows_list) continue;
        for (std::size_t sub = 0; sub < panel.groups.at(index).size(); ++sub) {
            panel.rows.push_back(AreaRow{.big = big, .sub = sub});
        }
    }
}

// SelectServer_Area_ClearAllStatus: bỏ chọn mọi nút đại khu, giấu và bỏ chọn mọi vùng con.
void clear_all_status(SelectServer& panel) noexcept {
    panel.big_selected.fill(false);
    panel.subs_shown.fill(false);
    panel.sub_selected.reset();
}

// SelectServer_Area_SubAreaButtonUpdate: hiện mọi vùng con của đại khu, chọn nút đại khu và chọn
// vùng con sub.
void sub_button_update(SelectServer& panel, BigArea big, std::size_t sub) {
    if (!is_valid_big(slot(big)) || !is_sub_valid(panel, big, sub)) return;
    panel.subs_shown.at(slot(big)) = true;
    panel.big_selected.at(slot(big)) = has_row(panel, big);
    panel.sub_selected = AreaRow{.big = big, .sub = sub};
}

// SelectServer_Area_BigAreaButtonUpdate. Nút đại khu có danh sách vùng con: đang mở thì đóng, đang
// đóng thì mở và hiện các vùng con chưa chọn; các đại khu khác chỉ được chọn.
void big_button_update(SelectServer& panel, BigArea big) {
    const bool was_opened = panel.opened.at(slot(big));
    panel.opened.fill(false);
    const bool lists = info_of(big).shows_list;
    if (!lists && has_row(panel, big)) panel.big_selected.at(slot(big)) = true;
    if (!lists) return;
    if (was_opened) {
        panel.big_selected.at(slot(big)) = false;
        return;
    }
    panel.opened.at(slot(big)) = true;
    panel.big_selected.at(slot(big)) = true;
    panel.subs_shown.at(slot(big)) = true;
    if (panel.sub_selected && panel.sub_selected->big == big) panel.sub_selected.reset();
}

// SelectServer_UI_ShowServerUI: trang máy chủ của một vùng hay kết quả tìm.
void show_server_ui(SelectServer& panel, ServerPage page) noexcept {
    panel.page = page;
}

// SelectServer_SelectAreaServer: bên phải hiện mọi máy chủ của vùng con sub. Máy chủ đang chọn bị bỏ.
void select_area_server(SelectServer& panel, BigArea big, std::size_t sub) {
    if (!is_valid_big(slot(big)) || !is_sub_valid(panel, big, sub)) return;
    panel.help.assign(kHelpDefault);
    panel.viewed_area = panel.groups.at(slot(big)).at(sub);
    panel.picked.reset();
    panel.title.assign("#e010101#gFF0FA0");
    panel.title.append(sub_title(panel, big, sub));
    show_server_ui(panel, ServerPage::kArea);
}

// SelectServer_SelectAreaButton: chọn nút ứng với vùng con (selected là dấu chọn của nút đại khu
// không có danh sách vùng con).
void select_area_button(SelectServer& panel, BigArea big, std::size_t sub, bool selected) {
    if (!is_valid_big(slot(big)) || !is_sub_valid(panel, big, sub)) return;
    clear_all_status(panel);
    if (!info_of(big).must_show) {
        if (has_row(panel, big)) panel.big_selected.at(slot(big)) = selected;
        return;
    }
    if (info_of(big).shows_list) sub_button_update(panel, big, sub);
}

// SelectServer_UI_ShowRecommendServerUI cộng SelectServer_Data_ShowRecommendServer: trang đề cử.
void show_recommend(SelectServer& panel) {
    panel.page = ServerPage::kRecommend;
    panel.picked.reset();
    panel.recommend = recommended(panel.directory);
}

// SelectServer_Area_BigAreaUpdate.
void big_area_update(SelectServer& panel, BigArea big) {
    panel.help.assign(kHelpDefault);
    if (big == BigArea::kRecommend) show_recommend(panel);
    if (!info_of(big).must_show && !panel.groups.at(slot(big)).empty()) select_area_server(panel, big, 0);
    if (info_of(big).shows_list && panel.opened.at(slot(big))) {
        sub_button_update(panel, big, 0);
        select_area_server(panel, big, 0);
    }
}

// SelectServerEvent_Area_SwitchPage cho nút phần tử row: bỏ mọi trạng thái, cập nhật nút rồi trang.
void switch_page(SelectServer& panel, std::size_t row_index) {
    if (row_index >= panel.rows.size()) return;
    const AreaRow row = panel.rows.at(row_index);
    clear_all_status(panel);
    if (row.sub) {
        sub_button_update(panel, row.big, *row.sub);
        select_area_server(panel, row.big, *row.sub);
        return;
    }
    big_button_update(panel, row.big);
    big_area_update(panel, row.big);
}

[[nodiscard]] const LoginServer* server_of(const SelectServer& panel, ServerRef ref) noexcept {
    return server_at(panel.directory, ref);
}

// Nút của máy chủ bấm được: trạng thái 0 tới 3 (đầy, bận, tốt, rất tốt). Bảo trì và trạng thái ẩn
// làm nút xám và khoá.
[[nodiscard]] bool is_open(const LoginServer& server) noexcept {
    return server.status <= kStatusBest;
}

// Chữ của nút máy chủ: tên (kèm "(mới)" nếu có) bọc trong màu theo trạng thái.
[[nodiscard]] std::string coloured(const LoginServer& server, std::string_view name) {
    std::string_view colour = "#c959595";
    if (server.status == kStatusFull) colour = "#cff0000";
    if (server.status == kStatusBusy) colour = "#cff8a00";
    if (server.status == kStatusGood) colour = "#cECE58D";
    if (server.status == kStatusBest) colour = "#c4CFA4C";
    std::string text(colour);
    text.append("#e010101");
    text.append(name);
    if (server.is_new) text.append(kNewMark);
    text.append("#cffffff");
    return text;
}

// Dòng ở thanh thông tin khi trỏ vào máy chủ: chữ thưởng nếu có, không thì "tên máy chủ" kèm dấu
// Vũ Thần Đàn.
[[nodiscard]] std::string server_hint(const LoginServer& server) {
    const std::string_view tip = kPrizeTips.at(std::min<std::size_t>(server.prize, kPrizeLevels));
    if (!tip.empty()) return std::string(tip);
    std::string text = server.name;
    text.append(kServerWord);
    if (server.has_arena) text.append(kArenaMark);
    return text;
}

// Dòng hướng dẫn sau khi chọn máy chủ: mẫu "#{FWQWL_201130_02}" điền tên, kèm dấu Vũ Thần Đàn.
void set_picked_help(SelectServer& panel, const LoginServer& server, const gui::StringBook* words) {
    panel.help.clear();
    if (words == nullptr) return;
    const std::array<std::string_view, 1> slots = {std::string_view(server.name)};
    format_key(panel.help, *words, kHelpPicked, slots);
    if (server.has_arena) panel.help.append(kArenaMark);
}

// Máy chủ ở trang kết quả tìm, nút thứ index (từ 0) của trang search_page.
[[nodiscard]] std::optional<ServerRef> found_at(const SelectServer& panel, std::size_t index) {
    if (panel.search_page == 0) return std::nullopt;
    const std::size_t at = ((panel.search_page - 1) * kSearchPageSize) + index;
    if (at >= panel.found.size()) return std::nullopt;
    return panel.found.at(at);
}

// Máy chủ mà nút thứ index (từ 0) của trang bên phải hiện, theo trang đang xem.
[[nodiscard]] std::optional<ServerRef> button_ref(const SelectServer& panel, std::size_t index) {
    if (panel.page == ServerPage::kRecommend) {
        if (index >= panel.recommend.size()) return std::nullopt;
        return panel.recommend.at(index);
    }
    if (panel.page == ServerPage::kSearch) return found_at(panel, index);
    if (!panel.viewed_area) return std::nullopt;
    const ServerRef ref{.area = *panel.viewed_area, .server = index};
    return server_of(panel, ref) == nullptr ? std::nullopt : std::optional<ServerRef>(ref);
}

// Số nút máy chủ hiện ở trang kArea hay kSearch: số máy chủ của vùng, hay số kết quả của trang.
[[nodiscard]] std::size_t button_count(const SelectServer& panel) {
    if (panel.page == ServerPage::kArea) {
        if (!panel.viewed_area) return 0;
        return std::min(panel.directory.areas.at(*panel.viewed_area).servers.size(), kServersPerArea);
    }
    if (panel.page != ServerPage::kSearch || panel.search_page == 0) return 0;
    const std::size_t begin = (panel.search_page - 1) * kSearchPageSize;
    if (begin >= panel.found.size()) return 0;
    if (panel.found.size() == kServersPerArea) return kServersPerArea;
    return std::min(panel.found.size() - begin, kSearchPageSize);
}

// Số trang kết quả tìm: 1 khi đúng 85 kết quả, không thì làm tròn lên của số kết quả chia 84.
[[nodiscard]] std::size_t search_pages(const SelectServer& panel) noexcept {
    const std::size_t count = panel.found.size();
    if (count == kServersPerArea) return 1;
    return (count + kSearchPageSize - 1) / kSearchPageSize;
}

// SelectServer_Data_ShowSearchServer: hiện trang page của kết quả tìm; trang ngoài khoảng thì bỏ.
void show_search_page(SelectServer& panel, std::size_t page) {
    panel.picked_mark.reset();
    if (page < 1 || page > search_pages(panel)) return;
    if ((page - 1) * kSearchPageSize >= panel.found.size()) return;
    panel.search_page = page;
}

// Chữ ô tìm bỏ khoảng trắng hai đầu (string.gsub(text, "^%s*(.-)%s*$", "%1")).
[[nodiscard]] std::string trimmed(std::string_view text) {
    constexpr std::string_view kBlank = " \t\r\n\f\v";
    const std::size_t first = text.find_first_not_of(kBlank);
    if (first == std::string_view::npos) return {};
    return std::string(text.substr(first, text.find_last_not_of(kBlank) - first + 1));
}

// SelectServerEvent_Search_OK: tìm theo chữ trong ô.
void run_search(SelectServer& panel) {
    panel.search = trimmed(panel.search);
    if (panel.search.empty()) return;
    clear_all_status(panel);
    panel.found = search(panel.directory, panel.search);
    show_server_ui(panel, ServerPage::kSearch);
    panel.search_page = 0;
    panel.title.assign(panel.found.empty() ? "#{DLYHQF_12121317}" : "#{DLYHQF_12121316}");
    show_search_page(panel, 1);
}

// SelectServerEvent_ServerBn_Clicked: chọn máy chủ ở nút thứ index (từ 0) của trang bên phải.
void click_server(SelectServer& panel, std::size_t index, const gui::StringBook* words) {
    const std::optional<ServerRef> ref = button_ref(panel, index);
    if (!ref) return;
    const LoginServer* server = server_of(panel, *ref);
    if (server == nullptr || !is_open(*server)) return;
    const std::optional<ServerRef> before = panel.picked;
    panel.picked = ref;
    panel.picked_mark = ref;
    if (panel.page != ServerPage::kSearch) panel.is_last_checked = panel.last == ref;
    if (before != panel.picked) set_picked_help(panel, *server, words);
    if (panel.page != ServerPage::kSearch) return;
    const std::optional<SubFind> sub = find_sub(panel, ref->area);
    if (sub) select_area_button(panel, sub->big, sub->sub, false);
}

// SelectServerEvent_RecommendBn_Cliecked: chọn máy chủ ở nút đề cử thứ index (từ 0), rồi tô vùng
// của nó ở cột trái (không đổi trang bên phải).
void click_recommend(SelectServer& panel, std::size_t index) {
    if (index >= panel.recommend.size()) return;
    const ServerRef ref = panel.recommend.at(index);
    const LoginServer* server = server_of(panel, ref);
    if (server == nullptr || !is_open(*server)) return;
    panel.picked = ref;
    panel.picked_mark = ref;
    const std::optional<SubFind> sub = find_sub(panel, ref.area);
    if (sub) select_area_button(panel, sub->big, sub->sub, false);
}

// SelectServerEvent_LastServer_Cliecked: về vùng của lần đăng nhập trước và chọn máy chủ ấy.
void click_last(SelectServer& panel, const gui::StringBook* words) {
    if (!panel.last) return;
    const std::optional<SubFind> sub = find_sub(panel, panel.last->area);
    if (!sub) return;
    select_area_button(panel, sub->big, sub->sub, true);
    select_area_server(panel, sub->big, sub->sub);
    click_server(panel, panel.last->server, words);
}

// SelectServerEvent_SelectOk: máy chủ đang chọn; chưa chọn thì lấy lần đăng nhập trước nếu nó không
// đang bảo trì. Không có máy chủ nào thì nhờ báo "phải chọn một máy chủ" (MUST_SELECTSERVER).
void accept(SelectServer& panel) {
    std::optional<ServerRef> target = panel.picked;
    if (!target && panel.last) {
        const LoginServer* server = server_of(panel, *panel.last);
        if (server != nullptr && server->status != kStatusStop) target = panel.last;
    }
    if (!target) {
        panel.request = ServerRequest{.work = ServerWork::kMustPick, .server = {}};
        return;
    }
    panel.request = ServerRequest{.work = ServerWork::kEnter, .server = *target};
}

constexpr std::string_view kServerPrefix = "SelectServer_Server";
constexpr std::string_view kRecommendPrefix = "SelectServer_Commendable_Subarea";

void press_server_button(SelectServer& panel, const ServerPress& press) {
    const std::string_view window = press.window;
    if (window == kAccept) accept(panel);
    if (window == kRegister) panel.request = ServerRequest{.work = ServerWork::kOpenRegister, .server = {}};
    if (window == kCharge) panel.request = ServerRequest{.work = ServerWork::kOpenTopUp, .server = {}};
    if (window == kCancel) panel.request = ServerRequest{.work = ServerWork::kLeave, .server = {}};
    if (window == kSearchOk) run_search(panel);
    if (window == kUpPage && panel.search_page > 1) show_search_page(panel, panel.search_page - 1);
    if (window == kDownPage && panel.search_page > 0) show_search_page(panel, panel.search_page + 1);
    if (window == kLastButton) {
        click_last(panel, press.words);
        if (press.is_double) accept(panel);
    }
}

// Chữ ở thanh thông tin khi chuột đứng trên một cửa sổ: MouseEnter của từng nút trong script.
[[nodiscard]] std::string hint_of(const SelectServer& panel, std::string_view window, std::optional<std::size_t> element) {
    if (window == kServerAreaList && element && *element < panel.rows.size()) {
        const AreaRow& row = panel.rows.at(*element);
        if (row.sub) return area_of_sub(panel, row.big, *row.sub).tip;
        return std::string(big_tip(panel, row.big, panel.opened.at(slot(row.big))));
    }
    if (window == kAccept) return "#{DLYHQF_12121338}";
    if (window == kRegister) return "#{DLYHQF_12121335}";
    if (window == kCharge) return "#{DLYHQF_12121334}";
    if (window == kCancel) return "#{DLYHQF_12121337}";
    if (window == kBack) return "#{DLYHQF_12121336}";
    if (window == kRoleInquiry) return "#{DLYHQF_12121319}";
    if (window == kLastButton && panel.last) {
        const LoginServer* server = server_of(panel, *panel.last);
        return server == nullptr ? std::string() : server_hint(*server);
    }
    const std::optional<std::size_t> recommend = ordinal_of(window, kRecommendPrefix, kRecommendCap);
    const std::optional<std::size_t> number = recommend ? recommend : ordinal_of(window, kServerPrefix, kServersPerArea);
    if (!number) return {};
    if (recommend.has_value() != (panel.page == ServerPage::kRecommend)) return {};
    const std::optional<ServerRef> ref = button_ref(panel, *number - 1);
    const LoginServer* server = ref ? server_of(panel, *ref) : nullptr;
    return server == nullptr ? std::string() : server_hint(*server);
}

constexpr std::string_view kTrue = "True";
constexpr std::string_view kFalse = "False";

[[nodiscard]] constexpr std::string_view flag(bool is_set) noexcept {
    return is_set ? kTrue : kFalse;
}

void set_text(Deck& deck, std::string_view window, std::string_view text) {
    deck.set(gui::Override{.window = window, .name = "Text", .value = text});
}

void hide_unless(Deck& deck, std::string_view window, bool is_shown) {
    if (!is_shown) deck.hide(window);
}

// Một bản ghi của cột trái: khoá, cờ, section sáng và chữ (gui/content.hpp).
void add_record(std::string& blob, std::string_view key, std::string_view flags, std::string_view text) {
    if (!blob.empty()) blob.push_back(gui::kRecordMark);
    blob.append(key);
    blob.push_back(gui::kFieldMark);
    blob.append(flags);
    blob.push_back(gui::kFieldMark);
    blob.append(kHoverSection);
    blob.push_back(gui::kFieldMark);
    blob.append(text);
}

// SelectServer_AddBigArea và SelectServer_AddSubArea: các nút của cột vùng bên trái.
void paint_area_list(Deck& deck, const SelectServer& panel) {
    std::string& blob = deck.compose(Key{.window = kServerAreaList, .name = gui::kElementsProperty});
    for (const AreaRow& row : panel.rows) {
        if (!row.sub) {
            const bool is_selected = panel.big_selected.at(slot(row.big));
            add_record(blob, kCatalogKey, is_selected ? "s" : "", big_label(panel, row.big));
            continue;
        }
        std::string flags;
        if (!panel.subs_shown.at(slot(row.big))) flags.push_back(gui::kHiddenFlag);
        if (panel.sub_selected == row) flags.push_back(gui::kSelectedFlag);
        const LoginArea& area = area_of_sub(panel, row.big, *row.sub);
        std::string text(area.recommend > 0 ? "#-50" : "    ");
        text.append("#e010101#gFF0FA0");
        text.append(sub_title(panel, row.big, *row.sub));
        add_record(blob, kTextKey, flags, text);
    }
}

// Một nút máy chủ: chữ có màu theo trạng thái, khoá khi bảo trì, dấu chọn và dấu Vũ Thần Đàn.
struct ServerButton {
    std::string_view window;
    std::string_view image;
    std::optional<ServerRef> ref;
    std::string_view name;
};

void paint_server_button(Deck& deck, const SelectServer& panel, const ServerButton& button) {
    const LoginServer* server = button.ref ? server_of(panel, *button.ref) : nullptr;
    if (server == nullptr) {
        deck.hide(button.window);
        return;
    }
    set_text(deck, button.window, coloured(*server, button.name));
    deck.set(gui::Override{.window = button.window, .name = "Disabled", .value = flag(!is_open(*server))});
    deck.set(gui::Override{.window = button.window, .name = "Selected", .value = flag(panel.picked_mark == button.ref)});
    if (server->has_arena) deck.reveal(button.image);
}

// Nút máy chủ trang đề cử: "vùng-máy chủ".
void paint_recommend(Deck& deck, const SelectServer& panel) {
    std::string name;
    for (std::size_t index = 0; index < kRecommendCap; ++index) {
        ServerButton button{.window = kRecommendButtons.at(index), .image = kRecommendImages.at(index), .ref = {}, .name = {}};
        const bool is_used = panel.page == ServerPage::kRecommend && index < panel.recommend.size();
        if (is_used) {
            button.ref = panel.recommend.at(index);
            const LoginArea& area = panel.directory.areas.at(button.ref->area);
            name.assign(recommend_label(area.name));
            name.push_back('-');
            name.append(panel.directory.areas.at(button.ref->area).servers.at(button.ref->server).name);
            button.name = name;
        }
        paint_server_button(deck, panel, button);
    }
}

// Nút máy chủ của trang vùng hay trang tìm.
void paint_servers(Deck& deck, const SelectServer& panel) {
    const std::size_t count = panel.page == ServerPage::kRecommend ? 0 : button_count(panel);
    for (std::size_t index = 0; index < kServersPerArea; ++index) {
        ServerButton button{.window = kServerButtons.at(index), .image = kServerImages.at(index), .ref = {}, .name = {}};
        if (index < count) button.ref = button_ref(panel, index);
        const LoginServer* server = button.ref ? server_of(panel, *button.ref) : nullptr;
        if (server != nullptr) button.name = server->name;
        paint_server_button(deck, panel, button);
    }
}

// Nút lần đăng nhập trước: tên máy chủ, hoặc "无" và khoá khi chưa có hay đang bảo trì.
void paint_last(Deck& deck, const SelectServer& panel) {
    const LoginServer* server = panel.last ? server_of(panel, *panel.last) : nullptr;
    set_text(deck, kLastButton, server == nullptr ? kNoLast : std::string_view(server->name));
    const bool is_usable = server != nullptr && server->status != kStatusStop;
    deck.set(gui::Override{.window = kLastButton, .name = "Disabled", .value = flag(!is_usable)});
    deck.set(gui::Override{.window = kLastButton, .name = "Selected", .value = flag(is_usable && panel.is_last_checked)});
    if (server != nullptr && server->has_arena) deck.reveal(kLastImage);
}

// Hai nút trang trước và trang sau của kết quả tìm: chỉ hiện khi kết quả nhiều hơn một trang.
void paint_paging(Deck& deck, const SelectServer& panel) {
    const bool is_shown = panel.page == ServerPage::kSearch && panel.found.size() > kServersPerArea;
    hide_unless(deck, kUpPage, is_shown);
    hide_unless(deck, kDownPage, is_shown);
    if (!is_shown) return;
    deck.set(gui::Override{.window = kUpPage, .name = "Disabled", .value = flag(panel.search_page <= 1)});
    deck.set(gui::Override{.window = kDownPage, .name = "Disabled", .value = flag(panel.search_page >= search_pages(panel))});
}

} // namespace

void open_servers(SelectServer& panel, ServerDirectory directory, std::optional<ServerRef> last,
    std::optional<ServerRef> back) {
    panel = SelectServer{};
    panel.directory = std::move(directory);
    build_rows(panel);
    switch_page(panel, 0);
    if (last && find_sub(panel, last->area) && server_of(panel, *last) != nullptr) panel.last = last;
    if (panel.last) panel.is_last_checked = server_of(panel, *panel.last)->status != kStatusStop;
    if (!back) return;
    const std::optional<SubFind> sub = find_sub(panel, back->area);
    if (!sub) return;
    select_area_button(panel, sub->big, sub->sub, true);
    select_area_server(panel, sub->big, sub->sub);
    click_server(panel, back->server, nullptr);
}

void press_server(SelectServer& panel, const ServerPress& press) {
    panel.is_search_focused = press.window == kServerSearchBox;
    if (press.window == kServerAreaList) {
        if (press.element) switch_page(panel, *press.element);
        return;
    }
    press_server_button(panel, press);
    if (const std::optional<std::size_t> number = ordinal_of(press.window, kServerPrefix, kServersPerArea)) {
        click_server(panel, *number - 1, press.words);
        if (press.is_double) accept(panel);
    }
    if (const std::optional<std::size_t> number = ordinal_of(press.window, kRecommendPrefix, kRecommendCap)) {
        click_recommend(panel, *number - 1);
        if (press.is_double) accept(panel);
    }
}

void hover_server(SelectServer& panel, std::string_view window, std::optional<std::size_t> element) {
    panel.info = hint_of(panel, window, element);
}

void type_server(SelectServer& panel, char32_t code) {
    if (!panel.is_search_focused) return;
    if (code == kEnter) run_search(panel);
    if (code == kBackspace) pop_code_point(panel.search);
    const bool is_surrogate = code >= 0xD800 && code <= 0xDFFF;
    const bool is_printable = code >= U' ' && code != 0x7F && !is_surrogate && code <= 0xFFFF;
    if (is_printable && code_points(panel.search) < kSearchLimit) append_utf8(panel.search, code);
}

std::optional<ServerRequest> take_server_request(SelectServer& panel) noexcept {
    return std::exchange(panel.request, std::nullopt);
}

void paint_server(Deck& deck, const SelectServer& panel) {
    deck.show(kRoot);
    deck.hide(kWeGameCancel);
    deck.hide(kFluencyFrame);
    hide_unless(deck, kRecommendFrame, panel.page == ServerPage::kRecommend);
    hide_unless(deck, kAreaFrame, panel.page != ServerPage::kRecommend);
    paint_area_list(deck, panel);
    paint_recommend(deck, panel);
    paint_servers(deck, panel);
    paint_last(deck, panel);
    paint_paging(deck, panel);
    set_text(deck, kTitle, panel.title);
    set_text(deck, kHelp, panel.help);
    set_text(deck, kInfo, panel.info);
    set_text(deck, kServerSearchBox, panel.search);
    deck.set(gui::Override{.window = kServerSearchBox, .name = "Caret", .value = flag(panel.is_search_focused)});
    // Combobox: chữ đã chọn nằm ở ô nhập con; danh sách thả chưa mở được nên luôn giấu.
    set_text(deck, kLineEdit, kLineNames.at(std::min(panel.line, kLineCount - 1)));
    deck.hide(kLineList);
}

} // namespace game::ui::panel
