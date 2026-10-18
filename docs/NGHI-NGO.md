# Sổ nghi ngờ

Mỗi mục: chỗ nghi, vì sao chưa chắc, cần gì để kết luận. Mục đánh số không đổi; đóng mục nào thì ghi
kết luận ngay dưới mục đó chứ không xoá.

## Bước B1 — cửa sổ (2026-10-05)

1. **Kéo hoặc đổi cỡ cửa sổ bằng chuột làm đứng vòng lặp.** Trong lúc người dùng giữ chuột trên
   thanh tiêu đề hay mép cửa sổ, Win32 chạy vòng thông điệp riêng bên trong `DispatchMessage`, nên
   `pump_messages` không trả về. Ghi theo sổ của Forge2 (mục window số 1), CHƯA tự đo ở đây: phép
   thử của bước này đổi cỡ bằng `SetWindowPos` từ tiến trình khác, không qua vòng modal. Bước B1
   chưa vẽ gì nên chưa có hệ quả; từ B2 khung hình sẽ đứng trong lúc kéo. Cần: chạy tay, kéo mép
   cửa sổ khi đã có phần vẽ, rồi chọn vẽ từ `WM_TIMER` trong vòng modal hay chạy cửa sổ trên luồng
   riêng.

   Kết luận (2026-10-05, đã đo, đóng): nhịp vẽ đi bằng `WM_TIMER` trên luồng tạo cửa sổ, không tách
   luồng. HWND gắn luồng tạo, vòng khung hình đã ở đó. `WM_ENTERSIZEMOVE` gọi `SetTimer`, `WM_TIMER`
   gọi `ModalTick`, `WM_EXITSIZEMOVE` gọi `KillTimer`. Cây làm việc gọi `set_modal_tick` từ
   `viewer_win32.cpp`; tệp đó đang lẫn phần hiển thị chưa commit nên commit này không gồm nó.

   `WM_QUIT` gửi trong vòng modal bị nuốt và không làm vòng đó kết thúc. Đã đo trước khi hoãn lệnh
   thoát: `request_quit` một mình trong nhịp, mã thoát -1073740791, log
   `build/gcc-debug/window-quit3-err.txt`. Sau sửa, mọi `request_quit` trên luồng đang kéo ghi cờ
   vào cửa sổ đang kéo và gửi `WM_CANCELMODE`; `WM_QUIT` chỉ gửi khi vòng đã kết thúc. Đóng một cửa
   sổ khác trong lúc cửa sổ này đang kéo đi cùng đường đó, không chỉ cửa sổ đang kéo.

   Huỷ `Window` giữa `window_proc` (kể cả trong nhịp) không xoá trạng thái ngay. `proc_depth` đếm
   proc lồng nhau; `unique_ptr` được giữ tới khi proc ngoài cùng trả về; `GWLP_USERDATA` bị xoá
   trước để thông điệp sau không dùng trạng thái đang chết.

   Vòng modal trả về mà không có `WM_EXITSIZEMOVE` thì cuối `pump_messages` tắt nhịp và gửi nốt
   lệnh thoát đã hoãn. Nếu không, cờ kéo và timer còn sống sau khi vòng đã thoát.

   Ba `thread_local` trong hàm (cửa sổ đang kéo, độ sâu proc, chuỗi chờ huỷ) là trạng thái của vòng
   modal. `request_quit` không có cửa sổ để truyền. Lệch KTR-04, nghi ngờ 4 xử lý tiếp.

   Khoảng chờ khoảng 500 ms khi bấm thanh tiêu đề mà chuột chưa nhúc nhích là hành vi đã công bố
   (gamedev.net, 2015: vòng kéo chờ một thông điệp chuột hoặc phím). Chưa tái hiện ở đây.
   `PostMessage` và `SendMessage` `WM_NCLBUTTONDOWN`/`HTCAPTION`, và `PostMessage`
   `SC_MOVE|HTCAPTION`, trên cửa sổ ẩn không vào vòng modal (1–4 ms, 0 nhịp). `SC_MOVE` vào vòng và
   nhịp đầu tới sau 19 ms. Không gửi `WM_MOUSEMOVE` giả khi chưa đo được đường bấm thật.

   `build/gcc-debug/window_tests.exe` (GCC 16.2 debug): trước `SetTimer`, ca
   `modal_resize_runs_tick_before_pump_returns` đỏ (nhịp không chạy, watchdog 3 giây, `main` abort,
   mã -1073740791). Sau sửa cả bộ thoát 0, gồm `quit_alone_during_modal_move_survives` (chỉ
   `request_quit`), `close_during_modal_move_reaches_quit` (vòng kết thúc trước 1,5 giây),
   `other_window_close_during_modal_reaches_quit`,
   `size_move_flag_clears_when_pump_returns` (`SendMessage` `WM_ENTERSIZEMOVE` rồi `pump_messages`,
   cờ kéo tắt, nhịp không chạy tiếp), `quit_during_stuck_size_move_is_reported_once` (thoát khi cờ
   kéo còn mà không có vòng modal: lần pump đó trả `kQuit` đúng một lần) và
   `modal_tick_destroy_window_is_safe` (nhịp chuyển `Window`
   ra biến cục bộ, destructor chạy trong nhịp, HWND mất, không treo). Ba ca sau chưa có log đỏ
   riêng: chúng được thêm cùng bản sửa. `client_tests` thoát 0. `build/clang-asan/window_tests.exe`
   (Clang 23.1, ASan + UBSan) thoát 0, gồm ca huỷ cửa sổ trong nhịp.
2. **Ảnh màu là sRGB hay không.** Client gốc chạy Direct3D 9 không có sRGB; bộ nạp của Forge2 coi
   ảnh màu là sRGB và đích vẽ là định dạng sRGB. Chưa tới bước nạp ảnh (B4, B5) nên chưa có ảnh nào
   để so. Cần: ảnh chụp của bước B5 đặt cạnh ảnh chụp client gốc cùng vật thể; chỉ đổi khi sai rõ.
3. **Mã chép còn `throw`** (lệch LH-07). `core::widen` và `core::narrow` ném `std::length_error`
   với chuỗi dài hơn `INT_MAX` byte; nhánh tự cài của `core/function.hpp` ném
   `std::bad_function_call`; constructor của `core::Log` ném lại khi không tạo được luồng. Giữ
   nguyên theo luật của bước này (không viết lại kiểu lỗi). Cần: chủ dự án chốt lúc nào viết lại
   phần lỗi của mã chép sang `std::expected`.

   Kết luận (2026-10-05, đóng phần throw đã biết, không đổi kiểu `Result`/`Status`/`Error`):
   đường dẫn Win32 dài nhất 32767 ký tự UTF-16, thấp hơn nhiều so với `INT_MAX`, nên chuỗi dài hơn
   `INT_MAX` là lỗi lập trình. `widen`/`narrow` giữ chữ ký, `checked_size` gọi `core::check`.
   `MoveOnlyFunction` không còn là alias: cả nhánh thư viện và nhánh tự cài, chữ ký thường và chữ
   ký const, `operator()` gọi `core::check` khi rỗng trước khi gọi hàm trong. `Log::create` trả
   `Result<unique_ptr<Log>>` và chỉ bắt `std::system_error`; `bad_alloc` của `make_unique` vẫn ném
   vì không còn bộ nhớ để trả `Status`. `Checksum` gọi `core::check` khi `XXH3_createState` trả
   null, constructor xếp chồng giữ nguyên. `std::formatter<Error>::parse` vẫn `throw
   std::format_error` vì chuẩn bắt formatter ném kiểu đó. `check.py` 9 tệp 0 lỗi. `build/gcc-debug`:
   `core_tests`, `log_tests`, `function_fallback_tests`, `window_tests` thoát 0.
4. **Trạng thái toàn cục khả biến trong mã chép** (lệch KTR-04). `Hub` của log là biến `static`
   trong hàm, sống tới khi tiến trình thoát; `clip_list` của `window.cpp` là danh sách cửa sổ đang
   giam chuột của cả tiến trình (có NOLINT kèm lý do). Cả hai là thiết kế của Forge2. Nghi ngờ 1
   thêm ba `thread_local` trong hàm ở `window.cpp`: cửa sổ đang kéo, độ sâu `window_proc`, chuỗi
   cửa sổ chờ huỷ. Cần: quyết định có đưa chúng vào một đối tượng ngữ cảnh hay chấp nhận như ngoại
   lệ có ghi.
5. **Log đa luồng chưa chạy ThreadSanitizer.** `core/log.cpp` có vòng đệm không khoá (CAS trên
   `head`, bên xả ghi `tail`); bốn thân vòng lặp của nó đã đổi hình dạng cho qua cổng. Đã chạy
   `log_tests` (có luồng log thật) dưới ASan + UBSan trên Windows; TSan không có trên Windows.
   Cần: chạy preset `clang-tsan` trên Linux. Máy này không có Linux. Bản POSIX đã chạy
   `log_tests` trên Android (mục 7); lượt đó không có TSan.

   Lập luận thứ tự bộ nhớ ở commit a81fd6a: không thấy lỗ hổng trong hợp đồng ở đầu `log.cpp`.
   CAS `relaxed` trên `head` chỉ đặt chỗ, không chở dữ liệu. Luồng gọi ghi word nội dung `relaxed`
   rồi word đầu `release`; bên xả đọc word đầu `acquire` rồi mới đọc nội dung. `tail` chỉ bên xả
   ghi `release` sau khi đã xoá word về 0; luồng gọi đọc `tail` `acquire` trước khi ghi đè. Ca
   `log_eight_threads_keep_every_line`: 8 luồng, mỗi luồng 200 dòng, `Full::kWait`, không `sleep`.

   Câu kết luận cũ ("đóng phần kiểm được trên Windows" vì một lần gcc-debug và một lần clang-asan
   thoát 0) không đứng. Lượt 2026-10-05, cùng `build/gcc-debug/log_tests.exe`, 24 lần liên tiếp:
   17 lần thoát 0, 7 lần thoát -1073740940 (0xC0000374, hỏng heap). Lượt đo này không dựng song
   song. Chưa chạy gdb lại trong 24 lần đó. TSan không chạy: máy không có Linux. Android cùng
   ngày, `ctest --preset android-arm64`: `log_tests` thoát 0 một lần (0,97 giây). Chưa đóng.
   Chưa sửa `thread_local` trong log.

   Lượt 2026-10-07: 0xC0000374 không phải do vòng đệm. Nguyên nhân ở mục 12; phần TSan của mục
   này vẫn chưa làm.
6. **Chữ ký bẻ dòng trong mã chép.** Luật của dự án đòi chữ ký nằm trọn một dòng; mã chép giữ các
   chữ ký mà clang-format bẻ làm hai dòng (ví dụ `file_sink`, `Error::Error`) vì `check.py` không
   bắt và sửa hết là đổi thêm nhiều dòng của mã gốc. Cần: chủ dự án chốt có rút gọn bằng `using`
   alias cho toàn bộ mã chép hay không. (Đóng 2026-10-08: bộ cpp23 đã gỡ mọi luật hình thức, phần
   chung của `AGENTS.md` đồng bộ theo mẫu mới ghi "hình thức mã không phải luật", `check.py` không
   còn bước nào kiểm chữ ký một dòng.)
7. **Phần `.cpp` của core chỉ có bản Win32.** Trên Android và iOS, `core/text.hpp`, `core/log.hpp`,
   `core/thread.hpp`, `core/handle.hpp` có khai báo mà không có định nghĩa: gọi tới là lỗi liên kết
   (ồn, không sai lặng lẽ). Forge2 có các tệp `*_android.cpp` tương ứng nhưng chưa chép vì chưa
   module nào ở Android cần. Cần: chép khi phần GPU sang Android.

   Kết luận (2026-10-05, Android đã đo trên máy; iOS có mã, chưa build): giữ API C++ của engine
   (`Result`, `MoveOnlyFunction`, `park` dạng template). Biên hệ điều hành đã là C: futex, liblog,
   pthread, `android_native_app_glue.c`, UIKit qua `.mm`. Một lớp C bọc engine sẽ thành bản sao
   trên đường log và luồng, và không có bên thứ ba nào giữ ABI đó. Forge2 (d7fcd76) cùng kiểu,
   tệp `*_android.cpp` viết bằng C++.

   Bốn tệp POSIX dùng chung: `handle_posix.cpp`, `thread_posix.cpp`, `log_sink_posix.cpp`,
   `system_posix.cpp`. Android chờ 4 byte thấp của atomic 8 byte (Lenovo TB-X306F, ABI
   arm64-v8a, SDK 29, nhân 4.9, không có `futex_waitv`). Hằng `__ulock_wait` chỉ trong nhánh
   Apple của `thread_posix.cpp`. Nhánh Apple chưa được biên dịch trên máy này.

   Đã đo: `check.py` 15 tệp, 0 lỗi (GCC 16.2, Clang 23.1, tidy). APK
   `build/android-arm64/thienlong.apk` 10523045 byte, gói `vn.thienlong.client`. Mở lại
   NativeActivity, logcat `I THIENLONG: THIENLONG: nền tảng sẵn sàng` (pid 12309, 2026-10-06
   01:00:33 giờ máy). Ảnh 1280×800, điểm (200,200) và (640,400) đều R=27 G=75 B=110. `ctest
   --preset android-arm64` với `ANDROID_SERIAL=HA1RC00J`: 10/10 thoát 0, 4,28 giây. Trong 10 ca
   có `props_tests` vì cây làm việc đang đăng ký test đó; commit phần này không gồm
   `props.cpp`. `ios_main.mm` và `if(IOS)` có trong cây. Chưa cấu hình preset iOS, chưa build.
   GPU Android chưa bật. Heap log Windows (mục 5) chưa sửa trong commit này.
8. **Client chưa tạo `core::Log`.** Dòng log của mã chép đi đường ghi thẳng `stderr` (không luồng
   log, không tệp log). Đủ cho bước này; cần quyết khi có phần GPU ghi log nhiều: tệp log đặt ở đâu
   trong `CLIENT/`.
9. **Nhánh tự cài của `core/function.hpp` chưa chạy.** MSVC, Clang với STL MSVC và GCC đều có
   `std::move_only_function` nên dùng nhánh đầu; nhánh tự cài chỉ được biên dịch (qua
   `header_check` của preset `android-arm64`), chưa có ca test nào gọi nó.

   Kết luận (2026-10-05, đóng): `tests/function_fallback_tests.cpp` include `<version>` rồi
   `#undef __cpp_lib_move_only_function` trước `function.hpp`, nên include guard không bật lại macro.
   `static_assert` bắt `kIsFallback` cho chữ ký thường và chữ ký const. Ca chạy lambda, `operator
   bool`, và chữ ký const. Không gọi hàm rỗng vì `core::check` dừng tiến trình. GCC 16.2 debug:
   `function_fallback_tests` thoát 0. `check.py` không có `--run`: 0 lỗi ở định dạng, độ lồng,
   GCC 16.2, Clang 23.1 và tidy. Lệnh đó không chạy ASan. Chưa chạy ASan trên nhánh tự cài.
10. **Hai cách xử lý `misc-include-cleaner` với Win32 cùng tồn tại.** `SRC/io/platform_win32.cpp`
    (có từ trước) dùng NOLINT từng dòng và dựa vào danh sách `IgnoreHeaders` của `.clang-tidy`;
    mã mới include trực tiếp header con (`winuser.h`...) và lấy `<windows.h>` qua
    `core/win32.hpp`. Chưa sửa `platform_win32.cpp` vì ngoài phạm vi bước này. Cần: chủ dự án
    chốt một cách, rồi đổi tệp còn lại cho thống nhất.

    Đã đo một phần (2026-10-05): `platform_win32.cpp` và `shader/dxil.cpp` lấy `<windows.h>` qua
    `core/win32.hpp`, rồi include header con (`libloaderapi.h`, `d3d12shader.h`, `d3dcommon.h`,
    `winerror.h`). `check.py` hai tệp, 0 lỗi, GCC 16.2 và Clang 23.1. GCC cần header chuyển
    `TOOLS/check/isystem/d3d12shader.h` (trước 2026-10-09 nằm ở `build/check-isystem`, xoá `build/`
    là mất): MinGW 16.2 thiếu enumerator mà SDK 10.0.26100 có; không đưa cả thư mục `um` của SDK
    vào `-isystem` vì `windows.h` của SDK không dịch bằng GCC. Lệnh: `CPP23_G14="g++ -isystem
    TOOLS/check/isystem" CPP23_G15="g++ -isystem TOOLS/check/isystem" python
    ~/.claude/cpp23/tools/check.py SRC/shader/dxil.cpp` (đưa bằng `-I` thì header của SDK thành
    header thường và vấp `-Werror=undef`).
    `dxil.cpp` tách vòng lồng để qua cổng. `GetDesc` lỗi thì bỏ thành viên (cỡ 0, `std::max` không
    dấu cho cùng kết quả với `continue`). Vòng tài nguyên dừng ở lỗi đầu. `shader/compiler.cpp` vẫn
    `#include <windows.h>` trực tiếp vì kèm WRL và `dxcapi.h`; GCC của `check.py` chưa dịch mặt đó.
    Chưa đóng: đưa `compiler.cpp` sang cùng kiểu khi có đường include mà cả GCC và Clang đều dịch.
11. **(Đã đóng 2026-10-08) Camera và nhập liệu.** Camera và chuột của màn chơi là bản port từ
    mã máy của client 2026 (`docs/CAMERA-2026.md`): `control/follow_camera`,
    `control/player_input`. Bản của TLBB Dev (theo mã nguồn 2008) dùng từ 2026-10-06 đã được
    thay. Thuật toán kính Cool3D và ClientCamera của Loong (`SRC/camera`), bỏ ngày 2026-10-06
    rồi được commit `83c87f4` đưa lại, đã gỡ hẳn cùng lưới mực nước chỉ nó dùng (`WaterCover`
    của `client/map/liquid`). Chuột và phím gắn vào cửa sổ Win32 ở
    `client/viewer/viewer_win32.cpp`, cảm ứng Android ở `client/android_main.cpp` qua
    `control/touch`; Display nhận sự kiện qua `Display::input`. Phần còn ngờ của bản port ở
    mục 38.
12. **`log_tests` trên gcc-debug thỉnh thoảng thoát 0xC0000374.** Một lượt
    `cmake --workflow --preset gcc-debug` ngày 2026-10-05 thấy một lần 0xC0000374 rồi vài lần
    chạy lại thoát 0. Lượt đo riêng sau đó, không dựng song song: 24 lần
    `build/gcc-debug/log_tests.exe`, 7 lần thoát -1073740940, 17 lần thoát 0. Cùng việc với mục
    5. Chưa đóng. Chưa chạy gdb trong lượt 24 lần. Cần: backtrace lúc vỡ, rồi lặp dưới Clang
    ASan, trước khi sửa `thread_local` `std::string`.

    Lượt 2026-10-07, đã có backtrace và nguyên nhân gốc (ĐO). gdb bắt ngay lần đầu: luồng `log`
    đang thoát, `pthread_create_wrapper` → `_endthreadex` → `tls_callback` → `run_dtor_list` →
    `std::string::~basic_string` với con trỏ `0xfeeefeeefeeefeee`, tức destructor của một
    `thread_local std::string` chạy trên vùng nhớ đã `free`. Đây là lỗi của toolchain, không phải
    của vòng đệm log: GCC 16.2 MinGW bản luồng POSIX dùng TLS giả lập (`__emutls_get_address`),
    và với luồng tạo bằng `std::thread` hay `std::jthread` thì bộ nhớ của biến `thread_local` bị
    trả trước khi destructor của nó chạy. Tệp tái hiện 30 dòng không dùng mã dự án (một
    `thread_local` struct chứa `std::string` 200 ký tự, 400 luồng `std::jthread`): GCC hỏng 20
    trên 20 lần chạy, Clang 23 (TLS thật của Windows) 0 trên 20. GCC bản này không có cờ nào để
    dùng TLS thật (`-fno-emulated-tls` bị từ chối). Trên dự án: `log_tests` lặp 40 lần dưới
    Clang ASan + UBSan và 40 lần với MSVC đều thoát 0; dưới `gcc-debug` chết 1 trong 4 tới 1
    trong 30 lần. Cùng lượt, `window_tests` của `gcc-debug` chết một lần 0xC0000409 trong 12
    lần lặp; chưa bắt lại được dưới gdb (25 lần) nên CHƯA biết có cùng nguyên nhân không.

    Biến `thread_local` có destructor, tức dính lỗi này ở bản GCC MinGW: `core/log.cpp`
    (`line_buffer`, `drain_buffer`), `core/log_sink.cpp` (`joined`), `core/thread.cpp`
    (`local_name`), `core/clock.cpp` (`kTimer`), `fs/codec.cpp` (hai ngữ cảnh zstd, hai bộ đệm
    lz4), `window/window.cpp` (`deferred_head`), `gpu/gles/context_wgl.cpp` (`thread_bind`).
    Bản phát hành (MSVC) và bản Clang không dính. Chưa sửa: đây là mã hạ tầng chép từ Forge2,
    sửa là đổi thiết kế ở bảy tệp. Ba hướng, cần chủ dự án chọn: (a) bỏ destructor khỏi các
    biến đó (bộ đệm cỡ cố định trong `thread_local`, hoặc đưa bộ đệm về đối tượng sở hữu nó);
    (b) đổi bản GCC sang bản không dùng winpthreads rồi đo lại bằng tệp tái hiện (CHƯA thử, chưa
    biết có hết không); (c) chấp nhận bộ test `gcc-debug` thỉnh thoảng đỏ ở lúc luồng thoát. Tái
    hiện: `ctest --preset gcc-debug -R "^log_tests$" --repeat until-fail:40`.

    Lượt 2026-10-08, đã sửa phần mà bản GCC đang dựng. Thêm `core::thread_slot`
    (`core/thread_slot.hpp`): ở GCC MinGW giá trị nằm trên heap, giữ bằng một con trỏ
    `thread_local` không có destructor và không bao giờ trả (rò một giá trị mỗi luồng thay cho
    hỏng heap; bản GCC MinGW chỉ để kiểm chéo, không phát hành); toolchain khác vẫn là
    `thread_local` thường, huỷ khi luồng kết thúc. Chọn cách này thay cho ba hướng trên vì nó
    không đổi hành vi của bản phát hành, không đổi thiết kế của mã chép từ Forge2, và gỡ được
    bằng một dòng khi GCC có TLS thật. Đã chuyển: `core/log.cpp` (hai bộ đệm),
    `core/log_sink.cpp`, `core/thread.cpp`, `core/clock.cpp`, `window/window.cpp`. Chưa chuyển vì
    GCC trên Windows không dựng chúng (`GAME_HAS_GPU` tắt): `fs/codec.cpp`,
    `gpu/gles/context_wgl.cpp`; `core/thread_posix.cpp` thuộc nền POSIX, có TLS thật. Số đo:
    `thread_slot_tests` khi `thread_slot` còn là `thread_local` thường chết 6 trên 6 lượt dưới
    `gcc-debug`; sau khi sửa, `log_tests`, `thread_slot_tests`, `core_tests` lặp 40 lượt mỗi ca,
    hai đợt liền (200 lượt), không hỏng lượt nào. `window_tests` chết 0xC0000409 KHÔNG cùng
    nguyên nhân: mục 37.

    Lượt 2026-10-14, phần sửa trên MẤT rồi khôi phục. Trong cây gộp, `core/log.cpp` (hai bộ đệm),
    `core/log_sink.cpp` (`joined`) và `core/thread.cpp` (`local_name`) lại khai `thread_local
    std::string` trần, dù cùng sổ này ghi là đã chuyển (cây ghép lại sau vụ xoá nhầm 2026-10-09,
    `AGENTS.md` mục 0); `log.cpp` và `thread.cpp` còn include `core/thread_slot.hpp` mà không dùng.
    Đo trên `gcc-debug`: `log_tests` chết 21 trên 30 lần liên tiếp (đúng backtrace trên: gdb bắt
    `std::string::~basic_string` trên con trỏ `0xfeeefeeefeeefeee` trong `run_dtor_list`, ném
    `std::system_error: No such process`). Chuyển lại ba chỗ sang `thread_slot`: `log_tests`,
    `thread_slot_tests`, `core_tests` lặp 40 lần mỗi ca dưới `gcc-debug`, 0 lần chết. `window.cpp` và
    `clock.cpp` vẫn dùng `thread_slot`; chưa chuyển như cũ: `fs/codec.cpp`,
    `gpu/gles/context_wgl.cpp` (GCC Windows không dựng).
