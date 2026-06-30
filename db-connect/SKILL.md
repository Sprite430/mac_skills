---
name: db-connect
description: 扫描项目数据库配置，智能路由 Oracle→oracle-db-helper / MySQL/PG→mcp-database-server
author: zhangchengke
triggers:
  - 连接数据库
  - db connect
  - 连库
  - 配置数据库连接
  - setup database
---

# db-connect — 项目数据库自动连接（双引擎）

自动扫描当前项目的数据库配置文件，解析连接信息，按引擎类型智能路由：

```
扫描配置 → 识别引擎 ──→ Oracle  → oracle-db-handler（run_query.sh）
                    ──→ MySQL   → mcp-database-server MCP
                    ──→ PG      → mcp-database-server MCP
```

## 前置条件

| 引擎 | 依赖 | 状态 |
|------|------|------|
| Oracle | `oracle-db-handler` 技能 + Docker `oracle-21c-local` | 已就绪 |
| MySQL | `mcp-database-server` MCP（全局 `database`） | 已就绪 |
| PostgreSQL | `mcp-database-server` MCP（全局 `database`） | 已就绪 |

---

## 工作流

### 第 1 步：定位项目根目录

```
1. Git 根目录：git rev-parse --show-toplevel
2. SVN 根目录：svn info --show-item wc-root  
3. 当前工作目录
```

### 第 2 步：扫描配置文件

在项目根目录及其子目录中，按优先级扫描：

| 优先级 | 文件 | 说明 |
|--------|------|------|
| 1 | `db-config.json` | 项目专属数据库配置 |
| 2 | `application.yml` / `application-*.yml` | Spring Boot / PB 项目 |
| 3 | `application.properties` | Spring Boot |
| 4 | `.env` / `.env.local` | 环境变量 |
| 5 | `src/main/resources/application*.yml` | Java 项目标准路径 |
| 6 | `src/main/resources/application*.properties` | Java 项目标准路径 |
| 7 | `config/database.yml` | 自定义路径 |

扫描命令：
```bash
find . -maxdepth 4 \( -name "db-config.json" -o -name "application*.yml" -o -name "application*.properties" -o -name ".env*" \) 2>/dev/null | grep -v target | head -20
```

### 第 3 步：解析配置

**application.yml — PB 项目格式（datasource 在顶层）**：
```yaml
datasource:
  url: jdbc:oracle:thin:@172.16.101.111:1521:orcl
  username: GUANGXI_XINGYE_33_LJT_221202
  password: 1
  driver: oracle.jdbc.driver.OracleDriver
```
→ 从 `datasource.url` / `datasource.username` / `datasource.password` / `datasource.driver` 提取。

**application.yml — 标准 Spring Boot 格式**：
```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/mydb
    username: app
    password: secret
```
→ 从 `spring.datasource.url` 等提取。

**db-config.json**：
```json
{
  "connections": [{
    "id": "main",
    "engine": "postgresql",
    "host": "localhost",
    "port": 5432,
    "database": "myapp",
    "username": "postgres",
    "password": "secret"
  }]
}
```
→ 直接提取，无需转换。

### 第 4 步：识别引擎类型

| 来源 | 匹配规则 | 引擎 |
|------|---------|------|
| JDBC URL | `jdbc:oracle:thin:@` | **oracle** |
| JDBC URL | `jdbc:oracle:oci:@` | **oracle** |
| JDBC URL | `jdbc:mysql://` | mysql |
| JDBC URL | `jdbc:postgresql://` | postgresql |
| JDBC URL | `jdbc:dm://` | 达梦（暂不支持，提示用户） |
| JDBC URL | `jdbc:db2://` | DB2（暂不支持，提示用户） |
| driver | `oracle.jdbc.driver.OracleDriver` | **oracle** |
| driver | `oracle.jdbc.OracleDriver` | **oracle** |
| driver | `com.mysql.cj.jdbc.Driver` | mysql |
| driver | `org.postgresql.Driver` | postgresql |
| DB_ENGINE 环境变量 | `oracle/mysql/postgresql` | 直接使用 |

### 第 5 步：引擎路由（核心）

根据识别的引擎类型，走不同的连接路径：

---

#### 🔴 Oracle 路径 → oracle-db-handler

