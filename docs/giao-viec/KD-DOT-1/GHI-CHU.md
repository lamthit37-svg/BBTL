# Tối ưu khởi động client ("mở là lên ngay"): ghi chú để làm sau

Ngày 2026-10-07 chủ dự án nêu mục tiêu "tối ưu gần như tuyệt đối, mở là lên ngay", rồi trong cùng
buổi quyết định hoãn: mức hiện tại tạm được, viết mã cho xong client và máy chủ trước. Tệp này giữ
những gì đã đo và đã dò để lúc quay lại không phải làm lại từ đầu. Chưa có đề bài, chưa giao cho ai.

## 1. Số nền đã đo

Bản `msvc-release` ở commit `7e379d4`, cài vào `CLIENT/bin`; PC của dự án (RTX 5060, màn 60 Hz),
vùng chơi 1280x720, cảnh mặc định resid 251 (Hỏa Diệm Cốc), bộ đệm tệp của hệ điều hành đã ấm, máy
rảnh. Đo từ bên ngoài tiến trình bằng `kiem-claude/startup_probe.py`, mười lượt mỗi backend; mốc
tính từ ngay trước `CreateProcess`, độ phân giải của mốc sau cửa sổ là một nhịp quét (16,7 ms).
Bảng gốc ở `moc/pc-vulkan.tsv`, `moc/pc-gles.tsv`; vết từng mẫu của một lượt ở
`moc/pc-vulkan-run04.trace.tsv`.

- Vulkan: cửa sổ hiện 39 ms (37 tới 55); khung đầu có cảnh và giao diện 427 ms (423 tới 522); tới
  khung đó tiến trình đã đọc 19,3 MiB bằng 5.430 lần đọc và dùng 531 ms CPU (422 tới 734); đỉnh bộ
  nhớ 257 MiB.
- GLES: cửa sổ hiện 38 ms (37 tới 59); khung đầu 516 ms (510 tới 541); 19,5 MiB bằng 5.653 lần
  đọc; 695 ms CPU (641 tới 844); đỉnh bộ nhớ 228 MiB.
- Hình đứng yên (mesh vào hết) sau khung đầu chừng 170 ms: trung vị 606 ms với Vulkan, 679 ms với
  GLES. Client tự báo nạp cảnh, tính từ lúc bắt đầu nạp, trung vị 146 ms (Vulkan) và 277 ms (GLES).
- Giữa mốc cửa sổ và khung đầu, khoảng 390 ms với Vulkan, cửa sổ trống: 250 ms đầu Windows còn
  đang làm mờ dần cửa sổ lên, phần còn lại là một ô một màu.
- Máy tính bảng Lenovo TB-X306F (đo ở phần đóng việc client cùng ngày, bằng log, chưa dùng bộ đo
  nào): lần chạy đầu sau khi cài chép 2.257 tệp assets từ APK ra thư mục dữ liệu, cỡ 25 giây; lần
  hai không chép, từ "nền tảng sẵn sàng" tới "phần hiển thị đã chạy" là 1,1 giây.

Chưa đo: khởi động nguội (sau khi khởi động lại máy, bộ đệm tệp trống); bấm đúp exe (exe là chương
trình console nên Windows mở thêm một cửa sổ console, bộ đo có `--console new` nhưng chưa chạy);
máy tính bảng từ lúc chạm biểu tượng (`am start -W`) tới khung đầu; cảnh lớn hơn resid 251.

## 2. Đường khởi động hiện tại (đã đọc mã)

1. `client/main.cpp`: đọc `Config/SceneDefineEx.txt`, `world::enter` đọc và phân tích tệp cảnh, tệp
   bầu trời, địa hình, tất cả trên luồng chính, rồi mới gọi `run_viewer`.
2. `client/viewer/viewer_win32.cpp`, `run_viewer`: `Window::create` (cửa sổ hiện ở đây, 39 ms), rồi
   `Display::create` đứng chờ luồng vẽ làm xong `Display::State::launch`. Trong lúc chờ, luồng cửa
   sổ không đọc thông điệp: một lời gọi `SetWindowPos` đồng bộ từ tiến trình khác vào cửa sổ này đã
   đứng hơn 400 ms (gặp khi viết bộ đo, nên bộ đo gọi kiểu không chờ).
