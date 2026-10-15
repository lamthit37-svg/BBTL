// Vỏ C++ của LuaPlus 5.0.1 (third_party/luaplus), máy Lua của script giao diện client 2026. LuaPlus chạy đúng như LuaPlus.dll của
// client gốc (ctest lua_golden_tests, lua_oracle); vỏ này thêm những thứ máy gốc không có:
//   - State sở hữu một lua_State bằng RAII (move được, không chép được);
//   - trần bộ nhớ riêng của mỗi State, qua hàm cấp phát của LuaPlus (lua_openwithmemory): vượt trần là lỗi kMemory của lần gọi
//     đang chạy, State vẫn dùng tiếp được;
//   - trần số lệnh máy ảo cho một lần gọi ngoài cùng, bằng móc đếm lệnh: vòng lặp vô hạn của script (SafeCenter_SafeCheck là một
//     ví dụ thật) thành lỗi kInstructions thay vì treo client; không cách nào của script (pcall, coroutine) tránh được;
//   - trần độ sâu các lần gọi bảo vệ lồng nhau (native gọi lại script gọi lại native...);
//   - nạp chunk và gọi hàm trả std::expected kèm lời lỗi (lỗi chạy kèm traceback), không bao giờ nhảy qua khung C++ của người gọi.
//
// Luồng: một State dùng từng lúc một luồng (như lua_State). Trần chỉ tính trong các hàm của vỏ này; mã gọi thẳng lua_pcall/lua_call
// qua State::raw() tự chịu (không có móc cho lỗi lồng của nó, không traceback).
#pragma once

#include "lua/capi.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <memory>
#include <string>
#include <string_view>

namespace game::lua {

inline constexpr std::size_t kDefaultHeapBytes = std::size_t{128} * 1024 * 1024;
inline constexpr std::int32_t kDefaultInstructions = 20'000'000;
inline constexpr std::int32_t kDefaultDepth = 16;

// Trần của một State; State::open kiểm miền một lần, mọi trường phải dương.
struct Limits {
    // Tổng byte LuaPlus cấp phát cho State (kể cả bản thân state, chuỗi, bảng, hàm). Cấp phát làm vượt trần bị từ chối.
    std::size_t heap_bytes = kDefaultHeapBytes;
    // Số lệnh máy ảo tối đa cho một lần gọi ngoài cùng (lần gọi bảo vệ đầu tiên khi chưa có lần nào đang chạy); các lần gọi lồng
    // trong nó dùng chung ngân sách ấy. Đếm theo bước 1 000 lệnh (hoặc nhỏ hơn nếu trần nhỏ hơn): vượt trần tối đa một bước.
    std::int32_t instructions = kDefaultInstructions;
    // Số lần gọi bảo vệ lồng nhau tối đa. Thấp hơn LUA_MAXCCALLS (200) của LuaPlus nhiều lần, vì mỗi tầng tốn vài tầng C.
    std::int32_t depth = kDefaultDepth;
};

enum class [[nodiscard]] Fault : std::uint8_t {
    kInvalidLimits, // Limits có trường không dương
    kSyntax,        // chunk sai cú pháp, hoặc là chunk nhị phân (không nạp, vì bytecode của Lua 5.0 không được kiểm)
    kRuntime,       // lỗi lúc chạy (error(), phép toán sai kiểu, tràn ngăn xếp gọi...), kể cả lỗi trong bộ xử lý lỗi; lời lỗi kèm traceback
    kMemory,        // vượt Limits::heap_bytes (hoặc malloc thất bại)
    kInstructions,  // vượt Limits::instructions
    kDepth,         // vượt Limits::depth
};

[[nodiscard]] constexpr std::string_view to_string(Fault fault) noexcept {
    switch (fault) {
    case Fault::kInvalidLimits: return "invalid-limits";
    case Fault::kSyntax: return "syntax";
    case Fault::kRuntime: return "runtime";
    case Fault::kMemory: return "memory";
    case Fault::kInstructions: return "instructions";
    case Fault::kDepth: return "depth";
    }
    return "?";
}

struct Failure {
    Fault fault = Fault::kRuntime;
    std::string message;
};

// Trạng thái riêng của một State (trần, bộ đếm); định nghĩa trong state.cpp.
struct Machine;

class State {
public:
    // Dựng State với bốn thư viện chuẩn (base, string, table, math) như máy gốc; io, os, debug, loadlib không có. Chính sách bỏ bớt
    // hàm của base (dofile, loadfile, loadstring, require, print) là việc của nơi dùng. O(trần bộ nhớ) trong trường hợp xấu nhất.
    [[nodiscard]] static std::expected<State, Failure> open(const Limits& limits = {});

