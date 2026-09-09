---
name: pb-delivery
description: 用于 PbServer/国库集中支付/PB 2.x/3.x 需求开发和测试完成后生成交付包。Use when the user explicitly says pb-delivery; also use for PB/PbServer projects when the user says 开始交付、生成交付、开发完成、测试完成、打交付包。用户明确提供全量包路径时直接交付该包；未提供时默认生成增量覆盖包，只定向编译新增/修改的生产 Java，并把新增/修改的 JSP、JS、报表、配置、SQL 等映射到现场目录。只有用户明确要求源码时才加入 code/source。输出 deliveries/YYYY-MM-DD_需求名称/roundN-YYYY-MM-DD/、doc/readme.md、doc/manifest.sha256、code/、database/、config/。For non-PB tool projects, use only when explicitly invoked and apply the same incremental-first rule.
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
16. 用户明确说明全量包并提供路径时，校验该文件/目录和现场目标路径后直接交付，不在本 skill 中重新构建全量包。
17. 用户未提供全量包时默认增量交付：只使用 `partial-javac-compile` 编译本次新增/修改的生产 Java；JS、JSP、报表、SQL、配置等非 Java 文件直接按现场目录映射。
18. 项目只支持整体 jar/war 替换、不能覆盖松散 class/资源且用户未提供全量包时，必须停止并要求开发人员提供全量包路径。
19. 不得为了完成交付而注释、修改或回滚无关冲突代码。局部编译必须写入独立临时目录，不得覆盖模块现有 `target/classes` 或其他构建产物。
20. 局部编译成功只表示目标源码通过当前 classpath 下的语法和类型检查，不能宣称完整 Maven 构建、测试或运行时验证通过。
21. 每次生成 `roundN-YYYY-MM-DD/` 轮次目录时，日期必须取当前运行日期（执行 `date +%F`），禁止沿用或复制上次打包的 round 日期；同一自然日多次打轮次包时，轮次序号递增、日期仍为当天。

## 和其他 Skill 的配合

- `pb-requirement` 生成 `docs/requirement/YYYY-MM-DD-<需求名称>-prd.md`。
- `pb-server-developer` 完成开发和验证。
- `partial-javac-compile` 负责在默认增量交付中编译本次新增/修改的一个或少量互相依赖生产 Java；也可处理完整构建被无关源码冲突阻断的场景。本 skill 负责验收 `.class` 并映射现场路径。
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
- `doc/manifest.sha256`：`code/`、`database/`、`config/` 下交付文件的 SHA-256 清单。清单路径相对于项目 `deliveries/` 根目录，必须从 `YYYY-MM-DD_需求名称/roundN-YYYY-MM-DD/...` 开始，不写绝对路径，也不只写 `code/...`。
- `YYYY-MM-DD_需求名称.zip`：最终交付压缩包，压缩整个需求文件夹，位于 `deliveries/` 根目录、与需求文件夹同级，每次打完 round 包后生成并覆盖，生成时机和命令见“交付包压缩（最终步骤）”。
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

3.x jar/war 全量包交付：

- 只有用户明确说明全量交付并提供 jar/war 或完整 Web 包路径时，才进入此分支。
- 校验用户提供路径存在且可读，记录 SHA-256、来源路径和现场目标路径；不要在本 skill 中执行完整 Maven 构建。
- 不要把全量包随意放到 `code/target/`；应按用户确认的现场部署相对路径放到 `code/<现场路径>/`。
- 项目只支持全量包发布但用户没有提供路径时停止，不生成松散 `.class` 冒充可部署包。

用户没有说明全量包路径时默认 realware/classes 增量覆盖包。若无法确认现场是否支持松散 class/资源覆盖，必须先询问；不要主动提供源码交付选项。

## 文件归类规则

### 2.x realware 交付

| 来源文件 | 交付路径 | 说明 |
|---|---|---|
| `realware/<省份>_js/xxx.js` | `code/realware/<省份>_js/xxx.js` | 页面 JS |
| `realware/WEB-INF/views/xxx.jsp` | `code/realware/WEB-INF/views/xxx.jsp` | JSP |
| `realware/WEB-INF/<定制>_jsp/xxx.jsp` | `code/realware/WEB-INF/<定制>_jsp/xxx.jsp` | 定制 JSP |
| `<局部输出>/<包路径>/*.class` | `code/realware/WEB-INF/classes/<包路径>/*.class` | 本次新增/修改 Java 的定向编译产物 |
| `src/*.xml`、`src/*.properties` | `code/realware/WEB-INF/classes/...` 或 `config/` | 按现场实际位置放；无法确认时放 `config/` 并在 readme 说明 |
| SQL | `database/001_xxx.sql` | 数据库脚本 |

