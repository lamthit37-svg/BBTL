// Thiết bị Vulkan: cài đặt gpu::Device — Vulkan.c của _Ref, vulkan/device.cpp của Platium. Lớp và
// các kiểu ở đây là nội bộ của backend; cài đặt chia theo việc ra device.cpp (vòng đời, hàng đợi,
// nộp lệnh), resources.cpp (buffer, texture, view, sampler, truy vấn, bộ nhớ) và programs.cpp
// (shader, bố cục, pipeline, nhóm gắn). Khác gốc:
// - bộ nhớ chia từ khối lớn (gpu/memory.hpp) thay vì mỗi tài nguyên một vkAllocateMemory;
// - mỗi hàng đợi có một timeline nội bộ đếm lần nộp, làm mốc cho huỷ hoãn và thu hồi command list;
// - descriptor set layout và pipeline layout dựng từ phản chiếu shader, dùng chung theo băm.
// Nguồn: Forge2 src/gpu/vulkan/device.hpp@d7fcd76. Khác gốc (so với Forge2): enumerator mang tiền
// tố k.
#pragma once

#include "gpu/check.hpp"
#include "gpu/device.hpp"
#include "gpu/memory.hpp"
#include "gpu/retire.hpp"
#include "gpu/slots.hpp"
#include "gpu/vulkan/api.hpp"
#include "gpu/vulkan/instance.hpp"

#include <array>
#include <atomic>
#include <memory>
#include <mutex>
#include <unordered_map>
#include <vector>

namespace game::gpu::vulkan {

class Commands;

// Một VkDeviceMemory của MemoryPool; ánh xạ sẵn suốt đời khi CPU nhìn thấy được.
class Block {
public:
    Block(VkDevice device, VkDeviceMemory memory, std::byte* mapped) noexcept
        : device_(device), memory_(memory), mapped_(mapped) {}
    ~Block();
    Block(const Block&) = delete;
    Block& operator=(const Block&) = delete;
    Block(Block&& other) noexcept;
    Block& operator=(Block&& other) noexcept;

