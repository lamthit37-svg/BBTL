# layers C1–C3 (gốc e007c12)

| Commit | Mục đích | Kiểm nhanh GameLayers | Build target |
|---|---|---|---|
| (gốc) e007c12 | — | exit 1, 7 vi phạm (quick_base_e007c12.log, chạy ở worktree ff730cd-fix sạch) | — |
| 54e9fdc C1 | timeline.hpp → engine/core, game::core | exit 1, còn 5 (hết display/viewer→client) | display, viewer, thienlong_client: OK |
| cb0c6d0 C2 | gate→guard, classic→resource/render | exit 1, còn 2 (metrics, metrics/serve) | game_gate, guard, classic, avatar, shade_tests, gate_motion_tests: OK |
| 693a79f C3 | dòng tầng metrics, metrics/serve + game_metrics_serve | **exit 0** | full --fresh -k 0 |

## Phá thử (cả ba đều làm kiểm nhanh FAIL, đã khôi phục, không commit)
- bỏ guard khỏi gate → exit 1 `gate → guard (src/server/gate/motion.hpp)`
- bỏ resource/render khỏi classic → exit 1 `classic → render`, `classic → resource` (bake.hpp)
- bỏ dòng metrics → exit 1 `module metrics chưa có trong bảng`
- sau khôi phục: exit 0.

## Build/ctest tại 693a79f
- Build: 875/882 rồi dừng; 7 target lỗi, đúng bằng 7 lỗi có sẵn ở e98e5cd: thienlong_lint, world_tests, classic_tests, gui_sheet_tests, ui_flow_tests, wire_loop_tests, gate_tests.
- ctest (không -E): 71/85. Cùng tập 84 bài với mốc 7e1c6a4 (bỏ audio_tests, Passed): **70/84** so với 69/84.
- Khác duy nhất: `layers` Failed → **Passed**. 14 bài đỏ còn lại trùng danh sách asan_15_red.md (6 Not Run do build + 8 0xc0000409).
- gate_tests vẫn Not Run: test dùng gate::Backing/metrics::Registry chưa từng được cài trong gate (không phải lỗi bảng tầng); thuộc TL Gameplay.

## Ghi chú
- clang-format --dry-run báo vi phạm có sẵn ở prelude.hpp:109,1237-1238 và viewer_win32.cpp:436, không nằm trên dòng sửa; không định dạng lại để giữ một mục đích mỗi commit.