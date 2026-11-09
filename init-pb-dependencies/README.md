# init-pb-dependencies

PB 产品化依赖 ↔ 源码映射初始化助手：解析 pom 依赖版本，定位源码仓库对应版本目录，写入项目 CLAUDE.md（及 AGENTS.md），替代 source_code_lib 软链方式。

## 功能

- 解析根 pom 与各模块 pom 的产品化依赖（`com.ctjsoft` 系），处理 `${}` 属性继承与传递依赖
- 在源码仓库（默认 `/Users/zhangchengke/Documents/ZKJN/code/svn/source`）中逐字符定位对应版本的源码目录
- 生成幂等的「产品化依赖 ↔ 源码仓库映射」标记区块，写入项目 CLAUDE.md 并同步 AGENTS.md
- 标注「有依赖无源码」的构件，列出仓库可用版本，不编造路径

## 使用

在 PB 项目根目录说：**「init-pb-dependencies」**、**「初始化产品化依赖映射」**或**「刷新源码映射」**

## 前置

- 项目根有 `pom.xml` 且依赖 `com.ctjsoft` 系构件
- 产品化源码仓库存在（默认路径见上，可在会话中指定其他位置）

## 文件

- [SKILL.md](SKILL.md) — 完整工作流
