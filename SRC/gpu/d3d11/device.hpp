// Thiết bị D3D11: cài gpu::Device cho máy không chạy được Vulkan hoặc D3D12. Một immediate context
// dưới mutex; mỗi danh sách lệnh là deferred context để nhiều luồng ghi song song. Buffer upload
// dạng constant hoặc structured dùng USAGE_DYNAMIC và MAP_WRITE_DISCARD. Mesh shader và ray tracing
// trả Unsupported. Đối chiếu feature level và swapchain với bgfx renderer_d3d11. Khác gốc: không
// chép file đó vì nó không cài gpu::Device.
#pragma once

#include "core/win32.hpp" // IWYU pragma: keep
#include "gpu/check.hpp"
#include "gpu/device.hpp"
#include "gpu/layout.hpp"
#include "gpu/slots.hpp"

#include <d3d11.h>
#include <d3d11sdklayers.h>
#include <dxgi1_6.h>
#include <wrl/client.h>

#include <array>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <memory>
#include <mutex>
#include <optional>
#include <span>
#include <vector>

namespace game::gpu::d3d11 {

class Commands;

// Khoá immediate context. Mọi Map, Execute và Present đi qua đây.
class ImmediateGuard {
public:
    ImmediateGuard(std::mutex& mutex, ID3D11DeviceContext& context);
    ImmediateGuard(ImmediateGuard&& other) noexcept;
    ~ImmediateGuard();
    ImmediateGuard(const ImmediateGuard&) = delete;
    ImmediateGuard& operator=(const ImmediateGuard&) = delete;
    ImmediateGuard& operator=(ImmediateGuard&&) = delete;

    [[nodiscard]] ID3D11DeviceContext& context() noexcept { return *context_; }

private:
    std::unique_lock<std::mutex> lock_;
    ID3D11DeviceContext* context_;
};

struct Buffer {
    Microsoft::WRL::ComPtr<ID3D11Buffer> resource;
    std::vector<std::byte> shadow;
    std::uint64_t size = 0;
    std::uint32_t stride = 0;
    BufferUsage usage = BufferUsage::kNone;
    MemoryDomain domain = MemoryDomain::kDevice;
    D3D11_USAGE heap = D3D11_USAGE_DEFAULT;
    bool is_structured = false;
};

struct Texture {
    Microsoft::WRL::ComPtr<ID3D11Resource> resource;
    Format format = Format::kUnknown;
    TextureKind kind = TextureKind::kTex2D;
    TextureUsage usage = TextureUsage::kNone;
    std::uint32_t width = 0;
    std::uint32_t height = 1;
    std::uint32_t depth_or_layers = 1;
    std::uint32_t mip_levels = 1;
    std::uint32_t samples = 1;
    // false: ảnh swapchain, thả khi resize sau khi GPU đã rỗi.
    bool is_owned = true;
};

// Mô tả thuần để gọi check.hpp. name để trống vì không giữ chuỗi.
[[nodiscard]] inline TextureDesc texture_of(const Texture& texture) noexcept {
    TextureDesc desc;
    desc.kind = texture.kind;
    desc.format = texture.format;
    desc.width = texture.width;
    desc.height = texture.height;
    desc.depth_or_layers = texture.depth_or_layers;
    desc.mip_levels = texture.mip_levels;
    desc.samples = texture.samples;
    desc.usage = texture.usage;
    return desc;
}

struct View {
    Microsoft::WRL::ComPtr<ID3D11ShaderResourceView> srv;
    Microsoft::WRL::ComPtr<ID3D11RenderTargetView> rtv;
    Microsoft::WRL::ComPtr<ID3D11DepthStencilView> dsv;
    Microsoft::WRL::ComPtr<ID3D11DepthStencilView> dsv_read;
    Microsoft::WRL::ComPtr<ID3D11UnorderedAccessView> uav;
    TextureHandle texture{};
    Format format = Format::kUnknown;
    ViewAspect aspect = ViewAspect::kAll;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::uint32_t samples = 1;
    std::uint32_t first_mip = 0;
    std::uint32_t mip_count = 1;
    std::uint32_t first_layer = 0;
    std::uint32_t layer_count = 1;
};

struct Sampler {
    Microsoft::WRL::ComPtr<ID3D11SamplerState> state;
};

struct Shader {
    Microsoft::WRL::ComPtr<ID3D11DeviceChild> code;
    std::vector<std::byte> bytes;
    shader::StageReflection reflection{};
};

struct Pipeline {
    ProgramLayout layout{};
    Microsoft::WRL::ComPtr<ID3D11VertexShader> vertex;
    Microsoft::WRL::ComPtr<ID3D11PixelShader> pixel;
    Microsoft::WRL::ComPtr<ID3D11GeometryShader> geometry;
    Microsoft::WRL::ComPtr<ID3D11HullShader> hull;
    Microsoft::WRL::ComPtr<ID3D11DomainShader> domain;
    Microsoft::WRL::ComPtr<ID3D11ComputeShader> compute;
    Microsoft::WRL::ComPtr<ID3D11InputLayout> inputs;
    Microsoft::WRL::ComPtr<ID3D11RasterizerState> raster;
    Microsoft::WRL::ComPtr<ID3D11DepthStencilState> depth;
    Microsoft::WRL::ComPtr<ID3D11BlendState> blend;
    D3D_PRIMITIVE_TOPOLOGY topology = D3D_PRIMITIVE_TOPOLOGY_UNDEFINED;
    std::array<std::uint32_t, kMaxVertexBuffers> strides{};
    bool is_compute = false;
    bool depth_write = true;
};

struct GroupBinding {
    std::uint32_t slot = 0;
    bool in_vertex = false;
    bool in_pixel = false;
    bool in_compute = false;
};

struct GroupBuffer : GroupBinding {
    BufferHandle buffer{};
    Microsoft::WRL::ComPtr<ID3D11ShaderResourceView> srv;
    Microsoft::WRL::ComPtr<ID3D11UnorderedAccessView> uav;
    bool is_uniform = false;
    std::uint64_t offset = 0;
    std::uint32_t bytes = 0;
};

struct GroupView : GroupBinding {
    TextureViewHandle view{};
};

struct GroupSampler : GroupBinding {
    SamplerHandle sampler{};
};

struct BindGroup {
    std::uint32_t space = 0;
    std::vector<GroupBuffer> buffers;
    std::vector<GroupView> views;
    std::vector<GroupSampler> samplers;
};

struct QueryPool {
    std::vector<Microsoft::WRL::ComPtr<ID3D11Query>> queries;
    Microsoft::WRL::ComPtr<ID3D11Query> disjoint;
    QueryKind kind = QueryKind::kTimestamp;
    std::uint32_t count = 0;
    bool disjoint_open = false;
};

// Ảnh swapchain bọc sẵn, không gọi CreateTexture.
struct SwapImage {
    Microsoft::WRL::ComPtr<ID3D11Texture2D> texture;
    Format format = Format::kUnknown;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
};

// Chép texture sang buffer: GPU chép vào ảnh staging, CPU chép nốt khi ticket xong.
struct PendingReadback {
    Microsoft::WRL::ComPtr<ID3D11Resource> staging;
    BufferHandle target{};
    CopyRegion region{};
};

struct TimelineNote {
    Timeline* timeline = nullptr;
    std::uint64_t value = 0;
};

// Một lần nộp: query sự kiện, danh sách lệnh và tín hiệu timeline.
struct GpuWait {
    std::uint64_t ticket = 0;
    Microsoft::WRL::ComPtr<ID3D11Query> event;
    std::vector<Commands*> lists;
    std::vector<TimelineNote> signals;
    std::vector<PendingReadback> readbacks;
};

// Tài nguyên đã thả về mặt tay nắm, huỷ khi GPU xong mọi lệnh đã nộp lúc thả.
struct Retired {
    std::uint64_t done_at = 0;
    Microsoft::WRL::ComPtr<IUnknown> object;
};

class D3d11Device final : public Device {
    friend class Commands;

public:
    D3d11Device() = default;
    ~D3d11Device() override;
    D3d11Device(const D3d11Device&) = delete;
    D3d11Device& operator=(const D3d11Device&) = delete;
    D3d11Device(D3d11Device&&) = delete;
    D3d11Device& operator=(D3d11Device&&) = delete;

