/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/book/quest/defs.hpp
 *  PHÂN HỆ   : Client / Sổ sách / Nhiệm vụ
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - DefBook: bản ghi định nghĩa nhiệm vụ theo id script, nạp trễ như Game.exe
 *    (0x1401e0d00 tra hoặc dựng bản ghi mặc định, 0x1402cdbc0 nạp tệp khi
 *    GetPlayerMission_Description chạy). Chưa nạp thì getter thấy bản ghi mặc
 *    định (-1 hết), đúng như gốc.
 *  - Bảng id script sang tệp đọc từ Script.dat của client (bộ nạp 0x1406865b0).
 *    Logic thuần: tệp đọc qua Reader do bên dùng đưa vào.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "quest/misdesc.hpp"

#include <cstdint>
#include <expected>
#include <functional>
#include <map>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::quest {

// id script sang đường dẫn tệp trong Config (dấu '/', không '/' đầu), ví dụ
// "event/dali/edali_newquest_001.lua".
using ScriptIndex = std::map<std::int32_t, std::string>;

// Đọc Script.dat như bộ nạp 0x1406865b0: dòng bắt đầu bằng ';' là chú thích; mọi dòng trước dòng
// "MGR_TXT" (không phân biệt hoa thường) bị bỏ; dòng sau đó cắt khoảng trắng và tab hai đầu, lấy số
// trước dấu '=' đầu tiên làm id (atoi), phần sau làm đường dẫn. Id lặp thì dòng sau ghi đè. Lỗi:
// không thấy dòng "MGR_TXT". Khác gốc: gốc đọc đường dẫn nguyên văn từ '='; ở đây đổi '\' thành '/'
// và bỏ '/' đầu ngay lúc đọc (gốc đổi '\' lúc tra, trong 0x1402cdbc0).
[[nodiscard]] std::expected<ScriptIndex, std::string> parse_script_index(std::string_view text);

// Đọc nội dung tệp theo đường dẫn của ScriptIndex; nullopt khi không đọc được.
using FileReader = std::function<std::optional<std::string>(std::string_view path)>;

class DefBook {
public:
    DefBook() = default;
    DefBook(ScriptIndex index, FileReader reader);

    // Bản ghi của script: mặc định khi chưa nạp hoặc nạp lỗi, như bản ghi vừa dựng của gốc.
    [[nodiscard]] const MissionDef& find(std::int32_t script) const;
    // Nạp tệp của script nếu chưa nạp (GetPlayerMission_Description). Script không có trong chỉ mục
    // hay tệp lỗi: ghi một dòng vào notes và bản ghi giữ mặc định. Khác gốc: gốc ném ngoại lệ rồi
    // thử lại ở lần gọi sau; ở đây ghi lỗi một lần và không đọc lại.
    void load(std::int32_t script);
    // Lời nhắn lỗi nạp tệp kể từ lần lấy trước, mỗi script một dòng.
    [[nodiscard]] std::vector<std::string> take_notes();

private:
    struct Entry {
        MissionDef def;
        bool is_done = false;
    };

    ScriptIndex index_;
    FileReader reader_;
    std::map<std::int32_t, Entry> entries_;
    std::vector<std::string> notes_;
};

} // namespace game::quest
