# Hỏi đáp P1 đợt 3

## H1. `lint_names` và mẫu `{n}`

Mục 5.1 bắt `name` chứa cùng số `{n}` với `original`. `align_columns._term_name_ok` thay `{n}` bằng `1` rồi mới khớp `[a-z][a-z0-9_]*`. `lint_names._term_names` đưa nguyên `name` vào N2, nên 26 dòng mẫu trong `column_terms.tsv` bị `sai dạng tên`.

Đã thử thay `{n}` bằng `1` rồi chạy cùng luật N1: 0 tên cấm. Không sửa `lint_names.py`. Nhờ L coi `{n}` như `align_columns` trước khi kiểm N1 và N2.

Trả lời của L: đúng như đề nghị. `lint_names._filled_term` thay mỗi `{n}` bằng `1` rồi mới chạy N1 và N2. Dòng nguyên văn không có `{n}` vẫn được. Tên cột đã sinh và tên tệp đích không được chứa `{n}`.

## H2. Tên bảng `achievement_ability`

`ChengjiuAbility.txt` không có bản 0859602, ba cột int, 11 dòng. Cột 2 là `10, 7, 8, 9, 1, 2, 4, 5, 27, 28, 39`, đúng id kỹ năng sống trong `life_skills.tsv` (trồng, đào, hái thuốc, câu, nấu, luyện đan, đúc, may, dược lý, dưỡng sinh, và id 39). Phụ lục: ChengJiu là `achievement`, Ability là `life_skill`.

Tên đúng là `achievement_life_skill`. Không ghi ngoại lệ: token `ability` là tên sai, không phải từ được giữ. `table_names.tsv` không thuộc vai A, nên chưa đổi đích và chưa đổi tên tệp.

Trả lời của L: đã đổi đích trong `table_names.tsv` và đổi tên hai tệp `tables/shared` và `columns/shared` thành `achievement_life_skill.tsv`. Không ghi `name_exceptions.tsv`. Phụ lục không sửa.

## H3. Test đầu đợt của `refs/shared.tsv`

`test_table_refs.py` bắt `refs/shared.tsv` không có dòng dữ liệu. Mục 4 bắt tệp này có ít nhất 12 dòng. Đã ghi 25 dòng, không sửa test. Nhờ L bỏ hoặc thu assertion đó vào lúc tệp còn trống.

Trả lời của L: test không còn bắt số dòng bằng 0. Ba tệp phải còn là bảng soạn tay: có `# schema 1`, không có `# tool:`, và `read_ref_file` đọc được.
