# G0-K: hạ tầng E2E phía client

Làn K (`thienlong-14`), nền `bb8dd17e`. Gói chỉ là công cụ dev; không có tính năng người chơi nào
mới, nên không có chữ nào mới hiện trong giao diện. H2 đã chuyển sang việc đệm (HO-SO mục 5.11).

## Bằng chứng

- Móc có sẵn, script dùng lại đúng đường chuột đang đi (không viết đường thứ hai):
  - đi: `order_move` (`display/graphic/play.cpp:515`), đường `run_to_scene_point`;
  - nói chuyện, nhặt: nhánh sau khi trúng của `pick_npc` và `pick_foe` (`graphic/talk.cpp:147-199`),
    tách thành hàm dùng chung `start_talk`, `start_pick`;
  - ra chiêu: `press_slot` (`graphic/fight.cpp:411`); sự kiện: `posted_events`
    (`graphic/face.cpp:303`); chọn dòng: `pick_talk_option` (`ui/panel/npc_talk.hpp:144`);
  - bấm, gõ: bơm `control::InputEvent` (`kMove`, `kPress`, `kRelease`, `kText`) vào hàng `queued`
    của `Display::State`, tức đi qua `absorb` (`graphic/play.cpp:394`) như SDL; vị trí bấm lấy từ
    `gui::Hub::box(tên cửa sổ)` (`gui/sheet.hpp:409`). Không dùng chuột hay bàn phím hệ điều hành.
- Chụp: `plan_shot` chỉ chụp một lần, đường dẫn cố định (`graphic/frame.cpp:742-831`); đổi thành
  hàng yêu cầu chụp, giữ nguyên hành vi của `--shot`.
- Tần số quét: `RaisedRefresh` (`viewer/viewer_win32.cpp:807`), kích hoạt: `restore()` ở
  `viewer_win32.cpp:943` (SW_RESTORE) và `Window::show()` (SW_SHOW, `engine/window/window.cpp:961`).
- Mạng: mọi tin gửi qua `protocol::encode` rồi `send_frame` (8 chỗ, `session/session.cpp:492-803`),
  nhận qua `decode_game_server`, `decode_auth_server` (`session.cpp:683,820`). Mỗi kiểu tin có
  `kKind` (`protocol/messages.hpp`). Không sửa `src/shared/**`.

## Làm

1. `--script <tệp>` và `--shot-dir <thư mục>` (mặc định thư mục hiện hành). Một lệnh một dòng, `#`
   là chú thích. Bước: `wait N` (khung), `wait Ns` (giây), `wait play [giây]` (chờ vào game, mặc
   định 90 s), `shot tên`, `event TÊN|a|b`, `click cửa_sổ`, `type chữ`, `walk x,z` (một trong hai số có
   dấu `+` hay `-` thì cả cặp cộng dồn từ chỗ đứng: `+4,0` đi 4 m theo x, `0,+4` đi 4 m theo z), `talk id|tên`, `choose i`, `cast ô`, `pick`, `quit`. Mỗi bước in một
   dòng TSV `SCRIPT<TAB>số<TAB>lệnh<TAB>đối số<TAB>ok|fail<TAB>ms<TAB>ghi chú` (chữ `fail` ASCII, để
   dòng không phụ thuộc bảng mã của console), rồi một dòng `SCRIPT<TAB>end<TAB>số bước đã chạy<TAB>số
   bước hỏng`. Hết tệp là `quit`, `quit` giữa tệp bỏ các bước sau nó; bước hỏng hay quá hạn thì thoát
   mã 3 sau khi in; tệp sai cú pháp thì in `dòng N: …` và thoát mã 2 trước khi mở cửa sổ. Có `--script`
   thì không nâng tần số quét, cửa sổ tạo với `WS_EX_NOACTIVATE` và hiện bằng SW_SHOWNOACTIVATE.
2. `THIENLONG_NET_TRACE=<tệp>`: mỗi tin một dòng `giờ_ms<TAB>gửi|nhận<TAB>tên<TAB>trường chính`.
   Mật khẩu không bao giờ vào log.
3. `TOOLS/run/e2e_client.py <kịch bản>`: mở client bằng `Popen` (`SW_SHOWNOACTIVATE`,
   `cwd=dev/client/bin`, `THIENLONG_ACCOUNT`), gom stdout, ảnh, log mạng vào `build/e2e/G0/`, xét theo
   dòng `#! expect-…` trong tệp kịch bản (`exit`, `shots`, `net`, `file <đường dẫn> <regex>`,
   `sidecar <lệnh>` chạy song song từ lúc mở client, phải thoát mã 0 như bot `--peers` của M), ghi
   `report.txt`, mã thoát 0 hay 1. `expect-file` chỉ xét dòng mới của tệp kể từ lúc bắt đầu chạy (log
   cụm không bị dòng của lượt trước đánh lừa), `{account}` trong regex là tài khoản của lượt đó.

