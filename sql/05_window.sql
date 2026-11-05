/* Observation window: sessions per player within 90 days after signup and the active player threshold, report section 2.4 */


WITH window_sessions AS (
  SELECT
    players.player_id,
    COUNT(sessions.session_id) AS sessions_count
  FROM players
  LEFT JOIN sessions
    ON players.player_id = sessions.player_id
    AND sessions.start_ts < players.signup_ts + INTERVAL '90 days'
  GROUP BY players.player_id
)
SELECT
  COUNT(window_sessions.player_id) AS players,
  ROUND(100.0 * COUNT(window_sessions.player_id) FILTER (WHERE window_sessions.sessions_count = 0) / COUNT(window_sessions.player_id), 1) AS zero_sessions_pct,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY window_sessions.sessions_count) AS median_sessions,
  ROUND(100.0 * COUNT(window_sessions.player_id) FILTER (WHERE window_sessions.sessions_count >= 3) / COUNT(window_sessions.player_id), 1) AS sessions_3plus_pct
FROM window_sessions;
