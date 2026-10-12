# Đề bài P2 đợt 1: đọc cấu hình, điều khiển tiến trình, bảy exe rỗng

Soạn ngày 2026-10-07 cho Grok Build. Người kiểm cuối là Claude; người duyệt là chủ dự án.

## 1. Việc này là gì

Mốc P1 (dữ liệu) đã đạt đủ bốn tiêu chí của `docs/KE-HOACH-SERVER.md`: một lệnh sinh lại cả cây,
`thienlong_lint` 0 lỗi, `diff_tables.py` in độ phủ, lưới đi trùng nguồn. Đợt này mở mốc P2 (nền
máy chủ). P2 chia ba đợt:

- Đợt 1, tệp này: module `config`, `process`, `supervise`, `service`; bảy exe rỗng chạy theo thứ
  tự, in `ready`, dừng êm; `cmake --install` vào `SERVER/bin`; `thienlong_lint` kiểm cả TOML.
- Đợt 2: `net`, `protocol`, `gen_protocol.py`, fuzz bộ giải mã.
- Đợt 3: `secure`, `ipc`, `metrics`; các tiến trình nối với nhau.

Kèm theo là nợ dữ liệu của P1 đợt 3 (mục 2). Xong đợt này, ba trên bốn tiêu chí của P2 phải đạt:
bảy exe khởi động theo thứ tự rồi dừng êm; `cmake --install` chép chúng vào `SERVER/bin`; cấu hình
sai khoá bị từ chối kèm số dòng.

Tổ chức như các đợt trước: bạn là phiên chính L; A, B, C viết mã song song; R review trong phiên
mới; đối chất chéo; L ghi `KET-QUA.md`. Khác trước ở một chỗ: L có phần mã tích hợp (bước 1b) và
phần đó cũng phải qua R. Giao việc cho subagent bằng đường dẫn tệp này và tên vai. Làm trực tiếp
trong `F:\tl 2026\THIENLONG`, không dùng worktree.

Đọc trước khi viết mã, theo thứ tự:

1. Tệp này.
2. `AGENTS.md` của dự án, trọn mục 2 tới mục 11. Mục 11 vừa có thêm một bẫy đã đo về
   `tomlplusplus` dưới `check.py`.
3. `docs/giao-viec/P1-DOT-3/DE-BAI.md` mục 5.5 (luật mã C++ của đợt) và mục 6; các mục về hợp đồng
   TSV, cổng `lint_py.py`, luật test của hai đợt đầu vẫn có hiệu lực.
4. `docs/giao-viec/P1-DOT-3/KET-QUA.md` và `REVIEW.md`.
5. `docs/KE-HOACH-SERVER.md` mục 3, 5, 6, 11; `SERVER/README.md`; mười một tệp
   `SERVER/config/*.toml` (không mở `secrets.local.toml`); `docs/SERVER-TEP-CAU-HINH.md` mục 1, có
   bảng thuật ngữ thuộc tính và chiến đấu mới thêm.
6. Vai B và L đọc thêm, chỉ đọc, trong `G:\TLBB\Dev`: `src\platform\process.hpp`,
   `process_win32.cpp`, `process_posix.cpp`, `console.hpp`, `console.cpp`,
   `src\server\supervise.cpp`, và phần khởi động, dừng của `docs\SERVER.md`.

## 2. Kết quả kiểm đợt 3 và nợ phải trả

Claude chạy lại T1 tới T14 bằng lệnh của mình, đều ra kết quả như `KET-QUA.md`:

- 211 test Python xanh, không bỏ qua (514,9 giây). `build_data.py --digest` hai lần cùng mã
  `29a45614a089d6f506b7ffd4d178f365a1935862f7b6a01a28438d1561b8633f`; năm dòng băm không đổi.
- Ba trình dịch dựng lại `lint.cpp`, `main.cpp`, `content_tests.cpp` từ đầu: 0 cảnh báo; ba test
  xanh ở `gcc-debug`, `clang-asan` (50 giây cho cây thật dưới ASan), `msvc-release` (2,2 giây).
  `check.py` 4 tệp, 0 lỗi.
- Script thứ ba, `docs/giao-viec/P1-DOT-3/kiem-claude/verify_p3.py`, đếm lại cả 55 dòng tham chiếu
  mà không dùng mã của bạn: trùng `table_ref_coverage.tsv` từng ô. Ba bản cài đặt độc lập, một
  kết quả. 22.019.096 ô, không ô số nào lệch dạng chính tắc. `files_on_disk` trùng cả 250 dòng.
