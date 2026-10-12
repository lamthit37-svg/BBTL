# THIENLONG — quy định riêng của dự án (Claude Code)

@AGENTS.md

Riêng Claude Code: skill `cpp-build`, `cpp-debug`, `cpp-deps`, `vn-text`, `win32-native`,
`investigating-bugs`, `verification-before-completion` có sẵn ở mức người dùng — nạp khi việc cần.

## Bộ nhớ của Claude cho dự án này — dọn định kỳ (chủ dự án chốt 2026-10-08)

Thư mục memory của Claude (`~/.claude/projects/f--tl-2026-THIENLONG/memory`) chỉ giữ lời dặn của
chủ dự án về CÁCH LÀM VIỆC mà repo chưa ghi. Mọi thứ khác có chỗ riêng và không chép sang memory:

- Quyết định đã chốt: mục 0 của `AGENTS.md`. Bẫy đã đo: mục 11 (bẫy chung và chỉ mục) và
  `docs/BAY-DA-BIET.md` (bẫy theo vùng). Tiến độ, việc đã xong, số đo: `docs/TIEN-DO.md` và
  `docs/giao-viec/`. Điều chưa chắc: `docs/NGHI-NGO.md`.
- Không ghi vào memory: nhật ký việc đã làm (commit, merge, nghiệm thu), trạng thái của phiên,
  thứ `AGENTS.md` hay `docs/` đã có.

Trần, đo bằng `wc -l *.md` trong thư mục đó: chỉ mục `MEMORY.md` không quá 8 dòng, mỗi tệp không
quá 40 dòng. Dọn không chờ được nhắc, ở ba thời điểm:

1. Trước MỖI lần ghi memory: đọc chỉ mục; đã có tệp cùng chủ đề thì sửa tệp đó, không thêm tệp.
   Thêm mà chạm trần thì gộp hoặc bỏ một tệp trước.
2. Cuối mỗi việc nhiều bước (lúc viết báo cáo bốn mục), và ngay sau khi chuyển một điều vào
   `AGENTS.md` hay `docs/`: rà cả thư mục. Xoá tệp mà repo đã ghi đủ và tệp hết tác dụng; rút phần
   kể chuyện; kiểm tên tệp, lệnh nhắc trong memory còn tồn tại, sai thì sửa; đo lại trần.
3. Đầu phiên, khi chỉ mục nạp vào ngữ cảnh đã vượt trần: dọn trước khi làm việc được giao.

Mỗi tệp còn lại phải trả lời được ba câu: chủ dự án nói gì (nguyên văn, ngày), vì sao, lần sau
làm khác đi thế nào. Thiếu câu thứ ba thì không phải memory. Mỗi lần dọn ghi một dòng trong báo
cáo: xoá, gộp, giữ tệp nào.
