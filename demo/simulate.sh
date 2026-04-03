#!/usr/bin/env bash
# 模拟 lark-retro 工作流的终端演示脚本
# 用于 VHS 录制

set -euo pipefail

# — 颜色定义 —
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
WHITE='\033[97m'
RESET='\033[0m'

print_slow() {
  local text="$1"
  local delay="${2:-0.02}"
  for (( i=0; i<${#text}; i++ )); do
    printf '%s' "${text:$i:1}"
    sleep "$delay"
  done
  echo
}

spin() {
  local msg="$1"
  local duration="$2"
  local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local end=$((SECONDS + duration))
  while [ $SECONDS -lt $end ]; do
    for (( i=0; i<${#chars}; i++ )); do
      printf "\r  ${CYAN}${chars:$i:1}${RESET} ${DIM}${msg}${RESET}"
      sleep 0.08
    done
  done
  printf "\r  ${GREEN}✔${RESET} ${msg}\n"
}

p() { echo -e "$1"; }

# ─────────────────────────────────────────────
#  开始演示
# ─────────────────────────────────────────────

echo ""
p "${BOLD}${WHITE}🔄 lark-retro${RESET}  ${DIM}v2.0.0 — AI Sprint Retrospective for Feishu${RESET}"
p "${DIM}─────────────────────────────────────────────────────${RESET}"
echo ""

# 用户输入
printf "${GREEN}❯${RESET} "
print_slow "帮我做上周的 Sprint 回顾" 0.05
echo ""
sleep 0.3

# Step 1
p "${BOLD}${CYAN}▸ Step 1${RESET} 确定回顾周期  ${DIM}→ W13 (2026-03-24 ~ 2026-03-30)${RESET}"
sleep 0.3

# Step 2
p "${BOLD}${CYAN}▸ Step 2${RESET} 采集日历数据"
p "  ${DIM}\$ lark-cli calendar +agenda --start 2026-03-24 --end 2026-03-30${RESET}"
spin "获取日历事件..." 1
p "  ${WHITE}📅 23 个事件${RESET}  ${DIM}🔄×5  📋×4  👥×3  🌐×2  📌×4  │  会议占比 42%${RESET}"

# Step 3
p "${BOLD}${CYAN}▸ Step 3${RESET} 采集任务数据"
p "  ${DIM}\$ lark-cli task +get-my-tasks --page-all${RESET}"
spin "获取任务列表..." 1
p "  ${WHITE}✅ 22 个任务${RESET}  ${DIM}完成 18 个 (81.8%)  │  按时 15/18  │  🚧 Blocker ×2${RESET}"

# Step 4
p "${BOLD}${CYAN}▸ Step 4${RESET} 采集消息数据"
p "  ${DIM}\$ lark-cli im +messages-search --query \"进展|问题|blocker\" --format json${RESET}"
spin "搜索关键消息..." 1
p "  ${WHITE}💬 12 条高质量消息${RESET}  ${DIM}（4 层漏斗过滤噪声）${RESET}"

# Step 5
p "${BOLD}${CYAN}▸ Step 5${RESET} 对比历史报告"
p "  ${DIM}\$ lark-cli docs +search --query \"Sprint 回顾 W12\"${RESET}"
spin "搜索上期报告..." 1
p "  ${WHITE}📄 找到 W12 报告${RESET}  ${DIM}会议 47%→42% ↓  完成率 75.8%→81.8% ↑${RESET}"

# Step 5c
p "${BOLD}${CYAN}▸ Step 5c${RESET} 行动项闭环"
p "  ${DIM}\$ lark-cli task +complete --task-id <guid-1/2/3>${RESET}"
spin "关闭已完成的行动项..." 1
p "  ${GREEN}✔${RESET} 3 个已关闭  ${YELLOW}↻${RESET} 1 个添加备注  ${DIM}闭环率 75%${RESET}"

echo ""

# Step 6: 生成报告
p "${BOLD}${MAGENTA}▸ Step 6${RESET} ${BOLD}AI 生成回顾报告${RESET}"
spin "分析数据、生成结构化报告..." 2
echo ""

# 报告预览 — 紧凑排版
p "${BOLD}${WHITE}┌──────────────────────────────────────────────────┐${RESET}"
p "${BOLD}${WHITE}│  🔄 Sprint 回顾报告 — W13 (03-24 ~ 03-30)       │${RESET}"
p "${BOLD}${WHITE}├──────────────────────────────────────────────────┤${RESET}"
p "${BOLD}${WHITE}│${RESET}                                                  ${BOLD}${WHITE}│${RESET}"
p "${BOLD}${WHITE}│${RESET}  ${GREEN}🌟 What Went Well${RESET}                              ${BOLD}${WHITE}│${RESET}"
p "${BOLD}${WHITE}│${RESET}  ${DIM}1. 📈 任务完成率显著提升 (+6%)${RESET}                 ${BOLD}${WHITE}│${RESET}"
p "${BOLD}${WHITE}│${RESET}  ${DIM}2. ⏱️  会议时间成功缩减 (47%→42%)${RESET}              ${BOLD}${WHITE}│${RESET}"
p "${BOLD}${WHITE}│${RESET}  ${DIM}3. 🤝 跨团队协作效率提升${RESET}                       ${BOLD}${WHITE}│${RESET}"
p "${BOLD}${WHITE}│${RESET}  ${DIM}4. 📄 文档协作顺畅，新增 4 篇技术文档${RESET}          ${BOLD}${WHITE}│${RESET}"
p "${BOLD}${WHITE}│${RESET}                                                  ${BOLD}${WHITE}│${RESET}"
p "${BOLD}${WHITE}│${RESET}  ${YELLOW}⚠️  What Could Be Improved${RESET}                      ${BOLD}${WHITE}│${RESET}"
p "${BOLD}${WHITE}│${RESET}  ${DIM}1. 🚧 2 个 Blocker 未解决（支付沙箱/iOS 泄漏）${RESET} ${BOLD}${WHITE}│${RESET}"
p "${BOLD}${WHITE}│${RESET}  ${DIM}2. 📋 需求评审占比最高 (36%)，2 场二次评审${RESET}     ${BOLD}${WHITE}│${RESET}"
p "${BOLD}${WHITE}│${RESET}  ${DIM}3. ⏰ 3 个任务延期  4. 📅 周一会议过于密集${RESET}     ${BOLD}${WHITE}│${RESET}"
p "${BOLD}${WHITE}│${RESET}                                                  ${BOLD}${WHITE}│${RESET}"
p "${BOLD}${WHITE}│${RESET}  ${BLUE}🎯 Action Items${RESET}                                 ${BOLD}${WHITE}│${RESET}"
p "${BOLD}${WHITE}│${RESET}  ${DIM}1. 🔧 联系支付团队升级沙箱环境      → @王五${RESET}    ${BOLD}${WHITE}│${RESET}"
p "${BOLD}${WHITE}│${RESET}  ${DIM}2. 📝 PRD 模板增加边界场景清单      → @张三${RESET}    ${BOLD}${WHITE}│${RESET}"
p "${BOLD}${WHITE}│${RESET}  ${DIM}3. 🕐 周一同步会移至下午            → @张三${RESET}    ${BOLD}${WHITE}│${RESET}"
p "${BOLD}${WHITE}│${RESET}  ${DIM}4. 🐛 iOS 内存泄漏专项排查          → @赵六${RESET}    ${BOLD}${WHITE}│${RESET}"
p "${BOLD}${WHITE}│${RESET}                                                  ${BOLD}${WHITE}│${RESET}"
p "${BOLD}${WHITE}│${RESET}  ${GREEN}🔁 上期闭环率: 3/4 = 75%${RESET}                       ${BOLD}${WHITE}│${RESET}"
p "${BOLD}${WHITE}└──────────────────────────────────────────────────┘${RESET}"
echo ""
sleep 0.3

# Step 7: 保存
p "${BOLD}${CYAN}▸ Step 7${RESET} 保存到飞书"
p "  ${DIM}\$ lark-cli docs +create --title \"Sprint 回顾 W13\"${RESET}"
spin "创建飞书文档..." 1
p "  ${DIM}\$ lark-cli task +tasklist-create --name \"W13 Action Items\"${RESET}"
spin "创建任务列表..." 1

echo ""
p "${GREEN}${BOLD}✅ 回顾完成！${RESET}"
p "  📄 报告 → ${BLUE}飞书文档「Sprint 回顾 W13」${RESET}"
p "  📂 归档 → ${BLUE}知识库「团队回顾」${RESET}"
p "  ✅ 行动 → ${BLUE}任务列表「W13 Action Items」(4 项)${RESET}"
p "  🔁 闭环 → ${GREEN}3 个上期行动项已自动关闭${RESET}"
echo ""
