# Đề bài P1 đợt 1: đường ống dữ liệu của máy chủ

Soạn ngày 2026-10-06 cho Grok Build. Người kiểm cuối là Claude; người duyệt là chủ dự án.

## 1. Việc này là gì

THIENLONG (`F:\tl 2026\THIENLONG`) là client tự viết của Thiên Long Bát Bộ, đang dựng thêm máy chủ
game. Kế hoạch máy chủ có mười ba mốc. Mốc P0 (chuẩn bị) đã đạt. Mốc P1 dựng dữ liệu cho máy chủ;
đợt 1 của P1 viết ba công cụ Python đổi dữ liệu gốc thành bảng TSV và tệp cảnh, kèm test.

Mọi mốc sau đọc các bảng này. Một ô sai hay một dòng rơi mất ở đây sẽ thành bug gameplay rất khó lần
ngược. Vì vậy thứ tự ưu tiên của đợt này là: không mất dữ liệu, không đoán, mọi thứ đếm được. Đặt
được nhiều tên cột đẹp xếp sau cả ba điều đó.

Cách tổ chức: bạn là phiên chính, gọi là L. L điều phối năm vai:

- L: dựng hợp đồng chung trước, tích hợp sau, viết báo cáo cuối. L không viết hộ mã của A, B, C.
- A, B, C: ba subagent viết mã, chạy song song, mỗi vai một cây nguồn và một thư mục đích.
- R: một subagent review, mở sau khi A, B, C xong. R không sửa mã.

Dùng cơ chế subagent của Grok Build (role `implementer` cho A, B, C; role `reviewer` cho R nếu có).
R phải là phiên mới, không thừa hưởng ngữ cảnh làm việc của A, B, C, để nhận xét không bị neo theo
lời kể của người viết. Nếu phiên này không mở được subagent thì chạy năm vai lần lượt, giữ nguyên
tệp sở hữu và các bước, và ghi rõ điều đó ở đầu `KET-QUA.md`.

Khi giao việc cho subagent: đưa đường dẫn tệp này và tên vai, bảo nó đọc trọn tệp. Không kể lại đề
bài bằng lời của bạn: mỗi lần kể lại là một lần rơi chi tiết.

Làm trực tiếp trong `F:\tl 2026\THIENLONG`. Không dùng git worktree: `SERVER/`, `TOOLS/server/` và
hai tệp kế hoạch chưa vào git, nên một worktree mới sẽ không có chúng.

## 2. Hiện trạng

Đã có (đừng viết lại):

- `SERVER/config/`: mười một tệp TOML của tiến trình, và `secrets.local.toml` do công cụ sinh.
- `TOOLS/server/config_style.py`: bố cục tệp TOML, hàm `render()` để sinh TOML đúng bố cục.
- `TOOLS/server/lint_config.py`: kiểm TOML. Hiện in `12 tệp sạch, 144 cài đặt đều có chú thích và
  thẳng cột`.
- `TOOLS/server/setup_db.py`: dựng PostgreSQL. Đợt này không dùng tới database.
- `TOOLS/content/dbc.py`: bộ đọc bảng DBC nhị phân của client 2026. Dùng lại, không chép, không sửa.
- `SERVER/tables/server`, `SERVER/tables/shared`, `SERVER/tables/variants`, `SERVER/scenes`: thư mục
  rỗng, là đích của đợt này.

Chưa có: mọi công cụ dữ liệu của mục 9 trong kế hoạch, mọi bảng, mọi tệp cảnh, mọi mã C++ của máy
chủ.

Cây làm việc đang có thay đổi chưa commit của một phiên khác (client: `SRC/client`, `SRC/gpu`,
`SRC/render`, `SRC/window`, `tests/`, `CMakeLists.txt`...). Phiên đó vẫn đang làm. Không đụng vào.

## 3. Tài liệu phải đọc trước khi viết dòng mã đầu tiên

Đường dẫn tính từ gốc dự án.

