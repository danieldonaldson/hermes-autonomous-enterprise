# Proactive Fixes During Board Scan

> Reference file for the `kanban-worker` skill's Board Health Scan procedure.
> Patterns for what a monitoring agent (COO, PMO, CoS) should fix on the spot
> vs. report/escalate during a board scan.

## Principle

A monitoring agent's output is not the end goal — fixing the board is. If you
can fix an issue immediately (profile reassignment, task reclaim, comment
update), do it. Only escalate or report when the fix requires human judgment
or config changes you can't make.

## Pattern 1: Orphaned Ready Tasks (Assigned to Non-Existent Profiles)

**Symptom:** A task shows `status: ready` but the assignee field doesn't match
any existing profile in `hermes profile list`.

**Session example (2026-05-14):** Two ready tasks found at 17:05:
- `t_02ada862` assigned to `audit` (no such profile) → actual profile: `audit-governance`
- `t_7511d18e` assigned to `cfo` (no such profile) → actual profile: `finance`

**Fix (immediate):**
```bash
hermes kanban reassign t_02ada862 audit-governance
hermes kanban reassign t_7511d18e finance
```

After reassignment, the dispatcher picks them up naturally on the next cycle
(~60s). These tasks would have sat in `ready` forever if not caught.

**How to detect in a scan:**

```bash
# Get all valid profile names (skip the header line)
valid_profiles=$(hermes profile list 2>&1 | tail -n +2 | awk '{print $1}')

# Get all ready tasks
hermes kanban list 2>&1 | while read -r line; do
    symbol=$(echo "$line" | awk '{print $1}')
    [ "$symbol" = "▶" ] || continue
    task_id=$(echo "$line" | awk '{print $2}')
    assignee=$(echo "$line" | awk '{print $4}')
    if ! echo "$valid_profiles" | grep -qw "$assignee"; then
        echo "ORPHANED: $task_id assigned to '$assignee' — not a valid profile"
    fi
done
```

**Common mismatches to check for:**
| Non-existent name | Correct profile |
|---|---|
| `audit` | `audit-governance` |
| `cfo` | `finance` |
| `cmo` (singular) | Already valid, but check for `cmo-team` → individual team members |
| `sales` | `sales-bd` |
| `qa` | `head-of-quality` or `quality-assurance` |
| `support` | `customer-success` |

## Pattern 2: Root Cause Already Known, Escalate Actionably

**Symptom:** The board has a bulk cascade failure (50+ tasks all failed
identically) and the root cause is clear from log inspection.

**Session example (2026-05-14):** 71 blocked tasks, 0 running, all with
identical MiniMax HTTP 429 errors. Config says `provider: deepseek` but
runtime routes through `api.minimax.io/anthropic`. Credential pool exhausted.

**What the monitor should do:**
1. **Diagnose** — cross-reference profile configs vs runtime provider. If
   config says X but runtime shows Y, the issue is at the routing/credential
   pool layer, not per-profile config.
2. **Log findings to a plan file** so the founder has the exact diagnosis.
3. **Do NOT attempt to fix the credential pool** — that's infrastructure
   config that needs human judgment (the routing logic may be intentional).
4. **Do NOT unblock or reclaim tasks** until the provider fix is in place.
   Unblocking without fixing creates a death spiral (see `references/two-wave-429-pid-not-alive-cascade.md`).

```bash
# Diagnostic commands used in session:
# 1. Profile config sweep
for p in ~/.hermes/profiles/*/config.yaml; do
    profile=$(basename $(dirname $p))
    provider=$(grep -E '^provider:' "$p" | awk '{print $2}')
    model=$(grep -E '^model:' "$p" | awk '{print $2}')
    runtime_provider=$(grep -m1 'provider=' ~/.hermes/profiles/$profile/logs/agent.log 2>/dev/null \
      | grep -oP 'provider=\S+' | head -1)
    echo "$profile: config=$provider/$model runtime=$runtime_provider"
done

# 2. Check credential pool exhaustion
grep -h 'credential pool' ~/.hermes/profiles/*/logs/agent.log 2>/dev/null

# 3. Count error patterns across all profiles
grep -h 'HTTP 429\|RateLimitError\|api.minimax.io' ~/.hermes/profiles/*/logs/agent.log \
  2>/dev/null | sort | uniq -c | sort -rn | head -10
```

## Pattern 3: Fix vs Escalate Decision Matrix

| Discovery | Fix immediately? | How |
|---|---|---|
| Ready task assigned to non-existent profile | ✅ Yes | `kanban reassign <id> <correct-profile>` |
| Blocked task with review-required but no review task | ✅ Yes | Create Tech Lead review task (Approach A) |
| Blocked task with approval comment but still blocked | ✅ Yes | `kanban unblock <id>` (CoS green action) |
| Bulk cascade failure (identical crash on 50+ tasks) | ❌ No — diagnose only | Write plan file, do NOT unblock |
| Stuck worker (PID alive, no progress) | ✅ Yes | `kill <pid>` + `kanban reclaim <id>` |
| Individual task gave_up once (no pattern) | ❌ No — let retry handle it | Note in report |
| Task gave_up 2+ times (identical error, chronic) | ❌ No — escalate | Create escalation task |
| Profile config stale (wrong provider/model) | ⚠️ Cautious yes | `hermes config set --profile` if known-good values |
| Misassigned Engineer/Tech Lead tasks | ✅ Yes | `kanban reassign` to correct role |

## Key Principle

Fix everything you can fix with a single CLI command (`reassign`, `unblock`,
`reclaim`, `comment`). For anything that requires config changes, credential
pool edits, or provider switches — diagnose thoroughly and let the founder
decide. A detailed plan file is worth more than a vague escalation message.
