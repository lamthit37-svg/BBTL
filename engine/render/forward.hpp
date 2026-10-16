/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/render/forward.hpp
 *  PHÂN HỆ   : Render / Forward
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Lượt vẽ thuận (forward) cho model GLB: lát đầu tiên của renderer, đủ để
 *    một model đã nạp, đã tải lên GPU và đã đặt tư thế bằng anim hiện thành
 *    khung hình. Vẽ lưới tam giác có skinning bốn khớp mỗi đỉnh, màu nền (hệ
 *    số, texture, màu đỉnh), cắt và trộn theo alpha, chất liệu hai mặt và
 *    unlit.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Ánh sáng và sương theo shader của client 2026 (MaterialTemplates/Model_vs.hlsl, Model_ps.hlsl, FairyTerrain.hlsl):
// hai đèn chính, một đèn điểm gần nhất cho mỗi vật thể, ambient có màu, màu ambient, diffuse, specular, emissive của
// Pass do người gọi điền, ánh sáng riêng của nhân vật, sương theo độ sâu. Mọi màu trong Lighting là số của tệp cảnh
// (không gian gamma). CHƯA có (lộ trình 3.13): PBR, normal map, bóng đổ, hậu xử lý, morph target,
// KHR_texture_transform, bộ UV thứ hai, lọc khuất, topology ngoài danh sách tam giác. Bản sao cứng không skin của
// cùng một drawable vẽ bằng một lệnh instanced cho mỗi primitive (Instance::copies), mỗi bản mang đèn điểm của riêng
// nó. Loại theo khung nhìn bằng hình cầu bao: bản sao, và vật thể đứng yên ở tư thế nghỉ (không skin, Instance::nodes
// rỗng), nằm hẳn ngoài một mặt của khung thì không vẽ. Nguồn shader ở src/client/render/shaders, dịch lúc build thành
// gói .f2s; bố cục gắn tài nguyên lấy từ phản chiếu của gói, không khai lại ở C++. Dữ liệu mỗi khung (hằng của khung,
// bảng khớp) nằm ở buffer Upload chia theo slot: nơi gọi trao chỉ số ảnh swapchain vừa acquire làm slot. Ảnh ấy chỉ
// được acquire lại khi GPU đã vẽ xong khung trước của nó, nên buffer của slot chắc chắn không còn được đọc. Khác gốc
// (Forge2 src/render/forward.hpp): Instance::joints, ma trận skin dựng sẵn do nơi gọi đưa vào (người chơi dùng công
// thức skin của OGRE); Lighting thay Light một đèn Lambert; Instance::is_actor.

#pragma once

#include "core/error.hpp"
#include "gpu/device.hpp"
#include "math/matrix.hpp"
#include "render/camera.hpp"
#include "resource/model.hpp"
#include "resource/upload.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <span>
#include <string>
#include <vector>

