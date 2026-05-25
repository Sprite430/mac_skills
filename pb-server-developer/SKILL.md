---
name: pb-server-developer
description: 用于 PbServer、国库集中支付、代理银行 PB 2.x/3.x 产品化项目和基于产品化代码的地区个性化项目开发。Use when adding buttons to existing JSP/ExtJS pages, adding backend Controller/Service/DAO APIs, creating new pages, creating auto tasks/jobs, adding system parameters, adding yml/properties/xml configuration parameters, generating SQL for GAP_MODULE/GAP_MENU/PB_SYS_BUTTON/PB_AUTO_TASK/PB_SYS_PARAM-style tables, and safely referencing source_code_lib or PB product baseline projects without modifying them.
---

# PbServer 开发助手

这个 skill 用于 PB 2.x/3.x 产品化和个性化项目开发。主文件只做“入口路由”：先识别项目、版本和场景，再按需读取 `references/` 里的场景说明，最后结合当前项目和产品化参考代码实施。

## 强制规则

1. 用户没有明确说“开始编码”“开始编写”“开始修改”或等价直接命令时，不得修改代码。
2. 编码前必须完整理解需求、识别场景、查找当前项目已有实现、查找产品化或 `source_code_lib/` 参考实现。
3. 所有 `source_code_lib/` 目录只读，只能参考，不能修改。
4. 2.x/3.x 产品化基线项目默认只读，除非用户明确要求修改产品化代码。
5. 对 `.java`、`.js`、`.jsp`、`.yml`、`.properties`、`.xml`、`.sh` 的真实新增/修改代码块，必须使用当前文件类型的注释语法添加成对 AI 标记：
   - 开始：`@AI-Begin <ID5> <DATE8> @@Codex`
   - 结束：`@AI-End <ID5> <DATE8> @@Codex`
   - `<ID5>` 是同一文件内不重复的 5 位大写字母/数字组合。
   - `<DATE8>` 是北京时间 `yyyyMMdd`。
6. 所有新增代码都要有有用注释，解释意图、边界或关键业务逻辑，不写重复表面语义的注释。
7. 保留用户已有改动，不回滚无关文件。

## 已知代码库

当用户没有明确给出目标项目时，用这些路径辅助判断：

| 角色 | 版本 | 路径 | 默认策略 |
|---|---:|---|---|
| 3.x 产品化基线 | 3.x | `/Users/zhangchengke/Documents/ZKJN/code/PbServerApplication/pb` | 默认只参考 |
| 2.x 产品化基线 | 2.x | `/Users/zhangchengke/Documents/ZKJN/code/svn/source/tags/Product/PB2.1.0(build20210918)` | 默认只参考 |
| 四川 3.x 个性化项目 | 3.x | `/Users/zhangchengke/Documents/ZKJN/code/svn/electronic/ProxyBank/ProxyBankV2/customize/sichuan/SiChuanApplication` | 被选中时可修改 |
| 四川 2.x 个性化项目 | 2.x | `/Users/zhangchengke/Documents/ZKJN/code/svn/pbclient_BankCustom/trunk/SiChuan/SiChuan_Server_Maven_Unity` | 被选中时可修改 |

## 启动流程

1. 确认目标项目路径；如果不清楚，询问用户要操作哪个已知代码库。
2. 按 `references/version-detection.md` 判断 2.x/3.x 和产品化/个性化类型。
3. 从下面的场景表中选择一个主场景。
4. 读取 `references/common-rules.md` 和对应场景文件。
5. 先在目标项目查同类实现，再查 `source_code_lib/` 或匹配版本的产品化基线。
6. 总结可能修改的文件和仍不确定的问题；如果用户还没有明确允许编码，停下来请求确认。
7. 获得允许后，只修改目标项目中与本次需求相关的文件。
8. 使用最小有效方式验证：编译/测试、定向 grep、SQL 自查或页面加载链路检查。

## 场景路由

| 用户需求 | 主场景 | 读取 |
|---|---|---|
| 已有页面新增按钮、工具栏按钮、个性化 JS 方法、按钮不显示 | 已有页面加按钮 | `references/scenario-add-button.md` |
| 新增后端接口、Controller 方法、Service 方法、DAO/query、Ajax URL | 后端接口 | `references/scenario-backend-api.md` |
| 新建 JSP/ExtJS/MVC 页面，新增菜单/模块/按钮/状态 SQL | 新增页面 | `references/scenario-new-page.md` |
| 新建自动任务、定时任务、PB_AUTO_TASK、Job | 自动任务 | `references/scenario-auto-task.md` |
| 新增系统参数、业务开关、数据库参数、参数读取逻辑 | 系统参数 | `references/scenario-system-param.md` |
| 新增 `.properties`、`.yml`、XML bean/config、FTP/client/bank 配置项 | 配置文件参数 | `references/scenario-config-param.md` |

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
