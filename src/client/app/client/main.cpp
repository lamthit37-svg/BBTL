// thienlong_client: điểm vào của client. Nạp tệp cảnh của một map từ thư mục dữ liệu, in tóm tắt
// (số vật thể theo kiểu, hộp bao vị trí, vài phép đặt đầu) để đối chiếu với tệp gốc, rồi mở cửa sổ
// và vẽ mọi vật thể tĩnh của cảnh (GLB nạp từ thư mục dữ liệu, đúng phép đặt gốc); --shot ghi ảnh
// chụp khung đầu tiên ra PNG. Dữ liệu tìm ở <thư mục chứa exe>/../assets (dev/client/bin và
// dev/client/assets, hoặc release/client), đổi bằng --data. Không nêu --scene thì mở cảnh duy nhất của thư mục
// dữ liệu. Mã thoát: 0 xong, 1 lỗi dữ liệu hoặc không mở được cửa sổ, 2 sai cách dùng hoặc không
// biết mở cảnh nào.
#include "client/boot.hpp"
#include "client/display/display.hpp"
#include "client/map/book.hpp"
#include "client/map/ground.hpp"
#include "client/map/terrain.hpp"
#include "client/options.hpp"
#include "client/stage/stage.hpp"
#include "client/viewer/viewer.hpp"
#include "client/world/world.hpp"
#include "control/char_camera.hpp"
#include "control/login_view.hpp"
#include "core/timeline.hpp"
#include "io/file.hpp"
#include "io/platform.hpp"
#include "scene/placement.hpp"
#include "scene/scene_file.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdio>
#include <exception>
#include <expected>
#include <filesystem>
#include <format>
#include <map>
#include <memory>
#include <optional>
#include <print>
#include <ranges>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace {

namespace client = game::client;
namespace core = game::core;
namespace io = game::io;
namespace scene = game::scene;
namespace world = game::client::world;

using Path = std::filesystem::path;

// Bản dựng debug bật lớp kiểm tra của Vulkan mặc định (lỗi phải hiện lúc phát triển); bản phát
// hành tắt: lớp kiểm tra tốn CPU mỗi khung hình và gây giật.
#ifdef GAME_DEBUG_CHECKS
constexpr bool kValidatedByBuild = true;
#else
constexpr bool kValidatedByBuild = false;
#endif

constexpr std::string_view kStaticEntity = "StaticEntity";
constexpr int kShownPlacements = 3;

struct Bounds {
    scene::Vector3 low;
    scene::Vector3 high;
    std::size_t count = 0;
};

struct Summary {
    std::map<std::string_view, std::size_t> kinds;
    Bounds bounds;
};

[[nodiscard]] std::filesystem::path data_folder_of(const client::Options& options) {
    if (!options.data_folder.empty()) return options.data_folder;
    return io::executable_directory().parent_path() / "assets";
}

void extend(Bounds& bounds, const scene::Vector3& point) noexcept {
    if (bounds.count == 0) bounds.low = point;
    if (bounds.count == 0) bounds.high = point;
    bounds.low.x = std::min(bounds.low.x, point.x);
    bounds.low.y = std::min(bounds.low.y, point.y);
    bounds.low.z = std::min(bounds.low.z, point.z);
    bounds.high.x = std::max(bounds.high.x, point.x);
    bounds.high.y = std::max(bounds.high.y, point.y);
    bounds.high.z = std::max(bounds.high.z, point.z);
    ++bounds.count;
}

[[nodiscard]] bool is_static(const scene::Object& object) noexcept {
    return object.type == kStaticEntity;
}

void count_object(Summary& summary, const scene::Object& object) {
    ++summary.kinds[object.type];
    if (is_static(object)) extend(summary.bounds, scene::placement_of(object).position);
}

void print_placement(const scene::Object& object) {
    const scene::Placement placement = scene::placement_of(object);
    const std::string_view mesh = scene::property(object, "mesh name").value_or("?");
    const scene::Vector3& position = placement.position;
    const scene::Quaternion& turn = placement.orientation;
    const scene::Vector3& scale = placement.scale;
    std::println("  {}", mesh);
    std::println("    vị trí {} {} {}", position.x, position.y, position.z);
    std::println("    hướng (x y z w) {} {} {} {}", turn.x, turn.y, turn.z, turn.w);
    std::println("    tỉ lệ {} {} {}", scale.x, scale.y, scale.z);
}

