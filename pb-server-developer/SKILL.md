# 国库集中支付系统开发辅助工具

## 1. 技能概述

### 1.1 技能定位

本技能是专为国库集中支付系统（PbServer）开发设计的辅助工具，旨在通过结构化的问答引导和自动化代码生成，大幅提升开发效率。本技能支持多个版本的产品化代码，包括2.x和3.x等主流版本，能够根据项目实际情况自动适配相应的开发规范和代码模板。

### 1.2 版本支持说明

本技能支持以下版本的国库集中支付系统开发：

| 版本 | 架构模式 | 配置方式 | 产品化包格式 |
|------|----------|----------|--------------|
| **2.x版本** | 传统Java Web | XML配置为主 | Pb-{版本号}-sources |
| **3.x版本** | Spring Boot | 注解配置为主 | pb-{版本号}.jar |

2.x版本采用传统的Java Web架构，Bean配置主要通过XML文件完成。3.x版本采用Spring Boot框架，全面使用注解进行Bean定义和依赖注入，架构更加现代化。

### 1.3 术语定义

为确保文档中术语使用准确统一，本技能使用以下术语定义：

**1. 产品化代码**

指产品化厂商提供的标准代码，存放在项目根目录的 `source_code_lib/` 目录中。2.x版本以源码包形式存在（如 `Pb-2.1.1-sources`），3.x版本被打包为JAR文件通过Maven依赖引入（如 `pb-3.4.9.jar`）。

**2. 初始化代码**

指页面创建时，在JSP中通过 `<script>` 标签直接引入的JavaScript文件。初始化代码与页面一一对应，是页面首次创建时的基础功能代码。初始化代码可能存放在 `realware/js/` 目录，也可能存放在省份定制目录下（如 `realware/{省份}_js/`）。

**3. 个性化代码**

指页面已存在后，通过 `GAP_MODULE.REF_JS` 配置引入的JavaScript文件。个性化代码用于在不修改初始化代码的情况下，为页面添加额外的功能扩展。个性化代码通常以 `Custom` 结尾，存放在省份定制目录下（如 `realware/{省份}_js/RefundZero4UnityCustom.js`）。

**4. 省份个性化代码**

指针对特定省份定制的JavaScript代码，存放在各省份的定制目录下（如 `scbank_js/`、`leshan_js/` 等）。省份个性化代码目录既可以存放初始化代码，也可以存放个性化代码，区分依据是代码的引入方式而非存放位置。

**核心区别**：
- **初始化代码** = JSP中 `<script>` 标签直接引入
- **个性化代码** = `GAP_MODULE.REF_JS` 配置引入
- 两者可以共存于同一个省份定制目录中

### 1.4 适用场景

**场景一：新增完整页面**

当系统需要新增一个完整的业务页面时，需要同时完成数据库配置、JSP页面创建、初始化JavaScript文件编写、Controller和Service开发等工作。这是最复杂的场景，涉及多个配置表的插入和多类型代码文件的生成。

**场景二：扩展已有页面的初始化JS按钮**

当需要在已有的页面上添加新的按钮功能时，如果该功能是通用的业务逻辑，会被添加到初始化JavaScript文件中。这种情况下，只需要生成按钮对应的JavaScript方法实现。

**场景三：扩展已有页面的个性化JS按钮**

当需要在已有的页面上添加省份特定的功能按钮时，应该创建或修改个性化JavaScript文件。这种方式不会影响初始化代码，便于后续版本升级。个性化JavaScript文件配置在GAP_MODULE表的REF_JS字段中。

**场景四：新增自动任务**

系统中的定时任务（Job）需要数据库配置和Java实现类。本技能可以生成完整的自动任务相关代码和配置。

### 1.5 核心能力

**数据库配置自动生成**

能够根据用户输入自动生成GAP_MODULE、GAP_MENU、PB_SYS_BUTTON、PB_SYS_STATUS、PB_STATUS_CONDITION等配置表的INSERT语句。在生成前会查询目标数据库获取当前最大值，确保生成的ID不冲突。

**多模式页面支持**

支持EXT传统模式和MVC模式两种页面开发方式。EXT模式适用于简单的单页面功能，代码结构较为直接；MVC模式使用ExtJS的MVC架构，适合复杂的业务页面，需要声明controllers和mainView配置。

**多版本代码生成**

根据项目版本自动适配相应的代码模板。2.x版本生成XML配置和继承基类的Controller代码，3.x版本生成注解配置的Controller和Service代码。所有生成的代码都遵循对应版本的编码规范和命名约定。

**灵活的代码生成**

根据不同的场景需求，可以生成JSP页面代码、初始化JavaScript功能代码、个性化JavaScript代码、Java Controller代码、Java Service代码、配置文件等多种类型的代码片段。

## 2. 版本识别与项目架构

### 2.1 版本自动识别

