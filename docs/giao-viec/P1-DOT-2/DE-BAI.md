# Đề bài P1 đợt 2: trả nợ đợt 1, luật chơi, tên cột, tệp cảnh do script nạp

Soạn ngày 2026-10-07 cho Grok Build. Người kiểm cuối là Claude; người duyệt là chủ dự án.

## 1. Việc này là gì

Đợt 1 đã dựng đường ống đổi dữ liệu gốc thành bảng TSV và tệp cảnh cho máy chủ THIENLONG
(`F:\tl 2026\THIENLONG`). Claude đã chạy lại và nhận phần dữ liệu: không ô nào lệch nguồn. Đợt 2 làm
bốn việc: sửa các chỗ Claude tìm ra ở đợt 1, sinh các tệp luật chơi, đặt tên cột theo bằng chứng dữ
liệu, và gắn các tệp cảnh do script nạp.

Cách tổ chức giữ nguyên như đợt 1: bạn là phiên chính L; A, B, C viết mã song song; R review trong
phiên mới không thừa hưởng ngữ cảnh của người viết; rồi đối chất chéo; L ghi `KET-QUA.md`. Khi giao
việc cho subagent, đưa đường dẫn tệp này và tên vai, không kể lại bằng lời của bạn. Làm trực tiếp
trong `F:\tl 2026\THIENLONG`, không dùng worktree.

Đọc trước khi viết mã, theo thứ tự:

1. Tệp này.
2. `docs/giao-viec/P1-DOT-1/DE-BAI.md`: mục 3 (tài liệu), mục 4 (ba cây nguồn và điều đã đo), mục 6
   (hợp đồng TSV), mục 7 (chuẩn chất lượng), mục 8 (ranh giới). Các mục đó vẫn có hiệu lực; tệp này
   chỉ ghi chỗ thay đổi và việc mới.
3. `docs/giao-viec/P1-DOT-1/KET-QUA.md` và `REVIEW.md`: thứ đã làm và đã tranh luận.
4. `AGENTS.md` của dự án, `docs/KE-HOACH-SERVER.md`, `docs/SERVER-TEP-CAU-HINH.md`. Hai tệp kế hoạch
   đã được Claude sửa theo các số đo của đợt 1.

Quy định áp cho đợt này là `AGENTS.md` của dự án. Công cụ dữ liệu viết bằng Python 3.13, gọi bằng
`python`; tệp TOML căn cột bằng `config_style`. Cả hai là quyết định của chủ dự án ở mục 0 của
`AGENTS.md`. Quy định chung nào của máy nói khác hai điều đó thì quyết định của dự án thắng trong
phạm vi đợt này.

## 2. Kết quả kiểm đợt 1 và nợ phải trả

Claude kiểm bằng script riêng ở `docs/giao-viec/P1-DOT-1/kiem-claude/` (đọc và chạy được, không sửa):

- 635 bảng client, 994.925 bản ghi, 18.636.500 ô so với DBC: 0 lệch.
- 92 tệp chữ và 22 tệp ini bản 0859602 so với bộ đọc viết lại theo mã 2008: 0 lệch.
- 1.570 bảng quái của 244 cảnh, 39.932 dòng: 0 lệch. 244 `walk.nav` trùng băm với nguồn.
- 4.719 tệp TSV đúng hợp đồng. Chạy lại ra cây trùng từng byte.
- T2, T3, T4 không đạt đúng như `KET-QUA.md` đã báo. Báo cáo trung thực, giữ cách báo đó.

Nợ. Mỗi mục có người trả và trạng thái phải đạt; mã `C-` là finding của Claude.

**C-01 (C): 45 tệp của `Public\Scene` không có `.scn` cha.** Đo được: 7 tệp do script nạp bằng
`LuaFnSetSceneLoad_Monster` và `LuaFnSetSceneLoad_Area`; 38 tệp của năm cảnh đăng nhập phía client
(`chuangjian`, `xuanren`, `登陆`, `选人`, `选人11`) không được `.scn`, `SceneInfo.ini` hay script
nào trỏ tới. Cách xử ở mục 4, vai C. Xong thì `build_data.py` thoát 0.

