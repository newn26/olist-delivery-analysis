-- 02_checks.sql : data-quality checks before analysis
-- Run each check one at a time (cursor on the query, Ctrl+Enter).
USE olist;

-- ---------------------------------------------------------------
-- Check 1: Missing delivery dates by order status
-- Question: which orders have no customer delivery date, and is that expected?
-- Read: 'delivered' orders should almost all have a date; other statuses
--       (shipped, canceled, ...) are expected to be missing it.
-- ---------------------------------------------------------------
SELECT order_status,
       COUNT(*) AS n_orders,
       SUM(order_delivered_customer_date IS NULL) AS missing_delivered_date
FROM orders
GROUP BY order_status
ORDER BY n_orders DESC;

-- ---------------------------------------------------------------
-- Check 2: Orders with more than one review (join fan-out risk)
-- Read: if > 0, joining orders to reviews duplicates those orders.
-- ---------------------------------------------------------------
SELECT COUNT(*) AS orders_with_multiple_reviews
FROM (
  SELECT order_id
  FROM reviews
  GROUP BY order_id
  HAVING COUNT(*) > 1
) AS multi;

-- ---------------------------------------------------------------
-- Check 3: Duplicate keys
-- Read: every number should be 0. These columns are meant to be unique.
-- ---------------------------------------------------------------
SELECT 'orders.order_id' AS key_checked,
       COUNT(*) - COUNT(DISTINCT order_id) AS duplicates FROM orders
UNION ALL
SELECT 'customers.customer_id',
       COUNT(*) - COUNT(DISTINCT customer_id) FROM customers
UNION ALL
SELECT 'products.product_id',
       COUNT(*) - COUNT(DISTINCT product_id) FROM products
UNION ALL
SELECT 'order_items (order_id, order_item_id)',
       COUNT(*) - COUNT(DISTINCT order_id, order_item_id) FROM order_items;

-- ---------------------------------------------------------------
-- Check 4: Impossible dates
-- Question: are there orders delivered before they were purchased?
-- Uses the orders_clean view (dates already converted from text).
-- ---------------------------------------------------------------
SELECT COUNT(*) AS delivered_before_purchase
FROM orders_clean
WHERE delivered_ts < purchase_ts;

-- ---------------------------------------------------------------
-- Check 5: Product categories without an English translation
-- Read: these categories would show as NULL in English in Q2.
-- ---------------------------------------------------------------
SELECT p.product_category_name,
       COUNT(*) AS n_products
FROM products p
LEFT JOIN category_translation t
       ON p.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY n_products DESC;

-- ===============================================================
-- RESULTS (run 2026-11-13) and how each issue is handled
-- ===============================================================
-- Check 1  delivered: 96,478 orders, 8 have no delivery date
--            -> excluded (definition: delivered AND date not null)
--          canceled: 625 orders, 6 have a delivery date
--            -> not analysed (only 'delivered' is used); open question for client
--          shipped / invoiced / processing / unavailable / created / approved:
--            all missing a delivery date -> expected, not yet delivered
-- Check 2  547 orders have more than one review
--            -> fan-out risk; reviews are aggregated to one row per order
--               (average score) before joining. See step 3.
-- Check 3  duplicate keys: 0 in all four checks -> no action needed
-- Check 4  delivered before purchase: 0 -> no action needed
-- Check 5  products with no category (NULL): 610 -> grouped as 'unknown' in Q2
--          categories with no English name: 2
--            portateis_cozinha_e_preparadores_de_alimentos (10 products)
--            pc_gamer (3 products)
--            -> fall back to the Portuguese name with COALESCE
