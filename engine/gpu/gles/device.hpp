// Thiết bị OpenGL 4.3 / OpenGL ES 3.1 cài gpu::Device. Một context, một mutex: ghi lệnh ở CPU,
// thực thi trên context lúc submit. Huỷ tài nguyên là hoãn theo ticket của lần nộp.
// Thiết bị màu thô: backend này không dùng phép đổi sRGB nào của phần cứng. Định dạng khai sRGB cất
// là RGBA8 thường, nên lấy mẫu, lọc, trộn, ghi và chép đều làm trên số đã mã hoá, như bộ vẽ D3D9
// của game gốc. Shader GLSL vì thế tính thẳng công thức gamma, không tự đổi màu; màu xoá vẫn nhận
// số tuyến tính như backend khác và được mã hoá ở CPU. Lý do (đo trên PowerVR GE8320, 1280 x 800):
// pow ở từng điểm ảnh làm khung tụt từ 16,7 xuống 33 ms, và bật tắt GL_FRAMEBUFFER_SRGB giữa lượt
// vẽ tốn khoảng 4 ms mỗi khung.
#pragma once

#include "gpu/device.hpp"
#include "gpu/gles/bind_map.hpp"
#include "gpu/gles/context.hpp"
#include "gpu/slots.hpp"

#include <array>
#include <atomic>
#include <cstdint>
#include <mutex>
#include <string>
#include <vector>

namespace game::gpu::gles {

class GlCommands;

// Số vùng đẩy xoay vòng: mỗi lần bắt đầu danh sách lệnh lấy một vùng, khung sau không ghi đè vùng
// mà GPU có thể còn đang đọc. Một vùng chứa 512 khối hằng đẩy.
inline constexpr std::uint32_t kPushBuffers = 16;

struct GlBuffer {
    std::uint32_t name = 0;
    std::uint64_t size = 0;
    BufferUsage usage = BufferUsage::kNone;
    MemoryDomain memory = MemoryDomain::kDevice;
    void* mapped = nullptr;
};

struct GlTexture {
    std::uint32_t name = 0;
    TextureKind kind = TextureKind::kTex2D;
    Format format = Format::kUnknown;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::uint32_t layers = 1;
    std::uint32_t mips = 1;
    std::uint32_t samples = 1;
    TextureUsage usage = TextureUsage::kNone;
    bool srgb = false;
    // Đích màu: hàng 0 của RHI là đỉnh ảnh, GL để đỉnh ở toạ độ y cao. Đọc ngược phải lật.
    bool is_target = false;
    std::uint32_t target = 0;
};

struct GlView {
    TextureHandle texture{};
    std::uint32_t name = 0;
    std::uint32_t target = 0;
    Format format = Format::kUnknown;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::uint32_t samples = 1;
    bool srgb = false;
    bool is_target = false;
    bool has_depth = false;
};

struct GlSampler {
    std::uint32_t name = 0;
};

struct GlShader {
    shader::Stage stage = shader::Stage::kVertex;
    std::string source;
    shader::StageReflection reflection;
};

struct GlAttribute {
    std::uint32_t location = 0;
    Format format = Format::kUnknown;
    std::uint32_t offset = 0;
};

// Khuôn một thuộc tính đỉnh theo định dạng của RHI: số thành phần, kiểu GL, và có phải gắn bằng
// glVertexAttribIPointer (thuộc tính số nguyên) hay không.
struct AttribLayout {
    int components = 0;
    std::uint32_t type = GL_FLOAT;
    bool is_integer = false;
};

[[nodiscard]] constexpr AttribLayout layout_of(Format format) noexcept {
    switch (format) {
    case Format::kRg32Float: return {.components = 2, .type = GL_FLOAT, .is_integer = false};
    case Format::kRgb32Float: return {.components = 3, .type = GL_FLOAT, .is_integer = false};
    case Format::kRgba32Float: return {.components = 4, .type = GL_FLOAT, .is_integer = false};
    case Format::kRgba16Uint: return {.components = 4, .type = GL_UNSIGNED_SHORT, .is_integer = true};
    case Format::kR32Uint: return {.components = 1, .type = GL_UNSIGNED_INT, .is_integer = true};
    default: return {};
    }
}

// Khóa nhận dạng một VAO: khuôn thuộc tính đến từ pipeline, vị trí dữ liệu từ buffer đỉnh (kèm độ
// lệch) và buffer chỉ số, vì cả ba đều là trạng thái nằm trong VAO của GLES.
struct VertexKey {
    PipelineHandle pipeline{};
    BufferHandle vertices{};
    std::uint64_t vertex_offset = 0;
    BufferHandle indices{};

