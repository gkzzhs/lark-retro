# lark-retro 配置指南

`lark-retro` 开箱即用，无需任何配置文件（但首次使用仍需完成 `lark-cli` 配置与授权）。以下是进阶用法的说明。

---

## 1. 权限配置

### 最低可用授权（仅日历 + 文档）

只需日历和文档权限，即可生成基于时间分配分析的基础回顾报告：

```bash
lark-cli auth login --domain calendar,docs
```

### 推荐授权（日历 + 任务 + 文档 + 多维表格）

加上任务和多维表格权限后，功能最全：

```bash
lark-cli auth login --domain calendar,task,docs,base
```

> ⚠️ domain 必须用 `docs`（带 s），`doc` 会被 CLI 拒绝。

### 增强权限（消息搜索 + 文档搜索 + 妙记）

```bash
lark-cli auth login --scope "search:message search:docs:read minutes:minute:read"
```

### v2.5 可选增强权限（lark-cli v1.0.10+）

如果要使用报告快捷方式归档、标题修正或知识库成员只读预检，再补以下 scope：

```bash
lark-cli auth login --scope "space:document:shortcut space:document:retrieve space:folder:create docx:document:write_only wiki:member:retrieve"
```

> `wiki members create/delete` 属于高风险知识库管理动作，默认不纳入 lark-retro 主流程；如果你确实要管理成员，删除成员使用 `wiki:member:update`，不是 `wiki:member:delete`。

### v2.6 可选增强权限（lark-cli v1.0.14+）

如果要使用 OKR 对齐、知识空间初始化、用户身份富媒体通知，再补以下 scope：

```bash
lark-cli auth login --scope "okr:okr.period:readonly okr:okr.content:readonly wiki:space:write_only im:message im:message.send_as_user"
```

> OKR 只做只读分析；`wiki spaces create` 会真实新增知识空间，必须确认名称、描述和分享状态后才执行。部分环境创建知识空间还会提示补 `wiki:wiki`。

---

## 2. 知识库归档配置
详情同 v2.2.0。

---

## 3. 群聊通知配置
详情同 v2.2.0。

---

## 4. 自定义回顾周期
详情同 v2.2.0。

---

## 5. 能力分层

| 层级 | 功能 | 所需授权 |
|------|------|---------|
| 🟢 基础版 | 日历分析 + 文档输出 | `--domain calendar,docs` |
| 🔵 增强版 | + 任务追踪 + 行动项关闭 | `--domain calendar,task,docs` |
| 🟣 高级版 | + 消息分析 + 知识库归档 + 会议纪要/会议记录 + OKR 对齐 | + `--scope "search:message search:docs:read minutes:minute:read vc:record:readonly okr:okr.period:readonly okr:okr.content:readonly"` |
| 🟠 完整版 | + Bitable 归档 + 会议室预约 + 画板分析 + 报告空间初始化/快捷方式归档 | + `--domain base` + bot 能力 + `space:folder:create wiki:space:write_only space:document:shortcut` |

---

## 6. 行动项任务列表 (v2.0+)
默认把行动项加入本次回顾任务列表：

```bash
lark-cli task +tasklist-task-add --tasklist-id "<tasklist_guid>" --task-id "<task_guid>"
```

v2.5 / lark-cli v1.0.10+ 支持放入已有自定义分组：

```bash
lark-cli task +tasklist-task-add \
  --tasklist-id "<tasklist_guid>" \
  --task-id "<task_guid>" \
  --section-guid "<section_guid>"
```

> 注意：`--task-id`、`--tasklist-id`、`--section-guid` 都要用 GUID。传错 `section_guid` 时可能仍返回 `ok: true`，但 `data.failed_tasks` 会包含失败原因，必须检查。如果用户没有提供已有分组的 `section_guid`，不要猜测，直接使用默认清单添加。

## 7. 行动项闭环追踪 (v2.0+)
详情同 v2.2.0。

## 8. 历史报告导出
详情同 v2.2.0。

## 9. 文档创建与更新 (v2.1+)
详情同 v2.2.0。

## 10. 会议纪要分析 (v2.2+)
详情同 v2.2.0。

---

## 13. 行动项 Bitable 归档（v2.3 新增）

v2.3 支持利用 v1.0.8 的批量写入能力，将行动项同步至多维表格：

```bash
# 工作流程：
# 1. AI 整理本次回顾的所有行动项。
# 2. 调用 base +record-batch-create 批量写入指定的 Bitable。
```

### 使用示例
```
帮我做这周的回顾，行动项存到多维表格 app_xxx 的 tbl_xxx 表里
```

---

## 14. 预约下期回顾会议室（v2.3 新增）

v2.3 实现了从数字协作到物理空间的闭环。