    [[nodiscard]] VkDeviceMemory memory() const noexcept { return memory_; }
    // null khi khối nằm trong bộ nhớ CPU không nhìn thấy.
    [[nodiscard]] std::byte* mapped() const noexcept { return mapped_; }
    void set_mapped(std::byte* mapped) noexcept { mapped_ = mapped; }

private:
    VkDevice device_ = VK_NULL_HANDLE;
    VkDeviceMemory memory_ = VK_NULL_HANDLE;
    std::byte* mapped_ = nullptr;
};

using Pool = MemoryPool<Block>;

// Vùng nhớ của một tài nguyên: vùng trong MemoryPool thứ pool.
struct Allocation {
    MemorySpan span{};
    std::uint32_t pool = 0;
};

struct Buffer {
    VkBuffer handle = VK_NULL_HANDLE;
    Allocation memory{};
    std::uint64_t size = 0;
    BufferUsage usage = BufferUsage::kNone;
    MemoryDomain domain = MemoryDomain::kDevice;
    // Chỗ của buffer trong vùng đã ánh xạ; null với buffer Device.
    std::byte* mapped = nullptr;
    std::uint64_t address = 0;
};

struct Texture {
    VkImage handle = VK_NULL_HANDLE;
    Allocation memory{};
    // Mô tả lúc tạo, tên đã bỏ (string_view của chỗ gọi không sống tới đây).
    TextureDesc desc{};
    // false cho ảnh của swapchain: ảnh thuộc VkSwapchainKHR, không huỷ ở đây.
    bool is_owned = true;
};

struct View {
    VkImageView handle = VK_NULL_HANDLE;
    TextureHandle texture{};
    ViewRange range{};
    // Cỡ của mức mip đầu trong view và số mẫu: vùng vẽ mặc định của begin_rendering.
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::uint32_t samples = 1;
};

struct Sampler {
    VkSampler handle = VK_NULL_HANDLE;
};

struct Shader {
    VkShaderModule handle = VK_NULL_HANDLE;
    shader::StageReflection reflection{};
};

// Bố cục gắn của một chương trình, dùng chung giữa mọi pipeline có cùng băm bố cục. Sống tới khi
// thiết bị bị huỷ; pipeline và nhóm gắn trỏ vào.
struct Layout {
    VkPipelineLayout handle = VK_NULL_HANDLE;
    std::array<VkDescriptorSetLayout, kMaxBindGroups> sets{};
    ProgramLayout program{};
    VkShaderStageFlags push_stages = 0;
    // Bit s bật khi register space s có tài nguyên: các nhóm phải gắn trước khi vẽ.
    std::uint32_t used = 0;
};

struct Pipeline {
    VkPipeline handle = VK_NULL_HANDLE;
    VkPipelineBindPoint point = VK_PIPELINE_BIND_POINT_GRAPHICS;
    const Layout* layout = nullptr;
};

struct BindGroup {
    VkDescriptorSet set = VK_NULL_HANDLE;
    VkDescriptorPool pool = VK_NULL_HANDLE;
    // Nhóm có mảng không chặn giữ riêng một pool; nhóm thường lấy set từ pool chung.
    bool owns_pool = false;
    const Layout* layout = nullptr;
    std::uint32_t space = 0;
    std::uint32_t capacity = 0;
};

struct QueryPool {
    VkQueryPool handle = VK_NULL_HANDLE;
    QueryKind kind = QueryKind::kTimestamp;
    std::uint32_t count = 0;
    QueueType queue = QueueType::kGraphics;
};

// Tính năng tuỳ chọn của thiết bị mà backend rẽ nhánh theo, ngoài phần lộ ra ở DeviceCaps.
struct Traits {
    bool swapchain = false;
    bool memory_budget = false;
    // Địa chỉ GPU của buffer (BufferUsage::kAddress).
    bool address = false;
    // Nhiều lệnh vẽ gián tiếp trong một lời gọi; thiếu thì backend lặp từng lệnh.
    bool multi_draw = false;
    bool bias_clamp = false;
};

// Một hàng đợi vật lý. Hàng đợi thiếu trên thiết bị dùng chung hàng Graphics.
struct Queue {
    VkQueue handle = VK_NULL_HANDLE;
    std::uint32_t family = 0;
    // Số bit hợp lệ của dấu thời gian; 0 là hàng đợi không ghi được.
    std::uint32_t timestamp_bits = 0;
    // Timeline nội bộ: lần nộp thứ n phát giá trị n.
    VkSemaphore progress = VK_NULL_HANDLE;
    // vkQueueSubmit và vkQueuePresentKHR đòi đồng bộ ngoài; mutex cũng bảo vệ việc tăng submitted.
    std::mutex mutex;
    std::atomic<std::uint64_t> submitted{0};
};

// Adapter đạt mức tối thiểu của backend, theo thứ tự ưu tiên (gpu::enumerate_adapters).
[[nodiscard]] Result<std::vector<AdapterInfo>> adapters();

class VulkanDevice final : public Device {
public:
    [[nodiscard]] static Result<std::unique_ptr<Device>> create(const DeviceDesc& desc);

    // Định nghĩa trong device.cpp: Contexts chỉ đầy đủ ở đó.
    explicit VulkanDevice(std::unique_ptr<Instance> instance) noexcept;
    ~VulkanDevice() override;
    VulkanDevice(const VulkanDevice&) = delete;
    VulkanDevice& operator=(const VulkanDevice&) = delete;
    VulkanDevice(VulkanDevice&&) = delete;
    VulkanDevice& operator=(VulkanDevice&&) = delete;

    [[nodiscard]] const AdapterInfo& adapter() const noexcept override { return adapter_; }
    [[nodiscard]] const DeviceCaps& caps() const noexcept override { return caps_; }
    [[nodiscard]] FormatSupport format_support(Format format) const override;
    [[nodiscard]] MemoryBudget memory_budget() const override;
    [[nodiscard]] DeviceLoss loss() const noexcept override { return loss_.load(); }
    [[nodiscard]] std::uint64_t validation_errors() const noexcept override { return instance_->errors(); }

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

