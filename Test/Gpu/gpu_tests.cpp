/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Gpu/gpu_tests.cpp
 *  PHÂN HỆ   : Gpu / Gpu Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Test gpu trên GPU thật, lớp kiểm tra bật, Vulkan, D3D12 và D3D11: chép
 *    buffer và texture khứ hồi, resolve, vòng present, stride của khe đỉnh
 *    theo pipeline (shader dịch lúc chạy bằng Slang). Cuối mỗi ca lớp kiểm
 *    tra không được báo lỗi nào (thiếu lớp thì phép đếm luôn bằng 0).
 *  - Mỗi ca hồi quy ghi lỗi D3D cũ mà nó giữ; đã đỏ trên backend trước khi
 *    sửa và xanh sau (2026-10-17).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "core/check.hpp"
#include "core/error.hpp"
#include "gpu/command.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/gles/gl_api.hpp"
#include "gpu/gles/pick.hpp"
#include "gpu/gles/probe.hpp"
#include "gpu/handle.hpp"
#include "gpu/pipeline.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"
#include "shader/compiler.hpp"
#include "shader/package.hpp"
#include "shader/types.hpp"
#include "test.hpp"

#if defined(_WIN32)
#include "core/win32.hpp"
#include "gpu/d3d11/convert.hpp"
#include "gpu/d3d12/convert.hpp"
#include <d3d11.h>
#include <d3d12.h>
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
#include <string_view>
#include <utility>
#include <vector>

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

// Buffer storage mà CPU ghi mỗi khung (palette và worlds của render::Forward). D3D12 từng gắn cờ
// UAV cho nó nên CreatePlacedResource2 trả E_INVALIDARG và client D3D12 không mở được.
void storage_upload_keeps_device(Context& context, gpu::Backend backend) {
    const DeviceResult made = validated_device(backend);
    context.expect(made.has_value(), "tạo được thiết bị có lớp kiểm tra");
    if (!made) return;
    gpu::Device& device = **made;
    const BufferKind kind{.memory = gpu::MemoryDomain::kUpload, .usage = gpu::BufferUsage::kStorage};
    const core::Result<gpu::BufferHandle> buffer = make_buffer(device, kind);
    context.expect(buffer.has_value(), "tạo được buffer storage ở bộ nhớ Upload");
    if (buffer) context.expect(device.write_buffer(*buffer, 0, make_pattern()).has_value(), "ghi được");
    if (buffer) device.destroy(*buffer);
    context.expect(device.loss() == gpu::DeviceLoss::kNone, "thiết bị còn sống");
    context.expect(device.validation_errors() == 0, "lớp kiểm tra không báo lỗi");
}

// Mọi tổ hợp lọc min, mag, mip, có và không có phép so sánh, cộng dị hướng. D3D11 và D3D12 từng mã
// hoá bộ lọc sai (trọng số 4/2/1 thay vì D3D1x_ENCODE_BASIC_FILTER) nên lọc tuyến tính ra mã lạ và
// lớp kiểm tra gỡ thiết bị ("Filter unrecognized").
void every_filter_keeps_device(Context& context, gpu::Backend backend) {
    const DeviceResult made = validated_device(backend);
    context.expect(made.has_value(), "tạo được thiết bị có lớp kiểm tra");
    if (!made) return;
    gpu::Device& device = **made;
    for (std::uint32_t code = 0; code < 18; ++code) {
        gpu::SamplerDesc desc;
        desc.min_filter = (code & 1U) != 0 ? gpu::Filter::kLinear : gpu::Filter::kNearest;
        desc.mag_filter = (code & 2U) != 0 ? gpu::Filter::kLinear : gpu::Filter::kNearest;
        desc.mip_filter = (code & 4U) != 0 ? gpu::Filter::kLinear : gpu::Filter::kNearest;
        desc.compare = (code & 8U) != 0 ? gpu::CompareOp::kLessOrEqual : gpu::CompareOp::kNever;
        desc.max_anisotropy = code >= 16 ? 8U : 1U;
        const core::Result<gpu::SamplerHandle> sampler = device.create_sampler(desc);
        context.expect(sampler.has_value(), std::format("tạo được sampler mã {}", code));
        if (sampler) device.destroy(*sampler);
    }
    context.expect(device.loss() == gpu::DeviceLoss::kNone, "thiết bị còn sống");
    context.expect(device.validation_errors() == 0, "lớp kiểm tra không báo lỗi");
}

// Một texture cùng chuỗi mip của nó, chép lên từ buffer Upload rồi chép về buffer Readback.
struct CopyShape {
    std::string_view name;
    gpu::Format format = gpu::Format::kUnknown;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::uint32_t mips = 1;
};

struct MipPlan {
    std::vector<gpu::BufferTextureCopy> regions;
    std::uint64_t bytes = 0;
};

// Bố cục buffer theo hợp đồng chung (check_rows ở gpu/check.cpp): mỗi mức bắt đầu ở bội của
// kTextureOffsetAlignment, dòng cách nhau padded_row_bytes, dòng cuối của mức cuối không đệm.
// Buffer cắt đúng ở đó: backend nào đòi thêm phần đệm của dòng cuối thì đỏ.
[[nodiscard]] MipPlan plan_mips(const CopyShape& shape) {
    MipPlan plan;
    std::uint64_t offset = 0;
    for (std::uint32_t mip = 0; mip < shape.mips; ++mip) {
        gpu::BufferTextureCopy region;
        region.buffer_offset = offset;
        region.mip = mip;
        plan.regions.push_back(region);
        const std::uint32_t width = gpu::mip_size(shape.width, mip);
        const std::uint32_t height = gpu::mip_size(shape.height, mip);
        plan.bytes = offset + gpu::staged_bytes(shape.format, width, height);
        offset = (plan.bytes + gpu::kTextureOffsetAlignment - 1) / gpu::kTextureOffsetAlignment * gpu::kTextureOffsetAlignment;
    }
    return plan;
}

struct CopyRig {
    gpu::TextureHandle texture{};
    gpu::BufferHandle upload{};
    gpu::BufferHandle readback{};
};

[[nodiscard]] core::Result<gpu::BufferHandle> make_staging(gpu::Device& device, std::uint64_t bytes, BufferKind kind) {
    gpu::BufferDesc desc;
    desc.name = "gpu_tests.staging";
    desc.size = bytes;
    desc.usage = kind.usage;
    desc.memory = kind.memory;
    return device.create_buffer(desc);
}

