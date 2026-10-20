/* Data quality checks: report section 1.3 */


/* 1.3. Completeness */
SELECT
  'players: NULL in any field' AS check_name,
  COUNT(*) FILTER (
    WHERE players.signup_ts IS NULL
      OR players.country IS NULL
      OR players.acquisition_channel IS NULL
      OR players.device_pref IS NULL
      OR players.os IS NULL
  ) AS bad_rows,
  COUNT(*) AS total_rows
FROM players
UNION ALL
SELECT
  'sessions: NULL in any field',
  COUNT(*) FILTER (
    WHERE sessions.player_id IS NULL
      OR sessions.start_ts IS NULL
      OR sessions.end_ts IS NULL
      OR sessions.duration_sec IS NULL
      OR sessions.device_id_hash IS NULL
      OR sessions.ip_hash IS NULL
      OR sessions.ip_country IS NULL
      OR sessions.geo_mismatch IS NULL
      OR sessions.num_spins IS NULL
      OR sessions.avg_bet IS NULL
      OR sessions.max_bet IS NULL
      OR sessions.spins_per_min IS NULL
  ),
  COUNT(*)
FROM sessions
UNION ALL
SELECT
  'spins: NULL in any field',
  COUNT(*) FILTER (
    WHERE spins.session_id IS NULL
      OR spins.player_id IS NULL
      OR spins.ts IS NULL
      OR spins.slot_id IS NULL
      OR spins.slot_volatility IS NULL
      OR spins.bet_amount IS NULL
      OR spins.win_amount IS NULL
      OR spins.feature_buy IS NULL
  ),
  COUNT(*)
FROM spins;


/* 1.3. Uniqueness and links */
SELECT
  'players: duplicate player_id' AS check_name,
  COUNT(*) - COUNT(DISTINCT players.player_id) AS bad_rows,
  COUNT(*) AS total_rows
FROM players
UNION ALL
SELECT
  'sessions: duplicate session_id',
  COUNT(*) - COUNT(DISTINCT sessions.session_id),
  COUNT(*)
FROM sessions
UNION ALL
SELECT
  'spins: duplicate spin_id',
  COUNT(*) - COUNT(DISTINCT spins.spin_id),
  COUNT(*)
FROM spins
UNION ALL
SELECT
  'sessions without player',
  COUNT(*) FILTER (
    WHERE NOT EXISTS (
      SELECT 1
      FROM players
      WHERE players.player_id = sessions.player_id
    )
  ),
  COUNT(*)
FROM sessions
UNION ALL
SELECT
  'spins without session',
  COUNT(*) FILTER (
    WHERE NOT EXISTS (
      SELECT 1
      FROM sessions
      WHERE sessions.session_id = spins.session_id
    )
  ),
  COUNT(*)
FROM spins
UNION ALL
SELECT
  'sessions without spins',
  COUNT(*) FILTER (WHERE sessions.num_spins = 0),
  COUNT(*)
FROM sessions
UNION ALL
SELECT
  'spins: player_id differs from session player',
  COUNT(*) FILTER (WHERE spins.player_id <> sessions.player_id),
  COUNT(*)
FROM spins
JOIN sessions
  ON spins.session_id = sessions.session_id;


/* 1.3. Time */
SELECT
  'sessions: end_ts earlier than start_ts' AS check_name,
  COUNT(*) FILTER (WHERE sessions.end_ts < sessions.start_ts) AS bad_rows,
  COUNT(*) AS total_rows
FROM sessions
UNION ALL
SELECT
  'sessions: duration_sec differs from end_ts - start_ts by > 1 sec',
  COUNT(*) FILTER (
    WHERE ABS(sessions.duration_sec - EXTRACT(EPOCH FROM sessions.end_ts - sessions.start_ts)) > 1
  ),
  COUNT(*)
FROM sessions
UNION ALL
SELECT
  'spins: ts outside its session',
  COUNT(*) FILTER (
    WHERE spins.ts < sessions.start_ts
      OR spins.ts > sessions.end_ts
  ),
  COUNT(*)
FROM spins
JOIN sessions
  ON spins.session_id = sessions.session_id
UNION ALL
SELECT
  'sessions: start outside 2025-10-01 .. 2026-01-28',
  COUNT(*) FILTER (
    WHERE sessions.start_ts < DATE '2025-10-01'
      OR sessions.start_ts >= DATE '2026-01-29'
  ),
  COUNT(*)
