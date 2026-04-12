# 测试记录

> 测试环境：macOS (arm64) · lark-cli 1.0.3 → 1.0.9 · 真实飞书账号
> 最后更新：2026-04-12

---

## v2.4.0 / lark-cli 1.0.9 回归摘要

| 测试场景 | 命令 | 结果 | 备注 |
|----------|------|------|------|
| CLI 升级 | `lark-cli update` | ✅ 升级到 1.0.9 | 本地网络下官方 Skills clone 60s 超时；CLI 主程序不受影响 |
| 会议录制搜索 | `vc +search --start ... --end ... --page-size 5` | ✅ 返回 `ok: true`，3 条候选 | 真实账号读链路跑通 |
| 关键词会议搜索 | `vc +search --query "回顾" ...` | ✅ 返回 `ok: true`，0 条结果 | 空结果不影响主流程 |
| 会议记录 token 获取 | `vc +notes --meeting-ids <meeting_id>` | ✅ 返回 `note_doc_token` / `shared_doc_tokens` / `verbatim_doc_token` | 不在文档中记录具体会议内容 |
| 会议记录正文读取 | `docs +fetch --doc <note_doc_token>` | ✅ 返回 `markdown` 正文 | 仅校验 `has_content: true`，不在测试记录中粘贴正文 |
| 会议录制权限边界 | `vc +recording --meeting-ids <meeting_id>` | ⚠️ 缺 `vc:record:readonly` | 已在 Skill 中标注降级策略 |
| 考勤记录 | `attendance user_tasks query ...` | ⚠️ 缺 `attendance:task:readonly` | 需要员工 ID，暂不纳入主线回顾流程 |
| 幻灯片创建 | `slides +create ...` | ⚠️ 缺 slides scopes | 可作为未来汇报模式，不进入 v2.4 主流程 |
| Drive 删除 | `drive +delete ...` | ⚠️ 缺 `space:document:delete` | 高风险删除能力，不纳入回顾工作流 |

---

## CLI 命令测试

### Step 2: 日历数据采集

| 测试场景 | 命令 | 结果 | 备注 |
|----------|------|------|------|
| 正常查询 7 天日程 | `calendar +agenda --start 2026-03-27 --end 2026-04-03` | ✅ 返回 52 条 | 含 38 条批量分发城市分会场 |
| 去重聚合验证 | AI 按同名规则聚合 | ✅ 聚合为 ~10 组 | "AI切磋大会"38 个城市变体 → 1 组 |
| RSVP 状态过滤 | 检查 `needs_action` vs `accept` | ⚠️ 需注意 | 大量事件 RSVP 为 `needs_action`，仅 1 条 `accept` |
| 空日程周 | 无工作日程的周末范围 | ✅ 返回空数组 | 不报错，data 为空数组 |
| `--jq` 过滤 | `-q '.data[] \| {summary, start: .start_time.datetime}'` | ✅ 正常 | 有效减少输出量 |

### Step 3: 任务数据采集

| 测试场景 | 命令 | 结果 | 备注 |
|----------|------|------|------|
| 获取未完成任务 | `task +get-my-tasks` | ✅ `items: null` | 用户不使用飞书任务 |
| 获取已完成任务 | `task +get-my-tasks --complete` | ✅ `items: null` | 同上 |
| `--page-all` 翻页 | `task +get-my-tasks --page-all` | ✅ 正常 | 无数据时正常返回 |
| `--jq` 对 null 的处理 | `--jq '.data.items[]'` | ⚠️ 空输出 | `items: null` 时 jq 返回空，不报错也不提示 |
| 非阻塞降级 | 无任务时继续生成报告 | ✅ | v2.0 改为在报告中标注，不中断流程 |

### Step 4: 消息数据采集

| 测试场景 | 命令 | 结果 | 备注 |
|----------|------|------|------|
| 关键词搜索 | `im +messages-search --query "问题" --chat-type group` | ✅ 返回多条 | `has_more: true`，结果含社区群噪声 |
| 时间范围过滤 | `--start "2026-03-27T00:00:00+08:00" --end "2026-04-03T23:59:59+08:00"` | ✅ 正常 | ISO 8601 格式 |
| `--format json` | 显式指定 JSON 格式 | ✅ 正常 | |
| 噪声过滤有效性 | 4 层漏斗过滤后 | ✅ | 大量社区群闲聊被过滤，保留有效工作讨论 |

### Step 5a: 文档搜索

| 测试场景 | 命令 | 结果 | 备注 |
|----------|------|------|------|
| 模糊搜索 | `docs +search --query "Sprint 回顾" --format json` | ✅ 返回 15 条 | 搜索索引正常 |
| 搜索结果分页 | `has_more: false` | ✅ | 15 条未触发分页 |
| 空关键词搜索 | `docs +search --query ""` | ⚠️ 返回空 | 不报错但无结果 |

