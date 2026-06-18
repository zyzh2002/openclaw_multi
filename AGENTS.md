# AGENTS.md

## Project

- **Name:** openclaw_multi
- **Description:** OpenClaw 多实例 Docker 隔离部署方案，4 个独立实例共享宿主机代理，Web 面板使用统一 Token 认证。

## Commands

### 初始化

```bash
# Windows
.\scripts\init.ps1

# Linux/macOS
bash scripts/init.sh
```

### 启动

```bash
# Windows / macOS
docker compose up -d

# Linux (沙箱模式需要 docker.sock)
docker compose -f docker-compose.yml -f docker-compose.linux.yml up -d
```

### 查看状态

```bash
docker compose ps
docker compose logs -f openclaw-1
```

### 停止

```bash
docker compose down
```

### 清除工作区

```bash
# Windows
.\scripts\cleanup.ps1

# Linux/macOS
bash scripts/cleanup.sh
```

## Architecture

```text
Host (Windows/Linux)
├── Docker Compose
│   ├── openclaw-net (bridge network)
│   ├── openclaw-1 :18789  → instances/instance-1/
│   ├── openclaw-2 :18790  → instances/instance-2/
│   ├── openclaw-3 :18791  → instances/instance-3/
│   └── openclaw-4 :18792  → instances/instance-4/
└── 宿主机代理 (HTTP/SOCKS5)
    └── 容器通过 host.docker.internal 访问
```

Key directories:

- `instances/instance-{1..4}/openclaw.json` — 各实例独立的 Gateway/Model/Channel 配置
- `instances/instance-{1..4}/workspace/` — 各实例工作空间，Docker volume 挂载为读写
- `scripts/init.sh` / `scripts/init.ps1` — 跨平台初始化脚本
- `scripts/cleanup.sh` / `scripts/cleanup.ps1` — 一键清除工作区脚本
- `docker-compose.linux.yml` — Linux 追加 docker.sock 挂载（沙箱模式需要）

## Conventions

- 实例数量固定为 4，端口连续映射 (18789~18792)
- Web 面板使用统一 Token 认证，Token 由 `.env` 的 `OPENCLAW_GATEWAY_TOKEN` 提供，默认 `openclaw123`
- 代理统一配置在 `.env`，不提交
- `workspace/` 运行时数据被 `.gitignore` 忽略
- `.env` 从 `.env.example` 复制生成，不提交
