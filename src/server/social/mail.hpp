#pragma once
// Thư giữa người chơi và thư hệ thống: gửi (chỉ cho bạn bè, có phí, có tiền/vật phẩm/trân thú đính kèm,
// có thể thu tiền khi nhận - COD), đọc, xoá, lấy đồ đính kèm, trả thư, hết hạn. Lõi thuần: vật phẩm và
// tiền thật do hành trang của world giữ; lõi chỉ nói chuyện với hành trang qua AttachmentPort theo hai
// pha để việc chuyển đồ nguyên tử (gửi hỏng thì đồ còn nguyên ở người gửi, đồ không bao giờ vừa mất vừa
// nhân đôi).
//
// Nguồn: MailCenter của WorldServer 2008 (MAX_MAIL = 20, MAX_MAIL_CONTEX = 256, loại NORMAL/SYSTEM/
// SCRIPT/NORMAL2); luật gửi thư theo MailEdit.lua và MailBox.lua của client 2026 (cấp 50, phải là bạn,
// phí 2000 đồng, tiêu đề 20 byte, nội dung 253 byte, 5 vật phẩm, 1 trân thú, tiền kèm, tiền thu "ReqMoney",
// hộp thư 15 thư; loại 0 thường, 1 người chơi trả, 2 hệ thống, 3 hệ thống trả).
// Khác gốc: (1) trần hộp thư 15 theo client 2026 (2008: 20); (2) thư có đồ không xoá được và không tự hết
// hạn: hết hạn thì trả về người gửi, người gửi không nhận được (hộp đầy/chưa nạp) thì thư ở lại và thử lại ở
// nhịp sau - để đồ và tiền không biến mất; (3) tiền COD người nhận trả được gửi cho người gửi bằng một
// thư hệ thống có tiền, nên tiền người nhận bị trừ luôn có thư tương ứng; (4) người nhận phải đã được
// world nạp hộp thư (world nạp hộp của người trực tuyến và của người sắp nhận thư), lõi không đọc kho.
//
// Độ phức tạp: mỗi hộp tối đa mail_inbox_cap thư nên duyệt tuyến tính; tick duyệt mọi hộp đang nạp
// (gọi thưa, vài giây một lần).

#include "social/codec.hpp"
#include "social/directory.hpp"
#include "social/limits.hpp"
#include "social/policy.hpp"
#include "social/relation.hpp"
#include "social/types.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <map>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::social {

enum class MailKind : std::uint8_t {
    kNormal = 0,          // người chơi gửi
    kReturned = 1,        // trả lại: người gửi nhận lại thư của mình
    kSystem = 2,          // hệ thống gửi
    kSystemReturned = 3,  // hệ thống trả (đồ của thư hệ thống bị trả)
};

using ReservationId = std::uint64_t;

struct MailItem {
    ids::ItemSerial serial{};
    ids::ItemTemplateId item{};
    std::uint16_t count = 1;
};

// Phần đính kèm của một thư.
struct MailPayload {
    std::vector<MailItem> items;
    ids::PetId pet{};   // 0 = không có
    Copper money = 0;   // tiền kèm biếu
    Copper cod = 0;     // tiền người nhận phải trả mới lấy được đồ (0 = miễn phí)

    [[nodiscard]] bool has_goods() const noexcept { return !items.empty() || pet.value() != 0; }
    [[nodiscard]] bool has_any() const noexcept { return has_goods() || money > 0; }
};

// Giao diện tới hành trang của world. Mọi hàm gọi một lần trong cùng bước xử lý đơn luồng của lõi, nên
// không có khe hở giữa kiểm và đổi.
class AttachmentPort {
public:
    AttachmentPort() = default;
    AttachmentPort(const AttachmentPort&) = delete;
    AttachmentPort& operator=(const AttachmentPort&) = delete;
    AttachmentPort(AttachmentPort&&) = delete;
    AttachmentPort& operator=(AttachmentPort&&) = delete;
    virtual ~AttachmentPort() = default;

    // Pha 1 của gửi: world kiểm người gửi thực sự sở hữu vật phẩm/trân thú/tiền + phí, rồi khoá chúng.
    // nullopt = từ chối (sai chủ, không đủ tiền...): lõi báo lỗi, không đổi gì.
    [[nodiscard]] virtual std::optional<ReservationId> reserve(CharacterId sender, const MailPayload& payload, Copper fee) = 0;
    // Pha 2: thư đã vào hộp người nhận; world chuyển đồ khỏi hành trang người gửi (và trừ phí, tiền kèm).
    virtual void commit(ReservationId reservation) = 0;
    // Thay cho pha 2 khi lõi không giao được thư: mở khoá, đồ còn nguyên ở người gửi.
    virtual void release(ReservationId reservation) = 0;
    // Người nhận lấy đồ: world kiểm chỗ trong hành trang và `cod` đồng của người nhận, rồi chuyển đồ và
    // tiền kèm cho người nhận và trừ `cod` của người nhận. false = từ chối, không đổi gì.
    [[nodiscard]] virtual bool claim(CharacterId recipient, const MailPayload& payload, Copper cod) = 0;
};

