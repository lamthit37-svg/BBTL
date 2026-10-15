-- Trạng thái chơi của nhân vật mà zone giữ trong bộ nhớ và ghi định kỳ: thân thể (actor::Record), sổ nhiệm vụ
-- (mission::Book) và túi tạm (khối nhị phân có phiên bản, bộ giải mã kiểm từng byte). Cột NULL là nhân vật chưa
-- từng vào game từ bản này: zone dựng mới từ cấp, kinh nghiệm, tiền của các cột có sẵn. Cột level, exp, hp, mp,
-- money, bound_coin vẫn được ghi cùng để danh sách nhân vật và công cụ quản trị đọc không cần giải khối.
BEGIN;

ALTER TABLE player ADD COLUMN IF NOT EXISTS body bytea;
ALTER TABLE player ADD COLUMN IF NOT EXISTS mission bytea;
ALTER TABLE player ADD COLUMN IF NOT EXISTS bag bytea;

INSERT INTO schema_version (version) VALUES (2) ON CONFLICT DO NOTHING;

COMMIT;
