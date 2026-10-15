// Danh sách lệnh của backend Vulkan: một VkCommandPool kèm đúng một VkCommandBuffer, nên thu hồi
// là một lần vkResetCommandPool và hai luồng không bao giờ chung pool (Vulkan cấm). Platium giữ
// pool theo luồng theo khung; ở đây pool đi theo danh sách lệnh, luồng nào xin cũng được. Lệnh ghi
// sai (tay nắm chết, thiếu pipeline) không sập và không đi xuống trình điều khiển: lỗi đầu tiên
// được giữ lại, các lệnh sau bị bỏ, và Device::submit trả lỗi ấy thay vì nộp. Không lệnh nào cấp
// phát bộ nhớ sau khi các vùng tạm của danh sách đã đủ lớn.
// Nguồn: Forge2 src/gpu/vulkan/commands.hpp@d7fcd76. Khác gốc: enumerator của State mang tiền tố k;
// bỏ {} thừa của error_.
#pragma once

#include "gpu/command.hpp"
#include "gpu/vulkan/api.hpp"
#include "gpu/vulkan/device.hpp"
#include "gpu/vulkan/passes.hpp"

#include <array>
#include <string>
#include <vector>

namespace game::gpu::vulkan {

class Commands final : public CommandList {
public:
    Commands(VulkanDevice& device, QueueType queue, VkCommandPool pool, VkCommandBuffer buffer) noexcept
        : device_(&device), queue_(queue), pool_(pool), buffer_(buffer) {}
    ~Commands() override;
    Commands(const Commands&) = delete;
    Commands& operator=(const Commands&) = delete;
    Commands(Commands&&) = delete;
    Commands& operator=(Commands&&) = delete;

    [[nodiscard]] QueueType queue() const noexcept override { return queue_; }
    void begin_label(std::string_view name) override;
    void end_label() override;
    void insert_label(std::string_view name) override;
    void barrier(std::span<const BufferBarrier> buffers, std::span<const TextureBarrier> textures,
        std::span<const GlobalBarrier> memory) override;
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

    // Phần dưới do VulkanDevice gọi.
    enum class State : std::uint8_t {
        // Nằm trong hàng rảnh của thiết bị.
        kIdle,
        // Đang nhận lệnh.
        kRecording,
        // Đã đóng, chờ nộp.
        kClosed,
        // Đã nộp, GPU chưa chạy xong.
        kPending,
    };

    [[nodiscard]] VkCommandBuffer buffer() const noexcept { return buffer_; }
    [[nodiscard]] State state() const noexcept { return state_; }
    // Đưa pool về trống và mở buffer để ghi.
    [[nodiscard]] Status open();
    // Đóng buffer để nộp. Trả lỗi ghi lệnh đầu tiên nếu có, hoặc lỗi khi còn begin_rendering hay
    // nhãn chưa đóng. Gọi lại trên danh sách đã đóng thì trả đúng kết quả lần trước.
    [[nodiscard]] Status close();
    void mark_pending() noexcept { state_ = State::kPending; }
    void mark_idle() noexcept { state_ = State::kIdle; }
    // Bỏ buffer đang ghi mà không nộp. Pool reset ở lần mở sau chỉ hợp lệ khi buffer không còn pending.
    void discard() noexcept;

private:
    // true khi lệnh được ghi xuống trình điều khiển: danh sách đang mở và chưa có lệnh nào sai.
    [[nodiscard]] bool live();
    // Giữ lỗi đầu tiên của một lệnh ghi sai và ngừng ghi xuống trình điều khiển.
    void reject(core::Failure failure);
    [[nodiscard]] const Buffer* need(BufferHandle handle, BufferUsage usage, core::Message message);
    [[nodiscard]] const Texture* need(TextureHandle handle, TextureUsage usage, core::Message message);
    [[nodiscard]] const View* need(TextureViewHandle handle, core::Message message);
    [[nodiscard]] const QueryPool* need(QueryPoolHandle handle, QueryKind kind, std::uint32_t first,
        std::uint32_t count);
    // Buffer tham số của lệnh gián tiếp, đã kiểm count lệnh cách nhau stride byte nằm trong buffer.
    [[nodiscard]] const Buffer* need_arguments(BufferHandle handle, std::uint64_t offset, std::uint32_t count,
        std::uint32_t stride, std::uint32_t size);
    // Sẵn sàng vẽ: đang trong begin_rendering, pipeline đồ hoạ đã gắn, đủ nhóm gắn.
    [[nodiscard]] bool can_draw();
    [[nodiscard]] bool can_dispatch();
    void add_barrier(const BufferBarrier& item);
    void add_barrier(const TextureBarrier& item);
    [[nodiscard]] bool fill_color(ColorAttach& attach, const ColorTarget& target);
    [[nodiscard]] DepthAttach depth_of(const DepthTarget& target, const View& view) const noexcept;
    // View của attachment độ sâu; nullptr khi đã chết hoặc không phải định dạng độ sâu.
    [[nodiscard]] const View* need_depth(TextureViewHandle handle);
    // Vùng vẽ mặc định: cỡ của attachment đầu tiên.
    void note_extent(const View& view) noexcept;
    [[nodiscard]] bool fill_regions(const Buffer& buffer, const Texture& texture,
        std::span<const BufferTextureCopy> regions);
    void set_label(VkDebugUtilsLabelEXT& label, std::string_view name);

    VulkanDevice* device_;
    QueueType queue_;
    VkCommandPool pool_;
    VkCommandBuffer buffer_;
    State state_ = State::kIdle;
    bool is_live_ = false;
    bool is_rendering_ = false;
    bool has_warned_ = false;
    std::uint32_t open_labels_ = 0;
    // Khác gốc: bỏ {} mà clang-tidy báo thừa.
    Status error_;
    // Bản chép của pipeline đang gắn (tay nắm có thể chết giữa chừng; Layout sống tới hết thiết bị)
    // và các register space đã có nhóm gắn kể từ lần bố cục đổi.
    Pipeline pipeline_{};
    std::uint32_t bound_ = 0;
    VkExtent2D extent_{};
    // Vùng tạm dùng lại giữa các lệnh.
    std::vector<VkBufferMemoryBarrier> buffer_barriers_;
    std::vector<VkImageMemoryBarrier> image_barriers_;
    std::vector<VkMemoryBarrier> memory_barriers_;
    // Giai đoạn gộp của lần barrier đang dựng (sync1 chỉ có một cặp).
    VkPipelineStageFlags barrier_src_ = 0;
    VkPipelineStageFlags barrier_dst_ = 0;
    std::vector<VkBufferImageCopy> regions_;
    std::string label_;
};

} // namespace game::gpu::vulkan
