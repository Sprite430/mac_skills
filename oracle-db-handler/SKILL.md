---
name: "oracle-db-handler"
description: "国库集中支付系统Oracle数据库操作工具，支持执行查询和自动数据修复"
version: "5.0.0"
author: "Treasury System Team"
---

# Oracle数据库操作工具 - AI调用指南

## 概述

本工具用于国库集中支付系统的Oracle数据库操作。核心能力：**用户输入SQL查询 → 查询为空时AI自动造数据 → 查询有值**。

AI负责理解SQL语义、分析WHERE条件、生成INSERT语句；shell脚本只负责执行。

## 调用条件

- 用户提供SQL查询语句，希望查询返回数据
- 用户需要查看表结构
- 用户需要执行数据库更新操作

## 前置条件

- Docker容器 `oracle-21c-local` 已运行
- 已通过 `setup` 命令配置数据库连接（连接信息缓存在 `.last_connection`）
- `run_query.sh` 有执行权限

## 工具参数

| 参数 | 类型 | 必填 | 说明 | 默认值 |
|------|------|------|------|--------|
| sql_statement | string | 是 | SQL查询语句 | - |
| action | string | 否 | query(仅查询) / fix(查询为空时造数据) | fix |

## 核心工作流：数据修复

当 `action=fix` 时，AI按以下流程操作：

```
┌──────────────────────────────────────────────────────────┐
│ Step 1: 执行原始查询                                      │
│   命令: run_query.sh sql '<用户SQL>'                      │
│   判断: 结果是否 > 0                                       │
│     是 → 返回结果，结束                                    │
│     否 → 继续 Step 2                                      │
├──────────────────────────────────────────────────────────┤
│ Step 2: 分析SQL语义                                       │
│   AI自行理解:                                              │
│   - 目标表名 (FROM后的主表)                                │
│   - WHERE条件 (等值/范围/IN/EXISTS等)                      │
│   - 子查询关联 (如账户筛选、工作流节点)                     │
│   - 需要满足的约束条件                                     │
├──────────────────────────────────────────────────────────┤
│ Step 3: 获取表结构                                        │
│   命令: run_query.sh desc <表名>                          │
│   目的: 确认必填字段、字段类型、字段长度                     │
│   如有 references/ 下的造数据指引，参考关联查询和原则        │
├──────────────────────────────────────────────────────────┤
│ Step 4: 生成INSERT语句                                    │
│   AI根据分析结果动态生成，原则:                             │
│   - INSERT值必须满足WHERE中的所有条件                       │
│   - 必填字段(NOT NULL)必须有值                             │
│   - 外键关联字段需先查询有效值                              │
│   - ID类字段用大随机数避免冲突: 9XXXXXXX + RANDOM           │
│   - 子查询条件需同步处理(如插入工作流任务)                   │
├──────────────────────────────────────────────────────────┤
│ Step 5: 执行INSERT                                       │
│   命令: run_query.sh update '<INSERT语句>'                 │
│   如有多个关联表需更新，逐个执行                            │
├──────────────────────────────────────────────────────────┤
│ Step 6: 验证结果                                          │
│   命令: run_query.sh sql '<原始查询SQL>'                   │
│   确认: 结果 > 0 则成功，否则继续分析调整                   │
└──────────────────────────────────────────────────────────┘
```

## 常用表及造数据要点

### PB_PAY_VOUCHER (支付凭证)
- 关键条件: `admdiv_code`, `vt_code`, `business_type`, `pay_account_no`
- `pay_account_no` 需从 `pb_ele_account` 查询有效值
- 查询示例: `SELECT account_no FROM pb_ele_account WHERE bank_id = 1672 AND account_type_code = '11' AND admdiv_code = '511100' AND ROWNUM = 1`

### PB_REALPAY_BUDGET_VOUCHER (实拨预算凭证)
- 关键条件: `business_type`, `is_input`, `clear_account_no`, `task_id`
- `task_id` 关联 `GAP_WF_TASK`，需同步创建工作流任务
- 工作流: `GAP_WF_TASK.proc_id` + `GAP_WF_TASK.node_id` 需匹配 `GAP_WF_NODE` 中 `menu_id` 对应的记录
- `clear_account_no` 需从 `pb_ele_account` 查询 (account_type_code = '5')

### PB_DEMAND_NOTE_VOUCHER (收款凭证)
- 关键条件: `vt_code`, `business_type`, `pay_dbj_flag`, `clear_account_no`
- `pay_dbj_flag <> 1` → 插入时设为 0
- `clear_account_no` 需从 `pb_ele_account` 查询

### PB_PAYBACK_VOUCHER (退款凭证)
- 关键条件: `vt_code`, `business_type`, `clear_account_no`
- `clear_account_no` 需从 `pb_ele_account` 查询

### PB_PAY_REQUEST (支付申请)
- 需根据具体查询条件分析，参考 `references/` 下的表结构文档

