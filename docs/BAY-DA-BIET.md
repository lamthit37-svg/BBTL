# Bẫy đã biết theo vùng

Mỗi gạch đầu dòng là một bẫy đã đo trên dự án này, kèm lệnh tái hiện. Tệp này giữ bẫy của riêng
một vùng; bẫy mà việc nào cũng có thể dính và chỉ mục "sắp làm gì thì đọc nhóm nào" nằm ở mục 11
của `AGENTS.md`. Mỗi bẫy chỉ nằm một nơi. Thêm bẫy mới vào nhóm của nó, rồi thêm một cụm vào chỉ
mục ở mục 11.

## Trình dịch, cờ và cổng kiểm

- MinGW mặc định `_WIN32_WINNT` là 0x0601 (Windows 7): API của Windows 10 (`SetThreadDescription`,
  `GetSystemCpuSetInformation`, `AdjustWindowRectExForDpi`, `SetProcessDpiAwarenessContext`) báo
  "was not declared". Tái hiện: `grep -n 'define _WIN32_WINNT' <mingw64>/x86_64-w64-mingw32/include/_mingw.h`.
  `core/win32.hpp` đã nâng lên 0x0A00.
- `check.py` dịch từng tệp đứng riêng, không có macro khai ở CMake: `UNICODE`, `NOMINMAX` chỉ khai ở
  CMake thì CMake xanh mà `check.py` đỏ (`IDC_ARROW` thành `char*`, `std::max` vướng macro `max`).
  Macro phải nằm trong mã nguồn; mọi tệp Win32 lấy `<windows.h>` qua `core/win32.hpp`.
- `misc-include-cleaner` đòi header con cung cấp từng ký hiệu Win32 (`winuser.h`, `winerror.h`...),
  không chấp nhận chỉ `<windows.h>`. Hỏi danh sách: `python TOOLS/port/forge2_port.py includes <tệp>`.
- GCC MinGW cần `-lsynchronization` cho `WaitOnAddress` (CMake: `target_link_libraries(game_core
  PRIVATE synchronization ntdll)`).
- MSVC `/W4 /WX`: `std::getenv` là C4996. Trên Windows đọc biến môi trường bằng
  `GetEnvironmentVariableA`.
- MinGW không có `<jobapi2.h>` (`fatal error: jobapi2.h: No such file or directory`); hàm job nằm
  sẵn trong `<windows.h>` của nó. `misc-include-cleaner` lại đòi header đó với SDK của MSVC, nên
  bọc `#if !defined(__MINGW32__)` quanh dòng include.
- Khởi tạo ghi tên bỏ sót một thành viên không có giá trị mặc định (`std::string line;`) là cảnh
  báo ở cả Clang 23 (`-Wmissing-designated-field-initializers`) và GCC 16
  (`-Wmissing-field-initializers`), còn viết `std::string line{};` thì clang-tidy báo
  `readability-redundant-member-init`. Struct có thành viên kiểu lớp: dựng rỗng rồi gán từng
  trường, hoặc viết hàm dựng nhỏ (`poll_of` trong `tests/supervise_script.hpp`).
- `windres` của MinGW (binutils 2.47) đưa thư mục `-I` cho bộ tiền xử lý mà không bọc nháy: thư
  mục có dấu cách, như chính đường dẫn dự án, làm nó dừng với `cc1.exe: fatal error:
  2026/THIENLONG/SRC: No such file or directory`. Tệp `.rc` vì thế nằm trong một target `OBJECT`
  riêng không có thư mục include (`thienlong_client_icon`); đường dẫn trong `.rc` tính từ chỗ tệp
  `.rc` nên không cần `-I`. Tái hiện: `windres -O coff -I "<gốc dự án>/SRC" SRC/client/app.rc
  x.obj` hỏng, bỏ `-I` thì được (đo 2026-10-07).
- GCC MinGW bản luồng POSIX (bản đang cài) dùng TLS giả lập: biến `thread_local` có destructor
  (`std::string`, `unique_ptr`, handle RAII) trong luồng tạo bằng `std::thread` hay `std::jthread`
  bị trả bộ nhớ trước khi destructor chạy, nên luồng thoát là đọc vùng nhớ đã free và thỉnh
  thoảng hỏng heap (0xC0000374). MSVC và Clang không dính. Khai `thread_local` thẳng chỉ cho kiểu
  không có destructor (số, con trỏ không sở hữu, `std::array`); kiểu có destructor đi qua
  `core::thread_slot` (`core/thread_slot.hpp`): ở GCC MinGW nó để giá trị trên heap và không huỷ,
  toolchain khác vẫn huỷ khi luồng kết thúc. Tái hiện: đổi `thread_slot` về `thread_local` thường
  thì `thread_slot_tests` của `gcc-debug` chết ngay. Số đo và hai tệp chưa chuyển (GCC MinGW
  không dựng chúng) ở mục 12 của `docs/NGHI-NGO.md`.
- Sáu tệp gắn `target("sse4.1")` bằng pragma ở đầu tệp (để `check.py` dịch được một mình) phải
  kèm `defined(__x86_64__)`: thiếu thì mỗi lần dựng Android arm64 clang in `'+sse4.1' is not a
  recognized feature for this target (ignoring feature)` (đo 2026-10-08, có từ trước ở bốn tệp).
- MSVC bản debug và `if constexpr` (đo 2026-10-08 ở `SRC/resource/upload.cpp`): viết `if constexpr
  (Flag) return a;` rồi các câu của nhánh kia ngay sau đó, không có `else`, thì ở bản `Flag` đúng
  các câu sau vẫn được dịch và `msvc-debug` dừng với C4702 (mã không tới được) dưới `/WX`;
  `msvc-release`, GCC, Clang và `cl /Zs` đều không báo. Viết đủ `if constexpr (...) { ... } else {
  ... }`, và sửa tệp có template kiểu này thì dựng cả `msvc-debug` chứ không chỉ bản phát hành.
- Preset PC và preset Android dùng chung MỘT thư mục vcpkg `C:\dev\third_party\installed` (toolchain
  `C:\dev\third_party\vcpkg.cmake` bỏ qua `VCPKG_INSTALLED_DIR` của preset), nên mỗi lần cấu hình
  một bên, vcpkg gỡ gói của bên kia (đo 2026-10-13: `cmake --preset android-arm64` gỡ `opus`,
  `sdl3` của `x64-windows-static-md`, rồi `cmake --build build/msvc-release` dừng ở LNK1104
  `SDL3-static.lib`; cấu hình lại `msvc-release` gỡ gói `arm64-android` và khôi phục gói PC từ
  binary-cache trong 1,6 s). Đừng cấu hình hai nền xen kẽ trong một lượt làm việc; sau khi cấu
  hình nền phụ, cấu hình lại preset hàng ngày trước khi dựng nó.

- `check.py` trên tệp include header của Vulkan SDK (`engine/shader/compiler.cpp`, `detail/slang.cpp`:
  `dxcapi.h`, `slang.h`): cùng bẫy với `tomlplusplus` ở nhóm Máy chủ — truyền `-I <SDK>/Include/dxc` thì clang-tidy
  đếm cả header của SDK là mã của dự án và đổ hàng trăm lỗi của chúng lên tệp. Cho đúng đường `-isystem` qua biến
  trình dịch và qua clang-tidy:
  `CPP23_G14="g++ -DNOMINMAX -isystem C:/VulkanSDK/<bản>/Include/dxc -isystem C:/VulkanSDK/<bản>/Include/slang"`
  (cả `CPP23_G15`, `CPP23_C20` với `clang++`), `CPP23_CLANG_TIDY="clang-tidy --extra-arg=-DNOMINMAX
  --extra-arg=-isystemC:/VulkanSDK/<bản>/Include/dxc --extra-arg=-isystemC:/VulkanSDK/<bản>/Include/slang"`, rồi
  `check.py -I engine <tệp>` (đo 2026-10-13). `dxil.cpp` vẫn đỏ ở GCC MinGW vì header `d3d12shader.h` của MinGW thiếu
  `D3D_SVT_INT64` và `D3D_REGISTER_COMPONENT_FLOAT64`: giới hạn của môi trường, Clang qua.