新增/修改 Java 使用 `partial-javac-compile` 输出到空临时目录，根据包路径收集 `Xxx.class`、`Xxx$*.class`，再复制到对应 `code/realware/WEB-INF/classes/...`；不要使用 `realware/` 中可能陈旧的旧 class，也不要复制 `.java` 兜底。

2.x 新增页面时，必须检查 `src/spring-views.properties` 是否产生需要现场覆盖的最终配置文件，并按其最终现场路径交付；不要直接因为源码文件发生变化就复制源码目录。

### 3.x realware/classes 增量交付

Java 使用局部编译产物；无需构建转换的 JS、JSP、报表和配置直接从本次变更文件映射到现场目录。

常见映射：

| 增量来源 | 交付路径 | 说明 |
|---|---|---|
| `<局部输出>/grp/.../*.class` | `code/realware/WEB-INF/classes/grp/.../*.class` | 业务 class、内部类和匿名类 |
| `<局部输出>/com/.../*.class` | `code/realware/WEB-INF/classes/com/.../*.class` | 其他包根下的业务 class |
| `<module>/src/main/resources/static/RCU_js/xxx.js` | `code/realware/RCU_js/xxx.js` | 无转换时直接复制静态 JS |
| `<module>/src/main/resources/static/js/xxx.js` | `code/realware/js/xxx.js` | 无转换时直接复制公共 JS |
| `<module>/src/main/resources/static/report/xxx.report` | `code/realware/report/xxx.report` | 无转换时直接复制报表 |
| `<module>/src/main/webapp/WEB-INF/views/xxx.jsp` | `code/realware/WEB-INF/views/xxx.jsp` | JSP |
| `<module>/src/main/webapp/WEB-INF/viewscustom/xxx.jsp` | `code/realware/WEB-INF/viewscustom/xxx.jsp` | 个性化 JSP |
| `<module>/src/main/webapp/WEB-INF/unity_jsp/xxx.jsp` | `code/realware/WEB-INF/unity_jsp/xxx.jsp` | 定制 JSP |
| `<module>/src/main/resources/*.yml`、`*.properties` | `code/realware/WEB-INF/classes/xxx` 或 `config/xxx` | 按现场是否直接覆盖决定 |
| SQL | `database/001_xxx.sql` | 数据库脚本 |

注意：

- Java 只编译版本控制基线与用户确认清单中的新增/修改 `src/main/java`；`src/test/java` 不进入部署包。
- 如果只修改 JS/JSP/配置等非 Java 文件，直接按表中路径交付，不执行完整 Maven 构建。
- 如果 Maven filtering、资源替换、压缩、打包插件或前端构建会改变文件内容，必须使用转换后的最终产物；最终产物不可用时停止，不复制源文件冒充最终产物。
- 同一源码生成的主类、内部类和匿名类必须一起检查并交付，例如 `Xxx.class` 和 `Xxx$*.class`，不能只复制主类。
- 不要默认交付整个 `WEB-INF/lib`，除非本次确实新增或升级依赖 jar。

### 3.x jar/war 全量包交付

仅适用于用户明确提供全量包路径的场景。

| 最终产物 | 交付路径 | 说明 |
|---|---|---|
| `<用户提供路径>/*.jar` | `code/<现场部署相对路径>/*.jar` | 校验存在性和 SHA-256 后直接交付 |
| `<用户提供路径>/*.war` | `code/<现场部署相对路径>/*.war` | 校验存在性和 SHA-256 后直接交付 |
| `<用户提供完整 Web 包目录>/...` | `code/<现场部署相对路径>/...` | 保持用户确认的完整目录结构 |
| 外部配置 | `config/...` 或 `code/<现场部署相对路径>/...` | 按现场是否直接覆盖决定 |
| SQL | `database/001_xxx.sql` | 数据库脚本 |

