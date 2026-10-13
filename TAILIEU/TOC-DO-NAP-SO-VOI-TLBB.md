# Tốc độ nạp: THIENLONG so với client G:\TLBB (đo 2026-10-13)

Điều kiện bắt buộc của chủ dự án (2026-10-13): nạp đủ giao diện game cùng bản đồ phải nhanh hơn G:\TLBB, có số làm
dẫn chứng; map hiện đồng bộ cùng giao diện (không hiện giao diện trước rồi map lấp dần).

## Kết quả

Cảnh Đại Lý (resid 2, 5982 vật thể, 310 mesh, địa hình 320 x 320 ô), cửa sổ 1280 x 720, tính từ lúc chạy lệnh tới lúc
màn hình có **đủ cảnh và đủ giao diện**:

- THIENLONG: khung đầu có đủ bản đồ và HUD, **trung vị 387 ms** (nhỏ nhất 378, lớn nhất 420; 15 lượt).
  Đo bằng mtime của ảnh `--shot` (cùng cách đo với bên kia, gồm cả mã hoá PNG): trung vị 436 ms (428 tới 489; 10 lượt).
- G:\TLBB (`tlbb_client.prev.exe`, D3D11): khung ổn định, tức khung đầu tiên giống khung cuối (độ lệch xám trung bình
  ≤ 1,0 trên ảnh 320 x 180): **trung vị 1239 ms** (nhỏ nhất 1009, lớn nhất 1794; 8 lượt). Các mốc sớm hơn của bên đó:
  ảnh đầu tiên 749 ms, thế giới đã hiện (≥ 20% điểm ảnh khác nền) 1004 ms.

Chênh: nhanh hơn 3,2 lần theo trung vị; lượt chậm nhất của THIENLONG (420 ms) vẫn nhanh hơn lượt nhanh nhất của
G:\TLBB (1009 ms) 2,4 lần.

Bằng chứng nhìn được: `anh/nap-thienlong-khung-dau.jpg` (khung đầu của THIENLONG, đã đủ bản đồ nét và HUD),
`anh/nap-tlbb-khung-on-dinh.jpg` (khung ổn định của G:\TLBB), `anh/nap-tlbb-khung-som.jpg` (khung sớm của G:\TLBB,
thế giới chưa nạp xong). Số từng lượt: `anh/bench-thienlong.json`, `anh/bench-thienlong-shot.json`, `anh/bench-tlbb.json`.

## Hai bên không giống hệt nhau — đọc kèm số

- G:\TLBB tự đăng nhập vào máy chủ thử chạy trên máy này (`127.0.0.1`, bản sao ở thư mục tạm, tài khoản riêng, không đụng
  dữ liệu G:) rồi mới vào cảnh, nên số của nó gồm cả vòng đăng nhập mạng (cỡ 0,3 giây theo các lần đo trước). THIENLONG chạy
  offline: client chưa mở socket nào (AGENTS.md mục 0).
- Khung cuối của G:\TLBB có NPC, người chơi khác và tên bay trên đầu; THIENLONG chưa có những thứ ấy. Phần nạp bản đồ,
  vật thể tĩnh, hạt và giao diện thì hai bên tương đương (so hai ảnh).
- G:\TLBB chạy D3D11 `--no-vsync`; THIENLONG chạy Vulkan, mailbox. Mỗi bên là backend mặc định tốt nhất của nó.
- Thước đo: THIENLONG đo trong tiến trình (`Mốc … ms`, tính từ lúc hệ điều hành tạo tiến trình, nên có cả phần nạp
  thư viện) và từ ngoài bằng mtime ảnh; G:\TLBB chỉ đo được từ ngoài, bằng ảnh nó chụp theo kịch bản mỗi ~30 ms, nên số
  của nó có sai số làm tròn khoảng ±30 ms và cộng thêm chi phí ghi TGA của các ảnh trước.
- Máy: i5-14600KF (14 lõi, 20 luồng), 64 GB, RTX 5060 (driver 32.0.15.9186), Windows 11. Chạy lặp, cache tệp của hệ điều
  hành đã ấm với cả hai bên. Chưa đo lúc nguội, chưa đo Android, chưa đo cảnh nào khác Đại Lý.
- Trong các đợt đo thử trước đó có lượt chậm bất thường (570 và 589 ms; một đợt 8 lượt có trung vị 580 ms) lúc nhiều tiến
  trình Python khác của máy đang chạy; chưa chứng minh được nguyên nhân. Đợt 15 lượt dùng làm số chính không có lượt nào như
  vậy; bảng trên lấy đợt đó, đừng lấy một đợt ít lượt hơn.

## Đường nạp mới và đo trước sau

Trước đợt này: khung đầu (có cả cảnh lẫn HUD) ở 1055 tới 1088 ms. Chuỗi việc nối đuôi: cửa sổ → thiết bị GPU → HUD
(đọc 286 ms) → dựng cảnh → nạp mesh → trời, nước → khung đầu. Nay các việc không cần GPU chạy ở luồng riêng từ đầu tiến
trình và trùng nhau; luồng vẽ chỉ còn việc cần thiết bị:

