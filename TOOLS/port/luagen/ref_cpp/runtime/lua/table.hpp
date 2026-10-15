// Bảng của Lua (ltable.c của Lua 5.0.1): phần mảng và phần băm xích kiểu Brent, để thứ tự duyệt bằng next/pairs khớp
// LuaPlus.dll ở mọi dãy chèn, xoá và đổi cỡ.
//
// Port từ ltable.c. Khác gốc:
// - Nút dùng chỉ số thay con trỏ (chuỗi xích, firstfree), vector thay mảng malloc.
// - Phần băm rỗng (lsizenode = 0) của gốc dùng một nút chung `dummynode`; ở đây là vector rỗng. Chèn khoá vào bảng như
//   vậy tạm dựng vector một nút rồi chạy đúng mã của gốc (nút đó đầy ngay nên rehash), kết quả giống gốc.
// - Khoá là bảng hay hàm băm theo số thứ tự tạo (serial) thay vì địa chỉ: địa chỉ không tất định giữa các lần chạy.
// - Không có cờ đệm vắng metamethod (flags): chỉ là bộ nhớ đệm, không đổi kết quả.
// - Lỗi (khoá nil, khoá NaN) trả qua Fault thay vì longjmp; cỡ vượt MAXBITS không thể xảy ra dưới trần heap của State
//   (xem check ở resize).
#pragma once

#include "lua/vm.hpp"

#include <cstddef>
#include <cstdint>
#include <span>
#include <vector>

namespace game::lua {

// Số thứ tự tạo của một hàm, để băm khoá là hàm (định nghĩa ở state.cpp).
[[nodiscard]] std::uint32_t function_serial(const Function& function) noexcept;

class Table {
public:
    // Số bit tối đa của cỡ mảng (2^24 phần tử) và của cỡ phần băm (MAXBITS của gốc).
    static constexpr std::int32_t kMaxBits = 24;

    struct Node {
        Value value;
        Value key;
        // Nút kế trong xích; -1 là hết xích.
        std::int32_t next = -1;
    };

    // luaH_new(narray, lnhash): mảng narray ô, phần băm 2^log2_nodes nút (0 là rỗng). Hai cỡ do State kiểm trần trước.
    // heap_bytes là bộ đếm byte của State; bảng cộng và trừ phần của nó.
    Table(std::uint32_t serial, std::size_t* heap_bytes, std::int32_t array_size, std::int32_t log2_nodes);
    ~Table();
    Table(const Table&) = delete;
    Table(Table&&) = delete;
    Table& operator=(const Table&) = delete;
    Table& operator=(Table&&) = delete;

    // luaH_get / luaH_getnum / luaH_getstr: ô giá trị của khoá, nullptr khi không có ô (gốc trả &luaO_nilobject). Ô có thể
    // chứa nil (khoá đã gán nil). Con trỏ chỉ dùng được tới lần ghi kế tiếp vào bảng.
    [[nodiscard]] const Value* find(Value key) const noexcept;
    [[nodiscard]] const Value* find_int(std::int32_t key) const noexcept;
    [[nodiscard]] const Value* find_string(const String& key) const noexcept;
    [[nodiscard]] Value get(Value key) const noexcept {
        const Value* const slot = find(key);
        return slot != nullptr ? *slot : Value();
    }
    [[nodiscard]] Value get_int(std::int32_t key) const noexcept {
        const Value* const slot = find_int(key);
        return slot != nullptr ? *slot : Value();
    }
    [[nodiscard]] Value get_string(const String& key) const noexcept {
        const Value* const slot = find_string(key);
        return slot != nullptr ? *slot : Value();
    }

    enum class Fault : std::uint8_t { kNone, kNilKey, kNanKey };
    struct Slot {
        Value* value = nullptr;
        Fault fault = Fault::kNone;
    };
    // luaH_set: ô của khoá, tạo khoá mới (giá trị nil) khi chưa có. Có thể rehash; con trỏ chỉ dùng ngay.
    [[nodiscard]] Slot set_slot(Value key);
    // luaH_setnum.
    [[nodiscard]] Value* set_slot_int(std::int32_t key);

    // luaH_next: phần tử kế sau key (nil là bắt đầu): mảng trước, rồi nút theo thứ tự chỉ số.
    enum class Step : std::uint8_t { kFound, kEnd, kBadKey };
    struct Advance {
        Step step = Step::kEnd;
        Value key;
        Value value;
    };
    [[nodiscard]] Advance next(Value key) const noexcept;

    [[nodiscard]] Table* metatable() const noexcept { return metatable_; }
    void set_metatable(Table* metatable) noexcept { metatable_ = metatable; }

    // Cỡ khai báo bằng table.setn (thay bảng `sizes` yếu trong sổ đăng ký của lauxlib.c); âm là chưa khai báo.
    [[nodiscard]] std::int32_t declared_size() const noexcept { return declared_size_; }
    void set_declared_size(std::int32_t size) noexcept { declared_size_ = size; }

    [[nodiscard]] std::uint32_t serial() const noexcept { return serial_; }
    [[nodiscard]] std::size_t array_size() const noexcept { return array_.size(); }
    [[nodiscard]] std::size_t node_count() const noexcept { return nodes_.size(); }
    // Duyệt con của thu gom rác.
    [[nodiscard]] std::span<const Value> array() const noexcept { return array_; }
    [[nodiscard]] std::span<const Node> nodes() const noexcept { return nodes_; }

    [[nodiscard]] bool marked() const noexcept { return marked_; }
    void set_marked(bool value) noexcept { marked_ = value; }

private:
    // Ba hàm tìm ô dùng chung cho bản const (find*) và bản ghi (set_slot, new_key); định nghĩa ở table.cpp.
    template <class Self>
    [[nodiscard]] static auto* locate(Self& self, Value key) noexcept;
    template <class Self>
    [[nodiscard]] static auto* locate_int(Self& self, std::int32_t key) noexcept;
    template <class Self>
    [[nodiscard]] static auto* locate_string(Self& self, const String& key) noexcept;
    [[nodiscard]] std::int32_t find_node(Value key) const noexcept;
    [[nodiscard]] std::size_t main_position(Value key) const noexcept;
    [[nodiscard]] Value* new_key(Value key);
    void rehash();
    void resize(std::int32_t new_array_size, std::int32_t new_log2_nodes);
    void set_node_vector(std::int32_t log2_nodes);
    void account();

    std::size_t* heap_bytes_;
    std::size_t accounted_ = 0;
    std::vector<Value> array_;
    std::vector<Node> nodes_;
    // Chỉ số nút trống cuối cùng còn có thể dùng (firstfree).
    std::size_t first_free_ = 0;
    Table* metatable_ = nullptr;
    std::int32_t declared_size_ = -1;
    std::uint32_t serial_;
    bool marked_ = false;
};

} // namespace game::lua
