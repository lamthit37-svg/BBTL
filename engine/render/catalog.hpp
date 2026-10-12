// Catalog pipeline: mỗi PSO một nhóm và một tầng. Nhóm là chỗ quản lý, tầng là lúc prepare.
// Forward, UiPass và FxView mượn handle; catalog huỷ chúng. prepare tạo mục của tầng chưa có.
// Model hỏng thì prepare trả lỗi. Giao diện và hiệu ứng hỏng thì handle rỗng, lỗi nằm ở fault.
// Đường vẽ không tạo PSO. Nhà và địa hình đang vẽ bằng họ model của nhóm Character.
#pragma once

#include "core/error.hpp"
#include "gpu/device.hpp"
#include "gpu/handle.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>

namespace game::render {

// Nhóm quản lý. Một nhóm giữ nhiều PSO; một PSO chỉ thuộc một nhóm.
// Core: fallback, lúc mở client. Ui: HUD, chữ, icon, menu, cùng lúc đó.
// Character: skin, thân, áo, tóc, vũ khí, trước khi vào thế giới.
// World: địa hình, nước, nhà, cây, theo map. Light: bóng và lượt sáng, theo cấu hình.
// Vfx: lửa, khói, phép, hạt, vệt, theo kỹ năng hoặc khu vực.
// Post: bloom, tone map, AA, lúc tạo renderer.
// Compute: skin compute, culling, hạt, tiện ích GPU, theo tính năng đang dùng.
enum class Group : std::uint8_t {
    kCore,
    kUi,
    kCharacter,
    kWorld,
    kLight,
    kVfx,
    kPost,
    kCompute,
};

// Cấp tải, độc lập với nhóm. Một nhóm có PSO ở nhiều tầng.
// kBootstrap: tầng 0, bắt buộc lúc mở client (fallback, UI nạp, texture cơ bản, pipeline báo lỗi).
// kEssential: tầng 1, prewarm trước khi vào game (nhân vật, địa hình cơ bản, trang bị, sáng, bóng).
// kScene: tầng 2, prefetch trước khi map, boss, kỹ năng, nước, thời tiết hoặc vật hiếm xuất hiện.
// kOptional: tầng 3, chỉ khi GPU và cấu hình hỗ trợ (ray tracing, mesh shader, cinematic).
enum class Tier : std::uint8_t { kBootstrap, kEssential, kScene, kOptional };

// Tầng 3 chỉ khi GPU phần cứng có mesh shader hoặc ray query. Chưa có mục thì prepare không tạo gì.
[[nodiscard]] constexpr bool optional_tier_allowed(const gpu::AdapterInfo& adapter,
    const gpu::DeviceCaps& caps) noexcept {
    if (adapter.is_software) return false;
    return caps.mesh_shader || caps.ray_query;
}

// Sáu PSO đang có. Bốn ô model trùng bit chất liệu: bit 0 hai mặt, bit 1 trộn alpha.
enum class Pso : std::uint8_t {
    kModelOpaque = 0,
    kModelTwoSided = 1,
    kModelBlend = 2,
    kModelBlendTwoSided = 3,
    kUi = 4,
    kFx = 5,
};

inline constexpr std::uint32_t kModelTwoSided = 1;
inline constexpr std::uint32_t kModelBlended = 2;
// Cỡ khối hằng của model.hlsli. forward.cpp static_assert sizeof khối C++ bằng hai số này.
inline constexpr std::uint32_t kModelFrameBytes = 1280;
inline constexpr std::uint32_t kModelDrawBytes = gpu::kMaxPushBytes;
inline constexpr std::size_t kModelVariants = 4;
inline constexpr std::size_t kSlotCount = 6;

// Bố cục đỉnh hạt. fx_view giữ struct cùng các số này; catalog dựng pipeline theo chúng.
inline constexpr std::uint32_t kFxStride = 36;
inline constexpr std::uint32_t kFxUv = 12;
inline constexpr std::uint32_t kFxColour = 20;

// Mọi gói .f2s catalog có thể nạp. Hash cache đĩa đi theo danh sách này, mỗi tên một lần.
inline constexpr std::array<std::string_view, kSlotCount> kPackageNames{
    "model.vs", "model.ps", "ui.vs", "ui.ps", "fx.vs", "fx.ps"};

// Một dòng của bảng. is_required: thiếu PSO ấy thì prepare của tầng trả lỗi.
// frame_bytes và draw_bytes là cỡ khối hằng mà mã ghi. 0 nghĩa là không kiểm khối đó.
// Mọi dòng cùng vertex dùng một lần nạp, nên phải cùng pixel và cùng hai cỡ.
struct Entry {
    std::string_view name;
    Group group = Group::kWorld;
    Tier tier = Tier::kBootstrap;
    Pso pso = Pso::kModelOpaque;
    std::string_view vertex;
    std::string_view pixel;
    bool is_required = false;
    std::uint32_t frame_bytes = 0;
    std::uint32_t draw_bytes = 0;
};

// Bảng tĩnh. Thêm shader là thêm một dòng. prepare đi theo bảng, không theo tên viết cứng.
inline constexpr std::array<Entry, kSlotCount> kEntries{{
    {.name = "render.model.opaque",
        .group = Group::kCharacter,
        .tier = Tier::kEssential,
        .pso = Pso::kModelOpaque,
        .vertex = "model.vs",
        .pixel = "model.ps",
        .is_required = true,
        .frame_bytes = kModelFrameBytes,
        .draw_bytes = kModelDrawBytes},
    {.name = "render.model.two_sided",
        .group = Group::kCharacter,
        .tier = Tier::kEssential,
        .pso = Pso::kModelTwoSided,
        .vertex = "model.vs",
        .pixel = "model.ps",
        .is_required = true,
        .frame_bytes = kModelFrameBytes,
        .draw_bytes = kModelDrawBytes},
    {.name = "render.model.blend",
        .group = Group::kCharacter,
        .tier = Tier::kEssential,
        .pso = Pso::kModelBlend,
        .vertex = "model.vs",
        .pixel = "model.ps",
        .is_required = true,
        .frame_bytes = kModelFrameBytes,
        .draw_bytes = kModelDrawBytes},
    {.name = "render.model.blend_two_sided",
        .group = Group::kCharacter,
        .tier = Tier::kEssential,
        .pso = Pso::kModelBlendTwoSided,
        .vertex = "model.vs",
        .pixel = "model.ps",
        .is_required = true,
        .frame_bytes = kModelFrameBytes,
        .draw_bytes = kModelDrawBytes},
    {.name = "render.ui",
        .group = Group::kUi,
        .tier = Tier::kBootstrap,
        .pso = Pso::kUi,
        .vertex = "ui.vs",
        .pixel = "ui.ps",
        .is_required = false},
    {.name = "render.fx",
        .group = Group::kVfx,
        .tier = Tier::kScene,
        .pso = Pso::kFx,
        .vertex = "fx.vs",
        .pixel = "fx.ps",
        .is_required = false},
}};

static_assert(std::to_underlying(Pso::kModelTwoSided) == kModelTwoSided);
static_assert(std::to_underlying(Pso::kModelBlend) == kModelBlended);
static_assert(std::to_underlying(Pso::kModelBlendTwoSided) == (kModelTwoSided | kModelBlended));

// Cùng tên vertex là một lần nạp. Lệch pixel hoặc cỡ khối thì gói sau bị kiểm bằng cỡ của dòng đầu.
[[nodiscard]] constexpr bool same_family(const Entry& left, const Entry& right) noexcept {
    if (left.vertex != right.vertex) return true;
    const bool same_pixel = left.pixel == right.pixel;
    const bool same_frame = left.frame_bytes == right.frame_bytes;
    const bool same_draw = left.draw_bytes == right.draw_bytes;
    return same_pixel && same_frame && same_draw;
}

[[nodiscard]] constexpr bool row_family_agrees(const Entry& left) noexcept {
    for (const Entry& right : kEntries) {
        if (!same_family(left, right)) return false;
    }
    return true;
}

[[nodiscard]] constexpr bool families_agree() noexcept {
    for (const Entry& left : kEntries) {
        if (!row_family_agrees(left)) return false;
    }
    return true;
}

static_assert(families_agree());

[[nodiscard]] inline std::span<const Entry> entries() noexcept {
    return kEntries;
}

// Thư mục gói: chosen khi khác rỗng, không thì <thư mục exe>/shaders.
[[nodiscard]] std::string resolved_shader_folder(const std::string& chosen);

struct CatalogDesc {
    gpu::Format color = gpu::Format::kRgba8UnormSrgb;
    gpu::Format depth = gpu::Format::kD32Float;
    std::uint32_t samples = 1;
    std::string shader_dir;
};

// Sở hữu mọi PSO đã tạo. Mượn device: huỷ catalog trước device, sau mọi chỗ đang giữ handle.
class Catalog {
public:
    Catalog(const Catalog&) = delete;
    Catalog& operator=(const Catalog&) = delete;
    Catalog(Catalog&& other) noexcept;
    Catalog& operator=(Catalog&&) = delete;
    ~Catalog();

