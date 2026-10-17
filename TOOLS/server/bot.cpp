/*==============================================================================
 *  THIENLONG  |  TOOLS
 *------------------------------------------------------------------------------
 *  TỆP       : TOOLS/server/bot.cpp
 *  PHÂN HỆ   : Server / Bot
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Khách giả nối vào cụm máy chủ thật: tạo tài khoản, tạo nhân vật, vào game,
 *    đi quanh điểm sinh rồi thoát. Kiểm đường đi đầy đủ gate -> zone -> gate
 *    (SceneEnter, EntityAppear, EntityPos, EntityDisappear) và dùng làm nền cho
 *    bài đo tải thế giới. Mỗi khách một luồng, mỗi luồng một cặp kết nối (cổng
 *    auth rồi cổng game).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Chạy: thienlong_bot --identity <identity.key> [--game 7000] [--auth 7001] [--count 4] [--seconds 6] [--prefix bot]
//       [--straight 1] [--hunt <x_m>,<z_m>] [--talk <x_m>,<z_m>] [--fight <x_m>,<z_m>]
// Thoát 0 khi mọi khách vào được cảnh và thấy đủ những khách còn lại; khác 0 kèm lý do.
// --straight 1: mỗi khách đi thẳng một hướng (chia đều 360 độ theo số khách) tới khi bị luật đi của zone chặn, rồi
// đo việc server kéo về: phải có ít nhất một lần kéo về, và mỗi lần kéo về chỉ lùi vài bước so với chỗ khách tưởng
// mình đang đứng (không nhảy đi đâu khác). Khi đó khách không cần thấy nhau (mỗi người đi một hướng, ra khỏi vùng nhìn).
// --hunt X,Z: mỗi khách đi thẳng tới điểm (X, Z) mét (cảnh vào game) rồi đứng đó --seconds giây, đếm quái hiện ra, quái
// di chuyển (EntityPos Walk/Idle) và khoảng gần nhất quái tới khách: kiểm AI quái của zone trên cụm thật. Đạt khi thấy
// quái hiện ra và quái có đi.
// --fight X,Z: đi tới điểm (X, Z) mét, chọn quái gần nhất còn sống, đi sát và ra chiêu đầu tiên trong SelfSkills tới khi
// nó chết, rồi nhặt vật rơi (nếu có). Đạt khi có SkillCast mang seq của mình, sát thương, EntityDied và kinh nghiệm tăng.

#include "io/platform.hpp"
#include "link/link.hpp"
#include "net/net.hpp"
#include "protocol/messages.hpp"
#include "protocol/wire.hpp"
#include "secure/secure.hpp"

#include <atomic>
#include <charconv>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <format>
#include <iterator>
#include <numbers>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <thread>
#include <unordered_map>
#include <utility>
#include <variant>
#include <vector>

namespace {

namespace io = game::io;
namespace link = game::link;
namespace net = game::net;
namespace protocol = game::protocol;
namespace secure = game::secure;
using Clock = std::chrono::steady_clock;

constexpr net::Milliseconds kStep{5000};
constexpr std::string_view kPassword = "Bot-pass-2026-xyz";

struct Options {
    std::filesystem::path identity;
    std::uint16_t game_port = 7000;
    std::uint16_t auth_port = 7001;
    int count = 4;
    int seconds = 6;
    std::string prefix = "bot";
    bool straight = false;
    // Điểm tới của --hunt, centimet.
    std::optional<std::pair<float, float>> hunt;
    // Điểm tới của --talk, centimet.
    std::optional<std::pair<float, float>> talk;
    // Điểm tới của --fight, centimet.
    std::optional<std::pair<float, float>> fight;
};

struct Tally {
    std::atomic<int> entered{0};
    // EntityAppear của người chơi khác; NPC và quái đếm riêng để bài kiểm "thấy đủ khách" không bị số quái làm mờ.
    std::atomic<int> appear{0};
    std::atomic<int> npcs{0};
    std::atomic<int> monsters{0};
    std::atomic<int> disappear{0};
    std::atomic<int> position{0};
    std::atomic<int> failed{0};
    // Chỉ chế độ --straight: số lần server kéo về, và số lần kéo về xa hơn vài bước so với chỗ khách đang tưởng mình đứng.
    std::atomic<int> corrections{0};
    std::atomic<int> drifted{0};
    // Chỉ chế độ --hunt: EntityPos của quái theo trạng thái, và khoảng gần nhất (cm) từ quái tới khách.
    std::atomic<int> monster_walking{0};
    std::atomic<int> monster_resting{0};
    std::atomic<int> closest_cm{1'000'000};
    // Chỉ chế độ --talk: NPC bấm được thấy, hộp thoại mở, bảng nhận nhiệm vụ gặp, và nhiệm vụ vào sổ.
    std::atomic<int> talkable{0};
    std::atomic<int> dialogs{0};
    std::atomic<int> offers{0};
    std::atomic<int> accepted{0};
    // Chỉ chế độ --fight: chiêu của mình được SkillCast xác nhận (seq khác 0), sát thương, quái chết, vật rơi thấy, vật nhặt
    // được, và kinh nghiệm tăng.
    std::atomic<int> casts{0};
    std::atomic<int> damage_events{0};
    std::atomic<int> deaths{0};
    std::atomic<int> drops{0};
    std::atomic<int> picked{0};
    std::atomic<std::int64_t> exp_gained{0};
};

void report(std::string_view who, std::string_view what) { std::println(stderr, "[{}] {}", who, what); }

template <typename Message>
[[nodiscard]] bool send(link::Link& line, const Message& message) {
    std::vector<std::byte> frame;
    if (!protocol::encode(frame, message)) return false;
    return line.send_frame(frame, kStep).has_value();
}

[[nodiscard]] std::optional<protocol::GameServerMessage> read_game(link::Link& line, net::Milliseconds wait) {
    const link::LinkResult<std::vector<std::byte>> got = line.receive_frame(wait);
    if (!got) return std::nullopt;
    const protocol::ByteView bytes{got->data(), got->size()};
    const protocol::FrameResult head = protocol::peek_frame(bytes, protocol::kMaxBodyBytes);
    if (!head || !head->has_value()) return std::nullopt;
    const protocol::Frame frame = **head;
    protocol::GameServerResult decoded = protocol::decode_game_server(frame, bytes.subspan(protocol::kHeaderBytes));
    if (!decoded) return std::nullopt;
    return std::move(*decoded);
}

[[nodiscard]] std::optional<protocol::Ticket> read_ticket(link::Link& line) {
    const link::LinkResult<std::vector<std::byte>> got = line.receive_frame(kStep);
    if (!got) return std::nullopt;
    const protocol::ByteView bytes{got->data(), got->size()};
    const protocol::FrameResult head = protocol::peek_frame(bytes, protocol::kMaxBodyBytes);
    if (!head || !head->has_value()) return std::nullopt;
    const protocol::Frame frame = **head;
    protocol::AuthServerResult decoded = protocol::decode_auth_server(frame, bytes.subspan(protocol::kHeaderBytes));
    if (!decoded) return std::nullopt;
    if (auto* ticket = std::get_if<protocol::Ticket>(&*decoded)) return *ticket;
    return std::nullopt;
}

[[nodiscard]] std::optional<link::Link> dial(std::uint16_t port, const secure::PublicKey& server) {
    link::Link::HelloDesc desc;
    desc.peer = net::Endpoint{.address = {127, 0, 0, 1}, .port = port};
    desc.server = server;
    desc.build = 1;
    link::LinkResult<link::Link> opened = link::Link::open(desc);
    if (!opened) return std::nullopt;
    return std::move(*opened);
}

// Vé đăng nhập: thử tạo tài khoản, đã có thì đăng nhập.
[[nodiscard]] std::optional<std::string> ticket_for(const Options& options, const secure::PublicKey& server,
    const std::string& account) {
    for (int attempt = 0; attempt < 2; ++attempt) {
        std::optional<link::Link> line = dial(options.auth_port, server);
        if (!line) return std::nullopt;
        const bool sent = attempt == 0 ? send(*line, protocol::CreateAccount{.account = account, .password = std::string{kPassword}})
                                       : send(*line, protocol::SignIn{.account = account, .password = std::string{kPassword}});
        if (!sent) return std::nullopt;
        // Vé đi trong Ticket dưới dạng chữ hex ASCII, phần thừa của mảng là 0.
        if (const std::optional<protocol::Ticket> ticket = read_ticket(*line)) {
            std::string text;
            for (const std::byte letter : ticket->token) {
                if (letter == std::byte{0}) break;
                text.push_back(static_cast<char>(letter));
            }
            return text;
        }
    }
    return std::nullopt;
}

struct Npc {
    std::string name;
    float x_cm = 0.0F;
    float z_cm = 0.0F;
};

struct Seen {
    // Loại của từng thực thể đã hiện, và chỗ khách đang đứng (để đo khoảng tới quái).
    std::unordered_map<std::uint32_t, protocol::EntityKind> kinds;
    // NPC chưa có cờ bấm được, và NPC đã có cờ bit 0 (bấm vào để nói chuyện).
    std::unordered_map<std::uint32_t, Npc> npcs;
    std::unordered_map<std::uint32_t, Npc> talkable;
    // Tin hội thoại và sổ nhiệm vụ mới nhất.
    std::optional<protocol::DialogOpen> dialog;
    std::optional<protocol::QuestBook> book;
    // Chế độ --fight: kỹ năng đã học, quái và vật rơi đang thấy, kinh nghiệm mới nhất và túi đồ mới nhất.
    std::vector<protocol::SkillEntry> skills;
    std::unordered_map<std::uint32_t, Npc> monsters;
    std::unordered_map<std::uint32_t, Npc> loot;
    std::optional<std::uint64_t> exp;
    std::optional<protocol::SelfBag> bag;
    float x_cm = 0.0F;
    float z_cm = 0.0F;
    std::optional<protocol::Position> position;
    std::optional<protocol::CharacterList> roster;
    bool refused = false;
    // Chế độ --talk: một Reject (lựa chọn chưa có hội thoại, nhiệm vụ chưa nhận được) không kết thúc phiên thử.
    bool tolerate_reject = false;
};

void note_gap(Tally& tally, int gap) {
    int best = tally.closest_cm.load();
    while (gap < best && !tally.closest_cm.compare_exchange_weak(best, gap)) {
    }
}

template <typename Place>
void note_pos(const Place& moved, Seen& seen, Tally& tally) {
    ++tally.position;
    const auto known = seen.monsters.find(moved.id);
    if (known != seen.monsters.end()) {
        known->second.x_cm = moved.x_cm;
        known->second.z_cm = moved.z_cm;
    }
    const auto kind = seen.kinds.find(moved.id);
    if (kind == seen.kinds.end()) return;
    if (kind->second != protocol::EntityKind::kMonster) return;
    const bool walking = moved.state == protocol::EntityState::kWalk;
    if (walking) ++tally.monster_walking;
    if (!walking) ++tally.monster_resting;
    const float along = moved.x_cm - seen.x_cm;
    const float across = moved.z_cm - seen.z_cm;
    const auto gap = static_cast<int>(std::hypot(along, across));
    note_gap(tally, gap);
}

void note_batch(const protocol::EntityPosBatch& batch, Seen& seen, Tally& tally) {
    for (const protocol::PosEntry& place : batch.places)
        note_pos(place, seen, tally);
}

void note(const protocol::GameServerMessage& message, Seen& seen, Tally& tally) {
    if (const auto* reject = std::get_if<protocol::Reject>(&message)) {
        std::println(stderr, "  server từ chối tin 0x{:04x}: mã {}", reject->request,
            static_cast<unsigned>(reject->code));
    }
    if (const auto* bye = std::get_if<protocol::Goodbye>(&message)) {
        std::println(stderr, "  server đóng phiên: lý do {}", static_cast<unsigned>(bye->reason));
    }
    if (const auto* list = std::get_if<protocol::CharacterList>(&message)) seen.roster = *list;
    if (const auto* spot = std::get_if<protocol::Position>(&message)) seen.position = *spot;
    if ((std::holds_alternative<protocol::Reject>(message) && !seen.tolerate_reject) ||
        std::holds_alternative<protocol::Goodbye>(message)) {
        seen.refused = true;
    }
    if (std::holds_alternative<protocol::SceneEnter>(message)) ++tally.entered;
    if (const auto* shown = std::get_if<protocol::EntityAppear>(&message)) {
        seen.kinds[shown->id] = shown->kind;
        if (shown->kind == protocol::EntityKind::kNpc) {
            seen.npcs[shown->id] = Npc{.name = shown->name, .x_cm = shown->x_cm, .z_cm = shown->z_cm};
        }
        if (shown->kind == protocol::EntityKind::kMonster && shown->state != protocol::EntityState::kDead) {
            seen.monsters[shown->id] = Npc{.name = shown->name, .x_cm = shown->x_cm, .z_cm = shown->z_cm};
        }
        if (shown->kind == protocol::EntityKind::kDrop) {
            seen.loot[shown->id] = Npc{.name = shown->name, .x_cm = shown->x_cm, .z_cm = shown->z_cm};
            ++tally.drops;
        }
        if (shown->kind == protocol::EntityKind::kPlayer) {
            ++tally.appear;
        } else if (shown->kind == protocol::EntityKind::kNpc) {
            ++tally.npcs;
        } else {
            ++tally.monsters;
        }
    }
    if (const auto* flags = std::get_if<protocol::EntityFlags>(&message)) {
        const auto npc = seen.npcs.find(flags->id);
        if ((flags->flags & 1U) != 0 && npc != seen.npcs.end() && seen.talkable.emplace(flags->id, npc->second).second) {
            ++tally.talkable;
        }
    }
    if (const auto* dialog = std::get_if<protocol::DialogOpen>(&message)) seen.dialog = *dialog;
    if (const auto* book = std::get_if<protocol::QuestBook>(&message)) seen.book = *book;
    if (const auto* gone = std::get_if<protocol::EntityDisappear>(&message)) {
        ++tally.disappear;
        seen.monsters.erase(gone->id);
        seen.loot.erase(gone->id);
    }
    if (const auto* skills = std::get_if<protocol::SelfSkills>(&message)) seen.skills = skills->skills;
    if (const auto* bag = std::get_if<protocol::SelfBag>(&message)) seen.bag = *bag;
    if (const auto* stats = std::get_if<protocol::SelfStats>(&message)) {
        if (seen.exp && stats->exp > *seen.exp) tally.exp_gained += static_cast<std::int64_t>(stats->exp - *seen.exp);
        seen.exp = stats->exp;
    }
    if (const auto* cast = std::get_if<protocol::SkillCast>(&message); cast != nullptr && cast->seq != 0) ++tally.casts;
    if (const auto* hit = std::get_if<protocol::CombatEvent>(&message);
        hit != nullptr && hit->kind == protocol::CombatKind::kDamage && hit->value > 0) {
        ++tally.damage_events;
    }
    if (const auto* died = std::get_if<protocol::EntityDied>(&message)) {
        if (seen.monsters.erase(died->id) != 0) ++tally.deaths;
    }
    const auto* moved = std::get_if<protocol::EntityPos>(&message);
    if (moved != nullptr) note_pos(*moved, seen, tally);
    const auto* batch = std::get_if<protocol::EntityPosBatch>(&message);
    if (batch != nullptr) note_batch(*batch, seen, tally);
}

// Hướng đi (radian) và độ rẽ sau mỗi bước.
struct Gait {
    float heading = 0.0F;
    float turn = 0.0F;
};

// Đi 10 cm mỗi bước, 30 bước mỗi giây, rẽ `gait.turn` radian sau mỗi bước (0 là đi thẳng; 0,05 là vòng tròn bán kính
// 200 cm). Nhận Position thì đặt lại vị trí của mình như client thật phải làm (không thì bước sau bị gate coi là
// nhảy vọt), đếm một lần kéo về và so với chỗ mình tưởng đang đứng: tới lúc Position đến, khách đã gửi thêm một hai
// bước nữa vào chỗ bị chặn, nên điểm kéo về chỉ được cách vài bước (đi dọc tường thì điểm này trượt theo).
// false khi gửi Move hỏng (socket đã đóng). Người gọi phải tính là lỗi: Goodbye có thể còn nằm trong
// hàng chưa đọc, nên seen.refused một mình không đủ để biết phiên đã chết.
[[nodiscard]] bool walk(link::Link& line, Seen& seen, Tally& tally, const protocol::Position& start, Gait gait,
    int seconds) {
    constexpr float kStepCm = 10.0F;
    constexpr float kMaxBehindCm = 45.0F;
    float x = start.x_cm;
    float z = start.z_cm;
    const auto until = Clock::now() + std::chrono::seconds{seconds};
    std::uint32_t tick = 0;
    while (Clock::now() < until && !seen.refused) {
        ++tick;
        gait.heading += gait.turn;
        x += kStepCm * std::cos(gait.heading);
        z += kStepCm * std::sin(gait.heading);
        if (!send(line, protocol::Move{.x_cm = x, .z_cm = z, .tick = tick})) return false;
        const auto frame_end = Clock::now() + std::chrono::milliseconds{33};
        while (Clock::now() < frame_end) {
            const auto message = read_game(line, net::Milliseconds{3});
            if (!message) continue;
            note(*message, seen, tally);
            const auto* spot = std::get_if<protocol::Position>(&*message);
            if (spot == nullptr) continue;
            ++tally.corrections;
            if (std::hypot(spot->x_cm - x, spot->z_cm - z) > kMaxBehindCm) ++tally.drifted;
            x = spot->x_cm;
            z = spot->z_cm;
        }
    }
    return true;
}

// Đi thẳng tới khi cách `goal` không quá `close_cm` (10 cm mỗi bước, 30 bước mỗi giây), vẫn đọc mọi tin. Position kéo
// về thì đặt lại vị trí như client thật.
void go(link::Link& line, Seen& seen, Tally& tally, std::pair<float, float> goal, float close_cm, std::uint32_t& tick) {
    constexpr float kStepCm = 10.0F;
    const auto give_up = Clock::now() + std::chrono::seconds{120};
    while (Clock::now() < give_up && !seen.refused && std::hypot(goal.first - seen.x_cm, goal.second - seen.z_cm) > close_cm) {
        ++tick;
        const float heading = std::atan2(goal.second - seen.z_cm, goal.first - seen.x_cm);
        seen.x_cm += kStepCm * std::cos(heading);
        seen.z_cm += kStepCm * std::sin(heading);
        if (!send(line, protocol::Move{.x_cm = seen.x_cm, .z_cm = seen.z_cm, .tick = tick})) return;
        const auto frame_end = Clock::now() + std::chrono::milliseconds{33};
        while (Clock::now() < frame_end) {
            const auto message = read_game(line, net::Milliseconds{3});
            if (!message) continue;
            note(*message, seen, tally);
            if (const auto* spot = std::get_if<protocol::Position>(&*message)) {
                ++tally.corrections;
                seen.x_cm = spot->x_cm;
                seen.z_cm = spot->z_cm;
            }
        }
    }
}

// Đi thẳng tới `goal` rồi đứng lại `seconds` giây, vẫn đọc mọi tin và gửi Ping mỗi giây để giữ phiên.
void hunt(link::Link& line, Seen& seen, Tally& tally, const protocol::Position& start, std::pair<float, float> goal,
    int seconds) {
    constexpr float kCloseCm = 300.0F;
    seen.x_cm = start.x_cm;
    seen.z_cm = start.z_cm;
    std::uint32_t tick = 0;
    go(line, seen, tally, goal, kCloseCm, tick);
    std::println("  tới ({:.0f}, {:.0f}) cm, còn cách đích {:.0f} cm", seen.x_cm, seen.z_cm,
        std::hypot(goal.first - seen.x_cm, goal.second - seen.z_cm));
    const auto until = Clock::now() + std::chrono::seconds{seconds};
    auto next_ping = Clock::now();
    while (Clock::now() < until && !seen.refused) {
        if (Clock::now() >= next_ping) {
            static_cast<void>(send(line, protocol::Ping{.client_time = std::chrono::milliseconds{0}}));
            next_ping += std::chrono::seconds{1};
        }
        const auto message = read_game(line, net::Milliseconds{20});
        if (message) note(*message, seen, tally);
    }
}

// Đọc mọi tin tới khi `done()` đúng hoặc hết `wait`.
template <typename Done>
void listen(link::Link& line, Seen& seen, Tally& tally, std::chrono::milliseconds wait, Done done) {
    const auto until = Clock::now() + wait;
    while (Clock::now() < until && !seen.refused && !done()) {
        const auto message = read_game(line, net::Milliseconds{20});
        if (message) note(*message, seen, tally);
    }
}

// NPC bấm được gần `from` nhất.
[[nodiscard]] std::optional<std::pair<std::uint32_t, Npc>> nearest_talkable(const Seen& seen) {
    std::optional<std::pair<std::uint32_t, Npc>> best;
    float best_gap = 0.0F;
    for (const auto& [id, npc] : seen.talkable) {
        const float gap = std::hypot(npc.x_cm - seen.x_cm, npc.z_cm - seen.z_cm);
        if (!best || gap < best_gap) {
            best = std::pair{id, npc};
            best_gap = gap;
        }
    }
    return best;
}

// Nói chuyện với NPC bấm được gần nhất: duyệt từng lựa chọn (chọn, rồi nói lại với NPC để về hộp thoại gốc) tới khi gặp
// bảng nhận nhiệm vụ, nhận, và chờ sổ nhiệm vụ có ô mới.
void converse(link::Link& line, Seen& seen, Tally& tally, std::uint32_t npc, std::uint32_t& tick) {
    constexpr std::chrono::milliseconds kReply{1500};
    // Mỗi tin cách nhau hơn nhịp 100 ms để không chạm trần mười ý định mỗi giây của server.
    const auto pace = [] { std::this_thread::sleep_for(std::chrono::milliseconds{150}); };
    const auto ask = [&](const auto& message) {
        pace();
        seen.dialog.reset();
        return send(line, message);
    };
    if (!ask(protocol::Talk{.npc = npc})) return;
    listen(line, seen, tally, kReply, [&] { return seen.dialog.has_value(); });
    if (!seen.dialog) return;
    ++tally.dialogs;
    std::println("  hộp thoại: {} dòng, {} lựa chọn", seen.dialog->lines.size(), seen.dialog->choices.size());
    const protocol::DialogOpen root = *seen.dialog;
    std::uint64_t session = root.session;
    for (const protocol::DialogChoice& choice : root.choices) {
        if (!ask(protocol::DialogChoose{.session = session, .index = choice.index})) return;
        listen(line, seen, tally, kReply, [&] { return seen.dialog.has_value(); });
        if (seen.dialog && seen.dialog->mode == protocol::DialogMode::kMissionInfo && seen.dialog->panel_quest >= 0) {
            ++tally.offers;
            const auto quest = static_cast<std::uint16_t>(seen.dialog->panel_quest);
            std::println("  gặp bảng nhận nhiệm vụ {}", quest);
            seen.book.reset();
            if (!ask(protocol::QuestAccept{.session = seen.dialog->session, .quest = quest})) return;
            listen(line, seen, tally, kReply, [&] { return seen.book.has_value(); });
            if (seen.book && !seen.book->slots.empty()) {
                ++tally.accepted;
                std::println("  nhiệm vụ {} đã vào sổ ({} ô)", seen.book->slots.front().quest, seen.book->slots.size());
            }
            return;
        }
        if (!ask(protocol::Talk{.npc = npc})) return;
        listen(line, seen, tally, kReply, [&] { return seen.dialog.has_value(); });
        if (!seen.dialog) return;
        session = seen.dialog->session;
        ++tick;
    }
}

// Đi tới `goal`, chờ NPC bấm được hiện ra, đi tới sát NPC gần nhất rồi nói chuyện (xem converse).
void talk(link::Link& line, Seen& seen, Tally& tally, const protocol::Position& start, std::pair<float, float> goal) {
    constexpr float kCloseCm = 300.0F;
    constexpr float kTalkCm = 150.0F;
    seen.x_cm = start.x_cm;
    seen.z_cm = start.z_cm;
    std::uint32_t tick = 0;
    seen.tolerate_reject = true;
    go(line, seen, tally, goal, kCloseCm, tick);
    listen(line, seen, tally, std::chrono::milliseconds{1500}, [] { return false; });
    const auto target = nearest_talkable(seen);
    if (!target) {
        std::println("  không thấy NPC bấm được quanh ({:.0f}, {:.0f})", seen.x_cm, seen.z_cm);
        return;
    }
    std::println("  NPC gần nhất: {} (id {:#x}), cách {:.0f} cm", target->second.name, target->first,
        std::hypot(target->second.x_cm - seen.x_cm, target->second.z_cm - seen.z_cm));
    go(line, seen, tally, std::pair{target->second.x_cm, target->second.z_cm}, kTalkCm, tick);
    listen(line, seen, tally, std::chrono::milliseconds{300}, [] { return false; });
    converse(line, seen, tally, target->first, tick);
}

// Quái còn sống gần khách nhất.
[[nodiscard]] std::optional<std::pair<std::uint32_t, Npc>> nearest_monster(const Seen& seen) {
    std::optional<std::pair<std::uint32_t, Npc>> best;
    float best_gap = 0.0F;
    for (const auto& [id, monster] : seen.monsters) {
        const float gap = std::hypot(monster.x_cm - seen.x_cm, monster.z_cm - seen.z_cm);
        if (!best || gap < best_gap) {
            best = std::pair{id, monster};
            best_gap = gap;
        }
    }
    return best;
}

// Đi tới vật rơi gần nhất, nhặt, chờ túi đổi. Trả đúng khi túi đổi.
[[nodiscard]] bool collect(link::Link& line, Seen& seen, Tally& tally, std::uint32_t& tick) {
    constexpr float kPickCm = 120.0F;
    std::optional<std::pair<std::uint32_t, Npc>> best;
    float best_gap = 0.0F;
    for (const auto& [id, drop] : seen.loot) {
        const float gap = std::hypot(drop.x_cm - seen.x_cm, drop.z_cm - seen.z_cm);
        if (!best || gap < best_gap) {
            best = std::pair{id, drop};
            best_gap = gap;
        }
    }
    if (!best) return false;
    go(line, seen, tally, std::pair{best->second.x_cm, best->second.z_cm}, kPickCm, tick);
    const std::optional<protocol::SelfBag> before = seen.bag;
    seen.bag.reset();
    if (!send(line, protocol::PickUp{.drop = best->first})) return false;
    listen(line, seen, tally, std::chrono::milliseconds{1500}, [&] { return seen.bag.has_value(); });
    const bool changed = seen.bag.has_value() && (!before || *seen.bag != *before);
    if (changed) ++tally.picked;
    return changed;
}

// Săn quái ở `goal`: giết tối đa kMaxKills con (dừng sớm khi đã nhặt được một món), mỗi con đánh bằng kỹ năng đầu tiên
// trong SelfSkills.
void fight(link::Link& line, Seen& seen, Tally& tally, const protocol::Position& start, std::pair<float, float> goal) {
    constexpr float kCloseCm = 300.0F;
    constexpr float kReachCm = 150.0F;
    constexpr int kMaxKills = 12;
    constexpr int kMaxCasts = 40;
    seen.x_cm = start.x_cm;
    seen.z_cm = start.z_cm;
    seen.tolerate_reject = true;
    std::uint32_t tick = 0;
    std::uint16_t seq = 0;
    go(line, seen, tally, goal, kCloseCm, tick);
    listen(line, seen, tally, std::chrono::milliseconds{1500}, [] { return false; });
    if (seen.skills.empty()) {
        std::println("  SelfSkills rỗng: nhân vật chưa có kỹ năng");
        return;
    }
    const std::uint16_t skill = seen.skills.front().skill;
    std::println("  ra chiêu {} (cấp {})", skill, seen.skills.front().level);
    for (int kills = 0; kills < kMaxKills && tally.picked.load() == 0 && !seen.refused; ++kills) {
        const auto target = nearest_monster(seen);
        if (!target) {
            std::println("  không còn quái sống quanh ({:.0f}, {:.0f})", seen.x_cm, seen.z_cm);
            break;
        }
        const int deaths_before = tally.deaths.load();
        for (int round = 0; round < kMaxCasts && tally.deaths.load() == deaths_before && !seen.refused; ++round) {
            const auto current = seen.monsters.find(target->first);
            if (current == seen.monsters.end()) break;
            go(line, seen, tally, std::pair{current->second.x_cm, current->second.z_cm}, kReachCm, tick);
            if (!send(line, protocol::CastSkill{.seq = ++seq, .skill = skill, .target = target->first})) return;
            // 1,4 giây giữa hai chiêu: đủ hồi chiêu cơ bản và dưới trần mười ý định mỗi giây của server.
            listen(line, seen, tally, std::chrono::milliseconds{1400}, [&] { return tally.deaths.load() != deaths_before; });
        }
        if (tally.deaths.load() == deaths_before) continue;
        std::println("  quái {:#x} chết sau {} chiêu", target->first, seq);
        listen(line, seen, tally, std::chrono::milliseconds{800}, [] { return false; });
        if (collect(line, seen, tally, tick)) std::println("  nhặt được vật rơi, túi có {} ô", seen.bag ? seen.bag->slots.size() : 0U);
    }
}

void run_bot(const Options& options, const secure::PublicKey& server, int index, Tally& tally) {
    // Auth băm Argon2id từng vé và hàng hỏi của gate chỉ chứa 64 câu. Cả đám cùng xin thì vé sau bị
    // kBusy.
    std::this_thread::sleep_for(std::chrono::milliseconds{index * 200});
    const std::string account = std::format("{}{}", options.prefix, index);
    const auto fail = [&](std::string_view why) {
        report(account, why);
        ++tally.failed;
    };
    const std::optional<std::string> ticket = ticket_for(options, server, account);
    if (!ticket) return fail("không lấy được vé đăng nhập");
    std::optional<link::Link> line = dial(options.game_port, server);
    if (!line) return fail("không nối được cổng game");
    if (!send(*line, protocol::Login{.account = account, .ticket = *ticket})) return fail("gửi Login hỏng");
    Seen seen;
    for (int round = 0; round < 8 && !seen.roster && !seen.refused; ++round) {
        const auto message = read_game(*line, kStep);
        if (!message) return fail("không nhận được danh sách nhân vật");
        note(*message, seen, tally);
    }
    if (!seen.roster) return fail("Login bị từ chối");
    if (seen.roster->characters.empty()) {
        // Mặt 100 và tóc 5 nằm trong danh sách nam tạo được của store.toml.
        const protocol::CreateCharacter create{
            .name = std::format("{}nv{}", options.prefix, index), .gender = protocol::Gender::kMale,
            .face = 100, .hair = 5};
        if (!send(*line, create)) return fail("gửi CreateCharacter hỏng");
        seen.roster.reset();
        for (int round = 0; round < 8 && !seen.roster && !seen.refused; ++round) {
            const auto message = read_game(*line, kStep);
            if (!message) return fail("không nhận được danh sách sau khi tạo nhân vật");
            note(*message, seen, tally);
        }
        if (!seen.roster || seen.roster->characters.empty()) return fail("tạo nhân vật bị từ chối");
    }
    if (!send(*line, protocol::EnterGame{.character = seen.roster->characters.front().id})) {
        return fail("gửi EnterGame hỏng");
    }
    for (int round = 0; round < 16 && !seen.position && !seen.refused; ++round) {
        const auto message = read_game(*line, kStep);
        if (!message) return fail("không nhận được Position");
        note(*message, seen, tally);
    }
    if (!seen.position) return fail("EnterGame bị từ chối");
    const float arrived_x = seen.position->x_cm;
    const float arrived_z = seen.position->z_cm;
    std::println("[{}] vào tại x={:.0f} z={:.0f} (cm)", account, arrived_x, arrived_z);
    const float share = static_cast<float>(index) / static_cast<float>(options.count);
    const float heading = 2.0F * std::numbers::pi_v<float> * share;
    bool walked = true;
    if (options.fight) {
        fight(*line, seen, tally, *seen.position, *options.fight);
    } else if (options.talk) {
        talk(*line, seen, tally, *seen.position, *options.talk);
    } else if (options.hunt) {
        hunt(*line, seen, tally, *seen.position, *options.hunt, options.seconds);
    } else if (options.straight) {
        const Gait gait{.heading = heading, .turn = 0.0F};
        walked = walk(*line, seen, tally, *seen.position, gait, options.seconds);
    } else {
        // Vòng tròn bán kính 200 cm bắt đầu từ điểm sinh (mỗi bước 10 cm, dưới trần 15,5 cm của
        // guard::Pace).
        const Gait gait{.heading = 0.0F, .turn = 0.05F};
        walked = walk(*line, seen, tally, *seen.position, gait, options.seconds);
    }
    if (seen.refused || !walked) return fail("bị server đóng giữa chừng");
    static_cast<void>(send(*line, protocol::Logout{}));
}

// Số nguyên thập phân chiếm trọn chuỗi; stoi sẽ ném ngoại lệ với đối số hỏng, ở đây thì trả nullopt.
[[nodiscard]] std::optional<int> whole_number(std::string_view text) {
    int value = 0;
    const char* const first = text.data();
    const char* const last = std::next(first, static_cast<std::ptrdiff_t>(text.size()));
    const std::from_chars_result parsed = std::from_chars(first, last, value);
    if (parsed.ec != std::errc{} || parsed.ptr != last) return std::nullopt;
    return value;
}

[[nodiscard]] std::optional<std::uint16_t> port_number(std::string_view text) {
    const std::optional<int> value = whole_number(text);
    if (!value || *value < 1 || *value > 65535) return std::nullopt;
    return static_cast<std::uint16_t>(*value);
}

[[nodiscard]] std::optional<Options> parse(std::span<const char* const> args) {
    Options options;
    for (std::size_t at = 1; at < args.size(); ++at) {
        const std::string_view key = args[at];
        if (at + 1 >= args.size()) return std::nullopt;
        ++at;
        const std::string_view value = args[at];
        if (key == "--identity") {
            options.identity = std::filesystem::path{std::string{value}};
        } else if (key == "--game") {
            const std::optional<std::uint16_t> port = port_number(value);
            if (!port) return std::nullopt;
            options.game_port = *port;
        } else if (key == "--auth") {
            const std::optional<std::uint16_t> port = port_number(value);
            if (!port) return std::nullopt;
            options.auth_port = *port;
        } else if (key == "--count" || key == "--seconds") {
            const std::optional<int> number = whole_number(value);
            if (!number) return std::nullopt;
            (key == "--count" ? options.count : options.seconds) = *number;
        } else if (key == "--prefix") {
            options.prefix = value;
        } else if (key == "--straight") {
            options.straight = value == "1";
        } else if (key == "--hunt" || key == "--talk" || key == "--fight") {
            const std::size_t comma = value.find(',');
            if (comma == std::string_view::npos) return std::nullopt;
            const std::optional<int> east = whole_number(value.substr(0, comma));
            const std::optional<int> south = whole_number(value.substr(comma + 1));
            if (!east || !south) return std::nullopt;
            const std::pair goal{static_cast<float>(*east) * 100.0F, static_cast<float>(*south) * 100.0F};
            if (key == "--hunt") {
                options.hunt = goal;
            } else if (key == "--talk") {
                options.talk = goal;
            } else {
                options.fight = goal;
            }
        } else {
            return std::nullopt;
        }
    }
    if (options.identity.empty() || options.count < 1 || options.count > 256 || options.seconds < 1) return std::nullopt;
    return options;
}

} // namespace

// NOLINTNEXTLINE(bugprone-exception-escape): công cụ thử, hết bộ nhớ thì dừng tiến trình là đủ.
int main(int argc, char** argv) {
    io::use_utf8_console();
    const std::optional<Options> options =
        parse(std::span<const char* const>{argv, static_cast<std::size_t>(argc)});
    if (!options) {
        std::println(stderr, "dùng: thienlong_bot --identity <identity.key> [--game 7000] [--auth 7001] [--count 4] "
                             "[--seconds 6] [--prefix bot] [--straight 1] [--hunt <x_m>,<z_m>] [--talk <x_m>,<z_m>] "
                             "[--fight <x_m>,<z_m>]");
        return 2;
    }
    const net::NetResult<net::Network> network = net::Network::start();
    if (!network) return 1;
    const secure::Result<secure::Identity> identity = secure::Identity::load(options->identity);
    if (!identity) {
        std::println(stderr, "không đọc được khoá danh tính: {}", secure::describe(identity.error()));
        return 2;
    }
    const secure::PublicKey server = identity->public_key();
    Tally tally;
    {
        std::vector<std::jthread> bots;
        bots.reserve(static_cast<std::size_t>(options->count));
        for (int index = 0; index < options->count; ++index) {
            bots.emplace_back([&, index] { run_bot(*options, server, index, tally); });
        }
    }
    const int want_seen = options->count - 1;
    std::println("khách={} vào cảnh={} hiện={} biến mất={} vị trí={} npc={} quái={} kéo về={} lệch={} lỗi={}",
        options->count, tally.entered.load(), tally.appear.load(), tally.disappear.load(), tally.position.load(),
        tally.npcs.load(), tally.monsters.load(), tally.corrections.load(), tally.drifted.load(), tally.failed.load());
    if (tally.failed.load() != 0) return 1;
    if (tally.entered.load() != options->count) return 1;
    if (options->fight) {
        std::println("chiến đấu: chiêu của mình={} sát thương={} quái chết={} vật rơi thấy={} đã nhặt={} kinh nghiệm +{}",
            tally.casts.load(), tally.damage_events.load(), tally.deaths.load(), tally.drops.load(), tally.picked.load(),
            tally.exp_gained.load());
        return tally.casts.load() > 0 && tally.damage_events.load() > 0 && tally.deaths.load() > 0 && tally.exp_gained.load() > 0
            ? 0
            : 1;
    }
    if (options->talk) {
        std::println("hội thoại: NPC bấm được={} hộp thoại={} bảng nhận={} đã nhận={}", tally.talkable.load(),
            tally.dialogs.load(), tally.offers.load(), tally.accepted.load());
        return tally.accepted.load() > 0 ? 0 : 1;
    }
    if (options->hunt) {
        std::println("quái đi: Walk={} Idle={}, gần nhất {} cm", tally.monster_walking.load(), tally.monster_resting.load(),
            tally.closest_cm.load());
        return tally.monsters.load() > 0 && tally.monster_walking.load() > 0 ? 0 : 1;
    }
    if (options->straight) return tally.corrections.load() > 0 && tally.drifted.load() == 0 ? 0 : 1;
    // Mỗi khách phải thấy mọi khách khác hiện ra ít nhất một lần.
    if (tally.appear.load() < options->count * want_seen) return 1;
    return 0;
}
