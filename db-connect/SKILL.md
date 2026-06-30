---
name: db-connect
description: 扫描当前项目的数据库配置文件，解析连接信息，识别引擎类型并路由到对应 MCP 工具的统一连库入口。Use when the user wants to connect to a project's database without manually providing parameters, e.g. "连库"、"连接数据库"、"db connect"、"帮我连上这个项目的数据库". Scans db-config.json / application.yml / application.properties / .env, then routes Oracle/OceanBase to oracle MCP and MySQL/PostgreSQL/GaussDB to database MCP. Do not use when connection parameters are already known and the engine is Oracle (call oracle-db-helper or oracle MCP directly); 达梦/DB2 are unsupported.
author: zhangchengke
---

# db-connect — 项目数据库自动连接

自动扫描当前项目的数据库配置文件，解析连接信息，按引擎类型路由到对应 MCP 工具：

```
扫描配置 → 识别引擎 ──→ Oracle/OceanBase   → oracle MCP（mcp__oracle__*）
                    ──→ MySQL/TiDB/GoldenDB → database MCP（mcp__database__*）
                    ──→ PostgreSQL/GaussDB  → database MCP（mcp__database__*）
                    ──→ 达梦/DB2            → 暂不支持，提示手动连接
```

## 前置条件

| 引擎 | MCP Server | 工具前缀 |
|------|-----------|---------|
| Oracle 11g+ | oracle（全局） | `mcp__oracle__` |
| OceanBase | oracle（Oracle 兼容协议） | `mcp__oracle__` |
| MySQL/TiDB/GoldenDB | database（全局） | `mcp__database__` |
| PostgreSQL | database（全局） | `mcp__database__` |
| GaussDB | database（PG 兼容协议） | `mcp__database__` |
| 达梦 DM | 暂不支持 | — |
| DB2 | 暂不支持 | — |

---

## 工作流

### 第 1 步：定位项目根目录

```
1. Git 根目录：git rev-parse --show-toplevel
2. SVN 根目录：svn info --show-item wc-root  
3. 当前工作目录
```

### 第 2 步：扫描配置文件

按优先级扫描：

| 优先级 | 文件 | 说明 |
|--------|------|------|
| 1 | `db-config.json` | 项目专属数据库配置（有 default 字段则直连） |
| 2 | `application.yml` / `application-*.yml` | Spring Boot / PB 项目 |
| 3 | `application.properties` | Spring Boot |
| 4 | `.env` / `.env.local` | 环境变量 |
| 5 | `src/main/resources/application*.yml` | Java 标准路径 |
| 6 | `src/main/resources/application*.properties` | Java 标准路径 |

扫描命令：
```bash
find . -maxdepth 5 \( -name "db-config.json" -o -name "application*.yml" -o -name "application*.properties" -o -name ".env*" \) 2>/dev/null | grep -v target | grep -v node_modules | head -20
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

**application.yml — PbServerApplication 多数据库注释格式**：
- 注释行（`#` 开头）标为"未激活"，也展示给用户可选
- 未注释的行为当前激活配置

**db-config.json**：
```json
{
  "connections": [{"id": "main", "engine": "oracle", "host": "...", "port": 1521, "database": "orcl", "username": "...", "password": "..."}],
  "default": "main"
}
```
有 `default` 字段时直连不询问。

### 第 4 步：识别引擎类型

| 来源 | 匹配规则 | 引擎 | MCP 路由 |
|------|---------|------|---------|
| JDBC URL | `jdbc:oracle:thin:@` | oracle | mcp__oracle__ |
| JDBC URL | `jdbc:oracle:oci:@` | oracle | mcp__oracle__ |
| JDBC URL | `jdbc:oceanbase://` | oceanbase | mcp__oracle__（兼容） |
| JDBC URL | `jdbc:mysql://` | mysql | mcp__database__ |
| JDBC URL | `jdbc:postgresql://` | postgresql | mcp__database__ |
| JDBC URL | `jdbc:gaussdb://` | gaussdb | mcp__database__（PG 兼容）|
| JDBC URL | `jdbc:dm://` | 达梦 | 暂不支持 |
| JDBC URL | `jdbc:db2://` | DB2 | 暂不支持 |
| driver | `oracle.jdbc.driver.OracleDriver` | oracle | mcp__oracle__ |
| driver | `com.mysql.cj.jdbc.Driver` | mysql | mcp__database__ |
| driver | `org.postgresql.Driver` | postgresql | mcp__database__ |
| driver | `com.huawei.gauss200.jdbc.Driver` | gaussdb | mcp__database__ |
| db-config.json `engine` 字段 | 直接使用 | — | 按上表 |

