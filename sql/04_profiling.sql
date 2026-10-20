/* Data profiling: report sections 1.1 and 1.4 */


/* 1.1. Source */


/* Rows and time range per table */
SELECT
  'players' AS table_name,
  COUNT(*) AS row_count,
  MIN(players.signup_ts) AS min_ts,
  MAX(players.signup_ts) AS max_ts
FROM players
UNION ALL
SELECT
  'sessions',
  COUNT(*),
  MIN(sessions.start_ts),
  MAX(sessions.end_ts)
FROM sessions
UNION ALL
SELECT
  'spins',
  COUNT(*),
  MIN(spins.ts),
  MAX(spins.ts)
FROM spins;


/* 1.4. Players */


/* Players by acquisition channel */
SELECT
  players.acquisition_channel,
  COUNT(*) AS players_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS players_pct
FROM players
GROUP BY players.acquisition_channel
ORDER BY players_count DESC;


/* Players by device and OS */
SELECT
  'device_pref' AS field,
  players.device_pref AS value,
  COUNT(*) AS players_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS players_pct
FROM players
GROUP BY players.device_pref
UNION ALL
SELECT
  'os',
  players.os,
  COUNT(*),
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)
FROM players
GROUP BY players.os
ORDER BY field, players_count DESC;


/* Players by country */
SELECT
  players.country,
  COUNT(*) AS players_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS players_pct
FROM players
GROUP BY players.country
ORDER BY players_count DESC;


/* Signups: median date by channel and by country */
SELECT
  'channel' AS segment_type,
  players.acquisition_channel AS segment,
  PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY players.signup_ts) AS median_signup
FROM players
GROUP BY players.acquisition_channel
UNION ALL
SELECT
  'country',
  players.country,
  PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY players.signup_ts)
FROM players
GROUP BY players.country
ORDER BY segment_type, median_signup;


/* Sessions per player, including players with no sessions */
WITH sessions_per_player AS (
  SELECT
    players.player_id,
    COUNT(sessions.session_id) AS sessions_count
  FROM players
  LEFT JOIN sessions
    ON players.player_id = sessions.player_id
  GROUP BY players.player_id
)
SELECT
  COUNT(*) FILTER (WHERE sessions_per_player.sessions_count = 0) AS zero_sessions_players,
  ROUND(100.0 * COUNT(*) FILTER (WHERE sessions_per_player.sessions_count = 0) / COUNT(*), 1) AS zero_sessions_pct,
  PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY sessions_per_player.sessions_count) AS median_sessions,
  PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY sessions_per_player.sessions_count) AS p75_sessions,
  PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY sessions_per_player.sessions_count) AS p90_sessions,
  MAX(sessions_per_player.sessions_count) AS max_sessions
FROM sessions_per_player;


/* Sessions per player: distribution, 10 = 10 or more */
WITH sessions_per_player AS (
  SELECT
    players.player_id,
    COUNT(sessions.session_id) AS sessions_count
  FROM players
  LEFT JOIN sessions
    ON players.player_id = sessions.player_id
  GROUP BY players.player_id
)
SELECT
  LEAST(sessions_per_player.sessions_count, 10) AS sessions_bucket,
  COUNT(*) AS players_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS players_pct
FROM sessions_per_player
GROUP BY LEAST(sessions_per_player.sessions_count, 10)
ORDER BY sessions_bucket;


/* 1.4. Sessions and spins */


/* Numeric fields: min, median, mean, max on raw data */
SELECT
  'session.duration_sec' AS metric,
  MIN(sessions.duration_sec) AS min_value,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sessions.duration_sec)::numeric AS median_value,
  ROUND(AVG(sessions.duration_sec)::numeric, 1) AS avg_value,
  MAX(sessions.duration_sec) AS max_value
FROM sessions
UNION ALL
SELECT
  'session.num_spins',
  MIN(sessions.num_spins),
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sessions.num_spins)::numeric,
  ROUND(AVG(sessions.num_spins)::numeric, 1),
  MAX(sessions.num_spins)
FROM sessions
UNION ALL
SELECT
  'session.avg_bet',
  MIN(sessions.avg_bet),
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sessions.avg_bet)::numeric, 2),
  ROUND(AVG(sessions.avg_bet)::numeric, 2),
  MAX(sessions.avg_bet)
FROM sessions
UNION ALL
SELECT
  'session.spins_per_min',
  MIN(sessions.spins_per_min),
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sessions.spins_per_min)::numeric, 2),
  ROUND(AVG(sessions.spins_per_min)::numeric, 2),
  MAX(sessions.spins_per_min)
FROM sessions
UNION ALL
SELECT
  'spin.bet_amount',
  MIN(spins.bet_amount),
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY spins.bet_amount)::numeric, 2),
  ROUND(AVG(spins.bet_amount)::numeric, 2),
  MAX(spins.bet_amount)
