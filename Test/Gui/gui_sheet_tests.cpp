// Dàn trang Falagard (gui/sheet.hpp) trên GuiAsset dựng tay: chỗ cửa sổ theo UDim, ảnh kéo giãn,
// thanh máu còn một nửa, góc khung, và radar giữa cảnh 320. Màn đăng nhập: thuộc tính đặt lúc chạy,
// nút đang chọn, nút bị khoá, chữ đơn tra bảng chuỗi và ô nhập có con nháy. Thứ tự vẽ theo
// AlwaysOnTop dựng bằng ngăn xếp.
// Nguồn: TLBB Dev tests/gui/sheet_test.cpp@e0d89a6. Khác gốc: khung test của dự án; bảng chuỗi dựng
// từ table::Tsv; API radar, thanh và quạt gom tham số vào struct; bỏ ca đường dẫn ô radar (chưa
// có); thêm ca thứ tự vẽ và nút nóng.
#include "core/check.hpp"
#include "gui/asset.hpp"
#include "gui/sheet.hpp"
#include "gui/strings.hpp"
#include "table/tsv.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <numbers>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using gui::Box;
using gui::GuiAsset;
using gui::GuiDim;
using gui::GuiDimKind;
using gui::GuiDimType;
using gui::GuiImage;
using gui::GuiRange;
using gui::GuiUDim;
using gui::Hub;
using gui::Override;
using gui::Place;
using gui::Probe;
using gui::Quad;
using gui::Sheet;
using gui::TextRun;

bool near_value(float value, float expect) {
    return std::fabs(value - expect) < 0.01F;
}

bool same_box(Box box, Box want) {
    const bool is_same_place = near_value(box.x, want.x) && near_value(box.y, want.y);
    const bool is_same_size = near_value(box.w, want.w) && near_value(box.h, want.h);
    return is_same_place && is_same_size;
}

GuiRange range_of(std::uint32_t first, std::uint32_t count) {
    return GuiRange{.first = first, .count = count};
}

std::int32_t add_dim(GuiAsset& asset, GuiDim dim) {
    const auto index = static_cast<std::int32_t>(asset.dims.size());
    asset.dims.push_back(std::move(dim));
    return index;
}

std::int32_t absolute(GuiAsset& asset, float value) {
    GuiDim dim;
    dim.kind = GuiDimKind::kAbsolute;
    dim.value = value;
    return add_dim(asset, dim);
}

std::int32_t full(GuiAsset& asset, GuiDimType what) {
    GuiDim dim;
    dim.kind = GuiDimKind::kUnified;
    dim.what = what;
    dim.unified = GuiUDim{.scale = 1.0F, .offset = 0.0F};
    return add_dim(asset, dim);
}

void fill_area(GuiAsset& asset, gui::GuiArea& area) {
    const std::int32_t left = absolute(asset, 0.0F);
    const std::int32_t top = absolute(asset, 0.0F);
    const std::int32_t width = full(asset, GuiDimType::kWidth);
    const std::int32_t height = full(asset, GuiDimType::kHeight);
    area.dims = {left, top, width, height};
    area.types = {GuiDimType::kLeftEdge, GuiDimType::kTopEdge, GuiDimType::kWidth, GuiDimType::kHeight};
}

gui::GuiProperty property(std::string name, std::string value) {
    return gui::GuiProperty{.name = std::move(name), .value = std::move(value)};
}

// Kiểu và cha của một cửa sổ (parent -1 là cửa sổ gốc).
struct Slot {
    std::int32_t type = -1;
    std::int32_t parent = -1;
};

// Thêm một cửa sổ chưa có thuộc tính; thuộc tính của nó thêm bằng add_property ngay sau đó.
void add_window(GuiAsset& asset, std::string name, Slot slot) {
    gui::GuiWindow window;
    window.name = std::move(name);
    window.type = slot.type;
    window.parent = slot.parent;
    window.properties.first = static_cast<std::uint32_t>(asset.properties.size());
    asset.windows.push_back(std::move(window));
}

// Thêm một thuộc tính cho cửa sổ vừa thêm. Thuộc tính của một cửa sổ nằm liền nhau trong asset,
// nên chỉ cửa sổ cuối nhận thêm được.
void add_property(GuiAsset& asset, std::string name, std::string value) {
    core::check(!asset.windows.empty(), "thuộc tính phải theo sau một cửa sổ");
    gui::GuiProperty added = property(std::move(name), std::move(value));
    asset.properties.push_back(std::move(added));
    ++asset.windows.back().properties.count;
}

// Màn hình rộng width, cao height, không bảng chuỗi, không chuột.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): rộng rồi cao, nơi gọi viết số cụ thể.
Place screen_of(float width, float height) {
    Place input;
    input.width = width;
    input.height = height;
    return input;
}

GuiImage image_of(std::string imageset, std::string name, float size) {
    GuiImage image;
    image.imageset = std::move(imageset);
    image.name = std::move(name);
    image.width = size;
    image.height = size;
    return image;
}

// Thêm state name vẽ đúng một lớp, lớp ấy chỉ có spec thứ slot. Lớp mang cùng số thứ tự với spec:
// mỗi asset ở đây thêm lớp và spec theo từng cặp.
void add_layer_state(GuiAsset& asset, std::string name, std::uint32_t slot) {
    asset.layers.push_back(gui::GuiLayer{.priority = 0, .specs = range_of(slot, 1)});
    gui::GuiState state;
    state.name = std::move(name);
    state.layers = range_of(slot, 1);
    asset.states.push_back(std::move(state));
}

// Thanh máu Falagard/SuperProgress: khung kéo giãn bằng ảnh Common/Red ở ô (4, 35, 5, 5).
GuiAsset bar_asset() {
    GuiAsset asset;
    GuiImage image = image_of("Common", "Red", 5.0F);
    image.texture = 0;
    image.x = 4.0F;
    image.y = 35.0F;
    asset.images.push_back(image);
    asset.textures.emplace_back("Common/Red.dds");
    gui::GuiFrame frame;
    fill_area(asset, frame.area);
    frame.images.at(0) = 0;
    frame.horz.value = std::to_underlying(gui::GuiHorz::kStretched);
    frame.vert.value = std::to_underlying(gui::GuiVert::kStretched);
    asset.frames.push_back(frame);
    gui::GuiSection section;
    section.name = "progressbar";
    section.frames = range_of(0, 1);
    asset.sections.push_back(section);
    asset.specs.push_back(gui::GuiSpec{.section = 0, .overrides = false, .colour = {}});
    add_layer_state(asset, "Enabled", 0);
    gui::GuiLook look;
    look.name = "Red";
    look.states = range_of(0, 1);
    asset.looks.push_back(look);
    gui::GuiType bar;
    bar.name = "TLBB_ProgressPropertyRed";
    bar.renderer = "Falagard/SuperProgress";
    bar.look = 0;
    asset.types.push_back(bar);
    add_window(asset, "PlayerFrame_HP", Slot{.type = 0, .parent = -1});
    add_property(asset, "AbsoluteSize", "w:128 h:5");
    add_property(asset, "CurrentProgress", "0.5");
    return asset;
}

// Ba cửa sổ của minimap: gốc dính góc phải, con theo cha, con bị giấu.
void placed_windows(Context& context) {
    GuiAsset asset;
    asset.images.push_back(image_of("Map", "Frame", 8.0F));
    const std::string frame = "set:Map image:Frame";
    add_window(asset, "MiniMap_Frame", Slot{.type = -1, .parent = -1});
    add_property(asset, "UnifiedPosition", "{{1,-294},{0,0}}");
    add_property(asset, "AbsoluteSize", "w:294 h:268");
    add_property(asset, "Image", frame);
    add_window(asset, "MiniMap_Background_Frame", Slot{.type = -1, .parent = 0});
    add_property(asset, "UnifiedPosition", "{{1,-213},{0,0}}");
    add_property(asset, "AbsoluteSize", "w:213 h:239");
    add_property(asset, "Image", frame);
    add_window(asset, "MiniMap_OpenButtons", Slot{.type = -1, .parent = 0});
    add_property(asset, "Visible", "False");
    add_property(asset, "Image", frame);
    const std::string_view root_name = "MiniMap_Frame";
    Place input = screen_of(1024.0F, 768.0F);
    input.roots = std::span{&root_name, 1};
    const Sheet sheet = gui::place(asset, input);
    context.expect(sheet.quads.size() == 2, "minimap có hai ảnh");
    if (sheet.quads.size() != 2) return;
    const Box root{.x = 730.0F, .y = 0.0F, .w = 294.0F, .h = 268.0F};
    const Box child{.x = 811.0F, .y = 0.0F, .w = 213.0F, .h = 239.0F};
    context.expect(same_box(sheet.quads.at(0).dest, root), "minimap dính góc phải");
    context.expect(same_box(sheet.quads.at(1).dest, child), "khung con theo cha");
}

// Cửa sổ con rộng 0,15 của cha 430 (cha rộng 0,42 màn 1024, có thành phần scale nên onParentSized tính
// lại cỡ con): vùng cửa sổ là URect (min, max = min + cỡ), cỡ đọc lại là max - min trong float32. Vị trí
// 0,5 rồi cỡ 0,15 cho max = 0,65 và cỡ 0,14999998, nhân 430 được 64,49999 nên làm tròn xuống 64; vị trí
// 0,35 rồi cỡ 0,15 cho max = 0,5 đúng nên giữ 0,15, nhân 430 được 64,5 nên làm tròn lên 65. Số 64 và 65
// của hai con này là ô getUnclippedPixelRect của BieYePersonnelManage_List1_Text_3 và _Text_2 (golden).
GuiAsset area_asset(bool is_parent_fixed) {
    GuiAsset asset;
    add_window(asset, "Row", Slot{.type = -1, .parent = -1});
    add_property(asset, "UnifiedSize", is_parent_fixed ? "{{0,430},{0,28}}" : "{{0.42,0},{0,28}}");
    add_window(asset, "Row_Early", Slot{.type = -1, .parent = 0});
    add_property(asset, "UnifiedPosition", "{{0.35,0},{0,0}}");
    add_property(asset, "UnifiedSize", "{{0.15,0},{0,28}}");
    add_window(asset, "Row_Late", Slot{.type = -1, .parent = 0});
    add_property(asset, "UnifiedPosition", "{{0.5,0},{0,0}}");
    add_property(asset, "UnifiedSize", "{{0.15,0},{0,28}}");
    add_window(asset, "Row_SizeFirst", Slot{.type = -1, .parent = 0});
    add_property(asset, "UnifiedSize", "{{0.15,0},{0,28}}");
    add_property(asset, "UnifiedPosition", "{{0.5,0},{0,0}}");
    return asset;
}

