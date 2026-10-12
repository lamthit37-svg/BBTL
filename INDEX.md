# Chỉ mục quy tắc C++23

Sinh tự động bởi `tools/verify.py --index` từ tiêu đề trong refs/. Không sửa tay.
Cấp: N = Nền tảng, C = Nâng cao, T = Thần thoại. Đọc đúng một quy tắc:
`Read(~/.claude/cpp23/refs/<tệp>, offset = Dòng, limit = Dài)` (đường dẫn tuyệt đối);
một dải liền A..B: offset = Dòng(A), limit = Dòng(B) + Dài(B) − Dòng(A). Tìm mã:
`grep '^[|] MMO-06 ' INDEX.md`, lọc một tệp: `grep '^[|] DT-' INDEX.md` (`[|]` đúng cả
với grep -E và ripgrep). "Kiểm nhanh" của mỗi tệp ghi ở dòng tiêu đề của tệp đó.
Tổng: 356 quy tắc.

## Mục không phải quy tắc

| Tệp | Mục | Dòng | Dài |
|---|---|---|---|
| `refs/00-hien-phap.md` | 0. Cách đọc bộ quy cách | 11 | 54 |
| `refs/00-hien-phap.md` | Thuật ngữ | 616 | 28 |
| `refs/08-thu-vien-chuan-cpp23.md` | 0. Bảng hỗ trợ (đo trên máy kiểm, `-std=c++23`) | 15 | 38 |
| `refs/10-bo-nho-cache-dod.md` | Bảng tra bậc độ lớn (x86-64 hiện đại, tuỳ đời CPU — chỉ để ước lượng) | 13 | 11 |
| `refs/13-ub-on-dinh.md` | 0. Danh mục UB thường gặp | 15 | 23 |
| `refs/14-build-toolchain.md` | 0. Bố cục tệp build của dự án | 22 | 17 |
| `refs/19-review-checklist.md` | 4. Checklist | 96 | 39 |
| `refs/19-review-checklist.md` | 5. Lệnh kiểm một thay đổi | 136 | 22 |

## HP · Hiến pháp: phương châm, ưu tiên, quy trình — `refs/00-hien-phap.md` (33 KB) · Kiểm nhanh: Dòng 604, Dài 11

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| HP-01 | N | PHẢI | Ưu tiên theo thứ tự: Đúng > An toàn, ổn định > Rõ ràng > Hiệu năng > Ngắn gọn | 68 | 26 |
| HP-02 | N | CẤM | Undefined behavior dưới mọi hình thức; không có "UB vô hại" | 95 | 37 |
| HP-03 | N | PHẢI | Trạng thái sai không biểu diễn được bằng kiểu | 133 | 28 |
| HP-04 | N | PHẢI | Giá trị trước tham chiếu; mỗi tài nguyên có đúng một chủ tường minh | 162 | 28 |
| HP-05 | N | PHẢI | Lỗi lập trình dừng sớm; lỗi dự kiến trả `std::expected`; không nuốt lỗi | 191 | 43 |
| HP-07 | N | PHẢI | Comment nói hợp đồng và lý do; code port ghi "Khác gốc" và sửa UB của gốc | 235 | 23 |
| HP-08 | N | CẤM | Code chết, code bị comment hoá, `#if 0`, TODO không chủ | 259 | 28 |
| HP-09 | N | CẤM | Đoán API, cờ trình dịch, tên check, số liệu | 288 | 19 |
| HP-10 | N | PHẢI | Quy trình mỗi việc C++: phân cấp, mở refs, viết, tự kiểm, biên dịch, báo cáo | 308 | 27 |
| HP-11 | N | CẤM | Tuyên bố "đã biên dịch", "đã test", "nhanh hơn" khi chưa chạy thật | 336 | 18 |
| HP-12 | N | PHẢI | Phân xử mâu thuẫn theo thứ tự cố định và ghi lý do tại chỗ lệch | 355 | 16 |
| HP-13 | C | PHẢI | Không tốn phí cho thứ không dùng | 374 | 31 |
| HP-14 | C | PHẢI | Đo trước khi tối ưu; ghi số đo kèm điều kiện tái lập | 406 | 15 |
| HP-15 | C | PHẢI | Tất định mặc định: cùng đầu vào cho cùng kết quả trên mọi máy và trình dịch | 422 | 32 |
| HP-16 | C | CẤM | Dừng máy chủ vì dữ liệu client: kiểm mọi trường, trả lỗi, máy chủ chạy tiếp | 455 | 37 |
| HP-17 | T | PHẢI | Kỹ thuật [T] chỉ dùng khi đủ bốn điều kiện: số đo, test bảo vệ, comment bất biến, bản tham chiếu | 495 | 52 |
| HP-18 | T | PHẢI | Mã [T] kèm lập luận đúng theo chuẩn hoặc tài liệu phần cứng, không chỉ theo thử nghiệm | 548 | 55 |

## DD · Định danh, include, namespace, macro — `refs/01-dinh-dang-dat-ten.md` (18 KB) · Kiểm nhanh: Dòng 371, Dài 10

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| DD-02 | N | CẤM | Định danh dành riêng (`_Hoa`, `__`, `_` đầu tên ở phạm vi toàn cục) và khai báo thêm vào `namespace std` | 12 | 8 |
| DD-05 | N | PHẢI | Include đủ thứ mình dùng, không dựa vào include bắc cầu; header tự đủ | 21 | 35 |
| DD-06 | N | PHẢI | Namespace `game::<module>` theo bảng tầng, `detail` cho nội bộ; CẤM `using namespace` và namespace ẩn danh trong header | 57 | 38 |
| DD-08 | N | PHẢI | NOLINT nêu tên check, lý do và mã quy tắc; vùng dùng NOLINTBEGIN/NOLINTEND | 96 | 28 |
| DD-09 | N | PHẢI | Định danh ASCII; nguồn UTF-8 không BOM, dạng NFC; không ký tự điều khiển hai chiều | 125 | 24 |
| DD-10 | N | CẤM | Macro cho hằng hoặc hàm; macro cấu hình được đọc đúng một chỗ thành `constexpr bool` | 150 | 38 |
| DD-12 | C | PHẢI | Hàm tự do đặt tên theo phép toán, nạp chồng theo kiểu; bản vô hướng gọi đủ `std::` | 191 | 53 |
| DD-14 | T | PHẢI | Cách ly header nền tảng định nghĩa macro trùng tên thường | 247 | 54 |
| DD-15 | T | CẤM | Hai định nghĩa khác nhau cho cùng một tên ở hai TU: helper chép sang header khác, bố cục kiểu theo macro | 302 | 31 |
| DD-16 | T | CẤM | Dùng tên định danh làm dữ liệu bền: `typeid().name()`, `source_location::function_name()`, `#x` | 334 | 36 |

## PH · Bảng tra, switch, bất đồng bộ, máy trạng thái — `refs/02-code-phang.md` (15 KB) · Kiểm nhanh: Dòng 341, Dài 6

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| PH-06 | N | NÊN | Ánh xạ giá trị và khác biệt giữa các loại là bảng `constexpr`, không phải chuỗi if/switch hay tầng kế thừa | 12 | 47 |
| PH-07 | N | PHẢI | `switch` trên enum không `default`; sau switch là `core::fail`; byte từ mạng kiểm miền trước khi ép kiểu | 60 | 66 |
| PH-08 | N | CẤM | `goto`, đệ quy | 127 | 8 |
| PH-09 | C | PHẢI | Lưới 2D là một mảng liền; láng giềng là bảng offset trên lưới có viền rỗng | 138 | 48 |
| PH-10 | C | PHẢI | Chuỗi bất đồng bộ: mỗi bước một hàm có tên, callback chỉ chuyển tiếp | 187 | 49 |
| PH-11 | T | CÓ THỂ | Bỏ nhánh phụ thuộc dữ liệu (cộng bool, mặt nạ, min/max) khi profiler cho thấy đoán sai nhánh | 239 | 47 |
| PH-12 | T | NÊN | Máy trạng thái phiên là bảng chuyển `constexpr` + hàm `step` tra bảng; bất biến kiểm bằng `static_assert` | 287 | 53 |

