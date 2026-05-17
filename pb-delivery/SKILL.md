---
name: pb-delivery
description: Use when development and testing is complete and need to generate delivery documentation with changed files, source code, and test points
---

# PB Delivery - 交付总结

## Overview

交付总结工具。开发测试完成后，收集变更文件、源码、可执行代码、SQL、测试要点等，生成完整的交付文档。

与业务相关，适用于国库集中支付系统（PbServer）开发。

## When to Use

- 开发测试完成，需要交付给测试/生产团队
- 需求变更后需要重新交付
- 需要输出完整的交付文档

## Workflow

```
1. 开发者触发交付
2. AI检查是否有需求文档（requirements/ 目录下）
   - 有：读取需求文档，用于交付文档的「需求回顾」
   - 无：询问开发者是否需要补充需求信息，或跳过需求回顾
3. AI收集信息（需求名、轮次、变更文件）
4. AI组织交付目录
5. AI生成交付文档
6. 开发者确认
```

## 交付文档内容

一份交付文档包含以下部分：

### 1. 需求回顾

**如果存在需求文档**（requirements/ 目录下找到对应文件）：
- 需求名称：从需求文档读取
- 需求描述：从需求文档的「需求描述」部分引用
- 交付轮次（Round 1, 2, 3...）
- 交付日期

**如果没有需求文档**：
- 询问开发者：「未找到需求文档，是否需要补充需求信息？」
- 如果开发者补充：记录开发者提供的信息
- 如果开发者跳过：此部分标记为「未提供需求文档」

### 2. 变更文件清单

#### 新增文件

| 文件路径 | 说明 |
|---------|------|
| realware/xxx/xxx.java | XXX功能 |
| realware/xxx/xxx.jsp | XXX页面 |

#### 修改文件

| 文件路径 | 修改内容 |
|---------|---------|
| realware/xxx/existing.java | 修改了XXX方法 |

### 3. 源代码

列出新增/修改的Java源代码文件：

```
files/
  realware/xxx/xxx.java
  realware/xxx/xxx.jsp
```

### 4. 可执行代码

编译后的class文件（如需要）：

```
classes/
  realware/WEB-INF/classes/xxx.class
```

### 5. SQL脚本

| 脚本 | 说明 | 执行顺序 |
|------|------|---------|
| create_xxx.sql | 创建XXX表 | 1 |
| insert_xxx.sql | 初始化数据 | 2 |

### 6. 测试要点

- [ ] 测试点1：XXX功能正常
- [ ] 测试点2：XXX数据正确
- [ ] 测试点3：XXX异常处理

### 7. 影响范围

- 影响的模块/页面
- 影响的接口
- 影响的数据表
- 对其他功能的影响

### 8. 注意事项

- 部署顺序（先SQL还是先代码）
- 依赖关系
- 回滚方案
- 其他需要注意的点

### 9. 变更历史（多轮交付时）

| 轮次 | 日期 | 变更内容 |
|------|------|---------|
| R1 | 2026-05-16 | 初始交付 |
| R2 | 2026-05-18 | 优化XXX |

## 交付目录结构

### 项目结构检测

AI 在交付启动时按以下逻辑检测项目类型：

1. 检查项目根目录是否存在 `realware/` 目录 -> realware 项目（默认）
2. 检查是否存在 `pom.xml` 且模块内有 `src/main/java` -> Maven 多模块项目
3. 检查是否存在 `.jar` 文件在项目根目录 -> jar 包项目
4. 无法判断时询问开发者

检测完成后询问开发者确认输出类型：「检测到项目类型为 XXX，是否使用对应的目录结构？」

### 三种目录结构模板

#### realware 目录结构（默认）

适用于传统 Java Web 项目，保持 realware 部署路径：

```
project/
  deliveries/
    YYYYMMDD_需求名称/
      roundN/
        delivery.md          # 交付文档
        files/               # 源代码（保持realware路径）
          realware/...
        classes/             # 可执行代码
          realware/WEB-INF/classes/...
        sql/                 # SQL脚本
        config/              # 配置文件
```

#### Maven 多模块目录结构

