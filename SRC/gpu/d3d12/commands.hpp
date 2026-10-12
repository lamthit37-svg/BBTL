// Danh sách lệnh D3D12: một allocator và một command list 7. Lệnh ghi sai không xuống trình điều
// khiển; lỗi đầu tiên được giữ và submit trả lỗi ấy. D3D12 không lật trục Y.
// Nguồn: Forge2 src/gpu/d3d12/commands.hpp@d7fcd76. Khác gốc: bỏ {} thừa của error_;
// alias để chữ ký còn một dòng.
#pragma once

#include "gpu/d3d12/device.hpp"

#include <vector>

namespace game::gpu::d3d12 {

class Commands final : public CommandList {
public:
    using Allocator = Microsoft::WRL::ComPtr<ID3D12CommandAllocator>;
    using List = Microsoft::WRL::ComPtr<ID3D12GraphicsCommandList7>;
    using BufferBarriers = std::span<const BufferBarrier>;
    using TextureBarriers = std::span<const TextureBarrier>;
    using GlobalBarriers = std::span<const GlobalBarrier>;
    using Regions = std::span<const BufferTextureCopy>;
    using U32 = std::uint32_t;
    using U64 = std::uint64_t;

    Commands(D3d12Device& device, QueueType queue, Allocator allocator, List list) noexcept
        : device_(&device), queue_(queue), allocator_(std::move(allocator)), list_(std::move(list)) {}
    ~Commands() override = default;
    Commands(const Commands&) = delete;
    Commands& operator=(const Commands&) = delete;
    Commands(Commands&&) = delete;
    Commands& operator=(Commands&&) = delete;

    [[nodiscard]] QueueType queue() const noexcept override { return queue_; }
    void begin_label(std::string_view name) override;
    void end_label() override;
    void insert_label(std::string_view name) override;
    void barrier(BufferBarriers buffers, TextureBarriers textures, GlobalBarriers memory) override;
    void begin_rendering(const RenderingDesc& desc) override;
    void end_rendering() override;
    void set_viewport(const Viewport& viewport) override;
    void set_scissor(const Scissor& scissor) override;
    void set_stencil_reference(std::uint32_t value) override;
    void set_blend_constants(const ClearColor& color) override;
    void set_depth_bounds(float nearest, float farthest) override;
    void bind_pipeline(PipelineHandle pipeline) override;
    void bind_group(std::uint32_t space, BindGroupHandle group) override;
    void push_constants(std::span<const std::byte> data, std::uint32_t offset) override;
    void bind_vertex_buffer(std::uint32_t slot, BufferHandle buffer, std::uint64_t offset) override;
    void bind_index_buffer(BufferHandle buffer, IndexType type, std::uint64_t offset) override;
    void draw(const DrawArguments& arguments) override;
    void draw_indexed(const DrawIndexedArguments& arguments) override;
    void draw_indirect(BufferHandle buffer, U64 offset, U32 count, U32 stride) override;
    void draw_indexed_indirect(BufferHandle buffer, U64 offset, U32 count, U32 stride) override;
    void dispatch(const DispatchArguments& arguments) override;
    void dispatch_indirect(BufferHandle arguments, std::uint64_t offset) override;
    void copy_buffer(BufferHandle from, BufferHandle dest, const BufferCopy& region) override;
    void copy_texture(TextureHandle from, TextureHandle dest, const TextureCopy& region) override;
    void copy_buffer_to_texture(BufferHandle source, TextureHandle target, Regions regions) override;
    void copy_texture_to_buffer(TextureHandle source, BufferHandle target, Regions regions) override;
    void reset_queries(QueryPoolHandle pool, std::uint32_t first, std::uint32_t count) override;
    void write_timestamp(QueryPoolHandle pool, std::uint32_t index, SyncStage stage) override;
    void begin_occlusion(QueryPoolHandle pool, std::uint32_t index) override;
    void end_occlusion(QueryPoolHandle pool, std::uint32_t index) override;
    void resolve_queries(QueryPoolHandle pool, std::uint32_t first, std::uint32_t count) override;

