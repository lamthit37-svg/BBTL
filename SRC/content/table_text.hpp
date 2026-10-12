#pragma once
// Việc đọc một bảng TSV theo dòng: phần đầu tệp (schema, kiểu, tên cột), hình dạng các dòng, rồi
// từng bản ghi. Bảng không được dựng trong bộ nhớ: mỗi bản ghi là các view vào chữ của tệp, nên
// bộ nhớ của một lần kiểm không phụ thuộc số ô của bảng lớn nhất.
// Quy tắc dòng trùng table::parse_tsv, bộ đọc mà máy chủ sẽ dùng: dòng rỗng và dòng bắt đầu bằng #
// bị bỏ, dòng đầu còn lại là tên cột, mọi bản ghi đủ số ô. content_tests giữ hai bên khớp nhau.

#include "content/detail/scan.hpp"
#include "content/lint.hpp"

#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <vector>

namespace game::content {

struct Preamble {
    int schemas = 0;
    int types = 0;
    std::size_t schema_line = 1;
    std::size_t types_line = 1;
    std::string type_text;
    bool saw_header = false;
};

void read_preamble(Preamble& preamble, TextView text);

// false khi thiếu hoặc lặp dòng schema hay dòng types. Lỗi đã ghi.
[[nodiscard]] bool preamble_ok(const Preamble& preamble, TextView path, IssueList& issues);

// Phần đầu của một bảng. Mọi view trỏ vào chữ của tệp.
struct TableHead {
    std::vector<TextView> columns;
    // Kiểu từng cột theo dòng # types; rỗng khi dòng đó sai số cột.
    std::vector<TextView> types;
    // Chỗ bắt đầu của dòng ngay sau dòng tên cột.
    LinePlace body;
    bool is_readable = false;
};

// Kiểm K1 và K2 của một tệp: byte, schema, kiểu, tên cột, mọi dòng đủ số ô. is_readable false thì
// tệp không dùng được, lỗi đã ghi và không bản ghi nào của nó được đọc.
[[nodiscard]] TableHead read_head(const TextFile& file, IssueList& issues);

// Một bản ghi. cells chỉ sống tới lời gọi next kế tiếp của bộ đọc đã trả nó.
struct Record {
    std::span<const TextView> cells;
    std::size_t line = 0;
};

// Duyệt các bản ghi của một bảng đã qua read_head, hai lượt trên cùng thân bảng: trước là các dòng
// thường theo thứ tự trong tệp, sau là các dòng có ô đầu bắt đầu bằng #. parse_tsv coi dòng # là
// chú thích và nuốt mất bản ghi, nên mỗi dòng như vậy là một lỗi và vẫn được đọc như bản ghi.
class RecordReader {
public:
    // file và head phải sống lâu hơn bộ đọc.
    RecordReader(const TextFile& file, const TableHead& head) noexcept;

    // false khi hết bản ghi của cả hai lượt.
    [[nodiscard]] bool next(Record& record, IssueList& issues);

private:
    enum class Pass : std::uint8_t { kPlain, kHash };

    [[nodiscard]] bool take_line(Record& record, IssueList& issues);
    void end_pass() noexcept;

    TextView path_;
    TextView text_;
    const TableHead* head_ = nullptr;
    LinePlace place_;
    Pass pass_ = Pass::kPlain;
    bool is_done_ = false;
    std::vector<TextView> cells_;
};

enum class CellKind : std::uint8_t { kOther, kInt, kFloat };

// K3 của một bảng: ô int là số nguyên chính tắc vừa int32, ô float là số thực hữu hạn chính tắc.
class CellChecker {
public:
    // file, head và issues phải sống lâu hơn bộ kiểm.
    CellChecker(const TextFile& file, const TableHead& head, IssueList& issues);

    void check(const Record& record);

private:
    void check_cell(const Record& record, std::size_t column);

    TextView path_;
    std::span<const TextView> columns_;
    std::vector<CellKind> kinds_;
    IssueList* issues_ = nullptr;
};

} // namespace game::content
