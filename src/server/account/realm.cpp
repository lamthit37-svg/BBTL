#include "account/realm.hpp"

#include "account/rpc.hpp"
#include "account/rules.hpp"
#include "secure/secure.hpp"

#include <chrono>
#include <utility>

namespace game::account {
namespace {

constexpr std::chrono::milliseconds kFast{3000};
constexpr std::chrono::milliseconds kPassword{8000};

void wipe_call(Call& call) {
    secure::wipe_bytes(call.body);
    call.body.clear();
}

[[nodiscard]] TicketReply pack_ticket(const TicketResult& ticket) {
    TicketReply reply;
    reply.code = ticket.code;
    if (!ticket.ok || ticket.hex.size() != kTicketHex) {
        if (ticket.ok) reply.code = protocol::ErrorCode::kBusy;
        return reply;
    }
    for (std::size_t index = 0; index < kTicketHex; ++index) {
        reply.token[index] = static_cast<std::byte>(ticket.hex[index]);
    }
    reply.ok = true;
    return reply;
}

[[nodiscard]] TicketReply ask_ticket(const net::Endpoint& endpoint, const Call& call, secure::ByteView key) {
    const std::optional<Reply> reply = exchange(endpoint, call, kPassword, key);
    if (!reply) return {};
    return pack_ticket(ticket_from(*reply));
}

[[nodiscard]] RosterReply roster_from(const ListResult& list, std::uint64_t account) {
    RosterReply reply;
    reply.code = list.code;
    if (!list.ok) return reply;
    reply.ok = true;
    reply.account = account;
    reply.characters = list.characters;
    return reply;
}

} // namespace

Realm::Realm(net::Endpoint auth, net::Endpoint store, std::array<std::byte, kIpcKeyBytes> key)
    : auth_(auth), store_(store), key_(key) {}

TicketReply Realm::create_account(std::string_view name, std::string_view password, std::string_view ip) const {
    Call call = account_call(Op::kCreateAccount, name, password, ip);
    const TicketReply reply = ask_ticket(auth_, call, key_);
    wipe_call(call);
    return reply;
}

TicketReply Realm::sign_in(std::string_view name, std::string_view password, std::string_view ip) const {
    Call call = account_call(Op::kSignIn, name, password, ip);
    const TicketReply reply = ask_ticket(auth_, call, key_);
    wipe_call(call);
    return reply;
}

RosterReply Realm::login(std::string_view name, std::string_view ticket_hex) const {
    Call call = redeem_call(ticket_hex);
    const std::optional<Reply> reply = exchange(auth_, call, kFast, key_);
    if (!reply) return {};
    const RedeemResult redeemed = redeem_from(*reply);
    if (!redeemed.ok) {
        RosterReply failed;
        failed.code = redeemed.code;
        return failed;
    }
    if (fold_ascii(name) != fold_ascii(redeemed.name)) {
        RosterReply failed;
        failed.code = protocol::ErrorCode::kBadCredentials;
        return failed;
    }
    const std::optional<Reply> listed = exchange(store_, list_call(redeemed.cap), kFast, key_);
    if (!listed) return {};
    RosterReply roster = roster_from(list_from(*listed), redeemed.account);
    if (!roster.ok) return roster;
    roster.cap = redeemed.cap;
    roster.has_cap = true;
    return roster;
}

RosterReply Realm::create_character(std::span<const std::byte, kCapBytes> cap, const protocol::CreateCharacter& request) const {
    const Call call = character_call(cap, request.name, request.gender, request.face, request.hair);
    const std::optional<Reply> reply = exchange(store_, call, kFast, key_);
    if (!reply) return {};
    return roster_from(list_from(*reply), 0);
}

RosterReply Realm::remove_character(std::span<const std::byte, kCapBytes> cap, std::uint64_t character) const {
    const Call call = id_call(Op::kDeleteCharacter, cap, character);
    const std::optional<Reply> reply = exchange(store_, call, kFast, key_);
    if (!reply) return {};
    return roster_from(list_from(*reply), 0);
}

EnterReply Realm::enter(std::span<const std::byte, kCapBytes> cap, std::uint64_t character) const {
    const Call call = id_call(Op::kEnter, cap, character);
    const std::optional<Reply> reply = exchange(store_, call, kFast, key_);
    if (!reply) return {};
    const EnterResult result = enter_from(*reply);
    EnterReply out;
    out.ok = result.ok;
    if (!result.ok) out.code = result.code;
    return out;
}

} // namespace game::account