// readback rộng bằng upload khi read_bytes là 0.
[[nodiscard]] core::Result<CopyRig> make_copy_rig(gpu::Device& device, const CopyShape& shape, std::uint64_t bytes,
    std::uint64_t read_bytes = 0) {
    gpu::TextureDesc desc;
    desc.name = shape.name;
    desc.format = shape.format;
    desc.width = shape.width;
    desc.height = shape.height;
    desc.mip_levels = shape.mips;
    desc.usage = gpu::TextureUsage::kSampled | gpu::TextureUsage::kCopyDest | gpu::TextureUsage::kCopySource;
    const core::Result<gpu::TextureHandle> texture = device.create_texture(desc);
    if (!texture) return std::unexpected(texture.error());
    const BufferKind upload_kind{.memory = gpu::MemoryDomain::kUpload, .usage = gpu::BufferUsage::kCopySource};
    const BufferKind readback_kind{.memory = gpu::MemoryDomain::kReadback, .usage = gpu::BufferUsage::kCopyDest};
    const core::Result<gpu::BufferHandle> upload = make_staging(device, bytes, upload_kind);
    if (!upload) return std::unexpected(upload.error());
    const core::Result<gpu::BufferHandle> readback = make_staging(device, read_bytes == 0 ? bytes : read_bytes, readback_kind);
    if (!readback) return std::unexpected(readback.error());
    return CopyRig{.texture = *texture, .upload = *upload, .readback = *readback};
}

void issue_barrier(gpu::CommandList& list, const gpu::TextureBarrier& barrier) {
    const std::span<const gpu::BufferBarrier> buffers;
    const std::span<const gpu::GlobalBarrier> memory;
    list.barrier(buffers, std::span(&barrier, 1), memory);
}

[[nodiscard]] core::Status submit_and_wait(gpu::Device& device, gpu::CommandList* list) {
    gpu::SubmitDesc submit;
    submit.lists = std::span(&list, 1);
    const core::Status submitted = device.submit(gpu::QueueType::kGraphics, submit);
    if (!submitted) return submitted;
    const core::Status idle = device.wait_idle();
    if (!idle) return idle;
    return device.end_frame();
}

// Undefined sang CopyDest, như resource/upload.cpp làm với ảnh vừa tạo.
[[nodiscard]] gpu::TextureBarrier to_copy_dest(gpu::TextureHandle texture) noexcept {
    gpu::TextureBarrier barrier;
    barrier.texture = texture;
    barrier.stage_before = gpu::SyncStage::kAll;
    barrier.stage_after = gpu::SyncStage::kCopy;
    barrier.access_after = gpu::Access::kCopyWrite;
    barrier.layout_after = gpu::TextureLayout::kCopyDest;
    return barrier;
}

[[nodiscard]] gpu::TextureBarrier to_copy_source(gpu::TextureHandle texture, const gpu::TextureBarrier& before) noexcept {
    gpu::TextureBarrier barrier;
    barrier.texture = texture;
    barrier.stage_before = before.stage_after;
    barrier.access_before = before.access_after;
    barrier.layout_before = before.layout_after;
    barrier.stage_after = gpu::SyncStage::kCopy;
    barrier.access_after = gpu::Access::kCopyRead;
    barrier.layout_after = gpu::TextureLayout::kCopySource;
    return barrier;
}

// Chép lên theo vùng sent, rồi chép về theo vùng read.
struct BounceRegions {
    std::span<const gpu::BufferTextureCopy> sent;
    std::span<const gpu::BufferTextureCopy> read;
};

[[nodiscard]] core::Status bounce(gpu::Device& device, const CopyRig& rig, BounceRegions regions) {
    const core::Result<gpu::CommandList*> list = device.begin_commands(gpu::QueueType::kGraphics);
    if (!list) return std::unexpected(list.error());
    const gpu::TextureBarrier written = to_copy_dest(rig.texture);
    issue_barrier(**list, written);
    (*list)->copy_buffer_to_texture(rig.upload, rig.texture, regions.sent);
    issue_barrier(**list, to_copy_source(rig.texture, written));
    (*list)->copy_texture_to_buffer(rig.texture, rig.readback, regions.read);
    return submit_and_wait(device, *list);
}

// Số dòng khối của một mức đọc về khác dữ liệu đã gửi. Phần đệm cuối dòng không được giữ nên không so.
[[nodiscard]] std::uint32_t bad_rows(const CopyShape& shape, const gpu::BufferTextureCopy& region,
    std::span<const std::byte> sent, std::span<const std::byte> seen) {
    const std::uint32_t width = gpu::mip_size(shape.width, region.mip);
    const std::uint32_t height = gpu::mip_size(shape.height, region.mip);
    const std::size_t tight = gpu::row_bytes(shape.format, width);
    const std::size_t pitch = gpu::padded_row_bytes(shape.format, width);
    std::uint32_t bad = 0;
    for (std::uint32_t row = 0; row < gpu::row_count(shape.format, height); ++row) {
        const std::size_t start = region.buffer_offset + (row * pitch);
        bad += std::ranges::equal(sent.subspan(start, tight), seen.subspan(start, tight)) ? 0U : 1U;
    }
    return bad;
}

[[nodiscard]] std::vector<std::byte> make_bytes(std::uint64_t count) {
    std::vector<std::byte> bytes(count);
    for (std::size_t i = 0; i < bytes.size(); ++i) bytes[i] = static_cast<std::byte>(((i * 7) + 3) & 0xFFU);
    return bytes;
}

// Texture chép lên rồi chép về từng byte qua buffer cắt đúng ở dòng cuối không đệm. D3D11 từng đòi
// buffer Upload chứa cả phần đệm của dòng cuối ("shadow thiếu byte") và lặng lẽ bỏ dữ liệu đọc về;
// mip BC nhỏ hơn một khối từng đi xuống UpdateSubresource với hộp không căn theo khối.
void texture_round_trip(Context& context, gpu::Backend backend, const CopyShape& shape) {
    const DeviceResult made = validated_device(backend);
    context.expect(made.has_value(), "tạo được thiết bị có lớp kiểm tra");
    if (!made) return;
    gpu::Device& device = **made;
    const MipPlan plan = plan_mips(shape);
    const core::Result<CopyRig> rig = make_copy_rig(device, shape, plan.bytes);
    context.expect(rig.has_value(), "tạo được texture và hai buffer trung chuyển");
    if (!rig) return;
    const std::vector<std::byte> sent = make_bytes(plan.bytes);
    context.expect(device.write_buffer(rig->upload, 0, sent).has_value(), "ghi buffer Upload");
    const core::Status bounced = bounce(device, *rig, {.sent = plan.regions, .read = plan.regions});
    context.expect(bounced.has_value(), bounced ? "chép lên rồi chép về" : bounced.error().message());
    std::vector<std::byte> seen(plan.bytes);
    context.expect(device.read_buffer(rig->readback, 0, seen).has_value(), "đọc buffer Readback");
    for (const gpu::BufferTextureCopy& region : plan.regions) {
        const std::uint32_t bad = bad_rows(shape, region, sent, seen);
        context.expect(bad == 0, std::format("mức {}: {} dòng đọc về khác dữ liệu đã gửi", region.mip, bad));
    }
    device.destroy(rig->texture);
    device.destroy(rig->upload);
    device.destroy(rig->readback);
    context.expect(device.loss() == gpu::DeviceLoss::kNone, "thiết bị còn sống");
    context.expect(device.validation_errors() == 0, "lớp kiểm tra không báo lỗi");
}

