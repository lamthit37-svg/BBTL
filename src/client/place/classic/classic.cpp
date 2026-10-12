// Đọc extras.ogre bằng một bộ quét JSON tối thiểu: chỉ cần tìm khoá trong object, đọc chuỗi và
// nhảy qua giá trị không dùng. Dữ liệu là tệp ngoài nên mọi bước đều kiểm biên; JSON hỏng thì
// dừng ở chỗ hỏng và trả phần đã đọc được hoặc không có gì, không bao giờ đọc ra ngoài chuỗi.
// Chuỗi cần dùng (từ khoá, số, tên template) đều là ASCII không có ký tự thoát; chuỗi khác (bản
// chép script, có chữ Hán) chỉ được nhảy qua.
#include "classic/classic.hpp"

#include "core/number.hpp"
#include "math/types.hpp"

#include <array>
#include <cstddef>
#include <optional>
#include <string_view>

namespace game::classic {
namespace {

using OptionalText = std::optional<std::string_view>;

struct Cursor {
    std::string_view text;
    std::size_t at = 0;
};

[[nodiscard]] bool is_space(char letter) noexcept {
    return letter == ' ' || letter == '\n' || letter == '\r' || letter == '\t';
}

// Ký tự đang đứng; 0 khi đã hết chuỗi.
[[nodiscard]] char peek(const Cursor& cursor) noexcept {
    if (cursor.at >= cursor.text.size()) return '\0';
    return cursor.text[cursor.at];
}

void skip_space(Cursor& cursor) noexcept {
    while (is_space(peek(cursor))) {
        ++cursor.at;
    }
}

// Phần giữa hai dấu nháy của chuỗi đang đứng (ký tự thoát để nguyên); không có khi con trỏ không
// đứng ở dấu nháy hoặc chuỗi không đóng.
[[nodiscard]] OptionalText take_string(Cursor& cursor) noexcept {
    if (peek(cursor) != '"') return std::nullopt;
    const std::size_t start = cursor.at + 1;
    std::size_t stop = start;
    while (stop < cursor.text.size() && cursor.text[stop] != '"') {
        stop += cursor.text[stop] == '\\' ? std::size_t{2} : std::size_t{1};
    }
    if (stop >= cursor.text.size()) return std::nullopt;
    cursor.at = stop + 1;
    return cursor.text.substr(start, stop - start);
}

[[nodiscard]] bool ends_scalar(char letter) noexcept {
    return letter == ',' || letter == '}' || letter == ']' || letter == '\0' || is_space(letter);
}

// Số, true, false, null: chạy tới dấu ngăn kế tiếp.
[[nodiscard]] bool skip_scalar(Cursor& cursor) noexcept {
    const std::size_t start = cursor.at;
    while (!ends_scalar(peek(cursor))) {
        ++cursor.at;
    }
    return cursor.at > start;
}

// Một bước trong object hoặc mảng lồng: chuỗi được nhảy trọn, ngoặc đổi độ sâu.
[[nodiscard]] bool step_nested(Cursor& cursor, int& depth) noexcept {
    const char letter = peek(cursor);
    if (letter == '"') return take_string(cursor).has_value();
    if (letter == '{' || letter == '[') ++depth;
    if (letter == '}' || letter == ']') --depth;
    ++cursor.at;
    return true;
}

// Con trỏ đứng ở ngoặc mở: chạy tới hết ngoặc đóng tương ứng. Sai khi chuỗi hết trước đó.
[[nodiscard]] bool skip_nested(Cursor& cursor) noexcept {
    int depth = 0;
    bool is_sound = step_nested(cursor, depth);
    while (is_sound && depth > 0 && cursor.at < cursor.text.size()) {
        is_sound = step_nested(cursor, depth);
    }
    return is_sound && depth == 0;
}

[[nodiscard]] bool skip_value(Cursor& cursor) noexcept {
    skip_space(cursor);
    const char letter = peek(cursor);
    if (letter == '"') return take_string(cursor).has_value();
    if (letter == '{' || letter == '[') return skip_nested(cursor);
    return skip_scalar(cursor);
}

// Tên của thành viên kế tiếp trong object, con trỏ dừng ở giá trị của nó; không có khi object đã
// hết hoặc JSON hỏng.
[[nodiscard]] OptionalText next_name(Cursor& cursor) noexcept {
    skip_space(cursor);
    if (peek(cursor) == ',') ++cursor.at;
    skip_space(cursor);
    const OptionalText name = take_string(cursor);
    if (!name) return std::nullopt;
    skip_space(cursor);
    if (peek(cursor) != ':') return std::nullopt;
    ++cursor.at;
    skip_space(cursor);
    return name;
}

// Tên của thành viên đứng sau giá trị đang đứng; không có khi giá trị ấy hỏng hoặc object hết.
[[nodiscard]] OptionalText name_after(Cursor& cursor) noexcept {
    if (!skip_value(cursor)) return std::nullopt;
    return next_name(cursor);
}

// Con trỏ đứng trước một object: đưa nó tới giá trị của khoá key. Sai khi không có khoá đó.
[[nodiscard]] bool enter_member(Cursor& cursor, std::string_view key) noexcept {
    skip_space(cursor);
    if (peek(cursor) != '{') return false;
    ++cursor.at;
    OptionalText name = next_name(cursor);
    while (name && *name != key) {
        name = name_after(cursor);
    }
    return name.has_value();
}

constexpr std::size_t kMostNumbers = 5;

struct Numbers {
    std::array<float, kMostNumbers> values{};
    std::size_t count = 0;
};

void skip_blanks(std::string_view& rest) noexcept {
    while (!rest.empty() && rest.front() == ' ') {
        rest.remove_prefix(1);
    }
}

// Một số ở đầu rest vào bảng; sai khi rest không mở đầu bằng số.
[[nodiscard]] bool take_number(Numbers& numbers, std::string_view& rest) noexcept {
    skip_blanks(rest);
    const core::OptionalDouble parsed = core::parse_double(rest);
    if (!parsed) return false;
    numbers.values.at(numbers.count) = static_cast<float>(parsed->value);
    ++numbers.count;
    rest.remove_prefix(parsed->length);
    return true;
}

// Các số cách nhau bằng dấu cách ở đầu text, tối đa kMostNumbers.
[[nodiscard]] Numbers numbers_of(std::string_view text) noexcept {
    Numbers numbers;
    std::string_view rest = text;
    while (numbers.count < kMostNumbers && take_number(numbers, rest)) {
    }
    return numbers;
}

[[nodiscard]] math::Float3 rgb_of(const Numbers& numbers) noexcept {
    return {.x = numbers.values[0], .y = numbers.values[1], .z = numbers.values[2]};
}

void set_ambient(Classic& classic, std::string_view value) noexcept {
    if (value.starts_with("vertexcolour")) classic.tracks_vertex = true;
    const Numbers numbers = numbers_of(value);
    if (numbers.count >= 3) classic.ambient = rgb_of(numbers);
}

void set_diffuse(Classic& classic, std::string_view value) noexcept {
    if (value.starts_with("vertexcolour")) classic.tracks_vertex = true;
    const Numbers numbers = numbers_of(value);
    if (numbers.count < 3) return;
    const math::Float3 rgb = rgb_of(numbers);
    const float alpha = numbers.count >= 4 ? numbers.values[3] : 1.0F;
    classic.diffuse = {.x = rgb.x, .y = rgb.y, .z = rgb.z, .w = alpha};
}

void set_emissive(Classic& classic, std::string_view value) noexcept {
    const Numbers numbers = numbers_of(value);
    if (numbers.count >= 3) classic.emissive = rgb_of(numbers);
}

// Ogre: "specular r g b shininess" hoặc "specular r g b a shininess".
void set_specular(Classic& classic, std::string_view value) noexcept {
    const Numbers numbers = numbers_of(value);
    if (numbers.count < 4) return;
    classic.specular = rgb_of(numbers);
    classic.shininess = numbers.values.at(numbers.count - 1);
}

void set_lighting(Classic& classic, std::string_view value) noexcept {
    if (value.starts_with("off")) classic.lit = Lit::kOff;
    if (value.starts_with("on")) classic.lit = Lit::kVertex;
    if (value.starts_with("on pslit")) classic.lit = Lit::kPixel;
}

// "true" một mình hoặc "true none": pass tắt sương. Kiểu sương riêng của pass chưa đọc.
void set_fog(Classic& classic, std::string_view value) noexcept {
    if (value == "true" || value == "true none") classic.has_fog = false;
}

// Một dòng của pass: từ khoá và phần còn lại của dòng.
struct Setting {
    std::string_view name;
    std::string_view value;
};

void apply_setting(Classic& classic, Setting setting) noexcept {
    if (setting.name == "ambient") set_ambient(classic, setting.value);
    if (setting.name == "diffuse") set_diffuse(classic, setting.value);
    if (setting.name == "emissive") set_emissive(classic, setting.value);
    if (setting.name == "specular") set_specular(classic, setting.value);
    if (setting.name == "lighting") set_lighting(classic, setting.value);
    if (setting.name == "fog_override") set_fog(classic, setting.value);
}

// Một thành viên của settings; sai khi object đã hết hoặc hỏng.
[[nodiscard]] bool take_setting(Cursor& cursor, Classic& classic) noexcept {
    const OptionalText name = next_name(cursor);
    if (!name) return false;
    if (peek(cursor) != '"') return skip_value(cursor);
    const OptionalText value = take_string(cursor);
    if (!value) return false;
    const Setting setting{.name = *name, .value = *value};
    apply_setting(classic, setting);
    return true;
}

void read_settings(Cursor cursor, Classic& classic) noexcept {
    if (!enter_member(cursor, "settings")) return;
    if (peek(cursor) != '{') return;
    ++cursor.at;
    while (take_setting(cursor, classic)) {
    }
}

struct TemplateOp {
    std::string_view name;
    TexOp combine = TexOp::kModulate;
};

// Template có BLEND_OP_0 khác 0 trong Character.program (dùng Model_ps.hlsl hoặc
// Model_2Tex_ps.hlsl). Họ ColourChangable (BLEND_OP_0=3) nhận theo đoạn tên chung.
constexpr std::array<TemplateOp, 7> kTemplateOps{{
    {.name = "Mtl_Character_ColorX2", .combine = TexOp::kModulate2},
    {.name = "Mtl_Character_Frozen", .combine = TexOp::kModulate2},
    {.name = "Mtl_Model_TwoTex_Tex1_ColorX2", .combine = TexOp::kModulate2},
    {.name = "Mtl_Outline_TwoTex_Tex1_ColorX2", .combine = TexOp::kModulate2},
    {.name = "Mtl_Character_ColorX4", .combine = TexOp::kModulate4},
    {.name = "Mtl_Model_TwoTex_Tex1_ColorX4", .combine = TexOp::kModulate4},
    {.name = "Mtl_Model_TwoTex_Tex1_ColorX4_Tex2_ColorX4", .combine = TexOp::kModulate4},
}};

void apply_template(Classic& classic, const TemplateOp& entry, std::string_view parent) noexcept {
    if (entry.name == parent) classic.combine = entry.combine;
}

void apply_parent(Classic& classic, std::string_view parent) noexcept {
    if (parent.contains("ColourChangable")) classic.combine = TexOp::kAdd;
    for (const TemplateOp& entry : kTemplateOps) {
        apply_template(classic, entry, parent);
    }
}

// Một phần tử của mảng parents; sai khi mảng đã hết hoặc hỏng.
[[nodiscard]] bool take_parent(Cursor& cursor, Classic& classic) noexcept {
    skip_space(cursor);
    if (peek(cursor) == ',') ++cursor.at;
    skip_space(cursor);
    const OptionalText parent = take_string(cursor);
    if (!parent) return false;
    apply_parent(classic, *parent);
    return true;
}

void read_parents(Cursor cursor, Classic& classic) noexcept {
    if (!enter_member(cursor, "parents")) return;
    if (peek(cursor) != '[') return;
    ++cursor.at;
    while (take_parent(cursor, classic)) {
    }
}

} // namespace

std::optional<Classic> read_classic(std::string_view extras) {
    Cursor cursor;
    cursor.text = extras;
    if (!enter_member(cursor, "ogre")) return std::nullopt;
    skip_space(cursor);
    if (peek(cursor) != '{') return std::nullopt;
    Classic classic;
    read_settings(cursor, classic);
    read_parents(cursor, classic);
    return classic;
}

} // namespace game::classic