float width_of(const Hub& hub, std::string_view window) {
    const std::optional<Box> box = hub.box(window);
    return box ? box->w : -1.0F;
}

void area_size_is_max_minus_min(Context& context) {
    const GuiAsset asset = area_asset(false);
    Hub hub(asset);
    hub.update(screen_of(1024.0F, 768.0F));
    context.expect(width_of(hub, "Row") == 430.0F, "cha rộng 430");
    context.expect(width_of(hub, "Row_Early") == 65.0F, "max = 0,5 đúng nên 0,15 x 430 = 64,5 làm tròn lên");
    context.expect(width_of(hub, "Row_Late") == 64.0F, "max = 0,65 lệch 1 ulp nên cỡ đọc lại là 64,49999");
    context.expect(width_of(hub, "Row_SizeFirst") == 64.0F, "đặt cỡ rồi vị trí cũng ra cùng max");
}

// Cha cỡ tuyệt đối (không scale ở cạnh max) thì onParentSized không lan xuống con: con giữ cỡ của lần
// setWindowArea_impl cuối, vẫn là 0,15 nguyên (lần đặt vị trí truyền lại cỡ đọc từ vùng lúc đó, chưa lệch),
// nên cả hai con đều 65.
void fixed_parent_does_not_resize_children(Context& context) {
    const GuiAsset asset = area_asset(true);
    Hub hub(asset);
    hub.update(screen_of(1024.0F, 768.0F));
    context.expect(width_of(hub, "Row_Late") == 65.0F, "cha cố định: con giữ cỡ vừa đặt, 65");
    context.expect(width_of(hub, "Row_SizeFirst") == 65.0F, "cha cố định: cỡ đặt trước vị trí cũng giữ 0,15, 65");
}

void half_bar(Context& context) {
    const GuiAsset asset = bar_asset();
    const Sheet half = gui::place(asset, screen_of(200.0F, 200.0F));
    context.expect(!half.quads.empty(), "thanh máu có ảnh");
    if (half.quads.empty()) return;
    const Box want{.x = 0.0F, .y = 0.0F, .w = 64.0F, .h = 5.0F};
    context.expect(same_box(half.quads.at(0).dest, want), "thanh máu 0,5 rộng một nửa");
    const Box source = half.quads.at(0).source;
    context.expect(source.x == 4.0F && source.w == 5.0F, "ô ảnh của thanh");
}

// Radar 140 x 140 của người đứng giữa cảnh 320 x 320.
constexpr gui::RadarAsk kMiddleAsk{
    .scene_width = 320.0F,
    .scene_depth = 320.0F,
    .window_width = 140.0F,
    .window_height = 140.0F,
    .player_x = 160.0F,
    .player_z = 160.0F,
};

void radar_center(Context& context) {
    const gui::Radar view = gui::radar_uv(kMiddleAsk);
    context.expect(near_value(view.u0, 0.4453125F) && near_value(view.u1, 0.5546875F), "giữa cảnh");
    context.expect(near_value(view.v0, view.u0) && near_value(view.v1, view.u1), "trục z");
    gui::RadarAsk corner = kMiddleAsk;
    corner.player_x = 0.0F;
    corner.player_z = 0.0F;
    const gui::Radar edge = gui::radar_uv(corner);
    context.expect(near_value(edge.u0, 0.0F), "sát mép thì kẹp");
    context.expect(near_value(edge.u1, 140.0F / (320.0F * 4.0F)), "mép phải của vùng thấy");
    context.expect(view.is_centred_u && view.is_centred_v, "giữa cảnh: vùng thấy canh giữa người chơi");
    context.expect(!edge.is_centred_u && !edge.is_centred_v, "sát mép: vùng thấy bị kẹp");
    const gui::BarMove move{.shown = 1.0F, .target = 0.5F, .speed = 1.0F, .seconds = 0.25F};
    context.expect(near_value(gui::bar_step(move), 0.75F), "thanh trượt 0,25 mỗi nhịp");
    const gui::SceneCursor centre{.local_x = 70.0F, .local_y = 70.0F};
    const gui::SceneHit middle_hit = gui::scene_at(kMiddleAsk, centre);
    context.expect(middle_hit.is_on_scene, "tâm cửa sổ nằm trên cảnh");
    context.expect(near_value(middle_hit.x, 160.0F) && near_value(middle_hit.z, 160.0F), "tâm là chỗ đứng");
    const gui::SceneCursor west{.local_x = 0.0F, .local_y = 70.0F};
    const gui::SceneHit edge_hit = gui::scene_at(kMiddleAsk, west);
    context.expect(near_value(edge_hit.x, 142.5F), "mép trái là 142.5");
    const gui::SceneHit missed = gui::scene_at(kMiddleAsk, {.local_x = -600.0F, .local_y = 70.0F});
    context.expect(!missed.is_on_scene && missed.x == 0.0F, "ra ngoài cảnh thì không có điểm");
}

// createBackground của DLL: trunc / 64, dư thì thêm ô. 320 và 192 chia hết; 100 thì không.
void radar_grid(Context& context) {
    context.expect(gui::radar_tiles(320.0F) == 5, "320 là 5 ô");
    context.expect(gui::radar_tiles(192.0F) == 3, "192 là 3 ô");
    context.expect(gui::radar_tiles(100.0F) == 2, "100 dư nên 2 ô");
    context.expect(gui::radar_tiles(64.0F) == 1, "đúng một ô");
    context.expect(gui::radar_tiles(65.0F) == 2, "65 dư nên 2 ô");
    context.expect(gui::radar_tiles(0.0F) == 0 && gui::radar_tiles(-4.0F) == 0, "cảnh không dương");
    context.expect(gui::radar_tiles(16777216.0F) == 0, "quá lớn thì không ép int");
    context.expect(gui::radar_grid_exact(320.0F) && gui::radar_grid_exact(64.0F), "chia hết");
    context.expect(!gui::radar_grid_exact(100.0F) && !gui::radar_grid_exact(65.0F), "có dư");
}

void round_edge(Context& context) {
    std::array<gui::Fan, gui::kRoundCount> fan{};
    const Box dest{.x = 10.0F, .y = 20.0F, .w = 40.0F, .h = 60.0F};
    const gui::FanView view{.dest = dest, .u0 = 0.0F, .v0 = 0.25F, .u1 = 1.0F, .v1 = 0.75F};
    gui::round_fan(view, fan);
    context.expect(near_value(fan.at(0).x, 30.0F) && near_value(fan.at(0).y, 50.0F), "tâm quạt");
    context.expect(near_value(fan.at(1).x, 50.0F) && near_value(fan.at(1).y, 50.0F), "vành phải");
    context.expect(near_value(fan.at(11).y, 80.0F), "góc 90 độ ở đáy như renderer gốc");
    context.expect(near_value(fan.at(1).u, 1.0F) && near_value(fan.at(1).v, 0.5F), "uv vành phải");
}

// Một cửa sổ chữ: section "label" có một TextComponent phủ cả cửa sổ.
GuiAsset text_asset() {
    GuiAsset asset;
    gui::GuiText text;
    text.text = "Mau";
    fill_area(asset, text.area);
    asset.texts.push_back(text);
    gui::GuiSection section;
    section.name = "label";
    section.texts = range_of(0, 1);
    asset.sections.push_back(section);
    asset.specs.push_back(gui::GuiSpec{.section = 0, .overrides = false, .colour = {}});
    add_layer_state(asset, "Enabled", 0);
    gui::GuiLook look;
    look.name = "Label";
    look.states = range_of(0, 1);
    asset.looks.push_back(look);
    asset.types.push_back(gui::GuiType{.name = "TLBB_StaticText", .renderer = "Falagard/StaticText", .look = 0});
    add_window(asset, "PlayerFrame_Name", Slot{.type = 0, .parent = -1});
    add_property(asset, "AbsoluteSize", "w:80 h:16");
    return asset;
}

void text_run(Context& context) {
    const GuiAsset asset = text_asset();
    const Sheet sheet = gui::place(asset, screen_of(200.0F, 100.0F));
    context.expect(sheet.texts.size() == 1, "một dòng chữ");
    if (sheet.texts.size() != 1) return;
    context.expect(sheet.texts.at(0).text == "Mau", "đúng chữ");
    const Box want{.x = 0.0F, .y = 0.0F, .w = 80.0F, .h = 16.0F};
    context.expect(same_box(sheet.texts.at(0).box, want), "ô chữ bằng cửa sổ");
}

void round_map(Context& context) {
    GuiAsset asset;
    asset.types.push_back(gui::GuiType{.name = "TLBB_SceneMap", .renderer = "Falagard/SceneMap", .look = -1});
    add_window(asset, "MiniMap_MapArea", Slot{.type = 0, .parent = -1});
    add_property(asset, "AbsoluteSize", "w:140 h:140");
    add_property(asset, "RoundEnabled", "True");
    Place input;
    input.width = 800.0F;
    input.height = 600.0F;
    input.scene_width = 320.0F;
    input.scene_depth = 320.0F;
    input.player_x = 160.0F;
    input.player_z = 160.0F;
    const Sheet sheet = gui::place(asset, input);
    const auto is_map = [](const Quad& quad) { return quad.texture == gui::kSceneMap; };
    const auto map = std::ranges::find_if(sheet.quads, is_map);
    context.expect(map != sheet.quads.end(), "có quad ảnh cảnh");
    if (map == sheet.quads.end()) return;
    context.expect(map->is_round, "RoundEnabled thành quạt");
    context.expect(sheet.radar.has_value(), "ô radar được ghi lại");
}