| Tệp | Đọc mục nào | Để biết gì |
|---|---|---|
| `AGENTS.md` | mục 0 (các dòng về máy chủ), 2, 4, 5, 9, 11 | quyết định đã chốt, vòng làm việc, điều cấm, bẫy đã đo |
| `docs/KE-HOACH-SERVER.md` | mục 1, 6, 9, và dòng P1 của mục 10 | định dạng dữ liệu, danh sách công cụ, tiêu chí của mốc |
| `docs/SERVER-TEP-CAU-HINH.md` | mục 1, 2, 5, 6, 7, 8, 9 | luật đặt tên, bảng thuật ngữ pinyin sang tiếng Anh, tên gốc sang tên mới của từng tệp |
| `SERVER/README.md` | cả tệp | bố cục `SERVER/`, thứ nào vào git |
| `SRC/table/tsv.hpp`, `SRC/table/tsv.cpp` | cả hai | bộ đọc TSV phía C++; mọi bảng sinh ra phải đọc được bằng nó |
| `TOOLS/server/lint_config.py`, `TOOLS/server/config_style.py` | cả hai | phong cách công cụ Python của máy chủ |
| `TOOLS/bake/test_bake.py` | phần đầu | cách dự án viết test `unittest` cho công cụ |

Tài liệu mâu thuẫn với thứ trên đĩa thì đĩa thắng. Ghi chỗ mâu thuẫn vào báo cáo, không sửa tài
liệu: Claude sửa sau khi kiểm.

## 4. Nguồn dữ liệu (chỉ đọc)

Bạn được phép đọc ba cây ngoài dự án dưới đây. Không ghi, không đổi tên, không xoá gì trong đó.

Bản chạy 0859602, gốc `C:\Users\myhea\Desktop\New folder\TLBB_0859602_Win10_11\tlbb`:

- `Server\Config`: 113 tệp (93 `.txt`, 18 `.ini`, 2 `.cpf`).
- `Public\Config`: 91 tệp, và 180 tệp trong ba thư mục con `AbilityLevelUp` (24), `RandShop` (15),
  `MountFlight` (141).
- `Public\Scene`: 3.251 tệp (2.150 `.ini`, 291 `.txt`, 244 `.scn`, 234 `.path`, 231 `.nav`,
  73 `.stall`, 28 `.ObjRegion`).
- `Public\Data`: `Script.dat`, `AIScript.dat`, thư mục `Script` và `AIScript`.

Mã nguồn máy chủ 2008, gốc `C:\Users\myhea\Desktop\New folder\tlbb_server`. Chỉ để đọc ngữ nghĩa:
tệp gốc được nạp ra sao thì bảng xuất ra phải mang đúng nghĩa đó.

- `Common\DataBase\TLBB_DBC.cpp`: bộ đọc bảng chữ, hàm `OpenFromMemoryImpl_Text`.
- `Common\ServerBase\Ini.cpp`: bộ đọc ini. `Common\ServerBase\Config.cpp`, `Config.h`, `FileDef.h`:
  tệp nào được nạp và nạp thành gì.
- `Server\GameServer\Server\Main\GameTable.cpp`: nơi nạp từng bảng.
- `Server\GameServer\Server\Scene\Map.cpp`, `PathFinder.cpp`, `Scene_Core.cpp`, `AreaManager.cpp`;
  `Server\GameServer\Server\Obj\MonsterManager.cpp`; `Server\GameServer\Server\AI\Patrol.cpp`;
  `Server\GameServer\Server\Item\GrowPointManager.cpp`: nơi nạp tệp của cảnh.

Client 2026, gốc `F:\tl 2026\_raw`:

- `Config`: 722 tệp ở tầng trên cùng (718 `.txt` là bảng DBC nhị phân, `Script.dat`, `AIScript.dat`,
  hai tệp `.lua`), và bốn thư mục con: `AbilityLevelUp` (24 tệp) và `ActionSet` (3 tệp) cũng là
  bảng DBC; `event` và `obj` là thư mục script.

Điều đã đo ngày 2026-10-06. Đo lại trước khi dựa vào; lệch thì báo, không sửa số cho khớp:

- Tệp chữ của bản 0859602 là UTF-8 không BOM hoặc ASCII, xuống dòng CRLF. Không tệp nào chỉ giải mã
  được bằng GB18030. Nhiều tệp trong đó giải mã GB18030 sẽ báo lỗi hoặc ra chữ rác. Chuỗi trong DBC
  của client 2026 thì là GB18030 (`dbc.py` đã xử lý).
- Bảng chữ: dòng 1 là kiểu cột (`INT`, `FLOAT`, `STRING`), dòng 2 là tên cột, từ dòng 3 là bản ghi,
  các ô cách nhau bằng tab. `OpenFromMemoryImpl_Text` bỏ dòng bắt đầu bằng `#`, bỏ dòng có ô đầu
  rỗng, đệm ô rỗng cho dòng thiếu ô, đọc ô `INT` bằng `atoi`, bộ đệm mỗi dòng 10 KiB.
