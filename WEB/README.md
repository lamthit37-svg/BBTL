# THIÊN LONG BÁT BỘ — Website cổng (Hỏa Long Bất Tử)

Website cổng điện ảnh cho MMORPG võ hiệp **Thiên Long Bát Bộ**: Hỏa Long bất tử đậu trên
cột đá giữa biển mây, theo dõi con trỏ người xem, gầm phun lửa khi bấm **Đăng nhập** và
chuyển cảnh lửa sang bảng đăng nhập. Toàn bộ chữ giao diện tiếng Việt có dấu chuẩn.

## Chạy và build

```bash
npm install          # một lần
npm run dev          # máy phát: http://localhost:5173
npm run build        # tsc --noEmit + vite build → dist/
npm run preview      # chạy bản build: http://localhost:4173
```

Yêu cầu: Node 20.19+ (đo trên Node 24.20). Trình duyệt đích: mọi trình duyệt WebGL2
(Chrome/Edge/Firefox/Safari 16+). Không có WebGL2 thì trang vẫn chạy với ảnh nền tĩnh.

## Chế độ ảnh (deep-link QA)

`?anh=<pha>` vào thẳng một pha của long, bỏ hoạt cảnh mở màn — dùng cho chụp kiểm định
và CI screenshot:

| Đường | Pha |
|---|---|
| `?anh=intro` | đang bay S qua biển mây |
| `?anh=circle` | bay vòng quanh đỉnh núi |
| `?anh=landing` | đang hạ xuống cột đá |
| `?anh=idle` | đậu, nhìn về người xem |
| `?anh=fire` | gầm phun lửa (lớp phủ lửa hiện) |
| `?anh=login` | bảng đăng nhập mở |

## Cấu trúc

```
src/
  app/        App.tsx (ghép trang), store.ts (máy pha + cờ UI), pointer, useReveals, mathx
  components/ Header, Hero, FireTransition (chuyển cảnh lửa 2D), LoginPanel,
              News/Classes/World/Features/Guide/Download/Community, Footer, VideoGate
  scenes/     DragonScene (Canvas + postprocessing), Environment (núi, mây, điện, cột đá,
              biển lửa, than hồng), CameraRig, layout.ts (toạ độ bố cục), glbDragon (đường model thật)
  dragon/     rig (máy pha + chuỗi thân), chain (xương sống), head, limbs, flow (bờm/râu/lửa đuôi),
              materials (vật liệu lava dùng chung)
  particles/  fireBreath (hơi thở lửa), sparks (tia lửa), embers (than hồng GPU)
  shaders/    noise GLSL dùng chung
  services/   assets (probe tài sản), auth (chỗ nối backend), audio
  styles/     global / sections / login CSS
public/       models/ videos/ audio/ images/ — tài sản thật đặt ở đây (xem docs/TAI-SAN-3D.md)
```

## Kiến trúc nhanh

- **Máy pha** (`src/app/store.ts`): `intro → circle → landing → idle → roar → login`.
  Bối cảnh 3D tự chuyển pha theo thời gian; UI gửi lệnh qua `requestLogin / requestSkip / closeLogin`.
- **Long**: chuỗi 34 đốt chạy theo đầu (relax + uốn mượt), đậu thì thân được kéo về xoắn ốc
  quanh cột đá; đầu quay theo con trỏ (giới hạn yaw/pitch, damping theo dt); chớp mắt, thở,
  xả khói mũi, tia lửa rơi khỏi thân. Toàn bộ là procedural — không cần model.
- **Vật liệu lava**: `MeshStandardMaterial` + `onBeforeCompile` (nhiễu fbm rạch khe phát sáng,
  rim nhiệt). Lưu ý: shader dùng biến `normal` của fragment, không dùng `vNormal` — để tương
  thích `flatShading` (xem bẫy đã gặp ở cuối tệp materials.ts).
- **Hiệu năng**: DPR chặn 2 (desktop) / 1.5 (mobile); quality `low` tự phát hiện (mobile/CPU yếu)
  tắt bloom + giảm hạt; dừng vòng vẽ khi tab ẩn hoặc cuộn qua hero (trừ pha roar/login);
  `prefers-reduced-motion` hoặc nút "Giảm chuyển động" ở header: bỏ hoạt cảnh, đậu ngay,
  tắt chuyển cảnh lửa, giảm biên độ chuyển động.
- **Asset thật**: khi đặt `public/models/dragon/dragon.glb` (đúng spec) trang tự dùng model rig
  thay cho long thủ công; khi đặt `public/videos/dragon_intro.webm` thì chiếu trước khi 3D vào pha.
  Âm thanh: `public/audio/ambient.webm`, `roar.webm` — chỉ phát sau khi người dùng bật loa ở header.

## Đã kiểm / chưa kiểm

- Build `tsc --noEmit` 0 lỗi; `vite build` xanh (three 0.186, R3F 9, drei 10, postprocessing 6.39, gsap 3.15).
- Đã chụp thật bằng Edge headless (SwiftShader) các pha `?anh=idle|fire|login`, hero desktop,
  hero mobile 390×844, toàn trang — chữ Việt đúng dấu, bố cục theo thiết kế.
- Chưa kiểm trên thiết bị iOS/Android thật; đường `glbDragon` chưa chạy với model thật (chưa có asset);
  âm thanh chưa kiểm (chưa có tệp). Đường preview của Vite có SPA fallback — probe asset đã lọc
  `text/html` để không nhầm trang 404 thành asset.
