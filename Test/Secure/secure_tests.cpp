// Máy trạng thái bắt tay và bản ghi: lời chào hỏng, chữ ký sai, phát lại, đảo thứ tự, cắt cụt,
// hạ phiên bản, hai chiều, bộ đếm cạn, tệp khoá. Không ngủ và không mở socket.
#include "secure/secure.hpp"

#include "secure/private_file.hpp"

#include "core/check.hpp"
#include "support/lax_file.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <ios>
#include <span>
#include <string>
#include <system_error>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using secure::AbsorbResult;
using secure::ByteView;
using secure::ClientHandshake;
using secure::Error;
using secure::Identity;
using secure::PublicKey;
using secure::RecordPipe;
using secure::ServerHandshake;
using secure::SessionKeys;

constexpr std::size_t kPlain = secure::kMaxPlainBytes;

[[nodiscard]] ByteView view_of(std::string_view text) noexcept {
    return std::as_bytes(std::span{text.data(), text.size()});
}

struct Linked {
    RecordPipe server;
    RecordPipe client;
};

[[nodiscard]] Identity make_identity() {
    secure::Result<Identity> made = Identity::generate();
    core::check(made.has_value(), "sinh được khoá danh tính");
    return std::move(*made);
}

[[nodiscard]] Linked connect(const Identity& identity) {
    secure::Result<ClientHandshake> client = ClientHandshake::begin();
    core::check(client.has_value(), "client bắt đầu bắt tay được");
    ServerHandshake server{identity};
    const AbsorbResult absorbed = server.absorb(client->hello());
    core::check(absorbed.has_value() && server.is_done(), "server bắt tay xong");
    secure::Result<SessionKeys> client_keys = client->finish(server.reply(), identity.public_key());
    core::check(client_keys.has_value(), "client bắt tay xong");
    RecordPipe server_pipe{server.take_keys()};
    RecordPipe client_pipe{std::move(*client_keys)};
    return Linked{.server = std::move(server_pipe), .client = std::move(client_pipe)};
}

[[nodiscard]] std::vector<std::byte> sealed(RecordPipe& pipe, ByteView plain) {
    std::array<std::byte, secure::kMaxRecordBytes> out{};
    const secure::SealResult wrote = pipe.seal(plain, out);
    core::check(wrote.has_value(), "niêm được bản ghi");
    return {out.begin(), out.begin() + static_cast<std::ptrdiff_t>(*wrote)};
}

[[nodiscard]] std::vector<std::byte> opened(RecordPipe& pipe, ByteView record) {
    std::array<std::byte, kPlain> plain{};
    const secure::OpenResult read = pipe.open_bytes(record, plain);
    core::check(read.has_value(), "mở được bản ghi");
    return {plain.begin(), plain.begin() + static_cast<std::ptrdiff_t>(read->written)};
}

void expect_error(Context& context, const secure::OpenResult& result, Error error) {
    context.expect(!result.has_value() && result.error() == error, "đúng lỗi mở bản ghi");
}

void round_trip(Context& context) {
    const Identity identity = make_identity();
    Linked linked = connect(identity);
    const ByteView plain = view_of("xin chao");
    const std::vector<std::byte> record = sealed(linked.server, plain);
    const std::vector<std::byte> back = opened(linked.client, record);
    context.expect(std::ranges::equal(back, plain), "máy chủ gửi, client mở đúng");
    const std::vector<std::byte> reply = sealed(linked.client, view_of("pong"));
    const std::vector<std::byte> echoed = opened(linked.server, reply);
    context.expect(std::ranges::equal(echoed, view_of("pong")), "client gửi, máy chủ mở đúng");
}

void directions_do_not_open(Context& context) {
    const Identity identity = make_identity();
    Linked linked = connect(identity);
    const std::vector<std::byte> record = sealed(linked.server, view_of("chi-mot-chieu"));
    std::array<std::byte, kPlain> plain{};
    const secure::OpenResult read = linked.server.open_bytes(record, plain);
    expect_error(context, read, Error::kRecord);
    context.expect(linked.server.is_broken(), "mở nhầm chiều thì luồng hỏng");
}

