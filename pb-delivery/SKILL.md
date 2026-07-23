---
name: pb-delivery
description: 用于 PbServer/国库集中支付/PB 2.x/3.x 需求开发和测试完成后生成交付包。Use when the user explicitly says pb-delivery; also use for PB/PbServer projects when the user says 开始交付、生成交付、开发完成、测试完成、打交付包。默认生成匹配现场目录的编译/打包产物交付包，包括 class、JSP、JS、报表、配置、SQL、jar/war 等；只有用户明确要求源码时才额外加入源码及其项目相对路径。输出 deliveries/YYYY-MM-DD_需求名称/roundN-YYYY-MM-DD/、doc/readme.md、doc/manifest.sha256、code/、database/、config/。For non-PB tool projects, use only when explicitly invoked and apply the same deployable-artifact-first rule.
---

# PB 交付助手

用于开发测试完成后，按 PB 版本和实际部署形态生成交付目录、说明文档、现场覆盖包、数据库脚本和配置文件。

## 强制规则

1. 只整理交付产物，不修改业务代码。
2. 输出必须使用中文。
3. 优先读取 `docs/requirement/*-prd.md` 中与需求名称匹配的 PRD。
4. 必须分开判断“PB 版本”和“交付形态”：3.x 既可能是 realware/classes 增量覆盖包，也可能是完整 jar/war 二进制包。
5. PB realware 交付时，`code/` 默认放项目部署现场可覆盖的包路径，不是简单源码归档。
6. 自动收集变更后，必须让用户确认是否遗漏文件、是否有未纳入版本控制的新增文件。
7. 不要把 `source_code_lib/` 或产品化参考代码复制进交付包，除非用户明确要求。
8. 非 PB 工具项目不要创建 `code/realware`，除非用户明确要求按 PB 现场覆盖包交付。
9. 自动收集变更前必须确定版本控制基线，并分开处理新增、修改、删除和重命名；删除文件不能静默忽略。
10. 交付 `.class` 前必须确认最终部署产物来自当前交付基线的已验证构建，并收集该源码生成的主类、内部类和匿名类文件。
11. 复制配置前必须检查密码、密钥、token、证书、环境地址等敏感信息；没有用户明确确认时，不交付真实敏感值。
12. 文件收集完成后必须生成 `doc/manifest.sha256`，用于核验 `code/`、`database/`、`config/` 中交付文件的完整性。
13. 默认只交付编译或打包后的现场可部署产物。源码变更只用于定位对应产物，不要把 `.java`、`src/main/`、构建文件或其他源码自动放入交付包。
14. 只有用户明确要求“交付源码”“附带源码”或等价表达时，才把源码放入 `code/source/` 并保持目标项目相对路径；源码不能混入 `code/realware/`。
15. 找不到与源码变更对应的最终产物或无法确认现场目标路径时，必须暂停并要求先完成构建或确认路径，禁止用源码代替产物兜底。
16. 优先使用项目既有完整构建。只有完整构建因本次目标源码之外的冲突失败，且目标源码不依赖冲突源码时，才使用 `partial-javac-compile` 局部编译本次需求目标文件。
17. 不得为了完成交付而注释、修改或回滚无关冲突代码。局部编译必须写入独立临时目录，不得覆盖模块现有 `target/classes` 或其他构建产物。
18. 局部编译成功只表示目标源码通过当前 classpath 下的语法和类型检查，不能宣称完整 Maven 构建、测试或运行时验证通过。

## 和其他 Skill 的配合

- `pb-requirement` 生成 `docs/requirement/YYYY-MM-DD-<需求名称>-prd.md`。
- `pb-server-developer` 完成开发和验证。
- `partial-javac-compile` 仅在完整 Maven 构建被无关源码冲突阻断时，负责编译用户明确指定的一个或少量互相依赖目标源码；本 skill 负责验收其 `.class` 并映射现场路径。
- 本 skill 在最后生成 `deliveries/YYYY-MM-DD_<需求名称>/roundN-YYYY-MM-DD/`。

## 交付目录结构

PB realware 交付固定输出到目标项目下：

```text
deliveries/
  YYYY-MM-DD_需求名称/
    roundN-YYYY-MM-DD/
      doc/
        readme.md
        manifest.sha256
      code/
        realware/
          ...
      database/
      config/
```

目录含义：

