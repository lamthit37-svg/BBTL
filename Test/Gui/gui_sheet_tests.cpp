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

// Radar 140 x 140 giữa cảnh 320, mũi tên hai khung 32 x 32 (khung 0 hướng +z, khung 1 hướng -z).
GuiAsset arrow_asset() {
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
    add_property(asset, "AbsoluteSize", "w:140 h:140");
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

// FalagardIMEEditBox::populateRenderCache: bề ngang của dòng chữ là TextArea của look, còn chiều dọc
// là cả cửa sổ (dòng chữ và con nháy nằm giữa chiều cao ô, không theo mép trên dưới của TextArea);
// canh trái; có nháy khi đang nhập.
void edit_box(Context& context) {
    const GuiAsset asset = front_asset();
    Place input = screen_of(300.0F, 200.0F);
    context.expect(run_at(gui::place(asset, input), 60.0F) == nullptr, "ô rỗng không nháy");
    const std::array typed = {Override{.window = "Name", .name = "Text", .value = "an"},
        Override{.window = "Name", .name = "Caret", .value = "True"}};
    input.overrides = typed;
    const Sheet sheet = gui::place(asset, input);
    const TextRun* run = run_at(sheet, 60.0F);
    context.expect(run != nullptr, "có dòng của ô nhập");
    if (run == nullptr) return;
    context.expect(run->text == "an" && run->has_caret, "chữ đã gõ và con nháy");
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
    for (std::uint32_t tile = 0; tile < 3; ++tile)
        add_tile(asset, std::to_string(tile), static_cast<float>(tile) * 10.0F);
    asset.textures.emplace_back("Common/Set.dds");
    add_window(asset, "First", Slot{.type = -1, .parent = -1},
        {property("AlwaysOnTop", "True"), property("AbsoluteSize", "w:10 h:10"), property("Image", "set:Set image:0")});
    add_window(asset, "Second", Slot{.type = -1, .parent = -1},
        {property("AbsoluteSize", "w:10 h:10"), property("Image", "set:Set image:1")});
    add_window(asset, "Second_Child", Slot{.type = -1, .parent = 1},
        {property("AbsoluteSize", "w:10 h:10"), property("Image", "set:Set image:2")});
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
    for (std::uint32_t tile = 0; tile < 2; ++tile)
        add_tile(asset, std::to_string(tile), static_cast<float>(tile) * 10.0F);
    asset.textures.emplace_back("Common/Set.dds");
    add_window(asset, "Frame", Slot{.type = -1, .parent = -1},
        {property("AlwaysOnTop", "True"), property("AbsoluteSize", "w:30 h:10"), property("Image", "set:Set image:0")});
    add_window(asset, "Button", Slot{.type = -1, .parent = -1},
        {property("AlwaysOnTop", "True"), property("AbsoluteSize", "w:10 h:10"), property("Image", "set:Set image:1")});
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
    add_window(asset, "Slot", Slot{.type = -1, .parent = -1}, {property("AbsoluteSize", "w:20 h:20")});
    add_window(asset, "Mask", Slot{.type = -1, .parent = -1},
        {property("AbsoluteSize", "w:20 h:20"), property("MouseLButtonHollow", "True")});
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
    for (std::uint32_t tile = 0; tile < 3; ++tile)
        add_tile(asset, std::to_string(tile), static_cast<float>(tile) * 10.0F);
    asset.textures.emplace_back("Common/Set.dds");
    add_window(asset, "Bar", Slot{.type = -1, .parent = -1},
        {property("AbsoluteSize", "w:10 h:10"), property("Image", "set:Set image:0")});
    add_window(asset, "Bar_Slot", Slot{.type = -1, .parent = 0},
        {property("AbsoluteSize", "w:10 h:10"), property("Image", "set:Set image:1")});
    add_window(asset, "Bag", Slot{.type = -1, .parent = -1},
        {property("AbsoluteSize", "w:10 h:10"), property("Image", "set:Set image:2")});
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
    add_window(asset, "Panel", Slot{.type = 0, .parent = -1},
        {property("UnifiedPosition", "{{0,30},{0,40}}"), property("UnifiedSize", "{{0,400},{0,200}}")});
    add_window(asset, "Fill", Slot{.type = 0, .parent = 0}, {});
    add_window(asset, "Bare", child, {});
    add_window(asset, "Edge", child,
        {property("UnifiedXPosition", "{1.0,-44}"), property("UnifiedYPosition", "{0.25,70}"),
            property("AbsoluteSize", "w:44 h:20")});
    add_window(asset, "Centre", child,
        {property("UnifiedSize", "{{0,101},{0,50}}"), property("HorizontalAlignment", "Centre"),
            property("VerticalAlignment", "Bottom")});
    add_window(asset, "Right", child,
        {property("UnifiedPosition", "{{0,-10},{0,5}}"), property("UnifiedSize", "{{0,200},{0,50}}"),
            property("HorizontalAlignment", "Right")});
    add_window(asset, "Kept", child,
        {property("UnifiedSize", "{{0,100},{0,50}}"), property("AbsoluteSize", "w:-10 h:20"),
            property("Size", "w:0.5 h:-0.5")});
    add_window(asset, "Ratio", child,
        {property("RelativePosition", "x:0.5 y:0.25"), property("RelativeSize", "w:0.25 h:0.5")});
    add_window(asset, "Negative", child,
        {property("AbsolutePosition", "x:-4 y:-1.5"), property("AbsoluteSize", "w:10 h:10")});
    return asset;
}

// Ô mong đợi của một cửa sổ và quy tắc nó thử.
struct Expected {
    std::string_view window;
    Box box;
    std::string_view rule;
};

void window_geometry(Context& context) {
    const GuiAsset asset = geometry_asset();
    Hub hub(asset);
    hub.update(screen_of(1000.0F, 600.0F));
    const std::array<Expected, 9> wanted = {{
        {.window = "Panel", .box = Box{.x = 30.0F, .y = 40.0F, .w = 400.0F, .h = 200.0F}, .rule = "bảng đặt theo UDim"},
        {.window = "Fill",
            .box = Box{.x = 30.0F, .y = 40.0F, .w = 400.0F, .h = 200.0F},
            .rule = "DefaultWindow phủ kín cha"},
        {.window = "Bare",
            .box = Box{.x = 30.0F, .y = 40.0F, .w = 0.0F, .h = 0.0F},
            .rule = "kiểu khác bắt đầu từ cỡ 0"},
        {.window = "Edge", .box = Box{.x = 386.0F, .y = 160.0F, .w = 44.0F, .h = 20.0F}, .rule = "UnifiedX/YPosition"},
        {.window = "Centre",
            .box = Box{.x = 179.5F, .y = 190.0F, .w = 101.0F, .h = 50.0F},
            .rule = "căn giữa, căn đáy"},
        {.window = "Right",
            .box = Box{.x = 220.0F, .y = 45.0F, .w = 200.0F, .h = 50.0F},
            .rule = "căn phải cộng vị trí"},
        {.window = "Kept", .box = Box{.x = 30.0F, .y = 40.0F, .w = 100.0F, .h = 50.0F}, .rule = "cỡ âm bị bỏ qua"},
        {.window = "Ratio",
            .box = Box{.x = 230.0F, .y = 90.0F, .w = 100.0F, .h = 100.0F},
            .rule = "Relative* theo cha"},
        {.window = "Negative",
            .box = Box{.x = 27.0F, .y = 39.0F, .w = 10.0F, .h = 10.0F},
            .rule = "toạ độ âm cắt về 0"},
    }};
    const auto is_placed = [&hub](const Expected& item) {
        const std::optional<Box> box = hub.box(item.window);
        return box && same_box(*box, item.box);
    };
    for (const Expected& item : wanted)
        context.expect(is_placed(item), item.rule);
}

constexpr std::array kCases{
    Case{.name = "placed_windows", .body = &placed_windows},
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

