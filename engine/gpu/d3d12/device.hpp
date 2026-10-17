/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/d3d12/device.hpp
 *  PHÂN HỆ   : Gpu / D3d12 / Device
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Thiết bị D3D12: cài gpu::Device bằng Enhanced Barriers (command list 7).
 *    Bộ nhớ là ID3D12Heap chia bởi gpu/memory.hpp, đơn vị 64 KiB; heap texture
 *    căn 4 MiB để đặt được tài nguyên đa mẫu. Hàng đợi thiếu thì mượn Graphics.
 *    Mesh shader và ray tracing trả Unsupported. Nguồn: Forge2
 *    src/gpu/d3d12/device.hpp@d7fcd76. Khác gốc: core/win32.hpp trước d3d12.h
 *    vì check.py không có NOMINMAX của CMake.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "core/win32.hpp" // IWYU pragma: keep
#include "gpu/check.hpp"
#include "gpu/device.hpp"
#include "gpu/memory.hpp"
#include "gpu/retire.hpp"
#include "gpu/slots.hpp"

#include <d3d12.h>
#include <dxgi1_6.h>
#include <wrl/client.h>

#include <array>
#include <atomic>
#include <cstdint>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <vector>

namespace game::gpu::d3d12 {

inline constexpr UINT kResourceDescriptors = 65'536;
inline constexpr UINT kSamplerDescriptors = 2'048;
inline constexpr UINT kRtvDescriptors = 1'024;
inline constexpr UINT kDsvDescriptors = 256;
inline constexpr UINT kNoDescriptor = ~UINT{0};

class Commands;
class Swapchain12;
class Timeline12;

// Một ID3D12Heap của MemoryPool.
struct HeapBlock {
    Microsoft::WRL::ComPtr<ID3D12Heap> heap;
};

// Năm miền: buffer, đích vẽ, texture thường không được trộn trong một heap tầng 1.
enum class PoolKind : std::uint8_t {
    kDeviceBuffer,
    kDeviceTarget,
    kDeviceTexture,
    kUpload,
    kReadback,
    kCount,
};

struct Allocation {
    MemorySpan span{};
    PoolKind pool = PoolKind::kDeviceBuffer;
};

struct Buffer {
    Microsoft::WRL::ComPtr<ID3D12Resource> resource;
    Allocation memory{};
    std::uint64_t size = 0;
    std::uint64_t gpu_address = 0;
    BufferUsage usage = BufferUsage::kNone;
    MemoryDomain domain = MemoryDomain::kDevice;
    std::byte* mapped = nullptr;
};

struct Texture {
    Microsoft::WRL::ComPtr<ID3D12Resource> resource;
    Allocation memory{};
    TextureDesc desc{};
    // false: ảnh swapchain, tay nắm thả ngay khi resize (đã chờ GPU rỗi).
    bool is_owned = true;
};

struct View {
    TextureHandle texture{};
    ViewRange range{};
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::uint32_t samples = 1;
    UINT srv = kNoDescriptor;
    UINT uav = kNoDescriptor;
    UINT rtv = kNoDescriptor;
    UINT dsv = kNoDescriptor;
    UINT dsv_read = kNoDescriptor;
};

struct Sampler {
    UINT index = kNoDescriptor;
};

struct Shader {
    std::vector<std::byte> code;
    shader::StageReflection reflection{};
};

// Một bảng trong root signature. kNoDescriptor khi space không có bảng ấy.
struct TableRef {
    UINT root = kNoDescriptor;
    UINT count = 0;
};

// Bố cục gắn, sống tới khi thiết bị huỷ. Pipeline và nhóm gắn trỏ vào, không đếm tham chiếu.
struct Layout {
    Microsoft::WRL::ComPtr<ID3D12RootSignature> signature;
    ProgramLayout program{};
    std::array<TableRef, kMaxBindGroups> resources{};
    std::array<TableRef, kMaxBindGroups> samplers{};
    UINT push_root = kNoDescriptor;
    std::uint32_t used = 0;
};

struct Pipeline {
    Microsoft::WRL::ComPtr<ID3D12PipelineState> state;
    const Layout* layout = nullptr;
    bool is_compute = false;
    D3D12_PRIMITIVE_TOPOLOGY topology = D3D_PRIMITIVE_TOPOLOGY_UNDEFINED;
    std::array<std::uint32_t, kMaxVertexBuffers> strides{};
};

// Dãy sampler của một bảng sampler, mỗi phần tử là SamplerHandle đóng gói, 0 là ô rỗng. Tay nắm
// mang thế hệ nên sampler huỷ rồi tạo lại ở cùng ô không trùng khoá với bảng cũ.
using SamplerKey = std::vector<std::uint64_t>;

// Sampler đã chọn cho một bảng dùng chung, theo thứ tự trong bảng: khoá và ô staging để chép.
struct SamplerPick {
    SamplerKey key;
    std::vector<UINT> staging;
};

struct BindGroup {
    const Layout* layout = nullptr;
    std::uint32_t space = 0;
    std::uint32_t capacity = 0;
    UINT resource_at = kNoDescriptor;
    UINT resource_count = 0;
    UINT sampler_at = kNoDescriptor;
    UINT sampler_count = 0;
    // Khoá của bảng sampler dùng chung; rỗng khi nhóm giữ dải riêng hoặc không có sampler.
    SamplerKey sampler_key;
};

struct QueryPool {
    Microsoft::WRL::ComPtr<ID3D12QueryHeap> heap;
    Microsoft::WRL::ComPtr<ID3D12Resource> readback;
    Allocation memory{};
    std::byte* mapped = nullptr;
    // insert chép pool, nên mutex phải dùng chung: stamp và read_queries khoá cùng một cái.
    std::shared_ptr<std::mutex> mutex;
    // Giá trị fence mà ô đã resolve xong; 0 là chưa resolve.
    std::vector<std::uint64_t> ready_at;
    QueryKind kind = QueryKind::kTimestamp;
    D3D12_QUERY_TYPE type = D3D12_QUERY_TYPE_TIMESTAMP;
    std::uint32_t count = 0;
    QueueType queue = QueueType::kGraphics;
    D3D12_BARRIER_SYNC last_sync = D3D12_BARRIER_SYNC_NONE;
    D3D12_BARRIER_ACCESS last_access = D3D12_BARRIER_ACCESS_COMMON;
};

// Hàng đợi vật lý. Hàng thiếu trên thiết bị dùng chung hàng Graphics.
struct Queue {
    Microsoft::WRL::ComPtr<ID3D12CommandQueue> queue;
    Microsoft::WRL::ComPtr<ID3D12Fence> fence;
    // ExecuteCommandLists và Signal đòi đồng bộ ngoài; mutex cũng bảo vệ submitted.
    std::mutex mutex;
    std::atomic<std::uint64_t> submitted{0};
    double period_ns = 1.0;
    bool is_native = false;
};

// Vùng descriptor liên tiếp. mutex bảo vệ bump và free.
class DescriptorArena {
public:
    [[nodiscard]] core::Status create(ID3D12Device* device, D3D12_DESCRIPTOR_HEAP_TYPE type, UINT count,
        bool is_shader_visible);
    [[nodiscard]] std::optional<UINT> allocate(UINT count);
    void free(UINT index, UINT count) noexcept;
    [[nodiscard]] D3D12_CPU_DESCRIPTOR_HANDLE cpu(UINT index) const noexcept;
    [[nodiscard]] D3D12_GPU_DESCRIPTOR_HANDLE gpu(UINT index) const noexcept;
    [[nodiscard]] ID3D12DescriptorHeap* heap() const noexcept { return heap_.Get(); }
    [[nodiscard]] UINT capacity() const noexcept { return capacity_; }

private:
    [[nodiscard]] std::optional<UINT> take_free(UINT count) noexcept;

