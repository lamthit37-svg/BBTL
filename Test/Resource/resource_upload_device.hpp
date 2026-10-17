/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Resource/resource_upload_device.hpp
 *  PHÂN HỆ   : Resource / Resource Upload Device
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Thiết bị giả cho test của resource/upload. Nó giữ sổ các tay nắm còn sống,
 *    nhớ thứ tự trả tay nắm và thứ tự lệnh đã ghi, đếm từng loại lời gọi, và
 *    hỏng theo kế hoạch ở lời gọi thứ n. Chỉ các hàm mà upload.cpp gọi mới có
 *    thân thật; mọi hàm khác của gpu::Device và gpu::CommandList ghi một lần
 *    "lạc" để test bắt được lời gọi ngoài hợp đồng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Viết tay: giao diện gpu thêm hàm thuần ảo thì trình dịch báo thiếu ngay ở đây, thêm một dòng "lạc" cho hàm ấy là
// xong.

#pragma once

#include "core/error.hpp"
#include "gpu/barrier.hpp"
#include "gpu/binding.hpp"
#include "gpu/command.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "gpu/pipeline.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {

// Loại tay nắm trong sổ của thiết bị giả; mỗi loại đếm số thứ tự riêng.
enum class Kind : std::uint8_t {
    kBuffer,
    kTexture,
    kView,
    kSampler,
};

// Một tay nắm đã cấp, gọi bằng loại và số thứ tự.
struct Slot {
    Kind kind = Kind::kBuffer;
    std::uint32_t index = 0;

    friend constexpr bool operator==(const Slot&, const Slot&) = default;
};

// Lời gọi có thể hỏng của thiết bị, để test biết lỗi đã tiêm rơi vào bước nào.
enum class Call : std::uint8_t {
    kBeginCommands,
    kCreateBuffer,
    kWriteBuffer,
    kCreateTexture,
    kCreateView,
    kCreateSampler,
    kSubmit,
    kWaitIdle,
};

// Lệnh đã ghi vào danh sách lệnh. Rào chia hai loại theo bố cục đích của texture: sang CopyDest
// trước lệnh chép ảnh, và rào cuối đưa buffer cùng texture về trạng thái đọc.
enum class Command : std::uint8_t {
    kCopyBuffer,
    kToCopyDest,
    kCopyImage,
    kToRead,
};

// Cách thiết bị giả phải hỏng trong một lượt thử.
struct Plan {
    // Lời gọi có thể hỏng thứ fail_at (đếm từ 1) trả lỗi kCorrupt; 0 là không tiêm lỗi.
    std::uint32_t fail_at = 0;
    // end_frame trả lỗi kDeviceLost mỗi lần được gọi.
    bool fail_end_frame = false;
    // Thiết bị báo đã mất ngay từ đầu.
    bool is_lost = false;
    // Thiết bị báo bộ nhớ hợp nhất (DeviceCaps::has_unified_memory).
    bool is_unified = false;
};

// Mọi điều thiết bị giả đã thấy trong một lượt thử.
struct Seen {
    // Tay nắm đã tạo mà chưa trả, và các tay nắm đã trả theo đúng thứ tự trả.
    std::vector<Slot> live;
    std::vector<Slot> released;
    // Trả một tay nắm hợp lệ nhưng không còn sống: trả hai lần, hoặc trả thứ chưa từng tạo.
    std::uint32_t double_frees = 0;
    // Lệnh chép dùng một tay nắm không còn sống.
    std::uint32_t dead_uses = 0;
    // Hàm ngoài hợp đồng của upload bị gọi, hoặc submit không mang đúng danh sách lệnh đã mở.
    std::uint32_t strays = 0;
    // Số lời gọi có thể hỏng đã thấy, và lời gọi đã bị tiêm lỗi nếu có.
    std::uint32_t fallible = 0;
    std::optional<Call> tripped;
    // Số lời gọi thành công theo loại.
    std::uint32_t buffers = 0;
    // Phần của buffers nằm ở MemoryDomain::kUpload.
    std::uint32_t upload_buffers = 0;
    std::uint32_t textures = 0;
    std::uint32_t views = 0;
    std::uint32_t samplers = 0;
    std::uint32_t writes = 0;
    std::uint32_t begins = 0;
    std::uint32_t submits = 0;
    // Số tay nắm đã trả vào lúc lần nộp gần nhất: buffer trung chuyển chưa nộp mà trả là hỏng.
    std::uint32_t released_at_submit = 0;
    std::uint32_t waits = 0;
    std::uint32_t end_frames = 0;
    // Lệnh theo thứ tự ghi; tổng số vùng của các lệnh chép ảnh; tổng số rào buffer và rào texture.
    std::vector<Command> commands;
    std::uint32_t copy_regions = 0;
    std::uint32_t buffer_barriers = 0;
    std::uint32_t texture_barriers = 0;
};