3. `client/display/display_gpu.cpp`, `launch` trên luồng vẽ, lần lượt: thiết bị và swapchain;
   `render::Forward` (gói shader, pipeline); `open_hud` (lượt vẽ 2D, dữ liệu giao diện, ảnh, phông);
   `arm_scene`: giao việc nạp cảnh cho luồng đọc, rồi `load_player`, `prepare_board`, `FxView::open`
   chạy đồng bộ. Xong hết mới trả cửa sổ và vẽ khung đầu.
4. Trở lại luồng cửa sổ, `present`: `load_game_cursors` (22 ảnh), mở thiết bị âm thanh và bật nhạc,
   rồi mới vào vòng thông điệp.
5. Nạp cảnh chạy nền: một luồng nướng ảnh địa hình (26 ms cho lưới 128x128), các luồng đọc GLB;
   mỗi khung luồng vẽ nộp GPU tối đa 8 ms. Client báo mặt đất lên GPU sau 113 tới 128 ms (Vulkan),
   203 tới 219 ms (GLES) trong khi nướng chỉ mất 26 ms: mặt đất nướng xong vẫn phải chờ luồng vẽ
   làm hết bước 3.

## 3. Chỗ nghi, xếp theo phần thời gian đang chiếm

Chưa chỗ nào được đo riêng; thứ tự dựa trên số ở mục 1 và mã ở mục 2.

1. Quãng 390 ms giữa cửa sổ và khung đầu nằm trọn trong `launch`. Chưa biết bước nào chiếm bao
   nhiêu vì client không có mốc thời gian khởi động. Việc đầu tiên khi quay lại: cho client in một
   bảng mốc tính từ lúc tiến trình sinh ra (vào `main`, cửa sổ hiện, thiết bị xong, pipeline xong,
   giao diện xong, người chơi xong, khung đầu, mặt đất hiện, cảnh đủ, âm thanh mở).
2. Thứ tự: khung đầu chờ cả giao diện, người chơi và hiệu ứng. Vẽ khung đầu ngay khi có thiết bị và
   mặt đất, những thứ còn lại vào dần như mesh của cảnh, là hướng rút được nhiều nhất mà không cần
   đổi định dạng dữ liệu.
3. 19,3 MiB đọc bằng 5.430 lần, trung bình 3,6 KiB mỗi lần: có chỗ đọc tệp qua bộ đệm 4 KiB. Nghi
   ảnh PNG đọc qua `FILE*` của stb; chưa xác minh. Đọc cả tệp một lần hoặc ánh xạ tệp.
4. Mỗi lần mở đều giải mã lại PNG và GLB, nướng lại ảnh địa hình, dịch lại pipeline: quyết định
   "chưa nấu hay nén tài nguyên" ở `AGENTS.md` mục 0 còn hiệu lực. Ứng viên: bộ đệm pipeline
   (`VkPipelineCache`), ảnh đã nén theo nền tảng, ảnh địa hình nướng sẵn trên đĩa. Mỗi thứ phải có
   số đo trước khi làm, và đổi quyết định đó là việc của chủ dự án.
5. Preset `msvc-release` thật ra là `RelWithDebInfo`: `/O2 /Ob1`, liên kết `/debug /INCREMENTAL`,
   không LTCG, không `/OPT:REF,ICF`. Thời gian CPU tới khung đầu là 531 ms nên bản phát hành thật
   (`/Ob2` trở lên, LTCG) đáng đo.
6. GLES chậm hơn Vulkan 90 ms tới khung đầu và nạp cảnh gần gấp đôi (277 so với 146 ms; riêng đưa
   mặt đất lên GPU 42 so với 15 ms). Chưa dò.
7. Android: 25 giây chép assets ở lần chạy đầu. Ứng viên: đọc thẳng từ APK qua `AAssetManager`,
   hoặc chép nền kèm thanh tiến độ, chép trước những tệp khung đầu cần.