- Mã nguồn 2008 lưu bằng GBK: chú thích trong đó đọc ra chữ rác nếu mở như UTF-8, phần mã thì đọc
  bình thường.
- `luoyang.nav` dài 1.638.404 byte: hai số u16 little-endian (640, 640) rồi 4 byte mỗi ô.
- `Server\Config\Account.txt` chứa 10.074 tên và mật khẩu thử dạng rõ. Không xuất, không in, không
  chép nội dung tệp này vào bất cứ đâu, kể cả báo cáo.

## 5. Việc của từng vai

Mỗi vai chỉ tạo và sửa tệp của mình. Cần đổi tệp của vai khác thì ghi yêu cầu vào báo cáo của mình
và báo L, không tự sửa.

### L: hợp đồng chung và tích hợp

Trước khi mở A, B, C (bước 0):

- `TOOLS/server/table_names.tsv`: một nguồn duy nhất cho câu hỏi "tệp gốc này thành gì". Mỗi cặp
  (tệp gốc, tệp đích) một dòng; tệp gốc không có đích vẫn có một dòng. Cột tối thiểu: `tree`
  (`server_config`, `public_config`, `client_2026`), `source` (đường dẫn tương đối trong cây, dấu
  `/`), `fate` (`table`, `reference`, `rules`, `process_config`, `scene_data`, `client_only`,
  `dropped`, `deferred`), `target` (đường dẫn dưới `SERVER/`, rỗng khi không phải `table`), `key`
  (`box_key`, `shop_key` hay khoá biến thể; rỗng nếu không có), `owner` (`A`, `B` hoặc rỗng),
  `unresolved` (1 khi phụ lục còn dấu `?`), `note`. Lấy từ mục 5, 6, 9 của phụ lục. Được thêm cột,
  không bớt.
- `TOOLS/server/tsv_file.py`: hàm ghi và hàm đọc bảng theo hợp đồng ở mục 6. A, B, C đều ghi bảng
  qua nó.
- `TOOLS/server/test_table_names.py`, `TOOLS/server/test_tsv_file.py`.

Luật chia bảng khi phụ lục không rõ: tệp có trong `_raw\Config` của client 2026 thì A xuất vào
`tables/shared/` hoặc `tables/variants/`. Tệp của `Public\Config` có bản cùng tên ở client thì chỉ
là `reference`, dùng để lấy tên cột. Tệp của `Public\Config` không có ở client thì B đưa vào
`tables/server/`.

Sau khi đối chất xong (bước 5): `TOOLS/server/build_data.py` và `TOOLS/server/test_build_data.py`,
một lệnh sinh lại toàn bộ cây dữ liệu, rồi `KET-QUA.md`.

### A: bảng của client 2026

- Nguồn: `F:\tl 2026\_raw\Config`. Tham chiếu tên cột: `Public\Config` của bản 0859602.
- Viết: `TOOLS/server/table_census.py`, `TOOLS/server/export_tables.py`, hai tệp test tương ứng
  `test_table_census.py`, `test_export_tables.py`, và các tệp cột `TOOLS/server/columns/shared/`.
- Đích: `TOOLS/server/table_census.tsv` (mỗi bảng một dòng: tên, số cột, số bản ghi, dãy kiểu cột,
  SHA-256 của tệp gốc); `SERVER/tables/shared/`; `SERVER/tables/variants/<khoá>/`.
- Mọi tệp và thư mục dưới `_raw\Config` phải được phân loại, kể cả thứ không xuất (`event`, `obj`,
  `.lua`, `.dat`): không có tệp nào "không biết là gì".
- DBC không mang tên cột. Mặc định cột tên `column_<chỉ số từ 0>`. Chỉ đặt tên thật khi có bằng
  chứng: bảng cùng tên ở bản 0859602 có cùng số cột và cùng dãy kiểu. Khi đó lấy tên từ dòng tên cột
  của bản 0859602, dịch sang tiếng Anh theo bảng thuật ngữ ở mục 1 của phụ lục, và báo thêm với mỗi
  cột: trong các bản ghi có cùng id ở hai bản, bao nhiêu phần trăm ô bằng nhau.
