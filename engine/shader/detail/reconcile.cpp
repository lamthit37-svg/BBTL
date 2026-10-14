#include "shader/detail/reconcile.hpp"

#include "shader/failure.hpp"
#include "shader/reflection.hpp"
#include "shader/types.hpp"

#include <cstddef>
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
    diff.check(spirv.offset == dxil.offset, "offset");
    diff.check(spirv.size == dxil.size, "size");
    diff.check(spirv.scalar == dxil.scalar, "scalar");
    diff.check(spirv.bits == dxil.bits, "bits");
    diff.check(spirv.rows == dxil.rows, "rows");
    diff.check(spirv.columns == dxil.columns, "columns");
    diff.check(spirv.elements == dxil.elements, "elements");
    return diff.finish(spirv.name);
}

// Semantic và index là thứ SPIR-V của Slang không có, nên không so ở đây.
[[nodiscard]] std::string differing(const Attribute& spirv, const Attribute& dxil) {
    Diff diff;
    diff.check(spirv.location == dxil.location, "location");
    diff.check(spirv.scalar == dxil.scalar, "scalar");
    diff.check(spirv.bits == dxil.bits, "bits");
    diff.check(spirv.components == dxil.components, "components");
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

} // namespace

Result<StageReflection> reconcile(StageReflection spirv, const StageReflection& dxil) {
    const bool same_shape = spirv.stage == dxil.stage && spirv.entry == dxil.entry &&
        spirv.group_size == dxil.group_size && spirv.control_points == dxil.control_points;
    if (!same_shape) return fail(ErrorCode::kInternal, "SPIR-V và DXIL của Slang lệch stage, entry hay cỡ nhóm");
    if (Status resources = match("tài nguyên", spirv.resources, dxil.resources); !resources) return pass(resources);
    if (Status blocks = match_blocks(spirv.blocks, dxil.blocks); !blocks) return pass(blocks);
    if (Status inputs = match("đầu vào", spirv.inputs, dxil.inputs); !inputs) return pass(inputs);
    if (Status outputs = match("đầu ra", spirv.outputs, dxil.outputs); !outputs) return pass(outputs);
    // Semantic và index của chữ ký lấy từ DXIL, theo đúng vị trí đã khớp location ở match().
    for (auto [target, source] : std::views::zip(spirv.inputs, dxil.inputs)) {
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
