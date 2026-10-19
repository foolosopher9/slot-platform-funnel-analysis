/* Primary keys, foreign keys and indexes (run after data load) */


/* Primary keys */
ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_pkey PRIMARY KEY (player_id);

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (session_id);

ALTER TABLE ONLY public.spins
    ADD CONSTRAINT spins_pkey PRIMARY KEY (spin_id);


/* Foreign keys */
ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT fk_sessions_player
    FOREIGN KEY (player_id) REFERENCES public.players(player_id);

ALTER TABLE ONLY public.spins
    ADD CONSTRAINT fk_spins_session
    FOREIGN KEY (session_id) REFERENCES public.sessions(session_id);

ALTER TABLE ONLY public.spins
    ADD CONSTRAINT fk_spins_player
    FOREIGN KEY (player_id) REFERENCES public.players(player_id);


/* Indexes: joins from spins and sessions to their parents */
CREATE INDEX idx_spins_player_id    ON spins (player_id);
CREATE INDEX idx_spins_session_id   ON spins (session_id);
CREATE INDEX idx_sessions_player_id ON sessions (player_id);


/* Indexes: filters by time */
CREATE INDEX idx_spins_ts           ON spins (ts);
CREATE INDEX idx_sessions_start_ts  ON sessions (start_ts);
CREATE INDEX idx_players_signup_ts  ON players (signup_ts);


/* Index: rare feature_buy spins only */
CREATE INDEX idx_spins_feature_buy_player
    ON spins (player_id)
    WHERE feature_buy = true;


/* Planner statistics */
ANALYZE public.players;
ANALYZE public.sessions;
ANALYZE public.spins;
