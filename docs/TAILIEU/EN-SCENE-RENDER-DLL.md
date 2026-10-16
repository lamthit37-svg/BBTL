# Bầu trời EnScene của Render.dll (client 2026) — mã máy đã tháo

Ghi 2026-10-16. Nguồn: Render.dll (Ghidra, dự án `TLBB`; lệnh `TOOLS/port/ghidra/DecompileAt.java`,
khoá `g:` mới thêm để decompile cả khoảng địa chỉ), Game.exe, shader gốc
`F:\tl 2026\_goc\MaterialTemplates\EnScene.hlsl` và vật liệu `Material\all.material` (đoạn
`EnScene/*`). Địa chỉ dưới đây là địa chỉ ảo của Render.dll (gốc ảnh 0x180000000).

## 1. Tệp và nạp

- `.Scene` có `Object type="EnScene" name="#FairyEnScene"` với `Property config_file`. Cảnh đăng nhập
  `erengu_DL.Scene` trỏ tới `erengu_DL.EnScene`. 203 tệp `.EnScene`, 260 khối `<EnSky>`; 28 cảnh có cả
  `.skysphere` (bầu trời đời cũ), 260 cảnh chỉ có `.skysphere`, 175 chỉ có `.EnScene`.
- XML mã hoá UTF-8 hoặc GBK (tên ảnh tiếng Hán): thử UTF-8, hỏng thì GBK.
- Cấu trúc: `EnScene` > (`EnRegionComposite` > `EnRegion name maxAffectDistance` > `RegionGroups`,
  `polygon`/`Point`, `EnSky`) hoặc `EnSky` ngay dưới gốc (145 tệp). `EnSky` có `SkyDome`, `SkyClouds`
  (`SkyCloudsLayer`), `SkyRingClouds` (`RingCloudsLayer`), `Star`, `Moon`, `Sun`, `Effects`, `Ocean`,
  `LightAndFog` (`EnvKey`). Mỗi lớp mây có `TimeNodesInfo` > `TimeNode time=...`.
- Ảnh nằm ở `Material/`; tệp nấu `.tga` thành `<tên>.tga.png`. Mesh: `enskydome.mesh`,
  `enskycloud.mesh`, `ringcloud.mesh`, `ZMcloud.mesh` (bản nấu `.mesh.glb`).

## 2. Đồng hồ trời (0x1800ddf40)

- Một đối tượng toàn cục `DAT_1803b5d68`: [0] cờ dừng, [4] float 60,0, [8] phần ngày 0..1, [0xc] 0.
- Khởi tạo: không dừng, phần ngày 0. Mỗi lần đọc cộng `ms * 0,001 / 60` (một ngày chạy 60 giây),
  vượt 1,0 thì trừ 1,0 (DAT_1802bbd8c = 1,0; DAT_1802d4b90 = 0,001 kiểu double).
- Giờ = phần ngày * 24, kẹp: nếu >= 23,999 thì 23,999 (0x1802fbe0c = 24, fbe04 = 23,9 và fbe08 = 23,999).
- `+0x350(this, ngày, phần)` của đối tượng engine (Game.exe) dừng đồng hồ và đặt phần ngày. Game.exe
  `GamePro_Main` (0x14064e7d0) đặt phần = giờ máy chủ / 8,64e7 kẹp 0,01..0,99 (hoặc 0,5 khi cờ
  `+0x5efa00`); `CharSel` đặt 0,9479; `CharCreate` đặt 0,1330. **Màn đăng nhập
  (`CGamePro_Login::Init` 0x140630fd0) không gọi `+0x350`**: đồng hồ chạy tự do từ 0 lúc Render.dll
  khởi tạo.
- Cờ `EnSky+0x3bc` = máy hỗ trợ ps_2_0 và vs_2_0. Không hỗ trợ thì giờ cố định 12 và vòm cũ
  `#FairySkyDome`; mọi máy hiện nay là hỗ trợ.

## 3. Thứ tự vẽ (Ogre)

- Vòm: nhóm hàng đợi 5, ưu tiên 100 (trước thế giới). Depth: kiểm `less_equal`, không ghi.
- Mọi thứ còn lại nằm nhóm 59 (sau nhóm chính 50, nên sau cả hạt):
  - lớp mây (`cloud_`): ưu tiên 90 + layer.
  - lớp mây vòng (`ringcloud_`): ưu tiên 110 + layer.
  - trăng: 90 + layer (mặc định 115 lúc tạo), mặt trời `_` 95 khi tạo (cũng 90 + layer sau khi áp cấu hình).
  - sao: nhóm 57 ưu tiên 99.
