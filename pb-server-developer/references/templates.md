# 模板

## 目录

- 2.x Controller 形态
- 3.x Controller 形态
- 2.x Service XML 形态
- 3.x Service 形态
- SQL 骨架
- 状态/列配置模板
- 页面数据加载模板

## 2.x Controller 形态

```java
@Controller
public class ExampleController extends RootController {
    private static Logger log = Logger.getLogger(ExampleController.class);

    @Autowired
    private IExampleService exampleService;

    @RequestMapping(value = "/exampleQuery.do")
    public @ResponseBody Object exampleQuery(HttpServletRequest request, HttpServletResponse response) {
        Session session = copySession(request);
        // 返回结构必须与附近方法保持一致。
        return exampleService.exampleQuery(session, request.getParameterMap());
    }
}
```

## 3.x Controller 形态

```java
@Slf4j
@Controller
public class ExampleController extends RootController {
    @Autowired
    private IExampleService exampleService;

    @RequestMapping(value = "/exampleQuery.do")
    public @ResponseBody Object exampleQuery(HttpServletRequest request, HttpServletResponse response) {
        Session session = copySession(request);
        return exampleService.exampleQuery(session, request.getParameterMap());
    }
}
```

## 2.x Service XML 形态

```xml
<bean id="exampleService" class="grp.pb.branch.example.service.impl.ExampleServiceImpl">
    <property name="daoSupport" ref="bill.DaoSupport"/>
</bean>
```

## 3.x Service 形态

```java
public interface IExampleService {
    Object exampleQuery(Session session, Map<String, String[]> params);
}

@Service
public class ExampleServiceImpl implements IExampleService {
    @Override
    public Object exampleQuery(Session session, Map<String, String[]> params) {
        return null;
    }
}
```

## SQL 骨架

这些骨架只能在核对目标项目表结构后使用。

```sql
-- GAP_MODULE：执行前核对 ID、CODE、CLASS_NAME、REF_JS。
INSERT INTO GAP_MODULE (ID, CODE, NAME, CLASS_NAME, PARENT_ID, SYSTEM_ID, REF_JS)
VALUES (${MODULE_ID}, '${MODULE_CODE}', '${MODULE_NAME}', '${JSP_NAME}', ${PARENT_ID}, ${SYSTEM_ID}, '${REF_JS}');

-- GAP_MENU：执行前核对 ID、排序号、父菜单。
INSERT INTO GAP_MENU (ID, MODULE_ID, MENU_NAME, URL, PARENT_ID, ORDER_NUM, STATUS)
VALUES (${MENU_ID}, ${MODULE_ID}, '${MENU_NAME}', '/realware/doGo.do?description=${DESC}&id=${MENU_ID}', ${PARENT_MENU_ID}, ${ORDER_NUM}, 1);

-- PB_SYS_BUTTON：BUTTON_ID 必须与 JS handler 保持一致。
INSERT INTO PB_SYS_BUTTON (JSP_NAME, BUTTON_ID, BUTTON_NAME, VISIBLE, ICON, CUSTOM, STATUS_CODES, DISP_ORDER)
VALUES ('${JSP_NAME}', '${BUTTON_ID}', '${BUTTON_NAME}', 1, '${ICON}', ${CUSTOM}, '${STATUS_CODES}', ${DISP_ORDER});

-- PB_AUTO_TASK：执行前核对 JOB_ID/JOB_NAME 唯一性。
INSERT INTO PB_AUTO_TASK (JOB_ID, JOB_NAME, JOB_TYPE, CLASS_NAME, JOB_ENABLE, JOB_TIME, JOB_INTERVAL, EXE_TYPE, MAX_EXE_TIME, PARAMETER, REMARK)
VALUES ('${JOB_ID}', '${JOB_NAME}', ${JOB_TYPE}, '${CLASS_NAME}', 0, '${JOB_TIME}', '${JOB_INTERVAL}', ${EXE_TYPE}, ${MAX_EXE_TIME}, '${PARAMETER}', '${REMARK}');
```

## 状态/列配置模板

已有 MVC 页面新增状态、挂页面、配列的可复制模板见 [sql-status-column-template.md](sql-status-column-template.md)。

## 页面数据加载模板

`loadXXX.do` 的通用直连查询模板见 [page-data-load-template.md](page-data-load-template.md)。
