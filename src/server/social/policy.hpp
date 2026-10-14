#pragma once
// Cổng kiểm văn bản do người chơi gõ (tên bang, tên liên minh, tên chức vị, lời chat). Lõi xã hội không
// tự giữ bảng chữ cấm: bộ lọc chữ (social/wordfilter.hpp) cài đặt các giao diện này, test dùng bản giả.

#include <string>
#include <string_view>

namespace game::social {

class TextPolicy {
public:
    TextPolicy() = default;
    TextPolicy(const TextPolicy&) = delete;
    TextPolicy& operator=(const TextPolicy&) = delete;
    TextPolicy(TextPolicy&&) = delete;
    TextPolicy& operator=(TextPolicy&&) = delete;
    virtual ~TextPolicy() = default;

    // true = chữ được phép. `text` đã qua kiểm UTF-8 và độ dài của bên gọi.
    [[nodiscard]] virtual bool allowed(std::string_view text) const = 0;
};

// Cho qua mọi chữ: dùng khi world chưa nạp bảng chữ cấm, hoặc trong test của bên không đụng bộ lọc.
class AllowAllText final : public TextPolicy {
public:
    [[nodiscard]] bool allowed(std::string_view /*text*/) const override { return true; }
};

// Bộ lọc lời chat: ngoài việc trả lời "được/không", còn che đoạn cấm để tin vẫn đi tiếp (khác tên bang:
// tên có chữ cấm thì từ chối cả tên).
class TextFilter : public TextPolicy {
public:
    // Thay mỗi điểm mã nằm trong đoạn bị cấm bằng '*'. Chuỗi không có chữ cấm trả về nguyên văn.
    [[nodiscard]] virtual std::string mask(std::string_view text) const = 0;
};

// Không lọc gì: bản của test và của world khi chưa nạp bảng.
class PassThroughFilter final : public TextFilter {
public:
    [[nodiscard]] bool allowed(std::string_view /*text*/) const override { return true; }
    [[nodiscard]] std::string mask(std::string_view text) const override { return std::string{text}; }
};

} // namespace game::social