// Rộng 5 điểm ảnh: dòng 20 byte, bước dòng 256, buffer 532 byte thay vì 768.
constexpr CopyShape kTightRows{.name = "gpu_tests.tight", .format = gpu::Format::kRgba8Unorm, .width = 5, .height = 3};
// Mức 2x2 và 1x1 nhỏ hơn một khối 4x4.
constexpr CopyShape kBlockMips{.name = "gpu_tests.bc1", .format = gpu::Format::kBc1Unorm, .width = 8, .height = 8, .mips = 4};
constexpr CopyShape kWholeImage{.name = "gpu_tests.part", .format = gpu::Format::kRgba8Unorm, .width = 8, .height = 4};

// Đọc về vùng 4x2 ở góc (4, 2) của ảnh 8x4. D3D12 từng chép trọn mức mip từ góc (0, 0) vì không
// truyền hộp nguồn, nên vùng đọc về sai chỗ và lớp kiểm tra báo footprint đích tràn biên.
void part_round_trip(Context& context, gpu::Backend backend) {
    const DeviceResult made = validated_device(backend);
    context.expect(made.has_value(), "tạo được thiết bị có lớp kiểm tra");
    if (!made) return;
    gpu::Device& device = **made;
    const MipPlan plan = plan_mips(kWholeImage);
    gpu::BufferTextureCopy part{.x = 4, .y = 2, .width = 4, .height = 2};
    const std::uint64_t part_bytes = gpu::staged_bytes(kWholeImage.format, part.width, part.height);
    const core::Result<CopyRig> rig = make_copy_rig(device, kWholeImage, plan.bytes, part_bytes);
    context.expect(rig.has_value(), "tạo được texture và hai buffer trung chuyển");
    if (!rig) return;
    const std::vector<std::byte> sent = make_bytes(plan.bytes);
    context.expect(device.write_buffer(rig->upload, 0, sent).has_value(), "ghi buffer Upload");
    const core::Status bounced = bounce(device, *rig, {.sent = plan.regions, .read = std::span(&part, 1)});
    context.expect(bounced.has_value(), bounced ? "chép lên rồi chép một vùng về" : bounced.error().message());
    std::vector<std::byte> seen(part_bytes);
    context.expect(device.read_buffer(rig->readback, 0, seen).has_value(), "đọc buffer Readback");
    const std::size_t pitch = gpu::padded_row_bytes(kWholeImage.format, kWholeImage.width);
    const std::size_t part_pitch = gpu::padded_row_bytes(kWholeImage.format, part.width);
    const std::size_t tight = gpu::row_bytes(kWholeImage.format, part.width);
    const std::size_t left = gpu::row_bytes(kWholeImage.format, part.x);
    for (std::uint32_t row = 0; row < part.height; ++row) {
        const std::span<const std::byte> wanted = std::span(sent).subspan(((part.y + row) * pitch) + left, tight);
        const std::span<const std::byte> got = std::span(seen).subspan(row * part_pitch, tight);
        context.expect(std::ranges::equal(wanted, got), std::format("dòng {} của vùng đọc về đúng chỗ", row));
    }
    device.destroy(rig->texture);
    device.destroy(rig->upload);
    device.destroy(rig->readback);
    context.expect(device.loss() == gpu::DeviceLoss::kNone, "thiết bị còn sống");
    context.expect(device.validation_errors() == 0, "lớp kiểm tra không báo lỗi");
}

// Màu xoá của ca resolve, khai cả lúc tạo đích đa mẫu: D3D12 nhắc mỗi lần xoá bằng màu khác.
constexpr gpu::ClearColor kResolveClear{.red = 0.5F, .green = 0.25F, .blue = 0.0F, .alpha = 1.0F};

struct ResolveRig {
    gpu::TextureHandle samples{};
    gpu::TextureViewHandle samples_view{};
    gpu::TextureHandle target{};
    gpu::TextureViewHandle target_view{};
    gpu::BufferHandle readback{};
};

[[nodiscard]] core::Result<gpu::TextureViewHandle> view_of(gpu::Device& device, gpu::TextureHandle texture) {
    gpu::TextureViewDesc desc;
    desc.name = "gpu_tests.resolve";
    desc.texture = texture;
    return device.create_view(desc);
}

[[nodiscard]] core::Result<ResolveRig> make_resolve_rig(gpu::Device& device) {
    gpu::TextureDesc desc;
    desc.name = "gpu_tests.resolve";
    desc.format = gpu::Format::kRgba8Unorm;
    desc.width = kTargetSide;
    desc.height = kTargetSide;
    desc.samples = 4;
    desc.usage = gpu::TextureUsage::kColorTarget | gpu::TextureUsage::kTransient;
    desc.clear_color = kResolveClear;
    const core::Result<gpu::TextureHandle> samples = device.create_texture(desc);
    if (!samples) return std::unexpected(samples.error());
    desc.samples = 1;
    desc.usage = gpu::TextureUsage::kColorTarget | gpu::TextureUsage::kCopySource;
    const core::Result<gpu::TextureHandle> target = device.create_texture(desc);
    if (!target) return std::unexpected(target.error());
    const core::Result<gpu::TextureViewHandle> samples_view = view_of(device, *samples);
    if (!samples_view) return std::unexpected(samples_view.error());
    const core::Result<gpu::TextureViewHandle> target_view = view_of(device, *target);
    if (!target_view) return std::unexpected(target_view.error());
    const std::uint64_t bytes = gpu::staged_bytes(desc.format, kTargetSide, kTargetSide);
    const BufferKind readback_kind{.memory = gpu::MemoryDomain::kReadback, .usage = gpu::BufferUsage::kCopyDest};
    const core::Result<gpu::BufferHandle> readback = make_staging(device, bytes, readback_kind);
    if (!readback) return std::unexpected(readback.error());
    return ResolveRig{.samples = *samples,
        .samples_view = *samples_view,
        .target = *target,
        .target_view = *target_view,
        .readback = *readback};
}

// Undefined sang ColorTarget, như Screen::begin làm mỗi khung.
[[nodiscard]] gpu::TextureBarrier to_color(gpu::TextureHandle texture) noexcept {
    gpu::TextureBarrier barrier;
    barrier.texture = texture;
    barrier.stage_before = gpu::SyncStage::kColorOutput;
    barrier.stage_after = gpu::SyncStage::kColorOutput;
    barrier.access_after = gpu::Access::kColorWrite;
    barrier.layout_after = gpu::TextureLayout::kColorTarget;
    return barrier;
}

