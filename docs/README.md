# Chỉ mục tài liệu THIENLONG

Mọi phân tích, quyết định và số đo của dự án nằm ở hai chỗ sống: `docs/` (tài liệu
dự án) và `docs/TAILIEU/` (phân tích mã máy client gốc 2026). Mục 0 của `AGENTS.md` là
trạng thái hiện tại theo mã; `docs/TIEN-DO.md` là nhật ký theo phiên.

Ngày 2026-10-14 đã dọn một lượt theo đúng mã hiện tại (`main` ở `1ff6703`):
xoá 6 bản nháp `I18N-BAO-CAO-2026-10-13.truoc-*`/`*.bak-*` (giữ bản cuối
`I18N-BAO-CAO-2026-10-13.md`); xoá bản sao bộ quy cách C++23 trong repo
(`docs/refs/`, `docs/MAP.md`, `docs/INDEX.md`, nội dung cũ của `README.md` gốc) —
bản duy nhất nằm ở `D:\CLAUDE\cpp23` (`~/.claude/cpp23` trỏ vào đó).

## Tài liệu sống (đọc trước)

- `AGENTS.md` mục 0 — trạng thái, ngân sách, quyết định đã chốt, danh sách tài liệu.
- `TIEN-DO.md` — nhật ký nhiều phiên; mục mới nhất ở đầu tệp.
- `NGHI-NGO.md` — sổ nghi ngờ đánh số; đóng mục ghi kết luận tại chỗ.
- `BAY-DA-BIET.md` — bẫy theo vùng kèm lệnh tái hiện; bẫy chung việc nào cũng
  dính nằm ở mục 11 của `AGENTS.md`, mỗi bẫy chỉ nằm một nơi.
- `KE-HOACH-SERVER.md` — kế hoạch máy chủ (mười ba mốc); mục 10 là mốc và số đo.
- `SERVER-TEP-CAU-HINH.md` — từng tệp cấu hình và bảng của máy chủ.
- `SERVER-DU-LIEU.md` — định dạng dữ liệu máy chủ, ai sở hữu thư mục nào (nhà phát hành chỉ sửa `config/`),
  tệp đè, bảo mật, tệp chữ thoại `dialogue.zh.txt`.
- `PROTOCOL-TIN.md` — danh mục tin (tệp sinh, không sửa tay; sửa bảng ở
  `src/shared/protocol/catalog/*.tsv` rồi chạy `TOOLS/server/gen_protocol.py`).
- `SERVER-BAO-MAT.md` — bắt tay, bản ghi mã hoá, mặt trước của gate.
- `SERVER-DI-CHUYEN.md` — nguyên tắc di chuyển do server làm chủ.
- `SERVER-BILLING.md` — billing: sổ điểm, webhook, đổi điểm hai pha, ipc, mô hình lỗi, phần chưa làm.
- `SERVER-ITEM.md` — vật phẩm, rơi đồ, cửa hàng NPC, lò rèn: kế hoạch rồi áp dụng, bảng đọc, giá, giả định, số tự đặt, phần chưa làm.
- `SERVER-COMBAT.md` — thân thể (`actor`) và chiến đấu (`combat`): thuộc tính, kỹ năng, buff, chuỗi sát thương, phủ dữ liệu 14 môn, số tự đặt, phần chưa làm.
- `SERVER-MISSION.md` — nhiệm vụ, hội thoại, NPC (`ops`, `bus`, `ledger`, `mission`, `talk`, `handlers`) và bộ rút Lua: số đo độ phủ, phần chưa hỗ trợ.
- `SERVER-SOCIAL.md` — xã hội (`social`): tổ đội, quan hệ, bang, thành, thư, chat và lọc chữ, xếp hạng, thông báo; API, khác gốc, số tự đặt.
- `CAMERA-2026.md` — camera và chuột từ mã máy client 2026.
- `DUONG-DI-2026.md` — lưới đi `.path`, tìm đường, luật đi.
- `VA-CHAM-2026.md` — mặt công trình `.WCollision`, `Model::height`/`raycast`.
- `GIAO-DIEN-2026.md` — widget CEGUI của bản 2026.
- `TAO-NHAN-VAT-2026.md` — màn tạo nhân vật, phân bố chân dung/mặt/tóc/đồ.
- `UI-DIEN-THOAI.md` — giao diện điện thoại: vì sao không dùng lại giao diện PC, khung 1080, cỡ tối thiểu, bản phác thảo.
- `NGUON-FORGE2.md` — từng tệp chép từ Forge2: nguồn, khác gốc, số đo.
- `NGUON-TLBB.md` — từng tệp port từ TLBB Dev.
- `CHEP-FORGE2.md` — quy trình chép một tệp từ Forge2.
- `DINH-DANG-TLA.md` — định dạng tệp âm thanh đã cook `.tla`.
- `I18N-BAO-CAO-2026-10-13.md` — báo cáo bản địa hoá ba ngôn ngữ (bản cuối).
- `docs/TAILIEU/README.md` — chỉ mục phân tích mã máy mới (đăng nhập gốc, gói tin,
  tốc độ nạp, giao diện màn chơi) và chỉ mục tài liệu cũ ở `docs/`.
- `AUDIT-2026-10-14/` — audit kỹ thuật theo mã ở `1ff6703` (inventory đã đo,
  kiến trúc AS-IS, findings `AUD-*` có evidence, gap + quality gates, metrics,
  evidence index). Trạng thái `PARTIALLY COMPLETE`: build/test/runtime chưa chạy.
- `dev/server/README.md` — bố cục runtime máy chủ thử, lệnh chạy cụm.
- `android/HUONG-DAN.txt`, `apple/HUONG-DAN.txt` — vỏ mobile (iOS chưa build).
- `WEB/README.md`, `WEB/docs/TAI-SAN-3D.md` — trang giới thiệu tĩnh.

## Tệp đã biết thiếu

- `docs/NHIEM-VU-VO-CONG-2026.md` — code (`src/client/book/*`, `Test/Quest`,
  `Test/Skill`, `TOOLS/port/oracle/*`) và `docs/TAILIEU/README.md` còn trỏ tới, nhưng
  tệp không còn ở `docs/` sau vụ mất cây 2026-10-09. Bản cũ (165 KB) còn ở
  `docs/KHOI-PHUC-2026-10-09/chua-du/docs/NHIEM-VU-VO-CONG-2026.md`, kém bản cuối
  khoảng 223/6226 dòng theo `BAO-CAO-GHEP.tsv`. Chưa khôi phục vì bản cũ khác bản
  cuối; cần ghép lại từ nhật ký rồi mới đưa về `docs/`.

## Lưu trữ (tra cứu, không phải tài liệu sống)

- `docs/giao-viec/` — hồ sơ từng đợt giao việc cho phiên AI phụ (`DE-BAI`,
  `BAO-CAO-A/B/C`, `DOI-CHAT-*`, `KET-QUA`, `REVIEW`). Đọc khi cần biết vì sao
  một quyết định được chốt.
- `docs/AUDIT/` — kết quả audit (`TONG-HOP.md` và bằng chứng ở `evidence/`).
- `docs/KHOI-PHUC-2026-10-09/` — hồ sơ vụ mất cây `F:\tl 2026` và cách ghép lại
  (`DOC-TRUOC.md`, `BAO-CAO-GHEP.tsv`, `DANH-SACH-*`, bundle lịch sử git).
  Không dùng làm tài liệu kỹ thuật hiện tại.
