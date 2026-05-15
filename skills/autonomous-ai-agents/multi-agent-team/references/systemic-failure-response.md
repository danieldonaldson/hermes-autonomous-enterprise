# Systemic Failure Response — Actionable Audit Checklist

> Based on the PMO orchestration audit (t_84bc1648) and COO operational audit (t_5bbd6a75) conducted 2026-05-14.
> These recommendations are the systemic fixes that prevent stuck tasks — firefighting individual tasks without actioning these means the same failures recur.

## Implementation Status (2026-05-14)

| Priority | Item | Status | Details |
|----------|------|--------|---------|
| P0.1 | Agent-based review router | ✅ DONE | Created `Review Router v2` cron (a2d282d759da), paused old script router. Agent-based, uses kanban_* tools. See multi-agent-team skill Approach E. |
| P0.2 | Help-needed routing | ✅ DONE | Included in `Review Router v2` prompt — catches both `review-required:` and `help-needed:` prefixes. |
| P0.3 | Crash/failure monitoring in CoS | ✅ DONE | Added gave_up, crashed, stale-running detection to Chief of Staff prompt. Next check-in at 12:29. |
| P1.1 | PMO Board Monitor cron | ✅ DONE | Created `PMO Board Monitor` cron (a15e31098cc8), every 2h, agent-based, delivers local. Fires at 10,12,14,16,18,20:00. |
| P1.2 | PMO Housekeeping cron | ❌ NOT YET | Still needs `kanban gc` + archive cron, daily 07:00. |
| P1.3 | COO monitoring cadence | ❌ NOT YET | Still needs COO operational review cron, 2x daily. |
| P1.4 | Finance SOUL.md | ❌ NOT YET | Still missing escalation protocol. |
| P1.5 | Deprecate Daily Standup script | ❌ NOT YET | Still active — can be disabled if CEO 09:25 covers it. |

## P0 — Blocking (fix before routing new tasks)

### P0.1: Review Router must use kanban tools, not CLI
`review-router.sh` uses `hermes kanban list --json` which fails silently in containerized backends. Convert to an agent-based cron job that uses `kanban_*` tool functions.

**Implementation:** Created `Review Router v2` (job_id: a2d282d759da) running the same `*/5 * * * *` schedule. Prompt includes both `review-required:` and `help-needed:` routing. Paused the old script-based router (job_id: ab6bab3248a1). See the `multi-agent-team` skill's Approach E for the creation command.

### P0.2: Add help-needed routing
Engineers blocked with `help-needed:` have no automated path to Tech Lead. Extend the Review Router to catch `help-needed:` prefix and route to tech-lead.

**Implementation:** Included in the Review Router v2 prompt. The agent scans all blocked tasks and checks for both `review-required:` and `help-needed:` prefixes before routing.

### P0.3: Add crash/failure monitoring to Chief of Staff
CoS checks for `blocked >4h` but not for `crashed`/`gave_up` tasks or stale running tasks (>4h since last event).

**Implementation:** Updated CoS cron prompt (job_id: ca0c65c94248) to scan for:
- `outcome: gave_up` — tasks that exhausted retries and died silently
- `outcome: crashed` or `protocol_violation` runs
- `status: running` with last event >4h ago (stale workers)

Also increased `gateway_timeout: 3600` (60 min) and `gateway_timeout_warning: 1800` (30 min) for the engineer profile to prevent timeouts on test-writing tasks.

## P1 — This Sprint

### P1.1: PMO Board Monitor cron job
PMO has no scheduled scan. Board health degrades between CoS pulses (every 4h).

**Implementation:** Created `PMO Board Monitor` (job_id: a15e31098cc8), agent-based, every 2h at 10,12,14,16,18,20:00. Scans for stale blocks >2h, gave_up/crashed tasks, WIP violations, orphaned todos. Delivers local.

### P1.2: PMO Housekeeping cron job
No automated board cleanup. Workspaces accumulate.

**Action:** Create `PMO Housekeeping` cron job, daily 07:00, runs `kanban gc` and archives resolved tasks.

### P1.3: COO monitoring cadence
COO has no scheduled deep-dive.

**Action:** Create `COO Operational Review` cron job, 2x daily (09:00, 17:00), reviews CoS output + board health. Weekly deep-dive on Monday.

### P1.4: Finance profile needs SOUL.md
Finance profile has context.md but no SOUL.md. Missing escalation protocol.

### P1.5: Deprecate Daily Standup script cron
The daily-standup.sh script is shell-only (no agent), adds no reasoning, and duplicates the CEO agent's 09:25 scan. Redundant noise.

**Action:** Disable or delete the daily-standup.sh cron job (job_id: 60b1b92cb2f8).

## P2 — Backlog

- Add dispatch priority weight to kanban config
- WIP limits on board (max 3 running tasks per agent)
- Dispatcher heartbeat monitoring (alert if >120s since last dispatch)
- Standardise ">4 hours" threshold formatting across SOUL.md files
- Cron job delivery to `origin` instead of hardcoded Telegram chat ID

## Escalation Matrix Gaps (not covered)

| Event | Auto-alert? | Fix |
|---|---|---|
| Worker crash / gave_up | ✅ DONE (CoS scans now) | P0.3 — CoS crash monitoring |
| Dispatcher stall | ❌ Not yet | P2 — heartbeat monitoring |
| Cron job failure | ❌ Not yet | Requires cron-level alert mechanism |
| help-needed: block (Tech Lead unavailable) | ✅ DONE (Review Router v2) | P0.2 — help-needed routing |
| Stale running task (>4h, no heartbeat) | ✅ DONE (CoS scans now) | P0.3 — CoS stale-running monitoring |
