/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/zone/trace.cpp
 *  PHÂN HỆ   : Server / Zone / Trace
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt Trace: định dạng một dòng kiểm cho mỗi việc của người chơi và in
 *    ra stderr; trình giám sát gom về log/cluster_err.txt.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "zone/trace.hpp"

#include "ipc/relay.hpp"
#include "play/stage.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <format>
#include <print>
#include <string>
#include <string_view>
#include <utility>

namespace game::zone {

namespace {

constexpr std::string_view kHead = "tick={} việc={} tk={} nv={}";
constexpr std::string_view kWhere = "scene={} x={} z={}";
constexpr std::string_view kTail = "kq={} gt={} ten=\"{}\"";
constexpr std::string_view kHome = " về={},{}";

// Tên nhân vật vào dòng nguyên văn, trừ dấu nháy và ký tự điều khiển: không ai giả được một dòng
// khác bằng cái tên.
[[nodiscard]] bool is_unsafe(char letter) noexcept {
    const auto code = static_cast<unsigned char>(letter);
    return letter == '"' || code < 0x20;
}

[[nodiscard]] std::string clean(std::string name) {
    std::ranges::replace_if(name, is_unsafe, '?');
    return name;
}

[[nodiscard]] std::string_view name_of(play::Act act) noexcept {
    switch (act) {
    case play::Act::kTalk: return "nói";
    case play::Act::kChoose: return "chọn";
    case play::Act::kAccept: return "nhận";
    case play::Act::kTurnIn: return "trả";
    case play::Act::kAbandon: return "bỏ";
    case play::Act::kCast: return "chiêu";
    case play::Act::kStrike: return "đánh";
    case play::Act::kStruck: return "trúng";
    case play::Act::kSlay: return "hạ";
    case play::Act::kDie: return "chết";
    case play::Act::kRespawn: return "hồi";
    case play::Act::kPick: return "nhặt";
    }
    return "?";
}

} // namespace

void Trace::emit(const Row& row, std::string_view extra) const {
    const Who& who = *row.who;
    const TraceSpot& at = row.spot;
    const long x_cm = std::lround(at.x_cm);
    const long z_cm = std::lround(at.z_cm);
    const std::string head = std::format(kHead, row.tick, row.act, who.account, who.character);
    const std::string place = std::format(kWhere, at.scene, x_cm, z_cm);
    const std::string tail = std::format(kTail, row.result, row.value, who.name);
    std::println(stderr, "zone: kiểm {} {} {}{}", head, place, tail, extra);
}

void Trace::enter(std::uint64_t session, const ipc::Attach& arrival, const TraceSpot& spot,
    std::uint32_t tick) {
    if (!on_) return;
    Who made{.account = arrival.account, .character = arrival.character};
    made.name = clean(arrival.name);
    const Who& who = who_.insert_or_assign(session, std::move(made)).first->second;
    const Row row{.tick = tick, .act = "vào", .who = &who, .spot = spot, .result = "ok"};
    emit(row, {});
}

void Trace::leave(std::uint64_t session, const TraceSpot& spot, std::uint32_t tick) {
    if (!on_) return;
    const auto found = who_.find(session);
    if (found == who_.end()) return;
    const Who& who = found->second;
    const Row row{.tick = tick, .act = "rời", .who = &who, .spot = spot, .result = "ok"};
    emit(row, {});
    who_.erase(found);
}

void Trace::walk(std::uint64_t session, const TraceSpot& spot, std::uint32_t tick) {
    if (!on_) return;
    const auto found = who_.find(session);
    if (found == who_.end()) return;
    Who& who = found->second;
    const bool is_due = !who.walked || tick - who.walked_at >= hz_;
    if (!is_due) return;
    who.walked = true;
    who.walked_at = tick;
    const Row row{.tick = tick, .act = "đi", .who = &who, .spot = spot, .result = "ok"};
    emit(row, {});
}

void Trace::pull(std::uint64_t session, const TraceSpot& refused, const TraceSpot& home,
    std::uint32_t tick) {
    if (!on_) return;
    const auto found = who_.find(session);
    if (found == who_.end()) return;
    const Who& who = found->second;
    const long home_x = std::lround(home.x_cm);
    const long home_z = std::lround(home.z_cm);
    const std::string extra = std::format(kHome, home_x, home_z);
    const Row row{.tick = tick, .act = "kéo", .who = &who, .spot = refused, .result = "ok"};
    emit(row, extra);
}

void Trace::act(const play::Note& note, const TraceSpot& spot, std::uint32_t tick) {
    if (!on_) return;
    const auto found = who_.find(note.session);
    const Who none{};
    const Who& who = found == who_.end() ? none : found->second;
    Row row{.tick = tick, .act = name_of(note.act), .who = &who, .spot = spot};
    row.result = note.code != 0 ? std::to_string(note.code) : "ok";
    row.value = note.value;
    emit(row, {});
}

} // namespace game::zone
