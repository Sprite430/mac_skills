---
name: init-codegraph
description: CodeGraph 初始化助手，自动检测项目特征并生成排除配置完成索引。
author: Claude
---

# CodeGraph 项目初始化助手

自动检测项目环境，生成排除配置，完成 CodeGraph 索引初始化。

## 使用场景

**触发条件（满足任一即应调用）：**
- 用户说「初始化 codegraph」
- 用户说「codegraph init」
- 用户说「项目初始化 codegraph」
- 用户说「第一次初始化项目的代码索引」

**不触发的情况：**
- CodeGraph 已初始化且 `codegraph status` 显示正常（Index is up to date，文件数合理）
- 用户只是想「重新索引」或「更新索引」→ 用 `codegraph sync` / `codegraph index`

## 前置条件

- 已安装 CodeGraph CLI（`codegraph --version` 可执行）
- 当前目录是项目根目录或需初始化的目录
- 若未安装，提示用户先安装：`npm i -g @colbymchenry/codegraph`

## 强制规则

1. 只生成配置文件和运行 codegraph init，不修改任何业务代码。
2. 输出使用中文。
3. 必须先检测项目特征，再生成配置，最后初始化。
4. `.gitignore` 已存在时追加不冲突的规则，不覆盖已有内容。
5. 检测到软链接指向外部目录时，必须添加到排除列表并告知用户。
6. 遇到 SVN 项目必须同时创建 `.gitignore` 和 `codegraph.json`（双保险）。
7. init 完成后运行 `codegraph status` 验证文件数是否合理。

## 工作流

### 第一步：检测项目特征

按顺序执行检测：

**1.1 版本控制类型**
```bash
# 检测 Git
git rev-parse --show-toplevel 2>/dev/null && echo "GIT" || echo "NOT_GIT"
# 检测 SVN
svn info 2>/dev/null && echo "SVN" || echo "NOT_SVN"
```

**1.2 构建工具**
```bash
# 检测 Maven
find . -maxdepth 2 -name "pom.xml" 2>/dev/null | head -1
# 检测 Gradle
find . -maxdepth 2 -name "build.gradle*" 2>/dev/null | head -1
```

**1.3 大型排除目录**
```bash
# 检查 target/（Maven 编译产物）
find . -maxdepth 3 -type d -name "target" 2>/dev/null | head -5
# 检查 build/（Gradle 编译产物）
find . -maxdepth 3 -type d -name "build" 2>/dev/null | head -5
# 检查 node_modules/
find . -maxdepth 3 -type d -name "node_modules" 2>/dev/null | head -3
```

**1.4 软链接指向外部目录（关键！）**
```bash
# 查找所有软链接，输出「链接名 → 目标路径」
find . -maxdepth 3 -type l 2>/dev/null | while read link; do
  target=$(readlink "$link")
  # 判断是否指向外部（以 / 开头=绝对路径，或包含 .. 跳出项目）
  echo "$link -> $target"
done
```

**1.5 未纳入版本控制的目录（SVN 项目常见）**
```bash
# 检查 source_code_lib/ 等目录是否独立于版本控制
ls -la source_code_lib/ 2>/dev/null
```

### 第二步：展示检测结果

向用户报告检测结果，格式：

```
📋 项目检测结果：
- 版本控制：SVN / Git / 无
- 构建工具：Maven / Gradle / 无
- 编译产物目录：target/ (xxx 文件) / build/ (xxx 文件)
- ⚠️ 软链接：source_code_lib/pb-x.x.x-sources → /外部路径 (xxx 文件)
- 建议排除项：[列表]

即将生成配置：
- .gitignore
- codegraph.json
（如已存在则追加不冲突的规则）

确认后继续。
```

### 第三步：生成配置文件

**3.1 创建/更新 `.gitignore`**

根据检测结果生成排除规则。Git 项目只追加缺失行；SVN/无版本控制项目首次创建：

```
# Maven 编译产物
**/target/

# Gradle 编译产物
**/build/

# SVN 元数据（SVN 项目）
**/.svn/

# 产品参考源码（软链接，只读）
source_code_lib/

# Node 依赖（如有）
**/node_modules/
```

**3.2 创建/更新 `codegraph.json`**

```json
{
  "exclude": [
    "**/target/**",
    "**/build/**",
    "**/.svn/**",
    "source_code_lib/**"
  ]
}
```

根据实际检测结果增减排除项。

### 第四步：清理旧索引

```bash
rm -rf .codegraph/
```

### 第五步：运行 codegraph init

```bash
CODEGRAPH_NO_WATCHDOG=1 codegraph init
```

超时设置 600000ms（10 分钟），大项目可能需要等待。

### 第六步：验证结果

```bash
codegraph status
```

检查要点：
- **文件数是否合理**：一般几十到几百个源文件。如果几千个，排除规则可能没生效（最常见原因：软链接未排除）。
- **DB Size 是否正常**：几百文件应该在几十 MB 以内。
- **Index is up to date**：状态应为绿色。

验证通过后告知用户：

```
✅ CodeGraph 初始化完成
- 索引文件：xxx 个
- 节点数：xxx
- 数据库大小：xx MB
- 自动同步：已启用（文件变更自动更新索引）

日后 Maven 构译后无需手动操作，排除规则持续生效。
```

## 使用示例

**示例一：SVN + Maven 项目（含软链接）**

```
用户：初始化 codegraph
→ 检测到 SVN，Maven，source_code_lib/ → /外部目录（软链接）
→ 生成 .gitignore + codegraph.json
→ 清理旧索引
→ codegraph init（469 files，41 MB）
→ ✅ 完成
```

**示例二：Git + Gradle 项目**

```
用户：codegraph init
→ 检测到 Git，Gradle，已有 .gitignore
→ 追加缺失的 build/ 排除规则到 .gitignore
→ codegraph init
→ ✅ 完成
```

## 常见问题处理

| 问题 | 原因 | 处理 |
|------|------|------|
| init 卡在 Resolving refs | 软链接导致索引了外部大量文件 | Ctrl+C 停止，添加 `source_code_lib/**` 到排除列表后重建 |
| 文件数 6000+ | 软链接未排除或 target 未排除 | 检查 `.gitignore` 和 `codegraph.json` 是否都有排除规则 |
| `database is locked` | 旧版本 CodeGraph | 升级：`codegraph upgrade` |
| `Transport closed` | WSL2 跨文件系统问题 | 项目移到 Linux 原生文件系统，或设置 `CODEGRAPH_NO_DAEMON=1` |
