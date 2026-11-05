/* Geo mismatch background rate within 90 days after signup, report section 2.4 */


SELECT
  COUNT(sessions.session_id) AS window_sessions,
  COUNT(sessions.session_id) FILTER (WHERE sessions.geo_mismatch) AS mismatch_sessions,
  ROUND(100.0 * COUNT(sessions.session_id) FILTER (WHERE sessions.geo_mismatch) / COUNT(sessions.session_id), 2) AS mismatch_pct
FROM sessions
JOIN players
  ON sessions.player_id = players.player_id
  AND sessions.start_ts < players.signup_ts + INTERVAL '90 days';
