/* Data quality checks: report section 1.3 */


/* 1.3. Completeness */
SELECT 'players: NULL in any field' AS check_name,
       COUNT(*) FILTER (WHERE signup_ts IS NULL OR country IS NULL
                           OR acquisition_channel IS NULL
                           OR device_pref IS NULL OR os IS NULL) AS bad_rows,
       COUNT(*) AS total_rows
FROM players
UNION ALL
SELECT 'sessions: NULL in any field',
       COUNT(*) FILTER (WHERE player_id IS NULL OR start_ts IS NULL
                           OR end_ts IS NULL OR duration_sec IS NULL
                           OR device_id_hash IS NULL OR ip_hash IS NULL
                           OR ip_country IS NULL OR geo_mismatch IS NULL
                           OR num_spins IS NULL OR avg_bet IS NULL
                           OR max_bet IS NULL OR spins_per_min IS NULL),
       COUNT(*)
FROM sessions
UNION ALL
SELECT 'spins: NULL in any field',
       COUNT(*) FILTER (WHERE session_id IS NULL OR player_id IS NULL
                           OR ts IS NULL OR slot_id IS NULL
                           OR slot_volatility IS NULL OR bet_amount IS NULL
                           OR win_amount IS NULL OR feature_buy IS NULL),
       COUNT(*)
FROM spins;


/* 1.3. Uniqueness and links */
SELECT 'players: duplicate player_id' AS check_name,
       COUNT(*) - COUNT(DISTINCT player_id) AS bad_rows,
       COUNT(*) AS total_rows
FROM players
UNION ALL
SELECT 'sessions: duplicate session_id',
       COUNT(*) - COUNT(DISTINCT session_id), COUNT(*)
FROM sessions
UNION ALL
SELECT 'spins: duplicate spin_id',
       COUNT(*) - COUNT(DISTINCT spin_id), COUNT(*)
FROM spins
UNION ALL
SELECT 'sessions without player',
       COUNT(*) FILTER (WHERE NOT EXISTS
         (SELECT 1 FROM players p WHERE p.player_id = se.player_id)),
       COUNT(*)
FROM sessions se
UNION ALL
SELECT 'spins without session',
       COUNT(*) FILTER (WHERE NOT EXISTS
         (SELECT 1 FROM sessions se WHERE se.session_id = sp.session_id)),
       COUNT(*)
FROM spins sp
UNION ALL
SELECT 'sessions without spins',
       COUNT(*) FILTER (WHERE num_spins = 0), COUNT(*)
FROM sessions
UNION ALL
SELECT 'spins: player_id differs from session player',
       COUNT(*) FILTER (WHERE sp.player_id <> se.player_id), COUNT(*)
FROM spins sp
JOIN sessions se ON se.session_id = sp.session_id;


/* 1.3. Time */
SELECT 'sessions: end_ts earlier than start_ts' AS check_name,
       COUNT(*) FILTER (WHERE end_ts < start_ts) AS bad_rows,
       COUNT(*) AS total_rows
FROM sessions
UNION ALL
SELECT 'sessions: duration_sec differs from end_ts - start_ts by > 1 sec',
       COUNT(*) FILTER (WHERE ABS(duration_sec
                                  - EXTRACT(EPOCH FROM end_ts - start_ts)) > 1),
       COUNT(*)
FROM sessions
UNION ALL
SELECT 'spins: ts outside its session',
       COUNT(*) FILTER (WHERE sp.ts < se.start_ts OR sp.ts > se.end_ts), COUNT(*)
FROM spins sp
JOIN sessions se ON se.session_id = sp.session_id
UNION ALL
SELECT 'sessions: start outside 2025-10-01 .. 2026-01-28',
       COUNT(*) FILTER (WHERE start_ts <  DATE '2025-10-01'
                           OR start_ts >= DATE '2026-01-29'),
       COUNT(*)
