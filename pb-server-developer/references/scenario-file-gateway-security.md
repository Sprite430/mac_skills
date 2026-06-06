# 场景：上传下载 / 网关白名单 / 文件安全

## 目录

- 目标
- 适用范围
- 版本差异
- 必查项
- 3.x 检查清单
- 2.x 检查清单
- 文件安全规则
- 验证方式

## 目标

处理上传、下载、导入、导出、临时文件访问、外部回调免登录、网关或安全拦截白名单相关开发，避免接口不可访问或文件安全问题。

## 适用范围

- 新增或修改 `importXXX.do`、`uploadXXX.do`、`downloadXXX.do`、`downLoad.do`、`exportXXX.do`。
- 文件导入导出、银行/财政文件传输、FTP/SFTP、本地临时目录。
- 需要免登录、外部系统回调、网关转发或拦截器排除的接口。

## 版本差异

- 3.x 项目常见独立 `gateway` 模块、`pb.ignore-urls`、`file-interceptor.download.urls`、`file-interceptor.upload.urls`、`authority-interceptor.urls`。
- 2.x 产品化基线通常没有独立 gateway 模块，也没有 3.x 的 `file-interceptor` yml 白名单；常见拦截配置在 `src/springmvc-servlet.xml`，包括 `MyInterceptor`、`AuthorityInterceptor`、`SecurityInterceptor`。
- 因此：只有目标项目实际存在 `gateway` 或 `file-interceptor` 配置时才维护这些白名单；2.x 不要硬套 3.x 配置。

## 必查项

1. 确认接口是否需要登录、是否外部系统调用、是否可经网关访问。
2. 找同项目已有上传/下载接口，模仿参数名、返回结构、异常处理和文件名编码。
3. 检查文件路径、文件类型、文件大小、临时目录、清理策略。
4. 涉及 Controller/Service 修改时，按项目 GitNexus 规则先做 impact。
5. 编码前检查 SVN/Git 状态，避免覆盖已有个性化配置。

常用搜索：

```bash
rg -n "file-interceptor|ignore-urls|authority-interceptor|SecurityInterceptor|AuthorityInterceptor|FileDownloadInterceptor|FileUploadInterceptor" .
rg -n "downLoad.do|downloadFile.do|import.*do|upload.*do|export.*do|MultipartFile|FileOutputStream|SFTP|FTP" .
```

## 3.x 检查清单

- `pb/src/main/resources/application.yml` 是否需要维护：
  - `file-interceptor.download.urls`
  - `file-interceptor.download.file-types`
  - `file-interceptor.download.file-paths`
  - `file-interceptor.upload.urls`
  - `file-interceptor.upload.file-types`
  - `authority-interceptor.urls`
- `gateway/src/main/resources/application.yml` 是否需要维护 `pb.ignore-urls`。
- `WebConfig` 中对应拦截器是否会拦截该 URL。
- 如果接口不应免登录，不要为了调通页面把它加入 ignore/authority 白名单。

## 2.x 检查清单

- 检查 `src/springmvc-servlet.xml` 中的 `MyInterceptor`、`Logincheck`、`AuthorityInterceptor`、`SecurityInterceptor`。
- 检查 2.x 是否已有同类 Controller，例如 `BaseController.downLoad.do`、`CheckVoucherController.downloadFile.do` 或各类 `importXXX.do`。
- 如果没有 gateway/file-interceptor 配置，不要新增 3.x 风格 yml 白名单。
- 需要放开拦截时，优先模仿 2.x 项目已有排除或校验机制；不明确时先给方案并询问用户。

## 文件安全规则

- 禁止直接信任用户传入的完整路径；必须限制在允许目录内，并防止 `../`、绝对路径、盘符绕过。
- 上传文件必须校验扩展名、大小和业务允许类型；不能只依赖前端校验。
- 下载文件名要做编码处理，避免中文乱码和响应头注入。
- 临时文件要有清理策略；异常时关闭流。
- 日志不要打印敏感文件内容、密码、token、完整报文或过长 Base64。

## 验证方式

- 正常文件、非法扩展名、越权路径、空文件/超大文件分别验证。
- 经网关访问和直连 pb 访问都要按实际部署方式确认。
- 免登录接口要验证未登录、已登录、无权限三种情况。
- 说明需要用户在目标环境核对的 yml、XML 或数据库配置。
