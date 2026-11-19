# 场景：系统参数

## 目录

- 目标
- 必查项
- PB 产品化参数体系（PB_PARAMETER / PbParameters）
- 参数设计
- 实施清单

## 目标

新增数据库系统参数、业务开关或可配置业务值，并在 Java/JS 逻辑中读取使用。

## 必查项

不同版本和模块的参数表/API 可能不同，生成 SQL 前必须先找当前项目真实写法。

常用搜索：

```bash
rg -n "PB_SYS_PARAM|SYS_PARAM|sysParam|SysParam|PARAM_CODE|PARAM_VALUE|get.*Param|getSysParam|para" .
rg -n "select .*param|insert .*param|update .*param" .
```

重点查看：

- 现有参数表字段。
- 参数 code 命名规则。
- 参数是否有缓存和刷新机制。
- Java 中读取参数的 helper 或 Service。
- 参数是否区分账套、行政区划、银行、模块。

## PB 产品化参数体系（PB_PARAMETER / PbParameters）

PB 2.x/3.x 产品化参数走 `PB_PARAMETER` + `PB_PARAMETER_VALUES`，由 `grp.pt.pb.util.PbParameters` 读取；与老 `PB_SYS_PARAM` 机制并存，先确认项目实际用哪套（搜到 `PbParameters.getStringParameter` 调用即为本套）。

### 公共 / 私有必须先看代码怎么读，不能凭名字猜

| 代码读取方式 | 归属 | 存储 |
|---|---|---|
| `PbParameters.getStringParameter(key)` / `getParameterValue(key)` | 公共（IS_PUBLIC=1） | 值在 `PB_PARAMETER.DEFAULT_VALUE` |
| `PbParameters.getStringParameter(key, admDivCode)` / `getParameterValue(key, admdiv)` | 私有（IS_PUBLIC=0） | 定义在 `PB_PARAMETER`；每个区划一行 `PB_PARAMETER_VALUES(PARA_ID, ADMDIV_CODE, PARA_VALUE)`，代码读的是区划值 |

- 产品自带参数既有公共也有私有；公共树和私有树可能各有一个同名的组（如"省个性参数配置"），按 IS_PUBLIC 区分归属。
- 把公共参数误插成私有（或反之）的典型现象：参数页面重复显示、代码永远读不到值（私有读取只查 `is_public=0`，反之亦然）。
- 私有参数没有对应区划的记录时读取返回 null；调用方不判空常见 NPE（如 `pb.unionKeyField` 未配时 `split("#")` 空指针）。

### 父节点（参数树）

- 参数页面按树展示，`PARENT_ID` 指向"参数组"；组本身也是 `PB_PARAMETER` 记录：`PARA_NAME=组名`，`PARA_KEY` 为空或**不带 `pb.` 前缀**（参数 key 均以 `pb.` 开头，可据此区分参数和组）。
- **不能挂根 `'0'`**（挂根等于没分类，部分现场页面不显示）；公共参数只挂公共树的组，私有参数只挂私有树的组。
- 组按业务语义选择（如流水配置、自动转账、省个性参数配置）；业务组找不到时退到同树的「省个性参数配置」（公共/私有树可能各有一个）；仍找不到就 `RAISE_APPLICATION_ERROR` 明确提示由现场改脚本，不要静默挂根。

### 幂等 SQL 骨架（Oracle）

```sql
-- 按组名查组：业务组 → 同树「省个性参数配置」→ 报错
DECLARE
  v_parent VARCHAR2(38);
BEGIN
  BEGIN
    SELECT PARA_ID INTO v_parent FROM PB_PARAMETER
     WHERE PARA_NAME = '流水配置' AND IS_PUBLIC = 1
       AND (PARA_KEY IS NULL OR PARA_KEY NOT LIKE 'pb.%') AND ROWNUM = 1;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      BEGIN
        SELECT PARA_ID INTO v_parent FROM PB_PARAMETER
         WHERE PARA_NAME = '省个性参数配置' AND IS_PUBLIC = 1
           AND (PARA_KEY IS NULL OR PARA_KEY NOT LIKE 'pb.%') AND ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE_APPLICATION_ERROR(-20001, '公共参数组【流水配置】和【省个性参数配置】都不存在：请按现场实际组名修改脚本');
      END;
  END;

  -- 不存在才插入；已存在不覆盖现场取值
  INSERT INTO PB_PARAMETER (PARA_ID, PARA_KEY, PARA_NAME, DEFAULT_VALUE, PARA_REMARK,
                            IS_PUBLIC, DISP_MODE, DISP_ORDER, PARENT_ID, NULLABLE)
  SELECT SYS_GUID(), 'pb.xxx', '名称', '默认值', '备注', 1, 0, 0, v_parent, 1 FROM DUAL
   WHERE NOT EXISTS (SELECT 1 FROM PB_PARAMETER WHERE PARA_KEY = 'pb.xxx' AND IS_PUBLIC = 1);

  -- 已存在但挂在根上的，归位到组（取值不动）
  UPDATE PB_PARAMETER SET PARENT_ID = v_parent
   WHERE PARA_KEY = 'pb.xxx' AND IS_PUBLIC = 1 AND (PARENT_ID = '0' OR PARENT_ID IS NULL);
END;
/
COMMIT;
```

- 私有参数：`IS_PUBLIC=0`、`DEFAULT_VALUE` 置 NULL，再按区划写 `PB_PARAMETER_VALUES`（先查后插，已有不覆盖）。
- 不要把公共参数用"私有 upsert"过程插入（up 成 `IS_PUBLIC=0` + 区划值）——这是历史事故来源。

### 缓存与生效

- `PbParameters` 有静态缓存（公共一份、每个区划一份），应用运行中直接改库**不生效**；脚本执行后重启应用，或在参数管理页面保存触发刷新。

## 参数设计

需要明确：

- 参数 code/key。
- 中文名称和备注。
- 值类型：boolean、枚举、数字、字符串、JSON 风格文本。
- 默认值。
- 作用范围：全局、模块、银行、行政区划、账套。
- 参数缺失时的运行行为。

业务开关要优先使用安全默认值，默认保持原有行为不变。

## 实施清单

- 使用目标项目真实参数表和列名生成 SQL。
- 只在必要位置添加 Java/JS 读取逻辑。
- 不要在多个地方硬编码同一个参数值。
- 新增读取逻辑附近写注释，说明该参数影响的业务行为。
- 说明参数变更后是否需要重启、刷新缓存或重新登录。
- 相关代码/配置变更块加 AI 标记。
