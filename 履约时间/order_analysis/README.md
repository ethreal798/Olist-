# 📦 `olist_orders_dataset` 数据集说明

## 一、主题简介（Purpose）

本主题数据集用于支撑 **Olist 电商平台的订单与履约时效分析**。
 通过对订单表的清洗与结构化处理，提取核心字段，用于：

- 分析订单量变化趋势；
- 计算履约时效指标（如 **OTD≤5、P50、P90**）；
- 评估物流时效对用户体验的影响。

------

## 二、数据来源（Source Tables）

| 来源表                 | 说明                                             |
| ---------------------- | ------------------------------------------------ |
| `olist_orders_dataset` | 订单主表，包含订单购买、发货、送达等关键时间信息 |

------

## 三、主要字段说明（Schema）

| 字段名                          | 类型     | 来源    | 说明                                                         |
| ------------------------------- | -------- | ------- | ------------------------------------------------------------ |
| `order_id`                      | string   | orders  | 订单唯一标识                                                 |
| `customer_id`                   | string   | orders  | 客户唯一标识                                                 |
| `order_status`                  | string   | orders  | 订单状态（如 delivered, shipped, canceled 等）               |
| `order_purchase_timestamp`      | datetime | orders  | 用户下单时间                                                 |
| `order_delivered_customer_date` | datetime | orders  | 订单送达时间                                                 |
| `days`                          | int      | derived | 履约天数 = `order_delivered_customer_date - order_purchase_timestamp` |

------

## 四、ETL 逻辑（Processing Steps）

### 🧩 Python 层处理

1. 从 `olist_orders_dataset` 表筛选时间范围：**2017-01 ~ 2018-08**；
2. 将时间列缺失值统一填充为占位值 `"1970-01-01 00:00:00"`（用于保持字段完整性）；
3. 计算履约天数字段 `days`；
4. 输出清洗日志至 `etl.log`，并保存处理后的结果至 `/processed` 目录。

### 🧮 SQL 层分析

1. 基于年月聚合计算订单量变化趋势；
2. 计算平均履约时长；
3. 过滤条件：
   - 状态为 `delivered`；
   - 履约天数在 **0–180 天**；
4. 计算履约时效指标：
   - **OTD≤5：** 履约时间 ≤5 天订单占比；
   - **P50/P90：** 履约时长中位数与 90 分位数。

------

## 五、文件结构（File Structure）

```bash
order_analysis/
├── notebook/          # 存放 ETL 流程 (etl.ipynb) 与日志文件 (etl.log)
├── processed/          # 存放清洗后的结构化数据
├── raw/                # 原始源数据
└── sql/                # 存放 SQL 分析脚本
```

------

## 六、成果说明（Outputs）

- ✅ `orders_cleaned.csv`：结构化订单数据；
- ✅ SQL 统计结果：订单量趋势、履约中位数、P90；
- ✅ 可视化：履约时效趋势图、OTD≤5 占比趋势；
- ✅ 支撑分析主题：《Olist 平台履约时效分析》。

------