## KG · Kiểu và giá trị — `refs/03-kieu-gia-tri.md` (34 KB) · Kiểm nhanh: Dòng 760, Dài 13

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| KG-01 | N | PHẢI | Biến không gán lại là `const`, hằng là `constexpr`, `auto` chỉ khi kiểu đã hiện | 14 | 39 |
| KG-02 | N | PHẢI | Mọi biến, mọi thành viên khởi tạo tại chỗ; dữ liệu thuần là aggregate tạo bằng designated initializer | 54 | 40 |
| KG-03 | N | PHẢI | Chọn kiểu số nguyên theo vai trò của giá trị | 95 | 45 |
| KG-04 | N | PHẢI | Chuyển đổi thu hẹp có kiểm: `core::narrow<T>` khi giá trị có thể ngoài miền | 141 | 43 |
| KG-05 | N | CẤM | Ép kiểu cú pháp C, ép kiểu hàm `T(x)`, union punning; dùng ép kiểu có tên | 185 | 41 |
| KG-06 | N | PHẢI | Enum là `enum class` có kiểu nền tường minh; lấy số bằng `std::to_underlying` | 227 | 32 |
| KG-07 | N | CẤM | Tham số `bool` làm cờ hành vi; mỗi cờ là một `enum class` | 260 | 28 |
| KG-08 | N | PHẢI | Mỗi loại ID là một kiểu riêng (`StrongId<Tag>`), không phải số nguyên trần | 289 | 56 |
| KG-09 | N | PHẢI | Đại lượng có đơn vị mang đơn vị trong kiểu; thời gian là `std::chrono::duration` | 346 | 40 |
| KG-10 | N | PHẢI | So sánh dùng `= default` cho `==`/`<=>`; khoá sắp xếp phải có thứ tự toàn phần | 387 | 27 |
| KG-11 | C | PHẢI | "Có thể không có" là `std::optional<T>`; giá trị canh chỉ trong định dạng lưu | 417 | 31 |
| KG-12 | C | NÊN | Tập kiểu đóng là `std::variant` + `std::visit`; hàm từng kiểu mang tên khác hàm tổng | 449 | 42 |
| KG-13 | C | NÊN | Kiểu mà bỏ qua là sai thì gắn `[[nodiscard("lý do")]]` ở mức kiểu | 492 | 27 |
| KG-14 | T | NÊN | Kiểu có miền: constructor `consteval` cho hằng, factory kiểm cho giá trị chạy | 522 | 64 |
| KG-15 | T | CÓ THỂ | Type-state: trạng thái nằm trong kiểu, chuyển trạng thái tiêu thụ đối tượng cũ | 587 | 50 |
| KG-16 | T | CÓ THỂ | Số nguyên mạnh không bất biến là `enum class Id : std::uint32_t {}` | 638 | 44 |
| KG-17 | T | PHẢI | Struct lưu/mạng chốt bố cục bằng `static_assert`; không bit-field, không đệm ngầm | 683 | 41 |
| KG-18 | T | CÓ THỂ | `std::float16_t` chỉ để LƯU, sau guard `__STDCPP_FLOAT16_T__`; tính ở `float` | 725 | 34 |

## SH · Sở hữu và vòng đời — `refs/04-so-huu-vong-doi.md` (33 KB) · Kiểm nhanh: Dòng 777, Dài 14

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| SH-01 | N | PHẢI | Mọi tài nguyên do một đối tượng RAII sở hữu; giải phóng nằm trong destructor | 16 | 36 |
| SH-02 | N | PHẢI | Rule of zero: lớp có thành viên RAII không khai báo hàm đặc biệt nào | 53 | 34 |
| SH-03 | N | PHẢI | Sở hữu heap độc quyền là `std::unique_ptr` qua `std::make_unique`; CẤM `new`/`delete` trần | 88 | 40 |
| SH-04 | N | PHẢI | Con trỏ và tham chiếu trần không bao giờ sở hữu; không giữ chúng qua tick | 129 | 35 |
| SH-05 | N | PHẢI | `std::shared_ptr` chỉ khi sở hữu chung thật; hàm dùng nhận `const T&`; cache giữ `weak_ptr` | 165 | 47 |
| SH-06 | N | CẤM | View (`std::string_view`, `std::span`) sống lâu hơn dữ liệu nó trỏ tới | 213 | 32 |
| SH-07 | N | CẤM | Giữ tham chiếu, con trỏ, iterator vào container qua thao tác có thể vô hiệu hoá chúng | 246 | 34 |
| SH-08 | N | PHẢI | Trả theo giá trị, không `return std::move(local)`; moved-from chỉ huỷ hoặc gán lại | 281 | 34 |
| SH-09 | C | PHẢI | Lớp bọc tài nguyên viết đủ năm hàm đặc biệt; move `noexcept` để lại trạng thái rỗng | 318 | 53 |
| SH-10 | C | PHẢI | Con trỏ của API C: `unique_ptr` + deleter struct rỗng; con trỏ ra nhận bằng `std::out_ptr` | 372 | 37 |
| SH-11 | C | CẤM | Callback bất đồng bộ bắt `this`, tham chiếu hay con trỏ tới đối tượng có thể chết trước nó | 410 | 47 |
| SH-12 | C | CẤM | Gắn tham chiếu/view vào kết quả hàm gọi trên tạm thời; range-for trên thành viên của tạm thời | 458 | 40 |
| SH-13 | T | NÊN | Bộ nhớ thô: `std::construct_at`/`std::destroy_at`; con trỏ tính lại từ byte qua `std::launder` | 501 | 59 |
| SH-14 | T | PHẢI | Đối tượng từ bộ đệm byte: `std::memcpy` vào đối tượng cục bộ; CẤM `reinterpret_cast` con trỏ bộ đệm | 561 | 46 |
| SH-15 | T | NÊN | Biết chi phí thật của `shared_ptr`: một hay hai khối, ai giữ khối nào, khi nào nguyên tử | 608 | 43 |
| SH-16 | T | CÓ THỂ | Dữ liệu nháp của một tick sống trong arena; mọi con trỏ vào đó chết cuối tick | 652 | 39 |
| SH-17 | T | NÊN | Hàm trả tham chiếu/view vào đối số gắn `GAME_LIFETIMEBOUND`; biết công cụ nào bắt gì | 692 | 44 |
| SH-18 | T | PHẢI | Dữ liệu tĩnh khởi tạo lúc biên dịch (`constexpr`/`constinit`); không đối tượng tĩnh có destructor | 737 | 39 |

## LH · Lỗi và hợp đồng — `refs/05-loi-hop-dong.md` (43 KB) · Kiểm nhanh: Dòng 859, Dài 14

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| LH-01 | N | PHẢI | Xếp mỗi lỗi vào đúng một trong ba loại rồi mới chọn cơ chế xử lý | 14 | 39 |
| LH-02 | N | PHẢI | Kiểm hợp đồng bằng `core/check.hpp`; CẤM `assert` và macro kiểm tự chế | 54 | 94 |
| LH-03 | N | CẤM | Để dữ liệu client làm dừng máy chủ: lỗi đầu vào là giá trị trả về, có đếm, xử lý theo phiên | 149 | 40 |
| LH-04 | N | PHẢI | Mã lỗi là `enum class [[nodiscard]]` kiểu nền `std::uint8_t`, kèm `to_string` trả tên ASCII cố định | 190 | 34 |
| LH-05 | N | CẤM | Bỏ qua giá trị có thể mang lỗi; mọi hàm trả `std::expected` là `[[nodiscard]]` | 225 | 36 |
| LH-06 | N | PHẢI | Destructor, move và `swap` là `noexcept`; chốt bằng `static_assert` cạnh kiểu | 262 | 41 |
| LH-07 | N | CẤM | `throw` trong code game và mạng; ngoại lệ thư viện chỉ có một đích: dừng tiến trình | 304 | 47 |
| LH-08 | N | PHẢI | Hàm vào luồng và callback trao cho thư viện C là `noexcept`; lỗi qua ranh giới đi dưới dạng giá trị | 352 | 37 |
| LH-09 | C | NÊN | Chuỗi bước có thể lỗi viết bằng `and_then`/`transform`/`transform_error` khi mỗi bước là hàm có tên | 392 | 36 |
| LH-10 | C | PHẢI | Lỗi có hai mặt: ngữ cảnh có cấu trúc cho log máy chủ, mã công khai thô cho client | 429 | 44 |
| LH-11 | C | PHẢI | Lỗi hệ điều hành giữ dạng `std::error_code` tới nơi quyết định; so sánh với `std::errc`, không với số errno | 474 | 35 |
| LH-12 | C | PHẢI | Thao tác nhiều bước có đảm bảo mạnh: làm hết mọi việc có thể lỗi trước, rồi sửa trạng thái bằng các bước không thể lỗi | 510 | 61 |
| LH-13 | C | PHẢI | Cài terminate handler in stacktrace rồi `std::abort()`; bật core dump | 572 | 39 |
| LH-14 | T | NÊN | Dựng lỗi trong hàm lạnh riêng `[[gnu::cold]] [[gnu::noinline]]` khi đường lỗi làm phình hàm nóng | 614 | 44 |
| LH-15 | T | NÊN | `std::expected` trên đường nóng ≤ 16 byte, copy/move constructor và destructor tầm thường, để trả qua thanh ghi | 659 | 38 |
| LH-16 | T | PHẢI | Bảng dữ liệu dựng lúc biên dịch kiểm bất biến bằng `core::check`: vi phạm thành lỗi biên dịch | 698 | 64 |
| LH-17 | T | NÊN | Viết kiểm hợp đồng để chuyển sang contracts C++26 (P2900) được máy móc | 763 | 32 |
| LH-18 | T | KHÔNG NÊN | Dùng ngoại lệ ở nơi tần suất lỗi do bên ngoài quyết định; biết mô hình chi phí | 796 | 34 |
| LH-19 | T | NÊN | Tiến trình zone theo kiểu crash-only: dừng bất kỳ lúc nào không mất dữ liệu đã xác nhận; giám sát tự khởi động lại | 831 | 27 |

