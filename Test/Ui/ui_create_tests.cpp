// Bảng tạo nhân vật (ui/panel/create_role) và dữ liệu của nó (ui/panel/role_cast): bản port để lại
// đúng trạng thái cửa sổ và đúng các lời gọi game mà CreateRole.lua của client 2026 để lại khi chạy
// trên LuaPlus.dll gốc với bảng thật (tests/golden/panel/create_role_newcomer.tsv, sinh bằng
// TOOLS/port/lua_oracle.py với kịch bản TOOLS/port/oracle/create_role_newcomer.lua), cùng các ca
// biên mà kịch bản không đi tới: bảng rỗng, dòng hỏng, sắp ổn định, nút khoá, ô tên, bản dịch.
#include "ui/panel/create_role.hpp"

#include "core/check.hpp"
#include "gui/asset.hpp"
#include "gui/loader.hpp"
#include "gui/sheet.hpp"
#include "gui/strings.hpp"
#include "io/file.hpp"
#include "panel_golden.hpp"
#include "table/tsv.hpp"
#include "test.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/role_cast.hpp"
#include "ui/panel/widgets.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <format>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using ui::panel::Ask;
using ui::panel::Call;
using ui::panel::CastRow;
using ui::panel::CastTables;
using ui::panel::CreateFacts;
using ui::panel::CreateRole;
using ui::panel::Deck;
using ui::panel::Key;
using ui::panel::ModelLook;
using ui::panel::RoleCast;

#ifdef GAME_CLIENT_DATA
constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
constexpr std::string_view kClientData;
#endif

constexpr std::string_view kGoldenFile = "create_role_newcomer.tsv";
constexpr std::int32_t kFemale = ui::panel::kFemale;
constexpr std::int32_t kMale = ui::panel::kMale;

// Bốn bảng đã đọc và dữ liệu dựng từ chúng.
struct Tables {
    std::optional<table::Tsv> portraits;
    std::optional<table::Tsv> faces;
    std::optional<table::Tsv> hairs;
    std::optional<table::Tsv> outfits;

    [[nodiscard]] RoleCast cast() const {
        CastTables given;
        given.portraits = portraits ? &*portraits : nullptr;
        given.faces = faces ? &*faces : nullptr;
        given.hairs = hairs ? &*hairs : nullptr;
        given.outfits = outfits ? &*outfits : nullptr;
        return RoleCast::from_tables(given);
    }
};

std::optional<table::Tsv> parsed(std::string_view text) {
    table::TsvResult table = table::parse_tsv(text);
    core::check(table.has_value(), "bảng mẫu phải đọc được");
    return std::move(*table);
}

// Bảng mẫu nhỏ: ba ảnh nữ chọn được (một ảnh order nhỏ hơn nằm cuối tệp) và một ảnh không chọn
// được; hai ảnh nam; ba kiểu mặt nữ chọn được kèm một dòng cao mô và một dòng không chọn được; hai
// kiểu tóc nữ chọn được kèm dòng cao mô của kiểu đầu; một mặt, một tóc nam; ba bộ đồ.
Tables sample_tables() {
    Tables tables;
    tables.portraits = parsed("id\trace\timage\tchoice\torder\n"
                              "1\t0\tset:G image:G_1\t3\t1\n"
                              "2\t0\tset:G image:G_2\t1\t1\n"
                              "7\t0\tset:G image:G_7\t0\t0\n"
                              "13\t1\tset:M image:M_1\t3\t1\n"
                              "49\t0\tset:G image:G_49\t3\t0\n"
                              "14\t1\tset:M image:M_2\t3\t1\n");
    tables.faces = parsed("id\trace\tmesh\tname\tchoice\n"
                          "1\t0\tf1.mesh\tMặt Một\t3\n"
                          "2\t0\tf2.mesh\tMặt Hai\t0\n"
                          "3\t0\tf3.mesh\tMặt Ba\t1\n"
                          "4\t0\tf4.mesh\tMặt Bốn\t3\n"
                          "100\t1\tm1.mesh\tMặt Nam\t3\n"
                          "10001\t0\tf1_hi.mesh\tMặt Một Cao\t-1\n");
    tables.hairs = parsed("id\trace\tmesh\taccessory\tname\tchoice\n"
                          "0\t0\th0.mesh\t\tTóc Không\t2\n"
                          "1\t0\th1.mesh\t\tTóc Một\t3\n"
                          "5\t1\tn5.mesh\t\tTóc Nam\t3\n"
                          "17\t0\th17.mesh\t\tTóc Hai\t1\n"
                          "10001\t0\th1_hi.mesh\t\tTóc Một Cao\t-1\n");
    tables.outfits = parsed("id\tname\tbody\tfoot\tarm\n"
                            "0\tBộ Một\t437\t440\t443\n"
                            "1\tBộ Hai\t438\t441\t444\n"
                            "2\tBộ Ba\t439\t442\t445\n");
    return tables;
}

// Dãy số đưa sẵn cho math.random của script, như kịch bản trọng tài; gieo quá dãy thì trả 0 và nhớ.
struct Dice {
    std::vector<std::int32_t> rolls;
    std::size_t next = 0;
    std::size_t overruns = 0;

    [[nodiscard]] std::int32_t roll() {
        if (next < rolls.size()) return rolls[next++];
        ++overruns;
        return 0;
    }
};

// Một bảng đang chạy: dữ liệu, xúc xắc, trạng thái bảng và các việc đã nhờ game.
struct Run {
    RoleCast cast;
    Dice dice;
    CreateRole panel;
    std::vector<Call> calls;
    const gui::StringBook* words = nullptr;

    [[nodiscard]] CreateFacts facts() {
        CreateFacts facts;
        facts.cast = &cast;
        facts.words = words;
        facts.roll = [this](std::int32_t /*top*/) { return dice.roll(); };
        return facts;
    }
    void open() { ui::panel::open_create(panel, facts(), calls); }
    void press(std::string_view window) { ui::panel::press_create(panel, window, facts(), calls); }
    void release() { ui::panel::release_create(panel, calls); }
    void type(std::u32string_view text) {
        for (const char32_t code : text) ui::panel::type_create(panel, code, facts(), calls);
    }
    [[nodiscard]] std::vector<std::string> lines() { return panel_lines(panel.is_shown, panel.widgets, calls); }
};

