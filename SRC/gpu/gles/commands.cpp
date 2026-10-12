// Thực thi lệnh GL. Viewport gốc trên-trái đổi sang gốc dưới-trái: glViewport không nhận chiều cao
// âm (INVALID_VALUE), còn viewport âm của Vulkan chỉ để ra cùng một hình với D3D.
// Mỗi trạng thái GL đều đi qua bộ nhớ đệm của thiết bị (GlDrawCache): trên PowerVR, một lời gọi
// trạng thái thừa tốn hàng chục micro giây nên cảnh nhỏ vẫn quá chậm nếu gọi lại mọi thứ mỗi lệnh vẽ.
#include "gpu/gles/commands.hpp"

#include "gpu/format.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <ranges>
#include <span>
#include <utility>
#include <vector>

namespace game::gpu::gles {
namespace {

using core::ErrorCode;
using core::fail;

constexpr ErrorCode kBad = ErrorCode::kInvalidArgument;
constexpr ErrorCode kState = ErrorCode::kInvalidState;
constexpr std::uint32_t kPushAlign = 256;
// Số uvec4 tối đa của khối hằng đẩy: 256 byte, bằng kPushAlign.
constexpr std::size_t kPushWords = 16;

[[nodiscard]] std::uint32_t compare_of(CompareOp op) noexcept {
    switch (op) {
    case CompareOp::kNever: return GL_NEVER;
    case CompareOp::kLess: return GL_LESS;
    case CompareOp::kEqual: return GL_EQUAL;
    case CompareOp::kLessOrEqual: return GL_LEQUAL;
    case CompareOp::kGreater: return GL_GREATER;
    case CompareOp::kNotEqual: return GL_NOTEQUAL;
    case CompareOp::kGreaterOrEqual: return GL_GEQUAL;
    case CompareOp::kAlways: return GL_ALWAYS;
    }
    device.api().bind_sampler(index, name);
}

// Công tắc mã hoá sRGB của ES (EXT_sRGB_write_control) là trạng thái của lệnh vẽ: pipeline màu thô
// tắt nó, còn lệnh xoá và lệnh chép (resolve, trình bày) cần nó bật. ES luôn giải mã nguồn sRGB khi
// chép, nên để tắt thì cả khung ra màn hình tối đi đúng một lần giải mã (đã đo trên PowerVR GE8320).
// Desktop GL chép nguyên số khi công tắc tắt nên không cần.
void encode_again(GlDevice& device) {
    const GlProfile& profile = device.profile();
    if (profile.is_es && profile.has_raw_color) device.api().enable(GL_FRAMEBUFFER_SRGB);
}

} // namespace

GlCommands::GlCommands(GlDevice& device, QueueType queue) : device_(&device), queue_(queue) {}

void GlCommands::reset(QueueType queue) {
    queue_ = queue;
    is_open_ = true;
    is_rendering_ = false;
    error_.reset();
    pipeline_ = {};
    groups_.fill({});
    vertices_ = {};
    vertex_offset_ = 0;
    indices_ = {};
    index_offset_ = 0;
    push_.clear();
    has_push_ = false;
    target_height_ = 0;
    resolve_ = {};
    // reset_push (gọi ngay sau đây ở begin_commands) xả buffer đẩy, nên vùng đã gắn của lệnh trước
    // không còn dùng được: bỏ hết bộ nhớ đệm trạng thái.
    device_->invalidate_draw_cache();
}

core::Status GlCommands::take_error() {
    is_open_ = false;
    if (!error_) return core::ok();
    return std::unexpected(*error_);
}

QueueType GlCommands::queue() const noexcept {
    return queue_;
}

void GlCommands::reject(core::Failure failure) {
    if (error_) return;
    error_ = std::move(failure.error());
}

bool GlCommands::live() const noexcept {
    return is_open_ && !error_;
}

void GlCommands::begin_label(std::string_view) {}
void GlCommands::end_label() {}
void GlCommands::insert_label(std::string_view) {}

void GlCommands::barrier(std::span<const BufferBarrier>, std::span<const TextureBarrier>,
    std::span<const GlobalBarrier>) {
    // Bố cục ảnh của Vulkan không phải glMemoryBarrier. ALL_BARRIER_BITS trên PowerVR
    // xả tile mỗi khung; GL đã sắp lệnh vẽ và glTexSubImage trong cùng context.
    if (!live()) return;
}

void GlCommands::begin_rendering(const RenderingDesc& desc) {
    if (!live()) return;
    if (is_rendering_ || queue_ != QueueType::kGraphics) {
        reject(fail(kState, "begin_rendering lồng nhau hoặc ngoài hàng Graphics"));
        return;
    }
    if (desc.colors.empty() && !desc.depth) {
        reject(fail(kBad, "begin_rendering thiếu attachment"));
        return;
    }
    GlFunctions& api = device_->api();
    const std::uint32_t framebuffer = device_->draw_framebuffer();
    api.bind_framebuffer(GL_FRAMEBUFFER, framebuffer);
    GlView* first = nullptr;
    if (!desc.colors.empty()) {
        first = device_->view(desc.colors.front().view);
        if (first == nullptr) {
            reject(fail(kBad, "begin_rendering: view màu đã chết"));
            return;
        }
        api.framebuffer_texture(
            GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, first->target, first->name, 0);
        const std::uint32_t color = GL_COLOR_ATTACHMENT0;
        api.draw_buffers(1, &color);
    }
    if (desc.depth) {
        GlView* depth = device_->view(desc.depth->view);
        if (depth == nullptr) {
            reject(fail(kBad, "begin_rendering: view độ sâu đã chết"));
            return;
        }
        api.framebuffer_texture(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, depth->target, depth->name, 0);
        if (first == nullptr) first = depth;
    }
    if (api.check_framebuffer(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        reject(fail(kState, "framebuffer GL không hoàn chỉnh"));
        return;
    }
    target_height_ = first->height;
    pass_width_ = first->width;
    pass_height_ = first->height;
    Scissor area = desc.area;
    if (area.width == 0 || area.height == 0) {
        area.width = pass_width_;
        area.height = pass_height_;
    }
    viewport_of(api, static_cast<float>(area.x), static_cast<float>(area.y),
        static_cast<float>(area.width), static_cast<float>(area.height), target_height_);
    api.enable(GL_SCISSOR_TEST);
    scissor_of(api, area, target_height_);
    // GLES tự mã hoá attachment sRGB. GL_FRAMEBUFFER_SRGB không có trong ES: bật nó là
    // INVALID_ENUM và driver có thể bỏ lệnh xoá độ sâu ngay sau đó.
    if (!device_->profile().is_es) {
        if (first->srgb) api.enable(GL_FRAMEBUFFER_SRGB);
        if (!first->srgb) api.disable(GL_FRAMEBUFFER_SRGB);
    }
    encode_again(*device_);
    // glClear tôn trọng mask của pipeline khung trước. Vulkan thì không. Depth mask tắt
    // thì màu vẫn xoá, độ sâu đảo giữ nguyên 1, gần như mọi mảnh rơi ở test GEQUAL.
    const auto write = static_cast<std::uint8_t>(GL_TRUE);
    api.color_mask(write, write, write, write);
    api.depth_mask(write);
    if (!desc.colors.empty() && desc.colors.front().load == LoadOp::kClear) {
        const ClearColor& clear = desc.colors.front().clear;
        const std::array<float, 4> color{clear.red, clear.green, clear.blue, clear.alpha};
        api.clear_buffer(GL_COLOR, 0, color.data());
    }
    if (desc.depth && desc.depth->load == LoadOp::kClear) {
        const float depth = desc.depth->clear.depth;
        api.clear_buffer(GL_DEPTH, 0, &depth);
    }
    resolve_ = desc.colors.empty() ? TextureViewHandle{} : desc.colors.front().resolve;
    is_rendering_ = true;
    // color_mask và depth_mask ở trên đổi trạng thái ngoài lệnh vẽ: bộ nhớ đệm không còn đúng.
    device_->invalidate_draw_cache();
}

void GlCommands::end_rendering() {
    if (!live()) return;
    if (!is_rendering_) {
        reject(fail(kState, "end_rendering không có begin_rendering"));
        return;
    }
    // Phép cắt là trạng thái của lượt vẽ. glBlitFramebuffer cũng bị nó cắt, nên để nguyên thì lệnh
    // chép lúc resolve hay lúc trình bày chỉ còn ô của lượt vừa đóng (một lượt 128 x 128 ngoài màn
    // hình làm cả khung đen trừ một góc). begin_rendering kế bật lại.
    device_->api().disable(GL_SCISSOR_TEST);
    encode_again(*device_);
    if (resolve_) {
        GlView* view = device_->view(resolve_);
        if (view == nullptr) {
            reject(fail(kBad, "resolve: view đã chết"));
            return;
        }
        GlFunctions& api = device_->api();
        const std::uint32_t draw = device_->read_framebuffer();
        api.bind_framebuffer(GL_DRAW_FRAMEBUFFER, draw);
        api.framebuffer_texture(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, view->target, view->name, 0);
        api.bind_framebuffer(GL_READ_FRAMEBUFFER, device_->draw_framebuffer());
        api.blit_framebuffer(0, 0, static_cast<int>(pass_width_), static_cast<int>(pass_height_), 0, 0,
            static_cast<int>(view->width), static_cast<int>(view->height), GL_COLOR_BUFFER_BIT,
            GL_NEAREST);
    }
    device_->api().bind_framebuffer(GL_FRAMEBUFFER, 0);
    is_rendering_ = false;
    resolve_ = {};
    device_->invalidate_draw_cache();
}

void GlCommands::set_viewport(const Viewport& viewport) {
    if (!live()) return;
    viewport_of(device_->api(), viewport.x, viewport.y, viewport.width, viewport.height, target_height_);
}

void GlCommands::set_scissor(const Scissor& scissor) {
    if (!live()) return;
    scissor_of(device_->api(), scissor, target_height_);
}

void GlCommands::set_stencil_reference(std::uint32_t) {}

void GlCommands::set_blend_constants(const ClearColor& color) {
    if (!live()) return;
    device_->api().blend_color(color.red, color.green, color.blue, color.alpha);
}

void GlCommands::set_depth_bounds(float, float) {
    if (!live()) return;
    reject(fail(ErrorCode::kUnsupported, "GL không có depth bounds trên đường này"));
}

void GlCommands::bind_pipeline(PipelineHandle pipeline) {
    if (!live()) return;
    if (device_->pipeline(pipeline) == nullptr) {
        reject(fail(kBad, "bind_pipeline: pipeline đã chết"));
        return;
    }
    pipeline_ = pipeline;
}

void GlCommands::bind_group(std::uint32_t space, BindGroupHandle group) {
    if (!live()) return;
    if (space >= kMaxBindGroups) {
        reject(fail(kBad, "bind_group: space vượt trần"));
        return;
    }
    groups_.at(space) = group;
}

void GlCommands::push_constants(std::span<const std::byte> data, std::uint32_t offset) {
    if (!live()) return;
    if (offset + data.size() > kMaxPushBytes) {
        reject(fail(kBad, "push_constants vượt khối"));
        return;
    }
    if (push_.size() < offset + data.size()) push_.resize(offset + data.size());
    std::memcpy(push_.data() + offset, data.data(), data.size());
    has_push_ = true;
    push_offset_ = 0;
}

void GlCommands::bind_vertex_buffer(std::uint32_t slot, BufferHandle buffer, std::uint64_t offset) {
    if (!live()) return;
    if (slot != 0) {
        reject(fail(kBad, "GLES chỉ gắn một buffer đỉnh"));
        return;
    }
    vertices_ = buffer;
    vertex_offset_ = offset;
}

void GlCommands::bind_index_buffer(BufferHandle buffer, IndexType type, std::uint64_t offset) {
    if (!live()) return;
    indices_ = buffer;
    index_type_ = type;
    index_offset_ = offset;
}

void GlCommands::draw_common(std::uint32_t count, std::uint32_t instances, bool indexed) {
    GlPipeline* pipeline = device_->pipeline(pipeline_);
    if (pipeline == nullptr || pipeline->is_compute) {
        reject(fail(kState, "vẽ: thiếu pipeline đồ hoạ"));
        return;
    }
    GlFunctions& api = device_->api();
    apply_pipeline(api, *pipeline);
    is_raw_color_ = pipeline->raw_color;
    bind_groups(*pipeline);
    bind_push(*pipeline);
    bind_geometry(api);
    issue_draw(api, *pipeline, count, instances, indexed);
}

// Trạng thái của pipeline (chương trình, cull, độ sâu, trộn): context đang giữ đúng pipeline ấy thì
// không gọi lại gì cả.
void GlCommands::apply_pipeline(GlFunctions& api, const GlPipeline& pipeline) {
    GlDrawCache& cache = device_->draw_cache();
    const bool is_same = cache.has_pipeline && cache.pipeline == pipeline_;
    if (is_same) return;
    cache.has_pipeline = true;
    cache.pipeline = pipeline_;
    api.use_program(pipeline.program);
    const bool culls = pipeline.cull != CullMode::kNone;
    if (culls) api.enable(GL_CULL_FACE);
    if (!culls) api.disable(GL_CULL_FACE);
    if (culls) api.cull_face(pipeline.cull == CullMode::kFront ? GL_FRONT : GL_BACK);
    api.front_face(pipeline.front == FrontFace::kClockwise ? GL_CW : GL_CCW);
    if (pipeline.depth_test) api.enable(GL_DEPTH_TEST);
    if (!pipeline.depth_test) api.disable(GL_DEPTH_TEST);
    api.depth_func(compare_of(pipeline.depth_compare));
    api.depth_mask(static_cast<std::uint8_t>(pipeline.depth_write ? GL_TRUE : GL_FALSE));
    if (pipeline.blend) api.enable(GL_BLEND);
    if (!pipeline.blend) api.disable(GL_BLEND);
    const BlendState& blend = pipeline.blend_state;
    api.blend_func(factor_of(blend.src_color), factor_of(blend.dst_color), factor_of(blend.src_alpha),
        factor_of(blend.dst_alpha));
    api.blend_equation(equation_of(blend.color_op), equation_of(blend.alpha_op));
    const bool offsets = pipeline.depth_bias != 0.0F || pipeline.depth_slope != 0.0F;
    if (offsets) api.enable(GL_POLYGON_OFFSET_FILL);
    if (offsets) api.polygon_offset(pipeline.depth_slope, pipeline.depth_bias);
    if (pipeline.alpha_to_coverage) api.enable(GL_SAMPLE_ALPHA_TO_COVERAGE);
    if (!pipeline.alpha_to_coverage) api.disable(GL_SAMPLE_ALPHA_TO_COVERAGE);
    apply_color_coding(api, pipeline);
}

// Pipeline màu thô ghi thẳng số đã mã hoá; pipeline thường để phần cứng mã hoá. Chỉ đổi khi driver
// có công tắc; đích không phải sRGB thì công tắc này không có tác dụng gì.
void GlCommands::apply_color_coding(GlFunctions& api, const GlPipeline& pipeline) {
    if (!device_->profile().has_raw_color) return;
    if (pipeline.raw_color) api.disable(GL_FRAMEBUFFER_SRGB);
    if (!pipeline.raw_color) api.enable(GL_FRAMEBUFFER_SRGB);
}

void GlCommands::bind_groups(const GlPipeline& pipeline) {
    for (std::uint32_t space = 0; space < kMaxBindGroups; ++space) {
        bind_group_at(pipeline, space);
    }
}

void GlCommands::bind_group_at(const GlPipeline& pipeline, std::uint32_t space) {
    GlGroup* group = device_->group(groups_.at(space));
    if (group == nullptr) return;
    for (const GlBinding& binding : group->bindings) {
        bind_entry(pipeline, space, binding);
    }
}

void GlCommands::bind_entry(
    const GlPipeline& pipeline, std::uint32_t space, const GlBinding& binding) {
    const BindSlot* slot = find_slot(pipeline.bindings, space, binding.type, binding.slot);
    if (slot == nullptr) return;
    bind_slot(*slot, binding.resource);
}

void GlCommands::bind_slot(const BindSlot& slot, const Bound& resource) {
    if (const BufferRange* range = std::get_if<BufferRange>(&resource)) {
        bind_range(slot, *range);
        return;
    }
    if (const TextureViewHandle* view = std::get_if<TextureViewHandle>(&resource)) {
        bind_view(slot, *view);
        return;
    }
    if (const SamplerHandle* sampler = std::get_if<SamplerHandle>(&resource)) {
        bind_object(slot, *sampler);
    }
}

void GlCommands::bind_range(const BindSlot& slot, const BufferRange& range) {
    GlBuffer* buffer = device_->buffer(range.buffer);
    if (buffer == nullptr) return;
    const std::uint32_t target =
        slot.kind == BindClass::kStorage ? GL_SHADER_STORAGE_BUFFER : GL_UNIFORM_BUFFER;
    const std::uint64_t size = range.size == kWholeSize ? buffer->size - range.offset : range.size;
    bind_buffer_once(*device_, target, slot.index, buffer->name, range.offset, size);
}

void GlCommands::bind_view(const BindSlot& slot, const TextureViewHandle& handle) {
    GlView* view = device_->view(handle);
    if (view == nullptr) return;
    bind_texture_once(*device_, slot.index, view->target, view->name);
}

void GlCommands::bind_object(const BindSlot& slot, const SamplerHandle& handle) {
    GlSampler* object = device_->sampler(handle);
    if (object == nullptr) return;
    bind_sampler_once(*device_, slot.index, object->name);
}

namespace {

// Đặt khối hằng đẩy thành uniform thường "tl_push" (mảng uvec4, giữ nguyên bit của cả số thực lẫn
// số nguyên). Đo trên PowerVR GE8320: chép khối này vào buffer bằng glBufferSubData trước mỗi lệnh
// vẽ chiếm 69% CPU của luồng vẽ, vì driver phải xin vùng nhớ mới hoặc chờ GPU nhả buffer.
void push_as_uniform(GlFunctions& api, int location, std::span<const std::byte> data) {
    std::array<std::uint32_t, kPushWords * 4> words{};
    const std::size_t bytes = std::min(data.size(), words.size() * sizeof(std::uint32_t));
    std::memcpy(words.data(), data.data(), bytes);
    const std::size_t vectors = (bytes + 15) / 16;
    api.uniform4uiv(location, static_cast<int>(vectors), words.data());
}

} // namespace

// Khối hằng đẩy: shader khai "tl_push" thì đi đường uniform thường; shader cũ còn khai khối std140
// thì chép vào buffer đẩy và gắn vùng (vùng đổi mỗi lệnh vẽ, lệnh gắn chỉ khi vùng đổi).
void GlCommands::bind_push(const GlPipeline& pipeline) {
    if (!has_push_ || !pipeline.bindings.has_push) return;
    if (pipeline.push_location >= 0) {
        push_as_uniform(device_->api(), pipeline.push_location, push_);
        return;
    }
    const std::uint32_t offset = device_->push_range(push_);
    bind_buffer_once(*device_, GL_UNIFORM_BUFFER, pipeline.bindings.push_binding, device_->push_buffer(),
        offset, kPushAlign);
}

// Hình học: VAO nhớ sẵn khuôn thuộc tính của cặp (pipeline, buffer đỉnh, buffer chỉ số), nên lần
// vẽ sau chỉ còn một lệnh gắn VAO thay cho mỗi thuộc tính một cặp lệnh.
void GlCommands::bind_geometry(GlFunctions& api) {
    VertexKey key;
    key.pipeline = pipeline_;
    key.vertices = vertices_;
    key.vertex_offset = vertex_offset_;
    key.indices = indices_;
    GlDrawCache& cache = device_->draw_cache();
    const bool is_same = cache.has_vertices && cache.vertices == key;
    if (is_same) return;
    const std::uint32_t array = device_->vertex_array_for(key);
    if (array == 0) {
        reject(fail(kState, "vẽ: thiếu buffer đỉnh"));
        return;
    }
    api.bind_vertex_array(array);
    GlBuffer* indices = device_->buffer(indices_);
    if (indices != nullptr) api.bind_buffer(GL_ELEMENT_ARRAY_BUFFER, indices->name);
    cache.has_vertices = true;
    cache.vertices = key;
}

void GlCommands::issue_draw(GlFunctions& api, const GlPipeline& pipeline, std::uint32_t count,
    std::uint32_t instances, bool indexed) {
    const std::uint32_t mode = topology_of(pipeline.topology);
    if (!indexed) {
        if (instances > 1) {
            api.draw_arrays_instanced(mode, 0, static_cast<int>(count), static_cast<int>(instances));
            return;
        }
        api.draw_arrays(mode, 0, static_cast<int>(count));
        return;
    }
    GlBuffer* index_buffer = device_->buffer(indices_);
    if (index_buffer == nullptr) {
        reject(fail(kState, "vẽ: thiếu buffer chỉ số"));
        return;
    }
    const std::uint32_t type = index_type_ == IndexType::kUint16 ? GL_UNSIGNED_SHORT : GL_UNSIGNED_INT;
    const auto pointer = reinterpret_cast<const void*>(static_cast<std::uintptr_t>(index_offset_));
    if (api.draw_elements_instanced != nullptr) {
        api.draw_elements_instanced(
            mode, static_cast<int>(count), type, pointer, static_cast<int>(instances), 0);
        return;
    }
    api.draw_elements(mode, static_cast<int>(count), type, pointer);
}

void GlCommands::draw(const DrawArguments& arguments) {
    if (!live()) return;
    if (!is_rendering_) {
        reject(fail(kState, "vẽ: thiếu begin_rendering"));
        return;
    }
    draw_common(arguments.vertex_count, arguments.instance_count, false);
}

void GlCommands::draw_indexed(const DrawIndexedArguments& arguments) {
    if (!live()) return;
    if (!is_rendering_) {
        reject(fail(kState, "vẽ: thiếu begin_rendering"));
        return;
    }
    const std::uint32_t index_size = index_type_ == IndexType::kUint16 ? 2U : 4U;
    index_offset_ += static_cast<std::uint64_t>(arguments.first_index) * index_size;
    draw_common(arguments.index_count, arguments.instance_count, true);
    index_offset_ -= static_cast<std::uint64_t>(arguments.first_index) * index_size;
}

void GlCommands::draw_indirect(BufferHandle, std::uint64_t, std::uint32_t, std::uint32_t) {
    if (!live()) return;
    reject(fail(ErrorCode::kUnsupported, "GLES chưa vẽ gián tiếp"));
}

void GlCommands::draw_indexed_indirect(BufferHandle, std::uint64_t, std::uint32_t, std::uint32_t) {
    if (!live()) return;
    reject(fail(ErrorCode::kUnsupported, "GLES chưa vẽ gián tiếp"));
}

void GlCommands::dispatch(const DispatchArguments&) {
    if (!live()) return;
    reject(fail(ErrorCode::kUnsupported, "compute GLES chưa nối"));
}

void GlCommands::dispatch_indirect(BufferHandle, std::uint64_t) {
    if (!live()) return;
    reject(fail(ErrorCode::kUnsupported, "compute GLES chưa nối"));
}

void GlCommands::copy_buffer(BufferHandle source, BufferHandle target, const BufferCopy& region) {
    if (!live()) return;
    if (is_rendering_) {
        reject(fail(kState, "lệnh chép nằm trong begin_rendering"));
        return;
    }
    GlBuffer* from = device_->buffer(source);
    GlBuffer* to = device_->buffer(target);
    if (from == nullptr || to == nullptr) {
        reject(fail(kBad, "copy_buffer: buffer đã chết"));
        return;
    }
    GlFunctions& api = device_->api();
    api.bind_buffer(GL_COPY_READ_BUFFER, from->name);
    api.bind_buffer(GL_COPY_WRITE_BUFFER, to->name);
    api.copy_buffer(GL_COPY_READ_BUFFER, GL_COPY_WRITE_BUFFER, static_cast<std::intptr_t>(region.source_offset),
        static_cast<std::intptr_t>(region.target_offset), static_cast<std::intptr_t>(region.size));
}

void GlCommands::copy_texture(TextureHandle, TextureHandle, const TextureCopy&) {
    if (!live()) return;
    reject(fail(ErrorCode::kUnsupported, "copy texture GLES chưa nối"));
}

void GlCommands::copy_buffer_to_texture(BufferHandle source, TextureHandle target,
    std::span<const BufferTextureCopy> regions) {
    if (!live()) return;
    GlBuffer* buffer = device_->buffer(source);
    GlTexture* texture = device_->texture(target);
    if (buffer == nullptr || texture == nullptr) {
        reject(fail(kBad, "copy_buffer_to_texture: tài nguyên đã chết"));
        return;
    }
    const bool is_rgba = texture->format == Format::kRgba8Unorm || texture->format == Format::kRgba8UnormSrgb;
    if (texture->samples != 1 || !is_rgba) {
        reject(fail(ErrorCode::kUnsupported, "upload GL chỉ nhận RGBA8"));
        return;
    }
    GlFunctions& api = device_->api();
    // Buffer đang map không được làm PBO. Dữ liệu nằm ở con trỏ map thì đưa thẳng cho glTexSubImage.
    const bool is_mapped = buffer->mapped != nullptr;
    api.bind_buffer(GL_PIXEL_UNPACK_BUFFER, is_mapped ? 0 : buffer->name);
    api.pixel_store(GL_UNPACK_ALIGNMENT, 1);
    api.bind_texture(texture->target, texture->name);
    for (const BufferTextureCopy& region : regions) {
        const std::uint32_t mip_width = std::max(texture->width >> region.mip, 1U);
        const std::uint32_t mip_height = std::max(texture->height >> region.mip, 1U);
        const std::uint32_t width = region.width == 0 ? mip_width : region.width;
        const std::uint32_t height = region.height == 0 ? mip_height : region.height;
        const std::uint32_t row = region.row_bytes == 0
            ? static_cast<std::uint32_t>(padded_row_bytes(texture->format, width))
            : region.row_bytes;
        api.pixel_store(GL_UNPACK_ROW_LENGTH, static_cast<int>(row / 4));
        const void* pointer = nullptr;
        if (is_mapped) {
            pointer = static_cast<const std::byte*>(buffer->mapped) + region.buffer_offset;
        } else {
            pointer = reinterpret_cast<const void*>(static_cast<std::uintptr_t>(region.buffer_offset));
        }
        api.tex_sub_image(texture->target, static_cast<int>(region.mip), static_cast<int>(region.x),
            static_cast<int>(region.y), static_cast<int>(width), static_cast<int>(height), GL_RGBA, GL_UNSIGNED_BYTE,
            pointer);
    }
    api.pixel_store(GL_UNPACK_ROW_LENGTH, 0);
    api.bind_buffer(GL_PIXEL_UNPACK_BUFFER, 0);
    // Lệnh chép vừa gắn ảnh vào một đơn vị texture ngoài lệnh vẽ.
    device_->invalidate_draw_cache();
}

void GlCommands::copy_texture_to_buffer(TextureHandle source, BufferHandle target,
    std::span<const BufferTextureCopy> regions) {
    if (!live()) return;
    GlTexture* texture = device_->texture(source);
    GlBuffer* buffer = device_->buffer(target);
    if (texture == nullptr || buffer == nullptr) {
        reject(fail(kBad, "copy_texture_to_buffer: tài nguyên đã chết"));
        return;
    }
    GlFunctions& api = device_->api();
    const std::uint32_t framebuffer = device_->read_framebuffer();
    api.bind_framebuffer(GL_READ_FRAMEBUFFER, framebuffer);
    api.framebuffer_texture(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, texture->target, texture->name, 0);
    api.read_buffer(GL_COLOR_ATTACHMENT0);
    api.pixel_store(GL_PACK_ALIGNMENT, 1);
    api.bind_buffer(GL_PIXEL_PACK_BUFFER, 0);
    for (const BufferTextureCopy& region : regions) {
        const std::uint32_t width = region.width == 0 ? texture->width : region.width;
        const std::uint32_t height = region.height == 0 ? texture->height : region.height;
        const std::uint32_t row = region.row_bytes == 0
            ? static_cast<std::uint32_t>(padded_row_bytes(texture->format, width))
            : region.row_bytes;
        const std::uint32_t tight = static_cast<std::uint32_t>(row_bytes(texture->format, width));
        std::vector<std::byte> pixels(static_cast<std::size_t>(tight) * height);
        const int bottom = static_cast<int>(texture->height - region.y - height);
        api.read_pixels(static_cast<int>(region.x), bottom, static_cast<int>(width), static_cast<int>(height), GL_RGBA,
            GL_UNSIGNED_BYTE, pixels.data());
        std::vector<std::byte> packed(static_cast<std::size_t>(row) * height);
        for (std::uint32_t line = 0; line < height; ++line) {
            const std::uint32_t source_line = texture->is_target ? height - 1 - line : line;
            std::memcpy(packed.data() + static_cast<std::size_t>(line) * row,
                pixels.data() + static_cast<std::size_t>(source_line) * tight, tight);
        }
        if (buffer->mapped != nullptr) {
            auto* destination = static_cast<std::byte*>(buffer->mapped) + region.buffer_offset;
            std::memcpy(destination, packed.data(), packed.size());
        } else {
            api.bind_buffer(GL_COPY_WRITE_BUFFER, buffer->name);
            api.buffer_sub_data(GL_COPY_WRITE_BUFFER, static_cast<std::intptr_t>(region.buffer_offset),
                static_cast<std::intptr_t>(packed.size()), packed.data());
        }
    }
    api.bind_framebuffer(GL_READ_FRAMEBUFFER, 0);
    device_->invalidate_draw_cache();
}

void GlCommands::reset_queries(QueryPoolHandle, std::uint32_t, std::uint32_t) {
    if (!live()) return;
    reject(fail(ErrorCode::kUnsupported, "query GLES chưa nối"));
}

void GlCommands::write_timestamp(QueryPoolHandle, std::uint32_t, SyncStage) {
    if (!live()) return;
    reject(fail(ErrorCode::kUnsupported, "query GLES chưa nối"));
}

void GlCommands::begin_occlusion(QueryPoolHandle, std::uint32_t) {
    if (!live()) return;
    reject(fail(ErrorCode::kUnsupported, "query GLES chưa nối"));
}

void GlCommands::end_occlusion(QueryPoolHandle, std::uint32_t) {
    if (!live()) return;
    reject(fail(ErrorCode::kUnsupported, "query GLES chưa nối"));
}

void GlCommands::resolve_queries(QueryPoolHandle, std::uint32_t, std::uint32_t) {
    if (!live()) return;
    reject(fail(ErrorCode::kUnsupported, "query GLES chưa nối"));
}

void GlCommands::execute() {
    device_->reset_push();
}

} // namespace game::gpu::gles
