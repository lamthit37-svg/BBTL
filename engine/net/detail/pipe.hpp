/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/net/detail/pipe.hpp
 *  PHÂN HỆ   : Net / Carrier
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Kiểu nội bộ của carrier: khung byte, mảnh gửi, cửa sổ ack, hộp nhận.
 *    Codec, đường gửi và đường nhận mỗi phần một tệp, không gom một god file.
 *  - Không phải API công khai. Module khác không include tệp này.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "net/carrier.hpp"
#include "net/shard.hpp"

#include <array>
#include <cstdint>
#include <deque>
#include <optional>
#include <span>
#include <vector>

namespace game::net::detail {


constexpr std::uint8_t kVersion = 1;
constexpr std::uint8_t kFlagAck = 1;
constexpr std::uint8_t kFlagStop = 2;
constexpr std::uint8_t kKnownFlags = kFlagAck | kFlagStop;
constexpr std::uint8_t kKindReliable = 1;
constexpr std::uint8_t kKindUnreliable = 2;
constexpr std::size_t kChunk = 1024;
constexpr std::size_t kFrameHeader = 10;
constexpr std::size_t kAckSpan = 512;
constexpr std::size_t kAckBytes = kAckSpan / 8;
constexpr std::uint16_t kWindow = 512;
constexpr std::uint16_t kRecvWindow = 256;
constexpr std::uint32_t kReliableBudget = 1024 * 1024;
constexpr std::uint32_t kMaxReliableFrags = 256;
constexpr std::uint32_t kUnreliableBudget = 256 * 1024;
constexpr int kFastGap = 3;
constexpr int kExpireRounds = 8;
constexpr std::uint32_t kInitialRto = 200;
constexpr std::size_t kMaxFrames = 128;
constexpr std::size_t kMaxPartial = 32;

static_assert(kCarrierLanes == kLaneCount);
static_assert(kChunk + kFrameHeader + 76 <= kCarrierPacketBytes);

struct Cursor {
    std::span<std::byte> buf;
    std::size_t at = 0;
    bool bad = false;
};

struct View {
    std::span<const std::byte> buf;
    std::size_t at = 0;
    bool bad = false;
};

struct Frame {
    std::uint8_t kind = 0;
    std::uint8_t lane = 0;
    std::uint16_t message = 0;
    std::uint16_t index = 0;
    std::uint16_t count = 0;
    std::span<const std::byte> payload;
};

struct Frag {
    std::uint32_t generation = 1;
    std::uint8_t lane = 0;
    std::uint8_t kind = 0;
    std::uint16_t message = 0;
    std::uint16_t index = 0;
    std::uint16_t count = 0;
    std::vector<std::byte> payload;
    bool live = false;
    bool acked = false;
    bool in_queue = false;
    bool sent = false;
    std::uint64_t sent_ms = 0;
};

struct Ref {
    std::uint32_t index = 0;
    std::uint32_t generation = 0;
};

struct Slot {
    bool live = false;
    bool acked = false;
    bool fast = false;
    std::uint16_t number = 0;
    std::uint64_t sent_ms = 0;
    std::vector<Ref> refs;
};

struct Piece {
    std::uint16_t message = 0;
    std::uint16_t count = 0;
    std::uint16_t got = 0;
    std::vector<std::vector<std::byte>> parts;
    std::vector<std::uint8_t> have;
};

struct LaneIn {
    std::uint16_t next_reliable = 1;
    std::vector<Piece> reliable;
    std::vector<Piece> unreliable;
    std::array<std::uint16_t, 64> done{};
    std::uint8_t done_count = 0;
    std::uint8_t done_cursor = 0;
};

struct Parsed {
    std::uint8_t flags = 0;
    std::uint16_t number = 0;
    std::uint16_t stop_before = 0;
    bool has_ack = false;
    std::uint16_t ack_newest = 0;
    std::array<std::byte, kAckBytes> ack_bits{};
    std::vector<Frame> frames;
};

enum class Place : std::uint8_t { kFresh, kDup, kStale, kFar };

struct State {
    CarrierConfig config{};
    LaneQueue<std::uint32_t> lanes;
    std::vector<Frag> frags;
    std::vector<std::uint32_t> free_ids;
    std::vector<Slot> slots;
    std::optional<std::uint32_t> held;
    std::uint16_t next_number = 1;
    std::uint32_t in_flight = 0;
    std::uint32_t reliable_bytes = 0;
    std::uint32_t reliable_frags = 0;
    std::uint32_t unreliable_bytes = 0;
    std::array<std::uint16_t, kCarrierLanes> next_reliable{};
    std::array<std::uint16_t, kCarrierLanes> next_unreliable{};
    std::array<std::uint64_t, kAckBytes / 8> recv_bits{};
    bool have_recv = false;
    std::uint16_t highest = 0;
    bool ack_due = false;
    bool have_rtt = false;
    std::uint32_t srtt = 0;
    std::uint32_t rttvar = 0;
    std::array<LaneIn, kCarrierLanes> incoming{};
    std::deque<CarrierMessage> ready;
};

void write_u8(Cursor& cursor, std::uint8_t value);
void write_u16(Cursor& cursor, std::uint16_t value);
void copy_bytes(std::span<std::byte> dest, std::span<const std::byte> src);
void write_bytes(Cursor& cursor, std::span<const std::byte> data);
std::uint8_t read_u8(View& view);
std::uint16_t read_u16(View& view);
std::span<const std::byte> read_bytes(View& view, std::size_t size);
std::uint8_t foreign_flags(std::uint8_t flags) noexcept;
bool seq_before(std::uint16_t left, std::uint16_t right) noexcept;
CarrierConfig normalize(CarrierConfig config) noexcept;
void prime_lane(State& state, std::uint8_t lane);
void prime_ids(State& state);
std::uint32_t rto_ms(const State& state) noexcept;
void smooth_rtt(State& state, std::uint32_t sample);
std::uint32_t sample_of(std::uint64_t gap) noexcept;
void note_rtt(State& state, std::uint64_t sent_ms, std::uint64_t now);
bool storage_test(const State& state, std::uint16_t number) noexcept;
void storage_set(State& state, std::uint16_t number, bool on) noexcept;
void clear_forward(State& state, std::uint16_t from, std::uint16_t to);
Place classify(const State& state, std::uint16_t number, std::uint16_t stop_before);
void remember_fresh(State& state, std::uint16_t number);
bool ack_bit(const std::array<std::byte, kAckBytes>& raw, std::size_t index) noexcept;
void set_ack_bit(std::array<std::byte, kAckBytes>& raw, std::size_t index) noexcept;
int add_if_set(const std::array<std::byte, kAckBytes>& raw, std::uint16_t newest,
    std::uint16_t cursor);
int newer_received(std::uint16_t newest, const std::array<std::byte, kAckBytes>& raw,
    std::uint16_t seq);
Frag* frag_of(State& state, Ref ref);
void subtract_unreliable(State& state, std::uint32_t size);
void release_account(State& state, Frag& frag);
void free_frag(State& state, std::uint32_t index);
void mark_acked(State& state, Frag& frag, std::uint32_t index);
void mark_ref(State& state, Ref ref);
void mark_listed(State& state, const Slot& slot);
void release_slot(State& state, Slot& slot);
void ack_number(State& state, std::uint16_t number, std::uint64_t now);
void enqueue(State& state, std::uint32_t index);
void requeue_ref(State& state, Ref ref);
void requeue_listed(State& state, const Slot& slot);
void arm_fast(State& state, std::uint16_t number);
void consider_gap(State& state, std::uint16_t newest, const std::array<std::byte, kAckBytes>& raw,
    std::size_t index, std::uint64_t now);
void apply_ack(State& state, std::uint16_t newest, const std::array<std::byte, kAckBytes>& raw,
    std::uint64_t now);
std::uint16_t bit_seq(std::uint16_t newest, std::size_t index) noexcept;
void fill_ack_bit(State& state, std::array<std::byte, kAckBytes>& raw, std::size_t index);
void write_ack_bits(Cursor& cursor, State& state);
std::uint16_t oldest_or(const State& state, std::uint16_t fallback) noexcept;
std::size_t header_size(bool has_ack) noexcept;
void write_ack_block(Cursor& cursor, State& state);
void write_header(Cursor& cursor, State& state, std::uint16_t number);
void stamp_frames(Cursor& cursor, bool has_ack) noexcept;
bool pop_lane(State& state, std::uint32_t& index);
bool keep_frag(State& state, std::uint32_t index);
bool take_ready(State& state, std::uint32_t& index);
void write_frame(Cursor& cursor, const Frag& frag);
void note_sent(State& state, std::uint32_t index, std::uint64_t now);
bool too_big(const Cursor& cursor, const Frag& frag) noexcept;
bool write_and_note(State& state, Cursor& cursor, Slot& slot, std::uint32_t index,
    std::uint64_t now);
bool place_or_hold(State& state, Cursor& cursor, Slot& slot, std::uint32_t index,
    std::uint64_t now);
void fill_frames(State& state, Cursor& cursor, Slot& slot, std::uint64_t now);
void requeue_one(State& state, std::uint32_t index, std::uint64_t now);
void requeue_due(State& state, std::uint64_t now);
std::uint64_t expire_at(const State& state, const Slot& slot) noexcept;
void expire_slot(State& state, Slot& slot, std::uint64_t now);
void expire_due(State& state, std::uint64_t now);
bool need_send(const State& state) noexcept;
void occupy(State& state, std::uint16_t number, std::uint64_t now);
bool claim_number(State& state, std::uint16_t& number, std::uint64_t now);
bool claim_with_room(State& state, std::uint16_t& number, std::uint64_t now);
void publish(std::span<std::byte> out, std::size_t& written, const Cursor& cursor);
bool write_one(State& state, std::span<std::byte> out, std::size_t& written, std::uint64_t now);
bool push_frame(View& view, std::vector<Frame>& frames);
bool parse_frames(View& view, std::vector<Frame>& frames);
bool parse_packet(std::span<const std::byte> packet, Parsed& parsed);
bool frame_fits(const State& state, const Frame& frame);
bool all_fit(const State& state, const std::vector<Frame>& frames);
Piece* find_piece(std::vector<Piece>& pieces, std::uint16_t message);
void erase_piece(std::vector<Piece>& pieces, std::uint16_t message);
Piece& add_piece(std::vector<Piece>& pieces, std::uint16_t message, std::uint16_t count);
bool store_piece(std::vector<Piece>& pieces, const Frame& frame);
void append_part(std::vector<std::byte>& out, const std::vector<std::byte>& part);
std::size_t part_total(const Piece& piece);
bool build_message(const Piece& piece, std::vector<std::byte>& out);
bool piece_complete(const Piece& piece) noexcept;
std::uint8_t lane_of(const State& state, const LaneIn& lane) noexcept;
bool deliver_ready(State& state, LaneIn& lane);
void flush_reliable(State& state, LaneIn& lane);
bool already_done(const LaneIn& lane, std::uint16_t message);
void remember_done(LaneIn& lane, std::uint16_t message);
void trim_partial(LaneIn& lane);
void push_unreliable(State& state, std::uint8_t lane_index, const Piece& piece);
void apply_unreliable(State& state, std::uint8_t lane_index, const Frame& frame);
void apply_reliable(State& state, std::uint8_t lane_index, const Frame& frame);
void apply_frame(State& state, const Frame& frame);
void apply_frames(State& state, const std::vector<Frame>& frames);
bool read_one(State& state, std::span<const std::byte> packet, std::uint64_t now);
std::uint16_t take_id(std::uint16_t& next);
std::uint16_t fragment_count(std::size_t size) noexcept;
bool over_reliable(const State& state, std::size_t size, std::uint16_t count) noexcept;
bool budget_ok(const State& state, Delivery delivery, std::size_t size,
    std::uint16_t count) noexcept;
std::uint32_t alloc_index(State& state);
void revive(Frag& frag);
void note_new(State& state, const Frag& frag);
std::uint32_t make_frag(State& state, std::uint8_t lane, std::uint8_t kind, std::uint16_t message,
    std::uint16_t index, std::uint16_t count, std::span<const std::byte> part);
std::size_t queue_at(State& state, std::uint8_t lane, std::uint8_t kind, std::uint16_t message,
    std::span<const std::byte> payload, std::uint16_t count, std::uint16_t index,
    std::size_t offset);
void queue_all(State& state, std::uint8_t lane, std::uint8_t kind, std::uint16_t message,
    std::span<const std::byte> payload, std::uint16_t count);
std::uint8_t kind_of(Delivery delivery) noexcept;
std::uint16_t& id_slot(State& state, std::uint8_t lane, Delivery delivery);
bool send_rejected(std::uint8_t lane, std::span<const std::byte> payload) noexcept;
bool send_message(State& state, std::uint8_t lane, Delivery delivery,
    std::span<const std::byte> payload);
State make_state(CarrierConfig config);

} // namespace game::net::detail
