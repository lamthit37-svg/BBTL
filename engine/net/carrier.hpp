/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/net/carrier.hpp
 *  PHÂN HỆ   : Net / Carrier
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Lõi vận chuyển GameNetworkingSockets v1.6.1 (d534c19): số gói, ack chọn
 *    lọc từng gói, gửi lại tin cậy, tin không tin cậy, cắt mảnh, lane ưu tiên.
 *  - Khác gốc: LaneQueue số nguyên thay virtual time float; không crypto,
 *    protobuf hay ICE; byte tường minh; RTO sàn thấp, gửi lại nhanh sau 3 gói.
 *  - Một luồng. Thời gian do bên gọi đưa. Gói sai thì bỏ, không abort.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>
#include <span>
#include <vector>

namespace game::net {

// Trần một datagram: dưới MTU thông thường để không bị cắt ở tầng IP.
inline constexpr std::size_t kCarrierPacketBytes = 1200;
// Khớp một thân protocol (64 KiB) cộng phần bao.
inline constexpr std::size_t kCarrierMessageMax = 96 * 1024;
inline constexpr std::uint8_t kCarrierLanes = 4;

enum class Delivery : std::uint8_t {
    kReliable = 1,
    kUnreliable = 2,
};

struct CarrierConfig {
    // Sàn RTO. TCP của hệ điều hành thường không xuống dưới vài trăm ms.
    std::uint32_t min_rto_ms = 40;
    std::uint32_t max_rto_ms = 1000;
};

struct CarrierMessage {
    std::uint8_t lane = 0;
    Delivery delivery = Delivery::kReliable;
    std::vector<std::byte> bytes;
};

// Một chiều gửi và một chiều nhận. Hai đầu mỗi đầu một Carrier; gói ra từ
// write_packet của đầu này là đầu vào read_packet của đầu kia.
class Carrier {
public:
    Carrier();
    explicit Carrier(CarrierConfig config);
    ~Carrier();
    Carrier(Carrier&&) noexcept;
    Carrier& operator=(Carrier&&) noexcept;
    Carrier(const Carrier&) = delete;
    Carrier& operator=(const Carrier&) = delete;

    // false: lane lạ, tin rỗng, tin quá lớn, hoặc hết ngân sách gửi.
    [[nodiscard]] bool send(std::uint8_t lane, Delivery delivery,
        std::span<const std::byte> payload);

    // Ghi một datagram. false khi không có gì để gửi. `out` phải chứa đủ
    // kCarrierPacketBytes. `now_ms` là đồng hồ đơn điệu do bên gọi chọn.
    [[nodiscard]] bool write_packet(std::span<std::byte> out, std::size_t& written,
        std::uint64_t now_ms);

    // false chỉ khi gói hỏng. Gói trùng, gói cũ, hoặc gói nằm ngoài cửa sổ nhận
    // thì bỏ phần dữ liệu và vẫn trả true.
    [[nodiscard]] bool read_packet(std::span<const std::byte> packet, std::uint64_t now_ms);

    // Lấy một tin đã ghép xong. Tin cậy trong một lane giữ đúng thứ tự.
    [[nodiscard]] bool take(CarrierMessage& out);

    [[nodiscard]] std::uint32_t reliable_bytes() const noexcept;

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

} // namespace game::net
