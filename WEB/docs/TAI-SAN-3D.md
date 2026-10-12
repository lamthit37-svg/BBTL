# Spec tài sản production — Hỏa Long, video điện ảnh, âm thanh

Trang chạy được ngay với long thủ công (procedural). Khi tài sản thật dưới đây được đặt
đúng đường, trang **tự chuyển** sang dùng chúng (probe HEAD lúc mở trang; probe lọc
`content-type: text/html` để không nhầm SPA fallback). Không cần sửa mã.

## 1. Model rồng — `public/models/dragon/dragon.glb`

Đường dùng: `src/scenes/glbDragon.tsx` (được mount thay `DragonView` khi probe thấy tệp).
**Chưa kiểm với model thật** — khớp tên theo spec này thì mới ăn.

- Định dạng: glTF 2.0 binary (.glb), trục Y-up, đơn vị mét. Kích thước tham chiếu:
  dài thân ~21 m, đầu cao ~1,6 m so với cổ. Gốc (origin) tại điểm đốt cổ đầu tiên.
- Hình học: LOD0 ≤ 60k triangle, LOD1 ≤ 25k (tắt bằng suffix `_LOD1`…, trang chưa tự chọn LOD
  — ghi rõ ở đây khi làm). Nén: `gltfpack -i in.glb -o dragon.glb -cc -tc` (meshopt + KTX2)
  hoặc Draco (`gltf-transform optimize --compress draco`).
- Vật liệu: PBR metallic-roughness. 4 bản đồ 4096² (nén KTX2 UASTC cho normal/ORM, ETC1S cho
  albedo): `albedo`, `normal`, `orm`, `emissive` (khe dung nham — emissiveIntensity 2–3).
- Xương (tên bắt buộc — mã dò theo regex `/head/i` cho đầu):
  - Chuỗi thân: `spine_00` (cổ) → `spine_27` (chóp đuôi), mỗi khớp một bone, hướng +Z dọc thân.
  - Đầu: `head` (con của `spine_00`), `jaw` (con của `head`, xoay +X để mở miệng 0–0.55 rad),
    `eye_L`, `eye_R`, `whisker_L/​R` (chuỗi 4 khớp), `horn_L/R` (tĩnh), `mane_00..05`.
  - Chân: `leg_FL/FR/RL/RR` → `_{upper,lower,paw}` → 3 móng mỗi bàn.
  - Màng/bờm: bone `mane_root` để sway.
- Animation clip (tên bắt buộc — mã khớp theo từ khoá):
  | Tên clip | Độ dài | Dùng cho pha |
  |---|---|---|
  | `fly` | 4 s, loop | intro, circle |
  | `land` | 3 s, một lần | landing |
  | `idle` | 6 s, loop | idle, login |
  | `roar` | 3,4 s, một lần | roar (khớp ROAR_T = 3,4 s của máy pha) |
- Crossfade 0,35 s do `useAnimations` tự lo; đầu vẫn được quay về phía camera bằng code
  (giới hạn ±0,55 rad yaw, ±0,32 rad pitch).

## 2. Video điện ảnh — `public/videos/*.webm`

Chỉ `dragon_intro.webm` có đường dùng thật hôm nay (`VideoGate`): chiếu toàn màn trước khi
3D vào pha intro, có nút "Bỏ qua", kết thúc thì nhảy long tới tư thế đậu. Bốn tệp còn lại
dự phòng cho phương án "video trước, 3D sau" — chưa nối; khi làm, đặt theo đúng tên:

| Tệp | Nội dung | Thời lượng | Loop |
|---|---|---|---|
| `dragon_intro.webm` | long ngoi từ biển mây, bay S tới gần | 8–10 s | không |
| `dragon_flight.webm` | bay vòng quanh đỉnh | 6 s | có |
| `dragon_landing.webm` | hạ xuống, quấn quanh cột | 5 s | không |
| `dragon_idle.webm` | đậu, thở, chớp mắt | 6 s | có |
| `dragon_fire_breath.webm` | gầm phun lửa vào máy quay | 3,5 s | không |

Spec kỹ thuật: VP9 (libvpx-vp9, `-crf 31 -b:v 0 -row-mt 1`), 1920×1080 (bản dọc 1080×1920
cho mobile nếu cần), 30 fps, yuv420p. Bản có alpha (nếu cần ghép lên nền 3D): VP9
`-pix_fmt yuva420p`; Safari không đọc VP9 alpha → giữ fallback MP4 (H.264) + ảnh poster JPEG.
Lưu ý bất biến: theo dõi chuột LUÔN làm trên 3D thật, không bao giờ "giả" bằng video.

## 3. Âm thanh — `public/audio/`

| Tệp | Nội dung | Spec |
|---|---|---|
| `ambient.webm` | gió núi + vọng trống, loop mượt | Opus 96 kbps, −18 LUFS, loop 30–60 s |
| `roar.webm` | gầm của long khi bấm Đăng nhập | Opus 160 kbps, đầu xung < 50 ms |

Chỉ phát sau cử chỉ người dùng (nút loa ở header) — đúng chính sách autoplay. Kiểm bằng
nút loa; chưa có tệp thì trang im lặng, không lỗi.

## 4. Kiểm sau khi bỏ tài sản vào

1. `npm run build && npm run preview`.
2. Mở `/?anh=idle` — long phải là model GLB (soi Network: `dragon.glb` 200, không phải HTML).
3. Bấm Đăng nhập — pha `roar` chạy clip `roar`, lửa + lớp phủ vẫn chuyển sang bảng đăng nhập.
4. `?anh=intro` — video intro chiếu, nút Bỏ qua hoạt động, xong video long đậu đúng cột.
5. Console sạch: không lỗi shader, không 404.
