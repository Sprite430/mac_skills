# 场景：新增页面

## 目录

- 目标
- 必须确认的信息
- 必查项
- 常见变更文件
- 常见 SQL
- 实施清单

## 目标

新增 PB 页面，通常包含 JSP、JS、Controller、Service，以及菜单、模块、按钮、状态等数据库配置。

## 必须确认的信息

需要询问或根据上下文推断：

- 目标版本：2.x 或 3.x。
- 目标模块、银行或地区。
- 页面名/JSP 名和页面中文标题。
- 页面模式：传统 ExtJS 页面或 ExtJS MVC。
- 页面是产品通用功能还是地区个性化功能。
- 页面数据加载方式：直连查询还是单据引擎。
- 父菜单、按钮、状态、查询条件和主要业务动作。

## 必查项

先找与新页面业务最接近的已有页面，复制它的结构和约定，不要凭空设计。

常用搜索：

```bash
rg -n "controllers =|mainView|loadUrl|PB_SYS_BUTTON|GAP_MODULE|GAP_MENU" .
rg -n "spring-views.properties|viewscustom|WEB-INF/views" .
rg -n "load.*\\.do|save.*\\.do|query.*\\.do" .
```

## 常见变更文件

2.x：

- `realware/WEB-INF/views/` 或项目专用 JSP 目录
- `realware/js/` 或 `realware/<region>_js/`
- `src/spring-views.properties`
- Controller Java
- Service 接口/实现 Java
- XML bean 配置
- SQL 脚本

3.x：

- `<module>/src/main/webapp/WEB-INF/views/` 或 `viewscustom/`
- `<module>/src/main/resources/static/<module>_js/`
- `<module>/src/main/java/.../web/`
- `<module>/src/main/java/.../service/`
- SQL 脚本

## 常见 SQL

- `GAP_MODULE`
- `GAP_MENU`
- `PB_SYS_BUTTON`
- `PB_SYS_STATUS`
- `PB_STATUS_CONDITION`

必须提示用户：ID、CODE、父菜单、排序号等需要在目标数据库执行前核对。无法访问数据库时，用明确占位符或基于最大值的假设生成 SQL，并说明风险。

## 实施清单

- `GAP_MODULE.CLASS_NAME` 与 JSP 名保持一致。
- 菜单 URL 跟随系统 `doGo.do` 约定。
- 2.x 新页面必须维护 `src/spring-views.properties`。
- 3.x 个性化覆盖页面优先考虑 `viewscustom/`，但以目标模块现有习惯为准。
- JSP 中的 JS 路径必须与实际静态资源目录一致。
- Controller load 方法和业务接口模仿已有页面。
- Service 注册方式按版本规则执行。
- 新页面的 `loadXXX.do` 数据加载、分页查询、字段返回，单独按 `scenario-page-data-load.md` 处理，不要混进菜单/模块/按钮 SQL。
- 所有代码/配置变更块加 AI 标记。