## API · Hàm, lớp và thiết kế API — `refs/06-ham-lop-api.md` (34 KB) · Kiểm nhanh: Dòng 805, Dài 13

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| API-01 | N | PHẢI | Truyền tham số theo bảng; không đoán | 15 | 56 |
| API-02 | N | CẤM | Tham số ra; trả struct có tên, `std::optional` hoặc `std::expected` | 72 | 34 |
| API-03 | N | PHẢI | Không hai tham số cùng kiểu dễ đổi chỗ liền nhau; nhóm tham số luôn đi cùng nhau gom thành struct | 107 | 37 |
| API-04 | N | PHẢI | Constructor một đối số và toán tử chuyển đổi là `explicit` | 145 | 31 |
| API-05 | N | PHẢI | Chữ ký nói hợp đồng: hàm chỉ đọc là `const` (đọc đồng thời an toàn), hàm trả giá trị là `[[nodiscard]]`, hàm không ném là `noexcept` | 177 | 45 |
| API-06 | N | NÊN | Hàm không cần truy cập private là hàm tự do cùng namespace | 223 | 29 |
| API-07 | N | PHẢI | Nạp chồng chỉ khi cùng ngữ nghĩa, không trộn `bool`/con trỏ/số với kiểu lớp; tham số mặc định chỉ ở cuối, CẤM trên hàm ảo | 253 | 32 |
| API-08 | C | PHẢI | Constructor lập bất biến; tạo có thể thất bại thì factory `static` trả `std::expected` | 288 | 50 |
| API-09 | C | PHẢI | Toán tử là hidden friend, chỉ khi nghĩa hiển nhiên và đúng quy ước; phép so trả mặt nạ là hàm có tên | 339 | 43 |
| API-10 | C | NÊN | `= delete` và ràng buộc chặn nạp chồng nguy hiểm: view trên rvalue, chuyển đổi mất mát | 383 | 47 |
| API-11 | C | PHẢI | Lớp đa hình: destructor public virtual (hoặc protected không virtual), `override`/`final`, chặn copy | 431 | 37 |
| API-12 | C | CÓ THỂ | Pimpl cho lớp công khai có phụ thuộc nặng hoặc cần giữ ABI | 469 | 57 |
| API-13 | T | NÊN | Mixin dùng deducing this thay CRTP; getter cho mọi loại tham chiếu theo GN-15 | 529 | 49 |
| API-14 | T | CÓ THỂ | `static operator()` cho đối tượng hàm không trạng thái; `operator[]` nhiều chiều cho lưới | 579 | 45 |
| API-15 | T | NÊN | Điểm tuỳ biến là đối tượng hàm (CPO/niebloid), không phải hàm tự do cộng `using std::swap` | 625 | 56 |
| API-16 | T | PHẢI | Ranh giới ABI (plugin, SDK) là C ABI có `struct_size` và phiên bản; không lộ kiểu thư viện chuẩn | 682 | 45 |
| API-17 | T | CÓ THỂ | Thành viên rỗng (policy, clock, deleter) dùng `[[no_unique_address]]` qua macro | 728 | 44 |
| API-18 | T | NÊN | Tiến hoá API không phá nơi gọi: trường mới có mặc định, `[[deprecated]]` một vòng trước khi xoá | 773 | 31 |

## GN · Generic và tính toán lúc biên dịch — `refs/07-generic-compile-time.md` (40 KB) · Kiểm nhanh: Dòng 940, Dài 14

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| GN-01 | N | PHẢI | Mọi tham số kiểu của template bị ràng buộc bằng concept; CẤM `enable_if`/SFINAE mới | 17 | 35 |
| GN-02 | N | PHẢI | Rẽ nhánh theo kiểu là một chuỗi `if constexpr` kết thúc bằng `static_assert(false, "…")` | 53 | 46 |
| GN-03 | N | CẤM | Chuyên biệt hoá tường minh hàm template; tuỳ biến theo kiểu bằng nạp chồng | 100 | 37 |
| GN-04 | N | PHẢI | Giá trị chỉ được phép tính lúc biên dịch dùng `consteval`; hàm dùng ở cả hai thời điểm là `constexpr` | 138 | 34 |
| GN-05 | N | PHẢI | Mỗi hàm `constexpr` được đánh giá hằng ít nhất một lần trong build: `static_assert` cạnh định nghĩa hoặc trong test | 173 | 40 |
| GN-06 | N | PHẢI | Forwarding reference (`T&&`, `auto&&` suy diễn) chỉ để chuyển tiếp: mỗi tham số `std::forward` đúng một lần | 214 | 50 |
| GN-07 | N | PHẢI | Tham số callable gọi ngay là template ràng buộc (`std::invocable`, `std::predicate`), không `std::function` | 265 | 32 |
| GN-08 | C | PHẢI | Concept mô tả một vai trò có ngữ nghĩa, không một phép toán đơn lẻ | 300 | 44 |
| GN-09 | C | PHẢI | Concept hẹp viết qua concept rộng để subsumption chọn nạp chồng; không ghép trait rời | 345 | 59 |
| GN-10 | C | NÊN | Chỉ dựa vào CTAD khi kiểu suy ra hiển nhiên; container dựng từ dãy ghi rõ kiểu | 405 | 43 |
| GN-11 | C | PHẢI | Mở pack bằng fold expression hoặc `std::index_sequence`; không đệ quy template theo pack | 449 | 39 |
| GN-12 | C | NÊN | Bảng tra sinh lúc biên dịch bằng hàm `constexpr` trả `std::array`, có `static_assert` điểm mẫu | 489 | 52 |
| GN-13 | C | PHẢI | Tham số phụ (dung sai, bước, hệ số) là `std::type_identity_t<T>` để T chỉ suy từ tham số chính | 542 | 27 |
| GN-14 | C | NÊN | Tên và khoá cố định là NTTP kiểu lớp (`FixedString`); kiểm trùng id lúc biên dịch | 570 | 60 |
| GN-15 | C | NÊN | Deducing this thay các bản const/không const/rvalue của cùng hàm thành viên; không `this auto self` | 631 | 44 |
| GN-16 | T | PHẢI | Đo thời gian biên dịch trước khi thêm tầng generic; template nặng dùng ở nhiều TU thì `extern template` cho thành viên định nghĩa NGOÀI lớp | 678 | 47 |
| GN-17 | T | PHẢI | Template số học được `static_assert` tại ca biên với MỌI kiểu trong concept: đánh giá hằng là máy dò UB | 726 | 55 |
| GN-18 | T | PHẢI | Tính toán trên kiểu bằng giá trị (mảng constexpr + thuật toán), không đệ quy N mức; pack indexing là C++26 | 782 | 37 |
| GN-19 | T | PHẢI | Giữ ODR cho template và hàm inline: macro cấu hình đồng nhất trên mọi TU, không thực thể liên kết nội bộ trong header | 820 | 58 |
| GN-20 | T | PHẢI | `if consteval` khi bản lúc biên dịch và bản lúc chạy khác nhau; hai nhánh cho cùng kết quả từng bit và cả hai được test | 879 | 60 |

