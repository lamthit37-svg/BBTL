# Audit B: i18n (2026-10-13), đối chấp, chỉ đọc

Người audit: thành viên B. Chỉ đọc mã nguồn và dữ liệu; tệp này là tệp duy nhất được ghi.
Phạm vi: `assets/i18n/{en,zh,vi}.tsv`, `glossary.tsv`, `TOOLS/content/build_i18n.py` và test, `src/shared/table/localize.*`, `src/client/face/ui/hud.cpp`, bảng đã triển khai ở `dev/client/assets/Table/` (bản dựng hiện tại là **zh**), các script trong `C:\tlx` và `build\i18n_extract`.
Cách làm: script Python chạy trên bản sao của các tệp (parity khoá, thẻ, khoảng trắng, đối chiếu id và cột với bảng xuất, nhất quán thuật ngữ, kiểu chữ), cộng với soát tay 300 mẫu ngẫu nhiên (seed 42).

## Tóm tắt số liệu
| Hạng mục | Kết quả |
|---|---|
| Số khoá zh / vi / en | 120.605 / 120.605 / 120.603 |
| Khoá trùng, dòng hỏng (số tab, CR, dòng trống) | 0 / 0 |
| Khoá `table/` trỏ tới bảng, id hay cột không tồn tại | 0 (đã đối chiếu 106.581 ô với các tệp bảng xuất) |
| Giá trị zh của khoá `table/` khác ô gốc | 0 |
| Thẻ và chỗ điền lệch so với zh | 0 lỗi thật (4 dòng bị script đánh dấu đều là dương tính giả: `%s124点` = `%s1`+`24点`, `##` là ký tự thường) |
| Chữ Hán sót trong en/vi (ngoài `#{...}`) | 0 |
| Bản dịch `table/` đã triển khai khớp số dòng với nguồn | có (7/7 bảng) |
| `test_build_i18n.py` | chạy qua, không thấy lỗi |

Cấu trúc tệp và độ đúng của build_i18n đều ổn. **Lỗi nặng nằm ở phía client: hầu như không bản dịch nào được hiện ra** (I18N-B-01, I18N-B-02). Lỗi chất lượng nằm ở văn phong tiếng Việt và độ nhất quán thuật ngữ.

## Phát hiện

### I18N-B-01: Critical. Client không nạp `ui_strings.lang.tsv`, nên 13.765 chuỗi giao diện đã dịch không bao giờ hiện
- Bằng chứng: `hud.cpp:224-230` hàm `strings_of()` chỉ gọi `add_strings(book, ".../ui_strings.tsv")`. Chú thích ghi: "Bản dịch Table/ui_strings.lang.tsv chưa nạp: chủ dự án muốn hết bản gốc trước, tiếng Việt để sau". Tìm `ui_strings.lang` trong `src/` và `engine/` chỉ thấy chú thích.
- Nguyên nhân: phần nối dây chưa làm. Báo cáo i18n coi việc "dịch xong" như "hiện trong game".
- Đề xuất sửa: sau `ui_strings.tsv`, gọi thêm `add_strings(book, data_root/"Table"/"ui_strings.lang.tsv")`. Đây là overlay: khoá nào chưa có thì giữ gốc. Thêm test cho `strings_of` có tệp lang, và cần chủ dự án xác nhận vì chú thích cho thấy trước đó đã có quyết định chưa nạp.

### I18N-B-02: Critical. Không bảng nào trong 7 bảng đã dịch (items, equips, campaign_items, skills, gems, inner_arts, life_skills) được client đọc
- Bằng chứng: `read_table()`, và qua đó `localize_table()`, chỉ được gọi cho `faces`, `hairs`, `newbie_outfits`, `portraits`, `ui_strings`, `scene_names.lang`. Tìm `"items.tsv"`, `"equips.tsv"`, `"skills.tsv"`… trong `src/` và `engine/` không ra kết quả nào. Các tệp `*.lang.tsv` vẫn được sinh ra (`dev/client/assets/Table/items.lang.tsv` 40.990 dòng…) nhưng không có ai đọc.
- Nguyên nhân: client chưa có hệ thống vật phẩm hay kỹ năng nào đọc các bảng này. Lượt trước đã có ghi chú việc này nhưng chưa thành mục chặn.
- Đề xuất sửa: khi thêm nơi đọc bảng (túi đồ, tooltip, sách kỹ năng), bắt buộc đi qua `read_table()`. Thêm một test tích hợp: dựng với `GAME_LANGUAGE=vi`, đọc `items.tsv` qua `read_table` và kiểm `name` của một id đã biết là chữ Việt. Đến lúc đó, báo cáo phải ghi rõ là "đã dịch, chưa hiện".

