-- Gedafe Demo Application 1 - A very simple customers/products/orders database
-- Released as Public Domain. Do with it what you want.

DROP DATABASE demo1;
CREATE DATABASE demo1;
COMMENT ON DATABASE demo1 IS 'Gedafe Demo Application 1';

--###################
-- Gedafe Meta Tables
--###################

DROP TABLE meta_tables;
CREATE TABLE meta_tables (
	meta_tables_id	serial NOT NULL PRIMARY KEY,
	-- Table Name
	meta_tables_table	NAME	NOT NULL ,
	-- Attribute
	meta_tables_attribute	TEXT	NOT NULL,
	-- Value
	meta_tables_value	TEXT
);
-- standard attributes: filterfirst, hide

DROP TABLE meta_fields;
CREATE TABLE meta_fields (
        meta_fields_id  serial  NOT NULL PRIMARY KEY,
	-- Table Name
	meta_fields_table	NAME	NOT NULL,
	-- Field Name
	meta_fields_field	NAME	NOT NULL,
	-- Attribute
	meta_fields_attribute	TEXT	NOT NULL,
	-- Value
	meta_fields_value	TEXT
);
-- standard attributes: widget, copy, sortfunc

GRANT SELECT ON meta_fields, meta_tables TO PUBLIC;


--##########
-- Customer
--##########

DROP TABLE customer;
DROP SEQUENCE customer_customer_id_seq;
CREATE TABLE customer (
	customer_id		SERIAL	NOT NULL PRIMARY KEY,
	customer_name		TEXT	CHECK (customer_name != ''),
	customer_address	TEXT	CHECK (customer_address != ''),
	customer_email		TEXT,
	customer_last_modified  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	customer_last_modified_by NAME NOT NULL DEFAULT CURRENT_USER
);
GRANT ALL ON customer TO PUBLIC ;

-- comments
COMMENT ON TABLE customer IS 'Customers';
COMMENT ON COLUMN customer.customer_id IS 'ID';
COMMENT ON COLUMN customer.customer_name IS 'Name';
COMMENT ON COLUMN customer.customer_address IS 'Address';
COMMENT ON COLUMN customer.customer_email IS 'E-mail';
COMMENT ON COLUMN customer.customer_last_modified IS 'Last modified';
COMMENT ON COLUMN customer.customer_last_modified_by IS 'Last modified by';

-- meta information
INSERT INTO meta_fields VALUES (DEFAULT,'customer', 'customer_address', 'widget', 'area');
INSERT INTO meta_fields VALUES (DEFAULT,'customer', 'customer_email', 'markup', 1);

INSERT INTO meta_tables VALUES (DEFAULT,'customer', 'longcomment','Our lovely Customers');
INSERT INTO meta_tables VALUES (DEFAULT, 'customer','editmask','mask_customer');
INSERT INTO meta_tables VALUES (DEFAULT, 'customer','quicklink(1)',
	'foot("http://isg.ee.ethz.ch/tools/gedafe/","","Gedafe Homepage Quicklink") ');

-- combo-box
DROP VIEW customer_combo;
CREATE VIEW customer_combo AS
	SELECT customer_id AS id,
		customer_id || ' -- ' || customer_name AS text
	FROM customer;
GRANT SELECT ON customer_combo TO PUBLIC ;

-- Log timestamp and user
-- ======================
-- Creates a trigger function which saves timestamp and user of
-- last modification
--  Note: you need to register PL/pgSQL (see top of useful-functions.sql)

DROP FUNCTION update_last_modified();
CREATE FUNCTION update_last_modified()
RETURNS OPAQUE
AS  '
BEGIN
	NEW.customer_last_modified_by = CURRENT_USER;
	NEW.customer_last_modified    = CURRENT_TIMESTAMP;
	RETURN NEW;
END;'
LANGUAGE 'plpgsql';

-- trigger before each row update, for logging last modification time with
-- user who modified each record
DROP TRIGGER customer_last_modified ON customer;
CREATE TRIGGER customer_last_modified
  BEFORE UPDATE
  ON customer FOR EACH ROW
  EXECUTE PROCEDURE update_last_modified();


--#########
-- Product
--#########

DROP TABLE product;
DROP SEQUENCE product_product_id_seq;
CREATE TABLE product (
	product_id		SERIAL	NOT NULL PRIMARY KEY,
	product_hid		CHAR(5)	NOT NULL UNIQUE,
	product_description	TEXT	CHECK (product_description != ''),
	product_url		TEXT
);
GRANT ALL ON product TO PUBLIC ;

