// Catalog pipeline: mỗi PSO một nhóm và một tầng. Nhóm là chỗ quản lý, tầng là lúc prepare.
// Forward, UiPass và FxView mượn handle; catalog huỷ chúng. prepare tạo mục của tầng chưa có.
// Model hỏng thì prepare trả lỗi. Giao diện và hiệu ứng hỏng thì handle rỗng, lỗi nằm ở fault.
// Đường vẽ không tạo PSO. Vật có ngưỡng cắt alpha vẽ bằng họ model của nhóm Character; vật đục không cắt vẽ bằng
// model_solid.ps của nhóm World khi gói có mặt.
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
    // Bầu trời EnScene: vòm, mây, trăng và mặt trời (sky.vs, sky.ps).
    kSky,
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

// PSO đang có. Bốn ô model trùng bit chất liệu: bit 0 hai mặt, bit 1 trộn alpha.
// Hạt dùng chung fx.vs và fx.ps; mỗi scene_blend một PSO. kFx là one one, kFxBlend là
// src_alpha / one_minus_src_alpha. Năm ô sau kModelSolidTwoSided là các cặp còn lại.
// kTerrain là mặt đất lớp cọ: đỉnh của model, điểm ảnh của terrain.ps; đục, hai mặt.
enum class Pso : std::uint8_t {
    kModelOpaque = 0,
    kModelTwoSided = 1,
    kModelBlend = 2,
    kModelBlendTwoSided = 3,
    kUi = 4,
    kFx = 5,
    kFxBlend = 6,
    kTerrain = 7,
    // Model đục không cắt alpha (model_solid.ps, không discard): discard làm GPU tile mất khử che
    // khuất. Đo 2026-10-15 trên PowerVR GE8320: vật đục ăn 160 trong 217 ms mỗi khung. Không bắt
    // buộc: thiếu gói thì vẽ bằng kModelOpaque.
    kModelSolid = 8,
    kModelSolidTwoSided = 9,
    // Không chen trước kModelSolid: bit chất liệu model nằm ở các giá trị 0..3 và 8..9.
    kFxAlphaAdd = 10,
    kFxDarken = 11,
    kFxGlow = 12,
    kFxColour = 13,
    kFxReplace = 14,
    // Bầu trời EnScene (sky.vs, sky.ps; một cbuffer cho cả khung, xem display/sky_view.cpp).
    // kSkyDome là vòm: đục, hai mặt kề nhau, nhìn từ trong; kSkyCloud là lớp mây và mây vòng: trộn
    // alpha, hai mặt; kSkyBody là trăng và mặt trời: trộn alpha, một mặt. Ba PSO đều thử độ sâu và
    // không ghi.
    kSkyDome = 15,
    kSkyCloud = 16,
    kSkyBody = 17,
    // Sao (star.vs, star.ps): mỗi sao một hình chữ nhật bốn đỉnh, cộng màu một một, một mặt cắt
    // không loại.
    kSkyStar = 18,
    // Cộng sáng one one (scene_blend add). Bit của 19 và 20 không phải cờ trộn hay hai mặt:
    // make_model nhận riêng hai giá trị này. Không chen trước kModelSolid.
    kModelAdd = 19,
    kModelAddTwoSided = 20,
};

inline constexpr std::uint32_t kModelTwoSided = 1;
inline constexpr std::uint32_t kModelBlended = 2;
// Cỡ khối hằng của model.inc.slang. forward.cpp static_assert sizeof khối C++ bằng hai số này.
inline constexpr std::uint32_t kModelFrameBytes = 2896;
inline constexpr std::uint32_t kModelDrawBytes = gpu::kMaxPushBytes;
inline constexpr std::size_t kModelVariants = 4;
inline constexpr std::size_t kPackageCount = 12;
inline constexpr std::size_t kSlotCount = 21;
// Cỡ khối hằng của sky.inc.slang: SkyBlock (32 lệnh, mỗi lệnh 16 float4) và push constant (một uvec4).
inline constexpr std::uint32_t kSkyFrameBytes = 8192;
inline constexpr std::uint32_t kSkyDrawBytes = 16;