FROM sessions
UNION ALL
SELECT 'sessions: start before player signup',
       COUNT(*) FILTER (WHERE se.start_ts < p.signup_ts), COUNT(*)
FROM sessions se
JOIN players p ON p.player_id = se.player_id;


/* 1.3. Consistency */
WITH actual AS (
  SELECT session_id,
         COUNT(*)        AS cnt,
         AVG(bet_amount) AS avg_b,
         MAX(bet_amount) AS max_b
  FROM spins
  GROUP BY session_id
)
SELECT 'sessions: num_spins differs from actual spins' AS check_name,
       COUNT(*) FILTER (WHERE se.num_spins <> COALESCE(a.cnt, 0)) AS bad_rows,
       COUNT(*) AS total_rows
FROM sessions se
LEFT JOIN actual a ON a.session_id = se.session_id
UNION ALL
SELECT 'sessions: avg_bet / max_bet differ from actual spins',
       COUNT(*) FILTER (WHERE ABS(se.avg_bet - a.avg_b) > 0.01
                           OR ABS(se.max_bet - a.max_b) > 0.01),
       COUNT(*)
FROM sessions se
JOIN actual a ON a.session_id = se.session_id
UNION ALL
SELECT 'sessions: spins_per_min differs from num_spins / minutes',
       COUNT(*) FILTER (WHERE ABS(spins_per_min
                                  - num_spins / (duration_sec / 60.0)) > 0.011),
       COUNT(*)
FROM sessions
UNION ALL
SELECT 'sessions: geo_mismatch differs from ip_country <> players.country',
       COUNT(*) FILTER (WHERE se.geo_mismatch <> (se.ip_country <> p.country)),
       COUNT(*)
FROM sessions se
JOIN players p ON p.player_id = se.player_id;


/* 1.3. Allowed values */
SELECT 'spins: bet_amount <= 0 or win_amount < 0' AS check_name,
       COUNT(*) FILTER (WHERE bet_amount <= 0 OR win_amount < 0) AS bad_rows,
       COUNT(*) AS total_rows
FROM spins
UNION ALL
SELECT 'players: channel / country / device / os outside lists',
       COUNT(*) FILTER (WHERE acquisition_channel NOT IN
                                ('affiliate', 'organic', 'paid_search',
                                 'paid_social', 'referral')
                           OR country NOT IN
                                ('RS', 'DE', 'GB', 'FR', 'IT',
                                 'NL', 'ES', 'SE', 'PL', 'NO')
                           OR device_pref NOT IN ('mobile', 'desktop')
                           OR os NOT IN ('android', 'ios', 'windows', 'mac')),
       COUNT(*)
FROM players
UNION ALL
SELECT 'sessions: ip_country outside the 10 player countries',
       COUNT(*) FILTER (WHERE ip_country NOT IN
                                ('RS', 'DE', 'GB', 'FR', 'IT',
                                 'NL', 'ES', 'SE', 'PL', 'NO')),
       COUNT(*)
FROM sessions
UNION ALL
SELECT 'spins: volatility not low/med/high or slot_id outside slot_001..slot_060',
       COUNT(*) FILTER (WHERE slot_volatility NOT IN ('low', 'med', 'high')
                           OR slot_id !~ '^slot_0([0-5][0-9]|60)$'
                           OR slot_id = 'slot_000'),
       COUNT(*)
FROM spins
UNION ALL
SELECT 'slots: more than one volatility level',
       COUNT(*) FILTER (WHERE levels > 1), COUNT(*)
FROM (
  SELECT slot_id, COUNT(DISTINCT slot_volatility) AS levels
  FROM spins
  GROUP BY slot_id
) v
UNION ALL
SELECT 'players: os does not match device_pref',
       COUNT(*) FILTER (WHERE (device_pref = 'mobile'  AND os NOT IN ('android', 'ios'))
                           OR (device_pref = 'desktop' AND os NOT IN ('windows', 'mac'))),
       COUNT(*)
FROM players;
