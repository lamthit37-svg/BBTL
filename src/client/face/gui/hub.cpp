/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/gui/hub.cpp
 *  PHÂN HỆ   : Face / Gui / Hub
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hub: trung tâm dàn trang giữ bộ nhớ đệm của vòng vẽ. Chỉ dàn lại cửa sổ
 *    khi cỡ màn hình, danh sách cửa sổ gốc hay giá trị đặt lúc chạy đổi; trang
 *    tĩnh (ảnh, chữ) chỉ dựng lại khi nút dưới chuột đổi; trang động (thanh,
 *    radar) dựng lại khi thanh hay vị trí người chơi đổi. Mỗi lần dựng lại tăng
 *    một mốc (stamp) để bộ vẽ biết có phải đẩy lại bộ đệm GPU không.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Thanh trượt như FalagardSuperProgress: người gọi nêu mức muốn tới, Hub giữ mức đang chạy của từng thanh và đưa nó
// tới đích tối đa MoveSpeed mỗi giây (updateSelf 0x18007a760), cùng màu mà hàm vẽ nhân vào thanh (bar_tint.hpp);
// paint.cpp vẽ theo cả mức muốn tới lẫn mức đang chạy (populateRenderCache 0x180078870). Nguồn: TLBB Dev
// src/gui/sheet.cpp@e0d89a6 (Hub, draw_order, hit). Khác gốc: thứ tự vẽ dựng bằng ngăn xếp thay cho đệ quy; anh em
// luôn-trên-cùng xếp theo thứ tự khai như CEGUI (bản Dev xếp ngược); hit nhận loại dò để nút trái xuyên
// MouseLButtonHollow; vòng lặp viết theo luật độ lồng; chỉ số nút nóng thay cho phép trừ con trỏ; Hub tự trượt thanh
// (bản Dev để người gọi trượt); mức đang chạy của thanh mới bắt đầu ở CurrentProgress (bản 2026 bắt đầu ở 0 rồi chạy
// tới, nhưng cửa sổ của nó có từ lúc nạp giao diện nên đã chạy xong trước khi người gọi nêu mức: docs/NGHI-NGO.md mục
// 18).

#include "gui/asset.hpp"
#include "gui/detail/bar_tint.hpp"
#include "gui/detail/draw.hpp"
#include "gui/detail/softkey.hpp"
#include "gui/scroll.hpp"
#include "gui/sheet.hpp"
#include "gui/strings.hpp"
#include "gui/value.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <deque>
#include <format>
#include <iterator>
#include <memory>
#include <optional>
#include <ranges>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::gui {

using detail::Ctx;
using detail::ImageIndex;
using detail::Placed;

namespace {

// Một thanh đang được người gọi đặt mức: đích, mức đang chạy, MoveSpeed của cửa sổ, cách chọn màu và màu hiện hành.
struct Glide {
    std::string window;
    float target = 1.0F;
    float shown = 1.0F;
    float speed = 1.0F;
    detail::BarTint style;
    std::uint32_t tint = kWhiteArgb;
};

// Mặt nạ của một cửa sổ chủ: texture (chỉ số trong GuiAsset, -1 là không có) và ô màn hình mà
// texture đó phủ kín.
struct Veil {
    std::int32_t texture = -1;
    Box box;
};

// Các đích của lần update này và số giây đã trôi từ lần trước.
struct BarTick {
    std::span<const Bar> bars;
    float seconds = 0.0F;
};

} // namespace

struct Hub::Body {
    const GuiAsset* asset = nullptr;
    ImageIndex images;
    std::vector<Placed> placed;
    std::vector<std::size_t> order;
    // Số lớp của từng cửa sổ: thứ tự vẽ của gốc chứa nó.
    std::vector<std::uint16_t> layers;
    // Mặt nạ áp lên quad của từng cửa sổ (của tổ tiên gần nhất mang MaskImage).
    std::vector<Veil> veils;
    std::vector<Quad> still;
    std::vector<Quad> live;
    std::vector<TextRun> texts;
    // Chuỗi mà texts mượn và do bộ vẽ dựng (số trong ô tiền); đổi cùng texts.
    std::deque<std::string> made;
    std::optional<Box> radar;
    Radar uv;
    std::optional<Box> board;
    Box board_dest;
    Radar board_uv;
    std::optional<Box> world;
    std::vector<WorldHit> world_hits;
    std::uint64_t still_stamp = 0;
    std::uint64_t live_stamp = 0;
    std::uint64_t text_stamp = 0;
    float width = -1.0F;
    float height = -1.0F;
    // Lần dàn trang gần nhất có số đo chữ không: có hay không là hai trang khác nhau (danh sách và
    // cửa sổ phức hợp không có mục khi thiếu).
    bool has_meter = false;
    std::vector<std::string> roots;
    std::vector<std::string> hidden;
    // Các thanh của lần update gần nhất, cùng thứ tự với Place::bars, và mức vẽ ra của chúng.
    std::vector<Glide> glides;
    std::vector<detail::BarLevel> bar_levels;
    // Đồng hồ của lần update trước; chưa có thì lần đầu không trượt.
    std::optional<std::chrono::milliseconds> clock;
    // Bản chép của Place::overrides: dòng chữ mượn chuỗi ở đây, không mượn của người gọi.
    std::vector<std::array<std::string, 3>> forced;
    std::vector<Override> forced_views;
    const StringBook* strings = nullptr;
    float scene_width = 0.0F;
    float scene_depth = 0.0F;
    float player_x = 0.0F;
    float player_z = 0.0F;
    float player_facing = 0.0F;
    int hot = -2;
    bool is_down = false;
    // Ô phím dưới chuột mà trang động đang vẽ, khi cửa sổ nóng là bàn phím ảo.
    std::optional<std::size_t> hot_key;
};