**C-02 (A, L): test dữ liệu thật ghi thẳng vào cây thật.** `test_export_tables.py` dòng 462 chạy
công cụ với đích `SERVER/tables`. `test_two_digests_match` của `test_build_data.py` chạy
`build_data.py`, mà lệnh đó chỉ biết ghi vào `SERVER/` của dự án. Chạy test không được đổi sản phẩm:
mọi test ghi vào `build/`. `build_data.py` cần một tham số chọn gốc đích (mặc định vẫn là `SERVER/`
của dự án) để test trỏ sang `build/`.

**C-03 (A, B, C): hàm dài và lồng sâu.** Đề bài đợt 1 chỉ viết "hàm ngắn, không lồng sâu" nên không
ai đo. Đợt này có số và có cổng kiểm (mục 5). Đo trên mã hiện tại, 13 hàm vượt ngưỡng 50 dòng hoặc
3 mức lồng:

- `import_legacy.py`: `_parse_text` 95 dòng lồng 4; `_load_mgr` 90 dòng lồng 5; `_build_group` 84
  dòng; `_parse_scene` 67 dòng; `_grid` 64 dòng; `export_legacy` 62 dòng lồng 4; `_parse_system` 59
  dòng.
- `export_scene.py`: `_patrol_section` 74 dòng; `_value_rows` lồng 4.
- `export_tables.py`: `collect` 66 dòng.
- `test_export_scene.py`: `test_level_override_and_patrol_unread` 62 dòng. `test_import_legacy.py`:
  `test_real_tree` 62 dòng. `test_export_tables.py`: `_mismatch` lồng 4.

Khoảng 70 dòng mã dài quá 120 cột. Sửa bằng tách hàm và đặt tên phần trung gian. Tách hàm trước,
thêm tính năng sau: sau bước tách, cây đầu ra phải trùng từng byte với mốc ở bước 0.

**C-04 (B): dòng nằm ngoài số khai báo.** `SceneInfo.ini` khai `scenenumber=723` nhưng có 923
section, nên 200 dòng cuối của `scenes.tsv` và `scene_hosting.tsv` là cảnh máy chủ gốc không nạp.
`SystemInfo.ini` khai `broadcount=0` và `huodongcount=0` với 10 và 30 section; `RandShop\shide.ini`
khai `Total=9` với 10 section. Hiện không có gì trong bảng cho biết dòng nào được nạp. Thêm cột số
nguyên `within_declared_count` (1 hoặc 0) vào năm bảng `scenes`, `scene_hosting`,
`rolling_announcements`, `scheduled_events`, `random_shop_goods`. Bỏ ba cột lặp trên mọi dòng
`broadtime`, `broadcount`, `huodongcount`; ba khoá `[info]` đó đi vào bảng luật của mục 4, vai B.

**C-05 (C): tên tệp không nhất quán.** `spawn_operates.tsv` của tệp quái chính nhưng `ops.<hậu
tố>.tsv` của tệp quái theo cấp; tương tự `vals.`. Dùng một quy tắc: `spawn_operates.<hậu tố>.tsv`
và `spawn_operate_values.<hậu tố>.tsv`. Dòng `scene.toml` quá 110 cột thì đặt chú thích lên dòng
trên, đừng rút tên tệp.

**C-06 (A, B, C, L): test in rác ra màn hình.** Lượt T1 in lẫn các dòng như `build_data.py:1: không
rõ đối số: --nope`. Test tự bắt stdout và stderr của công cụ nó gọi; output của lượt test chỉ còn
dòng của `unittest`.

**C-07 (L, A, B): mô-đun gọi tên riêng của nhau.** `export_tables.py` dòng 553 và
`import_legacy.py` dòng 1052 gọi `tsv_file._owned_tool`; `export_tables.py` dòng 630 gọi
`table_census._coverage`. Không mô-đun nào dùng tên bắt đầu bằng `_` của mô-đun khác: L mở hàm công
khai, A và B đổi chỗ gọi. Test của một mô-đun thì được gọi tên riêng của chính mô-đun đó.

**C-08 (R): vòng review bỏ sót C-02 và C-03**, và ở bước 4 không chạy lại lệnh sinh cả cây. Cách
làm của R đợt này ở mục 6.

