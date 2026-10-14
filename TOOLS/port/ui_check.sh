#!/bin/bash
# Cổng kiểm của đợt UI-PORT: chạy check.py (GCC + Clang -Werror 84 cờ, clang-tidy 438 check) cho các tệp
# C++ của ui/panel và Test/Ui, ở gốc cây làm việc chứa tệp này (worktree nào chạy thì kiểm worktree đó).
# Dùng:  bash TOOLS/port/ui_check.sh <tệp.cpp|.hpp>...        (đối số thêm đi thẳng vào check.py)
# I-path khớp include_directories của CMake cho game_ui_panel và test (engine, src/shared, các thư mục
# src/client/{app,figure,place,face,book,pack}, Test, Test/Ui); phần clang-tidy của check.py chỉ đọc
# CPP23_TIDY_ARGS, không lấy từ CPP23_G14/C20, nên cả ba cùng một chuỗi (docs/BAY-DA-BIET.md).
# Hai macro của test: GAME_PANEL_GOLDEN (thư mục số vàng, tương đối) để ca đối chiếu số vàng không bị
# coi là mã không tới được, và GAME_CLIENT_DATA (dữ liệu client gitignore ở cây chính).
# Chạy test dưới sanitizer: TOOLS/port/ui_run_gate.sh.
set -eu
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
includes="-Iengine -Isrc/shared -Isrc/client/app -Isrc/client/figure -Isrc/client/place -Isrc/client/face -Isrc/client/book -Isrc/client/pack -ITest -ITest/Ui"
defines='-DGAME_PANEL_GOLDEN=\"Test/golden/panel\" -DGAME_CLIENT_DATA=\"D:/THIENLONG/dev/client/assets\"'
export CPP23_G14="g++ $includes $defines"
export CPP23_G15="g++ $includes $defines"
export CPP23_C20="clang++ $includes $defines"
export CPP23_TIDY_ARGS="$includes $defines"
exec python -X utf8 "$HOME/.claude/cpp23/tools/check.py" "$@"
