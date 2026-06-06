# 页面数据加载通用模板

## 适用场景

- 新页面的 `loadXXX.do`、`queryXXX.do`。
- 已有页面新增查询接口。
- 新表、新查询条件、新分页列表。

这份模板只管“把数据查出来并返回给前端”，不管菜单、模块、按钮、状态、列配置。

> 说明：下面的代码是中性骨架。2.x/3.x 的注入方式、DAO 工具、分页方法和返回包装，请按当前项目已有写法替换。

## 默认推荐：直连查询

直连查询适合绝大多数新增页面，尤其是产品化里还没有现成 billType、字段映射、明细配置的情况。

### Controller 模板

```java
@Controller
public class ExampleController extends RootController {

    @Autowired
    private IExampleService exampleService;

    /**
     * 加载列表数据。
     * 说明：这里演示的是通用直连查询写法，实际参数名、返回格式要跟当前项目已有页面保持一致。
     */
    @RequestMapping(value = "/loadExampleList.do")
    public @ResponseBody Object loadExampleList(HttpServletRequest request, HttpServletResponse response) {
        Session session = copySession(request);

        ExampleCondition condition = new ExampleCondition();
        String keyword = request.getParameter("keyword");
        if (StringUtil.isNotEmpty(keyword)) {
            condition.setKeyword(keyword.trim());
        }

        Paging page = parsePage(request);
        List<String> fieldNames = parseFieldNames(request, "filedNames");

        ReturnPage returnPage = exampleService.loadExampleList(session, condition, page);
        return buildPageResult(returnPage, fieldNames);
    }
}
```

### Service 模板

```java
public interface IExampleService {
    ReturnPage loadExampleList(Session session, ExampleCondition condition, Paging page);
}

@Service
public class ExampleServiceImpl implements IExampleService {

    @Autowired
    private ExampleDao exampleDao;

    @Override
    public ReturnPage loadExampleList(Session session, ExampleCondition condition, Paging page) {
        return exampleDao.loadExampleList(session, condition, page);
    }
}
```

### DAO 模板

```java
public interface ExampleDao {
    ReturnPage loadExampleList(Session session, ExampleCondition condition, Paging page);
}

@Repository
public class ExampleDaoImpl implements ExampleDao {

    @Override
    public ReturnPage loadExampleList(Session session, ExampleCondition condition, Paging page) {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT t.id, t.name, t.status ");
        sql.append("  FROM example_table t ");
        sql.append(" WHERE 1 = 1 ");

        Map<String, Object> params = new HashMap<String, Object>();
        if (StringUtil.isNotEmpty(condition.getKeyword())) {
            sql.append(" AND t.name LIKE :keyword ");
            params.put("keyword", "%" + condition.getKeyword() + "%");
        }

        // 说明：这里的 queryPage 代表当前项目已有的分页查询封装，
        // 可能是 DaoSupport、Mapper、JdbcTemplate、QueryBuilder 等，按目标项目替换即可。
        return queryPage(sql.toString(), params, page, ExampleDto.class);
    }
}
```

## 可选分支：单据引擎

只有在目标项目已经明确要求 billEngine 路径时，才按单据引擎继续配置：

- billType
- 主表字段映射
- 明细字段映射
- 加载/更新/删除关系

如果产品化里没有这套配置，优先回到直连查询。

## 使用提示

- 参数名、分页参数、返回结构先对齐现有页面。
- 直接复制模板时，优先替换成当前项目已经存在的 `loadXXX.do` 习惯。
- 若项目里的返回格式不是 `buildPageResult`，就改成项目现有包装方式。