- Bảng có tên còn dấu `?` vẫn xuất, dưới tên tạm trong `table_names.tsv`.

### B: bảng chỉ máy chủ giữ, bản 0859602

- Nguồn: `Server\Config`, các tệp của `Public\Config` không có ở client 2026, thư mục `RandShop`,
  và `Public\Data\Script.dat`, `Public\Data\AIScript.dat`.
- Viết: `TOOLS/server/import_legacy.py`, `TOOLS/server/test_import_legacy.py`, các tệp cột
  `TOOLS/server/columns/server/`.
- Đích: `SERVER/tables/server/`, tên theo mục 5, 6, 8 của phụ lục. 35 tệp `boxdroplist*` gộp thành
  một bảng có cột `box_key`; 15 tệp `RandShop` gộp thành một bảng có cột `shop_key`.
- Bảng xuất ra phải mang đúng giá trị mà máy chủ gốc nhìn thấy sau khi nạp, theo
  `OpenFromMemoryImpl_Text` và `Ini.cpp`. Mỗi chỗ giá trị ghi ra khác nguyên văn của tệp gốc (ô rỗng
  thành 0, `12abc` thành 12, dòng bị bỏ, dòng được đệm) phải được đếm theo từng bảng và in trong báo
  cáo. Không có biến đổi nào diễn ra im lặng.
- Tệp ini dạng bảng (`SceneInfo.ini`, `SystemInfo.ini`, `GuildMemberAccess.ini`,
  `BaseValueTable.ini`, `MonsterAITable.ini`, `RandShop\*.ini`): đọc hàm nạp tương ứng trong mã 2008
  trước khi quyết định mỗi section thành dòng hay thành cột.
- Tên cột: tên gốc đã là định danh ASCII thì đổi sang `snake_case` bằng máy; tên tiếng Trung thì
  dịch theo bảng thuật ngữ. Chưa chắc nghĩa thì để `column_<chỉ số>` và ghi `?` vào cột `note` của
  tệp cột. Không đặt tên theo phỏng đoán.
- Không làm ở đợt này: mười ba tệp TOML luật chơi của `SERVER/config/rules/`, và mọi tệp có `fate`
  khác `table`.

### C: dữ liệu cảnh, bản 0859602

- Nguồn: `Public\Scene`.
- Viết: `TOOLS/server/export_scene.py`, `TOOLS/server/test_export_scene.py`, tệp phụ nếu cần thì
  đặt tiền tố `scene_`, các tệp cột `TOOLS/server/columns/scenes/`.
- Đích: `SERVER/scenes/<scene>/`, tên tệp theo mục 7 của phụ lục: `scene.toml`, `spawns.tsv`,
  `spawns.level_<cấp>.tsv`, `spawns.<entrance>.tsv`, `areas.tsv`, `patrols.tsv`, `grow_points.tsv`,
  `grow_point_rules.tsv`, `wild_pets.tsv`, `platforms.tsv`, `portals.tsv`, `buses.tsv`, `walk.nav`.
- `<scene>` là thân tên của tệp `.scn`, giữ nguyên. Hai thân tên chỉ khác chữ hoa chữ thường là lỗi.
- Cả 3.251 tệp phải được phân loại vào đúng một loại. Tệp không gắn được vào cảnh nào là lỗi có
  tên tệp, không bỏ qua.
- `scene.toml` sinh bằng `config_style.render`, có `schema = 1`, mỗi khoá một chú thích tiếng Việt,
  và phải qua `lint_config.py`. Ghi cỡ lưới đọc từ đầu tệp `.nav`.
- `.nav`: đọc `Map.cpp` để biết bố cục, kiểm cỡ tệp của cả 231 tệp khớp với đầu tệp, rồi chép
  nguyên byte thành `walk.nav`. Chưa nấu sang định dạng khác.
- `.path`, `.stall`, `.ObjRegion`: chưa đọc được định dạng. Chỉ đếm và phân loại, không chép.
- Khoá có trong tệp ini mà mã 2008 không đọc: vẫn xuất thành cột và đánh dấu trong tệp cột. Khoá
  công cụ chưa biết là lỗi, không rơi im lặng.

### R: review

Việc và cách làm ở mục 9, bước 2 và bước 4.

## 6. Hợp đồng chung

Bảng TSV, đọc được bằng `game::table::parse_tsv`:

