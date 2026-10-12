// Ngôn ngữ của bản client: mã này là tên tệp nguồn assets/i18n/<mã>.tsv và là phần tên của các tệp
// mà TOOLS/content/build_i18n.py dựng cùng client vào thư mục dữ liệu (Table/ui_strings.<mã>.tsv,
// Table/scene_names.<mã>.tsv, i18n/<mã>/Interface/). Khai một chỗ cho bảng chuỗi và bộ vẽ.
#pragma once

#include <string_view>

namespace game::ui {

inline constexpr std::string_view kLanguage = "vi";

} // namespace game::ui
