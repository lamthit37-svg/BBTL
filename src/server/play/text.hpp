/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/play/text.hpp
 *  PHÂN HỆ   : Server / Play / Text
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Sách chữ của hội thoại và nhiệm vụ: mã chuỗi (ops::string_id của khoá)
 *    sang câu chữ. Máy chủ dựng câu hoàn chỉnh rồi mới gửi, nên client không
 *    cần bảng chuỗi của máy chủ. Nguồn theo thứ tự đè nhau: StrDictionary của
 *    client (khoá dạng GGZLR_160902_03), tables/server/dialogue.<ngôn ngữ>.txt
 *    (khoá lua.<băm> do công cụ trích), rồi config/text/dialogue.<ngôn ngữ>.txt
 *    của nhà phát hành.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Chữ giữ nguyên thẻ màu (#R, #W...) và thẻ giao diện (#{...}) của game: phần đó client dựng. Chỗ {0}, {1}... là tham số có kiểu của
// TextRef, máy chủ thay bằng tên người chơi, tên NPC hay một đại lượng số.

#pragma once

#include "ops/ops.hpp"
#include "table/tsv.hpp"

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <unordered_map>

namespace game::play {

class TextBook {
public:
    // Thêm mọi dòng của một bảng hai cột (khoá, chữ); khoá đã có thì bị đè. Trả số dòng đã thêm.
    std::size_t add(const table::Tsv& two_columns);

    [[nodiscard]] const std::string* find(std::uint32_t id) const noexcept;
    [[nodiscard]] std::size_t size() const noexcept { return by_id_.size(); }

private:
    std::unordered_map<std::uint32_t, std::string> by_id_;
};

// Tên đã dựng sẵn cho tham số kPlayer và kNpc.
struct Names {
    std::string_view player;
    std::string_view npc;
};

// Dựng chữ của một tham chiếu. Mã chuỗi lạ (hoặc 0) cho chuỗi rỗng. Kết quả cắt tại ranh giới ký tự UTF-8 ở `max_bytes`.
[[nodiscard]] std::string render(const TextBook& book, const ops::TextRef& text, const Names& names,
    const ops::Context& context, std::size_t max_bytes);

// Cắt `text` còn tối đa `max_bytes` byte mà không chẻ đôi một ký tự UTF-8.
[[nodiscard]] std::string clip_utf8(std::string text, std::size_t max_bytes);

} // namespace game::play
