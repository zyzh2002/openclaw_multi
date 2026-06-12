#!/usr/bin/env bash
set -euo pipefail

echo "=== OpenClaw Workspace Cleanup ==="
echo ""

for i in 1 2 3 4; do
  dir="instances/instance-${i}/workspace"
  if [[ -d "$dir" ]]; then
    find "$dir" -mindepth 1 ! -name '.gitkeep' -exec rm -rf {} + 2>/dev/null || true
    echo "[OK] instance-${i} workspace 已清除"
  else
    echo "[..] instance-${i} workspace 不存在，跳过"
  fi
done

echo ""
echo "=== 清除完成 ==="