- Exe `msvc-release` trên cây thật: 2.164 ms, bộ nhớ đỉnh 239,5 MiB (lấy mẫu 20 ms một lần).

Nợ. Mã `E-` là finding của Claude ở đợt 3. Đợt này vai C là chủ mọi tệp Python của `TOOLS/server`
và của `SRC/content`, `SRC/linttool`.

**E-01 (C): hai bảng thuật ngữ dịch cùng một chữ thành hai từ.** Đề bài đợt 3 chỉ cấm trùng khoá
(`original`, `scope`), nên hai vai dịch lệch nhau mà không cổng nào báo. Đo bằng `verify_p3.py N`:
48 nhãn nguyên văn có hơn một tên (`物理防御` là `physical_defence` và `physical_defense`; `闪避`
là `dodge` và `miss`; `冰攻击` là `cold_attack` và `ice_attack`; `死后是否保留` là
`keep_after_death` và `kept_after_death`). Trong tên cột đã sinh: `defence` 28 lần và `defense` 19;
`cold` 12 và `ice` 9; `dodge` 4 và `miss` 6; `dexterity` 3 và `agility` 13; `concentration` 16 trong
khi enum gốc là `INT`; `mp` 17 và `mana` 6; `restore` 6 và `regen` 4. Phụ lục mục 1 đã có bảng 15
dòng chốt từ cho các chữ này. Việc phải làm:

- `TOOLS/server/term_morphemes.tsv`: bản máy đọc của bảng đó (`chinese`, `name`, `banned`,
  `basis`), có test so với phụ lục như `test_glossary.py`.
- Hai luật mới trong `lint_names.py`. N3: dòng thuật ngữ có `original` chứa một chữ của bảng thì
  `name` phải có từ dùng và không có từ cấm. N4: một `original` chỉ có một `name` trên mọi `scope`
  và trên cả hai tệp. Ngoại lệ của N3 và N4 ghi từng dòng vào `name_exceptions.tsv` kèm lý do.
- Sửa hai bảng thuật ngữ cho tới khi cổng sạch. Sau khi sinh lại, `verify_p3.py N` phải in 0 cho
  `defense`, `ice`, `miss`, `agility`, `concentration`, `mana`, `regen`, và số nhãn có hơn một tên
  bằng đúng số ngoại lệ N4 đã ghi.

**E-02 (C): bốn chỗ trong tệp luật.** `[start_position]` có `position_x`, `position_z` là mảng
nhưng `scene0`, `scene1`, `scene2` là ba khoá rời: gộp thành mảng `scene`, cùng thứ tự. `[attribute]`
đang là `str`, `spr`, `con`, `int`, `dex` với chú thích `Giá trị str.`: đổi theo bảng thuật ngữ
(`strength`, `spirit`, `constitution`, `intellect`, `dexterity`), chú thích nói đó là điểm thuộc
tính ban đầu, `basis` dẫn `Common/GameDefine_Attr.h:10` tới dòng 14. `[inner_art] number` thành
`count` như các nhóm bên cạnh. `default_move_speed_permille` không phải tỉ lệ: bỏ hậu tố
`_permille`; chú thích giữ câu "mã chia cho 1000" và ghi đơn vị nếu mã xác lập được, không thì
`Đơn vị chưa xác lập.`

**E-03 (C): mã C++ của `content` và `linttool`.**

- `SRC/content/lint.cpp` dài 1.226 dòng, chứa năm việc: kiểm UTF-8, đọc phần đầu tệp và kiểm ô,
  khớp mẫu đường dẫn, đọc `refs`, đếm độ phủ. Tách theo việc, mỗi tệp `.cpp` không quá 500 dòng,
  mỗi việc có header riêng trong `content/`. Hành vi và báo cáo không đổi một byte.
- `lint_texts` nhận mọi tệp cùng lúc, nên exe giữ cả cây trong bộ nhớ: đỉnh 239,5 MiB cho 245 MB
  bảng. Đổi sang giao diện đưa từng tệp một (tạo phiên, đưa tệp, chốt), exe đọc tệp nào đưa tệp ấy
  rồi bỏ. Đích: đỉnh bộ nhớ trên cây thật ở `msvc-release` không quá 120 MiB; đo và ghi số.
- Lỗi bị nuốt trong `main.cpp`: `collect_dir` bỏ kết quả duyệt thư mục (`static_cast<void>(walked)`),
  nên duyệt hỏng giữa chừng vẫn có thể ra "0 lỗi"; thiếu thư mục `tables` hoặc `scenes` vẫn thoát 0;
  ghi báo cáo hỏng trả mã 2 của "sai cách dùng". Mỗi trường hợp phải thành lỗi có câu, mã thoát 1.