- `doc/readme.md`：说明文档，包含需求说明、变更清单、测试方案、测试范围、部署更新方式、回滚建议。
- `doc/manifest.sha256`：`code/`、`database/`、`config/` 下交付文件的 SHA-256 清单。
- `code/`：编译/打包后的现场部署文件。默认保持现场目标目录的相对路径，例如 `code/realware/RCU_js/xxx.js`、`code/realware/WEB-INF/classes/grp/.../Xxx.class`；只有用户明确要求源码时才增加 `code/source/`。
- `database/`：SQL 脚本、数据库初始化或变更脚本。
- `config/`：不直接覆盖到 realware 的外部配置、部署说明配置、环境差异配置。若配置文件本身在现场 `realware/WEB-INF/classes/` 下覆盖，应同时或优先放入 `code/realware/WEB-INF/classes/...`。

不要默认创建独立 `classes/` 目录；class 文件作为现场覆盖包的一部分放入 `code/realware/WEB-INF/classes/...`。只有用户明确要求“单独 class 目录”时，才额外创建。

普通工具项目交付使用通用结构：

```text
deliveries/
  YYYY-MM-DD_需求名称/
    roundN-YYYY-MM-DD/
      doc/
        readme.md
        manifest.sha256
      code/
      database/
      config/
```

普通工具项目的 `code/` 默认放可直接部署或运行的 jar、war、可执行文件、运行脚本和资源，并保持用户确认的部署相对路径。源码和构建文件仅在用户明确要求源码时放入 `code/source/<项目相对路径>`，不要映射成 `realware`。

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

3.x jar/war 二进制交付：

- 现场按完整 jar/war 发布时，交付已经验证的最终 jar/war，不交付源码代替二进制包。
- 产物必须来自当前交付基线的构建结果，并在 readme 中记录构建命令、JDK、校验结果和现场目标路径。
- 不要把 jar/war 随意放到 `code/target/`；应按用户确认的现场部署相对路径放到 `code/<现场路径>/`。

无法判断时，先询问用户：“本次交付是 realware/classes 增量覆盖包，还是完整 jar/war 二进制包？”不要主动提供源码交付选项；只有用户明确要求源码时才增加源码。

## 文件归类规则

### 2.x realware 交付

| 来源文件 | 交付路径 | 说明 |
|---|---|---|
| `realware/<省份>_js/xxx.js` | `code/realware/<省份>_js/xxx.js` | 页面 JS |
| `realware/WEB-INF/views/xxx.jsp` | `code/realware/WEB-INF/views/xxx.jsp` | JSP |
| `realware/WEB-INF/<定制>_jsp/xxx.jsp` | `code/realware/WEB-INF/<定制>_jsp/xxx.jsp` | 定制 JSP |
| `realware/WEB-INF/classes/.../*.class` | `code/realware/WEB-INF/classes/.../*.class` | 可执行 class |
| `src/*.xml`、`src/*.properties` | `code/realware/WEB-INF/classes/...` 或 `config/` | 按现场实际位置放；无法确认时放 `config/` 并在 readme 说明 |
| SQL | `database/001_xxx.sql` | 数据库脚本 |

Java 源码变更只作为定位线索：根据包名和最终构建结果，在 `realware/WEB-INF/classes/...` 找到对应 `Xxx.class`、`Xxx$*.class`，再复制到相同的 `code/realware/WEB-INF/classes/...` 路径；不要复制 `.java` 兜底。

2.x 新增页面时，必须检查 `src/spring-views.properties` 是否产生需要现场覆盖的最终配置文件，并按其最终现场路径交付；不要直接因为源码文件发生变化就复制源码目录。

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
- 如果修改了 Java，通常需要交付编译后的 `.class`，路径必须来自最终 Web 包的 `WEB-INF/classes/...`。同一源码生成的主类、内部类和匿名类必须一起检查并交付，例如 `Xxx.class` 和 `Xxx$*.class`，不能只复制主类。
- `<module>/src/main/java/.../Xxx.java` 只用于定位 `<module>/target/<展开包>/WEB-INF/classes/.../Xxx.class` 和 `Xxx$*.class`；交付路径必须保持为 `code/realware/WEB-INF/classes/...`。
- 不要仅凭文件修改时间判断产物是否最新。必须记录构建命令、构建结果、构建时间、JDK 版本和产物来源目录，并确认构建基线与交付基线一致。
- 不要默认交付整个 `WEB-INF/lib`，除非本次确实新增或升级依赖 jar。

### 3.x jar/war 二进制交付

适用于现场按完整 jar/war 发布的场景。

| 最终产物 | 交付路径 | 说明 |
|---|---|---|
| `<module>/target/*.jar` | `code/<现场部署相对路径>/*.jar` | 已验证 jar，不保留 `target/` 源路径 |
| `<module>/target/*.war` | `code/<现场部署相对路径>/*.war` | 已验证 war |
| 外部配置 | `config/...` 或 `code/<现场部署相对路径>/...` | 按现场是否直接覆盖决定 |
| SQL | `database/001_xxx.sql` | 数据库脚本 |