13. **Context EGL không hỏi mức anisotropy.** Bản WGL đọc `GL_MAX_TEXTURE_MAX_ANISOTROPY` khi có
    `GL_EXT_texture_filter_anisotropic`; bản EGL chưa từng đọc, nên trên Android
    `caps.max_anisotropy` luôn là 1 dù GPU có extension. Khi gộp hai bản vào `gpu/gles/probe.cpp`
    (2026-10-06) khác biệt này được giữ nguyên và có test ghim (`gles_probe_follows_the_api_flavor`).
    Chưa rõ là chủ ý (tiết kiệm trên GPU điện thoại) hay sót. Cần: chủ dự án chốt; nếu bật thì đo
    khung trên GE8320 trước và sau.
14. **Ba chỗ của bộ âm thanh còn chặn hoặc còn thô** (2026-10-06, sau khi viết lại bộ trộn).
    (a) Phát một hiệu ứng chưa nạp thì luồng game đọc tệp, giải mã và đổi tần số tại chỗ: chưa đo
    trên tablet, ước lượng vài chục ms cho mỗi giây âm thanh. (b) Thu hồi clip cũ khi hết 32 MB
    hoặc hết 64 chỗ: luồng game chờ bộ trộn báo, tối đa 200 ms; bộ trộn chỉ nhận lệnh ở đầu mỗi
    khối của callback, trên tablet mỗi callback cách nhau tới 20 ms. (c) Tiếng 3D có vận tốc đổi
    cao độ bằng nội suy tuyến tính trong `sample_at`, cùng loại ảnh phổ đã đo ở bộ đổi tần số của
    miniaudio; client chưa đặt vận tốc cho nguồn nào nên chưa nghe thấy. Cần: nạp ở luồng nền và
    thu hồi không chờ khi làm cooker; đổi `sample_at` sang sinc ngắn trước khi bật Doppler thật.
15. **Nút tự chiến đấu của HUD hiện theo suy đoán** (2026-10-06). `AutoAttack_Button` chỉ có ở
    client 2026 và script của nó đã mã hoá. `ui/panel/start.cpp` hiện gốc
    `AutoAttack_Button_Frame` và giấu nút "đang tự chiến đấu" nằm chồng lên nút "tự chiến đấu",
    chỉ dựa vào layout. Cần: quan sát client 2026 lúc vào game để biết nút có hiện sẵn không.
16. **Ba chỗ của bộ dàn chữ chưa có căn cứ đo** (2026-10-06, `ui/text.cpp`). (a) Dòng cao cỡ
    phông cộng 2 và ô chữ lùi xuống 1 điểm ảnh: lấy từ ghi chú về mã 2008 trong `ui_font.py`,
    chưa đối chiếu ảnh chụp client 2026. (b) Viền `#e` vẽ bằng bốn bản lệch một điểm ảnh; cách
    vẽ viền của bản gốc chưa đọc. (c) Thẻ `#gRRGGBB` và `#H` chỉ có ở bảng chuỗi 2026: đang đọc
    rồi bỏ, độ dài và ý nghĩa suy từ dữ liệu. Cần: một ảnh chụp client 2026 có chữ để so từng
    điểm ảnh. (Cập nhật 2026-10-08: `ui/text` đã port lại từ mã máy của `UI_CEGUI.dll` và
    `CEGUIBase.dll`, đặc tả ở `docs/GIAO-DIEN-2026.md` mục 5. Viền `#e` nay vẽ tám bản lệch, quad
    gradient `#g` có vẽ; còn lại theo dòng "Khác gốc" đầu `SRC/ui/text.hpp`: nháy `#b` không vẽ,
    biểu cảm và hoạt ảnh rộng 0, tham số sau dấu `*` của `#{ID*...}` chưa làm. Ảnh chụp client
    thật để so từng điểm ảnh vẫn chưa có.)
17. **Nhãn thẻ kênh chat bị cắt sau khi dịch** (2026-10-06). Thẻ rộng khoảng 40 điểm ảnh, vừa hai
    chữ Hán; "Tổng hợp", "Hệ thống", "Cá nhân" rộng hơn nên bị cắt hai đầu. Script gốc tự đặt tên
    thẻ lúc chạy, nên chỗ sửa đúng là bảng chat của `ui/panel` (nới thẻ hoặc dùng nhãn ngắn).
18. **`FalagardSuperProgress`: đã port từ mã máy 2026, còn năm chỗ khác gốc** (2026-10-06, viết lại 2026-10-15;
    `gui/paint.cpp` `draw_progress`, `gui/hub.cpp`, `gui/bar_tint.cpp`, `gui/text.cpp` `progress_text`). Hub trước
    đây theo mã 2008 (thanh tăng thì nhảy ngay, thanh giảm thì rút dần, vẽ mức lớn hơn); mã máy
    `CEGUIFalagard.dll` 2026 ngược lại. Trường: +0x3f0 mức muốn tới p, +0x91c mức đang chạy q (hàm tạo đặt 0),
    +0x918 `MoveSpeed`, +0x940 `LightEnable`, +0xa78 kiểu màu, +0xadc màu hiện hành (trắng), +0x3f8 mười một màu
    tầng. `updateSelf` (0x18007a760) đưa q tới p tối đa `MoveSpeed` mỗi giây và chỉ khi q ≠ p mới gọi hàm tính màu
    0x18007a250. `populateRenderCache` (0x180078870) vẽ theo min(p, q): thanh giảm thì rơi ngay, thanh tăng thì
    chạy theo `MoveSpeed`. Có `LightEnable`: state `Background` cả cửa sổ, `Enabled`/`Disabled` rộng bằng p trong
    `ProgressArea`, state `LightEnable` ở mép phải phần đầy (cỡ `LightArea`, không có thì vuông bằng cao
    `ProgressArea`), chữ của cửa sổ canh giữa; không có: chỉ `Enabled` rộng min(p, q) nhân màu hiện hành. Ảnh trước
    và sau của HUD cảnh 2: thanh máu, nội y nguyên (đầy); thanh nộ và thanh kinh nghiệm của nhân vật mẫu là 0 nên
    nay rỗng ngay (bản cũ còn đang rút dần từ 1 ở khung 60); thanh luyện công (`PROGRESSBAR_SHOW`) có nền, lề
    17x6, đầu sáng và chữ. Khác gốc: (1) dải state `Effect` (rộng bằng |p − q|, nhân `EffectColor`) chưa vẽ vì
    không look nào của kho 2026 khai `NamedArea` tên `Effect` (0 trên 46 look) nên hàm gốc không vẽ gì; (2) một
    `ColourRect` có bốn góc mà quad chỉ mang một màu, nên lấy trung bình bốn góc (mọi layout của khung nhân vật
    dùng bốn góc cùng màu); (3) `startpoint` trùng `endpoint` ở kiểu `uninterrupted` thì hàm gốc chia cho 0
    ra NaN, bản này lấy màu đầu; (4) `FlashPoint`, `FlashSetting` (nháy khi mức qua mốc, 0x180077f40) chưa port;
    (5) q của thanh mới bắt đầu ở `CurrentProgress` (bản 2026 bắt đầu ở 0, nhưng cửa sổ của nó có từ lúc nạp giao
    diện nên đã chạy tới 1 trước khi game nêu mức). Giả định chưa đo: độ trong của ảnh lấy theo
    `Window::getEffectiveAlpha` chuẩn của Falagard (nhân với cha, trừ `InheritsAlpha` tắt), chữ chỉ theo
    `Alpha` của chính cửa sổ (hàm gốc đọc cửa sổ + 0xec).
19. **Sáu cửa sổ con của khung nhân vật bị giấu theo suy đoán** (2026-10-06,
    `ui/panel/player_frame.cpp`). `PlayerFrame_HPHDSandBoxHPBK`, `PlayerFrame_GQ`,
    `PlayerFrame_DaoYi`, `PlayerFrame_XingLingDian`, `PlayerFrame_ERenSoulHit` (thanh và hàng điểm
    nằm chồng lên thanh nộ, hàng liên kích) và `PlayerFrame_PVPPK` chỉ có ở layout 2026; script
    2026 đã mã hoá, script đọc được không nhắc tới chúng. Giấu là suy từ vị trí chồng nhau và
    tooltip "trạng thái PK". Cần: quan sát client 2026 với nhân vật chưa môn phái.
20. **Bảng cảnh client đang nạp không phải bảng của bản 2026** (2026-10-06, phát hiện khi đối
    chiếu tên cảnh). `CLIENT/data/Config/SceneDefineEx.txt` có 297 dòng 24 cột; bảng DBC của
    `_raw/Config/SceneDefineEx.txt` có 680 dòng 25 cột. 254/297 dòng trùng (tên, tệp cảnh, token
    minimap) với dòng cùng id của bản 2026; 43 dòng khác (ví dụ id 0: `luoyangsnow.Scene` so với
    `luoyang_new.Scene`), 395 id của bản 2026 không có. Chưa sửa (ngoài phạm vi lát giao diện).
    Khi đổi sang bảng 2026 thì các dòng `scene/` của `assets/i18n/vi.tsv` thiếu 257 tên;
    `collect_ui.py` sẽ in ra.
21. **`Falagard/MapImage` và `Falagard/AnimateImage` không có mã nguồn** (2026-10-06,
    `gui/paint.cpp`). MapImage vẽ theo suy đoán từ layout và script đọc được: ảnh con chọn bằng
    `SetCurrentImage`, chưa chọn thì vẽ thuộc tính `Image`. AnimateImage chưa vẽ. Hoạt ảnh
    `CoolDownEnd2` mà 22 ô kỹ năng của thanh phụ nhắc tới không còn trong `wowanimate.xml` 2026
    (hỏng từ dữ liệu gốc, bộ nạp ghi chú một dòng).
22. **Giờ trong game của minimap đứng ở giờ Tý** (2026-10-06, `ui/panel/minimap.cpp`). Script gốc
    lấy `GetCurrentTime()` (bản 2008 trả giờ hệ thống 0..23 trong khi chỉ có 12 ảnh; bản sau hẳn
    trả chỉ số canh giờ, không có mã). Bảng nhận canh giờ từ người gọi; client chưa có máy chủ
    nên luôn đưa 0. Toạ độ trên minimap là chỗ đứng của người chơi; bản gốc đổi sang điểm dưới
    chuột khi chuột nằm trên minimap (đã làm: `coordinate_of` trong `ui/panel/minimap.cpp`; phần
    canh giờ luôn 0 còn nguyên).
23. **Texture ghi thẳng đường dẫn trong look chưa được gom** (2026-10-06). `verify_ui.py` mục 4b
    báo `Common/MeshBack.dds` của `TLBB_Look_MeshWindow` mất do gom: `collect_ui.py` chỉ gom ảnh
    qua imageset. Nền này thuộc cửa sổ đầu 3D (MeshWindow), làm cùng lúc với widget đó. Từ ngày
    2026-10-08 thêm `Common/jpg_RoleBack.dds` của `TLBB_Look_MeshWindowRole` (nền ô nhân vật 3D
    của bảng `SelfEquip`), cùng nguyên nhân.
24. **Ảnh đầu 3D của khung người chơi: phần còn ngờ** (2026-10-06, `look/head.hpp`,
    `client/display/portrait.cpp`; phần đã đo ghi ở TIEN-DO mục "Ảnh đầu 3D của khung người chơi").
    (a) Loại ô: script 2026 vẽ chân dung 2D (`PlayerFrame_Head_2D`), không còn lời gọi
    `AdjustHeadCamera` nào cho khung người chơi; lời gọi duy nhất còn sót (đã tắt) là khung đội với
    loại 2. Dự án dùng loại 2 cho khung người chơi vì cùng nằm mép trái; hai mô hình người chơi có
    loại 1, 2, 3 trùng số, nhưng 1026 trong 3870 dòng của bảng thì không, nên khi vẽ đầu của mô
    hình khác phải xác định lại loại. (b) Dự án giữ đầu 3D theo quyết định của người dùng dù script
    2026 hiện ảnh 2D. (c) Ánh sáng đang chỉ là môi trường trắng. Báo cáo tháo mã của tác tử phụ
    (CHƯA tự kiểm) nói bản gốc thêm ActorLightOne (0,68; 0,68; 0,5) từ đèn đặt tại mắt trừ (2000,
    1000, 100) và mặt cắt xa 100000; mặt cắt xa của dự án đang là 2000. (d) Cỡ texture của bộ quản
    lý cũ (Render.dll 0x35E50 tạo đúng cỡ được giao) và nơi giao cỡ ở UI_CEGUI.dll chưa đọc; dự án
    dùng 128, không đổi bố cục vì tỉ lệ khung bằng rộng chia cao và ảnh phủ kín ô. (e) Nền
    `TLBB/UIModelBackground` chưa làm (tên nền của khung người chơi rỗng).
25. **(Đã đóng phần khởi tạo và vẽ 2026-10-17, `a0b31fa3`) D3D12 và D3D11.** Lỗi khởi tạo ghi
    2026-10-06 không còn: cả hai backend vẽ Đại Lý với lớp kiểm tra 0 lỗi, `gpu_tests` 47/47. Các
    gốc đã sửa: stride đỉnh chốt lúc `bind_vertex_buffer` nên lô hạt `yanjiangzhengqi` vẽ thành
    cột nhiễu trước mặt nhân vật; fxc đọc `float4x4` của buffer instanced theo hàng; chép mip BC
    2x2 và chép một phần trên D3D12. Còn mở một chỗ: D3D11 khi bật MSAA lệch khoảng 200 điểm ảnh
    (lớn nhất 21 mức) giữa hai lần chạy cùng bản, ở mép lá và chỗ hai mặt trùng độ sâu; tắt MSAA
    (samples = 1) thì trùng từng điểm ảnh, Vulkan và D3D12 luôn trùng. Đo: ba lần
    `--scene-id 2 --bare --backend d3d11 --frames 120`, so bằng `diff.py`. Chưa biết do trình điều
    khiển hay do mã; cần thử MSAA với một lượt vẽ duy nhất trong `gpu_tests` để tách. Mã máy gốc
    (`G:\XTLBB\Bin64\RenderSystem_Direct3D11.dll`, đọc 2026-10-17) không có MSAA trên D3D11:
    swapchain gọi `determineFSAASettings` với fsaa 0 cứng (`0x180021934`), render texture luôn
    `SampleDesc` 1/0, cả DLL không có `ResolveSubresource`. Đặt D3D11 về một mẫu là khớp gốc và hết
    lệch; chưa làm vì đổi chất lượng hình của backend, chờ chủ dự án chọn.
    Cũng ngày đó: `open` của D3D12 có `--validate` rơi xuống Microsoft Basic Render Driver (3/3 lần)
    khi luồng làm nóng driver của client còn giữ thiết bị dò lúc bật lớp kiểm tra. Đã sửa bằng khoá
    dò của backend (`d3d12/device.cpp`, `probe_mutex`); sau sửa 3/3 lần chọn RTX 5060.
26. **Nhịp khung của backend GL** (2026-10-06, `gpu/gles/swapchain.cpp`). Desktop xin Mailbox và tự
    giữ nhịp 120 Hz; commit e404d1e đổi GL sang chờ quét cho mọi chế độ khác Immediate, từ đó PC
    GLES (WGL, màn 60 Hz) nhảy 7/16/32 ms: 120 trong 449 khung quá 20 ms khi có lượt ảnh đầu, 34
    khi tắt. Đã trả về "chỉ Fifo chờ quét" (đo lại: 3 trong 897 khung quá 20 ms, trung vị 8,3 ms).
    Hai hướng đã thử và SAI: tạo fence trước SwapBuffers, bỏ chờ fence lúc xin ảnh. D3D12 vẫn chờ
    quét với Mailbox (không đụng, mục 25 chưa cho chạy). Chưa kiểm: GL toàn màn hình độc quyền
    không chờ quét có xé hình không (cửa sổ do DWM ghép thì không).
27. **Số "Vừa rồi" trên tablet dao động dù hình hiện đều** (2026-10-06, đo bằng `dumpsys
    SurfaceFlinger --latency`, 500 khung). Khoảng cách hai lần hiện: trung vị 16,70 ms, min 16,26,
    max 17,19, không khung nào lệch quá 2 ms. Khoảng cách hai lần app nộp khung: p95 20,66, min
    10,64, max 23,73 (236 khung lệch quá 2 ms): `eglSwapBuffers` không chặn tới đúng vblank nên
    vòng lặp của app không bám nhịp quét. Có từ trước lượt ảnh đầu (bảng số liệu lúc 18:37 đã ghi
    p95 18,7). Muốn số này đứng yên phải giữ nhịp theo Choreographer; chưa làm.
28. **Ánh sáng theo shader gốc: phần còn ngờ** (2026-10-06, `render/shade`, `client/display/
    lighting`). (a) Giờ trong ngày đang là 0,5 (`kOfflineDayTime`); nguồn giờ của SkySphere (máy chủ
    hay đồng hồ client) chưa tháo. (b) Chất liệu "lighting off" vẫn nhân màu đỉnh, chỉ bỏ specular:
    SUY từ shader 2026, chưa đặt cạnh ảnh client gốc. (c) Chất liệu LSScene/PBR (khoảng 10% số chất
    liệu) đang vẽ bằng công thức classic. (d) Màu đỉnh bị bỏ với chất liệu OGRE không khai tracking.
    (e) `Light::setCullingMask`, cảnh chỉ có một đèn directional và cảnh không khai Enviroment chưa
    có ca thử trên dữ liệu thật. (f) Ánh sáng riêng của ảnh đầu (listener Render.dll 0x19B50 đặt
    ambient và đèn nhân vật riêng) chưa port: ảnh đầu đang dùng ánh sáng của cảnh.
29. **Backend GL màu thô lệch Vulkan ở phần trong suốt** (2026-10-06, `gpu/gles/device.hpp`). GL
    trộn và lọc trên số đã mã hoá như D3D9 của game gốc, Vulkan để phần cứng trộn tuyến tính. Đo
    trên PC cùng vị trí: nền khung chat (ô đen mờ) Vulkan (100, 20, 0), GLES (45, 10, 0); trời lệch
    0. Hướng xử lý cho đồng nhất: đưa Vulkan và D3D về cùng cách (định dạng UNORM, bỏ phép đổi màu
    trong shader), tức là chốt mục 2 theo "không sRGB"; cần chủ dự án quyết. Chưa kiểm: so từng
    điểm ảnh phần cảnh 3D giữa hai backend (máy quay lệch vài điểm ảnh giữa hai lần chạy nên phép
    so bị nhiễu). Thấy mà chưa điều tra: PC GLES có viền răng cưa, Vulkan thì không.
30. **GLES tính ánh sáng ở đỉnh** (2026-10-06, `ForwardDesc::lights_at_vertices`). Khác gốc: địa
    hình và chất liệu PS-lit của gốc tính ở điểm ảnh. Lý do là số đo trên GE8320 (TIEN-DO, mục ánh
    sáng). Điều kiện bật là backend GLES, kể cả PC `--backend gles`; chưa có công tắc theo năng lực
    GPU nên máy GLES mạnh cũng chịu.