- Dòng tên cột của tệp `refs` không được kiểm: đổi thứ tự cột là đọc sai mà không báo. Kiểm đúng
  tám tên theo thứ tự.
- Mẫu có hai `*` trong một đoạn đường dẫn: C++ lặng lẽ coi là không khớp. Chốt: mỗi đoạn tối đa
  một `*`; cả `table_refs.py` lẫn exe báo lỗi hình dạng cho dòng đó. Mục 5.2 của đề bài đợt 3 hiểu
  theo câu này.
- Tên viết tắt tự chế trái luật đặt tên: `ChildAcc`, `acc`, `col`, `SegStep`. Biến `valid` trong
  `check_names` được tính rồi bỏ. Sửa.

**E-04 (L): dọn.** `build/p1-d3-stage1`, `build/p1-d3-stage2`, `build/p1-dot3-r` và các thứ cũ ở
mục 6 của `KET-QUA.md` đợt 3: xoá những thứ do các đợt của bạn sinh ra, liệt kê dung lượng đã giải
phóng. Không xoá build tree của preset và thứ không do bạn tạo.

Không phải nợ của đợt này, ghi để biết: bảng `refs` có 55 dòng nhưng chỉ 21 quan hệ khác nhau (36
dòng là hai họ cột đánh số); `drop_packages` sang bảng vật phẩm cần cột cha là hợp của nhiều bảng,
hình dạng hiện tại chưa viết được. Việc đó làm trước mốc P5.

## 3. Điều Claude đã đo cho đợt này

`tomlplusplus` 3.4.0, thử bằng một tệp 20 dòng dưới `check.py` (ghi ở mục 11 của `AGENTS.md`):

- Thư mục include đưa bằng `-I`: GCC 16 và Clang 23 đều dừng ở `operator"" _toml` của thư viện;
  clang-tidy soi cả header của thư viện, ra hàng trăm lỗi.
- Đưa bằng `-isystem` qua biến trình dịch: GCC sạch, Clang sạch, chạy dưới ASan và UBSan sạch;
  `toml::parse` không exception trả đúng giá trị và đúng số dòng nguồn. Lệnh, chạy ở gốc dự án:
  `CPP23_G14="g++ -isystem <inc>" CPP23_G15="g++ -isystem <inc>" CPP23_C20="clang++ -isystem <inc>"
  CPP23_CLANG_TIDY="clang-tidy --extra-arg=-isystem<inc>" python ~/.claude/cpp23/tools/check.py
  <tệp>`, với `<inc>` là `vcpkg_installed/x64-windows-static-md/include`.
- clang-tidy còn đòi hai thứ ở chính tệp include thư viện: NOLINT `cppcoreguidelines-macro-usage`
  quanh `#define TOML_EXCEPTIONS 0` và `#define TOML_HEADER_ONLY 1`; NOLINT `misc-include-cleaner`
  cho các kiểu `toml::`, vì thư viện chỉ cho include tệp ô `toml.hpp`.

Dựng: preset `clang-asan`, `msvc-debug`, `msvc-release` dùng vcpkg, triplet
`x64-windows-static-md`, thư mục cài chung `vcpkg_installed/` ở gốc dự án. Preset `gcc-debug` không
dùng vcpkg. `vcpkg.json` chưa có `tomlplusplus`. `CMAKE_INSTALL_PREFIX` của mọi preset là `CLIENT`.

Mười một tệp cấu hình tiến trình có 140 khoá: `admin` 3, `auth` 17, `billing` 12, `cluster` 36,
`gate` 13, `log` 5, `secrets.example` 5, `store` 7, `supervisor` 17, `world` 8, `zone` 17. Claude
vừa thêm nhóm `[stop]` với `timeout_seconds = 30` vào `supervisor.toml`.

Dự án tham chiếu `G:\TLBB\Dev` (đã khảo sát): chỉ có bốn tiến trình; không có module `config`,
không TOML, không PostgreSQL, không `metrics`, không công cụ sinh mã giao thức; include kiểu phẳng.
Thứ dùng được cho đợt này: `platform\process.hpp` 61 dòng, `process_win32.cpp` 275,
`process_posix.cpp` 224, `console` 23 và 90, `server\supervise.cpp` 557. Ở đó con in `ready` ra
stdout, log ra stderr; giám sát dừng con bằng cách đóng stdin của nó, chờ 3 giây rồi buộc dừng.
`supervise.cpp` không có test.

## 4. Thiết kế đã chốt