无法确认 jar/war 的现场部署相对路径时必须询问用户，不要自行使用源码目录、Maven `target/` 目录或臆造目录。

### 源码附加交付（仅用户明确要求）

源码不是默认交付内容。用户明确要求交付或附带源码时，才按以下规则额外收集：

| 来源文件 | 交付路径 | 说明 |
|---|---|---|
| `src/...` | `code/source/src/...` | PB 2.x 保持项目相对路径 |
| `<module>/src/main/...` | `code/source/<module>/src/main/...` | PB 3.x 保持模块和项目相对路径 |
| `pom.xml`、`build.gradle` | `code/source/pom.xml`、`code/source/build.gradle` | 仅用户要求可构建源码包时加入 |

在 readme 中把源码列为“附加源码”，与现场部署产物分开说明。若用户明确要求纯源码交付，可以不生成二进制产物，但必须在 readme 标明“本包不能直接覆盖现场，需按项目构建流程编译”。

### 普通工具项目交付

适用于非 PB 的工具、迁移程序、命令行程序或脚本工程。

| 最终产物 | 交付路径 | 说明 |
|---|---|---|
| `target/*.jar`、`target/*.war`、`dist/...` | `code/<现场部署相对路径>/...` | 已验证构建产物 |
| `scripts/...`、`bin/...` | `code/<现场部署相对路径>/...` | 本身就是运行产物的脚本或可执行文件 |
| 运行所需资源 | `code/<现场部署相对路径>/...` | 保持实际运行目录结构 |
| 外部配置 | `config/...` 或 `code/<现场部署相对路径>/...` | 按现场是否直接覆盖决定 |
| SQL | `database/001_xxx.sql` | 数据库脚本 |

普通工具项目默认不复制 `src/`、`pom.xml` 或 `build.gradle`。用户明确要求源码时，按“源码附加交付”规则放入 `code/source/`。`doc/readme.md` 必须说明运行入口、运行参数、配置文件、输入输出、验证命令和回滚方式。

## 变更文件识别

先确定“从哪个版本到当前版本”的比较基线，再检测工作区变更。基线优先使用用户指定的 commit、tag、branch 或 SVN revision；用户未指定时，可使用当前分支的 upstream merge-base。无法可靠确定时，必须让用户确认，不能自行猜测。

按顺序检测：

1. Git：使用 `git status --porcelain`，并分别检查 `<base>...HEAD`、暂存区、未暂存区和未跟踪文件，避免只收集其中一层变更。
2. SVN：使用 `svn info` 记录仓库地址和 revision，使用 `svn status` 检查工作区；需要比较历史范围时使用用户确认的起止 revision。
3. 都不存在时，要求用户手动提供变更文件清单。

按变更类型处理：

- 新增/修改：按交付形态映射并复制实际文件。
- 删除：文件已不存在，不复制；必须在 `doc/readme.md` 的删除清单、部署步骤和回滚步骤中写明现场删除路径。
- 重命名：复制新路径，同时在 readme 写明旧路径删除和新路径新增，避免现场残留两份文件。
- 冲突、无法解释的大量修改或非本次需求改动：暂停收集，先向用户报告风险和文件清单。

自动检测后必须询问：

1. 自动检测到的变更文件是否完整？
2. 是否有未纳入版本控制的新增文件、SQL、class、JSP、JS 或配置文件需要加入？
3. 本次是第几轮交付，默认 `round1`。
4. 如果是 PB 3.x，确认交付形态：realware/classes 增量覆盖包，还是完整 jar/war 二进制包。
5. 如果是普通工具项目，确认实际运行产物和现场目标路径，且不要生成 `code/realware`。
6. 比较基线是否正确，删除和重命名清单是否完整？
7. 仅当用户明确要求源码时，确认是附带源码还是纯源码交付；用户未要求时不要主动加入源码。

## 构建产物与配置安全

PB realware 交付包含 `.class` 时：

1. 先尝试项目既有完整构建/测试并保存命令和结果；成功时优先从最终展开包收集产物。
2. 确认产物来自本次目标项目和本次交付基线，不从其他项目或旧包拼接。
3. 从最终展开 Web 包的 `WEB-INF/classes/` 收集产物；局部编译场景也必须包含同一源码生成的全部相关 `.class`。
4. 在 readme 记录构建命令、JDK、结果、时间和最终产物目录；无法证明来源时暂停交付并让用户确认。
5. 按最终部署目录计算交付路径。源码路径只用于定位产物，不得直接转换成 `code/source/`，也不得在找不到 `.class` 时退回交付 `.java`。

