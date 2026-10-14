#include "config/client.hpp"

#include "config/detail/node.hpp"
#include "config/detail/read.hpp"
#include "config/issue.hpp"

#include <array>
#include <string_view>

namespace game::config {
namespace {

using detail::Bag;
using detail::Choice;
using detail::Cursor;
using detail::keep;
using detail::Node;

constexpr std::array<std::string_view, 2> kRoot{"schema", "hud"};
constexpr std::array<std::string_view, 1> kHud{"avatar_frame"};
constexpr std::array<Choice<AvatarFrame>, 2> kFrames{{
    {.name = "round", .value = AvatarFrame::kRound},
    {.name = "square", .value = AvatarFrame::kSquare},
}};

void read_hud(Bag& bag, const Node* table, ClientHud& hud) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kHud);
    keep(cursor.choice("avatar_frame", kFrames), hud.avatar_frame);
}

[[nodiscard]] Client read_sections(Bag& bag, const Node& root) {
    Cursor cursor{bag, root};
    cursor.schema();
    cursor.only(kRoot);
    Client client;
    read_hud(bag, cursor.child("hud"), client.hud);
    return client;
}

} // namespace

ReadResult<Client> read_client(std::string_view text) {
    return detail::read_document<Client>(text, read_sections);
}

} // namespace game::config
