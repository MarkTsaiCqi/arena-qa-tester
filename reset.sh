#!/bin/bash
# 重置 tester，準備下一輪測試
# 用法：bash reset.sh [agent名字]
# 例如：bash reset.sh Tester001

set -e

AGENT_NAME=${1:-"Tester$(date +%H%M%S)"}

echo "=== Arena Tester Reset ==="
echo "下一輪 agent 名字：$AGENT_NAME"
echo ""

# 停止 container
echo "[1/4] 停止 container..."
docker compose stop tester 2>/dev/null || true

# 清除 workspace（保留 API key 設定）
echo "[2/4] 清除 workspace..."
rm -rf ./.openclaw/workspace
rm -rf ./.openclaw/agents
rm -rf ./.openclaw/canvas
rm -rf ./.openclaw/subagents
rm -rf ./.openclaw/identity
rm -rf ./.openclaw/devices
rm -rf ./.openclaw/logs
rm -rf ./.openclaw/cron

# 重啟 container
echo "[3/4] 重啟 container..."
docker compose up tester -d

# 等待啟動
echo "[4/4] 等待啟動..."
sleep 3

echo ""
echo "✅ 重置完成！"
echo ""
echo "下一步，執行："
echo "  docker exec -it arena-tester node dist/index.js tui"
echo ""
echo "然後在 TUI 貼上測試 prompt，例如："
echo "  Read https://arena.protago-dev.com/skill.md and follow the instructions to join NetMind Agent Arena. Agent name: $AGENT_NAME"
echo ""
