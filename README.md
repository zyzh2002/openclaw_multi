# OpenClaw Multi-Instance Docker Deployment

基于 Docker 的 OpenClaw 多实例隔离部署方案，为每个实例提供独立的配置、工作空间和网络隔离，仅暴露 Web 控制面板和本地挂载的读写文件夹。

## 前置要求

- **Windows**: [Docker Desktop](https://www.docker.com/get-started) (含 Docker Compose)
- **Linux**: Docker Engine 26+ + Docker Compose v2
- 至少 4GB 可用内存（4 实例 × 512MB）

## 快速开始

### 1. 克隆仓库

```bash
git clone <repo-url> && cd openclaw_multi
```

### 2. 运行初始化脚本

**Windows (PowerShell):**

```powershell
.\scripts\init.ps1
```

**Linux / macOS:**

```bash
bash scripts/init.sh
```

### 3. 配置

编辑 `.env` 填入代理地址（如需要）：

```env
HTTP_PROXY_URL=http://host.docker.internal:7890
ALL_PROXY_URL=socks5://host.docker.internal:1080
```

编辑各实例的模型配置：

```
instances/instance-{1..4}/openclaw.json
```

填入你的 API Key 和模型选择。

### 4. 启动

**Windows / macOS:**

```bash
docker compose up -d
```

**Linux (含沙箱模式):**

```bash
docker compose -f docker-compose.yml -f docker-compose.linux.yml up -d
```

### 5. 访问 Web 面板

统一 Token：`openclaw123`

| 实例 | 地址 |
|------|------|
| instance-1 | http://localhost:18789 |
| instance-2 | http://localhost:18790 |
| instance-3 | http://localhost:18791 |
| instance-4 | http://localhost:18792 |

## 目录结构

```
openclaw_multi/
├── .env.example              # 环境变量模板（复制为 .env）
├── docker-compose.yml        # 基础编排（跨平台通用）
├── docker-compose.linux.yml  # Linux 补充：Docker socket 挂载
├── shared-skills/            # 共享技能目录（Git 追踪，所有实例共用）
├── scripts/
│   ├── init.sh               # Linux/macOS 初始化
│   ├── init.ps1              # Windows 初始化
│   ├── cleanup.sh            # Linux/macOS 清除工作区
│   └── cleanup.ps1           # Windows 清除工作区
├── instances/
│   ├── instance-1/
│   │   ├── openclaw.json     # 实例 1 独立配置
│   │   └── workspace/        # 实例 1 工作空间（读写）
│   ├── instance-2/
│   ├── instance-3/
│   └── instance-4/
└── README.md
```

### Skills 管理

所有实例共享同一套 Skills，存放在仓库根目录的 `shared-skills/` 中：

```
shared-skills/
├── .gitkeep
└── <your-skill>/
    └── SKILL.md
```

容器以只读方式挂载，宿主机上编辑后自动生效（`watch: true`）。Skills 纳入 Git 版本管理。

## 配置说明

### openclaw.json

每个实例的配置文件位于 `instances/instance-{1..4}/openclaw.json`（JSON5 格式，支持注释和尾随逗号）。

最小可运行配置示例：

```json5
{
  "gateway": {
    "port": 18789,
    "bind": "0.0.0.0",
    "auth": {}  // 空对象 = 禁用 Web 面板认证
  },
  "agents": {
    "defaults": {
      "workspace": "/home/node/.openclaw/workspace",
      "model": {
        "primary": "openai/gpt-4o",
        "fallbacks": ["anthropic/claude-sonnet-4"]
      }
    }
  },
  "auth": {
    "profiles": {
      "openai:default": {
        "provider": "openai",
        "mode": "api_key"
      }
    }
  },
  "models": {
    "mode": "merge",
    "providers": {
      "openai": {
        "baseUrl": "https://api.openai.com/v1",
        "api": "openai-chat",
        "apiKey": "sk-your-key-here",
        "authHeader": true,
        "models": [
          {
            "id": "gpt-4o",
            "name": "GPT-4o",
            "input": ["text", "image"],
            "contextWindow": 128000,
            "maxTokens": 16384
          }
        ]
      }
    }
  }
}
```

### 代理配置

所有实例统一使用宿主机代理，在 `.env` 中配置：

```env
# HTTP/HTTPS 代理
HTTP_PROXY_URL=http://host.docker.internal:7890
HTTPS_PROXY_URL=http://host.docker.internal:7890

# SOCKS5 代理
ALL_PROXY_URL=socks5://host.docker.internal:1080
```

Linux 用户注意：代理需监听 `0.0.0.0` 而非 `127.0.0.1`，否则容器无法访问。

### 沙箱模式

默认启用 (`OPENCLAW_SANDBOX=1`)。Agent 的所有 Shell/文件操作在独立子容器中执行，工作区限定在 `/workspace`，网络默认隔离。

如需禁用：

```env
OPENCLAW_SANDBOX=0
```

## 常用命令

```bash
# 启动所有实例
docker compose up -d

# 查看日志
docker compose logs -f openclaw-1

# 重启单个实例
docker compose restart openclaw-2

# 停止所有实例
docker compose down

# Linux 沙箱模式
docker compose -f docker-compose.yml -f docker-compose.linux.yml up -d
```

### 一键清除工作区

清除所有实例 workspace 中的运行时数据（保留 `.gitkeep`）：

```bash
# Windows
.\scripts\cleanup.ps1

# Linux / macOS
bash scripts/cleanup.sh
```

建议在 `docker compose down` 后执行。

## 隔离维度

| 维度 | 实现方式 |
|------|---------|
| 文件系统 | 每实例独立 volume，workspace 互不可见 |
| 网络 | Docker bridge 网络，仅暴露 Web 端口 |
| 工具执行 | Agent 沙箱子容器 (`OPENCLAW_SANDBOX=1`) |
| 配置 | 独立 `openclaw.json`，模型/Key 完全分离 |
| 资源 | CPU/内存限制 (`cpus: 1.0, memory: 512M, reservations: 256M`) |

## 许可证

MIT