namespace game::render {

// Một đèn chính (directional) của cảnh.
struct Sun {
    // Hướng TỚI đèn trong không gian thế giới; không cần chuẩn hoá.
    math::Vector3 toward{0.4F, 1.0F, 0.6F};
    // Màu vật thể của cảnh nhận, đã nhân cường độ của đèn.
    math::Vector3 color{0.0F, 0.0F, 0.0F};
    // Màu nhân vật nhận từ hướng này, đã nhân cường độ.
    math::Vector3 actor{0.0F, 0.0F, 0.0F};
};

// Một đèn điểm: tại khoảng cách d sáng (1 - d / range) mũ falloff, kẹp trong 0..1.
struct Lamp {
    math::Vector3 position{0.0F, 0.0F, 0.0F};
    // Đã nhân cường độ của đèn.
    math::Vector3 color{0.0F, 0.0F, 0.0F};
    float range = 0.0F;
    float falloff = 1.0F;
};

// Số đèn giả một khung mang theo (kFakes ở model.inc.slang). Forward chọn những đèn gần mắt nhất còn trong
// khung nhìn.
inline constexpr std::size_t kFakeSlots = 24;

// Đèn giả FakeLight của Render.dll (0x18010c960): một hộp (unitbox.mesh, nửa cạnh 50) nhân scale, cộng sáng
// lên mọi bề mặt nằm trong hộp (Model_FakePointLight_ps.hlsl, scene_blend dest_colour one). Bản gốc vẽ hộp rồi
// đọc depth buffer; ở đây từng điểm ảnh của model và địa hình tự đổi vị trí của chính nó sang toạ độ hộp, cho
// cùng kết quả với bề mặt đục.
struct FakeLight {
    // Tâm hộp trong thế giới và bán kính hình cầu bao hộp, để bỏ đèn ngoài khung nhìn.
    math::Vector3 centre{0.0F, 0.0F, 0.0F};
    float radius = 0.0F;
    // Ba hàng đổi vị trí thế giới (w = 1) sang toạ độ hộp: gốc ở tâm, mỗi cạnh dài 1 (đã nhân 0,01).
    std::array<math::Float4, 3> rows{};
    // rgb: diffuse nhân cường độ và fake_point_light_intensity của EnvKey; w: size (lightParams.w).
    math::Float4 color{};
};

// Đúng thứ tự Ogre::FogMode.
enum class FogKind : std::uint8_t { kNone, kExp, kExp2, kLinear };

struct Fog {
    FogKind kind = FogKind::kNone;
    math::Vector3 color{1.0F, 1.0F, 1.0F};
    // Dùng cho kExp và kExp2.
    float density = 0.001F;
    // Dùng cho kLinear, tính bằng độ sâu trong không gian camera.
    float start = 0.0F;
    float end = 1.0F;
};

// Số ô đèn điểm của khối hằng một khung (kLamps ở model.inc.slang); ô cuối dành cho đèn tắt.
inline constexpr std::size_t kLampSlots = 32;
// Số đèn điểm một khung mang được; đèn đứng sau trong Lighting::lamps không chiếu.
inline constexpr std::size_t kMaxLamps = kLampSlots - 1;

// Ánh sáng của một khung. Mặc định là một đèn trắng chếch từ trên xuống với nền xám, để model vẽ
// không kèm cảnh vẫn thấy khối.
struct Lighting {
    math::Vector3 ambient{0.25F, 0.25F, 0.25F};
    // Ambient của nhân vật (Instance::is_actor).
    math::Vector3 actor_ambient{0.25F, 0.25F, 0.25F};
    std::array<Sun, 2> suns{
        Sun{.color = math::Vector3(1.0F, 1.0F, 1.0F), .actor = math::Vector3(1.0F, 1.0F, 1.0F)}, Sun{}};
    // Màu specular của đèn chính một; chất liệu có specular mới dùng.
    math::Vector3 specular{0.0F, 0.0F, 0.0F};
    // Đèn điểm của cảnh; phải sống tới khi draw trả về. Mỗi vật thể nhận đèn gần nhất còn với tới.
    std::span<const Lamp> lamps;
    // Đèn giả đang bật của cảnh (độ sáng cảnh nằm trong khoảng của từng đèn); phải sống tới khi draw xong.
    std::span<const FakeLight> fakes;
    Fog fog;
    // ColorGreaterOne của bản gốc: ánh sáng không bị kẹp ở 1.
    bool is_overbright = false;
    // Giây từ lúc mở cửa sổ. Shader model đưa vào rules.y để cuộn UV của thác (scroll_anim).
    float seconds = 0.0F;
    // Sương chiều cao. hfog_color.a > 0 thì shader áp HeightFog_ps. Mặc định tắt.
    math::Float4 hfog{};
    math::Float4 dfog{};
    math::Float4 hfog_color{};
    math::Float4 hfog_scatter{};
};

struct ForwardDesc {
    // Định dạng của đích vẽ mà mọi lệnh draw sẽ ghi vào.
    gpu::Format color_format = gpu::Format::kRgba8UnormSrgb;
    gpu::Format depth_format = gpu::Format::kD32Float;
    // Số bộ buffer mỗi khung: số ảnh của swapchain, hoặc 1 khi nơi gọi chờ GPU xong giữa hai khung.
    std::uint32_t slots = 1;
    // Số mẫu khử răng cưa của đích vẽ; pipeline phải dựng đúng số mẫu của đích ấy.
    std::uint32_t samples = 1;
    // Thư mục chứa model.vs.f2s và model.ps.f2s; rỗng thì lấy thư mục shaders cạnh exe.
    std::string shader_dir;
    // Máy yếu: mọi chất liệu tính ánh sáng ở đỉnh, kể cả địa hình và chất liệu pslit mà bản gốc
    // tính ở điểm ảnh (đo trên PowerVR GE8320: tính ở điểm ảnh thì không giữ được 60 khung/giây).
    bool lights_at_vertices = false;
    // Trần số tam giác mỗi khung (đã nhân số bản sao). Vượt trần thì Forward chuyển lưới có nhiều mức chi tiết sang mức
    // thô hơn, lưới to và gần giữ lâu nhất; lưới không có mức thô và nền địa hình không giảm được. 0 là không giới hạn.
    // Đo trên PowerVR GE8320: thời gian khung theo số tam giác, không theo điểm ảnh.
    std::uint32_t triangle_cap = 0;
};

class Forward;

// Hình học của một primitive trong không gian lưới: bán kính hình cầu bao quanh tâm hộp bao, và tổng diện tích tam giác.
struct PartExtent {
    float radius = 0.0F;
    float area = 0.0F;
};

// Model sẵn sàng để vẽ: nhóm gắn của từng chất liệu và tư thế nghỉ của các nút. Mượn Model và
// Uploaded đã trao cho Forward::prepare: cả hai, cùng Forward tạo ra nó, phải sống lâu hơn.
class Drawable {
public:
    Drawable() = default;
    Drawable(Drawable&& other) noexcept;
    Drawable& operator=(Drawable&& other) noexcept;
    Drawable(const Drawable&) = delete;
    Drawable& operator=(const Drawable&) = delete;
    ~Drawable();

