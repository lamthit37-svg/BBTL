/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/hud.cpp
 *  PHÂN HỆ   : Face / Ui / Hud
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - HUD của client: nạp layout, dựng bảng port tay (ui/panel) và bảng chạy
 *    bằng script Lua, rồi kê vào deck để vẽ.
 *  - Nhận chuột, bàn phím và tin hội thoại NPC từ Display; trả lại việc người
 *    chơi nhờ máy chủ.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "ui/hud.hpp"

#include "core/error.hpp"
#include "gpu/command.hpp"
#include "gui/loader.hpp"
#include "gui/scroll.hpp"
#include "gui/sheet.hpp"
#include "gui/strings.hpp"
#include "io/file.hpp"
#include "render/ui.hpp"
#include "resource/image.hpp"
#include "table/localize.hpp"
#include "table/tsv.hpp"
#include "ui/pace.hpp"
#include "ui/painter.hpp"
#include "ui/panel/action_bar.hpp"
#include "ui/panel/action_bars.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/call_events.hpp"
#include "ui/panel/can_do.hpp"
#include "ui/panel/create_role.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/desk.hpp"
#include "ui/panel/events.hpp"
#include "ui/panel/login_flow.hpp"
#include "ui/panel/logon.hpp"
#include "ui/panel/main_menu_bar_3.hpp"
#include "ui/panel/maps.hpp"
#include "ui/panel/menubar.hpp"
#include "ui/panel/minimap.hpp"
#include "ui/panel/npc_talk.hpp"
#include "ui/panel/online.hpp"
#include "ui/panel/packet.hpp"
#include "ui/panel/player_frame.hpp"
#include "ui/panel/portraits.hpp"
#include "ui/panel/quest_book.hpp"
#include "ui/panel/quest_log.hpp"
#include "ui/panel/relive.hpp"
#include "ui/panel/role_cast.hpp"
#include "ui/panel/role_pose.hpp"
#include "ui/panel/roles.hpp"
#include "ui/panel/scene_board.hpp"
#include "ui/panel/scene_table.hpp"
#include "ui/panel/select_role.hpp"
#include "ui/panel/select_server.hpp"
#include "ui/panel/self_equip.hpp"
#include "ui/panel/skill_bar.hpp"
#include "ui/panel/softkey.hpp"
#include "ui/panel/start.hpp"
#include "ui/panel/system_info.hpp"
#include "ui/panel/talk.hpp"
#include "ui/panel/target_frame.hpp"
#include "ui/panel/world_map.hpp"
#include "ui/radar.hpp"
#include "ui/script/context.hpp"
#include "ui/script/gui_screen.hpp"
#include "ui/script/host.hpp"
#include "ui/script/natives.hpp"
#include "ui/script/windows.hpp"
#include "ui/script/xscript.hpp"
#include "ui/text.hpp"
#include "ui/view.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <expected>
#include <filesystem>
#include <format>
#include <future>
#include <limits>
#include <memory>
#include <optional>
#include <print>
#include <set>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <variant>
#include <vector>

namespace game::ui {
namespace {

// Layout của HUD, của ba bảng mở từ thanh menu chính, của các bảng đăng nhập (chọn máy chủ, tài khoản,
// chọn và tạo nhân vật) và bàn phím ảo của chúng
// (đường dẫn tương đối với Interface).
constexpr std::array<std::string_view, 44> kLayouts = {
    "PlayerFrame/PlayerFrame.layout.xml",
    "TargetFrame/TargetFrame.layout.xml",
    "Relive/Relive.layout.xml",
    "MiniMap/MiniMap.layout.xml",
    "MainMenuBar/MainMenuBar.layout.xml",
    "MainMenuBar_2/MainMenuBar_2.layout.xml",
    "MainMenuBar_3/MainMenuBar_3.layout.xml",
    "MainMenuBar_4/MainMenuBar_4.layout.xml",
    "ChatFrame/ChatFrame.layout.xml",
    "PlayerImpactFrame/PlayerImpactFrame.layout.xml",
    "AutoAttack_Button/AutoAttack_Button.layout.xml",
    "FunctionBarRight/FunctionBarRight.layout.xml",
    "FunctionBarRight_2/FunctionBarRight_2.layout.xml",
    "ProgressBar/ProgressBar.layout.xml",
    "SelfEquip/SelfEquip.layout.xml",
    "Packet/Packet.layout.xml",
    "QuestLog/QuestLog.layout.xml",
    "MissionTrack/MissionTrack.layout.xml",
    "Quest/Quest.layout.xml",
    "YuanbaoShop/YuanbaoShop.layout.xml",
    "Operation/Operation.layout.xml",
    "ViewSetup/ViewSetup.layout.xml",
    "SoundSetup/SoundSetup.layout.xml",
    "GameSetup/GameSetup.layout.xml",
    "AcceSetup/AcceSetup.layout.xml",
    "ActionSkill/ActionSkill.layout.xml",
    "CommonSkill/CommonSkill.layout.xml",
    "LifeSkill/LifeSkill.layout.xml",
    "ZhenfaSkill/ZhenfaSkill.layout.xml",
    "AutoAttackSkill/AutoAttackSkill.layout.xml",
    "ZongMenSkill/ZongMenSkill.layout.xml",
    "Pet/Pet.layout.xml",
    "Friend/Friend.layout.xml",
    "TeamFrame/TeamFrame.layout.xml",
    "DebugListBox/DebugListBox.layout.xml",
    "SceneMap/SceneMap.layout.xml",
    "LargeMap/LargeMap.layout.xml",
    panel::kServerLayout,
    panel::kSystemInfoLayout,
    panel::kLogonLayout,
    panel::kSelectLayout,
    panel::kCreateLayout,
    panel::kSoftKeysLayout,
    "SceneTrans/SceneTrans.layout.xml",
};

// Cửa sổ chạy bằng script Lua gốc của client 2026 qua ui/script (docs/giao-viec/LUA-GEN/HOST.md). Cửa sổ khác còn là bảng
// port tay (ui/panel) cho tới khi hàm game mà script của nó gọi (tầng B) có đủ; hết bảng port tay thì danh sách này bỏ và host
// chạy cả sổ.
constexpr std::array<std::string_view, 4> kScripted = {
    "ProgressBar", "DebugListBox", "SceneTrans", "SoftKeyBoard"};

// Tên trong sổ (Script/windows.tsv) của bàn phím ảo đăng nhập.
constexpr std::string_view kSoftKeyBoard = "SoftKeyBoard";

// Trần số sự kiện giao diện xử lý mỗi khung, kể cả sự kiện do các bảng tự đẩy (xem Hud::State::step_panels và EventQueue:
// gốc không có trần, đây là chốt an toàn).
constexpr std::size_t kMaxPanelEvents = 256;

// Bảng chuyển cảnh đã hiện thì ở lại ít nhất chừng này (xem Hud::State::note_loading).
constexpr std::chrono::milliseconds kTransShown{900};

// Nhấn đúp (MouseDoubleClick của CEGUI): lần nhấn thứ hai trên cùng cửa sổ trong chừng này và trong
// ô vuông 12 điểm ảnh quanh lần nhấn trước (System::DefaultMultiClickTimeout 0,33 giây và
// DefaultMultiClickAreaSize 12x12 của CEGUI 0.4.1; chưa đối chiếu với mã máy 2026).
// Khác gốc: chưa đo hằng của client 2026.
constexpr std::chrono::milliseconds kDoubleClick{330};

// Hai nút xoay người mẫu của bảng nhân vật và tốc độ xoay: SelfEquip_Modle_TurnLeft và TurnRight gọi
// RotateBeginEx("Player", ∓0,3), bản thân RotateBeginEx của UI_CEGUI.dll nhân đối số với 0,5 (0x180032e51)
// trước khi đưa cho engine.
constexpr std::string_view kEquipTurnLeft = "SelfEquip_Model_TurnLeft";
constexpr std::string_view kEquipTurnRight = "SelfEquip_Model_TurnRight";
constexpr float kEquipSpin = 0.3F * 0.5F;

// Một cú nhấp trái lên bản đồ lớn không được kéo chuột đi xa hơn chừng này (điểm ảnh).
constexpr float kClickReach = 5.0F;
// Atlas bản đồ lớn: texture 2048 x 2048 (8 ô nguyên), thu nhỏ tối đa 4 lần; ảnh gốc 4 điểm ảnh một đơn vị cảnh;
// số ô giữ lại trong bộ đệm giải mã.
constexpr int kBoardAtlasTiles = 8;
constexpr int kBoardMaxShrink = 4;
constexpr float kRadarSourcePixels = 4.0F;
constexpr std::size_t kBoardKeptTiles = 8;
constexpr float kDoubleReach = 6.0F;

// Phông bitmap đầu của SongTiBmp12 trong scheme gốc: GBK12, trang 936. VTNAM14 để khi làm tiếng Việt.
constexpr std::string_view kFontFile = "Schema/GBK12.bin";
// Phông Việt (Tahoma 14 của dòng CodePage 1258): chữ có dấu mà GBK12 không có (tên cảnh, chuỗi i18n).
constexpr std::string_view kViFontFile = "Schema/VTNAM14.bin";

// Cỡ cửa sổ nhỏ nhất của client 2026 là 800 x 600 (hàm đặt độ phân giải của Game.exe, docs/TIEN-DO.md "Khung chơi trên PC"); bảng
// đăng nhập cần cao khoảng 620 điểm ảnh (đo trên LDPlayer 960 x 540: ở 600 hàng nút dưới cùng bị cắt) nên khung ảo cao 640. Bản
// gốc không co giao diện (Imageset::notifyDisplaySizeChanged đặt hệ số co 1,0): PC có mật độ 1 nên từ cỡ này trở lên mọi điểm
// ảnh là 1:1, ảnh và chữ bitmap sắc nét. Màn mật độ cao (iPad Retina, tablet 320 dpi) phóng theo mật độ để giữ cỡ vật lý, như
// Constant Physical Size của Unity. Màn nhỏ hơn khung ảo (LDPlayer 960 x 540, điện thoại) co cho vừa thay vì cắt bảng.
constexpr float kLayoutWidth = 800.0F;
constexpr float kLayoutHeight = 640.0F;

// Đầu vào của khung đổi từ điểm ảnh của màn sang điểm ảnh của layout: cỡ và con trỏ chia cho scale.
[[nodiscard]] HudView layout_view(const HudView& view, float scale) {
    HudView local = view;
    local.width = view.width / scale;
    local.height = view.height / scale;
    if (local.pointer) {
        local.pointer->x /= scale;
        local.pointer->y /= scale;
    }
    return local;
}

// Nạp mọi layout của HUD; lỗi đầu tiên được giữ lại.
std::expected<void, std::string> add_layouts(gui::GuiLoader& loader) {
    std::expected<void, std::string> status;
    for (const std::string_view layout : kLayouts) {
        status = status ? loader.add_layout(layout) : status;
    }
    return status;
}

// Dịch ô của bảng đã đọc theo tệp bản dịch cạnh nó (<bảng>.lang.tsv, table/localize.hpp). Không có
// tệp bản dịch thì bảng giữ chữ gốc; bản dịch hỏng thì ghi một dòng và cũng giữ chữ gốc.
void localize_table(table::Tsv& table, const std::filesystem::path& file) {
    const std::string name = table::lang_name(io::utf8_of(file.filename()));
    if (name.empty()) return;
    const std::filesystem::path lang_file = file.parent_path() / std::filesystem::path(name);
    std::error_code missing;
    if (!std::filesystem::is_regular_file(lang_file, missing)) return;
    const io::TextResult text = io::read_text(lang_file);
    if (!text) {
        std::println(stderr, "Giao diện: không đọc được bản dịch {}", io::utf8_of(lang_file));
        return;
    }
    const table::TsvResult lang = table::parse_tsv(*text);
    const table::LocalizeResult done =
        lang ? table::localize(table, *lang) : table::LocalizeResult(std::unexpected(lang.error()));
    if (!done) {
        std::println(stderr, "Giao diện: bỏ bản dịch hỏng {}: {}", io::utf8_of(lang_file), done.error());
    } else if (done->missed > 0) {
        std::println(stderr, "Giao diện: {} có {} ô dịch không khớp bảng", io::utf8_of(lang_file), done->missed);
    }
}

// Đọc một bảng của thư mục Table; thiếu tệp hay hỏng thì ghi một dòng và trả nullopt. Ô có bản dịch
// (<bảng>.lang.tsv) mang chữ dịch.
std::optional<table::Tsv> read_table(const std::filesystem::path& file) {
    const io::TextResult text = io::read_text(file);
    if (!text) {
        std::println(stderr, "Giao diện: không có bảng {}", io::utf8_of(file));
        return std::nullopt;
    }
    table::TsvResult table = table::parse_tsv(*text);
    if (!table) {
        std::println(stderr, "Giao diện: bảng hỏng: {}", table.error());
        return std::nullopt;
    }
    localize_table(*table, file);
    return std::move(*table);
}

// Nạp đè một bảng chuỗi vào book; không đọc được thì book giữ nguyên.
void add_strings(gui::StringBook& book, const std::filesystem::path& file) {
    const std::optional<table::Tsv> table = read_table(file);
    if (table) book.overlay(*table);
}

// Con trỏ tới bảng đã đọc; nullptr khi không đọc được.
const table::Tsv* table_of(const std::optional<table::Tsv>& table) noexcept {
    return table ? &*table : nullptr;
}

// Dữ liệu của màn tạo nhân vật: ảnh chân dung (bảng đã đọc cho khung nhân vật), kiểu mặt, kiểu
// tóc và bộ đồ tân thủ. Bảng nào không đọc được thì phần đó rỗng.
panel::RoleCast cast_of(const std::filesystem::path& data_root, const std::optional<table::Tsv>& portraits) {
    const std::filesystem::path folder = data_root / "Table";
    const std::optional<table::Tsv> faces = read_table(folder / "faces.tsv");
    const std::optional<table::Tsv> hairs = read_table(folder / "hairs.tsv");
    const std::optional<table::Tsv> outfits = read_table(folder / "newbie_outfits.tsv");
    panel::CastTables tables;
    tables.portraits = table_of(portraits);
    tables.faces = table_of(faces);
    tables.hairs = table_of(hairs);
    tables.outfits = table_of(outfits);
    panel::RoleCast cast = panel::RoleCast::from_tables(tables);
    if (cast.skipped() != 0) std::println(stderr, "Giao diện: bảng tạo nhân vật bỏ {} dòng hỏng", cast.skipped());
    return cast;
}

// Tên fake object của đầu người chơi nếu nơi vẽ đã dựng ảnh của nó; rỗng thì chưa có.
std::string_view head_model(std::span<const ViewPaint> views) noexcept {
    const auto is_head = [](const ViewPaint& view) { return view.name == panel::kPlayerHead; };
    const auto found = std::ranges::find_if(views, is_head);
    return found == views.end() ? std::string_view{} : found->name;
}

// Ảnh minimap của hai khung liền nhau có cùng texture và cùng phép đổi toạ độ không.
bool same_map(const std::optional<MapPaint>& left, const std::optional<MapPaint>& right) noexcept {
    if (left.has_value() != right.has_value()) return false;
    if (!left) return true;
    const bool is_same_u = left->origin_u == right->origin_u && left->scale_u == right->scale_u;
    const bool is_same_v = left->origin_v == right->origin_v && left->scale_v == right->scale_v;
    return left->texture == right->texture && is_same_u && is_same_v;
}

// Điểm (across, down) có nằm trong ô box không; mép phải và mép dưới không tính.
[[nodiscard]] bool holds(const gui::Box& box, float across, float down) noexcept {
    return across >= box.x && across < box.x + box.w && down >= box.y && down < box.y + box.h;
}

} // namespace

// Bảng chuỗi gốc rồi lớp phủ Table/ui_strings.lang.tsv. Khoá không có trong bản dịch giữ chữ gốc.
gui::StringBook strings_of(const std::filesystem::path& data_root) {
    gui::StringBook book;
    add_strings(book, data_root / "Table" / "ui_strings.tsv");
    add_strings(book, data_root / "Table" / "ui_strings.lang.tsv");
    return book;
}

std::optional<table::Tsv> read_localized_table(const std::filesystem::path& file) {
    return read_table(file);
}

gui::StringBook scene_names(const std::filesystem::path& data_root) {
    gui::StringBook book;
    add_strings(book, data_root / "Table" / "scene_names.lang.tsv");
    return book;
}

namespace {

// Mọi thứ Hud::open đọc từ đĩa mà không cần thiết bị GPU. Dựng ở luồng riêng (HudPrep), State nhận bằng move.
struct Prepared {
    explicit Prepared(gui::GuiLoader opened) : loader(std::move(opened)) {}

