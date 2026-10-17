/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Server/account_tests.cpp
 *  PHÂN HỆ   : Server / Account Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Luật tên, vé một lần và trần nhân vật. Bản nhớ, không cần PostgreSQL.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "account/book.hpp"
#include "account/cap.hpp"
#include "account/ipc_key.hpp"
#include "account/play.hpp"
#include "account/rpc.hpp"
#include "account/rules.hpp"
#include "account/standing.hpp"
#include "secure/private_file.hpp"
#include "protocol/messages.hpp"
#include "secure/secure.hpp"

#include "support/lax_file.hpp"
#include "test.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

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
    context.expect(!again.ok && again.code == protocol::ErrorCode::kBadCredentials, "không phân biệt hoa thường, tên trùng không lộ");
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
    context.expect(book.create_character(account, "Lý Mộ", protocol::Gender::kFemale, 1, 1).ok, "nhân vật một");
    context.expect(book.create_character(account, "Trần Phong", protocol::Gender::kMale, 100, 5).ok, "nhân vật hai");
    const account::ListResult third = book.create_character(account, "Vô Danh", protocol::Gender::kMale, 100, 5);
    context.expect(third.ok && third.characters.size() == 3, "đủ ba");
    const account::ListResult full = book.create_character(account, "Thêm", protocol::Gender::kFemale, 1, 1);
    context.expect(full.code == protocol::ErrorCode::kCharacterLimit, "hết ô");
    const account::ListResult other = book.create_character(account, "Lý Mộ", protocol::Gender::kMale, 100, 5);
    context.expect(other.code == protocol::ErrorCode::kCharacterLimit, "đầy thì chưa tới lỗi trùng tên");
    const std::uint64_t removed = third.characters.front().id;
    const account::ListResult left = book.remove_character(account, removed);
    context.expect(left.ok && left.characters.size() == 2, "xoá mềm giải phóng ô");
    const account::ListResult reused = book.create_character(account, "Lý Mộ", protocol::Gender::kFemale, 1, 1);
    context.expect(reused.ok, "tên đã xoá dùng lại được");
    context.expect(book.enter(account, reused.characters.back().id).ok, "vào được nhân vật của mình");
    context.expect(!book.enter(account, 999).ok, "không vào nhân vật không có");
    const account::EnterResult spot = book.enter(account, reused.characters.back().id);
    context.expect(spot.x_cm == 16500 && spot.z_cm == 16971, "vào ở điểm sinh của hồ sơ mới, đổi mét ra centimet");
    context.expect(spot.summary.id == reused.characters.back().id && spot.summary.name == "Lý Mộ",
        "vào game mang hồ sơ nhân vật");
}

// Zone ghi điểm đứng qua Op::kSave: thân đi về nguyên vẹn, sai cỡ hay toạ độ ngoài trần bị từ chối.
void save_call_round_trip(Context& context) {
    const account::SaveSpot sent{.character = 0x1122334455667788ULL, .scene = 71, .x_cm = -12345, .z_cm = 16900};
    account::SaveSpot got;
    const std::optional<account::Call> made = account::save_call(sent);
    context.expect(made.has_value(), "đóng gói được");
    if (!made) return;
    const account::Call& call = *made;
    context.expect(call.op == account::Op::kSave && account::read_save_call(call, got), "thân đọc lại được");
    context.expect(got.character == sent.character && got.scene == 71 && got.x_cm == -12345 && got.z_cm == 16900,
        "giá trị nguyên vẹn");
    account::Call cut = call;
    cut.body.pop_back();
    context.expect(!account::read_save_call(cut, got), "thiếu byte bị từ chối");
    account::Call longer = call;
    longer.body.push_back(std::byte{0});
    context.expect(!account::read_save_call(longer, got), "thừa byte bị từ chối");
    const account::SaveSpot beyond{.character = 1, .scene = 1, .x_cm = account::kSpotLimitCm + 1, .z_cm = 0};
    context.expect(!account::read_save_call(*account::save_call(beyond), got), "toạ độ ngoài trần bị từ chối");
    const account::SaveSpot edge{.character = 1, .scene = 1, .x_cm = account::kSpotLimitCm, .z_cm = -account::kSpotLimitCm};
    context.expect(account::read_save_call(*account::save_call(edge), got), "đúng trần vẫn nhận");
}

