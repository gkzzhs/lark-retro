# 测试记录

> 测试环境：macOS (arm64) · lark-cli 1.0.3 → 1.0.20 · 真实飞书账号
> 最后更新：2026-04-28

---

## v2.6.6 / lark-cli 1.0.20 搜索增强与日程更新摘要

| 测试场景 | 命令/检查 | 结果 | 备注 |
|----------|-----------|------|------|
| CLI 版本确认 | `lark-cli --version` | ✅ `1.0.20` | 本机已升级到用户口径中的最新版本 |
| Drive 搜索命令面 | `drive +search --help` | ✅ 命中 `--mine` / `--edited-since` / `--commented-since` / `--folder-tokens` / `--space-ids` | 适合做历史报告定位增强 |
| Drive 搜索真实夹具 | `drive +create-folder` → `docs +create` → `docs +update` → `drive +search ...` | ⚠️ 查询均返回 0 | 对真实临时文档执行 `--mine`、`--created-since 1d`、`--edited-since 1d`、`--folder-tokens` 均未命中，说明受搜索索引/租户可见性影响，不可替代 `docs +search` |
| Drive 搜索字段边界 | `drive +search --query "Codex v1.0.20 Search Test 20260428-125131"` | ⚠️ 命中 `99992402 field validation failed` | 实测 query 过长会触发字段校验失败，应拆成更短关键词 |
| 消息 @过滤命令面 | `im +messages-search --help` | ✅ 命中 `--is-at-me` / `--at-chatter-ids` | 可作为 blocker 搜索降噪增强 |
| 消息 @过滤真实账号查询 | `im +messages-search --is-at-me ...` / `--at-chatter-ids <my_open_id> ...` | ⚠️ `items: []` | 当前时间窗没有可见命中；0 结果不能当作“无人讨论” |
| 日程更新真实 E2E | `calendar +create` → `calendar +update` → `calendar events get` → `calendar events delete` | ✅ 跑通 | 成功更新 `summary`、`description`、`start/end`，随后删除临时事件 |
| 测试资源清理 | `drive +delete --type docx/folder` / `calendar events delete` | ✅ 已清理 | 临时文档 `J3xJdtWAhohaZxx0eU9c3bfgnXf`、文件夹 `DepBfsxrvlSjdpdwoztcAWgCngb`、事件 `1b9fc621-bfe2-465c-a65d-6eb5e5e3ed91_0` 均已清除 |
| Skill 文档落地 | `skills/lark-retro/SKILL.md` / `README*` | ✅ 已更新到 v2.6.6 | Drive 搜索优先 + docs 回退、消息 @过滤、`calendar +update` 已纳入 |

---

## v2.6.5 / lark-cli 1.0.17 权限补救与分享链接评估摘要

| 测试场景 | 命令/检查 | 结果 | 备注 |
|----------|-----------|------|------|
| 官方 release 核对 | `gh release view v1.0.17 -R larksuite/cli --json body` | ✅ 命中 `drive +apply-permission` / 记录分享链接 / 画板图片支持 | 确认三个新增点真实存在 |
| 文档权限申请授权 | `lark-cli auth login --scope "docs:permission.member:apply"` | ✅ 授权成功 | 当前账号已补齐 `docs:permission.member:apply` |
| 文档权限申请真实调用 | `drive +apply-permission --token "https://www.feishu.cn/docx/IxfedCBrKoSvnRxRoyhcdV2anYf" --perm view --as user` | ✅ 真实 API 边界命中 | owned doc 场景返回 `1063007 Pointless authorized request`，与官方 reference 一致；随后删除临时文档 |
| Bitable 记录分享真实 E2E | `base +base-create` → `+field-create` → `+record-batch-create` → `+record-share-link-create` | ✅ 跑通 | 真实生成两条记录分享链接；重复 ID 自动去重；混合有效/无效 ID 时保留有效结果 |
| 画板图片能力评估 | `gh release view v1.0.17` / `skills/lark-whiteboard/SKILL.md` | ✅ 已评估 | 更偏展示增强，与 retro 主链路弱相关，因此不纳入默认流程 |
| 测试资源清理 | `drive +delete --file-token UnZub4apxaPX0bsd2OecydUyngY --type bitable --yes` / `drive +delete --file-token IxfedCBrKoSvnRxRoyhcdV2anYf --type docx --yes` | ✅ 已清理 | 临时 Bitable 与临时文档均已删除 |
| Skill 文档落地 | `skills/lark-retro/SKILL.md` / `README*` | ✅ 已更新到 v2.6.5 | 权限申请补救与分享链接已纳入；白板插图只保留边界说明 |