void replay_is_rejected(Context& context) {
    const Identity identity = make_identity();
    Linked linked = connect(identity);
    const std::vector<std::byte> record = sealed(linked.client, view_of("mot"));
    const std::vector<std::byte> first = opened(linked.server, record);
    context.expect(std::ranges::equal(first, view_of("mot")), "lần đầu mở được");
    std::array<std::byte, kPlain> plain{};
    const secure::OpenResult again = linked.server.open_bytes(record, plain);
    expect_error(context, again, Error::kRecord);
}

void reorder_is_rejected(Context& context) {
    const Identity identity = make_identity();
    Linked linked = connect(identity);
    const std::vector<std::byte> first = sealed(linked.client, view_of("a"));
    const std::vector<std::byte> second = sealed(linked.client, view_of("b"));
    std::array<std::byte, kPlain> plain{};
    const secure::OpenResult read = linked.server.open_bytes(second, plain);
    expect_error(context, read, Error::kRecord);
    static_cast<void>(first);
}

void truncated_record_waits(Context& context) {
    const Identity identity = make_identity();
    Linked linked = connect(identity);
    const std::vector<std::byte> record = sealed(linked.client, view_of("cat"));
    const ByteView head{record.data(), 4};
    std::array<std::byte, kPlain> plain{};
    const secure::OpenResult read = linked.server.open_bytes(head, plain);
    context.expect(read.has_value() && read->written == 0, "chưa đủ byte thì chưa có bản rõ");
    context.expect(linked.server.has_partial(), "còn mẩu dở");
    context.expect(!linked.server.is_broken(), "mẩu dở chưa phải lỗi");
}

void short_length_is_protocol(Context& context) {
    const Identity identity = make_identity();
    Linked linked = connect(identity);
    const std::array<std::byte, 2> header{std::byte{16}, std::byte{0}};
    std::array<std::byte, kPlain> plain{};
    const secure::OpenResult read = linked.server.open_bytes(header, plain);
    expect_error(context, read, Error::kProtocol);
}

void huge_length_is_protocol(Context& context) {
    const Identity identity = make_identity();
    Linked linked = connect(identity);
    const std::array<std::byte, 2> header{std::byte{0xff}, std::byte{0xff}};
    std::array<std::byte, kPlain> plain{};
    const secure::OpenResult read = linked.server.open_bytes(header, plain);
    expect_error(context, read, Error::kProtocol);
}

void flipped_byte_is_record(Context& context) {
    const Identity identity = make_identity();
    Linked linked = connect(identity);
    std::vector<std::byte> record = sealed(linked.client, view_of("lat-bit"));
    record[6] = static_cast<std::byte>(static_cast<unsigned>(record[6]) ^ 0x01U);
    std::array<std::byte, kPlain> plain{};
    const secure::OpenResult read = linked.server.open_bytes(record, plain);
    expect_error(context, read, Error::kRecord);
}

void counter_does_not_wrap(Context& context) {
    const Identity identity = make_identity();
    Linked linked = connect(identity);
    const secure::CounterMarks marks{.send = secure::kCounterLast, .receive = 0};
    linked.client.advance_counters(marks);
    std::array<std::byte, 64> out{};
    const secure::SealResult wrote = linked.client.seal(view_of("het"), out);
    context.expect(!wrote.has_value() && wrote.error() == Error::kExhausted, "bộ đếm cạn thì không niêm");
    context.expect(linked.client.is_broken(), "luồng hỏng khi cạn bộ đếm");
}

void empty_plain_is_protocol(Context& context) {
    const Identity identity = make_identity();
    Linked linked = connect(identity);
    std::array<std::byte, 64> out{};
    const secure::SealResult wrote = linked.client.seal({}, out);
    context.expect(!wrote.has_value() && wrote.error() == Error::kProtocol, "bản rõ rỗng bị từ chối");
    context.expect(!linked.client.is_broken(), "từ chối bản rõ rỗng không làm hỏng luồng");
}

