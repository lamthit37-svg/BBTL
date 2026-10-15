/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/device.hpp
 *  PHÂN HỆ   : Gpu / Device
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Thiết bị đồ hoạ: cửa duy nhất để tạo tài nguyên, nộp lệnh và trình bày —
 *    Renderer, Queue, Fence, Semaphore, SwapChain, QueryPool của IGraphics.h
 *    trong _Ref; rhi/device.hpp của Platium; GraphicsDevice của Wicked. Khác
 *    gốc:
 *  - đồng bộ chỉ bằng Timeline (bộ đếm u64 đơn điệu: ID3D12Fence, timeline
 *    semaphore của Vulkan); semaphore nhị phân mà WSI của Vulkan đòi bị giấu
 *    sau Swapchain. _Ref lộ cả Fence lẫn Semaphore;
 *  - huỷ tài nguyên là hoãn: tay nắm mất hiệu lực ngay, tài nguyên biến mất khi
 *    GPU chạy xong mọi lần nộp đã có lúc huỷ. _Ref huỷ ngay, chỗ gọi phải tự
 *    waitQueueIdle;
 *  - mất thiết bị là trạng thái hỏi được (loss()), không phải một mã lỗi lẫn
 *    trong đám khác;
 *  - ghi và đọc buffer bằng write_buffer, read_buffer, không trao con trỏ map
 *    ra ngoài;
 *  - mọi hàm tạo và huỷ an toàn đa luồng: hệ thống job nạp tài nguyên trên
 *    nhiều luồng.
 *  - Hàm vận hành trả Result hoặc Status; dùng sai (tay nắm chết, tham số ngoài
 *    hợp đồng) là InvalidArgument chứ không sập.
 *  - Nguồn: Forge2 src/gpu/device.hpp@d7fcd76. Khác gốc (so với Forge2):
 *    enumerator mang tiền tố k; bỏ {} thừa của các thành viên string,
 *    string_view, optional và span ở AdapterInfo, DeviceDesc, SubmitDesc,
 *    QueryPoolDesc.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "core/error.hpp"
#include "gpu/binding.hpp"
#include "gpu/command.hpp"
#include "gpu/pipeline.hpp"
#include "gpu/resource.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::gpu {

using core::ErrorCode;
using core::Result;
using core::Status;

// Khác gốc: bỏ {} mà clang-tidy báo thừa ở thành viên string, optional và span của tệp này.
struct AdapterInfo {
    std::string name;
    Backend backend = Backend::kVulkan;
    std::uint32_t vendor_id = 0;
    std::uint32_t device_id = 0;
    // Bộ nhớ riêng của GPU.
    std::uint64_t memory_bytes = 0;
    // Card rời. Máy xách tay có cả hai loại, chọn nhầm là chạy tám khung hình mỗi giây.
    bool is_discrete = false;
    // Bộ dựng hình bằng CPU (WARP, llvmpipe).
    bool is_software = false;
    // Tên và phiên bản trình điều khiển: nhiều lỗi đồ hoạ là của một bản cụ thể.
    std::string driver;
};

// Việc thiết bị làm được ngoài phần lõi bắt buộc.
struct DeviceCaps {
    // Mảng không chặn và cập nhật nhóm khi đang dùng (BindGroupDesc::capacity).
    bool bindless = false;
    bool tessellation = false;
    bool geometry_shader = false;
    bool mesh_shader = false;
    bool ray_query = false;
    bool depth_bounds = false;
    bool conservative_raster = false;
    // RasterState::is_depth_clipped bằng false.
    bool depth_clamp = false;
    // FillMode::kWireframe.
    bool wireframe = false;
    // Mỗi đích màu một BlendState riêng.
    bool independent_blend = false;
    // Truy vấn Occlusion đếm đúng số mẫu; false thì kết quả chỉ phân biệt 0 với khác 0.
    bool precise_occlusion = false;
    // Sức chứa lớn nhất của một mảng không chặn: texture và buffer, rồi sampler (heap sampler của
    // D3D12 chỉ có 2048 ô). 0 khi không có bindless.
    std::uint32_t max_unbounded = 0;
    std::uint32_t max_unbounded_samplers = 0;
    // Hàng đợi có thật; hàng thiếu được dồn sang Graphics và submit vẫn chạy.
    std::array<bool, kQueueCount> has_queue{};
    // Hàng đợi ghi được dấu thời gian.
    std::array<bool, kQueueCount> has_timestamps{};
    std::uint32_t max_texture_size = 0;
    std::uint32_t max_anisotropy = 1;
};

