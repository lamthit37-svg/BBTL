#include "client/assets.hpp"

#include <algorithm>
#include <cstddef>
#include <optional>
#include <string_view>
#include <vector>

namespace game::client {
namespace {

// Phần trước dấu cách đầu tiên của rest; rest được cắt qua dấu cách ấy. Không có dấu cách thì
// không có gì và rest giữ nguyên.
[[nodiscard]] std::optional<std::string_view> take_word(std::string_view& rest) noexcept {
    const std::size_t space = rest.find(' ');
    if (space == std::string_view::npos) return std::nullopt;
    const std::string_view word = rest.substr(0, space);
    rest.remove_prefix(space + 1);
    return word;
}

[[nodiscard]] std::optional<AssetEntry> entry_of(std::string_view line) noexcept {
    if (!line.empty() && line.back() == '\r') line.remove_suffix(1);
    std::string_view rest = line;
    const std::optional<std::string_view> group = take_word(rest);
    if (!group || (*group != "D" && *group != "S")) return std::nullopt;
    const std::optional<std::string_view> stamp = take_word(rest);
    if (!stamp || stamp->empty() || rest.empty()) return std::nullopt;
    return AssetEntry{.group = group->front(), .stamp = *stamp, .path = rest};
}

void take_line(std::vector<AssetEntry>& entries, std::string_view line) {
    const std::optional<AssetEntry> entry = entry_of(line);
    if (entry) entries.push_back(*entry);
}

[[nodiscard]] bool is_before(const AssetEntry& left, const AssetEntry& right) noexcept {
    if (left.group != right.group) return left.group < right.group;
    return left.path < right.path;
}

// Mục cùng nhóm và cùng đường dẫn trong sổ đã xếp; nullptr khi không có.
[[nodiscard]] const AssetEntry* find_entry(const std::vector<AssetEntry>& sorted, const AssetEntry& wanted) noexcept {
    const auto found = std::ranges::lower_bound(sorted, wanted, is_before);
    if (found == sorted.end()) return nullptr;
    if (found->group != wanted.group || found->path != wanted.path) return nullptr;
    return &*found;
}

struct Sieve {
    const std::vector<AssetEntry>* kept = nullptr;
    std::vector<AssetEntry>* stale = nullptr;
};

void sift(Sieve sieve, const AssetEntry& entry) {
    const AssetEntry* same = find_entry(*sieve.kept, entry);
    if (same != nullptr && same->stamp == entry.stamp) return;
    sieve.stale->push_back(entry);
}

} // namespace

std::vector<AssetEntry> read_asset_book(std::string_view text) {
    std::vector<AssetEntry> entries;
    std::size_t start = 0;
    while (start < text.size()) {
        const std::size_t end = std::min(text.find('\n', start), text.size());
        take_line(entries, text.substr(start, end - start));
        start = end + 1;
    }
    return entries;
}

std::vector<AssetEntry> assets_to_copy(const AssetBooks& books) {
    std::vector<AssetEntry> kept = read_asset_book(books.installed);
    std::ranges::sort(kept, is_before);
    std::vector<AssetEntry> stale;
    const Sieve sieve{.kept = &kept, .stale = &stale};
    for (const AssetEntry& entry : read_asset_book(books.packed)) {
        sift(sieve, entry);
    }
    return stale;
}

} // namespace game::client
