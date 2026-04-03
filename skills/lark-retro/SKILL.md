---
name: lark-retro
version: 2.0.0
description: "Sprint/周期回顾工作流：自动从日历、消息、任务、文档中采集工作数据，AI 生成结构化回顾报告（做得好的/待改进的/行动项），沉淀到知识库，并追踪改进项闭环。支持行动项自动关闭、任务列表分组、历史报告对比。当用户需要做回顾、复盘、retrospective、周报总结时使用。"
metadata:
  requires:
    bins: ["lark-cli"]
    cliHelp: "lark-cli calendar --help && lark-cli task --help && lark-cli docs --help && lark-cli im --help && lark-cli drive --help"
---

# Sprint 回顾工作流

**CRITICAL — 开始前 MUST 先用 Read 工具读取 [`../lark-shared/SKILL.md`](../lark-shared/SKILL.md)，其中包含认证、权限处理、安全规则。如果文件不存在，提示用户先安装官方 Skills：`npx skills add https://github.com/larksuite/cli -y -g`**

## 适用场景

- "帮我做一下上周的回顾" / "sprint retrospective"
- "复盘一下这周的工作" / "这周我们做得怎么样"
- "总结一下过去两周的工作情况" / "生成回顾报告"
- "上周的改进项落地了吗" / "追踪一下行动项"
- "帮我写周报" / "weekly report" / "生成工作总结"
- "帮我写一下这周的工作汇报" / "本周工作小结"
- "帮我关掉上次的行动项" / "close action items"

## 前置条件

仅支持 **user 身份**（`--as user`，calendar/task/docs 默认）。执行前确保已授权所需业务域：

```bash
# 最低可用授权（日历 + 文档）
lark-cli auth login --domain calendar,docs

# 推荐授权（日历 + 任务 + 文档）— 报告内容更丰富
lark-cli auth login --domain calendar,task,docs

# 可选增强（消息搜索 + 文档搜索）— 使用 --scope 按需授权
lark-cli auth login --scope "search:message search:docs:read"

# 可选增强（导出历史报告为 Markdown 做趋势对比）
lark-cli auth login --scope "docs:document.content:read"
```

> **最低可用**：`calendar,docs` 即可生成基于时间分配的基础报告。加 `task` 后可分析任务完成率。多次 login 的 scope 会累积。
>
> ⚠️ domain 必须用 `docs`（带 s），`doc` 会被 CLI 拒绝。

## 能力分层

| 层级 | 功能 | 所需授权 |
|------|------|---------|
| **基础版** | 日历分析 + 文档输出 | `--domain calendar,docs` |
| **增强版** | + 任务追踪 + 行动项关闭 | `--domain calendar,task,docs` |
| **高级版** | + 消息分析 + 文档搜索 + 知识库归档 | + `--scope "search:message search:docs:read"` |
| **完整版** | + Bot 群聊通知 + 历史报告导出 | + bot 能力 + `--scope "docs:document.content:read"` |

缺少某一层的授权时，对应模块自动跳过，不影响其他功能。报告中标注"（未采集 — 需 `<具体授权命令>`）"。

## 工作流总览

```
Step 1: 确定报告模式 & 时间范围（推断用户意图 → 用系统命令计算 start/end）
    │
    ├─► Step 2: calendar +agenda ──────────► 日程数据（时间分配）
    ├─► Step 3: task +get-my-tasks ─────────► 任务完成情况
    ├─► Step 4: im +messages-search ────────► 关键讨论 & Blocker（可选）
    ├─► Step 5a: docs +search ─────────────► 上期回顾上下文（可选）
    ├─► Step 5b: drive +export ─────────────► 导出上期报告全文对比（可选）
    │
    ▼
Step 5c: 追踪上期行动项（task +complete / +comment）
    │
    ▼
Step 6: AI 分析 & 生成结构化回顾报告
    │
    ├─► Step 7: docs +create ──────────────► 创建回顾文档（⚠️ 用户确认）
    ├─► Step 8: task +create ──────────────► 创建行动项任务 + 任务列表（⚠️ 用户确认）
    └─► Step 9: im +messages-send ──────────► 群聊通知（⚠️ 用户确认，需 bot）
```

---

## Step 1: 确定报告模式 & 时间范围

### 模式判断

根据用户措辞自动选择报告模式：

