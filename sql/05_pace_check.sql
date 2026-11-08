/* Session pace check: is any session faster than humanly possible? Report section 1.5, limitation 12 */
/* The session without spins is excluded (report section 1.3) */


/* Percentiles of spins per minute across sessions with spins */
SELECT
  PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY sessions.spins_per_min) AS median,
  PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY sessions.spins_per_min) AS p90,
  PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY sessions.spins_per_min) AS p99,
  PERCENTILE_CONT(0.999) WITHIN GROUP (ORDER BY sessions.spins_per_min) AS p999
FROM sessions
WHERE sessions.num_spins > 0;


/* Maximum spins per minute */
SELECT
  MAX(sessions.spins_per_min) AS max_spins_per_min
FROM sessions
WHERE sessions.num_spins > 0;