适用于 Spring Boot 多模块项目：

```
project/
  deliveries/
    YYYYMMDD_需求名称/
      roundN/
        delivery.md          # 交付文档
        files/               # 源代码（按模块组织）
          {模块名}/src/main/java/...
          {模块名}/src/main/resources/...
        sql/                 # SQL脚本
        config/              # 配置文件（.yml/.xml/.properties）
```

#### jar 包项目目录结构

适用于 jar 包部署项目，可执行代码由开发人员自行构建：

```
project/
  deliveries/
    YYYYMMDD_需求名称/
      roundN/
        delivery.md          # 交付文档
        files/               # 源代码
          src/main/java/...
        sql/                 # SQL脚本
        config/              # 配置文件
```

注意：jar 包本身不包含在交付目录中，由开发人员自行构建和提供。

## 自动收集文件

交付时，AI必须自动收集以下文件并复制到交付目录。收集规则按项目类型分别适配。

### realware 项目

| 文件类型 | 来源路径 | 说明 |
|---------|---------|------|
| .java | src/... | Java源码 |
| .jsp | realware/... | JSP页面 |
| .js | realware/... | JavaScript文件 |
| .xml | src/或realware/ | Spring配置、web.xml等 |
| .properties | src/或realware/ | 配置文件 |
| spring-views.properties | src/ | 视图映射配置（新增JSP页面时必须包含） |
| .class | realware/WEB-INF/classes/... | 编译后的class文件 |

### Maven 多模块项目

| 文件类型 | 来源路径 | 说明 |
|---------|---------|------|
| .java | {模块}/src/main/java/... | Java源码 |
| .jsp | {模块}/src/main/webapp/... 或 {模块}/src/main/resources/... | JSP页面 |
| .js | {模块}/src/main/resources/static/... | JavaScript文件 |
| .xml | {模块}/src/main/resources/... | Spring配置 |
| .properties | {模块}/src/main/resources/... | 配置文件 |
| .yml | {模块}/src/main/resources/... | Spring Boot配置 |
| .class | {模块}/target/classes/... | 编译后的class文件（如需要） |

### jar 包项目

| 文件类型 | 来源路径 | 说明 |
|---------|---------|------|
| .java | src/main/java/... | Java源码 |
| .jsp | src/main/webapp/... 或 src/main/resources/... | JSP页面 |
| .js | src/main/resources/static/... | JavaScript文件 |
| .xml | src/main/resources/... | Spring配置 |
| .properties | src/main/resources/... | 配置文件 |
| .yml | src/main/resources/... | Spring Boot配置 |

注意：jar 包本身由开发人员自行构建，不在交付目录中包含。

### 通用收集规则

1. AI从版本控制差异（Git/SVN）识别变更的文件
2. 自动复制到对应目录，保持项目部署路径
3. realware 项目新增 JSP 页面时不要遗漏 spring-views.properties
4. 如有编译后的class文件，一并收集到classes/
5. 收集完成后列出文件清单，供开发者确认

## 版本控制

### 自动检测

AI 按以下顺序检测项目使用的版本控制工具：

1. 检查项目根目录是否存在 `.git` 目录 -> Git 项目
2. 检查项目根目录是否存在 `.svn` 目录 -> SVN 项目
3. 均不存在时询问开发者使用哪种工具或手动指定变更文件

### 获取变更文件

#### Git 命令

```bash
# 获取相对于上次提交的变更
git diff --name-status HEAD~1 HEAD

# 获取未提交的变更
git status --porcelain

# 获取指定基线之后的变更
git diff --name-status <baseline-commit> HEAD
```

#### SVN 命令

```bash
# 获取未提交的变更
svn status

# 获取指定 revision 之后的变更
svn diff -r <baseline-revision>:HEAD --summarize
```

### 开发者补充

自动检测后 AI 必须询问两个问题：

1. 「以上是自动检测到的变更文件，是否有遗漏？」
2. 「是否有未纳入版本控制的新增文件需要包含？」

### 交付基线记录

每轮交付在 delivery.md 尾部记录版本控制基线信息：

