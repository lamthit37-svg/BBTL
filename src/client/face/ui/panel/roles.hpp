// Danh sách nhân vật cục bộ của thủ tục đăng nhập, thay phần máy chủ chưa có. Một tài khoản giữ
// tối đa ba nhân vật, đúng trần của SelectRole.lua. Tệp là TSV phiên bản 2: dòng đầu "2", mỗi dòng
// sau là một nhân vật (tài khoản, ô, tên, giới, mặt, tóc, cấp, môn phái, chân dung, ảnh, áo, bao
// tay, giày). Ảnh chân dung có dấu cách, không có tab. Mật khẩu không nằm trong tệp. Tệp phiên bản
// 1 (dòng đầu "1", mười ô, chưa có ba ô trang phục) vẫn đọc được: nhân vật của nó mặc bộ mặc định;
// lần ghi kế chuyển tệp sang phiên bản 2.
// Khác gốc: chưa có danh sách tên cấm của máy chủ; tên trùng chỉ so đúng từng ký tự trên cùng tài
// khoản. Nhân vật mới là cấp 1, môn phái 9 (chưa nhập môn), như CreateRole của client 2026.
#pragma once

#include <array>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui::panel {

inline constexpr std::size_t kRoleCap = 3;
inline constexpr std::size_t kNameLimit = 12;
inline constexpr std::uint8_t kNewSect = 9;
inline constexpr std::int32_t kNewLevel = 1;

// Một nhân vật đã lưu. Giới 0 là nữ, 1 là nam, cùng look::Race. face và hair là id bảng ngoại hình;
// body, arm, foot là id hình trang phục của áo, bao tay, giày (bộ đồ tân thủ chọn lúc tạo), 0 là bộ
// mặc định của giới.
struct Role {
    std::string name;
    std::uint8_t sex = 0;
    std::uint16_t face = 0;
    std::uint16_t hair = 0;
    std::uint16_t body = 0;
    std::uint16_t arm = 0;
    std::uint16_t foot = 0;
    std::int32_t level = kNewLevel;
    std::uint8_t sect = kNewSect;
    std::int32_t portrait = 1;
    std::string icon;
    // Id nhân vật do máy chủ cấp (CharacterSummary::id); 0 với nhân vật của sổ cục bộ. Không ghi vào tệp sổ.
    std::uint64_t id = 0;

    friend bool operator==(const Role&, const Role&) = default;
};

// Một dòng của sổ: nhân vật thuộc tài khoản nào.
struct StoredRole {
    std::string account;
    Role role;
};

// Mọi tài khoản trong một tệp, theo thứ tự ghi.
struct Book {
    std::vector<StoredRole> rows;
};

// Tối đa ba nhân vật của một tài khoản, theo thứ tự trong sổ.
struct Roster {
    std::array<Role, kRoleCap> roles{};
    std::uint8_t count = 0;
};

// Lý do một tên không được tạo. kOk là tên dùng được.
enum class NameFault : std::uint8_t { kOk, kEmpty, kLong, kBad, kTaken, kFull };

// Nhân vật của account trong book, tối đa ba, theo thứ tự sổ.
[[nodiscard]] Roster roster_of(const Book& book, std::string_view account);
// Tên name có được thêm cho account không. Không sửa book.
[[nodiscard]] NameFault admit_name(const Book& book, std::string_view account, std::string_view name);
// Câu tiếng Việt của fault; rỗng khi tên dùng được.
[[nodiscard]] std::string_view name_fault_text(NameFault fault) noexcept;
// Thêm role vào cuối account. Không thêm khi tên không được nhận; trả lý do.
[[nodiscard]] NameFault add_role(Book& book, std::string_view account, const Role& role);
// Xoá nhân vật thứ index của account (0 là nhân vật đầu). Không có thì không đổi gì.
[[nodiscard]] bool erase_role(Book& book, std::string_view account, std::uint8_t index);
// Sổ thành chữ TSV phiên bản 2, kết thúc bằng dấu xuống dòng nếu có dòng.
[[nodiscard]] std::string encode_book(const Book& book);
// Đọc sổ phiên bản 2, hoặc phiên bản 1 (mười ô, trang phục về bộ mặc định). Không có khi dòng
// phiên bản khác hai số đó. Dòng hỏng bị bỏ, dòng đúng được giữ.
[[nodiscard]] std::optional<Book> decode_book(std::string_view text);

} // namespace game::ui::panel