enum class FormatSupport : std::uint8_t {
    kNone = 0,
    kSampled = 1U << 0U,
    // Lấy mẫu có lọc tuyến tính.
    kFiltered = 1U << 1U,
    kColorTarget = 1U << 2U,
    kBlendable = 1U << 3U,
    kDepthTarget = 1U << 4U,
    kStorage = 1U << 5U,
};

template <>
inline constexpr bool kIsFlags<FormatSupport> = true;

struct MemoryBudget {
    // Số byte bộ nhớ GPU tiến trình đang giữ.
    std::uint64_t used_bytes = 0;
    // Số byte hệ điều hành cho giữ lúc này; vượt qua là bị đẩy ra bộ nhớ hệ thống, tụt khung hình
    // mà không có lỗi nào báo.
    std::uint64_t budget_bytes = 0;
};

struct DeviceDesc {
    Backend backend = Backend::kVulkan;
    // Chỉ số trong enumerate_adapters; rỗng thì lấy adapter đứng đầu danh sách (rời, nhiều bộ nhớ
    // nhất).
    std::optional<std::uint32_t> adapter;
    // Lớp kiểm tra của API. Thiếu lớp trên máy thì ghi cảnh báo rồi chạy tiếp.
    bool is_validated = false;
    // Nội dung Device::pipeline_cache của một lần chạy trước; sai thiết bị hay sai bản trình điều
    // khiển thì bị bỏ qua.
    std::span<const std::byte> pipeline_cache;
};

// Mất thiết bị làm mọi tay nắm, command list và timeline hết hiệu lực; cách duy nhất đi tiếp là
// huỷ Device rồi tạo lại.
enum class DeviceLoss : std::uint8_t {
    kNone,
    // Hệ điều hành reset trình điều khiển vì một lệnh chạy quá lâu (TDR).
    kReset,
    // Trình điều khiển treo, bị gỡ hay được cập nhật.
    kRemoved,
    kOutOfMemory,
};

[[nodiscard]] std::string_view name(DeviceLoss loss) noexcept;

// Bộ đếm đơn điệu cho mọi phép đồng bộ CPU với GPU và GPU với GPU. Mọi hàm an toàn đa luồng.
class Timeline {
public:
    Timeline() = default;
    Timeline(const Timeline&) = delete;
    Timeline& operator=(const Timeline&) = delete;
    Timeline(Timeline&&) = delete;
    Timeline& operator=(Timeline&&) = delete;
    virtual ~Timeline() = default;

    // Giá trị đã đạt; chỉ tăng.
    [[nodiscard]] virtual std::uint64_t completed() const noexcept = 0;
    // Chờ tới khi completed() đạt value. Timeout khi hết giờ; DeviceLost khi mất thiết bị.
    [[nodiscard]] virtual Status wait(std::uint64_t value, std::chrono::nanoseconds timeout) = 0;
    // Đẩy bộ đếm từ phía CPU, để mở một hàng đợi đang chờ dữ liệu CPU vừa dựng xong.
    virtual void signal(std::uint64_t value) = 0;
};

struct SubmitWait {
    Timeline* timeline = nullptr;
    std::uint64_t value = 0;
    // Giai đoạn đầu tiên bị chặn; D3D12 chờ ở đầu hàng đợi nên bỏ qua.
    SyncStage stage = SyncStage::kAll;
};

struct SubmitSignal {
    Timeline* timeline = nullptr;
    std::uint64_t value = 0;
};

class Swapchain;