    Microsoft::WRL::ComPtr<ID3D12DescriptorHeap> heap_;
    D3D12_CPU_DESCRIPTOR_HANDLE cpu_{};
    D3D12_GPU_DESCRIPTOR_HANDLE gpu_{};
    UINT stride_ = 0;
    UINT capacity_ = 0;
    UINT bump_ = 0;
    struct Span {
        UINT index = 0;
        UINT count = 0;
    };
    std::vector<Span> free_;
    mutable std::mutex mutex_;
};

enum class IndirectKind : std::uint8_t { kDraw, kDrawIndexed, kDispatch };

class D3d12Device final : public Device {
public:
    D3d12Device() = default;
    ~D3d12Device() override;
    D3d12Device(const D3d12Device&) = delete;
    D3d12Device& operator=(const D3d12Device&) = delete;
    D3d12Device(D3d12Device&&) = delete;
    D3d12Device& operator=(D3d12Device&&) = delete;

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

    [[nodiscard]] ID3D12Device* device() const noexcept { return device_.Get(); }
    [[nodiscard]] Queue& queue_of(QueueType type) noexcept {
        return queues_.at(queue_index_.at(std::to_underlying(type)));
    }
    [[nodiscard]] const Queue& queue_of(QueueType type) const noexcept {
        return queues_.at(queue_index_.at(std::to_underlying(type)));
    }
    [[nodiscard]] std::uint64_t completed(QueueType type) const noexcept;

