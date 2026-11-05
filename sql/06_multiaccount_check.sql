/* Multi-account signals: shared devices and IPs, devices per player, overlapping sessions */


/* Devices used by more than one player */
WITH players_per_device AS (
  SELECT
    sessions.device_id_hash,
    COUNT(DISTINCT sessions.player_id) AS players_count
  FROM sessions
  GROUP BY sessions.device_id_hash
)
SELECT
  COUNT(players_per_device.device_id_hash) AS devices,
  COUNT(players_per_device.device_id_hash) FILTER (WHERE players_per_device.players_count > 1) AS shared_devices,
  MAX(players_per_device.players_count) AS max_players_per_device
FROM players_per_device;


/* IPs used by more than one player */
WITH players_per_ip AS (
  SELECT
    sessions.ip_hash,
    COUNT(DISTINCT sessions.player_id) AS players_count
  FROM sessions
  GROUP BY sessions.ip_hash
)
SELECT
  COUNT(players_per_ip.ip_hash) AS ips,
  COUNT(players_per_ip.ip_hash) FILTER (WHERE players_per_ip.players_count > 1) AS shared_ips,
  MAX(players_per_ip.players_count) AS max_players_per_ip
FROM players_per_ip;


/* Distribution of devices per player */
WITH devices_per_player AS (
  SELECT
    sessions.player_id,
    COUNT(DISTINCT sessions.device_id_hash) AS devices_count
  FROM sessions
  GROUP BY sessions.player_id
)
SELECT
  devices_per_player.devices_count,
  COUNT(devices_per_player.player_id) AS players
FROM devices_per_player
GROUP BY devices_per_player.devices_count
ORDER BY devices_per_player.devices_count;


/* Overlapping sessions of the same player */
SELECT
  COUNT(*) AS overlapping_pairs
FROM sessions AS first_session
JOIN sessions AS second_session
  ON first_session.player_id = second_session.player_id
  AND first_session.session_id < second_session.session_id
  AND first_session.start_ts < second_session.end_ts
  AND second_session.start_ts < first_session.end_ts;

/* Players with at least one session on a device shared with another player */
WITH players_per_device AS (
  SELECT
    sessions.device_id_hash,
    COUNT(DISTINCT sessions.player_id) AS players_count
  FROM sessions
  GROUP BY sessions.device_id_hash
),
shared_device_players AS (
  SELECT DISTINCT
    sessions.player_id
  FROM sessions
  JOIN players_per_device
    ON sessions.device_id_hash = players_per_device.device_id_hash
    AND players_per_device.players_count > 1
)
SELECT
  COUNT(shared_device_players.player_id) AS players_with_shared_device,
  ROUND(100.0 * COUNT(shared_device_players.player_id) / (SELECT COUNT(DISTINCT sessions.player_id) FROM sessions), 1) AS players_with_shared_device_pct
FROM shared_device_players;


/* Players with at least two overlapping sessions */
SELECT
  COUNT(DISTINCT first_session.player_id) AS players_with_overlap,
  ROUND(100.0 * COUNT(DISTINCT first_session.player_id) / (SELECT COUNT(DISTINCT sessions.player_id) FROM sessions), 1) AS players_with_overlap_pct
FROM sessions AS first_session
JOIN sessions AS second_session
  ON first_session.player_id = second_session.player_id
  AND first_session.session_id < second_session.session_id
  AND first_session.start_ts < second_session.end_ts
  AND second_session.start_ts < first_session.end_ts;