void print_summary(const scene::SceneFile& file) {
    Summary summary;
    for (const scene::Object& object : file.objects) {
        count_object(summary, object);
    }
    const std::size_t total = file.objects.size();
    std::println("Cảnh \"{}\": địa hình {}, {} vật thể", file.name, file.terrain_file, total);
    for (const auto& [kind, count] : summary.kinds) {
        std::println("  {} {}", kind, count);
    }
    const Bounds& bounds = summary.bounds;
    if (bounds.count == 0) return;
    std::println("Hộp bao vị trí của {} vật thể tĩnh:", bounds.count);
    std::println("  thấp {} {} {}", bounds.low.x, bounds.low.y, bounds.low.z);
    std::println("  cao {} {} {}", bounds.high.x, bounds.high.y, bounds.high.z);
}

void print_first_placements(const scene::SceneFile& file) {
    std::println("Phép đặt của {} vật thể tĩnh đầu tiên:", kShownPlacements);
    const auto first_statics = std::views::filter(is_static) | std::views::take(kShownPlacements);
    std::ranges::for_each(file.objects | first_statics, print_placement);
}

using SceneNames = std::vector<std::string>;

void add_scene_name(SceneNames& names, const std::filesystem::directory_entry& entry) {
    if (entry.path().extension() != ".Scene") return;
    names.push_back(io::utf8_of(entry.path().stem()));
}

// Tên các cảnh của thư mục dữ liệu: mỗi tệp <tên>.Scene trong folder, đã sắp. Thư mục không đọc
// được thì danh sách rỗng.
[[nodiscard]] SceneNames scene_names(const std::filesystem::path& folder) {
    SceneNames names;
    std::error_code ignored;
    for (const auto& entry : std::filesystem::directory_iterator(folder, ignored)) {
        add_scene_name(names, entry);
    }
    std::ranges::sort(names);
    return names;
}

// Không biết mở cảnh nào: in hướng dẫn kèm các cảnh đang có để người dùng chọn.
[[nodiscard]] int report_no_scene(const SceneNames& available) {
    std::println(stderr, "{}", client::kUsage);
    std::println(stderr, "Thư mục dữ liệu có {} cảnh:", available.size());
    for (const std::string& name : available) {
        std::println(stderr, "  {}", name);
    }
    return 2;
}

[[nodiscard]] std::optional<client::map::Ground> ground_of(const Path& folder, const scene::SceneFile& file) {
    std::optional<game::client::map::Ground> ground;
    if (file.terrain_file.empty()) return ground;
    game::client::map::GroundResult loaded = game::client::map::load_ground(folder, file.terrain_file);
    if (!loaded) {
        std::println(stderr, "Địa hình: {}", game::client::map::describe(loaded.error()));
        return ground;
    }
    ground = std::move(*loaded);
    std::println("Địa hình {}: {}x{} ô, {} tam giác, bản đồ {}x{}", ground->file.name, ground->file.x_size,
        ground->file.z_size, ground->triangle_count(), ground->overview.width, ground->overview.height);
    return ground;
}

[[nodiscard]] std::optional<int> resid_of(const world::World& playing, const client::Options& options) {
    if (options.scene_id) return options.scene_id;
    if (options.scene_name.empty()) return world::file_resid(data_folder_of(options));
    const game::client::map::SceneRef* row = game::client::map::find_scene(playing.book, options.scene_name);
    if (row == nullptr) return std::nullopt;
    return row->id;
}

void print_visit(const world::ShownScene& shown) {
    print_summary(shown.scene);
    print_first_placements(shown.scene);
    std::println("{}", world::describe_walk(shown));
    if (shown.terrain_error) {
        const std::string_view reason = game::client::map::describe(*shown.terrain_error);
        std::println(stderr, "Địa hình: {}", reason);
        return;
    }
    if (!shown.ground) return;
    std::println("Địa hình {}: {}x{} ô, {} tam giác, bản đồ {}x{}", shown.ground->file.name, shown.ground->file.x_size,
        shown.ground->file.z_size, shown.ground->triangle_count(), shown.ground->overview.width,
        shown.ground->overview.height);
}