### 完整构建失败时的局部编译降级

完整构建失败后，先根据错误输出、目标源码依赖和版本控制变更清单判断失败是否与本次需求无关。只有同时满足以下条件时，才调用 `partial-javac-compile`：

1. 错误来自其他模块或本次需求未修改的源码。
2. 本次目标源码不直接依赖冲突源码，所需同模块/其他模块类型已有与当前基线匹配的 `.class`，或会作为少量目标源码一起编译。
3. 目标模块存在 `pom.xml`，`mvn` 与 `javac` 使用的 JDK 与目标环境一致。
4. 模块现有 `target/classes` 和加入 classpath 的其他模块产物可确认没有陈旧或版本错配。

满足条件后：

1. 把本次需求明确修改的一个或少量互相依赖 Java 文件作为目标源码，不要传入整个包目录或无关源码。
2. 完整遵循 `partial-javac-compile`：复用 Maven compile classpath 和已有 `target/classes`，使用空 `-sourcepath`，输出到独立临时目录。
3. 不要注释冲突代码、删除冲突文件、执行 `mvn clean`，也不要覆盖原有 `target/classes`。
4. 从局部输出目录收集本次产生的全部 `.class`，包括主类、内部类和匿名类；空输出目录可确保不会混入旧产物。
5. 根据 class 的包目录映射现场路径：`<临时输出>/grp/.../Xxx.class` 交付到 `code/realware/WEB-INF/classes/grp/.../Xxx.class`，其他包根同理。
6. 在 readme 标明本次是“局部 javac 编译交付”，记录完整构建失败摘要、目标源码、JDK、classpath 基线、临时输出目录、生成 class 清单和未完成的验证。

遇到以下任一情况必须停止局部编译和交付：

- 完整构建错误来自本次目标源码，或无法证明错误与目标源码无关。
- 目标源码依赖冲突源码、尚未编译源码、缺失的生成源码或不匹配的旧 `.class`。
- 构建依赖 annotation processor、Maven Toolchain、自定义编译器参数或 JPMS module-path。
- 需要验证 Spring 注入、AOP、事务、资源装配或其他运行时行为。
- 局部 `javac` 失败，或生成结果缺少应有的主类、内部类、匿名类。

复制 `.properties`、`.yml`、`.yaml`、`.xml`、证书或其他环境配置前：

1. 检查密码、私钥、secret、token、access key、证书口令、生产地址等敏感值。
2. 能模板化的配置使用占位符，并在 readme 说明由现场填写；不能模板化且必须交付真实值时，先获得用户明确确认。
3. 不在回复、日志或 readme 中回显真实敏感值，只记录文件路径和处理方式。

## 完整性清单

完成文件复制后，在轮次目录内生成 SHA-256 清单：

```bash
find code database config -type f -exec shasum -a 256 {} \; | LC_ALL=C sort > doc/manifest.sha256
```

生成后使用 `shasum -a 256 -c doc/manifest.sha256` 校验，必须全部通过。若环境使用 `sha256sum`，可使用等价命令，但 readme 中应写明实际生成和校验命令。

## doc/readme.md 内容

