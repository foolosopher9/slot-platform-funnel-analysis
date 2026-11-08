/* Player metrics within 90 days after signup: base for questions 1–5, report chapters 3–4 */
/* Window rules from report section 2.4: sessions by start_ts, spins by ts */


/* One row per player, all 8 000 players; players without sessions get zeros */
CREATE OR REPLACE VIEW player_window_metrics AS
WITH window_sessions AS (
  SELECT
    sessions.player_id,
    COUNT(sessions.session_id) AS sessions_count,
    COUNT(sessions.session_id) FILTER (WHERE sessions.geo_mismatch) AS mismatch_sessions
  FROM sessions
  JOIN players
    ON sessions.player_id = players.player_id
    AND sessions.start_ts < players.signup_ts + INTERVAL '90 days'
  GROUP BY sessions.player_id
),
window_spins AS (
  SELECT
    spins.player_id,
    SUM(spins.bet_amount) AS turnover,
    SUM(spins.bet_amount) FILTER (WHERE NOT spins.feature_buy) AS turnover_no_spikes
  FROM spins
  JOIN players
    ON spins.player_id = players.player_id
    AND spins.ts < players.signup_ts + INTERVAL '90 days'
  GROUP BY spins.player_id
)
SELECT
  players.player_id,
  players.acquisition_channel,
  players.country,
  COALESCE(window_sessions.sessions_count, 0) AS sessions_count,
  COALESCE(window_sessions.mismatch_sessions, 0) AS mismatch_sessions,
  COALESCE(window_spins.turnover, 0) AS turnover,
  COALESCE(window_spins.turnover_no_spikes, 0) AS turnover_no_spikes
FROM players
LEFT JOIN window_sessions
  ON players.player_id = window_sessions.player_id
LEFT JOIN window_spins
  ON players.player_id = window_spins.player_id;


/* Check against chapter 2: 8 000 players, 39 902 sessions, 1 428 mismatch sessions, zero_sessions_pct as in 06_window.sql */
SELECT
  COUNT(player_window_metrics.player_id) AS players,
  SUM(player_window_metrics.sessions_count) AS sessions,
  SUM(player_window_metrics.mismatch_sessions) AS mismatch_sessions,
  ROUND(100.0 * COUNT(player_window_metrics.player_id) FILTER (WHERE player_window_metrics.sessions_count = 0) / COUNT(player_window_metrics.player_id), 1) AS zero_sessions_pct,
  COUNT(player_window_metrics.player_id) FILTER (
    WHERE player_window_metrics.sessions_count > 0
      AND player_window_metrics.turnover = 0
  ) AS playing_without_turnover
FROM player_window_metrics;


/* Window edge: spins after day 90 inside sessions that started before day 90 */
SELECT
  COUNT(*) AS edge_spins,
  COUNT(DISTINCT spins.player_id) AS edge_players
FROM spins
JOIN sessions
  ON spins.session_id = sessions.session_id
JOIN players
  ON spins.player_id = players.player_id
WHERE sessions.start_ts < players.signup_ts + INTERVAL '90 days'
  AND spins.ts >= players.signup_ts + INTERVAL '90 days';


/* Window coverage: share of all sessions, spins and turnover that fall inside the 90-day window */
SELECT
  COUNT(*) FILTER (WHERE sessions.start_ts < players.signup_ts + INTERVAL '90 days') AS window_sessions,
  COUNT(*) AS all_sessions,
  ROUND(100.0 * COUNT(*) FILTER (WHERE sessions.start_ts < players.signup_ts + INTERVAL '90 days') / COUNT(*), 1) AS window_sessions_pct
FROM sessions
JOIN players
  ON sessions.player_id = players.player_id;

SELECT
  COUNT(*) FILTER (WHERE spins.ts < players.signup_ts + INTERVAL '90 days') AS window_spins,
  COUNT(*) AS all_spins,
  ROUND(100.0 * COUNT(*) FILTER (WHERE spins.ts < players.signup_ts + INTERVAL '90 days') / COUNT(*), 1) AS window_spins_pct,
  ROUND(100.0 * SUM(spins.bet_amount) FILTER (WHERE spins.ts < players.signup_ts + INTERVAL '90 days') / SUM(spins.bet_amount), 1) AS window_turnover_pct
FROM spins
JOIN players
  ON spins.player_id = players.player_id;
