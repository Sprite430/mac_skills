# 通用规则

## 目录

- 必查项
- CodeGraph 与影响面分析
- 版本控制和本地改动保护
- AI 变更标记
- 产品化/参考代码策略
- 常用搜索
- 验证方式

## 必查项

编码前必须确认：

1. 目标项目路径。
2. 项目是否属于 PB/PbServer 产品化或个性化项目；非 PB 工具项目不要套用本 skill。
3. 版本：2.x 或 3.x。
4. 项目类型：产品化主线、产品化参考基线、地区个性化项目。
5. 场景：已有页面加按钮、页面状态/列配置、页面数据加载、问题定位/修复、SQL/数据库、后端接口、新增页面、自动任务、系统参数、配置文件参数、文件/网关安全。
6. 当前项目中可模仿的已有实现。
7. 项目 CLAUDE.md「产品化依赖 ↔ 源码仓库映射」表中的产品化源码，或已知产品化基线中的产品实现。

用户给出明确路径时，以用户路径为准，不凭记忆替换目标项目。

如果目标项目是普通工具项目，例如 `OracleMigrateTool`，停止使用 PB 场景规则，改按普通 Java/工具项目处理。


## CodeGraph 与影响面分析

目标项目接入 CodeGraph（存在 `.codegraph/` 索引）时，按以下规则使用：

1. 探索代码、查符号源码/调用关系/影响范围优先用 `codegraph_explore`，不要先用 grep/Read 铺开；它返回的源码即 Read 等效。
2. 修改函数、类、方法、Controller 接口或共享工具前，先对目标符号执行 `codegraph_explore` 确认影响范围（blast radius），并向用户说明直接调用方、受影响流程和风险。
3. 索引报告 `pendingChanges`/`pendingRefs` 时先向用户报告；获得明确授权后才执行 `codegraph sync`，不要自动全量重建。
4. 调用方超过 10 个时，先警告风险，再继续修改。
5. 项目没有 `.codegraph/` 时不得自动初始化，由用户决定是否执行 `codegraph init`。
6. CodeGraph 只是索引工具，不代表项目一定是 Git；SVN 项目同样适用。

## 版本控制和本地改动保护

编码前必须识别当前项目的版本控制状态，避免覆盖用户或同事已有改动：

1. Git 项目先执行 `git status --short --branch`。
2. SVN 项目先执行 `svn status`；如果需要确认根目录，再执行 `svn info --show-item wc-root` 或 `svn info`。
3. 无版本控制项目也要用定向 `find`/`rg` 判断是否存在备份文件、冲突文件或同名个性化文件。
4. 如果存在 `C` 冲突、大量未解释的 `M` 修改、`.mine`/`.rNNN` 冲突文件，或目标文件已有非本次任务改动，不得直接覆盖；先汇报文件清单和风险，请用户确认处理方式。
5. 只修改本次需求必要文件；禁止顺手格式化、批量重排 import、批量替换无关代码。

## AI 变更标记

对 `.java`、`.js`、`.jsp`、`.yml`、`.properties`、`.xml`、`.sh` 的真实新增/修改代码块，必须使用该文件类型注释语法添加成对 AI 标记。

Java/JavaScript/JSP 脚本示例：

```java
// @AI-Begin A1B2C 20260525 DeepSeek
// 说明该业务分支存在的原因。
doSomething();
// @AI-End A1B2C 20260525 DeepSeek
```

XML/JSP 标签示例：

```xml
<!-- @AI-Begin A1B2C 20260525 DeepSeek -->
<bean id="exampleService" class="grp.pb.branch.ExampleServiceImpl"/>
<!-- @AI-End A1B2C 20260525 DeepSeek -->
```

Properties/YAML/shell 示例：

```properties
# @AI-Begin A1B2C 20260525 DeepSeek
example.enabled=true
# @AI-End A1B2C 20260525 DeepSeek
```

规则：

- 每个变更块生成一个新的 5 位大写字母/数字 ID。
- 开始和结束标记使用同一个 ID。
- 同一文件内 ID 不重复。
- 日期使用北京时间。
- 除非整个文件确实是全新文件或整体替换，否则不要用一组标记包住整个文件。

## 产品化/参考代码策略

- 映射表指向的产品化源码目录只读（旧方式 `source_code_lib/` 如仍存在也同理）。
- 已知产品化基线默认只读，除非用户明确要求修改产品化代码。
- 优先参考产品化行为和命名，再把个性化改动落到地区项目。
- 如果目标项目已经覆盖了产品化文件，先对比目标项目版本和产品化版本，再决定修改位置。

## 常用搜索

优先使用 `rg`。

- 页面/JSP：`rg -n "PageName|JspName|class_name|doGo|scripts.jsp" .`
- 按钮：`rg -n "BUTTON_ID|buttonId|PB_SYS_BUTTON|StatusButton|addButton|toolbar" .`
- 状态/列：`rg -n "PB_MODULE_STATUS_UI|PB_MODULE_UI_DETAIL|PB_SYS_STATUS|PB_STATUS_CONDITION|VIEW_ID|VIEW_ALIAS|CONTROL_NAME|DATAINDEX|IS_VISBLE" .`
- Controller 接口：`rg -n "@RequestMapping|@PostMapping|@GetMapping|ResponseBody|RootController|copySession" .`
- Service：`rg -n "interface .*Service|ServiceImpl|custom-context|<bean id=.*Service" .`
- 自动任务：`rg -n "PB_AUTO_TASK|JOB_NAME|execute\\(|Auto.*Task|Quartz|Job" .`
- 系统参数：`rg -n "PbParameters|PB_PARAMETER|PB_PARAMETER_VALUES|sysParam|SysParam|PB_SYS_PARAM|PARAM_CODE|getParam|getSysParam" .`
- 配置参数：`rg -n "Properties|@Value|Environment|getProperty|application.yml|\\.properties" .`

## 验证方式

选择最小有效验证：

- 条件允许时执行 Java 编译或模块测试。
- 3.x 且模块明确时，可优先考虑 `mvn -pl <module> -am test`。
- 用定向 `rg` 检查接口映射、按钮 ID、配置键、Bean id。
- 没有数据库时，对 SQL 中易冲突的 ID/CODE/JOB_NAME 做人工自查并明确提示用户核对。
- UI 改动至少确认 JSP 是否能加载目标 JS，按钮 ID 与 JS handler 是否一致。