    [[nodiscard]] const Buffer* find(BufferHandle handle) const noexcept { return buffers_.find(handle); }
    [[nodiscard]] const Texture* find(TextureHandle handle) const noexcept { return textures_.find(handle); }
    [[nodiscard]] const View* find(TextureViewHandle handle) const noexcept { return views_.find(handle); }
    [[nodiscard]] const Sampler* find(SamplerHandle handle) const noexcept { return samplers_.find(handle); }
    [[nodiscard]] const Shader* find(ShaderHandle handle) const noexcept { return shaders_.find(handle); }
    [[nodiscard]] const Pipeline* find(PipelineHandle handle) const noexcept { return pipelines_.find(handle); }
    [[nodiscard]] const BindGroup* find(BindGroupHandle handle) const noexcept { return groups_.find(handle); }
    [[nodiscard]] QueryPool* find(QueryPoolHandle handle) noexcept { return queries_.find(handle); }
    [[nodiscard]] const QueryPool* find(QueryPoolHandle handle) const noexcept { return queries_.find(handle); }

    [[nodiscard]] D3D12_CPU_DESCRIPTOR_HANDLE resource_cpu(UINT index) const noexcept { return resources_.cpu(index); }
    [[nodiscard]] D3D12_GPU_DESCRIPTOR_HANDLE resource_gpu(UINT index) const noexcept { return resources_.gpu(index); }
    [[nodiscard]] D3D12_CPU_DESCRIPTOR_HANDLE sampler_cpu(UINT index) const noexcept {
        return samplers_gpu_.cpu(index);
    }
    [[nodiscard]] D3D12_GPU_DESCRIPTOR_HANDLE sampler_gpu(UINT index) const noexcept {
        return samplers_gpu_.gpu(index);
    }
    [[nodiscard]] D3D12_CPU_DESCRIPTOR_HANDLE staging_cpu(UINT index) const noexcept { return staging_.cpu(index); }
    [[nodiscard]] D3D12_CPU_DESCRIPTOR_HANDLE sampler_staging_cpu(UINT index) const noexcept {
        return sampler_staging_.cpu(index);
    }
    [[nodiscard]] D3D12_CPU_DESCRIPTOR_HANDLE rtv_cpu(UINT index) const noexcept { return rtvs_.cpu(index); }
    [[nodiscard]] D3D12_CPU_DESCRIPTOR_HANDLE dsv_cpu(UINT index) const noexcept { return dsvs_.cpu(index); }
    [[nodiscard]] ID3D12DescriptorHeap* resource_heap() const noexcept { return resources_.heap(); }
    [[nodiscard]] ID3D12DescriptorHeap* sampler_heap() const noexcept { return samplers_gpu_.heap(); }

    [[nodiscard]] std::optional<UINT> allocate_resource(UINT count) { return resources_.allocate(count); }
    [[nodiscard]] std::optional<UINT> allocate_sampler(UINT count) { return samplers_gpu_.allocate(count); }
    [[nodiscard]] std::optional<UINT> allocate_staging() { return staging_.allocate(1); }
    [[nodiscard]] std::optional<UINT> allocate_sampler_staging() { return sampler_staging_.allocate(1); }
    [[nodiscard]] std::optional<UINT> allocate_rtv() { return rtvs_.allocate(1); }
    [[nodiscard]] std::optional<UINT> allocate_dsv() { return dsvs_.allocate(1); }
    void free_resource(UINT index, UINT count) noexcept { resources_.free(index, count); }
    void free_sampler(UINT index, UINT count) noexcept { samplers_gpu_.free(index, count); }
    void free_staging(UINT index) noexcept { staging_.free(index, 1); }
    void free_sampler_staging(UINT index) noexcept { sampler_staging_.free(index, 1); }
    void free_rtv(UINT index) noexcept { rtvs_.free(index, 1); }
    void free_dsv(UINT index) noexcept { dsvs_.free(index, 1); }

