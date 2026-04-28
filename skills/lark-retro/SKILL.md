---
name: lark-retro
version: 2.6.6
description: "Sprint/周期回顾工作流：自动从日历（含会议纪要/会议录制记录）、OKR、审批、任务、消息、文档、画板中采集数据，AI 生成结构化报告，并追踪改进项闭环。支持 OKR 对齐分析、审批阻塞信号补强、历史文档权限申请补救、自有云文档搜索增强、@提及消息过滤、行动项自动关闭、任务列表自定义分组、历史报告对比、Bitable 归档、记录分享链接、报告空间初始化、报告快捷方式归档、预约并更新下期回顾会议室。当用户需要做回顾、复盘、retrospective、周报总结时使用。"
metadata:
  requires:
    bins: ["lark-cli"]
    cliHelp: "lark-cli calendar --help && lark-cli task --help && lark-cli approval --help && lark-cli docs --help && lark-cli wiki --help && lark-cli drive --help && lark-cli im --help && lark-cli minutes --help && lark-cli vc --help && lark-cli okr --help && lark-cli base --help && lark-cli whiteboard --help"
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
- "把上期的行动项记录到多维表格" / "log action items to bitable"
- "预约一下下周的回顾会议室" / "book retro room"
- "把这周会议录制也纳入回顾" / "include meeting recordings"

## 前置条件

仅支持 **user 身份**（`--as user`，calendar/task/docs 默认）。执行前确保已授权所需业务域：

```bash
# 最低可用授权（日历 + 文档）
lark-cli auth login --domain calendar,docs

# 推荐授权（日历 + 任务 + 文档 + 多维表格）
lark-cli auth login --domain calendar,task,docs,base

# 可选增强（消息搜索 + 文档搜索 + 妙记）
lark-cli auth login --scope "search:message search:docs:read minutes:minute:read"

# 可选增强（会议录制/会议记录搜索，lark-cli v1.0.9+）
lark-cli auth login --scope "vc:record:readonly"

# 可选增强（导出历史报告为 Markdown 做趋势对比）
lark-cli auth login --scope "docs:document.content:read"

# 可选增强（lark-cli v1.0.10+：报告快捷方式、标题修正、知识库成员只读预检）
lark-cli auth login --scope "space:document:shortcut space:document:retrieve space:folder:create docx:document:write_only wiki:member:retrieve"

# 可选增强（lark-cli v1.0.14+：OKR 对齐、知识空间初始化、用户身份富媒体通知）
lark-cli auth login --scope "okr:okr.period:readonly okr:okr.content:readonly wiki:space:write_only im:message im:message.send_as_user"

# 可选增强（lark-cli v1.0.15+：审批阻塞信号只读补强）
lark-cli auth login --scope "approval:instance:read approval:task:read"

# 可选增强（lark-cli v1.0.17+：历史文档权限申请补救）
lark-cli auth login --scope "docs:permission.member:apply"
```

> **最低可用**：`calendar,docs` 即可生成基于时间分配的基础报告。加 `task` 后可分析任务完成率。多次 login 的 scope 会累积。
>
> ⚠️ domain 必须用 `docs`（带 s），`doc` 会被 CLI 拒绝。

## 能力分层

| 层级 | 功能 | 所需授权 |
|------|------|---------|
| **基础版** | 日历分析 + 文档输出 | `--domain calendar,docs` |
| **增强版** | + 任务追踪 + 行动项关闭 | `--domain calendar,task,docs` |
| **高级版** | + 消息分析 + 文档搜索 + 知识库归档 + 会议纪要/会议记录分析 + OKR 对齐 + 审批阻塞信号 | + `--scope "search:message search:docs:read minutes:minute:read vc:record:readonly okr:okr.period:readonly okr:okr.content:readonly approval:instance:read approval:task:read"` |
| **完整版** | + Bitable 归档 + 记录分享链接 + 会议室预约 + 画板分析 + 报告空间初始化/快捷方式归档 + 文档权限申请补救 | + `--domain base` + bot 能力 + `space:folder:create wiki:space:write_only space:document:shortcut docs:permission.member:apply` |

缺少某一层的授权时，对应模块自动跳过，不影响其他功能。报告中标注"（未采集 — 需 `<具体授权命令>`）"。

## 工作流总览

```
Step 1: 确定报告模式 & 时间范围（推断用户意图 → 用系统命令计算 start/end）
    │
    ├─► Step 2: calendar +agenda ──────────► 日程数据（时间分配）
    │    └─► minutes minutes get ──────────► 会议纪要深度分析（v1.0.7）
    ├─► Step 2b: vc +search / +notes ───────► 会议录制/会议记录补强（可选, v1.0.9）
    ├─► Step 2c: okr +cycle-list/+cycle-detail ─► OKR 目标/KR 对齐（可选, v1.0.14）
    ├─► Step 3: task +get-my-tasks ─────────► 任务完成情况
    ├─► Step 3b: approval instances/tasks ─► 已发起审批 / 待处理审批阻塞（可选, v1.0.15）
    ├─► Step 4: im +messages-search ────────► 关键讨论 & Blocker（可选）
    ├─► Step 4b: whiteboard +query ─────────► 画板脑暴背景（可选, v1.0.8）
    ├─► Step 5a: drive +search / docs +search ─► 上期回顾上下文（可选, v1.0.20 增强）
    ├─► Step 5b: drive +export ─────────────► 导出上期报告全文对比（可选）
    ├─► Step 5d: drive +apply-permission ───► 历史文档权限申请补救（可选, v1.0.17）
    │
    ▼
Step 5c: 追踪上期行动项（task +complete / +comment）
    │
    ▼
Step 6: AI 分析 & 生成结构化回顾报告
    │
    ├─► Step 7: docs +create ──────────────► 创建回顾文档（⚠️ 用户确认）
    ├─► Step 7c: drive +create-folder/+create-shortcut ─► 报告文件夹与快捷方式归档（可选, v1.0.13）
    ├─► Step 7e: docs +media-insert ───────► 插入报告附件/录屏（可选, v1.0.14）
    ├─► Step 8: task +create ──────────────► 创建行动项任务 + 任务列表（⚠️ 用户确认）
    ├─► Step 8d: base +record-batch-create ──► 归档到多维表格（可选, v1.0.8）
    ├─► Step 8e: base +record-share-link-create ─► 记录分享链接（可选, v1.0.17）
    ├─► Step 9: im +messages-send ──────────► 群聊通知（⚠️ 用户确认，需 bot）
    ├─► Step 10: calendar +room-find ────────► 预约下期回顾会议室（⚠️ 用户确认, v1.0.8）
    └─► Step 10b: calendar +update ─────────► 调整下期回顾时间/标题/参会人（可选, v1.0.20）
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

## Step 2: 采集日程 & 会议纪要数据

```bash
# 获取指定时间范围的日程
lark-cli calendar +agenda --start "<start_date>" --end "<end_date>"