---

## v2.6.4 / lark-cli 1.0.15 审批能力评估摘要

| 测试场景 | 命令/检查 | 结果 | 备注 |
|----------|-----------|------|------|
| 官方 release 核对 | `gh release view v1.0.15 -R larksuite/cli --json body` | ✅ 命中 `feat: add remind/initiated method` | 确认 v1.0.15 的审批新增点真实存在 |
| 已发起审批 schema | `npx -y @larksuite/cli@1.0.15 schema approval.instances.initiated` | ✅ 只读接口 | `approval:instance:read`，适合补强 retro 的外部依赖/Blocker 信号 |
| 审批任务 schema | `npx -y @larksuite/cli@1.0.15 schema approval.tasks.remind` | ✅ 危险写操作 | 返回 `danger: true`，因此 `tasks.remind` 不进入默认回顾主流程 |
| 浮动图片能力评估 | `gh pr view 494 -R larksuite/cli --json title,body` | ✅ 功能明确 | 适合电子表格看板展示，但与回顾主链路弱相关，暂不纳入主线 |
| Skill 文档落地 | `skills/lark-retro/SKILL.md` / `README*` | ✅ 已更新到 v2.6.4 | 审批只读增强已纳入；催办默认禁用；README 中明确写出取舍 |

---

## v2.6.3 / Emoji 真实写入与全局 Skill 版本回归摘要

| 测试场景 | 命令/检查 | 结果 | 备注 |
|----------|-----------|------|------|
| 全局 skill 版本排查 | `~/.agents/skills/lark-retro/SKILL.md` | ❌ 原本仍是 `version: 1.3.0` | 这是实际运行仍无 emoji 的根因：Agent 加载的是旧版 skill |
| 本地路径安装 | `npx skills add /Users/wangguanhang/Documents/飞书CLI/lark-retro-v110-review -y -g` | ✅ 安装成功 | 避开 GitHub clone 60s 超时，覆盖全局 skill |
| 安装后版本确认 | `grep -n "version: 2.6.3\\|Emoji 输出契约" ~/.agents/skills/lark-retro/SKILL.md` | ✅ 命中 | 已确认 Agent 可读取到 emoji gate 规则 |
| Emoji 文档真实创建 | `docs +create --title "【Codex实测】Emoji Gate..." --markdown "<emoji markdown>"` | ✅ 创建成功 | 返回 doc token `Ivypdf...rnUj` |
| Emoji 文档真实读取 | `docs +fetch --doc Ivypdf...rnUj` | ✅ emoji 完整保留 | H1、H2、表格指标、洞察、行动项中的 emoji 均存在 |
| 测试文档清理 | `drive +delete --file-token Ivypdf...rnUj --type docx --yes` | ✅ 删除成功 | 另一个索引延迟后发现的测试文档 `UDzb...Tntg` 也已删除 |

---

## v2.6.2 / Emoji 输出门槛回归摘要

| 测试场景 | 检查 | 结果 | 备注 |
|----------|------|------|------|
| Emoji 规则强度 | `SKILL.md` Step 6 | ✅ 已从"视觉增强"改为"输出契约" | 缺 emoji 时必须重写 Markdown，不得进入 `docs +create` |
| 报告骨架 | H1/H2、数据概览、洞察、行动项 | ✅ 已提供固定 emoji 模板 | 覆盖回顾模式和周报模式 |
| 创建前自检 | 最少 8 个 emoji、H1/H2 必须带 emoji、Action Items 必须带 emoji | ✅ 已标注硬性门槛 | 防止生成纯文本报告 |
| 示例输出 | `examples/sample-output.md` | ✅ 已有 emoji 示例 | 与新门槛一致，无需修改 |

---

## v2.6.1 / Hermes Agent 兼容性摘要