[[nodiscard]] account::PlayRecord sample_play() {
    account::PlayRecord play;
    play.level = 12;
    play.exp = 345'678;
    play.money = 9'000;
    play.bound = 120;
    play.hp = 777;
    play.mp = 55;
    play.body = {std::byte{1}, std::byte{2}, std::byte{3}};
    play.mission.assign(5000, std::byte{0x5A});
    play.bag = {std::byte{9}};
    return play;
}

// Khối trạng thái chơi: đóng gói rồi mở ra giữ nguyên; mọi dạng hỏng bị từ chối chứ không đoán.
void play_record_round_trip_and_hostile(Context& context) {
    const account::PlayRecord play = sample_play();
    const auto packed = account::pack(play);
    context.expect(packed.has_value(), "đóng gói được");
    if (!packed) return;
    const auto back = account::unpack(*packed);
    context.expect(back.has_value() && *back == play, "mở ra giống hệt");
    std::vector<std::byte> cut = *packed;
    cut.pop_back();
    context.expect(!account::unpack(cut).has_value(), "thiếu byte bị từ chối");
    std::vector<std::byte> longer = *packed;
    longer.push_back(std::byte{0});
    context.expect(!account::unpack(longer).has_value(), "thừa byte bị từ chối");
    std::vector<std::byte> wrong_kind = *packed;
    wrong_kind[0] = std::byte{0x02};
    context.expect(!account::unpack(wrong_kind).has_value(), "sai loại khung bị từ chối");
    context.expect(!account::unpack({}).has_value(), "rỗng bị từ chối");

    account::PlayRecord zero_level = play;
    zero_level.level = 0;
    context.expect(!account::pack(zero_level).has_value(), "cấp 0 không đóng gói");
    account::PlayRecord rich = play;
    rich.money = account::kMoneyLimit + 1;
    context.expect(!account::pack(rich).has_value(), "tiền quá trần không đóng gói");
    account::PlayRecord fat = play;
    fat.mission.assign(account::kMaxMissionBlob + 1, std::byte{1});
    context.expect(!account::pack(fat).has_value(), "khối quá trần không đóng gói");
    account::PlayRecord full = play;
    full.body.assign(account::kMaxBodyBlob, std::byte{1});
    full.mission.assign(account::kMaxMissionBlob, std::byte{2});
    full.bag.assign(account::kMaxBagBlob, std::byte{3});
    const auto biggest = account::pack(full);
    context.expect(biggest.has_value() && biggest->size() <= account::kMaxPackedPlay, "ba khối đầy vẫn dưới trần khung");

    // Độ dài khối khai quá trần: không cấp phát, từ chối ngay.
    std::vector<std::byte> lying = *packed;
    constexpr std::size_t kBodyLenAt = protocol::kHeaderBytes + 2 + 2 + 8 + 8 + 8 + 4 + 4;
    for (std::size_t i = 0; i < 4; ++i) lying[kBodyLenAt + i] = std::byte{0xFF};
    context.expect(!account::unpack(lying).has_value(), "độ dài khối nói dối bị từ chối");
}

