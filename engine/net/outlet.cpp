/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/net/outlet.cpp
 *  PHÂN HỆ   : Net / Carrier / Outlet
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hàng gửi: cắt mảnh, lane, số gói, ack và gửi lại. Một luồng.
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

bool seq_before(std::uint16_t left, std::uint16_t right) noexcept {
    const auto gap = static_cast<std::uint16_t>(right - left);
    return gap != 0 && gap < 32768;
}
CarrierConfig normalize(CarrierConfig config) noexcept {
    if (config.min_rto_ms == 0) config.min_rto_ms = 1;
    if (config.max_rto_ms < config.min_rto_ms) config.max_rto_ms = config.min_rto_ms;
    return config;
}
void prime_lane(State& state, std::uint8_t lane) {
    state.next_reliable[lane] = 1;
    state.next_unreliable[lane] = 1;
}
void prime_ids(State& state) {
    for (std::uint8_t lane = 0; lane < kCarrierLanes; ++lane)
        prime_lane(state, lane);
}
std::uint32_t rto_ms(const State& state) noexcept {
    std::uint32_t base = kInitialRto;
    if (state.have_rtt) base = state.srtt + (4U * state.rttvar);
    if (base < state.config.min_rto_ms) base = state.config.min_rto_ms;
    if (base > state.config.max_rto_ms) base = state.config.max_rto_ms;
    return base;
}
void smooth_rtt(State& state, std::uint32_t sample) {
    if (!state.have_rtt) {
        state.have_rtt = true;
        state.srtt = sample;
        state.rttvar = sample / 2U;
        return;
    }
    const auto delta = static_cast<std::int32_t>(sample) - static_cast<std::int32_t>(state.srtt);
    state.srtt = static_cast<std::uint32_t>(static_cast<std::int32_t>(state.srtt) + (delta / 8));
    const std::int32_t spread = std::abs(delta) - static_cast<std::int32_t>(state.rttvar);
    const auto next = static_cast<std::int32_t>(state.rttvar) + (spread / 4);
    if (next > 0) state.rttvar = static_cast<std::uint32_t>(next);
}
std::uint32_t sample_of(std::uint64_t gap) noexcept {
    if (gap == 0) return 1;
    if (gap > 10000) return 10000;
    return static_cast<std::uint32_t>(gap);
}
void note_rtt(State& state, std::uint64_t sent_ms, std::uint64_t now) {
    if (now < sent_ms) return;
    smooth_rtt(state, sample_of(now - sent_ms));
}
Frag* frag_of(State& state, Ref ref) {
    if (ref.index >= state.frags.size()) return nullptr;
    Frag& frag = state.frags[ref.index];
    if (!frag.live || frag.generation != ref.generation) return nullptr;
    return &frag;
}
void subtract_unreliable(State& state, std::uint32_t size) {
    if (state.unreliable_bytes < size) return;
    state.unreliable_bytes -= size;
}
void release_account(State& state, Frag& frag) {
    const auto size = static_cast<std::uint32_t>(frag.payload.size());
    if (frag.kind == kKindReliable && state.reliable_bytes >= size) state.reliable_bytes -= size;
    if (frag.kind == kKindReliable && state.reliable_frags > 0) --state.reliable_frags;
    if (frag.kind == kKindUnreliable) subtract_unreliable(state, size);
}
void free_frag(State& state, std::uint32_t index) {
    Frag& frag = state.frags[index];
    if (!frag.live || frag.in_queue) return;
    if (state.held && *state.held == index) return;
    frag.live = false;
    frag.payload.clear();
    ++frag.generation;
    state.free_ids.push_back(index);
}
void mark_acked(State& state, Frag& frag, std::uint32_t index) {
    if (!frag.live || frag.acked) return;
    frag.acked = true;
    release_account(state, frag);
    frag.payload.clear();
    free_frag(state, index);
}
void mark_ref(State& state, Ref ref) {
    Frag* frag = frag_of(state, ref);
    if (frag == nullptr) return;
    mark_acked(state, *frag, ref.index);
}
void mark_listed(State& state, const Slot& slot) {
    for (const Ref& ref : slot.refs)
        mark_ref(state, ref);
}
void release_slot(State& state, Slot& slot) {
    if (!slot.live) return;
    slot.live = false;
    slot.acked = true;
    slot.refs.clear();
    if (state.in_flight > 0) --state.in_flight;
}
void ack_number(State& state, std::uint16_t number, std::uint64_t now) {
    Slot& slot = state.slots[number % kWindow];
    if (!slot.live || slot.number != number || slot.acked) return;
    note_rtt(state, slot.sent_ms, now);
    mark_listed(state, slot);
    release_slot(state, slot);
}
void enqueue(State& state, std::uint32_t index) {
    Frag& frag = state.frags[index];
    if (!frag.live || frag.acked || frag.in_queue) return;
    frag.in_queue = true;
    state.lanes.push(frag.lane, index);
}
void requeue_ref(State& state, Ref ref) {
    Frag* frag = frag_of(state, ref);
    if (frag == nullptr || frag->kind != kKindReliable) return;
    enqueue(state, ref.index);
}
void requeue_listed(State& state, const Slot& slot) {
    for (const Ref& ref : slot.refs)
        requeue_ref(state, ref);
}
void arm_fast(State& state, std::uint16_t number) {
    Slot& slot = state.slots[number % kWindow];
    if (!slot.live || slot.number != number || slot.acked || slot.fast) return;
    slot.fast = true;
    requeue_listed(state, slot);
}
void consider_gap(State& state, std::uint16_t newest, const std::array<std::byte, kAckBytes>& raw,
    std::size_t index, std::uint64_t now) {
    const std::uint16_t seq = bit_seq(newest, index);
    if (ack_bit(raw, index)) {
        ack_number(state, seq, now);
        return;
    }
    if (newer_received(newest, raw, seq) < kFastGap) return;
    arm_fast(state, seq);
}
void apply_ack(State& state, std::uint16_t newest, const std::array<std::byte, kAckBytes>& raw,
    std::uint64_t now) {
    ack_number(state, newest, now);
    for (std::size_t index = 0; index < kAckSpan; ++index)
        consider_gap(state, newest, raw, index, now);
}
std::uint16_t oldest_or(const State& state, std::uint16_t fallback) noexcept {
    std::uint16_t oldest = fallback;
    bool found = false;
    for (const Slot& slot : state.slots) {
        if (!slot.live || slot.acked) continue;
        if (!found || seq_before(slot.number, oldest)) oldest = slot.number;
        found = true;
    }
    if (!found) return fallback;
    return oldest;
}
bool pop_lane(State& state, std::uint32_t& index) {
    if (state.held) {
        index = *state.held;
        state.held.reset();
        return true;
    }
    std::array<std::uint32_t, 1> out{};
    if (state.lanes.pop(out) != 1) return false;
    index = out[0];
    return true;
}
bool keep_frag(State& state, std::uint32_t index) {
    if (index >= state.frags.size()) return false;
    Frag& frag = state.frags[index];
    frag.in_queue = false;
    if (!frag.live) return false;
    if (!frag.acked) return true;
    free_frag(state, index);
    return false;
}
bool take_ready(State& state, std::uint32_t& index) {
    while (pop_lane(state, index)) {
        if (keep_frag(state, index)) return true;
    }
    return false;
}
void note_sent(State& state, std::uint32_t index, std::uint64_t now) {
    Frag& frag = state.frags[index];
    frag.sent = true;
    frag.sent_ms = now;
    if (frag.kind != kKindUnreliable) return;
    release_account(state, frag);
    free_frag(state, index);
}
bool too_big(const Cursor& cursor, const Frag& frag) noexcept {
    return cursor.at + kFrameHeader + frag.payload.size() > kCarrierPacketBytes;
}
bool write_and_note(State& state, Cursor& cursor, Slot& slot, std::uint32_t index,
    std::uint64_t now) {
    Frag& frag = state.frags[index];
    write_frame(cursor, frag);
    slot.refs.push_back(Ref{.index = index, .generation = frag.generation});
    note_sent(state, index, now);
    return !cursor.bad;
}
bool place_or_hold(State& state, Cursor& cursor, Slot& slot, std::uint32_t index,
    std::uint64_t now) {
    Frag& frag = state.frags[index];
    if (!too_big(cursor, frag)) return write_and_note(state, cursor, slot, index, now);
    core::check(!slot.refs.empty(), "mảnh lớn hơn một gói");
    state.held = index;
    return false;
}
void fill_frames(State& state, Cursor& cursor, Slot& slot, std::uint64_t now) {
    std::uint32_t index = 0;
    while (take_ready(state, index)) {
        if (!place_or_hold(state, cursor, slot, index, now)) return;
    }
}
void requeue_one(State& state, std::uint32_t index, std::uint64_t now) {
    if (index >= state.frags.size()) return;
    Frag& frag = state.frags[index];
    if (!frag.live || frag.acked || frag.in_queue || !frag.sent) return;
    if (state.held && *state.held == index) return;
    if (frag.kind != kKindReliable) return;
    const std::uint64_t due = frag.sent_ms + rto_ms(state);
    if (now < due) return;
    enqueue(state, index);
}
void requeue_due(State& state, std::uint64_t now) {
    const auto count = static_cast<std::uint32_t>(state.frags.size());
    for (std::uint32_t index = 0; index < count; ++index)
        requeue_one(state, index, now);
}
std::uint64_t expire_at(const State& state, const Slot& slot) noexcept {
    const auto rounds = static_cast<std::uint64_t>(kExpireRounds);
    return slot.sent_ms + (static_cast<std::uint64_t>(rto_ms(state)) * rounds);
}
void expire_slot(State& state, Slot& slot, std::uint64_t now) {
    if (!slot.live || slot.acked) return;
    if (now < expire_at(state, slot)) return;
    requeue_listed(state, slot);
    release_slot(state, slot);
}
void expire_due(State& state, std::uint64_t now) {
    for (Slot& slot : state.slots)
        expire_slot(state, slot, now);
}
bool need_send(const State& state) noexcept {
    if (state.ack_due && state.have_recv) return true;
    if (state.held.has_value()) return true;
    return state.lanes.size() > 0;
}
void occupy(State& state, std::uint16_t number, std::uint64_t now) {
    Slot& slot = state.slots[number % kWindow];
    slot = Slot{};
    slot.live = true;
    slot.number = number;
    slot.sent_ms = now;
    slot.refs.reserve(8);
    ++state.in_flight;
}
bool claim_number(State& state, std::uint16_t& number, std::uint64_t now) {
    if (state.in_flight >= kWindow) return false;
    std::uint16_t candidate = state.next_number;
    if (candidate == 0) candidate = 1;
    Slot& slot = state.slots[candidate % kWindow];
    if (slot.live) return false;
    std::uint16_t next = static_cast<std::uint16_t>(candidate + 1U);
    if (next == 0) next = 1;
    state.next_number = next;
    occupy(state, candidate, now);
    number = candidate;
    return true;
}
bool claim_with_room(State& state, std::uint16_t& number, std::uint64_t now) {
    if (claim_number(state, number, now)) return true;
    expire_due(state, now);
    return claim_number(state, number, now);
}
void publish(std::span<std::byte> out, std::size_t& written, const Cursor& cursor) {
    const std::span<std::byte> dest = out.first(cursor.at);
    const std::span<const std::byte> src = cursor.buf.first(cursor.at);
    copy_bytes(dest, src);
    written = cursor.at;
}
bool write_one(State& state, std::span<std::byte> out, std::size_t& written, std::uint64_t now) {
    written = 0;
    if (out.size() < kCarrierPacketBytes) return false;
    expire_due(state, now);
    requeue_due(state, now);
    if (!need_send(state)) return false;
    std::uint16_t number = 0;
    if (!claim_with_room(state, number, now)) return false;
    std::array<std::byte, kCarrierPacketBytes> storage{};
    Cursor cursor{.buf = storage, .at = 0, .bad = false};
    write_header(cursor, state, number);
    Slot& slot = state.slots[number % kWindow];
    fill_frames(state, cursor, slot, now);
    if (!cursor.bad) stamp_frames(cursor, state.have_recv);
    if (cursor.bad || cursor.at < header_size(state.have_recv)) {
        release_slot(state, slot);
        return false;
    }
    publish(out, written, cursor);
    if (state.have_recv) state.ack_due = false;
    return true;
}
std::uint16_t take_id(std::uint16_t& next) {
    std::uint16_t id = next;
    if (id == 0) id = 1;
    next = static_cast<std::uint16_t>(id + 1U);
    return id;
}
std::uint16_t fragment_count(std::size_t size) noexcept {
    const std::size_t count = (size + kChunk - 1U) / kChunk;
    return static_cast<std::uint16_t>(count);
}
bool over_reliable(const State& state, std::size_t size, std::uint16_t count) noexcept {
    if (state.reliable_frags + count > kMaxReliableFrags) return false;
    if (state.reliable_bytes + size > kReliableBudget) return false;
    return true;
}
bool budget_ok(const State& state, Delivery delivery, std::size_t size,
    std::uint16_t count) noexcept {
    if (delivery == Delivery::kReliable) return over_reliable(state, size, count);
    return state.unreliable_bytes + size <= kUnreliableBudget;
}
std::uint32_t alloc_index(State& state) {
    if (!state.free_ids.empty()) {
        const std::uint32_t index = state.free_ids.back();
        state.free_ids.pop_back();
        return index;
    }
    state.frags.push_back(Frag{});
    return static_cast<std::uint32_t>(state.frags.size() - 1U);
}
void revive(Frag& frag) {
    frag.live = true;
    frag.acked = false;
    frag.in_queue = false;
    frag.sent = false;
    frag.sent_ms = 0;
    frag.payload.clear();
}
void note_new(State& state, const Frag& frag) {
    const auto size = static_cast<std::uint32_t>(frag.payload.size());
    if (frag.kind == kKindReliable) {
        ++state.reliable_frags;
        state.reliable_bytes += size;
        return;
    }
    state.unreliable_bytes += size;
}
std::uint32_t make_frag(State& state, std::uint8_t lane, std::uint8_t kind, std::uint16_t message,
    std::uint16_t index, std::uint16_t count, std::span<const std::byte> part) {
    const std::uint32_t id = alloc_index(state);
    Frag& frag = state.frags[id];
    revive(frag);
    frag.lane = lane;
    frag.kind = kind;
    frag.message = message;
    frag.index = index;
    frag.count = count;
    frag.payload.assign(part.begin(), part.end());
    note_new(state, frag);
    return id;
}
std::size_t queue_at(State& state, std::uint8_t lane, std::uint8_t kind, std::uint16_t message,
    std::span<const std::byte> payload, std::uint16_t count, std::uint16_t index,
    std::size_t offset) {
    const std::size_t take = std::min(kChunk, payload.size() - offset);
    const std::span<const std::byte> part = payload.subspan(offset, take);
    const std::uint32_t id = make_frag(state, lane, kind, message, index, count, part);
    enqueue(state, id);
    return offset + take;
}
void queue_all(State& state, std::uint8_t lane, std::uint8_t kind, std::uint16_t message,
    std::span<const std::byte> payload, std::uint16_t count) {
    std::size_t offset = 0;
    for (std::uint16_t index = 0; index < count; ++index) {
        offset = queue_at(state, lane, kind, message, payload, count, index, offset);
    }
}
std::uint8_t kind_of(Delivery delivery) noexcept {
    if (delivery == Delivery::kReliable) return kKindReliable;
    return kKindUnreliable;
}
std::uint16_t& id_slot(State& state, std::uint8_t lane, Delivery delivery) {
    if (delivery == Delivery::kReliable) return state.next_reliable[lane];
    return state.next_unreliable[lane];
}
bool send_rejected(std::uint8_t lane, std::span<const std::byte> payload) noexcept {
    if (lane >= kCarrierLanes) return true;
    if (payload.empty()) return true;
    return payload.size() > kCarrierMessageMax;
}
bool send_message(State& state, std::uint8_t lane, Delivery delivery,
    std::span<const std::byte> payload) {
    if (send_rejected(lane, payload)) return false;
    const std::uint16_t count = fragment_count(payload.size());
    if (!budget_ok(state, delivery, payload.size(), count)) return false;
    std::uint16_t& next = id_slot(state, lane, delivery);
    const std::uint16_t message = take_id(next);
    queue_all(state, lane, kind_of(delivery), message, payload, count);
    return true;
}
State make_state(CarrierConfig config) {
    State state;
    state.config = normalize(config);
    std::array<LaneSpec, kCarrierLanes> specs{};
    specs[0] = LaneSpec{.priority = 0, .weight = 1};
    specs[1] = LaneSpec{.priority = 1, .weight = 1};
    specs[2] = LaneSpec{.priority = 2, .weight = 1};
    specs[3] = LaneSpec{.priority = 3, .weight = 1};
    state.lanes.reset(specs);
    state.slots.resize(kWindow);
    prime_ids(state);
    return state;
}

} // namespace game::net::detail
