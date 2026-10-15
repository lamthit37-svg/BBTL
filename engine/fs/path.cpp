/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/fs/path.cpp
 *  PHÂN HỆ   : Fs / Path
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt fs/path.hpp.
 *  - Chuẩn hoá theo từng đoạn thay cho con trỏ chạy lùi của
 *    fsNormalizePathContinue (gốc lùi con trỏ tới trước đầu bộ đệm và lấy
 *    UINTPTR_MAX làm cuối bộ đệm, cả hai là UB). Kết quả trùng gốc trên mọi
 *    đường dẫn tương đối; bài đo bench/fs đối chiếu hai bản trên cùng bộ mẫu.
 *  - Nguồn: Forge2 src/fs/path.cpp@d7fcd76. Khác gốc (so với Forge2): check là
 *    bản của THIENLONG; thân vòng lặp của resolve tách thành end_segment với
 *    trạng thái trong Splitter; câu if trong vòng của assemble thành append có
 *    số lần 0 hoặc 1 (ghi tại chỗ); tham số c của is_letter thành unit; bỏ {}
 *    thừa của Segments::parts; return kèm lời gọi hàm void tách làm hai.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "fs/path.hpp"

#include "core/check.hpp"

#include <algorithm>
#include <cstddef>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::fs {

namespace {

[[nodiscard]] bool is_letter(char unit) noexcept {
    return (unit >= 'a' && unit <= 'z') || (unit >= 'A' && unit <= 'Z');
}

[[nodiscard]] bool is_drive(std::string_view path) noexcept {
    return path.size() >= 3 && is_letter(path.front()) && path.at(1) == ':' && is_separator(path.at(2));
}

// UNC cần đúng hai dấu phân cách rồi tên máy; "///" chỉ là gốc "/" như ở _Ref.
[[nodiscard]] bool is_unc(std::string_view path) noexcept {
    return path.size() >= 3 && is_separator(path.front()) && is_separator(path.at(1)) && !is_separator(path.at(2));
}

// Số ký tự gốc ở đầu path: 2 cho UNC, 3 cho "X:/", 1 cho "/", 0 nếu tương đối.
[[nodiscard]] std::size_t root_length(std::string_view path) noexcept {
    if (is_unc(path)) return 2;
    if (is_drive(path)) return 3;
    return !path.empty() && is_separator(path.front()) ? 1 : 0;
}

// Gốc viết lại bằng separator: "C:\" thành "C:/", "\\máy" thành "//máy".
[[nodiscard]] std::string root_text(std::string_view path, char separator) {
    std::string root(path.substr(0, root_length(path)));
    std::ranges::replace_if(root, is_separator, separator);
    return root;
}

// Các đoạn đã giải; trailing là dấu phân cách cuối mà gốc giữ lại sau ".", ".." đã giải, hay khi
// đường dẫn vốn kết thúc bằng dấu phân cách.
struct Segments {
    std::vector<std::string_view> parts;
    bool trailing = false;
};

// has_root: ".." ngay trên gốc ổ đĩa, "/" hay UNC thì bỏ, không đẩy vào kết quả. Hợp đồng của
// path.hpp: "C:/.." ra "C:/". Không có gốc thì ".." giữ nguyên ("../../a" vẫn là đường tương đối).
void push_segment(Segments& segments, std::string_view segment, bool has_root) {
    if (segment.empty()) return;
    if (segment == ".") {
        segments.trailing = true;
        return;
    }
    const bool is_parent = segment == "..";
    const bool resolvable = is_parent && !segments.parts.empty() && segments.parts.back() != "..";
    const bool at_root = is_parent && has_root && segments.parts.empty();
    if (at_root) return;
    segments.trailing = resolvable;
    if (resolvable) {
        segments.parts.pop_back();
        return;
    }
    segments.parts.push_back(segment);
}

// Khác gốc: gốc giữ segments và begin là biến cục bộ của resolve, thân vòng lặp mở đầu bằng câu
// if (...) continue. Ở đây trạng thái của vòng nằm trong Splitter và thân vòng là end_segment; thứ
// tự và công thức giữ nguyên.
struct Splitter {
    std::string_view rest;
    bool has_root = false;
    Segments segments;
    // Đầu đoạn đang đọc.
    std::size_t begin = 0;
};

// Tại i là dấu phân cách hay cuối chuỗi thì khép đoạn [begin, i); ký tự thường thì không làm gì.
void end_segment(Splitter& splitter, std::size_t i) {
    const std::string_view rest = splitter.rest;
    const bool at_end = i == rest.size();
    if (!at_end && !is_separator(rest.at(i))) return;
    const std::size_t begin = splitter.begin;
    push_segment(splitter.segments, rest.substr(begin, i - begin), splitter.has_root);
    splitter.begin = i + 1;
}

[[nodiscard]] Segments resolve(std::string_view rest, bool has_root) {
    Splitter splitter{.rest = rest, .has_root = has_root, .segments = {}, .begin = 0};
    for (std::size_t i = 0; i <= rest.size(); ++i) {
        end_segment(splitter, i);
    }
    Segments segments = std::move(splitter.segments);
    if (!rest.empty() && is_separator(rest.back())) segments.trailing = true;
    return segments;
}

[[nodiscard]] std::string assemble(std::string root, const Segments& segments, char separator) {
    std::string out = std::move(root);
    for (std::size_t i = 0; i < segments.parts.size(); ++i) {
        // Khác gốc: gốc viết if (i != 0) out += separator; append với số lần 0 không thêm gì.
        const std::size_t gaps = i != 0 ? 1 : 0;
        out.append(gaps, separator);
        out += segments.parts.at(i);
    }
    if (segments.trailing && !segments.parts.empty()) out += separator;
    return out;
}

// Vị trí dấu chấm mở đầu phần mở rộng trong tên tệp; npos cho ".", "..", ".ẩn" và tên không chấm.
[[nodiscard]] std::size_t extension_dot(std::string_view name) noexcept {
    if (name == "." || name == "..") return std::string_view::npos;
    const std::size_t dot = name.rfind('.');
    return dot == 0 ? std::string_view::npos : dot;
}

[[nodiscard]] std::string_view without_dot(std::string_view ext) noexcept {
    return !ext.empty() && ext.front() == '.' ? ext.substr(1) : ext;
}

} // namespace

