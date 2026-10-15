// Ra các dòng chữ của dàn trang Falagard: TextComponent của look, Falagard/SimpleText (chữ của cả
// cửa sổ) và ô nhập. Vẽ chữ thật (phông, thẻ màu #c, xuống dòng) là việc của bộ vẽ chữ ở module ui.
// Nguồn: TLBB Dev src/gui/sheet.cpp@e0d89a6 (phần chữ). Khác gốc: vòng lặp viết theo luật độ lồng;
// chỉ nhận #{ID} khi cả chuỗi là một thẻ (như bản Dev); thẻ lẫn trong chuỗi để bộ vẽ chữ xử lý.
#include "gui/asset.hpp"
#include "gui/detail/draw.hpp"
#include "gui/detail/names.hpp"
#include "gui/detail/softkey.hpp"
#include "gui/sheet.hpp"
#include "gui/value.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string_view>

namespace game::gui::detail {
namespace {

constexpr std::uint8_t kCentredVert = 1;
constexpr float kChannelMax = 255.0F;

// Tên của FalagardSimpleText, cùng thứ tự với GuiTextHorz và GuiTextVert.
constexpr std::array<std::string_view, 8> kSimpleHorz = {"LeftAligned", "RightAligned", "HorzCentred", "HorzJustified",
    "WordWrapLeftAligned", "WordWrapRightAligned", "WordWrapCentred", "WordWrapJustified"};
constexpr std::array<std::string_view, 3> kSimpleVert = {"TopAligned", "VertCentred", "BottomAligned"};

// Chữ viết thẳng trong layout: lấy bản dịch khi bảng chuỗi có, không thì nguyên văn.
std::string_view translated(const Ctx& ctx, std::string_view text) noexcept {
    if (ctx.input->strings == nullptr) return text;
    return ctx.input->strings->find_literal(text).value_or(text);
}

// Chữ viết đúng một #{ID} tra bảng chuỗi; không có bảng hay không có ID thì rỗng. Chữ có nhiều thẻ hay
// chữ nối sau thẻ ("#{BDYB_090714_01}0" của hòm đồ: script nối số sau thẻ) giữ nguyên: bộ viết chữ dịch
// từng #{ID} khi vẽ, như SetText của client gốc dịch thẻ ở bất cứ chỗ nào trong chuỗi.
std::string_view resolved(const Ctx& ctx, std::string_view text) noexcept {
    if (!text.starts_with("#{")) return translated(ctx, text);
    const bool is_whole = text.find('}') == text.size() - 1;
    if (!is_whole) return text;
    if (ctx.input->strings == nullptr) return {};
    const std::string_view id = text.substr(2, text.size() - 3);
    return ctx.input->strings->find(id).value_or(std::string_view{});
}

std::string_view text_body(const Ctx& ctx, const Placed& self, const GuiText& text) {
    if (!text.text.empty()) return resolved(ctx, text.text);
    const auto prop = effective(ctx, self, "Text");
    if (!prop) return {};
    return resolved(ctx, *prop);
}

// Phông của cửa sổ: thuộc tính Font; rỗng là phông mặc định.
std::string_view window_font(const Ctx& ctx, const Placed& self) {
    return effective(ctx, self, "Font").value_or(std::string_view{});
}

// Một TextComponent của section vẽ qua spec: màu chữ là màu của thành phần nhân Colours của spec.
// Chữ canh trong ô của thành phần nhưng cắt theo ô cửa sổ, như RenderCache của CEGUI cắt mọi thứ
// một cửa sổ vẽ theo ô của chính nó.
void emit_text(const Ctx& ctx, const Placed& self, const GuiSpec& spec, const GuiText& text) {
    const std::string_view body = text_body(ctx, self, text);
    if (body.empty()) return;
    const Box area = shift(area_box(ctx, self, text.area, self.screen), self.screen);
    if (area.w <= 0.0F || area.h <= 0.0F) return;
    TextRun run;
    run.text = body;
    run.box = area;
    run.clip = self.screen;
    run.rule = TextRule::kComponent;
    run.colour = tinted(spec, text.colour);
    run.horz = format_value(ctx, self, text.horz).index_in(kTextHorz);
    run.vert = format_value(ctx, self, text.vert).index_in(kTextVert);
    run.font = text.font.empty() ? window_font(ctx, self) : std::string_view(text.font);
    ctx.sheet->texts.push_back(run);
}

void texts_section(const Ctx& ctx, const Placed& self, const GuiSpec& spec) {
    if (spec.section < 0) return;
    if (static_cast<std::size_t>(spec.section) >= ctx.asset->sections.size()) return;
    const GuiSection& section = ctx.asset->sections.at(static_cast<std::size_t>(spec.section));
    if (!in_range(ctx.asset->texts.size(), section.texts)) return;
    const auto items = std::span(ctx.asset->texts).subspan(section.texts.first, section.texts.count);
    for (const GuiText& text : items) {
        emit_text(ctx, self, spec, text);
    }
}

void texts_layer(const Ctx& ctx, const Placed& self, const GuiLayer& layer) {
    if (!in_range(ctx.asset->specs.size(), layer.specs)) return;
    const auto items = std::span(ctx.asset->specs).subspan(layer.specs.first, layer.specs.count);
    for (const GuiSpec& spec : items) {
        texts_section(ctx, self, spec);
    }
}

void texts_state(const Ctx& ctx, const Placed& self, const GuiState& state) {
    if (!in_range(ctx.asset->layers.size(), state.layers)) return;
    const auto items = std::span(ctx.asset->layers).subspan(state.layers.first, state.layers.count);
    for (const GuiLayer& layer : items) {
        texts_layer(ctx, self, layer);
    }
}

// State mang chữ của look. Nút: đúng state nó đang vẽ, nên nhãn đổi màu theo trạng thái (thẻ khoá
// xám, thẻ đang chọn vàng). Cửa sổ khác: Enabled, không có thì Normal.
const GuiState* text_state(const Ctx& ctx, const Placed& self) {
    if (self.look == nullptr) return nullptr;
    if (is_pressable(self.kind)) return button_look_state(ctx, self);
    const GuiState* enabled = state_named(*ctx.asset, *self.look, "Enabled");
    if (enabled != nullptr) return enabled;
    return state_named(*ctx.asset, *self.look, "Normal");
}

// FalagardSimpleText::populateRenderCache (Fal 0x18004e300): chữ của cửa sổ trong ô TextArea của
// look (getTextRenderArea, Fal 0x18004e130; look không khai thì cả cửa sổ) và cắt theo đúng ô đó,
// màu TextColor (mặc định trắng), canh trái và giữa theo chiều dọc khi layout không nói.
void simple_text(const Ctx& ctx, const Placed& self) {
    const auto prop = effective(ctx, self, "Text");
    const std::string_view body = prop ? resolved(ctx, *prop) : std::string_view{};
    if (body.empty()) return;
    const auto tint = effective(ctx, self, "TextColor");
    TextRun run;
    run.text = body;
    run.box = named_area(ctx, self, "TextArea").value_or(self.screen);
    run.rule = TextRule::kSimpleText;
    run.colour = tint ? parse_colour(*tint).value_or(kWhiteArgb) : kWhiteArgb;
    const FormatValue horz{.name = effective(ctx, self, "HorzFormatting"), .fixed = 0};
    run.horz = horz.index_in(kSimpleHorz);
    const FormatValue vert{.name = effective(ctx, self, "VertFormatting"), .fixed = kCentredVert};
    run.vert = vert.index_in(kSimpleVert);
    run.font = window_font(ctx, self);
    ctx.sheet->texts.push_back(run);
}

// FalagardSuperProgress::populateRenderCache (CEGUIFalagard.dll 0x180078870) vẽ chữ của cửa sổ bằng Font::drawText khi
// cửa sổ có phông và chữ: màu trắng nhân Alpha của chính cửa sổ (cửa sổ + 0xec, không phải TextColor), canh giữa theo
// chiều ngang, canh giữa theo chiều dọc bằng (cao ô - cao khối) / 2 + 0,5 cắt về số nguyên (đúng quy tắc kSimpleText), ô
// là TextArea của look (không khai thì cả cửa sổ) và cắt theo chính ô đó.
void progress_text(const Ctx& ctx, const Placed& self) {
    const auto prop = effective(ctx, self, "Text");
    const std::string_view body = prop ? resolved(ctx, *prop) : std::string_view{};
    if (body.empty()) return;
    const auto alpha = static_cast<std::uint32_t>(own_alpha(ctx, self) * kChannelMax);
    TextRun run;
    run.text = body;
    run.box = named_area(ctx, self, "TextArea").value_or(self.screen);
    run.rule = TextRule::kSimpleText;
    run.colour = (alpha << 24U) | (kWhiteArgb & 0x00FFFFFFU);
    run.horz = static_cast<std::uint8_t>(GuiTextHorz::kCentreAligned);
    run.vert = kCentredVert;
    run.font = window_font(ctx, self);
    ctx.sheet->texts.push_back(run);
}

// Cửa sổ con tên của look nút phần tử (__auto_AchievementCatalogName__, __auto_AchievementTextName__):
// nơi SetAchievementCatalogName và SetAchievementTextName đặt chữ.
const GuiChild* name_child(const GuiAsset& asset, const Placed& button) {
    if (button.look == nullptr || !in_range(asset.children.size(), button.look->children)) return nullptr;
    const auto children = std::span(asset.children).subspan(button.look->children.first, button.look->children.count);
    const auto is_name = [](const GuiChild& child) { return child.suffix.ends_with("Name__"); };
    const auto found = std::ranges::find_if(children, is_name);
    return found == children.end() ? nullptr : &*found;
}

// Chữ của các nút trong cửa sổ thành tích: một dòng của cửa sổ con tên trong ô của nó, canh theo
// HorzFormatting của <Child> (trái khi vắng) và giữa theo chiều dọc như FalagardSimpleText, cắt theo
// ô cửa sổ.
void catalog_texts(const Ctx& ctx, const Placed& self) {
    for (const CatalogItem& item : catalog_items(ctx, self)) {
        const Placed button = catalog_button(ctx, self, item);
        const GuiChild* name = name_child(*ctx.asset, button);
        if (name == nullptr || item.text.empty()) continue;
        const Box area = shift(area_box(ctx, button, name->area, button.screen), button.screen);
        const FormatValue horz{.name = last_prop(*ctx.asset, name->properties, "HorzFormatting"), .fixed = 0};
        const FormatValue vert{
            .name = last_prop(*ctx.asset, name->properties, "VertFormatting"), .fixed = kCentredVert};
        TextRun run;
        run.text = item.text;
        run.box = area;
        run.clip = self.screen;
        run.rule = TextRule::kSimpleText;
        run.horz = horz.index_in(kSimpleHorz);
        run.vert = vert.index_in(kSimpleVert);
        ctx.sheet->texts.push_back(run);
    }
}

const GuiNamedArea* area_named(const GuiAsset& asset, const GuiLook& look, std::string_view name) {
    if (!in_range(asset.areas.size(), look.areas)) return nullptr;
    const auto items = std::span(asset.areas).subspan(look.areas.first, look.areas.count);
    const auto matches = [name](const GuiNamedArea& area) { return area.name == name; };
    const auto found = std::ranges::find_if(items, matches);
    return found == items.end() ? nullptr : &*found;
}

// Ô chữ của ô nhập: bề ngang là TextArea của look cắt theo mép phải cửa sổ, chiều dọc là cả cửa
// sổ. TextArea của look gốc dài quá mép dưới cửa sổ (TLBB_Look_EditBoxNormal: trên 3, cao bằng
// cửa sổ trừ 1), nên không dùng được chiều dọc của nó. Không có TextArea thì cả cửa sổ.
Box edit_box(const Ctx& ctx, const Placed& self) {
    if (self.look == nullptr) return self.screen;
    const GuiNamedArea* area = area_named(*ctx.asset, *self.look, "TextArea");
    if (area == nullptr) return self.screen;
    const Box across = shift(area_box(ctx, self, area->area, self.screen), self.screen);
    const float right = std::min(across.x + across.w, self.screen.x + self.screen.w);
    return {.x = across.x, .y = self.screen.y, .w = right - across.x, .h = self.screen.h};
}

// FalagardIMEEditBox::populateRenderCache (CEGUIFalagardEx/FalIMEEditBox.cpp của mã 2008): dòng
// chữ canh trái trong bề ngang của TextArea; mép trên của nó là (cao cửa sổ - cao dòng) / 2 làm
// tròn về điểm ảnh, cao đúng một dòng, và con nháy vẽ trong đúng ô đó. Ở đây ô chữ trải cả chiều
// cao cửa sổ và canh giữa: bộ vẽ chữ tính ra cùng mép trên. Che mật khẩu là việc của người gọi
// (đưa sẵn chuỗi dấu sao). Chữ là thứ người chơi gõ nên là nguyên văn: "#c" trong ô tài khoản không
// thành thẻ màu. Ô chỉ đọc (ReadOnly của look, như ô nhập của Combobox) không có người gõ: chữ của nó
// do chương trình đặt nên "#{khoá}" được dịch như chữ của cửa sổ thường. Khác gốc: chưa cuộn ngang khi
// chữ dài hơn ô, chưa có vùng chọn.
void edit_text(const Ctx& ctx, const Placed& self) {
    const auto prop = effective(ctx, self, "Text");
    TextRun run;
    run.text = prop.value_or(std::string_view{});
    run.has_caret = flag(ctx, self, "Caret");
    run.is_plain = !flag(ctx, self, "ReadOnly");
    run.rule = TextRule::kEdit;
    if (run.text.empty() && !run.has_caret) return;
    run.box = edit_box(ctx, self);
    run.vert = kCentredVert;
    run.font = window_font(ctx, self);
    ctx.sheet->texts.push_back(run);
}

// Chữ của look: các TextComponent trong state mà text_state chọn.
void look_texts(const Ctx& ctx, const Placed& self) {
    const GuiState* state = text_state(ctx, self);
    if (state == nullptr) return;
    texts_state(ctx, self, *state);
}

} // namespace

void texts_of(const Ctx& ctx, const Placed& self) {
    if (self.kind == Kind::kText) {
        simple_text(ctx, self);
    } else if (self.kind == Kind::kList) {
        list_texts(ctx, self);
    } else if (self.kind == Kind::kComplex) {
        complex_texts(ctx, self);
    } else if (self.kind == Kind::kCatalog) {
        catalog_texts(ctx, self);
    } else if (self.kind == Kind::kMoney) {
        money_texts(ctx, self);
    } else if (self.kind == Kind::kWorld) {
        world_texts(ctx, self);
    } else if (self.kind == Kind::kEdit) {
        edit_text(ctx, self);
    } else if (self.kind == Kind::kProgress) {
        progress_text(ctx, self);
    } else if (self.kind == Kind::kSoftKeys) {
        soft_key_texts(ctx, self);
    } else {
        look_texts(ctx, self);
    }
}

} // namespace game::gui::detail
