<p align="center">
  <h1 align="center">🔄 lark-retro</h1>
  <p align="center">
    <strong>AI-Driven Sprint Retro & Weekly Report for Feishu/Lark</strong><br>
    One sentence triggers a retro or weekly report: auto-collect from Calendar, Tasks, Messages, Docs, Whiteboards — generate structured reports, archive to Wiki, create tasks, and <strong>pre-book the next meeting room</strong>.
  </p>
  <p align="center">
    <img src="https://img.shields.io/badge/version-2.3.0-blue" alt="version">
    <img src="https://img.shields.io/badge/license-MIT-green" alt="license">
    <img src="https://img.shields.io/badge/lark--cli-%3E%3D1.0.8-orange" alt="lark-cli">
    <img src="https://img.shields.io/badge/zero%20code-pure%20SKILL.md-blueviolet" alt="zero code">
  </p>
  <p align="center">
    <a href="README.md">中文文档</a>
  </p>
  <p align="center">
    <code>v2.3.0</code>: Next Retro Room Booking · Bitable Action Items · Whiteboard Context — fully adapted for lark-cli v1.0.8
  </p>
</p>

---

## 😩 The Problem

Every Friday afternoon, the same question hits you — what did I actually do this week?

You open the calendar, scroll through tasks, search keywords in group chats… 30 minutes later, you haven't even started writing the retro. And those action items from last sprint? Who even remembers?

That's why I built lark-retro: **one sentence, and it automatically pulls data, generates a report, and tracks action items. It even books your next meeting room.**

## 🎬 Demo

<p align="center">
  <img src="assets/demo.gif" alt="lark-retro workflow demo" width="800">
</p>

## 🆕 v2.3 Highlights (Adapting lark-cli v1.0.8)

- **Book Next Retro Room (v1.0.8)** — Suggests next time slot and uses `calendar +room-find` to find available rooms automatically.
- **Archive Action Items to Bitable (v1.0.8)** — Support syncing items to Bitable tables via `base +record-batch-create`.
- **Whiteboard Context Analysis (v1.0.8)** — Use `whiteboard +query` to export brainstorm boards as background input for the report.
- **Meeting Minutes Analysis (v1.0.7)** — Automatically analyze linked Feishu Minutes for deeper meeting insights.

## 🏗️ Architecture

```mermaid
flowchart TB
    User["🗣️ Generate last week's retro"] --> Collect

    subgraph Collect["📥 Data Collection"]
        direction LR
        C1["📅 Calendar/Min"] ~~~ C2["✅ Tasks"] ~~~ C3["💬 Messages"] ~~~ C4["🎨 Whiteboard"]
    end

    Collect --> Analyze

    subgraph Analyze["🔍 AI Analysis"]
        direction LR
        A1["Minutes Insight"] ~~~ A2["Trends"] ~~~ A3["Blockers"] ~~~ A4["History Comparison"]
    end

    Analyze --> Output

    subgraph Output["📤 Output"]
        direction LR
        O1["📝 Report Doc"] ~~~ O2["📚 Wiki"] ~~~ O3["🎯 Tasks/Bitable"] ~~~ O4["📢 Room Booking"]
    end

    Output --> Loop["🔁 Next retro auto-tracks & closes action items"]
    Loop -.->|"next cycle"| User
```

## ✅ Verified Capabilities

> v2.3.0 was regression-tested on a real Feishu account with lark-cli v1.0.8. Capabilities that require external live resources are marked separately as command/permission/parameter boundary checks.

### Full E2E Verified

- ✅ `calendar +agenda` / `minutes minutes get` — Calendar & Minutes (v1.0.7)
- ✅ `docs +search --filter` — Precise doc search (v1.0.7)
- ✅ `wiki +node-create` — Wiki node management (v1.0.7)
- ✅ `task +get-my-tasks` / `task +create` — Tasks
- ✅ `task +complete` / `task +comment` — Task closure/notes
- ✅ `im +messages-send --as bot` — Bot messages
- ✅ `im +chat-messages-list` — Group message history

### Command Verified + Permission/Parameter Boundary Verified

- ⚠️ `calendar +room-find` — Room candidate lookup command and parameter shape verified; actual booking requires user confirmation and the calendar creation flow. (v1.0.8)
- ⚠️ `base +record-batch-create` — Batch write command and payload shape verified; real writes require a target `base_token` / `table_id`. (v1.0.8)
- ⚠️ `drive +export` — Document export to Markdown command verified; real export requires readable source documents and export permissions.
- ⚠️ `whiteboard +query` — Whiteboard raw/image query command verified; real analysis requires a valid `whiteboard_token`. (v1.0.8)

## 🛠️ Technical Features

- 🚫 **Zero Code, Pure Skill** — 100% `SKILL.md`, no external dependencies.
- 🏢 **Space Loop** — Closes the loop from digital tasks to physical meeting room booking.
- 🔁 **Continuous Retro** — Auto-closes previous items and bridges to the next cycle.

## 📄 License

[MIT](LICENSE)