| 用户说法 | 模式 | 报告模板 |
|----------|------|----------|
| "回顾" / "复盘" / "retrospective" / "retro" | **回顾模式** | What Went Well / What Could Be Improved / Action Items |
| "周报" / "工作总结" / "工作汇报" / "weekly report" / "小结" | **周报模式** | 本周完成 / 下周计划 / 需要支持 |

> 如果无法判断，默认使用**回顾模式**。用户可随时要求切换："换成周报格式" / "用回顾格式"。

### 时间范围

默认**过去 7 天**（上一个 Sprint 周期）。推断规则：

| 用户说法 | 时间范围 |
|----------|----------|
| "上周" | 上周一 00:00 ~ 上周日 23:59 |
| "这周" | 本周一 00:00 ~ 当前时间 |
| "过去两周" | 14 天前 00:00 ~ 当前时间 |
| "这个月" | 本月 1 日 00:00 ~ 当前时间 |
| "上个 sprint" | 需要用户确认周期长度，默认 2 周 |

> **⚠️ 必须用系统命令计算绝对日期**，不要心算。周起始默认周一（ISO 8601 标准）。时间格式使用 ISO 8601（如 `2026-03-24T00:00:00+08:00`）。
>
> 日期计算命令因平台而异：
> - macOS：`date -v-7d +%Y-%m-%d`
> - Linux：`date -d "7 days ago" +%Y-%m-%d`
> - 跨平台：`python3 -c "from datetime import datetime,timedelta; print((datetime.now()-timedelta(days=7)).strftime('%Y-%m-%d'))"`

## Step 2: 采集日程数据

```bash
# 获取指定时间范围的日程
# --start/--end 支持 ISO 8601 格式（YYYY-MM-DD 或 YYYY-MM-DDTHH:mm:ss+08:00）
lark-cli calendar +agenda --start "<start_date>" --end "<end_date>"

# 💡 用 --jq 精简输出，仅保留关键字段
lark-cli calendar +agenda --start "<start_date>" --end "<end_date>" \
  --jq '.data | .[] | {summary, start: .start_time.datetime, end: .end_time.datetime, rsvp: .self_rsvp_status}'
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
7. **相似事件聚合（重要）**：当多个事件满足以下任一条件时，视为同一活动的并行实例，在报告中合并为一条并标注实例数：
   - 同一天同一时段，`summary` 仅在城市名/编号/分会场标识上不同（如"北京AI大会""上海AI大会"→ 合并为"AI大会（30+ 城市分会场）"）
   - `summary` 完全相同的重复日程（如每日 standup 合并为"每日站会 x5"）
   - 判断方法：去掉 summary 中的地名/数字后缀，若剩余部分相同则视为同一活动
   - 合并后仅按 1 个事件计入会议数量和时长（取用户实际参加的那个实例的时长）

## Step 3: 采集任务数据

```bash
# 获取已完成任务（⚠️ 注意是 --complete 不是 --completed）
lark-cli task +get-my-tasks --complete

# 获取未完成任务
lark-cli task +get-my-tasks

# 超过 20 条时自动翻页
lark-cli task +get-my-tasks --page-all
```

> **可选过滤**：`--due-end`、`--created_at` 可用于缩小范围（格式：`date/relative/ms`），但这些过滤器可能在客户端执行，建议先不带过滤获取全量，再在 AI 分析阶段按时间范围筛选。
>
> **无任务数据时**：在报告"📋 数据质量说明"中标注"✅ 任务数据 ❌（本周期无飞书任务数据）"，**不中断工作流**。基于日程数据仍可生成有价值的回顾。在报告末尾补充提示："💡 如果您使用 Jira / Linear / GitHub Issues 等外部工具管理任务，可在下次回顾时告知，以便纳入分析。"避免错误建议用户"开始使用飞书任务"。

**从任务数据中提取：**
- 任务完成率：已完成 / 总任务数
- 按时完成 vs 延期完成（对比 `due` 和 `completed_at`）
- 仍未关闭的任务列表（潜在 Blocker）
- 新创建但未完成的任务

## Step 4: 采集消息数据（可选）

有两种方式获取消息数据，根据场景选择：

### 方式 A：消息搜索（需 `search:message` scope）

适用于模糊搜索关键词，不限定特定群聊。

```bash
# 搜索群聊中的关键讨论（推荐限定 --chat-type group 减少噪声）
# --start/--end 使用 ISO 8601 格式（带时区偏移）
lark-cli im +messages-search --query "问题" \
  --chat-type group \
  --start "2026-03-24T00:00:00+08:00" \
  --end "2026-03-31T23:59:59+08:00" \
  --format json
