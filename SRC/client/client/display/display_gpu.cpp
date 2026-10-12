// check.py dịch tệp này một mình, không kèm -msse4.1 mà CMake gắn vào game_math.
// Chỉ cho x86-64: đích ARM không có tính năng này, clang in cảnh báo rồi bỏ qua.
#if defined(__clang__) && defined(__x86_64__)
#pragma clang attribute push(__attribute__((target("sse4.1"))), apply_to = function)
#elif defined(__GNUC__) && defined(__x86_64__)
#pragma GCC target("sse4.1")
#endif
// Bản có chuỗi đồ hoạ: MỘT LUỒNG VẼ riêng giữ thiết bị của module gpu (xin backend rồi fallback,
// lớp kiểm tra theo yêu cầu), màn hình vẽ và render::Forward, và quay đều mỗi khung tới khi bị
// dừng. Luồng thông điệp của cửa sổ không chạm GPU nữa: kéo hay đổi cỡ cửa sổ không bao giờ đứng
// chờ vblank. Luồng vẽ khởi tạo thiết bị rồi trả cửa sổ ngay. Đọc đĩa và nướng địa hình chạy ở
// luồng nền, nhiều file một lúc; mỗi khung chỉ nộp GPU phần đã đọc xong. Mesh nào nộp xong thì
// hiện ngay. Map đang xem vẫn vẽ cho tới khi địa hình map mới lên GPU.
// Mỗi khung: đổi cỡ nếu cửa sổ vừa báo, xử lý sự kiện chuột, chạm và phím theo thứ tự tới, dời
// nhân vật rồi đặt camera cảnh của client 2026 (control/follow_camera và control/player_input; cảnh
// không có địa hình thì camera quay quanh hộp bao), đèn đầu và ambient của cảnh, vẽ mọi instance,
// nộp và trình bày;
// --shot chụp khung đầu sau khi mesh của cảnh đã vào hết. Vòng acquire–vẽ–present
// theo tools/view/main.cpp của Forge2; begin trả kInvalidState khi bề mặt đã đổi cỡ là đường chạy
// thường ngày, khung ấy bị bỏ và màn hình vẽ được dựng lại sau.
#include "client/display/display.hpp"
#include "client/display/fx_view.hpp"
#include "client/display/lighting.hpp"
#include "client/display/login_data.hpp"
#include "client/map/gates.hpp"
#include "client/map/ground.hpp"
#include "client/map/picture.hpp"
#include "client/map/sheet.hpp"
#include "client/map/surface.hpp"
#include "client/map/terrain.hpp"
#include "client/world/world.hpp"
#include "control/char_camera.hpp"
#include "fx/field.hpp"
#include "fx/mesh.hpp"
#include "fx/system.hpp"

#include "capture/frame.hpp"
#include "capture/png.hpp"
#include "client/display/player.hpp"
#include "client/display/portrait.hpp"
#include "client/display/role_preview.hpp"
#include "client/display/role_stage.hpp"
#include "client/map/samples.hpp"
#include "client/stage/props.hpp"
#include "client/stage/stage.hpp"
#include "control/cursor_rules.hpp"
#include "control/follow_camera.hpp"
#include "control/ground.hpp"
#include "control/input.hpp"
#include "control/login_view.hpp"
#include "control/player_input.hpp"
#include "control/stick.hpp"
#include "control/view_ray.hpp"
#include "core/bits.hpp"
#include "core/clock.hpp"
#include "core/error.hpp"
#include "core/ground_point.hpp"
#include "core/hash.hpp"
#include "core/system.hpp"
#include "core/text.hpp"
#include "gpu/barrier.hpp"
#include "gpu/command.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"
#include "gui/sheet.hpp"
#include "gui/strings.hpp"
#include "hero/hero.hpp"
#include "io/file.hpp"
#include "look/appearance.hpp"
#include "look/look.hpp"
#include "math/geometry.hpp"
#include "math/matrix.hpp"
#include "math/quat.hpp"
#include "math/vector.hpp"
#include "motion/motion.hpp"
#include "nav/finder.hpp"
#include "nav/route.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"
#include "render/camera.hpp"
#include "render/catalog.hpp"
#include "render/forward.hpp"
#include "render/screen.hpp"
#include "render/ui.hpp"
#include "render/view_size.hpp"
#include "resource/classic.hpp"
#include "resource/image.hpp"
#include "resource/model.hpp"
#include "resource/upload.hpp"
#include "scene/placement.hpp"
#include "scene/transform.hpp"
#include "shader/package.hpp"
#include "ui/hud.hpp"
#include "ui/pace.hpp"
#include "ui/panel/role_pose.hpp"
#include "ui/panel/roles.hpp"
#include "ui/view.hpp"

#ifdef __ANDROID__
#include <android/log.h>
#endif
#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cmath>
#include <condition_variable>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <deque>
#include <expected>
#include <filesystem>
#include <format>
#include <fstream>
#include <ios>
#include <iterator>
#include <limits>
#include <memory>
#include <mutex>
#include <numbers>
#include <optional>
#include <print>
#include <ranges>
#include <ratio>
#include <span>
#include <stop_token>
#include <string>
#include <string_view>
#include <system_error>
#include <thread>
#include <unordered_map>
#include <utility>
#include <vector>