### 4.1 Module

| Module | Vai | Được include | Việc |
|---|---|---|---|
| `SRC/config/` | A | `core` | chữ TOML thành struct đã kiểm miền; khoá lạ là lỗi |
| `SRC/process/` | B | `core` | chạy tiến trình con, ống stdin và stdout, chờ, buộc dừng; nơi duy nhất include header tiến trình của hệ điều hành |
| `SRC/supervise/` | B | `core` | máy trạng thái khởi động, chạy lại, dừng; không đụng hệ điều hành, không đọc đồng hồ |
| `SRC/service/` | L | `core`, `io`, `config`, `process` | khung chung của một tiến trình máy chủ |
| `SRC/supervisor/`, `gated/`, `authd/`, `billingd/`, `worldd/`, `zoned/`, `stored/` | L | các module trên | mỗi thư mục một `main.cpp` |
| `SRC/content/`, `SRC/linttool/` | C | như đợt 3 | E-03 |

Exe: `thienlong_server` (thư mục `supervisor`), `thienlong_gate`, `thienlong_auth`,
`thienlong_billing`, `thienlong_world`, `thienlong_zone`, `thienlong_store`. Namespace
`game::<module>`. Include dạng `"<module>/x.hpp"`. Mã port từ Dev ghi `Nguồn:` và `Khác gốc:` đầu
tệp; danh sách tệp port ghi vào `docs/giao-viec/P2-DOT-1/NGUON.md` để Claude chép sang
`docs/NGUON-TLBB.md`.

### 4.2 Giao kèo giữa các tiến trình

- Dòng lệnh: `thienlong_server --config <thư mục cấu hình> [--no-postgres]`. Tiến trình con:
  `thienlong_<loại> --config <thư mục cấu hình> [--id <n>]`. Exe con nằm cùng thư mục với exe giám
  sát. Đường dẫn có dấu cách phải chạy được: chính đường dẫn dự án có dấu cách.
- Tiến trình con ở đợt này: đọc và kiểm `cluster.toml`, `log.toml` và tệp của chính nó; in đúng
  một dòng `ready` ra stdout; chờ tới khi stdin đóng; thoát 0. Ngoài dòng đó không in gì ra stdout;
  log ra stderr. Cấu hình sai: in từng lỗi dạng `tệp:dòng: nội dung` ra stderr, thoát 2. Không mở
  cổng mạng nào, không mở `secrets.local.toml`.
- Giám sát kiểm mọi tệp cấu hình nó biết (của nó và của từng con) trước khi chạy bất cứ thứ gì;
  có lỗi thì in hết lỗi rồi thoát 2. Sau đó chạy từng bước của `[[start]]`: một tiến trình cho mỗi
  khối `[[process]]` cùng loại trong `cluster.toml` (kèm `--id`), riêng `gate` một tiến trình không
  có khối. Chờ dòng `ready` trong `ready_timeout_seconds` rồi mới sang bước sau.
- stdout của giám sát là cho máy đọc, đúng thứ tự: `started <loại> <id>` cho từng con (`started
  gate` không có id), rồi `ready`; lúc dừng `stopped <loại> <id>` theo thứ tự ngược. Mọi câu khác
  ra stderr, tiếng Việt.
- Dừng: stdin của giám sát đóng, hoặc Ctrl+C. Giám sát đóng stdin của con cuối cùng, chờ nó thoát
  trong `[stop] timeout_seconds`, quá hạn thì buộc dừng và ghi lỗi, rồi tới con trước đó. Giám sát
  chết bất ngờ thì ống đóng theo, con thấy stdin đóng và tự thoát: không tiến trình mồ côi.
- Con chưa `ready` mà hết hạn hoặc chết: dừng các con đã chạy theo thứ tự ngược, thoát 1. Con chết
  sau khi đã `ready`: chạy lại, tối đa `[restart] max_per_hour` lần mỗi giờ cho mỗi tiến trình; quá
  trần thì dừng cả cụm, thoát 1.
- Mã thoát của giám sát: 0 khi dừng theo yêu cầu và mọi con thoát 0; 1 khi có lỗi lúc chạy; 2 khi
  dòng lệnh hoặc cấu hình sai.
- PostgreSQL, khi `[postgres] managed = true` và không có `--no-postgres`: trước bước đầu, hỏi
  `pg_ctl status` với `bin_dir`, `data_dir` của `cluster.toml` (đường dẫn tương đối tính từ thư mục
  cấu hình). Đang chạy sẵn: in `using postgres`, lúc thoát không dừng nó. Chưa chạy: `pg_ctl start
  -w` với `log_file` và hạn `ready_timeout_seconds`, in `started postgres`; lúc thoát, sau con cuối
  cùng, `pg_ctl stop -m fast -w`, in `stopped postgres`. Cấm `initdb`, cấm ghi hay xoá bất cứ thứ gì
  dưới `SERVER/data`, cấm `-m immediate`.