// Một trạng thái vẽ đúng một ảnh kéo giãn cả cửa sổ.
void add_state(GuiAsset& asset, std::string name, std::int32_t image) {
    gui::GuiImagery imagery;
    fill_area(asset, imagery.area);
    imagery.image = image;
    imagery.horz.value = std::to_underlying(gui::GuiHorz::kStretched);
    imagery.vert.value = std::to_underlying(gui::GuiVert::kStretched);
    const auto slot = static_cast<std::uint32_t>(asset.imageries.size());
    asset.imageries.push_back(imagery);
    gui::GuiSection section;
    section.name = name;
    section.imageries = range_of(slot, 1);
    asset.sections.push_back(section);
    asset.specs.push_back(gui::GuiSpec{.section = static_cast<std::int32_t>(slot), .overrides = false, .colour = {}});
    add_layer_state(asset, std::move(name), slot);
}

// Ô túi trống: nền ActionBK vẽ trước icon, kể cả khi ô chưa có đồ.
GuiAsset slot_asset() {
    GuiAsset asset;
    GuiImage image = image_of("CommonItem", "ActionBK", 34.0F);
    image.texture = 0;
    image.x = 1.0F;
    image.y = 1.0F;
    asset.images.push_back(image);
    asset.textures.emplace_back("Common/Common_Item.dds");
    add_state(asset, "BackgroundImage", 0);
    gui::GuiSection normal;
    normal.name = "normal";
    asset.sections.push_back(normal);
    asset.specs.push_back(gui::GuiSpec{.section = 1, .overrides = false, .colour = {}});
    add_layer_state(asset, "Normal", 1);
    gui::GuiLook look;
    look.name = "TLBB_Look_ActionButton";
    look.states = range_of(0, 2);
    asset.looks.push_back(look);
    asset.types.push_back(gui::GuiType{.name = "TLBB_ActionButton", .renderer = "Falagard/ActionButton", .look = 0});
    add_window(asset, "Packet_Space_Line1_Row1_button", Slot{.type = 0, .parent = -1});
    add_property(asset, "AbsoluteSize", "w:35 h:35");
    return asset;
}

void slot_back(Context& context) {
    const GuiAsset asset = slot_asset();
    const Sheet sheet = gui::place(asset, screen_of(400.0F, 400.0F));
    context.expect(sheet.quads.size() == 1, "ô trống vẫn có nền ActionBK");
    if (sheet.quads.size() != 1) return;
    const Box source = sheet.quads.at(0).source;
    context.expect(source.w == 34.0F && source.h == 34.0F, "đúng ô ActionBK");
    const Box want{.x = 0.0F, .y = 0.0F, .w = 35.0F, .h = 35.0F};
    context.expect(same_box(sheet.quads.at(0).dest, want), "nền phủ cả ô");
}

void hub_keeps_still(Context& context) {
    const GuiAsset asset = bar_asset();
    Hub hub(asset);
    Place input = screen_of(200.0F, 200.0F);
    hub.update(input);
    const std::uint64_t still = hub.still_stamp();
    const std::uint64_t live = hub.live_stamp();
    hub.update(input);
    context.expect(hub.still_stamp() == still && hub.live_stamp() == live, "lặp không dàn lại");
    const gui::Bar bar{.window = "PlayerFrame_HP", .amount = 0.75F};
    input.bars = std::span{&bar, 1};
    hub.update(input);
    context.expect(hub.still_stamp() == still, "đổi máu không đụng trang tĩnh");
    context.expect(hub.live_stamp() != live, "đổi máu dựng lại thanh");
    const bool is_raised = !hub.live().empty() && near_value(hub.live().front().dest.w, 96.0F);
    context.expect(is_raised, "thanh tăng thì nhảy ngay tới ba phần tư");
}

// Bề rộng của quad đầu trang động (thanh máu của bar_asset, rộng 128).
float bar_width(const Hub& hub) {
    return hub.live().empty() ? -1.0F : hub.live().front().dest.w;
}

// FalagardSuperProgress: thanh giảm thì rút dần theo MoveSpeed (1 mỗi giây), bắt đầu từ
// CurrentProgress của cửa sổ; tăng thì nhảy ngay. Trượt xong thì không dựng lại nữa.
void bar_glides(Context& context) {
    const GuiAsset asset = bar_asset();
    Hub hub(asset);
    Place input = screen_of(200.0F, 200.0F);
    const gui::Bar low{.window = "PlayerFrame_HP", .amount = 0.25F};
    input.bars = std::span{&low, 1};
    hub.update(input);
    context.expect(near_value(bar_width(hub), 64.0F), "lần đầu còn ở CurrentProgress 0,5");
    input.clock = std::chrono::milliseconds{125};
    hub.update(input);
    context.expect(near_value(bar_width(hub), 48.0F), "sau 125 ms rút 0,125");
    input.clock = std::chrono::milliseconds{100};
    hub.update(input);
    context.expect(near_value(bar_width(hub), 48.0F), "đồng hồ lùi thì đứng yên");
    input.clock = std::chrono::milliseconds{2100};
    hub.update(input);
    context.expect(near_value(bar_width(hub), 32.0F), "trượt xong dừng ở đích");
    const std::uint64_t settled = hub.live_stamp();
    input.clock = std::chrono::milliseconds{5000};
    hub.update(input);
    context.expect(hub.live_stamp() == settled, "đã yên thì không dựng lại");
    const gui::Bar high{.window = "PlayerFrame_HP", .amount = 0.75F};
    input.bars = std::span{&high, 1};
    hub.update(input);
    context.expect(near_value(bar_width(hub), 96.0F), "tăng thì nhảy ngay");
    input.bars = std::span{&low, 1};
    const Sheet still = gui::place(asset, input);
    const bool is_settled = !still.quads.empty() && near_value(still.quads.front().dest.w, 32.0F);
    context.expect(is_settled, "place trả trang đã yên");
}

// Khung của mũi tên 30 khung (Minimap_arrow của client 2026) khi mặt quay về facing.
std::size_t frame_of(float facing) {
    return gui::arrow_frame(gui::ArrowTurn{.facing = facing, .frames = 30});
}

void arrow_frames(Context& context) {
    const float quarter = std::numbers::pi_v<float> / 2.0F;
    context.expect(frame_of(0.0F) == 0, "hướng +z là khung 0");
    context.expect(frame_of(quarter) == 7, "90 độ: 90 x 30 / 360");
    context.expect(frame_of(2.0F * quarter) == 15, "180 độ");
    context.expect(frame_of(-quarter) == 22, "-90 độ là 270 độ");
    // -12,5 độ là 347,5 độ, cắt còn 347: khung 28. Cắt -12,5 thành -12 rồi mới cộng 360 sẽ ra 29.
    context.expect(frame_of(-12.5F / 180.0F * 2.0F * quarter) == 28, "âm sát biên");
    context.expect(frame_of((4.0F * quarter) + 0.1F) == 0, "quá một vòng");
    context.expect(frame_of(std::nanf("")) == 0, "hướng hỏng");
    const gui::ArrowTurn empty{.facing = quarter, .frames = 0};
    context.expect(gui::arrow_frame(empty) == 0, "hoạt ảnh rỗng");
}

// Radar size (mặc định 140 x 140) giữa cảnh 320, mũi tên hai khung 32 x 32 (khung 0 hướng +z, khung 1
// hướng -z).
GuiAsset arrow_asset(std::string_view size = "w:140 h:140") {
    GuiAsset asset;
    GuiImage down = image_of("MiniMap_Arrow", "Arrow_00015", 32.0F);
    down.texture = 0;
    GuiImage back = image_of("MiniMap_Arrow", "Arrow_00000", 32.0F);
    back.texture = 0;
    back.x = 32.0F;
    asset.images.push_back(down);
    asset.images.push_back(back);
    asset.textures.emplace_back("Common/tga_MiniMap_Arrow.dds");
    gui::GuiAnimate arrow;
    arrow.name = "Minimap_arrow";
    arrow.frames = range_of(0, 2);
    asset.animates.push_back(arrow);
    asset.animate_frames = {0, 1};
    asset.types.push_back(gui::GuiType{.name = "TLBB_SceneMap", .renderer = "Falagard/SceneMap", .look = -1});
    add_window(asset, "MiniMap_MapArea", Slot{.type = 0, .parent = -1});
    add_property(asset, "AbsoluteSize", std::string(size));
    add_property(asset, "AnimateImage", "type:Animate9 animate:Minimap_Direction");
    add_property(asset, "AnimateImage", "type:Animate10 animate:Minimap_arrow");
    return asset;
}

Place radar_input() {
    Place input = screen_of(800.0F, 600.0F);
    input.scene_width = 320.0F;
    input.scene_depth = 320.0F;
    input.player_x = 160.0F;
    input.player_z = 160.0F;
    return input;
}

void radar_arrow(Context& context) {
    const GuiAsset asset = arrow_asset();
    Hub hub(asset);
    Place input = radar_input();
    hub.update(input);
    const auto is_arrow = [](const Quad& quad) { return quad.texture == 0; };
    const auto arrow = std::ranges::find_if(hub.live(), is_arrow);
    context.expect(arrow != hub.live().end(), "radar có mũi tên");
    if (arrow == hub.live().end()) return;
    const Box centred{.x = 54.0F, .y = 54.0F, .w = 32.0F, .h = 32.0F};
    context.expect(same_box(arrow->dest, centred), "cỡ gốc của ảnh, tâm ở người chơi");
    context.expect(arrow->source.x == 0.0F, "hướng +z là khung đầu");
    const auto is_dot = [](const Quad& quad) { return quad.texture == gui::kSolid; };
    context.expect(std::ranges::none_of(hub.live(), is_dot), "có mũi tên thì không còn chấm");
    const std::uint64_t before = hub.live_stamp();
    input.player_facing = std::numbers::pi_v<float>;
    hub.update(input);
    context.expect(hub.live_stamp() != before, "quay mặt dựng lại radar");
    const auto turned = std::ranges::find_if(hub.live(), is_arrow);
    const bool is_back = turned != hub.live().end() && turned->source.x == 32.0F;
    context.expect(is_back, "quay 180 độ sang khung hai");
}

