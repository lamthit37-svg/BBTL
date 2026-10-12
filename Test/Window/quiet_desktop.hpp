// Chạy test đụng tới cửa sổ thật trên một window station không tương tác thay vì desktop của
// người đang dùng máy. Lý do (đo 2026-10-08 bằng bộ ghi thông điệp và bộ canh desktop): vòng kéo
// của Windows kết thúc thì kích hoạt cửa sổ vừa kéo (WM_ACTIVATEAPP, WM_SETFOCUS), tức lấy bàn
// phím của người đang làm việc, và chuột, phím thật của người đó cũng tới được cửa sổ đang giữ
// capture. Tiến trình tạo với STARTUPINFO::lpDesktop trỏ sang station khác thì không cửa sổ nào
// của nó nằm trên desktop của người dùng và không input thật nào tới nó.
// Giới hạn đã đo: con trỏ chuột là của cả phiên đăng nhập. Hình con trỏ, vùng giam (ClipCursor)
// và, ở kiểu kéo bằng bàn phím, cả vị trí con trỏ vẫn bị vòng kéo đổi dù tiến trình ở station khác.
// Tệp này không làm test "vô hình"; test còn đụng con trỏ thì không được nằm trong ctest thường
// ngày (xem window_modal_tests.cpp).
// Cách dùng: đầu main gọi rerun_on_quiet_desktop(); nó trả mã thoát thì main trả luôn mã đó.
#pragma once

#include "core/handle.hpp"
#include "core/win32.hpp" // IWYU pragma: keep

#include <cstdio>
#include <expected>
#include <format>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <type_traits>

#include <errhandlingapi.h>
#if !defined(__MINGW32__)
#include <jobapi2.h>
#endif
#include <processenv.h>
#include <processthreadsapi.h>
#include <synchapi.h>
#include <winbase.h>
#include <windef.h>
#include <winnt.h>
#include <winuser.h>

