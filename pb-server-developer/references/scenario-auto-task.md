# 场景：自动任务

## 目录

- 目标
- 必查项
- PB_AUTO_TASK 字段
- 2.x/3.x 实现要点
- 实施清单

## 目标

新增或修改自动任务/定时任务 Job，并生成或调整数据库任务注册配置。

## 必查项

先在目标模块和产品化代码中搜索已有任务：

```bash
rg -n "PB_AUTO_TASK|JOB_NAME|JOB_TYPE|CLASS_NAME|MAX_EXE_TIME" .
rg -n "Auto.*Task|execute\\(|Quartz|Job|Task" src */src/main/java
```

优先复制最接近任务的基类、接口、日志和异常处理方式。

## PB_AUTO_TASK 字段

常见字段：

- `JOB_ID`：GUID 风格 ID。
- `JOB_NAME`：有意义的英文任务名。
- `JOB_TYPE`：`1` 间隔执行，`2` 定时/Cron，`3` 线程执行。
- `CLASS_NAME`：Java 类全限定名。
- `JOB_ENABLE`：通常初始为 `0`，除非用户要求启用。
- `JOB_TIME`：`JOB_TYPE=2` 的定时表达式。
- `JOB_INTERVAL`：`JOB_TYPE=1` 的间隔。
- `REPEATCOUNT`、`DELAYTIME`、`EXE_TYPE`、`MAX_EXE_TIME`、`PARAMETER`、`REMARK`。

## 2.x/3.x 实现要点

2.x：

- Java 类放到现有任务包风格下。
- 类似任务需要 XML bean 时，本任务也要补 XML。
- 除非本地示例使用注解，不默认添加 `@Service`。

3.x：

- Java 类放到目标模块。
- 是否加注解以本模块已有任务为准。
- 注意组件扫描和模块包边界。

## 实施清单

- 未提供触发时间时，先询问定时规则。
- 单机/多机执行不明确时，询问或按同类任务默认值。
- 参数必须可解析，并在代码注释中说明含义。
- 生成 SQL 时提示用户核对 `JOB_ID`、`JOB_NAME` 唯一性。
- 所有 `.java`、`.xml`、`.properties`、`.yml` 变更块加 AI 标记。
