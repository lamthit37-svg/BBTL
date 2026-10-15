# ref_cpp — bộ phát C++ của LUA-GEN (mã tham khảo)

Hướng này **đã bỏ** ngày 2026-10-15 (chủ dự án chốt): script giao diện chạy bằng bytecode và máy thông dịch C++ trên
runtime `lua`, không sinh C++ từng script. Mã ở đây giữ lại làm tham khảo ("cái đã làm giữ lại vào mã ref"); không nối vào
CMake, không nằm trong đường dựng nào.

Giá trị còn lại: `emit.py` là bản **đúng thứ tự đánh giá** của lparser.c/lcode.c 5.0.1 mà ta có, viết ra từ số đo trên
LuaPlus.dll. Bộ biên dịch bytecode (`../compile.py`) phải đánh giá theo cùng thứ tự; ca nào nghi ngờ thì đối chiếu ở đây.

## Gồm gì

- `emit.py`: cây đã phân giải phạm vi (`../tree.py`) → C++ gọi `src/client/face/lua/vm.hpp`.
  - biến bị hàm con bắt là `Cell`, biến khác là `Value`; đọc muộn tại chỗ dùng, sao chép ở các điểm exp2nextreg
    (đối số, callee, phần của concat, mục danh sách, return, vế phải gán nhiều đích);
  - gán nhiều đích: tính đích và vế phải trước, ghi từ phải sang trái, `check_conflict`;
  - `OP_SELF` trước đối số; `a > b` là `less(b, a)`; `a .. b .. c` gộp một `concat` (kể cả `..` lồng trong ngoặc);
  - `new_table(số mục danh sách, số mục `Tên = v`)`, `set_list` xả theo lô 32;
  - for số: `index = sub(init, step)` rồi `for_next` mỗi vòng, biến vòng dùng chung một ô; `for ... in` có TFORPREP;
  - `continue` (LuaPlus): nhảy tới điều kiện/FORLOOP/TFORLOOP, **không** đóng upvalue — sau biến bị bắt thì bộ phát báo
    `EmitError` (kho thật không có ca này);
  - `if (failed(L)) return {};` sau mỗi thao tác có thể lỗi, `if (!tick(L)) return {};` ở đầu vòng;
  - xử lý theo số đo: chuỗi elseif dài phát dạng bộ chọn phẳng (MSVC C1061 ở 128 khối lồng), gập điều kiện hằng và bỏ mã
    chết, `x = x` bỏ, hai nhánh giống hệt chạy một lần, tên biến đánh số.
- `generate.py`: dịch cả `mass_units.units()` + `world.lua`, chia các đơn vị vào K tệp `tu_NNN.cpp` cố định và một sổ
  `units.cpp` (mảng `Chunk` hằng cho mỗi đơn vị). Chạy: `python -B TOOLS/port/luagen/ref_cpp/generate.py --out <thư mục>
  --layout-root <Interface>`.
- `test_emit.py`: 35 ca (literal, thứ tự đánh giá, gập hằng, chia tệp). `check.sh`: chạy `check.py` cho mã sinh.

## Trạng thái (trung thực)

- **Chưa đối soát lần nào**: `thienlong_lua_mass` chưa chạy trên mã sinh này, nên chưa biết nó khớp vết LuaPlus.dll bao nhiêu.
  Chỉ biết nó biên dịch được và test Python xanh.
- Sinh cả kho: 2 060 đơn vị, 24 943 chunk (21 chunk lỗi cú pháp như DLL), 77 330 hàm, 16 giây.
- GCC + Clang `-Werror` (84 cờ) sạch 49/49 tệp ở một bản phát (trước ba chỉnh cuối: escape bát phân, tên biến đánh số,
  nhánh giống hệt). clang-tidy toàn kho bắt ba dạng (modernize-raw-string-literal, readability-suspicious-call-argument,
  modernize-use-std-numbers); đã sửa trong mã nhưng **chưa chạy lại** để xác nhận. MSVC release /W4 /WX sạch 49 tệp ở bản
  trước khi gập hằng/ đánh số tên; chưa dựng lại bản cuối.

## Số đo cỡ (2026-10-15, MSVC 14.51, i5-14600KF)

- 4,39 triệu dòng C++ (187 MB nguồn sinh) cho 876 424 dòng / 28 MB Lua (5× dòng).
- Dựng `msvc-release` bằng Ninja -j20: **408 s tường** cho 49 tệp (~12 s CPU mỗi tệp, cỡ 10 phút CPU), lúc máy có việc khác.
- `game_luagen.lib` 689 MB (có `/Zi`); không `/Zi` mỗi tệp ~6,9 MB obj, trong đó `.text` ~3,2 MB → **~155-170 MB `.text`**
  nếu nối cả kho (bảng đơn vị tham chiếu mọi chunk nên linker không bỏ được).
- Cờ biên dịch chỉ giảm ~10%: `/Os /Ob0` 2,94 MB, `/O1` 2,90 MB, `/EHs-c-` ~0. Mật độ nằm ở cách phát: ~50 dòng asm mỗi lời gọi
  Lua (mảng `to_array` đối số, `Results` trả về theo giá trị, kiểm `failed`, `constant()` có kiểm biên).
- Số đo của thienlong-34 cho dạng gom tối đa: 31,8-35,5 byte mỗi phép, 1,25 triệu phép → 40-44 MB.

## Vì sao bỏ

Ngân sách: nguồn Lua cả kho 27,5 MB, cả `Game.exe` 2026 chỉ 18,6 MB; 155-170 MB mã máy cho giao diện là quá lớn và dựng quá lâu.
Bytecode + máy thông dịch cho cỡ nhỏ hơn một bậc mà vẫn đối soát được bằng cùng bộ `thienlong_lua_mass`.