struct SubmitDesc {
    std::span<CommandList* const> lists;
    std::span<const SubmitWait> waits;
    std::span<const SubmitSignal> signals;
    // Swapchain mà lần nộp này vẽ vào ảnh vừa acquire; đúng một lần nộp mỗi khung đặt trường này.
    // Vulkan nối semaphore của acquire và present qua đây; D3D12 bỏ qua.
    Swapchain* present_target = nullptr;
};

enum class PresentMode : std::uint8_t {
    // Chờ quét dọc: không xé hình, trễ cao nhất. Chế độ duy nhất mọi thiết bị bảo đảm có.
    kFifo,
    // Không chờ: xé hình, trễ thấp nhất.
    kImmediate,
    // Thay khung mới nhất khi chưa quét tới: không xé, trễ thấp.
    kMailbox,
};

[[nodiscard]] std::string_view name(PresentMode mode) noexcept;
[[nodiscard]] std::optional<PresentMode> parse_present_mode(std::string_view text) noexcept;

struct SwapchainDesc {
    // HWND trên Windows (window::Window::native_handle).
    void* window = nullptr;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    // Định dạng muốn có; bề mặt không nhận thì Swapchain::format trả định dạng thật.
    Format format = Format::kBgra8UnormSrgb;
    PresentMode present_mode = PresentMode::kFifo;
    std::uint32_t image_count = 3;
};

// Hình dạng theo Vulkan (phải acquire trước khi vẽ): D3D12 cài hình dạng ấy trong ba dòng, chiều
// ngược lại thì không có cách. Không an toàn đa luồng: một swapchain thuộc luồng vẽ.
class Swapchain {
public:
    Swapchain() = default;
    Swapchain(const Swapchain&) = delete;
    Swapchain& operator=(const Swapchain&) = delete;
    Swapchain(Swapchain&&) = delete;
    Swapchain& operator=(Swapchain&&) = delete;
    virtual ~Swapchain() = default;

    // Chỉ số ảnh để vẽ khung này. InvalidState khi bề mặt đã đổi cỡ và phải resize trước: đó là
    // đường chạy thường ngày (người dùng kéo cửa sổ), không phải hỏng.
    [[nodiscard]] virtual Result<std::uint32_t> acquire() = 0;
    [[nodiscard]] virtual TextureHandle image(std::uint32_t index) const = 0;
    [[nodiscard]] virtual TextureViewHandle view(std::uint32_t index) const = 0;
    [[nodiscard]] virtual std::uint32_t image_count() const noexcept = 0;
    // Đưa ảnh vừa acquire lên màn hình; ảnh phải ở bố cục Present.
    [[nodiscard]] virtual Status present() = 0;
    // Chờ GPU rỗi rồi dựng lại ảnh theo cỡ mới; tay nắm ảnh và view cũ hết hiệu lực.
    [[nodiscard]] virtual Status resize(std::uint32_t width, std::uint32_t height) = 0;

    // True khi swapchain đã đúng cỡ này và còn dùng được: resize lúc ấy chỉ tốn một lần chờ GPU rỗi và dựng
    // lại ảnh. Android báo đổi cỡ lại mỗi khi swapchain được dựng lại, nên chỗ gọi cần chặn vòng đó.
    // Mặc định false: backend nào không biết thì cứ dựng lại.
    [[nodiscard]] virtual bool is_current(std::uint32_t width, std::uint32_t height) const noexcept {
        static_cast<void>(width);
        static_cast<void>(height);
        return false;
    }

    // Định dạng, chế độ và cỡ thật sau khi bề mặt chốt; có thể khác thứ đã xin.
    [[nodiscard]] virtual Format format() const noexcept = 0;
    [[nodiscard]] virtual PresentMode present_mode() const noexcept = 0;
    [[nodiscard]] virtual std::uint32_t width() const noexcept = 0;
    [[nodiscard]] virtual std::uint32_t height() const noexcept = 0;

