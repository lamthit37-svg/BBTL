// Gói .tlpak: đầu 64 byte, mục niêm, chỉ mục niêm ở cuối. Mọi số little-endian, ghi từng byte.
#include "seal/detail/format.hpp"

#include "core/check.hpp"
#include "seal/detail/sodium.hpp"
#include "seal/package.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <set>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::seal::detail {
namespace {

constexpr std::uint16_t kVersion = 1;
constexpr std::uint64_t kEntryId = 1;
constexpr std::uint64_t kIndexId = 2;
constexpr std::uint64_t kNameId = 3;
constexpr std::uint64_t kCheckId = 4;
constexpr std::size_t kMaxName = 240;
constexpr std::array<char, 8> kMagic{'T', 'L', 'B', 'B', 'P', 'A', 'K', '1'};

struct Field {
    std::size_t at = 0;
    std::size_t width = 0;
};

struct Cut {
    std::string_view text;
    std::size_t next = 0;
};

struct Loaded {
    Head head;
    std::array<std::byte, kHeaderBytes> raw{};
};

void put_le(std::span<std::byte> out, Field field, std::uint64_t value) {
    core::check(field.width >= 1 && field.width <= 8, "bề rộng trường");
    core::check(field.at <= out.size(), "ghi vượt vùng");
    core::check(field.width <= out.size() - field.at, "ghi vượt vùng");
    const auto bits = static_cast<unsigned>(8 * field.width);
    const bool fits = bits == 64 || value < (std::uint64_t{1} << bits);
    core::check(fits, "giá trị không vừa trường");
    for (std::size_t step = 0; step < field.width; ++step) {
        const auto shift = static_cast<unsigned>(8 * step);
        const auto piece = static_cast<unsigned>((value >> shift) & 0xFFU);
        out[field.at + step] = static_cast<std::byte>(piece);
    }
}

std::uint64_t get_le(Bytes source, Field field) {
    core::check(field.width >= 1 && field.width <= 8, "bề rộng trường");
    core::check(field.at <= source.size(), "đọc vượt vùng");
    core::check(field.width <= source.size() - field.at, "đọc vượt vùng");
    std::uint64_t value = 0;
    for (std::size_t step = 0; step < field.width; ++step) {
        const auto shift = static_cast<unsigned>(8 * step);
        const auto piece = std::to_integer<std::uint64_t>(source[field.at + step]);
        value |= piece << shift;
    }
    return value;
}

void copy_bytes(std::span<std::byte> into, Bytes from) {
    core::check(into.size() == from.size(), "cỡ chép lệch");
    for (std::size_t index = 0; index < into.size(); ++index)
        into[index] = from[index];
}

bool is_zero(Bytes bytes) {
    bool clear = true;
    for (const std::byte value : bytes)
        clear = clear && value == std::byte{0};
    return clear;
}

bool magic_ok(Bytes bytes) {
    if (bytes.size() < kMagic.size()) return false;
    bool same = true;
    std::size_t index = 0;
    for (const char unit : kMagic) {
        same = same && bytes[index] == static_cast<std::byte>(unit);
        index += 1;
    }
    return same;
}

void write_magic(std::span<std::byte> out) {
    core::check(out.size() >= kMagic.size(), "đầu gói ngắn hơn phép thuật");
    std::size_t index = 0;
    for (const char unit : kMagic) {
        out[index] = static_cast<std::byte>(unit);
        index += 1;
    }
}

bool is_banned(unsigned char code) {
    if (code < 0x20 || code == 0x7F) return true;
    if (code == '\\' || code == ':' || code == '*' || code == '?') return true;
    if (code == '"' || code == '<' || code == '>' || code == '|') return true;
    return false;
}

bool is_segment(std::string_view segment) {
    if (segment.empty() || segment == "." || segment == "..") return false;
    bool clean = true;
    for (const char unit : segment) {
        const auto code = static_cast<unsigned char>(unit);
        clean = clean && !is_banned(code);
    }
    return clean;
}

Cut next_cut(std::string_view name, std::size_t offset) {
    const std::size_t slash = name.find('/', offset);
    const bool found = slash != std::string_view::npos;
    Cut cut;
    cut.text = found ? name.substr(offset, slash - offset) : name.substr(offset);
    cut.next = found ? slash + 1 : name.size() + 1;
    return cut;
}

bool segments_ok(std::string_view name) {
    bool alive = true;
    std::size_t cursor = 0;
    while (cursor <= name.size()) {
        const Cut cut = next_cut(name, cursor);
        alive = alive && is_segment(cut.text);
        cursor = cut.next;
    }
    return alive;
}

std::array<std::byte, 12> item_extra(const Entry& entry) {
    std::array<std::byte, 12> out{};
    put_le(out, Field{.at = 0, .width = 8}, entry.hash);
    put_le(out, Field{.at = 8, .width = 4}, entry.raw_size);
    return out;
}

bool version_ok(Bytes bytes) {
    const auto version = get_le(bytes, Field{.at = 8, .width = 2});
    const auto flags = get_le(bytes, Field{.at = 10, .width = 2});
    return version == kVersion && flags == 0;
}

bool reserved_clear(Bytes bytes) {
    return is_zero(bytes.subspan(48, kCheckBytes));
}

bool check_matches(const SubKeys& keys, const Head& head) {
    const std::array<std::byte, kCheckBytes> expect = package_check(keys);
    return equal16(expect, head.check);
}

bool entry_inside(const Entry& entry, std::uint64_t index_offset) {
    const bool overhead = entry.sealed_size >= kOverhead;
    const bool stored = entry.method == 0 && overhead;
    const bool width = stored && entry.sealed_size - kOverhead == entry.raw_size;
    const bool start = entry.offset >= kHeaderBytes && entry.offset <= index_offset;
    const bool end = start && entry.sealed_size <= index_offset - entry.offset;
    return width && end;
}

bool take_entry(std::vector<Entry>& out, Bytes plain, std::uint64_t end, std::size_t slot) {
    const std::size_t pos = slot * kRecord;
    Entry entry;
    entry.hash = get_le(plain, Field{.at = pos, .width = 8});
    entry.offset = get_le(plain, Field{.at = pos + 8, .width = 8});
    const auto sealed_bits = get_le(plain, Field{.at = pos + 16, .width = 4});
    entry.sealed_size = static_cast<std::uint32_t>(sealed_bits);
    const auto raw_bits = get_le(plain, Field{.at = pos + 20, .width = 4});
    entry.raw_size = static_cast<std::uint32_t>(raw_bits);
    const auto method_bits = get_le(plain, Field{.at = pos + 24, .width = 2});
    entry.method = static_cast<std::uint16_t>(method_bits);
    const auto reserved = get_le(plain, Field{.at = pos + 26, .width = 2});
    const bool ordered = out.empty() || out.back().hash < entry.hash;
    const bool sound = reserved == 0 && ordered && entry_inside(entry, end);
    if (!sound) return false;
    out.push_back(entry);
    return true;
}

BlobResult read_span(const View& view, std::uint64_t offset, std::uint64_t size) {
    if (view.read == nullptr) return std::unexpected(Error::kIo);
    if (size > std::numeric_limits<std::size_t>::max()) return std::unexpected(Error::kCorrupt);
    if (offset > view.size || size > view.size - offset) return std::unexpected(Error::kCorrupt);
    Blob buffer(static_cast<std::size_t>(size));
    const bool got = view.read(view.context, offset, buffer);
    if (!got) return std::unexpected(Error::kIo);
    return buffer;
}

std::expected<Loaded, Error> load_head(const View& view) {
    auto raw = read_span(view, 0, kHeaderBytes);
    if (!raw) return std::unexpected(raw.error());
    if (raw->size() != kHeaderBytes) return std::unexpected(Error::kCorrupt);
    if (!magic_ok(*raw)) return std::unexpected(Error::kBadMagic);
    if (!version_ok(*raw)) return std::unexpected(Error::kBadVersion);
    if (!reserved_clear(*raw)) return std::unexpected(Error::kCorrupt);
    Loaded loaded;
    loaded.head.count = static_cast<std::uint32_t>(get_le(*raw, Field{.at = 12, .width = 4}));
    loaded.head.index_offset = get_le(*raw, Field{.at = 16, .width = 8});
    loaded.head.index_size = get_le(*raw, Field{.at = 24, .width = 8});
    const Bytes header(*raw);
    const Bytes check = header.subspan(32, kCheckBytes);
    copy_bytes(loaded.head.check, check);
    copy_bytes(loaded.raw, *raw);
    return loaded;
}

bool index_fits(const Head& head, std::uint64_t file_size) {
    const std::uint64_t plain = std::uint64_t{head.count} * kRecord;
    const bool sized = head.index_size == plain + kOverhead;
    const bool placed = head.index_offset >= kHeaderBytes && head.index_offset <= file_size;
    const bool tail = placed && head.index_size == file_size - head.index_offset;
    return sized && tail;
}

const Entry* find_hash(std::span<const Entry> entries, std::uint64_t hash) {
    const auto found = std::ranges::lower_bound(entries, hash, {}, &Entry::hash);
    if (found == entries.end()) return nullptr;
    if (found->hash != hash) return nullptr;
    return &*found;
}

BlobResult open_with(const Key& key, Bytes sealed, Bytes extra) {
    if (sealed.size() < kOverhead) return std::unexpected(Error::kCorrupt);
    Blob plain(sealed.size() - kOverhead);
    const Box box{.destination = plain, .source = sealed, .extra = extra, .key = key.bytes};
    const bool opened = open_box(box);
    if (!opened) return std::unexpected(Error::kCorrupt);
    return plain;
}

BlobResult open_entry(const Key& key, Bytes sealed, const Entry& entry) {
    if (entry.method != 0) return std::unexpected(Error::kCorrupt);
    if (sealed.size() != entry.sealed_size) return std::unexpected(Error::kCorrupt);
    if (sealed.size() < kOverhead) return std::unexpected(Error::kCorrupt);
    if (sealed.size() - kOverhead != entry.raw_size) return std::unexpected(Error::kCorrupt);
    const std::array<std::byte, 12> extra = item_extra(entry);
    return open_with(key, sealed, extra);
}

std::string text_of(Bytes body) {
    std::string text(body.size(), '\0');
    for (std::size_t index = 0; index < body.size(); ++index)
        text[index] = static_cast<char>(std::to_integer<unsigned char>(body[index]));
    return text;
}

Cut next_line(std::string_view text, std::size_t offset) {
    const std::size_t newline = text.find('\n', offset);
    const bool found = newline != std::string_view::npos;
    Cut cut;
    cut.text = found ? text.substr(offset, newline - offset) : text.substr(offset);
    cut.next = found ? newline + 1 : text.size();
    return cut;
}

struct Lines {
    Gate* gate = nullptr;
    std::set<std::string>* seen = nullptr;
    std::vector<std::string>* names = nullptr;
};

bool push_line(const Lines& lines, std::string_view line) {
    if (!lines.gate->is_ok) return false;
    if (!legal_name(line)) mark(*lines.gate, Error::kCorrupt);
    if (!lines.gate->is_ok) return false;
    const std::string folded = fold_ascii(line);
    const bool fresh = lines.seen->insert(folded).second;
    if (!fresh) mark(*lines.gate, Error::kCorrupt);
    if (!fresh) return false;
    lines.names->emplace_back(line);
    return true;
}

NamesResult split_lines(Bytes body) {
    const std::string text = text_of(body);
    std::vector<std::string> names;
    std::set<std::string> seen;
    Gate gate;
    const Lines lines{.gate = &gate, .seen = &seen, .names = &names};
    bool alive = true;
    std::size_t cursor = 0;
    while (cursor < text.size()) {
        const Cut cut = next_line(text, cursor);
        cursor = cut.next;
        alive = alive && push_line(lines, cut.text);
    }
    if (!alive) return std::unexpected(gate.error);
    return names;
}

void write_record(std::span<std::byte> out, const Entry& entry, std::size_t pos) {
    put_le(out, Field{.at = pos, .width = 8}, entry.hash);
    put_le(out, Field{.at = pos + 8, .width = 8}, entry.offset);
    put_le(out, Field{.at = pos + 16, .width = 4}, entry.sealed_size);
    put_le(out, Field{.at = pos + 20, .width = 4}, entry.raw_size);
    put_le(out, Field{.at = pos + 24, .width = 2}, entry.method);
}

struct Placed {
    std::vector<Chunk> chunks;
    std::uint64_t end = kHeaderBytes;
    bool is_ok = true;
};

void place_one(Placed& placed, Chunk chunk) {
    const auto size = chunk.bytes.size();
    const bool room = placed.end <= std::numeric_limits<std::uint64_t>::max() - size;
    if (!placed.is_ok) return;
    if (!room) placed.is_ok = false;
    if (!placed.is_ok) return;
    chunk.entry.offset = placed.end;
    placed.end += size;
    placed.chunks.push_back(std::move(chunk));
}

std::vector<Entry> by_hash(const std::vector<Chunk>& chunks) {
    std::vector<Entry> entries;
    entries.reserve(chunks.size());
    for (const Chunk& chunk : chunks)
        entries.push_back(chunk.entry);
    std::ranges::sort(entries, {}, &Entry::hash);
    return entries;
}

bool unique_hashes(const std::vector<Entry>& entries) {
    bool distinct = true;
    for (std::size_t index = 1; index < entries.size(); ++index)
        distinct = distinct && entries[index].hash != entries[index - 1].hash;
    return distinct;
}

using HeadBytes = std::array<std::byte, kHeaderBytes>;

Blob join_chunks(const HeadBytes& head, const std::vector<Chunk>& chunks, Bytes index) {
    Blob out;
    out.insert(out.end(), head.begin(), head.end());
    for (const Chunk& chunk : chunks)
        out.insert(out.end(), chunk.bytes.begin(), chunk.bytes.end());
    out.insert(out.end(), index.begin(), index.end());
    return out;
}

} // namespace