**适用场景**：国库集中支付系统、PB 项目、ProxyBank 项目。

**操作流程**：

1. 检查 oracle-db-handler 技能环境：
   ```bash
   ls /Users/zhangchengke/zzz_skills/oracle-db-handler/run_query.sh
   ```

2. 如果项目根目录存在 `db-config.json` 且有 Oracle 连接 → 直接提取连接信息。
   如果是从 `application.yml` 解析的 → 向用户展示解析结果并确认：

   ```
   📋 从 application.yml 解析到 Oracle 连接：
   
     host     : 172.16.101.111
     port     : 1521
     database : orcl
     username : GUANGXI_XINGYE_33_LJT_221202
     password : 1
   
   使用 oracle-db-handler 连接。是否继续？
   ```

3. 调起 oracle-db-handler 技能，告知用户：
   ```
   已切换到 oracle-db-handler。
   你可以直接执行 SQL 查询，例如：
   - "查一下 PB_PAY_VOUCHER 表有多少条"
   - "desc PB_PAY_VOUCHER"
   - "select * from PB_PAY_VOUCHER where rownum <= 10"
   ```

**注意**：oracle-db-handler 依赖 Docker 容器 `oracle-21c-local`。如果容器未运行，提示用户启动。

---

#### 🟢 MySQL / PostgreSQL 路径 → mcp-database-server

**操作流程**：

1. 组装连接参数，调用 MCP 工具 `connect_database`：
   ```
   MCP tool: mcp__database__connect_database
   参数:
     type: "mysql" 或 "postgresql"
     name: "<project-name>-db"
     host: "<parsed>"
     port: <parsed>
     database: "<parsed>"
     user: "<parsed>"
     password: "<parsed>"
   ```

2. 验证连接：调用 `test_connection`
3. 展示可用的表：调用 `list_connections`

**连接信息展示**：
```
✓ 已连接 MySQL 10.0.0.1:3306/mydb
  可用工具: execute_query, list_connections, test_connection, close_connection
```

---

### 第 6 步：处理缺失信息

如果解析后有缺失字段，向用户展示：

```
已从 application.yml 解析到以下连接信息：

  engine   : oracle          ✓
  host     : 172.16.101.111  ✓
  port     : 1521             ✓
  database : orcl             ✓
  username : GUANGXI_XINGYE  ✓
  password : ???              ✗ 未找到

密码未在配置文件中。请提供密码。
```

### 第 7 步：多模块项目

如果项目有多个模块（如 GuangXi 下有 xingye/bbw/guilin 等），：

1. 扫描所有模块的 `application.yml`
2. 列出所有找到的数据库配置让用户选择：

```
发现 3 个模块的数据库配置：

  1. xingye  → oracle 172.16.101.111:1521:orcl
  2. bbw     → oracle 172.16.101.111:1521:orcl  
  3. guilin  → oracle 172.16.101.111:1521:orcl

要连接哪个？
```

---

## 错误处理

| 场景 | 处理方式 |
|------|---------|
| 找不到配置文件 | 列出支持的配置方式，提供手动输入或创建 `db-config.json` 模板 |
| 引擎是达梦/DB2 | 告知暂不支持，建议手动连接 |
| Oracle 路径：Docker 未运行 | 提示 `docker start oracle-21c-local` |
| Oracle 路径：run_query.sh 无权限 | `chmod +x run_query.sh` |
| MySQL/PG：连接被拒 | 检查 host/port/VPN |
| MySQL/PG：认证失败 | 提示检查 username/password |
| MySQL/PG：MCP 未运行 | `claude mcp list` 检查 database server |

---

## 使用示例

```
用户: 连库
→ 扫描到 application.yml → 识别为 Oracle → 切到 oracle-db-handler → 可查询

用户: db connect
→ 扫描到 .env → 识别为 MySQL → 调用 connect_database → 展示表列表

用户: 连接数据库  
→ 多模块项目 → 列出 xingye/bbw/guilin → 用户选 xingye → 连接
```

---

## 注意事项

- 密码等敏感信息不记录到对话历史
- 每次新会话需重新运行此 skill
- 多模块项目会让用户选择具体模块
- Oracle 走 oracle-db-handler（Docker 内连接，不走 MCP）
- MySQL/PG 走 mcp-database-server MCP 协议