## 3. Nguồn thêm của đợt này (chỉ đọc)

Ba cây nguồn như mục 4 của đề bài đợt 1. Thêm, trong
`C:\Users\myhea\Desktop\New folder\TLBB_0859602_Win10_11\tlbb`:

- `Public\Data\Script`: 4.248 tệp `.lua`, UTF-8. Đo được 255 lời gọi `LuaFnSetSceneLoad_*` (83
  `_Map`, 125 `_Monster`, 47 `_Area`); 189 dòng có chuỗi viết thẳng, 66 dòng dùng biến hoặc
  `format`.
- Tệp ini luật chơi, số khoá đếm sơ bộ bằng grep, đo lại trước khi dựa vào: `Server\Config\
  ConfigInfo.ini` 42 section 212 khoá; `DefaultChar.ini` 9 section 83 khoá; `PetConfigTable.ini` 1
  section 246 khoá; `DarkConfigTable.ini` 15 khoá; `CopyScene.ini` 5 khoá; `Public\Config\
  CombatLimits.ini` 7 khoá, không có dòng section; `SystemInfo.ini` section `[info]` 3 khoá;
  `MergeConfig.txt` là bảng chữ 7 bản ghi.

Trong `C:\Users\myhea\Desktop\New folder\tlbb_server` (mã 2008, lưu bằng GBK):

- `Common\ServerBase\Config.cpp`, `Config.h`: khoá ini nào được đọc và đọc thành gì.
- `Server\LoginServer\Login\DB\CharConfig.cpp`: nơi đọc `DefaultChar.ini`.
- `Server\GameServer\Server\Main\GameTable.cpp`, `Server\WorldServer\World\Main\WorldTable.cpp`: cột
  nào của bảng nào vào trường nào của struct.
- `Server\GameServer\Server\Script\LuaFnTbl_Scene.h`: các hàm `LuaFnSetSceneLoad_*`.

Số đo cho vai A: 106 bảng client có bản cùng tên ở `Public\Config`; 30 cặp cùng bố cục đã có tên
cột; 76 cặp khác bố cục, phía client 4.517 cột, phía 0859602 3.157 cột. Ví dụ `skills` 102 cột so
với 79, `skill_levels` 54 so với 48, `monsters` 73 so với 70, `items_common` 28 so với 26.

## 4. Việc của từng vai

Mỗi vai chỉ sửa tệp của mình (tệp vai đó tạo ở đợt 1 và tệp mới nêu dưới đây). Trả nợ trước, việc
mới sau.

### L

Bước 0, một mình:

- Ghi mốc vào `docs/giao-viec/P1-DOT-2/moc/`: `git-status.txt` (`git status --short`),
  `treehash.txt` (`python docs/giao-viec/P1-DOT-1/kiem-claude/treehash.py`), `verify.txt`
  (`python docs/giao-viec/P1-DOT-1/kiem-claude/verify_p1.py`, cần hai biến môi trường).
- Viết `TOOLS/server/lint_py.py` và `TOOLS/server/test_lint_py.py` theo mục 5.
- Trả phần của mình trong C-02, C-06, C-07. Hàm công khai của C-07 phải có trước khi mở A, B, C.
- Thêm vào `table_names.tsv` dòng cho các bảng mới của đợt (ít nhất `scene_load_refs.tsv`).

Bước 5: thêm `import_rules.py` và `scene_refs.py` vào `build_data.py`, chạy đủ mục 7, ghi
`KET-QUA.md`.

### A: tên cột theo bằng chứng dữ liệu

DBC không mang tên cột. Tên chỉ có ở dòng 2 của bảng chữ 0859602, mà 76 bảng đã đổi bố cục: thêm
cột, bớt cột. Việc của A là tìm cột nào của bản 2026 ứng với cột nào của bản 0859602 bằng chính dữ
liệu, không bằng phỏng đoán.

- Viết `TOOLS/server/align_columns.py`, `TOOLS/server/test_align_columns.py`; sửa `export_tables.py`
  để dùng nó khi hai bản khác bố cục.
- So trên các bản ghi có cùng id (cột 0) ở hai bản. Phép căn giữ thứ tự: cột được thêm hay bớt,
  không đổi chỗ. Hai cột chỉ được ghép chéo thứ tự khi bạn chứng minh được bằng số liệu và ghi riêng.