### 工作流程
1. AI 根据当前回顾周期建议下次时间（如：下周五同一时间）。
2. 调用 `calendar +room-find` 查找指定条件（城市、大楼、容纳人数）的可用会议室。
3. 展示会议室供用户选择并一键预约。

### 使用示例
```
做完回顾后，帮我订一下下周五下午 4 点的会议室，5 个人
```

---

## 15. 画板脑暴背景分析（v2.3 新增）

如果回顾前有画板脑暴，AI 可以直接读取画板内容。

### 工作流程
1. 调用 `whiteboard +query` 获取画板图片或节点数据。
2. AI 分析画板中的关键词、逻辑关系，作为报告的背景分析。

---

## 16. 报告快捷方式与标题修正（v2.5 新增）

如果团队有固定资料夹，可以把生成后的回顾报告以快捷方式放进去：

```bash
# v2.6 / lark-cli v1.0.13+：如果还没有资料夹，可以先创建
lark-cli drive +create-folder \
  --name "Sprint 回顾 W16" \
  --folder-token "<parent_folder_token>"

lark-cli drive +create-shortcut \
  --file-token "<doc_token>" \
  --type docx \
  --folder-token "<target_folder_token>"
```

如果报告创建后需要统一标题：

```bash
lark-cli drive files patch \
  --params '{"file_token":"<doc_token>","type":"docx"}' \
  --data '{"new_title":"Sprint 回顾 W16"}'
```

> `drive +create-folder` 可省略 `--folder-token`，表示创建到当前用户云空间根目录；`drive +create-shortcut` 必须传有效 `target_folder_token`，空字符串会被 CLI 拒绝。刚创建后马上删除可能遇到 `resource contention`，等待几秒后重试即可。

---

## 17. 知识库成员只读预检（v2.5 新增）

如果担心目标知识库空间权限不足，可先只读查看成员：

```bash
lark-cli wiki members list --params '{"space_id":"<space_id>","page_size":20}'
```

> lark-retro 默认只做 `list`。`wiki members create/delete` 会真实改变成员权限，必须由用户明确要求并再次确认后才执行。

---

## 18. OKR 与知识空间增强（v2.6 新增）

### OKR 对齐分析

当你希望复盘"本周期工作是否支撑 OKR"时，可以让 lark-retro 读取 OKR 周期和目标详情：

```bash
lark-cli okr +cycle-list \
  --user-id "<open_id>" \
  --user-id-type open_id \
  --time-range "2026-01--2026-04"

lark-cli okr +cycle-detail --cycle-id "<cycle_id>"
```

> `okr +cycle-list` 必须传 `--user-id`；缺少 OKR scope 时跳过该模块，不影响日历、任务、消息和文档主流程。

### 首次初始化回顾知识空间

```bash
lark-cli wiki spaces create \
  --data '{"name":"团队回顾空间","description":"Sprint Retro / 周报 / 行动项沉淀","open_sharing":"closed"}'
```

> 真实执行会新增知识空间。默认建议 `open_sharing: "closed"`，确认后再开放。

### 报告附件展示方式

```bash
cd ./lark-retro-export
lark-cli docs +media-insert \
  --doc "<doc_token>" \
  --type file \
  --file ./retro-report.pdf \
  --file-view preview
```

> `--file-view` 支持 `card`、`preview`、`inline`。真实执行会上传本地文件，必须先展示文件路径和目标文档。

---

## 19. 常见问题

**Q: 多维表格归档需要什么 Token？**

A: 需要 `base_token`（在 Bitable URL 中 `base/` 之后的部分）和 `table_id`（通常以 `tbl_` 开头）。

**Q: 会议室预约可以自动完成吗？**

A: AI 会先列出可选会议室，你确认后才会执行预约操作，防止误订。

**Q: 画板分析支持手写内容吗？**

A: 当前主要支持画板中的文字节点（Sticky notes, Text）。手写内容依赖 OCR 能力，建议尽量使用文字组件。

**Q: lark-cli v1.0.8 还有哪些值得关注的更新？**

A: 包括批量修改记录、下载附件、画板导出代码等。`lark-retro` 主要利用了其中的批量写入、会议室找房和画板查询能力。

**Q: lark-cli v1.0.10 这次主要适配了什么？**

A: 主要适配任务清单自定义分组、报告快捷方式归档、云文档标题修正和知识库成员只读预检。其中成员增删属于高风险管理能力，不进入默认回顾流程。

**Q: lark-cli v1.0.14 这次主要适配了什么？**

A: 主要适配 OKR 只读对齐、Wiki 知识空间初始化、文档附件展示方式。邮件定时/优先级、表格单元格评论对 lark-retro 主闭环帮助较小，暂不进入主流程。
