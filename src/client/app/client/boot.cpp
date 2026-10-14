// Xem boot.hpp. Đọc cảnh và bảng bằng io::read_text (có trần cỡ) và scene::read_scene; không
// tự phân tích XML lần nữa.
#include "client/boot.hpp"

#include "client/display/display.hpp"
#include "client/map/book.hpp"
#include "client/map/ground.hpp"
#include "client/map/terrain.hpp"
#include "client/stage/stage.hpp"
#include "client/world/world.hpp"
#include "control/char_camera.hpp"
#include "control/login_view.hpp"
#include "io/file.hpp"
#include "scene/scene_file.hpp"

#include <expected>
#include <filesystem>
#include <format>
#include <memory>
#include <string>
#include <string_view>
#include <utility>

namespace game::client {
namespace {

[[nodiscard]] bool is_scene_name(std::string_view name) noexcept {
    if (name.empty() || name == "." || name == "..") return false;
    if (name.contains(':')) return false;
    return !name.contains('/') && !name.contains('\\');
}

void add_ground(NamedScene& named, world::ShownScene& shown, const std::filesystem::path& folder,
    const scene::SceneFile& file) {
    if (file.terrain_file.empty()) return;
    map::GroundResult ground = map::load_ground(folder, file.terrain_file);
    if (!ground) {
        named.terrain = std::string(map::describe(ground.error()));
        return;
    }
    named.summary =
        std::format("Địa hình {}: {}x{} ô, {} tam giác, bản đồ {}x{}", ground->file.name, ground->file.x_size,
            ground->file.z_size, ground->triangle_count(), ground->overview.width, ground->overview.height);
    shown.ground = std::move(*ground);
}

void fill_shown(world::ShownScene& shown, scene::SceneFile file, std::string_view name, int scene_id) {
    shown.id = scene_id;
    shown.name = std::string(name);
    shown.scene_file = std::string(name) + ".Scene";
    shown.stage = stage_of(file);
    shown.scene = std::move(file);
}

void take_named(BootLoad& boot, NamedScene named, std::string_view label, bool is_role) {
    if (!named.error.empty()) boot.lines.push_back({.is_problem = true, .text = std::string(label) + named.error});
    if (!named.terrain.empty()) boot.lines.push_back({.is_problem = true, .text = "Địa hình: " + named.terrain});
    if (!named.summary.empty()) boot.lines.push_back({.is_problem = false, .text = std::move(named.summary)});
    if (is_role) boot.role_scene = std::move(named.shown);
    if (!is_role) boot.backdrop = std::move(named.shown);
}

void open_book(BootLoad& boot) {
    const io::TextResult table = io::read_text(boot.data_root / "Config" / "SceneDefineEx.txt");
    if (!table) {
        boot.lines.push_back({.is_problem = true, .text = "Bảng cảnh: không đọc được Config/SceneDefineEx.txt"});
        return;
    }
    std::expected<world::World, map::BookError> opened = world::open_world(*table);
    if (!opened) {
        boot.lines.push_back({.is_problem = true,
            .text = std::string("Bảng cảnh: ") + std::string(map::describe(opened.error()))});
        return;
    }
    boot.playing = std::move(*opened);
    const io::TextResult startup = io::read_text(boot.data_root / "Config" / "startup.id");
    if (!startup) {
        boot.lines.push_back({.is_problem = true, .text = "không đọc được Config/startup.id"});
        return;
    }
    boot.first_scene = world::file_resid(boot.data_root);
    if (!boot.first_scene) boot.lines.push_back({.is_problem = true, .text = "Config/startup.id không phải resid"});
}

} // namespace

NamedScene load_named_scene(const std::filesystem::path& data_root, std::string_view name, int scene_id) {
    NamedScene named;
    if (!is_scene_name(name)) {
        named.error = "tên cảnh không hợp lệ";
        return named;
    }
    const std::filesystem::path path = data_root / "Scene" / io::path_from_utf8(std::string(name) + ".Scene");
    const io::TextResult text = io::read_text(path);
    if (!text) {
        named.error = std::format("{}: {}", io::describe(text.error()), io::utf8_of(path));
        return named;
    }
    scene::SceneResult file = scene::read_scene(*text);
    if (!file) {
        named.error = std::format("tệp cảnh hỏng: {}", io::utf8_of(path));
        return named;
    }
    auto shown = std::make_shared<world::ShownScene>();
    add_ground(named, *shown, path.parent_path(), *file);
    fill_shown(*shown, std::move(*file), name, scene_id);
    world::attach_sky_file(shown->stage, path.parent_path(), shown->scene.sky_file);
    world::attach_height_fog(shown->stage, path.parent_path(), shown->scene_file);
    world::attach_models(shown->stage, data_root);
    world::attach_buildings(shown->buildings, path.parent_path(), shown->scene_file);
    named.shown = std::move(shown);
    return named;
}

BootLoad load_login(const std::filesystem::path& data_root) {
    BootLoad boot;
    boot.data_root = data_root;
    NamedScene backdrop = load_named_scene(data_root, control::kLoginScene, kBackdropSceneId);
    take_named(boot, std::move(backdrop), "Nền đăng nhập: ", false);
    NamedScene roles = load_named_scene(data_root, control::kRoleScene, kRoleSceneId);
    take_named(boot, std::move(roles), "Nền chọn nhân vật: ", true);
    open_book(boot);
    return boot;
}

EnterNote enter_startup(world::World& playing, int resid, const std::filesystem::path& data_root) {
    EnterNote note;
    const world::EnterResult entered = world::enter(playing, resid, data_root / "Scene");
    if (!entered) note.detail = std::string(world::describe(entered.error()));
    note.ok = entered.has_value();
    return note;
}

HostStep host_step(BootLoad& boot, bool& is_playing, Request request) {
    HostStep step;
    if (request.kind == RequestKind::kLeave) {
        step.ask = HostAsk::kLeave;
        return step;
    }
    if (request.kind == RequestKind::kOpenWeb) {
        step.ask = HostAsk::kOpenWeb;
        step.link = request.link;
        return step;
    }
    if (request.kind != RequestKind::kEnterGame || is_playing) return step;
    if (!boot.playing || !boot.first_scene) {
        step.detail = "thư mục dữ liệu không có bảng cảnh hay cảnh đầu tiên";
        return step;
    }
    const EnterNote entered = enter_startup(*boot.playing, *boot.first_scene, boot.data_root);
    if (!entered.ok) {
        step.detail = entered.detail;
        return step;
    }
    is_playing = true;
    step.ask = HostAsk::kEntered;
    return step;
}

std::string_view web_link_name(WebLink link) noexcept {
    switch (link) {
    case WebLink::kTopUp: return "nạp thẻ";
    case WebLink::kRegister: return "đăng ký tài khoản";
    case WebLink::kLostPassword: return "quên mật khẩu";
    case WebLink::kSecurityCard: return "thẻ bảo mật";
    case WebLink::kHelp: return "trợ giúp";
    case WebLink::kForum: return "diễn đàn";
    }
    return "trang web";
}

} // namespace game::client
