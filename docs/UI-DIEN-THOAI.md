# Giao diện điện thoại — số đo và bản phác thảo để thiết kế

Chủ dự án chốt ngày 2026-10-15: "Ở tablet dùng giao diện PC là hoàn toàn bình thường. Còn ở mobile thì cố
gắng dùng lại, được thì dùng, nếu không thì tính toán cho tôi bản phác thảo tôi thiết kế UI." Tệp này là
kết quả: giao diện PC không dùng lại được trên điện thoại (mục 1), và khung, cỡ tối thiểu, bố cục để thiết kế
bản điện thoại (mục 2 tới 6).

Mọi con số nằm ở một chỗ là `TOOLS/content/phone_wireframe.py`. Công cụ tính cỡ tối thiểu từ số đo vật lý.
Nó còn kiểm bố cục: mọi phần nằm trong khung, ô bấm đủ cỡ, hai ô bấm cách nhau ít nhất một khe. Cuối cùng nó
vẽ ba tấm phác thảo ở `docs/ui-dien-thoai/` (SVG để sửa, PNG để xem):

```
python -B TOOLS/content/phone_wireframe.py                           in bảng số, kiểm bố cục
python -B TOOLS/content/phone_wireframe.py --out docs/ui-dien-thoai  ghi thêm SVG và PNG
```

Sửa số trong công cụ chứ không sửa SVG tay: công cụ báo lỗi và thoát mã 1 khi bố cục mới vi phạm cỡ hay khe.

## 1. Vì sao điện thoại không dùng lại giao diện PC

Cạnh ngắn của điện thoại nằm ngang chỉ khoảng 65 tới 70 mm, dù màn 5,5" hay 6,7" (bảng máy tham chiếu do
công cụ in). HUD PC cần khung cao 640 điểm ảnh. Khít khung đó vào cạnh ngắn là mức to nhất còn đủ chỗ cho HUD
PC, và ở mức đó (điện thoại nhỏ nhất, 64,9 mm):

- ô hành động 40 px ra 4,1 mm;
- nút minimap 25 px ra 2,5 mm;
- nút kênh chat 17 px ra 1,7 mm;
- chữ phông 12 ra 1,2 mm.

Ngưỡng là ô bấm 7 mm (Android 48 dp khoảng 7,6 mm, Apple 44 pt khoảng 6,9 mm) và chữ thường 2,2 mm (chữ Hán
cần to hơn chữ Latinh). Nút chat cần to gấp 4 lần, chữ gấp gần 2 lần, và khi đó HUD PC không còn vừa màn. Bộ
layout tạm `Interface/phone/` (layout PC nhân 1,4 bởi `TOOLS/content/phone_layout.py`) cũng không đạt: chữ
vẫn là phông 12, nút chat ra 2,4 mm.