// Giá trị của một thuộc tính đang giữ; rỗng khi chưa đặt.
std::string_view value_of(const CreateRole& panel, std::string_view window, std::string_view name) {
    return panel.widgets.value(Key{.window = window, .name = name}).value_or(std::string_view{});
}

std::string_view text_of(const CreateRole& panel, std::string_view window) {
    return value_of(panel, window, "Text");
}

// Chữ của lời gọi cuối cùng thuộc loại ask; rỗng khi không có.
std::string last_call(std::span<const Call> calls, Ask ask) {
    std::string text;
    for (const Call& call : calls) {
        if (call.ask == ask) text = call.text;
    }
    return text;
}

std::size_t count_calls(std::span<const Call> calls, Ask ask) {
    return static_cast<std::size_t>(std::ranges::count(calls, ask, &Call::ask));
}

// Một bước của kịch bản trọng tài trên bản port.
using Step = void (*)(Run&);

void step_open(Run& run) {
    run.open();
}
void step_head5(Run& run) {
    run.press("CreateRole_Select_Head5");
}
void step_page_down(Run& run) {
    run.press("CreateRole_PageDown");
}
void step_head2(Run& run) {
    run.press("CreateRole_Select_Head2");
}
void step_page_up(Run& run) {
    run.press("CreateRole_PageUp");
}
void step_hair_next(Run& run) {
    run.press("CreateRole_SelectHair_TurnRight1");
}
void step_hair_next_twice(Run& run) {
    run.press("CreateRole_SelectHair_TurnRight1");
    run.press("CreateRole_SelectHair_TurnRight1");
}
void step_hair_back(Run& run) {
    run.press("CreateRole_SelectHair_TurnLeft1");
}
void step_face_next(Run& run) {
    run.press("CreateRole_SelectFace_TurnRight1");
}
void step_face_next_twice(Run& run) {
    run.press("CreateRole_SelectFace_TurnRight1");
    run.press("CreateRole_SelectFace_TurnRight1");
}
void step_face_back(Run& run) {
    run.press("CreateRole_SelectFace_TurnLeft1");
}
void step_cloth_next(Run& run) {
    run.press("CreateRole_SelectClothin_TurnRight1");
}
void step_cloth_back_twice(Run& run) {
    run.press("CreateRole_SelectClothin_TurnLeft1");
    run.press("CreateRole_SelectClothin_TurnLeft1");
}
void step_boy(Run& run) {
    run.press("CreateRole_SelectSex_Boy");
}
void step_random(Run& run) {
    run.press("CreateRole_Random");
}
void step_menpai3(Run& run) {
    run.press("CreateRole_MenpaiModel03");
}
void step_preview_woman(Run& run) {
    run.press("CreateRole_Info2_Frame_Back5");
}
void step_menpai11(Run& run) {
    run.press("CreateRole_MenpaiModel11");
}
void step_cancel_preview(Run& run) {
    run.press("CreateRole_MenpaiModel00");
}
void step_hover_random(Run& run) {
    ui::panel::hover_create(run.panel, "CreateRole_Random");
}
void step_hover_menpai12(Run& run) {
    ui::panel::hover_create(run.panel, "CreateRole_MenpaiModel12");
}
void step_hover_none(Run& run) {
    ui::panel::hover_create(run.panel, {});
}
void step_turn_and_zoom(Run& run) {
    for (const std::string_view window : {"CreateRole_Role2_Model_TurnLeft", "CreateRole_Role2_Model_TurnRight",
             "CreateRole_ModelZoomIn", "CreateRole_ModelZoomOut"}) {
        run.press(window);
        run.release();
    }
}
void step_create_third(Run& run) {
    run.type(U"Lang");
    run.press("CreateRole_Select_Head3");
    run.press("CreateRole_Author");
}
void step_create_empty_slot(Run& run) {
    run.press("CreateRole_Select_Head8");
    run.press("CreateRole_PageDown");
    run.press("CreateRole_Author");
}
void step_back(Run& run) {
    run.press("CreateRole_Last");
}
void step_close(Run& run) {
    ui::panel::close_create(run.panel);
}

// Đúng thứ tự các bước của TOOLS/port/oracle/create_role_newcomer.lua.
constexpr std::array<Step, 30> kScript = {
    step_open,          step_head5,           step_page_down,     step_head2,          step_page_up,
    step_hair_next,     step_hair_next_twice, step_hair_back,     step_face_next,      step_face_next_twice,
    step_face_back,     step_cloth_next,      step_cloth_back_twice, step_boy,         step_page_down,
    step_random,        step_menpai3,         step_preview_woman, step_menpai11,       step_cancel_preview,
    step_hover_random,  step_hover_menpai12,  step_hover_none,    step_turn_and_zoom,  step_create_third,
    step_create_empty_slot, step_back,        step_close,         step_open,           step_face_next,
};

std::optional<table::Tsv> read_client_table(std::string_view name) {
    const std::filesystem::path file = io::path_from_utf8(kClientData) / "Table" / io::path_from_utf8(name);
    const io::TextResult text = io::read_text(file);
    if (!text) return std::nullopt;
    table::TsvResult table = table::parse_tsv(*text);
    if (!table) return std::nullopt;
    return std::move(*table);
}

Tables client_tables() {
    Tables tables;
    tables.portraits = read_client_table("portraits.tsv");
    tables.faces = read_client_table("faces.tsv");
    tables.hairs = read_client_table("hairs.tsv");
    tables.outfits = read_client_table("newbie_outfits.tsv");
    return tables;
}

void port_matches_original_script(Context& context) {
    if (kPanelGolden.empty() || kClientData.empty()) return;
    const std::vector<GoldenBlock> blocks = read_golden(kGoldenFile);
    context.expect(blocks.size() == kScript.size(), "số vàng có đủ ba mươi bước của kịch bản");
    const Tables tables = client_tables();
    const bool has_tables = tables.portraits && tables.faces && tables.hairs && tables.outfits;
    context.expect(has_tables, "đọc được bốn bảng của màn tạo trong CLIENT/data/Table");
    if (blocks.size() != kScript.size() || !has_tables) return;
    Run run;
    run.cast = tables.cast();
    context.expect(run.cast.skipped() == 0, "bảng thật không có dòng hỏng");
    // Dãy __rolls của kịch bản: lúc nạp, mở bảng, chọn nam, ba số của nút ngẫu nhiên, xem trước nữ,
    // mở lại bảng.
    run.dice.rolls = {1, 2, 0, 2, 1, 1, 1, 0};
    for (std::size_t index = 0; index < kScript.size(); ++index) {
        kScript.at(index)(run);
        expect_block(context, blocks.at(index), run.lines());
    }
    context.expect(run.dice.next == run.dice.rolls.size() && run.dice.overruns == 0, "gieo đúng tám lần như script");
}

