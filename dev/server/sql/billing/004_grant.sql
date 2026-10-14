-- Quà và mã đổi. Đợt (reward_batch) có các khoản thưởng (batch_reward) và các mã (redeem_code); mã chỉ lưu
-- SHA-256 của chữ chuẩn hoá nên đọc được database cũng không dùng được mã. Mỗi lần đổi ghi một dòng
-- redeem_log. Quà (reward_grant) chờ phát cho nhân vật qua hai pha (grant_order) giống đơn đổi ingot.
-- "grant" là từ khoá SQL nên bảng quà tên reward_grant.
BEGIN;

CREATE TABLE reward_batch (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL,
    starts_at bigint,
    ends_at bigint,
    per_account_limit integer NOT NULL,
    enabled boolean NOT NULL DEFAULT true,
    actor text NOT NULL,
    created_at bigint NOT NULL,
    CONSTRAINT reward_batch_name UNIQUE (name),
    CONSTRAINT reward_batch_name_len CHECK (octet_length(name) BETWEEN 1 AND 64),
    CONSTRAINT reward_batch_window CHECK (starts_at IS NULL OR ends_at IS NULL OR starts_at <= ends_at),
    CONSTRAINT reward_batch_limit CHECK (per_account_limit BETWEEN 1 AND 1000),
    CONSTRAINT reward_batch_actor_len CHECK (octet_length(actor) BETWEEN 1 AND 64)
);

-- kind 0 là điểm nạp (phần mười), còn lại là loại quà (1 vàng, 5 ingot, 6 điểm tặng, 8 giao tử, 100 vật phẩm).
CREATE TABLE batch_reward (
    batch_id bigint NOT NULL REFERENCES reward_batch (id),
    seq smallint NOT NULL,
    kind smallint NOT NULL,
    ref_id bigint NOT NULL,
    quantity bigint NOT NULL,
    PRIMARY KEY (batch_id, seq),
    CONSTRAINT batch_reward_seq CHECK (seq BETWEEN 0 AND 15),
    CONSTRAINT batch_reward_kind CHECK (kind IN (0, 1, 5, 6, 8, 100)),
    CONSTRAINT batch_reward_quantity CHECK (quantity >= 1),
    CONSTRAINT batch_reward_ref CHECK (CASE WHEN kind = 100 THEN ref_id >= 1 ELSE ref_id = 0 END)
);

CREATE TABLE redeem_code (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id bigint NOT NULL REFERENCES reward_batch (id),
    code_hash text NOT NULL,
    used_by bigint,
    used_at bigint,
    CONSTRAINT redeem_code_hash UNIQUE (code_hash),
    CONSTRAINT redeem_code_hash_form CHECK (code_hash ~ '^[0-9a-f]{64}$'),
    CONSTRAINT redeem_code_used CHECK ((used_by IS NULL) = (used_at IS NULL))
);

CREATE INDEX redeem_code_batch ON redeem_code (batch_id);
CREATE INDEX redeem_code_user ON redeem_code (used_by, batch_id) WHERE used_by IS NOT NULL;

CREATE TABLE redeem_log (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code_id bigint NOT NULL REFERENCES redeem_code (id),
    account_id bigint NOT NULL REFERENCES billing_account (account_id),
    ip inet NOT NULL,
    at bigint NOT NULL
);

CREATE INDEX redeem_log_account ON redeem_log (account_id, id DESC);

CREATE TABLE reward_grant (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id bigint NOT NULL REFERENCES billing_account (account_id),
    kind text NOT NULL,
    ref_id bigint NOT NULL,
    quantity bigint NOT NULL,
    status text NOT NULL,
    source text NOT NULL,
    reason text NOT NULL,
    actor text NOT NULL,
    created_at bigint NOT NULL,
    updated_at bigint NOT NULL,
    CONSTRAINT reward_grant_kind CHECK (kind IN ('coin', 'ingot', 'bonus_point', 'bound_coin', 'item')),
    CONSTRAINT reward_grant_status CHECK (status IN ('pending', 'delivering', 'delivered', 'void')),
    CONSTRAINT reward_grant_quantity CHECK (quantity >= 1),
    CONSTRAINT reward_grant_ref CHECK (CASE WHEN kind = 'item' THEN ref_id >= 1 ELSE ref_id = 0 END),
    CONSTRAINT reward_grant_source_len CHECK (octet_length(source) BETWEEN 1 AND 16),
    CONSTRAINT reward_grant_times CHECK (created_at >= 0 AND updated_at >= 0)
);

CREATE INDEX reward_grant_account ON reward_grant (account_id, id) WHERE status = 'pending';

CREATE TABLE grant_order (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    grant_id bigint NOT NULL REFERENCES reward_grant (id),
    character_id bigint NOT NULL,
    status text NOT NULL,
    created_at bigint NOT NULL,
    updated_at bigint NOT NULL,
    CONSTRAINT grant_order_status CHECK (status IN ('pending', 'done', 'cancelled')),
    CONSTRAINT grant_order_character CHECK (character_id >= 1),
    CONSTRAINT grant_order_times CHECK (created_at >= 0 AND updated_at >= 0)
);

-- Một quà chỉ có một đơn giao đang mở: giao hai lần cùng một quà không thể xảy ra.
CREATE UNIQUE INDEX grant_order_one_open ON grant_order (grant_id) WHERE status = 'pending';
CREATE INDEX grant_order_open ON grant_order (created_at, id) WHERE status = 'pending';

INSERT INTO schema_version (version) VALUES (4) ON CONFLICT DO NOTHING;

COMMIT;
