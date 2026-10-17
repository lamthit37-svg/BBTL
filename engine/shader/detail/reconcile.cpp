/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/shader/detail/reconcile.cpp
 *  PHÂN HỆ   : Shader / Detail / Reconcile
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Ghép phản chiếu SPIR-V và DXIL của cùng một nguồn Slang: tên lấy từ
 *    SPIR-V, semantic lấy từ DXIL
 *  - Mọi chỗ hai bên lệch bố cục là lỗi Internal kèm giá trị hai bên, không để
 *    lọt thành phản chiếu sai
 *  - Locations::kSemantic bỏ đầu vào DXIL mà SPIR-V không có (Slang bỏ biến vào
 *    không dùng ở SPIR-V)
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "shader/detail/reconcile.hpp"

#include "shader/failure.hpp"
#include "shader/reflection.hpp"
#include "shader/types.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <format>
#include <ranges>
#include <string>
#include <string_view>
#include <vector>

namespace game::shader::detail {

namespace {

// Danh sách tên trường lệch, cách nhau dấu phẩy; rỗng là hai bên khớp.
class Diff {
public:
    void check(bool same, std::string_view field) {
        if (same) return;
        if (!fields_.empty()) fields_ += ", ";
        fields_ += field;
    }

    // Trường số: ghi kèm giá trị hai bên để lỗi tự nói lệch bao nhiêu.
    void check(std::uint32_t spirv, std::uint32_t dxil, std::string_view field) {
        if (spirv == dxil) return;
        if (!fields_.empty()) fields_ += ", ";
        fields_ += std::format("{} (SPIR-V {}, DXIL {})", field, spirv, dxil);
    }