31. **Sổ assets Android và dữ liệu vào APK** (2026-10-06, `client/assets`, `package_apk.py`). (a)
    Tệp bị bỏ khỏi gói không bị xoá trên máy. (b) Guard "gói shader lệch đời với mã" mới có test đơn
    vị, chưa thử bằng gói lệch thật trên máy. (c) Một cảnh nêu tệp `.skysphere` không có ở `_raw`.
    (d) APK không có `Config/ScenePosDefineEx.txt` (trong `Config/` sổ chỉ có `startup.id` và
    `SceneDefineEx.txt`); chưa xem hệ quả với bảng cổng. (e) Depfile kê thư mục đã quét nên thêm
    tệp vào `music/` hay `sound/` làm APK đóng lại, nhưng chưa thử ca đó.
32. **Gợi ý cho mục 25 từ mã bgfx** (2026-10-06, do tác tử phụ đọc bgfx và mã dự án). Đã đóng
    2026-10-17: swapchain UNORM với sRGB ở view (có từ `fd4a1afe`) và D3D11 chỉ gọi `GetBuffer(0)`
    (có từ `8e13f0d4`) đã nằm trong mã; mục 25 nay chạy được. D3D12: `CreateSwapChainForHwnd` với flip model không nhận định dạng
    `B8G8R8A8_UNORM_SRGB` (0x887A0001); tạo chain UNORM và giữ sRGB ở view. D3D11: ảnh swapchain bị
    gắn `kSampled` nên tạo SRV trên back buffer hỏng; sửa xong sẽ lộ tiếp `GetBuffer(1)` và chỉ số
    back buffer của flip model; `SetMaximumFrameLatency(1)` hỏng khi chain không waitable. Ngoài ra
    bgfx kiểm magic, phiên bản và hash của shader lúc nạp, invalidate depth cuối lượt vẽ, nén
    texture ETC2/ASTC cho di động. Không có gì dùng được cho việc giữ nhịp theo Choreographer.
33. **Chữ Việt và vùng chữ của nút** (2026-10-08, `TOOLS/content/ui_text_fit.py`,
    `assets/i18n/vi.tsv`). Bộ đo so bề rộng chữ với cả ô của cửa sổ, còn client
    cắt chữ theo vùng chữ của look, hẹp hơn ô: thẻ kênh trò chuyện rộng 40 px vẽ trọn chữ 30 px
    ("Riêng") nhưng cắt hai mép chữ 35 px ("Chung", "Tuyển"; nhìn trên ảnh chụp), trong khi thẻ của
    bảng nhân vật rộng 35 px vẽ trọn chữ 33 px ("Luyện"). Nên "0 nút tràn" của bộ đo chưa bảo đảm
    không nút nào bị cắt; các nút của 24 layout đã gom thì đã nhìn trên ảnh. Muốn chắc: đo bằng
    chính `TextRun::box` mà `gui::Hub` trả ra (một ca test có dữ liệu thật), làm cùng lúc với phông
    co giãn. Ngoài ra bảy cửa sổ không phải nút còn chữ rộng hơn ô, đều là chỗ điền mẫu của layout
    (tên, cấp, `9999/9999`) hoặc chữ tĩnh của khung mô tả vật phẩm đang ẩn.
34. **Một khung dài 87–100 ms khi lần đầu mở bảng** (2026-10-08, đo bằng `click_shot.py`, bản
    `msvc-release`). Bảy lượt chạy có mở bảng đều có đúng một khung dài (86,9 tới 99,5 ms); lượt
    không mở bảng thì khung dài nhất 9,0 ms. Chưa biết bảng nào và bước nào (dàn trang, dựng bộ
    đệm, nạp texture lần đầu). Để lại theo quyết định viết mã trước, tối ưu sau.
35. **Ảnh con trỏ `Interface/cursor` không có công cụ nào sinh ra** (2026-10-08, lộ khi chạy
    `python TOOLS/content/verify_ui.py --raw <_raw> --data CLIENT/data`). `CLIENT/data/Interface/
    cursor` có `cursors.tsv`, `cursors.list.tsv` và 22 tệp `.ttex` (ngày tệp 2026-09-27) mà
    `SRC/client/viewer/cursors.cpp` đọc, nhưng không tệp nào trong `TOOLS/` tạo ra chúng và kho
    `_raw` không có nguồn cùng tên. Hệ quả: `verify_ui.py` đỏ ở mục 1 (24 tệp mồ côi; màn hình chỉ
    in 20 dòng đầu, đủ thì xem `--report`) và mục 5a (24 tệp thiếu trong `ui.files.tsv`); máy khác gom lại dữ liệu sẽ không có con trỏ game (client
    rơi về mũi tên hệ thống). Chưa lần ra nguồn của các tệp này nên chưa viết bước gom.
36. **Bảng nhân vật: phần chưa theo hết script 2026** (2026-10-08, `ui/panel/self_equip`,
    `hero/hero.hpp`). (a) [Đã giải 2026-10-15: 24 byte đầu là khối Rijndael 192 bit, `TOOLS/content/script_crypt.py`;
    không phải lúc nào cũng là chú thích (QuestLog: `local bBeingRadio = 0;`).] (b) `ScriptGlobal_Format` nằm trong `Game.exe`, chưa tháo:
    `format_key` chỉ làm phần nhìn thấy ở dữ liệu (`%s0`..`%s9`); chưa biết nó còn xử lý gì khác
    (số, khoá lồng). (c) Chưa port: nhánh máy chủ Khinh Hưởng (`Is2606S`) và máy chủ PK
    (`IsPKServer_JD`) của dãy thẻ và nút lên cấp; nộ riêng của môn phái 13 (`ENG`); tooltip; chấm
    đỏ nhắc việc (coi như không có gì để nhắc); kỹ năng đổi bảo thạch 278 (coi như chưa học); mức
    cường hoá bộ (để mức thấp nhất); hạng thí kiếm `Lua_GetXbwData_2018("LevelIndex")` (giấu, chưa
    biết giá trị của nhân vật mới). (d) `Hero::level_cap` 129 là số mặc định viết trong script;
    máy chủ thật trả số này qua `Lua_GetMyMaxLevelLimit`. (e) Mô hình 3D giữa bảng
    (`AttachWindowEx("Player")`) chưa vẽ. (f) Số của nhân vật mới tính từ cấu hình máy chủ bản
    0859602 (`DefaultChar.ini`, `BaseValueTable.ini`); chưa có nguồn nào cho biết máy chủ 2026
    còn dùng đúng các hệ số đó. (g) Phép nhân màu của `gui::modulate` giả định bản 2026 dựng với
    số thực IEEE như mã CEGUI 2008; lệch nếu có chỉ ở bit cuối của một kênh.
37. **Ca vòng kéo của cửa sổ thỉnh thoảng không có nhịp nào** (2026-10-08,
    `tests/window_modal_tests.cpp`, trước đó nằm trong `window_tests`). Sáu ca gửi lệnh kéo cho
    cửa sổ ẩn rồi đòi nhịp vẽ (bộ hẹn giờ 16 ms) chạy trong vòng kéo của Windows. Dấu hiệu hỏng:
    vòng kéo tự kết thúc trước nhịp đầu tiên (`ticks == 0`, không chạm watchdog), `core::check`
    của test dừng tiến trình nên mã thoát là 0xC0000409; có ở cả MSVC, không phải lỗi TLS của mục
    12. Tỉ lệ đã đo trên bản MSVC: bản của commit `2d73daf` (kéo bằng bàn phím, trên desktop
    của người dùng) 3 trên 420 lượt; sau khi đổi sang kéo bằng chuột và chạy trên window station
    không tương tác vẫn 1 trên 150 lượt, nên không phải chỉ do chuột, phím thật chen vào như tôi
    đoán lúc đầu. Một dấu vết thông điệp của lượt hỏng (bản kéo bằng bàn phím): `WM_ENTERSIZEMOVE`,
    8,8 ms sau là `WM_CAPTURECHANGED` với `lParam` 0, rồi các thông điệp kích hoạt và
    `WM_EXITSIZEMOVE` ở 12,5 ms. CHƯA biết ai lấy capture. Chưa bắt tiếp: phải chạy hàng trăm
    lượt mới gặp, mà mỗi lượt làm con trỏ của phiên nháy sáu lần (`AGENTS.md` mục 11); cần một
    lúc không ai dùng máy, hoặc một phiên đăng nhập khác. Hệ quả hiện tại: các ca này không nằm
    trong `ctest` thường ngày; chạy tay mà đỏ đúng dấu hiệu trên thì ghi lại rồi chạy lại một
    lượt, đỏ kiểu khác là lỗi thật.
38. **Camera và chuột theo mã máy 2026: phần còn ngờ** (2026-10-08, `control/follow_camera`,
    `control/player_input`, `docs/CAMERA-2026.md`). Mọi thứ là đọc tĩnh mã máy và tệp dữ liệu,
    chưa đối chiếu với một client 2026 đang chạy (client gốc cần máy chủ mới vào được cảnh).
    (a) Giao diện nhận sự kiện nào trước màn chơi: bản gốc để `UI_CEGUI.dll` nhận trước, chưa
    đọc dll đó. Dự án coi nhấn, nhả, bấm, giữ trái, nhấn và bấm phải, nhấn và bấm giữa trên HUD
    là của giao diện (`kUiEvents`), còn lăn chuột trên HUD vẫn zoom: đoán. (b) Bấm trái khi tia
    không trúng mặt đất: bản gốc vẫn kích hoạt lệnh chuột với điểm chưa đọc ra; dự án không ra
    lệnh đi. (c) Hàm ảo `+0x288` của nhân vật trả khác 0 thì bản gốc bỏ kẹp pitch; cùng hàm đó ở
    0x1406199b0 chọn kiểu đi thẳng bỏ qua vật cản (đọc ngày 2026-10-08), tức trạng thái bay hay
    đi tự do; dự án chưa có trạng thái đó nên luôn kẹp. (d) Lần `Update` đầu tiên bản gốc lấy bán kính quả cầu mắt
    từ mặt gần mà `Ogre::Camera` đang có (5 lúc dựng) rồi mới đặt mặt gần của cảnh; dự án dùng
    mặt gần của cảnh ngay. Chỉ khác ở một lần tính. (e) Hộp ô của camera chưa cộng độ cao mặt
    đi của công trình (cầu, sàn nhà): chưa có WalkMap, nên ở chỗ công trình cao hơn đất mắt của
    dự án có thể chui vào công trình mà bản gốc thì tránh. (f) Bản gốc trần 45 khung mỗi giây
    (`System_MaxFPS_Front`) và zoom mượt 0,01 mỗi nhịp; dự án nhân theo thời gian với 45 nhịp
    mỗi giây. Chưa tháo đoạn đọc trần khung nên chưa biết còn chế độ khung cao nào. (g) 59 cảnh
    có dòng riêng trong `SpecialSceneCamera` (loại 1 và 2: giới hạn pitch, khoảng zoom, góc
    nhìn, hướng và pitch đầu, chữa mắt vướng bằng khoảng cách) chưa nối: mọi cảnh dùng luật
    cảnh thường. `CameraFit::kDistance` có mã và test nhưng chưa có ai gọi. (h) Chưa port: rung
    camera của kỹ năng, khoá hướng, phim cắt cảnh, nới sương khi zoom xa hơn 16,5 (`Render.dll`
    0x180032510, chưa đọc hết). (i) Phím mặc định của hai lệnh zoom 0x2d, 0x2e chưa biết; cửa
    sổ của dự án gán mũi tên lên, xuống. (j) Android đi chung logic chuột mới (ngón kéo nhanh
    thành kéo phải, chụm thành lăn), vào cảnh ở zoom xa nhất như PC thay cho 0,45 trước đây:
    thư viện và test dựng được cho arm64, CHƯA đóng APK và chưa thử trên máy tính bảng (máy
    đang cắm báo `unauthorized` với adb).

39. **Đường đi và vật cản theo `PathLib.dll` 2026: phần còn ngờ** (2026-10-08, `SRC/nav`,
    `docs/DUONG-DI-2026.md`). (a) Thứ tự gỡ hoà của A* (hai phép so `>=` trong đống nhị phân và khi
    sửa chi phí của tam giác đã gặp) đọc từ mã máy nhưng chưa có ca thử: cần một lưới đối xứng tuyệt
    đối để hai tam giác có cùng điểm số. (b) Điểm rẽ ở đỉnh mà ô chứa nó liệt kê chưa đủ hai cạnh
    ràng buộc của nó: bản gốc dùng lại trạng thái của điểm rẽ trước, và ở điểm rẽ đầu tiên thì đọc
    ngăn xếp chưa khởi tạo; dự án không dời điểm rẽ đầu tiên như vậy. Dữ liệu thật có 15.841 đỉnh mà
    ô của nó liệt kê dưới hai cạnh; chưa đo bao nhiêu đường đi thật chạm ca này (400 đường của
    `huoyangu` không lệch dòng nào). (c) Thuật toán dự phòng 0x18002cd60 khi góc không né được ở bán
    kính nào: chưa port, chưa biết tần suất. (d) Kéo căng đường là thuật toán phễu chuẩn, không phải
    bản hai chuỗi của gốc: bản C++ mới so trên 802 đường của hai lưới, chưa chạy đủ 419 cảnh. (e)
    Cảnh không có tệp `.path` (kho có 419 tệp cho 512 tệp `.Scene`): dự án cho đi tự do; bản gốc
    theo mã thì không ra được lệnh đi; chưa thử trên client gốc. (f) Hai tệp bản 0x1000
    (`luoyang_MD`, `wending`): bản gốc đọc cỡ ô sai nên chỉ thấy vật cản của ô đầu; dự án giữ đúng
    lỗi đó. (g) Phím đi và cần gạt không có ở bản gốc: luật `step_reach` (dừng trước vật cản, không
    trượt dọc tường) là của dự án. (h) arm64: `-ffp-contract=off` đã đặt, nhưng test số vàng không
    chạy trên thiết bị nên khớp từng bit chưa kiểm. (i) Lệnh đi bị từ chối khi đang đứng sát vật cản: buổi thử tay của chủ dự án ngày
    2026-10-08 có 32 lần nhấp chuột, 14 lần không ra lệnh, cả 14 đều là đang đứng ở chỗ dừng sát
    vách (ba chỗ: 69,07 17,76; 67,87 24,68; 67,34 15,71) rồi nhấp tiếp vào vách: chỗ dừng mới cách
    chỗ đứng dưới căn 2 nên `GetPathDirect` từ chối. Đúng theo mã máy, nhưng chưa thấy trên client
    gốc đang chạy; người chơi sẽ thấy "nhấp mà không đi". (j)
    `TOOLS/run/click_shot.py`: cửa sổ client ngoài màn hình vẫn nằm trong danh sách Alt+Tab và
    thành cửa sổ ở trước khi người dùng Alt+Tab (đo bằng `desk_watch.py`: 22 lần đổi cửa sổ ở
    trước trong 21 giây, 5 lần rơi vào client); cần đặt `WS_EX_TOOLWINDOW` và `WS_EX_NOACTIVATE`
    cho cửa sổ trước khi hiện.

40. **Màn đăng nhập: phần chưa theo hết bản gốc** (2026-10-08, `ui/panel/logon`,
    `control/login_view.hpp`, `client/viewer`, `client/display`; phần đã đo ghi ở TIEN-DO mục
    "Thủ tục đăng nhập" và `docs/CAMERA-2026.md` mục "Màn đăng nhập"). (a) Cảnh nền mới sống một
    phần. Thư viện hiệu ứng giờ gom từ nguồn bản 2026 (`TOOLS/content/collect_fx.py`; thư viện nấu
    từ client cũ và `SRC/fx/ttex` đã bỏ). Đo trên `erengu_DL` bằng dòng "Hiệu ứng:" của log
    (2026-10-08, `msvc-release`): 88 chỗ đặt thành 86 hệ hạt đang vẽ (lửa cam, lửa xanh ở tượng,
    quầng đèn, 1073 quad mỗi khung), 77 hệ bị bỏ có đếm lý do: 57 hệ có material không cộng sáng
    (`src_alpha one_minus_src_alpha`: trọn mặt nước `cj_程式瀑布_水面`, sương `cj_恶人谷_方向雾*`,
    khói), 15 hệ hạt mesh cần material hạt (trong đó sương xa `cj_恶人谷_远景雾片`), 5 hệ dùng
    affector chưa có (`SequenceFrame` 4, là ngọn nến `cj_恶人谷_烛火`; `DirectionRandomiser` 1).
    Chưa làm trong `SRC/fx`: pipeline trộn alpha, hạt mesh, hai affector trên, xoay hạt của
    `Rotator`, emitter `Ring` và `HollowEllipsoid` (đang mô phỏng như hộp), `use_scale`, effect con
    `use_particle_effect`. Đọc mã 2026-10-08 thêm: `Cylinder` và `Ellipsoid` cũng sinh điểm như
    hộp (mọi emitter không phải Point và Polar đi `area_point`, `SRC/fx/field.cpp`); xoay hạt bị bỏ
    ở `SRC/fx/billboard.cpp` (`static_cast<void>(grain.rotation)`) trong khi `Rotator` có trong
    884 khối của `all.particle`; `duration_min`, `duration_max` đọc mà không dùng, `repeat_delay_*`
    không đọc, nên emitter không bao giờ tắt hay lặp; `colour_range_end` và `sorted` đọc mà không
    dùng; `billboard_origin`, `force_application`, `accurate_facing` không đọc; affector
    `PolarMove`, `Dissolve` và element `PointLight` có trong dữ liệu mà không có mã. Những chỗ
    này hệ vẫn vẽ nhưng vẽ thiếu, và dòng "Hiệu ứng:" của log không đếm chúng. Với `src_alpha one` và hệ số nhân lớn hơn 1, màu bị kẹp trước khi nhân
    alpha; chưa xét cộng trong sRGB hay tuyến tính. Ảnh của hạt giải mã ngay trên luồng vẽ lúc dùng
    lần đầu (18 ảnh, 60,9 ms, gây một khung 51 ms lúc cảnh đang nạp). 12 vật thể kiểu `Model` (quạ
    đứng, quạ bay) không vào `Stage`. Sáu mặt `TerrainLiquid` không được vẽ. `package_apk.py` chưa
    đóng `effect/` vào APK (đọc `effect/fx.files.tsv` là đủ danh sách). (b) Môi trường của cảnh nền: các lời gọi còn lại của `CRenderSystem` ô `+0x260`
    (tầm nhìn 65000, hai đối tượng đơn được bật kèm số 18000 và 1000, tắt hậu kỳ `Floodlighting`)
    và byte `+0x13a` chưa đọc hết, chưa làm. (c) Mặt gần của camera lấy 5 theo suy luận (lần
    `Update` lúc khởi tạo); chưa kiểm bằng chạy thật. (d) Cửa sổ đăng nhập nằm giữa màn hình; bản
    gốc đặt giữa vùng làm việc (lệch 24 điểm ảnh theo chiều dọc trên máy dựng, do thanh tác vụ).
    (e) "Vào Game" không kiểm tài khoản: bản gốc gọi `GameProduceLogin:CheckAccount` rồi qua chọn
    máy chủ. Dự án bỏ chọn máy chủ (chưa port) và mở SelectRole rồi CreateRole trên sổ cục bộ
    `CLIENT/data/Save/roles.tsv`: tối đa 3 nhân vật một tài khoản, nhân vật mới là cấp 1 môn 9
    (Vô Phái), vào game dùng đúng tên, giới, mặt, tóc và chân dung đã chọn. Cửa sổ
    `CreateRole_Model` vẽ người toàn thân (fake object `CreateRole_Woman` / `CreateRole_Man`,
    FOV dọc 20 độ, mắt lùi vừa chiều cao BoundingBox). Giữ nút xoay thì quay ±1 vòng mỗi giây
    (Game.exe 0x1406416f1). Bảng chọn nạp `tl3chuangjian.Scene` (Game.exe 0x14063cc7a),
    đặt chân đúng số 0x14063d97a và nhìn bằng tư thế nghỉ của track Role0To1 / Role1To2 /
    Role2To0 (Render.dll 0x180001dc0, FOV 65). Bảng tạo nhìn khoá cuối của CameraTrack;
    người tạo vẫn ở `CreateRole_Model`. Khác gốc còn lại: chưa tua đoạn chạy giữa các ô
    (vào ô là tư thế nghỉ ngay); zoom chưa đẩy camera; `ShowModel` môn phái chưa
    có mô hình riêng; không hộp YesNo (xoá hỏi trên dòng trạng thái,
    nhấn Xoá lần nữa); không danh sách tên cấm; ô trống mở tạo bằng một lần nhấn
    (gốc là nhấn đúp); chữ do bảng đặt là tiếng Việt, ảnh nút vẫn là ảnh 2026 còn chữ Hán. Bảng tạo
    từ 2026-10-09 là bản dịch của `CreateRole.lua` đối chiếu số vàng (ảnh chân dung, tóc, mặt, bộ
    đồ tân thủ đúng phân bố bản gốc); phần khác gốc còn lại của nó kê ở mục 7 của
    `docs/TAO-NHAN-VAT-2026.md`. Chưa kết luận được: (1) Enter trong ô tên có tạo nhân vật ở bản
    gốc không (layout không nối `TextAccepted`; cần tháo hàm xử lý phím của `CGamePro_CharCreate`,
    vtable `0x140c2bea8`); (2) hai chuỗi "chuangjiannan" và "default" của `ChangeNewRoleEquipSet`
    đi tới đối tượng `#FairySkySphere` qua `Render.dll` `0x1800f3440`, hàm này làm gì với vòm trời
    thì chưa tháo (dự án chưa vẽ vòm trời); (3) `math.random` của client gốc gieo từ hạt nào (bản
    này dùng xorshift trộn đồng hồ khung); (4) người mẫu nam của màn tạo làm gì khi tới lượt nghỉ
    `空手休闲` mà mẫu `男新手套装N.obj` không nối skeleton chứa nó (`_changeAnimation`, `Render.dll`
    `0x18006b510`, trả sai và để tên hoạt ảnh rỗng; phần logic nhân vật phía sau chưa tháo); (5)
    nam ngẩng cằm 12 đến 15 độ ở clip đứng là dữ liệu của bản thường, chủ dự án vẫn thấy khác bản
    gốc: cần ảnh chụp màn tạo của bản gốc; (6) lần đầu vào bảng chọn camera gốc chạy thế nào
    (`0x14063b7a0` cho chạy ngược `Role0To1` khi chưa có ô nào; bản này đứng sẵn ở ô đang chọn). Cỡ cửa
    sổ giữ 1280 x 720 sau khi vào game kể cả khi có `--size`. Chưa có máy chủ (phần 3, 4, 6). (f) "Quay Lại" đóng client; bản gốc về màn chọn
    máy chủ (chưa port, và nó là màn ĐẦU của luồng gốc). (g) "Giúp" mở trang web; bản gốc mở bảng
    `Helper`. Bốn nút web mở cùng một trang "Coming soon"; `GetWeblink` và `StartAccountReg` của
    `Game.exe` chưa tháo. `io::open_in_browser` chỉ có trên Windows. (h) Bàn phím ảo đã port
    từ mã máy của `CEGUIFalagard.dll` (2026-10-08, `gui/softkey`, `ui/panel/softkey`); chỗ chưa
    theo bản gốc: phím ăn ngay lúc nhấn (gốc: lúc nhả trên chính phím đó) và ảnh nhấn hiện khi
    chuột đang nhấn trên phím; số ngẫu nhiên của lần xoay vòng phím là xorshift32 thay `rand()`;
    cửa sổ chưa kéo được bằng thanh `TLBB_DragTitle`; nút trợ giúp chưa làm gì; ảnh tiêu đề
    `MainFrameLuo01/Softkeyboard` (52 x 18) còn chữ Hán, chưa có ảnh thay; chưa kiểm bản gốc vẽ
    ký tự `#` của mặt phím thế nào (ở đây chữ của phím là nguyên văn); trong `resetAllPosition`
    đã khớp số vòng lặp (10, 13, 10, 9, 7), bộ hằng cột của 19 phím dấu lẻ và ba vector của phím
    lớn với mã 2008, nhưng chưa lần từng cặp cột, hàng của 19 phím lẻ ấy; phím Return bắn sự kiện
    `ReturnPush` mà không tệp nào trong `Bin64` ngoài chính DLL có chuỗi đó, nên ở đây Return
    không làm gì; hai widget họ hàng `Falagard/SFZSoftKeyWindow`, `PhoneSoftKeyWindow` chưa port.
    (i) Ô nhập: chỉ ASCII in được, chưa IME, chọn vùng, dán, cuộn ngang (tên
    dài hơn ô 100 điểm ảnh bị cắt, con nháy ra ngoài); cách đặt dòng chữ và con nháy theo mã 2008,
    chưa tháo `UI_CEGUI.dll` bản 2026. Nhấn nút ăn ngay lúc nhấn; `Clicked` của CEGUI bắn lúc nhả.
    (j) Ô chọn đuôi tài khoản `LogOn_Region` (`Falagard/Combobox`): `gui` chưa dựng cửa sổ con của
    look cho Combobox nên ô không hiện (từ 2026-10-08 `kChildHosts` trong `SRC/gui/loader.cpp` đã
    dựng con cho Listbox, ListBoxEx, ComplexWindow, StaticText và Scrollbar; Combobox, ChatHistory
    và Star thì chưa). (k) Chữ trên ba thẻ theo ảnh chủ dự án đưa: thẻ mã QR mang chữ "Đăng
    Ký" trong khi nhấn nó là về kiểu tài khoản truyền thống. (l) Nền của nút gốc dựng lại bằng
    trung vị của các cột không có nét chữ; ba thẻ dùng chung nền của thẻ mã QR, chưa so từng điểm
    ảnh với nền của hai thẻ kia ở vùng bị nét chữ che. (m) Giữ cả `Model` gốc trong RAM sau khi tải
    lên GPU (ảnh RGBA đã giải mã): đỉnh bộ nhớ của màn đăng nhập 1,9 tới 2,2 GiB.