// Phân bố của client 2026: mỗi giới mười lăm ảnh chân dung (ba ảnh order 0 đứng trước mười hai ảnh
// order 1), ba kiểu tóc, sáu kiểu mặt chọn được, ba bộ đồ tân thủ.
void client_data_has_the_2026_spread(Context& context) {
    if (kClientData.empty()) return;
    const RoleCast cast = client_tables().cast();
    constexpr std::array<std::int32_t, 15> kWomen = {49, 50, 51, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12};
    constexpr std::array<std::int32_t, 15> kMen = {52, 53, 54, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24};
    context.expect(cast.portrait_count(kFemale) == 15 && cast.portrait_count(kMale) == 15, "mười lăm ảnh mỗi giới");
    for (std::int32_t index = 0; index < 15; ++index) {
        const auto place = static_cast<std::size_t>(index);
        const bool is_woman = cast.portrait_id(CastRow{.sex = kFemale, .index = index}) == kWomen.at(place);
        const bool is_man = cast.portrait_id(CastRow{.sex = kMale, .index = index}) == kMen.at(place);
        context.expect(is_woman && is_man, std::format("ảnh thứ {} của hai giới", index));
    }
    context.expect(cast.portrait_image(CastRow{.sex = kFemale, .index = 15}).empty(), "ảnh thứ mười sáu không chọn được");
    context.expect(cast.hair_count(kFemale) == 3 && cast.hair_count(kMale) == 3, "ba kiểu tóc mỗi giới");
    const std::array<std::int32_t, 3> women_hair = {1, 17, 19};
    const std::array<std::int32_t, 3> men_hair = {5, 12, 14};
    for (std::int32_t index = 0; index < 3; ++index) {
        const auto place = static_cast<std::size_t>(index);
        const bool is_woman = cast.hair_id(CastRow{.sex = kFemale, .index = index}) == women_hair.at(place);
        const bool is_man = cast.hair_id(CastRow{.sex = kMale, .index = index}) == men_hair.at(place);
        context.expect(is_woman && is_man, std::format("tóc thứ {} của hai giới", index));
    }
    std::int32_t women_faces = 0;
    std::int32_t men_faces = 0;
    for (std::int32_t index = 0; index < cast.face_count(kFemale); ++index) {
        const std::int32_t choice = cast.face_choice(CastRow{.sex = kFemale, .index = index});
        women_faces += (choice == 1 || choice == 3) ? 1 : 0;
    }
    for (std::int32_t index = 0; index < cast.face_count(kMale); ++index) {
        const std::int32_t choice = cast.face_choice(CastRow{.sex = kMale, .index = index});
        men_faces += (choice == 1 || choice == 3) ? 1 : 0;
    }
    context.expect(women_faces == 6 && men_faces == 6, "sáu kiểu mặt chọn được mỗi giới");
    context.expect(cast.outfit_count() == 3, "ba bộ đồ tân thủ");
    const ModelLook shown = cast.model_look(ModelLook{.sex = kMale, .face = 100, .hair = 5});
    context.expect(shown.face == 10100 && shown.hair == 10005, "người mẫu nam dùng dòng cao mô");
}

void cast_sorts_portraits_stably(Context& context) {
    const RoleCast cast = sample_tables().cast();
    context.expect(cast.skipped() == 0, "bảng mẫu không có dòng hỏng");
    context.expect(cast.portrait_count(kFemale) == 3 && cast.portrait_count(kMale) == 2, "đếm dòng chọn được");
    context.expect(cast.portrait_count(2) == 0 && cast.portrait_count(-1) == 0, "giới lạ không có ảnh");
    // Sau khi sắp theo order: id 7 (order 0, không chọn được), id 49 (order 0), rồi id 1, 2 (order 1,
    // giữ thứ tự tệp).
    context.expect(cast.portrait_image(CastRow{.sex = kFemale, .index = 0}).empty(), "dòng không chọn được trả ảnh rỗng");
    context.expect(!cast.portrait_id(CastRow{.sex = kFemale, .index = 0}), "dòng không chọn được không có id");
    context.expect(cast.portrait_id(CastRow{.sex = kFemale, .index = 1}) == 49, "order nhỏ đứng trước dù nằm cuối tệp");
    context.expect(cast.portrait_id(CastRow{.sex = kFemale, .index = 2}) == 1, "cùng order thì theo thứ tự tệp");
    context.expect(cast.portrait_image(CastRow{.sex = kFemale, .index = 3}) == "set:G image:G_2", "ảnh của dòng cuối");
    context.expect(cast.portrait_image(CastRow{.sex = kFemale, .index = 4}).empty(), "ngoài dãy thì rỗng");
    context.expect(cast.portrait_image(CastRow{.sex = kFemale, .index = -1}).empty(), "chỉ số âm thì rỗng");
    context.expect(!cast.portrait_id(CastRow{.sex = 7, .index = 0}), "giới lạ không có id");
    context.expect(cast.portrait_id(CastRow{.sex = kMale, .index = 1}) == 14, "ảnh nam thứ hai");
}

void cast_keeps_faces_filters_hairs(Context& context) {
    const RoleCast cast = sample_tables().cast();
    context.expect(cast.face_count(kFemale) == 5 && cast.face_count(kMale) == 1, "mặt giữ mọi dòng");
    context.expect(cast.face_count(3) == 0, "giới lạ không có mặt");
    context.expect(cast.face_choice(CastRow{.sex = kFemale, .index = 1}) == 0, "cờ chọn nguyên giá trị");
    context.expect(cast.face_choice(CastRow{.sex = kFemale, .index = 4}) == -1, "dòng cao mô có cờ -1");
    context.expect(cast.face_choice(CastRow{.sex = kFemale, .index = 5}) == -1, "không có dòng thì -1");
    context.expect(cast.face_name(CastRow{.sex = kFemale, .index = 2}) == "Mặt Ba", "tên theo vị trí");
    context.expect(cast.face_name(CastRow{.sex = kFemale, .index = -1}).empty(), "vị trí âm thì tên rỗng");
    context.expect(cast.face_id(CastRow{.sex = kFemale, .index = 3}) == 4, "id theo vị trí");
    context.expect(cast.face_id(CastRow{.sex = kFemale, .index = 9}) == 0, "không có dòng thì id 0");
    context.expect(cast.hair_count(kFemale) == 2 && cast.hair_count(kMale) == 1, "tóc chỉ giữ dòng chọn được");
    context.expect(cast.hair_count(-4) == 0, "giới lạ không có tóc");
    context.expect(cast.hair_name(CastRow{.sex = kFemale, .index = 1}) == "Tóc Hai", "tên tóc theo vị trí đã lọc");
    context.expect(cast.hair_id(CastRow{.sex = kFemale, .index = 0}) == 1, "id tóc đầu");
    context.expect(cast.hair_id(CastRow{.sex = kFemale, .index = 2}) == 0, "không có dòng thì id tóc 0");
    context.expect(cast.hair_name(CastRow{.sex = kMale, .index = 1}).empty(), "ngoài dãy thì tên tóc rỗng");
}