无法确认全量包来源或现场部署相对路径时必须询问用户，不要自行构建、使用其他 `target/` 产物或臆造目录。

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
4. 用户是否已经明确说明全量包并提供路径？未提供时直接采用增量交付，不反复询问是否需要全量包。
5. 现场是否支持松散 class/资源覆盖？只支持整体 jar/war 且缺少全量包时停止。
6. 如果是普通工具项目，确认实际运行产物和现场目标路径，且不要生成 `code/realware`。
7. 比较基线是否正确，删除和重命名清单是否完整？
8. 仅当用户明确要求源码时，确认是附带源码还是纯源码交付；用户未要求时不要主动加入源码。

## 增量交付与配置安全

PB realware 交付包含 `.class` 时：

1. 未提供全量包时不要执行完整 Maven 构建，直接从已确认变更清单筛选新增/修改的 `src/main/java`。
2. 调用 `partial-javac-compile` 把这些目标源码编译到独立空临时目录；少量目标源码互相依赖时一次编译。
3. 确认 classpath、已有 `target/classes` 和其他模块已编译类与当前基线匹配，不从其他项目或旧包拼接。
4. 收集临时目录中全部主类、内部类和匿名类，并按包路径映射到 `code/realware/WEB-INF/classes/...`。
5. 在 readme 记录目标源码、JDK、classpath、命令、结果、时间和局部输出目录；无法证明来源时停止。

### 增量 Java 定向编译

未提供全量包且存在新增/修改的生产 Java 时，满足以下条件即可调用 `partial-javac-compile`，不要求先运行完整 Maven 构建：

1. 目标源码来自用户确认的版本控制变更清单，只包含新增/修改的 `src/main/java`；测试源码不进入部署包。
2. 目标源码所需同模块/其他模块类型已有与当前基线匹配的 `.class`，或属于本次少量互相依赖目标源码并会一起编译。
3. 目标模块存在 `pom.xml`，`mvn` 与 `javac` 使用的 JDK 与目标环境一致。
4. 模块现有 `target/classes` 和加入 classpath 的其他模块产物可确认没有陈旧或版本错配。

满足条件后：

1. 把本次需求明确修改的一个或少量互相依赖 Java 文件作为目标源码，不要传入整个包目录或无关源码。
2. 完整遵循 `partial-javac-compile`：复用 Maven compile classpath 和已有 `target/classes`，使用空 `-sourcepath`，输出到独立临时目录。
3. 不要注释冲突代码、删除冲突文件、执行 `mvn clean`，也不要覆盖原有 `target/classes`。
4. 从局部输出目录收集本次产生的全部 `.class`，包括主类、内部类和匿名类；空输出目录可确保不会混入旧产物。
5. 根据 class 的包目录映射现场路径：`<临时输出>/grp/.../Xxx.class` 交付到 `code/realware/WEB-INF/classes/grp/.../Xxx.class`，其他包根同理。
6. 在 readme 标明本次是“增量 javac 编译交付”，记录目标源码、JDK、classpath 基线、临时输出目录、生成 class 清单和未完成的验证。

遇到以下任一情况必须停止局部编译和交付：

- 目标源码依赖冲突源码、尚未编译源码、缺失的生成源码或不匹配的旧 `.class`。
- 构建依赖 annotation processor、Maven Toolchain、自定义编译器参数或 JPMS module-path。
- 需要验证 Spring 注入、AOP、事务、资源装配或其他运行时行为。
- 局部 `javac` 失败，或生成结果缺少应有的主类、内部类、匿名类。

### 非 Java 增量文件

- JS、JSP、报表、SQL、properties、yml、xml 等无需构建转换时，直接取本次新增/修改文件并按“文件归类规则”映射，不执行完整 Maven 构建。
- `src/test`、开发说明、IDE 文件和普通源码不属于部署文件，除非用户明确要求。
- 如果 Maven filtering、资源替换、压缩、打包插件或前端构建会改变文件内容，必须使用转换后的最终产物；最终产物不可用时停止并说明原因。
- 不要因为 `target/` 中存在旧文件就优先使用旧产物。直接复制前确认目标文件不需要转换，使用本次变更文件作为来源。

复制 `.properties`、`.yml`、`.yaml`、`.xml`、证书或其他环境配置前：

