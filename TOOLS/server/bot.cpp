// Khách giả nối vào cụm máy chủ thật: tạo tài khoản, tạo nhân vật, vào game, đi quanh điểm sinh rồi thoát.
// Kiểm đường đi đầy đủ gate -> zone -> gate (SceneEnter, EntityAppear, EntityPos, EntityDisappear) và dùng làm
// nền cho bài đo tải thế giới. Mỗi khách một luồng, mỗi luồng một cặp kết nối (cổng auth rồi cổng game).
//
// Chạy: thienlong_bot --identity <identity.key> [--game 7000] [--auth 7001] [--count 4] [--seconds 6] [--prefix bot]
//       [--straight 1]
// Thoát 0 khi mọi khách vào được cảnh và thấy đủ những khách còn lại; khác 0 kèm lý do.
// --straight 1: mỗi khách đi thẳng một hướng (chia đều 360 độ theo số khách) tới khi bị luật đi của zone chặn, rồi
// đo việc server kéo về: phải có ít nhất một lần kéo về, và mỗi lần kéo về chỉ lùi vài bước so với chỗ khách tưởng
// mình đang đứng (không nhảy đi đâu khác). Khi đó khách không cần thấy nhau (mỗi người đi một hướng, ra khỏi vùng nhìn).
#include "io/platform.hpp"
#include "link/link.hpp"
#include "net/net.hpp"
#include "protocol/messages.hpp"
#include "secure/secure.hpp"

#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <format>
#include <numbers>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <string_view>
#include <thread>
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

struct Seen {
    std::optional<protocol::Position> position;
    std::optional<protocol::CharacterList> roster;
    bool refused = false;
};

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
    if (std::holds_alternative<protocol::Reject>(message) || std::holds_alternative<protocol::Goodbye>(message)) {
        seen.refused = true;
    }
    if (std::holds_alternative<protocol::SceneEnter>(message)) ++tally.entered;
    if (const auto* shown = std::get_if<protocol::EntityAppear>(&message)) {
        if (shown->kind == protocol::EntityKind::kPlayer) {
            ++tally.appear;
        } else if (shown->kind == protocol::EntityKind::kNpc) {
            ++tally.npcs;
        } else {
            ++tally.monsters;
        }
    }
    if (std::holds_alternative<protocol::EntityDisappear>(message)) ++tally.disappear;
    if (std::holds_alternative<protocol::EntityPos>(message)) ++tally.position;
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
void walk(link::Link& line, Seen& seen, Tally& tally, const protocol::Position& start, Gait gait, int seconds) {
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
        if (!send(line, protocol::Move{.x_cm = x, .z_cm = z, .tick = tick})) return;
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
}

void run_bot(const Options& options, const secure::PublicKey& server, int index, Tally& tally) {
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
    std::println("[{}] vào tại x={:.0f} z={:.0f} (cm)", account, seen.position->x_cm, seen.position->z_cm);
    if (options.straight) {
        const float heading = 2.0F * std::numbers::pi_v<float> * static_cast<float>(index) / static_cast<float>(options.count);
        walk(*line, seen, tally, *seen.position, Gait{.heading = heading, .turn = 0.0F}, options.seconds);
    } else {
        // Vòng tròn bán kính 200 cm bắt đầu từ điểm sinh (mỗi bước 10 cm, dưới trần 15,5 cm của guard::Pace).
        walk(*line, seen, tally, *seen.position, Gait{.heading = 0.0F, .turn = 0.05F}, options.seconds);
    }
    if (seen.refused) return fail("bị server đóng giữa chừng");
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
        } else {
            return std::nullopt;
        }
    }
    if (options.identity.empty() || options.count < 1 || options.count > 256 || options.seconds < 1) return std::nullopt;
    return options;
}

} // namespace

int main(int argc, char** argv) {
    io::use_utf8_console();
    const std::optional<Options> options =
        parse(std::span<const char* const>{argv, static_cast<std::size_t>(argc)});
    if (!options) {
        std::println(stderr, "dùng: thienlong_bot --identity <identity.key> [--game 7000] [--auth 7001] [--count 4] "
                             "[--seconds 6] [--prefix bot] [--straight 1]");
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
    if (options->straight) return tally.corrections.load() > 0 && tally.drifted.load() == 0 ? 0 : 1;
    // Mỗi khách phải thấy mọi khách khác hiện ra ít nhất một lần.
    if (tally.appear.load() < options->count * want_seen) return 1;
    return 0;
}