    gui::GuiLoader loader;
    gui::StringBook strings;
    gui::StringBook scene_names;
    panel::Portraits portraits;
    panel::RoleCast cast;
    panel::SceneTable scenes;
    std::string world_cities;
    panel::LoginFlow flow;
    panel::QuestBook quests;
    // Dữ liệu hai phông chưa lên GPU; thiếu phông thì HUD không có chữ (GBK12) hay chữ có dấu ra ô vuông (VTNAM14).
    std::optional<BitmapFont> font;
    std::optional<BitmapFont> vi_font;

    void open_portraits(const std::filesystem::path& data_root);
    void open_servers(const std::filesystem::path& data_root);
    void open_scenes(const std::filesystem::path& data_root);
    void open_quests(const std::filesystem::path& data_root);
};

// Đọc một phông bitmap; thiếu hay hỏng thì ghi một dòng (what là tên gọi trong dòng đó) và trả nullopt.
std::optional<BitmapFont> read_font(const std::filesystem::path& file, std::string_view what) {
    core::Result<BitmapFont> opened = BitmapFont::open(file);
    if (opened) return std::move(*opened);
    std::println(stderr, "Giao diện: không có {}: {}", what, opened.error());
    return std::nullopt;
}

// Nạp bảng chân dung (Table/portraits.tsv; không đọc được thì khung nhân vật không có mặt) và dữ
// liệu của màn tạo nhân vật, rồi đưa các bộ ảnh mà bảng chỉ đặt lúc chạy vào giao diện (chân dung, màn
// tạo nhân vật, ô khoá của hòm đồ: layout không nhắc tới chúng). Gọi trước khi dựng Hub vì asset đổi.
void Prepared::open_portraits(const std::filesystem::path& data_root) {
    const std::optional<table::Tsv> table = read_table(data_root / "Table" / "portraits.tsv");
    portraits = table ? panel::Portraits::from_table(*table) : panel::Portraits{};
    cast = cast_of(data_root, table);
    for (const std::string& imageset : portraits.imagesets()) {
        loader.add_imageset(imageset);
    }
    for (const std::string_view imageset : panel::create_imagesets()) {
        loader.add_imageset(imageset);
    }
    loader.add_imageset(panel::kBagLockImageset);
    // Dạng khung đổi được lúc chạy (UiConfig của máy chủ), nên nền khung vuông luôn được nạp.
    loader.add_imageset(panel::kSquareImageset);
}

// Nạp bảng cảnh của các bảng bản đồ (Config/SceneDefineEx.txt). Thiếu hay hỏng thì bảng rỗng và bản đồ lớn
// không mở được cảnh nào.
void Prepared::open_scenes(const std::filesystem::path& data_root) {
    const io::TextResult text = io::read_text(data_root / "Config" / "SceneDefineEx.txt");
    if (!text) {
        std::println(stderr, "Giao diện: không có bảng cảnh, bản đồ lớn không mở được");
        return;
    }
    scenes = panel::SceneTable::from_text(*text);
    if (scenes.is_empty()) std::println(stderr, "Giao diện: bảng cảnh không đọc được dòng nào");
    world_cities = panel::world_cities(scenes, scene_names);
    // Ảnh nhãn của các thành phố do bảng cảnh chỉ tên lúc chạy, layout không nhắc tới: đưa trọn bộ ảnh vào.
    std::set<std::string_view> label_sets;
    for (const panel::SceneRow& row : scenes.rows()) {
        if (row.world == panel::kNormalWorld && !row.hover_set.empty()) label_sets.insert(row.hover_set);
    }
    for (const std::string_view set : label_sets)
        loader.add_imageset(set);
}

// Nạp danh sách máy chủ của bảng chọn máy chủ (Table/login_servers.tsv). Thiếu hay hỏng thì thủ tục
// đăng nhập bỏ bước chọn máy chủ và mở ở bảng tài khoản.
void Prepared::open_servers(const std::filesystem::path& data_root) {
    const io::TextResult text = io::read_text(data_root / "Table" / "login_servers.tsv");
    if (!text) {
        std::println(stderr, "Giao diện: không có danh sách máy chủ, bỏ bước chọn máy chủ");
        return;
    }
    if (!panel::recall_directory(flow, *text)) std::println(stderr, "Giao diện: danh sách máy chủ sai dạng");
}

// Nạp hai bảng của sổ nhiệm vụ (Table/mission_outline.tsv, Table/mission_kinds.tsv, do
// TOOLS/content/export_config.py xuất); thiếu hay hỏng thì ghi một dòng và sổ không có nhiệm vụ nhận được.
void Prepared::open_quests(const std::filesystem::path& data_root) {
    const std::optional<table::Tsv> outline = read_table(data_root / "Table" / "mission_outline.tsv");
    const std::optional<table::Tsv> kinds = read_table(data_root / "Table" / "mission_kinds.tsv");
    if (!outline || !kinds) return;
    if (const std::optional<std::string> failed = panel::load_quest_tables(quests, *outline, *kinds)) {
        std::println(stderr, "Giao diện: bảng nhiệm vụ hỏng: {}", *failed);
    }
}

// Việc đọc đĩa của Hud::open, chạy được ở luồng nào cũng được (không đụng GPU, không đụng trạng thái chung).
// Ba việc độc lập với bộ nạp giao diện (chuỗi, tên cảnh, hai phông) chạy ở luồng riêng cùng lúc với nó: đường dài
// nhất còn lại là bộ nạp và 40 layout (đo 2026-10-13: 96 + 24 ms trên tổng 286 ms khi nối đuôi).
core::Result<Prepared> prepare_hud(const std::filesystem::path& data_root, bool uses_phone_layout) {
    const std::filesystem::path root = data_root / "Interface";
    auto strings = std::async(std::launch::async, [&data_root] { return strings_of(data_root); });
    auto names = std::async(std::launch::async, [&data_root] { return scene_names(data_root); });
    auto font = std::async(std::launch::async,
        [&root] { return read_font(root / io::path_from_utf8(kFontFile), "phông chữ"); });
    auto vi_font = std::async(std::launch::async,
        [&root] { return read_font(root / io::path_from_utf8(kViFontFile), "phông Việt"); });
    const gui::DiskSource files(root, uses_phone_layout);
    gui::GuiSources sources;
    sources.files = &files;
    auto opened = gui::GuiLoader::open(sources);
    if (!opened) {
        constexpr const char* kNoUi = "không mở được giao diện";
        const auto& reason = opened.error();
        return core::fail(core::ErrorCode::kInvalidArgument, kNoUi, reason);
    }
    Prepared ready(std::move(*opened));
    const auto added = add_layouts(ready.loader);
    if (!added) {
        constexpr const char* kNoLayout = "không nạp được layout";
        const auto& reason = added.error();
        return core::fail(core::ErrorCode::kInvalidArgument, kNoLayout, reason);
    }
    ready.open_portraits(data_root);
    ready.open_servers(data_root);
    ready.open_quests(data_root);
    // Bảng tên cảnh phải có trước open_scenes (danh sách thành phố của bản đồ thế giới dựng từ nó).
    ready.scene_names = names.get();
    ready.open_scenes(data_root);
    ready.strings = strings.get();
    ready.font = font.get();
    ready.vi_font = vi_font.get();
    return ready;
}

} // namespace

// Mỗi Hud một State duy nhất trên heap: 50 byte đệm giữa các trường không đáng đảo thứ tự các trường đang xếp theo
// nhóm ý nghĩa (bảng, bản đồ, thủ tục đăng nhập, phông).
// NOLINTNEXTLINE(clang-analyzer-optin.performance.Padding)
struct Hud::State {
    // Lấy đi mọi phần của ready trừ hai phông: chúng chờ seat_fonts đưa lên GPU.
    State(Prepared& ready, render::UiPass& target, const std::filesystem::path& data_root, resource::TextureTier tier)
        : loader(std::move(ready.loader)),
          pass(&target),
          painter(target, data_root, tier),
          strings(std::move(ready.strings)),
          scene_names(std::move(ready.scene_names)),
          portraits(std::move(ready.portraits)),
          cast(std::move(ready.cast)),
          client_root(data_root),
          scenes(std::move(ready.scenes)),
          world_cities(std::move(ready.world_cities)),
          flow(std::move(ready.flow)),
          quests(std::move(ready.quests)),
          atlas(data_root) {}