    // Phần dưới dùng trong backend: command list, swapchain, timeline.
    [[nodiscard]] VkDevice handle() const noexcept { return device_; }
    [[nodiscard]] VkPhysicalDevice physical() const noexcept { return physical_; }
    [[nodiscard]] const Instance& instance() const noexcept { return *instance_; }
    [[nodiscard]] const DebugApi& debug() const noexcept { return debug_; }
    [[nodiscard]] Queue& queue(QueueType type) noexcept {
        return queues_.at(queue_index_.at(std::to_underlying(type)));
    }

    [[nodiscard]] const Buffer* find(BufferHandle handle) const noexcept { return buffers_.find(handle); }
    [[nodiscard]] const Texture* find(TextureHandle handle) const noexcept { return textures_.find(handle); }
    [[nodiscard]] const View* find(TextureViewHandle handle) const noexcept { return views_.find(handle); }
    [[nodiscard]] const Sampler* find(SamplerHandle handle) const noexcept { return samplers_.find(handle); }
    [[nodiscard]] const Shader* find(ShaderHandle handle) const noexcept { return shaders_.find(handle); }
    [[nodiscard]] const Pipeline* find(PipelineHandle handle) const noexcept { return pipelines_.find(handle); }
    [[nodiscard]] const BindGroup* find(BindGroupHandle handle) const noexcept { return groups_.find(handle); }
    [[nodiscard]] const QueryPool* find(QueryPoolHandle handle) const noexcept { return queries_.find(handle); }

    // Ảnh của swapchain vào bảng texture; không sở hữu VkImage.
    [[nodiscard]] TextureHandle adopt(VkImage image, const TextureDesc& desc);
    // Gỡ ảnh và view của swapchain khỏi bảng ngay (swapchain đã chờ GPU rỗi).
    void release(TextureHandle handle);
    void release(TextureViewHandle handle);
    // Số thứ tự lần nộp mới nhất mà GPU đã chạy xong trên hàng đợi của type.
    [[nodiscard]] std::uint64_t completed(QueueType type) const noexcept;

    // Gắn tên cho một đối tượng Vulkan; không làm gì khi không có VK_EXT_debug_utils.
    void set_name(VkObjectType type, std::uint64_t object, std::string_view name) const;
    // Ghi nhận mất thiết bị khi result là VK_ERROR_DEVICE_LOST, rồi trả lỗi của lời gọi.
    [[nodiscard]] core::Failure failed(VkResult result, core::Message message) noexcept;
    // Số thứ tự lần nộp mới nhất của từng hàng đợi: mốc cho việc huỷ hoãn.
    [[nodiscard]] QueueMarks marks() const noexcept;
    void retire(Retired::Action action) { retired_.push(marks(), std::move(action)); }
    [[nodiscard]] const Traits& traits() const noexcept { return traits_; }
    [[nodiscard]] const VkPhysicalDeviceLimits& limits() const noexcept { return limits_; }

private:
    struct Contexts;

    [[nodiscard]] Status start(const PhysicalDevice& physical, const DeviceDesc& desc);
    [[nodiscard]] Status pick_queues();
    [[nodiscard]] Status create_device();
    [[nodiscard]] Status create_queues();
    void read_caps(const VkPhysicalDeviceVulkan12Properties& indexing);
    void create_cache(std::span<const std::byte> data);
    [[nodiscard]] QueueMarks completed() const noexcept;
    void recycle(const QueueMarks& done);
    [[nodiscard]] Result<std::unique_ptr<Commands>> create_commands(QueueType queue);

    // Giải phóng ngay các đối tượng Vulkan của một tài nguyên đã rời bảng. Gọi từ hàng huỷ hoãn khi
    // GPU đã qua mốc, và từ destructor.
    void discard(Buffer& buffer) noexcept;
    void discard(Texture& texture) noexcept;
    void discard(View& view) noexcept;
    void discard(Sampler& sampler) noexcept;
    void discard(Shader& shader) noexcept;
    void discard(Pipeline& pipeline) noexcept;
    void discard(BindGroup& group) noexcept;
    void discard(QueryPool& pool) noexcept;
    void discard(Layout& layout) noexcept;
    template <class T, class Tag>
    void discard_all(Slots<T, Tag>& table) noexcept;
    void discard_layouts() noexcept;
    // Gỡ tài nguyên khỏi bảng (tay nắm chết ngay) rồi hẹn giải phóng khi GPU qua mốc hiện tại.
    template <class T, class Tag>
    void retire_from(Slots<T, Tag>& table, Handle<Tag> handle);