- `std::bit_cast` giữa hai con trỏ hàm (đọc `GetProcAddress`) bị clang-tidy 23 chặn bằng `bugprone-bitwise-pointer-cast`;
  `reinterpret_cast` thẳng giữa hai chữ ký hàm bị `-Wcast-function-type` của GCC và `-Wcast-function-type-strict` của
  Clang chặn, kể cả khi đi qua `void (*)()` (Clang strict vẫn báo). Dùng `find_symbol` của `engine/shader/detail/library.hpp`
  (bit_cast kèm NOLINT có lý do), đừng ép tay ở chỗ khác.

- Dựng `gcc-debug` trên máy này: preset không chạy vcpkg nên cấu hình dừng ở `find_package(SDL3 CONFIG REQUIRED)`
  (`CMakeLists.txt`, trong `if(WIN32)`). Thêm `-DCMAKE_PREFIX_PATH=C:/dev/third_party/installed/x64-windows-static-md
  -DGAME_TOML_INCLUDE=C:/dev/third_party/installed/x64-windows-static-md/include` thì cấu hình qua và mọi tệp biên dịch
  được, nhưng `thienlong_client.exe`, `thienlong_audio.exe` và bốn test (`audio_dsp_tests`, `world_tests`, `client_tests`,
  `boot_tests`) không link vì SDL3 và opus của vcpkg dựng bằng MSVC (`Warning: corrupt .drectve`, hàng nghìn
  `undefined reference`): ctest báo `Not Run`, không phải lỗi mã. Hai test đó vẫn chạy được ở MSVC và `clang-asan`. Đo
  2026-10-14: 70/74 test qua, 0 lỗi biên dịch. Libpq cũng vắng ở bản này, nên `auth` và `store` không in hai dòng
  "bỏ qua database" mà `server_boot_tests.cpp` chờ ở MSVC và Clang (test nhận 0 hoặc 1 lần mỗi dòng).

## Công cụ Python và git

- Python trên Windows, `subprocess.run(..., input=chuỗi, text=True)`: chế độ văn bản ghi `\n` thành
  `\r\n` vào stdin của tiến trình con. Đưa một bản vá cho `git apply` kiểu đó thì nó báo "patch
  does not apply" dù bản vá đúng (đo 2026-10-08 lúc tách hunk của `CMakeLists.txt`). Truyền byte:
  `input=chuỗi.encode()` và không đặt `text`.
- Tách cây làm việc thành nhiều commit: thêm một enumerator vào header tầng dưới phải nằm cùng
  commit với mọi `switch` trên enum đó, không thì commit trung gian dừng ở `-Wswitch` (đo
  2026-10-08: `control::InputKind::kText` và `display_gpu.cpp`). Cây cuối đúng không nói lên điều
  đó; chỉ dựng lại từng commit trong một worktree tạm mới lộ ra.
- Nhánh `server` trùng tên với thư mục `SERVER` vì hệ tệp Windows không phân biệt hoa thường (đo
  2026-10-09): `git log --oneline -1 server` dừng với `fatal: ambiguous argument 'server': both
  revision and filename`. Thêm `--` sau tên nhánh: `git log --oneline -1 server --`; lệnh nhận cả
  nhánh lẫn đường dẫn (`log`, `diff`, `show`, `checkout`) đều thế.

## Test và công cụ đụng máy người dùng

- Thử giao diện bằng thông điệp chuột gửi thẳng cho cửa sổ client (đo 2026-10-08): để cửa sổ trên
  màn hình thì kết quả chập chờn, ít nhất ba lần bấm trượt trong sáu lượt chạy. Windows gửi cho
  cửa sổ dưới con trỏ thật một `WM_MOUSEMOVE` mỗi khi con trỏ nhúc nhích hay một cửa sổ khác hiện
  lên gần đó (tooltip của taskbar); thông điệp ấy không mang cờ nút nên client coi nút đã nhả và
  dời điểm bấm theo con trỏ thật. Ảnh chụp từ màn hình còn dính cửa sổ lạ, và cửa sổ client mở ra
  thì cướp bàn phím của người đang dùng máy. `TOOLS/run/click_shot.py` vì thế mở client bằng
  `SW_SHOWNOACTIVATE`, dời cửa sổ ra ngoài màn hình ảo và chụp bằng `PrintWindow(PW_CLIENTONLY |
  PW_RENDERFULLCONTENT)`: Vulkan vẫn vẽ đủ khung, ảnh ra đúng. `PrintWindow` đôi lúc trả ảnh
  toàn đen dù báo thành công; công cụ chụp lại tối đa năm lần, và dừng với mã 103 khi cửa sổ bị
  thu nhỏ giữa chừng. Đừng viết thêm công cụ bấm thử kiểu cửa sổ trên màn hình.
- Test đụng tới desktop thật của Windows (đo 2026-10-08 bằng `TOOLS/run/desk_watch.py`): con trỏ
  chuột là của cả phiên đăng nhập. Vòng kéo của Windows (`WM_SYSCOMMAND` với `SC_MOVE`) bật rồi
  tắt vùng giam con trỏ và đổi hình con trỏ sang đồng hồ cát 15 tới 35 ms mỗi lần; kiểu kéo bằng
  bàn phím (`SC_MOVE` trần) còn dời cả vị trí con trỏ về giữa thanh tiêu đề; và vòng kết thúc thì
  cửa sổ vừa kéo được kích hoạt, lấy bàn phím. Cho tiến trình test sang window station không
  tương tác (`tests/quiet_desktop.hpp`) chặn được việc lấy focus và việc chuột, phím thật chen
  vào, KHÔNG chặn được ba thứ của con trỏ. Vì vậy sáu ca vòng kéo nằm ở `window_modal_tests`,
  luôn dựng nhưng `ctest` không chạy (hiện "Disabled"; bật bằng `-DGAME_DESKTOP_TESTS=ON`). Sửa
  `SRC/window/window.cpp` thì chạy tay đúng một lượt `build/<preset>/window_modal_tests.exe` và
  báo người dùng máy trước. Không chạy lặp test loại này khi có người đang dùng máy: một nghìn
  lượt là con trỏ của họ nháy vài phút liền. Muốn nói một test hay công cụ "không đụng màn hình"
  thì đo bằng `python TOOLS/run/desk_watch.py <lệnh>` (vùng giam, vị trí nhảy, cửa sổ ở trước, cửa
  sổ mới hiện, hình con trỏ); chỉ soi vị trí con trỏ và danh sách cửa sổ là chưa đủ.
- Kiểm ô nhập và phím bằng `TOOLS/run/click_shot.py --type X,Y,CHỮ` (bấm ô rồi gửi `WM_CHAR`;
  `\t`, `\r`, `\b` là Tab, Enter, xoá lùi), không viết công cụ gõ riêng.

## Máy chủ

- Hàm khai `GAME_NONALLOCATING` hay `GAME_NONBLOCKING` (`core/effects.hpp`) dưới Clang 23 với STL
  MSVC 14.51 (đo 2026-10-09 ở `SRC/metrics/metrics.cpp`, cờ `-Wfunction-effects` của `check.py`):
  `std::string_view::substr` bị từ chối vì nó ném khi vị trí ngoài chuỗi (`_Xran`), và
  `std::string_view::find` bị từ chối vì nó gọi hàm véc-tơ hoá nằm ngoài header
  (`_Find_vectorized`). Thay bằng `remove_prefix`/`remove_suffix` và `std::ranges::find_if`. Đi
  qua không cảnh báo: `std::atomic` (`fetch_add`, `store`, `load`, `compare_exchange_weak`),
  `std::from_chars` và `std::to_chars` của số nguyên, `std::ranges::copy`, `all_of`, `any_of`,
  `transform`, `starts_with`, so sánh `string_view`, `core::check`.
