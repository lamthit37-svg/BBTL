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
using detail::keep;
using detail::Node;
using detail::read_login;

constexpr std::string_view kRoot[] = {"schema", "database", "flush", "journal"};
constexpr std::string_view kFlush[] = {"character_ms", "world_ms"};
constexpr std::string_view kJournal[] = {"dir"};

void read_flush(Bag& bag, const Node* table, Store& store) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kFlush);
    keep(cursor.millis("character_ms"), store.character_ms);
    keep(cursor.millis("world_ms"), store.world_ms);
}

void read_journal(Bag& bag, const Node* table, Store& store) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kJournal);
    keep(cursor.text("dir", detail::kPathText), store.dir);
}

[[nodiscard]] Store read_sections(Bag& bag, const Node& root) {
    Cursor cursor{bag, root};
    cursor.schema();
    cursor.only(kRoot);
    Store store;
    read_login(bag, cursor.child("database"), store.database);
    read_flush(bag, cursor.child("flush"), store);
    read_journal(bag, cursor.child("journal"), store);
    return store;
}

} // namespace

ReadResult<Store> read_store(std::string_view text) {
    return detail::read_document<Store>(text, read_sections);
}

} // namespace game::config