namespace game::client {

using TimePoint = core::Clock::time_point;
using MatrixRow = std::span<const double, 4>;
using ByteSpan = std::span<const std::byte>;

namespace {

// Màu nền, ánh sáng tuyến tính; đích vẽ là định dạng sRGB nên màu hiện ra sáng hơn con số này.
constexpr gpu::ClearColor kBackdrop{.red = 0.05F, .green = 0.06F, .blue = 0.08F, .alpha = 1.0F};
// Nghỉ giữa hai khung khi cửa sổ đang thu nhỏ, hoặc khi bề mặt chưa sẵn cỡ.
constexpr std::chrono::milliseconds kIdleNap{16};
// Trần nhịp vẽ trên PC: 120 Hz. Màn 60 Hz vẫn quét 60 lần, nhưng mailbox giữ khung mới nhất
// nên trễ tối đa một nửa nhịp quét. Vượt trần thì bỏ tick, không vẽ bù.
constexpr std::uint32_t kPaceHz = 120;

// Nghỉ một nhịp rồi đặt lại mốc đo: lượt sau không phải chịu thời gian ngủ.
void nap(core::Clock::time_point& previous) noexcept {
    std::this_thread::sleep_for(kIdleNap);
    previous = core::Clock::now();
}

// Khoảng giữa hai mốc đồng hồ đơn điệu, tính bằng mili giây, cho số đo của một lần nạp cảnh.
[[nodiscard]] double millis_between(TimePoint from, TimePoint stop) noexcept {
    return std::chrono::duration<double, std::milli>(stop - from).count();
}

// Một khung dài: nạp (đọc và đưa GPU), vẽ (xin ảnh, ghi lệnh, nộp), chờ nhịp (ngủ tới tick).
struct SpikeParts {
    double interval = 0.0;
    double load_ms = 0.0;
    double render_ms = 0.0;
    double pace_ms = 0.0;
    float acquire_ms = 0.0F;
    float draw_ms = 0.0F;
    float submit_ms = 0.0F;
    double prepare_ms = 0.0;
};

// In khi khung vượt một nhịp 60 Hz cộng phần dư. Khung đều 16,7 ms không in.
void report_spike(const SpikeParts& parts) {
    if (parts.interval <= 20.0) return;
    const std::string interval = std::format("{:.1f}", parts.interval);
    const std::string load_ms = std::format("{:.1f}", parts.load_ms);
    const std::string render_ms = std::format("{:.1f}", parts.render_ms);
    const std::string pace_ms = std::format("{:.1f}", parts.pace_ms);
    const std::string acquire_ms = std::format("{:.1f}", parts.acquire_ms);
    const std::string draw_ms = std::format("{:.1f}", parts.draw_ms);
    const std::string submit_ms = std::format("{:.1f}", parts.submit_ms);
    const std::string prepare_ms = std::format("{:.1f}", parts.prepare_ms);
    const std::string head = "Khung chậm " + interval + " ms: nạp " + load_ms + " ms, dựng UI ";
    const std::string body = prepare_ms + " ms, vẽ " + render_ms + " ms (xin " + acquire_ms;
    const std::string tail = ", ghi " + draw_ms + ", nộp " + submit_ms + "), chờ nhịp " + pace_ms;
    std::println("{}{}{} ms", head, body, tail);
}

struct FrameRank {
    double median = 0.0;
    double p95 = 0.0;
    double peak = 0.0;
    std::size_t under_12 = 0;
    std::size_t mid = 0;
    std::size_t over = 0;
};

[[nodiscard]] double rank_at(std::span<const double> sorted, double part) noexcept {
    const auto index = static_cast<std::size_t>(part * static_cast<double>(sorted.size() - 1));
    return sorted[index];
}

void count_band(FrameRank& rank, double millis) noexcept {
    if (millis < 12.0) ++rank.under_12;
    if (millis >= 12.0 && millis <= 20.0) ++rank.mid;
    if (millis > 20.0) ++rank.over;
}

[[nodiscard]] FrameRank rank_frames(std::span<const double> sorted) noexcept {
    FrameRank rank;
    if (sorted.empty()) return rank;
    rank.median = rank_at(sorted, 0.5);
    rank.p95 = rank_at(sorted, 0.95);
    rank.peak = sorted.back();
    for (const double millis : sorted) {
        count_band(rank, millis);
    }
    return rank;
}

void say_rank(std::string_view title, const FrameRank& rank, std::size_t count) {
    const std::string median = std::format("{:.1f}", rank.median);
    const std::string p95 = std::format("{:.1f}", rank.p95);
    const std::string peak = std::format("{:.1f}", rank.peak);
    const std::string head = std::string(title) + ": " + std::to_string(count) + " khung, trung vị ";
    const std::string mid = median + " ms, p95 " + p95 + " ms, max " + peak + " ms, ";
    const std::string low = std::to_string(rank.under_12) + " khung dưới 12 ms, ";
    const std::string band = std::to_string(rank.mid) + " khung 12–20 ms, ";
    const std::string high = std::to_string(rank.over) + " khung quá 20 ms";
    std::println("{}{}{}{}{}", head, mid, low, band, high);
}

void say_steady(std::span<const double> frames, std::size_t from) {
    const auto begin = frames.begin() + static_cast<std::ptrdiff_t>(from);
    std::vector<double> steady(begin, frames.end());
    std::ranges::sort(steady);
    say_rank("Khung sau khi cảnh hiện", rank_frames(steady), steady.size());
}
// Khử răng cưa đa mẫu 4x: cảnh đá chi tiết quay chậm mà không có nó thì cạnh và hoạ tiết lăn tăn
// từng khung, nhìn như giật dù nhịp khung đều (đã đo: median 16,6 ms). Resolve chạy trên chip.
constexpr std::uint32_t kSamples = 4;
// Trần nộp mesh trong một khung. Dev dùng 8 ms: 2 ms thì cảnh lớn hiện chậm vì việc bị xé vụn,
// quá 8 ms thì khung 120 Hz trượt một nhịp. Địa hình ngồi một khung riêng, không cộng vào đây.
constexpr std::chrono::milliseconds kLoadSlice{8};
// Địa hình GPU của từng cảnh vừa xem. Trùng kRemembered của world: đổi lại không tải lại.
constexpr std::size_t kKeptGrounds = 4;
// Camera quay quanh cảnh khi chưa có mặt đất để đứng: góc ban đầu và tốc độ quay mỗi giây. Theo
// đồng hồ đơn điệu chứ không theo số khung: cùng một tốc độ trên mọi tần số quét, và một khung bị
// bỏ (đang kéo cửa sổ, máy bận) không để lại cú giật bù.
constexpr float kYawStart = 0.6F;
constexpr float kYawPerSecond = 0.24F;
// Android và iOS trình Fifo theo Hz của tấm nền (60, 90 hay 120). Ngủ thêm 120 Hz sau Fifo làm
// khung trễ mất nhịp quét. PC mới dùng mailbox và trần 120 Hz.
#if defined(__ANDROID__)
constexpr bool kIsMobile = true;
#elif defined(__APPLE__)
constexpr bool kIsMobile = TARGET_OS_IPHONE != 0;
#else
constexpr bool kIsMobile = false;
#endif
// Số sự kiện chuột hay chạm chờ tối đa giữa hai khung; quá thì bỏ sự kiện mới.
constexpr std::size_t kMaxQueued = 4096;
// Bước thời gian dài nhất của một khung, giây: máy khựng không làm điểm nhìn nhảy xa.
constexpr float kMaxStep = 0.1F;
// Số nấc lăn dồn tối đa cho giao diện giữa hai khung (xem State::hud_wheel).
constexpr std::int32_t kHudWheelCap = 16;
// Chỉ số mesh không nạp được trong bảng ánh xạ tên mesh sang kết quả nạp.
constexpr std::size_t kMissing = std::numeric_limits<std::size_t>::max();

using ForwardResult = core::Result<render::Forward>;
using UiResult = core::Result<render::UiPass>;

// Một mesh đã nạp và tải lên GPU. Drawable giữ địa chỉ của model và uploaded cùng phần tử nên
// phần tử phải đứng yên: vector chứa chúng được reserve đủ trước khi nạp.
struct LoadedMesh {
    resource::Model model;
    resource::Uploaded uploaded;
    render::Drawable drawable;
};

// Mesh prop đứng trong deque: thêm mesh mới không đổi địa chỉ drawable của mesh cũ.
struct KeptMesh {
    LoadedMesh loaded;
    math::Aabb bounds{};
};

struct KeptGround {
    int scene_id = 0;
    KeptMesh mesh;
};

struct Crowd {
    const render::Drawable* drawable = nullptr;
    std::vector<math::Matrix4> worlds;
};

// Cảnh đang chảy vào GPU. Map cũ vẫn vẽ tới khi revealed: lúc ấy địa hình mới thế chỗ.
struct Arrival {
    std::shared_ptr<const world::ShownScene> scene;
    PropTable table;
    // Chỉ số prop dùng mỗi mesh của bảng, để mesh xong là đặt ngay, không quét lại cả cảnh.
    std::vector<std::vector<std::size_t>> users;
    std::vector<std::size_t> loaded;
    // Chỉ số đám trong crowds, theo chỉ số mesh đã nằm trong kept.
    std::vector<std::size_t> crowd_of;
    std::size_t cursor = 0;
    // Epoch của Feed: kết quả đọc của lần nạp khác bị bỏ.
    std::uint64_t epoch = 0;
    // Ô trong Feed cho mesh chưa có trong nhớ. kMissing là mesh đã có, loaded đã ghi chỉ số.
    std::vector<std::size_t> feed_slot;
    core::Clock::time_point started;
    // Số đo của lần nạp, in một dòng lúc xong. Ba phần này giải thích trọn thời gian nạp: chờ luồng
    // đọc trả mesh (stall_ms), dựng tài nguyên GPU cho mesh (place_ms) và đặt vật thể vào danh sách
    // vẽ (show_ms). load_frames cho biết thời gian nạp bị nhịp màn hình chia nhỏ tới mức nào.
    core::Clock::time_point stall_started;
    double ground_ms = 0.0;
    double stall_ms = 0.0;
    double place_ms = 0.0;
    double show_ms = 0.0;
    // Riêng phần đưa model địa hình đã nướng lên GPU, nằm trong ground_ms.
    double seat_ms = 0.0;
    std::uint64_t load_frames = 0;
    bool is_stalled = false;
    bool ground_done = false;
    bool revealed = false;
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

// Thời gian mỗi khung chia theo ba chặng, cộng dồn để in trung bình lúc thoát: chặng nào chiếm
// phần lớn là chặng đang chặn nhịp khung.
struct PhaseSums {
    double acquire = 0.0;
    double draw = 0.0;
    double submit = 0.0;
    std::uint64_t frames = 0;
};

// Cỡ vùng vẽ gói trong một số nguyên để luồng thông điệp trao cho luồng vẽ không khoá.
using PackedSize = std::uint64_t;

[[nodiscard]] PackedSize pack(PixelSize size) noexcept {
    return (static_cast<PackedSize>(size.width) << 32U) | size.height;
}

[[nodiscard]] PixelSize unpack(PackedSize packed) noexcept {
    const auto width = static_cast<std::uint32_t>(packed >> 32U);
    const auto height = static_cast<std::uint32_t>(packed & 0xFFFF'FFFFU);
    return {.width = width, .height = height};
}

// Thư mục gói shader của một thư mục dữ liệu: data/shaders (Android giải nén từ APK); không có thì
// rỗng và bộ vẽ dùng mặc định cạnh exe (bố cục CLIENT/bin với CLIENT/data của Windows).
[[nodiscard]] std::string shader_dir_of(const std::filesystem::path& data_root) {
    const std::filesystem::path packaged = data_root / "shaders";
    std::error_code ignored;
    return std::filesystem::exists(packaged, ignored) ? packaged.string() : std::string{};
}

[[nodiscard]] ForwardResult make_forward(gpu::Device& device, const render::Screen& screen, std::string shaders,
    std::array<gpu::PipelineHandle, render::kModelVariants> models) {
    render::ForwardDesc pass;
    pass.color_format = screen.color_format();
    pass.depth_format = screen.depth_format();
    // Nửa đầu cho lượt vẽ màn hình (theo ảnh swapchain), nửa sau cho lượt vẽ ảnh đầu 3D.
    pass.slots = screen.image_count() * 2;
    pass.samples = screen.samples();
    // Backend GLES là chế độ di động (tablet PowerVR): ánh sáng tính ở đỉnh để giữ nhịp khung.
    pass.lights_at_vertices = device.adapter().backend == gpu::Backend::kGles;
    pass.shader_dir = std::move(shaders);
    return render::Forward::create(device, pass, models);
}

// Lượt vẽ 2D của giao diện: cùng đích vẽ và thư mục shader với Forward.
[[nodiscard]] UiResult make_ui(gpu::Device& device, const render::Screen& screen, std::string shaders,
    gpu::PipelineHandle pipeline) {
    render::UiDesc pass;
    pass.color_format = screen.color_format();
    pass.depth_format = screen.depth_format();
    pass.slots = screen.image_count();
    pass.samples = screen.samples();
    pass.shader_dir = std::move(shaders);
    return render::UiPass::create(device, pass, pipeline);
}

// Một hàng của phép đặt như vùng nhìn bốn số, có kiểm biên ở mọi cấu hình.
[[nodiscard]] MatrixRow row_of(const scene::Transform& placed, std::size_t row) noexcept {
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

// Camera quay quanh hộp bao thế giới, ở góc quay sau elapsed giây kể từ lúc tạo. Hộp rỗng thì quay
// quanh gốc với bán kính 1.
[[nodiscard]] render::Camera orbit_view(float elapsed, const math::Aabb& bounds, render::ViewSize size) noexcept {
    const math::Vector3 extent = bounds.max - bounds.min;
    const bool is_empty = extent.x() < 0.0F || extent.y() < 0.0F || extent.z() < 0.0F;
    const float half = is_empty ? 0.0F : math::length(extent) * 0.5F;
    render::Orbit orbit;
    orbit.centre = is_empty ? math::Vector3(0.0F) : (bounds.min + bounds.max) * 0.5F;
    orbit.radius = half > 0.0F ? half : 1.0F;
    orbit.angle = kYawStart + (elapsed * kYawPerSecond);
    return render::orbit_camera(orbit, size);
}

// Lệnh đi: các điểm phải lần lượt tới, đơn vị game (một ô lưới); next là điểm đang hướng tới. Bất
// biến: next nhỏ hơn số điểm của path.
struct WalkOrder {
    nav::Path path;
    std::size_t next = 0;
};

// Vị trí đi bộ. Đổi cảnh thì đứng ở điểm đến của cổng khi bảng chốt được một điểm; không thì ô
// trống gần giữa map. Hướng 0,4 không lấy từ cột 11 vì hàm tra cổng không đọc cột đó.
struct WalkPose {
    int scene_id = -1;
    float x = 0.0F;
    float z = 0.0F;
    float yaw = 0.4F;
};

struct FrameAsk {
    float elapsed = 0.0F;
    render::ViewSize size;
};

using MapGround = game::client::map::Ground;

[[nodiscard]] bool scale_ok(const map::TerrainFile& file) noexcept {
    if (file.x_size <= 0 || file.z_size <= 0) return false;
    return file.scale.x > 0.0F && file.scale.z > 0.0F;
}

// Chỗ đứng hiện tại, đơn vị game. Axis_Trans GFX sang GAME, chỉ X và Z.
[[nodiscard]] core::GroundPoint game_of(const map::TerrainFile& file, const WalkPose& pose) noexcept {
    return {.x = (pose.x - file.origin.x) / file.scale.x, .z = (pose.z - file.origin.z) / file.scale.z};
}

[[nodiscard]] bool cell_open_index(const MapGround& ground, int index) noexcept {
    if (index < 0) return false;
    const auto slot = static_cast<std::size_t>(index);
    if (slot >= ground.grid.cells.size()) return false;
    return ground.grid.cells[slot].base.pixmap != 0;
}

[[nodiscard]] int find_open(const MapGround& ground) noexcept {
    const int columns = std::max(ground.file.x_size, 1);
    const int count = columns * std::max(ground.file.z_size, 0);
    int index = 0;
    while (index < count && !cell_open_index(ground, index)) {
        ++index;
    }
    if (index >= count) return 0;
    return index;
}

void apply_stand(WalkPose& pose, const map::TerrainFile& file, int scene_id, map::GateStand stand) noexcept {
    map::PlanFrame frame;
    frame.origin_x = file.origin.x;
    frame.origin_z = file.origin.z;
    frame.scale_x = file.scale.x;
    frame.scale_z = file.scale.z;
    map::GameCell cell;
    cell.x = stand.x;
    cell.z = stand.z;
    const map::WorldPoint world = map::plan_to_world(frame, cell);
    pose.x = world.x;
    pose.z = world.z;
    pose.yaw = 0.4F;
    pose.scene_id = scene_id;
}

void place_walk(WalkPose& pose, const MapGround& ground, int scene_id, map::GateStand stand) noexcept {
    if (stand.has && scale_ok(ground.file)) {
        apply_stand(pose, ground.file, scene_id, stand);
        return;
    }
    const int columns = std::max(ground.file.x_size, 1);
    const int rows = std::max(ground.file.z_size, 0);
    const int center = ((rows / 2) * columns) + (columns / 2);
    const int index = cell_open_index(ground, center) ? center : find_open(ground);
    const int column = index % columns;
    const int row = index / columns;
    pose.x = ground.file.origin.x + (ground.file.scale.x * (static_cast<float>(column) + 0.5F));
    pose.z = ground.file.origin.z + (ground.file.scale.z * (static_cast<float>(row) + 0.5F));
    pose.yaw = 0.4F;
    pose.scene_id = scene_id;
}

// Đổi giữa kiểu vô hướng của ogre (control) và kiểu SIMD của math (render).
[[nodiscard]] math::Point3 point_of(ogre::Vec3 value) noexcept {
    return {value.x, value.y, value.z};
}

// Tỉ lệ rộng trên cao của vùng vẽ; chiều cao 0 thì coi như khung vuông.
[[nodiscard]] float aspect_of(render::ViewSize size) noexcept {
    if (size.height == 0) return 1.0F;
    return static_cast<float>(size.width) / static_cast<float>(size.height);
}

// Thông số nhìn của tư thế camera: mắt, hướng nhìn đơn vị và góc dọc, để đổi điểm màn hình thành
// tia và để cần gạt biết hướng nhìn.
[[nodiscard]] control::Lens lens_of(const control::CameraPose& pose, float aspect) noexcept {
    const ogre::Vec3 toward = ogre::sub_vec3(pose.target, pose.eye);
    control::Lens lens;
    lens.eye = pose.eye;
    lens.forward = ogre::normalize_vec3(toward);
    lens.fov_y = pose.fov_degrees * (std::numbers::pi_v<float> / 180.0F);
    lens.aspect = aspect;
    return lens;
}

// Như CCamera_Scene::Update đặt Ogre::Camera: setPosition, lookAt, rồi mặt cắt và góc nhìn.
[[nodiscard]] render::Camera camera_of(const control::CameraPose& pose, render::ViewSize size) {
    render::Lens optics;
    optics.fov_degrees = pose.fov_degrees;
    optics.near_plane = pose.near_plane;
    optics.far_plane = pose.far_plane;
    return render::look_camera(point_of(pose.eye), point_of(pose.target), optics, size);
}

// Việc của một nút giao diện thành việc của vòng cửa sổ: bốn nút mở trang web và nút trợ giúp
// thành kOpenWeb kèm trang của nó. Khác gốc: trợ giúp của bản gốc là bảng Helper trong game
// (Helper:GotoHelper), chưa port, nên tạm mở trang web.
struct ActionRequest {
    ui::Action action;
    Request request;
};

[[nodiscard]] constexpr Request web_request(WebLink link) noexcept {
    return {.kind = RequestKind::kOpenWeb, .link = link};
}

constexpr std::array<ActionRequest, 8> kActionRequests = {{
    {.action = ui::Action::kEnterGame, .request = {.kind = RequestKind::kEnterGame}},
    {.action = ui::Action::kLeave, .request = {.kind = RequestKind::kLeave}},
    {.action = ui::Action::kOpenTopUp, .request = web_request(WebLink::kTopUp)},
    {.action = ui::Action::kOpenRegister, .request = web_request(WebLink::kRegister)},
    {.action = ui::Action::kOpenLostPassword, .request = web_request(WebLink::kLostPassword)},
    {.action = ui::Action::kOpenSecurityCard, .request = web_request(WebLink::kSecurityCard)},
    {.action = ui::Action::kOpenHelp, .request = web_request(WebLink::kHelp)},
    {.action = ui::Action::kOpenForum, .request = web_request(WebLink::kForum)},
}};

// Camera của màn đăng nhập: tư thế cố định mà client 2026 đặt thẳng lên Ogre::Camera sau khi nạp
// cảnh nền (control/login_view).
[[nodiscard]] render::Camera login_camera(render::ViewSize size) noexcept {
    const control::FixedView& fixed = control::kLoginView;
    render::Lens optics;
    optics.fov_degrees = fixed.fov_degrees;
    optics.near_plane = fixed.near_plane;
    optics.far_plane = fixed.far_plane;
    const ogre::Quat& turn = fixed.orientation;
    const math::Quat orientation(turn.x, turn.y, turn.z, turn.w);
    return render::posed_camera(point_of(fixed.eye), orientation, optics, size);
}

// Camera chọn nhân vật ở tư thế mà track đang cho. FOV 65, mặt xa 100000.
[[nodiscard]] render::Camera role_pose_camera(ogre::Vec3 eye, ogre::Quat turn, render::ViewSize size) noexcept {
    render::Lens optics;
    optics.fov_degrees = control::kRoleFov;
    optics.near_plane = control::kRoleNear;
    optics.far_plane = control::kRoleFar;
    const math::Quat orientation(turn.x, turn.y, turn.z, turn.w);
    return render::posed_camera(point_of(eye), orientation, optics, size);
}

// Luật camera của một cảnh thường: số của System.cfg, cộng hai mặt cắt của bảng cảnh.
[[nodiscard]] control::CameraRules rules_of(const world::ShownScene* scene) noexcept {
    control::CameraRules rules;
    if (scene == nullptr) return rules;
    rules.near_plane = static_cast<float>(scene->near_clip);
    rules.far_plane = static_cast<float>(scene->far_clip);
    return rules;
}

[[nodiscard]] resource::Image image_at(const std::filesystem::path& path) {
    resource::Image image;
    const io::TextResult text = io::read_text(path);
    if (!text) return image;
    const std::span<const char> chars(text->data(), text->size());
    const auto encoded = std::as_bytes(chars);
    auto decoded = resource::decode_image(encoded);
    if (!decoded) return image;
    return std::move(*decoded);
}

using MapPicture = game::client::map::Picture;
using Paths = std::vector<std::filesystem::path>;

// Giải mã một ảnh của danh sách vào đúng ô của nó; mỗi luồng một ô nên không cần khoá.
struct DecodeOne {
    std::vector<resource::Image>* images = nullptr;
    const Paths* paths = nullptr;
    std::size_t index = 0;
    void operator()() const { (*images)[index] = image_at((*paths)[index]); }
};

// Giải mã mọi ảnh cùng lúc, mỗi ảnh một luồng. Giải mã PNG lần lượt là phần chờ dài nhất của việc
// nướng mặt đất, nhất là lúc các luồng đọc mesh đang chiếm các lõi (đo 2026-10-08, erengu_DL: 11
// ảnh cọ và ảnh sáng 2048 x 2048).
[[nodiscard]] std::vector<resource::Image> decoded_all(const Paths& paths) {
    std::vector<resource::Image> images(paths.size());
    std::vector<std::jthread> pool;
    pool.reserve(paths.size());
    for (std::size_t index = 0; index < paths.size(); ++index) {
        pool.emplace_back(DecodeOne{.images = &images, .paths = &paths, .index = index});
    }
    // Chờ mọi luồng xong trước khi trả: chúng ghi thẳng vào images.
    pool.clear();
    return images;
}

[[nodiscard]] game::client::map::SurfaceImage view_of(const resource::Image& image) noexcept {
    game::client::map::SurfaceImage view;
    view.width = image.width;
    view.height = image.height;
    view.rgba = image.rgba;
    return view;
}

// Ảnh mặt đất của cảnh: các ảnh cọ của địa hình, rồi ảnh sáng (nếu cảnh có) ở cuối danh sách.
[[nodiscard]] MapPicture baked_surface(const MapGround& ground, const std::filesystem::path& root) {
    const std::size_t brush_count = ground.file.textures.size();
    const bool has_light = !ground.file.lightmap.empty();
    Paths paths;
    paths.reserve(brush_count + 1);
    for (const std::string& name : ground.file.textures) {
        paths.push_back(root / "Brushes" / io::path_from_utf8(name));
    }
    if (has_light) paths.push_back(root / "Scene" / io::path_from_utf8(ground.file.lightmap));
    const std::vector<resource::Image> stored = decoded_all(paths);
    std::vector<game::client::map::SurfaceImage> views(brush_count);
    std::ranges::transform(std::span(stored).first(brush_count), views.begin(), view_of);
    game::client::map::SurfaceImage light_view;
    if (has_light) light_view = view_of(stored.back());
    game::client::map::SurfaceInputs inputs;
    inputs.brushes = views;
    if (has_light) inputs.light = &light_view;
    return game::client::map::paint_surface(ground.file, ground.grid, inputs);
}

struct LayJob {
    resource::Primitive* primitive = nullptr;
    const MapGround* ground = nullptr;
    float span_x = 0.0F;
    float span_z = 0.0F;
};

void lay_vertex(LayJob job, std::size_t index) {
    resource::Vertex& vertex = job.primitive->vertices[index];
    const game::client::map::Corner& corner = job.ground->sheet.corners[index];
    const game::client::map::TerrainFile& file = job.ground->file;
    if (job.span_x != 0.0F) vertex.uv.x = (corner.x - file.origin.x) / job.span_x;
    if (job.span_z != 0.0F) vertex.uv.y = (corner.z - file.origin.z) / job.span_z;
    vertex.color = {.x = 1.0F, .y = 1.0F, .z = 1.0F, .w = 1.0F};
}

void lay_paint(resource::Primitive& primitive, const MapGround& ground) {
    const game::client::map::TerrainFile& file = ground.file;
    LayJob job;
    job.primitive = &primitive;
    job.ground = &ground;
    job.span_x = file.scale.x * static_cast<float>(file.x_size);
    job.span_z = file.scale.z * static_cast<float>(file.z_size);
    for (std::size_t index = 0; index < primitive.vertices.size(); ++index) {
        lay_vertex(job, index);
    }
}

// Ảnh nướng là các lớp cọ nhân lightmap; đèn và sương tính lúc vẽ như FairyTerrain.hlsl của bản
// gốc.
void attach_paint(resource::Model& model, const MapPicture& paint) {
    if (paint.rgba.empty() || model.materials.empty()) return;
    resource::Image image;
    image.name = "dia-hinh";
    image.width = paint.width;
    image.height = paint.height;
    image.rgba = paint.rgba;
    model.images.push_back(std::move(image));
    model.materials.front().color.image = 0;
    model.materials.front().classic = resource::Classic{.lit = resource::Lit::kTerrain};
}

void push_height_vertex(resource::Primitive& primitive, const game::client::map::Corner& corner, bool has_paint) {
    resource::Vertex vertex;
    vertex.position = {.x = corner.x, .y = corner.y, .z = corner.z};
    vertex.normal = {.x = corner.normal_x, .y = corner.normal_y, .z = corner.normal_z};
    if (!has_paint) vertex.color = {.x = corner.red, .y = corner.green, .z = corner.blue, .w = 1.0F};
    primitive.vertices.push_back(vertex);
}

// Lưới địa hình thành một model một nút. Không có cọ thì màu đỉnh theo độ cao.
[[nodiscard]] resource::Model model_of(const MapGround& ground, const MapPicture& paint) {
    resource::Model model;
    resource::Mesh mesh;
    mesh.name = "dia-hinh";
    resource::Primitive primitive;
    primitive.topology = resource::Topology::kTriangles;
    primitive.material = 0;
    primitive.vertices.reserve(ground.sheet.corners.size());
    const bool has_paint = !paint.rgba.empty();
    for (const game::client::map::Corner& corner : ground.sheet.corners) {
        push_height_vertex(primitive, corner, has_paint);
    }
    if (has_paint) lay_paint(primitive, ground);
    primitive.indices = ground.sheet.indices;
    mesh.primitives.push_back(std::move(primitive));
    model.meshes.push_back(std::move(mesh));
    resource::Material material;
    material.name = "dia-hinh";
    material.double_sided = true;
    model.materials.push_back(std::move(material));
    attach_paint(model, paint);
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

[[nodiscard]] bool is_opaque(const resource::Material& material) noexcept {
    return material.alpha != resource::Alpha::kBlend;
}

// Model không skin và không trộn alpha: mọi bản sao vẽ bằng một lệnh.
[[nodiscard]] bool can_batch(const resource::Model& model) noexcept {
    if (!model.skins.empty()) return false;
    return std::ranges::all_of(model.materials, is_opaque);
}

[[nodiscard]] const KeptGround* find_ground(const std::deque<KeptGround>& grounds, int scene_id) {
    using Kept = const KeptGround&;
    const auto same = [scene_id](Kept item) noexcept { return item.scene_id == scene_id; };
    const auto found = std::ranges::find_if(grounds, same);
    if (found == grounds.end()) return nullptr;
    return &*found;
}

[[nodiscard]] bool mesh_waiting(const Arrival& arrival, core::Clock::time_point deadline) noexcept {
    if (core::Clock::now() >= deadline) return false;
    return arrival.cursor < arrival.table.meshes.size();
}

// Luồng đọc chưa xong mesh đang chờ: ghi mốc để đo quãng bị đói dữ liệu (không phải công việc).
[[nodiscard]] bool note_waiting(Arrival& loading) noexcept {
    if (!loading.is_stalled) loading.stall_started = core::Clock::now();
    loading.is_stalled = true;
    return false;
}

void note_user(Arrival& loading, std::size_t prop_index) {
    const std::size_t mesh = loading.table.props.at(prop_index).mesh;
    loading.users.at(mesh).push_back(prop_index);
}

void index_users(Arrival& loading) {
    loading.users.resize(loading.table.meshes.size());
    const std::size_t count = loading.table.props.size();
    for (std::size_t index = 0; index < count; ++index) {
        note_user(loading, index);
    }
}

void grow_slots(std::vector<std::size_t>& slots, std::size_t count) {
    if (slots.size() >= count) return;
    slots.resize(count, kMissing);
}

// Một ô mesh do luồng đọc đĩa ghi. kWait là chưa xong.
enum class SlotMark : std::uint8_t { kWait, kFailed, kReady, kTaken };

// Một mesh đã qua luồng nạp: model kèm chuỗi mip đã nướng của các ảnh của nó. Nướng mip là phần đắt
// nhất của việc nạp (đo 2026-10-08 ở cảnh erengu_DL, 153 ảnh: 2,5 giây khi làm tuần tự trên luồng
// vẽ), nên làm ở luồng nạp, nhiều ảnh cùng lúc; luồng vẽ chỉ còn chép byte lên GPU. baked rỗng khi
// nướng hỏng: bộ tải lên sẽ tự nướng lại và báo đúng lỗi.
struct ReadMesh {
    resource::Model model;
    std::vector<resource::StagedImage> baked;
};

[[nodiscard]] ReadMesh baked_mesh(resource::Model model) {
    ReadMesh read;
    auto baked = resource::stage_images(model);
    if (baked) read.baked = std::move(*baked);
    read.model = std::move(model);
    return read;
}

struct SlotBox {
    SlotMark mark = SlotMark::kWait;
    std::optional<ReadMesh> mesh;
};

struct Need {
    std::size_t slot = 0;
    std::string name;
};

// Kết quả take_mesh. is_ready sai khi ô chưa đọc xong. Đúng mà model rỗng là file hỏng.
struct MeshReady {
    bool is_ready = false;
    std::optional<ReadMesh> mesh;
};

// Việc đọc đĩa. Luồng vẽ không đụng file: luồng này đọc .glb và nướng địa hình.
struct FeedJob {
    std::uint64_t epoch = 0;
    std::filesystem::path root;
    std::shared_ptr<const world::ShownScene> scene;
    bool bake_ground = false;
    std::vector<Need> needs;
};

struct Feed {
    std::mutex mu;
    std::condition_variable cv;
    std::uint64_t epoch = 0;
    std::optional<FeedJob> job;
    std::vector<SlotBox> slots;
    std::optional<ReadMesh> ground;
    bool ground_ready = false;
    bool quit = false;
    std::jthread thread;

    Feed();
    ~Feed();
    Feed(const Feed&) = delete;
    Feed& operator=(const Feed&) = delete;
    Feed(Feed&&) = delete;
    Feed& operator=(Feed&&) = delete;

    std::uint64_t post(FeedJob next);
    void cancel();
    [[nodiscard]] std::optional<ReadMesh> take_ground(std::uint64_t current);
    [[nodiscard]] MeshReady take_mesh(std::uint64_t current, std::size_t slot);
    [[nodiscard]] std::optional<FeedJob> wait_job(const std::stop_token& stop);
    [[nodiscard]] bool serve_next(const std::stop_token& stop);
    void run(const std::stop_token& stop);
};

void bake_job(const FeedJob& job, Feed& feed) {
    if (!job.bake_ground || !job.scene || !job.scene->ground) return;
    const TimePoint began = core::Clock::now();
    const MapPicture paint = baked_surface(*job.scene->ground, job.root);
    const double painted_ms = millis_between(began, core::Clock::now());
    ReadMesh model = baked_mesh(model_of(*job.scene->ground, paint));
    const double baked_ms = millis_between(began, core::Clock::now());
    const int scene_id = job.scene->id;
    {
        const std::scoped_lock<std::mutex> lock(feed.mu);
        if (feed.epoch != job.epoch) return;
        feed.ground = std::move(model);
        feed.ground_ready = true;
    }
    const std::string millis = std::format("{:.1f}", baked_ms);
    const std::string painted = std::format("{:.1f}", painted_ms);
    std::println("Địa hình resid {} đã nướng trong {} ms (tô ảnh mặt {} ms)", scene_id, millis, painted);
}

[[nodiscard]] std::size_t slot_span(const std::vector<Need>& needs) {
    std::size_t count = 0;
    for (const Need& need : needs) {
        count = std::max(count, need.slot + 1);
    }
    return count;
}

[[nodiscard]] bool epoch_matches(Feed& feed, std::uint64_t epoch) {
    const std::scoped_lock<std::mutex> lock(feed.mu);
    return feed.epoch == epoch;
}

void store_read(Feed& feed, const FeedJob& job, const Need& need) {
    const std::filesystem::path path = job.root / io::path_from_utf8("Model") / io::path_from_utf8(need.name + ".glb");
    auto loaded = resource::load_glb_file(io::utf8_of(path), io::utf8_of(job.root));
    if (!loaded) std::println(stderr, "Bỏ mesh {}: {}", need.name, loaded.error());
    std::optional<ReadMesh> read;
    if (loaded) read = baked_mesh(std::move(*loaded));
    const std::scoped_lock<std::mutex> lock(feed.mu);
    if (feed.epoch != job.epoch) return;
    SlotBox& box = feed.slots.at(need.slot);
    box.mark = read ? SlotMark::kReady : SlotMark::kFailed;
    box.mesh = std::move(read);
}

// Con trỏ việc đang đọc. Nhiều luồng lấy chỉ số qua next, không chia nhau một Model.
struct ReadCursor {
    const FeedJob* job = nullptr;
    Feed* feed = nullptr;
    std::stop_token stop;
    std::atomic<std::size_t> next{0};
};

[[nodiscard]] bool next_need(ReadCursor& cursor, std::size_t& index) {
    if (cursor.stop.stop_requested()) return false;
    if (!epoch_matches(*cursor.feed, cursor.job->epoch)) return false;
    index = cursor.next.fetch_add(1, std::memory_order_relaxed);
    return index < cursor.job->needs.size();
}

void read_need(ReadCursor& cursor) {
    std::size_t index = 0;
    while (next_need(cursor, index)) {
        store_read(*cursor.feed, *cursor.job, cursor.job->needs.at(index));
    }
}

// Để lại một lõi cho luồng vẽ. Nhiều hơn Dev (mẻ 16, xong cả mẻ mới giao): file xong là giao ngay.
[[nodiscard]] std::size_t reader_count(std::size_t files) noexcept {
    const unsigned cores = std::max(2U, std::thread::hardware_concurrency());
    const std::size_t readers = static_cast<std::size_t>(cores) - 1;
    return std::max(std::size_t{1}, std::min(readers, files));
}

struct ReadStart {
    ReadCursor* cursor = nullptr;
    void operator()(const std::stop_token&) const { read_need(*cursor); }
};

void start_readers(ReadCursor& cursor, std::size_t files) {
    const std::size_t readers = reader_count(files);
    std::vector<std::jthread> pool;
    pool.reserve(readers);
    ReadStart start;
    start.cursor = &cursor;
    for (std::size_t index = 0; index < readers; ++index) {
        pool.emplace_back(start);
    }
}

void read_job(const FeedJob& job, Feed& feed, std::stop_token stop) {
    if (job.needs.empty()) return;
    ReadCursor cursor;
    cursor.job = &job;
    cursor.feed = &feed;
    cursor.stop = std::move(stop);
    start_readers(cursor, job.needs.size());
}

void serve(const FeedJob& job, Feed& feed, std::stop_token stop) {
    const std::jthread baker([&job, &feed](const std::stop_token&) { bake_job(job, feed); });
    read_job(job, feed, std::move(stop));
}

Feed::Feed() {
    thread = std::jthread([this](const std::stop_token& stop) { run(stop); });
}

Feed::~Feed() {
    {
        const std::scoped_lock<std::mutex> lock(mu);
        quit = true;
    }
    cv.notify_all();
}

std::uint64_t Feed::post(FeedJob next) {
    const std::scoped_lock<std::mutex> lock(mu);
    ++epoch;
    next.epoch = epoch;
    slots.assign(slot_span(next.needs), {});
    ground.reset();
    ground_ready = false;
    job = std::move(next);
    cv.notify_all();
    return epoch;
}

void Feed::cancel() {
    const std::scoped_lock<std::mutex> lock(mu);
    ++epoch;
    job.reset();
    ground.reset();
    ground_ready = false;
    slots.clear();
    cv.notify_all();
}

std::optional<ReadMesh> Feed::take_ground(std::uint64_t current) {
    const std::scoped_lock<std::mutex> lock(mu);
    if (!ground_ready || epoch != current || !ground) return std::nullopt;
    ground_ready = false;
    return std::exchange(ground, std::nullopt);
}

MeshReady Feed::take_mesh(std::uint64_t current, std::size_t slot) {
    const std::scoped_lock<std::mutex> lock(mu);
    MeshReady ready;
    if (epoch != current || slot >= slots.size()) return ready;
    SlotBox& box = slots.at(slot);
    if (box.mark == SlotMark::kWait || box.mark == SlotMark::kTaken) return ready;
    ready.is_ready = true;
    ready.mesh = std::move(box.mesh);
    box.mark = SlotMark::kTaken;
    return ready;
}

std::optional<FeedJob> Feed::wait_job(const std::stop_token& stop) {
    std::unique_lock<std::mutex> lock(mu);
    cv.wait(lock, [this, &stop] { return quit || job.has_value() || stop.stop_requested(); });
    if (quit || stop.stop_requested()) return std::nullopt;
    std::optional<FeedJob> taken = std::move(job);
    job.reset();
    return taken;
}

bool Feed::serve_next(const std::stop_token& stop) {
    std::optional<FeedJob> taken = wait_job(stop);
    if (!taken) return false;
    serve(*taken, *this, stop);
    return true;
}

void Feed::run(const std::stop_token& stop) {
    while (!stop.stop_requested() && serve_next(stop)) {
    }
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
[[nodiscard]] bool write_bytes(const std::filesystem::path& path, ByteSpan bytes) {
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

struct GroundUpload {
    KeptMesh* slot = nullptr;
    const map::Ground* ground = nullptr;
    const std::filesystem::path* data_root = nullptr;
    gpu::Device* device = nullptr;
    render::Forward* forward = nullptr;
};

struct SeatTarget {
    KeptMesh* slot = nullptr;
    gpu::Device* device = nullptr;
    render::Forward* forward = nullptr;
};

// Nộp vào phần tử đã nằm trong deque. prepare giữ con trỏ vào model của chính phần tử đó.
[[nodiscard]] bool seat_model(SeatTarget target, ReadMesh mesh) {
    target.slot->loaded.model = std::move(mesh.model);
    LoadedMesh& loaded = target.slot->loaded;
    auto uploaded = resource::upload_queued(*target.device, loaded.model, mesh.baked);
    if (!uploaded) {
        std::println(stderr, "Bỏ nội dung (tải lên GPU): {}", uploaded.error());
        return false;
    }
    loaded.uploaded = std::move(*uploaded);
    auto drawable = target.forward->prepare(loaded.model, loaded.uploaded);
    if (!drawable) {
        std::println(stderr, "Bỏ nội dung (chuẩn bị vẽ): {}", drawable.error());
        return false;
    }
    loaded.drawable = std::move(*drawable);
    target.slot->bounds = render::bounds_of(loaded.model, loaded.drawable.rest());
    return true;
}

[[nodiscard]] bool upload_ground(GroundUpload upload) {
    MapPicture paint;
    if (upload.data_root != nullptr) paint = baked_surface(*upload.ground, *upload.data_root);
    ReadMesh mesh = baked_mesh(model_of(*upload.ground, paint));
    SeatTarget target;
    target.slot = upload.slot;
    target.device = upload.device;
    target.forward = upload.forward;
    return seat_model(target, std::move(mesh));
}

// Bộ ba backend, adapter và hash gói shader. Đổi một trong ba là một file cache khác.
struct CacheId {
    gpu::Backend backend = gpu::Backend::kVulkan;
    std::uint32_t vendor = 0;
    std::uint32_t device = 0;
    std::uint64_t shaders = 0;
};

[[nodiscard]] bool has_hardware(gpu::Backend backend) {
    const gpu::Result<std::vector<gpu::AdapterInfo>> list = gpu::enumerate_adapters(backend);
    if (!list) return false;
    for (const gpu::AdapterInfo& info : *list) {
        if (!info.is_software) return true;
    }
    return false;
}

[[nodiscard]] CacheId identity_of(gpu::Backend backend, std::uint32_t index, std::uint64_t shaders) {
    CacheId id;
    id.backend = backend;
    id.shaders = shaders;
    const gpu::Result<std::vector<gpu::AdapterInfo>> list = gpu::enumerate_adapters(backend);
    if (!list || index >= list->size()) return id;
    id.vendor = list->at(index).vendor_id;
    id.device = list->at(index).device_id;
    return id;
}

// Cùng thứ tự create_present_device: Vulkan phần cứng, rồi D3D12, D3D11, GLES. Backend ép thì
// lấy đúng backend ấy.
[[nodiscard]] CacheId predict_cache(const gpu::DeviceDesc& desc, std::uint64_t shaders) {
    const bool is_automatic = desc.backend == gpu::Backend::kVulkan && !desc.adapter;
    if (!is_automatic) return identity_of(desc.backend, desc.adapter.value_or(0), shaders);
    constexpr std::array<gpu::Backend, 4> order{
        gpu::Backend::kVulkan, gpu::Backend::kD3D12, gpu::Backend::kD3D11, gpu::Backend::kGles};
    for (const gpu::Backend backend : order) {
        if (!has_hardware(backend)) continue;
        return identity_of(backend, 0, shaders);
    }
    return identity_of(gpu::Backend::kVulkan, 0, shaders);
}

[[nodiscard]] std::uint64_t hash_packages(const std::string& folder) {
    std::uint64_t hash = core::kFnvOffsetBasis;
    for (const std::string_view name : render::kPackageNames) {
        hash = core::fnv1a(name, hash);
        const io::TextResult bytes = io::read_text(io::path_from_utf8(shader::package_path(folder, name)));
        if (!bytes) {
            hash = core::fnv1a(std::string_view("missing"), hash);
            continue;
        }
        hash = core::fnv1a(std::as_bytes(std::span(*bytes)), hash);
    }
    return hash;
}

[[nodiscard]] std::filesystem::path cache_file(const std::filesystem::path& root, const CacheId& id) {
    const std::string name =
        std::format("pipeline-{}-{:08x}-{:08x}-{:016x}.bin", gpu::name(id.backend), id.vendor, id.device, id.shaders);
    return root / "cache" / name;
}

[[nodiscard]] std::filesystem::path writable_root(const DisplayDesc& desc) {
    if (!desc.save_root.empty()) return desc.save_root;
    return desc.data_root;
}

[[nodiscard]] std::vector<std::byte> read_cache(const std::filesystem::path& path) {
    const io::TextResult text = io::read_text(path);
    if (!text) return {};
    std::vector<std::byte> bytes(text->size());
    std::ranges::copy(std::as_bytes(std::span(*text)), bytes.begin());
    return bytes;
}

[[nodiscard]] core::Status apply_backend(gpu::DeviceDesc& device_desc, const DisplayDesc& desc) {
    if (!desc.backend) return core::ok();
    const std::optional<gpu::Backend> parsed = gpu::parse_backend(*desc.backend);
    if (!parsed) return core::fail(core::ErrorCode::kInvalidArgument, "backend không có");
    device_desc.backend = *parsed;
    return core::ok();
}

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
    [[nodiscard]] core::Status open_gpu(const DisplayDesc& desc);
    void open_hud(const DisplayDesc& desc);
    void arm_scene(const DisplayDesc& desc);
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
    [[nodiscard]] float step_clock(float elapsed) noexcept;
    // Điều khiển đã gom của một khung: phím và các sự kiện chuột, chạm theo thứ tự tới.
    struct Taken {
        Steering keys;
        std::vector<control::InputEvent> events;
    };
    [[nodiscard]] Taken take_steering();
    // Gom sự kiện chuột và chạm của khung thành một mẫu chuột; sự kiện chưa dùng được trả lại
    // hàng chờ cho khung sau.
    void take_events(std::span<const control::InputEvent> events);
    [[nodiscard]] bool absorb(const control::InputEvent& event);
    [[nodiscard]] bool flip_button(const control::InputEvent& event);
    void move_pointer(const control::InputEvent& event);
    void cancel_left() noexcept;
    void turn_wheel(float notches);
    void release_stick();
    // Vào cảnh, phím camera, rồi một khung chuột của màn chơi (control::Pilot).
    void enter_camera(int scene_id);
    void steer_camera(const Steering& keys);
    void pilot_frame(core::Clock::time_point now, float seconds);
    [[nodiscard]] control::MouseSample mouse_sample() const noexcept;
    // Ghi con trỏ của khung cho luồng cửa sổ. Chưa có chọn đối tượng dưới chuột nên hover để
    // trống.
    void publish_cursor() noexcept;
    void hold_stick_frame(core::Clock::time_point now);
    void apply_stick_step(const control::StickStep& step);
    void order_move(std::optional<core::GroundPoint> target, nav::MoveMode mode);
    [[nodiscard]] std::optional<core::GroundPoint> pick_at(control::ScreenPoint point) const;
    [[nodiscard]] ogre::Vec3 foot() const;
    void move_player(const Steering& keys, float dt);
    void walk_free(const Steering& keys, float dt);
    void walk_order(float dt);
    // Một khung Tick_Move rồi kéo điểm vào trong map (VerifyPos).
    void apply_tick(motion::MoveAsk ask);
    void place_step(const motion::MoveStep& step, core::GroundPoint from);
    void finish_leg();
    void rebuild_terrain(int scene_id);
    // Đọc ScenePosDefineEx một lần. Thiếu tệp thì in một dòng và đứng giữa map.
    void ensure_gates();
    // Resid đổi: điểm đến của cổng, không có điểm thì ô trống gần giữa map.
    void place_at(int scene_id);
    [[nodiscard]] render::Camera frame_camera(FrameAsk ask);
    [[nodiscard]] render::Camera idle_view(FrameAsk ask);
    [[nodiscard]] bool shows_world_role() const;
    [[nodiscard]] bool shows_role_scene() const;
    [[nodiscard]] render::Camera role_scene_camera(render::ViewSize size) const;
    void append_login_role();
    void close_mouse_frame() noexcept;
    void prepare_hud();
    void post_request(ui::Action action);
    void open_login();
    void store_roles() const;
    void apply_role();
    void apply_kept(const KeptRole& restored);
    void start_play();
    [[nodiscard]] ui::HudView hud_view() const;
    [[nodiscard]] std::optional<ui::SceneLoad> scene_load() const;
    [[nodiscard]] bool is_on_hud(control::ScreenPoint point) const;
    void fill_pace_board();
    void prepare_board();
    // Ba mốc của một khung: bắt đầu xin ảnh, đã có ảnh, đã ghi xong lệnh vẽ.
    struct FrameMarks {
        TimePoint asked;
        TimePoint acquired;
        TimePoint recorded;
    };
    void stamp_phases(const FrameMarks& marks);
    struct IntervalNote {
        double interval = 0.0;
        double render_ms = 0.0;
        double pace_ms = 0.0;
    };
    void note_pace(double interval);
    void record_interval(IntervalNote note);
    void ensure_clock();
    void hold_pace(double spent_ms);
    [[nodiscard]] core::Status paint_hud(gpu::CommandList& list, std::uint32_t slot) const;
    struct FxAsk {
        gpu::CommandList* list = nullptr;
        const render::Camera* camera = nullptr;
        std::uint32_t slot = 0;
        float elapsed = 0.0F;
    };
    void advance_fx(float elapsed);
    [[nodiscard]] std::size_t fx_mesh_slot(const fx::Field& field);
    void push_fx_field(const fx::Field& field, std::size_t slot);
    void append_fx_meshes();
    void draw_fx(const FxAsk& ask) const;
    // Camera, mọi instance, hiệu ứng rồi HUD của một khung, vào ảnh slot.
    [[nodiscard]] core::Status draw_world(gpu::CommandList& list, std::uint32_t slot);
    struct PresentAsk {
        gpu::CommandList* list = nullptr;
        std::optional<ShotPlan> shot;
    };
    [[nodiscard]] core::Status present_drawn(PresentAsk ask) const;
    [[nodiscard]] core::Status render();
    // Lấy cảnh mới nếu luồng cửa sổ vừa đổi resid. Mesh prop đã có thì không đọc lại đĩa.
    void adopt();
    void clear_shown();
    void clear_if_shown();
    void begin_load(std::shared_ptr<const world::ShownScene> next);
    void remember_mesh(Arrival& loading, FeedJob& job, std::size_t index);
    void remember_meshes(Arrival& loading, FeedJob& job);
    [[nodiscard]] bool needs_fresh_ground(const Arrival& loading) const;
    void pump_load();
    void open_ground(Arrival& loading);
    [[nodiscard]] bool pull_mesh(Arrival& loading);
    [[nodiscard]] bool step_mesh(Arrival& loading);
    void stream_ground(Arrival& loading);
    void reveal(Arrival& loading);
    void show_mesh(Arrival& loading);
    void publish_mesh(Arrival& loading, std::size_t mesh_slot);
    void seal_mesh(std::size_t index, std::vector<std::size_t>& slots);
    void finish_stream();
    [[nodiscard]] core::Status submit_frame(gpu::CommandList& list) const;
    void load_props();
    [[nodiscard]] std::vector<std::size_t> load_listed(const PropTable& table);
    void load_stage();
    void load_player();
    void load_head(const PlayerDesc& desc, const MeshLoader& loader);
    void record_head(gpu::CommandList& list);
    void open_role(const ui::panel::ShownModel& model);
    void step_role_stage();
    [[nodiscard]] PlayerDesc role_player(const ui::panel::ShownModel& model) const;
    [[nodiscard]] MeshLoader meshes();
    void compose_frame();
    void append_ground();
    void attach_cached_ground();
    void bind_ground(const KeptGround* slot);
    [[nodiscard]] KeptGround* make_ground(int scene_id);
    [[nodiscard]] std::size_t load_mesh(const std::string& mesh);
    [[nodiscard]] std::size_t keep_model(const std::string& mesh, ReadMesh read);
    bool keep_ground(int scene_id, ReadMesh read);
    void grow_world(const math::Aabb& local, const math::Matrix4& placed);
    void push_matrix(const render::Drawable& drawable, const math::Matrix4& placed);
    struct CrowdFill {
        std::size_t index = 0;
        math::Matrix4 placed = math::Matrix4::identity();
        std::vector<std::size_t>* crowd_of = nullptr;
    };
    void add_crowd(CrowdFill fill);
    void push_crowd(const Crowd& crowd);
    void push_crowds();
    struct PropPlace {
        const PlacedProp* prop = nullptr;
        std::span<const std::size_t> loaded;
        std::vector<std::size_t>* crowd_of = nullptr;
    };
    void place_prop(PropPlace place);
    void build_instances(const PropTable& table, std::span<const std::size_t> loaded);
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
    // Ghi blob pipeline_cache của thiết bị. D3D11 trả rỗng nên không tạo file.
    void store_pipeline_cache() const;
    // Dừng khéo từ luồng thông điệp: join luồng vẽ rồi wrap_up nếu luồng chưa tự làm.
    void settle();

    // Thứ tự trường theo clang-analyzer-optin.performance.Padding. device đứng trước đối tượng
    // GPU dùng nó, nên chúng huỷ trước. feeder đứng trước spinner: luồng vẽ join xong rồi luồng
    // đọc mới join. settle join spinner trước khi State bị huỷ.
    // Nhịp đưa lên bảng: chặng của khung vừa xong.
    struct PaceLast {
        float acquire_ms = 0.0F;
        float draw_ms = 0.0F;
        float submit_ms = 0.0F;
        std::uint32_t draws = 0;
        std::uint32_t quads = 0;
    };

    // Hộp bao thế giới, cho camera quay khi chưa có mặt đất. Ánh sáng lấy một lần từ stage.
    math::Aabb world;
    SceneLight light;
    // Camera cảnh và phần chuột của màn chơi theo client 2026. Không giữ tài nguyên GPU.
    control::FollowCamera follow{control::CameraRules{}};
    control::Pilot pilot{control::PilotRules{}};
    std::optional<PlayerActor> player;
    std::unique_ptr<gpu::Device> device;
    // Sau device, trước forward và ui: huỷ các lượt vẽ trước, rồi PSO, rồi device.
    std::unique_ptr<render::Catalog> catalog;
    std::filesystem::path pipeline_cache_file;
    std::unique_ptr<render::Screen> screen;
    std::unique_ptr<render::Forward> forward;
    std::unique_ptr<FxView> fx_view;
    // Giao diện 2D. Rỗng khi thiếu shader hay dữ liệu; game vẫn chạy.
    std::unique_ptr<render::UiPass> ui_pass;
    std::unique_ptr<ui::Hud> hud;
    const Stage* stage = nullptr;
    const game::client::map::Ground* ground = nullptr;
    core::Clock::time_point started;
    std::atomic<PackedSize> posted_size{0};
    // Số khung bỏ vì bề mặt đã đổi cỡ. Quay nhiều nghĩa là đường này bị bão hoà.
    std::uint64_t stale_frames = 0;
    std::atomic<std::uint64_t> reported_faults{0};
    double last_load_ms = 0.0;
    double last_prepare_ms = 0.0;
    std::size_t pace_filled = 0;
    std::size_t pace_cursor = 0;
    // Đọc đĩa. Đứng trước spinner nên huỷ sau: luồng vẽ join xong rồi luồng đọc mới join.
    std::unique_ptr<Feed> feeder;
    // Ảnh đầu 3D. Đứng sau device, forward và ui_pass để huỷ trước chúng.
    std::optional<HeadShot> head;
    std::optional<RoleShot> role_shot;
    // Camera của bảng chọn và màn tạo cùng phần thủ tục điều khiển nó; chỉ luồng vẽ đụng.
    RoleStage role_stage;
    std::optional<core::Clock::time_point> role_stamp;
    std::shared_ptr<const world::ShownScene> held;
    // Cảnh tl3chuangjian. Chỉ luồng vẽ đọc, gán một lần lúc mở.
    std::shared_ptr<const world::ShownScene> role_scene;
    // libc++ không có atomic<shared_ptr>. Luồng cửa sổ ghi, luồng vẽ đọc, dưới pending_guard.
    std::shared_ptr<const world::ShownScene> pending;
    std::optional<std::size_t> steady_from;
    std::vector<render::Instance> frame_instances;
    std::vector<control::InputEvent> queued;
    // Ký tự gõ ở khung này, chờ lần prepare kế của giao diện. Chỉ luồng vẽ chạm vào.
    std::vector<char32_t> typed;
    // Việc giao diện nhờ vòng cửa sổ; request_guard bảo vệ requests.
    std::mutex request_guard;
    std::vector<Request> requests;
    // Vòng cửa sổ đã gọi play: luồng vẽ rời thủ tục đăng nhập ở lượt kế.
    std::atomic<bool> wants_play{false};
    std::array<ui::ViewPaint, 1> head_views{};
    std::vector<render::Instance> instances;
    std::vector<map::Gate> gates;
    std::vector<double> frame_ms;
    // Luồng vẽ; join trong settle.
    std::jthread spinner;
    control::StickMove stick;
    PhaseSums phase_ms;
    std::filesystem::path data_root;
    std::filesystem::path save_root;
    std::filesystem::path shot_path;
    std::string reported_description;
    std::deque<KeptMesh> kept;
    std::deque<KeptGround> grounds;
    // deque: thêm đám mới không kéo đám cũ, span ma trận của lệnh vẽ không đứt.
    std::deque<Crowd> crowds;
    ui::PaceOverlay pace_board;
    std::optional<core::FixedStep> frame_clock;
    std::unordered_map<std::string, std::size_t> kept_by_name;
    std::mutex steer_guard;
    std::mutex pending_guard;
    std::mutex outcome_guard;
    std::optional<ui::BitmapFont> pace_font;
    // Nhân vật HUD. Có người vừa chọn thì là người đó; vào thẳng cảnh thì nhân vật mới mặc định.
    hero::Hero hero = hero::newcomer();
    look::Look role_look{};
    look::Race role_race = look::Race::kFemale;
    bool has_role_look = false;
    mutable std::mutex kept_guard;
    KeptRole played_role;
    bool roles_loaded = false;
    // Thủ tục đang chạy: HUD hiện bảng nhập tài khoản hay giao diện của màn chơi.
    Procedure procedure = Procedure::kPlay;
    // DisplayDesc::is_bare: paint_hud không ghi lệnh vẽ nào.
    bool is_bare = false;
    // Mặt đất đang đi: độ cao tam giác đã vẽ, tia chạm đất, va chạm của mắt camera.
    std::optional<control::Ground> terrain;
    core::Status outcome{core::ok()};
    std::optional<Arrival> arrival;
    float fx_stamp = -1.0F;
    std::uint32_t head_turns = 0;
    std::uint32_t scene_draws = 0;
    std::uint32_t pace_texture = 0;
    std::atomic<std::uint32_t> reported_draws{0};
    // Mốc đi bộ, hướng mặt, cảnh của mặt đất và cảnh camera đã vào, zoom đã lưu khi rời cảnh
    // (biến Camera_Zoom của bản gốc), phần lẻ nấc lăn, độ dời con trỏ của khung.
    float walk_stamp = -1.0F;
    float facing = 0.0F;
    int terrain_scene = -1;
    std::optional<int> camera_scene;
    float saved_zoom = 1.0F;
    float wheel_carry = 0.0F;
    int drag_x = 0;
    int drag_y = 0;
    control::ScreenPoint pointer;
    render::ViewSize view_size{};
    std::optional<WalkOrder> order;
    // Lưới đi của cảnh đang đứng (rỗng khi cảnh không có tệp .path) và bộ nhớ làm việc của phép tìm
    // đường, giữ qua các lần nhấp chuột.
    const nav::Field* walk_field = nullptr;
    nav::Scratch scratch;
    std::optional<control::Tilt> tilt;
    WalkPose walk;
    PaceLast pace_last;
    Steering steering;
    ui::PaceNumbers pace_shown;
    // Thông số nhìn của khung trước, để cần gạt biết mắt.
    control::Lens lens;
    std::array<float, 90> pace_ring{};
    // Giá trị >= control::kCursorKinds là ẩn. Luồng vẽ ghi, luồng cửa sổ đọc.
    std::atomic<std::uint8_t> cursor_bits{static_cast<std::uint8_t>(control::CursorKind::kNormal)};
    bool is_player_running = false;
    bool has_lens = false;
    // Ba nút chuột đang giữ theo sự kiện đã nhận, theo thứ tự của control::MouseButton, và nút
    // nào đã đổi trạng thái trong khung này.
    std::array<bool, 4> is_button_down{};
    std::array<bool, 4> has_button_changed{};
    bool is_wheel_up = false;
    bool is_wheel_down = false;
    // Nấc lăn chưa đưa cho giao diện (dương là lăn lên): cộng ở turn_wheel, prepare_hud lấy rồi
    // xoá. Tách khỏi hai cờ trên vì chúng hết ở close_mouse_frame, trước lúc giao diện chạy.
    std::int32_t hud_wheel = 0;
    // Bảng đo khung hình đang hiện (F11); chỉ luồng vẽ đụng, trong take_steering.
    bool shows_pace = false;
    // Cú nhấn trái bắt đầu trên HUD thì thuộc về giao diện tới khi nhả.
    bool is_hud_press = false;
    bool stale_flag = false;
    // Acquire hết hạn: bỏ khung này, không dựng lại swapchain. Vòng vẽ kiểm dừng rồi thử lại.
    bool wait_flag = false;
    // Ảnh chụp (--shot): chụp đúng một lần ở khung đầu vẽ được.
    bool shot_taken = false;
    // Đã thử đọc bảng cổng. Không thử lại mỗi khung khi tệp thiếu hoặc hỏng.
    bool gates_ready = false;
    std::atomic<bool> is_resize_pending{false};
    // Luồng vẽ còn quay: sai nghĩa là lỗi vẽ hoặc thiết bị mất.
    std::atomic<bool> is_spinning{false};
    bool is_wrapped = false;
};

SceneTitle scene_title_lookup(const std::filesystem::path& data_root) {
    const auto book = std::make_shared<const gui::StringBook>(ui::scene_names(data_root));
    return [book](std::string_view name) { return std::string(book->find(name).value_or(name)); };
}

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

void Display::steer(const Steering& input) noexcept {
    const std::scoped_lock<std::mutex> locked(state_->steer_guard);
    Steering& kept = state_->steering;
    kept.turn_keys += input.turn_keys;
    kept.zoom_keys += input.zoom_keys;
    kept.is_home = kept.is_home || input.is_home;
    kept.toggles_pace = kept.toggles_pace != input.toggles_pace;
    if (!input.has_walk) return;
    kept.walk_forward = input.walk_forward;
    kept.walk_right = input.walk_right;
}

void Display::input(std::span<const control::InputEvent> events) {
    const std::scoped_lock<std::mutex> locked(state_->steer_guard);
    std::vector<control::InputEvent>& queued = state_->queued;
    const std::size_t room = queued.size() < kMaxQueued ? kMaxQueued - queued.size() : 0;
    const std::span<const control::InputEvent> kept = events.first(std::min(events.size(), room));
    queued.insert(queued.end(), kept.begin(), kept.end());
}

void Display::show(const std::shared_ptr<const world::ShownScene>& scene) {
    const std::scoped_lock<std::mutex> locked(state_->pending_guard);
    state_->pending = scene;
}

void Display::play(const std::shared_ptr<const world::ShownScene>& scene) {
    show(scene);
    state_->wants_play.store(true, std::memory_order_relaxed);
}

KeptRole Display::kept_role() const {
    const std::scoped_lock<std::mutex> locked(state_->kept_guard);
    return state_->played_role;
}

std::vector<Request> Display::take_requests() {
    const std::scoped_lock<std::mutex> locked(state_->request_guard);
    return std::exchange(state_->requests, {});
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

std::optional<control::CursorKind> Display::cursor_choice() const noexcept {
    const std::uint8_t bits = state_->cursor_bits.load(std::memory_order_relaxed);
    if (bits >= control::kCursorKinds) return std::nullopt;
    return static_cast<control::CursorKind>(bits);
}

core::Status Display::State::open_gpu(const DisplayDesc& desc) {
    gpu::DeviceDesc device_desc;
    device_desc.is_validated = desc.is_validated;
    const core::Status backend = apply_backend(device_desc, desc);
    if (!backend) return backend;
    const std::string shaders = shader_dir_of(desc.data_root);
    const std::string folder = render::resolved_shader_folder(shaders);
    const std::uint64_t shader_hash = hash_packages(folder);
    const std::filesystem::path root = writable_root(desc);
    std::vector<std::byte> cache;
    if (!root.empty()) cache = read_cache(cache_file(root, predict_cache(device_desc, shader_hash)));
    device_desc.pipeline_cache = cache;
    const bool is_forced = desc.backend.has_value();
    auto made = is_forced ? gpu::create_device(device_desc) : gpu::create_present_device(device_desc);
    if (!made) return std::unexpected(made.error());
    device = std::move(*made);
    const gpu::AdapterInfo& adapter = device->adapter();
    if (!root.empty()) {
        CacheId actual;
        actual.backend = adapter.backend;
        actual.vendor = adapter.vendor_id;
        actual.device = adapter.device_id;
        actual.shaders = shader_hash;
        pipeline_cache_file = cache_file(root, actual);
    }
    render::ScreenDesc screen_desc;
    screen_desc.window = desc.window;
    screen_desc.width = desc.size.width;
    screen_desc.height = desc.size.height;
    screen_desc.samples = kSamples;
    screen_desc.clear = kBackdrop;
    // PC: mailbox, trần 120 Hz. Android và iOS: Fifo bám Hz của tấm nền, không ngủ thêm.
    screen_desc.present_mode = kIsMobile ? gpu::PresentMode::kFifo : gpu::PresentMode::kMailbox;
    core::Result<render::Screen> shown = render::Screen::create(*device, screen_desc);
    if (!shown) return std::unexpected(shown.error());
    screen = std::make_unique<render::Screen>(std::move(*shown));
    render::CatalogDesc catalog_desc;
    catalog_desc.color = screen->color_format();
    catalog_desc.depth = screen->depth_format();
    catalog_desc.samples = screen->samples();
    catalog_desc.shader_dir = shaders;
    core::Result<render::Catalog> opened = render::Catalog::open(*device, std::move(catalog_desc));
    if (!opened) return std::unexpected(opened.error());
    catalog = std::make_unique<render::Catalog>(std::move(*opened));
    const core::Status warmed = catalog->prepare(render::Tier::kBootstrap);
    store_pipeline_cache();
    if (!warmed) return warmed;
    core::Result<render::Forward> pass = make_forward(*device, *screen, shaders, catalog->models());
    if (!pass) return std::unexpected(pass.error());
    forward = std::make_unique<render::Forward>(std::move(*pass));
    open_hud(desc);
    return core::ok();
}

// Mở giao diện nếu đủ shader và dữ liệu; thiếu thì ghi một dòng và bỏ qua, không làm hỏng game.
void Display::State::open_hud(const DisplayDesc& desc) {
    const gpu::PipelineHandle pipeline = catalog->get(render::Pso::kUi);
    if (!pipeline) {
        const core::Error* fault = catalog->fault(render::Pso::kUi);
        if (fault != nullptr) std::println(stderr, "Giao diện: bỏ qua, không dựng được lượt vẽ 2D: {}", *fault);
        if (fault == nullptr) std::println(stderr, "Giao diện: bỏ qua, không dựng được lượt vẽ 2D");
        return;
    }
    std::string shaders = shader_dir_of(desc.data_root);
    core::Result<render::UiPass> made = make_ui(*device, *screen, std::move(shaders), pipeline);
    if (!made) {
        std::println(stderr, "Giao diện: bỏ qua, không dựng được lượt vẽ 2D: {}", made.error());
        return;
    }
    ui_pass = std::make_unique<render::UiPass>(std::move(*made));
    ui::HudDesc hud_desc;
    hud_desc.data_root = desc.data_root;
    core::Result<ui::Hud> opened = ui::Hud::open(*ui_pass, hud_desc);
    if (!opened) {
        std::println(stderr, "Giao diện: bỏ qua, không mở được dữ liệu: {}", opened.error());
        return;
    }
    hud = std::make_unique<ui::Hud>(std::move(*opened));
    const std::filesystem::path font_file = desc.data_root / "Interface" / "Schema" / "VTNAM14.bin";
    core::Result<ui::BitmapFont> font = ui::BitmapFont::open(font_file);
    if (!font) {
        std::println(stderr, "Nhịp: không có phông bảng số: {}", font.error());
        return;
    }
    const core::Result<std::uint32_t> texture = ui_pass->add_texture(font->atlas());
    if (!texture) {
        std::println(stderr, "Nhịp: không tải được phông: {}", texture.error());
        return;
    }
    pace_font = std::move(*font);
    pace_texture = *texture;
}

void Display::State::arm_scene(const DisplayDesc& desc) {
    held = desc.scene;
    role_scene = desc.role_scene;
    {
        const std::scoped_lock<std::mutex> locked(pending_guard);
        pending = held;
    }
    data_root = desc.data_root;
    save_root = desc.save_root;
    shot_path = desc.shot_path;
    is_bare = desc.is_bare;
    procedure = desc.procedure;
    feeder = std::make_unique<Feed>();
    if (!held) {
        stage = desc.stage;
        ground = desc.ground;
        light = stage != nullptr ? light_of(*stage) : SceneLight{};
        load_stage();
    }
    // Gốc của đồng hồ khung đặt trước mọi lần dựng giao diện: open_login và prepare_board đã gọi
    // prepare_hud, trước đây chúng đọc một gốc chưa đặt và đưa cho giao diện một mốc rất lớn rồi
    // mốc tụt về 0 ở khung thật đầu tiên.
    started = core::Clock::now();
    // Nướng địa hình bắt đầu trước khi dựng giao diện và người chơi, để ba việc chạy cùng lúc.
    if (held) begin_load(held);
    // Màn đăng nhập chưa có nhân vật nào: không nạp mô hình. Sổ và danh sách tạo đọc trước khung đầu.
    if (desc.restored.has) apply_kept(desc.restored);
    if (procedure == Procedure::kLogin) open_login();
    if (procedure == Procedure::kPlay) load_player();
    prepare_board();
    const gpu::PipelineHandle fx_pipeline = catalog->get(render::Pso::kFx);
    if (!fx_pipeline) {
        const core::Error* fault = catalog->fault(render::Pso::kFx);
        if (fault != nullptr) std::println(stderr, "Hiệu ứng: bỏ qua, không dựng được bộ vẽ: {}", *fault);
        if (fault == nullptr) std::println(stderr, "Hiệu ứng: bỏ qua, không dựng được bộ vẽ");
    }
    if (fx_pipeline) fx_view = FxView::open(*device, fx_pipeline);
    if (fx_view) fx_view->load(data_root);
    const gpu::AdapterInfo& adapter = device->adapter();
    const gpu::PresentMode shown = screen->swapchain()->present_mode();
    const std::string_view api = gpu::name(adapter.backend);
    const std::string_view mode = gpu::name(shown);
    reported_description = std::format("{} trên {}, trình {}, có forward", api, adapter.name, mode);
    posted_size.store(pack(desc.size), std::memory_order_relaxed);
}

core::Status Display::State::launch(const DisplayDesc& desc) {
    const core::Status opened = open_gpu(desc);
    if (!opened) return opened;
    arm_scene(desc);
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

// Rời thủ tục đăng nhập: từ khung này camera, người chơi và giao diện là của màn chơi. Người chơi
// lấy mặt, tóc và giới của nhân vật vừa chọn; chưa chọn thì là nhân vật mới mặc định.
void Display::State::start_play() {
    if (procedure == Procedure::kPlay) return;
    procedure = Procedure::kPlay;
    typed.clear();
    apply_role();
    load_player();
}

void Display::State::open_login() {
    if (!hud || roles_loaded) return;
    roles_loaded = true;
    const std::filesystem::path root = save_root.empty() ? data_root : save_root;
    const std::filesystem::path file = root / "Save" / "roles.tsv";
    const std::string text = read_role_book(file);
    if (!hud->recall_roles(text)) std::println(stderr, "Nhân vật: sổ hỏng phiên bản, bắt đầu sổ trống");
}

void Display::State::store_roles() const {
    if (!hud) return;
    const std::optional<std::string> text = hud->roles_text();
    if (!text) return;
    const std::filesystem::path root = save_root.empty() ? data_root : save_root;
    const std::filesystem::path file = root / "Save" / "roles.tsv";
    if (write_role_book(file, *text)) hud->mark_roles_saved();
}

void Display::State::apply_role() {
    const ui::panel::Role* role = hud ? hud->entering_role() : nullptr;
    if (role == nullptr) return;
    hero = hero::newcomer();
    hero.name = role->name;
    hero.level = role->level;
    hero.portrait = hero::PortraitId{role->portrait};
    hero.sect = static_cast<hero::Sect>(role->sect);
    role_look = {};
    role_look.face = role->face;
    role_look.hair = role->hair;
    role_look.body = role->body;
    role_look.arm = role->arm;
    role_look.foot = role->foot;
    const bool is_female = role->sex == 0;
    role_race = is_female ? look::Race::kFemale : look::Race::kMale;
    has_role_look = true;
    KeptRole copy;
    copy.has = true;
    copy.sex = role->sex;
    copy.face = role->face;
    copy.hair = role->hair;
    copy.body = role->body;
    copy.arm = role->arm;
    copy.foot = role->foot;
    const std::scoped_lock<std::mutex> locked(kept_guard);
    played_role = std::move(copy);
}

void Display::State::apply_kept(const KeptRole& restored) {
    if (!restored.has) return;
    role_look = {};
    role_look.face = restored.face;
    role_look.hair = restored.hair;
    role_look.body = restored.body;
    role_look.arm = restored.arm;
    role_look.foot = restored.foot;
    const bool is_female = restored.sex == 0;
    role_race = is_female ? look::Race::kFemale : look::Race::kMale;
    has_role_look = true;
}

// Một lượt của luồng vẽ, kể cả lúc cửa sổ bị che; false khi dừng vì lỗi vẽ.
void Display::State::adopt() {
    if (wants_play.exchange(false, std::memory_order_relaxed)) start_play();
    std::shared_ptr<const world::ShownScene> next;
    {
        const std::scoped_lock<std::mutex> locked(pending_guard);
        next = pending;
    }
    if (procedure == Procedure::kLogin && role_scene && shows_role_scene()) next = role_scene;
    if (!next) {
        clear_if_shown();
        return;
    }
    if (arrival.has_value() && arrival->scene == next) return;
    if (!arrival.has_value() && next == held) return;
    begin_load(std::move(next));
}

[[nodiscard]] bool Display::State::turn_one(core::Clock::time_point& previous) {
    adopt();
    const TimePoint load_began = core::Clock::now();
    pump_load();
    last_load_ms = millis_between(load_began, core::Clock::now());
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
    const TimePoint render_began = core::Clock::now();
    const core::Status frame = render();
    const double render_ms = millis_between(render_began, core::Clock::now());
    const TimePoint pace_began = core::Clock::now();
    const double spent_ms = last_load_ms + render_ms;
    if (frame && !stale_flag) hold_pace(spent_ms);
    const double pace_ms = millis_between(pace_began, core::Clock::now());
    const core::Clock::time_point now = core::Clock::now();
    if (frame && wait_flag) {
        wait_flag = false;
        nap(previous);
        return true;
    }
    const bool is_stale = frame && stale_flag;
    if (is_stale) {
        // Bề mặt đã đổi cỡ giữa chừng: chờ cỡ mới tới rồi dựng lại, không quay cứng chờ nó.
        ++stale_frames;
        is_resize_pending.store(true, std::memory_order_relaxed);
        nap(previous);
        return true;
    }
    IntervalNote note;
    note.interval = std::chrono::duration<double, std::milli>(now - previous).count();
    note.render_ms = render_ms;
    note.pace_ms = pace_ms;
    record_interval(note);
    previous = now;
    publish();
    if (!frame) {
        keep(frame);
        return false;
    }
    return true;
}

void Display::State::clear_if_shown() {
    if (held || arrival.has_value()) clear_shown();
}

void Display::State::clear_shown() {
    held.reset();
    stage = nullptr;
    ground = nullptr;
    instances.clear();
    crowds.clear();
    world = {};
    arrival.reset();
    if (feeder) feeder->cancel();
}

void Display::State::begin_load(std::shared_ptr<const world::ShownScene> next) {
    if (catalog) {
        const core::Status tier = catalog->prepare(render::Tier::kScene);
        if (!tier) std::println(stderr, "Pipeline: tầng cảnh: {}", tier.error());
    }
    if (!next) {
        clear_shown();
        return;
    }
    Arrival loading;
    loading.scene = std::move(next);
    loading.started = core::Clock::now();
    if (!data_root.empty()) loading.table = table_of(loading.scene->stage);
    loading.loaded.assign(loading.table.meshes.size(), kMissing);
    index_users(loading);
    FeedJob job;
    job.root = data_root;
    job.scene = loading.scene;
    job.bake_ground = needs_fresh_ground(loading);
    remember_meshes(loading, job);
    const std::size_t fresh = job.needs.size();
    loading.epoch = feeder->post(std::move(job));
    if (!loading.table.meshes.empty()) {
        const std::size_t count = loading.table.meshes.size();
        std::println("Đang nạp {} mesh cho resid {}, {} đọc đĩa", count, loading.scene->id, fresh);
    }
    arrival = std::move(loading);
}

void Display::State::remember_mesh(Arrival& loading, FeedJob& job, std::size_t index) {
    const std::string& mesh = loading.table.meshes.at(index);
    const auto found = kept_by_name.find(mesh);
    if (found != kept_by_name.end()) {
        loading.loaded.at(index) = found->second;
        return;
    }
    Need need;
    need.slot = job.needs.size();
    need.name = mesh;
    loading.feed_slot.at(index) = need.slot;
    job.needs.push_back(std::move(need));
}

void Display::State::remember_meshes(Arrival& loading, FeedJob& job) {
    const std::size_t count = loading.table.meshes.size();
    loading.feed_slot.assign(count, kMissing);
    for (std::size_t index = 0; index < count; ++index) {
        remember_mesh(loading, job, index);
    }
}

bool Display::State::needs_fresh_ground(const Arrival& loading) const {
    if (data_root.empty() || !loading.scene || !loading.scene->ground) return false;
    if (loading.scene->ground->sheet.indices.empty()) return false;
    return find_ground(grounds, loading.scene->id) == nullptr;
}

void Display::State::reveal(Arrival& loading) {
    if (loading.revealed) return;
    held = loading.scene;
    stage = held ? &held->stage : nullptr;
    ground = held && held->ground ? &*held->ground : nullptr;
    walk_field = held && held->walk ? &*held->walk : nullptr;
    order.reset();
    instances.clear();
    crowds.clear();
    loading.crowd_of.clear();
    world = {};
    light = stage != nullptr ? light_of(*stage) : SceneLight{};
    loading.revealed = true;
    attach_cached_ground();
    if (fx_view && stage != nullptr) fx_view->adopt(*stage);
}

void Display::State::stream_ground(Arrival& loading) {
    // Địa hình phải xong trước mesh đầu tiên: đọc tệp, nướng ảnh mặt và tải lên GPU đều nằm ở đây.
    loading.ground_ms = millis_between(loading.started, core::Clock::now());
    loading.ground_done = true;
    reveal(loading);
}

void Display::State::seal_mesh(std::size_t index, std::vector<std::size_t>& slots) {
    const std::size_t slot = slots.at(index);
    if (slot == kMissing) return;
    push_crowd(crowds.at(slot));
}

void Display::State::publish_mesh(Arrival& loading, std::size_t mesh_slot) {
    const std::size_t index = loading.loaded.at(mesh_slot);
    if (index == kMissing) return;
    grow_slots(loading.crowd_of, kept.size());
    const std::vector<std::size_t>& users = loading.users.at(mesh_slot);
    for (const std::size_t prop_index : users) {
        PropPlace place;
        place.prop = &loading.table.props.at(prop_index);
        place.loaded = loading.loaded;
        place.crowd_of = &loading.crowd_of;
        place_prop(place);
    }
    seal_mesh(index, loading.crowd_of);
}

void Display::State::show_mesh(Arrival& loading) {
    if (!loading.revealed) return;
    publish_mesh(loading, loading.cursor - 1);
}

void Display::State::finish_stream() {
    if (!arrival.has_value()) return;
    const auto elapsed = core::Clock::now() - arrival->started;
    const double millis = std::chrono::duration<double, std::milli>(elapsed).count();
    const int id = arrival->scene ? arrival->scene->id : -1;
    const std::string millis_text = std::format("{:.1f}", millis);
    const std::string meshes_text = std::to_string(kept.size());
    const std::string props_text = std::to_string(instances.size());
    const std::string loaded = "Nạp cảnh resid " + std::to_string(id) + " xong trong " + millis_text;
    const std::string loaded_tail = " ms, " + meshes_text + " mesh nhớ, " + props_text + " vật thể";
    std::println("{}", loaded + loaded_tail);
    const std::string ground_ms = std::format("{:.1f}", arrival->ground_ms);
    const std::string seat_ms = std::format("{:.1f}", arrival->seat_ms);
    const std::string stall_ms = std::format("{:.1f}", arrival->stall_ms);
    const std::string place_ms = std::format("{:.1f}", arrival->place_ms);
    const std::string show_ms = std::format("{:.1f}", arrival->show_ms);
    const std::string frames_text = std::to_string(arrival->load_frames);
    const std::string timing = "  địa hình " + ground_ms + " ms, đưa GPU " + seat_ms + " ms, chờ luồng đọc " + stall_ms;
    if (!steady_from) steady_from = frame_ms.size() + 30;
    const std::string built = " ms, dựng GPU " + place_ms + " ms, đặt vật thể " + show_ms;
    const std::string timing_tail = built + " ms, " + frames_text + " khung";
    std::println("{}", timing + timing_tail);
    arrival.reset();
}

void Display::State::open_ground(Arrival& loading) {
    if (loading.ground_done) return;
    if (!needs_fresh_ground(loading)) {
        stream_ground(loading);
        return;
    }
    std::optional<ReadMesh> read = feeder->take_ground(loading.epoch);
    if (!read) return;
    const TimePoint seat_began = core::Clock::now();
    keep_ground(loading.scene->id, std::move(*read));
    loading.seat_ms += millis_between(seat_began, core::Clock::now());
    stream_ground(loading);
}

bool Display::State::pull_mesh(Arrival& loading) {
    const std::size_t index = loading.cursor;
    if (loading.feed_slot.at(index) == kMissing) {
        ++loading.cursor;
        return true;
    }
    const std::size_t slot = loading.feed_slot.at(index);
    MeshReady ready = feeder->take_mesh(loading.epoch, slot);
    if (!ready.is_ready) return note_waiting(loading);
    if (loading.is_stalled) {
        loading.stall_ms += millis_between(loading.stall_started, core::Clock::now());
        loading.is_stalled = false;
    }
    if (ready.mesh) {
        const std::string& mesh = loading.table.meshes.at(index);
        loading.loaded.at(index) = keep_model(mesh, std::move(*ready.mesh));
    }
    ++loading.cursor;
    return true;
}

bool Display::State::step_mesh(Arrival& loading) {
    const core::Clock::time_point before = core::Clock::now();
    const bool moved = pull_mesh(loading);
    const core::Clock::time_point pulled = core::Clock::now();
    if (!moved) return false;
    loading.place_ms += millis_between(before, pulled);
    show_mesh(loading);
    loading.show_ms += millis_between(pulled, core::Clock::now());
    return true;
}

void Display::State::pump_load() {
    if (!arrival.has_value()) return;
    Arrival& loading = arrival.value();
    const bool was_grounded = loading.ground_done;
    open_ground(loading);
    if (!loading.ground_done) return;
    // Khung vừa đưa cả mặt đất lên GPU thì dừng: cộng mesh vào cùng khung là cú giật 30 ms.
    if (!was_grounded) return;
    ++loading.load_frames;
    const core::Clock::time_point deadline = core::Clock::now() + kLoadSlice;
    bool running = true;
    while (running) {
        running = mesh_waiting(loading, deadline) && step_mesh(loading);
    }
    if (loading.cursor < loading.table.meshes.size()) return;
    finish_stream();
}

std::vector<std::size_t> Display::State::load_listed(const PropTable& table) {
    std::vector<std::size_t> loaded(table.meshes.size(), kMissing);
    for (std::size_t index = 0; index < table.meshes.size(); ++index) {
        loaded.at(index) = load_mesh(table.meshes.at(index));
    }
    return loaded;
}

void Display::State::load_props() {
    const PropTable table = table_of(*stage);
    const std::vector<std::size_t> loaded = load_listed(table);
    build_instances(table, loaded);
}

void Display::State::load_stage() {
    if (stage != nullptr && !data_root.empty()) load_props();
    append_ground();
    std::println("Nạp cảnh: {} mesh nhớ, {} vật thể", kept.size(), instances.size());
}

KeptGround* Display::State::make_ground(int scene_id) {
    // prepare giữ con trỏ vào Model. Phải nạp vào phần tử đã nằm trong deque, không
    // dựng tạm rồi move: move làm Drawable::model_ trỏ vào model đã chết.
    grounds.emplace_back();
    KeptGround& made = grounds.back();
    made.scene_id = scene_id;
    GroundUpload upload;
    upload.slot = &made.mesh;
    upload.ground = ground;
    upload.data_root = &data_root;
    upload.device = device.get();
    upload.forward = forward.get();
    if (!upload_ground(upload)) {
        grounds.pop_back();
        return nullptr;
    }
    if (grounds.size() > kKeptGrounds) grounds.pop_front();
    return &grounds.back();
}

void Display::State::bind_ground(const KeptGround* slot) {
    if (slot == nullptr) return;
    push_matrix(slot->mesh.loaded.drawable, math::Matrix4::identity());
    const int cells_x = ground->file.x_size;
    const int cells_z = ground->file.z_size;
    const std::size_t triangles = ground->triangle_count();
    std::println("Địa hình: {}x{} ô, {} tam giác", cells_x, cells_z, triangles);
    if (!has_points(slot->mesh.bounds)) return;
    grow_world(slot->mesh.bounds, math::Matrix4::identity());
}

void Display::State::append_ground() {
    if (ground == nullptr || ground->sheet.indices.empty()) return;
    const int scene_id = held ? held->id : -1;
    const KeptGround* found = find_ground(grounds, scene_id);
    const KeptGround* slot = found != nullptr ? found : make_ground(scene_id);
    bind_ground(slot);
}

void Display::State::attach_cached_ground() {
    if (ground == nullptr || ground->sheet.indices.empty()) return;
    const int scene_id = held ? held->id : -1;
    bind_ground(find_ground(grounds, scene_id));
}

std::size_t Display::State::load_mesh(const std::string& mesh) {
    const auto found = kept_by_name.find(mesh);
    if (found != kept_by_name.end()) return found->second;
    const std::filesystem::path path = data_root / io::path_from_utf8("Model") / io::path_from_utf8(mesh + ".glb");
    auto model = resource::load_glb_file(io::utf8_of(path), io::utf8_of(data_root));
    if (!model) {
        std::println(stderr, "Bỏ mesh {}: {}", mesh, model.error());
        return kMissing;
    }
    return keep_model(mesh, baked_mesh(std::move(*model)));
}

std::size_t Display::State::keep_model(const std::string& mesh, ReadMesh read) {
    kept.emplace_back();
    SeatTarget target;
    target.slot = &kept.back();
    target.device = device.get();
    target.forward = forward.get();
    if (!seat_model(target, std::move(read))) {
        kept.pop_back();
        return kMissing;
    }
    const std::size_t index = kept.size() - 1;
    kept_by_name.emplace(mesh, index);
    return index;
}

bool Display::State::keep_ground(int scene_id, ReadMesh read) {
    grounds.emplace_back();
    KeptGround& made = grounds.back();
    made.scene_id = scene_id;
    SeatTarget target;
    target.slot = &made.mesh;
    target.device = device.get();
    target.forward = forward.get();
    if (!seat_model(target, std::move(read))) {
        grounds.pop_back();
        return false;
    }
    if (grounds.size() > kKeptGrounds) grounds.pop_front();
    return true;
}

void Display::State::grow_world(const math::Aabb& local, const math::Matrix4& placed) {
    const math::Aabb moved = math::transform(local, placed);
    world.min = math::min(world.min, moved.min);
    world.max = math::max(world.max, moved.max);
}

void Display::State::push_matrix(const render::Drawable& drawable, const math::Matrix4& placed) {
    render::Instance instance;
    instance.drawable = &drawable;
    instance.world = placed;
    instances.push_back(instance);
}

void Display::State::add_crowd(CrowdFill fill) {
    const std::span<std::size_t> slots = *fill.crowd_of;
    std::size_t slot = core::at(slots, fill.index);
    if (slot == kMissing) {
        slot = crowds.size();
        core::at(slots, fill.index) = slot;
        Crowd crowd;
        crowd.drawable = &kept.at(fill.index).loaded.drawable;
        crowds.push_back(std::move(crowd));
    }
    crowds.at(slot).worlds.push_back(fill.placed);
}

void Display::State::push_crowd(const Crowd& crowd) {
    if (crowd.worlds.empty()) return;
    if (crowd.worlds.size() < 2) {
        push_matrix(*crowd.drawable, crowd.worlds.front());
        return;
    }
    render::Instance instance;
    instance.drawable = crowd.drawable;
    instance.copies = crowd.worlds;
    instances.push_back(instance);
}

void Display::State::push_crowds() {
    for (const Crowd& crowd : crowds) {
        push_crowd(crowd);
    }
}

void Display::State::place_prop(PropPlace place) {
    const std::size_t index = core::at(place.loaded, place.prop->mesh);
    if (index == kMissing) return;
    const math::Aabb& local = kept.at(index).bounds;
    if (!has_points(local)) return;
    const math::Matrix4 placed = world_of(place.prop->world);
    grow_world(local, placed);
    if (!can_batch(kept.at(index).loaded.model)) {
        push_matrix(kept.at(index).loaded.drawable, placed);
        return;
    }
    CrowdFill fill;
    fill.index = index;
    fill.placed = placed;
    fill.crowd_of = place.crowd_of;
    add_crowd(fill);
}

void Display::State::build_instances(const PropTable& table, std::span<const std::size_t> loaded) {
    std::vector<std::size_t> crowd_of(kept.size(), kMissing);
    for (const PlacedProp& prop : table.props) {
        PropPlace place;
        place.prop = &prop;
        place.loaded = loaded;
        place.crowd_of = &crowd_of;
        place_prop(place);
    }
    push_crowds();
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

float Display::State::step_clock(float elapsed) noexcept {
    if (walk_stamp < 0.0F) {
        walk_stamp = elapsed;
        return 0.0F;
    }
    const float dt = std::clamp(elapsed - walk_stamp, 0.0F, kMaxStep);
    walk_stamp = elapsed;
    return dt;
}

void Display::State::ensure_gates() {
    if (gates_ready || data_root.empty()) return;
    gates_ready = true;
    const std::filesystem::path file = data_root / "Config" / "ScenePosDefineEx.txt";
    const io::TextResult text = io::read_text(file);
    if (!text) {
        const std::string_view reason = io::describe(text.error());
        const std::string name = io::utf8_of(file);
        std::println(stderr, "Bảng cổng: {} ({})", reason, name);
        return;
    }
    map::GateResult read = map::read_gates(*text);
    if (!read) {
        const std::string_view reason = map::describe(read.error());
        std::println(stderr, "Bảng cổng: {}", reason);
        return;
    }
    gates = std::move(*read);
}

void Display::State::place_at(int scene_id) {
    ensure_gates();
    map::SceneStep step;
    step.previous = walk.scene_id;
    step.scene = scene_id;
    const map::GateStand stand = map::arrival_at(gates, step);
    place_walk(walk, *ground, scene_id, stand);
}

// Khung không có người chơi (thủ tục đăng nhập, cảnh không có địa hình): camera là tư thế cố định
// của màn đăng nhập, hoặc xoay quanh hộp bao thế giới; nút và vị trí chuột vẫn tới giao diện. Phím
// và thao tác của màn chơi không có camera cảnh nào nhận nên bị bỏ; trước đây cả hàng chờ nằm lại,
// giao diện không thấy cú bấm nào.
render::Camera Display::State::idle_view(FrameAsk ask) {
    const Taken taken = take_steering();
    view_size = ask.size;
    take_events(taken.events);
    if (procedure == Procedure::kLogin) step_role_stage();
    close_mouse_frame();
    if (procedure == Procedure::kLogin && shows_role_scene()) return role_scene_camera(ask.size);
    if (procedure == Procedure::kLogin) return login_camera(ask.size);
    return orbit_view(ask.elapsed, world, ask.size);
}

// Thủ tục đăng nhập có cảnh nền và mặt đất nhưng không có người chơi: không dựng mặt đất cho camera
// bám theo, nên compose_frame cũng không đặt nhân vật vào cảnh.
render::Camera Display::State::frame_camera(FrameAsk ask) {
    if (procedure == Procedure::kLogin) return idle_view(ask);
    if (ground == nullptr || ground->heights.samples.empty()) return idle_view(ask);
    const int scene_id = held ? held->id : -1;
    if (walk.scene_id != scene_id) place_at(scene_id);
    if (terrain_scene != scene_id) rebuild_terrain(scene_id);
    if (!terrain) return idle_view(ask);
    const core::Clock::time_point now = core::Clock::now();
    const Taken taken = take_steering();
    view_size = ask.size;
    take_events(taken.events);
    const float delta_seconds = step_clock(ask.elapsed);
    enter_camera(scene_id);
    steer_camera(taken.keys);
    pilot_frame(now, delta_seconds);
    hold_stick_frame(now);
    publish_cursor();
    move_player(taken.keys, delta_seconds);
    // NOLINTNEXTLINE(bugprone-unchecked-optional-access): terrain đã kiểm ở đầu hàm
    follow.set_look_at(*terrain, foot());
    const control::CameraPose& pose = follow.pose();
    lens = lens_of(pose, aspect_of(ask.size));
    has_lens = true;
    return camera_of(pose, ask.size);
}

// Sự kiện tới theo thứ tự; cái nào chưa dùng được ở khung này thì nó và mọi cái sau nó quay lại
// đầu hàng chờ.
void Display::State::take_events(std::span<const control::InputEvent> events) {
    std::size_t used = 0;
    while (used < events.size() && absorb(events[used])) {
        ++used;
    }
    if (used == events.size()) return;
    const std::span<const control::InputEvent> rest = events.subspan(used);
    const std::scoped_lock<std::mutex> locked(steer_guard);
    queued.insert(queued.begin(), rest.begin(), rest.end());
}

// Lần đầu có mặt đất của một cảnh, như CGamePro_Enter: hướng 3,1415, zoom đã lưu, pitch theo zoom.
void Display::State::enter_camera(int scene_id) {
    if (camera_scene == scene_id || !terrain) return;
    camera_scene = scene_id;
    follow = control::FollowCamera{rules_of(held.get())};
    follow.enter(*terrain, foot(), saved_zoom);
    pilot.enter(saved_zoom);
}

// Phím của cửa sổ: lên xuống là lệnh phím zoom của bản gốc, V là ResetCamera; trái phải là phím
// xoay của bản 2008, bản 2026 không còn.
void Display::State::steer_camera(const Steering& keys) {
    if (!terrain) return;
    if (keys.turn_keys != 0) control::key_turn(follow, *terrain, keys.turn_keys);
    const control::ZoomWay way = keys.zoom_keys > 0 ? control::ZoomWay::kCloser : control::ZoomWay::kFarther;
    for (int press = 0; press < std::abs(keys.zoom_keys); ++press) {
        control::key_zoom(follow, *terrain, way);
    }
    if (keys.is_home) pilot.reset_camera(follow, *terrain);
}

control::MouseSample Display::State::mouse_sample() const noexcept {
    const auto width = static_cast<float>(view_size.width);
    const auto height = static_cast<float>(view_size.height);
    control::MouseSample mouse;
    mouse.x = static_cast<int>(pointer.x * width);
    mouse.y = static_cast<int>(pointer.y * height);
    mouse.dx = drag_x;
    mouse.dy = drag_y;
    mouse.is_left_down = is_button_down[static_cast<std::size_t>(control::MouseButton::kLeft)];
    mouse.is_middle_down = is_button_down[static_cast<std::size_t>(control::MouseButton::kMiddle)];
    mouse.is_right_down = is_button_down[static_cast<std::size_t>(control::MouseButton::kRight)];
    mouse.is_wheel_up = is_wheel_up;
    mouse.is_wheel_down = is_wheel_down;
    return mouse;
}

// Một khung của CGamePro_Main: chuột thành lệnh đi và chỉnh camera, rồi phần camera tự động.
void Display::State::pilot_frame(core::Clock::time_point now, float seconds) {
    if (!terrain) return;
    control::PilotFrame frame;
    frame.mouse = mouse_sample();
    frame.now = now;
    frame.seconds = seconds;
    frame.is_over_ui = is_hud_press || is_on_hud(pointer);
    frame.is_player_moving = is_player_running;
    frame.under_cursor = pick_at(pointer);
    const control::PilotStep step = pilot.frame(follow, *terrain, frame);
    order_move(step.move_to, pilot.auto_run() ? nav::MoveMode::kStraight : nav::MoveMode::kFind);
    close_mouse_frame();
}

// Hết một khung chuột: độ dời, cờ lăn và dấu "nút đã đổi" chỉ sống một khung; nút trái đã nhả
// thì lần nhấn không còn thuộc về giao diện.
void Display::State::close_mouse_frame() noexcept {
    drag_x = 0;
    drag_y = 0;
    is_wheel_up = false;
    is_wheel_down = false;
    has_button_changed = {};
    if (!is_button_down[static_cast<std::size_t>(control::MouseButton::kLeft)]) is_hud_press = false;
}

// Mặt đất để camera bám theo và để chọn điểm bằng tia: cùng gốc, tỉ lệ, độ cao và đường chéo với
// lưới đã vẽ. Đổi cảnh thì bỏ lệnh đi và cần gạt của cảnh cũ, và giữ lại zoom như
// CGamePro_Main::Release ghi biến Camera_Zoom; Camera_SetZoom bỏ qua số ngoài [0, 1] nên kẹp ở đây.
void Display::State::rebuild_terrain(int scene_id) {
    if (terrain && camera_scene) saved_zoom = std::clamp(follow.zoom(*terrain), 0.0F, 1.0F);
    pilot.leave();
    terrain_scene = scene_id;
    terrain.reset();
    order.reset();
    tilt.reset();
    static_cast<void>(stick.release());
    control::GroundShape shape;
    const map::TerrainFile& file = ground->file;
    shape.position = ogre::Vec3{.x = file.origin.x, .y = file.origin.y, .z = file.origin.z};
    shape.scale = ogre::Vec3{.x = file.scale.x, .y = file.scale.y, .z = file.scale.z};
    shape.x_size = file.x_size;
    shape.z_size = file.z_size;
    shape.heights = ground->heights.samples;
    const auto is_flipped = [](const map::Cell& cell) { return (cell.flags & map::kFlipDiagonal) != 0; };
    shape.flipped.reserve(ground->grid.cells.size());
    std::ranges::transform(ground->grid.cells, std::back_inserter(shape.flipped), is_flipped);
    terrain = control::Ground::create(std::move(shape));
}

Display::State::Taken Display::State::take_steering() {
    const std::scoped_lock<std::mutex> locked(steer_guard);
    Taken taken;
    taken.keys = steering;
    taken.events.swap(queued);
    steering.turn_keys = 0;
    steering.zoom_keys = 0;
    steering.is_home = false;
    if (steering.toggles_pace) shows_pace = !shows_pace;
    steering.toggles_pace = false;
    return taken;
}

// false khi sự kiện phải chờ khung sau.
bool Display::State::absorb(const control::InputEvent& event) {
    using Kind = control::InputKind;
    switch (event.kind) {
    case Kind::kPress:
    case Kind::kRelease: return flip_button(event);
    case Kind::kMove: move_pointer(event); break;
    case Kind::kWheel: turn_wheel(event.wheel); break;
    case Kind::kCancel: cancel_left(); break;
    case Kind::kStick: tilt = control::Tilt{.x = event.dx, .y = event.dy}; break;
    case Kind::kStickEnd: release_stick(); break;
    case Kind::kText: typed.push_back(event.text); break;
    }
    return true;
}

// Nhấn hay nhả một nút. Bản gốc đọc nút mỗi nhịp một lần (GetAsyncKeyState), nên một nút chỉ đổi
// trạng thái một lần mỗi khung: lần đổi thứ hai, như cú bấm ngắn hơn một khung, chờ khung sau để
// không mất. Nhấn trái bắt đầu trên HUD thì thuộc về giao diện tới khi nhả.
bool Display::State::flip_button(const control::InputEvent& event) {
    const auto slot = static_cast<std::size_t>(event.button);
    const bool is_down = event.kind == control::InputKind::kPress;
    if (is_button_down.at(slot) == is_down) return true;
    if (has_button_changed.at(slot)) return false;
    pointer = control::ScreenPoint{.x = event.x, .y = event.y};
    is_button_down.at(slot) = is_down;
    has_button_changed.at(slot) = true;
    const bool is_left_press = is_down && event.button == control::MouseButton::kLeft;
    if (is_left_press) is_hud_press = is_on_hud(pointer);
    return true;
}

// Thao tác trái bị huỷ (ngón thứ hai chạm xuống, mất focus): không thành lệnh đi và không còn giữ
// nút. Còn để nút trái là đang giữ thì giao diện bỏ qua lần bấm kế tiếp.
void Display::State::cancel_left() noexcept {
    pilot.cancel_left();
    is_button_down[static_cast<std::size_t>(control::MouseButton::kLeft)] = false;
    is_hud_press = false;
}

// Độ dời cộng dồn cho cả khung, như MouseTick lấy vị trí nhịp này trừ nhịp trước.
void Display::State::move_pointer(const control::InputEvent& event) {
    pointer = control::ScreenPoint{.x = event.x, .y = event.y};
    drag_x += static_cast<int>(event.dx);
    drag_y += static_cast<int>(event.dy);
}

// Nấc lăn nguyên thành cờ lăn lên hay xuống của nhịp, như WM_MOUSEWHEEL đặt cờ cho MouseTick: lăn
// mấy nấc trong một khung cũng chỉ là một sự kiện. Phần lẻ (bàn rê) để dành cho lần sau. Giao diện
// nhận mỗi sự kiện một nấc, dồn không quá kHudWheelCap nấc giữa hai khung.
void Display::State::turn_wheel(float notches) {
    wheel_carry += notches;
    const float whole = std::trunc(wheel_carry);
    wheel_carry -= whole;
    if (whole > 0.0F) is_wheel_up = true;
    if (whole < 0.0F) is_wheel_down = true;
    if (whole != 0.0F) hud_wheel = std::clamp(hud_wheel + (whole > 0.0F ? 1 : -1), -kHudWheelCap, kHudWheelCap);
}

void Display::State::release_stick() {
    tilt.reset();
    apply_stick_step(stick.release());
}

// Hover để trống: chưa có danh sách NPC. Cửa sổ đọc loại này rồi gắn ảnh Interface/cursor; nullopt
// là đang kéo camera, cửa sổ ẩn và giữ con trỏ.
void Display::State::publish_cursor() noexcept {
    const bool is_left_down = is_button_down[static_cast<std::size_t>(control::MouseButton::kLeft)];
    control::CursorState state;
    state.auto_run = pilot.auto_run();
    state.primary_down = is_left_down && !is_hud_press;
    state.camera_held = pilot.holds_cursor();
    const std::optional<control::CursorKind> kind = control::choose_cursor(state);
    const auto hidden = static_cast<std::uint8_t>(control::kCursorKinds);
    const std::uint8_t bits = kind ? static_cast<std::uint8_t>(*kind) : hidden;
    cursor_bits.store(bits, std::memory_order_relaxed);
}

// Hướng của cần là hướng camera nhìn chiếu xuống mặt đất, từ mắt tới chân nhân vật, toạ độ game.
void Display::State::hold_stick_frame(core::Clock::time_point now) {
    if (!tilt || !terrain || !has_lens) return;
    const core::GroundPoint feet = terrain->to_game(foot());
    const core::GroundPoint eye = terrain->to_game(lens.eye);
    const core::GroundPoint ahead{.x = feet.x - eye.x, .z = feet.z - eye.z};
    const control::StickStep sample = stick.hold(feet, ahead, *tilt, now);
    apply_stick_step(sample);
}

void Display::State::apply_stick_step(const control::StickStep& step) {
    if (step.order == control::StickOrder::kMove) order_move(step.target, nav::MoveMode::kStraight);
    if (step.order == control::StickOrder::kStop) order.reset();
}

// Lệnh đi tới một điểm, đơn vị game, theo luật của client 2026 (nav::Field::plan_move): nhấp chuột
// thì tìm đường vòng qua vật cản, giữ chuột hay cần gạt thì đi thẳng tới sát vật cản. Lệnh bị luật
// từ chối thì lệnh đang chạy giữ nguyên, như bản gốc. Cảnh không có lưới đi thì đi thẳng tới điểm.
void Display::State::order_move(std::optional<core::GroundPoint> target, nav::MoveMode mode) {
    if (!target || !terrain || ground == nullptr || !scale_ok(ground->file)) return;
    const nav::Segment walk_line{.start = game_of(ground->file, walk), .end = *target};
    const nav::MoveAsk ask{.walk = walk_line, .mode = mode};
    WalkOrder given;
    if (walk_field == nullptr) given.path.push_back(*target);
    if (walk_field != nullptr) given.path = walk_field->plan_move(ask, scratch);
    if (given.path.empty()) return;
    order = std::move(given);
}

// Mặt đất dưới con trỏ, theo thông số nhìn của khung trước.
std::optional<core::GroundPoint> Display::State::pick_at(control::ScreenPoint point) const {
    if (!terrain || !has_lens) return std::nullopt;
    if (view_size.width == 0 || view_size.height == 0) return std::nullopt;
    return control::pick_ground(*terrain, lens, point);
}

// Chân nhân vật trên mặt đất, cùng tam giác với lưới đã vẽ.
ogre::Vec3 Display::State::foot() const {
    const float height = terrain ? terrain->height_at(walk.x, walk.z) : 0.0F;
    return ogre::Vec3{.x = walk.x, .y = height, .z = walk.z};
}

// Phím đi bộ thắng lệnh nhấp chuột; không có phím thì đi tiếp theo lệnh (nếu có).
void Display::State::move_player(const Steering& keys, float dt) {
    const bool is_asked = keys.walk_forward != 0.0F || keys.walk_right != 0.0F;
    if (is_asked) order.reset();
    if (is_asked) walk_free(keys, dt);
    if (!is_asked) walk_order(dt);
}

// Một khung Tick_Move rồi Map::VerifyPos. Chỗ đứng thế giới là Axis_Trans GAME sang GFX.
void Display::State::apply_tick(motion::MoveAsk ask) {
    const motion::MoveStep step = motion::move_tick(ask);
    if (!step.moved) is_player_running = false;
    if (step.moved) place_step(step, ask.here);
    if (step.arrived) finish_leg();
}

// Tới điểm đang hướng tới: lệnh còn điểm sau thì đi tiếp và vẫn tính là đang chạy, hết điểm thì
// xong lệnh.
void Display::State::finish_leg() {
    if (!order) return;
    ++order->next;
    const bool has_more = order->next < order->path.size();
    if (has_more) is_player_running = true;
    if (!has_more) order.reset();
}

void Display::State::place_step(const motion::MoveStep& step, core::GroundPoint from) {
    if (ground == nullptr || !scale_ok(ground->file)) return;
    const map::TerrainFile& file = ground->file;
    motion::MapLimit limit;
    limit.width = static_cast<float>(file.x_size);
    limit.depth = static_cast<float>(file.z_size);
    const core::GroundPoint clamped = motion::verify_pos(step.position, limit);
    walk.x = file.origin.x + (clamped.x * file.scale.x);
    walk.z = file.origin.z + (clamped.z * file.scale.z);
    facing = step.facing;
    const bool is_shifted = clamped.x != from.x || clamped.z != from.z;
    is_player_running = is_shifted && !step.arrived;
}

// Đi theo phím W A S D so với hướng nhìn của camera. Tốc độ là chạy (MOVE_MODE_RUN).
void Display::State::walk_free(const Steering& keys, float dt) {
    if (ground == nullptr || !scale_ok(ground->file)) return;
    const map::TerrainFile& file = ground->file;
    const float direction = follow.direction();
    const float ahead_x = std::sin(direction);
    const float ahead_z = std::cos(direction);
    const float world_x = (ahead_x * keys.walk_forward) - (ahead_z * keys.walk_right);
    const float world_z = (ahead_z * keys.walk_forward) + (ahead_x * keys.walk_right);
    const float game_x = world_x / file.scale.x;
    const float game_z = world_z / file.scale.z;
    const float length = std::sqrt((game_x * game_x) + (game_z * game_z));
    if (!(length > 0.0F)) {
        is_player_running = false;
        return;
    }
    const float speed = motion::human_speed(motion::MoveMode::kRun);
    const float reach = (speed * dt) + 1.0F;
    const core::GroundPoint here = game_of(file, walk);
    motion::MoveAsk ask;
    ask.here = here;
    ask.target.x = here.x + ((game_x / length) * reach);
    ask.target.z = here.z + ((game_z / length) * reach);
    // Phím đi không có ở bản gốc: bước dừng trước vật cản đầu tiên, không bao giờ kết thúc trong nó.
    if (walk_field != nullptr) ask.target = walk_field->step_reach(nav::Segment{.start = here, .end = ask.target});
    ask.speed = speed;
    ask.seconds = dt;
    apply_tick(ask);
}

// Đi theo lệnh: một khung Tick_Move tới điểm đang hướng tới của lệnh, tốc độ chạy.
void Display::State::walk_order(float dt) {
    is_player_running = false;
    if (!order || ground == nullptr || !scale_ok(ground->file)) return;
    motion::MoveAsk ask;
    ask.here = game_of(ground->file, walk);
    ask.target = order->path[order->next];
    ask.speed = motion::human_speed(motion::MoveMode::kRun);
    ask.seconds = dt;
    apply_tick(ask);
}

void Display::State::load_player() {
    if (catalog) {
        const core::Status tier = catalog->prepare(render::Tier::kEssential);
        if (!tier) std::println(stderr, "Pipeline: tầng chơi: {}", tier.error());
    }
    if (data_root.empty()) return;
    PlayerDesc desc;
    desc.data_root = data_root;
    if (has_role_look) desc.race = role_race;
    if (has_role_look) desc.look = role_look;
    const MeshLoader loader = [this](const std::string& mesh) -> const render::Drawable* {
        const std::size_t index = load_mesh(mesh);
        return index == kMissing ? nullptr : &kept.at(index).loaded.drawable;
    };
    auto made = PlayerActor::create(desc, loader);
    if (!made) {
        std::println(stderr, "Không có người chơi: {}", made.error());
        return;
    }
    player.emplace(std::move(*made));
    std::println("Người chơi: {} bộ phận", player->figure().parts.size());
    load_head(desc, loader);
}

// Ảnh đầu 3D cho ô chân dung: một bản mô hình cùng ngoại hình với người chơi. Không dựng được thì
// ghi một dòng và bỏ qua.
void Display::State::load_head(const PlayerDesc& desc, const MeshLoader& loader) {
    if (!ui_pass || head) return;
    HeadShotDesc shot;
    shot.player = desc;
    shot.forward = forward.get();
    shot.color_format = screen->color_format();
    shot.depth_format = screen->depth_format();
    shot.samples = screen->samples();
    core::Result<HeadShot> made = HeadShot::create(*device, shot, loader);
    if (!made) {
        std::println(stderr, "Chân dung: không dựng được đầu 3D: {}", made.error());
        return;
    }
    const core::Result<std::uint32_t> texture = ui_pass->add_view(made->view());
    if (!texture) {
        std::println(stderr, "Chân dung: không gắn được ảnh đầu: {}", texture.error());
        return;
    }
    head.emplace(std::move(*made));
    ui::ViewPaint& view = head_views.front();
    view.name = ui::kPlayerHead;
    view.texture = *texture;
    view.is_bottom_up = head->is_bottom_up();
}

// Vẽ ảnh đầu vào đích riêng của nó, sau khi lượt vẽ màn hình đã đóng: giao diện của khung kế lấy
// mẫu ảnh này. Ghi ở cuối khung để khung bị bỏ (bề mặt đổi cỡ) không để lại ảnh đích dở dang.
void Display::State::record_head(gpu::CommandList& list) {
    if (!head) return;
    const std::uint32_t count = screen->image_count();
    const std::uint32_t slot = count + (head_turns % count);
    const core::Status drawn = head->record(list, slot);
    if (!drawn) std::println(stderr, "Chân dung: {}", drawn.error());
    ++head_turns;
}

namespace {

// Ngoại hình mà mô hình của giao diện đòi, để so với thứ RoleShot đang vẽ.
[[nodiscard]] RoleLook role_look_of(const ui::panel::ShownModel& model) noexcept {
    RoleLook look;
    look.sex = model.sex;
    look.face = model.face;
    look.hair = model.hair;
    look.body = model.body;
    look.arm = model.arm;
    look.foot = model.foot;
    look.sect = model.sect;
    return look;
}

} // namespace

PlayerDesc Display::State::role_player(const ui::panel::ShownModel& model) const {
    PlayerDesc desc;
    desc.data_root = data_root;
    desc.race = model.sex == 0 ? look::Race::kFemale : look::Race::kMale;
    look::Look worn;
    worn.face = model.face;
    worn.hair = model.hair;
    worn.body = model.body;
    worn.arm = model.arm;
    worn.foot = model.foot;
    desc.look = worn;
    if (model.sect >= 0) desc.sect = static_cast<std::uint8_t>(model.sect);
    return desc;
}

MeshLoader Display::State::meshes() {
    return [this](const std::string& mesh) -> const render::Drawable* {
        const std::size_t index = load_mesh(mesh);
        return index == kMissing ? nullptr : &kept.at(index).loaded.drawable;
    };
}

// Người mẫu dựng một lần; đổi mặt, tóc hay bộ đồ thì nạp lại lưới (RoleShot::retarget).
void Display::State::open_role(const ui::panel::ShownModel& model) {
    if (role_shot) return;
    core::Result<RoleShot> made = RoleShot::create(role_player(model), meshes());
    if (!made) {
        std::println(stderr, "Nhân vật: không dựng được mô hình: {}", made.error());
        return;
    }
    role_shot.emplace(std::move(*made));
}

bool Display::State::shows_world_role() const {
    if (procedure != Procedure::kLogin || !hud) return false;
    return hud->role_model().in_world;
}

bool Display::State::shows_role_scene() const {
    if (procedure != Procedure::kLogin || !hud) return false;
    return hud->role_model().on_role_scene;
}

// Camera của cảnh chọn nhân vật: tư thế mà phần thủ tục (role_stage) vừa tính ở khung này.
render::Camera Display::State::role_scene_camera(render::ViewSize size) const {
    const std::optional<control::TrackPose> pose = role_stage.camera();
    if (!pose) return login_camera(size);
    return role_pose_camera(pose->eye, pose->look, size);
}

// Một nhịp của thủ tục chọn hay tạo nhân vật phía camera. Gọi trước khi xoá cờ lăn của khung.
void Display::State::step_role_stage() {
    if (!hud || !shows_role_scene()) {
        role_stamp.reset();
        return;
    }
    const core::Clock::time_point now = core::Clock::now();
    StageFrame frame;
    frame.now_ms =
        static_cast<std::uint32_t>(std::chrono::duration_cast<std::chrono::milliseconds>(now - started).count());
    if (role_stamp) frame.seconds = std::chrono::duration<float>(now - *role_stamp).count();
    // Chuột nằm trên khung cuộn chữ của giao diện thì nấc lăn thuộc về khung đó, camera không phóng.
    const bool is_ui_wheel = hud->takes_wheel(pointer.x * static_cast<float>(screen->width()),
        pointer.y * static_cast<float>(screen->height()));
    frame.is_wheel_up = is_wheel_up && !is_ui_wheel;
    frame.is_wheel_down = is_wheel_down && !is_ui_wheel;
    role_stamp = now;
    role_stage.step(hud->role_model(), frame);
}

void Display::State::append_login_role() {
    if (!shows_world_role()) return;
    const ui::panel::ShownModel& model = hud->role_model();
    open_role(model);
    if (!role_shot) return;
    RoleShot& shot = *role_shot;
    const RoleLook look = role_look_of(model);
    const bool is_ready = shot.matches(look) || shot.retarget(role_player(model), meshes());
    if (!is_ready) return;
    Stand stand;
    stand.foot = point_of(model.is_creating ? control::kCreateFeet : control::role_place(model.slot).feet);
    stand.scale = model.is_creating ? control::kCreateScale : 1.0F;
    stand.facing = model.yaw;
    const core::Status posed = shot.pose(stand);
    if (!posed) {
        std::println(stderr, "Nhân vật: {}", posed.error());
        return;
    }
    shot.append(frame_instances);
}

// Instance của khung: cảnh tĩnh rồi người chơi (nếu có), dựng tư thế mới theo điểm đứng.
void Display::State::compose_frame() {
    frame_instances = instances;
    append_login_role();
    if (!player || ground == nullptr || !terrain) return;
    Stand stand;
    stand.foot = point_of(foot());
    stand.facing = facing;
    stand.is_moving = is_player_running;
    const core::Status posed = player->update(core::Clock::now(), stand);
    if (!posed) {
        std::println(stderr, "Người chơi: {}", posed.error());
        return;
    }
    player->append(frame_instances);
}

// Giao diện của khung: đưa đầu vào (kể cả ký tự vừa gõ) rồi lấy việc nó nhờ vòng cửa sổ làm.
void Display::State::prepare_hud() {
    if (!hud) return;
    hud->prepare(hud_view());
    typed.clear();
    hud_wheel = 0;
    const std::optional<ui::Action> action = hud->take_action();
    if (action) post_request(*action);
    store_roles();
}

void Display::State::post_request(ui::Action action) {
    const auto found = std::ranges::find(kActionRequests, action, &ActionRequest::action);
    if (found == kActionRequests.end()) return;
    const std::scoped_lock<std::mutex> locked(request_guard);
    requests.push_back(found->request);
}

// Đầu vào của HUD ở khung này: cỡ khung, chuột theo điểm ảnh, nhân vật, đồng hồ, và cảnh cùng chỗ
// đứng, hướng mặt cho minimap.
ui::HudView Display::State::hud_view() const {
    const auto width = static_cast<float>(screen->width());
    const auto height = static_cast<float>(screen->height());
    ui::HudView view;
    view.phase = procedure == Procedure::kLogin ? ui::Phase::kLogin : ui::Phase::kPlay;
    view.width = width;
    view.height = height;
    view.hero = &hero;
    if (head_turns > 0) view.views = head_views;
    view.clock = std::chrono::duration_cast<std::chrono::milliseconds>(core::Clock::now() - started);
    view.pointer.emplace();
    view.pointer->x = pointer.x * width;
    view.pointer->y = pointer.y * height;
    view.pointer->is_down = is_button_down[static_cast<std::size_t>(control::MouseButton::kLeft)];
    view.typed = typed;
    view.wheel = hud_wheel;
    view.loading = scene_load();
    if (!held || !terrain) return view;
    const core::GroundPoint feet = terrain->to_game(foot());
    view.scene.radar = held->radar;
    view.scene.width = static_cast<float>(held->x_size);
    view.scene.depth = static_cast<float>(held->z_size);
    view.scene.player_x = feet.x;
    view.scene.player_z = feet.z;
    view.scene.name = held->name;
    view.scene.facing = facing;
    view.scene.id = held->id;
    return view;
}

// Việc nạp cảnh mà bảng chuyển cảnh của giao diện báo cho người chơi: cảnh của màn chơi đang được
// nạp, kèm phần mesh đã đặt xong. Thủ tục đăng nhập đổi cảnh nền thì không báo (bản gốc chỉ phát
// PLAYER_LEAVE_WORLD khi rời một cảnh của thế giới). Trước khi mặt đất sẵn thì phần trăm là 0.
std::optional<ui::SceneLoad> Display::State::scene_load() const {
    if (procedure != Procedure::kPlay || !arrival.has_value() || !arrival->scene) return std::nullopt;
    ui::SceneLoad load;
    load.name = arrival->scene->name;
    const std::size_t total = arrival->table.meshes.size();
    if (arrival->ground_done && total > 0) {
        load.percent = static_cast<std::int32_t>((std::min(arrival->cursor, total) * 100U) / total);
    }
    return load;
}

bool Display::State::is_on_hud(control::ScreenPoint point) const {
    if (!hud) return false;
    const auto width = static_cast<float>(screen->width());
    const auto height = static_cast<float>(screen->height());
    return hud->contains(point.x * width, point.y * height);
}

void Display::State::fill_pace_board() {
    pace_board.vertices.clear();
    pace_board.batches.clear();
    if (!pace_font || !shows_pace) return;
    ui::PacePlace place;
    place.font = &*pace_font;
    place.texture = pace_texture;
    place.origin_x = 16.0F;
    place.origin_y = 210.0F;
    ui::write_pace(place, pace_shown, pace_board);
}

void Display::State::prepare_board() {
    prepare_hud();
    fill_pace_board();
}

void Display::State::stamp_phases(const FrameMarks& marks) {
    pace_last.acquire_ms = static_cast<float>(millis_between(marks.asked, marks.acquired));
    pace_last.draw_ms = static_cast<float>(millis_between(marks.acquired, marks.recorded));
    pace_last.submit_ms = static_cast<float>(millis_between(marks.recorded, core::Clock::now()));
    pace_last.draws = scene_draws;
    const std::size_t quads = hud ? hud->quad_count() : 0;
    pace_last.quads = static_cast<std::uint32_t>(quads);
    phase_ms.acquire += static_cast<double>(pace_last.acquire_ms);
    phase_ms.draw += static_cast<double>(pace_last.draw_ms);
    phase_ms.submit += static_cast<double>(pace_last.submit_ms);
    ++phase_ms.frames;
}

void Display::State::ensure_clock() {
    if (frame_clock) return;
    core::TickConfig config;
    config.hz = kPaceHz;
    config.max_steps = 1;
    core::Result<core::FixedStep> made = core::FixedStep::create(config);
    if (!made) return;
    frame_clock = *made;
}

void Display::State::hold_pace(double spent_ms) {
    if constexpr (kIsMobile) return;
    // Việc của khung đã nuốt hết một nhịp 120 Hz thì trình ngay. Ngủ thêm biến khung nạp thành
    // hai nhịp (đo: đưa đất 15 ms rồi ngủ 8 ms thành khung 26 ms).
    if (spent_ms >= 1000.0 / static_cast<double>(kPaceHz)) return;
    ensure_clock();
    if (!frame_clock) return;
    static_cast<void>(frame_clock->advance(core::Clock::now()));
    const std::optional<core::Clock::time_point> next = frame_clock->next_tick();
    if (!next) return;
    core::sleep_until(*next);
}

void Display::State::record_interval(IntervalNote note) {
    frame_ms.push_back(note.interval);
    note_pace(note.interval);
    SpikeParts spike;
    spike.interval = note.interval;
    spike.load_ms = last_load_ms;
    spike.render_ms = note.render_ms;
    spike.pace_ms = note.pace_ms;
    spike.acquire_ms = pace_last.acquire_ms;
    spike.draw_ms = pace_last.draw_ms;
    spike.submit_ms = pace_last.submit_ms;
    spike.prepare_ms = last_prepare_ms;
    report_spike(spike);
}

void Display::State::note_pace(double interval) {
    constexpr std::size_t kPaceWindow = 90;
    pace_ring.at(pace_cursor) = static_cast<float>(interval);
    pace_cursor = (pace_cursor + 1) % kPaceWindow;
    if (pace_filled < kPaceWindow) ++pace_filled;
    ui::PaceNumbers phases;
    phases.acquire_ms = pace_last.acquire_ms;
    phases.draw_ms = pace_last.draw_ms;
    phases.submit_ms = pace_last.submit_ms;
    phases.draws = pace_last.draws;
    phases.ui_quads = pace_last.quads;
    const std::span<const float> samples(pace_ring.data(), pace_filled);
    pace_shown = ui::pace_of(samples, phases);
    pace_shown.last_ms = static_cast<float>(interval);
}

core::Status Display::State::paint_hud(gpu::CommandList& list, std::uint32_t slot) const {
    if (!hud || is_bare) return core::ok();
    ui::Hud::HudExtra extra;
    extra.vertices = pace_board.vertices;
    extra.batches = pace_board.batches;
    return hud->draw(list, slot, extra);
}

void Display::State::advance_fx(float elapsed) {
    if (!fx_view) return;
    const float raw = elapsed - fx_stamp;
    const float step = fx_stamp < 0.0F ? 0.016F : std::min(raw, kMaxStep);
    fx_stamp = elapsed;
    fx_view->advance(step);
}

namespace {

[[nodiscard]] math::Quat fx_quat(ogre::Quat value) {
    return {value.x, value.y, value.z, value.w};
}

[[nodiscard]] math::Vector3 fx_vec(ogre::Vec3 value) {
    return {value.x, value.y, value.z};
}

// [R | t] rồi nhân scale: T * R * S, đúng nút OGRE.
[[nodiscard]] math::Matrix4 fx_placed(ogre::Vec3 position, ogre::Quat orientation, ogre::Vec3 scale) {
    const math::Transform3 spin(fx_quat(orientation), fx_vec(position));
    return math::Matrix4(spin) * math::Matrix4::scale(fx_vec(scale));
}

} // namespace

std::size_t Display::State::fx_mesh_slot(const fx::Field& field) {
    if (field.definition().renderer != fx::RendererKind::kMesh) return kMissing;
    if (field.definition().mesh_name.empty()) return kMissing;
    return load_mesh(field.definition().mesh_name);
}

void Display::State::push_fx_field(const fx::Field& field, std::size_t slot) {
    if (slot == kMissing) return;
    const fx::Node& node = field.node();
    const math::Matrix4 parent = fx_placed(node.position, node.orientation, node.scale);
    const render::Drawable& drawable = kept.at(slot).loaded.drawable;
    for (const fx::MeshPose& pose : fx::mesh_poses(field)) {
        render::Instance instance;
        instance.drawable = &drawable;
        instance.world = parent * fx_placed(pose.position, pose.orientation, pose.scale);
        frame_instances.push_back(instance);
    }
}

void Display::State::append_fx_meshes() {
    if (!fx_view) return;
    const std::vector<const fx::Field*> live = fx_view->fields();
    std::vector<std::size_t> slots;
    slots.reserve(live.size());
    for (const fx::Field* field : live) {
        slots.push_back(fx_mesh_slot(*field));
    }
    for (std::size_t index = 0; index < live.size(); ++index) {
        push_fx_field(*live[index], slots[index]);
    }
}

void Display::State::draw_fx(const FxAsk& ask) const {
    if (!fx_view) return;
    fx_view->draw(*ask.list, ask.slot, *ask.camera);
}

core::Status Display::State::present_drawn(PresentAsk ask) const {
    const core::Status submitted = submit_frame(*ask.list);
    if (!submitted) {
        discard_shot(*device, ask.shot);
        return submitted;
    }
    if (ask.shot) finish_shot(*ask.shot);
    return submitted;
}

core::Status Display::State::render() {
    stale_flag = false;
    wait_flag = false;
    const core::Clock::time_point asked = core::Clock::now();
    prepare_board();
    last_prepare_ms = millis_between(asked, core::Clock::now());
    const core::Clock::time_point drawing = core::Clock::now();
    const core::Result<gpu::CommandList*> list = device->begin_commands(gpu::QueueType::kGraphics);
    if (!list) return std::unexpected(list.error());
    screen->set_clear(light.clear_color());
    const core::Result<std::uint32_t> slot = screen->begin(**list);
    // Bề mặt đổi cỡ giữa chừng: bỏ khung này, spin() dựng lại ở khung kế.
    const bool is_wait = !slot && slot.error().code() == core::ErrorCode::kTimeout;
    if (is_wait) {
        wait_flag = true;
        return device->end_frame();
    }
    const bool is_stale = !slot && slot.error().code() == core::ErrorCode::kInvalidState;
    stale_flag = is_stale;
    if (is_stale) return device->end_frame();
    if (!slot) return std::unexpected(slot.error());
    const core::Clock::time_point acquired = core::Clock::now();
    const core::Status shown = draw_world(**list, *slot);
    if (!shown) return shown;
    const core::Clock::time_point recorded = core::Clock::now();
    screen->end(**list);
    scene_draws = forward->draw_count();
    record_head(**list);
    const std::optional<ShotPlan> shot = record_shot(**list, *slot);
    const PresentAsk present{.list = *list, .shot = shot};
    const core::Status submitted = present_drawn(present);
    if (!submitted) return submitted;
    const core::Status ended = device->end_frame();
    // Chia thời gian khung vào ba chặng để biết chặng nào chặn: xin ảnh (chờ GPU nhả ảnh cũ), ghi
    // lệnh vẽ, và nộp + trình bày (chờ vblank hoặc chờ GPU). Số in ra là trung bình mỗi khung.
    const FrameMarks marks{.asked = drawing, .acquired = acquired, .recorded = recorded};
    stamp_phases(marks);
    return ended;
}

core::Status Display::State::draw_world(gpu::CommandList& list, std::uint32_t slot) {
    const float elapsed = std::chrono::duration<float>(core::Clock::now() - started).count();
    FrameAsk ask;
    ask.elapsed = elapsed;
    ask.size = render::ViewSize{.width = screen->width(), .height = screen->height()};
    const render::Camera camera = ask.size.height > 0 ? frame_camera(ask) : render::Camera{};
    advance_fx(elapsed);
    compose_frame();
    append_fx_meshes();
    const render::Lighting lighting = light.view();
    const core::Status drawn = forward->draw(list, slot, camera, lighting, frame_instances);
    if (!drawn) return drawn;
    const FxAsk effects{.list = &list, .camera = &camera, .slot = slot, .elapsed = elapsed};
    draw_fx(effects);
    return paint_hud(list, slot);
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
    if (shot_taken || shot_path.empty() || arrival.has_value()) return std::nullopt;
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
    ShotPlan plan;
    plan.staging = *made;
    plan.size = buffer.size;
    plan.stride = stride;
    plan.width = width;
    plan.height = height;
    plan.format = *format;
    return plan;
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
    capture::FrameView taken;
    taken.pixels = pixels;
    taken.width = plan.width;
    taken.height = plan.height;
    taken.stride = plan.stride;
    taken.format = plan.format;
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
    reported_draws.store(scene_draws, std::memory_order_relaxed);
}

void Display::State::keep(const core::Status& failure) noexcept {
    const std::scoped_lock<std::mutex> locked(outcome_guard);
    if (!outcome) return;
    outcome = failure;
#ifdef __ANDROID__
    std::string text(failure.error().message());
    const std::string_view extra = failure.error().detail();
    if (!extra.empty()) {
        text.push_back(' ');
        text.append(extra);
    }
    __android_log_write(ANDROID_LOG_ERROR, "THIENLONG", text.c_str());
#endif
}

void Display::State::store_pipeline_cache() const {
    if (device == nullptr || pipeline_cache_file.empty()) return;
    const std::vector<std::byte> bytes = device->pipeline_cache();
    if (bytes.empty()) return;
    std::error_code error;
    std::filesystem::create_directories(pipeline_cache_file.parent_path(), error);
    if (error) {
        std::println(stderr, "Pipeline: không tạo được thư mục cache {}", io::utf8_of(pipeline_cache_file));
        return;
    }
    if (write_bytes(pipeline_cache_file, bytes)) return;
    std::println(stderr, "Pipeline: không ghi được {}", io::utf8_of(pipeline_cache_file));
}

void Display::State::wrap_up() {
    if (is_wrapped || device == nullptr) return;
    is_wrapped = true;
    store_pipeline_cache();
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
    say_rank("Khung hình", rank_frames(sorted), sorted.size());
    const bool has_steady = steady_from && *steady_from + 8 < frame_ms.size();
    if (has_steady) say_steady(frame_ms, *steady_from);
    std::println("Khung bỏ vì đổi cỡ: {}", stale_frames);
    if (phase_ms.frames == 0) return;
    const auto frames = static_cast<double>(phase_ms.frames);
    const std::string acquire_ms = std::format("{:.2f}", phase_ms.acquire / frames);
    const std::string draw_ms = std::format("{:.2f}", phase_ms.draw / frames);
    const std::string submit_ms = std::format("{:.2f}", phase_ms.submit / frames);
    const std::string phases = "Chặng mỗi khung: xin ảnh " + acquire_ms + " ms, ghi lệnh vẽ " + draw_ms +
        " ms, nộp và trình bày " + submit_ms + " ms";
    std::println("{}", phases);
#ifdef __ANDROID__
    __android_log_write(ANDROID_LOG_INFO, "THIENLONG", phases.c_str());
#endif
}

void Display::State::settle() {
    if (spinner.joinable()) {
        spinner.request_stop();
        spinner.join();
    }
    wrap_up();
}

} // namespace game::client

#if defined(__clang__) && defined(__x86_64__)
#pragma clang attribute pop
#endif