# 💡 v1.0.7 增强：如果日程包含会议纪要（minutes），可通过以下命令获取内容分析
lark-cli minutes minutes get --minute_token "<token_from_agenda>"
```

> **重要**：从 `calendar +agenda` 的响应中提取 `minute_token`（如有）。如果存在会议纪要，将其摘要纳入分析，作为洞察的深度数据源。

**从日程数据中提取：**
- 会议总数和总时长
- **会议纪要洞察（v1.0.7+）**：提取纪要中的关键结论和遗留问题
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
   - **展示可合并，统计不可丢失**：报告列表中可合并为一条展示，但指标仍要保留真实发生次数与用户实际参加时长总和；重复站会计入多次，城市并行会只计入用户实际参加的实例

## Step 2b: 采集会议录制/会议记录（可选 — v1.0.9+）

当 `calendar +agenda` 没有返回 `minute_token`，或用户明确要求纳入会议录制/会议记录时，使用 `vc +search` 在同一时间范围内补充会议上下文：

```bash
# 按时间范围搜索会议录制/会议记录（先不加关键词，避免漏掉标题不规范的会议）
lark-cli vc +search --start "<start_date>" --end "<end_date>" --page-size 15

# 如果结果过多，再用回顾相关关键词收窄
lark-cli vc +search --query "回顾" --start "<start_date>" --end "<end_date>" --page-size 15

# 对相关会议 ID 获取会议记录/纪要文档 token
lark-cli vc +notes --meeting-ids "<meeting_id_1>,<meeting_id_2>" \
  --output-dir "./lark-retro-vc-notes" --overwrite

# 对返回的 note_doc_token / verbatim_doc_token 读取正文
lark-cli docs +fetch --doc "<note_doc_token>"
```

> **实测边界**：`vc +search` 可按时间范围返回会议录制候选；`vc +notes` 可返回 `note_doc_token`、`shared_doc_tokens`、`verbatim_doc_token`。如果 `vc +recording` 或相关步骤报 `missing_scope: vc:record:readonly`，跳过会议录制分析，并在报告中标注"（会议录制未采集 — 需要 `lark-cli auth login --scope "vc:record:readonly"` 授权）"。
>
> **相关性过滤（重要）**：不要把时间范围内所有会议录制都直接纳入报告。优先保留满足以下条件之一的会议：
> - 会议标题/`display_info` 与 `calendar +agenda` 的日程标题、时间接近。
> - 标题包含回顾、复盘、周会、项目名、评审、同步、standup、weekly 等关键词。
> - 用户明确点名的会议或会议 ID。
>
> **无结果处理**：`items: []` 不代表没有会议，只代表未搜索到可访问的会议录制/记录。报告中标注"会议录制未找到可访问结果"，不要影响日历/任务/消息主流程。

**从会议记录中提取：**
- 会议 ID、标题、组织者、时间、是否外部会议/重复日程
- `note_doc_token`、`shared_doc_tokens`、`verbatim_doc_token`（如有）
- 关键结论、待办、争议点、未闭环问题
- 与日历/任务/消息数据交叉验证出的 Blocker

## Step 2c: 采集 OKR 目标/KR（可选 — v1.0.14+）

当用户明确希望做目标对齐、季度复盘、OKR 复盘，或本周期报告需要回答"这些忙碌是否支持目标"时，使用 OKR 只读数据作为增强输入：

```bash
# 先获取当前用户在指定月份范围内的 OKR 周期
lark-cli okr +cycle-list \
  --user-id "<open_id>" \
  --user-id-type open_id \
  --time-range "2026-01--2026-04"

# 对相关周期读取目标与关键结果
lark-cli okr +cycle-detail --cycle-id "<cycle_id>"
```

> **实测边界（v1.0.14）**：`okr +cycle-list` 必须显式传 `--user-id`；缺少 `okr:okr.period:readonly` 会报 `missing_scope`。`okr +cycle-detail` 需要 `okr:okr.content:readonly`。如果缺少 OKR 权限，跳过本步骤，并在报告中标注"OKR 未采集 — 需要 `lark-cli auth login --scope "okr:okr.period:readonly okr:okr.content:readonly"` 授权"。
>
> **安全边界**：lark-retro 只读取 OKR，不创建、不修改、不删除目标或关键结果。

**从 OKR 数据中提取：**
- 周期 ID、周期起止时间、周期状态、周期得分
- Objective 标题、权重、得分、截止时间
- Key Result 标题、权重、得分、截止时间
- 与会议、任务、消息中的工作主题做对齐：支持哪些目标、偏离哪些目标、哪些 KR 存在风险

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

## Step 3b: 采集审批阻塞信号（可选 — v1.0.15+）

当团队大量依赖采购、权限、法务、报销、用印等审批流时，审批数据可以补强“为什么某些任务没推进”的证据链。这里默认只做只读采集，不做催办。

```bash
# 查询当前用户已发起的审批实例
lark-cli approval instances initiated --params '{"page_size":20,"locale":"zh-CN"}'

