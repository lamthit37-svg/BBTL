## Bảng tiêu chí

| mã | đạt hay không | lệnh đã chạy | dòng output quyết định | tệp log |
|---|---|---|---|---|
| T1 | đạt (bộ đọc Python cùng thuật toán; L chốt) | `python -B TOOLS/port/make_building_file.py scan "F:\tl 2026\_raw\Scene" --tsv docs/giao-viec/DH-DOT-1/so-do/b-t1-tep-2.tsv` (make_building_file.py 7ffb8981…) | `tổng: 435 tệp, 75847042 byte`; `mã 0xFF000001: 125 tệp`; `mã 0xFF000002: 310 tệp`; `tệp nhận: 435; trong đó số byte đọc khác cỡ tệp: 0`; `bị từ chối: 0 tệp` | `so-do/b-t1-scan-2.log` (610a1fad…), `so-do/b-t1-tep-2.tsv` |
| T2 | CHỜ: C (Model, B3) và Build & Test (`collision_bench --verify`), 18:00 | | | |
| T3 | CHỜ: A và C, sau B3. Hiện tại: V-2 20000/20000 lệch 0 trên gcc-debug và msvc-release; `collision_tests` trả 77 (Skipped) vì các ca chờ Model của C | | | `so-do/a-v2-xanh-lan1.log` (bc81e2c9…) |
| T4 | CHỜ: Build & Test, ctest lượt 2 ba preset | | | |
| T5 | CHỜ: A, C, Build & Test (mỗi vai cho tệp C++ của mình), 17:30 | | | |
| T6 | không đạt (16:20, `so-do/b-t6-lint.log` 4c228c6b, exit 1): `fuzz_building.py:211: hàm main dài 71 dòng, quá 50` và `fuzz_building.py:1: chuỗi có đường dẫn ổ đĩa Windows` (0427e5cd, của Build & Test); `building_oracle.py` a82afed9 và `make_building_file.py` a095e976 sạch | | | |
| T7 | CHỜ: L, cuối đợt | | | |
| T8 | CHỜ: C, 17:00 (`docs/VA-CHAM-2026.md`) | | | |
| G1 | CHỜ: A | | | |
| G2 | CHỜ: A | | | |
| G3 | CHỜ: A | | | |
| G4 | CHỜ: Build & Test | | | |
| G5 | CHỜ: Build & Test (lượt 2 đang chạy) | | | |
| G6 | CHỜ: Build & Test, 17:30 | | | |
| G7 | CHỜ: Build & Test, 17:30 | | | |
| G8 | CHỜ: C, sau B3 | | | |
| G9 | CHỜ: L hoặc R, cuối đợt | | | |
| G10 | CHỜ: A, 16:40 | | | |
| G11 | CHỜ: A, sau G5 lượt 2 | | | |
| G12 | CHỜ: L hoặc R, cuối đợt | | | |
| H1 | CHỜ: C và A, sau B3 | | | |
| H2 | CHỜ: C và A, sau B3 | | | |
| H3 | CHỜ: Build & Test, sau B3 (phía DLL đã đo, xem Bảng số đo) | | | |
| H4 | CHỜ: Build & Test và C, B5 | | | |
| H5 | CHỜ: C | | | |
| H6 | CHỜ: C | | | |

## Bảng số đo

Điều kiện đo phía DLL: commit `30172db092019864f8e7b337f049ed28b4126f67` (`git rev-parse HEAD` lúc 2026-10-08 16:09:18; đợt không commit); `dll_bench.exe` dựng bằng `l-b4-dll.py dich` (preset và cờ: CHỜ: Build & Test ghi từ `so-do/l-b4-dll-dich-lan3.txt`); CPU Intel(R) Core(TM) i5-14600KF; dòng đầu `l-b4-dll-tom-tat-lan1.tsv` (15:51:09) và `-lan2.tsv` (15:54:25): "không có bản dựng nào khác đang chạy (giữ NANG.lock)". Số lần cấp phát là cận dưới. Ghi đủ mọi lượt, kể cả lượt quá 1,5.