// Phần của ViewerDesc lấy từ tuỳ chọn dòng lệnh, chung cho mọi cách mở cửa sổ; tiêu đề là tên
// game, nơi gọi nối thêm tên cảnh.
[[nodiscard]] client::ViewerDesc viewer_of(const client::Options& options,
    std::shared_ptr<client::DisplayPreload> preload) {
    client::ViewerDesc viewer;
    viewer.preload = std::move(preload);
    viewer.title = std::string(client::kGameTitle);
    viewer.frames = options.frames;
    viewer.data_folder = data_folder_of(options);
    viewer.shot = options.shot_path;
    viewer.is_bare = options.is_bare;
    viewer.is_auto_walk = options.is_auto_walk;
    viewer.auto_strike_from = options.auto_strike_from;
    viewer.ui_events = options.ui_events;
    viewer.weapon_item = options.weapon_item;
    viewer.weapon_gem = options.weapon_gem;
    viewer.skill_id = options.skill_id;
    viewer.is_validated = options.validate.value_or(kValidatedByBuild);
    viewer.backend = options.backend;
    viewer.client_size = options.client_size;
    return viewer;
}

// Một cảnh mở thẳng từ tệp, không qua bảng cảnh: tệp cảnh, nội dung vẽ và địa hình của nó.
struct OpenedScene {
    scene::SceneFile file;
    client::Stage stage;
    std::optional<client::map::Ground> ground;
};

using OpenResult = std::expected<OpenedScene, std::string>;

// Đọc <folder>/<name>.Scene và địa hình nó nêu; lỗi là một câu đã kèm đường dẫn tệp.
[[nodiscard]] OpenResult open_scene(const Path& folder, std::string_view name) {
    const Path path = folder / io::path_from_utf8(std::string(name) + ".Scene");
    const auto text = io::read_text(path);
    if (!text) return std::unexpected(std::format("{}: {}", io::describe(text.error()), io::utf8_of(path)));
    auto file = scene::read_scene(*text);
    if (!file) return std::unexpected(std::format("tệp cảnh hỏng: {}", io::utf8_of(path)));
    OpenedScene opened;
    opened.stage = client::stage_of(*file);
    client::world::attach_sky_file(opened.stage, folder, file->sky_file);
    client::world::attach_models(opened.stage, folder.parent_path());
    opened.ground = ground_of(folder, *file);
    opened.file = std::move(*file);
    return opened;
}

// Bảng cảnh cho lúc rời màn đăng nhập. Không đọc được thì nút vào game báo một dòng và ở lại bảng.
[[nodiscard]] std::optional<world::World> book_world(const Path& data_root) {
    const io::TextResult table = io::read_text(data_root / "Config" / "SceneDefineEx.txt");
    if (!table) return std::nullopt;
    auto opened = world::open_world(*table);
    if (!opened) return std::nullopt;
    return std::move(*opened);
}

void report_named(const client::NamedScene& named, std::string_view label) {
    if (!named.error.empty()) std::println(stderr, "{}{}", label, named.error);
    if (!named.terrain.empty()) std::println(stderr, "Địa hình: {}", named.terrain);
    if (!named.summary.empty()) std::println("{}", named.summary);
}

// Thủ tục đăng nhập: bảng nhập tài khoản trên cảnh nền của client 2026 (control::kLoginScene), nhìn
// bằng camera cố định của màn đăng nhập. Thiếu dữ liệu cảnh thì báo một dòng, bảng hiện trên nền
// trống. Nút vào game đưa sang màn chơi ở cảnh mà --scene, --scene-id hay Config/startup.id nêu.
[[nodiscard]] int run_login(const client::Options& options, std::shared_ptr<client::DisplayPreload> preload) {
    const Path data_root = data_folder_of(options);
    // Nạp dần ở luồng vẽ, cùng đường với Android và iOS (client/boot). Đưa thẳng stage thì khung
    // đầu đứng yên đến khi hết mesh (đo 2026-10-08: 2,2 giây).
    const client::NamedScene backdrop =
        client::load_named_scene(data_root, game::control::kLoginScene, client::kBackdropSceneId);
    report_named(backdrop, "Nền đăng nhập: ");
    const client::NamedScene roles =
        client::load_named_scene(data_root, game::control::kRoleScene, client::kRoleSceneId);
    report_named(roles, "Nền chọn nhân vật: ");
    std::optional<world::World> playing = book_world(data_root);
    client::ViewerDesc viewer = viewer_of(options, std::move(preload));
    viewer.procedure = client::Procedure::kLogin;
    viewer.backdrop = backdrop.shown;
    viewer.role_scene = roles.shown;
    if (playing) viewer.playing = &*playing;
    if (playing) viewer.first_scene = resid_of(*playing, options);
    std::println("Thủ tục đăng nhập: bảng nhập tài khoản");
    return client::run_viewer(viewer);
}

