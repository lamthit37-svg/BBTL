#pragma once
// Phía gate nói với auth (vé) và store (nhân vật). Không mở database.
// Vé trên dây của protocol là 204 byte: 64 byte đầu là hex thường của 32 byte ngẫu nhiên, phần còn
// lại là 0. Login.ticket mang đúng 64 chữ hex đó, không mang cả 204 byte vì trường ticket là text.

#include "account/cap.hpp"
#include "account/ipc_key.hpp"
#include "net/net.hpp"
#include "protocol/messages.hpp"

#include <array>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::account {

struct TicketReply {
    protocol::ErrorCode code = protocol::ErrorCode::kBusy;
    bool ok = false;
    std::array<std::byte, protocol::kTicketTokenBytes> token{};
};

struct RosterReply {
    protocol::ErrorCode code = protocol::ErrorCode::kBusy;
    bool ok = false;
    std::uint64_t account = 0;
    std::vector<protocol::CharacterSummary> characters;
    std::array<std::byte, kCapBytes> cap{};
    bool has_cap = false;
};

// ok thì scene/x_cm/z_cm là điểm vào store giữ cho nhân vật (centimet).
struct EnterReply {
    protocol::ErrorCode code = protocol::ErrorCode::kBusy;
    bool ok = false;
    std::uint16_t scene = 0;
    float x_cm = 0.0F;
    float z_cm = 0.0F;
};

class Realm {
public:
    Realm(net::Endpoint auth, net::Endpoint store, std::array<std::byte, kIpcKeyBytes> key);

    [[nodiscard]] TicketReply create_account(std::string_view name, std::string_view password,
        std::string_view ip) const;
    [[nodiscard]] TicketReply sign_in(std::string_view name, std::string_view password, std::string_view ip) const;
    [[nodiscard]] RosterReply login(std::string_view name, std::string_view ticket_hex) const;
    [[nodiscard]] RosterReply create_character(std::span<const std::byte, kCapBytes> cap,
        const protocol::CreateCharacter& request) const;
    [[nodiscard]] RosterReply remove_character(std::span<const std::byte, kCapBytes> cap, std::uint64_t character) const;
    [[nodiscard]] EnterReply enter(std::span<const std::byte, kCapBytes> cap, std::uint64_t character) const;

private:
    net::Endpoint auth_;
    net::Endpoint store_;
    std::array<std::byte, kIpcKeyBytes> key_;
};

} // namespace game::account
