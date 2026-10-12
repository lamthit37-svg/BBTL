// Vòng đời thiết bị D3D12: liệt kê adapter, tạo thiết bị mức 12.0 có Enhanced Barriers, hàng đợi,
// heap descriptor và nộp lệnh. Tài nguyên nằm ở resources.cpp, pipeline ở programs.cpp.
// Nguồn: Forge2 src/gpu/d3d12/device.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; if trong
// for hoặc if tách hàm hoặc đưa lên điều kiện lặp; submit tách vì dài quá 40 dòng; thứ tự lời gọi
// D3D12 và phép kiểm HRESULT giữ nguyên; const HANDLE thành auto* const; include đúng header của
// từng tên; IID lấy từ hằng của SDK; NOLINT kèm lý do và mã quy tắc.
#include "gpu/d3d12/device.hpp"

#include "core/error.hpp"
#include "core/log.hpp"
#include "core/text.hpp"
#include "core/win32.hpp" // IWYU pragma: keep
#include "gpu/command.hpp"
#include "gpu/d3d12/commands.hpp"
#include "gpu/d3d12/convert.hpp"
#include "gpu/d3d12/swapchain.hpp"
#include "gpu/device.hpp"
#include "gpu/handle.hpp"
#include "gpu/memory.hpp"
#include "gpu/resource.hpp"
#include "gpu/retire.hpp"
#include "gpu/slots.hpp"
#include "gpu/types.hpp"

#include <basetsd.h>
#include <combaseapi.h>
#include <d3d12.h>
#include <d3d12sdklayers.h>
#include <d3dcommon.h>
#include <dxgi.h>
#include <dxgi1_3.h>
#include <dxgi1_4.h>
#include <dxgidebug.h>
#include <handleapi.h>
#include <synchapi.h>
#include <winbase.h>
#include <winerror.h>
#include <winnt.h>
#include <winuser.h>
#include <wrl/client.h>

#include "gpu/com.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <memory>
#include <mutex>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::gpu::d3d12 {

