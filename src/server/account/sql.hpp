#pragma once
// Bản PostgreSQL của sổ tài khoản và sổ nhân vật. Hai database khác nhau, hai lớp: auth không
// mở database game, store không mở database auth. Thứ tự quyết định trùng MemoryBook.

#include "account/book.hpp"
#include "account/cap.hpp"
#include "store/pg.hpp"

#include <array>
#include <cstdint>
#include <string>
#include <string_view>

namespace game::account {

struct AuthOptions {
    bool auto_register = false;
    std::int64_t gift_points = 0;
    int ttl_seconds = 300;
    int ops_limit = 2;
    int mem_limit_kib = 65536;
    std::string dummy_hash;
};

struct RedeemResult {
    bool ok = false;
    protocol::ErrorCode code = protocol::ErrorCode::kBusy;
    std::uint64_t account = 0;
    std::string name;
    std::array<std::byte, kCapBytes> cap{};
};

class AuthDb {
public:
    AuthDb(store::PgConn& conn, AuthOptions options);

    [[nodiscard]] TicketResult create_account(std::string_view name, std::string_view password, std::string_view ip);
    [[nodiscard]] TicketResult sign_in(std::string_view name, std::string_view password, std::string_view ip);
    [[nodiscard]] RedeemResult redeem(std::string_view ticket_hex);

private:
    store::PgConn& conn_;
    AuthOptions options_;
};

class GameDb {
public:
    explicit GameDb(store::PgConn& conn);

    [[nodiscard]] ListResult list(std::uint64_t account);
    [[nodiscard]] ListResult create_character(std::uint64_t account, std::string_view name, protocol::Gender gender,
        std::uint16_t face, std::uint16_t hair);
    [[nodiscard]] ListResult remove_character(std::uint64_t account, std::uint64_t character);
    [[nodiscard]] EnterResult enter(std::uint64_t account, std::uint64_t character);

private:
    store::PgConn& conn_;
};

} // namespace game::account