void cast_finds_high_poly_rows(Context& context) {
    const RoleCast cast = sample_tables().cast();
    const ModelLook first = cast.model_look(ModelLook{.sex = kFemale, .face = 1, .hair = 1});
    context.expect(first.face == 10001 && first.hair == 10001, "có dòng cao mô thì dùng nó");
    const ModelLook second = cast.model_look(ModelLook{.sex = kFemale, .face = 3, .hair = 17});
    context.expect(second.face == 3 && second.hair == 17, "không có dòng cao mô thì giữ id");
    const ModelLook man = cast.model_look(ModelLook{.sex = kMale, .face = 1, .hair = 1});
    context.expect(man.face == 1 && man.hair == 1, "dòng cao mô của giới khác không tính");
    const ModelLook odd = cast.model_look(ModelLook{.sex = 9, .face = 1, .hair = 1});
    context.expect(odd.sex == 9 && odd.face == 1 && odd.hair == 1, "giới lạ thì giữ nguyên");
    const ModelLook huge = cast.model_look(ModelLook{.sex = kFemale, .face = 2147483647, .hair = -5});
    context.expect(huge.face == 2147483647 && huge.hair == -5, "id ngoài miền không cộng tràn");
}

void cast_reads_outfits(Context& context) {
    const RoleCast cast = sample_tables().cast();
    context.expect(cast.outfit_count() == 3, "ba bộ đồ");
    context.expect(cast.outfit_name(1) == "Bộ Hai", "tên bộ đồ");
    context.expect(cast.outfit_name(3).empty() && cast.outfit_name(-1).empty(), "ngoài dãy thì tên rỗng");
    const ui::panel::NewbieOutfit* outfit = cast.outfit(2);
    const bool is_third = outfit != nullptr && outfit->id == 2 && outfit->body == 439 && outfit->foot == 442;
    context.expect(is_third && outfit->arm == 445, "ba id hình của bộ thứ ba");
    context.expect(cast.outfit(3) == nullptr && cast.outfit(-1) == nullptr, "ngoài dãy thì không có dòng");
}

void cast_skips_broken_rows(Context& context) {
    Tables tables;
    tables.portraits = parsed("id\trace\timage\tchoice\torder\n"
                              "x\t0\tset:G image:G_1\t3\t1\n"
                              "2\t0\tset:G image:G_2\t3\t1\n"
                              "3\t5\tset:G image:G_3\t3\t1\n"
                              "-4\t0\tset:G image:G_4\t3\t1\n");
    tables.faces = parsed("id\trace\tmesh\tname\n1\t0\tf.mesh\tMặt\n");
    tables.hairs = parsed("id\trace\tmesh\taccessory\tname\tchoice\n70000\t0\th.mesh\t\tTóc\t3\n1\t1\th.mesh\t\tTóc\tba\n");
    tables.outfits = parsed("id\tname\tbody\tfoot\tarm\n0\tBộ\t70000\t1\t1\n1\tBộ Hai\t1\t2\t3\n");
    const RoleCast cast = tables.cast();
    context.expect(cast.portrait_count(kFemale) == 1, "dòng hỏng và dòng giới lạ không vào dãy");
    context.expect(cast.portrait_id(CastRow{.sex = kFemale, .index = 0}) == 2, "dòng đúng còn lại");
    context.expect(cast.face_count(kFemale) == 0, "bảng thiếu cột thì không có dòng nào");
    context.expect(cast.hair_count(kFemale) == 0 && cast.hair_count(kMale) == 0, "id ngoài miền và cờ sai bị bỏ");
    context.expect(cast.outfit_count() == 1 && cast.outfit_name(0) == "Bộ Hai", "bộ đồ có id hình ngoài miền bị bỏ");
    // Hai dòng chân dung, một dòng mặt, hai dòng tóc, một dòng bộ đồ; dòng giới 5 không tính là hỏng.
    context.expect(cast.skipped() == 6, "đếm đúng số dòng hỏng");
    const RoleCast none = RoleCast::from_tables(CastTables{});
    context.expect(none.portrait_count(kFemale) == 0 && none.outfit_count() == 0 && none.skipped() == 0, "không bảng nào");
}

Run sample_run(std::vector<std::int32_t> rolls) {
    Run run;
    run.cast = sample_tables().cast();
    run.dice.rolls = std::move(rolls);
    return run;
}

void open_sets_the_first_choices(Context& context) {
    Run run = sample_run({0, 2});
    run.open();
    const CreateRole& panel = run.panel;
    context.expect(panel.is_shown && panel.sex == kFemale && panel.head == 0 && panel.page == 0, "nữ, trang đầu, ô đầu");
    context.expect(text_of(panel, "CreateRole_SelectHair_Text2") == "Tóc Một", "tóc đầu");
    context.expect(text_of(panel, "CreateRole_SelectFace_Text2") == "Mặt Một", "mặt đầu");
    context.expect(text_of(panel, "CreateRole_SelectClothing_Text2") == "Bộ Ba", "bộ đồ theo số gieo");
    context.expect(panel.game.hair == 1 && panel.game.face == 1 && panel.game.outfit == 2, "game nhận tóc, mặt, bộ đồ");
    context.expect(panel.game.sex == kFemale && panel.game.menpai == ui::panel::kNoMenpai, "người mẫu nữ, không xem trước");
    context.expect(value_of(panel, "CreateRole_Model", "FakeObject") == "CreateRole_Woman", "fake object nữ");
    context.expect(panel.widgets.is_checked("CreateRole_Select_Head1"), "ô ảnh đầu được đánh dấu");
    context.expect(panel.widgets.is_checked("CreateRole_SelectSex_Girl"), "nút nữ được đánh dấu");
    context.expect(!panel.widgets.is_checked("CreateRole_SelectSex_Boy"), "nút nam tắt");
    // Dãy chân dung nữ sau khi sắp: dòng không chọn được đứng đầu nên ô đầu trống.
    context.expect(value_of(panel, "CreateRole_Select_HeadImage1", "Image").empty(), "ô của dòng không chọn được để trống");
    context.expect(value_of(panel, "CreateRole_Select_HeadImage2", "Image") == "set:G image:G_49", "ô thứ hai");
    context.expect(panel.widgets.is_disabled("CreateRole_PageUp") && panel.widgets.is_disabled("CreateRole_PageDown"), "một trang");
    context.expect(ui::panel::create_name(panel).empty(), "tên trống");
}

