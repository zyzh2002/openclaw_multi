#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "=== OpenClaw Multi-Instance Init ==="

# Check Docker Desktop
$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
    Write-Error "错误: 未安装 Docker Desktop"
    Write-Host "请从 https://www.docker.com/get-started 下载安装 Docker Desktop"
    exit 1
}

# Check if Docker is running
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Error "错误: Docker Desktop 未运行，请先启动 Docker Desktop"
    exit 1
}

if (-not (docker compose version 2>&1)) {
    Write-Error "错误: 未安装 Docker Compose"
    exit 1
}

Write-Host "[OK] Docker 环境就绪"

# Create directories
1..4 | ForEach-Object {
    New-Item -ItemType Directory -Force -Path "instances/instance-$_/workspace" | Out-Null
}
Write-Host "[OK] 目录结构已创建"

# Copy .env from example
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "[OK] .env 已从 .env.example 复制"
} else {
    Write-Host "[..] .env 已存在，跳过"
}

Write-Host ""
Write-Host "=== 初始化完成 ==="
Write-Host ""
Write-Host "下一步:"
Write-Host "  1. 编辑 .env                  — 确认 OPENCLAW_GATEWAY_TOKEN 并填入代理地址（如需要）"
Write-Host "  2. 编辑 instances\instance-*\openclaw.json — 填入 API Key 和模型"
Write-Host ""
Write-Host "启动:  docker compose up -d"
Write-Host ""
Write-Host "Web 面板 (Token 默认: openclaw123):"
Write-Host "  http://localhost:18789  (instance-1)"
Write-Host "  http://localhost:18790  (instance-2)"
Write-Host "  http://localhost:18791  (instance-3)"
Write-Host "  http://localhost:18792  (instance-4)"