FROM sessions
UNION ALL
SELECT
  'sessions: start before player signup',
  COUNT(*) FILTER (WHERE sessions.start_ts < players.signup_ts),
  COUNT(*)
FROM sessions
JOIN players
  ON sessions.player_id = players.player_id;


/* 1.3. Consistency */
WITH actual_spins_per_session AS (
  SELECT
    spins.session_id,
    COUNT(*) AS spins_count,
    AVG(spins.bet_amount) AS avg_bet,
    MAX(spins.bet_amount) AS max_bet
  FROM spins
  GROUP BY spins.session_id
)
SELECT
  'sessions: num_spins differs from actual spins' AS check_name,
  COUNT(*) FILTER (
    WHERE sessions.num_spins <> COALESCE(actual_spins_per_session.spins_count, 0)
  ) AS bad_rows,
  COUNT(*) AS total_rows
FROM sessions
LEFT JOIN actual_spins_per_session
  ON sessions.session_id = actual_spins_per_session.session_id
UNION ALL
SELECT
  'sessions: avg_bet / max_bet differ from actual spins',
  COUNT(*) FILTER (
    WHERE ABS(sessions.avg_bet - actual_spins_per_session.avg_bet) > 0.01
      OR ABS(sessions.max_bet - actual_spins_per_session.max_bet) > 0.01
  ),
  COUNT(*)
FROM sessions
JOIN actual_spins_per_session
  ON sessions.session_id = actual_spins_per_session.session_id
UNION ALL
SELECT
  'sessions: spins_per_min differs from num_spins / minutes',
  COUNT(*) FILTER (
    WHERE ABS(sessions.spins_per_min - sessions.num_spins / (sessions.duration_sec / 60.0)) > 0.011
  ),
  COUNT(*)
FROM sessions
UNION ALL
SELECT
  'sessions: geo_mismatch differs from ip_country <> players.country',
  COUNT(*) FILTER (
    WHERE sessions.geo_mismatch <> (sessions.ip_country <> players.country)
  ),
  COUNT(*)
FROM sessions
JOIN players
  ON sessions.player_id = players.player_id;


/* 1.3. Allowed values */
SELECT
  'spins: bet_amount <= 0 or win_amount < 0' AS check_name,
  COUNT(*) FILTER (
    WHERE spins.bet_amount <= 0
      OR spins.win_amount < 0
  ) AS bad_rows,
  COUNT(*) AS total_rows
FROM spins
UNION ALL
SELECT
  'players: channel / country / device / os outside lists',
  COUNT(*) FILTER (
    WHERE players.acquisition_channel NOT IN ('affiliate', 'organic', 'paid_search', 'paid_social', 'referral')
      OR players.country NOT IN ('RS', 'DE', 'GB', 'FR', 'IT', 'NL', 'ES', 'SE', 'PL', 'NO')
      OR players.device_pref NOT IN ('mobile', 'desktop')
      OR players.os NOT IN ('android', 'ios', 'windows', 'mac')
  ),
  COUNT(*)
FROM players
UNION ALL
SELECT
  'sessions: ip_country outside the 10 player countries',
  COUNT(*) FILTER (
    WHERE sessions.ip_country NOT IN ('RS', 'DE', 'GB', 'FR', 'IT', 'NL', 'ES', 'SE', 'PL', 'NO')
  ),
  COUNT(*)
FROM sessions
UNION ALL
SELECT
  'spins: volatility not low/med/high or slot_id outside slot_001..slot_060',
  COUNT(*) FILTER (
    WHERE spins.slot_volatility NOT IN ('low', 'med', 'high')
      OR spins.slot_id !~ '^slot_0([0-5][0-9]|60)$'
      OR spins.slot_id = 'slot_000'
  ),
  COUNT(*)
FROM spins
UNION ALL
SELECT
  'slots: more than one volatility level',
  COUNT(*) FILTER (WHERE volatility_levels_per_slot.levels_count > 1),
  COUNT(*)
FROM (
  SELECT
    spins.slot_id,
    COUNT(DISTINCT spins.slot_volatility) AS levels_count
  FROM spins
  GROUP BY spins.slot_id
) AS volatility_levels_per_slot
UNION ALL
SELECT
  'players: os does not match device_pref',
  COUNT(*) FILTER (
    WHERE (players.device_pref = 'mobile' AND players.os NOT IN ('android', 'ios'))
      OR (players.device_pref = 'desktop' AND players.os NOT IN ('windows', 'mac'))
  ),
  COUNT(*)
FROM players;