namespace {

constexpr int kNoButton = -1;
// Khoảng đồng hồ đủ cho mọi thanh trượt xong (MoveSpeed nhỏ nhất của layout gốc là 1 mỗi giây).
constexpr std::chrono::hours kSettleSpan{1};

ImageIndex index_images(const GuiAsset& asset) {
    ImageIndex index;
    for (std::size_t image_index = 0; image_index < asset.images.size(); ++image_index) {
        const GuiImage& image = asset.images.at(image_index);
        const std::string key = std::format("{}/{}", image.imageset, image.name);
        index.emplace(key, static_cast<std::int32_t>(image_index));
    }
    return index;
}

// Window::getUnclippedPixelRect (Base 0x1800a2000) ở chế độ Relative, chế độ của mọi layout gốc:
// windowToScreen(Rect(0, 0, 1, 1)) đặt cạnh phải và dưới ở PixelAligned(cỡ) cộng gốc. Ô dùng để dò
// chuột, cắt và báo ra ngoài vì thế có cỡ đã làm tròn; cỡ lẻ (UnifiedSize có offset lẻ) chỉ còn
// trong phép đặt cửa sổ con và phép vẽ ảnh, như d_pixelSize của bản gốc.
Box shown_box(const Placed& window) noexcept {
    Box box = window.screen;
    box.w = detail::pixel_align(box.w);
    box.h = detail::pixel_align(box.h);
    return box;
}

bool contains(Box box, float across, float down) noexcept {
    if (box.w <= 0.0F || box.h <= 0.0F) return false;
    if (across < box.x || down < box.y) return false;
    return across < box.x + box.w && down < box.y + box.h;
}

std::optional<std::string_view> prop_of(const GuiAsset& asset, const Placed& placed, std::string_view name) {
    const auto own = detail::last_prop(asset, placed.window->properties, name);
    if (own) return own;
    if (placed.look == nullptr) return std::nullopt;
    return detail::last_prop(asset, placed.look->properties, name);
}

bool is_switched_on(const GuiAsset& asset, const Placed& placed, std::string_view name) {
    const auto text = prop_of(asset, placed, name);
    return text && parse_bool(*text);
}

bool is_hollow(const GuiAsset& asset, const Placed& placed) {
    return is_switched_on(asset, placed, "MouseHollow");
}

// Thủng với loại dò probe: MouseHollow thủng với mọi loại, MouseLButtonHollow chỉ với nút trái.
bool is_pierced(const GuiAsset& asset, const Placed& placed, Probe probe) {
    if (is_hollow(asset, placed)) return true;
    return probe == Probe::kLeftButton && is_switched_on(asset, placed, "MouseLButtonHollow");
}

bool is_locked(const GuiAsset& asset, const Placed& window, const Place& input) {
    auto text = detail::forced(input, window, "Disabled");
    if (!text) text = prop_of(asset, window, "Disabled");
    return text && parse_bool(*text);
}

// Kiểu cửa sổ đổi hình theo chuột: nút, bàn phím ảo (phím dưới chuột sáng lên) và cửa sổ thành tích
// (nút dưới chuột sáng lên).
bool is_hot_kind(detail::Kind kind) noexcept {
    return detail::is_pressable(kind) || kind == detail::Kind::kSoftKeys || kind == detail::Kind::kCatalog;
}

// Cửa sổ window có đang nằm dưới con trỏ của input và nhận nó không.
bool is_button_hot(const GuiAsset& asset, const Placed& window, const Place& input) {
    if (!input.pointer || !window.is_visible || !is_hot_kind(window.kind)) return false;
    if (is_hollow(asset, window) || is_locked(asset, window, input)) return false;
    return contains(shown_box(window), input.pointer->x, input.pointer->y);
}

// Cửa sổ đang hiện và ô của nó chứa điểm.
bool is_under(const Placed& window, float across, float down) noexcept {
    return window.is_visible && contains(shown_box(window), across, down);
}

// Cửa sổ đang hiện mang tên name; nullptr khi không có hay đang ẩn.
const Placed* shown_window(std::span<const Placed> placed, std::string_view name) noexcept {
    const auto is_named = [name](const Placed& window) { return window.is_visible && window.window->name == name; };
    const auto found = std::ranges::find_if(placed, is_named);
    return found == placed.end() ? nullptr : &*found;
}

// Nhóm của cửa sổ theo cha: 0 là cửa sổ gốc, n + 1 là con của cửa sổ n.
std::size_t group_of(const Placed& window) noexcept {
    const std::int32_t parent = window.window->parent;
    return parent < 0 ? 0U : static_cast<std::size_t>(parent) + 1U;
}

// Nhóm cửa sổ con theo cha, mỗi nhóm theo thứ tự khai.
std::vector<std::vector<std::size_t>> group_by_parent(std::span<const Placed> placed) {
    std::vector<std::vector<std::size_t>> groups(placed.size() + 1);
    for (std::size_t index = 0; index < placed.size(); ++index) {
        groups.at(group_of(placed[index])).push_back(index);
    }
    return groups;
}

// Cây cửa sổ đã đặt và các gốc được kê (Place::roots).
struct Tree {
    std::span<const Placed> placed;
    std::span<const std::string_view> roots;
};

// Thứ tự thăm các con: anh em thường rồi tới anh em luôn-trên-cùng, mỗi nhóm theo thứ tự khai nên
// khai sau nằm trên. CEGUI gắn cửa sổ vào cha rồi mới đặt thuộc tính, và setAlwaysOnTop gỡ nó ra
// rồi thêm lại vào cuối danh sách vẽ của cha (Window::addWindowToDrawList).
// Khác gốc: không có RiseOnClick, bấm vào một cửa sổ không đưa nó lên trên anh em.
std::vector<std::size_t> visit_list(std::span<const std::size_t> kids, const Tree& tree) {
    const auto is_front = [&tree](std::size_t index) { return tree.placed[index].is_on_top; };
    std::vector<std::size_t> list(kids.begin(), kids.end());
    std::ranges::stable_sort(list, {}, is_front);
    return list;
}

// Hạng của một gốc trong danh sách kê: chỉ số trong roots, gốc không kê (đang ẩn) đứng đầu.
std::size_t root_rank(const Tree& tree, std::size_t index) noexcept {
    const std::string_view name = tree.placed[index].window->name;
    const auto found = std::ranges::find(tree.roots, name);
    if (found == tree.roots.end()) return 0;
    return static_cast<std::size_t>(std::distance(tree.roots.begin(), found)) + 1U;
}

// Các gốc theo thứ tự vẽ. Có danh sách kê thì thứ tự kê quyết định (kê sau nằm trên); không thì
// như các con khác: thứ tự khai, luôn-trên-cùng vẽ sau.
std::vector<std::size_t> root_list(std::span<const std::size_t> kids, const Tree& tree) {
    std::vector<std::size_t> list = visit_list(kids, tree);
    if (tree.roots.empty()) return list;
    const auto rank = [&tree](std::size_t index) { return root_rank(tree, index); };
    std::ranges::stable_sort(list, {}, rank);
    return list;
}

// Các con của window theo thứ tự vẽ, trừ lớp phủ (danh sách thả của Combobox): lớp phủ dồn vào overlays để vẽ sau cùng.
std::vector<std::size_t> kids_of(std::span<const std::size_t> group, const Tree& tree, std::vector<std::size_t>& overlays) {
    std::vector<std::size_t> kids;
    for (const std::size_t index : visit_list(group, tree)) {
        const bool is_overlay = tree.placed[index].is_overlay;
        if (is_overlay) overlays.push_back(index);
        if (!is_overlay) kids.push_back(index);
    }
    return kids;
}

// Thứ tự vẽ: duyệt trước cây cửa sổ theo visit_list, bằng ngăn xếp (con thăm đầu nằm trên đỉnh). Lớp phủ và cây con của nó
// đứng sau mọi gốc, theo thứ tự gặp.
std::vector<std::size_t> draw_order(const Tree& tree) {
    const std::vector<std::vector<std::size_t>> groups = group_by_parent(tree.placed);
    std::vector<std::size_t> order;
    order.reserve(tree.placed.size());
    std::vector<std::size_t> overlays;
    const std::vector<std::size_t> first = root_list(groups.front(), tree);
    std::vector<std::size_t> stack(first.rbegin(), first.rend());
    const auto walk = [&] {
        while (!stack.empty()) {
            const std::size_t index = stack.back();
            stack.pop_back();
            order.push_back(index);
            const std::vector<std::size_t> kids = kids_of(groups.at(index + 1), tree, overlays);
            stack.insert(stack.end(), kids.rbegin(), kids.rend());
        }
    };
    walk();
    for (std::size_t seen = 0; seen < overlays.size(); ++seen) {
        stack.assign(1, overlays.at(seen));
        walk();
    }
    return order;
}

// Số lớp đang đánh: số của từng cửa sổ và số của gốc kế tiếp.
struct LayerCount {
    std::vector<std::uint16_t> layers;
    std::uint16_t next = 0;
};

// Số lớp của một cửa sổ khi các cửa sổ vẽ trước nó đã có số: gốc và lớp phủ mở lớp mới, con theo cha.
void assign_layer(LayerCount& count, const Placed& window, std::size_t index) {
    const std::int32_t parent = window.window->parent;
    if (parent >= 0 && !window.is_overlay) {
        count.layers.at(index) = count.layers.at(static_cast<std::size_t>(parent));
        return;
    }
    count.layers.at(index) = count.next;
    ++count.next;
}

// Số lớp của mọi cửa sổ theo thứ tự vẽ order: lớp là thứ tự vẽ của gốc chứa nó.
std::vector<std::uint16_t> layers_of(const Tree& tree, std::span<const std::size_t> order) {
    LayerCount count;
    count.layers.assign(tree.placed.size(), 0);
    for (const std::size_t index : order) {
        assign_layer(count, tree.placed[index], index);
    }
    return count.layers;
}

// Texture của imageset name: texture của ảnh đầu tiên thuộc bộ đó trong asset; -1 khi không có.
std::int32_t imageset_texture(const GuiAsset& asset, std::string_view name) noexcept {
    const auto is_member = [name](const GuiImage& image) { return image.imageset == name; };
    const auto found = std::ranges::find_if(asset.images, is_member);
    return found == asset.images.end() ? -1 : found->texture;
}

// Tên imageset mặt nạ của một cửa sổ chủ, theo đúng thứ tự setter của client 2026: MaskImage chỉ
// có hiệu lực khi RoundEnabled đã được đặt True TRƯỚC nó trong layout, và lúc vẽ cờ vẫn phải bật.
std::string_view mask_name(const GuiAsset& asset, const Placed& host) {
    bool is_round = false;
    std::string_view taken;
    for (const GuiProperty& property : detail::window_properties(asset, host)) {
        const bool is_flag = property.name == "RoundEnabled";
        const bool is_mask = property.name == "MaskImage";
        is_round = is_flag ? parse_bool(property.value) : is_round;
        taken = (is_mask && is_round) ? std::string_view(property.value) : taken;
    }
    return is_round ? taken : std::string_view{};
}

// Phần chung của hai ô; rỗng (cạnh 0) khi không giao nhau.
Box intersect(const Box& one, const Box& other) noexcept {
    const float left = std::max(one.x, other.x);
    const float top = std::max(one.y, other.y);
    const float right = std::min(one.x + one.w, other.x + other.w);
    const float bottom = std::min(one.y + one.h, other.y + other.h);
    const float width = std::max(right - left, 0.0F);
    const float height = std::max(bottom - top, 0.0F);
    return Box{.x = left, .y = top, .w = width, .h = height};
}

// Số liệu để tính mặt nạ: cây cửa sổ, asset và cỡ màn hình.
struct VeilAsk {
    const GuiAsset* asset = nullptr;
    std::span<const Placed> placed;
    Box screen;
};

// getPixelRect của cửa sổ index: ô của nó cắt theo mọi tổ tiên và màn hình.
Box pixel_rect(const VeilAsk& ask, std::size_t index) noexcept {
    Box box = intersect(shown_box(ask.placed[index]), ask.screen);
    std::int32_t parent = ask.placed[index].window->parent;
    while (parent >= 0) {
        const Placed& above = ask.placed[static_cast<std::size_t>(parent)];
        box = intersect(box, shown_box(above));
        parent = above.window->parent;
    }
    return box;
}

// Mặt nạ mà cửa sổ index tự mang cho con cháu; texture -1 khi nó không phải chủ mặt nạ.
Veil own_veil(const VeilAsk& ask, std::size_t index) {
    const Placed& host = ask.placed[index];
    if (host.kind != detail::Kind::kMaskHost) return {};
    const std::string_view name = mask_name(*ask.asset, host);
    if (name.empty()) return {};
    return Veil{.texture = imageset_texture(*ask.asset, name), .box = pixel_rect(ask, index)};
}

// Mặt nạ áp lên quad của từng cửa sổ: của cha nếu cha là chủ mặt nạ, không thì thừa hưởng của cha.
// Cha đứng trước con trong placed nên một lượt xuôi là đủ. Chủ mặt nạ không che chính nó.
Veil veil_at(const VeilAsk& ask, std::span<const Veil> done, std::size_t index) {
    const std::int32_t parent = ask.placed[index].window->parent;
    if (parent < 0) return {};
    const auto above = static_cast<std::size_t>(parent);
    const Veil own = own_veil(ask, above);
    return own.texture >= 0 ? own : done[above];
}

std::vector<Veil> veils_of(const VeilAsk& ask) {
    std::vector<Veil> veils(ask.placed.size());
    for (std::size_t index = 0; index < ask.placed.size(); ++index) {
        veils.at(index) = veil_at(ask, veils, index);
    }
    return veils;
}

bool names_same(const std::vector<std::string>& saved, std::span<const std::string_view> now) {
    return std::ranges::equal(saved, now);
}

void store_names(std::vector<std::string>& saved, std::span<const std::string_view> now) {
    saved.assign(now.begin(), now.end());
}

bool is_live_window(const Ctx& ctx, const Placed& self) noexcept {
    if (self.kind == detail::Kind::kProgress || self.kind == detail::Kind::kRadar) return true;
    return ctx.hot == &self;
}

// Bản đồ lớn (radar mang SceneMapZoom) vẽ ở cả hai trang: ảnh nền ở trang tĩnh, mũi tên ở trang động.
bool is_board_window(const Ctx& ctx, const Placed& self) {
    return self.kind == detail::Kind::kRadar && detail::effective(ctx, self, "SceneMapZoom").has_value();
}

void draw_window(const Ctx& ctx, const Placed& self) {
    if (!self.is_visible) return;
    if (!ctx.is_live_pass) detail::texts_of(ctx, self);
    if (is_board_window(ctx, self)) {
        detail::draw_images(ctx, self);
        return;
    }
    if (ctx.is_live_pass != is_live_window(ctx, self)) return;
    detail::draw_images(ctx, self);
}

} // namespace

