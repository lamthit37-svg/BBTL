#pragma once
// Kiểm bảng TSV của máy chủ và độ phủ tham chiếu. Module không mở tệp và không in: linttool đọc
// đĩa, đưa nguyên văn vào đây, rồi tự in kết quả.
// Một phiên nhận từng tệp một và đọc nó theo từng bản ghi. Sau feed phiên không giữ chữ của tệp:
// bộ nhớ của phiên là các ô trỏ và các khoá cha, không phải cây dữ liệu.

#include <cstddef>
#include <cstdint>
#include <memory>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::content {

// Một tệp đã đọc. path dùng dấu / và tính từ gốc đang kiểm.
struct TextFile {
    std::string_view path;
    std::string_view text;
};

// Một lỗi. line là số dòng trong tệp path, từ 1.
struct Issue {
    std::string path;
    std::size_t line = 0;
    std::string message;
};

// Một dòng của table_ref_coverage.tsv, đúng thứ tự cột của tệp đó.
struct CoverageRow {
    std::string child;
    std::string child_column;
    std::string parent;
    std::string parent_column;
    std::int64_t child_files = 0;
    std::int64_t child_rows = 0;
    std::int64_t references = 0;
    std::int64_t distinct_values = 0;
    std::int64_t missing_values = 0;
    std::int64_t missing_rows = 0;
    std::string first_missing;
};

// Năm số in cuối lần chạy.
struct LintStats {
    std::int64_t files = 0;
    std::int64_t records = 0;
    std::int64_t cells = 0;
    std::int64_t ref_rows = 0;
    std::int64_t errors = 0;
};

// issues là mọi lỗi, chưa cắt 20 dòng mỗi tệp. coverage theo thứ tự refs.
struct LintResult {
    std::vector<Issue> issues;
    std::vector<CoverageRow> coverage;
    LintStats stats;
};

using TextList = std::span<const TextFile>;

// files và refs đã sắp theo đường dẫn. Hàm không sắp lại hai danh sách đó.
struct LintSources {
    TextList files;
    TextList refs;
};

struct CoverageState;

// Phiên kiểm một cây: nạp refs lúc dựng, đưa từng tệp, rồi chốt.
class LintSession {
public:
    // Chữ của refs chỉ cần sống trong lời gọi này.
    explicit LintSession(TextList refs);
    ~LintSession();
    LintSession(LintSession&&) noexcept;
    LintSession& operator=(LintSession&&) noexcept;
    LintSession(const LintSession&) = delete;
    LintSession& operator=(const LintSession&) = delete;

    // Đưa một tệp dữ liệu. Hàm chép những gì còn cần; bên gọi bỏ chữ của tệp ngay sau đó được.
    void feed(const TextFile& file);

    // Chốt độ phủ và thống kê. Chỉ gọi một lần; sau đó phiên không còn dùng được.
    [[nodiscard]] LintResult finish();

private:
    std::unique_ptr<CoverageState> state_;
};

// Đọc sources.files theo luật trong sources.refs. Bản gói của một phiên, cho test nhỏ.
[[nodiscard]] LintResult lint_texts(const LintSources& sources);

// TSV độ phủ, kể cả dòng # schema và # types. Phần không bắt đầu bằng # là bảng độ phủ.
[[nodiscard]] std::string coverage_report(std::span<const CoverageRow> rows);

// Đuôi tệp .tsv, không phân biệt hoa thường.
[[nodiscard]] bool is_tsv_extension(std::string_view extension) noexcept;

// Đuôi của tệp theo hợp đồng bảng mà thienlong_lint đọc: .tsv, và .txt cho tệp chữ hai cột key, text
// (tables/server/dialogue.zh.txt; đuôi txt để nhà phát hành mở bằng trình soạn chữ chứ không phải Excel).
[[nodiscard]] bool is_table_extension(std::string_view extension) noexcept;

} // namespace game::content
