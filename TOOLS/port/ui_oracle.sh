#!/bin/bash
# Chạy CHÍNH script gốc của một cửa sổ trên LuaPlus.dll (trọng tài TOOLS/port/lua_oracle.py) và ghi số vàng
# Test/golden/panel/<snake>_<kịch bản>.tsv. Chạy ở gốc cây làm việc chứa tệp này.
# Dùng:  bash TOOLS/port/ui_oracle.sh <CửaSổ> <snake> <kịch bản> [đối số thêm của lua_oracle.py...]
#   vd:  bash TOOLS/port/ui_oracle.sh MainMenuBar_4 main_menu_bar_4 chat --lib TOOLS/port/oracle/action_bar_api.lua
# - Script: src/client/script/Interface/<CửaSổ>/<CửaSổ>.lua; layout: <dữ liệu>/Interface/<CửaSổ>/<CửaSổ>.layout.xml
#   (dữ liệu client gitignore ở GAME_DATA, mặc định cây chính D:/THIENLONG/dev/client/assets).
# - Kịch bản: TOOLS/port/oracle/<snake>_<kịch bản>.lua; hàm game của riêng cửa sổ: TOOLS/port/oracle/<snake>_api.lua
#   (nạp tự động nếu có). Hàm dùng chung nhiều cửa sổ thì truyền thêm --lib.
# - LuaPlus.dll ở XTLBB_BIN64 (mặc định D:/XTLBB/Bin64).
set -eu
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
if [ "$#" -lt 3 ]; then
    echo "dùng: ui_oracle.sh <CửaSổ> <snake> <kịch bản> [đối số thêm]" >&2
    exit 2
fi
window="$1"
snake="$2"
scenario="$3"
shift 3
data="${GAME_DATA:-D:/THIENLONG/dev/client/assets}"
bin="${XTLBB_BIN64:-D:/XTLBB/Bin64}"
api="TOOLS/port/oracle/${snake}_api.lua"
own=()
if [ -f "$api" ]; then own=(--lib "$api"); fi
exec python -X utf8 -B TOOLS/port/lua_oracle.py "$bin" "src/client/script/Interface/$window/$window.lua" \
    "$data/Interface/$window/$window.layout.xml" "TOOLS/port/oracle/${snake}_${scenario}.lua" \
    "${OUT:-Test/golden/panel/${snake}_${scenario}.tsv}" "${own[@]}" "$@"