// Radar cạnh lẻ (MiniMap của bản 2026 rộng 119): tâm rơi vào nửa điểm ảnh. Người chơi đi giữa cảnh thì vùng thấy
// trôi theo, mũi tên đứng yên đúng một ô; trước đây sai số số thực quanh .5 (86,49994 rồi 86,50003) làm phép làm tròn
// lật nó qua lại 1 px mỗi khung, mũi tên rung khi chạy.
void radar_arrow_steady(Context& context) {
    const GuiAsset asset = arrow_asset("w:119 h:119");
    const auto is_arrow = [](const Quad& quad) { return quad.texture == 0; };
    std::optional<Box> first;
    int moved = 0;
    for (const float scene : {320.0F, 448.0F, 512.0F}) {
        Place input = radar_input();
        input.scene_width = scene;
        input.scene_depth = scene;
        for (int step = 0; step < 1000; ++step) {
            input.player_x = 100.0F + (static_cast<float>(step) * 0.0693F);
            input.player_z = 200.0F - (static_cast<float>(step) * 0.0517F);
            const Sheet sheet = gui::place(asset, input);
            const auto arrow = std::ranges::find_if(sheet.quads, is_arrow);
            if (arrow == sheet.quads.end()) {
                ++moved;
                continue;
            }
            if (!first) first = arrow->dest;
            if (!same_box(arrow->dest, *first)) ++moved;
        }
    }
    context.expect(first.has_value(), "có mũi tên");
    context.expect(moved == 0, "đi giữa cảnh: mũi tên không lệch điểm ảnh nào");
}

// Người chơi ở góc cảnh: tâm mũi tên nằm sát mép radar nên ảnh bị cắt theo ô radar.
void radar_arrow_clipped(Context& context) {
    const GuiAsset asset = arrow_asset();
    Place input = radar_input();
    input.player_x = 0.0F;
    input.player_z = 160.0F;
    const Sheet sheet = gui::place(asset, input);
    const auto is_arrow = [](const Quad& quad) { return quad.texture == 0; };
    const auto arrow = std::ranges::find_if(sheet.quads, is_arrow);
    context.expect(arrow != sheet.quads.end(), "vẫn có mũi tên");
    if (arrow == sheet.quads.end()) return;
    const Box half{.x = 0.0F, .y = 54.0F, .w = 16.0F, .h = 32.0F};
    context.expect(same_box(arrow->dest, half), "chỉ còn nửa trong ô radar");
    const bool is_right_half = arrow->source.x == 16.0F && arrow->source.w == 16.0F;
    context.expect(is_right_half, "phần ảnh tương ứng là nửa phải");
}

// Layout không nêu mũi tên (hay bảng hoạt ảnh thiếu): giữ chấm vàng để vẫn thấy chỗ đứng.
void radar_dot_fallback(Context& context) {
    GuiAsset asset = arrow_asset();
    asset.animates.clear();
    const Sheet sheet = gui::place(asset, radar_input());
    const auto is_dot = [](const Quad& quad) { return quad.texture == gui::kSolid; };
    context.expect(std::ranges::count_if(sheet.quads, is_dot) == 1, "chấm thay mũi tên");
}

// Ô chân dung của client 2026: khung nền, cửa sổ chủ mặt nạ 80 x 80 ở (10, 4) chứa cửa sổ mô hình
// kín ô, và một ảnh anh em nằm ngoài. first và second là hai thuộc tính đầu của cửa sổ chủ (thứ tự
// RoundEnabled, MaskImage quyết định mặt nạ có hiệu lực không).
GuiAsset head_asset(const gui::GuiProperty& first, const gui::GuiProperty& second) {
    GuiAsset asset;
    GuiImage ring = image_of("CommonFrame8", "PlayerFrame", 64.0F);
    ring.texture = 0;
    GuiImage region = image_of("HeadRoundRegion", "RoundRegion", 80.0F);
    region.texture = 1;
    asset.images.push_back(ring);
    asset.images.push_back(region);
    asset.textures.emplace_back("Common/CommonFrame8.dds");
    asset.textures.emplace_back("Common/HeadRoundRegion.dds");
    gui::GuiType host;
    host.name = "TLBB_MeshWindow_ParentWindow";
    host.renderer = "Falagard/MeshWindow/ParentWindow";
    host.look = -1;
    asset.types.push_back(host);
    asset.types.push_back(gui::GuiType{.name = "TLBB_MeshWindowNBG", .renderer = "Falagard/MeshWindow", .look = -1});
    const std::string frame = "set:CommonFrame8 image:PlayerFrame";
    add_window(asset, "PlayerFrame_Background", Slot{.type = -1, .parent = -1});
    add_property(asset, "AbsoluteSize", "w:247 h:93");
    add_window(asset, "PlayerFrame_Head_Parent", Slot{.type = 0, .parent = 0});
    add_property(asset, first.name, first.value);
    add_property(asset, second.name, second.value);
    add_property(asset, "AbsolutePosition", "x:10 y:4");
    add_property(asset, "AbsoluteSize", "w:80 h:80");
    add_property(asset, "Image", frame);
    add_window(asset, "PlayerFrame_Head_3D", Slot{.type = 1, .parent = 1});
    add_property(asset, "Size", "w:1 h:1");
    add_property(asset, "FakeObject", "Player_Head");
    add_window(asset, "PlayerFrame_BG", Slot{.type = -1, .parent = 0});
    add_property(asset, "AbsoluteSize", "w:64 h:64");
    add_property(asset, "Image", frame);
    return asset;
}

const Quad* mesh_quad(const Sheet& sheet) {
    const auto is_mesh = [](const Quad& quad) { return quad.texture == gui::kMeshView; };
    const auto found = std::ranges::find_if(sheet.quads, is_mesh);
    return found == sheet.quads.end() ? nullptr : &*found;
}

// MaskImage của cửa sổ chủ che quad của con cháu; chính cửa sổ chủ và anh em của nó không bị che.
void mask_veils_children(Context& context) {
    const GuiAsset asset = head_asset(property("RoundEnabled", "True"), property("MaskImage", "HeadRoundRegion"));
    const Sheet sheet = gui::place(asset, screen_of(800.0F, 600.0F));
    const Quad* head = mesh_quad(sheet);
    context.expect(head != nullptr, "cửa sổ mô hình ra một quad");
    if (head == nullptr) return;
    const Box host{.x = 10.0F, .y = 4.0F, .w = 80.0F, .h = 80.0F};
    context.expect(same_box(head->dest, host) && head->view == "Player_Head", "ảnh kín ô, mang tên");
    context.expect(head->mask == 1, "mặt nạ là texture của imageset HeadRoundRegion");
    context.expect(same_box(head->mask_box, host), "mặt nạ phủ đúng ô cửa sổ chủ");
    const auto is_plain = [](const Quad& quad) { return quad.texture == 0; };
    const auto is_veiled = [](const Quad& quad) { return quad.texture == 0 && quad.mask >= 0; };
    context.expect(std::ranges::count_if(sheet.quads, is_plain) == 2, "ảnh của chủ và của anh em");
    context.expect(std::ranges::none_of(sheet.quads, is_veiled), "chủ và anh em không bị che");
}

// Setter của client 2026: MaskImage chỉ nạp khi RoundEnabled đã bật trước nó, và cờ phải còn bật.
void mask_needs_round_first(Context& context) {
    const GuiAsset swapped = head_asset(property("MaskImage", "HeadRoundRegion"), property("RoundEnabled", "True"));
    const Sheet late = gui::place(swapped, screen_of(800.0F, 600.0F));
    const Quad* late_head = mesh_quad(late);
    context.expect(late_head != nullptr && late_head->mask < 0, "MaskImage đặt trước thì không nạp");
    const GuiAsset off = head_asset(property("RoundEnabled", "False"), property("MaskImage", "HeadRoundRegion"));
    const Sheet flat = gui::place(off, screen_of(800.0F, 600.0F));
    const Quad* flat_head = mesh_quad(flat);
    context.expect(flat_head != nullptr && flat_head->mask < 0, "RoundEnabled tắt thì không che");
    const GuiAsset lost = head_asset(property("RoundEnabled", "True"), property("MaskImage", "KhongCo"));
    const Sheet bare = gui::place(lost, screen_of(800.0F, 600.0F));
    const Quad* bare_head = mesh_quad(bare);
    context.expect(bare_head != nullptr && bare_head->mask < 0, "imageset lạ thì không che");
}

// getPixelRect: ô mặt nạ là ô cửa sổ chủ cắt theo màn hình (và tổ tiên), nên màn hình hẹp làm mặt
// nạ co theo phần còn lại. Chưa gắn fake object thì cửa sổ mô hình không vẽ gì.
void mask_box_is_clipped(Context& context) {
    const GuiAsset asset = head_asset(property("RoundEnabled", "True"), property("MaskImage", "HeadRoundRegion"));
    const Sheet narrow = gui::place(asset, screen_of(50.0F, 600.0F));
    const Quad* head = mesh_quad(narrow);
    context.expect(head != nullptr, "vẫn có quad mô hình");
    if (head == nullptr) return;
    const Box clipped{.x = 10.0F, .y = 4.0F, .w = 40.0F, .h = 80.0F};
    context.expect(same_box(head->mask_box, clipped), "ô mặt nạ cắt theo màn hình");
    Place input = screen_of(800.0F, 600.0F);
    const Override unhooked{.window = "PlayerFrame_Head_3D", .name = "FakeObject", .value = ""};
    input.overrides = std::span{&unhooked, 1};
    const Sheet empty = gui::place(asset, input);
    context.expect(mesh_quad(empty) == nullptr, "chưa gắn fake object thì không vẽ");
}

// Thuộc tính đặt lúc chạy của ca portrait_fills_mask: gỡ fake object rồi đặt ảnh chân dung.
constexpr std::array kPortraitOverrides{
    Override{.window = "PlayerFrame_Head_3D", .name = "FakeObject", .value = ""},
    Override{.window = "PlayerFrame_Head_3D", .name = "Image", .value = "set:CommonFrame8 image:PlayerFrame"},
};

