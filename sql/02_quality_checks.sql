/*
 * Data quality checks for report section 1.5.
 *
 * Query 1: row counts.
 * Query 2: all rule-based checks in one result set.
 *          Columns: check number, description, problem rows, total rows, share.
 *          Expected result for every check: bad_rows = 0.
 * Query 3: bet distribution (check 8, outliers) - no "right" answer here,
 *          the threshold is a decision to make from these numbers.
 *
 * Measurement window (report 1.1): 2025-10-01 .. 2026-01-29 inclusive.
 */


/* ---------------------------------------------------------------------------
 * Query 1. Check 1: row counts
 * ------------------------------------------------------------------------- */
SELECT 'players' AS table_name, COUNT(*) AS rows FROM players
UNION ALL
SELECT 'sessions', COUNT(*) FROM sessions
UNION ALL
SELECT 'spins', COUNT(*) FROM spins;


/* ---------------------------------------------------------------------------
 * Query 2. Checks 2-11 (except 8 outliers, see query 3)
 * ------------------------------------------------------------------------- */
WITH
spin_counts AS (
  SELECT session_id, COUNT(*) AS cnt
  FROM spins
  GROUP BY session_id
),
checks AS (

  /* 2. Duplicate identifiers */
  SELECT '02a' AS no, 'players: duplicate player_id' AS check_name,
         COUNT(*) - COUNT(DISTINCT player_id) AS bad_rows, COUNT(*) AS total_rows
  FROM players
  UNION ALL
  SELECT '02b', 'sessions: duplicate session_id',
         COUNT(*) - COUNT(DISTINCT session_id), COUNT(*)
  FROM sessions
  UNION ALL
  SELECT '02c', 'spins: duplicate spin_id',
         COUNT(*) - COUNT(DISTINCT spin_id), COUNT(*)
  FROM spins

  /* 3. NULL in key fields */
  UNION ALL
  SELECT '03a', 'players: NULL in signup_ts / country / channel / device / os',
         COUNT(*) FILTER (WHERE signup_ts IS NULL OR country IS NULL
                             OR acquisition_channel IS NULL
                             OR device_pref IS NULL OR os IS NULL),
         COUNT(*)
  FROM players
  UNION ALL
  SELECT '03b', 'sessions: NULL in player_id / start_ts / end_ts / num_spins',
         COUNT(*) FILTER (WHERE player_id IS NULL OR start_ts IS NULL
                             OR end_ts IS NULL OR num_spins IS NULL),
         COUNT(*)
  FROM sessions
  UNION ALL
  SELECT '03c', 'spins: NULL in session_id / player_id / ts / bet / win',
         COUNT(*) FILTER (WHERE session_id IS NULL OR player_id IS NULL
                             OR ts IS NULL OR bet_amount IS NULL
                             OR win_amount IS NULL),
         COUNT(*)
  FROM spins

  /* 4. Broken links (guaranteed 0 by foreign keys, kept for the record) */
  UNION ALL
  SELECT '04a', 'sessions without player',
         COUNT(*) FILTER (WHERE NOT EXISTS
           (SELECT 1 FROM players p WHERE p.player_id = se.player_id)),
         COUNT(*)
  FROM sessions se
  UNION ALL
  SELECT '04b', 'spins without session',
         COUNT(*) FILTER (WHERE NOT EXISTS
           (SELECT 1 FROM sessions se WHERE se.session_id = sp.session_id)),
         COUNT(*)
  FROM spins sp

  /* 5. Empty sessions */
  UNION ALL
  SELECT '05', 'sessions with num_spins = 0',
         COUNT(*) FILTER (WHERE num_spins = 0), COUNT(*)
  FROM sessions

  /* 6. sessions.num_spins vs actual spins */
  UNION ALL
  SELECT '06', 'sessions: num_spins differs from actual spin count',
         COUNT(*) FILTER (WHERE se.num_spins IS DISTINCT FROM COALESCE(sc.cnt, 0)),
         COUNT(*)
  FROM sessions se
  LEFT JOIN spin_counts sc ON sc.session_id = se.session_id

  /* 7. Time and duration */
  UNION ALL
  SELECT '07a', 'sessions: end_ts earlier than start_ts',
         COUNT(*) FILTER (WHERE end_ts < start_ts), COUNT(*)
  FROM sessions
  UNION ALL
  SELECT '07b', 'sessions: duration_sec differs from end_ts - start_ts by > 1 sec',
         COUNT(*) FILTER (WHERE ABS(duration_sec
                                    - EXTRACT(EPOCH FROM end_ts - start_ts)) > 1),
         COUNT(*)
  FROM sessions
  UNION ALL
  SELECT '07c', 'spins: ts outside its session start_ts..end_ts',
         COUNT(*) FILTER (WHERE sp.ts < se.start_ts OR sp.ts > se.end_ts),
         COUNT(*)
  FROM spins sp
  JOIN sessions se ON se.session_id = sp.session_id

  /* 8. Impossible values (outliers are in query 3) */
  UNION ALL
  SELECT '08a', 'spins: bet_amount <= 0 or win_amount < 0',
         COUNT(*) FILTER (WHERE bet_amount <= 0 OR win_amount < 0), COUNT(*)
  FROM spins
  UNION ALL
  SELECT '08b', 'sessions: avg_bet > max_bet',
         COUNT(*) FILTER (WHERE avg_bet > max_bet), COUNT(*)
  FROM sessions

  /* 9. Outside measurement window or before signup */
  UNION ALL
  SELECT '09a', 'sessions: start_ts outside measurement window',
         COUNT(*) FILTER (WHERE start_ts <  DATE '2025-10-01'
                             OR start_ts >= DATE '2026-01-30'),
         COUNT(*)
  FROM sessions
  UNION ALL
  SELECT '09b', 'sessions: start_ts before player signup_ts',
         COUNT(*) FILTER (WHERE se.start_ts < p.signup_ts), COUNT(*)
  FROM sessions se
  JOIN players p ON p.player_id = se.player_id

  /* 10. geo_mismatch flag vs its definition */
  UNION ALL
  SELECT '10', 'sessions: geo_mismatch disagrees with ip_country <> players.country',
         COUNT(*) FILTER (WHERE se.geo_mismatch IS DISTINCT FROM
                                (se.ip_country IS DISTINCT FROM p.country)),
         COUNT(*)
  FROM sessions se
  JOIN players p ON p.player_id = se.player_id

  /* 11. Denormalized spins.player_id vs player of the session */
  UNION ALL
  SELECT '11', 'spins: player_id differs from player of its session',
         COUNT(*) FILTER (WHERE sp.player_id <> se.player_id), COUNT(*)
  FROM spins sp
  JOIN sessions se ON se.session_id = sp.session_id
)
SELECT
  no,
  check_name,
  bad_rows,
  total_rows,
  ROUND(100.0 * bad_rows / NULLIF(total_rows, 0), 3) AS pct