- Một cặp cột là `neo` khi cùng kiểu, bằng nhau trên ít nhất 95% id chung, và cột có từ 3 giá trị
  khác nhau trở lên trên các id đó. Cột ít thông tin (hằng số, gần hằng số) không tự làm neo; nó chỉ
  được ghép khi nằm giữa hai neo liền kề mà số cột hai bên bằng nhau, và ghi là `nội suy`. Cột 2026
  không ghép được với cột nào ghi `mới ở 2026`; cột 0859602 không ghép được ghi vào báo cáo là đã
  mất. Kiểu khác nhau mà nội dung bằng nhau thì ghi `đổi kiểu` và cần 99%.
- Tệp cột `columns/shared/<bảng>.tsv`: `original` là tên gốc của cột 0859602 đã ghép, `note` ghi
  loại ghép, chỉ số cột gốc và tỉ lệ, ví dụ `neo: cột gốc 17, khớp 99.2% (812/819 id)`.
- Ghi `TOOLS/server/column_alignment.tsv`, mỗi cặp bảng một dòng: số cột hai bên, số neo, số nội
  suy, số đổi kiểu, số mới ở 2026, số mất.
- Tên tiếng Anh. Tên gốc đã là định danh ASCII thì đổi `snake_case` bằng máy. Tên tiếng Trung thì
  tra `TOOLS/server/column_terms.tsv`, tệp mới do A soạn tay, cột: `original` (nguyên văn tên gốc),
  `name`, `basis`, `note`. `basis` là `glossary` (bảng thuật ngữ ở mục 1 của phụ lục), `direct`
  (dịch thẳng nghĩa của nhãn) hoặc `code:<tệp>:<dòng>` (mã 2008 đọc cột đó vào trường nào). Tên có
  mã chống lưng mạnh hơn tên dịch từ nhãn; có mã thì dẫn mã. Không chắc thì không thêm dòng: cột giữ
  `column_<chỉ số>` và `?`.
- Soạn thuật ngữ cho mười một bảng mà các mốc chiến đấu cần trước: `SkillTemplate_V1`,
  `SkillData_V1`, `XinFa_V1`, `MonsterAttrExTable`, `CommonItem`, `PlayerExpLevel`,
  `ImpactSEData_V1`, `SpecialObjData`, `Bullet`, `AttackTraits`, `SceneAttr`. Các bảng khác chỉ nhận
  tên ASCII đổi bằng máy.
- Tên lặp trong một bảng (251 cột đang ghi `? trùng tên`): đánh số mọi lần xuất hiện theo thứ tự,
  từ 1: `item_index_1`, `item_index_2`.
- Bảng biến thể có cùng số cột và dãy kiểu với bảng gốc 2026 của nó thì dùng tên cột của bảng gốc.
- Ô dữ liệu của `SERVER/tables/shared` và `variants` không đổi một byte; chỉ dòng tên cột đổi.
- Trả C-02, C-03, C-06 phần của mình.

### B: mười ba tệp luật chơi

Mục 4 của phụ lục liệt kê mười ba tệp `SERVER/config/rules/*.toml` và section nguồn của từng tệp.

- Viết `TOOLS/server/import_rules.py`, `TOOLS/server/test_import_rules.py`. Lệnh:
  `python TOOLS/server/import_rules.py <tlbb> SERVER/config/rules [--check]`.
