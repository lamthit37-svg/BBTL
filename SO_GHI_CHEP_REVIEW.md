# SỔ GHI CHÉP REVIEW — AUDIT BỔ SUNG + CHUẨN HOÁ HEADER (2026-10-15)

BỔ SUNG PHIÊN TIẾP THEO (cùng ngày, sau commit e88b910e): chủ dự án đã chốt chuẩn khung mới
kiểu ENGINEHP (`/*====*/` 80 cột, AGENTS.md mục 0, tool mới có unittest) và CẤM dọn hàng loạt cây
("chạm tệp nào thì --fix tệp đó"). Toàn bộ mass-edit khung hộp cũ của phiên trước đã revert về HEAD
(trừ 8 tệp đang có việc dở của phiên khác, liệt kê ở mục 5). Số liệu header và H1/L5 dưới đây đã cập
nhật theo chuẩn mới; các phát hiện audit M1–M3/L1–L4 giữ nguyên hiệu lực (mã đã revert về đúng HEAD).

Ngày: 2026-10-15. Người làm: phiên agent hiện tại (đơn lẻ, không multi-agent).
Repo lúc audit: HEAD 0f5a1a47 rồi 77714693 (một phiên khác commit giữa lúc audit, xem mục 6).
Phạm vi đọc trực tiếp: engine/core (clock, system_posix, range), engine/net (reactor_win32, shard, socket),
engine/resource (model meshopt), engine/io, src/shared (protocol/wire, secure/handshake/record, account/rpc,
store/pg, link), src/server (gate/table/front/motion, guard/pace, zone/saver, billing/webhook, config),
src/client (session/session, online/bridge, face/luanum, display/graphic/frame, viewer_win32),
TOOLS/source_headers toàn bộ, TOOLS/server (gen_protocol, lint_config, export_gates), .gitignore,
dev/server/config/gate.toml, dev/server/sql/auth+ billing, release/server/config/gate.toml.

Quan hệ với sổ audit trước (docs/AUDIT-2026-10-15/SO-GHI-CHEP-REVIEW.md, 6 tác tử, P0–P3):
sổ đó giữ nguyên hiệu lực và KHÔNG liệt kê lại ở đây. Sổ này chỉ ghi MỚI (chưa có trong sổ đó),
hiệu lực lại một phần bằng chạy máy thật, và toàn bộ công việc header. Đối chiếu đã làm:
migrate/SQL (sổ cũ P? đã loại false-positive) — đọc lại pg.cpp:180-219 và từng tệp .sql, xác nhận
mỗi migration tự bọc BEGIN/COMMIT lũy đẳng nên KHÔNG phải lỗi; system_posix (sổ cũ không nêu,
AGENTS.md nêu sai) — xem L4; SECURE_DROP_LENGTH_CHECK (sổ cũ P0, Confirmed) — vẫn còn trong mã
(record.cpp:95-113) và vẫn chỉ do fuzz_secure.py --teeth bật, không có define ở build thường.

Lệch mẫu header của đề bài: ĐÃ HẾT HIỆU LỰC. Chủ dự án chốt cùng ngày (commit e88b910e,
AGENTS.md mục 0) dùng đúng mẫu ENGINEHP của đề bài (`/*====*/` 80 cột, TỆP/PHÂN HỆ/CHUẨN/CHỨC NĂNG/
TÁC GIẢ/TELEGRAM) thay khung hộp cũ. Mọi chuẩn hoá từ đây theo tool mới, từng tệp khi chạm, cấm dọn
hàng loạt cây. Khung hộp cũ trong phiên trước chỉ còn trên 8 tệp (mục 5), tool mới tự đổi khi chạm.

## 1. NHIỆM VỤ 1 — CHUẨN HOÁ HEADER (chuẩn cũ đã revert toàn bộ; chuẩn mới theo chủ dự án)

