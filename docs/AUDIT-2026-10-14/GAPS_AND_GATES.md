# GAPS_AND_GATES — khoảng trống, quality gates, rủi ro

Scope: so hiện trạng (AS-IS đã xác minh) với yêu cầu production-grade. Nhãn gap:
Implemented-Verified / Implemented-Unverified / Partial / Stub / Missing /
Needs-Redesign. Mọi target dưới đây là PROPOSED TARGET, không phải giá trị đạt được.

## Gap analysis (rút gọn, cái nào cũng có evidence ở FINDINGS)

| Vùng | Hiện trạng | Nhãn | Khuyến nghị (PROPOSED) |
|---|---|---|---|
| iOS build | Mã + preset có, chưa từng dựng | Missing | Dựng trên macOS, pin MoltenVK, ghi kết quả |
| Metal backend | Không có, dùng MoltenVK qua Vulkan | Needs-Redesign (nếu cần Metal gốc) | Quyết định: giữ MoltenVK hay viết backend |
| GPU time thật | API có, client chưa gọi | Partial | Gọi timestamp ở `frame.cpp`, validate 1 backend |
| Test còn thiếu | 9+ test được gọi nhưng file không có | Partial | Khôi phục file hoặc thắt `game_test` |
| Server pool `pool 2/4` | TOML có số, code 1 conn/1 luồng | Implemented-Unverified | Đọc `sql.cpp` rồi chốt pool thật |
| NPC/quái/vật phẩm | `Stage` thiếu `Actor`, `kOtherActor` stub; vũ khí: đang có file chưa track của phiên khác (`look/weapon.*`, `look/skill.*`, `avatar/locator.*`, `export_weapons/skills.py`) — đã đọc lướt, chưa audit/chưa đo | Stub (giữ nguyên tới khi vào git + qua kiểm) | Port actor theo mã máy, có test |
| Client nối server | `link` có, client chưa gọi | Stub | Nối `UiConfig` khi có module mạng (P3) |
| Migration DB | `sql/` trống | Missing | Viết migration đầu + test rollback |
| Chat/economy/AOI/snapshot | Chưa thấy implementation | Missing | Ghi vào roadmap, chưa nhận hỗ trợ |
| Perf budget | Chỉ có nạp đầu 450 ms | Partial | Thêm budget khung/VRAM/dung lượng khi có số đo |

## Quality gates (PROPOSED, hiện tại toàn là Unknown)

| Gate | Requirement | Metric | Threshold (PROPOSED) | Hiện tại |
|---|---|---|---|---|
| G-BUILD | Mọi preset dev configure+build xanh | `cmake --workflow` | pass | Unknown (BLOCKED đợt này) |
| G-TEST | ctest xanh gồm `layers` | pass rate | 100% | Unknown |
| G-SAN | ASan+UBSan sạch phần C++/test mới | findings | 0 | Unknown |
| G-PROTO | Tệp sinh còn tươi | `gen_protocol --check` | True | Pass (MEASURED 2026-10-14) |
| G-CONFIG | TOML lint xanh | `lint_config` (không `--fix`) | 0 lỗi | Pass (MEASURED 2026-10-14: 26 tệp, 437 cài đặt) |
| G-LOAD | Nạp đầu Đại Lý giữ ngân sách | trung vị bench_load | ≤ 450 ms | Unknown (số 387 ms là của 2026-10-13, không đo lại) |
| G-SECRET | Không secret trong repo | review tay mẫu quét | 0 hardcoded | Pass (VERIFIED 2026-10-14: 130 dòng) |
| G-DOC | Không link hỏng, không claim vượt coverage | self-review | 0 | Pass đợt này (2 link là ghi chú xoá) |

## TOP 5 rủi ro kỹ thuật

1. iOS/MoltenVK chưa kiểm chứng — toàn bộ phía Apple là UNKNOWN (AUD-RENDER-0001).
2. Handle thô tái cấp gây nhầm tag trong net layer (AUD-NET-0001, High).
3. `gcc-debug` xanh giả — mất server+GPU mà không báo (AUD-BUILD-0002).
4. Test thiếu bị bỏ qua im lặng — coverage tưởng cao hơn thật (AUD-BUILD-0001).
5. `SECURE_DROP_LENGTH_CHECK` và `auto_register` dev — sai một cờ là mở đường
   (AUD-SEC-0001/0002).

## Remediation backlog (ưu tiên)

1. P0: self-review + pin MoltenVK + quyết định Metal (chủ: engine render).
2. P0: generation cho tag net + test đóng-mở nhanh (AUD-NET-0001).
3. P1: thắt `game_test` + khôi phục test thiếu (AUD-BUILD-0001).
4. P1: warning khi preset bỏ module + ma trận preset×module (AUD-BUILD-0002).
5. P1: `static_assert` cấm `SECURE_DROP_LENGTH_CHECK` ở release; `auto_register`
   prod=false (AUD-SEC-0001/0002).
6. P2: gọi GPU timestamp 1 backend + validate số pace (AUD-RENDER-0003).
7. P2: `collect_* --strict` cho asset (AUD-GAME-0001).