// Op::kSave mang trạng thái chơi và Op::kEnter trả nó về nguyên vẹn qua bốn chặng mã hoá/giải mã.
void play_travels_through_save_and_enter(Context& context) {
    const account::SaveSpot sent{.character = 5, .scene = 2, .x_cm = 100, .z_cm = 200, .play = sample_play()};
    account::SaveSpot got;
    const std::optional<account::Call> call = account::save_call(sent);
    context.expect(call.has_value() && account::read_save_call(*call, got) && got.play == sent.play, "Save mang play");
    if (call) {
        account::Call cut = *call;
        cut.body.pop_back();
        context.expect(!account::read_save_call(cut, got), "Save cụt bị từ chối");
        account::Call flag = *call;
        flag.body[8 + 2 + 4 + 4] = std::byte{2};
        context.expect(!account::read_save_call(flag, got), "cờ play lạ bị từ chối");
    }
    account::SaveSpot bad = sent;
    bad.play->level = 0;
    context.expect(!account::save_call(bad).has_value(), "play ngoài miền không thành Call");

    account::EnterResult enter;
    enter.ok = true;
    enter.scene = 2;
    enter.summary.id = 5;
    enter.summary.name = "A";
    enter.play = sample_play();
    const account::EnterResult back = account::entered_from(account::enter_reply_of(enter));
    context.expect(back.ok && back.play == enter.play, "Enter mang play về");
    account::EnterResult broken = enter;
    broken.play.level = 0;
    context.expect(!account::entered_from(account::enter_reply_of(broken)).ok, "store không trả play ngoài miền");
}

