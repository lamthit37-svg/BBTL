// Phần thuần của phiên mạng client: bảng cổng máy chủ (Table/gates.tsv) và máy trạng thái. Không socket, không luồng,
// nên chạy được qua check.py --run (ASan, UBSan, debug mode của libstdc++). Phần chạy thật với máy chủ giả ở
// session_tests.cpp.
#include "client/session/gates.hpp"
#include "client/session/machine.hpp"

#include "core/check.hpp"
#include "net/net.hpp"
#include "protocol/messages.hpp"
#include "secure/secure.hpp"
#include "test.hpp"

#include <array>
#include <cstddef>
#include <format>
#include <optional>
#include <string>
#include <string_view>

namespace game::test {
namespace {

using client::session::Ask;
using client::session::Gate;
using client::session::Outcome;
using client::session::Phase;

constexpr std::string_view kKey = "00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff";

// ---------------------------------------------------------------------------------------------------------------
// Bảng cổng

void gate_book_reads_rows(Context& context) {
    const std::string text = std::format("area\tserver\thost\tgame_port\tauth_port\tkey\n"
                                         "Vùng Một\tMáy Một\t127.0.0.1\t7000\t7001\t{}\n"
                                         "Vùng Một\tMáy Hai\t10.0.0.5\t7100\t7101\t{}\n",
        kKey, kKey);
    const client::session::GateBookResult book = client::session::read_gate_book(text);
    context.expect(book.has_value(), "bảng đúng đọc được");
    if (!book) return;
    context.expect(book->gates.size() == 2, "hai dòng");
    const Gate* second = client::session::find_gate(*book, "Vùng Một", "Máy Hai");
    context.expect(second != nullptr, "tìm được theo vùng và tên");
    if (second != nullptr) {
        context.expect(second->game == net::Endpoint{.address = {10, 0, 0, 5}, .port = 7100}, "cổng game");
        context.expect(second->auth == net::Endpoint{.address = {10, 0, 0, 5}, .port = 7101}, "cổng xác thực");
        context.expect(second->key.bytes.at(1) == std::byte{0x11}, "khoá giải từ hex");
    }
    context.expect(client::session::find_gate(*book, "Vùng Một", "Máy Ba") == nullptr, "máy chủ lạ không có");
    context.expect(client::session::find_gate(*book, "Vùng Hai", "Máy Một") == nullptr, "vùng lạ không có");
}

void gate_book_rejects_bad_tables(Context& context) {
    const std::string head = "area\tserver\thost\tgame_port\tauth_port\tkey\n";
    const std::array<std::string, 9> bad{
        head + std::format("a\ts\t127.0.0.1\t7000\t7001\t{}\na\ts\t127.0.0.1\t7002\t7003\t{}\n", kKey, kKey),
        head + std::format("a\ts\t127.0.0.1\t0\t7001\t{}\n", kKey),
        head + std::format("a\ts\t127.0.0.1\t7000\t70000\t{}\n", kKey),
        head + std::format("a\ts\t127.0.0.1\t7000\t7000\t{}\n", kKey),
        head + std::format("a\ts\tmay-chu.example\t7000\t7001\t{}\n", kKey),
        head + "a\ts\t127.0.0.1\t7000\t7001\t0011\n",
        head + std::format("a\ts\t127.0.0.1\t7000\t7001\t{}zz\n", kKey.substr(0, 62)),
        head + std::format("a\t\t127.0.0.1\t7000\t7001\t{}\n", kKey),
        "area\tserver\thost\tgame_port\tauth_port\na\ts\t127.0.0.1\t7000\t7001\n",
    };
    for (const std::string& text : bad) {
        const client::session::GateBookResult book = client::session::read_gate_book(text);
        context.expect(!book.has_value(), "bảng sai phải bị từ chối cả bảng");
    }
    const client::session::GateBookResult empty = client::session::read_gate_book(head);
    context.expect(empty.has_value() && empty->gates.empty(), "bảng chỉ có dòng tên cột là bảng rỗng");
}

void decode_key_checks_shape(Context& context) {
    const std::optional<secure::PublicKey> lower = client::session::decode_key(kKey);
    context.expect(lower.has_value(), "hex thường");
    std::string upper{kKey};
    for (char& letter : upper) {
        if (letter >= 'a' && letter <= 'f') letter = static_cast<char>(letter - 'a' + 'A');
    }
    const std::optional<secure::PublicKey> big = client::session::decode_key(upper);
    context.expect(big.has_value() && lower.has_value() && big->bytes == lower->bytes, "hex hoa cùng khoá");
    context.expect(!client::session::decode_key("").has_value(), "rỗng");
    context.expect(!client::session::decode_key(kKey.substr(1)).has_value(), "thiếu một chữ số");
    context.expect(!client::session::decode_key(std::string{kKey} + "0").has_value(), "thừa một chữ số");
}

// ---------------------------------------------------------------------------------------------------------------
// Máy trạng thái

void machine_allows_by_phase(Context& context) {
    using client::session::allows;
    const std::array all{Phase::kIdle, Phase::kSigningIn, Phase::kChoosing, Phase::kEditing, Phase::kEntering,
        Phase::kInGame, Phase::kResuming, Phase::kLost};
    for (const Phase phase : all) {
        context.expect(allows(phase, Ask::kDrop), "trả phiên được ở mọi pha");
        const bool is_idle = phase == Phase::kIdle || phase == Phase::kLost;
        const bool can_sign = is_idle || phase == Phase::kResuming;
        context.expect(allows(phase, Ask::kSignIn) == can_sign, "đăng nhập ở kIdle, kLost, kResuming");
        const bool is_choosing = phase == Phase::kChoosing;
        context.expect(allows(phase, Ask::kCreate) == is_choosing, "tạo chỉ ở kChoosing");
        context.expect(allows(phase, Ask::kDelete) == is_choosing, "xoá chỉ ở kChoosing");
        context.expect(allows(phase, Ask::kEnter) == is_choosing, "vào game chỉ ở kChoosing");
    }
    context.expect(client::session::begin(Phase::kIdle, Ask::kSignIn) == Phase::kSigningIn, "SignIn -> kSigningIn");
    context.expect(client::session::begin(Phase::kChoosing, Ask::kCreate) == Phase::kEditing, "Create -> kEditing");
    context.expect(client::session::begin(Phase::kChoosing, Ask::kDelete) == Phase::kEditing, "Delete -> kEditing");
    context.expect(client::session::begin(Phase::kChoosing, Ask::kEnter) == Phase::kEntering, "Enter -> kEntering");
    context.expect(client::session::begin(Phase::kInGame, Ask::kDrop) == Phase::kIdle, "Drop -> kIdle");
}

[[nodiscard]] client::session::Step step_of(Phase next, Outcome outcome) noexcept {
    return client::session::Step{.next = next, .outcome = outcome};
}

void machine_routes_server_messages(Context& context) {
    using client::session::on_server;
    const protocol::GameServerMessage roster = protocol::CharacterList{};
    const protocol::GameServerMessage reject = protocol::Reject{};
    const protocol::GameServerMessage bye = protocol::Goodbye{};
    const protocol::GameServerMessage pong = protocol::Pong{};
    const protocol::GameServerMessage opening = protocol::UiConfig{};
    const protocol::GameServerMessage spot = protocol::Position{};
    const protocol::GameServerMessage world = protocol::EntityPos{};
    const protocol::GameServerMessage stray = protocol::Welcome{};

    context.expect(on_server(Phase::kSigningIn, roster) == step_of(Phase::kChoosing, Outcome::kDeliver), "CharacterList mở bảng chọn");
    context.expect(on_server(Phase::kSigningIn, reject) == step_of(Phase::kIdle, Outcome::kRejected), "Login bị từ chối về kIdle");
    context.expect(on_server(Phase::kEditing, roster) == step_of(Phase::kChoosing, Outcome::kDeliver), "tạo xong về kChoosing");
    context.expect(on_server(Phase::kEditing, reject) == step_of(Phase::kChoosing, Outcome::kRejected), "tạo bị từ chối về kChoosing");
    context.expect(on_server(Phase::kEntering, opening) == step_of(Phase::kEntering, Outcome::kDeliver), "phần mở đầu giữ kEntering");
    context.expect(on_server(Phase::kEntering, spot) == step_of(Phase::kInGame, Outcome::kDeliver), "Position đưa vào game");
    context.expect(on_server(Phase::kEntering, reject) == step_of(Phase::kChoosing, Outcome::kRejected), "vào bị từ chối về kChoosing");
    context.expect(on_server(Phase::kInGame, world) == step_of(Phase::kInGame, Outcome::kDeliver), "tin thế giới trong game");
    context.expect(on_server(Phase::kInGame, spot) == step_of(Phase::kInGame, Outcome::kDeliver), "Position kéo về trong game");
    context.expect(on_server(Phase::kInGame, reject) == step_of(Phase::kInGame, Outcome::kRejected), "từ chối trong game");

    const std::array all{Phase::kIdle, Phase::kSigningIn, Phase::kChoosing, Phase::kEditing, Phase::kEntering,
        Phase::kInGame, Phase::kResuming, Phase::kLost};
    for (const Phase phase : all) {
        context.expect(on_server(phase, bye) == step_of(Phase::kLost, Outcome::kClosed), "Goodbye ở mọi pha là kLost");
        if (phase == Phase::kIdle) {
            context.expect(on_server(phase, pong).outcome == Outcome::kViolation, "kIdle không nhận gì");
        } else if (phase != Phase::kLost) {
            context.expect(on_server(phase, pong).outcome == Outcome::kQuiet, "Pong bị bỏ qua");
            context.expect(on_server(phase, stray).outcome == Outcome::kViolation, "Welcome lần hai là vi phạm");
        }
    }
    context.expect(on_server(Phase::kChoosing, spot).outcome == Outcome::kViolation, "Position ở bảng chọn là sai trình tự");
    context.expect(on_server(Phase::kChoosing, world).outcome == Outcome::kViolation, "tin thế giới ở bảng chọn là sai trình tự");
    context.expect(on_server(Phase::kInGame, roster).outcome == Outcome::kViolation, "CharacterList trong game là sai trình tự");
    context.expect(on_server(Phase::kSigningIn, spot).outcome == Outcome::kViolation, "Position khi đăng nhập là sai trình tự");
    context.expect(on_server(Phase::kLost, world).outcome == Outcome::kQuiet, "tin muộn sau khi mất phiên bị bỏ");
    context.expect(on_server(Phase::kResuming, spot) == step_of(Phase::kInGame, Outcome::kDeliver), "Resume xong thì vào game");
    context.expect(on_server(Phase::kResuming, reject) == step_of(Phase::kLost, Outcome::kRejected), "Resume bị từ chối thì mất phiên");
    context.expect(on_server(Phase::kResuming, opening) == step_of(Phase::kResuming, Outcome::kDeliver), "token mới giữ kResuming");
}

void resume_only_after_a_live_game(Context& context) {
    using client::session::LinkBreak;
    using client::session::can_resume;
    using client::session::resume_again;
    context.expect(can_resume(LinkBreak::kDown, Phase::kInGame, true), "đứt lúc chơi thì nối lại");
    context.expect(can_resume(LinkBreak::kTimeout, Phase::kEntering, true), "hết giờ lúc vào game thì nối lại");
    context.expect(can_resume(LinkBreak::kDown, Phase::kResuming, true), "lần nối lại hỏng thì thử tiếp");
    context.expect(!can_resume(LinkBreak::kFatal, Phase::kInGame, true), "lỗi giao thức không nối lại");
    context.expect(!can_resume(LinkBreak::kDown, Phase::kInGame, false), "chưa có token thì không nối lại");
    context.expect(!can_resume(LinkBreak::kDown, Phase::kChoosing, true), "còn ở bảng chọn thì không nối lại");
    context.expect(!resume_again(true, LinkBreak::kDown, Phase::kResuming, true), "đã gửi token thì không gửi lại");
    context.expect(resume_again(false, LinkBreak::kDown, Phase::kInGame, true), "chưa gửi token thì còn được thử");
}

constexpr std::array kCases{
    Case{.name = "gate_book_reads_rows", .body = &gate_book_reads_rows},
    Case{.name = "gate_book_rejects_bad_tables", .body = &gate_book_rejects_bad_tables},
    Case{.name = "decode_key_checks_shape", .body = &decode_key_checks_shape},
    Case{.name = "machine_allows_by_phase", .body = &machine_allows_by_phase},
    Case{.name = "machine_routes_server_messages", .body = &machine_routes_server_messages},
    Case{.name = "resume_only_after_a_live_game", .body = &resume_only_after_a_live_game},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "session_logic_tests: mọi ca phải qua");
    return 0;
}
