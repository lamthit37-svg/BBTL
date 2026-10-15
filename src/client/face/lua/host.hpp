// Hướng chủ của runtime Lua: tạo máy, mở thư viện, nạp chunk đã dịch, gọi có bảo vệ, đăng ký hàm C++, thu gom rác.
// Hợp đồng giữa runtime (module lua) và chủ: bộ chạy đối soát thienlong_lua_mass, sau này chủ giao diện của client
// (lớp C của docs/giao-viec/LUA-GEN/THIET-KE.md). Mã sinh không dùng tệp này (xem vm.hpp).
//
// Một State chỉ được dùng trên một luồng tại một lúc. Mọi Value lấy từ State chỉ dùng được tới lần collect() kế tiếp,
// trừ khi nằm trong bảng toàn cục (gốc của thu gom rác).
#pragma once

#include "lua/vm.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <memory>
#include <string>
#include <string_view>

namespace game::lua {

// Trần của một State. Khác gốc: LuaPlus không có ba trần này; chúng giữ client không treo, không tràn ngăn xếp C (1 MB
// ở luồng chính của Windows) và không ăn hết bộ nhớ khi script lỗi.
struct Limits {
    // Độ sâu gọi lồng tối đa; vượt thì lỗi "stack overflow".
    std::uint32_t max_depth = 200;
    // Số lần quay vòng tối đa trong một lần gọi từ chủ (tick() của vm.hpp); vượt thì lỗi.
    std::uint64_t loop_budget = 100'000'000;
    // Byte heap tối đa; vượt thì lỗi "not enough memory".
    std::size_t heap_bytes = std::size_t{256} * 1024 * 1024;
};

// Lỗi của một lần chạy từ chủ: giá trị lỗi của Lua đổi thành chuỗi như lua_tostring (không phải chuỗi hay số thì
// "(error object is not a string)").
struct Failure {
    std::string message;
};

using Outcome = std::expected<Results, Failure>;

// Ngữ cảnh của chủ cho hàm C++ (__emit ghi vào vết của bộ chạy, hàm của game đọc trạng thái client...).
class Host {
public:
    Host() = default;
    Host(const Host&) = delete;
    Host& operator=(const Host&) = delete;
    Host(Host&&) = delete;
    Host& operator=(Host&&) = delete;
    virtual ~Host() = default;
};

struct StateDeleter {
    void operator()(State* state) const noexcept;
};
using StatePtr = std::unique_ptr<State, StateDeleter>;

[[nodiscard]] StatePtr new_state(const Limits& limits);

// Thư viện chuẩn đúng như máy của trọng tài (TOOLS/port/luagen/mass_oracle.py): base, string, table, math; chuỗi có bảng
// meta trỏ bảng string; __pow toàn cục là pow thật. Không os, io, debug.
void open_standard(State& state);

// Ngữ cảnh chủ mà hàm C++ đọc bằng host(); State không sở hữu nó, nó phải sống lâu hơn mọi lần gọi.
void set_host(State& state, Host* host) noexcept;
[[nodiscard]] Host* host(const State& state) noexcept;

// Chuỗi Lua mang đúng các byte (kể cả byte 0).
[[nodiscard]] Value intern(State& state, std::string_view bytes);
// Byte của một chuỗi Lua; string phải là chuỗi (lỗi lập trình nếu không). View sống tới lần collect() kế tiếp.
[[nodiscard]] std::string_view bytes_of(Value string);

// rawset/rawget trên bảng toàn cục, không qua bảng meta.
void put_global(State& state, std::string_view name, Value value);
[[nodiscard]] Value find_global(State& state, std::string_view name);

// Hàm C++ không upvalue; proto.body là hàm C++ nhận (State&, self, đối số). proto phải sống lâu hơn State.
[[nodiscard]] Value native(State& state, const Proto& proto);

// Nạp và chạy một chunk đã dịch (intern hằng chuỗi, tạo closure của main, gọi không đối số). chunk.main là nullptr
// (chunk lỗi cú pháp) là lỗi lập trình: chủ hỏi trước.
[[nodiscard]] Outcome run(State& state, const Chunk& chunk);
// Gọi callee có bảo vệ (như lua_pcall): lỗi thành Failure, cờ lỗi của State được xoá.
[[nodiscard]] Outcome protected_call(State& state, Value callee, Args args);

// Thu gom rác (mark-sweep). Chỉ gọi khi không có lời gọi nào đang chạy (lỗi lập trình nếu đang chạy).
void collect(State& state);

} // namespace game::lua