namespace {

using core::ErrorCode;
using core::fail;
using core::ok;
using Microsoft::WRL::ComPtr;

constexpr std::uint64_t kDiscreteBytes = std::uint64_t{512} << 20U;
constexpr std::uint64_t kHeapAlign = D3D12_DEFAULT_RESOURCE_PLACEMENT_ALIGNMENT;
constexpr std::uint64_t kMsaaAlign = D3D12_DEFAULT_MSAA_RESOURCE_PLACEMENT_ALIGNMENT;

struct Candidate {
    AdapterInfo info{};
    ComPtr<IDXGIAdapter1> adapter;
};

[[nodiscard]] bool is_before(const Candidate& left, const Candidate& right) noexcept {
    if (left.info.is_software != right.info.is_software) {
        return !left.info.is_software && right.info.is_software;
    }
    if (left.info.is_discrete != right.info.is_discrete) {
        return left.info.is_discrete && !right.info.is_discrete;
    }
    return left.info.memory_bytes > right.info.memory_bytes;
}

[[nodiscard]] bool has_barriers(IDXGIAdapter1* adapter) noexcept {
    ComPtr<ID3D12Device> device;
    const HRESULT created = D3D12CreateDevice(adapter, D3D_FEATURE_LEVEL_12_0, com_iid(device), com_pp(device));
    if (FAILED(created)) return false;
    D3D12_FEATURE_DATA_D3D12_OPTIONS12 options{};
    const HRESULT checked = device->CheckFeatureSupport(D3D12_FEATURE_D3D12_OPTIONS12, &options, sizeof(options));
    if (FAILED(checked)) return false;
    return options.EnhancedBarriersSupported == TRUE;
}

[[nodiscard]] Candidate describe(IDXGIAdapter1* adapter, bool is_software) {
    DXGI_ADAPTER_DESC1 desc{};
    adapter->GetDesc1(&desc);
    const bool is_flagged = (desc.Flags & DXGI_ADAPTER_FLAG_SOFTWARE) != 0;
    Candidate item;
    item.adapter = adapter;
    item.info.backend = Backend::kD3D12;
    const auto* description = static_cast<const wchar_t*>(desc.Description);
    item.info.name = core::narrow(description);
    item.info.vendor_id = desc.VendorId;
    item.info.device_id = desc.DeviceId;
    item.info.memory_bytes = desc.DedicatedVideoMemory;
    item.info.is_software = is_software || is_flagged;
    item.info.is_discrete = !item.info.is_software && desc.DedicatedVideoMemory >= kDiscreteBytes;
    item.info.driver = std::format("{:04x}.{:04x}.{}", desc.VendorId, desc.DeviceId, desc.Revision);
    return item;
}

// Khác gốc: if trong vòng EnumAdapters1 của collect.
void keep_adapter(std::vector<Candidate>& found, ComPtr<IDXGIAdapter1>& adapter) {
    IDXGIAdapter1* const raw = adapter.Get();
    if (!has_barriers(raw)) return;
    Candidate item = describe(raw, false);
    found.push_back(std::move(item));
    adapter.Reset();
}

[[nodiscard]] ComPtr<IDXGIFactory4> make_factory(bool debug) {
    const UINT flags = debug ? DXGI_CREATE_FACTORY_DEBUG : 0;
    ComPtr<IDXGIFactory4> factory;
    HRESULT created = CreateDXGIFactory2(flags, com_iid(factory), com_pp(factory));
    if (FAILED(created) && flags != 0) created = CreateDXGIFactory2(0, com_iid(factory), com_pp(factory));
    if (FAILED(created)) return {};
    return factory;
}

[[nodiscard]] std::vector<Candidate> collect(IDXGIFactory4* factory) {
    std::vector<Candidate> found;
    ComPtr<IDXGIAdapter1> adapter;
    for (UINT index = 0; factory->EnumAdapters1(index, &adapter) != DXGI_ERROR_NOT_FOUND; ++index) {
        keep_adapter(found, adapter);
    }
    const ComPtr<IDXGIFactory4> warp_factory = factory;
    ComPtr<IDXGIAdapter1> warp;
    const HRESULT warped = warp_factory->EnumWarpAdapter(com_iid(warp), com_pp(warp));
    if (FAILED(warped)) return found;
    IDXGIAdapter1* const raw = warp.Get();
    if (!has_barriers(raw)) return found;
    Candidate item = describe(raw, true);
    found.push_back(std::move(item));
    return found;
}

[[nodiscard]] ErrorCode code_of(HRESULT result) noexcept {
    if (result == E_OUTOFMEMORY) return ErrorCode::kOutOfMemory;
    if (result == DXGI_ERROR_DEVICE_REMOVED) return ErrorCode::kDeviceLost;
    if (result == DXGI_ERROR_DEVICE_HUNG) return ErrorCode::kDeviceLost;
    if (result == DXGI_ERROR_DEVICE_RESET) return ErrorCode::kDeviceLost;
    if (result == E_INVALIDARG) return ErrorCode::kInvalidArgument;
    return ErrorCode::kInternal;
}

[[nodiscard]] D3D12_HEAP_TYPE heap_type(PoolKind kind) noexcept {
    if (kind == PoolKind::kUpload) return D3D12_HEAP_TYPE_UPLOAD;
    if (kind == PoolKind::kReadback) return D3D12_HEAP_TYPE_READBACK;
    return D3D12_HEAP_TYPE_DEFAULT;
}

[[nodiscard]] D3D12_HEAP_FLAGS heap_flags(PoolKind kind) noexcept {
    if (kind == PoolKind::kDeviceBuffer) return D3D12_HEAP_FLAG_ALLOW_ONLY_BUFFERS;
    if (kind == PoolKind::kDeviceTarget) return D3D12_HEAP_FLAG_ALLOW_ONLY_RT_DS_TEXTURES;
    if (kind == PoolKind::kDeviceTexture) return D3D12_HEAP_FLAG_ALLOW_ONLY_NON_RT_DS_TEXTURES;
    return D3D12_HEAP_FLAG_ALLOW_ONLY_BUFFERS;
}

[[nodiscard]] bool needs_msaa_align(PoolKind kind) noexcept {
    return kind == PoolKind::kDeviceTarget || kind == PoolKind::kDeviceTexture;
}

[[nodiscard]] Status wait_value(ID3D12Fence* fence, UINT64 value) {
    if (fence->GetCompletedValue() >= value) return ok();
    // Khác gốc: gốc khai const HANDLE.
    auto* const event = CreateEventW(nullptr, FALSE, FALSE, nullptr);
    if (event == nullptr) return fail(ErrorCode::kInternal, "không tạo được sự kiện chờ");
    const HRESULT armed = fence->SetEventOnCompletion(value, event);
    if (SUCCEEDED(armed)) WaitForSingleObject(event, INFINITE);
    CloseHandle(event);
    if (FAILED(armed)) return fail(ErrorCode::kDeviceLost, "chờ hàng đợi rỗng thất bại");
    return ok();
}

void log_stored(ID3D12InfoQueue& info, std::uint64_t index) noexcept {
    try {
        SIZE_T bytes = 0;
        info.GetMessage(index, nullptr, &bytes);
        std::vector<std::byte> storage(bytes);
        // GetMessage ghi vào khối byte, không bit_cast được (UB-03).
        // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
        auto* message = reinterpret_cast<D3D12_MESSAGE*>(storage.data());
        info.GetMessage(index, message, &bytes);
        core::error("D3D12: {}", message->pDescription);
    } catch (...) {
        core::error("D3D12: không đọc được thông điệp lớp kiểm tra");
    }
}

void wait_queue(const Queue& queue) noexcept {
    if (queue.queue == nullptr || queue.fence == nullptr) return;
    const UINT64 value = queue.submitted.load();
    if (value == 0 || queue.fence->GetCompletedValue() >= value) return;
    // Khác gốc: gốc khai const HANDLE.
    auto* const event = CreateEventW(nullptr, FALSE, FALSE, nullptr);
    if (event == nullptr) return;
    const HRESULT armed = queue.fence->SetEventOnCompletion(value, event);
    if (SUCCEEDED(armed)) WaitForSingleObject(event, 5'000);
    CloseHandle(event);
}

constexpr ErrorCode kBad = ErrorCode::kInvalidArgument;

using QueueIndex = std::array<std::uint32_t, kQueueCount>;
using PipelineLibrary = ComPtr<ID3D12PipelineLibrary>;
using RawLists = std::vector<ID3D12CommandList*>;
using CommandPointers = std::vector<Commands*>;

void enable_debug() {
    ComPtr<ID3D12Debug> debug;
    // Khác gốc: if lồng của open tách ra đây.
    const HRESULT found = D3D12GetDebugInterface(com_iid(debug), com_pp(debug));
    if (SUCCEEDED(found)) debug->EnableDebugLayer();
    if (FAILED(found)) core::warn("D3D12: không có lớp kiểm tra, chạy tiếp");
}

// Khác gốc: if lồng của start tách ra đây.
void attach_info(ID3D12Device* device, ComPtr<ID3D12InfoQueue>& info) {
    const HRESULT queried = device->QueryInterface(com_iid(info), com_pp(info));
    if (SUCCEEDED(queried)) info->SetMessageCountLimit(1024);
    // Ngắt khi gặp lỗi (cấu hình hệ thống) ném 0x87D và giết tiến trình trước khi log kịp ghi.
    if (SUCCEEDED(queried)) {
        static_cast<void>(info->SetBreakOnSeverity(D3D12_MESSAGE_SEVERITY_CORRUPTION, FALSE));
        static_cast<void>(info->SetBreakOnSeverity(D3D12_MESSAGE_SEVERITY_ERROR, FALSE));
        static_cast<void>(info->SetBreakOnSeverity(D3D12_MESSAGE_SEVERITY_WARNING, FALSE));
    }
    Microsoft::WRL::ComPtr<IDXGIInfoQueue> dxgi_info;
    if (SUCCEEDED(DXGIGetDebugInterface1(0, com_iid(dxgi_info), com_pp(dxgi_info)))) {
        static_cast<void>(dxgi_info->SetBreakOnSeverity(DXGI_DEBUG_ALL, DXGI_INFO_QUEUE_MESSAGE_SEVERITY_CORRUPTION,
            FALSE));
        static_cast<void>(dxgi_info->SetBreakOnSeverity(DXGI_DEBUG_ALL, DXGI_INFO_QUEUE_MESSAGE_SEVERITY_ERROR, FALSE));
    }
    // pSeverityList nhận con trỏ không hằng, nên mảng không const.
    std::array deny{D3D12_MESSAGE_SEVERITY_INFO, D3D12_MESSAGE_SEVERITY_MESSAGE};
    D3D12_INFO_QUEUE_FILTER filter{};
    filter.DenyList.NumSeverities = static_cast<UINT>(deny.size());
    filter.DenyList.pSeverityList = deny.data();
    // Nạp tên chưa có là lần trượt cache bình thường. Lưu trùng tên cũng vậy: tên chỉ là khoá.
    std::array deny_ids{D3D12_MESSAGE_ID_LOADPIPELINE_NAMENOTFOUND, D3D12_MESSAGE_ID_STOREPIPELINE_DUPLICATENAME};
    filter.DenyList.NumIDs = static_cast<UINT>(deny_ids.size());
    filter.DenyList.pIDList = deny_ids.data();
    if (SUCCEEDED(queried)) info->PushStorageFilter(&filter);
    if (SUCCEEDED(queried)) info->ClearStoredMessages();
}

// Khác gốc: if trong vòng tạo hàng đợi.
[[nodiscard]] Status accept_queue(bool made, QueueType kind) {
    if (made) return ok();
    if (kind != QueueType::kGraphics) return ok();
    return fail(ErrorCode::kInternal, "không tạo được hàng Graphics");
}

// Khác gốc: if trong vòng mượn hàng Graphics.
void borrow_graphics(DeviceCaps& caps, QueueIndex& index, QueueType kind) {
    const auto slot = std::to_underlying(kind);
    if (caps.has_queue.at(slot)) return;
    const std::uint32_t graphics = index.at(0);
    index.at(slot) = graphics;
}

// Khác gốc: if lồng của create_library.
// Thư viện pipeline giữ con trỏ blob của người gọi. Chép vào bộ nhớ của thiết bị trước khi tạo.
void load_cache(ID3D12Device2* device, PipelineLibrary& library, std::vector<std::byte>& kept,
    std::span<const std::byte> cache) {
    if (cache.empty()) return;
    kept.assign(cache.begin(), cache.end());
    const HRESULT loaded = device->CreatePipelineLibrary(kept.data(), kept.size(), com_iid(library), com_pp(library));
    if (FAILED(loaded)) library.Reset();
    if (FAILED(loaded)) kept.clear();
}

// Khác gốc: if trong vòng wait_idle.
[[nodiscard]] Status wait_submitted(Queue& queue) {
    const std::uint64_t value = queue.submitted.load();
    if (value == 0) return ok();
    const std::scoped_lock lock(queue.mutex);
    ID3D12Fence* const fence = queue.fence.Get();
    return wait_value(fence, value);
}

struct Submission {
    CommandPointers lists;
    RawLists raw;
    std::vector<Timeline12*> waits;
    std::vector<std::uint64_t> wait_values;
    std::vector<Timeline12*> signals;
    std::vector<std::uint64_t> signal_values;
};

// Khác gốc: if trong vòng list của submit.
[[nodiscard]] Status add_list(Submission& submission, CommandList* list, QueueType queue) {
    auto* const commands = dynamic_cast<Commands*>(list);
    const bool is_ours = commands != nullptr && commands->queue() == queue;
    if (!is_ours) return fail(kBad, "submit: command list lạ hoặc sai hàng đợi");
    for (const Commands* const held : submission.lists) {
        if (held == commands) return fail(kBad, "submit: cùng một list hai lần");
    }
    Status closed = commands->close();
    if (!closed) return closed;
    submission.lists.push_back(commands);
    ID3D12CommandList* const raw = commands->list();
    submission.raw.push_back(raw);
    return ok();
}

// Khác gốc: if trong vòng wait của submit.
[[nodiscard]] Status add_wait(Submission& submission, const SubmitWait& wait) {
    auto* const timeline = dynamic_cast<Timeline12*>(wait.timeline);
    if (timeline == nullptr) return fail(kBad, "submit: timeline lạ");
    submission.waits.push_back(timeline);
    submission.wait_values.push_back(wait.value);
    return ok();
}

// Khác gốc: if trong vòng signal của submit.
[[nodiscard]] Status add_signal(Submission& submission, const SubmitSignal& signal) {
    auto* const timeline = dynamic_cast<Timeline12*>(signal.timeline);
    if (timeline == nullptr) return fail(kBad, "submit: timeline tín hiệu lạ");
    submission.signals.push_back(timeline);
    submission.signal_values.push_back(signal.value);
    return ok();
}

// Khác gốc: ba vòng if của submit đưa lên điều kiện lặp.
[[nodiscard]] Status fill(Submission& submission, QueueType queue, const SubmitDesc& desc) {
    submission.lists.reserve(desc.lists.size());
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

// Khác gốc: kiểm present_target của submit tách ra đây.
[[nodiscard]] Result<Swapchain12*> find_target(QueueType queue, const SubmitDesc& desc) {
    auto* const target = dynamic_cast<Swapchain12*>(desc.present_target);
    const bool has_target = desc.present_target != nullptr;
    const bool is_presentable = target != nullptr && queue == QueueType::kGraphics;
    if (has_target && !is_presentable) {
        return fail(kBad, "submit: present_target lạ hoặc ngoài hàng Graphics");
    }
    if (has_target && !target->is_awaiting_submit()) {
        return fail(ErrorCode::kInvalidState, "submit: present_target chưa acquire hoặc đã được nộp");
    }
    return target;
}

// Khác gốc: vòng Wait của submit, tách vì hàm dài.
void record_waits(const Queue& physical, const Submission& submission) {
    const std::size_t count = submission.waits.size();
    for (std::size_t index = 0; index < count; ++index) {
        const Timeline12* const timeline = submission.waits.at(index);
        const std::uint64_t value = submission.wait_values.at(index);
        ID3D12Fence* const fence = timeline->fence();
        physical.queue->Wait(fence, value);
    }
}

// Khác gốc: vòng Signal của submit, tách vì hàm dài.
void record_signals(const Queue& physical, const Submission& submission) {
    const std::size_t count = submission.signals.size();
    for (std::size_t index = 0; index < count; ++index) {
        const Timeline12* const timeline = submission.signals.at(index);
        const std::uint64_t value = submission.signal_values.at(index);
        ID3D12Fence* const fence = timeline->fence();
        physical.queue->Signal(fence, value);
    }
}

// Khác gốc: Execute của submit tách ra vì hàm dài.
void execute_lists(const Queue& physical, const RawLists& raw) {
    if (raw.empty()) return;
    const auto count = static_cast<UINT>(raw.size());
    ID3D12CommandList* const* data = raw.data();
    physical.queue->ExecuteCommandLists(count, data);
}

// Khác gốc: vòng stamp của submit, tách vì hàm dài.
void stamp_lists(const CommandPointers& lists, std::uint64_t value) {
    for (Commands* const commands : lists) {
        commands->stamp(value);
    }
}

} // namespace

using core::ErrorCode;
using core::fail;
using core::ok;

void set_name(ID3D12Object* object, std::string_view name) {
    if (object == nullptr || name.empty()) return;
    const std::wstring wide = core::widen(name);
    object->SetName(wide.c_str());
}

using HeapType = D3D12_DESCRIPTOR_HEAP_TYPE;
using IDevice = ID3D12Device;

Status DescriptorArena::create(IDevice* device, HeapType type, UINT count, bool is_shader_visible) {
    D3D12_DESCRIPTOR_HEAP_DESC desc{};
    desc.Type = type;
    desc.NumDescriptors = count;
    desc.Flags = is_shader_visible ? D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE : D3D12_DESCRIPTOR_HEAP_FLAG_NONE;
    const HRESULT created = device->CreateDescriptorHeap(&desc, com_iid(heap_), com_pp(heap_));
    if (FAILED(created)) return fail(ErrorCode::kOutOfMemory, "hết descriptor D3D12");
    cpu_ = heap_->GetCPUDescriptorHandleForHeapStart();
    if (is_shader_visible) gpu_ = heap_->GetGPUDescriptorHandleForHeapStart();
    stride_ = device->GetDescriptorHandleIncrementSize(type);
    capacity_ = count;
    bump_ = 0;
    return ok();
}

// Khác gốc: for của take_free đổi thành while.
std::optional<UINT> DescriptorArena::take_free(UINT count) noexcept {
    std::size_t index = 0;
    while (index < free_.size() && free_.at(index).count < count)
        ++index;
    if (index == free_.size()) return std::nullopt;
    const UINT slot = free_.at(index).index;
    free_.at(index).index += count;
    free_.at(index).count -= count;
    if (free_.at(index).count != 0) return slot;
    const auto begin = free_.begin();
    const auto where = begin + static_cast<std::ptrdiff_t>(index);
    free_.erase(where);
    return slot;
}

std::optional<UINT> DescriptorArena::allocate(UINT count) {
    if (count == 0) return std::nullopt;
    const std::scoped_lock lock(mutex_);
    const std::optional<UINT> recycled = take_free(count);
    if (recycled) return recycled;
    if (bump_ + count > capacity_) return std::nullopt;
    const UINT slot = bump_;
    bump_ += count;
    return slot;
}

// push_back có thể ném; noexcept của gốc thì terminate (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
void DescriptorArena::free(UINT index, UINT count) noexcept {
    if (count == 0 || index == kNoDescriptor) return;
    const std::scoped_lock lock(mutex_);
    free_.push_back({.index = index, .count = count});
}

D3D12_CPU_DESCRIPTOR_HANDLE DescriptorArena::cpu(UINT index) const noexcept {
    return {.ptr = cpu_.ptr + (static_cast<SIZE_T>(index) * stride_)};
}

D3D12_GPU_DESCRIPTOR_HANDLE DescriptorArena::gpu(UINT index) const noexcept {
    return {.ptr = gpu_.ptr + (static_cast<UINT64>(index) * stride_)};
}

struct D3d12Device::Contexts {
    struct Pending {
        Commands* commands = nullptr;
        std::uint64_t value = 0;
    };
    struct Lane {
        std::mutex mutex;
        std::vector<std::unique_ptr<Commands>> owned;
        std::vector<Commands*> idle;
        std::vector<Commands*> open;
        std::vector<Pending> busy;
    };
    std::array<Lane, kQueueCount> lanes{};

    static void settle(Lane& lane, std::uint64_t reached) {
        const std::scoped_lock lock(lane.mutex);
        const auto is_running = [reached](const Pending& item) { return item.value > reached; };
        const auto finished = std::ranges::stable_partition(lane.busy, is_running);
        for (const Pending& item : finished) {
            item.commands->mark_idle();
            lane.idle.push_back(item.commands);
        }
        lane.busy.erase(finished.begin(), finished.end());
    }

    // Khác gốc: khối if (lane.idle.empty()) của begin_commands.
    [[nodiscard]] static Status refill(D3d12Device& device, Lane& lane, QueueType queue);
    using ListSet = std::vector<Commands*>;
    static void park(Lane& lane, const ListSet& lists, std::uint64_t value);

    static void reclaim(Lane& lane, std::atomic<std::uint32_t>& recording) {
        const std::scoped_lock lock(lane.mutex);
        const auto count = static_cast<std::uint32_t>(lane.open.size());
        for (Commands* const commands : lane.open) {
            commands->discard();
            lane.idle.push_back(commands);
        }
        lane.open.clear();
        if (count != 0) recording.fetch_sub(count, std::memory_order_acq_rel);
    }
};

Result<std::vector<AdapterInfo>> adapters() {
    const ComPtr<IDXGIFactory4> factory = make_factory(false);
    if (factory == nullptr) return fail(ErrorCode::kInternal, "không tạo được factory DXGI");
    std::vector<Candidate> found = collect(factory.Get());
    std::ranges::sort(found, is_before);
    std::vector<AdapterInfo> infos;
    infos.reserve(found.size());
    for (const Candidate& item : found) {
        infos.push_back(item.info);
    }
    if (infos.empty()) {
        return fail(ErrorCode::kUnsupported, "không adapter nào có Enhanced Barriers");
    }
    return infos;
}

Result<std::unique_ptr<Device>> create(const DeviceDesc& desc) {
    return D3d12Device::open(desc);
}

Result<std::unique_ptr<Device>> D3d12Device::open(const DeviceDesc& desc) {
    if (desc.is_validated) enable_debug();
    const ComPtr<IDXGIFactory4> factory = make_factory(desc.is_validated);
    if (factory == nullptr) return fail(ErrorCode::kInternal, "không tạo được factory DXGI");
    IDXGIFactory4* const raw = factory.Get();
    std::vector<Candidate> found = collect(raw);
    std::ranges::sort(found, is_before);
    if (found.empty()) {
        return fail(ErrorCode::kUnsupported, "không adapter nào có Enhanced Barriers");
    }
    const std::size_t index = desc.adapter.value_or(0);
    if (index >= found.size()) return fail(kBad, "chỉ số adapter ngoài danh sách");
    auto device = std::make_unique<D3d12Device>();
    device->factory_ = factory;
    device->debug_ = desc.is_validated;
    const Candidate& chosen = found.at(index);
    IDXGIAdapter1* const adapter = chosen.adapter.Get();
    Status started = device->start(chosen.info, adapter, desc);
    if (!started) return std::unexpected(std::move(started).error());
    return device;
}

Status D3d12Device::start(const AdapterInfo& info, IDXGIAdapter1* adapter, const DeviceDesc& desc) {
    adapter_ = info;
    adapter_com_ = adapter;
    IDXGIAdapter1* const hardware = adapter_com_.Get();
    const HRESULT created = D3D12CreateDevice(hardware, D3D_FEATURE_LEVEL_12_0, com_iid(device_), com_pp(device_));
    if (FAILED(created)) return failed(created, "không tạo được thiết bị D3D12");
    ID3D12Device* const device = device_.Get();
    if (debug_) attach_info(device, info_);
    const Status queues = create_queues();
    if (!queues) return queues;
    const Status heaps = create_heaps();
    if (!heaps) return heaps;
    read_caps();
    create_library(desc.pipeline_cache);
    contexts_ = std::make_unique<Contexts>();
    return ok();
}

bool D3d12Device::add_queue(QueueType kind) {
    D3D12_COMMAND_QUEUE_DESC info{};
    info.Type = to_list(kind);
    Queue& slot = queues_.at(queue_count_);
    const HRESULT created = device_->CreateCommandQueue(&info, com_iid(slot.queue), com_pp(slot.queue));
    const HRESULT fence = device_->CreateFence(0, D3D12_FENCE_FLAG_NONE, com_iid(slot.fence), com_pp(slot.fence));
    const bool is_ok = SUCCEEDED(created) && SUCCEEDED(fence);
    if (!is_ok) slot.queue.Reset();
    if (!is_ok) slot.fence.Reset();
    if (!is_ok) return false;
    UINT64 frequency = 0;
    slot.queue->GetTimestampFrequency(&frequency);
    if (frequency != 0) slot.period_ns = 1'000'000'000.0 / static_cast<double>(frequency);
    slot.is_native = true;
    queue_index_.at(std::to_underlying(kind)) = static_cast<std::uint32_t>(queue_count_);
    caps_.has_queue.at(std::to_underlying(kind)) = true;
    caps_.has_timestamps.at(std::to_underlying(kind)) = true;
    ++queue_count_;
    return true;
}

Status D3d12Device::create_queues() {
    const std::array kinds{QueueType::kGraphics, QueueType::kCompute, QueueType::kCopy};
    Status made = ok();
    for (auto cursor = kinds.begin(); cursor != kinds.end() && made; ++cursor) {
        const bool added = add_queue(*cursor);
        made = accept_queue(added, *cursor);
    }
    if (!made) return made;
    for (const QueueType kind : kinds) {
        borrow_graphics(caps_, queue_index_, kind);
    }
    return ok();
}

Status D3d12Device::create_heaps() {
    UINT resource_count = kResourceDescriptors;
    core::Status resources =
        resources_.create(device_.Get(), D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV, resource_count, true);
    if (!resources) resource_count = 4'096;
    if (!resources) {
        resources = resources_.create(device_.Get(), D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV, resource_count, true);
    }
    if (!resources) return resources;
    UINT sampler_count = kSamplerDescriptors;
    core::Status samplers =
        samplers_gpu_.create(device_.Get(), D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER, sampler_count, true);
    if (!samplers) sampler_count = 128;
    if (!samplers) {
        samplers = samplers_gpu_.create(device_.Get(), D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER, sampler_count, true);
    }
    if (!samplers) return samplers;
    const Status staging =
        staging_.create(device_.Get(), D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV, resource_count, false);
    if (!staging) return staging;
    const Status sampler_staging =
        sampler_staging_.create(device_.Get(), D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER, sampler_count, false);
    if (!sampler_staging) return sampler_staging;
    const Status rtvs = rtvs_.create(device_.Get(), D3D12_DESCRIPTOR_HEAP_TYPE_RTV, kRtvDescriptors, false);
    if (!rtvs) return rtvs;
    const Status dsvs = dsvs_.create(device_.Get(), D3D12_DESCRIPTOR_HEAP_TYPE_DSV, kDsvDescriptors, false);
    if (!dsvs) return dsvs;
    caps_.max_unbounded = resource_count / 4;
    caps_.max_unbounded_samplers = sampler_count / 4;
    return ok();
}

void D3d12Device::read_caps() {
    // Enum struct SDK không có 0; API ghi đè trước khi đọc (UB-06).
    // NOLINTNEXTLINE(bugprone-invalid-enum-default-initialization)
    D3D12_FEATURE_DATA_D3D12_OPTIONS options{};
    device_->CheckFeatureSupport(D3D12_FEATURE_D3D12_OPTIONS, &options, sizeof(options));
    D3D12_FEATURE_DATA_D3D12_OPTIONS2 options2{};
    device_->CheckFeatureSupport(D3D12_FEATURE_D3D12_OPTIONS2, &options2, sizeof(options2));
    D3D12_FEATURE_DATA_D3D12_OPTIONS5 options5{};
    device_->CheckFeatureSupport(D3D12_FEATURE_D3D12_OPTIONS5, &options5, sizeof(options5));
    D3D12_FEATURE_DATA_D3D12_OPTIONS7 options7{};
    device_->CheckFeatureSupport(D3D12_FEATURE_D3D12_OPTIONS7, &options7, sizeof(options7));
    caps_.bindless = options.ResourceBindingTier >= D3D12_RESOURCE_BINDING_TIER_2;
    if (!caps_.bindless) caps_.max_unbounded = 0;
    if (!caps_.bindless) caps_.max_unbounded_samplers = 0;
    caps_.tessellation = true;
    caps_.geometry_shader = true;
    caps_.mesh_shader = options7.MeshShaderTier != D3D12_MESH_SHADER_TIER_NOT_SUPPORTED;
    caps_.ray_query = options5.RaytracingTier >= D3D12_RAYTRACING_TIER_1_1;
    caps_.depth_bounds = options2.DepthBoundsTestSupported == TRUE;
    caps_.conservative_raster =
        options.ConservativeRasterizationTier != D3D12_CONSERVATIVE_RASTERIZATION_TIER_NOT_SUPPORTED;
    caps_.depth_clamp = true;
    caps_.wireframe = true;
    caps_.independent_blend = true;
    caps_.precise_occlusion = true;
    caps_.max_texture_size = 16'384;
    caps_.max_anisotropy = 16;
}

void D3d12Device::create_library(std::span<const std::byte> cache) {
    ID3D12Device2* const device = device_.Get();
    load_cache(device, library_, library_bytes_, cache);
    if (library_ != nullptr) return;
    const HRESULT created = device->CreatePipelineLibrary(nullptr, 0, com_iid(library_), com_pp(library_));
    if (FAILED(created)) library_.Reset();
}

// drain cấp phát; ném trong noexcept là terminate (LH-07).
// NOLINTBEGIN(bugprone-exception-escape)
template <class T, class Tag>
void D3d12Device::drain(Slots<T, Tag>& table) noexcept {
    for (T& value : table.drain()) {
        discard(value);
    }
}
// NOLINTEND(bugprone-exception-escape)

void D3d12Device::wait_queues() noexcept {
    for (std::uint32_t index = 0; index < queue_count_; ++index) {
        wait_queue(queues_.at(index));
    }
}

// Hàm huỷ noexcept; ném là terminate (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
D3d12Device::~D3d12Device() {
    if (loss() == DeviceLoss::kNone && device_ != nullptr) wait_queues();
    contexts_.reset();
    drain(buffers_);
    drain(textures_);
    drain(views_);
    drain(samplers_);
    drain(shaders_);
    drain(pipelines_);
    drain(groups_);
    drain(queries_);
    retired_.flush();
    for (auto& pool : pools_) {
        pool.reset();
    }
}

void D3d12Device::pump_messages() const {
    if (info_ == nullptr) return;
    const std::uint64_t count = info_->GetNumStoredMessages();
    for (std::uint64_t index = logged_; index < count; ++index) {
        log_stored(*info_.Get(), index);
    }
    logged_ = count;
}

std::uint64_t D3d12Device::validation_errors() const noexcept {
    if (info_ == nullptr) return 0;
    pump_messages();
    return info_->GetNumStoredMessages();
}

void D3d12Device::note_loss() noexcept {
    const HRESULT reason = device_->GetDeviceRemovedReason();
    DeviceLoss kind = DeviceLoss::kRemoved;
    if (reason == DXGI_ERROR_DEVICE_HUNG) kind = DeviceLoss::kReset;
    if (reason == DXGI_ERROR_DEVICE_RESET) kind = DeviceLoss::kReset;
    if (reason == E_OUTOFMEMORY) kind = DeviceLoss::kOutOfMemory;
    loss_.store(kind);
}

core::Failure D3d12Device::failed(HRESULT result, core::Message message) noexcept {
    const bool is_lost =
        result == DXGI_ERROR_DEVICE_REMOVED || result == DXGI_ERROR_DEVICE_HUNG || result == DXGI_ERROR_DEVICE_RESET;
    // Hết bộ nhớ của một lần cấp phát không gỡ thiết bị. Chỉ DEVICE_REMOVED mới hỏi lý do.
    if (is_lost) note_loss();
    core::warn("D3D12 {:#x}: {}", static_cast<std::uint32_t>(result), message.text());
    return fail(code_of(result), message);
}

QueueMarks D3d12Device::marks() const noexcept {
    QueueMarks values{};
    for (std::size_t type = 0; type < kQueueCount; ++type) {
        std::uint64_t value = queues_.at(queue_index_.at(type)).submitted.load(std::memory_order_acquire);
        value += recording_.at(type).load(std::memory_order_acquire);
        values.at(type) = value;
    }
    return values;
}

QueueMarks D3d12Device::cached_done() const noexcept {
    QueueMarks done{};
    for (std::size_t type = 0; type < kQueueCount; ++type) {
        done.at(type) = done_cache_.at(type).load(std::memory_order_relaxed);
    }
    return done;
}

void D3d12Device::keep_done(const QueueMarks& done) noexcept {
    for (std::size_t type = 0; type < kQueueCount; ++type) {
        done_cache_.at(type).store(done.at(type), std::memory_order_relaxed);
    }
}

QueueMarks D3d12Device::finished() const noexcept {
    QueueMarks values{};
    for (std::size_t type = 0; type < kQueueCount; ++type) {
        values.at(type) = queues_.at(queue_index_.at(type)).fence->GetCompletedValue();
    }
    return values;
}

std::uint64_t D3d12Device::completed(QueueType type) const noexcept {
    const UINT64 value = queue_of(type).fence->GetCompletedValue();
    if (value == UINT64_MAX) return 0;
    return value;
}

void D3d12Device::recycle(const QueueMarks& done) {
    for (std::size_t type = 0; type < kQueueCount; ++type) {
        Contexts::settle(contexts_->lanes.at(type), done.at(type));
    }
}

Result<std::unique_ptr<Commands>> D3d12Device::make_commands(QueueType queue) {
    ComPtr<ID3D12CommandAllocator> allocator;
    const HRESULT allocated = device_->CreateCommandAllocator(to_list(queue), com_iid(allocator), com_pp(allocator));
    if (FAILED(allocated)) return failed(allocated, "không tạo được command allocator");
    ComPtr<ID3D12GraphicsCommandList7> list;
    const HRESULT created =
        device_->CreateCommandList(0, to_list(queue), allocator.Get(), nullptr, com_iid(list), com_pp(list));
    if (FAILED(created)) return failed(created, "không tạo được command list");
    const HRESULT closed = list->Close();
    if (FAILED(closed)) return failed(closed, "không đóng được command list mới");
    return std::make_unique<Commands>(*this, queue, std::move(allocator), std::move(list));
}

// Khác gốc: if rỗng của begin_commands tách ra đây.
Status D3d12Device::Contexts::refill(D3d12Device& device, Lane& lane, QueueType queue) {
    if (!lane.idle.empty()) return ok();
    Result<std::unique_ptr<Commands>> created = device.make_commands(queue);
    if (!created) return std::unexpected(std::move(created).error());
    Commands* const commands = created->get();
    lane.idle.push_back(commands);
    std::unique_ptr<Commands> owned = std::move(*created);
    lane.owned.push_back(std::move(owned));
    return ok();
}

Result<CommandList*> D3d12Device::begin_commands(QueueType queue) {
    if (loss() != DeviceLoss::kNone) return fail(ErrorCode::kDeviceLost, "thiết bị đã mất");
    const auto slot = std::to_underlying(queue);
    Contexts::Lane& lane = contexts_->lanes.at(slot);
    const std::scoped_lock lock(lane.mutex);
    Status refilled = Contexts::refill(*this, lane, queue);
    if (!refilled) return std::unexpected(std::move(refilled).error());
    Commands* const commands = lane.idle.back();
    const Status opened = commands->open();
    if (!opened) return std::unexpected(opened.error());
    lane.idle.pop_back();
    lane.open.push_back(commands);
    recording_.at(slot).fetch_add(1, std::memory_order_acq_rel);
    return commands;
}

// Khác gốc: vòng busy của submit, tách vì hàm dài.
void D3d12Device::Contexts::park(Lane& lane, const ListSet& lists, std::uint64_t value) {
    for (Commands* const commands : lists) {
        std::erase(lane.open, commands);
        commands->mark_pending();
        lane.busy.push_back({.commands = commands, .value = value});
    }
}

Status D3d12Device::submit(QueueType queue, const SubmitDesc& desc) {
    if (loss() != DeviceLoss::kNone) return fail(ErrorCode::kDeviceLost, "thiết bị đã mất");
    Result<Swapchain12*> found = find_target(queue, desc);
    if (!found) return std::unexpected(std::move(found).error());
    Submission submission;
    Status filled = fill(submission, queue, desc);
    if (!filled) return filled;
    Queue& physical = queue_of(queue);
    const std::scoped_lock lock(physical.mutex);
    record_waits(physical, submission);
    execute_lists(physical, submission.raw);
    const std::uint64_t value = physical.submitted.load() + 1;
    ID3D12Fence* const fence = physical.fence.Get();
    const HRESULT signaled = physical.queue->Signal(fence, value);
    record_signals(physical, submission);
    physical.submitted.store(value);
    stamp_lists(submission.lists, value);
    Swapchain12* const target = *found;
    if (target != nullptr) target->mark_submitted();
    const auto slot = std::to_underlying(queue);
    Contexts::Lane& lane = contexts_->lanes.at(slot);
    const std::scoped_lock lane_lock(lane.mutex);
    Contexts::park(lane, submission.lists, value);
    const auto parked = static_cast<std::uint32_t>(submission.lists.size());
    recording_.at(slot).fetch_sub(parked, std::memory_order_acq_rel);
    if (FAILED(signaled)) return failed(signaled, "nộp lệnh thất bại");
    return ok();
}

Status D3d12Device::wait_idle() {
    Status waited = ok();
    for (std::uint32_t index = 0; index < queue_count_ && waited; ++index) {
        waited = wait_submitted(queues_.at(index));
    }
    if (!waited) return waited;
    const QueueMarks done = finished();
    keep_done(done);
    recycle(done);
    retired_.collect(done);
    return ok();
}

Status D3d12Device::end_frame() {
    if (loss() != DeviceLoss::kNone) return fail(ErrorCode::kDeviceLost, "thiết bị đã mất");
    const QueueMarks done = finished();
    keep_done(done);
    recycle(done);
    for (std::size_t type = 0; type < kQueueCount; ++type) {
        Contexts::reclaim(contexts_->lanes.at(type), recording_.at(type));
    }
    retired_.collect(done);
    return ok();
}

std::vector<std::byte> D3d12Device::pipeline_cache() const {
    if (library_ == nullptr) return {};
    const SIZE_T size = library_->GetSerializedSize();
    if (size == 0) return {};
    std::vector<std::byte> data(size);
    const HRESULT stored = library_->Serialize(data.data(), size);
    if (FAILED(stored)) return {};
    return data;
}

ID3D12CommandSignature* D3d12Device::signature(IndirectKind kind, UINT stride) {
    const std::scoped_lock lock(signature_mutex_);
    const SignatureKey key{.kind = kind, .stride = stride};
    const auto matches = [key](const auto& item) { return item.first == key; };
    const auto found = std::ranges::find_if(signatures_, matches);
    if (found != signatures_.end()) return found->second.Get();
    D3D12_INDIRECT_ARGUMENT_DESC argument{};
    const auto indexed = D3D12_INDIRECT_ARGUMENT_TYPE_DRAW_INDEXED;
    if (kind == IndirectKind::kDraw) argument.Type = D3D12_INDIRECT_ARGUMENT_TYPE_DRAW;
    if (kind == IndirectKind::kDrawIndexed) argument.Type = indexed;
    if (kind == IndirectKind::kDispatch) argument.Type = D3D12_INDIRECT_ARGUMENT_TYPE_DISPATCH;
    D3D12_COMMAND_SIGNATURE_DESC desc{};
    desc.ByteStride = stride;
    desc.NumArgumentDescs = 1;
    desc.pArgumentDescs = &argument;
    ComPtr<ID3D12CommandSignature> signature;
    const HRESULT created = device_->CreateCommandSignature(&desc, nullptr, com_iid(signature), com_pp(signature));
    if (FAILED(created)) return nullptr;
    signatures_.emplace_back(key, signature);
    return signature.Get();
}

Result<HeapBlock> D3d12Device::make_heap(PoolKind kind, bool is_msaa, std::uint64_t bytes) {
    const std::uint64_t align = is_msaa ? kMsaaAlign : kHeapAlign;
    const std::uint64_t size = (bytes + align - 1) & ~(align - 1);
    // Enum struct SDK không có 0; CreateHeap ghi đè trước khi đọc (UB-06).
    // NOLINTNEXTLINE(bugprone-invalid-enum-default-initialization)
    D3D12_HEAP_DESC desc{};
    desc.SizeInBytes = size;
    desc.Properties.Type = heap_type(kind);
    desc.Alignment = align;
    desc.Flags = heap_flags(kind);
    HeapBlock block;
    const HRESULT created = device_->CreateHeap(&desc, com_iid(block.heap), com_pp(block.heap));
    if (FAILED(created)) return failed(created, "không tạo được heap D3D12");
    return block;
}

using AllocInfo = D3D12_RESOURCE_ALLOCATION_INFO;

Result<Allocation> D3d12Device::allocate(const AllocInfo& needs, PoolKind kind) {
    const bool is_msaa = needs_msaa_align(kind);
    const auto make = [this, kind, is_msaa](auto n) { return make_heap(kind, is_msaa, n); };
    const std::scoped_lock lock(memory_mutex_);
    auto& pool = pools_.at(std::to_underlying(kind));
    if (!pool) {
        const MemoryConfig config{.unit_bytes = static_cast<std::uint32_t>(kHeapAlign)};
        pool = std::make_unique<MemoryPool<HeapBlock>>(config, make);
    }
    core::Result<MemorySpan> span = pool->allocate(needs.SizeInBytes, needs.Alignment);
    if (!span) return std::unexpected(span.error());
    return Allocation{.span = *span, .pool = kind};
}

void D3d12Device::free(const Allocation& allocation) noexcept {
    if (!allocation.span.valid()) return;
    const std::scoped_lock lock(memory_mutex_);
    const auto& pool = pools_.at(std::to_underlying(allocation.pool));
    if (pool) pool->free(allocation.span);
}

ComPtr<ID3D12Heap> D3d12Device::heap_of(const Allocation& allocation) {
    const std::scoped_lock lock(memory_mutex_);
    return pools_.at(std::to_underlying(allocation.pool))->block(allocation.span).heap;
}

template <class T, class Tag>
void D3d12Device::retire_of(Slots<T, Tag>& table, Handle<Tag> handle) {
    std::optional<T> value = table.remove(handle);
    if (!value) return;
    retire([this, held = std::move(*value)] mutable { discard(held); });
}

void D3d12Device::discard(Buffer& buffer) noexcept {
    if (buffer.mapped != nullptr && buffer.resource != nullptr) buffer.resource->Unmap(0, nullptr);
    buffer.mapped = nullptr;
    buffer.resource.Reset();
    free(buffer.memory);
    buffer = {};
}

void D3d12Device::discard(Texture& texture) noexcept {
    texture.resource.Reset();
    if (texture.is_owned) free(texture.memory);
    texture = {};
}

void D3d12Device::discard(View& view) noexcept {
    if (view.srv != kNoDescriptor) free_staging(view.srv);
    if (view.uav != kNoDescriptor) free_staging(view.uav);
    if (view.rtv != kNoDescriptor) free_rtv(view.rtv);
    if (view.dsv != kNoDescriptor) free_dsv(view.dsv);
    if (view.dsv_read != kNoDescriptor) free_dsv(view.dsv_read);
    view = {};
}

void D3d12Device::discard(Sampler& sampler) noexcept {
    if (sampler.index != kNoDescriptor) free_sampler_staging(sampler.index);
    sampler = {};
}

// Giữ trong họ discard, không tách static (API-06).
// NOLINTNEXTLINE(readability-convert-member-functions-to-static)
void D3d12Device::discard(Shader& shader) noexcept {
    shader = {};
}

// Giữ trong họ discard, không tách static (API-06).
// NOLINTNEXTLINE(readability-convert-member-functions-to-static)
void D3d12Device::discard(Pipeline& pipeline) noexcept {
    pipeline.state.Reset();
    pipeline = {};
}

void D3d12Device::discard(BindGroup& group) noexcept {
    if (group.resource_at != kNoDescriptor) free_resource(group.resource_at, group.resource_count);
    if (group.sampler_at != kNoDescriptor) free_sampler(group.sampler_at, group.sampler_count);
    group = {};
}

void D3d12Device::discard(QueryPool& pool) noexcept {
    if (pool.mapped != nullptr && pool.readback != nullptr) pool.readback->Unmap(0, nullptr);
    pool.mapped = nullptr;
    pool.readback.Reset();
    pool.heap.Reset();
    free(pool.memory);
    pool = {};
}

void D3d12Device::destroy(BufferHandle handle) {
    retire_of(buffers_, handle);
}
void D3d12Device::destroy(TextureHandle handle) {
    retire_of(textures_, handle);
}
void D3d12Device::destroy(TextureViewHandle handle) {
    retire_of(views_, handle);
}
void D3d12Device::destroy(SamplerHandle handle) {
    retire_of(samplers_, handle);
}
void D3d12Device::destroy(ShaderHandle handle) {
    retire_of(shaders_, handle);
}
void D3d12Device::destroy(PipelineHandle handle) {
    retire_of(pipelines_, handle);
}
void D3d12Device::destroy(BindGroupHandle handle) {
    retire_of(groups_, handle);
}
void D3d12Device::destroy(QueryPoolHandle handle) {
    retire_of(queries_, handle);
}

TextureHandle D3d12Device::adopt(ComPtr<ID3D12Resource> image, const TextureDesc& desc) {
    Texture texture;
    texture.resource = std::move(image);
    texture.desc = desc;
    texture.desc.name = {};
    texture.is_owned = false;
    return textures_.insert(std::move(texture));
}

void D3d12Device::release(TextureHandle handle) {
    std::optional<Texture> texture = textures_.remove(handle);
    if (!texture) return;
    discard(*texture);
}

void D3d12Device::release(TextureViewHandle handle) {
    std::optional<View> view = views_.remove(handle);
    if (!view) return;
    discard(*view);
}

void D3d12Device::collect_retired() {
    const QueueMarks done = finished();
    keep_done(done);
    retired_.collect(done);
}

void D3d12Device::note_presented() {
    Queue& physical = queue_of(QueueType::kGraphics);
    const std::scoped_lock lock(physical.mutex);
    const std::uint64_t value = physical.submitted.load() + 1;
    const HRESULT signaled = physical.queue->Signal(physical.fence.Get(), value);
    if (SUCCEEDED(signaled)) physical.submitted.store(value);
}

} // namespace game::gpu::d3d12
