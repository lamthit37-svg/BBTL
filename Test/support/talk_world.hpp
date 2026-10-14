// Thế giới hội thoại nhỏ dùng chung cho test của talk và handlers: một NPC (script 7000) đứng cạnh trưởng làng của mission_world,
// có lời chào theo cấp, trả tiền, quà thất bại (sổ cái từ chối), dịch chuyển, và các khối hỏng để thử trần bước.
#pragma once

#include "ops/ops.hpp"
#include "support/mission_world.hpp"
#include "support/talk_data.hpp"

#include <cstdint>
#include <string>

namespace game::test::talkw {

inline constexpr std::uint32_t kNpcScript = 7000;
// NPC có hộp thoại gốc là chuỗi 100 câu if liên tiếp (mẫu mà bộ trích sinh cho script gốc dài): độ sâu ngăn xếp không được tăng theo chuỗi.
inline constexpr std::uint32_t kChainScript = 7002;
inline constexpr int kChainLinks = 100;
inline constexpr std::int32_t kNpcGuid = world::kElder;

// Khoá chuỗi và mã chuỗi ghi sẵn ở đây để test nhìn thấy đúng thứ gửi qua dây.
inline std::uint32_t id(const char* key) { return ops::string_id(key); }

// Số điểm vào (num) của script 7000.
inline constexpr int kPay = 1;
inline constexpr int kGift = 2;
inline constexpr int kTravel = 3;
inline constexpr int kVeteran = 10;
inline constexpr int kShown = 5;
inline constexpr int kLoop = 90;
inline constexpr int kDeep = 91;
inline constexpr int kFlood = 92;
inline constexpr int kReturned = 6;
inline constexpr int kHand = 40;
inline constexpr int kHandRefused = 41;

// Mã bộ điều kiện / hiệu ứng thêm vào (mission_world dùng 1..3 và 1..4).
inline constexpr int kCondVeteran = 4;
inline constexpr int kCondGreeter = 5;
inline constexpr int kEffPay = 5;
inline constexpr int kEffBadGift = 6;
inline constexpr int kEffTravel = 7;
inline constexpr int kEffGem = 8;

inline void fill(TalkData& data) {
    world::fill(data);
    data.cond(kCondVeteran, 0, 0, "level_at_least", 0, 10);
    data.cond(kCondGreeter, 0, 0, "target_name", 0, 0, 0, 0, "老人");
    data.effect(kEffPay, 0, "give_money", 100, 0);
    data.effect(kEffPay, 1, "notify", 0, 0, 0, "lua.paid", "player");
    data.effect(kEffBadGift, 0, "give_exp", 10);
    data.effect(kEffBadGift, 1, "take_item", 9999, 1);  // túi không có: cả bộ bị từ chối
    data.effect(kEffTravel, 0, "teleport", 7, 100, 200);
    data.effect(kEffGem, 0, "give_item", 4002, 1, 0);

    data.npc_script(kNpcScript);
    // Gốc: lời chào, lựa chọn riêng của cấp 10, năm lựa chọn thường, mời một nhiệm vụ script.
    data.begin(1).text(1, "lua.hello", "player").branch(1, kCondVeteran, 2);
    data.option(1, kNpcScript, 2, kPay, "lua.pay").option(1, kNpcScript, 2, kGift, "lua.gift");
    data.option(1, kNpcScript, 2, kTravel, "lua.travel").option(1, kNpcScript, 3, kShown, "lua.shown_option");
    data.option(1, world::kKillScript, 4, -1, "lua.quest").option(1, kNpcScript, 5, kLoop, "lua.loop");
    data.option(1, kNpcScript, 5, kDeep, "lua.deep").option(1, kNpcScript, 5, kFlood, "lua.flood");
    // Hai điểm vào chưa trích được: test gắn handler viết tay (không có handler thì không có hội thoại).
    data.option(1, kNpcScript, 6, kHand, "lua.hand").option(1, kNpcScript, 6, kHandRefused, "lua.hand_refused").dispatch(1, "list");
    data.option(2, kNpcScript, 6, kVeteran, "lua.vet");
    data.entry(kNpcScript, -1, 1);

    data.begin(3).text(3, "lua.paying").effects(3, kEffPay).dispatch(3, "list");
    data.entry(kNpcScript, kPay, 3);
    data.begin(4).text(4, "lua.gifting").effects(4, kEffBadGift).dispatch(4, "list");
    data.entry(kNpcScript, kGift, 4);
    data.begin(5).text(5, "lua.travelling").effects(5, kEffTravel).dispatch(5, "list");
    data.entry(kNpcScript, kTravel, 5);
    data.begin(6).text(6, "lua.vet_text").dispatch(6, "list");
    data.entry(kNpcScript, kVeteran, 6);
    // Điểm vào có hiệu ứng ngay khi hiển thị: tính lại để kiểm lựa chọn KHÔNG được áp hiệu ứng lần hai.
    data.begin(7).effects(7, kEffGem).text(7, "lua.shown").option(7, kNpcScript, 1, kReturned, "lua.next").dispatch(7, "list");
    data.entry(kNpcScript, kShown, 7);
    data.begin(8).text(8, "lua.back").dispatch(8, "list");
    data.entry(kNpcScript, kReturned, 8);
    // Nhiệm vụ script: bảng mô tả + phần thưởng.
    data.begin(9).text(9, "lua.kill_desc").bonus(9, "money", 50).bonus(9, "item", 4001, 2).dispatch(9, "mission_info");
    data.entry(world::kKillScript, -1, 9);
    // Khối hỏng: vòng lặp, đệ quy sâu, tràn dòng chữ.
    data.jump(20, 20);
    data.entry(kNpcScript, kLoop, 20);
    data.call(21, 21);
    data.entry(kNpcScript, kDeep, 21);
    for (int line = 0; line < 70; ++line) data.text(22, "lua.line");
    data.entry(kNpcScript, kFlood, 22);
    // Chuỗi nhánh liên tiếp: khối 100+2i là `if` (hai nhánh cùng vào khối lẻ), khối lẻ nhảy sang câu if kế; khối cuối mới có chữ.
    data.npc_script(kChainScript);
    for (int link = 0; link < kChainLinks; ++link) {
        const int head = 100 + 2 * link;
        data.branch(head, kCondVeteran, head + 1, head + 1);
        data.jump(head + 1, head + 2);
    }
    data.begin(100 + 2 * kChainLinks).text(100 + 2 * kChainLinks, "lua.chain_end").dispatch(100 + 2 * kChainLinks, "list");
    data.entry(kChainScript, -1, 100);
    // Hai trạng thái không chạy được: kèm lý do.
    data.entry(kNpcScript, kHand, 0, "unsupported", "API LuaFnGetCopySceneData_Param");
    data.entry(kNpcScript, kHandRefused, 0, "no_dialog");
}

}  // namespace game::test::talkw
