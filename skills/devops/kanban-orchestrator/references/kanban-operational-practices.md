# Kanban Operational Practices — System Health & Maintenance

These practices keep the kanban orchestration system healthy: monitoring, housekeeping, priority discipline, and dependency enforcement. They're complementary to the decomposition playbook in the main SKILL.md.

## Priority Conventions

The kanban system supports `--priority PRIORITY` as a dispatch tiebreaker (higher number = higher priority). Use these conventions consistently so the dispatcher routes work correctly:

| Priority | Category | Examples |
|----------|----------|----------|
| 0 | Foundation | Core architecture, blocking infrastructure, foundational build tasks |
| 1 | Critical path | MVP blockers, time-sensitive items, customer-facing fixes |
| 2 | Standard | Feature work, enhancements, non-urgent tasks |
| 3+ | Low priority | Nice-to-haves, research, housekeeping, technical debt |

Tasks created without an explicit priority default to 0. Fix tasks in the re-review cycle should use priority 1 (critical path) since they're time-sensitive.

## Board Dependency Enforcement

For sequential tasks where one task's output feeds into another, enforce ordering using `kanban_link parent_id child_id`:

- The **child task** waits for the **parent task** to complete before promoting to `ready`
- The child stays in `todo` until every parent reaches `done`
- Use this for any sequential workflow where order matters

**Common patterns:**
- **Audit chain:** PMO audit (parent) → COO review (child) — COO should not start until PMO's findings exist
- **Re-review cycle** (already in main SKILL.md): Fix task's parent = original task; Re-review task's parent = fix task
- **Pipeline:** Research (parent) → Implement (child) → Review (child of implement)

## Dispatcher Health Monitoring

The dispatcher runs inside the gateway (`kanban.dispatch_in_gateway: true`, typically 60s interval). If it stalls, tasks pile up in `ready` without being claimed.

**Symptoms of a stalled dispatcher:**
- Tasks stuck in `ready` for >2 minutes (normal dispatch should claim them within 60s)
- `hermes gateway status` shows gateway running but no recent task events
- `kanban stats` shows `oldest_ready_age_seconds` growing without bound

**Recommended setup — Dispatcher Heartbeat Watchdog:**
A no_agent script that runs every 30 minutes and checks:
1. Gateway service is running (`systemctl --user is-active hermes-gateway.service`)
2. Kanban stats respond (board is queryable)
3. No task has been `ready` for >10 minutes without being claimed

Location: `~/.hermes/scripts/dispatcher-watchdog.sh`
Cron job: `*/30 * * * *`, no_agent, deliver `origin` (reports only on failure — silent when healthy)

The script is simple enough to create fresh if it's missing:
```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. Check gateway running
if ! systemctl --user is-active --quiet hermes-gateway.service 2>/dev/null; then
  echo "🚨 [DISPATCHER WATCHDOG] Gateway service is NOT running!"
  systemctl --user status hermes-gateway.service 2>&1 | head -10
  exit 1
fi

# 2. Query kanban stats
LAST_CHECK=$(hermes kanban stats --json 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "⚠️ [DISPATCHER WATCHDOG] Cannot query kanban stats"
  exit 1
fi

# 3. Check for stale ready tasks
OLDEST_READY=$(echo "$LAST_CHECK" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('oldest_ready_age_seconds') or 'null')" 2>/dev/null)
if [ "$OLDEST_READY" != "null" ] && [ "$OLDEST_READY" -gt 600 ] 2>/dev/null; then
  echo "⚠️ [DISPATCHER WATCHDOG] Task ready for ${OLDEST_READY}s without being claimed"
  exit 1
fi
exit 0
```

## Housekeeping Cron Patterns

| Cron | Schedule | Type | Purpose |
|------|----------|------|---------|
| Kanban GC | Weekly (Sunday 03:00) | no_agent, `hermes kanban gc` | Cleans up archived task workspaces, vacuums DB |
| PMO Board Monitor | Every 2h (business hours) | agent, kanban-worker | Scans for blocked, stale, stuck tasks |
| COO Operational Review | 09:00 + 17:00 (daily) | agent, kanban-worker | Cross-references PMO + CoS outputs, identifies systemic issues |
| Dispatcher Watchdog | Every 30 min | no_agent | Silent health check — alerts only on failure |

**For agent-based health crons:** Put a CRITICAL RULE at the very top of the prompt (in all-caps, before any task instructions) telling the agent it MUST produce meaningful output even when nothing is wrong. Without this, the cron scheduler will log `agent returned [SILENT] — skipping delivery` and the user gets no check-in.

**Distinguish "report" from "act" in monitoring prompts.** The most common failure of monitoring agent prompts is giving the agent a detection checklist but only telling it to "report findings." When an agent detects a gave_up/crashed task with ≥2 failures, reporting alone is invisible to other systems — no board artifact exists for other agents to act on. Design monitoring prompts with two action tiers:

- **Informational findings** (board is healthy, nothing changed) → report in prose output
- **Actionable findings** (gave_up ≥2, crashed, stale >4h) → create a kanban task for escalation, then report what you created

A monitoring agent without `kanban_create` in its action vocabulary will never escalate — it will report the same gave_up task every single scan and the founder will never see it. If the agent has the kanban toolset (`kanban-worker` skill), it can and should create escalation tasks for repeated failures.

## Recovery from Audit Findings

When PMO/COO audits produce findings, the standard remediation loop:

1. **P0 findings** (blocking operational health): Fix immediately — review router, block routing, crash monitoring
2. **P1 findings** (significant gaps, this sprint): Fix after P0s — missing cron jobs, missing SOUL.md files, config gaps
3. **P2 findings** (backlog, improvements): Fix as time permits — priority conventions, formatting consistency, delivery standardization

For each finding:
- Create the fix (file, config change, cron job, script)
- Update memory with the new state (cron list, config changes, script locations)
- If the fix changes how profiles or crons behave, note it in the relevant SOUL.md or cron prompt

## Common Profile Issues

**Broken symlinks in profile directories:**
If a profile's `SOUL.md` or `config.yaml` is a symlink pointing to a non-existent file (e.g., the framework role directory doesn't exist or was renamed), tools that read the profile will get empty results. Check with:
```bash
find ~/.hermes/profiles/<name>/ -type l -xtype l
```
Fix by creating real files or updating the symlink target.

**Missing SOUL.md:**
A profile without SOUL.md relies entirely on its config.yaml and context.md. For roles that need escalation protocols, decision frameworks, or team structure, SOUL.md is essential. Check:
```bash
ls ~/.hermes/profiles/<name>/SOUL.md 2>/dev/null || echo "MISSING"
```
