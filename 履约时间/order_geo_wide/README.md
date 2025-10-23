# 🌍 olist_geo_orders_dataset 数据集说明

## 一、主题简介（Purpose）

本数据集用于支持 **「订单履约时效的地理维度分析」**。
通过整合订单、客户、卖家及订单明细数据，构建 **“发货地-收货地”宽表模型**，从地理角度刻画 Olist 平台的履约效率。

研究目标包括：

* 识别各州的订单量分布与主要发货区域；
* 比较同州与跨州履约差异；
* 计算各地区履约指标（OTD≤5、P50、P90 等），评估物流效率与区域差异；
* 剔除低样本（订单数 < 100）区域，保证分析结果的稳定性。

---

## 二、数据来源（Source Tables）

| 来源表                         | 说明                             |
| --------------------------- | ------------------------------ |
| `order_table_cleaned`       | 清洗后的订单表，包含状态、购买时间、送达时间、履约天数等字段 |
| `olist_sellers_dataset`     | 卖家表，包含发货城市、发货州                 |
| `olist_customers_dataset`   | 买家表，包含收货城市、收货州                 |
| `olist_order_items_dataset` | 订单明细表，包含订单与卖家关联信息              |

---

## 三、主要字段说明（Schema）

| 字段名                             | 类型       | 来源                  | 说明     |
| ------------------------------- | -------- | ------------------- | ------ |
| `order_id`                      | string   | order_table_cleaned | 订单唯一标识 |
| `customer_id`                   | string   | customers           | 客户唯一标识 |
| `seller_id`                     | string   | sellers             | 卖家唯一标识 |
| `customer_state`                | string   | customers           | 收货州    |
| `seller_state`                  | string   | sellers             | 发货州    |
| `days`                          | int      | orders              | 订单履约天数 |
| `order_purchase_timestamp`      | datetime | orders              | 订单创建时间 |
| `order_delivered_customer_date` | datetime | orders              | 送达时间   |

---

## 四、ETL逻辑（ETL Pipeline）

### 🧹 数据提取（Extract）

* 使用 `pandas` 从 CSV 文件加载 4 张原始表；
* 对每张表执行数据质量报告（缺失率、重复率）；
* 记录日志到 `etl.log` 文件。

### 🔄 数据清洗与转换（Transform）

1. 筛选订单状态为 `'delivered'` 且履约天数在 `0–180` 天之间；
2. 仅保留核心字段：`order_id`、`customer_id`、`order_purchase_timestamp`、`order_delivered_customer_date`、`days`；
3. 合并买家表，追加 `customer_city`、`customer_state`；
4. 合并订单明细表，建立 `order_id → seller_id` 关联；
5. 去除重复记录；
6. 合并卖家表，追加 `seller_city`、`seller_state`；
7. 输出合并后宽表 `order_geo_wide`。

### 💾 数据加载（Load）

* 将处理完成的宽表导出至 `../processed/order_table_cleaned.csv`；
* 自动生成日志输出清洗后行数、列数、缺失率、重复率等信息。

---

## 五、SQL分析逻辑（Geo-level Analysis）

### 1️⃣ 发货地分布

```sql
SELECT
  seller_state AS 发货州,
  COUNT(*) AS 订单数
FROM order_geo_cleaned
GROUP BY 发货州
ORDER BY 订单数 DESC;
```

> ⏩ 识别平台订单集中区域，发现 SP 州订单量占比超过 70%。

---

### 2️⃣ 发货州 × 收货州 履约表现

```sql
WITH ranked AS (
  SELECT
    seller_state AS 发货州,
    customer_state AS 收货州,
    days,
    PERCENT_RANK() OVER (ORDER BY days) AS pct_rank
  FROM order_geo_cleaned
)
SELECT
  发货州,
  收货州,
  COUNT(*) AS 订单量,
  ROUND(AVG(days),2) AS avg_days,
  ROUND(SUM(days <=5)*100.0/COUNT(*),2) AS otd_le_5_pct,
  ROUND(SUM(days > 30)*100.0/COUNT(*),2) AS gt_30_pct,
  MIN(CASE WHEN pct_rank >= 0.5 THEN days END) AS P50_days,
  MIN(CASE WHEN pct_rank >= 0.9 THEN days END) AS P90_days
FROM ranked
GROUP BY 发货州, 收货州
HAVING 订单量 > 100
ORDER BY 发货州, 订单量 DESC, P90_days DESC;
```

> ✅ 同州发货收货订单中，OTD≤5 占比可达 **36%+**；
> 🚫 跨州履约订单 OTD≤5 占比普遍低于 **20%**；
> 🔎 说明地理距离显著影响履约速度，是后续优化的重要维度。

---

## 六、文件结构（File Structure）

```
order_geo_analysis/
│
├── notebook/
│   ├── etl.ipynb              # ETL流程代码
│   ├── etl.log                # 日志文件
│
├── raw/                       # 原始数据 (orders, sellers, customers, items)
├── processed/                 # 输出宽表 order_table_cleaned.csv
├── sql/                       # SQL分析脚本
└── README.md                  # 当前文档
```

---

## 七、分析结论（Key Findings）

| 维度       | 主要发现                           |
| -------- | ------------------------------ |
| 发货州分布    | SP 州为核心发货区，占比 >70%             |
| 同州 vs 跨州 | 同州履约 OT D≤5 ≥36%，跨州不超20%       |
| 长时履约占比   | 履约 >30 天订单约占 10% 左右，主要集中在北部偏远州 |
| 业务建议     | 可在 SP、RJ 州建立区域仓，缩短跨州履约距离       |

