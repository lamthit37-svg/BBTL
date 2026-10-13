// Template hệ hạt và effect đọc từ script đã nấu.
// MeshRotator theo Render.dll RVA 0x1475c0 và 0x1474d0; parseAngle đổi độ sang radian.
// Khác gốc: mảng scale của ScaleInterpolator bắt đầu bằng (1, 1, 1) vì script bỏ
// khoá đúng bằng 1; để 0 thì lửa có kích thước 0.
#pragma once

#include "fx/script.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"

#include <array>
#include <cstdint>
#include <string>
#include <variant>
#include <vector>

namespace game::fx {

inline constexpr std::size_t kStages = 6;
inline constexpr float kDegree = 0.0174532925F;

using Colour = std::array<float, 4>;

enum class EmitterKind : std::uint8_t { kPoint, kBox, kRing, kEllipsoid, kHollowEllipsoid, kCylinder, kPolar };

struct EmitterDef {
    EmitterKind kind = EmitterKind::kPoint;
    float angle = 0.0F;
    Colour colour_start{1.0F, 1.0F, 1.0F, 1.0F};
    Colour colour_end{1.0F, 1.0F, 1.0F, 1.0F};
    ogre::Vec3 direction{.x = 1.0F, .y = 0.0F, .z = 0.0F};
    ogre::Vec3 up{.x = 0.0F, .y = 0.0F, .z = 1.0F};
    float emission_rate = 10.0F;
    ogre::Vec3 position{};
    float velocity_min = 0.0F;
    float velocity_max = 0.0F;
    float ttl_min = 1.0F;
    float ttl_max = 1.0F;
    float duration_min = 0.0F;
    float duration_max = 0.0F;
    float repeat_min = 0.0F;
    float repeat_max = 0.0F;
    ogre::Vec3 size{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    ogre::Vec3 inner{.x = 0.5F, .y = 0.5F, .z = 0.5F};
    ogre::Vec3 x_range{};
    ogre::Vec3 y_range{};
    ogre::Vec3 z_range{};
    // PolarEmitter trong Plugin_ParticleFX2.dll. Góc để độ, như bản gốc.
    float radius_start = 0.0F;
    float radius_step = 0.0F;
    float radius_end = 0.0F;
    float theta_start = 0.0F;
    float theta_step = 0.0F;
    float theta_end = 0.0F;
    float phi_start = 0.0F;
    float phi_step = 0.0F;
    float phi_end = 0.0F;
    bool polar_step = true;
    bool flip_yz = false;
    bool reset_radius = false;
    int reset_count = 0;
};

struct LinearForce {
    ogre::Vec3 force{.x = 0.0F, .y = -100.0F, .z = 0.0F};
    bool average = false;
};

struct Scaler {
    float rate = 0.0F;
};

struct Rotator {
    float speed_start = 0.0F;
    float speed_end = 0.0F;
    float angle_start = 0.0F;
    float angle_end = 0.0F;
};

struct ColourFading {
    std::array<Colour, kStages> colour{};
    std::array<float, kStages> time{0.0F, 1.0F, 1.0F, 1.0F, 1.0F, 1.0F};
    std::array<float, kStages> opacity{1.0F, 1.0F, 1.0F, 1.0F, 1.0F, 1.0F};
    float repeat_times = 1.0F;
    float opacity_all = 1.0F;
    float fade_in = 0.0F;
    float fade_out = 1.0F;
};

struct ScaleInterpolator {
    float width_start = 1.0F;
    float width_end = 1.0F;
    float height_start = 1.0F;
    float height_end = 1.0F;
    bool uniform = true;
    bool use_constant = false;
    ogre::Vec3 constant{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    // Constructor của DLL ghi 1 vào cờ nội suy (RVA 0xC25A) và 0 vào cờ increment (RVA 0xC2F3).
    bool use_interpolated = true;
    bool use_increment = false;
    std::array<ogre::Vec3, kStages> scale{ogre::Vec3{.x = 1.0F, .y = 1.0F, .z = 1.0F},
        ogre::Vec3{.x = 1.0F, .y = 1.0F, .z = 1.0F}, ogre::Vec3{.x = 1.0F, .y = 1.0F, .z = 1.0F},
        ogre::Vec3{.x = 1.0F, .y = 1.0F, .z = 1.0F}, ogre::Vec3{.x = 1.0F, .y = 1.0F, .z = 1.0F},
        ogre::Vec3{.x = 1.0F, .y = 1.0F, .z = 1.0F}};
    std::array<float, kStages> time{0.0F, 1.0F, 1.0F, 1.0F, 1.0F, 1.0F};
    float repeat_times = 1.0F;
    std::array<ogre::Vec3, kStages> increment{};
    std::array<float, kStages> increment_time{1.0F, 1.0F, 1.0F, 1.0F, 1.0F, 1.0F};
    float increment_repeat = 1.0F;
};

struct Movement {
    bool use_start = true;
    ogre::Vec3 start_min{};
    ogre::Vec3 start_max{};
    ogre::Vec3 acceleration{};
    ogre::Vec3 random_min{};
    ogre::Vec3 random_max{};
};

// RevolutionAffector::_affectParticles. RevoluMove là cùng phép quay, cộng thêm vận tốc trôi.
struct Revolution {
    float speed = 0.0F;
    ogre::Vec3 axis{.x = 0.0F, .y = 1.0F, .z = 0.0F};
    float radius_increment = 0.0F;
    ogre::Vec3 center_min{};
    ogre::Vec3 center_max{};
    bool use_scale = false;
    std::array<float, kStages> scale{};
    std::array<float, kStages> time{1.0F, 1.0F, 1.0F, 1.0F, 1.0F, 1.0F};
    float repeat_times = 1.0F;
    bool move = false;
    ogre::Vec3 move_velocity{};
    bool variable_velocity = false;
    std::array<ogre::Vec3, kStages> move_points{};
    std::array<float, kStages> move_time{1.0F, 1.0F, 1.0F, 1.0F, 1.0F, 1.0F};
    float move_repeat = 1.0F;
};

struct MeshRotator {
    ogre::Vec3 speed_start{};
    ogre::Vec3 speed_end{};
    ogre::Vec3 angle_start{};
    ogre::Vec3 angle_end{};
};

// MeshAnimationAffector chỉ giao tên clip cho renderer mesh. Phát clip nằm ở lúc vẽ.
struct MeshAnimation {
    std::string name;
    bool loop = false;
    float speed = 1.0F;
};

// SequenceFrame (Plugin_ParticleFX2.dll): phát lần lượt các ô stacks x slices của ảnh hạt theo tuổi hạt, repeat_times
// vòng trong một đời. Thuộc tính loop, pingpang, start_range đọc như tên gọi; play_mode, head_and_tail, play_times và
// baned_frames chưa đọc từ mã máy (docs/NGHI-NGO.md) nên mọi giá trị đều phát như "normal", "none".
struct SequenceFrame {
    int stacks = 1;
    int slices = 1;
    float repeat_times = 1.0F;
    bool loop = true;
    bool pingpang = false;
    // Ô bắt đầu của mỗi hạt, ngẫu nhiên trong [start_min, start_max] (tỉ lệ của số ô).
    float start_min = 0.0F;
    float start_max = 0.0F;
};

// DirectionRandomiserAffector của Ogre: mỗi nhịp, hạt nằm trong scope (phần trăm số hạt) được cộng vào vận tốc một vectơ
// ngẫu nhiên mỗi trục trong [-randomness, randomness] nhân số giây của nhịp; keep_velocity giữ độ dài vận tốc.
struct DirectionRandomiser {
    float randomness = 1.0F;
    float scope = 100.0F;
    bool keep_velocity = false;
};

using Affector = std::variant<LinearForce, Scaler, Rotator, ColourFading, ScaleInterpolator, Movement, Revolution,
    MeshRotator, MeshAnimation, SequenceFrame, DirectionRandomiser>;

enum class RendererKind : std::uint8_t { kBillboard, kTexcoord, kMesh, kRibbon };

enum class BillboardKind : std::uint8_t {
    kPoint,
    kOrientedCommon,
    kOrientedSelf,
    kPerpendicularCommon,
    kPerpendicularSelf
};

struct Origin {
    float left = -0.5F;
    float right = 0.5F;
    float top = 0.5F;
    float bottom = -0.5F;
};

struct SystemDef {
    std::string name;
    std::string material;
    std::size_t quota = 10;
    float width = 1.0F;
    float height = 1.0F;
    float depth = 1.0F;
    RendererKind renderer = RendererKind::kBillboard;
    // Tên tệp .mesh. GLB nằm ở Model/<tên>.glb. Rỗng khi không phải renderer mesh.
    std::string mesh_name;
    // true: mesh quay theo hướng hạt (MOT_ORIENTED_SELF). Mặc định gốc là origin.
    bool face_direction = false;
    int stacks = 1;
    int slices = 1;
    float repeat_times = 1.0F;
    int element_count = 15;
    float head_alpha = 1.0F;
    float tail_alpha = 1.0F;
    float head_width = 1.0F;
    float tail_width = 1.0F;
    bool local_space = true;
    bool sorted = false;
    BillboardKind billboard = BillboardKind::kPoint;
    Origin origin{};
    bool rotate_texcoord = false;
    ogre::Vec3 common_direction{.x = 0.0F, .y = 0.0F, .z = 1.0F};
    ogre::Vec3 common_up{.x = 0.0F, .y = 1.0F, .z = 0.0F};
    float speed_factor = 0.01F;
    std::vector<EmitterDef> emitters;
    std::vector<Affector> affectors;
};

inline constexpr std::size_t kFade = 5;

enum class ElementKind : std::uint8_t { kParticle, kBeam, kTrail, kProjector };

// Beam theo WXBeamElement: chuỗi từ gốc tới đích, nhiễu ở các mốc giữa, dựng lại theo tần số.
// NewRibbonTrail: dài tối đa TrailLength, bề rộng đầu-đuôi, năm mốc màu theo tuổi điểm.
// Projector: quad ngang cạnh ProjectionSize. Khác gốc: không chiếu lên mặt địa hình lồi.
struct ElementDef {
    ElementKind kind = ElementKind::kParticle;
    std::string system;
    std::string material;
    float start_time = 0.0F;
    float lifetime = 0.0F;
    ogre::Vec3 position{};
    ogre::Quat orientation{};
    int links = 10;
    float width = 10.0F;
    float frequency = 20.0F;
    Colour colour_a{1.0F, 1.0F, 1.0F, 1.0F};
    Colour colour_b{1.0F, 1.0F, 1.0F, 1.0F};
    ogre::Vec3 noise_min{};
    ogre::Vec3 noise_max{};
    // Sóng của Render.dll RVA 0x227C90. Mặc định ctor: sin bật, biên độ y 10, tần số 10, vận tốc 5.
    // t của sin/cos là chỉ số mốc, không phải chỉ số chia NumElements. CurveType khác 0 và
    // SpLineEditor chưa có công thức trong DLL nên không đổi đường thẳng. wave là quat tại +0x114,
    // ctor để đơn vị nên phép nhân vector là không đổi.
    bool sin_play = true;
    float extent_y = 10.0F;
    float extent_z = 0.0F;
    float wave_frequency = 10.0F;
    float wave_velocity = 5.0F;
    float shade_y = 0.0F;
    float shade_z = 0.0F;
    int tex_repeat = 1;
    bool visible = true;
    int curve = 0;
    ogre::Quat wave{};
    float trail_length = 100.0F;
    int chain_count = 80;
    float head_width = 20.0F;
    float tail_width = 0.0F;
    float width_change = 0.0F;
    float low_cut = 0.0F;
    float high_cut = 0.0F;
    float alpha_cut = 0.0F;
    float lift_time = 0.0F;
    std::array<float, kFade> fade_time{};
    std::array<Colour, kFade> fade_colour{};
    float projection = 200.0F;
};

struct EffectDef {
    std::string name;
    float lifetime = 0.0F;
    std::vector<ElementDef> elements;
};

[[nodiscard]] SystemDef read_system(const ScriptBlock& block);
[[nodiscard]] EffectDef read_effect(const ScriptBlock& block);

} // namespace game::fx
