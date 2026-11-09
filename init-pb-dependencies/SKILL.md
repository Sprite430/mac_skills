---
name: init-pb-dependencies
description: PB/PbServer 项目产品化依赖映射初始化助手。解析项目 pom 中所有 com.ctjsoft 系产品化依赖的实际生效版本（pb、sccommon、authority、ssop 等），在产品化源码仓库（默认 /Users/zhangchengke/Documents/ZKJN/code/svn/source）中逐字符定位对应版本的源码目录，并在项目级 CLAUDE.md 与同构的 AGENTS.md 中生成/刷新「产品化依赖 ↔ 源码仓库映射」标记区块，取代 source_code_lib 软链方式。使用时机：用户说 init-pb-dependencies、初始化产品化依赖、生成产品化源码映射、更新源码映射、不再使用 source_code_lib、pb 版本升级后刷新源码映射。
author: Claude
---

# PB 产品化依赖 ↔ 源码映射初始化助手

解析项目 pom 的产品化依赖版本，定位本地产品化源码仓库中对应版本的源码目录，把映射写入项目级 CLAUDE.md（及同构的 AGENTS.md），替代 source_code_lib 软链方式。

## 使用场景

**触发条件（满足任一即应调用）：**
- 用户说「init-pb-dependencies」
- 用户说「初始化产品化依赖」「生成产品化源码映射」「更新源码映射」
- 用户说「不再使用 source_code_lib」「用源码仓库替代 source_code_lib」
- 项目根 pom 的 `pb.version` / `sccommon.version` 变更后需要刷新映射

**不触发的情况：**
- 非 PB 项目（pom 无 `com.ctjsoft` 系依赖）
- 项目 CLAUDE.md 已有映射区块，用户只是查询某构件源码在哪 → 直接按区块读取，不改文档
- 用户只问依赖版本、没要求更新文档 → 只回答，不写入

## 前置条件

- 当前目录是项目根目录（含 `pom.xml`）
- 产品化源码仓库存在，默认 `/Users/zhangchengke/Documents/ZKJN/code/svn/source`；默认路径不存在时必须先询问用户仓库位置，禁止编造路径
- 项目根有 `CLAUDE.md`；没有时先询问用户是否创建

## 强制规则

1. 只更新文档（项目 `CLAUDE.md` / `AGENTS.md`），不修改任何业务代码或构建配置。
2. 源码仓库只读：禁止修改其中任何文件，禁止在其中执行任何构建命令。
3. 版本必须逐字符匹配：`3.3.7.05` 不得归一化为 `3.3.7.5`；禁止浮点或数值近似比较（`3.4.10` ≠ `3.4.1`）。
4. 版本排序必须按段数值比较：`3.4.12 > 3.4.2`、`3.4.10 > 3.4.9`；禁止字符串排序。
5. 有依赖无源码时必须标注「未找到对应源码」，禁止编造路径。
6. 映射区块必须用 `<!-- pb-dependencies:start -->` 与 `<!-- pb-dependencies:end -->` 包裹；重复运行只替换区块内容，禁止追加重复区块，保证幂等。
7. 不修改 CodeGraph 自动生成区块（`<!-- codegraph:start -->` 到 `<!-- codegraph:end -->`）；其中若仍引用 `source_code_lib`，只向用户报告，由用户决定是否调整 `codegraph.json` 与生成模板。
8. 写入前必须展示「将写入的区块全文 + 将替换/修改的位置」，获得用户确认后才落盘。
9. 输出使用中文。

## 工作流

### 第一步：确认项目与 PB 判定

```bash
ls pom.xml 2>/dev/null && echo "POM_OK"
grep -rl 'com\.ctjsoft' --include='pom.xml' --exclude-dir=target --exclude-dir=source_code_lib . 2>/dev/null | head -20
grep -A 20 '<modules>' pom.xml
```

- 无 `pom.xml` 或无任何 `com.ctjsoft` 系依赖 → 报告「非 PB 产品化项目」并停止。
- 记录根 pom `<modules>` 列出的模块清单，后续逐模块解析。

### 第二步：解析产品化依赖

读取根 pom 与 `<modules>` 下每个模块的 pom：

