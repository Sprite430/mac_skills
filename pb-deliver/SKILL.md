---
name: pb-deliver
description: Use when development and testing is complete and user wants to package deliverables - changed files, SQL scripts, and documentation for handoff
---

# PB Deliver - 交付打包

## Overview

交付打包skill。开发测试完成后，收集变更文件、SQL脚本、配置文件，生成交付目录和报告。

与 `pb-server-developer` 配合使用：pb-server-developer 负责代码生成，pb-deliver 负责打包输出。

## When to Use

- 开发测试完成，需要交付给测试/生产团队
- 用户说"开始交付"、"打包交付"、"输出交付文件"
- 需求变更后需要重新交付

## Workflow

```
用户触发交付
    ↓
询问：需求名称？第几轮？
    ↓
确认：涉及哪些文件？
    ↓
组织交付目录（保持realware路径）
    ↓
生成交付报告
    ↓
输出到项目 deliveries/ 目录
```

## 项目内文件组织

```
project/
  deliveries/
    需求名称/
      round1/
        files/           # 交付文件（保持realware部署路径）
          realware/...
        sql/             # SQL脚本
        config/          # 配置文件
        delivery-report.md
      round2/
        files/
        sql/
        config/
        delivery-report.md
```

## 交付步骤

### Step 1: 收集信息

询问用户：
- **需求名称** — 用于创建文件夹
- **轮次** — round1, round2, ...
- **PRD路径** — 关联的需求文档

### Step 2: 确认变更文件

与用户确认本次涉及的文件：
- 新增的Java/JSP/JS文件
- 修改的Java/JSP/JS文件
- SQL脚本
- 配置文件变更

用户可能直接告知文件列表，或AI从开发过程推断后让用户确认。

### Step 3: 组织交付目录

按realware部署路径组织文件：

```
deliveries/需求名称/roundN/
  files/realware/...     ← Java源码、JSP、JS等
  sql/                   ← SQL脚本
  config/                ← 配置文件（xml、properties等）
  delivery-report.md     ← 交付报告
```

### Step 4: 生成交付报告

使用 `delivery-report-template.md` 模板，填入：
- 需求信息
- 变更概述
- 文件清单（新增/修改）
- SQL脚本说明
- 配置变更
- 测试要点
- 变更历史（如有多轮）

### Step 5: 输出确认

提示用户：
- 交付目录位置
- 检查文件是否完整
- 确认报告内容

## 多轮迭代

- 每轮创建新的 `roundN/` 目录
- 每轮独立交付报告
- 报告包含完整变更历史表
- 可选：增量交付（本轮变更）或全量交付（合并所有轮次）

## 交付报告内容

详见 `delivery-report-template.md`。核心包含：

| 部分 | 内容 |
|------|------|
| 需求信息 | 名称、PRD、轮次、日期 |
| 变更概述 | 做了什么（1-3句话） |
| 新增文件 | 路径 + 说明 |
| 修改文件 | 路径 + 修改内容 |
| SQL脚本 | 脚本名 + 说明 + 执行顺序 |
| 配置变更 | 文件 + 变更内容 |
| 测试要点 | checklist |
| 注意事项 | 部署顺序、依赖等 |
| 变更历史 | 所有轮次汇总 |

## 与pb-server-developer的配合

- pb-server-developer 负责代码生成（/pbdev）
- pb-deliver 负责打包输出（/pb-deliver）
- 开发过程中不需要记录，交付时统一收集
- 交付目录放在项目根目录的 `deliveries/` 下

## Common Mistakes

| 问题 | 解决 |
|------|------|
| 遗漏文件 | 交付前让AI扫描开发过程涉及的文件 |
| 路径错误 | 保持realware部署路径，不要改变目录结构 |
| SQL遗漏 | 单独列出SQL，标注执行顺序 |
| 测试要点不全 | 从PRD的测试要点提取 |
