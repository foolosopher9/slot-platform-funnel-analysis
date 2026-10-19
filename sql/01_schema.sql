DROP TABLE IF EXISTS spins CASCADE;
DROP TABLE IF EXISTS sessions CASCADE;
DROP TABLE IF EXISTS players CASCADE;

CREATE TABLE public.players (
    player_id bigint NOT NULL,
    signup_ts timestamp without time zone,
    country text,
    acquisition_channel text,
    device_pref text,
    os text
);

CREATE TABLE public.sessions (
    session_id bigint NOT NULL,
    player_id bigint,
    start_ts timestamp without time zone,
    end_ts timestamp without time zone,
    duration_sec integer,
    device_id_hash text,
    ip_hash text,
    ip_country text,
    geo_mismatch boolean,
    num_spins integer,
    avg_bet numeric,
    max_bet numeric,
    spins_per_min numeric
);

CREATE TABLE public.spins (
    spin_id bigint NOT NULL,
    session_id bigint,
    player_id bigint,
    ts timestamp without time zone,
    slot_id text,
    slot_volatility text,
    bet_amount numeric,
    win_amount numeric,
    feature_buy boolean
);

COMMENT ON COLUMN public.players.player_id IS 'Unique player identifier';
COMMENT ON COLUMN public.players.signup_ts IS 'Signup timestamp';
COMMENT ON COLUMN public.players.country IS 'Player-declared country';
COMMENT ON COLUMN public.players.acquisition_channel IS 'Marketing channel (affiliate / paid_search / paid_social / organic / referral)';
COMMENT ON COLUMN public.players.device_pref IS 'Preferred device type (mobile / desktop)';
COMMENT ON COLUMN public.players.os IS 'Operating system, consistent with device type';

COMMENT ON COLUMN public.sessions.session_id IS 'Unique session identifier';
COMMENT ON COLUMN public.sessions.player_id IS 'FK to players';
COMMENT ON COLUMN public.sessions.start_ts IS 'Session start time';
COMMENT ON COLUMN public.sessions.end_ts IS 'Session end time';
COMMENT ON COLUMN public.sessions.duration_sec IS 'Session duration in seconds';
COMMENT ON COLUMN public.sessions.device_id_hash IS 'Hashed device identifier';
COMMENT ON COLUMN public.sessions.ip_hash IS 'Hashed IP identifier';
COMMENT ON COLUMN public.sessions.ip_country IS 'Country inferred from IP';
COMMENT ON COLUMN public.sessions.geo_mismatch IS '1 if ip_country differs from the player''s declared country';
COMMENT ON COLUMN public.sessions.num_spins IS 'Number of spins in the session';
COMMENT ON COLUMN public.sessions.avg_bet IS 'Mean bet amount in the session';
COMMENT ON COLUMN public.sessions.max_bet IS 'Max bet amount in the session';
COMMENT ON COLUMN public.sessions.spins_per_min IS 'num_spins / (duration_sec / 60)';

COMMENT ON COLUMN public.spins.spin_id IS 'Unique spin identifier';
COMMENT ON COLUMN public.spins.session_id IS 'FK to sessions';
COMMENT ON COLUMN public.spins.player_id IS 'FK to players';
COMMENT ON COLUMN public.spins.ts IS 'Spin timestamp';
COMMENT ON COLUMN public.spins.slot_id IS 'Slot identifier (slot_001–slot_060)';
COMMENT ON COLUMN public.spins.slot_volatility IS 'Per-slot category: low / med / high';
COMMENT ON COLUMN public.spins.bet_amount IS 'Spin bet';
COMMENT ON COLUMN public.spins.win_amount IS 'Spin win';
COMMENT ON COLUMN public.spins.feature_buy IS '1 if the spin represents a "feature buy" style bet spike';
