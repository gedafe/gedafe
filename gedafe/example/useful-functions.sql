-- #########################################################################
-- # Gedafe relies on application logic being implemented in PostgreSQL
-- # here are some code fragments which may help
-- #########################################################################
-- # Tobias Oetiker <oetiker@ee.ethz.ch>
-- #########################################################################

-- Register PLPGSQL
-- ================
-- Without this you will not be able to implement any sensible stored
-- Procedures. Note that you have to adjust the Path to the shared library

create function plpgsql_call_handler() returns opaque
        as '/usr/pack/postgresql-7.0.3-to/lib/plpgsql.so'
        language 'C';

create trusted procedural language 'plpgsql'
        handler plpgsql_call_handler
        lancompiler 'PL/pgSQL';

-- Raise an exception 
-- ==================
-- Sometimes you may want to print an error message to the user.
-- Here is an example how this could be done

CREATE FUNCTION elog(text) RETURNS BOOLEAN 
        AS 'BEGIN RAISE EXCEPTION ''%s'', $1 ; END;' 
	LANGUAGE 'plpgsql';


-- Example use for elog(). This prevents updates to records in the
-- personel table unless they refer to the current user.

CREATE RULE personel_update_test AS 
       ON UPDATE TO personel
       WHERE new.name != old.name OR new.name != current_user
       DO INSTEAD SELECT elog('You can only Update your own Records');


-- Group Membership Test
-- =====================
-- Test if a user is a member of a specific Group

CREATE FUNCTION getgroup(name,int4) RETURNS int4 AS '
     SELECT grolist[$2]
           FROM pg_group
           WHERE groname = $1' LANGUAGE 'sql';

CREATE FUNCTION ingroup(name) RETURNS BOOLEAN AS '
DECLARE
        group ALIAS FOR $1;
        fuid int4;
        uid int4;
        i int4;
BEGIN
  SELECT INTO uid usesysid
         FROM pg_user
         WHERE usename = getpgusername();
  IF NOT FOUND THEN RETURN FALSE; END IF;
  i := 1;
  LOOP  
    SELECT INTO fuid getgroup(group,i);
    IF NOT FOUND THEN RETURN FALSE; END IF;
    IF fuid IS NULL THEN RETURN FALSE; END IF;
    IF fuid = uid THEN RETURN TRUE; END IF;
    i := i+1; 
  END LOOP;
  RETURN FALSE;
END;
' LANGUAGE 'plpgsql';


-- Nice Trim
-- =========
-- Trim a Long Text string in a sensible fashion

DROP FUNCTION nicetrim (text, int4);
CREATE FUNCTION nicetrim (text, int4) RETURNS text AS '
        DECLARE
                str ALIAS FOR $1;
                len ALIAS FOR $2;
        BEGIN
                IF char_length(str) > len THEN
                        RETURN substring(str from 1 for len) || '' [...]'';
                END IF;
                RETURN str;
        END;
' LANGUAGE 'plpgsql';


-- HumanID to ID
-- =============
-- Figure out the id of a record from its hid

CREATE FUNCTION hid2id(NAME) returns int4
       AS 'SELECT personel_id FROM personel WHERE personel_hid = $1 ' 
       LANGUAGE 'sql';