FROM spins
UNION ALL
SELECT
  'spin.win_amount',
  MIN(spins.win_amount),
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY spins.win_amount)::numeric, 2),
  ROUND(AVG(spins.win_amount)::numeric, 2),
  MAX(spins.win_amount)
FROM spins;


/* Share of spins with no win */
SELECT
  ROUND(100.0 * AVG((spins.win_amount = 0)::int), 1) AS zero_win_pct
FROM spins;


/* Overall RTP: total wins / total bets */
SELECT
  ROUND(SUM(spins.win_amount) / NULLIF(SUM(spins.bet_amount), 0), 4) AS rtp
FROM spins;


/* Session starts by hour (UTC) */
SELECT
  EXTRACT(HOUR FROM sessions.start_ts)::int AS hour_utc,
  COUNT(*) AS sessions_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS sessions_pct
FROM sessions
GROUP BY hour_utc
ORDER BY hour_utc;


/* 1.4. Flags */


/* geo_mismatch: share of sessions */
SELECT
  sessions.geo_mismatch,
  COUNT(*) AS sessions_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS sessions_pct
FROM sessions
GROUP BY sessions.geo_mismatch
ORDER BY sessions_count DESC;


/* feature_buy: share of spins */
SELECT
  spins.feature_buy,
  COUNT(*) AS spins_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS spins_pct
FROM spins
GROUP BY spins.feature_buy
ORDER BY spins_count DESC;


/* 1.4. Bet concentration */


/* Bet percentiles: per spin and per session */
SELECT
  'spin.bet_amount' AS metric,
  ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY spins.bet_amount)::numeric, 2) AS p50,
  ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY spins.bet_amount)::numeric, 2) AS p90,
  ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY spins.bet_amount)::numeric, 2) AS p99,
  ROUND(PERCENTILE_CONT(0.999) WITHIN GROUP (ORDER BY spins.bet_amount)::numeric, 2) AS p999,
  MAX(spins.bet_amount) AS max_value
FROM spins
UNION ALL
SELECT
  'session.avg_bet',
  ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY sessions.avg_bet)::numeric, 2),
  ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY sessions.avg_bet)::numeric, 2),
  ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY sessions.avg_bet)::numeric, 2),
  ROUND(PERCENTILE_CONT(0.999) WITHIN GROUP (ORDER BY sessions.avg_bet)::numeric, 2),
  MAX(sessions.avg_bet)
FROM sessions
WHERE sessions.num_spins > 0;


/* Bets above p99.9: turnover share, players, feature_buy share */
WITH bet_threshold AS (
  SELECT
    PERCENTILE_CONT(0.999) WITHIN GROUP (ORDER BY spins.bet_amount) AS p999
  FROM spins
)
SELECT
  COUNT(*) FILTER (WHERE spins.bet_amount > bet_threshold.p999) AS tail_spins,
  ROUND(100.0 * SUM(spins.bet_amount) FILTER (WHERE spins.bet_amount > bet_threshold.p999) / SUM(spins.bet_amount), 1) AS tail_turnover_pct,
  COUNT(DISTINCT spins.player_id) FILTER (WHERE spins.bet_amount > bet_threshold.p999) AS tail_players,
  ROUND(100.0 * AVG(spins.feature_buy::int) FILTER (WHERE spins.bet_amount > bet_threshold.p999), 1) AS tail_feature_buy_pct
FROM spins
CROSS JOIN bet_threshold;


/* Share of turnover from the top 10 and top 1% of players */
WITH turnover_per_player AS (
  SELECT
    spins.player_id,
    SUM(spins.bet_amount) AS turnover
  FROM spins
  GROUP BY spins.player_id
),
ranked_players AS (
  SELECT
    turnover_per_player.turnover,
    ROW_NUMBER() OVER (ORDER BY turnover_per_player.turnover DESC) AS turnover_rank,
    COUNT(*) OVER () AS players_count,
    SUM(turnover_per_player.turnover) OVER () AS total_turnover
  FROM turnover_per_player
)
SELECT
  ROUND(100.0 * SUM(ranked_players.turnover) FILTER (WHERE ranked_players.turnover_rank <= 10) / MAX(ranked_players.total_turnover), 1) AS top10_players_pct,
  CEIL(MAX(ranked_players.players_count) * 0.01) AS top1pct_players,
  ROUND(100.0 * SUM(ranked_players.turnover) FILTER (WHERE ranked_players.turnover_rank <= CEIL(ranked_players.players_count * 0.01)) / MAX(ranked_players.total_turnover), 1) AS top1pct_players_pct
FROM ranked_players;


/* 1.4. Slots and volatility */


/* Slots, spins and spins per slot by volatility level */
SELECT
  spins.slot_volatility,
  COUNT(DISTINCT spins.slot_id) AS slots_count,
  COUNT(*) AS spins_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS spins_pct,
  ROUND(COUNT(*)::numeric / COUNT(DISTINCT spins.slot_id)) AS spins_per_slot
FROM spins
GROUP BY spins.slot_volatility
ORDER BY spins_count DESC;