```

> **权限**：需要 `search:message` scope。未授权会报 `missing_scope` 错误，此时跳过消息分析，在报告中标注"（消息数据未采集 — 需要 `lark-cli auth login --scope "search:message"` 授权）"。
>
> **搜索策略**：分多次搜索不同关键词（问题、bug、延期、blocker、风险），合并结果去重。
>
> **可用过滤器**：`--chat-id`（限定群聊）、`--sender`（限定发送人 open_id）、`--is-at-me`（只看@我的）、`--chat-type group|p2p`。

### 方式 B：群聊消息列表（需 `im:message` scope）

适用于已知特定群聊 ID，按时间范围列出所有消息。比搜索更完整、噪声更少。

```bash
# 列出指定群聊的消息（按时间范围）
lark-cli im +chat-messages-list --chat-id "<chat_id>" \
  --start "2026-03-24T00:00:00+08:00" \
  --end "2026-03-31T23:59:59+08:00" \
  --page-size 50 --sort asc

# 也支持用 --user-id 列出与某人的私聊消息（与 --chat-id 互斥）
lark-cli im +chat-messages-list --user-id "<open_id>" \
  --start "2026-03-24T00:00:00+08:00" \
  --end "2026-03-31T23:59:59+08:00"
```

> **权限**：需要 `im:message` scope（`im:message:readonly` 可读部分消息，完整读取需 `im:message`）。
>
> **选择策略**：如果用户指定了群聊名称或 ID，优先用方式 B；如果用户描述模糊（如"搜一下最近讨论的问题"），用方式 A。先用 `im +chat-search --query "<群名>"` 获取 `chat_id`。

**⚠️ 噪声过滤（重要）**：搜索结果中会包含大量系统通知、应用卡片、运营公告等噪声消息。在提取洞察前必须逐层过滤：

**第零层：按消息来源区分工作相关性**
- 优先保留：与用户日常工作相关的**内部团队群聊**（项目群、部门群、协作群）
- 降权处理：**外部公开社区/技术交流群**（如开源社区、产品反馈群、行业交流群）——这些群的讨论通常与用户本职工作无关
- 判断方法：**优先依据消息内容主题与用户日历事件/任务的重合度判断**。若同一 `chat_id` 下的消息内容主题与用户的日历事件/任务完全无关，则标记为低相关性来源
- "用户未主动发言"仅作为**弱信号**辅助判断，不能单独作为低相关性依据（阅读型参与在真实工作中很常见，如大型项目群、跨部门信息同步群）
- 低相关性来源的消息不纳入 Blocker/风险分析，仅在有明确相关性时引用

**第一层：按消息类型排除**
- 排除 `sender_type` 为 `app` 的消息（系统/应用自动发送）
- 排除 `msg_type` 为 `interactive`（卡片消息）、`share_*`（分享类）的消息
- 仅保留 `msg_type: "text"` 或 `"post"`（富文本）的消息

**第二层：按关键词排除公告/运营噪声**
- 排除包含以下关键词的消息：权限开通、已分享、妙记、卡片通知、应用消息、每日收录通知、知识库更新、报名、倒计时、我们现场见、活动链接、签到
- 排除纯链接文本（无上下文讨论的 URL 贴发）

**第三层：按内容质量保留**
- 优先保留：带人名、带动词、有上下文的讨论性文本
- 降权处理：长公告卡片、批量链接贴、格式化运营内容

**过滤结果统计**：在报告的"数据质量说明"中注明过滤漏斗："消息搜索原始命中 N 条，经四层过滤后保留 M 条（第零层排除 a 条，第一层排除 b 条，第二层排除 c 条，第三层降权 d 条）"

**数据不足时**：如果过滤后高质量消息少于 3 条，在报告中标注"消息洞察不足（原始命中 N 条，过滤后仅 M 条高质量讨论）"，不要硬编分析

**从消息数据中提取：**
- Blocker 和风险讨论
- 关键决策（含关键词：决定、确认、同意、方案）
- 值得记录的正面反馈

## Step 5: 采集上期回顾上下文（可选）

### 5a: 搜索上期报告（需 `search:docs:read` scope）

```bash
# 依次尝试多个关键词，直到命中或全部尝试完毕
lark-cli docs +search --query "Sprint 回顾" --format json
lark-cli docs +search --query "回顾" --format json
lark-cli docs +search --query "Retro" --format json
lark-cli docs +search --query "周报" --format json
# 如果用户提供了项目名/Sprint 名，也用它搜索
lark-cli docs +search --query "{用户提供的项目名或Sprint名}" --format json
```

> **权限**：需要 `search:docs:read` scope。未授权时跳过，趋势对比标注"（无上期数据）"。

**多查询回退策略**：依次尝试上述关键词，任一查询返回结果即可停止。合并所有结果去重后，按创建时间倒序取最近一期作为趋势对比基准。

> **⚠️ 搜索限制**：`docs +search` 依赖飞书搜索索引，存在以下已知边界：
> - 新创建的文档可能需要数分钟才能被搜索索引收录
> - 标题命名不一致时可能搜不到（如用户把报告命名为"本周复盘"而非"Sprint 回顾"）
> - 若所有查询均返回 0 结果，**不代表没有历史文档**，在报告中标注"（未找到上期报告 — 可能因标题命名或索引延迟，趋势对比不可用）"

**用途**：查找是否有之前的回顾报告，用于趋势对比和上期行动项追踪。

### 5b: 导出上期报告全文（可选 — 需 `docs:document.content:read` scope）

如果在 Step 5a 中找到了上期回顾报告的 `doc_token`，可以导出为 Markdown 做更精确的趋势对比：

```bash
# 将上期回顾报告导出为 Markdown 文件
lark-cli drive +export --token "<doc_token>" --doc-type docx --file-extension markdown \
  --output-dir /tmp --overwrite