### 第 5 步：路由连接（核心）

---

#### Oracle / OceanBase → oracle MCP

1. 提取连接信息（host、port、service、username、password）
2. 多连接时列出让用户选择（标明激活/注释）
3. 调用 `mcp__oracle__connect_database`：
   ```
   host: <parsed>
   port: <parsed>
   service: <parsed>        ← JDBC URL @后面的 host:port:service 中的 service 部分
   user: <parsed>
   password: <parsed>
   name: "<project>-<module>"
   verify: true             ← 注册时立即测试连通性
   ```
4. 成功后展示：
   ```
   ✓ 已连接 Oracle 172.16.101.111:1521/orcl
     用户: GUANGXI_XINGYE_33_LJT_221202
   
   可用工具: execute_query / execute_update / describe_table / list_tables / get_db_version
   ```

---

#### MySQL/PG/GaussDB → database MCP

1. 提取连接信息（host、port、database、username、password）
2. 调用 `mcp__database__connect_database`：
   ```
   type: "mysql" 或 "postgresql"
   name: "<project>-db"
   host: <parsed>
   port: <parsed>
   database: <parsed>
   user: <parsed>
   password: <parsed>
   ```
3. 调用 `mcp__database__test_connection` 验证
4. 展示连接信息

GaussDB 注意：type 用 `"postgresql"`，JDBC URL 中的 `currentSchema` 值需要在连接后手动执行 `SET search_path = <schema>` 设置。

---

### 第 6 步：处理缺失信息

```
已从 application.yml 解析到以下连接信息：

  engine   : oracle          ✓
  host     : 172.16.101.111  ✓
  port     : 1521            ✓
  database : orcl            ✓
  username : GUANGXI_XINGYE ✓
  password : ???             ✗ 未找到

密码未在配置文件中，请提供密码。
```

### 第 7 步：多模块/多连接项目

产品化项目（PbServerApplication）application.yml 含多数据库注释块，多模块项目（GuangXi）每个模块各自连库：

```
发现 5 个数据库连接：

  [激活] 1. GaussDB   → 172.16.101.75:5432/pbank_db (pbank_test)
  [注释] 2. Oracle    → 172.16.101.187:1540:orcl19c (pb250506)
  [注释] 3. MySQL     → 172.16.22.151:4000/pb250702 (root)
  [注释] 4. PostgreSQL → 172.16.22.151:5432/pb250704 (postgres)
  [注释] 5. 达梦      → 192.168.1.218:5236 (暂不支持)

要连接哪个？
```

---

## 错误处理

| 场景 | 处理方式 |
|------|---------|
| 找不到配置文件 | 提供手动输入模板，或创建 db-config.json |
| 引擎是达梦/DB2 | 告知暂不支持 |
| oracle MCP 连接失败 ORA-12541 | 检查 IP/网络/VPN |
| oracle MCP 连接失败 ORA-01017 | 检查 username/password |
| database MCP 连接被拒 | 检查 host/port/VPN |
| database MCP 认证失败 | 检查 username/password |
| oracle MCP 未启动 | `claude mcp list` 检查 oracle server |
| database MCP 未启动 | `claude mcp list` 检查 database server |

---

## 使用示例

```
用户: 连库
→ 扫描 application.yml → 激活 GaussDB → mcp__database__connect_database → 可查询

用户: 连库
→ db-config.json 有 default=guangxi-xingye → 直接 mcp__oracle__connect_database → 可查询

用户: 连接数据库
→ 多模块 → 列出 xingye/guilin → 用户选 xingye → mcp__oracle__connect_database

用户: 连Oracle
→ 触发 oracle-db-helper skill（直连备用，无需 MCP）
```

---

## 注意事项

- 密码不记录到对话历史
- 连接注册是会话级，新会话需重新连接
- db-config.json 中有 `default` 字段则跳过选择直连
- Oracle 走 oracle MCP（mcp__oracle__*），全程不再调 Bash 脚本
- oracle-db-helper skill 保留作备用直连手段
