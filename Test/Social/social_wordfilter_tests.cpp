// Bộ lọc chữ cấm: gập chữ, bỏ ký tự chen, ranh giới cứng, từ có ký hiệu khớp nguyên văn, từ ASCII ngắn cần
// ranh giới cụm, mẫu dãy lớp ký tự, tên dành riêng, UTF-8 hỏng và văn bản quá dài. Sai thì chữ cấm lọt qua
// (hỏng thầm) hoặc câu vô tội bị che, nên mỗi ca nêu đầu vào và đầu ra mong đợi cụ thể.
#include "social/policy.hpp"
#include "social/wordfilter.hpp"
#include "test.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <string_view>
#include <utility>

namespace game::test {
namespace {

using social::FilterSources;
using social::NameKind;
using social::NamePolicy;
using social::WordFilter;

// Cột đọc theo vị trí: id, text, type (bảng thật có tên cột "int", "column_1", "column_2").
constexpr std::string_view kWords =
    "# schema 1\nid\ttext\ttype\n"
    "1\t江泽民\t1\n"
    "2\t辅*助\t1\n"
    "3\tfuck\t1\n"
    "4\tsb\t1\n"
    "5\t%江%泽%民%\t1\n"
    "6\tV\t1\n"
    "7\t系统\t2\n"
    "8\t少林\t3\n"
    "9\t[夕兮][a-zA-Z0-9\\s]*[巾今]\t11\n"
    "10\tass\t1\n"
    "11\tNPC\t2\n"
    "12\t[a\t11\n"
    "13\t六四\t1\n";

constexpr std::string_view kReserved =
    "# schema 1\nid\tkind\ttext\n"
    "1\tall\t中国\n"
    "2\tguild\t光明顶\n"
    "3\tteam\t队伍\n";

constexpr std::string_view kExtra =
    "# schema 1\nindex\tword\torigin\n"
    "1\t#666\tfilt\n"
    "2\tgm\tfilt\n";

std::unique_ptr<WordFilter> make(Context& context, std::string_view extra = {}) {
    auto filter = WordFilter::parse({.words_tsv = kWords, .reserved_tsv = kReserved, .extra_tsv = extra});
    context.expect(filter.has_value(), "bảng mẫu nạp được");
    if (!filter) return nullptr;
    return std::move(*filter);
}

void folding_and_separators(Context& context) {
    const auto filter = make(context);
    if (!filter) return;
    context.expect(filter->allowed("xin chào các bạn"), "câu vô tội qua");
    context.expect(!filter->allowed("江泽民万岁"), "từ cấm nguyên văn");
    context.expect(filter->mask("江泽民万岁") == "***万岁", "che đúng ba điểm mã");
    context.expect(!filter->allowed("江 泽 民"), "dấu cách chen giữa");
    context.expect(!filter->allowed("江·泽·民"), "chấm giữa chen giữa");
    context.expect(!filter->allowed("江​泽‍民"), "ký tự rộng-không chen giữa");
    context.expect(!filter->allowed("江_泽-民"), "gạch chen giữa");
    context.expect(filter->mask("江 泽 民!") == "*****!", "che cả đoạn chen giữa, giữ dấu câu sau");
    // Ranh giới cứng không bắc cầu: ba chữ rời nhau qua dấu câu hết câu không thành từ cấm.
    context.expect(filter->allowed("江，泽，民"), "dấu phẩy toàn góc là ranh giới");
    context.expect(filter->allowed("江。泽。民"), "dấu chấm CJK là ranh giới");
    context.expect(filter->allowed("江.泽.民"), "dấu chấm ASCII là ranh giới");
    context.expect(filter->allowed("六，四"), "hai chữ cách dấu phẩy không phải 六四");
    context.expect(!filter->allowed("六 四"), "hai chữ cách dấu cách là 六四");
    // Gập kiểu viết: chữ rộng, chữ hoa, chữ toán học, chữ khoanh tròn.
    context.expect(!filter->allowed("fuck"), "ASCII thường");
    context.expect(!filter->allowed("FUCK"), "chữ hoa");
    context.expect(!filter->allowed("ｆｕｃｋ"), "chữ rộng toàn góc");
    context.expect(!filter->allowed("𝐟𝐮𝐜𝐤"), "chữ toán học đậm");
    context.expect(!filter->allowed("ⓕⓤⓒⓚ"), "chữ khoanh tròn");
    context.expect(!filter->allowed("f u c k"), "dấu cách chen giữa chữ ASCII");
    context.expect(!filter->allowed("fuckyou"), "từ ASCII dài là chuỗi con");
    context.expect(filter->mask("a fuck b") == "a **** b", "che chữ ASCII");
}

void strict_words(Context& context) {
    const auto filter = make(context);
    if (!filter) return;
    context.expect(!filter->allowed("tôi muốn 辅*助 nhé"), "từ có dấu * khớp đúng dạng viết");
    context.expect(filter->allowed("辅助"), "không có dấu * thì không cấm (tác giả bảng chỉ cấm dạng có *)");
    context.expect(filter->allowed("辅 助"), "dấu cách không thay cho * trong từ có ký hiệu");
    context.expect(!filter->allowed("%江%泽%民%"), "từ có % khớp nguyên văn");
    context.expect(filter->mask("a辅*助b") == "a***b", "che từ có ký hiệu");
    context.expect(filter->allowed("V"), "từ một ký tự ASCII bị bỏ");
}

void short_ascii_words(Context& context) {
    const auto filter = make(context);
    if (!filter) return;
    context.expect(!filter->allowed("sb"), "'sb' đứng riêng");
    context.expect(!filter->allowed("you sb !"), "'sb' giữa hai dấu cách");
    context.expect(filter->allowed("sbd"), "'sb' dính vào chữ khác không bị cấm");
    context.expect(filter->allowed("xsb"), "'sb' dính phía trước không bị cấm");
    context.expect(!filter->allowed("ass"), "'ass' đứng riêng");
    context.expect(filter->allowed("class"), "'class' không dính 'ass'");
    context.expect(filter->allowed("passport"), "'passport' không dính 'ass'");
    context.expect(filter->allowed("a.ss"), "dấu chấm cắt cụm");
    context.expect(!filter->allowed("a ss"), "dấu cách không cắt cụm: a ss = ass");
}

void regex_rules(Context& context) {
    const auto filter = make(context);
    if (!filter) return;
    context.expect(!filter->allowed("夕今"), "hai lớp liền nhau");
    context.expect(!filter->allowed("夕abc 今"), "khe cho phép chữ-số-dấu cách");
    context.expect(!filter->allowed("兮x1今"), "lớp thứ nhất lấy ký tự khác");
    context.expect(filter->allowed("夕。今"), "dấu chấm CJK không nằm trong khe");
    context.expect(filter->allowed("夕"), "thiếu lớp cuối");
    context.expect(filter->allowed("今夕"), "sai thứ tự");
    context.expect(filter->mask("a夕12今b") == "a****b", "che đúng đoạn khớp mẫu");
    context.expect(filter->stats().regex_rules == 1, "một mẫu nạp được");
    context.expect(filter->stats().regex_skipped == 1, "mẫu '[a' sai cú pháp bị bỏ và đếm");
}

void reserved_names(Context& context) {
    const auto filter = make(context);
    if (!filter) return;
    context.expect(filter->reserved_name(NameKind::kCharacter, "系统"), "tên dành riêng type 2");
    context.expect(filter->reserved_name(NameKind::kCharacter, "系 统"), "bỏ ký tự chen");
    context.expect(filter->reserved_name(NameKind::kCharacter, "npc"), "không phân biệt hoa thường");
    context.expect(filter->reserved_name(NameKind::kCharacter, "中国"), "bảng all của full_compare");
    context.expect(!filter->reserved_name(NameKind::kCharacter, "系统公告"), "chỉ trùng nguyên tên");
    context.expect(!filter->reserved_name(NameKind::kCharacter, "少林"), "tên bang không cấm tên nhân vật");
    context.expect(filter->reserved_name(NameKind::kGuild, "少林"), "tên bang dành riêng type 3");
    context.expect(filter->reserved_name(NameKind::kGuild, "光明顶"), "bảng guild của full_compare");
    context.expect(filter->reserved_name(NameKind::kGuild, "系统"), "tên bang cũng dùng bảng all");
    context.expect(!filter->reserved_name(NameKind::kCharacter, "光明顶"), "bảng guild không áp cho nhân vật");
    context.expect(filter->reserved_name(NameKind::kTeam, "队伍"), "bảng team");
    context.expect(!filter->reserved_name(NameKind::kGuild, "队伍"), "bảng team không áp cho bang");
    const NamePolicy guild_names(*filter, NameKind::kGuild);
    context.expect(!guild_names.allowed("少林"), "NamePolicy từ chối tên dành riêng");
    context.expect(!guild_names.allowed("江泽民"), "NamePolicy từ chối chữ cấm");
    context.expect(guild_names.allowed("Thiên Long"), "NamePolicy cho tên thường");
    const social::TextPolicy& as_policy = guild_names;
    context.expect(as_policy.allowed("Bắc Cái"), "qua giao diện TextPolicy");
    context.expect(filter->stats().reserved_names == 6, "sáu tên dành riêng (2 type 2 + 1 type 3 + 3 full_compare)");
}

void hostile_input(Context& context) {
    const auto filter = make(context);
    if (!filter) return;
    context.expect(!filter->allowed("\xff\xfe江泽民"), "byte UTF-8 hỏng không che từ cấm theo sau");
    context.expect(filter->mask("\xff江泽民") == "\xff***", "byte hỏng giữ nguyên, từ cấm vẫn bị che");
    context.expect(filter->allowed("\xE6\xB1"), "chuỗi cụt không làm hỏng");
    context.expect(filter->mask("江泽\xE6\xB0") == "江泽\xE6\xB0", "đuôi cụt giữ nguyên");
    context.expect(filter->allowed(""), "chuỗi rỗng");
    context.expect(filter->mask("").empty(), "mask rỗng");
    const std::string big(WordFilter::kMaxScanBytes + 1, 'a');
    context.expect(!filter->allowed(big), "văn bản quá cỡ quét bị từ chối");
    const std::string masked = filter->mask(big);
    context.expect(masked.size() == big.size() && masked.back() == '*' && masked.front() == 'a', "đuôi chưa quét bị che hết");
    const std::string zeros(WordFilter::kMaxScanBytes, '\0');
    context.expect(filter->allowed(zeros), "byte NUL không làm hỏng");
    const std::string spaces(WordFilter::kMaxScanBytes, ' ');
    context.expect(filter->allowed(spaces), "toàn dấu cách");
}

void extra_table(Context& context) {
    const auto filter = make(context, kExtra);
    if (!filter) return;
    context.expect(!filter->allowed("hello #666"), "từ cấm thêm của máy chủ chứa ký hiệu: nguyên văn");
    context.expect(filter->allowed("hello 666"), "không có # thì không cấm");
    context.expect(!filter->allowed("gm"), "'gm' ASCII ngắn đứng riêng");
    context.expect(filter->allowed("gmail"), "'gm' dính vào chữ khác không bị cấm");
    context.expect(filter->stats().strict_words == 3, "ba từ khớp nguyên văn: 辅*助, %江%泽%民%, #666");
}

// Chỉ bảng từ, hai bảng còn lại rỗng.
FilterSources words_only(std::string_view words) { return {.words_tsv = words, .reserved_tsv = {}, .extra_tsv = {}}; }

void bad_tables(Context& context) {
    const auto too_narrow = WordFilter::parse(words_only("# schema 1\nid\ttext\n1\ta\n"));
    context.expect(!too_narrow.has_value(), "bảng thiếu cột type");
    const auto bad_type = WordFilter::parse(words_only("# schema 1\nid\ttext\ttype\n1\tabc\tx\n"));
    context.expect(!bad_type.has_value(), "type không phải số");
    const auto bad_kind = WordFilter::parse({.words_tsv = kWords, .reserved_tsv = "# schema 1\nid\tkind\ttext\n1\tzzz\tabc\n", .extra_tsv = {}});
    context.expect(!bad_kind.has_value(), "loại tên lạ");
    const auto ragged = WordFilter::parse(words_only("# schema 1\nid\ttext\ttype\n1\tabc\n"));
    context.expect(!ragged.has_value(), "dòng thiếu ô");
    const auto empty_ok = WordFilter::parse(words_only("# schema 1\nid\ttext\ttype\n"));
    context.expect(empty_ok.has_value() && (*empty_ok)->allowed("bất kỳ"), "bảng không dòng nào: cho qua mọi chữ");
    const auto unknown_type = WordFilter::parse(words_only("# schema 1\nid\ttext\ttype\n1\tabcd\t99\n"));
    context.expect(unknown_type.has_value() && (*unknown_type)->allowed("abcd"), "type lạ bị bỏ, không làm hỏng bảng");
}

// 145 nghìn từ giả (xorshift tất định) để thấy bộ khớp dựng và quét được ở cỡ bảng thật.
void at_table_scale(Context& context) {
    std::string tsv = "# schema 1\nid\ttext\ttype\n";
    std::uint64_t state = 0x9E3779B97F4A7C15ULL;
    const auto next = [&state]() {
        state ^= state << 13U;
        state ^= state >> 7U;
        state ^= state << 17U;
        return state;
    };
    const auto append_codepoint = [](std::string& out, std::uint64_t value) {
        const auto cp = static_cast<char32_t>(0x4E00U + (value % 20'000U));
        out.push_back(static_cast<char>(0xE0U | (cp >> 12U)));
        out.push_back(static_cast<char>(0x80U | ((cp >> 6U) & 0x3FU)));
        out.push_back(static_cast<char>(0x80U | (cp & 0x3FU)));
    };
    constexpr std::size_t kWordsCount = 145'000;
    for (std::size_t index = 0; index < kWordsCount; ++index) {
        tsv += std::to_string(index + 1) + "\t";
        const std::size_t length = 2 + (next() % 5U);
        for (std::size_t at = 0; at < length; ++at) append_codepoint(tsv, next());
        tsv += "\t1\n";
    }
    tsv += "145001\t天龙专用禁词\t1\n";
    const auto filter = WordFilter::parse(words_only(tsv));
    context.expect(filter.has_value(), "bảng cỡ thật nạp được");
    if (!filter) return;
    const WordFilter& built = **filter;
    context.expect(built.stats().loose_words > 140'000, "gần đủ 145 nghìn từ sau khi bỏ trùng");
    context.expect(!built.allowed("xin chào 天龙专用禁词 bạn"), "tìm thấy từ gài giữa 145 nghìn từ");
    context.expect(built.allowed("xin chào các bạn, hôm nay trời đẹp quá"), "câu Latin không dính từ giả");
    std::size_t flagged = 0;
    for (std::size_t line = 0; line < 200; ++line) {
        std::string text;
        for (std::size_t at = 0; at < 60; ++at) append_codepoint(text, next());
        if (!built.allowed(text)) ++flagged;
    }
    // Không đòi số cụ thể (ngẫu nhiên), chỉ đòi quét xong và đếm được; tránh test hỏng thầm khi bộ khớp treo.
    context.expect(flagged <= 200, "quét 200 dòng ngẫu nhiên xong");
}

constexpr std::array kCases{
    Case{.name = "folding_and_separators", .body = folding_and_separators},
    Case{.name = "strict_words", .body = strict_words},
    Case{.name = "short_ascii_words", .body = short_ascii_words},
    Case{.name = "regex_rules", .body = regex_rules},
    Case{.name = "reserved_names", .body = reserved_names},
    Case{.name = "hostile_input", .body = hostile_input},
    Case{.name = "extra_table", .body = extra_table},
    Case{.name = "bad_tables", .body = bad_tables},
    Case{.name = "at_table_scale", .body = at_table_scale},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
