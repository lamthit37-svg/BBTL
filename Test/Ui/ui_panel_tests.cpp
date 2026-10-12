// Chỉ thị của HUD (ui/panel): Deck giữ đúng thứ tự gốc và chép giá trị; các bảng (khung nhân vật,
// minimap, thanh chính) ghi đúng lời gọi của script gốc; bảng chân dung; và mọi tên cửa sổ các bảng
// nêu đều có thật trong layout của client 2026.
#include "ui/panel/deck.hpp"

#include "core/check.hpp"
#include "gui/asset.hpp"
#include "gui/loader.hpp"
#include "gui/sheet.hpp"
#include "hero/hero.hpp"
#include "io/file.hpp"
#include "table/tsv.hpp"
#include "test.hpp"
#include "ui/panel/desk.hpp"
#include "ui/panel/maps.hpp"
#include "ui/panel/menubar.hpp"
#include "ui/panel/minimap.hpp"
#include "ui/panel/player_frame.hpp"
#include "ui/panel/portraits.hpp"
#include "ui/panel/start.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <filesystem>
#include <optional>
#include <span>
#include <string>
#include <string_view>

namespace game::test {
namespace {

using ui::panel::Deck;
using ui::panel::Key;

// Thư mục dữ liệu client mà bản dựng biết; rỗng thì ca đối chiếu layout thật tự bỏ qua.
#ifdef GAME_CLIENT_DATA
constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
constexpr std::string_view kClientData;
#endif

bool near_fill(float value, float expect) {
    return std::fabs(value - expect) < 0.0001F;
}

void deck_keeps_root_order(Context& context) {
    Deck deck;
    deck.show("PlayerFrame");
    deck.show("Packet_Frame");
    deck.show("PlayerFrame");
    const std::span<const std::string_view> roots = deck.roots();
    context.expect(roots.size() == 2, "kê lại một gốc thì không thêm");
    if (roots.size() != 2) return;
    context.expect(roots[0] == "PlayerFrame" && roots[1] == "Packet_Frame", "gốc kê sau nằm sau");
    context.expect(deck.is_shown("Packet_Frame") && !deck.is_shown("Quest_Frame"), "tra gốc");
}

void deck_copies_values(Context& context) {
    Deck deck;
    std::string name = "Tiêu Phong";
    deck.set({.window = "PlayerFrame_Name", .name = "Text", .value = name});
    name = "đã đổi";
    deck.bar("PlayerFrame_HP", 0.25F);
    deck.hide("PlayerFrame_Captain");
    const std::span<const gui::Override> said = deck.overrides();
    context.expect(said.size() == 1, "một thuộc tính");
    if (said.size() != 1) return;
    context.expect(said[0].value == "Tiêu Phong", "giá trị được chép, không mượn người gọi");
    context.expect(said[0].window == "PlayerFrame_Name" && said[0].name == "Text", "tên giữ nguyên");
    context.expect(deck.bars().size() == 1 && deck.bars()[0].amount == 0.25F, "thanh");
    context.expect(deck.hidden().size() == 1, "cửa sổ bị giấu");
    deck.clear();
    const bool is_empty = deck.roots().empty() && deck.hidden().empty() && deck.bars().empty();
    context.expect(is_empty && deck.overrides().empty(), "clear bỏ hết chỉ thị");
    deck.set({.window = "PlayerFrame_Level", .name = "Text", .value = "90"});
    const std::span<const gui::Override> again = deck.overrides();
    context.expect(again.size() == 1 && again[0].value == "90", "dùng lại chỗ cũ sau clear");
}

// Giá trị cuối cùng đặt cho một thuộc tính trong khung này; nullopt khi bảng không đặt.
std::optional<std::string_view> said(Deck& deck, const Key& key) {
    std::optional<std::string_view> value;
    for (const gui::Override& item : deck.overrides()) {
        const bool is_mine = item.window == key.window && item.name == key.name;
        value = is_mine ? std::optional(item.value) : value;
    }
    return value;
}

bool is_hidden(const Deck& deck, std::string_view window) {
    return std::ranges::contains(deck.hidden(), window);
}

// Mức đặt cho một thanh; -1 khi bảng không đặt.
float bar_of(const Deck& deck, std::string_view window) {
    const auto is_mine = [window](const gui::Bar& bar) { return bar.window == window; };
    const auto found = std::ranges::find_if(deck.bars(), is_mine);
    return found == deck.bars().end() ? -1.0F : found->amount;
}

void deck_composes_in_place(Context& context) {
    Deck deck;
    std::string& first = deck.compose(Key{.window = "MiniMap_Coordinate", .name = "Text"});
    first.append("160  94");
    deck.reveal("PlayerFrame_Head_2D");
    const Key place{.window = "MiniMap_Coordinate", .name = "Text"};
    const Key shown{.window = "PlayerFrame_Head_2D", .name = "Visible"};
    context.expect(said(deck, place) == "160  94", "chuỗi ghi thẳng vào bộ đệm");
    context.expect(said(deck, shown) == "True", "reveal đặt Visible");
    deck.clear();
    const std::string& again = deck.compose(place);
    context.expect(again.empty(), "bộ đệm dùng lại đã được xoá");
    context.expect(again.capacity() >= 7, "sức chứa của khung trước còn giữ");
}

constexpr Key kName{.window = "PlayerFrame_Name", .name = "Text"};
constexpr Key kLevel{.window = "PlayerFrame_Level", .name = "Text"};
constexpr Key kFace{.window = "PlayerFrame_Head_3D", .name = "Image"};
constexpr Key kFlat{.window = "PlayerFrame_Head_2D", .name = "Image"};
constexpr Key kRing{.window = "PlayerFrame_TypeFrame_2D", .name = "SetCurrentImage"};
constexpr Key kFlash{.window = "PlayerFrame_HP_Flash", .name = "Size"};
constexpr std::string_view kGirl = "set:GirlProtagonist image:GirlProtagonist_1";

// Nhân vật mới: thanh đầy, nộ rỗng, không điểm liên kích, không cảnh báo máu, có chân dung.
void player_frame_of_newcomer(Context& context) {
    const hero::Hero hero = hero::newcomer();
    Deck deck;
    ui::panel::fill_player(deck, hero, ui::panel::Face{.image = kGirl, .model = {}});
    context.expect(bar_of(deck, "PlayerFrame_HP") == 1.0F, "máu đầy");
    context.expect(bar_of(deck, "PlayerFrame_MP") == 1.0F, "khí đầy");
    context.expect(bar_of(deck, "PlayerFrame_SP") == 0.0F, "nộ rỗng");
    context.expect(said(deck, kName) == "#cDED784#{GMGameInterface_Script_Talk_Info_R_Man}", "tên màu vàng");
    context.expect(said(deck, kLevel) == "#cDED7841", "cấp màu vàng");
    context.expect(is_hidden(deck, "PlayerFrame_DoubleHit1"), "chưa có điểm liên kích");
    context.expect(is_hidden(deck, "PlayerFrame_DoubleHit9"), "ô liên kích cuối");
    context.expect(is_hidden(deck, "PlayerFrame_Captain"), "không phải đội trưởng");
    const bool is_calm = is_hidden(deck, "PlayerFrame_Mask") && is_hidden(deck, "PlayerFrame_HP_Flash");
    context.expect(is_calm && !said(deck, kFlash), "máu đủ thì không cảnh báo");
    context.expect(said(deck, kFace) == kGirl, "chân dung gán vào cửa sổ trong khung tròn");
    context.expect(!said(deck, kFlat) && !said(deck, kRing), "ô phẳng và vòng 2D giữ ẩn");
    context.expect(is_hidden(deck, "PlayerFrame_GQ"), "thanh của môn phái mới bị giấu");
    context.expect(is_hidden(deck, "PlayerFrame_PVPPK"), "không ở trạng thái PK");
}

// Có đầu 3D thì cửa sổ mô hình nhận tên fake object (như SetFakeObject), không nhận ảnh phẳng.
void player_frame_prefers_model(Context& context) {
    const hero::Hero hero = hero::newcomer();
    const Key model{.window = "PlayerFrame_Head_3D", .name = "FakeObject"};
    Deck deck;
    const ui::panel::Face both{.image = kGirl, .model = ui::panel::kPlayerHead};
    ui::panel::fill_player(deck, hero, both);
    context.expect(said(deck, model) == "Player_Head", "cửa sổ mô hình nhận tên fake object");
    context.expect(!said(deck, kFace), "có đầu 3D thì không gán ảnh phẳng");
    deck.clear();
    ui::panel::fill_player(deck, hero, ui::panel::Face{.image = kGirl, .model = {}});
    context.expect(!said(deck, model) && said(deck, kFace) == kGirl, "chưa có đầu 3D: ảnh phẳng");
}

// Máu đúng một phần năm là thấp (bản gốc so HP / MAXHP > 1/5), hơn một điểm thì hết.
void player_frame_warns_low_health(Context& context) {
    hero::Hero hero = hero::newcomer();
    hero.health.now = 117;
    hero.strike_points = 3;
    hero.is_leader = true;
    Deck deck;
    ui::panel::fill_player(deck, hero, ui::panel::Face{});
    context.expect(!is_hidden(deck, "PlayerFrame_Mask"), "lớp đỏ hiện");
    context.expect(!is_hidden(deck, "PlayerFrame_HP_Flash"), "cửa sổ nháy hiện");
    context.expect(said(deck, kFlash) == "w:0.2 h:1", "nháy phủ đúng phần máu còn lại");
    context.expect(near_fill(bar_of(deck, "PlayerFrame_HP"), 0.2F), "thanh máu một phần năm");
    const bool is_three = !is_hidden(deck, "PlayerFrame_DoubleHit3") && is_hidden(deck, "PlayerFrame_DoubleHit4");
    context.expect(is_three, "ba điểm liên kích sáng");
    context.expect(!is_hidden(deck, "PlayerFrame_Captain"), "đội trưởng có dấu");
    context.expect(!said(deck, kFace) && !said(deck, kFlat), "không ảnh thì ô mặt để trống");
    hero.health.now = 118;
    hero.strike_points = 200;
    deck.clear();
    ui::panel::fill_player(deck, hero, ui::panel::Face{});
    context.expect(is_hidden(deck, "PlayerFrame_Mask"), "trên một phần năm thì hết cảnh báo");
    context.expect(!is_hidden(deck, "PlayerFrame_DoubleHit9"), "điểm quá trần thì sáng cả chín ô");
}

constexpr Key kTitle{.window = "MiniMap_Placename", .name = "Text"};
constexpr Key kTitleFont{.window = "MiniMap_Placename", .name = "Font"};
constexpr Key kPlace{.window = "MiniMap_Coordinate", .name = "Text"};
constexpr Key kWatch{.window = "MiniMap_ChineseTime", .name = "SetCurrentImage"};

void minimap_texts(Context& context) {
    ui::panel::MapSeen seen;
    seen.title = "Tô Châu";
    seen.player_x = 160.9F;
    seen.player_z = 94.2F;
    Deck deck;
    ui::panel::fill_minimap(deck, seen);
    context.expect(said(deck, kTitle) == "#gFF0FA0Tô Châu", "tên cảnh mang thẻ màu");
    context.expect(said(deck, kTitleFont) == "YouYuan9.75", "tên ngắn dùng phông lớn");
    context.expect(said(deck, kPlace) == "#cFDFF73160  94", "toạ độ cắt phần lẻ");
    context.expect(said(deck, kWatch) == "Time1", "giờ Tý");
    const bool is_first_lit = !is_hidden(deck, "MiniMap_TimeDot1") && is_hidden(deck, "MiniMap_TimeDot2") &&
        is_hidden(deck, "MiniMap_TimeDot12");
    context.expect(is_first_lit && deck.hidden().size() == 11, "chỉ chấm của giờ Tý sáng");
    seen.title = "Yên Vương Cổ Mộ Tầng 7";
    seen.player_x = -0.5F;
    seen.player_z = std::nanf("");
    seen.watch = 200;
    deck.clear();
    ui::panel::fill_minimap(deck, seen);
    context.expect(said(deck, kTitleFont) == "SongTiBmp12", "tên dài dùng phông gọn");
    context.expect(said(deck, kPlace) == "#cFDFF730  0", "toạ độ hỏng thành 0");
    const bool is_last_lit = !is_hidden(deck, "MiniMap_TimeDot12") && is_hidden(deck, "MiniMap_TimeDot1") &&
        is_hidden(deck, "MiniMap_TimeDot11");
    context.expect(said(deck, kWatch) == "Time12" && is_last_lit, "canh giờ quá trần là Hợi");
    seen.title = {};
    deck.clear();
    ui::panel::fill_minimap(deck, seen);
    context.expect(!said(deck, kTitle) && !said(deck, kTitleFont), "không tên thì để trống");
}

void minimap_hover(Context& context) {
    ui::panel::Hover hover;
    hover.player_x = 40.0F;
    hover.player_z = 70.0F;
    const ui::panel::PlaceText away = ui::panel::coordinate_of(hover);
    context.expect(away.across == 40.0F && away.down == 70.0F && !away.is_inside, "rời map");
    hover.is_inside = true;
    hover.is_on_scene = true;
    hover.scene_x = 12.5F;
    hover.scene_z = 8.0F;
    const ui::panel::PlaceText over = ui::panel::coordinate_of(hover);
    context.expect(over.across == 12.5F && over.down == 8.0F && over.is_inside, "trên cảnh");
    hover.is_on_scene = false;
    hover.was_inside = false;
    const ui::panel::PlaceText entered = ui::panel::coordinate_of(hover);
    context.expect(entered.across == 0.0F && entered.down == 0.0F, "vừa vào mà ngoài cảnh");
    hover.was_inside = true;
    hover.held_x = 12.5F;
    hover.held_z = 8.0F;
    const ui::panel::PlaceText kept = ui::panel::coordinate_of(hover);
    context.expect(kept.across == 12.5F && kept.down == 8.0F, "đang trên map thì giữ số cũ");
}

void menubar_experience(Context& context) {
    hero::Hero hero = hero::newcomer();
    hero.experience.now = 45;
    Deck deck;
    ui::panel::fill_menubar(deck, hero);
    context.expect(bar_of(deck, "MainMenuBar_EXP2") == 0.5F, "45 trên 90 là nửa thanh");
}

table::Tsv portrait_table() {
    table::Tsv table;
    table.header = {"id", "race", "image"};
    table.rows = {
        {"2", "0", "set:GirlProtagonist image:GirlProtagonist_2"},
        {"61", "1", "set:ManProtagonist image:ManProtagonist_1"},
        {"1", "0", "set:GirlProtagonist image:GirlProtagonist_1"},
        {"x", "0", "set:GirlProtagonist image:GirlProtagonist_9"},
        {"7", "0", "GirlProtagonist_7"},
        {"1", "0", "set:GirlProtagonist3 image:GirlProtagonist3_1"},
    };
    return table;
}

void portraits_lookup(Context& context) {
    const ui::panel::Portraits portraits = ui::panel::Portraits::from_table(portrait_table());
    context.expect(portraits.size() == 3, "dòng hỏng và id lặp bị bỏ");
    const std::string_view first = portraits.image_of(hero::PortraitId{1});
    context.expect(first == "set:GirlProtagonist image:GirlProtagonist_1", "id lặp: dòng trước thắng");
    const std::string_view man = portraits.image_of(hero::PortraitId{61});
    context.expect(man == "set:ManProtagonist image:ManProtagonist_1", "tra theo id");
    context.expect(portraits.image_of(hero::PortraitId{7}).empty(), "ảnh sai dạng không vào bảng");
    context.expect(portraits.image_of(hero::PortraitId{999}).empty(), "id lạ thì rỗng");
    const std::span<const std::string> sets = portraits.imagesets();
    const bool is_listed = sets.size() == 3 && sets[0] == "GirlProtagonist" && sets[1] == "ManProtagonist" &&
        sets[2] == "GirlProtagonist3";
    context.expect(is_listed, "bộ ảnh không lặp, theo thứ tự gặp");
    table::Tsv bare;
    bare.header = {"id", "race"};
    context.expect(ui::panel::Portraits::from_table(bare).size() == 0, "thiếu cột thì rỗng");
}

constexpr std::array<std::string_view, 7> kLayouts = {
    "PlayerFrame/PlayerFrame.layout.xml",
    "MiniMap/MiniMap.layout.xml",
    "MainMenuBar/MainMenuBar.layout.xml",
    "ChatFrame/ChatFrame.layout.xml",
    "FunctionBarRight/FunctionBarRight.layout.xml",
    "TargetFrame/TargetFrame.layout.xml",
    "AutoAttack_Button/AutoAttack_Button.layout.xml",
};

bool has_window(const gui::GuiAsset& asset, std::string_view name) {
    const auto is_named = [name](const gui::GuiWindow& window) { return window.name == name; };
    return std::ranges::any_of(asset.windows, is_named);
}

// Mỗi tên trong trạng thái lúc vào game phải là một cửa sổ có thật: gõ sai tên thì cửa sổ đáng lẽ
// bị giấu sẽ hiện mà không báo gì.
void start_names_exist(Context& context) {
    if (kClientData.empty()) return;
    const std::filesystem::path root = std::filesystem::path(kClientData) / "Interface";
    const gui::DiskSource files(root);
    gui::GuiSources sources;
    sources.files = &files;
    auto loader = gui::GuiLoader::open(sources);
    context.expect(loader.has_value(), "mở được giao diện của kho");
    if (!loader) return;
    for (const std::string_view layout : kLayouts)
        context.expect(loader->add_layout(layout).has_value(), layout);
    Deck deck;
    ui::panel::show_start(deck);
    const gui::GuiAsset& asset = loader->asset();
    for (const std::string_view root_name : deck.roots())
        context.expect(has_window(asset, root_name), root_name);
    for (const std::string_view hidden : deck.hidden())
        context.expect(has_window(asset, hidden), hidden);
    context.expect(deck.is_shown("PlayerFrame") && deck.is_shown("MiniMap_Frame"), "khung chính");
    context.expect(!deck.is_shown("TargetFrame"), "khung mục tiêu chờ có mục tiêu");
}

// Mọi cửa sổ mà các bảng giấu, đặt thuộc tính hay đặt thanh phải có thật trong layout: gõ sai tên
// thì lời gọi rơi vào khoảng không mà không báo gì. Nhân vật máu thấp để mọi nhánh đều ghi tên.
void panel_names_exist(Context& context) {
    if (kClientData.empty()) return;
    const std::filesystem::path root = std::filesystem::path(kClientData) / "Interface";
    const gui::DiskSource files(root);
    gui::GuiSources sources;
    sources.files = &files;
    auto loader = gui::GuiLoader::open(sources);
    context.expect(loader.has_value(), "mở được giao diện của kho");
    if (!loader) return;
    for (const std::string_view layout : kLayouts)
        context.expect(loader->add_layout(layout).has_value(), layout);
    hero::Hero hero = hero::newcomer();
    hero.health.now = 1;
    ui::panel::MapSeen seen;
    seen.title = "Lạc Dương";
    Deck deck;
    ui::panel::fill_player(deck, hero, ui::panel::Face{.image = kGirl, .model = {}});
    ui::panel::fill_menubar(deck, hero);
    ui::panel::fill_minimap(deck, seen);
    const gui::GuiAsset& asset = loader->asset();
    for (const std::string_view hidden : deck.hidden())
        context.expect(has_window(asset, hidden), hidden);
    for (const gui::Bar& bar : deck.bars())
        context.expect(has_window(asset, bar.window), bar.window);
    for (const gui::Override& item : deck.overrides())
        context.expect(has_window(asset, item.window), item.window);
}

// Bảng chân dung của kho: nhân vật mới có ảnh, và bộ ảnh của nó nạp được vào giao diện.
void real_portrait_is_loadable(Context& context) {
    if (kClientData.empty()) return;
    const std::filesystem::path data = std::filesystem::path(kClientData);
    const io::TextResult text = io::read_text(data / "Table" / "portraits.tsv");
    context.expect(text.has_value(), "có Table/portraits.tsv");
    if (!text) return;
    const table::TsvResult table = table::parse_tsv(*text);
    context.expect(table.has_value(), "bảng chân dung đọc được");
    if (!table) return;
    const ui::panel::Portraits portraits = ui::panel::Portraits::from_table(*table);
    context.expect(portraits.size() == 150, "150 chân dung như CharacterFace.txt");
    const std::string_view image = portraits.image_of(hero::newcomer().portrait);
    context.expect(image == kGirl, "chân dung của nhân vật mới");
    const gui::DiskSource files(data / "Interface");
    gui::GuiSources sources;
    sources.files = &files;
    auto loader = gui::GuiLoader::open(sources);
    if (!loader) return;
    for (const std::string& imageset : portraits.imagesets())
        loader->add_imageset(imageset);
    const auto is_girl = [](const gui::GuiImage& item) { return item.name == "GirlProtagonist_1"; };
    context.expect(std::ranges::any_of(loader->asset().images, is_girl), "ảnh chân dung vào asset");
    context.expect(loader->notes().empty(), "mọi bộ ảnh chân dung đều có");
}

void map_toggle_and_floors(Context& context) {
    ui::panel::Maps maps;
    ui::panel::follow_here(maps, 251);
    ui::panel::press_map(maps, "MiniMap_Plot");
    context.expect(maps.is_scene_open && !maps.is_world_open, "nút bản đồ cảnh mở bảng");
    context.expect(maps.chosen == 251 && maps.group < 0, "cảnh thường không có tầng");
    ui::panel::press_map(maps, "MiniMap_Plot");
    context.expect(!maps.is_scene_open, "bấm lần nữa thì đóng");
    ui::panel::press_map(maps, "MiniMap_WorldMap");
    context.expect(maps.is_world_open && !maps.is_scene_open, "nút mắt mở bản đồ thế giới");
    ui::panel::press_map(maps, "LargeMap_Qiehuan");
    context.expect(maps.is_scene_open && !maps.is_world_open, "nút đổi về bản đồ cảnh");
    ui::panel::SceneAsk other;
    other.order = ui::panel::MapToggle::kOther;
    other.scene_id = 242;
    other.here = 0;
    ui::panel::note_scene(maps, other);
    context.expect(maps.chosen == 0 && !maps.shows_here, "tuyết Lạc Dương ghi thành id 0");
    ui::panel::choose_city(maps, ui::panel::kNoCity);
    context.expect(maps.chosen == 0, "không có thành thì giữ nguyên");
    ui::panel::choose_city(maps, 166);
    context.expect(maps.is_scene_open && maps.group == 1 && maps.floor == 0, "Bảo Tàng Động tầng 1");
    ui::panel::pick_floor(maps, 2);
    context.expect(maps.chosen == 169 && maps.floor == 1, "combo chọn tầng 2");
    ui::panel::follow_here(maps, 251);
    context.expect(!maps.is_scene_open, "đổi cảnh thì đóng bản đồ lớn");
}

void map_zoom_and_paint(Context& context) {
    context.expect(ui::panel::clamped_zoom(3) == 2, "zoom 3 kẹp về 2");
    context.expect(ui::panel::clamped_zoom(5) == -1, "zoom ngoài 0..4 thì bỏ");
    context.expect(ui::panel::label_is_inset("800,600"), "800 thì kéo chữ vào");
    context.expect(!ui::panel::label_is_inset("1920,1080"), "1920 thì chữ rộng");
    context.expect(ui::panel::label_is_inset("800x600"), "không đọc được số thì kéo vào");
    Deck deck;
    ui::panel::Maps shown;
    ui::panel::follow_here(shown, 166);
    ui::panel::press_map(shown, "MiniMap_Plot");
    ui::panel::paint_maps(deck, shown, "Lạc Dương", "800,600");
    context.expect(deck.is_shown("SceneMap_Frame"), "bản đồ lớn hiện");
    context.expect(is_hidden(deck, "LargeMapFrame"), "bản đồ thế giới giấu");
    context.expect(!is_hidden(deck, "sceneMap_ComboList"), "tầng thì hiện danh sách");
    const auto is_title = [](const gui::Override& item) { return item.window == "SceneMap_SceneName"; };
    const auto title = std::ranges::find_if(deck.overrides(), is_title);
    context.expect(title != deck.overrides().end(), "có tên cảnh");
    if (title == deck.overrides().end()) return;
    context.expect(title->value.starts_with("#gFF0FA0"), "tên có màu của script");
}

constexpr std::array kBoards{ui::panel::Board::kCharacter, ui::panel::Board::kBag, ui::panel::Board::kQuest};

// Nút của thanh menu chính đảo bảng của nó, nút đóng thì đóng, như ba script gốc.
void desk_toggles_from_menubar(Context& context) {
    using ui::panel::Board;
    using ui::panel::is_open;
    ui::panel::Desk desk;
    context.expect(!is_open(desk, Board::kCharacter), "lúc đầu mọi bảng đều đóng");
    ui::panel::press_desk(desk, "Button_Character");
    context.expect(is_open(desk, Board::kCharacter), "nút nhân vật mở bảng nhân vật");
    context.expect(!is_open(desk, Board::kBag), "bảng khác không đổi");
    ui::panel::press_desk(desk, "Button_Character");
    context.expect(!is_open(desk, Board::kCharacter), "bấm lần nữa thì đóng");
    ui::panel::press_desk(desk, "Packet_Close");
    context.expect(!is_open(desk, Board::kBag), "nút đóng không mở bảng đang đóng");
    ui::panel::press_desk(desk, "Button_Pack");
    ui::panel::press_desk(desk, "Button_Mission");
    const bool is_bag_open = is_open(desk, Board::kBag);
    context.expect(is_bag_open && is_open(desk, Board::kQuest), "hai bảng mở cùng lúc được");
    ui::panel::press_desk(desk, "Packet_Close");
    context.expect(!is_open(desk, Board::kBag), "nút đóng của thùng đồ");
    context.expect(is_open(desk, Board::kQuest), "đóng thùng đồ không đóng nhiệm vụ");
    ui::panel::press_desk(desk, "QuestLog_Close");
    ui::panel::press_desk(desk, "Button_Action1");
    ui::panel::press_desk(desk, "MiniMap_Plot");
    const auto is_shut = [&desk](Board board) { return !is_open(desk, board); };
    context.expect(std::ranges::all_of(kBoards, is_shut), "nút không thuộc bàn không mở gì");
    ui::panel::press_desk(desk, "MiniMap_Yuanbao");
    context.expect(is_open(desk, Board::kShop), "nút nguyên bảo mở thương thành");
    ui::panel::press_desk(desk, "MiniMap_Yuanbao");
    context.expect(!is_open(desk, Board::kShop), "bấm lần nữa thì đóng thương thành");
    ui::panel::press_desk(desk, "Button_System");
    context.expect(is_open(desk, Board::kSystem), "nút hệ thống mở menu");
    ui::panel::press_desk(desk, "Operation_System");
    context.expect(is_open(desk, Board::kView), "nút hình ảnh mở trang hình");
    context.expect(!is_open(desk, Board::kSystem), "mở trang cài đặt thì đóng menu");
    ui::panel::press_desk(desk, "ViewSetup_MenuBox_SoundSetup");
    context.expect(is_open(desk, Board::kSound) && !is_open(desk, Board::kView), "thẻ âm thanh đổi trang");
    ui::panel::press_desk(desk, "Operation_BackGame");
    context.expect(!is_open(desk, Board::kSystem), "trở lại đóng menu hệ thống");
    ui::panel::press_desk(desk, "Button_System");
    const bool is_menu = is_open(desk, Board::kSystem) && !is_open(desk, Board::kSound);
    context.expect(is_menu, "mở menu thì đóng trang cài đặt");
    ui::panel::press_desk(desk, "Operation_QuitGame");
    context.expect(is_open(desk, Board::kSystem), "nút thoát không tự đóng menu");
}

// Sách kỹ năng, trân thú, hảo hữu, tổ đội và lời nhắc bang hội.
void desk_wires_the_menu(Context& context) {
    using ui::panel::Board;
    using ui::panel::is_open;
    ui::panel::Desk desk;
    ui::panel::press_desk(desk, "Button_Skills");
    context.expect(is_open(desk, Board::kCommon), "nút kỹ năng mở trang phổ thông");
    ui::panel::press_desk(desk, "CommonSkill_LifeSkill");
    const bool is_life = is_open(desk, Board::kLife) && !is_open(desk, Board::kCommon);
    context.expect(is_life, "thẻ sinh hoạt đổi trang");
    ui::panel::press_desk(desk, "LifeSkill_ActionSkill");
    context.expect(desk.notice == ui::panel::Notice::kNoSect, "vô phái thì không mở môn phái");
    context.expect(is_open(desk, Board::kLife), "trang đang mở giữ nguyên");
    ui::panel::press_desk(desk, "Button_Skills");
    context.expect(!is_open(desk, Board::kLife), "nút kỹ năng đóng mọi trang");
    ui::panel::press_desk(desk, "Button_Pet");
    ui::panel::press_desk(desk, "Button_Friend");
    ui::panel::press_desk(desk, "Friend_List_Page3");
    ui::panel::press_desk(desk, "Button_Team");
    const bool is_people = is_open(desk, Board::kPet) && is_open(desk, Board::kFriend);
    context.expect(is_people && is_open(desk, Board::kTeam), "trân thú, hảo hữu và tổ đội");
    context.expect(desk.friend_page == 3, "trang hảo hữu thứ ba");
    ui::panel::press_desk(desk, "Button_Exchange");
    context.expect(is_open(desk, Board::kPet), "giao dịch không đóng bảng đang mở");
    ui::panel::press_desk(desk, "Button_Reputation");
    context.expect(desk.notice == ui::panel::Notice::kNoGuild, "chưa có bang thì có lời nhắc");
}

void desk_routes_system_buttons(Context& context) {
    using ui::panel::LogonAction;
    context.expect(ui::panel::menu_action("Operation_Help") == LogonAction::kOpenHelp, "nút giúp");
    context.expect(ui::panel::menu_action("Operation_BBS") == LogonAction::kOpenForum, "nút diễn đàn");
    context.expect(ui::panel::menu_action("Operation_QuitGame") == LogonAction::kLeave, "nút thoát");
    context.expect(!ui::panel::menu_action("Operation_2Menu").has_value(), "về đăng nhập chưa có đường");
    context.expect(ui::panel::menu_action("Pet_Help") == LogonAction::kOpenHelp, "giúp của trân thú");
}

void desk_paints_shop_shelves(Context& context) {
    ui::panel::Desk desk;
    ui::panel::press_desk(desk, "MiniMap_Yuanbao");
    ui::panel::press_desk(desk, "YuanbaoShop_Button2");
    ui::panel::press_desk(desk, "YuanbaoShop_Button03");
    Deck deck;
    ui::panel::paint_desk(deck, desk);
    context.expect(desk.shop_tab == 2 && desk.shop_shelf == 3, "mục bảo thạch, kệ ba");
    context.expect(is_hidden(deck, "YuanbaoShop_UpPage"), "hết hàng thì giấu trang trước");
    context.expect(is_hidden(deck, "YuanbaoShop_DownPage"), "hết hàng thì giấu trang sau");
    const Key shelf{.window = "YuanbaoShop_Button03", .name = "Text"};
    context.expect(said(deck, shelf) == "#{YBSDTZ_130503_02}", "kệ năm cấp");
    const Key chosen{.window = "YuanbaoShop_Button2", .name = "Selected"};
    context.expect(said(deck, chosen) == "True", "mục bảo thạch đang chọn");
}

void desk_paints_notice(Context& context) {
    ui::panel::Desk desk;
    ui::panel::press_desk(desk, "Button_Reputation");
    Deck deck;
    ui::panel::paint_desk(deck, desk);
    context.expect(deck.is_shown("DebugListBox"), "lời nhắc hiện ở danh sách");
    const Key line{.window = "DebugListBox_ListBox", .name = "Text"};
    const auto text = said(deck, line);
    const bool has_place = text.has_value() && text->find("Lạc Dương (237, 236)") != std::string_view::npos;
    context.expect(has_place, "đúng chỗ xin vào bang");
}

// Gốc của ba bảng khi mở lần lượt nhân vật, nhiệm vụ, thùng đồ; rồi sau khi mở lại nhân vật.
constexpr std::array<std::string_view, 3> kOpenOrder = {"SelfEquip_Frame", "QuestLog_Frame", "Packet_Frame"};
constexpr std::array<std::string_view, 3> kReopenOrder = {"QuestLog_Frame", "Packet_Frame", "SelfEquip_Frame"};

// Bảng mở sau nằm trên; đóng rồi mở lại thì lên trên cùng.
void desk_paints_in_open_order(Context& context) {
    using ui::panel::Board;
    ui::panel::Desk desk;
    Deck none;
    ui::panel::paint_desk(none, desk);
    context.expect(none.roots().empty(), "không bảng nào mở thì không kê gốc nào");
    ui::panel::toggle_board(desk, Board::kCharacter);
    ui::panel::toggle_board(desk, Board::kQuest);
    ui::panel::toggle_board(desk, Board::kBag);
    Deck three;
    ui::panel::paint_desk(three, desk);
    context.expect(std::ranges::equal(three.roots(), kOpenOrder), "kê theo thứ tự mở");
    ui::panel::close_board(desk, Board::kCharacter);
    ui::panel::toggle_board(desk, Board::kCharacter);
    Deck again;
    ui::panel::paint_desk(again, desk);
    context.expect(std::ranges::equal(again.roots(), kReopenOrder), "mở lại thì lên trên cùng");
    ui::panel::close_board(desk, Board::kQuest);
    Deck two;
    ui::panel::paint_desk(two, desk);
    const bool is_quest_gone = two.roots().size() == 2 && !two.is_shown("QuestLog_Frame");
    context.expect(is_quest_gone, "bảng đóng không kê");
}

constexpr std::array<std::string_view, 4> kDeskLayouts = {
    "MainMenuBar/MainMenuBar.layout.xml",
    "SelfEquip/SelfEquip.layout.xml",
    "Packet/Packet.layout.xml",
    "QuestLog/QuestLog.layout.xml",
};

constexpr std::array<std::string_view, 3> kDeskOpeners = {"Button_Character", "Button_Pack", "Button_Mission"};
constexpr std::array<std::string_view, 3> kDeskClosers = {"SelfEquip_Close", "Packet_Close", "QuestLog_Close"};

// Nút mở, nút đóng và gốc của ba bảng phải có thật trong layout của kho, và bấm đúng tên đó thì
// bàn đổi: gõ sai một tên thì nút bấm không ăn mà không báo gì.
void desk_names_exist(Context& context) {
    if (kClientData.empty()) return;
    const std::filesystem::path root = std::filesystem::path(kClientData) / "Interface";
    const gui::DiskSource files(root);
    gui::GuiSources sources;
    sources.files = &files;
    auto loader = gui::GuiLoader::open(sources);
    context.expect(loader.has_value(), "mở được giao diện của kho");
    if (!loader) return;
    for (const std::string_view layout : kDeskLayouts)
        context.expect(loader->add_layout(layout).has_value(), layout);
    const gui::GuiAsset& asset = loader->asset();
    ui::panel::Desk desk;
    for (const std::string_view opener : kDeskOpeners)
        context.expect(has_window(asset, opener), opener);
    for (const std::string_view opener : kDeskOpeners)
        ui::panel::press_desk(desk, opener);
    Deck deck;
    ui::panel::paint_desk(deck, desk);
    context.expect(deck.roots().size() == 3, "ba nút mở ba bảng");
    for (const std::string_view shown : deck.roots())
        context.expect(has_window(asset, shown), shown);
    for (const std::string_view closer : kDeskClosers)
        context.expect(has_window(asset, closer), closer);
    for (const std::string_view closer : kDeskClosers)
        ui::panel::press_desk(desk, closer);
    Deck shut;
    ui::panel::paint_desk(shut, desk);
    context.expect(shut.roots().empty(), "ba nút đóng đóng ba bảng");
}

constexpr std::array kCases{
    Case{.name = "deck_keeps_root_order", .body = &deck_keeps_root_order},
    Case{.name = "deck_copies_values", .body = &deck_copies_values},
    Case{.name = "deck_composes_in_place", .body = &deck_composes_in_place},
    Case{.name = "player_frame_of_newcomer", .body = &player_frame_of_newcomer},
    Case{.name = "player_frame_prefers_model", .body = &player_frame_prefers_model},
    Case{.name = "player_frame_warns_low_health", .body = &player_frame_warns_low_health},
    Case{.name = "minimap_texts", .body = &minimap_texts},
    Case{.name = "minimap_hover", .body = &minimap_hover},
    Case{.name = "map_toggle_and_floors", .body = &map_toggle_and_floors},
    Case{.name = "map_zoom_and_paint", .body = &map_zoom_and_paint},
    Case{.name = "desk_toggles_from_menubar", .body = &desk_toggles_from_menubar},
    Case{.name = "desk_wires_the_menu", .body = &desk_wires_the_menu},
    Case{.name = "desk_routes_system_buttons", .body = &desk_routes_system_buttons},
    Case{.name = "desk_paints_shop_shelves", .body = &desk_paints_shop_shelves},
    Case{.name = "desk_paints_notice", .body = &desk_paints_notice},
    Case{.name = "desk_paints_in_open_order", .body = &desk_paints_in_open_order},
    Case{.name = "desk_names_exist", .body = &desk_names_exist},
    Case{.name = "menubar_experience", .body = &menubar_experience},
    Case{.name = "portraits_lookup", .body = &portraits_lookup},
    Case{.name = "start_names_exist", .body = &start_names_exist},
    Case{.name = "panel_names_exist", .body = &panel_names_exist},
    Case{.name = "real_portrait_is_loadable", .body = &real_portrait_is_loadable},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_panel_tests: mọi ca phải qua");
    return 0;
}
