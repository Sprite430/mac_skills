---
name: db-connect
description: 扫描项目数据库配置文件，自动连接 omnidb-mcp
author: zhangchengke
triggers:
  - 连接数据库
  - db connect
  - 连库
  - 配置数据库连接
  - setup database
---

# db-connect — 项目数据库自动连接

自动扫描当前项目的数据库配置文件，解析连接信息，通过 omnidb-mcp 的 `connect` 工具建立数据库连接。

## 使用场景

- 进入一个项目后，需要连接该项目数据库进行查询或更新
- 项目已有 `application.yml`、`.env` 等配置，不想手动填连接参数
- 不确定项目用的什么数据库、连的哪台机器

## 前置条件

- omnidb-mcp 已注册为 `database` MCP server（已全局配置好）
- 当前项目目录下有可识别的数据库配置文件

---

## 工作流

### 第 1 步：定位项目根目录

通过以下方式确定项目根目录（按优先级）：

```
1. Git 根目录：git rev-parse --show-toplevel
2. SVN 根目录：svn info --show-item wc-root
3. 当前工作目录
```

### 第 2 步：扫描配置文件

在项目根目录及其子目录中，按优先级扫描以下文件：

| 优先级 | 文件 | 说明 |
|--------|------|------|
| 1 | `db-config.json` | 项目专属的 omnidb-mcp 配置 |
| 2 | `application.yml` / `application-*.yml` | Spring Boot 配置 |
| 3 | `application.properties` | Spring Boot 配置 |
| 4 | `.env` / `.env.local` / `.env.development` | 环境变量文件 |
| 5 | `src/main/resources/application*.yml` | Java 项目标准路径 |
| 6 | `src/main/resources/application*.properties` | Java 项目标准路径 |
| 7 | `config/database.yml` | 常见自定义路径 |

扫描命令示例：
```bash
find . -maxdepth 4 \( -name "db-config.json" -o -name "application*.yml" -o -name "application*.properties" -o -name ".env*" -o -name "database.yml" \) 2>/dev/null | head -20
```

### 第 3 步：解析配置

根据文件类型解析数据库连接信息：

**db-config.json（omnidb-mcp 原生格式）**：
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

**application.yml（Spring Boot 格式）**：
```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/mydb
    username: app
    password: secret
    # 或
    driver-class-name: com.mysql.cj.jdbc.Driver
```
→ 从 `url` 解析 engine/host/port/database，提取 username/password。

**application.properties**：
```properties
spring.datasource.url=jdbc:mysql://10.0.0.1:3306/mydb?useSSL=false
spring.datasource.username=root
spring.datasource.password=secret
```
→ 同上，从 JDBC URL 解析。

**.env 文件**：
```bash
DB_ENGINE=postgresql
DB_HOST=localhost
DB_PORT=5432
DB_DATABASE=myapp
DB_USERNAME=postgres
DB_PASSWORD=secret
# 或
DATABASE_URL=postgresql://user:pass@localhost:5432/mydb
```
→ 识别 `DB_*`、`DATABASE_*`、`MCP_DB_*`、`DATABASE_URL` 变量。

### 第 4 步：识别引擎类型

从以下信息推断数据库引擎：

| 来源 | 匹配规则 | 引擎 |
|------|---------|------|
| JDBC URL | `jdbc:mysql://` | mysql |
| JDBC URL | `jdbc:postgresql://` | postgresql |
| JDBC URL | `jdbc:oracle:` | oracle |
| JDBC URL | `jdbc:sqlserver://` | mssql |
| JDBC URL | `jdbc:sqlite:` | sqlite |
| driver-class-name | `com.mysql.cj.jdbc.Driver` | mysql |
| driver-class-name | `org.postgresql.Driver` | postgresql |
| driver-class-name | `oracle.jdbc.OracleDriver` | oracle |
| DB_ENGINE | `mysql/postgresql/oracle/...` | 直接使用 |

### 第 5 步：处理缺失信息

如果解析后有缺失字段，**不要猜测**，向用户展示：

```
已从 application.yml 解析到以下连接信息：

  engine   : postgresql       ✓
  host     : localhost         ✓
  port     : 5432              ✓
  database : myapp             ✓
  username : app               ✓
  password : ???               ✗ 未找到

密码未在配置文件中找到。请提供以下缺失信息：
  - password: ______

（或提供完整连接串: postgresql://app:PASSWORD@localhost:5432/myapp）
```

### 第 6 步：建立连接

信息完整后，调用 omnidb-mcp 的 `connect` 工具：

```
MCP tool: mcp__database__connect
参数:
  connection_id: "<project-name>-db"
  engine: "postgresql"
  host: "localhost"
  port: 5432
  database: "myapp"
  username: "app"
  password: "<from config>"
```

### 第 7 步：验证连接

连接后调用 `ping` 确认连通，然后调用 `list_tables` 展示可用的表，让用户确认连接正确。

```
✓ 连接成功！数据库版本: PostgreSQL 14.5
  可用表 (前 10 个): users, orders, products, ...
```

---

## 错误处理

| 场景 | 处理方式 |
|------|---------|
| 找不到任何配置文件 | 列出支持的配置方式，提供手动输入或创建 `db-config.json` 的选项 |
| 配置文件存在但无数据库信息 | 说明该文件不包含数据库配置，继续扫描下一优先级 |
| JDBC URL 解析失败 | 显示原始 URL，请求用户手动确认各项参数 |
| 引擎类型无法识别 | 列出常见选项让用户选择 |
| 连接被拒绝 | 检查 host/port 是否正确，提示检查网络/VPN |
| 认证失败 | 提示检查 username/password，询问是否重试 |
| MCP server 未运行 | 提示运行 `claude mcp list` 检查 database server 状态 |

---

## 使用示例

```
用户: 连库
→ 扫描项目配置 → 从 application.yml 解析 → 自动连接 → 显示表列表

用户: db connect
→ 扫描到多个配置文件 → 让用户选择用哪个 → 解析 → 连接

用户: 连接数据库
→ 找不到配置文件 → 列出选项：
  1. 手动输入连接信息
  2. 创建 db-config.json 模板
  3. 设置 .env 环境变量
```

---

## 注意事项

- 密码等敏感信息不会记录到对话历史中
- 每次新会话需要重新运行此 skill 来建立连接
- 如果项目有多个数据源配置，会列出所有让用户选择
- 优先使用 `db-config.json`，因为它是 omnidb-mcp 原生格式，无需转换