void mark(Gate& gate, Error error) {
    if (!gate.is_ok) return;
    gate.is_ok = false;
    gate.error = error;
}

bool legal_name(std::string_view name) {
    if (name.empty() || name.size() > kMaxName) return false;
    if (name == kManifestName) return false;
    if (name.starts_with('/') || name.ends_with('/')) return false;
    return segments_ok(name);
}

std::string fold_ascii(std::string_view name) {
    std::string folded(name);
    for (char& unit : folded) {
        const auto code = static_cast<unsigned char>(unit);
        const bool upper = code >= 'A' && code <= 'Z';
        unit = upper ? static_cast<char>(code - 'A' + 'a') : unit;
    }
    return folded;
}

KeysResult derive_subkeys(const Key& pack_key) {
    SubKeys keys;
    const bool entries = derive(keys.entries.bytes, pack_key.bytes, kEntryId);
    const bool index = derive(keys.index.bytes, pack_key.bytes, kIndexId);
    const bool names = derive(keys.names.bytes, pack_key.bytes, kNameId);
    const bool check = derive(keys.check.bytes, pack_key.bytes, kCheckId);
    const bool ready_keys = entries && index && names && check;
    if (!ready_keys) return std::unexpected(Error::kCrypto);
    return keys;
}

std::uint64_t hash_name(const Key& name_key, std::string_view name) {
    std::array<std::byte, kCheckBytes> hash{};
    Bytes message;
    if (!name.empty()) {
        const std::span<const char> chars(name.data(), name.size());
        message = std::as_bytes(chars);
    }
    const bool hashed = blake16(hash, name_key.bytes, message);
    core::check(hashed, "BLAKE2b 16 byte với khoá 32 byte");
    return get_le(hash, Field{.at = 0, .width = 8});
}