// Bố cục đỉnh sao (display/sky_view.cpp giữ struct cùng các số này): vị trí, góc 0..1 của hình chữ nhật, rồi
// (r, g, b, độ sáng ngẫu nhiên). Cùng cbuffer SkyBlock với ba PSO bầu trời khác.
inline constexpr std::uint32_t kStarStride = 36;
inline constexpr std::uint32_t kStarCorner = 12;
inline constexpr std::uint32_t kStarColour = 20;

// Bố cục đỉnh hạt. fx_view giữ struct cùng các số này; catalog dựng pipeline theo chúng.
inline constexpr std::uint32_t kFxStride = 44;
inline constexpr std::uint32_t kFxUv = 12;
inline constexpr std::uint32_t kFxColour = 20;
// UV của ảnh thứ hai, sau màu. Particle_vs gốc copy uv thành xyxy rồi mỗi unit một ma trận.
inline constexpr std::uint32_t kFxCoverUv = 36;

// Mọi gói .f2s catalog có thể nạp. Hash cache đĩa đi theo danh sách này, mỗi tên một lần.
inline constexpr std::array<std::string_view, kPackageCount> kPackageNames{"model.vs",
    "model.ps", "ui.vs", "ui.ps", "fx.vs", "fx.ps", "terrain.ps", "model_solid.ps", "sky.vs",
    "sky.ps", "star.vs", "star.ps"};

// Một dòng của bảng. is_required: thiếu PSO ấy thì prepare của tầng trả lỗi.
// frame_bytes và draw_bytes là cỡ khối hằng mà mã ghi. 0 nghĩa là không kiểm khối đó.
// Mọi dòng cùng cặp (vertex, pixel) dùng một lần nạp, nên phải cùng hai cỡ.
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

// Bảng tĩnh. Thêm shader là thêm một hàm rồi một tên vào mảng. prepare đi theo bảng.
constexpr Entry character_entry(std::string_view name, Pso pso) {
    Entry entry;
    entry.name = name;
    entry.group = Group::kCharacter;
    entry.tier = Tier::kEssential;
    entry.pso = pso;
    entry.vertex = "model.vs";
    entry.pixel = "model.ps";
    entry.is_required = true;
    entry.frame_bytes = kModelFrameBytes;
    entry.draw_bytes = kModelDrawBytes;
    return entry;
}

constexpr Entry world_entry(std::string_view name, Pso pso, std::string_view pixel) {
    Entry entry;
    entry.name = name;
    entry.group = Group::kWorld;
    entry.tier = Tier::kEssential;
    entry.pso = pso;
    entry.vertex = "model.vs";
    entry.pixel = pixel;
    entry.is_required = false;
    entry.frame_bytes = kModelFrameBytes;
    entry.draw_bytes = kModelDrawBytes;
    return entry;
}

constexpr Entry solid_entry(std::string_view name, Pso pso) {
    return world_entry(name, pso, "model_solid.ps");
}

constexpr Entry terrain_entry() {
    return world_entry("render.terrain", Pso::kTerrain, "terrain.ps");
}

constexpr Entry effect_entry(std::string_view name, Pso pso) {
    Entry entry;
    entry.name = name;
    entry.group = Group::kVfx;
    entry.tier = Tier::kScene;
    entry.pso = pso;
    entry.vertex = "fx.vs";
    entry.pixel = "fx.ps";
    entry.is_required = false;
    return entry;
}

constexpr Entry sky_entry(std::string_view name, Pso pso, std::string_view vertex,
    std::string_view pixel) {
    Entry entry;
    entry.name = name;
    entry.group = Group::kSky;
    entry.tier = Tier::kScene;
    entry.pso = pso;
    entry.vertex = vertex;
    entry.pixel = pixel;
    entry.is_required = false;
    entry.frame_bytes = kSkyFrameBytes;
    entry.draw_bytes = kSkyDrawBytes;
    return entry;
}

constexpr Entry ui_entry() {
    Entry entry;
    entry.name = "render.ui";
    entry.group = Group::kUi;
    entry.tier = Tier::kBootstrap;
    entry.pso = Pso::kUi;
    entry.vertex = "ui.vs";
    entry.pixel = "ui.ps";
    entry.is_required = false;
    return entry;
}