本技能能够自动识别当前工作目录对应的产品化版本。在启动技能时，系统会检测项目的目录结构和配置文件，判断当前项目使用的版本类型，并自动加载对应的开发规范和代码模板。

版本识别的依据包括：项目目录结构、配置文件类型、源码包格式等。如果系统无法自动识别版本，会提示用户手动指定版本类型。

### 2.2 2.x版本项目架构

2.x版本采用传统的Java Web项目结构，核心代码组织在realware目录下。

```
{项目名称}/
├── realware/                          # Web应用根目录
│   ├── WEB-INF/
│   │   ├── views/                     # MVC模式的JSP页面
│   │   ├── {定制类型}_jsp/          # 定制JSP页面（根据实际项目调整）
│   │   └── classes/                  # Java编译后的类文件
│   ├── js/                            # 初始化JavaScript文件
│   │   ├── controller/                # ExtJS控制器
│   │   ├── store/                     # ExtJS数据Store
│   │   ├── model/                     # ExtJS数据模型
│   │   └── view/                      # ExtJS视图组件
│   ├── {省份}_js/                    # 省份定制JavaScript（可存放初始化代码或个性化代码）
│   └── jscustom/                      # JavaScript自定义扩展
└── source_code_lib/                   # 产品化代码库
```

2.x版本的源码包存放在source_code_lib目录下，格式为`Pb-{版本号}-sources`。例如：`Pb-2.1.1-sources`表示2.1.1版本的源码包。

### 2.3 3.x版本项目架构

3.x版本采用Spring Boot项目结构，按模块化组织代码，不同的银行或省份定制代码放在不同的模块目录下。

```
{项目名称}/
├── {模块名}/                           # 业务模块（根据实际项目调整）
│   ├── src/main/
│   │   ├── java/
│   │   │   └── grp/pb/branch/{模块名}/
│   │   │       ├── web/               # Web控制器（注解方式）
│   │   │       ├── service/           # 业务服务（注解方式）
│   │   │       ├── job/              # 定时任务
│   │   │       └── model/            # 数据模型
│   │   ├── resources/
│   │   │   ├── static/
│   │   │   │   └── {模块标识}_js/   # 定制JavaScript
│   │   │   └── application.yml       # Spring Boot配置
│   │   └── webapp/
│   │   └── WEB-INF/
│   │           ├── views/            # 初始化JSP
│   │           └── viewscustom/      # 个性化JSP（3.x专用）
│   └── pom.xml
├── pom.xml                            # Maven父配置
└── {其他模块}/                        # 其他业务模块
```

3.x版本的源码不再以独立的源码包形式存在，而是被打包为JAR文件，通过Maven依赖引入。例如：`pb-3.4.9.jar`、`pb-utils-3.4.9.jar`等。

### 2.4 两种版本的核心差异

#### 2.4.1 配置方式差异

**2.x版本配置方式**

2.x版本的Bean配置主要通过XML文件完成。Controller需要继承基类或实现接口，Service通过XML注入依赖。

```xml
<!-- beans-config.xml (2.x) -->
<bean id="userService" class="com.example.UserServiceImpl">
    <property name="userDao" ref="userDao"/>
</bean>
```

**3.x版本配置方式**

3.x版本的Bean配置全面采用注解方式。所有配置都内聚在Java代码中，不再需要XML文件。

```java
// 3.x版本
@Service
public class UserServiceImpl implements IUserService {
    
    @Autowired
    private IUserDao userDao;
}
```

#### 2.4.2 文件位置差异

| 文件类型 | 2.x版本位置 | 3.x版本位置 |
|----------|--------------|--------------|
| 个性化JSP | 无专门目录 | `{模块}/viewscustom/` |
| 定制JS | `realware/{定制标识}_js/` | `{模块}/static/{模块标识}_js/` |
| Controller | 继承基类 | `@Controller`注解 |
| Service | XML配置 | `@Service`注解 |

#### 2.4.3 Controller实现差异

**2.x版本Controller**

```java
// 2.x版本
public class UserController extends BaseController {
    
    private IUserService userService;
    
    public void setUserService(IUserService userService) {
        this.userService = userService;
    }
    
    public ModelAndView list(HttpServletRequest request) {
        // 实现代码
    }
}
```

**3.x版本Controller**

```java
// 3.x版本
@Slf4j
@Controller
@RequestMapping("/user")
public class UserController extends RootController {
    
    @Autowired
    private IUserService userService;
    
    @RequestMapping("/list.do")
    public ModelAndView list(HttpServletRequest request) {
        log.info("查询用户列表");
        // 实现代码
    }
}
```

### 2.5 页面模式对比

#### EXT传统模式

EXT模式是系统早期采用的页面开发方式，特点是简单直接，没有采用ExtJS的MVC架构。页面功能和组件都在单个JavaScript文件中定义，代码组织相对扁平。

