# 造数据指引

## 表结构获取

- **本文档已维护的表**: 优先参考下方的关联说明，再 `desc` 确认字段细节
- **本文档未维护的表**: 自行 `desc <表名>` 获取结构，AI分析SQL条件后生成INSERT

```bash
run_query.sh desc <表名>
```

## 复杂关联表说明

以下表的造数据涉及多表关联，提前说明避免反复试错。

### PB_REALPAY_BUDGET_VOUCHER (实拨预算凭证)

关联链路深，需同步处理3张表：

```
PB_REALPAY_BUDGET_VOUCHER.task_id
  → GAP_WF_TASK.task_id (需创建)
    → GAP_WF_TASK.proc_id + node_id
      → GAP_WF_NODE.proc_id + node_id (需已存在，按menu_id查找)
```

造数据步骤：
1. 从SQL中提取 `menu_id`（无则用默认 94107101）
2. 查询工作流节点: `SELECT PROC_ID, NODE_ID FROM GAP_WF_NODE WHERE MENU_ID = '{menu_id}' AND ROWNUM = 1`
3. 查询有效账户: `SELECT account_no FROM pb_ele_account WHERE bank_id = 1672 AND account_type_code = '5' AND ROWNUM = 1`
4. INSERT INTO PB_REALPAY_BUDGET_VOUCHER (设 business_type=0, is_input=0, clear_account_no=查到的账户, task_id=随机数)
5. INSERT INTO GAP_WF_TASK (NODETASK_ID=随机, TASK_ID=同上task_id, PROC_ID=步骤2的值, NODE_ID=步骤2的值, TASK_STATE=2)
6. COMMIT
7. 验证原始查询

### PB_PAY_VOUCHER (支付凭证)

`pay_account_no` 需满足子查询，从账户表查有效值：

```sql
SELECT account_no FROM pb_ele_account WHERE bank_id = 1672 AND account_type_code = '11' AND admdiv_code = '{admdiv_code}' AND ROWNUM = 1
```

常见条件值: admdiv_code='511100', vt_code='5214'/'2216'/'8210', business_type=0

### PB_DEMAND_NOTE_VOUCHER (收款凭证)

`pay_dbj_flag <> 1` → 插入时设为 0。`clear_account_no` 需从账户表查（account_type_code='5'）。

### PB_PAYBACK_VOUCHER (退款凭证)

`clear_account_no` 需从账户表查（account_type_code='5'）。

## 常用关联查询

```sql
-- 查询有效账户 (零余额账户)
SELECT account_no FROM pb_ele_account WHERE bank_id = 1672 AND account_type_code = '11' AND admdiv_code = '{admdiv_code}' AND ROWNUM = 1

-- 查询有效账户 (清算账户)
SELECT account_no FROM pb_ele_account WHERE bank_id = 1672 AND account_type_code = '5' AND ROWNUM = 1

-- 查询工作流节点
SELECT PROC_ID, NODE_ID FROM GAP_WF_NODE WHERE MENU_ID = '{menu_id}' AND ROWNUM = 1
```

## 造数据原则

1. **先查后造**: 先执行原始查询确认结果为0，再决定造数据
2. **先看结构**: `desc` 表结构，确认必填字段和类型
3. **满足条件**: INSERT值必须满足WHERE中的所有条件
4. **关联同步**: 子查询涉及的关联表需同步处理（参考上方复杂关联说明）
5. **ID防冲突**: 主键用大随机数 (9XXXXXXX)
6. **验证闭环**: INSERT后重新执行原始查询确认结果>0
