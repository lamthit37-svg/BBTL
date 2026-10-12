// Vòng đời thiết bị GL: context, buffer, hàng đợi một mutex và hàng rào fence.
#include "gpu/gles/device.hpp"

#include "gpu/check.hpp"
#include "gpu/gles/commands.hpp"

#include <algorithm>
#include <chrono>
#include <cstring>
#include <thread>
#include <utility>

namespace game::gpu::gles {
namespace {

using core::ErrorCode;
using core::fail;
using core::ok;

constexpr ErrorCode kBad = ErrorCode::kInvalidArgument;
constexpr std::uint32_t kPushBytes = 256U * 512U;

void erase_name(std::vector<std::uint32_t>& names, std::uint32_t name) {
    const auto found = std::ranges::find(names, name);
    if (found != names.end()) names.erase(found);
}

class GlTimeline final : public Timeline {
public:
    explicit GlTimeline(std::uint64_t initial) : value_(initial) {}

    [[nodiscard]] std::uint64_t completed() const noexcept override { return value_.load(std::memory_order_acquire); }

    [[nodiscard]] core::Status wait(std::uint64_t value, std::chrono::nanoseconds timeout) override {
        const auto start = std::chrono::steady_clock::now();
        while (completed() < value) {
            if (std::chrono::steady_clock::now() - start > timeout) {
                return fail(ErrorCode::kTimeout, "hết giờ chờ timeline GL");
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
        return ok();
    }

    void signal(std::uint64_t value) override {
        std::uint64_t current = value_.load(std::memory_order_relaxed);
        while (current < value && !value_.compare_exchange_weak(current, value, std::memory_order_release)) {
        }
    }

private:
    std::atomic<std::uint64_t> value_;
};

} // namespace

GlDevice::GlDevice(GlContext context, AdapterInfo adapter, DeviceCaps caps, bool validated)
    : context_(std::move(context)), adapter_(std::move(adapter)), caps_(caps) {
    if (!lock_context()) return;
    if (validated) context_.set_debug_sink(&errors_);
    int kilobytes = 0;
    api().get_integer(GL_GPU_MEMORY_INFO_TOTAL_AVAILABLE_MEMORY, &kilobytes);
    while (api().get_error() != 0) {
    }
    if (kilobytes > 0) budget_bytes_ = static_cast<std::uint64_t>(kilobytes) * 1024U;
    unlock_context();
}

GlDevice::~GlDevice() {
    if (!lock_context()) return;
    for (const PendingFence& fence : fences_) {
        if (fence.sync != nullptr) api().client_wait(fence.sync, 0, GL_TIMEOUT_IGNORED);
        if (fence.sync != nullptr) api().delete_sync(fence.sync);
    }
    fences_.clear();
    // Vùng đẩy nằm trong buffer_names_, phải bỏ map trước khi xoá buffer.
    unmap_push();
    for (const std::uint32_t name : buffer_names_)
        api().delete_buffers(1, &name);
    for (const std::uint32_t name : texture_names_)
        api().delete_textures(1, &name);
    for (const std::uint32_t name : sampler_names_)
        api().delete_samplers(1, &name);
    for (const std::uint32_t name : program_names_)
        api().delete_program(name);
    release_vertex_arrays();
    if (draw_fbo_ != 0) api().delete_framebuffers(1, &draw_fbo_);
    if (read_fbo_ != 0) api().delete_framebuffers(1, &read_fbo_);
    buffer_names_.clear();
    texture_names_.clear();
    sampler_names_.clear();
    program_names_.clear();
    unlock_context();
}

const AdapterInfo& GlDevice::adapter() const noexcept {
    return adapter_;
}

const DeviceCaps& GlDevice::caps() const noexcept {
    return caps_;
}

FormatSupport GlDevice::format_support(Format format) const {
    switch (format) {
    case Format::kRgba8Unorm:
    case Format::kRgba8UnormSrgb:
        return FormatSupport::kSampled | FormatSupport::kFiltered | FormatSupport::kColorTarget |
            FormatSupport::kBlendable;
    case Format::kD32Float:
    case Format::kD24UnormS8Uint: return FormatSupport::kDepthTarget;
    default: return FormatSupport::kNone;
    }
}

MemoryBudget GlDevice::memory_budget() const {
    MemoryBudget budget;
    budget.used_bytes = used_bytes_;
    budget.budget_bytes = budget_bytes_;
    return budget;
}

DeviceLoss GlDevice::loss() const noexcept {
    return loss_.load(std::memory_order_relaxed);
}

std::uint64_t GlDevice::validation_errors() const noexcept {
    return errors_.load(std::memory_order_relaxed);
}

bool GlDevice::lock_context() {
    mutex_.lock();
    if (context_.make_current()) return true;
    mutex_.unlock();
    return false;
}

void GlDevice::unlock_context() {
    mutex_.unlock();
}

GlFunctions& GlDevice::api() {
    return context_.api();
}

const GlProfile& GlDevice::profile() const noexcept {
    return context_.profile();
}

GlBuffer* GlDevice::buffer(BufferHandle handle) noexcept {
    return buffers_.find(handle);
}

GlTexture* GlDevice::texture(TextureHandle handle) noexcept {
    return textures_.find(handle);
}

GlView* GlDevice::view(TextureViewHandle handle) noexcept {
    return views_.find(handle);
}

GlSampler* GlDevice::sampler(SamplerHandle handle) noexcept {
    return samplers_.find(handle);
}

GlPipeline* GlDevice::pipeline(PipelineHandle handle) noexcept {
    return pipelines_.find(handle);
}

GlGroup* GlDevice::group(BindGroupHandle handle) noexcept {
    return groups_.find(handle);
}

std::uint64_t GlDevice::bytes_used() const noexcept {
    return used_bytes_;
}

void GlDevice::note_recording(int delta) noexcept {
    recording_ += delta;
}

std::uint64_t GlDevice::retire_ticket() const noexcept {
    return recording_ > 0 ? submitted_ + 1 : submitted_;
}

void GlDevice::retire(RetiredKind kind, std::uint32_t name) {
    Retired item;
    item.ticket = retire_ticket();
    item.kind = kind;
    item.name = name;
    retired_.push_back(item);
}

std::uint32_t GlDevice::push_buffer() {
    const std::uint32_t index = push_index_;
    if (push_names_.at(index) != 0) return push_names_.at(index);
    std::uint32_t name = 0;
    api().gen_buffers(1, &name);
    api().bind_buffer(GL_UNIFORM_BUFFER, name);
    const std::uint32_t flags = GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT;
    const bool is_persistent = api().buffer_storage != nullptr;
    if (is_persistent) {
        api().buffer_storage(GL_UNIFORM_BUFFER, static_cast<std::intptr_t>(kPushBytes), nullptr, flags);
        push_mapped_.at(index) =
            api().map_buffer_range(GL_UNIFORM_BUFFER, 0, static_cast<std::intptr_t>(kPushBytes), flags);
    }
    if (push_mapped_.at(index) == nullptr) {
        api().buffer_data(GL_UNIFORM_BUFFER, kPushBytes, nullptr, GL_DYNAMIC_DRAW);
    }
    push_names_.at(index) = name;
    buffer_names_.push_back(name);
    return name;
}

// Vùng đẩy giữ map suốt đời: glBufferSubData trên driver này xin một vùng bộ nhớ thiết bị mới cho MỖI
// lần gọi (đo trên GE8320: 1,7 ms mỗi lệnh vẽ, cả khung 48 ms), còn ghi vào vùng đã map chỉ là memcpy.
// Buffer map nhất quán phải dựng bằng buffer_storage (bất biến) nên không xả kiểu glBufferData được:
// thay vào đó xoay vòng nhiều vùng, khung sau không ghi đè vùng GPU còn đang đọc.
void GlDevice::reset_push() {
    push_index_ = (push_index_ + 1) % kPushBuffers;
    push_cursor_ = 0;
    (void)push_buffer();
}

std::uint32_t GlDevice::push_range(std::span<const std::byte> data) {
    const std::uint32_t name = push_buffer();
    if (push_cursor_ + kUniformAlignment > kPushBytes) reset_push();
    const std::uint32_t offset = push_cursor_;
    void* mapped = push_mapped_.at(push_index_);
    if (mapped != nullptr) {
        std::memcpy(static_cast<std::byte*>(mapped) + offset, data.data(), data.size());
    } else {
        api().bind_buffer(GL_UNIFORM_BUFFER, name);
        api().buffer_sub_data(GL_UNIFORM_BUFFER, static_cast<std::intptr_t>(offset),
            static_cast<std::intptr_t>(data.size()), data.data());
    }
    push_cursor_ += kUniformAlignment;
    return offset;
}

void GlDevice::unmap_push() {
    for (std::size_t index = 0; index < push_names_.size(); ++index) {
        if (push_mapped_.at(index) == nullptr) continue;
        api().bind_buffer(GL_UNIFORM_BUFFER, push_names_.at(index));
        api().unmap_buffer(GL_UNIFORM_BUFFER);
        push_mapped_.at(index) = nullptr;
    }
}

namespace {

// Một thuộc tính đỉnh của VAO: bật ô và trỏ vào buffer đang gắn, đúng kiểu số nguyên hay số thực.
void set_attribute(GlFunctions& api, const GlAttribute& attribute, int stride, std::uint64_t offset) {
    const AttribLayout layout = layout_of(attribute.format);
    const auto pointer = reinterpret_cast<const void*>(static_cast<std::uintptr_t>(offset + attribute.offset));
    api.enable_attrib(attribute.location);
    if (layout.is_integer) {
        api.attrib_ipointer(attribute.location, layout.components, layout.type, stride, pointer);
        return;
    }
    api.attrib_pointer(attribute.location, layout.components, layout.type, GL_FALSE, stride, pointer);
}

} // namespace

std::uint32_t GlDevice::vertex_array_for(VertexKey key) {
    for (const VertexArray& entry : vertex_arrays_) {
        if (entry.key == key) return entry.name;
    }
    GlPipeline* pipeline = this->pipeline(key.pipeline);
    GlBuffer* vertices = buffer(key.vertices);
    if (pipeline == nullptr || vertices == nullptr) return 0;
    std::uint32_t name = 0;
    api().gen_vertex_arrays(1, &name);
    api().bind_vertex_array(name);
    api().bind_buffer(GL_ARRAY_BUFFER, vertices->name);
    const auto stride = static_cast<int>(pipeline->stride);
    for (const GlAttribute& attribute : pipeline->attributes) {
        set_attribute(api(), attribute, stride, key.vertex_offset);
    }
    vertex_arrays_.push_back({.key = key, .name = name});
    return name;
}

std::uint32_t GlDevice::draw_framebuffer() {
    if (draw_fbo_ == 0) api().gen_framebuffers(1, &draw_fbo_);
    return draw_fbo_;
}

std::uint32_t GlDevice::read_framebuffer() {
    if (read_fbo_ == 0) api().gen_framebuffers(1, &read_fbo_);
    return read_fbo_;
}

void GlDevice::remember_binary(ProgramBinary binary) {
    for (ProgramBinary& item : binaries_) {
        if (item.hash != binary.hash) continue;
        item = std::move(binary);
        return;
    }
    binaries_.push_back(std::move(binary));
}

const ProgramBinary* GlDevice::find_binary(std::uint64_t hash) const noexcept {
    for (const ProgramBinary& item : binaries_) {
        if (item.hash == hash) return &item;
    }
    return nullptr;
}

void GlDevice::poll_fences() {
    std::uint64_t done = submitted_;
    std::vector<PendingFence> pending;
    for (PendingFence& fence : fences_) {
        if (fence.sync == nullptr) continue;
        const std::uint32_t state = api().client_wait(fence.sync, 0, 0);
        const bool signaled = state == GL_ALREADY_SIGNALED || state == GL_CONDITION_SATISFIED;
        if (!signaled) {
            if (fence.ticket != 0 && fence.ticket - 1 < done) done = fence.ticket - 1;
            pending.push_back(fence);
            continue;
        }
        api().delete_sync(fence.sync);
    }
    fences_.swap(pending);
    if (done > completed_) completed_ = done;
}

void GlDevice::release_retired(std::uint64_t done) {
    std::vector<Retired> kept;
    bool released = false;
    for (const Retired& item : retired_) {
        if (item.ticket > done) {
            kept.push_back(item);
            continue;
        }
        released = true;
        if (item.kind == RetiredKind::kBuffer) {
            api().delete_buffers(1, &item.name);
            erase_name(buffer_names_, item.name);
        } else if (item.kind == RetiredKind::kTexture) {
            api().delete_textures(1, &item.name);
            erase_name(texture_names_, item.name);
        } else if (item.kind == RetiredKind::kSampler) {
            api().delete_samplers(1, &item.name);
            erase_name(sampler_names_, item.name);
        } else if (item.kind == RetiredKind::kProgram) {
            api().delete_program(item.name);
            erase_name(program_names_, item.name);
        }
    }
    retired_.swap(kept);
    if (released) release_vertex_arrays();
}

void GlDevice::release_vertex_arrays() {
    for (const VertexArray& entry : vertex_arrays_) {
        std::uint32_t name = entry.name;
        api().delete_vertex_arrays(1, &name);
    }
    vertex_arrays_.clear();
    invalidate_draw_cache();
}

void GlDevice::invalidate_draw_cache() noexcept {
    draw_cache_.has_pipeline = false;
    draw_cache_.pipeline = {};
    draw_cache_.buffers.clear();
    draw_cache_.textures.clear();
    draw_cache_.samplers.clear();
    draw_cache_.has_push = false;
    draw_cache_.has_vertices = false;
}

void GlDevice::release_all() {}

Result<BufferHandle> GlDevice::create_buffer(const BufferDesc& desc) {
    const core::Status checked = check_buffer(desc);
    if (!checked) return std::unexpected(checked.error());
    if (!lock_context()) return fail(ErrorCode::kUnsupported, "context GL không current");
    GlBuffer created;
    created.size = desc.size;
    created.usage = desc.usage;
    created.memory = desc.memory;
    api().gen_buffers(1, &created.name);
    api().bind_buffer(GL_ARRAY_BUFFER, created.name);
    const bool can_map = api().buffer_storage != nullptr && desc.memory != MemoryDomain::kDevice;
    if (can_map && desc.memory == MemoryDomain::kUpload) {
        const std::uint32_t flags = GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT;
        api().buffer_storage(GL_ARRAY_BUFFER, static_cast<std::intptr_t>(desc.size), nullptr, flags);
        created.mapped = api().map_buffer_range(GL_ARRAY_BUFFER, 0, static_cast<std::intptr_t>(desc.size), flags);
    } else if (can_map) {
        const std::uint32_t flags = GL_MAP_READ_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT;
        api().buffer_storage(GL_ARRAY_BUFFER, static_cast<std::intptr_t>(desc.size), nullptr, flags);
        created.mapped = api().map_buffer_range(GL_ARRAY_BUFFER, 0, static_cast<std::intptr_t>(desc.size), flags);
    } else {
        const std::uint32_t usage = desc.memory == MemoryDomain::kUpload ? GL_DYNAMIC_DRAW
            : desc.memory == MemoryDomain::kReadback                     ? GL_STREAM_READ
                                                                         : GL_STATIC_DRAW;
        api().buffer_data(GL_ARRAY_BUFFER, static_cast<std::intptr_t>(desc.size), nullptr, usage);
    }
    buffer_names_.push_back(created.name);
    used_bytes_ += desc.size;
    const BufferHandle handle = buffers_.insert(std::move(created));
    unlock_context();
    if (!handle) return fail(ErrorCode::kOutOfMemory, "hết chỗ bảng buffer GL");
    return handle;
}

Status GlDevice::write_buffer(BufferHandle handle, std::uint64_t offset, std::span<const std::byte> data) {
    GlBuffer* buffer = buffers_.find(handle);
    if (buffer == nullptr) return fail(kBad, "write_buffer: tay nắm chết");
    if (buffer->memory != MemoryDomain::kUpload) return fail(kBad, "write_buffer chỉ nhận Upload");
    const core::Status span = check_span(buffer->size, offset, data.size());
    if (!span) return span;
    if (!lock_context()) return fail(ErrorCode::kUnsupported, "context GL không current");
    if (buffer->mapped != nullptr) {
        auto* destination = static_cast<std::byte*>(buffer->mapped) + offset;
        std::memcpy(destination, data.data(), data.size());
    } else {
        api().bind_buffer(GL_ARRAY_BUFFER, buffer->name);
        api().buffer_sub_data(GL_ARRAY_BUFFER, static_cast<std::intptr_t>(offset),
            static_cast<std::intptr_t>(data.size()), data.data());
    }
    unlock_context();
    return ok();
}

Status GlDevice::read_buffer(BufferHandle handle, std::uint64_t offset, std::span<std::byte> out) {
    GlBuffer* buffer = buffers_.find(handle);
    if (buffer == nullptr) return fail(kBad, "read_buffer: tay nắm chết");
    if (buffer->memory != MemoryDomain::kReadback) return fail(kBad, "read_buffer chỉ nhận Readback");
    const core::Status span = check_span(buffer->size, offset, out.size());
    if (!span) return span;
    if (!lock_context()) return fail(ErrorCode::kUnsupported, "context GL không current");
    if (buffer->mapped != nullptr) {
        const auto* source = static_cast<const std::byte*>(buffer->mapped) + offset;
        std::memcpy(out.data(), source, out.size());
    } else {
        api().bind_buffer(GL_COPY_READ_BUFFER, buffer->name);
        void* mapped = api().map_buffer_range(GL_COPY_READ_BUFFER, static_cast<std::intptr_t>(offset),
            static_cast<std::intptr_t>(out.size()), GL_MAP_READ_BIT);
        if (mapped == nullptr) {
            unlock_context();
            return fail(ErrorCode::kInvalidState, "không map được buffer đọc");
        }
        std::memcpy(out.data(), mapped, out.size());
        api().unmap_buffer(GL_COPY_READ_BUFFER);
    }
    unlock_context();
    return ok();
}

void GlDevice::destroy(BufferHandle handle) {
    std::optional<GlBuffer> taken = buffers_.remove(handle);
    if (!taken) return;
    if (used_bytes_ >= taken->size) used_bytes_ -= taken->size;
    retire(RetiredKind::kBuffer, taken->name);
}

void GlDevice::destroy(TextureHandle handle) {
    std::optional<GlTexture> taken = textures_.remove(handle);
    if (!taken) return;
    retire(RetiredKind::kTexture, taken->name);
}

void GlDevice::destroy(TextureViewHandle handle) {
    const std::optional<GlView> dropped_view = views_.remove(handle);
    (void)dropped_view;
}

void GlDevice::destroy(SamplerHandle handle) {
    std::optional<GlSampler> taken = samplers_.remove(handle);
    if (!taken) return;
    retire(RetiredKind::kSampler, taken->name);
}

void GlDevice::destroy(ShaderHandle handle) {
    const std::optional<GlShader> dropped_shader = shaders_.remove(handle);
    (void)dropped_shader;
}

void GlDevice::destroy(PipelineHandle handle) {
    std::optional<GlPipeline> taken = pipelines_.remove(handle);
    if (!taken) return;
    retire(RetiredKind::kProgram, taken->program);
}

void GlDevice::destroy(BindGroupHandle handle) {
    const std::optional<GlGroup> dropped_group = groups_.remove(handle);
    (void)dropped_group;
}

void GlDevice::destroy(QueryPoolHandle) {}

std::uint64_t GlDevice::address(BufferHandle) const {
    return 0;
}

Status GlDevice::read_queries(QueryPoolHandle, std::uint32_t, std::span<std::uint64_t>) {
    return fail(ErrorCode::kUnsupported, "query GLES chưa nối");
}

Result<QueryPoolHandle> GlDevice::create_query_pool(const QueryPoolDesc&) {
    return fail(ErrorCode::kUnsupported, "query GLES chưa nối");
}

Result<std::unique_ptr<Timeline>> GlDevice::create_timeline(std::uint64_t initial) {
    return std::make_unique<GlTimeline>(initial);
}

Result<CommandList*> GlDevice::begin_commands(QueueType queue) {
    if (queue != QueueType::kGraphics) {
        return fail(ErrorCode::kUnsupported, "GLES chỉ có hàng graphics");
    }
    if (!lock_context()) return fail(ErrorCode::kUnsupported, "context GL không current");
    GlCommands* list = nullptr;
    for (const std::unique_ptr<GlCommands>& item : lists_) {
        if (!item->is_open()) list = item.get();
    }
    if (list == nullptr) {
        lists_.push_back(std::make_unique<GlCommands>(*this, queue));
        list = lists_.back().get();
    }
    list->reset(queue);
    reset_push();
    note_recording(1);
    return list;
}

Status GlDevice::submit(QueueType queue, const SubmitDesc& desc) {
    if (queue != QueueType::kGraphics) return fail(ErrorCode::kUnsupported, "GLES chỉ có hàng graphics");
    int opened = 0;
    for (CommandList* list : desc.lists) {
        auto* commands = dynamic_cast<GlCommands*>(list);
        if (commands == nullptr) return fail(kBad, "submit: danh sách lệnh lạ");
        ++opened;
        const core::Status error = commands->take_error();
        if (!error) {
            note_recording(-opened);
            for (int index = 0; index < opened; ++index)
                unlock_context();
            return error;
        }
    }
    ++submitted_;
    PendingFence fence;
    fence.sync = api().fence_sync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);
    fence.ticket = submitted_;
    fences_.push_back(fence);
    for (const SubmitSignal& signal : desc.signals) {
        if (signal.timeline != nullptr) signal.timeline->signal(signal.value);
    }
    note_recording(-opened);
    for (int index = 0; index < opened; ++index)
        unlock_context();
    return ok();
}

Status GlDevice::wait_idle() {
    if (!lock_context()) return fail(ErrorCode::kUnsupported, "context GL không current");
    for (const PendingFence& fence : fences_) {
        if (fence.sync != nullptr) api().client_wait(fence.sync, 0, GL_TIMEOUT_IGNORED);
    }
    poll_fences();
    release_retired(submitted_);
    unlock_context();
    return ok();
}

Status GlDevice::end_frame() {
    int leftover = 0;
    for (const std::unique_ptr<GlCommands>& list : lists_) {
        if (list->is_open()) ++leftover;
    }
    for (const std::unique_ptr<GlCommands>& list : lists_) {
        if (!list->is_open()) continue;
        const core::Status ignored = list->take_error();
        (void)ignored;
    }
    if (leftover > 0) {
        note_recording(-leftover);
        for (int index = 0; index < leftover; ++index)
            unlock_context();
    }
    if (!lock_context()) return fail(ErrorCode::kUnsupported, "context GL không current");
    poll_fences();
    release_retired(completed_);
    unlock_context();
    if (loss() != DeviceLoss::kNone) return fail(ErrorCode::kDeviceLost, "mất thiết bị GL");
    return ok();
}

std::vector<std::byte> GlDevice::pipeline_cache() const {
    std::vector<std::byte> bytes;
    const auto put = [&bytes](const void* data, std::size_t size) {
        const auto* raw = static_cast<const std::byte*>(data);
        bytes.insert(bytes.end(), raw, raw + size);
    };
    const std::uint32_t magic = 0x314C4747U;
    const std::uint32_t version = 1;
    const auto count = static_cast<std::uint32_t>(binaries_.size());
    put(&magic, sizeof(magic));
    put(&version, sizeof(version));
    put(&count, sizeof(count));
    for (const ProgramBinary& binary : binaries_) {
        const auto size = static_cast<std::uint32_t>(binary.bytes.size());
        put(&binary.hash, sizeof(binary.hash));
        put(&binary.format, sizeof(binary.format));
        put(&size, sizeof(size));
        put(binary.bytes.data(), binary.bytes.size());
    }
    return bytes;
}

Result<std::vector<AdapterInfo>> adapters() {
    core::Result<GlContext> context = open_context(false);
    if (!context) return std::unexpected(context.error());
    AdapterInfo info;
    info.name = std::string(context->renderer());
    info.backend = Backend::kGles;
    info.driver = std::string(context->driver());
    info.is_discrete = context->profile().is_discrete;
    info.is_software = context->profile().is_software;
    std::vector<AdapterInfo> list;
    list.push_back(std::move(info));
    return list;
}

Result<std::unique_ptr<Device>> create(const DeviceDesc& desc) {
    core::Result<GlContext> context = open_context(desc.is_validated);
    if (!context) return std::unexpected(context.error());
    const GlProfile& profile = context->profile();
    AdapterInfo info;
    info.name = std::string(context->renderer());
    info.backend = Backend::kGles;
    info.driver = std::string(context->driver());
    info.is_discrete = profile.is_discrete;
    info.is_software = profile.is_software;
    DeviceCaps caps;
    caps.independent_blend = true;
    caps.precise_occlusion = false;
    caps.has_queue[static_cast<std::size_t>(QueueType::kGraphics)] = true;
    caps.max_texture_size = profile.max_texture;
    caps.max_anisotropy = profile.max_anisotropy == 0 ? 1 : profile.max_anisotropy;
    auto device = std::make_unique<GlDevice>(std::move(*context), std::move(info), caps, desc.is_validated);
    if (desc.adapter && *desc.adapter != 0) {
        return fail(kBad, "GLES chỉ thấy một context của process");
    }
    return device;
}

} // namespace game::gpu::gles