41. **Module `collision` gộp từ việc dở của đợt DH 1** (2026-10-08, `SRC/collision`, `tests/collision_*`;
    hồ sơ ở `docs/giao-viec/DH-DOT-1/`). (a) Sáu tệp không qua `check.py` (đo bằng `python
    ~/.claude/cpp23/tools/check.py -j 2 <22 tệp>`, 18 bước không đạt): `SRC/collision/mesh.cpp` (độ
    lồng, 12 chẩn đoán clang-tidy), `opcode_tree.cpp` (định dạng, độ lồng, 4 câu lệnh trải nhiều
    dòng, 15 chẩn đoán), `opcode_tree.hpp` và `transform.hpp` (định dạng, chữ ký và khối khởi tạo
    bị bẻ), `tests/collision_model_tests.cpp` và `tests/collision_sha256.hpp` (định dạng, độ lồng,
    hình dạng, mỗi tệp 15 chẩn đoán). Tổng 57 chẩn đoán clang-tidy; 16 tệp còn lại sạch. Chưa
    sửa: mã là bản port đòi trùng từng bit, sửa hình dạng phải đi kèm lượt so số vàng
    (`collision_model_tests` trên tệp thật). (b) Chưa có API truy vấn (`load`, `height`,
    `raycast`); `collision_tests` và `collision_alloc_tests` vì thế trả 77. (c) Các tiêu chí T2 tới
    T5, T7, T8, G1 tới G12, H1 tới H6 của đề bài chưa được ai đo; số đo tốc độ phía DLL gốc đã có
    ở `KET-QUA.md`, phía bản port chưa có. (d) Chưa đọc trọn mã của phiên phụ; mới kiểm bằng dựng
    ba preset, chạy test, lint và `check.py`.

42. **Nút còn không nối vì chưa đo được đích** (2026-10-08, `ui/panel/desk`). (a) `Button_Exchange`
    khi không nháy gọi `PrepearExchange`, hàm C++ không có trong mã 2008 và chưa tháo trong
    `Game.exe`; có lời mời thì `Exchange:OpenExchangeFrame` chỉ mở khi người đó còn trong tầm.
    Không mở khung giao dịch trống. (b) `Operation_2Menu` gọi `ReturnServerLogin`; từ màn chơi
    chưa có thủ tục về màn đăng nhập, không gán thành thoát game. (c) Thẻ tự động cần
    `BattleAssist:Farm_GetLimitLevel` và thẻ tông môn cần `Lua_CheckOpenTalent`; cả hai chưa đo,
    nhân vật vô phái không mở hai trang và không bịa câu `#{ZDZD_200724_62}`. (d) `WEB_TLLUNTAN`
    không có trong cây; Diễn Đàn mở `coming_soon.html` như các nút web của bảng đăng nhập.
    Đã đo ở `docs/NHIEM-VU-VO-CONG-2026.md` (phần II, mục C.5): `Farm_GetLimitLevel` trả 30 khi
    `Is2606S`, không thì 50; `Lua_CheckOpenTalent` dưới cấp 60 báo `ZMTF_230628_21`, vô phái báo
    `ZMTF_230628_165`. `desk.cpp` chưa dùng hai số đó.
    (e) `YuanbaoShop_XuanShop` đẩy `OPEN_IMDRESS_YUANBAOSHOP` và `YuanbaoShop_Lijin` gọi
    `YuanbaoShop_Lijin_Show`; hai khung đó chưa gom, bấm chỉ đổi thẻ đang chọn. (f) `InfoList`:
    lời nhắc của nút nay đi qua `ui/panel/debug_list_box` (sự kiện NEW_DEBUGMESSAGE; tuổi thọ 5 giây, rồi mờ
    FadeSpeed/255 mỗi giây, bỏ khi độ trong âm, tối đa 5 mục — đọc từ `FalagardInfoList::updateSelf` 0x18006bd60).
    Phần vẽ vẫn là một khối chữ như SimpleText (mỗi mục một dòng, đủ độ đục tới lúc bị bỏ), vì `gui` chưa vẽ
    ListboxTextItem của InfoList; còn thiếu độ trong từng dòng. `--shot` chụp ở khung thứ 30 trở đi nên chưa nhìn
    được lúc dòng hết hạn; phần đó chỉ có test (`ui_debug_list_box_tests`).

43. **Sổ nhiệm vụ, sách võ và widget cuộn: phần đã port chưa nối vào màn chơi** (2026-10-08,
    `SRC/quest`, `SRC/skill`, `SRC/ui/panel/quest_log.*`, `SRC/ui/panel/widgets.*`,
    `SRC/gui/widgets.cpp`; đặc tả ở `docs/NHIEM-VU-VO-CONG-2026.md` và `docs/GIAO-DIEN-2026.md`).
    (a) Chưa nối HUD: `ui::Hud` chưa gọi `toggle_quest_log`, `press_quest_log`, `pick_quest_item`,
    `paint_quest_log`; nút nhiệm vụ vẫn mở khung trống qua `desk.cpp`. `Widgets::paint` chưa chép
    mục danh sách, phần tử cửa sổ phức hợp và vị trí cuộn sang Deck (`gui/content.hpp` đã định dạng
    các thuộc tính `Items`, `Elements`, `ScrollPosition`), nên bộ vẽ danh sách và cửa sổ phức hợp
    của `gui` mới chạy trong `gui_widgets_tests`. Bánh xe chuột chưa tới `HudView`; kéo con chạy,
    bấm rãnh và hai nút của thanh cuộn chưa có đường từ HUD. Hai chỗ nối còn thiếu thấy khi đọc mã
    (2026-10-08): `SRC/ui/hud.cpp` không gán `Place::meter`, mà thiếu nó thì danh sách và cửa sổ
    phức hợp không có mục nào (`SRC/gui/widgets.cpp` dòng đầu; chỗ gán duy nhất nằm trong
    `tests/gui_widgets_tests.cpp`); và `SRC/ui/panel/widgets.cpp` không include `gui/content.hpp`,
    tức phía dựng chưa dùng các hằng mà phía vẽ đọc.
    (b) Bảng nhiệm vụ mới là phần P0: thẻ nhận được (lọc theo `MissionOutline`), gập mở loại, mô tả
    ba dòng, hai ô theo dõi, các nút. Nhiệm vụ đang giữ (danh sách, mục tiêu, phần thưởng, bật tắt
    theo dõi, từ bỏ; dòng 533 tới 1470 của `QuestLog.lua`) và các bộ dựng chữ theo sự kiện (dòng
    1709 tới 3939) chưa port; `MissionTrack.lua` chưa đọc. 39 token `MisDesc` và văn bản mục tiêu
    đã có đặc tả và mô hình Python (`TOOLS/port/quest`), chưa có công cụ xuất bảng và mã C++.
    Trọng tài chưa mô phỏng nhóm chọn một của nút đánh dấu `CheckMode=1` và cuộn theo điểm ảnh của
    listbox (`FirstItem` còn là số nguyên do kịch bản giữ).
    (c) Sách võ mới có công cụ xuất bảng và module `skill` (bảng, sách, action); bốn trang
    (`CommonSkill`, `ActionSkill`, `LifeSkill`, `ZhenfaSkill`), số vàng, test giao diện và bản dịch
    chưa có; `skill_api.lua` của trọng tài mới có phần lõi. Chưa chắc: id action sau
    `CActionSystem::Initial` (trận pháp 1017 tới 1020, action đầu của sách 1021) tính từ số dòng
    năm bảng, giả định không action nào tạo trước `Initial`; thứ tự máy chủ gửi kỹ năng cho nhân
    vật mới lấy theo `DefaultChar.ini`; thứ tự script nhận sự kiện lấy theo dòng `InterfaceEx`
    (quyết định `SkillUnionPos`), chưa đọc từ mã máy; nhánh -8888 của `GetOwnerXinfa` chưa port;
    một tâm pháp có thể có hơn năm kỹ năng (46 có 9) trong khi `ActionSkill.lua` chỉ có năm ô;
    `ScriptGlobal_Format` thật đóng gói đối số vào `#{KHOÁ*…}` cho bộ phân tích chữ điền `%s0` tới
    `%sf`, `SRC/ui/panel/wording.cpp` hiện để trống khi thiếu đối số và không nhận `%sa` tới `%sf`;
    texture icon kỹ năng chưa gom (`CLIENT/data/Interface/Icons` có 9 tệp) nên ô action có tên ảnh
    mà chưa có ảnh; chưa đo thời gian nạp `skill_levels.tsv` (13 MB).
    (d) Widget của `gui`: ô tiền (`Falagard/Money`) mới giữ chỗ trong cửa sổ phức hợp, chưa vẽ; nút
    action chưa có chữ góc, hoạt ảnh hồi chiêu và nháy; nút lên xuống của thanh cuộn chưa nháy
    (`BtnAnimation`); `Falagard/StaticText` (ô mô tả của ba trang sách võ) và `Falagard/ListBoxEx`
    (MissionTrack) chưa có bộ vẽ; con tự dựng của look mới dựng cho listbox, cửa sổ phức hợp,
    StaticText và thanh cuộn (Combobox, ChatHistory, Star chưa). Đặc tả là đọc mã máy tĩnh, chưa
    chụp client thật để so từng điểm ảnh; cách cộng phần lẻ của toạ độ cửa sổ ra màn hình và việc
    giữ nút cuộn có lặp hay không còn là suy luận (`docs/GIAO-DIEN-2026.md` mục 12).

