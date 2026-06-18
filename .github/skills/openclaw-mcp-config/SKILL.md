---
name: openclaw-mcp-config
description: "为 4 个 OpenClaw 实例统一写入 MCP 服务器配置。Use when 用户要求\"添加 MCP 服务器\"、\"配置 MCP\"、\"给 OpenClaw 加 MCP\"、\"为所有实例配置 MCP\"、\"统一 MCP 配置\"，或粘贴了一段 MCP 服务器 JSON 代码块希望应用到 openclaw_multi 项目。Agent 会解析用户提供的 JSON、检测敏感值、并将服务器定义合并写入 instances/instance-{1..4}/openclaw.json 的 mcp.servers 节，保留已有配置不覆盖。NOT for：单实例独立配置（直接编辑该实例的 openclaw.json 即可）；OpenClaw 自身升级或镜像构建。"
---

# OpenClaw MCP 配置统一管理

为 `openclaw_multi` 项目的 4 个实例统一写入 MCP（Model Context Protocol）服务器配置。

## 项目上下文

本项目部署 4 个 OpenClaw 容器实例，配置文件分别位于：

```
instances/instance-1/openclaw.json    # 端口 18789
instances/instance-2/openclaw.json    # 端口 18790
instances/instance-3/openclaw.json    # 端口 18791
instances/instance-4/openclaw.json    # 端口 18792
```

每个实例的容器内工作空间路径统一为：`/home/node/.openclaw/workspace`

## 工作流

### 步骤 1：接收用户输入

要求用户粘贴**描述 MCP 服务器的 JSON 代码块**。支持以下三种格式：

**格式 A — 完整 servers 映射（推荐，可一次添加多个）：**
```json5
{
  "servers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/home/node/.openclaw/workspace"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}" }
    }
  }
}
```

**格式 B — 单个具名服务器：**
```json5
{
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/home/node/.openclaw/workspace"]
  }
}
```

**格式 C — 单个匿名服务器对象（必须追问名称）：**
```json5
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-filesystem", "/home/node/.openclaw/workspace"]
}
```

如果用户没有粘贴 JSON，**主动提示**他们粘贴，并给出格式 A 的示例作为参考。

### 步骤 2：解析与验证

1. 用 JSON5 容错方式解析（允许注释和尾部逗号）。如解析失败，向用户报告具体行号和错误。
2. 自动判断输入格式：
   - 含 `servers` 顶层键 → 格式 A
   - 顶层值是对象且每个对象都含 `command` 或 `url` → 格式 B
   - 顶层直接含 `command`/`url` → 格式 C，**追问用户该服务器的名称**
3. 对每个服务器条目执行 schema 验证（见下方 Schema 速查表）。

### 步骤 3：敏感值检测

扫描 `headers`、`env`、`url` 中是否含有疑似敏感字面量：
- 匹配模式：`Bearer\s+[A-Za-z0-9_-]{20,}`、`sk-[A-Za-z0-9]{20,}`、`ghp_[A-Za-z0-9]{30,}`、`xoxb-`、长度 ≥ 32 的连续字母数字串
- 字段名包含 `token`、`key`、`secret`、`password`、`auth` 时，值不应为字面量
- **若发现**：暂停写入，告知用户发现的位置，建议改用 `${VAR_NAME}` 语法，并将变量加入项目根目录 `.env`（参考 `.env.example`）。提供修改后的 JSON 让用户确认。

### 步骤 4：合并到 4 个实例

1. 并行读取 `instances/instance-1/openclaw.json` ~ `instance-4/openclaw.json`
2. 对每个文件：
   - 若不存在 `mcp` 节：新增 `"mcp": { "servers": { ... } }`
   - 若存在 `mcp.servers`：**合并**新条目，**保留已有条目**，同名条目以新值覆盖（先告知用户）
   - 若存在 `mcp` 但无 `servers`：在 `mcp` 下新增 `servers` 子对象
3. 使用 `replace_string_in_file` 工具写入，保持原文件的缩进风格（2 空格）和键顺序。
4. 写入位置：放在 `gateway` 之后、`skills` 之前，与现有结构一致。

### 步骤 5：验证

1. 写入后立即用 `get_errors` 检查 4 个文件是否有 JSON 语法错误
2. 用 `grep_search` 搜索 4 个文件中的 `mcp.servers` 条目，确认 4 份配置完全一致
3. 报告写入摘要：服务器名、传输类型、所在文件路径

### 步骤 6：提示用户后续操作

输出以下后续步骤（**不要自动执行**）：

```
✅ MCP 配置已写入 4 个实例。

下一步:
  1. 如使用 ${ENV} 变量，编辑 .env 文件填入真实值
  2. 重启容器使配置生效:
     docker compose restart
  3. 验证 MCP 服务器加载:
     docker compose exec openclaw-1 openclaw mcp list
     docker compose exec openclaw-1 openclaw mcp doctor --probe
```

