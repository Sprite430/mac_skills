# 场景：已有 MVC 页面状态/列配置

## 目录

- 目标
- 适用范围
- 必查项
- 典型 SQL
- 实施清单
- 常见误区

## 目标

在已有 MVC 页面上新增状态展示、列字段、显示字段，或调整页面状态对应的列表字段配置。

## 适用范围

只适用于使用数据库配置状态/列表显示的 MVC 页面。

如果页面是纯初始化页面、纯 JS 渲染页面，或者本地并没有 `PB_MODULE_STATUS_UI` / `PB_MODULE_UI_DETAIL` / `PB_SYS_STATUS` 这类配置链路，就不要硬套本场景，改走 JSP/JS 代码修改。

## 必查项

1. 找到页面对应的 `JSP_NAME`、`VIEW_ID`、`CONTROL_NAME`、`VIEW_ALIAS`。
2. 确认页面是 MVC 列表页，且数据库确实控制状态和列显示。
3. 找到已有状态定义和对应条件。
4. 找到已有列配置，确认哪些字段是新增、哪些字段是显示顺序或显隐调整。
5. 找到同模块中最接近的状态页 SQL，优先复用它的写法。

常用搜索：

```bash
rg -n "PB_MODULE_STATUS_UI|PB_MODULE_UI_DETAIL|PB_SYS_STATUS|PB_STATUS_CONDITION|VIEW_ALIAS|CONTROL_NAME|DATAINDEX|IS_VISBLE" .
rg -n "JSP_NAME|VIEW_ID|STATUS_ID|STATUS_CODE|STATUS_ORDER|STATUS_NAME" .
```

## 典型 SQL

### 1. 新增状态

- `PB_SYS_STATUS`
- `PB_STATUS_CONDITION`

用于定义状态编码、状态名称和进入条件。

### 2. 把状态挂到页面

- `PB_MODULE_STATUS_UI`

用于把状态绑定到某个 `VIEW_ID` 和 `VIEW_ALIAS`。

### 3. 配置状态下的页面列

- `PB_MODULE_UI_DETAIL`

用于配置列表字段、字段名、显示顺序、宽度、显隐、字段绑定名 `DATAINDEX`。

如果你要我“直接生成一份可执行 SQL”，优先看同目录的 [sql-status-column-template.md](sql-status-column-template.md)。

## 实施清单

- 新增状态时，先确认状态码是否与已有状态冲突。
- 新增列字段时，先确认 `UI_ID`、`DATAINDEX`、`UI_ORDER`、`VIEW_ID` 是否与目标页一致。
- 如果新增的是显示字段，不要误写成按钮场景。
- 如果是只改列显示顺序或显隐，通常只改 `PB_MODULE_UI_DETAIL`。
- 如果是新增状态且要显示不同列，通常要同时改 `PB_SYS_STATUS`、`PB_STATUS_CONDITION`、`PB_MODULE_STATUS_UI`、`PB_MODULE_UI_DETAIL`。
- 若页面代码仍需联动显示文本或格式化，才补充 JS/JSP 改动。

## 常见误区

- 把列配置误归到“新增页面”。
- 把状态展示误归到“新增按钮”。
- 只改 `PB_SYS_STATUS`，忘了补 `PB_MODULE_STATUS_UI` 和列配置。
- 只改 `PB_MODULE_UI_DETAIL`，忘了状态条件。
- 把本应由 SQL 控制的页面改成代码硬编码。
