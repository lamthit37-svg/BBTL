// Máy Lua của vỏ lua::State với hàm game của script giao diện (open_natives) và một Context của test, để chạy đoạn Lua thật rồi đọc
// kết quả. Dùng chung cho các test của ui/script/native_*.
#pragma once

#include "lua/capi.hpp"
#include "lua/state.hpp"
#include "ui/script/context.hpp"
#include "ui/script/native_support.hpp"
#include "ui/script/natives.hpp"

#include <expected>
#include <string>
#include <string_view>

namespace game::test {

class ScriptRig {
public:
    explicit ScriptRig(ui::script::Context& script) : state_(lua::State::open()) {
        if (!state_) return;
        const auto registered = lua::protect(
            state_->raw(),
            [](lua_State* lua, void* data) {
                ui::script::open_natives(lua);
                ui::script::native::attach(lua, *static_cast<ui::script::Context*>(data));
            },
            &script);
        if (!registered) state_ = std::unexpected(registered.error());
    }

    [[nodiscard]] bool ok() const noexcept { return state_.has_value(); }

    // Chạy code (kết thúc bằng `return <biểu thức>`) và trả giá trị đầu dưới dạng chuỗi, hay "LỖI: <thông điệp>". Code không trả gì
    // thì chuỗi rỗng.
    [[nodiscard]] std::string eval(std::string_view code) {
        auto loaded = state_->load(code, "=thử");
        if (loaded) loaded = state_->call(0, 1);
        if (!loaded) return "LỖI: " + loaded.error().message;
        lua_State* const lua = state_->raw();
        std::string text;
        if (lua_isstring(lua, -1) != 0) text.assign(lua_tostring(lua, -1), lua_strlen(lua, -1));
        lua_settop(lua, 0);
        return text;
    }

private:
    std::expected<lua::State, lua::Failure> state_;
};

} // namespace game::test
