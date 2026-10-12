// Bộ vẽ bàn phím ảo (Falagard/SoftKeyWindow) của dàn trang: nền phím, ảnh của phím dưới chuột, chữ
// của từng phím, và phép đổi một điểm màn hình ra chỉ số ô phím. Nội bộ module gui; thứ tự ô nêu ở
// gui/softkey.hpp.
#pragma once

#include "gui/asset.hpp"
#include "gui/detail/draw.hpp"
#include "gui/sheet.hpp"

#include <cstddef>
#include <optional>

namespace game::gui::detail {

// Ô phím của cửa sổ bàn phím self chứa điểm màn hình pointer (mép trái và trên thuộc ô, mép phải
// và dưới không, như Rect::isPointInRect); nullopt khi điểm rơi vào khe giữa hai phím hay ngoài
// lưới.
[[nodiscard]] std::optional<std::size_t> soft_key_under(const GuiAsset& asset, const Placed& self, Pointer pointer);
// Vẽ nền của mọi phím, rồi ảnh trỏ (hay ảnh nhấn khi chuột đang nhấn) của phím dưới chuột nếu self
// là cửa sổ dưới chuột.
void draw_soft_keys(const Ctx& ctx, const Placed& self);
// Ra chữ của các ô ký tự theo Override "Keys": mỗi ô một ký tự, canh giữa ô, nguyên văn.
void soft_key_texts(const Ctx& ctx, const Placed& self);

} // namespace game::gui::detail