- Windows nhận trọn một lần `send` không chặn dù nó lớn hơn vùng đệm của socket, miễn vùng đệm
  chưa đầy lúc gọi (đo 2026-10-09 ở `tests/metrics_serve_tests.cpp`): gửi 896 KB một lần cho một
  bên không đọc vẫn trả đủ 896 KB, nên phía gửi không bao giờ thấy "phải chờ" và hạn gửi không có
  dịp chạy. Muốn bên chậm bị phát hiện thì gửi từng khúc nhỏ (`metrics/serve` gửi 16 KiB một lần);
  với khúc 16 KiB, bên không đọc làm lần gửi phải chờ sau khoảng vài trăm KiB.
- Fuzz một bộ đọc ghi vào cấu trúc lớn cấp một lần (`metrics::Snapshot`, 280 KB) phải dựng với
  `-D_MSVC_STL_HARDENING=1`: ghi lệch chỉ số qua `std::span` hay `std::array` rơi vào phần khác của
  chính khối đó nên ASan không thấy. Đo 2026-10-09 ở `tests/fuzz/fuzz_metrics_snapshot.cpp`: bỏ
  phép kiểm chỉ số cột khỏi bộ đọc, không có cờ này một triệu vòng vẫn thoát 0, có cờ thì dừng sau
  khoảng 47.000 vòng.
- Hai phiên cùng cây chính, một phiên sửa client: dựng phần máy chủ ở cây riêng chỉ với target cần,
  `cmake --preset msvc-release -B build/srv-msvc` (trong `dev.bat`), `clang-asan -B build/srv-asan`,
  `gcc-debug -B build/srv-gcc` (hai cây sau ở shell thường), rồi `cmake --build build/srv-<tên>
  --target <exe và test máy chủ>` và `ctest --test-dir build/srv-<tên> -R <mẫu>`. Đo 2026-10-09:
  ba cây riêng dựng và chạy 13, 12, 12 test máy chủ trong lúc phiên kia đang sửa
  `SRC/client/android_main.cpp`; không dựng `all` (mục 11 của `AGENTS.md`).
- vcpkg `libpq` bản tĩnh (`x64-windows-static-md`, `default-features: false`): `find_package(PostgreSQL)`
  và `PostgreSQL::PostgreSQL` kéo `pgcommon`, `pgport` nhưng không kéo Winsock. Thiếu `ws2_32` trong
  `target_link_libraries` thì LNK2019 ở 17 ký hiệu (`closesocket`, `WSAStartup`, `getaddrinfo`...).
  Bản không OpenSSL vẫn xác thực SCRAM-SHA-256 được (đo với PostgreSQL 18.6, 2026-10-06).
- vcpkg `tomlplusplus` 3.4.0 cài thư viện đã dịch có bật exception và ép `TOML_HEADER_ONLY=0` qua
  target. Dùng không exception thì không link `tomlplusplus::tomlplusplus`: chỉ lấy
  `INTERFACE_INCLUDE_DIRECTORIES` của nó, khai `TOML_EXCEPTIONS=0` và `TOML_HEADER_ONLY=1` trước
  `#include <toml++/toml.hpp>`. Link target với `TOML_EXCEPTIONS=0` thì lỗi
  `undefined symbol: toml::v3::noex::parse_file`.
- `tomlplusplus` 3.4.0 dưới `check.py` (đo 2026-10-07): đưa thư mục include bằng `-I` thì GCC 16 và
  Clang 23 dừng ở `operator"" _toml` của thư viện (`-Wdeprecated-literal-operator` là lỗi ở C++23),
  và clang-tidy soi luôn header của thư viện. Đưa bằng `-isystem` qua biến trình dịch thì biên dịch
  và chạy ASan sạch, `<inc>` là `vcpkg_installed/x64-windows-static-md/include`:
  `CPP23_G14="g++ -isystem <inc>" CPP23_G15="g++ -isystem <inc>" CPP23_C20="clang++ -isystem <inc>"
  CPP23_CLANG_TIDY="clang-tidy --extra-arg=-isystem<inc>" python ~/.claude/cpp23/tools/check.py <tệp>`.
  Tệp include `<toml++/toml.hpp>` vẫn cần NOLINT `cppcoreguidelines-macro-usage` quanh hai
  `#define TOML_*` và NOLINT `misc-include-cleaner` cho các kiểu `toml::` (thư viện chỉ cho include
  tệp ô). Trong CMake thư mục đó là include `SYSTEM`. Chỉ một tệp `.cpp` của module `config` được
  include thư viện này. `<inc>` phải là đường dẫn tương đối: đường dẫn tuyệt đối của dự án có dấu
  cách, `check.py` cắt biến trình dịch theo dấu cách nên mọi tệp báo lỗi giả.
- Windows, stdin là thiết bị rỗng (`< NUL`, `< /dev/null` của Git Bash, `subprocess.DEVNULL`,
  CTest): `GetFileType` trả `FILE_TYPE_CHAR` như console, `PeekNamedPipe` thất bại với lỗi 1 chứ
  không phải 109 (`ERROR_BROKEN_PIPE`) của ống đã đóng, nên mã chỉ hỏi "ống đã đóng chưa" sẽ chờ
  mãi (đo 2026-10-07). Phân biệt console bằng `GetConsoleMode`; thiết bị rỗng, tệp
  thường và handle hỏng đều là "stdin đã hết" (`SRC/process/self_win32.cpp`). Tái hiện:
  `SERVER/bin/thienlong_zone.exe --config SERVER/config < /dev/null` phải in `ready` rồi thoát 0
  ngay; bản trước ngày 2026-10-07 treo. (Từ 2026-10-08 đừng thử bằng `thienlong_gate`: nó cần tệp
  khoá `SERVER/data/gate/identity.key` và mở cổng `0.0.0.0:7000`, `7001` trước khi in `ready`.)
- Windows, tiến trình tạo bằng `CREATE_NEW_PROCESS_GROUP` sinh ra với Ctrl+C bị tắt, và con của nó
  thừa hưởng trạng thái đó. Exe chạy tay trong console phải gọi `SetConsoleCtrlHandler(nullptr,
  FALSE)` để nghe lại Ctrl+C; tham số thứ hai của `SetConsoleCtrlHandler(handler, Add)` là TRUE khi
  thêm trình xử lý, FALSE là gỡ. Tái hiện: phần `ctrlc` và `break` của
  `docs/giao-viec/P2-DOT-1/kiem-claude/boot_check.py`.
- Windows, chạy `pg_ctl start` từ trình giám sát: tiến trình con mặc định thừa hưởng mọi handle
  thừa hưởng được và job của cha. PostgreSQL do `pg_ctl` sinh ra giữ luôn đầu ghi của ống stdout
  nên bên đọc ống không bao giờ thấy hết dòng, và nằm trong job `KILL_ON_JOB_CLOSE` nên chết theo
  giám sát. Chạy lệnh loại này bằng `process::Mode::kCommand`: ngoài job, stdin rỗng, danh sách
  handle thừa hưởng chỉ có ba handle chuẩn (`PROC_THREAD_ATTRIBUTE_HANDLE_LIST`), và đọc kết quả
  bằng mã thoát chứ không chờ ống đóng. Tái hiện: `boot_check.py SERVER/bin SERVER/config survive`.