    friend bool operator==(const VertexKey&, const VertexKey&) = default;
};

struct VertexArray {
    VertexKey key{};
    std::uint32_t name = 0;
};

// Trạng thái vẽ đã áp lên context GL, để lệnh vẽ sau chỉ gọi hàm GL khi giá trị đổi. GLES của
// PowerVR tính hàng chục micro giây cho mỗi lời gọi trạng thái — glVertexAttribPointer, glUseProgram
// và glBindBufferRange đắt nhất — nên cảnh chỉ có vài trạng thái khác nhau vẫn tốn hàng nghìn lời
// gọi mỗi khung: đo trên GE8320 (map huoyangu, 78 lệnh vẽ) là 48,75 ms mỗi khung.
struct GlDrawCache {
    // false nghĩa là không biết context đang ở trạng thái nào: mọi thứ phải áp lại.
    bool has_pipeline = false;
    PipelineHandle pipeline{};

    // Dải buffer đã gắn theo chỉ số (glBindBufferRange).
    struct BufferSlot {
        std::uint32_t target = 0;
        std::uint32_t index = 0;
        std::uint32_t name = 0;
        std::uint64_t offset = 0;
        std::uint64_t size = 0;
    };
    std::vector<BufferSlot> buffers;

    // Ảnh và sampler đã gắn theo đơn vị texture.
    struct UnitSlot {
        std::uint32_t index = 0;
        std::uint32_t name = 0;
        std::uint32_t target = 0;
    };
    std::vector<UnitSlot> textures;
    std::vector<UnitSlot> samplers;

    // Khối hằng đẩy đang gắn: vùng trong buffer đẩy.
    bool has_push = false;
    std::uint32_t push_index = 0;
    std::uint32_t push_name = 0;
    std::uint64_t push_offset = 0;

    // Hình học đang gắn: VAO và buffer chỉ số của nó.
    bool has_vertices = false;
    VertexKey vertices{};
};

struct GlPipeline {
    std::uint32_t program = 0;
    bool is_compute = false;
    BindMap bindings;
    std::uint32_t stride = 0;
    std::vector<GlAttribute> attributes;
    CullMode cull = CullMode::kBack;
    FrontFace front = FrontFace::kCounterClockwise;
    bool depth_test = false;
    bool depth_write = false;
    CompareOp depth_compare = CompareOp::kGreaterOrEqual;
    bool blend = false;
    BlendState blend_state{};
    Topology topology = Topology::kTriangleList;
    bool alpha_to_coverage = false;
    float depth_bias = 0.0F;
    float depth_slope = 0.0F;
    // Vị trí của uniform "tl_push" (mảng uvec4 chứa khối hằng đẩy); âm khi shader không khai.
    int push_location = -1;
};

struct GlBinding {
    shader::RegisterType type = shader::RegisterType::kConstant;
    std::uint32_t slot = 0;
    Bound resource;
};

struct GlGroup {
    std::uint32_t space = 0;
    std::vector<GlBinding> bindings;
};

enum class RetiredKind : std::uint8_t { kBuffer, kTexture, kSampler, kProgram };

struct Retired {
    std::uint64_t ticket = 0;
    RetiredKind kind = RetiredKind::kBuffer;
    std::uint32_t name = 0;
};

struct PendingFence {
    Sync sync = nullptr;
    std::uint64_t ticket = 0;
};

struct ProgramBinary {
    std::uint64_t hash = 0;
    std::uint32_t format = 0;
    std::vector<std::byte> bytes;
};

class GlDevice final : public Device {
public:
    GlDevice(GlContext context, AdapterInfo adapter, DeviceCaps caps, bool validated);
    ~GlDevice() override;

