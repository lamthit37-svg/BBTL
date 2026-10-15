/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/device.cpp
 *  PHÂN HỆ   : Gpu / Device
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cửa chọn backend của tầng đồ hoạ: tên và phép phân tích của các enum công
 *    khai, danh sách backend có trong bản dựng, liệt kê adapter và tạo thiết
 *    bị. Tệp duy nhất của phần chung biết tên các backend; mọi thứ khác đi qua
 *    giao diện Device.
 *  - Nguồn: Forge2 src/gpu/device.cpp@d7fcd76. Khác gốc: enumerator mang tiền
 *    tố k; CMake của game_gpu định nghĩa GAME_GPU_D3D12 và GAME_GPU_D3D11;
 *    thiếu macro thì backend đó trả kUnsupported; tham số c của lower thành
 *    letter; tham số lambda của is_same_word đổi tên vì trùng tên tham số của
 *    hàm.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "gpu/device.hpp"

#include "core/error.hpp"
#include "gpu/types.hpp"
#include "gpu/vulkan/device.hpp"

#if defined(GAME_GPU_D3D12)
#include "gpu/d3d12/entry.hpp"
#endif
#if defined(GAME_GPU_D3D11)
#include "gpu/d3d11/entry.hpp"
#endif
#if defined(GAME_GPU_GLES)
#include "gpu/gles/entry.hpp"
#endif

#include <algorithm>
#include <array>
#include <chrono>
#include <cstdint>
#include <memory>
#include <optional>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace game::gpu {

namespace {

// Thứ tự ưu tiên khi chỗ gọi không chọn. D3D12 đứng trước vì đó là đường gốc của Windows.
// Khác gốc: thiếu GAME_GPU_D3D12 thì danh sách chỉ còn Vulkan, đúng hợp đồng của
// available_backends (backend dựng được trong bản dựng này).
// Vulkan 1.3 phần cứng được chọn ở create_present_device. Danh sách này là thứ tự khi backend
// đã xin trả kUnsupported: D3D (Windows) trước GLES. GLES là đường cuối, đúng đo dài của TLBB
// (D3D11 đều hơn một bài GL ngắn) và đúng Android khi không có D3D.
#if defined(GAME_GPU_D3D12) && defined(GAME_GPU_D3D11) && defined(GAME_GPU_GLES)
constexpr std::array kBackends{Backend::kD3D12, Backend::kVulkan, Backend::kD3D11, Backend::kGles};
#elif defined(GAME_GPU_D3D12) && defined(GAME_GPU_D3D11)
constexpr std::array kBackends{Backend::kD3D12, Backend::kVulkan, Backend::kD3D11};
#elif defined(GAME_GPU_D3D12)
constexpr std::array kBackends{Backend::kD3D12, Backend::kVulkan};
#elif defined(GAME_GPU_D3D11) && defined(GAME_GPU_GLES)
constexpr std::array kBackends{Backend::kVulkan, Backend::kD3D11, Backend::kGles};
#elif defined(GAME_GPU_D3D11)
constexpr std::array kBackends{Backend::kVulkan, Backend::kD3D11};
#elif defined(GAME_GPU_GLES)
constexpr std::array kBackends{Backend::kVulkan, Backend::kGles};
#else
constexpr std::array kBackends{Backend::kVulkan};
#endif

constexpr std::array kPresentModes{PresentMode::kFifo, PresentMode::kImmediate, PresentMode::kMailbox};

[[nodiscard]] constexpr char lower(char letter) noexcept {
    const bool is_upper = letter >= 'A' && letter <= 'Z';
    return is_upper ? static_cast<char>(letter - 'A' + 'a') : letter;
}

// So chuỗi ASCII không phân biệt hoa thường.
[[nodiscard]] bool is_same_word(std::string_view left, std::string_view right) noexcept {
    // Khác gốc: tham số của lambda trùng tên left, right của hàm (-Wshadow), nên đổi tên.
    const auto matches = [](char first, char second) { return lower(first) == lower(second); };
    return std::ranges::equal(left, right, matches);
}

} // namespace

std::string_view name(Backend backend) noexcept {
    switch (backend) {
    case Backend::kVulkan: return "vulkan";
    case Backend::kD3D12: return "d3d12";
    case Backend::kD3D11: return "d3d11";
    case Backend::kGles: return "gles";
    }
    return {};
}

std::optional<Backend> parse_backend(std::string_view text) noexcept {
    if (is_same_word(text, "vulkan")) return Backend::kVulkan;
    if (is_same_word(text, "d3d12")) return Backend::kD3D12;
    if (is_same_word(text, "d3d11")) return Backend::kD3D11;
    if (is_same_word(text, "gles")) return Backend::kGles;
    return std::nullopt;
}

std::string_view name(DeviceLoss loss) noexcept {
    switch (loss) {
    case DeviceLoss::kNone: return "none";
    case DeviceLoss::kReset: return "reset";
    case DeviceLoss::kRemoved: return "removed";
    case DeviceLoss::kOutOfMemory: return "out_of_memory";
    }
    return {};
}

Status Swapchain::wait_shown(std::uint64_t count, std::chrono::nanoseconds timeout) {
    static_cast<void>(count);
    static_cast<void>(timeout);
    return core::fail(ErrorCode::kUnsupported, "bề mặt không báo lúc ảnh lên màn");
}

std::string_view name(PresentMode mode) noexcept {
    switch (mode) {
    case PresentMode::kFifo: return "fifo";
    case PresentMode::kImmediate: return "immediate";
    case PresentMode::kMailbox: return "mailbox";
    }
    return {};
}

