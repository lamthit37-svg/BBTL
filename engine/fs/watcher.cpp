/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/fs/watcher.cpp
 *  PHÂN HỆ   : Fs / Watcher
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt fs/watcher.hpp.
 *  - Một luồng mỗi thư mục như gốc. Luồng chờ cùng lúc sự kiện I/O và sự kiện
 *    dừng; jthread yêu cầu dừng thì stop_callback đặt sự kiện dừng. Trước khi
 *    thoát, I/O còn treo bị CancelIoEx và luồng chờ nó hoàn tất, vì nhân còn
 *    ghi vào bộ đệm và OVERLAPPED nằm trong State. Bản ghi
 *    FILE_NOTIFY_INFORMATION được chép ra từng trường, kiểm biên với số byte
 *    nhân đã ghi, không ép con trỏ vào giữa bộ đệm.
 *  - Nguồn: Forge2 src/fs/watcher.cpp@d7fcd76. Khác gốc (so với Forge2): macro
 *    của windows.h lấy từ core/win32.hpp (gốc khai ở CMake), header con của
 *    Win32 include trực tiếp; vòng lặp của run tách thành pump, thân vòng của
 *    dispatch tách thành dispatch_one (ghi tại chỗ, dãy lời gọi Win32 và thứ tự
 *    huỷ không đổi); ThreadConfig khai biến rồi gán tên; tham số at của
 *    read_record thành rest; bỏ {} thừa của các thành viên Record và State;
 *    return kèm lời gọi hàm void tách làm hai.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "fs/watcher.hpp"

#include "core/error.hpp"
#include "core/handle.hpp"
#include "core/log.hpp"
#include "core/text.hpp"
#include "core/thread.hpp"
#include "core/win32.hpp" // IWYU pragma: keep
#include "fs/file.hpp"
#include "fs/path.hpp"
#include "fs/stream.hpp"

#include <errhandlingapi.h>
#include <fileapi.h>
#include <ioapiset.h>
#include <minwinbase.h>
#include <synchapi.h>
#include <winbase.h>
#include <winerror.h>
#include <winnt.h>

#include <algorithm>
#include <array>
#include <bit>
#include <cstddef>
#include <cstring>
#include <exception>
#include <future>
#include <memory>
#include <optional>
#include <span>
#include <stop_token>
#include <string>
#include <string_view>
#include <thread>
#include <utility>

namespace game::fs {

using core::fail;
using core::fail_system;
using core::UniqueHandle;

namespace {

// ReadDirectoryChangesW qua mạng không nhận bộ đệm lớn hơn 64 KiB.
constexpr std::size_t kNotifyBuffer = std::size_t{64} * 1024;
// FILE_NOTIFY_INFORMATION: NextEntryOffset, Action, FileNameLength rồi tên UTF-16 không có số 0
// cuối.
constexpr std::size_t kRecordHead = 3 * sizeof(DWORD);

struct Record {
    DWORD next = 0;
    DWORD action = 0;
    std::wstring name;
};

[[nodiscard]] DWORD filter_for(Change events) noexcept {
    DWORD filter = 0;
    if (has(events, Change::kModified)) filter |= FILE_NOTIFY_CHANGE_LAST_WRITE;
    if (has(events, Change::kAccessed)) filter |= FILE_NOTIFY_CHANGE_LAST_ACCESS;
    const bool names = has(events, Change::kCreated) || has(events, Change::kDeleted);
    if (names) filter |= FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_DIR_NAME;
    return filter;
}

// Gốc ghi đè MODIFIED thành ACCESSED khi đăng ký cả hai; ở đây Accessed chỉ khi không đăng ký
// Modified, vì Windows không cho biết lần đổi là ghi hay đọc.
[[nodiscard]] std::optional<Change> change_of(DWORD action, Change events) noexcept {
    switch (action) {
    case FILE_ACTION_ADDED:
    case FILE_ACTION_RENAMED_NEW_NAME: return Change::kCreated;
    case FILE_ACTION_REMOVED:
    case FILE_ACTION_RENAMED_OLD_NAME: return Change::kDeleted;
    case FILE_ACTION_MODIFIED: return has(events, Change::kModified) ? Change::kModified : Change::kAccessed;
    default: return std::nullopt;
    }
}

// Bản ghi ở đầu rest; nullopt nếu nó tràn khỏi phần nhân đã ghi.
[[nodiscard]] std::optional<Record> read_record(std::span<const std::byte> rest) {
    if (rest.size() < kRecordHead) return std::nullopt;
    std::array<std::byte, kRecordHead> head{};
    std::ranges::copy(rest.first(kRecordHead), head.begin());
    const auto [next, action, length] = std::bit_cast<std::array<DWORD, 3>>(head);
    if (rest.size() - kRecordHead < length) return std::nullopt;
    Record record{.next = next, .action = action, .name = {}};
    record.name.resize(length / sizeof(wchar_t));
    const std::size_t whole = length - (length % sizeof(wchar_t));
    std::memcpy(record.name.data(), rest.subspan(kRecordHead).data(), whole);
    return record;
}

} // namespace

struct Watcher::State {
    std::string directory;
    // Change không có giá trị 0; start() gán lại trước khi luồng chạy.
    Change events = Change::kModified;
    DWORD filter = 0;
    Callback callback;
    // Thư mục mở với FILE_FLAG_OVERLAPPED.
    UniqueHandle handle;
    // Sự kiện của OVERLAPPED, đặt lại tay.
    UniqueHandle ready;
    // Đặt khi jthread yêu cầu dừng.
    UniqueHandle halt;
    OVERLAPPED overlapped{};
    DWORD received = 0;
    // Đang có một ReadDirectoryChangesW chưa xong.
    bool pending = false;
    // Mảng DWORD để có căn lề DWORD mà ReadDirectoryChangesW đòi, không cần alignas.
    std::array<DWORD, kNotifyBuffer / sizeof(DWORD)> buffer{};