- Cùng ưu tiên: vật trong suốt xếp theo khoảng cách tới camera giảm dần (xa trước); mây đặt tại camera
  nên khoảng cách 0, trăng ở 9000. Hoà thì theo thứ tự tạo (thứ tự tệp).
- Mọi lớp ghi z = w * 0,999999 (vòm, mây, mây vòng) hoặc z = w (trăng, mặt trời): sát mặt xa.
  Nhân thêm `far_clip - 100` vào clip không đổi điểm chiếu, bỏ.

## 4. Vòm `EnScene/skyDome` (class EnDome 0x180238990, `En_sky_dome_v/p`)

- Mesh `enskydome.mesh`, entity `en_skydome`, nút tại vị trí camera mỗi khung (0x180239890).
- Cấu hình XML -> đối tượng: `texture` = ảnh rayleigh (đơn vị 1), ảnh `TextureUnitEx` (đơn vị 2) lấy cùng
  ảnh khi tệp không khai `textureEx` (mọi tệp thật chỉ có `texture`); đơn vị 0 là `mie_gradient.dds`
  (vật liệu). Địa chỉ ảnh rayleigh: U lặp, V kẹp (tamU=0, tamV=2).
- Tham số: `hight` -> HIGHT (cộng vào y đỉnh), `mieAmount` -> mie (0,01), `vertexHeightEffect`,
  `sunHeightEffect`, `power`; TURBIDITY cố định 0,2 (không có trong XML); `weight` = 1 (cfg[+0x314] /
  (cfg[+0x314] + cfg[+0x318]) = 1/(1+0)).
- `EN_DOME_PARAM1 = (giờ/24, HIGHT, mie)`, `EN_DOME_PARAM2 = (TURBIDITY, vertexHeightEffect,
  sunHeightEffect, power)`, `SUN_POSITION` = hướng mặt trời (chuẩn hoá), `SUN_COLOUR` = màu `light_one`.
- Pixel: `ray = tex(rayleigh, (giờ/24, saturate(1 - nrm.y)))`; `mie = tex(mie_gradient, t*mieAmount)` với
  `t = pow(fwd,power) + saturate(fwd*(horizonV*horizonS*vHE + sun.y*nrm.y*sHE) + turbidity)`,
  `fwd = saturate(dot(nrm, sunPos))`; `rgb = ray.rgb*ray.a*weight`; `rgb += mie.rgb*rgb`;
  `rgb *= skydome_ambient_color.xyz * .w`. Kết hợp `scene_blend one zero`.
- `skydome_ambient_color` = `(skyDomeAmbientColor, skyDomeAmbientColorStrength)` của EnvKey
  (`setSkyDomeAmbientColor`, 0x1801e8130).

## 5. Lớp mây `EnScene/cloud` (class EnCloud 0x180239b00, cập nhật 0x18023a9b0)

- Mặc định: mesh `enskycloud.mesh`, ảnh sương `bmp_overhead_weak_fog.dds` (kẹp cả hai trục, đơn vị 1),
  ảnh mây (lặp, đơn vị 0).
- Nút đặt tại camera; `rotangle` = quay yaw (rad); `turnoverMesh` = lật PI quanh trục z cục bộ (roll).
- `textureTile (x y z w)`: `z` ghi đè mỗi khung = `skyCloudHeight * 15` (cộng vào y đỉnh).
- `windSpeed += cloudspeed * dt * 0,1` mỗi khung.
- `control = (fog, cloudspeed, ambientBlend, alpha)`; `rimParam = (rimStrength, rimPower, rimDetectPower,
  rimDetectWidth)`; `dLight = (hướng mặt trời, scatteringStrength)`; `lcolor = (màu light_one,
  scatteringPower)`.
- Vertex: `p = pos + (0, tile.z, 0)`; `normal = normalize(float4(R*S*p, 1)).xyz` (không tịnh tiến);
  `uv = tc * tile.xy + (0, windSpeed)`; `ntc = tc`.
- Pixel: xem `cloudLighting` trong EnScene.hlsl: `light = saturate(dot(normalize(dLight.xyz), normal))`,
  `diffuse = map*ambient*surfaceAmbient*control.z + map*(1-control.z)` (ambient = ambient của EnvKey,
  surfaceAmbient = 1), `colour = diffuse + lcolor*pow(light,sP)*sS + lcolor*litRim*rS`, `litRim =
  pow(1 - saturate(a - rimDetectWidth), rimDetectPower) * pow(light, rimPower)`; `fogAmount =
  saturate(tex(fog, ntc) + control.x)`; `rgb = lerp(rgb, fogColour, fogAmount)`; `alpha = a *
  control.w`. Phép tính trong không gian gamma (đích không sRGB).
