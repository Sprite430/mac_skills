# 场景：已有页面新增按钮

## 目录

- 目标
- 判断：初始化 JS 还是个性化 JS
- 必查项
- REF_JS 检查
- 实施清单
- 常见问题

## 目标

在已有 PB JSP/ExtJS 页面中新增按钮或动作，同时尽量保持产品化升级友好。

## 判断：初始化 JS 还是个性化 JS

以下情况使用初始化 JS：

- 当前正在新建页面。
- 目标项目本身拥有该页面初始化 JS，且本次按钮属于页面基础功能。

以下情况优先使用个性化 JS：

- 页面已经存在。
- 页面来自产品化代码，或者原文件需要保持升级友好。
- 本次功能属于地区、银行或客户个性化。

个性化 JS 通常命名为 `<原页面或原JS名>Custom.js`，并通过 `GAP_MODULE.REF_JS` 加载；如果 JSP 不支持 `REF_JS`，再使用 JSP 覆盖并硬编码 `<script>` 引入。

## 必查项

1. 找到目标 JSP 和初始化 JS。
2. 找到同页面已有按钮配置或同类按钮 SQL。
3. 确认按钮是否由 `PB_SYS_BUTTON` 及状态表控制。
4. 检查 JSP 是否包含 `scripts.jsp`。
5. 找一个类似按钮 handler，优先模仿其写法。

常用搜索：

```bash
rg -n "JspName|PageName|scripts.jsp|_menu.ref_js|PB_SYS_BUTTON|buttonId|BUTTON_ID" .
rg -n "handler|listeners|toolbar|StatusButton|addButton|buttonName" realware src */src/main
```

## REF_JS 检查

`GAP_MODULE.REF_JS` 生效必须同时满足：

1. 页面通过 `doGo.do` 打开，并且菜单 id 有效。
2. JSP 包含 `scripts.jsp`。
3. `GAP_MENU` 关联了 `GAP_MODULE`。
4. `GAP_MODULE.REF_JS` 配置了不带 `.js` 后缀的 JS 路径。

如果 JSP 不包含 `scripts.jsp`，`REF_JS` 不会生效，应复制/覆盖 JSP，并在 JSP 中硬编码个性化 JS 引用。账户维护类页面经常属于这种情况。

## 实施清单

- 页面使用数据库按钮配置时，新增或修改 `PB_SYS_BUTTON` SQL。
- 确保 `BUTTON_ID` 与 JavaScript 函数名或 handler 映射一致。
- 如果按钮受状态控制，同步维护状态编码配置。
- 个性化 JS 放在目标模块/地区已有 custom JS 目录中。
- 使用 `REF_JS` 时，`GAP_MODULE.REF_JS` 写成类似 `RCU_js/SomePageCustom`，不要带 `.js`。
- JSP 硬编码 `<script>` 时，保留原有 include 和脚本顺序，把新增脚本放在相关 JS 附近。
- 所有 `.js`、`.jsp`、SQL 文件中的真实代码/配置变更都按通用规则加 AI 标记；SQL 如单独保存为 `.sql` 不强制，但建议用 SQL 注释标明用途。

## 常见问题

- SQL 的按钮 ID 和 JS handler 不一致。
- 个性化按钮的 `CUSTOM` 标志设置错误。
- `STATUS_CODES` 缺少当前页面状态。
- JSP 没有 `scripts.jsp`，导致 `REF_JS` 永远不加载。
- `REF_JS` 误写了 `.js` 后缀。
- 直接修改产品化初始化 JS，而不是在地区项目新增个性化 JS。
