#pragma once
// Bộ lọc chữ cấm cho lời chat và tên (bang, liên minh, nhân vật). Nạp một lần từ ba bảng, rồi mọi lần hỏi
// chỉ đọc nên nhiều luồng dùng chung được:
//   - text_filter.tsv (client 2026, StrFilter.txt): cột id, text, type. type 1 = từ cấm (hơn 145 nghìn
//     dòng); type 2 = tên dành riêng chung, type 3 = tên dành riêng của bang (so khớp toàn chuỗi);
//     type 11/12 = mẫu "dãy lớp ký tự" kiểu [..][a-zA-Z0-9\s]*[..] (627 dòng).
//   - full_compare_filters.tsv (client 2026, FullCompareFilter.txt): cột id, kind (all|guild|team), text.
//     Client gốc dùng nó để kiểm TOÀN CHUỖI tên (CheckStringFullCompare).
//   - chat_blocked_words.tsv (máy chủ, TOOLS/server/import_social.py): từ cấm của máy chủ gốc không có ở
//     client (Filt.txt/FiltV2.txt), cột index, word, origin.
//
// Cách khớp (khác client, ghi ở docs/SERVER-SOCIAL.md):
//   * Client gốc tìm chuỗi con nguyên văn (UIString.cpp _CheckStringFilter). Lõi này giữ nguyên ý đó nhưng
//     chống né: chữ hoa/thường, chữ rộng toàn góc, chữ toán học và chữ khoanh tròn được đưa về chữ
//     thường ASCII; từ KHÔNG chứa ký hiệu còn được khớp xuyên qua dấu cách, ký tự vô hình và ký hiệu chen
//     giữa ("辅 助"); dấu câu hết câu (. , ; : ? ! 。 、 ， ！ ？ xuống dòng) là ranh giới cứng, không bắc cầu.
//   * Từ có chứa ký hiệu (vd "辅*助", "#666", "%江%泽%民%") chỉ khớp nguyên văn (có gập chữ), vì tác giả
//     bảng cố ý cấm đúng dạng viết đó chứ không cấm "辅助".
//   * Từ ASCII chữ-số dài tối đa 3 ký tự ("sb", "cao", "731") chỉ khớp khi đứng thành một cụm riêng, để
//     "class" không dính "ass"; từ ASCII dài hơn khớp như chuỗi con.
//   * Mẫu type 11/12 chạy trên văn bản đã gập chữ, không bỏ ký hiệu (mẫu tự khai chỗ cho phép chen).
// Không làm: gập chữ Hán phồn/giản hay bộ thủ Khang Hy, đổi vần pinyin. Văn bản vào là dữ liệu thù địch:
// UTF-8 hỏng được xử lý từng byte, không bao giờ assert; quét tối đa kMaxScanBytes byte.

#include "social/policy.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <memory>
#include <string>
#include <string_view>

namespace game::social {

// Loại tên khi kiểm chữ dành riêng: kCharacter chỉ dùng bảng "all"; kGuild dùng "all" + "guild".
enum class NameKind : std::uint8_t {
    kCharacter = 0,
    kGuild,
    kTeam,
};

struct FilterSources {
    std::string_view words_tsv;     // text_filter.tsv (bắt buộc)
    std::string_view reserved_tsv;  // full_compare_filters.tsv (có thể rỗng)
    std::string_view extra_tsv;     // chat_blocked_words.tsv (có thể rỗng)
};

struct FilterStats {
    std::size_t loose_words = 0;     // từ khớp xuyên ký hiệu chen
    std::size_t strict_words = 0;    // từ chứa ký hiệu, khớp nguyên văn
    std::size_t short_ascii = 0;     // trong số trên: từ ASCII ngắn cần ranh giới cụm
    std::size_t regex_rules = 0;     // mẫu dãy lớp ký tự đã nạp
    std::size_t regex_skipped = 0;   // mẫu không đọc được (cú pháp ngoài tập hỗ trợ)
    std::size_t ignored_words = 0;   // dòng bỏ: rỗng, quá dài, hay một ký tự ASCII
    std::size_t reserved_names = 0;  // số tên dành riêng (mọi loại)
};

class WordFilter final : public TextFilter {
public:
    // Quét tối đa chừng này byte; phần sau bị coi là chữ cấm (allowed = false) hoặc che hết (mask).
    static constexpr std::size_t kMaxScanBytes = 16'384;

    // Nạp và dựng bộ khớp. Lỗi: bảng sai dạng (thông báo tiếng Việt kèm số dòng). Dòng riêng lẻ không đọc
    // được thì bỏ và đếm trong stats(), không làm cả bảng hỏng. Trả con trỏ vì giao diện gốc không chuyển
    // được (TextPolicy cấm sao chép và di chuyển để mọi bên cùng nhìn một bộ lọc).
    [[nodiscard]] static std::expected<std::unique_ptr<WordFilter>, std::string> parse(const FilterSources& sources);

    struct Impl;  // chi tiết cài đặt ở wordfilter.cpp
    explicit WordFilter(std::unique_ptr<Impl> impl);
    WordFilter(const WordFilter&) = delete;
    WordFilter& operator=(const WordFilter&) = delete;
    WordFilter(WordFilter&&) = delete;
    WordFilter& operator=(WordFilter&&) = delete;
    ~WordFilter() override;

    // true = không có đoạn cấm nào.
    [[nodiscard]] bool allowed(std::string_view text) const override;
    [[nodiscard]] std::string mask(std::string_view text) const override;

    // Tên trùng hệt (không phân biệt hoa/thường, bỏ ký hiệu chen) một tên dành riêng của loại đó.
    [[nodiscard]] bool reserved_name(NameKind kind, std::string_view name) const;

    [[nodiscard]] const FilterStats& stats() const noexcept;

private:
    std::unique_ptr<Impl> impl_;
};

// Chính sách cho tên: không có chữ cấm và không trùng tên dành riêng. Giữ tham chiếu tới WordFilter.
class NamePolicy final : public TextPolicy {
public:
    NamePolicy(const WordFilter& filter, NameKind kind) noexcept : filter_(&filter), kind_(kind) {}

    [[nodiscard]] bool allowed(std::string_view text) const override {
        return filter_->allowed(text) && !filter_->reserved_name(kind_, text);
    }

private:
    const WordFilter* filter_;
    NameKind kind_;
};

} // namespace game::social