| 测试场景 | 命令/检查 | 结果 | 备注 |
|----------|-----------|------|------|
| Skill 结构 | `skills/lark-retro/SKILL.md` | ✅ 标准 `SKILL.md` 结构 | Hermes Skills 系统兼容 `SKILL.md`/agentskills.io 风格 skill |
| Hermes 本机命令 | `command -v hermes && hermes --version` | ⚠️ 本机未安装 | 未做 Hermes 运行时扫描实测 |
| 仓库说明 | README / README_EN | ✅ 已补充 | 推荐 `external_dirs` 指向 `/path/to/lark-retro/skills`，而非仓库根目录 |
| 现有安装方式 | `npx skills add https://github.com/gkzzhs/lark-retro -y -g` | ✅ 保留 | 不破坏 Codex / Cursor / Claude Code / Trae 等现有安装方式 |

---

## v2.6.0 / lark-cli 1.0.14 回归摘要

| 测试场景 | 命令 | 结果 | 备注 |
|----------|------|------|------|
| CLI 升级 | `lark-cli update` / `lark-cli --version` / `npm view @larksuite/cli version` | ✅ 本机 1.0.14，npm 最新 1.0.14 | 官方 skills 同步更新成功 |
| OKR 命令面 | `okr --help` / `okr +cycle-list --help` / `okr +cycle-detail --help` | ✅ 命令存在 | `+cycle-list` 需要 `--user-id` |
| OKR 周期权限边界 | `okr +cycle-list --user-id ... --time-range ... --dry-run` | ⚠️ 缺 `okr:okr.period:readonly` | Skill 已标注降级，不影响主流程 |
| OKR 详情权限边界 | `okr +cycle-detail --cycle-id 123 --dry-run` | ⚠️ 缺 `okr:okr.content:readonly` | Skill 已标注只读增强 |
| Wiki 知识空间创建 dry-run | `wiki spaces create --data ... --dry-run` | ✅ 请求结构正确 | POST `/open-apis/wiki/v2/spaces`，真实创建需用户确认 |
| 文档附件展示 dry-run | `docs +media-insert --type file --file ./retro-report.pdf --file-view preview --dry-run` | ✅ 四步编排正确 | 查询根 block → 创建 file block → 上传 → 绑定 token |
| 报告文件夹创建 dry-run | `drive +create-folder --name ... --dry-run` | ✅ 请求结构正确 | 不传 `--folder-token` 时 body 为 `folder_token: ""`，表示根目录 |
| 用户身份附件通知 dry-run | `im +messages-send --as user --chat-id ... --file ./retro-report.pdf --dry-run` | ✅ 请求结构正确 | dry-run 使用 `file_dryrun_upload` 占位，真实执行会先上传文件 |
| 邮件定时/优先级边界 | `mail +send --priority high --send-time ... --confirm-send --dry-run` | ⚠️ 缺 `mail:user_mailbox.message:send` | 与 lark-retro 主通知闭环弱相关，暂不纳入主流程 |
| 权限检查 | `auth check --scope "okr:okr.period:readonly ..."` | ⚠️ 仅 OKR 两个只读 scope 缺失 | `wiki:space:write_only`、`im:message`、`im:message.send_as_user`、`space:folder:create`、`docx:document:write_only` 已授权 |
| GitHub 拉取 | `git clone` / `git fetch --all --tags` | ⚠️ 本地网络无法连接 GitHub 443 | 已基于干净 v2.5.0 评审目录和官方 CLI/schema 适配 |

---

## v2.5.0 / lark-cli 1.0.10 回归摘要