8. Exe là chương trình console: bấm đúp thì hiện cửa sổ console trước cửa sổ game. Chưa đo.
9. Con trỏ chuột và âm thanh mở trên luồng cửa sổ trước vòng thông điệp: không chặn khung đầu nhưng
   kéo dài quãng cửa sổ không phản hồi.

## 4. Bộ đo và chỗ nó chưa chắc

    python -B docs/giao-viec/KD-DOT-1/kiem-claude/startup_probe.py CLIENT/bin/thienlong_client.exe
        --backend vulkan --runs 10 --keep build/kd/pc-vulkan --out build/kd/pc-vulkan.tsv [--trace]

Chạy sau `cmake --install build/msvc-release`, khi không có bản build hay lượt đo nào khác đang
chạy. Hai mốc `window` và `frame` ổn định qua cả hai mươi lượt. Hai mốc `hud` và `settled` thì
chưa: 5 trên 20 lượt cho số sai. Hai lượt hàng điểm ảnh của thanh menu lệch ảnh ổn định suốt 2,4
tới 3,2 giây đầu; nghi cửa sổ mở chồng lên thanh tác vụ và lệnh đưa lên trên cùng tới muộn vì
luồng cửa sổ chưa đọc thông điệp, chưa xác minh. Ba lượt ảnh ổn định lấy ở 3,5 giây rơi đúng lúc
hình còn đổi, chưa biết thứ gì đổi. Trước khi dùng hai mốc đó để nghiệm thu: đặt cửa sổ về một chỗ
cố định, và chọn ảnh ổn định theo độ đứng yên thay vì theo một mốc giờ. Bộ đo chỉ đúng với vùng
chơi 1280x720 và màn hình không khoá.

## 5. Khi quay lại

