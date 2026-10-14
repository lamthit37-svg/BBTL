# Đường đi và vật cản theo client 2026

Chỗ nào đi được, chỗ nào bị chặn, và nhân vật đi vòng thế nào. Mã: `SRC/nav` (lưới đi, truy vấn,
luật đi), `SRC/client/map/book` (cột `.path` của bảng cảnh), `SRC/client/world` (nạp lưới theo cảnh),
`SRC/client/display/display_gpu.cpp` (`order_move`, `walk_free`, `walk_order`). Trước phần này client
đi thẳng tới điểm nhấp chuột và chỉ bị mép bản đồ chặn: leo được tường thành, đi xuyên nhà, lên được
vách núi dựng đứng vì chỉ có độ cao địa hình.

Mọi địa chỉ dưới đây là của bản client trong `F:\tl 2026\Bin64` (`Game.exe` base `0x140000000`, các
DLL base `0x180000000`). Tìm lại bằng `python TOOLS/port/pe_refs.py <tệp> func <địa chỉ>`.

## Nguồn

Client 2026 không còn tự đọc `.region` như client cũ. Mỗi cảnh có một tệp `.path` (cột thứ 6 của
`Config/SceneDefineEx.txt`), `Game.exe` giao nó cho `PathLib.dll` qua lớp bọc trong `Render.dll`:

- `PathLib.dll`: `PathDataImpl` (vtable 0x180045068) giữ lưới; `PathFinderImpl` (vtable 0x180045908)
  trả lời truy vấn. Chuỗi PDB trong DLL: `D:\Fairy_New\...\PathLib.pdb`; nó nối CGAL, libgmp và OPCODE
  cho phần dựng lưới từ `.region`, phần đó client không gọi lúc chơi.
- `Render.dll`: `CPathData` (vtable 0x1802c0248), `CPathFinder` (0x1802c0268), `CPathLibRoot`
  (0x1802c02e8) chỉ chuyển lời gọi. `CScene + 0x2090` là con trỏ tới bộ tìm đường của cảnh.
- `Game.exe`: `CPath::CreateMovePath` (0x1406d9da0), `CPath::GetPathDirect` (0x1406da140),
  `CPath::IsPointInUnreachRegion` (0x1406da6c0), hàm chọn cách đi của `CAI_MySelf` (0x1406199b0),
  `CScene::IsValidPosition` (0x1406be3a0).
- `tEngine.dll`: `fVector2::normalise` (0x18000d3e0) và `TDU_GetDistSq`.

Kho `_raw` có 419 tệp `.path` cho 513 tệp cảnh của kho (bảng `Config/SceneDefineEx.txt` mà client đang nạp chỉ
có 297 dòng dữ liệu). Cảnh không có tệp (ví dụ `dali.path`) thì
client này cho đi thẳng không vật cản; bản gốc ở cảnh như vậy không ra được lệnh đi nào (chưa thử
trên client gốc, suy từ mã: `direct` trả false khi không có dữ liệu).

## Tệp `.path`

Số little-endian. u16 mã bản: `0x2000` (số đếm và chỉ số 32 bit) hoặc `0x1000` (16 bit). Rồi:

1. số đỉnh; mỗi đỉnh f32 x, f32 z, đơn vị game (một đơn vị là một ô lưới của cảnh);
2. số tam giác; mỗi tam giác ba chỉ số đỉnh, ba chỉ số tam giác hàng xóm (hàng xóm k nằm đối diện
   đỉnh k), u8 cờ (bit 0 vật cản, bit 1 bay qua được), chỉ số đảo (các tam giác đi được liền nhau
   chung một số; vật cản là 0): 29 byte ở bản rộng, 15 byte ở bản hẹp;
3. số cạnh ràng buộc; mỗi cạnh hai chỉ số đỉnh, tam giác vật cản và tam giác đi được hai bên;
4. đầu lưới tra: u32 cỡ ô, số cột, số hàng;
5. từng ô theo hàng: số tam giác, số cạnh, rồi các chỉ số tam giác và các chỉ số cạnh chạm ô đó.

"Không có" là 1000000 ở bản rộng và 0xFFFF ở bản hẹp. Bộ đọc (`nav::read_mesh`, theo
`PathDataImpl::getDataFromMemory` 0x18001c6f0) khớp đúng số byte của cả 419 tệp. Số liệu trên 419
tệp: lưới lớn nhất 89.986 tam giác (`bianjing`), lưới tra lớn nhất 16.384 ô, danh sách của một ô dài
nhất 318; mọi cạnh nằm giữa một tam giác vật cản và một tam giác đi được; 906.853 đỉnh có đúng hai
cạnh ràng buộc, 1.840 đỉnh có một, 7 đỉnh có bốn.