    [[nodiscard]] ID3D12CommandSignature* signature(IndirectKind kind, UINT stride);
    [[nodiscard]] core::Failure failed(HRESULT result, core::Message message) noexcept;
    // Mốc hoàn thành đã biết là cận dưới. GPU đã qua mốc hiện tại thì thả ngay, không xếp hàng.
    [[nodiscard]] QueueMarks cached_done() const noexcept;
    void keep_done(const QueueMarks& done) noexcept;
    void retire(Retired::Action action) {
        const QueueMarks current = marks();
        if (has_passed(cached_done(), current)) {
            action();
            return;
        }
        retired_.push(current, std::move(action));
    }
    [[nodiscard]] Result<const Layout*> layout_for(const ProgramLayout& program);

    // Ảnh swapchain vào bảng texture. release thả ngay, chỉ gọi khi GPU đã rỗi.
    [[nodiscard]] TextureHandle adopt(Microsoft::WRL::ComPtr<ID3D12Resource> image, const TextureDesc& desc);
    void release(TextureHandle handle);
    void release(TextureViewHandle handle);
    // Thu phần huỷ hoãn mà GPU đã xong, không đụng danh sách lệnh đang mở. Swapchain gọi sau khi
    // nhả ảnh: DXGI đòi hết tham chiếu bộ đệm trước ResizeBuffers và trước khi huỷ swapchain.
    void collect_retired();
    // Present là thao tác GPU nằm sau Signal của submit. Đánh dấu thêm một mốc để wait_idle chờ cả nó.
    void note_presented();

    [[nodiscard]] ID3D12CommandQueue* present_queue() noexcept { return queue_of(QueueType::kGraphics).queue.Get(); }

private:
    struct Contexts;

    [[nodiscard]] Status start(const AdapterInfo& info, IDXGIAdapter1* adapter, const DeviceDesc& desc);
    [[nodiscard]] bool add_queue(QueueType kind);
    [[nodiscard]] Status create_queues();
    [[nodiscard]] Status create_heaps();
    void read_caps();
    void create_library(std::span<const std::byte> cache);
    void pump_messages() const noexcept;
    void note_loss() noexcept;
    [[nodiscard]] QueueMarks marks() const noexcept;
    [[nodiscard]] QueueMarks finished() const noexcept;
    void recycle(const QueueMarks& done);
    void wait_queues() noexcept;
    [[nodiscard]] Result<std::unique_ptr<Commands>> make_commands(QueueType queue);

    // Tài nguyên đặt trên heap. address là địa chỉ GPU; mapped khác null khi CPU đọc ghi được.
    struct Placed {
        Microsoft::WRL::ComPtr<ID3D12Resource> resource;
        Allocation memory{};
        std::byte* mapped = nullptr;
        std::uint64_t address = 0;
    };
    [[nodiscard]] Result<Placed> place(const D3D12_RESOURCE_DESC& desc, PoolKind kind, const D3D12_CLEAR_VALUE* clear,
        bool map_cpu);

    [[nodiscard]] Result<HeapBlock> make_heap(PoolKind kind, bool is_msaa, std::uint64_t bytes);
    [[nodiscard]] Result<Allocation> allocate(const D3D12_RESOURCE_ALLOCATION_INFO& needs, PoolKind kind);
    void free(const Allocation& allocation) noexcept;
    [[nodiscard]] Microsoft::WRL::ComPtr<ID3D12Heap> heap_of(const Allocation& allocation);

    void discard(Buffer& buffer) noexcept;
    void discard(Texture& texture) noexcept;
    void discard(View& view) noexcept;
    void discard(Sampler& sampler) noexcept;
    void discard(Shader& shader) noexcept;
    void discard(Pipeline& pipeline) noexcept;
    void discard(BindGroup& group) noexcept;
    void discard(QueryPool& pool) noexcept;
    template <class T, class Tag>
    void retire_of(Slots<T, Tag>& table, Handle<Tag> handle);
    template <class T, class Tag>
    void drain(Slots<T, Tag>& table) noexcept;