# 查询当前用户待处理/已处理审批任务列表
lark-cli approval tasks query --params '{"page_size":20,"locale":"zh-CN"}'
```

> **实测边界（v1.0.15）**：`approval instances initiated` 的 schema 已验证为只读接口，scope 为 `approval:instance:read`；`approval tasks query` 需要 `approval:task:read`。如果缺少审批权限，跳过本步骤，并在报告中标注"审批未采集 — 需要 `lark-cli auth login --scope "approval:instance:read approval:task:read"` 授权"。
>
> **安全边界**：`approval tasks remind` 是危险写操作，会真实催办审批人，默认不纳入回顾主流程。只有当用户明确说“顺便帮我催办这些审批”并确认实例 code / task_ids 后，才允许单独执行。

**从审批数据中提取：**
- 本周期已发起审批数、审批类型分布、典型审批主题
- 仍待处理或停留较久的审批实例，作为潜在 Blocker 或外部依赖
- 审批阻塞与任务/会议/消息中提到的问题是否一致
- 需要外部团队支持的事项是否长期卡在审批链路上

> **分析原则**：审批数据是“阻塞信号补强”，不是绩效考核素材。报告里只引用与项目推进直接相关的审批趋势，不展开敏感审批正文。

## Step 4: 采集消息数据（可选）

详情参考 v2.2.0。支持方式 A（消息搜索，需 `search:message`）和方式 B（群聊消息列表，需 `im:message`）。

**噪声过滤规则（重要）**：必须执行第零层（来源相关性）、第一层（类型排除）、第二层（关键词排除）、第三层（内容质量保留）过滤。

### v1.0.20 搜索增强：按 @提及对象收窄消息

当用户明确要看“@我”的催办、“@某负责人”的 blocker，或想减少群聊搜索噪声时，优先在方式 A 上叠加提及过滤：

```bash
# 只看 @我 的消息
lark-cli im +messages-search \
  --as user \
  --is-at-me \
  --chat-type group \
  --start "<start_date>" \
  --end "<end_date>"

# 只看 @指定同事/负责人 的消息（open_id）
lark-cli im +messages-search \
  --as user \
  --at-chatter-ids "<open_id>" \
  --chat-type group \
  --start "<start_date>" \
  --end "<end_date>"
```

> **实测边界（v1.0.20）**：命令和参数面已验证，当前测试账号在 2026-04 的真实搜索结果为 `items: []`。因此 0 结果只能说明“当前检索条件下没有可见命中”，**不能**据此断言没有相关讨论。应立即回退到更宽的 `im +messages-search` 或 `im +chat-messages-list`。

## Step 4b: 采集画板背景（可选 — v1.0.8+）

如果团队在回顾前使用了画板（Whiteboard）进行脑暴，AI 可以通过导出画板图片或节点数据来获取背景：

```bash
# 导出画板为预览图片或节点数据
lark-cli whiteboard +query --whiteboard-token "<token>" --output_as image --output "./whiteboard-preview"
```

> **用途**：读取画板中的文字节点或导出的图片分析（如有 OCR），作为回顾报告中“背景”或“脑暴成果”部分的输入。

## Step 5: 采集上期回顾上下文（可选）

### 5a: 精确搜索上期报告（v1.0.20+ 优先，v1.0.7+ 回退）

采用**“Drive 搜索优先，旧版 docs 搜索兜底”**策略，优先利用 v1.0.20 的自有云文档过滤能力缩小范围。

#### 1. Drive 搜索优先（推荐）
```bash
# 先按标题关键词 + 我编辑过的文档搜索
lark-cli drive +search \
  --as user \
  --query "Sprint 回顾" \
  --mine \
  --only-title \
  --doc-types docx \
  --edited-since 90d \
  --sort edit_time

# 如果知道大致目录，优先按 folder token 收窄
lark-cli drive +search \
  --as user \
  --query "回顾" \
  --folder-tokens "<folder_token>" \
  --only-title

# 如果是知识库空间里的历史回顾，可按 wiki space 收窄
lark-cli drive +search \
  --as user \
  --query "Retro" \
  --space-ids "<space_id>" \
  --only-title
```

#### 2. 评论/编辑轨迹补强（可选）
```bash
# 看最近我编辑过或评论过的相关文档
lark-cli drive +search --as user --query "回顾" --edited-since 30d --only-title
lark-cli drive +search --as user --query "回顾" --commented-since 30d --only-title
```

#### 3. 旧版 docs 精确回退
```bash
# 使用 v1.0.7 的 --filter 实现标题精确匹配
lark-cli docs +search --query "Sprint 回顾报告" --filter '{"title_only": true, "exact_match": true}'

# 如果知道 wiki space，可继续收窄
lark-cli docs +search --query "回顾" --filter '{"wiki_space_ids": ["<space_id>"], "title_only": true}'
```

#### 4. 广搜回退（保底）
如果仍无结果，依次尝试模糊关键词：
```bash
lark-cli docs +search --query "Sprint 回顾"
lark-cli docs +search --query "Retro"
lark-cli docs +search --query "周报"
```

> **v1.0.20 优势**：`drive +search` 可直接按“我创建/我编辑/我评论过”、文档类型、文件夹、知识空间来收窄，适合在个人云文档很多的情况下优先定位历史报告。
>
> **实测边界（v1.0.20）**：当前测试账号上，`drive +search` 对新建临时文档和 `--mine --created-since 1d` 的真实查询均返回 0 结果；说明它依赖搜索索引和租户可见性，不适合做唯一入口。只要 `drive +search` 返回 0，就要立刻回退到 `docs +search` 和标题变体，不要阻塞主流程。
>
> **⚠️ 搜索限制**：
> - 新创建的文档可能需要数分钟甚至更久才能被搜索索引收录。
> - 标题命名不一致时可能搜不到（如用户把报告命名为"本周复盘"而非"Sprint 回顾"）。
> - `drive +search --query` 长度过长会报字段校验错误；长标题请拆成更短关键词组合。
> - 若所有查询均返回 0 结果，**不代表没有历史文档**，在报告中标注"（未找到上期报告 — 可能因标题命名、索引延迟或搜索可见性限制，趋势对比不可用）"。

**用途**：查找是否有之前的回顾报告，用于趋势对比和上期行动项追踪。

### 5b: 导出上期报告全文（可选 — 需 `docs:document.content:read` scope）

如果在 Step 5a 中找到了上期回顾报告的 `doc_token`，可以导出为 Markdown 做更精确的趋势对比：

```bash
# 将上期回顾报告导出为 Markdown 文件
# ⚠️ output-dir 建议用当前目录下的相对路径，不要直接传 /tmp 等绝对路径
mkdir -p ./lark-retro-export && cd ./lark-retro-export
lark-cli drive +export --token "<doc_token>" --doc-type docx \
  --file-extension markdown --output-dir . --overwrite