-- comments
COMMENT ON TABLE product IS 'Products';
COMMENT ON COLUMN product.product_id IS 'ID';
COMMENT ON COLUMN product.product_hid IS 'HID';
COMMENT ON COLUMN product.product_description IS 'Description';
COMMENT ON COLUMN product.product_url IS 'WWW-URL';

-- meta information
INSERT INTO meta_fields VALUES (DEFAULT,'product', 'product_description', 'widget', 'area');
INSERT INTO meta_fields VALUES (DEFAULT,'product', 'product_url', 'markup', 1);

-- make a counting link to orders from product.
-- see the showref section of the gedafe manual for details
INSERT INTO meta_tables VALUES (DEFAULT,'product', 'showref', 'orders');


-- combo-box
DROP VIEW product_combo;
CREATE VIEW product_combo AS
	SELECT product_id AS id,
		product_hid || ' -- ' || product_description AS text
	FROM product;
GRANT SELECT ON product_combo TO PUBLIC ;

--#######
-- Order
--#######

DROP TABLE orders;
DROP SEQUENCE orders_orders_id_seq;
CREATE TABLE orders (
	orders_id		SERIAL	NOT NULL PRIMARY KEY,
	orders_date		DATE	NOT NULL DEFAULT CURRENT_DATE,
	orders_customer		INT4	NOT NULL REFERENCES customer,
	orders_product		INT4	NOT NULL REFERENCES product,
	orders_qty		INT4,
	orders_shipped		BOOLEAN
);
GRANT ALL ON orders TO PUBLIC;

-- comments
COMMENT ON TABLE orders IS 'Orders';
COMMENT ON COLUMN orders.orders_id IS 'ID';
COMMENT ON COLUMN orders.orders_date IS 'Date';
COMMENT ON COLUMN orders.orders_customer IS 'Customer';
COMMENT ON COLUMN orders.orders_product IS 'Product';
COMMENT ON COLUMN orders.orders_qty IS 'Quantity';
COMMENT ON COLUMN orders.orders_shipped IS 'Shipped?';

-- meta information
-- (copy date and customer on the next form while adding)
INSERT INTO meta_fields VALUES (DEFAULT,'orders', 'orders_date', 'copy', '1');
INSERT INTO meta_fields VALUES (DEFAULT,'orders', 'orders_customer', 'copy', '1');
INSERT INTO meta_fields VALUES (DEFAULT,'orders', 'orders_customer', 'widget', 'jsisearch');

-- presentation view
-- note that the customer_name column is renamed tot orders_customer 
-- to make a reference back to the customer column.
-- see the showref section of the gedafe manual for more details
DROP VIEW orders_list;
CREATE VIEW orders_list AS
	SELECT	 orders_id, 
		 orders_date, 
		 customer_name as orders_customer, 
		 orders_qty,
		 product_hid as orders_product, 
		 product_description, 
		 orders_shipped,
		 customer_name || ',' || product_hid AS meta_sort
	FROM	 orders, customer, product
	WHERE	 customer_id = orders_customer AND
		 product_id = orders_product;
GRANT SELECT ON orders_list TO PUBLIC;

--###############################
-- Report: Due Product Shipments
--###############################

DROP VIEW due_shipments_rep;
CREATE VIEW due_shipments_rep AS
	SELECT SUM(orders_qty) AS orders_total, product_hid, product_description
	FROM orders, product
	WHERE orders_product = product_id AND orders_shipped = FALSE
	GROUP BY product_hid, product_description;

COMMENT ON VIEW due_shipments_rep IS 'Due Product Shipments';
COMMENT ON COLUMN due_shipments_rep.orders_total IS 'Orders';

GRANT SELECT ON due_shipments_rep TO PUBLIC;

--#######
-- Filetable
--#######

DROP TABLE filetable;
DROP SEQUENCE filetable_filetable_id_seq;
CREATE TABLE filetable (
	filetable_id		SERIAL	NOT NULL PRIMARY KEY,
	filetable_date		DATE	NOT NULL DEFAULT CURRENT_DATE,
	filetable_file		BYTEA
);

GRANT ALL ON filetable TO PUBLIC;

COMMENT ON TABLE filetable IS 'Filetable';
COMMENT ON COLUMN filetable.filetable_id IS 'ID';
COMMENT ON COLUMN filetable.filetable_date IS 'Date';
COMMENT ON COLUMN filetable.filetable_file IS 'File';

INSERT INTO meta_fields VALUES (DEFAULT,'filetable', 'filetable_date', 'widget', 'date(from=2000,to=2005)');



GRANT ALL ON customer_customer_id_seq TO PUBLIC;
GRANT ALL ON product_product_id_seq TO PUBLIC;
GRANT ALL ON orders_orders_id_seq TO PUBLIC;
GRANT ALL ON filetable_filetable_id_seq TO PUBLIC;