- Winsock dưới `check.py` (đo 2026-10-08, tệp thử mở cổng nghe trên `127.0.0.1`, nối không chặn,
  `WSAPoll`; GCC 16 và Clang 23 dựng sạch, nối `-lws2_32`): include `"core/win32.hpp" // IWYU
  pragma: keep` trước, rồi `<winsock2.h>`, `<ws2tcpip.h>`. clang-tidy từ chối `handle ==
  INVALID_SOCKET` (`modernize-use-integer-sign-comparison`): dùng `constexpr SOCKET kNoSocket =
  ~SOCKET{0};`. `WSAEWOULDBLOCK` và các mã lỗi khác đòi include thẳng `<winerror.h>`.
- libFuzzer chạy được trên máy này với Clang 23 đích MSVC (đo 2026-10-08): `clang++ -std=c++23 -g
  -O1 -fsanitize=fuzzer,address,undefined -fno-sanitize-recover=undefined x.cpp -o x.exe`, rồi
  `x.exe -runs=1000000 -seed=<n> <thư mục corpus>`. Harness gọi bộ giải mã rồi bỏ kết quả thì trình
  dịch xoá luôn vòng đọc: bản cố ý đọc quá biên chạy hết một triệu vòng không báo gì. Harness phải
  dùng kết quả (mã hoá lại rồi so, hoặc ghi vào biến `volatile`); khi đó ASan báo
  `heap-buffer-overflow` ngay và ghi tệp `crash-*`. Harness dùng `std::string` hay `std::vector`
  còn phải dựng với `-D_DISABLE_STRING_ANNOTATION -D_DISABLE_VECTOR_ANNOTATION`: thư viện
  libFuzzer dựng sẵn tắt chú thích ASan của STL MSVC, lệch thì lld-link dừng với
  `/failifmismatch 'annotate_string'` (đội Grok gặp ngày 2026-10-08; lệnh đầy đủ ở
  `TOOLS/server/fuzz_protocol.py`).
- Bản cài `SERVER/bin` không tự theo mã: thêm một khoá vào tệp cấu hình mà chưa cài lại thì exe cũ
  từ chối cả tệp (đo 2026-10-08: `gate.toml:32: khoá lạ idle_timeout_ms`, thoát 2). Kiểm nhanh
  trước khi chạy cụm: `SERVER/bin/thienlong_lint.exe --root SERVER --refs TOOLS/server/refs` phải
  in `lỗi: 0`.
- PostgreSQL không nhận cổng 0 (đo 2026-10-09 với 18.6): `postgres -D <thư mục dữ liệu> -c port=0
  -C port` dừng với `FATAL: 0 is outside the valid range for parameter "port" (1 .. 65535)`. Cụm
  PostgreSQL tạm của test hay công cụ vì thế phải xin một cổng trống trên `127.0.0.1` rồi ghi số
  vào cấu hình, khác gate và các tiến trình của dự án vốn nghe cổng 0 rồi báo cổng thật ở dòng
  `ready`. Giữa lúc trả cổng và lúc PostgreSQL nghe còn một khe: mất cổng thì `pg_ctl start` hỏng,
  phải để phần đó báo hỏng chứ không thử lại lặng lẽ (lớp `TempPostgres` của
  `docs/giao-viec/P2-DOT-1/kiem-claude/boot_check.py`). Vì cùng lý do, `[postgres] port = 0` trong
  `cluster.toml` vẫn là "ngoài miền" dù các cổng nghe khác trên `127.0.0.1` nhận 0.

## Port từ client 2026

- Chuyển cảnh của bản 2026 không phải một post filter (đo 2026-10-09). Post filter `Fade` của
  `Render.dll` là màn hình ngả xám: `0x180028000` chạy mỗi nhịp, khi cờ `+0x94` của hệ vẽ bật thì
  số đếm `+0x98` tăng 5 tới 100 và hàm đặt `ColourAmount = (100 - đếm) / 100`, `GrayAmount = đếm /
  100` cho filter đó. `FadeColor` chỉ có một chỗ nhắc tên, trong factory của nó, và `Game.exe` không
  có chuỗi nào tên hai filter này. Thứ người chơi thấy lúc đổi cảnh là bảng giao diện `SceneTrans`
  (tấm rồng 256 x 256 ghi "前往<tên cảnh>[phần trăm]", sự kiện `PLAYER_LEAVE_WORLD`,
  `ON_SCENE_TRANSING`, `SCENE_TRANSED`) và `SceneTransB` (đếm ngược trước khi chuyển). Tái hiện:
  `python -B TOOLS/port/pe_refs.py "F:/tl 2026/Bin64/Render.dll" func 0x180028000` và `python -B
  TOOLS/content/lua_plain.py "F:/tl 2026/_raw" build/lua-2026 SceneTrans SceneTransB`.
- Bộ tài nguyên `_iv` nằm cạnh bộ thường nhưng `Game.exe` bản này không dùng (đo 2026-10-09):
  `CharModelEx`, `CharFaceGeo`, `CharHairGeo` có cột tên `_iv`, `Model` có `*_iv.skeleton`,
  `*_iv.mesh`, `Config` có `ItemVisualChar_iv.txt`. Cờ chọn chúng (`0x14103ef58`) không có lệnh nào
  ghi và `SystemSetup:IsClassic()` trả hằng 1. Hai bộ cùng tên clip nhưng KHÁC tư thế (clip đứng của
  nam lệch nhau 11 đến 14 độ ở xương đầu), nên lấy nhầm tệp `_iv` là sai hình mà không báo lỗi. Số
  đo ở mục 8.6 của `docs/TAO-NHAN-VAT-2026.md`.
- OGRE của client 2026 không cộng dồn animation cảnh (đo 2026-10-09): `_applySceneAnimations`
  (`OgreMain.dll` `0x18016e340`) đặt lại node rồi mới áp, cho TỪNG state, và `setEnabled(true)` đưa
  state về cuối danh sách, nên state bật sau cùng thắng trọn. Mã gốc vì thế không bao giờ tắt state
  cũ (`CCamera_CharSel`). Port một lớp điều khiển animation của node thì giữ "state bật gần nhất",
  đừng cộng hay lấy trung bình các state đang bật. `Quaternion::Slerp` của bản này là bản có ngưỡng
  1 − 1e-3 và `atan2`, không phải bản `acos` của OGRE 1.2.
- Tên kiểu trùng trong một namespace giữa hai header chỉ lộ ra ở tệp include cả hai (đo
  2026-10-09): `control::CameraPose` đã có ở `follow_camera.hpp`; khai thêm một `CameraPose` ở
  `char_camera.hpp` thì từng tệp vẫn qua `check.py`, tới `display_gpu.cpp` MSVC mới báo "uses
  undefined struct". Trước khi đặt tên kiểu mới trong module: `grep -rn "struct <Tên>" SRC/<module>`.

- DLL của client gốc gọi được từ Python để làm trọng tài cho bản port (đo 2026-10-08):
  `os.add_dll_directory("F:/tl 2026/Bin64")` rồi `ctypes.CDLL` nạp được `PathLib.dll`,
  `tEngine.dll`, `Render.dll`; hàm xuất kiểu C++ gọi theo tên đã trang trí, hàm ảo gọi theo số ô
  của vtable (`TOOLS/port/pathlib_oracle.py`). Số thực ghi bằng mẫu bit để test so từng bit;
  module port dựng với `-ffp-contract=off`. Lưới thử tự vẽ phải giống dữ liệu thật: với lưới có
  đỉnh nằm giữa vùng trống, `PathLib.dll` đọc ngăn xếp chưa khởi tạo khi né góc và 29 trên 400
  đường đi của nó không tái hiện được; `TOOLS/port/make_path_mesh.py` vì thế chỉ đặt đỉnh trên
  mép vật cản.
- Lưới đi của client 2026 là tệp `.path` (cột thứ 6 của `SceneDefineEx.txt`), không phải
  `.region` như client cũ và như `src/walk` của TLBB Dev; kho có 419 tệp `.path` cho 513 tệp cảnh.
  Sửa `SRC/nav` thì chạy `nav_tests`: nó so từng bit với `tests/golden/nav_*.tsv`; số vàng chỉ
  sinh lại bằng trọng tài, không sửa tay.
