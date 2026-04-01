---
name: lark-retro
version: 1.0.0
description: "Sprint/周期回顾工作流：自动从日历、消息、任务、文档中采集工作数据，AI 生成结构化回顾报告（做得好的/待改进的/行动项），沉淀到知识库，并追踪改进项闭环。当用户需要做回顾、复盘、retrospective、周报总结时使用。"
metadata:
  requires:
    bins: ["lark-cli"]
---

# Sprint 回顾工作流

**CRITICAL — 开始前 MUST 先用 Read 工具读取 [`../lark-shared/SKILL.md`](../lark-shared/SKILL.md)，其中包含认证、权限处理**

## 适用场景

- "帮我做一下上周的回顾" / "sprint retrospective"
- "复盘一下这周的工作" / "这周我们做得怎么样"
- "总结一下过去两周的工作情况" / "生成回顾报告"
- "上周的改进项落地了吗" / "追踪一下行动项"
- "帮我写周报" / "生成工作总结"

## 前置条件

仅支持 **user 身份**。执行前确保已授权所需业务域：

```bash
lark-cli auth login --domain calendar,im,task,doc,wiki
```

> **最小化启动**：如果只需要基础回顾（日程+任务），授权 `calendar,task` 即可。消息分析和知识库沉淀为增强功能，按需授权。

## 工作流总览

```
用户输入（时间范围）
    │
    ├─► Step 1: calendar +agenda ──────────► 日程数据（时间分配）
    ├─► Step 2: task +get-my-tasks ─────────► 任务完成情况
    ├─► Step 3: im +messages-search ────────► 关键讨论 & Blocker（可选）
    ├─► Step 4: docs +search ──────────────► 相关文档上下文（可选）
    │
    ▼
Step 5: AI 分析 & 生成结构化回顾报告
    │
    ├─► Step 6: docs +create ──────────────► 创建回顾文档
    ├─► Step 7: wiki +create-node ──────────► 沉淀到知识库（可选）
    ├─► Step 8: task +create ──────────────► 创建行动项任务
    └─► Step 9: im +messages-send ──────────► 群聊通知（可选）
```

---

## Step 1: 确定时间范围

默认**过去 7 天**（上一个 Sprint 周期）。推断规则：

| 用户说法 | 时间范围 |
|----------|----------|
| "上周" | 上周一 00:00 ~ 上周日 23:59 |
| "这周" | 本周一 00:00 ~ 当前时间 |
| "过去两周" | 14 天前 00:00 ~ 当前时间 |
| "这个月" | 本月 1 日 00:00 ~ 当前时间 |
| "上个 sprint" | 需要用户确认周期长度，默认 2 周 |

> **注意**：日期转换必须通过系统命令（如 `date`）计算，不要心算。时间格式使用 ISO 8601（如 `2026-03-24T00:00:00+08:00`）。

## Step 2: 采集日程数据

```bash
# 获取指定时间范围的日程
lark-cli calendar +agenda --start "<start_date>" --end "<end_date>"
```

> `--start` / `--end` 仅支持 ISO 8601 格式或 Unix timestamp，**不支持** `"last week"` 等自然语言。

**从日程数据中提取：**
- 会议总数和总时长
- 按类别分类（可从 summary 关键词推断）：
  - 团队会议（standup / sync / weekly）
  - 评审会议（review / 评审）
  - 一对一（1:1 / one-on-one）
  - 其他事件
- 会议密度：会议时间占总工作时间的百分比
- 超时会议：实际时长超过预定时长的（如有相关数据）

**数据处理规则：**
1. **时间转换**：API 返回 Unix timestamp，需根据 `timezone` 字段（通常 `Asia/Shanghai`）转换为 `HH:mm`
2. **RSVP 状态映射**：`accept`→已接受, `decline`→已拒绝, `needs_action`→待确认, `tentative`→暂定
3. **已拒绝的日程**：统计时排除，不计入会议时间
4. **全天事件**：单独标注，不计入会议时长

## Step 3: 采集任务数据

```bash
# 获取指定日期前到期的已完成任务
lark-cli task +get-my-tasks --completed

# 获取未完成任务
lark-cli task +get-my-tasks
```

> **注意**：不带过滤条件可能返回大量历史任务（100KB+），建议用 `--due-end` 限制范围。超过 20 条时加 `--page-all`。

**从任务数据中提取：**
- 任务完成率：已完成 / 总任务数
- 按时完成 vs 延期完成
- 仍未关闭的任务列表（潜在 Blocker）
- 新创建但未完成的任务

## Step 4: 采集消息数据（可选 — 需 im 授权）

```bash
# 搜索群聊中的关键讨论
lark-cli im +messages-search --query "问题|bug|延期|blocker|风险|卡住" --start-time "<unix_start>" --end-time "<unix_end>" --format json
```

> **注意**：`--start-time` 和 `--end-time` 使用 Unix timestamp（秒），需要从 ISO 8601 转换。如果不确定参数格式，先运行 `lark-cli schema im.messages.search` 查看。

**从消息数据中提取：**
- Blocker 和风险讨论
- 关键决策（含关键词：决定、确认、同意、方案）
- 值得记录的正面反馈