using BufferBarriers = std::span<const gpu::BufferBarrier>;
using TextureBarriers = std::span<const gpu::TextureBarrier>;
using GlobalBarriers = std::span<const gpu::GlobalBarrier>;
using CopyRegions = std::span<const gpu::BufferTextureCopy>;
using ByteView = std::span<const std::byte>;

[[nodiscard]] inline std::uint32_t count_of(std::size_t size) noexcept {
    return static_cast<std::uint32_t>(size);
}

// Danh sách lệnh giả: ghi loại lệnh vào sổ của thiết bị đã mở nó.
class FakeCommands final : public gpu::CommandList {
public:
    explicit FakeCommands(Seen& seen) noexcept : seen_(&seen) {}

    [[nodiscard]] gpu::QueueType queue() const noexcept override { return gpu::QueueType::kGraphics; }

    void barrier(BufferBarriers buffers, TextureBarriers textures, GlobalBarriers) override {
        const bool has_textures = !textures.empty();
        const bool to_copy = has_textures && textures.front().layout_after == gpu::TextureLayout::kCopyDest;
        seen_->commands.push_back(to_copy ? Command::kToCopyDest : Command::kToRead);
        seen_->buffer_barriers += count_of(buffers.size());
        seen_->texture_barriers += count_of(textures.size());
    }

    void copy_buffer(gpu::BufferHandle source, gpu::BufferHandle target, const gpu::BufferCopy&) override {
        seen_->commands.push_back(Command::kCopyBuffer);
        use(Slot{.kind = Kind::kBuffer, .index = source.index});
        use(Slot{.kind = Kind::kBuffer, .index = target.index});
    }

    void copy_buffer_to_texture(gpu::BufferHandle source, gpu::TextureHandle target, CopyRegions regions) override {
        seen_->commands.push_back(Command::kCopyImage);
        seen_->copy_regions += count_of(regions.size());
        use(Slot{.kind = Kind::kBuffer, .index = source.index});
        use(Slot{.kind = Kind::kTexture, .index = target.index});
    }

    // Từ đây xuống là các hàm upload không được gọi.
    void begin_label(std::string_view) override { stray(); }
    void end_label() override { stray(); }
    void insert_label(std::string_view) override { stray(); }
    void begin_rendering(const gpu::RenderingDesc&) override { stray(); }
    void end_rendering() override { stray(); }
    void set_viewport(const gpu::Viewport&) override { stray(); }
    void set_scissor(const gpu::Scissor&) override { stray(); }
    void set_stencil_reference(std::uint32_t) override { stray(); }
    void set_blend_constants(const gpu::ClearColor&) override { stray(); }
    void set_depth_bounds(float, float) override { stray(); }
    void bind_pipeline(gpu::PipelineHandle) override { stray(); }
    void bind_group(std::uint32_t, gpu::BindGroupHandle) override { stray(); }
    void push_constants(ByteView, std::uint32_t) override { stray(); }
    void bind_vertex_buffer(std::uint32_t, gpu::BufferHandle, std::uint64_t) override { stray(); }
    void bind_index_buffer(gpu::BufferHandle, gpu::IndexType, std::uint64_t) override { stray(); }
    void draw(const gpu::DrawArguments&) override { stray(); }
    void draw_indexed(const gpu::DrawIndexedArguments&) override { stray(); }
    void draw_indirect(gpu::BufferHandle, std::uint64_t, std::uint32_t, std::uint32_t) override { stray(); }
    void draw_indexed_indirect(gpu::BufferHandle, std::uint64_t, std::uint32_t, std::uint32_t) override { stray(); }
    void dispatch(const gpu::DispatchArguments&) override { stray(); }
    void dispatch_indirect(gpu::BufferHandle, std::uint64_t) override { stray(); }
    void copy_texture(gpu::TextureHandle, gpu::TextureHandle, const gpu::TextureCopy&) override { stray(); }
    void copy_texture_to_buffer(gpu::TextureHandle, gpu::BufferHandle, CopyRegions) override { stray(); }
    void reset_queries(gpu::QueryPoolHandle, std::uint32_t, std::uint32_t) override { stray(); }
    void write_timestamp(gpu::QueryPoolHandle, std::uint32_t, gpu::SyncStage) override { stray(); }
    void begin_occlusion(gpu::QueryPoolHandle, std::uint32_t) override { stray(); }
    void end_occlusion(gpu::QueryPoolHandle, std::uint32_t) override { stray(); }
    void resolve_queries(gpu::QueryPoolHandle, std::uint32_t, std::uint32_t) override { stray(); }

private:
    void stray() noexcept { ++seen_->strays; }

