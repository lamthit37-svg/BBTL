#!/bin/bash
# Chạy một test của ui/panel qua check.py --run: Clang (ASan + UBSan mở rộng + hardening STL MSVC) và GCC
# (debug mode của libstdc++), không clang-tidy (phần đó là TOOLS/port/ui_check.sh).
# Dùng:  bash TOOLS/port/ui_run_gate.sh Test/Ui/ui_<tên>_tests.cpp --with <nguồn.cpp> [--with ...]
# Đã nối sẵn các nguồn nền mà mọi test panel cần: engine/core/*.cpp (clock, error, log, log_sink, range,
# system, text, uarch, handle, thread), engine/io/file.cpp và platform_win32.cpp. Người gọi chỉ thêm nguồn
# của panel và của module nó dùng (vd src/client/face/ui/panel/main_menu_bar_3.cpp, widgets.cpp, deck.cpp).
# Thư viện hệ thống của lõi (synchronization, ntdll, shell32) phải đứng SAU tệp đối tượng khi GCC liên kết,
# nên GCC chạy qua một tệp .cmd tạm nối chúng vào cuối dòng lệnh; Clang nhận chúng ở đầu. Clang MSVC báo
# "linker input unused" khi chỉ biên dịch nên thêm -Wno-unused-command-line-argument.
# PATH: thư mục bin của WinLibs phải đứng trước mingw64 của Git, nếu không libstdc++-6.dll cũ của Git được
# nạp và exe GCC chết ngay với 0xC0000139 (docs/BAY-DA-BIET.md). Đặt WINLIBS_BIN nếu WinLibs ở chỗ khác.
set -eu
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
winlibs="${WINLIBS_BIN:-$HOME/AppData/Local/Microsoft/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/mingw64/bin}"
export PATH="$winlibs:$PATH"
wrapper_dir="$(mktemp -d)"
trap 'rm -rf "$wrapper_dir"' EXIT
printf '@g++ %%* -lsynchronization -lntdll -lshell32\r\n' > "$wrapper_dir/gxx.cmd"
gxx="$(cygpath -m "$wrapper_dir")/gxx.cmd"
includes="-Iengine -Isrc/shared -Isrc/client/app -Isrc/client/figure -Isrc/client/place -Isrc/client/face -Isrc/client/book -Isrc/client/pack -ITest -ITest/Ui"
defines='-DGAME_PANEL_GOLDEN=\"Test/golden/panel\" -DGAME_CLIENT_DATA=\"D:/THIENLONG/dev/client/assets\"'
export CPP23_G14="$gxx $includes $defines"
export CPP23_G15="$gxx $includes $defines"
export CPP23_C20="clang++ $includes $defines -lsynchronization -lntdll -lshell32 -Wno-unused-command-line-argument"
base=""
for name in clock error log log_sink range system text uarch handle thread; do
    base="$base --with engine/core/$name.cpp"
done
base="$base --with engine/io/file.cpp --with engine/io/platform_win32.cpp"
# shellcheck disable=SC2086
python -X utf8 "$HOME/.claude/cpp23/tools/check.py" --run --no-tidy $base "$@"
