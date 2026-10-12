// Chỉ mục script khối ngoặc của OGRE: all.particle và all.effect. Tệp hạt đã nấu khoảng 7 MB,
// nên chỉ nhớ vị trí từng khối cấp cao rồi phân tích khi được hỏi.
// Nguồn: TLBB Dev src/fx/script.hpp và words.hpp. Khác gốc: namespace game::fx; tên dài hơn
// ba ký tự; không có from_chars trên con trỏ thô.
#pragma once

#include <cstddef>
#include <optional>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace game::fx {

struct ScriptProperty {
    std::string key;
    std::vector<std::string> args;
};

struct ScriptBlock {
    std::vector<std::string> head;
    std::vector<ScriptProperty> properties;
    std::vector<ScriptBlock> children;

    // Đối số thứ index của khoá; nullopt khi thiếu.
    [[nodiscard]] std::optional<std::string_view> arg(std::string_view key, std::size_t index = 0) const;
    [[nodiscard]] float number(std::string_view key, float fallback, std::size_t index = 0) const;
    [[nodiscard]] bool flag(std::string_view key, bool fallback) const;
    [[nodiscard]] std::string_view word(std::size_t index) const;
};

// name_word: 0 cho hệ hạt (dòng tên rồi '{'), 1 cho "effect Tên".
class ScriptIndex {
public:
    ScriptIndex() = default;
    ScriptIndex(std::string text, std::size_t name_word);

    [[nodiscard]] bool contains(std::string_view name) const;
    [[nodiscard]] const ScriptBlock* find(std::string_view name);

private:
    struct Span {
        std::size_t begin = 0;
        std::size_t end = 0;
    };

    void index_blocks();

    std::string text_;
    std::size_t name_word_ = 0;
    std::unordered_map<std::string, Span> spans_;
    std::unordered_map<std::string, ScriptBlock> parsed_;
};

[[nodiscard]] std::optional<float> parse_float(std::string_view text);
[[nodiscard]] bool parse_bool(std::string_view text);

} // namespace game::fx