## STD · Thư viện chuẩn và tính năng C++23 — `refs/08-thu-vien-chuan-cpp23.md` (43 KB) · Kiểm nhanh: Dòng 875, Dài 14

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| STD-01 | N | PHẢI | Container mặc định là `std::vector`; container khác chọn theo bảng và ghi lý do | 56 | 53 |
| STD-02 | N | PHẢI | Tham số chuỗi chỉ đọc là `std::string_view`; giữ lại thì `std::string`; dùng `contains`/`starts_with`/`ends_with` | 110 | 34 |
| STD-03 | N | NÊN | Thuật toán chuẩn (`std::ranges::…`, `std::erase_if`) thay vòng lặp tay khi có thuật toán đúng tên | 145 | 39 |
| STD-04 | N | PHẢI | Định dạng bằng `std::format`/`std::print`; đường nóng dùng `std::format_to` vào buffer tái dùng; CẤM `printf` và `iostream` trong code mới | 185 | 34 |
| STD-05 | N | PHẢI | Đo khoảng thời gian và hạn chờ bằng `std::chrono::steady_clock`; `system_clock` chỉ cho mốc lịch; CẤM `high_resolution_clock` | 220 | 32 |
| STD-06 | N | PHẢI | Đọc/ghi số dạng văn bản bằng `<charconv>`; kiểm `ec` VÀ đã tiêu thụ hết chuỗi; CẤM `atoi`/`stoi`/`strtol`/`sscanf`/`stringstream` trên dữ liệu ngoài | 253 | 30 |
| STD-07 | N | PHẢI | Thao tác bit bằng `<bit>` trên kiểu không dấu; đổi thứ tự byte bằng `std::byteswap` + `std::endian` | 284 | 36 |
| STD-08 | N | PHẢI | Dãy liền kề làm tham số là `std::span<const T>`/`std::span<T>`; bộ đệm thô là `std::span<const std::byte>` | 321 | 28 |
| STD-09 | N | CẤM | `.value()` của `optional`/`expected` trên đường game và mạng; truy cập bằng `*`/`->` sau câu bảo vệ, `value_or`, hoặc monadic | 350 | 38 |
| STD-10 | C | NÊN | Pipeline views + `std::ranges::to` thay vòng lặp gom; chỉ dùng view có ở cả hai thư viện, hoặc gắn thẻ | 391 | 36 |
| STD-11 | C | PHẢI | Gộp bằng `std::ranges::fold_left`, không `std::accumulate`; CẤM `std::reduce` khi cần tất định số thực | 428 | 23 |
| STD-12 | C | NÊN | Ghi thẳng vào `std::string` bằng `resize_and_overwrite`, giữ đúng hợp đồng của `op` | 452 | 42 |
| STD-13 | C | PHẢI | Tiện ích chỉ libstdc++ có (bảng §0) đi kèm đường lui hoặc thẻ; `std::stacktrace` cần `-lstdc++exp` | 495 | 29 |
| STD-14 | C | CẤM | Dùng phân phối của `<random>` (và `std::shuffle`, `std::sample`) khi kết quả phải giống nhau giữa nền tảng | 525 | 35 |
| STD-15 | C | CẤM | Dựa vào thứ tự duyệt `unordered_*` hay giá trị `std::hash` cho dữ liệu lưu, gửi mạng, băm trạng thái hoặc logic tất định | 561 | 32 |
| STD-16 | T | PHẢI | Chọn theo feature-test macro trong `<version>` + đường lui; biết các chỗ macro VẮNG mà tính năng CÓ | 596 | 43 |
| STD-17 | T | NÊN | Map khoá chuỗi tra bằng `string_view` không cấp phát: hash trong suốt + `std::equal_to<>` | 640 | 41 |
| STD-18 | T | NÊN | Kiểu game in được bằng `std::formatter` tự viết: kế thừa formatter của kiểu nền, `format` là template theo context và `const` | 682 | 51 |
| STD-19 | T | CẤM | Sửa phần tử qua `views::filter` làm vị từ thành sai; trả view tham chiếu dữ liệu cục bộ; duyệt lại view lười sau khi nguồn đổi | 734 | 50 |
| STD-20 | T | PHẢI | Callback LƯU LẠI dùng `std::move_only_function` khi có, `std::function` khi không; biết bộ đệm trong; `function_ref` là C++26 | 785 | 35 |
| STD-21 | T | CẤM | `std::regex` trên đường nóng và trên mọi đầu vào từ client | 821 | 34 |
| STD-22 | T | KHÔNG NÊN | `import std;` trong code production C++23 lúc này; giữ `#include`, theo dõi thực trạng | 856 | 18 |

## HN · Hiệu năng: đo, thuật toán, cấp phát, cờ biên dịch — `refs/09-hieu-nang.md` (35 KB) · Kiểm nhanh: Dòng 676, Dài 12

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| HN-01 | N | PHẢI | Đo trước khi tối ưu; mọi thay đổi vì hiệu năng kèm số đo trước và sau | 16 | 18 |
| HN-02 | N | PHẢI | Chọn thuật toán và cấu trúc dữ liệu theo độ phức tạp trước mọi vi tối ưu | 35 | 26 |
| HN-03 | N | CẤM | Cấp phát heap mỗi tick hoặc mỗi gói tin trên đường nóng | 62 | 36 |
| HN-04 | N | CẤM | Sao chép ngầm đối tượng sở hữu heap hoặc `std::shared_ptr` trên đường nóng | 99 | 39 |
| HN-05 | N | KHÔNG NÊN | Gọi gián tiếp (`virtual`, `std::function`) cho từng phần tử trên đường nóng | 139 | 44 |
| HN-06 | N | PHẢI | Log kiểm mức trước khi định dạng; nơi gọi không tự dựng chuỗi; cấm `std::endl` | 184 | 46 |
| HN-07 | C | PHẢI | Benchmark theo phương pháp: dữ liệu thật, khởi động, nhiều mẫu, trung vị + p99 | 233 | 18 |
| HN-08 | C | PHẢI | Ngân sách tick chia cho từng pha, đo mỗi tick, theo dõi p99 và số lần vượt | 252 | 46 |
| HN-09 | C | KHÔNG NÊN | Tra cứu bằng chuỗi trên đường nóng; đổi chuỗi → chỉ số một lần lúc nạp | 299 | 44 |
| HN-10 | C | NÊN | Chép giá trị bất biến vòng lặp ra biến `const` cục bộ khi trình dịch không chứng minh được nó bất biến | 344 | 58 |
| HN-11 | C | PHẢI | Hiểu đúng `inline`: quy tắc ODR, không phải lệnh nội tuyến | 403 | 25 |
| HN-12 | C | PHẢI | Cờ hiệu năng bản phát hành theo bảng; cờ ngoài bảng chỉ khi có số đo | 429 | 33 |
| HN-13 | T | CÓ THỂ | `[[likely]]`/`[[unlikely]]` và `[[gnu::cold/noinline/hot/flatten/always_inline]]` khi số đo chỉ ra vấn đề bố cục hoặc nội tuyến cụ thể | 465 | 43 |
| HN-14 | T | CÓ THỂ | `[[gnu::target_clones]]` cho hàm lá nóng tự vector hoá khi binary chạy trên nhiều đời CPU | 509 | 31 |
| HN-15 | T | PHẢI | Khẳng định về codegen và vi kiến trúc dựa trên asm và bộ đếm phần cứng, không suy đoán | 541 | 24 |
| HN-16 | T | NÊN | Giảm sức mạnh phép tính: số chia hằng hoặc luỹ thừa 2 không dấu; số chia lúc chạy thì tính trước | 566 | 46 |
| HN-17 | T | CÓ THỂ | PGO rồi BOLT cho binary máy chủ, huấn luyện bằng replay tải thật | 613 | 26 |
| HN-18 | T | PHẢI | Đuôi p99.9 của tick: đưa page fault và cấp phát lớn ra khỏi vòng tick | 640 | 35 |

## BN · Bộ nhớ, cache và thiết kế hướng dữ liệu — `refs/10-bo-nho-cache-dod.md` (30 KB) · Kiểm nhanh: Dòng 694, Dài 11

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| BN-01 | N | PHẢI | Dữ liệu duyệt mỗi tick nằm trong mảng giá trị liền và đặc; xoá bằng chép phần tử cuối vào chỗ trống | 27 | 40 |
| BN-02 | N | PHẢI | Sắp thành viên theo căn lề giảm dần và khoá cỡ bằng `static_assert` cho struct nóng, struct mạng, struct lưu | 68 | 48 |
| BN-03 | N | CẤM | `std::vector<bool>` trên đường nóng, khi cần tham chiếu hay `span`, hoặc khi nhiều luồng ghi | 117 | 27 |
| BN-04 | N | PHẢI | Lưới 2D là một mảng phẳng hàng-trước; duyệt từng hàng như một đoạn liền | 145 | 35 |
| BN-05 | N | PHẢI | Liên kết giữa dữ liệu nóng bằng chỉ số 32 bit, không bằng con trỏ 64 bit | 181 | 27 |
| BN-06 | C | NÊN | Chọn AoS, SoA hay AoSoA theo mẫu truy cập của hệ thống nóng nhất | 211 | 42 |
| BN-07 | C | PHẢI | Tách trường nóng (đọc mỗi tick) khỏi trường lạnh thành hai mảng song song cùng chỉ số | 254 | 33 |
| BN-08 | C | PHẢI | Căn lề bằng `alignas` trên kiểu với hằng dự án `kCacheLine = 64`; không dùng `std::hardware_destructive_interference_size` trong header hay struct thuộc ABI | 288 | 36 |
| BN-09 | C | NÊN | Dữ liệu tạm sống trong một tick dùng arena `std::pmr::monotonic_buffer_resource`, reset cuối tick | 325 | 39 |
| BN-10 | C | NÊN | Pool cỡ cố định với danh sách tự do nhúng trong slot, liên kết bằng chỉ số | 365 | 53 |
| BN-11 | C | NÊN | Tập nhỏ có trần đã biết dùng sức chứa cố định trong đối tượng, không heap | 419 | 53 |
| BN-12 | T | CÓ THỂ | Prefetch mềm cho truy cập gián tiếp theo danh sách chỉ số, khoảng cách chọn bằng đo | 475 | 40 |
| BN-13 | T | CÓ THỂ | Trang lớn (THP qua `madvise`) cho vùng nhớ lớn, nóng, truy cập ngẫu nhiên | 516 | 37 |
| BN-14 | T | PHẢI | Máy chủ nhiều socket: luồng zone ghim vào một node NUMA và tự dựng, tự chạm dữ liệu của zone | 554 | 32 |
| BN-15 | T | NÊN | Vòng lặp nhiều dữ liệu, ít phép tính là bound băng thông: giảm byte mỗi thực thể trước khi tối ưu phép tính | 587 | 34 |
| BN-16 | T | CÓ THỂ | Thứ tự Morton (Z-order) cho ô lưới khi truy vấn vùng lân cận chiếm ưu thế | 622 | 35 |
| BN-17 | T | CÓ THỂ | `__restrict` (không chuẩn) cho hàm lá nóng có hợp đồng "không chồng lấn" đã kiểm | 658 | 35 |

