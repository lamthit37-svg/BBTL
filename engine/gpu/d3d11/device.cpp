// Vòng đời thiết bị D3D11: liệt kê adapter, tạo thiết bị feature level 11, nộp deferred context.
// Tài nguyên ở resources.cpp, pipeline ở programs.cpp, lệnh ở commands.cpp, cửa sổ ở swapchain.cpp.
// Đối chiếu thứ tự adapter và lớp kiểm tra với D3D12. Khác gốc: một hàng immediate cho cả ba
// hàng đợi; mốc hoàn thành là query sự kiện chứ không phải fence.
#include "gpu/d3d11/device.hpp"

#include "gpu/d3d11/entry.hpp"

#include "core/error.hpp"
#include "core/log.hpp"
#include "core/text.hpp"
#include "gpu/check.hpp"
#include "gpu/command.hpp"
#include "gpu/d3d11/commands.hpp"
#include "gpu/d3d11/convert.hpp"
#include "gpu/d3d11/hresult.hpp"
#include "gpu/d3d11/swapchain.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/types.hpp"

#include <basetsd.h>
#include <combaseapi.h>
#include <d3d10.h>
#include <d3d11.h>
#include <d3d11sdklayers.h>
#include <d3dcommon.h>
#include <dxgi.h>
#include <dxgi1_3.h>
#include <dxgi1_4.h>
#include <dxgi1_5.h>
#include <dxgiformat.h>
#include <unknwnbase.h>
#include <winerror.h>
#include <winnt.h>
#include <winuser.h>
#include <wrl/client.h>

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <expected>
#include <iterator>
#include <memory>
#include <mutex>
#include <span>
#include <thread>
#include <utility>
#include <vector>

#if defined(__clang__)
#pragma clang diagnostic ignored "-Wlanguage-extension-token"
#endif

