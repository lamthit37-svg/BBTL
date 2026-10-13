// Nội bộ phần đồ hoạ. Chỉ các tệp display/graphic được include.
// Kiểu và hàm từng nằm trong một tệp: tách domain vẫn gọi chung, nên để inline ở đây.
#pragma once
// check.py dịch tệp này một mình, không kèm -msse4.1 mà CMake gắn vào game_math.
// Chỉ cho x86-64: đích ARM không có tính năng này, clang in cảnh báo rồi bỏ qua.
#if defined(__clang__) && defined(__x86_64__)
#pragma clang attribute push(__attribute__((target("sse4.1"))), apply_to = function)
#elif defined(__GNUC__) && defined(__x86_64__)
#pragma GCC target("sse4.1")
#endif
#include "client/display/assets.hpp"
#include "client/display/display.hpp"
#include "client/display/fx_view.hpp"
#include "client/display/lighting.hpp"
#include "client/display/login_data.hpp"
#include "client/display/sky_mesh.hpp"
#include "client/display/water_mesh.hpp"
#include "client/map/gates.hpp"
#include "client/map/ground.hpp"
#include "client/map/picture.hpp"
#include "client/map/sheet.hpp"
#include "client/map/splat.hpp"
#include "client/map/terrain.hpp"
#include "client/world/world.hpp"
#include "control/char_camera.hpp"
#include "fx/cast.hpp"
#include "fx/field.hpp"
#include "fx/mesh.hpp"
#include "fx/system.hpp"

#include "capture/frame.hpp"
#include "capture/png.hpp"
#include "classic/bake.hpp"
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
#include "core/thread.hpp"
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
#include "render/shade.hpp"
#include "render/ui.hpp"
#include "render/view_size.hpp"
#include "resource/image.hpp"
#include "resource/model.hpp"
#include "resource/ogre_mesh.hpp"
#include "resource/tier.hpp"
#include "resource/upload.hpp"
#include "scene/placement.hpp"
#include "scene/transform.hpp"
#include "shader/package.hpp"
#include "ui/hud.hpp"
#include "ui/pace.hpp"
#include "ui/panel/role_pose.hpp"
#include "ui/panel/roles.hpp"
#include "ui/phone.hpp"
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

// Màu nền, ánh sáng tuyến tính; đích vẽ là định dạng sRGB nên màu hiện ra sáng hơn con số này.
inline constexpr gpu::ClearColor kBackdrop{.red = 0.05F, .green = 0.06F, .blue = 0.08F, .alpha = 1.0F};
// Nghỉ giữa hai khung khi cửa sổ đang thu nhỏ, hoặc khi bề mặt chưa sẵn cỡ.
constexpr std::chrono::milliseconds kIdleNap{16};
// Trần nhịp vẽ trên PC khi máy đủ mạnh: 120 Hz. Màn 60 Hz vẫn quét 60 lần, mailbox giữ khung mới nhất
// nên trễ tối đa một nửa nhịp quét. Vượt trần thì bỏ tick, không vẽ bù.

// Nghỉ một nhịp rồi đặt lại mốc đo: lượt sau không phải chịu thời gian ngủ.
inline void nap(core::Clock::time_point& previous) noexcept {
    std::this_thread::sleep_for(kIdleNap);
    previous = core::Clock::now();
}

