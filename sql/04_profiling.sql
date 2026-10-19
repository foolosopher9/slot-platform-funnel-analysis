/* Data profiling: report sections 1.1 and 1.4 */


/* 1.1. Source */


/* Rows and time range per table */
SELECT 'players' AS table_name, COUNT(*) AS row_count,
       MIN(signup_ts) AS min_ts, MAX(signup_ts) AS max_ts
FROM players
UNION ALL
SELECT 'sessions', COUNT(*), MIN(start_ts), MAX(end_ts)
FROM sessions
UNION ALL
SELECT 'spins', COUNT(*), MIN(ts), MAX(ts)
FROM spins;


/* 1.4. Players */


/* Players by acquisition channel */
SELECT acquisition_channel,
       COUNT(*) AS players,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM players
GROUP BY acquisition_channel
ORDER BY players DESC;


/* Players by device and OS */
SELECT 'device_pref' AS field, device_pref AS value,
       COUNT(*) AS players,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM players
GROUP BY device_pref
UNION ALL
SELECT 'os', os, COUNT(*),
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)
FROM players
GROUP BY os
ORDER BY field, players DESC;


/* Players by country */
SELECT country,
       COUNT(*) AS players,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM players
GROUP BY country
ORDER BY players DESC;


/* Signups: median date by channel and by country */
SELECT 'channel' AS segment_type, acquisition_channel AS segment,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY signup_ts) AS median_signup
FROM players
GROUP BY acquisition_channel
UNION ALL
SELECT 'country', country,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY signup_ts)
FROM players
GROUP BY country
ORDER BY segment_type, median_signup;


/* Sessions per player, including players with no sessions */
WITH per_player AS (
  SELECT p.player_id, COUNT(se.session_id) AS n
  FROM players p
  LEFT JOIN sessions se ON se.player_id = p.player_id
  GROUP BY p.player_id
)
SELECT COUNT(*) FILTER (WHERE n = 0) AS zero_players,
       ROUND(100.0 * COUNT(*) FILTER (WHERE n = 0) / COUNT(*), 1) AS zero_pct,
       PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY n) AS median,
       PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY n) AS p75,
       PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY n) AS p90,
       MAX(n) AS max
FROM per_player;


/* Sessions per player: distribution, 10 = 10 or more */
WITH per_player AS (
  SELECT p.player_id, COUNT(se.session_id) AS n
  FROM players p
  LEFT JOIN sessions se ON se.player_id = p.player_id
  GROUP BY p.player_id
)
SELECT LEAST(n, 10) AS sessions,
       COUNT(*) AS players,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM per_player
GROUP BY LEAST(n, 10)
ORDER BY sessions;


/* 1.4. Sessions and spins */


/* Numeric fields: min, median, mean, max on raw data */
SELECT 'session.duration_sec' AS metric,
       MIN(duration_sec) AS min,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY duration_sec)::numeric AS median,
       ROUND(AVG(duration_sec)::numeric, 1) AS avg,
       MAX(duration_sec) AS max
FROM sessions
UNION ALL
SELECT 'session.num_spins', MIN(num_spins),
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY num_spins)::numeric,
       ROUND(AVG(num_spins)::numeric, 1), MAX(num_spins)
FROM sessions
UNION ALL
SELECT 'session.avg_bet', MIN(avg_bet),
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_bet)::numeric, 2),
       ROUND(AVG(avg_bet)::numeric, 2), MAX(avg_bet)
FROM sessions
UNION ALL
SELECT 'session.spins_per_min', MIN(spins_per_min),
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY spins_per_min)::numeric, 2),
       ROUND(AVG(spins_per_min)::numeric, 2), MAX(spins_per_min)
FROM sessions
UNION ALL
SELECT 'spin.bet_amount', MIN(bet_amount),
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY bet_amount)::numeric, 2),
       ROUND(AVG(bet_amount)::numeric, 2), MAX(bet_amount)
FROM spins
UNION ALL
SELECT 'spin.win_amount', MIN(win_amount),
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY win_amount)::numeric, 2),
       ROUND(AVG(win_amount)::numeric, 2), MAX(win_amount)
FROM spins;


/* Share of spins with no win */
SELECT ROUND(100.0 * AVG((win_amount = 0)::int), 1) AS pct_zero_win
FROM spins;