| 测试场景 | 命令 | 结果 | 备注 |
|----------|------|------|------|
| CLI 升级 | `lark-cli --version` / `npm view @larksuite/cli version` | ✅ 均为 1.0.10 | 本地 CLI 与 npm 最新版本一致 |
| 任务清单添加 | `task +tasklist-task-add --tasklist-id ... --task-id ...` | ✅ 真实写入成功 | 创建临时 tasklist/task 后验证，再删除清理 |
| 自定义分组参数 | `task +tasklist-task-add ... --section-guid ... --dry-run` | ✅ 参数结构可用 | 真实分组写入需用户提供已有 `section_guid` |
| 自定义分组失败边界 | `task +tasklist-task-add ... --section-guid 00000000-0000-0000-0000-000000000000` | ⚠️ 返回 `ok: true` 但 `failed_tasks` 为 `not_found` | Skill 已要求检查 `data.failed_tasks`，不能只看 `ok` |
| 文档标题修改 | `drive files patch --params '{"file_token":"...","type":"docx"}' --data '{"new_title":"..."}'` | ✅ 真实修改成功 | `docs +fetch` 验证标题已变更，随后删除临时文档 |
| 报告快捷方式 | `drive +create-shortcut --file-token ... --type docx --folder-token ...` | ✅ 真实创建成功 | `drive files list` 返回 `type: shortcut` 和 `shortcut_info.target_token` |
| 快捷方式清理 | `drive +delete --type shortcut` | ✅ 重试后删除成功 | 刚创建后立即删遇到 `resource contention`，等待 3-5 秒后成功 |
| 临时文件夹清理 | `drive +delete --type folder` | ✅ 异步任务成功 | 删除后读取文件夹返回 `file has been delete` |
| Wiki 成员只读预检 | `wiki members list --params '{"space_id":"...","page_size":10}'` | ✅ 返回成员列表 | create/delete 只做 dry-run，不改真实成员 |
| Wiki 成员管理 dry-run | `wiki members create/delete --dry-run` | ✅ 请求结构正确 | 删除成员使用 `wiki:member:update`，不存在 `wiki:member:delete` scope |

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
| `--section-guid` 参数结构 | `task +tasklist-task-add --section-guid <section_guid> --dry-run` | ✅ | v1.0.10 新增；真实写入需用户提供已有自定义分组 GUID |
| `--section-guid` 错误路径 | 传不存在的 section GUID | ⚠️ | `ok: true` 但 `failed_tasks` 有 `not_found`，必须检查失败数组 |

### Step 7c: 云空间标题与快捷方式（v1.0.10）

| 测试场景 | 命令 | 结果 | 备注 |
|----------|------|------|------|
| 标题修改 dry-run | `drive files patch --params ... --data ... --dry-run` | ✅ | PATCH `/open-apis/drive/v1/files/{file_token}` |
| 标题修改真实写入 | `drive files patch --params '{"file_token":"<docx_token>","type":"docx"}' --data '{"new_title":"..."}'` | ✅ | `docs +fetch` 可读到新标题 |
| 空 folder token | `drive +create-shortcut --folder-token ""` | ❌ | CLI 拒绝：`--folder-token must not be empty` |
| 快捷方式真实写入 | `drive +create-shortcut --file-token <docx_token> --type docx --folder-token <folder_token>` | ✅ | 返回 `shortcut_token`，list 可见 `type: shortcut` |
| 快捷方式快速删除 | `drive +delete --type shortcut` | ⚠️ | 可能遇到 `resource contention`，等待 3-5 秒后重试成功 |

### Step 7d: Wiki 成员预检（v1.0.10）

| 测试场景 | 命令 | 结果 | 备注 |
|----------|------|------|------|
| 空间列表分页 | `wiki spaces list --page-all --page-limit 5` | ✅ | 真实账号返回 2 个可访问空间 |
| 成员列表 | `wiki members list --params '{"space_id":"<space_id>","page_size":10}'` | ✅ | 返回成员 `member_id` / `member_role` / `member_type` |
| 添加成员 dry-run | `wiki members create ... --dry-run` | ✅ | 不修改真实成员 |
| 删除成员 dry-run | `wiki members delete ... --dry-run` | ✅ | 删除成员需要 `wiki:member:update` |

### Step 2c: OKR 对齐（v1.0.14）

| 测试场景 | 命令 | 结果 | 备注 |
|----------|------|------|------|
| OKR 域帮助 | `lark-cli okr --help` | ✅ | 包含 `+cycle-list`、`+cycle-detail`、objectives、key_results 等资源 |
| 周期列表参数 | `lark-cli okr +cycle-list --help` | ✅ | `--user-id` 为必填，`--time-range` 格式为 `YYYY-MM--YYYY-MM` |
| 周期详情参数 | `lark-cli okr +cycle-detail --help` | ✅ | 需要 `--cycle-id` |
| 周期列表缺权限 | `okr +cycle-list --user-id <open_id> --time-range 2026-01--2026-04 --dry-run` | ⚠️ | 缺 `okr:okr.period:readonly` |
| 周期详情缺权限 | `okr +cycle-detail --cycle-id 123 --dry-run` | ⚠️ | 缺 `okr:okr.content:readonly` |

