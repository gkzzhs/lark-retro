#!/usr/bin/env bash
# 模拟 lark-retro 工作流的终端演示脚本
# 风格：macOS Terminal.app Pro 主题

set -euo pipefail

# — 颜色（克制、柔和，贴近 macOS Terminal 原生色彩） —
B='\033[1m'
D='\033[2m'
R='\033[0m'
# 标准 ANSI — 在 Pro 主题下自然柔和
GRN='\033[32m'
YLW='\033[33m'
BLU='\033[34m'
CYN='\033[36m'
WHT='\033[37m'

type_out() {
  local text="$1"
  for (( i=0; i<${#text}; i++ )); do
    printf '%s' "${text:$i:1}"
    sleep 0.04
  done
  echo
}

spin() {
  local msg="$1" dur="$2"
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local end=$((SECONDS + dur))
  while [ $SECONDS -lt $end ]; do
    for f in "${frames[@]}"; do
      printf "\r  ${CYN}${f}${R} ${D}${msg}${R}"
      sleep 0.08
    done
  done
  printf "\r  ${GRN}✓${R} ${msg}\n"
}

p() { echo -e "$1"; }

# ─────────────────────────────────────────

echo ""
p "${B}🔄 lark-retro${R} ${D}v2.0.0${R}"
p "${D}───────────────────────────────────────────────────${R}"
echo ""

printf "$ "
type_out "帮我做上周的 Sprint 回顾"
echo ""
sleep 0.4

# ── Step 1 ──
p "${B}Step 1${R}  确定回顾周期"
p "  ${D}W13 · 2026-03-24 ~ 2026-03-30${R}"
echo ""
sleep 0.3

# ── Step 2 ──
p "${B}Step 2${R}  采集日历数据"
p "  ${D}$ lark-cli calendar +agenda --start 2026-03-24 --end 2026-03-30${R}"
spin "获取日历事件" 1
p "  📅 ${B}23${R} 个事件  ${D}│  同步×5  评审×4  1:1×3  外部×2  其他×4  │  会议 42%${R}"
echo ""

# ── Step 3 ──
p "${B}Step 3${R}  采集任务数据"
p "  ${D}$ lark-cli task +get-my-tasks --page-all${R}"
spin "获取任务列表" 1
p "  ✅ ${B}22${R} 个任务  ${D}│  完成 18 (81.8%)  │  按时 15/18  │  Blocker ×2${R}"
echo ""

# ── Step 4 ──
p "${B}Step 4${R}  采集消息数据"
p "  ${D}$ lark-cli im +messages-search --query \"进展|问题|blocker\"${R}"
spin "搜索关键消息" 1
p "  💬 ${B}12${R} 条高质量消息  ${D}│  4 层漏斗过滤噪声${R}"
echo ""

# ── Step 5 ──
p "${B}Step 5${R}  对比历史报告"
p "  ${D}$ lark-cli docs +search --query \"Sprint 回顾 W12\"${R}"
spin "搜索上期报告" 1
p "  📄 找到 W12 报告  ${D}│  会议 47%→42% ↓  完成率 75.8%→81.8% ↑${R}"
echo ""

# ── Step 5c ──
p "${B}Step 5c${R}  行动项闭环"
p "  ${D}$ lark-cli task +complete --task-id <guid>  (×3)${R}"
spin "关闭已完成的行动项" 1
p "  ${GRN}✓${R} 3 个已关闭  ${YLW}↻${R} 1 个添加备注  ${D}│  闭环率 75%${R}"

echo ""
echo ""

# ── Step 6 ──
p "${B}Step 6${R}  AI 生成回顾报告"
spin "分析数据、生成结构化报告" 2

echo ""

# ── 报告预览 ──
p "  ┌────────────────────────────────────────────────┐"
p "  │  ${B}🔄 Sprint 回顾报告 — W13${R}                     │"
p "  ├────────────────────────────────────────────────┤"
p "  │                                                │"
p "  │  ${GRN}🌟 What Went Well${R}                            │"
p "  │  ${D}1. 📈 任务完成率提升 +6%${R}                      │"
p "  │  ${D}2. ⏱️  会议时间缩减 47%→42%${R}                   │"
p "  │  ${D}3. 🤝 跨团队协作效率提升${R}                      │"
p "  │  ${D}4. 📄 新增 4 篇技术文档${R}                       │"
p "  │                                                │"
p "  │  ${YLW}⚠️  What Could Be Improved${R}                   │"
p "  │  ${D}1. 🚧 2 个 Blocker 未解决${R}                     │"
p "  │  ${D}2. 📋 需求评审占比最高 36%${R}                    │"
p "  │  ${D}3. ⏰ 3 个任务延期${R}                            │"
p "  │                                                │"
p "  │  ${BLU}🎯 Action Items${R}                              │"
p "  │  ${D}1. 🔧 联系支付团队升级沙箱     → @王五${R}       │"
p "  │  ${D}2. 📝 PRD 增加边界场景清单     → @张三${R}       │"
p "  │  ${D}3. 🕐 周一同步会移至下午       → @张三${R}       │"
p "  │  ${D}4. 🐛 iOS 内存泄漏专项排查     → @赵六${R}       │"
p "  │                                                │"
p "  │  ${GRN}🔁 上期闭环率: 75% (3/4)${R}                     │"
p "  └────────────────────────────────────────────────┘"

echo ""
sleep 0.3

# ── Step 7 ──
p "${B}Step 7${R}  保存到飞书"
p "  ${D}$ lark-cli docs +create --title \"Sprint 回顾 W13\"${R}"
spin "创建飞书文档" 1
p "  ${D}$ lark-cli task +tasklist-create --name \"W13 Action Items\"${R}"
spin "创建任务列表" 1

echo ""
p "${GRN}${B}✅ 回顾完成${R}"
echo ""
p "  📄 报告  →  飞书文档「Sprint 回顾 W13」"
p "  📂 归档  →  知识库「团队回顾」"
p "  ✅ 行动  →  任务列表「W13 Action Items」(4 项)"
p "  🔁 闭环  →  ${GRN}3 个上期行动项已自动关闭${R}"
echo ""