EXT模式的JSP页面结构非常简洁，只需要在script标签中引入必要的JavaScript文件，不需要声明controllers和mainView配置。页面的初始化和渲染由JavaScript文件自行完成。

这种模式适合功能相对简单的单页面，不需要多个控制器协同工作的情况。代码逻辑集中，便于理解和维护。

#### MVC模式

MVC模式是系统推荐的页面开发方式，采用ExtJS的MVC架构。页面功能分散在Model、View、Controller三个层次中，代码组织更加清晰，便于大型项目的开发和维护。

MVC模式的JSP页面需要在script标签中声明controllers数组和mainView配置。controllers数组指定页面使用的所有控制器，mainView配置指定页面的主视图组件。系统会根据这些配置自动加载对应的控制器和视图组件。

这种模式适合功能复杂的业务页面，多个功能模块需要协同工作的情况。

### 2.7 JavaScript文件说明

在国库集中支付系统中，JavaScript文件按照用途和引入方式分为两类：初始化代码和个性化代码。

**初始化JavaScript文件**

初始化JavaScript文件是页面首次创建时，在JSP中通过 `<script>` 标签直接引入的文件。初始化JavaScript文件包含页面的核心业务逻辑，与页面一一对应。初始化JavaScript文件可能存放在 `realware/js/` 目录，也可能存放在省份定制目录下。

**个性化JavaScript文件**

个性化JavaScript文件用于在不修改初始化代码的情况下，为页面添加额外的功能扩展。个性化JavaScript文件通过 `GAP_MODULE.REF_JS` 字段配置引入。个性化JavaScript文件的命名规范是在初始化文件名后加上Custom后缀，例如：`{页面名}Custom.js`。

**重要说明**

省份定制目录（如 `realware/{省份}_js/`）既可以存放初始化JavaScript文件，也可以存放个性化JavaScript文件。区分依据是代码的引入方式：JSP中 `<script>` 直接引入的为初始化代码，`GAP_MODULE.REF_JS` 配置引入的为个性化代码。

## 3. 数据库配置规范

### 3.1 配置表关系

国库集中支付系统的页面配置由多个数据库表协同完成，这些表之间通过外键关联，形成完整的配置体系。

GAP_MODULE表是配置体系的核心，存储页面的基本信息。每个页面在系统中对应一条GAP_MODULE记录。

GAP_MENU表存储页面的菜单配置信息，关联到GAP_MODULE的ID字段。

PB_SYS_BUTTON表存储页面按钮的配置信息，包括按钮ID、名称、图标、可见性、状态关联等属性。

PB_SYS_STATUS表存储页面的状态配置信息。

PB_STATUS_CONDITION表存储状态的具体判断条件。

### 3.2 GAP_MODULE表结构

| 字段名 | 数据类型 | 说明 |
|--------|----------|------|
| ID | NUMBER(10) | 模块唯一标识，主键 |
| CODE | VARCHAR2(50) | 模块编码 |
| NAME | VARCHAR2(100) | 模块显示名称 |
| CLASS_NAME | VARCHAR2(100) | 页面类名，与JSP_NAME对应 |
| DLL_PATH | VARCHAR2(200) | DLL路径，默认为空 |
| PARENT_ID | NUMBER(10) | 父级模块ID，用于分组 |
| REMARK | VARCHAR2(500) | 备注说明 |
| SYSTEM_ID | NUMBER(10) | 系统ID |
| CREATE_DATE | DATE | 创建日期 |
| LAST_VER | NUMBER(10) | 版本号 |
| IS_ACCOUNT | NUMBER(1) | 是否账套相关 |
| PARA_CONFIG_CLASS | VARCHAR2(200) | 参数配置类 |
| BACKLOG_CLASS_NAME | VARCHAR2(200) | 待办类名 |
| REF_JS | VARCHAR2(200) | 个性化JavaScript路径 |

CLASS_NAME字段是页面配置的关键字段，必须与JSP页面的文件名（不含.jsp后缀）保持一致。REF_JS字段用于配置个性化JavaScript文件路径，格式为目录名/文件名，不包含.js后缀。

### 3.3 GAP_MENU表结构

| 字段名 | 数据类型 | 说明 |
|--------|----------|------|
| ID | NUMBER(10) | 菜单唯一标识，主键 |
| MODULE_ID | NUMBER(10) | 关联的模块ID |
| MENU_NAME | VARCHAR2(100) | 菜单显示名称 |
| URL | VARCHAR2(200) | 菜单访问路径 |
| PARENT_ID | NUMBER(10) | 父级菜单ID |
| ORDER_NUM | NUMBER(5) | 菜单排序序号 |
| ICON | VARCHAR2(100) | 菜单图标 |
| STATUS | NUMBER(1) | 菜单状态，1为启用 |

### 3.4 PB_SYS_BUTTON表结构

