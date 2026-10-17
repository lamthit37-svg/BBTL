/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/net/carrier.cpp
 *  PHÂN HỆ   : Net / Carrier
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Mặt trước của carrier. Codec, đường gửi và đường nhận nằm ở tệp riêng.
 *  - Nguồn: GameNetworkingSockets v1.6.1 commit d534c19. Một luồng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "net/carrier.hpp"

#include "net/detail/pipe.hpp"

#include <memory>
#include <utility>

namespace game::net {

struct Carrier::Impl {
    explicit Impl(CarrierConfig config) : state(detail::make_state(config)) {}

    detail::State state;
};

Carrier::Carrier() : Carrier(CarrierConfig{}) {}

Carrier::Carrier(CarrierConfig config) : impl_(std::make_unique<Impl>(config)) {}

Carrier::~Carrier() = default;

Carrier::Carrier(Carrier&& other) noexcept = default;

Carrier& Carrier::operator=(Carrier&& other) noexcept = default;

bool Carrier::send(std::uint8_t lane, Delivery delivery, std::span<const std::byte> payload) {
    return detail::send_message(impl_->state, lane, delivery, payload);
}

bool Carrier::write_packet(std::span<std::byte> out, std::size_t& written, std::uint64_t now_ms) {
    return detail::write_one(impl_->state, out, written, now_ms);
}

bool Carrier::read_packet(std::span<const std::byte> packet, std::uint64_t now_ms) {
    return detail::read_one(impl_->state, packet, now_ms);
}

bool Carrier::take(CarrierMessage& out) {
    if (impl_->state.ready.empty()) return false;
    out = std::move(impl_->state.ready.front());
    impl_->state.ready.pop_front();
    return true;
}

std::uint32_t Carrier::reliable_bytes() const noexcept {
    return impl_->state.reliable_bytes;
}

} // namespace game::net
