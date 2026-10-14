// Vòng đời thiết bị, hàng đợi, timeline, nộp lệnh và ranh giới khung hình của backend Vulkan.
// Nguồn: Forge2 src/gpu/vulkan/device.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; include
// trực tiếp header của mọi tên dùng tới; hàm dài hoặc có nhánh trong thân vòng lặp tách hàm ở ranh
// giới câu lệnh, thứ tự lời gọi Vulkan và phép kiểm lỗi giữ nguyên (ghi tại chỗ): fill đưa điều
// kiện dừng lên điều kiện lặp; pick_queues tách take_family; create_device tách pick_extensions;
// create_queues tách start_queue; begin_commands tách Contexts::refill; submit tách find_target;
// wait_idle tách wait_queue; handle Vulkan cục bộ khai auto* const; NOLINT kèm lý do cho các hàm
// noexcept của gốc và hai chữ ký có tham số cùng kiểu.
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

// Chuỗi tính năng của Vulkan 1.0 tới 1.3, nối sẵn qua pNext.
struct Features {
    VkPhysicalDeviceFeatures2 base{};
    VkPhysicalDeviceVulkan11Features v11{};
    VkPhysicalDeviceVulkan12Features v12{};
    VkPhysicalDeviceVulkan13Features v13{};

    Features() noexcept {
        base.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2;
        v11.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES;
        v12.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES;
        v13.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES;
        base.pNext = &v11;
        v11.pNext = &v12;
        v12.pNext = &v13;
    }
    // pNext trỏ vào chính đối tượng: chép hay dời là trỏ sai.
    Features(const Features&) = delete;
    Features& operator=(const Features&) = delete;
    Features(Features&&) = delete;
    Features& operator=(Features&&) = delete;
    ~Features() = default;
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
    wanted.timelineSemaphore = has.timelineSemaphore;
    wanted.bufferDeviceAddress = has.bufferDeviceAddress;
    wanted.drawIndirectCount = has.drawIndirectCount;
    wanted.scalarBlockLayout = has.scalarBlockLayout;
    wanted.hostQueryReset = has.hostQueryReset;
    wanted.shaderInt8 = has.shaderInt8;
    wanted.shaderFloat16 = has.shaderFloat16;
    wanted.shaderOutputLayer = has.shaderOutputLayer;
    wanted.shaderOutputViewportIndex = has.shaderOutputViewportIndex;
    wanted.separateDepthStencilLayouts = has.separateDepthStencilLayouts;
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

void enable_v13(VkPhysicalDeviceVulkan13Features& wanted, const VkPhysicalDeviceVulkan13Features& has) noexcept {
    wanted.dynamicRendering = has.dynamicRendering;
    wanted.synchronization2 = has.synchronization2;
    wanted.maintenance4 = has.maintenance4;
    wanted.shaderDemoteToHelperInvocation = has.shaderDemoteToHelperInvocation;
    wanted.shaderTerminateInvocation = has.shaderTerminateInvocation;
    wanted.shaderZeroInitializeWorkgroupMemory = has.shaderZeroInitializeWorkgroupMemory;
    wanted.shaderIntegerDotProduct = has.shaderIntegerDotProduct;
    wanted.subgroupSizeControl = has.subgroupSizeControl;
    wanted.computeFullSubgroups = has.computeFullSubgroups;
    wanted.textureCompressionASTC_HDR = has.textureCompressionASTC_HDR;
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

class TimelineVk final : public Timeline {
public:
    TimelineVk(VulkanDevice& device, VkSemaphore semaphore) noexcept : device_(&device), semaphore_(semaphore) {}
    // retire cấp phát, ném
    // là terminate (LH-07).
    // NOLINTNEXTLINE(bugprone-exception-escape)
    ~TimelineVk() override {
        auto* const device = device_->handle();
        auto* const semaphore = semaphore_;
        device_->retire([device, semaphore] { vkDestroySemaphore(device, semaphore, nullptr); });
    }
    TimelineVk(const TimelineVk&) = delete;
    TimelineVk& operator=(const TimelineVk&) = delete;
    TimelineVk(TimelineVk&&) = delete;
    TimelineVk& operator=(TimelineVk&&) = delete;

    [[nodiscard]] VkSemaphore handle() const noexcept { return semaphore_; }

    [[nodiscard]] std::uint64_t completed() const noexcept override {
        std::uint64_t value = 0;
        semaphore_counter(device_->handle(), semaphore_, &value);
        return value;
    }

    [[nodiscard]] Status wait(std::uint64_t value, std::chrono::nanoseconds timeout) override {
        VkSemaphoreWaitInfo info{};
        info.sType = VK_STRUCTURE_TYPE_SEMAPHORE_WAIT_INFO;
        info.semaphoreCount = 1;
        info.pSemaphores = &semaphore_;
        info.pValues = &value;
        const auto nanos = static_cast<std::uint64_t>(std::max<std::int64_t>(timeout.count(), 0));
        const VkResult waited = wait_semaphores(device_->handle(), &info, nanos);
        if (waited == VK_SUCCESS) return ok();
        return device_->failed(waited, "chờ timeline không xong");
    }

    void signal(std::uint64_t value) override {
        VkSemaphoreSignalInfo info{};
        info.sType = VK_STRUCTURE_TYPE_SEMAPHORE_SIGNAL_INFO;
        info.semaphore = semaphore_;
        info.value = value;
        const VkResult signalled = signal_semaphore(device_->handle(), &info);
        if (signalled != VK_SUCCESS) core::error("vulkan: signal semaphore: {}", name(signalled));
    }

private:
    VulkanDevice* device_;
    VkSemaphore semaphore_;
};

[[nodiscard]] Result<VkSemaphore> create_timeline_semaphore(VkDevice device, std::uint64_t initial) {
    VkSemaphoreTypeCreateInfo type{};
    type.sType = VK_STRUCTURE_TYPE_SEMAPHORE_TYPE_CREATE_INFO;
    type.semaphoreType = VK_SEMAPHORE_TYPE_TIMELINE;
    type.initialValue = initial;
    VkSemaphoreCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
    info.pNext = &type;
    VkSemaphore semaphore = VK_NULL_HANDLE;
    const VkResult created = vkCreateSemaphore(device, &info, nullptr, &semaphore);
    if (created != VK_SUCCESS) return fail_vk(created, "không tạo được timeline semaphore");
    return semaphore;
}

// Mọi thứ của một lần nộp, dựng xong rồi mới khoá hàng đợi.
struct Submission {
    std::vector<VkSemaphoreSubmitInfo> waits;
    std::vector<VkSemaphoreSubmitInfo> signals;
    std::vector<VkCommandBufferSubmitInfo> buffers;
    std::vector<Commands*> lists;
};

// Giá trị rồi giai đoạn như VkSemaphoreSubmitInfo;
// hai kiểu đều là số 64 bit (lệch API-03).
// NOLINTBEGIN(bugprone-easily-swappable-parameters)
[[nodiscard]] VkSemaphoreSubmitInfo semaphore_info(VkSemaphore semaphore, std::uint64_t value,
    VkPipelineStageFlags2 stages) noexcept {
    VkSemaphoreSubmitInfo info{};
    info.sType = VK_STRUCTURE_TYPE_SEMAPHORE_SUBMIT_INFO;
    info.semaphore = semaphore;
    info.value = value;
    info.stageMask = stages;
    return info;
}
// NOLINTEND(bugprone-easily-swappable-parameters)

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
    VkCommandBufferSubmitInfo info{};
    info.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_SUBMIT_INFO;
    info.commandBuffer = commands->buffer();
    submission.buffers.push_back(info);
    submission.lists.push_back(commands);
    return ok();
}

[[nodiscard]] Status add_wait(Submission& submission, const SubmitWait& wait) {
    const auto* const timeline = dynamic_cast<const TimelineVk*>(wait.timeline);
    if (timeline == nullptr) return fail(ErrorCode::kInvalidArgument, "submit: timeline chờ lạ");
    submission.waits.push_back(semaphore_info(timeline->handle(), wait.value, to_vk(wait.stage)));
    return ok();
}

[[nodiscard]] Status add_signal(Submission& submission, const SubmitSignal& signal) {
    const auto* const timeline = dynamic_cast<const TimelineVk*>(signal.timeline);
    if (timeline == nullptr) return fail(ErrorCode::kInvalidArgument, "submit: timeline báo lạ");
    const VkPipelineStageFlags2 all = VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT;
    submission.signals.push_back(semaphore_info(timeline->handle(), signal.value, all));
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
        added = add_wait(submission, *wait);
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
[[nodiscard]] Names pick_extensions(DeviceCaps& caps, Traits& traits, VkPhysicalDevice device) {
    const std::vector<VkExtensionProperties> known = device_extensions(device);
    const char* const conservative = VK_EXT_CONSERVATIVE_RASTERIZATION_EXTENSION_NAME;
    traits.swapchain = has_extension(known, VK_KHR_SWAPCHAIN_EXTENSION_NAME);
    traits.memory_budget = has_extension(known, VK_EXT_MEMORY_BUDGET_EXTENSION_NAME);
    caps.conservative_raster = has_extension(known, conservative);
    traits.present_wait = traits.swapchain && has_extension(known, VK_KHR_PRESENT_ID_EXTENSION_NAME) &&
        has_extension(known, VK_KHR_PRESENT_WAIT_EXTENSION_NAME);
    std::vector<const char*> extensions;
    if (traits.swapchain) extensions.push_back(VK_KHR_SWAPCHAIN_EXTENSION_NAME);
    if (traits.memory_budget) extensions.push_back(VK_EXT_MEMORY_BUDGET_EXTENSION_NAME);
    if (caps.conservative_raster) extensions.push_back(conservative);
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

// Khác gốc: thân vòng lặp của create_queues tách ra đây:
// lấy hàng đợi rồi tạo timeline nội bộ của nó.
[[nodiscard]] Status start_queue(VkDevice device, Queue& queue) {
    vkGetDeviceQueue(device, queue.family, 0, &queue.handle);
    Result<VkSemaphore> progress = create_timeline_semaphore(device, 0);
    if (!progress) return std::unexpected(std::move(progress).error());
    queue.progress = *progress;
    return ok();
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
    vkGetPhysicalDeviceMemoryProperties(physical_, &memory_);
    // Struct của SDK: enum của nó thiếu giá trị
    // 0, trình điều khiển ghi đè (lệch KG-06).
    // NOLINTNEXTLINE(bugprone-invalid-enum-default-initialization)
    VkPhysicalDeviceVulkan12Properties indexing{};
    indexing.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_PROPERTIES;
    VkPhysicalDeviceProperties2 chain{};
    chain.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2;
    chain.pNext = &indexing;
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
    if (is_cache_usable(desc.pipeline_cache, properties)) create_cache(desc.pipeline_cache);
    if (cache_ == VK_NULL_HANDLE) create_cache({});
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
    Features has;
    vkGetPhysicalDeviceFeatures2(physical_, &has.base);
    const bool is_enough = has.v13.dynamicRendering != VK_FALSE && has.v13.synchronization2 != VK_FALSE &&
        has.v12.timelineSemaphore != VK_FALSE;
    if (!is_enough) {
        return fail(ErrorCode::kUnsupported,
            "thiết bị thiếu dynamic rendering, synchronization2 hoặc timeline semaphore");
    }
    Features wanted;
    enable_base(wanted.base.features, has.base.features);
    wanted.v11.shaderDrawParameters = has.v11.shaderDrawParameters;
    enable_v12(wanted.v12, has.v12);
    enable_v13(wanted.v13, has.v13);
    read_features(caps_, traits_, has);

    std::vector<const char*> extensions = pick_extensions(caps_, traits_, physical_);
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
        wanted.v13.pNext = &present_wait.id;
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

Status VulkanDevice::create_queues() {
    Status started = ok();
    for (std::uint32_t index = 0; index < queue_count_ && started; ++index) {
        started = start_queue(device_, queues_.at(index));
    }
    if (!started) return started;
    if (traits_.present_wait) {
        wait_for_present_ = device_function<PFN_vkWaitForPresentKHR>(device_, "vkWaitForPresentKHR");
        traits_.present_wait = wait_for_present_ != nullptr;
    }
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
    if (cache_ != VK_NULL_HANDLE) vkDestroyPipelineCache(device_, cache_, nullptr);
    for (const Queue& queue : queues_) {
        vkDestroySemaphore(device_, queue.progress, nullptr);
    }
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

std::uint64_t VulkanDevice::completed(QueueType type) const noexcept {
    const Queue& queue = queues_.at(queue_index_.at(std::to_underlying(type)));
    std::uint64_t value = 0;
    semaphore_counter(device_, queue.progress, &value);
    return value;
}

Result<std::unique_ptr<Swapchain>> VulkanDevice::create_swapchain(const SwapchainDesc& desc) {
    return SwapchainVk::create(*this, desc);
}

QueueMarks VulkanDevice::completed() const noexcept {
    QueueMarks done{};
    for (std::size_t type = 0; type < kQueueCount; ++type) {
        const Queue& queue = queues_.at(queue_index_.at(type));
        semaphore_counter(device_, queue.progress, &done.at(type));
    }
    return done;
}

Result<std::unique_ptr<Timeline>> VulkanDevice::create_timeline(std::uint64_t initial) {
    Result<VkSemaphore> semaphore = create_timeline_semaphore(device_, initial);
    if (!semaphore) return std::unexpected(std::move(semaphore).error());
    return std::make_unique<TimelineVk>(*this, *semaphore);
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
// Hàng rảnh rỗng thì tạo thêm một danh sách lệnh; gọi khi đang giữ lane.mutex.
Status VulkanDevice::Contexts::refill(VulkanDevice& device, Lane& lane, QueueType queue) {
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
    const VkPipelineStageFlags2 all = VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT;
    // Semaphore nhị phân của WSI: chờ ảnh vừa acquire, báo cho lần present.
    if (target != nullptr) submission.waits.push_back(semaphore_info(target->acquired(), 0, all));
    if (target != nullptr) submission.signals.push_back(semaphore_info(target->rendered(), 0, all));

    Queue& physical = this->queue(queue);
    const std::scoped_lock lock(physical.mutex);
    const std::uint64_t value = physical.submitted.load() + 1;
    submission.signals.push_back(semaphore_info(physical.progress, value, all));
    VkSubmitInfo2 info{};
    info.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO_2;
    info.waitSemaphoreInfoCount = static_cast<std::uint32_t>(submission.waits.size());
    info.pWaitSemaphoreInfos = submission.waits.data();
    info.commandBufferInfoCount = static_cast<std::uint32_t>(submission.buffers.size());
    info.pCommandBufferInfos = submission.buffers.data();
    info.signalSemaphoreInfoCount = static_cast<std::uint32_t>(submission.signals.size());
    info.pSignalSemaphoreInfos = submission.signals.data();
    const VkResult submitted = submit2(physical.handle, 1, &info, VK_NULL_HANDLE);
    if (submitted != VK_SUCCESS) return failed(submitted, "nộp lệnh thất bại");
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
