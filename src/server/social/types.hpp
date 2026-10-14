#pragma once
// Kiểu dùng chung của lõi xã hội (đội, bang, quan hệ, thư, chat, xếp hạng, thông báo). Lõi thuần:
// không mạng, không database, không đồng hồ thật. Trạng thái do bên gọi (tiến trình world) sở hữu,
// mỗi thao tác trả lỗi có kiểu hoặc danh sách sự kiện để world phát đi; lõi không biết kết nối.
//
// Id nhân vật, bang, đội, cảnh và Tick lấy từ "ids/ids.hpp" (src/shared). Id vào từ client là dữ liệu
// thù địch: mọi thao tác kiểm tồn tại, quyền và trần trước khi đổi trạng thái.

#include "ids/ids.hpp"

#include <algorithm>
#include <cstdint>
#include <optional>
#include <vector>

namespace game::social {

using ids::CharacterId;
using ids::GuildId;
using ids::SceneId;
using ids::TeamId;
using ids::Tick;
using ids::TickSpan;

// Máy chủ chạy 20 bước mỗi giây (docs/KE-HOACH-SERVER.md); mọi hạn trong bảng giới hạn tính bằng
// giây hoặc mili giây rồi đổi sang tick một lần lúc nạp (làm tròn lên, ids::to_ticks).
inline constexpr std::int64_t kTicksPerSecond = 20;

using MailId = ids::StrongId<struct MailTag, std::uint64_t>;
using CityId = ids::StrongId<struct CityTag, std::uint32_t>;
using BoardId = ids::StrongId<struct BoardTag, std::uint32_t>;
using ChannelId = ids::StrongId<struct ChannelTag, std::uint8_t>;
using CustomChannelId = ids::StrongId<struct CustomChannelTag, std::uint32_t>;
using LeagueId = ids::StrongId<struct LeagueTag, std::uint32_t>;

// Tiền tệ tính bằng đồng nhỏ nhất (copper) của client 2026: số nguyên có dấu 64 bit, không bao giờ
// là số thực. Số âm chỉ xuất hiện trong phép tính trung gian, trạng thái không lưu số âm.
using Copper = std::int64_t;

// Kết quả mọi thao tác của lõi. `error` là lỗi của người ra lệnh: có lỗi thì dữ liệu xã hội (đội,
// bang, danh sách bạn, hộp thư...) KHÔNG đổi; riêng lời mời/đơn xin đang chờ mà người ra lệnh vừa
// trả lời thì bị tiêu thụ dù lệnh lỗi (nó đã cũ). `events` là thứ world phát đi; một lệnh bị từ chối vẫn có thể mang sự kiện cho bên
// thứ ba (ví dụ đội đầy: người mời nhận thông báo, người trả lời nhận lỗi). Thứ tự sự kiện là thứ
// tự phát.
template <class Event, class Error>
struct Outcome {
    std::vector<Event> events;
    std::optional<Error> error;

    [[nodiscard]] bool ok() const noexcept { return !error.has_value(); }
};

// Sát trần của Copper: mọi phép cộng trạng thái đi qua add_clamped để không tràn có dấu.
inline constexpr Copper kCopperCeiling = Copper{1} << 53;

// Kẹp một khoản tiền vào [0, kCopperCeiling]. Khoản âm (dữ liệu thù địch) thành 0.
[[nodiscard]] constexpr Copper clamp_money(Copper value) noexcept {
    return std::clamp(value, Copper{0}, kCopperCeiling);
}

// Cộng hai khoản tiền, kết quả kẹp vào [0, kCopperCeiling]. Phép cộng giao hoán nên hai tham số cùng
// kiểu đổi chỗ vô hại.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): giao hoán, đổi chỗ vô hại (API-03)
[[nodiscard]] constexpr Copper add_clamped(Copper left, Copper right) noexcept {
    return clamp_money(clamp_money(left) + clamp_money(right));
}

} // namespace game::social