- Script Lua của client 2026 (đo 2026-10-08): 226 trên 2047 tệp `Interface/**/*.lua` của `_raw`
  mã hoá (dấu hiệu `D2 D1 E2 E1 B2 B1 C2 C1`; từ byte 0x100 là GBK XOR "AS" theo vị trí), trong
  đó có script của các bảng chính. Script cùng tên ở `G:\TLBB\_content\source\Interface` là của
  bản cũ và khác nhiều (SelfEquip bản 2026 có 16 thẻ, khoá lên cấp, ô bảo thạch). Port hành vi
  cửa sổ thì giải bằng `python TOOLS/content/lua_plain.py "F:/tl 2026/_raw" build/lua-2026` rồi
  đọc ở đó. Hàm C++ mà script gọi thì tháo từ `F:\tl 2026\Bin64\Game.exe` (cách tìm ở mục "bảng
  nhân vật" của `docs/TIEN-DO.md`), đừng đoán theo tên.
- Mã nguồn 2008 ở `G:\TLBB\_ref` và bản TLBB Dev không phải chuẩn cho hành vi của client 2026
  (đo 2026-10-08 ở camera và chuột: pitch kéo được, zoom mượt qua đích, điểm nhìn cao 1,5 thay cho
  0,7, mặt cắt theo cảnh, số của sự kiện chuột lệch 1 từ số 5, phím xoay bị bỏ). Port một hành vi
  thì tháo hàm tương ứng trong `F:\tl 2026\Bin64` bằng `python TOOLS/port/pe_refs.py` (`rtti`,
  `func`, `text` rồi `refs`, `calls`, `vcalls`, `imports`, `jump`, `uses`, `imm`, `floats`; ví dụ ở
  `docs/CAMERA-2026.md`); mã 2008 chỉ dùng để gọi tên hàm. Hàm lá không có dòng `.pdata`: tìm
  biên hàm chỉ theo `.pdata` sẽ sót nó, `func` tự dò tới lệnh `ret`.
- `TOOLS/port/pe_refs.py <pe> exports <chuỗi con>` liệt kê hàm export kèm địa chỉ: các DLL của
  CEGUI trong `Bin64` (`CEGUIFalagard.dll`, `CEGUIBase.dll`) xuất hàm thành viên theo tên đã trang
  trí, nên tìm được ngay `populateRenderCache`, `onMouseButtonUp`... của một widget mà không phải
  dò RTTI (`exports "FalagardSoftKeyBoard@"`). Hàm lớn bị `.pdata` chia mảnh: tháo bằng khoảng
  `func <đầu>..<địa chỉ hàm export kế tiếp>`.
- Script Lua mã hoá của client (`lua_plain.py`) mất 24 byte đầu: chạy nó bằng trọng tài thì đưa
  phần đầu đoán được qua `--head` (QuestLog bắt đầu bằng một dòng chú thích, CommonSkill bằng
  `local COMMON_BUTTONS = {`). `TOOLS/port/lua_native.py` in địa chỉ hàm trung chuyển chung
  (0x1406864e0) cho phương thức kiểu đối tượng (`DataPool:...`, `Player:...`); hàm thật là địa
  chỉ nạp vào `rcx` ngay trước lời đăng ký.
- Trọng tài `lua_oracle.py` không có CEGUI: hành vi nào của widget mà script dựa vào thì phải mô
  phỏng trong `lua_oracle.lua`, thiếu thì số vàng sai mà test vẫn xanh vì bản port chép cùng lỗi.
  Đo 2026-10-09: nút đánh dấu `CheckMode` 1 (thẻ, ô chọn một) tắt các nút cùng cha khi bật; trước
  khi trọng tài biết luật đó, số vàng bảng nhiệm vụ giữ thẻ "hiện tại" bật sau khi bấm thẻ "nhận
  được" (5 khối sai, `quest_log.cpp` sai theo). Port bảng mới thì rà các phương thức và sự kiện
  script dùng (`SetCheck`, `StartFade`, `GetAlpha`...), tháo widget đó trong `CEGUIFalagard.dll`
  trước khi tin số vàng. Tên hàm của script có thể khác tên tệp (`CreateRole.lua` đăng ký
  `LoginCreateRole_*`): đưa qua `--name`.
- `math.random` trong script (bảng tạo nhân vật gieo bộ đồ tân thủ): kịch bản trọng tài thay nó
  bằng một dãy số đưa sẵn, test của bản port đưa cùng dãy qua hàm gieo tiêm vào; để nguyên
  `math.random` thì số vàng không lặp lại được.

## Giao diện và bản địa hoá

- Chuỗi `#{khoá}` viết trong `SRC/ui/panel/*.cpp` chỉ có trong bảng chuỗi của client sau khi chạy
  lại `python TOOLS/content/collect_ui.py "F:/tl 2026/_raw" CLIENT/data`: bộ gom quét các tệp đó.
  Quên chạy thì chữ ra rỗng mà không báo lỗi; dòng "chưa dịch sang tiếng Việt" của bộ gom nêu các
  khoá mới cần thêm vào `assets/i18n/vi.tsv`.
- Ảnh của `CLIENT/data/Interface` có chữ là ảnh đã thay theo ngôn ngữ của bản dựng, không còn là
  bản gom từ `_raw`: `build_i18n.py` thay ngay trong atlas và giữ bản gốc ở `build/i18n/base`, sổ
  băm ở `build/i18n/atlases.tsv`. Xoá `build/i18n` (hay cả `build/`) trong lúc `CLIENT/data` còn
  ảnh đã thay thì lượt dựng kế dừng với "atlas ... đang mang ảnh thay nhưng ... không còn bản gốc"
  (dấu `CLIENT/data/Table/i18n.applied.tsv` nhớ atlas nào đã thay): gom lại bằng `python -B
  TOOLS/content/collect_ui.py "F:/tl 2026/_raw" CLIENT/data --force` rồi dựng lại. So ảnh với
  `_raw` thì chạy `verify_ui.py --raw <_raw> --data CLIENT/data --i18n build/i18n`: thiếu `--i18n`
  thì mục 3 đỏ ở đúng các atlas có tên trong sổ (đo 2026-10-08: ba atlas, lệch tối đa 255).
- Ảnh nút tiếng Việt vẽ lại cả nút (góc bo, lề, viền khác bản gốc) thì đúng cỡ ô vẫn lệch khung
  và trông nhỏ hơn (chủ dự án thấy trên cửa sổ thật ngày 2026-10-08): chỉ thay phần chữ, giữ nền
  gốc từng điểm ảnh (`letter_buttons.py`). Ô của bộ ảnh gốc có khi chồng nhau: `Logon_Erweima_Pushed`
  khai ở hàng 118 trong khi `Logon_Erweima_Normal` chiếm hàng 102 tới 118; `build_i18n.py` từ chối
  hai ảnh thay khác nhau ở phần chung.
- Gom thêm một layout (thêm tên vào `DEFAULT_WINDOWS` của `collect_ui.py`) thì sinh lại golden ô
  cửa sổ trong cùng thay đổi: `python -B TOOLS/content/ui_rects.py --raw "F:/tl 2026/_raw"
  --collected CLIENT/data --out tests/golden/ui_rects.tsv`. Quên thì `gui_real_tests` đỏ ở "golden
  có đủ mọi cửa sổ ở bốn cỡ màn hình" (đo 2026-10-08 với `SoftKeyBoard`: thiếu 36 dòng). Bản mới so
  với bản cũ chỉ được thêm dòng của layout mới và đổi số layout ở dòng chú thích; dòng cũ đổi là
  bộ tính đã đổi, phải xem lại trước khi nhận.
- Ô cửa sổ có cỡ lẻ (đo 2026-10-08 ở `ActionSkill_Name`, `UnifiedSize` có offset 7,599998):
  `Window::getUnclippedPixelRect` (CEGUIBase.dll 0x1800a2000) đặt cạnh phải và dưới ở
  `PixelAligned(cỡ)`, nên ô dò chuột, ô cắt và ô `Hub::box` trả có cỡ đã làm tròn, còn phép đặt
  cửa sổ con và phép vẽ ảnh dùng cỡ lẻ (`shown_box` trong `SRC/gui/hub.cpp`). Layout chỉ có cỡ
  nguyên thì hai thứ trùng nhau, nên `gui_real_tests` chỉ đỏ khi gom thêm layout có cỡ lẻ.
- Cỡ điểm ảnh của cửa sổ con không tính từ UDim cỡ đã đặt mà từ `max - min` của vùng `URect` (đo
  2026-10-14 ở `BieYePersonnelManage_List1_Text_3`: vị trí `0,5` rồi cỡ `0,15` trong cha rộng 430 cho 64,
  không phải 65). `setWindowArea_impl` đặt `max = min + cỡ` qua cộng trừ float32 nên `max - min` có thể
  lệch 1 ulp, và `onParentSized` lúc layout gắn vào tấm nền tính lại cỡ từ giá trị lệch đó. Chỉ cửa sổ
  gốc cuối của layout được gắn, con chỉ bị tính lại khi cha có scale ở cạnh max (`layout.cpp`,
  `place_window`). Layout gốc luôn đặt thuộc tính trước cửa sổ con (đếm 2.035 layout), nên một lượt từ
  gốc xuống là đủ; layout mới có thuộc tính hình học đứng sau cửa sổ con thì mô hình này không đủ.
  Hai ca `area_size_is_max_minus_min`, `fixed_parent_does_not_resize_children` của `gui_sheet_tests` canh.
- `grep` thấy một dòng `<Imageset Name=... Filename=...>` trong `WoWLookSkin.scheme.xml` không có nghĩa
  client gốc nạp nó: ~3.800 dòng đó nằm lẫn trong những chú thích XML nhiều dòng (`chunfen`, `chunfen1`,
  `WeixinHongbaoPaisong` ở cuối tệp đều bị chú thích). Xác định bằng bộ phân tích XML chứ không bằng grep.
  Một lần đã thêm nạp imageset riêng theo scheme vì đọc sai chỗ này rồi hoàn nguyên.
- Giá trị thuộc tính ảnh có thể ngắt dòng giữa `set:` và `image:` (`NewExterior_PetPossJian.layout.xml`
  dòng 595, CR LF rồi thụt lề). `PropertyHelper::stringToImage` tách bằng `sscanf(" set:%s image:%s")` nên
  khoảng trắng nào cũng ngăn cách; `parse_image` phải tách y như vậy chứ không tìm `" image:"` (tìm kiểu đó
  làm tên bộ dính xuống dòng và ảnh bị ghi chú là thiếu).
- `Place::overrides` quét tuyến tính: `layout.cpp` (`apply_forced`, `forced`) duyệt cả danh sách cho từng cửa sổ
  và mỗi thuộc tính, nên `Hub::update` tốn O(cửa sổ × override). Game thật chỉ có vài override nên không sao;
  `gui_real_tests` từng ép `Visible=True` lên cả 94 nghìn cửa sổ của 2.027 layout và `update` mất 50–72 s mỗi
  cỡ màn hình, cả test 459 s (đo 2026-10-14, ctest `--timeout 300` làm nó đỏ giả). Nay `show_hidden` chỉ ép
  cửa sổ mà chính layout khai `Visible=False`: 96 s, cùng 0 ô lệch. Test nào dựng `Place` cho nhiều cửa sổ
  thì đừng nhét override cho từng cửa sổ.

## Dữ liệu, hình và bản dựng client

- Test `collision` trên tệp `.WCollision` thật cần thư mục `_raw` nằm ngoài dự án: đặt biến môi
  trường `THIENLONG_RAW_ROOT=<_raw>` trước khi cấu hình, hoặc cấu hình với
  `-DGAME_RAW_SCENE=<_raw>/Scene`. Không có thì ca `real_files_match_scan` của `collision_tests`
  và các ca cảnh thật của `collision_model_tests` bị bỏ, test trả 77 và CTest ghi Skipped, không
  đỏ. `collision_tests` và `collision_alloc_tests` hiện Skipped ở MỌI cấu hình, có `_raw` hay
  không: chúng dò `__has_include("collision/model.hpp")`, mà API truy vấn `Model` chưa có nên ca
  "chờ Model" luôn bị bỏ. Ba cây dựng `gcc-debug`, `clang-asan`, `msvc-release` của máy này đã lưu
  đường dẫn trong cache.
- Thư viện hiệu ứng `CLIENT/data/effect` (`all.effect`, `all.particle`, `materials.tsv`,
  `fx.files.tsv`) gom từ nguồn bản 2026 (`_raw/Effect`, `_raw/Material`, chữ GBK) bằng `python -B
  TOOLS/content/collect_fx.py "F:/tl 2026/_raw" "F:/tl 2026/_glb" CLIENT/data`; ảnh của hạt là PNG
  trong `CLIENT/data/Material`. Trước ngày 2026-10-08 thư mục này là bản nấu của client CŨ (chép
  từ `G:\TLBB\_content\cooked`, ảnh `tex/*.ttex`): cảnh 2026 gọi hiệu ứng không có trong đó thì
  không vẽ gì và không báo lỗi (`erengu_DL` gọi 16 tên, thư viện cũ có 2). Giờ client in lúc nạp
  cảnh một dòng "Hiệu ứng: N chỗ đặt thành ... ; bỏ M: ..." đếm từng lý do bỏ, bảy lý do của
  `fx::Skip` (`SRC/fx/cast.hpp`): tên không có trong thư viện, element chưa hỗ trợ, affector chưa hỗ
  trợ, hạt mesh, material không có trong bảng hoặc thiếu ảnh, material cần ảnh thứ hai hay cuộn UV
  hay shader riêng, material không cộng sáng; muốn biết một cảnh thiếu hiệu ứng gì thì đọc dòng đó
  trong log, đừng nhìn ảnh mà đoán. Dòng đó không kể những thứ vẫn vẽ nhưng vẽ thiếu (xoay hạt của
  Rotator, thời lượng và lặp của emitter): xem `docs/NGHI-NGO.md` mục 40.
- Đường nạp đo bằng mốc, không đoán (2026-10-13). Ba bẫy đã đo ở đợt đưa nạp đầu Đại Lý từ 1,06 s xuống 0,39 s:
  (1) `look_of` của `engine/resource/ogre_mesh.cpp` từng quét tuần tự hàng nghìn luật của `all.material` dưới một khoá chung:
  19 luồng đọc mesh xếp hàng, 310 mesh tốn 10,4 giây CPU cộng dồn; nay bảng băm bất biến (`table_of`) tra không khoá, 2,3 giây.
  Nghi nạp chậm thì cộng thời gian từng luồng đọc trước khi tối ưu chỗ khác. (2) Texture giao diện không dùng mip, nhưng
  `upload_queued` từng nướng cả chuỗi mip cho mọi ảnh RGBA8: phông GBK12 384 x 9192 tốn 48 ms; ảnh nào chỉ dùng mức 0 thì đặt
  `resource::Image::has_mips = false` (`render/ui.cpp` đã đặt cho mọi texture của `UiPass`). (3) Lần liệt kê adapter Vulkan
  đầu tiên của tiến trình tốn 100 tới 150 ms (nạp loader và mọi ICD); gọi nó ở luồng riêng sớm nhất (`Display::preload`)
  và đừng liệt kê cùng một backend hai lần. Thước đo: `TOOLS/run/bench_load.py` (số từng lượt, trung vị) và các dòng `Mốc` trong log.
  Hai việc ở luồng khác phải không đụng trạng thái chung: `ui::HudPrep` chạy `gui::GuiLoader` và bảng TSV ở luồng riêng
  — thêm `static` có thể đổi vào mã `gui` hay `table` là thêm cuộc đua dữ liệu (đã rà ngày 2026-10-13: không có).
- Tóc nhân vật trắng toát (đo 2026-10-13): `all.material` có 1313 dòng `set_texture_alias <baseTexture> x.dds` kết thúc bằng
  khoảng trắng (cả tóc `女主角头发01..`), và `last_token` của `engine/resource/ogre_mesh.cpp` lấy phần sau dấu cách cuối
  nên trả chuỗi rỗng: chất liệu mất ảnh, `attach_texture` im lặng bỏ qua, shader nhân ánh sáng với ảnh trắng dự phòng.
  Sửa ở `parse_rules` (cắt khoảng trắng cuối dòng sau khi bỏ chú thích); ca hồi quy `trailing_spaces_keep_the_texture`
  của `ogre_mesh_tests`. Thấy một phần model trắng trơn thì kiểm trước `material.color.image` của nó (có ảnh hay không),
  đừng sửa ánh sáng. Còn chất liệu tóc nhận `ColourChangable` (cộng ánh sáng, ambient và diffuse 0) mà đường lưới OGRE
  chưa mang (`Material::pass` rỗng với mọi lưới `.mesh`); màu tóc người chơi chọn (`SelectHairColor`) chưa có đường nào.
- Số lệnh vẽ của cảnh (đo 2026-10-13, Đại Lý resid 2, bảng đo `--pace`): 753 lệnh xuống 110 khi cho mô hình có skin
  trung tính gom bản sao (`Drawable::is_rest_neutral`, `Forward::State::is_flat_copy`). Nguyên nhân: 559 trong 586 vật
  thể không gom được là lưới OGRE mang một skin dự phòng mà loader dựng ra không có nút nào (`nodes = 1`,
  `inverse_bind` rỗng, mọi khớp rơi về phép đơn vị trong `add_joint`), và `can_batch` từng từ chối mọi model có skin. Tìm
  kiểu này bằng cách đếm item theo (primitive, vật liệu, số instance) trước khi nghĩ tới kỹ thuật lớn: 143 primitive
  khác nhau vẽ thành 753 lệnh nghĩa là gom instance đang hỏng, không phải thiếu multi-draw. Hai lệnh `Drawable` có
  danh sách thành viên viết tay trong hàm khởi tạo di chuyển và phép gán di chuyển: thành viên mới (như
  `is_rest_neutral_`) không chép thì về `false` âm thầm ở bản dựng mà vẫn biên dịch sạch. Còn 110 lệnh: lưới trộn alpha
  (27) vẫn không gom vì thứ tự xa tới gần của từng bản; gom thêm cần multi-draw indirect cộng bindless (lớp `gpu` có `draw_indexed_indirect` ở
  `engine/gpu/command.hpp` và `max_unbounded` ở `DeviceCaps`, client chưa dùng cái nào; chưa đo backend nào hỗ trợ đủ). Dự án `F:\tl 2026\2027` gom cùng kiểu (một lệnh mỗi
  primitive có instance): log `DEV/TLBBClient/log/gpu.txt` ghi `cảnh erengu_DL lệnh 312` và `đất 14 lệnh`, không phải 1–2.
- Nạp cảnh: chuỗi mip của texture phải nướng ở luồng nạp (`resource::stage_images` rồi
  `upload_queued(device, model, baked)`); gọi `upload_queued(device, model)` trên luồng vẽ cho
  model có ảnh lớn là nướng mip tuần tự ngay trên luồng vẽ (đo 2026-10-08: 2,5 giây cho 153 ảnh
  của `erengu_DL`). Số đo và việc còn lại ở `docs/giao-viec/KD-DOT-1/GHI-CHU.md` mục 6.
- Gói shader `.f2s`: `CMakeLists.txt` lấy danh sách gói thẳng từ `SRC/render/shaders/shaders.list`.
  Trước ngày 2026-10-08 nó chép tay bốn tên gói, nên hai gói `fx.vs`, `fx.ps` được dịch nhưng không
  được cài: bản `CLIENT/bin` không vẽ hạt nào và không báo gì (`FxView::open` trả rỗng khi thiếu
  gói), trong khi exe chạy từ `build/<preset>` thì vẽ. Kiểm bản cài chứ không chỉ bản trong cây
  dựng: `ls CLIENT/bin/shaders` phải có đủ một tệp cho mỗi dòng `shader` của `shaders.list`.
- Dựng `thienlong_client` cần Pillow: target `thienlong_i18n` chạy `TOOLS/content/build_i18n.py` ở
  mọi lượt dựng và tệp đó `from PIL import Image`. CMake chỉ bỏ bước này khi không có Python; có
  Python mà thiếu Pillow thì bước dựng dừng. Cài: `python -m pip install pillow`.
- Chép exe client vào `dev/client/bin` phải chép cả thư mục `shaders/` của CÙNG bản dựng, và không lấy exe từ cây main khi người dùng chỉ nhờ đổi một chỗ trên một bản đang test (đo 2026-10-14): ở lượt đầu bản `97ed65b` được dựng trong worktree và chép cả exe lẫn shader (biên dịch từ HLSL); các lượt sau exe dựng từ cây main (HEAD `b0f8904` cộng thay đổi chưa commit: commit nhảy `fe36a46`, `shaders.list` chuyển HLSL sang Slang, `engine/shader` và `engine/render/ui.*` viết lại) bị chép đè vào mà shader vẫn của `97ed65b`, cả 7 gói `.f2s` đều khác (`cmp`), người dùng thấy bản có nhảy, có điều khiển và nhiễu hình mà họ không yêu cầu. Muốn một bản chỉ khác bản đang test đúng phần được nhờ thì dựng ở `.worktrees/<tên>` từ đúng commit rồi chồng riêng phần đó (`git diff --stat` của worktree phải chỉ có tệp của việc ấy); đối chiếu bằng `cmp` từng gói `.f2s` giữa `build/<preset>/shaders` và `dev/client/bin/shaders` trước khi giao.
- Ảnh đầu 3D của ô chân dung (`HeadShot`, `render::Canvas` nền trong suốt) từng bị xuyên thấu, lộ viền vàng của khung tròn qua tóc và trán (đo 2026-10-14 trên Đại Lý `--scene-id 2 --frames 120`, bản trước khi sửa: chụp hai lần, nền canvas trong suốt và nền đen đặc, vùng đầu 84x96 khác nhau ở 495 điểm ảnh mà ở bản nền đặc không phải đen thuần, tức điểm ảnh của đầu có alpha dưới 1). Hai nguyên nhân, sửa cả hai: (1) pixel shader model trả `alpha = texel.a * ...` cho chất liệu KHÔNG trộn, pipeline không trộn ghi thẳng giá trị ấy vào canvas nên tóc, mi, mép cắt alpha có alpha dưới 1; nay `forward.cpp` đặt cờ `kOpaqueAlpha` cho mọi lệnh không phải `kBlended` và shader trả alpha 1 sau phép cắt; (2) pipeline trộn của forward ghi màu đã nhân alpha (`src * a + dst * (1 - a)`, alpha `a + dst.a * (1 - a)`) còn `UiPass` trộn ảnh canvas như alpha thẳng nên mép trộn bị nhân alpha hai lần; nay `UiPass::add_view` đánh dấu ảnh là premultiplied và `ui.ps` giải nhân (`ScreenBlock::size.z`, varying `premultiplied`). Đừng sửa bằng cách xoá canvas thành màu đặc: nền đặc cho hộp đen vuông phía trên vòng vì mặt nạ `HeadRoundRegion` là hình chữ nhật ở nửa trên. Hai gói shader `model.ps`, `ui.ps` và `ui.vs` đổi theo, nên exe và `shaders/` phải đi cùng nhau (bẫy ở trên).
- Gói shader `.f2s` có khoá kiểm cũ-mới gồm phiên bản Slang, DXC và băm nguồn, nhưng KHÔNG gồm cách trình dịch ghép
  phản chiếu: đổi `engine/shader/compiler.cpp` hay `detail/reconcile.cpp` mà không tăng `kPipeline` thì `thienlong_shader`
  in `[còn mới]` cho cả 7 gói và giữ nguyên gói cũ mang phản chiếu của quy trình trước (đo 2026-10-13: gói trong
  `build/msvc-release/shaders` khác băm gói dựng sạch). Đổi quy trình dịch thì tăng `kPipeline`; nghi gói cũ thì dựng
  vào thư mục trống để so: `thienlong_shader build src/client/render/shaders/shaders.list --out <thư mục trống>
  --target spirv,dxil,dxbc,glsl`, rồi `thienlong_shader show <gói>` so băm `phản chiếu` giữa các đích (phải bằng nhau).
- Chụp ảnh khung đầu bằng `thienlong_client --shot` mà mở cửa sổ ở chế độ thu nhỏ (`Start-Process -WindowStyle
  Minimized`) thì khởi tạo hiển thị dừng với `InvalidArgument: texture: rộng hoặc cao bằng 0`: vùng vẽ của cửa sổ thu
  nhỏ rộng 0 nên texture độ sâu của swapchain rộng 0. Lỗi trông như hỏng dữ liệu hay shader nhưng bản cài cũ cũng dừng
  y hệt (đo 2026-10-13). Chạy cửa sổ thường; cửa sổ bật lên ngắn trên màn hình người đang dùng máy, nói trước. So
  ảnh chụp của hai bản thì chụp mỗi bản hai lần: cảnh có hạt và hoạt ảnh nên hai lượt của cùng một bản đã lệch
  3.432 điểm ảnh (Đại Lý có giao diện) và 10.174 (màn đăng nhập) trên 921.600; chênh giữa hai bản chỉ có nghĩa khi
  nhỏ hơn mức nhiễu ấy. `--bare` (cảnh 3D thuần, không giao diện) của Đại Lý cho hai ảnh giống nhau từng điểm ảnh.
- `thienlong_client --shot <ảnh>` không nêu `--frames` thì chụp xong vẫn chạy tiếp như bản chơi thật; công cụ chờ tiến
  trình thoát sẽ treo tới hết giờ (đo 2026-10-13: 120 giây, ảnh đã ghi từ giây 0,6). Chụp rồi đóng: thêm `--frames 3`.
  Cờ này cũng là cách dò log nạp cảnh trên máy không có người ngồi.
- `collect_map.py` trước 2026-10-13 không gom lưới đi `.path` và mặt công trình `.WCollision`: map nào gom từ bản cũ
  của công cụ thì client in `Lưới đi: cảnh không có tệp .path: nhân vật không bị vật cản nào chặn` và nhân vật đi xuyên
  mọi vật cản, dù kho gốc có đủ hai tệp (đo: `dali_new_320` và `luoyang_new` đều thiếu). Nay `collect_walk` gom theo tên
  `.path` của cột 5 bảng cảnh và tên cảnh đổi đuôi `.WCollision`. Map gom từ trước chạy lại công cụ là đủ (idempotent);
  cảnh không có hai tệp ở kho gốc (như `tl3chuangjian`) chỉ để lại ghi chú. Kết quả sau khi gom lại: Đại Lý 11.669 đỉnh,
  23.324 tam giác, 11.665 cạnh vật cản; Lạc Dương 10.546 đỉnh, 21.080 tam giác, 10.543 cạnh vật cản.
- Bảng F3 (`ui/pace`) báo TRƯỢT với FPS đúng 60,0 trong cửa sổ thật không có nghĩa giao diện chậm: client trình Fifo
  (`frame.cpp`, commit `2953249`) nên khung khoá vào nhịp quét của màn, mà Windows đang đặt màn 1920x1080 ở 60 Hz
  (đo 2026-10-14 bằng `Win32_VideoController.CurrentRefreshRate` = 60, `MaxRefreshRate` = 200). Ngân sách 120 Hz là
  8,3 ms nên mọi khung 16,7 ms đều "vượt". Đã sửa cùng ngày: trình Fifo thì ngân sách là một nhịp quét của màn đang
  chứa cửa sổ (`frame_budget_ms` ở `face.cpp`, tần số từ chế độ hiển thị của SDL, đổi màn thì đọc lại), không biết
  nhịp quét thì mới về `1000 / render_hz`. Số CPU của khung (ghi lệnh, nộp, dựng UI) cộng lại chỉ khoảng 0,4 ms, còn
  "Xin ảnh" 15–16 ms là chờ nhịp quét. Chạy `--pace --shot ... --frames 150` (không qua cửa sổ thật, "Xin ảnh" 0,0 ms)
  (cờ `--pace` nay đã bỏ: bảng luôn hiện) thì màn chơi Đại Lý đứng im ra 1119 FPS, trung vị 0,3 ms, ĐẠT; màn đăng nhập 178 FPS, một khung đột biến 117,8 ms,
  vượt ngân sách 6,7% nên TRƯỢT. Muốn thấy trên cửa sổ thật số lớn hơn 60 thì đặt tần số quét của Windows lên 120 Hz
  trở lên (nếu màn hỗ trợ). Đường `--shot` không cùng đường trình với cửa sổ thật và bảng chưa có mili-giây GPU, nên
  đây là chặn trên của phía CPU. Đo lúc di chuyển: `--walk` (nhân vật tự chạy vòng, lúc thoát in bước chân mỗi khung).
- Chu kỳ khung đo bằng đồng hồ CPU quanh `present` không phải nhịp ảnh lên màn: sau một lần lỡ nhịp quét các mẫu dồn
  lại (khung 33 ms rồi 0 ms) nên bước chân và hoạt ảnh không đều dù trung vị 16,7 ms. Dùng `Swapchain::wait_shown`
  (`face.cpp`/`frame.cpp`, `await_shown`) làm mốc khung; đo p95 và lớn nhất, đừng chỉ nhìn trung vị.
- Mũi tên minimap (và mọi thứ đặt ở nửa điểm ảnh) rung 1 px mỗi khung nếu vị trí suy lại từ phép chia số thực: đặt thẳng
  vào tâm khi biết nó ở tâm (`Radar::is_centred_u`). Tái hiện: `gui_sheet_tests` ca `radar_arrow_steady`.
- `vkAcquireNextImageKHR` trả số ảnh swapchain TRƯỚC khi GPU vẽ xong khung trước dùng ảnh đó: nó chỉ hứa báo semaphore
  phía GPU. Mọi bộ đệm Upload ánh xạ sẵn mà CPU ghi theo số ảnh (UBO của khung, ma trận thế giới, bảng xương, đỉnh UI,
  quad hạt) vì thế bị ghi đè lúc GPU còn đọc: cây cối, trời, đất "nhảy loạn" mỗi khi camera đi, minimap giật (đo
  2026-10-14, Đại Lý, Fifo 3 ảnh, `--walk`: 893 trên 893 khung ghi vào bộ đệm GPU còn dùng, đều vì chính ảnh swapchain
  đó). Sửa: `gpu::Timeline` của khung, mỗi lần nộp báo số thứ tự khung; trước khi ghi bộ đệm của ảnh nào thì
  `wait_slot` chờ số của lần cuối dùng ảnh đó (và vòng `image_count` khung). Sau sửa 871 khung, trung vị 16,7 ms,
  p95 17,4 ms, 0 lỗi lớp kiểm. Bộ đệm mới đánh số theo ảnh swapchain phải đi sau `wait_slot`; số khung phải chờ in ở
  dòng "Khung phải chờ GPU nhả bộ đệm của ảnh" lúc thoát.