**Git 格式：**
```markdown
## 版本控制基线
- 工具：Git
- 基线 commit：a1b2c3d
- 当前 commit：e4f5g6h
```

**SVN 格式：**
```markdown
## 版本控制基线
- 工具：SVN
- 基线 revision：12345
- 当前 revision：12400
```

## 使用示例

### 场景一：有需求文档

**开发者：** 开发完成了，开始交付。

**AI：** 检测到需求文档 `requirements/20260516_支付导出功能.md`，已读取需求信息。
请确认：
1. 交付轮次？（Round 1? 2?）
2. 涉及哪些文件？（新增/修改的Java、JSP、SQL等）

**开发者：** Round 1，新增了ExportController.java和export.jsp，修改了PaymentService.java，有一个create_export_table.sql。

**AI：** 生成交付文档和目录结构...

### 场景二：无需求文档

**开发者：** 开发完成了，开始交付。

**AI：** 未找到需求文档。是否需要补充需求信息？
1. 补充需求名称和描述
2. 跳过需求回顾

**开发者：** 需求名称"支付导出功能"，功能是支持导出支付数据到Excel。

**AI：** 已记录需求信息。请确认交付轮次和涉及文件...

## 迭代交付

交付后收到优化/变更需求时，判断处理方式：

### 同需求新轮次（小优化/迭代）

适用：改动范围小、逻辑相关、在同一功能上优化

```
deliveries/
  支付导出功能/
    round1/    ← 第一次交付
    round2/    ← 优化后交付
    round3/    ← 再次优化
```

流程：
1. 更新原需求文档（追加变更点）
2. 修改代码
3. `/pb-delivery` → 选 round2（或更高轮次）
4. 交付文档自动包含变更历史表

### 新需求（新功能）

适用：功能独立、可单独上线、与原需求关联不大

```
requirements/
  20260516_支付导出功能.md
  20260520_支付导出_批量导出.md   ← 新需求
```

流程：
1. 按「需求文档规则」章节输出新需求文档
2. 开发
3. `/pb-delivery` → 新的交付目录

### 判断标准

- 改动范围小、逻辑相关 → 同需求新轮次
- 功能独立、可单独上线 → 新需求

## 需求文档规则

### 何时创建

需求文档是**可选的**，但推荐在开发前创建：

- **推荐**：开发前创建需求文档，便于后续交付时引用
- **可选**：如果需求简单，可以跳过，交付时由开发者补充或跳过需求回顾

### 文件命名规则

需求文档命名格式：`YYYYMMDD_需求名称.md`

存放在项目根目录的 `requirements/` 目录中。

### 需求文档模板

```markdown
# 需求名称

## 基本信息

- 需求编号：REQ-YYYYMMDD-NNN
- 提出日期：YYYY-MM-DD
- 优先级：高/中/低
- 提出人：XXX

## 需求背景

描述业务背景和当前痛点。

## 需求描述

### 功能概述
一句话描述需求目标。

### 详细描述
分点描述具体功能要求。

### 业务规则
1. 规则1：XXX
2. 规则2：XXX

## 影响范围

- 影响模块：XXX
- 影响页面：XXX
- 影响接口：XXX
- 涉及数据表：XXX

## 验收标准

- [ ] 标准1：XXX
- [ ] 标准2：XXX

## 备注

其他补充信息。
```

### 使用场景

- 新功能开发前，先编写需求文档
- 迭代交付时，更新原需求文档（追加变更点）
- 交付文档中引用需求文档的内容

## 多轮交付

- 每轮创建新的 `roundN/` 目录
- 每轮独立交付文档
- 交付文档包含完整变更历史（R1→R2→...每次做了什么）
- 最终可合并所有轮次的文件

## 注意事项

- 文件路径保持项目部署结构（realware 项目保持 realware 路径，Maven 项目保持模块路径）
- SQL 脚本标注执行顺序
- 测试要点要具体可检查
- 影响范围要全面，不要遗漏
- jar 包项目的可执行代码（jar 包）由开发人员自行构建，交付目录中不包含
- 每轮交付记录版本控制基线信息