Hai tệp bản hẹp của client (`luoyang_MD`, `wending`) ghi cỡ ô bằng 16 bit trong khi bản gốc luôn đọc
32 bit, nên cỡ ô ra 4.194.312 và mọi điểm rơi vào ô (0, 0): ở hai cảnh đó bản gốc chỉ thấy vật cản
của ô đầu tiên. Bộ đọc giữ nguyên hành vi này.

Khác gốc ở bộ đọc: bản gốc tin mọi chỉ số; ở đây chỉ số ngoài bảng, toạ độ không hữu hạn, cỡ ô 0,
số ô vượt trần hay vượt phần còn lại của tệp, tệp từ 1 GiB đều là lỗi. Hàng xóm 0xFFFF của bản hẹp
thành "không có" (bản gốc đem số đó đi tra bảng).

## Truy vấn (`SRC/nav/finder.cpp`)

Số thực 32 bit, giữ đúng thứ tự phép toán của mã máy; module dựng với `-ffp-contract=off`.

- **Ô chứa điểm**: phần nguyên của toạ độ chia cỡ ô.
- **Điểm trong tam giác** (0x1800117f0): ba tích có hướng cùng dấu; tích có trị tuyệt đối không quá
  1e-6 coi như điểm nằm trên cạnh và bỏ qua cạnh đó. `locate` (0x18002c160) duyệt tam giác của ô theo
  thứ tự trong tệp và trả tam giác đầu tiên đúng loại (đi được hoặc vật cản).
- **Giao hai đoạn** (0x180031e00): tham số trong [0, 1] kể cả hai đầu; mẫu số có trị tuyệt đối không
  quá 1,19e-7 coi như song song.
- **Chỗ đoạn thẳng cắt cạnh ràng buộc** (`direct`, 0x18002a580): đi qua các ô dọc đoạn theo trục
  chính, mỗi bước thử ô giữa và hai ô kề theo trục phụ; chỗ cắt xếp theo bình phương khoảng cách tới
  đầu đoạn trong một `std::set`, hai chỗ cùng khoảng cách chỉ giữ chỗ gặp trước.
- **Tìm đường** (0x1800287c0): hai đầu phải nằm trên tam giác đi được cùng đảo. Nhìn thẳng được thì
  đường là hai điểm. Không thì A* trên tam giác (0x180027db0): chi phí là quãng từ điểm vào tam giác
  hiện tại tới trung điểm cạnh chung, ước lượng là khoảng cách từ trọng tâm tới đích, hàng đợi là đống
  nhị phân viết tay so bằng `>=`, tam giác đã đóng gặp đường ngắn hơn thì sửa số mà không mở lại.
  Rồi kéo căng đường qua dãy cửa, dời mỗi điểm rẽ khỏi đỉnh 0,1 theo phân giác ngoài của hai cạnh
  ràng buộc tại đỉnh (điểm dời rơi vào vật cản thì thử nửa quãng, một phần tư...), cuối cùng tỉa: từ
  mỗi điểm giữ lại nhảy tới điểm xa nhất còn nhìn thấy; không thấy điểm nào thì lấy điểm kế.

## Luật đi (`SRC/nav/route.cpp`)

- Vị trí hợp lệ (`is_inside`): toạ độ là số và nằm trong [0, cỡ cảnh] kể cả hai mép.
- Không tới được (`is_unreachable`): ngoài cảnh hoặc nằm trên tam giác vật cản.
- Đi thẳng (`straight_stop`, `GetPathDirect` khi không bay): hai đầu hợp lệ. Đang trong vật cản mà
  đích là chỗ đi được: đi thẳng tới đích nếu chỉ phải qua không quá một cạnh, không thì từ chối. Còn
  lại: không vướng thì tới đích; vướng thì dừng ở chỗ cắt đầu tiên lùi 0,1 về phía mình (điểm lùi
  vẫn trong vật cản thì dừng ngay chỗ cắt). Quãng có bình phương độ dài dưới 2 thì từ chối. Phép lùi
  chuẩn hoá vector bằng căn nghịch đảo nhanh (hằng 0x5f3759df, một bước Newton), giữ nguyên.
- Chọn cách đi (`plan_move`, 0x1406199b0): đích phải hợp lệ. Giữ chuột chạy theo con trỏ (cờ
  `+0x14c` của trạng thái chuột): đang trong vật cản thì từ chối, không thì đi thẳng. Nhấp chuột:
  đang trong vật cản mà đích đi được thì đi thẳng ra; không thì tìm đường, có đường thì đi theo các
  điểm của nó; không có đường thì đi thẳng tới sát vật cản, trừ khi đang trong vật cản.
- Bước theo phím đi và cần gạt (`step_reach`) không có ở bản gốc: bước dừng 0,1 trước vật cản đầu
  tiên, không kết thúc trong vật cản; đang trong vật cản thì chỉ bước ra được.

## Trọng tài

