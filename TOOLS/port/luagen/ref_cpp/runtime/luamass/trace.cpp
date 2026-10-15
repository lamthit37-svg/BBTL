#include "luamass/trace.hpp"

#include "core/check.hpp"
#include "lua/host.hpp"
#include "lua/vm.hpp"

#include <string>
#include <string_view>
#include <utility>

namespace game::luamass {
namespace {

// Vết đang ghi của một đơn vị; __emit đọc nó qua lua::host().
class Sink final : public lua::Host {
public:
    void line(std::string_view text) {
        bytes.append(text);
        bytes.push_back('\n');
    }

    std::string bytes;
};

// __emit(chuỗi): một dòng vết. Phía gốc đọc đối số bằng lua_tostring (nil thành chuỗi rỗng); world.lua chỉ đưa chuỗi,
// nên giá trị khác chuỗi ghi một dòng rỗng như nil ở phía gốc.
// NOLINTNEXTLINE(misc-const-correctness): chữ ký phải khớp lua::Body, chỉ đọc host() thôi (HP-07)
lua::Results emit(lua::State& state, const lua::Function& /*self*/, lua::Args args) {
    auto* const sink = dynamic_cast<Sink*>(lua::host(state));
    core::check(sink != nullptr, "__emit chạy trên State không có Sink");
    const bool is_text = !args.empty() && args.front().type() == lua::Type::kString;
    sink->line(is_text ? lua::bytes_of(args.front()) : std::string_view{});
    return {};
}

constexpr lua::Proto kEmit{.body = &emit, .name = "__emit"};

// Nạp một chunk như Run.chunk của mass_oracle.py: ghi load, rồi !syntax hay !err.
void load(lua::State& state, Sink& sink, const lua::Chunk& chunk) {
    sink.line(std::string("load\t").append(chunk.name));
    if (chunk.main == nullptr) {
        sink.line("!syntax");
        return;
    }
    if (!lua::run(state, chunk)) sink.line("!err");
}

} // namespace

std::string trace_unit(const UnitChunks& unit, const lua::Chunk& world) {
    Sink sink;
    const lua::StatePtr state = lua::new_state(lua::Limits{});
    lua::open_standard(*state);
    lua::set_host(*state, &sink);
    lua::put_global(*state, "__emit", lua::native(*state, kEmit));
    sink.line(std::string("unit\t").append(unit.name));
    load(*state, sink, world);
    for (const lua::Chunk& chunk : unit.chunks) load(*state, sink, chunk);
    sink.line("drive");
    // Phía gốc gọi __drive() trong một chunk không ghi gì, nên lỗi của chính bộ chạy (mỗi bước đã có pcall riêng) cũng
    // không thành dòng vết; ở đây cũng vậy, vết của hai phía vẫn so được từng byte.
    [[maybe_unused]] const lua::Outcome driven =
        lua::protected_call(*state, lua::find_global(*state, "__drive"), {});
    sink.line("end");
    lua::set_host(*state, nullptr);
    return std::move(sink.bytes);
}

} // namespace game::luamass