std::optional<PresentMode> parse_present_mode(std::string_view text) noexcept {
    const auto matches = [text](PresentMode mode) { return is_same_word(text, name(mode)); };
    const auto found = std::ranges::find_if(kPresentModes, matches);
    if (found == kPresentModes.end()) return std::nullopt;
    return *found;
}

std::span<const Backend> available_backends() noexcept {
    return kBackends;
}

// Không default: thêm backend mà quên ở đây là C4062.
// Khác gốc: lời gọi vào backend D3D12 ở hàm này và ở create_device nằm sau GAME_GPU_D3D12; thiếu
// macro thì nhánh D3D12 trả kUnsupported thay vì gọi mã chưa được chép.
Result<std::vector<AdapterInfo>> enumerate_adapters(Backend backend) {
    switch (backend) {
    case Backend::kD3D12:
#if defined(GAME_GPU_D3D12)
        return d3d12::adapters();
#else
        return core::fail(ErrorCode::kUnsupported, "backend D3D12 chưa được dựng trong bản này");
#endif
    case Backend::kVulkan: return vulkan::adapters();
    case Backend::kD3D11:
#if defined(GAME_GPU_D3D11)
        return d3d11::adapters();
#else
        return core::fail(ErrorCode::kUnsupported, "backend D3D11 chưa được dựng trong bản này");
#endif
    case Backend::kGles:
#if defined(GAME_GPU_GLES)
        return gles::adapters();
#else
        return core::fail(ErrorCode::kUnsupported, "backend GLES chưa được dựng trong bản này");
#endif
    }
    return core::fail(ErrorCode::kUnsupported, "backend không có trong bản dựng", name(backend));
}

Result<std::unique_ptr<Device>> create_device(const DeviceDesc& desc) {
    switch (desc.backend) {
    case Backend::kD3D12:
#if defined(GAME_GPU_D3D12)
        return d3d12::create(desc);
#else
        return core::fail(ErrorCode::kUnsupported, "backend D3D12 chưa được dựng trong bản này");
#endif
    case Backend::kVulkan: return vulkan::VulkanDevice::create(desc);
    case Backend::kD3D11:
#if defined(GAME_GPU_D3D11)
        return d3d11::create(desc);
#else
        return core::fail(ErrorCode::kUnsupported, "backend D3D11 chưa được dựng trong bản này");
#endif
    case Backend::kGles:
#if defined(GAME_GPU_GLES)
        return gles::create(desc);
#else
        return core::fail(ErrorCode::kUnsupported, "backend GLES chưa được dựng trong bản này");
#endif
    }
    return core::fail(ErrorCode::kUnsupported, "backend không có trong bản dựng", name(desc.backend));
}

namespace {

using DeviceResult = Result<std::unique_ptr<Device>>;

struct TryArgs {
    const DeviceDesc* desc = nullptr;
    Backend backend = Backend::kVulkan;
};

[[nodiscard]] DeviceResult try_backend(const DeviceDesc& desc, Backend backend) {
    DeviceDesc next = desc;
    next.backend = backend;
    return create_device(next);
}

void keep_or_try(DeviceResult& opened, TryArgs args) {
    if (opened) return;
    if (opened.error().code() != ErrorCode::kUnsupported) return;
    if (args.backend == args.desc->backend) return;
    DeviceResult tried = try_backend(*args.desc, args.backend);
    opened = std::move(tried);
}

void try_one(DeviceResult& opened, const DeviceDesc& desc, Backend backend) {
    TryArgs args;
    args.desc = &desc;
    args.backend = backend;
    keep_or_try(opened, args);
}

void try_rest(DeviceResult& opened, const DeviceDesc& desc) {
    const std::span<const Backend> order = available_backends();
    for (const Backend backend : order)
        try_one(opened, desc, backend);
}

[[nodiscard]] bool has_hardware(Backend backend) {
    const Result<std::vector<AdapterInfo>> list = enumerate_adapters(backend);
    if (!list) return false;
    for (const AdapterInfo& info : *list) {
        if (!info.is_software) return true;
    }
    return false;
}

// Vulkan 1.3 phần cứng trước. Hết thì D3D phần cứng (Windows), rồi GLES phần cứng, rồi bản CPU.
// Không đo khung: bài đo ngắn của TLBB đã xếp nhầm backend trên RTX 5060.
Result<std::unique_ptr<Device>> open_automatic(const DeviceDesc& desc) {
    if (has_hardware(Backend::kVulkan)) return try_backend(desc, Backend::kVulkan);
#if defined(GAME_GPU_D3D12)
    if (has_hardware(Backend::kD3D12)) return try_backend(desc, Backend::kD3D12);
#endif
#if defined(GAME_GPU_D3D11)
    if (has_hardware(Backend::kD3D11)) return try_backend(desc, Backend::kD3D11);
#endif
#if defined(GAME_GPU_GLES)
    if (has_hardware(Backend::kGles)) return try_backend(desc, Backend::kGles);
#endif
    Result<std::unique_ptr<Device>> opened = try_backend(desc, Backend::kVulkan);
    try_rest(opened, desc);
    return opened;
}

} // namespace

Result<std::unique_ptr<Device>> create_present_device(const DeviceDesc& desc) {
    const bool is_automatic = desc.backend == Backend::kVulkan && !desc.adapter;
    if (is_automatic) return open_automatic(desc);
    Result<std::unique_ptr<Device>> opened = create_device(desc);
    try_rest(opened, desc);
    return opened;
}

} // namespace game::gpu
