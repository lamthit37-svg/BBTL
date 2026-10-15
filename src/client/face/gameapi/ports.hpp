// Cổng giữa các hàm game của script (src/client/face/gameapi) và phần còn lại của client. Game.exe 2026 cho hàm Lua chạm thẳng
// vào singleton toàn cục (CDataPool, CNetManager...) theo offset; ở đây hàm chỉ thấy các cổng dưới, test cài bản giả.
// Cổng chỉ có khi một hàm đã port dùng nó: thêm cổng khi hàm đầu tiên cần (docs/giao-viec/LUA-GEN/TANG-B.md mục 2.1).
#pragma once

#include "hero/hero.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <string_view>

namespace game::gameapi {

// Bản ghi XSCRIPT mà script dựng bằng Set_XSCRIPT_* rồi gửi bằng Send_XSCRIPT (CDataPool +0x138dc của Game.exe, 128 byte,
// gói CGExecuteScript). Cùng thứ tự trường với bản gốc: số hiệu script, byte độ dài tên, tên 64 byte, byte số tham số,
// mười bốn tham số int32.
struct ScriptCall {
    static constexpr std::size_t kNameBytes = 64;
    static constexpr std::size_t kParameters = 14;
    // Chỉ nằm trong 63 byte đầu của name được ghi; byte cuối luôn 0 nên name_length không quá 63.
    static constexpr std::size_t kNameCopy = kNameBytes - 1;

    // -1 là bản ghi đã xoá (Clear_XSCRIPT đặt 0xffffffff).
    std::int32_t script_id = -1;
    std::uint8_t name_length = 0;
    std::array<char, kNameBytes> name{};
    std::uint8_t parameter_count = 0;
    std::array<std::int32_t, kParameters> parameters{};

    [[nodiscard]] std::string_view name_text() const noexcept { return {name.data(), name_length}; }

    friend bool operator==(const ScriptCall&, const ScriptCall&) = default;
};

// Đường ra máy chủ. Chế độ cục bộ (không có máy chủ) không cài Outbox: gói bị bỏ.
class Outbox {
public:
    Outbox() = default;
    Outbox(const Outbox&) = delete;
    Outbox& operator=(const Outbox&) = delete;
    Outbox(Outbox&&) = delete;
    Outbox& operator=(Outbox&&) = delete;
    virtual ~Outbox() = default;

    // CGExecuteScript (opcode 2219): gửi bản ghi như script đã dựng.
    virtual void execute_script(const ScriptCall& call) = 0;
};

// Đồng hồ mili giây của client (TdGetTimeTickCountSafe: GetTickCount, 32 bit, quấn sau 49,7 ngày).
class Clock {
public:
    Clock() = default;
    Clock(const Clock&) = delete;
    Clock& operator=(const Clock&) = delete;
    Clock(Clock&&) = delete;
    Clock& operator=(Clock&&) = delete;
    virtual ~Clock() = default;

    [[nodiscard]] virtual std::uint32_t tick_count() const noexcept = 0;
};

// Đồng hồ thật: số mili giây của đồng hồ đơn điệu, cắt về 32 bit như GetTickCount.
class SystemClock final : public Clock {
public:
    [[nodiscard]] std::uint32_t tick_count() const noexcept override {
        const auto now = std::chrono::steady_clock::now().time_since_epoch();
        return static_cast<std::uint32_t>(std::chrono::duration_cast<std::chrono::milliseconds>(now).count());
    }
};

// Các cổng một GameHost cần. Con trỏ do chủ giữ, phải sống lâu hơn GameHost.
struct Ports {
    // Người chơi đang điều khiển; null là chưa vào game (Game.exe: pMyself rỗng).
    const hero::Hero* hero = nullptr;
    // Null thì dùng đồng hồ thật.
    const Clock* clock = nullptr;
    // Null: chế độ cục bộ, không gửi gói.
    Outbox* outbox = nullptr;
};

} // namespace game::gameapi