- Lớp chỉ được tạo khi alpha > 1e-6 (double ở 0x1802e9370); alpha <= đó thì đối tượng bị xoá.
- Vật liệu `EnScene/cloudocclusion` (zero one, ghi sâu, alpha_reject >= alpha*150) chỉ dùng để đo che
  khuất mặt trời.

## 6. Lớp mây vòng `EnScene/ringcloud` (class EnRingCloud 0x18023b0f0, cập nhật 0x18023bf50)

- Mesh `ringcloud.mesh` hoặc `ZMcloud.mesh`; ảnh sương `bmp_horizon_fog_strong.dds` (U lặp, V kẹp).
- Mọi nút là con của nút chung `EnRingCloudRoot`. Mỗi khung: vị trí = camera + (0, CloudHeight, 0);
  tỉ lệ (1, CloudScale, 1); hướng:
  - `rollspeed == 0`: tuyệt đối, yaw `CloudOffset` độ (w = cos(o*pi/360), y = sin(o*pi/360)); nếu
    `turnoverMesh` thì thêm roll PI.
  - `rollspeed != 0`: yaw cộng dồn `rollspeed * dt * deg2rad` (độ trên giây).
- `vOffset += verticalSpeed * dt`, quấn vào [-1, 1] (v > 1 thì -1; v < -1 thì +1). Địa chỉ V của ảnh mây
  là kẹp khi vOffset == 0, lặp khi khác 0 (U lặp, W kẹp).
- `offsetParam = (TextureRepeat, vOffset, parallax, 1)`; `control = (fogblend, fadeRange, ambientBlend,
  alpha)`; rimParam/dLight/lcolor như mây.
- Vertex: `pos.y -= camera.y * parallax * 1e-6`; `normal = normalize(R*S*pos)`; `uv = (tc.x*repeat,
  tc.y + vOffset)`, `ntc = (tc.x*repeat, tc.y)`.
- Pixel: như mây, thêm `edge = -2*|ntc.y - 0,5| + 1`; `alpha = a * min(edge/(fadeRange+1e-5), 1) *
  control.w`.

## 7. Nội suy TimeNode (0x1802087a0 mây, 0x180208a50 vòng, 0x180207570 EnvKey)

Bảng `map<float time, giá trị>` tuần hoàn 24 giờ: tìm cặp (prev, next) có `prev.time <= giờ <
next.time`, prev đầu là nút cuối trừ 24 giờ, sau nút cuối nối về nút đầu cộng 24 giờ; nội suy tuyến
tính. Cập nhật khi giờ đổi hơn `DAT_1802c757c`. Mây cho (fog, alpha, cloudspeed, ambientBlend); vòng
cho (fogblend, ambientBlend, alpha, fadeRange, rollspeed, verticalSpeed).

## 8. Trăng và mặt trời (0x180235190, 0x180235780, 0x1802359a0, 0x180237050)

- Entity = mặt phẳng dựng sẵn của Ogre (PT_PLANE: 100 x 100, pháp tuyến +Z, uv 0..1), nút gốc đặt tại
  camera, nút con dịch (0, 0, -9000) cho trăng và (0, 0, +9003) cho mặt trời, tỉ lệ đều `scale`.
- Hướng nút gốc: `resetOrientation`; rồi xoay cục bộ (nhân sau): `q1 = (moonOrient + 180)° quanh -Y`,
  `q2 = -moonAngle° quanh -X`, rồi nếu không `fix`: `q3 = p*360° quanh -Y`.
- `p` theo giờ h, với (start, end): mặt trời start = sunUpTime (+0xe0), end = sunDownTime (+0xe4);
  trăng start = moonDownTime (+0x58), end = moonUpTime (+0x54). Đã đối chiếu từng nhánh trên mã máy:
  - end >= start: h > end thì `(h-end)/(((24-end)+start)*2)+0,75`; h < start thì
    `(h+24-end)/(((24-end)+start)*2)+0,75`; còn lại `(h-start)/((end-start)*2)+0,25`.
  - end < start: h > start thì `(h-start)/((end+24-start)*2)+0,25`; h < end thì
    `(h+24-start)/((end+24-start)*2)+0,25`; còn lại `(h-end)/((start-end)*2)+0,75`.
  - Cờ `fix` (moonfix/sunfix): mặt trời p = 0,5; trăng bỏ q3.
