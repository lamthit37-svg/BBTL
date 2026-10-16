#include "client/world/world.hpp"

#include "client/map/ground.hpp"
#include "core/error.hpp"
#include "core/number.hpp"
#include "io/file.hpp"

#include "client/map/book.hpp"
#include "client/stage/height_fog.hpp"
#include "client/stage/sky.hpp"
#include "client/stage/stage.hpp"
#include "fs/file.hpp"
#include "nav/mesh.hpp"
#include "nav/route.hpp"
#include "scene/scene_file.hpp"

#include <algorithm>
#include <expected>
#include <filesystem>
#include <iterator>
#include <memory>
#include <mutex>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace game::client::world {
namespace {

[[nodiscard]] EnterResult fail(EnterError error) {
    return std::unexpected(error);
}

// Lưới đi nằm cạnh tệp cảnh. Thiếu tệp không phải lỗi: bảng cảnh ghi tên .path cho cả những cảnh
// mà kho của client không có tệp đó.
void load_walk(ShownScene& shown, const std::filesystem::path& scene_folder, std::string_view path_file) {
    if (path_file.empty()) return;
    const io::TextResult bytes = io::read_text(scene_folder / io::path_from_utf8(path_file));
    if (!bytes) return;
    nav::MeshResult mesh = nav::read_mesh(std::as_bytes(std::span{*bytes}));
    if (!mesh) shown.walk_error = mesh.error();
    if (!mesh) return;
    const nav::Area area{.width = static_cast<float>(shown.x_size), .depth = static_cast<float>(shown.z_size)};
    shown.walk.emplace(std::move(*mesh), area);
}

[[nodiscard]] std::shared_ptr<ShownScene> load_row(const map::Book& book, const map::SceneRef& row,
    const std::filesystem::path& scene_folder, EnterError& error) {
    const std::string_view scene_file = map::file_of(book, row);
    const std::filesystem::path path = scene_folder / io::path_from_utf8(scene_file);
    const io::TextResult text = io::read_text(path);
    if (!text) {
        error = EnterError::kMissingFile;
        return nullptr;
    }
    scene::SceneResult scene = scene::read_scene(*text);
    if (!scene) {
        error = EnterError::kBadXml;
        return nullptr;
    }
    auto shown = std::make_shared<ShownScene>();
    shown->id = row.id;
    shown->name = std::string(map::name_of(book, row));
    shown->scene_file = std::string(scene_file);
    shown->radar = std::string(map::radar_of(book, row));
    shown->x_size = row.x_size;
    shown->z_size = row.z_size;
    shown->far_clip = row.far_clip;
    shown->near_clip = row.near_clip;
    shown->music = row.music;
    shown->scene = std::move(*scene);
    shown->stage = stage_of(shown->scene);
    attach_sky_file(shown->stage, scene_folder, shown->scene.sky_file);
    attach_height_fog(shown->stage, scene_folder, shown->scene_file);
    attach_models(shown->stage, scene_folder.parent_path());
    attach_buildings(shown->buildings, scene_folder, shown->scene_file);
    load_walk(*shown, scene_folder, map::path_of(book, row));
    if (shown->scene.terrain_file.empty()) return shown;
    map::GroundResult ground = map::load_ground(scene_folder, shown->scene.terrain_file);
    if (!ground) {
        shown->terrain_error = ground.error();
        return shown;
    }
    shown->ground = std::move(*ground);
    return shown;
}

[[nodiscard]] std::shared_ptr<const ShownScene> cached_scene(const World& world, int id) {
    const auto same = [id](const std::shared_ptr<const ShownScene>& item) noexcept {
        return static_cast<bool>(item) && item->id == id;
    };
    const auto found = std::ranges::find_if(world.remembered, same);
    if (found == world.remembered.end()) return nullptr;
    return *found;
}

// Giữ khoá của world. Cảnh cùng id được đưa xuống cuối; quá kRemembered thì bỏ cảnh cũ nhất.
void remember(World& world, const std::shared_ptr<ShownScene>& shown) {
    std::vector<std::shared_ptr<const ShownScene>> kept;
    kept.reserve(kRemembered);
    const int id = shown->id;
    const auto other = [id](const std::shared_ptr<const ShownScene>& item) noexcept { return !item || item->id != id; };
    std::ranges::copy_if(world.remembered, std::back_inserter(kept), other);
    kept.push_back(shown);
    if (kept.size() > kRemembered) kept.erase(kept.begin());
    world.remembered = std::move(kept);
    world.current = shown;
}

// Đang đứng cảnh này, hoặc còn trong remembered. nullopt khi phải đọc đĩa.
[[nodiscard]] std::optional<EnterCode> cached_enter(World& world, int id) {
    const std::scoped_lock locked(*world.guard);
    if (world.current && world.current->id == id) return EnterCode::kSame;
    const std::shared_ptr<const ShownScene> found = cached_scene(world, id);
    if (!found) return std::nullopt;
    world.current = found;
    return EnterCode::kLoaded;
}

[[nodiscard]] bool is_tail_space(char letter) noexcept {
    return letter == '\n' || letter == '\r' || letter == ' ';
}

[[nodiscard]] bool drop_tail(std::string_view& body) noexcept {
    if (body.empty()) return false;
    if (!is_tail_space(body.back())) return false;
    body.remove_suffix(1);
    return true;
}

} // namespace