namespace game::gpu::d3d11 {

namespace {

using core::ErrorCode;
using core::fail;
using core::ok;
using Microsoft::WRL::ComPtr;

constexpr std::uint64_t kDiscreteBytes = std::uint64_t{512} << 20U;
constexpr std::array<D3D_FEATURE_LEVEL, 2> kLevels{D3D_FEATURE_LEVEL_11_1, D3D_FEATURE_LEVEL_11_0};

struct Candidate {
    AdapterInfo info{};
    ComPtr<IDXGIAdapter1> adapter;
};

struct Opened {
    ComPtr<ID3D11Device> device;
    ComPtr<ID3D11DeviceContext> context;
    D3D_FEATURE_LEVEL level = D3D_FEATURE_LEVEL_11_0;
};

struct Closed {
    Commands* commands = nullptr;
    ComPtr<ID3D11CommandList> list;
};

enum class Poll : std::uint8_t { kPending, kDone, kLost };

[[nodiscard]] bool is_before(const Candidate& left, const Candidate& right) noexcept {
    if (left.info.is_software != right.info.is_software) return !left.info.is_software;
    if (left.info.is_discrete != right.info.is_discrete) return left.info.is_discrete;
    return left.info.memory_bytes > right.info.memory_bytes;
}

[[nodiscard]] bool supports_11(IDXGIAdapter1& adapter) noexcept {
    ComPtr<ID3D11Device> device;
    ComPtr<ID3D11DeviceContext> context;
    D3D_FEATURE_LEVEL chosen = D3D_FEATURE_LEVEL_11_0;
    const auto* levels = kLevels.data();
    const auto count = static_cast<UINT>(kLevels.size());
    const HRESULT created =
        D3D11CreateDevice(&adapter, D3D_DRIVER_TYPE_UNKNOWN, nullptr, D3D11_CREATE_DEVICE_BGRA_SUPPORT, levels, count,
            D3D11_SDK_VERSION, device.GetAddressOf(), &chosen, context.GetAddressOf());
    if (FAILED(created)) return false;
    return chosen >= D3D_FEATURE_LEVEL_11_0;
}

[[nodiscard]] Candidate describe(IDXGIAdapter1& adapter) {
    DXGI_ADAPTER_DESC1 desc{};
    adapter.GetDesc1(&desc);
    Candidate item;
    item.adapter = &adapter;
    const auto* wide = static_cast<const wchar_t*>(desc.Description);
    item.info.name = core::narrow(wide);
    item.info.backend = Backend::kD3D11;
    item.info.vendor_id = desc.VendorId;
    item.info.device_id = desc.DeviceId;
    item.info.memory_bytes = desc.DedicatedVideoMemory;
    const UINT software = desc.Flags & DXGI_ADAPTER_FLAG_SOFTWARE;
    item.info.is_software = software != 0;
    const bool big = item.info.memory_bytes >= kDiscreteBytes;
    item.info.is_discrete = !item.info.is_software && big;
    item.info.driver = "d3d11";
    return item;
}

void take_adapter(std::vector<Candidate>& out, IDXGIAdapter1& adapter) {
    if (!supports_11(adapter)) return;
    out.push_back(describe(adapter));
}

// Một bước liệt kê. keep tắt khi hết adapter hoặc chạm trần 64.
struct EnumState {
    IDXGIFactory1* factory = nullptr;
    std::vector<Candidate>* out = nullptr;
    UINT index = 0;
    bool keep = true;
};

void enum_step(EnumState& state) {
    if (!state.keep) return;
    if (state.index >= 64) {
        state.keep = false;
        return;
    }
    ComPtr<IDXGIAdapter1> adapter;
    IDXGIFactory1* factory = state.factory;
    const HRESULT listed = factory->EnumAdapters1(state.index, adapter.GetAddressOf());
    ++state.index;
    if (listed == DXGI_ERROR_NOT_FOUND) {
        state.keep = false;
        return;
    }
    if (FAILED(listed)) return;
    take_adapter(*state.out, *adapter.Get());
}

[[nodiscard]] core::Result<std::vector<Candidate>> list_candidates(IDXGIFactory1& factory) {
    std::vector<Candidate> out;
    EnumState state;
    state.factory = &factory;
    state.out = &out;
    while (state.keep) {
        enum_step(state);
    }
    std::ranges::sort(out, is_before);
    return out;
}

[[nodiscard]] core::Result<ComPtr<IDXGIFactory1>> make_factory(bool debug) {
    UINT flags = 0;
    if (debug) flags = DXGI_CREATE_FACTORY_DEBUG;
    ComPtr<IDXGIFactory1> factory;
    HRESULT created = CreateDXGIFactory2(flags, IID_PPV_ARGS(factory.GetAddressOf()));
    if (FAILED(created) && flags != 0) {
        created = CreateDXGIFactory2(0, IID_PPV_ARGS(factory.GetAddressOf()));
    }
    if (FAILED(created)) return failed(created, "không tạo được factory DXGI");
    return factory;
}

[[nodiscard]] core::Result<Candidate> pick(const DeviceDesc& desc, std::vector<Candidate>& all) {
    if (all.empty()) return fail(ErrorCode::kUnsupported, "không adapter feature level 11.0");
    if (!desc.adapter) return std::move(all.front());
    const bool past = *desc.adapter >= all.size();
    if (past) return fail(ErrorCode::kInvalidArgument, "chỉ số adapter vượt biên");
    return std::move(all.at(*desc.adapter));
}

[[nodiscard]] HRESULT create_raw(IDXGIAdapter1& adapter, UINT flags, Opened& opened) {
    ID3D11Device** device = opened.device.GetAddressOf();
    ID3D11DeviceContext** context = opened.context.GetAddressOf();
    const auto kind = D3D_DRIVER_TYPE_UNKNOWN;
    const UINT version = D3D11_SDK_VERSION;
    const auto* levels = kLevels.data();
    const auto count = static_cast<UINT>(kLevels.size());
    return D3D11CreateDevice(&adapter, kind, nullptr, flags, levels, count, version, device, &opened.level, context);
}

[[nodiscard]] core::Result<Opened> open_device(IDXGIAdapter1& adapter, bool validated) {
    const UINT base = D3D11_CREATE_DEVICE_BGRA_SUPPORT;
    UINT flags = base;
    if (validated) flags |= D3D11_CREATE_DEVICE_DEBUG;
    Opened opened;
    HRESULT created = create_raw(adapter, flags, opened);
    if (FAILED(created) && validated) {
        core::warn("D3D11: thiếu lớp kiểm tra, chạy tiếp không có lớp ấy");
        opened = Opened{};
        created = create_raw(adapter, base, opened);
    }
    if (FAILED(created)) return failed(created, "không tạo được thiết bị D3D11");
    if (opened.level < D3D_FEATURE_LEVEL_11_0) {
        return fail(ErrorCode::kUnsupported, "máy không có feature level 11.0");
    }
    return opened;
}

void fill_caps(DeviceCaps& caps) {
    caps.tessellation = true;
    caps.geometry_shader = true;
    caps.wireframe = true;
    caps.independent_blend = true;
    caps.precise_occlusion = true;
    caps.depth_clamp = true;
    caps.max_texture_size = D3D11_REQ_TEXTURE2D_U_OR_V_DIMENSION;
    caps.max_anisotropy = 16;
    const auto graphics = std::to_underlying(QueueType::kGraphics);
    caps.has_queue.at(graphics) = true;
    caps.has_timestamps.at(graphics) = true;
}

void protect_device(ID3D11Device& device) {
    ComPtr<ID3D10Multithread> threads;
    const HRESULT queried = device.QueryInterface(IID_PPV_ARGS(threads.GetAddressOf()));
    if (FAILED(queried)) return;
    threads->SetMultithreadProtected(TRUE);
}

void attach_info(ID3D11Device& device, ComPtr<ID3D11InfoQueue>& info) {
    const HRESULT queried = device.QueryInterface(IID_PPV_ARGS(info.GetAddressOf()));
    if (FAILED(queried)) return;
    info->ClearStoredMessages();
}

[[nodiscard]] bool tearing_ok(IDXGIFactory1& factory) noexcept {
    ComPtr<IDXGIFactory5> fifth;
    const HRESULT queried = factory.QueryInterface(IID_PPV_ARGS(fifth.GetAddressOf()));
    if (FAILED(queried)) return false;
    BOOL allow = FALSE;
    const UINT bytes = sizeof(allow);
    const auto feature = DXGI_FEATURE_PRESENT_ALLOW_TEARING;
    const HRESULT checked = fifth->CheckFeatureSupport(feature, &allow, bytes);
    if (FAILED(checked)) return false;
    return allow == TRUE;
}

void log_stored(ID3D11InfoQueue& info, std::uint64_t index) noexcept {
    try {
        SIZE_T bytes = 0;
        info.GetMessage(index, nullptr, &bytes);
        std::vector<std::byte> storage(bytes);
        // GetMessage ghi vào khối byte. NOLINT vì API nhận con trỏ struct.
        // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
        auto* message = reinterpret_cast<D3D11_MESSAGE*>(storage.data());
        info.GetMessage(index, message, &bytes);
        core::error("D3D11: {}", message->pDescription);
    } catch (...) {
        core::error("D3D11: không đọc được thông điệp lớp kiểm tra");
    }
}

void log_at(ID3D11InfoQueue& info, std::uint64_t& index) noexcept {
    log_stored(info, index);
    ++index;
}

using Ticket = std::atomic<std::uint64_t>;

void log_new(ID3D11InfoQueue& info, Ticket& logged, std::uint64_t count) noexcept {
    std::uint64_t index = logged.load(std::memory_order_relaxed);
    while (index < count) {
        log_at(info, index);
    }
    logged.store(count, std::memory_order_relaxed);
}

[[nodiscard]] FormatSupport add_bit(FormatSupport out, UINT bits, UINT mask, FormatSupport flag) {
    if ((bits & mask) == 0) return out;
    return out | flag;
}

[[nodiscard]] FormatSupport support_of(UINT bits, Format format) {
    FormatSupport out = FormatSupport::kNone;
    out = add_bit(out, bits, D3D11_FORMAT_SUPPORT_SHADER_SAMPLE, FormatSupport::kSampled);
    const bool sampled = has(out, FormatSupport::kSampled);
    const bool integer = is_uint(format) || is_sint(format);
    if (sampled && !integer) out |= FormatSupport::kFiltered;
    out = add_bit(out, bits, D3D11_FORMAT_SUPPORT_RENDER_TARGET, FormatSupport::kColorTarget);
    out = add_bit(out, bits, D3D11_FORMAT_SUPPORT_BLENDABLE, FormatSupport::kBlendable);
    out = add_bit(out, bits, D3D11_FORMAT_SUPPORT_DEPTH_STENCIL, FormatSupport::kDepthTarget);
    const UINT storage = D3D11_FORMAT_SUPPORT_TYPED_UNORDERED_ACCESS_VIEW;
    return add_bit(out, bits, storage, FormatSupport::kStorage);
}

[[nodiscard]] bool cas_release(Ticket& slot, std::uint64_t& seen, std::uint64_t ticket) noexcept {
    const auto release = std::memory_order_release;
    const auto relaxed = std::memory_order_relaxed;
    return slot.compare_exchange_weak(seen, ticket, release, relaxed);
}

void publish_max(Ticket& slot, std::uint64_t ticket) noexcept {
    std::uint64_t seen = slot.load(std::memory_order_relaxed);
    while (seen < ticket && !cas_release(slot, seen, ticket)) {
    }
}

[[nodiscard]] bool is_idle(const std::unique_ptr<Commands>& item) noexcept {
    return item->state() == Commands::State::kIdle;
}

[[nodiscard]] Commands* find_idle(std::vector<std::unique_ptr<Commands>>& pool) noexcept {
    const auto found = std::ranges::find_if(pool, is_idle);
    if (found == pool.end()) return nullptr;
    return found->get();
}

using ClosedList = std::vector<Closed>;
using ReadList = std::vector<PendingReadback>;
using ListSpan = std::span<CommandList* const>;

struct CloseArgs {
    CommandList* list = nullptr;
    ClosedList* out = nullptr;
    ReadList* reads = nullptr;
};

[[nodiscard]] core::Status close_one(CloseArgs args) {
    auto* const commands = dynamic_cast<Commands*>(args.list);
    if (commands == nullptr) return fail(ErrorCode::kInvalidArgument, "submit: danh sách lệnh lạ");
    if (commands->state() != Commands::State::kRecording) {
        return fail(ErrorCode::kInvalidState, "submit: danh sách không đang ghi");
    }
    const core::Status earlier = commands->error();
    if (!earlier) return earlier;
    Closed closed;
    closed.commands = commands;
    const core::Status done = commands->close(closed.list);
    if (!done) commands->mark_idle();
    if (!done) return done;
    ReadList taken = commands->take_readbacks();
    const auto begin = std::make_move_iterator(taken.begin());
    const auto end = std::make_move_iterator(taken.end());
    args.reads->insert(args.reads->end(), begin, end);
    args.out->push_back(std::move(closed));
    return ok();
}

[[nodiscard]] core::Status close_keep(core::Status status, CloseArgs args) {
    if (!status) return status;
    return close_one(args);
}

struct CloseBatch {
    core::Status* status = nullptr;
    CommandList* list = nullptr;
    ClosedList* out = nullptr;
    ReadList* reads = nullptr;
};

void close_step(const CloseBatch& batch) {
    CloseArgs args;
    args.list = batch.list;
    args.out = batch.out;
    args.reads = batch.reads;
    *batch.status = close_keep(*batch.status, args);
}

void close_next(CloseBatch& batch, CommandList* list) {
    batch.list = list;
    close_step(batch);
}

[[nodiscard]] bool already_closed(const ClosedList& out, const CommandList* list) noexcept {
    for (const Closed& item : out) {
        if (item.commands == list) return true;
    }
    return false;
}

[[nodiscard]] core::Status close_all(ListSpan lists, ClosedList& out, ReadList& reads) {
    core::Status status = ok();
    CloseBatch batch;
    batch.status = &status;
    batch.out = &out;
    batch.reads = &reads;
    for (CommandList* list : lists) {
        if (!status) continue;
        if (already_closed(out, list)) status = fail(ErrorCode::kInvalidArgument, "submit: cùng một list hai lần");
        if (!status) continue;
        close_next(batch, list);
    }
    return status;
}

void release_closed(const std::vector<Closed>& closed) {
    for (const Closed& item : closed) {
        item.commands->mark_idle();
    }
}

using ContextRef = ID3D11DeviceContext&;

void execute_one(ContextRef context, Closed& item) {
    ID3D11CommandList* list = item.list.Get();
    context.ExecuteCommandList(list, FALSE);
    item.list.Reset();
    item.commands->mark_pending();
}

void execute_next(ContextRef context, Closed& item) {
    execute_one(context, item);
}

void execute_all(ContextRef context, std::span<Closed> closed) {
    for (Closed& item : closed) {
        execute_next(context, item);
    }
}

[[nodiscard]] core::Status make_event(ID3D11Device& device, ComPtr<ID3D11Query>& query) {
    D3D11_QUERY_DESC desc{};
    desc.Query = D3D11_QUERY_EVENT;
    const HRESULT created = device.CreateQuery(&desc, query.GetAddressOf());
    if (FAILED(created)) return failed(created, "không tạo được query sự kiện");
    return ok();
}

[[nodiscard]] core::Status wait_one(core::Status status, const SubmitWait& wait) {
    if (!status) return status;
    if (wait.timeline == nullptr) return fail(ErrorCode::kInvalidArgument, "timeline chờ rỗng");
    const auto forever = std::chrono::nanoseconds::max();
    return wait.timeline->wait(wait.value, forever);
}

[[nodiscard]] core::Status wait_all(std::span<const SubmitWait> waits) {
    core::Status status = ok();
    for (const SubmitWait& wait : waits) {
        status = wait_one(status, wait);
    }
    return status;
}

void note_signal(std::vector<TimelineNote>& out, const SubmitSignal& signal) {
    if (signal.timeline == nullptr) return;
    TimelineNote note;
    note.timeline = signal.timeline;
    note.value = signal.value;
    out.push_back(note);
}

void note_signals(std::vector<TimelineNote>& out, std::span<const SubmitSignal> signals) {
    for (const SubmitSignal& signal : signals) {
        note_signal(out, signal);
    }
}

[[nodiscard]] Poll poll_event(ID3D11DeviceContext& context, const GpuWait& wait) {
    if (wait.event == nullptr) return Poll::kDone;
    const HRESULT data = context.GetData(wait.event.Get(), nullptr, 0, 0);
    if (data == S_FALSE) return Poll::kPending;
    if (FAILED(data)) return Poll::kLost;
    return Poll::kDone;
}

void mark_idle_one(Commands* commands) {
    if (commands == nullptr) return;
    commands->mark_idle();
}

void mark_lists(std::span<Commands*> lists) {
    for (Commands* commands : lists) {
        mark_idle_one(commands);
    }
}

void publish_signal(const TimelineNote& note) {
    if (note.timeline == nullptr) return;
    auto* const typed = dynamic_cast<Timeline11*>(note.timeline);
    if (typed == nullptr) core::error("D3D11: timeline tín hiệu lạ");
    if (typed == nullptr) return;
    typed->publish(note.value);
}

void publish_signals(std::span<const TimelineNote> notes) {
    for (const TimelineNote& note : notes) {
        publish_signal(note);
    }
}

[[nodiscard]] DXGI_FORMAT texture_format(ID3D11Resource& resource) {
    ComPtr<ID3D11Texture2D> texture;
    const HRESULT queried = resource.QueryInterface(IID_PPV_ARGS(texture.GetAddressOf()));
    if (FAILED(queried)) return DXGI_FORMAT_UNKNOWN;
    D3D11_TEXTURE2D_DESC desc{};
    texture->GetDesc(&desc);
    return desc.Format;
}

struct RowPlace {
    std::byte* dest = nullptr;
    const std::byte* source = nullptr;
    std::uint32_t row = 0;
    std::uint32_t pitch = 0;
    std::uint32_t row_bytes = 0;
    std::uint32_t tight = 0;
};

void place_row(const RowPlace& row) {
    const std::uint32_t amount = std::min(row.tight, row.pitch);
    const auto row_index = static_cast<std::size_t>(row.row);
    const auto dest_row = row_index * row.row_bytes;
    const auto source_row = row_index * row.pitch;
    const auto count = static_cast<std::size_t>(amount);
    const std::span<std::byte> dest(row.dest, dest_row + count);
    const std::span<const std::byte> source(row.source, source_row + count);
    const std::span<std::byte> dest_tail = dest.subspan(dest_row);
    const std::span<const std::byte> source_tail = source.subspan(source_row);
    std::byte* const dest_bytes = dest_tail.data();
    const std::byte* const source_bytes = source_tail.data();
    std::memcpy(dest_bytes, source_bytes, count);
}

struct LayerSnap {
    std::vector<std::byte> bytes;
    std::uint32_t pitch = 0;
    bool ok = false;
};

struct SnapArgs {
    ID3D11DeviceContext* context = nullptr;
    ID3D11Resource* staging = nullptr;
    std::uint32_t layer = 0;
    std::uint32_t rows = 0;
    LayerSnap* out = nullptr;
};

// Không Map buffer đích cùng lúc.
void snap_layer(const SnapArgs& args) {
    D3D11_MAPPED_SUBRESOURCE mapped{};
    const UINT sub = D3D11CalcSubresource(0, args.layer, 1);
    ID3D11DeviceContext* context = args.context;
    const HRESULT mapped_ok = context->Map(args.staging, sub, D3D11_MAP_READ, 0, &mapped);
    if (FAILED(mapped_ok)) return;
    args.out->pitch = static_cast<std::uint32_t>(mapped.RowPitch);
    const auto bytes = static_cast<std::uint64_t>(args.rows) * args.out->pitch;
    args.out->bytes.resize(static_cast<std::size_t>(bytes));
    const auto* source = static_cast<const std::byte*>(mapped.pData);
    std::memcpy(args.out->bytes.data(), source, args.out->bytes.size());
    context->Unmap(args.staging, sub);
    args.out->ok = true;
}

[[nodiscard]] std::uint32_t tight_row(Format format, std::uint32_t width) noexcept {
    const FormatInfo facts = info(format);
    const std::uint32_t block = std::max<std::uint32_t>(facts.block_width, 1U);
    const std::uint32_t blocks = std::max(width / block, 1U);
    return blocks * facts.block_bytes;
}

struct LayArgs {
    const LayerSnap* snap = nullptr;
    std::byte* dest = nullptr;
    std::uint32_t rows = 0;
    std::uint32_t row_bytes = 0;
    std::uint32_t tight = 0;
    std::uint32_t row = 0;
};

void lay_row(LayArgs& args) {
    RowPlace place;
    place.dest = args.dest;
    place.source = args.snap->bytes.data();
    place.row = args.row;
    place.pitch = args.snap->pitch;
    place.row_bytes = args.row_bytes;
    place.tight = args.tight;
    place_row(place);
    ++args.row;
}

void lay_rows(LayArgs& args) {
    args.row = 0;
    while (args.row < args.rows) {
        lay_row(args);
    }
}

struct PackState {
    ID3D11DeviceContext* context = nullptr;
    ID3D11Resource* staging = nullptr;
    CopyRegion region{};
    Format format = Format::kUnknown;
    std::vector<std::byte>* laid = nullptr;
    std::uint32_t layer = 0;
    bool failed = false;
};

void pack_layer(PackState& state) {
    if (state.failed) return;
    const std::uint32_t depth = std::max(state.region.depth, 1U);
    const std::uint32_t rows = state.region.rows * depth;
    LayerSnap snap;
    SnapArgs snap_args;
    snap_args.context = state.context;
    snap_args.staging = state.staging;
    snap_args.layer = state.layer;
    snap_args.rows = rows;
    snap_args.out = &snap;
    snap_layer(snap_args);
    if (!snap.ok) state.failed = true;
    if (!snap.ok) return;
    const std::uint64_t layer_bytes = static_cast<std::uint64_t>(state.region.row_bytes) * rows;
    const auto layer_index = static_cast<std::size_t>(state.layer);
    const auto layer_span = static_cast<std::size_t>(layer_bytes);
    const std::size_t byte_at = layer_index * layer_span;
    const std::span<std::byte> laid(*state.laid);
    const bool wrapped = layer_span != 0 && byte_at / layer_span != layer_index;
    const std::size_t end_at = byte_at + layer_span;
    const bool past = wrapped || end_at < byte_at || end_at > laid.size();
    if (past) state.failed = true;
    if (past) return;
    const std::span<std::byte> tail = laid.subspan(byte_at);
    LayArgs lay;
    lay.snap = &snap;
    lay.dest = tail.data();
    lay.rows = rows;
    lay.row_bytes = state.region.row_bytes;
    lay.tight = tight_row(state.format, state.region.width);
    lay_rows(lay);
    ++state.layer;
}

void pack_readback(PackState& state) {
    const std::uint32_t depth = std::max(state.region.depth, 1U);
    const std::uint32_t rows = state.region.rows * depth;
    const auto layers = static_cast<std::uint64_t>(state.region.layer_count);
    const auto layer_bytes = static_cast<std::uint64_t>(state.region.row_bytes) * rows;
    const auto bytes = layers * layer_bytes;
    state.laid->assign(static_cast<std::size_t>(bytes), std::byte{});
    while (state.layer < state.region.layer_count && !state.failed) {
        pack_layer(state);
    }
}

struct WritePacked {
    ID3D11DeviceContext* context = nullptr;
    Buffer* buffer = nullptr;
    const CopyRegion* region = nullptr;
    const std::vector<std::byte>* laid = nullptr;
};

void write_packed(const WritePacked& write) {
    const auto offset = static_cast<std::size_t>(write.region->buffer_offset);
    const bool in_range = offset <= write.buffer->size;
    const bool fits = in_range && write.laid->size() <= write.buffer->size - offset;
    if (!fits) return;
    D3D11_MAPPED_SUBRESOURCE mapped{};
    ID3D11Buffer* resource = write.buffer->resource.Get();
    ID3D11DeviceContext* context = write.context;
    const HRESULT opened = context->Map(resource, 0, D3D11_MAP_READ_WRITE, 0, &mapped);
    if (FAILED(opened)) core::error("D3D11: không map được buffer readback");
    if (FAILED(opened)) return;
    auto* const dest = static_cast<std::byte*>(mapped.pData);
    const std::size_t bytes = write.laid->size();
    const auto mapped_size = static_cast<std::size_t>(write.buffer->size);
    const std::span<std::byte> mapped_bytes(dest, mapped_size);
    const std::span<std::byte> slot = mapped_bytes.subspan(offset, bytes);
    std::byte* const slot_data = slot.data();
    const std::byte* const source = write.laid->data();
    std::memcpy(slot_data, source, bytes);
    context->Unmap(resource, 0);
}

void read_one(D3d11Device& device, ID3D11DeviceContext& context, const PendingReadback& item) {
    Buffer* buffer = device.find(item.target);
    if (buffer == nullptr || item.staging == nullptr) return;
    ID3D11Resource* staging = item.staging.Get();
    PackState state;
    state.context = &context;
    state.staging = staging;
    state.region = item.region;
    state.format = from_dxgi(texture_format(*staging));
    std::vector<std::byte> laid;
    state.laid = &laid;
    pack_readback(state);
    if (state.failed) core::error("D3D11: không đọc được ảnh staging của readback");
    if (state.failed) return;
    WritePacked write;
    write.context = &context;
    write.buffer = buffer;
    write.region = &item.region;
    write.laid = &laid;
    write_packed(write);
}

using ReadSpan = std::span<const PendingReadback>;

void read_all(D3d11Device& device, ID3D11DeviceContext& context, ReadSpan items) {
    for (const PendingReadback& item : items) {
        read_one(device, context, item);
    }
}

struct WaitClock {
    const D3d11Device* device = nullptr;
    std::uint64_t ticket = 0;
    std::chrono::steady_clock::time_point start;
    std::chrono::nanoseconds timeout{};
    core::Status* error = nullptr;
};

[[nodiscard]] bool still_before(const WaitClock& clock) {
    const D3d11Device& device = *clock.device;
    if (device.completed_fence() >= clock.ticket) return false;
    if (device.loss() != DeviceLoss::kNone) {
        *clock.error = fail(ErrorCode::kDeviceLost, "thiết bị mất khi đang chờ");
        return false;
    }
    const bool bounded = clock.timeout != std::chrono::nanoseconds::max();
    const auto elapsed = std::chrono::steady_clock::now() - clock.start;
    const bool late = elapsed >= clock.timeout;
    if (bounded && late) *clock.error = fail(ErrorCode::kTimeout, "hết giờ chờ GPU");
    return !(bounded && late);
}

// Vài trăm lần nhường luồng trước khi ngủ. Ngủ 1 ms mỗi vòng thăm dò biến một lần chờ ngắn thành ~3 ms.
struct WaitBackoff {
    static constexpr int kSpinPolls = 200;
    int spins_ = 0;
    HANDLE timer_ = nullptr;

