#pragma once
// Store nhớ ngắn câu trả lời của auth về tài khoản: còn chơi được, bị khoá hay bị ban.
// Ban có hiệu lực với cap đã cấp chậm nhất kStandingTtl. Lỗi đường truyền (Busy) không được
// nhớ để lần sau hỏi lại; khi auth không trả lời thì store từ chối (đóng an toàn).
// Đầy thì bỏ dòng hết hạn, vẫn đầy thì xoá cả bảng: chỉ tốn thêm câu hỏi, không sai.

#include "protocol/messages.hpp"

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <iterator>
#include <optional>
#include <unordered_map>

namespace game::account {

inline constexpr std::chrono::seconds kStandingTtl{1};
inline constexpr std::size_t kStandingRoom = 4096;

struct Standing {
    bool ok = false;
    protocol::ErrorCode code = protocol::ErrorCode::kBusy;
};

[[nodiscard]] constexpr bool standing_cacheable(const Standing& standing) noexcept {
    return standing.ok || standing.code != protocol::ErrorCode::kBusy;
}

class StandingCache {
public:
    using Clock = std::chrono::steady_clock;

    // ttl từ store.toml [security] standing_cache_ms; 0 là không nhớ.
    explicit StandingCache(std::chrono::milliseconds ttl = kStandingTtl) noexcept : ttl_(ttl) {}
    [[nodiscard]] std::chrono::milliseconds ttl() const noexcept { return ttl_; }

    [[nodiscard]] std::optional<Standing> find(std::uint64_t account, Clock::time_point now) {
        const auto found = rows_.find(account);
        if (found == rows_.end()) return std::nullopt;
        if (now >= found->second.until) {
            rows_.erase(found);
            return std::nullopt;
        }
        return found->second.standing;
    }

    void put(std::uint64_t account, Standing standing, Clock::time_point now) {
        if (!standing_cacheable(standing)) return;
        if (rows_.size() >= kStandingRoom && !rows_.contains(account)) {
            for (auto row = rows_.begin(); row != rows_.end();) {
                row = now >= row->second.until ? rows_.erase(row) : std::next(row);
            }
            if (rows_.size() >= kStandingRoom) rows_.clear();
        }
        if (ttl_ <= std::chrono::milliseconds::zero()) return;
        rows_[account] = Row{.standing = standing, .until = now + ttl_};
    }

    [[nodiscard]] std::size_t size() const noexcept { return rows_.size(); }

private:
    struct Row {
        Standing standing;
        Clock::time_point until;
    };

    std::chrono::milliseconds ttl_;
    std::unordered_map<std::uint64_t, Row> rows_;
};

} // namespace game::account