| 字段名 | 数据类型 | 说明 |
|--------|----------|------|
| JSP_NAME | VARCHAR2(100) | 页面名称，与CLASS_NAME对应 |
| BUTTON_ID | VARCHAR2(50) | 按钮唯一标识 |
| REMARK | VARCHAR2(200) | 按钮备注说明 |
| BUTTON_NAME | VARCHAR2(50) | 按钮显示名称 |
| VISIBLE | NUMBER(1) | 是否可见，1为可见 |
| ICON | VARCHAR2(50) | 按钮图标 |
| CUSTOM | NUMBER(1) | 是否个性化按钮，1为个性化 |
| STATUS_CODES | VARCHAR2(200) | 按钮启用的状态列表 |
| DISP_ORDER | NUMBER(5) | 按钮显示顺序 |
| ENABLE_ADMDIVS | VARCHAR2(200) | 启用的行政区划 |
| DISABLE_ADMDIVS | VARCHAR2(200) | 禁用的行政区划 |

BUTTON_ID字段是按钮配置的关键字段，个性化JavaScript中的方法名必须与此字段保持一致。STATUS_CODES字段使用井号分隔的状态编码列表，表示按钮在哪些状态下可用。

### 3.5 PB_SYS_STATUS表结构

| 字段名 | 数据类型 | 说明 |
|--------|----------|------|
| STATUS_ID | VARCHAR2(50) | 状态唯一标识，主键 |
| JSP_NAME | VARCHAR2(100) | 页面名称 |
| STATUS_CODE | VARCHAR2(20) | 状态编码 |
| STATUS_NAME | VARCHAR2(50) | 状态显示名称 |
| CONDITION | VARCHAR2(200) | 状态条件预览 |
| TYPE | NUMBER(1) | 状态类型 |
| MENU_ID | NUMBER(10) | 关联的菜单ID |

### 3.6 PB_STATUS_CONDITION表结构

| 字段名 | 数据类型 | 说明 |
|--------|----------|------|
| STATUS_CID | VARCHAR2(50) | 条件唯一标识，主键 |
| STATUS_ID | VARCHAR2(50) | 关联的状态ID |
| OPERATION | VARCHAR2(10) | 逻辑运算符，and或or |
| ATTR_CODE | VARCHAR2(50) | 属性编码 |
| RELATION | VARCHAR2(10) | 关系运算符 |
| VALUE | VARCHAR2(200) | 比较值 |
| ALIAS | VARCHAR2(50) | 属性别名 |
| DATATYPE | NUMBER(1) | 数据类型 |

## 4. 代码模板

### 4.1 MVC模式JSP模板

#### 2.x版本JSP模板

```jsp
<%@ page language="java" pageEncoding="UTF-8"%>
<%@ include file="common/taglibs.jsp"%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
    <head>
        <title>${PAGE_TITLE}</title>
        <%@ include file="common/meta.jsp"%>
        <%@ include file="common/scripts.jsp"%>
        <script type="text/javascript" src="<%=path%>/js/${JS_FILE_NAME}.js"></script>
    </head>
    <script type="text/javascript">
        var loadUrl = "<%=path%>/load${ENTITY_NAME}.do";
        var account_type_right = "${ACCOUNT_TYPE}";
        var controllers = [${CONTROLLERS}];
        var mainView = {
            xtype : '${VIEW_XTYPE}'
        };
    </script>
    <body></body>
</html>
```

#### 3.x版本JSP模板

```jsp
<%@ page language="java" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/views/common/taglibs.jsp"%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
    <head>
        <title>${PAGE_TITLE}</title>
        <%@ include file="/WEB-INF/views/common/meta.jsp"%>
        <%@ include file="/WEB-INF/views/common/scripts.jsp"%>
        <script type="text/javascript" src="${pageContext.request.contextPath}/static/${MODULE_JS}/${JS_FILE_NAME}.js"></script>
    </head>
    <script type="text/javascript">
        var loadUrl = "${pageContext.request.contextPath}/load${ENTITY_NAME}.do";
        var account_type_right = "${ACCOUNT_TYPE}";
        var controllers = [${CONTROLLERS}];
        var mainView = {
            xtype : '${VIEW_XTYPE}'
        };
    </script>
    <body></body>
</html>
```

### 4.2 个性化JSP模板

#### 3.x版本个性化JSP模板

3.x版本的个性化JSP存放在viewscustom目录下。

```jsp
<%@ page language="java" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/views/common/taglibs.jsp"%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
    <head>
        <title>${PAGE_TITLE}</title>
        <%@ include file="/WEB-INF/views/common/meta.jsp"%>
        <%@ include file="/WEB-INF/views/common/scripts.jsp"%>
        <script type="text/javascript" src="${pageContext.request.contextPath}/static/${MODULE_JS}/${JS_FILE_NAME}Custom.js"></script>
    </head>
    <body></body>
</html>
```