    // Bề mặt báo được lúc một lần present đã lên màn (Vulkan: VK_KHR_present_id và VK_KHR_present_wait).
    // Sai thì wait_shown luôn báo kUnsupported: chỗ gọi đo nhịp bằng đồng hồ CPU.
    [[nodiscard]] virtual bool reports_shown() const noexcept { return false; }
    // Số lần present đã nộp từ lần dựng swapchain gần nhất; resize đếm lại từ 0.
    [[nodiscard]] virtual std::uint64_t presents() const noexcept { return 0; }
    // Chờ tối đa timeout tới khi lần present thứ count (1 là lần đầu sau khi dựng, không quá presents())
    // đã lên màn. kTimeout khi hết hạn, kInvalidState khi bề mặt đã đổi (phải resize), kInvalidArgument
    // khi count ngoài [1, presents()], kUnsupported khi không reports_shown().
    [[nodiscard]] virtual Status wait_shown(std::uint64_t count, std::chrono::nanoseconds timeout);
};

enum class QueryKind : std::uint8_t {
    // Dấu thời gian; đọc ra nano giây.
    kTimestamp,
    // Số mẫu qua phép thử độ sâu.
    kOcclusion,
};

struct QueryPoolDesc {
    std::string_view name;
    QueryKind kind = QueryKind::kTimestamp;
    std::uint32_t count = 0;
    // Hàng đợi sẽ ghi vào pool: D3D12 cần kiểu heap riêng cho dấu thời gian trên hàng đợi Copy.
    QueueType queue = QueueType::kGraphics;
};

class Device {
public:
    Device() = default;
    Device(const Device&) = delete;
    Device& operator=(const Device&) = delete;
    Device(Device&&) = delete;
    Device& operator=(Device&&) = delete;
    virtual ~Device() = default;

    [[nodiscard]] virtual const AdapterInfo& adapter() const noexcept = 0;
    [[nodiscard]] virtual const DeviceCaps& caps() const noexcept = 0;
    [[nodiscard]] virtual FormatSupport format_support(Format format) const = 0;
    [[nodiscard]] virtual MemoryBudget memory_budget() const = 0;
    // None là thiết bị còn sống.
    [[nodiscard]] virtual DeviceLoss loss() const noexcept = 0;
    // Số lỗi lớp kiểm tra của API đã báo từ lúc tạo thiết bị (DeviceDesc::is_validated); luôn 0 khi
    // không bật. Nội dung từng lỗi nằm trong log. Bản gỡ lỗi và test đòi con số này bằng 0.
    [[nodiscard]] virtual std::uint64_t validation_errors() const noexcept = 0;

    [[nodiscard]] virtual Result<BufferHandle> create_buffer(const BufferDesc& desc) = 0;
    [[nodiscard]] virtual Result<TextureHandle> create_texture(const TextureDesc& desc) = 0;
    [[nodiscard]] virtual Result<TextureViewHandle> create_view(const TextureViewDesc& desc) = 0;
    [[nodiscard]] virtual Result<SamplerHandle> create_sampler(const SamplerDesc& desc) = 0;
    [[nodiscard]] virtual Result<ShaderHandle> create_shader(const ShaderDesc& desc) = 0;
    [[nodiscard]] virtual Result<PipelineHandle> create_pipeline(const GraphicsPipelineDesc& desc) = 0;
    [[nodiscard]] virtual Result<PipelineHandle> create_pipeline(const ComputePipelineDesc& desc) = 0;
    [[nodiscard]] virtual Result<BindGroupHandle> create_bind_group(const BindGroupDesc& desc) = 0;
    [[nodiscard]] virtual Result<QueryPoolHandle> create_query_pool(const QueryPoolDesc& desc) = 0;

    // Ghi thêm hoặc ghi đè các chỗ gắn của một nhóm. Chỉ nhóm có mảng không chặn mới được cập nhật
    // sau lần đầu được gắn; phần tử đang được một lệnh đã nộp đọc thì không được ghi đè.
    [[nodiscard]] virtual Status update_bind_group(BindGroupHandle group, std::span<const BindEntry> entries) = 0;

