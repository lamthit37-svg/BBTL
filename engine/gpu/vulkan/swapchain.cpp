// Chọn định dạng, chế độ trình bày và cỡ ảnh theo khả năng của bề mặt.
// Chỉ nhận không gian màu sRGB; không có chế độ được xin thì dùng Fifo.
// maxImageCount bằng 0 nghĩa là không trần; ưu tiên biến đổi identity.
// Nguồn: Forge2 src/gpu/vulkan/swapchain.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; phần
// điền VkSwapchainCreateInfoKHR của build tách thành swapchain_info (kèm struct Picked); lambda huỷ
// semaphore trong hai vòng lặp của drop_images tách thành retire_semaphore; vòng lặp của
// adopt_images đưa điều kiện dừng lên điều kiện lặp và TextureDesc khai rồi gán trường; present giữ
// semaphore chờ trong mảng một phần tử; handle cục bộ viết auto* const; include trực tiếp header
// của mọi tên dùng tới.
#include "gpu/vulkan/swapchain.hpp"

#include "core/error.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"
#include "gpu/vulkan/convert.hpp"
#include "gpu/vulkan/device.hpp"

#include <vulkan/vulkan_core.h>

#include <algorithm>
#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <memory>
#include <mutex>
#include <span>
#include <tuple>
#include <utility>
#include <vector>

