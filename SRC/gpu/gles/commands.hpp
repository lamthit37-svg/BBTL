// Danh sách lệnh GL ghi ở CPU. submit mới đụng driver, một lần khoá cho cả lần nộp.
#pragma once

#include "gpu/command.hpp"
#include "gpu/gles/device.hpp"

#include <array>
#include <cstdint>
#include <optional>
#include <vector>

namespace game::gpu::gles {

class GlCommands final : public CommandList {
public:
    GlCommands(GlDevice& device, QueueType queue);

    void reset(QueueType queue);
    [[nodiscard]] bool is_open() const noexcept { return is_open_; }
    [[nodiscard]] core::Status take_error();

    [[nodiscard]] QueueType queue() const noexcept override;
    void begin_label(std::string_view name) override;
    void end_label() override;
    void insert_label(std::string_view name) override;
    void barrier(std::span<const BufferBarrier> buffers, std::span<const TextureBarrier> textures,
        std::span<const GlobalBarrier> globals) override;
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
    void draw_indirect(BufferHandle arguments, std::uint64_t offset, std::uint32_t count,
        std::uint32_t stride) override;
    void draw_indexed_indirect(BufferHandle arguments, std::uint64_t offset, std::uint32_t count,
        std::uint32_t stride) override;
    void dispatch(const DispatchArguments& arguments) override;
    void dispatch_indirect(BufferHandle arguments, std::uint64_t offset) override;
    void copy_buffer(BufferHandle source, BufferHandle target, const BufferCopy& region) override;
    void copy_texture(TextureHandle source, TextureHandle target, const TextureCopy& region) override;
    void copy_buffer_to_texture(BufferHandle source, TextureHandle target,
        std::span<const BufferTextureCopy> regions) override;
    void copy_texture_to_buffer(TextureHandle source, BufferHandle target,
        std::span<const BufferTextureCopy> regions) override;
    void reset_queries(QueryPoolHandle pool, std::uint32_t first, std::uint32_t count) override;
    void write_timestamp(QueryPoolHandle pool, std::uint32_t index, SyncStage stage) override;
    void begin_occlusion(QueryPoolHandle pool, std::uint32_t index) override;
    void end_occlusion(QueryPoolHandle pool, std::uint32_t index) override;
    void resolve_queries(QueryPoolHandle pool, std::uint32_t first, std::uint32_t count) override;

    void execute();

private:
    void reject(core::Failure failure);
    [[nodiscard]] bool live() const noexcept;
    void draw_common(std::uint32_t count, std::uint32_t instances, bool indexed);
    // Trạng thái pipeline, tài nguyên và hình học của một lệnh vẽ. Mỗi phần tự bỏ qua khi context GL
    // đã giữ đúng giá trị ấy (GlDrawCache), vì mỗi lời gọi trạng thái trên PowerVR rất đắt.
    void apply_pipeline(GlFunctions& api, const GlPipeline& pipeline);
    void bind_groups(const GlPipeline& pipeline);
    void bind_group_at(const GlPipeline& pipeline, std::uint32_t space);
    void bind_entry(const GlPipeline& pipeline, std::uint32_t space, const GlBinding& binding);
    void bind_slot(const BindSlot& slot, const Bound& resource);
    void bind_range(const BindSlot& slot, const BufferRange& range);
    void bind_view(const BindSlot& slot, const TextureViewHandle& handle);
    void bind_object(const BindSlot& slot, const SamplerHandle& handle);
    void bind_push(const GlPipeline& pipeline);
    void bind_geometry(GlFunctions& api);
    void issue_draw(GlFunctions& api, const GlPipeline& pipeline, std::uint32_t count, std::uint32_t instances,
        bool indexed);

    GlDevice* device_ = nullptr;
    QueueType queue_ = QueueType::kGraphics;
    bool is_open_ = false;
    bool is_rendering_ = false;
    std::optional<core::Error> error_;
    PipelineHandle pipeline_{};
    std::array<BindGroupHandle, kMaxBindGroups> groups_{};
    BufferHandle vertices_{};
    std::uint64_t vertex_offset_ = 0;
    BufferHandle indices_{};
    IndexType index_type_ = IndexType::kUint32;
    std::uint64_t index_offset_ = 0;
    std::vector<std::byte> push_;
    std::uint32_t push_offset_ = 0;
    bool has_push_ = false;
    std::uint32_t target_height_ = 0;
    TextureViewHandle resolve_{};
    std::uint32_t pass_width_ = 0;
    std::uint32_t pass_height_ = 0;
};

} // namespace game::gpu::gles