    // Ma trận không gian mô hình của mọi nút ở tư thế nghỉ, theo chỉ số nút.
    [[nodiscard]] std::span<const math::Matrix4> rest() const noexcept { return rest_; }

    // Mọi skin của model, ở tư thế nghỉ, cho ma trận khớp bằng đơn vị: lưới skin vẽ ra y như lưới không
    // skin đặt ở không gian của instance. Model như vậy vẽ được bằng bản sao instanced (Instance::copies)
    // khi instance không đặt tư thế (nodes và joints rỗng). Model không skin cũng đúng.
    [[nodiscard]] bool is_rest_neutral() const noexcept { return is_rest_neutral_; }

private:
    friend class Forward;

    void release() noexcept;

    gpu::Device* device_ = nullptr;
    const resource::Model* model_ = nullptr;
    const resource::Uploaded* uploaded_ = nullptr;
    // Một nhóm cho mỗi chất liệu của model, rồi một nhóm cho primitive không khai chất liệu.
    std::vector<gpu::BindGroupHandle> materials_;
    std::vector<math::Matrix4> rest_;
    bool is_rest_neutral_ = false;
    // Khoảng cách xa nhất từ gốc model tới một đỉnh ở tư thế nghỉ (bán kính bao của Ogre::Mesh),
    // để biết đèn điểm nào còn với tới vật thể và vật thể còn chạm khung nhìn hay không.
    float radius_ = 0.0F;
    // Tâm hộp bao của từng primitive, theo [lưới][primitive], trong không gian của lưới: mốc đo
    // khoảng cách khi xếp lưới trộn alpha.
    std::vector<std::vector<math::Vector3>> centers_;
    // Kích thước hình học của từng primitive, cùng chỉ số với centers_: bán kính hình cầu bao quanh tâm và diện tích bề mặt
    // (radius_ đo từ gốc model nên có thể lớn hơn nhiều so với hình học). Dùng chọn mức chi tiết.
    std::vector<std::vector<PartExtent>> part_extents_;
};

// Một lần vẽ một model trong khung.
struct Instance {
    const Drawable* drawable = nullptr;
    // Không gian mô hình sang thế giới.
    math::Matrix4 world = math::Matrix4::identity();
    // Ma trận không gian mô hình của mọi nút, theo chỉ số nút (từ anim, qua resource::Rig); rỗng
    // thì vẽ ở tư thế nghỉ.
    std::span<const math::Matrix4> nodes;
    // Rỗng: một bản ở world. Khác rỗng: mỗi ma trận là một bản sao; world bị bỏ. Model có skin chỉ được
    // vẽ bằng bản sao khi Drawable::is_rest_neutral và instance không đặt tư thế (nodes, joints rỗng).
    std::span<const math::Matrix4> copies;
    // Ma trận skin dựng sẵn theo thứ tự khớp của skin: khác rỗng thì thay phép nodes * inverse_bind
    // khi dựng bảng khớp, để nơi gọi dùng đúng công thức skin của OGRE (Bone::_getOffsetTransform),
    // vốn khác phép nhân ma trận ở xương có scale không đều. Rỗng: như trước.
    std::span<const math::Matrix4> joints;
    // Nhân vật (LogicModel của bản gốc): nhận ambient và màu đèn riêng của nhân vật.
    bool is_actor = false;
};

class Forward {
public:
    // pipelines là bốn biến thể model của Catalog, theo Pso 0..3. terrain là pipeline địa hình lớp cọ
    // (Pso::kTerrain), được phép rỗng: chất liệu có resource::Splat khi ấy vẽ như chất liệu thường.
    // solid là Pso::kModelSolid và kModelSolidTwoSided (không discard), được phép rỗng: chất liệu đục không cắt
    // alpha khi ấy vẽ bằng biến thể model thường.
    // Forward không huỷ chúng: Catalog phải sống lâu hơn Forward. InvalidArgument khi thiếu slot hoặc
    // một handle model rỗng. Mượn device: Forward và mọi Drawable của nó phải bị huỷ trước device.
    [[nodiscard]] static core::Result<Forward> create(gpu::Device& device, const ForwardDesc& desc,
        std::array<gpu::PipelineHandle, 4> pipelines, gpu::PipelineHandle terrain = {},
        std::array<gpu::PipelineHandle, 2> solid = {});

