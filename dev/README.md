# dev — bản thử

Không có mã nguồn. Mã ở `src/`, `engine/`, `TOOLS/`, `WEB/`. Nguyên liệu dựng ở `assets/`.

- `client/bin` — chương trình người chơi chạy.
- `client/assets` — assets của bản thử. Nhìn thư mục này là thấy dạng assets bản này đang dùng.
- `server` — máy chủ thử: `config`, `tables`, `scenes`, `sql`, `bin`, `pgsql`, `data`, `log`. Database này chỉ của bản thử.

Thư mục này chỉ chứa thứ dành cho nhà phát hành: không mã nguồn, không exe thử nghiệm, không bản sao lưu. Nhà
phát hành chỉ sửa `server/config`; mọi thứ khác bị thay ở lần nâng bản sau (`docs/SERVER-DU-LIEU.md`).

`release/` là cùng kiểu bố trí, cho bản chính thức, assets và database riêng.