namespace game::test {

// Biến môi trường báo cho bản chạy lại biết nó đã ở trên desktop riêng.
inline constexpr const wchar_t* kQuietDesktopMark = L"THIENLONG_QUIET_DESKTOP";
inline constexpr std::string_view kQuietDesktopFailure = "không chạy được test trên desktop riêng: lỗi Win32 {}\n";

struct StationClose {
    void operator()(HWINSTA station) const noexcept { CloseWindowStation(station); }
};
using StationHandle = std::unique_ptr<std::remove_pointer_t<HWINSTA>, StationClose>;

struct DesktopClose {
    void operator()(HDESK desktop) const noexcept { CloseDesktop(desktop); }
};
using DesktopHandle = std::unique_ptr<std::remove_pointer_t<HDESK>, DesktopClose>;

// Tên của một window station; rỗng khi không hỏi được.
[[nodiscard]] inline std::wstring station_name(HWINSTA station) {
    std::wstring name(128, L'\0');
    DWORD bytes = 0;
    const auto room = static_cast<DWORD>(name.size() * sizeof(wchar_t));
    const BOOL is_known = GetUserObjectInformationW(station, UOI_NAME, name.data(), room, &bytes);
    if (is_known == FALSE || bytes < sizeof(wchar_t)) return {};
    name.resize((bytes / sizeof(wchar_t)) - 1);
    return name;
}

// Chỗ chạy không input: window station không tương tác của phiên đăng nhập này cùng một desktop mới
// trong đó. path là chuỗi "station\\desktop" cho STARTUPINFO::lpDesktop; failure khác 0 là mã lỗi
// Win32 của bước không làm được. desktop đứng sau station để được đóng trước.
struct QuietPlace {
    StationHandle station;
    DesktopHandle desktop;
    std::wstring path;
    DWORD failure = 0;
};

// Desktop tạo ra thuộc window station đang gắn với tiến trình, nên gắn tạm sang station mới rồi
// gắn lại station cũ. Station không tên: Windows đặt tên theo phiên đăng nhập và mở lại station
// đó ở các lần gọi sau (chỉ quản trị viên mới được tự đặt tên).
[[nodiscard]] inline QuietPlace open_quiet_place() {
    QuietPlace place;
    auto* const home = GetProcessWindowStation();
    place.station.reset(CreateWindowStationW(nullptr, 0, GENERIC_ALL, nullptr));
    place.failure = place.station ? 0 : GetLastError();
    if (!place.station) return place;
    const std::wstring desk = std::format(L"thienlong-test-{}", GetCurrentProcessId());
    SetProcessWindowStation(place.station.get());
    place.desktop.reset(CreateDesktopW(desk.c_str(), nullptr, nullptr, 0, GENERIC_ALL, nullptr));
    place.failure = place.desktop ? 0 : GetLastError();
    SetProcessWindowStation(home);
    const std::wstring station = station_name(place.station.get());
    if (station.empty()) place.failure = ERROR_INVALID_NAME;
    place.path = std::format(L"{}\\{}", station, desk);
    return place;
}

// Job giết tiến trình con khi tiến trình này chết: ctest hết giờ giết bản cha thì bản con không
// thành tiến trình mồ côi trên một desktop không ai nhìn thấy.
[[nodiscard]] inline core::UniqueHandle kill_on_close_job() noexcept {
    core::UniqueHandle job(CreateJobObjectW(nullptr, nullptr));
    if (!job) return job;
    JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits{};
    limits.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
    const auto kind = JobObjectExtendedLimitInformation;
    SetInformationJobObject(job.get(), kind, &limits, sizeof(limits));
    return job;
}

// Mã thoát của bản chạy lại, hoặc mã lỗi Win32 của bước không làm được.
using CopyResult = std::expected<int, DWORD>;

// Chạy lại đúng dòng lệnh của tiến trình này trên desktop tên desktop rồi chờ nó.
[[nodiscard]] inline CopyResult run_copy_on(std::wstring desktop) {
    std::wstring command = GetCommandLineW();
    STARTUPINFOW startup{};
    startup.cb = sizeof(startup);
    startup.lpDesktop = desktop.data();
    PROCESS_INFORMATION made{};
    const core::UniqueHandle job = kill_on_close_job();
    const BOOL is_started = CreateProcessW(nullptr, command.data(), nullptr, nullptr, TRUE, CREATE_SUSPENDED, nullptr,
        nullptr, &startup, &made);
    if (is_started == FALSE) return std::unexpected(GetLastError());
    const core::UniqueHandle process(made.hProcess);
    const core::UniqueHandle thread(made.hThread);
    if (job) AssignProcessToJobObject(job.get(), process.get());
    ResumeThread(thread.get());
    WaitForSingleObject(process.get(), INFINITE);
    DWORD code = 1;
    GetExitCodeProcess(process.get(), &code);
    return static_cast<int>(code);
}

// nullopt: tiến trình này đã ở trên desktop riêng, cứ chạy test tại đây. Có giá trị: mã thoát của
// bản vừa chạy trên desktop riêng, hoặc 1 kèm một dòng lỗi khi không dựng được desktop hay tiến
// trình (không lặng lẽ chạy trên desktop của người dùng).
[[nodiscard]] inline std::optional<int> rerun_on_quiet_desktop() {
    if (GetEnvironmentVariableW(kQuietDesktopMark, nullptr, 0) != 0) return std::nullopt;
    SetEnvironmentVariableW(kQuietDesktopMark, L"1");
    const QuietPlace place = open_quiet_place();
    const bool is_open = place.failure == 0;
    const CopyResult code = is_open ? run_copy_on(place.path) : std::unexpected(place.failure);
    if (code) return *code;
    const std::string line = std::format(kQuietDesktopFailure, code.error());
    static_cast<void>(std::fputs(line.c_str(), stderr));
    return 1;
}

} // namespace game::test
