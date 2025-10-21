# 📦 olist_orders_reviews_dataset 数据集说明

## 一、主题简介（Purpose）

本数据集用于支持 **「履约时效与差评分析」** 主题研究。
通过对清洗后的订单表（order_cleaned）与评论表（olist_order_reviews_dataset）进行宽表建模，分析 **订单履约速度对用户评价的影响**，并进一步通过 **评论文本翻译与关键词频率分析**，识别出导致差评的主要原因（如发货慢、未收货等）。

研究目标包括：

* 计算并比较不同履约时长区间的差评率变化；
* 量化 OTD≤5、P50、P90 等指标与用户满意度的关系；
* 挖掘评论中与履约体验相关的高频词，形成用户体验洞察。

---

## 二、数据来源（Source Tables）

| 来源表                           | 说明                               |
| ----------------------------- | -------------------------------- |
| `order_cleaned`               | 清洗后的订单表，包含订单状态、购买时间、发货时间、履约天数等信息 |
| `olist_order_reviews_dataset` | 评论主表，包含评论标题、评论内容、评分等字段           |

---

## 三、主要字段说明（Schema）

| 字段名                      | 类型     | 来源                          | 说明         |
| ------------------------ | ------ | --------------------------- | ---------- |
| `order_id`               | string | order_cleaned               | 订单唯一标识     |
| `customer_id`            | string | olist_order_reviews_dataset | 客户唯一标识     |
| `days`                   | int    | order_cleaned               | 履约天数       |
| `review_score`           | int    | olist_order_reviews_dataset | 评论星级（1–5）  |
| `review_comment_message` | text   | olist_order_reviews_dataset | 评论正文（葡萄牙语） |
| `review_comment_title`   | text   | olist_order_reviews_dataset | 评论标题       |

---

## 四、ETL与分析逻辑（Processing Steps）

### 🧹 ETL流程

**Python阶段**

1. 从订单表筛选状态为 `delivered` 的订单，仅保留 `order_id`、`days` 两列；
2. 与评论表通过 `order_id` 字段进行左连接，构建宽表；
3. 对评论内容与标题的缺失值统一填充 `'U'`（未知）；
4. 检测并删除重复记录；
5. 基于 `days` 列构建履约时间分桶（0–7天、8–14天、15-30天、30天以上）。

**SQL阶段**

1. 按照履约时间分桶聚合，计算各分组的平均评分与差评率；
2. 使用窗口函数计算 OTD≤5、P50、P90 等履约效率指标；
3. 生成分组结果表，用于后续评论词频分析。

---

###  评论文本分析

1. 使用 `deep_translator` 库将葡萄牙语评论翻译为中文；
2. 预处理（去停用词、统一大小写、去除标点）；
3. 统计关键词词频（如 `'未收到'`、`'发货慢'`、`'延迟'`、`'未发货'` 等）；
4. 使用 `wordcloud` 绘制词云，直观展示负面评论的主要集中领域；
5. 对比不同履约分桶的负面词频，验证履约延迟与差评关联性。

---

## 五、文件结构（File Structure）

```
order_review_wide/
│
├── notebook/
│   ├── etl.ipynb              # ETL流程脚本
│   ├── etl.log                # 日志文件
│   └── wordcloud/             # 评论词频与可视化结果
│
├── processed/                 # 处理后的宽表数据
├── raw/                       # 原始数据
└── sql/                       # SQL分析脚本
```