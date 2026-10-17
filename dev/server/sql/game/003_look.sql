-- Ảnh chân dung và bộ đồ tân thủ mà người chơi chọn lúc tạo nhân vật (G1-M D3). Gốc ghi ảnh chân dung
-- ở 0x48 của bản ghi danh sách 0x1a4, riêng với kiểu mặt (0x3c): màn tạo 2026 chọn chúng độc lập. Nhân vật
-- tạo trước bản này không có lựa chọn nào để lấy lại, nên cho ảnh đầu tiên của giới (nữ 49, nam 52 trong
-- portraits.tsv) và bộ đồ 0; id nằm trong danh sách tạo được của store.toml nên Enter vẫn hợp lệ.
BEGIN;

ALTER TABLE player ADD COLUMN IF NOT EXISTS portrait integer NOT NULL DEFAULT 0;
ALTER TABLE player ADD COLUMN IF NOT EXISTS equip_set integer NOT NULL DEFAULT 0;

UPDATE player SET portrait = CASE gender WHEN 1 THEN 49 ELSE 52 END WHERE portrait = 0;

ALTER TABLE player ADD CONSTRAINT player_portrait CHECK (portrait BETWEEN 0 AND 65535);
ALTER TABLE player ADD CONSTRAINT player_equip_set CHECK (equip_set BETWEEN 0 AND 65535);

INSERT INTO schema_version (version) VALUES (3) ON CONFLICT DO NOTHING;

COMMIT;
