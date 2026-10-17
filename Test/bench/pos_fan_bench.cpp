/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/bench/pos_fan_bench.cpp
 *  PHÂN HỆ   : Zone / Position Fan Bench
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đo trong tiến trình thời gian scene.advance khi nhiều thực thể cùng ô đi,
 *    và khi rải gần/xa. Lệnh: pos_fan_bench <hz> <giây mô phỏng>.
 *  - Một giây đầu bỏ qua. Không đo TCP, AEAD, chiến đấu, hay sức chứa.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "ipc/relay.hpp"
#include "protocol/messages.hpp"
#include "protocol/wire.hpp"
#include "zone/outbox.hpp"
#include "zone/rate.hpp"
#include "zone/scene.hpp"

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <span>
#include <string>
#include <vector>

namespace {

using game::zone::Outbox;
using game::zone::Scene;

constexpr float kCell = 1000.0F;
constexpr std::uint64_t kWatch = 1;

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

[[nodiscard]] Scene make_scene(std::size_t players, std::int64_t hz) {
    Scene::Config config;
    config.id = 1;
    config.grid.cell_cm = kCell;
    config.grid.radius = 2;
    config.player_max = players;
    config.hz = hz;
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

void tally_ready(const std::vector<game::zone::Letter>& letters, std::uint64_t watch,
    Totals& totals) {
    for (const game::zone::Letter& letter : letters)
        tally_letter(letter, watch, totals);
}

struct MoveJob {
    bool spread = false;
    std::size_t players = 0;
    int near = 0;
    int far = 0;
    std::int64_t hz = 20;
};

struct StepUs {
    std::uint64_t move = 0;
    std::uint64_t advance = 0;
    std::uint64_t flush = 0;
    std::uint64_t step = 0;
};

struct Samples {
    std::vector<std::uint64_t> move;
    std::vector<std::uint64_t> advance;
    std::vector<std::uint64_t> flush;
    std::vector<std::uint64_t> step;
};

[[nodiscard]] std::uint64_t us_since(std::chrono::steady_clock::time_point began) {
    const auto delta = std::chrono::steady_clock::now() - began;
    const auto us = std::chrono::duration_cast<std::chrono::microseconds>(delta);
    return static_cast<std::uint64_t>(us.count());
}

[[nodiscard]] std::uint64_t rank_of(const std::vector<std::uint64_t>& sorted, int percent) {
    if (sorted.empty()) return 0;
    const std::size_t index = (sorted.size() - 1) * static_cast<std::size_t>(percent) / 100;
    return sorted[index];
}

void attach_at(Scene& scene, std::uint64_t id, float x_cm, Outbox& out) {
    static_cast<void>(scene.attach(id, arrival(id, x_cm, 100.0F), out));
}

void attach_crowd_one(Scene& scene, std::uint64_t id, Outbox& out) {
    const float x_cm = 100.0F + static_cast<float>(id % 20U);
    attach_at(scene, id, x_cm, out);
}

void move_id(Scene& scene, std::uint64_t id, float x_cm, Outbox& out) {
    scene.moved(id, game::ipc::Moved{.x_cm = x_cm, .z_cm = 100.0F}, out);
}

void move_crowd_one(Scene& scene, std::uint64_t id, int wave, Outbox& out) {
    const float x_cm = 150.0F + static_cast<float>(wave);
    move_id(scene, id, x_cm, out);
}

void move_near_one(Scene& scene, int index, int wave, Outbox& out) {
    const std::uint64_t id = static_cast<std::uint64_t>(index + 2);
    const float x_cm = 210.0F + static_cast<float>(wave);
    move_id(scene, id, x_cm, out);
}

void move_far_one(Scene& scene, int index, int near, int wave, Outbox& out) {
    const std::uint64_t id = static_cast<std::uint64_t>(index + 2 + near);
    const float x_cm = 2510.0F + static_cast<float>(wave);
    move_id(scene, id, x_cm, out);
}

void move_crowd(Scene& scene, int wave, const MoveJob& job, Outbox& out) {
    for (std::uint64_t id = 2; id <= job.players; ++id)
        move_crowd_one(scene, id, wave, out);
}

void move_spread(Scene& scene, int wave, const MoveJob& job, Outbox& out) {
    for (int index = 0; index < job.near; ++index)
        move_near_one(scene, index, wave, out);
    for (int index = 0; index < job.far; ++index)
        move_far_one(scene, index, job.near, wave, out);
}

// Client gửi Move mỗi 50 ms. Cả ba nhịp đều nhận 20 bước đi mỗi giây mô phỏng.
[[nodiscard]] bool move_due(int wave, std::int64_t hz) noexcept {
    if (hz == 40) return wave % 2 == 0;
    if (hz == 30) return wave % 3 != 2;
    return true;
}

void apply_moves(Scene& scene, int wave, const MoveJob& job, Outbox& out) {
    if (!move_due(wave, job.hz)) return;
    if (job.spread) {
        move_spread(scene, wave, job, out);
        return;
    }
    move_crowd(scene, wave, job, out);
}

[[nodiscard]] StepUs step_once(Scene& scene, Outbox& out, int wave, const MoveJob& job,
    Totals& totals) {
    const auto move_began = std::chrono::steady_clock::now();
    apply_moves(scene, wave, job, out);
    const std::uint64_t move_us = us_since(move_began);
    const auto advance_began = std::chrono::steady_clock::now();
    scene.advance(out);
    const std::uint64_t advance_us = us_since(advance_began);
    // letters() ghép các vị trí đã xếp thành khung. Giải mã sau đó chỉ để đếm, không tính vào bước.
    const auto flush_began = std::chrono::steady_clock::now();
    const std::vector<game::zone::Letter>& letters = out.letters();
    const std::uint64_t flush_us = us_since(flush_began);
    tally_ready(letters, kWatch, totals);
    out.clear();
    StepUs step;
    step.move = move_us;
    step.advance = advance_us;
    step.flush = flush_us;
    step.step = move_us + advance_us + flush_us;
    return step;
}

void remember(Samples& samples, StepUs step) {
    samples.move.push_back(step.move);
    samples.advance.push_back(step.advance);
    samples.flush.push_back(step.flush);
    samples.step.push_back(step.step);
}

void measure(Scene& scene, Outbox& out, int begin, int count, const MoveJob& job, Totals& totals,
    Samples& samples) {
    for (int wave = 0; wave < count; ++wave) {
        const StepUs step = step_once(scene, out, begin + wave, job, totals);
        remember(samples, step);
    }
}

void warmup(Scene& scene, Outbox& out, int count, const MoveJob& job) {
    Totals discard;
    for (int wave = 0; wave < count; ++wave)
        static_cast<void>(step_once(scene, out, wave, job, discard));
}

void print_rank(const char* name, const std::vector<std::uint64_t>& sorted) {
    const std::uint64_t worst = sorted.empty() ? 0 : sorted.back();
    std::cout << name << "_p50=" << rank_of(sorted, 50) << " p95=" << rank_of(sorted, 95)
              << " p99=" << rank_of(sorted, 99) << " max=" << worst;
}

void print_case(const char* name, std::int64_t hz, int seconds, const Totals& totals,
    Samples samples) {
    std::ranges::sort(samples.move);
    std::ranges::sort(samples.advance);
    std::ranges::sort(samples.flush);
    std::ranges::sort(samples.step);
    const std::uint64_t budget = static_cast<std::uint64_t>(1'000'000 / hz);
    const std::uint64_t limit = budget * 70ULL / 100ULL;
    std::cout << name << " hz=" << hz << " sim_s=" << seconds << " ticks=" << samples.step.size()
              << " frames=" << totals.frames << " entries=" << totals.entries
              << " app_bytes=" << totals.bytes << " watch_entries=" << totals.watch_entries
              << " watch_bytes=" << totals.watch_bytes << " budget70_us=" << limit << " ";
    print_rank("step_us", samples.step);
    std::cout << " ";
    print_rank("move_us", samples.move);
    std::cout << " ";
    print_rank("advance_us", samples.advance);
    std::cout << " ";
    print_rank("flush_us", samples.flush);
    std::cout << '\n';
}

void run_case(const char* name, std::int64_t hz, int seconds, Scene& scene, const MoveJob& job) {
    Outbox out;
    // Một giây mô phỏng để đường nạp ổn, không đưa vào phân vị.
    warmup(scene, out, static_cast<int>(hz), job);
    Totals totals;
    Samples samples;
    const int count = seconds * static_cast<int>(hz);
    const auto slots = static_cast<std::size_t>(count);
    samples.move.reserve(slots);
    samples.advance.reserve(slots);
    samples.flush.reserve(slots);
    samples.step.reserve(slots);
    measure(scene, out, static_cast<int>(hz), count, job, totals, samples);
    print_case(name, hz, seconds, totals, std::move(samples));
}

void crowd(std::int64_t hz, int seconds) {
    constexpr std::size_t kPlayers = 500;
    Scene scene = make_scene(kPlayers, hz);
    Outbox out;
    for (std::uint64_t id = 1; id <= kPlayers; ++id)
        attach_crowd_one(scene, id, out);
    out.clear();
    MoveJob job;
    job.players = kPlayers;
    job.hz = hz;
    run_case("crowd", hz, seconds, scene, job);
}

void attach_near(Scene& scene, int index, Outbox& out) {
    const std::uint64_t id = static_cast<std::uint64_t>(index + 2);
    attach_at(scene, id, 200.0F, out);
}

void attach_far(Scene& scene, int index, int near, Outbox& out) {
    const std::uint64_t id = static_cast<std::uint64_t>(index + 2 + near);
    attach_at(scene, id, 2500.0F, out);
}

void spread(std::int64_t hz, int seconds) {
    constexpr int kNear = 20;
    constexpr int kFar = 20;
    const std::size_t players = 1 + static_cast<std::size_t>(kNear + kFar);
    Scene scene = make_scene(players, hz);
    Outbox out;
    attach_at(scene, kWatch, 100.0F, out);
    for (int index = 0; index < kNear; ++index)
        attach_near(scene, index, out);
    for (int index = 0; index < kFar; ++index)
        attach_far(scene, index, kNear, out);
    out.clear();
    MoveJob job;
    job.spread = true;
    job.players = players;
    job.near = kNear;
    job.far = kFar;
    job.hz = hz;
    run_case("spread", hz, seconds, scene, job);
}

[[nodiscard]] bool parse_args(int argc, char** argv, std::int64_t& hz, int& seconds) {
    hz = 20;
    seconds = 20;
    if (argc >= 2) hz = std::strtoll(argv[1], nullptr, 10);
    if (argc >= 3) seconds = std::atoi(argv[2]);
    const bool hz_ok = game::zone::accepted_hz(hz);
    const bool time_ok = seconds >= 1 && seconds <= 3600;
    return hz_ok && time_ok;
}

} // namespace

int main(int argc, char** argv) {
    std::int64_t hz = 20;
    int seconds = 20;
    if (!parse_args(argc, argv, hz, seconds)) {
        std::cerr << "dùng: pos_fan_bench <20|30|40> <giây 1..3600>\n";
        return 2;
    }
    std::cout << "Trong tiến trình. Byte là khung application, không phải byte trên dây.\n";
    std::cout << "Bước đi 20 lần mỗi giây mô phỏng.\n";
    std::cout << "Không có TCP, AEAD, chiến đấu hay cơ sở dữ liệu.\n";
    std::cout << "Không suy ra sức chứa.\n";
    crowd(hz, seconds);
    spread(hz, seconds);
    return 0;
}
