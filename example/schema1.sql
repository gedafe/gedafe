-- Schema demonstration Addendum to
-- Gedafe Demo Application 1 - A very simple customers/products/orders database
-- Released as Public Domain. Do with it what you want.

DROP SCHEMA test;
CREATE SCHEMA test;
COMMENT ON SCHEMA test IS 'Gedafe Test Schema';
GRANT ALL ON SCHEMA test TO public;

SET search_path to 'test','public';

DROP TABLE test.example;
DROP SEQUENCE test.example_example_id_seq;
CREATE TABLE example (
	example_id		SERIAL	NOT NULL PRIMARY KEY,
	example_name		TEXT	CHECK (example_name != '')
);
GRANT ALL ON test.example TO PUBLIC ;
GRANT ALL ON test.example_example_id_seq TO PUBLIC ;

