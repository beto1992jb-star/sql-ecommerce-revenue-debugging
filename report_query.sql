-- Category performance report: delivered orders placed in 2026, excluding test accounts
-- Only categories with at least 30 orders, sorted by net revenue (highest first)

-- FIXED: Pre-aggregate returns by item_id to avoid duplicating order_items rows or revenue
WITH return_by_item AS (
    SELECT r.item_id,
           COUNT(r.return_id) AS return_count,
           COALESCE(SUM(r.refund_amount), 0) AS refund_amount
    FROM returns r
    GROUP BY r.item_id
)
SELECT p.category, -- FIXED: Validated category column reference
       COUNT(DISTINCT o.order_id) AS orders, -- FIXED: Count distinct orders instead of line items
       COUNT(DISTINCT o.customer_id) AS customers, -- FIXED: Count distinct customers instead of line items
       SUM(i.quantity) AS units,
       SUM(i.quantity * i.unit_price) AS gross_revenue,
       COALESCE(SUM(rb.refund_amount), 0) AS refunds, -- FIXED: COALESCE so zero-refund categories like Toys show 0 instead of NULL
       SUM(i.quantity * i.unit_price) - COALESCE(SUM(rb.refund_amount), 0) AS net_revenue, -- FIXED: Net revenue calculation (not profit)
       ROUND(100.0 * COALESCE(SUM(rb.return_count), 0) / NULLIF(COUNT(i.item_id), 0), 1) AS return_rate_pct -- FIXED: 100.0 avoids integer truncation; NULLIF avoids division by zero
FROM products p
INNER JOIN order_items i
    ON i.product_id = p.product_id
INNER JOIN orders o
    ON o.order_id = i.order_id -- FIXED: Correct join key between orders and order_items
LEFT JOIN customers c
    ON c.customer_id = o.customer_id -- FIXED: LEFT JOIN keeps orders even if customer row is missing
LEFT JOIN return_by_item rb
    ON rb.item_id = i.item_id -- FIXED: LEFT JOIN preserves orders without returns (such as Toys)
WHERE o.status = 'delivered'
  AND o.order_date >= '2026-01-01' -- FIXED: Inclusive start date for Jan 1, 2026
  AND o.order_date < '2027-01-01' -- FIXED: Upper bound keeps results strictly within 2026
  AND (c.city IS NULL OR c.city != 'TEST') -- FIXED: Preserves NULL city while excluding 'TEST' accounts
GROUP BY p.category
HAVING COUNT(DISTINCT o.order_id) >= 30 -- FIXED: Filters by unique orders >= 30 (excludes Gift Cards with 23 orders)
ORDER BY net_revenue DESC; -- FIXED: Ordered by net_revenue instead of gross_revenue