```text
# schema 1
# source: <tree>/<đường dẫn tệp gốc>
# tool: TOOLS/server/<công cụ>.py; sửa tay sẽ mất ở lượt xuất sau
# types: <kiểu từng cột, cách nhau bằng tab: int, float, text>
<tên cột, cách nhau bằng tab>
<bản ghi>
```

- UTF-8 không BOM, xuống dòng LF, có xuống dòng cuối tệp. Bảng gộp từ nhiều tệp thì dòng `source`
  ghi mẫu tên và số tệp.
- Tên cột khớp `[a-z][a-z0-9_]*`, không trùng nhau trong một bảng.
- Ô không chứa tab, CR, LF. Gặp thì báo lỗi kèm tệp, dòng, cột. Không tự nghĩ ra cách escape: đó là
  đổi định dạng, phải có quyết định của chủ dự án. Bảng vướng lỗi này thì không xuất và nêu tên
  trong báo cáo.
- `parse_tsv` bỏ dòng rỗng và dòng bắt đầu bằng `#`. Bản ghi có ô đầu bắt đầu bằng `#`, hoặc bảng
  một cột có ô rỗng, sẽ biến mất khi đọc. `tsv_file.py` phải từ chối ghi hai ca đó.
- Kiểu cột ghi theo khai báo của tệp gốc. Không đoán lại kiểu. Cột khai `STRING` mà mọi ô là số thì
  liệt kê trong báo cáo, chưa đổi.
- Ô số thực của DBC ghi bằng chuỗi ngắn nhất mà đọc lại ra đúng 32 bit gốc. Ô số thực của bảng chữ
  giữ nguyên văn.
- Tất định: cùng đầu vào cho ra tệp trùng từng byte. Không ngày giờ, không tên máy, không đường dẫn
  tuyệt đối trong tệp sinh ra; duyệt thư mục theo thứ tự đã sắp.

Tệp cột `TOOLS/server/columns/<shared|server|scenes>/<tên bảng>.tsv`, cùng hợp đồng trên, cột:
`index`, `original` (tên gốc, rỗng nếu không có), `name`, `type`, `note`.

Dòng lệnh. Gốc nguồn luôn là tham số, không ghi đường dẫn tuyệt đối vào mã:

```text
python TOOLS/server/table_census.py <_raw>
python TOOLS/server/export_tables.py <_raw> <tlbb> SERVER/tables
python TOOLS/server/import_legacy.py <tlbb> SERVER/tables/server
python TOOLS/server/export_scene.py <tlbb> SERVER/scenes
python TOOLS/server/build_data.py --legacy <tlbb> --raw <_raw> [--check] [--digest]
```

Mọi công cụ có `--help` tiếng Việt và `--check` (kiểm hết, không ghi tệp nào). Thoát 0 khi sạch, 1
khi có lỗi. Mỗi lỗi một dòng `tệp:dòng: nội dung`. `build_data.py --digest` in một mã SHA-256 của
toàn bộ `SERVER/tables` và `SERVER/scenes`.

Test dùng hai biến môi trường để tìm dữ liệu thật: `THIENLONG_LEGACY_ROOT` (thư mục `tlbb`) và
`THIENLONG_RAW_ROOT` (thư mục `_raw`). Thiếu biến thì các test dữ liệu thật tự bỏ qua kèm lý do; các
test còn lại dựng dữ liệu giả nhỏ ngay trong test và phải chạy được trên máy không có hai cây nguồn.

## 7. Chuẩn chất lượng

Mã là production grade. Với công cụ Python của dự án này, điều đó nghĩa là:

- Python 3.13, chỉ thư viện chuẩn. Cần gói ngoài thì dừng và ghi vào báo cáo, không `pip install`.
- Thất bại ồn ào. Tệp lạ trong thư mục nguồn, sai số ô, byte không giải mã được, id trùng, khoá
  lạ: đều là lỗi có vị trí. Không `except` rồi bỏ qua, không trả giá trị mặc định thay cho lỗi.
- Kiểm hết rồi mới ghi. Mỗi tệp ghi ra tệp tạm cùng thư mục rồi `os.replace`. Một bảng lỗi thì
  không để lại tệp dở.
- Thư mục đích không giữ tệp cũ của lượt trước: công cụ chỉ xoá tệp mang dòng `# tool:` của chính
  nó; gặp tệp lạ trong thư mục đích thì báo lỗi, không xoá.