44. **Máy chủ sau P2 đợt 3 phần đầu: nợ và chỗ ngờ của `gate`, `secure` và test của chúng**
    (2026-10-08, `SRC/gate`, `SRC/secure`, `tests/service_tests.cpp`, `tests/server_boot_tests.cpp`,
    `tests/gate_loop_tests.cpp`, `TOOLS/server/gate_load.cpp`; số đo ở mục "Máy chủ: P2 đợt 3, phần
    đầu" của `docs/TIEN-DO.md`).
    (a) Tick của gate vỡ ở kịch bản mặc định của công cụ đo (10.000 khách tốt, 2.000 thù địch): p99
    121,4 ms so với hạn 16,7 ms, 1.088 tick trễ, chỉ 3.908 bắt tay xong trong 20 giây; ở 2.000 và
    400 thì p99 12,4 ms, không tick trễ. Chưa đo tách nguyên nhân. Hai nghi phạm đọc từ mã: không
    có ngân sách bắt tay trong một tick (mỗi lời chào 42 byte buộc gate sinh khoá X25519, ký
    Ed25519 và suy khoá, trong khi `kReadBudget` cho 512 lượt đọc mỗi tick — ngân sách này đã bỏ
    ngày 2026-10-12, xem mục 47), và `WSAPoll` quét cả
    mảng 12.000 socket mỗi lượt chờ. Cần số đo từng pha theo số kết nối trước khi sửa.
    (b) ĐÃ SỬA MỘT PHẦN 2026-10-09 (gói P2-2). Bộ đếm lý do ngắt từng không ra khỏi tiến trình: chỉ
    có `Table::drops` trong bộ nhớ và dòng log bị giới hạn năm dòng mỗi giây, và ba lý do từ chối
    lúc nhận không được đếm. Nay mọi lý do là bộ đếm `gate.drop.*` của module `metrics`, đọc qua
    cổng `metrics` (`gate_loop_tests`: 100 rồi 600 khách xả tin ra đúng 100 rồi 600). Còn lại:
    `thienlong_gate_load` vẫn đếm bằng cách đọc log, nên các số `drop_*` nó in vẫn là số dòng log;
    hết khi công cụ đó đọc cổng metrics (gói P2-5).
    (b2) ĐÃ SỬA 2026-10-09. Hạn tick của gate trôi: mỗi vòng cộng một nhịp vào hạn kể cả khi thức
    sớm vì I/O, nên sau một đợt I/O dồn dập gate ngủ hàng chục giây, không chạy hạn nào và không
    thấy yêu cầu dừng (mục "Máy chủ: P2-2" của `docs/TIEN-DO.md`). Hệ quả còn mở: số nền ở (a) đo
    trước khi sửa, và mỗi vòng thức sớm vẫn quét trọn bảng trong `Table::advance`; chưa đo phần
    này chiếm bao nhiêu của p99 121 ms. Cần: đo lại ba mức kết nối của P2-3 trên bản đã sửa.
    (c) ĐÃ SỬA 2026-10-09 (gói P2-1). Test từng nghe cổng thật: `service_tests` và `server_boot`
    chạy cụm với `SERVER/config` (gate nghe mọi địa chỉ ở hai cổng cố định), `gate_loop_tests` và
    công cụ đo tải dùng bốn cổng cố định khác; hai lượt `ctest` cùng lúc là tranh cổng và đỏ giả,
    mỗi cây dựng mới còn làm Windows thêm rule tường lửa (12 rule cho 6 đường dẫn
    `thienlong_gate.exe`, 4 đường dẫn thuộc worktree đã xoá). Sửa hai bước. Bước một (`a8cf96b`):
    bốn thứ ấy chạy gate trên `127.0.0.1` bằng bản chép cấu hình và khoá tạm trong cây dựng, cổng
    do test xin trước rồi ghi vào bản chép; còn một khe hẹp giữa lúc trả cổng và lúc gate nghe. Bước
    hai (P2-1) bỏ hẳn khe đó: cấu hình nhận cổng 0 cho bên nghe trên `127.0.0.1`, gate tự nghe
    cổng 0 và báo cổng thật ở dòng `ready`, giám sát báo lại ở dòng `ready` của cụm; `stage_config`
    đổi cổng của mọi `[[process]]` thành 0; hai hàm xin cổng trước đã xoá. Ba phần chạy PostgreSQL
    của `boot_check.py` nay dựng một cụm PostgreSQL tạm trong cây dựng, chỉ nghe `127.0.0.1`.
    Còn một chỗ xin cổng trước, biết mà chấp nhận: cụm PostgreSQL tạm ấy, vì PostgreSQL không nhận
    cổng 0; mất cổng thì `pg_ctl start` hỏng và phần đó báo HỎNG, không sai lặng lẽ.
    (d) `Welcome.heartbeat` ghi cứng 1 giây ở `SRC/gate/table.cpp`; hạn im lặng lấy từ
    `idle_timeout_ms`. Bản Dev (nguồn port) lấy nhịp tim từ cấu hình (mặc định 30 giây), ngắt khi
    im quá đúng nhịp đó, và client gửi `Ping` theo một phần của nhịp. Chỗ lệch này chưa ghi `Khác
    gốc:`, chưa có khoá cấu hình cho nhịp tim và chưa có phép kiểm nhịp tim nhỏ hơn hạn im lặng.
    (e) `Welcome.server_time` và `Pong.server_time` là đồng hồ đơn điệu của tiến trình gate tính
    từ lúc nó khởi động. Bản Dev gửi giờ thật (`wall_time()`, mili giây từ Unix epoch;
    `G:\TLBB\Dev\src\server\server.cpp` và mục "Mã tin" của `G:\TLBB\Dev\docs\PROTOCOL.md`). Chỗ
    lệch này cũng chưa ghi `Khác gốc:`; chưa nơi nào chốt gốc thời gian chung giữa gate, world và
    zone.
    (f) `listen.game` và `listen.auth` hiện xử lý y như nhau; tin của nhóm xác thực (`SignIn`,
    `CreateAccount`) tới cổng nào cũng bị ngắt như tin lạ. Tách bảng tin theo cổng là việc của P3.
    (g) Bản POSIX của `process` và `net` chưa dựng, chưa chạy lần nào; `gate_load.cpp` gọi thẳng
    Winsock và `psapi` nên chỉ có bản Windows, trái quyết định "mọi chỗ phụ thuộc hệ điều hành có
    đủ hai bản" của `docs/KE-HOACH-SERVER.md` mục 1. Công cụ ấy còn bỏ qua đối số lạ: gõ `--help`
    là chạy luôn kịch bản mặc định 20 giây (đo 2026-10-08), trái giao kèo "đối số lạ thì in cách
    dùng, thoát 2" của mục 3.1 cùng tệp.
    (h) Cây dựng dùng chung `build/clang-asan` và `build/msvc-release` chưa dựng lại trọn vẹn trên
    `main` từ khi gộp `gate-front`, `quest-skill` và phần chọn, tạo nhân vật. Số đo của hai trình
    dịch ấy lấy ở hai cây riêng (mục "Khảo sát theo mã" của `docs/TIEN-DO.md`): mọi target test,
    `header_check` và `game_client_display` dựng 0 cảnh báo, `ctest` 75 qua ở mỗi cây. Chưa đo ở
    hai preset ấy: `service_tests`, `server_boot`, `audio_tests`, và exe `thienlong_client`.

45. **Lỗ hổng của hạ tầng và của cổng dựng, thấy khi đối chiếu mã với tài liệu** (2026-10-08;
    mỗi điểm đã kiểm lại bằng grep hoặc đếm, chưa điểm nào được sửa trong mã).
    (a) Máy chủ chưa dựng được trên Linux thật dù bản POSIX qua kiểm cú pháp NDK:
    `SRC/core/system_posix.cpp` include `<sys/system_properties.h>` cho mọi nền không phải Apple và
    gọi `__system_property_get`; header ấy chỉ Bionic của Android có, mà mọi module máy chủ link
    `game_core`. Chưa sửa vì máy không có glibc để dựng thử; cần một distro WSL hoặc một máy Linux.
    Trên Linux còn phải có sẵn `toml++/toml.hpp` trong đường tìm của hệ thống: preset `gcc-asan`,
    `clang-tsan` không kế thừa `vcpkg`, thiếu thì CMake bỏ mọi target máy chủ.
    (b) `core` không có `Tick`, `TickSpan`, `StrongId`: `SRC/core` thiếu `time.hpp`,
    `strong_id.hpp`, `narrow.hpp` mà mục 7 của `AGENTS.md` và mẫu cpp23 nêu
    (`~/.claude/cpp23/templates/project/src/core`). `core::narrow` của dự án là hàm đổi UTF-16 sang
    UTF-8 (`core/text.hpp`), trùng tên với phép thu hẹp số của mẫu. Mô phỏng theo tick của máy chủ
    cần các kiểu này: thêm cùng module đầu tiên dùng tới, và đặt tên phép thu hẹp số sao cho không
    đụng `core::narrow`.
    (c) ĐÃ SỬA 2026-10-08 phần đăng ký: `tests/fs_tests.cpp` (718 dòng), `tests/math_tests.cpp`
    (530), `tests/shader_tests.cpp` (985) có tệp mà CMake chưa từng dựng (`git log -G` trên
    `CMakeLists.txt`); nay đăng ký cho Windows. Đo ở cây riêng: Clang 23 ASan và UBSan cùng MSVC
    bản phát hành dựng cả ba 0 cảnh báo và cả ba qua; GCC 16 dựng và qua `math_tests` (GCC không
    dựng `fs`, `shader`). Còn mở: `jobs`, `capture`, `table` không có tệp test riêng; `math_tests`
    chưa dựng thử cho Android (đường `sse2neon`); ba tệp test ấy chưa chạy qua `check.py`.
    (d) Nguồn không target nào dựng: `SRC/shader/library.cpp` (184 dòng, nạp nóng) và
    `SRC/render/target.cpp` (223 dòng) cùng hai header của chúng.
    (e) `Window::adopt(ANativeWindow*)` và `adopted_size()` khai trong khối `__ANDROID__` của
    `SRC/window/window.hpp` mà không có định nghĩa nào trong `SRC/`.
    (f) Preset: `android-x86_64` kế thừa triplet vcpkg `arm64-android` và trên máy chưa có cây
    dựng hay gói nào cho nó. Chưa dựng thử. (Nhánh iOS link `game_jobs` và `game_capture` mà hai
    target chỉ tạo khi `WIN32 OR ANDROID`: ĐÃ SỬA 2026-10-13, mục 49.)
    (g) Cổng dựng của CMake yếu hơn cổng `check.py`: `config/warnings-*.txt` trong repo là bản
    2026-10-05 (17 cờ chung, 6 cờ GCC, 6 cờ Clang, tức 23 cờ mỗi trình dịch), bộ cpp23 hiện tại là
    29, 23, 32 (52 cờ với GCC, 61 với Clang, 84 cờ khác nhau); `cmake/GameSanitize.cmake` chưa có
    bốn nhóm UBSan mở rộng và `cmake/GameHarden.cmake` chưa có `GAME_STL_DEBUG` của mẫu. Vì vậy "84
    cờ", "UBSan mở rộng" và "debug mode của libstdc++" trong mục 3 của `AGENTS.md` chỉ đúng với
    `check.py` và `check.py --run`, không đúng với `ctest --preset`. Nâng ba tệp đó theo mẫu sẽ làm
    lộ cảnh báo mới trên cả cây; chưa đo là bao nhiêu.
    (h) `.clang-tidy` và `.clang-format` ở gốc repo là bản cũ còn luật hình thức (`readability-*`,
    cỡ hàm, `ColumnLimit`). `check.py` không đọc chúng; chúng còn tác động tới clangd của trình
    soạn, tới `TOOLS/port/forge2_port.py` và tới bộ sinh protocol (đọc `ColumnLimit`).
    (i) `collision_tests` và `collision_alloc_tests` báo Skipped cả khi có đủ dữ liệu thật, vì ca
    "chờ Model" của chúng trả 77; câu "không có `_raw` thì trả 77" ở mục 11 của `AGENTS.md` mới nói
    một nửa.
    (j) Dựng client cần Pillow: `TOOLS/content/build_i18n.py` import `PIL` và chạy ở mọi lượt dựng
    `thienlong_client`; chưa tài liệu nào ghi yêu cầu này (máy đang có Pillow 12.3.0).
    (k) `check.py` trên `SRC/client/display/display_gpu.cpp` còn đỏ một chẩn đoán:
    `clang-analyzer-optin.performance.Padding` ở `Display::State` (37 byte đệm, tối ưu là 5; từ
    2026-10-09, sau khi thêm trường `is_bare`, bộ kiểm báo 36 và 4), có từ
    commit `b830c03` thêm trường cho bảng chọn nhân vật. Khối trường của struct này vốn xếp theo
    chính bộ kiểm đó, kèm ràng buộc thứ tự huỷ ghi ngay trên khối (device trước đối tượng GPU,
    feeder trước spinner, head sau device, forward, ui_pass). Thứ tự bộ kiểm đề nghị giữ nguyên
    thứ tự tương đối của các trường giữ tài nguyên, nhưng xếp lại 107 trường là đổi thứ tự huỷ của
    cả đối tượng: phải chạy client thật tới lúc đóng cửa sổ mới kiểm được, và lượt khảo sát không
    dựng exe client (bước i18n của nó ghi vào `CLIENT/data` dùng chung trong lúc có phiên khác làm
    giao diện). Bảy chẩn đoán khác của tệp, cũng từ commit đó, đã sửa ngày 2026-10-08: ba include
    thiếu (kèm thêm `gui`, `ui/panel` vào dòng `client/display` của bảng tầng, vì tệp vốn dùng
    `gui::Box`, `ui::panel::Role`, `ui::panel::ShownModel`), `store_roles` thành `const`, ba chỗ
    đọc `role_shot` sau lời gọi hàm thành viên nay đi qua một tham chiếu lấy ngay sau phép kiểm.
    (l) Phép kiểm gói shader lệch đời (`render/detail/shaders.hpp`, `check_blocks`) chỉ so cỡ khối
    hằng của khung và của lệnh vẽ. Ngày 2026-10-09 giao kèo giữa `forward.cpp` và `model.vs` đổi
    mà hai cỡ ấy giữ nguyên (chỉ số đèn của bản sao dời từ `Draw::lamp` sang ô hàng cuối, cột đầu
    của ma trận trong buffer `worlds`): gói `.f2s` cũ nạp cùng exe mới không bị từ chối, bản sao
    instanced chỉ mất ánh sáng đèn điểm; gói mới với exe cũ thì mọi bản sao nhận đèn số 0. Không
    đọc ngoài biên (shader kẹp chỉ số về 31). Bản cài PC chép exe và gói cùng lúc nên không dính;
    APK giải nén gói ra máy thì có thể dính như lần màn hình đen trước đây. Cần một số đời của
    giao kèo nằm trong gói (hoặc băm nguồn shader) để `ShaderPair::load` so; chưa làm.

46. **Bảng chuyển cảnh: lúc nào bản gốc phát `PLAYER_LEAVE_WORLD`** (2026-10-09,
    `Hud::note_loading`, `Display::State::scene_load`; panel C++ đã gỡ ở G1-K, bảng chạy bằng
    `SceneTrans.lua` gốc). Bản port hiện bảng `SceneTrans` mỗi khi một cảnh của màn chơi đang nạp, kể cả lần vào game đầu tiên từ bảng chọn nhân vật và lần nạp
    đầu của tiến trình khi chạy không có `--login`. Script gốc chỉ hiện bảng ở sự kiện
    `PLAYER_LEAVE_WORLD`; chưa tháo chỗ `Game.exe` phát sự kiện đó (chuỗi ở `0x140afc7f8`), nên
    chưa biết lần vào game đầu tiên bản gốc hiện bảng này, hiện video nạp (`PlayLoadingVideo`) hay
    không hiện gì. Cần: `python -B TOOLS/port/pe_refs.py "F:/tl 2026/Bin64/Game.exe" refs
    0x140afc7f8` rồi lần ngược tới thủ tục gọi (`CGamePro_Enter`, `CGamePro_ChangeScene`).

47. **Máy chủ: review cuối 2026-10-12 — đã sửa và còn mở** (`src/server/gate`, `src/server/account`,
    `src/server/guard`, `engine/net/shard.hpp`). ĐÃ SỬA: (a) gate gọi IPC auth/store đồng bộ trong
    tick, nay qua luồng thư ký (`docs/SERVER-BAO-MAT.md` mục "Tài khoản qua gate"); (b) `pump` của
    gate bỏ các sự kiện sau sự kiện thứ 512 của một lượt chờ, mà reactor IOCP đã xoá cờ của chúng,
    nên với hơn 512 socket cùng có việc một số socket không bao giờ được đọc lại và byte đã gửi
    không được trừ khỏi outbox; nay xử lý mọi sự kiện; (c) `SpscMail::poke` đọc `parked_` trước
    fence, cặp ghi tail rồi đọc cờ ngủ bị đảo được trên x86, bên nhận có thể ngủ với phần tử trong
    hàng; nay fence trước lần đọc đầu (đo `core_bench` trên máy dự án: `spsc_inline` từ khoảng
    100–320 xuống 19–41 triệu tin/giây; người dùng duy nhất là hàng auth và hàng thư ký, vài nghìn
    tin/giây); (d) `load_account` coi lỗi đọc bảng `ban` là không bị cấm; nay lỗi là lỗi; (e)
    `redeem` không xét bảng `ban`; (f) `CreateAccount` tên trùng trả `kDuplicate` mà không ghi lần
    thử, dò tài khoản không trần; nay tính vào trần theo IP; (g) `guard::Pace` dời mốc tới cả bước
    vượt tầm chưa bị phạt và đặt lại mốc khi tick không tiến, nên nhảy xen bước thường không bao
    giờ bị bắt (test chặn ở `Test/Server/guard_tests.cpp`). ĐỢT 2 ĐÃ SỬA: (h) cấm sau khi đổi vé: store
    hỏi auth `kStanding`, nhớ ≤5 giây; (i) `Resume` lưu digest token, giữ 60 giây, dùng một lần;
    (j) `serve_loop` không chặn, 64 kết nối, hạn đọc/ghi riêng. (l) `catch_up` của gate cộng 1/60 giây vào
    mốc tick sau mỗi lượt, kể cả lượt bị sự kiện đánh thức sớm: 400 kết nối tới đẩy mốc xa ~6,4 giây
    và vòng chờ tới đó không chạy tick; nay `gate::next_tick` giữ mốc khi thức sớm (test
    `early_wakes_keep_deadline`; 400 kết nối im lặng: bắt tay thật p99 6187 → 33 ms). CÒN MỞ: (k)
    `gate_tests` không dịch được (thiếu `metrics::Registry`, `gate::Backing`) và test `layers` đỏ
    (`metrics/serve` chưa có trong bảng tầng) từ trước lượt này.

48. **Giao diện màn chơi 2026-10-13: các chỗ chưa đọc được từ mã máy hay chưa làm** (`TAILIEU/MAN-CHOI-GIAO-DIEN-2026.md`).
    (a) Đơn vị tốc độ xoay người mẫu của bảng nhân vật: `RotateBeginEx` nhân đối số với 0,5 rồi đưa cho engine qua
    `[vtable + 0x498]` của đối tượng toàn cục `0x14103e688` trong `Game.exe`; chưa tìm ra lớp chứa hàm đó. Bản port coi là vòng mỗi giây
    (nút giữ 1 giây quay 0,15 vòng). Cần: tháo hàm ở slot `0x498` của lớp mà `0x14103e688` trỏ tới, đọc cách nó đổi số này ra góc mỗi khung.
    (b) `SequenceFrame` của hệ hạt: chỉ đọc `stacks`, `slices`, `repeat_times`, `loop`, `pingpang`, `start_range`; `play_mode`, `head_and_tail`,
    `play_times`, `baned_frames` chưa biết nghĩa (mọi giá trị coi như `normal`, `none`). Cần: tháo `SequenceFrameAffector` trong `Plugin_ParticleFX2.dll`.
    (c) Mặt đất nướng một ảnh (16 điểm ảnh mỗi ô, trần 8192 trên PC; 8 điểm ở bản đầu quá mờ theo chủ dự án) lọc đúng nhưng chi tiết đá chạm lớn (sân Lạc Dương, bậc thềm) thấp hơn bản gốc vẽ từng
    ô theo độ phân giải màn hình; làm cho đủ cần shader mặt đất nhiều lớp (lớp cọ, lớp phủ, lightmap) thay cho ảnh nướng. (d) Bản đồ thế giới
    chưa có tooltip, bạn bè, đối địch, cờ chỉ huy, thông tin bang chiếm; ảnh nhãn thành phố đang là chữ Hán (ảnh dựng sẵn). (e) Bốn tham chiếu mà
    chính dữ liệu gốc cũng thiếu: ảnh `MainMenuBar/EXPBar_3`, `Chat/CommonEditBoxBK`, hoạt ảnh `CoolDownEnd2`, bộ ảnh `BaseInterface` (không có trong
    `_goc`); client gốc cũng không vẽ chúng. (f) Số ô hòm đồ (20 và 60) và nhiệm vụ (20 và 20) lấy theo giả định, chưa có số liệu từ máy chủ. (g) Bảng
    tầng ngoài đầu tiên: ô combo `sceneMap_ComboList` chưa mở xổ danh sách. (h) `Test/Client/map_tests.cpp` không dịch được từ trước lượt này vì gọi
    `WaterCover`, `water_cover`, `pour_liquid`, `water_at`, `ray_water` không còn trong `src` (cây bị khôi phục ngày 2026-10-09 thiếu chúng); chuỗi
    `kTable` của ca `book_reads_clip_planes` còn bị hỏng dấu tab và xuống dòng, đã sửa 2026-10-13. Các test đỏ từ trước: `ui_panel`
    (`desk_paints_notice`), `ui_quest` (thiếu số vàng), `gui_sheet_tests` (không dịch được).

49. **iOS: dọn nguồn 2026-10-13 và những gì chỉ kiểm được trên máy Apple** (`apple/HUONG-DAN.txt`). Máy phát triển
    không có macOS nên không nhánh `IOS` nào qua trình dịch; mọi sửa dưới đây dựa trên đọc mã, header của miniaudio
    và `FindVulkan.cmake` của CMake 4.4, rồi cấu hình lại preset Windows và Android để chắc phần chung không vỡ.
    ĐÃ SỬA: (a) `game_jobs` và `game_capture` nay tạo cho cả iOS (mục 45f nêu lỗi này); (b) `project()` chỉ khai `CXX`
    nên `.mm` không được dịch: nay `enable_language(OBJCXX)` và ARC khi `IOS`; (c) `engine/audio/detail/native.cpp`
    include miniaudio, mà bản iOS của nó chứa `@interface` và `@autoreleasepool` và không nạp khung lúc chạy
    (`MA_APPLE_MOBILE`): nay dịch thành Objective-C++ và link CoreFoundation, CoreAudio, AudioToolbox, AVFoundation;
    (d) `gpu/vulkan/instance.cpp` đòi `VK_KHR_win32_surface` trên mọi nền không phải Android, nên trên MoltenVK
    `has_surface` luôn sai: nay `VK_EXT_metal_surface` khi `__APPLE__`; (e) preset iOS không có toolchain vcpkg nên
    `find_package(lz4)` sẽ đỏ: nay kế thừa preset ẩn `ios` (`$VCPKG_ROOT`, triplet `arm64-ios`, simulator
    `arm64-ios-simulator`); (f) gói shader của Android và iOS ghim `build/clang-asan/shaders`, cây chẩn đoán bị xoá khi hết
    đợt soi bug: nay `cmake/GameDeviceShaders.cmake` chọn cây có đủ gói; (g) `kAtlasEdge` dùng `__APPLE__` (cả macOS),
    nay `ui::kPhone`; `has_loader()` của `surface_ios.mm` dlopen rồi trả true cả hai nhánh, nay trả true.
    CÒN MỞ, cần máy Apple: (1) `find_package(Vulkan)` tìm thư viện tên `vulkan`, iOS chỉ có MoltenVK, nên phải đặt
    `Vulkan_LIBRARY`, `Vulkan_INCLUDE_DIR` tay (đã ghi trong HUONG-DAN); chưa biết `Vulkan::Vulkan` có đủ cho
    `vulkan_metal.h` không. (2) MoltenVK có đạt `append_capable` (Vulkan 1.3: `bufferDeviceAddress`, timeline semaphore,
    dynamic rendering, synchronization2) không; chưa đo, nếu thiếu thì `Instance::devices()` trả `kUnsupported`.
    (3) `VK_KHR_portability_subset` không được bật ở `gpu/vulkan/device.cpp`: spec đòi bật khi thiết bị công bố nó,
    MoltenVK công bố. (4) `vcpkg.json` kéo `sdl3` và `libpq` cho mọi nền; chưa biết hai gói dựng được cho `arm64-ios`
    không, nếu không thì thêm `"platform"` cho chúng. (5) Cảnh báo `-Werror` trên hai tệp `.mm` chưa từng chạy.
    (6) `ITSAppUsesNonExemptEncryption=false` trong `Info.plist.in` và `PrivacyInfo.xcprivacy` rỗng: client có libsodium
    (`seal`), dùng `stat` và đồng hồ đơn điệu; chủ dự án quyết khai báo mã hoá, và phần API cần lý do (FileTimestamp
    `C617.1`, SystemBootTime `35F9.1`) đối chiếu khi App Store Connect báo. (7) `setpriority` của `core::sleep_until`
    trên iOS luôn thất bại (không đặc quyền) và bị bỏ qua; vô hại nhưng thừa một lời gọi hệ thống mỗi lần ngủ.
    ĐÃ LÀM THÊM 2026-10-15 để iOS có đủ đường như PC (chỉ viết và kiểm bằng trình dịch NDK, KHÔNG phải bản dựng Apple):
    `ios_main.mm` giữ `host::Online` và `host::Soundscape` như `android_main.cpp` (cùng `client/host`, một mã cho hai vỏ):
    nối máy chủ thật (bảng cổng `Table/gates.tsv`, `online::Bridge`, thực thể máy chủ qua `cast`), nhạc cảnh, chỗ đứng máy
    chủ đặt (`HostStep::entry`), chạm hai ngón là nhảy, Hz màn (`UIScreen.maximumFramesPerSecond`; iPhone chỉ 60 vì chưa khai
    `CADisableMinimumFrameDurationOnPhone`, iPad lấy mức cao nhất), ảnh giao diện đọc bản nấu ASTC (`Painter` theo tier).
    `--stage` của `package_apk.py` mang bản nấu `--baked` (chỉ ASTC) và sound đã cook như APK. CÒN MỞ, cần máy Apple:
    (8) `ios_main.mm` chưa qua Apple Clang: phần Objective-C++ mới (đọc `maximumFramesPerSecond`, chạm hai ngón) chỉ do đọc
    mã; phần C++ dùng chung với Android (`host.cpp`, `touch.cpp`, `painter.cpp`) đã dịch bằng NDK không cảnh báo. (9) `Info.plist`
    chưa khai `NSAppTransportSecurity` cho TCP thô: socket POSIX trực tiếp không đi qua ATS, nhưng iOS 14+ đòi
    `NSLocalNetworkUsageDescription` khi nối máy chủ trong mạng LAN (đã có), còn lên Internet thì chưa thử. (10) `socket_posix.cpp`
    dùng `SO_NOSIGPIPE` và `poll`; chưa chạy trên Darwin. (11) Bản nấu ASTC trên iOS bỏ ETC2: máy không có ASTC (iPhone 5s trở về trước)
    không chạy, vô hại vì iOS tối thiểu của dự án có A8 trở lên.
50. **Shader chuyển sang Slang 2026-10-13: các chỗ chưa kiểm** (`engine/shader/detail/slang.cpp`, `reconcile.cpp`).
    Nguồn `src/client/render/shaders/*.slang`; Slang (`slang.dll` của Vulkan SDK 1.4.363) dịch ra SPIR-V, DXIL, DXBC;
    DXC chỉ còn đọc phản chiếu DXIL; GLSL của GLES vẫn viết tay (`*.glsl`). Đã đo: băm phản chiếu của 7 gói × 4 đích
    bằng bản DXC cũ; ảnh chụp Vulkan của `--bare` giống bản cũ từng điểm ảnh, ảnh có giao diện lệch ít hơn nhiễu giữa
    hai lượt chạy cùng một bản. CHƯA KIỂM: (a) DXIL và DXBC do Slang sinh chưa chạy trên D3D12 và D3D11 thật (mục 25: hai
    backend chưa hiển thị được); mới biết DXIL có chữ ký và phản chiếu của nó khớp SPIR-V. (b) DXIL to hơn bản DXC
    (`model.vs` 7668 lên 11448 byte), chưa tìm cờ giảm; chỉ ảnh hưởng gói trên đĩa của D3D12. (c) Stage hull, domain,
    geometry, compute, mesh, amplification và `Stage::kLibrary` chưa shader nào dùng, nhánh tương ứng của `stage_of`,
    `profile_of` chưa chạy; `kLibrary` bị từ chối. (d) Append/Consume: Slang ghi bộ đếm thành biến `<buffer>.counter`
    (đo bằng `slangc`), `reflect_spirv` từ chối tên ấy; chưa shader nào dùng. (e) Sinh GLSL của GLES bằng Slang
    (`-target glsl`) để bỏ ba tệp `.glsl` viết tay chưa thử, chưa đo. (f) Mỗi lần dịch chạy 2 tới 3 lượt Slang (SPIR-V
    và DXIL để đối chiếu, thêm DXBC); 7 gói × 4 đích mất 2,6 giây trên máy dựng, chưa so với DXC. Khoá cache của gói
    gồm `kPipeline` trong `compiler.cpp`: đổi cách ghép phản chiếu thì tăng số này, không thì gói cũ vẫn "còn mới".
51. **Vũ khí, hiệu ứng đồ, đòn đánh, tuyệt chiêu 2026-10-14: đã có và CHƯA làm** (`TOOLS/content/export_weapons.py`,
    `export_skills.py`, `src/client/figure/look/{weapon,skill}`, `avatar/locator`, `place/fx`). Đã có và đã chạy thật:
    vũ khí theo bảy khe gắn vào locator của mẫu nhân vật (đứng, chạy, đánh); phím 1 tới 9, `--skill`, `--auto-strike`
    chạy đòn đánh thường và tuyệt chiêu qua chuỗi `SkillTemplate_V1` cột 18 -> `ActionSet` -> `Effect/all.skill` -> clip
    (mốc của `all.skill` là PHẦN độ dài clip); hiệu ứng AnimEffect và âm thanh của kịch bản; hiệu ứng đồ (đá quý gắn
    vũ khí: `--weapon <item> --gem <đá>`) bám điểm `武器特效点` mỗi khung; hiệu ứng của skill và của đồ có vòng đời
    (LifeTime của effect, `duration`/`repeat_delay` của emitter, hết hạt thì gỡ). CHƯA làm hay chưa kiểm:
    (a) Hành trang, skill, đá quý chưa nối máy chủ: `hero.equipment`, `hero.skills` do `--weapon`, `--skill`, `--gem`
    gieo (`Display::State::seed_equipment`); client chưa có gói trang bị, gói skill, gói đá quý.
    (b) Điều kiện chưa giải trong `FUN_140604720` của Game.exe 2026: hàm `FUN_1405e95a0(char)` (dữ liệu nhân vật
    `+0x3c == 0`) và `locator id != *(int*)(char+0x424)` (nghi là vũ khí thời trang đè hình); port bỏ cả hai, nên vũ khí
    đã đè hình vẫn hiện hiệu ứng của hình gốc. Chỉ số hiệu ứng của đá quý tới 169 nhưng ItemVisualLocator chỉ có 34 ô
    (cột 29 tới 62): mã máy đọc ngoài hàng, port trả không hiệu ứng (`Khác gốc:` ở `look::gem_effect`).
    (c) Khe lưng, hông 1, hông 2 chỉ nhận hiệu ứng khi cờ cột 19, 23, 27 bật; võ hồn (KFS, điểm 18) và vũ khí ảo
    (điểm 22, `0x16`) không có hiệu ứng đá quý và chưa có mẫu riêng. Cờ ẩn vũ khí lúc đánh chưa làm.
    (d) Bảng `CharEffect`, `SpecialDressEffect`, `CangPinSetEffect`, `ChongLouEffect`, `GemEffect_Cloth`,
    `Exterior_GemEffect`, `DressGem`, `WeaponVisualLocator` (hiệu ứng đồ không phải vũ khí: áo, bộ, cường hoá, tinh luyện)
    chưa đọc và chưa xuất bảng nào; hiệu ứng của trang phục khác vũ khí vẫn thiếu.
    (e) Kịch bản, cập nhật 2026-10-16: `accept_chain`/`finish_chain` (`look/skill.hpp`) port `Start_MagicSend` và
    nhánh `FreshAnimation` của `SKILL_SEND` — `kRandom`, `kLinkedEx`, `kLinked` đều vào danh sách bước; lệnh cùng skill
    khi clip chưa hết thì hoãn và tăng chỉ số hai lần (phát 0 rồi 2 với liên hoàn 3 bước), không phát theo chú thích
    (1,2,3) của enum. `ShakeTime` bắn cue `kShake`, camera gọi `AddOneVib(10, 8, 2)` một nhịp mỗi khung. `kRandom` có
    `send_ms` ngắn hơn clip thì `rate` là clip/send (không còn luôn 1). Còn thiếu: `OnAnimationHit` chỉ đặt cờ hoàn tất
    lệnh ở gốc, chưa có hàng lệnh đó nên không phát số lần trúng; Ribbon (`AnimationRibbon`, material không nằm trong
    thư viện hạt) và SceneLight (đèn cảnh, bảng sự kiện không có dòng) chưa dựng; âm thanh chiêu phát 3D tại điểm
    gắn, tai nghe là camera, nhỏ dần từ 2 m tới 40 m (2008 để rolloff factor 0 nên chỉ pan); chưa có đạn (`BeHit`,
    bullet) và đường nhảy của khinh công. 116 tên animation của
    `skill_clips` không có clip trong kho.
    (f) Hiệu ứng theo dõi: emitter chỉ theo `duration` và `repeat_delay` ở hiệu ứng skill và hiệu ứng đồ
    (`Spawn::is_tracked`); hiệu ứng của cảnh vẫn phát mãi, CHƯA đo bản gốc có lặp lại theo `repeat_delay` hay không.
    `LifeTime` của element Particle (không phải dải) chưa dùng; hiệu ứng đồ chưa theo tỉ lệ người chơi (`Stand::scale`).
    (g) Dung lượng: `weapon_effects.tsv` 1,1 MB, `effect/all.effect` + `all.particle` 4,2 MB, clip đòn đánh 102 MB đi
    vào `avatar.files.tsv`: APK và bản điện thoại chưa đo lại; nạp đầu của cảnh Đại Lý đo 2026-10-14 trung vị 490 ms
    ở cả bản cũ lẫn bản mới (ngân sách 450 ms; máy hôm đó chậm hơn lúc đo 387 ms ngày 2026-10-13).
52. **Xương/animation (figure/anim, avatar/rig, model clip): review sâu 2026-10-14 — đã xác minh và kẽ hở còn mở**.
    Phạm vi đã đọc: `src/client/figure/anim/{asset,rig,pose}.hpp/cpp`, `src/client/figure/avatar/avatar.cpp:40-120,255-296`,
    `src/client/figure/avatar/rig.cpp`, `engine/resource/model.cpp:1195-1241` (read_track), `engine/render/forward.cpp:672-700`
    (add_joint/skin_of), `src/client/place/ogre/quat.hpp:19-23`, `src/client/app/client/display/graphic/scene.cpp:334-338`,
    `Test/Anim/anim_tests.cpp`, `Test/Avatar/avatar_data_tests.cpp`. Không sửa code trong lượt này theo phạm vi.
    Đã xác minh ĐÚNG (không phải lỗi, ghi để khỏi đào lại):
    - `Quat{}` là đơn vị (x=y=z=0, w=1; `quat.hpp:19-23`) nên `accumulate` nlerp từ đơn vị đúng (`pose.cpp:110`).
    - Ánh xạ skin-joint -> ma trận khớp: `add_joint` (`forward.cpp:672-684`) lấy `ready[joint]` theo chỉ số skin-joint;
    loader ép identity (`avatar/rig.cpp:45-49` `check_bone`: `skins.front().joints.at(handle) != handle` thì `bad`), lưới
    `.mesh` tự dựng identity (`ogre_mesh.cpp:881-883`).
    - Toán bind/offset theo OGRE và có test: `anim_tests.cpp:297-331` (loop_time biên), `:468-473` (kBadBone/kBadTime),
    `:485-534` (palette/retarget); `avatar_data_tests.cpp:109-119` (ma trận hữu hạn trên dữ liệu thật).
    - `wrap_time` treo với +Inf (`pose.cpp:30-35`, `while (time > length)`) nhưng không tới được hôm nay: caller duy
    nhất ngoài test là `accumulate` với thời gian đã quấn (`apply` chặn `!isfinite` ở `pose.cpp:161`); `sample` vẫn
    công khai nên caller tương lai phải giữ hữu hạn.
    - `loop_time` âm lớn đúng một lần cộng (`pose.cpp:136-141`); `bracket`/`interpolate`/`linked_scale` đúng nhánh OGRE đã port.
    Lỗi/kẽ hở (mỗi điểm có evidence, đều cần ĐIỀU KIỆN dữ liệu mới nổ):
    (a) Sampler input/output lệch số lượng -> ném `std::out_of_range` thay vì trả lỗi: `read_track`
    (`model.cpp:1229-1241`) kiểm hiện diện/kiểu-rộng mà không kiểm số đếm input == output; `key_at`
    (`avatar/rig.cpp:161-179`) trỏ `values.at(index*3|4)` theo chỉ số thời điểm. Tệp lệch -> `.at()` ném lúc
    nạp, xuyên qua mọi lớp `Result`/`Status`, chỉ bị chặn ở `main.cpp:381-388` thành "Lỗi không lường trước"
    exit 1. Cần để kết luận: một GLB sampler lệch đếm chạy qua `Avatar::load` xem có đúng exit 1 không
    (chưa làm — cần tạo tệp hỏng, không dám đụng dữ liệu).
    (b) Key times không sắp xếp -> sai thầm: không chỗ nào trên đường GLB kiểm/ép sắp xếp (đã grep
    `sort|is_sorted` trong `model.cpp`, `avatar/rig.cpp`: 0 kết quả); `bracket` (`pose.cpp:53-62`) dùng `lower_bound`
    đòi dãy sắp. Tệp vi phạm -> nội suy sai, không crash, không báo. Cần: quét một lượt `times` trên `Model/*.glb`
    đã gom xem có tệp nào không tăng dần không.
    (c) `check_same_bones` (`avatar.cpp:72-79`) chỉ so tiền tố chung: comment dòng 71 hứa "cùng handle và tên",
    nhưng code lấy `min` độ dài rồi chỉ tìm lệch trong tiền tố. Clip-file dài hơn main mà khớp tiền tố ->
    lọt; track xương thừa -> `apply` trả `kBadBone` MỖI KHUNG (`pose.cpp:162-164`); `PlayerActor::update` trả fail
    (`avatar.cpp:286-287`); `compose_frame` in "Người chơi: ..." ra stderr mỗi khung rồi bỏ qua người chơi
    (`scene.cpp:334-338`) — nhân vật tàng hình + spam log. Cần: liệt kê `bones.size()` của từng clip-file so với
    main trên dữ liệu thật xem có ca nào dài hơn không.
    (d) Asset suy biến -> Inf/NaN thầm: `Rig::create` và `key_at` không kiểm hữu hạn; scale bind 0 -> `div_vec3`
    ra Inf (`rig.cpp:179`), NaN trong quaternion bind lan qua `rotation_matrix`. Test `is_finite_matrix` chỉ cover dữ
    liệu thật đang có (`avatar_data_tests.cpp:109-119`). Cần: một ca test với bind scale 0 / NaN để chốt hành vi
    (chưa viết — luật Test: sửa bug mới viết).
    (e) Chưa tối ưu (đã đọc, chưa đo máy — không nhận là chậm): `apply` quét `any_of` toàn track mỗi khung
    (`pose.cpp:162-164`) trong khi `pose.size()` (từ `bind_pose` của cùng rig) và `tracks` đều bất biến sau nạp ->
    kết quả vòng-lặp-bất-biến, dời được ra lúc nạp; `make_transform` (`rig.cpp:149-155`) và `matrix_of`
    (`avatar.cpp:113-119`) dùng `.at()` với chỉ số hằng trong đường nóng mỗi xương mỗi khung (không bao giờ ném
    được — chỉ là rào biên dịch có thể chưa gấp). Cần: số đo khung trước/sau (chưa có workload đo) mới được kết luận.
    Ghi chú trung thực: toán xương khớp OGRE và có test; 5 điểm trên đều cần điều kiện dữ liệu mới nổ,
    dữ liệu hiện tại không nổ (test xanh trên dữ liệu thật là bằng chứng).
53. **Địa chỉ `Game.exe` trong mã và tài liệu không khớp bản `Game.exe` đã trích** (2026-10-14,
    `TAILIEU/GAME-EXE-2026/so-sanh/dia-chi-trich-dan.tsv`, sinh bằng `TOOLS/port/rea/compare_client.py`). Đo: lấy mọi địa
    chỉ `0x14xxxxxxx` trong `src`, `engine`, `TOOLS`, `docs`, `TAILIEU`, `Test` (trừ dump máy và hồ sơ khôi phục) rồi đối với
    `Game.exe` đã trích (SHA-256 `3f8bb47de0bc...`, dấu thời gian PE 2026-09-29) bằng quét lệnh capstone trong phạm vi hàm của
    `.pdata`. Phần lớn địa chỉ trỏ vào hàm đúng đầu hàm hay đúng ranh giới lệnh (khoảng 90 đầu hàm, toàn bộ nhóm đăng nhập, gói tin
    và `CGamePro_*`, lớp ảo khớp tên). Nhưng khoảng 180 địa chỉ nằm GIỮA một lệnh, nên không thể là mốc mã; hơn 130 trong số đó chia
    hết cho 16, tức dạng đầu hàm của một bố cục khác (cột `detail` ghi lệnh chứa nó bắt đầu ở đâu). Bằng chứng hai chiều: (a)
    `IsLMSJSecond`, `IsJYJYSecond`, `IsWJQFSecond` có nội dung ĐÚNG bản này (bảng id 821..826 ở 0x140b1f8f4, 827..834 ở 0x140b1fa54,
    hàm cuối so 0x1171/0x1172) nhưng mã trích dẫn địa chỉ lệch đúng 0x500 so với hàm trong bản trích; (b)
    `docs/AUDIT/evidence/jump_re.log` tháo 1405ea2f0 (viết không có 0x để công cụ quét không đếm lại) ra `add byte ptr [rax], al`,
    mà byte tại đó giống bản này, nên địa chỉ ấy sai từ đầu chứ không phải bản khác. Hai hướng loại nhau, nên chưa kết luận được là
    địa chỉ ghi sai (typo, tháo nhầm đầu hàm) hay các phiên port đã đọc một bản `Game.exe` khác (`F:\tl 2026\2026\Bin64\Game.exe`
    đã bị xoá 2026-10-09; dự án Ghidra TLBB chỉ có một `Game.exe`). Đã sửa 9 chỗ chắc chắn ở 3 tệp nhờ nội dung đối chiếu được (bảng
    tên loại action ở 0x140ed88d0 thay cho 140ed78d0, ba hàm `Is*Second`, `Jump` ở 0x1405ea2b0); còn lại không sửa vì không biết
    địa chỉ đúng. Hệ quả: dùng địa chỉ trong mã/tài liệu để tra thẳng `decompile.zip` của bản trích có thể ra hàm
    khác; cần tra bằng tên hàm script (`lua_api.tsv`), chuỗi assert hay lớp (`classes.tsv`). Cần để kết luận: một bản `Game.exe`
    2026 khác nguồn (cài lại client, hay SHA-256 của bản đã port) để so từng địa chỉ; nếu cài lại được thì chạy lại
    `compare_client.py` với tệp đó và xem số địa chỉ giữa lệnh về 0 hay không.
    Đo thêm 2026-10-15, có bản thứ hai `D:\XTLBB\Bin64\Game.exe` (3.71.9509, SHA-256 `62e0174f…`, dấu thời gian PE 2026-08-11, đường PDB
    cùng `Temp_Release_v3-71-9001`). (a) Dự án Ghidra TLBB: `Game.exe` có SHA-256 trùng bản trích, nhập từ `F:/tl 2026/2026/Bin64`. (b) Trên 229
    địa chỉ khác nhau thuộc mã: 9 địa chỉ (19 dòng: `hero.hpp:197`, `create_role.cpp:371`, `role_cast.hpp:3`, `outline.hpp:7`,
    `actions.hpp:73,81`, `book.hpp:74`, các tệp `TOOLS/port/oracle/*_api.lua` tương ứng, `docs/CAMERA-2026.md:182`,
    `docs/TAO-NHAN-VAT-2026.md:32,68,69,76`, `docs/TIEN-DO.md:1145`) là đầu hàm `.pdata` của bản 11/08 mà không phải đầu hàm của bản 30/09.
    Theo chữ ký 24 lệnh đầu, 6 trong số đó có đúng một hàm cùng mã ở bản 30/09 (địa chỉ bản 11/08 viết không có 0x để
    `compare_client.py` không đếm lại): 14001d6a0→0x14001d9b0, 140017280→0x140017590, 140193f30→0x140194aa0, 1402cc5c0→0x1402cd4e0,
    140343540→0x1403443b0, 14063df70→0x14063fb60. 1403954d0, 140342950, 140342a10 có nhiều ứng viên. Đầu hàm ngẫu nhiên chỉ trúng 0,4% (đo trên 3 000 địa chỉ ngẫu nhiên của `.text`), nên các phiên port
    trước đã đọc bản 11/08 hay một bản rất gần nó. (c) 87 địa chỉ không hợp lệ ở cả hai bản. Cộng 0xc00 (chênh lệch VA và offset tệp của `.text`)
    thì 6–7 địa chỉ thành đầu hàm, nên vài địa chỉ là offset tệp viết nhầm thành địa chỉ ảo. Phần còn lại chưa giải thích được. Trúng
    "ranh giới lệnh" là bằng chứng yếu: địa chỉ ngẫu nhiên trúng 20,6%. Chưa sửa các dòng ở (b) vì chưa rõ dòng nào cố ý nói về bản 11/08
    (số vàng của trọng tài có thể đã sinh trên `LuaPlus.dll` của bản đó). Cần để kết luận: biết bản nào nằm ở `F:\tl 2026\2026` trước ngày
    2026-10-09, rồi ghi bản dựng cạnh từng địa chỉ.

54. **Máy chủ gameplay 2026-10-15: các chỗ chưa kết luận được** (`src/server/zone/`, `src/server/scenedata/`, `docs/SERVER-SCENEDATA.md`,
    `docs/SERVER-DI-CHUYEN.md`)
    (a) Hướng quái và NPC: bảng cảnh ghi hướng theo bước 10 độ, `scenedata` đổi ra độ (`heading_degrees()`), `zone/content.cpp` đổi tiếp sang
    `0..65535` của `EntityAppear.direction` (tuyến tính). Chưa đối chiếu với client 2026 gốc góc (hướng 0 là +X hay +Z) và chiều quay (thuận hay
    ngược chiều kim đồng hồ), nên NPC có thể quay lệch một góc cố định khi client nối máy chủ. Cần để kết luận: client có module nối máy chủ,
    rồi so hướng một NPC đứng đã biết (ví dụ NPC ở Đại Lý) giữa `spawns.tsv` và hình dựng của client.
    (b) Luật đi của zone chỉ kiểm điểm đến của mỗi gói `Moved` (độ nới 20 cm ở mép) và không kiểm trục Y. Chưa đo xem trần tốc độ của gate có đủ
    nhỏ để một bước không vượt qua bức tường mỏng giữa hai gói hay không. Cần: đo bề dày nhỏ nhất của ranh giới không đi được trong lưới
    `.path` của vài cảnh so với bước đi lớn nhất gate cho qua trong một tick.
    (c) Bảng quái theo cấp người chơi (`spawns.level_*.tsv`) và quy tắc chọn (`spawn_operates`: `select_type`, `select_value`, `data_def`,
    `max_left`): `scenedata` chỉ nạp, ngữ nghĩa của `select_type` thuộc zone và chưa đọc từ mã 2008; zone chưa dùng bảng này nên chỉ đặt bảng
    quái gốc của cảnh.
    (d) Lệch giữa dữ liệu 2008 và lưới đi 2026: điểm đặt quái nằm ngoài lưới `.path` của client 2026 ở nhiều cảnh (`dali` 50/164, `kunlunshan`
    143/325, `guigu` 80/234; bảng đầy đủ ở `docs/SERVER-SCENEDATA.md`). Quái đặt ở đó đứng ngoài lưới và người chơi không tới được. Chưa biết
    là dữ liệu đặt quái 2008 cũ hơn bản đồ hay bản đồ 2026 đổi bố cục; không đoán vị trí mới.

55. **Trần tần số quét theo hạng CPU, chưa theo GPU** (2026-10-15, `viewer_win32.cpp` `RaisedRefresh`, `core::loop_plan`).
    Viewer nâng Hz của màn lên tối đa `loop_plan(cpu_count()).render_hz`: từ 8 luồng logic là 120. Máy laptop 8–16 luồng mà chỉ có GPU
    tích hợp có thể không vẽ kịp 8,3 ms một khung; khi đó Fifo ở 120 Hz hiện lặp khung (giật), tệ hơn đứng ở 60 Hz. `gpu::DeviceInfo` có
    `is_discrete` nhưng thiết bị GPU tạo trong `Display`, sau chỗ nâng Hz (cố ý: nâng trước khi tạo swapchain). Chưa đo được vì máy phát
    triển không có GPU tích hợp (i5-14600KF). Cần để kết luận: chạy `thienlong_screen_pace` cùng client `--walk` trên một máy GPU tích hợp
    có màn 120 Hz trở lên; nếu tỉ lệ "đúng 1 nhịp quét" thấp hơn ở 60 Hz thì đưa `is_discrete` (hoặc số đo khung thật) vào trần.

56. **Bản tiếng Việt của chữ thoại máy chủ 2026-10-15: các chỗ chưa kết luận được** (`dev/server/tables/server/dialogue.vi.txt`,
    `server_strings.vi.tsv`; `docs/SERVER-DU-LIEU.md` mục 6).
    (a) `server_strings.11` tới `.16` là các mẩu một chữ (二 三 四 五 六 之) mà máy chủ ghép vào câu khác; bản dịch "hai ba bốn năm
    sáu của" đọc đúng nghĩa từng mẩu nhưng chưa biết ghép ra câu nào, và máy chủ mới chưa dùng id đó (`grep server_strings` trong
    `src/server` không có kết quả). Cần để kết luận: nơi dùng 11–16 trong máy chủ gốc, hoặc khi máy chủ mới đọc `server_strings`.
    (b) Tám chuỗi (`lua.e3a84954`, `lua.14cfc13d`, `lua.caa184b4`, `lua.f33105e4`, `lua.7d57fa3c`, `lua.6032c811`, `lua.ca96f758`,
    `lua.ed1e2df2`) trong nhóm cảnh thảo nguyên chỉ có tiền tố và ghép với mục từ điển `OBJ_caoyuan_*` của client (Config/StrDictionary,
    không có trong `assets/i18n/*.tsv`). Bản dịch mục từ điển Việt sau này phải mở bằng dấu câu hoặc chữ nối được với tiền tố
    Việt, và xưng "ngài" (mục từ gốc dùng 您).
    (c) Câu gốc có lỗi chữ, đã dịch theo nghĩa hợp lý nhất: 枫侨街 (枫桥街), 碱 (咸) ở `lua.9fcd39e4`, `lua.48d03e78` ghi kinh Túc
    Dương Minh Vị trong khi các huyệt thuộc kinh Túc Thái Âm Tỳ (dịch sát gốc), 玉华坛 (五华坛), 称青霜 (程青霜, đã gộp thành
    "Trình Thanh Sương"). Nếu bản chuẩn của Lua gốc đúng là 称青霜 thì đổi lại.
    (d) Một số tên NPC và kỹ năng không có trong sách Kim Dung hay trong bảng của client được đọc Hán-Việt từng chữ (ví dụ 慧易 "Tuệ
    Dịch", khoảng 90 kỹ năng của NPC "texiaonpc"); đọc sai âm thì sửa ở bản vi, giữ nhất quán trong mọi câu nhắc tới.
    (e) 路霸 "lộ bá" và 饮鸩止渴 "Ẩm Chậm Chỉ Khát" (theo tên kỹ năng client đang hiển thị, 鸩 có thể đọc "trậm") còn khó hiểu với người
    chơi; chỉ sửa cùng lúc với bảng của client.

57. **Chiến đấu máy chủ lát cắt 3 (2026-10-15): các chỗ chưa kết luận được hoặc làm tạm** (`src/server/play/battle.cpp`, `src/server/zone/scene.cpp`).
    (a) Kỹ năng ban đầu là luật tạm của bản thử: đòn thường (id 0) cộng mọi chiêu chủ động cấp 1 của môn phái nhân vật (`starting_skills`), vì chưa có học kỹ năng ở NPC; thay khi làm học kỹ năng.
    (b) Chưa có trang bị: mọi người chơi coi như `weapon_type = 0`; `item::Inventory` thay `play::Bag` tạm ở lát cắt sau, nên thuộc tính vật phẩm đang bị mất khi nhặt.
    (c) Quái chưa phản công, nên đường chết và hồi sinh của người chơi (DeathNotice, Respawn Town/Here, phạt kinh nghiệm và tiền) mới được kiểm bằng mã đọc, chưa có test hay chạy thật. Hồi tại chỗ 30% sinh lực là số tạm (`revival_here`); Town là chỗ vào cảnh, chưa phải điểm hồi sinh của cảnh.
    (d) Đấu trường của một cảnh chỉ chạy tick khi có người chơi trong cảnh; cảnh vắng thì quái đứng yên (chỉ vật rơi vẫn hết hạn). Chấp nhận được khi quái không phản công; xem lại khi quái đuổi và đánh.
    (e) Chuyển cảnh qua cổng truyền tống chưa làm: bot thử đặt nhân vật sang cảnh có quái bằng cách sửa bảng `player` trong PostgreSQL (`scene`, `position_x`, `position_z`).
    (f) Ngày giờ và lịch (sự kiện theo ngày) vẫn UTC+8 cố định; chưa nối đồng hồ máy chủ thật.

58. **Chiến đấu phía client lát cắt 3 (2026-10-15): các chỗ chưa làm hoặc chưa chạy thật** (`src/client/app/client/fight`, `display/graphic/fight.cpp`).
    (a) Chưa chạy client thật với cụm v6: đăng nhập chỉ đi được bằng giao diện (chuột), mà agent bị cấm chiếm chuột. Đường mạng kiểm bằng `online_tests` (bridge hai chiều) và `fight_tests` (logic); đường vẽ và vòng đánh kiểm bằng `--talk-demo fight|fall` (máy chủ giả đúng hình tin, `graphic/fight_demo.cpp`), có ảnh chụp. Hai đường chưa gặp nhau trên một lần chạy duy nhất.
    (b) Thanh kỹ năng trang 1 (`Button_Action1`..`10`) vẽ kỹ năng đã học theo thứ tự `SelfSkills`: phím 1–9, phím 0 và nhấp ô đi qua `press_slot`; đang hồi thì `Gloom` (chưa có vệt `CoolDownEnd2`); không kéo thả; trang 2–3 và hàng biến thân vẫn giấu. Tên và thanh máu của quái, NPC, trân thú vẽ trên đầu (phông GBK12; thanh máu là thêm so với bảng 2008). Tên tuyệt chiêu chữ vàng hiện trên đầu người chơi khi chiêu khác 0 được xác nhận. Đã nhìn ảnh: sói 11158 tên 雪山狼, thanh máu ngắn, số bay, chữ 亢龙有悔 (`--skill 358 --auto-strike`, log `Đòn: skill 358 bước 0 là g01_gb_大鹏展翅`, 4 khối con). Khung mục tiêu (`TargetFrame`) hiện khi đang chọn mục tiêu: tên, cấp theo chênh với mình, thanh máu. Không có mục tiêu thì giấu. Chưa có khí, nộ, môn phái, loại NPC và chân dung. Vòng chọn dưới chân lấy `ring_size` (centimét) của mẫu, tô đỏ với quái, lục với NPC, lam với trân thú, vàng với người chơi; ảnh vòng là material cộng sáng có sẵn vì không có mesh chọn riêng. Cửa sổ Relive hiện khi chết: hồi thành và hồi tại chỗ, cùng phím 1 và 2. Không có hồn xuất khiếu, cờ hồi sinh hay đếm giờ. Khi chết phím 1 hồi sinh ở thành và phím 2 tại chỗ; lời nhắc hồi sinh là chữ Hán vẽ bằng phông giao diện giữa màn.
    (c) Số bay dùng phông bitmap GBK12 phóng 2 lần (3 lần khi hội tâm), không phải ảnh số của client 2026; màu, độ cao và nhịp bay chọn theo mắt, chưa port từ mã máy.
    (d) Lời từ chối của máy chủ (`Declined`) chỉ chỉnh logic đánh tự động (hồi chiêu, quá tầm, chưa học...), không có dòng thông báo cho người chơi.
    (e) `SelfBag` đổ vào thẻ đạo cụ (tab 0) của `Packet` theo chỉ số ô; ảnh lấy từ `Table/icons.tsv`; số chồng ghi `CornerBotRight`. Dây không có loại túi và sức chứa, nên thẻ vật liệu và nhiệm vụ để trống và sức chứa giữ mặc định script 20/60 (mục 51(f) vẫn đúng). Vật rơi chọn được khi có cờ nhặt (bit 1 của `EntityFlags`), chưa có tên theo template, chưa có con trỏ riêng khi rê chuột.
    (f) Quái, NPC và trân thú chết thì nằm lại: clip `death` (sói 11158 là `倒地`) phát một lần rồi giữ khung cuối; có `corpse` thì lặp clip đó. Xác đã chết từ trước khi vào tầm nhìn nằm sẵn, không diễn lại cú ngã. Mẫu không có clip chết vẫn hiện, ở tư thế đứng. Người chơi chết chưa có động tác: `CharActionSet` có `倒地` (id 24) và `死亡` (id 25) nhưng `anim_sets.tsv` không xuất hai dòng đó, nên người chơi khác bị giấu và nhân vật mình giữ clip đứng.
    (g) Tầm tiếp cận chung 2,5 m (`fight::kReach`) cho mọi chiêu, thu ngắn mỗi lần máy chủ báo quá tầm; chiêu tầm xa vẫn đi tới 2,5 m rồi mới đánh. Máy chủ mới là nơi kiểm tầm từng chiêu.
    (h) Ô kỹ năng k là kỹ năng học thứ k của `SelfSkills` (ô 10 là phím 0). `show_fight` nạp lại clip khi danh sách đổi. Chưa có thanh action kéo thả của client 2026 (bố cục do người chơi xếp, máy chủ nhớ).
    (i) Cổng `check.py`/clang-tidy: phần của lát cắt sạch (đo bằng clang-tidy với `--header-filter` rỗng cho từng tệp, `check.py --run` cho `fight_tests`). Cả nhóm `display/graphic` vẫn không qua `check.py` nguyên tệp vì lỗi có sẵn ở HEAD: `misc-include-cleaner` hàng loạt (các tệp dựa vào `prelude.hpp`), `State` đệm 125 byte, `sky_mesh.hpp`/`water_mesh.hpp` khởi tạo không chỉ định tên.

59. **Treo đơ trên điện thoại, màn đăng nhập (2026-10-16): các chỗ chưa kết luận được** (`engine/render/forward.cpp`, `engine/resource/lod.cpp`, `engine/render/detail_governor.hpp`).
    (a) Chưa đạt 30 Hz trên TB-X306F (23,5 fps, ~42 ms/khung): còn ~300 lệnh vẽ mỗi lệnh tốn 50–80 µs ở driver GLES. Cần gộp lệnh vẽ giữa các mesh; chưa làm.
    (b) Số đo có nhiễu: DVFS của MT8768 đổi xung CPU 0,9–2,3 GHz theo tải GPU, pin 24% cắm USB. Cần đo lại với pin đầy hoặc khoá xung để kết luận mức cải thiện chính xác.
    (c) iOS chưa build và chưa chạy (không có macOS); đường MoltenVK dùng chung mã nhưng hành vi TBDR của GPU Apple chưa đo, `discard` ở shader khác (cây, hiệu ứng) vẫn có thể tắt HSR ở đó.
    (d) `kPhoneTriangleCap` 300k và các hệ số của `DetailGovernor` chọn theo một máy; máy mạnh hơn nâng trần tự động, máy yếu hơn bị kẹp ở sàn 120k mà vẫn có thể chậm.
    (e) LOD chỉ cho lưới tĩnh (không skin, không morph): nhân vật và quái skin vẫn vẽ đủ tam giác.
    (f) `lod_tests` chưa chạy dưới sanitizer (`check.py --run`); chỉ chạy bản `msvc-release`.

60. **Bản tiếng Việt 2026-10-16: chỗ cần chủ dự án hoặc chưa có dữ liệu** (`assets/i18n`, `zone.toml`).
    (a) 坐骑: glossary là "thú cưỡi", bản dịch bảng dùng "Toạ Kỵ" khoảng 4.000 ô. Chưa gộp.
    (b) Tên trang bị dạng `之` còn hai kiểu ("X Chi Y" và "Y X"). Chưa sinh lại.
    (c) Phông: VTNAM14 phủ hết chữ Việt của `vi.tsv` và `dialogue.vi.txt` (test `vietnamese_letters_have_glyphs`). Chưa chọn phông vector OFL để thay `tahoma.ttf` thiếu trong gói; không đóng gói phông hệ thống.
    (d) 13 ảnh `#CHO_ANH` còn chữ Hán trên nút đăng nhập. Chưa vẽ thay.
    (e) Tên quái và NPC trên đầu lấy cột `name` của `creature_templates.tsv`. Không có `creature_templates.lang.tsv`. Đường nạp đã chờ tệp đó.
    (f) Lời chết trong `display/graphic/fight.cpp` (`您已经死亡`, `按 1 回城复活`) là chữ Hán cứng. Phiên khác đang sửa thư mục đó nên chưa đổi.
    (g) Sáu bảng thông báo `.vi.tsv` chưa được zone nạp; chỉ `dialogue.<language>.txt` đi theo `[text] language`.

61. **Màn đăng nhập: sương thung lũng, thác nước, cây gió, độ nét so với ảnh gốc** (chủ dự án gửi ảnh gốc 2026-10-16).
    (a) Sương thung lũng của ảnh gốc dày và sáng hơn (trắng xanh quanh x 330-760, y 330-460 của ảnh 1252x719), bản này
    chỉ nhạt. Nguồn nghi: hệ billboard `方向雾_深灰` (300 hạt, 400-800 đơn vị, chỉ 2 trên 7 chỗ đặt nằm trong khung),
    `远景雾片_3`, hay sương cao độ (`EnvKey height_fog_param`). Cần: so từng nguồn bằng cách tắt riêng.
    (b) Thác nước: chủ dự án báo thác đứng im ở màn chọn nhân vật và thiếu thác bên trái. Nguyên nhân tìm được và đã
    sửa: `decode_model` (đường đọc cache `.tlms`) không gán `emissive` từ `scroll_anim`, nên mesh nào đã có cache thì
    thác đứng im (test `cached_load_keeps_scroll`, `shipped_waterfall_scrolls`). Chưa chứng minh bằng mắt: ảnh `--shot`
    luôn lấy khung đầu nên không thấy chuyển động, và chưa rõ "thác bên trái" của ảnh gốc là mesh nào (cảnh có thác ở
    x 245 và x 645 trên ảnh 1280x720). Cần chủ dự án xem lại bản dựng mới.
    (c) Gió lung lay cây: chưa làm. Cần đọc cách bản gốc rung đỉnh (shader cây) trước khi viết.
    (d) Độ nét: bản gốc có chuỗi hậu xử lý (`hdr.hlsl`, `Bloom.hlsl`, `ColorLUT.hlsl`, `AntiAlias.hlsl`) mà client chưa có;
    lọc dị hướng 16x và MSAA 4x đã bật, cỡ texture khớp bản gốc (đo 14 tệp). Chưa chứng minh nguyên nhân.

62. **`TOOLS/bake/bake.py` treo khi chạy không người gõ trên Windows** (2026-10-16). Không đặt `BAKE_PASSPHRASE` mà
    chạy `new-key` với stdin là `NUL`: `_tty()` (`sys.stdin.isatty()`) trả True cho `NUL`, rồi `getpass` đọc thẳng
    bàn phím console nên chờ mãi. Trên Windows không đặt được biến môi trường rỗng (gán rỗng là xoá), nên không có cách
    nào chạy `new-key` không cụm mật khẩu ở chế độ tự động. Cần: `_tty()` kiểm console thật (`GetConsoleMode`) thay vì
    `isatty`; hiện chỉ gặp khi tự động hoá, người dùng gõ tay hay dùng cửa sổ không bị. Chưa sửa.

63. **Tablet 60 Hz, địa hình theo đỉnh và điều tốc** (2026-10-17, TB-X306F, Đại Lý). Số đo ở `docs/TIEN-DO.md`.
    (a) Bộ nhớ: mỗi ô 4 đỉnh riêng × 96 byte. Đại Lý 320² là 409.600 đỉnh (~39 MB, hơn bản đỉnh dùng chung ~29 MB);
    Lạc Dương 512² sẽ cỡ 100 MB, mà `kKeptGrounds` = 4 giữ bốn mặt đất trên GPU. Đo gộp đỉnh trùng chỉ bớt 21%.
    APK hiện chỉ gói Login và Đại Lý nên chưa vượt. Cần: định dạng đỉnh gọn riêng cho địa hình (cỡ 32 byte) trước
    khi gói Lạc Dương lên máy 2 GB.
    (b) Ô xoay 8–15 (góc lặp) nay affine từng tam giác như bản gốc; PS cũ song tuyến. Chưa so ảnh với client gốc
    riêng ở các ô ấy.
    (c) `terrain.ps.glsl` (GLES) sửa theo cùng công thức nhưng chưa biên dịch hay chạy; GLES đã ngừng phát triển.
    (d) "Chỉ vẽ vùng thay đổi" chưa làm. Chưa đo bao nhiêu phần khung thật sự đổi (camera, hạt, nước), nên chưa biết có đáng.
    (e) `kHeadroom` 1,5, `kSettle` 90, `kStartSettle` 240 đo trên một máy. Cập nhật 2026-10-17 tối: hai nguyên
    nhân đã đo được: luồng vẽ bị dời sang cụm cpu4–7 (nay ghim ở lõi mạnh, `core/cores.cpp`) và điều tốc đếm khoảng
    vòng lặp mà hàng chờ Fifo che (nay đếm nhịp màn thật, `core/cadence.hpp`). Ba hằng số chưa đo lại sau hai sửa
    ấy; có thể `kSettle`/`kStartSettle` không còn cần lớn như thế. Cần: lượt đo lên-xuống mức có SurfaceFlinger.
    (f) Sau ~25 giây chạy việc thật mỗi khung tăng 11,9 → 15,8 ms (khung đúng nhịp 99,0% → 96,7%), cả khi không
    điều tốc. Nghi nhiệt. Ghi lệnh chiếm 8,4 ms mỗi khung nên bớt công ghi lệnh là cách tăng độ dư. Cập nhật
    2026-10-17 tối: có ghim lõi, các lượt 30 giây đứng yên giữ 59,87 FPS ở mọi cửa sổ sau nạp, không thấy trôi;
    chưa chạy lượt dài (5–10 phút) để loại hẳn nhiệt.
    (g) Nạp cảnh Đại Lý vẫn 8,7–10,4 giây: mỗi lần nộp lệnh chép ảnh chặn cỡ 25 ms (~70 lần). Chưa biết chặn
    trong `vkQueueSubmit` hay ở chỗ khác. Phương án: nộp chung danh sách lệnh chép với danh sách lệnh của khung.
    (h) Cắt hiệu ứng theo khung nhìn (`fx::grain_sphere`) mới đo trên PC (CPU chặng hiệu ứng 0,55 xuống 0,15 ms, quad
    3852 xuống ~500); trên tablet chưa có số sạch vì lượt đo bị chạm tay và nhân vật tự đi. Cần: một lượt đo khi
    không ai cầm máy, nhân vật đứng yên, so "Ghi lệnh" và FPS có điều tốc trước và sau. Cầu bao theo tâm hạt nên một
    hạt bay xa làm cả hệ khó bị cắt (không sai hình, chỉ mất lợi). Phần `Cast::update` (11,2% luồng vẽ) và
    `Hub::hit` gọi hai lần mỗi khung (5,4%) chưa đụng: dừng cập nhật hệ ngoài khung đổi hình khi quay lại, còn
    nhớ kết quả `hit` cần biết dấu nào phủ việc ẩn hiện.
    (i) Lượt đo trên tablet dễ nhiễu: cảm ứng nhận chạm ngoài ý muốn thì nhân vật đi theo, và đo xen kẽ nhiều lượt
    làm máy nóng dần. Cần: đo ở chế độ máy đứng yên (ghi toạ độ HUD vào log, bỏ lượt lệch) và nghỉ giữa các lượt.
    (j) Đi bộ trên tablet: mỗi lần toạ độ nguyên của người chơi đổi, `minimap.cpp` `fill_place` đổi một override chữ
    và `gui::Hub::update` (`forced_same` sai) gọi `relayout` dựng lại cả layout, ~35–40 ms trên A53 (simpleperf:
    `HubOps::relayout` 76% của `Hub::update`, phần lớn là `parse_uvector`/`from_chars`). Đây là đỉnh "dựng UI"
    39,6 ms của các khung lặp khi đi. Phương án: layout chỉ phụ thuộc override có tên thuộc `kRules`/`apply_flag`
    (`layout.cpp`); chữ được đọc lại lúc vẽ qua `effective()`, nên override chỉ đổi chữ thì cần vẽ lại, không cần
    relayout. Chưa sửa vì `hub.cpp` đang có thay đổi chưa commit của phiên khác. Thêm: phân tích số trong chuỗi
    layout một lần lúc nạp thay vì mỗi lần relayout.
    (k) `FifoCadence` dựa vào giả định "acquire chờ từ 2 ms là lúc màn thay ảnh". Mới đối chiếu trên TB-X306F
    (Android 10, PowerVR, WSI kết nối kiểu EGL, ba ảnh). iOS (MoltenVK, `nextDrawable`) chưa đối chiếu; PC không
    dùng mô hình. Máy khác có thể chờ ở `vkQueuePresentKHR` thay vì acquire; khi đó không có lần chờ nào, chu kỳ giữ
    số hệ điều hành báo và lưới dựa vào khung đầu. Cần: một lượt `--latency` trên máy thứ hai và trên iOS.
    (l) Mấy giây đầu sau nạp vẫn lặp ảnh thật (SurfaceFlinger cửa sổ đầu 7–21% vượt, chậm nhất 67–167 ms):
    `pump_load` và GPU còn bận đưa mesh cuối. Liên quan (g).

64. **Shader HLSL của client gốc chuyển qua Slang** (2026-10-18; `src/client/render/shaders/origin`,
    `TOOLS/port/hlsl_origin.py`, nhật ký ở `docs/TIEN-DO.md`). Oracle fxc chứng minh bản đã chuyển ra
    cùng mã máy fxc với bản gốc (289/289). Nó không chứng minh mã Slang sinh ra (SPIR-V, DXIL) cho
    cùng điểm ảnh.
    (a) Chưa nạp gói nào vào lượt vẽ, chưa so ảnh với client gốc. Cần: nối một vật liệu (ví dụ
    Character_Skin_PS) vào lượt vẽ, chụp cùng cảnh ở client gốc và ở đây, so từng điểm ảnh.
    (b) Ở `locations semantic`, DXIL giữ đầu vào khai mà không dùng còn SPIR-V bỏ. Bố cục vào của D3D11
    và D3D12 với các đầu vào thừa ấy chưa chạy qua lớp kiểm tra. Cần: dựng PSO D3D12 cho một gói có
    đầu vào thừa, bật lớp kiểm tra.
    (c) 194/376 nội dung `ShaderCache` gốc là biến thể define do Render.dll tạo lúc chạy, không khai
    trong `.program` (Bloom, GodRays, EnScene, AntiAlias, và chừng 94 chương trình của
    `Material/all.material` chưa đối chiếu). Cần: tìm define của từng biến thể trong mã máy, ghi vào
    `code_programs.tsv`, chạy oracle với `--cache`.
    (d) Ma trận: 195 chương trình gói theo hàng (`matrix=row`), và `ParamNamedAuto.inc` khai riêng
    `row_major` cho `shadow_csm_proj_scale`, `shadow_csm_proj_offset`. Lúc nối tham số tự động, bộ ghi
    cbuffer phải theo đúng layout từng biến (phản chiếu đã báo rows, columns, size đúng). Chưa có mã
    ghi nào.
    (e) Ở chế độ semantic, phép đối chiếu ghép đầu vào DXIL với SPIR-V theo location. Nếu Slang dời
    location (xem TIEN-DO cùng ngày) trùng đúng location của một đầu vào thừa cùng kiểu, semantic sẽ
    ghép sai mà không báo lỗi. Bộ sinh ghim gốc location cho tham số struct và từ chối struct trả về
    cùng biến ra rời, nên với 289 chương trình hiện có không còn nguồn dời nào đã biết. Engine không tự
    phát hiện được ca này.
    (f) Khi dựng DXBC, fxc báo X3571 (`pow` với cơ số có thể âm) ở 7 chỗ: CalcLight.inc, Model_2Tex_ps,
    Model_Face_ps, Model_Flow_ps, Model_ps (hai chỗ), WaveGrass. Nó cũng báo X3550 (chỉ số mảng
    sampler trong vòng lặp, buộc unroll) ở SkySphereLayer. D3DCompiler_43 báo đúng các chỗ ấy khi
    dịch bản gốc chưa chuyển, nên đây là hành vi của game gốc (cơ số âm cho NaN). Bộ chuyển giữ
    nguyên vì thêm `abs` sẽ đổi mã máy. Cần: chủ dự án quyết định có sửa như bug của bản gốc không.

65. **Thú cưỡi và hiệu ứng thú 2026-10-18: các chỗ chưa làm hoặc chưa kết luận** (`engine/render/forward.cpp`,
    `src/client/render/shaders/model.ps.slang`, `src/client/place/fx/`, `display/player.cpp`; nhật ký ở `docs/TIEN-DO.md`).
    (a) Hạt mesh trộn `src_alpha one` (28 hệ), `one one_minus_src_colour` (17), `zero one_minus_src_colour` (2)
    vẫn bị bỏ: Forward chỉ có pipeline trộn alpha và cộng one/one. Cần: Pso model và kiểu trộn mới cho chất liệu.
    (b) Chưa làm: hiệu ứng con (`ParEffectName`, 2 hiệu ứng), PointLight (2), energy wave (3), RotationCurve (1 hệ),
    MeshAnimationAffector, `play_mode` của SequenceFrame (3), `accurate_facing` (90 hệ), `force_application
    average` (10), `rotate` của texture (2), `colour_range_end`.
    (c) Màu vệt NewRibbonTrail đã theo mã máy (REA 2026-10-18): Render.dll `0x180158970` lấy mốc đầu tiên có
    time > tuổi, quá năm mốc thì mốc 4 (Black của ctor `0x18022e870`), rồi `0x180158fa0` saturate. Còn lệch ở vòng
    cập nhật `0x180158fa0`: alpha <= ngưỡng, độ rộng ngoài khoảng cắt hay tuổi quá LiftTime thì cắt đuôi vệt tại
    điểm ấy khi LiftTime >= 0, làm trong suốt điểm khi LiftTime < 0; độ rộng cộng dồn theo dt và kẹp >= 0; điểm
    vệt sinh theo `Fairy::RibbonTrail` (addNode `0x1801593a0`). Ở đây chỉ làm trong suốt điểm và giữ cách nối
    điểm cũ. Cần: đọc doSet của các ParamCommand (`0x1803c06a8`...) để khớp tên tham số với offset 0x260–0x278
    trước khi port vòng này.
    (d) Màu trên PC: luồng sáng cộng trong gamma rồi đổi tuyến tính như phần còn lại của `model.ps`; hạt fx còn
    lệch gốc (mục 29). Cường độ luồng sáng chưa so ảnh với client gốc.
    (e) Người cưỡi không thấy trên sư tử 385, 387 trong ảnh chụp (camera nhìn mặt trước, bờm che); ngựa 212 thấy.
    `add_height`, tỉ lệ mẫu và `camera_y` của `rides.tsv` chưa áp. Cần: chụp nghiêng hoặc đối chiếu toạ độ ghế
    với client gốc.
    (f) GLES: `model.ps.glsl` không có luồng sáng, viền; cảnh GLES có mảng đen quanh cánh sư tử, có cả ở bản trước
    đợt này. GLES đã ngừng phát triển nên chưa soát.
    (g) APK mang `Material/programs.tsv` (`WHOLE_FILES` của `package_apk.py`); ảnh ctl, luồng, viền chỉ có trong
    gói khi lượt trace mở chúng. Thiếu ảnh thì phép ấy tắt, như ảnh đen của D3D9.
    (h) `avatar/locator.cpp` dời offset của điểm neo mà không nhân derived scale của xương (Render.dll có nhân).
    Lệch chỉ khi xương có tỉ lệ khác 1.
    (i) Ellipsoid nhánh rỗng: khi thể tích rút ra ngoài mọi đoạn, mã gốc không ghi vị trí (hạt giữ vị trí đời trước);
    ở đây hạt đứng ở tâm emitter. Chưa có hệ thú nào rơi vào nhánh này.
    (j) Đã kết luận (REA 2026-10-18): `BillboardSet::genVertices` gói màu qua `ColourValue::getAsABGR_SSE`
    (OgreMain `0x18005ff70`: nhân 255, CVTPS2DQ, PACKUSWB), bão hoà về [0, 255]; log Fairy của client gốc trên máy
    này báo SSE, MMX, MMXEXT có nên chạy nhánh này. 11 hiệu ứng có độ mờ ColourFading lớn hơn 1 nay kẹp alpha
    ở `fx_view.cpp`. Khác gốc còn lại: không lượng tử về 8 bit.

66. **Đăng nhập: máy chủ gốc gửi `LCRetLogin` 0x15, 0x17, 0x18 trong điều kiện nào** (2026-10-18, G1-K; handler
    `docs/TAILIEU/ghidra/login_packets.txt:1125-1190`). 0x15 đẩy sự kiện `0x1f5` OPEN_AGREEMENT_DLG (cửa sổ
    Agreement); 0x17 là hàng chờ (`LOGIN_MUST_WAIT`, cửa sổ LoginTimer, chữ `DLYH_180224_01` kèm số giây); 0x18
    đẩy `0x20c` OPEN_FANGCHENGMI_DLG (FangChenMi) khi cờ `DAT_140fb73b8` khác 2. Máy chủ 2008 chỉ có năm mã
    `LOGINR_*` 0 đến 4 (`Common/ResultDefine.h:118-122`), nên ba mã này là phần của máy chủ 2026 mà ta chưa có luật
    hay gói tương ứng. Hiện tại ta không làm Agreement, FangChenMi, LoginTimer. Cần: gói hay luật máy chủ gốc nói
    điều kiện gửi; khi có thì M thêm kết quả đăng nhập và K mở cửa sổ. Tương tự `LOGIN_MIBAO` (`0x1c1`, Pswprotect):
    chưa tìm thấy nơi đẩy trong `login_packets.txt`.

67. **Menu NPC ẩn mục dẫn tới nhiệm vụ không chạy được** (2026-10-18, N1; `talk/detail/runner.cpp` hàm `offerable`, ca
    `newbie_npc_menu_has_no_dead_option`). Trước đây menu dựng từ bảng thoại 2008 mời cả mục dẫn tới nhiệm vụ mà client
    2026 không có (440 第一把武器, 718 十年 bản 2008) hay chưa chạy được; chọn chúng ra `kNoDialog`, `play` đổi thành Reject
    21 (14 và 6a đo ở 赵天师: chọn 1 và 2 hỏng, chọn 3 ổn). Nay bước `option` có script là một nhiệm vụ không `runnable()` thì
    bị bỏ khỏi menu. Số bước `option` bị bỏ trên bảng sinh 2026-10-18: 847 trỏ nhiệm vụ ngoài danh bạ client và chưa hỗ
    trợ (nội dung 2008, không có bằng chứng 2026, bỏ đúng), 72 trỏ nhiệm vụ `ok` nhưng ngoài danh bạ (bỏ đúng), và 137 trỏ
    59 script nhiệm vụ CÓ trong danh bạ client 2026 mà bộ trích chưa chạy được. Nhóm 137/59 là lỗ của ta, không phải nội dung
    2008: lý do theo họ là 13 `OnAccept: phép tính * trên giá trị không phải hằng` (212119–212133 vùng Thảo Nguyên, anh hùng
    250–255), 12 `CheckSubmit: id vật phẩm không phải số nguyên hằng` (sư môn 229000–229014 và 546), 6 `OnAccept không AddMission
    đúng nhiệm vụ` (713–716 ngự tứ, 949), 5 `API GetMonsterCount`, 6 API phụ bản (`LuaFnGet/SetCopySceneData_Param`, thuộc
    N4), còn lại lẻ. Cần: N2 (chuỗi nhiệm vụ theo cấp) và N3 (sư môn) viết bộ chạy hay bộ trích cho từng nhóm; khi một script
    chạy được thì mục tự trở lại menu, không phải sửa chỗ khác. Lấy danh sách: bước `option` của `talk_blocks.tsv` có cột
    `a` là script nhiệm vụ mà `mission_quests.tsv` ghi `in_client=1` và `status` khác `ok`.

68. **Lựa chọn trỏ tới điểm vào hội thoại chưa trích được vẫn hiện, chọn ra Reject 21** (2026-10-18, N1). Bộ lọc mục 67 chỉ
    xét nhiệm vụ. Mục menu của NPC trỏ tới hàm sự kiện (cửa hàng, dịch chuyển, luyện nghề...) mà `talk_entries.tsv` ghi
    `unsupported` hay `no_dialog` vẫn hiện, chọn ra `kNoDialog`. `talk_data_tests` (ca `every_npc_script_walks`, 1 727 script
    NPC, ba mức cấp) in `chọn: không có hội thoại` 1 548 trên 3 394 lượt chọn sau bộ lọc. Chưa ẩn vì mục cửa hàng và dịch
    chuyển là việc của G6 và N-sau: ẩn chúng làm người chơi tưởng NPC không có chức năng. Cần: mỗi gói sở hữu chức năng
    làm bộ chạy; riêng mã lỗi: `gameplay.cpp:166` ép `kNoDialog` thành `kNoSuchEntity` (21), nên client hiện câu "mục tiêu không
    tồn tại" cho một mục chỉ là chưa làm; đổi sang mã riêng khi `gameplay.cpp` được mở (6a). Kiểm 赵天师 cấp 1 thì 0 mục
    chết (`[赵天师] 1 mục, 0 mục chết`).

69. **Chuỗi tân thủ: bước chặn và gói chặn** (2026-10-18, N1; `NHIEM-VU-NGUON.md` mục 5 và 9). Đi hết trong G3: 1400–1408, 1413,
    1424. Chặn: 1414 và 1415 (cần sổ trân thú: data id 559 `飘飘兔` lên cấp 2, giữ 558 `飘飘鸭`; gói trân thú sau G9, HO-SO 5.10),
    1417 (dùng 七彩烟花 38000173 tại cảnh 2 (160,93); gói dùng vật phẩm G5), 1419 (năm câu đúng liên tiếp ở 钱龙, `equiz.lua`
    311100; N6), 1421 (nhập phái, môn phái khác 9; G7, và mở nó khoá 1422), 1423 (xem mục 70). Kéo theo 1412, 1416, 1418, 1420,
    1422 vì tiền đề của chúng nằm sau bước không nộp được. Khi một gói đạt, chạy lại ca `longest_chain_end_to_end` và kịch bản
    `n1-tanthu.script` kéo dài tới bước đó.

70. **1423 何谓行善: ba vật phẩm có định nghĩa, thiếu nguồn cấp** (2026-10-18, N1; kiểm lại theo yêu cầu của 6a). `items_common.tsv`
    (client 2026 `CommonItem.txt`) có đủ 40004514 小馒头, 40004515 衣服, 40004516 锄头 (loại 任务道具, mô tả "段延庆让你送给
    大理（250，271）小乞丐"). Cái thiếu là nguồn cấp: chuỗi `XSRW_100111_120` bảo lấy ba món trong 杂货车 tại (282,261), mà
    杂货车 không có trong bảng phát, spawn, điểm thu hoạch hay script nào (mesh trong `dali_new_320.Scene` là vật tĩnh; mẫu quái
    629 và 636 tên 杂货车 không được thả ở Đại Lý). Ghi chú "không có trong bảng nào" ở `NHIEM-VU-NGUON.md` mục 9 chỉ đúng với
    nguồn cấp, không đúng với định nghĩa vật phẩm. Không phát ba món lúc nhận nhiệm vụ để cho qua. Cần: cơ chế vật cảnh tương tác
    cho ra vật phẩm (gói thu hoạch/vật cảnh) hoặc bằng chứng gốc về nơi 杂货车 phát đồ.

71. **Chữ hộp thoại có `}` thừa trước đợt này** (2026-10-18, N1; đã sửa). `lua_emit.py:65` thoát `{`→`{{` và `}`→`}}` trong bảng
    thoại (28 mẫu có `#{{OBJ_...}}`), còn `play/text.cpp` `render` chỉ thay `{n}` nên gửi nguyên `#{{OBJ_dali_0011}}`; client đọc
    khoá lạ và để lại một `}` (`e2ek0t2兄弟}`, ảnh `g0-talk.png` của 14). Nay `render` đổi `{{`→`{` và `}}`→`}`, ca
    `render_unescapes_braces` trong `play_tests`. Còn lại, chưa kiểm: dòng đầu bắt đầu bằng `!` trong cùng ảnh. Cần: chụp lại sau
    khi dựng cụm với bản mới, đọc bằng mắt; nếu `!` vẫn có thì tra `dialogue.zh.txt` mẫu của 赵天师 xem `!` nằm trong chữ gốc
    hay do client thêm.

72. **Điểm sinh nhân vật mới: số gốc là vật cản, cảnh 71 và 72 chưa có lưới để đo** (2026-10-18, G1-M D4; `account/starter.hpp`
    `kPositionZ`, `rules/new_character.toml`, `TOOLS/server/import_rules.py` bảng `DEVIATIONS`). `DefaultChar.ini` (bản 2008
    và XJL7457) ghi (165; 169) ở cảnh 2. Trên lưới đi `.path` 2026 của Đại Lý đó là một tam giác VẬT CẢN, nên nhân vật mới bị
    kéo về hay không tới được 赵天师 (160; 159). Đã đổi cảnh 2 thành (165,00; 169,71): điểm đi được gần nhất, liền với 赵天师,
    cách mọi cạnh ràng buộc ít nhất 20 cm (đúng độ lệch `kWalkSlackCm` của zone). Bot mới của cả sáu kịch bản G0 vào ở
    16500; 16971 và không bị kéo về (pair, peers, walker 0 lần, trước đây 59 và 30). Chưa biết: bản gốc 2026 sinh nhân vật ở
    toạ độ nào (`Config/startup.id` chỉ có cảnh 2; `ScenePosDefineEx.txt` nhị phân chưa mở; log client gốc không có dòng vào
    cảnh). `[start_position]` còn hai cảnh 71 và 72, nhưng `dev/server/scenes/` chưa có lưới của chúng nên giữ 169,0; mã chưa
    đọc danh sách này (`starter.hpp` chỉ dùng `kScene` = 2). Cần: lưới đi của cảnh 71 và 72 hoặc bằng chứng gốc về chỗ sinh,
    rồi đo lại bằng đúng quy tắc 20 cm. `import_rules.py` giữ giá trị đổi qua mọi lượt nhập lại (không chép số gốc về
    `starter.hpp`).

73. **Danh sách nhân vật 2026: các trường gốc chưa có trên dây** (2026-10-18, G1-M D3; `docs/giao-viec/HOAN-THIEN/G1-M.md`,
    `src/shared/protocol/catalog/fields.tsv`). Bản ghi gốc 0x1a4 byte có trường mà catalog v9 KHÔNG mang vì ta không có dữ
    liệu hay chưa có chứng cứ: `delete_days` (0x128, luôn 0 vì xoá ngay), `pk_level` (0x1a0, luôn 0 tới khi có PvP),
    `equip[19]` (u16 ở 0xa0..0xc5, rỗng tới G5; tạm thay bằng `equip_set` của bộ đồ tân thủ), `hair_color` (0x30: màn tạo
    2026 không có ô chọn, đổi màu tóc là chức năng trong game sau này), màu mặt/dye và hai mẫu u16 (0x190, 0x194, 0x18a,
    0x18c; để khi G5 có trang bị), trường 0x50 (setter 0x1401738c0 ghi +0x968 rồi gọi hàm ảo 0x7e0, chưa gọi được tên), thú
    cưng (0x130, 0x134), `sale_state` (mảng toàn cục theo ô, ngoài bản ghi), `camp` (không thấy ở CharSel hay Lua). Client
    đặt cứng 0 cho những cái cần hiển thị. Chưa kiểm: người mẫu màn chọn mặc đúng bộ đồ tân thủ đã chọn (K dựng). Cần:
    khi G5 có trang bị thì thêm `equip[19]`, khi có PvP thì thêm `pk_level`, rồi nâng phiên bản giao thức. Chưa có khoá
    `store.toml` cho danh sách ảnh chân dung và bộ đồ tân thủ (tập đóng trong `account/rules.cpp`, khớp `portraits.tsv`
    choice 1 hay 3 và `newbie_outfits.tsv`); client đổi bảng thì phải sửa mã.

74. **Kiểm đoạn đi của zone (B19): mẫu 20 cm, chưa chạy trên cảnh `legacy_nav` và chưa đo với client giật khung** (2026-10-18,
    B19; `src/server/zone/scene.cpp` `Scene::blocked`, `kStepSampleCm`; `docs/giao-viec/HOAN-THIEN/H1-M.md`).
    `Scene::blocked` lấy mẫu dọc đoạn đi, cách nhau 20 cm (bằng độ lệch `kWalkSlackCm` của luật đi) bằng chính hàm
    `walkable`, thay cho việc chỉ tra điểm đến; bước dài xuyên tường mỏng không còn lọt. Chưa chắc: (1) E2E `--leap` mới
    chạy trên Đại Lý (lưới `.path`), chưa trên cảnh `legacy_nav` (lưới ô); (2) client giật khung vài trăm ms phát một Move
    dài quanh góc lồi có thể cắt qua mép tường và bị hoàn bước (chỉ kéo về, không phạt); (3) gốc 2008 không có bản tương
    ứng vì máy chủ tự đi đường qua FindPath (`AI_Character.cpp:152-201`), nên ghi `// Khác gốc:` ở `Scene::blocked`;
    (4) lần chạy `--leap` đầu tiên ngay sau khi cài exe mới và khởi động cụm bị EnterGame từ chối mã 16 (`kBusy`: gate
    chưa nối zone, `gate/table.cpp:1282`), 6/6 lần sau vào được, kể cả bot chạy 2 s sau khi start: chưa tái hiện, chưa rõ
    nguyên nhân (nghi lần chạy đầu của exe mới chậm vì quét tệp), không do B19 (gate là HEAD).
    Cần: một lượt đi sát tường bằng client thật ở cả hai loại cảnh, đếm Position kéo về; và bắt được lần `kBusy`
    đầu (dừng cụm, cài exe mới, chạy bot ngay) để biết gate nối zone mất bao lâu.

75. **Tin máy chủ lớn hơn một bản ghi mật (4104 byte): chưa có tin thật nào vượt, gate vẫn bỏ lặng khi vượt** (2026-10-18,
    điều phối giao đo; `src/server/gate/table.cpp` `queue_down`, `note_oversize`; `docs/PROTOCOL-TIN.md` cột "Thân tối đa").
    Đo: cột "Thân tối đa" của catalog (cận trên lý thuyết) cho thấy chỉ hai tin server gửi vượt 4096 byte thân:
    `DialogOpen` 29 473 và `UiCommand` 4 188; mọi tin khác không quá 3000 (CharacterList 579, QuestBook 1 334, SceneEnter 16).
    Cỡ thật của `DialogOpen`: `dialogue.zh.txt` (1 183 nhóm: script NPC và nhiệm vụ; đo bằng một
    đoạn Python tạm cộng chữ từng nhóm kèm 4 byte tiền tố mỗi dòng) có nhóm lớn nhất 1 686 byte (`obj/dali/odali_zhengyi.lua`,
    58 dòng gồm cả lựa chọn), dòng dài nhất 408 byte, không nhóm nào quá 4 000. Cộng tối đa 16 dòng dấu nhiệm vụ,
    bonus và số lựa chọn thì ước chừng dưới 3 500 byte: còn dưới trần, nhưng cận trên này chưa dựng bằng cách mã hoá từng hộp
    thoại thật. `UiCommand` mang chuỗi ngắn (tên lệnh, id) nên thực tế vài chục byte. Chưa chắc: một hộp thoại đủ lớn
    (bảng nhiệm vụ với nhiều phần thưởng và dòng dấu cùng lúc, hoặc bảng chữ của nhà phát hành ghi đè trong
    `config/text/dialogue.zh.txt` dài hơn) có vượt 4 096 hay không. Cần: một lượt dựng `DialogOpen` cho mọi NPC và mọi
    nhiệm vụ rồi mã hoá để lấy cỡ thật (hoặc đọc dòng log `gate: bỏ khung zone 0x8601 (n byte), lần k` khi E2E chạm
    một hộp quá lớn). Nếu có tin vượt: B1 cần đổi giao thức (`link.cpp` coi mỗi bản ghi là một khung, nên gate không chẻ
    khung ra nhiều bản ghi được nếu không có nhận biết ở client) hoặc cắt chữ ở nguồn; hai phương án gửi điều phối chọn.

76. **MisDesc: sáu biến `g_Parameter_*` của nhiệm vụ ngẫu nhiên chưa dựng, bộ đọc bỏ qua chúng** (2026-10-18, N1 bước 2;
    `src/client/book/quest/misdesc.cpp`, hàm xử lý gốc `Game.exe` 0x1401db7b0, 0x1401dba60, 0x1401dbc70, 0x1401dbe50,
    0x1401dc060, 0x1401dc240). `parse_misdesc` tìm tên bằng strstr như vòng 0x1402cdbc0, nên dòng `g_Parameter_*` không có
    hàm xử lý thì bị bỏ lặng, không báo lỗi. Đo trên `src/client/script/Config/event`: 26 khối MisDesc có dòng loại này,
    chỉ ba tên: `g_Parameter_Item_IDRandom` (16 khối), `g_Parameter_Kill_AllRandom` (15), `g_Parameter_Kill_CountRandom`
    (10); đều thuộc nhiệm vụ ngẫu nhiên (`shimen_*`, `event_shimen_*`, `city/ecity_loop0901`,
    `fuben/efuben_sijuezhuang_mission`). Nhiệm vụ tân thủ 1400–1424 không có dòng nào. Hậu quả: `MissionDef` của 26 nhiệm
    vụ này thiếu tham số ngẫu nhiên. Chưa chắc: bố cục bản ghi mỗi dòng và giới hạn của sáu hàm gốc (chưa đọc bằng REA).
    Cần: đọc sáu hàm bằng REA rồi dựng khi N3 (nhiệm vụ lặp) cần.