`TOOLS/port/pathlib_oracle.py` nạp chính `PathLib.dll` và `tEngine.dll` bằng `ctypes`, gọi hàm ảo
theo số ô (nạp dữ liệu 3, khởi tạo bộ tìm 1, tìm đường 3, cắt cạnh 5, định vị 6, số điểm 7, điểm 8),
đọc `std::set` chỗ cắt ngay trong bộ nhớ của DLL, và ghi câu trả lời thành tệp số vàng, số thực
bằng mẫu bit. Dòng `stop` đi lại các bước của `GetPathDirect` (hàm đó nằm trong `Game.exe`, không gọi
rời được) bằng chỗ cắt, phép định vị và phép chuẩn hoá của DLL gốc.

```
python TOOLS/port/make_path_mesh.py <yard.path>
python TOOLS/port/pathlib_oracle.py golden "F:/tl 2026/Bin64" <yard.path> tests/golden/nav_yard.tsv --queries 200 --embed --probe 13.6 9.6 14.8 11.4 --probe 14.8 11.4 13.6 9.6
python TOOLS/port/pathlib_oracle.py golden "F:/tl 2026/Bin64" CLIENT/data/Scene/huoyangu.path tests/golden/nav_huoyangu.tsv --queries 200
```

`make_path_mesh.py` sinh lưới tự vẽ (44 đỉnh, 82 tam giác, 40 cạnh ràng buộc, hai đảo, một khe rộng
0,05) nhúng trong `nav_yard.tsv`, để test chạy không cần dữ liệu client.

## Số đo khớp (2026-10-08)

- `nav_tests`, so từng bit với DLL gốc: lưới tự vẽ 200 định vị, 200 cắt cạnh, 402 tìm đường, 200 chỗ
  dừng; cảnh `huoyangu` 200, 200, 400, 200. Lệch 0 dòng ở `gcc-debug`, `clang-asan`, `msvc-release`.
- Bản mẫu Python của cùng thuật toán (trước khi viết C++): 2.850 truy vấn tìm đường ngẫu nhiên trên
  bốn cảnh, 2.846 trùng từng bit; 4 ca lệch đều là nhánh "thử nửa quãng", sau đó đã thêm.
- Phép chuẩn hoá vector: 7 trên 7 ca trùng `tEngine.dll` từng bit.
- Răng của test: 17 đột biến trong `SRC/nav`, 13 bị bắt. Bốn cái sống: bỏ lối tắt nhìn thẳng và cho
  thoát vật cản qua hai cạnh (cho cùng kết quả: phép tỉa cũng ra hai điểm; số cạnh phải qua luôn
  lẻ), và hai phép so `>=` của A* (chỉ khác khi hai chi phí bằng nhau tuyệt đối, chưa có ca thử).

## Khác gốc và phần chưa làm

- Kéo căng đường viết theo thuật toán phễu chuẩn, không chép hai chuỗi trái phải của 0x1800288d0;
  đúng sai của nó đo bằng số vàng ở trên.
- Ở đỉnh mà ô chứa nó liệt kê chưa đủ hai cạnh ràng buộc của nó, bản gốc dùng lại hai đỉnh kề của
  điểm rẽ trước, và ở điểm rẽ đầu tiên thì đọc ngăn xếp chưa khởi tạo. Ở đây điểm rẽ đầu tiên như
  vậy không dời. Lưới thử có đỉnh nằm giữa vùng trống (thứ dữ liệu thật gần như không có) lệch bản
  gốc ở 29 trên 400 đường đi vì đúng chỗ này; lưới thử hiện tại không có đỉnh như vậy.
- Góc không né được ở bán kính nào: bản gốc đổi sang thuật toán dự phòng 0x18002cd60, chưa port; ở
  đây điểm rẽ nằm ngay đỉnh.
- Vùng cấm động do máy chủ bật (0x1800236f0) chưa có: client nối máy chủ từ 2026-10-15 nhưng chưa xử lý tin này.
- Trạng thái bay (hàm ảo `+0x288` của nhân vật): đi thẳng, bỏ qua vật cản có cờ bay qua được; chưa
  port.
- Câu báo "không tới được" của giao diện chưa có. Bản gốc ghi log khi đường dài hơn 16 đoạn; chỗ cắt
  bớt đường (nếu có) chưa đọc, ở đây đường dài bao nhiêu cũng đi hết.
- Mặt đi được của công trình (`.WCollision`: cầu, bậc thang) là việc riêng,
  `docs/giao-viec/DH-DOT-1/DE-BAI.md`. Từ 2026-10-08 đã có `SRC/collision` (bộ đọc, lưới, cây
  OPCODE) và `docs/VA-CHAM-2026.md`; truy vấn độ cao và tia chưa có, client chưa dùng.
- Android: test số vàng không chạy trên thiết bị (tệp số vàng nằm ở máy dựng), nên khớp từng bit
  trên arm64 chưa được kiểm.