[[nodiscard]] core::Status resolve_and_copy(gpu::Device& device, const ResolveRig& rig) {
    const core::Result<gpu::CommandList*> list = device.begin_commands(gpu::QueueType::kGraphics);
    if (!list) return std::unexpected(list.error());
    const gpu::TextureBarrier drawn = to_color(rig.target);
    const std::array<gpu::TextureBarrier, 2> entry{to_color(rig.samples), drawn};
    (*list)->barrier({}, entry, {});
    gpu::ColorTarget color;
    color.view = rig.samples_view;
    color.store = gpu::StoreOp::kDiscard;
    color.clear = kResolveClear;
    color.resolve = rig.target_view;
    gpu::RenderingDesc pass;
    pass.colors = std::span(&color, 1);
    (*list)->begin_rendering(pass);
    (*list)->end_rendering();
    issue_barrier(**list, to_copy_source(rig.target, drawn));
    const gpu::BufferTextureCopy region{};
    (*list)->copy_texture_to_buffer(rig.target, rig.readback, std::span(&region, 1));
    return submit_and_wait(device, *list);
}

// Đích resolve vừa tạo, chưa từng được xoá hay chép vào, nhận kết quả resolve của một lần vẽ đa mẫu.
// D3D12 đặt đích vẽ trên heap không xoá sẵn: rào đầu tiên từ Undefined phải mang cờ DISCARD, thiếu
// thì lớp kiểm tra báo tài nguyên chưa khởi tạo (render.canvas.color từng như vậy mỗi khung).
void resolve_into_fresh_target(Context& context, gpu::Backend backend) {
    const DeviceResult made = validated_device(backend);
    context.expect(made.has_value(), "tạo được thiết bị có lớp kiểm tra");
    if (!made) return;
    gpu::Device& device = **made;
    const core::Result<ResolveRig> rig = make_resolve_rig(device);
    context.expect(rig.has_value(), "tạo được đích đa mẫu, đích resolve và buffer đọc về");
    if (!rig) return;
    const core::Status resolved = resolve_and_copy(device, *rig);
    context.expect(resolved.has_value(), resolved ? "xoá, resolve, chép về" : resolved.error().message());
    std::array<std::byte, 4> pixel{};
    context.expect(device.read_buffer(rig->readback, 0, pixel).has_value(), "đọc điểm ảnh đầu");
    const int red = std::to_integer<int>(pixel[0]);
    const int green = std::to_integer<int>(pixel[1]);
    const int blue = std::to_integer<int>(pixel[2]);
    const int alpha = std::to_integer<int>(pixel[3]);
    const std::string seen = std::format("điểm ảnh resolve {} {} {} {}", red, green, blue, alpha);
    const bool is_cleared = is_near(red, 128) && is_near(green, 64) && is_near(blue, 0) && is_near(alpha, 255);
    context.expect(is_cleared, seen);
    device.destroy(rig->samples_view);
    device.destroy(rig->target_view);
    device.destroy(rig->samples);
    device.destroy(rig->target);
    device.destroy(rig->readback);
    context.expect(device.loss() == gpu::DeviceLoss::kNone, "thiết bị còn sống");
    context.expect(device.validation_errors() == 0, "lớp kiểm tra không báo lỗi");
}

void vulkan_tight_rows_round_trip(Context& context) {
    texture_round_trip(context, gpu::Backend::kVulkan, kTightRows);
}

void d3d12_tight_rows_round_trip(Context& context) {
    texture_round_trip(context, gpu::Backend::kD3D12, kTightRows);
}

void d3d11_tight_rows_round_trip(Context& context) {
    texture_round_trip(context, gpu::Backend::kD3D11, kTightRows);
}

void vulkan_block_mips_round_trip(Context& context) {
    texture_round_trip(context, gpu::Backend::kVulkan, kBlockMips);
}

void d3d12_block_mips_round_trip(Context& context) {
    texture_round_trip(context, gpu::Backend::kD3D12, kBlockMips);
}

void d3d11_block_mips_round_trip(Context& context) {
    texture_round_trip(context, gpu::Backend::kD3D11, kBlockMips);
}

void vulkan_part_round_trip(Context& context) {
    part_round_trip(context, gpu::Backend::kVulkan);
}

void d3d12_part_round_trip(Context& context) {
    part_round_trip(context, gpu::Backend::kD3D12);
}

void d3d11_part_round_trip(Context& context) {
    part_round_trip(context, gpu::Backend::kD3D11);
}

void vulkan_resolve_into_fresh_target(Context& context) {
    resolve_into_fresh_target(context, gpu::Backend::kVulkan);
}

void d3d12_resolve_into_fresh_target(Context& context) {
    resolve_into_fresh_target(context, gpu::Backend::kD3D12);
}

void d3d11_resolve_into_fresh_target(Context& context) {
    resolve_into_fresh_target(context, gpu::Backend::kD3D11);
}

// Stride của khe đỉnh thuộc pipeline đang gắn lúc vẽ, như Vulkan: gắn buffer rồi đổi pipeline vẫn
// đọc đỉnh theo stride của pipeline mới, và gắn buffer trước mọi pipeline là hợp lệ. Lỗi cũ
// (2026-10-17): D3D12 và D3D11 chốt stride lúc bind_vertex_buffer (D3D12 còn từ chối khi chưa có
// pipeline). FxView gắn buffer hạt trước pipeline hạt, nên đỉnh 44 byte bị đọc theo stride của
// pipeline vẽ trước và hiện thành cột nhiễu trước mặt nhân vật ở Đại Lý.
constexpr std::string_view kStrideVertex =
    "float4 main(float2 position : POSITION) : SV_Position { return float4(position, 0.5, 1.0); }\n";
constexpr std::string_view kStridePixel = "float4 main() : SV_Target0 { return float4(1.0, 0.0, 0.0, 1.0); }\n";
constexpr gpu::Format kStrideFormat = gpu::Format::kRgba8Unorm;
constexpr std::uint32_t kNarrowStride = 8;
constexpr std::uint32_t kWideStride = 16;
constexpr std::uint32_t kQuadCorners = 6;
// Hai tam giác phủ kín khung theo bố cục rộng: (x, y) rồi hai số đệm ở xa ngoài khung. Đọc theo
// stride hẹp thì mọi đỉnh lẻ là cặp số đệm, nên chỉ còn khoảng nửa khung được vẽ.
constexpr std::array<float, std::size_t{4} * kQuadCorners> kWideQuad{-1.0F, -1.0F, 9.0F, 9.0F, 1.0F, -1.0F, 9.0F,
    9.0F, -1.0F, 1.0F, 9.0F, 9.0F, -1.0F, 1.0F, 9.0F, 9.0F, 1.0F, -1.0F, 9.0F, 9.0F, 1.0F, 1.0F, 9.0F, 9.0F};

struct StrideRig {
    std::array<gpu::ShaderHandle, 2> shaders{};
    gpu::PipelineHandle narrow{};
    gpu::PipelineHandle wide{};
    gpu::BufferHandle vertices{};
    gpu::TextureHandle target{};
    gpu::TextureViewHandle view{};
    gpu::BufferHandle readback{};
};