    gui::GuiLoader loader;
    render::UiPass* pass;
    Painter painter;
    gui::StringBook strings;
    gui::StringBook scene_names;
    panel::Portraits portraits;
    panel::RoleCast cast;
    std::unique_ptr<gui::Hub> hub;
    // Màn của host trên loader và hub ở trên, và host chạy script các cửa sổ trong kScripted (không có thì còn bảng port tay).
    // host_press và host_right_press là cửa sổ dưới chuột lúc nhấn trái và phải, để nhận ra Clicked và RBClicked; host_hover là cửa
    // sổ dưới chuột ở khung trước (MouseEnter, MouseLeave).
    // Trạng thái ghi được mà hàm game của script dùng chung (XSCRIPT, XParam); khai trước host để sống lâu hơn máy Lua.
    script::Context script_context;
    std::optional<script::GuiScreen> screen;
    std::optional<script::Host> host;
    std::string host_press;
    std::string host_right_press;
    std::string host_hover;
    bool was_right_down = false;
    panel::Deck deck;
    panel::Maps maps;
    panel::Desk desk;
    panel::Packet packet;
    // Thư mục dữ liệu client (atlas bản đồ lớn đọc ô ảnh từ đây).
    std::filesystem::path client_root;
    // Bảng cảnh (Config/SceneDefineEx.txt) và bản đồ lớn: trạng thái, cảnh đang vẽ, atlas và texture riêng.
    panel::SceneTable scenes;
    panel::SceneBoard board;
    int board_scene = -1;
    bool is_board_open = false;
    std::optional<RadarAtlas> board_atlas;
    std::optional<std::uint32_t> board_texture;
    std::optional<MapPaint> board_map;
    // Nhấp trái bắt đầu trên bản đồ lớn (điểm chuột) và việc đi tới sau khi nhả.
    std::optional<gui::Pointer> board_press;
    std::optional<RunTo> run_to;
    // Tốc độ xoay đang giữ ở hai nút mũi tên dưới người mẫu của bảng nhân vật.
    float equip_spin = 0.0F;
    // Bản đồ thế giới: độ lệch và thành đang trỏ, các dòng thành phố dựng từ bảng cảnh, ảnh nền (nạp lần
    // đầu bản đồ mở) và điểm bắt đầu một cú nhấp trái.
    panel::WorldBoard world;
    std::string world_cities;
    std::optional<std::uint32_t> world_texture;
    bool has_world_image_failed = false;
    std::optional<MapPaint> world_paint;
    std::optional<gui::Pointer> world_press;
    panel::LoginFlow flow;
    // Sổ nhiệm vụ (QuestLog_Frame) và việc nó nhờ ở lần nhấn gần nhất.
    panel::QuestBook quests;
    std::vector<panel::Call> quest_calls;
    // Hộp thoại NPC (Quest_Frame) và tên vật phẩm cho phần thưởng của nó (đọc Table/items.tsv ở lần đầu cần).
    panel::NpcTalk talk;
    panel::ItemNames item_names;
    bool has_item_names_failed = false;
    panel::SkillBook skill_book;
    bool has_skill_book_failed = false;
    bool has_skill_icons_failed = false;
    // Ô kỹ năng vừa nhấn; prepare xong thì Display lấy đi và ra chiêu.
    std::optional<std::uint32_t> skill_press;
    std::optional<panel::talk::Place> revive_press;
    // Thanh kỹ năng thú cưng (MainMenuBar_3) và việc nó nhờ ở lần nhấn gần nhất. Danh sách action của
    // thanh do hệ thú cưng giữ, client chưa có hệ đó nên thanh chưa hiện (xem main_menu_bar_3.hpp).
    panel::MainMenuBar3 pet_bar;
    std::vector<panel::Call> pet_bar_calls;
    // Nhóm thanh action (MainMenuBar_4, FunctionBarRight_2...) và việc chúng nhờ ở lần xử lý gần nhất. bar_facts là điều
    // game trả cho script của nhóm: client chưa có hệ action, hệ thú cưng và kho gói hành động chat nên để rỗng (xem
    // action_bar.hpp).
    panel::ActionBars action_bars;
    panel::BarFacts bar_facts;
    std::vector<panel::Call> bar_calls;
    // Đã phát PLAYER_ENTERING_WORLD cho lần vào màn chơi này (đặt lại khi rời màn chơi).
    bool has_entered_world = false;
    panel::SoftKeys keys;
    // Bảng chuyển cảnh chạy bằng SceneTrans.lua gốc. note_loading đẩy ba sự kiện của gốc
    // (PLAYER_LEAVE_WORLD, ON_SCENE_TRANSING, SCENE_TRANSED) vào trans_events, step_panels đưa
    // chúng vào dispatch. is_trans_open là bảng đang hiện theo dòng sự kiện đó; trans_percent là
    // phần trăm đã báo ở khung trước.
    std::int32_t trans_percent = -1;
    std::chrono::milliseconds trans_since{0};
    bool is_trans_open = false;
    std::vector<panel::PostedEvent> trans_events;
    // Cửa sổ chạy bằng script gốc: kScripted cộng công tắc so sánh THIENLONG_UI_SCRIPT
    // (script/windows.hpp).
    std::vector<std::string> scripted;
    // Các bảng port từ script (UI-PORT): ui_args là kho arg<k> dùng chung của mọi bảng (xem ui/panel/events.hpp).
    panel::EventArgs ui_args;
    bool is_app_inited = false;
    // Lần nhấn trước trong thủ tục đăng nhập (cửa sổ, lúc nhấn, điểm nhấn: press_x, press_y đứng cạnh
    // held_x), để nhận ra nhấn đúp.
    std::string press_window;
    std::chrono::milliseconds press_clock{0};
    // Thủ tục của khung trước; rỗng trước khung đầu, để lần đầu vào thủ tục đăng nhập mở bảng.
    std::optional<Phase> phase;
    bool was_down = false;
    std::optional<Action> asked;
    // Dạng khung chân dung: theo lúc dựng cho tới khi máy chủ gửi UiConfig.
    panel::FrameStyle style = panel::FrameStyle::kBuild;
    std::optional<std::chrono::milliseconds> last_clock;
    panel::ShownModel shown;
    // Phông và bộ viết chữ; không mở được phông thì HUD không có chữ.
    std::optional<BitmapFont> font;
    std::optional<TextWriter> writer;
    std::uint32_t font_texture = render::kUiWhite;
    std::optional<BitmapFont> vi_font;
    std::optional<TextWriter> vi_writer;
    std::uint32_t vi_font_texture = render::kUiWhite;
    // Ảnh minimap: atlas quanh người chơi, texture của nó và cách vẽ ở khung này.
    RadarAtlas atlas;
    std::optional<std::uint32_t> map_texture;
    std::optional<MapPaint> map;
    // Ô MiniMap_MapArea của khung trước, để toạ độ chuột dùng đúng hộp đã dàn.
    std::optional<gui::Box> map_area;
    bool cursor_inside = false;
    float held_x = 0.0F;
    float held_z = 0.0F;
    float press_x = 0.0F;
    float press_y = 0.0F;
    // Ảnh fake object của khung này; mượn của HudView, chỉ dùng trong prepare.
    std::span<const ViewPaint> views;
    // Cỡ khung ảo của layout (điểm ảnh của layout) và số điểm ảnh của màn cho một điểm ảnh ấy (layout_scale).
    float width = 0.0F;
    float height = 0.0F;
    float scale = 1.0F;
    // Scale của lần dựng quad gần nhất: đổi thì chữ và lưới điểm ảnh phải dàn lại.
    float built_scale = 1.0F;
    std::uint64_t still_stamp = 0;
    std::uint64_t live_stamp = 0;
    std::uint64_t text_stamp = 0;
    bool is_built = false;
    std::vector<render::UiVertex> joined_vertices;
    std::vector<render::UiBatch> joined_batches;

    // Nối quad của extra vào sau quad của giao diện (painter), dời chỉ số quad của các lô thêm. Quad của extra tính
    // theo điểm ảnh của màn nên đổi sang khung ảo của layout: không co theo giao diện.
    void join(Hud::HudExtra extra) {
        const std::span<const render::UiVertex> own = painter.vertices();
        const std::span<const render::UiBatch> own_batches = painter.batches();
        const auto base = static_cast<std::uint32_t>(own.size() / 4);
        joined_vertices.assign(own.begin(), own.end());
        for (render::UiVertex vertex : extra.vertices) {
            vertex.x /= scale;
            vertex.y /= scale;
            joined_vertices.push_back(vertex);
        }
        joined_batches.assign(own_batches.begin(), own_batches.end());
        for (render::UiBatch batch : extra.batches) {
            batch.first_quad += base;
            batch.mask_box = render::UiRect{.x = batch.mask_box.x / scale, .y = batch.mask_box.y / scale,
                .width = batch.mask_box.width / scale, .height = batch.mask_box.height / scale};
            joined_batches.push_back(batch);
        }
    }

