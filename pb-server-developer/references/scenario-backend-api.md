# 场景：后端接口

## 目录

- 目标
- 必查项
- 2.x 写法
- 3.x 写法
- 实施清单
- 验证方式

## 目标

新增或修改 PB 后端 Controller/Service/DAO 接口，通常供 ExtJS Ajax、页面初始化或后端任务调用。

## 必查项

1. 找到目标页面或业务功能对应的 Controller。
2. 找到请求参数、返回结构相似的已有方法。
3. 追踪 Controller 到 Service、DAO 或 SQL/query 的现有链路。
4. 检查 Session 获取、日志、异常处理、返回包装对象的项目约定。
5. 在产品化或 `source_code_lib/` 中搜索相同或相近业务实现。

常用搜索：

```bash
rg -n "@RequestMapping|ResponseBody|RootController|copySession|ModelAndView" .
rg -n "Ext.Ajax.request|url:|loadUrl|\\.do" realware */src/main/resources/static */src/main/webapp
rg -n "interface .*Service|ServiceImpl|daoSupport|queryFor|update\\(" src */src/main/java
```

## 2.x 写法

- Controller 常见写法是 `@Controller`、方法级 `@RequestMapping`、`@ResponseBody`、`copySession(request)`，并继承 `RootController`。
- Service 接口和实现通常在 `src/grp/...` 下。
- Service 实现一般需要在 XML 中注册，例如 `src/custom-context.xml` 或业务 `*-context.xml`。
- 除非同包已有一致写法，不默认给 2.x Service 加 `@Service`。

## 3.x 写法

- Controller 通常使用 `@Controller`，可能配合 Lombok 的 `@Slf4j`。
- Service 通常使用 `@Service`。
- 代码必须放到正确模块包下，不要写到兄弟银行模块。
- 如果本地 Controller 习惯使用方法级完整路径映射，继续沿用。

## 实施清单

- 属于已有页面的接口，优先复用已有 Controller。
- 业务逻辑复杂或复用时再新增 Service 方法。
- 请求参数名必须与前端 JS 调用一致。
- 返回结构必须与 ExtJS success/failure 处理一致。
- DAO/query 按目标项目现有方式实现。
- 2.x 需要时添加 XML bean/property 注入。
- 每个 `.java`、`.xml`、`.js` 变更块都加 AI 标记。

## 验证方式

- 检查前端 URL 与 Controller mapping 是否完全匹配。
- 2.x 检查 Service bean id 与注入字段或 XML property 是否匹配。
- 条件允许时执行模块编译或测试。
- 无法运行时，输出请求参数、返回结构和手工测试步骤。