```

> **权限**：需要 `docs:document.content:read` scope。此命令**不支持 `--format` flag**。
>
> **用途**：读取导出的 Markdown 文件，提取上期数据概览和 Action Items，用于 Step 6 的趋势对比和 Step 5c 的行动项追踪。
>
> **如果未授权或导出失败**：回退到仅用 `docs +search` 结果中的标题和摘要进行粗略对比。

### 5c: 追踪并关闭上期行动项（需 `task` 域授权）

如果上期回顾创建了飞书任务作为 Action Items，自动追踪它们的状态：

```bash
# 搜索上期创建的行动项任务
lark-cli task +get-my-tasks --query "Sprint 回顾" --complete
lark-cli task +get-my-tasks --query "Sprint 回顾"

# 对已完成的行动项，标记为完成并添加备注
lark-cli task +complete --task-id "<task_guid>"
lark-cli task +comment --task-id "<task_guid>" --content "在 Sprint W14 回顾中确认已完成"

# 对未完成的行动项，添加跟踪备注
lark-cli task +comment --task-id "<task_guid>" --content "Sprint W14 回顾：仍在进行中，继续跟踪"
```

> **⚠️ 关闭行动项前需要用户确认**：列出上期行动项的当前状态，让用户确认哪些已完成、哪些仍在进行。
>
> **`task +complete`** 只需要 `--task-id`（guid 格式），返回 `ok: true` 表示成功。
>
> **`task +comment`** 需要 `--task-id` 和 `--content`，用于记录关闭原因或跟踪状态。
>
> **⚠️ `--task-id` 必须传 UUID 格式的 `guid`**（如 `3f69e180-4fe3-46cb-9d45-dc2084720793`），不能传短 ID（如 `t1000xx`）。`guid` 从 `task +create` 或 `task +get-my-tasks` 的返回结果中获取。`--tasklist-id` 同理。

---

## Step 6: AI 生成回顾报告

将 Step 2-5 的数据交给 AI，按以下模板生成结构化报告：

```markdown
# 🔄 Sprint 回顾报告 — {周期标识} ({start_date} ~ {end_date})

> 由 lark-retro 自动生成 | 数据来源：📅 Calendar · ✅ Tasks · 💬 IM · 📄 Docs

## 📊 数据概览

| 指标 | 数值 | 趋势 |
|------|------|------|
| 📅 日程事件 | {n} 个 | {vs上期} |
| ⏱️ 会议占比 | {x}%（{h}小时/{total_h}工作小时） | {vs上期} |
| ✅ 任务完成率 | {done}/{total} = {rate}% | {vs上期} |
| 🚧 未关闭 Blocker | {b} 个 | — |

