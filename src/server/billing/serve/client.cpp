#include "billing/serve/client.hpp"

#include "account/ipc_key.hpp"
#include "account/rpc.hpp"
#include "billing/error.hpp"
#include "billing/rpc.hpp"
#include "net/net.hpp"
#include "secure/secure.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <utility>

namespace game::billing {
namespace {

// Kết quả khi không biết thao tác đã chạy hay chưa (mạng đứt, hết hạn, khung hỏng).
[[nodiscard]] Reply unknown_outcome() {
    return Reply{.code = wire_code(Error::kBusy), .body = {}};
}

} // namespace

Client::Client(net::Endpoint endpoint, const std::array<std::byte, account::kIpcKeyBytes>& key)
    : endpoint_(endpoint), key_(key) {
    net::NetResult<net::Network> started = net::Network::start();
    if (started) network_ = std::move(*started);
}

Client::~Client() {
    secure::wipe_bytes(key_);
}

Reply Client::call(const Request& request, std::chrono::milliseconds timeout) const {
    if (!network_) return unknown_outcome();
    const account::Call call{.op = static_cast<account::Op>(static_cast<std::uint16_t>(request.op)), .body = request.body};
    std::optional<account::Reply> reply = account::exchange(endpoint_, call, timeout, key_);
    if (!reply) return unknown_outcome();
    return Reply{.code = reply->code, .body = std::move(reply->body)};
}

} // namespace game::billing
