# SQL E-Commerce Revenue Debugging & Refactoring

Case study focused on auditing, debugging, and refactoring a multi-table SQLite reporting query (`report_query.sql`) executed via Python (`run_sql.py`) against an e-commerce database (`store2.db`).

## Overview

The original reporting query produced runtime errors and distorted category-level KPIs due to broken join keys, row-multiplication in aggregations, `NULL` propagation, and missing data quality filters. The refactored query accurately computes category performance across **orders**, **customers**, **units**, **gross revenue**, **refunds**, **net revenue**, and **return rate (%)**.

## Key Issues Resolved

1. **Column Reference Fix:** Corrected invalid column alias reference (`p.category`) that caused a `no such column` execution failure.
2. **Join Key Correction:** Fixed incorrect join condition (`o.order_id = i.item_id`) so order items properly map to their parent orders.
3. **Preserving Zero-Return Categories:** Replaced `INNER JOIN` on `returns` with `LEFT JOIN` so categories without refunds (e.g., *Toys*) are retained in the report.
4. **NULL Refund Handling:** Wrapped refund aggregations with `COALESCE(..., 0)` to prevent `NULL` values from propagating into `net_revenue`.
5. **Preventing Count Inflation:** Applied `COUNT(DISTINCT ...)` for order and customer metrics to avoid overcounting caused by one-to-many item joins.
6. **Inclusive Date Boundaries:** Updated date filter from `>` to `>=` (`2026-01-01`) and added an upper bound (`< '2027-01-01'`) to capture the full target year.
7. **Safe Test-Account Filtering:** Updated `city != 'TEST'` to `(city IS NULL OR city != 'TEST')` so valid customers with unknown cities are not silently excluded.
8. **Floating-Point Return Rate:** Replaced integer division (`100 * a / b`) with `100.0` and `NULLIF(..., 0)` to preserve decimal precision and prevent division-by-zero errors.
9. **Accurate Order Thresholds:** Changed `HAVING COUNT(*)` to `HAVING COUNT(DISTINCT o.order_id) >= 30` so categories are filtered by unique orders rather than line items.
10. **Requested Sorting:** Updated `ORDER BY` to rank categories by `net_revenue` descending.

## Verified Output

| category | orders | customers | units | gross_revenue | refunds | net_revenue | return_rate_pct |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| **Electronics** | 637 | 324 | 1,760 | 118,400,075.37 | 6,482,209.48 | 111,917,865.89 | 7.80 |
| **Home** | 489 | 290 | 1,254 | 44,913,288.85 | 3,567,260.89 | 41,346,027.96 | 8.90 |
| **Sports** | 206 | 170 | 450 | 19,475,031.58 | 887,990.12 | 18,587,041.46 | 7.90 |
| **Fashion** | 460 | 270 | 1,129 | 22,549,680.99 | 7,103,980.63 | 15,445,700.36 | 40.90 |
| **Toys** | 270 | 196 | 599 | 8,587,402.11 | 0.00 | 8,587,402.11 | 0.00 |

## Repository Structure

- `report_query.sql` — Refactored SQLite query with inline fix annotations.
- `run_sql.py` — Python runner script executing the query against `store2.db`.
- `store2.db` — Sample SQLite database (`orders`, `order_items`, `products`, `returns`, `customers`).

## How to Run

```bash
python run_sql.py
