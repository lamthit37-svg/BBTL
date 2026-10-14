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
    Case{.name = "slot_back", .body = &slot_back},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "gui_sheet_tests: mọi ca phải qua");
    return 0;
}

