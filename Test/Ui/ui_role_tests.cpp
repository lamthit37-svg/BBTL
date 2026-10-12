// Sổ nhân vật cục bộ: thêm, trùng tên, đủ ba, xoá, TSV phiên bản 2 đi vòng kể cả chữ Việt và bộ đồ
// tân thủ, và tệp phiên bản 1 (chưa có ba ô trang phục) vẫn đọc được.
#include "ui/panel/roles.hpp"

#include "core/check.hpp"
#include "test.hpp"

#include <array>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::test {
namespace {

using ui::panel::Book;
using ui::panel::NameFault;
using ui::panel::Role;
using ui::panel::Roster;

Role named(std::string name) {
    Role role;
    role.name = std::move(name);
    role.face = 1;
    role.hair = 2;
    role.icon = "set:Face image:Girl 1";
    return role;
}

void add_keeps_order(Context& context) {
    Book book;
    context.expect(ui::panel::add_role(book, "acc", named("Mot")) == NameFault::kOk, "thêm được");
    context.expect(ui::panel::add_role(book, "acc", named("Hai")) == NameFault::kOk, "thêm người thứ hai");
    const Roster roster = ui::panel::roster_of(book, "acc");
    context.expect(roster.count == 2 && roster.roles[0].name == "Mot", "người đầu giữ chỗ");
    context.expect(roster.roles[1].name == "Hai" && roster.roles[1].sect == 9, "người sau và môn mới");
    context.expect(roster.roles[0].level == 1, "cấp mới là 1");
}

void duplicate_name_is_rejected(Context& context) {
    Book book;
    context.expect(ui::panel::add_role(book, "acc", named("Mot")) == NameFault::kOk, "lần đầu");
    context.expect(ui::panel::add_role(book, "acc", named("Mot")) == NameFault::kTaken, "trùng tên");
    context.expect(ui::panel::roster_of(book, "acc").count == 1, "không thêm bản trùng");
    context.expect(ui::panel::add_role(book, "khac", named("Mot")) == NameFault::kOk, "tài khoản khác được trùng tên");
}

void third_is_the_cap(Context& context) {
    Book book;
    context.expect(ui::panel::add_role(book, "acc", named("Mot")) == NameFault::kOk, "một");
    context.expect(ui::panel::add_role(book, "acc", named("Hai")) == NameFault::kOk, "hai");
    context.expect(ui::panel::add_role(book, "acc", named("Ba")) == NameFault::kOk, "ba");
    context.expect(ui::panel::add_role(book, "acc", named("Bon")) == NameFault::kFull, "đủ ba");
    context.expect(ui::panel::roster_of(book, "acc").count == 3, "vẫn ba người");
}

void delete_shifts_the_rest(Context& context) {
    Book book;
    static_cast<void>(ui::panel::add_role(book, "acc", named("Mot")));
    static_cast<void>(ui::panel::add_role(book, "acc", named("Hai")));
    static_cast<void>(ui::panel::add_role(book, "khac", named("Giu")));
    context.expect(ui::panel::erase_role(book, "acc", 0), "xoá người đầu");
    const Roster roster = ui::panel::roster_of(book, "acc");
    context.expect(roster.count == 1 && roster.roles[0].name == "Hai", "người sau dịch lên");
    context.expect(ui::panel::roster_of(book, "khac").roles[0].name == "Giu", "tài khoản kia không mất");
    context.expect(!ui::panel::erase_role(book, "acc", 3), "ô không có thì không xoá");
}

void names_follow_the_rules(Context& context) {
    Book book;
    context.expect(ui::panel::admit_name(book, "acc", "") == NameFault::kEmpty, "tên trống");
    context.expect(ui::panel::admit_name(book, "acc", "ten#") == NameFault::kBad, "dấu thăng");
    context.expect(ui::panel::admit_name(book, "acc", "1234567890123") == NameFault::kLong, "quá 12 chữ");
    context.expect(ui::panel::admit_name(book, "acc", "Huyền") == NameFault::kOk, "chữ Việt");
    context.expect(ui::panel::name_fault_text(NameFault::kTaken) == "#{Login_Create_Role_Name_Exist}", "câu trùng tên");
}

void round_trip_keeps_text(Context& context) {
    Book book;
    Role role = named("Huyền");
    role.sex = 1;
    role.portrait = 13;
    role.body = 438;
    role.arm = 444;
    role.foot = 441;
    context.expect(ui::panel::add_role(book, "acc", role) == NameFault::kOk, "thêm Huyền");
    const std::string text = ui::panel::encode_book(book);
    context.expect(text.starts_with("2\n"), "tệp ghi ra là phiên bản 2");
    context.expect(text.ends_with("\t438\t444\t441\n"), "ba ô trang phục đứng cuối dòng: áo, bao tay, giày");
    context.expect(!text.contains("matkhau"), "không ghi mật khẩu");
    context.expect(text.contains("Huyền"), "giữ tên");
    const std::optional<Book> back = ui::panel::decode_book(text);
    context.expect(back.has_value(), "đọc lại được");
    if (!back) return;
    const Roster roster = ui::panel::roster_of(*back, "acc");
    context.expect(roster.count == 1 && roster.roles[0] == role, "đúng người đã ghi");
    context.expect(ui::panel::roster_of(*back, "khac").count == 0, "không lẫn tài khoản");
}

void bad_file_is_selective(Context& context) {
    context.expect(!ui::panel::decode_book("3\nacc\t0\tMot\t0\t1\t2\t1\t9\t1\ticon\t0\t0\t0\n"), "sai phiên bản");
    context.expect(!ui::panel::decode_book("\n\n"), "không có dòng phiên bản");
    const std::string text = "1\nbad\nacc\t9\tMot\t0\t1\t2\t1\t9\t1\tset:Face image:Girl 1\n";
    const std::optional<Book> book = ui::panel::decode_book(text);
    context.expect(book.has_value(), "còn dòng đúng");
    if (!book) return;
    const Roster roster = ui::panel::roster_of(*book, "acc");
    context.expect(roster.count == 1 && roster.roles[0].name == "Mot", "bỏ dòng hỏng");
    context.expect(roster.roles[0].icon == "set:Face image:Girl 1", "ảnh có dấu cách");
}

// Tệp phiên bản 1 của bản trước: mười ô, nhân vật mặc bộ mặc định; ghi lại thì thành phiên bản 2.
void old_file_still_reads(Context& context) {
    const std::string old = "1\nacc\t0\tMot\t1\t100\t5\t1\t9\t13\tset:Face image:Man 1\n"
                            "acc\t1\tThua\t0\t1\t2\t1\t9\t1\ticon\t437\t443\t440\n";
    const std::optional<Book> book = ui::panel::decode_book(old);
    context.expect(book.has_value(), "đọc được tệp phiên bản 1");
    if (!book) return;
    const Roster roster = ui::panel::roster_of(*book, "acc");
    context.expect(roster.count == 1, "dòng mười ba ô trong tệp phiên bản 1 là dòng hỏng");
    const Role& role = roster.roles[0];
    context.expect(role.name == "Mot" && role.sex == 1 && role.face == 100 && role.hair == 5, "giữ ngoại hình cũ");
    context.expect(role.body == 0 && role.arm == 0 && role.foot == 0, "chưa có trang phục thì là bộ mặc định");
    const std::string again = ui::panel::encode_book(*book);
    context.expect(again == "2\nacc\t0\tMot\t1\t100\t5\t1\t9\t13\tset:Face image:Man 1\t0\t0\t0\n", "ghi lại thành phiên bản 2");
}

void new_file_checks_the_outfit_cells(Context& context) {
    const std::string text = "2\n"
                             "acc\t0\tThieu\t0\t1\t2\t1\t9\t1\ticon\n"
                             "acc\t0\tLon\t0\t1\t2\t1\t9\t1\ticon\t70000\t1\t1\n"
                             "acc\t0\tAm\t0\t1\t2\t1\t9\t1\ticon\t1\t-1\t1\n"
                             "acc\t0\tChu\t0\t1\t2\t1\t9\t1\ticon\t1\t1\tx\n"
                             "acc\t0\tThua\t0\t1\t2\t1\t9\t1\ticon\t1\t1\t1\t1\n"
                             "acc\t0\tDung\t0\t1\t2\t1\t9\t1\ticon\t65535\t0\t439\n";
    const std::optional<Book> book = ui::panel::decode_book(text);
    context.expect(book.has_value(), "đọc được tệp phiên bản 2");
    if (!book) return;
    const Roster roster = ui::panel::roster_of(*book, "acc");
    context.expect(roster.count == 1 && roster.roles[0].name == "Dung", "chỉ dòng đủ mười ba ô đúng miền được giữ");
    context.expect(roster.roles[0].body == 65535 && roster.roles[0].arm == 0 && roster.roles[0].foot == 439, "ba ô trang phục");
}

constexpr std::array<Case, 9> kCases{{
    {.name = "add_keeps_order", .body = &add_keeps_order},
    {.name = "duplicate_name_is_rejected", .body = &duplicate_name_is_rejected},
    {.name = "third_is_the_cap", .body = &third_is_the_cap},
    {.name = "delete_shifts_the_rest", .body = &delete_shifts_the_rest},
    {.name = "names_follow_the_rules", .body = &names_follow_the_rules},
    {.name = "round_trip_keeps_text", .body = &round_trip_keeps_text},
    {.name = "bad_file_is_selective", .body = &bad_file_is_selective},
    {.name = "old_file_still_reads", .body = &old_file_still_reads},
    {.name = "new_file_checks_the_outfit_cells", .body = &new_file_checks_the_outfit_cells},
}};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_role_tests: mọi ca phải qua");
    return 0;
}
