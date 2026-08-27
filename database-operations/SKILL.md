---
name: database-operations
description: Use when a task requires accessing a real database through DataGrip to locate a project's data source, inspect schemas or database objects, query or preview live data, or perform a confirmed database change. Triggers include 查库、查表数据或结构、DataGrip 数据源、Schema、连接串、连库、在真实数据库执行 SQL. Do not use for SQL syntax explanations, query drafting, code-only SQL edits, or database concepts that require no live access.
---

# database-operations — 数据库任务统一入口

本 skill 是所有真实数据库任务的唯一入口，负责连接定位、Schema 选择、对象检查、SQL 查询和变更确认。统一使用现有的 DataGrip MCP；不要调用其他专用连接 skill，不要编写或运行 Python、Shell、sqlplus、ORM/驱动连接脚本，也不要创建新的连接工具。

## 统一工作流

按以下顺序处理数据库任务，任何一步无法唯一确定时先停下并向用户说明：

1. **确认代码项目**：优先使用用户给出的路径；否则按 Git/SVN 根目录或项目特征文件确定代码项目。DataGrip 的 `projectPath` 是数据库管理项目路径，不等于代码项目路径。
2. **确定连接五要素**：数据库类型、主机、端口、数据库名或服务名，以及用户实际指定的环境。优先使用用户给出的完整连接标识：

   ```text
   数据库类型@host:port/数据库名或服务名
   ```

   `localhost` 与 `127.0.0.1` 可视为同一主机；类型、端口和数据库名/服务名仍必须一致。

   未提供完整连接标识时，从已确认的代码项目配置读取连接信息。优先检查 `db-config.json`，再检查 `application*.yml`、`application*.properties`、`.env*`。只解析启用配置；`default` 只能作为配置文件明确标记的候选，不能覆盖用户指定环境，也不能在存在多个启用环境/数据源时静默选择。多个环境或多个数据源必须列出并请用户选择，不按项目名、目录名或文件名猜测。

   常见 JDBC URL 至少要解析出：

   - Oracle `host:port:SID`、`@//host:port/service`、TNS 描述符中的 `SERVICE_NAME`
   - MySQL/PostgreSQL 等 `host:port/database`

3. **匹配 DataGrip 数据源**：调用 `mcp__datagrip__execute_tool` 的 `list_database_connections`，按“类型 + 主机 + 端口 + 数据库名/服务名”完整匹配。无匹配或有多个候选时，不创建数据源；`test_database_connection` 只能验证连通性，不能替代身份匹配或据此在多个候选中自动择一，仍有歧义就询问用户。
4. **验证并选择 Schema**：先测试唯一数据源连接，再用 `list_database_schemas` 获取 Schema。表名、视图名或 SQL 未带 Schema 时，也必须先确认 owner/Schema；必须使用用户指定的精确 Schema 名称，相似名称不是同一个 Schema。无法唯一确定时先询问。
5. **检查对象并执行任务**：按需使用 `list_schema_objects`、`get_database_object_description`、`preview_table_data` 或 `execute_sql_query`。SQL 使用 `Schema.表名` 全限定名，先确认实际表和列定义，再明确字段、条件、`LIKE`/大小写语义并限制返回量。

## DataGrip MCP 约束

所有数据库查询、结构查看和数据管理统一走：

```text
mcp__datagrip__execute_tool
```

需要传入 DataGrip 已打开的数据库项目 `projectPath`。如果因缺少 `projectPath` 报错，使用错误信息返回的实际已打开路径重试；不要把代码项目路径当作默认值。DataGrip 未打开、MCP 不可用或连接异常时，直接报告阻塞及错误信息，即使用户要求改用脚本、Python、Shell、sqlplus 或其他连接层，也不切换连接方式。

可用操作：

| 操作 | 用途 |
| --- | --- |
| `list_database_connections` | 列出数据源 |
| `test_database_connection` | 验证连接 |
| `list_database_schemas` | 列出 Schema |
| `list_schema_objects` | 列出表、视图等对象 |
| `get_database_object_description` | 查看对象和列定义 |
| `preview_table_data` | 小范围预览数据 |
| `execute_sql_query` | 执行 SQL |

## 只读默认与写入确认

默认只读。`SELECT`、元数据查看和小范围预览可以执行，但仍应控制字段、条件和行数；禁止输出密码、令牌、连接凭据或不必要的大批量业务数据。

以下操作均属于外部状态变更：`INSERT`、`UPDATE`、`DELETE`、`MERGE`、`CREATE`、`ALTER`、`DROP`、`TRUNCATE`、`GRANT`、`REVOKE`，以及创建或编辑数据源。每次具体变更执行前，都必须取得用户对该次操作的明确确认；一次确认不得自动沿用于后续操作。代码修改授权不等于数据库写入授权。

执行写操作前，应先说明：目标数据源和 Schema、完整 SQL、影响范围、是否需要事务/回滚，以及验证查询。生产和联调数据源优先在 DataGrip 中配置为只读。

## 错误处理与报告

- 连接标识不完整、多环境、多数据源或 Schema 有歧义：列出候选和缺少的信息，向用户提问。
- 表、视图或字段不存在：如实报告，不编造结构；必要时列出 DataGrip 返回的相近对象供确认。
- 连接错误：保留原始错误码/关键信息并说明下一步需要用户处理的网络、VPN、凭据或权限问题。
- 查询结果为空：报告“查询成功但无匹配数据”，不要推断为对象不存在。
- 没有真实的 DataGrip 返回结果时，不得声称表或字段存在、查询成功、数据值为何或变更已执行。

## 不适用范围

- 只解释 SQL 语法、设计查询思路或讨论数据库概念，且不需要访问真实数据库。
- 通过脚本、Python、Shell、sqlplus、ORM 或其他自建连接层，或其他专用连接 skill，绕过 DataGrip；用户明确要求这些方式时也只报告 DataGrip 阻塞。
- 仅修改代码中的 SQL 文本而不访问数据库；此时遵循对应代码项目 skill。