// Tên nằm trong row để không đụng kTwoSided, kFxColour của forward và của đỉnh hạt.
namespace row {
constexpr auto opaque = character_entry("render.model.opaque", Pso::kModelOpaque);
constexpr auto two_sided = character_entry("render.model.two_sided", Pso::kModelTwoSided);
constexpr auto blend = character_entry("render.model.blend", Pso::kModelBlend);
constexpr auto blend_two =
    character_entry("render.model.blend_two_sided", Pso::kModelBlendTwoSided);
constexpr auto ui = ui_entry();
constexpr auto fx = effect_entry("render.fx", Pso::kFx);
constexpr auto fx_blend = effect_entry("render.fx.blend", Pso::kFxBlend);
constexpr auto terrain = terrain_entry();
constexpr auto solid = solid_entry("render.model.solid", Pso::kModelSolid);
constexpr auto solid_two = solid_entry("render.model.solid_two_sided", Pso::kModelSolidTwoSided);
constexpr auto fx_alpha = effect_entry("render.fx.alpha_add", Pso::kFxAlphaAdd);
constexpr auto fx_darken = effect_entry("render.fx.darken", Pso::kFxDarken);
constexpr auto fx_glow = effect_entry("render.fx.glow", Pso::kFxGlow);
constexpr auto fx_tint = effect_entry("render.fx.colour", Pso::kFxColour);
constexpr auto fx_replace = effect_entry("render.fx.replace", Pso::kFxReplace);
constexpr auto dome = sky_entry("render.sky.dome", Pso::kSkyDome, "sky.vs", "sky.ps");
constexpr auto cloud = sky_entry("render.sky.cloud", Pso::kSkyCloud, "sky.vs", "sky.ps");
constexpr auto body = sky_entry("render.sky.body", Pso::kSkyBody, "sky.vs", "sky.ps");
constexpr auto star = sky_entry("render.sky.star", Pso::kSkyStar, "star.vs", "star.ps");
constexpr auto add = character_entry("render.model.add", Pso::kModelAdd);
constexpr auto add_two = character_entry("render.model.add_two_sided", Pso::kModelAddTwoSided);
} // namespace row

inline constexpr std::array<Entry, kSlotCount> kEntries{{
    row::opaque,
    row::two_sided,
    row::blend,
    row::blend_two,
    row::ui,
    row::fx,
    row::fx_blend,
    row::terrain,
    row::solid,
    row::solid_two,
    row::fx_alpha,
    row::fx_darken,
    row::fx_glow,
    row::fx_tint,
    row::fx_replace,
    row::dome,
    row::cloud,
    row::body,
    row::star,
    row::add,
    row::add_two,
}};

static_assert(std::to_underlying(Pso::kModelTwoSided) == kModelTwoSided);
static_assert(std::to_underlying(Pso::kModelBlend) == kModelBlended);
static_assert(std::to_underlying(Pso::kModelBlendTwoSided) == (kModelTwoSided | kModelBlended));

// Cùng cặp (vertex, pixel) là một lần nạp, nên hai cỡ khối hằng phải trùng nhau.
[[nodiscard]] constexpr bool same_family(const Entry& left, const Entry& right) noexcept {
    const bool is_same_pair = left.vertex == right.vertex && left.pixel == right.pixel;
    if (!is_same_pair) return true;
    const bool same_frame = left.frame_bytes == right.frame_bytes;
    const bool same_draw = left.draw_bytes == right.draw_bytes;
    return same_frame && same_draw;
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
    [[nodiscard]] bool tier_has(Tier tier, const Entry& pair) const noexcept;
    void warm_tier(Tier tier, std::uint32_t& created, std::optional<core::Error>& required);
    void warm_family(Tier tier, const Entry& pair, std::uint32_t& created, std::optional<core::Error>& required);
    void take_loaded(const Entry& entry, std::span<const gpu::ShaderHandle> shaders, const core::Status& loaded,
        std::uint32_t& created, std::optional<core::Error>& required);
    [[nodiscard]] core::Result<gpu::PipelineHandle> build(const Entry& entry,
        std::span<const gpu::ShaderHandle> shaders) const;

    gpu::Device* device_ = nullptr;
    CatalogDesc desc_{};
    std::array<SlotState, kSlotCount> slots_{};
};

} // namespace game::render