// Không có đầu 3D: thuộc tính Image của mesh window kéo giãn kín ô và vẫn nhận mặt nạ của cha.
void portrait_fills_mask(Context& context) {
    const GuiAsset asset = head_asset(property("RoundEnabled", "True"), property("MaskImage", "HeadRoundRegion"));
    Place input = screen_of(800.0F, 600.0F);
    input.overrides = kPortraitOverrides;
    const Sheet sheet = gui::place(asset, input);
    context.expect(mesh_quad(sheet) == nullptr, "không còn quad mô hình");
    const auto is_face = [](const Quad& quad) { return quad.mask == 1; };
    const auto face = std::ranges::find_if(sheet.quads, is_face);
    context.expect(face != sheet.quads.end(), "ảnh chân dung bị mặt nạ che");
    if (face == sheet.quads.end()) return;
    const Box host{.x = 10.0F, .y = 4.0F, .w = 80.0F, .h = 80.0F};
    const bool is_full = face->texture == 0 && same_box(face->dest, host);
    context.expect(is_full && same_box(face->mask_box, host), "ảnh phủ kín ô và mặt nạ phủ đúng ô");
}

// Falagard/MapImage: chưa chọn thì vẽ thuộc tính Image; SetCurrentImage chọn ảnh con theo tên.
void map_image(Context& context) {
    GuiAsset asset;
    GuiImage first = image_of("CommonStaticImage", "Minimap_Time1", 20.0F);
    first.texture = 0;
    GuiImage third = image_of("CommonStaticImage", "Minimap_Time3", 20.0F);
    third.texture = 0;
    third.x = 40.0F;
    asset.images.push_back(first);
    asset.images.push_back(third);
    asset.textures.emplace_back("Common/CommonStaticImage.dds");
    asset.types.push_back(gui::GuiType{.name = "TLBB_MapImage", .renderer = "Falagard/MapImage", .look = -1});
    add_window(asset, "MiniMap_ChineseTime", Slot{.type = 0, .parent = -1});
    add_property(asset, "AbsoluteSize", "w:20 h:20");
    add_property(asset, "Image", "set:CommonStaticImage image:Minimap_Time1");
    add_property(asset, "ChildImage", "name:Time1 set:CommonStaticImage image:Minimap_Time1");
    add_property(asset, "ChildImage", "name:Time3 set:CommonStaticImage image:Minimap_Time3");
    Place input = screen_of(100.0F, 100.0F);
    const Sheet plain = gui::place(asset, input);
    const bool is_default = plain.quads.size() == 1 && plain.quads.front().source.x == 0.0F;
    context.expect(is_default, "chưa chọn thì vẽ Image");
    const Override pick{.window = "MiniMap_ChineseTime", .name = "SetCurrentImage", .value = "Time3"};
    input.overrides = std::span{&pick, 1};
    const Sheet chosen = gui::place(asset, input);
    const bool is_third = chosen.quads.size() == 1 && chosen.quads.front().source.x == 40.0F;
    context.expect(is_third, "SetCurrentImage chọn ảnh con");
    const Box whole{.x = 0.0F, .y = 0.0F, .w = 20.0F, .h = 20.0F};
    context.expect(is_third && same_box(chosen.quads.front().dest, whole), "ảnh phủ cả cửa sổ");
    const Override lost{.window = "MiniMap_ChineseTime", .name = "SetCurrentImage", .value = "Time9"};
    input.overrides = std::span{&lost, 1};
    const Sheet unknown = gui::place(asset, input);
    const bool is_kept = unknown.quads.size() == 1 && unknown.quads.front().source.x == 0.0F;
    context.expect(is_kept, "tên lạ thì vẽ như chưa chọn");
}

void hit_child(Context& context) {
    GuiAsset asset;
    asset.images.push_back(image_of("Map", "Frame", 8.0F));
    add_window(asset, "PlayerFrame", Slot{.type = -1, .parent = -1});
    add_property(asset, "AbsolutePosition", "x:0 y:0");
    add_property(asset, "AbsoluteSize", "w:100 h:80");
    add_window(asset, "PlayerFrame_HP", Slot{.type = -1, .parent = 0});
    add_property(asset, "AbsolutePosition", "x:10 y:10");
    add_property(asset, "AbsoluteSize", "w:40 h:8");
    add_window(asset, "PlayerFrame_Back", Slot{.type = -1, .parent = 0});
    add_property(asset, "AbsolutePosition", "x:60 y:10");
    add_property(asset, "AbsoluteSize", "w:30 h:30");
    add_property(asset, "MouseHollow", "True");
    Hub hub(asset);
    hub.update(screen_of(200.0F, 200.0F));
    const auto on_child = hub.hit(15.0F, 14.0F, Probe::kAny);
    const auto on_hollow = hub.hit(70.0F, 20.0F, Probe::kAny);
    const auto outside = hub.hit(150.0F, 10.0F, Probe::kAny);
    context.expect(on_child && *on_child == "PlayerFrame_HP", "con nằm trên cha");
    context.expect(on_hollow && *on_hollow == "PlayerFrame", "MouseHollow rơi xuống cha");
    context.expect(!outside, "ngoài khung thì trượt");
}

void add_tile(GuiAsset& asset, std::string name, float left) {
    GuiImage image = image_of("Set", std::move(name), 10.0F);
    image.texture = 0;
    image.x = left;
    asset.images.push_back(std::move(image));
}

// Thêm count ô ảnh của imageset Set: tên là số thứ tự, ô thứ n nằm ở x = 10n.
void add_numbered_tiles(GuiAsset& asset, std::uint32_t count) {
    for (std::uint32_t tile = 0; tile < count; ++tile) {
        add_tile(asset, std::to_string(tile), static_cast<float>(tile) * 10.0F);
    }
}

// Look "Edit" của ô nhập với vùng TextArea như TLBB_Look_EditBoxNormal: vùng chữ bắt đầu dưới mép
// trên và dài quá mép dưới của cửa sổ.
void add_edit_look(GuiAsset& asset) {
    gui::GuiNamedArea text_area;
    text_area.name = "TextArea";
    const std::int32_t left = absolute(asset, 4.0F);
    const std::int32_t top = absolute(asset, 3.0F);
    const std::int32_t width = absolute(asset, 92.0F);
    const std::int32_t height = absolute(asset, 22.0F);
    text_area.area.dims = {left, top, width, height};
    asset.areas.push_back(text_area);
    gui::GuiLook edit_look;
    edit_look.name = "Edit";
    edit_look.areas = range_of(0, 1);
    asset.looks.push_back(edit_look);
}

// Ba cửa sổ của màn đăng nhập: nút chọn Pick, chữ đơn Label, ô nhập Name có TextArea lùi 4.
GuiAsset front_asset() {
    GuiAsset asset;
    asset.textures.emplace_back("Common/Set.dds");
    add_tile(asset, "Normal", 0.0F);
    add_tile(asset, "Pushed", 10.0F);
    add_tile(asset, "Off", 20.0F);
    add_state(asset, "Normal", 0);
    add_state(asset, "Pushed", 1);
    add_state(asset, "Disabled", 2);
    gui::GuiLook check_look;
    check_look.name = "Check";
    check_look.states = range_of(0, 3);
    asset.looks.push_back(check_look);
    add_edit_look(asset);
    asset.types.push_back(gui::GuiType{.name = "TLBB_Check", .renderer = "Falagard/CheckBox", .look = 0});
    asset.types.push_back(gui::GuiType{.name = "TLBB_SimpleText", .renderer = "Falagard/SimpleText", .look = -1});
    asset.types.push_back(gui::GuiType{.name = "TLBB_Edit", .renderer = "Falagard/IMEEditBox", .look = 1});
    add_window(asset, "Pick", Slot{.type = 0, .parent = -1});
    add_property(asset, "AbsoluteSize", "w:100 h:20");
    add_window(asset, "Label", Slot{.type = 1, .parent = -1});
    add_property(asset, "AbsolutePosition", "x:0 y:30");
    add_property(asset, "AbsoluteSize", "w:200 h:20");
    add_property(asset, "Text", "#{HELLO}");
    add_property(asset, "TextColor", "FFFEE601");
    add_property(asset, "HorzFormatting", "HorzCentred");
    add_window(asset, "Name", Slot{.type = 2, .parent = -1});
    add_property(asset, "AbsolutePosition", "x:0 y:60");
    add_property(asset, "AbsoluteSize", "w:100 h:20");
    return asset;
}

const Quad* quad_at(const Sheet& sheet, float top) {
    const auto is_there = [top](const Quad& quad) { return near_value(quad.dest.y, top); };
    const auto found = std::ranges::find_if(sheet.quads, is_there);
    return found == sheet.quads.end() ? nullptr : &*found;
}

const TextRun* run_at(const Sheet& sheet, float top) {
    const auto is_there = [top](const TextRun& run) { return run.box.y >= top && run.box.y < top + 20.0F; };
    const auto found = std::ranges::find_if(sheet.texts, is_there);
    return found == sheet.texts.end() ? nullptr : &*found;
}

// Bảng chuỗi mẫu: hai cột key và text.
gui::StringBook book_of(std::string_view text) {
    const table::TsvResult table = table::parse_tsv(text);
    core::check(table.has_value(), "bảng chuỗi mẫu phải đọc được");
    return gui::StringBook::from_table(*table);
}

// FalagardCheckButton::drawSelf: đang chọn mà không bị nhấn thì vẽ trạng thái Pushed.
void check_selected(Context& context) {
    const GuiAsset asset = front_asset();
    Place input = screen_of(300.0F, 200.0F);
    const Sheet plain = gui::place(asset, input);
    const Quad* normal = quad_at(plain, 0.0F);
    context.expect(normal != nullptr && near_value(normal->source.x, 0.0F), "chưa chọn vẽ Normal");
    const std::array picked = {Override{.window = "Pick", .name = "Selected", .value = "True"}};
    input.overrides = picked;
    const Sheet chosen = gui::place(asset, input);
    const Quad* pushed = quad_at(chosen, 0.0F);
    context.expect(pushed != nullptr && near_value(pushed->source.x, 10.0F), "đang chọn vẽ Pushed");
}