[[nodiscard]] core::Result<gpu::ShaderHandle> make_test_shader(gpu::Device& device, const shader::Compiler& compiler,
    shader::Stage stage, std::string_view text) {
    shader::CompileOptions options;
    options.stage = stage;
    options.target = gpu::shader_target(device.adapter().backend);
    const shader::MemorySource source{.path = "gpu_tests.stride.slang", .text = text};
    const core::Result<shader::Compiled> compiled = compiler.compile(source, options);
    if (!compiled) return std::unexpected(compiled.error());
    shader::Variant variant;
    variant.target = options.target;
    variant.code = compiled->code;
    variant.reflection = compiled->reflection;
    gpu::ShaderDesc desc;
    desc.name = "gpu_tests.stride";
    desc.variant = &variant;
    return device.create_shader(desc);
}

[[nodiscard]] core::Result<gpu::PipelineHandle> make_stride_pipeline(gpu::Device& device, const StrideRig& rig,
    std::uint32_t stride) {
    const gpu::VertexBufferLayout layout{.stride = stride};
    const gpu::VertexAttribute position{.location = 0, .buffer = 0, .format = gpu::Format::kRg32Float, .offset = 0};
    const gpu::Format color = kStrideFormat;
    const gpu::BlendState blend{};
    gpu::GraphicsPipelineDesc desc;
    desc.name = "gpu_tests.stride";
    desc.shaders = rig.shaders;
    desc.vertex_buffers = std::span(&layout, 1);
    desc.vertex_attributes = std::span(&position, 1);
    desc.raster.cull = gpu::CullMode::kNone;
    desc.color_formats = std::span(&color, 1);
    desc.blends = std::span(&blend, 1);
    return device.create_pipeline(desc);
}

[[nodiscard]] core::Status make_stride_shaders(gpu::Device& device, StrideRig& rig) {
    const core::Result<shader::Compiler> compiler = shader::Compiler::create();
    if (!compiler) return std::unexpected(compiler.error());
    const core::Result<gpu::ShaderHandle> vertex =
        make_test_shader(device, *compiler, shader::Stage::kVertex, kStrideVertex);
    if (!vertex) return std::unexpected(vertex.error());
    const core::Result<gpu::ShaderHandle> pixel = make_test_shader(device, *compiler, shader::Stage::kPixel, kStridePixel);
    if (!pixel) return std::unexpected(pixel.error());
    rig.shaders = {*vertex, *pixel};
    return core::ok();
}

[[nodiscard]] core::Status make_stride_target(gpu::Device& device, StrideRig& rig) {
    gpu::TextureDesc desc;
    desc.name = "gpu_tests.stride";
    desc.format = kStrideFormat;
    desc.width = kTargetSide;
    desc.height = kTargetSide;
    desc.usage = gpu::TextureUsage::kColorTarget | gpu::TextureUsage::kCopySource;
    const core::Result<gpu::TextureHandle> target = device.create_texture(desc);
    if (!target) return std::unexpected(target.error());
    rig.target = *target;
    const core::Result<gpu::TextureViewHandle> view = view_of(device, *target);
    if (!view) return std::unexpected(view.error());
    rig.view = *view;
    const std::uint64_t bytes = gpu::staged_bytes(kStrideFormat, kTargetSide, kTargetSide);
    const BufferKind readback_kind{.memory = gpu::MemoryDomain::kReadback, .usage = gpu::BufferUsage::kCopyDest};
    const core::Result<gpu::BufferHandle> readback = make_staging(device, bytes, readback_kind);
    if (!readback) return std::unexpected(readback.error());
    rig.readback = *readback;
    return core::ok();
}

[[nodiscard]] core::Result<StrideRig> make_stride_rig(gpu::Device& device) {
    StrideRig rig;
    const core::Status shaders = make_stride_shaders(device, rig);
    if (!shaders) return std::unexpected(shaders.error());
    const core::Result<gpu::PipelineHandle> narrow = make_stride_pipeline(device, rig, kNarrowStride);
    if (!narrow) return std::unexpected(narrow.error());
    rig.narrow = *narrow;
    const core::Result<gpu::PipelineHandle> wide = make_stride_pipeline(device, rig, kWideStride);
    if (!wide) return std::unexpected(wide.error());
    rig.wide = *wide;
    const BufferKind vertex_kind{.memory = gpu::MemoryDomain::kUpload, .usage = gpu::BufferUsage::kVertex};
    const core::Result<gpu::BufferHandle> vertices = make_staging(device, sizeof(kWideQuad), vertex_kind);
    if (!vertices) return std::unexpected(vertices.error());
    rig.vertices = *vertices;
    const core::Status written = device.write_buffer(rig.vertices, 0, std::as_bytes(std::span(kWideQuad)));
    if (!written) return std::unexpected(written.error());
    const core::Status target = make_stride_target(device, rig);
    if (!target) return std::unexpected(target.error());
    return rig;
}

// Gắn buffer theo một trong hai thứ tự rồi đổi sang pipeline rộng và vẽ: trước mọi pipeline, hoặc
// sau pipeline hẹp (đúng thứ tự FxView sau lượt vẽ cảnh).
void record_quad(gpu::CommandList& list, const StrideRig& rig, bool binds_first) {
    constexpr auto kSide = static_cast<float>(kTargetSide);
    list.set_viewport(gpu::Viewport{.width = kSide, .height = kSide});
    list.set_scissor(gpu::Scissor{.width = kTargetSide, .height = kTargetSide});
    if (binds_first) list.bind_vertex_buffer(0, rig.vertices, 0);
    list.bind_pipeline(rig.narrow);
    if (!binds_first) list.bind_vertex_buffer(0, rig.vertices, 0);
    list.bind_pipeline(rig.wide);
    gpu::DrawArguments arguments;
    arguments.vertex_count = kQuadCorners;
    list.draw(arguments);
}

[[nodiscard]] core::Status draw_quad(gpu::Device& device, const StrideRig& rig, bool binds_first) {
    const core::Result<gpu::CommandList*> list = device.begin_commands(gpu::QueueType::kGraphics);
    if (!list) return std::unexpected(list.error());
    const gpu::TextureBarrier drawn = to_color(rig.target);
    issue_barrier(**list, drawn);
    gpu::ColorTarget color;
    color.view = rig.view;
    color.clear = {.red = 0.0F, .green = 0.0F, .blue = 0.0F, .alpha = 1.0F};
    gpu::RenderingDesc pass;
    pass.colors = std::span(&color, 1);
    (*list)->begin_rendering(pass);
    record_quad(**list, rig, binds_first);
    (*list)->end_rendering();
    issue_barrier(**list, to_copy_source(rig.target, drawn));
    const gpu::BufferTextureCopy region{};
    (*list)->copy_texture_to_buffer(rig.target, rig.readback, std::span(&region, 1));
    return submit_and_wait(device, *list);
}