    [[nodiscard]] static Result<std::unique_ptr<Device>> open(const DeviceDesc& desc);

    [[nodiscard]] const AdapterInfo& adapter() const noexcept override { return adapter_; }
    [[nodiscard]] const DeviceCaps& caps() const noexcept override { return caps_; }
    [[nodiscard]] FormatSupport format_support(Format format) const override;
    [[nodiscard]] MemoryBudget memory_budget() const override;
    [[nodiscard]] DeviceLoss loss() const noexcept override { return loss_.load(); }
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
    using EntrySpan = std::span<const BindEntry>;
    using U32 = std::uint32_t;
    using ChainResult = Result<std::unique_ptr<Swapchain>>;

    [[nodiscard]] Status update_bind_group(BindGroupHandle group, EntrySpan entries) override;

    void destroy(BufferHandle handle) override;
    void destroy(TextureHandle handle) override;
    void destroy(TextureViewHandle handle) override;
    void destroy(SamplerHandle handle) override;
    void destroy(ShaderHandle handle) override;
    void destroy(PipelineHandle handle) override;
    void destroy(BindGroupHandle handle) override;
    void destroy(QueryPoolHandle handle) override;

    [[nodiscard]] std::uint64_t address(BufferHandle handle) const override;
    using U64 = std::uint64_t;
    using ByteIn = std::span<const std::byte>;
    using ByteOut = std::span<std::byte>;
    using QueryOut = std::span<std::uint64_t>;

    [[nodiscard]] Status write_buffer(BufferHandle handle, U64 offset, ByteIn data) override;
    [[nodiscard]] Status read_buffer(BufferHandle handle, U64 offset, ByteOut out) override;
    [[nodiscard]] Status read_queries(QueryPoolHandle pool, U32 first, QueryOut out) override;