### 4.3 Controller模板

#### 2.x版本Controller模板

```java
package ${PACKAGE_NAME};

import grp.pt.pb.web.BaseController;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.springframework.web.servlet.ModelAndView;

public class ${CONTROLLER_NAME}Controller extends BaseController {
    
    private ${SERVICE_INTERFACE} ${SERVICE_VARIABLE};
    
    public void set${SERVICE_VARIABLE}(${SERVICE_INTERFACE} ${SERVICE_VARIABLE}) {
        this.${SERVICE_VARIABLE} = ${SERVICE_VARIABLE};
    }
    
    public ModelAndView loadPage(HttpServletRequest request, HttpServletResponse response) {
        ModelAndView view = new ModelAndView("/${JSP_PATH}");
        return view;
    }
}
```

#### 3.x版本Controller模板

```java
package ${PACKAGE_NAME}.web;

import grp.pt.pb.web.RootController;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.HashMap;
import java.util.Map;

/**
 * ${CONTROLLER_DESCRIPTION}
 * ${MODULE_NAME}模块Web控制器
 */
@Slf4j
@Controller
@RequestMapping(value = "/${REQUEST_MAPPING}")
public class ${CONTROLLER_NAME}Controller extends RootController {

    @Autowired
    private ${SERVICE_INTERFACE} ${SERVICE_VARIABLE};

    /**
     * 加载页面
     *
     * @param request  HTTP请求对象
     * @param response HTTP响应对象
     * @return 视图模型
     */
    @RequestMapping(value = ".do")
    public ModelAndView loadPage(HttpServletRequest request, HttpServletResponse response) {
        ModelAndView view = new ModelAndView("/viewscustom/${JSP_NAME}");
        return view;
    }

    /**
     * 加载数据
     *
     * @param request  HTTP请求对象
     * @param response HTTP响应对象
     */
    @RequestMapping(value = "/load${ENTITY_NAME}.do")
    public void load${ENTITY_NAME}(HttpServletRequest request, HttpServletResponse response) {
        try {
            Map<String, String> params = getRequestParams(request);
            Map<String, Object> result = ${SERVICE_VARIABLE}.load${ENTITY_NAME}(params);
            writeResponseText(response, result);
        } catch (Exception e) {
            log.error("加载数据失败", e);
            writeResponseText(response, getErrorMap(e.getMessage()));
        }
    }

    /**
     * 保存数据
     *
     * @param request  HTTP请求对象
     * @param response HTTP响应对象
     */
    @RequestMapping(value = "/save${ENTITY_NAME}.do")
    public void save${ENTITY_NAME}(HttpServletRequest request, HttpServletResponse response) {
        try {
            Map<String, String> params = getRequestParams(request);
            Map<String, Object> result = ${SERVICE_VARIABLE}.save${ENTITY_NAME}(params);
            writeResponseText(response, result);
        } catch (Exception e) {
            log.error("保存数据失败", e);
            writeResponseText(response, getErrorMap(e.getMessage()));
        }
    }
}
```

### 4.4 Service模板

#### 2.x版本Service模板

```java
package ${PACKAGE_NAME};

import java.util.Map;

public class ${SERVICE_CLASS_NAME}Service implements ${SERVICE_INTERFACE} {
    
    public Map<String, Object> load${ENTITY_NAME}(Map<String, String> params) {
        Map<String, Object> result = new HashMap<String, Object>();
        // TODO: 实现加载逻辑
        return result;
    }
}
```

#### 3.x版本Service模板

```java
package ${PACKAGE_NAME}.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;

/**
 * ${SERVICE_DESCRIPTION}
 * ${MODULE_NAME}模块业务服务
 */
@Slf4j
@Service
public class ${SERVICE_CLASS_NAME}Service {

    @Autowired
    private ${DAO_INTERFACE} ${DAO_VARIABLE};

    /**
     * 加载${ENTITY_NAME}数据
     *
     * @param params 查询参数
     * @return 查询结果
     */
    public Map<String, Object> load${ENTITY_NAME}(Map<String, String> params) {
        Map<String, Object> result = new HashMap<>();
        try {
            // TODO: 实现加载逻辑
            result.put("success", true);
            result.put("data", new java.util.ArrayList<>());
        } catch (Exception e) {
            log.error("加载${ENTITY_NAME}失败", e);
            result.put("success", false);
            result.put("message", e.getMessage());
        }
        return result;
    }

    /**
     * 保存${ENTITY_NAME}数据
     *
     * @param params 保存参数
     * @return 保存结果
     */
    @Transactional(rollbackFor = Exception.class)
    public Map<String, Object> save${ENTITY_NAME}(Map<String, String> params) {
        Map<String, Object> result = new HashMap<>();
        try {
            // TODO: 实现保存逻辑
            result.put("success", true);
            result.put("message", "保存成功");
        } catch (Exception e) {
            log.error("保存${ENTITY_NAME}失败", e);
            throw new RuntimeException(e.getMessage());
        }
    }
}
```

