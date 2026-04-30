---
name: "oracle-db-handler"
description: "国库集中支付系统Oracle数据库操作工具，支持执行查询和自动数据修复"
version: "4.0.0"
author: "Treasury System Team"
---

# Oracle数据库操作工具 - AI调用指南

## 概述

本工具专为AI设计，用于自动执行SQL查询并修复数据库数据，使查询返回预期结果。

## 调用条件

当用户提供SQL查询语句并希望该查询返回数据时，AI应调用此工具。

## 工具参数

| 参数 | 类型 | 必填 | 说明 | 默认值 |
|------|------|------|------|--------|
| sql_statement | string | 是 | 用户提供的SQL查询语句 | - |
| action | string | 否 | 执行动作：query(仅查询) / fix(修复数据) | fix |
| host | string | 否 | 数据库服务器地址 | 172.16.101.111 |
| port | string | 否 | Oracle监听端口 | 1521 |
| service | string | 否 | Oracle服务名 | orcl |
| user | string | 否 | 数据库用户名 | SICHUAN_LESHAN |
| password | string | 否 | 数据库密码 | 1 |

## 执行流程

```
┌─────────────────────────────────────────────────────┐
│ AI调用流程                                         │
│  1. 用户提供SQL查询语句                            │
│  2. AI调用本工具执行查询                            │
│  3. 工具检查查询结果                               │
│  4. 如果结果为0，自动修改数据库使其有数据           │
│  5. 返回最终结果给用户                             │
└─────────────────────────────────────────────────────┘
```

## 支持的表类型

- `PB_PAY_VOUCHER` - 支付凭证
- `PB_REALPAY_BUDGET_VOUCHER` - 实拨预算凭证
- `PB_DEMAND_NOTE_VOUCHER` - 收款凭证
- `PB_PAYBACK_VOUCHER` - 退款凭证
- `PB_PAY_REQUEST` - 支付申请

## AI调用示例

### 示例1: 用户提供查询语句

**用户输入:**
```
select count(1) AS ct from (select 1 from PB_PAY_VOUCHER objsrc_2742 where admdiv_code = '511100' and vt_code = '5214' and business_type = '0') st
```

**AI调用:**
```json
{
  "tool": "oracle-db-handler",
  "parameters": {
    "sql_statement": "select count(1) AS ct from (select 1 from PB_PAY_VOUCHER objsrc_2742 where admdiv_code = '511100' and vt_code = '5214' and business_type = '0') st",
    "action": "fix"
  }
}
```

**执行结果:**
```
查询结果: 1
说明: 已成功修复数据，查询现在返回1条记录
```

### 示例2: 指定不同的数据库连接

**用户输入:**
```
数据库地址: 172.16.101.112, 用户: TEST_USER, 密码: test123
select count(1) from PB_DEMAND_NOTE_VOUCHER where vt_code = '5408'
```

**AI调用:**
```json
{
  "tool": "oracle-db-handler",
  "parameters": {
    "sql_statement": "select count(1) from PB_DEMAND_NOTE_VOUCHER where vt_code = '5408'",
    "action": "fix",
    "host": "172.16.101.112",
    "user": "TEST_USER",
    "password": "test123"
  }
}
```

### 示例3: 仅查询不修改数据

**用户输入:**
```
帮我查询一下有多少条支付凭证
```

**AI调用:**
```json
{
  "tool": "oracle-db-handler",
  "parameters": {
    "sql_statement": "SELECT COUNT(*) FROM PB_PAY_VOUCHER",
    "action": "query"
  }
}
```

## 工具执行命令

### 命令1: 测试连接
```bash
docker exec oracle-21c-local bash -c "echo \"SELECT 'Connected' FROM dual\" | sqlplus -s {user}/{password}@//{host}:{port}/{service}"
```

### 命令2: 执行查询
```bash
docker exec oracle-21c-local bash -c "echo \"{sql_statement}\" | sqlplus -s {user}/{password}@//{host}:{port}/{service}"
```

### 命令3: 修复数据
```bash
cd /Users/zhangchengke/Documents/ZKJN/code/db/.trae/skills/oracle-db-handler && ./run_query.sh fix '{sql_statement}'
```

## 返回结果格式

### 成功修复
```
{
  "status": "success",
  "message": "数据修复成功",
  "before_count": 0,
  "after_count": 1,
  "action_taken": "INSERT INTO PB_PAY_VOUCHER (...)",
  "sql_statement": "用户原始查询语句"
}
```

### 查询结果
```
{
  "status": "success",
  "message": "查询成功",
  "result": 5,
  "sql_statement": "用户原始查询语句"
}
```

### 错误情况
```
{
  "status": "error",
  "message": "错误描述",
  "sql_statement": "用户原始查询语句"
}
```

## 注意事项

1. **自动修复**: `action=fix` 时，工具会自动修改数据库使查询有值
2. **仅查询**: `action=query` 时，工具仅执行查询不修改数据
3. **表类型限制**: 仅支持预设的表类型，其他表需要手动处理
4. **连接信息**: 如果用户未指定，使用默认连接信息

## 总结

AI可以通过以下方式使用此工具：

1. **接收用户的SQL查询请求**
2. **调用工具执行查询**
3. **工具自动修复数据（如果需要）**
4. **返回结果给用户**

用户只需提供SQL查询语句，AI调用此工具后即可获得有数据的查询结果。