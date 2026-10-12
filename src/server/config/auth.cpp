#include "config/auth.hpp"

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

constexpr std::string_view kRoot[] = {
    "schema",
    "database",
    "register",
    "password",
    "ticket",
    "login",
    "captcha",
    "security_card",
};
constexpr std::string_view kRegister[] = {"auto_register", "gift_points"};
constexpr std::string_view kPassword[] = {"ops_limit", "mem_limit_kib"};
constexpr std::string_view kTicket[] = {"ttl_seconds"};
constexpr std::string_view kLogin[] = {
    "relogin_limit",
    "relogin_block",
    "relogin_block_ms",
    "queue_turn_size",
    "max_sessions_per_device",
};
constexpr std::string_view kCaptcha[] = {"on_create", "on_enter"};
constexpr std::string_view kCard[] = {"enabled"};

void read_register(Bag& bag, const Node* table, Auth& auth) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kRegister);
    keep(cursor.flag("auto_register"), auth.auto_register);
    keep(cursor.bounded("gift_points", detail::kAmount), auth.gift_points);
}

void read_password(Bag& bag, const Node* table, Auth& auth) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kPassword);
    keep(cursor.bounded("ops_limit", detail::kCount), auth.ops_limit);
    keep(cursor.bounded("mem_limit_kib", detail::kCount), auth.mem_limit_kib);
}

void read_ticket(Bag& bag, const Node* table, Auth& auth) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kTicket);
    keep(cursor.seconds("ttl_seconds"), auth.ttl_seconds);
}

void read_login_rules(Bag& bag, const Node* table, Auth& auth) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kLogin);
    keep(cursor.flag("relogin_limit"), auth.relogin_limit);
    keep(cursor.flag("relogin_block"), auth.relogin_block);
    keep(cursor.millis("relogin_block_ms"), auth.relogin_block_ms);
    keep(cursor.bounded("queue_turn_size", detail::kCount), auth.queue_turn_size);
    keep(cursor.bounded("max_sessions_per_device", detail::kCount), auth.max_sessions_per_device);
}

void read_captcha(Bag& bag, const Node* table, Auth& auth) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kCaptcha);
    keep(cursor.flag("on_create"), auth.on_create);
    keep(cursor.flag("on_enter"), auth.on_enter);
}

void read_card(Bag& bag, const Node* table, Auth& auth) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kCard);
    keep(cursor.flag("enabled"), auth.security_card);
}

[[nodiscard]] Auth read_sections(Bag& bag, const Node& root) {
    Cursor cursor{bag, root};
    cursor.schema();
    cursor.only(kRoot);
    Auth auth;
    read_login(bag, cursor.child("database"), auth.database);
    read_register(bag, cursor.child("register"), auth);
    read_password(bag, cursor.child("password"), auth);
    read_ticket(bag, cursor.child("ticket"), auth);
    read_login_rules(bag, cursor.child("login"), auth);
    read_captcha(bag, cursor.child("captcha"), auth);
    read_card(bag, cursor.child("security_card"), auth);
    return auth;
}

} // namespace

ReadResult<Auth> read_auth(std::string_view text) {
    return detail::read_document<Auth>(text, read_sections);
}

} // namespace game::config
