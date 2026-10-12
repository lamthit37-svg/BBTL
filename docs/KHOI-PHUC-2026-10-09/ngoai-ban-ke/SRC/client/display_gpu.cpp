// Bản có chuỗi đồ hoạ: MỘT LUỒNG VẼ riêng giữ thiết bị của module gpu (xin backend rồi fallback, lớp kiểm tra
// theo yêu cầu), màn hình vẽ và render::Forward, và tự quay đều mỗi khung tới khi bị dừng. Luồng
// thông điệp của cửa sổ không chạm GPU nữa: kéo hay đổi cỡ cửa sổ không bao giờ đứng chờ vblank.
// Luồng vẽ khởi tạo mọi thứ (lỗi trả về Display::create), nạp stage đúng một lần — mỗi mesh một GLB
// (Model/<tên>.glb, ảnh ngoài giải trong thư mục dữ liệu), một upload, một Drawable, rồi dựng
// instance cho từng vật thể — và mỗi khung: đổi cỡ nếu cửa sổ vừa báo, camera quay quanh hộp bao
// thế giới theo đồng hồ, đèn đầu và ambient của cảnh, vẽ mọi instance, nộp và trình bày; khung đầu
// vẽ được chép ra buffer đọc ngược rồi ghi PNG khi có --shot. Vòng acquire–vẽ–present theo
// tools/view/main.cpp của Forge2; begin trả kInvalidState khi bề mặt đã đổi cỡ là đường chạy thường
// ngày, khung ấy bị bỏ và màn hình vẽ được dựng lại sau.
#include "client/display.hpp"

#include "capture/frame.hpp"
#include "capture/png.hpp"
#include "client/props.hpp"
#include "client/stage.hpp"
#include "core/bits.hpp"
#include "core/clock.hpp"
#include "core/error.hpp"
#include "gpu/barrier.hpp"
#include "gpu/command.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"
#include "io/file.hpp"
#include "math/geometry.hpp"
#include "math/matrix.hpp"
#include "math/vector.hpp"
#include "render/camera.hpp"
#include "render/forward.hpp"
#include "render/screen.hpp"
#include "resource/model.hpp"
#include "resource/upload.hpp"
#include "scene/placement.hpp"
#include "scene/transform.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <expected>
#include <filesystem>
#include <format>
#include <fstream>
#include <ios>
#include <limits>
#include <memory>
#include <mutex>
#include <optional>
#include <print>
#include <ratio>
#include <span>
#include <stop_token>
#include <string>
#include <thread>
#include <utility>
#include <vector>