    [[nodiscard]] const AdapterInfo& adapter() const noexcept override;
    [[nodiscard]] const DeviceCaps& caps() const noexcept override;
    [[nodiscard]] FormatSupport format_support(Format format) const override;
    [[nodiscard]] MemoryBudget memory_budget() const override;
    [[nodiscard]] DeviceLoss loss() const noexcept override;
    [[nodiscard]] std::uint64_t validation_errors() const noexcept override;

    [[nodiscard]] Result<BufferHandle> create_buffer(const BufferDesc& desc) override;
    [[nodiscard]] Result<TextureHandle> create_texture(const TextureDesc& desc) override;
    [[nodiscard]] Result<TextureViewHandle> create_view(const TextureViewDesc& desc) override;
    [[nodiscard]] Result<SamplerHandle> create_sampler(const SamplerDesc& desc) override;
    [[nodiscard]] Result<ShaderHandle> create_shader(const ShaderDesc& desc) override;
    [[nodiscard]] Result<PipelineHandle> create_pipeline(const GraphicsPipelineDesc& desc) override;
    [[nodiscard]] Result<PipelineHandle> create_pipeline(const ComputePipelineDesc& desc) override;
    [[nodiscard]] Result<BindGroupHandle> create_bind_group(const BindGroupDesc& desc) override;
    [[nodiscard]] Result<QueryPoolHandle> create_query_pool(const QueryPoolDesc& desc) override;
    [[nodiscard]] Status update_bind_group(BindGroupHandle group, std::span<const BindEntry> entries) override;

    void destroy(BufferHandle handle) override;
    void destroy(TextureHandle handle) override;
    void destroy(TextureViewHandle handle) override;
    void destroy(SamplerHandle handle) override;
    void destroy(ShaderHandle handle) override;
    void destroy(PipelineHandle handle) override;
    void destroy(BindGroupHandle handle) override;
    void destroy(QueryPoolHandle handle) override;

    [[nodiscard]] std::uint64_t address(BufferHandle handle) const override;
    [[nodiscard]] Status write_buffer(BufferHandle handle, std::uint64_t offset,
        std::span<const std::byte> data) override;
    [[nodiscard]] Status read_buffer(BufferHandle handle, std::uint64_t offset, std::span<std::byte> out) override;
    [[nodiscard]] Status read_queries(QueryPoolHandle pool, std::uint32_t first, std::span<std::uint64_t> out) override;

    [[nodiscard]] Result<std::unique_ptr<Timeline>> create_timeline(std::uint64_t initial) override;
    [[nodiscard]] Result<std::unique_ptr<Swapchain>> create_swapchain(const SwapchainDesc& desc) override;
    [[nodiscard]] Result<CommandList*> begin_commands(QueueType queue) override;
    [[nodiscard]] Status submit(QueueType queue, const SubmitDesc& desc) override;
    [[nodiscard]] Status wait_idle() override;
    [[nodiscard]] Status end_frame() override;
    [[nodiscard]] std::vector<std::byte> pipeline_cache() const override;

