/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/ipc/relay.cpp
 *  PHÂN HỆ   : Server / Ipc / Relay
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Mã hoá và giải mã thân các khung ipc giữa gate và zone (Attach, Moved,
 *    Place, Refuse, Close).
 *  - Bộ giải mã không tin byte nào: thân thiếu, thừa hay sai miền đều là
 *    nullopt.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "ipc/relay.hpp"

#include "protocol/wire.hpp"

#include <cmath>
#include <utility>

namespace game::ipc {
namespace {

constexpr std::uint16_t kAnyKind = 0;

// Writer chỉ biết ghi cả khung; thân relay không có đầu khung nên cắt đầu đi.
template <typename Fill>
[[nodiscard]] std::vector<std::byte> body_of(const Fill& fill) {
    std::vector<std::byte> framed;
    protocol::Writer writer{framed};
    fill(writer);
    if (!writer.finish(kAnyKind)) return {};
    framed.erase(framed.begin(), framed.begin() + static_cast<std::ptrdiff_t>(protocol::kHeaderBytes));
    return framed;
}

[[nodiscard]] bool finite(float value) noexcept { return std::isfinite(value); }

} // namespace

std::vector<std::byte> encode_body(const Attach& message) {
    return body_of([&](protocol::Writer& out) {
        out.u64(message.character);
        out.u64(message.account);
        out.u16(message.scene);
        out.f32(message.x_cm);
        out.f32(message.z_cm);
        out.u16(message.direction);
        out.text(message.name, protocol::kCharacterSummaryNameBytes);
        out.u16(message.level);
        out.u8(message.gender);
        out.u16(message.face);
        out.u16(message.hair);
        out.u8(message.school);
        out.u16(message.client_version);
        out.u32(static_cast<std::uint32_t>(message.play.size()));
        out.bytes(message.play);
    });
}

std::vector<std::byte> encode_body(const Moved& message) {
    return body_of([&](protocol::Writer& out) {
        out.f32(message.x_cm);
        out.f32(message.z_cm);
    });
}

std::vector<std::byte> encode_body(const Place& message) {
    return body_of([&](protocol::Writer& out) {
        out.f32(message.x_cm);
        out.f32(message.z_cm);
    });
}

std::vector<std::byte> encode_body(const Refuse& message) {
    return body_of([&](protocol::Writer& out) { out.u16(static_cast<std::uint16_t>(message.code)); });
}

std::vector<std::byte> encode_body(const Close& message) {
    return body_of([&](protocol::Writer& out) { out.u8(static_cast<std::uint8_t>(message.reason)); });
}

std::optional<Attach> decode_attach(std::span<const std::byte> body) {
    protocol::Reader in{body};
    Attach out;
    out.character = in.u64();
    out.account = in.u64();
    out.scene = in.u16();
    out.x_cm = in.f32();
    out.z_cm = in.f32();
    out.direction = in.u16();
    out.name = in.text(protocol::kCharacterSummaryNameBytes);
    out.level = in.u16();
    out.gender = in.u8();
    out.face = in.u16();
    out.hair = in.u16();
    out.school = in.u8();
    out.client_version = in.u16();
    const std::uint32_t play_bytes = in.u32();
    if (play_bytes > kPlayMax) return std::nullopt;
    if (play_bytes > 0 && in.is_ok()) {
        out.play.resize(play_bytes);
        in.bytes(out.play);
    }
    if (!in.finish() || !finite(out.x_cm) || !finite(out.z_cm)) return std::nullopt;
    if (out.gender != 1 && out.gender != 2) return std::nullopt;
    return out;
}

std::optional<Moved> decode_moved(std::span<const std::byte> body) {
    protocol::Reader in{body};
    Moved out;
    out.x_cm = in.f32();
    out.z_cm = in.f32();
    if (!in.finish() || !finite(out.x_cm) || !finite(out.z_cm)) return std::nullopt;
    return out;
}

std::optional<Place> decode_place(std::span<const std::byte> body) {
    protocol::Reader in{body};
    Place out;
    out.x_cm = in.f32();
    out.z_cm = in.f32();
    if (!in.finish() || !finite(out.x_cm) || !finite(out.z_cm)) return std::nullopt;
    return out;
}

std::optional<Refuse> decode_refuse(std::span<const std::byte> body) {
    protocol::Reader in{body};
    const auto code = static_cast<protocol::ErrorCode>(in.u16());
    if (!in.finish() || !protocol::is_valid(code)) return std::nullopt;
    return Refuse{.code = code};
}

std::optional<Close> decode_close(std::span<const std::byte> body) {
    protocol::Reader in{body};
    const auto reason = static_cast<protocol::DisconnectReason>(in.u8());
    if (!in.finish() || !protocol::is_valid(reason)) return std::nullopt;
    return Close{.reason = reason};
}

bool is_single_frame(std::span<const std::byte> bytes) noexcept {
    const protocol::FrameResult peeked = protocol::peek_frame(bytes, bytes.size());
    if (!peeked || !peeked->has_value()) return false;
    return protocol::kHeaderBytes + (*peeked)->body_bytes == bytes.size();
}

} // namespace game::ipc
