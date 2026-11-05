/* Loss before bet spike: checks of the 10-spin window, report section 2.4 */


/* Spins with fewer than 10 previous spins in their session: spikes vs ordinary spins */
WITH numbered_spins AS (
  SELECT
    spins.spin_id,
    spins.player_id,
    spins.ts,
    spins.feature_buy,
    ROW_NUMBER() OVER (
      PARTITION BY spins.session_id
      ORDER BY spins.ts, spins.spin_id
    ) AS spin_number
  FROM spins
)
SELECT
  numbered_spins.feature_buy,
  COUNT(*) AS spins_count,
  COUNT(*) FILTER (WHERE numbered_spins.spin_number <= 10) AS short_history_spins,
  ROUND(100.0 * COUNT(*) FILTER (WHERE numbered_spins.spin_number <= 10) / COUNT(*), 1) AS short_history_pct
FROM numbered_spins
JOIN players
  ON numbered_spins.player_id = players.player_id
  AND numbered_spins.ts < players.signup_ts + INTERVAL '90 days'
GROUP BY numbered_spins.feature_buy
ORDER BY numbered_spins.feature_buy;


/* Spins with a previous spike in their 10-spin window: spikes vs ordinary spins */
WITH numbered_spins AS (
  SELECT
    spins.spin_id,
    spins.player_id,
    spins.ts,
    spins.feature_buy,
    ROW_NUMBER() OVER (
      PARTITION BY spins.session_id
      ORDER BY spins.ts, spins.spin_id
    ) AS spin_number,
    SUM(spins.feature_buy::int) OVER (
      PARTITION BY spins.session_id
      ORDER BY spins.ts, spins.spin_id
      ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING
    ) AS spikes_in_window
  FROM spins
)
SELECT
  numbered_spins.feature_buy,
  COUNT(*) AS full_window_spins,
  COUNT(*) FILTER (WHERE numbered_spins.spikes_in_window > 0) AS spike_in_window_spins,
  ROUND(100.0 * COUNT(*) FILTER (WHERE numbered_spins.spikes_in_window > 0) / COUNT(*), 1) AS spike_in_window_pct
FROM numbered_spins
JOIN players
  ON numbered_spins.player_id = players.player_id
  AND numbered_spins.ts < players.signup_ts + INTERVAL '90 days'
WHERE numbered_spins.spin_number > 10
GROUP BY numbered_spins.feature_buy
ORDER BY numbered_spins.feature_buy;
