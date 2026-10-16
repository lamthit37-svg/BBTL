// Nối bản dịch: ui_strings.lang.tsv phủ lên bảng gốc, bảng dữ liệu đi qua read_localized_table,
// dòng tên dự trữ không vào túi. Phủ glyph: mọi chữ Việt trong vi.tsv và dialogue.vi.txt có nét
// riêng trên VTNAM14.
#include "table/localize.hpp"
#include "table/tsv.hpp"
#include "test.hpp"
#include "ui/hud.hpp"
#include "ui/pace.hpp"
#include "ui/panel/npc_talk.hpp"
#include "gui/strings.hpp"
#include "ui/panel/skill_bar.hpp"

#include "core/check.hpp"
#include "core/text.hpp"

#include <array>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <optional>
#include <string>
#include <string_view>
#include <unordered_set>

namespace game::test {
namespace {

#ifdef GAME_CLIENT_DATA
constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
constexpr std::string_view kClientData;
#endif

#ifdef GAME_I18N_VI
constexpr std::string_view kVietnamese = GAME_I18N_VI;
#else
constexpr std::string_view kVietnamese;
#endif

#ifdef GAME_DIALOGUE_VI
constexpr std::string_view kDialogue = GAME_DIALOGUE_VI;
#else
constexpr std::string_view kDialogue;
#endif

void write_text(const std::filesystem::path& file, std::string_view text) {
    std::filesystem::create_directories(file.parent_path());
    std::ofstream out(file, std::ios::binary);
    core::check(out.good(), "ui_i18n_tests: mở được tệp mẫu");
    out.write(text.data(), static_cast<std::streamsize>(text.size()));
    core::check(out.good(), "ui_i18n_tests: ghi được tệp mẫu");
}

void strings_overlay_replaces_the_original(Context& context) {
    const std::filesystem::path root = std::filesystem::temp_directory_path() / "thienlong-ui-i18n-strings";
    std::filesystem::remove_all(root);
    write_text(root / "Table" / "ui_strings.tsv", "key\ttext\nHELLO\t你好\n");
    write_text(root / "Table" / "ui_strings.lang.tsv", "key\ttext\nHELLO\tXin chào\nONLY\tChỉ bản dịch\n");
    const gui::StringBook book = ui::strings_of(root);
    context.expect(book.find("HELLO") == "Xin chào", "bản dịch phủ chữ gốc");
    context.expect(book.find("ONLY") == "Chỉ bản dịch", "khoá chỉ có trong bản dịch vẫn vào");
    std::filesystem::remove_all(root);
}

void localized_table_replaces_the_name(Context& context) {
    const std::filesystem::path root = std::filesystem::temp_directory_path() / "thienlong-ui-i18n-items";
    std::filesystem::remove_all(root);
    const std::filesystem::path file = root / "items.tsv";
    write_text(file, "id\tname\n7\t青铜刀\n1\t未使用\n");
    write_text(root / "items.lang.tsv", "id\tcolumn\ttext\n7\tname\tĐao Thanh Đồng\n1\tname\tChưa Dùng\n");
    const std::optional<table::Tsv> table = ui::read_localized_table(file);
    context.expect(table.has_value(), "đọc được bảng đã dịch");
    if (!table) return;
    context.expect(table->rows.size() == 2 && table->rows[0][1] == "Đao Thanh Đồng", "tên vật phẩm là chữ Việt");
    ui::panel::ItemNames names;
    context.expect(names.load_table(*table, true), "nạp tên từ bảng đã dịch");
    context.expect(names.name(7) == "Đao Thanh Đồng", "túi thấy tên Việt");
    context.expect(names.name(1).empty(), "dòng dự trữ không vào túi");
    std::filesystem::remove_all(root);
}

void reserved_skill_name_is_dropped(Context& context) {
    const table::Tsv table = [] {
        table::TsvResult parsed = table::parse_tsv("id\tname\ticon\n3\t未使用\tA\n4\tĐả Cẩu\tB\n");
        core::check(parsed.has_value(), "ui_i18n_tests: bảng kỹ năng mẫu");
        return std::move(*parsed);
    }();
    ui::panel::SkillBook book;
    context.expect(book.load_table(table), "nạp sách kỹ năng");
    context.expect(book.name(3).empty(), "kỹ năng dự trữ không có tên");
    context.expect(book.name(4) == "Đả Cẩu", "kỹ năng thật giữ tên");
}

[[nodiscard]] bool is_vietnamese_letter(char32_t code) noexcept {
    if (code >= 0x1EA0 && code <= 0x1EF9) return true;
    if (code >= 0xC0 && code <= 0xFF) return code != 0xD7 && code != 0xF7;
    constexpr char32_t kSingles[] = {0x102, 0x103, 0x110, 0x111, 0x128, 0x129, 0x168, 0x169, 0x1A0, 0x1A1, 0x1AF, 0x1B0};
    for (const char32_t single : kSingles) {
        if (code == single) return true;
    }
    return false;
}

void collect_letters(std::string_view text, std::unordered_set<char32_t>& letters) {
    while (!text.empty()) {
        const core::Utf8Step step = core::utf8_step(text);
        if (step.length == 0) return;
        if (is_vietnamese_letter(step.code)) letters.insert(step.code);
        text.remove_prefix(step.length);
    }
}

void collect_file(const std::filesystem::path& file, std::unordered_set<char32_t>& letters) {
    std::ifstream in(file, std::ios::binary);
    if (!in) return;
    std::string line;
    while (std::getline(in, line)) {
        if (line.starts_with('#')) continue;
        const std::size_t tab = line.rfind('\t');
        const std::string_view value = tab == std::string::npos ? std::string_view{line} : std::string_view{line}.substr(tab + 1);
        collect_letters(value, letters);
    }
}

void vietnamese_letters_have_glyphs(Context& context) {
    if (kClientData.empty() || kVietnamese.empty()) return;
    const std::filesystem::path font_file = std::filesystem::path(kClientData) / "Interface" / "Schema" / "VTNAM14.bin";
    if (!std::filesystem::is_regular_file(font_file)) return;
    core::Result<ui::BitmapFont> font = ui::BitmapFont::open(font_file);
    context.expect(font.has_value(), "mở được VTNAM14");
    if (!font) return;
    std::unordered_set<char32_t> letters;
    collect_file(std::filesystem::path(kVietnamese), letters);
    collect_file(std::filesystem::path(kDialogue), letters);
    context.expect(!letters.empty(), "có chữ Việt để đo");
    std::size_t missing = 0;
    for (const char32_t code : letters) {
        if (!font->paints(code)) ++missing;
    }
    context.expect(missing == 0, "mọi chữ Việt có nét trên VTNAM14");
}

constexpr std::array kCases{
    Case{.name = "strings_overlay_replaces_the_original", .body = &strings_overlay_replaces_the_original},
    Case{.name = "localized_table_replaces_the_name", .body = &localized_table_replaces_the_name},
    Case{.name = "reserved_skill_name_is_dropped", .body = &reserved_skill_name_is_dropped},
    Case{.name = "vietnamese_letters_have_glyphs", .body = &vietnamese_letters_have_glyphs},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_i18n_tests: mọi ca phải qua");
    return 0;
}