void disabled_button(Context& context) {
    const GuiAsset asset = front_asset();
    Place input = screen_of(300.0F, 200.0F);
    const std::array locked = {Override{.window = "Pick", .name = "Disabled", .value = "True"}};
    input.overrides = locked;
    input.pointer = gui::Pointer{.x = 5.0F, .y = 5.0F, .is_down = true};
    const Sheet sheet = gui::place(asset, input);
    const Quad* off = quad_at(sheet, 0.0F);
    context.expect(off != nullptr && near_value(off->source.x, 20.0F), "nút khoá vẽ Disabled");
}

// Nút dưới chuột vẽ Pushed khi nhấn; chuột ngoài nút thì vẽ Normal.
void pressed_button(Context& context) {
    const GuiAsset asset = front_asset();
    Place input = screen_of(300.0F, 200.0F);
    input.pointer = gui::Pointer{.x = 5.0F, .y = 5.0F, .is_down = true};
    const Sheet hit = gui::place(asset, input);
    const Quad* pushed = quad_at(hit, 0.0F);
    context.expect(pushed != nullptr && near_value(pushed->source.x, 10.0F), "nhấn trúng vẽ Pushed");
    input.pointer = gui::Pointer{.x = 250.0F, .y = 150.0F, .is_down = true};
    const Sheet missed = gui::place(asset, input);
    const Quad* normal = quad_at(missed, 0.0F);
    context.expect(normal != nullptr && near_value(normal->source.x, 0.0F), "nhấn trượt vẽ Normal");
}

// Màu nhãn của TLBB_Look_ButtonPageDown theo state, và màu riêng của thành phần ở ca nhân màu.
constexpr std::uint32_t kTabNormal = 0xFFFDEB78U;
constexpr std::uint32_t kTabPushed = 0xFFFFFF00U;
constexpr std::uint32_t kTabDisabled = 0xFFBBBBBBU;
constexpr std::uint32_t kHalfGrey = 0xFF808080U;

// Thêm state name vẽ section nhãn (section 0) qua một spec mang Colours tint.
void add_label_state(GuiAsset& asset, std::string name, std::uint32_t tint) {
    gui::GuiSpec spec;
    spec.section = 0;
    spec.overrides = true;
    spec.colour.colours.fill(tint);
    const auto slot = static_cast<std::uint32_t>(asset.specs.size());
    asset.specs.push_back(spec);
    add_layer_state(asset, std::move(name), slot);
}

// Thẻ trang của bảng nhân vật: nút chọn mà nhãn lấy chữ của cửa sổ, TextComponent mang màu own,
// mỗi state vẽ nhãn với một màu Colours.
GuiAsset tab_asset(std::uint32_t own) {
    GuiAsset asset;
    gui::GuiText text;
    fill_area(asset, text.area);
    text.colour.colours.fill(own);
    asset.texts.push_back(text);
    gui::GuiSection label;
    label.name = "label";
    label.texts = range_of(0, 1);
    asset.sections.push_back(label);
    add_label_state(asset, "Normal", kTabNormal);
    add_label_state(asset, "Pushed", kTabPushed);
    add_label_state(asset, "Disabled", kTabDisabled);
    gui::GuiLook look;
    look.name = "Tab";
    look.states = range_of(0, 3);
    asset.looks.push_back(look);
    asset.types.push_back(gui::GuiType{.name = "TLBB_ButtonPageDown", .renderer = "Falagard/CheckBox", .look = 0});
    add_window(asset, "Tab", Slot{.type = 0, .parent = -1});
    add_property(asset, "AbsoluteSize", "w:35 h:18");
    add_property(asset, "Text", "Thú");
    return asset;
}

// Màu dòng chữ của thẻ khi cửa sổ mang cờ flag (rỗng là không đặt cờ nào); nullopt khi thẻ không
// ra đúng một dòng chữ.
std::optional<std::uint32_t> tab_colour(const GuiAsset& asset, std::string_view flag) {
    Place input = screen_of(300.0F, 200.0F);
    const std::array forced = {Override{.window = "Tab", .name = flag, .value = "True"}};
    if (!flag.empty()) input.overrides = forced;
    const Sheet sheet = gui::place(asset, input);
    if (sheet.texts.size() != 1) return std::nullopt;
    return sheet.texts.at(0).colour;
}

// FalagardButton::doButtonRender vẽ StateImagery của đúng trạng thái đang có, nên nhãn mang màu
// Colours của state đó: thẻ khoá xám, thẻ đang chọn vàng.
void label_follows_state(Context& context) {
    const GuiAsset asset = tab_asset(gui::kWhiteArgb);
    context.expect(tab_colour(asset, {}) == kTabNormal, "thẻ thường mang màu của Normal");
    context.expect(tab_colour(asset, "Selected") == kTabPushed, "thẻ đang chọn mang màu Pushed");
    context.expect(tab_colour(asset, "Disabled") == kTabDisabled, "thẻ khoá mang màu Disabled");
}

// SectionSpecification::render rồi initColoursRect: Colours của spec nhân từng kênh với màu của
// thành phần, cả chữ lẫn ảnh, chứ không thay nó.
void section_colours_modulate(Context& context) {
    const GuiAsset tab = tab_asset(kHalfGrey);
    context.expect(tab_colour(tab, "Selected") == 0xFF808000U, "chữ: xám nhân vàng");
    context.expect(tab_colour(tab, "Disabled") == 0xFF5D5D5DU, "chữ: xám nhân xám, cắt số lẻ");
    GuiAsset front = front_asset();
    front.imageries.at(0).colour.colours.fill(kHalfGrey);
    front.specs.at(0).overrides = true;
    front.specs.at(0).colour.colours.fill(0xFFFF0000U);
    const Sheet sheet = gui::place(front, screen_of(300.0F, 200.0F));
    const Quad* normal = quad_at(sheet, 0.0F);
    context.expect(normal != nullptr && normal->colour == 0xFF800000U, "ảnh: xám nhân đỏ");
}

void override_hides(Context& context) {
    const GuiAsset asset = front_asset();
    const gui::StringBook book = book_of("key\ttext\nHELLO\tXin chào\n");
    Place input = screen_of(300.0F, 200.0F);
    input.strings = &book;
    context.expect(run_at(gui::place(asset, input), 30.0F) != nullptr, "có chữ khi chưa giấu");
    const std::array hidden = {Override{.window = "Label", .name = "Visible", .value = "False"}};
    input.overrides = hidden;
    context.expect(run_at(gui::place(asset, input), 30.0F) == nullptr, "Visible False giấu cửa sổ");
}

// FalagardSimpleText::populateRenderCache: chữ của cửa sổ, màu TextColor, canh theo HorzFormatting,
// mặc định giữa theo chiều dọc. #{ID} tra bảng chuỗi; không có bảng hay không có ID thì không vẽ.
void simple_text(Context& context) {
    const GuiAsset asset = front_asset();
    Place input = screen_of(300.0F, 200.0F);
    context.expect(run_at(gui::place(asset, input), 30.0F) == nullptr, "không bảng thì không vẽ");
    const gui::StringBook book = book_of("key\ttext\nHELLO\tXin chào\n");
    input.strings = &book;
    const Sheet sheet = gui::place(asset, input);
    const TextRun* run = run_at(sheet, 30.0F);
    context.expect(run != nullptr, "có dòng chữ");
    if (run == nullptr) return;
    context.expect(run->text == "Xin chào", "chữ tra từ bảng");
    context.expect(run->colour == 0xFFFEE601U, "màu TextColor");
    context.expect(run->horz == 2 && run->vert == 1, "HorzCentred, giữa theo chiều dọc");
    const Box want{.x = 0.0F, .y = 30.0F, .w = 200.0F, .h = 20.0F};
    context.expect(same_box(run->box, want), "ô chữ bằng cửa sổ");
    const std::array said = {Override{.window = "Label", .name = "Text", .value = "Tạm biệt"}};
    input.overrides = said;
    const Sheet other = gui::place(asset, input);
    const TextRun* forced = run_at(other, 30.0F);
    context.expect(forced != nullptr && forced->text == "Tạm biệt", "Text đặt lúc chạy thắng");
}

// Thuộc tính đặt lúc chạy của ca edit_box: ô Name đã gõ "an" và đang nhập.
constexpr std::array kTypedName{
    Override{.window = "Name", .name = "Text", .value = "an"},
    Override{.window = "Name", .name = "Caret", .value = "True"},
};

// FalagardIMEEditBox::populateRenderCache: bề ngang của dòng chữ là TextArea của look, còn chiều dọc
// là cả cửa sổ (dòng chữ và con nháy nằm giữa chiều cao ô, không theo mép trên dưới của TextArea);
// canh trái; có nháy khi đang nhập.
void edit_box(Context& context) {
    const GuiAsset asset = front_asset();
    Place input = screen_of(300.0F, 200.0F);
    context.expect(run_at(gui::place(asset, input), 60.0F) == nullptr, "ô rỗng không nháy");
    input.overrides = kTypedName;
    const Sheet sheet = gui::place(asset, input);
    const TextRun* run = run_at(sheet, 60.0F);
    context.expect(run != nullptr, "có dòng của ô nhập");
    if (run == nullptr) return;
    context.expect(run->text == "an" && run->has_caret, "chữ đã gõ và con nháy");
    // viết mới, không phải bản gốc — xem docs/AUDIT/evidence/gui_sheet_lost_cases_v6.md
    context.expect(run->is_plain, "chữ người chơi gõ là nguyên văn, dấu # không thành thẻ");
    const Box want{.x = 4.0F, .y = 60.0F, .w = 92.0F, .h = 20.0F};
    context.expect(same_box(run->box, want), "ngang theo TextArea, dọc theo cả cửa sổ");
    context.expect(run->horz == 0 && run->vert == 1, "canh trái, giữa theo chiều dọc");
    const std::array blank = {Override{.window = "Name", .name = "Caret", .value = "True"}};
    input.overrides = blank;
    const Sheet empty = gui::place(asset, input);
    const TextRun* caret = run_at(empty, 60.0F);
    context.expect(caret != nullptr && caret->text.empty() && caret->has_caret, "ô rỗng vẫn nháy");
}

