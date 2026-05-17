---
name: pb-requirement
description: 创建简洁的需求文档，包含功能描述、影响范围和测试要点
author: zhangchengke
---

# PB Requirement - 需求文档创建

## 概述

创建简洁的需求文档。只需提供三个核心信息：要做什么、影响什么、测试什么。

## 使用场景

- 开发新功能前，快速记录需求
- 为 pb-delivery 交付提供需求文档
- 团队沟通时明确需求边界

## 工作流

```
1. AI 询问三个核心问题
2. 开发者回答
3. AI 生成需求文档
4. 保存到 requirements/ 目录
```

## 核心问题

AI 会询问以下三个问题：

### 1. 要做什么？

简洁描述本次需求的功能目标。

示例：
- 「支持批量导出支付数据到 Excel」
- 「增加零余额退款功能」
- 「优化报表查询性能」

### 2. 影响什么？

列出受影响的模块、页面、接口、数据表等。

示例：
- 模块：支付导出模块
- 页面：ExportController、export.jsp
- 接口：/api/export/batch
- 数据表：PB_PAYMENT_RECORD

### 3. 测试什么？

列出测试时需要关注的要点。

示例：
- [ ] 批量导出 1000 条数据不超时
- [ ] 导出的 Excel 格式正确
- [ ] 权限控制：只有授权用户可导出

## 输出格式

生成的需求文档保存到 `requirements/YYYYMMDD_需求名称.md`：

```markdown
# 需求名称

## 要做什么

[功能描述]

## 影响什么

- 模块：XXX
- 页面：XXX
- 接口：XXX
- 数据表：XXX

## 测试要点

- [ ] 测试点1
- [ ] 测试点2
- [ ] 测试点3
```

## 使用示例

**开发者：** /pb-requirement

**AI：** 请回答三个问题：
1. 这次需求要做什么？
2. 影响哪些模块/页面/接口？
3. 测试时需要注意什么？

**开发者：**
1. 支持批量导出支付数据到 Excel
2. 影响 ExportController、export.jsp、PB_PAYMENT_RECORD 表
3. 测试批量导出性能、Excel 格式、权限控制

**AI：** 已生成需求文档 `requirements/20260517_批量导出支付数据.md`

## 与 pb-delivery 配合

生成的需求文档可被 pb-delivery 交付时引用：

1. 开发前：`/pb-requirement` 创建需求文档
2. 开发中：按需求文档实现功能
3. 开发后：`/pb-delivery` 交付时自动读取需求文档

## 注意事项

- 需求文档保持简洁，不需要写得很详细
- 三个核心问题缺一不可
- 文件名格式：`YYYYMMDD_需求名称.md`
