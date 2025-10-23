# 🏬 Olist 电商平台履约与用户体验分析项目

## 一、项目简介（Project Overview）

本项目基于 **巴西 Olist 电商平台** 公共数据集，构建端到端的数据分析体系，聚焦 **订单履约效率（Order-to-Delivery Performance）** 与 **用户满意度（Customer Experience）** 的关系。
通过构建清洗、建模、SQL计算与文本挖掘的分析链路，实现从履约时间到评论情绪的量化分析。

研究目标包括：

* 📦 评估平台整体履约效率（OTD≤5、P50、P90 等指标）；
* 🌍 分析不同地理区域、发货地与收货地的履约差异；
* 💬 识别发货延迟、未收货等负面评论关键词，探究差评驱动因素；
* 🧭 输出履约优化与客户体验改进建议。

---

## 二、项目结构（Project Architecture）

```
Olist_Performance_Analysis/
│
├── olist_orders_dataset/          # 模块一：订单清洗与时效指标计算
│   └── README.md
│
├── olist_geo_orders_dataset/      # 模块二：地理维度订单分析（发货地-收货地）
│   └── README.md
│
├── order_cus_sel_geo_wide/        # 模块三：扩展地理宽表（含经纬度与距离）
│   └── README.md
│
├── olist_orders_reviews_dataset/  # 模块四：订单 × 评论融合与词频分析
│   └── README.md
│
├── processed/                     # 所有模块产出数据集
├── sql/                           # SQL脚本合集（指标计算、聚合分析）
├── notebook/                      # Jupyter分析脚本与日志
│   ├── etl.ipynb
│   ├── etl.log
│   └── wordcloud/
└── README.md                      # 当前文件
```

---

## 三、分析流程（Pipeline Overview）

| 阶段                | 模块                             | 主要任务                                               | 技术栈                           |
| ----------------- | ------------------------------ | -------------------------------------------------- | ----------------------------- |
| **1️⃣ 数据清洗与履约计算** | `olist_orders_dataset`         | 清洗订单表，计算履约天数、筛选 `delivered` 状态、生成 OTD≤5、P50、P90 指标 | Python（pandas）、SQL            |
| **2️⃣ 地理维度分析**    | `olist_geo_orders_dataset`     | 合并客户、卖家与订单明细，建立 “发货州-收货州” 模型，分析区域履约差异              | pandas + SQL 聚合               |
| **3️⃣ 地理扩展建模**    | `order_cus_sel_geo_wide`       | 引入经纬度计算地理距离，量化距离与履约时间关系                            | pandas + geopy                |
| **4️⃣ 评论融合与词频分析** | `olist_orders_reviews_dataset` | 构建订单-评论宽表，计算差评率、翻译评论并统计关键词频率                       | deep_translator、wordcloud、SQL |

---

## 四、核心ETL逻辑（ETL Logic）

1. **抽取（Extract）**
   从 Olist 原始表中读取订单、买家、卖家、订单明细、评论等 CSV 文件。

2. **转换（Transform）**

   * 筛选状态为 `delivered` 的订单；
   * 按时间字段计算履约天数 `days`；
   * 构建 `发货州-收货州`、`经纬度距离`、`订单-评论` 等宽表；
   * 删除重复与异常值，标准化字段命名。

3. **加载（Load）**

   * 生成主题宽表（orders_cleaned, geo_orders_wide, review_wide 等）；
   * 输出 CSV 至 `/processed/`；
   * 生成清洗日志（`etl.log`）与质量报告。

---

## 五、SQL分析逻辑（Analytical Metrics）

**核心指标计算：**

| 指标          | 说明                    |
| ----------- | --------------------- |
| `OTD≤5`     | 履约≤5天的订单占比            |
| `P50 / P90` | 履约天数的中位数与90分位         |
| `avg_days`  | 平均履约天数                |
| `bad_rate`  | 差评率（review_score ≤ 2） |

**典型分析：**

```sql
SELECT
  seller_state, customer_state,
  COUNT(*) AS order_count,
  ROUND(SUM(days <=5)*100.0/COUNT(*),2) AS otd_le_5_pct,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days) AS P50,
  PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY days) AS P90
FROM order_geo_wide
GROUP BY seller_state, customer_state
HAVING order_count > 100;
```

---

## 六、主要发现（Key Insights）

| 主题   | 发现                                     | 说明       |
| ---- | -------------------------------------- | -------- |
| 履约效率 | 平台平均履约时间为 **12.5 天**，行业均值约 5 天         | 存在显著滞后   |
| 地理分布 | **SP 州** 订单占比达 71%，同州履约 OTD≤5 占比高达 36% | 地理集中度高   |
| 跨州问题 | 跨州订单 OTD≤5 占比普遍低于 20%                  | 跨州物流瓶颈明显 |
| 评论反馈 | “发货慢”“未收货”“延迟” 等词频随履约时间显著上升            | 履约延迟驱动差评 |
| 优化建议 | 建立 SP / RJ 区域仓，提升跨州订单时效                | 成本效率兼顾   |

---

## 七、技术栈（Tech Stack）

| 分类    | 技术                                                  |
| ----- | --------------------------------------------------- |
| 语言与框架 | Python（pandas, logging, wordcloud, deep_translator） |
| 数据处理  | SQL（窗口函数、聚合分析）、Jupyter Notebook                     |
| 可视化   | WordCloud、Matplotlib                                |
| 数据管理  | 模块化 ETL、主题宽表设计、日志追踪                                 |

---
