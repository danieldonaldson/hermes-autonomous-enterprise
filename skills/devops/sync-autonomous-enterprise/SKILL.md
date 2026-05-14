---
name: sync-autonomous-enterprise
description: "Run an autonomous AI agent company — C-levels decompose KPIs, Chief of Staff produces Enterprise Sync every 4h, founder reviews with Approve/Rework/Question."
version: 1.0.0
platforms: [linux, macos]
metadata:
  hermes:
    tags: [enterprise, sync, autonomous, orchestration, kpi]
    related_skills: [multi-agent-team, kanban-worker, hermes-agent]
---

# Sync Autonomous Enterprise

A pattern for running an autonomous AI agent company where the founder reviews
progress at scheduled sync points instead of being in the daily loop.

## The Problem

In a multi-agent kanban system, someone needs to:
1. Decompose high-level goals into work items
2. Review completed work
3. Make strategic decisions that agents can't make

Without a cadence, the founder either micromanages (defeating autonomy) or
checks in randomly (missing critical decisions).

## The Pattern

```
KPI Framework → C-levels decompose KPIs → Teams execute
  → CoS reads board every 4h → Sync to founder
    → Founder reviews + gives Approve/Rework/Question
      → Agent processes instructions → Teams continue
        → Next sync shows results
```

### Key Components

**1. C-Level Decomposition** — Each C-level reads the KPI framework and breaks
their department's KPIs into granular kanban tasks (≤30 min, single outcome)
for their direct reports. Tech Lead gates task granularity before work starts.

**2. Enterprise Sync (every 4 hours)** — Chief of Staff scans the board and
produces a department-by-department presentation for the founder:
- ✅ Completed since last sync
- 🔄 In progress  
- ❌ Blocked
- 📋 Queued
- → Review needed items with Approve/Rework/Question options

**3. Fast Monitoring (between syncs)** — PMO scans every 30 min for crashes,
Review Router runs every 5 min for block routing, Dispatcher Watchdog every
30 min for heartbeats.

**4. Founder Review** — Founder reads the sync at their convenience, responds
with Approve/Rework/Question instructions. An agent processes them
asynchronously — no meeting needed.

## Cron Job Setup

The following cron jobs implement this pattern. Prompts are in `templates/`.

| Name | Schedule | Purpose |
|------|----------|---------|
| Chief of Staff — Enterprise Sync | `29 8,12,16,20 * * *` | Produce sync presentation |
| Review Router v2 | `*/5 * * * *` | Route blocks to Tech Lead |
| PMO Board Monitor | `0,30 8-21 * * *` | Catch crashes between syncs |
| COO Operational Review | `0 9,17 * * *` | Deep operational analysis |
| CEO Daily Strategy Check | `25 9 * * *` | Strategic pulse |
| PMO Housekeeping | `0 3 * * 0` | Kanban GC (weekly) |
| Up-or-Out Monthly | `0 9 1 * *` | Monthly performance review |

## Required Skills

- `kanban-worker` — for all kanban-board-reading agents
- `multi-agent-team` — for C-level agents that need the team coordination protocol

## Escalation Protocol

- **Green**: Decide autonomously. No notification.
- **Yellow**: Blocked >1h → Chief of Staff creates escalation task for COO
- **Red**: Needs founder decision → flagged in next sync. Urgent items between
  syncs escalate via Telegram/Slack/whatever channel is configured.

## See Also

- `framework/escalation/` — escalation protocol templates
- `framework/scripts/` — no-agent scripts (review-router, kanban-gc)
- `templates/prompts/` — full cron job prompts