```

> **权限**：需要 `docs:document.content:read` scope。此命令**不支持 `--format` flag**。
>
> **用途**：读取导出的 Markdown 文件，提取上期数据概览和 Action Items，用于 Step 6 的趋势对比和 Step 5c 的行动项追踪。
>
> **如果未授权或导出失败**：回退到仅用 `docs +search` 结果中的标题和摘要进行粗略对比。

### 5d: 对历史报告发起权限申请（可选 — v1.0.17+）

如果 Step 5a/5b 已经定位到历史文档，但 `docs +fetch` / `drive +export` 因权限不足失败，且用户明确同意向文档 Owner 发起申请，可以使用权限申请作为补救链路：

```bash
# 先 dry-run 预览请求，确认不会误发给错误对象
lark-cli drive +apply-permission \
  --token "https://example.larksuite.com/docx/doxcnxxxxxxxxx" \
  --perm view \
  --remark "Sprint 回顾趋势对比：申请查看历史回顾文档" \
  --as user --dry-run

# 用户确认后再真实发起
lark-cli drive +apply-permission \
  --token "https://example.larksuite.com/docx/doxcnxxxxxxxxx" \
  --perm view \
  --remark "Sprint 回顾趋势对比：申请查看历史回顾文档" \
  --as user
```

> **实测边界（v1.0.17 官方 reference）**：`drive +apply-permission` 仅支持 `user` 身份，scope 为 `docs:permission.member:apply`，只允许申请 `view` 或 `edit`，不支持 `full_access`。它会真实给 Owner 发送卡片通知，因此默认**不要自动执行**。
>
> **频率限制**：同一用户对同一篇文档每天最多 5 次。若命中文档不接受申请或次数超限，报告中应标注"历史文档已定位但当前无读取权限"，并建议用户手动联系 Owner，不要死循环重试。
>
> **适用范围**：这是历史文档/知识库内容读取失败时的补救动作，不影响主回顾流程。如果用户没有明确授权申请动作，就保持降级，不要代替用户发起请求。

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

将 Step 2-5 的数据交给 AI，按模板生成结构化报告。

### AI 分析规则：
1. "What Went Well" 和 "What Could Be Improved" 各列 3-5 条，**必须基于数据**而非泛泛而谈。
2. Action Items 必须具体、可执行、有负责人和截止日期。
3. 趋势对比：如果找到上期报告，自动计算变化趋势（↑/↓/→）；如果是首次回顾（无上期数据），隐藏趋势列，在表头标注"（首次回顾，无趋势数据）"。
4. 语气中立客观，不过分乐观也不过分悲观。
5. 如果某个数据源没有授权或数据为空，在报告中注明"（未采集）"而非留白。
6. **数据充分性判断（重要）**：评估有效数据量，不足时不硬凑报告。
7. **避免空泛表述**：每一条洞察必须引用具体数据（事件名称、任务标题、消息原文、具体数字）。
8. **Emoji 输出契约（必须执行，不是可选美化）**：最终写入飞书文档的 Markdown 必须包含适量语义 emoji，缺失时必须先重写报告，不得进入 Step 7。

### Emoji 输出契约（创建文档前必须自检）

使用下面的固定骨架生成报告，不要输出无 emoji 的纯文本标题：

```markdown
# 🔄 Sprint 回顾报告 — {周期标识}

> 由 lark-retro 自动生成 | 数据来源：📅 Calendar · ✅ Tasks · 💬 IM · 📄 Docs · 🎯 OKR

## 📊 数据概览
| 指标 | 数值 | 说明 |
|------|------|------|
| 📅 日程事件 | ... | ... |
| ✅ 任务完成率 | ... | ... |
| 🚧 Blocker | ... | ... |

## 🌟 做得好的 / What Went Well
1. **📈 ...**：必须引用具体数据。

## ⚠️ 待改进 / What Could Be Improved
1. **🚧 ...**：必须引用具体数据。

## 🎯 行动项 / Action Items
| # | 改进项 | 负责人 | 截止日期 |
|---|--------|--------|----------|
| 1 | 🔧 ... | ... | ... |

## 🔁 上期行动项追踪
```

**Emoji 使用规则：**
- 一级标题必须以 `🔄`、`📊`、`📝`、`📈` 等语义 emoji 开头。
- 每个二级标题必须以 emoji 开头，例如 `📊` 数据概览、`🌟` 做得好的、`⚠️` 待改进、`🎯` 行动项、`🔁` 上期追踪、`📋` 数据质量说明。
- 数据概览表的每个指标名必须带 emoji，例如 `📅 日程事件`、`⏱️ 会议占比`、`✅ 任务完成率`、`🚧 Blocker`、`🎯 OKR 对齐度`。
- 每条洞察的加粗小标题必须带 emoji，例如 `**📈 任务完成率提升**`、`**🚧 支付沙箱仍阻塞测试**`。
- 每条行动项文本必须带 emoji，例如 `🔧 修复...`、`📝 补充...`、`🤝 对齐...`、`🧪 验证...`。
- 周报模式同样执行：`# 📝 工作周报`、`## ✅ 本周完成`、`## 📌 下周计划`、`## 🙋 需要支持`。