    ~State();
    State(State&& other) noexcept;
    State& operator=(State&& other) noexcept;
    State(const State&) = delete;
    State& operator=(const State&) = delete;

    // lua_State của luồng chính, cho mã dùng C API (đăng ký native, đẩy đối số). Hợp lệ tới khi State huỷ hay bị move đi.
    [[nodiscard]] lua_State* raw() const noexcept;

    // Gắn một con trỏ của nơi dùng (kho cửa sổ, bộ máy chủ...) với State; State không sở hữu nó. Hàm native lấy lại bằng host_of từ
    // lua_State bất kỳ của State này, kể cả coroutine (lua_getstateuserdata của LuaPlus chỉ có trên từng luồng riêng).
    void set_host(void* host) noexcept;

    // Byte LuaPlus đang giữ cho State này (luôn không vượt Limits::heap_bytes).
    [[nodiscard]] std::size_t heap_used() const noexcept;

    // Nạp chunk văn bản và đẩy hàm lên ngăn xếp. chunk_name là chuỗi kết thúc bằng 0 khác null, theo quy ước của LuaPlus: tên có
    // tiền tố '=' hiện nguyên văn trong lời lỗi ("=ProgressBar"), '@' là tên tệp. Chunk nhị phân (byte đầu 0x1B) bị từ chối.
    // Độ phức tạp: O(source.size()); trần của source là heap_bytes (cây cú pháp tính vào trần).
    [[nodiscard]] std::expected<void, Failure> load(std::string_view source, const char* chunk_name);

    // load rồi call(0, 0).
    [[nodiscard]] std::expected<void, Failure> run(std::string_view source, const char* chunk_name);

    // protected_call(raw(), arguments, results).
    [[nodiscard]] std::expected<void, Failure> call(int arguments, int results);

    // Đăng ký hàm native (lua/native.hpp: dùng adapt<body>) làm biến toàn cục name (chuỗi kết thúc bằng 0 khác null).
    [[nodiscard]] std::expected<void, Failure> set_global(const char* name, lua_CFunction function);

private:
    explicit State(std::unique_ptr<Machine> machine) noexcept;
    void close() noexcept;

    std::unique_ptr<Machine> machine_;
};

// Gọi hàm Lua có bảo vệ, mang trần của State đã dựng ra `state` (State::open; state có thể là luồng chính hoặc coroutine của nó).
// Như lua_pcall: ngăn xếp có hàm rồi `arguments` đối số trên cùng. Thành công thì hàm và đối số được thay bằng `results` kết quả
// (LUA_MULTRET được). Thất bại thì hàm và đối số bị gỡ, không đẩy gì, lời lỗi nằm trong Failure. Cần ít nhất 2 ô trống trên ngăn
// xếp (LuaPlus bảo đảm LUA_MINSTACK ô khi vào hàm native). Dùng được từ trong hàm native để gọi lại script (lua/native.hpp).
[[nodiscard]] std::expected<void, Failure> protected_call(lua_State* state, int arguments, int results);

// Thân C++ chạy trong vùng bảo vệ. Quy tắc như hàm native (lua/native.hpp): mọi lời gọi API Lua trong thân có thể nhảy.
using ProtectedBody = void (*)(lua_State* state, void* data);

// Chạy body(state, data) trong vùng bảo vệ như protected_call: lỗi Lua nhảy trong thân (lua_error, luaL_error, hết bộ nhớ, trần lệnh)
// thành Failure kèm traceback, trần lệnh và độ sâu tính như mọi lần gọi bảo vệ. Khác lua_cpcall ở chỗ không tạo closure mới cho mỗi lần gọi (hàm chạy thân
// neo sẵn trong registry từ lúc State::open); ngăn xếp trước và sau cùng cỡ, thân phải tự cân bằng nó. Cần 2 ô trống như protected_call.
[[nodiscard]] std::expected<void, Failure> protect(lua_State* state, ProtectedBody body, void* data);

// Con trỏ do State::set_host gắn (nullptr nếu chưa gắn). O(1), không cấp phát; lua_State phải do lua::State::open dựng.
[[nodiscard]] void* host_of(lua_State* state) noexcept;

} // namespace game::lua