[[nodiscard]] std::uint32_t red_in_row(std::span<const std::byte> row) noexcept {
    std::uint32_t count = 0;
    for (std::size_t at = 0; at + 4 <= row.size(); at += 4) {
        const bool is_red = row[at] == std::byte{255} && row[at + 1] == std::byte{0} && row[at + 2] == std::byte{0};
        count += is_red ? 1U : 0U;
    }
    return count;
}

[[nodiscard]] std::uint32_t red_pixels(gpu::Device& device, const StrideRig& rig) {
    const std::uint64_t pitch = gpu::padded_row_bytes(kStrideFormat, kTargetSide);
    std::vector<std::byte> bytes(gpu::staged_bytes(kStrideFormat, kTargetSide, kTargetSide));
    if (!device.read_buffer(rig.readback, 0, bytes)) return 0;
    std::uint32_t count = 0;
    for (std::uint32_t row = 0; row < kTargetSide; ++row)
        count += red_in_row(std::span(bytes).subspan(row * pitch, std::size_t{kTargetSide} * 4));
    return count;
}

void destroy_stride_rig(gpu::Device& device, const StrideRig& rig) {
    device.destroy(rig.narrow);
    device.destroy(rig.wide);
    for (const gpu::ShaderHandle shader : rig.shaders) device.destroy(shader);
    device.destroy(rig.vertices);
    device.destroy(rig.view);
    device.destroy(rig.target);
    device.destroy(rig.readback);
}

void vertex_stride_follows_pipeline(Context& context, gpu::Backend backend) {
    const DeviceResult made = validated_device(backend);
    context.expect(made.has_value(), "tạo được thiết bị có lớp kiểm tra");
    if (!made) return;
    gpu::Device& device = **made;
    const core::Result<StrideRig> rig = make_stride_rig(device);
    context.expect(rig.has_value(), rig ? "dựng shader, hai pipeline, buffer đỉnh và đích" : rig.error().message());
    if (!rig) return;
    for (const bool binds_first : {false, true}) {
        const core::Status drawn = draw_quad(device, *rig, binds_first);
        context.expect(drawn.has_value(), drawn ? "vẽ, chép về" : drawn.error().message());
        const std::uint32_t red = red_pixels(device, *rig);
        const std::uint32_t whole = kTargetSide * kTargetSide;
        const std::string seen = std::format("gắn buffer trước mọi pipeline: {}; {}/{} điểm đỏ", binds_first, red, whole);
        context.expect(red == whole, seen);
    }
    destroy_stride_rig(device, *rig);
    context.expect(device.loss() == gpu::DeviceLoss::kNone, "thiết bị còn sống");
    context.expect(device.validation_errors() == 0, "lớp kiểm tra không báo lỗi");
}

void vulkan_vertex_stride_follows_pipeline(Context& context) {
    vertex_stride_follows_pipeline(context, gpu::Backend::kVulkan);
}

void d3d12_vertex_stride_follows_pipeline(Context& context) {
    vertex_stride_follows_pipeline(context, gpu::Backend::kD3D12);
}

void d3d11_vertex_stride_follows_pipeline(Context& context) {
    vertex_stride_follows_pipeline(context, gpu::Backend::kD3D11);
}

struct CacheAsk {
    int calls = 0;
    std::string adapter;
};

// DeviceDesc::load_pipeline_cache ghi lại lần hỏi; trả rỗng như máy chưa có cache.
struct CacheProbe {
    CacheAsk* asked = nullptr;

    [[nodiscard]] std::vector<std::byte> operator()(const gpu::AdapterInfo& info) const {
        ++asked->calls;
        asked->adapter = info.name;
        return {};
    }
};

// Backend hỏi cache đúng một lần, cho đúng adapter vừa chọn. Sai thì cache của lần chạy trước không
// bao giờ được nạp mà không gì báo: chỉ thấy qua thời gian tạo pipeline.
void cache_asked_once(Context& context, gpu::Backend backend) {
    CacheAsk asked;
    gpu::DeviceDesc desc;
    desc.backend = backend;
    desc.is_validated = true;
    desc.load_pipeline_cache = CacheProbe{.asked = &asked};
    const DeviceResult made = gpu::create_device(desc);
    context.expect(made.has_value(), "tạo được thiết bị có lớp kiểm tra");
    if (!made) return;
    const std::string& chosen = (*made)->adapter().name;
    context.expect(asked.calls == 1, std::format("hỏi cache {} lần, cần đúng 1", asked.calls));
    context.expect(asked.adapter == chosen, std::format("hỏi cho {}, đã chọn {}", asked.adapter, chosen));
}

void vulkan_cache_asked_once(Context& context) {
    cache_asked_once(context, gpu::Backend::kVulkan);
}

void d3d12_cache_asked_once(Context& context) {
    cache_asked_once(context, gpu::Backend::kD3D12);
}

#if defined(_WIN32)
// ColorTarget sang Present, như Screen::end khi khung không bị chụp: không truy cập nào sau rào.
[[nodiscard]] gpu::TextureBarrier to_present(gpu::TextureHandle texture) noexcept {
    gpu::TextureBarrier barrier;
    barrier.texture = texture;
    barrier.stage_before = gpu::SyncStage::kColorOutput;
    barrier.access_before = gpu::Access::kColorWrite;
    barrier.layout_before = gpu::TextureLayout::kColorTarget;
    barrier.stage_after = gpu::SyncStage::kColorOutput;
    barrier.layout_after = gpu::TextureLayout::kPresent;
    return barrier;
}

// Một khung đủ vòng: acquire, xoá ảnh, rào sang Present, nộp kèm present_target, present.
[[nodiscard]] core::Status present_frame(gpu::Device& device, gpu::Swapchain& chain) {
    const core::Result<std::uint32_t> index = chain.acquire();
    if (!index) return std::unexpected(index.error());
    const core::Result<gpu::CommandList*> list = device.begin_commands(gpu::QueueType::kGraphics);
    if (!list) return std::unexpected(list.error());
    const gpu::TextureHandle image = chain.image(*index);
    issue_barrier(**list, to_color(image));
    gpu::ColorTarget color;
    color.view = chain.view(*index);
    color.clear = {.red = 0.0F, .green = 0.5F, .blue = 1.0F, .alpha = 1.0F};
    gpu::RenderingDesc pass;
    pass.colors = std::span(&color, 1);
    (*list)->begin_rendering(pass);
    (*list)->end_rendering();
    issue_barrier(**list, to_present(image));
    gpu::CommandList* const recorded = *list;
    gpu::SubmitDesc submit;
    submit.lists = std::span(&recorded, 1);
    submit.present_target = &chain;
    const core::Status submitted = device.submit(gpu::QueueType::kGraphics, submit);
    if (!submitted) return submitted;
    const core::Status presented = chain.present();
    if (!presented) return presented;
    return device.end_frame();
}