**创建文档前的硬性自检：**
- 如果报告正文少于 8 个 emoji，或者任一 H1/H2 标题没有 emoji，必须先重写 Markdown。
- 如果 Action Items 表的改进项列没有 emoji，必须先补齐。
- 只有自检通过后，才允许执行 `docs +create` 或 `docs +update`。

---

## Step 7: 创建回顾文档 & Wiki 归档（⚠️ 需用户确认）

**创建文档前，先展示报告预览并询问用户**：是否创建文档？是否归档到知识库？

> **v1.0.7+ 权限优化**：应用创建的文档会自动授予用户编辑权限，用户可直接点击 URL 进一步完善。lark-cli v1.0.13 后，应用创建知识库节点也会自动给当前用户授权，减少 bot 创建后用户打不开的问题。

### 路径 A：创建独立文档（默认）
lark-cli docs +create --title "Sprint 回顾 {周期标识}" --markdown "@retro-report.md"

### 路径 B：归档到知识库节点（v1.0.7+ 推荐）
```bash
# 使用 wiki +node-create 直接在指定空间创建节点，自动处理权限
lark-cli wiki +node-create --space-id "my_library" --title "Sprint 回顾 {周期标识}"

# 返回结果获取 node_token，再将内容写入该节点
lark-cli docs +update --doc "<node_token>" --markdown "@retro-report.md" --mode overwrite
```

> **注意**：`wiki +node-create` 默认会在个人知识库 `my_library` 下创建新节点。如果需要归档到特定父节点下，使用 `--parent-node-token`。

### 路径 B2：首次初始化回顾知识空间（可选 — v1.0.14+）
```bash
# 仅当用户明确要新建知识空间时执行；open_sharing 建议默认 closed
lark-cli wiki spaces create \
  --data '{"name":"团队回顾空间","description":"Sprint Retro / 周报 / 行动项沉淀","open_sharing":"closed"}'
```

> **实测边界（v1.0.14）**：`wiki spaces create --dry-run` 会请求 `POST /open-apis/wiki/v2/spaces`，body 支持 `name`、`description`、`open_sharing`。真实创建会新增知识空间，必须先展示空间名称、描述和分享状态并获得用户确认。需要 `wiki:space:write_only`，部分环境还会提示补 `wiki:wiki`。

### 路径 C：归档到特定知识库空间（旧版）
```bash
lark-cli docs +create --title "Sprint 回顾 {周期标识}" \
  --markdown "@retro-report.md" \
  --wiki-space "<space_id>"
```

> **⚠️ `@file` 必须使用相对路径**（如 `@retro-report.md` 或 `@./reports/retro.md`），不支持绝对路径。需要先 `cd` 到文件所在目录。也支持 `- for stdin`（管道输入）。

### 备选：直接传 markdown 字符串
```bash
# 短内容可以直接传字符串
lark-cli docs +create --title "Sprint 回顾 {周期标识}" --markdown "<报告内容>"
```

> ⚠️ `--wiki-space`、`--wiki-node`、`--folder-token` 三者**互斥**，只能选一个。同时传会报错。
>
> **返回值**：`doc_id`、`doc_url`（wiki 路径）。后续通知需要用到 `doc_url`。
> **注意**：`docs +create` 不支持 `--format` flag。
> 如果用户未指定归档方式，默认用路径 A 创建独立文档。

### Step 7b: 更新已有文档（可选 — v1.0.7+）
如果需要在已有回顾文档上追加内容（如更新行动项状态、添加后续跟踪笔记），使用 `docs +update`。

### Step 7c: 报告文件夹、标题修正与快捷方式归档（可选 — v1.0.10+/v1.0.13+）

如果用户希望把报告入口放到固定团队文件夹，或需要在生成后统一重命名标题，可使用云空间增强能力。

```bash
# v1.0.13+：如果还没有目标文件夹，可先创建报告文件夹
# 不传 --folder-token 时会落到当前用户云空间根目录；传入时放到指定父文件夹
lark-cli drive +create-folder \
  --name "Sprint 回顾 {周期标识}" \
  --folder-token "<parent_folder_token>"

# 可选：修正已有报告标题（仅在标题需要后改时使用）
lark-cli drive files patch \
  --params '{"file_token":"<doc_token>","type":"docx"}' \
  --data '{"new_title":"Sprint 回顾 W16"}'

# 可选：在指定文件夹创建报告快捷方式
lark-cli drive +create-shortcut \
  --file-token "<doc_token>" \
  --type docx \
  --folder-token "<target_folder_token>"
```

> **实测边界（v1.0.13/v1.0.10）**：`drive +create-folder --dry-run` 会请求 `POST /open-apis/drive/v1/files/create_folder`，不传 `--folder-token` 时 body 为 `folder_token: ""`，表示根目录；`drive files patch` 修改 docx 标题可用；`drive +create-shortcut` 仍需要有效目标 `folder_token`，`--folder-token ""` 会被 CLI 拒绝。创建快捷方式后，`drive files list --params '{"folder_token":"<target_folder_token>"}'` 会返回 `type: "shortcut"` 和 `shortcut_info.target_token`。
>
> **权限**：创建文件夹需要 `space:folder:create`（schema 也列出 `drive:drive`）；快捷方式需要 `space:document:shortcut`，读取文件夹清单验证需要 `space:document:retrieve`；标题修改 docx 需要 `docx:document:write_only`。
>
> **错误处理**：刚创建快捷方式后立即删除或重试可能遇到 `resource contention`，等待 3-5 秒后重试即可。此功能是报告沉淀增强，不影响主回顾流程。

### Step 7d: 知识库成员只读预检（可选 — v1.0.10+）

如果用户担心目标知识库空间权限不足，可先只读检查成员列表：

```bash
lark-cli wiki members list --params '{"space_id":"<space_id>","page_size":20}'
```

> **安全边界**：`wiki members create/delete` 会真实增删知识库成员，默认**不要执行**。只有当用户明确要求管理知识库成员、给出目标 `space_id`、`member_id`、`member_role`、`member_type`，并再次确认后，才可执行添加或移除。删除权限使用 `wiki:member:update`，不要写不存在的 `wiki:member:delete` scope。