### 4.5 个性化JavaScript模板

```javascript
var Custom = function() {
    return {
        /**
         * ${BUTTON_NAME} - ${BUTTON_DESCRIPTION}
         * @param {Ext.grid.Panel} grid - 当前操作的Grid面板
         */
        ${BUTTON_ID} : function(grid) {
            ${FUNCTION_IMPL}
        }
    };
}();

function afterCreateViewport() {
    // 页面初始化完成后的回调
}

function ${OVERRIDE_FUNCTION}() {
    // 覆盖初始化代码中的方法
}
```

### 4.6 Job定时任务模板

#### 2.x版本Job模板

```java
package ${PACKAGE_NAME}.job;

import grp.pt.autotask.bs.SysAutoTaskBO;
import grp.pt.autotask.model.AutoTaskVO;

public class ${TASK_CLASS_NAME}Job extends SysAutoTaskBO {

    @Override
    public boolean execute(AutoTaskVO taskVO) throws Exception {
        try {
            logger.info("${TASK_NAME} 开始执行...");
            // TODO: 实现具体业务逻辑
            logger.info("${TASK_NAME} 执行完成");
            return true;
        } catch (Exception e) {
            logger.error("${TASK_NAME} 执行失败", e);
            return false;
        }
    }
}
```

#### 3.x版本Job模板

```java
package ${PACKAGE_NAME}.job;

import grp.pt.autotask.bs.SysAutoTaskBO;
import grp.pt.autotask.model.AutoTaskVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * ${TASK_NAME} - ${TASK_DESCRIPTION}
 * 自动任务实现类
 */
@Slf4j
@Component
public class ${TASK_CLASS_NAME}Job extends SysAutoTaskBO {

    @Override
    public boolean execute(AutoTaskVO taskVO) throws Exception {
        try {
            log.info("${TASK_NAME} 开始执行...");
            // TODO: 实现具体业务逻辑
            log.info("${TASK_NAME} 执行完成");
            return true;
        } catch (Exception e) {
            log.error("${TASK_NAME} 执行失败", e);
            return false;
        }
    }
}
```

## 5. SQL生成规范

### 5.1 GAP_MODULE INSERT模板

```sql
-- Module配置
INSERT INTO GAP_MODULE (
    ID, CODE, NAME, CLASS_NAME, DLL_PATH, PARENT_ID,
    REMARK, SYSTEM_ID, CREATE_DATE, LAST_VER,
    IS_ACCOUNT, PARA_CONFIG_CLASS, BACKLOG_CLASS_NAME, REF_JS
) VALUES (
    ${ID}, '${CODE}', '${NAME}', '${CLASS_NAME}', '${DLL_PATH}', ${PARENT_ID},
    '${REMARK}', ${SYSTEM_ID}, SYSDATE, 0,
    ${IS_ACCOUNT}, '${PARA_CONFIG_CLASS}', '${BACKLOG_CLASS_NAME}', '${REF_JS}'
);

COMMIT;
```

### 5.2 GAP_MENU INSERT模板

```sql
-- Menu配置
INSERT INTO GAP_MENU (
    ID, MODULE_ID, MENU_NAME, URL, PARENT_ID,
    ORDER_NUM, ICON, STATUS
) VALUES (
    ${ID}, ${MODULE_ID}, '${MENU_NAME}', '${URL}', ${PARENT_ID},
    ${ORDER_NUM}, '${ICON}', ${STATUS}
);

COMMIT;
```

### 5.3 PB_SYS_BUTTON INSERT模板

```sql
-- Button配置
INSERT INTO PB_SYS_BUTTON (
    JSP_NAME, BUTTON_ID, REMARK, BUTTON_NAME, VISIBLE,
    ICON, CUSTOM, STATUS_CODES, DISP_ORDER,
    ENABLE_ADMDIVS, DISABLE_ADMDIVS
) VALUES (
    '${JSP_NAME}', '${BUTTON_ID}', '${REMARK}', '${BUTTON_NAME}', ${VISIBLE},
    '${ICON}', ${CUSTOM}, '${STATUS_CODES}', ${DISP_ORDER},
    '${ENABLE_ADMDIVS}', '${DISABLE_ADMDIVS}'
);

COMMIT;
```

### 5.4 PB_SYS_STATUS INSERT模板

```sql
-- Status配置
INSERT INTO PB_SYS_STATUS (
    STATUS_ID, JSP_NAME, STATUS_CODE, STATUS_NAME,
    CONDITION, TYPE, MENU_ID
) VALUES (
    '${STATUS_ID}', '${JSP_NAME}', '${STATUS_CODE}', '${STATUS_NAME}',
    '${CONDITION}', ${TYPE}, ${MENU_ID}
);

COMMIT;
```

