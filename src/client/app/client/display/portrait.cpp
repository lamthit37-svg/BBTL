// Ảnh đầu 3D của người chơi (xem portrait.hpp).
#include "client/display/portrait.hpp"

#include "client/display/player.hpp"
#include "core/clock.hpp"
#include "core/error.hpp"
#include "gpu/command.hpp"
#include "gpu/device.hpp"
#include "gpu/handle.hpp"
#include "io/file.hpp"
#include "look/body.hpp"
#include "look/head.hpp"
#include "math/vector.hpp"
#include "render/camera.hpp"
#include "render/canvas.hpp"
#include "render/forward.hpp"
#include "render/view_size.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <expected>
#include <filesystem>
#include <memory>
#include <print>
#include <string_view>
#include <utility>
#include <vector>

namespace game::client {
namespace {

// Ống kính của fake object ở client 2026: FOV dọc 20 độ, mặt cắt gần 10 (Render.dll RVA 0x17C10).
// Mặt cắt xa không đọc được; đủ xa để trọn mô hình.
constexpr float kFovDegrees = 20.0F;
constexpr float kNearPlane = 10.0F;
constexpr float kFarPlane = 2000.0F;

// Loại ô của khung người chơi. Script 2026 vẽ chân dung 2D nên không còn lời gọi nào cho biết loại
// của khung này; nó nằm cùng mép trái với khung đội nên dùng cùng bộ số (mặt quay vào giữa màn
// hình). Với hai mô hình người chơi, loại 1, 2 và 3 trùng số (NGHI-NGO 24).
constexpr std::uint8_t kPlayerKind = look::kPartyHeadKind;

// Bộ số camera của mẫu mô hình ở khung người chơi; không đọc được bảng thì số mặc định của bản gốc.
look::HeadPose pose_of(const std::filesystem::path& data_root, std::string_view model) {
    const io::TextResult text = io::read_text(data_root / "Table" / "head_cameras.tsv");
    if (!text) {
        std::println(stderr, "Chân dung: không có bảng camera ảnh đầu, dùng số mặc định");
        return {};
    }
    const look::HeadsResult rows = look::parse_heads(*text);
    if (!rows) {
        std::println(stderr, "Chân dung: bảng camera ảnh đầu hỏng: {}", rows.error());
        return {};
    }
    return look::find_head(*rows, look::HeadKey{.model = model, .kind = kPlayerKind});
}

// Ánh sáng của fake object ở mã 2008: môi trường trắng (1, 1, 1); đèn riêng đặt tại camera chỉ làm
// sáng thêm phần đã đủ sáng. Ở đây chỉ giữ phần môi trường nên màu ra đúng màu texture.
constexpr float kAmbient = 1.0F;

constexpr float kTwoPi = 6.28318548F;
// Khoảng thời gian tối đa một khung được tính vào góc quay (giây).
constexpr float kLongestStep = 0.1F;

} // namespace

render::Camera head_camera(const look::HeadPose& pose) noexcept {
    const look::HeadSight sight = look::head_sight(pose);
    const math::Point3 target(sight.target[0], sight.target[1], sight.target[2]);
    const math::Point3 eye(sight.eye[0], sight.eye[1], sight.eye[2]);
    const render::Lens lens{.fov_degrees = kFovDegrees, .near_plane = kNearPlane, .far_plane = kFarPlane};
    return render::look_camera(eye, target, lens, render::ViewSize{.width = 1, .height = 1});
}

// Toàn thân vừa khít FOV 20 độ, cùng ống kính fake object của bảng nhân vật.
render::Camera body_camera(float height) noexcept {
    const look::BodySight sight = look::body_sight(height);
    const math::Point3 target(sight.target[0], sight.target[1], sight.target[2]);
    const math::Point3 eye(sight.eye[0], sight.eye[1], sight.eye[2]);
    const render::Lens lens{
        .fov_degrees = look::kBodyFovDegrees, .near_plane = look::kBodyNear, .far_plane = kFarPlane};
    return render::look_camera(eye, target, lens, render::ViewSize{.width = 1, .height = 1});
}

struct HeadShot::State {
    State(PlayerActor made, render::Canvas target) : actor(std::move(made)), canvas(std::move(target)) {}