### I18N-B-03: High. Thứ tự từ trong tên trang bị bộ "X之Y" tiếng Việt không thống nhất
- Bằng chứng: có 8.305 tên trang bị dạng `XX之…`, trong đó 1.583 tên dùng "X Chi Y" và 6.722 tên dùng thứ tự khác. Cùng một tiền tố mà lẫn hai kiểu, ví dụ `玉女之` có 200 tên "Chi" và 641 tên kiểu khác. Mẫu cụ thể: `荒毒之棉丝鞋` thành "Hoang Độc Chi Miên Ti Hài", nhưng `荒毒之如梦手套` lại thành "Găng Như Mộng Hoang Độc", và `降龙之玄铁铠` thành "Khải Huyền Thiết Hàng Long".
- Nguyên nhân: nhiều luật ghép tên chạy ở các đợt khác nhau, và đợt đổi sang Hán Việt (1.626 tên) không phủ hết.
- Đề xuất sửa: chốt một mẫu theo TLBB VN. Đề xuất "Y + X" bỏ "Chi", ví dụ "Miên Ti Hài Hoang Độc", hoặc giữ "X Chi Y", miễn là một kiểu. Sinh lại toàn bộ `equips/*/name` có `之` bằng một luật duy nhất, sao lưu trước, rồi thêm kiểm tra trong lint.

### I18N-B-04: High. Còn khoảng 1.934 tên trang bị chứa từ thuần Việt, trái với quyết định "chuẩn TLBB / Hán Việt"
- Bằng chứng: "Hộ Vai Da Thằn Lằn Ngưng Mạch" (凝脉之蜥皮护肩), "Vai Vải Bông Vô Cực" (无极之棉布肩), "Hài Da Bạc Vô Tướng". Trong khi đó cột `type_name` của cùng món là "Hộ Kiên". Món ăn cũng lẫn kiểu: "Hoạt Nộn Long Tuyền Báo Nhục" đứng cạnh "Cá Nhồi Thịt Cừu".
- Nguyên nhân: đợt chuyển sang Hán Việt chỉ thay theo một danh sách từ hữu hạn.
- Đề xuất sửa: lập bảng chuyển chất liệu và bộ phận (Vai→Kiên, Vải Bông→Miên Bố, Da→Bì, Bạc→Ngân, Găng→Thủ Sáo…), áp cho toàn bộ `equips` và `items`. Nếu có danh sách tên chính thức của VNG thì đối chiếu với danh sách đó.

### I18N-B-05: Medium. Viết hoa trong tiếng Việt không đồng đều
- Bằng chứng: `type_name` có 27.834 ô viết hoa đầu từ ("Thời Trang", "Toạ Kỵ") và 22.484 ô viết thường ("Đạo cụ nhiệm vụ", "Điêu văn đỏ"). Có 6.157 trên 56.263 ô `name` chứa từ viết thường, ví dụ "(cấp 9)", "Người tuyết nghịch ngợm", "Huỷ biến thân", "Ăn dưa Hami". Cùng một chữ zh mà khác cách viết hoa: 坐骑 có Toạ Kỵ ×4371, Toạ kỵ ×1, Thú Cưỡi ×3; 烟花 có Pháo hoa ×237, Pháo Hoa ×3; 称号 có Danh hiệu ×79, Danh Hiệu ×3.
- Nguyên nhân: không có quy ước văn phong cho từng loại cột.
- Đề xuất sửa: đặt quy ước "tên riêng (`name`, `type_name`) Title Case; câu giao diện viết hoa chữ đầu câu", gồm cả "(Cấp N)" như đã báo với người dùng. Sửa bằng script và thêm kiểm tra vào lint.