- Soạn tay `TOOLS/server/legacy_rules.tsv`, một dòng cho mỗi cặp (section, khoá) của các tệp nguồn ở
  mục 3, không sót và không lặp. Cột: `source`, `section`, `key`, `fate`, `target_file`,
  `target_table`, `target_key`, `index`, `convert`, `note_vi`, `basis`, `reason`.
  - `fate`: `rule` (vào một trong mười ba tệp), `process_config` (đã nằm ở mười một tệp của
    `SERVER/config`, theo mục 3 của phụ lục; ghi tệp và khoá đích), `dropped` (phụ lục đã bỏ; ghi lý
    do), `unknown` (chưa xác lập được nghĩa; không xuất, đếm trong báo cáo).
  - `convert`: `int`, `bool`, `text`, `permille`, `ppm`. Số thực của bản gốc đổi bằng
    `decimal.Decimal`: ra phần nghìn nếu chẵn, không thì phần triệu, không chẵn nữa thì lỗi có vị
    trí. Không qua `float`.
  - `index`: dãy khoá đánh số (`X0`, `X1`...) thành một mảng TOML; cột này giữ chỉ số.
  - `note_vi`: chú thích tiếng Việt sẽ in cạnh khoá. `basis`: `comment` (dịch chú thích tiếng Trung
    sau dấu `;` của chính khoá đó), `code:<tệp>:<dòng>` (chỗ mã 2008 đọc và dùng khoá) hoặc cả hai.
    Chú thích nói đúng điều đã xác lập, không thêm thắt. Không có căn cứ thì `fate` là `unknown`.
- Tên khoá tiếng Anh `snake_case`, đơn vị nằm trong tên (`_ms`, `_seconds`, `_permille`, `_ppm`).
- Ghi tệp bằng `config_style.render`: tiêu đề in hoa, mỗi nhóm một khung, mỗi khoá một chú thích
  tiếng Việt, `schema = 1`. Mọi tệp phải qua `python TOOLS/server/lint_config.py`.
- Với dòng `process_config`: so giá trị của tệp ini với giá trị đang nằm trong tệp TOML đích và liệt
  kê chỗ khác nhau trong báo cáo. Không sửa mười một tệp đó.
- Thứ tự ưu tiên, chất lượng trước số lượng: sáu tệp `global`, `combat`, `character`,
  `new_character`, `monster`, `instances` trước; bảy tệp còn lại sau. Tệp nào chưa kịp làm kỹ thì
  không sinh, ghi vào báo cáo. Bảng `legacy_rules.tsv` thì vẫn phải phủ kín mọi khoá: khoá chưa làm
  mang `fate` là `unknown` kèm `reason` là `chưa làm ở đợt 2`.
- Trả C-03, C-04, C-06 phần của mình.

### C: tệp cảnh do script nạp

- Viết `TOOLS/server/scene_refs.py`, `TOOLS/server/test_scene_refs.py`. Lệnh:
  `python TOOLS/server/scene_refs.py <tlbb> SERVER/tables/server [--check]`, ghi
  `scene_load_refs.tsv`: mỗi lời gọi `LuaFnSetSceneLoad_*` một dòng. Cột: `script` (đường dẫn dưới
  `Public/Data/Script`), `line`, `kind` (`map`, `monster`, `area` và loại khác nếu có), `argument`
  (nguyên văn đối số thứ hai), `resolved` (tên tệp nếu là chuỗi viết thẳng hoặc hằng chuỗi khai
  trong cùng tệp; mẫu tên nếu là `format`), `how` (`literal`, `constant`, `format`, `unresolved`).
  Lời gọi nằm trong chú thích `--` không tính, nhưng đếm. Không đoán: không giải được thì
  `unresolved`.
- Soạn tay `TOOLS/server/scene_attach.tsv` cho 45 tệp của C-01. Cột: `file`, `fate`, `scene`,
  `evidence`.
  - 7 tệp do script nạp: `fate` là `scene_set`; `scene` là cảnh có `.scn` trỏ tới tệp `.nav` mà
    cùng script đó chọn bằng `LuaFnSetSceneLoad_Map`; `evidence` là `script:dòng`. Xuất vào thư mục
    cảnh đó thành `spawns.set_<thân tên>.tsv` hoặc `areas.set_<thân tên>.tsv`.
  - 38 tệp còn lại: `fate` là `client_only` nếu bạn tự tìm lại và xác nhận không `.scn`, không
    `SceneInfo.ini`, không script nào trỏ tới; `evidence` ghi lệnh tìm. Không xuất, chỉ đếm.
  - Tệp không khớp mẫu tên và không có trong bảng này vẫn là lỗi có tên tệp, như đợt 1.