## SV · SIMD, vi kiến trúc và số thực — `refs/11-simd-vi-kien-truc.md` (38 KB) · Kiểm nhanh: Dòng 735, Dài 12

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| SV-01 | N | PHẢI | Vòng lặp nóng viết ở dạng vector hoá được: dữ liệu liền, số lần lặp đếm được, không gọi hàm mờ, không thoát sớm theo dữ liệu, không alias mơ hồ | 16 | 41 |
| SV-02 | N | PHẢI | Vòng lặp nóng có báo cáo vector hoá của cả GCC và Clang trong review | 58 | 15 |
| SV-03 | N | PHẢI | So sánh số thực bằng dung sai hợp với độ lớn; `==` chỉ cho giá trị được gán chính xác | 74 | 30 |
| SV-04 | N | PHẢI | Số thực từ client hay từ dữ liệu ngoài được kiểm hữu hạn và trong miền trước khi vào mô phỏng; chuyển sang số nguyên chỉ sau khi kẹp | 105 | 45 |
| SV-05 | N | PHẢI | `float` cho dữ liệu mô phỏng khối lớn, hằng có hậu tố `F`; `double` hoặc toạ độ cục bộ khi độ lớn vượt độ chính xác cần | 151 | 29 |
| SV-06 | N | CẤM | `-ffast-math`, `-Ofast` hay `-ffinite-math-only` ở cấp dự án hoặc TU có kiểm NaN | 181 | 19 |
| SV-07 | C | PHẢI | Intrinsic chỉ nằm trong tầng SIMD (math/simd.hpp, math/vector*.hpp); kiểu bọc mới theo đúng phong cách vector.hpp/vector_int.hpp | 203 | 53 |
| SV-08 | C | PHẢI | Rẽ nhánh theo làn bằng mặt nạ toàn bit và chọn (and/andnot/or hoặc blend); hỏi "có làn nào" bằng `movemask` | 257 | 31 |
| SV-09 | C | PHẢI | Nạp/lưu kiểu lưu trữ và buffer bằng `loadu`/`storeu`; không ép con trỏ thành `__m128*` | 289 | 30 |
| SV-10 | C | PHẢI | Bản phân phối có baseline x86-64-v2; đường AVX2/FMA viết trong hàm `[[gnu::target]]` và chọn một lần lúc khởi động bằng `__builtin_cpu_supports` | 320 | 48 |
| SV-11 | C | PHẢI | Hợp nhất nhân-cộng (FMA) là quyết định trong code (`std::fma`), không phải của cờ; code tất định build với `-ffp-contract=off` | 369 | 27 |
| SV-12 | C | PHẢI | Không để giá trị trôi vào vùng số không chuẩn trên đường nóng: kẹp về 0, hoặc bật FTZ/DAZ có chủ đích cho luồng mô phỏng | 397 | 38 |
| SV-13 | C | NÊN | Tổng dài của nhiều số hạng nhỏ dùng tổng bù Neumaier (hoặc `double` + thứ tự cố định) | 436 | 35 |
| SV-14 | T | PHẢI | Mô phỏng lockstep/replay tất định giữa các máy: fixed-point hoặc kiểm soát trọn chuỗi số thực | 474 | 41 |
| SV-15 | T | NÊN | Kiểm sai số đúng nghĩa bằng khoảng cách ulp khi so bản SIMD/ước lượng với bản chính xác | 516 | 36 |
| SV-16 | T | CÓ THỂ | Ước lượng `rcp`/`rsqrt` + một bước Newton–Raphson khi số đo cho thấy bộ chia/căn là nút thắt, và code không cần tất định | 553 | 30 |
| SV-17 | T | NÊN | Nhánh phụ thuộc dữ liệu khó đoán thì dùng chọn không nhánh (cmov/mặt nạ), và kiểm asm vì trình dịch có thể đổi ngược | 584 | 42 |
| SV-18 | T | PHẢI | Phép cộng dồn số thực nóng dùng nhiều bộ cộng dồn độc lập (SIMD tường minh), thứ tự cố định | 627 | 48 |
| SV-19 | T | PHẢI | Kiểm áp lực cổng thực thi trước khi tối ưu vi kiến trúc: shuffle ra khỏi vòng lặp nóng, không bật AVX-512 khi chưa đo tần số | 676 | 21 |
| SV-20 | T | NÊN | Thay gather/scatter bằng sắp lại dữ liệu cho liền mạch; sắp theo khoá toàn phần để giữ tất định | 698 | 36 |

## DT · Đồng thời: luồng, khoá, atomic, thứ tự bộ nhớ, lock-free — `refs/12-dong-thoi.md` (49 KB) · Kiểm nhanh: Dòng 1081, Dài 13

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| DT-01 | N | PHẢI | Trạng thái khả biến thuộc đúng một luồng; luồng khác gửi thông điệp qua hộp thư | 14 | 53 |
| DT-02 | N | CẤM | Tranh chấp dữ liệu: biến nhiều luồng chạm mà có luồng ghi phải là atomic hoặc cùng một mutex bảo vệ | 68 | 46 |
| DT-03 | N | PHẢI | Khoá bằng RAII, vùng khoá chỉ chạm bộ nhớ của lớp; không IO, log, callback hay tham chiếu thoát ra ngoài khoá | 115 | 50 |
| DT-04 | N | PHẢI | Luồng là thành viên `std::jthread` khai báo cuối lớp, dừng bằng `stop_token`, chờ bằng biến điều kiện có vị từ; CẤM `detach()`, `std::thread` trần, `sleep_for` thăm dò | 166 | 69 |
| DT-05 | N | PHẢI | Atomic chỉ cho một giá trị độc lập; đọc-rồi-ghi trên atomic là vòng CAS; bất biến nhiều biến dùng mutex | 236 | 28 |
| DT-06 | N | PHẢI | Mỗi kiểu dùng ở nhiều luồng ghi hợp đồng luồng; kiểu chỉ-luồng-sở-hữu tự kiểm luồng gọi ở bản debug | 265 | 51 |
| DT-07 | N | PHẢI | Code chạm nhiều luồng có test stress chạy dưới TSan trong CI; TSan sạch là điều kiện merge | 317 | 16 |
| DT-08 | C | NÊN | Mô hình luồng máy chủ: một luồng mỗi zone, luồng IO riêng, pool DB; chỉ giao tiếp qua hàng đợi có giới hạn | 336 | 25 |
| DT-09 | C | PHẢI | Thứ tự bộ nhớ mặc định `seq_cst`; hạ xuống theo bảng, và mỗi thao tác hạ cấp ghi tên thao tác ghép cặp | 362 | 56 |
| DT-10 | C | PHẢI | Dữ liệu do các luồng khác nhau ghi nằm trên các dòng cache khác nhau | 419 | 59 |
| DT-11 | C | NÊN | Pha song song trong tick dùng `std::barrier` (lặp) hay `std::latch` (một lần), không tự ghép mutex + biến điều kiện | 479 | 57 |
| DT-12 | C | NÊN | Cấu hình nóng là ảnh chụp bất biến `shared_ptr<const T>` thay nguyên khối; zone đổi ảnh chụp ở ranh giới tick | 537 | 45 |
| DT-13 | C | PHẢI | Lấy nhiều mutex cùng lúc bằng một `std::scoped_lock(a, b)`; khoá lấy lần lượt phải theo thứ bậc ghi trong tài liệu | 583 | 33 |
| DT-14 | T | CÓ THỂ | Ring buffer SPSC lock-free: chỉ số 64 bit đơn điệu, release/acquire ghép cặp, bản sao chỉ số phía kia, mỗi phía một dòng cache | 619 | 134 |
| DT-15 | T | CÓ THỂ | Seqlock đúng mô hình bộ nhớ: dữ liệu là các word nguyên tử, ghi release và đọc acquire | 754 | 68 |
| DT-16 | T | PHẢI | CAS trên chỉ số hay con trỏ phải chặn ABA bằng thẻ đóng gói cùng chỉ số trong một word 64 bit | 823 | 87 |
| DT-17 | T | NÊN | Thu hồi bộ nhớ cho người đọc không khoá: QSBR theo ranh giới tick (`std::rcu`, `std::hazard_pointer` là C++26) | 911 | 85 |
| DT-18 | T | CẤM | `volatile` để đồng bộ; chờ bận chỉ khi đo thấy chờ rất ngắn, luôn có `pause` và giới hạn trước khi nhường OS | 997 | 32 |
| DT-19 | T | PHẢI | Lập luận happens-before thành văn cho mọi thứ tự yếu hơn `seq_cst`; biết chỗ TSan mù | 1030 | 50 |

