/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/vulkan/device.cpp
 *  PHÂN HỆ   : Gpu / Vulkan / Device
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Vòng đời thiết bị, hàng đợi, fence, timeline, nộp lệnh và ranh giới khung
 *    hình của backend Vulkan. Mức tối thiểu 1.1 (api.hpp): không timeline
 *    semaphore, nên "lần nộp thứ n đã xong" là fence của lần nộp ấy
 *    (Queue::flights), và Timeline của chỗ gọi là bộ đếm CPU tiến lên theo các
 *    fence đó. Nguồn: Forge2 src/gpu/vulkan/device.cpp@d7fcd76.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Khác gốc: enumerator mang tiền tố k; include trực tiếp header của mọi tên dùng tới; hàm dài hoặc
// có nhánh trong thân vòng lặp tách hàm ở ranh giới câu lệnh, thứ tự lời gọi Vulkan và phép kiểm
// lỗi giữ nguyên (ghi tại chỗ): fill đưa điều kiện dừng lên điều kiện lặp; pick_queues tách
// take_family; create_device tách pick_extensions; create_queues tách start_queue; begin_commands
// tách Contexts::refill; submit tách find_target; wait_idle tách wait_queue; handle Vulkan cục bộ
// khai auto* const; NOLINT kèm lý do cho các hàm noexcept của gốc và hai chữ ký có tham số cùng
// kiểu.

#include "gpu/vulkan/device.hpp"

#include "core/error.hpp"
#include "core/log.hpp"
#include "gpu/command.hpp"
#include "gpu/device.hpp"
#include "gpu/retire.hpp"
#include "gpu/slots.hpp"
#include "gpu/types.hpp"
#include "gpu/vulkan/api.hpp"
#include "gpu/vulkan/commands.hpp"
#include "gpu/vulkan/convert.hpp"
#include "gpu/vulkan/instance.hpp"
#include "gpu/vulkan/swapchain.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <expected>
#include <memory>
#include <mutex>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <thread>
#include <utility>
#include <vector>

#include <vulkan/vulkan_core.h>

namespace game::gpu::vulkan {

namespace {

using core::ErrorCode;
using core::fail;
using core::ok;

[[nodiscard]] std::vector<VkQueueFamilyProperties> families(VkPhysicalDevice device) {
    std::uint32_t count = 0;
    vkGetPhysicalDeviceQueueFamilyProperties(device, &count, nullptr);
    std::vector<VkQueueFamilyProperties> list(count);
    vkGetPhysicalDeviceQueueFamilyProperties(device, &count, list.data());
    list.resize(count);
    return list;
}

// Family đầu tiên có mọi cờ của wanted và không có cờ nào của excluded; rỗng khi không có.
// Nội bộ, chỉ pick_queues gọi (lệch API-03).
// NOLINTBEGIN(bugprone-easily-swappable-parameters)
[[nodiscard]] std::optional<std::uint32_t> find_family(std::span<const VkQueueFamilyProperties> list,
    VkQueueFlags wanted, VkQueueFlags excluded) {
    const auto fits = [=](const VkQueueFamilyProperties& family) {
        const bool has_wanted = (family.queueFlags & wanted) == wanted;
        return family.queueCount != 0 && has_wanted && (family.queueFlags & excluded) == 0;
    };
    const auto found = std::ranges::find_if(list, fits);
    if (found == list.end()) return std::nullopt;
    return static_cast<std::uint32_t>(found - list.begin());
}
// NOLINTEND(bugprone-easily-swappable-parameters)

[[nodiscard]] std::vector<VkExtensionProperties> device_extensions(VkPhysicalDevice device) {
    std::uint32_t count = 0;
    vkEnumerateDeviceExtensionProperties(device, nullptr, &count, nullptr);
    std::vector<VkExtensionProperties> list(count);
    vkEnumerateDeviceExtensionProperties(device, nullptr, &count, list.data());
    list.resize(count);
    return list;
}

[[nodiscard]] bool has_extension(std::span<const VkExtensionProperties> list, std::string_view name) {
    const auto matches = [name](const auto& item) {
        return name == std::string_view(static_cast<const char*>(item.extensionName));
    };
    return std::ranges::any_of(list, matches);
}

// Chuỗi tính năng: lõi 1.0, tham số draw của 1.1, và bộ 1.2 chỉ khi thiết bị và instance đạt 1.2 (bộ
// 1.2 trong pNext của thiết bị 1.1 là cấu trúc lạ). Nối bằng link(), không nối sẵn: struct không dời.
struct Features {
    VkPhysicalDeviceFeatures2 base{};
    VkPhysicalDeviceShaderDrawParametersFeatures draw{};
    VkPhysicalDeviceVulkan12Features v12{};

    Features() noexcept {
        base.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2;
        draw.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_DRAW_PARAMETERS_FEATURES;
        v12.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES;
    }
    // pNext trỏ vào chính đối tượng: chép hay dời là trỏ sai.
    Features(const Features&) = delete;
    Features& operator=(const Features&) = delete;
    Features(Features&&) = delete;
    Features& operator=(Features&&) = delete;
    ~Features() = default;

