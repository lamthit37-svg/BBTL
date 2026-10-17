/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/d3d11/commands.hpp
 *  PHÂN HỆ   : Gpu / D3d11 / Commands
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Danh sách lệnh D3D11: một deferred context. Lỗi đầu tiên được giữ, lệnh
 *    sau bỏ, submit trả lỗi ấy. Không lật trục Y. Cache pipeline, nhóm gắn và
 *    buffer đỉnh để khỏi gắn lại thứ không đổi. Push constant là cbuffer
 *    DEFAULT 256 byte ở b1, UpdateSubresource lúc ghi.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "gpu/d3d11/binding_map.hpp"
#include "gpu/d3d11/device.hpp"

#include <d3d11_1.h>

#include <array>
#include <vector>

namespace game::gpu::d3d11 {

class Commands final : public CommandList {
public:
    using BufferBarriers = std::span<const BufferBarrier>;
    using TextureBarriers = std::span<const TextureBarrier>;
    using GlobalBarriers = std::span<const GlobalBarrier>;
    using Regions = std::span<const BufferTextureCopy>;
    using U32 = std::uint32_t;
    using U64 = std::uint64_t;
    using Buf = BufferHandle;
    using Tex = TextureHandle;
    using List = Microsoft::WRL::ComPtr<ID3D11CommandList>;
    using Context = Microsoft::WRL::ComPtr<ID3D11DeviceContext>;

    Commands(D3d11Device& device, QueueType queue, Context context);
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
    void bind_vertex_buffer(U32 slot, Buf buffer, U64 offset) override;
    void bind_index_buffer(Buf buffer, IndexType type, U64 offset) override;
    void draw(const DrawArguments& arguments) override;
    void draw_indexed(const DrawIndexedArguments& arguments) override;
    void draw_indirect(BufferHandle buffer, U64 offset, U32 count, U32 stride) override;
    void draw_indexed_indirect(BufferHandle buffer, U64 offset, U32 count, U32 stride) override;
    void dispatch(const DispatchArguments& arguments) override;
    void dispatch_indirect(BufferHandle arguments, std::uint64_t offset) override;
    void copy_buffer(BufferHandle from, BufferHandle dest, const BufferCopy& region) override;
    void copy_texture(TextureHandle from, TextureHandle dest, const TextureCopy& region) override;
    void copy_buffer_to_texture(Buf source, Tex target, Regions regions) override;
    void copy_texture_to_buffer(Tex source, Buf target, Regions regions) override;
    void reset_queries(QueryPoolHandle pool, U32 first, U32 count) override;
    void write_timestamp(QueryPoolHandle pool, std::uint32_t index, SyncStage stage) override;
    void begin_occlusion(QueryPoolHandle pool, std::uint32_t index) override;
    void end_occlusion(QueryPoolHandle pool, std::uint32_t index) override;
    void resolve_queries(QueryPoolHandle pool, U32 first, U32 count) override;

    enum class State : std::uint8_t { kIdle, kRecording, kClosed, kPending };

    [[nodiscard]] State state() const noexcept { return state_; }
    [[nodiscard]] Status error() const { return error_; }
    [[nodiscard]] Status open();
    [[nodiscard]] Status close(List& out);
    void mark_pending();
    void mark_idle();
    [[nodiscard]] std::vector<PendingReadback> take_readbacks();

private:
    [[nodiscard]] bool live();
    void reject(core::Failure failure);
    void unbind_targets();
    void apply_area(const Scissor& area);
    void forget_groups() noexcept;
    void apply_vertex_buffer(const Pipeline& pipeline, std::uint32_t slot);
    void apply_vertex_buffers(const Pipeline& pipeline);

    D3d11Device* device_;
    QueueType queue_;
    Microsoft::WRL::ComPtr<ID3D11DeviceContext> context_;
    Microsoft::WRL::ComPtr<ID3D11DeviceContext1> context1_;
    Microsoft::WRL::ComPtr<ID3DUserDefinedAnnotation> annotation_;
    Microsoft::WRL::ComPtr<ID3D11Buffer> push_;
    std::array<std::byte, kConstantBytes> push_bytes_{};
    State state_ = State::kIdle;
    bool is_rendering_ = false;
    bool targets_bound_ = false;
    Status error_;
    PipelineHandle pipeline_{};
    std::uint64_t layout_hash_ = 0;
    std::array<BindGroupHandle, kMaxBindGroups> groups_{};
    std::array<bool, kMaxBindGroups> group_set_{};
    std::array<BufferHandle, kMaxVertexBuffers> vertices_{};
    std::array<std::uint64_t, kMaxVertexBuffers> vertex_at_{};
    std::array<bool, kMaxVertexBuffers> vertex_set_{};
    // Stride đang nằm trên context của từng khe, 0 khi chưa áp. Stride thuộc pipeline như Vulkan:
    // bind_pipeline áp lại khe nào có stride khác.
    std::array<std::uint32_t, kMaxVertexBuffers> vertex_strides_{};
    BufferHandle index_{};
    IndexType index_type_ = IndexType::kUint32;
    std::uint64_t index_at_ = 0;
    bool index_set_ = false;
    bool viewport_set_ = false;
    bool scissor_set_ = false;
    Viewport viewport_{};
    Scissor scissor_{};
    std::uint32_t stencil_ = 0;
    ClearColor blend_{};
    bool blend_set_ = false;
    std::vector<PendingReadback> readbacks_;
};

} // namespace game::gpu::d3d11