1. 提取 `<properties>` 中的版本属性（`pb.version`、`sccommon.version` 及自定义属性）。
2. **递归展开 `${}` 属性插值**：如 `sccommon.version=${pb.version}-005` 且 `pb.version=3.4.9` → `3.4.9-005`。嵌套引用必须展开到底，禁止把 `${...}` 原样写入映射表。
3. 合并 `<dependencyManagement>` 与各模块 `<dependencies>` 中 groupId 以 `com.ctjsoft` 开头的依赖（跳过 `<scope>test</scope>`）。
4. 记录每个构件的版本来源，分三类：
   - `直接声明`：模块 pom 中写死版本号
   - `根属性`：版本引用 `${...}` 属性
   - `传递依赖`：模块未直接声明该构件（如银行模块未声明 pb，pb 经 sccommon 传递），版本取依赖链上游声明的版本

产出依赖清单：项目模块 / 构件坐标（groupId:artifactId）/ 生效版本 / 版本来源。

### 第三步：扫描源码仓库

```bash
SOURCE_ROOT=/Users/zhangchengke/Documents/ZKJN/code/svn/source
# 1. 列出 pb 源码目录（大小写两种前缀都要查：pb-* 与 Pb-1.0.0）
ls -d "$SOURCE_ROOT"/pb-*-sources 2>/dev/null
ls -d "$SOURCE_ROOT"/[Pp]b-*-sources 2>/dev/null | sort -u
# 2. 版本自证：目录名必须与 META-INF 中的构件版本一致
for d in "$SOURCE_ROOT"/[Pp]b-*-sources; do
  v=$(grep -m1 '^version=' "$d/META-INF/maven/com.ctjsoft/pb/pom.properties" 2>/dev/null | cut -d= -f2)
  echo "$(basename "$d") -> ${v:-<无 pom.properties，需人工核对>}"
done
# 3. tags 降级目录（1.x/2.x 完整工程与 Pb-2.1.1 提取源码）
ls -d "$SOURCE_ROOT"/tags/Product/* 2>/dev/null
```

- 目录名与 `pom.properties` 版本不一致时，报告不一致并以 `pom.properties` 为准，询问用户后再继续。
- 汇总仓库内全部可用 pb 版本（`sort -V` 或按段数值排序）。

### 第四步：建立映射

对第二步产出的每个产品化构件：

| 构件情况 | 源码定位规则 |
|---|---|
| 构件是当前项目自身模块（artifactId 在根 pom `<modules>` 中） | 项目内源码，路径写 `./<module>` |
| `artifactId=pb` | `<SOURCE_ROOT>/pb-<version>-sources`，逐字符匹配目录名（大小写不敏感兜底） |
| pb 根目录未命中 | 降级查 `<SOURCE_ROOT>/tags/Product/Pb-<version>` |
| 其他 `com.ctjsoft` 构件（authority、ssop 等） | 按 `<artifactId>-<version>-sources` 与关键词在 SOURCE_ROOT 下搜索 |
| 最终仍未找到 | 标注「未找到对应源码」，禁止编造 |

额外产出：仓库中全部可用 pb 版本清单（按段数值升序），供升级参考。

### 第五步：展示并确认

向用户展示，等待确认：

1. 依赖解析清单（模块 / 构件 / 版本 / 来源）
2. 映射表（含未找到源码的构件）
3. 将写入的区块全文
4. 将执行的文档变更：替换哪个章节、同步哪个文件、哪些引用改为指向映射章节

### 第六步：写入项目文档

对 `CLAUDE.md` 按以下优先级处理：

1. 已存在 `<!-- pb-dependencies:start/end -->` 区块 → 原地替换区块内容（幂等）。
2. 否则存在 `## source_code_lib` 章节 → 整段替换为新章节（保留其中的「关键包」清单到新区块）。
3. 两者都没有 → 在 Architecture 相关章节之后插入新章节。

同时：
- 将「模块依赖关系」等处旧的 `source_code_lib/...` 路径引用改为「见『产品化依赖 ↔ 源码仓库映射』章节」。
- `AGENTS.md` 若存在且包含同样的 `source_code_lib` 内容 → 做同样替换，保持两文件同构。
- 禁止触碰 `<!-- codegraph:start/end -->` 区块。

### 第七步：验证

```bash
# 1. 区块标记成对且唯一
grep -c 'pb-dependencies:start' CLAUDE.md
grep -c 'pb-dependencies:end' CLAUDE.md
# 2. 映射表中的每个源码路径真实存在
test -d "<映射表中的路径>" && echo OK
# 3. 版本与 pom 一致（抽查 pb.version 与映射表）
grep -m1 'pb.version' pom.xml
# 4. 幂等：对区块重新执行一遍替换逻辑后 diff 为空
```

报告：写入文件清单、映射条目数、未找到源码的构件、CodeGraph 区块中的 `source_code_lib` 残留提示。

## 输出区块模板

