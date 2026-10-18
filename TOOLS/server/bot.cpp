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

// Chạy: thienlong_bot --identity <identity.key> [--game 7100] [--auth 7101] [--count 4]
//       [--seconds 6] [--prefix bot] [--straight 1] [--hunt <x_m>,<z_m>] [--talk <x_m>,<z_m>]
//       [--fight <x_m>,<z_m>] [--peers <n>] [--walk <walk.path>] [--roster 1] [--leap 1]
//       [--probe 1] [--hud 1]
// Thoát 0 khi mọi khách vào được cảnh và thấy đủ những khách còn lại; khác 0 kèm lý do.
// --walk <walk.path>: tệp .path của cảnh vào (dev/server/scenes/<cảnh>/walk.path). --hunt, --talk,
// --fight đi theo các điểm rẽ của luật đi client (nav::Field::plan_move, nhấp chuột tìm đường vòng
// vật cản) thay vì đi thẳng; không có --walk thì đi thẳng và vướng vật cản của zone như --straight.
// --peers N: đứng yên đủ --seconds giây ở điểm sinh (không thoát sớm), chỉ đọc tin và Ping giữ
// phiên; hết giờ thì thoát 0 nếu đã thấy ít nhất N người chơi khác hiện ra. Dùng làm con mắt chạy
// song song với client thật trong kịch bản E2E.
// --straight 1: mỗi khách đi thẳng một hướng (chia đều 360 độ theo số khách) tới khi bị luật đi của
// zone chặn, rồi đo việc server kéo về: phải có ít nhất một lần kéo về, và mỗi lần kéo về chỉ lùi
// vài bước so với chỗ khách tưởng mình đang đứng (không nhảy đi đâu khác). Khi đó khách không cần
// thấy nhau (mỗi người đi một hướng, ra khỏi vùng nhìn).
// --hunt X,Z: mỗi khách đi thẳng tới điểm (X, Z) mét (cảnh vào game) rồi đứng đó --seconds giây,
// đếm quái hiện ra, quái di chuyển (EntityPos Walk/Idle) và khoảng gần nhất quái tới khách: kiểm AI
// quái của zone trên cụm thật. Đạt khi thấy quái hiện ra và quái có đi.
// --fight X,Z: đi tới điểm (X, Z) mét, chọn quái gần nhất còn sống, đi sát và ra chiêu đầu tiên
// trong SelfSkills tới khi nó chết, rồi nhặt vật rơi (nếu có). Đạt khi có SkillCast mang seq của
// mình, sát thương, EntityDied và kinh nghiệm tăng. --seconds là tổng giờ săn (mặc định 6 giây là
// quá ngắn, nên đặt 60 trở lên). Server báo ngoài tầm (mã 31) thì đứng sát hơn; sau 8 lần liên tiếp
// ở tầm sát nhất thì bỏ quái đó, đánh con khác.
// --roster 1: không vào cảnh; hai tài khoản `<prefix>r` và `<prefix>x` (dùng --prefix mới mỗi lần,
// vì nhân vật nằm lại trong database) đi qua các bước tạo và xoá nhân vật, in mã server trả cho
// từng bước và thoát 1 nếu một bước sai mã mong đợi (G1-M): trần ba nhân vật (can_create), xoá id
// của tài khoản khác, xoá lại id đã xoá, xoá nhân vật đang chơi qua kết nối thứ hai, xoá dồn dưới
// 500 ms, xoá khi hết nhân vật.
// --leap 1 (cần --walk): đứng yên 2,2 giây cho giới hạn từng bước của guard::Pace đủ dài, rồi gửi
// một Move dài tới điểm đi được nằm sau tường (B19); zone phải đặt lại về chỗ cũ (Position). Sau đó
// một Move cùng khoảng cách tới điểm thông phải được nhận, để biết việc đặt lại là do tường chứ
// không do giới hạn quãng.
// --hud 1 (G2-M): vào cảnh rồi đối chiếu các tin của HUD với điều máy chủ phải gửi: SelfStats đủ
// thuộc tính, SelfSkills đúng sáu chiêu DefaultChar [0, 1, 21, 22, 34, 35], WorldTime, BuffList của
// mình, AskTarget (chính mình, thực thể khác, id lạ phải bị từ chối kNoSuchEntity, id 0 là bỏ
// chọn), rồi ra chiêu 35 (打坐) lên chính mình để thấy một buff thật trong BuffList của mình và
// trong bản của mục tiêu.
// --seconds từ 155 trở lên thì đứng chờ thêm tới khi canh giờ đổi (một canh dài 150 giây).

#include "io/platform.hpp"
#include "link/link.hpp"
#include "nav/mesh.hpp"
#include "nav/route.hpp"
#include "net/net.hpp"
#include "protocol/messages.hpp"
#include "protocol/wire.hpp"
#include "secure/secure.hpp"

#include <algorithm>
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
#include <fstream>
#include <iterator>
#include <memory>
#include <numbers>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <thread>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <variant>
#include <vector>