### 5.5 PB_STATUS_CONDITION INSERT模板

```sql
-- Status Condition配置
INSERT INTO PB_STATUS_CONDITION (
    STATUS_CID, STATUS_ID, OPERATION, ATTR_CODE,
    RELATION, VALUE, ALIAS, DATATYPE
) VALUES (
    '${STATUS_CID}', '${STATUS_ID}', '${OPERATION}', '${ATTR_CODE}',
    '${RELATION}', '${VALUE}', '${ALIAS}', ${DATATYPE}
);

COMMIT;
```

## 6. 工作流程

### 6.1 整体流程

```
用户启动技能
    ↓
系统自动识别项目版本（2.x或3.x）
    ↓
展示版本提示和开发场景选择
    ↓
根据场景进行结构化问答
    ↓
收集关键信息（页面信息、按钮信息、数据库连接等）
    ↓
查询数据库现有配置（获取最大ID等）
    ↓
生成开发产物（SQL脚本、代码文件）
    ↓
输出结果并确认
```

### 6.2 场景一：新增完整页面

**第一步：版本确认**

系统自动识别当前项目版本，并展示相应的开发规范提示。

**第二步：页面基本信息**

用户需要提供页面名称、页面标题、页面模式等信息。页面名称必须与JSP文件名（不含.jsp后缀）保持一致。

**第三步：文件路径确认**

系统根据版本类型展示相应的文件存放位置。2.x版本使用realware目录结构，3.x版本使用模块化目录结构。

**第四步：菜单配置**

用户需要提供菜单位置信息，包括父级菜单名称、菜单显示名称等。

**第五步：按钮配置**

用户需要提供按钮列表信息，包括每个按钮的ID、名称、图标、显示顺序、状态关联等。

**第六步：状态配置**

用户需要提供页面状态列表，包括每个状态的编码、名称、判断条件等。

**第七步：Java代码生成**

系统根据版本类型生成对应的Controller和Service代码。2.x版本生成XML配置和继承基类的代码，3.x版本生成注解配置的代码。

### 6.3 场景二：新增初始化JS按钮

**第一步：目标页面确认**

用户需要提供目标页面的名称和所在的模块。

**第二步：按钮信息收集**

用户需要提供新按钮的详细信息。

**第三步：JavaScript方法生成**

系统生成符合版本规范的初始化JavaScript方法代码。

### 6.4 场景三：新增个性化JS按钮

**第一步：目标页面确认**

用户需要提供目标页面的名称。系统确认页面使用的JavaScript文件路径。

**第二步：个性化文件确认**

系统展示个性化文件的目标位置，提示用户确认或创建文件。

**第三步：按钮信息收集**

用户需要提供新按钮的详细信息。

**第四步：SQL脚本生成**

系统生成PB_SYS_BUTTON表的INSERT语句。

**第五步：JavaScript代码生成**

系统生成个性化JavaScript的方法代码。

### 6.5 场景四：新增自动任务

**第一步：任务基本信息**

用户需要提供任务名称、任务描述、Cron表达式等信息。

**第二步：任务实现类信息**

用户需要提供Java实现类的包名、类名等信息。系统根据版本类型生成对应的Job代码模板。

**第三步：SQL脚本生成**

系统生成PB_SYS_AUTO_TASK表的INSERT语句，以及完整的Java实现类代码。

## 7. 命名规范

### 7.1 页面命名规范

页面名称采用PascalCase命名规范，即首字母大写，每个单词的首字母大写。例如：UnityRefundZero、PATransferVoucherForm等。

页面名称应简洁明了，能够准确表达页面的功能。避免使用过长的名称，通常控制在三到五个单词内。

### 7.2 模块目录命名规范

模块目录采用{模块标识}_js的命名格式。具体的模块标识需要根据实际项目确定，例如：RCU_js、RCC_js等。

### 7.3 文件存放位置规范

| 版本 | 文件类型 | 存放位置 |
|------|----------|----------|
| 2.x | JSP页面 | `{项目}/realware/WEB-INF/views/` |
| 2.x | 定制JS | `{项目}/realware/{定制标识}_js/` |
| 3.x | JSP页面 | `{模块}/src/main/webapp/WEB-INF/views/` |
| 3.x | 个性化JSP | `{模块}/src/main/webapp/WEB-INF/viewscustom/` |
| 3.x | 定制JS | `{模块}/src/main/resources/static/{模块标识}_js/` |

### 7.4 按钮命名规范

按钮ID采用camelCase命名规范，即首字母小写，后续单词的首字母大写。例如：inputCustom、sendVoucher等。

按钮名称采用中文命名规范，直接描述按钮的功能。

### 7.5 状态编码规范

状态编码采用三位数字，从000开始递增。000通常表示初始状态或查询状态，001及之后的编码表示业务处理状态。