- Dòng một tiến trình con gửi lên có trần 4 KiB; dài hơn là lỗi của con đó, không phải lý do để
  giám sát cấp phát thêm.

### 4.3 `config`

- Nhận chữ, trả struct; không mở tệp, không in. Đúng một tệp `.cpp` include `<toml++/toml.hpp>`
  (đặt ở `SRC/config/detail/`); phần còn lại của module và mọi module khác chỉ thấy kiểu của dự án.
- Mười một bộ đọc, mỗi bộ một struct: `cluster`, `supervisor`, `log`, `gate`, `auth`, `billing`,
  `world`, `zone`, `store`, `admin`, `secrets` (theo `secrets.example.toml`; test dùng chuỗi trong
  mã, không bao giờ mở `secrets.local.toml`). Thêm một phép kiểm chung cho tệp chưa có struct
  (`rules/*.toml`, `scene.toml`): đọc được và có `schema = 1`.
- Mỗi bộ đọc trả struct hoặc danh sách lỗi `{dòng, câu}`: đọc hết tệp, báo mọi lỗi một lượt, xếp
  theo dòng. Lỗi gồm: cú pháp; `schema` khác 1; khoá hoặc nhóm lạ; thiếu khoá; sai kiểu; ngoài
  miền; phần tử của `[[...]]` sai; cặp (`kind`, `id`) lặp trong `cluster`.
- Mọi khoá đang có trong tệp là bắt buộc, trừ khi chú thích của khoá nói khác. Miền của từng khoá
  lấy từ chú thích tiếng Việt và nghĩa của khoá (cổng 1 tới 65535, thời lượng không âm, số lượng
  dương). Miền nào chú thích không nói mà A tự đặt thì liệt kê trong báo cáo để duyệt.
- Kiểu mạnh: thời lượng là `std::chrono` đúng đơn vị của tên khoá; cổng, id tiến trình là kiểu
  riêng; lựa chọn có tập đóng là `enum class`. Không `bool` cờ trần trong chữ ký hàm.
- Một phép kiểm chéo: mọi `process` của `[[start]]` thuộc tập `store`, `auth`, `billing`, `world`,
  `zone`, `gate`, không lặp, và mỗi loại trừ `gate` có ít nhất một khối trong `cluster.toml`.

### 4.4 `process` và `supervise`

- `process`: port từ Dev, viết lại theo luật của dự án. Chạy một exe với danh sách đối số; stdin
  và stdout của con là ống do cha giữ, stderr thừa hưởng. Đọc một dòng của con có hạn chờ; đóng
  stdin của con; chờ con thoát có hạn; buộc dừng. Huỷ đối tượng khi con còn sống thì buộc dừng rồi
  chờ, không để lại tiến trình. Cho cả con lẫn giám sát: một câu hỏi không chặn "đã có yêu cầu dừng
  chưa", đúng khi stdin đã đóng hoặc tiến trình đã nhận Ctrl+C, Ctrl+Break hay lệnh đóng cửa sổ. Bản Windows phải dựng
  và chạy test; bản POSIX port theo nhưng máy này không dựng được, ghi rõ "chưa dựng" trong báo cáo.
- `supervise`: máy trạng thái thuần. Bên gọi đưa kế hoạch (các bước, hạn chờ, trần chạy lại), một
  giao diện để chạy và hỏi tiến trình, và thời điểm hiện tại ở mỗi lời gọi. Không include `process`,
  không đọc đồng hồ. Test dùng bộ chạy giả và đồng hồ giả cho từng nhánh ở mục 4.2: đúng thứ tự,
  hết hạn chờ `ready`, con chết trước `ready`, con chết sau `ready` và trần chạy lại, dừng ngược
  thứ tự, quá hạn dừng thì buộc dừng, PostgreSQL chạy sẵn và chưa chạy.
- Exe phụ cho test, không cài: `thienlong_test_child` (`tests/support/server_child.cpp`), có đối số
  để in `ready` trễ, không bao giờ `ready`, thoát với mã cho trước, chết sau `ready`, lờ stdin, in
  một dòng dài quá trần.

### 4.5 Dựng, kiểm, cài

