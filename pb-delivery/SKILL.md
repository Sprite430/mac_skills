---
name: pb-delivery
description: 用于 PbServer/国库集中支付/PB 2.x/3.x 需求开发和测试完成后生成交付包。Use when the user explicitly says pb-delivery; also use for PB/PbServer projects when the user says 开始交付、生成交付、开发完成、测试完成、打交付包。按 PB 版本和交付形态生成 deliveries/YYYY-MM-DD_需求名称/roundN/，包含 doc/readme.md、code/realware 现场覆盖包、database SQL、config 外部配置；支持 2.x realware、3.x jar 源码交付、3.x realware/信创 Web 包交付。For non-PB tool projects such as OracleMigrateTool, use only when explicitly invoked and generate a generic doc/code/database/config package without realware mapping.
---

# PB 交付助手

用于开发测试完成后，按 PB 版本和实际部署形态生成交付目录、说明文档、现场覆盖包、数据库脚本和配置文件。

## 强制规则

1. 只整理交付产物，不修改业务代码。
2. 输出必须使用中文。
3. 优先读取 `docs/requirement/*-prd.md` 中与需求名称匹配的 PRD。
4. 必须分开判断“PB 版本”和“交付形态”：3.x 既可能是 jar 源码交付，也可能是 realware/信创 Web 包交付。
5. PB realware 交付时，`code/` 默认放项目部署现场可覆盖的包路径，不是简单源码归档。
6. 自动收集变更后，必须让用户确认是否遗漏文件、是否有未纳入版本控制的新增文件。
7. 不要把 `source_code_lib/` 或产品化参考代码复制进交付包，除非用户明确要求。
8. 非 PB 工具项目不要创建 `code/realware`，除非用户明确要求按 PB 现场覆盖包交付。

## 和其他 Skill 的配合

- `pb-requirement` 生成 `docs/requirement/YYYY-MM-DD-<需求名称>-prd.md`。
- `pb-server-developer` 完成开发和验证。
- 本 skill 在最后生成 `deliveries/YYYY-MM-DD_<需求名称>/roundN/`。

## 交付目录结构

PB realware 交付固定输出到目标项目下：

```text
deliveries/
  YYYY-MM-DD_需求名称/
    roundN/
      doc/
        readme.md
      code/
        realware/
          ...
      database/
      config/
```

目录含义：

- `doc/readme.md`：说明文档，包含需求说明、变更清单、测试方案、测试范围、部署更新方式、回滚建议。
- `code/`：现场覆盖包。默认保持现场部署相对路径，例如 `code/realware/RCU_js/xxx.js`、`code/realware/WEB-INF/classes/grp/.../Xxx.class`。
- `database/`：SQL 脚本、数据库初始化或变更脚本。
- `config/`：不直接覆盖到 realware 的外部配置、部署说明配置、环境差异配置。若配置文件本身在现场 `realware/WEB-INF/classes/` 下覆盖，应同时或优先放入 `code/realware/WEB-INF/classes/...`。

不要默认创建独立 `classes/` 目录；class 文件作为现场覆盖包的一部分放入 `code/realware/WEB-INF/classes/...`。只有用户明确要求“单独 class 目录”时，才额外创建。

普通工具项目交付使用通用结构：

```text
deliveries/
  YYYY-MM-DD_需求名称/
    roundN/
      doc/
        readme.md
      code/
      database/
      config/
```

普通工具项目的 `code/` 保持项目相对路径，例如 `code/src/main/java/...`、`code/scripts/...`、`code/pom.xml`，不要映射成 `realware`。

## 识别顺序

### 第一步：判断是否 PB 项目

属于 PB/PbServer 项目时继续识别版本和交付形态。普通工具项目、迁移工具、命令行工具默认走“普通工具项目交付”，例如：

- `/Users/zhangchengke/Documents/ZKJN/code/svn/pbclient/trunk/yunwei/OracleMigrateTool`

如果用户没有明确调用 `pb-delivery` 或没有要求使用 PB 交付目录，非 PB 项目不要套用本 skill。

### 第二步：识别 PB 版本

2.x 常见特征：

- `realware/`
- `src/springmvc-servlet.xml`
- `src/spring-views.properties`
- 大量 `src/*-context.xml`
- 现场 class 路径通常是 `realware/WEB-INF/classes/...`

3.x 常见特征：

- 多 Maven 模块，如 `luzhou`、`rcc`、`boc`、`sccommon`
- 模块下有 `src/main/java`
- 模块下有 `src/main/resources`
- 模块下有 `src/main/webapp/WEB-INF/views` 或 `viewscustom`
- `target/` 下可能生成 `.jar`、`.war`，也可能生成展开的 Web 包目录

### 第三步：识别交付形态

realware 现场覆盖包：