namespace game::gpu::vulkan {

namespace {

using core::ErrorCode;
using core::fail;
using core::ok;

constexpr ErrorCode kState = ErrorCode::kInvalidState;

[[nodiscard]] std::vector<VkSurfaceFormatKHR> surface_formats(VkPhysicalDevice device, VkSurfaceKHR surface) {
    std::uint32_t count = 0;
    vkGetPhysicalDeviceSurfaceFormatsKHR(device, surface, &count, nullptr);
    std::vector<VkSurfaceFormatKHR> list(count);
    vkGetPhysicalDeviceSurfaceFormatsKHR(device, surface, &count, list.data());
    list.resize(count);
    return list;
}

[[nodiscard]] std::vector<VkPresentModeKHR> surface_modes(VkPhysicalDevice device, VkSurfaceKHR surface) {
    std::uint32_t count = 0;
    vkGetPhysicalDeviceSurfacePresentModesKHR(device, surface, &count, nullptr);
    std::vector<VkPresentModeKHR> list(count);
    vkGetPhysicalDeviceSurfacePresentModesKHR(device, surface, &count, list.data());
    list.resize(count);
    return list;
}

[[nodiscard]] bool is_srgb_space(const VkSurfaceFormatKHR& format) noexcept {
    return format.colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR;
}

// Định dạng chỗ gọi xin nếu bề mặt có; không thì định dạng đầu tiên mà engine biết. Chỉ nhận không
// gian màu sRGB: HDR là mốc sau.
[[nodiscard]] Format pick_format(std::span<const VkSurfaceFormatKHR> list, Format wanted) noexcept {
    const VkFormat exact = to_vk(wanted);
    const auto is_wanted = [exact](const VkSurfaceFormatKHR& item) {
        return item.format == exact && is_srgb_space(item);
    };
    if (std::ranges::any_of(list, is_wanted)) return wanted;
    const auto is_known = [](const VkSurfaceFormatKHR& item) {
        return from_vk(item.format) != Format::kUnknown && is_srgb_space(item);
    };
    const auto found = std::ranges::find_if(list, is_known);
    return found == list.end() ? Format::kUnknown : from_vk(found->format);
}

// Fifo là chế độ duy nhất mọi bề mặt bảo đảm có.
[[nodiscard]] PresentMode pick_mode(std::span<const VkPresentModeKHR> list, PresentMode wanted) noexcept {
    const bool is_present = std::ranges::find(list, to_vk(wanted)) != list.end();
    return is_present ? wanted : PresentMode::kFifo;
}

// Bề mặt cho cỡ cố định (currentExtent) thì theo nó; không thì kẹp cỡ chỗ gọi xin vào khoảng cho
// phép.
[[nodiscard]] VkExtent2D pick_extent(const VkSurfaceCapabilitiesKHR& caps, const SwapchainDesc& desc) noexcept {
    const bool is_fixed = caps.currentExtent.width != std::numeric_limits<std::uint32_t>::max();
    if (is_fixed) return caps.currentExtent;
    const VkExtent2D& least = caps.minImageExtent;
    const VkExtent2D& most = caps.maxImageExtent;
    const std::uint32_t width = std::clamp(desc.width, least.width, most.width);
    const std::uint32_t height = std::clamp(desc.height, least.height, most.height);
    return {.width = width, .height = height};
}

// maxImageCount bằng 0 là không có trần.
[[nodiscard]] std::uint32_t pick_count(const VkSurfaceCapabilitiesKHR& caps, std::uint32_t wanted) noexcept {
    const std::uint32_t count = std::max(wanted, caps.minImageCount);
    return caps.maxImageCount == 0 ? count : std::min(count, caps.maxImageCount);
}

// Ảnh của swapchain là đích vẽ; thêm chép ra (chụp màn hình, ghi hình) và chép vào khi bề mặt cho.
[[nodiscard]] TextureUsage pick_usage(const VkSurfaceCapabilitiesKHR& caps) noexcept {
    const VkImageUsageFlags supported = caps.supportedUsageFlags;
    TextureUsage usage = TextureUsage::kColorTarget;
    if ((supported & VK_IMAGE_USAGE_TRANSFER_SRC_BIT) != 0) usage |= TextureUsage::kCopySource;
    if ((supported & VK_IMAGE_USAGE_TRANSFER_DST_BIT) != 0) usage |= TextureUsage::kCopyDest;
    return usage;
}

// Không xoay sẵn theo màn hình: hệ điều hành tự xoay, tốn một lượt chép trên điện thoại. Xoay sẵn
// cần renderer cùng xoay ma trận chiếu, là mốc Android.
[[nodiscard]] VkSurfaceTransformFlagBitsKHR pick_transform(const VkSurfaceCapabilitiesKHR& caps) noexcept {
    const bool has_identity = (caps.supportedTransforms & VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR) != 0;
    return has_identity ? VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR : caps.currentTransform;
}

[[nodiscard]] VkCompositeAlphaFlagBitsKHR pick_alpha(const VkSurfaceCapabilitiesKHR& caps) noexcept {
    const VkCompositeAlphaFlagsKHR supported = caps.supportedCompositeAlpha;
    const bool has_opaque = (supported & VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR) != 0;
    if (has_opaque) return VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
    // Bề mặt không có chế độ đục (vài trình tổng hợp trên Android): lấy bit thấp nhất đang có.
    return static_cast<VkCompositeAlphaFlagBitsKHR>(supported & (~supported + 1U));
}

// Khác gốc: gói các giá trị SwapchainVk::build đã chọn, để phần điền VkSwapchainCreateInfoKHR của
// nó tách thành hàm (build của gốc dài hơn 40 dòng).
struct Picked {
    VkExtent2D extent{};
    Format format = Format::kUnknown;
    PresentMode mode = PresentMode::kFifo;
    TextureUsage usage = TextureUsage::kNone;
    // Số ảnh chỗ gọi xin, chưa kẹp theo bề mặt.
    std::uint32_t image_count = 0;
};

// Khác gốc: phần điền VkSwapchainCreateInfoKHR của SwapchainVk::build tách ra đây; giá trị và thứ
// tự gán như gốc. old là swapchain đang có (VK_NULL_HANDLE ở lần dựng đầu).
[[nodiscard]] VkSwapchainCreateInfoKHR swapchain_info(VkSurfaceKHR surface, VkSwapchainKHR old,
    const VkSurfaceCapabilitiesKHR& caps, const Picked& picked) noexcept {
    // Struct C của Vulkan: 0 là "chưa đặt" theo quy ước của API, mọi trường enum được gán ngay dưới
    // (lệch KG-06).
    // NOLINTNEXTLINE(bugprone-invalid-enum-default-initialization)
    VkSwapchainCreateInfoKHR info{};
    info.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
    info.surface = surface;
    info.minImageCount = pick_count(caps, picked.image_count);
    info.imageFormat = to_vk(picked.format);
    info.imageColorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR;
    info.imageExtent = picked.extent;
    info.imageArrayLayers = 1;
    info.imageUsage = to_vk(picked.usage);
    info.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
    info.preTransform = pick_transform(caps);
    info.compositeAlpha = pick_alpha(caps);
    info.presentMode = to_vk(picked.mode);
    info.clipped = VK_TRUE;
    info.oldSwapchain = old;
    return info;
}

[[nodiscard]] Result<VkSemaphore> create_semaphore(VulkanDevice& device) {
    VkSemaphoreCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
    VkSemaphore semaphore = VK_NULL_HANDLE;
    const VkResult created = vkCreateSemaphore(device.handle(), &info, nullptr, &semaphore);
    if (created != VK_SUCCESS) return device.failed(created, "không tạo được semaphore swapchain");
    return semaphore;
}

// vkQueuePresentKHR đòi đồng bộ ngoài trên hàng đợi, như vkQueueSubmit2.
[[nodiscard]] VkResult present_locked(Queue& queue, const VkPresentInfoKHR& info) {
    const std::scoped_lock lock(queue.mutex);
    return vkQueuePresentKHR(queue.handle, &info);
}

// Khác gốc: lambda huỷ semaphore trong thân hai vòng lặp của drop_images tách ra đây.
void retire_semaphore(VulkanDevice& device, VkSemaphore semaphore) {
    auto* const handle = device.handle();
    device.retire([handle, semaphore] { vkDestroySemaphore(handle, semaphore, nullptr); });
}

} // namespace

Result<std::unique_ptr<Swapchain>> SwapchainVk::create(VulkanDevice& device, const SwapchainDesc& desc) {
    if (!device.traits().swapchain) {
        return fail(ErrorCode::kUnsupported, "thiết bị không có VK_KHR_swapchain");
    }
    Result<VkSurfaceKHR> surface = create_surface(device.instance(), desc.window);
    if (!surface) return std::unexpected(std::move(surface).error());
    // Swapchain nhận bề mặt trước mọi phép kiểm: destructor của nó huỷ bề mặt trên đường lỗi.
    auto swapchain = std::make_unique<SwapchainVk>(device, *surface, desc);
    const std::uint32_t family = device.queue(QueueType::kGraphics).family;
    VkBool32 is_presentable = VK_FALSE;
    const VkResult asked = vkGetPhysicalDeviceSurfaceSupportKHR(device.physical(), family, *surface, &is_presentable);
    if (asked != VK_SUCCESS) return device.failed(asked, "không hỏi được bề mặt");
    if (is_presentable == VK_FALSE) {
        return fail(ErrorCode::kUnsupported, "hàng đợi Graphics không trình bày được lên bề mặt này");
    }
    const Status built = swapchain->build();
    if (!built) return std::unexpected(built.error());
    return swapchain;
}

SwapchainVk::~SwapchainVk() {
    // Lỗi chờ ở đây không báo được cho ai; mất thiết bị thì việc huỷ bên dưới vẫn hợp lệ.
    std::ignore = device_->wait_idle();
    drop_images();
    auto* const device = device_->handle();
    if (swapchain_ != VK_NULL_HANDLE) vkDestroySwapchainKHR(device, swapchain_, nullptr);
    vkDestroySurfaceKHR(device_->instance().handle(), surface_, nullptr);
}

Status SwapchainVk::build() {
    auto* const physical = device_->physical();
    // Struct C của Vulkan: trình điều khiển điền mọi trường; 0 chỉ để không đọc rác khi lời gọi
    // thất bại (lệch KG-06).
    // NOLINTNEXTLINE(bugprone-invalid-enum-default-initialization)
    VkSurfaceCapabilitiesKHR caps{};
    const VkResult read = vkGetPhysicalDeviceSurfaceCapabilitiesKHR(physical, surface_, &caps);
    if (read != VK_SUCCESS) return device_->failed(read, "không đọc được khả năng của bề mặt");
    const VkExtent2D extent = pick_extent(caps, desc_);
    const Format format = pick_format(surface_formats(physical, surface_), desc_.format);
    const PresentMode mode = pick_mode(surface_modes(physical, surface_), desc_.present_mode);
    const TextureUsage usage = pick_usage(caps);
    const bool is_hidden = extent.width == 0 || extent.height == 0;
    if (format == Format::kUnknown) {
        return fail(ErrorCode::kUnsupported, "bề mặt không có định dạng nào engine biết");
    }

    // Khác gốc: gốc điền VkSwapchainCreateInfoKHR tại đây; nay ở swapchain_info.
    const Picked picked{
        .extent = extent, .format = format, .mode = mode, .usage = usage, .image_count = desc_.image_count};
    const VkSwapchainCreateInfoKHR info = swapchain_info(surface_, swapchain_, caps, picked);
    VkSwapchainKHR created = VK_NULL_HANDLE;
    auto* const device = device_->handle();
    const VkResult made = is_hidden ? VK_SUCCESS : vkCreateSwapchainKHR(device, &info, nullptr, &created);
    // Swapchain cũ không còn dùng được kể cả khi lần tạo mới thất bại.
    if (swapchain_ != VK_NULL_HANDLE) vkDestroySwapchainKHR(device, swapchain_, nullptr);
    swapchain_ = created;
    presents_ = 0;
    extent_ = is_hidden ? VkExtent2D{} : extent;
    format_ = format;
    mode_ = mode;
    is_stale_ = false;
    if (made != VK_SUCCESS) return device_->failed(made, "không tạo được swapchain");
    return is_hidden ? ok() : adopt_images(usage);
}

Status SwapchainVk::adopt_images(TextureUsage usage) {
    auto* const device = device_->handle();
    std::uint32_t count = 0;
    vkGetSwapchainImagesKHR(device, swapchain_, &count, nullptr);
    std::vector<VkImage> images(count);
    const VkResult listed = vkGetSwapchainImagesKHR(device, swapchain_, &count, images.data());
    if (listed != VK_SUCCESS) return device_->failed(listed, "không lấy được ảnh của swapchain");
    images.resize(count);
    // Khác gốc: gốc khởi tạo chỉ định ba trường; name của TextureDesc đã bỏ {} nên khởi tạo chỉ
    // định thiếu trường bị -Wmissing-field-initializers chặn.
    TextureDesc desc;
    desc.format = format_;
    desc.width = extent_.width;
    desc.height = extent_.height;
    desc.usage = usage;
    // Khác gốc: gốc là vòng for có câu if (!adopted) return adopted trong thân; ở đây điều kiện
    // dừng lên điều kiện lặp, cùng thứ tự duyệt, dừng ở lỗi đầu tiên.
    Status adopted = ok();
    for (auto image = images.begin(); image != images.end() && adopted; ++image) {
        adopted = adopt_image(*image, desc);
    }
    return adopted;
}

Status SwapchainVk::adopt_image(VkImage image, const TextureDesc& desc) {
    const TextureHandle texture = device_->adopt(image, desc);
    if (!texture) return fail(ErrorCode::kExhausted, "hết ô trong bảng texture cho ảnh swapchain");
    images_.push_back(texture);
    const Result<TextureViewHandle> view = device_->create_view({.name = "swapchain", .texture = texture});
    if (!view) return std::unexpected(view.error());
    views_.push_back(*view);
    const Result<VkSemaphore> semaphore = create_semaphore(*device_);
    if (!semaphore) return std::unexpected(semaphore.error());
    present_ready_.push_back(*semaphore);
    return ok();
}

// Gọi khi GPU đã rỗi. Semaphore đi qua hàng huỷ hoãn: lần present cuối có thể còn giữ chúng một lúc
// sau khi hàng đợi đã rỗi.
// noexcept chủ ý của gốc (hàm huỷ gọi nó): hàng huỷ hoãn hết bộ nhớ thì std::terminate (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
void SwapchainVk::drop_images() noexcept {
    for (const TextureViewHandle view : views_) {
        device_->release(view);
    }
    for (const TextureHandle image : images_) {
        device_->release(image);
    }
    for (auto* const semaphore : present_ready_) {
        retire_semaphore(*device_, semaphore);
    }
    for (const Signal& signal : acquire_ready_) {
        retire_semaphore(*device_, signal.handle);
    }
    views_.clear();
    images_.clear();
    present_ready_.clear();
    acquire_ready_.clear();
    is_acquired_ = false;
    is_submitted_ = false;
}

// Semaphore acquire dùng lại được khi lần nộp đã chờ nó chạy xong: lúc ấy phép chờ chắc chắn đã
// tiêu tín hiệu. Xoay vòng theo số ảnh thì không đủ: GPU chậm có thể còn chưa chạm tới lần nộp cũ.
Result<std::size_t> SwapchainVk::free_signal() {
    const std::uint64_t done = device_->completed(QueueType::kGraphics);
    const auto is_free = [done](const Signal& signal) { return signal.used_at <= done; };
    const auto found = std::ranges::find_if(acquire_ready_, is_free);
    const auto index = static_cast<std::size_t>(found - acquire_ready_.begin());
    if (found != acquire_ready_.end()) return index;
    const Result<VkSemaphore> semaphore = create_semaphore(*device_);
    if (!semaphore) return std::unexpected(semaphore.error());
    acquire_ready_.push_back({.handle = *semaphore});
    return acquire_ready_.size() - 1;
}

Result<std::uint32_t> SwapchainVk::acquire() {
    if (is_acquired_) return fail(kState, "acquire khi ảnh trước chưa được present");
    const bool is_usable = swapchain_ != VK_NULL_HANDLE && !is_stale_;
    if (!is_usable) return fail(kState, "bề mặt đã đổi, cần resize trước khi acquire");
    const Result<std::size_t> signal = free_signal();
    if (!signal) return std::unexpected(signal.error());
    auto* const semaphore = acquire_ready_.at(*signal).handle;
    // 100 ms chứ không phải vô hạn: luồng cửa sổ join luồng vẽ trong lúc bề mặt sắp mất (Android
    // pause). Chờ mãi thì join không xong và cửa sổ không huỷ được. Hết hạn thì semaphore không
    // được báo, lần sau dùng lại được.
    constexpr std::uint64_t kAcquireWaitNs = 100'000'000;
    std::uint32_t index = 0;
    const VkResult acquired =
        vkAcquireNextImageKHR(device_->handle(), swapchain_, kAcquireWaitNs, semaphore, VK_NULL_HANDLE, &index);
    if (acquired == VK_TIMEOUT) return fail(ErrorCode::kTimeout, "hết hạn chờ ảnh swapchain");
    // SUBOPTIMAL: ảnh vẫn vẽ được cho khung này, khung sau phải dựng lại.
    const bool is_changed = acquired == VK_ERROR_OUT_OF_DATE_KHR || acquired == VK_SUBOPTIMAL_KHR;
    if (is_changed) is_stale_ = true;
    if (acquired == VK_ERROR_OUT_OF_DATE_KHR) return fail(kState, "bề mặt đã đổi cỡ, cần resize");
    const bool has_image = acquired == VK_SUCCESS || acquired == VK_SUBOPTIMAL_KHR;
    if (!has_image) return device_->failed(acquired, "không lấy được ảnh của swapchain");
    turn_ = *signal;
    current_ = index;
    is_acquired_ = true;
    is_submitted_ = false;
    return index;
}

void SwapchainVk::mark_submitted(std::uint64_t value) noexcept {
    acquire_ready_.at(turn_).used_at = value;
    is_submitted_ = true;
}

TextureHandle SwapchainVk::image(std::uint32_t index) const {
    return index < images_.size() ? images_.at(index) : TextureHandle{};
}

TextureViewHandle SwapchainVk::view(std::uint32_t index) const {
    return index < views_.size() ? views_.at(index) : TextureViewHandle{};
}

std::uint32_t SwapchainVk::image_count() const noexcept {
    return static_cast<std::uint32_t>(images_.size());
}

Status SwapchainVk::present() {
    const bool is_ready = is_acquired_ && is_submitted_;
    if (!is_ready) return fail(kState, "present: chưa acquire hoặc chưa nộp với present_target");
    // Khác gốc: gốc viết const VkSemaphore wait rồi lấy &wait; const trên typedef con trỏ bị
    // misc-misplaced-const chặn, nên semaphore nằm trong mảng một phần tử.
    const std::array<VkSemaphore, 1> wait{rendered()};
    VkPresentInfoKHR info{};
    info.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
    info.waitSemaphoreCount = 1;
    info.pWaitSemaphores = wait.data();
    info.swapchainCount = 1;
    info.pSwapchains = &swapchain_;
    info.pImageIndices = &current_;
    // presentId tăng ngặt theo swapchain: số thứ tự của lần present này.
    const std::uint64_t id = presents_ + 1;
    VkPresentIdKHR numbered{};
    numbered.sType = VK_STRUCTURE_TYPE_PRESENT_ID_KHR;
    numbered.swapchainCount = 1;
    numbered.pPresentIds = &id;
    if (reports_shown()) info.pNext = &numbered;
    presents_ = id;
    const VkResult presented = present_locked(device_->queue(QueueType::kGraphics), info);
    is_acquired_ = false;
    // Bề mặt đổi ngay lúc present: khung này coi như đã trình bày, lần acquire kế báo cần resize.
    const bool is_changed = presented == VK_ERROR_OUT_OF_DATE_KHR || presented == VK_SUBOPTIMAL_KHR;
    if (is_changed) is_stale_ = true;
    if (is_changed || presented == VK_SUCCESS) return ok();
    return device_->failed(presented, "present thất bại");
}

// vkWaitForPresentKHR đòi đồng bộ ngoài trên swapchain như present: chỉ gọi từ luồng vẽ (lớp này không an
// toàn đa luồng, xem gpu::Swapchain).
Status SwapchainVk::wait_shown(std::uint64_t count, std::chrono::nanoseconds timeout) {
    if (!reports_shown()) return fail(ErrorCode::kUnsupported, "thiết bị không có VK_KHR_present_wait");
    if (swapchain_ == VK_NULL_HANDLE || is_stale_) return fail(kState, "bề mặt đã đổi, cần resize");
    if (count == 0 || count > presents_) return fail(ErrorCode::kInvalidArgument, "lần present chưa nộp");
    const auto nanoseconds = static_cast<std::uint64_t>(std::max<std::int64_t>(timeout.count(), 0));
    const VkResult waited = device_->wait_for_present()(device_->handle(), swapchain_, count, nanoseconds);
    if (waited == VK_TIMEOUT) return fail(ErrorCode::kTimeout, "hết hạn chờ ảnh lên màn");
    const bool is_changed = waited == VK_ERROR_OUT_OF_DATE_KHR || waited == VK_SUBOPTIMAL_KHR;
    if (is_changed) is_stale_ = true;
    if (waited == VK_SUCCESS || waited == VK_SUBOPTIMAL_KHR) return ok();
    if (waited == VK_ERROR_OUT_OF_DATE_KHR) return fail(kState, "bề mặt đã đổi cỡ, cần resize");
    return device_->failed(waited, "không chờ được ảnh lên màn");
}

// Rộng rồi cao là thứ tự quen của mọi API cỡ ảnh; chữ ký do gpu::Swapchain định (lệch API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
Status SwapchainVk::resize(std::uint32_t width, std::uint32_t height) {
    const Status idle = device_->wait_idle();
    if (!idle) return idle;
    drop_images();
    desc_.width = width;
    desc_.height = height;
    return build();
}

} // namespace game::gpu::vulkan