- Định danh tiếng Anh, không viết tắt tự chế. Chú thích, thông báo, `--help` bằng tiếng Việt có dấu.
  Đầu mỗi tệp một khối chú thích ngắn: tệp làm gì, cách chạy, định dạng lấy từ đâu.
- Hàm ngắn, câu bảo vệ thoát sớm, không lồng sâu. Có type hint. Không căn thẳng cột bằng dấu cách,
  trong mã lẫn trong báo cáo.
- Test viết trước, bằng `unittest`, tên `TOOLS/server/test_<công cụ>.py`. Test phải đỏ vì đúng lý do
  trước khi có mã (lỗi import không tính), rồi mới xanh. Dán một lần output đỏ và một lần output
  xanh vào báo cáo.
- Test phải bắt được lỗi thật. Với mỗi luật ở mục 6 có ít nhất một ca đầu vào hỏng mà công cụ phải
  từ chối: sai magic, tệp cụt, dòng thừa ô, tab trong ô, id trùng, byte UTF-8 hỏng, tệp lạ.
- Chạy test với `python -W error`: cảnh báo là lỗi.
- Tệp tạm của test nằm trong `build/` của dự án và được xoá khi test xong.
- Chưa chạy thì nói chưa chạy. Test đỏ thì nói đỏ và dán output. Không viết "đã kiểm" cho thứ mới
  chỉ đọc bằng mắt.

Việc chạy lâu (xuất 718 bảng, 109 MB) thì chạy nền và chờ xong, không huỷ giữa chừng.

## 8. Ranh giới cứng

Phiên này chạy ở chế độ tự duyệt lệnh, nên các ranh giới dưới đây là thứ duy nhất chặn một thao tác
hỏng việc của người khác.

Chỉ được tạo và sửa tệp ở bốn chỗ:

- `TOOLS/server/`: tệp mới nêu ở mục 5. Không sửa `config_style.py`, `lint_config.py`,
  `setup_db.py`.
- `SERVER/tables/` và `SERVER/scenes/`: đầu ra của công cụ.
- `docs/giao-viec/P1-DOT-1/`: báo cáo. Không sửa `DE-BAI.md`.
- `build/`: tệp tạm, tự dọn.

Không đụng: mọi thứ còn lại, trong đó có `AGENTS.md`, `CLAUDE.md`, `docs/*.md`, `.gitignore`,
`CMakeLists.txt`, `vcpkg.json`, `SRC/`, `tests/`, `CLIENT/`, `SERVER/README.md`, `SERVER/config/`,
`SERVER/pgsql/`, `SERVER/data/`, `TOOLS/content/`. Thấy cần sửa chỗ nào trong đó thì ghi vào báo
cáo. Không mở, không in `SERVER/config/secrets.local.toml`.

Git chỉ dùng lệnh đọc: `git status`, `git diff`, `git log`. Không `add`, `commit`, `push`, `stash`,
`restore`, `checkout`, `reset`, `clean`, `rebase`, `worktree`. Một lệnh `git stash` hay `git restore`
sẽ xoá việc đang dở của phiên khác trong cùng cây.

Không chạy `setup_db.py`. Không cài gì lên máy. Không ghi ra ngoài thư mục dự án.

## 9. Các bước

Bước 0, L làm một mình. Đọc tài liệu ở mục 3. Ghi lại `git status --short` lúc bắt đầu. Viết hợp
đồng chung ở mục 5, chạy test của nó cho xanh. Chạy `python TOOLS/server/lint_config.py` và giữ
output làm mốc. Chưa xong bước này thì chưa mở A, B, C: ba vai dựa vào cùng một hợp đồng.

Bước 1, A, B, C song song. Mỗi vai đọc tệp này, đọc tài liệu và nguồn của mình, viết test đỏ, viết
mã, chạy trên dữ liệu thật, rồi viết `BAO-CAO-<vai>.md`. Trong lúc làm chỉ chạy test của mình
(`python -W error -m unittest discover -s TOOLS/server -p "test_export_tables.py"`), vì tệp của vai
khác có thể đang viết dở.

Bước 2, R review. R đọc tệp này và mã, không tin báo cáo: mọi con số trong `BAO-CAO-*.md` phải tự
chạy lại. R viết `REVIEW.md`. Việc của R:

