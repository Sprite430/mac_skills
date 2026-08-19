---
name: init-workspace
description: 为当前项目初始化 Workspace Session Sync（工作区会话同步）项目级配置。使用时机：打开一个新项目后，希望该项目的 AI 会话采集/上报生效时调用。调用后本项目才启用采集上报；未调用过本 skill 的项目不采集、不上报、零开销。
---

# init-workspace：接入 Workspace Session Sync（项目级）

## 目标

为**当前项目**添加 Workspace Session Sync 的项目级配置（hooks + 开关），使本项目会话采集/上报生效。**未执行过本 skill 的项目默认不采集、不上报。**

## 前置条件检查

1. 插件已安装：`~/.claude/plugins/local/workspace-session-sync/hooks/workspace_session_sync.py` 存在
2. 全局配置已完成：`~/.workspace-session-sync/config.json` 中 `dataConsent=true`、`api.enabled=true`、凭据已填
3. 全局插件处于禁用状态：`~/.claude/settings.json` 中 `enabledPlugins["workspace-session-sync@ctj-plugins"]` 为 `false`，**或该条目已删除**（等价且更彻底；防止 hooks 双重触发）
   - 若仍为 `true`，先改为 `false`（或删除条目）再继续

条件不满足时报告缺项并停止，不要创建半成品配置。

## 步骤

### 1. 确认项目根目录

用 `git rev-parse --show-toplevel`（git 项目）或 `pwd`（非 git）确定项目根 `PROJECT_ROOT`。

### 2. 配置项目级 hooks（.claude/hooks.json）

目标文件：`PROJECT_ROOT/.claude/hooks.json`

- **文件不存在** → 创建，内容为下方 hooks 模板
- **文件已存在且不含 workspace-session-sync hook** → 合并追加（保留项目原有 hooks，只添加 `UserPromptSubmit` / `PreToolUse` / `PostToolUse` / `Stop` 四类）
- **已含 workspace-session-sync hook** → 跳过，不重复添加

hooks 模板（command 用插件绝对路径，`${CLAUDE_PLUGIN_ROOT}` 在项目级 hooks 中不可用）：

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/Users/zhangchengke/.claude/plugins/local/workspace-session-sync/hooks/workspace-session-sync.sh",
            "statusMessage": "Capturing workspace prompt",
            "timeout": 30
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "apply_patch|Edit|Write|SearchReplace|search_replace|CreateFile|create_file|StrReplace",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/zhangchengke/.claude/plugins/local/workspace-session-sync/hooks/workspace-session-sync.sh",
            "statusMessage": "Capturing workspace baseline",
            "timeout": 30
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "apply_patch|Edit|Write|Read|SearchReplace|search_replace|CreateFile|create_file|StrReplace",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/zhangchengke/.claude/plugins/local/workspace-session-sync/hooks/workspace-session-sync.sh",
            "statusMessage": "Capturing workspace changes",
            "timeout": 30
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/Users/zhangchengke/.claude/plugins/local/workspace-session-sync/hooks/workspace-session-sync.sh",
            "statusMessage": "Syncing workspace session",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

> Windows 机器：command 改为 `workspace-session-sync.cmd` 的绝对路径。

### 3. 配置项目级开关（.claude/workspace-session-sync/config.json）

目标文件：`PROJECT_ROOT/.claude/workspace-session-sync/config.json`

- **不存在** → 创建：
  ```json
  {
    "enabled": true
  }
  ```
- **已存在** → 不修改，尊重用户现有设置（如用户已改为 `false` 表示暂停采集）

### 4. 补充 .gitignore（可选但推荐）

项目 `.gitignore` 不存在以下条目时追加（config.json 保留入库，作为项目启用声明）：

```
.claude/workspace-session-sync/queue/
.claude/workspace-session-sync/locks/
.claude/workspace-session-sync/workitem-sessions/
.claude/workspace-session-sync/file-state/
.claude/workspace-session-sync/before-tool/
.claude/workspace-session-sync/upload.log.jsonl
.claude/workspace-session-sync/debug.log.jsonl
.claude/workspace-session-sync/upload.trace.log.jsonl
```

### 5. 验证

运行：

```bash
python3 ~/.claude/plugins/local/workspace-session-sync/hooks/workspace_session_sync.py --status
```

确认输出中：
- `项目级开关：已开启`
- `采集状态：已启用`
- `下一步：已具备采集与上报条件。`

## 关闭采集（反向操作）

- 临时暂停：改 `config.json` 中 `"enabled": false`
- 彻底退出：删除 `.claude/hooks.json` 中的 workspace-session-sync 四类 hook（或整个 hooks.json）

## 注意事项

- 本 skill 只配置**当前项目**；其他项目未调用本 skill 前保持静默
- 全局插件禁用后，`--status` 的"插件本身：已安装、已启用"仍显示启用（那是插件安装状态），实际以"项目级开关"为准
- 会话内容（提问、文件变更、回复）会在 Stop 后上报公司 DevOps（`https://devops.ctjsoft.com`）；敏感内容请开不带 `#taskID`/`#bugID` 的新会话