### Step 7e: 插入报告附件/录屏（可选 — v1.0.14+）

如果用户已导出 PDF、录屏、音频或补充材料，希望把附件直接嵌到回顾文档末尾，可使用 `docs +media-insert`：

```bash
# 文件路径必须是当前工作目录内的相对路径
cd ./lark-retro-export

# 报告附件用 card；音视频回放材料可用 preview；需要贴近正文时用 inline
lark-cli docs +media-insert \
  --doc "<doc_token>" \
  --type file \
  --file ./retro-report.pdf \
  --file-view preview
```

> **实测边界（v1.0.14）**：`--file-view` 支持 `card`、`preview`、`inline`，dry-run 会展示"查询根 block → 创建 file block → 上传本地文件 → 绑定 file token"四步编排。真实执行会上传本地文件，必须先向用户展示文件路径、目标文档和展示方式。

> **v1.0.17 取舍说明**：官方新增了画板插图能力，但 lark-retro 当前仍只把画板作为输入背景，不把"向画板插图片"纳入默认复盘主流程，避免把展示型动作和分析型主链路混在一起。

---

## Step 8: 创建行动项任务（⚠️ 需用户确认）

### 8a: 创建任务列表 (v2.0+)
为本次回顾的行动项创建专属任务列表，方便分组管理：
```bash
lark-cli task +tasklist-create --name "Sprint 回顾 {周期标识} Action Items"
```

### 8b: 创建行动项任务
对报告中的每个 Action Item，自动创建飞书任务：
```bash
lark-cli task +create --summary "<行动项描述>" --due "<date>" --assignee "<open_id>"
```

### 8c: 将任务添加到列表
```bash
lark-cli task +tasklist-task-add --tasklist-id "<tasklist_guid>" --task-id "<task_guid>"

# lark-cli v1.0.10+：如果用户提供了清单自定义分组 section_guid，可直接放入该分组
lark-cli task +tasklist-task-add \
  --tasklist-id "<tasklist_guid>" \
  --task-id "<task_guid>" \
  --section-guid "<section_guid>"
```

> **实测边界（v1.0.10）**：`--section-guid` 只能传已有自定义分组的 `section_guid`。如果分组不存在，CLI 可能仍返回 `ok: true`，但 `data.failed_tasks` 会包含 `not_found`。因此执行后必须检查 `data.failed_tasks`，只要非空就不能判定成功，应提示用户检查分组或回退到不带 `--section-guid` 的默认清单添加。
>
> 如果用户没有提供可验证的 `section_guid`，不要猜测或伪造分组 ID，直接使用不带 `--section-guid` 的默认清单添加。
>
> **ID 格式**：`--task-id` 和 `--tasklist-id` 都必须传 UUID 格式的 `guid`，不能传短 ID（如 `t1000xx`）。

## Step 8d: 归档到多维表格（可选 — v1.0.8+）

如果用户指定了 Bitable 作为行动项仓库，使用批量写入功能：

```bash
# 将本次回顾的所有行动项批量写入多维表格
lark-cli base +record-batch-create --base-token "<base_token>" --table-id "<table_id>" \
  --json '{"fields":["标题","负责人","截止日期","状态"],"rows":[["修复 Bug","ou_123","2026-04-15","进行中"]]}'
```

> **v1.0.8 优势**：`+record-batch-create` 支持一次性写入所有 Action Items，效率远高于逐条创建。

## Step 8e: 生成行动项记录分享链接（可选 — v1.0.17+）

如果行动项已经写入 Bitable，且用户希望把每条记录的直达链接贴回复盘文档或通知消息，可为单条或批量记录生成分享链接：

```bash
# 单条或多条记录都可以，record_ids 最多 100 条
lark-cli base +record-share-link-create \
  --base-token "<base_token>" \
  --table-id "<table_id>" \
  --record-ids "rec001,rec002,rec003"
```

> **实测边界（v1.0.17 官方 reference）**：单次最多 100 条记录，重复 `record_id` 会自动去重；如果部分记录无权限或不存在，只会返回有效记录对应的 `record_share_links`。如果全部记录都不可读，会返回"records do not exist or no read permission"。
>
> **使用原则**：这是归档后的分享便利增强，不是主流程必需步骤。只有用户明确说"把行动项链接也带上"时才执行；默认不自动外发。

---

## Step 9: 群聊通知（可选 — ⚠️ 需用户确认 + bot 身份）

**发送通知前必须先询问用户是否需要通知。**

```bash
# 默认发送 Markdown 摘要到群聊（⚠️ 必须显式指定 --as bot）
lark-cli im +messages-send --as bot --chat-id "<chat_id>" \
  --markdown "**Sprint 回顾已生成**\n\n完成率 {rate}% | {blocker_count} 个待处理项\n\n[查看完整报告]({doc_url})"

# v1.0.13+ 可选：用户明确要求"用我的身份发送附件"时，发送本地报告文件
# 文件路径必须是当前工作目录内的相对路径，不能传绝对路径
cd ./lark-retro-export
lark-cli im +messages-send --as user --chat-id "<chat_id>" --file ./retro-report.pdf
```

> **实测边界（v1.0.13+）**：`im +messages-send --as user --file ./file` dry-run 会先上传文件并以 `msg_type: file` 发送；绝对路径会被 CLI 拒绝。此能力需要 `im:message im:message.send_as_user`，并且必须在发送前展示接收群、文件名和发送身份。默认仍推荐 bot Markdown 通知，避免用户身份误发。

---

## Step 10: 预约下期回顾会议室（可选 — ⚠️ 需用户确认, v1.0.8+）

生成报告后，自动建议下期回顾时间（如：下周五 16:00），并查找会议室：

```bash
# 查找下周五 16:00-17:00 的可用会议室
lark-cli calendar +room-find --slot "2026-04-17T16:00:00+08:00~2026-04-17T17:00:00+08:00" \
  --city "北京" --building "科技园" --min-capacity 5
```

