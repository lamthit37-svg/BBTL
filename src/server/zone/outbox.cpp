/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/zone/outbox.cpp
 *  PHÂN HỆ   : Server / Zone / Outbox
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Gom vị trí đã đủ điều kiện gửi trong cùng một lượt, theo từng người nhận,
 *    thành một hoặc nhiều EntityPosBatch. Đầy số mục hoặc đầy byte thì tách
 *    lô, không bỏ cập nhật và không gửi lô rỗng.
 *  - Mỗi vị trí được mã hoá một lần thành 19 byte rồi chép vào bộ đệm của người
 *    nhận. Chốt lô trước tin khác của cùng người, và khi đọc thư.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "zone/outbox.hpp"

#include "protocol/wire.hpp"

#include <algorithm>
#include <cstdint>

namespace game::zone {
namespace {

constexpr std::size_t kRawReserve = kPosBinReserve * kPosEntryBytes;

} // namespace

std::size_t Outbox::fit_count(std::size_t available) noexcept {
    const std::size_t cap = protocol::kEntityPosBatchPlacesCount;
    std::size_t count = 0;
    std::size_t bytes = protocol::kHeaderBytes + 2;
    while (count < available && count < cap && bytes + kPosEntryBytes <= kPosFrameMax) {
        bytes += kPosEntryBytes;
        ++count;
    }
    return count;
}

Outbox::PosBlob Outbox::blob(const protocol::EntityPos& pos) {
    frame_buf_.clear();
    protocol::Writer writer(frame_buf_);
    writer.u32(pos.id);
    writer.f32(pos.x_cm);
    writer.f32(pos.z_cm);
    writer.u16(pos.direction);
    writer.u32(pos.tick);
    writer.u8(static_cast<std::uint8_t>(pos.state));
    PosBlob coded;
    if (frame_buf_.size() < protocol::kHeaderBytes + kPosEntryBytes || !writer.is_ok()) {
        ++failures_;
        return coded;
    }
    const auto start = frame_buf_.begin() + static_cast<std::ptrdiff_t>(protocol::kHeaderBytes);
    std::copy_n(start, kPosEntryBytes, coded.bytes.begin());
    return coded;
}

Outbox::PosBin& Outbox::bin_of(std::uint64_t session) {
    const auto found = index_.find(session);
    if (found != index_.end()) return bins_[found->second];
    PosBin created;
    created.session = session;
    if (!spare_.empty()) {
        created.raw = std::move(spare_.back());
        spare_.pop_back();
    }
    if (created.raw.capacity() < kRawReserve) created.raw.reserve(kRawReserve);
    bins_.push_back(std::move(created));
    const auto slot = static_cast<std::uint32_t>(bins_.size() - 1);
    index_.emplace(session, slot);
    return bins_.back();
}

void Outbox::stage_blob(std::uint64_t session, const PosBlob& blob) {
    if (session == 0) return;
    PosBin& bin = bin_of(session);
    bin.used = true;
    const std::size_t at = bin.raw.size();
    bin.raw.resize(at + kPosEntryBytes);
    const auto dest = bin.raw.begin() + static_cast<std::ptrdiff_t>(at);
    std::copy_n(blob.bytes.begin(), kPosEntryBytes, dest);
}

void Outbox::emit_raw(std::uint64_t session, std::span<const std::byte> raw) {
    frame_buf_.clear();
    protocol::Writer writer(frame_buf_);
    const std::size_t count = raw.size() / kPosEntryBytes;
    writer.count(count, protocol::kEntityPosBatchPlacesCount);
    writer.bytes(raw);
    if (!writer.finish(protocol::EntityPosBatch::kKind)) {
        ++failures_;
        return;
    }
    Letter letter;
    letter.kind = ipc::Relay::kDown;
    letter.session = session;
    letter.body = frame_buf_;
    letters_.push_back(std::move(letter));
}

void Outbox::flush_bin(PosBin& bin) {
    std::size_t at = 0;
    while (at < bin.raw.size()) {
        const std::size_t left = (bin.raw.size() - at) / kPosEntryBytes;
        const std::size_t count = fit_count(left);
        if (count == 0) break;
        const std::size_t bytes = count * kPosEntryBytes;
        const auto raw = std::span<const std::byte>{bin.raw}.subspan(at, bytes);
        emit_raw(bin.session, raw);
        at += bytes;
    }
    bin.raw.clear();
}

void Outbox::flush_session(std::uint64_t session) {
    const auto found = index_.find(session);
    if (found == index_.end()) return;
    flush_bin(bins_[found->second]);
}

void Outbox::recycle_at(std::size_t at) {
    spare_.push_back(std::move(bins_[at].raw));
    index_.erase(bins_[at].session);
    const std::size_t last = bins_.size() - 1;
    if (at != last) {
        bins_[at] = std::move(bins_[last]);
        index_[bins_[at].session] = static_cast<std::uint32_t>(at);
    }
    bins_.pop_back();
}

void Outbox::step_compact(std::size_t& at) {
    if (!bins_[at].used) {
        recycle_at(at);
        return;
    }
    bins_[at].used = false;
    ++at;
}

void Outbox::compact() {
    std::size_t at = 0;
    while (at < bins_.size())
        step_compact(at);
}

void Outbox::flush_all() {
    std::size_t at = 0;
    while (at < bins_.size()) {
        flush_bin(bins_[at]);
        ++at;
    }
    compact();
}

const std::vector<Letter>& Outbox::letters() {
    flush_all();
    return letters_;
}

std::vector<Letter> Outbox::take() {
    flush_all();
    return std::exchange(letters_, {});
}

void Outbox::clear() noexcept {
    letters_.clear();
    std::size_t at = 0;
    while (at < bins_.size()) {
        bins_[at].raw.clear();
        bins_[at].used = false;
        ++at;
    }
}

} // namespace game::zone
