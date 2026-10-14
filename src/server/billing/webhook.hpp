#pragma once
// Webhook của nhà cung cấp thanh toán: chữ ký, định tuyến theo đường dẫn, đổi thân form thành
// PaymentEvent, gọi Book::apply_payment, đổi kết quả sang mã HTTP. Thuần: không socket, không đồng hồ
// (mốc `now` do bên gọi đưa), nên test chạy được với MemoryBook.
//
// Hợp đồng chữ ký (mỗi nhà cung cấp một khoá bí mật 32 byte, ghi hex trong tệp `secret_file` của khối
// [[provider]]):
//   message   = "TLBBPAY1\n" + đường dẫn + "\n" + X-Timestamp + "\n" + thân nguyên văn
//   signature = hex thường của HMAC-SHA512-256(khoá, message)        (secure::mac32, libsodium)
// gửi trong tiêu đề X-Signature. Đường dẫn nằm trong message nên chữ ký của nhà cung cấp A không dùng
// được ở đường dẫn của B; mốc thời gian nằm trong message và bị chặn độ lệch nên bản ghi chặn được
// không phát lại vô hạn (và phát lại trong cửa sổ vẫn vô hại: khoá (provider, trade_no) làm yêu cầu
// lặp lại không cộng hai lần).
//
// Vì sao không HMAC-SHA256 như nhiều cổng thanh toán thật: lớp secure của dự án bọc libsodium và chỉ
// lộ HMAC-SHA512-256 (crypto_auth). Một cổng thanh toán cụ thể có định dạng chữ ký riêng sẽ được thêm
// bằng một hàm xác thực mới cho nhà cung cấp đó, sau reverse proxy hoặc bộ chuyển; khung ở đây giữ
// nguyên.

#include "billing/book.hpp"
#include "billing/http.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::billing {

inline constexpr std::size_t kProviderKeyBytes = 32;
using ProviderKey = std::array<std::byte, kProviderKeyBytes>;

// Khoá từ 64 ký tự hex (chữ hoa hay thường), cho phép khoảng trắng/xuống dòng ở cuối tệp. nullopt
// khi sai độ dài hay ký tự lạ.
[[nodiscard]] std::optional<ProviderKey> parse_provider_key(std::string_view text);

// Ba phần được ký: đường dẫn, mốc thời gian (giây Unix, như X-Timestamp) và thân nguyên văn.
struct SignedPart {
    std::string_view path;
    std::int64_t timestamp = 0;
    std::string_view body;
};

[[nodiscard]] std::string sign_webhook(const ProviderKey& key, const SignedPart& part);

// So khớp thời gian không đổi (mac32_verify). signature_hex sai độ dài hay ký tự lạ là sai.
[[nodiscard]] bool verify_webhook(const ProviderKey& key, const SignedPart& part, std::string_view signature_hex);

struct WebhookProvider {
    // Tên đi vào cột provider của đơn nạp: chữ, số, '_', '.', '-', tối đa 32.
    std::string name;
    std::string path;
    ProviderKey key{};
};

struct WebhookAnswer {
    http::Status status = http::Status::kOk;
    std::string body;
};

class Webhooks {
public:
    Webhooks(std::vector<WebhookProvider> providers, std::int64_t max_skew_seconds);
    ~Webhooks();
    Webhooks(const Webhooks&) = delete;
    Webhooks& operator=(const Webhooks&) = delete;
    Webhooks(Webhooks&&) = delete;
    Webhooks& operator=(Webhooks&&) = delete;

    [[nodiscard]] bool empty() const noexcept { return providers_.empty(); }

    // Xử lý một yêu cầu đã phân tích. Thứ tự kiểm: đường dẫn (404), chữ ký (401), độ lệch thời gian (401),
    // thân form (422), sổ (200/409/422/503). Kẻ không có khoá chỉ thấy 404 hoặc 401.
    [[nodiscard]] WebhookAnswer handle(Book& book, const http::Request& request, UnixTime now) const;

private:
    std::vector<WebhookProvider> providers_;
    std::int64_t max_skew_ = 0;
};

} // namespace game::billing