- Hướng ánh sáng dùng cho dome/mây = chuẩn hoá(vị trí nút con - vị trí nút gốc) tính cả khi mặt trời tắt.
- Vật liệu: `EnScene/moon` alpha_blend, depth_check on, depth_write off, less_equal; shader
  `En_sunandmoon_*`: z = w, màu = ảnh.
- Ưu tiên nhóm 59: `layer + 90`.
- Nút con của mặt trời gọi `lookAt(DAT_1803c7b90 = (0,0,0), TS_LOCAL, NEGATIVE_UNIT_Z)` (hàm ảo +0x368,
  0x1802359a0). Với TS_LOCAL gốc là ZERO nên hướng = (0,0,0) - ZERO = vectơ không, `setDirection` thoát ngay:
  **lookAt là lệnh rỗng**, nút con giữ hướng của nút gốc. Mặt phẳng mặt trời ở +9003 có pháp tuyến +Z đi xa
  camera, nên bị loại mặt sau như bản gốc (vật liệu `EnScene/sun` mặc định loại mặt kim đồng hồ); chú thích
  trong all.material ghi vật liệu ấy chỉ để đo che khuất. Thứ người chơi thấy là chùm sáng (sunflare,
  lens flare), chưa dựng.

## 8b. Sao `EnStar` / `FixedStar` (0x1802385b0, 0x180237590; shader `FixStar.hlsl`)

- Đối tượng `en_star` đặt tại vị trí camera mỗi khung (hướng đơn vị). Hàng đợi nhóm 57 ưu tiên 99, tức
  sau thế giới và trước nhóm 59; vật liệu `SkySphere/FixedStar`: `scene_blend src_alpha one`, `depth_write
  off`, `point_sprites on`. Chỉ vẽ khi độ hiện `0x234 > 0`.
- Hàm dựng đặt: 2000 sao, bán kính 10000, cỡ 10, `0x214` = 1 (StarIntensity), tốc độ nhấp nháy 0,2, màu nhỏ
  nhất (0,5 0,5 0,5 0,5), màu lớn nhất đặt (1 1 1 1). `EnSky::applyStar` (0x1801ea040) chỉ chạy khi
  `Enable` và gọi theo thứ tự: màu nhỏ, cỡ, cường độ, tốc độ nhấp nháy, số sao, bán kính, màu lớn, cờ `starfix`.
- Setter có ngưỡng: số sao chỉ đổi khi lệch hơn 2 và khác 0 (0x1802383d0); bán kính khi lệch hơn 0,01
  (0x180238390); màu (0x180238200, 0x180238430) chỉ đổi khi **cả bốn kênh** lệch từ 0,05, nối bằng VÀ. Màu lớn
  nhất dựng sẵn là (0 1 1 1) nên EndColour (1 1 1 1) chỉ lệch kênh đỏ và bị bỏ: sao có đỏ trong [0, 0,5],
  xanh lục, xanh lam và độ sáng trong [0,5, 1], tức tông xanh lục. Giữ nguyên như mã máy.
- Dựng đỉnh (0x180237ae0): sao đầu tiên sinh lúc bán kính còn 0 nên nằm ở gốc và không bao giờ lên màn
  hình; sao còn lại: góc quay `RangeRandom(0, 2π)`, góc nghiêng `RangeRandom(0, π/2)`, vị trí
  `(sin(nghiêng)·cos(quay), cos(nghiêng), sin(nghiêng)·sin(quay)) · bán kính` (chỉ nửa trên); màu bốn lần
  `RangeRandom(nhỏ, lớn)` theo r, g, b, a rồi cắt (không làm tròn) c·255 xuống 8 bit. Vị trí sinh một lần,
  đổi bán kính sau đó không dời sao đã có.
- Độ hiện theo giờ (0x1802388e0): `(|giờ/24 − 0,5| − 0,3) · 4`, hoặc 0,8 khi `starfix`. Giữa trưa là âm nên
  không vẽ; hiện từ 19,2 giờ tới 4,8 giờ.
- Nhấp nháy (0x1801d4020, controller FrameTimePassthrough tạo ở `_notifyAttached` 0x1801d3e70): `pha +=
  tốc độ · dt`; chạm 1 (tốc độ dương) hay 0 (tốc độ âm) thì đảo dấu tốc độ (nhân −1). Pha vào `StarSize.w`.