void hub_follows_overrides(Context& context) {
    const GuiAsset asset = front_asset();
    Hub hub(asset);
    Place input = screen_of(300.0F, 200.0F);
    std::string text = "an";
    std::array typed = {Override{.window = "Name", .name = "Text", .value = text}};
    input.overrides = typed;
    hub.update(input);
    const std::uint64_t still = hub.still_stamp();
    hub.update(input);
    context.expect(hub.still_stamp() == still, "thuộc tính không đổi thì không dàn lại");
    text = "anh";
    typed.at(0).value = text;
    hub.update(input);
    context.expect(hub.still_stamp() != still, "gõ thêm thì dàn lại");
    // Hub giữ bản chép: chuỗi của người gọi đổi sau update không được làm hỏng dòng chữ.
    text = "xxx";
    const std::span<const TextRun> runs = hub.texts();
    context.expect(runs.size() == 1 && runs.front().text == "anh", "chữ không mượn của người gọi");
}

void string_book(Context& context) {
    const gui::StringBook book = book_of("key\ttext\nA\tmột\n# ghi chú\nB\thai\nA\tba\n");
    context.expect(book.size() == 2, "hai ID, dòng chú thích bỏ");
    context.expect(book.find("A") == std::string_view{"ba"}, "ID lặp thì dòng sau thắng");
    context.expect(book.find("B") == std::string_view{"hai"}, "tra theo khoá");
    context.expect(!book.find("C").has_value(), "ID lạ không có");
    const table::TsvResult wrong = table::parse_tsv("id\tvalue\nA\tx\n");
    context.expect(wrong && gui::StringBook::from_table(*wrong).size() == 0, "thiếu cột thì rỗng");
}

// Bảng dịch nạp đè: khoá trùng thì bản dịch thắng, khoá chưa dịch giữ chữ gốc; khoá "=" nối nguyên
// văn là bản dịch của chữ viết thẳng trong layout.
void string_overlay(Context& context) {
    gui::StringBook book = book_of("key\ttext\nHP\t血\nMP\t氣\n");
    constexpr std::string_view kVietnamese = "key\ttext\nHP\tMáu\n=帮助\tTrợ giúp\n=门派手册\tSổ tay môn phái\nép\tx\n";
    const table::TsvResult over = table::parse_tsv(kVietnamese);
    context.expect(over.has_value(), "bảng dịch đọc được");
    if (!over) return;
    book.overlay(*over);
    context.expect(book.find("HP") == std::string_view{"Máu"}, "khoá trùng: bản dịch thắng");
    context.expect(book.find("MP") == std::string_view{"氣"}, "khoá chưa dịch giữ chữ gốc");
    context.expect(book.find_literal("帮助") == std::string_view{"Trợ giúp"}, "chữ viết thẳng");
    context.expect(book.find_literal("门派手册") == std::string_view{"Sổ tay môn phái"}, "dòng kế");
    context.expect(!book.find_literal("帮").has_value(), "tiền tố không khớp");
    context.expect(!book.find_literal("HP").has_value(), "khoá thường không phải chữ viết thẳng");
    context.expect(!book.find("帮助").has_value(), "nguyên văn không tra được như một ID");
}

// Chữ viết thẳng trong layout (không qua #{ID}) được thay bằng bản dịch khi bảng có.
void literal_text_translated(Context& context) {
    const GuiAsset asset = front_asset();
    const gui::StringBook book = book_of("key\ttext\n=門派\tMôn phái\n");
    Place input = screen_of(300.0F, 200.0F);
    const std::array said = {Override{.window = "Label", .name = "Text", .value = "門派"}};
    input.overrides = said;
    const Sheet plain_sheet = gui::place(asset, input);
    const TextRun* plain = run_at(plain_sheet, 30.0F);
    context.expect(plain != nullptr && plain->text == "門派", "không bảng thì nguyên văn");
    input.strings = &book;
    const Sheet sheet = gui::place(asset, input);
    const TextRun* run = run_at(sheet, 30.0F);
    context.expect(run != nullptr && run->text == "Môn phái", "có bản dịch thì dùng bản dịch");
}

// Hai anh em: First luôn-trên-cùng khai trước, Second thường khai sau. Thường vẽ trước, luôn-trên-
// cùng vẽ sau; con vẽ ngay sau cha.
void draw_order(Context& context) {
    GuiAsset asset;
    add_numbered_tiles(asset, 3);
    asset.textures.emplace_back("Common/Set.dds");
    add_window(asset, "First", Slot{.type = -1, .parent = -1});
    add_property(asset, "AlwaysOnTop", "True");
    add_property(asset, "AbsoluteSize", "w:10 h:10");
    add_property(asset, "Image", "set:Set image:0");
    add_window(asset, "Second", Slot{.type = -1, .parent = -1});
    add_property(asset, "AbsoluteSize", "w:10 h:10");
    add_property(asset, "Image", "set:Set image:1");
    add_window(asset, "Second_Child", Slot{.type = -1, .parent = 1});
    add_property(asset, "AbsoluteSize", "w:10 h:10");
    add_property(asset, "Image", "set:Set image:2");
    const Sheet sheet = gui::place(asset, screen_of(100.0F, 100.0F));
    context.expect(sheet.quads.size() == 3, "ba ảnh");
    if (sheet.quads.size() != 3) return;
    context.expect(near_value(sheet.quads.at(0).source.x, 10.0F), "Second (thường) vẽ trước");
    context.expect(near_value(sheet.quads.at(1).source.x, 20.0F), "con vẽ ngay sau cha");
    context.expect(near_value(sheet.quads.at(2).source.x, 0.0F), "First (luôn trên cùng) vẽ cuối");
}

// Hai anh em cùng luôn-trên-cùng chồng nhau: khai sau nằm trên, lúc vẽ lẫn lúc dò chuột. CEGUI gắn
// cửa sổ vào cha rồi mới đặt thuộc tính, và setAlwaysOnTop đưa nó ra cuối danh sách vẽ của cha
// (Window::addWindowToDrawList), nên nút của thanh menu nằm trên khung ô kỹ năng khai trước nó.
void top_siblings_keep_order(Context& context) {
    GuiAsset asset;
    add_numbered_tiles(asset, 2);
    asset.textures.emplace_back("Common/Set.dds");
    add_window(asset, "Frame", Slot{.type = -1, .parent = -1});
    add_property(asset, "AlwaysOnTop", "True");
    add_property(asset, "AbsoluteSize", "w:30 h:10");
    add_property(asset, "Image", "set:Set image:0");
    add_window(asset, "Button", Slot{.type = -1, .parent = -1});
    add_property(asset, "AlwaysOnTop", "True");
    add_property(asset, "AbsoluteSize", "w:10 h:10");
    add_property(asset, "Image", "set:Set image:1");
    Hub hub(asset);
    hub.update(screen_of(100.0F, 100.0F));
    const std::span<const Quad> quads = hub.still();
    context.expect(quads.size() == 2, "hai ảnh");
    if (quads.size() != 2) return;
    context.expect(near_value(quads[0].source.x, 0.0F), "Frame khai trước vẽ trước");
    context.expect(near_value(quads[1].source.x, 10.0F), "Button khai sau vẽ sau");
    const auto on_both = hub.hit(5.0F, 5.0F, Probe::kAny);
    const auto on_frame = hub.hit(20.0F, 5.0F, Probe::kAny);
    context.expect(on_both == std::string_view{"Button"}, "chỗ chồng nhau trúng Button");
    context.expect(on_frame == std::string_view{"Frame"}, "ngoài Button trúng Frame");
}

// MouseLButtonHollow chỉ thủng với nút trái: bấm trái rơi xuống cửa sổ bên dưới, còn dò thường
// vẫn trúng nó, như nEventType 1 và 0 của Window::getChildAtPosition.
void left_hollow(Context& context) {
    GuiAsset asset;
    add_window(asset, "Slot", Slot{.type = -1, .parent = -1});
    add_property(asset, "AbsoluteSize", "w:20 h:20");
    add_window(asset, "Mask", Slot{.type = -1, .parent = -1});
    add_property(asset, "AbsoluteSize", "w:20 h:20");
    add_property(asset, "MouseLButtonHollow", "True");
    Hub hub(asset);
    hub.update(screen_of(100.0F, 100.0F));
    const auto hovered = hub.hit(5.0F, 5.0F, Probe::kAny);
    const auto pressed = hub.hit(5.0F, 5.0F, Probe::kLeftButton);
    context.expect(hovered == std::string_view{"Mask"}, "dò thường trúng Mask");
    context.expect(pressed == std::string_view{"Slot"}, "bấm trái xuyên qua Mask");
}

// Hai cửa sổ gốc chồng nhau: thứ tự kê trong roots là thứ tự vẽ (kê sau nằm trên), quad mang số
// lớp của gốc chứa nó để bộ vẽ xếp trọn một bảng (ảnh, thanh, chữ) rồi mới tới bảng kế.
void root_layers(Context& context) {
    GuiAsset asset;
    add_numbered_tiles(asset, 3);
    asset.textures.emplace_back("Common/Set.dds");
    add_window(asset, "Bar", Slot{.type = -1, .parent = -1});
    add_property(asset, "AbsoluteSize", "w:10 h:10");
    add_property(asset, "Image", "set:Set image:0");
    add_window(asset, "Bar_Slot", Slot{.type = -1, .parent = 0});
    add_property(asset, "AbsoluteSize", "w:10 h:10");
    add_property(asset, "Image", "set:Set image:1");
    add_window(asset, "Bag", Slot{.type = -1, .parent = -1});
    add_property(asset, "AbsoluteSize", "w:10 h:10");
    add_property(asset, "Image", "set:Set image:2");
    const std::array<std::string_view, 2> listed = {"Bag", "Bar"};
    Place input = screen_of(100.0F, 100.0F);
    input.roots = listed;
    Hub hub(asset);
    hub.update(input);
    const std::span<const Quad> quads = hub.still();
    context.expect(quads.size() == 3, "ba ảnh");
    if (quads.size() != 3) return;
    context.expect(near_value(quads[0].source.x, 20.0F), "Bag kê trước nên vẽ trước");
    context.expect(quads[0].layer == 0, "gốc vẽ đầu là lớp 0");
    context.expect(near_value(quads[1].source.x, 0.0F), "Bar kê sau nên vẽ sau");
    context.expect(quads[1].layer == 1 && quads[2].layer == 1, "con cùng lớp với gốc của nó");
    const auto top = hub.hit(5.0F, 5.0F, Probe::kAny);
    context.expect(top == std::string_view{"Bar_Slot"}, "gốc kê sau nằm trên khi dò chuột");
}

