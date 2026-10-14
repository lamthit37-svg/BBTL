#include "mission/codec.hpp"

#include "ledger/ledger.hpp"
#include "mission/book.hpp"
#include "protocol/wire.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <utility>
#include <vector>

namespace game::mission {
namespace {

using Unexpected = std::unexpected<CodecError>;
using protocol::ByteView;
using protocol::Reader;
using protocol::Writer;

constexpr std::uint8_t kLastReason = static_cast<std::uint8_t>(ledger::Reason::kStale);

void write_slot(Writer& w, std::size_t index, const Slot& slot) {
    w.u8(static_cast<std::uint8_t>(index));
    w.i32(slot.mission);
    w.i32(slot.script);
    w.u8(slot.flags);
    for (const std::uint32_t param : slot.params) w.u32(param);
}

[[nodiscard]] bool read_journal(Reader& r, Book& draft) {
    const std::uint64_t seq = r.u64();
    const std::uint64_t floor = r.u64();
    const std::size_t count = r.count(ledger::kJournalSize);
    std::vector<ledger::Journal::Record> records;
    records.reserve(count);
    for (std::size_t index = 0; index < count; ++index) {
        const std::uint64_t request = r.u64();
        const std::uint8_t reason = r.u8();
        if (!r.is_ok() || reason > kLastReason) return false;
        records.push_back({.request = request, .reason = static_cast<ledger::Reason>(reason)});
    }
    if (!r.is_ok()) return false;
    draft.ledger_seq = seq;
    return draft.journal.restore(floor, records);
}

[[nodiscard]] bool read_slots(Reader& r, Book& draft) {
    const std::size_t count = r.count(kSlotCount);
    std::array<bool, kSlotCount> seen{};
    for (std::size_t item = 0; item < count; ++item) {
        const std::uint8_t index = r.u8();
        Slot slot;
        slot.mission = r.i32();
        slot.script = r.i32();
        slot.flags = r.u8();
        for (std::uint32_t& param : slot.params) param = r.u32();
        if (!r.is_ok() || index >= kSlotCount || seen.at(index) || !slot.used()) return false;
        seen.at(index) = true;
        draft.slots.at(index) = slot;
    }
    return true;
}

[[nodiscard]] bool read_done(Reader& r, Book& draft) {
    const std::size_t count = r.count(kDoneWords);
    std::optional<std::uint8_t> previous;
    for (std::size_t item = 0; item < count; ++item) {
        const std::uint8_t word = r.u8();
        const std::uint32_t bits = r.u32();
        if (!r.is_ok() || word >= kDoneWords || bits == 0 || (previous && *previous >= word)) return false;
        previous = word;
        draft.done.at(word) = bits;
    }
    return true;
}

[[nodiscard]] bool read_counters(Reader& r, Book& draft) {
    const std::size_t count = r.count(kMaxCounters);
    draft.counters.reserve(count);
    for (std::size_t item = 0; item < count; ++item) {
        Counter counter;
        counter.index = r.i32();
        counter.value = r.i64();
        if (!r.is_ok()) return false;
        draft.counters.push_back(counter);
    }
    return true;
}

[[nodiscard]] bool read_flags(Reader& r, Book& draft) {
    const std::size_t count = r.count(kMaxFlags);
    draft.flags.reserve(count);
    for (std::size_t item = 0; item < count; ++item) {
        draft.flags.push_back(r.i32());
        if (!r.is_ok()) return false;
    }
    return true;
}

std::optional<ByteView> open_frame(ByteView blob) {
    const protocol::FrameResult frame = protocol::peek_frame(blob, protocol::kMaxBodyBytes);
    if (!frame || !*frame || (*frame)->kind != kBlobBook) return std::nullopt;
    const std::size_t total = protocol::kHeaderBytes + (*frame)->body_bytes;
    if (total != blob.size()) return std::nullopt;
    return blob.subspan(protocol::kHeaderBytes, (*frame)->body_bytes);
}

}  // namespace

std::expected<Blob, CodecError> encode(const Book& book) {
    if (!well_formed(book)) return Unexpected(CodecError::kEncodeFailed);
    Blob out;
    Writer w(out);
    w.u16(kCodecVersion);
    w.u64(book.ledger_seq);
    w.u64(book.journal.floor());
    w.count(book.journal.records().size(), ledger::kJournalSize);
    for (const ledger::Journal::Record& record : book.journal.records()) {
        w.u64(record.request);
        w.u8(static_cast<std::uint8_t>(record.reason));
    }
    w.count(kSlotCount - static_cast<std::size_t>(book.free_slots()), kSlotCount);
    for (std::size_t index = 0; index < kSlotCount; ++index) {
        if (book.slots.at(index).used()) write_slot(w, index, book.slots.at(index));
    }
    std::size_t words = 0;
    for (const std::uint32_t bits : book.done) words += bits != 0 ? 1 : 0;
    w.count(words, kDoneWords);
    for (std::size_t word = 0; word < kDoneWords; ++word) {
        if (book.done.at(word) == 0) continue;
        w.u8(static_cast<std::uint8_t>(word));
        w.u32(book.done.at(word));
    }
    w.count(book.counters.size(), kMaxCounters);
    for (const Counter& counter : book.counters) {
        w.i32(counter.index);
        w.i64(counter.value);
    }
    w.count(book.flags.size(), kMaxFlags);
    for (const std::int32_t flag : book.flags) w.i32(flag);
    if (!w.finish(kBlobBook)) return Unexpected(CodecError::kEncodeFailed);
    return out;
}

std::expected<void, CodecError> decode(ByteView blob, Book& into) {
    const std::optional<ByteView> body = open_frame(blob);
    if (!body) return Unexpected(CodecError::kBadBlob);
    Reader r(*body);
    const std::uint16_t version = r.u16();
    if (!r.is_ok() || version != kCodecVersion) return Unexpected(CodecError::kBadBlob);
    Book draft;
    if (!read_journal(r, draft) || !read_slots(r, draft) || !read_done(r, draft) || !read_counters(r, draft) ||
        !read_flags(r, draft) || !r.finish() || !well_formed(draft)) {
        return Unexpected(CodecError::kBadBlob);
    }
    into = std::move(draft);
    return {};
}

}  // namespace game::mission
