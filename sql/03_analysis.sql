-- 03_analysis.sql : the three analysis questions
-- All queries use the view delivered_orders (one row per delivered order, see 01_schema.sql).
USE olist;

-- ===============================================================
-- Q1. Does late delivery lower review scores?
-- Definitions: days_late = delivery date - estimated date (days).
--   Buckets: on time or early (<= 0), 1-3, 4-7, 8+ days late.
--   Review score = average of the order's reviews (547 orders have more than one).
--   Low review = order's average score <= 2.
--   Orders with no review (646) are excluded from score columns only.
-- How to read: compare avg_score and pct_low_review down the buckets.
--   If lateness hurts satisfaction, the score falls and the low share rises.
-- ===============================================================
SELECT lateness_bucket,
       COUNT(*)                                       AS n_orders,
       COUNT(avg_review_score)                        AS n_reviewed,
       ROUND(AVG(avg_review_score), 2)                AS avg_score,
       ROUND(100 * AVG(avg_review_score <= 2), 1)     AS pct_low_review
FROM delivered_orders
GROUP BY lateness_bucket
ORDER BY lateness_bucket;

-- ===============================================================
-- Q2. Which product categories are the worst?
-- Definitions: category = English name, Portuguese name if no translation,
--   'unknown' if the product has no category.
--   An order with items in two categories counts once in each category;
--   DISTINCT stops an order with 3 items of the same category counting 3 times.
--   Late = days_late > 0. Minimum volume: 100 delivered orders per category.
-- How to read: categories at the top have the highest late-delivery rate.
-- ===============================================================
SELECT category,
       COUNT(*)                                 AS n_orders,
       ROUND(100 * AVG(days_late > 0), 1)       AS pct_late,
       ROUND(AVG(avg_review_score), 2)          AS avg_score
FROM (
  SELECT DISTINCT
         d.order_id,
         d.days_late,
         d.avg_review_score,
         COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category
  FROM delivered_orders d
  JOIN order_items i ON d.order_id = i.order_id
  JOIN products p    ON i.product_id = p.product_id
  LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
) AS order_category
GROUP BY category
HAVING n_orders >= 100
ORDER BY pct_late DESC
LIMIT 10;

-- ===============================================================
-- Q3. Where is lateness concentrated geographically?
-- Definitions: state = customer_state of the order's customer.
--   Late = days_late > 0. Minimum volume: 100 delivered orders per state.
-- How to read: states at the top have the highest late-delivery rate;
--   n_late shows how many late orders that is in absolute terms.
-- ===============================================================
SELECT c.customer_state,
       COUNT(*)                                 AS n_orders,
       SUM(d.days_late > 0)                     AS n_late,
       ROUND(100 * AVG(d.days_late > 0), 1)     AS pct_late,
       ROUND(AVG(d.avg_review_score), 2)        AS avg_score
FROM delivered_orders d
JOIN customers c ON d.customer_id = c.customer_id
GROUP BY c.customer_state
HAVING n_orders >= 100
ORDER BY pct_late DESC;
