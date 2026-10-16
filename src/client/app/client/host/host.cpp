/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/host/host.cpp
 *  PHÂN HỆ   : Client / Host
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt client/host/host.hpp. Cùng việc mà viewer_win32.cpp làm cho cửa
 *    sổ PC (cầu nối đăng nhập trực tuyến, nhạc cảnh, âm thanh đòn), viết một
 *    lần cho Android và iOS, không dùng API hệ điều hành.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/host/host.hpp"
#include "client/host/play_sound.hpp"

#include "audio/engine.hpp"
#include "client/cast/cast.hpp"
#include "client/cast/note.hpp"
#include "client/display/display.hpp"
#include "client/online/bridge.hpp"
#include "client/session/gates.hpp"
#include "client/world/world.hpp"
#include "core/ground_point.hpp"
#include "io/file.hpp"
#include "ui/panel/online.hpp"

#include <array>
#include <cstdint>
#include <filesystem>
#include <format>
#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <variant>
#include <vector>

namespace game::client::host {
namespace {

// Thời gian chuyển nhạc khi đổi cảnh, giây: nhạc cũ nhỏ dần trong lúc nhạc mới lên (cùng viewer PC).
constexpr float kSceneMusicFade = 1.0F;

[[nodiscard]] Note info(std::string text) {
    return Note{.is_problem = false, .text = std::move(text)};
}

[[nodiscard]] Note problem(std::string text) {
    return Note{.is_problem = true, .text = std::move(text)};
}

} // namespace

GateBookLoad load_gate_book(const std::filesystem::path& data_root) {
    GateBookLoad loaded;
    const std::filesystem::path file = data_root / "Table" / std::filesystem::path{std::string{session::kGateTable}};
    const io::TextResult text = io::read_text(file);
    if (!text) return loaded;
    session::GateBookResult book = session::read_gate_book(*text);
    if (!book) {
        loaded.notes.push_back(problem(std::format("Bảng cổng máy chủ {}: {}", io::utf8_of(file), book.error())));
        return loaded;
    }
    loaded.notes.push_back(info(std::format("Bảng cổng máy chủ: {} máy chủ trực tuyến", book->gates.size())));
    loaded.book = std::move(*book);
    return loaded;
}

Online::Online(session::GateBook book) : bridge_(std::move(book)) {}

std::vector<ui::panel::ServerName> Online::servers() const {
    return bridge_.servers();
}

void Online::abandon(Display& display) {
    ui::panel::OnlineReply lost;
    lost.kind = ui::panel::OnlineReply::Kind::kLost;
    lost.fault = ui::panel::OnlineFault::kOther;
    display.post_online(lost);
    std::array<ui::panel::OnlineAsk, 1> drop{ui::panel::OnlineAsk{.work = ui::panel::OnlineWork::kDrop}};
    bridge_.serve(drop);
    seen_.clear();
    spot_.reset();
}

void Online::on_display_made(Display& display, bool is_playing) {
    if (!is_playing) {
        // Chuỗi đăng nhập của Display mới đứng ở bảng tài khoản: phiên đã đăng nhập (nếu có) không còn ai giữ.
        std::array<ui::panel::OnlineAsk, 1> drop{ui::panel::OnlineAsk{.work = ui::panel::OnlineWork::kDrop}};
        bridge_.serve(drop);
        seen_.clear();
        spot_.reset();
        return;
    }
    const std::optional<std::uint16_t> scene = seen_.scene();
    if (!scene) return;
    // Cùng thứ tự máy chủ gửi: vào cảnh (xoá thực thể cũ của nơi vẽ, đặt chỗ đứng) rồi từng thực thể.
    std::vector<cast::Note> replay;
    replay.reserve(seen_.actors().size() + 2);
    const core::GroundPoint at = spot_.value_or(core::GroundPoint{});
    replay.emplace_back(cast::Arrive{.scene = *scene, .x = at.x, .z = at.z, .facing = 0.0F, .self_id = seen_.self_id()});
    for (const cast::Actor& actor : seen_.actors()) {
        replay.emplace_back(cast::Spawn{.id = actor.id,
            .kind = actor.kind,
            .template_id = actor.template_id,
            .name = actor.name,
            .level = actor.level,
            .x = actor.x,
            .z = actor.z,
            .facing = actor.facing,
            .speed = actor.speed,
            .hp_percent = actor.hp_percent,
            .gender = actor.gender,
            .face = actor.face,
            .hair = actor.hair,
            .school = actor.school,
            .pose = actor.pose});
        if (actor.flags != 0) replay.emplace_back(cast::Flagged{.id = actor.id, .flags = actor.flags});
    }
    if (const std::optional<std::uint8_t> hp = seen_.self_hp()) {
        replay.emplace_back(cast::Hurt{.id = seen_.self_id(), .hp_percent = *hp});
    }
    display.post_world(replay);
}

void Online::follow(Display& display, world::World& playing, const std::filesystem::path& scenes,
    const cast::Arrive& arrive, Notes& notes) {
    const std::shared_ptr<const world::ShownScene> current = world::current_scene(playing);
    if (current != nullptr && current->id == arrive.scene) return;
    const world::EnterResult entered = world::enter(playing, arrive.scene, scenes);
    if (!entered) {
        notes.push_back(problem(std::format("Đổi cảnh {}: {}", arrive.scene, world::describe(entered.error()))));
        abandon(display);
        return;
    }
    display.play(world::current_scene(playing), EntryPoint{.scene = arrive.scene, .x = arrive.x, .z = arrive.z});
}

void Online::on_frame(Display& display, world::World* playing, const std::filesystem::path& scenes, float seconds,
    Notes& notes) {
    std::vector<ui::panel::OnlineAsk> asks = display.take_online_asks();
    bridge_.serve(asks);
    for (const ui::panel::OnlineReply& reply : bridge_.collect()) display.post_online(reply);
    const std::vector<cast::Note> arrived = bridge_.take_notes();
    for (const cast::Note& note : arrived) {
        seen_.apply(note);
        if (const auto* arrive = std::get_if<cast::Arrive>(&note)) {
            spot_ = core::GroundPoint{.x = arrive->x, .z = arrive->z};
            if (playing != nullptr) follow(display, *playing, scenes, *arrive, notes);
        }
        if (const auto* pulled = std::get_if<cast::Pulled>(&note)) spot_ = core::GroundPoint{.x = pulled->x, .z = pulled->z};
    }
    display.post_world(arrived);
    display.post_talk(bridge_.take_heard());
    bridge_.speak(display.take_says());
    seen_.advance(seconds);
    if (const std::optional<core::GroundPoint> spot = display.reported_spot()) {
        bridge_.report(spot->x, spot->z);
        spot_ = spot;
    }
}

namespace {

void play_scene_music(audio::Engine& speaker, const world::ShownScene& scene, Notes& notes) {
    if (scene.music <= 0) return;
    const std::string id = std::to_string(scene.music);
    const core::Status played = speaker.play_music(id, kSceneMusicFade);
    if (played) {
        notes.push_back(info(std::format("Âm thanh: nhạc nền cảnh {} là id {}", scene.id, id)));
        return;
    }
    notes.push_back(problem(std::format("Âm thanh: nhạc nền cảnh {} (id {}): {}", scene.id, id, played.error())));
}

void play_due_sounds(audio::Engine& speaker, const Display::SoundBatch& batch, Notes& notes) {
    play_heard(speaker, batch, [&notes](const std::string& path, const core::Error& error) {
        notes.push_back(problem(std::format("Âm thanh: {}: {}", path, error)));
    });
}

} // namespace

void Soundscape::on_frame(audio::Engine* speaker, Display& display, const world::ShownScene* scene, Notes& notes) {
    // Luôn rút hàng đợi: không rút thì âm thanh đòn dồn lại tới lúc có loa.
    const Display::SoundBatch due = display.take_sounds();
    if (speaker == nullptr || !speaker->device_is_open()) return;
    const bool is_new_scene = scene != nullptr && scene->id != shown_id_;
    if (is_new_scene) {
        shown_id_ = scene->id;
        play_scene_music(*speaker, *scene, notes);
    }
    play_due_sounds(*speaker, due, notes);
}

} // namespace game::client::host
