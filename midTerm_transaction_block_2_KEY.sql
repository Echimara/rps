DO $outer_block_2$
BEGIN
    DO $create_player$
    BEGIN

    DROP PROCEDURE IF EXISTS proc_insert_player;

    CREATE OR REPLACE PROCEDURE proc_insert_player
    (
        IN parm_p_id CHAR(16),
        OUT parm_errlvl SMALLINT
        -- I use INTEGER for parm_errlvl because we plan a
        -- front end and PHP has no SMALLINT.
    )
    --  Error codes:  0 --> success, 1 --> NULL pid, 2 --> player already exists
    --               99 --> unexpected error (exception logged)
    -- document your error codes here!  They don't have to be exactly my suggested
    -- codes.  Document them whatever they are!

    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $GO$
    -- DECLARE
    --  This is where we'd define local variables if we needed any.

    BEGIN
        -- if we throw the exception, we never get here.
        parm_errlvl := 0;

        -- first, check what we can by simply looking before we search any tables

        IF parm_p_id IS NULL OR LENGTH(parm_p_id) = 0
        THEN
            parm_errlvl := 1;
        ELSEIF
            EXISTS(             -- check that the ID isn't in use.
                    SELECT *
                    FROM rps.tbl_players
                    WHERE fld_p_id_pk = parm_p_id
                   )
            THEN
                parm_errlvl := 2; -- already in table
            ELSE
                INSERT INTO rps.tbl_players(fld_p_id_pk) -- the timestamp defaults to NOW()
                VALUES (parm_p_id);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            INSERT INTO rps.tbl_errata(fld_SQLERRM, fld_SQLSTATE)
            VALUES (SQLERRM, SQLSTATE);

            RAISE WARNING 'exception: "%" logged, SQLSTATE = %', SQLERRM, SQLSTATE;
            -- The warning displayed on the console is optional and usually not
            -- implemented.  Often, a database won't have a console operator.

            parm_errlvl := -13; -- unexpected error
    END $GO$;


    EXCEPTION -- transaction block
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0100';
    END $create_player$;

    -- ----------------------------------------------------------



    DO $create_game$
    BEGIN

        DROP PROCEDURE IF EXISTS proc_insert_game;

        CREATE OR REPLACE PROCEDURE proc_insert_game
        (
            IN parm_p1_id CHAR(16),
            IN parm_p2_id CHAR(16),
            OUT parm_errlvl SMALLINT
        )
        --  Error codes:  0 --> success, 1 --> local issue with parameters
        --                2 --> either p1 or p2 invalid, 3 --> game already exists
        --                99 --> unexpected error (exception logged)

        LANGUAGE plpgsql
        SECURITY DEFINER
        AS $GO$
        DECLARE
            lv_p1_id CHAR(16);
            lv_p2_id CHAR(16);
            -- PostgreSQL will allow changing a value parameter like C,
            -- but most database languages won't, so we'll make local
            -- copies to modify.
            lv_gid  BIGINT;
            lv_p SMALLINT;
        BEGIN
            -- Check for reversed parameters
            IF parm_p1_id > parm_p2_id
            THEN
                -- If they're reversed, just fix them & continue.
                lv_p1_id := parm_p2_id;
                lv_p2_id := parm_p1_id;
            ELSE
                lv_p1_id := parm_p1_id;
                lv_p2_id := parm_p2_id;
            END IF;

            parm_errlvl := 0;

            lv_p := LENGTH(lv_p1_id) * LENGTH(lv_p2_id);
            
            IF(lv_p IS NULL OR lv_p = 0 OR lv_p1_id = lv_p2_id)
            THEN
                parm_errlvl := 1;
            ELSIF
                    NOT EXISTS
                    (             -- check that the PIDs are in tbl_players.
                        SELECT *
                        FROM rps.tbl_players
                        WHERE fld_p_id_pk = lv_p1_id
                    )
                        OR
                    NOT EXISTS
                    (
                        SELECT *
                        FROM rps.tbl_players
                        WHERE fld_p_id_pk = lv_p2_id
                    )
                THEN
                    parm_errlvl := 2;
                ELSIF rps.func_get_game_id(lv_p1_id, lv_p2_id) IS NOT NULL
                    THEN
                        parm_errlvl := 3;
                    ELSE
                        INSERT INTO rps.tbl_games
                                (fld_p_id1_fk, fld_p_id2_fk)
                        VALUES(lv_p1_id, lv_p2_id );
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                INSERT INTO rps.tbl_errata(fld_SQLERRM, fld_SQLSTATE)
                VALUES (SQLERRM, SQLSTATE);

                RAISE WARNING 'exception: "%" logged, SQLSTATE = %', SQLERRM, SQLSTATE;

                parm_errlvl := 99; -- unexpected error
        END $GO$;


    EXCEPTION -- transaction block
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0101';
    END $create_game$;

    -- ----------------------------------------------------------

    DO $create_round$
    BEGIN

        DROP PROCEDURE IF EXISTS proc_insert_round;

        CREATE OR REPLACE PROCEDURE proc_insert_round
        (
            IN parm_p1_id CHAR(16),
            IN parm_p2_id CHAR(16),
            IN parm_p1_tok CHAR(1),
            IN parm_p2_tok CHAR(1),
            OUT parm_errlvl SMALLINT
        )
        --  Error codes:  0 --> success, 1 --> unable to resolve Game ID,
        --                2 --> NULL or invalid token
        --               99 --> unexpected error (exception logged)
        -- Student's codes may vary

        LANGUAGE plpgsql
        SECURITY DEFINER
        AS $GO$
        DECLARE
            lv_p1_tok CHAR(1);
            lv_p2_tok CHAR(1);
            lv_game_id BIGINT := rps.func_get_game_id(parm_p1_id, parm_p2_id);
        BEGIN
            parm_errlvl := 0;

            IF lv_game_id IS NULL
            THEN parm_errlvl := 1;
            ELSIF lv_game_id < 0
                THEN
                    lv_p1_tok := parm_p2_tok;
                    lv_p2_tok := parm_p1_tok;
                    lv_game_id := lv_game_id*-1;
                ELSE
                    lv_p1_tok := parm_p1_tok;
                    lv_p2_tok := parm_p2_tok;
            END IF;

            IF  lv_p1_tok NOT IN ('R', 'P', 'S')
                            OR
                lv_p2_tok NOT IN ('R', 'P', 'S')
            THEN parm_errlvl := 2;

            ELSE
                INSERT INTO rps.tbl_rounds(fld_g_id_fk, fld_r_p1token, fld_r_p2token)
                VALUES(lv_game_id, lv_p1_tok, lv_p2_tok);
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                INSERT INTO rps.tbl_errata(fld_SQLERRM, fld_SQLSTATE)
                VALUES (SQLERRM, SQLSTATE);

                RAISE WARNING 'exception: "%" logged, SQLSTATE = %', SQLERRM, SQLSTATE;
                -- The warning displayed on the console is optional and usually not
                -- implemented.  Often, a database won't have a console operator.

                parm_errlvl := 99; -- unexpected error
        END $GO$;


    EXCEPTION -- transaction block
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0102';
    END $create_round$;

    -- ----------------------------------------------------------

    DO $get_game_id$
    BEGIN

        DROP FUNCTION IF EXISTS func_get_game_id;


        CREATE OR REPLACE FUNCTION func_get_game_id( arg_p1 CHAR(16), arg_p2 CHAR(16))      RETURNS BIGINT
        LANGUAGE plpgsql
        SECURITY INVOKER
        AS $GO$
        DECLARE
            lv_p1   CHAR(16);
            lv_p2   CHAR(16);
            lv_sign  SMALLINT;
            lv_gid   BIGINT;
        BEGIN
            IF arg_p1 > arg_p2
            THEN
                lv_p1 := arg_p2;
                lv_p2 := arg_p1;

                lv_sign := -1;
            ELSE
                lv_p1 := arg_p1;
                lv_p2 := arg_p2;

                lv_sign := 1;
            END IF;

            SELECT fld_g_id_pk INTO lv_gid
            FROM rps.tbl_games
            WHERE fld_p_id1_fk = lv_p1 AND fld_p_id2_fk = lv_p2;

            RETURN lv_gid * lv_sign;

        END $GO$;


    EXCEPTION -- transaction block
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0103';
    END $get_game_id$; -- syntax variations allowed

    -- ----------------------------------------------------------

    DO $grant_privileges$
    BEGIN

        GRANT CONNECT ON DATABASE db55 TO public_Users;
            -- db55 is *my* home database.  Yours will probably vary!
            -- It has to be *your* home database.

        GRANT USAGE ON SCHEMA rps TO public_Users;

        GRANT EXECUTE ON PROCEDURE proc_insert_player TO public_Users;
        GRANT EXECUTE ON PROCEDURE proc_insert_game TO public_Users;
        GRANT EXECUTE ON PROCEDURE proc_insert_round TO public_Users;


            -- This is the Big Kahuna!  Any user member of role "public_Users"
            -- (user jqpublic, for example) may connect to my database, may set
            -- their SEARCH_PATH to rps, and may execute the procedures

            -- If the procedures run as SECURITY DEFINER, then *the procedures*
            -- have full access to your tables; however, the user does *not*!

            -- And that's the whole point of what we're doing.


    EXCEPTION -- transaction block
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0104';
    END $grant_privileges$;

    -- ----------------------------------------------------------

    -- If we get here, SUCCESS!!!
    RAISE INFO E'\n\n\n  Creation Script 2 Completes Successfully.\n\n\n';

