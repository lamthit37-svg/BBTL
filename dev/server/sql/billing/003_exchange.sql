-- Đơn đổi điểm lấy ingot, hai pha. Pha một giữ điểm (một dòng sổ exchange_hold cùng giao dịch với dòng
-- này), pha hai chốt hoặc huỷ. Đơn quá hạn sang 'stale' chờ đối soát, điểm vẫn bị giữ: không bao giờ tự
-- hoàn, vì game có thể đã cộng ingot mà tin báo chưa tới.
-- Khoá lặp lại (account_id, request_id): world gọi lại sau khi mạng đứt không tạo đơn thứ hai.
BEGIN;

CREATE TABLE exchange_order (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id bigint NOT NULL REFERENCES billing_account (account_id),
    character_id bigint NOT NULL,
    request_id bigint NOT NULL,
    ingot bigint NOT NULL,
    -- Điểm (phần mười) đã giữ.
    points bigint NOT NULL,
    status text NOT NULL,
    created_at bigint NOT NULL,
    updated_at bigint NOT NULL,
    CONSTRAINT exchange_order_key UNIQUE (account_id, request_id),
    CONSTRAINT exchange_order_status CHECK (status IN ('pending', 'stale', 'confirmed', 'cancelled')),
    CONSTRAINT exchange_order_ingot CHECK (ingot >= 1),
    CONSTRAINT exchange_order_points CHECK (points >= 1),
    CONSTRAINT exchange_order_ids CHECK (character_id >= 1 AND request_id >= 1),
    CONSTRAINT exchange_order_times CHECK (created_at >= 0 AND updated_at >= 0)
);

-- Hàng đợi đối soát: chỉ đơn còn mở.
CREATE INDEX exchange_order_open ON exchange_order (created_at, id) WHERE status IN ('pending', 'stale');
CREATE INDEX exchange_order_account ON exchange_order (account_id, id DESC);

INSERT INTO schema_version (version) VALUES (3) ON CONFLICT DO NOTHING;

COMMIT;