    // Nối base, draw và (khi has_v12) v12; trả đầu chuỗi.
    void link(bool has_v12) noexcept {
        base.pNext = &draw;
        draw.pNext = has_v12 ? static_cast<void*>(&v12) : nullptr;
    }
};

// Phần lõi của 1.0 mà engine dùng khi thiết bị có. robustBufferAccess cố ý không bật: nó chèn kiểm
// biên vào mọi lần đọc buffer.
void enable_base(VkPhysicalDeviceFeatures& wanted, const VkPhysicalDeviceFeatures& has) noexcept {
    wanted.independentBlend = has.independentBlend;
    wanted.geometryShader = has.geometryShader;
    wanted.tessellationShader = has.tessellationShader;
    wanted.sampleRateShading = has.sampleRateShading;
    wanted.multiDrawIndirect = has.multiDrawIndirect;
    wanted.drawIndirectFirstInstance = has.drawIndirectFirstInstance;
    wanted.depthClamp = has.depthClamp;
    wanted.depthBiasClamp = has.depthBiasClamp;
    wanted.fillModeNonSolid = has.fillModeNonSolid;
    wanted.depthBounds = has.depthBounds;
    wanted.samplerAnisotropy = has.samplerAnisotropy;
    wanted.textureCompressionETC2 = has.textureCompressionETC2;
    wanted.textureCompressionASTC_LDR = has.textureCompressionASTC_LDR;
    wanted.textureCompressionBC = has.textureCompressionBC;
    wanted.occlusionQueryPrecise = has.occlusionQueryPrecise;
    wanted.vertexPipelineStoresAndAtomics = has.vertexPipelineStoresAndAtomics;
    wanted.fragmentStoresAndAtomics = has.fragmentStoresAndAtomics;
    wanted.shaderStorageImageExtendedFormats = has.shaderStorageImageExtendedFormats;
    wanted.shaderStorageImageReadWithoutFormat = has.shaderStorageImageReadWithoutFormat;
    wanted.shaderStorageImageWriteWithoutFormat = has.shaderStorageImageWriteWithoutFormat;
    wanted.shaderUniformBufferArrayDynamicIndexing = has.shaderUniformBufferArrayDynamicIndexing;
    wanted.shaderSampledImageArrayDynamicIndexing = has.shaderSampledImageArrayDynamicIndexing;
    wanted.shaderStorageBufferArrayDynamicIndexing = has.shaderStorageBufferArrayDynamicIndexing;
    wanted.shaderStorageImageArrayDynamicIndexing = has.shaderStorageImageArrayDynamicIndexing;
    wanted.shaderClipDistance = has.shaderClipDistance;
    wanted.shaderCullDistance = has.shaderCullDistance;
    wanted.shaderInt16 = has.shaderInt16;
    wanted.shaderInt64 = has.shaderInt64;
    wanted.imageCubeArray = has.imageCubeArray;
}

void enable_v12(VkPhysicalDeviceVulkan12Features& wanted, const VkPhysicalDeviceVulkan12Features& has) noexcept {
    wanted.bufferDeviceAddress = has.bufferDeviceAddress;
    wanted.scalarBlockLayout = has.scalarBlockLayout;
    wanted.descriptorIndexing = has.descriptorIndexing;
    wanted.runtimeDescriptorArray = has.runtimeDescriptorArray;
    wanted.descriptorBindingPartiallyBound = has.descriptorBindingPartiallyBound;
    wanted.descriptorBindingVariableDescriptorCount = has.descriptorBindingVariableDescriptorCount;
    wanted.descriptorBindingUpdateUnusedWhilePending = has.descriptorBindingUpdateUnusedWhilePending;
    wanted.descriptorBindingSampledImageUpdateAfterBind = has.descriptorBindingSampledImageUpdateAfterBind;
    wanted.descriptorBindingStorageImageUpdateAfterBind = has.descriptorBindingStorageImageUpdateAfterBind;
    wanted.descriptorBindingStorageBufferUpdateAfterBind = has.descriptorBindingStorageBufferUpdateAfterBind;
    wanted.descriptorBindingUniformBufferUpdateAfterBind = has.descriptorBindingUniformBufferUpdateAfterBind;
    wanted.shaderSampledImageArrayNonUniformIndexing = has.shaderSampledImageArrayNonUniformIndexing;
    wanted.shaderStorageImageArrayNonUniformIndexing = has.shaderStorageImageArrayNonUniformIndexing;
    wanted.shaderStorageBufferArrayNonUniformIndexing = has.shaderStorageBufferArrayNonUniformIndexing;
    wanted.shaderUniformBufferArrayNonUniformIndexing = has.shaderUniformBufferArrayNonUniformIndexing;
}

// Mảng không chặn dùng được khi đủ cả bộ tính năng của descriptor indexing.
[[nodiscard]] bool has_bindless(const VkPhysicalDeviceVulkan12Features& has) noexcept {
    const bool has_arrays = has.runtimeDescriptorArray != VK_FALSE && has.descriptorBindingPartiallyBound != VK_FALSE &&
        has.descriptorBindingVariableDescriptorCount != VK_FALSE &&
        has.descriptorBindingUpdateUnusedWhilePending != VK_FALSE;
    const bool has_updates = has.descriptorBindingSampledImageUpdateAfterBind != VK_FALSE &&
        has.descriptorBindingStorageImageUpdateAfterBind != VK_FALSE &&
        has.descriptorBindingStorageBufferUpdateAfterBind != VK_FALSE;
    return has_arrays && has_updates && has.shaderSampledImageArrayNonUniformIndexing != VK_FALSE;
}

// Tính năng tuỳ chọn mà chỗ gọi hỏi được (caps) và backend rẽ nhánh theo (traits).
void read_features(DeviceCaps& caps, Traits& traits, const Features& has) noexcept {
    const VkPhysicalDeviceFeatures& base = has.base.features;
    caps.bindless = has_bindless(has.v12);
    caps.tessellation = base.tessellationShader != VK_FALSE;
    caps.geometry_shader = base.geometryShader != VK_FALSE;
    caps.depth_bounds = base.depthBounds != VK_FALSE;
    caps.depth_clamp = base.depthClamp != VK_FALSE;
    caps.wireframe = base.fillModeNonSolid != VK_FALSE;
    caps.independent_blend = base.independentBlend != VK_FALSE;
    caps.precise_occlusion = base.occlusionQueryPrecise != VK_FALSE;
    traits.address = has.v12.bufferDeviceAddress != VK_FALSE;
    traits.multi_draw = base.multiDrawIndirect != VK_FALSE;
    traits.bias_clamp = base.depthBiasClamp != VK_FALSE;
}

// Trần của một mảng không chặn: giới hạn nhỏ nhất trong limits chia cho số mảng một pipeline được
// có cộng một phần cho các chỗ gắn cỡ cố định, không quá ceiling.
[[nodiscard]] std::uint32_t unbounded_most(std::span<const std::uint32_t> limits, std::uint32_t ceiling) noexcept {
    return std::min(std::ranges::min(limits) / (kMaxUnboundedArrays + 1), ceiling);
}

// Phần đầu của dữ liệu VkPipelineCache theo đặc tả: 32 byte.
struct CacheHeader {
    std::uint32_t size = 0;
    std::uint32_t version = 0;
    std::uint32_t vendor = 0;
    std::uint32_t device = 0;
    std::array<std::uint8_t, VK_UUID_SIZE> uuid{};
};

// Cache của thiết bị khác hay bản trình điều khiển khác thì bỏ: trình điều khiển không bắt buộc
// phải tự kiểm.
[[nodiscard]] bool is_cache_usable(std::span<const std::byte> data, const VkPhysicalDeviceProperties& device) noexcept {
    CacheHeader header;
    if (data.size() < sizeof(header)) return false;
    std::memcpy(&header, data.data(), sizeof(header));
    const bool is_same_device = header.vendor == device.vendorID && header.device == device.deviceID;
    const bool is_same_driver = std::memcmp(header.uuid.data(), std::data(device.pipelineCacheUUID), VK_UUID_SIZE) == 0;
    const bool is_known = header.version == VK_PIPELINE_CACHE_HEADER_VERSION_ONE;
    return header.size == sizeof(header) && is_known && is_same_device && is_same_driver;
}

// Timeline của chỗ gọi: bộ đếm CPU (TimelineState) do các fence của lần nộp đẩy tiến.
class TimelineVk final : public Timeline {
public:
    TimelineVk(VulkanDevice& device, std::shared_ptr<TimelineState> state) noexcept
        : device_(&device), state_(std::move(state)) {}
    ~TimelineVk() override = default;
    TimelineVk(const TimelineVk&) = delete;
    TimelineVk& operator=(const TimelineVk&) = delete;
    TimelineVk(TimelineVk&&) = delete;
    TimelineVk& operator=(TimelineVk&&) = delete;

