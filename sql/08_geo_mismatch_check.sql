/* Geo mismatch per player within 90 days after signup: how many mismatches and how likely that number is by chance */


WITH window_sessions AS (
  SELECT
    sessions.player_id,
    sessions.ip_country,
    sessions.geo_mismatch,
    ROW_NUMBER() OVER (PARTITION BY sessions.player_id ORDER BY sessions.start_ts) AS session_number
  FROM sessions
  JOIN players
    ON sessions.player_id = players.player_id
    AND players.signup_ts + INTERVAL '90 days' > sessions.start_ts
),
mismatch_rate AS (
  SELECT
    AVG(window_sessions.geo_mismatch::int)::double precision AS rate
  FROM window_sessions
),
player_mismatch AS (
  SELECT
    window_sessions.player_id,
    COUNT(*) AS total_sessions,
    COUNT(*) FILTER (WHERE window_sessions.geo_mismatch) AS mismatch_sessions,
    COUNT(DISTINCT window_sessions.ip_country) FILTER (WHERE window_sessions.geo_mismatch) AS foreign_countries,
    BOOL_OR(window_sessions.geo_mismatch AND window_sessions.session_number = 1) AS first_session_mismatch
  FROM window_sessions
  GROUP BY window_sessions.player_id
  HAVING COUNT(*) FILTER (WHERE window_sessions.geo_mismatch) > 0
),
log_factorials AS (
  SELECT
    numbers.number,
    SUM(LN(GREATEST(numbers.number, 1))) OVER (ORDER BY numbers.number) AS log_factorial
  FROM generate_series(0, (SELECT MAX(player_mismatch.total_sessions) FROM player_mismatch)) AS numbers(number)
),
chance_terms AS (
  -- probability of exactly possible_count.k mismatches out of total_sessions, for every k from observed to total
  SELECT
    player_mismatch.player_id,
    EXP(
      total_factorial.log_factorial - count_factorial.log_factorial - rest_factorial.log_factorial
      + possible_count.k * LN(mismatch_rate.rate)
      + (player_mismatch.total_sessions - possible_count.k) * LN(1 - mismatch_rate.rate)
    ) AS probability
  FROM player_mismatch
  CROSS JOIN mismatch_rate
  CROSS JOIN LATERAL generate_series(player_mismatch.mismatch_sessions, player_mismatch.total_sessions) AS possible_count(k)
  JOIN log_factorials AS total_factorial
    ON total_factorial.number = player_mismatch.total_sessions
  JOIN log_factorials AS count_factorial
    ON count_factorial.number = possible_count.k
  JOIN log_factorials AS rest_factorial
    ON rest_factorial.number = player_mismatch.total_sessions - possible_count.k
),
player_chance AS (
  SELECT
    chance_terms.player_id,
    SUM(chance_terms.probability) AS chance_probability
  FROM chance_terms
  GROUP BY chance_terms.player_id
)
SELECT
  player_mismatch.player_id,
  player_mismatch.total_sessions,
  player_mismatch.mismatch_sessions,
  ROUND((player_mismatch.total_sessions * mismatch_rate.rate)::numeric, 2) AS expected_by_chance,
  player_mismatch.foreign_countries,
  player_mismatch.first_session_mismatch,
  player_chance.chance_probability
FROM player_mismatch
CROSS JOIN mismatch_rate
JOIN player_chance
  ON player_mismatch.player_id = player_chance.player_id
ORDER BY player_chance.chance_probability;
