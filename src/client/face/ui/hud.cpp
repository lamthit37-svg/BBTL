#include "ui/hud.hpp"

#include "core/error.hpp"
#include "gpu/command.hpp"
#include "gui/loader.hpp"
#include "gui/scroll.hpp"
#include "gui/sheet.hpp"
#include "gui/strings.hpp"
#include "io/file.hpp"
#include "render/ui.hpp"
#include "table/tsv.hpp"
#include "ui/pace.hpp"
#include "ui/painter.hpp"
#include "ui/phone.hpp"
#include "ui/panel/create_role.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/desk.hpp"
#include "ui/panel/login_flow.hpp"
#include "ui/panel/logon.hpp"
#include "ui/panel/maps.hpp"
#include "ui/panel/menubar.hpp"
#include "ui/panel/minimap.hpp"
#include "ui/panel/player_frame.hpp"
#include "ui/panel/portraits.hpp"
#include "ui/panel/role_cast.hpp"
#include "ui/panel/role_pose.hpp"
#include "ui/panel/roles.hpp"
#include "ui/panel/scene_trans.hpp"
#include "ui/panel/select_role.hpp"
#include "ui/panel/self_equip.hpp"
#include "ui/panel/softkey.hpp"
#include "ui/panel/start.hpp"
#include "ui/radar.hpp"
#include "ui/text.hpp"
#include "ui/view.hpp"

