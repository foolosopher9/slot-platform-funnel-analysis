/*
 * Profiling queries for the casino database.
 * These queries are intended to provide a quick overview of the data in the database.
 * They can be used to identify potential issues with the data, such as missing values or outliers.
 */

/* Overall table-level profiling: number of rows and min/max timestamps */
SELECT
  'players' AS table_name,
  COUNT(*) AS rows,
  MIN(signup_ts) AS min_ts,
  MAX(signup_ts) AS max_ts
FROM
  players
UNION ALL
SELECT
  'sessions' AS table_name,
  COUNT(*) AS rows,
  MIN(start_ts) AS min_ts,
  MAX(end_ts) AS max_ts
FROM
  sessions
UNION ALL
SELECT
  'spins' AS table_name,
  COUNT(*) AS rows,
  MIN(ts) AS min_ts,
  MAX(ts) AS max_ts
FROM
  spins;

/* Distribution of players by categorial fields */
SELECT
  'acquisition_channel' AS field,
  acquisition_channel AS value,
  COUNT(*) AS cnt,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM
  players
GROUP BY
  acquisition_channel
UNION ALL
SELECT
  'device_pref',
  device_pref,
  COUNT(*),
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)
FROM
  players
GROUP BY
  device_pref
UNION ALL
SELECT
  'os',
  os,
  COUNT(*),
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)
FROM
  players
GROUP BY
  os
ORDER BY
  field,
  cnt DESC;

/* Distribution of players by country */
SELECT
  country,
  COUNT(*) AS players,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM
  players
GROUP BY
  country
ORDER BY
  players DESC;

/* Key metrics profiling: min, median, avg, max for numeric fields (raw data) */
SELECT
  'session.duration_sec' AS metric,
  MIN(duration_sec) AS min,
  percentile_cont(0.5) WITHIN GROUP (ORDER BY duration_sec)::numeric AS median,
  ROUND(AVG(duration_sec)::numeric, 1) AS avg,
  MAX(duration_sec) AS max
FROM sessions
UNION ALL
SELECT 'session.num_spins', MIN(num_spins),
  percentile_cont(0.5) WITHIN GROUP (ORDER BY num_spins)::numeric,
  ROUND(AVG(num_spins)::numeric, 1), MAX(num_spins)
FROM sessions
UNION ALL
SELECT 'session.avg_bet', MIN(avg_bet),
  ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY avg_bet)::numeric, 2),
  ROUND(AVG(avg_bet)::numeric, 2), MAX(avg_bet)
FROM sessions
UNION ALL
SELECT 'session.spins_per_min', MIN(spins_per_min),
  ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY spins_per_min)::numeric, 2),
  ROUND(AVG(spins_per_min)::numeric, 1), MAX(spins_per_min)
FROM sessions
UNION ALL
SELECT 'spin.bet_amount', MIN(bet_amount),
  ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY bet_amount)::numeric, 2),
  ROUND(AVG(bet_amount)::numeric, 2), MAX(bet_amount)
FROM spins
UNION ALL
SELECT 'spin.win_amount', MIN(win_amount),
  ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY win_amount)::numeric, 2),
  ROUND(AVG(win_amount)::numeric, 2), MAX(win_amount)
FROM spins;

/* Overall RTP (Return to Player) */
SELECT
  ROUND(SUM(win_amount) / NULLIF(SUM(bet_amount), 0), 4) AS rtp
FROM
  spins;

/* Flags and categorical fields profiling */
SELECT
  'geo_mismatch' AS field,
  geo_mismatch::text AS value,
  COUNT(*) AS cnt,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM
  sessions
GROUP BY
  geo_mismatch
UNION ALL
SELECT
  'slot_volatility',
  slot_volatility,
  COUNT(*),
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)
FROM
  spins
GROUP BY
  slot_volatility
UNION ALL
SELECT
  'feature_buy',
  feature_buy::text,
  COUNT(*),
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)
FROM
  spins
GROUP BY
  feature_buy
ORDER BY
  field,
  cnt DESC;