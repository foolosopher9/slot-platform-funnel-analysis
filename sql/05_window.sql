/* Windows analysis for players' sessions and turnover within 30, 60, and 90 days after signup */


WITH windows(days) AS (
  VALUES (30), (60), (90)
),
window_sessions AS (
  SELECT
    windows.days,
    players.player_id,
    COUNT(sessions.session_id) AS sessions_count
  FROM players
  CROSS JOIN windows
  LEFT JOIN sessions
    ON players.player_id = sessions.player_id
    AND players.signup_ts + windows.days * INTERVAL '1 day' > sessions.start_ts
  GROUP BY players.player_id, windows.days
),
window_turnover AS (
  SELECT
    windows.days,
    players.player_id,
    COALESCE(SUM(spins.bet_amount), 0) AS turnover
  FROM players
  CROSS JOIN windows
  LEFT JOIN spins
    ON players.player_id = spins.player_id
    AND players.signup_ts + windows.days * INTERVAL '1 day' > spins.ts
  GROUP BY players.player_id, windows.days
  ),
window_info_per_player AS (
  SELECT
    window_sessions.days,
    window_sessions.player_id,
    window_sessions.sessions_count,
    window_turnover.turnover
  FROM window_sessions
  JOIN window_turnover
    ON window_sessions.player_id = window_turnover.player_id
    AND window_sessions.days = window_turnover.days
)
SELECT
  days,
  COUNT(player_id) AS players,
  ROUND(100.0 * COUNT(sessions_count) FILTER (WHERE sessions_count = 0) / COUNT(*), 1) AS zero_sessions_pct,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sessions_count) AS median_sessions,
  ROUND(100.0 * COUNT(sessions_count) FILTER (WHERE sessions_count >= 3) / COUNT(sessions_count), 1) AS sessions_3plus_pct,
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY turnover)::numeric, 2) AS median_turnover
FROM window_info_per_player
GROUP BY days;