void sex_change_keeps_the_head_mark(Context& context) {
    Run run = sample_run({0, 0, 1});
    run.open();
    run.press("CreateRole_Select_Head3");
    context.expect(run.panel.head == 2 && run.panel.widgets.is_checked("CreateRole_Select_Head3"), "chọn ô ba");
    context.expect(!run.panel.widgets.is_checked("CreateRole_Select_Head1"), "ô một tắt");
    run.press("CreateRole_SelectFace_TurnRight1");
    context.expect(run.panel.face == 1, "kiểu mặt thứ hai");
    run.press("CreateRole_SelectSex_Boy");
    const CreateRole& panel = run.panel;
    context.expect(panel.sex == kMale && panel.head == 0, "nam, ô dùng để tạo về ô đầu");
    context.expect(panel.widgets.is_checked("CreateRole_Select_Head3"), "dấu chọn vẫn ở ô ba như bản gốc");
    context.expect(panel.face == 1, "chỉ số kiểu mặt không đặt lại");
    context.expect(panel.game.face == 100 && panel.game.hair == 5 && panel.game.outfit == 1, "người mẫu nam");
    context.expect(value_of(panel, "CreateRole_Model", "FakeObject") == "CreateRole_Man", "fake object nam");
    context.expect(panel.widgets.is_checked("CreateRole_SelectSex_Boy"), "nút nam bật");
    context.expect(!panel.widgets.is_checked("CreateRole_SelectSex_Girl"), "nút nữ tắt");
}

void face_arrows_stop_at_hair_count(Context& context) {
    // Nữ của bảng mẫu có ba kiểu mặt chọn được nhưng chỉ hai kiểu tóc: mũi tên mặt chỉ đi qua hai
    // kiểu đầu.
    Run run = sample_run({0, 0});
    run.open();
    run.press("CreateRole_SelectFace_TurnRight1");
    context.expect(run.panel.game.face == 3, "kiểu mặt thứ hai (dòng thứ ba của bảng)");
    run.press("CreateRole_SelectFace_TurnRight1");
    context.expect(run.panel.face == 0 && run.panel.game.face == 1, "tiến nữa thì quay về đầu, không tới kiểu thứ ba");
    run.press("CreateRole_SelectFace_TurnLeft1");
    context.expect(run.panel.face == 1 && run.panel.game.face == 3, "lùi từ đầu thì về kiểu thứ hai");
}

void arrows_skip_rows_without_names(Context& context) {
    Tables tables = sample_tables();
    tables.hairs = parsed("id\trace\tmesh\taccessory\tname\tchoice\n"
                          "1\t0\th1.mesh\t\tTóc Một\t3\n"
                          "2\t0\th2.mesh\t\t\t3\n"
                          "3\t0\th3.mesh\t\tTóc Ba\t3\n");
    tables.outfits = parsed("id\tname\tbody\tfoot\tarm\n0\tBộ Một\t437\t440\t443\n1\t\t438\t441\t444\n");
    Run run;
    run.cast = tables.cast();
    run.dice.rolls = {0, 0};
    run.open();
    const std::size_t before = run.calls.size();
    run.press("CreateRole_SelectHair_TurnRight1");
    context.expect(run.panel.hair == 0 && run.calls.size() == before, "kiểu tóc không tên chặn mũi tên tiến");
    run.press("CreateRole_SelectHair_TurnLeft1");
    context.expect(run.panel.hair == 0 && run.calls.size() == before, "và chặn cả mũi tên lùi");
    run.press("CreateRole_SelectClothin_TurnRight1");
    context.expect(run.panel.outfit == 0 && run.calls.size() == before, "bộ đồ không tên chặn mũi tên");
    run.press("CreateRole_SelectClothin_TurnLeft1");
    context.expect(run.panel.outfit == 0 && run.calls.size() == before, "bộ đồ không tên chặn mũi tên lùi");
    // Mũi tên mặt: script đếm theo số kiểu tóc (ba, kể cả kiểu không tên) và cả ba ô kiểu mặt của
    // nữ đều có kiểu, nên lùi từ đầu thì tới kiểu mặt thứ ba.
    run.press("CreateRole_SelectFace_TurnLeft1");
    context.expect(run.panel.face == 2 && run.panel.game.face == 4, "mũi tên mặt đi theo số kiểu tóc, không theo tên tóc");
}

void missing_outfit_row_leaves_the_text_empty(Context& context) {
    Tables tables = sample_tables();
    tables.outfits = parsed("id\tname\tbody\tfoot\tarm\n0\tBộ Một\t437\t440\t443\n");
    Run run;
    run.cast = tables.cast();
    run.dice.rolls = {0, 2};
    run.open();
    context.expect(text_of(run.panel, "CreateRole_SelectClothing_Text2").empty(), "bảng không có dòng thứ ba thì tên rỗng");
    context.expect(last_call(run.calls, Ask::kChangeNewRoleEquipSet) == "0\t2", "game nhận chỉ số, không có id bộ đồ");
    context.expect(run.panel.game.outfit == 2, "game vẫn nhớ chỉ số script đưa");
}

void random_uses_three_rolls_in_script_order(Context& context) {
    Run run = sample_run({0, 0, 1, 1, 2});
    run.open();
    run.calls.clear();
    run.press("CreateRole_Random");
    context.expect(run.panel.hair == 1 && run.panel.face == 1 && run.panel.outfit == 2, "tóc, mặt, bộ đồ theo ba số gieo");
    context.expect(run.panel.game.hair == 17 && run.panel.game.face == 3 && run.panel.game.outfit == 2, "game nhận cả ba");
    context.expect(run.dice.next == 5 && run.dice.overruns == 0, "đúng ba lần gieo");
    Run loaded = sample_run({0, 0, 9, -3, 7});
    loaded.open();
    loaded.press("CreateRole_Random");
    context.expect(loaded.panel.hair == 1 && loaded.panel.face == 0 && loaded.panel.outfit == 2, "số gieo ngoài miền bị kẹp");
}