- Đối chiếu cách gắn theo tên của đợt 1 với script: trong 1.344 tệp quái theo cấp, nhóm và lối vào,
  bao nhiêu tệp được `scene_load_refs.tsv` trỏ tới, và cảnh suy từ `LuaFnSetSceneLoad_Map` đi kèm có
  trùng với thư mục cảnh đang chứa nó không. Liệt kê tệp lệch và tệp không script nào trỏ tới.
  Không tự chuyển tệp; Claude quyết sau khi xem danh sách.
- Trả C-01, C-03, C-05, C-06 phần của mình.

## 5. Hợp đồng thêm

Hợp đồng TSV và dòng lệnh ở mục 6 của đề bài đợt 1 giữ nguyên. Thêm:

Cổng kiểm mã `python TOOLS/server/lint_py.py [tệp...]`, mặc định mọi `TOOLS/server/*.py`. Thoát 0
khi sạch, 1 khi có lỗi, mỗi lỗi một dòng `tệp:dòng: nội dung`. Luật:

- G1: hàm không quá 50 dòng, tính từ dòng `def` tới dòng cuối của thân.
- G2: lồng không quá 3 mức. Mỗi `if`, `for`, `while`, `try`, `with`, `match` thêm một mức; `elif`
  không thêm; hàm lồng trong hàm đếm lại từ 0.
- G3: dòng không quá 120 ký tự.
- G4: mọi hàm có kiểu cho từng tham số (trừ `self`, `cls`) và kiểu trả.
- G5: không `except:` trần; `except Exception` và `except BaseException` phải `raise` lại.
- G6: không chuỗi đường dẫn có ổ đĩa Windows (`C:\...`, `F:/...`). URL không tính.

Claude đếm G1 và G2 bằng `docs/giao-viec/P1-DOT-1/kiem-claude/code_metrics.py`. Trên mã lúc bắt đầu
đợt, cổng của L phải báo đúng 13 hàm ở mục 2; lệch thì một trong hai bộ đếm sai, tìm cho ra trước
khi đi tiếp.

Test: không test nào ghi dưới `SERVER/` hay `TOOLS/server/columns/`; test dữ liệu thật ghi vào
`build/`. Test bắt output của công cụ nó gọi.

Bảng soạn tay (`column_terms.tsv`, `legacy_rules.tsv`, `scene_attach.tsv`) có hình dạng như
`table_names.tsv`: dòng `# schema`, dòng `# types:`, không có dòng `# tool:`. Mỗi bảng có test kiểm
hình dạng, khoá không lặp, giá trị cột thuộc tập cho phép.

## 6. Ranh giới và các bước

Ranh giới như mục 8 của đề bài đợt 1, với hai thay đổi: được ghi thêm vào `SERVER/config/rules/`
(chỉ thư mục đó, mười một tệp còn lại của `SERVER/config` không đụng), và thư mục báo cáo là
`docs/giao-viec/P1-DOT-2/`. `docs/giao-viec/P1-DOT-1/` chỉ đọc. Cây làm việc vẫn có thay đổi chưa
commit của phiên client; git chỉ dùng lệnh đọc.

Các bước như mục 9 của đề bài đợt 1, với các thay đổi sau.

Bước 1: mỗi vai làm theo thứ tự tách hàm, chạy `treehash.py` và so với mốc (phải trùng), rồi mới
trả nợ đổi đầu ra và làm việc mới. Dán hai lần băm vào báo cáo.

Bước 2, R review. Như đợt 1, thêm:

- Chạy `lint_py.py` và tự đếm lại bằng mắt ba hàm bất kỳ để tin bộ đếm.
- Chạy `treehash.py` trước và sau T2: test không được đổi cây thật.
- Lấy mẫu ngữ nghĩa, hạt giống 20261007: 30 dòng của `column_terms.tsv` và 40 dòng `fate=rule` của
  `legacy_rules.tsv`. Với mỗi dòng mở đúng căn cứ ghi ở `basis` và xếp `đúng`, `sai` hoặc `không đủ
  căn cứ`, kèm một câu lý do cho hai loại sau. Ghi cả ba con số.
- Với phép căn cột của A: tự chọn ba bảng, tự tìm bằng script riêng một cột bị ghép sai nếu có.

Bước 4, R phán quyết trên mã cuối cùng: chạy lại đủ T1 tới T10 sau mọi lần sửa, kể cả lệnh sinh cả
cây trên dữ liệu thật. Lời cuối của R phải nói về trạng thái cuối, không phải trạng thái lúc review.