## 📋 数据质量说明

{标注哪些数据源已采集、哪些未采集及原因}
{如：📅 日程数据 ✅ | ✅ 任务数据 ❌（无任务）| 💬 消息数据 ❌（未授权）| 📄 上期报告 ❌（未找到）}

## 🌟 What Went Well

{从以下数据源自动提取：}
{- 按时完成的重要任务}
{- 完成率高于上期}
{- 消息中的正面反馈}
{- 会议效率提升}

1. **{emoji} {标题}**：{具体描述，引用数据}...
2. ...
3. ...

## ⚠️ What Could Be Improved

{从以下数据源自动提取：}
{- 未完成/延期的任务}
{- 消息中的 blocker/风险讨论}
{- 会议占比过高（>50%）}
{- 超时会议}

1. **{emoji} {标题}**：{具体描述，引用数据}...
2. ...
3. ...

## 🎯 Action Items

| # | 改进项 | 负责人 | 截止日期 |
|---|--------|--------|----------|
| 1 | {emoji} {具体可执行的改进行动} | {从任务/消息推断} | {建议日期} |

## 🔁 上期行动项追踪

{如果找到上期回顾报告或任务，自动追踪行动项完成情况}

| # | 上期行动项 | 状态 | 操作 | 备注 |
|---|-----------|------|------|------|
| 1 | ... | ✅ 已完成 / 🔄 进行中 / ❌ 未开始 | task +complete 已执行 / 添加了跟踪备注 | ... |
```

### 周报模式模板

当 Step 1 判断为**周报模式**时，使用以下模板替代回顾模板：

```markdown
# 📋 工作周报 — {周期标识} ({start_date} ~ {end_date})

> 由 lark-retro 自动生成 | 数据来源：📅 Calendar · ✅ Tasks · 💬 IM · 📄 Docs

## 📊 本周概览

| 指标 | 数值 |
|------|------|
| 📅 会议数 | {n} 个（{h} 小时） |
| ✅ 完成任务 | {done} 个 |
| 🔄 进行中 | {in_progress} 个 |
| ⏰ 延期未完成 | {overdue} 个 |

## ✅ 本周完成

{从日历事件和已完成任务中提取，按重要程度排序}

1. **{emoji} {事项}**：{具体成果，引用数据}
2. ...
3. ...

## 📅 下周计划

{从未完成任务、下周日历事件、本周延期项中推断}

1. **{emoji} {计划事项}**：{预期目标 / 关键节点}
2. ...
3. ...

## 🙋 需要支持

{从 Blocker、延期任务、风险讨论中提取，如无则写"暂无"}

1. **{emoji} {事项}**：{需要谁的什么支持}
2. ...
```

**周报模式的特殊规则：**
- "下周计划"需要额外查询下周日历：`lark-cli calendar +agenda --start "{下周一}" --end "{下周五}"`，从中提取已安排的重要会议和事件
- "需要支持"如果数据中没有明确的 Blocker，写"暂无"即可，不要硬凑
- 周报语气偏向**汇报总结**，不需要回顾模式的改进分析深度
- 不包含"上期行动项追踪"章节

---

**AI 分析规则：**
1. "What Went Well" 和 "What Could Be Improved" 各列 3-5 条，**必须基于数据**而非泛泛而谈
2. Action Items 必须具体、可执行、有负责人和截止日期
3. 趋势对比：如果找到上期报告，自动计算变化趋势（↑/↓/→）；如果是首次回顾（无上期数据），隐藏趋势列，在表头标注"（首次回顾，无趋势数据）"
4. 语气中立客观，不过分乐观也不过分悲观
5. 如果某个数据源没有授权或数据为空，在报告中注明"（未采集）"而非留白
6. **数据充分性判断（重要）**：在生成报告前，先评估有效数据量：
   - **充分**：去重后日程 >= 3 个 且（任务数 >= 1 或 高质量消息 >= 3 条）→ 正常生成完整报告
   - **任务主导型周期**：去重后有效日程 < 3 个，但任务数 >= 3 → 生成以任务进展、完成率、未完成项和交付节奏为主的精简报告，明确标注"本周期会议数据较少，报告主要基于任务数据"
   - **基本可用**：仅日程数据有效（去重后 >= 3 个），其他数据源为空 → 生成以时间分配分析为主的精简报告，明确标注"本报告仅基于日历数据，建议补充任务/消息数据以获得更全面的洞察"
   - **不足**：去重后有效日程 < 3 个 且 任务为空 且 高质量消息 < 3 条 → **不硬凑报告**，改为输出"本周期有效工作数据不足以生成有价值的回顾报告"，并列出各数据源的实际状态和补充建议
7. **避免空泛表述**：每一条 "What Went Well" / "What Could Be Improved" 必须引用具体数据（事件名称、任务标题、消息原文片段、具体数字）。禁止出现"工作效率有所提升""沟通有待加强"等无数据支撑的泛化表述
8. **Emoji 视觉增强**：报告中应在标题、表格指标、每条洞察和行动项前添加语义相关的 emoji，提升可读性和视觉层次。规则：
   - 章节标题：📊 数据概览、🌟 What Went Well、⚠️ What Could Be Improved、🎯 Action Items、🔁 上期行动项追踪
   - 数据概览表指标：📅 日程、⏱️ 会议、✅ 任务、🚧 Blocker
   - 每条洞察开头加一个与内容匹配的 emoji（如 📈 提升、⏱️ 时间、🤝 协作、🚧 阻塞、⏰ 延期、🐛 Bug）
   - Action Items 每行开头加一个动作型 emoji（如 🔧 修复、📝 文档、🕐 调整、🐛 排查）
   - 不要过度堆砌，每个独立信息点前最多 1 个 emoji

---

## Step 7: 创建回顾文档（⚠️ 需用户确认）

**创建文档前，先展示报告预览并询问用户**：是否创建文档？是否归档到知识库？

```bash
# 路径 A：创建独立文档（默认）
lark-cli docs +create --title "Sprint 回顾 {周期标识}" --markdown "<报告内容>"