## OpenClaw MCP Schema 速查

### Stdio 传输（本地子进程）

```json5
{
  "command": "npx",                    // 必填，可执行文件
  "args": ["-y", "package-name"],      // 可选，命令行参数
  "env": { "API_KEY": "${MY_KEY}" },   // 可选，环境变量
  "cwd": "/path/to/workdir",           // 可选，工作目录
  "enabled": true,                     // 可选，默认 true
  "toolFilter": {                      // 可选
    "include": ["read_*"],
    "exclude": ["admin_*"]
  }
}
```

**Stdio 环境变量黑名单**：以下变量在 `env` 中会被 OpenClaw 拒绝（防止注入）：`NODE_OPTIONS`、`PYTHONSTARTUP`、`PYTHONPATH`、`PERL5OPT`、`RUBYOPT`、`BASHOPTS`、`SHELLOPTS`、`FPATH`、`KSH_ENV`、`PS4`、`TCLLIBPATH`。如需设置，让用户在 `docker-compose.yml` 的 `environment` 中配置。

### Streamable HTTP 传输

```json5
{
  "url": "https://mcp.example.com/mcp",        // 必填
  "transport": "streamable-http",              // 必填：streamable-http | sse
  "timeout": 20,                               // 可选，秒
  "connectTimeout": 5,                         // 可选，秒
  "headers": {
    "Authorization": "Bearer ${MCP_TOKEN}"     // 敏感值用 ${ENV}
  },
  "auth": "oauth",                             // 可选，OAuth 服务器
  "sslVerify": true,                           // 可选，默认 true
  "supportsParallelToolCalls": true            // 可选
}
```

### 字段约束

- 服务器名称：仅允许 `[a-zA-Z0-9_-]`，不含空格
- `transport` 仅接受 `"streamable-http"` 或 `"sse"`
- `command` 必须能在容器 `PATH` 中解析（`npx`/`node`/`python` 默认可用，`uvx` 取决于镜像）
- 敏感值必须使用 `${VAR_NAME}` 形式（仅匹配 `[A-Z_][A-Z0-9_]*`），变量在 `.env` 中提供

## 环境变量替换规则

OpenClaw 加载配置时会将 `${VAR_NAME}` 替换为环境变量值。在本项目中：

1. 变量需在项目根 `.env` 中定义（`docker-compose.yml` 已通过 `environment:` 段传递给容器）
2. 如需新增变量，**同时更新 `.env.example`** 让团队知晓
3. 转义字面量 `${VAR}`：写成 `$${VAR}`

## 容器内运行时

OpenClaw 官方镜像 `ghcr.io/openclaw/openclaw:latest` 内置：
- ✅ Node.js（`npx` 可用）
- ⚠️ Python/`uvx` — 取决于镜像版本，使用前提醒用户验证
- ❌ 其他语言运行时 — 需自行构建定制镜像

## 常见 MCP 服务器示例（仅供参考，不主动写入）

| 名称 | 配置片段 |
|------|---------|
| `filesystem` | `{"command": "npx", "args": ["-y", "@modelcontextprotocol/server-filesystem", "/home/node/.openclaw/workspace"]}` |
| `github` | `{"command": "npx", "args": ["-y", "@modelcontextprotocol/server-github"], "env": {"GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"}}` |
| `memory` | `{"command": "npx", "args": ["-y", "@modelcontextprotocol/server-memory"]}` |
| `fetch` | `{"command": "npx", "args": ["-y", "@modelcontextprotocol/server-fetch"]}` |

## 边界情况

| 情况 | 处理 |
|------|------|
| 用户粘贴的 JSON 含敏感字面量 | 暂停，提示改用 `${ENV}`，等待修订后的 JSON |
| 4 个实例已有同名 MCP 服务器 | 显示当前值与新值差异，等待用户确认覆盖 |
| 用户只想给某个实例加（不是全部） | 不使用本 Skill，引导用户直接编辑该实例的 `openclaw.json` |
| 用户想删除某个 MCP 服务器 | 本 Skill 仅负责添加；删除请用户直接编辑文件或单独要求 |
| 解析失败 | 输出错误位置，请求用户修正 JSON |
| 写入后某个文件 JSON 校验失败 | 立即回滚（用 `replace_string_in_file` 还原），报告问题 |

## 反例（不要做）

- ❌ 不要修改 `docker-compose.yml`（MCP 配置不需要 volume 挂载）
- ❌ 不要使用 `$include` 共享文件机制（用户已选择直接嵌入方案）
- ❌ 不要主动执行 `docker compose restart`（让用户决定时机）
- ❌ 不要把敏感字面量写入 `openclaw.json`，必须用 `${ENV}`
- ❌ 不要破坏现有 `gateway`、`skills`、`agents`、`models` 节的内容
