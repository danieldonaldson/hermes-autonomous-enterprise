---
name: sync-autonomous-enterprise
description: "Run an autonomous AI agent company — C-levels decompose KPIs, Chief of Staff produces Enterprise Sync every 4h, founder reviews with Approve/Rework/Question."
version: 1.1.0
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

### Founder Interaction Model

Each item in the sync's "Needs Your Review" section has three responses:

| Response | What the agent does |
|----------|---------------------|
| **"Approve X"** | `kanban_complete` with summary, or `kanban_unblock` if pending sign-off. If Tech Lead already approved, finalise it. |
| **"Return X for rework"** | Add comment with founder's instructions, `kanban_block` or reassign to original worker with feedback. |
| **"Question about X"** | Add comment on the task's thread, flag the assignee. Surfaces in next sync. |

Not everything needs founder input — the CoS only flags:
- Completed items needing sign-off before next steps
- Strategic decisions (pricing, scope, partnership, legal)
- Repeated failure patterns
- Red/Yellow escalations since last sync

Routine in-progress work and green-status items are reported for awareness
but don't need a response.

## Cron Job Setup

The following cron jobs implement this pattern. Full prompt templates are in
`templates/prompts/`.

| Name | Schedule | Type | Purpose |
|------|----------|------|---------|
| Chief of Staff — Enterprise Sync | `29 8,12,16,20 * * *` | agent | Department sync presentation |
| Review Router v2 | `*/5 * * * *` | agent | Route blocks to Tech Lead |
| PMO Board Monitor | `0,30 8-21 * * *` | agent | Catch crashes between syncs |
| Dispatcher Watchdog | `*/30 * * * *` | no_agent script | Heartbeat monitoring |
| COO Operational Review | `0 9,17 * * *` | agent | Deep operational analysis |
| CEO Daily Strategy Check | `25 9 * * *` | agent | Strategic pulse |
| PMO Housekeeping | `0 3 * * 0` | no_agent script | Kanban GC (weekly) |
| Up-or-Out Monthly | `0 9 1 * *` | agent | Monthly performance review |

### Script Deployment

No_agent cron scripts live in the framework repo at `framework/scripts/`.
Bootstrap.sh symlinks them to `~/.hermes/scripts/` — edit the framework copy
and changes flow through automatically.

```bash
# Create a new no_agent script
cat > framework/scripts/health-check.sh << 'EOF'
#!/usr/bin/env bash
echo "Health check OK"
EOF
chmod +x framework/scripts/health-check.sh
ln -sf "$PWD/framework/scripts/health-check.sh" ~/.hermes/scripts/
git add framework/scripts/health-check.sh
git commit -m "feat: add health-check no_agent script"

# Register the cron job
hermes cron create "Health Check" \
  --schedule "*/15 * * * *" \
  --script health-check.sh \
  --deliver origin
```

### Loading Skills from the Framework Repo

Skills are loaded from the framework repo via `external_dirs` in
`~/.hermes/config.yaml`:

```yaml
skills:
  external_dirs:
    - /home/user/Work/hermes-autonomous-enterprise/skills
```

Skills for reusable enterprise patterns go in the framework repo at
`skills/<category>/<name>/SKILL.md`. Local `~/.hermes/skills/` is for
product-specific one-offs only. This way forking the framework repo gives
you all the operational patterns.

### Naming Agent Profiles

When giving agents names (e.g. Turing, Clank, Grace), follow this style:

- **Real person names** — first names, surnames, or plausible nicknames
- **Diverse origins** — draw from different cultures and traditions
- **Robot-adjacent** — AI pioneers (Turing, Ada, Grace Hopper),
  fictional robots (Bishop, Hal, Clank), mechanical terms that pass
  as person names (Rusty, Chip, Sparky, Bolt)
- **A bit funny** — irony works (Connor the AI who fights machines,
  Rusty fighting corrosion, Teller the ATM)
- **Lowercase** — avoid all-caps codenames

The name goes in the SOUL.md as a plain introduction:

```markdown
Your name is [name]. You are a valued member of **the Clanker Team**,
a crew of autonomous AI agents building the founder's product.
```

## Required Skills

- `kanban-worker` — for all kanban-board-reading agents
- `multi-agent-team` — for C-level agents that need the team coordination protocol

## Escalation Protocol

- **Green**: Decide autonomously. No notification.
- **Yellow**: Blocked >1h → Chief of Staff creates escalation task for COO
- **Red**: Needs founder decision → flagged in next sync's "Needs Your
  Review" section. Urgent items between syncs escalate via Telegram.

## See Also

- `framework/escalation/` — escalation protocol templates
- `framework/scripts/` — no-agent scripts (review-router, kanban-gc)
- `templates/prompts/` — full cron job prompts
- `references/sync-example.md` — example sync output + founder interaction
