#pragma once
// Máy trạng thái khởi động, chạy lại và dừng cụm. Không include process, không
// đọc đồng hồ: bên gọi đưa kế hoạch, giao diện tiến trình và thời điểm mỗi lượt.
// Nguồn: TLBB Dev src/server/supervise.cpp @e0d89a6 (chạy lần lượt, chờ ready,
// dừng ngược, hết hạn thì buộc dừng).
// Khác gốc: thuần trạng thái; thêm PostgreSQL, trần chạy lại mỗi giờ và nhiều
// tiến trình cùng loại. Không đụng hệ điều hành.

#include "core/error.hpp"

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::supervise {

namespace detail {
struct MachineState;
} // namespace detail

enum class Role : std::uint8_t {
    kPostgres,
    kStore,
    kAuth,
    kBilling,
    kWorld,
    kZone,
    kGate,
};

enum class Stream : std::uint8_t { kOut, kErr };

// Một dòng cho bên gọi in. kOut là stdout máy đọc; kErr là stderr tiếng Việt.
struct Event {
    Stream stream = Stream::kErr;
    std::string line;
};

// Một tiến trình trong kế hoạch. id rỗng với gate.
struct Slot {
    Role role = Role::kStore;
    std::optional<std::int32_t> id;
};

struct Step {
    Role role = Role::kStore;
    std::chrono::milliseconds ready_timeout{};
    std::vector<Slot> slots;
};

enum class PostgresMode : std::uint8_t { kLeave, kManage };

// Kế hoạch đã kiểm. Máy không mở tệp cấu hình.
struct Plan {
    PostgresMode postgres = PostgresMode::kLeave;
    std::chrono::milliseconds postgres_timeout{};
    std::vector<Step> steps;
    std::chrono::milliseconds stop_timeout{};
    std::uint32_t max_restarts_per_hour = 0;
};

enum class StopAsk : std::uint8_t { kNo, kYes };

enum class PostgresState : std::uint8_t { kDown, kUp };

enum class PollKind : std::uint8_t {
    kRunning,
    kLine,
    kExited,
    kTooLong,
};

// Một nhịp hỏi con. line chỉ có nghĩa khi kind là kLine; code khi kExited.
struct Poll {
    PollKind kind = PollKind::kRunning;
    std::string line;
    int code = 0;
};

// Bên gọi thực hiện. force_stop chỉ trả về sau khi tiến trình đã thoát. launch một ô đang có tiến
// trình là thay tiến trình đó: tiến trình cũ còn sống thì bị buộc dừng.
class Host {
public:
    Host() = default;
    Host(const Host&) = delete;
    Host& operator=(const Host&) = delete;
    Host(Host&&) = delete;
    Host& operator=(Host&&) = delete;
    virtual ~Host() = default;

    [[nodiscard]] virtual core::Result<PostgresState> postgres_status() = 0;
    [[nodiscard]] virtual core::Status postgres_start(std::chrono::milliseconds timeout) = 0;
    [[nodiscard]] virtual core::Status postgres_stop(std::chrono::milliseconds timeout) = 0;
    [[nodiscard]] virtual core::Status launch(const Slot& slot) = 0;
    virtual void close_input(const Slot& slot) noexcept = 0;
    virtual void force_stop(const Slot& slot) noexcept = 0;
    [[nodiscard]] virtual Poll poll(const Slot& slot) = 0;
};

using Time = std::chrono::steady_clock::time_point;

// finished thì exit_code có nghĩa: 0 khi dừng theo yêu cầu và mọi con thoát 0, còn lại 1.
struct Outcome {
    std::vector<Event> events;
    bool finished = false;
    int exit_code = 0;
};

// Một lượt advance là một bước. now là thời điểm bên gọi đưa, không lấy từ đồng hồ. Yêu cầu dừng
// tới lúc đang khởi động được nhớ: máy chạy cho xong bước khởi động rồi mới dừng theo thứ tự ngược.
// Dòng stdout khi cả cụm sẵn sàng là `ready` kèm mọi cổng các con đã báo, theo thứ tự khởi động:
// `ready <vai>[.<số>].<khoá>=<cổng> ...` (gate không có số); không con nào báo cổng thì là `ready`
// trần. Một con chạy lại mà báo cổng khác trước thì máy in `ports <vai>[.<số>].<khoá>=<cổng> ...`
// cho riêng con đó. Con gửi dòng `ready` hỏng (parse_ready) là con hỏng: cả cụm dừng, thoát 1.
class Machine {
public:
    explicit Machine(Plan plan);
    ~Machine();
    Machine(const Machine&) = delete;
    Machine& operator=(const Machine&) = delete;
    Machine(Machine&&) = delete;
    Machine& operator=(Machine&&) = delete;

    [[nodiscard]] Outcome advance(Host& host, Time now, StopAsk stop);
    [[nodiscard]] bool finished() const noexcept;

private:
    std::unique_ptr<detail::MachineState> state_;
};

// Cổng một con báo ở dòng sẵn sàng của nó; 0 là con không báo khoá đó. Bốn khoá này là trọn bộ
// khoá cổng của giao kèo mục 3.1 (docs/KE-HOACH-SERVER.md): gate báo game và auth, các tiến trình
// có cổng nội bộ báo ipc, mọi tiến trình có cổng đọc số đo báo metrics.
struct ReadyPorts {
    std::uint16_t ipc = 0;
    std::uint16_t game = 0;
    std::uint16_t auth = 0;
    std::uint16_t metrics = 0;

    [[nodiscard]] friend bool operator==(const ReadyPorts&, const ReadyPorts&) = default;
};

enum class ReadyFault : std::uint8_t {
    // Từ đầu không phải `ready`: dòng khác của con, không phải dòng sẵn sàng.
    kNotReady = 1,
    // Một từ sau `ready` không có dạng `khoá=giá trị` với khoá khác rỗng.
    kPair,
    // Một khoá cổng xuất hiện hai lần.
    kDuplicate,
    // Giá trị của một khoá cổng không phải số thập phân.
    kNumber,
    // Số của một khoá cổng nằm ngoài 1..65535.
    kRange,
};

// Đọc dòng sẵn sàng của một con: từ `ready`, rồi các cặp `khoá=số` cách nhau đúng một dấu cách.
// Khoá cổng (ipc, game, auth, metrics) phải mang số 1..65535 và không lặp; khoá khác bị bỏ qua, để
// con thêm khoá mới mà trình giám sát cũ vẫn đọc được. `ready` trần cho bốn cổng bằng 0.
// Dòng dài tối đa trần một dòng của process (4096 byte); không cấp phát.
[[nodiscard]] std::expected<ReadyPorts, ReadyFault> parse_ready(std::string_view line) noexcept;

// Câu tiếng Việt cho stderr.
[[nodiscard]] std::string_view describe(ReadyFault fault) noexcept;

// Cỡ lớn nhất (byte, không kể dấu xuống dòng) của dòng `ready` mà máy có thể in cho kế hoạch này,
// khi mọi con báo đủ bốn cổng năm chữ số. Bên gọi so với trần một dòng của bên đọc trước khi chạy.
[[nodiscard]] std::size_t ready_line_bound(const Plan& plan) noexcept;

// Tên trên stdout: store, auth, billing, world, zone, gate, postgres.
[[nodiscard]] std::string_view role_name(Role role) noexcept;

// Cùng loại và cùng id.
[[nodiscard]] bool same_slot(const Slot& left, const Slot& right) noexcept;

} // namespace game::supervise