#include <algorithm>
#include <chrono>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <expected>
#include <filesystem>
#include <format>
#include <memory>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::ui {
namespace {

// Layout của HUD, của ba bảng mở từ thanh menu chính, của bảng nhập tài khoản và bàn phím ảo của nó
// (đường dẫn tương đối với Interface).
constexpr std::array<std::string_view, 36> kLayouts = {
    "PlayerFrame/PlayerFrame.layout.xml",
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
    panel::kLogonLayout,
    panel::kSelectLayout,
    panel::kCreateLayout,
    panel::kSoftKeysLayout,
    panel::kSceneTransLayout,
};

// Bảng chuyển cảnh đã hiện thì ở lại ít nhất chừng này (xem Hud::State::note_loading).
constexpr std::chrono::milliseconds kTransShown{900};

// Phông bitmap đầu của SongTiBmp12 trong scheme gốc: GBK12, trang 936. VTNAM14 để khi làm tiếng Việt.
constexpr std::string_view kFontFile = "Schema/GBK12.bin";

// Nạp mọi layout của HUD; lỗi đầu tiên được giữ lại.
std::expected<void, std::string> add_layouts(gui::GuiLoader& loader) {
    std::expected<void, std::string> status;
    for (const std::string_view layout : kLayouts) {
        status = status ? loader.add_layout(layout) : status;
    }
    return status;
}

// Đọc một bảng của thư mục Table; thiếu tệp hay hỏng thì ghi một dòng và trả nullopt.
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


// Bảng chuỗi gốc của client (Table/ui_strings.tsv, trích StrDictionary). Bản dịch
// Table/ui_strings.lang.tsv chưa nạp: chủ dự án muốn hết bản gốc trước, tiếng Việt để sau.
gui::StringBook strings_of(const std::filesystem::path& data_root) {
    gui::StringBook book;
    add_strings(book, data_root / "Table" / "ui_strings.tsv");
    return book;
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

gui::StringBook scene_names(const std::filesystem::path& data_root) {
    gui::StringBook book;
    add_strings(book, data_root / "Table" / "scene_names.lang.tsv");
    return book;
}

struct Hud::State {
    State(gui::GuiLoader opened, render::UiPass& target, const std::filesystem::path& data_root)
        : loader(std::move(opened)), pass(&target), painter(target, data_root / "Interface"), atlas(data_root) {}

    gui::GuiLoader loader;
    render::UiPass* pass;
    Painter painter;
    gui::StringBook strings;
    gui::StringBook scene_names;
    panel::Portraits portraits;
    panel::RoleCast cast;
    std::unique_ptr<gui::Hub> hub;
    panel::Deck deck;
    panel::Maps maps;
    panel::Desk desk;
    panel::LoginFlow flow;
    panel::SoftKeys keys;
    // Bảng chuyển cảnh, phần trăm đã đưa cho nó ở khung trước và lúc nó hiện ra.
    panel::SceneTrans trans;
    std::int32_t trans_percent = -1;
    std::chrono::milliseconds trans_since{0};
    // Thủ tục của khung trước; rỗng trước khung đầu, để lần đầu vào thủ tục đăng nhập mở bảng.
    std::optional<Phase> phase;
    bool was_down = false;
    std::optional<Action> asked;
    std::optional<std::chrono::milliseconds> last_clock;
    panel::ShownModel shown;
    // Phông và bộ viết chữ; không mở được phông thì HUD không có chữ.
    std::optional<BitmapFont> font;
    std::optional<TextWriter> writer;
    std::uint32_t font_texture = render::kUiWhite;
    // Ảnh minimap: atlas quanh người chơi, texture của nó và cách vẽ ở khung này.
    RadarAtlas atlas;
    std::optional<std::uint32_t> map_texture;
    std::optional<MapPaint> map;
    // Ô MiniMap_MapArea của khung trước, để toạ độ chuột dùng đúng hộp đã dàn.
    std::optional<gui::Box> map_area;
    bool cursor_inside = false;
    float held_x = 0.0F;
    float held_z = 0.0F;
    // Ảnh fake object của khung này; mượn của HudView, chỉ dùng trong prepare.
    std::span<const ViewPaint> views;
    float width = 0.0F;
    float height = 0.0F;
    std::uint64_t still_stamp = 0;
    std::uint64_t live_stamp = 0;
    std::uint64_t text_stamp = 0;
    bool is_built = false;
    std::vector<render::UiVertex> joined_vertices;
    std::vector<render::UiBatch> joined_batches;

    // Nối quad của extra vào sau quad của giao diện (painter), dời chỉ số quad của các lô thêm.
    void join(Hud::HudExtra extra) {
        const std::span<const render::UiVertex> own = painter.vertices();
        const std::span<const render::UiBatch> own_batches = painter.batches();
        const auto base = static_cast<std::uint32_t>(own.size() / 4);
        joined_vertices.assign(own.begin(), own.end());
        joined_vertices.insert(joined_vertices.end(), extra.vertices.begin(), extra.vertices.end());
        joined_batches.assign(own_batches.begin(), own_batches.end());
        for (render::UiBatch batch : extra.batches) {
            batch.first_quad += base;
            joined_batches.push_back(batch);
        }
    }

    void open_font(const std::filesystem::path& interface_root);
    void open_portraits(const std::filesystem::path& data_root);
    [[nodiscard]] panel::PlaceText place_under(const HudView& view);
    void enter(Phase next) noexcept;
    void note_press(const HudView& view);
    void note_hold(const HudView& view);
    [[nodiscard]] float frame_seconds(std::chrono::milliseconds now);
    [[nodiscard]] std::string_view held_window(gui::Pointer pointer) const;
    [[nodiscard]] bool is_on_scroll(float across, float down) const;
    void note_scroll(const HudView& view, float seconds);
    void press_login(std::string_view window, const HudView& view);
    [[nodiscard]] panel::LoginFacts login_facts(const HudView& view) const noexcept;
    void note_hover(const HudView& view);
    void note_text(const HudView& view);
    void note_loading(const HudView& view);
    void fill_panels(const HudView& view);
    void fill_play(const HudView& view);
    [[nodiscard]] core::Status add_map();
    void upload_map();
    [[nodiscard]] std::optional<MapPaint> map_of(const HudScene& scene);
    [[nodiscard]] bool is_current() const noexcept;
    void rebuild();
};

void Hud::State::open_font(const std::filesystem::path& interface_root) {
    const std::filesystem::path file = interface_root / io::path_from_utf8(kFontFile);
    core::Result<BitmapFont> opened = BitmapFont::open(file);
    if (!opened) {
        std::println(stderr, "Giao diện: không có phông chữ: {}", opened.error());
        return;
    }
    const core::Result<std::uint32_t> texture = pass->add_texture(opened->atlas());
    if (!texture) {
        std::println(stderr, "Giao diện: không tải được phông lên GPU: {}", texture.error());
        return;
    }
    font.emplace(std::move(*opened));
    font_texture = *texture;
    writer.emplace(*font, &strings);
}

// Nạp bảng chân dung (Table/portraits.tsv; không đọc được thì khung nhân vật không có mặt) và dữ
// liệu của màn tạo nhân vật, rồi đưa các bộ ảnh chân dung vào giao diện (layout không nhắc tới
// chúng). Gọi trước khi dựng Hub vì asset đổi.
void Hud::State::open_portraits(const std::filesystem::path& data_root) {
    const std::optional<table::Tsv> table = read_table(data_root / "Table" / "portraits.tsv");
    portraits = table ? panel::Portraits::from_table(*table) : panel::Portraits{};
    cast = cast_of(data_root, table);
    for (const std::string& imageset : portraits.imagesets()) {
        loader.add_imageset(imageset);
    }
    for (const std::string_view imageset : panel::create_imagesets()) {
        loader.add_imageset(imageset);
    }
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
void Hud::State::enter(Phase next) noexcept {
    if (phase == next) return;
    phase = next;
    if (next == Phase::kLogin) panel::reset_account(flow);
    if (next != Phase::kLogin) panel::close_soft_keys(keys);
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
    panel::hover_flow(flow, window.value_or(std::string_view{}));
}

void Hud::State::note_press(const HudView& view) {
    const bool is_down = view.pointer.has_value() && view.pointer->is_down;
    const bool is_press = is_down && !was_down;
    const bool is_release = !is_down && was_down;
    was_down = is_down;
    if (is_release && view.phase == Phase::kLogin) panel::release_flow(flow);
    if (!is_press || !hub || !view.pointer) return;
    const gui::Pointer spot = *view.pointer;
    const auto window = hub->hit(spot.x, spot.y, gui::Probe::kLeftButton);
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
}

// Một lần nhấn trong thủ tục đăng nhập: bảng nhập tài khoản nghe trước, rồi tới bàn phím ảo. Nút bàn
// phím ảo của bảng là ToggleWindow("SoftKeyBoard") của LogOn_KeyBoard; ký tự một phím gõ ra đi vào ô
// mà bảng đang ngắm. Đồng hồ khung làm muối cho lần xoay vòng phím.
void Hud::State::press_login(std::string_view window, const HudView& view) {
    panel::press_flow(flow, window, login_facts(view));
    if (!panel::on_account(flow)) {
        panel::close_soft_keys(keys);
        return;
    }
    panel::press_soft_keys(keys, window);
    const auto salt = static_cast<std::uint32_t>(view.clock.count());
    if (window == panel::kLogonKeysButton) panel::toggle_soft_keys(keys, salt);
    if (!panel::is_soft_key_face(window) || !view.pointer) return;
    const std::optional<std::size_t> cell = hub->soft_key(panel::kSoftKeysWindow, *view.pointer);
    const std::optional<char32_t> typed = cell ? panel::strike_soft_key(keys, *cell) : std::nullopt;
    if (typed) panel::key_flow(flow, *typed);
}

// Ký tự gõ từ bàn phím tới ô đang nhận phím của bảng nhập tài khoản; màn chơi chưa có ô nhập nào.
void Hud::State::note_text(const HudView& view) {
    if (view.phase != Phase::kLogin) return;
    for (const char32_t code : view.typed) panel::type_flow(flow, code, login_facts(view));
    if (!panel::on_account(flow)) panel::close_soft_keys(keys);
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
        if (trans.is_shown && is_due) panel::scene_transed(trans);
        if (!trans.is_shown) trans_percent = -1;
        return;
    }
    if (!trans.is_shown) {
        panel::leave_world(trans, scene_names.find(view.loading->name).value_or(view.loading->name), strings);
        trans_percent = -1;
        trans_since = view.clock;
    }
    if (view.loading->percent == trans_percent) return;
    trans_percent = view.loading->percent;
    if (trans_percent > 0) panel::scene_transing(trans, trans_percent, strings);
}

// Chỉ thị của khung theo thủ tục đang chạy (thay các script Lua của client gốc). Bảng chuyển cảnh
// kê sau cùng nên nằm trên mọi bảng khác.
void Hud::State::fill_panels(const HudView& view) {
    deck.clear();
    if (view.phase == Phase::kLogin) {
        panel::paint_flow(deck, flow);
        shown = panel::shown_model(flow, login_facts(view));
        if (panel::on_account(flow)) panel::paint_soft_keys(deck, keys);
    } else {
        shown = {};
        fill_play(view);
    }
    panel::paint_scene_trans(deck, trans);
}

// Màn chơi: trạng thái lúc vào game rồi tới từng bảng. Không có nhân vật thì khung nhân vật và
// thanh kinh nghiệm giữ nguyên như layout.
void Hud::State::fill_play(const HudView& view) {
    panel::follow_here(maps, view.scene.id);
    panel::show_start(deck);
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
    if (view.hero == nullptr) return;
    panel::Face face;
    face.image = portraits.image_of(view.hero->portrait);
    face.model = head_model(view.views);
    panel::fill_player(deck, *view.hero, face);
    panel::fill_menubar(deck, *view.hero);
    const bool is_sheet_open = panel::is_open(desk, panel::Board::kCharacter);
    if (is_sheet_open) panel::fill_self_equip(deck, *view.hero, strings);
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

bool Hud::State::is_current() const noexcept {
    const bool is_same_quads = still_stamp == hub->still_stamp() && live_stamp == hub->live_stamp();
    return is_built && is_same_quads && text_stamp == hub->text_stamp();
}

void Hud::State::rebuild() {
    const FrameParts parts{.still = hub->still(), .live = hub->live(), .texts = hub->texts()};
    PaintKit kit;
    kit.writer = writer ? &*writer : nullptr;
    kit.font_texture = font_texture;
    kit.map = map;
    kit.views = views;
    painter.build(loader.asset(), parts, kit);
    still_stamp = hub->still_stamp();
    live_stamp = hub->live_stamp();
    text_stamp = hub->text_stamp();
    is_built = true;
}

Hud::Hud(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}
Hud::Hud(Hud&&) noexcept = default;
Hud& Hud::operator=(Hud&&) noexcept = default;
Hud::~Hud() = default;

core::Result<Hud> Hud::open(render::UiPass& pass, const HudDesc& desc) {
    const std::filesystem::path root = desc.data_root / "Interface";
    const gui::DiskSource files(root, kPhone);
    gui::GuiSources sources;
    sources.files = &files;
    auto opened = gui::GuiLoader::open(sources);
    if (!opened) {
        constexpr const char* kNoUi = "không mở được giao diện";
        const auto& reason = opened.error();
        return core::fail(core::ErrorCode::kInvalidArgument, kNoUi, reason);
    }
    auto state = std::make_unique<State>(std::move(*opened), pass, desc.data_root);
    const auto added = add_layouts(state->loader);
    if (!added) {
        constexpr const char* kNoLayout = "không nạp được layout";
        const auto& reason = added.error();
        return core::fail(core::ErrorCode::kInvalidArgument, kNoLayout, reason);
    }
    state->strings = strings_of(desc.data_root);
    state->scene_names = scene_names(desc.data_root);
    state->open_portraits(desc.data_root);
    state->open_font(root);
    state->hub = std::make_unique<gui::Hub>(state->loader.asset());
    for (const std::string& note : state->loader.notes()) {
        std::println(stderr, "Giao diện: {}", note);
    }
    return Hud(std::move(state));
}

void Hud::prepare(const HudView& view) {
    State& state = *state_;
    state.views = view.views;
    state.enter(view.phase);
    state.note_hover(view);
    state.note_press(view);
    state.note_text(view);
    state.note_hold(view);
    state.note_loading(view);
    state.fill_panels(view);
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
    if (state.is_current() && is_same_map) return;
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
    return state_->hub->hit(across, down, gui::Probe::kAny).has_value();
}

bool Hud::takes_wheel(float across, float down) const {
    return state_->is_on_scroll(across, down);
}

std::optional<Action> Hud::take_action() noexcept {
    if (state_->asked) {
        const Action asked = *state_->asked;
        state_->asked.reset();
        return asked;
    }
    return panel::take_flow(state_->flow);
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

const panel::ShownModel& Hud::role_model() const noexcept {
    return state_->shown;
}

std::size_t Hud::quad_count() const noexcept {
    return state_->painter.vertices().size() / 4;
}

std::size_t Hud::missing_count() const noexcept {
    return state_->painter.missing();
}

} // namespace game::ui