### Step 7e: 报告附件展示（v1.0.14）

| 测试场景 | 命令 | 结果 | 备注 |
|----------|------|------|------|
| 文件预览插入 dry-run | `docs +media-insert --doc dummydoc --type file --file ./retro-report.pdf --file-view preview --dry-run` | ✅ | dry-run 展示四步编排 |
| 展示方式枚举 | `docs +media-insert --help` | ✅ | `card`、`preview`、`inline` |

### Step 7f: Wiki 知识空间初始化（v1.0.14）

| 测试场景 | 命令 | 结果 | 备注 |
|----------|------|------|------|
| 知识空间创建 schema | `schema wiki.spaces.create --format pretty` | ✅ | scope 为 `wiki:wiki`、`wiki:space:write_only`，identity 为 user |
| 知识空间创建 dry-run | `wiki spaces create --data '{"name":"...","description":"...","open_sharing":"closed"}' --dry-run` | ✅ | 真实创建会新增空间，默认不自动执行 |

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
| `drive +create-shortcut` | ✅ | 未测 | 默认 user，需目标文件夹 token |
| `drive files patch` | ✅ | 未测 | docx 标题修改需 `docx:document:write_only` |
| `wiki members list` | ✅ | 未测 | 只读预检可用，create/delete 不进默认流程 |
| `okr +cycle-list` | ⚠️ 需 OKR scope | ⚠️ 需 OKR scope | 只读增强，不影响主流程 |
| `wiki spaces create` | ✅ dry-run | 未测 | 真实创建需确认 |
| `docs +media-insert` | ✅ dry-run | 未测 | 上传本地文件，需确认 |

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
| `space:folder:create space:document:retrieve` | ✅ | 用于创建临时文件夹和读取文件夹清单 |
| `space:document:shortcut space:document:delete` | ✅ | 用于快捷方式创建与测试资源清理 |
| `wiki:member:retrieve wiki:member:create wiki:member:update` | ✅ | retrieve 真实 list；create/update 仅 dry-run |
| `wiki:member:delete` | ❌ | 不是有效 scope，删除成员用 `wiki:member:update` |
| `okr:okr.period:readonly okr:okr.content:readonly` | ⚠️ 当前未授权 | OKR 对齐增强；缺失时跳过 |
| `wiki:space:write_only` | ✅ | Wiki 知识空间创建；真实创建需确认 |
| `im:message im:message.send_as_user` | ✅ | 用户身份富媒体通知；默认仍推荐 bot Markdown |

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
| `tasklist-task-add --section-guid` | section 不存在时 `ok: true` 但 `failed_tasks` 非空 | ⚠️ 已在 Skill 中要求检查 |
| `drive +create-shortcut` 空 folder token | CLI 直接拒绝 | ✅ 已标注需有效 `folder_token` |
| 云空间资源快速删除 | 可能触发 `resource contention` | ⚠️ 已标注等待后重试 |
| `okr +cycle-list` 未传 `--user-id` | CLI 直接拒绝 | ✅ 已标注必须传用户 ID |
| OKR scope 缺失 | `missing_scope` | ✅ 已标注降级 |
| 本地附件路径 | `docs +media-insert` / `im +messages-send --file` 必须用相对路径 | ✅ 已标注先 `cd` 再传 `./filename` |
| `wiki spaces create` | 真实新增知识空间 | ⚠️ 默认只 dry-run 或用户确认后执行 |

---

## 兼容性

| lark-cli 版本 | 测试结果 | 备注 |
|---------------|----------|------|
| 1.0.3 | ✅ 全部通过 | 初始开发和测试版本 |
| 1.0.4 | ✅ 全部通过 | 新增 `im +chat-create`，lark-retro 不涉及 |
| 1.0.9 | ✅ 核心回归通过 | 新增 `vc +search` / `vc +notes` 作为会议记录补强数据源 |
| 1.0.10 | ✅ 核心回归通过 | 新增任务自定义分组、报告快捷方式、标题修正、Wiki 成员只读预检 |
| 1.0.14 | ✅ 命令与边界回归通过 | 新增 OKR 对齐、Wiki 知识空间初始化、文档附件展示方式 |
