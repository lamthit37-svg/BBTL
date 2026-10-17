/*==============================================================================
 *  THIENLONG  |  BENCH
 *------------------------------------------------------------------------------
 *  TỆP       : Test/bench/pos_fan_bench.cpp
 *  PHÂN HỆ   : Zone / Position Fan Bench
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đo trong tiến trình: số khung application, số vị trí và byte replication
 *    khi nhiều thực thể cùng ô đi ở nhịp gần, và khi rải gần/xa.
 *  - Không đo gói TCP hay byte trên dây. Không suy ra sức chứa 10.000 phiên.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "ipc/relay.hpp"
#include "protocol/messages.hpp"
#include "protocol/wire.hpp"
#include "zone/outbox.hpp"
#include "zone/scene.hpp"

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <iostream>
#include <span>
#include <string>
#include <vector>

namespace {

using game::zone::Outbox;
using game::zone::Scene;

constexpr float kCell = 1000.0F;
constexpr int kWaves = 8;

struct Totals {
    std::size_t frames = 0;
    std::size_t pos_frames = 0;
    std::size_t entries = 0;
    std::size_t bytes = 0;
    std::size_t watch_frames = 0;
    std::size_t watch_entries = 0;
    std::size_t watch_bytes = 0;
};

[[nodiscard]] game::ipc::Attach arrival(std::uint64_t character, float x_cm, float z_cm) {
    game::ipc::Attach attach;
    attach.character = character;
    attach.account = character + 1000;
    attach.scene = 1;
    attach.x_cm = x_cm;
    attach.z_cm = z_cm;
    attach.name = "nv";
    attach.level = 1;
    return attach;
}

[[nodiscard]] Scene make_scene(std::size_t players) {
    Scene::Config config;
    config.id = 1;
    config.grid.cell_cm = kCell;
    config.grid.radius = 2;
    config.player_max = players;
    return Scene{config};
}

void tally_letter(const game::zone::Letter& letter, std::uint64_t watch, Totals& totals) {
    if (letter.kind != game::ipc::Relay::kDown) return;
    ++totals.frames;
    totals.bytes += letter.body.size();
    const bool is_watch = letter.session == watch;
    if (is_watch) {
        ++totals.watch_frames;
        totals.watch_bytes += letter.body.size();
    }
    const game::protocol::FrameResult peeked = game::protocol::peek_frame(letter.body, letter.body.size());
    if (!peeked || !peeked->has_value()) return;
    const game::protocol::Frame frame = **peeked;
    const std::span<const std::byte> body = std::span{letter.body}.subspan(game::protocol::kHeaderBytes);
    const game::protocol::GameServerResult decoded = game::protocol::decode_game_server(frame, body);
    if (!decoded) return;
    const auto* pos = std::get_if<game::protocol::EntityPos>(&*decoded);
    const auto* batch = std::get_if<game::protocol::EntityPosBatch>(&*decoded);
    std::size_t count = 0;
    if (pos != nullptr) count = 1;
    if (batch != nullptr) count = batch->places.size();
    if (count == 0) return;
    ++totals.pos_frames;
    totals.entries += count;
    if (!is_watch) return;
    totals.watch_entries += count;
}

void consume(Outbox& out, std::uint64_t watch, Totals& totals) {
    const std::vector<game::zone::Letter>& letters = out.letters();
    for (const game::zone::Letter& letter : letters) tally_letter(letter, watch, totals);
    out.clear();
}

[[nodiscard]] std::uint64_t percentile(std::vector<std::uint64_t> samples, int percent) {
    if (samples.empty()) return 0;
    std::ranges::sort(samples);
    const std::size_t index = (samples.size() - 1) * static_cast<std::size_t>(percent) / 100;
    return samples[index];
}

void print_totals(const char* name, const Totals& totals, std::uint64_t pack_us,
    const std::vector<std::uint64_t>& ticks) {
    std::cout << name << " frames=" << totals.frames << " pos_frames=" << totals.pos_frames
              << " entries=" << totals.entries << " bytes=" << totals.bytes
              << " watch_frames=" << totals.watch_frames << " watch_entries=" << totals.watch_entries
              << " watch_bytes=" << totals.watch_bytes << " pack_us=" << pack_us
              << " tick_us_p50=" << percentile(ticks, 50) << " p95=" << percentile(ticks, 95)
              << " p99=" << percentile(ticks, 99) << '\n';
}

void crowd() {
    constexpr std::size_t kPlayers = 500;
    constexpr std::uint64_t kWatch = 1;
    Scene scene = make_scene(kPlayers);
    Outbox out;
    for (std::uint64_t id = 1; id <= kPlayers; ++id) {
        const float x_cm = 100.0F + static_cast<float>(id % 20);
        static_cast<void>(scene.attach(id, arrival(id, x_cm, 100.0F), out));
    }
    out.clear();
    Totals totals;
    std::vector<std::uint64_t> ticks;
    ticks.reserve(static_cast<std::size_t>(kWaves));
    const auto began = std::chrono::steady_clock::now();
    for (int wave = 0; wave < kWaves; ++wave) {
        const auto wave_began = std::chrono::steady_clock::now();
        for (std::uint64_t id = 2; id <= kPlayers; ++id) {
            const float x_cm = 150.0F + static_cast<float>(wave);
            scene.moved(id, game::ipc::Moved{.x_cm = x_cm, .z_cm = 100.0F}, out);
        }
        consume(out, kWatch, totals);
        scene.advance(out);
        consume(out, kWatch, totals);
        const auto wave_us = std::chrono::duration_cast<std::chrono::microseconds>(
            std::chrono::steady_clock::now() - wave_began);
        ticks.push_back(static_cast<std::uint64_t>(wave_us.count()));
    }
    const auto pack_us = std::chrono::duration_cast<std::chrono::microseconds>(
        std::chrono::steady_clock::now() - began);
    print_totals("crowd", totals, static_cast<std::uint64_t>(pack_us.count()), ticks);
}

void spread() {
    constexpr std::uint64_t kWatch = 1;
    constexpr int kNear = 20;
    constexpr int kFar = 20;
    const std::size_t players = 1 + static_cast<std::size_t>(kNear + kFar);
    Scene scene = make_scene(players);
    Outbox out;
    static_cast<void>(scene.attach(kWatch, arrival(kWatch, 100.0F, 100.0F), out));
    for (int index = 0; index < kNear; ++index) {
        const std::uint64_t id = static_cast<std::uint64_t>(index + 2);
        static_cast<void>(scene.attach(id, arrival(id, 200.0F, 100.0F), out));
    }
    for (int index = 0; index < kFar; ++index) {
        const std::uint64_t id = static_cast<std::uint64_t>(index + 2 + kNear);
        static_cast<void>(scene.attach(id, arrival(id, 2500.0F, 100.0F), out));
    }
    out.clear();
    Totals totals;
    std::vector<std::uint64_t> ticks;
    const auto began = std::chrono::steady_clock::now();
    for (int wave = 0; wave < kWaves; ++wave) {
        const auto wave_began = std::chrono::steady_clock::now();
        for (int index = 0; index < kNear; ++index) {
            const std::uint64_t id = static_cast<std::uint64_t>(index + 2);
            const float x_cm = 210.0F + static_cast<float>(wave);
            scene.moved(id, game::ipc::Moved{.x_cm = x_cm, .z_cm = 100.0F}, out);
        }
        for (int index = 0; index < kFar; ++index) {
            const std::uint64_t id = static_cast<std::uint64_t>(index + 2 + kNear);
            const float x_cm = 2510.0F + static_cast<float>(wave);
            scene.moved(id, game::ipc::Moved{.x_cm = x_cm, .z_cm = 100.0F}, out);
        }
        consume(out, kWatch, totals);
        scene.advance(out);
        consume(out, kWatch, totals);
        const auto wave_us = std::chrono::duration_cast<std::chrono::microseconds>(
            std::chrono::steady_clock::now() - wave_began);
        ticks.push_back(static_cast<std::uint64_t>(wave_us.count()));
    }
    const auto pack_us = std::chrono::duration_cast<std::chrono::microseconds>(
        std::chrono::steady_clock::now() - began);
    print_totals("spread", totals, static_cast<std::uint64_t>(pack_us.count()), ticks);
}

} // namespace

int main() {
    crowd();
    spread();
    return 0;
}
