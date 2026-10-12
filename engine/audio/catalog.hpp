// Bảng id SoundInfo trong sound_table.xml. Thiếu id là dữ liệu, không phải lỗi lập trình.
#pragma once

#include "core/error.hpp"

#include <cstddef>
#include <string>
#include <string_view>
#include <vector>

namespace game::audio {

class Catalog {
public:
    // Đọc các thẻ <item name value>. Giữ mục đầu nếu tên lặp.
    [[nodiscard]] core::Status load(std::string_view xml_text);

    [[nodiscard]] std::string_view find(std::string_view name) const noexcept;

    [[nodiscard]] std::size_t size() const noexcept { return names_.size(); }

private:
    struct NamedPath {
        std::string_view name;
        std::string_view path;
    };

    void add_unique(NamedPath row);

    std::vector<std::string> names_;
    std::vector<std::string> paths_;
};

} // namespace game::audio