## 8. 使用方法

### 8.1 启动技能

在对话中直接输入以下命令启动技能：

```
/pbdev
```

或者使用自然语言描述需求：

```
帮我开发一个集中支付系统的零余额退款页面
```

### 8.2 交互示例

**第一步：选择开发场景**

```
欢迎使用国库集中支付系统开发辅助工具！

已自动识别当前项目版本为：${VERSION}（${VERSION_MODE}）

请选择开发场景：
A. 新增页面（需要全套配置）
B. 已有页面新增初始化JavaScript按钮
C. 已有页面新增个性化JavaScript按钮
D. 新增自动任务Job
E. 其他定制开发

请输入选项（A/B/C/D/E）：
```

**后续步骤根据选择的场景和版本类型进行相应的引导。**

## 9. 最佳实践

### 9.1 版本兼容性考虑

如果项目需要同时支持多个版本，应注意代码的兼容性。避免使用特定版本的特有API，确保代码可以在目标版本中正常运行。

### 9.2 配置管理建议

**保持命名一致性**

页面名称、按钮ID、状态编码等都应遵循统一的命名规范，便于后续维护和查找。

**合理规划状态和按钮**

每个状态应有明确的业务含义，按钮在不同状态下的可用性应符合业务逻辑。

**及时备份和版本控制**

所有生成的SQL脚本和代码文件都应纳入版本控制，便于问题追溯和版本回滚。

### 9.3 代码组织建议

**遵循模块化开发**

3.x版本的项目按模块组织，不同银行的定制代码放在不同的目录下。开发时应遵循模块化原则，将相关代码放在对应的目录下。

**合理使用注解**

3.x版本的配置全面使用注解方式。开发时应合理使用注解，遵循Spring Boot的最佳实践。

## 10. 注意事项

### 10.1 版本差异注意事项

**文件路径差异**

不同版本的个性化JSP和JavaScript文件存放位置不同。开发时应特别注意文件路径的正确性。

**配置方式差异**

3.x版本不再使用XML配置，所有Bean配置都使用注解方式。如果需要自定义配置，应创建@Configuration注解的配置类。

### 10.2 常见问题处理

**ID冲突问题**

如果在执行SQL时遇到唯一约束冲突，说明生成的ID与数据库中已有记录重复。解决方法是在执行前重新查询表的最大ID。

**按钮不显示问题**

如果按钮在页面上不显示，可能的原因包括：VISIBLE字段设置错误、BUTTON_ID与方法名不匹配、STATUS_CODES配置错误等。

**JavaScript不加载问题**

如果个性化JavaScript文件没有被加载，可能的原因包括：REF_JS配置路径不正确、JavaScript文件不存在、JavaScript文件语法错误等。

**Controller注入失败（3.x版本）**

检查@Service注解是否正确添加，确保被注入的类已经纳入Spring容器管理。

## 11. 参考资料

### 11.1 模板变量说明

在代码模板中，使用以下变量占位符，实际生成时需要替换为具体的值：

| 变量 | 说明 | 示例 |
|------|------|------|
| ${PAGE_TITLE} | 页面显示标题 | 零余额到账 |
| ${JS_FILE_NAME} | JavaScript文件名 | UnityRefundZero |
| ${ENTITY_NAME} | 实体名称 | PayVoucher |
| ${CONTROLLERS} | ExtJS控制器列表 | 'pay.PayVouchers' |
| ${VIEW_XTYPE} | 视图组件类型 | printVoucherList |
| ${PACKAGE_NAME} | Java包名 | grp.pb.branch.rcc |
| ${MODULE_NAME} | 模块名称 | rcc |
| ${MODULE_JS} | 模块JS目录 | RCU_js |
| ${CONTROLLER_NAME} | 控制器类名 | PayVoucher |
| ${SERVICE_INTERFACE} | 服务接口名 | IPayVoucherService |
| ${SERVICE_VARIABLE} | 服务变量名 | payVoucherService |
| ${BUTTON_ID} | 按钮ID | inputCustom |
| ${BUTTON_NAME} | 按钮名称 | 自定义录入 |
| ${FUNCTION_IMPL} | 函数实现 | Ext.widget(...) |
| ${JSP_NAME} | JSP文件名 | PayVoucherForm |
| ${VERSION} | 产品化版本 | 2.1.1或3.4.9 |
| ${VERSION_MODE} | 版本模式 | 传统Java Web或Spring Boot |

### 11.2 文档说明

本技能文档适用于国库集中支付系统的多个版本开发。具体的项目名称、省份名称、银行标识等需要根据实际项目进行调整。文档中所有使用{占位符}格式的内容都需要在实际使用时替换为具体的值。

---

**版本信息**

技能版本：3.0.0（多版本支持）

创建日期：2024年

适用版本：国库集中支付系统2.x、3.x版本

维护者：zhangchengke