Thứ tự đề nghị: (a) bảng mốc trong client, mục 3.1; (b) đo lại, lập bảng chia thời gian thật;
(c) lúc đó mới viết đề bài cho đội Grok, chia theo tệp: thứ tự khởi động (`client/viewer`,
`client/display`), đọc tệp (`io`, `resource`), bản dựng phát hành (CMake, preset), Android assets
(`client/android_main.cpp`, `client/assets`), mỗi gói một ngưỡng bằng số đo của bộ đo này và của
bảng mốc. Máy chỉ có một: các vai dựng nối tiếp và chỉ một vai đo mỗi lúc (xem bẫy "chạy song song
việc nặng" ở `AGENTS.md` mục 11).

## 6. Màn đăng nhập: nạp cảnh nền (2026-10-08)

Chủ dự án nêu khi xem cửa sổ thật: "sao load lâu dữ vậy", rồi "tôi cần một sự tối ưu tuyệt đối để
load đủ hình và ngay lập tức". Cảnh nền `erengu_DL` nặng hơn cảnh mặc định nhiều: 167 mesh, 153
texture PNG (114 MiB tệp, 105 triệu điểm ảnh, 401 MiB RGBA8 chưa kể mip), mặt đất 256 x 256 ô với
ảnh mặt 2048 x 2048. Đo bằng `startup_probe.py`, bản `msvc-release`, ba lượt mỗi mốc, máy có 20
luồng, bộ đệm tệp ấm; "đủ cảnh" là dòng "Nạp cảnh ... xong" của client tính từ lúc bắt đầu nạp,
"đứng hình" là mốc `settled` của bộ đo tính từ `CreateProcess`.

| Bản | Khung đầu | Đủ cảnh | Đứng hình | Đỉnh bộ nhớ |
|---|---|---|---|---|
| Nạp đồng bộ trước khung đầu (đưa `stage`, `ground`) | không đo được (cửa sổ trống) | chặn khung đầu | 2,2 s | 1,2 GiB |
| Nạp dần như cảnh chơi (`ViewerDesc::backdrop`) | 0,44 s | 2,9 tới 3,1 s | 2,6 tới 2,9 s | 1,1 GiB |
| Nướng mip ở luồng nạp, ảnh cọ giải mã song song | 0,47 tới 0,52 s | 0,89 tới 0,99 s | 1,2 tới 1,5 s | 1,9 tới 2,2 GiB |

Chỗ chậm đã tìm ra và đã chữa: chuỗi mip của từng ảnh nướng tuần tự trên luồng vẽ trong
`resource::upload_queued` (dòng "dựng GPU" của client: 2,5 giây cho 153 ảnh), trong khi các luồng
đọc đã giải mã PNG song song và ngồi chờ. Nay `resource::stage_images` nướng ở luồng đọc; "dựng
GPU" còn 0,2 tới 0,36 giây. Đỉnh bộ nhớ tăng vì các chuỗi mip đã nướng nằm chờ luồng vẽ trong lúc
nó còn đợi mặt đất.

Đã thử và bỏ vì không có lợi đo được: cho mesh lên GPU trước khi mặt đất xong (đủ cảnh 0,95 tới
1,04 giây, trong nhiễu của 0,89 tới 0,99).

Còn lại, theo phần thời gian đang chiếm:

1. CPU: khoảng 3 giây CPU mỗi lần mở cho giải mã PNG và nướng mip (bộ đo: `cpu_ms` 3000), chia
   cho các luồng mất 0,5 tới 0,7 giây; nướng mặt đất 0,48 tới 0,72 giây, trong đó tô ảnh mặt 0,32
   tới 0,52 giây khi các luồng đọc đang chiếm lõi.
2. Luồng vẽ chép lên GPU 0,2 tới 0,36 giây (534 MiB RGBA8 kèm mip).
3. Khung đầu 0,47 giây: như mục 3.1, chưa có bảng mốc.

Muốn "đủ hình ngay khung đầu" thì phải bỏ hẳn phần 1 và thu nhỏ phần 2, tức đổi quyết định "chưa
nấu hay nén tài nguyên": nấu texture giữ đúng dữ liệu BCn của tệp DDS gốc kèm chuỗi mip (không
giải mã, không nướng, dữ liệu nhỏ đi 4 tới 8 lần), và nấu sẵn ảnh mặt đất. `gpu::Format` đã có
BC1 tới BC7 (bộ đọc `.ttex` cũ của `SRC/fx` chỉ giải mip đầu ra RGBA và đã bỏ ngày 2026-10-08
cùng thư viện hiệu ứng nấu từ client cũ; lấy lại từ git ở `836f759` nếu cần tham khảo). Việc phải
làm: `resource::Image` mang dữ liệu nén và các mức mip, bộ tải lên chép thẳng khối
nén, hỏi thiết bị có nhận BCn không (PowerVR GE8320 của máy tính bảng thì không: cần ETC2 hay
ASTC, hoặc giữ đường PNG), bộ gom chép DDS gốc thay cho đổi sang PNG, và rà mọi chỗ đọc điểm ảnh
của ảnh trên CPU. Chưa làm.

## 7. Thời gian tạo PSO (2026-10-12)

`render::Catalog::prepare` in một dòng khi tầng có mục: `Pipeline: <backend> tạo <số> PSO trong <ms>`.
Sáu PSO tầng 0 vẫn tạo đồng bộ trên luồng vẽ trước khung đầu.

Đo 2026-10-12, `build/msvc-release/thienlong_client.exe --data CLIENT\data --backend vulkan --login --frames 3`,
NVIDIA GeForce RTX 5060, trình mailbox. Lần đầu (chưa có file cache): `Pipeline: vulkan tạo 6 PSO trong 227.4 ms`.
File ghi ra `CLIENT/data/cache/pipeline-vulkan-000010de-00002d05-28baf619cd26cb5f.bin` (82491 byte).
Lần sau, cùng lệnh, nạp blob đó: `Pipeline: vulkan tạo 6 PSO trong 3.2 ms`. 227 ms là phần khởi động,
không phải vài mili giây; cache đĩa kéo lần sau xuống 3.2 ms. Cả hai lần cảnh đăng nhập không có tệp
(`Scene/erengu_DL.Scene`, `Scene/tl3chuangjian.Scene`), giao diện và hiệu ứng bỏ qua vì thiếu dữ liệu,
khung cuối 0 lệnh vẽ. Số này là thời gian tạo PSO, chưa phải thời gian khung có hình.