1. 检查密码、私钥、secret、token、access key、证书口令、生产地址等敏感值。
2. 能模板化的配置使用占位符，并在 readme 说明由现场填写；不能模板化且必须交付真实值时，先获得用户明确确认。
3. 不在回复、日志或 readme 中回显真实敏感值，只记录文件路径和处理方式。

## 完整性清单

完成文件复制后，以项目 `deliveries/` 目录为基准生成 SHA-256 清单。`manifest.sha256` 中每行的文件路径必须从需求日期目录开始，例如 `2026-07-20_新版本公务卡入库流水/round2-2026-07-23/code/realware/WEB-INF/classes/...`；禁止写入 `/Users/...` 等绝对路径，也禁止只写 `code/...`。

```bash
DELIVERIES_ROOT="deliveries"
ROUND_REL="2026-07-20_新版本公务卡入库流水/round2-2026-07-23"
test -d "$DELIVERIES_ROOT/$ROUND_REL"
(
  cd "$DELIVERIES_ROOT"
  find "$ROUND_REL/code" "$ROUND_REL/database" "$ROUND_REL/config" \
    -type f -exec shasum -a 256 {} \; | LC_ALL=C sort \
    > "$ROUND_REL/doc/manifest.sha256"
  shasum -a 256 -c "$ROUND_REL/doc/manifest.sha256"
)
```

生成和校验都必须从 `deliveries/` 根目录进行，清单中的路径才能与校验命令一致。若环境使用 `sha256sum`，可使用等价命令，但 readme 中应写明实际生成和校验命令及相对路径基准。

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
- 交付模式：默认增量交付 / 开发人员提供全量包 / 纯源码交付（仅明确要求）
- 部署形态：realware/classes 覆盖 / 整体 jar/war / 普通工具运行产物
- 全量包来源路径：未提供 / 用户提供路径
- 全量包 SHA-256：
- 全量包现场目标路径：
- 关联 PRD：
- 完整性清单：doc/manifest.sha256
- 清单相对路径基准：项目 `deliveries/` 根目录
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

- Java 处理：无 Java 变更 / 增量 javac 编译 / 使用用户提供全量包
- 增量编译目标源码：
- 增量编译命令/使用的 Skill：
- 构建时间：
- JDK/运行环境：
- classpath 基线：目标模块 target/classes、其他模块 target/classes、Maven 依赖
- 局部输出目录：
- 生成 class 清单：
- 非 Java 直接映射文件：
- 使用转换后最终产物的文件及来源：
- 未执行/未完成验证：完整构建、单元测试、集成测试、运行时验证
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
5. 用户提供全量包时，将已校验的全量包发布到 readme 记录的现场目标路径；不要混入本地推测的其他全量产物。
6. 普通工具项目交付时，按 readme 中运行入口和构建命令部署或执行。
7. 按需处理 `config/` 中外部配置，不直接覆盖未确认的环境敏感值。
8. 进入项目 `deliveries/` 根目录，使用 `doc/manifest.sha256` 核验文件完整性；不要从其他目录运行校验命令。
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

1. 确认目标项目路径、需求名称和交付轮次；轮次目录日期执行 `date +%F` 取当前日期，不要沿用上次打包的 round 日期（同一自然日多次交付时轮次序号递增、日期不变）。
2. 读取匹配 PRD；没有 PRD 时询问是否补充需求说明。
3. 判断项目类型：PB/PbServer 或普通工具项目。
4. PB 项目继续判断版本：2.x 或 3.x。
5. 检查用户是否明确提供全量包路径；提供时校验路径、SHA-256 和现场目标路径，直接进入全量包交付分支。
6. 用户未提供全量包时采用增量交付；项目只支持整体 jar/war 发布时停止并要求开发人员提供全量包。
7. 确认版本控制基线，用版本控制识别已提交、暂存、未暂存、未跟踪和删除/重命名文件。
8. 让用户确认基线、遗漏文件、未纳管文件和删除/重命名清单。
9. 增量交付时筛选新增/修改的 `src/main/java`，调用 `partial-javac-compile` 定向编译，不执行完整 Maven 构建。
10. 验收临时输出目录中的全部主类、内部类和匿名类，并按包路径映射到现场 `WEB-INF/classes`。
11. JS、JSP、报表、SQL、配置等非 Java 文件无需转换时直接按现场路径复制；需要构建转换时使用最终产物。
12. 找不到转换后产物或现场目标路径时停止；不要使用旧 `target/` 文件、源码或原始资源兜底。
13. 如果是普通工具项目，按实际运行方式判断是否支持增量文件；只支持整体包时同样要求用户提供全量包。
14. 只有用户明确要求源码时，才把源码按项目相对路径加入 `code/source/`，并与部署产物分开列示。
15. 检查待交付配置中的敏感信息并按确认结果脱敏、模板化或保留。
16. 创建 `deliveries/YYYY-MM-DD_<需求名称>/roundN-YYYY-MM-DD/`。
17. 按文件归类复制到 `doc/`、`code/`、`database/`、`config/`。
18. 生成 `doc/readme.md` 和 `doc/manifest.sha256`。
19. 校验 SHA-256 清单，确认全部通过。
20. 进入 `deliveries/` 根目录，将整个需求文件夹 `YYYY-MM-DD_<需求名称>/` 压缩为 `YYYY-MM-DD_<需求名称>.zip`；已有同名 zip 时先删除再压缩，确保覆盖为包含最新 round 的内容，命令见“交付包压缩（最终步骤）”。
21. 回复交付目录、交付模式、部署产物数量、现场目标路径、未完成验证、是否包含源码、基线和待人工确认事项。