enum class MailError : std::uint8_t {
    kUnknownPlayer = 1,
    kSelf,
    kNotLoaded,         // hộp thư của một bên chưa được nạp
    kLevelTooLow,
    kNotFriend,
    kRefused,           // người nhận chặn nhận thư / chặn người gửi
    kBadText,
    kTooManyItems,
    kBadItem,
    kBadMoney,
    kBadCod,
    kInboxFull,
    kNoSuchMail,
    kHasAttachments,    // không xoá được thư còn đồ
    kNoAttachments,
    kAttachmentRejected,
    kSenderUnavailable, // trả thư/thu COD nhưng hộp của người gửi chưa nạp hoặc đầy
    kNotReturnable,
};

[[nodiscard]] std::string_view describe(MailError error) noexcept;

struct Mail {
    MailId id{};
    MailKind kind = MailKind::kNormal;
    CharacterId sender{};  // 0 = hệ thống
    std::string sender_name;
    std::string title;
    std::string text;
    MailPayload payload;
    Tick sent{};
    bool read = false;
};

struct Mailbox {
    std::vector<Mail> mails;  // cũ nhất đứng đầu
};

enum class MailEventKind : std::uint8_t {
    kReceived,    // audience = {người nhận}; mail = id; sender
    kReturned,    // audience = {người gửi gốc}; mail = id thư mới
    kDeleted,     // audience = {chủ hộp}; mail
    kClaimed,     // audience = {chủ hộp}; mail; value = COD đã trả
    kExpired,     // audience = {chủ hộp}; mail
    kNotice,      // audience = {người nhận}; error
};

struct MailEvent {
    MailEventKind kind = MailEventKind::kNotice;
    MailId mail{};
    CharacterId subject{};
    MailError error = MailError::kNoSuchMail;
    std::int64_t value = 0;
    std::vector<CharacterId> audience;
};

using MailEvents = std::vector<MailEvent>;
using MailResult = Outcome<MailEvent, MailError>;

struct MailRoute {
    CharacterId sender{};
    CharacterId recipient{};
};

struct MailDraft {
    std::string_view title;
    std::string_view text;
    MailPayload payload;
};

class MailBook {
public:
    // `policy` phải sống lâu hơn MailBook.
    MailBook(const Limits& limits, const TextPolicy& policy);

    [[nodiscard]] std::expected<void, std::string> load(CharacterId owner, Mailbox box);
    [[nodiscard]] std::optional<Mailbox> unload(CharacterId owner);
    [[nodiscard]] const Mailbox* mailbox(CharacterId owner) const;
    [[nodiscard]] std::size_t loaded_count() const noexcept { return boxes_.size(); }

    // Gửi thư của người chơi. Chỉ cho bạn bè; thu phí mail_send_fee_copper qua port.
    [[nodiscard]] MailResult send(Tick now, const PlayerDirectory& directory, const RelationBook& relations, AttachmentPort& port,
        const MailRoute& route, const MailDraft& draft);
    // Thư hệ thống: không phí, đồ do hệ thống tạo (không qua pha giữ chỗ). Hộp đầy thì lỗi, bên gọi thử lại sau.
    [[nodiscard]] MailResult send_system(Tick now, CharacterId recipient, const MailDraft& draft);

    [[nodiscard]] MailResult mark_read(CharacterId owner, MailId mail);
    [[nodiscard]] MailResult remove(CharacterId owner, MailId mail);
    // Lấy đồ đính kèm; thư COD thu tiền người nhận qua port và gửi số tiền đó cho người gửi bằng thư hệ thống.
    [[nodiscard]] MailResult claim(Tick now, AttachmentPort& port, CharacterId owner, MailId mail);
    // Trả thư lại cho người gửi (thư chưa lấy đồ, của người chơi hoặc hệ thống có người gửi).
    [[nodiscard]] MailResult return_to_sender(Tick now, CharacterId owner, MailId mail);

    // Dọn thư hết hạn (xem "Khác gốc" 2).
    [[nodiscard]] MailEvents tick(Tick now);

    [[nodiscard]] MailId next_mail_id() const noexcept { return MailId{next_mail_}; }
    void set_next_mail_id(MailId id);

    // Bất biến: mỗi hộp trong trần, id duy nhất toàn sổ, COD chỉ khi có đồ.
    [[nodiscard]] std::expected<void, std::string> validate() const;

private:
    [[nodiscard]] Mailbox* mutable_box(CharacterId owner);
    [[nodiscard]] bool text_ok(std::string_view title, std::string_view text) const;
    [[nodiscard]] std::optional<MailError> check_payload(const MailPayload& payload) const;
    [[nodiscard]] Mail make_mail(MailKind kind, CharacterId sender, std::string sender_name, const MailDraft& draft, Tick now);
    void deliver(Mailbox& box, Mail mail);

    Limits limits_;
    const TextPolicy* policy_;
    TickSpan expire_after_{};
    std::uint64_t next_mail_ = 1;
    std::map<CharacterId, Mailbox> boxes_;
};

// Mã hoá/giải mã một hộp thư (blob::kMailbox, phiên bản 1). Tuổi thư lưu là số tick đã trôi so với `now`
// (không phụ thuộc đồng hồ của lần chạy trước). Giải mã kiểm miền, UTF-8, trùng id, trần.
[[nodiscard]] CodecResult encode_mailbox(const Mailbox& box, Tick now, Bytes& out);
[[nodiscard]] std::expected<Mailbox, CodecError> decode_mailbox(std::span<const std::byte> bytes, Tick now, const Limits& limits);

} // namespace game::social