    [[nodiscard]] Result<std::unique_ptr<Timeline>> create_timeline(std::uint64_t initial) override;
    [[nodiscard]] ChainResult create_swapchain(const SwapchainDesc& desc) override;

    [[nodiscard]] Result<CommandList*> begin_commands(QueueType queue) override;
    [[nodiscard]] Status submit(QueueType queue, const SubmitDesc& desc) override;
    [[nodiscard]] Status wait_idle() override;
    [[nodiscard]] Status end_frame() override;
    [[nodiscard]] std::vector<std::byte> pipeline_cache() const override;

    [[nodiscard]] ID3D11Device* device() const noexcept { return device_.Get(); }
    [[nodiscard]] ImmediateGuard lock_immediate();
    [[nodiscard]] std::uint64_t next_fence() noexcept;
    [[nodiscard]] std::uint64_t completed_fence() const noexcept { return completed_.load(std::memory_order_acquire); }
    [[nodiscard]] IDXGIAdapter1* adapter_dxgi() const noexcept { return adapter_dxgi_.Get(); }
    [[nodiscard]] bool allows_tearing() const noexcept { return allows_tearing_; }
    void pump();
    [[nodiscard]] Status wait_until(std::uint64_t ticket, std::chrono::nanoseconds timeout);
    [[nodiscard]] Result<TextureHandle> adopt_swap_image(SwapImage image);

    [[nodiscard]] Buffer* find(BufferHandle handle) noexcept { return buffers_.find(handle); }
    [[nodiscard]] const Buffer* find(BufferHandle handle) const noexcept { return buffers_.find(handle); }
    [[nodiscard]] Texture* find(TextureHandle handle) noexcept { return textures_.find(handle); }
    [[nodiscard]] const Texture* find(TextureHandle handle) const noexcept { return textures_.find(handle); }
    [[nodiscard]] const View* find(TextureViewHandle handle) const noexcept { return views_.find(handle); }
    [[nodiscard]] const Sampler* find(SamplerHandle handle) const noexcept { return samplers_.find(handle); }
    [[nodiscard]] const Shader* find(ShaderHandle handle) const noexcept { return shaders_.find(handle); }
    [[nodiscard]] const Pipeline* find(PipelineHandle handle) const noexcept { return pipelines_.find(handle); }
    [[nodiscard]] BindGroup* find(BindGroupHandle handle) noexcept { return groups_.find(handle); }
    [[nodiscard]] const BindGroup* find(BindGroupHandle handle) const noexcept { return groups_.find(handle); }
    [[nodiscard]] QueryPool* find(QueryPoolHandle handle) noexcept { return queries_.find(handle); }

    // Dựng buffer structured khi nhóm gắn cho biết stride. Gọi dưới khoá immediate.
    [[nodiscard]] Status materialize(Buffer& buffer, std::uint32_t stride);
    void retire(Microsoft::WRL::ComPtr<IUnknown> object);
    void note_loss(HRESULT code) noexcept;
    void enqueue(GpuWait& wait);

private:
    [[nodiscard]] Status flush_locked(ID3D11DeviceContext& context);
    void reclaim(std::uint64_t done);
    void pump_locked(ID3D11DeviceContext& context);
    void finish_wait(ID3D11DeviceContext& context, GpuWait& wait);
    [[nodiscard]] std::size_t consume_at(ID3D11DeviceContext& context, std::size_t index);
    [[nodiscard]] Result<CommandList*> adopt_list(std::unique_ptr<Commands>& made);

    Microsoft::WRL::ComPtr<ID3D11Device> device_;
    Microsoft::WRL::ComPtr<ID3D11DeviceContext> immediate_;
    Microsoft::WRL::ComPtr<IDXGIAdapter1> adapter_dxgi_;
    mutable Microsoft::WRL::ComPtr<ID3D11InfoQueue> info_;
    mutable std::atomic<std::uint64_t> logged_{0};
    std::mutex immediate_mutex_;
    std::mutex pool_mutex_;
    std::mutex retire_mutex_;
    std::vector<Retired> retired_;
    std::vector<GpuWait> waits_;
    std::vector<std::unique_ptr<Commands>> pool_;
    std::atomic<std::uint64_t> submitted_{0};
    std::atomic<std::uint64_t> completed_{0};
    std::atomic<DeviceLoss> loss_{DeviceLoss::kNone};
    AdapterInfo adapter_{};
    DeviceCaps caps_{};
    bool allows_tearing_ = false;
    Slots<Buffer, BufferTag> buffers_;
    Slots<Texture, TextureTag> textures_;
    Slots<View, TextureViewTag> views_;
    Slots<Sampler, SamplerTag> samplers_;
    Slots<Shader, ShaderTag> shaders_;
    Slots<Pipeline, PipelineTag> pipelines_;
    Slots<BindGroup, BindGroupTag> groups_;
    Slots<QueryPool, QueryPoolTag> queries_;
};

} // namespace game::gpu::d3d11