std::array<std::byte, kCheckBytes> package_check(const SubKeys& keys) {
    std::array<std::byte, kCheckBytes> out{};
    const bool hashed = blake16(out, keys.check.bytes, {});
    core::check(hashed, "BLAKE2b của khoá kiểm");
    return out;
}

BlobResult seal_plain(const Key& key, Bytes plain, Bytes extra) {
    if (plain.size() > kMaxPlain) return std::unexpected(Error::kTooLarge);
    Blob out(plain.size() + kOverhead);
    const Box box{.destination = out, .source = plain, .extra = extra, .key = key.bytes};
    const bool sealed = seal_box(box);
    if (!sealed) return std::unexpected(Error::kCrypto);
    return out;
}

ChunkResult seal_chunk(const SubKeys& keys, std::string_view name, Bytes raw) {
    if (raw.size() > kMaxPlain) return std::unexpected(Error::kTooLarge);
    Chunk chunk;
    chunk.entry.hash = hash_name(keys.names, name);
    chunk.entry.raw_size = static_cast<std::uint32_t>(raw.size());
    chunk.entry.method = 0;
    const std::array<std::byte, 12> extra = item_extra(chunk.entry);
    auto sealed = seal_plain(keys.entries, raw, extra);
    if (!sealed) return std::unexpected(sealed.error());
    chunk.bytes = std::move(*sealed);
    chunk.entry.sealed_size = static_cast<std::uint32_t>(chunk.bytes.size());
    return chunk;
}

