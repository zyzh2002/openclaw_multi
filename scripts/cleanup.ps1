#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "=== OpenClaw Workspace Cleanup ==="
Write-Host ""

1..4 | ForEach-Object {
    $dir = "instances/instance-$_/workspace"
    if (Test-Path -LiteralPath $dir) {
        Get-ChildItem -LiteralPath $dir -Exclude ".gitkeep" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "[OK] instance-$_ workspace 已清除"
    } else {
        Write-Host "[..] instance-$_ workspace 不存在，跳过"
    }
}

Write-Host ""
Write-Host "=== 清除完成 ==="
