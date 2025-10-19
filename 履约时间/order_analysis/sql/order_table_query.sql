-- 将购买时间,送达顾客时间转换为DateTime类型
ALTER TABLE order_table_cleaned 
MODIFY COLUMN order_purchase_timestamp DATETIME;

ALTER TABLE order_table_cleaned 
MODIFY COLUMN order_delivered_customer_date DATETIME;


-- 求按月订单量趋势走向
SELECT
  DATE_FORMAT(order_purchase_timestamp,'%Y-%m') 时间,
  count(order_id) as 订单量
FROM order_table_cleaned
GROUP BY 时间
ORDER BY 时间


-- 平均履约时间
SELECT
  avg(
  DATEDIFF(order_delivered_customer_date,order_purchase_timestamp))履约时间
FROM order_table_cleaned
WHERE order_delivered_customer_date != '1970-01-01 00:00:00'
-- https://www.eae.es/en/news/eae-news/delivery-time-e-commerce-services-has-dropped-8-5-days-3-years  
-- EAE 的研究表明，2014 年，电子商务服务从订购到交货的平均时间为 8 天，而在 2017 年，这一时间已降至平均 5 天  
-- 而Olist电商平台2018年到2017年的平均履约时间为12.5天

SELECT
  YEAR(order_purchase_timestamp) 年份,
  Avg(DATEDIFF(order_delivered_customer_date,order_purchase_timestamp))履约时间
FROM order_table_cleaned
WHERE order_delivered_customer_date != '1970-01-01 00:00:00'
GROUP BY 年份
-- 2017年12.9天   
-- 2018年12天


-- （只保留 0–180 天的已送达订单）：
WITH base AS (
  SELECT
    days
  FROM order_table_cleaned
  WHERE order_status = 'delivered'
    AND days BETWEEN 0 AND 180
),
ranked AS (
  SELECT
    days,
    PERCENT_RANK() OVER (ORDER BY days) AS pct_rank
  FROM base
)
SELECT
  COUNT(*) AS total_orders,
  SUM(days <= 5) AS otd_le_5_count,
  ROUND(AVG(days),2) AS avg_days,
  ROUND(SUM(days <= 5) * 100.0 / COUNT(*), 2) AS otd_le_5_pct,
  ROUND(SUM(days > 30)*100.0/COUNT(*),2) AS gt_30_pct,
  MIN(CASE WHEN pct_rank >= 0.5 THEN days END) AS P50_days,
  MIN(CASE WHEN pct_rank >= 0.9 THEN days END) AS P90_days
FROM ranked;