- L sửa ba tệp có sẵn, chỉ thêm dòng: `vcpkg.json` (thêm `tomlplusplus`), `CMakeLists.txt`,
  `cmake/GameLayers.cmake`. `CMakePresets.json` không đụng. Vai khác không sửa ba tệp này.
- Thư viện TOML vào CMake như một target giao diện chỉ mang thư mục include `SYSTEM`; không nối
  target của vcpkg (bẫy ở mục 11 của `AGENTS.md`). Hai `#define TOML_*` nằm trong mã nguồn. Ở preset
  không dùng vcpkg, tìm header trong `vcpkg_installed/x64-windows-static-md/include`; không thấy thì
  không khai `config` và các thứ phụ thuộc nó, in một dòng trạng thái.
- Trong lúc ba vai làm song song, danh sách nguồn của module mới lấy bằng `file(GLOB ...
  CONFIGURE_DEPENDS)` để không ai phải sửa CMake; ở bước 1b L đổi thành danh sách tường minh như
  phần còn lại của tệp.
- Mỗi vai dựng trong thư mục riêng: `cmake --preset clang-asan -B build/p2-<vai>`, rồi `cmake
  --build build/p2-<vai> --target <target của mình>`, `ctest --test-dir build/p2-<vai> -R <test của
  mình>`. Ở bước 1 không vai nào dựng trong `build/gcc-debug`, `build/clang-asan`, `build/msvc-*`:
  các thư mục đó chỉ L và R dùng, lần lượt.
- Cài: các exe máy chủ và `thienlong_lint` có luật cài với `COMPONENT server EXCLUDE_FROM_ALL`.
  Lệnh: `cmake --install build/msvc-release --component server --prefix SERVER`. Lệnh cài mặc định
  của client không được chép exe máy chủ vào `CLIENT/bin`.
- `thienlong_lint` thêm luật K6: đọc `<gốc>/config/*.toml` trừ tệp có đuôi `.local.toml`,
  `<gốc>/config/rules/*.toml` và `<gốc>/scenes/*/scene.toml`. Mười một tệp tiến trình đi qua bộ đọc
  có struct, phần còn lại qua phép kiểm chung. Lỗi in như các luật khác: `config/gate.toml:12: khoá
  lạ ...`.
- Luật mã C++ như mục 5.5 của đề bài P1 đợt 3. Thêm: không tệp `.cpp` nào quá 500 dòng; dữ liệu từ
  tiến trình con và từ tệp cấu hình là dữ liệu ngoài, kiểm trần trước khi cấp phát; không
  `std::system`, không gọi shell.

## 5. Việc của từng vai

### L

Bước 0, một mình: ghi mốc vào `docs/giao-viec/P2-DOT-1/moc/` (`git-status.txt`, `treehash.txt`,
bản chép của `CMakeLists.txt`, `cmake/GameLayers.cmake`, `vcpkg.json`); thêm `tomlplusplus`, target
include, khai các module và test mới với tệp khung rỗng, đưa đường dẫn `SERVER/config` cho
`config_tests` bằng một định nghĩa lúc biên dịch; cấu hình và dựng ba preset `gcc-debug`,
`clang-asan`, `msvc-release` cho tới khi cây có khung dựng được và `layers` xanh. Trả E-04.

Bước 1b, sau khi A, B, C xong: viết `SRC/service/` và bảy `main.cpp`; nối `config` vào
`thienlong_lint` (K6); luật cài; test đầu cuối `server_boot` (mục 7, T14); đổi glob thành danh sách
tường minh; dựng và chạy ba preset.

Bước 5: chạy đủ mục 7, ghi `KET-QUA.md`.

### A: `config`

`SRC/config/**`, `tests/config_tests.cpp`. Test đỏ trước. Mỗi bộ đọc có: một ca đọc đúng nguyên văn
tệp thật (chép nội dung tệp vào chuỗi trong test là không được, vì hai bản sẽ lệch: test đọc tệp
thật qua đường dẫn do CMake đưa, trừ `secrets`), một ca khoá lạ có số dòng, một ca thiếu khoá, một
ca sai kiểu, một ca ngoài miền cho mỗi loại miền. Báo cáo: bảng 140 khoá với kiểu và miền đã đặt,
đánh dấu miền tự đặt.

### B: `process`, `supervise`

`SRC/process/**`, `SRC/supervise/**`, `tests/process_tests.cpp`, `tests/supervise_tests.cpp`,
`tests/support/server_child.cpp`. Test đỏ trước. `process_tests` chạy exe phụ thật: đường dẫn có
dấu cách, đối số có dấu cách và dấu nháy, dòng dài quá trần, con lờ stdin phải bị buộc dừng đúng
hạn, huỷ đối tượng không để lại tiến trình.

