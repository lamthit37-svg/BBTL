/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/resource/ogre_program.cpp
 *  PHÂN HỆ   : Resource / Ogre Program
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bộ đọc Material/programs.tsv (xem ogre_program.hpp). Hàng tiêu đề phải
 *    đúng 23 cột theo thứ tự của công cụ; scene_blend diễn giải như
 *    paint_blend của ogre_mesh.cpp để hai bộ đọc không lệch nhau.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "resource/ogre_program.hpp"

#include "core/error.hpp"
#include "resource/model.hpp"

#include <algorithm>
#include <array>
#include <charconv>
#include <cstddef>
#include <expected>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace game::resource {
namespace {

constexpr std::array<std::string_view, 23> kColumns{"material", "program", "flow",
    "flow_light_type", "flow_tex_type", "outline", "outline_ctrl", "dissolve", "blend",
    "depth_write", "alpha_ref", "cull", "depth_pass", "depth_ref", "emissive", "diffuse",
    "flow_factor", "outline_pow", "outline_color", "base", "ctl", "reflection",
    "outline_ctrl_texture"};

// Chỉ số cột theo kColumns.
constexpr std::size_t kMaterial = 0;
constexpr std::size_t kFlow = 2;
constexpr std::size_t kFlowLightType = 3;
constexpr std::size_t kFlowTexType = 4;
constexpr std::size_t kOutline = 5;
constexpr std::size_t kOutlineCtrl = 6;
constexpr std::size_t kBlend = 8;
constexpr std::size_t kAlphaRef = 10;
constexpr std::size_t kCull = 11;
constexpr std::size_t kDepthPass = 12;
constexpr std::size_t kDepthRef = 13;
constexpr std::size_t kFlowFactor = 16;
constexpr std::size_t kOutlinePow = 17;
constexpr std::size_t kOutlineColor = 18;
constexpr std::size_t kCtl = 20;
constexpr std::size_t kReflection = 21;
constexpr std::size_t kOutlineTexture = 22;

using Cells = std::vector<std::string_view>;

[[nodiscard]] Cells split(std::string_view line, char mark) {
    Cells cells;
    std::size_t start = 0;
    while (start <= line.size()) {
        const std::size_t stop = line.find(mark, start);
        const std::size_t end = stop == std::string_view::npos ? line.size() : stop;
        cells.push_back(line.substr(start, end - start));
        start = end + 1;
    }
    return cells;
}

[[nodiscard]] std::string_view trimmed(std::string_view text) noexcept {
    while (!text.empty() && (text.back() == '\r' || text.back() == ' '))
        text.remove_suffix(1);
    while (!text.empty() && text.front() == ' ')
        text.remove_prefix(1);
    return text;
}

[[nodiscard]] std::optional<float> number_of(std::string_view text) noexcept {
    float value = 0.0F;
    const char* first = text.data();
    const char* last = std::to_address(text.end());
    const std::from_chars_result read = std::from_chars(first, last, value);
    const bool is_whole = read.ec == std::errc{} && read.ptr == last;
    if (!is_whole) return std::nullopt;
    return value;
}

// Đúng out.size() số cách nhau bằng dấu cách; cột rỗng thì giữ out. false khi số hỏng hay thiếu.
[[nodiscard]] bool read_floats(std::string_view cell, std::span<float> out) {
    if (cell.empty()) return true;
    const Cells parts = split(cell, ' ');
    if (parts.size() < out.size()) return false;
    for (std::size_t index = 0; index < out.size(); ++index) {
        const std::optional<float> value = number_of(parts[index]);
        if (!value) return false;
        out[index] = *value;
    }
    return true;
}

// Cùng luật với paint_blend: add và "one one" cộng sáng, replace và "one zero" đục, còn lại trộn.
[[nodiscard]] Alpha blend_of(std::string_view blend) noexcept {
    const bool is_replace = blend == "replace" || blend == "one zero";
    const bool is_plain = blend.empty() || is_replace;
    if (is_plain) return Alpha::kOpaque;
    if (blend == "add" || blend == "one one") return Alpha::kAdd;
    if (blend == "zero one_minus_src_colour") return Alpha::kDarken;
    return Alpha::kBlend;
}

[[nodiscard]] std::optional<bool> sides_of(std::string_view cull) noexcept {
    if (cull.empty()) return std::nullopt;
    return cull == "none";
}

[[nodiscard]] core::Failure bad_line(std::size_t line, std::string_view what) {
    return core::fail(core::ErrorCode::kCorrupt, "programs.tsv sai", "dòng {}: {}", line, what);
}

[[nodiscard]] bool read_params(Flow& flow, const Cells& cells) {
    std::array<float, 4> factor{flow.factor.x, flow.factor.y, flow.factor.z, flow.factor.w};
    std::array<float, 2> power{flow.outline_pow.x, flow.outline_pow.y};
    const math::Float4& tint = flow.outline_color;
    std::array<float, 4> color{tint.x, tint.y, tint.z, tint.w};
    const bool has_factor = read_floats(cells[kFlowFactor], factor);
    const bool has_power = read_floats(cells[kOutlinePow], power);
    const bool has_color = read_floats(cells[kOutlineColor], color);
    flow.factor = {.x = factor[0], .y = factor[1], .z = factor[2], .w = factor[3]};
    flow.outline_pow = {.x = power[0], .y = power[1]};
    flow.outline_color = {.x = color[0], .y = color[1], .z = color[2], .w = color[3]};
    return has_factor && has_power && has_color;
}

void read_kinds(Flow& flow, const Cells& cells) {
    flow.has_flow = cells[kFlow] == "1";
    flow.flows_by_uv = flow.has_flow && cells[kFlowLightType] != "0";
    flow.mask_in_alpha = flow.has_flow && cells[kFlowTexType] == "0";
    flow.has_outline = cells[kOutline] == "1";
    flow.uses_outline_map = flow.has_outline && cells[kOutlineCtrl] == "1";
}

// Pass hiện màu: trộn theo scene_blend, cắt theo alpha_rejection. Đục mà có cắt là mặt nạ.
[[nodiscard]] bool read_pass(ProgramLook& look, const Cells& cells) {
    look.alpha = blend_of(cells[kBlend]);
    const std::string_view reference = cells[kAlphaRef];
    const std::optional<float> cutoff = rejection_cutoff(reference);
    if (!reference.empty() && !cutoff) return false;
    look.cutoff = cutoff.value_or(0.0F);
    const bool masks = look.alpha == Alpha::kOpaque && look.cutoff > 0.0F;
    if (masks) look.alpha = Alpha::kMask;
    look.double_sided = sides_of(cells[kCull]);
    if (cells[kDepthPass] != "1") return true;
    const std::string_view depth = cells[kDepthRef];
    const std::optional<float> depth_cut = rejection_cutoff(depth);
    if (!depth.empty() && !depth_cut) return false;
    look.depth_prepass = depth_cut.value_or(0.0F);
    return true;
}

[[nodiscard]] core::Result<ProgramLook> read_row(const Cells& cells, std::size_t line) {
    if (cells.size() != kColumns.size()) return bad_line(line, "số cột khác tiêu đề");
    if (cells[kMaterial].empty()) return bad_line(line, "thiếu tên chất liệu");
    ProgramLook look;
    read_kinds(look.flow, cells);
    if (!read_params(look.flow, cells)) return bad_line(line, "tham số không phải số");
    if (!read_pass(look, cells)) return bad_line(line, "alpha_rejection lạ");
    look.ctl = std::string(cells[kCtl]);
    look.flow_map = std::string(cells[kReflection]);
    look.outline_map = std::string(cells[kOutlineTexture]);
    return look;
}

[[nodiscard]] bool is_header(const Cells& cells) noexcept {
    return std::ranges::equal(cells, kColumns);
}

[[nodiscard]] Cells cells_of(std::string_view line) {
    Cells cells = split(line, '\t');
    for (std::string_view& cell : cells)
        cell = trimmed(cell);
    return cells;
}

[[nodiscard]] bool is_blank(std::string_view line) noexcept {
    return trimmed(line).empty() || line.starts_with('#');
}

// Dòng có nghĩa đầu tiên phải là tiêu đề của công cụ; trả chỉ số dòng ngay sau nó.
[[nodiscard]] core::Result<std::size_t> header_end(const Cells& lines) {
    std::size_t index = 0;
    while (index < lines.size() && is_blank(lines[index]))
        ++index;
    if (index == lines.size()) return core::fail(core::ErrorCode::kCorrupt, "programs.tsv rỗng");
    const Cells cells = cells_of(lines[index]);
    if (!is_header(cells)) return bad_line(index + 1, "tiêu đề khác công cụ");
    return index + 1;
}

[[nodiscard]] core::Status add_row(ProgramTable& table, std::string_view line, std::size_t number) {
    const Cells cells = cells_of(line);
    core::Result<ProgramLook> look = read_row(cells, number);
    if (!look) return std::unexpected(look.error());
    table.insert_or_assign(std::string(cells[kMaterial]), std::move(*look));
    return core::ok();
}

} // namespace

std::optional<float> rejection_cutoff(std::string_view text) {
    const Cells parts = split(trimmed(text), ' ');
    if (parts.size() != 2) return std::nullopt;
    const std::optional<float> value = number_of(parts[1]);
    if (!value) return std::nullopt;
    if (parts[0] == "greater") return (*value + 0.5F) / 255.0F;
    if (parts[0] == "greater_equal") return (*value - 0.5F) / 255.0F;
    return std::nullopt;
}

core::Result<ProgramTable> parse_programs(std::string_view text) {
    const Cells lines = split(text, '\n');
    const core::Result<std::size_t> first = header_end(lines);
    if (!first) return std::unexpected(first.error());
    ProgramTable table;
    for (std::size_t index = *first; index < lines.size(); ++index) {
        if (is_blank(lines[index])) continue;
        const core::Status added = add_row(table, lines[index], index + 1);
        if (!added) return std::unexpected(added.error());
    }
    return table;
}

} // namespace game::resource
