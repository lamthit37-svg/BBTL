-- Tài khoản, vé đăng nhập và lần thử. Id là bigint để không kẹt ở 32 bit khi cụm chạy lâu.
-- Mật khẩu chỉ là chuỗi Argon2id. Vé lưu SHA-256 của 32 byte ngẫu nhiên, không lưu vé thô.
BEGIN;

CREATE TABLE IF NOT EXISTS schema_version (
    version integer PRIMARY KEY,
    applied_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS account (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL,
    name_fold text NOT NULL,
    password_hash text NOT NULL,
    ops_limit integer NOT NULL,
    mem_limit_kib integer NOT NULL,
    gift_points bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    disabled_at timestamptz,
    CONSTRAINT account_name_fold UNIQUE (name_fold),
    CONSTRAINT account_gift_nonnegative CHECK (gift_points >= 0),
    CONSTRAINT account_name_len CHECK (octet_length(name) BETWEEN 4 AND 32)
);

CREATE TABLE IF NOT EXISTS login_attempt (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id bigint REFERENCES account (id),
    name_fold text NOT NULL,
    ip inet NOT NULL,
    ok boolean NOT NULL,
    at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS login_attempt_name_at ON login_attempt (name_fold, at DESC);

CREATE TABLE IF NOT EXISTS ticket (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id bigint NOT NULL REFERENCES account (id),
    token_hash text NOT NULL,
    expires_at timestamptz NOT NULL,
    used_at timestamptz,
    CONSTRAINT ticket_token_hash UNIQUE (token_hash)
);

CREATE INDEX IF NOT EXISTS ticket_expires ON ticket (expires_at);

CREATE TABLE IF NOT EXISTS ban (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id bigint NOT NULL REFERENCES account (id),
    reason text NOT NULL,
    until_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS audit_event (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id bigint,
    kind text NOT NULL,
    detail text NOT NULL DEFAULT '',
    at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO schema_version (version) VALUES (1) ON CONFLICT DO NOTHING;

COMMIT;