    void use(Slot slot) noexcept {
        const bool is_live = std::ranges::find(seen_->live, slot) != seen_->live.end();
        if (!is_live) ++seen_->dead_uses;
    }

    Seen* seen_;
};

// Thiết bị giả. Tay nắm rỗng được phép trả (upload trả cả sampler mặc định chưa tạo); tay nắm hợp
// lệ mà không còn trong sổ thì tính là trả hai lần.
class FakeDevice final : public gpu::Device {
public:
    FakeDevice() noexcept : commands_(seen_) {}
    explicit FakeDevice(Plan plan) noexcept : plan_(plan), commands_(seen_) {
        caps_.has_unified_memory = plan.is_unified;
    }

    [[nodiscard]] const Seen& seen() const noexcept { return seen_; }

    [[nodiscard]] gpu::DeviceLoss loss() const noexcept override {
        return plan_.is_lost ? gpu::DeviceLoss::kRemoved : gpu::DeviceLoss::kNone;
    }

    [[nodiscard]] gpu::Result<gpu::BufferHandle> create_buffer(const gpu::BufferDesc& desc) override {
        if (trip(Call::kCreateBuffer)) return broken();
        ++seen_.buffers;
        if (desc.memory == gpu::MemoryDomain::kUpload) ++seen_.upload_buffers;
        return open<gpu::BufferHandle>(Kind::kBuffer);
    }

    [[nodiscard]] gpu::Result<gpu::TextureHandle> create_texture(const gpu::TextureDesc&) override {
        if (trip(Call::kCreateTexture)) return broken();
        ++seen_.textures;
        return open<gpu::TextureHandle>(Kind::kTexture);
    }

    [[nodiscard]] gpu::Result<gpu::TextureViewHandle> create_view(const gpu::TextureViewDesc&) override {
        if (trip(Call::kCreateView)) return broken();
        ++seen_.views;
        return open<gpu::TextureViewHandle>(Kind::kView);
    }

    [[nodiscard]] gpu::Result<gpu::SamplerHandle> create_sampler(const gpu::SamplerDesc&) override {
        if (trip(Call::kCreateSampler)) return broken();
        ++seen_.samplers;
        return open<gpu::SamplerHandle>(Kind::kSampler);
    }

    void destroy(gpu::BufferHandle handle) override { close(Kind::kBuffer, handle); }
    void destroy(gpu::TextureHandle handle) override { close(Kind::kTexture, handle); }
    void destroy(gpu::TextureViewHandle handle) override { close(Kind::kView, handle); }
    void destroy(gpu::SamplerHandle handle) override { close(Kind::kSampler, handle); }

    [[nodiscard]] gpu::Status write_buffer(gpu::BufferHandle, std::uint64_t, ByteView) override {
        if (trip(Call::kWriteBuffer)) return broken();
        ++seen_.writes;
        return core::ok();
    }

    [[nodiscard]] gpu::Result<gpu::CommandList*> begin_commands(gpu::QueueType) override {
        if (trip(Call::kBeginCommands)) return broken();
        ++seen_.begins;
        return &commands_;
    }

    [[nodiscard]] gpu::Status submit(gpu::QueueType, const gpu::SubmitDesc& desc) override {
        if (trip(Call::kSubmit)) return broken();
        const bool is_ours = desc.lists.size() == 1 && desc.lists.front() == &commands_;
        if (!is_ours) return stray();
        seen_.released_at_submit = count_of(seen_.released.size());
        ++seen_.submits;
        return core::ok();
    }

    [[nodiscard]] gpu::Status wait_idle() override {
        if (trip(Call::kWaitIdle)) return broken();
        ++seen_.waits;
        return core::ok();
    }

    [[nodiscard]] gpu::Status end_frame() override {
        ++seen_.end_frames;
        if (plan_.fail_end_frame) return core::fail(core::ErrorCode::kDeviceLost, "end_frame hỏng theo kế hoạch");
        return core::ok();
    }