std::array<std::byte, kHeaderBytes> encode_head(const Head& head) {
    std::array<std::byte, kHeaderBytes> out{};
    write_magic(out);
    put_le(out, Field{.at = 8, .width = 2}, kVersion);
    put_le(out, Field{.at = 12, .width = 4}, head.count);
    put_le(out, Field{.at = 16, .width = 8}, head.index_offset);
    put_le(out, Field{.at = 24, .width = 8}, head.index_size);
    copy_bytes(std::span(out).subspan(32, kCheckBytes), head.check);
    return out;
}

Blob encode_index(std::span<const Entry> entries) {
    const auto bytes = entries.size() * kRecord;
    core::check(entries.empty() || bytes / kRecord == entries.size(), "chỉ mục tràn");
    Blob out(bytes);
    for (std::size_t index = 0; index < entries.size(); ++index)
        write_record(out, entries[index], index * kRecord);
    return out;
}

CatalogResult open_catalog(const Key& pack_key, const View& view) {
    const auto loaded = load_head(view);
    if (!loaded) return std::unexpected(loaded.error());
    auto sub = derive_subkeys(pack_key);
    if (!sub) return std::unexpected(sub.error());
    if (!check_matches(*sub, loaded->head)) return std::unexpected(Error::kWrongKey);
    if (!index_fits(loaded->head, view.size)) return std::unexpected(Error::kCorrupt);
    const auto sealed = read_span(view, loaded->head.index_offset, loaded->head.index_size);
    if (!sealed) return std::unexpected(sealed.error());
    const auto plain = open_with(sub->index, *sealed, loaded->raw);
    if (!plain) return std::unexpected(plain.error());
    const std::uint64_t need = std::uint64_t{loaded->head.count} * kRecord;
    if (plain->size() != need) return std::unexpected(Error::kCorrupt);
    std::vector<Entry> entries;
    entries.reserve(loaded->head.count);
    bool alive = true;
    for (std::uint32_t index = 0; index < loaded->head.count; ++index)
        alive = alive && take_entry(entries, *plain, loaded->head.index_offset, index);
    if (!alive) return std::unexpected(Error::kCorrupt);
    Catalog catalog;
    catalog.keys = std::move(*sub);
    catalog.entries = std::move(entries);
    return catalog;
}