namespace {

[[nodiscard]] std::string hfog_name(std::string_view scene_file) {
    const std::size_t dot = scene_file.rfind('.');
    const std::size_t stem = dot == std::string_view::npos ? scene_file.size() : dot;
    std::string name(scene_file.substr(0, stem));
    name.append(".hfog");
    return name;
}

} // namespace

void attach_height_fog(Stage& stage, const std::filesystem::path& scene_folder, std::string_view scene_file) {
    if (scene_file.empty()) return;
    const std::filesystem::path file = scene_folder / io::path_from_utf8(hfog_name(scene_file));
    const auto bytes = fs::read_file(io::utf8_of(file));
    if (!bytes) return;
    stage.height_fog = read_height_fog(bytes->span());
    if (!stage.height_fog) return;
    const HeightFog& fog = *stage.height_fog;
    std::println(stderr, "Sương chiều cao: cao {:.0f}, mật độ {:.3f}, tán xạ {:.2f}", fog.height, fog.density,
        fog.inscatter);
}

void attach_sky_file(Stage& stage, const std::filesystem::path& scene_folder, std::string_view sky_file) {
    if (sky_file.empty()) return;
    const io::TextResult text = io::read_text(scene_folder / io::path_from_utf8(std::string(sky_file)));
    if (!text) return;
    apply_sky(stage, *text);
}

namespace {

[[nodiscard]] bool escapes_model(const std::filesystem::path& relative) noexcept {
    if (relative.empty() || relative.is_absolute()) return true;
    for (const std::filesystem::path& part : relative) {
        if (part == "..") return true;
    }
    return false;
}

// Tên mesh tương đối với Model/; rỗng khi nó thoát khỏi thư mục Model.
[[nodiscard]] std::string mesh_relative(const std::filesystem::path& model_root,
    const std::filesystem::path& model_file, const std::string& mesh) {
    const std::filesystem::path beside = model_file.parent_path() / io::path_from_utf8(mesh);
    const std::filesystem::path full = beside.lexically_normal();
    const std::filesystem::path relative = full.lexically_relative(model_root.lexically_normal());
    if (escapes_model(relative)) return {};
    // generic_string ném khi tên mesh có chữ ngoài trang mã ANSI. Đường trong dữ liệu là UTF-8.
    return io::utf8_of(relative);
}

// Lưới có xương khi cạnh gốc Model có <tên mesh>.skeleton.glb (clip nằm ở đó).
[[nodiscard]] bool has_skeleton(const std::filesystem::path& model_root, const std::string& mesh) {
    std::filesystem::path stem = io::path_from_utf8(mesh).filename();
    stem.replace_extension();
    std::filesystem::path file = model_root / stem;
    file += ".skeleton.glb";
    std::error_code ignored;
    return std::filesystem::is_regular_file(file, ignored);
}

void add_prop(Stage& stage, const Figure& figure, std::string mesh) {
    Prop prop;
    prop.mesh = std::move(mesh);
    prop.placement = figure.placement;
    stage.props.push_back(std::move(prop));
}

void add_ambient(Stage& stage, const Figure& figure, const ModelFile& file,
    const ModelEntity& entity, std::string mesh) {
    Ambient ambient;
    ambient.model = figure.model;
    ambient.frame = file.frame;
    ambient.node = entity.node;
    ambient.mesh = std::move(mesh);
    ambient.placement = figure.placement;
    stage.ambients.push_back(std::move(ambient));
}

void add_figure(Stage& stage, const std::filesystem::path& data_root, const Figure& figure) {
    const std::filesystem::path model_root = data_root / "Model";
    const std::filesystem::path model_file = model_root / io::path_from_utf8(figure.model);
    const io::TextResult text = io::read_text(model_file);
    if (!text) return;
    const ModelFile file = read_model(*text);
    for (const ModelEntity& entity : file.entities) {
        std::string mesh = mesh_relative(model_root, model_file, entity.mesh);
        if (mesh.empty()) continue;
        const bool has_frame = !file.frame.empty() && !entity.node.empty();
        const bool is_animated = has_frame && has_skeleton(model_root, mesh);
        if (is_animated) add_ambient(stage, figure, file, entity, std::move(mesh));
        else add_prop(stage, figure, std::move(mesh));
    }
}

} // namespace