namespace game::client {
namespace {

// Màu nền, ánh sáng tuyến tính; đích vẽ là định dạng sRGB nên màu hiện ra sáng hơn con số này.
constexpr gpu::ClearColor kBackdrop{.red = 0.05F, .green = 0.06F, .blue = 0.08F, .alpha = 1.0F};
// Nghỉ giữa hai khung khi cửa sổ đang thu nhỏ, hoặc khi bề mặt chưa sẵn cỡ.
constexpr std::chrono::milliseconds kIdleNap{16};

// Nghỉ một nhịp rồi đặt lại mốc đo: lượt sau không phải chịu thời gian ngủ.
void nap(core::Clock::time_point& previous) noexcept {
    std::this_thread::sleep_for(kIdleNap);
    previous = core::Clock::now();
}
// Khử răng cưa đa mẫu 4x: cảnh đá chi tiết quay chậm mà không có nó thì cạnh và hoạ tiết lăn tăn
// từng khung, nhìn như giật dù nhịp khung đều (đã đo: median 16,6 ms). Resolve chạy trên chip.
constexpr std::uint32_t kSamples = 4;
// Camera quay quanh cảnh: góc ban đầu, độ ngẩng và tốc độ quay mỗi giây. Theo đồng hồ đơn điệu
// chứ không theo số khung: cùng một tốc độ trên mọi tần số quét, và một khung bị bỏ (đang kéo cửa
// sổ, máy bận) không để lại cú giật bù.
constexpr float kYawStart = 0.6F;
constexpr float kPitch = 0.32F;
constexpr float kYawPerSecond = 0.24F;
constexpr float kMargin = 1.2F;
// Chỉ số mesh không nạp được trong bảng ánh xạ tên mesh sang kết quả nạp.
constexpr std::size_t kMissing = std::numeric_limits<std::size_t>::max();

using ForwardResult = core::Result<render::Forward>;
using ScreenRef = const render::Screen&;

// Một mesh đã nạp và tải lên GPU. Drawable giữ địa chỉ của model và uploaded cùng phần tử nên
// phần tử phải đứng yên: vector chứa chúng được reserve đủ trước khi nạp.
struct LoadedMesh {
    resource::Model model;
    resource::Uploaded uploaded;
    render::Drawable drawable;
};

// Kế hoạch đọc ngược một khung: buffer nhận bản chép và các số dựng FrameView sau khi GPU xong.
struct ShotPlan {
    gpu::BufferHandle staging{};
    std::uint64_t size = 0;
    std::uint64_t stride = 0;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    capture::PixelFormat format = capture::PixelFormat::kRgba8;
};

// Cỡ vùng vẽ gói trong một số nguyên để luồng thông điệp trao cho luồng vẽ không khoá.
using PackedSize = std::uint64_t;

[[nodiscard]] PackedSize pack(PixelSize size) noexcept {
    return (static_cast<PackedSize>(size.width) << 32U) | size.height;
}

[[nodiscard]] PixelSize unpack(PackedSize packed) noexcept {
    return {.width = static_cast<std::uint32_t>(packed >> 32U),
        .height = static_cast<std::uint32_t>(packed & 0xFFFF'FFFFU)};
}

[[nodiscard]] ForwardResult make_forward(
    gpu::Device& device, ScreenRef screen, const std::filesystem::path& data_root) {
    render::ForwardDesc pass;
    pass.color_format = screen.color_format();
    pass.depth_format = screen.depth_format();
    pass.slots = screen.image_count();
    pass.samples = screen.samples();
    // Gói shader ở data/shaders (Android giải nén từ APK); không có thì dùng mặc định cạnh exe
    // (bố cục CLIENT/bin với CLIENT/data của Windows).
    const std::filesystem::path packaged = data_root / "shaders";
    std::error_code ignored;
    if (std::filesystem::exists(packaged, ignored)) pass.shader_dir = packaged.string();
    return render::Forward::create(device, pass);
}

// Một hàng của phép đặt như vùng nhìn bốn số, có kiểm biên ở mọi cấu hình.
[[nodiscard]] std::span<const double, 4> row_of(
    const scene::Transform& placed, std::size_t row) noexcept {
    constexpr std::size_t kRows = 3;
    return core::at(std::span<const std::array<double, 4>, kRows>(placed.rows), row);
}

// Ma trận float cho GPU từ phép đặt double của cảnh: phần tử (hàng i, cột j) của [R * S | T] thành
// cột j của Matrix4, làm tròn về float đúng như scene/transform.hpp đã hứa.
[[nodiscard]] math::Matrix4 world_of(const scene::Transform& placed) noexcept {
    math::Matrix4 world = math::Matrix4::identity();
    for (std::size_t cell = 0; cell < 12; ++cell) {
        const std::size_t column = cell % 4;
        const std::size_t row = cell / 4;
        const double value = core::at(row_of(placed, row), column);
        world.set(column, row, static_cast<float>(value));
    }
    return world;
}

// Forward vẽ được một đèn hướng: lấy đèn đầu của cảnh (OGRE ghi hướng tia sáng đi, render::Light
// ghi hướng TỚI đèn) và trung bình ba kênh của ambient làm cường độ môi trường. Đèn directional
// thứ hai của cảnh chưa được vẽ: renderer một đèn, ghi ở docs/TIEN-DO.md bước B6.
[[nodiscard]] render::Light light_of(const Stage& stage) noexcept {
    render::Light light;
    if (!stage.suns.empty()) {
        const Sun& sun = stage.suns.front();
        const scene::Vector3& ray = sun.direction;
        light.toward = math::Vector3(-ray.x, -ray.y, -ray.z);
        light.color = math::Vector3(sun.colour.red, sun.colour.green, sun.colour.blue);
    }
    const Rgb& ambient = stage.ambient;
    light.ambient = (ambient.red + ambient.green + ambient.blue) / 3.0F;
    return light;
}

// Camera nhìn vào hộp bao thế giới từ góc quay sau elapsed giây kể từ lúc tạo; số giây đứng giữa
// hai tham số còn lại để hai số có thể hoán đổi cho nhau không nằm cạnh nhau.
[[nodiscard]] render::Camera orbit_camera(
    float elapsed, const math::Aabb& bounds, float aspect) noexcept {
    render::Orbit orbit;
    orbit.yaw = kYawStart + (elapsed * kYawPerSecond);
    orbit.pitch = kPitch;
    orbit.aspect = aspect;
    orbit.margin = kMargin;
    return render::frame_box(bounds, orbit);
}

// Lưới địa hình thành một model một nút: màu đỉnh theo độ cao, hai mặt để camera quay vẫn thấy đất.
[[nodiscard]] resource::Model model_of(const game::map::Ground& ground) {
    resource::Model model;
    resource::Mesh mesh;
    mesh.name = "dia-hinh";
    resource::Primitive primitive;
    primitive.topology = resource::Topology::kTriangles;
    primitive.material = 0;
    primitive.vertices.reserve(ground.sheet.corners.size());
    for (const game::map::Corner& corner : ground.sheet.corners) {
        resource::Vertex vertex;
        vertex.position = {.x = corner.x, .y = corner.y, .z = corner.z};
        vertex.normal = {.x = corner.normal_x, .y = corner.normal_y, .z = corner.normal_z};
        vertex.color = {.x = corner.red, .y = corner.green, .z = corner.blue, .w = 1.0F};
        primitive.vertices.push_back(vertex);
    }
    primitive.indices = ground.sheet.indices;
    mesh.primitives.push_back(std::move(primitive));
    model.meshes.push_back(std::move(mesh));
    resource::Material material;
    material.name = "dia-hinh";
    material.double_sided = true;
    model.materials.push_back(std::move(material));
    resource::Node node;
    node.name = "dia-hinh";
    node.local = math::Matrix4::identity();
    node.mesh = 0;
    model.nodes.push_back(std::move(node));
    model.roots.push_back(0);
    return model;
}

// Hộp có ít nhất một điểm (min không vượt max ở trục nào).
[[nodiscard]] bool has_points(const math::Aabb& box) noexcept {
    const math::Vector3 size = box.max - box.min;
    return size.x() >= 0.0F && size.y() >= 0.0F && size.z() >= 0.0F;
}

// Hộp local của mỗi mesh đã nạp, theo đúng thứ tự của danh sách mesh.
[[nodiscard]] std::vector<math::Aabb> local_bounds(const std::vector<LoadedMesh>& loaded) {
    std::vector<math::Aabb> local;
    local.reserve(loaded.size());
    for (const LoadedMesh& mesh : loaded) {
        local.push_back(render::bounds_of(mesh.model, mesh.drawable.rest()));
    }
    return local;
}

// Định dạng điểm ảnh của capture theo định dạng màu mà bề mặt đã chốt.
[[nodiscard]] core::Result<capture::PixelFormat> shot_format(gpu::Format colour) noexcept {
    switch (colour) {
    case gpu::Format::kRgba8Unorm:
    case gpu::Format::kRgba8UnormSrgb: return capture::PixelFormat::kRgba8;
    case gpu::Format::kBgra8Unorm:
    case gpu::Format::kBgra8UnormSrgb: return capture::PixelFormat::kBgra8;
    default: break;
    }
    return core::fail(core::ErrorCode::kUnsupported, "định dạng màu của màn hình chưa chụp được");
}

// Rào ảnh của khung qua lại giữa bố cục Present (trình bày) và CopySource (chép ra buffer).
void shot_barrier(gpu::CommandList& list, const gpu::TextureHandle& texture, bool to_copy) {
    gpu::TextureBarrier fence;
    fence.texture = texture;
    fence.stage_before = to_copy ? gpu::SyncStage::kColorOutput : gpu::SyncStage::kCopy;
    fence.stage_after = to_copy ? gpu::SyncStage::kCopy : gpu::SyncStage::kColorOutput;
    fence.access_before = to_copy ? gpu::Access::kColorWrite : gpu::Access::kCopyRead;
    fence.access_after = to_copy ? gpu::Access::kCopyRead : gpu::Access::kColorWrite;
    fence.layout_before = to_copy ? gpu::TextureLayout::kPresent : gpu::TextureLayout::kCopySource;
    fence.layout_after = to_copy ? gpu::TextureLayout::kCopySource : gpu::TextureLayout::kPresent;
    list.barrier({}, std::span(&fence, 1), {});
}

// Nộp hỏng thì buffer của ảnh chụp không bao giờ được đọc: huỷ ngay để khỏi chờ tới lúc tắt.
void discard_shot(gpu::Device& device, const std::optional<ShotPlan>& shot) noexcept {
    if (shot) device.destroy(shot->staging);
}

// ofstream nhận char; std::byte và char được phép trỏ cùng vùng nhớ.
// NOLINTBEGIN(cppcoreguidelines-pro-type-reinterpret-cast)
// Ghi nội dung nhị phân ra tệp; false khi mở tệp hoặc ghi hỏng.
[[nodiscard]] bool write_bytes(
    const std::filesystem::path& path, std::span<const std::byte> bytes) {
    std::ofstream file(path, std::ios::binary | std::ios::trunc);
    if (!file.is_open()) return false;
    const auto* const raw = reinterpret_cast<const char*>(bytes.data());
    file.write(raw, static_cast<std::streamsize>(bytes.size()));
    return file.good();
}
// NOLINTEND(cppcoreguidelines-pro-type-reinterpret-cast)

// Bàn tay bắt tay giữa Display::create (luồng thông điệp chờ) và luồng vẽ (khởi tạo rồi báo).
struct Launch {
    std::mutex mutex;
    std::condition_variable done;
    bool is_ready = false;
    bool is_ok = false;
    std::optional<core::Error> error;
};

// Kết quả dựng lại màn hình vẽ theo cỡ mới.
enum class Refit : std::uint8_t {
    // Dựng xong (hoặc không cần dựng).
    kDone,
    // Bề mặt chưa báo cỡ thật (cửa sổ giữa lúc khôi phục): chờ rồi thử lại.
    kRetry,
    // Lỗi thật; đã lưu vào outcome.
    kFailed,
};

} // namespace

// Toàn bộ trạng thái của luồng vẽ. Luồng thông điệp chỉ đọc các ô atomic cuối tệp; mọi thứ khác
// thuộc riêng luồng vẽ. Huỷ ngược thứ tự khai báo: mesh (drawable trước uploaded trước model),
// forward, screen rồi device.
struct Display::State {
    State() = default;
    State(const State&) = delete;
    State& operator=(const State&) = delete;
    State(State&&) = delete;
    State& operator=(State&&) = delete;
    ~State() = default;

    // Khởi tạo thiết bị, màn hình vẽ, renderer và nội dung; gọi trên luồng vẽ, báo kết quả qua bàn.
    [[nodiscard]] core::Status launch(const DisplayDesc& desc);
    // Thân của luồng vẽ: khởi tạo qua bàn tay bắt tay, báo kết quả, rồi quay tới khi dừng.
    void run(Launch& handshake, const DisplayDesc& desc, const std::stop_token& stop);
    // Vòng của luồng vẽ tới khi bị dừng hoặc lỗi vẽ.
    void spin(const std::stop_token& stop);
    // Một lượt của luồng vẽ, kể cả lúc cửa sổ bị che; false khi dừng vì lỗi vẽ.
    [[nodiscard]] bool turn_one(core::Clock::time_point& previous);
    // Một lượt khi cửa sổ còn hiện: dựng lại nếu vừa đổi cỡ, vẽ một khung, đo nhịp; false khi dừng.
    [[nodiscard]] bool turn(core::Clock::time_point& previous);
    // Dựng lại màn hình vẽ theo cỡ vùng vẽ mới nhất. Cửa sổ thu nhỏ (cỡ 0) thì giữ nguyên cờ.
    [[nodiscard]] core::Status fit();
    // Dựng lại qua refit(): giữa lúc khôi phục từ thu nhỏ, bề mặt có lúc còn báo cỡ 0 — chờ một
    // nhịp rồi thử lại (kRetry) thay vì coi là lỗi.
    [[nodiscard]] Refit refit();
    // Vẽ một khung: camera và đèn, rồi mọi instance; nộp và trình bày.
    [[nodiscard]] core::Status render();
    // Nộp lệnh của khung và trình bày ảnh vừa vẽ.
    [[nodiscard]] core::Status submit_frame(gpu::CommandList& list) const;
    // Nạp mọi mesh của stage, dựng instance cho từng vật thể và hộp bao thế giới.
    void load_stage();
    // Thêm lưới địa hình vào cuối danh sách mesh, một instance ma trận đơn vị.
    void append_ground();
    // Nạp một mesh vào cuối danh sách; kMissing khi bỏ. Phần tử đã vào phải đứng yên.
    [[nodiscard]] std::size_t load_mesh(const std::string& mesh);
    // Instance cho mọi vật thể có mesh nạp được, và hộp bao thế giới của chúng.
    void build_instances(const PropTable& table, std::span<const std::size_t> loaded);
    // Thêm một vật thể vào danh sách instance và mở hộp bao thế giới.
    void place_prop(const PlacedProp& prop, std::span<const std::size_t> loaded,
        std::span<const math::Aabb> local);
    // Ghi lệnh chép ảnh khung ra buffer đọc ngược; rỗng khi không chụp hoặc hỏng.
    [[nodiscard]] std::optional<ShotPlan> record_shot(gpu::CommandList& list, std::uint32_t slot);
    // Chờ GPU chép xong, đọc buffer, nén PNG và ghi tệp; lỗi được in ra.
    void finish_shot(const ShotPlan& plan) const;
    // Lưu các số báo cáo cho luồng thông điệp đọc không khoá.
    void publish() noexcept;
    // In một dòng tổng kết khoảng thời gian khung; gọi một lần lúc dừng.
    void report_frames() const;
    // Lưu lỗi vẽ của luồng vào outcome (giữ lỗi đầu tiên).
    void keep(const core::Status& failure) noexcept;
    // Cuối vòng đời của luồng vẽ: lưu số cuối, chờ GPU rỗi, giữ lỗi đầu tiên. Không join.
    void wrap_up();
    // Dừng khéo từ luồng thông điệp: join luồng vẽ rồi wrap_up nếu luồng chưa tự làm.
    void settle();

    // Thứ tự trường theo clang-analyzer-optin.performance.Padding. Ràng buộc vòng đời: device
    // đứng đầu nên huỷ sau mọi thứ gọi destroy của nó; spinner gần cuối, mọi trường đứng sau nó
    // chỉ được luồng vẽ đụng sau khi settle đã join (Display luôn settle trước khi huỷ State).

    // Hộp bao thế giới của mọi instance, cho camera quay quanh; ánh sáng lấy một lần từ stage.
    math::Aabb world;
    render::Light light{};
    std::unique_ptr<gpu::Device> device;
    std::unique_ptr<render::Screen> screen;
    std::unique_ptr<render::Forward> forward;
    // Nội dung vẽ: mượn từ lúc create.
    const Stage* stage = nullptr;
    const game::map::Ground* ground = nullptr;
    core::Clock::time_point started;
    std::atomic<PackedSize> posted_size{0};
    // Số khung bỏ vì bề mặt đã đổi cỡ (chưa kịp dựng lại): quay nhiều nghĩa là đường này bị
    // bão hoà — từng là vòng quay vô hạn ăn trọn một lõi (đã đo bằng drive_window.py).
    std::uint64_t stale_frames = 0;
    std::atomic<std::uint64_t> reported_faults{0};
    // Mesh nạp một lần; instance của từng vật thể trỏ drawable của mesh ấy.
    std::vector<LoadedMesh> meshes;
    std::vector<render::Instance> instances;
    // Khoảng thời gian từng khung (ms) để in tổng kết lúc thoát: chẩn đoán giật.
    std::vector<double> frame_ms;
    // Luồng vẽ; join trong settle.
    std::jthread spinner;
    std::filesystem::path data_root;
    std::filesystem::path shot_path;
    std::string reported_description;
    std::mutex outcome_guard;
    core::Status outcome{core::ok()};
    std::atomic<std::uint32_t> reported_draws{0};
    // Khung vừa rồi có bị bỏ vì bề mặt đã đổi cỡ không; render() ghi, vòng quay đọc ngay sau.
    bool stale_flag = false;
    // Ảnh chụp (--shot): chụp đúng một lần ở khung đầu vẽ được.
    bool shot_taken = false;
    // Cỡ vùng vẽ mới nhất và cờ đổi cỡ từ luồng thông điệp.
    std::atomic<bool> is_resize_pending{false};
    // Luồng vẽ còn quay: sai nghĩa là lỗi vẽ hoặc thiết bị mất, vòng cửa sổ nên dừng.
    std::atomic<bool> is_spinning{false};
    bool is_wrapped = false;
};

Display::Display(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}
Display::Display(Display&&) noexcept = default;
Display& Display::operator=(Display&&) noexcept = default;
Display::~Display() {
    if (state_ == nullptr) return;
    try {
        state_->settle();
    } catch (...) {
        // Huỷ tử không được ném; dừng luồng vẽ mà lỗi thì chỉ còn kịp nói ra bằng log.
        static_cast<void>(std::fputs("Lỗi khi dừng luồng vẽ\n", stderr));
    }
}

core::Result<Display> Display::create(const DisplayDesc& desc) {
    if (desc.window == nullptr) {
        return core::fail(core::ErrorCode::kInvalidArgument, "phần hiển thị thiếu cửa sổ");
    }
    auto state = std::make_unique<State>();
    // Luồng giữ con trỏ thô của chính State (đối tượng heap, thuộc Display, luồng bị join trước
    // khi nó bị huỷ); giữ unique_ptr cục bộ thì nó hoá null ngay khi create trả về.
    State* const home = state.get();
    Launch launch;
    // jthread chỉ gọi được khi lời gọi nhận stop_token theo giá trị; ở đây chỉ chuyển tiếp cho
    // State::run, không giữ bản sao.
    // NOLINTNEXTLINE(performance-unnecessary-value-param)
    auto born = [home, &launch, &desc](std::stop_token stop) { home->run(launch, desc, stop); };
    state->spinner = std::jthread(std::move(born));
    std::unique_lock<std::mutex> waiting(launch.mutex);
    launch.done.wait(waiting, [&launch] { return launch.is_ready; });
    if (launch.is_ok) return Display(std::move(state));
    if (launch.error.has_value()) return std::unexpected(std::move(*launch.error));
    return core::fail(core::ErrorCode::kInternal, "luồng vẽ không báo kết quả khởi tạo");
}

void Display::notify_resized(PixelSize size) noexcept {
    state_->posted_size.store(pack(size), std::memory_order_relaxed);
    state_->is_resize_pending.store(true, std::memory_order_relaxed);
}

core::Status Display::finish() {
    state_->settle();
    const std::scoped_lock<std::mutex> locked(state_->outcome_guard);
    return state_->outcome;
}

std::uint64_t Display::validation_errors() const noexcept {
    return state_->reported_faults.load(std::memory_order_relaxed);
}

std::uint32_t Display::draw_count() const noexcept {
    return state_->reported_draws.load(std::memory_order_relaxed);
}

bool Display::is_spinning() const noexcept {
    return state_->is_spinning.load(std::memory_order_relaxed);
}

std::string Display::description() const {
    return state_->reported_description;
}

core::Status Display::State::launch(const DisplayDesc& desc) {
    gpu::DeviceDesc device_desc;
    device_desc.is_validated = desc.is_validated;
    core::Result<std::unique_ptr<gpu::Device>> made = gpu::create_present_device(device_desc);
    if (!made) return std::unexpected(made.error());
    device = std::move(*made);
    render::ScreenDesc screen_desc;
    screen_desc.window = desc.window;
    screen_desc.width = desc.size.width;
    screen_desc.height = desc.size.height;
    screen_desc.samples = kSamples;
    screen_desc.clear = kBackdrop;
    core::Result<render::Screen> shown = render::Screen::create(*device, screen_desc);
    if (!shown) return std::unexpected(shown.error());
    screen = std::make_unique<render::Screen>(std::move(*shown));
    core::Result<render::Forward> pass = make_forward(*device, *screen, desc.data_root);
    if (!pass) return std::unexpected(pass.error());
    forward = std::make_unique<render::Forward>(std::move(*pass));
    stage = desc.stage;
    ground = desc.ground;
    data_root = desc.data_root;
    shot_path = desc.shot_path;
    light = desc.stage != nullptr ? light_of(*desc.stage) : render::Light{};
    load_stage();
    started = core::Clock::now();
    const gpu::AdapterInfo& adapter = device->adapter();
    reported_description =
        std::format("{} trên {}, có forward", gpu::name(adapter.backend), adapter.name);
    posted_size.store(pack(desc.size), std::memory_order_relaxed);
    return core::ok();
}

void Display::State::run(Launch& handshake, const DisplayDesc& desc, const std::stop_token& stop) {
    const core::Status made = launch(desc);
    {
        const std::scoped_lock<std::mutex> locked(handshake.mutex);
        handshake.is_ok = made.has_value();
        if (!made) handshake.error = made.error();
        handshake.is_ready = true;
    }
    handshake.done.notify_one();
    if (!made) return;
    is_spinning.store(true, std::memory_order_relaxed);
    frame_ms.reserve(8192);
    spin(stop);
    is_spinning.store(false, std::memory_order_relaxed);
    wrap_up();
}

void Display::State::spin(const std::stop_token& stop) {
    core::Clock::time_point previous = core::Clock::now();
    bool is_running = !stop.stop_requested();
    while (is_running) {
        is_running = turn_one(previous) && !stop.stop_requested();
    }
}

// Một lượt của luồng vẽ, kể cả lúc cửa sổ bị che; false khi dừng vì lỗi vẽ.
[[nodiscard]] bool Display::State::turn_one(core::Clock::time_point& previous) {
    const PixelSize size = unpack(posted_size.load(std::memory_order_relaxed));
    const bool is_hidden = size.width == 0 || size.height == 0;
    if (is_hidden) {
        nap(previous);
        return true;
    }
    return turn(previous);
}

bool Display::State::turn(core::Clock::time_point& previous) {
    const bool wants_fit = is_resize_pending.exchange(false, std::memory_order_relaxed);
    const Refit state = wants_fit ? refit() : Refit::kDone;
    if (state == Refit::kFailed) return false;
    if (state == Refit::kRetry) {
        nap(previous);
        return true;
    }
    const core::Status frame = render();
    const core::Clock::time_point now = core::Clock::now();
    const bool is_stale = frame && stale_flag;
    if (is_stale) {
        // Bề mặt đã đổi cỡ giữa chừng: chờ cỡ mới tới rồi dựng lại, không quay cứng chờ nó.
        ++stale_frames;
        is_resize_pending.store(true, std::memory_order_relaxed);
        nap(previous);
        return true;
    }
    frame_ms.push_back(std::chrono::duration<double, std::milli>(now - previous).count());
    previous = now;
    publish();
    if (!frame) {
        keep(frame);
        return false;
    }
    return true;
}

void Display::State::load_stage() {
    if (stage != nullptr && !data_root.empty()) {
        const PropTable table = table_of(*stage);
        meshes.reserve(table.meshes.size() + 1);
        std::vector<std::size_t> loaded(table.meshes.size(), kMissing);
        for (std::size_t index = 0; index < table.meshes.size(); ++index) {
            loaded.at(index) = load_mesh(table.meshes.at(index));
        }
        build_instances(table, loaded);
    }
    append_ground();
    std::println(
        "Nạp cảnh: {} mesh dùng chung, {} vật thể vẽ được", meshes.size(), instances.size());
}

void Display::State::append_ground() {
    if (ground == nullptr || ground->sheet.indices.empty()) return;
    meshes.emplace_back();
    LoadedMesh& slot = meshes.back();
    slot.model = model_of(*ground);
    auto uploaded = resource::upload(*device, slot.model);
    if (!uploaded) {
        std::println(stderr, "Bỏ địa hình (tải lên GPU): {}", uploaded.error());
        meshes.pop_back();
        return;
    }
    slot.uploaded = std::move(*uploaded);
    auto drawable = forward->prepare(slot.model, slot.uploaded);
    if (!drawable) {
        std::println(stderr, "Bỏ địa hình (chuẩn bị vẽ): {}", drawable.error());
        meshes.pop_back();
        return;
    }
    slot.drawable = std::move(*drawable);
    render::Instance instance;
    instance.drawable = &slot.drawable;
    instance.world = math::Matrix4::identity();
    instances.push_back(instance);
    const math::Aabb local = render::bounds_of(slot.model, slot.drawable.rest());
    if (!has_points(local)) return;
    const math::Aabb moved = math::transform(local, instance.world);
    world.min = math::min(world.min, moved.min);
    world.max = math::max(world.max, moved.max);
    std::println("Địa hình: {}x{} ô, {} tam giác", ground->file.x_size, ground->file.z_size,
        ground->triangle_count());
}

std::size_t Display::State::load_mesh(const std::string& mesh) {
    const std::filesystem::path path =
        data_root / io::path_from_utf8("Model") / io::path_from_utf8(mesh + ".glb");
    auto model = resource::load_glb_file(io::utf8_of(path), io::utf8_of(data_root));
    if (!model) {
        std::println(stderr, "Bỏ mesh {}: {}", mesh, model.error());
        return kMissing;
    }
    meshes.emplace_back();
    LoadedMesh& slot = meshes.back();
    slot.model = std::move(*model);
    auto uploaded = resource::upload(*device, slot.model);
    if (!uploaded) {
        std::println(stderr, "Bỏ mesh {} (tải lên GPU): {}", mesh, uploaded.error());
        meshes.pop_back();
        return kMissing;
    }
    slot.uploaded = std::move(*uploaded);
    auto drawable = forward->prepare(slot.model, slot.uploaded);
    if (!drawable) {
        std::println(stderr, "Bỏ mesh {} (chuẩn bị vẽ): {}", mesh, drawable.error());
        meshes.pop_back();
        return kMissing;
    }
    slot.drawable = std::move(*drawable);
    return meshes.size() - 1;
}

void Display::State::place_prop(const PlacedProp& prop, std::span<const std::size_t> loaded,
    std::span<const math::Aabb> local) {
    const std::size_t index = core::at(loaded, prop.mesh);
    if (index == kMissing || !has_points(core::at(local, index))) return;
    render::Instance instance;
    instance.drawable = &meshes.at(index).drawable;
    instance.world = world_of(prop.world);
    instances.push_back(instance);
    const math::Aabb moved = math::transform(core::at(local, index), instance.world);
    world.min = math::min(world.min, moved.min);
    world.max = math::max(world.max, moved.max);
}

void Display::State::build_instances(const PropTable& table, std::span<const std::size_t> loaded) {
    const std::vector<math::Aabb> local = local_bounds(meshes);
    instances.reserve(table.props.size());
    for (const PlacedProp& prop : table.props) {
        place_prop(prop, loaded, local);
    }
}

core::Status Display::State::fit() {
    const PixelSize size = unpack(posted_size.load(std::memory_order_relaxed));
    if (size.width == 0 || size.height == 0) return core::ok();
    return screen->resize(size.width, size.height);
}

Refit Display::State::refit() {
    const core::Status fitted = fit();
    const bool is_pending = !fitted && (screen->width() == 0 || screen->height() == 0);
    if (is_pending) {
        // Bề mặt chưa báo cỡ thật: xin thử lại ở lượt sau.
        is_resize_pending.store(true, std::memory_order_relaxed);
        return Refit::kRetry;
    }
    if (!fitted) {
        keep(fitted);
        return Refit::kFailed;
    }
    return Refit::kDone;
}

core::Status Display::State::render() {
    stale_flag = false;
    const core::Result<gpu::CommandList*> list = device->begin_commands(gpu::QueueType::kGraphics);
    if (!list) return std::unexpected(list.error());
    const core::Result<std::uint32_t> slot = screen->begin(**list);
    // Bề mặt đổi cỡ giữa chừng: bỏ khung này, spin() dựng lại ở khung kế.
    const bool is_stale = !slot && slot.error().code() == core::ErrorCode::kInvalidState;
    stale_flag = is_stale;
    if (is_stale) return device->end_frame();
    if (!slot) return std::unexpected(slot.error());
    const auto width = static_cast<float>(screen->width());
    const auto height = static_cast<float>(screen->height());
    const float elapsed = std::chrono::duration<float>(core::Clock::now() - started).count();
    const render::Camera camera =
        height > 0.0F ? orbit_camera(elapsed, world, width / height) : render::Camera{};
    const core::Status drawn = forward->draw(**list, *slot, camera, light, instances);
    if (!drawn) return drawn;
    screen->end(**list);
    const std::optional<ShotPlan> shot = record_shot(**list, *slot);
    const core::Status submitted = submit_frame(**list);
    if (!submitted) {
        discard_shot(*device, shot);
        return submitted;
    }
    if (shot) finish_shot(*shot);
    return device->end_frame();
}

core::Status Display::State::submit_frame(gpu::CommandList& list) const {
    const std::array<gpu::CommandList*, 1> one{&list};
    gpu::SubmitDesc submit;
    submit.lists = one;
    submit.present_target = screen->swapchain();
    const core::Status sent = device->submit(gpu::QueueType::kGraphics, submit);
    if (!sent) return sent;
    return screen->present();
}

std::optional<ShotPlan> Display::State::record_shot(gpu::CommandList& list, std::uint32_t slot) {
    if (shot_taken || shot_path.empty()) return std::nullopt;
    shot_taken = true;
    const gpu::Format colour = screen->color_format();
    const std::uint32_t width = screen->width();
    const std::uint32_t height = screen->height();
    const auto format = shot_format(colour);
    if (!format) {
        std::println(stderr, "Lỗi chụp {}: {}", io::utf8_of(shot_path), format.error());
        return std::nullopt;
    }
    const std::uint64_t stride = gpu::padded_row_bytes(colour, width);
    gpu::BufferDesc buffer;
    buffer.name = "client.shot.readback";
    buffer.size = stride * height;
    buffer.usage = gpu::BufferUsage::kCopyDest;
    buffer.memory = gpu::MemoryDomain::kReadback;
    const auto made = device->create_buffer(buffer);
    if (!made) {
        std::println(stderr, "Lỗi chụp {}: {}", io::utf8_of(shot_path), made.error());
        return std::nullopt;
    }
    const gpu::TextureHandle image = screen->swapchain()->image(slot);
    shot_barrier(list, image, true);
    gpu::BufferTextureCopy region;
    region.width = width;
    region.height = height;
    list.copy_texture_to_buffer(image, *made, std::span(&region, 1));
    shot_barrier(list, image, false);
    return ShotPlan{.staging = *made,
        .size = buffer.size,
        .stride = stride,
        .width = width,
        .height = height,
        .format = *format};
}

void Display::State::finish_shot(const ShotPlan& plan) const {
    const core::Status waited = device->wait_idle();
    if (!waited) {
        std::println(stderr, "Lỗi chụp {}: {}", io::utf8_of(shot_path), waited.error());
        return;
    }
    std::vector<std::byte> pixels(plan.size);
    const core::Status read = device->read_buffer(plan.staging, 0, pixels);
    device->destroy(plan.staging);
    if (!read) {
        std::println(stderr, "Lỗi chụp {}: {}", io::utf8_of(shot_path), read.error());
        return;
    }
    const capture::FrameView taken{.pixels = pixels,
        .width = plan.width,
        .height = plan.height,
        .stride = plan.stride,
        .format = plan.format};
    capture::PngOptions options;
    options.alpha = false;
    const auto png = capture::encode_png(taken, options);
    if (!png) {
        std::println(stderr, "Lỗi chụp {}: {}", io::utf8_of(shot_path), png.error());
        return;
    }
    if (!write_bytes(shot_path, *png)) {
        std::println(stderr, "Lỗi chụp {}: không ghi được tệp", io::utf8_of(shot_path));
        return;
    }
    std::println("Đã ghi ảnh chụp {} ({} byte)", io::utf8_of(shot_path), png->size());
}

void Display::State::publish() noexcept {
    reported_faults.store(device->validation_errors(), std::memory_order_relaxed);
    reported_draws.store(forward->draw_count(), std::memory_order_relaxed);
}

void Display::State::keep(const core::Status& failure) noexcept {
    const std::scoped_lock<std::mutex> locked(outcome_guard);
    if (outcome) outcome = failure;
}

void Display::State::wrap_up() {
    if (is_wrapped || device == nullptr) return;
    is_wrapped = true;
    publish();
    report_frames();
    const core::Status waited = device->wait_idle();
    const std::scoped_lock<std::mutex> locked(outcome_guard);
    if (outcome) outcome = waited;
}

// Một dòng tổng kết khoảng thời gian khung: giật hiện ra ngay ở p95 và số khung trần 20 ms.
void Display::State::report_frames() const {
    if (frame_ms.size() < 8) return;
    std::vector<double> sorted = frame_ms;
    std::ranges::sort(sorted);
    const auto percentile = [&sorted](double part) noexcept {
        const auto index = static_cast<std::size_t>(part * static_cast<double>(sorted.size() - 1));
        return sorted.at(index);
    };
    const auto over = static_cast<std::size_t>(
        std::ranges::count_if(sorted, [](double millis) noexcept { return millis > 20.0; }));
    std::println("Khung hình: trung vị {:.1f} ms, p95 {:.1f} ms, max {:.1f} ms, {} trên {} khung "
                 "quá 20 ms, {} khung bỏ vì đổi cỡ",
        percentile(0.5), percentile(0.95), sorted.back(), over, sorted.size(), stale_frames);
}

void Display::State::settle() {
    if (spinner.joinable()) {
        spinner.request_stop();
        spinner.join();
    }
    wrap_up();
}

} // namespace game::client