[[nodiscard]] int run_book(const client::Options& options, std::string_view table,
    std::shared_ptr<client::DisplayPreload> preload) {
    const std::filesystem::path data_root = data_folder_of(options);
    const std::filesystem::path folder = data_root / "Scene";
    std::expected<world::World, game::client::map::BookError> opened = world::open_world(table);
    if (!opened) {
        std::println(stderr, "Lỗi: {}", game::client::map::describe(opened.error()));
        return 1;
    }
    world::World playing = std::move(*opened);
    const bool named = !options.scene_name.empty();
    const std::optional<int> resid = resid_of(playing, options);
    if (!resid && named) {
        std::println(stderr, "Lỗi: bảng cảnh không có map {}", options.scene_name);
        return 1;
    }
    if (!resid) {
        const SceneNames available = scene_names(folder);
        return report_no_scene(available);
    }
    const world::EnterResult entered = world::enter(playing, *resid, folder);
    if (!entered) {
        std::println(stderr, "Lỗi: {}", world::describe(entered.error()));
        return 1;
    }
    const world::ShownScene& shown = *playing.current;
    print_visit(shown);
    std::println("Vào cảnh resid {} ({})", shown.id, shown.scene_file);
    core::mark("cảnh đã đọc (world::enter)");
    client::ViewerDesc viewer = viewer_of(options, std::move(preload));
    viewer.title += " — " + shown.name;
    viewer.stage = &shown.stage;
    viewer.ground = shown.ground ? &*shown.ground : nullptr;
    viewer.playing = &playing;
    return client::run_viewer(viewer);
}

// Bấm đúp không kèm --scene: vào đăng nhập. --scene hoặc --scene-id vẫn mở thẳng cảnh đó.
[[nodiscard]] bool asked_scene(const client::Options& options) noexcept {
    return options.scene_id.has_value() || !options.scene_name.empty();
}

[[nodiscard]] int run(const client::Options& options) {
    const std::filesystem::path data_root = data_folder_of(options);
    auto preload = std::make_shared<client::DisplayPreload>(data_root, options.backend);
    if (options.is_login || !asked_scene(options)) return run_login(options, std::move(preload));
    const io::TextResult table = io::read_text(data_root / "Config" / "SceneDefineEx.txt");
    if (table) return run_book(options, *table, std::move(preload));
    const std::filesystem::path folder = data_root / "Scene";
    const SceneNames available = scene_names(folder);
    const std::optional<std::string> chosen = client::choose_scene(options.scene_name, available);
    if (!chosen) return report_no_scene(available);
    OpenResult opened = open_scene(folder, *chosen);
    if (!opened) {
        std::println(stderr, "Lỗi: {}", opened.error());
        return 1;
    }
    print_summary(opened->file);
    print_first_placements(opened->file);
    // Không có bảng cảnh thì display nhận cảnh qua backdrop. Cùng ShownScene nên va chạm và
    // model vẫn được nạp như đường đi qua SceneDefineEx.
    auto shown = std::make_shared<world::ShownScene>();
    shown->name = *chosen;
    shown->scene_file = *chosen + ".Scene";
    shown->stage = std::move(opened->stage);
    shown->ground = std::move(opened->ground);
    shown->scene = std::move(opened->file);
    world::attach_buildings(shown->buildings, folder, shown->scene_file);
    client::ViewerDesc viewer = viewer_of(options, std::move(preload));
    viewer.title += " — " + *chosen;
    viewer.backdrop = std::move(shown);
    viewer.stage = &viewer.backdrop->stage;
    viewer.ground = viewer.backdrop->ground ? &*viewer.backdrop->ground : nullptr;
    return client::run_viewer(viewer);
}

[[nodiscard]] int start(std::span<const std::string> arguments) {
    io::use_utf8_console();
    core::mark("main bắt đầu");
    const std::vector<std::string_view> texts(arguments.begin(), arguments.end());
    const auto options = client::parse_options(texts);
    if (options) return run(*options);
    std::println(stderr, "{}", client::kUsage);
    return 2;
}

} // namespace

// Thư viện chuẩn (std::print, std::filesystem) có thể ném; main chặn lại để tiến trình thoát có mã.
int main(const int argc, const char* const* const argv) {
    try {
        const std::vector<std::string> arguments = io::command_arguments(argc, argv);
        return start(arguments);
    } catch (const std::exception& error) {
        static_cast<void>(std::fputs("Lỗi không lường trước: ", stderr));
        static_cast<void>(std::fputs(error.what(), stderr));
        static_cast<void>(std::fputc('\n', stderr));
        return 1;
    } catch (...) {
        static_cast<void>(std::fputs("Lỗi không lường trước\n", stderr));
        return 1;
    }
}