BlobResult read_named(const Catalog& book, const View& view, std::string_view name) {
    const std::uint64_t hash = hash_name(book.keys.names, name);
    const Entry* entry = find_hash(book.entries, hash);
    if (entry == nullptr) return std::unexpected(Error::kMissing);
    const auto sealed = read_span(view, entry->offset, entry->sealed_size);
    if (!sealed) return std::unexpected(sealed.error());
    return open_entry(book.keys.entries, *sealed, *entry);
}

NamesResult read_names(const Catalog& book, const View& view) {
    const auto body = read_named(book, view, kManifestName);
    if (!body) return std::unexpected(body.error());
    return split_lines(*body);
}

BlobResult pack_chunks(const SubKeys& keys, std::vector<Chunk> chunks) {
    Placed placed;
    for (Chunk& chunk : chunks)
        place_one(placed, std::move(chunk));
    if (!placed.is_ok) return std::unexpected(Error::kTooLarge);
    const std::vector<Entry> entries = by_hash(placed.chunks);
    if (!unique_hashes(entries)) return std::unexpected(Error::kDuplicate);
    if (entries.size() > std::numeric_limits<std::uint32_t>::max()) return std::unexpected(Error::kTooLarge);
    const Blob plain = encode_index(entries);
    Head head;
    head.count = static_cast<std::uint32_t>(entries.size());
    head.index_offset = placed.end;
    head.index_size = plain.size() + kOverhead;
    head.check = package_check(keys);
    const auto raw_head = encode_head(head);
    const auto index = seal_plain(keys.index, plain, raw_head);
    if (!index) return std::unexpected(index.error());
    return join_chunks(raw_head, placed.chunks, *index);
}

} // namespace game::seal::detail
