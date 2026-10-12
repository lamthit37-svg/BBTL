// Luật tên, vé một lần và trần nhân vật. Bản nhớ, không cần PostgreSQL.
#include "account/book.hpp"
#include "account/cap.hpp"
#include "account/ipc_key.hpp"
#include "account/rules.hpp"
#include "secure/secure.hpp"

#include "test.hpp"

#include <array>
#include <chrono>
#include <span>
#include <string>

namespace game::test {
namespace {

using account::BookConfig;
using account::CreateStep;
using account::MemoryBook;
using account::NameFault;
using account::SignStep;
using Clock = std::chrono::system_clock;

bool hash_plain(void*, std::string_view password, std::string& out) {
    out = "v1:";
    out.append(password);
    return true;
}

bool verify_plain(void*, std::string_view stored, std::string_view password) {
    return stored.size() >= 3 && stored.substr(3) == password;
}

bool fill_fixed(void*, std::span<std::byte> out) {
    for (std::byte& value : out) value = std::byte{0x11};
    return true;
}

[[nodiscard]] BookConfig test_config(bool auto_register) {
    BookConfig config;
    config.auto_register = auto_register;
    config.ticket_ttl = std::chrono::seconds{300};
    config.hash.hash = &hash_plain;
    config.hash.verify = &verify_plain;
    config.random.fill = &fill_fixed;
    return config;
}

void names_reject_junk(Context& context) {
    context.expect(account::account_fault("ab", "longenough") == NameFault::kAccount, "tên ngắn");
    context.expect(account::account_fault("hero", "hero") == NameFault::kPassword, "mật khẩu trùng tên");
    context.expect(account::account_fault("hero", "longenough") == NameFault::kOk, "tên hợp lệ");
    context.expect(!account::character_name_ok(" "), "tên nhân vật trắng");
    context.expect(!account::character_name_ok("<gm>"), "tên có ngoặc");
    context.expect(account::character_name_ok("Lý Mộ"), "tên Việt");
}

void sign_steps(Context& context) {
    context.expect(account::sign_step(false, false, false, 8, true) == SignStep::kRate, "đủ lần sai thì chặn");
    context.expect(account::sign_step(false, false, false, 0, true) == SignStep::kCreate, "chưa có thì tạo");
    context.expect(account::sign_step(false, false, false, 0, false) == SignStep::kMissing, "chưa có và không tự tạo");
    context.expect(account::sign_step(true, true, true, 0, false) == SignStep::kDisabled, "khoá thì không vào");
    context.expect(account::sign_step(true, false, false, 0, false) == SignStep::kMismatch, "sai mật khẩu");
    context.expect(account::sign_step(true, false, true, 0, false) == SignStep::kOk, "đúng mật khẩu");
    context.expect(account::create_step(false, 0, false) == CreateStep::kBadName, "tên xấu");
    context.expect(account::create_step(true, 3, false) == CreateStep::kFull, "đủ ba nhân vật");
    context.expect(account::create_step(true, 1, true) == CreateStep::kTaken, "trùng tên");
    context.expect(account::create_step(true, 1, false) == CreateStep::kOk, "tạo được");
}

void register_sign_and_ticket(Context& context) {
    MemoryBook book{test_config(false)};
    const Clock::time_point now = Clock::time_point{std::chrono::seconds{1'000}};
    const account::TicketResult created = book.create_account("Hero", "longenough", now);
    context.expect(created.ok, "tạo tài khoản");
    const account::TicketResult again = book.create_account("hero", "otherpass", now);
    context.expect(!again.ok && again.code == protocol::ErrorCode::kDuplicate, "không phân biệt hoa thường");
    const account::TicketResult wrong = book.sign_in("hero", "nopepass", now);
    context.expect(!wrong.ok && wrong.code == protocol::ErrorCode::kBadCredentials, "sai mật khẩu");
    const account::TicketResult right = book.sign_in("HERO", "longenough", now);
    context.expect(right.ok, "đăng nhập đúng");
    const account::ListResult first = book.login(right.hex, now);
    context.expect(first.ok && first.characters.empty(), "vé mở danh sách rỗng");
    const account::ListResult second = book.login(right.hex, now + std::chrono::seconds{1});
    context.expect(!second.ok && second.code == protocol::ErrorCode::kSessionExpired, "vé chỉ dùng một lần");
}

void eight_failures_then_rate(Context& context) {
    MemoryBook book{test_config(false)};
    const Clock::time_point now = Clock::time_point{std::chrono::seconds{2'000}};
    context.expect(book.create_account("hero", "longenough", now).ok, "có tài khoản");
    for (int index = 0; index < 8; ++index) {
        const account::TicketResult failed = book.sign_in("hero", "badpass1", now);
        context.expect(failed.code == protocol::ErrorCode::kBadCredentials, "lần sai chưa tới trần");
    }
    const account::TicketResult blocked = book.sign_in("hero", "longenough", now);
    context.expect(blocked.code == protocol::ErrorCode::kRateLimited, "lần thứ chín bị chặn dù đúng mật khẩu");
}

void three_characters_then_one_slot(Context& context) {
    MemoryBook book{test_config(false)};
    const Clock::time_point now = Clock::time_point{std::chrono::seconds{3'000}};
    const account::TicketResult ticket = book.create_account("hero", "longenough", now);
    const account::ListResult session = book.login(ticket.hex, now);
    context.expect(session.ok, "có phiên");
    const std::uint64_t account = session.account;
    context.expect(book.create_character(account, "Lý Mộ", protocol::Gender::kFemale, 1, 2).ok, "nhân vật một");
    context.expect(book.create_character(account, "Trần Phong", protocol::Gender::kMale, 3, 4).ok, "nhân vật hai");
    const account::ListResult third = book.create_character(account, "Vô Danh", protocol::Gender::kMale, 5, 6);
    context.expect(third.ok && third.characters.size() == 3, "đủ ba");
    const account::ListResult full = book.create_character(account, "Thêm", protocol::Gender::kFemale, 1, 1);
    context.expect(full.code == protocol::ErrorCode::kCharacterLimit, "hết ô");
    const account::ListResult other = book.create_character(account, "Lý Mộ", protocol::Gender::kMale, 1, 1);
    context.expect(other.code == protocol::ErrorCode::kCharacterLimit, "đầy thì chưa tới lỗi trùng tên");
    const std::uint64_t removed = third.characters.front().id;
    const account::ListResult left = book.remove_character(account, removed);
    context.expect(left.ok && left.characters.size() == 2, "xoá mềm giải phóng ô");
    const account::ListResult reused = book.create_character(account, "Lý Mộ", protocol::Gender::kFemale, 7, 8);
    context.expect(reused.ok, "tên đã xoá dùng lại được");
    context.expect(book.enter(account, reused.characters.back().id).ok, "vào được nhân vật của mình");
    context.expect(!book.enter(account, 999).ok, "không vào nhân vật không có");
}

void sign_in_hides_unknown_name(Context& context) {
    MemoryBook book{test_config(true)};
    const Clock::time_point now = Clock::time_point{std::chrono::seconds{4'000}};
    context.expect(book.create_account("hero", "longenough", now).ok, "có tài khoản");
    const account::TicketResult wrong = book.sign_in("hero", "nopepass", now);
    const account::TicketResult unknown = book.sign_in("other", "short", now);
    context.expect(wrong.code == protocol::ErrorCode::kBadCredentials, "sai mật khẩu");
    context.expect(unknown.code == protocol::ErrorCode::kBadCredentials, "tên chưa có cũng một mã");
}

void names_are_canonical(Context& context) {
    const std::string acute = std::string("e") + "\u0301";
    const std::optional<std::string> composed = account::canonical_character_name(acute);
    context.expect(composed && *composed == "é", "e + sắc thành é");
    const std::string horn = std::string("o") + "\u031b\u0301";
    const std::optional<std::string> ohorn = account::canonical_character_name(horn);
    context.expect(ohorn && *ohorn == "ớ", "o + sừng + sắc thành ớ");
    context.expect(!account::canonical_character_name("a\u200b"), "ký tự rộng zero bị từ chối");
    context.expect(!account::canonical_character_name("a\u202e"), "đảo hướng bị từ chối");
    context.expect(account::ipv4_ok("127.0.0.1"), "ipv4 đúng");
    context.expect(!account::ipv4_ok("127.00.0.1"), "ipv4 không nhận số 0 thừa");
}

void cap_rejects_tamper(Context& context) {
    std::array<std::byte, account::kIpcKeyBytes> key{};
    key[0] = std::byte{9};
    std::array<std::byte, account::kCapBytes> token{};
    context.expect(account::seal_cap(key, 7, 10'000, token), "ký vé");
    account::Cap cap;
    context.expect(account::open_cap(key, token, 100, cap) == account::CapStatus::kOk, "mở vé");
    context.expect(cap.account == 7, "đúng id");
    token[0] = std::byte{8};
    context.expect(account::open_cap(key, token, 100, cap) == account::CapStatus::kBad, "sửa id thì hỏng");
    context.expect(account::open_cap(key, token, 100, cap) != account::CapStatus::kOk, "vé giả không vào");
}

void sha256_of_empty(Context& context) {
    std::array<std::byte, 32> out{};
    context.expect(secure::sha256({}, out), "sha256 chạy");
    context.expect(out.front() == std::byte{0xe3}, "sha256 của chuỗi rỗng");
}

constexpr std::array kCases{
    Case{.name = "names_reject_junk", .body = &names_reject_junk},
    Case{.name = "sign_steps", .body = &sign_steps},
    Case{.name = "register_sign_and_ticket", .body = &register_sign_and_ticket},
    Case{.name = "eight_failures_then_rate", .body = &eight_failures_then_rate},
    Case{.name = "three_characters_then_one_slot", .body = &three_characters_then_one_slot},
    Case{.name = "sign_in_hides_unknown_name", .body = &sign_in_hides_unknown_name},
    Case{.name = "names_are_canonical", .body = &names_are_canonical},
    Case{.name = "cap_rejects_tamper", .body = &cap_rejects_tamper},
    Case{.name = "sha256_of_empty", .body = &sha256_of_empty},
};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