## 7. Tiêu chí đạt

`<tlbb>` và `<_raw>` như đợt 1. Lệnh chạy ở gốc dự án.

| Mã | Lệnh hoặc phép kiểm | Đạt khi |
|---|---|---|
| T1 | `python -W error -m unittest discover -s TOOLS/server -p "test_*.py"`, không đặt biến môi trường | xanh; output chỉ có dòng của `unittest` |
| T2 | cùng lệnh, đã đặt hai biến | xanh, không test nào bị bỏ qua |
| T3 | `python -W error TOOLS/server/build_data.py --legacy "<tlbb>" --raw "<_raw>"` | thoát 0, in tổng kết từng thư mục đích |
| T4 | cùng lệnh thêm `--digest`, hai lần | hai mã SHA-256 bằng nhau; ghi mã vào `KET-QUA.md` |
| T5 | `python -W error TOOLS/server/lint_py.py` | thoát 0 trên mọi `TOOLS/server/*.py` |
| T6 | `python TOOLS/server/lint_config.py`, rồi cùng lệnh với mọi `scene.toml` | sạch; số tệp của `SERVER/config` là 12 cộng số tệp luật đã sinh |
| T7 | `treehash.py` trước và sau T2 | năm dòng băm không đổi |
| T8 | `python docs/giao-viec/P1-DOT-1/kiem-claude/verify_p1.py` | A, B, C, D đều 0 lệch; dòng nào báo lệch vì thay đổi có chủ đích của đợt này thì nêu dòng đó và lý do, không sửa script |
| T9 | phủ kín | mọi cặp (section, khoá) của tệp nguồn luật có đúng một dòng trong `legacy_rules.tsv`; 3.251 tệp cảnh đã phân loại, 0 tệp chưa gắn, 45 tệp có trong `scene_attach.tsv`; 76 cặp bảng có dòng trong `column_alignment.tsv` |
| T10 | `git status --short` so với `moc/git-status.txt`; tìm `Account.txt` và mật khẩu | thay đổi của đợt chỉ nằm trong chỗ được phép; không có nội dung bí mật |

Tiêu chí không đạt thì ghi không đạt kèm output.

## 8. Báo cáo

Mọi tệp ở `docs/giao-viec/P1-DOT-2/`, cùng tên và cùng hình dạng như mục 11 của đề bài đợt 1:
`BAO-CAO-A.md`, `BAO-CAO-B.md`, `BAO-CAO-C.md`, `REVIEW.md`, `DOI-CHAT-A.md`, `DOI-CHAT-B.md`,
`DOI-CHAT-C.md`, `KET-QUA.md`, script kiểm của R ở `kiem/`. Thêm vào báo cáo của từng vai:

- Bảng nợ: từng mã `C-` của mình, đã trả hay chưa, lệnh chứng minh.
- A: bảng tóm tắt căn cột của mười một bảng ưu tiên; số thuật ngữ theo từng loại `basis`.
- B: số khoá theo từng `fate`; danh sách khoá `unknown`; chỗ giá trị ini khác tệp TOML tiến trình;
  tệp luật nào chưa sinh.
- C: số lời gọi theo `how`; kết quả đối chiếu 1.344 tệp; nội dung `scene_attach.tsv`.

`KET-QUA.md` thêm một mục: mã SHA-256 của `--digest`, và bảng nợ gộp C-01 tới C-08.

## 9. Ngoài phạm vi

Để các đợt sau: tên cột của bảng máy chủ (1.814 cột còn `?`) ngoài phần đổi bằng máy, 91 tên bảng
còn `?`, `diff_tables.py`, `thienlong_lint` và mọi mã C++, mọi thay đổi ở `CMakeLists.txt` và
`vcpkg.json`, `ai_convert.py`, `lua_extract.py`, nấu lưới đi, định dạng `.path`, `.stall`,
`.ObjRegion`, dịch nội dung bảng sang tiếng Việt, và việc chuyển tệp cảnh giữa các thư mục cảnh.

Thấy vấn đề ngoài phạm vi thì ghi vào báo cáo, không tự sửa.
