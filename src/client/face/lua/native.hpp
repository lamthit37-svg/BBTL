// Hàm native viết bằng C++ cho script (quy ước của Lua C API, như Game.exe): `int(lua_State*)` đọc đối số từ ngăn xếp, đẩy kết quả
// lên ngăn xếp và trả số kết quả.
//
// Quy tắc an toàn, vì LuaPlus báo lỗi bằng longjmp (lua/capi.hpp): lời gọi API nào cũng có thể nhảy khỏi hàm native mà không chạy
// destructor nào (hết trần bộ nhớ của lua::State làm lua_pushstring, lua_newtable... nhảy; luaL_check*, lua_error nhảy có chủ ý).
//   1. Thân native viết theo dạng `NativeResult body(lua_State*)` và đăng ký bằng `adapt<body>`.
//   2. Trong thân, các biến sống qua một lời gọi API phải có destructor tầm thường: số, con trỏ, `std::string_view` vào chuỗi do
//      Lua giữ (còn hợp lệ khi giá trị còn trên ngăn xếp). Không `std::string`, `std::vector`, `std::unique_ptr` sống qua lời gọi
//      API; cần thì dùng trong khối đóng lại trước lời gọi API kế tiếp (hoặc đọc đối số ra biến tầm thường trước, tính rồi mới đẩy).
//   3. Báo lỗi cho script bằng cách trả `std::unexpected(NativeError::of(...))`, không gọi lua_error/luaL_error trong thân.
//      `adapt` đẩy lời lỗi lên ngăn xếp rồi mới lua_error, ở chỗ không còn đối tượng nào có destructor trong khung.
//   4. Gọi lại script từ native chỉ bằng `lua::protected_call` (lua/state.hpp), không lua_call: lỗi của script quay về native thành
//      giá trị trả về, không nhảy qua khung C++ của native.
#pragma once

#include "lua/capi.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <string_view>
#include <type_traits>
#include <utility>

namespace game::lua {

// Lời lỗi của native, chứa trong bộ đệm cố định (cắt ở kCapacity byte) để NativeResult có destructor tầm thường: longjmp bỏ qua một
// NativeResult còn sống trong khung không làm rò gì.
class NativeError {
public:
    static constexpr std::size_t kCapacity = 255;

    [[nodiscard]] static NativeError of(std::string_view message) noexcept {
        NativeError error;
        error.length_ = static_cast<std::uint8_t>(std::min(message.size(), kCapacity));
        std::ranges::copy_n(message.begin(), error.length_, error.text_.begin());
        return error;
    }

    // format_to_n ghi vào bộ đệm cố định, không cấp phát; chỉ formatter của kiểu người dùng mới ném, khi đó noexcept đưa tới
    // terminate (chủ ý: ngoại lệ không được thoát qua khung C của LuaPlus).
    template <class... Args>
    // NOLINTNEXTLINE(bugprone-exception-escape)
    [[nodiscard]] static NativeError format(std::format_string<Args...> pattern, Args&&... args) noexcept {
        NativeError error;
        const std::format_to_n_result<char*> written = std::format_to_n(error.text_.data(), kCapacity, pattern, std::forward<Args>(args)...);
        error.length_ = static_cast<std::uint8_t>(std::min(static_cast<std::size_t>(written.size), kCapacity));
        return error;
    }

    [[nodiscard]] std::string_view message() const noexcept { return {text_.data(), length_}; }

private:
    NativeError() = default;

    std::array<char, kCapacity> text_{};
    std::uint8_t length_ = 0;
};

// Số giá trị native đã đẩy lên ngăn xếp (cũng là giá trị trả về của lua_CFunction), hoặc lỗi cho script.
using NativeResult = std::expected<int, NativeError>;

static_assert(std::is_trivially_destructible_v<NativeResult>, "NativeResult bị longjmp bỏ qua: không được có destructor");

// Chuyển thân native thành lua_CFunction. Lời lỗi được đẩy lên ngăn xếp rồi khối chứa NativeResult mới đóng, sau đó mới lua_error.
template <NativeResult (*Body)(lua_State*)>
[[nodiscard]] int adapt(lua_State* state) {
    {
        const NativeResult outcome = Body(state);
        if (outcome) return *outcome;
        const std::string_view message = outcome.error().message();
        lua_pushlstring(state, message.data(), message.size());
    }
    return lua_error(state);
}

} // namespace game::lua
