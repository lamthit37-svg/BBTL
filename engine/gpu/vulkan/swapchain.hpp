/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/vulkan/swapchain.hpp
 *  PHÂN HỆ   : Gpu / Vulkan / Swapchain
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Swapchain của backend Vulkan — addSwapChain, acquireNextImage,
 *    queuePresent của Vulkan.c trong _Ref; vulkan/swapchain của Platium.
 *    Semaphore nhị phân mà WSI đòi cho acquire và present nằm trọn trong lớp
 *    này: Device::submit lấy hai semaphore của khung đang vẽ qua acquired() và
 *    rendered().
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Khác gốc: bề mặt đổi cỡ là giá trị trả về (InvalidState) chứ không phải lỗi phải đoán; chế độ
// trình bày thiếu thì hạ về Fifo và chỗ gọi đọc lại được chế độ thật; ảnh của swapchain vào cùng
// bảng tay nắm với mọi texture khác; semaphore acquire chỉ được dùng lại khi lần nộp đã chờ nó chạy
// xong (hai gốc xoay vòng theo số khung, sai khi GPU chậm hơn CPU quá số khung ấy). Nguồn: Forge2
// src/gpu/vulkan/swapchain.hpp@d7fcd76. Khác gốc (so với Forge2): enumerator mang tiền tố k; lần
// dựng đầu chạy vkCreateSwapchainKHR ở luồng phụ, ảnh nhận ở acquire đầu.

#pragma once

#include "gpu/pacer.hpp"
#include "gpu/vulkan/device.hpp"

#include <chrono>
#include <cstdint>
#include <thread>
#include <vector>

namespace game::gpu::vulkan {

// Tạo VkSurfaceKHR cho cửa sổ của nền tảng (HWND trên Windows); cài đặt ở surface_win32.cpp.
[[nodiscard]] Result<VkSurfaceKHR> create_surface(const Instance& instance, void* window);

// Chờ luồng dựng swapchain kết thúc rồi join, theo cách an toàn với cửa sổ của nền tảng (Windows
// xử lý thông điệp gửi tới cửa sổ trong lúc chờ); cài đặt cạnh create_surface.
void wait_builder(std::jthread& builder) noexcept;

class SwapchainVk final : public Swapchain {
public:
    [[nodiscard]] static Result<std::unique_ptr<Swapchain>> create(VulkanDevice& device, const SwapchainDesc& desc);

    SwapchainVk(VulkanDevice& device, VkSurfaceKHR surface, const SwapchainDesc& desc) noexcept
        : device_(&device), surface_(surface), desc_(desc) {}
    ~SwapchainVk() override;
    SwapchainVk(const SwapchainVk&) = delete;
    SwapchainVk& operator=(const SwapchainVk&) = delete;
    SwapchainVk(SwapchainVk&&) = delete;
    SwapchainVk& operator=(SwapchainVk&&) = delete;

    [[nodiscard]] Result<std::uint32_t> acquire() override;
    [[nodiscard]] TextureHandle image(std::uint32_t index) const override;
    [[nodiscard]] TextureViewHandle view(std::uint32_t index) const override;
    [[nodiscard]] std::uint32_t image_count() const noexcept override;
    [[nodiscard]] Status present() override;
    [[nodiscard]] Status resize(std::uint32_t width, std::uint32_t height) override;
    [[nodiscard]] Format format() const noexcept override { return format_; }
    [[nodiscard]] PresentMode present_mode() const noexcept override { return mode_; }
    [[nodiscard]] bool is_current(std::uint32_t width,
        std::uint32_t height) const noexcept override;
    [[nodiscard]] std::uint32_t width() const noexcept override { return extent_.width; }
    [[nodiscard]] std::uint32_t height() const noexcept override { return extent_.height; }
    [[nodiscard]] bool reports_shown() const noexcept override { return device_->traits().present_wait; }
    [[nodiscard]] std::uint64_t presents() const noexcept override { return presents_; }
    [[nodiscard]] Status wait_shown(std::uint64_t count, std::chrono::nanoseconds timeout) override;
    [[nodiscard]] bool paces_present() const noexcept override {
        return device_->traits().display_timing;
    }
    [[nodiscard]] bool holds_cadence() const noexcept override {
        const auto next = static_cast<std::uint32_t>(presents_ + 1);
        return pacer_.is_locked(next);
    }
    void set_present_interval(std::uint32_t refreshes) noexcept override {
        pacer_.set_interval(refreshes);
    }

    // Phần dưới do VulkanDevice::submit gọi khi lần nộp đặt present_target là swapchain này.
    // Đã acquire một ảnh mà chưa lần nộp nào nhận nó.
    [[nodiscard]] bool is_awaiting_submit() const noexcept { return is_acquired_ && !is_submitted_; }
    // Semaphore mà lần acquire gần nhất báo, và semaphore mà present của ảnh ấy chờ.
    [[nodiscard]] VkSemaphore acquired() const noexcept { return acquire_ready_.at(turn_).handle; }
    [[nodiscard]] VkSemaphore rendered() const noexcept { return present_ready_.at(current_); }
    // Lần nộp thứ value của hàng Graphics đã nhận hai semaphore trên.
    void mark_submitted(std::uint64_t value) noexcept;

private:
    // Một semaphore acquire và lần nộp đã chờ nó; 0 là chưa dùng.
    struct Signal {
        VkSemaphore handle = VK_NULL_HANDLE;
        std::uint64_t used_at = 0;
    };

