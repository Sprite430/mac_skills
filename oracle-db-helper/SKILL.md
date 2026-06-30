---
name: oracle-db-helper
description: 通过 sqlplus 直连任意 Oracle 数据库执行 SQL 的纯执行层工具，支持查询/更新/查看表结构/列表。Use when the user wants to run SQL against an Oracle (or OceanBase) database and connection parameters (host/port/service/user/password) are known or can be parsed, e.g. "查Oracle"、"连 172.16.x.x 执行 SQL"、"desc 某张表"、"看看这个 Oracle 表的数据". This is the Bash-direct backup path; the oracle MCP (mcp__oracle__*) is the preferred route when available. Do not use for MySQL/PostgreSQL/GaussDB (use database MCP) or for 达梦/DB2 (unsupported).
---

# oracle-db-helper — Oracle 直连执行工具

通过 sqlplus 直接连接任意远程 Oracle / OceanBase 数据库执行 SQL。这是**纯执行层**：给定连接参数即执行，不负责扫描项目配置（扫描/路由由 `db-connect` 负责，见末尾）。

底层脚本 `oracle.sh` 也被 oracle MCP（`mcp__oracle__*`）复用。当 oracle MCP 可用时优先走 MCP；本 skill 作为 Bash 直连备用手段。

## 前置条件

- Oracle Instant Client 已安装：`/opt/oracle/instantclient_19_16/`
- sqlplus 可用：`/opt/oracle/instantclient_19_16/sqlplus`（19.16，x86_64 经 Rosetta 运行）
- 目标数据库可网络访问

---

## 工作流

### 第 1 步：获取连接信息

按优先级：

1. **用户直接提供** — 对话中说"连 172.16.101.111:1521:orcl 用户 xxx 密码 xxx"
2. **由 db-connect 传入** — db-connect 扫描项目配置后解析出的连接参数

本 skill 不维护连接缓存。每次执行都需要完整的 host/port/service/user/password。

### 第 2 步：测试连接

```bash
bash /Users/zhangchengke/zzz_skills/oracle-db-helper/oracle.sh test <host> <port> <service> <user> <pass>
```

成功后展示：
```
✓ 已连接 Oracle 172.16.101.111:1521/orcl
  用户: GUANGXI_XINGYE_33_LJT_221202
```

### 第 3 步：执行操作

| 用户意图 | action | 示例 |
|---------|--------|------|
| 执行查询 | `query` | `bash oracle.sh query H P S U P "SELECT * FROM PB_PAY_VOUCHER WHERE ROWNUM <= 10"` |
| 查看表结构 | `desc` | `bash oracle.sh desc H P S U P "PB_PAY_VOUCHER"` |
| 执行更新/DDL | `update` | `bash oracle.sh update H P S U P "UPDATE ... SET ... WHERE ..."` |
| 列出所有表 | `tables` | `bash oracle.sh tables H P S U P` |
| 查看版本 | `version` | `bash oracle.sh version H P S U P` |
| 测试连接 | `test` | `bash oracle.sh test H P S U P` |

统一格式：
```
bash /Users/zhangchengke/zzz_skills/oracle-db-helper/oracle.sh <action> <host> <port> <service> <user> <pass> [SQL|表名]
```

### 第 4 步：输出结果

查询结果以表格呈现，列之间用 ` | ` 分隔。大结果集脚本默认 PAGESIZE 50000，过大时建议加 `WHERE ROWNUM <= N` 限制。

---

## 命令速查

| action | 命令 | 说明 |
|--------|------|------|
| `test` | `oracle.sh test H P S U P` | 测试连接 |
| `query` | `oracle.sh query H P S U P "SQL"` | 执行 SELECT |
| `update` | `oracle.sh update H P S U P "SQL"` | 执行 INSERT/UPDATE/DELETE/DDL，自动 COMMIT |
| `desc` | `oracle.sh desc H P S U P "TABLE"` | 查看表结构 |
| `tables` | `oracle.sh tables H P S U P` | 列出当前用户所有表 |
| `version` | `oracle.sh version H P S U P` | 查看 Oracle 版本 |

（H=host P=port S=service U=user P=password）

---

## JDBC URL 解析（service 提取）

当连接信息来自 JDBC URL 时，注意 Oracle 有多种 URL 格式，提取 host/port/service 的规则不同：

| URL 格式 | 示例 | service 提取 |
|---------|------|-------------|
| SID 冒号格式 | `jdbc:oracle:thin:@host:1521:orcl` | `@` 后第 3 段 `orcl` |
| Service 斜杠格式 | `jdbc:oracle:thin:@//host:1521/orclpdb` | `/` 后的 `orclpdb` |
| TNS 描述符 | `jdbc:oracle:thin:@(DESCRIPTION=...(SERVICE_NAME=xxx)...)` | 取 `SERVICE_NAME` 的值 |

oracle.sh 的连接串统一拼成 `user/pass@//host:port/service`（sqlplus easy connect 格式），SID 和 service name 在 easy connect 下大多通用。如遇 `ORA-12514`（service 不存在），尝试把 service 当 SID 用，或换用对方实际的 service_name。

---

## 错误处理

| 错误 | 原因 | 处理 |
|------|------|------|
| `ORA-12541` | 无法到达主机 | 检查 IP/网络/VPN |
| `ORA-12514` | service 名不存在 | 确认 service_name，或 SID/service 互换尝试 |
| `ORA-12528` | 实例未就绪 | 等待后重试 |
| `ORA-01017` | 用户名密码错误 | 提示用户重新输入 |
| `ORA-00942` | 表或视图不存在 | 用 `tables` 查看可用表 |
| `ORA-00911` | SQL 含非法字符 | 检查特殊字符，`$` 在 shell 中需写成 `\$` |
| `ORA-01722` | 类型转换错误 | 检查字段类型匹配 |
| `sqlplus not found` | Instant Client 环境问题 | 检查 `/opt/oracle/instantclient_19_16/` |
| 连接超时 | 网络/防火墙 | `nc -zv <host> <port>` 检查连通性 |

---

## 使用示例

```
用户: 连 10.0.0.50:1521:paydb，用户 admin，密码 secret
→ oracle.sh test 10.0.0.50 1521 paydb admin secret → 成功 → 可查询

用户: 查一下 PB_PAY_VOUCHER 表前 10 条
→ oracle.sh query ... "SELECT * FROM PB_PAY_VOUCHER WHERE ROWNUM <= 10"

用户: desc PB_PAY_VOUCHER
→ oracle.sh desc ... "PB_PAY_VOUCHER"
```

---

## 安全注意事项

- SQL 中 `$` 字符在 shell 里需转义为 `\$`
- `update` 会自动 COMMIT 且不可回滚，执行 UPDATE/DELETE/DDL 前向用户确认
- 密码不记录到对话历史
- 连接信息仅本次会话使用，不落盘缓存

## 与 db-connect 的分工

- `db-connect`：唯一的"扫描项目配置 → 解析 → 识别引擎 → 多模块选择 → 路由"入口
- `oracle-db-helper`（本 skill）：纯执行层，拿到连接参数后执行 SQL，不做配置扫描

```
db-connect → 识别为 Oracle → oracle MCP（首选）或 oracle-db-helper（备用）
          → 识别为 MySQL/PG/GaussDB → database MCP
```
