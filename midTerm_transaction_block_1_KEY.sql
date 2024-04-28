/*
    Creation Script for mid-term project


    Run the following commands once.

    CREATE SCHEMA IF NOT EXISTS rps;
    SET SEARCH_PATH TO rps;

    CREATE SEQUENCE IF NOT EXISTS seq_rps;
    -- If we DROP the SEQUENCE, then we must CASCADE because it's a default.
    -- We will CREATE SEQUENCE outside the transaction block but inside the
    -- rps schema.
*/
DO $outer_block_1$
BEGIN
    DO $drop_tables$
    BEGIN

        DROP TABLE IF EXISTS tbl_rounds;
        DROP TABLE IF EXISTS tbl_games;
        DROP TABLE IF EXISTS tbl_players;

        DROP TABLE IF EXISTS tbl_errata; -- has no foreign keys

    EXCEPTION
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0010';
    END $drop_tables$;
    -- ----------------------------------------------------------

    DO $tbl_errata$
    BEGIN

        -- This one is quick & dirty
        CREATE TABLE tbl_errata
        (
            fld_sqlstate    CHAR(5),
            fld_sqlerrm     TEXT,
            fld_err_doc     TIMESTAMP DEFAULT NOW()
        );

    EXCEPTION
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0011';
    END $tbl_errata$;

    -- ----------------------------------------------------------

    DO $tbl_players$  -- block names may vary
    BEGIN

        CREATE TABLE tbl_players
        (
            fld_p_id_pk   CHAR(16), -- any text type
            fld_p_doc     TIMESTAMP DEFAULT NOW(),
            --
            CONSTRAINT players_pk PRIMARY KEY(fld_p_id_pk)
        );

    EXCEPTION
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0012';
    END $tbl_players$;

    -- ----------------------------------------------------------

    DO $tbl_games$
    BEGIN

        CREATE TABLE tbl_games
        (
            fld_g_id_pk     BIGINT DEFAULT NEXTVAL('seq_rps'),  -- primary key
            fld_g_doc       TIMESTAMP DEFAULT NOW(),
            fld_p_id1_fk    CHAR(16), -- foreign key into players
            fld_p_id2_fk    CHAR(16), -- foreign key into players
            --
            CONSTRAINT games_pk PRIMARY KEY(fld_g_id_pk),
            CONSTRAINT games_fk1 FOREIGN KEY(fld_p_id1_fk)
                                        REFERENCES tbl_players(fld_p_id_pk),
            CONSTRAINT games_fk2 FOREIGN KEY(fld_p_id2_fk)
                                        REFERENCES tbl_players(fld_p_id_pk),
            CONSTRAINT player_order CHECK(fld_p_id1_fk < fld_p_id2_fk),
            CONSTRAINT unique_pair UNIQUE(fld_p_id1_fk, fld_p_id2_fk)
        );

    EXCEPTION
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0013';
    END $tbl_games$;

    -- ----------------------------------------------------------

    DO $tbl_rounds$
    BEGIN

        CREATE TABLE tbl_rounds
        (
            fld_r_id_pk     BIGINT DEFAULT NEXTVAL('seq_rps'),  -- primary key
            fld_r_doc       TIMESTAMP DEFAULT NOW(),
            fld_r_p1token   CHAR(1),
            fld_r_p2token   CHAR(1),
            fld_g_id_fk     BIGINT,  -- foreign key into games
            --
            CONSTRAINT rounds_pk PRIMARY KEY(fld_r_id_pk),
            CONSTRAINT valid_tokens CHECK(  fld_r_p1token IN ('R', 'P', 'S')
                                                        AND
                                             fld_r_p2token IN ('R', 'P', 'S')
                                          ),
            CONSTRAINT rounds_fk FOREIGN KEY(fld_g_id_fk) REFERENCES tbl_games(fld_g_id_pk)

        );

        EXCEPTION
            WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0014';
    END $tbl_rounds$;

    -- If we get here, SUCCESS!!!
    RAISE INFO E'\n\n\n  Creation Script One Completes Successfully.\n\n\n';

EXCEPTION
    WHEN SQLSTATE 'P0010' THEN
        RAISE INFO E'\n\n\n  Block drop_tables failed.\n\n\n';
    WHEN SQLSTATE 'P0011' THEN
        RAISE INFO E'\n\n\n  Block tbl_errata failed.\n\n\n';
    WHEN SQLSTATE 'P0012' THEN
        RAISE INFO E'\n\n\n  Block tbl_players failed.\n\n\n';
    WHEN SQLSTATE 'P0013' THEN
        RAISE INFO E'\n\n\n  Block tbl_games failed.\n\n\n';
    WHEN SQLSTATE 'P0014' THEN
        RAISE INFO E'\n\n\n  Block tbl_rounds failed.\n\n\n';

    -- Do not change the next entry!
    WHEN OTHERS THEN
        RAISE EXCEPTION E'\n\n\nUnknown Error: sqlstate %, sqlerrm %.\n\n\n',
                                                    SQLSTATE, SQLERRM;
END $outer_block_1$;