FROM checks
ORDER BY no;


/* ---------------------------------------------------------------------------
 * Query 3. Check 8: bet distribution and concentration of turnover
 *
 * Bets in gambling are heavy-tailed: a few huge bets can carry a large share
 * of turnover. top_01pct_turnover_share shows how much turnover comes from
 * the largest 0.1% of bets. If it is large, means are unreliable and the
 * analysis should rely on medians / percentiles.
 * ------------------------------------------------------------------------- */
WITH
bet_pct AS (
  SELECT
    percentile_cont(0.50)  WITHIN GROUP (ORDER BY bet_amount) AS p50,
    percentile_cont(0.90)  WITHIN GROUP (ORDER BY bet_amount) AS p90,
    percentile_cont(0.99)  WITHIN GROUP (ORDER BY bet_amount) AS p99,
    percentile_cont(0.999) WITHIN GROUP (ORDER BY bet_amount) AS p999,
    MAX(bet_amount) AS max_value
  FROM spins
),
session_pct AS (
  SELECT
    percentile_cont(0.50)  WITHIN GROUP (ORDER BY avg_bet) AS p50,
    percentile_cont(0.90)  WITHIN GROUP (ORDER BY avg_bet) AS p90,
    percentile_cont(0.99)  WITHIN GROUP (ORDER BY avg_bet) AS p99,
    percentile_cont(0.999) WITHIN GROUP (ORDER BY avg_bet) AS p999,
    MAX(avg_bet) AS max_value
  FROM sessions
  WHERE num_spins > 0
)
SELECT
  'spin.bet_amount' AS metric,
  ROUND(b.p50::numeric, 2)  AS p50,
  ROUND(b.p90::numeric, 2)  AS p90,
  ROUND(b.p99::numeric, 2)  AS p99,
  ROUND(b.p999::numeric, 2) AS p999,
  b.max_value,
  ROUND(100.0 * SUM(s.bet_amount) FILTER (WHERE s.bet_amount > b.p999)
        / SUM(s.bet_amount), 1) AS top_01pct_turnover_share
FROM spins s
CROSS JOIN bet_pct b
GROUP BY b.p50, b.p90, b.p99, b.p999, b.max_value
UNION ALL
SELECT
  'session.avg_bet (num_spins > 0)',
  ROUND(p50::numeric, 2),
  ROUND(p90::numeric, 2),
  ROUND(p99::numeric, 2),
  ROUND(p999::numeric, 2),
  max_value,
  NULL
FROM session_pct;