## 辅助查询语句

造数据时常用的辅助查询：

```sql
-- 查询有效账户 (零余额账户)
SELECT account_no FROM pb_ele_account WHERE bank_id = 1672 AND account_type_code = '11' AND admdiv_code = '{admdiv_code}' AND ROWNUM = 1

-- 查询有效账户 (清算账户)
SELECT account_no FROM pb_ele_account WHERE bank_id = 1672 AND account_type_code = '5' AND ROWNUM = 1

-- 查询工作流节点
SELECT PROC_ID, NODE_ID FROM GAP_WF_NODE WHERE MENU_ID = '{menu_id}' AND ROWNUM = 1

-- 查询表结构
DESCRIBE {表名}
```

## AI调用示例

### 示例1: 简单查询修复

**用户输入:**
```
select count(1) AS ct from (select 1 from PB_PAY_VOUCHER objsrc_2742 where admdiv_code = '511100' and vt_code = '5214' and business_type = '0') st
```

**AI执行流程:**
1. `run_query.sh sql 'select count(1) AS ct from (...)' ` → 结果 0
2. AI分析: 表 PB_PAY_VOUCHER, 条件 admdiv_code='511100', vt_code='5214', business_type='0'
3. `run_query.sh desc PB_PAY_VOUCHER` → 获取表结构
4. `run_query.sh sql 'SELECT account_no FROM pb_ele_account WHERE bank_id = 1672 AND account_type_code = '\''11'\'' AND admdiv_code = '\''511100'\'' AND ROWNUM = 1'` → 获取账户
5. `run_query.sh update 'INSERT INTO PB_PAY_VOUCHER (PAY_VOUCHER_ID, TOP_ORG_ID, YEAR, IS_ONLYREQ, PAYEE_ACCOUNT_NO, PAY_SUMMARY_NAME, PAY_AMOUNT, PAY_ACCOUNT_NO, ADMDIV_CODE, VT_CODE, BUSINESS_TYPE, CLEAR_FLAG, PAY_REFUND_AMOUNT) VALUES (999999123, 1, 2026, 1, '\''123456789'\'', '\''测试摘要'\'', 1.5, '\''{account_no}'\'', '\''511100'\'', '\''5214'\'', 0, 1, 0)'`
6. `run_query.sh sql 'select count(1) AS ct from (...)' ` → 验证结果 > 0

### 示例2: 带子查询的复杂修复

**用户输入:**
```
select count(1) AS ct from (select 1 from PB_REALPAY_BUDGET_VOUCHER objsrc_6815 where business_type <= 0 and is_input = 0 and clear_account_no in (select account_no from pb_ele_account where bank_id = 1672 and account_type_code = '5')) st
```

**AI执行流程:**
1. 执行查询 → 结果 0
2. AI分析: 表 PB_REALPAY_BUDGET_VOUCHER, 条件 business_type<=0, is_input=0, clear_account_no需在pb_ele_account中存在
3. 获取表结构
4. 查询有效账户: `SELECT account_no FROM pb_ele_account WHERE bank_id = 1672 AND account_type_code = '5' AND ROWNUM = 1`
5. 生成INSERT并执行
6. 验证结果

### 示例3: 仅查询

**用户输入:**
```
帮我查一下支付凭证有多少条
```

**AI调用:**
```bash
run_query.sh sql 'SELECT COUNT(*) FROM PB_PAY_VOUCHER'
```

## 命令速查

| 命令 | 用途 | 示例 |
|------|------|------|
| `run_query.sh sql '<SQL>'` | 执行查询 | `run_query.sh sql 'SELECT COUNT(*) FROM PB_PAY_VOUCHER'` |
| `run_query.sh update '<SQL>'` | 执行更新(自动COMMIT) | `run_query.sh update 'INSERT INTO ...'` |
| `run_query.sh desc <表名>` | 查看表结构 | `run_query.sh desc PB_PAY_VOUCHER` |
| `run_query.sh connect` | 测试连接 | `run_query.sh connect` |
| `run_query.sh setup` | 配置连接 | `run_query.sh setup` |
| `run_query.sh show` | 显示连接信息 | `run_query.sh show` |

## 注意事项

1. **AI驱动**: 数据修复逻辑完全由AI理解SQL语义后动态生成，不依赖硬编码的fix函数
2. **先查后改**: 始终先执行查询确认结果为0，再决定是否造数据
3. **验证闭环**: INSERT后必须重新执行原始查询验证结果
4. **关联处理**: 子查询涉及的关联表(如GAP_WF_TASK)需同步处理
5. **ID冲突**: 使用大随机数(9XXXXXXX)作为主键，避免与已有数据冲突
6. **表结构优先**: 造数据前先 `desc` 表结构，确保INSERT字段完整且类型正确
7. **references目录**: 造数据指引和常用关联查询，表结构通过 `desc` 命令实时获取