void small_buffer_is_capacity(Context& context) {
    const Identity identity = make_identity();
    Linked linked = connect(identity);
    std::array<std::byte, 4> out{};
    const secure::SealResult wrote = linked.client.seal(view_of("dai"), out);
    context.expect(!wrote.has_value() && wrote.error() == Error::kCapacity, "hộp gửi nhỏ thì không niêm");
    context.expect(!linked.client.is_broken(), "thiếu chỗ không làm hỏng luồng");
}

void bad_magic_has_no_reply(Context& context) {
    const Identity identity = make_identity();
    secure::Result<ClientHandshake> client = ClientHandshake::begin();
    core::check(client.has_value(), "client bắt đầu được");
    std::array<std::byte, secure::kClientHelloBytes> hello{};
    std::memcpy(hello.data(), client->hello().data(), hello.size());
    hello[0] = std::byte{'X'};
    ServerHandshake server{identity};
    const AbsorbResult absorbed = server.absorb(hello);
    context.expect(!absorbed.has_value() && absorbed.error() == Error::kProtocol, "nhãn sai là lỗi giao thức");
    context.expect(server.reply().empty(), "nhãn sai thì không trả lời");
}

void downgrade_has_no_reply(Context& context) {
    const Identity identity = make_identity();
    secure::Result<ClientHandshake> client = ClientHandshake::begin();
    core::check(client.has_value(), "client bắt đầu được");
    std::array<std::byte, secure::kClientHelloBytes> hello{};
    std::memcpy(hello.data(), client->hello().data(), hello.size());
    hello[secure::kLabelBytes] = std::byte{0};
    hello[secure::kLabelBytes + 1] = std::byte{0};
    ServerHandshake server{identity};
    const AbsorbResult absorbed = server.absorb(hello);
    context.expect(!absorbed.has_value() && absorbed.error() == Error::kProtocol, "phiên bản 0 bị từ chối");
    context.expect(server.reply().empty(), "hạ phiên bản thì không trả lời");
}

void partial_hello_then_rest(Context& context) {
    const Identity identity = make_identity();
    secure::Result<ClientHandshake> client = ClientHandshake::begin();
    core::check(client.has_value(), "client bắt đầu được");
    const ByteView hello = client->hello();
    ServerHandshake server{identity};
    const AbsorbResult first = server.absorb(hello.first(10));
    context.expect(first.has_value() && !server.is_done() && !server.is_broken(), "chưa đủ lời chào");
    const AbsorbResult rest = server.absorb(hello.subspan(10));
    context.expect(rest.has_value() && server.is_done(), "nốt lời chào thì xong");
}

void extra_hello_bytes_stay(Context& context) {
    const Identity identity = make_identity();
    secure::Result<ClientHandshake> client = ClientHandshake::begin();
    core::check(client.has_value(), "client bắt đầu được");
    std::vector<std::byte> bytes{client->hello().begin(), client->hello().end()};
    bytes.push_back(std::byte{0xab});
    ServerHandshake server{identity};
    const AbsorbResult absorbed = server.absorb(bytes);
    context.expect(absorbed.has_value() && absorbed->consumed == secure::kClientHelloBytes, "chỉ lấy đúng lời chào");
}

void bad_signature_makes_no_keys(Context& context) {
    const Identity identity = make_identity();
    secure::Result<ClientHandshake> client = ClientHandshake::begin();
    core::check(client.has_value(), "client bắt đầu được");
    ServerHandshake server{identity};
    const AbsorbResult absorbed = server.absorb(client->hello());
    core::check(absorbed.has_value(), "server nhận lời chào");
    std::array<std::byte, secure::kServerHelloBytes> reply{};
    std::memcpy(reply.data(), server.reply().data(), reply.size());
    reply.back() = static_cast<std::byte>(static_cast<unsigned>(reply.back()) ^ 0x01U);
    const secure::Result<SessionKeys> keys = client->finish(reply, identity.public_key());
    context.expect(!keys.has_value() && keys.error() == Error::kAuthentication, "chữ ký sai thì không có khoá");
}