void present_frames(Context& context, gpu::Device& device, void* hwnd) {
    gpu::SwapchainDesc desc;
    desc.window = hwnd;
    desc.width = 64;
    desc.height = 64;
    const core::Result<std::unique_ptr<gpu::Swapchain>> chain = device.create_swapchain(desc);
    context.expect(chain.has_value(), "tạo được swapchain");
    if (!chain) return;
    for (std::uint32_t frame = 0; frame < 4; ++frame) {
        const core::Status shown = present_frame(device, **chain);
        context.expect(shown.has_value(), shown ? "khung đủ vòng" : shown.error().message());
    }
    context.expect(device.wait_idle().has_value(), "chờ GPU rỗi");
    context.expect(device.loss() == gpu::DeviceLoss::kNone, "thiết bị còn sống");
    context.expect(device.validation_errors() == 0, "lớp kiểm tra không báo lỗi");
}

// Bốn khung liền trên cửa sổ ẩn. D3D12 từng xoá cờ "đã acquire" khi nộp kèm present_target nên
// present báo chưa acquire, và rào sang Present từng giữ SyncAfter khác NONE khi AccessAfter là
// NO_ACCESS, điều lớp kiểm tra Enhanced Barriers cấm.
void swapchain_presents_frames(Context& context, gpu::Backend backend) {
    HiddenWindow window = open_hidden();
    context.expect(window.hwnd != nullptr, "tạo được cửa sổ ẩn");
    const DeviceResult made = validated_device(backend);
    context.expect(made.has_value(), "tạo được thiết bị");
    if (made && window.hwnd != nullptr) present_frames(context, **made, window.hwnd);
    close_hidden(window);
}

// Huỷ ngay sau khi tạo, lúc lần dựng đầu của Vulkan còn chạy ở luồng phụ (~150 ms trên NVIDIA):
// hàm huỷ phải chờ nó và huỷ swapchain nó tạo trước khi huỷ bề mặt, nếu không lớp kiểm tra báo
// bề mặt bị huỷ khi swapchain còn sống. Cỡ và định dạng phải có ngay, trước khi có ảnh.
void drop_fresh(Context& context, gpu::Device& device, void* hwnd) {
    gpu::SwapchainDesc desc;
    desc.window = hwnd;
    desc.width = 64;
    desc.height = 64;
    core::Result<std::unique_ptr<gpu::Swapchain>> chain = device.create_swapchain(desc);
    context.expect(chain.has_value(), "tạo được swapchain");
    if (!chain) return;
    const bool has_size = (*chain)->width() == 64 && (*chain)->height() == 64;
    context.expect(has_size, "cỡ có ngay khi chưa có ảnh");
    context.expect((*chain)->format() != gpu::Format::kUnknown, "định dạng có ngay");
    chain->reset();
    context.expect(device.wait_idle().has_value(), "chờ GPU rỗi");
    context.expect(device.loss() == gpu::DeviceLoss::kNone, "thiết bị còn sống");
    context.expect(device.validation_errors() == 0, "lớp kiểm tra không báo lỗi");
}

void vulkan_swapchain_dropped_while_building(Context& context) {
    HiddenWindow window = open_hidden();
    context.expect(window.hwnd != nullptr, "tạo được cửa sổ ẩn");
    const DeviceResult made = validated_device(gpu::Backend::kVulkan);
    context.expect(made.has_value(), "tạo được thiết bị");
    if (made && window.hwnd != nullptr) drop_fresh(context, **made, window.hwnd);
    close_hidden(window);
}
#endif

void vulkan_storage_upload_keeps_device(Context& context) {
    storage_upload_keeps_device(context, gpu::Backend::kVulkan);
}

void d3d12_storage_upload_keeps_device(Context& context) {
    storage_upload_keeps_device(context, gpu::Backend::kD3D12);
}

void d3d11_storage_upload_keeps_device(Context& context) {
    storage_upload_keeps_device(context, gpu::Backend::kD3D11);
}

void vulkan_every_filter_keeps_device(Context& context) {
    every_filter_keeps_device(context, gpu::Backend::kVulkan);
}

void d3d12_every_filter_keeps_device(Context& context) {
    every_filter_keeps_device(context, gpu::Backend::kD3D12);
}

void d3d11_every_filter_keeps_device(Context& context) {
    every_filter_keeps_device(context, gpu::Backend::kD3D11);
}

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

// Pass GLES không có attachment nào (không màu, không độ sâu) phải bị từ chối có lỗi ở submit,
// không được lặng lẽ bỏ qua cả pass vẽ. Pass có view màu đã chết cũng vậy.
void gles_rejects_pass_without_attachment(Context& context) {
    const DeviceResult made = validated_device(gpu::Backend::kGles);
    context.expect(made.has_value(), "tạo được thiết bị GLES");
    if (!made) return;
    gpu::Device& device = **made;
    const core::Result<gpu::CommandList*> empty = device.begin_commands(gpu::QueueType::kGraphics);
    context.expect(empty.has_value(), "mở được list cho pass rỗng");
    if (!empty) return;
    const gpu::RenderingDesc bare{};
    (*empty)->begin_rendering(bare);
    (*empty)->end_rendering();
    gpu::SubmitDesc submit;
    submit.lists = std::span(&*empty, 1);
    const core::Status refused = device.submit(gpu::QueueType::kGraphics, submit);
    context.expect(!refused.has_value(), "submit từ chối pass không có attachment");
    const core::Result<gpu::CommandList*> dead = device.begin_commands(gpu::QueueType::kGraphics);
    context.expect(dead.has_value(), "mở được list cho pass có view chết");
    if (!dead) return;
    gpu::ColorTarget color;
    color.view = gpu::TextureViewHandle{};
    gpu::RenderingDesc pass;
    pass.colors = std::span(&color, 1);
    (*dead)->begin_rendering(pass);
    (*dead)->end_rendering();
    submit.lists = std::span(&*dead, 1);
    const core::Status dropped = device.submit(gpu::QueueType::kGraphics, submit);
    context.expect(!dropped.has_value(), "submit từ chối pass có view màu đã chết");
}

#if defined(_WIN32)
void d3d12_swapchain_accepts_srgb(Context& context) {
    swapchain_accepts_srgb(context, gpu::Backend::kD3D12);
}

void d3d11_swapchain_accepts_srgb(Context& context) {
    swapchain_accepts_srgb(context, gpu::Backend::kD3D11);
}

void vulkan_swapchain_presents_frames(Context& context) {
    swapchain_presents_frames(context, gpu::Backend::kVulkan);
}

void d3d12_swapchain_presents_frames(Context& context) {
    swapchain_presents_frames(context, gpu::Backend::kD3D12);
}

void d3d11_swapchain_presents_frames(Context& context) {
    swapchain_presents_frames(context, gpu::Backend::kD3D11);
}

