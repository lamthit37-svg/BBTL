// Phần dùng chung của thư viện chuẩn (base, string, table, math): đọc đối số hàm C++ như lauxlib.c (luaL_check*,
// luaL_opt*, luaL_argerror) và đăng ký hàm vào bảng như luaL_openlib. Nội bộ module lua.
#pragma once

#include "lua/state.hpp"
#include "lua/vm.hpp"

#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>

namespace game::lua {

void open_base(State& state);
void open_string(State& state);
void open_table(State& state);
void open_math(State& state);

// luaL_openlib: đăng ký từng Proto vào bảng under, khoá là proto.name, theo thứ tự (thứ tự chèn quyết định thứ tự duyệt).
void register_functions(State& state, Table& into, std::span<const Proto> protos);
// Tạo bảng thư viện mới (lua_newtable), đăng ký vào bảng toàn cục dưới tên name, rồi đổ protos vào (luaL_openlib với tên).
[[nodiscard]] Table* open_library(State& state, std::string_view name, std::span<const Proto> protos);

// luaL_getn / luaL_setn của lauxlib.c: `n` của bảng nếu là số, không thì cỡ khai báo bằng table.setn, không thì đếm tới nil
// đầu tiên. Khác gốc: cỡ khai báo nằm trong Table (declared_size) thay vì bảng `sizes` yếu trong sổ đăng ký.
[[nodiscard]] std::int32_t table_length(State& state, const Table& table);
void set_table_length(State& state, Table& table, std::int32_t length);

// luaL_callmeta / luaB_tostring: chuỗi của một giá trị theo __tostring rồi theo kiểu. Hàm tạo lỗi trả nil (State đã ghi).
[[nodiscard]] Value to_display_string(State& state, Value value);

// lua_rawgeti / lua_rawseti. Chỉ số int64 để vòng lặp theo cỡ khai báo (tới 2^31 - 1) không tràn; ngoài miền int32 thì
// khoá là số thực như mọi khoá số khác. raw_set_int kiểm trần heap trước khi ghi và trả false (đã ghi lỗi) khi hết.
[[nodiscard]] Value raw_get_int(const Table& table, std::int64_t key) noexcept;
[[nodiscard]] bool raw_set_int(State& state, Table& table, std::int64_t key, Value value);

// luaL_Buffer: gom kết quả chuỗi của một hàm thư viện. Trần là phần heap còn lại lúc dựng; vượt thì ghi lỗi "not enough
// memory" vào State và mọi lần thêm sau đó không làm gì (hàm gọi hỏi failed() một lần ở cuối vòng, finish() trả nil khi lỗi).
class Buffer {
public:
    explicit Buffer(State& state);
    void add(std::string_view piece);
    void add(char letter, std::size_t count = 1);
    [[nodiscard]] std::size_t size() const noexcept { return text_.size(); }
    // luaL_pushresult: chuỗi Lua của mọi thứ đã thêm.
    [[nodiscard]] Value finish();

private:
    [[nodiscard]] bool room(std::size_t extra);

    State* state_;
    std::string text_;
    std::size_t cap_;
};

// Phép cộng int của C với kết quả quấn vòng (máy x86 của DLL), thay cho tràn số có dấu.
[[nodiscard]] constexpr std::int32_t wrapping_add(std::int32_t left, std::int32_t right) noexcept {
    return static_cast<std::int32_t>(static_cast<std::uint32_t>(left) + static_cast<std::uint32_t>(right));
}

// Đọc đối số của hàm C++ theo lauxlib. Sai kiểu thì ghi lỗi "bad argument #n to `tên' (...)" vào State và trả giá trị
// mặc định; hàm gọi hỏi failed() trước khi làm việc có tác dụng phụ (State::invoke bỏ kết quả khi lỗi). Chỉ số đếm từ 0.
class Arguments {
public:
    Arguments(State& state, const Function& self, Args args) noexcept : state_(&state), self_(&self), args_(args) {}

    [[nodiscard]] State& state() const noexcept { return *state_; }
    [[nodiscard]] Args all() const noexcept { return args_; }
    [[nodiscard]] std::size_t count() const noexcept { return args_.size(); }
    // lua_isnone: đối số có mặt (kể cả nil).
    [[nodiscard]] bool present(std::size_t index) const noexcept { return index < args_.size(); }
    [[nodiscard]] bool failed() const noexcept { return state_->failed(); }
    // Đối số thứ index, nil khi thiếu.
    [[nodiscard]] Value at(std::size_t index) const noexcept { return index < args_.size() ? args_[index] : Value(); }
    // lua_isnoneornil.
    [[nodiscard]] bool missing(std::size_t index) const noexcept { return at(index).is_nil(); }

    // luaL_checknumber: số hoặc chuỗi ép được sang số.
    [[nodiscard]] double number(std::size_t index);
    [[nodiscard]] double opt_number(std::size_t index, double fallback);
    // luaL_checkint: (int) của số, cắt phần lẻ.
    [[nodiscard]] std::int32_t integer(std::size_t index);
    [[nodiscard]] std::int32_t opt_integer(std::size_t index, std::int32_t fallback);
    // luaL_checklstring: chuỗi hoặc số (đổi sang chuỗi). View sống tới lần collect() kế tiếp.
    [[nodiscard]] std::string_view text(std::size_t index);
    [[nodiscard]] std::string_view opt_text(std::size_t index, std::string_view fallback);
    // luaL_checktype(.., LUA_TTABLE): bảng, hoặc nullptr khi lỗi.
    [[nodiscard]] Table* table(std::size_t index);
    // luaL_checkany: đối số phải có mặt.
    void any(std::size_t index);

    // luaL_argerror / luaL_typerror.
    void argument_error(std::size_t index, std::string_view detail);
    void type_error(std::size_t index, std::string_view expected);

private:
    State* state_;
    const Function* self_;
    Args args_;
};

} // namespace game::lua