    // Dựng (hoặc dựng lại) VkSwapchainKHR, ảnh, view và semaphore theo cỡ bề mặt hiện tại. Bề mặt
    // 0x0 (cửa sổ thu nhỏ) thì không có swapchain, và acquire báo InvalidState tới lần resize kế.
    [[nodiscard]] Status build();
    // Lần dựng của create: như build, nhưng vkCreateSwapchainKHR chạy ở builder_ và ảnh nhận ở
    // settle.
    [[nodiscard]] Status launch();
    // Đọc bề mặt, chọn cỡ, định dạng, chế độ và cách dùng ảnh rồi ghi vào lớp (đọc được trước khi
    // có ảnh); trả phần điền cho vkCreateSwapchainKHR.
    [[nodiscard]] Result<VkSwapchainCreateInfoKHR> plan();
    // Thay swapchain cũ bằng swapchain vừa tạo (made là kết quả của lần tạo) rồi nhận ảnh.
    [[nodiscard]] Status take(VkResult made, VkSwapchainKHR created);
    // builder_ còn chạy thì chờ nó rồi nhận swapchain nó tạo, chưa nhận ảnh; trả kết quả lần tạo.
    [[nodiscard]] VkResult join_builder() noexcept;
    // builder_ còn chạy thì join_builder rồi nhận ảnh. Lỗi của lần dựng đầu hiện ở đây.
    [[nodiscard]] Status settle();
    // settle, rồi InvalidState khi không có swapchain hoặc bề mặt đã đổi: điều kiện của acquire.
    [[nodiscard]] Status ready();
    [[nodiscard]] bool is_hidden() const noexcept {
        return extent_.width == 0 || extent_.height == 0;
    }
    [[nodiscard]] Status adopt_images(TextureUsage usage);
    [[nodiscard]] Status adopt_image(VkImage image, const TextureDesc& desc);
    // Chỉ số trong acquire_ready_ của một semaphore dùng được; tạo thêm khi mọi cái còn bận.
    [[nodiscard]] Result<std::size_t> free_signal();
    // Trả ảnh, view và semaphore; giữ lại VkSwapchainKHR để làm oldSwapchain của lần dựng kế.
    void drop_images() noexcept;
    // Lúc hẹn cho lần present id (VK_GOOGLE_display_timing): đọc chu kỳ quét nếu chưa có, nhận các
    // mốc trình thật mới vào pacer_, rồi hỏi pacer_. 0 là không ràng buộc.
    [[nodiscard]] std::uint64_t plan_present(std::uint32_t id) noexcept;
    void read_refresh() noexcept;
    void read_shown() noexcept;

    VulkanDevice* device_;
    VkSurfaceKHR surface_;
    SwapchainDesc desc_;
    VkSwapchainKHR swapchain_ = VK_NULL_HANDLE;
    VkExtent2D extent_{};
    Format format_ = Format::kUnknown;
    PresentMode mode_ = PresentMode::kFifo;
    std::vector<TextureHandle> images_;
    std::vector<TextureViewHandle> views_;
    std::vector<Signal> acquire_ready_;
    // Một semaphore present cho mỗi ảnh.
    std::vector<VkSemaphore> present_ready_;
    // Semaphore acquire và ảnh của khung đang vẽ.
    std::size_t turn_ = 0;
    std::uint32_t current_ = 0;
    // Ghi nhận VK_SUBOPTIMAL_KHR: dựng lại đúng một lần cho tới khi một present báo VK_SUCCESS.
    void note_suboptimal() noexcept;
    bool is_acquired_ = false;
    bool is_submitted_ = false;
    // Bề mặt đã đổi (cỡ, xoay): phải resize trước lần acquire kế.
    bool is_stale_ = false;
    // Đã dựng lại một lần vì VK_SUBOPTIMAL_KHR mà bề mặt vẫn báo suboptimal: trạng thái bền của bề mặt
    // (Android: màn xoay, preTransform khác currentTransform), không phải thay đổi mới; bỏ qua.
    bool has_rebuilt_for_suboptimal_ = false;
    // Số present đã nộp với swapchain_ hiện tại; cũng là presentId (VkPresentIdKHR) của lần cuối.
    std::uint64_t presents_ = 0;
    // Lịch hẹn lúc trình (VK_GOOGLE_display_timing). Số nhịp mỗi ảnh giữ qua resize; mốc neo và chu
    // kỳ quét bỏ khi đổi swapchain_. Chỉ luồng vẽ đụng, như mọi thứ khác của lớp.
    PresentPacer pacer_{};
    // Cách dùng ảnh mà plan chọn; settle nhận ảnh theo nó.
    TextureUsage usage_ = TextureUsage::kNone;
    // Lần dựng đầu: vkCreateSwapchainKHR tốn ~150 ms trên NVIDIA (đo 2026-10-17), luồng vẽ dựng
    // pipeline và nạp cảnh trong lúc ấy. builder_ ghi built_ và built_chain_ rồi kết thúc; luồng vẽ
    // chỉ đọc chúng sau join (join là mốc happens-before, không cần khoá). builder_ khai sau cùng
    // để hai trường nó ghi sống lâu hơn nó.
    VkResult built_ = VK_SUCCESS;
    VkSwapchainKHR built_chain_ = VK_NULL_HANDLE;
    std::jthread builder_;
};

} // namespace game::gpu::vulkan
