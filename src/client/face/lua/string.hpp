// Chuỗi của Lua và bảng chuỗi (lstring.c của Lua 5.0.1): mọi chuỗi được intern, nên hai chuỗi cùng nội dung là một
// đối tượng và so bằng chuỗi là so địa chỉ (raw_equal, khoá bảng).
//
// Port từ lstring.c. Khác gốc:
// - Bảng intern băm bằng FNV-1a 64 bit trên TOÀN BỘ byte, không dùng hàm băm của Lua: hàm của Lua chỉ lấy tối đa 32
//   byte mẫu của chuỗi dài nên chuỗi do kẻ khác chọn có thể cùng băm và biến bảng intern thành danh sách dài. Hàm băm
//   của Lua (string_hash) vẫn tính và lưu, vì thứ tự duyệt bảng phụ thuộc vào nó.
// - Chuỗi không còn chuỗi chốt (luaS_fix) và không có udata: tên metamethod được State giữ bằng gốc thu gom rác.
// - Chuỗi không có byte 0 cuối: độ dài lưu riêng, chuỗi có thể chứa byte 0.
#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

namespace game::lua {

// Hàm băm của luaS_newlstr: hạt giống là độ dài (cắt xuống 32 bit), lấy mẫu mỗi (độ dài / 32 + 1) byte từ cuối. Thứ tự
// pairs của bảng có khoá chuỗi phụ thuộc giá trị này, nên khớp từng bit với gốc.
[[nodiscard]] std::uint32_t string_hash(std::string_view bytes) noexcept;

class String {
public:
    // Chỉ StringTable tạo chuỗi (hàm dựng public để std::make_unique gọi được).
    String(std::string_view bytes, std::uint32_t lua_hash, std::uint64_t table_hash);
    ~String() = default;
    String(const String&) = delete;
    String(String&&) = delete;
    String& operator=(const String&) = delete;
    String& operator=(String&&) = delete;

    [[nodiscard]] std::string_view view() const noexcept { return text_; }
    [[nodiscard]] std::size_t size() const noexcept { return text_.size(); }
    [[nodiscard]] std::uint32_t hash() const noexcept { return lua_hash_; }
    // Byte tính vào trần heap của State.
    [[nodiscard]] std::size_t footprint() const noexcept { return sizeof(String) + text_.size() + 1; }

    // Dấu của thu gom rác; chỉ State đặt và xoá.
    [[nodiscard]] bool marked() const noexcept { return marked_; }
    void set_marked(bool value) noexcept { marked_ = value; }

private:
    friend class StringTable;

    std::string text_;
    std::uint64_t table_hash_;
    std::uint32_t lua_hash_;
    bool marked_ = false;
    // Chuỗi kế trong cùng ngăn của bảng intern.
    String* chain_ = nullptr;
};

class StringTable {
public:
    StringTable();
    ~StringTable() = default;
    StringTable(const StringTable&) = delete;
    StringTable(StringTable&&) = delete;
    StringTable& operator=(const StringTable&) = delete;
    StringTable& operator=(StringTable&&) = delete;

    struct Interned {
        String* string;
        bool created;
    };
    // Chuỗi mang đúng bytes: có sẵn thì trả nó, chưa có thì tạo. Thời gian O(độ dài) kỳ vọng.
    [[nodiscard]] Interned intern(std::string_view bytes);

    [[nodiscard]] std::size_t count() const noexcept { return owned_.size(); }
    // Tổng footprint của mọi chuỗi đang giữ.
    [[nodiscard]] std::size_t bytes() const noexcept { return bytes_; }

    // Thu gom rác: giải phóng chuỗi chưa đánh dấu, bỏ dấu của chuỗi còn lại; trả số byte đã giải phóng.
    std::size_t sweep();

private:
    void grow();

    std::vector<std::unique_ptr<String>> owned_;
    // Đầu danh sách của từng ngăn; số ngăn luôn là luỹ thừa của hai.
    std::vector<String*> buckets_;
    std::size_t bytes_ = 0;
};

} // namespace game::lua