    void run(const std::stop_token& token, std::promise<DWORD>& armed);
    void pump(const std::stop_token& token);
    [[nodiscard]] DWORD arm();
    [[nodiscard]] bool collect();
    [[nodiscard]] bool stop_on(DWORD error) const;
    void stop_quietly(DWORD error) noexcept;
    void dispatch();
    [[nodiscard]] bool dispatch_one(std::span<const std::byte>& rest);
    void notify(const Record& record);
    void deliver(std::string_view path, Change change) noexcept;
    void cancel() noexcept;
};

// Lần gửi đầu chạy trên luồng này rồi mới báo cho start(): I/O overlapped bị huỷ khi luồng đã gửi
// nó kết thúc, nên không gửi từ luồng gọi start(); và start() chờ báo này để thay đổi xảy ra ngay
// sau khi nó trả về không bị lỡ.
void Watcher::State::run(const std::stop_token& token, std::promise<DWORD>& armed) {
    const std::stop_callback wake(token, [this] { SetEvent(halt.get()); });
    const DWORD first = arm();
    armed.set_value(first);
    if (first != 0) return;
    try {
        pump(token);
    } catch (const std::exception& error) {
        core::error("Luồng theo dõi {} dừng vì lỗi: {}", directory, error.what());
    }
    // Khác gốc: gốc viết return stop_quietly(error) ngay trong vòng lặp nên không tới dòng này khi
    // arm hỏng. Ở đây vẫn tới, nhưng cancel() không làm gì: stop_quietly đã gọi cancel(), và
    // cancel() luôn để pending = false. Dãy lời gọi Win32 không đổi.
    cancel();
}

// Khác gốc: vòng while của run tách ra đây (gốc đặt nó trong khối try, thân có câu if). Lỗi của arm
// lên điều kiện lặp, đứng đầu để stop_requested và collect không bị gọi thêm sau lần gửi hỏng;
// stop_quietly chạy ngay sau vòng, vẫn trong khối try của run như gốc.
void Watcher::State::pump(const std::stop_token& token) {
    DWORD error = 0;
    while (error == 0 && !token.stop_requested() && collect()) {
        dispatch();
        error = arm();
    }
    if (error != 0) stop_quietly(error);
}

bool Watcher::State::stop_on(DWORD error) const {
    core::error("Ngừng theo dõi {}: {}", directory, core::system_message(error));
    return false;
}

void Watcher::State::stop_quietly(DWORD error) noexcept {
    [[maybe_unused]] const bool stopped = stop_on(error);
    cancel();
}

// Gửi một lần ReadDirectoryChangesW; 0 khi đã gửi, không thì mã lỗi Win32.
DWORD Watcher::State::arm() {
    overlapped = OVERLAPPED{};
    overlapped.hEvent = ready.get();
    ResetEvent(ready.get());
    const auto size = static_cast<DWORD>(kNotifyBuffer);
    const BOOL issued =
        ReadDirectoryChangesW(handle.get(), buffer.data(), size, TRUE, filter, nullptr, &overlapped, nullptr);
    if (issued == 0) return GetLastError();
    pending = true;
    return 0;
}

// Chờ lần gửi xong hay lệnh dừng; false khi dừng hoặc lỗi. Giữa hai lần gửi nhân vẫn ghi thay đổi
// vào bộ đệm riêng của handle, nên thời gian hàm gọi lại chạy không làm lỡ sự kiện.
bool Watcher::State::collect() {
    const std::array<HANDLE, 2> signals{ready.get(), halt.get()};
    const DWORD woke = WaitForMultipleObjects(2, signals.data(), FALSE, INFINITE);
    if (woke != WAIT_OBJECT_0) return false;
    pending = false;
    received = 0;
    if (GetOverlappedResult(handle.get(), &overlapped, &received, FALSE) != 0) return true;
    const DWORD error = GetLastError();
    // Tràn bộ đệm của nhân: received giữ 0, dispatch báo Overflow.
    if (error == ERROR_NOTIFY_ENUM_DIR) return true;
    return stop_on(error);
}

void Watcher::State::dispatch() {
    if (received == 0) {
        deliver(directory, Change::kOverflow);
        return;
    }
    std::span<const std::byte> rest = std::as_bytes(std::span(buffer)).first(received);
    // Khác gốc: gốc là for (;;) có hai câu if trả về trong thân; thân ấy thành dispatch_one.
    bool has_more = dispatch_one(rest);
    while (has_more) {
        has_more = dispatch_one(rest);
    }
}

// Báo bản ghi ở đầu rest rồi dời rest tới bản ghi kế. Trả false khi không còn bản ghi kế: bản ghi
// này tràn khỏi phần nhân đã ghi, là bản cuối (next bằng 0), hay next trỏ ra ngoài rest.
bool Watcher::State::dispatch_one(std::span<const std::byte>& rest) {
    const auto record = read_record(rest);
    if (!record) return false;
    notify(*record);
    if (record->next == 0 || record->next >= rest.size()) return false;
    rest = rest.subspan(record->next);
    return true;
}

void Watcher::State::notify(const Record& record) {
    const auto change = change_of(record.action, events);
    if (!change || !has(events, *change)) return;
    deliver(join(directory, core::narrow(record.name)), *change);
}

// Ngoại lệ của hàm gọi lại không được thoát khỏi thân jthread.
void Watcher::State::deliver(std::string_view path, Change change) noexcept {
    try {
        callback(path, change);
    } catch (const std::exception& error) {
        core::error("Hàm gọi lại của watcher ném: {}", error.what());
    } catch (...) {
        core::error("Hàm gọi lại của watcher ném ngoại lệ lạ");
    }
}

void Watcher::State::cancel() noexcept {
    if (!pending) return;
    CancelIoEx(handle.get(), &overlapped);
    DWORD ignored = 0;
    GetOverlappedResult(handle.get(), &overlapped, &ignored, TRUE);
    pending = false;
}

Watcher::Watcher(std::unique_ptr<State> state, std::jthread thread) noexcept
    : state_(std::move(state)), thread_(std::move(thread)) {}
Watcher::Watcher(Watcher&&) noexcept = default;

Watcher& Watcher::operator=(Watcher&& other) noexcept {
    if (this == &other) return *this;
    // jthread gán đè thì request_stop rồi join luồng đang giữ trước khi nhận luồng mới.
    thread_ = std::move(other.thread_);
    state_ = std::move(other.state_);
    return *this;
}
Watcher::~Watcher() = default;

Result<Watcher> Watcher::start(std::string_view directory, Change events, Callback callback) {
    const DWORD filter = filter_for(events);
    if (filter == 0) return fail(core::ErrorCode::kInvalidArgument, "chưa chọn sự kiện nào");
    if (!callback) return fail(core::ErrorCode::kInvalidArgument, "thiếu hàm gọi lại");
    auto state = std::make_unique<State>();
    state->directory = join(directory, "");
    state->events = events;
    state->filter = filter;
    state->callback = std::move(callback);
    const std::wstring wide = native_path(directory);
    const DWORD share = FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE;
    const DWORD flags = FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OVERLAPPED;
    state->handle.reset(CreateFileW(wide.c_str(), FILE_LIST_DIRECTORY, share, nullptr, OPEN_EXISTING, flags, nullptr));
    if (!state->handle) return fail_system(GetLastError(), "không mở được thư mục", directory);
    state->ready.reset(CreateEventW(nullptr, TRUE, FALSE, nullptr));
    state->halt.reset(CreateEventW(nullptr, TRUE, FALSE, nullptr));
    const bool signals = state->ready && state->halt;
    if (!signals) return fail_system(GetLastError(), "không tạo được sự kiện chờ");
    State* shared = state.get();
    std::promise<DWORD> armed;
    std::future<DWORD> first = armed.get_future();
    const auto body = [shared, &armed](const std::stop_token& token) { shared->run(token, armed); };
    // Khác gốc: gốc truyền {.name = ...} thẳng vào start_thread; ThreadConfig của dự án bỏ {} ở
    // affinity nên khởi tạo thiếu trường bị cảnh báo, ở đây khai biến rồi gán tên.
    core::ThreadConfig config;
    config.name = "theo dõi tệp";
    std::jthread thread = core::start_thread(std::move(config), body);
    const DWORD error = first.get();
    if (error != 0) return fail_system(error, "không theo dõi được thư mục", directory);
    return Watcher(std::move(state), std::move(thread));
}

} // namespace game::fs