    void seat_fonts(Prepared& ready);
    [[nodiscard]] bool note_double(std::string_view window, const HudView& view);
    [[nodiscard]] panel::PlaceText place_under(const HudView& view);
    void enter(Phase next);
    void note_press(const HudView& view);
    void note_hold(const HudView& view);
    [[nodiscard]] float frame_seconds(std::chrono::milliseconds now);
    [[nodiscard]] std::string_view held_window(gui::Pointer pointer) const;
    [[nodiscard]] bool is_on_scroll(float across, float down) const;
    void note_scroll(const HudView& view, float seconds);
    void press_login(std::string_view window, const HudView& view);
    void press_keys(std::string_view window, const HudView& view);
    void close_keys();
    void send_window_event(std::string name);
    void release_login(const HudView& view);
    void press_pet_bar(std::string_view window);
    void press_action_bars(std::string_view window);
    [[nodiscard]] bool can_do_action_now() const;
    [[nodiscard]] panel::LoginFacts login_facts(const HudView& view) const noexcept;
    void note_hover(const HudView& view);
    void note_text(const HudView& view);
    void note_loading(const HudView& view);
    void push_trans(std::string name, std::vector<std::string> args);
    void fill_panels(const HudView& view);
    void fill_play(const HudView& view);
    void step_panels(const HudView& view);
    void step_login(const HudView& view);
    void sync_soft_keys(const HudView& view);
    void dispatch(std::span<const panel::PostedEvent> first);
    void ensure_item_names();
    void ensure_skill_book();
    void post_to_host(panel::EventQueue& queue, const panel::PostedEvent& posted);
    void note_host(const HudView& view);
    void note_host_press(std::string_view window, const HudView& view);
    void note_host_release(const HudView& view);
    void note_host_pointer(const HudView& view);
    void drain_host_calls();
    [[nodiscard]] std::vector<panel::Call> take_script_calls();
    void update_script_facts(const HudView& view);
    void open_host();
    void push_debug_message(std::string_view text);
    [[nodiscard]] core::Status add_map();
    void upload_map();
    [[nodiscard]] std::optional<MapPaint> map_of(const HudScene& scene);
    [[nodiscard]] const panel::SceneRow* board_scene_row() const noexcept;
    void fill_board(const HudView& view);
    void note_board_press(std::string_view window, const HudView& view);
    void note_board_release(const HudView& view);
    void fill_world(const HudView& view);
    void note_world_release(const HudView& view);
    [[nodiscard]] std::optional<MapPaint> world_of();
    void load_world_image();
    [[nodiscard]] std::optional<MapPaint> board_of();
    void upload_board(const resource::Image& image);
    [[nodiscard]] bool is_current() const noexcept;
    void rebuild();
};

// Đưa hai phông đã đọc lên GPU. Không lên được thì phông đó coi như thiếu (HUD không có chữ, hay chữ có dấu ra ô
// vuông).
void Hud::State::seat_fonts(Prepared& ready) {
    if (!ready.font) return;
    const core::Result<std::uint32_t> texture = pass->add_texture(ready.font->atlas());
    if (!texture) {
        std::println(stderr, "Giao diện: không tải được phông lên GPU: {}", texture.error());
        return;
    }
    font = std::move(ready.font);
    font_texture = *texture;
    writer.emplace(*font, &strings);
    if (!ready.vi_font) return;
    const core::Result<std::uint32_t> vi_texture = pass->add_texture(ready.vi_font->atlas());
    if (!vi_texture) {
        std::println(stderr, "Giao diện: không tải được phông Việt lên GPU: {}", vi_texture.error());
        return;
    }
    vi_font = std::move(ready.vi_font);
    vi_font_texture = *vi_texture;
    vi_writer.emplace(*vi_font, &strings);
}

// Chuột trên MiniMap_MapArea thì GetMouseScenePos; rời ô thì chỗ đứng. Hộp là của khung trước
// vì chữ toạ độ phải có trước khi dàn trang, còn hộp không phụ thuộc chữ đó.
panel::PlaceText Hud::State::place_under(const HudView& view) {
    const bool has_box = view.pointer.has_value() && map_area.has_value();
    const gui::Box box = map_area.value_or(gui::Box{});
    const float across = view.pointer.has_value() ? view.pointer->x : 0.0F;
    const float down = view.pointer.has_value() ? view.pointer->y : 0.0F;
    const bool is_wide = box.w > 0.0F && box.h > 0.0F;
    const bool is_in_columns = across >= box.x && across < box.x + box.w;
    const bool is_in_rows = down >= box.y && down < box.y + box.h;
    const bool is_over = has_box && is_wide && is_in_columns && is_in_rows;
    gui::SceneHit hit;
    if (is_over) {
        gui::RadarAsk ask;
        ask.scene_width = view.scene.width;
        ask.scene_depth = view.scene.depth;
        ask.window_width = box.w;
        ask.window_height = box.h;
        ask.player_x = view.scene.player_x;
        ask.player_z = view.scene.player_z;
        gui::SceneCursor cursor;
        cursor.local_x = across - box.x;
        cursor.local_y = down - box.y;
        hit = gui::scene_at(ask, cursor);
    }
    panel::Hover hover;
    hover.was_inside = cursor_inside;
    hover.is_inside = is_over;
    hover.is_on_scene = hit.is_on_scene;
    hover.scene_x = hit.x;
    hover.scene_z = hit.z;
    hover.held_x = held_x;
    hover.held_z = held_z;
    hover.player_x = view.scene.player_x;
    hover.player_z = view.scene.player_z;
    const panel::PlaceText chosen = panel::coordinate_of(hover);
    cursor_inside = chosen.is_inside;
    held_x = chosen.held_x;
    held_z = chosen.held_z;
    return chosen;
}

// Thủ tục đổi (kể cả khung đầu): vào thủ tục đăng nhập thì mở bảng nhập tài khoản, như sự kiện
// GAMELOGIN_OPEN_COUNT_INPUT của client gốc; rời nó thì đóng bàn phím ảo, như CloseWindow của
// LoginLogOn_OnEvent khi bảng đóng.
void Hud::State::enter(Phase next) {
    if (phase == next) return;
    phase = next;
    if (next == Phase::kLogin) panel::start_login(flow);
    if (next != Phase::kLogin) close_keys();
}

// Lần nhấn trái mới lên một cửa sổ thì báo cho các bảng nghe nút của thủ tục đang chạy, thay sự
// kiện Clicked mà layout gốc nối vào script Lua. Khác gốc: báo ngay lúc nhấn; Clicked của CEGUI
// bắn lúc nhả trên chính nút đó.
float Hud::State::frame_seconds(std::chrono::milliseconds now) {
    const std::optional<std::chrono::milliseconds> previous = last_clock;
    last_clock = now;
    if (!previous || now < *previous) return 0.0F;
    return std::chrono::duration<float>(now - *previous).count();
}

// Điểm có nằm trên khung cuộn ô mô tả môn phái của bảng tạo, lúc chữ của nó dài hơn ô, không.
bool Hud::State::is_on_scroll(float across, float down) const {
    if (!hub) return false;
    const std::optional<gui::ScrollSpan> span = hub->text_span(panel::kCreateDetail);
    if (!span || !gui::is_scrollable(*span)) return false;
    const std::optional<gui::Box> frame = hub->box(panel::kCreateDetailFrame);
    return frame && holds(*frame, across, down);
}

// Khung cuộn ô mô tả môn phái: cỡ chữ và ô theo lần dàn trang trước; chuột nằm trên khung thì chữ
// đứng yên và nhận nấc lăn của khung.
void Hud::State::note_scroll(const HudView& view, float seconds) {
    panel::DetailRoll roll;
    roll.span = hub->text_span(panel::kCreateDetail).value_or(gui::ScrollSpan{});
    roll.seconds = seconds;
    roll.is_hovered = view.pointer.has_value() && is_on_scroll(view.pointer->x, view.pointer->y);
    if (roll.is_hovered) roll.notches = view.wheel;
    panel::roll_flow(flow, roll);
}

std::string_view Hud::State::held_window(gui::Pointer pointer) const {
    const std::optional<std::string_view> hit = hub->hit(pointer.x, pointer.y, gui::Probe::kLeftButton);
    return hit ? *hit : std::string_view{};
}

void Hud::State::note_hold(const HudView& view) {
    const float seconds = frame_seconds(view.clock);
    const bool is_login = view.phase == Phase::kLogin && hub != nullptr;
    const bool is_down = is_login && view.pointer.has_value() && view.pointer->is_down;
    std::string_view window;
    if (is_down) window = held_window(*view.pointer);
    if (!is_login) return;
    panel::hold_flow(flow, window);
    panel::advance_flow(flow, seconds);
    note_scroll(view, seconds);
}

// Điều chuỗi đăng nhập đọc của game ở khung này; đồng hồ khung làm muối cho xúc xắc bảng tạo.
panel::LoginFacts Hud::State::login_facts(const HudView& view) const noexcept {
    panel::LoginFacts facts;
    facts.cast = &cast;
    facts.portraits = &portraits;
    facts.words = &strings;
    facts.salt = static_cast<std::uint32_t>(view.clock.count());
    return facts;
}

// Cửa sổ dưới chuột của thủ tục đăng nhập (theo lần dàn trang trước), thay sự kiện MouseEnter và
// MouseLeave mà layout gốc nối vào script: bảng tạo nhân vật đổi dòng mô tả theo nó.
void Hud::State::note_hover(const HudView& view) {
    if (view.phase != Phase::kLogin || !hub) return;
    std::optional<std::string_view> window;
    if (view.pointer) window = hub->hit(view.pointer->x, view.pointer->y, gui::Probe::kAny);
    std::optional<std::size_t> element;
    if (window == panel::kServerAreaList && view.pointer.has_value()) {
        element = hub->element_at(panel::kServerAreaList, *view.pointer);
    }
    if (window == panel::kLogonSuffixList && view.pointer.has_value()) {
        element = hub->list_item(panel::kLogonSuffixList, *view.pointer);
    }
    const bool is_down = view.pointer.has_value() && view.pointer->is_down;
    panel::hover_flow(flow, window.value_or(std::string_view{}), element, is_down);
}

void Hud::State::note_press(const HudView& view) {
    const bool is_down = view.pointer.has_value() && view.pointer->is_down;
    const bool is_press = is_down && !was_down;
    const bool is_release = !is_down && was_down;
    was_down = is_down;
    if (is_release && view.phase == Phase::kLogin) {
        release_login(view);
        note_host_release(view);
    }
    if (is_release && view.phase == Phase::kPlay) {
        note_board_release(view);
        note_world_release(view);
        note_host_release(view);
        equip_spin = 0.0F;
    }
    if (!is_press || !hub || !view.pointer) return;
    const gui::Pointer spot = *view.pointer;
    const auto window = hub->hit(spot.x, spot.y, gui::Probe::kLeftButton);
    const std::string_view pressed = window.value_or("");
    note_host_press(pressed, view);
    if (!window && view.phase == Phase::kLogin) panel::dismiss_flow(flow);
    if (!window) return;
    if (const std::optional<Action> next = panel::menu_action(*window)) {
        asked = next;
        return;
    }
    if (view.phase == Phase::kLogin) {
        press_login(*window, view);
        return;
    }
    panel::press_map(maps, *window);
    panel::PlayFacts facts;
    if (view.hero != nullptr) facts.sect = view.hero->sect;
    panel::press_desk(desk, *window, facts);
    if (const std::string_view notice = panel::take_notice(desk); !notice.empty()) push_debug_message(notice);
    quest_calls.clear();
    panel::press_quest_book(quests, desk, *window, view.hero, &scene_names, quest_calls);
    if (const std::optional<std::size_t> row = hub->list_item(panel::kQuestLogList, spot)) {
        static_cast<void>(panel::pick_quest_row(quests, *row, view.hero, &scene_names));
    }
    for (const panel::Call& call : quest_calls) {
        std::println(stderr, "Sổ nhiệm vụ: việc nhờ {} chưa có ở HUD", static_cast<int>(call.ask));
    }
    panel::press_talk(talk, *window, view.clock);
    if (const std::optional<std::uint32_t> option = hub->option_at(panel::kTalkDesc, spot)) {
        panel::pick_talk_option(talk, *option, view.clock);
    }
    panel::press_packet(packet, *window);
    if (const std::optional<panel::talk::Place> place = panel::relive_place(*window)) revive_press = *place;
    if (const std::optional<std::uint32_t> slot = panel::skill_slot_of(*window)) {
        const bool known = view.hero != nullptr && *slot < view.hero->skills.size();
        if (known) skill_press = *slot;
    }
    press_pet_bar(*window);
    press_action_bars(*window);
    note_board_press(*window, view);
    if (window == panel::kWorldWindow && view.pointer) world_press = view.pointer;
    if (window == kEquipTurnLeft) equip_spin = -kEquipSpin;
    if (window == kEquipTurnRight) equip_spin = kEquipSpin;
}

// Nhấn trái lên cửa sổ window (rỗng là khoảng trống) của màn chơi: MouseButtonDown và MouseLButtonDown của layout, rồi cửa sổ
// bật lên nào ở ngoài chỗ nhấn thì tự đóng (CUIWindowMng sau injectMouseButtonDown). Việc script nhờ game: ghi một dòng.
// Khác gốc: nhấn phải, MouseEnter/MouseLeave và nhấn đúp chưa tới được host; CEGUI chỉ phát lên cửa sổ dưới chuột, chưa đối
// chiếu với CEGUIBase.dll 2026 xem có lan lên cửa sổ cha không.
void Hud::State::note_host_press(std::string_view window, const HudView& view) {
    if (!host || !view.pointer) return;
    host_press = window;
    if (!window.empty()) {
        static_cast<void>(host->fire(window, "MouseButtonDown", script::MouseButton::kLeft));
        static_cast<void>(host->fire(window, "MouseLButtonDown", script::MouseButton::kLeft));
    }
    host->pressed(script::Spot{.x = view.pointer->x, .y = view.pointer->y});
    drain_host_calls();
}

// Việc script nhờ game kể từ lần lấy trước: của host (PushEvent, OpenWindow...) rồi của hàm native (VARIABLE_CHANGED, lời nhắn của
// ScriptGlobal_Format).
std::vector<panel::Call> Hud::State::take_script_calls() {
    std::vector<panel::Call> calls;
    if (host) calls = host->take_calls();
    for (panel::Call& call : script_context.take_calls()) calls.push_back(std::move(call));
    return calls;
}

// Điều game biết về thế giới mà hàm native của script đọc (Context::facts), đặt lại từ đầu vào của khung. Khác gốc: chưa có NPC hội
// thoại, loại hiện của GM và máy chủ đặc biệt 2018 nên giữ mặc định của máy chủ thường.
void Hud::State::update_script_facts(const HudView& view) {
    script::Facts& facts = script_context.facts;
    facts.scene_id = view.phase == Phase::kPlay && view.scene.id >= 0 ? std::optional<std::int32_t>(view.scene.id) : std::nullopt;
    facts.hero = view.phase == Phase::kPlay ? view.hero : nullptr;
    facts.clock = view.clock;
    facts.scenes = &scenes;
    facts.scene_size = view.phase == Phase::kPlay && view.scene.id >= 0
        ? std::optional<script::Facts::SceneSize>(script::Facts::SceneSize{
              .width = static_cast<std::int32_t>(view.scene.width), .depth = static_cast<std::int32_t>(view.scene.depth)})
        : std::nullopt;
}

// Việc script nhờ game sau một thao tác của người chơi: PushEvent (và lời nhắn) thành sự kiện mới đi qua mọi bảng như sự kiện của
// game; việc khác chưa có phía game để làm nên ghi một dòng.
void Hud::State::drain_host_calls() {
    if (!host) return;
    std::vector<panel::PostedEvent> events;
    for (const panel::Call& call : take_script_calls()) {
        if (std::optional<panel::PostedEvent> next = panel::event_of(call)) {
            events.push_back(std::move(*next));
        } else {
            std::println(stderr, "Script giao diện: việc nhờ {} chưa có ở HUD", panel::name_of(call.ask));
        }
    }
    if (!events.empty()) dispatch(events);
}

// Nhả trái: MouseButtonUp lên cửa sổ dưới chuột, và Clicked khi nhả trên đúng cửa sổ đã nhấn (nút của CEGUI).
void Hud::State::note_host_release(const HudView& view) {
    const std::string pressed = std::move(host_press);
    host_press.clear();
    if (!host || !hub || !view.pointer) return;
    const auto window = hub->hit(view.pointer->x, view.pointer->y, gui::Probe::kLeftButton);
    if (!window) return;
    static_cast<void>(host->fire(*window, "MouseButtonUp", script::MouseButton::kLeft));
    if (*window == pressed) static_cast<void>(host->fire(*window, "Clicked", script::MouseButton::kLeft));
    drain_host_calls();
}

// Nhấn trái lên một ô của thanh kỹ năng thú cưng: MainMenuBar_3_Clicked(index). Khác gốc: nhấn phải
// (RBClicked) chưa tới được HUD; IsWindowShow là cửa sổ có ô trên màn hình ở lần dàn trang trước.
void Hud::State::press_pet_bar(std::string_view window) {
    const auto found = std::ranges::find(panel::kPetButtons, window);
    if (found == panel::kPetButtons.end()) return;
    const auto index = static_cast<std::int32_t>(found - panel::kPetButtons.begin()) + 1;
    pet_bar_calls.clear();
    panel::press_pet_skill_button(pet_bar, index, can_do_action_now(), pet_bar_calls);
    for (const panel::Call& call : pet_bar_calls) {
        std::println(stderr, "Thanh kỹ năng thú cưng: việc nhờ {} chưa có ở HUD", static_cast<int>(call.ask));
    }
}

// DataPool:IsCanDoAction() (Game.exe 0x1402e7d70): IsWindowShow là cửa sổ có ô trên màn hình ở lần dàn trang trước.
bool Hud::State::can_do_action_now() const {
    return panel::can_do_action([this](std::string_view name) { return hub->box(name).has_value(); });
}

// Nhấn trái lên một ô của nhóm thanh action: <Thanh>_Clicked(id). Lời nhắc "không làm được" của script là
// PushDebugMessage, tới các bảng qua NEW_DEBUGMESSAGE. Khác gốc: nhấn phải (RBClicked) chưa tới được HUD.
void Hud::State::press_action_bars(std::string_view window) {
    bar_calls.clear();
    action_bars.press(window, can_do_action_now(), bar_facts, bar_calls);
    // dispatch dùng lại bar_calls, nên việc đã nhờ phải ra khỏi nó trước khi gửi sự kiện.
    const std::vector<panel::Call> calls = std::move(bar_calls);
    bar_calls.clear();
    for (const panel::Call& call : calls) {
        if (call.ask == panel::Ask::kPushDebugMessage) {
            push_debug_message(call.text);
        } else {
            std::println(stderr, "Thanh action: việc nhờ {} chưa có ở HUD", panel::name_of(call.ask));
        }
    }
}

// Lần nhấn này có phải lần thứ hai của một cú nhấn đúp không. Nhấn đúp xong thì lần nhấn kế bắt đầu
// chuỗi mới (CEGUI không phát nhấn ba).
bool Hud::State::note_double(std::string_view window, const HudView& view) {
    const gui::Pointer spot = view.pointer.value_or(gui::Pointer{});
    const bool is_near = std::abs(spot.x - press_x) <= kDoubleReach && std::abs(spot.y - press_y) <= kDoubleReach;
    const bool is_soon = view.clock >= press_clock && view.clock - press_clock <= kDoubleClick;
    const bool is_double = window == press_window && is_near && is_soon;
    press_window = is_double ? std::string{} : std::string(window);
    press_x = spot.x;
    press_y = spot.y;
    press_clock = view.clock;
    return is_double;
}

// Một lần nhấn trong thủ tục đăng nhập: bảng nhập tài khoản nghe trước, rồi tới bàn phím ảo. Nút bàn
// phím ảo của bảng là ToggleWindow("SoftKeyBoard") của LogOn_KeyBoard; ký tự một phím gõ ra đi vào ô
// mà bảng đang ngắm. Đồng hồ khung làm muối cho lần xoay vòng phím.
void Hud::State::press_login(std::string_view window, const HudView& view) {
    panel::LoginFacts facts = login_facts(view);
    facts.is_double = note_double(window, view);
    if (window == panel::kServerAreaList && view.pointer.has_value()) {
        facts.element = hub->element_at(panel::kServerAreaList, *view.pointer);
    }
    if (window == panel::kLogonSuffixList && view.pointer.has_value()) {
        facts.element = hub->list_item(panel::kLogonSuffixList, *view.pointer);
    }
    // Danh sách đuôi tài khoản đang mở chiếm chuột: lần nhấn này không tới bàn phím ảo hay nút nào khác.
    const bool was_taken = panel::suffix_list_open(flow);
    panel::press_flow(flow, window, facts);
    if (was_taken) return;
    if (!panel::on_account(flow)) {
        close_keys();
        return;
    }
    press_keys(window, view);
}

// Bàn phím ảo ở một lần nhấn của bảng tài khoản: nút của bảng mở hay đóng nó, và mặt phím gõ ký tự
// vào ô đang ngắm. Cửa sổ do SoftKeyBoard.lua mở và đóng (nút đóng là Clicked của layout), bảng chỉ
// còn việc gõ.
void Hud::State::press_keys(std::string_view window, const HudView& view) {
    if (window == panel::kLogonKeysButton) send_window_event("TOGGLE_WINDOW");
    if (!panel::is_soft_key_face(window) || !view.pointer) return;
    const std::optional<std::size_t> cell = hub->soft_key(panel::kSoftKeysWindow, *view.pointer);
    const std::optional<char32_t> typed = cell ? panel::strike_soft_key(keys, *cell) : std::nullopt;
    if (typed) panel::key_flow(flow, *typed);
}

// CloseWindow("SoftKeyBoard") khi bảng tài khoản đóng: sự kiện CLOSE_WINDOW nếu bàn phím đang hiện.
void Hud::State::close_keys() {
    if (!keys.is_open) return;
    send_window_event("CLOSE_WINDOW");
}

// Sự kiện OPEN_WINDOW, CLOSE_WINDOW, TOGGLE_WINDOW của game cho cửa sổ bàn phím ảo (arg0 là tên cửa
// sổ).
void Hud::State::send_window_event(std::string name) {
    panel::PostedEvent event;
    event.name = std::move(name);
    event.args.emplace_back(kSoftKeyBoard);
    const std::array<panel::PostedEvent, 1> events{std::move(event)};
    dispatch(events);
}

// Nhả nút trái trong thủ tục đăng nhập: cửa sổ dưới chuột và mục danh sách đuôi dưới chuột cho danh sách đuôi đang mở.
void Hud::State::release_login(const HudView& view) {
    std::string_view window;
    if (view.pointer && hub) window = hub->hit(view.pointer->x, view.pointer->y, gui::Probe::kAny).value_or(window);
    panel::release_flow(flow, window);
}

// Ký tự gõ từ bàn phím tới ô đang nhận phím của bảng nhập tài khoản; màn chơi chưa có ô nhập nào.
void Hud::State::note_text(const HudView& view) {
    if (view.phase != Phase::kLogin) return;
    for (const char32_t code : view.typed)
        panel::type_flow(flow, code, login_facts(view));
    if (!panel::on_account(flow)) close_keys();
}

// Sự kiện của bảng chuyển cảnh theo việc nạp cảnh mà client báo: bắt đầu nạp là
// PLAYER_LEAVE_WORLD, phần trăm đổi là ON_SCENE_TRANSING, hết nạp là SCENE_TRANSED.
// Khác gốc: bản gốc giấu bảng ngay khi nạp xong, và nạp một cảnh mất vài giây. Client này nạp cảnh
// nhỏ trong chừng một phần mười giây (đo 2026-10-09: resid 251 xong sau 123 ms), bảng chỉ kịp chớp;
// nên bảng đã hiện thì ở lại ít nhất kTransShown rồi mới giấu.
void Hud::State::note_loading(const HudView& view) {
    // Đồng hồ của người gọi lùi (gốc của nó đổi sau vài khung đầu) thì tính lại từ khung này.
    trans_since = std::min(trans_since, view.clock);
    if (!view.loading) {
        const bool is_due = view.clock - trans_since >= kTransShown;
        if (is_trans_open && is_due) push_trans("SCENE_TRANSED", {});
        if (is_trans_open && is_due) is_trans_open = false;
        if (!is_trans_open) trans_percent = -1;
        return;
    }
    if (!is_trans_open) {
        const std::string& raw = view.loading->name;
        const std::string_view found = scene_names.find(raw).value_or(raw);
        const std::string text(found);
        push_trans("PLAYER_LEAVE_WORLD", {text});
        is_trans_open = true;
        trans_percent = -1;
        trans_since = view.clock;
    }
    if (view.loading->percent == trans_percent) return;
    trans_percent = view.loading->percent;
    const std::string percent = std::to_string(trans_percent);
    if (trans_percent > 0) push_trans("ON_SCENE_TRANSING", {percent});
}

void Hud::State::push_trans(std::string name, std::vector<std::string> args) {
    panel::PostedEvent event;
    event.name = std::move(name);
    event.args = std::move(args);
    trans_events.push_back(std::move(event));
}

// Bộ gửi sự kiện của game (CEventSystem::Tick): đặt arg<k> dùng chung một lần cho mỗi sự kiện, trước khi hỏi từng bảng
// có nghe không (bảng đang ẩn chỉ nhận sự kiện đăng ký với cờ true). Sự kiện do chính các bảng đẩy (PushEvent, chuỗi gỡ
// gói hành động chat) vào cuối hàng đợi và tới các bảng sau khi sự kiện đang xử lý xong, ngay trong lượt này; sự kiện
// lặp bị bỏ (xem EventQueue).
void Hud::State::dispatch(std::span<const panel::PostedEvent> first) {
    panel::EventQueue queue(first, kMaxPanelEvents);
    while (const std::optional<panel::PostedEvent> posted_event = queue.next()) {
        const panel::PostedEvent& posted = *posted_event;
        const std::vector<std::string_view> given = posted.arguments();
        const panel::UiEvent event = ui_args.raise(posted.name, given);
        const auto& bar3_events = panel::kMainMenuBar3Events;
        const bool is_bar3 = panel::is_delivered(bar3_events, event.name, pet_bar.is_shown);
        if (is_bar3) panel::on_main_menu_bar_3_event(pet_bar, event, panel::PetSkillBar{});
        bar_calls.clear();
        action_bars.raise(event, bar_facts, bar_calls);
        for (const panel::Call& call : bar_calls) {
            if (std::optional<panel::PostedEvent> next = panel::event_of(call)) {
                queue.push(std::move(*next));
            } else {
                std::println(stderr, "Thanh action: việc nhờ {} chưa có ở HUD", panel::name_of(call.ask));
            }
        }
        post_to_host(queue, posted);
    }
}

// Sự kiện tới các cửa sổ chạy bằng script. Việc script nhờ game trả về hàng đợi: PushEvent thành sự kiện kế tiếp của lượt này
// (như bảng port tay), việc khác chưa có phía game để làm nên ghi một dòng.
void Hud::State::post_to_host(panel::EventQueue& queue, const panel::PostedEvent& posted) {
    if (!host) return;
    const std::vector<std::string_view> given = posted.arguments();
    host->post(posted.name, given);
    for (const panel::Call& call : take_script_calls()) {
        if (std::optional<panel::PostedEvent> next = panel::event_of(call)) {
            queue.push(std::move(*next));
        } else {
            std::println(stderr, "Script giao diện: việc nhờ {} chưa có ở HUD", panel::name_of(call.ask));
        }
    }
}

// Mở host cho các cửa sổ trong kScripted. Thiếu dữ liệu script (Script/windows.tsv) thì HUD chạy tiếp mà không có chúng; lỗi
// của script ghi vào stderr, không dừng khung.
void Hud::State::open_host() {
    screen.emplace(loader);
    screen->bind(hub.get());
    script::HostDesc desc;
    desc.data_root = client_root;
    scripted.assign(kScripted.begin(), kScripted.end());
    std::ranges::move(script::requested_windows(), std::back_inserter(scripted));
    desc.only = scripted;
    desc.natives = script::make_natives(script_context);
    auto opened = script::Host::open(desc, *screen);
    if (!opened) {
        std::println(stderr, "Giao diện: không mở được giao diện Lua: {}", opened.error());
        screen.reset();
        return;
    }
    host.emplace(std::move(*opened));
    for (const std::string& note : host->take_notes())
        std::println(stderr, "Giao diện Lua: {}", note);
}

// Số pixel nguyên của một cỡ thực; âm, NaN thành 0, quá 65535 thì kẹp.
namespace {
[[nodiscard]] std::uint32_t pixels_of(float extent) noexcept {
    return extent > 0.0F ? static_cast<std::uint32_t>(std::min(extent, 65535.0F)) : 0U;
}
} // namespace

// Chuột lên các cửa sổ chạy bằng script ngoài nhấn trái: MouseLeave rồi MouseEnter khi cửa sổ dưới chuột đổi (CEGUI 0.4 chỉ báo
// cửa sổ sâu nhất dưới chuột), và nút phải: MouseButtonDown khi nhấn, MouseButtonUp khi nhả cùng RBClicked và MouseRClick nếu nhả
// trên chính cửa sổ đã nhấn.
// Khác gốc: nghĩa của MouseRClick, MouseLClick, MouseClick trong CEGUIBase.dll 2026 chưa đối chiếu (đoán theo tên: bấm xong trên cùng
// cửa sổ); MouseLClick chưa phát; nhấn đúp, phím, bánh xe, CaptureLost chưa có.
void Hud::State::note_host_pointer(const HudView& view) {
    if (!host || !hub) return;
    std::string_view under;
    if (view.pointer) {
        if (const auto window = hub->hit(view.pointer->x, view.pointer->y, gui::Probe::kAny)) under = *window;
    }
    if (under != host_hover) {
        const std::string left = std::exchange(host_hover, std::string(under));
        if (!left.empty()) static_cast<void>(host->fire(left, "MouseLeave", script::MouseButton::kNone));
        if (!under.empty()) static_cast<void>(host->fire(under, "MouseEnter", script::MouseButton::kNone));
    }
    const bool is_right = view.pointer.has_value() && view.pointer->is_right_down;
    const bool is_press = is_right && !was_right_down;
    const bool is_release = !is_right && was_right_down;
    was_right_down = is_right;
    if (is_press && view.pointer) {
        host_right_press = under;
        if (!under.empty()) static_cast<void>(host->fire(under, "MouseButtonDown", script::MouseButton::kRight));
        host->pressed(script::Spot{.x = view.pointer->x, .y = view.pointer->y});
    }
    if (is_release) {
        const std::string pressed = std::exchange(host_right_press, std::string());
        if (!under.empty()) {
            static_cast<void>(host->fire(under, "MouseButtonUp", script::MouseButton::kRight));
            if (under == pressed) {
                static_cast<void>(host->fire(under, "RBClicked", script::MouseButton::kRight));
                static_cast<void>(host->fire(under, "MouseRClick", script::MouseButton::kRight));
            }
        }
    }
    drain_host_calls();
}

// Nhịp của khung cho host: đồng hồ hẹn giờ, rồi lỗi script kể từ khung trước.
void Hud::State::note_host(const HudView& view) {
    if (!host) return;
    script::Host& active = *host;
    active.set_client_size(script::ClientSize{.width = pixels_of(view.width), .height = pixels_of(view.height)});
    active.tick(view.clock);
    drain_host_calls();
    // Send_XSCRIPT của script: gói CGExecuteScript chưa có trong protocol nên chưa có chỗ gửi; ghi để nhận ra script đang đòi.
    for (const script::XScriptRecord& sent : script_context.xscript.take_sent())
        std::println(stderr, "Giao diện Lua: Send_XSCRIPT {} (script {}) chưa có đường gửi tới máy chủ", sent.function(), sent.script_id);
    for (const std::string& note : active.take_notes())
        std::println(stderr, "Giao diện Lua: {}", note);
}

// PushDebugMessage(text) của script: sự kiện NEW_DEBUGMESSAGE với arg0 là lời nhắn.
void Hud::State::push_debug_message(std::string_view text) {
    const std::array<panel::PostedEvent, 1> message{panel::PostedEvent{.name = "NEW_DEBUGMESSAGE", .args = {std::string(text)}}};
    dispatch(message);
}

// Thủ tục đăng nhập một khung: sự kiện của game tới các cửa sổ chạy bằng script, rồi nhịp của host.
// Không có host (thiếu dữ liệu script) thì không có gì để chạy.
void Hud::State::step_login(const HudView& view) {
    if (!host) return;
    dispatch(view.events);
    sync_soft_keys(view);
    note_host(view);
}

// Bàn phím ảo chạy bằng SoftKeyBoard.lua: script mở và đóng cửa sổ (OPEN_WINDOW, CLOSE_WINDOW,
// TOGGLE_WINDOW, nút đóng của layout), còn mặt phím là việc của lớp widget SoftKey
// (CEGUIFalagard.dll gốc, panel/softkey), nên bảng giữ ký tự theo cờ hiện của cửa sổ: hiện thì xoay
// vòng phím như onShown, ẩn thì đóng.
void Hud::State::sync_soft_keys(const HudView& view) {
    const bool is_shown = host->is_shown(kSoftKeyBoard);
    if (is_shown == keys.is_open) return;
    const auto salt = static_cast<std::uint32_t>(view.clock.count());
    if (is_shown) panel::open_soft_keys(keys, salt);
    if (!is_shown) panel::close_soft_keys(keys);
}

// Sự kiện của game tới từng bảng đã đăng ký nghe, rồi nhịp của host (hẹn giờ và updateSelf của
// widget).
void Hud::State::step_panels(const HudView& view) {
    update_script_facts(view);
    if (!is_app_inited) {
        // Game gốc phát APPLICATION_INITED một lần khi giao diện nạp xong.
        is_app_inited = true;
        const std::array<panel::PostedEvent, 1> inited{panel::PostedEvent{.name = "APPLICATION_INITED", .args = {}}};
        dispatch(inited);
    }
    if (view.phase != Phase::kPlay) {
        has_entered_world = false;
        step_login(view);
        return;
    }
    // CGamePro_Main::Init (Game.exe 0x140648b80) phát PLAYER_ENTERING_WORLD một lần lúc vào thủ tục
    // chơi, trước mọi sự kiện khác. Khác gốc: 0x14021d2f0 phát lại sự kiện này khi bỏ chế độ ẩn
    // giao diện (HideMain), chưa có chế độ đó.
    std::vector<panel::PostedEvent> first;
    if (!has_entered_world) {
        has_entered_world = true;
        first.push_back(panel::PostedEvent{.name = "PLAYER_ENTERING_WORLD", .args = {}});
    }
    first.insert(first.end(), trans_events.begin(), trans_events.end());
    trans_events.clear();
    first.insert(first.end(), view.events.begin(), view.events.end());
    dispatch(first);
    note_host(view);
}

// Chỉ thị của khung theo thủ tục đang chạy (thay các script Lua của client gốc). Bảng chuyển cảnh
// kê sau cùng nên nằm trên mọi bảng khác.
void Hud::State::fill_panels(const HudView& view) {
    deck.clear();
    step_panels(view);
    if (view.phase == Phase::kLogin) {
        panel::paint_flow(deck, flow, writer ? &*writer : nullptr);
        shown = panel::shown_model(flow, login_facts(view));
        panel::paint_soft_keys(deck, keys);
        if (host) host->paint(deck);
    } else {
        shown = {};
        fill_play(view);
    }
}

// Màn chơi: trạng thái lúc vào game rồi tới từng bảng. Không có nhân vật thì khung nhân vật và
// thanh kinh nghiệm giữ nguyên như layout.
void Hud::State::fill_play(const HudView& view) {
    panel::follow_here(maps, view.scene.id);
    panel::show_start(deck);
    ensure_skill_book();
    const std::span<const std::uint32_t> learned = view.hero != nullptr ? std::span<const std::uint32_t>{view.hero->skills}
                                                                        : std::span<const std::uint32_t>{};
    panel::paint_skill_bar(deck, learned, view.bar_left_ms, skill_book, item_names);
    panel::MapSeen seen;
    const std::string_view floor = panel::floor_key(maps);
    const std::string_view scene_key = floor.empty() ? view.scene.name : floor;
    seen.title = scene_names.find(scene_key).value_or(scene_key);
    const panel::PlaceText place = place_under(view);
    seen.player_x = place.across;
    seen.player_z = place.down;
    seen.watch = view.scene.watch;
    panel::fill_minimap(deck, seen);
    const int across = static_cast<int>(view.width);
    const int down = static_cast<int>(view.height);
    const std::string resolution = std::format("{},{}", across, down);
    panel::paint_maps(deck, maps, seen.title, resolution);
    panel::paint_desk(deck, desk);
    panel::paint_quest_book(deck, quests);
    if (host) host->paint(deck);
    panel::paint_main_menu_bar_3(deck, pet_bar);
    action_bars.paint(deck);
    panel::step_talk(talk, view.clock);
    for (const std::string& notice : std::exchange(talk.notices, {})) push_debug_message(notice);
    panel::paint_talk(deck, talk, view.talk_title, item_names);
    fill_board(view);
    fill_world(view);
    if (panel::is_open(desk, panel::Board::kBag)) {
        panel::paint_packet(deck, packet, item_names, view.hero != nullptr ? view.hero->purse : hero::Purse{});
    }
    panel::fill_target(deck, view.target);
    panel::fill_relive(deck, view.is_dead, view.loss);
    if (view.hero == nullptr) return;
    panel::Face face;
    face.image = portraits.image_of(view.hero->portrait);
    face.model = head_model(view.views);
    face.style = style;
    panel::fill_player(deck, *view.hero, face);
    panel::fill_menubar(deck, *view.hero);
    const bool is_sheet_open = panel::is_open(desk, panel::Board::kCharacter);
    if (!is_sheet_open) {
        equip_spin = 0.0F;
        return;
    }
    panel::fill_self_equip(deck, *view.hero, strings);
    const auto is_body = [](const ViewPaint& paint) { return paint.name == panel::kEquipModel; };
    if (!std::ranges::any_of(view.views, is_body)) return;
    deck.set(gui::Override{.window = "SelfEquip_FakeObject", .name = "FakeObject", .value = panel::kEquipModel});
}

// Đẩy ảnh atlas vừa ghép lên GPU: lần đầu thêm texture, các lần sau thay ảnh của texture đó.
core::Status Hud::State::add_map() {
    const core::Result<std::uint32_t> added = pass->add_texture(atlas.image());
    if (!added) return std::unexpected(added.error());
    map_texture = *added;
    return core::ok();
}

void Hud::State::upload_map() {
    const bool is_first = !map_texture.has_value();
    const core::Status sent = is_first ? add_map() : pass->replace_texture(map_texture.value_or(0), atlas.image());
    if (!sent) std::println(stderr, "Giao diện: không đưa được minimap lên GPU: {}", sent.error());
}

// Ngắm atlas vào vùng radar đang thấy (theo lần dàn trang vừa xong) và trả cách vẽ ảnh cảnh;
// nullopt khi layout không có radar, cảnh không có token hay chưa ô ảnh nào nạp được.
std::optional<MapPaint> Hud::State::map_of(const HudScene& scene) {
    if (!hub->radar() || scene.radar.empty()) return std::nullopt;
    RadarAim seen;
    seen.token = scene.radar;
    seen.scene_width = scene.width;
    seen.scene_depth = scene.depth;
    seen.view = hub->uv();
    if (atlas.aim(seen)) upload_map();
    if (!atlas.has_image() || !map_texture) return std::nullopt;
    const gui::Radar part = atlas.to_atlas(gui::Radar{});
    MapPaint paint;
    paint.texture = *map_texture;
    paint.origin_u = part.u0;
    paint.origin_v = part.v0;
    paint.scale_u = part.u1 - part.u0;
    paint.scale_v = part.v1 - part.v0;
    return paint;
}

// Cảnh mà bản đồ lớn đang vẽ; nullptr khi bản đồ đóng hay cảnh không có trong bảng.
const panel::SceneRow* Hud::State::board_scene_row() const noexcept {
    return maps.is_scene_open ? scenes.find(maps.chosen) : nullptr;
}

// Bản đồ lớn một khung: mở thì dựng lại tâm (SceneMap_Show), rồi cuộn, kéo, theo người chơi và đưa chỉ thị.
void Hud::State::fill_board(const HudView& view) {
    const panel::SceneRow* scene = board_scene_row();
    if (scene == nullptr) {
        is_board_open = false;
        board_scene = -1;
        return;
    }
    const panel::Where player{.x = view.scene.player_x, .z = view.scene.player_z};
    if (!is_board_open || board_scene != maps.chosen) {
        panel::open_board(board, *scene, player, maps.shows_here);
        is_board_open = true;
        board_scene = maps.chosen;
    }
    const std::optional<gui::Box> window = hub->box(panel::kBoardWindow);
    if (window) {
        const panel::BoardStep step{
            .window = *window, .pointer = view.pointer, .seconds = frame_seconds(view.clock), .player = player};
        panel::step_board(board, *scene, step);
    }
    panel::paint_board(deck, board, *scene);
}

// Bản đồ thế giới một khung: kéo, kẹp, thành đang trỏ, rồi đưa chỉ thị. Đóng thì quên trạng thái kéo và trỏ.
void Hud::State::fill_world(const HudView& view) {
    if (!maps.is_world_open) {
        world.is_dragging = false;
        world.hover = -1;
        world_press.reset();
        return;
    }
    const std::optional<gui::Box> window = hub->world();
    if (window)
        panel::step_world(world,
            panel::WorldStep{.window = *window, .pointer = view.pointer, .hits = hub->world_hits()});
    panel::paint_world(deck, world, world_cities, maps.here);
}

// Nhả chuột: một cú nhấp trái bắt đầu và kết thúc ở cùng một thành (nút hay nhãn) mà không kéo đi quá vài điểm ảnh
// thì mở bản đồ cảnh của thành đó, trừ phó bản (onClick rồi LargeMap_Click_NormalScene).
void Hud::State::note_world_release(const HudView& view) {
    const std::optional<gui::Pointer> began = world_press;
    world_press.reset();
    if (!began || !view.pointer || !maps.is_world_open) return;
    const float moved = std::max(std::abs(view.pointer->x - began->x), std::abs(view.pointer->y - began->y));
    if (moved > kClickReach) return;
    const int city = panel::city_under(hub->world_hits(), began->x, began->y);
    if (city < 0 || city != panel::city_under(hub->world_hits(), view.pointer->x, view.pointer->y)) return;
    if (!panel::is_copy_scene(city)) panel::choose_city(maps, static_cast<std::uint32_t>(city));
}

// Ảnh nền của bản đồ thế giới: texture nạp lần đầu bản đồ mở, và còn lại trong suốt phiên. Chưa mở hay thiếu ảnh
// thì không vẽ nền.
std::optional<MapPaint> Hud::State::world_of() {
    if (!maps.is_world_open) return std::nullopt;
    if (!world_texture) load_world_image();
    if (!world_texture) return std::nullopt;
    MapPaint paint;
    paint.texture = *world_texture;
    return paint;
}

void Hud::State::load_world_image() {
    if (has_world_image_failed) return;
    has_world_image_failed = true;
    const std::filesystem::path file = client_root / "Interface" / "LargeMap" / "WorldMap.png";
    const io::TextResult bytes = io::read_text(file);
    if (!bytes) {
        std::println(stderr, "Giao diện: không có ảnh bản đồ thế giới {} (TOOLS/content/export_worldmap.py)",
            io::utf8_of(file));
        return;
    }
    const core::Result<resource::Image> image = resource::decode_image(std::as_bytes(std::span(*bytes)));
    if (!image) {
        std::println(stderr, "Giao diện: ảnh bản đồ thế giới hỏng: {}", image.error());
        return;
    }
    const core::Result<std::uint32_t> added = pass->add_texture(*image);
    if (!added) {
        std::println(stderr, "Giao diện: không đưa được bản đồ thế giới lên GPU: {}", added.error());
        return;
    }
    world_texture = *added;
}

// Nhấn trái trong màn chơi: nút cuộn, nút phóng của bản đồ lớn, và điểm bắt đầu một cú nhấp lên bản đồ.
void Hud::State::note_board_press(std::string_view window, const HudView& view) {
    const panel::SceneRow* scene = board_scene_row();
    if (scene == nullptr) return;
    panel::press_board(board, window, *scene);
    if (window == panel::kBoardWindow && view.pointer) board_press = view.pointer;
}

// Nhả chuột: nút cuộn thôi giữ; cú nhấp trái không kéo đi quá vài điểm ảnh trên bản đồ thì thành lệnh đi tới.
void Hud::State::note_board_release(const HudView& view) {
    panel::release_board(board);
    const std::optional<gui::Pointer> began = board_press;
    board_press.reset();
    const panel::SceneRow* scene = board_scene_row();
    if (!began || !view.pointer || scene == nullptr || !maps.shows_here) return;
    const float moved = std::max(std::abs(view.pointer->x - began->x), std::abs(view.pointer->y - began->y));
    if (moved > kClickReach) return;
    const std::optional<gui::Box> window = hub->box(panel::kBoardWindow);
    if (!window) return;
    const gui::BoardAsk ask = panel::board_ask(board, *scene, *window);
    const gui::BoardView seen = gui::board_view(ask);
    const gui::SceneCursor cursor{.local_x = view.pointer->x - window->x, .local_y = view.pointer->y - window->y};
    const gui::SceneHit hit = gui::board_scene_at(ask, seen, cursor);
    if (hit.is_on_scene) run_to = RunTo{.x = hit.x, .z = hit.z};
}

// Hình dạng atlas của bản đồ lớn: texture cố định 2048 x 2048, ô thu nhỏ khi mức phóng nhỏ hơn mức mà
// ảnh gốc (4 điểm ảnh một đơn vị) cần để vẫn đủ nét.
namespace {
AtlasShape board_shape(float pixels) noexcept {
    int shrink = 1;
    while (shrink < kBoardMaxShrink && kRadarSourcePixels / static_cast<float>(shrink * 2) >= pixels)
        shrink *= 2;
    const int tiles = kBoardAtlasTiles * shrink;
    return AtlasShape{.across = tiles, .down = tiles, .shrink = shrink, .kept = kBoardKeptTiles};
}
} // namespace

// Ngắm atlas vào vùng bản đồ lớn đang thấy và trả cách vẽ ảnh; nullopt khi bản đồ không hiện hay chưa ô nào nạp.
std::optional<MapPaint> Hud::State::board_of() {
    const panel::SceneRow* scene = board_scene_row();
    const std::optional<gui::Box> window = hub->board();
    if (scene == nullptr || !window || scene->token.empty()) return std::nullopt;
    const gui::BoardView seen = gui::board_view(panel::board_ask(board, *scene, *window));
    if (seen.pixels <= 0.0F) return std::nullopt;
    const AtlasShape shape = board_shape(seen.pixels);
    RadarAtlas& wide =
        (board_atlas && board_atlas->shape() == shape) ? *board_atlas : board_atlas.emplace(client_root, shape);
    RadarAim aim;
    aim.token = scene->token;
    aim.scene_width = scene->width;
    aim.scene_depth = scene->depth;
    aim.view = hub->board_uv();
    if (wide.aim(aim)) upload_board(wide.image());
    if (!wide.has_image() || !board_texture) return std::nullopt;
    const gui::Radar part = wide.to_atlas(gui::Radar{});
    MapPaint paint;
    paint.texture = *board_texture;
    paint.origin_u = part.u0;
    paint.origin_v = part.v0;
    paint.scale_u = part.u1 - part.u0;
    paint.scale_v = part.v1 - part.v0;
    return paint;
}

void Hud::State::upload_board(const resource::Image& image) {
    const std::optional<std::uint32_t> known = board_texture;
    const bool is_first = !known.has_value();
    const core::Result<std::uint32_t> added = known ? core::Result<std::uint32_t>(*known) : pass->add_texture(image);
    if (!added) {
        std::println(stderr, "Giao diện: không đưa được bản đồ lớn lên GPU: {}", added.error());
        return;
    }
    if (!is_first) {
        const core::Status replaced = pass->replace_texture(*added, image);
        if (!replaced) std::println(stderr, "Giao diện: không thay được ảnh bản đồ lớn: {}", replaced.error());
        return;
    }
    board_texture = *added;
}

bool Hud::State::is_current() const noexcept {
    const bool is_same_quads = still_stamp == hub->still_stamp() && live_stamp == hub->live_stamp();
    return is_built && is_same_quads && text_stamp == hub->text_stamp() && built_scale == scale;
}

void Hud::State::rebuild() {
    const FrameParts parts{.still = hub->still(), .live = hub->live(), .texts = hub->texts()};
    PaintKit kit;
    kit.writer = writer ? &*writer : nullptr;
    kit.font_texture = font_texture;
    kit.alt_writer = vi_writer ? &*vi_writer : nullptr;
    kit.alt_font_texture = vi_font_texture;
    kit.map = map;
    kit.board = board_map;
    kit.world = world_paint;
    kit.views = views;
    kit.scale = scale;
    painter.build(loader.asset(), parts, kit);
    still_stamp = hub->still_stamp();
    live_stamp = hub->live_stamp();
    text_stamp = hub->text_stamp();
    built_scale = scale;
    is_built = true;
}

Hud::Hud(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}
Hud::Hud(Hud&&) noexcept = default;
Hud& Hud::operator=(Hud&&) noexcept = default;
Hud::~Hud() = default;

struct HudPrep::Work {
    std::future<core::Result<Prepared>> done;
};

HudPrep::HudPrep(std::unique_ptr<Work> work) noexcept : work_(std::move(work)) {}
HudPrep::HudPrep(HudPrep&&) noexcept = default;
HudPrep& HudPrep::operator=(HudPrep&&) noexcept = default;
HudPrep::~HudPrep() = default;

HudPrep HudPrep::start(const HudDesc& desc) {
    auto work = std::make_unique<Work>();
    work->done = std::async(std::launch::async,
        [root = desc.data_root, phone = desc.uses_phone_layout] { return prepare_hud(root, phone); });
    return HudPrep(std::move(work));
}

core::Result<Hud> Hud::open(render::UiPass& pass, const HudDesc& desc) {
    return open(pass, desc, HudPrep::start(desc));
}

core::Result<Hud> Hud::open(render::UiPass& pass, const HudDesc& desc, HudPrep prep) {
    core::Result<Prepared> ready = prep.work_->done.get();
    if (!ready) return std::unexpected(ready.error());
    auto state = std::make_unique<State>(*ready, pass, desc.data_root, desc.texture_tier);
    state->seat_fonts(*ready);
    state->hub = std::make_unique<gui::Hub>(state->loader.asset());
    for (const std::string& note : state->loader.notes()) {
        std::println(stderr, "Giao diện: {}", note);
    }
    state->open_host();
    return Hud(std::move(state));
}

float layout_scale(float width, float height, float density) noexcept {
    const float ceiling = density > 0.0F ? density : 1.0F;
    if (!(width > 0.0F) || !(height > 0.0F)) return ceiling;
    return std::min({width / kLayoutWidth, height / kLayoutHeight, ceiling});
}

void Hud::prepare(const HudView& screen_view) {
    State& state = *state_;
    state.scale = layout_scale(screen_view.width, screen_view.height, screen_view.density);
    const HudView view = layout_view(screen_view, state.scale);
    state.views = view.views;
    state.enter(view.phase);
    state.note_hover(view);
    state.note_press(view);
    state.note_host_pointer(view);
    state.note_text(view);
    state.note_hold(view);
    state.note_loading(view);
    state.fill_panels(view);
    // Layout mà host vừa nạp thêm: Hub dựng từ asset lúc đó nên dựng lại để có cửa sổ của nó.
    if (state.screen && state.screen->take_grown()) {
        state.hub = std::make_unique<gui::Hub>(state.loader.asset());
        state.screen->bind(state.hub.get());
        state.is_built = false;
    }
    gui::Place place;
    place.width = view.width;
    place.height = view.height;
    place.roots = state.deck.roots();
    place.hidden = state.deck.hidden();
    place.bars = state.deck.bars();
    place.overrides = state.deck.overrides();
    place.strings = &state.strings;
    // Số đo chữ của chính bộ viết chữ sẽ vẽ trang: thiếu nó thì danh sách, cửa sổ phức hợp không có
    // mục và khung cuộn chữ không cuộn.
    if (state.writer) place.meter = &*state.writer;
    place.pointer = view.pointer;
    place.scene_width = view.scene.width;
    place.scene_depth = view.scene.depth;
    place.player_x = view.scene.player_x;
    place.player_z = view.scene.player_z;
    place.player_facing = view.scene.facing;
    place.clock = view.clock;
    state.hub->update(place);
    state.map_area = state.hub->box("MiniMap_MapArea");
    state.width = view.width;
    state.height = view.height;
    const std::optional<MapPaint> map = state.map_of(view.scene);
    const bool is_same_map = same_map(state.map, map);
    state.map = map;
    const std::optional<MapPaint> board = state.board_of();
    const bool is_same_board = same_map(state.board_map, board);
    state.board_map = board;
    const std::optional<MapPaint> world = state.world_of();
    const bool is_same_world = same_map(state.world_paint, world);
    state.world_paint = world;
    if (state.is_current() && is_same_map && is_same_board && is_same_world) return;
    state.rebuild();
}

core::Status Hud::draw(gpu::CommandList& list, std::uint32_t slot, HudExtra extra) {
    State& state = *state_;
    std::span<const render::UiVertex> vertices = state.painter.vertices();
    std::span<const render::UiBatch> batches = state.painter.batches();
    if (!extra.vertices.empty()) {
        state.join(extra);
        vertices = state.joined_vertices;
        batches = state.joined_batches;
    }
    render::UiDraw frame;
    frame.list = &list;
    frame.slot = slot;
    frame.screen = render::UiScreen{.width = state.width, .height = state.height};
    frame.vertices = vertices;
    frame.batches = batches;
    return state.pass->draw(frame);
}

bool Hud::contains(float across, float down) const {
    return state_->hub->hit(across / state_->scale, down / state_->scale, gui::Probe::kAny).has_value();
}

bool Hud::takes_wheel(float across, float down) const {
    return state_->is_on_scroll(across / state_->scale, down / state_->scale);
}

float Hud::equip_spin() const noexcept {
    return state_->equip_spin;
}

std::optional<RunTo> Hud::take_run_to() noexcept {
    const std::optional<RunTo> run = state_->run_to;
    state_->run_to.reset();
    return run;
}

std::optional<std::uint32_t> Hud::take_skill_slot() noexcept {
    return std::exchange(state_->skill_press, std::nullopt);
}

std::optional<panel::talk::Place> Hud::take_revive() noexcept {
    return std::exchange(state_->revive_press, std::nullopt);
}

std::optional<gui::Pointer> Hud::window_spot(std::string_view name) const {
    const State& state = *state_;
    if (!state.hub) return std::nullopt;
    const std::optional<gui::Box> box = state.hub->box(name);
    if (!box) return std::nullopt;
    const float across = (box->x + box->w * 0.5F) * state.scale;
    const float down = (box->y + box->h * 0.5F) * state.scale;
    return gui::Pointer{.x = across, .y = down};
}

bool Hud::choose_option(std::size_t position, std::chrono::milliseconds clock) {
    panel::NpcTalk& talk = state_->talk;
    if (!talk.is_open || talk.is_waiting) return false;
    if (position >= talk.dialog.choices.size()) return false;
    const std::uint32_t index = talk.dialog.choices.at(position).index;
    panel::pick_talk_option(talk, index, clock);
    return true;
}

// Bảng tên vật phẩm đọc ở lần đầu một phần thưởng hay yêu cầu cần tên; hỏng thì thôi, phần thưởng hiện theo số mẫu.
void Hud::State::ensure_item_names() {
    if (item_names.is_loaded() || has_item_names_failed) return;
    const std::optional<table::Tsv> text = read_table(client_root / "Table" / "items.tsv");
    if (!text || !item_names.load_table(*text, true)) {
        has_item_names_failed = true;
        std::println(stderr, "Hộp thoại: không đọc được Table/items.tsv, phần thưởng hiện theo số mẫu");
        return;
    }
    // Trang bị, bảo thạch và vật phẩm hoạt động không có trong items.tsv. Thiếu tệp thì ô đó dùng ảnh thay.
    const auto take = [this](const char* file) {
        const std::optional<table::Tsv> extra = read_table(client_root / "Table" / file);
        if (!extra || !item_names.load_table(*extra, false)) {
            std::println(stderr, "Hòm đồ: không đọc được Table/{}, mẫu ở bảng đó không có tên", file);
        }
    };
    take("equips.tsv");
    take("gems.tsv");
    take("campaign_items.tsv");
    const io::TextResult icons = io::read_text(client_root / "Table" / "icons.tsv");
    if (!icons || !item_names.load_icons(*icons)) {
        std::println(stderr, "Hòm đồ: không đọc được Table/icons.tsv, icon vật phẩm dùng ảnh thay");
    }
}

// Bảng kỹ năng và bảng icon cho mười ô MainMenuBar. Thiếu tệp thì ô vẫn bấm được, ảnh là set:X image:X.
void Hud::State::ensure_skill_book() {
    if (!skill_book.is_loaded() && !has_skill_book_failed) {
        const std::optional<table::Tsv> text = read_table(client_root / "Table" / "skills.tsv");
        if (!text || !skill_book.load_table(*text)) {
            has_skill_book_failed = true;
            std::println(stderr, "Thanh kỹ năng: không đọc được Table/skills.tsv, ô dùng ảnh thay");
        }
    }
    if (item_names.has_icons() || has_skill_icons_failed) return;
    const io::TextResult icons = io::read_text(client_root / "Table" / "icons.tsv");
    if (!icons || !item_names.load_icons(*icons)) {
        has_skill_icons_failed = true;
        std::println(stderr, "Thanh kỹ năng: không đọc được Table/icons.tsv, icon dùng ảnh thay");
    }
}

void Hud::deliver_talk(const panel::talk::Hear& heard) {
    struct Apply {
        State* state;
        void operator()(const panel::talk::Dialog& dialog) const {
            const auto is_item = [](const panel::talk::Bonus& bonus) { return bonus.kind != panel::talk::BonusKind::kMoney; };
            if (std::ranges::any_of(dialog.bonuses, is_item)) state->ensure_item_names();
            panel::open_talk(state->talk, dialog);
        }
        void operator()(const panel::talk::Closed& closed) const { panel::close_talk(state->talk, closed); }
        void operator()(const panel::talk::Refused& refused) const { panel::refuse_talk(state->talk, refused.why); }
        void operator()(const panel::talk::Book& book) const { state->quests.log = panel::log_of(book); }
        void operator()(const panel::talk::Notice& notice) const {
            if (notice.kind == panel::talk::NoticeKind::kRewardItem) state->ensure_item_names();
            panel::note_notice(state->talk, notice, state->item_names);
        }
        // Cấp, kinh nghiệm và tiền thuộc về hero của Display (Display::State::apply_stats); HUD không giữ bản nào.
        void operator()(const panel::talk::Stats& /*stats*/) const {}
        // Chiêu thức (sinh lực thật, kỹ năng, hồi chiêu, cái chết, lời từ chối) thuộc về Display::State (graphic/fight.cpp):
        // nó lọc những tin này trước khi đưa cho HUD, nên đây chỉ để visit phủ hết các loại.
        void operator()(const panel::talk::Vitals& /*vitals*/) const {}
        void operator()(const panel::talk::Skills& /*skills*/) const {}
        void operator()(const panel::talk::Cooldown& /*cooldown*/) const {}
        void operator()(const panel::talk::Slain& /*slain*/) const {}
        void operator()(const panel::talk::Declined& /*declined*/) const {}
        // Ảnh chụp thay cả túi. Đóng hòm không xoá bản này: máy chủ chỉ gửi lại khi túi đổi.
        void operator()(const panel::talk::Bag& bag) const {
            state->ensure_item_names();
            state->packet.bag = bag;
        }
    };
    std::visit(Apply{state_.get()}, heard);
}

void Hud::say(const panel::talk::Say& said) {
    state_->talk.says.push_back(said);
}

std::vector<panel::talk::Say> Hud::take_says() noexcept {
    return std::exchange(state_->talk.says, {});
}

std::optional<std::uint32_t> Hud::talking_with() const noexcept {
    if (!state_->talk.is_open) return std::nullopt;
    return state_->talk.dialog.npc;
}

void Hud::drop_talk() noexcept {
    panel::drop_talk(state_->talk);
}

std::optional<Action> Hud::take_action() noexcept {
    if (state_->asked) {
        const Action asked = *state_->asked;
        state_->asked.reset();
        return asked;
    }
    return panel::take_flow(state_->flow);
}

bool Hud::recall_last_server(std::string_view text) {
    panel::recall_last(state_->flow, text);
    return true;
}

std::optional<std::string> Hud::last_server_text() const {
    return panel::last_text(state_->flow);
}

void Hud::mark_last_server_saved() noexcept {
    panel::mark_last_saved(state_->flow);
}

bool Hud::recall_roles(std::string_view text) {
    return panel::recall_book(state_->flow, text);
}

std::optional<std::string> Hud::roles_text() const {
    return panel::book_text(state_->flow);
}

void Hud::mark_roles_saved() noexcept {
    panel::mark_saved(state_->flow);
}

const panel::Role* Hud::entering_role() const noexcept {
    return panel::entering_role(state_->flow);
}

void Hud::set_online_servers(std::span<const panel::ServerName> names) {
    panel::mark_online(state_->flow, names);
}

std::vector<panel::OnlineAsk> Hud::take_online_asks() noexcept {
    return panel::take_asks(state_->flow);
}

void Hud::deliver_online(const panel::OnlineReply& reply) {
    if (reply.kind == panel::OnlineReply::Kind::kStyle) {
        state_->style = reply.style;
        return;
    }
    panel::LoginFacts facts;
    facts.cast = &state_->cast;
    facts.portraits = &state_->portraits;
    facts.words = &state_->strings;
    panel::deliver_online(state_->flow, reply, facts);
}

const panel::ShownModel& Hud::role_model() const noexcept {
    return state_->shown;
}

Hud::ExtraFont Hud::extra_font() const noexcept {
    if (!state_->font) return {};
    return ExtraFont{.font = &*state_->font, .texture = state_->font_texture};
}

std::string_view Hud::skill_name(std::uint32_t skill) {
    if (skill > static_cast<std::uint32_t>(std::numeric_limits<std::int32_t>::max())) return {};
    state_->ensure_skill_book();
    return state_->skill_book.name(static_cast<std::int32_t>(skill));
}

std::size_t Hud::quad_count() const noexcept {
    return state_->painter.vertices().size() / 4;
}

std::size_t Hud::missing_count() const noexcept {
    return state_->painter.missing();
}

} // namespace game::ui
