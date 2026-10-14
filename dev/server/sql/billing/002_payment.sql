-- Đơn nạp tiền. Khoá tự nhiên (provider, trade_no) là chỗ chặn nạp hai lần khi nhà cung cấp gọi lại
-- webhook: dòng thứ hai cùng khoá không thể tồn tại, nên phép cộng điểm đi sau không thể chạy hai lần.
BEGIN;

CREATE TABLE payment (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    provider text NOT NULL,
    trade_no text NOT NULL,
    account_id bigint NOT NULL REFERENCES billing_account (account_id),
    -- Điểm (phần mười) mà đơn cộng khi trả xong.
    points bigint NOT NULL,
    -- Số tiền nhà cung cấp thu, đơn vị nhỏ nhất của tiền tệ; chỉ để đối chiếu.
    amount_minor bigint NOT NULL,
    currency text NOT NULL,
    status text NOT NULL,
    created_at bigint NOT NULL,
    updated_at bigint NOT NULL,
    CONSTRAINT payment_key UNIQUE (provider, trade_no),
    CONSTRAINT payment_status CHECK (status IN ('pending', 'paid', 'failed', 'refunded')),
    CONSTRAINT payment_points CHECK (points >= 1),
    CONSTRAINT payment_amount CHECK (amount_minor >= 0),
    CONSTRAINT payment_currency CHECK (currency ~ '^[A-Z]{3}$'),
    CONSTRAINT payment_provider CHECK (provider ~ '^[A-Za-z0-9_.-]{1,32}$'),
    CONSTRAINT payment_trade_no CHECK (trade_no ~ '^[A-Za-z0-9_.-]{1,64}$'),
    CONSTRAINT payment_times CHECK (created_at >= 0 AND updated_at >= 0)
);

CREATE INDEX payment_account ON payment (account_id, id DESC);

INSERT INTO schema_version (version) VALUES (2) ON CONFLICT DO NOTHING;

COMMIT;
