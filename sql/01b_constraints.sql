-- Primary keys
ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_pkey PRIMARY KEY (player_id);

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (session_id);

ALTER TABLE ONLY public.spins
    ADD CONSTRAINT spins_pkey PRIMARY KEY (spin_id);

-- Foreign keys
ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT fk_sessions_player
    FOREIGN KEY (player_id) REFERENCES public.players(player_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.spins
    ADD CONSTRAINT fk_spins_session
    FOREIGN KEY (session_id) REFERENCES public.sessions(session_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.spins
    ADD CONSTRAINT fk_spins_player
    FOREIGN KEY (player_id) REFERENCES public.players(player_id) ON DELETE CASCADE;

-- Refresh planner statistics after constraint creation
ANALYZE public.players;
ANALYZE public.sessions;
ANALYZE public.spins;
