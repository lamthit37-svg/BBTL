// Nội dung một khung của cảnh: trời, nước, địa hình và vật thể tĩnh.
// Mesh hạt tô material hạt cũng ở đây vì nó vào cùng danh sách instance.
#include "client/display/graphic/state.hpp"
namespace game::client {

const std::string& Display::State::material_script() {
    if (material_text_ready) return material_text;
    material_text_ready = true;
    const io::TextResult text = io::read_text(data_root / "Material" / "all.material");
    if (text) material_text = *text;
    return material_text;
}

void Display::State::ensure_water() {
    if (forward == nullptr || device == nullptr) return;
    if (stage == nullptr || ground == nullptr) {
        water_stamp.clear();
        water_mesh.reset();
        return;
    }
    const std::string key = water_key(*stage, ground);
    if (key == water_stamp) return;
    water_stamp = key;
    water_mesh.reset();
    if (key.empty() || data_root.empty()) return;
    resource::Model model = water_model(*stage, *ground, material_script(), data_root);
    if (model.meshes.empty()) return;
    ReadMesh read = baked_mesh(std::move(model));
    water_mesh.emplace();
    water_mesh->model = std::move(read.model);
    auto uploaded = resource::upload_queued(*device, water_mesh->model, read.baked);
    if (!uploaded) {
        water_mesh.reset();
        std::println(stderr, "Mặt nước: {}", uploaded.error());
        return;
    }
    water_mesh->uploaded = std::move(*uploaded);
    auto drawable = forward->prepare(water_mesh->model, water_mesh->uploaded);
    if (!drawable) {
        water_mesh.reset();
        std::println(stderr, "Mặt nước: {}", drawable.error());
        return;
    }
    water_mesh->drawable = std::move(*drawable);
}

void Display::State::append_water() {
    if (!water_mesh) return;
    render::Instance instance;
    instance.drawable = &water_mesh->drawable;
    frame_instances.push_back(instance);
}

void Display::State::ensure_sky() {
    if (stage == nullptr || forward == nullptr || device == nullptr) return;
    // Không có .skysphere thì không dựng vỏ. erengu_DL không có tệp trời: điểm trống là màu sương
    // của cảnh (clear). Một cầu trắng tự thêm nằm gần camera thành tấm xám sáng, không phải trời gốc.
    const std::string key = sky_key(*stage);
    if (key == sky_stamp) return;
    sky_stamp = key;
    sky_mesh.reset();
    if (key.empty() || data_root.empty()) return;
    resource::Model model = sky_model(*stage, data_root);
    if (model.meshes.empty()) return;
    ReadMesh read = baked_mesh(std::move(model));
    // prepare giữ con trỏ vào model và uploaded, nên hai thứ phải đứng yên trước khi prepare.
    sky_mesh.emplace();
    sky_mesh->model = std::move(read.model);
    auto uploaded = resource::upload_queued(*device, sky_mesh->model, read.baked);
    if (!uploaded) {
        sky_mesh.reset();
        std::println(stderr, "Vòm trời: {}", uploaded.error());
        return;
    }
    sky_mesh->uploaded = std::move(*uploaded);
    auto drawable = forward->prepare(sky_mesh->model, sky_mesh->uploaded);
    if (!drawable) {
        sky_mesh.reset();
        std::println(stderr, "Vòm trời: {}", drawable.error());
        return;
    }
    sky_mesh->drawable = std::move(*drawable);
}

void Display::State::append_sky(const render::Camera& camera) {
    if (!sky_mesh) return;
    const float span = clip_far - clip_near;
    if (!(span > 1.0F)) return;
    const math::Matrix4 placed = math::ortho_inverse(camera.view);
    const math::Vector3 eye = placed.translation();
    const float radius = clip_near + (span * 0.95F);
    const math::Vector3 scale{radius, radius, radius};
    render::Instance instance;
    instance.drawable = &sky_mesh->drawable;
    instance.world = math::Matrix4(math::Matrix3::identity(), eye) * math::Matrix4::scale(scale);
    frame_instances.push_back(instance);
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

namespace {

[[nodiscard]] std::optional<resource::Image> read_paint_image(const std::filesystem::path& root,
    std::string_view file) {
    if (file.empty()) return std::nullopt;
    const std::filesystem::path path = root / io::path_from_utf8(std::string(file));
    core::Result<resource::Image> image = resource::load_image_file(io::utf8_of(path));
    if (!image) return std::nullopt;
    image->name = std::string(file);
    return std::move(*image);
}

// Material của tệp mesh (BaseWhite) không phải mặt hạt. Ảnh hạt, mặt nạ, hệ số và cuộn UV thay vào.
// Không tắt sương cảnh: tấm sương xa nằm ngoài 2 km, tắt sương thì chúng thành mảng trắng trên trời.
void assign_paint(resource::Material& material, const fx::Paint& paint, std::uint32_t sampler, bool has_mask) {
    material.extras.clear();
    material.pass.reset();
    material.unlit = true;
    material.double_sided = true;
    material.alpha = resource::Alpha::kBlend;
    material.shading = resource::Shading::kMetallic;
    material.base_color = {.x = paint.gain, .y = paint.gain, .z = paint.gain, .w = 1.0F};
    material.emissive = {.x = paint.scroll_u, .y = paint.scroll_v, .z = 0.0F};
    material.color.image = 0;
    material.color.sampler = sampler;
    resource::Material::Pass pass;
    pass.lit = false;
    pass.color_scale = 1.0F;
    pass.flags = render::kUnlit;
    if (has_mask) {
        material.surface.image = 1;
        material.surface.sampler = sampler;
        pass.flags |= render::kMaskTex;
    }
    material.pass = pass;
}

void bind_primitive(resource::Primitive& primitive) {
    if (!primitive.material) primitive.material = 0;
}

void bind_mesh_material(resource::Mesh& mesh) {
    for (resource::Primitive& primitive : mesh.primitives)
        bind_primitive(primitive);
}

// Sai khi ảnh nền không đọc được: vẽ BaseWhite là một tấm trắng. Thiếu mặt nạ thì vẫn vẽ ảnh nền.
[[nodiscard]] bool paint_particle(resource::Model& model, const fx::Paint& paint, const std::filesystem::path& root) {
    std::optional<resource::Image> color = read_paint_image(root, paint.image);
    if (!color) return false;
    std::optional<resource::Image> mask = read_paint_image(root, paint.second);
    if (!paint.second.empty() && !mask) std::println(stderr, "Hạt mesh: thiếu mặt nạ {}", paint.second);
    resource::Sampler sampler;
    sampler.wrap_u = resource::Wrap::kRepeat;
    sampler.wrap_v = resource::Wrap::kRepeat;
    const auto sampler_index = static_cast<std::uint32_t>(model.samplers.size());
    model.samplers.push_back(sampler);
    model.images.clear();
    model.images.push_back(std::move(*color));
    const bool has_mask = mask.has_value();
    if (has_mask) model.images.push_back(std::move(*mask));
    if (model.materials.empty()) model.materials.emplace_back();
    for (resource::Material& material : model.materials)
        assign_paint(material, paint, sampler_index, has_mask);
    for (resource::Mesh& mesh : model.meshes)
        bind_mesh_material(mesh);
    return true;
}

} // namespace

std::size_t Display::State::load_painted_mesh(const std::string& mesh, std::string_view material,
    const fx::Paint& paint) {
    const std::string key = std::format("{}\n{}", mesh, material);
    const auto found = kept_by_name.find(key);
    if (found != kept_by_name.end()) return found->second;
    auto model = resource::load_named_model(mesh, io::utf8_of(data_root), texture_tier);
    if (!model) {
        std::println(stderr, "Bỏ mesh {}: {}", mesh, model.error());
        return kMissing;
    }
    if (!paint_particle(*model, paint, data_root)) {
        std::println(stderr, "Bỏ hạt mesh {}: thiếu ảnh {}", mesh, paint.image);
        return kMissing;
    }
    return keep_model(key, baked_mesh(std::move(*model)));
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
    if (!can_batch(kept.at(index).loaded.model, kept.at(index).loaded.drawable)) {
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
} // namespace game::client
