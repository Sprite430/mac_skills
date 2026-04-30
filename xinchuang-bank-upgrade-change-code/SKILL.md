---
name: xinchuang-bank-upgrade-change-code
description: 升级Java模块代码到信创版Spring Boot风格。
---

# 信创版本升级 (Bank Upgrade)

## 角色

你是一位资深 Java 架构师，精通 Spring Boot 2.7.x 和 CTJSoft 技术规范。

## 任务目标

将指定模块中的代码转化为 Spring Boot 风格，按以下顺序执行：

## 开始前

请用户提供需要处理的模块路径或具体文件名。若未提供，主动询问。

---

## 执行策略
对指定目录下的每个 Java 文件，按照检查清单中的内容依次检查并应用改造
采用「按文件垂直处理」策略：
- 对每个文件一次性应用所有适用的改造
- 避免重复扫描和重复读取
- 完成一个文件后再处理下一个


## 检查清单
### 1. 处理 Job 类（自动任务）

搜索路径中所有继承 `AutoJobAdapter` 的.java类文件：

- 将 `extends AutoJobAdapter` 改为 `extends ParameterAutoJobAdapter`
- 将 `public void executeJob()` 改为 `public void executeJob(JobDataMap paraMap) throws Exception`
- 添加方法：

```java
@Override
public void interrupt() throws UnableToInterruptJobException {
}
```

---

### 2. 日志改造

搜索路径中所有包含 `Logger.getLogger(xxx.class)` 的.java类文件：

1. 在此类上添加 `@Slf4j` 注解
2. 添加 `import lombok.extern.slf4j.Slf4j;`
3. 删除原日志定义 `Logger.getLogger(xxx.class);` 
- 整个文件中所有 `logger.xxx` 修改为  `log.xxx`

---

### 3. 处理业务类（XML 对应的 Java 类）

搜索路径中的所有的 .xml配置文件：针对 XML 配置文件中的每个 `<bean>` 配置项，如：

```xml
<bean id="xxxService" class="...xxxx.xxxServiceImpl">
```

对其对应的 Java 类执行：

1. 添加注解 `@Service("xxxService")`   与bean id相同，不可修改大小写。
2. 添加事务注解 `@Transactional(rollbackFor = Exception.class)`
3. 为对象属性添加 `@Autowired`
4. 删除该类中对应 bean 属性的 getter/setter 方法
5. 添加 import：

```java
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
```

6. 若 XML 文件下所有 bean 都已处理完成，删除该 XML 配置文件

---

### 4. bean 名替换

搜索所有 `getBean("xxxx")` 调用，按以下映射替换：

| 原始 bean 名 | 替换为 |
|---|---|
| `pb.ss.psfaBocPayService` | `psfaBocPayServiceImpl` |
| `pb.common.PbCommonService` | `pbCommonService` |

---

### 5. AOP/ 拦截类添加 @Component

1. 查找 `<mvc:interceptor>` 中 `<bean class="xxxx">` 对应的类 → 添加 `@Component`
2. XML 中 bean id 不以 `Service` 结尾的 → 对应 class 类添加 `@Component`
3. 并增加引入
```java
import org.springframework.stereotype.Component;
```

---

### 6. 方法替换

全局替换：
- BizType 的 `.getNoRule()` → `.findNoRule()` 
- ModuleService的 `loadModuleById(` → `loadCompleteModuleById(`

---

## 要求
- 保持代码格式和原有逻辑
- 确保编译通过
- 符合 CTJSoft 信创标准