struct HubOps {
    // Các thanh đang giữ có đúng là các thanh của lần này, cùng thứ tự không.
    static bool glides_match(const Hub::Body& body, std::span<const Bar> bars) {
        const auto same = [](const Glide& glide, const Bar& bar) { return glide.window == bar.window; };
        return std::ranges::equal(body.glides, bars, same);
    }

    // Các thuộc tính mà look khai cho cửa sổ (PropertyInitialiser); rỗng khi cửa sổ không có look.
    static std::span<const GuiProperty> look_properties(const GuiAsset& asset, const Placed& placed) {
        if (placed.look == nullptr || !detail::in_range(asset.properties.size(), placed.look->properties)) return {};
        return std::span(asset.properties).subspan(placed.look->properties.first, placed.look->properties.count);
    }

    // Số không âm của thuộc tính property trên cửa sổ (layout rồi look); không có hay hỏng thì 1.
    static float number_of(const Hub::Body& body, const Placed& placed, std::string_view property) {
        const auto text = prop_of(*body.asset, placed, property);
        const float number = text ? parse_float(*text).value_or(1.0F) : 1.0F;
        return number >= 0.0F ? number : 0.0F;
    }

    // Thanh mới: bắt đầu ở CurrentProgress của cửa sổ (mặc định 1, như d_curPos của
    // FalagardSuperProgress), trượt theo MoveSpeed của nó. Tên không có cửa sổ thì giữ mặc định.
    static Glide fresh_glide(const Hub::Body& body, std::string_view name) {
        Glide fresh;
        fresh.window = name;
        const auto is_named = [name](const Placed& placed) { return placed.window->name == name; };
        const auto found = std::ranges::find_if(body.placed, is_named);
        if (found == body.placed.end()) return fresh;
        fresh.shown = std::min(number_of(body, *found, "CurrentProgress"), 1.0F);
        fresh.speed = number_of(body, *found, "MoveSpeed");
        fresh.style = detail::read_bar_tint(look_properties(*body.asset, *found), detail::window_properties(*body.asset, *found));
        return fresh;
    }