## UB · UB và ổn định — `refs/13-ub-on-dinh.md` (46 KB) · Kiểm nhanh: Dòng 887, Dài 14

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| UB-01 | N | PHẢI | Số học số nguyên có dấu: chứng minh không tràn hoặc tính ở kiểu rộng hơn; phép chia loại cả mẫu 0 lẫn `INT_MIN / -1` | 41 | 45 |
| UB-02 | N | PHẢI | Số bit dịch nằm trong `[0, độ rộng)` của kiểu SAU thăng hạng; số học trên `uint8_t`/`uint16_t` là số học `int` | 87 | 35 |
| UB-03 | N | CẤM | `reinterpret_cast` vùng byte thành số hay struct để đọc; dùng `std::memcpy` vào đối tượng có sẵn hoặc `std::bit_cast` | 123 | 34 |
| UB-04 | N | PHẢI | Ranh giới tin cậy: kiểm độ dài trước mọi lần đọc, viết dạng `need > size - pos`; mọi độ dài khai báo có trần | 158 | 66 |
| UB-05 | N | PHẢI | Đổi số thực sang số nguyên chỉ sau khi kiểm hữu hạn và trong miền đích | 225 | 42 |
| UB-06 | N | CẤM | Đọc giá trị chưa khởi tạo; gói tin ghi từng trường, không `memcpy` cả struct có byte đệm | 268 | 42 |
| UB-07 | N | PHẢI | Mọi test chạy dưới ASan + UBSan với `-fno-sanitize-recover=all`; TSan ở bản riêng; GCC thêm `float-cast-overflow` | 311 | 26 |
| UB-08 | N | PHẢI | Bật hardening thư viện chuẩn ở mọi bản build: mức đầy đủ cho debug và test, mức nhanh cho máy chủ phát hành | 338 | 25 |
| UB-09 | N | PHẢI | Giải mã `enum`, `bool`, chỉ số từ dây qua hàm kiểm miền; không `static_cast` hay `memcpy` thẳng | 364 | 36 |
| UB-10 | C | PHẢI | Số học tiền tệ và kích thước dùng `__builtin_*_overflow` bọc trong hàm `checked_*`; `std::add_sat`/`std::mul_sat` là C++26 | 403 | 41 |
| UB-11 | C | PHẢI | Phân biệt UB, implementation-defined, unspecified; code tất định không dựa vào hai loại sau | 445 | 38 |
| UB-12 | C | CẤM | Dùng `-fwrapv`, `-fno-strict-aliasing`, `-fno-delete-null-pointer-checks` làm "cách sửa" UB | 484 | 16 |
| UB-13 | C | PHẢI | Hàng đợi gửi mỗi phiên có trần byte; đầy thì ngắt phiên chậm, không tăng vô hạn | 501 | 42 |
| UB-14 | C | PHẢI | Mỗi phiên có giới hạn tốc độ theo tick (token bucket số nguyên) và ngân sách tài nguyên | 544 | 56 |
| UB-15 | C | PHẢI | Mọi chờ đợi có thời hạn; tick có watchdog; chỉ thử lại thao tác idempotent mang id yêu cầu | 601 | 44 |
| UB-16 | T | NÊN | Dùng đánh giá hằng làm máy dò UB: hàm thuần `constexpr` thử ca biên bằng `static_assert` | 648 | 51 |
| UB-17 | T | NÊN | Một bản CI Clang thêm UBSan mở rộng (`implicit-conversion`, `local-bounds`) và một bản MSan khi mọi mã được instrument | 700 | 25 |
| UB-18 | T | CÓ THỂ | Máy chủ phát hành giữ một tập UBSan rẻ ở chế độ trap | 726 | 19 |
| UB-19 | T | PHẢI | Biết trình dịch khai thác UB: kiểm tràn đặt sau phép tràn và kiểm null đặt sau dereference đều bị xoá | 746 | 60 |
| UB-20 | T | PHẢI | Con trỏ chỉ đi trong `[begin, end]` của đúng một mảng; thứ tự giữa con trỏ khác mảng dùng `std::less` | 807 | 35 |
| UB-21 | T | PHẢI | Handler tín hiệu chỉ ghi một `std::atomic` không khoá; mọi việc khác làm ở vòng tick | 843 | 43 |

## BD · Build và toolchain — `refs/14-build-toolchain.md` (40 KB) · Kiểm nhanh: Dòng 673, Dài 13

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| BD-01 | N | PHẢI | CMake ≥ 3.28; mọi thiết lập gắn vào target; `cxx_std_23` và `CMAKE_CXX_EXTENSIONS OFF`; không sửa `CMAKE_CXX_FLAGS` trong CMakeLists | 42 | 75 |
| BD-02 | N | PHẢI | Cảnh báo lấy từ `config/warnings-*.txt` qua target INTERFACE `game::warnings`; `-Werror` bật bằng `COMPILE_WARNING_AS_ERROR` trong CI | 118 | 44 |
| BD-03 | N | PHẢI | Ba cấu hình Debug / RelWithDebInfo / Release; `GAME_DEBUG_CHECKS` gắn qua target INTERFACE `game::options` cho cả chương trình | 163 | 22 |
| BD-04 | N | PHẢI | `CMakePresets.json` mô tả mọi cấu hình dev và CI; CI chỉ gọi preset | 186 | 81 |
| BD-05 | N | PHẢI | clang-tidy dùng đúng `.clang-tidy` của bộ quy cách; `compile_commands.json` luôn bật | 268 | 29 |
| BD-06 | N | PHẢI | MSVC: `/W4 /permissive- /Zc:__cplusplus /Zc:preprocessor /utf-8`, `/WX` trong CI (chưa kiểm trên MSVC) | 298 | 21 |
| BD-07 | N | NÊN | Ninja + ccache; quét module tắt khi chưa dùng module | 320 | 15 |
| BD-08 | C | PHẢI | Preset sanitizer: `address,undefined` chung một build, `thread` build riêng; cờ biên dịch và liên kết khớp nhau | 338 | 40 |
| BD-09 | C | PHẢI | Bản RelWithDebInfo/Release của máy chủ bật cờ cứng hoá OpenSSF và kiểm biên thư viện; kiểm kết quả trên binary | 379 | 63 |
| BD-10 | C | PHẢI | Mọi cấu hình máy chủ giữ frame pointer, thông tin gỡ lỗi và build-id; đường dẫn nguồn trong binary là tương đối | 443 | 24 |
| BD-11 | C | PHẢI | clang-tidy trong CI chạy trên phần diff, bằng compile DB của build Clang + libc++, 0 cảnh báo | 468 | 20 |
| BD-12 | C | PHẢI | Ma trận CI: hai thư viện chuẩn × hai mục đích, cộng TSan; mọi PR qua hết | 489 | 24 |
| BD-13 | C | NÊN | PCH cho header chuẩn nặng và ổn định; CI có một build tắt PCH | 514 | 15 |
| BD-14 | T | CÓ THỂ | Module C++20 của dự án qua `FILE_SET CXX_MODULES` (CMake 3.28 + Ninja ≥ 1.11); `import std;` chưa | 532 | 24 |
| BD-15 | T | NÊN | Đo thời gian build trước khi tối ưu nó: `.ninja_log`, Clang `-ftime-trace`, GCC `-ftime-report` | 557 | 18 |
| BD-16 | T | NÊN | Liên kết bằng lld (hoặc mold); bỏ section thừa bằng `--gc-sections`; gộp hàm trùng bằng `--icf=safe` | 576 | 20 |
| BD-17 | T | PHẢI | Mọi bản phát hành tách symbol theo build-id và lưu lại; binary chạy trên máy chủ không có `.debug_*` | 597 | 29 |
| BD-18 | T | CÓ THỂ | `-fhardened` (GCC ≥ 14) thay danh sách cờ của BD-09 trên build GCC; kiểm macro thật nó sinh ra | 627 | 19 |
| BD-19 | T | PHẢI | Công cụ lỗi thì tắt ĐÚNG check/cờ gây lỗi, ghi phiên bản và lý do cạnh chỗ tắt, giữ ca tái hiện | 647 | 25 |