// Khoảng giữa hai mốc đồng hồ đơn điệu, tính bằng mili giây, cho số đo của một lần nạp cảnh.
[[nodiscard]] inline double millis_between(TimePoint from, TimePoint stop) noexcept {
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
inline void report_spike(const SpikeParts& parts) {
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

[[nodiscard]] inline double rank_at(std::span<const double> sorted, double part) noexcept {
    const auto index = static_cast<std::size_t>(part * static_cast<double>(sorted.size() - 1));
    return sorted[index];
}

inline void count_band(FrameRank& rank, double millis) noexcept {
    if (millis < 12.0) ++rank.under_12;
    if (millis >= 12.0 && millis <= 20.0) ++rank.mid;
    if (millis > 20.0) ++rank.over;
}

[[nodiscard]] inline FrameRank rank_frames(std::span<const double> sorted) noexcept {
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

inline void say_rank(std::string_view title, const FrameRank& rank, std::size_t count) {
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

inline void say_steady(std::span<const double> frames, std::size_t from) {
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
inline constexpr std::chrono::milliseconds kLoadSlice{8};
// Địa hình GPU của từng cảnh vừa xem. Trùng kRemembered của world: đổi lại không tải lại.
constexpr std::size_t kKeptGrounds = 4;
// Camera quay quanh cảnh khi chưa có mặt đất để đứng: góc ban đầu và tốc độ quay mỗi giây. Theo
// đồng hồ đơn điệu chứ không theo số khung: cùng một tốc độ trên mọi tần số quét, và một khung bị
// bỏ (đang kéo cửa sổ, máy bận) không để lại cú giật bù.
constexpr float kYawStart = 0.6F;
constexpr float kYawPerSecond = 0.24F;
// Android và iOS trình Fifo theo Hz của tấm nền (60, 90 hay 120). Ngủ thêm 120 Hz sau Fifo làm
// khung trễ mất nhịp quét. PC mới dùng mailbox và trần 120 Hz. Cờ nền là ui::kPhone.
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
    // Nạp vào nhớ mà không đổi cảnh đang vẽ. Bảng tài khoản hiện erengu, cảnh chọn được đọc
    // song song để lúc bấm vào game chỉ còn đặt ma trận.
    bool prefetch = false;
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

[[nodiscard]] inline PackedSize pack(PixelSize size) noexcept {
    return (static_cast<PackedSize>(size.width) << 32U) | size.height;
}

[[nodiscard]] inline PixelSize unpack(PackedSize packed) noexcept {
    const auto width = static_cast<std::uint32_t>(packed >> 32U);
    const auto height = static_cast<std::uint32_t>(packed & 0xFFFF'FFFFU);
    return {.width = width, .height = height};
}

// Thư mục gói shader của một thư mục dữ liệu: data/shaders (Android giải nén từ APK); không có thì
// rỗng và bộ vẽ dùng mặc định cạnh exe (bố cục CLIENT/bin với CLIENT/data của Windows).
[[nodiscard]] inline std::string shader_dir_of(const std::filesystem::path& data_root) {
    const std::filesystem::path packaged = data_root / "shaders";
    std::error_code ignored;
    return std::filesystem::exists(packaged, ignored) ? packaged.string() : std::string{};
}

[[nodiscard]] inline ForwardResult make_forward(gpu::Device& device, const render::Screen& screen, std::string shaders,
    const render::Catalog& catalog) {
    render::ForwardDesc pass;
    pass.color_format = screen.color_format();
    pass.depth_format = screen.depth_format();
    // Phần đầu cho lượt vẽ màn hình, rồi một phần cho ảnh đầu và một phần cho toàn thân.
    pass.slots = screen.image_count() * 3;
    pass.samples = screen.samples();
    // Backend GLES là chế độ di động (tablet PowerVR): ánh sáng tính ở đỉnh để giữ nhịp khung.
    pass.lights_at_vertices = device.adapter().backend == gpu::Backend::kGles;
    pass.shader_dir = std::move(shaders);
    return render::Forward::create(device, pass, catalog.models(), catalog.get(render::Pso::kTerrain));
}

// Lượt vẽ 2D của giao diện: cùng đích vẽ và thư mục shader với Forward.
[[nodiscard]] inline UiResult make_ui(gpu::Device& device, const render::Screen& screen, std::string shaders,
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
[[nodiscard]] inline MatrixRow row_of(const scene::Transform& placed, std::size_t row) noexcept {
    constexpr std::size_t kRows = 3;
    return core::at(std::span<const std::array<double, 4>, kRows>(placed.rows), row);
}

// Ma trận float cho GPU từ phép đặt double của cảnh: phần tử (hàng i, cột j) của [R * S | T] thành
// cột j của Matrix4, làm tròn về float đúng như scene/transform.hpp đã hứa.
[[nodiscard]] inline math::Matrix4 world_of(const scene::Transform& placed) noexcept {
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
[[nodiscard]] inline render::Camera orbit_view(float elapsed, const math::Aabb& bounds,
    render::ViewSize size) noexcept {
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

[[nodiscard]] inline bool scale_ok(const map::TerrainFile& file) noexcept {
    if (file.x_size <= 0 || file.z_size <= 0) return false;
    return file.scale.x > 0.0F && file.scale.z > 0.0F;
}

// Chỗ đứng hiện tại, đơn vị game. Axis_Trans GFX sang GAME, chỉ X và Z.
[[nodiscard]] inline core::GroundPoint game_of(const map::TerrainFile& file, const WalkPose& pose) noexcept {
    return {.x = (pose.x - file.origin.x) / file.scale.x, .z = (pose.z - file.origin.z) / file.scale.z};
}

// Mặt công trình chỉ nâng chân lên trên địa hình. height là mặt trên cùng, đơn vị game.
[[nodiscard]] inline float surface_y(const world::ShownScene* shown, const map::Ground* ground, float x, float z,
    float terrain_y) noexcept {
    if (shown == nullptr || !shown->buildings || ground == nullptr) return terrain_y;
    const map::TerrainFile& file = ground->file;
    if (!scale_ok(file) || !(file.scale.y > 0.0F)) return terrain_y;
    const float game_x = (x - file.origin.x) / file.scale.x;
    const float game_z = (z - file.origin.z) / file.scale.z;
    const std::optional<float> game_y = shown->buildings->height(game_x, game_z);
    if (!game_y) return terrain_y;
    const float world_y = file.origin.y + (*game_y * file.scale.y);
    if (!(world_y > terrain_y)) return terrain_y;
    return world_y;
}

[[nodiscard]] inline bool cell_open_index(const MapGround& ground, int index) noexcept {
    if (index < 0) return false;
    const auto slot = static_cast<std::size_t>(index);
    if (slot >= ground.grid.cells.size()) return false;
    return ground.grid.cells[slot].base.pixmap != 0;
}

[[nodiscard]] inline int find_open(const MapGround& ground) noexcept {
    const int columns = std::max(ground.file.x_size, 1);
    const int count = columns * std::max(ground.file.z_size, 0);
    int index = 0;
    while (index < count && !cell_open_index(ground, index)) {
        ++index;
    }
    if (index >= count) return 0;
    return index;
}

inline void apply_stand(WalkPose& pose, const map::TerrainFile& file, int scene_id, map::GateStand stand) noexcept {
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

inline void place_walk(WalkPose& pose, const MapGround& ground, int scene_id, map::GateStand stand) noexcept {
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
[[nodiscard]] inline math::Point3 point_of(ogre::Vec3 value) noexcept {
    return {value.x, value.y, value.z};
}

// Tỉ lệ rộng trên cao của vùng vẽ; chiều cao 0 thì coi như khung vuông.
[[nodiscard]] inline float aspect_of(render::ViewSize size) noexcept {
    if (size.height == 0) return 1.0F;
    return static_cast<float>(size.width) / static_cast<float>(size.height);
}

// Thông số nhìn của tư thế camera: mắt, hướng nhìn đơn vị và góc dọc, để đổi điểm màn hình thành
// tia và để cần gạt biết hướng nhìn.
[[nodiscard]] inline control::Lens lens_of(const control::CameraPose& pose, float aspect) noexcept {
    const ogre::Vec3 toward = ogre::sub_vec3(pose.target, pose.eye);
    control::Lens lens;
    lens.eye = pose.eye;
    lens.forward = ogre::normalize_vec3(toward);
    lens.fov_y = pose.fov_degrees * (std::numbers::pi_v<float> / 180.0F);
    lens.aspect = aspect;
    return lens;
}

// Như CCamera_Scene::Update đặt Ogre::Camera: setPosition, lookAt, rồi mặt cắt và góc nhìn.
[[nodiscard]] inline render::Camera camera_of(const control::CameraPose& pose, render::ViewSize size) {
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

[[nodiscard]] inline constexpr Request web_request(WebLink link) noexcept {
    return {.kind = RequestKind::kOpenWeb, .link = link};
}

inline constexpr std::array<ActionRequest, 8> kActionRequests = {{
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
[[nodiscard]] inline render::Camera login_camera(render::ViewSize size) noexcept {
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
[[nodiscard]] inline render::Camera role_pose_camera(ogre::Vec3 eye, ogre::Quat turn, render::ViewSize size) noexcept {
    render::Lens optics;
    optics.fov_degrees = control::kRoleFov;
    optics.near_plane = control::kRoleNear;
    optics.far_plane = control::kRoleFar;
    const math::Quat orientation(turn.x, turn.y, turn.z, turn.w);
    return render::posed_camera(point_of(eye), orientation, optics, size);
}

// Luật camera của một cảnh thường: số của System.cfg, cộng hai mặt cắt của bảng cảnh.
[[nodiscard]] inline control::CameraRules rules_of(const world::ShownScene* scene) noexcept {
    control::CameraRules rules;
    if (scene == nullptr) return rules;
    rules.near_plane = static_cast<float>(scene->near_clip);
    rules.far_plane = static_cast<float>(scene->far_clip);
    return rules;
}

[[nodiscard]] inline resource::Image image_at(const std::filesystem::path& path) {
    resource::Image image;
    const io::TextResult text = io::read_text(path);
    if (!text) return image;
    const std::span<const char> chars(text->data(), text->size());
    const auto encoded = std::as_bytes(chars);
    auto decoded = resource::decode_image(encoded);
    if (!decoded) return image;
    return std::move(*decoded);
}

using Paths = std::vector<std::filesystem::path>;

// Giải mã một ảnh của danh sách vào đúng ô của nó; mỗi luồng một ô nên không cần khoá.
struct DecodeOne {
    std::vector<resource::Image>* images = nullptr;
    const Paths* paths = nullptr;
    std::size_t index = 0;
    void operator()() const { (*images)[index] = image_at((*paths)[index]); }
};

// Giải mã mọi ảnh cùng lúc, mỗi ảnh một luồng; đường dẫn rỗng là ảnh không cần, ô của nó để trống. Giải mã PNG
// lần lượt là phần chờ dài nhất của việc nạp mặt đất, nhất là lúc các luồng đọc mesh đang chiếm các lõi (đo
// 2026-10-08, erengu_DL: 11 ảnh cọ và ảnh sáng 2048 x 2048).
[[nodiscard]] inline std::vector<resource::Image> decoded_all(const Paths& paths) {
    std::vector<resource::Image> images(paths.size());
    std::vector<std::jthread> pool;
    pool.reserve(paths.size());
    for (std::size_t index = 0; index < paths.size(); ++index) {
        if (paths[index].empty()) continue;
        pool.emplace_back(DecodeOne{.images = &images, .paths = &paths, .index = index});
    }
    // Chờ mọi luồng xong trước khi trả: chúng ghi thẳng vào images.
    pool.clear();
    return images;
}

[[nodiscard]] inline game::client::map::BrushImage view_of(const resource::Image& image) noexcept {
    game::client::map::BrushImage view;
    view.width = image.width;
    view.height = image.height;
    view.rgba = image.rgba;
    return view;
}

// Cạnh dài tối đa của atlas cọ: PC 4096, điện thoại 2048 vì GLES 3 chỉ bảo đảm texture 2048. Bản đồ thật cần ~1024
// (11 ảnh cọ 128 tới 512 cạnh, mỗi ảnh đệm 16 điểm ảnh).
#if defined(__ANDROID__) || defined(__APPLE__)
inline constexpr std::uint32_t kAtlasEdge = 2048;
#else
inline constexpr std::uint32_t kAtlasEdge = 4096;
#endif

// Mức mip lớn nhất mà sampler atlas được dùng: atlas đệm 16 điểm ảnh và đặt ở bội của 16, nên tới mức 4 mip không
// trộn ảnh cọ kề nhau (map/splat.hpp).
inline constexpr float kAtlasMaxLod = 4.0F;

// Ảnh của mặt đất lớp cọ: atlas, bảng ô, bảng tra do cọ dựng ra, và lightmap đọc nguyên. Không có cọ nào dùng được
// thì splat rỗng và địa hình tô màu theo độ cao.
struct GroundPaint {
    game::client::map::SplatImages splat;
    resource::Image light;
};

// Đọc đĩa và dựng. Chỉ giải mã những cọ có ô dùng tới (brushes_in_use): bản đồ thật dùng 3 tới 11 trong số cọ
// của file.
[[nodiscard]] inline GroundPaint ground_paint(const MapGround& ground, const std::filesystem::path& root) {
    const std::size_t brush_count = ground.file.textures.size();
    const std::vector<std::uint8_t> used = game::client::map::brushes_in_use(ground.file, ground.grid);
    const bool has_light = !ground.file.lightmap.empty();
    Paths paths(brush_count + 1);
    for (std::size_t index = 0; index < brush_count; ++index) {
        if (used[index] != 0) paths[index] = root / "Brushes" / io::path_from_utf8(ground.file.textures[index]);
    }
    if (has_light) paths[brush_count] = root / "Scene" / io::path_from_utf8(ground.file.lightmap);
    std::vector<resource::Image> stored = decoded_all(paths);
    std::vector<game::client::map::BrushImage> views(brush_count);
    std::ranges::transform(std::span(stored).first(brush_count), views.begin(), view_of);
    GroundPaint paint;
    paint.splat = game::client::map::build_splat(ground.file, ground.grid, views, kAtlasEdge);
    if (has_light) paint.light = std::move(stored.back());
    return paint;
}

struct LayJob {
    resource::Primitive* primitive = nullptr;
    const MapGround* ground = nullptr;
    float span_x = 0.0F;
    float span_z = 0.0F;
};

inline void lay_vertex(LayJob job, std::size_t index) {
    resource::Vertex& vertex = job.primitive->vertices[index];
    const game::client::map::Corner& corner = job.ground->sheet.corners[index];
    const game::client::map::TerrainFile& file = job.ground->file;
    if (job.span_x != 0.0F) vertex.uv.x = (corner.x - file.origin.x) / job.span_x;
    if (job.span_z != 0.0F) vertex.uv.y = (corner.z - file.origin.z) / job.span_z;
    vertex.color = {.x = 1.0F, .y = 1.0F, .z = 1.0F, .w = 1.0F};
}

inline void lay_paint(resource::Primitive& primitive, const MapGround& ground) {
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

// Ảnh của một Picture vào model; trả chỉ số ảnh.
[[nodiscard]] inline std::uint32_t add_picture(resource::Model& model, std::string name,
    game::client::map::Picture& picture) {
    resource::Image image;
    image.name = std::move(name);
    image.width = picture.width;
    image.height = picture.height;
    image.rgba = std::move(picture.rgba);
    model.images.push_back(std::move(image));
    return static_cast<std::uint32_t>(model.images.size() - 1U);
}

[[nodiscard]] inline resource::Sampler clamped_sampler(std::string name, float max_lod) {
    resource::Sampler sampler;
    sampler.name = std::move(name);
    sampler.wrap_u = resource::Wrap::kClamp;
    sampler.wrap_v = resource::Wrap::kClamp;
    sampler.max_lod = max_lod;
    return sampler;
}

// Mặt đất lớp cọ (terrain.ps): ghép các lớp cọ và nhân lightmap ở từng điểm ảnh; đèn và sương tính lúc vẽ như
// FairyTerrain.hlsl của bản gốc. Ảnh cọ giữ nguyên giá trị (không sRGB): bản gốc tính thẳng trên số của texture.
inline void attach_paint(resource::Model& model, GroundPaint& paint) {
    if (paint.splat.empty() || model.materials.empty()) return;
    resource::Splat splat;
    model.samplers.push_back(clamped_sampler("dia-hinh-coc", kAtlasMaxLod));
    splat.atlas.sampler = static_cast<std::uint32_t>(model.samplers.size() - 1U);
    splat.atlas.image = add_picture(model, "dia-hinh-coc", paint.splat.atlas);
    splat.cells.image = add_picture(model, "dia-hinh-o", paint.splat.cells);
    splat.table.image = add_picture(model, "dia-hinh-bang", paint.splat.table);
    if (!paint.light.rgba.empty()) {
        paint.light.name = "dia-hinh-sang";
        model.images.push_back(std::move(paint.light));
        model.samplers.push_back(clamped_sampler("dia-hinh-sang", 1000.0F));
        splat.light.image = static_cast<std::uint32_t>(model.images.size() - 1U);
        splat.light.sampler = static_cast<std::uint32_t>(model.samplers.size() - 1U);
    }
    resource::Material& material = model.materials.front();
    material.splat = splat;
    material.pass = classic::pass_of(classic::Classic{.lit = classic::Lit::kTerrain});
}

inline void push_height_vertex(resource::Primitive& primitive, const game::client::map::Corner& corner,
    bool has_paint) {
    resource::Vertex vertex;
    vertex.position = {.x = corner.x, .y = corner.y, .z = corner.z};
    vertex.normal = {.x = corner.normal_x, .y = corner.normal_y, .z = corner.normal_z};
    if (!has_paint) vertex.color = {.x = corner.red, .y = corner.green, .z = corner.blue, .w = 1.0F};
    primitive.vertices.push_back(vertex);
}

// Lưới địa hình thành một model một nút. Không có cọ thì màu đỉnh theo độ cao.
[[nodiscard]] inline resource::Model model_of(const MapGround& ground, GroundPaint paint) {
    resource::Model model;
    resource::Mesh mesh;
    mesh.name = "dia-hinh";
    resource::Primitive primitive;
    primitive.topology = resource::Topology::kTriangles;
    primitive.material = 0;
    primitive.vertices.reserve(ground.sheet.corners.size());
    const bool has_paint = !paint.splat.empty();
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
[[nodiscard]] inline bool has_points(const math::Aabb& box) noexcept {
    const math::Vector3 size = box.max - box.min;
    return size.x() >= 0.0F && size.y() >= 0.0F && size.z() >= 0.0F;
}

[[nodiscard]] inline bool is_opaque(const resource::Material& material) noexcept {
    return material.alpha != resource::Alpha::kBlend;
}

// Model đặc (không trộn alpha) mà vẽ ở tư thế nghỉ như lưới không skin (không skin, hoặc skin trung tính
// ở tư thế nghỉ: Drawable::is_rest_neutral): mọi bản sao vẽ bằng một lệnh. Cảnh tĩnh không đặt tư thế cho
// vật thể, nên skin của chúng chỉ là bộ xương dự phòng.
[[nodiscard]] inline bool can_batch(const resource::Model& model, const render::Drawable& drawable) noexcept {
    if (!model.skins.empty() && !drawable.is_rest_neutral()) return false;
    return std::ranges::all_of(model.materials, is_opaque);
}

[[nodiscard]] inline const KeptGround* find_ground(const std::deque<KeptGround>& grounds, int scene_id) {
    using Kept = const KeptGround&;
    const auto same = [scene_id](Kept item) noexcept { return item.scene_id == scene_id; };
    const auto found = std::ranges::find_if(grounds, same);
    if (found == grounds.end()) return nullptr;
    return &*found;
}

[[nodiscard]] inline bool mesh_waiting(const Arrival& arrival, core::Clock::time_point deadline) noexcept {
    if (core::Clock::now() >= deadline) return false;
    return arrival.cursor < arrival.table.meshes.size();
}

// Luồng đọc chưa xong mesh đang chờ: ghi mốc để đo quãng bị đói dữ liệu (không phải công việc).
[[nodiscard]] inline bool note_waiting(Arrival& loading) noexcept {
    if (!loading.is_stalled) loading.stall_started = core::Clock::now();
    loading.is_stalled = true;
    return false;
}

inline void note_user(Arrival& loading, std::size_t prop_index) {
    const std::size_t mesh = loading.table.props.at(prop_index).mesh;
    loading.users.at(mesh).push_back(prop_index);
}

inline void index_users(Arrival& loading) {
    loading.users.resize(loading.table.meshes.size());
    const std::size_t count = loading.table.props.size();
    for (std::size_t index = 0; index < count; ++index) {
        note_user(loading, index);
    }
}

inline void grow_slots(std::vector<std::size_t>& slots, std::size_t count) {
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

[[nodiscard]] inline ReadMesh baked_mesh(resource::Model model) {
    classic::note(model);
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
    resource::TextureTier tier = resource::TextureTier::kBc;
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

inline void bake_job(const FeedJob& job, Feed& feed) {
    if (!job.bake_ground || !job.scene || !job.scene->ground) return;
    const TimePoint began = core::Clock::now();
    GroundPaint paint = ground_paint(*job.scene->ground, job.root);
    const double painted_ms = millis_between(began, core::Clock::now());
    ReadMesh model = baked_mesh(model_of(*job.scene->ground, std::move(paint)));
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
    std::println("Địa hình resid {} đã dựng trong {} ms (ảnh cọ {} ms)", scene_id, millis, painted);
}

[[nodiscard]] inline std::size_t slot_span(const std::vector<Need>& needs) {
    std::size_t count = 0;
    for (const Need& need : needs) {
        count = std::max(count, need.slot + 1);
    }
    return count;
}

[[nodiscard]] inline bool epoch_matches(Feed& feed, std::uint64_t epoch) {
    const std::scoped_lock<std::mutex> lock(feed.mu);
    return feed.epoch == epoch;
}

inline void store_read(Feed& feed, const FeedJob& job, const Need& need) {
    auto loaded = resource::load_named_model(need.name, io::utf8_of(job.root), job.tier);
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

[[nodiscard]] inline bool next_need(ReadCursor& cursor, std::size_t& index) {
    if (cursor.stop.stop_requested()) return false;
    if (!epoch_matches(*cursor.feed, cursor.job->epoch)) return false;
    index = cursor.next.fetch_add(1, std::memory_order_relaxed);
    return index < cursor.job->needs.size();
}

inline void read_need(ReadCursor& cursor) {
    std::size_t index = 0;
    while (next_need(cursor, index)) {
        store_read(*cursor.feed, *cursor.job, cursor.job->needs.at(index));
    }
}

// Để lại một lõi cho luồng vẽ. Nhiều hơn Dev (mẻ 16, xong cả mẻ mới giao): file xong là giao ngay.
[[nodiscard]] inline std::size_t reader_count(std::size_t files) noexcept {
    const unsigned cores = std::max(2U, std::thread::hardware_concurrency());
    const std::size_t readers = static_cast<std::size_t>(cores) - 1;
    return std::max(std::size_t{1}, std::min(readers, files));
}

struct ReadStart {
    ReadCursor* cursor = nullptr;
    void operator()(const std::stop_token&) const { read_need(*cursor); }
};

inline void start_readers(ReadCursor& cursor, std::size_t files) {
    const std::size_t readers = reader_count(files);
    std::vector<std::jthread> pool;
    pool.reserve(readers);
    ReadStart start;
    start.cursor = &cursor;
    for (std::size_t index = 0; index < readers; ++index) {
        pool.emplace_back(start);
    }
}

inline void read_job(const FeedJob& job, Feed& feed, std::stop_token stop) {
    if (job.needs.empty()) return;
    ReadCursor cursor;
    cursor.job = &job;
    cursor.feed = &feed;
    cursor.stop = std::move(stop);
    start_readers(cursor, job.needs.size());
}

inline void serve(const FeedJob& job, Feed& feed, std::stop_token stop) {
    const std::jthread baker([&job, &feed](const std::stop_token&) { bake_job(job, feed); });
    read_job(job, feed, std::move(stop));
}

inline Feed::Feed() {
    thread = std::jthread([this](const std::stop_token& stop) { run(stop); });
}

inline Feed::~Feed() {
    {
        const std::scoped_lock<std::mutex> lock(mu);
        quit = true;
    }
    cv.notify_all();
}

inline std::uint64_t Feed::post(FeedJob next) {
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

inline void Feed::cancel() {
    const std::scoped_lock<std::mutex> lock(mu);
    ++epoch;
    job.reset();
    ground.reset();
    ground_ready = false;
    slots.clear();
    cv.notify_all();
}

inline std::optional<ReadMesh> Feed::take_ground(std::uint64_t current) {
    const std::scoped_lock<std::mutex> lock(mu);
    if (!ground_ready || epoch != current || !ground) return std::nullopt;
    ground_ready = false;
    return std::exchange(ground, std::nullopt);
}

inline MeshReady Feed::take_mesh(std::uint64_t current, std::size_t slot) {
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

inline std::optional<FeedJob> Feed::wait_job(const std::stop_token& stop) {
    std::unique_lock<std::mutex> lock(mu);
    cv.wait(lock, [this, &stop] { return quit || job.has_value() || stop.stop_requested(); });
    if (quit || stop.stop_requested()) return std::nullopt;
    std::optional<FeedJob> taken = std::move(job);
    job.reset();
    return taken;
}

inline bool Feed::serve_next(const std::stop_token& stop) {
    std::optional<FeedJob> taken = wait_job(stop);
    if (!taken) return false;
    serve(*taken, *this, stop);
    return true;
}

inline void Feed::run(const std::stop_token& stop) {
    while (!stop.stop_requested() && serve_next(stop)) {
    }
}

// Định dạng điểm ảnh của capture theo định dạng màu mà bề mặt đã chốt.
[[nodiscard]] inline core::Result<capture::PixelFormat> shot_format(gpu::Format colour) noexcept {
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
inline void shot_barrier(gpu::CommandList& list, const gpu::TextureHandle& texture, bool to_copy) {
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
inline void discard_shot(gpu::Device& device, const std::optional<ShotPlan>& shot) noexcept {
    if (shot) device.destroy(shot->staging);
}

// ofstream nhận char; std::byte và char được phép trỏ cùng vùng nhớ.
// NOLINTBEGIN(cppcoreguidelines-pro-type-reinterpret-cast)
// Ghi nội dung nhị phân ra tệp; false khi mở tệp hoặc ghi hỏng.
[[nodiscard]] inline bool write_bytes(const std::filesystem::path& path, ByteSpan bytes) {
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
[[nodiscard]] inline bool seat_model(SeatTarget target, ReadMesh mesh) {
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

[[nodiscard]] inline bool upload_ground(GroundUpload upload) {
    GroundPaint paint;
    if (upload.data_root != nullptr) paint = ground_paint(*upload.ground, *upload.data_root);
    ReadMesh mesh = baked_mesh(model_of(*upload.ground, std::move(paint)));
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

[[nodiscard]] inline bool has_hardware(gpu::Backend backend) {
    const gpu::Result<std::vector<gpu::AdapterInfo>> list = gpu::enumerate_adapters(backend);
    if (!list) return false;
    for (const gpu::AdapterInfo& info : *list) {
        if (!info.is_software) return true;
    }
    return false;
}

[[nodiscard]] inline CacheId identity_of(gpu::Backend backend, std::uint32_t index, std::uint64_t shaders) {
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
[[nodiscard]] inline CacheId predict_cache(const gpu::DeviceDesc& desc, std::uint64_t shaders) {
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

[[nodiscard]] inline std::uint64_t hash_packages(const std::string& folder) {
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

[[nodiscard]] inline std::filesystem::path cache_file(const std::filesystem::path& root, const CacheId& id) {
    const std::string name =
        std::format("pipeline-{}-{:08x}-{:08x}-{:016x}.bin", gpu::name(id.backend), id.vendor, id.device, id.shaders);
    return root / "cache" / name;
}

[[nodiscard]] inline std::filesystem::path writable_root(const DisplayDesc& desc) {
    if (!desc.save_root.empty()) return desc.save_root;
    return desc.data_root;
}

[[nodiscard]] inline std::vector<std::byte> read_cache(const std::filesystem::path& path) {
    const io::TextResult text = io::read_text(path);
    if (!text) return {};
    std::vector<std::byte> bytes(text->size());
    std::ranges::copy(std::as_bytes(std::span(*text)), bytes.begin());
    return bytes;
}

[[nodiscard]] inline core::Status apply_backend(gpu::DeviceDesc& device_desc, const DisplayDesc& desc) {
    if (!desc.backend) return core::ok();
    const std::optional<gpu::Backend> parsed = gpu::parse_backend(*desc.backend);
    if (!parsed) return core::fail(core::ErrorCode::kInvalidArgument, "backend không có");
    device_desc.backend = *parsed;
    return core::ok();
}

} // namespace game::client
