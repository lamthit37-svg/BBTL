// Niêm và mở một gói trong bộ nhớ. Bảng kê là mục cuối, cũng được niêm, không nằm dạng rõ.
#include "seal/package.hpp"

#include "core/check.hpp"
#include "seal/detail/format.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <set>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::seal {
namespace {

using detail::Catalog;
using detail::Chunk;
using detail::fold_ascii;
using detail::Gate;
using detail::legal_name;
using detail::mark;
using detail::pack_chunks;
using detail::read_named;
using detail::read_names;
using detail::seal_chunk;
using ChunksResult = std::expected<std::vector<Chunk>, Error>;
using detail::SubKeys;
using detail::View;

struct Memory {
    Bytes bytes;
};

struct Seen {
    Gate* gate = nullptr;
    std::set<std::string>* folded = nullptr;
};

struct ChunkGate {
    Gate gate;
    std::vector<Chunk> chunks;
};

// Cùng kiểu con trỏ với read_input. Nhánh kia ghi ifstream nên tham số không phải const void*.
// NOLINTNEXTLINE(misc-const-correctness)
bool read_memory(void* context, std::uint64_t offset, std::span<std::byte> into) {
    const auto* memory = static_cast<const Memory*>(context);
    if (memory == nullptr) return false;
    if (offset > memory->bytes.size()) return false;
    const auto start = static_cast<std::size_t>(offset);
    if (into.size() > memory->bytes.size() - start) return false;
    for (std::size_t index = 0; index < into.size(); ++index)
        into[index] = memory->bytes[start + index];
    return true;
}

View view_of(Memory& memory) {
    View view;
    view.size = memory.bytes.size();
    view.read = &read_memory;
    view.context = &memory;
    return view;
}

bool accept_name(const Seen& seen, std::string_view name) {
    if (seen.gate == nullptr || seen.folded == nullptr) return false;
    if (!seen.gate->is_ok) return false;
    if (!legal_name(name)) mark(*seen.gate, Error::kName);
    if (!seen.gate->is_ok) return false;
    const std::string folded = fold_ascii(name);
    const bool fresh = seen.folded->insert(folded).second;
    if (!fresh) mark(*seen.gate, Error::kDuplicate);
    return fresh;
}

Gate check_names(std::span<const Item> items) {
    Gate gate;
    std::set<std::string> folded;
    const Seen seen{.gate = &gate, .folded = &folded};
    bool alive = true;
    for (const Item& item : items)
        alive = alive && accept_name(seen, item.name);
    if (!alive && gate.is_ok) mark(gate, Error::kName);
    return gate;
}

bool push_chunk(ChunkGate& sink, const SubKeys& keys, std::string_view name, Bytes raw) {
    if (!sink.gate.is_ok) return false;
    auto chunk = seal_chunk(keys, name, raw);
    if (!chunk) mark(sink.gate, chunk.error());
    if (!sink.gate.is_ok) return false;
    sink.chunks.push_back(std::move(*chunk));
    return true;
}

void append_line(Blob& body, std::string_view name) {
    for (const char unit : name)
        body.push_back(static_cast<std::byte>(unit));
    body.push_back(std::byte{'\n'});
}

Blob manifest_body(std::span<const Item> items) {
    Blob body;
    for (const Item& item : items)
        append_line(body, item.name);
    return body;
}

ChunksResult seal_all(const SubKeys& keys, std::span<const Item> items) {
    ChunkGate sink;
    bool alive = true;
    for (const Item& item : items)
        alive = alive && push_chunk(sink, keys, item.name, item.bytes);
    if (!alive) return std::unexpected(sink.gate.error);
    const Blob body = manifest_body(items);
    const bool added = push_chunk(sink, keys, kManifestName, body);
    if (!added) return std::unexpected(sink.gate.error);
    return std::move(sink.chunks);
}

struct Gather {
    const Catalog* catalog = nullptr;
    const View* view = nullptr;
    std::vector<Item> items;
    Gate gate;
};

bool gather_one(Gather& gather, std::string_view name) {
    if (gather.catalog == nullptr || gather.view == nullptr) return false;
    if (!gather.gate.is_ok) return false;
    auto body = read_named(*gather.catalog, *gather.view, name);
    if (!body) mark(gather.gate, body.error());
    if (!gather.gate.is_ok) return false;
    Item item;
    item.name = std::string(name);
    item.bytes = std::move(*body);
    gather.items.push_back(std::move(item));
    return true;
}

ItemsResult gather_all(const Catalog& catalog, const View& view) {
    const auto names = read_names(catalog, view);
    if (!names) return std::unexpected(names.error());
    Gather gather{.catalog = &catalog, .view = &view, .items = {}, .gate = {}};
    bool alive = true;
    for (const std::string& name : *names)
        alive = alive && gather_one(gather, name);
    if (!alive) return std::unexpected(gather.gate.error);
    return std::move(gather.items);
}

} // namespace

std::string_view describe(Error error) noexcept {
    switch (error) {
    case Error::kCrypto: return "không khởi tạo được mật mã";
    case Error::kBadMagic: return "không phải gói TLBBPAK1";
    case Error::kBadVersion: return "bản gói không được hỗ trợ";
    case Error::kWrongKey: return "sai khoá";
    case Error::kCorrupt: return "gói bị sửa hoặc cụt";
    case Error::kMissing: return "không có mục này";
    case Error::kDuplicate: return "tên trùng hoặc cùng băm";
    case Error::kName: return "tên tệp không hợp lệ";
    case Error::kIo: return "không đọc hoặc ghi được tệp";
    case Error::kTooLarge: return "một tệp vượt 4 GiB";
    }
    core::fail("mã lỗi gói ngoài miền");
}

BlobResult seal(const Key& key, std::span<const Item> items) {
    const Gate names = check_names(items);
    if (!names.is_ok) return std::unexpected(names.error);
    const auto sub = detail::derive_subkeys(key);
    if (!sub) return std::unexpected(sub.error());
    auto chunks = seal_all(*sub, items);
    if (!chunks) return std::unexpected(chunks.error());
    return pack_chunks(*sub, std::move(*chunks));
}

BlobResult open_named(const Key& key, Bytes package, std::string_view name) {
    Memory memory{.bytes = package};
    const View view = view_of(memory);
    const auto catalog = detail::open_catalog(key, view);
    if (!catalog) return std::unexpected(catalog.error());
    return read_named(*catalog, view, name);
}

ItemsResult open_all(const Key& key, Bytes package) {
    Memory memory{.bytes = package};
    const View view = view_of(memory);
    const auto catalog = detail::open_catalog(key, view);
    if (!catalog) return std::unexpected(catalog.error());
    return gather_all(*catalog, view);
}

CountResult verify_bytes(const Key& key, Bytes package) {
    const auto items = open_all(key, package);
    if (!items) return std::unexpected(items.error());
    return items->size();
}

} // namespace game::seal