## KT · Kiểm thử — `refs/15-kiem-thu.md` (50 KB) · Kiểm nhanh: Dòng 1180, Dài 14

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| KT-01 | N | PHẢI | Test là chương trình C++ thuần trên khung tối giản của dự án: bảng test `constexpr`, `expect` ghi `source_location` | 15 | 91 |
| KT-02 | N | PHẢI | Logic là hàm thuần có unit test; mỗi test một hành vi, tên dạng `<chủ thể>_<tình huống>_<kết quả>` | 107 | 54 |
| KT-03 | N | PHẢI | Mỗi hàm có bảng ca biên viết thành dữ liệu; vòng lặp test chỉ gọi hàm kiểm một ca | 162 | 65 |
| KT-04 | N | PHẢI | Hàm `constexpr` được test bằng `static_assert` trên bảng ca; hàm có `if consteval` test cả đường chạy | 228 | 40 |
| KT-05 | N | PHẢI | Test tất định: thời gian và ngẫu nhiên là tham số; seed cố định, in ra khi đỏ | 269 | 61 |
| KT-06 | N | CẤM | `sleep` trong test; tua đồng hồ giả, hoặc chờ sự kiện có hạn chót | 331 | 39 |
| KT-07 | N | PHẢI | Mọi test chạy trong ma trận: GCC + libstdc++ và Clang + libc++, dưới ASan + UBSan; test có luồng thêm TSan | 371 | 21 |
| KT-08 | N | PHẢI | Mỗi lỗi sửa kèm test hồi quy dùng đúng đầu vào gây lỗi, tên theo hành vi, ghi mã sự cố | 393 | 43 |
| KT-09 | C | PHẢI | Bất biến kiểm bằng test thuộc tính: đầu vào sinh từ seed cố định, thuộc tính như round-trip `decode(encode(x)) == x` | 439 | 66 |
| KT-10 | C | PHẢI | Mỗi loại gói tin có golden test: byte mong đợi viết tay trong test | 506 | 47 |
| KT-11 | C | PHẢI | Mọi hàm giải mã dữ liệu không tin cậy có harness libFuzzer; corpus hạt giống chạy lại như test thường | 554 | 61 |
| KT-12 | C | PHẢI | Test đồng thời là stress test: các luồng xuất phát cùng lúc qua `std::latch`, kiểm bất biến bảo toàn, chạy dưới TSan | 616 | 88 |
| KT-13 | C | PHẢI | Benchmark dùng harness thuần C++ của dự án: khởi động, nhiều mẫu theo lô, trung vị và p99, chặn loại bỏ mã chết | 705 | 86 |
| KT-14 | C | PHẢI | Mỗi `check` bảo vệ an ninh hay dữ liệu có death test: tiến trình con phải dừng với đúng thông điệp | 792 | 20 |
| KT-15 | T | PHẢI | Bản SIMD hay ước lượng có test sai phân với bản tham chiếu, ngưỡng sai số là số đo và tài liệu, không phải đoán | 815 | 56 |
| KT-16 | T | NÊN | Replay test: ghi input theo tick, chạy lại từ cùng trạng thái đầu, so hash trạng thái từng tick và chỉ ra tick lệch đầu tiên | 872 | 75 |
| KT-17 | T | NÊN | Hàm trên miền nhỏ test vét cạn: mọi 2^16 giá trị `Half`, và mọi 2^32 `float` cho hàm then chốt | 948 | 67 |
| KT-18 | T | NÊN | Fuzz có cấu trúc: harness tự dựng phần khung (độ dài, checksum) hoặc đọc byte thành chuỗi thao tác so với mô hình tham chiếu | 1016 | 68 |
| KT-19 | T | PHẢI | Test không dựa vào thứ unspecified; ma trận libstdc++ + libc++ là thứ bắt lỗi này | 1085 | 52 |
| KT-20 | T | NÊN | Hợp đồng `constexpr` có test vi phạm lúc biên dịch: `requires` trên đối số mẫu hằng biến "tính hằng thất bại" thành `false` | 1138 | 41 |

## CM · Comment và tài liệu — `refs/16-comment-tai-lieu.md` (28 KB) · Kiểm nhanh: Dòng 552, Dài 12

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| CM-01 | N | PHẢI | Mỗi tệp mở bằng comment đầu tệp: câu 1 nói tệp chứa gì và từ đâu; sau đó ranh giới, quy ước chung, nơi có tài liệu | 14 | 34 |
| CM-02 | N | PHẢI | Code port liệt kê `Khác gốc:`, mỗi gạch một khác biệt có chủ đích kèm lý do; lỗi của gốc nói rõ gốc sai thế nào | 49 | 79 |
| CM-03 | N | PHẢI | Comment hàm nói hợp đồng: tiền điều kiện, miền, ca biên, độ chính xác, thứ tự phép tính | 129 | 28 |
| CM-04 | N | CẤM | Comment kể lại code, comment hiển nhiên | 158 | 40 |
| CM-05 | N | PHẢI | Port: tên gốc trong ngoặc ở cuối comment, gộp gọn cho cả nhóm | 199 | 31 |
| CM-08 | N | PHẢI | `static_assert` thay comment khi điều kiện kiểm được lúc biên dịch | 231 | 32 |
| CM-09 | N | PHẢI | TODO có chủ và đường theo dõi: `// TODO(<người>, #<issue>): <việc cụ thể>.` | 264 | 25 |
| CM-10 | N | PHẢI | Lựa chọn không hiển nhiên và mọi chỗ lệch quy tắc có comment "vì sao" ngay tại chỗ | 290 | 32 |
| CM-11 | C | PHẢI | API dùng chung ghi thêm: bất biến của lớp, an toàn luồng, cấp phát, vòng đời của view | 325 | 48 |
| CM-12 | C | PHẢI | Thông điệp check là tài liệu: `"<hàm>: <điều kiện phải đúng>"` | 374 | 27 |
| CM-13 | C | PHẢI | Mỗi module có docs/modules/<module>.md: mục đích, kiểu chính, quy ước, bảng ánh xạ tên gốc | 402 | 23 |
| CM-14 | C | PHẢI | Quyết định kiến trúc ghi ADR ngắn: docs/adr/NNNN-<tên>.md | 426 | 22 |
| CM-15 | T | PHẢI | Comment tối ưu ghi số đo đủ để tái lập và điều kiện xét lại | 451 | 16 |
| CM-16 | T | PHẢI | Khẳng định độ chính xác hay "đúng với mọi đầu vào" nêu cách đã chứng minh | 468 | 48 |
| CM-17 | T | PHẢI | Khẳng định về mã máy ("không rẽ nhánh", "một lệnh X", "vector hoá") nêu trình dịch, cờ đã kiểm và cách kiểm lại | 517 | 34 |

## KTR · Kiến trúc và module: tầng, phụ thuộc, cấu hình, log, triển khai — `refs/17-kien-truc-module.md` (45 KB) · Kiểm nhanh: Dòng 916, Dài 14

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| KTR-01 | N | PHẢI | Tầng phụ thuộc một chiều: một module chỉ include module mà cột "Được dùng" của bảng tầng cho phép | 15 | 37 |
| KTR-02 | N | CẤM | Phụ thuộc vòng giữa module; tầng dưới báo cho tầng trên bằng dữ liệu (sự kiện), không bằng lời gọi ngược | 53 | 47 |
| KTR-03 | N | PHẢI | Mỗi header tự đủ và nói về một khái niệm; CI biên dịch từng header thành một TU riêng | 101 | 24 |
| KTR-04 | N | CẤM | Singleton, biến toàn cục khả biến và `static` cục bộ khả biến; trạng thái thuộc một đối tượng ngữ cảnh truyền tường minh | 126 | 58 |
| KTR-05 | N | PHẢI | Cấu hình và dữ liệu nội dung là dữ liệu: struct có mặc định có tên, kiểm hợp lệ một lần khi nạp, bất biến sau đó | 185 | 53 |
| KTR-06 | N | PHẢI | Log đi qua một giao diện hẹp ở tầng core; thư viện không ghi thẳng ra stdout/stderr hay tệp | 239 | 43 |
| KTR-07 | N | PHẢI | Thời gian và ngẫu nhiên là đầu vào: logic nhận `now` (tick) làm tham số; chỉ vỏ đọc đồng hồ, một lần mỗi tick | 283 | 55 |
| KTR-08 | C | PHẢI | Thiết kế vật lý: header công khai tối thiểu, chi tiết trong `detail` hoặc `.cpp`, khai báo trước kiểu chỉ dùng qua tham chiếu | 341 | 53 |
| KTR-09 | C | PHẢI | Mọi định dạng vượt ranh giới tiến trình hay thời gian mang số phiên bản; đọc bản cũ qua chuỗi nâng cấp từng bước | 395 | 72 |
| KTR-10 | C | NÊN | Cờ tính năng là cấu hình có kiểu; nạp lại nóng = dựng ảnh chụp mới, kiểm hợp lệ, đổi ở ranh giới tick, giữ bản cũ để lùi | 468 | 50 |
| KTR-11 | C | NÊN | Tiêm phụ thuộc: tham số template ràng buộc concept trên đường nóng; constructor nhận giao diện ảo ở đường lạnh và ranh giới | 519 | 48 |
| KTR-12 | C | NÊN | Lõi thuần, vỏ mệnh lệnh: luật chơi là hàm (trạng thái, yêu cầu) → kết quả hoặc lỗi; IO, log, lưu, gửi nằm ở vỏ quanh tick | 568 | 48 |
| KTR-13 | C | NÊN | Hệ thống chạy trên nhiều thực thể mỗi tick theo hướng dữ liệu (mảng thành phần + hàm hệ thống); OOP cho đối tượng ít, sống lâu, đa hình thật | 617 | 42 |
| KTR-14 | T | CÓ THỂ | Modules C++20: một module mỗi tầng, partition giao diện cho API, đơn vị cài đặt cho chi tiết; chỉ khi cả chuỗi công cụ đã ổn | 662 | 56 |
| KTR-15 | T | PHẢI | Bảng tầng là dữ liệu và được máy kiểm: mỗi module một target, test `layers` quét include ngược tầng theo bảng | 719 | 65 |
| KTR-16 | T | NÊN | Zone là đơn vị sở hữu và triển khai; giao tiếp liên zone và với dịch vụ toàn cục chỉ bằng thông điệp có id, định tuyến qua bảng | 784 | 56 |
| KTR-17 | T | NÊN | Triển khai không dừng: gateway giữ kết nối, zone chuyển giao trạng thái đã phiên bản hoá ở ranh giới tick, luôn có đường lùi | 841 | 20 |
| KTR-18 | T | PHẢI | Quan sát được: số liệu theo luồng gộp định kỳ, histogram log-tuyến tính cho độ trễ, log có cấu trúc mang trace id của phiên/giao dịch | 862 | 53 |