void empty_cast_does_nothing_harmful(Context& context) {
    Run run;
    run.dice.rolls = {0, 0};
    CreateFacts bare;
    ui::panel::open_create(run.panel, bare, run.calls);
    const CreateRole& panel = run.panel;
    context.expect(panel.is_shown && panel.portrait_count == 0, "bảng mở với dữ liệu rỗng");
    context.expect(text_of(panel, "CreateRole_SelectHair_Text2").empty(), "không có tên tóc");
    context.expect(panel.game.hair == 0 && panel.game.face == 0, "game nhận id 0");
    context.expect(panel.widgets.is_disabled("CreateRole_PageDown"), "không có trang kế");
    run.calls.clear();
    ui::panel::press_create(run.panel, "CreateRole_Random", bare, run.calls);
    ui::panel::press_create(run.panel, "CreateRole_SelectHair_TurnRight1", bare, run.calls);
    ui::panel::press_create(run.panel, "CreateRole_SelectFace_TurnLeft1", bare, run.calls);
    ui::panel::press_create(run.panel, "CreateRole_SelectClothin_TurnRight1", bare, run.calls);
    ui::panel::press_create(run.panel, "CreateRole_PageDown", bare, run.calls);
    context.expect(run.calls.empty(), "không có dữ liệu thì các nút chọn không nhờ game gì");
    ui::panel::press_create(run.panel, "CreateRole_Author", bare, run.calls);
    context.expect(last_call(run.calls, Ask::kShowSystemInfo) == "#{DLXZ_090711_1}", "tạo mà không có ảnh thì game báo");
    context.expect(count_calls(run.calls, Ask::kCreateRole) == 0, "và không xin tạo");
}

void create_without_a_head_asks_to_pick(Context& context) {
    // Bảng hiện mà chưa qua sự kiện mở: g_iFaceIndexInPage còn -1 như lúc nạp script.
    Run run = sample_run({});
    run.panel.is_shown = true;
    run.press("CreateRole_Author");
    context.expect(last_call(run.calls, Ask::kShowSystemInfo) == "#{DLJM_XML_20}", "chưa chọn ô thì nhắc");
    context.expect(run.calls.size() == 1, "không gọi gì khác");
}

void create_reports_the_chosen_portrait(Context& context) {
    Run run = sample_run({0, 0});
    run.open();
    run.type(U"Mai");
    run.press("CreateRole_Select_Head2");
    run.calls.clear();
    run.press("CreateRole_Author");
    context.expect(last_call(run.calls, Ask::kSetFaceId) == "0\t1\t49", "ô hai là chân dung 49");
    context.expect(last_call(run.calls, Ask::kCreateRole) == "Mai\t0\t-1\t-1", "xin tạo với tên và giới");
    context.expect(run.panel.game.portrait == 49, "game nhớ id chân dung");
    run.press("CreateRole_Select_Head1");
    run.calls.clear();
    run.press("CreateRole_Author");
    context.expect(count_calls(run.calls, Ask::kSetFaceId) == 0, "ô của dòng không chọn được không đặt chân dung");
    context.expect(last_call(run.calls, Ask::kShowSystemInfo) == "#{DLXZ_090711_1}", "và game báo thiếu ảnh");
    context.expect(run.panel.game.portrait == 49, "id chân dung cũ còn nguyên");
}

void locked_and_hidden_windows_ignore_presses(Context& context) {
    Run run = sample_run({0, 0});
    run.press("CreateRole_SelectSex_Boy");
    context.expect(!run.panel.is_shown && run.calls.empty(), "bảng chưa mở thì không nhận nhấn");
    run.open();
    run.calls.clear();
    run.press("CreateRole_PageUp");
    run.press("CreateRole_PageDown");
    run.press("CreateRole_MenpaiModel00");
    run.press("CreateRole_Info2_Frame_Back4");
    run.press("CreateRole_Khong_Co");
    run.press("CreateRole_MenpaiModel16");
    run.press("CreateRole_Select_Head0");
    context.expect(run.calls.empty() && run.panel.sex == kFemale, "nút khoá, nút giấu và cửa sổ lạ không làm gì");
    run.press("CreateRole_MenpaiModel01");
    context.expect(run.panel.menpai == 0 && run.panel.game.menpai == 0, "xem trước môn đầu");
    context.expect(value_of(run.panel, "CreateRole_Info_Frame", "Alpha") == "0", "khung tuỳ chọn mờ hẳn");
    context.expect(run.panel.widgets.is_hidden("CreateRole_Name"), "ô tên giấu");
    context.expect(run.panel.widgets.is_checked("CreateRole_Info2_Frame_Back5"), "đang là nữ thì nút nữ của khung xem trước bật");
    run.calls.clear();
    for (const std::string_view window : {"CreateRole_SelectSex_Boy", "CreateRole_Random", "CreateRole_Author",
             "CreateRole_Last", "CreateRole_Select_Head2", "CreateRole_SelectHair_TurnRight1"}) {
        run.press(window);
    }
    context.expect(run.calls.empty() && run.panel.sex == kFemale && run.panel.head == 0, "đang xem trước thì khung tuỳ chọn không nhận nhấn");
    run.type(U"abc");
    context.expect(ui::panel::create_name(run.panel).empty(), "đang xem trước thì ô tên không nhận chữ");
    run.press("CreateRole_Info2_Frame_Back4");
    context.expect(run.panel.sex == kMale && run.panel.menpai == 0, "đổi giới trong khung xem trước giữ môn đang xem");
    context.expect(run.panel.widgets.is_hidden("CreateRole_Info_Frame"), "khung tuỳ chọn bị giấu hẳn");
    run.press("CreateRole_MenpaiModel00");
    context.expect(run.panel.menpai == ui::panel::kNoMenpai, "thôi xem trước");
    context.expect(value_of(run.panel, "CreateRole_Info_Frame", "Alpha") == "1", "khung tuỳ chọn rõ lại");
    context.expect(!run.panel.widgets.is_hidden("CreateRole_Info_Frame"), "và hiện lại");
    run.press("CreateRole_Select_Head2");
    context.expect(run.panel.head == 1, "khung tuỳ chọn nhận nhấn trở lại");
}

