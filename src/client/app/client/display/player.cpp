/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/player.cpp
 *  PHÂN HỆ   : Client / Display / Player
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Người chơi trên màn hình (xem player.hpp).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/display/player.hpp"

#include "anim/rig.hpp"
#include "avatar/avatar.hpp"
#include "avatar/gait.hpp"
#include "avatar/locator.hpp"
#include "avatar/rig.hpp"
#include "core/clock.hpp"
#include "core/error.hpp"
#include "io/file.hpp"
#include "look/appearance.hpp"
#include "look/look.hpp"
#include "look/mount.hpp"
#include "look/sect.hpp"
#include "look/skill.hpp"
#include "look/weapon.hpp"
#include "math/matrix.hpp"
#include "math/vector.hpp"
#include "motion/motion.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"
#include "render/forward.hpp"
#include "resource/ogre_mesh.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <expected>
#include <filesystem>
#include <future>
#include <iterator>
#include <limits>
#include <memory>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <utility>
#include <vector>

namespace game::client {
namespace {

// Hạt giống rand() của người chơi duy nhất: chỉ cần cố định để chạy lại ra cùng dãy động tác nghỉ.
constexpr std::uint32_t kSeed = 7;
// Số định danh của người chơi trong bộ làm mượt hướng.
constexpr std::uint32_t kPlayerId = 1;
// Trần số hiệu ứng bám đang theo: nơi vẽ không báo hết (không có bộ vẽ hiệu ứng) thì bỏ cái cũ nhất.
constexpr std::size_t kMaxFollowers = 64;

[[nodiscard]] std::expected<std::string, std::string> read_table(const std::string& path) {
    const auto text = io::read_text(io::path_from_utf8(path));
    if (!text) return std::unexpected(std::string(io::describe(text.error())));
    return *text;
}

// Khối ngoại hình để giải: khối đã chọn, không thì bộ mặc định của giới (id mặt, tóc theo bảng thân;
// id 0 của tóc là một kiểu tóc thật), rồi đặt vũ khí theo vật phẩm khe 0 nếu có.
[[nodiscard]] core::Result<look::Look> look_of(const look::Tables& tables, const PlayerDesc& desc) {
    look::Look wanted;
    if (desc.look) {
        wanted = *desc.look;
    } else {
        const look::PlayerBody* body = look::find_body(tables.bodies, desc.race);
        if (body == nullptr) return core::fail(core::ErrorCode::kNotFound, "không có thân của giới này");
        wanted.face = body->face;
        wanted.hair = body->hair;
    }
    if (desc.weapon_item && !look::equip_weapon(wanted, tables.weapons, *desc.weapon_item)) {
        return core::fail(core::ErrorCode::kNotFound, "vật phẩm không có trong bảng vũ khí", "{}", *desc.weapon_item);
    }
    if (desc.weapon_gem != 0) wanted.weapon_gem = desc.weapon_gem;
    return wanted;
}

// Hình đã giải, và môn có dùng bài múa làm động tác nghỉ hay không.
struct Built {
    look::Figure figure;
    look::Weapon weapon = look::Weapon::kNone;
    bool fidget = true;
    bool demo = false;
};

// Bảng Table/<name> của người mẫu môn phái; đọc không được là kNotFound kèm đường dẫn.
[[nodiscard]] core::Result<std::string> sect_table(const PlayerDesc& desc, std::string_view name) {
    const std::string path = (desc.data_root / "Table" / name).string();
    const auto text = read_table(path);
    if (!text) return core::fail(core::ErrorCode::kNotFound, "bảng người mẫu môn phái", path);
    return *text;
}

// Đồ gắn khe của người mẫu (sect_held.tsv): 鬼谷 cầm gậy bằng Slot của mẫu, không bằng lưới trong
// bảng sect_models. Môn không có dòng thì không gắn gì.
[[nodiscard]] core::Result<std::optional<look::Held>> sect_held(const PlayerDesc& desc,
    std::uint8_t sect) {
    const auto text = sect_table(desc, "sect_held.tsv");
    if (!text) return std::unexpected(text.error());
    auto held = look::sect_held(*text, desc.race, sect);
    if (!held) return core::fail(core::ErrorCode::kCorrupt, "đồ gắn môn phái", held.error());
    return std::move(*held);
}

// Người mẫu môn phái: bảng sect_models cùng đồ gắn khe của sect_held, không vũ khí trong tay theo
// bộ hành động (weapon kNone), fidget theo dòng mẫu.
[[nodiscard]] core::Result<Built> sect_figure(const PlayerDesc& desc, std::uint8_t sect) {
    const auto text = sect_table(desc, "sect_models.tsv");
    if (!text) return std::unexpected(text.error());
    auto figure = look::sect_figure(*text, desc.race, sect);
    if (!figure) return core::fail(core::ErrorCode::kCorrupt, "người mẫu môn phái", figure.error());
    auto held = sect_held(desc, sect);
    if (!held) return std::unexpected(held.error());
    if (*held) figure->figure.held.push_back(std::move(**held));
    Built built{.figure = std::move(figure->figure), .fidget = figure->has_fidget, .demo = true};
    return built;
}

// Khối đã chọn, không thì bộ mặc định của giới, rồi vũ khí đang cầm.
[[nodiscard]] core::Result<Built> player_figure(const look::Tables& tables, const PlayerDesc& desc) {
    const auto wanted = look_of(tables, desc);
    if (!wanted) return std::unexpected(wanted.error());
    auto figure = look::resolve(tables, desc.race, *wanted);
    if (!figure) return core::fail(core::ErrorCode::kCorrupt, "không giải được ngoại hình", "{}", look::describe(figure.error()));
    return Built{.figure = std::move(*figure), .weapon = wanted->weapon};
}

[[nodiscard]] core::Result<Built> figure_of(const look::Tables& tables, const PlayerDesc& desc) {
    if (desc.sect) return sect_figure(desc, *desc.sect);
    return player_figure(tables, desc);
}

// Drawable của một bộ phận, hoặc nullptr kèm log khi nơi vẽ không nạp được lưới.
[[nodiscard]] const render::Drawable* part_drawable(const MeshLoader& load_mesh, const look::Part& part) {
    const render::Drawable* drawable = load_mesh(part.mesh, {});
    if (drawable == nullptr) std::println(stderr, "Người chơi: bỏ bộ phận {}", part.mesh);
    return drawable;
}

[[nodiscard]] std::vector<const render::Drawable*> load_parts(const look::Figure& figure, const MeshLoader& load_mesh) {
    std::vector<const render::Drawable*> parts;
    parts.reserve(figure.parts.size());
    for (const look::Part& part : figure.parts) {
        parts.push_back(part_drawable(load_mesh, part));
    }
    std::erase(parts, nullptr);
    return parts;
}

// Một lưới của mẫu. Không nạp được thì ghi log và bỏ; mẫu vẫn giữ các lưới đã nạp.
void add_held_mesh(std::vector<HeldMesh>& drawn, std::size_t mount, const std::string& mesh, const MeshLoader& load_mesh) {
    const render::Drawable* drawable = load_mesh(mesh, {});
    if (drawable == nullptr) {
        std::println(stderr, "Người chơi: bỏ lưới vũ khí {}", mesh);
        return;
    }
    drawn.push_back(HeldMesh{.mount = mount, .drawable = drawable});
}

void load_mount(std::vector<HeldMesh>& drawn, std::size_t mount, const look::Held& held, const MeshLoader& load_mesh) {
    for (const std::string& mesh : held.meshes) add_held_mesh(drawn, mount, mesh, load_mesh);
}

[[nodiscard]] std::vector<HeldMesh> load_held(const look::Figure& figure,
    const MeshLoader& load_mesh) {
    std::vector<HeldMesh> drawn;
    for (std::size_t mount = 0; mount < figure.held.size(); ++mount) {
        load_mount(drawn, mount, figure.held[mount], load_mesh);
    }
    return drawn;
}

// Id CharMount vừa int32 của cột gốc. 0 là hổ, vẫn hợp lệ.
[[nodiscard]] bool ride_id_fits(std::uint32_t id) noexcept {
    const auto cap = static_cast<std::uint32_t>(std::numeric_limits<std::int32_t>::max());
    return id <= cap;
}

[[nodiscard]] core::Failure ride_fail(std::string_view detail) {
    return core::fail(core::ErrorCode::kNotFound, "thú cưỡi", detail);
}

[[nodiscard]] core::Failure ride_id_fail() {
    return core::fail(core::ErrorCode::kInvalidArgument, "id thú vượt int32");
}

void say_ride_name(const look::RideFigure& figure) {
    std::println("Thú cưỡi {} {} lưới {}", figure.id, figure.name, figure.mesh);
}

void say_ride_anchor(const look::RideFigure& figure) {
    std::println("Neo {} cao {}", figure.anchor, figure.add_height);
}

void say_ride_place(const look::RideFigure& figure) {
    say_ride_anchor(figure);
    std::println("Camera {}", figure.camera_y);
}

void say_ride_speed(const look::RideFigure& figure) {
    const float run = motion::human_speed(motion::MoveMode::kRun);
    const float speed = motion::mounted_speed(run, figure.speed_percent);
    std::println("Tốc độ +{}% {:.2f}", figure.speed_percent, speed);
}

// Đuôi .mesh thành hậu tố khác. Tên không phải lưới thì giữ nguyên.
[[nodiscard]] std::string with_suffix(std::string_view mesh, std::string_view suffix) {
    constexpr std::string_view kMesh = ".mesh";
    std::string name(mesh);
    const bool is_mesh = name.size() >= kMesh.size() && name.ends_with(kMesh);
    if (is_mesh) name.replace(name.size() - kMesh.size(), kMesh.size(), suffix);
    return name;
}

void say_attached(std::string_view name, std::string_view bone, const math::Vector3& moved) {
    std::println("Gắn {} {} {} {} {}", name, bone, moved.x(), moved.y(), moved.z());
}

[[nodiscard]] bool bone_missing(const anim::SourceSkeleton& bones, std::string_view name) {
    if (name.empty()) return false;
    const auto found = std::ranges::find(bones.bones, name, &anim::Bone::name);
    return found == bones.bones.end();
}

// Tư thế bind của locator. Xương ghi trong mẫu mà skeleton không có thì không bịa vị trí lệch.
[[nodiscard]] std::optional<math::Matrix4> seat_from_model(const resource::Model& model,
    const look::LocatorRow& row) {
    auto bones = resource::bones_of(model);
    if (!bones) return std::nullopt;
    if (bone_missing(*bones, row.bone)) return std::nullopt;
    auto rig = anim::Rig::create(*bones);
    if (!rig) return std::nullopt;
    const std::span<const anim::Transform> local = rig->initial();
    const std::vector<anim::Transform> derived = rig->derive(local);
    const avatar::Locator locator = avatar::make_locator(row, *bones);
    const anim::Transform pose = avatar::locator_pose(locator, derived);
    const anim::Affine rows = anim::affine_of(pose);
    return avatar::matrix_of(rows);
}

// Văn bản một bảng thú cưỡi trong Table. Không đọc được thì báo và trả rỗng. Phân tích bảng nằm
// ở look; display không đọc table trực tiếp (GameLayers).
[[nodiscard]] std::optional<std::string> ride_text(const PlayerDesc& desc, std::string_view file) {
    const std::string path = io::utf8_of(desc.data_root / "Table" / file);
    auto text = read_table(path);
    if (text) return std::move(*text);
    std::println(stderr, "Thú cưỡi: không đọc {}", file);
    return std::nullopt;
}

[[nodiscard]] std::vector<look::LocatorRow> locator_rows(const PlayerDesc& desc) {
    const auto text = ride_text(desc, "ride_locators.tsv");
    if (!text) return {};
    auto rows = look::parse_ride_locators(*text);
    if (!rows) {
        std::println(stderr, "Thú cưỡi: {}", rows.error());
        return {};
    }
    return std::move(*rows);
}

[[nodiscard]] std::optional<look::LocatorRow> ride_locator(const PlayerDesc& desc,
    std::string_view object, std::string_view anchor) {
    const std::vector<look::LocatorRow> rows = locator_rows(desc);
    const look::LocatorRow* found = look::find_locator(rows, object, anchor);
    if (found == nullptr) return std::nullopt;
    return *found;
}

// Neo bind và handle xương. Thiếu locator hoặc skeleton thì đơn vị, không bịa toạ độ.
struct SeatPose {
    math::Matrix4 seat = math::Matrix4::identity();
    std::optional<avatar::Locator> point;
};

[[nodiscard]] std::string with_glb(std::string_view skeleton) {
    std::string file(skeleton);
    file += ".glb";
    return file;
}

// Tên .skeleton thật trong ride_skeletons. Không có dòng thì đuôi lưới.
[[nodiscard]] std::string ride_skeleton_name(const PlayerDesc& desc,
    const look::RideFigure& figure) {
    const std::string fallback = with_suffix(figure.mesh, ".skeleton");
    const auto text = ride_text(desc, "ride_skeletons.tsv");
    if (!text) return fallback;
    auto name = look::parse_ride_skeleton(*text, figure.model_id);
    if (!name) std::println(stderr, "Thú cưỡi: {}", name.error());
    if (!name || name->empty()) return fallback;
    return std::move(*name);
}

[[nodiscard]] SeatPose seat_pose(const PlayerDesc& desc, const look::RideFigure& figure,
    std::string_view skeleton_glb) {
    SeatPose made;
    const std::string object = with_suffix(figure.mesh, ".obj");
    auto row = ride_locator(desc, object, figure.anchor);
    if (!row) {
        std::println(stderr, "Thú cưỡi: {} không có neo {}", object, figure.anchor);
        return made;
    }
    const std::string root = io::utf8_of(desc.data_root);
    auto model = resource::load_named_model(skeleton_glb, root);
    if (!model) {
        std::println(stderr, "Thú cưỡi: không nạp {}", skeleton_glb);
        return made;
    }
    auto seat = seat_from_model(*model, *row);
    if (!seat) {
        std::println(stderr, "Thú cưỡi: không dựng neo {} xương {}", row->name, row->bone);
        return made;
    }
    made.seat = *seat;
    const math::Vector3 moved = made.seat.translation();
    say_attached(row->name, row->bone, moved);
    auto bones = resource::bones_of(*model);
    if (!bones) return made;
    made.point = avatar::make_locator(*row, *bones);
    return made;
}

[[nodiscard]] std::vector<look::RacedAnimRow> load_ride_anims(const PlayerDesc& desc) {
    const auto text = ride_text(desc, "ride_anims.tsv");
    if (!text) return {};
    auto rows = look::parse_ride_anims(*text);
    if (!rows) {
        std::println(stderr, "Thú cưỡi: {}", rows.error());
        return {};
    }
    return std::move(*rows);
}

// Ô tra clip cưỡi: bộ động tác CharMount, giới người cưỡi và loại vũ khí đang cầm.
struct RideCell {
    std::span<const look::RacedAnimRow> rows;
    look::Race race = look::Race::kFemale;
    std::uint32_t set = 0;
    look::Weapon weapon = look::Weapon::kNone;
};

const look::AnimRow* cell_anim(const RideCell& cell, look::Action action, look::Weapon weapon) {
    return look::find_raced_anim(cell.rows, cell.race, cell.set, action, weapon);
}

const look::AnimRow* ride_anim(const RideCell& cell, look::Action action) {
    const look::AnimRow* armed = cell_anim(cell, action, cell.weapon);
    const look::AnimRow* bare = cell_anim(cell, action, look::Weapon::kNone);
    return armed != nullptr ? armed : bare;
}

void apply_action(look::Figure& figure, const RideCell& cell, look::Action action) {
    const look::AnimRow* row = ride_anim(cell, action);
    if (row == nullptr) return;
    const look::Clip clip{.anim = row->anim, .name = row->clip};
    if (action == look::Action::kIdle) figure.idle = clip;
    if (action == look::Action::kIdleAlt) figure.idle_alt = clip;
    if (action == look::Action::kIdleAlt2) figure.idle_alt2 = clip;
    if (action == look::Action::kRun) figure.run = clip;
    if (action == look::Action::kJumpStand) figure.jump_stand = clip;
    if (action == look::Action::kJumpRun) figure.jump_run = clip;
}

// Đổi clip đi, đứng, nhảy của người sang bộ động tác CharMount. Không có dòng thì giữ clip thân.
void apply_ride_anims(look::Figure& figure, std::span<const look::RacedAnimRow> rows,
    look::Race race, std::int32_t action_set, look::Weapon weapon) {
    if (action_set < 0) return;
    const auto set = static_cast<std::uint32_t>(action_set);
    const RideCell cell{.rows = rows, .race = race, .set = set, .weapon = weapon};
    const look::Clip previous = figure.idle;
    apply_action(figure, cell, look::Action::kIdle);
    const bool changed = figure.idle.name != previous.name || figure.idle.anim != previous.anim;
    if (!changed) return;
    figure.idle_trim.reset();
    figure.idle_alt.reset();
    figure.idle_alt2.reset();
    figure.jump_stand.reset();
    figure.jump_run.reset();
    apply_action(figure, cell, look::Action::kIdleAlt);
    apply_action(figure, cell, look::Action::kIdleAlt2);
    apply_action(figure, cell, look::Action::kRun);
    apply_action(figure, cell, look::Action::kJumpStand);
    apply_action(figure, cell, look::Action::kJumpRun);
    std::println("Clip cưỡi {} / {}", figure.idle.anim, figure.idle.name);
}

[[nodiscard]] look::MountClips mount_clips(const PlayerDesc& desc, std::int32_t model) {
    const auto text = ride_text(desc, "ride_model_clips.tsv");
    if (!text) return {};
    auto clips = look::parse_mount_clips(*text, model);
    if (!clips) {
        std::println(stderr, "Thú cưỡi: {}", clips.error());
        return {};
    }
    return std::move(*clips);
}

void say_mount_run(const look::Figure& body) {
    if (body.run.name == body.idle.name) return;
    std::println("Clip thú chạy {} / {}", body.run.anim, body.run.name);
}

[[nodiscard]] std::optional<avatar::Avatar> mount_avatar(const PlayerDesc& desc,
    std::string_view skeleton, const look::MountClips& pose) {
    if (skeleton.empty() || !pose.idle) return std::nullopt;
    look::Figure body;
    body.skeleton = std::string(skeleton);
    body.idle = *pose.idle;
    body.run = pose.run ? *pose.run : *pose.idle;
    body.idle_alt = pose.idle_alt;
    body.idle_alt2 = pose.idle_alt2;
    body.jump_stand = pose.jump_stand;
    body.jump_run = pose.jump_run;
    auto loaded = avatar::Avatar::load(body, desc.data_root);
    if (!loaded) {
        std::println(stderr, "Thú cưỡi: không phát clip {}", skeleton);
        return std::nullopt;
    }
    std::println("Clip thú {} / {}", body.idle.anim, body.idle.name);
    say_mount_run(body);
    return std::move(*loaded);
}

void say_halo(const look::RideOffset& offset) {
    std::println("Quầng {} lệch {} {} {}", look::kHaloSlot, offset.x, offset.y, offset.z);
    std::println("Góc {} trục {} {} {}", offset.angle, offset.axis_x, offset.axis_y, offset.axis_z);
}

void say_ride(const look::RideFigure& figure) {
    say_ride_name(figure);
    say_ride_place(figure);
    say_ride_speed(figure);
    if (!figure.offset) return;
    say_halo(*figure.offset);
}

// desc.ride_id đã có và vừa int32. Mã giới là giá trị Race (0 nữ, 1 nam), chưa chứng minh khớp
// +0x1c.
[[nodiscard]] core::Result<look::RideFigure> figure_for_ride(const PlayerDesc& desc) {
    const std::string folder = io::utf8_of(desc.data_root / "Table");
    auto tables = look::load_ride_tables(folder, read_table);
    if (!tables) return ride_fail(tables.error());
    const int sex = static_cast<int>(desc.race);
    const auto id = static_cast<std::int32_t>(*desc.ride_id);
    auto figure = look::ride_figure(*tables, id, sex, sex, look::kRideOwner);
    if (!figure) return ride_fail(figure.error());
    return std::move(*figure);
}

// Lưới, neo và clip. Khác gốc: chưa cộng add_height, chưa áp lệch quầng.
struct RideDrawn {
    std::vector<const render::Drawable*> meshes;
    math::Matrix4 seat = math::Matrix4::identity();
    std::optional<avatar::Avatar> body;
    std::optional<avatar::Locator> point;
    avatar::ClipLengths lengths{};
    bool fidget = false;
    std::int32_t speed_percent = 0;
    std::vector<RideSpark> sparks;
};

[[nodiscard]] anim::SourceSkeleton skeleton_bones(const PlayerDesc& desc,
    std::string_view skeleton_glb) {
    anim::SourceSkeleton bones;
    const std::string root = io::utf8_of(desc.data_root);
    auto model = resource::load_named_model(std::string(skeleton_glb), root);
    if (!model) return bones;
    auto read = resource::bones_of(*model);
    if (!read) return bones;
    return std::move(*read);
}

[[nodiscard]] RideSpark spark_from(const look::RideEffect& effect, const look::LocatorRow& row,
    const anim::SourceSkeleton& bones) {
    RideSpark spark;
    spark.name = effect.effect;
    spark.locator = avatar::make_locator(row, bones);
    spark.translate_all = effect.translate_all;
    return spark;
}

void add_spark(std::vector<RideSpark>& out, const look::RideEffect& effect,
    std::span<const look::LocatorRow> locators, const anim::SourceSkeleton& bones) {
    const look::LocatorRow* row = look::find_locator(locators, effect.object, effect.locator);
    if (row == nullptr) {
        std::println(stderr, "Thú cưỡi: {} thiếu điểm {}", effect.object, effect.locator);
        return;
    }
    out.push_back(spark_from(effect, *row, bones));
}

void add_object_sparks(std::vector<RideSpark>& out, std::span<const look::RideEffect> effects,
    std::string_view object, std::span<const look::LocatorRow> locators,
    const anim::SourceSkeleton& bones) {
    for (const look::RideEffect& effect : effects) {
        if (effect.object != object) continue;
        add_spark(out, effect, locators, bones);
    }
}

void fill_sparks(std::vector<RideSpark>& out, const PlayerDesc& desc,
    const look::RideFigure& figure, std::string_view skeleton_glb) {
    const std::string path = io::utf8_of(desc.data_root / "Table" / "ride_effects.tsv");
    auto text = read_table(path);
    if (!text) {
        std::println(stderr, "Thú cưỡi: không đọc ride_effects.tsv");
        return;
    }
    auto effects = look::parse_ride_effects(*text);
    if (!effects) {
        std::println(stderr, "Thú cưỡi: {}", effects.error());
        return;
    }
    const std::string object = with_suffix(figure.mesh, ".obj");
    const std::vector<look::LocatorRow> locators = locator_rows(desc);
    const anim::SourceSkeleton bones = skeleton_bones(desc, skeleton_glb);
    add_object_sparks(out, *effects, object, locators, bones);
    std::println("Hiệu ứng thú {} điểm", out.size());
}

[[nodiscard]] const render::Drawable* take_ride_mesh(const MeshLoader& load_mesh,
    const std::string& file, std::string_view materials) {
    const render::Drawable* drawable = load_mesh(file, materials);
    if (drawable == nullptr) std::println(stderr, "Người chơi: bỏ lưới thú {}", file);
    return drawable;
}

void keep_ride_mesh(RideDrawn& drawn, const render::Drawable* drawable) {
    if (drawable == nullptr) return;
    drawn.meshes.push_back(drawable);
}

void use_baked_mesh(RideDrawn& drawn, const MeshLoader& load_mesh, const std::string& file) {
    const std::string_view baked;
    const render::Drawable* drawable = take_ride_mesh(load_mesh, file, baked);
    keep_ride_mesh(drawn, drawable);
}

void add_ride_entity(RideDrawn& drawn, const MeshLoader& load_mesh,
    const look::RideEntity& entity) {
    if (!entity.condition.empty()) {
        std::println(stderr, "Thú cưỡi: bỏ lưới có điều kiện {}", entity.file);
        return;
    }
    const render::Drawable* drawable = take_ride_mesh(load_mesh, entity.file, entity.materials);
    keep_ride_mesh(drawn, drawable);
}

void add_object_entities(RideDrawn& drawn, const MeshLoader& load_mesh,
    std::span<const look::RideEntity> rows, std::string_view object) {
    for (const look::RideEntity& entity : rows) {
        if (entity.object != object) continue;
        add_ride_entity(drawn, load_mesh, entity);
    }
}

// Danh sách Entity của all.obj. Không có dòng thì mới rơi về tên lưới của CharModelEx.
void fill_entities(RideDrawn& drawn, const PlayerDesc& desc, const look::RideFigure& figure,
    const MeshLoader& load_mesh) {
    const std::string object = with_suffix(figure.mesh, ".obj");
    const std::string path = io::utf8_of(desc.data_root / "Table" / "ride_entities.tsv");
    auto text = read_table(path);
    if (!text) {
        std::println(stderr, "Thú cưỡi: không đọc ride_entities.tsv");
        use_baked_mesh(drawn, load_mesh, figure.mesh);
        return;
    }
    auto rows = look::parse_ride_entities(*text);
    if (!rows) {
        std::println(stderr, "Thú cưỡi: {}", rows.error());
        use_baked_mesh(drawn, load_mesh, figure.mesh);
        return;
    }
    const std::size_t before = drawn.meshes.size();
    add_object_entities(drawn, load_mesh, *rows, object);
    if (drawn.meshes.size() != before) {
        std::println("Lưới thú {} tệp", drawn.meshes.size() - before);
        return;
    }
    std::println(stderr, "Thú cưỡi: {} không có danh sách lưới", object);
    use_baked_mesh(drawn, load_mesh, figure.mesh);
}

void fill_ride(RideDrawn& drawn, const PlayerDesc& desc, const look::RideFigure& figure,
    const MeshLoader& load_mesh) {
    const std::string skeleton = ride_skeleton_name(desc, figure);
    const std::string skeleton_glb = with_glb(skeleton);
    const SeatPose seated = seat_pose(desc, figure, skeleton_glb);
    drawn.seat = seated.seat;
    drawn.point = seated.point;
    const look::MountClips pose = mount_clips(desc, figure.model_id);
    drawn.body = mount_avatar(desc, skeleton, pose);
    if (drawn.body) drawn.lengths = drawn.body->lengths();
    drawn.fidget = pose.idle_alt.has_value();
    fill_entities(drawn, desc, figure, load_mesh);
    fill_sparks(drawn.sparks, desc, figure, skeleton_glb);
}

// desc.ride_id đã có. Đổi clip người trước khi nạp avatar người.
[[nodiscard]] core::Result<RideDrawn> ride_drawn(const PlayerDesc& desc, look::Figure& rider,
    look::Weapon weapon, const MeshLoader& load_mesh) {
    if (!ride_id_fits(*desc.ride_id)) return ride_id_fail();
    auto figure = figure_for_ride(desc);
    if (!figure) return std::unexpected(figure.error());
    say_ride(*figure);
    const std::vector<look::RacedAnimRow> anims = load_ride_anims(desc);
    apply_ride_anims(rider, anims, desc.race, figure->rider_action, weapon);
    RideDrawn drawn;
    fill_ride(drawn, desc, *figure, load_mesh);
    drawn.speed_percent = figure->speed_percent;
    return drawn;
}

[[nodiscard]] core::Result<RideDrawn> take_ride(const PlayerDesc& desc, Built& built,
    const MeshLoader& load_mesh) {
    RideDrawn drawn;
    if (!desc.ride_id) return drawn;
    auto ready = ride_drawn(desc, built.figure, built.weapon, load_mesh);
    if (!ready) return std::unexpected(ready.error());
    if (!built.figure.idle_alt) built.fidget = false;
    return std::move(*ready);
}

// Đòn của mọi skill đã học theo giới và loại vũ khí đang cầm. Người mẫu môn phái không đánh nên bỏ qua.
[[nodiscard]] std::vector<look::Strike> strikes_for(const look::SkillTables& tables, const PlayerDesc& desc,
    look::Weapon weapon) {
    std::vector<look::Strike> strikes;
    if (desc.sect) return strikes;
    for (const std::uint32_t skill : desc.skills) {
        for (look::Strike& strike : look::strikes_of(tables, desc.race, weapon, skill)) {
            strikes.push_back(std::move(strike));
        }
    }
    return strikes;
}

// Phần bảng mà desc cần. Bốn bảng vũ khí chỉ khi người chơi cầm gì đó hay có skill (điểm gắn hiệu ứng của đòn là
// locator), năm bảng đòn đánh chỉ khi có skill: nạp đầu có ngân sách (AGENTS.md mục 0).
struct Needs {
    bool weapons = false;
    bool skills = false;
};

[[nodiscard]] Needs needs_of(const PlayerDesc& desc) {
    const bool has_weapon = desc.weapon_item || (desc.look && desc.look->weapon_visual != 0);
    const bool has_skills = !desc.skills.empty() && !desc.sect;
    return Needs{.weapons = has_weapon || has_skills, .skills = has_skills};
}

[[nodiscard]] core::Result<std::shared_ptr<const PlayerTables>> read_player_tables(const std::filesystem::path& data_root,
    Needs needs) {
    const std::string folder = io::utf8_of(data_root / "Table");
    auto made = std::make_shared<PlayerTables>();
    auto tables = look::load_tables(folder, read_table);
    if (!tables) {
        return core::fail(core::ErrorCode::kNotFound, "không nạp được bảng ngoại hình", "{}", tables.error());
    }
    made->look = std::move(*tables);
    if (needs.weapons) {
        auto weapons = look::load_weapon_tables(folder, read_table);
        if (!weapons) {
            return core::fail(core::ErrorCode::kNotFound, "không nạp được bảng vũ khí", "{}", weapons.error());
        }
        made->look.weapons = std::move(*weapons);
    }
    if (needs.skills) {
        auto skills = look::load_skill_tables(folder, read_table);
        if (!skills) {
            return core::fail(core::ErrorCode::kNotFound, "không nạp được bảng đòn đánh", "{}", skills.error());
        }
        made->skills = std::move(*skills);
    }
    return std::shared_ptr<const PlayerTables>(std::move(made));
}

// Ma trận đặt: phóng theo tỉ lệ, quay quanh +y theo hướng mặt rồi dời tới chân. Cột 0 là +x sau
// khi quay, cột 2 là +z sau khi quay (hướng 0 nhìn +z, hướng pi/2 nhìn +x).
[[nodiscard]] math::Matrix4 placement(const Stand& stand) {
    const float sine = std::sin(stand.facing) * stand.scale;
    const float cosine = std::cos(stand.facing) * stand.scale;
    const math::Vector4 col0(cosine, 0.0F, -sine, 0.0F);
    const math::Vector4 col1(0.0F, stand.scale, 0.0F, 0.0F);
    const math::Vector4 col2(sine, 0.0F, cosine, 0.0F);
    const math::Vector4 col3(stand.foot.x(), stand.foot.y(), stand.foot.z(), 1.0F);
    return {col0, col1, col2, col3};
}

struct WorldPose {
    ogre::Vec3 position;
    ogre::Quat orientation;
};

// Các bước của một skill theo thứ tự strikes(), và kiểu chọn bước của bước đầu tiên gặp.
struct SkillRun {
    std::vector<std::uint32_t> steps;
    look::ActionKind kind = look::ActionKind::kRandom;
};

void take_step(SkillRun& run, const look::Strike& strike, std::uint32_t skill) {
    if (strike.skill != skill) return;
    if (run.steps.empty()) run.kind = strike.kind;
    run.steps.push_back(strike.step);
}

[[nodiscard]] ogre::Vec3 offset_of(const math::Point3& foot, const ogre::Vec3& around) {
    const float x = foot.x() + around.x;
    const float y = foot.y() + around.y;
    const float z = foot.z() + around.z;
    return ogre::Vec3{.x = x, .y = y, .z = z};
}

[[nodiscard]] SkillRun skill_run(std::span<const look::Strike> strikes, std::uint32_t skill) {
    SkillRun run;
    for (const look::Strike& strike : strikes) take_step(run, strike, skill);
    return run;
}

// Điểm trong không gian mẫu nhân vật sang toạ độ thế giới bằng nút chính của mẫu: phóng theo tỉ lệ, xoay quanh +y theo
// hướng mặt, dời tới chân (cùng phép với placement).
[[nodiscard]] WorldPose world_of(const anim::Transform& pose, const Stand& drawn) {
    const ogre::Quat turn = ogre::quat_from_angle_axis(drawn.facing, ogre::Vec3{.x = 0.0F, .y = 1.0F, .z = 0.0F});
    const ogre::Vec3 grown{.x = pose.position.x * drawn.scale, .y = pose.position.y * drawn.scale,
        .z = pose.position.z * drawn.scale};
    const ogre::Vec3 around = ogre::quat_rotate(turn, grown);
    const ogre::Vec3 position = offset_of(drawn.foot, around);
    const ogre::Quat facing = ogre::quat_multiply(turn, pose.orientation);
    return WorldPose{.position = position, .orientation = facing};
}

// Render.dll gắn hiệu ứng làm nút con của điểm neo, không thừa hưởng tỉ lệ. translateAll thiếu
// hoặc false (addEffect kiểu 0) còn tắt thừa hưởng hướng: hiệu ứng đứng ở điểm neo nhưng trục
// trùng trục thế giới, không quay theo mẫu hay theo hướng mặt.
[[nodiscard]] RideFx ride_fx_at(const RideSpark& spark, std::uint32_t index, std::int32_t ride,
    std::span<const anim::Transform> bones, const Stand& drawn) {
    const anim::Transform pose = avatar::locator_pose(spark.locator, bones);
    const WorldPose placed = world_of(pose, drawn);
    RideFx made;
    made.ride = ride;
    made.index = index;
    made.name = spark.name;
    made.position = placed.position;
    made.orientation = spark.translate_all ? placed.orientation : ogre::Quat{};
    return made;
}

[[nodiscard]] core::Result<avatar::Avatar> load_rider(const look::Figure& figure,
    const PlayerDesc& desc, std::span<const look::Strike> strikes,
    std::span<const look::LocatorRow> locators) {
    return avatar::Avatar::load(figure, desc.data_root, strikes, locators);
}

} // namespace

PlayerActor::PlayerActor(avatar::Avatar avatar, std::vector<const render::Drawable*> parts,
    std::vector<HeldMesh> held, bool fidget, bool demo)
    : avatar_(std::move(avatar)),
      gait_(kSeed, avatar::kIdleInterval),
      lengths_(avatar_.lengths()),
      parts_(std::move(parts)),
      held_(std::move(held)),
      ride_gait_(kSeed, avatar::kIdleInterval),
      cue_demo_(demo) {
    gait_.set_fidget(fidget);
}

core::Result<std::shared_ptr<const PlayerTables>> load_player_tables(const std::filesystem::path& data_root) {
    return read_player_tables(data_root, Needs{.weapons = true, .skills = true});
}

PlayerTablesJob start_player_tables(std::filesystem::path data_root) {
    return std::async(std::launch::async, [root = std::move(data_root)]() -> std::shared_ptr<const PlayerTables> {
        auto loaded = load_player_tables(root);
        return loaded ? std::move(*loaded) : nullptr;
    });
}

core::Result<PlayerActor> PlayerActor::create(const PlayerDesc& desc, const MeshLoader& load_mesh) {
    std::shared_ptr<const PlayerTables> tables = desc.tables;
    if (!tables) {
        auto read = read_player_tables(desc.data_root, needs_of(desc));
        if (!read) return std::unexpected(read.error());
        tables = std::move(*read);
    }
    auto built = figure_of(tables->look, desc);
    if (!built) return std::unexpected(built.error());
    auto ride = take_ride(desc, *built, load_mesh);
    if (!ride) return std::unexpected(ride.error());
    const std::vector<look::Strike> strikes = strikes_for(tables->skills, desc, built->weapon);
    const auto locators = std::span<const look::LocatorRow>{tables->look.weapons.locators};
    auto avatar = load_rider(built->figure, desc, strikes, locators);
    if (!avatar) return std::unexpected(avatar.error());
    std::vector<const render::Drawable*> parts = load_parts(built->figure, load_mesh);
    std::vector<HeldMesh> held = load_held(built->figure, load_mesh);
    const bool fidget = built->fidget;
    const bool demo = built->demo;
    PlayerActor actor(std::move(*avatar), std::move(parts), std::move(held), fidget, demo);
    actor.ride_ = std::move(ride->meshes);
    actor.seat_ = ride->seat;
    actor.ride_body_ = std::move(ride->body);
    actor.ride_point_ = std::move(ride->point);
    actor.ride_lengths_ = ride->lengths;
    actor.ride_gait_.set_fidget(ride->fidget);
    const bool has_mesh = !actor.ride_.empty();
    const bool has_body = actor.ride_body_.has_value();
    actor.riding_ = desc.ride_id.has_value() && (has_mesh || has_body);
    actor.ride_speed_percent_ = ride->speed_percent;
    const bool keep_fx = actor.riding_ && desc.ride_id.has_value();
    if (!keep_fx) return actor;
    actor.ride_sparks_ = std::move(ride->sparks);
    actor.ride_id_ = static_cast<std::int32_t>(*desc.ride_id);
    return actor;
}

bool PlayerActor::stays_airborne(const Stand& stand) const noexcept {
    const bool planted = riding_ && !stand.is_moving;
    return !planted;
}

void PlayerActor::begin_ride_jump(core::Clock::time_point now, const Stand& stand) {
    if (stand.jump) ride_gait_.jump(now, *stand.jump, ride_lengths_, stays_airborne(stand));
    if (stand.has_landed) ride_gait_.land(now, ride_lengths_);
}

core::Status PlayerActor::pose_ride(core::Clock::time_point now, const Stand& stand) {
    if (!ride_body_) return core::ok();
    // ChangeAction param_8 = 1 (0x1405e2680): thú nhận cùng hành động 9 hoặc 12 trước update.
    begin_ride_jump(now, stand);
    const avatar::Playing playing = ride_gait_.update(now, stand.is_moving, ride_lengths_);
    const core::Status posed = ride_skin_.update(*ride_body_, playing);
    if (!posed) return posed;
    if (!ride_point_) return core::ok();
    const anim::Transform pose = avatar::locator_pose(*ride_point_, ride_skin_.derived());
    const anim::Affine rows = anim::affine_of(pose);
    seat_ = avatar::matrix_of(rows);
    return core::ok();
}

core::Status PlayerActor::update(core::Clock::time_point now, const Stand& stand) {
    const core::Status riding = pose_ride(now, stand);
    if (!riding) return riding;
    if (cue_demo_) {
        gait_.cue(avatar::Stance::kIdleAlt);
        cue_demo_ = false;
    }
    if (stand.jump) gait_.jump(now, *stand.jump, lengths_, stays_airborne(stand));
    if (stand.has_landed) gait_.land(now, lengths_);
    release_chain(now, stand);
    if (stand.strike && !gait_.is_locked(now)) begin_strike(now, *stand.strike);
    const avatar::Playing playing = gait_.update(now, stand.is_moving, lengths_);
    const core::Status posed = skinner_.update(avatar_, playing);
    if (!posed) return posed;
    avatar_.mount_matrices(skinner_.derived(), mounts_);
    Stand drawn = stand;
    drawn.facing = turning_.face(kPlayerId, stand.facing, now);
    turning_.drop_unseen();
    placed_ = placement(drawn);
    fire_cues(playing, drawn);
    place_gear(drawn);
    place_follows(drawn);
    place_ride_fx(drawn);
    return core::ok();
}

// Mọi kiểu bước, kể cả kLinked. Kiểu chỉ chọn chỉ số (accept_chain), không loại đòn khỏi danh sách.
// Bước không có clip đã bị strikes_of bỏ: count ở đây ngắn hơn m_nActionCount gốc khi thiếu clip.
std::vector<std::uint32_t> PlayerActor::steps_of(std::uint32_t skill) const {
    return skill_run(avatar_.strikes(), skill).steps;
}

std::optional<std::uint32_t> PlayerActor::accept_strike(std::uint32_t skill, std::uint32_t roll, core::Clock::time_point now) {
    const SkillRun run = skill_run(avatar_.strikes(), skill);
    if (run.steps.empty() || run.steps.size() > static_cast<std::size_t>(look::kMaxChainSteps)) return std::nullopt;
    const auto count = static_cast<std::int32_t>(run.steps.size());
    const look::ChainPick pick = look::accept_chain(chain_, skill, run.kind, count, roll, !gait_.in_strike(now));
    if (!pick.plays || pick.slot >= run.steps.size()) return std::nullopt;
    const std::uint32_t step = run.steps[pick.slot];
    if (!can_play(StrikeCall{.skill = skill, .step = step})) {
        look::stop_chain(chain_);
        return std::nullopt;
    }
    return step;
}

namespace {

// slot là chỉ số trong các đòn của skill, không phải số bước ghi trong bảng.
struct ChainSlot {
    std::uint32_t skill = 0;
    std::uint32_t slot = 0;
};

[[nodiscard]] std::optional<std::uint32_t> step_of(std::span<const look::Strike> strikes, ChainSlot which) noexcept {
    std::uint32_t seen = 0;
    for (const look::Strike& strike : strikes) {
        if (strike.skill != which.skill) continue;
        if (seen == which.slot) return strike.step;
        ++seen;
    }
    return std::nullopt;
}

void add_ride(std::vector<render::Instance>& out, const render::Drawable* drawable,
    const math::Matrix4& world, std::span<const math::Matrix4> joints) {
    render::Instance instance;
    instance.drawable = drawable;
    instance.world = world;
    instance.joints = joints;
    instance.is_actor = true;
    out.push_back(instance);
}

} // namespace

bool PlayerActor::is_locked(core::Clock::time_point now) const {
    return chain_.do_next || gait_.is_locked(now);
}

bool PlayerActor::can_play(const StrikeCall& call) const {
    const std::optional<std::size_t> index = avatar_.strike_index(call.skill, call.step);
    if (!index) return false;
    const avatar::StrikePlan plan = plan_of(*index);
    return plan.length > 0.0F && plan.rate > 0.0F;
}

[[nodiscard]] bool PlayerActor::play_deferred(core::Clock::time_point now, const Stand& stand) {
    const look::ChainPick next = look::finish_chain(chain_);
    if (!next.plays) return false;
    const ChainSlot which{.skill = chain_.skill, .slot = next.slot};
    const std::optional<std::uint32_t> step = step_of(avatar_.strikes(), which);
    if (!step || !can_play(StrikeCall{.skill = chain_.skill, .step = *step})) return false;
    const avatar::Playing ended{.stance = avatar::Stance::kIdle};
    fire_cues(ended, stand);
    begin_strike(now, StrikeCall{.skill = chain_.skill, .step = *step});
    return true;
}

// Hết clip: lệnh nối đã hoãn thì FreshAnimation tăng lần hai và phát bước đó. Đi thì bỏ phiên
// (Start_Move đổi logic, cờ nối không còn được FreshAnimation của SKILL_SEND ăn). Lệnh phát ngay
// trong cùng khung (stand.strike) giữ phiên mà accept_strike vừa mở.
void PlayerActor::release_chain(core::Clock::time_point now, const Stand& stand) {
    if (stand.is_moving || stand.jump) {
        look::stop_chain(chain_);
        return;
    }
    if (!gait_.strike_finished(now)) return;
    const bool played = chain_.do_next && play_deferred(now, stand);
    if (played || stand.strike) return;
    look::stop_chain(chain_);
}

void PlayerActor::take_cues(std::vector<SkillCue>& out) {
    out.insert(out.end(), std::make_move_iterator(cues_.begin()), std::make_move_iterator(cues_.end()));
    cues_.clear();
}

// Kế hoạch phát của một bước: Start_MagicSend ChangeAction với tốc độ logic (chưa có tốc độ đánh nên 1). Skill kiểu kRandom
// có m_nSendTime thì clip dài hơn thời gian phát được chạy nhanh lên cho vừa (Game.exe 2026 0x1405ee920: rate *= clip ms /
// send ms). BreakTime đầu tiên là mốc OnAnimationCanBreak.
avatar::StrikePlan PlayerActor::plan_of(std::size_t index) const {
    const look::Strike& strike = avatar_.strikes()[index];
    avatar::StrikePlan plan;
    plan.index = index;
    plan.length = avatar_.strike_length(index);
    const float clip_ms = plan.length * 1000.0F;
    const auto send_ms = static_cast<float>(strike.send_ms);
    if (strike.kind == look::ActionKind::kRandom && send_ms > 0.0F && send_ms < clip_ms) plan.rate = clip_ms / send_ms;
    const auto earliest = std::ranges::min_element(strike.break_times);
    if (earliest != strike.break_times.end() && *earliest <= 1.0F) plan.break_at = *earliest;
    return plan;
}

void PlayerActor::begin_strike(core::Clock::time_point now, const StrikeCall& call) {
    const std::optional<std::size_t> index = avatar_.strike_index(call.skill, call.step);
    if (!index) return;
    const look::Strike& strike = avatar_.strikes()[*index];
    const avatar::StrikePlan plan = plan_of(*index);
    gait_.strike(now, plan);
    active_ = Active{.index = *index, .fraction = 0.0F};
    std::println("Đòn: skill {} bước {} là {} ({:.2f} s, tốc độ {:.2f}, {} khối con)", call.skill, call.step, strike.script,
        plan.length, plan.rate, strike.events.size());
}

std::chrono::milliseconds PlayerActor::hit_after(const StrikeCall& call) const {
    const std::optional<std::size_t> index = avatar_.strike_index(call.skill, call.step);
    if (!index) return std::chrono::milliseconds{0};
    const look::Strike& strike = avatar_.strikes()[*index];
    const auto first = std::ranges::find_if(strike.hit_times, [](float part) { return part > 0.0F && part <= 1.0F; });
    if (first == strike.hit_times.end()) return std::chrono::milliseconds{0};
    const avatar::StrikePlan plan = plan_of(*index);
    if (!(plan.rate > 0.0F)) return std::chrono::milliseconds{0};
    const float seconds = (*first * plan.length) / plan.rate;
    return std::chrono::milliseconds{std::lround(seconds * 1000.0F)};
}

void PlayerActor::drop_follow(std::uint32_t token) {
    std::erase_if(followers_, [token](const Follower& follower) { return follower.token == token; });
}

// Hiệu ứng đồ (look::Held::effect) gắn vào điểm 武器特效点 của mẫu vũ khí, đi theo tay cầm mỗi khung
// (CRFObj_Actor::SetRightWeaponEffect của ref: Attach).
void PlayerActor::place_gear(const Stand& drawn) {
    gear_.clear();
    const std::vector<look::Held>& held = avatar_.figure().held;
    for (std::size_t mount = 0; mount < held.size(); ++mount) {
        if (held.at(mount).effect.empty()) continue;
        const std::optional<anim::Transform> pose = avatar_.effect_pose(mount, skinner_.derived());
        if (!pose) continue;
        const WorldPose placed = world_of(*pose, drawn);
        gear_.push_back(GearEffect{.mount = mount, .position = placed.position, .orientation = placed.orientation});
    }
}

// _updateAttachedAnimationEffect: hiệu ứng Attach theo điểm gắn của khối con mỗi khung.
void PlayerActor::place_follows(const Stand& drawn) {
    follows_.clear();
    for (const Follower& follower : followers_) {
        const std::optional<anim::Transform> pose = avatar_.event_pose(follower.strike, follower.event, skinner_.derived());
        if (!pose) continue;
        const WorldPose placed = world_of(*pose, drawn);
        CueFollow follow;
        follow.token = follower.token;
        follow.position = placed.position;
        follow.orientation = placed.orientation;
        follows_.push_back(follow);
    }
}

std::span<const anim::Transform> PlayerActor::ride_bones_now() const noexcept {
    if (!ride_body_) return {};
    return ride_skin_.derived();
}

void PlayerActor::place_ride_fx(const Stand& drawn) {
    ride_fx_.clear();
    if (!riding_) return;
    const std::span<const anim::Transform> bones = ride_bones_now();
    std::uint32_t index = 0;
    for (const RideSpark& spark : ride_sparks_) {
        const RideFx made = ride_fx_at(spark, index, ride_id_, bones, drawn);
        ride_fx_.push_back(made);
        ++index;
    }
}

// _createAnimationEffect, _updateAnimationSound: khối con có mốc trong [phần cũ, phần mới) của clip thì bắn. Hết clip
// thì bắn nốt tới 1. Điểm gắn đổi sang toạ độ thế giới (world_of). Khối con không có điểm gắn thì đứng ở chân.
void PlayerActor::fire_cues(const avatar::Playing& playing, const Stand& drawn) {
    if (!active_) return;
    const float length = avatar_.strike_length(active_->index);
    const bool is_playing = playing.stance == avatar::Stance::kStrike && playing.strike == active_->index;
    float reached = 1.0F;
    if (is_playing && length > 0.0F) reached = std::min(playing.time / length, 1.0F);
    const look::Strike& strike = avatar_.strikes()[active_->index];
    for (std::size_t event = 0; event < strike.events.size(); ++event) {
        const look::StrikeEvent& block = strike.events.at(event);
        if (!look::moment_due(block.time, active_->fraction, reached)) continue;
        SkillCue cue;
        cue.kind = block.kind;
        cue.name = block.name;
        cue.is_attached = block.is_attached;
        cue.props = block.props;
        const std::optional<anim::Transform> pose = avatar_.event_pose(active_->index, event, skinner_.derived());
        const WorldPose placed = world_of(pose.value_or(anim::Transform{}), drawn);
        cue.position = placed.position;
        cue.orientation = placed.orientation;
        // Ribbon của all.skill không có cờ Attach nhưng LogicModel::_updateAnimationRibbon vẫn bám xương mỗi khung.
        const bool is_ribbon = block.kind == look::EventKind::kRibbon;
        const bool is_following = pose && (is_ribbon || (block.is_attached && block.kind == look::EventKind::kAnimEffect));
        if (is_following) {
            cue.token = ++last_token_;
            if (followers_.size() >= kMaxFollowers) followers_.erase(followers_.begin());
            followers_.push_back(Follower{.token = cue.token, .strike = active_->index, .event = event});
        }
        cues_.push_back(std::move(cue));
    }
    for (const float mark : strike.shake_times) {
        if (!look::moment_due(mark, active_->fraction, reached)) continue;
        SkillCue shake;
        shake.kind = look::EventKind::kShake;
        cues_.push_back(std::move(shake));
    }
    active_->fraction = reached;
    if (!is_playing) active_.reset();
}

void PlayerActor::append(std::vector<render::Instance>& out) const {
    for (const render::Drawable* drawable : parts_) {
        render::Instance instance;
        instance.drawable = drawable;
        instance.world = placed_ * seat_;
        instance.joints = skinner_.joints();
        instance.is_actor = true;
        out.push_back(instance);
    }
    for (const HeldMesh& held : held_) {
        if (held.mount >= mounts_.size()) continue;
        render::Instance instance;
        instance.drawable = held.drawable;
        instance.world = placed_ * seat_ * mounts_[held.mount];
        instance.is_actor = true;
        out.push_back(instance);
    }
    std::span<const math::Matrix4> joints;
    if (ride_body_) joints = ride_skin_.joints();
    for (const render::Drawable* drawable : ride_)
        add_ride(out, drawable, placed_, joints);
}

} // namespace game::client
