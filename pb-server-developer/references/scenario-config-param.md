# 场景：配置文件参数

## 目录

- 目标
- 必查项
- 文件类型规则
- 实施清单

## 目标

新增或修改 `.properties`、`.yml`、XML 中的配置项，并在需要时接入 Java 读取逻辑。

## 必查项

先找最接近的已有配置键，以及它如何被读取：

```bash
rg -n "key.name|@Value|Environment|getProperty|PropertiesLoader|PropertyPlaceholder|\\.properties|application.yml" .
rg -n "<context:property-placeholder|PropertyPlaceholderConfigurer|<util:properties" src */src/main/resources
```

银行/地区配置优先搜索对应银行文件，再对比兄弟银行文件。

## 文件类型规则

Properties：

- 跟随现有 key 前缀和命名风格。
- 周边配置有注释时，新增 key 也补充注释。
- 保持文件现有编码和中文写法。

YAML：

- 保持缩进和现有层级。
- 不要在多个 profile 重复配置同一 key，除非确实需要环境差异。

XML：

- bean/property 放到与相关 Bean 相同的 context 文件。
- 2.x 中 XML 可能是主要注册和注入方式。

## 实施清单

- 把配置 key 加到正确环境、银行或模块文件。
- 只有现有配置绑定不覆盖时，才新增 Java 读取逻辑。
- 项目习惯支持默认值时，提供安全默认值。
- 说明配置是否需要重启或重新部署才生效。
- 所有 `.properties`、`.yml`、`.xml`、`.java`、`.sh` 变更块加 AI 标记。