### C: nợ dữ liệu và `content`

E-01, E-02, E-03. Thứ tự: E-03 trước (tách tệp, hành vi không đổi: báo cáo `--report` trên cây thật
trùng từng byte với trước khi tách), rồi giao diện từng tệp, rồi E-01 và E-02. Sau E-01 và E-02 chạy
lại `build_data.py`; ô dữ liệu không được lệch (`verify_p1.py`).

## 6. Ranh giới và các bước

Ranh giới như mục 6 của đề bài P1 đợt 3, với các thay đổi:

- Được tạo mới: các thư mục và tệp nêu ở mục 4.1 và mục 5, `TOOLS/server/term_morphemes.tsv`,
  `tests/support/`, và `docs/giao-viec/P2-DOT-1/`.
- Được sửa bằng cách chỉ thêm dòng, chỉ L: `CMakeLists.txt`, `cmake/GameLayers.cmake`,
  `vcpkg.json`. So với bản chép ở `moc/`, không dòng cũ nào bị xoá hay đổi.
- Không sửa `SRC/core`, `SRC/io`, `SRC/table` và mọi module của client; thiếu gì thì viết trong
  module mới và báo. Không sửa `AGENTS.md`, `docs/*.md`, mười một tệp TOML tiến trình,
  `setup_db.py`, `config_style.py`, `lint_config.py`, `CMakePresets.json`.
- Không mở, không in, không chép `SERVER/config/secrets.local.toml` và `Server\Config\Account.txt`.
- PostgreSQL thật chỉ được chạy đúng một lần, bởi L, ở T15. Trước và sau lần đó ghi output của
  `python TOOLS/server/setup_db.py status`.
- Git chỉ dùng lệnh đọc. Không commit.

Các bước: 0 (L), 1 (A, B, C song song), 1b (L tích hợp), 2 (R review), 3 (đối chất chéo: A xem B, B
xem C, C xem A), 4 (sửa, rồi R phán quyết trên mã cuối), 5 (L ghi kết quả).

Bước 2, R review. Như đợt 3, thêm:

- Mã của L ở bước 1b được review như mã của một vai.
- Thử phá `config`: TOML cụt, số vượt `int64`, khoá lặp, nhóm lặp, kiểu lẫn trong mảng, chuỗi có
  byte UTF-8 hỏng, tệp rỗng. Mỗi ca phải ra lỗi có số dòng, không dừng chương trình.
- Thử phá `process` và giám sát bằng exe phụ: con không bao giờ `ready`, con in liên tục không
  xuống dòng, con chết ngay, con lờ stdin; giết giám sát giữa chừng rồi đếm tiến trình
  `thienlong_*` còn sống sau 5 giây (phải là 0).
- Lấy mẫu ngữ nghĩa, hạt giống 20261009: 30 khoá cấu hình, so miền đã đặt với chú thích của khoá;
  30 dòng thuật ngữ đã sửa theo E-01, so với bảng của phụ lục.

## 7. Tiêu chí đạt

`<tlbb>` và `<_raw>` như các đợt trước. Lệnh chạy ở gốc dự án.

