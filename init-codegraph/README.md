# init-codegraph

CodeGraph 项目初始化助手，一行命令完成项目代码索引。

## 功能

- 自动检测版本控制类型（Git / SVN）
- 自动检测构建工具（Maven / Gradle）
- 识别软链接指向的外部源码目录（避免索引外部代码）
- 自动生成 `.gitignore` 和 `codegraph.json` 排除规则
- 运行 `codegraph init` 并验证结果

## 使用

在项目根目录说：**「初始化 codegraph」**或**「codegraph init」**

## 前置

```bash
codegraph --version  # 确认已安装 CLI
```

未安装：`npm i -g @colbymchenry/codegraph`

## 文件

- [SKILL.md](SKILL.md) — 完整工作流
