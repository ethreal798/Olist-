# 🌍 [order_cus_sel_geo_wide] 数据集说明

## 一、主题简介（Purpose）

本数据集为 **“订单地理扩展主题”**，用于分析 **地理距离对履约时效的影响**。
通过将订单、买家、卖家与地理位置表进行整合，构建包含 **经纬度与距离特征** 的宽表，可用于以下分析任务：

* 📦 分析不同地理距离区间（如同城、跨州）对履约天数的影响
* ⏱️ 计算 OTD≤5 占比、P50/P90 等指标，评估平台履约效率
* 🚚 辅助差评、延迟发货、履约体验相关建模

---

## 二、数据来源（Source Tables）

| 来源表                             | 说明                   |
| ------------------------------- | -------------------- |
| `order_table_cleaned.csv`       | 清洗后的订单主表，包含订单状态与履约天数 |
| `olist_sellers_dataset.csv`     | 卖家基础信息表              |
| `olist_order_items_dataset.csv` | 订单明细表，用于连接卖家与订单      |
| `olist_customers_dataset.csv`   | 买家信息表                |
| `olist_geolocation_dataset.csv` | 地理表，包含邮编、经纬度信息       |

---

## 三、主要字段说明（Schema）

| 字段名               | 类型       | 来源                      | 说明                        |
| ----------------- | -------- | ----------------------- | ------------------------- |
| `order_id`        | string   | order_table_cleaned     | 订单唯一标识                    |
| `days`            | int      | order_table_cleaned     | 履约天数                      |
| `customer_state`  | string   | olist_customers_dataset | 买家所在州                     |
| `seller_state`    | string   | olist_sellers_dataset   | 卖家所在州                     |
| `distance_km`     | float    | geo计算生成                 | 买卖双方距离（公里）                |
| `distance_bucket` | category | 特征工程                    | 距离分桶（如 `<100`, `100–500`） |

---

## 四、ETL逻辑（Processing Steps）

### 🧩 ETL Pipeline 结构

整个流程采用 **Extract → Transform → Load** 三步模式：

```bash
etl_pipeline(list_path)
```

### 1️⃣ Extract 阶段

* 从 `../raw` 目录读取 5 张原始数据表；
* 若文件缺失则自动记录日志并中止流程；
* 输出加载行列数以便监控数据完整性。

### 2️⃣ Transform 阶段

主要逻辑如下：

| 步骤       | 说明                                                      |
| -------- | ------------------------------------------------------- |
| ① 数据筛选   | 过滤 `delivered` 状态订单，保留履约天数 0–180 天之间的数据                 |
| ② 去重     | 在订单明细表中按 `order_id` 去重，仅保留首个记录                          |
| ③ 经纬度均值化 | 对相同邮编的经纬度取均值，减少地理噪声                                     |
| ④ 地理信息合并 | 依次将买家、卖家与地理表左连接，生成含经纬度字段的宽表                             |
| ⑤ 缺失值删除  | 删除无法匹配地理编码的记录                                           |
| ⑥ 距离计算   | 使用 Haversine 公式计算买卖双方距离（单位 km）                          |
| ⑦ 分桶     | 按距离区间 `[0,100,500,1000,2000,∞)` 构造 `distance_bucket` 字段 |

### 3️⃣ Load 阶段

* 输出结果保存至：

  ```
  ../processed/order_cus_sel_geo_wide.csv
  ```
* 并在 `etl.log` 中记录数据质量报告（缺失率、重复率等）。

---

## 五、SQL 分析示例（Analysis Example）

以下 SQL 可用于评估不同距离区间的履约表现：

```sql
WITH base AS (
  SELECT
    order_id,
    days,
    distance_bucket AS 距离区间,
    PERCENT_RANK() OVER (ORDER BY days) AS pct_rank
  FROM order_cus_sel_geo_wide
)
SELECT
  距离区间,
  COUNT(order_id) AS 订单量,
  ROUND(AVG(days), 2) AS 平均时长,
  ROUND(SUM(days <= 5) * 100.0 / COUNT(*), 2) AS otd_le_5_pct,
  ROUND(SUM(days > 30) * 100.0 / COUNT(*), 2) AS gt_30_pct,
  MIN(CASE WHEN pct_rank >= 0.5 THEN days END) AS P50_days,
  MIN(CASE WHEN pct_rank >= 0.9 THEN days END) AS P90_days
FROM base
GROUP BY 距离区间;
```

👉 输出结果可用于可视化：

* X轴：距离区间
* Y轴：平均履约时间或 OTD≤5 占比
* 从而验证“距离越远 → 履约时长增加”的假设。

---

## 六、日志与质量监控（Logging & QA）

* 日志文件：`etl.log`
* 输出示例：

  ```
  [DATA QUALITY] 合并后数据 - 行数: 87321 | 列数: 10 | 缺失率: 0.00% | 重复率: 0.00%
  [LOAD] 数据已保存至 ../processed/order_cus_sel_geo_wide.csv
  ```

---

## 七、文件结构（File Structure）

```
order_cus_sel_geo_wide/
│
├── raw/                    # 原始数据
│   ├── order_table_cleaned.csv
│   ├── olist_sellers_dataset.csv
│   ├── olist_order_items_dataset.csv
│   ├── olist_customers_dataset.csv
│   └── olist_geolocation_dataset.csv
│
├── processed/              # 处理后的输出文件
│   └── order_cus_sel_geo_wide.csv
│
├── etl.log                 # 日志文件（运行时自动生成）
└── etl_geo_wide.py         # 当前ETL脚本
```

---

## 八、指标解释（Metrics）

| 指标            | 含义                 |
| ------------- | ------------------ |
| **OTD≤5**     | 履约时间小于等于5天的订单占比    |
| **P50 / P90** | 履约天数的50分位数 / 90分位数 |
| **avg_days**  | 平均履约时间             |
| **gt_30_pct** | 履约超30天订单占比         |