constexpr std::array kBlendFactors{gpu::BlendFactor::kZero, gpu::BlendFactor::kOne, gpu::BlendFactor::kSrcColor,
    gpu::BlendFactor::kOneMinusSrcColor, gpu::BlendFactor::kDstColor, gpu::BlendFactor::kOneMinusDstColor,
    gpu::BlendFactor::kSrcAlpha, gpu::BlendFactor::kOneMinusSrcAlpha, gpu::BlendFactor::kDstAlpha,
    gpu::BlendFactor::kOneMinusDstAlpha, gpu::BlendFactor::kSrcAlphaSaturate, gpu::BlendFactor::kConstant,
    gpu::BlendFactor::kOneMinusConstant};

[[nodiscard]] bool is_color_factor(D3D12_BLEND blend) noexcept {
    return blend == D3D12_BLEND_SRC_COLOR || blend == D3D12_BLEND_INV_SRC_COLOR || blend == D3D12_BLEND_DEST_COLOR ||
        blend == D3D12_BLEND_INV_DEST_COLOR;
}

[[nodiscard]] bool is_color_factor(D3D11_BLEND blend) noexcept {
    return blend == D3D11_BLEND_SRC_COLOR || blend == D3D11_BLEND_INV_SRC_COLOR || blend == D3D11_BLEND_DEST_COLOR ||
        blend == D3D11_BLEND_INV_DEST_COLOR;
}

// Hệ số trộn alpha của D3D không nhận hệ số *_COLOR: CreateBlendState trả E_INVALIDARG, và pipeline
// hạt của client D3D12 từng hỏng như vậy. Vulkan đọc thành phần alpha của các hệ số ấy, nên D3D đổi
// sang hệ số *_ALPHA cùng nghĩa.
void d3d_alpha_blend_has_no_color_factor(Context& context) {
    for (const gpu::BlendFactor factor : kBlendFactors) {
        const bool is_color = is_color_factor(gpu::d3d12::to_alpha_blend(factor)) ||
            is_color_factor(gpu::d3d11::to_alpha_blend(factor));
        context.expect(!is_color, std::format("hệ số {} không ra *_COLOR", std::to_underlying(factor)));
    }
    const D3D12_BLEND source = gpu::d3d12::to_alpha_blend(gpu::BlendFactor::kSrcColor);
    const D3D11_BLEND target = gpu::d3d11::to_alpha_blend(gpu::BlendFactor::kOneMinusDstColor);
    context.expect(source == D3D12_BLEND_SRC_ALPHA, "SrcColor của alpha là SRC_ALPHA");
    context.expect(target == D3D11_BLEND_INV_DEST_ALPHA, "OneMinusDstColor của alpha là INV_DEST_ALPHA");
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
    Case{.name = "vulkan_storage_upload_keeps_device", .body = &vulkan_storage_upload_keeps_device},
    Case{.name = "d3d12_storage_upload_keeps_device", .body = &d3d12_storage_upload_keeps_device},
    Case{.name = "d3d11_storage_upload_keeps_device", .body = &d3d11_storage_upload_keeps_device},
    Case{.name = "vulkan_every_filter_keeps_device", .body = &vulkan_every_filter_keeps_device},
    Case{.name = "d3d12_every_filter_keeps_device", .body = &d3d12_every_filter_keeps_device},
    Case{.name = "d3d11_every_filter_keeps_device", .body = &d3d11_every_filter_keeps_device},
    Case{.name = "vulkan_tight_rows_round_trip", .body = &vulkan_tight_rows_round_trip},
    Case{.name = "d3d12_tight_rows_round_trip", .body = &d3d12_tight_rows_round_trip},
    Case{.name = "d3d11_tight_rows_round_trip", .body = &d3d11_tight_rows_round_trip},
    Case{.name = "vulkan_block_mips_round_trip", .body = &vulkan_block_mips_round_trip},
    Case{.name = "d3d12_block_mips_round_trip", .body = &d3d12_block_mips_round_trip},
    Case{.name = "d3d11_block_mips_round_trip", .body = &d3d11_block_mips_round_trip},
    Case{.name = "vulkan_part_round_trip", .body = &vulkan_part_round_trip},
    Case{.name = "d3d12_part_round_trip", .body = &d3d12_part_round_trip},
    Case{.name = "d3d11_part_round_trip", .body = &d3d11_part_round_trip},
    Case{.name = "vulkan_resolve_into_fresh_target", .body = &vulkan_resolve_into_fresh_target},
    Case{.name = "d3d12_resolve_into_fresh_target", .body = &d3d12_resolve_into_fresh_target},
    Case{.name = "d3d11_resolve_into_fresh_target", .body = &d3d11_resolve_into_fresh_target},
    Case{.name = "vulkan_vertex_stride_follows_pipeline", .body = &vulkan_vertex_stride_follows_pipeline},
    Case{.name = "d3d12_vertex_stride_follows_pipeline", .body = &d3d12_vertex_stride_follows_pipeline},
    Case{.name = "d3d11_vertex_stride_follows_pipeline", .body = &d3d11_vertex_stride_follows_pipeline},
    Case{.name = "vulkan_cache_asked_once", .body = &vulkan_cache_asked_once},
    Case{.name = "d3d12_cache_asked_once", .body = &d3d12_cache_asked_once},
    Case{.name = "gles_device_starts", .body = &gles_device_starts},
    Case{.name = "gles_buffer_round_trip", .body = &gles_buffer_round_trip},
    Case{.name = "gles_rejects_duplicate_list", .body = &gles_rejects_duplicate_list},
    Case{.name = "gles_rejects_pass_without_attachment", .body = &gles_rejects_pass_without_attachment},
    Case{.name = "gles_names_are_not_ranked_by_unused_features", .body = &gles_names_are_not_ranked_by_unused_features},
    Case{.name = "gles_probe_follows_the_api_flavor", .body = &gles_probe_follows_the_api_flavor},
    Case{.name = "gles_probe_copies_driver_strings", .body = &gles_probe_copies_driver_strings},
    Case{.name = "gles_debug_sink_counts_only_errors", .body = &gles_debug_sink_counts_only_errors},
    Case{.name = "gles_clear_of_srgb_target_is_encoded", .body = &gles_clear_of_srgb_target_is_encoded},
#if defined(_WIN32)
    Case{.name = "d3d12_swapchain_accepts_srgb", .body = &d3d12_swapchain_accepts_srgb},
    Case{.name = "d3d11_swapchain_accepts_srgb", .body = &d3d11_swapchain_accepts_srgb},
    Case{.name = "vulkan_swapchain_presents_frames", .body = &vulkan_swapchain_presents_frames},
    Case{.name = "vulkan_swapchain_dropped_while_building", .body = &vulkan_swapchain_dropped_while_building},
    Case{.name = "d3d12_swapchain_presents_frames", .body = &d3d12_swapchain_presents_frames},
    Case{.name = "d3d11_swapchain_presents_frames", .body = &d3d11_swapchain_presents_frames},
    Case{.name = "d3d_alpha_blend_has_no_color_factor", .body = &d3d_alpha_blend_has_no_color_factor},
#endif
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "gpu_tests: mọi ca phải qua");
    return 0;
}
