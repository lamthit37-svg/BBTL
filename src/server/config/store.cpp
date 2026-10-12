#include "config/store.hpp"

#include "config/detail/node.hpp"
#include "config/detail/read.hpp"
#include "config/issue.hpp"

#include <array>
#include <chrono>
#include <cstdint>
#include <optional>
#include <string_view>
#include <utility>

namespace game::config {
namespace {

using detail::Bag;
using detail::Cursor;
using detail::keep;
using detail::Node;
using detail::read_login;

constexpr std::string_view kRoot[] = {"schema", "database", "flush", "journal", "security"};
constexpr std::string_view kSecurity[] = {
    "standing_cache_ms", "name_reserve_days", "female_faces", "male_faces", "female_hairs", "male_hairs"};
// Trần cửa sổ ban 10 giây; 0 là không nhớ (mỗi lệnh hỏi auth).
constexpr detail::Bound kStandingMs{.least = 0, .most = 10000};
constexpr detail::Bound kReserveDays{.least = 0, .most = 3650};
// 65535 là giá trị canh của bảng client, không bao giờ là id tạo được.
constexpr detail::Bound kLookId{.least = 0, .most = 65534};
constexpr std::size_t kLookMost = 256;
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

void read_security(Bag& bag, const Node* table, StoreSecurity& security) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kSecurity);
    if (cursor.has("standing_cache_ms")) {
        const std::optional<std::int64_t> ms = cursor.bounded("standing_cache_ms", kStandingMs);
        if (ms) security.standing_cache_ms = std::chrono::milliseconds{*ms};
    }
    if (cursor.has("name_reserve_days")) {
        keep(cursor.bounded("name_reserve_days", kReserveDays), security.name_reserve_days);
    }
    if (cursor.has("female_faces")) keep(cursor.integers("female_faces", kLookId, kLookMost), security.female_faces);
    if (cursor.has("male_faces")) keep(cursor.integers("male_faces", kLookId, kLookMost), security.male_faces);
    if (cursor.has("female_hairs")) keep(cursor.integers("female_hairs", kLookId, kLookMost), security.female_hairs);
    if (cursor.has("male_hairs")) keep(cursor.integers("male_hairs", kLookId, kLookMost), security.male_hairs);
}

[[nodiscard]] Store read_sections(Bag& bag, const Node& root) {
    Cursor cursor{bag, root};
    cursor.schema();
    cursor.only(kRoot);
    Store store;
    read_login(bag, cursor.child("database"), store.database);
    read_flush(bag, cursor.child("flush"), store);
    read_journal(bag, cursor.child("journal"), store);
    // [security] tuỳ chọn: tệp cũ không có nhóm này vẫn đọc được, mọi nút lấy mặc định an toàn.
    if (cursor.has("security")) read_security(bag, cursor.child("security"), store.security);
    return store;
}

} // namespace

ReadResult<Store> read_store(std::string_view text) {
    return detail::read_document<Store>(text, read_sections);
}

} // namespace game::config
