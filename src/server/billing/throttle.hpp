#pragma once
// Bộ đếm tốc độ nhập mã: token bucket tính bằng tick (20 tick/giây, ids::Tick), một bộ theo tài khoản
// và một bộ theo IP. Tất định: kết quả chỉ phụ thuộc chuỗi (khoá, tick) đưa vào, không đồng hồ thật,
// không thứ tự duyệt bảng băm.
//
// Hợp đồng: mỗi khoá mới đầy `capacity` lượt, hồi 1 lượt mỗi ceil(3600 giây x 20 / capacity) tick, tức
// capacity lượt mỗi giờ. capacity 0 là không cho lượt nào. Bộ nhớ có trần max_keys: đầy thì bỏ các
// khoá đã hồi đầy (không còn gì để nhớ), vẫn đầy thì khoá mới bị từ chối. Trần này chặn kẻ đổi IP
// liên tục để ăn bộ nhớ của billing. Chi phí mỗi lượt O(1), lúc dọn bảng đầy O(max_keys).
//
// Không an toàn đa luồng: billing dùng nó trong đúng một luồng (luồng xử lý ipc).

#include "ids/ids.hpp"

#include <cstddef>
#include <cstdint>
#include <unordered_map>

namespace game::billing {

// per_hour: lượt mỗi giờ (0 là cấm hẳn). max_keys >= 1.
struct BucketRate {
    std::int64_t per_hour = 0;
    std::size_t max_keys = 1;
};

class TokenBuckets {
public:
    explicit TokenBuckets(BucketRate rate);

    // true và tiêu một lượt nếu khoá còn lượt tại tick `now`. now không lùi theo từng khoá; tick nhỏ hơn
    // lần trước của khoá được coi như bằng lần trước.
    [[nodiscard]] bool take(std::uint64_t key, ids::Tick now);

    [[nodiscard]] std::size_t size() const noexcept { return state_.size(); }

private:
    struct State {
        std::uint32_t tokens = 0;
        ids::Tick last;
    };

    void sweep_full(ids::Tick now);

    std::uint32_t capacity_ = 0;
    std::uint64_t refill_ticks_ = 1;
    std::size_t max_keys_ = 1;
    std::unordered_map<std::uint64_t, State> state_;
};

struct RedeemRates {
    std::int64_t account_per_hour = 0;
    std::int64_t ip_per_hour = 0;
    std::size_t max_keys = 1;
};

// Hai bộ đếm của một lần nhập mã: theo tài khoản và theo IPv4 đã gói thành số.
class RedeemThrottle {
public:
    explicit RedeemThrottle(RedeemRates rates)
        : by_account_({.per_hour = rates.account_per_hour, .max_keys = rates.max_keys}),
          by_ip_({.per_hour = rates.ip_per_hour, .max_keys = rates.max_keys}) {}

    // Phải qua cả hai bộ. Bộ tài khoản đứng trước: kẻ gọi giả mạo IP vẫn bị chặn theo tài khoản, và
    // một IP đông người (cổng NAT) không bị một tài khoản xấu ăn hết lượt khi tài khoản đó đã hết.
    [[nodiscard]] bool take(std::uint64_t account, std::uint32_t ip, ids::Tick now) {
        if (!by_account_.take(account, now)) return false;
        return by_ip_.take(ip, now);
    }

private:
    TokenBuckets by_account_;
    TokenBuckets by_ip_;
};

} // namespace game::billing