    [[nodiscard]] const std::shared_ptr<TimelineState>& state() const noexcept { return state_; }

    [[nodiscard]] std::uint64_t completed() const noexcept override {
        device_->poll_all();
        return state_->value.load();
    }

    [[nodiscard]] Status wait(std::uint64_t value, std::chrono::nanoseconds timeout) override {
        return device_->wait_state(*state_, value, timeout);
    }

    void signal(std::uint64_t value) override {
        std::uint64_t seen = state_->value.load();
        while (seen < value && !state_->value.compare_exchange_weak(seen, value)) {
        }
    }

private:
    VulkanDevice* device_;
    std::shared_ptr<TimelineState> state_;
};

// Mọi thứ của một lần nộp, dựng xong rồi mới khoá hàng đợi.
struct Submission {
    std::vector<VkSemaphore> waits;
    std::vector<VkPipelineStageFlags> wait_stages;
    std::vector<VkSemaphore> signals;
    std::vector<VkCommandBuffer> buffers;
    std::vector<Commands*> lists;
    std::vector<FlightSignal> flight_signals;
};

[[nodiscard]] Status add_list(Submission& submission, CommandList* list, QueueType queue) {
    auto* const commands = dynamic_cast<Commands*>(list);
    if (commands == nullptr) return fail(ErrorCode::kInvalidArgument, "submit: list không hợp lệ");
    if (commands->queue() != queue) {
        return fail(ErrorCode::kInvalidArgument, "submit: list ghi cho hàng đợi khác");
    }
    for (const Commands* const held : submission.lists) {
        if (held == commands) return fail(ErrorCode::kInvalidArgument, "submit: cùng một list hai lần");
    }
    const Status closed = commands->close();
    if (!closed) return closed;
    submission.buffers.push_back(commands->buffer());
    submission.lists.push_back(commands);
    return ok();
}

// Không có timeline semaphore: chờ một Timeline là chờ CPU tới khi nó đạt giá trị, rồi mới nộp. Đúng
// cho tín hiệu của lần nộp trước và của CPU; chưa dùng ở đâu trong engine.
[[nodiscard]] Status add_wait(const SubmitWait& wait) {
    auto* const timeline = dynamic_cast<TimelineVk*>(wait.timeline);
    if (timeline == nullptr) return fail(ErrorCode::kInvalidArgument, "submit: timeline chờ lạ");
    constexpr std::chrono::seconds kWaitPatience{10};
    return timeline->wait(wait.value, kWaitPatience);
}

[[nodiscard]] Status add_signal(Submission& submission, const SubmitSignal& signal) {
    const auto* const timeline = dynamic_cast<const TimelineVk*>(signal.timeline);
    if (timeline == nullptr) return fail(ErrorCode::kInvalidArgument, "submit: timeline báo lạ");
    submission.flight_signals.push_back({.state = timeline->state(), .value = signal.value});
    return ok();
}

// Khác gốc: thân ba vòng lặp của gốc có `if (!added) return added;`; ở đây điều kiện dừng
// nằm ở điều kiện lặp, nên lỗi đầu tiên vẫn chặn mọi phần tử và mọi vòng lặp đứng sau nó.
[[nodiscard]] Status fill(Submission& submission, QueueType queue, const SubmitDesc& desc) {
    Status added = ok();
    for (auto list = desc.lists.begin(); list != desc.lists.end() && added; ++list) {
        added = add_list(submission, *list, queue);
    }
    for (auto wait = desc.waits.begin(); wait != desc.waits.end() && added; ++wait) {
        added = add_wait(*wait);
    }
    for (auto signal = desc.signals.begin(); signal != desc.signals.end() && added; ++signal) {
        added = add_signal(submission, *signal);
    }
    return added;
}

// Khác gốc: phần kiểm present_target của submit tách ra đây (hàm gốc dài quá 40 dòng).
// Trả swapchain mà lần nộp này trình bày, null khi lần nộp không đặt present_target.
[[nodiscard]] Result<SwapchainVk*> find_target(QueueType queue, const SubmitDesc& desc) {
    auto* const target = dynamic_cast<SwapchainVk*>(desc.present_target);
    const bool has_target = desc.present_target != nullptr;
    const bool is_presentable = target != nullptr && queue == QueueType::kGraphics;
    if (has_target && !is_presentable) {
        return fail(ErrorCode::kInvalidArgument, "submit: present_target lạ hoặc ngoài hàng Graphics");
    }
    if (has_target && !target->is_awaiting_submit()) {
        return fail(ErrorCode::kInvalidState, "submit: present_target chưa acquire hoặc đã được nộp");
    }
    return target;
}

using Queues = std::array<Queue, kQueueCount>;
using Family = std::optional<std::uint32_t>;
using Families = std::vector<VkQueueFamilyProperties>;

// Khác gốc: phần thân vòng lặp của pick_queues sau `if (!family) continue;` tách ra đây.
// Hàng vật lý thứ count nhận family rồi count tăng một; family rỗng thì không đổi gì.
void take_family(Queues& queues, std::uint32_t& count, Family family, const Families& list) {
    if (!family) return;
    Queue& queue = queues.at(count);
    queue.family = *family;
    queue.timestamp_bits = list.at(*family).timestampValidBits;
    ++count;
}

// Tên phần mở rộng: hằng của SDK.
using Names = std::vector<const char*>;

// Khác gốc: khối chọn phần mở rộng của create_device tách ra đây (hàm gốc dài quá 40 dòng). Ghi
// vào caps và traits phần mở rộng thiết bị có, trả tên các phần mở rộng sẽ bật.
[[nodiscard]] Names pick_extensions(DeviceCaps& caps, Traits& traits, VkPhysicalDevice device, std::uint32_t api) {
    const std::vector<VkExtensionProperties> known = device_extensions(device);
    const char* const conservative = VK_EXT_CONSERVATIVE_RASTERIZATION_EXTENSION_NAME;
    traits.swapchain = has_extension(known, VK_KHR_SWAPCHAIN_EXTENSION_NAME);
    traits.memory_budget = has_extension(known, VK_EXT_MEMORY_BUDGET_EXTENSION_NAME);
    caps.conservative_raster = has_extension(known, conservative);
    const bool has_present_id = has_extension(known, VK_KHR_PRESENT_ID_EXTENSION_NAME);
    const bool has_present_wait = has_extension(known, VK_KHR_PRESENT_WAIT_EXTENSION_NAME);
    traits.present_wait = traits.swapchain && has_present_id && has_present_wait;
    const char* const timing = VK_GOOGLE_DISPLAY_TIMING_EXTENSION_NAME;
    traits.display_timing = traits.swapchain && has_extension(known, timing);
    // STORE_OP_NONE là lõi từ 1.3; dưới đó cần VK_EXT_load_store_op_none.
    const bool has_store_ext = has_extension(known, VK_EXT_LOAD_STORE_OP_NONE_EXTENSION_NAME);
    traits.store_none = api >= VK_API_VERSION_1_3 || has_store_ext;
    std::vector<const char*> extensions;
    if (api < VK_API_VERSION_1_3 && has_store_ext) extensions.push_back(VK_EXT_LOAD_STORE_OP_NONE_EXTENSION_NAME);
    if (traits.swapchain) extensions.push_back(VK_KHR_SWAPCHAIN_EXTENSION_NAME);
    if (traits.memory_budget) extensions.push_back(VK_EXT_MEMORY_BUDGET_EXTENSION_NAME);
    if (caps.conservative_raster) extensions.push_back(conservative);
    if (traits.display_timing) extensions.push_back(timing);
    return extensions;
}

// Hai tính năng của VK_KHR_present_id và VK_KHR_present_wait, nối nhau qua pNext.
struct PresentWaitFeatures {
    VkPhysicalDevicePresentIdFeaturesKHR id{};
    VkPhysicalDevicePresentWaitFeaturesKHR wait{};