## Không làm (không có bằng chứng gốc hoặc không ai yêu cầu)

- Không dùng `SendInput`, `SetCursorPos` hay bất cứ thứ gì chạm chuột và bàn phím hệ điều hành.
- Không thêm điều kiện `wait` ngoài `play`; gói sau cần thì thêm cùng kịch bản của nó.
- Không ghi hình, không phát lại, không sửa `src/shared/**`, `dev/server/**`.
- Không viết test logic cho trình đọc kịch bản; E2E (kể cả một kịch bản sai cú pháp) là bằng chứng.
- Không đụng `ui/script/host.cpp` (H2 làm sau, việc đệm).

## Kịch bản và tiêu chí đạt

`TOOLS/run/e2e/g0.script`: tài khoản mới tự đăng nhập, tạo nhân vật, `wait play`, `shot g0-vao`,
`walk +0,+4`, `walk +0,-4`, `shot g0-di`, `quit`; bot sidecar `--peers 1`. Lệnh:
`py -X utf8 TOOLS/run/desk_watch.py py -X utf8 TOOLS/run/e2e_client.py TOOLS/run/e2e/g0.script --account <tên mới>`.
Đạt khi: thoát 0; hai ảnh; `net.log` có `SignIn`, `CreateCharacter`, `EnterGame`, `Move`; zone ghi
dòng vào cảnh và đi, bot thấy thực thể (hai điều này do M); `desk_watch` báo 0 ở vùng giam, nhảy vị
trí, cửa sổ ở trước.

## Kết quả đo ngày 2026-10-18 (cụm 7100/7101, exe máy chủ mới)

- `g0.script` với `e2ek0a3`: đạt (client thoát 0, bot thoát 0, 8 bước ok, 2 ảnh, net.log và zone log
  đủ). Báo cáo ở `build/e2e/G0/report.txt`.
- `desk_watch`: "cửa sổ mới hiện 1" là chính cửa sổ client, "hình con trỏ 2" là con trỏ
  đang-khởi-động của Windows (0x10007, 0,35 s) rồi về như cũ. Tiêu chí "0 cả năm loại" không đạt
  nguyên chữ; bốn tín hiệu đáng tin (vùng giam, nhảy vị trí, cửa sổ ở trước) đều 0.
- Phát hiện 1 (vào G1-K): Move đầu sau SceneEnter báo (16050,16050), gate kéo về (16500,16900).
  Arrive chỉ ép hero về chỗ máy chủ khi cảnh cục bộ đã nạp (`graphic/play.cpp`, nhánh `is_here`).
- Phát hiện 2 (6a đo bằng lưới `walk.path`, sửa lại nhận định ban đầu của K là "vùng bao kín"):
  điểm sinh (165,169) là tam giác vật cản, (164,169) đi được và có đường tới cả bốn NPC. Luật
  `plan_move` cho người đang đứng trong vật cản chỉ đi thẳng ra qua không quá một cạnh, nên NPC mà
  đoạn thẳng từ điểm sinh cắt từ hai cạnh trở lên (孙八爷, 洪大贵) bị từ chối tới khi nhân vật bước ra
  chỗ đi được. Không phải lỗi nạp lưới.
- `g0-talk.script` với 赵天师 (`e2ek0t2`): đạt. `talk` mở hộp thoại với NPC 140 sau 2,6 s, `choose 1`
  ok, hai ảnh đã xem (hộp thoại 赵天师 ba mục), `net.log` có gửi `Talk`, nhận `DialogOpen`, gửi
  `DialogChoose`, zone có `việc=nói`. Báo cáo ở `build/e2e/G0/talk/report.txt`.
- Bước `walk` tính ok cả khi máy chủ kéo về (ghi "bị kéo về N lần" ở ghi chú); gói sau cần coi kéo
  về là hỏng thì thêm tuỳ chọn cho bước, không đổi mặc định.

## Chưa kiểm

- `cast`, `pick`, `click`, `type`, `event`: đã biên dịch và đọc lại, chưa có kịch bản chạy thật
  (G1 dùng `click`, `type`; G4 dùng `cast`, `pick`).
- Cấu hình GCC (`display_none.cpp`) và Android, iOS với mã mới.
