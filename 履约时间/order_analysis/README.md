# 📦 `olist_orders_dataset` 数据集说明
---

## 一、主题简介（Purpose）

本主题数据集用于支撑 **Olist 电商平台的订单与履约时效分析**。
通过对订单表的清洗与结构化处理，提取核心字段，用于：

* 分析订单量变化趋势；
* 计算履约时效指标（如 **OTD≤5、P50、P90**）；
* 评估物流时效对用户体验的影响。

---

## 二、数据来源（Source Tables）

| 来源表                    | 说明                       |
| ---------------------- | ------------------------ |
| `olist_orders_dataset` | 订单主表，包含订单购买、发货、送达等关键时间信息 |

---

## 三、主要字段说明（Schema）

| 字段名                             | 类型       | 来源      | 说明                                     |
| ------------------------------- | -------- | ------- | -------------------------------------- |
| `order_id`                      | string   | orders  | 订单唯一标识                                 |
| `customer_id`                   | string   | orders  | 客户唯一标识                                 |
| `order_status`                  | string   | orders  | 订单状态（如 delivered, shipped, canceled 等） |
| `order_purchase_timestamp`      | datetime | orders  | 用户下单时间                                 |
| `order_delivered_customer_date` | datetime | orders  | 订单送达时间                                 |
| `days`                          | int      | derived | 履约天数 = 送达时间 - 下单时间                     |

---

## 四、ETL逻辑（Processing Steps）

### 🧩 Python 层处理

1. **时间筛选：** 保留 2017-01 至 2018-08 的订单数据；
2. **异常时间过滤：** 删除异常月份（如 2016年9–12月、2018年9–10月）；
3. **缺失值填充：**

   * 时间列 → `"1970-01-01 00:00:00"` 占位；
   * 普通列 → `"未知"`；
4. **重复值处理：** 删除完全重复记录；
5. **特征生成：**

   * 计算 `days = order_delivered_customer_date - order_purchase_timestamp`；
   * 拆分年月字段 `year`、`month`；
6. **日志记录：** 输出到 `etl.log`；
7. **结果保存：** `/processed/order_table_cleaned.csv`。

---

## 五、SQL 层分析（Analysis）

以下 SQL 示例可用于统计履约表现：

```sql
WITH base AS (
  SELECT
    order_id,
    days,
    order_status,
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month
  FROM order_table_cleaned
  WHERE order_status = 'delivered'
    AND days BETWEEN 0 AND 180
)
SELECT
  month,
  COUNT(order_id) AS order_count,
  ROUND(AVG(days), 2) AS avg_days,
  ROUND(SUM(CASE WHEN days <= 5 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS otd_le_5,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days) AS p50,
  PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY days) AS p90
FROM base
GROUP BY month
ORDER BY month;
```

输出结果可用于：

* 绘制每月履约时间趋势；
* 计算 OTD≤5 占比；
* 比较 P50 / P90 履约时长。

---

## 六、文件结构（File Structure）

```bash
order_analysis/
├── raw/                 # 原始数据
│   └── olist_orders_dataset.csv
│
├── processed/           # 清洗后输出
│   └── order_table_cleaned.csv
│
├── notebook/            # ETL notebook + 日志
│   └── etl.log
│
├── sql/                 # 分析SQL脚本
│   └── order_analysis.sql
│
└── etl_orders.py        # 当前ETL脚本
```

---

## 七、成果说明（Outputs）

| 输出内容     | 文件名                       | 说明               |
| -------- | ------------------------- | ---------------- |
| ✅ 清洗后订单表 | `order_table_cleaned.csv` | 结构化订单数据          |
| ✅ 履约时效指标 | SQL 查询结果                  | 各月 OTD≤5、P50、P90 |
| ✅ 可视化成果  | Tableau / Excel           | 履约时效趋势图          |
| ✅ 报告主题   | 《Olist 平台履约时效分析》          | 核心分析支撑数据         |

---
