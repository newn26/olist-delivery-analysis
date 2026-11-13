-- 01_schema.sql : create tables, load the Kaggle CSVs, add indexes and views
-- Run with: mysql --local-infile=1 -u root -p < sql/01_schema.sql
-- Before running: download the CSVs from Kaggle (olistbr/brazilian-ecommerce)
-- into a data/ folder and run mysql from the repo root (paths below are relative).
-- The server must allow local loads: SET GLOBAL local_infile = 1;

DROP DATABASE IF EXISTS olist;
CREATE DATABASE olist CHARACTER SET utf8mb4;
USE olist;

-- ---------- Tables (dates kept as text; converted in orders_clean) ----------
CREATE TABLE orders (
  order_id VARCHAR(40), customer_id VARCHAR(40), order_status VARCHAR(20),
  order_purchase_timestamp VARCHAR(25), order_approved_at VARCHAR(25),
  order_delivered_carrier_date VARCHAR(25), order_delivered_customer_date VARCHAR(25),
  order_estimated_delivery_date VARCHAR(25));

CREATE TABLE order_items (
  order_id VARCHAR(40), order_item_id INT, product_id VARCHAR(40), seller_id VARCHAR(40),
  shipping_limit_date VARCHAR(25), price DECIMAL(10,2), freight_value DECIMAL(10,2));

CREATE TABLE reviews (
  review_id VARCHAR(40), order_id VARCHAR(40), review_score INT,
  review_creation_date VARCHAR(25), review_answer_timestamp VARCHAR(25));

CREATE TABLE products (
  product_id VARCHAR(40), product_category_name VARCHAR(80));

CREATE TABLE customers (
  customer_id VARCHAR(40), customer_unique_id VARCHAR(40),
  customer_zip_code_prefix VARCHAR(10), customer_city VARCHAR(80), customer_state VARCHAR(5));

CREATE TABLE category_translation (
  product_category_name VARCHAR(80), product_category_name_english VARCHAR(80));

-- ---------- Load CSVs ----------
-- ESCAPED BY '' : review text contains backslashes that would otherwise break rows.
-- The reviews and translation files use Windows line endings (\r\n).
LOAD DATA LOCAL INFILE 'data/olist_orders_dataset.csv'
INTO TABLE orders CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '' LINES TERMINATED BY '\n' IGNORE 1 LINES
(order_id, customer_id, order_status, order_purchase_timestamp, @appr, @carr, @cust, @est)
SET order_approved_at             = NULLIF(@appr, ''),
    order_delivered_carrier_date  = NULLIF(@carr, ''),
    order_delivered_customer_date = NULLIF(@cust, ''),
    order_estimated_delivery_date = NULLIF(@est, '');

LOAD DATA LOCAL INFILE 'data/olist_order_items_dataset.csv'
INTO TABLE order_items CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/olist_order_reviews_dataset.csv'
INTO TABLE reviews CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '' LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(review_id, order_id, review_score, @title, @msg, review_creation_date, review_answer_timestamp);

LOAD DATA LOCAL INFILE 'data/olist_products_dataset.csv'
INTO TABLE products CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '' LINES TERMINATED BY '\n' IGNORE 1 LINES
(product_id, @cat, @d1, @d2, @d3, @d4, @d5, @d6, @d7)
SET product_category_name = NULLIF(@cat, '');

LOAD DATA LOCAL INFILE 'data/olist_customers_dataset.csv'
INTO TABLE customers CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/product_category_name_translation.csv'
INTO TABLE category_translation CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;

-- ---------- Indexes ----------
CREATE INDEX idx_orders_id     ON orders(order_id);
CREATE INDEX idx_items_order   ON order_items(order_id);
CREATE INDEX idx_reviews_order ON reviews(order_id);

-- ---------- View 1: convert text dates to real dates ----------
CREATE VIEW orders_clean AS
SELECT order_id, customer_id, order_status,
  STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s') AS purchase_ts,
  STR_TO_DATE(NULLIF(order_delivered_customer_date, ''), '%Y-%m-%d %H:%i:%s') AS delivered_ts,
  STR_TO_DATE(order_estimated_delivery_date, '%Y-%m-%d %H:%i:%s') AS estimated_ts
FROM orders;

-- ---------- View 2: one row per delivered order ----------
-- Delivered order = status 'delivered' AND delivery date not null.
-- Reviews are averaged per order first, so orders with several reviews
-- are not counted twice (547 orders have more than one review).
-- LEFT JOIN keeps delivered orders that have no review (score = NULL);
-- they still count for late-delivery rates but not for review averages.
CREATE VIEW delivered_orders AS
SELECT o.order_id,
       o.customer_id,
       o.purchase_ts,
       o.delivered_ts,
       o.estimated_ts,
       DATEDIFF(o.delivered_ts, o.estimated_ts) AS days_late,
       CASE
         WHEN DATEDIFF(o.delivered_ts, o.estimated_ts) <= 0 THEN '0) on time or early'
         WHEN DATEDIFF(o.delivered_ts, o.estimated_ts) <= 3 THEN '1) 1-3 days late'
         WHEN DATEDIFF(o.delivered_ts, o.estimated_ts) <= 7 THEN '2) 4-7 days late'
         ELSE '3) 8+ days late'
       END AS lateness_bucket,
       r.avg_review_score,
       r.n_reviews
FROM orders_clean o
LEFT JOIN (
  SELECT order_id,
         AVG(review_score) AS avg_review_score,
         COUNT(*)          AS n_reviews
  FROM reviews
  GROUP BY order_id
) r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.delivered_ts IS NOT NULL;