void wrong_pin_is_authentication(Context& context) {
    const Identity identity = make_identity();
    const Identity other = make_identity();
    secure::Result<ClientHandshake> client = ClientHandshake::begin();
    core::check(client.has_value(), "client bắt đầu được");
    ServerHandshake server{identity};
    const AbsorbResult absorbed = server.absorb(client->hello());
    core::check(absorbed.has_value(), "server nhận lời chào");
    const secure::Result<SessionKeys> keys = client->finish(server.reply(), other.public_key());
    context.expect(!keys.has_value() && keys.error() == Error::kAuthentication, "ghim sai khoá thì từ chối");
}

void same_hello_two_keys(Context& context) {
    const Identity identity = make_identity();
    secure::Result<ClientHandshake> client = ClientHandshake::begin();
    core::check(client.has_value(), "client bắt đầu được");
    const ByteView hello = client->hello();
    ServerHandshake first{identity};
    ServerHandshake second{identity};
    core::check(first.absorb(hello).has_value(), "lần một");
    core::check(second.absorb(hello).has_value(), "lần hai");
    const SessionKeys one = first.take_keys();
    const SessionKeys two = second.take_keys();
    const bool differ = one.send != two.send || one.receive != two.receive;
    context.expect(differ, "cùng lời chào vẫn ra hai khoá phiên");
    context.expect(!std::ranges::equal(first.reply(), second.reply()), "hai lời đáp khác nhau");
}

void broken_stays_broken(Context& context) {
    const Identity identity = make_identity();
    ServerHandshake server{identity};
    const std::array<std::byte, secure::kClientHelloBytes> garbage{};
    const AbsorbResult first = server.absorb(garbage);
    context.expect(!first.has_value(), "lời chào rỗng nhãn là lỗi");
    const AbsorbResult again = server.absorb(garbage);
    context.expect(!again.has_value() && again.error() == first.error(), "lỗi sau giữ nguyên lỗi đầu");
}

void short_reply_is_protocol(Context& context) {
    const Identity identity = make_identity();
    secure::Result<ClientHandshake> client = ClientHandshake::begin();
    core::check(client.has_value(), "client bắt đầu được");
    const std::array<std::byte, 8> reply{};
    const secure::Result<SessionKeys> keys = client->finish(reply, identity.public_key());
    context.expect(!keys.has_value() && keys.error() == Error::kProtocol, "lời đáp cụt là lỗi giao thức");
}

[[nodiscard]] std::filesystem::path scratch_dir() {
    const std::filesystem::path path = std::filesystem::temp_directory_path() / "thienlong-secure-key";
    std::error_code error;
    std::filesystem::remove_all(path, error);
    std::filesystem::create_directories(path, error);
    core::check(!error, "tạo được thư mục thử khoá");
    return path;
}

void remove_scratch(const std::filesystem::path& path) {
    std::error_code error;
    std::filesystem::remove_all(path, error);
}

void key_file_round_trip(Context& context) {
    const std::filesystem::path dir = scratch_dir();
    const std::filesystem::path file = dir / "identity.key";
    const Identity identity = make_identity();
    const PublicKey created = identity.public_key();
    context.expect(identity.store_new(file).has_value(), "ghi được tệp khoá");
    const secure::Result<Identity> loaded = Identity::load(file);
    context.expect(loaded.has_value(), "đọc lại được tệp khoá");
    const bool same = loaded.has_value() && loaded->public_key().bytes == created.bytes;
    context.expect(same, "khoá công khai khớp");
    const secure::Result<void> again = identity.store_new(file);
    context.expect(!again.has_value() && again.error() == Error::kExists, "không ghi đè tệp đã có");
    remove_scratch(dir);
}

void missing_key_is_not_found(Context& context) {
    const std::filesystem::path dir = scratch_dir();
    const secure::Result<Identity> loaded = Identity::load(dir / "khong-co.key");
    context.expect(!loaded.has_value() && loaded.error() == Error::kNotFound, "thiếu tệp là không thấy");
    remove_scratch(dir);
}

// Thư mục không phải tệp khoá. CreateFile từ chối thư mục; phải ra không thấy, không phải lỗi đĩa.
void directory_key_is_not_found(Context& context) {
    const std::filesystem::path dir = scratch_dir();
    const secure::Result<Identity> loaded = Identity::load(dir);
    context.expect(!loaded.has_value() && loaded.error() == Error::kNotFound, "thư mục không phải tệp khoá");
    remove_scratch(dir);
}