```markdown
<!-- pb-dependencies:start -->
## 产品化依赖 ↔ 源码仓库映射

> 本区块由 init-pb-dependencies skill 生成/更新，请勿手工编辑；产品化版本变更后重新运行该 skill。
> 用途：替代 source_code_lib 软链。查阅产品化源码时，按下表路径只读访问。

- 源码仓库根：`/Users/zhangchengke/Documents/ZKJN/code/svn/source`
- 定位规则：`<artifactId>-<version>-sources` 与 Maven 版本逐字符匹配；根目录未命中时回退 `tags/Product/Pb-<version>`
- 源码形态：jar 解包提取源码（非可构建工程），只读参考，禁止修改、禁止在其中执行构建

### 版本来源
- `pb.version` = 3.4.9（根 pom）
- `sccommon.version` = 3.4.9-005（= ${pb.version}-005）

### 模块 → 依赖 → 源码映射

| 项目模块 | 产品化构件 | 生效版本 | 版本来源 | 源码目录 |
|---|---|---|---|---|
| sccommon | `com.ctjsoft:pb` | 3.4.9 | 直接声明 | `/Users/zhangchengke/Documents/ZKJN/code/svn/source/pb-3.4.9-sources` |
| sccommon | `com.ctjsoft.elec.pb.sichuan:sccommon` | 3.4.9-005 | 根属性 | 项目内源码 `./sccommon` |
| luzhou | `com.ctjsoft:pb` | 3.4.9 | 经 sccommon 传递 | `/Users/zhangchengke/Documents/ZKJN/code/svn/source/pb-3.4.9-sources` |
| rcc | `com.ctjsoft:pb` | 3.4.9 | 经 sccommon 传递 | 同上 |
| haerbin | `com.ctjsoft:pb` | 3.4.9 | 经 sccommon 传递 | 同上 |
| boc | `com.ctjsoft:pb` | 3.4.9 | 经 sccommon 传递 | 同上 |
| boc | `com.ctjsoft.pb:authority` | 3.1.0 | 直接声明 | 未找到对应源码 |
| boc | `com.ctjsoft.pb:ssop` | 3.1.0 | 直接声明 | 未找到对应源码 |

### 源码仓库可用 pb 版本
1.0.0 / 3.2.2.32 / 3.3.4 / 3.3.7.05 / 3.4.2 / 3.4.8 / 3.4.9 / 3.4.10 / 3.4.12（另有 `tags/Product` 下 1.x/2.x 完整工程）

### 常用包路径
- `grp/exinterface/bankinterface/` — 银行接口抽象层
- `grp/pt/pb/` — 核心支付凭证处理
- `grp/pt/database/` — 数据库抽象（ODM 模式）
- `com/ctjsoft/pb/dao/` — BeetlSQL DAO 层
<!-- pb-dependencies:end -->
```

模板中的版本、路径、表格行必须来自本次实际解析结果，不得照抄示例数据。

## 使用示例

**示例 1：首次初始化**
- 用户：「初始化产品化依赖映射」
- 执行七步流程 → 展示映射表与区块 → 用户确认 → 写入 `CLAUDE.md` 与 `AGENTS.md` → 报告映射条数、未找到源码的构件。

**示例 2：pb 升级后刷新**
- 用户：「pb 升级到 3.4.10 了，刷新源码映射」
- 解析到 `pb.version=3.4.10` → 定位 `pb-3.4.10-sources` → 原地替换区块 → 验证路径存在、版本一致。

## 常见问题处理

| 问题 | 原因 | 处理 |
|---|---|---|
| 无 `pom.xml` 或无 `com.ctjsoft` 依赖 | 非 PB 产品化项目 | 报告并停止，不写入任何文件 |
| 某构件版本在源码仓库无对应目录 | 仓库未同步该版本，或构件本身无源码 | 标注「未找到对应源码」，并列出仓库可用版本 |
| 目录名与 `pom.properties` 版本不一致 | 目录被改名或内容错放 | 报告不一致，以 `pom.properties` 为准，询问用户 |
| `CLAUDE.md` 既无 `source_code_lib` 章节也无映射区块 | 首次初始化 | 在 Architecture 章节后插入新章节 |
| CodeGraph 区块内仍引用 `source_code_lib` | CodeGraph 自动生成区块 | 只报告，建议用户调整 `codegraph.json` 与生成模板 |
| `AGENTS.md` 与 `CLAUDE.md` 已不同构 | 两文件历史分化 | 按同样替换规则处理；结构差异过大时报告，由用户决定 |
| 多模块声明同一构件不同版本 | 版本覆盖 | 以各模块实际生效版本为准，表格按模块分行，不合并 |
