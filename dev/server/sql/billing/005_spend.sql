-- Lượt tiêu ingot zone báo về (nguồn của hạn mức tiêu mỗi ngày và đối soát ngày) và nhật ký thao tác
-- quản trị. event là số duy nhất do zone cấp: báo hai lần chỉ ghi một lần, cùng event khác nội dung là xung đột.
BEGIN;

CREATE TABLE spend_log (
    event bigint PRIMARY KEY,
    account_id bigint NOT NULL REFERENCES billing_account (account_id),
    character_id bigint NOT NULL,
    amount bigint NOT NULL,
    -- Ngày UTC (giây Unix / 86400) lúc billing nhận.
    day bigint NOT NULL,
    at bigint NOT NULL,
    CONSTRAINT spend_log_event CHECK (event >= 1),
    CONSTRAINT spend_log_amount CHECK (amount BETWEEN 1 AND 1000000000),
    CONSTRAINT spend_log_character CHECK (character_id >= 1),
    CONSTRAINT spend_log_day CHECK (day >= 0)
);

CREATE INDEX spend_log_character_day ON spend_log (character_id, day);
CREATE INDEX spend_log_day ON spend_log (day);

-- Mọi thao tác quản trị không đi qua point_ledger (đóng băng, tắt đợt mã, dựng lại số dư).
CREATE TABLE audit_event (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kind text NOT NULL,
    subject bigint NOT NULL,
    detail text NOT NULL,
    actor text NOT NULL,
    at bigint NOT NULL,
    CONSTRAINT audit_event_kind CHECK (kind IN ('freeze', 'unfreeze', 'batch_enable', 'batch_disable', 'rebuild_balance')),
    CONSTRAINT audit_event_actor_len CHECK (octet_length(actor) BETWEEN 1 AND 64)
);

CREATE INDEX audit_event_at ON audit_event (at);

INSERT INTO schema_version (version) VALUES (5) ON CONFLICT DO NOTHING;

COMMIT;