- 项目根目录存在 `realware/`；或
- 3.x 模块 `target/` 下存在展开 Web 包目录，目录中有 `WEB-INF/`，例如 `rcc/target/rcc-3.4.9-005-001-20260525/WEB-INF/`；或
- 用户明确说明现场按 `realware` 覆盖部署。

3.x jar 源码交付：

- 现场由开发人员或部署人员自行编译 jar。
- 本 skill 不编译、不交付 jar，只整理源码、SQL、配置和说明。
- 如果 `target/*.jar` 存在，也不要默认放入交付包，除非用户明确要求。

无法判断时，先询问用户：“本次交付是 realware 现场覆盖包，还是 jar 源码交付？”

## 文件归类规则

### 2.x realware 交付

| 来源文件 | 交付路径 | 说明 |
|---|---|---|
| `realware/<省份>_js/xxx.js` | `code/realware/<省份>_js/xxx.js` | 页面 JS |
| `realware/WEB-INF/views/xxx.jsp` | `code/realware/WEB-INF/views/xxx.jsp` | JSP |
| `realware/WEB-INF/<定制>_jsp/xxx.jsp` | `code/realware/WEB-INF/<定制>_jsp/xxx.jsp` | 定制 JSP |
| `realware/WEB-INF/classes/.../*.class` | `code/realware/WEB-INF/classes/.../*.class` | 可执行 class |
| `src/.../*.java` | `code/source/src/.../*.java` | 源码留档，不作为现场覆盖路径 |
| `src/*.xml`、`src/*.properties` | `code/realware/WEB-INF/classes/...` 或 `config/` | 按现场实际位置放；无法确认时放 `config/` 并在 readme 说明 |
| SQL | `database/001_xxx.sql` | 数据库脚本 |

2.x 新增页面时，必须检查是否包含 `src/spring-views.properties`；若现场需要覆盖编译后配置，应确认它最终对应的现场路径。

### 3.x realware/信创 Web 包交付

优先从模块 `target/<展开包名>/` 取最终部署文件，而不是直接从 `src/main` 或 `target/classes` 取中间文件。示例：`rcc/target/rcc-3.4.9-005-001-20260525/WEB-INF/...`。

常见映射：

| target 展开包来源 | 交付路径 | 说明 |
|---|---|---|
| `target/<pkg>/WEB-INF/classes/static/RCU_js/xxx.js` | `code/realware/RCU_js/xxx.js` | 静态 JS 按现场 realware 静态目录覆盖 |
| `target/<pkg>/WEB-INF/classes/static/js/xxx.js` | `code/realware/js/xxx.js` | 公共 JS |
| `target/<pkg>/WEB-INF/classes/static/report/xxx.report` | `code/realware/report/xxx.report` | 报表文件 |
| `target/<pkg>/WEB-INF/views/xxx.jsp` | `code/realware/WEB-INF/views/xxx.jsp` | JSP |
| `target/<pkg>/WEB-INF/viewscustom/xxx.jsp` | `code/realware/WEB-INF/viewscustom/xxx.jsp` | 个性化 JSP |
| `target/<pkg>/WEB-INF/unity_jsp/xxx.jsp` | `code/realware/WEB-INF/unity_jsp/xxx.jsp` | 定制 JSP |
| `target/<pkg>/WEB-INF/classes/grp/.../*.class` | `code/realware/WEB-INF/classes/grp/.../*.class` | 业务 class |
| `target/<pkg>/WEB-INF/classes/com/.../*.class` | `code/realware/WEB-INF/classes/com/.../*.class` | 业务 class |
| `target/<pkg>/WEB-INF/classes/*.yml`、`*.properties` | `code/realware/WEB-INF/classes/xxx` 或 `config/xxx` | 若现场覆盖该文件则放 code；若只作配置参考则放 config |
| SQL | `database/001_xxx.sql` | 数据库脚本 |

注意：

- 3.x realware 包不要简单交付 `<module>/src/main/resources/static/...`，应优先交付编译/打包后的现场路径。
- 如果只修改了 JS/JSP，可只交付对应 `code/realware/...` 文件。
- 如果修改了 Java，通常需要交付编译后的 `.class`，路径必须来自最终 Web 包的 `WEB-INF/classes/...`。
- 不要默认交付整个 `WEB-INF/lib`，除非本次确实新增或升级依赖 jar。

### 3.x jar 源码交付

适用于用户明确说明由开发人员自行编译 jar 的场景。

| 来源文件 | 交付路径 | 说明 |
|---|---|---|
| `<module>/src/main/java/.../*.java` | `code/<module>/src/main/java/.../*.java` | 源码 |
| `<module>/src/main/resources/...` | `code/<module>/src/main/resources/...` 或 `config/` | 配置和资源 |
| `<module>/src/main/webapp/...` | `code/<module>/src/main/webapp/...` | JSP/Web 资源 |
| SQL | `database/001_xxx.sql` | 数据库脚本 |

