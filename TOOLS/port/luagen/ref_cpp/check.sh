#!/bin/bash
# Cổng kiểm của mã sinh: check.py (GCC + Clang -Werror 84 cờ, clang-tidy 438 check) cho tệp C++ trong thư mục sinh.
# Dùng:  bash TOOLS/port/luagen/ref_cpp/check.sh <thư mục gốc của mã sinh: cha của luagen/> <tệp.cpp>...   (đối số thêm vào check.py)
# Khác ui_check.sh ở chỗ thêm -I<thư mục sinh> để `#include "luagen/units.hpp"` tìm được.
set -eu
root="$(cd "$(dirname "$0")/../../../.." && pwd)"
gen="$(cd "$1" && pwd -W)"
shift
cd "$root"
includes="-Iengine -Isrc/shared -Isrc/client/app -Isrc/client/figure -Isrc/client/place -Isrc/client/face -Isrc/client/book -Isrc/client/pack -I$gen"
export CPP23_G14="g++ $includes"
export CPP23_G15="g++ $includes"
export CPP23_C20="clang++ $includes"
export CPP23_TIDY_ARGS="$includes"
exec python -X utf8 "$HOME/.claude/cpp23/tools/check.py" "$@"