### I18N-B-06: Medium. Thuật ngữ: cùng một chữ zh có nhiều bản dịch, và glossary tự mâu thuẫn
- Bằng chứng, với chuỗi zh dài ≤8 ký tự: vi có 202 cụm và en có 74 cụm nhận nhiều bản dịch. Ví dụ en: 时装 Outfit/Fashion; 护肩 Shoulder Guards/Pauldrons/Shoulders (cùng loại đồ mà tên món dùng "Pauldrons", `type_name` lại dùng "Shoulder Guards"); 珍兽 Treasure Beast/Pet; 打造图 Crafting Plan/Patterns; 前一页 Previous/Previous Page. Ví dụ vi: 打造图 "Bản vẽ chế tạo"/"Đồ Phổ"; 确定 "Xác nhận"/"Đồng ý"; 秘籍 "Bí Tịch"/"Sách".
- Glossary có 11 mục trùng chữ zh và mâu thuẫn nhau: 珍兽 (Treasure Beast/beast), 武魂 (Martial Soul/War Soul), 星阵 (star formation/star array), 段位, 神器, 雕纹 (khác hoa thường)…
- Bản dịch lệch khỏi glossary: glossary ghi 坐骑 = "thú cưỡi", nhưng 4.388 ô dùng "Toạ Kỵ"; 金蚕丝 glossary ghi "Kim Tàm Ti", bản dịch ghi "Kim Tằm Ti" (15/16); 返券 glossary ghi "Phiếu hoàn", bản dịch ghi "phản phiếu"; 命中 glossary ghi "mệnh trung", bản dịch ghi "Chính Xác"; 帮贡, 扫荡 cũng lệch.
- Nguyên nhân: glossary được nối thêm qua nhiều đợt mà không gộp lại, và không có kiểm tra tự động bản dịch so với glossary.
- Đề xuất sửa: gộp glossary về đúng một dòng cho mỗi chữ zh, chốt 坐骑 là "Toạ Kỵ" hay "Thú Cưỡi" (theo TLBB VN, rồi sửa hoặc glossary hoặc bản dịch). Thêm `tsv_lint`/`build_i18n --check-glossary` báo lỗi khi chuỗi zh ngắn chứa thuật ngữ mà bản dịch không có bản dịch của thuật ngữ đó.

### I18N-B-07: Medium. Bản en lẫn tiếng Việt (105 dòng)
- Bằng chứng: "Click to leave this chiến đội", "Divine Nguyên Đan Selection Box", "#GVạn T…", "Kim Sí Linh Vũ".
- Nguyên nhân: thuật ngữ được thay từ cột vi sang en.
- Đề xuất sửa: thêm lint "en không được có dấu tiếng Việt" và dịch lại 105 dòng (chiến đội → squad, theo glossary).

### I18N-B-08: Medium. Dịch sai hoặc dịch máy móc trong mẫu
Trong 300 mẫu soát tay, khoảng 92% đạt, khoảng 6% gượng hoặc lệch kiểu, và khoảng 2% sai nghĩa. Một số ví dụ:
- 武林派对 → "Võ Lâm Phái Đối" (派对 là "party"), nơi khác lại là "Võ Lâm Party". Nên dịch thành "Tiệc Võ Lâm".
- 浑天仪 / 浑天璞石 → "Hồn Thiên…", đúng là "Hỗn Thiên Nghi" / "Hỗn Thiên Phác Thạch".
- 特殊道具 → en "Special Tool" ×5.463. 道具 trong game là vật phẩm, nên dịch là "Special Item".
- 刀组类 → "Blade Set" / "Đao Tổ": chưa rõ nghĩa, cần đối chiếu với loại vũ khí trong game.
- 第三方账号登录 → vi "Tài khoản khác:" (mất nghĩa "bên thứ ba").
- 4 tên trang bị lặp chữ nghĩa do ghép theo luật, ví dụ "Tân Thiết Tạo Anh Thương Đạt Ma": 镔铁 đọc là "Tân Thiết" thì đúng, nhưng thứ tự ghép đặt "Đạt Ma" ở cuối (xem B-03).
- Nguyên nhân: dịch theo lô lớn và ghép theo mẫu, không có bước soát lần hai.
- Đề xuất sửa: sửa các mục trên, rồi chạy soát lần hai theo nhóm tên có tần suất cao (`type_name` và tiền tố bộ).