### Step 7: 创建文档

| 测试场景 | 命令 | 结果 | 备注 |
|----------|------|------|------|
| `--format` flag | `docs +create --format json` | ❌ 报错 | `docs +create` 不支持 `--format`，已在错误处理表中标注 |
| `--folder-token` vs `--wiki-space` | 同时使用 | ❌ 互斥 | 只能选其一 |

### Step 8: 创建任务

| 测试场景 | 命令 | 结果 | 备注 |
|----------|------|------|------|
| `--as user` 创建 | `task +create --summary "测试" --as user` | ✅ | 任务归属到个人待办 |
| `--as bot` 创建 | `task +create --summary "测试" --as bot` | ⚠️ | 任务归属 bot，user 看不到 |
| `--due` 参数 | `--due "+7d"` | ✅ | 相对日期格式正常 |
| `--task-id` 格式 | guid 格式（8-4-4-4-12） | ✅ | 不是数字 ID，是 GUID |

---

## 身份与权限测试

| 命令 | `--as user` | `--as bot` | 备注 |
|------|:-----------:|:----------:|------|
| `calendar +agenda` | ✅ | ❌ | 只有 user 能读自己的日程 |
| `task +get-my-tasks` | ✅ | ❌ | "我的任务"只对 user 有意义 |
| `task +create` | ✅ (推荐) | ✅ | bot 创建的任务 user 看不到 |
| `task +complete` | ✅ | ✅ | |
| `task +comment` | ✅ | ✅ | |
| `docs +create` | ✅ | ✅ | bot 创建的文档归属不同 |
| `docs +search` | ✅ | ❌ | 搜索用户自己的文档 |
| `im +messages-search` | ✅ | ❌ | 搜索用户视角的消息 |
| `im +messages-send` | ⚠️ 需额外 scope | ✅ (推荐) | bot 发送更稳定 |

---

## 授权测试

| 测试场景 | 结果 | 备注 |
|----------|------|------|
| 仅 `--domain calendar,docs` | ✅ 可生成基础报告 | 日历分析 + 文档输出 |
| 加 `--domain task` | ✅ 增强报告内容 | 增加任务完成率分析 |
| 加 `--scope "search:message"` | ✅ 消息搜索可用 | 增加关键讨论分析 |
| 缺少 scope 时的降级 | ✅ `missing_scope` 错误被捕获 | 自动跳过，报告中标注"（未采集）" |
| `--domain doc`（少 s） | ❌ `unknown domain "doc"` | 必须用 `docs` |
| 多次 `auth login` scope 累积 | ✅ 正常累积 | 不会覆盖之前的授权 |

---

## 渐进增强验证

| 能力层级 | 数据源 | 报告内容 | 测试结果 |
|----------|--------|----------|----------|
| 🟢 基础版 | 日历 + 文档 | 时间分配分析 + 会议模式 | ✅ |
| 🔵 增强版 | + 任务 | + 完成率 + Blocker 追踪 | ✅ (因无任务数据，标注后跳过) |
| 🟣 高级版 | + 消息搜索 | + 关键讨论提取 | ✅ |
| 🟠 完整版 | + Bot 通知 | + 群聊推送 | ⚠️ 未测试 bot 能力 |

---

## 边界情况 & 已知限制

| 场景 | 行为 | 状态 |
|------|------|------|
| 批量分发日程（38 个城市分会场） | 同名聚合规则处理 | ✅ 已处理 |
| 任务完全为空 | 报告标注"无任务数据"，不中断 | ✅ v2.0 已修复 |
| 消息搜索噪声大 | 4 层过滤漏斗 | ✅ 已处理 |
| `--jq` 遇到 `items: null` | 静默返回空输出 | ⚠️ 需先确认非空再用 `--jq` |
| 上期报告搜不到 | 渐进搜索（精确→模糊→跳过） | ✅ |
| `docs +create` 不支持 `--format` | 去掉此 flag | ✅ 已在错误处理表标注 |
| `task +get-my-tasks` 不支持 `--page-size` | 用 `--page-all` 代替 | ✅ 已在错误处理表标注 |
| ISO 8601 时区格式 | 使用 `+08:00` 后缀 | ✅ |
| lark-cli 1.0.3 → 1.0.4 兼容性 | 所有命令行为一致，无 breaking change | ✅ |

---

## 兼容性

| lark-cli 版本 | 测试结果 | 备注 |
|---------------|----------|------|
| 1.0.3 | ✅ 全部通过 | 初始开发和测试版本 |
| 1.0.4 | ✅ 全部通过 | 新增 `im +chat-create`，lark-retro 不涉及 |
| 1.0.9 | ✅ 核心回归通过 | 新增 `vc +search` / `vc +notes` 作为会议记录补强数据源 |