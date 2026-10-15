// Hàm game của script giao diện (ui/script/natives): chạy đoạn Lua thật trên một máy LuaPlus trần có open_natives và đọc kết quả.
#include "ui/script/natives.hpp"

#include "test.hpp"

#include <array>
#include <string>
#include <string_view>
#include <utility>

extern "C" {
#include "lauxlib.h"
#include "lua.h"
}

namespace game::test {
namespace {

// Máy Lua trần với open_natives; đóng khi ra khỏi phạm vi.
class Machine {
public:
    Machine() : lua_(lua_open()) {
        if (lua_ != nullptr) ui::script::open_natives(lua_);
    }
    Machine(const Machine&) = delete;
    Machine& operator=(const Machine&) = delete;
    Machine(Machine&&) = delete;
    Machine& operator=(Machine&&) = delete;
    ~Machine() {
        if (lua_ != nullptr) lua_close(lua_);
    }

    [[nodiscard]] bool ok() const noexcept { return lua_ != nullptr; }

    // Chạy code (kết thúc bằng `return <biểu thức>`); trả giá trị đầu dưới dạng chuỗi, hay "LỖI: <thông điệp>" khi script lỗi.
    [[nodiscard]] std::string eval(std::string_view code) {
        const int base = lua_gettop(lua_);
        const int loaded = luaL_loadbuffer(lua_, code.data(), code.size(), "=thử");
        const int status = loaded == 0 ? lua_pcall(lua_, 0, 1, 0) : loaded;
        std::string text;
        if (status != 0) text = "LỖI: ";
        if (lua_isstring(lua_, -1) != 0) text += std::string(lua_tostring(lua_, -1), lua_strlen(lua_, -1));
        lua_settop(lua_, base);
        return text;
    }

private:
    lua_State* lua_;
};

void data_pool_colour_is_missing(Context& context) {
    Machine machine;
    context.expect(machine.ok(), "mở được máy Lua");
    if (!machine.ok()) return;
    context.expect(machine.eval("local font, extent = DataPool:GetUIColor(1000) return font .. '|' .. extent") == "-1|-1",
        "id không có trong SystemColour trả hai chuỗi -1");
    context.expect(machine.eval("local font = DataPool:GetUIColor(1) return font") == "-1", "chưa nạp bảng nên id nào cũng thiếu");
}

void data_pool_checks_string_code(Context& context) {
    Machine machine;
    if (!machine.ok()) return;
    // Escape thập phân của Lua: máy trần không có thư viện chuẩn (string.char). \228\189\160 là "你" (UTF-8 ba byte).
    constexpr std::array<std::pair<std::string_view, std::string_view>, 6> kCases = {{
        {"return DataPool:Check_StringCode('abc')", "1"},
        {"return DataPool:Check_StringCode('')", "1"},
        {R"(return DataPool:Check_StringCode('a\9b\10c\13'))", "1"},
        {R"(return DataPool:Check_StringCode('\1'))", "0"},
        {R"(return DataPool:Check_StringCode('\228\189'))", "0"},
        {R"(return DataPool:Check_StringCode('\228\189\160'))", "1"},
    }};
    for (const auto& [code, wanted] : kCases)
        context.expect(machine.eval(code) == wanted, code);
}

void data_pool_rejects_non_string(Context& context) {
    Machine machine;
    if (!machine.ok()) return;
    const std::string failed = machine.eval("return DataPool:Check_StringCode({})");
    context.expect(failed.starts_with("LỖI: ") && failed.contains("Check_StringCode"), "tham số không phải chuỗi là lỗi Lua, không chết");
    context.expect(machine.eval("return DataPool:Check_StringCode(5)") == "1", "số đổi được thành chuỗi nên hợp lệ như lua_isstring");
}

constexpr std::array<Case, 3> kCases = {{
    {.name = "DataPool:GetUIColor chưa nạp bảng màu", .body = data_pool_colour_is_missing},
    {.name = "DataPool:Check_StringCode", .body = data_pool_checks_string_code},
    {.name = "Check_StringCode từ chối tham số sai kiểu", .body = data_pool_rejects_non_string},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
