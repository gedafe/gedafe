-- Gedafe Demo Application 1 - A very simple customers/products/orders database
-- Released as Public Domain. Do with it what you want.

--CREATE DATABASE demo1;
COMMENT ON DATABASE demo1 IS 'Gedafe Demo Application 1';

--###################
-- Gedafe Meta Tables
--###################

DROP TABLE meta_fields;
CREATE TABLE meta_fields (
	-- Field Name
	meta_fields_field	NAME	NOT NULL PRIMARY KEY,
	-- Use Widget X. At the moment there is only 'area'
	meta_fields_widget	TEXT,
	-- Copy forward in edit mask when adding several records
	meta_fields_copy	BOOLEAN,
	-- Use ORDER BY function(field) when sorting
	meta_fields_sortfunc	TEXT
);

DROP TABLE meta_tables;
CREATE TABLE meta_tables (
	-- Table Name
	meta_tables_table	NAME	NOT NULL PRIMARY KEY,
	-- Filter table on this column
	meta_tables_filterfirst	NAME,
	-- Hide Table in Front-end
	meta_tables_hide	BOOLEAN
);

GRANT SELECT ON meta_fields, meta_tables TO PUBLIC;


--##########
-- Customer
--##########

DROP TABLE customer;
DROP SEQUENCE customer_customer_id_seq;
CREATE TABLE customer (
	customer_id		SERIAL	NOT NULL PRIMARY KEY,
	customer_name		TEXT	CHECK (customer_name != ''),
	customer_address	TEXT	CHECK (customer_address != '')
);
GRANT ALL ON customer TO PUBLIC ;

-- comments
COMMENT ON TABLE customer IS 'Customers';
COMMENT ON COLUMN customer.customer_id IS 'ID';
COMMENT ON COLUMN customer.customer_name IS 'Name';
COMMENT ON COLUMN customer.customer_address IS 'Address';

-- meta information
INSERT INTO meta_fields VALUES ('customer_address', 'area');

-- combo-box
DROP VIEW customer_combo;
CREATE VIEW customer_combo AS
	SELECT customer_id AS id, customer_name AS text FROM customer;
GRANT SELECT ON customer_combo TO PUBLIC ;


--#########
-- Product
--#########

DROP TABLE product;
DROP SEQUENCE product_product_id_seq;
CREATE TABLE product (
	product_id		SERIAL	NOT NULL PRIMARY KEY,
	product_hid		CHAR(5)	NOT NULL UNIQUE,
	product_description	TEXT	CHECK (product_description != '')
);
GRANT ALL ON product TO PUBLIC ;

-- comments
COMMENT ON TABLE product IS 'Products';
COMMENT ON COLUMN product.product_id IS 'ID';
COMMENT ON COLUMN product.product_hid IS 'HID';
COMMENT ON COLUMN product.product_description IS 'Description';

-- meta information
INSERT INTO meta_fields VALUES ('product_description', 'area');

-- combo-box
DROP VIEW product_combo;
CREATE VIEW product_combo AS
	SELECT product_hid AS id,
		product_description AS text
	FROM product;
GRANT SELECT ON product_combo TO PUBLIC ;

-- hid2id and back
DROP FUNCTION product_hid2id(CHAR(5));
CREATE FUNCTION product_hid2id(CHAR(5)) returns INT4
	AS 'SELECT product_id FROM product WHERE product_hid = $1'
	LANGUAGE 'sql';
DROP FUNCTION product_id2hid(INT4);
CREATE FUNCTION product_id2hid(INT4) returns CHAR(5)
	AS 'SELECT product_hid FROM product WHERE product_id = $1'
	LANGUAGE 'sql';


--#######
-- Order
--#######

DROP TABLE orders;
DROP SEQUENCE orders_orders_id_seq;
CREATE TABLE orders (
	orders_id		SERIAL	NOT NULL PRIMARY KEY,
	orders_date		DATE	NOT NULL DEFAULT CURRENT_DATE,
	orders_customer		INT4	REFERENCES customer,
	orders_product		INT4	REFERENCES product,
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
INSERT INTO meta_fields VALUES ('orders_date', NULL, TRUE);
INSERT INTO meta_fields VALUES ('orders_customer', NULL, TRUE);

-- presentation view
DROP VIEW orders_list;
CREATE VIEW orders_list AS
	SELECT	orders_id, orders_date, customer_name, orders_qty,
		product_hid, product_description, orders_shipped,
		customer_name || ',' || product_hid AS meta_sort
	FROM	orders, customer, product
	WHERE	customer_id = orders_customer AND
		product_id = orders_product;
GRANT SELECT ON orders_list TO PUBLIC;

COMMENT ON TABLE orders_list IS 'Orders';
COMMENT ON COLUMN orders_list.orders_id IS 'ID';
COMMENT ON COLUMN orders_list.orders_date IS 'Date';
COMMENT ON COLUMN orders_list.customer_name IS 'Customer';
COMMENT ON COLUMN orders_list.product_hid IS 'Product';
COMMENT ON COLUMN orders_list.product_description IS 'Product Description';
COMMENT ON COLUMN orders_list.orders_qty IS 'Quantity';
COMMENT ON COLUMN orders_list.orders_shipped IS 'Shipped';


--###############################
-- Report: Due Product Shipments
--###############################

DROP VIEW due_shipments_rep;
CREATE VIEW due_shipments_rep AS
	SELECT SUM(orders_qty) AS orders_total, product_hid, product_description
	FROM orders, product
	WHERE orders_product = product_id AND orders_shipped = FALSE
	GROUP BY product_hid, product_description;

COMMENT ON TABLE due_shipments_rep IS 'Due Product Shipments';
COMMENT ON COLUMN due_shipments_rep.orders_total IS 'Orders';
COMMENT ON COLUMN due_shipments_rep.product_hid IS 'Product';
COMMENT ON COLUMN due_shipments_rep.product_description IS 'Description';

GRANT SELECT ON due_shipments_rep TO PUBLIC;