- Shader: `StarSize = (cỡ, cỡ, 0, pha)`, `StarParams = (cường độ, độ hiện)`. VS: `z = w`, độ sáng ngẫu nhiên
  `appMag = 6,5 + a·(−1,44 − 6,5)`, `brightness = nhấp_nháy(pos.xy) · 5^((−appMag − 1,44)/2,5)`, màu
  `(brightness·rgb, brightness)`, `PSIZE = StarSize.xy`. PS: `scale = exp(−|3,5·(uv − 0,5)|²)`, màu
  `cường_độ · (rgb·scale + 5·brightness·scale^10)`, alpha `brightness · độ_hiện`.
- Cài đặt: D3D12 và Vulkan không có kích thước điểm nên mỗi sao là hình chữ nhật bốn đỉnh cỡ `StarSize.xy` điểm
  ảnh (dùng chiều cao khung thật của camera); kết quả nhân sẵn alpha rồi cộng một một để phép cộng gần với bản
  gốc làm trong không gian gamma. Hạt giống ngẫu nhiên cố định (bản gốc dùng `rand()`).
- Cảnh đăng nhập `erengu_DL` tắt sao; 40 cảnh khác bật (đã kiểm bằng bản chép tạm của erengu_DL với
  `Enable="true"`).

## 9. Áp EnvKey (0x1801e8130)

Mỗi khung đặt vào cảnh: ambient, `fog.colour`, `fog.linear start/end` (từ `fog_near_distance`,
`fog_far_distance`), đèn chính một và hai (`diffuse` = light_*, `specular`, `intensity`, `direction` chỉ
khi khác 0), ánh sáng nhân vật (`actor_light_one/two/ambient`), `pbr_ambient`, `skyDomeAmbientColor`
(w = strength), `height_fog_param`, hậu kỳ (warm/cold, contrast, overlay, radial blur); lưu
`EnSky+0x398..0x3a0` = màu `light_one` (đưa vào `lcolor` của mây).

## 10. Vùng (EnRegionComposite)

- Trọng số mỗi vùng tính từ vị trí camera và `maxAffectDistance` (0x18020f490); vùng tên `backgroud`
  nhận `1 - tổng trọng số các vùng khác` (về 0 khi tổng >= 1) (0x18020f270). Một vùng `backgroud` duy nhất
  luôn có trọng số 1.
- Tham số cấu hình (không phải alpha) của lớp cùng tên được cộng theo trọng số rồi chia tổng trọng số
  (`fVar1 = 1 / tổng`); `alpha` thì không chia nên mờ dần ra ngoài vùng.

## 11. Cảnh đăng nhập `erengu_DL.EnScene`

Một vùng `backgroud`, trọng số 1. Vòm `DJLTyewan_color1.tga` (64 x 256, đồng nhất theo giờ), hight -573.
Bốn lớp mây `alpha=0` (không tạo). Chín lớp mây vòng, bảy lớp alpha > 0. Sao tắt, mặt trời tắt (hướng vẫn
tính), trăng `erengumoon_red.png` scale 11, `moonfix=true`, moonOrient 344, moonAngle 9, layer 30
(ưu tiên 120). Một EnvKey duy nhất (time 0): ambient (0,267 0,286 0,337), sương (0,090 0,176 0,239)
1000..25000, light_one (0,639 0,722 0,757) hướng (-0,3 -0,3 -0,5), skyDomeAmbientColor 1 1 1 độ mạnh 1.
Hiệu ứng `cj_挂屏_风吹落叶` (lá rơi gắn màn hình).

## 12. Trạng thái cài đặt (2026-10-16)

Đã dựng, đã kiểm bằng chạy và chụp: vòm, lớp mây, mây vòng, trăng, mặt trời (mặt phẳng, bị loại mặt sau như
bản gốc), sao, EnvKey đổi ánh sáng thế giới, hiệu ứng nền gắn `en_effect` tại camera, đồng hồ ngày chạy tự do
ở màn đăng nhập và ghim 12 giờ ở màn chơi.

Chưa dựng: chùm sáng mặt trời (sunflare, cường độ theo truy vấn che khuất GPU), lens flare (không cảnh nào
dùng), trộn nhiều vùng theo trọng số (36 cảnh; hiện chỉ lấy vùng `backgroud` hoặc vùng đầu), tắt dải
`.skysphere` cũ ở cảnh đã có EnScene, đồng hồ ghim của màn chọn và tạo nhân vật, các trường EnvKey còn lại
(`pbr_ambient`, `height_fog_param`, hậu kỳ), gom tài sản bầu trời của các map khác `erengu_DL` (chạy
`TOOLS/content/collect_sky.py`).