jar 源码交付不默认复制 `target/*.jar`。`doc/readme.md` 中必须写明“由开发人员/部署人员按项目构建流程编译 jar”。

### 普通工具项目交付

适用于非 PB 的工具、迁移程序、命令行程序或脚本工程。

| 来源文件 | 交付路径 | 说明 |
|---|---|---|
| `src/...` | `code/src/...` | 源码 |
| `pom.xml`、`build.gradle` | `code/pom.xml`、`code/build.gradle` | 构建文件 |
| `scripts/...`、`bin/...` | `code/scripts/...`、`code/bin/...` | 脚本 |
| `*.properties`、`*.yml`、`*.xml` | `config/...` 或 `code/...` | 外部配置放 config，项目内配置按相对路径放 code |
| SQL | `database/001_xxx.sql` | 数据库脚本 |

普通工具项目 `doc/readme.md` 必须说明运行入口、运行参数、配置文件、输入输出、验证命令和回滚方式。

## 变更文件识别

按顺序检测：

1. Git：存在 `.git` 时使用 `git status --porcelain` 和必要的 `git diff --name-status`。
2. SVN：存在 `.svn` 时使用 `svn status`。
3. 都不存在时，要求用户手动提供变更文件清单。

自动检测后必须询问：

1. 自动检测到的变更文件是否完整？
2. 是否有未纳入版本控制的新增文件、SQL、class、JSP、JS 或配置文件需要加入？
3. 本次是第几轮交付，默认 `round1`。
4. 如果是 PB 3.x，确认交付形态：realware/信创 Web 包交付，还是 jar 源码交付。
5. 如果是普通工具项目，确认是否使用通用交付结构，且不要生成 `code/realware`。

## doc/readme.md 内容

```markdown
# <需求名称> 交付说明

## 基本信息

- 需求名称：
- 交付轮次：roundN
- 交付日期：
- 目标项目：
- 项目类型：PB/PbServer / 普通工具项目
- PB 版本：2.x/3.x/不适用
- 交付形态：realware 现场覆盖包 / 3.x jar 源码交付 / 普通工具项目交付
- 关联 PRD：

## 需求说明

引用或概述 PRD 中的自然语言需求，不写代码实现细节。

## 变更清单

| 类别 | 交付文件 | 现场覆盖路径/用途 |
|---|---|---|
| 现场覆盖包 | code/realware/... | realware/... |
| 工具源码 | code/... | 普通工具项目源码/脚本 |
| 数据库 | database/... | 执行 SQL |
| 配置 | config/... | 外部配置或人工核对 |

## 测试方案

说明测试入口、测试数据、正常场景、异常场景和回归范围。

## 测试范围

- 页面：
- 接口：
- 数据库：
- 配置/参数：
- 自动任务：
- 回归影响：

## 部署更新方式

1. 备份现场待覆盖文件。
2. 按需先执行 `database/` 中 SQL。
3. realware 交付时，将 `code/realware/` 下文件覆盖到现场 `realware/` 对应路径。
4. jar 源码交付时，由开发人员/部署人员按项目构建流程编译 jar，再按现场发布流程部署。
5. 普通工具项目交付时，按 readme 中运行入口和构建命令部署或执行。
6. 按需处理 `config/` 中外部配置。
7. 重启应用、刷新缓存或重新执行工具，按项目要求执行。

## 回滚建议

说明回滚文件、SQL 回滚或配置恢复方式；无法自动回滚时明确提示人工处理。

## 版本控制基线

- 工具：Git/SVN/手工
- 基线：
- 当前：
```

## 工作流程

1. 确认目标项目路径、需求名称和交付轮次。
2. 读取匹配 PRD；没有 PRD 时询问是否补充需求说明。
3. 判断项目类型：PB/PbServer 或普通工具项目。
4. PB 项目继续判断版本：2.x 或 3.x。
5. 判断交付形态：realware 现场覆盖包、3.x realware/信创 Web 包、3.x jar 源码交付，或普通工具项目交付。
6. 用版本控制自动识别变更文件。
7. 如果是 realware 交付，将源码变更映射到最终部署产物：JS/JSP/配置/class 优先从实际部署目录或 `target/<展开包名>/` 获取。
8. 如果是普通工具项目，保持项目相对路径，不做 realware 映射。
9. 让用户确认遗漏文件和未纳管文件。
10. 创建 `deliveries/YYYY-MM-DD_<需求名称>/roundN/`。
11. 按文件归类复制到 `doc/`、`code/`、`database/`、`config/`。
12. 生成 `doc/readme.md`。
13. 回复交付目录、文件数量、待人工确认事项。

## 命名规则

- 日期格式：`YYYY-MM-DD`。
- 需求目录：`YYYY-MM-DD_需求名称`。
- 轮次目录：`round1`、`round2`、`round3`。
- SQL 建议加执行顺序前缀：`001_xxx.sql`、`002_xxx.sql`。