    PresentWaitFeatures() noexcept {
        id.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PRESENT_ID_FEATURES_KHR;
        wait.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PRESENT_WAIT_FEATURES_KHR;
        id.pNext = &wait;
    }
    // pNext trỏ vào chính đối tượng: chép hay dời là trỏ sai.
    PresentWaitFeatures(const PresentWaitFeatures&) = delete;
    PresentWaitFeatures& operator=(const PresentWaitFeatures&) = delete;
    PresentWaitFeatures(PresentWaitFeatures&&) = delete;
    PresentWaitFeatures& operator=(PresentWaitFeatures&&) = delete;
};

// Khác gốc: thân vòng lặp của create_queues tách ra đây: lấy hàng đợi.
void start_queue(VkDevice device, Queue& queue) {
    vkGetDeviceQueue(device, queue.family, 0, &queue.handle);
}

// Khác gốc: thân vòng lặp của wait_idle tách ra đây;
// failed vẫn được gọi khi đang giữ mutex của hàng đợi.
[[nodiscard]] Status wait_queue(VulkanDevice& device, Queue& queue) {
    const std::scoped_lock lock(queue.mutex);
    const VkResult waited = vkQueueWaitIdle(queue.handle);
    if (waited != VK_SUCCESS) return device.failed(waited, "chờ hàng đợi rỗng thất bại");
    return ok();
}

} // namespace

// Danh sách lệnh của một loại hàng đợi: rảnh, đang ghi, và đã nộp chờ GPU chạy xong.
struct VulkanDevice::Contexts {
    struct Pending {
        Commands* commands = nullptr;
        std::uint64_t value = 0;
    };

    struct Lane {
        // Bảo vệ mọi thành viên của Lane.
        std::mutex mutex;
        std::vector<std::unique_ptr<Commands>> owned;
        std::vector<Commands*> idle;
        std::vector<Commands*> open;
        std::vector<Pending> busy;
    };

    static void settle(Lane& lane, std::uint64_t reached);
    // Như settle, khi chỗ gọi đã giữ lane.mutex.
    static void settle_locked(Lane& lane, std::uint64_t reached);
    static void reclaim(Lane& lane, std::atomic<std::uint32_t>& recording);
    // Khác gốc: hàm dưới là khối tách từ begin_commands, ghi tại định nghĩa.
    [[nodiscard]] static Status refill(VulkanDevice& device, Lane& lane, QueueType queue);

