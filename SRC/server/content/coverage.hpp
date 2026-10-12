#pragma once
// Việc đếm độ phủ: với mỗi tệp, tìm các cột mà dòng refs cần (cột con gom ô trỏ, cột cha gom
// khoá), nhận từng bản ghi, rồi chốt bảng coverage khi mọi tệp đã qua.

#include "content/detail/order.hpp"
#include "content/lint.hpp"
#include "content/ref_rule.hpp"

#include <cstddef>
#include <cstdint>
#include <map>
#include <set>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::content {

struct Record;
struct TableHead;

struct TypeClash {
    std::string path;
    std::string type;
};

struct ChildTotals {
    std::int64_t files = 0;
    std::int64_t rows = 0;
    std::vector<RefPair> refs;
    std::string type;
    bool typed = false;
    std::vector<TypeClash> clashes;
};

struct KeySet {
    std::set<std::string, std::less<>> values;
    std::string type;
    bool typed = false;
    bool scanned = false;
};

// Trạng thái sống suốt phiên. Chữ từng tệp không nằm ở đây.
struct CoverageState {
    std::vector<RefRule> rules;
    std::vector<ChildTotals> children;
    std::vector<std::int64_t> parent_files;
    std::map<std::pair<std::string, std::string>, KeySet> keys;
    std::vector<Issue> issues;
    std::vector<CoverageRow> coverage;
    LintStats stats;
};

// Một cột của tệp đang đọc mà dòng refs thứ rule cần tới.
struct ColumnTap {
    std::size_t rule = 0;
    std::size_t column = 0;
    // Cột cha: nơi gom khoá, nằm trong CoverageState::keys. nullptr là cột con.
    KeySet* keys = nullptr;
    // Cột con: phần * của đường dẫn tệp; rỗng khi mẫu cha không có *.
    std::string capture;
};

// Mọi cột cần theo dõi của một tệp.
struct TapList {
    std::vector<ColumnTap> columns;
    // Các dòng refs nhận tệp này làm con, kể cả khi tệp thiếu cột: số bản ghi của tệp vẫn cộng
    // vào child_rows của dòng đó.
    std::vector<std::size_t> child_rules;
};

// Việc theo dõi một tệp đang đọc, dựng một lần ở đầu tệp. state và file phải sống lâu hơn nó.
class TableTaps {
public:
    // Tìm các cột dòng refs cần ở tệp này; ghi lỗi khi tệp khớp mẫu mà thiếu cột.
    TableTaps(CoverageState& state, const TextFile& file, const TableHead& head);

    // Đưa một bản ghi của tệp vào các cột đang theo dõi.
    void take(const Record& record);

    // Hết tệp: records là số bản ghi của nó.
    void close(std::int64_t records);

private:
    void take_cell(const ColumnTap& tap, const Record& record);

    CoverageState* state_ = nullptr;
    std::string_view path_;
    TapList list_;
};

// Mọi tệp đã qua: so con với cha, dựng bảng coverage.
void finish_coverage(CoverageState& state);

} // namespace game::content