    // Huỷ hoãn. Tay nắm rỗng hoặc đã chết thì không làm gì.
    virtual void destroy(BufferHandle handle) = 0;
    virtual void destroy(TextureHandle handle) = 0;
    virtual void destroy(TextureViewHandle handle) = 0;
    virtual void destroy(SamplerHandle handle) = 0;
    virtual void destroy(ShaderHandle handle) = 0;
    virtual void destroy(PipelineHandle handle) = 0;
    virtual void destroy(BindGroupHandle handle) = 0;
    virtual void destroy(QueryPoolHandle handle) = 0;

    // Địa chỉ GPU của buffer tạo với BufferUsage::kAddress; 0 khi tay nắm chết hoặc thiếu cờ.
    [[nodiscard]] virtual std::uint64_t address(BufferHandle handle) const = 0;

    // Chép data vào buffer Upload, hoặc từ buffer Readback ra out. InvalidArgument cho buffer
    // Device (dùng lệnh chép) và khi khoảng vượt biên.
    [[nodiscard]] virtual Status write_buffer(BufferHandle handle, std::uint64_t offset,
        std::span<const std::byte> data) = 0;
    [[nodiscard]] virtual Status read_buffer(BufferHandle handle, std::uint64_t offset, std::span<std::byte> out) = 0;

    // Kết quả của các ô đã resolve_queries, sau khi lần nộp chứa lệnh ấy chạy xong: nano giây cho
    // Timestamp, số mẫu cho Occlusion. WouldBlock khi GPU chưa xong.
    [[nodiscard]] virtual Status read_queries(QueryPoolHandle pool, std::uint32_t first,
        std::span<std::uint64_t> out) = 0;

    [[nodiscard]] virtual Result<std::unique_ptr<Timeline>> create_timeline(std::uint64_t initial) = 0;
    [[nodiscard]] virtual Result<std::unique_ptr<Swapchain>> create_swapchain(const SwapchainDesc& desc) = 0;

    // CommandList thuộc Device: hợp lệ từ đây tới khi lần nộp chứa nó chạy xong. Lấy mà không nộp
    // thì nó bị thu hồi ở end_frame kế.
    [[nodiscard]] virtual Result<CommandList*> begin_commands(QueueType queue) = 0;
    [[nodiscard]] virtual Status submit(QueueType queue, const SubmitDesc& desc) = 0;
    // Chờ mọi hàng đợi rỗng. Cho lúc tắt và lúc đổi cỡ, không dùng mỗi khung. Giữ mutex của hàng
    // suốt lúc chờ: GPU đang chờ một Timeline mà CPU chưa signal thì hàm này không trả về, và
    // submit cùng hàng bị chặn theo.
    [[nodiscard]] virtual Status wait_idle() = 0;
    // Ranh giới khung hình: thu hồi command list đã chạy xong, giải phóng tài nguyên huỷ hoãn đã
    // tới hạn. DeviceLost khi thiết bị mất.
    [[nodiscard]] virtual Status end_frame() = 0;

    // Dữ liệu cache pipeline để ghi ra đĩa và trao lại ở DeviceDesc::pipeline_cache lần chạy sau.
    [[nodiscard]] virtual std::vector<std::byte> pipeline_cache() const = 0;
};

// Backend dựng được trong bản dựng này, theo thứ tự ưu tiên.
[[nodiscard]] std::span<const Backend> available_backends() noexcept;

// Adapter theo thứ tự ưu tiên: rời trước tích hợp, phần mềm sau cùng, nhiều bộ nhớ trước ít.
[[nodiscard]] Result<std::vector<AdapterInfo>> enumerate_adapters(Backend backend);

// Unsupported khi backend không có trong bản dựng hoặc không adapter nào đạt mức tối thiểu
// (Vulkan 1.3; D3D12 mức 12.0 có Enhanced Barriers).
[[nodiscard]] Result<std::unique_ptr<Device>> create_device(const DeviceDesc& desc);

// Thử đúng backend đã xin. Chỉ khi lỗi là kUnsupported thì thử lần lượt backend còn lại.
[[nodiscard]] Result<std::unique_ptr<Device>> create_present_device(const DeviceDesc& desc);

} // namespace game::gpu
