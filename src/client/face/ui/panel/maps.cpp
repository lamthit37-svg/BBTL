// Hiện thực mở, đóng và tầng của SceneMap.lua / LargeMap.lua.
#include "ui/panel/maps.hpp"

#include "gui/sheet.hpp"
#include "ui/panel/deck.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <string_view>

namespace game::ui::panel {
namespace {

struct Floor {
    int scene_id = 0;
    std::string_view name;
};

constexpr Floor floor_of(int scene_id, std::string_view name) noexcept {
    Floor floor;
    floor.scene_id = scene_id;
    floor.name = name;
    return floor;
}

// Tên gốc của cảnh, cùng khoá scene/ trong bảng dịch. Không viết tiếng Việt ở đây.
constexpr std::array<Floor, 5> kBaoTang{{
    floor_of(166, "宝藏洞一层"),
    floor_of(169, "宝藏洞二层"),
    floor_of(191, "宝藏洞三层"),
    floor_of(192, "宝藏洞四层"),
    floor_of(193, "宝藏洞五层"),
}};
constexpr std::array<Floor, 9> kYenVuong{{
    floor_of(202, "燕王古墓一层"),
    floor_of(203, "燕王古墓二层"),
    floor_of(204, "燕王古墓三层"),
    floor_of(205, "燕王古墓四层"),
    floor_of(206, "燕王古墓五层"),
    floor_of(207, "燕王古墓六层"),
    floor_of(208, "燕王古墓七层"),
    floor_of(209, "燕王古墓八层"),
    floor_of(210, "燕王古墓九层"),
}};
constexpr std::array<Floor, 3> kTanHoang{{
    floor_of(262, "秦皇地宫一层"),
    floor_of(263, "秦皇地宫二层"),
    floor_of(264, "秦皇地宫三层"),
}};
constexpr std::array<Floor, 5> kThongThien{{
    floor_of(295, "通天塔地宫"),
    floor_of(296, "通天塔一层"),
    floor_of(297, "通天塔二层"),
    floor_of(298, "通天塔三层"),
    floor_of(299, "通天塔顶层"),
}};

constexpr std::string_view kHereBanner = "#{KCJXL_130417_1}";
constexpr std::string_view kAwayBanner = "#{KCJXL_130417_3}";
constexpr std::string_view kTitleTint = "#gFF0FA0";
constexpr std::string_view kInset = "{0.500000,-306.500000}";
constexpr std::string_view kWide = "{0.500000,-169.000000}";
constexpr Key kSceneTitle{.window = "SceneMap_SceneName", .name = "Text"};
constexpr Key kBanner{.window = "SceneMap_Text3", .name = "Text"};
constexpr Key kBannerX{.window = "SceneMap_Text3", .name = "UnifiedXPosition"};

struct Group {
    int id = 0;
    std::span<const Floor> floors;
};

[[nodiscard]] int index_in(std::span<const Floor> floors, int scene_id) noexcept {
    const auto same = [scene_id](const Floor& floor) { return floor.scene_id == scene_id; };
    const auto found = std::ranges::find_if(floors, same);
    if (found == floors.end()) return -1;
    return static_cast<int>(found - floors.begin());
}

[[nodiscard]] std::optional<Group> group_of(int scene_id) noexcept {
    if (index_in(kBaoTang, scene_id) >= 0) return Group{.id = 1, .floors = kBaoTang};
    if (index_in(kYenVuong, scene_id) >= 0) return Group{.id = 2, .floors = kYenVuong};
    if (index_in(kTanHoang, scene_id) >= 0) return Group{.id = 3, .floors = kTanHoang};
    if (index_in(kThongThien, scene_id) >= 0) return Group{.id = 4, .floors = kThongThien};
    return std::nullopt;
}

void bind_group(Maps& maps, int scene_id) noexcept {
    const std::optional<Group> group = group_of(scene_id);
    if (!group) {
        maps.group = -1;
        maps.floor = 0;
        return;
    }
    maps.group = group->id;
    maps.floor = index_in(group->floors, scene_id);
}

std::string_view chosen_floor_key(const Maps& maps) noexcept {
    const std::optional<Group> group = group_of(maps.chosen);
    if (!group) return {};
    const int count = static_cast<int>(group->floors.size());
    if (maps.floor < 0 || maps.floor >= count) return {};
    return group->floors[static_cast<std::size_t>(maps.floor)].name;
}

void open_scene(Maps& maps, int here) noexcept {
    maps.is_scene_open = true;
    maps.is_world_open = false;
    maps.here = here;
    maps.chosen = here;
    maps.shows_here = true;
    bind_group(maps, here);
}

void open_other(Maps& maps, int scene_id, int here) noexcept {
    maps.shows_here = scene_id == here;
    const int shown = scene_id == kSnowLuoyang ? 0 : scene_id;
    maps.is_scene_open = true;
    maps.is_world_open = false;
    maps.here = here;
    maps.chosen = shown;
    bind_group(maps, shown);
}

void close_scene(Maps& maps) noexcept {
    maps.is_scene_open = false;
}

void open_world(Maps& maps) noexcept {
    maps.is_world_open = true;
    close_scene(maps);
}

void close_world(Maps& maps) noexcept {
    maps.is_world_open = false;
    if (maps.world_choice < 0 || maps.world_choice != maps.here) return;
    open_scene(maps, maps.here);
}

[[nodiscard]] bool is_digit(char digit) noexcept {
    return digit >= '0' && digit <= '9';
}

[[nodiscard]] std::optional<int> parse_width(std::string_view text) noexcept {
    if (text.empty() || !std::ranges::all_of(text, is_digit)) return std::nullopt;
    int width = 0;
    for (const char digit : text)
        width = (width * 10) + (digit - '0');
    return width;
}

void paint_closed(Deck& deck, const Maps& maps) {
    if (!maps.is_world_open) deck.hide("LargeMapFrame");
    if (!maps.is_scene_open) deck.hide("SceneMap_Frame");
}

struct Caption {
    std::string_view title;
    std::string_view resolution;
};

void paint_open(Deck& deck, const Maps& maps, Caption caption) {
    if (maps.is_world_open) deck.show("LargeMapFrame");
    if (!maps.is_scene_open) return;
    deck.show("SceneMap_Frame");
    const std::string_view caption_text = caption.title;
    std::string& name = deck.compose(kSceneTitle);
    name.append(kTitleTint).append(caption_text);
    std::string& banner = deck.compose(kBanner);
    banner.assign(maps.shows_here ? kHereBanner : kAwayBanner);
    const gui::Override place{
        .window = kBannerX.window, .name = kBannerX.name, .value = label_is_inset(caption.resolution) ? kInset : kWide};
    deck.set(place);
    if (maps.group < 0) deck.hide("sceneMap_ComboList");
}

// title và resolution khác vai trò: tên cảnh và chuỗi View_Resoution.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
void paint_shown(Deck& deck, const Maps& maps, std::string_view title, std::string_view resolution) {
    Caption caption;
    caption.title = title;
    caption.resolution = resolution;
    paint_open(deck, maps, caption);
}

} // namespace

std::string_view floor_key(const Maps& maps) noexcept {
    return chosen_floor_key(maps);
}

void follow_here(Maps& maps, int here) noexcept {
    if (maps.here < 0) {
        maps.here = here;
        return;
    }
    if (maps.here == here) return;
    maps.here = here;
    close_scene(maps);
}

namespace {

void flip_world(Maps& maps) noexcept {
    if (maps.is_world_open)
        close_world(maps);
    else
        open_world(maps);
}

void flip_scene(Maps& maps, int here) noexcept {
    if (maps.is_scene_open)
        close_scene(maps);
    else
        open_scene(maps, here);
}

} // namespace

void note_world(Maps& maps, MapToggle order) noexcept {
    if (order == MapToggle::kFlip) {
        flip_world(maps);
        return;
    }
    if (order == MapToggle::kOpen) {
        open_world(maps);
        return;
    }
    close_world(maps);
}

void note_scene(Maps& maps, SceneAsk ask) noexcept {
    if (ask.order == MapToggle::kFlip) {
        flip_scene(maps, ask.here);
        return;
    }
    if (ask.order == MapToggle::kOpen) {
        open_scene(maps, ask.here);
        return;
    }
    if (ask.order == MapToggle::kClose) {
        close_scene(maps);
        return;
    }
    if (ask.order != MapToggle::kOther) return;
    open_other(maps, ask.scene_id, ask.here);
}

void choose_city(Maps& maps, std::uint32_t scene_id) noexcept {
    if (scene_id == kNoCity) return;
    maps.world_choice = static_cast<int>(scene_id);
    maps.is_world_open = false;
    open_other(maps, static_cast<int>(scene_id), maps.here);
}

void pick_floor(Maps& maps, int index) noexcept {
    if (maps.group < 0) return;
    const std::optional<Group> group = group_of(maps.chosen);
    if (!group) return;
    const int count = static_cast<int>(group->floors.size());
    if (index < 1 || index > count) return;
    const int scene_id = group->floors[static_cast<std::size_t>(index - 1)].scene_id;
    open_other(maps, scene_id, maps.here);
}

void show_here(Maps& maps) noexcept {
    open_scene(maps, maps.here);
}

int clamped_zoom(int step) noexcept {
    if (step < 0 || step > 4) return -1;
    if (step > 2) return 2;
    return step;
}

bool label_is_inset(std::string_view resolution) noexcept {
    if (resolution.size() < 4) return true;
    const bool is_comma = resolution[3] == ',';
    const std::string_view head = is_comma ? resolution.substr(0, 3) : resolution.substr(0, 4);
    const std::optional<int> width = parse_width(head);
    if (!width) return true;
    return *width <= 960;
}

void press_map(Maps& maps, std::string_view window) noexcept {
    if (window == "MiniMap_Plot") {
        note_scene(maps, SceneAsk{.order = MapToggle::kFlip, .here = maps.here});
        return;
    }
    if (window == "MiniMap_WorldMap") {
        note_world(maps, MapToggle::kFlip);
        return;
    }
    if (window == "sceneMap_LargeMap") {
        note_world(maps, MapToggle::kOpen);
        return;
    }
    if (window == "LargeMap_Qiehuan") {
        note_scene(maps, SceneAsk{.order = MapToggle::kOpen, .here = maps.here});
        return;
    }
    if (window == "LargeMap_CloseButtons") {
        note_world(maps, MapToggle::kClose);
        return;
    }
    if (window == "ScemeMap_CloseButtons") {
        close_scene(maps);
        return;
    }
    if (window == "sceneMap_back") show_here(maps);
}

void paint_maps(Deck& deck, const Maps& maps, std::string_view title, std::string_view resolution) {
    paint_closed(deck, maps);
    paint_shown(deck, maps, title, resolution);
}

} // namespace game::ui::panel
