---
name: oracle-db-helper
description: 通用 Oracle 数据库操作工具，连接任意 Oracle 执行 SQL 查询/更新/结构查看
author: zhangchengke
triggers:
  - oracle
  - Oracle查询
  - 查Oracle
  - 连Oracle
  - Oracle 数据库
  - oracle query
  - oracle connect
---

# oracle-db-helper — 通用 Oracle 数据库操作工具

不绑定 Docker 容器，通过 sqlplus 直接连接任意远程 Oracle 数据库。与 `oracle-db-handler` 互补：

| | oracle-db-handler | oracle-db-helper |
|---|---|---|
| 连接方式 | Docker 容器内 | sqlplus 直连 |
| 目标数据库 | 本地开发测试 | 任意远程 Oracle |
| 适用场景 | 国库系统开发 | 所有 Oracle 项目 |
| 数据修复 | ✓ 自动造数据 | ✗ 纯查询/更新 |

## 前置条件

- Oracle Instant Client 已安装：`/opt/oracle/instantclient_19_16/`
- sqlplus 可用：`/opt/oracle/instantclient_19_16/sqlplus`
- 目标数据库可网络访问

---

## 工作流

### 第 1 步：获取连接信息

按优先级从以下来源获取：

1. **用户直接提供** — 对话中说"连 172.16.101.111:1521:orcl 用户 xxx"
2. **项目配置文件** — 扫描 `application.yml` / `db-config.json` 中的 `datasource` 配置
3. **缓存** — 上次成功连接的 `.last_oracle_conn` 文件

### 第 2 步：建立连接并验证

使用 skill 目录下的 `oracle.sh` 脚本：

```bash
# 测试连接
bash oracle.sh test <host> <port> <service> <user> <pass>
```

成功后展示：

```
✓ 已连接 Oracle 172.16.101.111:1521/orcl
  版本: Oracle Database 11g Enterprise Edition Release 11.1.0.7.0
  用户: GUANGXI_XINGYE_33_LJT_221202
```

### 第 3 步：执行操作

根据用户意图选择对应命令：

| 用户意图 | 命令 | 示例 |
|---------|------|------|
| 执行查询 | `oracle.sh query` | `bash oracle.sh query ... "SELECT * FROM PB_PAY_VOUCHER WHERE ROWNUM <= 10"` |
| 查看表结构 | `oracle.sh desc` | `bash oracle.sh desc ... "PB_PAY_VOUCHER"` |
| 执行更新 | `oracle.sh update` | `bash oracle.sh update ... "UPDATE ... SET ... WHERE ..."` |
| 列出所有表 | `oracle.sh tables` | `bash oracle.sh tables ...` |
| 查看版本 | `oracle.sh version` | `bash oracle.sh version ...` |

所有命令格式：
```
bash /Users/zhangchengke/zzz_skills/oracle-db-helper/oracle.sh <action> <host> <port> <service> <user> <pass> [SQL|表名]
```

### 第 4 步：输出结果

SQL 查询结果以表格形式呈现给用户，列之间用 `|` 分隔。大结果集只展示前 50 行，并告知总行数。

---

## 命令速查

| 操作 | 命令 | 说明 |
|------|------|------|
| `test` | `oracle.sh test H P S U P` | 测试连接是否成功 |
| `query` | `oracle.sh query H P S U P "SQL"` | 执行 SELECT 查询 |
| `update` | `oracle.sh update H P S U P "SQL"` | 执行 INSERT/UPDATE/DELETE，自动 COMMIT |
| `desc` | `oracle.sh desc H P S U P "TABLE"` | 查看表结构（列名/类型/可空） |
| `tables` | `oracle.sh tables H P S U P` | 列出当前用户所有表 |
| `version` | `oracle.sh version H P S U P` | 查看 Oracle 版本 |

---

## 从项目配置自动解析

当用户在项目目录中说"连库"时，自动扫描 `application.yml` 中的 datasource 配置：

**PB 项目格式**：
```yaml
datasource:
  url: jdbc:oracle:thin:@172.16.101.111:1521:orcl
  username: GUANGXI_XINGYE_33_LJT_221202
  password: 1
```

解析步骤：
1. 从 `url` 中提取 `@` 后面的 `<host>:<port>:<service>`
2. 提取 `username` 和 `password`
3. 转换为 oracle.sh 参数格式
4. 自动执行 `test` 验证连接

**多模块项目**（如 GuangXi 下有 xingye/bbw/guilin 等）：
1. 扫描所有模块的 `application.yml`
2. 列出所有找到的配置让用户选择
3. 选定后连接

---

## 错误处理

| 错误 | 原因 | 处理 |
|------|------|------|
| `ORA-12541` | 无法到达主机 | 检查 IP/网络/VPN |
| `ORA-12528` | 实例未就绪 | 等待后重试 |
| `ORA-01017` | 用户名密码错误 | 提示用户重新输入 |
| `ORA-00942` | 表或视图不存在 | 检查表名，建议用 `tables` 查看可用表 |
| `ORA-00911` | SQL 语法错误 | 检查特殊字符需转义（如 `$` 需写成 `\$`） |
| `ORA-01722` | 类型转换错误 | 检查字段类型匹配 |
| `sqlplus: command not found` | Instant Client 环境问题 | 检查 `/opt/oracle/instantclient_19_16/` |
| `DYLD_LIBRARY_PATH` 未设置 | macOS 库路径 | oracle.sh 自动设置，无需手动处理 |
| 连接超时 | 网络/防火墙 | 建议用户检查连通性：`nc -zv <host> <port>` |

---

## 使用示例

### 示例 1：从项目配置自动连接

```
用户: 连Oracle
→ 扫描到 application.yml
→ 解析出 172.16.101.111:1521:orcl
→ oracle.sh test → 成功
→ 展示版本和表列表
```

### 示例 2：手动指定连接

```
用户: 连 10.0.0.50:1521:paydb，用户 admin，密码 secret
→ oracle.sh test 10.0.0.50 1521 paydb admin secret
→ 成功 → 可开始查询
```

### 示例 3：执行查询

```
用户: 查一下 PB_PAY_VOUCHER 表前 10 条
→ oracle.sh query ... "SELECT * FROM PB_PAY_VOUCHER WHERE ROWNUM <= 10"
→ 以表格展示结果
```

### 示例 4：查看表结构

```
用户: desc PB_PAY_VOUCHER
→ oracle.sh desc ... "PB_PAY_VOUCHER"
→ 展示列名、类型、可空性
```

### 示例 5：多模块项目选择

```
用户: 连库
→ 发现 9 个模块的数据库配置：
  1. xingye  → oracle 172.16.101.111:1521:orcl
  2. bbw     → oracle 172.16.101.111:1521:orcl
  3. guilin  → oracle 172.16.101.111:1521:orcl
  ...
  9. rcb     → oracle 172.16.101.111:1521:orcl
→ 用户选 1 → 用 xingye 的用户连接
```

---

## Security 注意事项

- SQL 中如有 `\$` 字符（Oracle 保留字），需转义
- UPDATE/DELETE 操作会自动 COMMIT，执行前向用户确认
- 密码不会记录到对话历史中
- 连接信息只缓存在本次会话
- 不支持 DDL 操作（CREATE/ALTER/DROP/TRUNCATE），如需执行请用户手动操作

## 与 db-connect 技能的关系

`db-connect` 是统一入口，负责扫描配置并路由：
```
db-connect → 识别为 Oracle → 调 oracle-db-helper（本 skill）
          → 识别为 MySQL  → 调 mcp-database-server
          → 识别为 PG     → 调 mcp-database-server
```
