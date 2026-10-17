/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/net/inlet.cpp
 *  PHÂN HỆ   : Net / Carrier / Inlet
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hàng nhận: ghép mảnh, giữ thứ tự tin cậy trong lane, bỏ gói trùng.
 *  - Nguồn thuật toán: GameNetworkingSockets v1.6.1 commit d534c19.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "net/detail/pipe.hpp"

#include "core/check.hpp"

#include <algorithm>
#include <array>
#include <utility>

namespace game::net::detail {

bool storage_test(const State& state, std::uint16_t number) noexcept {
    const std::size_t index = static_cast<std::size_t>(number % kWindow);
    const std::uint64_t word = state.recv_bits[index / 64U];
    const std::uint64_t mask = 1ULL << (index % 64U);
    return (word & mask) != 0;
}
void storage_set(State& state, std::uint16_t number, bool on) noexcept {
    const std::size_t index = static_cast<std::size_t>(number % kWindow);
    const std::uint64_t mask = 1ULL << (index % 64U);
    if (on) state.recv_bits[index / 64U] |= mask;
    if (!on) state.recv_bits[index / 64U] &= ~mask;
}
void clear_forward(State& state, std::uint16_t from, std::uint16_t to) {
    std::uint16_t cursor = from;
    while (cursor != to) {
        cursor = static_cast<std::uint16_t>(cursor + 1U);
        storage_set(state, cursor, false);
    }
}
Place classify(const State& state, std::uint16_t number, std::uint16_t stop_before) {
    if (seq_before(number, stop_before)) return Place::kStale;
    if (!state.have_recv) return Place::kFresh;
    const auto ahead = static_cast<std::uint16_t>(number - state.highest);
    if (ahead == 0) return Place::kDup;
    if (ahead < kWindow) return Place::kFresh;
    const auto behind = static_cast<std::uint16_t>(state.highest - number);
    if (behind < kWindow && storage_test(state, number)) return Place::kDup;
    if (behind < kWindow) return Place::kFresh;
    return Place::kFar;
}
void remember_fresh(State& state, std::uint16_t number) {
    if (!state.have_recv) {
        state.have_recv = true;
        state.highest = number;
        storage_set(state, number, true);
        return;
    }
    const auto ahead = static_cast<std::uint16_t>(number - state.highest);
    if (ahead != 0 && ahead < kWindow) {
        clear_forward(state, state.highest, number);
        state.highest = number;
    }
    storage_set(state, number, true);
}
bool frame_fits(const State& state, const Frame& frame) {
    if (frame.kind != kKindReliable) return true;
    const LaneIn& lane = state.incoming[frame.lane];
    if (seq_before(frame.message, lane.next_reliable)) return true;
    const auto ahead = static_cast<std::uint16_t>(frame.message - lane.next_reliable);
    return ahead < kRecvWindow;
}
bool all_fit(const State& state, const std::vector<Frame>& frames) {
    for (const Frame& frame : frames) {
        if (!frame_fits(state, frame)) return false;
    }
    return true;
}
Piece* find_piece(std::vector<Piece>& pieces, std::uint16_t message) {
    for (Piece& piece : pieces) {
        if (piece.message == message) return &piece;
    }
    return nullptr;
}
void erase_piece(std::vector<Piece>& pieces, std::uint16_t message) {
    for (std::size_t index = 0; index < pieces.size(); ++index) {
        if (pieces[index].message != message) continue;
        pieces.erase(pieces.begin() + static_cast<std::ptrdiff_t>(index));
        return;
    }
}
Piece& add_piece(std::vector<Piece>& pieces, std::uint16_t message, std::uint16_t count) {
    pieces.push_back(Piece{});
    Piece& piece = pieces.back();
    piece.message = message;
    piece.count = count;
    piece.parts.resize(count);
    piece.have.resize(count);
    return piece;
}
bool store_piece(std::vector<Piece>& pieces, const Frame& frame) {
    Piece* found = find_piece(pieces, frame.message);
    if (found == nullptr) found = &add_piece(pieces, frame.message, frame.count);
    if (found->count != frame.count || frame.index >= found->have.size()) return false;
    if (found->have[frame.index] != 0) return true;
    found->parts[frame.index].assign(frame.payload.begin(), frame.payload.end());
    found->have[frame.index] = 1;
    ++found->got;
    return true;
}
void append_part(std::vector<std::byte>& out, const std::vector<std::byte>& part) {
    out.insert(out.end(), part.begin(), part.end());
}
std::size_t part_total(const Piece& piece) {
    std::size_t total = 0;
    for (const std::vector<std::byte>& part : piece.parts)
        total += part.size();
    return total;
}
bool build_message(const Piece& piece, std::vector<std::byte>& out) {
    const std::size_t total = part_total(piece);
    if (total == 0 || total > kCarrierMessageMax) return false;
    out.clear();
    out.reserve(total);
    for (const std::vector<std::byte>& part : piece.parts)
        append_part(out, part);
    return out.size() == total;
}
bool piece_complete(const Piece& piece) noexcept {
    return piece.count > 0 && piece.got == piece.count;
}
std::uint8_t lane_of(const State& state, const LaneIn& lane) noexcept {
    for (std::uint8_t index = 0; index < kCarrierLanes; ++index) {
        if (&state.incoming[index] == &lane) return index;
    }
    return 0;
}
bool deliver_ready(State& state, LaneIn& lane) {
    Piece* found = find_piece(lane.reliable, lane.next_reliable);
    if (found == nullptr || !piece_complete(*found)) return false;
    CarrierMessage message;
    message.lane = lane_of(state, lane);
    message.delivery = Delivery::kReliable;
    if (!build_message(*found, message.bytes)) return false;
    state.ready.push_back(std::move(message));
    erase_piece(lane.reliable, lane.next_reliable);
    lane.next_reliable = static_cast<std::uint16_t>(lane.next_reliable + 1U);
    if (lane.next_reliable == 0) lane.next_reliable = 1;
    return true;
}
void flush_reliable(State& state, LaneIn& lane) {
    while (deliver_ready(state, lane))
        continue;
}
bool already_done(const LaneIn& lane, std::uint16_t message) {
    for (std::uint8_t index = 0; index < lane.done_count; ++index) {
        if (lane.done[index] == message) return true;
    }
    return false;
}
void remember_done(LaneIn& lane, std::uint16_t message) {
    lane.done[lane.done_cursor] = message;
    lane.done_cursor = static_cast<std::uint8_t>((lane.done_cursor + 1U) % lane.done.size());
    if (lane.done_count < lane.done.size()) ++lane.done_count;
}
void trim_partial(LaneIn& lane) {
    if (lane.unreliable.size() <= kMaxPartial) return;
    lane.unreliable.erase(lane.unreliable.begin());
}
void push_unreliable(State& state, std::uint8_t lane_index, const Piece& piece) {
    CarrierMessage message;
    message.lane = lane_index;
    message.delivery = Delivery::kUnreliable;
    if (!build_message(piece, message.bytes)) return;
    state.ready.push_back(std::move(message));
}
void apply_unreliable(State& state, std::uint8_t lane_index, const Frame& frame) {
    LaneIn& lane = state.incoming[lane_index];
    if (already_done(lane, frame.message)) return;
    trim_partial(lane);
    if (!store_piece(lane.unreliable, frame)) return;
    Piece* found = find_piece(lane.unreliable, frame.message);
    if (found == nullptr || !piece_complete(*found)) return;
    push_unreliable(state, lane_index, *found);
    remember_done(lane, frame.message);
    erase_piece(lane.unreliable, frame.message);
}
void apply_reliable(State& state, std::uint8_t lane_index, const Frame& frame) {
    LaneIn& lane = state.incoming[lane_index];
    if (seq_before(frame.message, lane.next_reliable)) return;
    if (!store_piece(lane.reliable, frame)) return;
    flush_reliable(state, lane);
}
void apply_frame(State& state, const Frame& frame) {
    if (frame.kind == kKindUnreliable) apply_unreliable(state, frame.lane, frame);
    if (frame.kind == kKindReliable) apply_reliable(state, frame.lane, frame);
}
void apply_frames(State& state, const std::vector<Frame>& frames) {
    for (const Frame& frame : frames)
        apply_frame(state, frame);
}
bool read_one(State& state, std::span<const std::byte> packet, std::uint64_t now) {
    Parsed parsed;
    if (!parse_packet(packet, parsed)) return false;
    if (parsed.has_ack) apply_ack(state, parsed.ack_newest, parsed.ack_bits, now);
    const Place place = classify(state, parsed.number, parsed.stop_before);
    state.ack_due = true;
    if (place != Place::kFresh) return true;
    if (!all_fit(state, parsed.frames)) return true;
    remember_fresh(state, parsed.number);
    apply_frames(state, parsed.frames);
    return true;
}

} // namespace game::net::detail
