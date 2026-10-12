// Shader GLSL và pipeline. Binding compact nằm ở bind_map, không lấy số 1000 của SPIR-V.
#include "gpu/gles/device.hpp"

#include "core/hash.hpp"
#include "core/log.hpp"
#include "gpu/check.hpp"

#include <algorithm>
#include <cstring>
#include <string>

namespace game::gpu::gles {
namespace {

using core::ErrorCode;
using core::fail;

[[nodiscard]] std::string preamble(const GlProfile& profile) {
    std::string text;
    if (profile.is_es) {
        text += "#version 310 es\nprecision highp float;\nprecision highp int;\n";
    } else {
        text += "#version 450 core\n";
    }
    if (profile.has_clip_control) text += "#define TL_ZERO_TO_ONE 1\n";
    return text;
}

[[nodiscard]] core::Status compile_one(GlFunctions& api, std::uint32_t shader, std::string_view name) {
    api.compile_shader(shader);
    int status = 0;
    api.get_shader(shader, GL_COMPILE_STATUS, &status);
    if (status == GL_TRUE) return core::ok();
    int length = 0;
    api.get_shader(shader, GL_INFO_LOG_LENGTH, &length);
    std::string log(static_cast<std::size_t>(std::max(length, 1)), '\0');
    api.shader_log(shader, length, nullptr, log.data());
    core::error("gles shader {}: {}", name, log);
    return fail(ErrorCode::kInvalidArgument, "shader GLES không dịch được");
}

} // namespace

Result<ShaderHandle> GlDevice::create_shader(const ShaderDesc& desc) {
    if (desc.variant == nullptr) return fail(ErrorCode::kInvalidArgument, "shader thiếu bản dịch");
    if (desc.variant->target != shader::Target::kGlsl) {
        return fail(ErrorCode::kInvalidArgument, "shader GLES cần bản glsl");
    }
    GlShader shader;
    shader.stage = desc.variant->reflection.stage;
    shader.reflection = desc.variant->reflection;
    shader.source.assign(reinterpret_cast<const char*>(desc.variant->code.data()), desc.variant->code.size());
    const ShaderHandle handle = shaders_.insert(std::move(shader));
    if (!handle) return fail(ErrorCode::kOutOfMemory, "hết chỗ bảng shader GL");
    return handle;
}

Result<PipelineHandle> GlDevice::create_pipeline(const ComputePipelineDesc&) {
    return fail(ErrorCode::kUnsupported, "compute GLES chưa nối");
}

Result<PipelineHandle> GlDevice::create_pipeline(const GraphicsPipelineDesc& desc) {
    std::vector<shader::StageReflection> stages;
    std::vector<const GlShader*> shaders;
    // Khoá bộ nhớ đệm chương trình gồm cả phần đầu chèn thêm: đổi macro là đổi mã đã dịch, và bộ
    // nhớ đệm sống qua nhiều lần chạy nên khoá cũ không được trúng nhầm.
    const std::string head = preamble(profile());
    std::uint64_t hash = core::fnv1a(head);
    for (const ShaderHandle handle : desc.shaders) {
        const GlShader* shader = shaders_.find(handle);
        if (shader == nullptr) return fail(ErrorCode::kInvalidArgument, "pipeline: shader đã chết");
        stages.push_back(shader->reflection);
        shaders.push_back(shader);
        hash = core::fnv1a(shader->source, hash);
    }
    const core::Result<Program> program = make_program(stages);
    if (!program) return std::unexpected(program.error());
    const core::Status checked = check_pipeline(desc, *program, caps_);
    if (!checked) return std::unexpected(checked.error());
    if (!lock_context()) return fail(ErrorCode::kUnsupported, "context GL không current");
    GlPipeline pipeline;
    pipeline.bindings = map_bindings(program->reflection);
    pipeline.program = api().create_program();
    const ProgramBinary* cached = find_binary(hash);
    bool linked = false;
    if (cached != nullptr && api().program_binary != nullptr) {
        api().program_binary(pipeline.program, cached->format, cached->bytes.data(),
            static_cast<int>(cached->bytes.size()));
        int status = 0;
        api().get_program(pipeline.program, GL_LINK_STATUS, &status);
        linked = status == GL_TRUE;
    }
    if (!linked) {
        std::vector<std::uint32_t> compiled;
        for (const GlShader* shader : shaders) {
            const std::uint32_t kind = shader->stage == shader::Stage::kVertex ? GL_VERTEX_SHADER
                : shader->stage == shader::Stage::kCompute                     ? GL_COMPUTE_SHADER
                                                                               : GL_FRAGMENT_SHADER;
            const std::uint32_t name = api().create_shader(kind);
            const std::string full = head + shader->source;
            const char* text = full.c_str();
            const int length = static_cast<int>(full.size());
            api().shader_source(name, 1, &text, &length);
            const core::Status built = compile_one(api(), name, desc.name);
            if (!built) {
                api().delete_shader(name);
                api().delete_program(pipeline.program);
                unlock_context();
                return std::unexpected(built.error());
            }
            api().attach_shader(pipeline.program, name);
            compiled.push_back(name);
        }
        if (api().program_parameter != nullptr) {
            api().program_parameter(pipeline.program, GL_PROGRAM_BINARY_RETRIEVABLE_HINT, GL_TRUE);
        }
        api().link_program(pipeline.program);
        int status = 0;
        api().get_program(pipeline.program, GL_LINK_STATUS, &status);
        for (const std::uint32_t name : compiled)
            api().delete_shader(name);
        if (status != GL_TRUE) {
            int length = 0;
            api().get_program(pipeline.program, GL_INFO_LOG_LENGTH, &length);
            std::string log(static_cast<std::size_t>(std::max(length, 1)), '\0');
            api().program_log(pipeline.program, length, nullptr, log.data());
            core::error("gles link: {}", log);
            api().delete_program(pipeline.program);
            unlock_context();
            return fail(ErrorCode::kInvalidArgument, "pipeline GLES không liên kết được");
        }
        linked = true;
    }
    if (linked && api().get_program_binary != nullptr) {
        int length = 0;
        api().get_program(pipeline.program, GL_PROGRAM_BINARY_LENGTH, &length);
        if (length > 0) {
            ProgramBinary binary;
            binary.hash = hash;
            binary.bytes.resize(static_cast<std::size_t>(length));
            api().get_program_binary(pipeline.program, length, nullptr, &binary.format, binary.bytes.data());
            remember_binary(std::move(binary));
        }
    }
    pipeline.push_location = api().get_uniform_location(pipeline.program, "tl_push");
    if (!desc.vertex_buffers.empty()) pipeline.stride = desc.vertex_buffers.front().stride;
    for (const VertexAttribute& attribute : desc.vertex_attributes) {
        GlAttribute stored;
        stored.location = attribute.location;
        stored.format = attribute.format;
        stored.offset = attribute.offset;
        pipeline.attributes.push_back(stored);
    }
    pipeline.cull = desc.raster.cull;
    pipeline.front = desc.raster.front_face;
    pipeline.depth_test = desc.depth.is_tested;
    pipeline.depth_write = desc.depth.is_written;
    pipeline.depth_compare = desc.depth.compare;
    pipeline.topology = desc.topology;
    pipeline.alpha_to_coverage = desc.is_alpha_to_coverage;
    pipeline.depth_bias = desc.raster.depth_bias;
    pipeline.depth_slope = desc.raster.depth_bias_slope;
    if (!desc.blends.empty()) {
        pipeline.blend = desc.blends.front().is_enabled;
        pipeline.blend_state = desc.blends.front();
    }
    program_names_.push_back(pipeline.program);
    const PipelineHandle handle = pipelines_.insert(std::move(pipeline));
    unlock_context();
    if (!handle) return fail(ErrorCode::kOutOfMemory, "hết chỗ bảng pipeline GL");
    return handle;
}

Result<BindGroupHandle> GlDevice::create_bind_group(const BindGroupDesc& desc) {
    GlPipeline* pipeline = pipelines_.find(desc.pipeline);
    if (pipeline == nullptr) return fail(ErrorCode::kInvalidArgument, "bind group: pipeline đã chết");
    GlGroup group;
    group.space = desc.space;
    for (const BindEntry& entry : desc.entries) {
        if (find_slot(pipeline->bindings, desc.space, entry.type, entry.slot) == nullptr) {
            return fail(ErrorCode::kInvalidArgument, "bind group: chỗ gắn không có trong shader");
        }
        GlBinding binding;
        binding.type = entry.type;
        binding.slot = entry.slot;
        binding.resource = entry.resource;
        group.bindings.push_back(std::move(binding));
    }
    const BindGroupHandle handle = groups_.insert(std::move(group));
    if (!handle) return fail(ErrorCode::kOutOfMemory, "hết chỗ bảng bind group GL");
    return handle;
}

Status GlDevice::update_bind_group(BindGroupHandle group, std::span<const BindEntry> entries) {
    GlGroup* stored = groups_.find(group);
    if (stored == nullptr) return fail(ErrorCode::kInvalidArgument, "update group: tay nắm chết");
    for (const BindEntry& entry : entries) {
        bool replaced = false;
        for (GlBinding& binding : stored->bindings) {
            if (binding.type != entry.type || binding.slot != entry.slot) continue;
            binding.resource = entry.resource;
            replaced = true;
        }
        if (!replaced) return fail(ErrorCode::kInvalidArgument, "update group: chỗ gắn lạ");
    }
    return core::ok();
}

} // namespace game::gpu::gles