| đại lượng | lệnh | số lượt | trung vị | nhỏ nhất | lớn nhất | tệp log |
|---|---|---|---|---|---|---|
| DLL gốc, fenghuang, nạp p50 (µs/lần nạp), lan1, lớn/nhỏ 1.114 | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 45925 | 42561 | 47396.3 | `so-do/l-b4-dll-fenghuang-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, fenghuang, nạp p99 (µs/lần nạp), lan1, lớn/nhỏ 1.260 | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 49673.8 | 45194 | 56948 | `so-do/l-b4-dll-fenghuang-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, fenghuang, o2 p50 (µs/truy vấn), lan1, lớn/nhỏ 1.079 | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 0.267 | 0.254 | 0.274 | `so-do/l-b4-dll-fenghuang-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, fenghuang, o2 p99 (µs/truy vấn), lan1, lớn/nhỏ 1.329 | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 0.419 | 0.365 | 0.485 | `so-do/l-b4-dll-fenghuang-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, fenghuang, o3 p50 (µs/truy vấn), lan1, lớn/nhỏ 1.073 | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 0.843 | 0.819 | 0.879 | `so-do/l-b4-dll-fenghuang-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, fenghuang, o3 p99 (µs/truy vấn), lan1, lớn/nhỏ 1.214 | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 1.268 | 1.224 | 1.486 | `so-do/l-b4-dll-fenghuang-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, fenghuang, số lần cấp phát một lần nạp (cận dưới), lan1, lớn/nhỏ inf | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 0 | 0 | 0 | `so-do/l-b4-dll-fenghuang-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, bianjing, nạp p50 (µs/lần nạp), lan1, lớn/nhỏ 1.218 | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 190718 | 179697 | 218933 | `so-do/l-b4-dll-bianjing-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, bianjing, nạp p99 (µs/lần nạp), lan1, lớn/nhỏ 1.305 | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 206462 | 190892 | 249081 | `so-do/l-b4-dll-bianjing-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, bianjing, o2 p50 (µs/truy vấn), lan1, lớn/nhỏ 1.233 | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 0.678 | 0.619 | 0.763 | `so-do/l-b4-dll-bianjing-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, bianjing, o2 p99 (µs/truy vấn), lan1, lớn/nhỏ 1.389 | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 1.221 | 1.051 | 1.46 | `so-do/l-b4-dll-bianjing-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, bianjing, o3 p50 (µs/truy vấn), lan1, lớn/nhỏ 1.143 | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 3.592 | 3.407 | 3.894 | `so-do/l-b4-dll-bianjing-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, bianjing, o3 p99 (µs/truy vấn), lan1, lớn/nhỏ 1.311 | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 6.016 | 5.059 | 6.632 | `so-do/l-b4-dll-bianjing-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, bianjing, số lần cấp phát một lần nạp (cận dưới), lan1, lớn/nhỏ inf | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 0 | 0 | 0 | `so-do/l-b4-dll-bianjing-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, xihu_Valentine, nạp p50 (µs/lần nạp), lan1, lớn/nhỏ 1.131 | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 1409.9 | 1318.7 | 1491 | `so-do/l-b4-dll-xihu_Valentine-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, xihu_Valentine, nạp p99 (µs/lần nạp), lan1, lớn/nhỏ 1.475 | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 1879.3 | 1603.6 | 2366 | `so-do/l-b4-dll-xihu_Valentine-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, xihu_Valentine, o2 p50 (µs/truy vấn), lan1, lớn/nhỏ 1.141 | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 0.198 | 0.184 | 0.21 | `so-do/l-b4-dll-xihu_Valentine-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, xihu_Valentine, o2 p99 (µs/truy vấn), lan1, lớn/nhỏ 1.470 | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 0.341 | 0.285 | 0.419 | `so-do/l-b4-dll-xihu_Valentine-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, xihu_Valentine, o3 p50 (µs/truy vấn), lan1, lớn/nhỏ 1.331 | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 0.444 | 0.438 | 0.583 | `so-do/l-b4-dll-xihu_Valentine-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, xihu_Valentine, o3 p99 (µs/truy vấn), lan1, lớn/nhỏ 1.945, **QUÁ 1,5** | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 0.677 | 0.652 | 1.268 | `so-do/l-b4-dll-xihu_Valentine-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, xihu_Valentine, số lần cấp phát một lần nạp (cận dưới), lan1, lớn/nhỏ inf | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 0 | 0 | 0 | `so-do/l-b4-dll-xihu_Valentine-lan1.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, xihu_Valentine, nạp p50 (µs/lần nạp), lan2, lớn/nhỏ 1.380 | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 1593.4 | 1447 | 1997.5 | `so-do/l-b4-dll-xihu_Valentine-lan2.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
| DLL gốc, xihu_Valentine, nạp p99 (µs/lần nạp), lan2, lớn/nhỏ 1.628, **QUÁ 1,5** | `dll_bench.exe` (d9e54f2b…) qua `so-do/l-b4-dll.py` | 5 | 2632.3 | 1969.9 | 3207.5 | `so-do/l-b4-dll-xihu_Valentine-lan2.txt`, `so-do/l-b4-dll-tom-tat-lan1.tsv` |
