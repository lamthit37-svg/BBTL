#pragma once
// Bố cục byte của .tlpak và một lần niêm. Đọc theo vị trí, không giữ cả gói.
#include "seal/package.hpp"

#include <array>
#include <cstdint>
#include <expected>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::seal::detail {

inline constexpr std::size_t kOverhead = 40;
inline constexpr std::size_t kRecord = 28;
inline constexpr std::size_t kCheckBytes = 16;
inline constexpr std::uint64_t kMaxPlain = 0xFFFFFFFFU - kOverhead;

struct Entry {
    std::uint64_t hash = 0;
    std::uint64_t offset = 0;
    std::uint32_t sealed_size = 0;
    std::uint32_t raw_size = 0;
    std::uint16_t method = 0;
};

struct SubKeys {
    Key entries;
    Key index;
    Key names;
    Key check;
};

struct Chunk {
    Entry entry;
    Blob bytes;
};

struct Head {
    std::uint32_t count = 0;
    std::uint64_t index_offset = 0;
    std::uint64_t index_size = 0;
    std::array<std::byte, kCheckBytes> check{};
};

struct View {
    std::uint64_t size = 0;
    bool (*read)(void* context, std::uint64_t offset, std::span<std::byte> into) = nullptr;
    void* context = nullptr;
};

struct Catalog {
    SubKeys keys;
    std::vector<Entry> entries;
};

struct Gate {
    Error error = Error::kIo;
    bool is_ok = true;
};

using ChunkResult = std::expected<Chunk, Error>;
using KeysResult = std::expected<SubKeys, Error>;
using HeadResult = std::expected<Head, Error>;
using EntriesResult = std::expected<std::vector<Entry>, Error>;
using CatalogResult = std::expected<Catalog, Error>;
using NamesResult = std::expected<std::vector<std::string>, Error>;
using ChunksResult = std::expected<std::vector<Chunk>, Error>;

void mark(Gate& gate, Error error);

[[nodiscard]] bool legal_name(std::string_view name);
[[nodiscard]] std::string fold_ascii(std::string_view name);
[[nodiscard]] KeysResult derive_subkeys(const Key& pack_key);
[[nodiscard]] std::uint64_t hash_name(const Key& name_key, std::string_view name);
[[nodiscard]] ChunkResult seal_chunk(const SubKeys& keys, std::string_view name, Bytes raw);
[[nodiscard]] BlobResult seal_plain(const Key& key, Bytes plain, Bytes extra);
[[nodiscard]] Blob encode_index(std::span<const Entry> entries);
[[nodiscard]] std::array<std::byte, kHeaderBytes> encode_head(const Head& head);
[[nodiscard]] std::array<std::byte, kCheckBytes> package_check(const SubKeys& keys);
[[nodiscard]] CatalogResult open_catalog(const Key& pack_key, const View& view);
[[nodiscard]] BlobResult read_named(const Catalog& book, const View& view, std::string_view name);
[[nodiscard]] NamesResult read_names(const Catalog& book, const View& view);
[[nodiscard]] BlobResult pack_chunks(const SubKeys& keys, std::vector<Chunk> chunks);

} // namespace game::seal::detail