void short_key_is_corrupt(Context& context) {
    const std::filesystem::path dir = scratch_dir();
    const std::filesystem::path file = dir / "identity.key";
    const std::array<std::byte, 8> bytes{};
    bool existed = false;
    std::string error;
    // Tệp riêng để phép kiểm quyền qua, chỉ còn cỡ sai.
    core::check(secure::create_private_file(file, bytes, "identity.key", existed, error), "ghi đủ tệp ngắn");
    const secure::Result<Identity> loaded = Identity::load(file);
    context.expect(!loaded.has_value() && loaded.error() == Error::kCorrupt, "sai cỡ là tệp hỏng");
    remove_scratch(dir);
}

// Hồi quy: store_new từng ghi tệp bằng ofstream, nên khoá danh tính mang quyền kế thừa của thư mục (máy chủ thử ở ổ D:
// Authenticated Users được sửa, Users được đọc). Thư mục ở đây cho mọi người toàn quyền: tệp vẫn phải ra riêng.
void stored_key_is_private(Context& context) {
    const std::filesystem::path dir = scratch_dir();
    context.expect(game::test::open_dir_to_everyone(dir), "mở được thư mục thử cho mọi người");
    const std::filesystem::path file = dir / "identity.key";
    const Identity identity = make_identity();
    context.expect(identity.store_new(file).has_value(), "ghi được tệp khoá");
    std::string error;
    context.expect(secure::file_private(file, "identity.key", error), "tệp khoá vừa ghi là riêng");
    context.expect(Identity::load(file).has_value(), "đọc lại được tệp khoá");
    remove_scratch(dir);
}

// Hồi quy: load từng đọc tệp khoá mà ai cũng đọc được. Quyền xét trước nội dung, nên 64 byte rác cũng ra kExposed.
void exposed_key_is_refused(Context& context) {
    const std::filesystem::path dir = scratch_dir();
    const std::filesystem::path file = dir / "identity.key";
    context.expect(game::test::write_world_readable(file, std::string(secure::kSecretBytes, 'x')), "dựng được tệp lỏng");
    const secure::Result<Identity> loaded = Identity::load(file);
    context.expect(!loaded.has_value() && loaded.error() == Error::kExposed, "tệp khoá lỏng quyền bị từ chối");
    remove_scratch(dir);
}

// Hồi quy: grants_read cũ bỏ qua FILE_GENERIC_WRITE. Everyone ghi được thì ghi đè khoá rồi siết DACL.
void writable_key_is_refused(Context& context) {
    const std::filesystem::path dir = scratch_dir();
    const std::filesystem::path file = dir / "identity.key";
    const std::string bytes(secure::kSecretBytes, 'x');
    context.expect(game::test::write_world_writable(file, bytes), "dựng được tệp ai cũng ghi");
    std::string error;
    context.expect(!secure::file_private(file, "identity.key", error) && !error.empty(), "tệp ai cũng ghi không riêng");
    const secure::Result<Identity> loaded = Identity::load(file);
    context.expect(!loaded.has_value() && loaded.error() == Error::kExposed, "nạp khoá ai cũng ghi là lộ");
    remove_scratch(dir);
}

void flipped_key_is_corrupt(Context& context) {
    const std::filesystem::path dir = scratch_dir();
    const std::filesystem::path file = dir / "identity.key";
    const Identity identity = make_identity();
    core::check(identity.store_new(file).has_value(), "ghi tệp để sửa");
    {
        std::fstream raw{file, std::ios::binary | std::ios::in | std::ios::out};
        core::check(static_cast<bool>(raw), "mở lại được tệp khoá");
        raw.seekg(40);
        const int byte = raw.get();
        core::check(byte != std::char_traits<char>::eof(), "đọc được một byte");
        raw.seekp(40);
        raw.put(static_cast<char>(byte ^ 0x01));
        raw.flush();
        core::check(static_cast<bool>(raw), "lật được một bit");
    }
    const secure::Result<Identity> loaded = Identity::load(file);
    context.expect(!loaded.has_value() && loaded.error() == Error::kCorrupt, "lệch một bit là tệp hỏng");
    remove_scratch(dir);
}