    [[nodiscard]] Result<Allocation> allocate(const VkMemoryRequirements& needs, MemoryDomain domain, bool is_image,
        bool is_transient);
    void free(const Allocation& allocation) noexcept;
    [[nodiscard]] Pool& pool_at(std::uint32_t index);
    // Gắn tài nguyên vào vùng nhớ đã cấp cho nó.
    [[nodiscard]] Status bind(Buffer& buffer);
    [[nodiscard]] Status bind(Texture& texture);

    [[nodiscard]] Result<const Layout*> layout_for(const ProgramLayout& program);
    [[nodiscard]] Status fill_layout(Layout& layout, const ProgramLayout& program);
    [[nodiscard]] Result<VkDescriptorSetLayout> create_set_layout(const SpaceLayout& space);
    [[nodiscard]] Result<PipelineHandle> keep(Pipeline& pipeline, std::string_view name);
    // Pool chung mới cho các nhóm thường; gọi khi đang giữ set_mutex_.
    [[nodiscard]] Result<VkDescriptorPool> add_set_pool();
    // Thử từng pool chung, bắt đầu từ pool vừa cấp được lần trước; gọi khi đang giữ set_mutex_.
    [[nodiscard]] VkResult take_set(VkDescriptorSetAllocateInfo& info, VkDescriptorSet& set);
    [[nodiscard]] Status allocate_set(BindGroup& group, const SpaceLayout& space);
    // Pool riêng vừa đúng một set: cho nhóm có mảng không chặn, và cho nhóm quá lớn so với pool
    // chung.
    [[nodiscard]] Status allocate_own_set(BindGroup& group, const SpaceLayout& space);
    [[nodiscard]] Status write_group(const BindGroup& group, std::span<const BindEntry> entries);

    std::unique_ptr<Instance> instance_;
    VkPhysicalDevice physical_ = VK_NULL_HANDLE;
    VkDevice device_ = VK_NULL_HANDLE;
    AdapterInfo adapter_{};
    DeviceCaps caps_{};
    DebugApi debug_{};
    VkPhysicalDeviceMemoryProperties memory_{};
    VkPhysicalDeviceLimits limits_{};
    Traits traits_{};
    std::atomic<DeviceLoss> loss_{DeviceLoss::kNone};

    // Hàng đợi vật lý (tối đa ba) và hàng của từng QueueType.
    std::array<Queue, kQueueCount> queues_{};
    std::array<std::uint32_t, kQueueCount> queue_index_{};
    std::uint32_t queue_count_ = 0;

    Slots<Buffer, BufferTag> buffers_;
    Slots<Texture, TextureTag> textures_;
    Slots<View, TextureViewTag> views_;
    Slots<Sampler, SamplerTag> samplers_;
    Slots<Shader, ShaderTag> shaders_;
    Slots<Pipeline, PipelineTag> pipelines_;
    Slots<BindGroup, BindGroupTag> groups_;
    Slots<QueryPool, QueryPoolTag> queries_;
    Retired retired_;

    // memory_mutex_ bảo vệ việc dựng pool; mỗi pool tự khoá khi cấp và trả.
    std::mutex memory_mutex_;
    std::array<std::unique_ptr<Pool>, std::size_t{VK_MAX_MEMORY_TYPES} * 2> pools_{};

    // layout_mutex_ bảo vệ layouts_.
    std::mutex layout_mutex_;
    std::unordered_map<std::uint64_t, std::unique_ptr<Layout>> layouts_;
    // set_mutex_ bảo vệ set_pools_, set_cursor_ và mọi lần cấp, trả set từ các pool ấy.
    std::mutex set_mutex_;
    std::vector<VkDescriptorPool> set_pools_;
    std::size_t set_cursor_ = 0;
    VkPipelineCache cache_ = VK_NULL_HANDLE;

    std::unique_ptr<Contexts> contexts_;
};

} // namespace game::gpu::vulkan
