-- Schema for the slot-platform project. Generated from pg_dump
-- --schema-only on local PostgreSQL 16; comments quoted verbatim
-- from the dataset author's documentation.

DROP TABLE IF EXISTS spins, sessions, players;

CREATE TABLE players (
    player_id           bigint PRIMARY KEY,
    signup_ts           timestamp,
    country             text,
    acquisition_channel text,
    device_pref         text,
    os                  text
);

CREATE TABLE sessions (
    session_id     bigint PRIMARY KEY,
    player_id      bigint,
    start_ts       timestamp,
    end_ts         timestamp,
    duration_sec   integer,
    device_id_hash text,
    ip_hash        text,
    ip_country     text,
    geo_mismatch   boolean,
    num_spins      integer,
    avg_bet        numeric,
    max_bet        numeric,
    spins_per_min  numeric
);

CREATE TABLE spins (
    spin_id         bigint PRIMARY KEY,
    session_id      bigint,
    player_id       bigint,
    ts              timestamp,
    slot_id         text,
    slot_volatility text,
    bet_amount      numeric,
    win_amount      numeric,
    feature_buy     boolean
);

COMMENT ON COLUMN players.player_id           IS 'Unique player identifier';
COMMENT ON COLUMN players.signup_ts           IS 'Signup timestamp';
COMMENT ON COLUMN players.country             IS 'Player-declared country';
COMMENT ON COLUMN players.acquisition_channel IS 'Marketing channel (affiliate / paid_search / paid_social / organic / referral)';
COMMENT ON COLUMN players.device_pref         IS 'Preferred device type (mobile / desktop)';
COMMENT ON COLUMN players.os                  IS 'Operating system, consistent with device type';

COMMENT ON COLUMN sessions.session_id     IS 'Unique session identifier';
COMMENT ON COLUMN sessions.player_id      IS 'FK to players';
COMMENT ON COLUMN sessions.start_ts       IS 'Session start time';
COMMENT ON COLUMN sessions.end_ts         IS 'Session end time';
COMMENT ON COLUMN sessions.duration_sec   IS 'Session duration in seconds';
COMMENT ON COLUMN sessions.device_id_hash IS 'Hashed device identifier';
COMMENT ON COLUMN sessions.ip_hash        IS 'Hashed IP identifier';
COMMENT ON COLUMN sessions.ip_country     IS 'Country inferred from IP';
COMMENT ON COLUMN sessions.geo_mismatch   IS '1 if ip_country differs from the player''s declared country';
COMMENT ON COLUMN sessions.num_spins      IS 'Number of spins in the session';
COMMENT ON COLUMN sessions.avg_bet        IS 'Mean bet amount in the session';
COMMENT ON COLUMN sessions.max_bet        IS 'Max bet amount in the session';
COMMENT ON COLUMN sessions.spins_per_min  IS 'num_spins / (duration_sec / 60)';

COMMENT ON COLUMN spins.spin_id         IS 'Unique spin identifier';
COMMENT ON COLUMN spins.session_id      IS 'FK to sessions';
COMMENT ON COLUMN spins.player_id       IS 'FK to players';
COMMENT ON COLUMN spins.ts              IS 'Spin timestamp';
COMMENT ON COLUMN spins.slot_id         IS 'Slot identifier (slot_001–slot_060)';
COMMENT ON COLUMN spins.slot_volatility IS 'Per-slot category: low / med / high';
COMMENT ON COLUMN spins.bet_amount      IS 'Spin bet';
COMMENT ON COLUMN spins.win_amount      IS 'Spin win';
COMMENT ON COLUMN spins.feature_buy     IS '1 if the spin represents a "feature buy" style bet spike';