- Chạy lại từng tiêu chí ở mục 10 và dán output thật.
- Kiểm mất dữ liệu bằng đường độc lập với mã của người viết: chọn ô ngẫu nhiên có hạt giống cố
  định, đọc tệp gốc bằng mã của chính R (với DBC thì dùng thẳng `TOOLS/content/dbc.py`), tách TSV
  bằng `split("\t")`, so từng ô. Script kiểm đặt ở `docs/giao-viec/P1-DOT-1/kiem/` và giữ lại để
  Claude chạy lại.
- Cố phá: đưa đầu vào hỏng (dựng trong `build/`) cho từng công cụ và xem nó có từ chối không. Ghi cả
  những đòn đã thử mà không phá được.
- Đọc test: test nào vẫn xanh khi mã sai thì nêu ca sai cụ thể.
- Soát ranh giới ở mục 8 và từng dòng của mục 7.
- Soát cả mã của L (`tsv_file.py`, `table_names.tsv`).

R không sửa mã và không viết hộ bản sửa; R nêu điều phải đúng sau khi sửa.

Bước 3, đối chất, ba lượt, mỗi lượt A, B, C song song và mỗi vai chỉ ghi vào `DOI-CHAT-<vai>.md`
của mình:

- 3a. Trả lời từng finding của R nhắm vào mình: NHẬN thì sửa và dán lệnh kiểm kèm output; BÁC thì
  dán bằng chứng. Không có câu trả lời nào chỉ gồm lý lẽ.
- 3b. Xét chéo theo vòng: A xét B, B xét C, C xét A. Dùng công cụ của bên kia như một người dùng
  khó tính: chạy nó trên dữ liệu thật, đọc mã, tìm ba thứ: dữ liệu mất im lặng, chỗ vi phạm hợp đồng
  ở mục 6, và một lỗi cụ thể mà test của bên kia không bắt được. Lượt này chỉ đọc mã của bên kia,
  không sửa.
- 3c. Trả lời các finding chéo nhắm vào mình, cùng luật với 3a.

Bước 4, R phán quyết. R chạy lại toàn bộ sau khi sửa và thêm mục `Phán quyết` vào cuối `REVIEW.md`,
mỗi finding (của R và finding chéo) một dòng: `ĐÃ SỬA` kèm lệnh R tự chạy lại, `BÁC ĐÚNG` khi bằng
chứng của người viết đứng vững, `CÒN MỞ`, hoặc `TRANH CHẤP`. Chỉ một vòng sửa sau review và một
vòng sau xét chéo. Còn bất đồng thì để `TRANH CHẤP` với lý lẽ và bằng chứng của cả hai bên. Không ép
đồng thuận: Claude phân xử.

Bước 5, L tích hợp. Viết `build_data.py` và test của nó, chạy đủ mục 10, viết `KET-QUA.md`. L
không sửa finding hộ ai; finding `CÒN MỞ` thì đưa nguyên vào báo cáo.

## 10. Tiêu chí đạt

Lệnh chạy ở gốc dự án. `<tlbb>` là `C:\Users\myhea\Desktop\New folder\TLBB_0859602_Win10_11\tlbb`,
`<_raw>` là `F:\tl 2026\_raw`.

| Mã | Lệnh hoặc phép kiểm | Đạt khi |
|---|---|---|
| T1 | `python -W error -m unittest discover -s TOOLS/server -p "test_*.py"`, không đặt hai biến môi trường | xanh; các test dữ liệu thật báo bỏ qua kèm lý do |
| T2 | cùng lệnh, đã đặt `THIENLONG_LEGACY_ROOT` và `THIENLONG_RAW_ROOT` | xanh, không test nào bị bỏ qua |
| T3 | `python TOOLS/server/build_data.py --legacy "<tlbb>" --raw "<_raw>"` | thoát 0, in bảng tổng kết số tệp và số bản ghi của từng thư mục đích |
| T4 | `build_data.py ... --digest` chạy hai lần liền nhau | hai mã SHA-256 bằng nhau |
| T5 | phủ kín nguồn | mọi tệp của `Server\Config`, `Public\Config`, `Public\Scene`, `_raw\Config` được phân loại đúng một lần; 0 tệp chưa phân loại; số đếm in ra |
| T6 | không mất dữ liệu | A: mọi bảng xuất đọc lại bằng từng ô của DBC; B: số bản ghi và từng ô khớp ngữ nghĩa bộ đọc gốc, mọi biến đổi đã đếm; C: số dòng mỗi bảng bằng số đếm ghi trong tệp ini, không khoá nào rơi |
| T7 | `python TOOLS/server/lint_config.py`, rồi cùng lệnh với mọi `SERVER/scenes/*/scene.toml` | sạch cả hai |
| T8 | `git status --short` so với mốc ở bước 0 | thay đổi do đợt này chỉ nằm trong bốn chỗ của mục 8 |
| T9 | tìm trong `SERVER/` và `docs/giao-viec/` | không có nội dung của `Account.txt`, không có mật khẩu |

