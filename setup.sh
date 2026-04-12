#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
#  lark-retro 一键安装脚本
#  https://github.com/gkzzhs/lark-retro
# ─────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { printf "${CYAN}[INFO]${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
fail()  { printf "${RED}[FAIL]${NC}  %s\n" "$*"; exit 1; }

# ── Step 0: 检查 Node.js ────────────────────
info "检查 Node.js 版本..."
if ! command -v node &>/dev/null; then
  fail "未检测到 Node.js，请先安装 Node.js >= 18: https://nodejs.org"
fi

NODE_MAJOR=$(node -e "console.log(process.versions.node.split('.')[0])")
if [ "$NODE_MAJOR" -lt 18 ]; then
  fail "Node.js 版本过低 (v$(node -v))，需要 >= 18"
fi
ok "Node.js v$(node -v | tr -d 'v')"

# ── Step 1: 安装 lark-cli ───────────────────
info "检查 lark-cli..."
if command -v lark-cli &>/dev/null; then
  ok "lark-cli 已安装 ($(lark-cli --version 2>/dev/null || echo 'unknown'))"
else
  info "安装 lark-cli..."
  npm install -g @larksuite/cli
  ok "lark-cli 安装完成"
fi

# ── Step 2: 安装官方 Skills（含 lark-shared）─
info "安装官方 Skills（lark-shared 等基础依赖）..."
npx skills add https://github.com/larksuite/cli -y -g
ok "官方 Skills 安装完成"

# ── Step 3: 安装 lark-retro ──────────────────
info "安装 lark-retro..."
npx skills add https://github.com/gkzzhs/lark-retro -y -g
ok "lark-retro 安装完成"

# ── Step 4: 初始化配置 ──────────────────────
info "初始化 lark-cli 配置..."
if lark-cli config get app_id &>/dev/null 2>&1; then
  ok "lark-cli 配置已存在，跳过初始化"
else
  lark-cli config init --new
  ok "配置初始化完成"
fi

# ── Step 5: 授权登录 ────────────────────────
echo ""
printf "${BOLD}🔐 选择授权级别：${NC}\n"
echo "  1) 基础版  — 日历 + 文档                  (最少权限，可快速体验)"
echo "  2) 增强版  — 日历 + 任务 + 文档            (推荐)"
echo "  3) 高级版  — 增强版 + 多维表格 + 妙记/会议记录/搜索/导出"
echo "  4) 跳过    — 稍后手动授权"
echo ""
read -rp "请选择 [1-4] (默认 2): " choice
choice=${choice:-2}

case "$choice" in
  1)
    info "授权：日历 + 文档..."
    lark-cli auth login --domain calendar,docs
    ;;
  2)
    info "授权：日历 + 任务 + 文档..."
    lark-cli auth login --domain calendar,task,docs
    ;;
  3)
    info "授权：日历 + 任务 + 文档 + 多维表格 + 消息/文档搜索 + 妙记/会议记录 + 文档导出..."
    lark-cli auth login --domain calendar,task,docs,base
    lark-cli auth login --scope "search:message search:docs:read minutes:minute:read vc:record:readonly docs:document.content:read"
    ;;
  4)
    warn "已跳过授权，稍后可手动运行："
    echo "  lark-cli auth login --domain calendar,task,docs"
    echo "  lark-cli auth login --scope \"search:message search:docs:read minutes:minute:read vc:record:readonly docs:document.content:read\""
    ;;
  *)
    warn "无效选项，使用默认增强版授权..."
    lark-cli auth login --domain calendar,task,docs
    ;;
esac

# ── 完成 ────────────────────────────────────
echo ""
echo "────────────────────────────────────────"
printf "${GREEN}${BOLD}✅ lark-retro 安装完成！${NC}\n"
echo "────────────────────────────────────────"
echo ""
echo "现在你可以："
echo "  1. 重启 AI Agent 工具（Trae / Cursor / Claude Code / Codex）"
echo "  2. 输入：帮我做一下上周的回顾"
echo ""
echo "更多用法见：https://github.com/gkzzhs/lark-retro"