void name_box_follows_the_layout_limit(Context& context) {
    Run run = sample_run({0, 0});
    run.type(U"x");
    context.expect(ui::panel::create_name(run.panel).empty(), "bảng chưa mở thì không nhận chữ");
    run.open();
    run.type(U"Huyền");
    context.expect(ui::panel::create_name(run.panel) == "Huyền", "ghép từng mã");
    run.type(U"\b");
    context.expect(ui::panel::create_name(run.panel) == "Huyề", "xoá một mã");
    run.type(U"#\t\u007F");
    context.expect(ui::panel::create_name(run.panel) == "Huyề", "bỏ dấu thăng, Tab và mã điều khiển");
    run.type(U"\U0001F600");
    context.expect(ui::panel::create_name(run.panel) == "Huyề", "bỏ mã ngoài mặt phẳng cơ bản");
    run.type(U"123456789");
    context.expect(ui::panel::create_name(run.panel) == "Huyề12345678", "trần mười hai mã của layout");
    run.type(U"\b\b\b\b\b\b\b\b\b\b\b\b\b");
    context.expect(ui::panel::create_name(run.panel).empty(), "xoá quá đầu thì tên rỗng");
    run.type(U"An");
    run.press("CreateRole_Select_Head2");
    run.calls.clear();
    run.type(U"\r");
    context.expect(last_call(run.calls, Ask::kCreateRole) == "An\t0\t-1\t-1", "Enter như nút tạo");
    ui::panel::close_create(run.panel);
    context.expect(!run.panel.is_shown, "đóng bảng");
    run.type(U"z");
    context.expect(ui::panel::create_name(run.panel) == "An", "bảng đã đóng thì không nhận chữ");
    run.open();
    context.expect(ui::panel::create_name(run.panel).empty(), "mở lại thì tên trống");
}

void hover_sets_the_description_line(Context& context) {
    Run run = sample_run({0, 0});
    ui::panel::hover_create(run.panel, "CreateRole_Author");
    context.expect(!run.panel.widgets.value(Key{.window = "CreateRole_Info", .name = "Text"}), "bảng chưa mở thì không đổi");
    run.open();
    struct Tip {
        std::string_view window;
        std::string_view text;
    };
    constexpr std::array<Tip, 10> kTips = {{
        {.window = "CreateRole_Name", .text = "#{DLJM_XML_16}"},
        {.window = "CreateRole_SelectSex_Girl", .text = "#{DLJM_XML_19}"},
        {.window = "CreateRole_SelectSex_Boy", .text = "#{DLJM_XML_19}"},
        {.window = "CreateRole_Select_Head9", .text = "#{DLJM_XML_20}"},
        {.window = "CreateRole_Author", .text = "#{DLJM_XML_22}"},
        {.window = "CreateRole_Last", .text = "#{DLJM_XML_23}"},
        {.window = "CreateRole_MenpaiModel00", .text = "#{DLJM_XML_24}"},
        {.window = "CreateRole_MenpaiModel01", .text = "#{DLJM_XML_25}"},
        {.window = "CreateRole_MenpaiModel15", .text = "#{XMPHM_210604_27}"},
        {.window = "CreateRole_RandomName", .text = "#{TCMZ_211027_2}"},
    }};
    for (const Tip& tip : kTips) {
        ui::panel::hover_create(run.panel, tip.window);
        context.expect(text_of(run.panel, "CreateRole_Info") == tip.text, tip.window);
    }
    ui::panel::hover_create(run.panel, "CreateRole_PageUp");
    context.expect(text_of(run.panel, "CreateRole_Info").empty(), "sang cửa sổ không có mô tả thì dòng mô tả trống");
    ui::panel::notify_create(run.panel, "Tên này đã có.");
    ui::panel::hover_create(run.panel, "CreateRole_PageUp");
    context.expect(text_of(run.panel, "CreateRole_Info") == "Tên này đã có.", "chuột đứng yên thì lời nhắn còn");
    ui::panel::hover_create(run.panel, "CreateRole_Random");
    context.expect(text_of(run.panel, "CreateRole_Info") == "#{JSCJYH_121224_02}", "rê sang nút khác thì mô tả thay lời nhắn");
}

void release_ends_what_was_held(Context& context) {
    Run run = sample_run({0, 0});
    run.open();
    run.calls.clear();
    run.release();
    context.expect(run.calls.empty(), "không giữ nút nào thì nhả không làm gì");
    run.press("CreateRole_Role2_Model_TurnRight");
    context.expect(run.panel.game.spin == 1 && last_call(run.calls, Ask::kModelRotBegin) == "1", "giữ nút xoay phải");
    run.release();
    context.expect(run.panel.game.spin == 0 && last_call(run.calls, Ask::kModelRotEnd) == "0", "nhả thì hết quay");
    run.press("CreateRole_ModelZoomOut");
    context.expect(run.panel.game.zoom == -1, "giữ nút lùi xa");
    ui::panel::close_create(run.panel);
    context.expect(run.panel.game.zoom == 0 && run.panel.game.spin == 0, "đóng bảng thì thôi xoay và phóng");
    run.calls.clear();
    run.release();
    context.expect(run.calls.empty(), "nút đang giữ đã quên sau khi đóng");
}

void names_are_translated(Context& context) {
    const table::TsvResult table = table::parse_tsv("key\ttext\n=Tóc Một\tTóc Du Tiên\n=Mặt Một\tKiểu Diễm Lệ\n=Bộ Một\tBộ Tím\n");
    core::check(table.has_value(), "bảng chuỗi mẫu phải đọc được");
    const gui::StringBook words = gui::StringBook::from_table(*table);
    Run run = sample_run({0, 0});
    run.words = &words;
    run.open();
    context.expect(text_of(run.panel, "CreateRole_SelectHair_Text2") == "Tóc Du Tiên", "tên tóc đã dịch");
    context.expect(text_of(run.panel, "CreateRole_SelectFace_Text2") == "Kiểu Diễm Lệ", "tên mặt đã dịch");
    context.expect(text_of(run.panel, "CreateRole_SelectClothing_Text2") == "Bộ Tím", "tên bộ đồ đã dịch");
    run.press("CreateRole_SelectHair_TurnRight1");
    context.expect(text_of(run.panel, "CreateRole_SelectHair_Text2") == "Tóc Hai", "tên chưa dịch thì hiện tên gốc");
}