### I18N-B-09: Low. Khoảng trắng đầu và cuối lệch so với zh (en 17, vi 16)
- Bằng chứng: các zh có dấu cách thừa ở cuối (`八列之舞 `, `上元清嘉景 ` ×~10) bị bỏ ở bản dịch. Bản dịch làm vậy là đúng, nên đây là dấu cách thừa trong dữ liệu gốc. `CHAR_SEL_DELETE_HEAD/TAIL` có dấu cách được thêm có chủ ý, vì zh không cần dấu cách giữa các từ. Thụt đầu dòng 4 dấu cách của đoạn mô tả được giữ đúng.
- Đề xuất sửa: không cần sửa bản dịch. Ghi vào lint như ngoại lệ đã biết, để lần sau khỏi bị báo lại.

### I18N-B-10: Low. en thiếu 2 khoá `file/` mà zh và vi có
- Bằng chứng: `file/Table/login_servers.tsv` và `file/Web/coming_soon.html` có trong zh và vi, nhưng không có trong en. Khi dựng `GAME_LANGUAGE=en`, build_i18n sẽ xoá các tệp đã chép ở lượt dựng trước (sổ `files.tsv`), nên danh sách máy chủ và trang coming soon sẽ quay về bản gốc tiếng Trung hoặc không còn tệp.
- Đề xuất sửa: thêm `assets/i18n/en/table/login_servers.tsv` và `en/web/coming_soon.html` cùng hai khoá này. Kiểm lại dữ liệu gốc khi các tệp đó vắng mặt.

### I18N-B-11: Low. Dữ liệu chữ giả (placeholder) và "未使用" được dịch thành tên thật
- Bằng chứng: rất nhiều `equips/*/name = 未使用` được dịch thành "Unused" / "Chưa Dùng". Đây là các dòng dự trữ, nếu lộ ra thì người chơi thấy một món tên "Chưa Dùng".
- Đề xuất sửa: không có tác dụng khi chưa có nơi đọc bảng (B-02). Khi nối dây thì nên lọc các dòng dự trữ ở logic, không lọc trong bản dịch.

### I18N-B-12: Info. Thiết kế fallback đúng, nhưng thiếu kiểm khi bảng bị xuất lại
- Bằng chứng: `localize()` bỏ qua id hay cột không tồn tại (đếm vào `missed`), không ghi vào cột khoá, gặp id lặp thì lấy dòng đầu, và bản dịch hỏng thì giữ nguyên bảng gốc. `localize_table()` chỉ in một dòng stderr. Cách làm này an toàn.
- Rủi ro: khi `export_config.py` xuất lại và đổi id, bản dịch mất âm thầm, chỉ để lại một dòng log. Ngoài ra khoá `table/` không mang băm của chữ zh gốc, nên khi chữ gốc đổi thì bản dịch cũ không bị phát hiện là cũ.
- Đề xuất sửa: cho build_i18n tuỳ chọn `--check-tables`, đối chiếu id, cột và chữ zh của khoá `table/` với `Table/<bảng>.tsv`, và báo lỗi khi lệch. Kiểm tra này đã được chạy thủ công trong audit (0 lệch), giờ cần đưa vào CI.

### I18N-B-13: Info. Vệ sinh mã và dữ liệu tạm
- `C:\tlx` và `build\i18n_extract` có hơn 60 script một lần (a.py…w.py, b1…b33.txt), cùng khoảng 20 thư mục sao lưu và `*.truoc-*` tạm ngay trong `build/`. Tên không gợi ý nội dung và nằm ngoài kho mã, nên không lặp lại được quy trình. `src/shared/table/localize.*`, `Test/Shared/table_localize_tests.cpp` và `TOOLS/tsv_lint.py` vẫn **untracked** trong git.
- Đề xuất sửa: đưa các bước cần lặp lại (extract, kiểm thẻ, kiểm glossary, đổi Hán Việt) vào `TOOLS/content/i18n_*.py` có test, còn lại thì xoá. `git add` các tệp mới. Gom sao lưu về một thư mục có ngày.

## Ưu tiên sửa
1. B-01 và B-02 (nối dây client, kèm test tích hợp). Chưa làm xong hai mục này thì người dùng không thấy bất kỳ bản dịch nào.
2. B-06 (gộp glossary và chốt 坐骑) → B-03 + B-04 + B-05 (sinh lại tên tiếng Việt bằng một luật duy nhất).
3. B-07, B-08, B-10, rồi đưa các kiểm tra ở B-12 và B-13 vào lint/CI.