## 交付包压缩（最终步骤）

`doc/manifest.sha256` 校验全部通过后，把整个需求文件夹压缩为单个 zip，输出到 `deliveries/` 根目录、与需求文件夹同级：

```text
deliveries/
  YYYY-MM-DD_需求名称/
    roundN-YYYY-MM-DD/...
  YYYY-MM-DD_需求名称.zip
```

**不要使用 macOS 自带 `zip` 或 `ditto` 压缩含中文的路径**：macOS 自带 zip 是 Apple 修改版 Info-ZIP 3.0，不支持 `-UN` 选项且不受 `LC_ALL` 影响，ditto 也不设置条目名 UTF-8 标志位（flag bit 0x800），中文条目名被按 cp437 解码，Windows/Linux 解压后乱码，接收方无法按 manifest 中文路径校验。必须在 `deliveries/` 根目录下用 Python 内置 zipfile 压缩：

```bash
cd deliveries
python3 - <<'PYEOF'
import os, sys, zipfile

src = "YYYY-MM-DD_<需求名称>"
dst = src + ".zip"
if os.path.exists(dst):
    os.remove(dst)
with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk(src):
        for d in dirs:
            p = os.path.join(root, d)
            z.write(p, os.path.relpath(p, os.getcwd()) + "/")
        for f in files:
            p = os.path.join(root, f)
            z.write(p, os.path.relpath(p, os.getcwd()))
bad = [i.filename for i in zipfile.ZipFile(dst).infolist()
       if any(ord(c) > 127 for c in i.filename) and not (i.flag_bits & 0x800)]
if bad:
    sys.exit("zip 条目缺少 UTF-8 标志: " + str(bad))
print("zip 完成:", dst, "条目数:", len(zipfile.ZipFile(dst).infolist()))
PYEOF
```

- 必须在 `deliveries/` 根目录下执行，zip 内部路径才会从 `YYYY-MM-DD_<需求名称>/` 开始，与 `doc/manifest.sha256` 的相对路径基准一致，接收方解压后可直接按清单校验。
- 已有同名 zip 时脚本先删除再重新压缩，保证覆盖为包含最新 round 的内容，不会残留上一轮已删除或替换的条目。
- Python 对含非 ASCII 字符的条目自动设置 UTF-8 标志位（0x800）；脚本末尾校验所有非 ASCII 条目都带该标志，缺失即退出，禁止交付乱码包。
- 系统无 `python3`（未安装 Command Line Tools）时提示用户安装后重试，不要回退到会产生乱码的 `zip`/`ditto`。

## 命名规则

- 日期格式：`YYYY-MM-DD`。
- 需求目录：`YYYY-MM-DD_需求名称`。
- 轮次目录：`round1-YYYY-MM-DD`、`round2-YYYY-MM-DD`、`round3-YYYY-MM-DD`；日期取生成轮次包当天的当前日期（`date +%F`），不得沿用上次打包的日期；同一自然日多次交付时轮次序号递增、日期相同。
- SQL 建议加执行顺序前缀：`001_xxx.sql`、`002_xxx.sql`。