> **工作流程**：
> 1. AI 计算下期回顾的建议时间。
> 2. 调用 `+room-find` 获取可用会议室列表。
> 3. 列出会议室供用户选择。
> 4. 确认后调用 `lark-cli calendar +create` 创建下期回顾日程并锁定会议室。

## Step 10b: 调整下期回顾日程（可选 — v1.0.20+）

如果下期回顾已经创建，但用户临时想改标题、时间、描述，或增删参会人/会议室，可直接在原事件上更新，而不是删掉重建：

```bash
# 修改标题、描述、开始/结束时间
lark-cli calendar +update \
  --as user \
  --event-id "<event_id>" \
  --summary "Sprint 回顾 W18（改期）" \
  --description "本次回顾改到周四晚，保留原议程" \
  --start "2026-04-30T20:30:00+08:00" \
  --end "2026-04-30T21:30:00+08:00"

# 可选：增删参会人或会议室（必须提供已验证的 ou_/oc_/omm_ ID）
lark-cli calendar +update \
  --as user \
  --event-id "<event_id>" \
  --add-attendee-ids "<user_or_room_id>" \
  --remove-attendee-ids "<user_or_room_id>"
```

> **实测结果（v1.0.20）**：已用真实临时事件完成 `calendar +create → calendar +update → calendar events get → calendar events delete` 闭环，成功更新 `summary`、`description`、`start/end`。更新响应会返回 `attendees_added_count` / `attendees_removed_count`，即使为 0 也可确认命令执行成功。
>
> **使用原则**：只有当用户明确说“改一下下期回顾时间/标题/参会人”时才执行；如果没有可靠的 `event_id`、`ou_` 或 `omm_`，不要猜测 ID。

---

## `--jq` 优化技巧
lark-cli 支持 `--jq` / `-q` 参数对 JSON 输出进行实时过滤，可显著减少数据量。

---

## 权限表

| 命令 | 授权方式 | 是否必须 |
|------|---------|----------|
| `calendar +agenda` | `--domain calendar` | 是 |
| `calendar +room-find` | `--domain calendar` | 否（会议室预约） |
| `calendar +update` | `--domain calendar` | 否（下期回顾日程调整） |
| `vc +search` | user 默认；必要时补 `--scope "vc:record:readonly"` | 否（会议录制搜索） |
| `vc +notes` | user 默认；必要时补 `--scope "vc:record:readonly"` | 否（会议记录补强） |
| `okr +cycle-list` | `--scope "okr:okr.period:readonly"`；必须传 `--user-id` | 否（OKR 周期读取） |
| `okr +cycle-detail` | `--scope "okr:okr.content:readonly"` | 否（OKR 目标/KR 读取） |
| `approval instances initiated` | `--scope "approval:instance:read"` | 否（审批已发起列表，只读） |
| `approval tasks query` | `--scope "approval:task:read"` | 否（审批任务列表，只读） |
| `approval tasks remind` | `--scope "approval:instance:write"` | 否（危险写操作，默认禁用） |
| `task +get-my-tasks` | `--domain task` | 推荐 |
| `task +create` | `--domain task` | 推荐 |
| `task +complete` | `--domain task` | 推荐 |
| `task +comment` | `--domain task` | 推荐 |
| `task +tasklist-create` | `--domain task` | 否 |
| `task +tasklist-task-add` | `--domain task`；自定义分组需已有 `section_guid` | 否 |
| `base +record-batch-create` | `--domain base` | 否（Bitable 归档） |
| `base +record-share-link-create` | `--domain base` | 否（Bitable 记录分享链接） |
| `docs +create` | `--domain docs` | 是 |
| `docs +update` | `--domain docs` | 否 |
| `docs +fetch` | `--domain docs` | 否（读取会议记录文档） |
| `docs +search` | `--scope "search:docs:read"` | 否 |
| `drive +search` | `--scope "search:docs:read"` | 否（历史报告搜索增强） |
| `docs +media-insert` | `--domain docs` + 本地相对路径文件 | 否（报告附件展示） |
| `wiki +node-create` | `--domain wiki` | 否 |
| `wiki spaces create` | `--scope "wiki:space:write_only"`；部分环境需 `wiki:wiki` | 否（知识空间初始化，需确认） |
| `wiki members list` | `--scope "wiki:member:retrieve"` | 否（知识库成员只读预检） |
| `wiki members create` | `--scope "wiki:member:create"` | 否（高风险，需明确确认） |
| `wiki members delete` | `--scope "wiki:member:update"` | 否（高风险，需明确确认） |
| `whiteboard +query` | `--domain drive` | 否（画板分析） |
| `drive +export` | `--scope "docs:document.content:read"` | 否 |
| `drive +apply-permission` | `--scope "docs:permission.member:apply"` + `--as user` | 否（历史文档权限申请补救） |
| `drive files patch` | `--scope "docx:document:write_only"` | 否（标题修正） |
| `drive +create-folder` | `--scope "space:folder:create"`；schema 也列出 `drive:drive` | 否（报告文件夹创建） |
| `drive +create-shortcut` | `--scope "space:document:shortcut"`；验证文件夹需 `space:document:retrieve` | 否（报告快捷方式归档） |
| `im +messages-search` | `--scope "search:message"` | 否 |
| `im +chat-messages-list` | `im:message` scope | 否 |
| `im +messages-send` | `--as bot` | 否 |
| `im +messages-send --as user --file/--image/--audio/--video` | `--scope "im:message im:message.send_as_user"` + 本地相对路径文件 | 否（用户身份富媒体通知） |

## 错误处理