- Phiên trước chuẩn hoá 1330+8 tệp theo khung hộp cũ. Cùng ngày chủ dự án chốt khung ENGINEHP mới
  và cấm dọn hàng loạt, nên toàn bộ mass-edit cũ đã revert về HEAD bằng script kiểm từng tệp
  (chỉ revert khi HEAD == BASE 0f5a1a47 và diff chỉ là khung cũ + hấp thu comment đầu tệp, kiểm mất chữ
  ở cấp từ; mọi tệp của phiên khác giữ nguyên). Còn lại đúng 8 khung hộp cũ trên tệp đang có việc dở
  của phiên khác (TOOLS/port/luagen/gen_pool_natives.py, Test/Ui/ui_script_pool_tests.cpp,
  Test/Window/window_tests.cpp, engine/window/monitor.cpp/.hpp,
  src/client/face/ui/script/context.hpp/native_groups.hpp/native_pool.cpp) — tool mới tự đổi khi chạm.
- Trạng thái hiện tại theo tool mới (`--survey`): đúng 53, tự chuyển 739 + 542 kèm comment dưới khung,
  cần mô tả viết tay 193 (phụ lục A). TOML cấu hình ra khỏi phạm vi (đúng như H1 đòi hỏi).
  Worktree còn 20 tệp modified, tất cả là việc của phiên khác hoặc bẩn từ trước (liệt kê ở mục 5);
  52 tệp WEB/* bị xoá từ trước phiên, không đụng vào.
- Quy trình từ đây (AGENTS.md mục 0): chạm tệp nào thì `python -B TOOLS/source_headers/source_headers.py
  --fix <tệp>` cho tệp đó (`--describe m.json` khi thiếu comment); không dọn hàng loạt cây. Tệp sinh
  thì bộ sinh phải xuất khung (gen_protocol.py hiện chưa làm — xem H1).
- Bằng chứng revert: script safe_revert (kiểm HEAD==BASE + diff top-only + bảo toàn từ) revert qua
  5 lượt (khóa index tranh với phiên khác 2 lần, đợi rồi chạy tiếp); mọi revert là `git checkout HEAD`
  nguyên tệp nên byte về đúng HEAD; lint_config xanh lại "26 tệp sạch, 438 cài đặt"; 4 đầu ra
  gen_protocol không còn diff tồn dư; unittest của tool mới xanh 14/14.

## 2. PHÁT HIỆN MỚI (không có trong sổ audit trước; sắp xếp CRITICAL → LOW)

- [HIGH][CONFIRMED] TOOLS/source_headers mới vs lint_config vs gen_protocol — Lỗi: hai trong ba cổng đã hoà giải, còn cổng gen mở | Bằng chứng: tool mới (e88b910e) loại .toml khỏi scope (source_headers.py:53) đúng như đề xuất — lint_config xanh ổn định; nhưng gen_protocol.py:37-40 vẫn ghi messages.hpp/messages.cpp/protocol_samples.hpp bằng comment thường trong khi AGENTS.md bắt "tệp sinh thì bộ sinh xuất khung", nên 3 tệp này rớt check mới ("thiếu khung") vĩnh viễn cho tới khi gen học render_frame | Tác động: check mới không bao giờ sạch toàn cây; ai --fix 3 tệp này thì lần gen sau lột lại (đã đo) | Khắc phục: dạy gen_protocol gọi render_frame của tool mới, hoặc đưa 3 đầu ra vào EXCLUDED có văn bản | Trạng thái: MỞ MỘT PHẦN (TOML xong, gen còn) |
- [MEDIUM][CONFIRMED] src/server/gate/table.cpp:814-822 — Lỗi: bản Ask phía producer không bao giờ được xoá sau post_ask thành công | Bằng chứng: post_ask nhận `Ask&`, try_push(ask) ở :816 MOVE vào SpscMail (engine/net/shard.hpp:82 `slots_[...] = std::move(item)`), đường thành công return mà không wipe_ask; mọi call-site (ask_password :1209-1215, on_login :844-849, on_move... :849/:866/:879/:892/:1056) để local ask huỷ không xoá; chỉ bản trong hàng được clerk xoá (wipe_ask ở :1277, :1570) và khi hàng đầy (:820) | Tác động: mật khẩu/vé/capability (cả ask.cap, :864) còn trong RAM (kể cả dư SSO) trái với chuẩn xoá-mọi-nơi của chính tệp (forget/wipe_ask/wipe_answer/dtor :1564-1574); khai thác cần lộ bộ nhớ | Khắc phục: wipe_ask(ask) ngay sau try_push thành công |
- [MEDIUM][CONFIRMED] .gitignore:69 — Lỗi: thiếu mục gates.tsv trong khi vận hành sinh tệp chứa khoá danh tính | Bằng chứng: .gitignore chỉ có `*.local.toml`; TOOLS/server/export_gates.py:83 ghi Table/gates.tsv gồm cổng và khoá công khai/định danh gate; AGENTS.md yêu cầu "bảng không vào git vì mỗi máy chủ có khoá riêng" nhưng không có ignore nào ép điều đó; git check-ignore gates.tsv trả rỗng | Tác động: một `git add -A` vô ý đưa khoá riêng lên lịch sử git, khó tẩy | Khắc phục: thêm `gates.tsv` vào .gitignore |
- [MEDIUM][PROBABLE] src/server/guard/pace.cpp:70-90 — Lỗi: bước cùng tick đo với thời gian 0 nên client nhanh hơn 30 Hz tick rất dễ ăn nợ oan | Bằng chứng: elapsed=0 cho limit_cm = 5 cm (:35-36); bước vượt tầm +1 nợ, kSpeedPenalty = 2.5 (:20) nên ba bước cùng-tick vượt 5 cm là kick; client_tick_ chỉ tiến khi kOk (:79-84) nên sau một lần reject oan các bước kế càng dễ vượt; motion.cpp:23-42 không có ngoại lệ burst | Tác động: khi Move online được bật (hiện chưa gửi Move — AGENTS.md), client 60 Hz/lag-jitter bị correct/kick oan | Khắc phục: miễn/trừ burst cùng-tick đầu tiên sau mốc, hoặc đo theo tick render của client; cần bằng chứng tick client trước khi chốt | Xác thực: NEEDS VERIFICATION (ngữ nghĩa Move.tick phía client) |
- [LOW][CONFIRMED] src/shared/secure/record.cpp:136-137 — Lỗi: độ dài do peer khai (body_length) chảy vào core::check | Bằng chứng: `core::check(plain.size() >= opened.written + plain_len)` với plain_len từ header 2 byte chưa qua length_ok tại điểm gọi (length_ok chỉ gọi ở open_bytes :165 trước decrypt); hiện an toàn nhờ open_bytes :157 ép plain >= kMaxPlainBytes và length_ok chặn body, nhưng chữ của luật sắt số 4 cấm điều kiện client vào check | Tác động: latent — ai đổi một trong hai hằng là có abort từ xa (DoS) | Khắc phục: thay check bằng break_with(Error::kProtocol) |
- [LOW][CONFIRMED] src/server/store/pg.cpp:107-112 — Lỗi: sslmode=disable cứng cho mọi kết nối DB | Bằng chứng: values[] có "disable"; release/server/config/gate.toml cũng nghe 0.0.0.0:7000/7001 như bản dev | Tác động: thấp trên máy dev (DB loopback), thành mật khẩu/dữ liệu plaintext nếu DB triển khai xa; cấu hình release không thắt lại | Khắc phục: cờ TLS trong store.toml + tài liệu topology cho bản release |
- [LOW][CONFIRMED] src/server/account/rpc.cpp:41-46 — Lỗi: Out::text ép size_t xuống u16 không kiểm, ghi độ dài cắt ngọn nhưng thân đầy đủ | Bằng chứng: `u16(static_cast<uint16_t>(value.size()))` rồi insert toàn bộ value.size() byte; phía đọc In::text :81-91 + finish() sẽ fail-closed (thừa byte) nên không mất an toàn bộ nhớ | Tác động: yêu cầu có text > 64 KiB chết câm thay vì lỗi rõ; latent | Khắc phục: kiểm value.size() <= max ở phía ghi như phía đọc, hoặc assert trần gọi |
- [LOW][CONFIRMED] AGENTS.md (mục 11 + NGHI-NGO 45) — Lỗi: tài liệu claims system_posix include system_properties.h cho mọi nền không-Apple, sai với mã hiện tại | Bằng chứng: engine/core/system_posix.cpp:25-26 include nằm trong `#elif defined(__ANDROID__)`; đường dẫn nêu "SRC/core" cũng không còn tồn tại (nay là engine/core) | Tác động: agent tương lai "sửa" một lỗi không có, hoặc bỏ qua build Linux vì tin đã hỏng | Khắc phục: cập nhật AGENTS.md theo mã |
- [LOW][CONFIRMED] TOOLS/source_headers/source_frame.py:39 — Lỗi: docstring mới vẫn nói gen_protocol.py và config_style.py gọi render_frame, sai | Bằng chứng: commit e88b910e không đụng gen_protocol.py; grep render_frame trong TOOLS chỉ trúng source_headers; lần chạy gen thật vẫn ghi comment thường | Tác động: hiểu nhầm chủ quyền khung của tệp sinh, nuôi H1 phần gen | Khắc phục: hoặc dạy gen gọi render_frame (đúng ý AGENTS.md) rồi sửa docstring, hoặc đưa đầu ra gen vào EXCLUDED |

Vùng đã đọc kỹ mà SẠCH (ghi nhận dương, không phải PASS mù): protocol/wire (Reader/Writer/peek_frame: mọi take() giữ bất biến position_ <= size, load() chỉ gọi với span cố định <= 8 byte, text/count kiểm trần kép); gate hello/ping/logout/version (state machine greeted, version min..max, goodbye mọi nhánh); gate outbox/backlog có trần hai lớp trước khi niêm phong (không tiêu nonce oan); webhook HMAC verify thời gian không đổi + skew checked + idempotent; meshopt decode (overflow kiểm trước nhân ở model.cpp:1881, malloc có kiểm null, RAII); reactor IOCP (Op/AcceptOp pointer-interconvertible thật, finish_op không free nên không UAF); session Mailbox hai chiều có trần + Lost; viewer MapRequest gộp không mất bước; render wait_slot (resize theo image_count, kiểm biên, chờ 2 s có hạn); saver zone (không I/O dưới khoá, xả có hạn lúc dừng); migration SQL (mỗi tệp tự BEGIN/COMMIT lũy đẳng); Engine dtor nối clerk + xoá asks/answers tồn.

## 3. ĐÃ KIỂM BẰNG MÁY (lệnh + kết quả thật; kiểm trước revert vẫn giữ giá trị chứng minh tool cũ lossless)

- Tool mới: `python -B -m unittest discover -s TOOLS/source_headers` → 14 test OK.
- Tool mới `--survey` sau revert → đúng 53, tự chuyển 739 + 542 kèm comment dưới khung, cần mô tả 193.
- `python TOOLS/server/lint_config.py` → `26 tệp sạch, 438 cài đặt đều có chú thích và thẳng cột` (sau revert TOML, kiểm lại sau revert mass-edit vẫn xanh).
- `python -B TOOLS/server/gen_protocol.py` chạy 2 lần: lần 1 lột khung ở 4 đầu ra về canonical, lần 2 không đổi gì (deterministic; freshness giữ nguyên).
- Phiên trước: `python -m py_compile` toàn bộ .py trong diff header cũ → 0 lỗi; `check.py --no-tidy --only gcc` (GCC 16.2) 6 tệp (clock, pace, wire, saver, range, tsv) → 0 lỗi; quét diff 26 TOML cũ: 0 dòng mã; worktree CRLF trộn (4803 tệp) có sẵn trước phiên, tool giữ nguyên từng tệp.
- Revert mass-edit cũ: `git checkout HEAD` từng tệp đạt kiểm (HEAD==BASE 0f5a1a47 + diff top-only + bảo toàn từ); worktree hiện tại còn 20 modified đều là việc phiên khác/bẩn cũ; không còn khung hộp cũ nào do phiên này thêm ngoài 8 tệp nêu ở mục 1.

## 4. CHƯA KIỂM (vì sao) / GIẢ ĐỊNH / LỆCH

- Chưa build cmake/ctest/clang-tidy/sanitizer/fuzz/benchmark: diff header về cấu tạo chỉ chạm comment (tool lossless + py_compile + check mẫu), nhưng build đầy đủ là việc của cây build chung đang bận và preset msvc cần dev.bat; không tuyên bố build xanh.
- Không kiểm TSan/Linux/iOS/D3D-hiển-thị/GPU-số: không có môi trường (như sổ trước).
- Sổ audit trước (P0–P3) không audit lại từng dòng; các mục đó vẫn là backlog chính, trừ những dòng sổ này hiệu lực lại có ghi rõ.
- Giả định: SpscMail một producer (luồng tick) một consumer (clerk) đúng như comment table.cpp:256; kMaxPlainBytes/kMaxBodyBytes không bị đổi lệch; Move.tick client tăng đơn điệu khi Move online được bật.
- Lệch quy tắc: (a) dùng chuẩn header THIENLONG thay ENGINEHP của đề bài (đã nêu lý do ở đầu sổ); (b) không sửa logic/API theo lệnh audit dù AGENTS.md có "thấy là sửa" — audit cấm sửa nên mọi khắc phục nằm trong sổ; (c) revert 26 TOML về HEAD để giữ cổng lint xanh thay vì "làm tới cùng" trên mọi tệp.

## 5. GHI CHÚ PHIÊN (blocker thực sự và nhiễu)

- Phiên trước: cây chính có commit 77714693 (LUA-GEN) giữa lúc audit — không đụng vào.
- Phiên này: thêm 3 commit của phiên khác giữa lúc revert (3a52c70d refresh-rate, e88b910e tool khung mới, a764db56 local_cluster) + tranh .git/index.lock 2 lần (đợi rồi chạy tiếp, không ép). Mọi revert kiểm HEAD==BASE động nên commit mới không làm revert sai: tệp ai đổi thì thành MANUAL.
- 20 modified còn lại (CMakeLists.txt, GameLayers.cmake, gen_pool_natives.py, ui_script_pool_tests.cpp, window_tests.cpp, monitor.cpp/.hpp, native_groups.hpp, native_pool.cpp, zone/scene.cpp/.hpp, ogre_mesh.cpp, file.cpp×2, android_main.cpp, android/*.py, context.hpp, zone.modules.cmake, seal/*.hpp, third_party) + 52 WEB/* bị xoá + 16 untracked (gồm sổ này) đều không phải của phiên này — không đụng vào.
- 8 khung hộp cũ còn lại (mục 1) là của phiên này nhưng nằm trên tệp phiên khác đang làm dở: cố ý để lại, tool mới tự đổi khi họ chạm tệp (đúng quy trình "chạm tệp nào --fix tệp đó").
- Worktree CRLF trộn sẵn — không phải do phiên này, đã đo để khỏi đổ lỗi cho header.

## 6. ĐỢT FIX ĐA TÁC TỬ (cùng ngày, sau các mục trên; 2 mục main làm, 6 tác tử song song)

HEAD đã tiến thêm 2 commit giữa đợt fix (60967bda clipboard, fcc16c7c Protocol v5: Talk/Dialog/Quest,
SelfStats, EntityFlags — protocol từ v3 lên v5). Mọi diff của đợt fix đã đọc lại từng dòng; tệp nào
cũng kiểm `git diff` trước/sau, không đè việc phiên khác (table.cpp có thêm dòng `arrival.play` của
phiên protocol bên cạnh dòng fix, khác vùng nên giữ nguyên cả hai).

ĐÃ SỬA (xác minh độc lập, không tin lời tác tử):
- M2 (.gitignore:72-73 `**/gates.tsv`): `git check-ignore -v` trúng cả 3 dạng đường dẫn. CONFIRMED.
- L5 (source_frame.py:39 docstring): unittest tool 14/14 xanh sau sửa. CONFIRMED.
- M1 (gate/table.cpp:824 `wipe_ask(ask)` sau try_push): check.py gcc/clang xanh; tidy chỉ báo
  findings có sẵn trong shard.hpp. Chưa chạy ctest (cấm build cây chung). NEEDS VERIFICATION runtime.
- L1 (secure/record.cpp:129-134 check→break_with kProtocol): core/check.hpp còn dùng ở :154 cho hợp
  đồng của caller nên giữ include. Nhánh mới chết khi hằng đúng nên không test trực tiếp được.
  NEEDS VERIFICATION runtime.
- H1-gen: KHÔNG PHẢI SỬA — gen_protocol đã tự xuất khung (FRAMED/with_frame, không rõ phiên nào làm
  trước đợt này). Xác minh độc lập: 3 đầu ra check khung xanh, `gen_protocol.py --check` exit 0,
  chạy gen 2 lần deterministic. RESOLVED (xác nhận, không tính công).
- Link inbox cap (prior P1-28): link.hpp:31-35 `kMaxInboxBytes = 4*kMaxRecordBytes` + link.cpp:79-81
  vượt trần đóng kSecure. Tác tử đo flood thật: bản gốc và bản sửa cùng đóng ngay (pipe đã chặn),
  inbox_ thực tế ≤ ~2 KB nên trần mới là hardening chưa chạm — KHÔNG thêm test giả, đúng chính sách test.
- range overflow (prior P1): ctor + allocate chặn tràn + test `page_allocator_rejects_huge_request`.
- frame/png caps (prior P2-50/51): valid() kiểm tràn 3 chỗ + png từ chối hàng > kMaxBand + repro đỏ-xanh.
- math .at (prior P2-52/53): check + [] + NOLINT kèm lý do+mã UB-04 + static_assert và ca lane.
- number base (prior P3-80): từ chối base ngoài 2..36 + repro đỏ-xanh.
- queue mask (prior P3-83): `spill_.empty() ? 0 : size()-1` + smoke.
- xml surrogate (prior P1-17): từ chối U+D800..U+DFFF + 7 kỳ vọng hồi quy (red-green qua --run,
  ASan/UBSan/hardening + libstdc++ debug).
- tsv RowReader (prior P3-81): check row_ trong reject() và text() + ca đọc bản ghi cuối.
- migrate sort (prior P3-86): sort theo (leading_number, tên); 001..005 thứ tự không đổi (replica standalone verify; pg.cpp thiếu libpq cho preset GCC nên chỉ logic-verify).
- codec TLS (prior P1-19): ZSTD encode/decode + lz4 fast/slow qua core::thread_slot (lz4 là cùng mẫu lỗi nên sửa luôn theo "thấy là sửa"); tidy sạch trong mã dự án.
- take_number (prior P3-82): CONFIRMED tràn int64 có dấu (đo wrap) → bão hoà trần + ăn hết digits; ghi nhận times_of() còn có thể tràn khi /proc crafted toàn số khổng lồ (follow-up).
- collect_fx exit (prior P1-48): scene_paths rỗng → missing + exit 1 kèm lệnh collect_map; unittest 9/9 (tự chạy lại, OK).

KHÔNG SỬA — GHI CHÚ (nghi ngờ/thiết kế/quyền chủ dự án, giữ nguyên khuyến nghị trong sổ):
- M3 (Pace burst cùng-tick): cần ngữ nghĩa Move.tick phía client; hiện client chưa gửi Move nên latent.
- L3 (rpc Out::text cắt u16): fail-closed đã xác minh; muốn lỗi rõ phải đổi API (thêm max/trả lỗi) — chờ chủ chốt hình.
- L4 (AGENTS.md ghi sai system_posix): mục 11 thuộc phần mẫu chung, tệp dặn không sửa riêng — đổi ở mẫu.
- L2 (sslmode disable): tắt TLS là thiết kế máy dev ghi trong mã; mở TLS cho release cần quyết định topology + schema config — chưa đụng.
- Toàn bộ P0 và các P1/P2 còn lại của sổ audit trước (zone wiring, Move command, D3D/Vulkan, world stub, handshake RL, ipc replay, Touch/UI, build/CI...): tính năng hoặc thiết kế, không đủ căn cứ "chắc chắn triệt để" trong một lượt — giữ backlog, không liệt kê lại.

## PHỤ LỤC A — 193 tệp cần mô tả viết tay theo tool mới (chạm tệp nào --fix tệp đó kèm --describe; TOML/gen-output ngoài phạm vi)

TOOLS/port/luagen/ref_cpp/runtime/lua/state.cpp
TOOLS/port/luagen/ref_cpp/runtime/lua/string.cpp
TOOLS/port/luagen/ref_cpp/runtime/lua/table.cpp
TOOLS/port/luagen/ref_cpp/runtime/luamass/trace.cpp
TOOLS/port/rea/ExportOriginal.java
Test/Fx/fx_tests.cpp
cmake/server/actor.tests.cmake
cmake/server/billing.tests.cmake
cmake/server/bus.tests.cmake
cmake/server/combat.tests.cmake
cmake/server/dice.tests.cmake
cmake/server/handlers.tests.cmake
cmake/server/ipc.tests.cmake
cmake/server/ledger.tests.cmake
cmake/server/scenedata.tests.cmake
cmake/server/zone.tests.cmake
engine/gpu/d3d11/hresult.cpp
engine/gpu/gles/bind_map.cpp
engine/io/platform_posix.cpp
engine/shader/detail/reconcile.cpp
engine/xml/document.cpp
src/client/app/client/assets.cpp
src/client/app/client/display/fx_view.cpp
src/client/app/client/map/book.cpp
src/client/app/client/map/gates.cpp
src/client/app/client/map/ground.cpp
src/client/app/client/map/picture.cpp
src/client/app/client/map/samples.cpp
src/client/app/client/map/sheet.cpp
src/client/app/client/map/terrain.cpp
src/client/app/client/options.cpp
src/client/app/client/session/gates.cpp
src/client/app/client/session/machine.cpp
src/client/app/client/stage/stage.cpp
src/client/app/client/viewer/cursors.cpp
src/client/app/client/world/world.cpp
src/client/face/gui/bar_tint.cpp
src/client/face/gui/strings.cpp
src/client/face/gui/value.cpp
src/client/face/lua/state.cpp
src/client/face/luanum/cformat.cpp
src/client/face/luanum/luanum.cpp
src/client/face/luanum/number.cpp
src/client/face/ui/hud.cpp
src/client/face/ui/painter.cpp
src/client/face/ui/panel/action_bar.cpp
src/client/face/ui/panel/action_bars.cpp
src/client/face/ui/panel/call_events.cpp
src/client/face/ui/panel/data_pool.cpp
src/client/face/ui/panel/debug_list_box.cpp
src/client/face/ui/panel/deck.cpp
src/client/face/ui/panel/desk.cpp
src/client/face/ui/panel/events.cpp
src/client/face/ui/panel/function_bar_right.cpp
src/client/face/ui/panel/function_bar_right_2.cpp
src/client/face/ui/panel/logon.cpp
src/client/face/ui/panel/main_menu_bar_2.cpp
src/client/face/ui/panel/main_menu_bar_3.cpp
src/client/face/ui/panel/main_menu_bar_4.cpp
src/client/face/ui/panel/menubar.cpp
src/client/face/ui/panel/minimap.cpp
src/client/face/ui/panel/online.cpp
src/client/face/ui/panel/player_frame.cpp
src/client/face/ui/panel/portraits.cpp
src/client/face/ui/panel/progress_bar.cpp
src/client/face/ui/panel/quest_book.cpp
src/client/face/ui/panel/quest_log.cpp
src/client/face/ui/panel/scene_trans.cpp
src/client/face/ui/panel/self_equip.cpp
src/client/face/ui/panel/softkey.cpp
src/client/face/ui/panel/start.cpp
src/client/face/ui/panel/widgets.cpp
src/client/face/ui/panel/wording.cpp
src/client/face/ui/radar.cpp
src/client/face/ui/script/context.cpp
src/client/face/ui/script/gui_screen.cpp
src/client/face/ui/script/message_format.cpp
src/client/face/ui/script/native_format.cpp
src/client/face/ui/script/native_player.cpp
src/client/face/ui/script/native_support.cpp
src/client/face/ui/script/native_system.cpp
src/client/face/ui/script/native_variable.cpp
src/client/face/ui/script/native_world.cpp
src/client/face/ui/script/native_xscript.cpp
src/client/face/ui/script/natives.cpp
src/client/face/ui/script/pool_image.cpp
src/client/face/ui/script/variable.cpp
src/client/face/ui/script/windows.cpp
src/client/face/ui/script/xscript.cpp
src/client/face/ui/text.cpp
src/client/figure/hero/hero.cpp
src/client/figure/look/head.cpp
src/client/figure/motion/jump.cpp
src/client/place/fx/billboard.cpp
src/client/place/fx/field.cpp
src/client/place/fx/mesh.cpp
src/client/place/fx/strip.cpp
src/client/place/scene/placement.cpp
src/client/place/scene/scene_file.cpp
src/client/place/scene/transform.cpp
src/client/render/shaders/fx.vs.slang
src/server/account/book.cpp
src/server/account/cap.cpp
src/server/account/ipc_key.cpp
src/server/account/realm.cpp
src/server/account/rpc.cpp
src/server/account/rules.cpp
src/server/account/serve.cpp
src/server/account/sql.cpp
src/server/actor/body.cpp
src/server/actor/codec.cpp
src/server/authd/main.cpp
src/server/billing/book.cpp
src/server/billing/checks.cpp
src/server/billing/code.cpp
src/server/billing/db/pg_book.cpp
src/server/billing/error.cpp
src/server/billing/http.cpp
src/server/billing/limits.cpp
src/server/billing/memory_book.cpp
src/server/billing/rpc.cpp
src/server/billing/rules.cpp
src/server/billing/serve/client.cpp
src/server/billing/serve/serve.cpp
src/server/billing/serve/setup.cpp
src/server/billing/serve/webhook_server.cpp
src/server/billing/throttle.cpp
src/server/billing/webhook.cpp
src/server/billing/wire.cpp
src/server/billingd/main.cpp
src/server/bus/bus.cpp
src/server/combat/codec.cpp
src/server/config/admin.cpp
src/server/config/auth.cpp
src/server/config/billing.cpp
src/server/config/client.cpp
src/server/config/cluster.cpp
src/server/config/detail/node.cpp
src/server/config/gate.cpp
src/server/config/log.cpp
src/server/config/loose.cpp
src/server/config/secrets.cpp
src/server/config/startup.cpp
src/server/config/store.cpp
src/server/config/supervisor.cpp
src/server/config/types.cpp
src/server/config/world.cpp
src/server/config/zone.cpp
src/server/dice/dice.cpp
src/server/gate/motion.cpp
src/server/gated/main.cpp
src/server/guard/pace.cpp
src/server/handlers/registry.cpp
src/server/ipc/link.cpp
src/server/ipc/relay.cpp
src/server/ledger/ledger.cpp
src/server/mission/book.cpp
src/server/mission/codec.cpp
src/server/mission/detail/progress.cpp
src/server/mission/detail/work.cpp
src/server/mission/engine.cpp
src/server/mission/hero.cpp
src/server/ops/ops.cpp
src/server/scenedata/ai_rules.cpp
src/server/scenedata/detail/cells.cpp
src/server/scenedata/disk.cpp
src/server/scenedata/scene.cpp
src/server/scenedata/tables.cpp
src/server/scenedata/walk.cpp
src/server/social/chat.cpp
src/server/social/city.cpp
src/server/social/codec.cpp
src/server/social/guild.cpp
src/server/social/limits.cpp
src/server/social/mail.cpp
src/server/social/notice.cpp
src/server/social/rank.cpp
src/server/social/relation.cpp
src/server/social/team.cpp
src/server/social/text.cpp
src/server/social/wordfilter.cpp
src/server/store/pg.cpp
src/server/stored/main.cpp
src/server/supervisor/main.cpp
src/server/worldd/main.cpp
src/server/zone/aoi.cpp
src/server/zone/content.cpp
src/server/zone/saver.cpp
src/server/zone/serve.cpp
src/server/zoned/main.cpp
src/shared/ids/ids.cpp
src/shared/link/link.cpp
src/shared/secure/private_file.cpp