void attach_models(Stage& stage, const std::filesystem::path& data_root) {
    for (const Figure& figure : stage.figures)
        add_figure(stage, data_root, figure);
}

void attach_buildings(std::optional<collision::Model>& slot, const std::filesystem::path& scene_folder,
    std::string_view scene_file) {
    slot.reset();
    if (scene_file.empty()) return;
    std::filesystem::path file = scene_folder / io::path_from_utf8(std::string(scene_file));
    file.replace_extension(".WCollision");
    const core::Result<fs::Bytes> bytes = fs::read_file(io::utf8_of(file));
    if (!bytes) return;
    std::expected<collision::Model, collision::LoadError> loaded = collision::load(bytes->span());
    if (!loaded) {
        std::println(stderr, "Va chạm {}: {}", io::utf8_of(file), collision::describe(loaded.error()));
        return;
    }
    slot = std::move(*loaded);
}

std::expected<World, map::BookError> open_world(std::string_view text) {
    map::BookResult book = map::read_book(text);
    if (!book) return std::unexpected(book.error());
    World world;
    world.book = std::move(*book);
    return world;
}

std::optional<int> file_resid(const std::filesystem::path& data_root) {
    const io::TextResult text = io::read_text(data_root / "Config" / "startup.id");
    if (!text) return std::nullopt;
    std::string_view body(*text);
    while (drop_tail(body)) {
    }
    return core::parse_whole_int(body);
}

EnterResult enter(World& world, int id, const std::filesystem::path& scene_folder) {
    const map::SceneRef* row = map::find_id(world.book, id);
    if (row == nullptr) return fail(EnterError::kUnknownScene);
    const std::optional<EnterCode> ready = cached_enter(world, id);
    if (ready) return *ready;
    EnterError error = EnterError::kMissingFile;
    const std::shared_ptr<ShownScene> shown = load_row(world.book, *row, scene_folder, error);
    if (!shown) return fail(error);
    const std::scoped_lock locked(*world.guard);
    const std::shared_ptr<const ShownScene> again = cached_scene(world, id);
    if (again) {
        world.current = again;
        return EnterCode::kLoaded;
    }
    remember(world, shown);
    return EnterCode::kLoaded;
}

std::shared_ptr<const ShownScene> current_scene(const World& world) {
    const std::scoped_lock locked(*world.guard);
    return world.current;
}

std::string describe_walk(const ShownScene& shown) {
    const std::string free_walk = ": nhân vật không bị vật cản nào chặn";
    if (shown.walk_error) return "Lưới đi hỏng, " + std::string(nav::describe(*shown.walk_error)) + free_walk;
    if (!shown.walk) return "Lưới đi: cảnh không có tệp .path" + free_walk;
    const nav::Mesh& mesh = shown.walk->mesh();
    const std::string shapes = std::to_string(mesh.vertices.size()) + " đỉnh, " + std::to_string(mesh.triangles.size());
    return "Lưới đi: " + shapes + " tam giác, " + std::to_string(mesh.edges.size()) + " cạnh vật cản";
}

std::string_view describe(EnterError error) noexcept {
    switch (error) {
    case EnterError::kUnknownScene: return "không có resid này trong bảng cảnh";
    case EnterError::kMissingFile: return "không đọc được file cảnh của resid";
    case EnterError::kBadXml: return "file cảnh của resid hỏng";
    }
    return "lỗi vào cảnh không rõ";
}

} // namespace game::client::world