# 路径 B：归档到个人知识库
lark-cli docs +create --title "Sprint 回顾 {周期标识}" \
  --markdown "<报告内容>" \
  --wiki-space "my_library"

# 路径 C：归档到指定知识库节点下（进阶）
lark-cli docs +create --title "Sprint 回顾 {周期标识}" \
  --markdown "<报告内容>" \
  --wiki-node "<parent_node_token>"
```

> ⚠️ `--wiki-space`、`--wiki-node`、`--folder-token` 三者**互斥**，只能选一个。同时传会报错。
>
> **返回值**：`doc_id`、`doc_url`（wiki 路径）。后续通知需要用到 `doc_url`。
> **注意**：`docs +create` 不支持 `--format` flag。
> 如果用户未指定归档方式，默认用路径 A 创建独立文档。

## Step 8: 创建行动项任务（⚠️ 需用户确认）

### 8a: 创建任务列表（可选）

为本次回顾的行动项创建专属任务列表，方便分组管理：

```bash
# 创建回顾专属任务列表
lark-cli task +tasklist-create --name "Sprint 回顾 {周期标识} Action Items"
# 返回 tasklist guid
```

### 8b: 创建行动项任务

对报告中的每个 Action Item，自动创建飞书任务：

```bash
# --due 支持格式：YYYY-MM-DD / ISO 8601 完整格式 / Unix 时间戳（毫秒）
# ⚠️ 不要用 "date:YYYY-MM-DD" 前缀格式，直接传日期字符串
# --summary 为任务标题
# --assignee 可选，指定负责人 open_id
# --description 可选，补充描述
lark-cli task +create --summary "<行动项描述>" --due "2026-04-08" --assignee "<open_id>"
```

### 8c: 将任务添加到列表（可选，配合 8a）

```bash
# 将创建的任务添加到回顾任务列表
lark-cli task +tasklist-task-add --tasklist-id "<tasklist_guid>" --task-id "<task_guid>"
```

> **⚠️ 安全**：创建任务前列出所有待创建的任务，**先让用户确认**再批量创建。可用 `--dry-run` 预览。
> **返回值**：`guid`（任务 ID）和 `url`（任务深链接）。

## Step 9: 群聊通知（可选 — ⚠️ 需用户确认 + bot 身份）

**发送通知前必须先询问用户是否需要通知。**

```bash
# 发送到群聊（⚠️ 必须显式指定 --as bot）
lark-cli im +messages-send --as bot --chat-id "<chat_id>" \
  --markdown "**Sprint 回顾已生成**\n\n完成率 {rate}% | {blocker_count} 个待处理项\n\n[查看完整报告]({doc_url})"

