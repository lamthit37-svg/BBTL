// Bảng chân dung nhân vật: id (máy chủ gửi cho từng nhân vật) sang ảnh "set:<bộ> image:<ảnh>". Dữ
// liệu là Table/portraits.tsv do TOOLS/content/collect_ui.py trích từ Config/CharacterFace.txt của
// client 2026 (cột id, race, image). Client gốc tra bảng này trong Player:GetData("PORTRAIT") và
// Target:GetData("PORTRAIT").
// Nguồn: bản mới của dự án; cách tra theo GMGameInterface_Script_PlayerMySelf.cpp (dòng 454-481)
// của _ref: không có dòng thì chuỗi rỗng.
#pragma once

#include "hero/hero.hpp"
#include "table/tsv.hpp"

#include <cstddef>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui::panel {

// Một dòng của bảng: id và ảnh nguyên văn.
struct Portrait {
    hero::PortraitId id{};
    std::string image;
};

class Portraits {
public:
    // Dòng có id không phải số nguyên hay ảnh không đúng dạng bị bỏ; thiếu cột thì bảng rỗng. id
    // lặp thì dòng gặp trước thắng.
    [[nodiscard]] static Portraits from_table(const table::Tsv& table);

    // Ảnh của chân dung id; rỗng khi bảng không có. Chuỗi sống cùng bảng.
    [[nodiscard]] std::string_view image_of(hero::PortraitId id) const noexcept;
    // Tên các bộ ảnh mà bảng dùng, không lặp, theo thứ tự gặp: giao diện phải nạp chúng thì ảnh
    // chân dung mới vẽ được.
    [[nodiscard]] std::span<const std::string> imagesets() const noexcept { return imagesets_; }
    [[nodiscard]] std::size_t size() const noexcept { return rows_.size(); }

private:
    // Xếp tăng theo id để tra bằng tìm nhị phân.
    std::vector<Portrait> rows_;
    std::vector<std::string> imagesets_;
};

} // namespace game::ui::panel