    // Thanh name: giữ mức đang chạy nếu lần trước đã có, không thì thanh mới.
    static Glide glide_of(const Hub::Body& body, std::string_view name) {
        const auto is_named = [name](const Glide& glide) { return glide.window == name; };
        const auto found = std::ranges::find_if(body.glides, is_named);
        return found == body.glides.end() ? fresh_glide(body, name) : *found;
    }

    // Danh sách thanh đổi (hiếm): dựng lại, thanh còn tên cũ giữ mức đang chạy. Mức vẽ ra chưa
    // biết nên đặt -1 để lượt trượt kế chắc chắn báo đổi.
    static void adopt_bars(Hub::Body& body, std::span<const Bar> bars) {
        const auto kept = [&body](const Bar& bar) { return glide_of(body, bar.window); };
        std::vector<Glide> next;
        next.reserve(bars.size());
        std::ranges::transform(bars, std::back_inserter(next), kept);
        body.glides = std::move(next);
        body.bar_levels.assign(bars.size(), detail::BarLevel{.target = -1.0F, .shown = -1.0F, .tint = 0});
    }

    // Trượt thanh thứ slot về đích mới của nó; true khi mức vẽ ra của nó đổi. Như updateSelf: chỉ khi mức đang chạy
    // chưa tới đích mới chạy và tính lại màu (hàm 0x18007a250 chỉ có chỗ gọi đó), nên thanh đứng yên giữ màu cũ.
    static bool step_glide(Hub::Body& body, const BarTick& tick, std::size_t slot) {
        Glide& glide = body.glides.at(slot);
        glide.target = std::clamp(tick.bars[slot].amount, 0.0F, 1.0F);
        if (glide.shown != glide.target) {
            BarMove move;
            move.shown = glide.shown;
            move.target = glide.target;
            move.speed = glide.speed;
            move.seconds = tick.seconds;
            glide.shown = bar_step(move);
            glide.tint = glide.style.at(glide.shown);
        }
        const detail::BarLevel level{.target = glide.target, .shown = glide.shown, .tint = glide.tint};
        const bool is_changed = level != body.bar_levels.at(slot);
        body.bar_levels.at(slot) = level;
        return is_changed;
    }