## MMO · Máy chủ game MMO: tick, thực thể, giao thức, AOI, kinh tế, tất định, chống gian lận — `refs/18-game-mmo.md` (80 KB) · Kiểm nhanh: Dòng 1693, Dài 14

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| MMO-01 | N | PHẢI | Máy chủ quyết định: client gửi ý định, không gửi kết quả; mọi trường được kiểm trước khi chạm trạng thái | 17 | 70 |
| MMO-02 | N | PHẢI | Mô phỏng chạy bước cố định với accumulator số nguyên; số bước bù mỗi vòng có trần, phần nợ vượt trần bị bỏ và đếm | 88 | 45 |
| MMO-03 | N | PHẢI | Thời gian game là số tick nguyên; thời lượng thiết kế (ms) đổi sang tick bằng làm tròn lên, một lần lúc nạp | 134 | 61 |
| MMO-04 | N | PHẢI | Thực thể được tham chiếu bằng handle thế hệ (chỉ số + thế hệ); con trỏ chỉ sống trong một tick | 196 | 76 |
| MMO-05 | N | PHẢI | Khung gói có tiền tố độ dài; độ dài được kiểm với trần TRƯỚC khi chờ thân hay cấp phát; khung hỏng là đóng phiên | 273 | 51 |
| MMO-06 | N | PHẢI | Thân gói đọc qua `Reader` trên `span<const std::byte>`: kiểm biên mỗi lần đọc, little-endian ghép từ byte, lỗi dính, chuỗi UTF-8 kiểm chặt, kiểm "đã đọc hết" ở cuối | 325 | 201 |
| MMO-07 | N | PHẢI | Tiền và số lượng là số nguyên 64 bit đơn vị nhỏ nhất, có trần kinh tế; CẤM số thực cho mọi giá trị kinh tế | 527 | 46 |
| MMO-08 | N | PHẢI | Giao dịch, chế tạo, thư, đấu giá theo hai pha: kiểm hết trên trạng thái chỉ đọc tạo ra "kế hoạch", rồi áp dụng không thể thất bại | 574 | 84 |
| MMO-09 | N | PHẢI | Mọi thay đổi kinh tế ghi một sự kiện append-only: id giao dịch, nhân vật, luồng tiền, delta và số dư sau | 659 | 67 |
| MMO-10 | C | NÊN | AOI bằng lưới đều, cạnh ô ≥ bán kính nhìn, dựng lại mỗi tick bằng sắp xếp đếm vào hai mảng phẳng; truy vấn 3×3 ô | 729 | 102 |
| MMO-11 | C | PHẢI | Thứ tự pha trong tick cố định và là dữ liệu: một bảng `constexpr` các pha, đo thời lượng từng pha | 832 | 54 |
| MMO-12 | C | NÊN | Snapshot gửi delta so với baseline mà client đã xác nhận (ack), kèm mặt nạ trường đổi; baseline quá cũ thì gửi đầy đủ | 887 | 47 |
| MMO-13 | C | PHẢI | Input mỗi phiên đi qua cổng: số thứ tự trong cửa sổ, bỏ trùng và cũ, trần số input mỗi tick | 935 | 49 |
| MMO-14 | C | PHẢI | Chống gian lận ở máy chủ: kiểm tốc độ, cooldown, tầm, tầm nhìn bằng số nguyên; vi phạm thì sửa về trạng thái máy chủ và cộng điểm nghi ngờ, không kick ngay | 985 | 57 |
| MMO-15 | C | PHẢI | Lưu DB bất đồng bộ kiểu write-behind với số phiên bản: luồng zone không chờ DB; ghi có điều kiện để thử lại an toàn | 1043 | 78 |
| MMO-16 | C | PHẢI | Opcode được phép phụ thuộc trạng thái phiên; kiểm trước khi giải mã thân gói | 1122 | 57 |
| MMO-17 | C | PHẢI | Ngẫu nhiên gameplay dùng PRNG tự viết (xoshiro256** gieo bằng splitmix64) và phân phối tự viết; mỗi hệ thống một luồng ngẫu nhiên có seed ghi log | 1180 | 85 |
| MMO-18 | T | PHẢI | Mô phỏng phải tất định (lockstep, replay, kiểm chéo) thì dùng số học điểm cố định và loại mọi nguồn bất định đã biết | 1268 | 63 |
| MMO-19 | T | NÊN | Băm trạng thái mô phỏng định kỳ, theo thứ tự id, nạp từng trường bằng byte tường minh; so giữa máy chủ, replay và bản chuyển giao | 1332 | 63 |
| MMO-20 | T | CÓ THỂ | Nén trạng thái gửi đi bằng bit-packing, zigzag + varint cho số có dấu nhỏ, và lượng tử hoá theo miền | 1396 | 107 |
| MMO-21 | T | PHẢI | Chống nhân bản vật phẩm: uid duy nhất toàn cục cho vật phẩm giá trị, id giao dịch cho mọi lần chuyển, DB áp dụng idempotent trong một transaction | 1504 | 56 |
| MMO-22 | T | PHẢI | Ngân sách tick: rút hộp thư có hạn mức, cắt tải theo mức có trễ khi p95 tick vượt ngưỡng; không bao giờ cắt input, chiến đấu, kinh tế | 1561 | 67 |
| MMO-23 | T | PHẢI | Chuyển thực thể giữa zone bằng hai pha có id chuyển giao: tại mọi thời điểm đúng một zone làm chủ, mọi thông điệp lặp đều vô hại | 1629 | 63 |

## RV · Review và checklist giao code — `refs/19-review-checklist.md` (12 KB) · Kiểm nhanh: Dòng 159, Dài 8

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| RV-01 | N | PHẢI | Tự review theo checklist §4 trước khi giao, theo thứ tự từ cấp N lên | 10 | 8 |
| RV-02 | N | PHẢI | Máy kiểm trước, mắt người sau | 19 | 9 |
| RV-03 | N | PHẢI | Mỗi nhận xét review nêu mã quy tắc, vị trí, hệ quả và cách sửa | 29 | 15 |
| RV-04 | N | PHẢI | Báo cáo cuối việc: Đã kiểm / Chưa kiểm / Giả định / Lệch quy tắc | 45 | 17 |
| RV-05 | C | PHẢI | Thay đổi chạm ranh giới tin cậy, đa luồng hay dữ liệu lưu được review theo lăng kính riêng | 65 | 10 |
| RV-06 | C | PHẢI | Thay đổi vì hiệu năng chỉ được nhận khi có phiếu đo | 76 | 7 |
| RV-07 | T | PHẢI | Mã [T] được review bởi người không viết nó, đối chiếu lập luận chứ không chỉ chạy test | 86 | 9 |

## CL · Chất lượng cực hạn: năm thuộc tính, bằng chứng, cổng máy — `refs/20-chat-luong-cuc-han.md` (27 KB) · Kiểm nhanh: Dòng 367, Dài 12

| Mã | Cấp | Mức | Quy tắc | Dòng | Dài |
|---|---|---|---|---|---|
| CL-01 | N | PHẢI | Mọi thay đổi đạt đủ năm thuộc tính an toàn, bền, tối ưu, hiện đại, thông minh; mỗi thuộc tính có bằng chứng trong báo cáo | 16 | 19 |
| CL-02 | N | PHẢI | Mọi tệp C++ đã đổi qua trọn cổng máy: hai trình dịch với bộ cảnh báo đầy đủ, clang-tidy, và test chạy trên hai thư viện chuẩn | 36 | 25 |
| CL-03 | N | PHẢI | Phân tích thất bại trước khi viết: với mỗi đầu vào, tài nguyên và bước, trả lời "hỏng thế nào" rồi mới viết mã | 62 | 20 |
| CL-04 | N | PHẢI | Mỗi mã lỗi, mỗi câu bảo vệ, mỗi ca biên có test đi tới nó; đường lỗi chưa từng chạy là mã chưa xong | 83 | 99 |
| CL-05 | N | PHẢI | Ghi độ phức tạp và trần đầu vào ở hợp đồng của mọi vòng lặp theo dữ liệu; CẤM thuật toán trên tuyến tính khi kích thước do bên ngoài quyết định | 183 | 12 |
| CL-06 | N | CẤM | Idiom cũ khi C++23 có thay thế chuẩn an toàn hơn | 196 | 30 |
| CL-07 | N | PHẢI | Điều gì máy chứng minh được thì để máy chứng minh: đặt mỗi bất biến ở bậc cao nhất dùng được | 227 | 18 |
| CL-08 | N | PHẢI | Thiết kế đơn giản nhất đủ năm thuộc tính: mỗi lớp trừu tượng, tham số và tuỳ chọn có nơi dùng thật ngay trong thay đổi này | 246 | 11 |
| CL-09 | C | PHẢI | Hàm chạy mỗi tick trên đường nóng khai `GAME_NONALLOCATING` để Clang chứng minh nó không cấp phát; luồng không được chờ khai `GAME_NONBLOCKING` | 260 | 68 |
| CL-10 | T | PHẢI | Nâng cấp trình dịch hay clang-tidy thì đo lại cổng: thử mọi chẩn đoán mới trên bộ mẫu, giữ cái sạch, ghi cái loại kèm số đo | 331 | 35 |
