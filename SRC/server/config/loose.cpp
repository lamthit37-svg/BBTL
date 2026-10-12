#include "config/loose.hpp"

#include "config/detail/node.hpp"
#include "config/detail/read.hpp"
#include "config/issue.hpp"

#include <string_view>

namespace game::config {

namespace {

[[nodiscard]] LooseDocument read_sections(detail::Bag& bag, const detail::Node& root) {
    detail::Cursor cursor{bag, root};
    cursor.schema();
    LooseDocument document;
    document.schema = 1;
    return document;
}

} // namespace

ReadResult<LooseDocument> read_loose(std::string_view text) {
    return detail::read_document<LooseDocument>(text, read_sections);
}

} // namespace game::config