Máy tính bảng thì đạt. Lenovo TB-X306F (10,1", 1280 x 800, cạnh ngắn 136 mm) dùng giao diện PC 1:1: ô hành
động 6,8 mm, chữ 2,0 mm. Từ bản này client chọn layout theo màn: cạnh ngắn dưới 600 dp (cách Android chia
máy tính bảng, `sw600dp`) hay iPhone thì dùng `Interface/phone/`, còn lại dùng layout PC
(`DisplayDesc::uses_phone_layout`, `is_phone_screen` ở `android_main.cpp`).

## 2. Khung thiết kế

- Đơn vị là điểm thiết kế. Khung cao 1080, rộng 1920 ở màn 16:9, dãn tới 2400 ở 20:9 (iPhone 19,5:9 khoảng
  2341). Client sẽ nhân mọi số với `cao màn / 1080`, nên màn 1080p là 1:1, màn 720p là 0,667, iPhone 15 là
  1,092.
- Khung là vùng an toàn. Tai thỏ, Dynamic Island và thanh cử chỉ nằm ngoài nó (iPhone nằm ngang: 59 pt mỗi
  bên, tức khoảng 162 điểm thiết kế, và 21 pt ở đáy). Ảnh nền được tràn ra ngoài, nhưng ô bấm và chữ thì không.
- Sáu nhóm neo: trên trái, trên giữa, trên phải, dưới trái, dưới giữa, dưới phải. Màn rộng hơn 1920 thì nhóm
  phải dời sang phải, nhóm giữa dời nửa phần dư, nhóm trái đứng yên. Hai tấm `hud-1920x1080` và
  `hud-2400x1080` cho thấy cùng một bố cục ở hai cỡ.

## 3. Cỡ tối thiểu

Tính trên điện thoại nhỏ nhất, nơi 1 điểm thiết kế bằng 0,0601 mm:

- Ô bấm: 120 x 120 (7,2 mm). Hình vẽ được nhỏ hơn, nhưng vùng nhận chạm thì không.
- Khe giữa hai ô bấm: 32 (1,9 mm).
- Chữ: nhỏ 30 (1,8 mm, chỉ cho số trên thanh), thường 38 (2,3 mm), tiêu đề 44 (2,6 mm).
- Nút đánh 190, kỹ năng 140. Bản mobile 天龙怀旧 đo ở `G:\TLBB\Dev\docs\UI-MOBILE.md` dùng 151, 129, 125 trên
  cùng khung 1080, tức nhỏ hơn mức ở đây một chút.

## 4. HUD (tấm `hud-1920x1080.png`, `hud-2400x1080.png`)

Phần màu lam là ô bấm, xám là phần chỉ hiện, lục là vùng chạm động.

- Trên trái: chân dung (bấm mở bảng nhân vật), tên và cấp, máu, nội lực, trạng thái; dưới đó khung theo dõi
  nhiệm vụ, ba dòng, mỗi dòng là một ô bấm (bấm thì tự tìm đường), và nút thu gọn.
- Trên giữa: khung mục tiêu, chỉ hiện khi đang chọn.
- Trên phải: bản đồ nhỏ (bấm mở bản đồ lớn) và tên cảnh, toạ độ. Bên trái nó là Menu và Shop. Menu mở lưới
  các bảng: túi đồ, nhân vật, kỹ năng, nhiệm vụ, bạn bè, tổ đội, cài đặt và các nút của `FunctionBarRight`.
- Dưới trái: vùng cần gạt (ngón chạm xuống trong vùng này thì đế nổi lên tại chỗ chạm, như
  `control/stick` đang làm), chỗ đế nằm khi nghỉ, và nút tự đánh.
- Dưới giữa: chat thu gọn (bấm mở bảng chat), thanh kinh nghiệm suốt chiều rộng ở đáy.
- Dưới phải: nút đánh, bốn kỹ năng trên cung bán kính 340 quanh nó, và nút nhảy. Bán kính 340 là số nhỏ nhất
  để hai kỹ năng kề nhau còn cách nhau đủ một khe (dây cung 2 x 340 x sin 15° = 176 > 140 + 32).

## 5. Bảng toàn màn (tấm `panel-1920x1080.png`)

Mẫu túi đồ, cũng là khuôn cho nhân vật, kỹ năng, nhiệm vụ, thương thành:

- bảng 1600 x 960 giữa vùng an toàn;
- tiêu đề chữ 44 và nút đóng 120 ở góc phải;
- cột thẻ bên trái, mỗi thẻ 240 x 120;
- lưới ô 120 cách nhau 32, vừa 8 x 5 = 40 ô một trang.

Danh sách cuộn dùng dòng cao ít nhất 120.

## 6. Ảnh và phông — việc phía client khi có bản thiết kế

- Ảnh: ảnh giao diện PC vẽ cho 1:1. Ô hành động 40 px phóng lên 140 điểm thiết kế là gấp 3,5 lần, sẽ nhoè.
  Biểu tượng kỹ năng, vật phẩm và khung nút của bản điện thoại cần ảnh vẽ ở cỡ thiết kế. Khung chín ô
  (9-slice) của PC thì giãn được.
- Phông: client mới đọc phông bitmap cỡ cố định (`GBK12.bin`, `VTNAM14.bin`). Client 2026 có cả phông FreeType
  (`Schema/*.font`: `TLNA__`, `VDA_M`, `YouYuan*` trỏ `0_FIREFOX_2.bin`, `1_FIREFOX_2.bin` và `tahoma.ttf`).
  Chữ 30 tới 44 điểm thiết kế cần một bộ dựng phông vector dựng glyph đúng cỡ điểm ảnh màn. Chưa làm.
- Layout: bản thiết kế đi vào `Interface/phone/<tên>.layout.xml` theo điểm thiết kế. Khi các tệp đó thay bộ
  tạm, HUD điện thoại đổi tỉ lệ sang `cao màn / 1080` và neo theo vùng an toàn. Hiện HUD vẫn co khung ảo
  800 x 640 cho bộ tạm (`ui::layout_scale` ở `src/client/face/ui/hud.cpp`), với trần là mật độ màn
  (`DisplayDesc::ui_density`: dpi/160 trên Android, contentScaleFactor trên iOS, 1 trên PC).
