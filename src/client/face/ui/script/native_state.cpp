// Hàm game nhỏ của script giao diện đọc trạng thái hay nhờ game một việc, port từ Game.exe 2026: giờ thế giới, tính hợp lệ của người chơi,
// cấp tối đa, tỉ lệ kinh nghiệm, chấm đỏ, lớp hướng dẫn tân thủ, trang thanh menu, xin giờ máy chủ, và những hàm "xoá/đặt" mà thứ chúng
// đụng tới (hộp thanh toán trang phục, điểm trận, chuột mặc định) client này chưa có nên không làm gì. Từng hàm ghi địa chỉ và Khác gốc.
#include "hero/hero.hpp"
#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "ui/panel/call.hpp"
#include "ui/script/context.hpp"
#include "ui/script/native_groups.hpp"
#include "ui/script/native_support.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::ui::script {
namespace {

using lua::NativeError;
using lua::NativeResult;

// GetCurrentTime() (0x140234650): số nguyên (atoi) của biến "WorldTime"; chưa đặt thì 0.
NativeResult get_current_time(lua_State* lua) {
    lua_pushnumber(lua, native::context_of(lua).variables.get_int("WorldTime"));
    return 1;
}

// Player:IsVaild() (0x1403966f0): 1 khi đang trong game và đã có người chơi, còn lại 0.
NativeResult player_is_valid(lua_State* lua) {
    lua_pushnumber(lua, native::context_of(lua).facts.hero != nullptr ? 1 : 0);
    return 1;
}

// Player:GetDefineHumanMaxLevel() (0x14039ac30) và ...Sub() (0x14039ac70): hằng 129 và 119 của gốc.
NativeResult player_max_level(lua_State* lua) {
    lua_pushnumber(lua, 129);
    return 1;
}

NativeResult player_max_level_sub(lua_State* lua) {
    lua_pushnumber(lua, 119);
    return 1;
}

// Player:GetHumanExpRatioToNeedExp() (0x140396140): ((kinh nghiệm * 100) / kinh nghiệm cần) / 100,0, chia số nguyên 64 bit cắt về 0.
// Chưa có người chơi thì 0. Khác gốc: cần bằng 0 thì gốc chia cho 0 (lỗi phần cứng), ở đây trả 0; kinh nghiệm kẹp trong
// 0..INT64_MAX/100 để phép nhân không tràn.
NativeResult player_exp_ratio(lua_State* lua) {
    const hero::Hero* const who = native::context_of(lua).facts.hero;
    double ratio = 0;
    if (who != nullptr && who->experience.top > 0) {
        constexpr std::int64_t kMostExperience = std::numeric_limits<std::int64_t>::max() / 100;
        const std::int64_t have = std::clamp<std::int64_t>(who->experience.now, 0, kMostExperience);
        const std::int64_t percent = (have * 100) / who->experience.top;
        ratio = static_cast<double>(percent) / 100.0;
    }
    lua_pushnumber(lua, ratio);
    return 1;
}

// GameProduceLogin:IsWeGameClient() (0x14033f7f0) và IsWeGameServer() (0x14033f950): byte toàn cục do tham số khởi động đặt.
NativeResult is_we_game_client(lua_State* lua) {
    lua_pushnumber(lua, native::context_of(lua).facts.we_game_client);
    return 1;
}

NativeResult is_we_game_server(lua_State* lua) {
    lua_pushnumber(lua, native::context_of(lua).facts.we_game_server);
    return 1;
}

// DataPool:Lua_IsRedPointInUIShow(chỉ số) (0x14028c900): cờ chấm đỏ thứ chỉ số (0..42), ngoài miền (so sánh không dấu) thì 0.
// Đối số 2 không phải số nghiêm thì ném câu của gốc.
NativeResult is_red_point_in_ui_show(lua_State* lua) {
    const std::optional<double> given = native::strict_number(lua, 2);
    if (!given) return std::unexpected(NativeError::of("Lua_IsRedPointInUIShow parameter error!"));
    const auto& flags = native::context_of(lua).facts.red_points;
    const auto slot = static_cast<std::size_t>(static_cast<std::uint32_t>(native::to_int(*given)));
    lua_pushnumber(lua, slot < flags.size() ? flags.at(slot) : 0);
    return 1;
}

// GetFreshManGuideOwner() (0x1402621b0): chủ lớp hướng dẫn tân thủ đang mở, rỗng khi không có.
NativeResult get_fresh_man_guide_owner(lua_State* lua) {
    const std::string& owner = native::context_of(lua).guide_owner;
    lua_pushlstring(lua, owner.data(), owner.size());
    return 1;
}

// CloseFreshManGuide() (0x140262120): đóng lớp hướng dẫn (Ask::kCloseFreshManGuide) rồi xoá chủ của nó.
NativeResult close_fresh_man_guide(lua_State* lua) {
    Context& context = native::context_of(lua);
    context.push_call(panel::Ask::kCloseFreshManGuide, {});
    context.guide_owner.clear();
    return 0;
}

// Câu ném của OpenFreshManGuideNew cho đối số số nghiêm đầu tiên bị sai trong năm đối số đầu; nullptr khi đủ.
const char* first_wrong_guide_argument(lua_State* lua) {
    static constexpr std::array<const char*, 5> kWrong = {"LUA: OpenFreshManGuide Wrong Param1", "LUA: OpenFreshManGuide Wrong Param2",
        "LUA: OpenFreshManGuide Wrong Param3", "LUA: OpenFreshManGuide Wrong Param4", "LUA: OpenFreshManGuide Wrong Param5"};
    for (int index = 1; index <= 5; ++index) {
        if (!native::strict_number(lua, index)) return kWrong.at(static_cast<std::size_t>(index - 1));
    }
    return nullptr;
}

// Lấy `count` đối số đầu dưới dạng chuỗi (số được đổi tại chỗ như lua_tostring), cắt ở NUL; view trỏ vào chuỗi do Lua giữ. Đối số thiếu
// hay không phải chuỗi/số cho view rỗng (chỉ xảy ra khi hàm gọi không kiểm trước).
std::array<std::string_view, 8> guide_arguments(lua_State* lua, int count) {
    std::array<std::string_view, 8> args{};
    for (int index = 1; index <= count; ++index) {
        args.at(static_cast<std::size_t>(index - 1)) = native::c_string(native::text_arg(lua, index).value_or(std::string_view{}));
    }
    return args;
}

// OpenFreshManGuideNew(loại, a, b, c, d[, kiểu, hướng, chủ]) (0x1402649e0): năm đối số đầu phải là số nghiêm (mỗi chỗ một câu ném
// "LUA: OpenFreshManGuide Wrong Param<n>"). Loại 1 cần thêm kiểu, hướng là số và chủ là chuỗi (không thì "Wrong ParamEx"), đặt chủ lớp rồi
// nhờ game mở lớp (Ask::kOpenFreshManGuide, chữ là tám đối số như main_menu_bar_2.cpp); loại 2 nhờ mở với năm đối số đầu; loại khác không
// làm gì. Gốc trả 1 (giá trị trên cùng của ngăn xếp). Khác gốc: gốc đẩy sự kiện 0x3f2 vào bus riêng của hướng dẫn (DAT_14103e6e0, kèm
// hình chữ nhật cửa sổ) mà client chưa có; ở đây chỉ ghi lời nhờ.
NativeResult open_fresh_man_guide_new(lua_State* lua) {
    if (const char* const wrong = first_wrong_guide_argument(lua)) return std::unexpected(NativeError::of(wrong));
    const std::int32_t kind = native::to_int(native::strict_number(lua, 1).value_or(0));
    if (kind != 1 && kind != 2) return 1;
    const bool extended = kind == 1;
    if (extended && !(native::strict_number(lua, 6) && native::strict_number(lua, 7) && native::text_arg(lua, 8))) {
        return std::unexpected(NativeError::of("LUA: OpenFreshManGuide Wrong ParamEx"));
    }
    const int count = extended ? 8 : 5;
    const std::array<std::string_view, 8> args = guide_arguments(lua, count);
    Context& context = native::context_of(lua);
    std::string text;
    for (int index = 0; index < count; ++index) {
        if (index != 0) text += '	';
        text += args.at(static_cast<std::size_t>(index));
    }
    if (extended) context.guide_owner.assign(args.at(7).substr(0, kGuideOwnerLimit));
    context.push_call(panel::Ask::kOpenFreshManGuide, std::move(text));
    return 1;
}

// SetMenuBarPageNumber(n) (0x140248880): ghi (int)n vào hệ action; không phải số nghiêm thì ném.
NativeResult set_menu_bar_page_number(lua_State* lua) {
    const std::optional<double> given = native::strict_number(lua, 1);
    if (!given) return std::unexpected(NativeError::of("LUA: Lua_SetMenuBarPageNumber Wrong Param"));
    native::context_of(lua).menu_bar_page = native::to_int(*given);
    return 0;
}

// AskServerTimeAgain() (0x140246fe0): gửi CGAskServerTime; ở đây nhờ game gửi (Ask::kAskServerTime).
NativeResult ask_server_time_again(lua_State* lua) {
    native::context_of(lua).push_call(panel::Ask::kAskServerTime, {});
    return 0;
}

// Các hàm sau chỉ xoá hay đặt trạng thái mà client này chưa có, nên không làm gì (Khác gốc: gốc ghi vào các đối tượng đó):
//  - IMDressCleanUpPayBox (0x14025a260): dọn hộp thanh toán trang phục của kho và hệ action;
//  - Lua_ClearZiDianZengYingHaoActionItem (0x140308d50): xoá ô action của tăng ích Tử Điện;
//  - SetDefaultMouse (0x14023f980): đặt hành động chuột mặc định của hệ action;
//  - City:ClearPhoenixPlainWarScore (0x140425f50) và Match:ClearHuaShanGRMatchScore (0x1403efb20): xoá bảng điểm trận trong bộ nhớ;
//  - BWDH/CorpsUI_2016:CancelPlayerWatchPosDirection (0x1403f29e0, 0x1402c9400): thôi chế độ xem vị trí người chơi khi cờ đang bật
//    (cờ chỉ bật bởi dữ liệu máy chủ, chưa có).
NativeResult do_nothing(lua_State* /*lua*/) {
    return 0;
}

constexpr std::array<native::Entry, 9> kGlobals = {{
    {.name = "GetCurrentTime", .function = &lua::adapt<get_current_time>},
    {.name = "GetFreshManGuideOwner", .function = &lua::adapt<get_fresh_man_guide_owner>},
    {.name = "CloseFreshManGuide", .function = &lua::adapt<close_fresh_man_guide>},
    {.name = "OpenFreshManGuideNew", .function = &lua::adapt<open_fresh_man_guide_new>},
    {.name = "SetMenuBarPageNumber", .function = &lua::adapt<set_menu_bar_page_number>},
    {.name = "AskServerTimeAgain", .function = &lua::adapt<ask_server_time_again>},
    {.name = "IMDressCleanUpPayBox", .function = &lua::adapt<do_nothing>},
    {.name = "SetDefaultMouse", .function = &lua::adapt<do_nothing>},
    {.name = "Lua_ClearZiDianZengYingHaoActionItem", .function = &lua::adapt<do_nothing>},
}};
constexpr std::array<native::Entry, 4> kPlayer = {{
    {.name = "IsVaild", .function = &lua::adapt<player_is_valid>},
    {.name = "GetDefineHumanMaxLevel", .function = &lua::adapt<player_max_level>},
    {.name = "GetDefineHumanMaxLevelSub", .function = &lua::adapt<player_max_level_sub>},
    {.name = "GetHumanExpRatioToNeedExp", .function = &lua::adapt<player_exp_ratio>},
}};
constexpr std::array<native::Entry, 2> kGameProduceLogin = {{
    {.name = "IsWeGameClient", .function = &lua::adapt<is_we_game_client>},
    {.name = "IsWeGameServer", .function = &lua::adapt<is_we_game_server>},
}};
constexpr std::array<native::Entry, 2> kDataPool = {{
    {.name = "Lua_IsRedPointInUIShow", .function = &lua::adapt<is_red_point_in_ui_show>},
    {.name = "Lua_ClearZiDianZengYingHaoActionItem", .function = &lua::adapt<do_nothing>},
}};
constexpr std::array<native::Entry, 1> kCity = {{{.name = "ClearPhoenixPlainWarScore", .function = &lua::adapt<do_nothing>}}};
constexpr std::array<native::Entry, 1> kMatch = {{{.name = "ClearHuaShanGRMatchScore", .function = &lua::adapt<do_nothing>}}};
constexpr std::array<native::Entry, 1> kWatch = {{{.name = "CancelPlayerWatchPosDirection", .function = &lua::adapt<do_nothing>}}};

} // namespace

void register_state(lua_State* lua) {
    native::register_globals(lua, kGlobals);
    native::register_table(lua, "Player", kPlayer);
    native::register_table(lua, "GameProduceLogin", kGameProduceLogin);
    native::register_table(lua, "DataPool", kDataPool);
    native::register_table(lua, "City", kCity);
    native::register_table(lua, "Match", kMatch);
    native::register_table(lua, "BWDH", kWatch);
    native::register_table(lua, "CorpsUI_2016", kWatch);
}

} // namespace game::ui::script