# 或发送私信（--user-id 与 --chat-id 互斥，只能选一个）
lark-cli im +messages-send --as bot --user-id "<open_id>" \
  --markdown "你的 Sprint 回顾已生成：{doc_url}"
```

> **⚠️ 必须显式写 `--as bot`**，不加可能默认落到 user 身份而报错。bot 需要应用已配置 bot 能力且 bot 已加入目标群聊。
> **如果用户未配置 bot 或未提供群聊 ID**，跳过通知步骤，在最终输出中直接展示文档链接即可。

---

## `--jq` 优化技巧

lark-cli 支持 `--jq` / `-q` 参数对 JSON 输出进行实时过滤，可显著减少数据量：

```bash
# 日程：仅提取摘要和时间
lark-cli calendar +agenda --start "..." --end "..." \
  -q '.data | .[] | {summary, start: .start_time.datetime, end: .end_time.datetime}'

# 任务：仅提取标题、截止日期和完成状态
lark-cli task +get-my-tasks \
  -q '.data.items | .[] | {summary, due, completed_at: .completed_at}'

# 消息搜索：仅提取发送者和内容
lark-cli im +messages-search --query "..." \
  -q '.data.messages | .[] | select(.sender.sender_type == "user") | {sender: .sender.id, content: .body.content[:200]}'
```

> **使用注意**：`--jq` 仅在结果为 JSON 且 `items`/`data` 非 null 时有效。如果目标字段可能为 null（如 `items: null`），直接用不带 `--jq` 的方式获取后判断。

---

## 权限表

| 命令 | 授权方式 | 是否必须 |
|------|---------|----------|
| `calendar +agenda` | `--domain calendar` | 是（必须） |
| `task +get-my-tasks` | `--domain task` | 推荐（增强） |
| `task +create` | `--domain task` | 推荐（增强） |
| `task +complete` | `--domain task` | 推荐（行动项关闭） |
| `task +comment` | `--domain task` | 推荐（行动项备注） |
| `task +tasklist-create` | `--domain task` | 否（任务列表分组） |
| `task +tasklist-task-add` | `--domain task` | 否（配合任务列表） |
| `docs +create` | `--domain docs` | 是（必须） |
| `docs +search` | `--scope "search:docs:read"` | 否（增强） |
| `drive +export` | `--scope "docs:document.content:read"` | 否（历史报告导出） |
| `im +messages-search` | `--scope "search:message"` | 否（增强） |
| `im +chat-messages-list` | `im:message` scope | 否（替代搜索） |
| `im +messages-send` | `--as bot`，需在开发者后台开通 | 否（通知） |

## 错误处理

| 错误 | 原因 | 处理 |
|------|------|------|
| `missing_scope` | 未授权某 scope | 跳过对应步骤，报告中标注"（未采集）"，展示 `hint` 中的修复命令 |
| `items: null` | 时间范围内无数据 | 报告中标注"本周期无{日程/任务}数据"，基于其他数据源继续生成报告 |
| `rate_limit` | API 限流 | 等待几秒后重试，最多 3 次 |
| `permission denied` | 用户无权访问某资源 | 参考 lark-shared 中的权限处理流程 |
| `mutually exclusive` | `--wiki-space`/`--wiki-node`/`--folder-token` 同时使用 | 只能选其一，见 Step 7 |
| `unknown domain "doc"` | domain 参数拼写错误 | 必须用 `docs`（带 s），不是 `doc` |
| `unknown flag: --page-size` | `task +get-my-tasks` 不支持 `--page-size` | 用 `--page-all` 自动翻页 |
| `unknown flag: --format` | `docs +create` 和 `drive +export` 不支持 `--format` | 去掉此 flag |

## 参考

- [lark-shared](../lark-shared/SKILL.md) — 认证、权限、安全规则（**必读**）
- [lark-calendar](../lark-calendar/SKILL.md) — `+agenda` 详细用法
- [lark-task](../lark-task/SKILL.md) — `+get-my-tasks`、`+create`、`+complete`、`+comment` 详细用法
- [lark-doc](../lark-doc/SKILL.md) — `+create`、`+search` 详细用法
- [lark-im](../lark-im/SKILL.md) — `+messages-search`、`+messages-send`、`+chat-messages-list` 详细用法
- [lark-drive](../lark-drive/SKILL.md) — `+export` 详细用法
