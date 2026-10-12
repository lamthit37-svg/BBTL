// Test của gpu chạy trên GPU thật, lớp kiểm tra bật, cho Vulkan, D3D12 và D3D11: tạo thiết bị, rồi ghi
// một buffer Upload, chép nó sang buffer Readback bằng một danh sách lệnh và đọc ngược về CPU. Ca
// chép đi qua bộ nhớ, danh sách lệnh, nộp lệnh, chờ GPU và huỷ hoãn. Cuối mỗi ca lớp kiểm tra không
// được báo lỗi nào. Thiếu lớp kiểm tra thì thiết bị vẫn tạo được và phép đếm lỗi luôn bằng 0.
#include "core/check.hpp"
#include "core/error.hpp"
#include "gpu/command.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/gles/gl_api.hpp"
#include "gpu/gles/pick.hpp"
#include "gpu/gles/probe.hpp"
#include "gpu/handle.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"
#include "test.hpp"

#if defined(_WIN32)
#include "core/win32.hpp"
#include <winuser.h>
#endif

#include <algorithm>
#include <array>
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <expected>
#include <format>
#include <memory>
#include <span>
#include <string>

namespace game::test {
namespace {

constexpr std::size_t kBytes = 256;

using DeviceResult = core::Result<std::unique_ptr<gpu::Device>>;
using Pattern = std::array<std::byte, kBytes>;

[[nodiscard]] DeviceResult validated_device(gpu::Backend backend) {
    gpu::DeviceDesc desc;
    desc.backend = backend;
    desc.is_validated = true;
    return gpu::create_device(desc);
}

struct BufferKind {
    gpu::MemoryDomain memory = gpu::MemoryDomain::kDevice;
    gpu::BufferUsage usage = gpu::BufferUsage::kNone;
};

[[nodiscard]] core::Result<gpu::BufferHandle> make_buffer(gpu::Device& device, BufferKind kind) {
    gpu::BufferDesc desc;
    desc.name = "gpu_tests.buffer";
    desc.size = kBytes;
    desc.usage = kind.usage;
    desc.memory = kind.memory;
    return device.create_buffer(desc);
}

struct BufferPair {
    gpu::BufferHandle source{};
    gpu::BufferHandle target{};
};

// Chép trọn source sang target bằng một danh sách lệnh rồi chờ GPU chạy xong.
[[nodiscard]] core::Status copy_and_wait(gpu::Device& device, const BufferPair& pair) {
    const core::Result<gpu::CommandList*> list = device.begin_commands(gpu::QueueType::kGraphics);
    if (!list) return std::unexpected(list.error());
    const gpu::BufferCopy region{.source_offset = 0, .target_offset = 0, .size = kBytes};
    (*list)->copy_buffer(pair.source, pair.target, region);
    gpu::SubmitDesc submit;
    submit.lists = std::span(&*list, 1);
    const core::Status submitted = device.submit(gpu::QueueType::kGraphics, submit);
    if (!submitted) return submitted;
    const core::Status idle = device.wait_idle();
    if (!idle) return idle;
    return device.end_frame();
}

[[nodiscard]] Pattern make_pattern() noexcept {
    Pattern pattern{};
    for (std::size_t i = 0; i < kBytes; ++i) {
        pattern.at(i) = static_cast<std::byte>(((i * 7) + 3) & 0xFFU);
    }
    return pattern;
}

void device_starts(Context& context, gpu::Backend backend) {
    const DeviceResult device = validated_device(backend);
    context.expect(device.has_value(), "tạo được thiết bị có lớp kiểm tra");
    if (!device) return;
    const gpu::AdapterInfo& adapter = (*device)->adapter();
    context.expect(!adapter.name.empty(), "thiết bị có tên card");
    context.expect(adapter.backend == backend, "backend đúng như đã xin");
    context.expect((*device)->validation_errors() == 0, "tạo thiết bị không sinh lỗi kiểm tra");
}

void buffer_round_trip(Context& context, gpu::Backend backend) {
    const DeviceResult made = validated_device(backend);
    context.expect(made.has_value(), "tạo được thiết bị có lớp kiểm tra");
    if (!made) return;
    gpu::Device& device = **made;
    const BufferKind upload_kind{.memory = gpu::MemoryDomain::kUpload, .usage = gpu::BufferUsage::kCopySource};
    const BufferKind readback_kind{.memory = gpu::MemoryDomain::kReadback, .usage = gpu::BufferUsage::kCopyDest};
    const core::Result<gpu::BufferHandle> upload = make_buffer(device, upload_kind);
    const core::Result<gpu::BufferHandle> readback = make_buffer(device, readback_kind);
    context.expect(upload.has_value() && readback.has_value(), "tạo được hai buffer");
    if (!upload || !readback) return;
    const Pattern pattern = make_pattern();
    Pattern read{};
    context.expect(device.write_buffer(*upload, 0, pattern).has_value(), "ghi buffer Upload");
    const BufferPair pair{.source = *upload, .target = *readback};
    context.expect(copy_and_wait(device, pair).has_value(), "chép bằng GPU và chờ xong");
    context.expect(device.read_buffer(*readback, 0, read).has_value(), "đọc buffer Readback");
    context.expect(read == pattern, "dữ liệu đọc ngược trùng dữ liệu đã ghi");
    device.destroy(*upload);
    device.destroy(*readback);
    context.expect(device.validation_errors() == 0, "lớp kiểm tra không báo lỗi nào");
}

void vulkan_device_starts(Context& context) {
    device_starts(context, gpu::Backend::kVulkan);
}

void vulkan_buffer_round_trip(Context& context) {
    buffer_round_trip(context, gpu::Backend::kVulkan);
}

void d3d12_device_starts(Context& context) {
    device_starts(context, gpu::Backend::kD3D12);
}

void d3d12_buffer_round_trip(Context& context) {
    buffer_round_trip(context, gpu::Backend::kD3D12);
}

void d3d11_device_starts(Context& context) {
    device_starts(context, gpu::Backend::kD3D11);
}

void d3d11_buffer_round_trip(Context& context) {
    buffer_round_trip(context, gpu::Backend::kD3D11);
}

void gles_device_starts(Context& context) {
    const DeviceResult device = validated_device(gpu::Backend::kGles);
    if (!device) {
        context.expect(false, std::format("GLES: {}", device.error()));
        return;
    }
    device_starts(context, gpu::Backend::kGles);
}

void gles_buffer_round_trip(Context& context) {
    buffer_round_trip(context, gpu::Backend::kGles);
}

void gles_names_are_not_ranked_by_unused_features(Context& context) {
    const gpu::gles::RendererClass phone = gpu::gles::classify_renderer("PowerVR Rogue GE8320");
    const gpu::gles::RendererClass apu = gpu::gles::classify_renderer("AMD Radeon(TM) Graphics");
    const gpu::gles::RendererClass card = gpu::gles::classify_renderer("NVIDIA GeForce RTX 5060");
    const gpu::gles::RendererClass software = gpu::gles::classify_renderer("llvmpipe");
    context.expect(!phone.is_discrete && !phone.is_software, "GE8320 không phải card rời");
    context.expect(!apu.is_discrete, "Radeon Graphics là APU");
    context.expect(card.is_discrete && !card.is_software, "RTX 5060 là card rời");
    context.expect(software.is_software, "llvmpipe là GPU CPU");
    gpu::gles::GlProfile plain;
    plain.major = 4;
    plain.minor = 3;
    plain.max_uniform_blocks = 2;
    plain.max_storage_blocks = 1;
    gpu::gles::GlProfile decorated = plain;
    decorated.has_srgb = true;
    decorated.max_samples = 8;
    decorated.max_anisotropy = 16;
    decorated.has_timer = true;
    decorated.has_buffer_storage = true;
    decorated.max_texture = 16384;
    decorated.has_compute = true;
    context.expect(gpu::gles::profile_score(plain) == gpu::gles::profile_score(decorated),
        "điểm GL không thưởng tính năng forward không dùng");
    plain.is_software = true;
    context.expect(gpu::gles::profile_score(plain) == 0, "GPU CPU không được điểm");
}

// Driver giả cho probe_context: một giới hạn theo tên, tên lạ trả 0 như driver thật trả cho
// truy vấn nó không biết.
struct FakeLimit {
    std::uint32_t name = 0;
    int value = 0;
};

[[nodiscard]] int fake_limit(std::span<const FakeLimit> limits, std::uint32_t name) noexcept {
    const auto is_named = [name](const FakeLimit& limit) { return limit.name == name; };
    const auto found = std::ranges::find_if(limits, is_named);
    return found == limits.end() ? 0 : found->value;
}

// Không khai số binding SSBO: probe phải nâng 0 lên trần spec khi bản GL đủ.
template <int Major, int Minor>
void GL_APIENTRY fake_integer(std::uint32_t name, int* value) {
    constexpr std::array<FakeLimit, 7> kLimits{{
        {.name = gpu::gles::GL_MAJOR_VERSION, .value = Major},
        {.name = gpu::gles::GL_MINOR_VERSION, .value = Minor},
        {.name = gpu::gles::GL_MAX_TEXTURE_SIZE, .value = 4096},
        {.name = gpu::gles::GL_MAX_SAMPLES, .value = 4},
        {.name = gpu::gles::GL_MAX_UNIFORM_BUFFER_BINDINGS, .value = 24},
        {.name = gpu::gles::GL_NUM_EXTENSIONS, .value = 1},
        {.name = gpu::gles::GL_MAX_TEXTURE_MAX_ANISOTROPY, .value = 16},
    }};
    *value = fake_limit(kLimits, name);
}

// GL trả chuỗi dưới kiểu GLubyte*; driver giả mượn một chuỗi char tĩnh.
[[nodiscard]] const std::uint8_t* gl_bytes(const char* text) noexcept {
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
    return reinterpret_cast<const std::uint8_t*>(text);
}

const std::uint8_t* GL_APIENTRY fake_string(std::uint32_t name) {
    if (name == gpu::gles::GL_RENDERER) return gl_bytes("PowerVR Rogue GE8320");
    if (name == gpu::gles::GL_VERSION) return gl_bytes("OpenGL ES 3.2 build 1.11");
    return nullptr;
}

const std::uint8_t* GL_APIENTRY fake_extension(std::uint32_t, std::uint32_t index) {
    if (index != 0) return nullptr;
    return gl_bytes("GL_EXT_texture_filter_anisotropic");
}

std::uint32_t GL_APIENTRY fake_error() {
    return 0;
}

template <int Major, int Minor>
[[nodiscard]] gpu::gles::GlProbe fake_probe(gpu::gles::GlFlavor flavor) {
    gpu::gles::GlFunctions api;
    api.get_string = &fake_string;
    api.get_stringi = &fake_extension;
    api.get_integer = &fake_integer<Major, Minor>;
    api.get_error = &fake_error;
    return gpu::gles::probe_context(api, flavor);
}

void gles_probe_follows_the_api_flavor(Context& context) {
    using gpu::gles::GlFlavor;
    using gpu::gles::GlProfile;
    const GlProfile phone = fake_probe<3, 1>(GlFlavor::kEmbedded).profile;
    context.expect(phone.is_es && phone.has_compute, "ES 3.1 có compute");
    context.expect(phone.max_anisotropy == 1, "context ES không hỏi anisotropy");
    context.expect(phone.max_storage_blocks == 8, "SSBO trả 0 được nâng lên trần spec");
    context.expect(phone.max_uniform_blocks == 24, "số khối uniform đọc từ driver");
    context.expect(phone.max_texture == 4096 && phone.max_samples == 4, "cỡ texture, số mẫu");
    context.expect(!phone.is_discrete && !phone.is_software, "tên card đi qua phân loại");
    const GlProfile old_phone = fake_probe<3, 0>(GlFlavor::kEmbedded).profile;
    context.expect(!old_phone.has_compute, "ES 3.0 chưa có compute");
    context.expect(old_phone.max_storage_blocks == 0, "ES 3.0 không được nâng SSBO");
    const GlProfile desktop = fake_probe<4, 6>(GlFlavor::kDesktop).profile;
    context.expect(!desktop.is_es && desktop.has_compute, "GL 4.6 có compute");
    context.expect(desktop.max_anisotropy == 16, "desktop hỏi anisotropy khi có extension");
    context.expect(desktop.max_storage_blocks == 8, "GL 4.6 được nâng SSBO");
    const GlProfile old_desktop = fake_probe<4, 2>(GlFlavor::kDesktop).profile;
    context.expect(!old_desktop.has_compute, "GL 4.2 chưa có compute");
    context.expect(old_desktop.max_storage_blocks == 0, "GL 4.2 không được nâng SSBO");
}

void gles_probe_copies_driver_strings(Context& context) {
    const gpu::gles::GlProbe probe = fake_probe<3, 1>(gpu::gles::GlFlavor::kEmbedded);
    context.expect(probe.renderer == "PowerVR Rogue GE8320", "chép GL_RENDERER");
    context.expect(probe.driver == "OpenGL ES 3.2 build 1.11", "chép GL_VERSION");
}

void gles_debug_sink_counts_only_errors(Context& context) {
    std::atomic<std::uint64_t> errors{0};
    const gpu::gles::DebugProc sink = gpu::gles::debug_sink();
    sink(0, gpu::gles::GL_DEBUG_TYPE_ERROR, 0, 0, 0, "lỗi thử của gpu_tests", &errors);
    context.expect(errors.load() == 1, "thông điệp lỗi được đếm");
    sink(0, 0, 0, 0, 0, "ghi chú thử", &errors);
    context.expect(errors.load() == 1, "thông điệp thường không đếm");
    sink(0, gpu::gles::GL_DEBUG_TYPE_ERROR, 0, 0, 0, nullptr, nullptr);
    context.expect(errors.load() == 1, "không có bộ đếm thì chỉ ghi log");
}

struct ClearRig {
    gpu::TextureHandle texture{};
    gpu::TextureViewHandle view{};
    gpu::BufferHandle readback{};
};

constexpr gpu::Format kTargetFormat = gpu::Format::kRgba8UnormSrgb;
constexpr std::uint32_t kTargetSide = 4;

// Đích màu khai sRGB cùng buffer đủ chỗ cho cả ảnh theo bước dòng đã đệm.
[[nodiscard]] core::Result<ClearRig> make_target(gpu::Device& device) {
    gpu::TextureDesc texture;
    texture.name = "gpu_tests.target";
    texture.format = kTargetFormat;
    texture.width = kTargetSide;
    texture.height = kTargetSide;
    texture.usage = gpu::TextureUsage::kColorTarget | gpu::TextureUsage::kCopySource;
    const core::Result<gpu::TextureHandle> image = device.create_texture(texture);
    if (!image) return std::unexpected(image.error());
    gpu::TextureViewDesc view;
    view.name = "gpu_tests.target";
    view.texture = *image;
    const core::Result<gpu::TextureViewHandle> seen = device.create_view(view);
    if (!seen) return std::unexpected(seen.error());
    gpu::BufferDesc buffer;
    buffer.name = "gpu_tests.readback";
    buffer.size = gpu::padded_row_bytes(kTargetFormat, kTargetSide) * kTargetSide;
    buffer.usage = gpu::BufferUsage::kCopyDest;
    buffer.memory = gpu::MemoryDomain::kReadback;
    const core::Result<gpu::BufferHandle> readback = device.create_buffer(buffer);
    if (!readback) return std::unexpected(readback.error());
    return ClearRig{.texture = *image, .view = *seen, .readback = *readback};
}

// Một lượt vẽ chỉ có lệnh xoá, rồi chép cả ảnh về buffer và chờ GPU chạy xong.
[[nodiscard]] core::Status clear_and_copy(gpu::Device& device, const ClearRig& target) {
    const core::Result<gpu::CommandList*> list = device.begin_commands(gpu::QueueType::kGraphics);
    if (!list) return std::unexpected(list.error());
    gpu::ColorTarget color;
    color.view = target.view;
    color.clear = {.red = 0.5F, .green = 0.25F, .blue = 0.0F, .alpha = 1.0F};
    gpu::RenderingDesc pass;
    pass.colors = std::span(&color, 1);
    (*list)->begin_rendering(pass);
    (*list)->end_rendering();
    const gpu::BufferTextureCopy region{};
    (*list)->copy_texture_to_buffer(target.texture, target.readback, std::span(&region, 1));
    gpu::SubmitDesc submit;
    submit.lists = std::span(&*list, 1);
    const core::Status submitted = device.submit(gpu::QueueType::kGraphics, submit);
    if (!submitted) return submitted;
    const core::Status idle = device.wait_idle();
    if (!idle) return idle;
    return device.end_frame();
}

[[nodiscard]] bool is_near(int seen, int wanted) noexcept {
    return std::abs(seen - wanted) <= 1;
}

// Backend GL cất đích khai sRGB như UNORM (thiết bị màu thô), nhưng màu xoá vẫn theo hợp đồng chung
// là số tuyến tính: điểm ảnh đọc về phải là số đã mã hoá sRGB, như mọi backend khác.
void gles_clear_of_srgb_target_is_encoded(Context& context) {
    const DeviceResult made = validated_device(gpu::Backend::kGles);
    context.expect(made.has_value(), "tạo được thiết bị GLES");
    if (!made) return;
    gpu::Device& device = **made;
    const core::Result<ClearRig> target = make_target(device);
    context.expect(target.has_value(), "tạo được đích màu sRGB và buffer đọc về");
    if (!target) return;
    context.expect(clear_and_copy(device, *target).has_value(), "xoá, chép về và chờ xong");
    std::array<std::byte, 4> pixel{};
    context.expect(device.read_buffer(target->readback, 0, pixel).has_value(), "đọc điểm ảnh đầu");
    const int red = std::to_integer<int>(pixel[0]);
    const int green = std::to_integer<int>(pixel[1]);
    const int blue = std::to_integer<int>(pixel[2]);
    const int alpha = std::to_integer<int>(pixel[3]);
    const std::string seen = std::format("điểm ảnh đọc về {} {} {} {}", red, green, blue, alpha);
    const bool is_color_encoded = is_near(red, 188) && is_near(green, 137) && is_near(blue, 0);
    context.expect(is_color_encoded && is_near(alpha, 255), seen);
    device.destroy(target->view);
    device.destroy(target->texture);
    device.destroy(target->readback);
    context.expect(device.validation_errors() == 0, "lớp kiểm tra không báo lỗi nào");
}

void depth_view_keeps_device(Context& context, gpu::Backend backend) {
    const DeviceResult made = validated_device(backend);
    context.expect(made.has_value(), "tạo được thiết bị");
    if (!made) return;
    gpu::Device& device = **made;
    gpu::TextureDesc texture_desc;
    texture_desc.name = "gpu_tests.depth";
    texture_desc.format = gpu::Format::kD32Float;
    texture_desc.width = 4;
    texture_desc.height = 4;
    texture_desc.usage = gpu::TextureUsage::kDepthStencilTarget;
    const core::Result<gpu::TextureHandle> texture = device.create_texture(texture_desc);
    context.expect(texture.has_value(), "tạo được depth D32");
    if (!texture) return;
    gpu::TextureViewDesc view_desc;
    view_desc.texture = *texture;
    const core::Result<gpu::TextureViewHandle> view = device.create_view(view_desc);
    context.expect(view.has_value(), "tạo được view depth");
    context.expect(device.loss() == gpu::DeviceLoss::kNone, "thiết bị không bị gỡ");
    context.expect(device.validation_errors() == 0, "lớp kiểm tra không báo lỗi");
    if (view) device.destroy(*view);
    device.destroy(*texture);
}

void submit_rejects_the_same_list_twice(Context& context, gpu::Backend backend) {
    const DeviceResult made = validated_device(backend);
    context.expect(made.has_value(), "tạo được thiết bị");
    if (!made) return;
    const core::Result<gpu::CommandList*> list = (*made)->begin_commands(gpu::QueueType::kGraphics);
    context.expect(list.has_value(), "mở được list");
    if (!list) return;
    std::array<gpu::CommandList*, 2> lists{*list, *list};
    gpu::SubmitDesc submit;
    submit.lists = lists;
    const core::Status submitted = (*made)->submit(gpu::QueueType::kGraphics, submit);
    context.expect(!submitted.has_value(), "submit từ chối cùng một list hai lần");
}

#if defined(_WIN32)
struct HiddenWindow {
    HWND hwnd = nullptr;
};

void close_hidden(HiddenWindow& window) {
    if (window.hwnd != nullptr) DestroyWindow(window.hwnd);
    UnregisterClassW(L"ThienlongGpuTest", GetModuleHandleW(nullptr));
    window.hwnd = nullptr;
}

[[nodiscard]] HiddenWindow open_hidden() {
    WNDCLASSW klass{};
    klass.lpfnWndProc = DefWindowProcW;
    klass.hInstance = GetModuleHandleW(nullptr);
    klass.lpszClassName = L"ThienlongGpuTest";
    RegisterClassW(&klass);
    HiddenWindow window;
    window.hwnd = CreateWindowExW(WS_EX_NOACTIVATE, klass.lpszClassName, L"", WS_POPUP, 0, 0, 64, 64, nullptr,
        nullptr, klass.hInstance, nullptr);
    return window;
}

void present_srgb(Context& context, gpu::Device& device, void* hwnd) {
    gpu::SwapchainDesc desc;
    desc.window = hwnd;
    desc.width = 64;
    desc.height = 64;
    const core::Result<std::unique_ptr<gpu::Swapchain>> chain = device.create_swapchain(desc);
    context.expect(chain.has_value(), "swapchain sRGB tạo được");
    context.expect(device.loss() == gpu::DeviceLoss::kNone, "thiết bị còn sống sau swapchain");
    context.expect(device.validation_errors() == 0, "lớp kiểm tra không báo lỗi");
}

void use_hidden(Context& context, gpu::Backend backend, HWND hwnd) {
    if (hwnd == nullptr) return;
    const DeviceResult made = validated_device(backend);
    context.expect(made.has_value(), "tạo được thiết bị");
    if (!made) return;
    present_srgb(context, **made, hwnd);
}

void swapchain_accepts_srgb(Context& context, gpu::Backend backend) {
    HiddenWindow window = open_hidden();
    context.expect(window.hwnd != nullptr, "tạo được cửa sổ ẩn");
    use_hidden(context, backend, window.hwnd);
    close_hidden(window);
}
#endif

void d3d12_depth_view_keeps_device(Context& context) {
    depth_view_keeps_device(context, gpu::Backend::kD3D12);
}

void d3d11_depth_view_keeps_device(Context& context) {
    depth_view_keeps_device(context, gpu::Backend::kD3D11);
}

void d3d12_rejects_duplicate_list(Context& context) {
    submit_rejects_the_same_list_twice(context, gpu::Backend::kD3D12);
}

void d3d11_rejects_duplicate_list(Context& context) {
    submit_rejects_the_same_list_twice(context, gpu::Backend::kD3D11);
}

void vulkan_rejects_duplicate_list(Context& context) {
    submit_rejects_the_same_list_twice(context, gpu::Backend::kVulkan);
}

void gles_rejects_duplicate_list(Context& context) {
    submit_rejects_the_same_list_twice(context, gpu::Backend::kGles);
}

#if defined(_WIN32)
void d3d12_swapchain_accepts_srgb(Context& context) {
    swapchain_accepts_srgb(context, gpu::Backend::kD3D12);
}

void d3d11_swapchain_accepts_srgb(Context& context) {
    swapchain_accepts_srgb(context, gpu::Backend::kD3D11);
}
#endif

constexpr std::array kCases{
    Case{.name = "vulkan_device_starts", .body = &vulkan_device_starts},
    Case{.name = "vulkan_buffer_round_trip", .body = &vulkan_buffer_round_trip},
    Case{.name = "vulkan_rejects_duplicate_list", .body = &vulkan_rejects_duplicate_list},
    Case{.name = "d3d12_device_starts", .body = &d3d12_device_starts},
    Case{.name = "d3d12_buffer_round_trip", .body = &d3d12_buffer_round_trip},
    Case{.name = "d3d12_depth_view_keeps_device", .body = &d3d12_depth_view_keeps_device},
    Case{.name = "d3d12_rejects_duplicate_list", .body = &d3d12_rejects_duplicate_list},
    Case{.name = "d3d11_device_starts", .body = &d3d11_device_starts},
    Case{.name = "d3d11_buffer_round_trip", .body = &d3d11_buffer_round_trip},
    Case{.name = "d3d11_depth_view_keeps_device", .body = &d3d11_depth_view_keeps_device},
    Case{.name = "d3d11_rejects_duplicate_list", .body = &d3d11_rejects_duplicate_list},
    Case{.name = "gles_device_starts", .body = &gles_device_starts},
    Case{.name = "gles_buffer_round_trip", .body = &gles_buffer_round_trip},
    Case{.name = "gles_rejects_duplicate_list", .body = &gles_rejects_duplicate_list},
    Case{.name = "gles_names_are_not_ranked_by_unused_features", .body = &gles_names_are_not_ranked_by_unused_features},
    Case{.name = "gles_probe_follows_the_api_flavor", .body = &gles_probe_follows_the_api_flavor},
    Case{.name = "gles_probe_copies_driver_strings", .body = &gles_probe_copies_driver_strings},
    Case{.name = "gles_debug_sink_counts_only_errors", .body = &gles_debug_sink_counts_only_errors},
#if defined(_WIN32)
    Case{.name = "d3d12_swapchain_accepts_srgb", .body = &d3d12_swapchain_accepts_srgb},
    Case{.name = "d3d11_swapchain_accepts_srgb", .body = &d3d11_swapchain_accepts_srgb},
#endif
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "gpu_tests: mọi ca phải qua");
    return 0;
}