Tiêu chí không đạt thì ghi không đạt kèm output. Một đợt báo trung thực rằng còn hai tiêu chí đỏ có
giá trị hơn một đợt báo xanh hết mà Claude chạy lại ra đỏ.

## 11. Báo cáo

Mọi tệp nằm ở `docs/giao-viec/P1-DOT-1/`. Viết tiếng Việt có dấu, câu ngắn, không lời khen, không
tóm tắt lại đề bài. Số liệu nào cũng kèm lệnh sinh ra nó.

`BAO-CAO-A.md`, `BAO-CAO-B.md`, `BAO-CAO-C.md` (người viết mã):

1. Tệp đã tạo: đường dẫn và một dòng vai trò.
2. Đã kiểm: từng lệnh và output thật, gồm một lần đỏ và một lần xanh của test.
3. Số đo: số tệp nguồn theo loại, số bảng, số bản ghi, số cột có tên thật trên tổng số cột, số cột
   còn `?`, số biến đổi so với nguyên văn theo từng bảng, thời gian chạy.
4. Chưa kiểm, kèm lý do.
5. Giả định.
6. Lệch quy tắc, kèm lý do.
7. Chỗ tài liệu mâu thuẫn với đĩa.

`REVIEW.md` (chỉ R viết). Mỗi finding:

```text
### R-B-03 [CHẶN] <một câu nói điều sai>
- Chỗ: TOOLS/server/import_legacy.py:142
- Bằng chứng: <lệnh> rồi <output thật>
- Đòi hỏi: <điều phải đúng sau khi sửa>
```

Mã finding: `R-<vai>-<số>`, vai là `A`, `B`, `C` hoặc `L`. Mức: `CHẶN` (mất hay sai dữ liệu, test
xanh giả, vượt ranh giới), `SỬA` (xử lý lỗi thiếu, test thiếu, thông báo sai), `GHI` (nhận xét).
Sau các finding có mục "Đã thử phá mà không phá được" cho từng vai, và cuối tệp là mục `Phán quyết`
của bước 4.

`DOI-CHAT-A.md`, `DOI-CHAT-B.md`, `DOI-CHAT-C.md` (mỗi vai viết tệp của mình), ba phần: "Trả lời
review", "Xét chéo <vai bên kia>" với mã `X-AB-01` (A xét B), "Trả lời xét chéo".

`KET-QUA.md` (L viết, gửi Claude):

1. Bảng T1 tới T9: đạt hay không, lệnh, output thật đã cắt gọn.
2. Mọi tệp đã tạo hoặc sửa trong đợt, theo vai.
3. Số đo gộp của ba vai.
4. Bảng mọi finding: mã, mức, chỗ, một câu, phán quyết.
5. Từng `TRANH CHẤP` và `CÒN MỞ`: lý lẽ và bằng chứng của các bên.
6. Chưa kiểm, giả định, lệch quy tắc.
7. Chỗ tài liệu cần sửa, kèm bằng chứng từ đĩa.
8. Đề nghị cho đợt 2.

Claude sẽ chạy lại từng lệnh trong `KET-QUA.md` và so mẫu dữ liệu bằng đường riêng. Lệnh không tái
hiện được thì coi như chưa làm. Lỗi Claude tìm ra mà `REVIEW.md` không có là thiếu sót của vòng
review.

## 12. Ngoài phạm vi đợt này

Để đợt 2, không làm trước: mười ba tệp TOML luật chơi (`SERVER/config/rules/`), `diff_tables.py`,
`thienlong_lint` (C++), `bake_nav.py` và lưới đi nấu từ `.region` của client, giải 91 tên bảng còn
dấu `?`, `lua_extract.py`, `ai_convert.py`, dịch nội dung bảng sang tiếng Việt, mọi mã C++ và mọi
thay đổi ở `CMakeLists.txt`.

Thấy vấn đề ngoài phạm vi thì ghi vào báo cáo, không tự sửa.