    // Trượt mọi thanh một bước; true khi có mức vẽ ra đổi. Đường thường (danh sách thanh không
    // đổi) không cấp phát.
    static bool glide_bars(Hub::Body& body, const BarTick& tick) {
        if (!glides_match(body, tick.bars)) adopt_bars(body, tick.bars);
        bool is_changed = false;
        for (std::size_t slot = 0; slot < tick.bars.size(); ++slot) {
            is_changed = step_glide(body, tick, slot) || is_changed;
        }
        return is_changed;
    }

    static bool forced_same(const Hub::Body& body, const Place& input) {
        if (body.strings != input.strings) return false;
        if (body.forced.size() != input.overrides.size()) return false;
        const auto same = [&](std::size_t index) {
            const Override& now = input.overrides[index];
            const std::array<std::string, 3>& kept = body.forced[index];
            return kept[0] == now.window && kept[1] == now.name && kept[2] == now.value;
        };
        return std::ranges::all_of(std::views::iota(std::size_t{0}, input.overrides.size()), same);
    }

    static void store_forced(Hub::Body& body, const Place& input) {
        body.strings = input.strings;
        body.forced.clear();
        body.forced.reserve(input.overrides.size());
        for (const Override& item : input.overrides) {
            const std::string window(item.window);
            const std::string name(item.name);
            const std::string value(item.value);
            body.forced.push_back({window, name, value});
        }
        body.forced_views.clear();
        body.forced_views.reserve(body.forced.size());
        for (const std::array<std::string, 3>& kept : body.forced) {
            const Override item{.window = kept[0], .name = kept[1], .value = kept[2]};
            body.forced_views.push_back(item);
        }
    }

