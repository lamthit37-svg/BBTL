// Người chơi trên màn hình (xem player.hpp).
#include "client/display/player.hpp"

#include "avatar/avatar.hpp"
#include "avatar/gait.hpp"
#include "core/clock.hpp"
#include "core/error.hpp"
#include "io/file.hpp"
#include "look/appearance.hpp"
#include "look/look.hpp"
#include "look/sect.hpp"
#include "math/matrix.hpp"
#include "math/vector.hpp"
#include "render/forward.hpp"

#include <cmath>
#include <cstdint>
#include <cstdio>
#include <expected>
#include <filesystem>
#include <print>
#include <string>
#include <utility>
#include <vector>

namespace game::client {
namespace {

// Hạt giống rand() của người chơi duy nhất: chỉ cần cố định để chạy lại ra cùng dãy động tác nghỉ.
constexpr std::uint32_t kSeed = 7;
// Số định danh của người chơi trong bộ làm mượt hướng.
constexpr std::uint32_t kPlayerId = 1;

[[nodiscard]] std::expected<std::string, std::string> read_table(const std::string& path) {
    const auto text = io::read_text(io::path_from_utf8(path));
    if (!text) return std::unexpected(std::string(io::describe(text.error())));
    return *text;
}

// Bộ mặc định của giới: id mặt, tóc theo bảng thân (id 0 của tóc là một kiểu tóc thật).
[[nodiscard]] core::Result<look::Figure> default_figure(const look::Tables& tables, look::Race race) {
    const look::PlayerBody* body = look::find_body(tables.bodies, race);
    if (body == nullptr) return core::fail(core::ErrorCode::kNotFound, "không có thân của giới này");
    look::Look wanted;
    wanted.face = body->face;
    wanted.hair = body->hair;
    const auto figure = look::resolve(tables, race, wanted);
    if (!figure) return core::fail(core::ErrorCode::kCorrupt, "không giải được ngoại hình");
    return *figure;
}

// Môn phái xem trước dùng mẫu riêng. Không thì khối đã chọn, rồi bộ mặc định của giới.
[[nodiscard]] core::Result<look::Figure> figure_of(const look::Tables& tables, const PlayerDesc& desc) {
    if (desc.sect) {
        const std::string path = (desc.data_root / "Table" / "sect_models.tsv").string();
        const auto text = read_table(path);
        if (!text) return core::fail(core::ErrorCode::kNotFound, "không đọc được bảng người mẫu môn phái");
        const auto figure = look::sect_figure(*text, desc.race, *desc.sect);
        if (!figure) return core::fail(core::ErrorCode::kCorrupt, "không giải được người mẫu môn phái", figure.error());
        return figure->figure;
    }
    if (!desc.look) return default_figure(tables, desc.race);
    const auto figure = look::resolve(tables, desc.race, *desc.look);
    if (!figure) return core::fail(core::ErrorCode::kCorrupt, "không giải được ngoại hình đã chọn");
    return *figure;
}

// Drawable của một bộ phận, hoặc nullptr kèm log khi nơi vẽ không nạp được lưới.
[[nodiscard]] const render::Drawable* part_drawable(const MeshLoader& load_mesh, const look::Part& part) {
    const render::Drawable* drawable = load_mesh(part.mesh);
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

} // namespace

PlayerActor::PlayerActor(avatar::Avatar avatar, std::vector<const render::Drawable*> parts)
    : avatar_(std::move(avatar)),
      gait_(kSeed, avatar::kIdleInterval),
      lengths_(avatar_.lengths()),
      parts_(std::move(parts)) {}

core::Result<PlayerActor> PlayerActor::create(const PlayerDesc& desc, const MeshLoader& load_mesh) {
    const std::string folder = io::utf8_of(desc.data_root / "Table");
    const auto tables = look::load_tables(folder, read_table);
    if (!tables) {
        return core::fail(core::ErrorCode::kNotFound, "không nạp được bảng ngoại hình", "{}", tables.error());
    }
    const auto figure = figure_of(*tables, desc);
    if (!figure) return std::unexpected(figure.error());
    auto avatar = avatar::Avatar::load(*figure, desc.data_root);
    if (!avatar) return std::unexpected(avatar.error());
    std::vector<const render::Drawable*> parts = load_parts(*figure, load_mesh);
    return PlayerActor(std::move(*avatar), std::move(parts));
}

core::Status PlayerActor::update(core::Clock::time_point now, const Stand& stand) {
    const avatar::Playing playing = gait_.update(now, stand.is_moving, lengths_);
    const core::Status posed = skinner_.update(avatar_, playing);
    if (!posed) return posed;
    Stand drawn = stand;
    drawn.facing = turning_.face(kPlayerId, stand.facing, now);
    turning_.drop_unseen();
    placed_ = placement(drawn);
    return core::ok();
}

void PlayerActor::append(std::vector<render::Instance>& out) const {
    for (const render::Drawable* drawable : parts_) {
        render::Instance instance;
        instance.drawable = drawable;
        instance.world = placed_;
        instance.joints = skinner_.joints();
        instance.is_actor = true;
        out.push_back(instance);
    }
}

} // namespace game::client