    std::array<Lane, kQueueCount> lanes{};
};

Block::~Block() {
    if (memory_ != VK_NULL_HANDLE) vkFreeMemory(device_, memory_, nullptr);
}

Block::Block(Block&& other) noexcept
    : device_(other.device_),
      memory_(std::exchange(other.memory_, VK_NULL_HANDLE)),
      mapped_(std::exchange(other.mapped_, nullptr)) {}

Block& Block::operator=(Block&& other) noexcept {
    if (this == &other) return *this;
    if (memory_ != VK_NULL_HANDLE) vkFreeMemory(device_, memory_, nullptr);
    device_ = other.device_;
    memory_ = std::exchange(other.memory_, VK_NULL_HANDLE);
    mapped_ = std::exchange(other.mapped_, nullptr);
    return *this;
}

Result<std::vector<AdapterInfo>> adapters() {
    const Result<std::unique_ptr<Instance>> instance = Instance::create(false);
    if (!instance) return std::unexpected(instance.error());
    Result<std::vector<PhysicalDevice>> devices = (*instance)->devices();
    if (!devices) return std::unexpected(std::move(devices).error());
    std::vector<AdapterInfo> list;
    list.reserve(devices->size());
    for (PhysicalDevice& device : *devices) {
        list.push_back(std::move(device.info));
    }
    return list;
}

// noexcept khai ở device.hpp: thành viên cấp phát lúc dựng
// mà ném thì std::terminate (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
VulkanDevice::VulkanDevice(std::unique_ptr<Instance> instance) noexcept : instance_(std::move(instance)) {}

Result<std::unique_ptr<Device>> VulkanDevice::create(const DeviceDesc& desc) {
    Result<std::unique_ptr<Instance>> instance = Instance::create(desc.is_validated);
    if (!instance) return std::unexpected(std::move(instance).error());
    Result<std::vector<PhysicalDevice>> devices = (*instance)->devices();
    if (!devices) return std::unexpected(std::move(devices).error());
    const std::uint32_t index = desc.adapter.value_or(0);
    if (index >= devices->size()) {
        return fail(ErrorCode::kInvalidArgument, "adapter ngoài danh sách", "{}", index);
    }
    auto device = std::make_unique<VulkanDevice>(std::move(*instance));
    const Status started = device->start(devices->at(index), desc);
    if (!started) return std::unexpected(started.error());
    return device;
}

Status VulkanDevice::start(const PhysicalDevice& physical, const DeviceDesc& desc) {
    physical_ = physical.handle;
    adapter_ = physical.info;
    is_raw_color_ = desc.is_raw_color;
    caps_.is_raw_color = desc.is_raw_color;
    vkGetPhysicalDeviceMemoryProperties(physical_, &memory_);
    caps_.has_unified_memory = upload_is_device_local(memory_);
    VkPhysicalDeviceProperties base{};
    vkGetPhysicalDeviceProperties(physical_, &base);
    api_ = std::min(base.apiVersion, instance_->api_version());
    // Struct của SDK: enum của nó thiếu giá trị
    // 0, trình điều khiển ghi đè (lệch KG-06).
    // NOLINTNEXTLINE(bugprone-invalid-enum-default-initialization)
    VkPhysicalDeviceVulkan12Properties indexing{};
    indexing.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_PROPERTIES;
    VkPhysicalDeviceProperties2 chain{};
    chain.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2;
    // Bộ thuộc tính 1.2 chỉ nối khi thiết bị đạt 1.2: thiết bị 1.1 không biết cấu trúc ấy.
    if (api_ >= VK_API_VERSION_1_2) chain.pNext = &indexing;
    vkGetPhysicalDeviceProperties2(physical_, &chain);
    const VkPhysicalDeviceProperties& properties = chain.properties;
    limits_ = properties.limits;
    const Status picked = pick_queues();
    if (!picked) return picked;
    const Status created = create_device();
    if (!created) return created;
    const Status queued = create_queues();
    if (!queued) return queued;
    read_caps(indexing);
    const std::vector<std::byte> stored = stored_cache(desc, adapter_);
    if (is_cache_usable(stored, properties)) create_cache(stored);
    if (cache_ == VK_NULL_HANDLE) create_cache({});
    passes_ = std::make_unique<Passes>(device_, traits_.store_none, is_raw_color_);
    contexts_ = std::make_unique<Contexts>();
    return ok();
}

// Hàng Graphics là family đầu có GRAPHICS và COMPUTE (đặc tả bảo đảm nếu có GRAPHICS thì có một
// family như thế). Compute và Copy chỉ là hàng riêng khi có family chuyên; không thì dùng chung
// hàng Graphics.
Status VulkanDevice::pick_queues() {
    const std::vector<VkQueueFamilyProperties> list = families(physical_);
    const VkQueueFlags draw = VK_QUEUE_GRAPHICS_BIT | VK_QUEUE_COMPUTE_BIT;
    const std::optional<std::uint32_t> graphics = find_family(list, draw, 0);
    if (!graphics) return fail(ErrorCode::kUnsupported, "thiết bị không có hàng đợi đồ hoạ");
    const std::optional<std::uint32_t> compute = find_family(list, VK_QUEUE_COMPUTE_BIT, VK_QUEUE_GRAPHICS_BIT);
    const std::optional<std::uint32_t> copy =
        find_family(list, VK_QUEUE_TRANSFER_BIT, VK_QUEUE_GRAPHICS_BIT | VK_QUEUE_COMPUTE_BIT);
    const std::array<std::optional<std::uint32_t>, kQueueCount> wanted{graphics, compute, copy};
    queue_count_ = 0;
    for (std::size_t type = 0; type < kQueueCount; ++type) {
        const std::optional<std::uint32_t> family = wanted.at(type);
        queue_index_.at(type) = family ? queue_count_ : 0;
        caps_.has_queue.at(type) = family.has_value();
        take_family(queues_, queue_count_, family, list);
    }
    return ok();
}

Status VulkanDevice::create_device() {
    const bool has_v12 = api_ >= VK_API_VERSION_1_2;
    Features has;
    has.link(has_v12);
    vkGetPhysicalDeviceFeatures2(physical_, &has.base);
    Features wanted;
    wanted.link(has_v12);
    enable_base(wanted.base.features, has.base.features);
    wanted.draw.shaderDrawParameters = has.draw.shaderDrawParameters;
    if (has_v12) enable_v12(wanted.v12, has.v12);
    read_features(caps_, traits_, has);

    std::vector<const char*> extensions = pick_extensions(caps_, traits_, physical_, api_);
    // Phần mở rộng có mà tính năng tắt thì không bật: chỉ hỏi tính năng khi thiết bị có phần mở rộng.
    PresentWaitFeatures present_wait;
    if (traits_.present_wait) {
        VkPhysicalDeviceFeatures2 asked{};
        asked.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2;
        asked.pNext = &present_wait.id;
        vkGetPhysicalDeviceFeatures2(physical_, &asked);
        traits_.present_wait = present_wait.id.presentId != VK_FALSE && present_wait.wait.presentWait != VK_FALSE;
    }
    if (traits_.present_wait) {
        extensions.push_back(VK_KHR_PRESENT_ID_EXTENSION_NAME);
        extensions.push_back(VK_KHR_PRESENT_WAIT_EXTENSION_NAME);
        // Nối cuối chuỗi: sau v12 nếu có, không thì sau draw.
        void*& tail = has_v12 ? wanted.v12.pNext : wanted.draw.pNext;
        tail = &present_wait.id;
    }

    const float priority = 1.0F;
    std::array<VkDeviceQueueCreateInfo, kQueueCount> queue_infos{};
    for (std::uint32_t index = 0; index < queue_count_; ++index) {
        VkDeviceQueueCreateInfo& info = queue_infos.at(index);
        info.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
        info.queueFamilyIndex = queues_.at(index).family;
        info.queueCount = 1;
        info.pQueuePriorities = &priority;
    }
    VkDeviceCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    info.pNext = &wanted.base;
    info.queueCreateInfoCount = queue_count_;
    info.pQueueCreateInfos = queue_infos.data();
    info.enabledExtensionCount = static_cast<std::uint32_t>(extensions.size());
    info.ppEnabledExtensionNames = extensions.data();
    const VkResult created = vkCreateDevice(physical_, &info, nullptr, &device_);
    if (created != VK_SUCCESS) return fail_vk(created, "không tạo được thiết bị Vulkan");
    return ok();
}

void VulkanDevice::load_display_timing() noexcept {
    using Refresh = PFN_vkGetRefreshCycleDurationGOOGLE;
    using Past = PFN_vkGetPastPresentationTimingGOOGLE;
    DisplayTimingApi& api = display_timing_;
    api.refresh_cycle = device_function<Refresh>(device_, "vkGetRefreshCycleDurationGOOGLE");
    api.past_timing = device_function<Past>(device_, "vkGetPastPresentationTimingGOOGLE");
    const bool has_both = api.refresh_cycle != nullptr && api.past_timing != nullptr;
    if (has_both) return;
    display_timing_ = {};
    traits_.display_timing = false;
}

Status VulkanDevice::create_queues() {
    for (std::uint32_t index = 0; index < queue_count_; ++index) {
        start_queue(device_, queues_.at(index));
    }
    if (traits_.address) {
        buffer_address_ = device_function<PFN_vkGetBufferDeviceAddress>(device_, "vkGetBufferDeviceAddress");
        traits_.address = buffer_address_ != nullptr;
    }
    if (traits_.present_wait) {
        wait_for_present_ = device_function<PFN_vkWaitForPresentKHR>(device_, "vkWaitForPresentKHR");
        traits_.present_wait = wait_for_present_ != nullptr;
    }
    if (traits_.display_timing) load_display_timing();
    if (!instance_->has_debug_utils()) return ok();
    using SetName = PFN_vkSetDebugUtilsObjectNameEXT;
    using Begin = PFN_vkCmdBeginDebugUtilsLabelEXT;
    using End = PFN_vkCmdEndDebugUtilsLabelEXT;
    using Insert = PFN_vkCmdInsertDebugUtilsLabelEXT;
    debug_.set_name = device_function<SetName>(device_, "vkSetDebugUtilsObjectNameEXT");
    debug_.begin_label = device_function<Begin>(device_, "vkCmdBeginDebugUtilsLabelEXT");
    debug_.end_label = device_function<End>(device_, "vkCmdEndDebugUtilsLabelEXT");
    debug_.insert_label = device_function<Insert>(device_, "vkCmdInsertDebugUtilsLabelEXT");
    return ok();
}

void VulkanDevice::read_caps(const VkPhysicalDeviceVulkan12Properties& indexing) {
    for (std::size_t type = 0; type < kQueueCount; ++type) {
        const Queue& queue = queues_.at(queue_index_.at(type));
        caps_.has_timestamps.at(type) = queue.timestamp_bits != 0;
    }
    caps_.max_texture_size = limits_.maxImageDimension2D;
    caps_.max_anisotropy = static_cast<std::uint32_t>(limits_.maxSamplerAnisotropy);
    if (!caps_.bindless) return;
    constexpr std::uint32_t kMostResources = 1U << 18U;
    constexpr std::uint32_t kMostSamplers = 1024;
    const std::array resources{indexing.maxPerStageUpdateAfterBindResources,
        indexing.maxPerStageDescriptorUpdateAfterBindSampledImages,
        indexing.maxPerStageDescriptorUpdateAfterBindStorageImages,
        indexing.maxPerStageDescriptorUpdateAfterBindStorageBuffers,
        indexing.maxDescriptorSetUpdateAfterBindSampledImages, indexing.maxDescriptorSetUpdateAfterBindStorageImages,
        indexing.maxDescriptorSetUpdateAfterBindStorageBuffers};
    const std::array samplers{
        indexing.maxPerStageDescriptorUpdateAfterBindSamplers, indexing.maxDescriptorSetUpdateAfterBindSamplers};
    caps_.max_unbounded = unbounded_most(resources, kMostResources);
    caps_.max_unbounded_samplers = unbounded_most(samplers, kMostSamplers);
}

void VulkanDevice::create_cache(std::span<const std::byte> data) {
    VkPipelineCacheCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO;
    info.initialDataSize = data.size();
    info.pInitialData = data.data();
    const VkResult created = vkCreatePipelineCache(device_, &info, nullptr, &cache_);
    if (created == VK_SUCCESS) return;
    // Không có cache thì pipeline vẫn tạo được, chỉ chậm hơn.
    cache_ = VK_NULL_HANDLE;
    core::warn("vulkan: không tạo được pipeline cache: {}", name(created));
}

// Giải phóng ngay mọi phần tử còn trong bảng; chỉ gọi khi GPU đã rỗi.
// drain cấp phát; ném là
// std::terminate (LH-07).
// NOLINTBEGIN(bugprone-exception-escape)
template <class T, class Tag>
void VulkanDevice::discard_all(Slots<T, Tag>& table) noexcept {
    for (T& item : table.drain()) {
        discard(item);
    }
}
// NOLINTEND(bugprone-exception-escape)

// Tài nguyên chỗ gọi quên huỷ vẫn được giải phóng ở đây; Timeline và Swapchain thì phải bị huỷ
// trước Device (chúng giữ con trỏ về nó).
// Ném trong hàm huỷ là
// std::terminate (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
VulkanDevice::~VulkanDevice() {
    if (device_ == VK_NULL_HANDLE) return;
    vkDeviceWaitIdle(device_);
    contexts_.reset();
    retired_.flush();
    discard_all(groups_);
    discard_all(pipelines_);
    discard_all(shaders_);
    discard_all(queries_);
    discard_all(samplers_);
    discard_all(views_);
    discard_all(textures_);
    discard_all(buffers_);
    discard_layouts();
    passes_.reset();
    if (cache_ != VK_NULL_HANDLE) vkDestroyPipelineCache(device_, cache_, nullptr);
    destroy_fences();
    // Khối bộ nhớ phải trả trước khi thiết bị bị huỷ.
    pools_ = {};
    vkDestroyDevice(device_, nullptr);
}

core::Failure VulkanDevice::failed(VkResult result, core::Message message) noexcept {
    if (result == VK_ERROR_DEVICE_LOST) loss_.store(DeviceLoss::kRemoved);
    return fail_vk(result, message);
}

void VulkanDevice::set_name(VkObjectType type, std::uint64_t object, std::string_view name) const {
    if (debug_.set_name == nullptr || name.empty()) return;
    const std::string text(name);
    VkDebugUtilsObjectNameInfoEXT info{};
    info.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_NAME_INFO_EXT;
    info.objectType = type;
    info.objectHandle = object;
    info.pObjectName = text.c_str();
    debug_.set_name(device_, &info);
}

QueueMarks VulkanDevice::marks() const noexcept {
    QueueMarks marks{};
    for (std::size_t type = 0; type < kQueueCount; ++type) {
        std::uint64_t value = queues_.at(queue_index_.at(type)).submitted.load(std::memory_order_acquire);
        value += recording_.at(type).load(std::memory_order_acquire);
        marks.at(type) = value;
    }
    return marks;
}

VkDeviceAddress VulkanDevice::address_of(VkBuffer buffer) const noexcept {
    if (buffer_address_ == nullptr) return 0;
    VkBufferDeviceAddressInfo info{};
    info.sType = VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_INFO;
    info.buffer = buffer;
    return buffer_address_(device_, &info);
}

std::uint64_t VulkanDevice::completed(QueueType type) {
    return poll(queue(type));
}

// Ghi nhận các lần nộp đã xong: fence theo thứ tự nộp nên dừng ở lần đầu chưa xong. Mất thiết bị thì
// ghi nhận qua failed() và dừng; completed không tiến nữa, begin_commands và submit báo kDeviceLost.
std::uint64_t VulkanDevice::retire_done(Queue& queue) {
    while (!queue.flights.empty()) {
        Flight& front = queue.flights.front();
        const VkResult status = vkGetFenceStatus(device_, front.fence);
        if (status == VK_NOT_READY) break;
        if (status != VK_SUCCESS) {
            std::ignore = failed(status, "không hỏi được fence của lần nộp");
            break;
        }
        for (const FlightSignal& signal : front.signals) {
            std::uint64_t seen = signal.state->value.load();
            while (seen < signal.value && !signal.state->value.compare_exchange_weak(seen, signal.value)) {
            }
        }
        vkResetFences(device_, 1, &front.fence);
        queue.spare.push_back(front.fence);
        queue.done.store(front.value);
        queue.flights.pop_front();
    }
    return queue.done.load();
}

std::uint64_t VulkanDevice::poll(Queue& queue) {
    const std::scoped_lock lock(queue.flight_mutex);
    return retire_done(queue);
}

void VulkanDevice::poll_all() {
    for (std::uint32_t index = 0; index < queue_count_; ++index) {
        std::ignore = poll(queues_.at(index));
    }
}

bool VulkanDevice::wait_flight(Queue& queue, const TimelineState& state, std::uint64_t value,
    std::chrono::nanoseconds slice) {
    const std::scoped_lock lock(queue.flight_mutex);
    const auto signals = [&](const Flight& flight) {
        const auto matches = [&](const FlightSignal& signal) {
            return signal.state.get() == &state && signal.value >= value;
        };
        return std::ranges::any_of(flight.signals, matches);
    };
    const auto found = std::ranges::find_if(queue.flights, signals);
    if (found == queue.flights.end()) return false;
    // Giữ khoá suốt lúc chờ: fence không được đặt lại hay huỷ khi đang có luồng chờ nó.
    const auto nanos = static_cast<std::uint64_t>(std::max<std::int64_t>(slice.count(), 0));
    VkFence fence = found->fence;
    const VkResult waited = vkWaitForFences(device_, 1, &fence, VK_TRUE, nanos);
    if (waited != VK_SUCCESS && waited != VK_TIMEOUT) std::ignore = failed(waited, "chờ fence không xong");
    retire_done(queue);
    return true;
}

Status VulkanDevice::wait_state(const TimelineState& state, std::uint64_t value, std::chrono::nanoseconds timeout) {
    constexpr std::chrono::nanoseconds kSlice{2'000'000};
    constexpr std::chrono::microseconds kIdle{200};
    const auto deadline = std::chrono::steady_clock::now() + timeout;
    for (;;) {
        poll_all();
        if (state.value.load() >= value) return ok();
        if (loss() != DeviceLoss::kNone) return fail(ErrorCode::kDeviceLost, "thiết bị đã mất");
        const auto left = deadline - std::chrono::steady_clock::now();
        if (left <= std::chrono::nanoseconds::zero()) return fail(ErrorCode::kTimeout, "chờ timeline hết hạn");
        const std::chrono::nanoseconds slice = std::min(kSlice, std::chrono::duration_cast<std::chrono::nanoseconds>(left));
        bool is_flying = false;
        for (std::uint32_t index = 0; index < queue_count_ && !is_flying; ++index) {
            is_flying = wait_flight(queues_.at(index), state, value, slice);
        }
        // Chưa có lần nộp nào mang giá trị ấy: đợi CPU signal hoặc lần nộp sắp tới.
        if (!is_flying) std::this_thread::sleep_for(kIdle);
    }
}

Result<VkFence> VulkanDevice::take_fence(Queue& queue) {
    {
        const std::scoped_lock lock(queue.flight_mutex);
        if (!queue.spare.empty()) {
            VkFence fence = queue.spare.back();
            queue.spare.pop_back();
            return fence;
        }
    }
    VkFenceCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
    VkFence fence = VK_NULL_HANDLE;
    const VkResult created = vkCreateFence(device_, &info, nullptr, &fence);
    if (created != VK_SUCCESS) return failed(created, "không tạo được fence");
    return fence;
}

// Gọi khi GPU đã rỗi (destructor): mọi fence, đang bay hay để dành, đều huỷ được.
void VulkanDevice::destroy_fences() noexcept {
    for (Queue& queue : queues_) {
        for (const Flight& flight : queue.flights) {
            vkDestroyFence(device_, flight.fence, nullptr);
        }
        for (VkFence const fence : queue.spare) {
            vkDestroyFence(device_, fence, nullptr);
        }
        queue.flights.clear();
        queue.spare.clear();
    }
}

Result<std::unique_ptr<Swapchain>> VulkanDevice::create_swapchain(const SwapchainDesc& desc) {
    return SwapchainVk::create(*this, desc);
}

QueueMarks VulkanDevice::completed() {
    QueueMarks done{};
    for (std::size_t type = 0; type < kQueueCount; ++type) {
        done.at(type) = poll(queues_.at(queue_index_.at(type)));
    }
    return done;
}

Result<std::unique_ptr<Timeline>> VulkanDevice::create_timeline(std::uint64_t initial) {
    auto state = std::make_shared<TimelineState>();
    state->value.store(initial);
    return std::make_unique<TimelineVk>(*this, std::move(state));
}

// Một danh sách lệnh mới: pool riêng kèm một buffer.
Result<std::unique_ptr<Commands>> VulkanDevice::create_commands(QueueType queue) {
    VkCommandPoolCreateInfo pool_info{};
    pool_info.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
    pool_info.queueFamilyIndex = this->queue(queue).family;
    VkCommandPool pool = VK_NULL_HANDLE;
    const VkResult made = vkCreateCommandPool(device_, &pool_info, nullptr, &pool);
    if (made != VK_SUCCESS) return failed(made, "không tạo được command pool");
    VkCommandBufferAllocateInfo buffer_info{};
    buffer_info.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
    buffer_info.commandPool = pool;
    buffer_info.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    buffer_info.commandBufferCount = 1;
    VkCommandBuffer buffer = VK_NULL_HANDLE;
    const VkResult allocated = vkAllocateCommandBuffers(device_, &buffer_info, &buffer);
    // Commands nhận pool trước khi kiểm lỗi: destructor của nó huỷ pool.
    auto commands = std::make_unique<Commands>(*this, queue, pool, buffer);
    if (allocated != VK_SUCCESS) return failed(allocated, "không cấp được command buffer");
    return commands;
}

// Khác gốc: khối `if (lane.idle.empty())` của begin_commands tách ra đây (if lồng if).
// Hàng rảnh rỗng thì nhận về các danh sách GPU đã chạy xong, còn rỗng mới tạo thêm; gọi khi đang
// giữ lane.mutex. Lúc nạp cảnh đầu chưa có end_frame nào trả danh sách về, nên mỗi lần nạp từng
// tạo một command pool rồi giữ tới khi tắt (đo 2026-10-17: 371 lần nạp, 46 ms trên RTX 5060).
// Thứ tự khoá: lane.mutex rồi flight_mutex (poll); không đường nào giữ flight_mutex mà lấy lane.
Status VulkanDevice::Contexts::refill(VulkanDevice& device, Lane& lane, QueueType queue) {
    if (!lane.idle.empty()) return ok();
    const std::uint64_t reached = device.poll(device.queue(queue));
    settle_locked(lane, reached);
    if (!lane.idle.empty()) return ok();
    Result<std::unique_ptr<Commands>> created = device.create_commands(queue);
    if (!created) return std::unexpected(std::move(created).error());
    lane.idle.push_back(created->get());
    lane.owned.push_back(std::move(*created));
    return ok();
}

Result<CommandList*> VulkanDevice::begin_commands(QueueType queue) {
    if (loss() != DeviceLoss::kNone) return fail(ErrorCode::kDeviceLost, "thiết bị đã mất");
    Contexts::Lane& lane = contexts_->lanes.at(std::to_underlying(queue));
    const std::scoped_lock lock(lane.mutex);
    Status refilled = Contexts::refill(*this, lane, queue);
    if (!refilled) return std::unexpected(std::move(refilled).error());
    Commands* const commands = lane.idle.back();
    const Status opened = commands->open();
    if (!opened) return std::unexpected(opened.error());
    lane.idle.pop_back();
    lane.open.push_back(commands);
    recording_.at(std::to_underlying(queue)).fetch_add(1, std::memory_order_acq_rel);
    return commands;
}

Status VulkanDevice::submit(QueueType queue, const SubmitDesc& desc) {
    if (loss() != DeviceLoss::kNone) return fail(ErrorCode::kDeviceLost, "thiết bị đã mất");
    Submission submission;
    const Status filled = fill(submission, queue, desc);
    if (!filled) return filled;
    Result<SwapchainVk*> found = find_target(queue, desc);
    if (!found) return std::unexpected(std::move(found).error());
    SwapchainVk* const target = *found;
    const VkPipelineStageFlags all = VK_PIPELINE_STAGE_ALL_COMMANDS_BIT;
    // Semaphore nhị phân của WSI: chờ ảnh vừa acquire, báo cho lần present.
    if (target != nullptr) submission.waits.push_back(target->acquired());
    if (target != nullptr) submission.wait_stages.push_back(all);
    if (target != nullptr) submission.signals.push_back(target->rendered());

    Queue& physical = this->queue(queue);
    Result<VkFence> fence = take_fence(physical);
    if (!fence) return std::unexpected(std::move(fence).error());
    const std::scoped_lock lock(physical.mutex);
    const std::uint64_t value = physical.submitted.load() + 1;
    VkSubmitInfo info{};
    info.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
    info.waitSemaphoreCount = static_cast<std::uint32_t>(submission.waits.size());
    info.pWaitSemaphores = submission.waits.data();
    info.pWaitDstStageMask = submission.wait_stages.data();
    info.commandBufferCount = static_cast<std::uint32_t>(submission.buffers.size());
    info.pCommandBuffers = submission.buffers.data();
    info.signalSemaphoreCount = static_cast<std::uint32_t>(submission.signals.size());
    info.pSignalSemaphores = submission.signals.data();
    const VkResult submitted = vkQueueSubmit(physical.handle, 1, &info, *fence);
    if (submitted != VK_SUCCESS) {
        // Fence chưa vào hàng đợi nên vẫn chưa báo hiệu: để dành lại.
        const std::scoped_lock spare_lock(physical.flight_mutex);
        physical.spare.push_back(*fence);
        return failed(submitted, "nộp lệnh thất bại");
    }
    {
        const std::scoped_lock flight_lock(physical.flight_mutex);
        physical.flights.push_back({.value = value, .fence = *fence, .signals = std::move(submission.flight_signals)});
    }
    physical.submitted.store(value);
    if (target != nullptr) target->mark_submitted(value);

    Contexts::Lane& lane = contexts_->lanes.at(std::to_underlying(queue));
    const std::scoped_lock lane_lock(lane.mutex);
    for (Commands* const commands : submission.lists) {
        std::erase(lane.open, commands);
        commands->mark_pending();
        lane.busy.push_back({.commands = commands, .value = value});
    }
    const auto parked = static_cast<std::uint32_t>(submission.lists.size());
    recording_.at(std::to_underlying(queue)).fetch_sub(parked, std::memory_order_acq_rel);
    return ok();
}

// Đưa các danh sách lệnh mà GPU đã chạy xong (lần nộp tới reached) về hàng rảnh.
void VulkanDevice::Contexts::settle(Lane& lane, std::uint64_t reached) {
    const std::scoped_lock lock(lane.mutex);
    settle_locked(lane, reached);
}

void VulkanDevice::Contexts::settle_locked(Lane& lane, std::uint64_t reached) {
    const auto is_running = [reached](const Pending& item) { return item.value > reached; };
    const auto finished = std::ranges::stable_partition(lane.busy, is_running);
    for (const Pending& item : finished) {
        item.commands->mark_idle();
        lane.idle.push_back(item.commands);
    }
    lane.busy.erase(finished.begin(), finished.end());
}

// Danh sách lệnh lấy mà không nộp quay về hàng rảnh.
void VulkanDevice::Contexts::reclaim(Lane& lane, std::atomic<std::uint32_t>& recording) {
    const std::scoped_lock lock(lane.mutex);
    const auto count = static_cast<std::uint32_t>(lane.open.size());
    for (Commands* const commands : lane.open) {
        commands->discard();
        lane.idle.push_back(commands);
    }
    lane.open.clear();
    if (count != 0) recording.fetch_sub(count, std::memory_order_acq_rel);
}

void VulkanDevice::recycle(const QueueMarks& done) {
    for (std::size_t type = 0; type < kQueueCount; ++type) {
        Contexts::settle(contexts_->lanes.at(type), done.at(type));
    }
}

// vkQueueWaitIdle chứ không chờ timeline nội bộ: nó chờ cả lần present cuối, thứ mà swapchain phải
// xong trước khi bị huỷ hay dựng lại. Hàng đợi bị khoá suốt lúc chờ, nên hàm này chỉ dành cho lúc
// tắt và lúc đổi cỡ.
Status VulkanDevice::wait_idle() {
    Status waited = ok();
    for (std::uint32_t index = 0; index < queue_count_ && waited; ++index) {
        waited = wait_queue(*this, queues_.at(index));
    }
    if (!waited) return waited;
    const QueueMarks done = completed();
    recycle(done);
    retired_.collect(done);
    return ok();
}

Status VulkanDevice::end_frame() {
    if (loss() != DeviceLoss::kNone) return fail(ErrorCode::kDeviceLost, "thiết bị đã mất");
    const QueueMarks done = completed();
    recycle(done);
    for (std::size_t type = 0; type < kQueueCount; ++type) {
        Contexts::reclaim(contexts_->lanes.at(type), recording_.at(type));
    }
    retired_.collect(done);
    return ok();
}

std::vector<std::byte> VulkanDevice::pipeline_cache() const {
    if (cache_ == VK_NULL_HANDLE) return {};
    std::size_t size = 0;
    vkGetPipelineCacheData(device_, cache_, &size, nullptr);
    std::vector<std::byte> data(size);
    const VkResult read = vkGetPipelineCacheData(device_, cache_, &size, data.data());
    if (read != VK_SUCCESS) return {};
    data.resize(size);
    return data;
}

} // namespace game::gpu::vulkan