std::string normalize(std::string_view path, char separator) {
    const std::size_t root = root_length(path);
    const Segments segments = resolve(path.substr(root), root != 0);
    std::string out = assemble(root_text(path, separator), segments, separator);
    if (out.empty() && !path.empty()) out = ".";
    return out;
}

bool is_normalized(std::string_view path, char separator) {
    return normalize(path, separator) == path;
}

bool is_absolute(std::string_view path) noexcept {
    return root_length(path) != 0;
}

std::string join(std::string_view dir, std::string_view name, char separator) {
    const bool name_only = dir.empty() || is_absolute(name);
    std::string merged(name_only ? std::string_view{} : dir);
    if (!name_only) merged += separator;
    merged += name;
    std::string out = normalize(merged, separator);
    const bool root_only = out.size() == root_length(out);
    if (!root_only && is_separator(out.back())) out.pop_back();
    return out;
}

std::string_view parent(std::string_view path) noexcept {
    const std::size_t last = path.find_last_of("/\\");
    if (last == std::string_view::npos) return {};
    const std::size_t root = root_length(path);
    return path.substr(0, last < root ? root : last);
}

std::string_view file_name(std::string_view path) noexcept {
    const std::size_t last = path.find_last_of("/\\");
    return last == std::string_view::npos ? path : path.substr(last + 1);
}

std::string_view stem(std::string_view path) noexcept {
    const std::string_view name = file_name(path);
    return name.substr(0, extension_dot(name));
}

std::string_view extension(std::string_view path) noexcept {
    const std::string_view name = file_name(path);
    const std::size_t dot = extension_dot(name);
    return dot == std::string_view::npos ? std::string_view{} : name.substr(dot + 1);
}

PathParts split(std::string_view path) noexcept {
    const std::string_view name = file_name(path);
    const bool has_parent = name.size() != path.size();
    const bool has_extension = extension_dot(name) != std::string_view::npos;
    PathParts parts;
    if (has_parent) parts.parent = parent(path);
    parts.stem = stem(path);
    if (has_extension) parts.extension = extension(path);
    return parts;
}

// Đường dẫn rồi phần mở rộng là thứ tự quen của hàm ghép tên tệp (lệch API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
std::string append_extension(std::string_view path, std::string_view ext) {
    const std::string_view bare = without_dot(ext);
    const bool has_separator = std::ranges::any_of(bare, is_separator);
    core::check(!has_separator, "phần mở rộng chứa dấu phân cách thư mục");
    std::string out(path);
    if (bare.empty()) return out;
    out += '.';
    out += bare;
    return out;
}

std::string replace_extension(std::string_view path, std::string_view ext) {
    const std::string_view name = file_name(path);
    const std::size_t dot = extension_dot(name);
    const std::size_t cut = dot == std::string_view::npos ? path.size() : path.size() - name.size() + dot;
    return append_extension(path.substr(0, cut), ext);
}

} // namespace game::fs
