// Hàm game chỉ đọc trường số của CDataPool (native_pool.cpp, sinh): giá trị đầu theo hàm dựng của gốc, ghi đè theo offset, cắt theo
// độ rộng của lần đọc, trần số trường ghi đè.
#include "support/script_rig.hpp"
#include "ui/script/context.hpp"
#include "ui/script/pool_image.hpp"

#include "test.hpp"

#include <array>
#include <cstdint>

namespace game::test {
namespace {

void initial_values_follow_the_constructor(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    // Hàm dựng CDataPool đặt thời gian hoà bình và cờ "bạch binh" về -1, các trường khác 0.
    context.expect(rig.eval("return Player:GetTimeToPeace()") == "-1", "GetTimeToPeace đầu là -1");
    context.expect(rig.eval("return DataPool:GetIsBaiBing()") == "-1", "GetIsBaiBing đầu là -1");
    context.expect(rig.eval("return DataPool:GetImMsgNumber()") == "0", "GetImMsgNumber đầu là 0");
    context.expect(rig.eval("local a, b = GetHuoYueShopDaiBiInfo() return a .. '|' .. b") == "0|0", "hàm đọc hai trường trả hai số");
}

void written_fields_override_and_narrow(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(script.facts.pool.write(0x5c0cf4, 42), "ghi trường thời gian hoà bình");
    context.expect(rig.eval("return Player:GetTimeToPeace()") == "42", "giá trị ghi đè thắng giá trị của hàm dựng");
    // Raid:GetApplicantCount đọc ushort ở 0x5ddc90, Guild:GetMyPosition đọc byte ở 0x5ac390.
    static_cast<void>(script.facts.pool.write(0x5ddc90, 100000));
    context.expect(rig.eval("return Raid:GetApplicantCount()") == "34464", "ushort cắt 100000 còn 34464 (không dấu)");
    static_cast<void>(script.facts.pool.write(0x5ac390, 456));
    context.expect(rig.eval("return Guild:GetMyPosition()") == "200", "byte cắt 456 còn 200 (không dấu)");
    static_cast<void>(script.facts.pool.write(0x5d6e58, -5));
    context.expect(rig.eval("return DataPool:GetImMsgNumber()") == "-5", "int giữ dấu");
    static_cast<void>(script.facts.pool.write(0x676500, 3));
    static_cast<void>(script.facts.pool.write(0x676504, 9));
    context.expect(rig.eval("local a, b = GetHuoYueShopDaiBiInfo() return a .. '|' .. b") == "3|9", "mỗi lần đẩy đọc trường của nó");
}

void override_table_is_bounded(Context& context) {
    ui::script::PoolImage image;
    bool accepted = true;
    for (std::uint32_t index = 0; index < ui::script::PoolImage::kLimit; ++index) accepted = image.write(index * 4, 1) && accepted;
    context.expect(accepted, "chưa quá trần thì mọi lần ghi được nhận");
    context.expect(!image.write(0xFFFF0, 1), "trường mới vượt trần thì bị từ chối");
    context.expect(image.write(4, 7), "ghi lại trường đã có vẫn được khi đầy");
    const std::array<ui::script::PoolInitial, 1> initial = {{{.offset = 0xFFFF0, .width = ui::script::Width::kI32, .value = -1}}};
    context.expect(image.read({.offset = 0xFFFF0, .width = ui::script::Width::kI32}, initial) == -1, "trường bị từ chối vẫn có giá trị đầu");
    context.expect(image.read({.offset = 0xFFFF0, .width = ui::script::Width::kU32}, initial) == 0, "độ rộng khác thì không khớp dòng đầu");
    context.expect(image.read({.offset = 4, .width = ui::script::Width::kI32}, initial) == 7, "giá trị ghi lại");
}

constexpr std::array<Case, 3> kCases = {{
    {.name = "giá trị đầu theo hàm dựng", .body = initial_values_follow_the_constructor},
    {.name = "ghi đè và cắt theo độ rộng", .body = written_fields_override_and_narrow},
    {.name = "trần số trường ghi đè", .body = override_table_is_bounded},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