    // Vector đổi chủ nhưng từng chuỗi nằm yên trong bộ đệm của nó, nên dòng chữ vẫn đúng.
    static std::vector<std::array<std::string, 3>> take_forced(Hub& hub) { return std::move(hub.body_->forced); }

    // Deque đổi chủ nhưng từng phần tử nằm yên, nên chữ mượn của texts vẫn đúng.
    static std::deque<std::string> take_made(Hub& hub) { return std::move(hub.body_->made); }

    static bool layout_same(const Hub::Body& body, const Place& input) {
        if (body.width != input.width || body.height != input.height) return false;
        if (body.has_meter != (input.meter != nullptr)) return false;
        if (!names_same(body.roots, input.roots)) return false;
        return names_same(body.hidden, input.hidden);
    }

    static bool world_same(const Hub::Body& body, const Place& input) {
        const bool is_scene = body.scene_width == input.scene_width && body.scene_depth == input.scene_depth;
        const bool is_place = body.player_x == input.player_x && body.player_z == input.player_z;
        return is_scene && is_place && body.player_facing == input.player_facing;
    }

    static void relayout(Hub::Body& body, const Place& input) {
        body.placed = detail::layout(*body.asset, input);
        const Tree tree{.placed = body.placed, .roots = input.roots};
        body.order = draw_order(tree);
        body.layers = layers_of(tree, body.order);
        const Box screen{.x = 0.0F, .y = 0.0F, .w = input.width, .h = input.height};
        const VeilAsk ask{.asset = body.asset, .placed = body.placed, .screen = screen};
        body.veils = veils_of(ask);
        body.width = input.width;
        body.height = input.height;
        body.has_meter = input.meter != nullptr;
        store_names(body.roots, input.roots);
        store_names(body.hidden, input.hidden);
    }

    // Một lượt vẽ: trang tĩnh (live false) hay trang động.
    static Sheet paint(const Hub::Body& body, const Place& input, bool is_live, const Placed* hot) {
        Sheet sheet;
        Ctx ctx;
        ctx.asset = body.asset;
        ctx.input = &input;
        ctx.placed = body.placed;
        ctx.sheet = &sheet;
        ctx.images = &body.images;
        ctx.hot = hot;
        ctx.bar_levels = body.bar_levels;
        ctx.is_live_pass = is_live;
        ctx.is_down = input.pointer && input.pointer->is_down;
        for (const std::size_t index : body.order) {
            draw_tagged(ctx, body, index);
        }
        return sheet;
    }

    // Vẽ một cửa sổ rồi ghi số lớp và mặt nạ của nó lên những quad vừa thêm, số lớp lên dòng chữ
    // (chữ không qua mặt nạ, như OgreFontGeometryBuffer của bản gốc).
    static void draw_tagged(const Ctx& ctx, const Hub::Body& body, std::size_t index) {
        const std::size_t quads_before = ctx.sheet->quads.size();
        const std::size_t texts_before = ctx.sheet->texts.size();
        draw_window(ctx, body.placed.at(index));
        const std::uint16_t layer = body.layers.at(index);
        const Veil& veil = body.veils.at(index);
        for (Quad& quad : std::span(ctx.sheet->quads).subspan(quads_before)) {
            quad.layer = layer;
            quad.mask = veil.texture;
            quad.mask_box = veil.box;
        }
        for (TextRun& run : std::span(ctx.sheet->texts).subspan(texts_before)) {
            run.layer = layer;
        }
    }

    // Nút dưới chuột (nullptr khi không có), chỉ số của nó, chuột có đang nhấn không, và ô phím
    // dưới chuột khi nút ấy là bàn phím ảo.
    struct HotState {
        const Placed* button = nullptr;
        int index = kNoButton;
        bool is_down = false;
        std::optional<std::size_t> key;
    };

    // Chỉ số cửa sổ nút ở trên cùng dưới chuột.
    static std::optional<std::size_t> hot_button(const Hub::Body& body, const Place& input) {
        if (!input.pointer) return std::nullopt;
        const auto is_hot = [&](std::size_t index) { return is_button_hot(*body.asset, body.placed[index], input); };
        const auto backwards = body.order | std::views::reverse;
        const auto found = std::ranges::find_if(backwards, is_hot);
        if (found == backwards.end()) return std::nullopt;
        return *found;
    }

    // Ô phím dưới chuột khi cửa sổ nóng button là bàn phím ảo, nút phần tử dưới chuột khi nó là cửa
    // sổ thành tích.
    static std::optional<std::size_t> hot_key(const Hub::Body& body, const Place& input, const Placed* button) {
        if (!input.pointer || button == nullptr) return std::nullopt;
        if (button->kind == detail::Kind::kCatalog) {
            return detail::catalog_item_under(query(body, input), *button, *input.pointer);
        }
        if (button->kind != detail::Kind::kSoftKeys) return std::nullopt;
        return detail::soft_key_under(*body.asset, *button, *input.pointer);
    }

