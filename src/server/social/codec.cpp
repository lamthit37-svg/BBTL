#include "social/codec.hpp"

#include "protocol/wire.hpp"

#include <cstdint>
#include <expected>
#include <string_view>

namespace game::social {

std::string_view describe(CodecError error) noexcept {
    switch (error) {
    case CodecError::kTruncated: return "khối dữ liệu bị cụt";
    case CodecError::kBadKind: return "khối dữ liệu sai loại";
    case CodecError::kBadVersion: return "phiên bản khối dữ liệu chưa hiểu";
    case CodecError::kBadValue: return "giá trị trong khối dữ liệu ngoài miền";
    case CodecError::kTrailing: return "khối dữ liệu còn byte thừa";
    case CodecError::kTooLarge: return "khối dữ liệu quá lớn";
    }
    return "lỗi khối dữ liệu lạ";
}

CodecError from_wire(protocol::WireError error) noexcept {
    switch (error) {
    case protocol::WireError::kTruncated: return CodecError::kTruncated;
    case protocol::WireError::kTrailingBytes: return CodecError::kTrailing;
    case protocol::WireError::kTooLong:
    case protocol::WireError::kBodyTooLarge: return CodecError::kTooLarge;
    case protocol::WireError::kBadText:
    case protocol::WireError::kNonFinite:
    case protocol::WireError::kBadEnum:
    case protocol::WireError::kBadFlags:
    case protocol::WireError::kUnknownKind:
    case protocol::WireError::kOutOfRange: return CodecError::kBadValue;
    }
    return CodecError::kBadValue;
}

std::expected<protocol::ByteView, CodecError> open_blob(protocol::ByteView bytes, std::uint16_t kind) {
    const auto peeked = protocol::peek_frame(bytes, protocol::kMaxBodyBytes);
    if (!peeked) return std::unexpected(from_wire(peeked.error()));
    if (!peeked->has_value()) return std::unexpected(CodecError::kTruncated);
    const protocol::Frame frame = **peeked;
    if (frame.kind != kind) return std::unexpected(CodecError::kBadKind);
    if (bytes.size() != protocol::kHeaderBytes + frame.body_bytes) {
        return std::unexpected(CodecError::kTrailing);
    }
    return bytes.subspan(protocol::kHeaderBytes, frame.body_bytes);
}

CodecResult finish_blob(protocol::Writer& writer, std::uint16_t kind) {
    const protocol::WireStatus status = writer.finish(kind);
    if (!status) return std::unexpected(from_wire(status.error()));
    return {};
}

CodecResult finish_read(const protocol::Reader& reader) {
    const protocol::WireStatus status = reader.finish();
    if (!status) return std::unexpected(from_wire(status.error()));
    return {};
}

} // namespace game::social