void wiped_after_destroy(Context& context) {
    alignas(Identity) std::array<std::byte, sizeof(Identity)> storage{};
    secure::Result<Identity> made = Identity::generate();
    core::check(made.has_value(), "sinh được khoá để xoá");
    // Placement new vào vùng mình sở hữu để đọc byte sau huỷ (SH-04).
    // NOLINTNEXTLINE(cppcoreguidelines-owning-memory, modernize-use-auto)
    Identity* live = new (storage.data()) Identity(std::move(*made));
    live->~Identity();
    const bool gone = std::ranges::all_of(storage, [](std::byte byte) { return byte == std::byte{0}; });
    context.expect(gone, "huỷ khoá thì vùng nhớ về 0");
}

[[nodiscard]] bool is_hex_letter(char letter) noexcept {
    const bool digit = letter >= '0' && letter <= '9';
    const bool lower = letter >= 'a' && letter <= 'f';
    return digit || lower;
}

void public_hex_is_lowercase(Context& context) {
    const Identity identity = make_identity();
    const std::string hex = secure::hex_encode(identity.public_key().bytes);
    context.expect(hex.size() == secure::kPublicBytes * 2, "hex đủ 64 chữ số");
    context.expect(std::ranges::all_of(hex, is_hex_letter), "hex thường");
}

constexpr std::array kCases{
    Case{.name = "round_trip", .body = round_trip},
    Case{.name = "directions_do_not_open", .body = directions_do_not_open},
    Case{.name = "replay_is_rejected", .body = replay_is_rejected},
    Case{.name = "reorder_is_rejected", .body = reorder_is_rejected},
    Case{.name = "truncated_record_waits", .body = truncated_record_waits},
    Case{.name = "short_length_is_protocol", .body = short_length_is_protocol},
    Case{.name = "huge_length_is_protocol", .body = huge_length_is_protocol},
    Case{.name = "flipped_byte_is_record", .body = flipped_byte_is_record},
    Case{.name = "counter_does_not_wrap", .body = counter_does_not_wrap},
    Case{.name = "empty_plain_is_protocol", .body = empty_plain_is_protocol},
    Case{.name = "small_buffer_is_capacity", .body = small_buffer_is_capacity},
    Case{.name = "bad_magic_has_no_reply", .body = bad_magic_has_no_reply},
    Case{.name = "downgrade_has_no_reply", .body = downgrade_has_no_reply},
    Case{.name = "partial_hello_then_rest", .body = partial_hello_then_rest},
    Case{.name = "extra_hello_bytes_stay", .body = extra_hello_bytes_stay},
    Case{.name = "bad_signature_makes_no_keys", .body = bad_signature_makes_no_keys},
    Case{.name = "wrong_pin_is_authentication", .body = wrong_pin_is_authentication},
    Case{.name = "same_hello_two_keys", .body = same_hello_two_keys},
    Case{.name = "broken_stays_broken", .body = broken_stays_broken},
    Case{.name = "short_reply_is_protocol", .body = short_reply_is_protocol},
    Case{.name = "key_file_round_trip", .body = key_file_round_trip},
    Case{.name = "missing_key_is_not_found", .body = missing_key_is_not_found},
    Case{.name = "directory_key_is_not_found", .body = directory_key_is_not_found},
    Case{.name = "short_key_is_corrupt", .body = short_key_is_corrupt},
    Case{.name = "stored_key_is_private", .body = stored_key_is_private},
    Case{.name = "exposed_key_is_refused", .body = exposed_key_is_refused},
    Case{.name = "writable_key_is_refused", .body = writable_key_is_refused},
    Case{.name = "flipped_key_is_corrupt", .body = flipped_key_is_corrupt},
    Case{.name = "wiped_after_destroy", .body = wiped_after_destroy},
    Case{.name = "public_hex_is_lowercase", .body = public_hex_is_lowercase},
};

} // namespace
} // namespace game::test

int main() {
    const std::int32_t failures = game::test::run_all(game::test::kCases);
    return failures == 0 ? 0 : 1;
}
