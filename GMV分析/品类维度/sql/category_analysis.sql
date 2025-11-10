with ele_month as (
SELECT
  category_final,
  round(sum(price+freight_value),2) GMV,
  count(distinct order_id) order_cnt
from category_gmv2
where month(order_purchase_timestamp) = 11 
GROUP BY category_final 
), tw_month as (
    SELECT
  category_final,
  round(sum(price+freight_value),2) GMV,
  count(distinct order_id) order_cnt
from category_gmv2
where month(order_purchase_timestamp) = 12 
GROUP BY category_final 
)
SELECT
  ele_month.category_final,
  ele_month.GMV as 11月GMV,
  tw_month.GMV as 12月GMV,
  ele_month.order_cnt as 11月订单数,
  tw_month.order_cnt as 12月订单数
FROM ele_month join tw_month on ele_month.category_final = tw_month.category_final
ORDER BY 11月GMV desc 
