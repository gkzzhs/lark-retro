---
name: lark-retro
version: 1.2.0
description: "Sprint/周期回顾工作流：自动从日历、消息、任务、文档中采集工作数据，AI 生成结构化回顾报告（做得好的/待改进的/行动项），沉淀到知识库，并追踪改进项闭环。当用户需要做回顾、复盘、retrospective、周报总结时使用。"
metadata:
  requires:
    bins: ["lark-cli"]
    cliHelp: "lark-cli calendar --help && lark-cli task --help && lark-cli docs --help && lark-cli im --help"
---

# Sprint 回顾工作流

**CRITICAL — 开始前 MUST 先用 Read 工具读取 [`../lark-shared/SKILL.md`](../lark-shared/SKILL.md)，其中包含认证、权限处理、安全规则**

## 适用场景

- "帮我做一下上周的回顾" / "sprint retrospective"
- "复盘一下这周的工作" / "这周我们做得怎么样"
- "总结一下过去两周的工作情况" / "生成回顾报告"
- "上周的改进项落地了吗" / "追踪一下行动项"
- "帮我写周报" / "生成工作总结"

## 前置条件

仅支持 **user 身份**（`--as user`，calendar/task/docs 默认）。执行前确保已授权所需业务域：

```bash
# 基础回顾（日程 + 任务 + 文档创建）— 必须
lark-cli auth login --domain calendar,task,doc

# 完整回顾（消息搜索 + 文档搜索）— 可选增强，使用 --scope 按需授权
lark-cli auth login --scope "search:message search:docs:read"
```

> **最小化启动**：授权 `calendar,task,doc` 即可使用核心功能。消息分析需额外 scope `search:message`，文档搜索需 `search:docs:read`。多次 login 的 scope 会累积。

## 工作流总览

```
用户输入（时间范围）
    │
    ├─► Step 1: calendar +agenda ──────────► 日程数据（时间分配）
    ├─► Step 2: task +get-my-tasks ─────────► 任务完成情况
    ├─► Step 3: im +messages-search ────────► 关键讨论 & Blocker（可选，需 search:message）
    ├─► Step 4: docs +search ──────────────► 上期回顾上下文（可选，需 search:docs:read）
    │
    ▼
Step 5: AI 分析 & 生成结构化回顾报告
    │
    ├─► Step 6: docs +create ──────────────► 创建回顾文档（可选 --wiki-space 归档）
    ├─► Step 7: task +create ──────────────► 创建行动项任务（需用户确认）
    └─► Step 8: im +messages-send ──────────► 群聊通知（可选，需 bot 身份）
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
# --start/--end 支持 ISO 8601 格式（YYYY-MM-DD 或 YYYY-MM-DDTHH:mm:ss+08:00）
lark-cli calendar +agenda --start "<start_date>" --end "<end_date>"
```

> **重要**：使用前先运行 `lark-cli calendar +agenda --help` 确认参数。

**从日程数据中提取：**
- 会议总数和总时长
- 按类别分类（从 `summary` 关键词推断）：
  - 团队会议（standup / sync / weekly）
  - 评审会议（review / 评审）
  - 一对一（1:1 / one-on-one）
  - 其他事件
- 会议密度：会议时间占总工作时间（每天 8 小时）的百分比
- 超时会议：实际时长超过预定时长的（如有相关数据）

**数据处理规则：**
1. **时间格式**：API 返回 ISO 8601 datetime（如 `2026-03-29T13:30:00+08:00`），直接解析
2. **RSVP 状态映射**：`self_rsvp_status` 字段 — `accept`→已接受, `decline`→已拒绝, `needs_action`→待确认, `tentative`→暂定
3. **已拒绝的日程**：`self_rsvp_status: "decline"` 的事件排除，不计入会议时间
4. **全天事件**：仅有 `date` 而无 `datetime` 的事件单独标注，不计入会议时长
5. **会议时长计算**：`end_time.datetime - start_time.datetime`
6. **日程排序**：按开始时间升序排列

## Step 3: 采集任务数据

```bash
# 获取已完成任务（⚠️ 注意是 --complete 不是 --completed）
lark-cli task +get-my-tasks --complete

# 获取未完成任务
lark-cli task +get-my-tasks

# 可选：限制时间范围减少数据量
# --due-end / --created_at 支持格式：date(YYYY-MM-DD) / relative(+7d) / ms timestamp
lark-cli task +get-my-tasks --due-end "<end_date>"
lark-cli task +get-my-tasks --complete --created_at "<start_date>"

# 超过 20 条时自动翻页（最多 40 条）
lark-cli task +get-my-tasks --page-all
```

> **注意**：不带过滤条件可能返回大量历史任务。摘要场景建议用 `--due-end` 过滤。

**从任务数据中提取：**
- 任务完成率：已完成 / 总任务数
- 按时完成 vs 延期完成（对比 `due` 和 `completed_at`）
- 仍未关闭的任务列表（潜在 Blocker）
- 新创建但未完成的任务

## Step 4: 采集消息数据（可选 — 需 `search:message` scope）

```bash
# 搜索群聊中的关键讨论
# --start/--end 使用 ISO 8601 格式（带时区偏移）
lark-cli im +messages-search --query "问题" \
  --start "2026-03-24T00:00:00+08:00" \
  --end "2026-03-31T23:59:59+08:00" \
  --format json
```

> **权限**：需要 `search:message` scope。未授权会报 `missing_scope` 错误，此时跳过消息分析，在报告中标注"（消息数据未采集 — 需要 `lark-cli auth login --scope "search:message"` 授权）"。
>
> **搜索策略**：分多次搜索不同关键词（问题、bug、延期、blocker、风险），合并结果去重。
>
> **可用过滤器**：`--chat-id`（限定群聊）、`--sender`（限定发送人 open_id）、`--is-at-me`（只看@我的）、`--chat-type group|p2p`。

