// Catalog pipeline: bảng PSO, mỗi mục một nhóm và một tầng. Forward, UiPso và FxView mượn
// handle; catalog huỷ chúng. prepare tạo mọi mục của tầng chưa có. Model hỏng thì prepare trả
// lỗi. Giao diện và hiệu ứng hỏng thì handle rỗng, lỗi nằm ở fault. Đường vẽ không tạo PSO.
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

// Nhóm quản lý. Một nhóm có thể có nhiều PSO; một PSO chỉ thuộc một nhóm.
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

// Lúc prepare được gọi. Tầng 0 trước khung đầu; tầng 1 lúc vào chơi; tầng 2 lúc đổi cảnh;
// tầng 3 khi thiết bị có năng lực tương ứng.
enum class Tier : std::uint8_t { kBootstrap, kEssential, kScene, kOptional };

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

// Gói .f2s mà tầng 0 nạp. Hash cache đĩa đi theo danh sách này, mỗi tên một lần.
inline constexpr std::array<std::string_view, kSlotCount> kPackageNames{
    "model.vs", "model.ps", "ui.vs", "ui.ps", "fx.vs", "fx.ps"};

// Một dòng của bảng. is_required: thiếu PSO ấy thì prepare của tầng trả lỗi.
struct Entry {
    std::string_view name;
    Group group = Group::kWorld;
    Tier tier = Tier::kBootstrap;
    Pso pso = Pso::kModelOpaque;
    std::string_view vertex;
    std::string_view pixel;
    bool is_required = false;
};

// Bảng tĩnh. Thêm shader là thêm một dòng, không thêm chỗ gọi create_pipeline.
inline constexpr std::array<Entry, kSlotCount> kEntries{{
    {.name = "render.model.opaque",
        .group = Group::kWorld,
        .tier = Tier::kBootstrap,
        .pso = Pso::kModelOpaque,
        .vertex = "model.vs",
        .pixel = "model.ps",
        .is_required = true},
    {.name = "render.model.two_sided",
        .group = Group::kWorld,
        .tier = Tier::kBootstrap,
        .pso = Pso::kModelTwoSided,
        .vertex = "model.vs",
        .pixel = "model.ps",
        .is_required = true},
    {.name = "render.model.blend",
        .group = Group::kWorld,
        .tier = Tier::kBootstrap,
        .pso = Pso::kModelBlend,
        .vertex = "model.vs",
        .pixel = "model.ps",
        .is_required = true},
    {.name = "render.model.blend_two_sided",
        .group = Group::kWorld,
        .tier = Tier::kBootstrap,
        .pso = Pso::kModelBlendTwoSided,
        .vertex = "model.vs",
        .pixel = "model.ps",
        .is_required = true},
    {.name = "render.ui",
        .group = Group::kUi,
        .tier = Tier::kBootstrap,
        .pso = Pso::kUi,
        .vertex = "ui.vs",
        .pixel = "ui.ps",
        .is_required = false},
    {.name = "render.fx",
        .group = Group::kVfx,
        .tier = Tier::kBootstrap,
        .pso = Pso::kFx,
        .vertex = "fx.vs",
        .pixel = "fx.ps",
        .is_required = false},
}};

static_assert(std::to_underlying(Pso::kModelTwoSided) == kModelTwoSided);
static_assert(std::to_underlying(Pso::kModelBlend) == kModelBlended);
static_assert(std::to_underlying(Pso::kModelBlendTwoSided) == (kModelTwoSided | kModelBlended));

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
    [[nodiscard]] bool tier_has(Tier tier, std::string_view vertex) const noexcept;
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