    WaitBackoff() = default;
    ~WaitBackoff();
    WaitBackoff(const WaitBackoff&) = delete;
    WaitBackoff& operator=(const WaitBackoff&) = delete;

    void pause();
    void pause_long();
};

void poll_once(D3d11Device& device, const WaitClock& clock, WaitBackoff& backoff) {
    device.pump();
    if (!still_before(clock)) return;
    backoff.pause();
}

[[nodiscard]] Result<CommandList*> reopen(Commands& commands) {
    const core::Status opened = commands.open();
    if (!opened) return std::unexpected(opened.error());
    return &commands;
}

using FactoryResult = core::Result<ComPtr<IDXGIFactory1>>;
using CandidateList = core::Result<std::vector<Candidate>>;

[[nodiscard]] CandidateList candidates_of(const FactoryResult& factory) {
    IDXGIFactory1* const raw = factory->Get();
    if (raw == nullptr) return fail(ErrorCode::kInternal, "factory DXGI rỗng");
    return list_candidates(*raw);
}

WaitBackoff::~WaitBackoff() {
    if (timer_ != nullptr) CloseHandle(timer_);
}

void WaitBackoff::pause() {
    if (spins_ < kSpinPolls) {
        ++spins_;
        std::this_thread::yield();
        return;
    }
    pause_long();
}

void WaitBackoff::pause_long() {
    if (timer_ == nullptr) {
        timer_ = CreateWaitableTimerExW(nullptr, nullptr, CREATE_WAITABLE_TIMER_HIGH_RESOLUTION,
            TIMER_MODIFY_STATE | SYNCHRONIZE);
    }
    if (timer_ == nullptr) {
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
        return;
    }
    LARGE_INTEGER due{};
    due.QuadPart = -2000;
    const BOOL armed = SetWaitableTimer(timer_, &due, 0, nullptr, nullptr, FALSE);
    if (armed == FALSE) {
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
        return;
    }
    std::ignore = WaitForSingleObject(timer_, INFINITE);
}

} // namespace

ImmediateGuard::ImmediateGuard(std::mutex& mutex, ID3D11DeviceContext& context) : lock_(mutex), context_(&context) {}

ImmediateGuard::ImmediateGuard(ImmediateGuard&& other) noexcept
    : lock_(std::move(other.lock_)), context_(other.context_) {}

ImmediateGuard::~ImmediateGuard() = default;

Result<std::vector<AdapterInfo>> adapters() {
    const core::Result<ComPtr<IDXGIFactory1>> factory = make_factory(false);
    if (!factory) return std::unexpected(factory.error());
    const core::Result<std::vector<Candidate>> listed = candidates_of(factory);
    if (!listed) return std::unexpected(listed.error());
    std::vector<AdapterInfo> infos;
    infos.reserve(listed->size());
    for (const Candidate& item : *listed) {
        infos.push_back(item.info);
    }
    return infos;
}

Result<std::unique_ptr<Device>> create(const DeviceDesc& desc) {
    return D3d11Device::open(desc);
}

Result<std::unique_ptr<Device>> D3d11Device::open(const DeviceDesc& desc) {
    const core::Result<ComPtr<IDXGIFactory1>> factory = make_factory(desc.is_validated);
    if (!factory) return std::unexpected(factory.error());
    const core::Result<std::vector<Candidate>> listed = candidates_of(factory);
    if (!listed) return std::unexpected(listed.error());
    std::vector<Candidate> all = *listed;
    const core::Result<Candidate> chosen = pick(desc, all);
    if (!chosen) return std::unexpected(chosen.error());
    const core::Result<Opened> opened = open_device(*chosen->adapter.Get(), desc.is_validated);
    if (!opened) return std::unexpected(opened.error());
    auto device = std::make_unique<D3d11Device>();
    device->device_ = opened->device;
    device->immediate_ = opened->context;
    device->adapter_dxgi_ = chosen->adapter;
    device->adapter_ = chosen->info;
    if (opened->level >= D3D_FEATURE_LEVEL_11_1) device->adapter_.driver = "d3d11 11.1";
    fill_caps(device->caps_);
    ID3D11Device* hardware = device->device_.Get();
    if (hardware == nullptr) return core::fail(core::ErrorCode::kInternal, "thiết bị D3D11 rỗng");
    protect_device(*hardware);
    attach_info(*hardware, device->info_);
    IDXGIFactory1* raw_factory = factory->Get();
    const bool tearing = raw_factory != nullptr && tearing_ok(*raw_factory);
    device->allows_tearing_ = tearing;
    return device;
}

// Ném thì terminate (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
D3d11Device::~D3d11Device() {
    const bool alive = immediate_ != nullptr && loss_.load() == DeviceLoss::kNone;
    if (!alive) return;
    const core::Status waited = wait_idle();
    if (!waited) core::error("D3D11: không chờ xong khi huỷ thiết bị");
}

FormatSupport D3d11Device::format_support(Format format) const {
    const DXGI_FORMAT native = to_dxgi(format);
    if (native == DXGI_FORMAT_UNKNOWN) return FormatSupport::kNone;
    UINT bits = 0;
    const HRESULT checked = device_->CheckFormatSupport(native, &bits);
    if (FAILED(checked)) return FormatSupport::kNone;
    return support_of(bits, format);
}

MemoryBudget D3d11Device::memory_budget() const {
    MemoryBudget budget;
    ComPtr<IDXGIAdapter3> adapter;
    const HRESULT queried = adapter_dxgi_->QueryInterface(IID_PPV_ARGS(adapter.GetAddressOf()));
    if (FAILED(queried)) return budget;
    DXGI_QUERY_VIDEO_MEMORY_INFO info{};
    const HRESULT read = adapter->QueryVideoMemoryInfo(0, DXGI_MEMORY_SEGMENT_GROUP_LOCAL, &info);
    if (FAILED(read)) return budget;
    budget.used_bytes = info.CurrentUsage;
    budget.budget_bytes = info.Budget;
    return budget;
}

std::uint64_t D3d11Device::validation_errors() const noexcept {
    if (info_ == nullptr) return 0;
    const UINT64 count = info_->GetNumStoredMessages();
    log_new(*info_.Get(), logged_, count);
    return count;
}

std::uint64_t D3d11Device::address(BufferHandle handle) const {
    static_cast<void>(handle);
    return 0;
}

std::vector<std::byte> D3d11Device::pipeline_cache() const {
    return {};
}

ImmediateGuard D3d11Device::lock_immediate() {
    ID3D11DeviceContext* const context = immediate_.Get();
    return {immediate_mutex_, *context};
}

std::uint64_t D3d11Device::next_fence() noexcept {
    const std::uint64_t previous = submitted_.fetch_add(1, std::memory_order_acq_rel);
    return previous + 1;
}

void D3d11Device::retire(ComPtr<IUnknown> object) {
    if (object == nullptr) return;
    // GPU đã chạy xong mọi lần nộp thì không còn lệnh nào giữ đối tượng. Thả ngay.
    if (submitted_.load(std::memory_order_acquire) <= completed_fence()) return;
    Retired retired;
    retired.done_at = submitted_.load(std::memory_order_acquire);
    retired.object = std::move(object);
    const std::scoped_lock lock(retire_mutex_);
    retired_.push_back(std::move(retired));
}

void D3d11Device::note_loss(HRESULT code) noexcept {
    const DeviceLoss kind = loss_of(code);
    if (kind == DeviceLoss::kNone) return;
    DeviceLoss seen = DeviceLoss::kNone;
    while (!loss_.compare_exchange_weak(seen, kind) && seen == DeviceLoss::kNone) {
    }
}

void D3d11Device::enqueue(GpuWait& wait) {
    waits_.push_back(std::move(wait));
}

void D3d11Device::reclaim(std::uint64_t done) {
    const std::scoped_lock lock(retire_mutex_);
    const auto stale = [done](const Retired& item) { return item.done_at <= done; };
    std::erase_if(retired_, stale);
}

void D3d11Device::finish_wait(ID3D11DeviceContext& context, GpuWait& wait) {
    publish_max(completed_, wait.ticket);
    mark_lists(wait.lists);
    publish_signals(wait.signals);
    read_all(*this, context, wait.readbacks);
    reclaim(wait.ticket);
}

std::size_t D3d11Device::consume_at(ID3D11DeviceContext& context, std::size_t index) {
    const Poll poll = poll_event(context, waits_.at(index));
    if (poll == Poll::kPending) return index + 1;
    if (poll == Poll::kLost) note_loss(device_->GetDeviceRemovedReason());
    finish_wait(context, waits_.at(index));
    const auto where = waits_.begin() + static_cast<std::ptrdiff_t>(index);
    waits_.erase(where);
    return index;
}

void D3d11Device::pump_locked(ID3D11DeviceContext& context) {
    if (flush_pending_) {
        context.Flush();
        flush_pending_ = false;
    }
    std::size_t index = 0;
    while (index < waits_.size()) {
        index = consume_at(context, index);
    }
}

void D3d11Device::pump() {
    if (immediate_ == nullptr) return;
    ImmediateGuard guard = lock_immediate();
    pump_locked(guard.context());
}

Status D3d11Device::wait_until(std::uint64_t ticket, std::chrono::nanoseconds timeout) {
    core::Status error = ok();
    WaitClock clock;
    clock.device = this;
    clock.ticket = ticket;
    clock.start = std::chrono::steady_clock::now();
    clock.timeout = timeout;
    clock.error = &error;
    WaitBackoff backoff;
    while (still_before(clock)) {
        poll_once(*this, clock, backoff);
    }
    return error;
}

Status D3d11Device::wait_idle() {
    const std::uint64_t ticket = submitted_.load(std::memory_order_acquire);
    return wait_until(ticket, std::chrono::nanoseconds::max());
}

Status D3d11Device::end_frame() {
    pump();
    reclaim(completed_fence());
    if (loss() != DeviceLoss::kNone) return fail(ErrorCode::kDeviceLost, "thiết bị mất");
    return ok();
}

// Giữ thành viên, chữ ký ở header.
// NOLINTNEXTLINE(readability-convert-member-functions-to-static)
Status D3d11Device::flush_locked(ID3D11DeviceContext& device_context) {
    device_context.Flush();
    return ok();
}

Result<CommandList*> D3d11Device::begin_commands(QueueType queue) {
    if (loss_.load() != DeviceLoss::kNone) return fail(ErrorCode::kDeviceLost, "thiết bị đã mất");
    const std::scoped_lock lock(pool_mutex_);
    Commands* idle = find_idle(pool_);
    if (idle != nullptr) return reopen(*idle);
    ComPtr<ID3D11DeviceContext> deferred;
    const HRESULT created = device_->CreateDeferredContext(0, deferred.GetAddressOf());
    if (FAILED(created)) return failed(created, "không tạo được deferred context");
    auto made = std::make_unique<Commands>(*this, queue, deferred);
    return adopt_list(made);
}

Result<CommandList*> D3d11Device::adopt_list(std::unique_ptr<Commands>& made) {
    const core::Status opened = made->open();
    if (!opened) return std::unexpected(opened.error());
    Commands* raw = made.get();
    pool_.push_back(std::move(made));
    return raw;
}

Status D3d11Device::submit(QueueType queue, const SubmitDesc& desc) {
    static_cast<void>(queue);
    if (loss_.load() != DeviceLoss::kNone) return fail(ErrorCode::kDeviceLost, "thiết bị đã mất");
    std::vector<Closed> closed;
    std::vector<PendingReadback> reads;
    const core::Status recorded = close_all(desc.lists, closed, reads);
    if (!recorded) release_closed(closed);
    if (!recorded) return recorded;
    const core::Status waited = wait_all(desc.waits);
    if (!waited) release_closed(closed);
    if (!waited) return waited;
    ImmediateGuard guard = lock_immediate();
    ComPtr<ID3D11Query> event;
    ID3D11Device* hardware = device_.Get();
    if (hardware == nullptr) return core::fail(core::ErrorCode::kInternal, "thiết bị D3D11 rỗng");
    const core::Status armed = make_event(*hardware, event);
    if (!armed) release_closed(closed);
    if (!armed) return armed;
    ID3D11DeviceContext& context = guard.context();
    execute_all(context, closed);
    ID3D11Query* query = event.Get();
    context.End(query);
    GpuWait wait;
    wait.ticket = next_fence();
    wait.event = std::move(event);
    wait.readbacks = std::move(reads);
    note_signals(wait.signals, desc.signals);
    for (const Closed& item : closed) {
        wait.lists.push_back(item.commands);
    }
    enqueue(wait);
    flush_pending_ = true;
    return ok();
}

} // namespace game::gpu::d3d11
