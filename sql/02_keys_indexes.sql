/* Keys and indexes: run after data load, report section 1.2 */


/* Primary keys */
ALTER TABLE players
    ADD CONSTRAINT players_pkey PRIMARY KEY (player_id);

ALTER TABLE sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (session_id);

ALTER TABLE spins
    ADD CONSTRAINT spins_pkey PRIMARY KEY (spin_id);


/* Foreign keys */
ALTER TABLE sessions
    ADD CONSTRAINT fk_sessions_player
    FOREIGN KEY (player_id) REFERENCES players(player_id);

ALTER TABLE spins
    ADD CONSTRAINT fk_spins_session
    FOREIGN KEY (session_id) REFERENCES sessions(session_id);

ALTER TABLE spins
    ADD CONSTRAINT fk_spins_player
    FOREIGN KEY (player_id) REFERENCES players(player_id);


/* Indexes: joins to parent tables */
CREATE INDEX idx_spins_player_id    ON spins (player_id);
CREATE INDEX idx_spins_session_id   ON spins (session_id);
CREATE INDEX idx_sessions_player_id ON sessions (player_id);


/* Indexes: filters by time */
CREATE INDEX idx_spins_ts           ON spins (ts);
CREATE INDEX idx_sessions_start_ts  ON sessions (start_ts);
CREATE INDEX idx_players_signup_ts  ON players (signup_ts);


/* Indexes: feature_buy spins only */
CREATE INDEX idx_spins_feature_buy_player
    ON spins (player_id)
    WHERE feature_buy = true;


/* Planner statistics */
ANALYZE players;
ANALYZE sessions;
ANALYZE spins;