    static HotState hot_state(const Hub::Body& body, const Place& input) {
        const std::optional<std::size_t> found = hot_button(body, input);
        HotState hot;
        hot.button = found ? &body.placed.at(*found) : nullptr;
        hot.index = found ? static_cast<int>(*found) : kNoButton;
        hot.is_down = input.pointer && input.pointer->is_down;
        hot.key = hot_key(body, input, hot.button);
        return hot;
    }

    static void refresh_still(Hub::Body& body, const Place& input, const HotState& hot) {
        Sheet sheet = paint(body, input, false, hot.button);
        body.still = std::move(sheet.quads);
        body.texts = std::move(sheet.texts);
        body.made = std::move(sheet.made);
        body.world = sheet.world;
        body.world_hits = std::move(sheet.world_hits);
        body.hot = hot.index;
        body.is_down = hot.is_down;
        ++body.still_stamp;
        ++body.text_stamp;
    }

    // Những gì đã đổi từ lần update trước, để refresh biết dựng lại trang nào.
    struct Dirt {
        bool is_relaid = false;
        bool is_bars_moved = false;
    };

    // Dựng lại trang tĩnh khi bố cục hay nút dưới chuột đổi, trang động khi thanh, vị trí hay
    // hướng mặt của người chơi đổi, hay chuột sang phím khác của bàn phím ảo (nền phím của cửa sổ
    // nóng nằm ở trang động, nên trang tĩnh không phải dựng lại).
    static void refresh(Hub::Body& body, const Place& input, const HotState& hot, Dirt dirt) {
        const bool is_changed = hot.index != body.hot || hot.is_down != body.is_down;
        const bool is_still_dirty = dirt.is_relaid || is_changed;
        const bool is_moved = dirt.is_bars_moved || !world_same(body, input) || hot.key != body.hot_key;
        if (is_still_dirty) refresh_still(body, input, hot);
        if (is_still_dirty || is_moved) refresh_live(body, input, hot);
    }

    static void refresh_live(Hub::Body& body, const Place& input, const HotState& hot) {
        Sheet sheet = paint(body, input, true, hot.button);
        body.live = std::move(sheet.quads);
        body.hot_key = hot.key;
        body.radar = sheet.radar;
        body.uv = sheet.uv;
        body.board = sheet.board;
        body.board_dest = sheet.board_dest;
        body.board_uv = sheet.board_uv;
        body.scene_width = input.scene_width;
        body.scene_depth = input.scene_depth;
        body.player_x = input.player_x;
        body.player_z = input.player_z;
        body.player_facing = input.player_facing;
        ++body.live_stamp;
    }

    // Đầu vào đủ cho các câu hỏi sau update (ô vùng, mục dưới chuột): cỡ màn hình, bản chép Override
    // và bảng chuỗi. Không mang số đo chữ, vì nó chỉ sống trong lời gọi update.
    static Place kept_input(const Hub::Body& body) {
        Place input;
        input.width = body.width;
        input.height = body.height;
        input.overrides = body.forced_views;
        input.strings = body.strings;
        return input;
    }

    // Ngữ cảnh của một câu hỏi trên trang đã dàn; input phải sống tới hết câu hỏi.
    static Ctx query(const Hub::Body& body, const Place& input) {
        Ctx ctx;
        ctx.asset = body.asset;
        ctx.input = &input;
        ctx.placed = body.placed;
        ctx.images = &body.images;
        return ctx;
    }

    // Số giây từ lần update trước theo đồng hồ của người gọi; lần đầu hay đồng hồ lùi thì 0.
    static float seconds_since(Hub::Body& body, std::chrono::milliseconds clock) {
        const std::chrono::milliseconds before = body.clock.value_or(clock);
        body.clock = clock;
        const std::chrono::duration<float> passed = clock - before;
        return std::max(passed.count(), 0.0F);
    }
};

Hub::Hub(const GuiAsset& asset) : body_(std::make_unique<Body>()) {
    body_->asset = &asset;
    body_->images = index_images(asset);
}

Hub::~Hub() = default;
Hub::Hub(Hub&&) noexcept = default;
Hub& Hub::operator=(Hub&&) noexcept = default;

void Hub::update(const Place& given) {
    Body& body = *body_;
    const bool is_forced_dirty = !HubOps::forced_same(body, given);
    if (is_forced_dirty) HubOps::store_forced(body, given);
    // Từ đây chỉ dùng bản chép: dòng chữ dựng ra không còn mượn chuỗi của người gọi.
    Place input = given;
    input.overrides = body.forced_views;
    const bool is_layout_dirty = is_forced_dirty || !HubOps::layout_same(body, input);
    if (is_layout_dirty) HubOps::relayout(body, input);
    const BarTick tick{.bars = input.bars, .seconds = HubOps::seconds_since(body, input.clock)};
    HubOps::Dirt dirt;
    dirt.is_relaid = is_layout_dirty;
    dirt.is_bars_moved = HubOps::glide_bars(body, tick);
    HubOps::refresh(body, input, HubOps::hot_state(body, input), dirt);
}

std::span<const Quad> Hub::still() const noexcept {
    return body_->still;
}

std::span<const Quad> Hub::live() const noexcept {
    return body_->live;
}