    // Từ đây xuống là các hàm upload không được gọi.
    [[nodiscard]] const gpu::AdapterInfo& adapter() const noexcept override { return adapter_; }
    [[nodiscard]] const gpu::DeviceCaps& caps() const noexcept override { return caps_; }
    [[nodiscard]] gpu::FormatSupport format_support(gpu::Format) const override { return {}; }
    [[nodiscard]] gpu::MemoryBudget memory_budget() const override { return {}; }
    [[nodiscard]] std::uint64_t validation_errors() const noexcept override { return 0; }
    [[nodiscard]] std::uint64_t address(gpu::BufferHandle) const override { return 0; }
    [[nodiscard]] std::vector<std::byte> pipeline_cache() const override { return {}; }
    [[nodiscard]] gpu::Result<gpu::ShaderHandle> create_shader(const gpu::ShaderDesc&) override { return stray(); }
    [[nodiscard]] gpu::Result<gpu::PipelineHandle> create_pipeline(const gpu::GraphicsPipelineDesc&) override {
        return stray();
    }
    [[nodiscard]] gpu::Result<gpu::PipelineHandle> create_pipeline(const gpu::ComputePipelineDesc&) override {
        return stray();
    }
    [[nodiscard]] gpu::Result<gpu::BindGroupHandle> create_bind_group(const gpu::BindGroupDesc&) override {
        return stray();
    }
    [[nodiscard]] gpu::Result<gpu::QueryPoolHandle> create_query_pool(const gpu::QueryPoolDesc&) override {
        return stray();
    }
    [[nodiscard]] gpu::Status update_bind_group(gpu::BindGroupHandle, std::span<const gpu::BindEntry>) override {
        return stray();
    }
    void destroy(gpu::ShaderHandle) override { note_stray(); }
    void destroy(gpu::PipelineHandle) override { note_stray(); }
    void destroy(gpu::BindGroupHandle) override { note_stray(); }
    void destroy(gpu::QueryPoolHandle) override { note_stray(); }
    [[nodiscard]] gpu::Status read_buffer(gpu::BufferHandle, std::uint64_t, std::span<std::byte>) override {
        return stray();
    }
    [[nodiscard]] gpu::Status read_queries(gpu::QueryPoolHandle, std::uint32_t, std::span<std::uint64_t>) override {
        return stray();
    }
    [[nodiscard]] gpu::Result<std::unique_ptr<gpu::Timeline>> create_timeline(std::uint64_t) override {
        return stray();
    }
    [[nodiscard]] gpu::Result<std::unique_ptr<gpu::Swapchain>> create_swapchain(const gpu::SwapchainDesc&) override {
        return stray();
    }

private:
    // Đếm một lời gọi có thể hỏng; true khi tới lượt nó phải hỏng theo kế hoạch.
    [[nodiscard]] bool trip(Call call) noexcept {
        ++seen_.fallible;
        if (seen_.fallible != plan_.fail_at) return false;
        seen_.tripped = call;
        return true;
    }

    [[nodiscard]] static core::Failure broken() {
        return core::fail(core::ErrorCode::kCorrupt, "lỗi tiêm vào thiết bị giả");
    }

    void note_stray() noexcept { ++seen_.strays; }

    [[nodiscard]] core::Failure stray() {
        note_stray();
        return core::fail(core::ErrorCode::kUnsupported, "upload gọi hàm ngoài hợp đồng của nó");
    }

    template <class Handle>
    [[nodiscard]] Handle open(Kind kind) {
        std::uint32_t& next = next_.at(std::to_underlying(kind));
        const Slot made{.kind = kind, .index = next};
        ++next;
        seen_.live.push_back(made);
        return Handle{.index = made.index, .generation = 1};
    }

    template <class Tag>
    void close(Kind kind, gpu::Handle<Tag> handle) {
        if (!handle.valid()) return;
        const Slot slot{.kind = kind, .index = handle.index};
        const auto found = std::ranges::find(seen_.live, slot);
        if (found == seen_.live.end()) {
            ++seen_.double_frees;
            return;
        }
        seen_.live.erase(found);
        seen_.released.push_back(slot);
    }

    Plan plan_;
    Seen seen_;
    FakeCommands commands_;
    std::array<std::uint32_t, 4> next_{};
    gpu::AdapterInfo adapter_;
    gpu::DeviceCaps caps_;
};

} // namespace game::test