    [[nodiscard]] GlFunctions& api();
    [[nodiscard]] const GlProfile& profile() const noexcept;
    [[nodiscard]] bool lock_context();
    void unlock_context();
    [[nodiscard]] GlBuffer* buffer(BufferHandle handle) noexcept;
    [[nodiscard]] GlTexture* texture(TextureHandle handle) noexcept;
    [[nodiscard]] GlView* view(TextureViewHandle handle) noexcept;
    [[nodiscard]] GlSampler* sampler(SamplerHandle handle) noexcept;
    [[nodiscard]] GlPipeline* pipeline(PipelineHandle handle) noexcept;
    [[nodiscard]] GlGroup* group(BindGroupHandle handle) noexcept;
    [[nodiscard]] std::uint32_t push_buffer();
    [[nodiscard]] std::uint32_t draw_framebuffer();
    [[nodiscard]] std::uint32_t read_framebuffer();
    // Trạng thái vẽ đã áp lên context; draw_common đọc và ghi, mọi chỗ khác đụng trạng thái GL thì
    // gọi invalidate_draw_cache.
    [[nodiscard]] GlDrawCache& draw_cache() noexcept { return draw_cache_; }
    void invalidate_draw_cache() noexcept;
    // VAO của một cặp (pipeline, buffer đỉnh, buffer chỉ số): dựng lần đầu rồi gắn lại, khỏi gọi
    // glVertexAttribPointer mỗi lệnh vẽ. 0 khi pipeline hoặc buffer đã chết.
    [[nodiscard]] std::uint32_t vertex_array_for(VertexKey key);
    void context_swap();
    void reset_push();
    [[nodiscard]] std::uint32_t push_range(std::span<const std::byte> data);
    // Bỏ map mọi vùng đẩy trước khi xoá buffer.
    void unmap_push();
    void retire(RetiredKind kind, std::uint32_t name);
    void note_recording(int delta) noexcept;
    [[nodiscard]] std::uint64_t bytes_used() const noexcept;
    void remember_binary(ProgramBinary binary);
    [[nodiscard]] const ProgramBinary* find_binary(std::uint64_t hash) const noexcept;

private:
    [[nodiscard]] std::uint64_t retire_ticket() const noexcept;
    void poll_fences();
    void release_retired(std::uint64_t done);
    void release_all();
    // Bỏ mọi VAO đã nhớ: chúng giữ tên buffer đỉnh, mà tên ấy được cấp lại sau khi buffer bị xoá.
    void release_vertex_arrays();

    GlContext context_;
    AdapterInfo adapter_;
    DeviceCaps caps_;
    // Đệ quy: begin_commands giữ khoá suốt lần ghi, write_buffer giữa khung khoá lại cùng luồng.
    mutable std::recursive_mutex mutex_;
    std::atomic<std::uint64_t> errors_{0};
    std::atomic<DeviceLoss> loss_{DeviceLoss::kNone};
    std::uint64_t submitted_ = 0;
    std::uint64_t completed_ = 0;
    int recording_ = 0;
    std::uint64_t used_bytes_ = 0;
    std::uint32_t push_cursor_ = 0;
    std::uint32_t push_index_ = 0;
    std::array<std::uint32_t, kPushBuffers> push_names_{};
    std::array<void*, kPushBuffers> push_mapped_{};
    std::uint32_t draw_fbo_ = 0;
    std::uint32_t read_fbo_ = 0;
    GlDrawCache draw_cache_;
    std::vector<VertexArray> vertex_arrays_;
    std::uint64_t budget_bytes_ = 0;
    Slots<GlBuffer, BufferTag> buffers_;
    Slots<GlTexture, TextureTag> textures_;
    Slots<GlView, TextureViewTag> views_;
    Slots<GlSampler, SamplerTag> samplers_;
    Slots<GlShader, ShaderTag> shaders_;
    Slots<GlPipeline, PipelineTag> pipelines_;
    Slots<GlGroup, BindGroupTag> groups_;
    std::vector<std::unique_ptr<GlCommands>> lists_;
    std::vector<Retired> retired_;
    std::vector<std::uint32_t> buffer_names_;
    std::vector<std::uint32_t> texture_names_;
    std::vector<std::uint32_t> sampler_names_;
    std::vector<std::uint32_t> program_names_;
    std::vector<PendingFence> fences_;
    std::vector<ProgramBinary> binaries_;
};

[[nodiscard]] Result<std::vector<AdapterInfo>> adapters();
[[nodiscard]] Result<std::unique_ptr<Device>> create(const DeviceDesc& desc);

} // namespace game::gpu::gles
