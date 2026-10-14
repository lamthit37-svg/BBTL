-- Sổ điểm nạp của billing: tài khoản, số dư (bản nhớ đệm) và sổ chỉ ghi thêm.
-- Tiền là số nguyên: điểm nạp tính theo phần mười điểm (10 = 1,0 điểm, như client 2026 hiển thị), ingot là
-- số đếm. Mọi cột *_at là giây Unix UTC (bigint) do bên gọi đưa vào, không phải timestamptz, để test
-- điều khiển được thời gian và đối soát ngày cắt đúng ranh giới ngày UTC.
-- Số dư thật của một tài khoản là tổng delta trong point_ledger; point_balance chỉ là bản nhớ đệm và
-- ledger_check/rebuild_balance của billing kiểm và dựng lại nó từ sổ.
BEGIN;

CREATE TABLE IF NOT EXISTS schema_version (
    version integer PRIMARY KEY,
    applied_at timestamptz NOT NULL DEFAULT now()
);

-- Id tài khoản do auth cấp (database khác), nên không có khoá ngoại tới đó. 2^62 là trần id của billing.
CREATE TABLE billing_account (
    account_id bigint PRIMARY KEY,
    frozen boolean NOT NULL DEFAULT false,
    created_at bigint NOT NULL,
    CONSTRAINT billing_account_id_range CHECK (account_id BETWEEN 1 AND 4611686018427387904),
    CONSTRAINT billing_account_created CHECK (created_at >= 0)
);

CREATE TABLE point_balance (
    account_id bigint PRIMARY KEY REFERENCES billing_account (account_id),
    points bigint NOT NULL,
    updated_at bigint NOT NULL,
    CONSTRAINT point_balance_nonnegative CHECK (points >= 0)
);

CREATE TABLE point_ledger (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id bigint NOT NULL REFERENCES billing_account (account_id),
    delta bigint NOT NULL,
    kind text NOT NULL,
    -- Id của đơn, mã hay tài khoản mà dòng sổ thuộc về; 0 khi không có.
    ref_id bigint NOT NULL,
    reason text NOT NULL,
    actor text NOT NULL,
    at bigint NOT NULL,
    CONSTRAINT point_ledger_kind CHECK (kind IN
        ('top_up', 'refund', 'exchange_hold', 'exchange_release', 'register_gift', 'redeem', 'admin')),
    CONSTRAINT point_ledger_delta_sign CHECK (
        delta <> 0 AND
        CASE kind
            WHEN 'top_up' THEN delta > 0
            WHEN 'refund' THEN delta < 0
            WHEN 'exchange_hold' THEN delta < 0
            WHEN 'exchange_release' THEN delta > 0
            WHEN 'register_gift' THEN delta > 0
            WHEN 'redeem' THEN delta > 0
            ELSE true
        END),
    CONSTRAINT point_ledger_ref CHECK (ref_id >= 0),
    CONSTRAINT point_ledger_reason_len CHECK (octet_length(reason) BETWEEN 1 AND 200),
    CONSTRAINT point_ledger_actor_len CHECK (octet_length(actor) BETWEEN 1 AND 64),
    CONSTRAINT point_ledger_at CHECK (at >= 0)
);

-- Khoá lặp lại: mỗi (loại, id) chỉ có một dòng. Đây là chỗ đảm bảo nạp hai lần, hoàn hai lần, giữ điểm
-- hai lần cho cùng một đơn không thể cộng hay trừ hai lần dù mã phía trên sai.
CREATE UNIQUE INDEX point_ledger_key ON point_ledger (kind, ref_id) WHERE ref_id <> 0;
CREATE INDEX point_ledger_account ON point_ledger (account_id, id DESC);
CREATE INDEX point_ledger_at ON point_ledger (at);

-- Sổ chỉ ghi thêm do chính database giữ: sửa hay xoá một dòng, hay TRUNCATE, đều bị từ chối.
CREATE FUNCTION point_ledger_append_only() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'point_ledger là sổ chỉ ghi thêm' USING ERRCODE = 'integrity_constraint_violation';
END
$$;

CREATE TRIGGER point_ledger_no_change BEFORE UPDATE OR DELETE ON point_ledger
    FOR EACH ROW EXECUTE FUNCTION point_ledger_append_only();
CREATE TRIGGER point_ledger_no_truncate BEFORE TRUNCATE ON point_ledger
    FOR EACH STATEMENT EXECUTE FUNCTION point_ledger_append_only();

INSERT INTO schema_version (version) VALUES (1) ON CONFLICT DO NOTHING;

COMMIT;