    PlayerActor actor;
    render::Canvas canvas;
    render::Forward* forward = nullptr;
    render::Camera camera;
    render::Lighting light;
    // Hướng mặt của mô hình trước camera (cột turn của bảng), radian.
    float turn = 0.0F;
    // Số vòng mỗi giây đang quay và lúc cập nhật hướng lần trước.
    float spin = 0.0F;
    core::Clock::time_point last;
    std::vector<render::Instance> instances;
};

HeadShot::HeadShot(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}
HeadShot::HeadShot(HeadShot&&) noexcept = default;
HeadShot& HeadShot::operator=(HeadShot&&) noexcept = default;
HeadShot::~HeadShot() = default;

core::Result<HeadShot> HeadShot::create(gpu::Device& device, const HeadShotDesc& desc, const MeshLoader& load_mesh) {
    if (desc.forward == nullptr) {
        return core::fail(core::ErrorCode::kInvalidArgument, "ảnh đầu thiếu lượt vẽ mô hình");
    }
    core::Result<PlayerActor> actor = PlayerActor::create(desc.player, load_mesh);
    if (!actor) return std::unexpected(actor.error());
    render::CanvasDesc target;
    target.width = desc.pixels;
    target.height = desc.pixels;
    target.color_format = desc.color_format;
    target.depth_format = desc.depth_format;
    target.samples = desc.samples;
    core::Result<render::Canvas> canvas = render::Canvas::create(device, target);
    if (!canvas) return std::unexpected(canvas.error());
    auto state = std::make_unique<State>(std::move(*actor), std::move(*canvas));
    state->forward = desc.forward;
    const look::Figure& figure = state->actor.figure();
    if (desc.is_body) {
        state->camera = body_camera(figure.height);
        state->turn = 0.0F;
    }
    if (!desc.is_body) {
        const look::HeadPose pose = pose_of(desc.player.data_root, figure.template_name);
        state->camera = head_camera(pose);
        state->turn = pose.turn;
    }
    state->light.actor_ambient = math::Vector3(kAmbient);
    state->light.suns = {};
    return HeadShot(std::move(state));
}

void HeadShot::set_spin(float speed) noexcept {
    state_->spin = speed;
}

core::Status HeadShot::record(gpu::CommandList& list, std::uint32_t slot) {
    State& state = *state_;
    const core::Clock::time_point now = core::Clock::now();
    if (state.spin != 0.0F) {
        // Một khung dừng lâu (kéo cửa sổ) không làm người mẫu nhảy một đoạn dài.
        const float seconds = std::min(std::chrono::duration<float>(now - state.last).count(), kLongestStep);
        state.turn = std::fmod(state.turn + (state.spin * kTwoPi * seconds), kTwoPi);
    }
    state.last = now;
    // Đứng yên ở gốc, hướng mặt đúng góc của bảng như SetFaceDir(turn) của bản gốc (0 là nhìn thẳng
    // vào camera ở phía +z); bộ dáng tự phát động tác nghỉ.
    Stand stand;
    stand.facing = state.turn;
    const core::Status posed = state.actor.update(now, stand);
    if (!posed) return posed;
    state.instances.clear();
    state.actor.append(state.instances);
    state.canvas.begin(list);
    const core::Status drawn = state.forward->draw(list, slot, state.camera, state.light, state.instances);
    state.canvas.end(list);
    return drawn;
}

gpu::TextureViewHandle HeadShot::view() const noexcept {
    return state_->canvas.color_view();
}

bool HeadShot::is_bottom_up() const noexcept {
    return state_->canvas.is_bottom_up();
}

} // namespace game::client
