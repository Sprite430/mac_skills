# 版本识别

## 目录

- 已知路径
- 识别规则
- 2.x 结构
- 3.x 结构
- 参考代码查找顺序

## 已知路径

| 角色 | 版本 | 路径 |
|---|---:|---|
| 3.x 产品化基线 | 3.x | `/Users/zhangchengke/Documents/ZKJN/code/PbServerApplication/pb` |
| 2.x 产品化基线 | 2.x | `/Users/zhangchengke/Documents/ZKJN/code/svn/source/tags/Product/PB2.1.0(build20210918)` |
| 四川 3.x 个性化项目 | 3.x | `/Users/zhangchengke/Documents/ZKJN/code/svn/electronic/ProxyBank/ProxyBankV2/customize/sichuan/SiChuanApplication` |
| 四川 2.x 个性化项目 | 2.x | `/Users/zhangchengke/Documents/ZKJN/code/svn/pbclient_BankCustom/trunk/SiChuan/SiChuan_Server_Maven_Unity` |

## 识别规则

先判断是否属于 PB/PbServer 范围。出现以下特征时，通常不属于本 skill：

- 项目是独立工具、迁移工具、命令行工具或脚本工程。
- 没有 `realware/`、PB Controller/Service 包结构、`GAP_MODULE`/`PB_SYS_BUTTON`/`PB_AUTO_TASK` 等业务配置迹象。
- 用户需求与 PB 页面、代理银行、国库集中支付业务无关。

非 PB 项目不要继续套用 2.x/3.x 页面、realware、GAP 表或 PB 自动任务规则，除非用户明确要求。

出现以下多个特征时，通常是 2.x：

- `realware/`
- `src/springmvc-servlet.xml`
- `src/spring-views.properties`
- 大量 `src/*-context.xml`
- Service bean 通过 XML 定义

出现以下多个特征时，通常是 3.x：

- 父级 `pom.xml` 加业务模块，如 `luzhou`、`rcc`、`boc`、`sccommon`
- 模块下有 `src/main/java`
- 模块下有 `src/main/resources`
- 模块下有 `src/main/webapp/WEB-INF/views`
- Service 多使用 Spring 注解

如果两类信号同时存在，以目标文件所在最近模块的现有习惯为准。

## 2.x 结构

常见文件和目录：

```text
realware/
realware/WEB-INF/views/
realware/<region>_js/
realware/js/
src/
src/spring-views.properties
src/springmvc-servlet.xml
src/custom-context.xml
src/*-context.xml
source_code_lib/
```

规则：

- Controller 可使用 `@Controller` 和 `@Autowired`。
- Service 实现通常配置在 XML 中，比如 `src/custom-context.xml` 或业务 `*-context.xml`。
- 除非同模块已有一致写法，不默认给 2.x Service 加 `@Service`。
- 新增 JSP 视图必须维护 `src/spring-views.properties`。

## 3.x 结构

常见模块结构：

```text
<module>/src/main/java/
<module>/src/main/resources/
<module>/src/main/resources/static/<module>_js/
<module>/src/main/webapp/WEB-INF/views/
<module>/src/main/webapp/WEB-INF/viewscustom/
<module>/pom.xml
source_code_lib/
```

规则：

- Controller 通常仍继承 `RootController`。
- Service 通常使用 `@Service`。
- Java 包、resources、JSP 都应落在正确模块内，避免写到兄弟银行模块。
- 个性化 JSP 覆盖通常放 `viewscustom/`，但最终跟随目标模块既有习惯。

## 参考代码查找顺序

1. 目标项目同模块或同银行/地区。
2. 目标项目兄弟模块。
3. 目标项目 `source_code_lib/`。
4. 匹配版本的已知产品化基线。

3.x 个性化项目中，如果本地 `source_code_lib/` 缺失或不完整，再参考 `/Users/zhangchengke/Documents/ZKJN/code/PbServerApplication/pb`。

2.x 个性化项目中，如果本地 `source_code_lib/` 缺失或不完整，再参考 `/Users/zhangchengke/Documents/ZKJN/code/svn/source/tags/Product/PB2.1.0(build20210918)`。