void many_faces_grow_the_script_table(Context& context) {
    // Hai mươi lăm kiểu mặt và hai mươi lăm kiểu tóc chọn được: bảng g_FaceModel của script dài quá
    // 21 ô đầu.
    std::string faces = "id\trace\tmesh\tname\tchoice\n";
    std::string hairs = "id\trace\tmesh\taccessory\tname\tchoice\n";
    for (int number = 1; number <= 25; ++number) {
        faces += std::format("{0}\t0\tf.mesh\tMặt {0}\t3\n", number);
        hairs += std::format("{0}\t0\th.mesh\t\tTóc {0}\t3\n", number);
    }
    Tables tables = sample_tables();
    tables.faces = parsed(faces);
    tables.hairs = parsed(hairs);
    Run run;
    run.cast = tables.cast();
    run.dice.rolls = {0, 0};
    run.open();
    context.expect(run.panel.face_models.size() == 25, "bảng kiểu mặt dài theo dữ liệu");
    run.press("CreateRole_SelectFace_TurnLeft1");
    context.expect(run.panel.face == 24 && run.panel.game.face == 25, "lùi từ đầu thì tới kiểu cuối");
}

void paint_copies_the_state(Context& context) {
    Run run = sample_run({0, 0});
    Deck deck;
    ui::panel::paint_create(deck, run.panel);
    context.expect(deck.roots().empty() && deck.overrides().empty(), "bảng chưa mở thì không ghi gì");
    run.open();
    ui::panel::paint_create(deck, run.panel);
    context.expect(deck.is_shown("CreateRole_Frame"), "bảng đang mở thì hiện cửa sổ gốc");
    const auto caret_of = [](Deck& from) {
        std::string value;
        for (const gui::Override& item : from.overrides()) {
            if (item.window == "CreateRole_Name" && item.name == "Caret") value = item.value;
        }
        return value;
    };
    context.expect(caret_of(deck) == "True", "ô tên có con trỏ nhập");
    context.expect(std::ranges::contains(deck.hidden(), std::string_view("CreateRole_RandomName")), "nút tên ngẫu nhiên giấu");
    run.press("CreateRole_MenpaiModel02");
    deck.clear();
    ui::panel::paint_create(deck, run.panel);
    context.expect(caret_of(deck) == "False", "đang xem trước thì ô tên không có con trỏ");
    context.expect(std::ranges::contains(deck.hidden(), std::string_view("CreateRole_Info_Frame")), "khung mờ hẳn bị giấu");
}

bool has_window(const gui::GuiAsset& asset, std::string_view name) {
    const auto is_named = [name](const gui::GuiWindow& window) { return window.name == name; };
    return std::ranges::any_of(asset.windows, is_named);
}

// Mọi cửa sổ bảng đụng tới qua cả kịch bản phải có trong layout thật.
void names_exist_in_layout(Context& context) {
    if (kClientData.empty()) return;
    const std::filesystem::path root = std::filesystem::path(kClientData) / "Interface";
    gui::GuiSources sources;
    const gui::DiskSource files(root);
    sources.files = &files;
    auto loader = gui::GuiLoader::open(sources);
    context.expect(loader.has_value(), "mở được giao diện");
    if (!loader) return;
    context.expect(loader->add_layout(ui::panel::kCreateLayout).has_value(), "nạp được layout tạo");
    Run run = sample_run({0, 0, 0, 0, 0, 0, 0, 0});
    for (const Step step : kScript) step(run);
    Deck deck;
    ui::panel::paint_create(deck, run.panel);
    for (const gui::Override& item : deck.overrides()) {
        context.expect(has_window(loader->asset(), item.window), item.window);
    }
    for (const std::string_view window : deck.hidden()) {
        context.expect(has_window(loader->asset(), window), window);
    }
    for (const std::string_view window : deck.roots()) {
        context.expect(has_window(loader->asset(), window), window);
    }
}

constexpr std::array kCases{
    Case{.name = "port_matches_original_script", .body = &port_matches_original_script},
    Case{.name = "client_data_has_the_2026_spread", .body = &client_data_has_the_2026_spread},
    Case{.name = "cast_sorts_portraits_stably", .body = &cast_sorts_portraits_stably},
    Case{.name = "cast_keeps_faces_filters_hairs", .body = &cast_keeps_faces_filters_hairs},
    Case{.name = "cast_finds_high_poly_rows", .body = &cast_finds_high_poly_rows},
    Case{.name = "cast_reads_outfits", .body = &cast_reads_outfits},
    Case{.name = "cast_skips_broken_rows", .body = &cast_skips_broken_rows},
    Case{.name = "open_sets_the_first_choices", .body = &open_sets_the_first_choices},
    Case{.name = "sex_change_keeps_the_head_mark", .body = &sex_change_keeps_the_head_mark},
    Case{.name = "face_arrows_stop_at_hair_count", .body = &face_arrows_stop_at_hair_count},
    Case{.name = "arrows_skip_rows_without_names", .body = &arrows_skip_rows_without_names},
    Case{.name = "missing_outfit_row_leaves_the_text_empty", .body = &missing_outfit_row_leaves_the_text_empty},
    Case{.name = "random_uses_three_rolls_in_script_order", .body = &random_uses_three_rolls_in_script_order},
    Case{.name = "empty_cast_does_nothing_harmful", .body = &empty_cast_does_nothing_harmful},
    Case{.name = "create_without_a_head_asks_to_pick", .body = &create_without_a_head_asks_to_pick},
    Case{.name = "create_reports_the_chosen_portrait", .body = &create_reports_the_chosen_portrait},
    Case{.name = "locked_and_hidden_windows_ignore_presses", .body = &locked_and_hidden_windows_ignore_presses},
    Case{.name = "name_box_follows_the_layout_limit", .body = &name_box_follows_the_layout_limit},
    Case{.name = "hover_sets_the_description_line", .body = &hover_sets_the_description_line},
    Case{.name = "release_ends_what_was_held", .body = &release_ends_what_was_held},
    Case{.name = "names_are_translated", .body = &names_are_translated},
    Case{.name = "many_faces_grow_the_script_table", .body = &many_faces_grow_the_script_table},
    Case{.name = "paint_copies_the_state", .body = &paint_copies_the_state},
    Case{.name = "names_exist_in_layout", .body = &names_exist_in_layout},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_create_tests: mọi ca phải qua");
    return 0;
}
