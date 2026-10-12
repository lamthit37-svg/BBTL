#include "config/store.hpp"

#include "config/detail/node.hpp"
#include "config/detail/read.hpp"
#include "config/issue.hpp"

#include <array>
#include <string_view>
#include <utility>

namespace game::config {
namespace {

using detail::Bag;
using detail::Cursor;
using detail::finish;
using detail::keep;
using detail::Node;
using detail::parse_text;
using detail::read_login;

constexpr std::string_view kRoot[] = {"schema", "database", "flush", "journal"};
constexpr std::string_view kFlush[] = {"character_ms", "world_ms"};
constexpr std::string_view kJournal[] = {"dir"};

void read_flush(Bag& bag, const Node* table, Store& store) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.unknown(kFlush);
    keep(cursor.millis("character_ms"), store.character_ms);
    keep(cursor.millis("world_ms"), store.world_ms);
}

void read_journal(Bag& bag, const Node* table, Store& store) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.unknown(kJournal);
    keep(cursor.text("dir", detail::kPathText), store.dir);
}

[[nodiscard]] Store read_sections(Bag& bag, const Node& root) {
    Cursor cursor{bag, root};
    cursor.schema();
    cursor.unknown(kRoot);
    Store store;
    read_login(bag, cursor.child("database"), store.database);
    read_flush(bag, cursor.child("flush"), store);
    read_journal(bag, cursor.child("journal"), store);
    return store;
}

} // namespace

ReadResult<Store> read_store(std::string_view text) {
    const detail::Parsed parsed = parse_text(text);
    if (!parsed.issues.empty()) return std::unexpected(std::move(parsed.issues));
    Bag bag;
    return finish(read_sections(bag, parsed.root), bag);
}

} // namespace game::config