    Forward(Forward&&) noexcept;
    Forward& operator=(Forward&&) noexcept;
    Forward(const Forward&) = delete;
    Forward& operator=(const Forward&) = delete;
    ~Forward();

    // uploaded phải là kết quả của resource::upload cho chính model này.
    [[nodiscard]] core::Result<Drawable> prepare(const resource::Model& model, const resource::Uploaded& uploaded);

    // Ghi dữ liệu của khung vào buffer của slot rồi ghi lệnh vẽ mọi instance. Gọi giữa
    // begin_rendering và end_rendering của một đích vẽ đúng định dạng đã khai, một lần mỗi slot
    // mỗi khung. Lưới đục vẽ trước; lưới trộn alpha vẽ sau, xa trước gần sau.
    [[nodiscard]] core::Status draw(gpu::CommandList& list, std::uint32_t slot, const Camera& camera,
        const Lighting& lighting, std::span<const Instance> instances);

    // Số lệnh vẽ của lần draw gần nhất, sau khi đã loại thứ nằm ngoài khung nhìn.
    [[nodiscard]] std::uint32_t draw_count() const noexcept;

    // Trần số tam giác mỗi khung (ForwardDesc::triangle_cap), đổi được giữa các khung. 0 là không giới hạn.
    void set_triangle_cap(std::uint32_t cap) noexcept;
    [[nodiscard]] std::uint32_t triangle_cap() const noexcept;

private:
    struct State;

    explicit Forward(std::unique_ptr<State> state) noexcept;

    std::unique_ptr<State> state_;
};

} // namespace game::render
