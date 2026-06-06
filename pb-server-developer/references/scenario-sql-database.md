# 场景：SQL / 数据库兼容

## 目录

- 目标
- 适用范围
- 必查项
- 跨库兼容规则
- SQL 生成规则
- 验证方式

## 目标

新增或调整 SQL 脚本、DDL/DML、菜单/按钮/状态/参数配置、业务查询、表字段或索引，同时尽量兼容 PB 2.x/3.x 常见数据库。

## 适用范围

- `GAP_MODULE`、`GAP_MENU`、`PB_SYS_BUTTON`、`PB_AUTO_TASK`、`PB_SYS_PARAM`、状态/列配置等初始化 SQL。
- Java/DAO 中的查询 SQL、更新 SQL、分页 SQL。
- 新增表、字段、索引或调整字段含义。

## 必查项

1. 先确认目标数据库类型：Oracle、PostgreSQL/GaussDB/openGauss、达梦、DB2、OceanBase、MySQL/TiDB/GoldenDB。
2. 查目标项目现有 SQL 写法和方言配置，例如 `dbStyle`、`driverDelegateClass`、DAO 工具类。
3. 查目标表真实字段名、主键生成方式、是否区分账套/行政区划/银行/年度。
4. 生成配置 SQL 前，必须提示执行前核对 ID、CODE、JOB_NAME、MENU_ID、STATUS_ID、UI_ID 等唯一键。
5. 不要自动执行生产或现场 SQL；除非用户明确授权并确认环境。

## 跨库兼容规则

- 不确定目标库时，不默认使用 Oracle 专用函数，如 `nvl`、`decode`、`rownum`、`sysdate`、`dual`。
- 日期、字符串拼接、空值处理、分页、批量插入、序列/自增是高风险点，优先模仿目标项目同类 SQL。
- PostgreSQL/GaussDB 注意 schema、大小写、`||` 拼接、`limit/offset`、布尔/数字字段差异。
- 达梦/DB2/OceanBase 不要仅凭数据库名称假设完全兼容 Oracle；以项目已有适配写法为准。
- Java 中拼 SQL 必须处理参数绑定和注入风险，优先使用项目已有 DAO/query 参数化方式。

## SQL 生成规则

- 能查库时先生成 `SELECT` 查重语句，再生成 `INSERT`/`UPDATE`。
- 不能查库时，用明确占位符或“执行前查询最大值/唯一值”的方式生成，并标注风险。
- 菜单、按钮、状态、列配置 SQL 应按场景拆分，不要把数据加载查询混入初始化 SQL。
- SQL 文件如果纳入交付，建议用 SQL 注释说明用途、适用版本、执行前核对项；`.sql` 不强制 AI 标记，但建议标明变更来源。

## 验证方式

- 对初始化 SQL：提供查重 SQL、执行 SQL、回查 SQL。
- 对查询 SQL：说明输入参数、预期行数、排序、分页和空结果行为。
- 对 DDL：说明是否需要停机、备份、默认值、历史数据回填、索引影响和回滚方式。
