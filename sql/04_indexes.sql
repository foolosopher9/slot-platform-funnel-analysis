-- Secondary indexes for analytical queries.
--
-- Primary keys (spins_pkey, sessions_pkey, players_pkey) are created in
-- 01b_constraints.sql and cover lookups by the parent id.
--
-- These indexes cover the additional access patterns typical for slot /
-- iGaming analytics:
--   * activation funnel:  players with / without any spins
--   * cohorts:            players grouped by signup week
--   * GGR by channel:     joins from spins to players
--   * time series:        spins within a date window
--   * session metrics:    sessions per player, sessions within a window
--   * feature-buy:        rare event, indexed with a partial index

-- spins -> players (activation, GGR by player)
CREATE INDEX idx_spins_player_id ON spins (player_id);

-- spins -> sessions (session-level aggregations)
CREATE INDEX idx_spins_session_id ON spins (session_id);

-- spins within a time window (daily / weekly GGR, time series)
CREATE INDEX idx_spins_ts ON spins (ts);

-- sessions -> players (sessions per player)
CREATE INDEX idx_sessions_player_id ON sessions (player_id);

-- sessions within a time window (activity by period)
CREATE INDEX idx_sessions_start_ts ON sessions (start_ts);

-- players grouped by signup week (cohort retention)
CREATE INDEX idx_players_signup_ts ON players (signup_ts);

-- players grouped by acquisition channel (channel-level GGR, activation)
CREATE INDEX idx_players_acq_channel ON players (acquisition_channel);

-- rare event: only the rows where feature_buy = true are indexed
CREATE INDEX idx_spins_feature_buy_player
    ON spins (player_id)
    WHERE feature_buy = true;

-- Refresh planner statistics after index creation
ANALYZE public.players;
ANALYZE public.sessions;
ANALYZE public.spins;