## Step 5: 采集文档上下文（可选 — 需 doc 授权）

```bash
# 搜索时间范围内相关文档
lark-cli docs +search --query "周报 sprint 总结" --format json
```

**用途**：查找是否有之前的回顾报告，用于趋势对比。

---

## Step 6: AI 生成回顾报告

将 Step 2-5 的数据交给 AI，按以下模板生成结构化报告：

```markdown
# Sprint 回顾报告 — {周期标识} ({start_date} ~ {end_date})

## 数据概览

| 指标 | 数值 | 趋势 |
|------|------|------|
| 日程事件 | {n} 个 | {vs上期} |
| 会议占比 | {x}%（{h}小时/{total_h}工作小时） | {vs上期} |
| 任务完成率 | {done}/{total} = {rate}% | {vs上期} |
| 未关闭 Blocker | {b} 个 | — |

## What Went Well

{从以下数据源自动提取：}
{- 按时完成的重要任务}
{- 完成率高于上期}
{- 消息中的正面反馈}
{- 会议效率提升（时间减少但产出不减）}

1. ...
2. ...
3. ...

## What Could Be Improved

{从以下数据源自动提取：}
{- 未完成/延期的任务}
{- 消息中的 blocker/风险讨论}
{- 会议占比过高（>50%）}
{- 超时会议}

1. ...
2. ...
3. ...

## Action Items

| # | 改进项 | 负责人 | 截止日期 |
|---|--------|--------|----------|
| 1 | {具体可执行的改进行动} | {从任务/消息推断} | {建议日期} |
| 2 | ... | ... | ... |

## 上期行动项追踪

{如果找到上期回顾报告，自动追踪行动项完成情况}

| # | 上期行动项 | 状态 | 备注 |
|---|-----------|------|------|
| 1 | ... | ✅ 已完成 / ⬜ 进行中 / ❌ 未开始 | ... |
```

**AI 分析规则：**
1. "What Went Well" 和 "What Could Be Improved" 各列 3-5 条，基于数据而非泛泛而谈
2. Action Items 必须具体、可执行、有负责人和截止日期
3. 趋势对比：如果找到上期报告，自动计算变化趋势（↑/↓/→）
4. 语气中立客观，不过分乐观也不过分悲观
5. 如果某个数据源没有授权或数据为空，在报告中注明"（未采集）"而非留白

---

## Step 7: 创建回顾文档

```bash
lark-cli docs +create --title "Sprint 回顾 {周期标识}" --markdown "<报告内容>"
```

> 记录返回的 `doc_token`，后续 Step 8 和 Step 9 需要用到文档链接。

## Step 8: 沉淀到知识库（可选 — 需 wiki 授权）

```bash
# 先查找知识库空间
lark-cli wiki +list

# 在指定空间下创建节点（挂载回顾文档）
lark-cli wiki +create-node --space-id "<space_id>" --parent-node "<parent_node_token>" --doc-token "<doc_token>"
```

> **注意**：用户需要告知知识库空间 ID 和父节点 token。首次使用时引导用户指定，后续可记住。
> 如果用户未指定知识库，跳过此步骤，仅创建独立文档。

## Step 9: 创建行动项任务

对报告中的每个 Action Item，自动创建飞书任务：

```bash
# 为每个行动项创建任务
lark-cli task +create --summary "<行动项描述>" --due "<截止日期ISO8601>"
```

> **安全**：创建任务前列出所有待创建的任务，**先让用户确认**再批量创建。

## Step 10: 群聊通知（可选 — 需 im 授权）

```bash
lark-cli im +messages-send --chat-id "<chat_id>" --markdown "**Sprint 回顾已生成**\n\n完成率 {rate}% | {blocker_count} 个待处理 Blocker\n\n[查看完整报告]({doc_url})"
```

> 用户需提供群聊 ID。如果不提供，跳过通知步骤。

---

## 权限表

| 命令 | 所需 scope | 是否必须 |
|------|-----------|----------|
| `calendar +agenda` | `calendar:calendar.event:read` | 是 |
| `task +get-my-tasks` | `task:task:read` | 是 |
| `task +create` | `task:task:write` | 是 |
| `docs +create` | `docs:doc:create` | 是 |
| `docs +search` | `docs:doc:read` | 否（增强） |
| `im +messages-search` | `im:message:read` | 否（增强） |
| `im +messages-send` | `im:message:send` | 否（通知） |
| `wiki +list` | `wiki:wiki:read` | 否（沉淀） |
| `wiki +create-node` | `wiki:wiki:write` | 否（沉淀） |

## 参考

- [lark-shared](../lark-shared/SKILL.md) — 认证、权限（必读）
- [lark-calendar](../lark-calendar/SKILL.md) — `+agenda` 详细用法
- [lark-task](../lark-task/SKILL.md) — `+get-my-tasks`、`+create` 详细用法
- [lark-doc](../lark-doc/SKILL.md) — `+create`、`+search` 详细用法
- [lark-im](../lark-im/SKILL.md) — `+messages-search`、`+messages-send` 详细用法
- [lark-wiki](../lark-wiki/SKILL.md) — `+list`、`+create-node` 详细用法