/* Overall RTP: total wins / total bets */
SELECT ROUND(SUM(win_amount) / NULLIF(SUM(bet_amount), 0), 4) AS rtp
FROM spins;


/* Session starts by hour (UTC) */
SELECT EXTRACT(HOUR FROM start_ts)::int AS hour_utc,
       COUNT(*) AS sessions,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM sessions
GROUP BY hour_utc
ORDER BY hour_utc;


/* 1.4. Flags */


/* geo_mismatch: share of sessions */
SELECT geo_mismatch,
       COUNT(*) AS sessions,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM sessions
GROUP BY geo_mismatch
ORDER BY sessions DESC;


/* feature_buy: share of spins */
SELECT feature_buy,
       COUNT(*) AS spins,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM spins
GROUP BY feature_buy
ORDER BY spins DESC;


/* 1.4. Bet concentration */


/* Bet percentiles: per spin and per session */
SELECT 'spin.bet_amount' AS metric,
       ROUND(PERCENTILE_CONT(0.50)  WITHIN GROUP (ORDER BY bet_amount)::numeric, 2) AS p50,
       ROUND(PERCENTILE_CONT(0.90)  WITHIN GROUP (ORDER BY bet_amount)::numeric, 2) AS p90,
       ROUND(PERCENTILE_CONT(0.99)  WITHIN GROUP (ORDER BY bet_amount)::numeric, 2) AS p99,
       ROUND(PERCENTILE_CONT(0.999) WITHIN GROUP (ORDER BY bet_amount)::numeric, 2) AS p999,
       MAX(bet_amount) AS max
FROM spins
UNION ALL
SELECT 'session.avg_bet',
       ROUND(PERCENTILE_CONT(0.50)  WITHIN GROUP (ORDER BY avg_bet)::numeric, 2),
       ROUND(PERCENTILE_CONT(0.90)  WITHIN GROUP (ORDER BY avg_bet)::numeric, 2),
       ROUND(PERCENTILE_CONT(0.99)  WITHIN GROUP (ORDER BY avg_bet)::numeric, 2),
       ROUND(PERCENTILE_CONT(0.999) WITHIN GROUP (ORDER BY avg_bet)::numeric, 2),
       MAX(avg_bet)
FROM sessions
WHERE num_spins > 0;


/* Bets above p99.9: turnover share, players, feature_buy share */
WITH threshold AS (
  SELECT PERCENTILE_CONT(0.999) WITHIN GROUP (ORDER BY bet_amount) AS p999
  FROM spins
)
SELECT COUNT(*) FILTER (WHERE sp.bet_amount > t.p999) AS tail_spins,
       ROUND(100.0 * SUM(sp.bet_amount) FILTER (WHERE sp.bet_amount > t.p999)
             / SUM(sp.bet_amount), 1) AS tail_turnover_pct,
       COUNT(DISTINCT sp.player_id) FILTER (WHERE sp.bet_amount > t.p999) AS tail_players,
       ROUND(100.0 * AVG(sp.feature_buy::int) FILTER (WHERE sp.bet_amount > t.p999), 1)
         AS tail_feature_buy_pct
FROM spins sp
CROSS JOIN threshold t;


/* Share of turnover from the top 10 and top 1% of players */
WITH per_player AS (
  SELECT player_id, SUM(bet_amount) AS turnover
  FROM spins
  GROUP BY player_id
),
ranked AS (
  SELECT turnover,
         ROW_NUMBER()  OVER (ORDER BY turnover DESC) AS rn,
         COUNT(*)      OVER () AS n,
         SUM(turnover) OVER () AS total
  FROM per_player
)
SELECT ROUND(100.0 * SUM(turnover) FILTER (WHERE rn <= 10) / MAX(total), 1)
         AS top10_players_pct,
       CEIL(MAX(n) * 0.01) AS top1pct_players,
       ROUND(100.0 * SUM(turnover) FILTER (WHERE rn <= CEIL(n * 0.01)) / MAX(total), 1)
         AS top1pct_players_pct
FROM ranked;


/* 1.4. Slots and volatility */


/* Slots, spins and spins per slot by volatility level */
SELECT slot_volatility,
       COUNT(DISTINCT slot_id) AS slots,
       COUNT(*) AS spins,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_spins,
       ROUND(COUNT(*)::numeric / COUNT(DISTINCT slot_id)) AS spins_per_slot
FROM spins
GROUP BY slot_volatility
ORDER BY spins DESC;