| Mã | Lệnh hoặc phép kiểm | Đạt khi |
|---|---|---|
| T1 | `python -B -W error -m unittest discover -s TOOLS/server -p "test_*.py"`, không đặt biến | xanh |
| T2 | cùng lệnh, đã đặt hai biến | xanh, không test nào bị bỏ qua |
| T3 | `python -B -W error TOOLS/server/build_data.py --legacy "<tlbb>" --raw "<_raw>"` | thoát 0 |
| T4 | cùng lệnh thêm `--digest`, hai lần | hai mã bằng nhau; ghi mã vào `KET-QUA.md` |
| T5 | `python -B -W error TOOLS/server/lint_py.py` | thoát 0 |
| T6 | `python -B TOOLS/server/lint_config.py`, rồi cùng lệnh với mọi `scene.toml` | 18 tệp sạch (đầu đợt 249 cài đặt; E-02 gộp ba khoá `scene` thành một); 244 `scene.toml` sạch |
| T7 | `treehash.py` trước và sau T2 | năm dòng băm không đổi |
| T8 | `verify_p1.py`, `verify_p2.py`, `verify_p3.py` | `verify_p1` như đợt 3 (25 và 61 ô có chủ đích); `verify_p3` H, J, L 0 lệch; N như E-01; dòng lệch do E-02 thì liệt kê |
| T9 | `python -B -W error TOOLS/server/lint_names.py` | thoát 0 với N1 tới N4 |
| T10 | `python -B -W error TOOLS/server/diff_tables.py "<tlbb>" SERVER --check` | thoát 0 |
| T11 | ba preset: `cmake --preset <p>`, dựng mọi exe và test mới cùng `header_check`, rồi `ctest --preset <p>` với bảy test ghi dưới bảng | 0 cảnh báo; bảy test xanh ở cả `gcc-debug`, `clang-asan`, `msvc-release` |
| T12 | `check.py` trên mọi tệp C++ mới hoặc đã sửa (tệp include TOML dùng lệnh ở mục 3) | 0 lỗi |
| T13 | exe `msvc-release`: `thienlong_lint --root SERVER --refs TOOLS/server/refs --report build/p2-l/cpp-coverage.tsv` | thoát 0, `lỗi` 0; có đọc các tệp TOML; báo cáo trùng `table_ref_coverage.tsv` sau khi bỏ dòng `#`; đỉnh bộ nhớ không quá 120 MiB |
| T14 | test `server_boot`: `thienlong_server --config SERVER/config --no-postgres` với stdin đã đóng | stdout đúng 13 dòng theo mục 4.2 (sáu dòng `started` theo thứ tự `store`, `auth`, `billing`, `world`, `zone`, `gate`; `ready`; sáu dòng `stopped` theo thứ tự ngược), thoát 0. Chép thư mục cấu hình sang `build/`, thêm một khoá lạ vào `gate.toml`: thoát 2, stderr có `gate.toml:<dòng>:`, không tiến trình nào được chạy |
| T15 | `cmake --install build/msvc-release --component server --prefix SERVER`; rồi `SERVER/bin/thienlong_server --config SERVER/config` với stdin đã đóng | `SERVER/bin` có tám exe; `CLIENT/bin` không thêm exe máy chủ; stdout đúng 15 dòng, `started postgres` đầu và `stopped postgres` cuối; thoát 0; `setup_db.py status` trước và sau đều báo cụm không chạy; không còn tiến trình `thienlong_*` hay `postgres` |
| T16 | `git status --short` so với `moc/git-status.txt`; `diff` ba tệp với bản ở `moc/`; tìm bí mật | tệp mới chỉ ở chỗ được phép; ba tệp chỉ thêm dòng; không có nội dung của `secrets.local.toml` hay `Account.txt` ở bất cứ đâu |

Bảy test của T11: `config_tests`, `process_tests`, `supervise_tests`, `content_tests`, `layers`,
`server_data_lint`, `server_boot`. Claude đo ngày 2026-10-07: `setup_db.py status` in `cụm không
chạy`; `cmake --preset gcc-debug -B <thư mục khác>` cấu hình được vào thư mục riêng.

Tiêu chí không đạt thì ghi không đạt kèm output.

## 8. Báo cáo

Mọi tệp ở `docs/giao-viec/P2-DOT-1/`, cùng tên và hình dạng như các đợt trước, thêm `NGUON.md`.
Riêng đợt này:

- A: bảng 140 khoá (tệp, nhóm, khoá, kiểu, miền, miền lấy từ chú thích hay tự đặt).
- B: tệp nào port từ tệp nào của Dev, khác gốc ở đâu; nhánh nào của mục 4.2 có test nào; thứ chưa
  dựng được (POSIX).
- C: bảng nợ E-01 tới E-03; trước và sau của `verify_p3.py N`; số dòng từng tệp của `content`; đỉnh
  bộ nhớ và thời gian trước và sau.
- L: ba tệp CMake và vcpkg đã thêm những dòng nào; output của T14 và T15 nguyên văn; thời gian từ
  lúc chạy giám sát tới dòng `ready`.
- Mỗi vai: lần chạy test đỏ, output `check.py`, và bốn mục Đã kiểm, Chưa kiểm, Giả định, Lệch quy
  tắc. Mỗi báo cáo vai được cập nhật sau lần sửa cuối.

## 9. Ngoài phạm vi

Để các đợt sau: `net`, `protocol`, `gen_protocol.py`, `secure`, `ipc`, `metrics`; `libpq` và
`store`; ghi log ra tệp theo `log.toml`; chạy như dịch vụ Windows; struct cho `rules/*.toml` và
`scene.toml`; bảy tệp luật còn lại; mở rộng bảng `refs`; 91 tên bảng còn `?`; cột nhãn rỗng của
bảng chỉ có ở bản 2026; commit.

Thấy vấn đề ngoài phạm vi thì ghi vào báo cáo, không tự sửa.