```markdown
# <需求名称> 交付说明

## 基本信息

- 需求名称：
- 交付轮次：roundN-YYYY-MM-DD
- 交付日期：
- 目标项目：
- 项目类型：PB/PbServer / 普通工具项目
- PB 版本：2.x/3.x/不适用
- 交付形态：realware/classes 增量覆盖包 / jar/war 二进制包 / 普通工具运行产物 / 纯源码交付（仅明确要求）
- 关联 PRD：
- 完整性清单：doc/manifest.sha256
- 源码要求：未要求 / 附带源码 / 纯源码交付

## 需求说明

引用或概述 PRD 中的自然语言需求，不写代码实现细节。

## 变更清单

| 类别 | 交付文件 | 现场覆盖路径/用途 |
|---|---|---|
| 现场覆盖包 | code/realware/... | realware/... |
| 二进制/运行产物 | code/... | 现场 jar、war、可执行文件或运行脚本路径 |
| 附加源码 | code/source/... | 仅用户明确要求；不作为现场直接覆盖文件 |
| 数据库 | database/... | 执行 SQL |
| 配置 | config/... | 外部配置或人工核对 |

## 删除与重命名清单

| 类型 | 原路径 | 新路径/处理方式 |
|---|---|---|
| 删除 |  | 现场删除并在回滚时恢复备份 |
| 重命名 |  | 删除旧路径并部署新路径 |

## 测试方案

说明测试入口、测试数据、正常场景、异常场景和回归范围。

## 测试范围

- 页面：
- 接口：
- 数据库：
- 配置/参数：
- 自动任务：
- 回归影响：

## 构建与验证记录

- 构建方式：完整 Maven 构建 / 局部 javac 编译
- 完整构建命令与结果：
- 完整构建失败摘要及与目标源码无关的判断依据：
- 局部编译目标源码：
- 局部编译命令/使用的 Skill：
- 构建时间：
- JDK/运行环境：
- classpath 基线：目标模块 target/classes、其他模块 target/classes、Maven 依赖
- 局部输出目录：
- 生成 class 清单：
- 最终产物来源目录：
- 未完成验证：完整构建/单元测试/集成测试/运行时验证
- SHA-256 校验结果：

## 敏感配置处理

- 检查范围：
- 脱敏/模板化文件：
- 经用户确认保留真实值的文件：只记录路径，不记录具体值

## 部署更新方式

1. 备份现场待覆盖文件。
2. 按需先执行 `database/` 中 SQL。
3. 按删除与重命名清单处理旧路径，执行前再次确认备份完整。
4. realware 交付时，将 `code/realware/` 下文件覆盖到现场 `realware/` 对应路径。
5. jar/war 二进制交付时，将已验证产物发布到 readme 记录的现场目标路径。
6. 普通工具项目交付时，按 readme 中运行入口和构建命令部署或执行。
7. 按需处理 `config/` 中外部配置，不直接覆盖未确认的环境敏感值。
8. 使用 `doc/manifest.sha256` 核验文件完整性。
9. 重启应用、刷新缓存或重新执行工具，按项目要求执行。

`code/source/` 仅用于用户明确要求的源码，不得把它当作上述现场覆盖步骤的输入；纯源码交付必须先按项目构建流程生成产物后才能部署。

## 回滚建议

说明回滚文件、SQL 回滚或配置恢复方式；无法自动回滚时明确提示人工处理。

## 版本控制基线

- 工具：Git/SVN/手工
- 基线 commit/tag/branch/revision：
- 当前 commit/revision：
- 工作区状态：干净/包含已确认的未提交变更
```

## 工作流程

1. 确认目标项目路径、需求名称和交付轮次。
2. 读取匹配 PRD；没有 PRD 时询问是否补充需求说明。
3. 判断项目类型：PB/PbServer 或普通工具项目。
4. PB 项目继续判断版本：2.x 或 3.x。
5. 判断交付形态：realware/classes 增量覆盖包、完整 jar/war 二进制包，或普通工具运行产物交付。
6. 确认版本控制基线，用版本控制识别已提交、暂存、未暂存、未跟踪和删除/重命名文件。
7. 让用户确认基线、遗漏文件、未纳管文件和删除/重命名清单。
8. 先执行项目既有完整构建/测试；成功时从实际部署目录或 `target/<展开包名>/` 收集最终 JS/JSP/配置/class/jar/war 等产物。
9. 完整构建失败时判断错误是否来自本次目标源码之外；符合降级条件时调用 `partial-javac-compile`，否则停止交付并报告原因。
10. 局部编译时只传入本次需求目标 Java 文件，验收临时输出目录中的全部主类、内部类和匿名类，并映射到现场 `WEB-INF/classes` 路径。
11. 找不到最终产物或现场目标路径时暂停，要求先完成构建或确认路径；不要复制源码兜底。
12. 如果是普通工具项目，按实际运行目录收集构建产物、脚本和资源，不做 realware 映射。
13. 只有用户明确要求源码时，才把源码按项目相对路径加入 `code/source/`，并与部署产物分开列示。
14. 检查待交付配置中的敏感信息并按确认结果脱敏、模板化或保留。
15. 创建 `deliveries/YYYY-MM-DD_<需求名称>/roundN-YYYY-MM-DD/`。
16. 按文件归类复制到 `doc/`、`code/`、`database/`、`config/`。
17. 生成 `doc/readme.md` 和 `doc/manifest.sha256`。
18. 校验 SHA-256 清单，确认全部通过。
19. 回复交付目录、部署产物数量、现场目标路径、构建方式、未完成验证、是否包含源码、基线和待人工确认事项。

## 命名规则

- 日期格式：`YYYY-MM-DD`。
- 需求目录：`YYYY-MM-DD_需求名称`。
- 轮次目录：`round1-YYYY-MM-DD`、`round2-YYYY-MM-DD`、`round3-YYYY-MM-DD`。
- SQL 建议加执行顺序前缀：`001_xxx.sql`、`002_xxx.sql`。