    [[nodiscard]] Result<const Layout*> keep_layout(std::unique_ptr<Layout> layout);
    [[nodiscard]] Status fill_signature(Layout& layout);
    // Cấp dải descriptor cho group rồi ghi entries; lỗi thì người gọi discard(group).
    [[nodiscard]] Status fill_group(BindGroup& group, const SpaceLayout& space,
        std::span<const BindEntry> entries);
    // pick khác null: sampler ghi vào pick để share_samplers, không ghi vào dải của nhóm.
    [[nodiscard]] Status write_group(const BindGroup& group, std::span<const BindEntry> entries,
        SamplerPick* pick);
    // Gắn group vào bảng sampler của dãy pick: thêm một người dùng nếu bảng đã có, không thì cấp
    // dải mới và chép descriptor. pick rỗng thì không làm gì. Exhausted khi heap sampler hết chỗ.
    [[nodiscard]] Status share_samplers(BindGroup& group, SamplerPick pick);
    // Bớt một người dùng; người cuối thì thả dải. Chỉ gọi khi GPU đã xong với nhóm (discard).
    void unshare_samplers(const SamplerKey& key) noexcept;
    [[nodiscard]] Result<PipelineHandle> keep_pipeline(Pipeline pipeline, std::string_view name);

    Microsoft::WRL::ComPtr<IDXGIFactory4> factory_;
    Microsoft::WRL::ComPtr<IDXGIAdapter1> adapter_com_;
    Microsoft::WRL::ComPtr<ID3D12Device2> device_;
    mutable Microsoft::WRL::ComPtr<ID3D12InfoQueue> info_;
    mutable std::uint64_t logged_ = 0;
    // Blob sống lâu hơn library_: thành viên khai sau bị huỷ trước, nên blob đứng trước thư viện.
    std::vector<std::byte> library_bytes_;
    Microsoft::WRL::ComPtr<ID3D12PipelineLibrary> library_;
    AdapterInfo adapter_{};
    DeviceCaps caps_{};
    std::atomic<DeviceLoss> loss_{DeviceLoss::kNone};
    bool debug_ = false;

    std::array<Queue, kQueueCount> queues_{};
    std::array<std::uint32_t, kQueueCount> queue_index_{};
    std::uint32_t queue_count_ = 0;
    // Số list đang mở trên từng hàng logic. marks() cộng số này vào mốc đã nộp để tài nguyên huỷ
    // trong lúc ghi lệnh không bị thả trước khi những list ấy được nộp.
    std::array<std::atomic<std::uint32_t>, kQueueCount> recording_{};
    std::array<std::atomic<std::uint64_t>, kQueueCount> done_cache_{};

    DescriptorArena resources_;
    DescriptorArena samplers_gpu_;
    DescriptorArena staging_;
    DescriptorArena sampler_staging_;
    DescriptorArena rtvs_;
    DescriptorArena dsvs_;

    Slots<Buffer, BufferTag> buffers_;
    Slots<Texture, TextureTag> textures_;
    Slots<View, TextureViewTag> views_;
    Slots<Sampler, SamplerTag> samplers_;
    Slots<Shader, ShaderTag> shaders_;
    Slots<Pipeline, PipelineTag> pipelines_;
    Slots<BindGroup, BindGroupTag> groups_;
    Slots<QueryPool, QueryPoolTag> queries_;
    Retired retired_;

    // Heap sampler nhìn thấy từ shader trần 2048 ô, mà mỗi material một dải riêng thì cảnh lớn
    // vượt trần; nhóm cùng dãy sampler dùng chung một dải. Thứ tự khoá: sampler_tables_mutex_
    // rồi mới tới mutex của samplers_gpu_.
    struct SharedSamplers {
        UINT at = kNoDescriptor;
        UINT users = 0;
    };
    std::mutex sampler_tables_mutex_; // bảo vệ sampler_tables_
    std::map<SamplerKey, SharedSamplers> sampler_tables_;

    std::mutex memory_mutex_;
    std::array<std::unique_ptr<MemoryPool<HeapBlock>>, std::to_underlying(PoolKind::kCount)> pools_{};

    std::mutex layout_mutex_;
    std::vector<std::unique_ptr<Layout>> layouts_;

    std::mutex signature_mutex_;
    struct SignatureKey {
        IndirectKind kind = IndirectKind::kDraw;
        UINT stride = 0;
        [[nodiscard]] friend bool operator==(const SignatureKey&, const SignatureKey&) = default;
    };
    std::vector<std::pair<SignatureKey, Microsoft::WRL::ComPtr<ID3D12CommandSignature>>> signatures_;

    std::unique_ptr<Contexts> contexts_;
};

[[nodiscard]] Result<std::vector<AdapterInfo>> adapters();
[[nodiscard]] Result<std::unique_ptr<Device>> create(const DeviceDesc& desc);
void set_name(ID3D12Object* object, std::string_view name);

} // namespace game::gpu::d3d12