**从消息数据中提取：**
- Blocker 和风险讨论
- 关键决策（含关键词：决定、确认、同意、方案）
- 值得记录的正面反馈

## Step 5: 采集文档上下文（可选 — 需 `search:docs:read` scope）

```bash
# 搜索相关文档（用于找到上期回顾报告做趋势对比）
lark-cli docs +search --query "Sprint 回顾" --format json
```

> **权限**：需要 `search:docs:read` scope。未授权时跳过，趋势对比标注"（无上期数据）"。

**用途**：查找是否有之前的回顾报告，用于趋势对比和上期行动项追踪。

---

## Step 6: AI 生成回顾报告

将 Step 1-5 的数据交给 AI，按以下模板生成结构化报告：

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
{- 会议效率提升}

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

## 上期行动项追踪

{如果找到上期回顾报告，自动追踪行动项完成情况}

| # | 上期行动项 | 状态 | 备注 |
|---|-----------|------|------|
| 1 | ... | ✅ 已完成 / ⬜ 进行中 / ❌ 未开始 | ... |
```

**AI 分析规则：**
1. "What Went Well" 和 "What Could Be Improved" 各列 3-5 条，**必须基于数据**而非泛泛而谈
2. Action Items 必须具体、可执行、有负责人和截止日期
3. 趋势对比：如果找到上期报告，自动计算变化趋势（↑/↓/→）
4. 语气中立客观，不过分乐观也不过分悲观
5. 如果某个数据源没有授权或数据为空，在报告中注明"（未采集）"而非留白

---

## Step 7: 创建回顾文档

```bash
# 创建独立文档
lark-cli docs +create --title "Sprint 回顾 {周期标识}" --markdown "<报告内容>"

# 或直接创建到知识库（推荐）
# --wiki-space 指定空间 ID，使用 "my_library" 表示个人知识库
# --wiki-node 可选，指定父节点 token
lark-cli docs +create --title "Sprint 回顾 {周期标识}" \
  --markdown "<报告内容>" \
  --wiki-space "<space_id>" \
  --wiki-node "<parent_node_token>"
```

> **返回值**：`doc_id`、`doc_url`（wiki 路径）。后续通知需要用到 `doc_url`。
> **注意**：`docs +create` 不支持 `--format` flag。
> 如果用户未指定知识库，跳过 `--wiki-space`，仅创建独立文档。首次使用时引导用户选择归档位置。

## Step 8: 创建行动项任务

对报告中的每个 Action Item，自动创建飞书任务：

```bash
# --due 支持格式：ISO 8601 / date:YYYY-MM-DD / relative:+7d / ms timestamp
# --summary 为任务标题
# --description 可选，补充描述
lark-cli task +create --summary "<行动项描述>" --due "<截止日期>"
```

> **⚠️ 安全**：创建任务前列出所有待创建的任务，**先让用户确认**再批量创建。可用 `--dry-run` 预览。
> **返回值**：`guid`（任务 ID）和 `url`（任务深链接）。

## Step 9: 群聊通知（可选 — 需 bot 身份）

```bash
# 发送到群聊（⚠️ 仅 bot 身份，默认 --as bot）
lark-cli im +messages-send --chat-id "<chat_id>" \
  --markdown "**Sprint 回顾已生成**\n\n完成率 {rate}% | {blocker_count} 个待处理项\n\n[查看完整报告]({doc_url})"

# 或发送私信（使用 --user-id 替代 --chat-id，互斥）
lark-cli im +messages-send --user-id "<open_id>" \
  --markdown "你的 Sprint 回顾已生成：{doc_url}"
```

> **注意**：`im +messages-send` 默认 `--as bot`，需要应用已配置 bot 能力且 bot 已加入目标群聊。
> **如果用户未配置 bot 或未提供群聊 ID**，跳过通知步骤，在最终输出中直接展示文档链接即可。
> `--chat-id` 与 `--user-id` 互斥，只能选一个。

---

## 权限表

| 命令 | 授权方式 | 是否必须 |
|------|---------|----------|
| `calendar +agenda` | `--domain calendar` | 是 |
| `task +get-my-tasks` | `--domain task` | 是 |
| `task +create` | `--domain task` | 是 |
| `docs +create` | `--domain doc` | 是 |
| `docs +search` | `--scope "search:docs:read"` | 否（增强） |
| `im +messages-search` | `--scope "search:message"` | 否（增强） |
| `im +messages-send` | bot 身份，需在开发者后台开通 | 否（通知） |

## 错误处理

| 错误 | 原因 | 处理 |
|------|------|------|
| `missing_scope` | 未授权某 scope | 跳过对应步骤，报告中标注"（未采集）"，展示 `hint` 中的修复命令 |
| `items: null` | 时间范围内无数据 | 报告中标注"本周期无{日程/任务}数据" |
| `rate_limit` | API 限流 | 等待几秒后重试，最多 3 次 |
| `permission denied` | 用户无权访问某资源 | 参考 lark-shared 中的权限处理流程 |

## 参考

- [lark-shared](../lark-shared/SKILL.md) — 认证、权限、安全规则（**必读**）
- [lark-calendar](../lark-calendar/SKILL.md) — `+agenda` 详细用法
- [lark-task](../lark-task/SKILL.md) — `+get-my-tasks`、`+create` 详细用法
- [lark-doc](../lark-doc/SKILL.md) — `+create`、`+search` 详细用法
- [lark-im](../lark-im/SKILL.md) — `+messages-search`、`+messages-send` 详细用法