    [[nodiscard]] static core::Result<Catalog> open(gpu::Device& device, CatalogDesc desc);

    // Tạo mọi mục của tầng chưa tạo. Gọi lại thì bỏ qua mục đã thử. In một dòng khi tầng có mục.
    [[nodiscard]] core::Status prepare(Tier tier);

    [[nodiscard]] gpu::PipelineHandle get(Pso pso) const noexcept;
    // Lỗi của mục đã thử mà không tạo được. nullptr khi chưa thử hoặc đã có handle.
    [[nodiscard]] const core::Error* fault(Pso pso) const noexcept;
    [[nodiscard]] std::array<gpu::PipelineHandle, kModelVariants> models() const noexcept;

private:
    // Một ô: đã thử, handle nếu tạo được, lỗi nếu không.
    struct SlotState {
        gpu::PipelineHandle handle{};
        std::optional<core::Error> fault;
        bool tried = false;
    };

    Catalog() = default;

    [[nodiscard]] SlotState& state_of(Pso pso) noexcept;
    [[nodiscard]] const SlotState& state_of(Pso pso) const noexcept;
    [[nodiscard]] bool tier_pending(Tier tier) const noexcept;
    [[nodiscard]] bool tier_has(Tier tier, std::string_view vertex) const noexcept;
    void warm_tier(Tier tier, std::uint32_t& created, std::optional<core::Error>& required);
    void warm_family(Tier tier, std::string_view vertex, std::string_view pixel, std::uint32_t frame_bytes,
        std::uint32_t draw_bytes, std::uint32_t& created, std::optional<core::Error>& required);
    void take_loaded(const Entry& entry, std::span<const gpu::ShaderHandle> shaders, const core::Status& loaded,
        std::uint32_t& created, std::optional<core::Error>& required);
    [[nodiscard]] core::Result<gpu::PipelineHandle> build(const Entry& entry,
        std::span<const gpu::ShaderHandle> shaders) const;

    gpu::Device* device_ = nullptr;
    CatalogDesc desc_{};
    std::array<SlotState, kSlotCount> slots_{};
};

} // namespace game::render
