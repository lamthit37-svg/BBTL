// Bản ghi XSCRIPT và bản ghi XParam của script giao diện (tầng B của LUA-GEN, docs/giao-viec/LUA-GEN/TANG-B.md): cách script
// nói chuyện với script phía máy chủ. Thuần dữ liệu và luật, không Lua, không mạng; dựng được ở mọi nền tảng.
//
// Chiều đi (Set_XSCRIPT_*, Send_XSCRIPT): script điền một bản ghi rồi gửi. Game.exe giữ bản ghi 128 byte ở CDataPool + 0x138dc và
// Send_XSCRIPT đóng nó vào gói CGExecuteScript (opcode 2219) cho CNetManager; protocol của dự án chưa có tin này, nên bản ghi
// vào hàng đợi ra (XScript::take_sent) cho tới khi nối mạng.
// Chiều về (Get_XParam_*): máy chủ gắn một bản ghi tham số vào sự kiện nó đẩy xuống; script đọc bản ghi của sự kiện đang chạy.
//
// Địa chỉ mã máy (Game.exe 9001, bản 3.71.9509 cùng hành vi): Clear_XSCRIPT 0x140241170 gọi 0x1407688d0 (id -1, tên, đếm, tham số
// về 0); Set_XSCRIPT_ScriptID 0x140241560, Set_XSCRIPT_Function_Name 0x140241400, Set_XSCRIPT_ParamCount 0x140241630,
// Set_XSCRIPT_Parameter 0x140241360, Send_XSCRIPT 0x1402411a0; bản ghi XParam đọc bằng 0x140768920 (số), 0x1407689a0 (chuỗi),
// 0x140768910 (đếm số), 0x140768990 (đếm chuỗi).
#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::ui::script {

inline constexpr std::size_t kXScriptNameLimit = 63;
inline constexpr std::size_t kXScriptParams = 14;
// Trần hàng đợi ra: một script lặp vô hạn trong trần lệnh vẫn gửi được hàng triệu bản ghi; quá trần thì bỏ bản mới và đếm.
inline constexpr std::size_t kXScriptOutboxLimit = 1024;

// Bản ghi XSCRIPT, đúng các trường của 128 byte trong gói (id 4 byte, độ dài tên 1, tên 63, một byte dành riêng, đếm tham số 1,
// hai byte đệm, 14 tham số 4 byte).
struct XScriptRecord {
    std::int32_t script_id = -1;
    std::uint8_t name_length = 0;
    std::array<char, kXScriptNameLimit> name{};
    std::uint8_t param_count = 0;
    std::array<std::int32_t, kXScriptParams> params{};

    [[nodiscard]] std::string_view function() const noexcept { return {name.data(), name_length}; }
    [[nodiscard]] friend bool operator==(const XScriptRecord&, const XScriptRecord&) = default;
};

class XScript {
public:
    // Về trạng thái trống: id -1, tên rỗng, đếm và mọi tham số 0.
    void clear() noexcept { record_ = XScriptRecord{}; }
    void set_script_id(std::int32_t id) noexcept { record_.script_id = id; }
    // Chép tối đa kXScriptNameLimit byte và dừng ở byte NUL đầu tiên (strncpy rồi strlen của gốc); phần dư của tên về 0.
    void set_function(std::string_view name) noexcept;
    // Gốc ép (char): chỉ 8 bit thấp.
    void set_param_count(std::int32_t count) noexcept { record_.param_count = static_cast<std::uint8_t>(count & 0xFF); }
    // slot ngoài [0, kXScriptParams) thì bỏ qua (không lỗi). Gốc lấy 8 bit thấp của chỉ số script đưa, nên 256 là ô 0.
    void set_param(std::uint8_t slot, std::int32_t value) noexcept;

    // Đóng bản ghi hiện tại vào hàng đợi ra; không đổi bản ghi hiện tại (script gọi Clear_XSCRIPT trước lần dùng kế).
    // Hàng đợi đầy thì bỏ bản này và tăng dropped().
    void send() noexcept;

    [[nodiscard]] const XScriptRecord& record() const noexcept { return record_; }
    // Lấy và xoá hàng đợi ra, theo thứ tự gửi.
    [[nodiscard]] std::vector<XScriptRecord> take_sent() noexcept { return std::exchange(sent_, {}); }
    [[nodiscard]] std::size_t pending() const noexcept { return sent_.size(); }
    [[nodiscard]] std::size_t dropped() const noexcept { return dropped_; }

private:
    XScriptRecord record_;
    std::vector<XScriptRecord> sent_;
    std::size_t dropped_ = 0;
};

inline constexpr std::size_t kXParamSlots = 16;

// Bản ghi tham số mà máy chủ gắn vào một sự kiện: tối đa 16 số và 16 chuỗi.
struct XParamRecord {
    std::array<std::int32_t, kXParamSlots> ints{};
    std::uint8_t int_count = 0;
    std::array<std::string, kXParamSlots> strings{};
    std::uint8_t string_count = 0;

    // Chỉ số ngoài [0, đếm) cho 0 (số) hay chuỗi rỗng, như gốc (con trỏ rỗng thành chuỗi rỗng ở lớp Lua).
    [[nodiscard]] std::int32_t int_at(std::int32_t index) const noexcept;
    [[nodiscard]] std::string_view string_at(std::int32_t index) const noexcept;
};

} // namespace game::ui::script
