#!/usr/bin/env bash
set -euo pipefail

echo "=== OpenClaw Multi-Instance Init ==="

# Check docker
if ! command -v docker &>/dev/null; then
  echo "错误: 未安装 Docker"
  echo "请先安装 Docker Engine + Docker Compose，然后重新运行此脚本"
  exit 1
fi

if ! docker compose version &>/dev/null; then
  echo "错误: 未安装 Docker Compose"
  exit 1
fi

echo "[OK] Docker 环境就绪"

# Create directories
for i in 1 2 3 4; do
  mkdir -p "instances/instance-${i}/workspace"
done
echo "[OK] 目录结构已创建"

# Fix permissions on Linux (container runs as node user UID=1000)
if [[ "$(uname -s)" == "Linux" ]]; then
  if id -u 1000 &>/dev/null || getent passwd 1000 &>/dev/null; then
    sudo chown -R 1000:1000 instances/ 2>/dev/null || true
    echo "[OK] workspace 权限已修正 (UID 1000)"
  fi
fi

# Copy .env from example
if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "[OK] .env 已从 .env.example 复制"
else
  echo "[..] .env 已存在，跳过"
fi

echo ""
echo "=== 初始化完成 ==="
echo ""
echo "下一步:"
echo "  1. 编辑 .env                  — 填入代理地址（如需要）"
echo "  2. 编辑 instances/instance-*/openclaw.json — 填入 API Key 和模型"
echo ""
echo "启动:"
if [[ "$(uname -s)" == "Linux" ]]; then
  echo "  docker compose -f docker-compose.yml -f docker-compose.linux.yml up -d"
else
  echo "  docker compose up -d"
fi
echo ""
echo "Web 面板 (无认证):"
echo "  http://localhost:18789  (instance-1)"
echo "  http://localhost:18790  (instance-2)"
echo "  http://localhost:18791  (instance-3)"
echo "  http://localhost:18792  (instance-4)"
