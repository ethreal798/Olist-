WITH base AS (
  SELECT
    order_id,
    days,
    review_score,
    bucket
  FROM order_review_wide
  WHERE days BETWEEN 0 AND 180
)
SELECT
  bucket 周区间,
  COUNT(*) AS n_orders,
  ROUND(AVG(review_score),2) AS avg_score,
  ROUND(SUM(review_score <= 2)*100.0/COUNT(*),2) AS bad_rate_pct
FROM base
GROUP BY 周区间
ORDER BY 周区间