namespace {

namespace io = game::io;
namespace link = game::link;
namespace nav = game::nav;
namespace net = game::net;
namespace protocol = game::protocol;
namespace secure = game::secure;
using Clock = std::chrono::steady_clock;

constexpr net::Milliseconds kStep{5000};
constexpr std::string_view kPassword = "Bot-pass-2026-xyz";

struct Options {
    std::filesystem::path identity;
    std::uint16_t game_port = 7100;
    std::uint16_t auth_port = 7101;
    int count = 4;
    int seconds = 6;
    // Chế độ --peers: số người chơi khác phải thấy; 0 là không dùng chế độ này.
    int peers = 0;
    std::string prefix = "bot";
    bool straight = false;
    // --probe 1: chỉ bắt tay với cổng game rồi in phiên bản giao thức của bot và của cụm.
    bool probe = false;
    // --roster 1: kịch bản tạo và xoá nhân vật thay cho việc vào cảnh.
    bool roster = false;
    // --leap 1: một Move dài xuyên tường sau khi đứng yên, mong bị đặt lại.
    bool leap = false;
    // --hud 1: kiểm các tin của HUD (thuộc tính, sáu chiêu đầu, canh giờ, buff, AskTarget).
    bool hud = false;
    // Điểm tới của --hunt, centimet.
    std::optional<std::pair<float, float>> hunt;
    // Điểm tới của --talk, centimet.
    std::optional<std::pair<float, float>> talk;
    // Điểm tới của --fight, centimet.
    std::optional<std::pair<float, float>> fight;
    // --walk: tệp .path của cảnh vào; đi vòng vật cản bằng đúng luật đi của client. Field nạp một
    // lần ở main.
    std::filesystem::path walk;
    std::shared_ptr<const nav::Field> field;
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
    // Chỉ chế độ --leap: số khách mà bước xuyên tường bị đặt lại còn bước tới điểm thông được nhận.
    std::atomic<int> leaped{0};
    // Chỉ chế độ --hunt: EntityPos của quái theo trạng thái, và khoảng gần nhất (cm) từ quái tới
    // khách.
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
    // Quái mà luật đi client từ chối hay đi không tới được: --fight bỏ qua, đánh tiếp con khác.
    std::unordered_set<std::uint32_t> unreachable;
    // Số lần liên tiếp server từ chối chiêu vì ngoài tầm (mã 31); một chiêu được nhận thì về 0.
    int out_of_range = 0;
    std::unordered_map<std::uint32_t, Npc> loot;
    std::optional<std::uint64_t> exp;
    std::optional<protocol::SelfBag> bag;
    // Chế độ --hud (G2-M): thuộc tính mới nhất, các canh giờ đã nhận, id thực thể của chính mình,
    // rồi EntityVitals và BuffList mới nhất theo id thực thể, và mã Reject mới nhất.
    std::optional<protocol::SelfStats> stats;
    std::vector<std::uint8_t> hours;
    std::uint32_t self_id = 0;
    std::unordered_map<std::uint32_t, protocol::EntityVitals> vitals;
    std::unordered_map<std::uint32_t, protocol::BuffList> buffs;
    std::optional<protocol::ErrorCode> last_reject;
    float x_cm = 0.0F;
    float z_cm = 0.0F;
    // Lưới đi của cảnh (mượn từ Options); null là đi thẳng.
    const nav::Field* field = nullptr;
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

template <typename Held>
[[nodiscard]] const Held* held_in(const protocol::GameServerMessage& message) {
    return std::get_if<Held>(&message);
}

// Tin của HUD (G2-M): chỉ ghi lại, --hud tự đối chiếu.
void note_hud(const protocol::GameServerMessage& message, Seen& seen) {
    if (const auto* one = held_in<protocol::SceneEnter>(message)) seen.self_id = one->self_id;
    if (const auto* one = held_in<protocol::SelfStats>(message)) seen.stats = *one;
    if (const auto* one = held_in<protocol::WorldTime>(message)) seen.hours.push_back(one->period);
    if (const auto* one = held_in<protocol::EntityVitals>(message)) seen.vitals[one->id] = *one;
    if (const auto* one = held_in<protocol::BuffList>(message)) seen.buffs[one->id] = *one;
    if (const auto* one = held_in<protocol::Reject>(message)) seen.last_reject = one->code;
}

void note(const protocol::GameServerMessage& message, Seen& seen, Tally& tally) {
    note_hud(message, seen);
    if (const auto* reject = std::get_if<protocol::Reject>(&message)) {
        std::println(stderr, "  server từ chối tin 0x{:04x}: mã {}", reject->request,
            static_cast<unsigned>(reject->code));
    }
    if (const auto* bye = std::get_if<protocol::Goodbye>(&message)) {
        std::println(stderr, "  server đóng phiên: lý do {}", static_cast<unsigned>(bye->reason));
    }
    const auto* denied = std::get_if<protocol::Reject>(&message);
    const bool is_far = denied != nullptr && denied->code == protocol::ErrorCode::kOutOfRange;
    if (is_far) ++seen.out_of_range;
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
    const auto* cast = std::get_if<protocol::SkillCast>(&message);
    const bool is_mine = cast != nullptr && cast->seq != 0;
    if (is_mine) ++tally.casts;
    if (is_mine) seen.out_of_range = 0;
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

using Goal = std::pair<float, float>;

// Một chặng đi thẳng: tới khi cách `goal` (centimet) không quá `close_cm` hoặc hết `limit`.
struct Leg {
    Goal goal;
    float close_cm = 0.0F;
    std::chrono::seconds limit{0};
};

// Đọc mọi tin trong một khung 33 ms. Position kéo về thì đặt lại vị trí như client thật.
void drain_frame(link::Link& line, Seen& seen, Tally& tally) {
    const auto frame_end = Clock::now() + std::chrono::milliseconds{33};
    while (Clock::now() < frame_end) {
        const auto message = read_game(line, net::Milliseconds{3});
        if (!message) continue;
        note(*message, seen, tally);
        const auto* spot = std::get_if<protocol::Position>(&*message);
        if (spot == nullptr) continue;
        ++tally.corrections;
        seen.x_cm = spot->x_cm;
        seen.z_cm = spot->z_cm;
    }
}

// Đi thẳng một chặng, tối đa 10 cm mỗi bước, 30 bước mỗi giây, vẫn đọc mọi tin. Bước cuối chỉ đi
// đúng phần còn lại để đứng đúng điểm rẽ: điểm rẽ của luật client cách vật cản 10 cm, đứng lệch 12
// cm là đã vào vật cản và zone kéo về. Trả đúng khi tới nơi, sai khi hết hạn hay phiên đóng.
[[nodiscard]] bool go_leg(link::Link& line, Seen& seen, Tally& tally, const Leg& leg,
    std::uint32_t& tick) {
    constexpr float kStepCm = 10.0F;
    const auto give_up = Clock::now() + leg.limit;
    while (Clock::now() < give_up && !seen.refused) {
        const float gap = std::hypot(leg.goal.first - seen.x_cm, leg.goal.second - seen.z_cm);
        if (gap <= leg.close_cm) return true;
        ++tick;
        const float stride = std::min(kStepCm, gap);
        const float heading = std::atan2(leg.goal.second - seen.z_cm, leg.goal.first - seen.x_cm);
        seen.x_cm += stride * std::cos(heading);
        seen.z_cm += stride * std::sin(heading);
        const protocol::Move step{.x_cm = seen.x_cm, .z_cm = seen.z_cm, .tick = tick};
        if (!send(line, step)) return false;
        drain_frame(line, seen, tally);
    }
    return false;
}

// Một đơn vị game là 100 cm.
constexpr float kCmPerUnit = 100.0F;

// Các điểm rẽ client sẽ đi từ chỗ đang đứng tới `goal`: cùng luật nav::Field::plan_move với client
// thật (nhấp chuột, tìm đường vòng vật cản). Rỗng khi lệnh đi bị từ chối.
[[nodiscard]] nav::Path plan_route(const nav::Field& field, const Seen& seen, Goal goal) {
    const nav::Point from{.x = seen.x_cm / kCmPerUnit, .z = seen.z_cm / kCmPerUnit};
    const nav::Point to{.x = goal.first / kCmPerUnit, .z = goal.second / kCmPerUnit};
    const nav::Segment walk{.start = from, .end = to};
    const nav::MoveAsk ask{.walk = walk, .mode = nav::MoveMode::kFind};
    nav::Scratch scratch;
    return field.plan_move(ask, scratch);
}

constexpr float kNodeCm = 2.0F;

// Hạn cho một chặng dài `gap` cm: 250 cm mỗi giây (bot đi 300 cm mỗi giây) cộng dư 10 giây. Hạn cố
// định 20 giây ngắn hơn một đoạn 61 m của lộ trình: bot bỏ giữa đường, quay sang điểm rẽ kế và đâm
// thẳng vào vật cản.
[[nodiscard]] std::chrono::seconds time_for(float gap) {
    constexpr float kCmPerSecond = 250.0F;
    constexpr int kSpareSeconds = 10;
    return std::chrono::seconds{static_cast<int>(gap / kCmPerSecond) + kSpareSeconds};
}

// Đi tới `spot` cho tới khi cách không quá `stop` cm. false khi không tới được.
[[nodiscard]] bool reach_spot(link::Link& line, Seen& seen, Tally& tally, Goal spot, float stop,
    std::uint32_t& tick) {
    const float gap = std::hypot(spot.first - seen.x_cm, spot.second - seen.z_cm);
    const Leg leg{.goal = spot, .close_cm = stop, .limit = time_for(gap)};
    return go_leg(line, seen, tally, leg, tick);
}

// Chỗ cách `from` đúng `radius` cm, theo hướng thứ `index` trong `count` hướng đều nhau.
[[nodiscard]] Goal spot_at(Goal from, float radius, int index, int count) {
    constexpr float kTurn = 2.0F * std::numbers::pi_v<float>;
    const float heading = kTurn * static_cast<float>(index) / static_cast<float>(count);
    return Goal{from.first + radius * std::cos(heading), from.second + radius * std::sin(heading)};
}

// Chỗ cách khách đúng `radius` cm, theo hướng thứ `index` trong `count` hướng đều nhau.
[[nodiscard]] Goal ring_spot(const Seen& seen, float radius, int index, int count) {
    return spot_at(Goal{seen.x_cm, seen.z_cm}, radius, index, count);
}

// Trong các chỗ trên vòng bán kính `radius` mà luật đi client cho tới được, chỗ gần `goal` nhất.
[[nodiscard]] std::optional<Goal> best_on_ring(const nav::Field& field, const Seen& seen, Goal goal,
    float radius) {
    constexpr int kHeadings = 16;
    std::optional<Goal> best;
    float best_gap = 0.0F;
    for (int i = 0; i < kHeadings; ++i) {
        const Goal spot = ring_spot(seen, radius, i, kHeadings);
        if (plan_route(field, seen, spot).empty()) continue;
        const float gap = std::hypot(goal.first - spot.first, goal.second - spot.second);
        if (best && gap >= best_gap) continue;
        best = spot;
        best_gap = gap;
    }
    return best;
}

// Đứng trong vật cản (điểm sinh nằm trên tam giác vật cản) thì luật client chỉ cho đi thẳng ra qua
// một cạnh: người chơi bấm gần trước. Bước ra chỗ đi được gần nhất về phía `goal`; false khi không
// có.
[[nodiscard]] bool step_out(link::Link& line, Seen& seen, Tally& tally, Goal goal,
    std::uint32_t& tick) {
    for (const float radius : {100.0F, 200.0F, 400.0F}) {
        const std::optional<Goal> spot = best_on_ring(*seen.field, seen, goal, radius);
        if (!spot) continue;
        return reach_spot(line, seen, tally, *spot, kNodeCm, tick);
    }
    return false;
}

// Các điểm rẽ theo luật client; kẹt trong vật cản thì bước ra rồi tính lại. Rỗng khi client từ
// chối.
[[nodiscard]] nav::Path route_of(link::Link& line, Seen& seen, Tally& tally, Goal goal,
    std::uint32_t& tick) {
    nav::Path route = plan_route(*seen.field, seen, goal);
    if (!route.empty()) return route;
    if (!step_out(line, seen, tally, goal, tick)) return route;
    return plan_route(*seen.field, seen, goal);
}

void report_goal(std::string_view what, Goal goal) {
    constexpr std::string_view kFormat = "  {} ({:.0f}, {:.0f})";
    std::println(kFormat, what, goal.first, goal.second);
}

// Không có lưới đi: đi thẳng tới `goal`, vướng vật cản của zone như --straight. Trả đúng khi tới
// nơi.
bool go_straight(link::Link& line, Seen& seen, Tally& tally, Goal goal, float close,
    std::uint32_t& tick) {
    constexpr std::chrono::seconds kLongLimit{120};
    const Leg leg{.goal = goal, .close_cm = close, .limit = kLongLimit};
    return go_leg(line, seen, tally, leg, tick);
}

// Đi tới `goal` cho tới khi cách không quá `close` cm. Có lưới đi (--walk) thì đi theo các điểm rẽ
// của luật đi client rồi dừng ở điểm cuối của lộ trình (đích nằm trong vật cản thì lộ trình dừng
// trước nó, như client), đứng yên khi client từ chối lệnh đi; không có thì đi thẳng. Position kéo
// về thì đặt lại vị trí như client thật. Trả đúng khi đã đi hết lộ trình (hay tới nơi khi đi
// thẳng).
bool go(link::Link& line, Seen& seen, Tally& tally, Goal goal, float close, std::uint32_t& tick) {
    const bool is_straight = seen.field == nullptr;
    if (is_straight) return go_straight(line, seen, tally, goal, close, tick);
    const nav::Path route = route_of(line, seen, tally, goal, tick);
    if (route.empty()) report_goal("client từ chối lệnh đi tới", goal);
    if (route.empty()) return false;
    for (std::size_t at = 0; at < route.size(); ++at) {
        const Goal spot{route[at].x * kCmPerUnit, route[at].z * kCmPerUnit};
        const bool is_final = at + 1 == route.size();
        const float stop = is_final ? close : kNodeCm;
        const bool is_reached = reach_spot(line, seen, tally, spot, stop, tick);
        if (!is_reached) report_goal("không tới được điểm rẽ", spot);
        if (!is_reached) return false;
    }
    return true;
}

// Gửi Ping khi tới hạn `due`; trả hạn kế (mỗi giây một lần) để giữ phiên.
[[nodiscard]] Clock::time_point keep_alive(link::Link& line, Clock::time_point due) {
    if (Clock::now() < due) return due;
    const protocol::Ping beat{.client_time = std::chrono::milliseconds{0}};
    static_cast<void>(send(line, beat));
    return due + std::chrono::seconds{1};
}

// Đứng yên `seconds` giây, đọc mọi tin và Ping mỗi giây.
void stand(link::Link& line, Seen& seen, Tally& tally, int seconds) {
    const auto until = Clock::now() + std::chrono::seconds{seconds};
    auto next_ping = Clock::now();
    while (Clock::now() < until && !seen.refused) {
        next_ping = keep_alive(line, next_ping);
        const auto message = read_game(line, net::Milliseconds{20});
        if (message) note(*message, seen, tally);
    }
}

// Chế độ --peers: đứng xem rồi thoát êm; phiên bị server đóng giữa chừng thì tính một lỗi.
void watch(link::Link& line, Seen& seen, Tally& tally, std::string_view account, int seconds) {
    stand(line, seen, tally, seconds);
    if (seen.refused) report(account, "bị server đóng giữa chừng");
    if (seen.refused) ++tally.failed;
    if (!seen.refused) static_cast<void>(send(line, protocol::Logout{}));
}

// Đi thẳng tới `goal` rồi đứng lại `seconds` giây.
void hunt(link::Link& line, Seen& seen, Tally& tally, const protocol::Position& start,
    std::pair<float, float> goal, int seconds) {
    constexpr float kCloseCm = 300.0F;
    seen.x_cm = start.x_cm;
    seen.z_cm = start.z_cm;
    std::uint32_t tick = 0;
    go(line, seen, tally, goal, kCloseCm, tick);
    std::println("  tới ({:.0f}, {:.0f}) cm, còn cách đích {:.0f} cm", seen.x_cm, seen.z_cm,
        std::hypot(goal.first - seen.x_cm, goal.second - seen.z_cm));
    stand(line, seen, tally, seconds);
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

// ---- Chế độ --hud: các tin của HUD (G2-M) -------------------------------------------------------

void want(Tally& tally, std::string_view what, bool is_right) {
    std::println("  hud: {} — {}", what, is_right ? "đạt" : "SAI");
    if (!is_right) ++tally.failed;
}

// Có đủ EntityVitals và BuffList mang đúng id đã hỏi.
[[nodiscard]] bool answered_whole(const Seen& seen, std::uint32_t id) {
    const auto vitals = seen.vitals.find(id);
    const bool has_vitals = vitals != seen.vitals.end() && vitals->second.id == id;
    const auto buffs = seen.buffs.find(id);
    const bool has_buffs = buffs != seen.buffs.end() && buffs->second.id == id;
    return has_vitals && has_buffs;
}

// Hỏi một mục tiêu: xoá tin cũ, gửi AskTarget, chờ tối đa 1 giây cho câu đáp (hay Reject).
void ask_target(link::Link& line, Seen& seen, Tally& tally, std::uint32_t id) {
    seen.vitals.clear();
    seen.buffs.clear();
    seen.last_reject.reset();
    const protocol::AskTarget ask{.id = id};
    static_cast<void>(send(line, ask));
    const auto is_done = [&] { return answered_whole(seen, id) || seen.last_reject.has_value(); };
    listen(line, seen, tally, std::chrono::seconds{1}, is_done);
}

[[nodiscard]] const protocol::BuffEntry* first_buff(const Seen& seen, std::uint32_t id) {
    const auto found = seen.buffs.find(id);
    if (found == seen.buffs.end()) return nullptr;
    if (found->second.buffs.empty()) return nullptr;
    return &found->second.buffs.front();
}

// Chọn chính mình rồi ra chiêu 35 (打坐) lên mình: nó sinh một buff, nên BuffList cuối cùng của
// mình phải mang buff do mình gây từ chiêu 35. Nếu bản rút gọn của mục tiêu đè lên bản đủ thì
// người gây và chiêu về 0 (lỗi c5 tìm thấy). Hỏi lại chính mình thì bản trả về phải đủ như
// cũ.
void sit_down(link::Link& line, Seen& seen, Tally& tally) {
    constexpr std::uint16_t kSit = 35;
    ask_target(line, seen, tally, seen.self_id);
    protocol::CastSkill cast{};
    cast.seq = 1;
    cast.skill = kSit;
    cast.target = seen.self_id;
    static_cast<void>(send(line, cast));
    const auto has_buff = [&] { return first_buff(seen, seen.self_id) != nullptr; };
    listen(line, seen, tally, std::chrono::seconds{2}, has_buff);
    const auto never = [] { return false; };
    listen(line, seen, tally, std::chrono::milliseconds{300}, never);
    const protocol::BuffEntry* own = first_buff(seen, seen.self_id);
    const bool is_own = own != nullptr && own->sender == seen.self_id && own->skill == kSit;
    want(tally, "chọn mình rồi ngồi: BuffList mình mang người gây và chiêu 35", is_own);
    if (own == nullptr) return;
    const protocol::BuffEntry sent = *own;
    std::println("  hud: buff chiêu 35: effect {} SN {}", sent.effect, sent.serial);
    std::println("  hud: buff chiêu 35: còn {} ms", sent.remaining_ms);
    ask_target(line, seen, tally, seen.self_id);
    const protocol::BuffEntry* again = first_buff(seen, seen.self_id);
    const bool has_again = again != nullptr;
    const bool is_effect = has_again && again->effect == sent.effect;
    const bool is_same = is_effect && again->serial == sent.serial;
    want(tally, "AskTarget chính mình sau khi ngồi: cùng buff và SN", is_same);
    const bool is_whole = is_same && again->sender == seen.self_id && again->skill == kSit;
    want(tally, "bản trả về cho chính mình vẫn đủ người gây và chiêu", is_whole);
}

[[nodiscard]] std::optional<std::uint32_t> other_entity(const Seen& seen) {
    if (!seen.monsters.empty()) return seen.monsters.begin()->first;
    if (!seen.npcs.empty()) return seen.npcs.begin()->first;
    return std::nullopt;
}

[[nodiscard]] std::vector<std::uint16_t> held_skills(const Seen& seen) {
    std::vector<std::uint16_t> held;
    for (const protocol::SkillEntry& entry : seen.skills)
        held.push_back(entry.skill);
    return held;
}

[[nodiscard]] std::int64_t primary_sum(const protocol::SelfStats& stats) {
    const std::int64_t body = std::int64_t{stats.strength} + stats.constitution + stats.dexterity;
    return body + stats.spirit + stats.concentration;
}

void show_stats(const protocol::SelfStats& now) {
    std::println("  hud: cấp {} kinh nghiệm {} phái {}", now.level, now.exp, now.sect);
    std::println("  hud: STR {} SPR {} CON {}", now.strength, now.spirit, now.constitution);
    std::println("  hud: INT {} DEX {}", now.concentration, now.dexterity);
    std::println("  hud: điểm tự do {}", now.free_points);
    std::println("  hud: công ngoại {} thủ ngoại {}", now.physical_attack, now.physical_defence);
    std::println("  hud: công nội {} thủ nội {}", now.magic_attack, now.magic_defence);
    std::println("  hud: trúng {} né {} hội tâm {}", now.hit, now.miss, now.critical_hit);
    std::println("  hud: liên kích {} tốc độ đánh {}", now.strike_point, now.attack_speed);
    std::println("  hud: tốc độ chạy {} hồi HP {}", now.move_speed, now.hp_restore);
    std::println("  hud: hồi MP {}", now.mp_restore);
}

// Kiểm tin HUD của máy chủ: thuộc tính, sáu chiêu đầu, canh giờ, buff của mình và AskTarget. Nhận
// canh giờ thứ hai chỉ khi --seconds đủ dài (một canh dài 150 giây theo zone.toml).
void hud(link::Link& line, Seen& seen, Tally& tally, int seconds) {
    constexpr int kSettleSeconds = 2;
    constexpr int kChangeSeconds = 155;
    constexpr std::uint32_t kStranger = 0xDEADBEEFU;
    seen.tolerate_reject = true;
    stand(line, seen, tally, kSettleSeconds);
    const bool has_stats = seen.stats.has_value();
    const bool is_primary_set = has_stats && primary_sum(*seen.stats) > 0;
    want(tally, "SelfStats có mặt và đủ thuộc tính chính", is_primary_set);
    if (has_stats) show_stats(*seen.stats);
    const std::vector<std::uint16_t> starting = {0, 1, 21, 22, 34, 35};
    want(tally, "SelfSkills đúng sáu chiêu DefaultChar", held_skills(seen) == starting);
    const bool has_hour = !seen.hours.empty() && seen.hours.front() <= 11;
    want(tally, "WorldTime sau SceneEnter, canh 0..11", has_hour);
    want(tally, "BuffList của chính mình khi vào cảnh", seen.buffs.contains(seen.self_id));
    ask_target(line, seen, tally, seen.self_id);
    const bool is_self_answered = answered_whole(seen, seen.self_id);
    want(tally, "AskTarget chính mình đáp EntityVitals và BuffList", is_self_answered);
    const std::optional<std::uint32_t> other = other_entity(seen);
    want(tally, "có thực thể khác trong vùng nhìn", other.has_value());
    if (other) ask_target(line, seen, tally, *other);
    const bool is_other_answered = other && answered_whole(seen, *other);
    if (other) want(tally, "AskTarget thực thể khác đáp đủ hai tin", is_other_answered);
    ask_target(line, seen, tally, kStranger);
    const bool is_unknown = seen.last_reject == protocol::ErrorCode::kNoSuchEntity;
    want(tally, "AskTarget id lạ bị từ chối kNoSuchEntity", is_unknown);
    ask_target(line, seen, tally, 0);
    want(tally, "AskTarget 0 là bỏ chọn, không đáp", seen.vitals.empty() && !seen.last_reject);
    sit_down(line, seen, tally);
    if (seconds < kChangeSeconds) return;
    stand(line, seen, tally, seconds);
    const bool has_next = seen.hours.size() >= 2 && seen.hours[1] == (seen.hours[0] + 1) % 12;
    want(tally, "WorldTime đổi canh sau một chu kỳ", has_next);
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
        if (seen.unreachable.contains(id)) continue;
        const float gap = std::hypot(monster.x_cm - seen.x_cm, monster.z_cm - seen.z_cm);
        if (best && gap >= best_gap) continue;
        best = std::pair{id, monster};
        best_gap = gap;
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

// Tầm đứng cách quái khi ra chiêu: 150 cm, sát hơn một nửa sau mỗi hai lần server báo ngoài tầm (mã
// 31), tối thiểu 20 cm.
[[nodiscard]] float reach_for(int refusals) {
    constexpr float kFirstCm = 150.0F;
    constexpr float kLeastCm = 20.0F;
    const float shrunk = kFirstCm / static_cast<float>(1 << (refusals / 2));
    return std::max(shrunk, kLeastCm);
}

// Một đợt đánh: chiêu, quái đang nhắm, số chiêu đã ra cho quái này và hạn chót của cả lượt săn.
struct Strike {
    std::uint16_t skill = 0;
    std::uint16_t seq = 0;
    std::uint32_t target = 0;
    int casts = 0;
    Clock::time_point deadline;
};

// Đứng sát quái `strike.target` rồi ra chiêu tới khi nó chết. Trả đúng khi chết. Không chết thì
// quái bị ghi vào `unreachable` (đi không tới, server báo ngoài tầm kGiveUp lần liên tiếp dù đã
// đứng sát nhất, hay quá kMaxCasts chiêu).
[[nodiscard]] bool engage(link::Link& line, Seen& seen, Tally& tally, Strike& strike,
    std::uint32_t& tick) {
    constexpr int kMaxCasts = 40;
    constexpr int kGiveUp = 8;
    constexpr std::chrono::milliseconds kBetween{1400};
    const int deaths_before = tally.deaths.load();
    const auto is_dead = [&] { return tally.deaths.load() != deaths_before; };
    seen.out_of_range = 0;
    strike.casts = 0;
    for (int round = 0; round < kMaxCasts; ++round) {
        const auto current = seen.monsters.find(strike.target);
        if (current == seen.monsters.end()) break;
        if (seen.refused || Clock::now() >= strike.deadline) break;
        if (seen.out_of_range >= kGiveUp) break;
        const std::pair spot{current->second.x_cm, current->second.z_cm};
        const bool is_near = go(line, seen, tally, spot, reach_for(seen.out_of_range), tick);
        if (!is_near) break;
        const protocol::CastSkill cast{
            .seq = ++strike.seq, .skill = strike.skill, .target = strike.target};
        const bool is_sent = send(line, cast);
        if (!is_sent) seen.refused = true;
        if (!is_sent) break;
        ++strike.casts;
        // 1,4 giây giữa hai chiêu: đủ hồi chiêu cơ bản và dưới trần mười ý định mỗi giây của
        // server.
        listen(line, seen, tally, kBetween, is_dead);
        if (is_dead()) return true;
    }
    seen.unreachable.insert(strike.target);
    return false;
}

void report_empty(const Seen& seen) {
    std::println("  không còn quái sống quanh ({:.0f}, {:.0f})", seen.x_cm, seen.z_cm);
}

void report_pick(const Seen& seen) {
    const std::size_t slots = seen.bag ? seen.bag->slots.size() : 0U;
    std::println("  nhặt được vật rơi, túi có {} ô", slots);
}

// Săn quái ở `goal`: giết tối đa kMaxKills con (dừng sớm khi đã nhặt được một món hoặc hết
// `seconds` giây), mỗi con đánh bằng kỹ năng đầu tiên trong SelfSkills.
void fight(link::Link& line, Seen& seen, Tally& tally, const protocol::Position& start,
    std::pair<float, float> goal, int seconds) {
    constexpr float kCloseCm = 300.0F;
    constexpr int kMaxKills = 12;
    seen.x_cm = start.x_cm;
    seen.z_cm = start.z_cm;
    seen.tolerate_reject = true;
    std::uint32_t tick = 0;
    go(line, seen, tally, goal, kCloseCm, tick);
    listen(line, seen, tally, std::chrono::milliseconds{1500}, [] { return false; });
    if (seen.skills.empty()) {
        std::println("  SelfSkills rỗng: nhân vật chưa có kỹ năng");
        return;
    }
    Strike strike;
    strike.skill = seen.skills.front().skill;
    strike.deadline = Clock::now() + std::chrono::seconds{seconds};
    std::println("  ra chiêu {} (cấp {})", strike.skill, seen.skills.front().level);
    for (int kills = 0; kills < kMaxKills && tally.picked.load() == 0 && !seen.refused; ++kills) {
        const auto target = nearest_monster(seen);
        if (!target) report_empty(seen);
        if (!target) break;
        strike.target = target->first;
        if (!engage(line, seen, tally, strike, tick)) continue;
        std::println("  quái {:#x} chết sau {} chiêu", strike.target, strike.casts);
        listen(line, seen, tally, std::chrono::milliseconds{800}, [] { return false; });
        if (collect(line, seen, tally, tick)) report_pick(seen);
    }
    if (Clock::now() >= strike.deadline) std::println("  hết {} giây săn quái", seconds);
}

// ---- Chế độ --leap: một Move dài xuyên tường (B19) ---------------------------------------------

constexpr int kIdleMs = 2200;
constexpr std::uint32_t kLeapTick = 70;
constexpr float kLeapSampleCm = 20.0F;
constexpr float kLeapSlackCm = 20.0F;

// Điểm đứng được của lưới tam giác: nằm trong một tam giác đi được.
[[nodiscard]] bool is_open(const nav::Mesh& mesh, Goal spot) {
    const nav::Point point{.x = spot.first / kCmPerUnit, .z = spot.second / kCmPerUnit};
    return nav::locate(mesh, point, nav::Ground::kOpen).has_value();
}

// Luật đi của zone (zone/content.cpp walkable_of): đi được khi chính điểm đó hoặc điểm lệch 20 cm
// theo bốn hướng nằm trong tam giác đi được.
[[nodiscard]] bool zone_stands(const nav::Mesh& mesh, Goal spot) {
    if (is_open(mesh, spot)) return true;
    const float right = spot.first + kLeapSlackCm;
    const float left = spot.first - kLeapSlackCm;
    const float above = spot.second + kLeapSlackCm;
    const float below = spot.second - kLeapSlackCm;
    if (is_open(mesh, Goal{right, spot.second})) return true;
    if (is_open(mesh, Goal{left, spot.second})) return true;
    if (is_open(mesh, Goal{spot.first, above})) return true;
    return is_open(mesh, Goal{spot.first, below});
}

// Đoạn from→to có một điểm mẫu (cách nhau 20 cm, như zone/scene.cpp) mà zone coi là không đi được.
[[nodiscard]] bool has_gap(const nav::Mesh& mesh, Goal from, Goal to) {
    const float length = std::hypot(to.first - from.first, to.second - from.second);
    const int samples = static_cast<int>(std::ceil(length / kLeapSampleCm));
    for (int at = 1; at <= samples; ++at) {
        const float along = std::min(1.0F, static_cast<float>(at) * kLeapSampleCm / length);
        const float spot_x = from.first + ((to.first - from.first) * along);
        const float spot_z = from.second + ((to.second - from.second) * along);
        if (!zone_stands(mesh, Goal{spot_x, spot_z})) return true;
    }
    return false;
}

// Hai đích cùng khoảng cách: `wall` đi được nhưng đoạn thẳng tới đó xuyên vật cản, `clear` thông
// hẳn.
struct Leap {
    Goal wall;
    Goal clear;
    float reach_cm = 0.0F;
};

// Cặp đích đầu tiên trên vòng bán kính `reach` (16 hướng quanh `from`); reach_cm là 0 khi thiếu một
// loại.
[[nodiscard]] Leap leap_on_ring(const nav::Mesh& mesh, Goal from, float reach) {
    constexpr int kHeadings = 16;
    std::optional<Goal> wall;
    std::optional<Goal> clear;
    for (int i = 0; i < kHeadings; ++i) {
        const Goal spot = spot_at(from, reach, i, kHeadings);
        if (!zone_stands(mesh, spot)) continue;
        const bool is_gap = has_gap(mesh, from, spot);
        if (is_gap && !wall) wall = spot;
        if (!is_gap && !clear) clear = spot;
    }
    if (!wall || !clear) return Leap{};
    return Leap{.wall = *wall, .clear = *clear, .reach_cm = reach};
}

// Thử các khoảng 400, 600, 800 cm (dưới giới hạn của 2,2 giây đứng yên, khoảng 1000 cm) cho tới khi
// có đủ cặp đích.
[[nodiscard]] std::optional<Leap> pick_leap(const nav::Mesh& mesh, Goal from) {
    for (const float reach : {400.0F, 600.0F, 800.0F}) {
        const Leap leap = leap_on_ring(mesh, from, reach);
        if (leap.reach_cm > 0.0F) return leap;
    }
    return std::nullopt;
}

// Đọc tin trong `span`, mỗi lượt một khung 33 ms.
void drain_for(link::Link& line, Seen& seen, Tally& tally, std::chrono::milliseconds span) {
    const auto end = Clock::now() + span;
    while (Clock::now() < end && !seen.refused) {
        drain_frame(line, seen, tally);
    }
}

// Đứng yên kIdleMs cho giới hạn từng bước đủ dài, gửi một Move tới `target`, đọc thêm 700 ms. true
// khi bị đặt lại (nhận Position).
[[nodiscard]] bool leap_pulled(link::Link& line, Seen& seen, Tally& tally, Goal target) {
    drain_for(line, seen, tally, std::chrono::milliseconds{kIdleMs});
    const int before = tally.corrections.load();
    const protocol::Move move{.x_cm = target.first, .z_cm = target.second, .tick = kLeapTick};
    if (!send(line, move)) return false;
    drain_for(line, seen, tally, std::chrono::milliseconds{700});
    return tally.corrections.load() > before;
}

// Chạy --leap từ chỗ vừa vào cảnh: nhảy tới điểm sau tường phải bị đặt lại, nhảy tới điểm thông
// cùng khoảng thì không. Cần --walk để biết chỗ nào là tường.
void run_leap(link::Link& line, Seen& seen, Tally& tally, std::string_view account) {
    if (seen.field == nullptr) return report(account, "--leap cần --walk <walk.path>");
    seen.x_cm = seen.position->x_cm;
    seen.z_cm = seen.position->z_cm;
    const Goal from{seen.x_cm, seen.z_cm};
    const std::optional<Leap> leap = pick_leap(seen.field->mesh(), from);
    if (!leap) return report(account, "không thấy cặp điểm tường và thông quanh điểm sinh");
    const bool is_wall_pulled = leap_pulled(line, seen, tally, leap->wall);
    const bool is_clear_pulled = leap_pulled(line, seen, tally, leap->clear);
    const bool is_right = is_wall_pulled && !is_clear_pulled;
    if (is_right) ++tally.leaped;
    const std::string_view wall_fate = is_wall_pulled ? "bị đặt lại" : "lọt qua";
    const std::string_view open_fate = is_clear_pulled ? "bị đặt lại" : "được nhận";
    const float reach = leap->reach_cm;
    std::println("[{}] leap {:.0f} cm: tường {}, thông {}", account, reach, wall_fate, open_fate);
}

// Nhân vật nam mới với lựa chọn nằm trong danh sách tạo được: mặt 100, tóc 5 (store.toml), ảnh chân
// dung 52 (đầu bảng của nam trong portraits.tsv) và bộ đồ tân thủ 0.
[[nodiscard]] protocol::CreateCharacter novice(const std::string& name) {
    protocol::CreateCharacter create;
    create.name = name;
    create.gender = protocol::Gender::kMale;
    create.face = 100;
    create.hair = 5;
    create.portrait = 52;
    create.equip_set = 0;
    return create;
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
    seen.field = options.field.get();
    for (int round = 0; round < 8 && !seen.roster && !seen.refused; ++round) {
        const auto message = read_game(*line, kStep);
        if (!message) return fail("không nhận được danh sách nhân vật");
        note(*message, seen, tally);
    }
    if (!seen.roster) return fail("Login bị từ chối");
    if (seen.roster->characters.empty()) {
        const std::string name = std::format("{}nv{}", options.prefix, index);
        const protocol::CreateCharacter create = novice(name);
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
    if (options.peers > 0) return watch(*line, seen, tally, account, options.seconds);
    const float share = static_cast<float>(index) / static_cast<float>(options.count);
    const float heading = 2.0F * std::numbers::pi_v<float> * share;
    if (options.leap) return run_leap(*line, seen, tally, account);
    if (options.hud) return hud(*line, seen, tally, options.seconds);
    bool walked = true;
    if (options.fight) {
        fight(*line, seen, tally, *seen.position, *options.fight, options.seconds);
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

// ---- Chế độ --roster: tạo và xoá nhân vật, in mã server trả cho từng bước ----------------------

// Một kết nối đã đăng nhập cùng danh sách nhân vật mới nhất server gửi về.
struct Session {
    link::Link line;
    protocol::CharacterList roster;
};

// Kết quả một lệnh: danh sách mới (is_done) hoặc mã của Reject.
struct Reply {
    bool is_done = false;
    protocol::ErrorCode code = protocol::ErrorCode::kMalformed;
};

// Hai tài khoản và số bước sai. mine giữ nhân vật thử; other chỉ để lấy một id của người khác.
struct Rig {
    Session mine;
    Session other;
    std::string prefix;
    int wrong = 0;
};

// Cách lần xoá trước hơn 500 ms của gate (kDeleteGapNs) một chút.
constexpr std::chrono::milliseconds kBeyondGap{700};

// Đọc tới khi có CharacterList hoặc Reject; Goodbye hay im lặng là nullopt.
[[nodiscard]] std::optional<Reply> await_roster(Session& session) {
    for (int round = 0; round < 8; ++round) {
        const auto message = read_game(session.line, kStep);
        if (!message) return std::nullopt;
        if (std::holds_alternative<protocol::Goodbye>(*message)) return std::nullopt;
        const auto* list = std::get_if<protocol::CharacterList>(&*message);
        const auto* reject = std::get_if<protocol::Reject>(&*message);
        if (list != nullptr) session.roster = *list;
        if (list != nullptr) return Reply{.is_done = true};
        if (reject != nullptr) return Reply{.is_done = false, .code = reject->code};
    }
    return std::nullopt;
}

template <typename Message>
[[nodiscard]] std::optional<Reply> ask(Session& session, const Message& message) {
    if (!send(session.line, message)) return std::nullopt;
    return await_roster(session);
}

[[nodiscard]] std::optional<Session> open_session(const Options& options,
    const secure::PublicKey& server, const std::string& account) {
    const std::optional<std::string> ticket = ticket_for(options, server, account);
    if (!ticket) return std::nullopt;
    std::optional<link::Link> line = dial(options.game_port, server);
    if (!line) return std::nullopt;
    const protocol::Login login{.account = account, .ticket = *ticket};
    if (!send(*line, login)) return std::nullopt;
    Session session{.line = std::move(*line), .roster = {}};
    const std::optional<Reply> got = await_roster(session);
    if (!got || !got->is_done) return std::nullopt;
    return session;
}

[[nodiscard]] std::string describe(const std::optional<Reply>& got) {
    if (!got) return "không có trả lời";
    if (got->is_done) return "thành công";
    return std::format("Reject mã {}", static_cast<unsigned>(got->code));
}

void judge(Rig& rig, std::string_view step, bool is_right, const std::string& seen) {
    const std::string_view mark = is_right ? "đúng" : "SAI";
    std::println("  {} {}: {}", mark, step, seen);
    if (!is_right) ++rig.wrong;
}

void want_refusal(Rig& rig, std::string_view step, const std::optional<Reply>& got,
    protocol::ErrorCode want) {
    const bool is_refused = got.has_value() && !got->is_done;
    const bool is_right = is_refused && got->code == want;
    const std::string shown = describe(got);
    const auto wanted = static_cast<unsigned>(want);
    const std::string seen = std::format("{}, mong mã {}", shown, wanted);
    judge(rig, step, is_right, seen);
}

void want_done(Rig& rig, std::string_view step, const std::optional<Reply>& got, std::size_t count,
    bool can_create) {
    const protocol::CharacterList& roster = rig.mine.roster;
    const bool is_done = got.has_value() && got->is_done;
    const bool is_count = roster.characters.size() == count;
    const bool is_shaped = is_count && roster.can_create == can_create;
    const std::string shown = describe(got);
    const std::size_t size = roster.characters.size();
    const bool open = roster.can_create;
    const std::string seen = std::format("{}, {} nhân vật, can_create={}", shown, size, open);
    judge(rig, step, is_done && is_shaped, seen);
}

void create_one(Rig& rig, std::string_view suffix, std::size_t count, bool can_create) {
    const std::string name = std::format("{}r{}", rig.prefix, suffix);
    const std::optional<Reply> got = ask(rig.mine, novice(name));
    const std::string step = std::format("tạo {}", name);
    want_done(rig, step, got, count, can_create);
}

[[nodiscard]] std::uint64_t id_at(const Session& session, std::size_t at) {
    return session.roster.characters.at(at).id;
}

void delete_one(Rig& rig, std::string_view step, std::uint64_t id, protocol::ErrorCode want) {
    const protocol::DeleteCharacter request{.character = id};
    const std::optional<Reply> got = ask(rig.mine, request);
    want_refusal(rig, step, got, want);
}

// Vào game bằng nhân vật `id`: chờ tới Position (gate đã mở phiên và attach zone).
[[nodiscard]] bool enter_game(Session& session, std::uint64_t id) {
    if (!send(session.line, protocol::EnterGame{.character = id})) return false;
    for (int round = 0; round < 16; ++round) {
        const auto message = read_game(session.line, kStep);
        if (!message) return false;
        if (std::holds_alternative<protocol::Position>(*message)) return true;
        if (std::holds_alternative<protocol::Reject>(*message)) return false;
    }
    return false;
}

// Ba nhân vật là trần (can_create tắt); xoá id của người khác và xoá lại id đã xoá đều NOT_OWNER.
void fill_and_trim(Rig& rig) {
    create_one(rig, "a", 1, true);
    create_one(rig, "b", 2, true);
    create_one(rig, "c", 3, false);
    const std::uint64_t first = id_at(rig.mine, 0);
    const std::string other_name = rig.prefix + "xa";
    const std::optional<Reply> made = ask(rig.other, novice(other_name));
    const std::uint64_t foreign = id_at(rig.other, 0);
    const protocol::ErrorCode not_owner = protocol::ErrorCode::kNoSuchCharacter;
    delete_one(rig, "xoá id của tài khoản khác", foreign, not_owner);
    std::this_thread::sleep_for(kBeyondGap);
    const protocol::DeleteCharacter own{.character = first};
    const std::optional<Reply> gone = ask(rig.mine, own);
    want_done(rig, "xoá nhân vật của mình", gone, 2, true);
    std::this_thread::sleep_for(kBeyondGap);
    delete_one(rig, "xoá lại id đã xoá", first, not_owner);
    std::this_thread::sleep_for(kBeyondGap);
    const bool is_made = made.has_value() && made->is_done;
    judge(rig, "tài khoản kia tạo được nhân vật", is_made, describe(made));
}

void want_gone(Rig& rig, std::string_view step, const std::optional<Reply>& got) {
    const bool is_done = got.has_value() && got->is_done;
    judge(rig, step, is_done, describe(got));
}

// Nhân vật đang chơi: kết nối thứ hai của cùng tài khoản xoá nó phải bị từ chối ONLINE; đăng xuất
// rồi thì xoá được. Dồn hai lần xoá dưới 500 ms thì lần sau OP_TIMES; hết nhân vật thì EMPTY.
void online_and_pace(Rig& rig, const Options& options, const secure::PublicKey& server) {
    const std::uint64_t playing = id_at(rig.mine, 0);
    const std::uint64_t spare = id_at(rig.mine, 1);
    const bool is_in = enter_game(rig.mine, playing);
    const std::string entered = is_in ? "có Position" : "không vào được";
    judge(rig, "vào game bằng nhân vật thứ nhất", is_in, entered);
    const std::string account = rig.prefix + "r";
    std::optional<Session> second = open_session(options, server, account);
    judge(rig, "mở kết nối thứ hai của cùng tài khoản", second.has_value(), "đăng nhập lại");
    if (!second) return;
    const protocol::DeleteCharacter play_request{.character = playing};
    const protocol::DeleteCharacter spare_request{.character = spare};
    const std::optional<Reply> online = ask(*second, play_request);
    want_refusal(rig, "xoá nhân vật đang chơi", online, protocol::ErrorCode::kCharacterOnline);
    static_cast<void>(send(rig.mine.line, protocol::Logout{}));
    std::this_thread::sleep_for(kBeyondGap);
    const std::optional<Reply> freed = ask(*second, spare_request);
    want_gone(rig, "xoá nhân vật dự phòng", freed);
    const std::optional<Reply> quick = ask(*second, play_request);
    want_refusal(rig, "xoá dồn dưới 500 ms", quick, protocol::ErrorCode::kRateLimited);
    std::this_thread::sleep_for(kBeyondGap);
    const std::optional<Reply> last = ask(*second, play_request);
    want_gone(rig, "xoá nhân vật cuối sau khi đăng xuất", last);
    std::this_thread::sleep_for(kBeyondGap);
    const std::optional<Reply> empty = ask(*second, play_request);
    want_refusal(rig, "xoá khi hết nhân vật", empty, protocol::ErrorCode::kNoCharacterToDelete);
}

[[nodiscard]] int run_roster(const Options& options, const secure::PublicKey& server) {
    std::optional<Session> mine = open_session(options, server, options.prefix + "r");
    std::optional<Session> other = open_session(options, server, options.prefix + "x");
    if (!mine || !other) std::println(stderr, "không đăng nhập được hai tài khoản thử");
    if (!mine || !other) return 1;
    Rig rig{.mine = std::move(*mine), .other = std::move(*other), .prefix = options.prefix};
    fill_and_trim(rig);
    online_and_pace(rig, options, server);
    std::println("roster: {} bước sai", rig.wrong);
    return rig.wrong == 0 ? 0 : 1;
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

// --peers <n>: 1 tới 256 người chơi khác phải thấy.
[[nodiscard]] bool take_peers(Options& options, std::string_view text) {
    const std::optional<int> number = whole_number(text);
    if (!number) return false;
    const bool is_in_range = *number >= 1 && *number <= 256;
    if (is_in_range) options.peers = *number;
    return is_in_range;
}

[[nodiscard]] bool take_path(std::filesystem::path& slot, std::string_view text) {
    slot = std::filesystem::path{std::string{text}};
    return !text.empty();
}

[[nodiscard]] bool take_port(std::uint16_t& slot, std::string_view text) {
    const std::optional<std::uint16_t> port = port_number(text);
    if (port) slot = *port;
    return port.has_value();
}

[[nodiscard]] bool take_number(int& slot, std::string_view text) {
    const std::optional<int> number = whole_number(text);
    if (number) slot = *number;
    return number.has_value();
}

// "x_m,z_m" (mét, số nguyên) thành centimet.
[[nodiscard]] bool take_goal(std::optional<Goal>& slot, std::string_view text) {
    const std::size_t comma = text.find(',');
    if (comma == std::string_view::npos) return false;
    const std::optional<int> east = whole_number(text.substr(0, comma));
    const std::optional<int> south = whole_number(text.substr(comma + 1));
    if (!east || !south) return false;
    slot = Goal{static_cast<float>(*east) * kCmPerUnit, static_cast<float>(*south) * kCmPerUnit};
    return true;
}

// Một cặp `--khoá giá trị`; false khi khoá lạ hay giá trị hỏng.
[[nodiscard]] bool take_option(Options& options, std::string_view key, std::string_view value) {
    if (key == "--peers") return take_peers(options, value);
    if (key == "--identity") return take_path(options.identity, value);
    if (key == "--walk") return take_path(options.walk, value);
    if (key == "--game") return take_port(options.game_port, value);
    if (key == "--auth") return take_port(options.auth_port, value);
    if (key == "--count") return take_number(options.count, value);
    if (key == "--seconds") return take_number(options.seconds, value);
    if (key == "--hunt") return take_goal(options.hunt, value);
    if (key == "--talk") return take_goal(options.talk, value);
    if (key == "--fight") return take_goal(options.fight, value);
    if (key == "--prefix") options.prefix = value;
    if (key == "--straight") options.straight = value == "1";
    if (key == "--probe") options.probe = value == "1";
    if (key == "--roster") options.roster = value == "1";
    if (key == "--leap") options.leap = value == "1";
    if (key == "--hud") options.hud = value == "1";
    const bool is_flag = key == "--prefix" || key == "--straight" || key == "--leap";
    return is_flag || key == "--probe" || key == "--roster" || key == "--hud";
}

[[nodiscard]] std::optional<Options> parse(std::span<const char* const> args) {
    Options options;
    for (std::size_t at = 1; at < args.size(); ++at) {
        const std::string_view key = args[at];
        if (at + 1 >= args.size()) return std::nullopt;
        ++at;
        const std::string_view value = args[at];
        if (!take_option(options, key, value)) return std::nullopt;
    }
    const bool is_complete = !options.identity.empty() && options.seconds >= 1;
    const bool is_count_ok = options.count >= 1 && options.count <= 256;
    if (!is_complete || !is_count_ok) return std::nullopt;
    return options;
}

// --walk <walk.path>: nạp lưới đi của cảnh vào một lần, mọi khách dùng chung (chỉ đọc). Cỡ cảnh suy
// từ lưới tra.
[[nodiscard]] bool load_walk(Options& options) {
    if (options.walk.empty()) return true;
    std::ifstream file{options.walk, std::ios::binary};
    const std::istreambuf_iterator<char> first{file};
    const std::vector<char> raw{first, std::istreambuf_iterator<char>{}};
    const std::span<const std::byte> bytes = std::as_bytes(std::span{raw});
    nav::MeshResult mesh = nav::read_mesh(bytes);
    if (!mesh) {
        const std::string_view why = nav::describe(mesh.error());
        std::println(stderr, "không đọc được lưới đi {}: {}", options.walk.string(), why);
        return false;
    }
    const float width = static_cast<float>(mesh->columns * mesh->cell_size);
    const float depth = static_cast<float>(mesh->rows * mesh->cell_size);
    const nav::Area area{.width = width, .depth = depth};
    options.field = std::make_shared<const nav::Field>(std::move(*mesh), area);
    return true;
}

// --probe 1: bắt tay với cổng game, in một dòng `giao thức: bot v<n>, cụm v<m>` rồi thoát. Thoát 1
// khi cụm từ chối bắt tay (cụm cũ hơn bot, hay chưa chạy), để bộ chạy E2E dừng sớm thay vì báo lỗi
// vé.
[[nodiscard]] int probe(const Options& options, const secure::PublicKey& server) {
    constexpr std::uint16_t kBot = protocol::kVersion;
    std::optional<link::Link> line = dial(options.game_port, server);
    if (!line) std::println("giao thức: bot v{}, cụm từ chối bắt tay", kBot);
    if (!line) return 1;
    const std::uint16_t cluster = line->welcome().version;
    std::println("giao thức: bot v{}, cụm v{}", kBot, cluster);
    return 0;
}

void print_usage() {
    std::println(stderr, "dùng: thienlong_bot --identity <khoá> [--game 7100] [--auth 7101]");
    std::println(stderr, "  [--count 4] [--seconds 6] [--prefix bot] [--straight 1] [--peers <n>]");
    std::println(stderr, "  [--probe 1] [--roster 1] [--hunt <x_m>,<z_m>] [--talk <x_m>,<z_m>]");
    std::println(stderr, "  [--fight <x_m>,<z_m>] [--walk <walk.path>] [--leap 1] [--hud 1]");
}

} // namespace

// NOLINTNEXTLINE(bugprone-exception-escape): công cụ thử, hết bộ nhớ thì dừng tiến trình là đủ.
int main(int argc, char** argv) {
    io::use_utf8_console();
    const std::span<const char* const> args{argv, static_cast<std::size_t>(argc)};
    std::optional<Options> options = parse(args);
    if (!options) {
        print_usage();
        return 2;
    }
    if (!load_walk(*options)) return 2;
    const net::NetResult<net::Network> network = net::Network::start();
    if (!network) return 1;
    const secure::Result<secure::Identity> identity = secure::Identity::load(options->identity);
    if (!identity) {
        std::println(stderr, "không đọc được khoá danh tính: {}", secure::describe(identity.error()));
        return 2;
    }
    const secure::PublicKey server = identity->public_key();
    if (options->probe) return probe(*options, server);
    if (options->roster) return run_roster(*options, server);
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
    if (options->peers > 0) {
        const int seen_peers = tally.appear.load();
        std::println("đứng xem: thấy {} người chơi khác, cần {}", seen_peers, options->peers);
        return seen_peers >= options->peers ? 0 : 1;
    }
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
    if (options->leap) {
        std::println("leap: {} trên {} khách bị đặt lại đúng", tally.leaped.load(), options->count);
        return tally.leaped.load() == options->count ? 0 : 1;
    }
    if (options->hud) return 0;
    if (options->straight) return tally.corrections.load() > 0 && tally.drifted.load() == 0 ? 0 : 1;
    // Mỗi khách phải thấy mọi khách khác hiện ra ít nhất một lần.
    if (tally.appear.load() < options->count * want_seen) return 1;
    return 0;
}