| 错误 | 原因 | 处理 |
|------|------|------|
| `missing_scope` | 未授权某 scope | 跳过对应步骤，显示修复命令 |
| `missing_scope: vc:record:readonly` | 未授权会议录制/记录读取 | 跳过 Step 2b，继续使用日历/妙记数据 |
| `missing_scope: okr:okr.period:readonly` | 未授权 OKR 周期读取 | 跳过 Step 2c，不做 OKR 对齐 |
| `missing_scope: okr:okr.content:readonly` | 未授权 OKR 目标/KR 内容读取 | 保留周期信息，跳过目标详情 |
| `missing_scope: approval:instance:read` | 未授权已发起审批读取 | 跳过 Step 3b，不做审批阻塞分析 |
| `missing_scope: approval:task:read` | 未授权审批任务读取 | 跳过 Step 3b 的审批任务部分，仅保留其他数据源 |
| `required flag(s) "user-id" not set` | `okr +cycle-list` 未传用户 ID | 从当前用户上下文或用户提供的 open_id 传 `--user-id`，否则跳过 OKR |
| `items: null` | 无数据 | 报告中标注"本周期无数据" |
| `rate_limit` | API 限流 | 等待后重试 |
| `no available rooms` | 指定时段无会议室 | 建议更换时段或线上会议 |
| `invalid base token` | 多维表格 Token 错误 | 提示用户检查 Token |
| `records do not exist or no read permission` | `base +record-share-link-create` 的记录不存在或无读权限 | 只返回可读记录的链接；若全部失败，提示用户检查 `record_ids` 或表权限 |
| `99992402 field validation failed` | `drive +search` 的 `--query` 过长或字段组合非法 | 缩短关键词（建议 30 字以内），或拆成多次搜索 |
| `unknown domain "doc"` | 拼写错误 | 必须用 `docs` |
| `unknown flag: --page-size` | 参数错误 | 用 `--page-all` |
| `unknown flag: --format` | 参数错误 | 去掉此 flag |
| `--file must be a relative path` | 路径错误 | 改为相对路径 |
| `absolute path rejected` | `im +messages-send` 或 `docs +media-insert` 传了绝对路径 | 先 `cd` 到文件所在目录，再传 `./filename` |
| `data.failed_tasks` 非空 | `task +tasklist-task-add --section-guid` 的分组或任务添加失败 | 不要按 `ok: true` 判定成功；提示用户检查 `section_guid`，必要时回退到默认清单添加 |
| `--folder-token must not be empty` | `drive +create-shortcut` 未传目标文件夹 token | 让用户提供有效目标文件夹 token，或跳过快捷方式归档 |
| `resource contention occurred` | 快速创建/删除云空间资源触发资源竞争 | 等待 3-5 秒后重试一次 |
| `1063006` | `drive +apply-permission` 对同一文档的申请已达 5 次/日上限 | 不再重试，提示用户改为联系 Owner 或次日再试 |
| `1063007` | 目标文档不接受权限申请，或用户已拥有对应权限 | 停止申请链路，回退为人工联系 Owner |
| `wiki:member:delete` scope 无效 | 飞书 CLI/API 使用 `wiki:member:update` 删除成员 | 改用 `wiki:member:update`，且仅在用户明确确认后执行成员删除 |
| `danger: true` | `approval tasks remind` 属于危险写操作 | 默认不执行；只有用户明确要求催办并确认实例 code / task_ids 后才可继续 |

## 安全规则

- **⚠️ 严禁修改 `strict-mode`**：AI Agent **绝对不能**调用此命令修改设置。
- **⚠️ 严禁修改 `--profile`**：不得新建、切换或删除 profile 配置。
- **⚠️ 批量操作确认**：执行 `base +record-batch-create` 前必须向用户展示待写入的所有数据。
- **⚠️ 分享链接确认**：`base +record-share-link-create` 会生成可转发的记录入口，必须先展示目标表、记录数和用途。
- **⚠️ OKR 只读**：OKR 只用于对齐分析，不创建、不修改、不删除目标或 KR。
- **⚠️ 审批默认只读**：`approval instances initiated` / `approval tasks query` 只用于识别阻塞与外部依赖；`approval tasks remind` 默认禁用。
- **⚠️ 权限申请确认**：`drive +apply-permission` 会真实给文档 Owner 发卡片通知，必须先展示目标文档、申请权限（view/edit）和备注。
- **⚠️ 知识库成员管理确认**：`wiki members create/delete` 会真实改变空间成员，默认只允许 `list` 预检；添加/删除必须二次确认。
- **⚠️ 审批催办确认**：`approval tasks remind` 会真实催办审批人，必须先展示实例 code、task_ids、催办对象和评论内容。
- **⚠️ 知识空间创建确认**：`wiki spaces create` 会真实新增空间，必须先展示名称、描述、分享状态。
- **⚠️ 快捷方式归档确认**：`drive +create-shortcut` 会在目标文件夹创建入口，必须先展示目标文件夹 token 和报告标题。
- **⚠️ 本地文件上传确认**：`docs +media-insert`、`im +messages-send --as user --file/--image/...` 会上传本地文件，必须先展示文件路径、接收人/目标文档和用途。

## 参考

- [lark-shared](../lark-shared/SKILL.md) — 认证、权限、安全规则
- [lark-calendar](../lark-calendar/SKILL.md) — `+agenda`, `+room-find`, `+update`
- [lark-vc](../lark-vc/SKILL.md) — `+search`, `+notes`
- [lark-okr](../lark-okr/SKILL.md) — `+cycle-list`, `+cycle-detail`
- [lark-approval](../lark-approval/SKILL.md) — `instances initiated`, `tasks query`, `tasks remind`
- [lark-task](../lark-task/SKILL.md) — `+get-my-tasks`, `+create`, `+complete`, `+comment`
- [lark-doc](../lark-doc/SKILL.md) — `+create`, `+search`, `+update`, `+media-insert`
- [lark-wiki](../lark-wiki/SKILL.md) — `+node-create`, `spaces create`
- [lark-im](../lark-im/SKILL.md) — `+messages-search`, `+messages-send`, `+chat-messages-list`
- [lark-drive](../lark-drive/SKILL.md) — `+search`, `+export`, `+apply-permission`, `+create-folder`, `+create-shortcut`, `files patch`
- [lark-base](../lark-base/SKILL.md) — `+record-batch-create`, `+record-share-link-create`
- [lark-whiteboard](../lark-whiteboard/SKILL.md) — `+query`
