---
name: pb-server-developer
description: 仅用于 PbServer、国库集中支付、代理银行 PB 2.x/3.x 产品化主线项目和基于产品化代码的地区个性化项目开发。Use only when the target is a PB/PbServer product or personalized project and the task involves JSP/ExtJS pages, MVC page status/column display configuration, new page data loading (loadXXX.do, direct query, bill engine), Controller/Service/DAO APIs, new pages, auto tasks/jobs, system parameters, yml/properties/xml configuration, GAP_MODULE/GAP_MENU/PB_SYS_BUTTON/PB_AUTO_TASK/PB_SYS_PARAM-style SQL, or source_code_lib/product baseline reference. Do not use for unrelated Java/tool projects such as OracleMigrateTool unless the user explicitly says to apply PB development rules.
---

# PbServer 开发助手

这个 skill 用于 PB 2.x/3.x 产品化和个性化项目开发。主文件只做“入口路由”：先识别项目、版本和场景，再按需读取 `references/` 里的场景说明，最后结合当前项目和产品化参考代码实施。

## 强制规则

1. 用户没有明确说“开始编码”“开始编写”“开始修改”或等价直接命令时，不得修改代码。
2. 编码前必须先做项目适用性判断；非 PB/PbServer 项目不要套用本 skill 的页面、GAP 表、realware、PB 自动任务规则。
3. 编码前必须完整理解需求、识别场景、查找当前项目已有实现、查找产品化或 `source_code_lib/` 参考实现。
4. 所有 `source_code_lib/` 目录只读，只能参考，不能修改。
5. 2.x/3.x 产品化基线项目默认只读；如果用户明确把产品化主线项目指定为目标项目，可以按产品化开发任务处理。
6. 对 `.java`、`.js`、`.jsp`、`.yml`、`.properties`、`.xml`、`.sh` 的真实新增/修改代码块，必须使用当前文件类型的注释语法添加成对 AI 标记：
   - 开始：`@AI-Begin <ID5> <DATE8> @@Claude`
   - 结束：`@AI-End <ID5> <DATE8> @@Claude`
   - `<ID5>` 是同一文件内不重复的 5 位大写字母/数字组合。
   - `<DATE8>` 是北京时间 `yyyyMMdd`。
7. 所有新增代码都要有有用注释，解释意图、边界或关键业务逻辑，不写重复表面语义的注释。
8. 保留用户已有改动，不回滚无关文件。

## 项目适用性判断

先判断目标项目是否属于本 skill：

| 项目类型 | 是否使用本 skill | 处理方式 |
|---|---|---|
| PB 2.x/3.x 产品化主线项目 | 是 | 用户明确指定为目标时可开发；否则默认作为参考 |
| 基于 PB 2.x/3.x 的省份/银行个性化项目 | 是 | 按版本和场景规则开发 |
| 当前项目含 `realware/`、`GAP_MODULE`、`PB_SYS_BUTTON`、`PB_AUTO_TASK`、PB Controller/Service 结构 | 是 | 继续识别 2.x/3.x 和场景 |
| 普通 Java 工具项目、迁移工具、脚本工具、非 PB Web 项目 | 否 | 不使用本 skill，改用普通项目开发方式 |
| 用户明确要求“在该工具项目中也按 PB 规则处理” | 谨慎使用 | 只使用用户指定的部分规则，并说明风险 |

示例：

- `/Users/zhangchengke/Documents/ZKJN/code/PbServerApplication` 是产品化主线工作区；如果用户明确要求修改主线，可以作为目标项目。
- `/Users/zhangchengke/Documents/ZKJN/code/svn/pbclient/trunk/yunwei/OracleMigrateTool` 是工具项目；默认不要套用 PB 页面、realware、GAP 表或 PB 自动任务规则。

## 已知代码库

当用户没有明确给出目标项目时，用这些路径辅助判断：

| 角色 | 版本 | 路径 | 默认策略 |
|---|---:|---|---|
| 3.x 产品化主线工作区 | 3.x | `/Users/zhangchengke/Documents/ZKJN/code/PbServerApplication` | 用户明确指定时可作为目标 |
| 3.x 产品化模块 | 3.x | `/Users/zhangchengke/Documents/ZKJN/code/PbServerApplication/pb` | 未指定为目标时默认只参考 |
| 2.x 产品化基线 | 2.x | `/Users/zhangchengke/Documents/ZKJN/code/svn/source/tags/Product/PB2.1.0(build20210918)` | 默认只参考 |
| 四川 3.x 个性化项目 | 3.x | `/Users/zhangchengke/Documents/ZKJN/code/svn/electronic/ProxyBank/ProxyBankV2/customize/sichuan/SiChuanApplication` | 被选中时可修改 |
| 四川 2.x 个性化项目 | 2.x | `/Users/zhangchengke/Documents/ZKJN/code/svn/pbclient_BankCustom/trunk/SiChuan/SiChuan_Server_Maven_Unity` | 被选中时可修改 |
| 运维迁移工具示例 | 非 PB 工具 | `/Users/zhangchengke/Documents/ZKJN/code/svn/pbclient/trunk/yunwei/OracleMigrateTool` | 默认不使用本 skill |

## 启动流程

