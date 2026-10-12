-- Nhân vật và đồ của một thế giới. Cột tra cứu là cột; kỹ năng, công thức và vật phẩm là dòng
-- con với id bigint vì client 2026 có nhiều id hơn bản 0.85 (bảng gốc nhồi blob t_char, t_iteminfo).
-- Tiền là bigint, không âm. Toạ độ là centimet của OGRE, số thực chỉ cho vị trí.
BEGIN;

CREATE TABLE IF NOT EXISTS schema_version (
    version integer PRIMARY KEY,
    applied_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS player (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id bigint NOT NULL,
    name text NOT NULL,
    name_fold text NOT NULL,
    gender smallint NOT NULL,
    face integer NOT NULL,
    hair integer NOT NULL,
    school integer NOT NULL,
    level integer NOT NULL,
    exp bigint NOT NULL,
    scene integer NOT NULL,
    position_x double precision NOT NULL,
    position_z double precision NOT NULL,
    hp integer NOT NULL,
    mp integer NOT NULL,
    camp integer NOT NULL,
    money bigint NOT NULL,
    bound_coin bigint NOT NULL DEFAULT 0,
    ingot bigint NOT NULL DEFAULT 0,
    bonus_point bigint NOT NULL DEFAULT 0,
    vigor integer NOT NULL,
    max_vigor integer NOT NULL,
    energy integer NOT NULL,
    max_energy integer NOT NULL,
    strength integer NOT NULL,
    spirit integer NOT NULL,
    constitution integer NOT NULL,
    intellect integer NOT NULL,
    dexterity integer NOT NULL,
    actual_age integer NOT NULL,
    motto text NOT NULL DEFAULT '',
    created_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz,
    CONSTRAINT player_gender CHECK (gender IN (1, 2)),
    CONSTRAINT player_face CHECK (face BETWEEN 0 AND 65535),
    CONSTRAINT player_hair CHECK (hair BETWEEN 0 AND 65535),
    CONSTRAINT player_school CHECK (school BETWEEN 0 AND 255),
    CONSTRAINT player_level CHECK (level BETWEEN 1 AND 10000),
    CONSTRAINT player_scene CHECK (scene BETWEEN 0 AND 65535),
    CONSTRAINT player_exp_nonnegative CHECK (exp >= 0),
    CONSTRAINT player_hp_nonnegative CHECK (hp >= 0),
    CONSTRAINT player_mp_nonnegative CHECK (mp >= 0),
    CONSTRAINT player_money_nonnegative CHECK (money >= 0),
    CONSTRAINT player_bound_nonnegative CHECK (bound_coin >= 0),
    CONSTRAINT player_ingot_nonnegative CHECK (ingot >= 0),
    CONSTRAINT player_bonus_nonnegative CHECK (bonus_point >= 0),
    CONSTRAINT player_name_len CHECK (octet_length(name) BETWEEN 1 AND 48)
);

CREATE UNIQUE INDEX IF NOT EXISTS player_name_live ON player (name_fold) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS player_account_live ON player (account_id) WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS player_skill (
    player_id bigint NOT NULL REFERENCES player (id),
    slot integer NOT NULL,
    skill_id bigint NOT NULL,
    PRIMARY KEY (player_id, slot),
    CONSTRAINT player_skill_slot CHECK (slot >= 0)
);

CREATE TABLE IF NOT EXISTS player_life_skill (
    player_id bigint NOT NULL REFERENCES player (id),
    skill_id bigint NOT NULL,
    level integer NOT NULL,
    exp bigint NOT NULL,
    PRIMARY KEY (player_id, skill_id),
    CONSTRAINT player_life_level CHECK (level >= 1),
    CONSTRAINT player_life_exp CHECK (exp >= 0)
);

CREATE TABLE IF NOT EXISTS player_recipe (
    player_id bigint NOT NULL REFERENCES player (id),
    recipe_id bigint NOT NULL,
    PRIMARY KEY (player_id, recipe_id)
);

CREATE TABLE IF NOT EXISTS player_setting (
    player_id bigint NOT NULL REFERENCES player (id),
    slot_index integer NOT NULL,
    kind integer NOT NULL,
    data bigint NOT NULL,
    PRIMARY KEY (player_id, slot_index)
);

CREATE TABLE IF NOT EXISTS item (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    player_id bigint NOT NULL REFERENCES player (id),
    container integer NOT NULL,
    slot integer NOT NULL,
    template_id bigint NOT NULL,
    count integer NOT NULL,
    bound boolean NOT NULL DEFAULT false,
    extra bytea NOT NULL DEFAULT '\x'::bytea,
    CONSTRAINT item_slot UNIQUE (player_id, container, slot),
    CONSTRAINT item_slot_nonnegative CHECK (slot >= 0),
    CONSTRAINT item_template_nonnegative CHECK (template_id >= 0),
    CONSTRAINT item_count_positive CHECK (count > 0)
);

INSERT INTO schema_version (version) VALUES (1) ON CONFLICT DO NOTHING;

COMMIT;
