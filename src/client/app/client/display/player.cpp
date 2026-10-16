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
#include "core/clock.hpp"
#include "core/error.hpp"
#include "io/file.hpp"
#include "look/appearance.hpp"
#include "look/look.hpp"
#include "look/sect.hpp"
#include "look/skill.hpp"
#include "math/matrix.hpp"
#include "math/vector.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"
#include "render/forward.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <iterator>
#include <expected>
#include <filesystem>
#include <future>
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

// Người mẫu môn phái: bảng sect_models, không vũ khí, fidget theo dòng mẫu.
[[nodiscard]] core::Result<Built> sect_figure(const PlayerDesc& desc, std::uint8_t sect) {
    const std::string path = (desc.data_root / "Table" / "sect_models.tsv").string();
    const auto text = read_table(path);
    if (!text) return core::fail(core::ErrorCode::kNotFound, "không đọc được bảng người mẫu môn phái");
    auto figure = look::sect_figure(*text, desc.race, sect);
    if (!figure) return core::fail(core::ErrorCode::kCorrupt, "không giải được người mẫu môn phái", figure.error());
    return Built{.figure = std::move(figure->figure), .weapon = look::Weapon::kNone, .fidget = figure->has_fidget, .demo = true};
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

// Một lưới của mẫu. Không nạp được thì ghi log và bỏ; mẫu vẫn giữ các lưới đã nạp.
void add_held_mesh(std::vector<HeldMesh>& drawn, std::size_t mount, const std::string& mesh, const MeshLoader& load_mesh) {
    const render::Drawable* drawable = load_mesh(mesh);
    if (drawable == nullptr) {
        std::println(stderr, "Người chơi: bỏ lưới vũ khí {}", mesh);
        return;
    }
    drawn.push_back(HeldMesh{.mount = mount, .drawable = drawable});
}

void load_mount(std::vector<HeldMesh>& drawn, std::size_t mount, const look::Held& held, const MeshLoader& load_mesh) {
    for (const std::string& mesh : held.meshes) add_held_mesh(drawn, mount, mesh, load_mesh);
}

[[nodiscard]] std::vector<HeldMesh> load_held(const look::Figure& figure, const MeshLoader& load_mesh) {
    std::vector<HeldMesh> drawn;
    for (std::size_t mount = 0; mount < figure.held.size(); ++mount) {
        load_mount(drawn, mount, figure.held[mount], load_mesh);
    }
    return drawn;
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
    return WorldPose{.position = ogre::Vec3{.x = drawn.foot.x() + around.x, .y = drawn.foot.y() + around.y,
                         .z = drawn.foot.z() + around.z},
        .orientation = ogre::quat_multiply(turn, pose.orientation)};
}

} // namespace

PlayerActor::PlayerActor(avatar::Avatar avatar, std::vector<const render::Drawable*> parts,
    std::vector<HeldMesh> held, bool fidget, bool demo)
    : avatar_(std::move(avatar)),
      gait_(kSeed, avatar::kIdleInterval),
      lengths_(avatar_.lengths()),
      parts_(std::move(parts)),
      held_(std::move(held)),
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
    const auto built = figure_of(tables->look, desc);
    if (!built) return std::unexpected(built.error());
    const std::vector<look::Strike> strikes = strikes_for(tables->skills, desc, built->weapon);
    auto avatar = avatar::Avatar::load(built->figure, desc.data_root, strikes, tables->look.weapons.locators);
    if (!avatar) return std::unexpected(avatar.error());
    std::vector<const render::Drawable*> parts = load_parts(built->figure, load_mesh);
    std::vector<HeldMesh> held = load_held(built->figure, load_mesh);
    return PlayerActor(std::move(*avatar), std::move(parts), std::move(held), built->fidget, built->demo);
}

core::Status PlayerActor::update(core::Clock::time_point now, const Stand& stand) {
    if (cue_demo_) {
        gait_.cue(avatar::Stance::kIdleAlt);
        cue_demo_ = false;
    }
    if (stand.jump) gait_.jump(now, *stand.jump, lengths_);
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
        follows_.push_back(CueFollow{.token = follower.token, .position = placed.position, .orientation = placed.orientation});
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
        instance.world = placed_;
        instance.joints = skinner_.joints();
        instance.is_actor = true;
        out.push_back(instance);
    }
    for (const HeldMesh& held : held_) {
        if (held.mount >= mounts_.size()) continue;
        render::Instance instance;
        instance.drawable = held.drawable;
        instance.world = placed_ * mounts_[held.mount];
        instance.is_actor = true;
        out.push_back(instance);
    }
}

} // namespace game::client
