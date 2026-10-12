-- Trần đăng nhập theo IP dùng cột ip đã có. Không đổi dữ liệu cũ.
BEGIN;
CREATE INDEX IF NOT EXISTS login_attempt_ip_at ON login_attempt (ip, at DESC);
INSERT INTO schema_version (version) VALUES (2) ON CONFLICT DO NOTHING;
COMMIT;