    [[nodiscard]] std::string finish(std::string_view label) const {
        if (fields_.empty()) return {};
        return std::format("{}: {}", label, fields_);
    }

private:
    std::string fields_;
};

// Mọi trường của tài nguyên trừ tên: tên là chỗ hai bên cố ý khác nhau.
[[nodiscard]] std::string differing(const Resource& spirv, const Resource& dxil) {
    Diff diff;
    diff.check(spirv.kind == dxil.kind, "kind");
    diff.check(spirv.space == dxil.space, "space");
    diff.check(spirv.slot == dxil.slot, "slot");
    diff.check(spirv.binding == dxil.binding, "binding");
    diff.check(spirv.count == dxil.count, "count");
    diff.check(spirv.shape == dxil.shape, "shape");
    diff.check(spirv.array == dxil.array, "array");
    diff.check(spirv.multisample == dxil.multisample, "multisample");
    diff.check(spirv.comparison == dxil.comparison, "comparison");
    diff.check(spirv.raw == dxil.raw, "raw");
    diff.check(spirv.sample == dxil.sample, "sample");
    diff.check(spirv.image_format == dxil.image_format, "image_format");
    diff.check(spirv.stride == dxil.stride, "stride");
    diff.check(spirv.block == dxil.block, "block");
    diff.check(spirv.stages == dxil.stages, "stages");
    return diff.finish(spirv.name);
}

[[nodiscard]] std::string differing(const Variable& spirv, const Variable& dxil) {
    Diff diff;
    diff.check(spirv.offset, dxil.offset, "offset");
    diff.check(spirv.size, dxil.size, "size");
    diff.check(spirv.scalar == dxil.scalar, "scalar");
    diff.check(spirv.bits, dxil.bits, "bits");
    diff.check(spirv.rows, dxil.rows, "rows");
    diff.check(spirv.columns, dxil.columns, "columns");
    diff.check(spirv.elements, dxil.elements, "elements");
    return diff.finish(spirv.name);
}

// Semantic và index là thứ SPIR-V của Slang không có, nên không so ở đây.
[[nodiscard]] std::string differing(const Attribute& spirv, const Attribute& dxil) {
    Diff diff;
    diff.check(spirv.location, dxil.location, "location");
    diff.check(spirv.scalar == dxil.scalar, "scalar");
    diff.check(spirv.bits, dxil.bits, "bits");
    diff.check(spirv.components, dxil.components, "components");
    return diff.finish(std::format("location {}", spirv.location));
}

// Hai danh sách phải cùng độ dài và từng cặp cùng bố cục.
template <class T>
[[nodiscard]] Status match(std::string_view what, const std::vector<T>& spirv, const std::vector<T>& dxil) {
    if (spirv.size() != dxil.size()) {
        return fail(ErrorCode::kInternal, "SPIR-V và DXIL của Slang lệch số phần tử", "{}: SPIR-V {}, DXIL {}", what,
            spirv.size(), dxil.size());
    }
    for (std::size_t index = 0; index < spirv.size(); ++index) {
        const std::string fields = differing(spirv.at(index), dxil.at(index));
        if (!fields.empty()) {
            return fail(ErrorCode::kInternal, "SPIR-V và DXIL của Slang lệch bố cục", "{} {}", what, fields);
        }
    }
    return ok();
}

[[nodiscard]] Status match_blocks(const std::vector<Block>& spirv, const std::vector<Block>& dxil) {
    if (spirv.size() != dxil.size()) {
        return fail(ErrorCode::kInternal, "SPIR-V và DXIL của Slang lệch số cbuffer", "SPIR-V {}, DXIL {}", spirv.size(),
            dxil.size());
    }
    for (std::size_t index = 0; index < spirv.size(); ++index) {
        const Block& left = spirv.at(index);
        const Block& right = dxil.at(index);
        if (left.size != right.size) {
            return fail(ErrorCode::kInternal, "SPIR-V và DXIL của Slang lệch cỡ cbuffer", "{}: SPIR-V {}, DXIL {}",
                left.name, left.size, right.size);
        }
        if (Status same = match(std::format("cbuffer {}, biến", left.name), left.variables, right.variables); !same) {
            return same;
        }
    }
    return ok();
}

[[nodiscard]] bool has_location(const std::vector<Attribute>& list, std::uint32_t location) {
    return std::ranges::find(list, location, &Attribute::location) != list.end();
}

// Đầu vào DXIL có location trùng một đầu vào SPIR-V. Chỉ dùng ở Locations::kSemantic: location hai
// bên cùng tính từ semantic nên ghép được; ở kDeclared location của DXIL là thứ tự khai, bỏ một
// phần tử thì các phần tử sau trượt và có thể ghép nhầm mà không lệch kiểu.
// Hai danh sách cùng kiểu, vai khác nhau: chỗ gọi duy nhất ở reconcile() truyền đúng thứ tự.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
[[nodiscard]] std::vector<Attribute> used_inputs(const std::vector<Attribute>& spirv,
    const std::vector<Attribute>& dxil) {
    std::vector<Attribute> used;
    for (const Attribute& input : dxil) {
        if (has_location(spirv, input.location)) used.push_back(input);
    }
    return used;
}

} // namespace

Result<StageReflection> reconcile(StageReflection spirv, const StageReflection& dxil,
    Locations locations) {
    const bool same_shape = spirv.stage == dxil.stage && spirv.entry == dxil.entry &&
        spirv.group_size == dxil.group_size && spirv.control_points == dxil.control_points;
    if (!same_shape) return fail(ErrorCode::kInternal, "SPIR-V và DXIL của Slang lệch stage, entry hay cỡ nhóm");
    if (Status resources = match("tài nguyên", spirv.resources, dxil.resources); !resources) return pass(resources);
    if (Status blocks = match_blocks(spirv.blocks, dxil.blocks); !blocks) return pass(blocks);
    std::vector<Attribute> inputs = dxil.inputs;
    if (locations == Locations::kSemantic) inputs = used_inputs(spirv.inputs, dxil.inputs);
    if (Status same = match("đầu vào", spirv.inputs, inputs); !same) return pass(same);
    Status outputs = match("đầu ra", spirv.outputs, dxil.outputs);
    if (!outputs) return pass(outputs);
    // Semantic và index của chữ ký lấy từ DXIL, theo đúng vị trí đã khớp location ở match().
    for (auto [target, source] : std::views::zip(spirv.inputs, inputs)) {
        target.semantic = source.semantic;
        target.index = source.index;
    }
    for (auto [target, source] : std::views::zip(spirv.outputs, dxil.outputs)) {
        target.semantic = source.semantic;
        target.index = source.index;
    }
    return spirv;
}

} // namespace game::shader::detail