    enum class State : std::uint8_t { kIdle, kRecording, kClosed, kPending };

    [[nodiscard]] ID3D12GraphicsCommandList* list() const noexcept { return list_.Get(); }
    [[nodiscard]] State state() const noexcept { return state_; }
    [[nodiscard]] Status open();
    [[nodiscard]] Status close();
    void mark_pending() noexcept { state_ = State::kPending; }
    void mark_idle() noexcept { state_ = State::kIdle; }
    void stamp(std::uint64_t value);

private:
    struct QueryUse {
        QueryPoolHandle pool{};
        std::uint32_t first = 0;
        std::uint32_t count = 0;
    };
    struct Resolve {
        ID3D12Resource* source = nullptr;
        ID3D12Resource* target = nullptr;
        UINT source_subresource = 0;
        UINT target_subresource = 0;
        UINT source_mip = 0;
        UINT source_layer = 0;
        UINT target_mip = 0;
        UINT target_layer = 0;
        DXGI_FORMAT format = DXGI_FORMAT_UNKNOWN;
        bool is_integer = false;
    };

    [[nodiscard]] bool live();
    void reject(core::Failure failure);
    [[nodiscard]] const Buffer* need(BufferHandle handle, BufferUsage usage, core::Message message);
    [[nodiscard]] const Texture* need(TextureHandle handle, TextureUsage usage, core::Message message);
    [[nodiscard]] const View* need(TextureViewHandle handle, core::Message message);
    [[nodiscard]] QueryPool* need_query(QueryPoolHandle handle, QueryKind kind, std::uint32_t first,
        std::uint32_t count);
    [[nodiscard]] const Buffer* need_arguments(BufferHandle handle, std::uint64_t offset, std::uint32_t count,
        std::uint32_t stride, std::uint32_t size);
    [[nodiscard]] bool can_draw();
    [[nodiscard]] bool can_dispatch();
    [[nodiscard]] bool is_bound() const noexcept;
    void add_buffer(const BufferBarrier& item);
    void add_texture(const TextureBarrier& item);
    void add_global(const GlobalBarrier& item);
    void flush_barriers();
    [[nodiscard]] bool fill_color(const ColorTarget& target, UINT slot);
    void note_extent(const View& view) noexcept;
    void apply_area(const Scissor& area);
    void resolve_stored();
    void resolve_item(const Resolve& item);
    [[nodiscard]] Resolve make_resolve(const View& view, const View& resolved, const Texture& source,
        const Texture& dest, std::uint32_t layer, bool is_integer) const;
    void copy_regions(const Buffer& buffer, const Texture& texture, std::span<const BufferTextureCopy> regions,
        bool to_texture);

    D3d12Device* device_;
    QueueType queue_;
    Microsoft::WRL::ComPtr<ID3D12CommandAllocator> allocator_;
    Microsoft::WRL::ComPtr<ID3D12GraphicsCommandList7> list_;
    State state_ = State::kIdle;
    bool is_live_ = false;
    bool is_rendering_ = false;
    bool has_warned_ = false;
    std::uint32_t open_labels_ = 0;
    Status error_;
    Pipeline pipeline_{};
    std::uint32_t bound_ = 0;
    std::uint32_t extent_width_ = 0;
    std::uint32_t extent_height_ = 0;
    std::vector<D3D12_BUFFER_BARRIER> buffer_barriers_;
    std::vector<D3D12_TEXTURE_BARRIER> texture_barriers_;
    std::vector<D3D12_GLOBAL_BARRIER> global_barriers_;
    std::vector<D3D12_CPU_DESCRIPTOR_HANDLE> colors_;
    std::vector<Resolve> resolves_;
    std::vector<QueryUse> queries_;
    std::string label_;
};

} // namespace game::gpu::d3d12