1. **Luồng đọc giao diện** (`ui::HudPrep`, `Display::preload`): bộ nạp giao diện, 40 layout, bảng chuỗi, bảng cảnh, hai
   phông đọc ở luồng riêng (chuỗi, tên cảnh, mỗi phông thêm một luồng) ngay đầu `run()`. `Hud::open` chỉ còn đưa hai phông
   lên GPU. 286 ms nối đuôi nằm ngoài đường găng.
2. **Nạp driver đồ hoạ sớm** (`Display::preload`): lần liệt kê adapter Vulkan đầu tiên của tiến trình mất 100 tới 150 ms
   (loader và mọi ICD); chạy ở luồng riêng trong lúc đọc cảnh và mở cửa sổ. `predict_cache` bỏ lần liệt kê thừa (trước đó
   mỗi backend liệt kê hai lần).
3. **Luồng đọc cảnh bắt đầu trước thiết bị** (`Display::State::kick_loading`, `post_load`): mesh và địa hình được giao
   cho luồng đọc ngay khi luồng vẽ khởi động, không chờ thiết bị và giao diện. Trên điện thoại cấp texture (ASTC hay ETC2)
   chỉ biết sau khi có thiết bị nên `open_gpu` gọi ở đó.
4. **Tra chất liệu của all.material** (`engine/resource/ogre_mesh.cpp`, `table_of`): tra tuần tự hàng nghìn luật dưới một
   khoá chung làm 19 luồng đọc mesh xếp hàng: `load_named_model` tốn 10,4 giây CPU cộng dồn cho 310 mesh, mesh cuối chỉ
   đọc xong ở 630 ms. Nay bảng băm bất biến dựng một lần, tra không khoá: 2,3 giây CPU, mesh cuối xong ở 220 ms.
   Đây là phát hiện lớn nhất (khung đầu 665 → 505 ms).
5. **Texture giao diện không nướng mip** (`resource::Image::has_mips`): sampler của giao diện không dùng mip nhưng bộ tải
   vẫn nướng cả chuỗi; riêng phông GBK12 (384 x 9192) tốn 48 ms trên luồng vẽ, nay 9 ms.
6. **Nạp đồng bộ** (`Display::State::settle_first_scene`): luồng vẽ nạp hết mặt đất, mesh, trời, nước trước khi trình khung
   đầu, nên khung đầu đã có đủ cảnh lẫn HUD (không có chuyện hiện HUD rồi cảnh lấp dần).
7. Trước đợt này, cùng hướng: địa hình nướng trên GPU (`terrain.ps`, 2,7 s → 331 ms), tra nước 454 → 16 ms.

Dòng thời gian của một lượt điển hình sau đợt này (ms từ lúc tạo tiến trình): `main` 6, cảnh đã đọc 57, cửa sổ mở 86,
thiết bị GPU 180, pipeline xong 225, HUD 238, `arm_scene` 265, mọi mesh đã đặt 350, khung đầu đã trình 385.
Đường găng còn lại nằm trên luồng vẽ (thiết bị 95 ms, pipeline 45 ms, đưa 310 mesh lên GPU ~80 ms, trời và nước ~30 ms).
Ý tiếp theo nếu cần nhanh hơn: gom lệnh tải lên GPU của các mesh vào ít lần nộp hơn, dựng phần CPU của trời và nước ở
luồng đọc, tạo thiết bị GPU ở luồng riêng trong lúc mở cửa sổ.

## Tái hiện

Mốc đã in sẵn ở log của client (`Mốc <ms> ms  <tên>`); đổi tên mốc thì đổi cả `TOOLS/run/bench_load.py`.

```
python TOOLS/run/bench_load.py --runs 15 --mark "cảnh nạp xong" --mark "khung đầu đã trình" --cwd dev/client/bin \
    -- ./thienlong_client.exe --scene-id 2 --size 1280x720 --frames 60
```

Client tham chiếu cần máy chủ thử của nó đang chạy và tài khoản đã có; lệnh đã dùng (bản sao máy chủ và `APPDATA`
riêng, không đụng G:):

```
cd /g/TLBB/CLIENT/pc && python TOOLS/run/bench_load.py --runs 8 --watch <thư mục ảnh> --until-files 30 \
    --background 31,46,64 --stable-diff 1.0 --env APPDATA=<thư mục riêng> \
    -- bin/tlbb_client.prev.exe --account <tài khoản> --server-key <khoá> --server 127.0.0.1:7000 --pack data/content.tlpak \
       --tables data/tables --cooked data/cooked --character data/cooked/model/tieu_phong_body.tlmesh \
       data/cooked/material/jpg_tieu_phong_body.ttex --backend d3d11 --no-vsync --script <kịch bản> --shots <thư mục ảnh>
```

Kịch bản chụp: 30 lần `shot sNN` cách nhau `wait 30` rồi `quit`. `TOOLS/run/launch_timeline.py` đo một lượt từ ngoài
(mốc dòng log hoặc mtime tệp) khi cần xem từng mốc.