1. 确认目标项目路径；如果不清楚，询问用户要操作哪个已知代码库。
2. 先做项目适用性判断；非 PB/PbServer 项目直接退出本 skill。
3. 按 `references/version-detection.md` 判断 2.x/3.x 和产品化/个性化类型。
4. 从下面的场景表中选择一个主场景。
5. 读取 `references/common-rules.md` 和对应场景文件。
6. 先在目标项目查同类实现，再查 `source_code_lib/` 或匹配版本的产品化基线。
7. 总结可能修改的文件和仍不确定的问题；如果用户还没有明确允许编码，停下来请求确认。
8. 获得允许后，只修改目标项目中与本次需求相关的文件。
9. 使用最小有效方式验证：编译/测试、定向 grep、SQL 自查或页面加载链路检查。

## 场景路由

| 用户需求 | 主场景 | 读取 |
|---|---|---|
| 已有页面新增按钮、工具栏按钮、个性化 JS 方法、按钮不显示 | 已有页面加按钮 | `references/scenario-add-button.md` |
| 已有 MVC 页面新增状态显示、列字段、显示字段、页面状态 SQL | 页面列/状态配置 | `references/scenario-status-column-config.md`（含可直接套用模板） |
| 新页面或已有页面新增 `loadXXX.do` 数据加载、分页查询、直连查询 / 单据引擎 | 页面数据加载 | `references/scenario-page-data-load.md` |
| 报错、异常、功能不生效、按钮/页面/接口问题定位和修复 | 问题定位/修复 | `references/scenario-debug-fix.md` |
| SQL 脚本、DDL/DML、跨库兼容、数据库字段/表/索引调整 | SQL/数据库兼容 | `references/scenario-sql-database.md` |
| 新增后端接口、Controller 方法、Service 方法、DAO/query、Ajax URL | 后端接口 | `references/scenario-backend-api.md` |
| 新建 JSP/ExtJS/MVC 页面，新增菜单/模块/按钮/状态 SQL | 新增页面 | `references/scenario-new-page.md` |
| 新建自动任务、定时任务、PB_AUTO_TASK、Job | 自动任务 | `references/scenario-auto-task.md` |
| 新增系统参数、业务开关、数据库参数、参数读取逻辑 | 系统参数 | `references/scenario-system-param.md` |
| 新增 `.properties`、`.yml`、XML bean/config、FTP/client/bank 配置项 | 配置文件参数 | `references/scenario-config-param.md` |
| 上传/下载接口、文件导入导出、3.x 网关免登录/白名单、安全拦截配置 | 文件/网关安全 | `references/scenario-file-gateway-security.md` |

如果一个需求跨多个场景，以用户可见入口为主场景；实现推进到其他层时，再读取对应的次级场景文件。

## 版本速记

- 2.x 通常有 `realware/`、`src/springmvc-servlet.xml`、`src/spring-views.properties`、大量 `*-context.xml`，Service 多通过 XML 配置。
- 3.x 通常是多 Maven 模块，有 `src/main/java`、`src/main/resources`、`src/main/webapp/WEB-INF/views`，Service 多使用注解。
- 2.x Controller 可使用注解，但 Service 实现原则上走 XML bean，不默认加 `@Service`。
- 3.x Service 实现通常使用 `@Service`。
- 2.x 新增页面必须维护 `src/spring-views.properties`。
- 3.x 个性化 JSP 覆盖通常放 `src/main/webapp/WEB-INF/viewscustom/`；普通产品或模块页面通常放 `views/`，最终以目标模块现有习惯为准。

## 参考文件索引

- `references/common-rules.md`：AI 标记、产品化只读、查找清单、验证要求。
- `references/version-detection.md`：2.x/3.x、产品化/个性化项目识别。
- `references/scenario-add-button.md`：初始化 JS、个性化 JS、`REF_JS`、`scripts.jsp`、`PB_SYS_BUTTON`。
- `references/scenario-status-column-config.md`：已有 MVC 页面上的状态、列字段、显示字段、`PB_MODULE_STATUS_UI`、`PB_MODULE_UI_DETAIL`。
- `references/sql-status-column-template.md`：已有 MVC 页面新增状态/挂页面/配列的直接 SQL 模板。
- `references/scenario-page-data-load.md`：新页面或已有页面的 `loadXXX.do` 数据加载、直连查询、单据引擎取数路径。
- `references/page-data-load-template.md`：通用直连查询模板，适合换到别的项目时直接套用。
- `references/scenario-debug-fix.md`：报错定位、功能不生效、最小修复和验证路径。
- `references/scenario-sql-database.md`：SQL/DDL/DML、跨 Oracle/PostgreSQL/GaussDB/达梦/DB2 等数据库兼容。
- `references/scenario-file-gateway-security.md`：上传/下载接口、文件路径安全，以及 3.x gateway/file-interceptor/ignore-urls 白名单。
- `references/scenario-backend-api.md`：2.x/3.x Controller、Service、DAO 接口模式。
- `references/scenario-new-page.md`：JSP、JS、Controller、Service、菜单/模块/状态/按钮 SQL。
- `references/scenario-auto-task.md`：Job 类和 `PB_AUTO_TASK`。
- `references/scenario-system-param.md`：数据库系统参数和业务开关。
- `references/scenario-config-param.md`：properties/yml/xml 配置参数。
- `references/templates.md`：常用模板和 SQL 骨架。

## 输出要求

使用本 skill 时：

- 先说明识别到的版本和项目类型。
- 优先给出具体文件路径和当前项目已有参考实现。
- 说明本次改动属于产品通用还是地区个性化。
- 生成 SQL 时，提示哪些 ID、CODE、JOB_NAME 或参数键必须在目标库执行前核对。
- 如果产品化参考代码与当前项目习惯冲突，优先跟随当前目标项目，并说明冲突点。