std::span<const TextRun> Hub::texts() const noexcept {
    return body_->texts;
}

std::optional<Box> Hub::radar() const noexcept {
    return body_->radar;
}

std::optional<Box> Hub::board() const noexcept {
    return body_->board;
}

Box Hub::board_dest() const noexcept {
    return body_->board_dest;
}

Radar Hub::board_uv() const noexcept {
    return body_->board_uv;
}

std::optional<Box> Hub::world() const noexcept {
    return body_->world;
}

std::span<const WorldHit> Hub::world_hits() const noexcept {
    return body_->world_hits;
}

Radar Hub::uv() const noexcept {
    return body_->uv;
}

std::uint64_t Hub::still_stamp() const noexcept {
    return body_->still_stamp;
}

std::uint64_t Hub::live_stamp() const noexcept {
    return body_->live_stamp;
}

std::uint64_t Hub::text_stamp() const noexcept {
    return body_->text_stamp;
}

std::optional<std::string_view> Hub::hit(float across, float down, Probe probe) const {
    const Body& body = *body_;
    const auto is_hit = [&](std::size_t index) {
        const Placed& window = body.placed.at(index);
        return is_under(window, across, down) && !is_pierced(*body.asset, window, probe);
    };
    const auto backwards = body.order | std::views::reverse;
    const auto found = std::ranges::find_if(backwards, is_hit);
    if (found == backwards.end()) return std::nullopt;
    return std::string_view(body.placed.at(*found).window->name);
}

std::optional<Box> Hub::box(std::string_view name) const {
    const Placed* found = shown_window(body_->placed, name);
    if (found == nullptr) return std::nullopt;
    return shown_box(*found);
}

std::optional<ScrollSpan> Hub::text_span(std::string_view name) const {
    const Placed* found = shown_window(body_->placed, name);
    if (found == nullptr) return std::nullopt;
    const bool scrolls = found->kind == detail::Kind::kComplex || found->kind == detail::Kind::kList;
    if (!scrolls) return std::nullopt;
    return found->span;
}

std::optional<std::size_t> Hub::list_item(std::string_view window, Pointer pointer) const {
    const Placed* found = shown_window(body_->placed, window);
    if (found == nullptr) return std::nullopt;
    const Place input = HubOps::kept_input(*body_);
    return detail::list_item_under(HubOps::query(*body_, input), *found, pointer);
}

std::optional<std::uint32_t> Hub::option_at(std::string_view window, Pointer pointer) const {
    const Placed* found = shown_window(body_->placed, window);
    if (found == nullptr) return std::nullopt;
    const Place input = HubOps::kept_input(*body_);
    return detail::complex_option_under(HubOps::query(*body_, input), *found, pointer);
}

std::optional<std::size_t> Hub::element_at(std::string_view window, Pointer pointer) const {
    const Placed* found = shown_window(body_->placed, window);
    if (found == nullptr || found->kind != detail::Kind::kCatalog) return std::nullopt;
    const Place input = HubOps::kept_input(*body_);
    return detail::catalog_item_under(HubOps::query(*body_, input), *found, pointer);
}

std::optional<Box> Hub::content(std::string_view name) const {
    const auto is_named = [name](const Placed& window) { return window.window->name == name; };
    const auto found = std::ranges::find_if(body_->placed, is_named);
    if (found == body_->placed.end()) return std::nullopt;
    const Place input = HubOps::kept_input(*body_);
    return detail::content_area(HubOps::query(*body_, input), *found);
}

std::optional<ThumbTrack> Hub::track(std::string_view name) const {
    const Placed* found = shown_window(body_->placed, name);
    if (found == nullptr || found->kind != detail::Kind::kScrollbar) return std::nullopt;
    const Place input = HubOps::kept_input(*body_);
    return detail::thumb_track(HubOps::query(*body_, input), *found);
}

std::optional<std::size_t> Hub::soft_key(std::string_view window, Pointer pointer) const {
    const Placed* found = shown_window(body_->placed, window);
    if (found == nullptr || found->kind != detail::Kind::kSoftKeys) return std::nullopt;
    return detail::soft_key_under(*body_->asset, *found, pointer);
}

Sheet place(const GuiAsset& asset, const Place& input) {
    Hub hub(asset);
    hub.update(input);
    // Lần hai với đồng hồ đi xa: mọi thanh đã trượt xong, trang ra là trang đã yên.
    Place settled = input;
    settled.clock = input.clock + kSettleSpan;
    hub.update(settled);
    Sheet sheet;
    const std::span<const Quad> still = hub.still();
    const std::span<const Quad> live = hub.live();
    sheet.quads.reserve(still.size() + live.size());
    sheet.quads.insert(sheet.quads.end(), still.begin(), still.end());
    sheet.quads.insert(sheet.quads.end(), live.begin(), live.end());
    const std::span<const TextRun> texts = hub.texts();
    sheet.texts.assign(texts.begin(), texts.end());
    sheet.radar = hub.radar();
    sheet.uv = hub.uv();
    sheet.board = hub.board();
    sheet.board_dest = hub.board_dest();
    sheet.board_uv = hub.board_uv();
    sheet.kept = HubOps::take_forced(hub);
    sheet.made = HubOps::take_made(hub);
    return sheet;
}

} // namespace game::gui