EXCEPTION

    WHEN SQLSTATE 'P0100' THEN
        RAISE INFO E'\n\n\n  Block create_player failed.\n\n\n';
    WHEN SQLSTATE 'P0101' THEN
        RAISE INFO E'\n\n\n  Block create_game failed.\n\n\n';
    WHEN SQLSTATE 'P0102' THEN
        RAISE INFO E'\n\n\n  Block create_round failed.\n\n\n';
    WHEN SQLSTATE 'P0103' THEN
        RAISE INFO E'\n\n\n  Block get_game_id failed.\n\n\n';
    WHEN SQLSTATE 'P0104' THEN
        RAISE INFO E'\n\n\n  Block grant_privileges failed.\n\n\n';

    -- Do not change the next entry!
    WHEN OTHERS THEN
        RAISE EXCEPTION E'\n\n\nUnknown Error: sqlstate %, sqlerrm %.\n\n\n',
                                                    SQLSTATE, SQLERRM;
END $outer_block_2$;

-------------------------

-- Testing
-- Start psql
-- su to user jqpublic
-- Connect to your home database... the one in grant_privileges block


/*
    SET SEARCH_PATH TO RPS;
    CALL proc_create_player();
    CALL proc_create_game();
    CALL proc_create_round();

    This is simply demonstrating that the stubs connect; it isn't *nearly*
    enough testing.

    We will be doing quite a bit of testing with a public user.  I named the
    one we set up: "jqpublic", but any user works as long as they're also
    created in PostgreSQL.

        Error messages when jqpublic starts & exits psql:

    When you su to jqpublic and start plsql, you will see a petulant error
    message that it couldn't change to your home directory.  To fix this,
    set the permissions on your home directory to 755.

    When jqpublic exits psql, there's another error message.  To eliminate
    that one, use sudo to create the directory /home/jqpublic and chown
    to jqpublic.

    Or you may simply ignore the messages... a "petulant" error message is
    just obnoxious, but does not need your immediate attention.
*/

/*
-- An example of testing:
    DO $GO$
    -- Assumptions:
    --  Empty Tables
    --  user:   jqpublic
    --  schema: rps
    DECLARE
        lv_errlvl   SMALLINT;
    BEGIN
        CALL proc_insert_player('Al', lv_errlvl);
        RAISE INFO '%', lv_errlvl;  -- expect zero.
    END $GO$;
    -- It is *not* a database error if the procedure returns an integer
    -- other than zero... that means the code caught it before it tried
    -- to insert it.
*/


/*
    Some advice (that you likely already know): do *not* type in the whole
    thing and try to compile.  Edit *one* transaction block and get that
    running and tested.  Then move to the next one.  Typing it all in,
    then compiling, is known as "Big Bang Programming".
*/

SELECT 'Done' AS done;


-- TRUNCATE tbl_players CACSADE;
-- TRUNCATE tbl_games CACSADE;
-- TRUNCATE tbl_rounds CACSADE;
-- TRUNCATE tbl_errata CACSADE;

-- Do validation within index.html if the code is all done