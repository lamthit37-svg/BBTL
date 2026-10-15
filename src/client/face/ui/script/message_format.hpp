// Gói lời nhắn của ScriptGlobal_Format (Game.exe 9001 0x140233f50, bộ gói FUN_140766830): script đưa chuỗi mẫu và tối đa 15 chuỗi đối số,
// hàm trả MỘT chuỗi đã đóng gói mà lớp xử lý lời nhắn của game (chat, PushDebugMessage) tách lại về sau; đây KHÔNG phải printf.
//
// Bố cục byte (n là độ dài chuỗi mẫu):
//   [0, n-1)  chuỗi mẫu bỏ ký tự cuối (gốc chép n-1 byte)
//   n-1       '*'  (ghi đè ký tự cuối của chuỗi mẫu)
//   n         số đối số
//   n+1       tổng độ dài các đối số kèm tiêu đề, cộng 3
//   n+2...    mỗi đối số: '*', độ dài (một byte), nội dung
//   sau cùng  ' ' nếu tổng ở trên đúng bằng 0x38 (gốc thêm để byte n+1 không rơi vào 0x3b), rồi '}'
// Bộ đệm gốc dài 1024 byte, điền 0; kết quả đẩy lên Lua bằng lua_pushstring nên cắt ở byte NUL đầu tiên (đối số rỗng có byte độ dài 0,
// vì thế cắt cụt lời nhắn ở đó).
#pragma once

#include <cstddef>
#include <optional>
#include <span>
#include <string_view>

namespace game::ui::script {

inline constexpr std::size_t kMessageBufferSize = 1024;
inline constexpr std::size_t kMessageArgLimit = 15;

// Gói theo bố cục trên vào out (điền 0 trước), rồi trả độ dài tới byte NUL đầu tiên. nullopt khi không đóng gói được: chuỗi mẫu rỗng
// (gốc chép −1 byte và chết), quá kMessageArgLimit đối số, hay lời nhắn không vừa bộ đệm (gốc ghi tràn ngăn xếp); hai trường hợp sau là
// Khác gốc. Bộ đệm do người gọi giữ để hàm native không giữ đối tượng có destructor qua một lời gọi API Lua.
[[nodiscard]] std::optional<std::size_t> pack_message(std::string_view pattern, std::span<const std::string_view> args,
    std::span<char, kMessageBufferSize> out);

} // namespace game::ui::script