// Dòng chữ mang tên phông của cửa sổ (thuộc tính Font) và số lớp của gốc chứa nó.
void text_font(Context& context) {
    const GuiAsset asset = front_asset();
    const gui::StringBook book = book_of("key\ttext\nHELLO\tXin chào\n");
    Place input = screen_of(300.0F, 200.0F);
    input.strings = &book;
    // Giữ Sheet trong biến: run_at trả con trỏ vào texts của nó.
    const Sheet bare = gui::place(asset, input);
    const TextRun* plain = run_at(bare, 30.0F);
    context.expect(plain != nullptr && plain->font.empty(), "không nêu Font thì phông mặc định");
    const std::array said = {Override{.window = "Label", .name = "Font", .value = "YouYuan18"}};
    input.overrides = said;
    const Sheet sheet = gui::place(asset, input);
    const TextRun* run = run_at(sheet, 30.0F);
    context.expect(run != nullptr && run->font == "YouYuan18", "phông lấy từ thuộc tính Font");
}

// Ô ảnh minimap của cảnh: Scene/jpg_<token>_<cột>_<hàng>.png, như tệp gốc jpg_<token>_x_y.dds.
void radar_tiles_path(Context& context) {
    const std::string path = gui::radar_tile_path("huoyangu", 1, 0);
    context.expect(path == "Scene/jpg_huoyangu_1_0.png", "tên ô theo token, cột, hàng");
    context.expect(gui::radar_tile_path("", 0, 0).empty(), "không token thì không có ô");
    context.expect(gui::radar_tile_path("luoyang_SP", -1, 0).empty(), "cột âm thì không có ô");
}

// Bảng 400x200 đặt ở (30, 40) cùng các con, mỗi con thử một quy tắc đặt cửa sổ của CEGUIBase.dll
// 2026. Kiểu 0 là DefaultWindow.
GuiAsset geometry_asset() {
    GuiAsset asset;
    gui::GuiType sheet;
    sheet.name = "DefaultWindow";
    asset.types.push_back(sheet);
    const Slot child{.type = -1, .parent = 0};
    add_window(asset, "Panel", Slot{.type = 0, .parent = -1});
    add_property(asset, "UnifiedPosition", "{{0,30},{0,40}}");
    add_property(asset, "UnifiedSize", "{{0,400},{0,200}}");
    add_window(asset, "Fill", Slot{.type = 0, .parent = 0});
    add_window(asset, "Bare", child);
    add_window(asset, "Edge", child);
    add_property(asset, "UnifiedXPosition", "{1.0,-44}");
    add_property(asset, "UnifiedYPosition", "{0.25,70}");
    add_property(asset, "AbsoluteSize", "w:44 h:20");
    add_window(asset, "Centre", child);
    add_property(asset, "UnifiedSize", "{{0,101},{0,50}}");
    add_property(asset, "HorizontalAlignment", "Centre");
    add_property(asset, "VerticalAlignment", "Bottom");
    add_window(asset, "Right", child);
    add_property(asset, "UnifiedPosition", "{{0,-10},{0,5}}");
    add_property(asset, "UnifiedSize", "{{0,200},{0,50}}");
    add_property(asset, "HorizontalAlignment", "Right");
    add_window(asset, "Kept", child);
    add_property(asset, "UnifiedSize", "{{0,100},{0,50}}");
    add_property(asset, "AbsoluteSize", "w:-10 h:20");
    add_property(asset, "Size", "w:0.5 h:-0.5");
    add_window(asset, "Ratio", child);
    add_property(asset, "RelativePosition", "x:0.5 y:0.25");
    add_property(asset, "RelativeSize", "w:0.25 h:0.5");
    add_window(asset, "Negative", child);
    add_property(asset, "AbsolutePosition", "x:-4 y:-1.5");
    add_property(asset, "AbsoluteSize", "w:10 h:10");
    return asset;
}

// Ô mong đợi của một cửa sổ và quy tắc nó thử.
struct Expected {
    std::string_view window;
    Box box;
    std::string_view rule;
};

// Ô trên màn hình 1000 x 600 của các cửa sổ trong geometry_asset; Fill nằm trùng ô của Panel.
constexpr Box kPanelBox{.x = 30.0F, .y = 40.0F, .w = 400.0F, .h = 200.0F};
constexpr Box kBareBox{.x = 30.0F, .y = 40.0F, .w = 0.0F, .h = 0.0F};
constexpr Box kEdgeBox{.x = 386.0F, .y = 160.0F, .w = 44.0F, .h = 20.0F};
constexpr Box kCentreBox{.x = 179.5F, .y = 190.0F, .w = 101.0F, .h = 50.0F};
constexpr Box kRightBox{.x = 220.0F, .y = 45.0F, .w = 200.0F, .h = 50.0F};
constexpr Box kKeptBox{.x = 30.0F, .y = 40.0F, .w = 100.0F, .h = 50.0F};
constexpr Box kRatioBox{.x = 230.0F, .y = 90.0F, .w = 100.0F, .h = 100.0F};
constexpr Box kNegativeBox{.x = 27.0F, .y = 39.0F, .w = 10.0F, .h = 10.0F};

constexpr std::array kWantedBoxes{
    Expected{.window = "Panel", .box = kPanelBox, .rule = "bảng đặt theo UDim"},
    Expected{.window = "Fill", .box = kPanelBox, .rule = "DefaultWindow phủ kín cha"},
    Expected{.window = "Bare", .box = kBareBox, .rule = "kiểu khác bắt đầu từ cỡ 0"},
    Expected{.window = "Edge", .box = kEdgeBox, .rule = "UnifiedX/YPosition"},
    Expected{.window = "Centre", .box = kCentreBox, .rule = "căn giữa, căn đáy"},
    Expected{.window = "Right", .box = kRightBox, .rule = "căn phải cộng vị trí"},
    Expected{.window = "Kept", .box = kKeptBox, .rule = "cỡ âm bị bỏ qua"},
    Expected{.window = "Ratio", .box = kRatioBox, .rule = "Relative* theo cha"},
    Expected{.window = "Negative", .box = kNegativeBox, .rule = "toạ độ âm cắt về 0"},
};

void window_geometry(Context& context) {
    const GuiAsset asset = geometry_asset();
    Hub hub(asset);
    hub.update(screen_of(1000.0F, 600.0F));
    const auto is_placed = [&hub](const Expected& item) {
        const std::optional<Box> box = hub.box(item.window);
        return box && same_box(*box, item.box);
    };
    for (const Expected& item : kWantedBoxes) {
        context.expect(is_placed(item), item.rule);
    }
}

constexpr std::array kCases{
    Case{.name = "placed_windows", .body = &placed_windows},
    Case{.name = "area_size_is_max_minus_min", .body = &area_size_is_max_minus_min},
    Case{.name = "fixed_parent_does_not_resize_children", .body = &fixed_parent_does_not_resize_children},
    Case{.name = "half_bar", .body = &half_bar},
    Case{.name = "radar_center", .body = &radar_center},
    Case{.name = "radar_grid", .body = &radar_grid},
    Case{.name = "round_edge", .body = &round_edge},
    Case{.name = "text_run", .body = &text_run},
    Case{.name = "round_map", .body = &round_map},
    Case{.name = "hub_keeps_still", .body = &hub_keeps_still},
    Case{.name = "bar_glides", .body = &bar_glides},
    Case{.name = "arrow_frames", .body = &arrow_frames},
    Case{.name = "radar_arrow", .body = &radar_arrow},
    Case{.name = "radar_arrow_steady", .body = &radar_arrow_steady},
    Case{.name = "radar_arrow_clipped", .body = &radar_arrow_clipped},
    Case{.name = "radar_dot_fallback", .body = &radar_dot_fallback},
    Case{.name = "map_image", .body = &map_image},
    Case{.name = "mask_veils_children", .body = &mask_veils_children},
    Case{.name = "mask_needs_round_first", .body = &mask_needs_round_first},
    Case{.name = "mask_box_is_clipped", .body = &mask_box_is_clipped},
    Case{.name = "portrait_fills_mask", .body = &portrait_fills_mask},
    Case{.name = "hit_child", .body = &hit_child},
    Case{.name = "slot_back", .body = &slot_back},
    Case{.name = "check_selected", .body = &check_selected},
    Case{.name = "disabled_button", .body = &disabled_button},
    Case{.name = "pressed_button", .body = &pressed_button},
    Case{.name = "label_follows_state", .body = &label_follows_state},
    Case{.name = "section_colours_modulate", .body = &section_colours_modulate},
    Case{.name = "override_hides", .body = &override_hides},
    Case{.name = "simple_text", .body = &simple_text},
    Case{.name = "edit_box", .body = &edit_box},
    Case{.name = "hub_follows_overrides", .body = &hub_follows_overrides},
    Case{.name = "string_book", .body = &string_book},
    Case{.name = "string_overlay", .body = &string_overlay},
    Case{.name = "literal_text_translated", .body = &literal_text_translated},
    Case{.name = "draw_order", .body = &draw_order},
    Case{.name = "top_siblings_keep_order", .body = &top_siblings_keep_order},
    Case{.name = "left_hollow", .body = &left_hollow},
    Case{.name = "root_layers", .body = &root_layers},
    Case{.name = "text_font", .body = &text_font},
    Case{.name = "radar_tiles_path", .body = &radar_tiles_path},
    Case{.name = "window_geometry", .body = &window_geometry},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "gui_sheet_tests: mọi ca phải qua");
    return 0;
}