// Trả lời Op::kEnter mang điểm vào; thân hỏng hoặc toạ độ ngoài trần thì không vào.
void enter_reply_carries_spot(Context& context) {
    account::EnterResult sent;
    sent.ok = true;
    sent.scene = 71;
    sent.x_cm = -12345;
    sent.z_cm = 16900;
    sent.summary.id = 77;
    sent.summary.name = "Lý Mộ";
    sent.summary.level = 5;
    sent.summary.gender = protocol::Gender::kFemale;
    sent.summary.face = 3;
    sent.summary.hair = 2;
    sent.summary.school = 4;
    sent.summary.scene = 71;
    const account::EnterResult got = account::entered_from(account::enter_reply_of(sent));
    context.expect(got.ok && got.scene == 71 && got.x_cm == -12345 && got.z_cm == 16900, "đi về giữ nguyên điểm vào");
    context.expect(got.summary.id == 77 && got.summary.name == "Lý Mộ" && got.summary.level == 5 &&
            got.summary.gender == protocol::Gender::kFemale && got.summary.face == 3 && got.summary.hair == 2 &&
            got.summary.school == 4,
        "hồ sơ hiển thị đi về nguyên vẹn");

    account::EnterResult denied;
    denied.code = protocol::ErrorCode::kNoSuchCharacter;
    const account::EnterResult refused = account::entered_from(account::enter_reply_of(denied));
    context.expect(!refused.ok && refused.code == protocol::ErrorCode::kNoSuchCharacter, "lỗi giữ nguyên mã");

    account::Reply cut = account::enter_reply_of(sent);
    cut.body.pop_back();
    context.expect(!account::entered_from(cut).ok, "thân thiếu byte bị từ chối");
    account::Reply longer = account::enter_reply_of(sent);
    longer.body.push_back(std::byte{0});
    context.expect(!account::entered_from(longer).ok, "thân thừa byte bị từ chối");
    context.expect(!account::entered_from(account::Reply{}).ok, "thân rỗng (kiểu standing) không phải điểm vào");

    account::EnterResult beyond = sent;
    beyond.x_cm = account::kSpotLimitCm + 1;
    context.expect(!account::entered_from(account::enter_reply_of(beyond)).ok, "store không gửi toạ độ ngoài trần");
    account::Reply forged = account::enter_reply_of(sent);
    const auto huge = static_cast<std::uint32_t>(account::kSpotLimitCm + 1);
    for (std::size_t i = 0; i < 4; ++i) forged.body[2 + i] = std::byte{static_cast<std::uint8_t>(huge >> (8U * i))};
    context.expect(!account::entered_from(forged).ok, "gate từ chối toạ độ ngoài trần");
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
    context.expect(!account::canonical_character_name("a\u202e\u202c"), "đảo hướng bị từ chối");
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

// Khoá lộ thì xoay khoá: cap ký bằng khoá cũ bị thu hồi (kRevoked), không lẫn với cap bị sửa (kBad).
void cap_rotation_revokes(Context& context) {
    std::array<std::byte, account::kIpcKeyBytes> old_key{};
    old_key[0] = std::byte{9};
    std::array<std::byte, account::kIpcKeyBytes> new_key{};
    new_key[0] = std::byte{10};
    context.expect(account::cap_key_id(old_key) != account::cap_key_id(new_key), "hai khoá hai key id");
    std::array<std::byte, account::kCapBytes> token{};
    context.expect(account::seal_cap(old_key, 7, 10'000, token), "ký bằng khoá cũ");
    account::Cap cap;
    context.expect(account::open_cap(new_key, token, 100, cap) == account::CapStatus::kRevoked, "khoá mới thu hồi cap cũ");
    context.expect(account::seal_cap(new_key, 7, 10'000, token), "ký bằng khoá mới");
    token[20] ^= std::byte{1};
    context.expect(account::open_cap(new_key, token, 100, cap) == account::CapStatus::kBad, "sửa chữ ký là kBad");
}

// Tên giả bằng chữ trông giống Latin (Cyrillic, Hy Lạp, toàn khổ, Latin ngoài tiếng Việt) bị chặn;
// chữ Việt và chữ Hán vẫn đặt được.
void names_block_confusables(Context& context) {
    context.expect(!account::character_name_ok("Adm\u0430n"), "a Cyrillic bị chặn");
    context.expect(!account::character_name_ok("\u0391dmin"), "Alpha Hy Lạp bị chặn");
    context.expect(!account::character_name_ok("\uFF21dmin"), "A toàn khổ bị chặn");
    context.expect(!account::character_name_ok("\u00D0ang"), "Ð (eth) giả Đ bị chặn");
    context.expect(!account::character_name_ok("\u0131lan"), "i không chấm bị chặn");
    context.expect(!account::character_name_ok("\U0001D400dmin"), "chữ toán học bị chặn");
    context.expect(account::character_name_ok("\u0110\u1EB7ng L\u00FD"), "Đặng Lý đặt được");
    context.expect(account::character_name_ok("\u674E\u6155\u767D"), "tên Hán đặt được");
}

// Khoá duy nhất hạ hoa thường cả chữ có dấu: "Ầu" và "ầu" không cùng sống được.
void character_fold_covers_vietnamese(Context& context) {
    const auto fold_of = [](std::string_view name) {
        const std::optional<std::string> canonical = account::canonical_character_name(name);
        return canonical ? account::fold_character_name(*canonical) : std::string{};
    };
    context.expect(fold_of("\u1EA6u") == fold_of("\u1EA7u"), "Ầu và ầu cùng khoá");
    context.expect(fold_of("\u0110\u00C0O") == fold_of("\u0111\u00E0o"), "ĐÀO và đào cùng khoá");
    context.expect(fold_of("\u01AF\u01A0\u0102") == fold_of("\u01B0\u01A1\u0103"), "ƯƠĂ và ươă cùng khoá");
    context.expect(fold_of("E\u0301") == fold_of("\u00E9"), "É ghép và é sẵn cùng khoá");
    context.expect(fold_of("\u0110ao") != fold_of("Dao"), "Đ và D vẫn khác");
}

void duplicate_account_looks_like_bad_login(Context& context) {
    MemoryBook book{test_config(false)};
    const Clock::time_point now = Clock::time_point{std::chrono::seconds{5'000}};
    context.expect(book.create_account("hero", "longenough", now).ok, "có tài khoản");
    const account::TicketResult again = book.create_account("HERO", "otherpass1", now);
    context.expect(again.code == protocol::ErrorCode::kBadCredentials, "tên trùng trả mã chung như đăng nhập sai");
}

void deleted_name_stays_reserved(Context& context) {
    MemoryBook book{test_config(false)};
    const Clock::time_point now = Clock::time_point{std::chrono::seconds{6'000}};
    const account::ListResult owner = book.login(book.create_account("owner", "longenough", now).hex, now);
    const account::ListResult thief = book.login(book.create_account("thief", "longenough", now).hex, now);
    const account::ListResult made = book.create_character(owner.account, "Danh", protocol::Gender::kMale, 100, 5);
    context.expect(made.ok, "chủ tạo tên");
    context.expect(book.remove_character(owner.account, made.characters.front().id).ok, "chủ xoá mềm");
    const account::ListResult stolen = book.create_character(thief.account, "DANH", protocol::Gender::kMale, 100, 5);
    context.expect(stolen.code == protocol::ErrorCode::kNameTaken, "tài khoản khác không chiếm tên vừa xoá");
    context.expect(book.create_character(owner.account, "Danh", protocol::Gender::kMale, 100, 5).ok, "chủ lấy lại được");
}

void look_rejects_unlisted(Context& context) {
    using protocol::Gender;
    context.expect(account::look_ok(Gender::kFemale, 1, 1), "mat toc nu hop le");
    context.expect(account::look_ok(Gender::kMale, 100, 5), "mat toc nam hop le");
    context.expect(!account::look_ok(Gender::kFemale, 65535, 1), "mat ngoai bang bi chan");
    context.expect(!account::look_ok(Gender::kFemale, 1, 65535), "toc ngoai bang bi chan");
    context.expect(!account::look_ok(Gender::kMale, 1, 1), "mat cua gioi khac bi chan");
    context.expect(!account::look_ok(Gender::kFemale, 0, 0), "id khong tao duoc bi chan");
    MemoryBook book{test_config(false)};
    const Clock::time_point now = Clock::time_point{std::chrono::seconds{7'000}};
    const account::ListResult who = book.login(book.create_account("looker", "longenough", now).hex, now);
    const account::ListResult odd = book.create_character(who.account, "Mat", Gender::kFemale, 65535, 65535);
    context.expect(!odd.ok && odd.code == protocol::ErrorCode::kBadOption, "book tu choi mat toc ngoai bang");
}

// Danh sách mặt/tóc đến từ store.toml: id ngoài danh sách cấu hình bị chặn kể cả khi có ở mặc định.
void look_follows_configured_policy(Context& context) {
    using protocol::Gender;
    account::LookPolicy policy;
    policy.female_faces = {7};
    policy.male_faces = {200};
    policy.female_hairs = {8};
    policy.male_hairs = {201};
    context.expect(account::look_ok(policy, Gender::kFemale, 7, 8), "id cấu hình được nhận");
    context.expect(!account::look_ok(policy, Gender::kFemale, 1, 1), "id mặc định không còn được nhận");
    context.expect(!account::look_ok(policy, Gender::kMale, 7, 8), "id của giới khác bị chặn");
    context.expect(!account::look_ok(account::LookPolicy{}, Gender::kFemale, 1, 1), "danh sách rỗng chặn hết");
    BookConfig config = test_config(false);
    config.look = std::move(policy);
    MemoryBook book{config};
    const Clock::time_point now = Clock::time_point{std::chrono::seconds{7'000}};
    const account::ListResult who = book.login(book.create_account("policy", "longenough", now).hex, now);
    context.expect(!book.create_character(who.account, "Mot", Gender::kFemale, 1, 1).ok, "book theo danh sách cấu hình");
    context.expect(book.create_character(who.account, "Hai", Gender::kFemale, 7, 8).ok, "id cấu hình tạo được");
}

void sha256_of_empty(Context& context) {
    std::array<std::byte, 32> out{};
    context.expect(secure::sha256({}, out), "sha256 chạy");
    context.expect(out.front() == std::byte{0xe3}, "sha256 của chuỗi rỗng");
}

// Ban sau khi đăng nhập: store chỉ được tin câu trả lời cũ trong kStandingTtl, và không được
// nhớ Busy (auth đứt) như thể tài khoản còn chơi được.
void standing_cache_expires_and_skips_busy(Context& context) {
    using account::Standing;
    using SteadyClock = account::StandingCache::Clock;
    account::StandingCache cache;
    const SteadyClock::time_point start = SteadyClock::time_point{std::chrono::seconds{100}};
    cache.put(1, Standing{.ok = true}, start);
    context.expect(cache.find(1, start + account::kStandingTtl - std::chrono::milliseconds{1}).has_value(),
        "trong hạn thì nhớ");
    context.expect(account::kStandingTtl <= std::chrono::seconds{1}, "cửa sổ ban sau đăng nhập không quá 1 giây");
    context.expect(!cache.find(1, start + account::kStandingTtl).has_value(), "hết hạn đúng ở kStandingTtl");
    context.expect(!cache.find(1, start).has_value(), "dòng hết hạn đã bị bỏ");
    cache.put(2, Standing{.ok = false, .code = protocol::ErrorCode::kBusy}, start);
    context.expect(!cache.find(2, start).has_value(), "Busy không được nhớ");
    cache.put(3, Standing{.ok = false, .code = protocol::ErrorCode::kBadCredentials}, start);
    const std::optional<Standing> banned = cache.find(3, start);
    context.expect(banned && !banned->ok && banned->code == protocol::ErrorCode::kBadCredentials, "ban được nhớ");
    cache.put(3, Standing{.ok = true}, start + std::chrono::seconds{1});
    const std::optional<Standing> lifted = cache.find(3, start + std::chrono::seconds{1} + account::kStandingTtl / 2);
    context.expect(lifted && lifted->ok, "câu trả lời mới thay câu cũ");
}

// standing_cache_ms trong store.toml: TTL đổi được, 0 là không nhớ gì.
void standing_cache_ttl_is_configurable(Context& context) {
    using SteadyClock = account::StandingCache::Clock;
    const SteadyClock::time_point start = SteadyClock::time_point{std::chrono::seconds{100}};
    account::StandingCache longer{std::chrono::milliseconds{3000}};
    longer.put(1, account::Standing{.ok = true}, start);
    context.expect(longer.find(1, start + std::chrono::milliseconds{2999}).has_value(), "nhớ tới hạn cấu hình");
    context.expect(!longer.find(1, start + std::chrono::milliseconds{3000}).has_value(), "hết đúng hạn cấu hình");
    account::StandingCache off{std::chrono::milliseconds{0}};
    off.put(1, account::Standing{.ok = true}, start);
    context.expect(!off.find(1, start).has_value() && off.size() == 0, "TTL 0 thì không nhớ");
    context.expect(account::StandingCache{}.ttl() == account::kStandingTtl, "mặc định vẫn là kStandingTtl");
}

void standing_cache_stays_bounded(Context& context) {
    using SteadyClock = account::StandingCache::Clock;
    account::StandingCache cache;
    const SteadyClock::time_point start = SteadyClock::time_point{std::chrono::seconds{100}};
    for (std::uint64_t id = 0; id < account::kStandingRoom * 3; ++id) {
        cache.put(id, account::Standing{.ok = true}, start);
    }
    context.expect(cache.size() <= account::kStandingRoom, "không vượt sức chứa");
    const std::uint64_t last = (account::kStandingRoom * 3) - 1;
    context.expect(cache.find(last, start).has_value(), "dòng vừa ghi vẫn còn");
}

// Hồi quy: khoá HMAC của nhà cung cấp thanh toán từng không bị kiểm quyền, nên tệp ai đọc cũng được vẫn chạy.
void secret_files_must_be_private(Context& context) {
    namespace fs = std::filesystem;
    const fs::path dir = fs::temp_directory_path() / "thienlong-private-file-test";
    std::error_code ignored;
    fs::remove_all(dir, ignored);
    fs::create_directories(dir, ignored);
    context.expect(!ignored, "dựng được thư mục thử");

    const std::array<std::byte, 4> bytes{std::byte{1}, std::byte{2}, std::byte{3}, std::byte{4}};
    const fs::path mine = dir / "alpha.key";
    std::string error;
    bool existed = true;
    context.expect(secure::create_private_file(mine, bytes, "alpha.key", existed, error) && !existed,
        "tạo tệp riêng thành công");
    context.expect(secure::file_private(mine, "alpha.key", error), "tệp vừa tạo là riêng");
    context.expect(account::ipc_key_private(mine, error), "ipc_key_private vẫn là cùng phép kiểm");

    error.clear();
    context.expect(!secure::create_private_file(mine, bytes, "alpha.key", existed, error) && existed && error.empty(),
        "tệp đã có: không ghi đè, báo existed");

    const fs::path lax = dir / "beta.key";
    context.expect(write_world_readable(lax, "x"), "dựng được tệp mọi người đọc");
    error.clear();
    context.expect(!secure::file_private(lax, "beta.key", error), "tệp mọi người đọc bị từ chối");
    context.expect(error.contains("beta.key"), "câu lỗi nêu đúng tên tệp, không nhầm ipc.key");
    error.clear();
    context.expect(!account::ipc_key_private(lax, error) && error.contains("ipc.key"),
        "ipc_key_private vẫn nêu ipc.key");

    error.clear();
    context.expect(!secure::file_private(dir / "khong-co.key", "khong-co.key", error) && !error.empty(),
        "tệp thiếu: sai kèm lý do");
    fs::remove_all(dir, ignored);
}

constexpr std::array kCases{
    Case{.name = "secret_files_must_be_private", .body = &secret_files_must_be_private},
    Case{.name = "names_reject_junk", .body = &names_reject_junk},
    Case{.name = "sign_steps", .body = &sign_steps},
    Case{.name = "register_sign_and_ticket", .body = &register_sign_and_ticket},
    Case{.name = "eight_failures_then_rate", .body = &eight_failures_then_rate},
    Case{.name = "three_characters_then_one_slot", .body = &three_characters_then_one_slot},
    Case{.name = "enter_reply_carries_spot", .body = &enter_reply_carries_spot},
    Case{.name = "save_call_round_trip", .body = &save_call_round_trip},
    Case{.name = "play_record_round_trip_and_hostile", .body = &play_record_round_trip_and_hostile},
    Case{.name = "play_travels_through_save_and_enter", .body = &play_travels_through_save_and_enter},
    Case{.name = "sign_in_hides_unknown_name", .body = &sign_in_hides_unknown_name},
    Case{.name = "names_are_canonical", .body = &names_are_canonical},
    Case{.name = "cap_rejects_tamper", .body = &cap_rejects_tamper},
    Case{.name = "cap_rotation_revokes", .body = &cap_rotation_revokes},
    Case{.name = "names_block_confusables", .body = &names_block_confusables},
    Case{.name = "character_fold_covers_vietnamese", .body = &character_fold_covers_vietnamese},
    Case{.name = "duplicate_account_looks_like_bad_login", .body = &duplicate_account_looks_like_bad_login},
    Case{.name = "deleted_name_stays_reserved", .body = &deleted_name_stays_reserved},
    Case{.name = "look_rejects_unlisted", .body = &look_rejects_unlisted},
    Case{.name = "look_follows_configured_policy", .body = &look_follows_configured_policy},
    Case{.name = "sha256_of_empty", .body = &sha256_of_empty},
    Case{.name = "standing_cache_ttl_is_configurable", .body = &standing_cache_ttl_is_configurable},
    Case{.name = "standing_cache_expires_and_skips_busy", .body = &standing_cache_expires_and_skips_busy},
    Case{.name = "standing_cache_stays_bounded", .body = &standing_cache_stays_bounded},
};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
