# Provider HTTP 402 Credit Exhaustion — Monitoring Cascade Blind Spot

> Reference file for `kanban-worker` skill.
> Real-world trace (2026-05-17) of DeepSeek API credit exhaustion causing ALL agent-based monitoring crons to fail simultaneously, while no-agent script crons continued running.

## The Cascade Signature

Unlike the 429 rate-limit cascade (which blocks kanban workers on the same provider), the 402 credit exhaustion pattern takes down **the monitoring agents themselves** — the crons that would normally detect and escalate failures. The board becomes blind.

### Key differentiator from 429 cascade

| Aspect | 429 Rate-Limit Cascade | 402 Credit Exhaustion |
|--------|----------------------|----------------------|
| **What fails** | Kanban workers (task execution) | **Agent-based monitoring crons** (CoS, PMO, COO, CEO, Review Router) |
| **Script-based crons** | May also fail (same provider) | **Continue running** — use no LLM credits |
| **Detection latency** | Immediate — workers crash, tasks block | **Delayed** — the monitoring agents that would detect it are dead too |
| **Recovery** | Provider switch or rate-limit cooldown | Top up credits or switch provider |
| **False sense of normalcy** | None — board is visibly stalled | **Yes** — no-agent scripts (dispatcher watchdog, domain check, git health) keep reporting "ok", masking the outage |

### Canonical agent.log error

```
2026-05-17 12:29:13,562 WARNING [cron_<job_id>] run_agent:
    Retrying API call in 5.3s (attempt 2/3)
    provider=deepseek base_url=https://api.deepseek.com
    model=deepseek-v4-flash
    error=Error code: 402 - {
      'error': {
        'message': 'Insufficient Balance',
        'type': 'unknown_error',
        'param': None,
        'code': 'invalid_request_error'
      }
    }

2026-05-17 12:29:19,899 ERROR run_agent:
    API call failed after 3 retries.
    HTTP 402: Insufficient Balance
    | provider=deepseek model=deepseek-v4-flash msgs=2 tokens=~53,674

2026-05-17 12:29:19,900 ERROR cron.scheduler:
    Job 'Chief of Staff — Enterprise Sync' failed:
    RuntimeError: HTTP 402: Insufficient Balance
```

### Cron list appearance

```
ca0c65c94248 [active]
    Name:      Chief of Staff — Enterprise Sync
    Schedule:  29 8,12,16,20 * * *
    Next run:  2026-05-17T16:29:00+02:00
    Last run:  2026-05-17T12:29:20.578235+02:00  error: RuntimeError: HTTP 402: Insufficient Balance

a2d282d759da [active]
    Name:      Review Router v2
    Schedule:  */5 * * * *
    Last run:  2026-05-17T15:42:25.443803+02:00  ok    ← recovered after balance top-up
```

Note: script-based jobs continue showing `ok` through the entire outage:
```
9eab4fa10bb2 [active]
    Name:      Dispatcher Heartbeat Watchdog
    Schedule:  */30 * * * *
    Last run:  2026-05-17T15:30:47.542049+02:00  ok    ← mask signal

01028d4049da [active]
    Name:      PMO Housekeeping — Kanban GC
    Schedule:  0 3 * * 0
    Last run:  2026-05-17T15:41:59.842646+02:00  ok    ← mask signal
```

## Diagnosis

### Step 1: Check cron job health (do this first in any board scan)

```bash
# Check for failing agent-based jobs vs healthy script jobs
hermes cron list 2>&1 | grep -E 'error:|ok'

# Specifically check monitoring crons
for job in "Chief of Staff" "PMO Board Monitor" "COO" "CEO Daily" "Review Router"; do
    hermes cron list 2>&1 | grep -A 3 "$job" | grep 'Last run'
done
```

### Step 2: Check the main agent log for 402 errors

```bash
grep 'Insufficient Balance' ~/.hermes/logs/agent.log | tail -5
```

Look for the pattern: all monitoring crons failing in the same time window with the identical 402 error.

### Step 3: Verify the mask signal

No-agent script crons (`Dispatcher Watchdog`, `Kanban GC`, `Git Health Check`, `Domain Check`) will show `ok` even during the outage because they use no LLM credits. If script crons are healthy but all agent-based crons are failing with 402, you have confirmed credit exhaustion.

## What to include in a sync report after an outage

When you're the first successful agent-based cron after a 402 outage:

1. **Flag the outage prominently** — the founder hasn't received updates since the last successful run before the outage
2. **List which crons failed and when** — so the founder knows their coverage gap
3. **Check if any intervening runs were missed** — compare the current board state against the last sync report to see if any changes happened during the blind window
4. **Recommend checking the provider billing dashboard** — top up if near limit, or consider adding a fallback provider
5. **Note that no-agent script crons were not affected** — this is the key diagnostic signal that distinguishes credit exhaustion from an infrastructure outage

### Example sync report addition

```
⚠️ **IMPORTANT: Monitoring Outage Detected**
The following agent-based crons FAILED due to DeepSeek HTTP 402 Insufficient Balance:
  - Chief of Staff (12:29) — no sync for ~3h
  - COO Operational Review (09:00) — no ops review
  - CEO Daily Strategy Check (09:25) — no strategic pulse
  - PMO Board Monitor (15:31) — no crash detection
  - Review Router v2 (15:35) — no block routing

No-agent script crons (dispatcher watchdog, git health, kanban GC, domain check)
continued running normally — board infrastructure was healthy, only LLM credits were
depleted. The board was fully stable through the outage; no changes were missed.

Recommended: Check your DeepSeek billing dashboard and top up if near limit.
```

## Prevention

### Option A: Add a fallback provider for monitoring crons

Configure a separate provider with its own credit pool for monitoring/scanning crons, distinct from the kanban worker provider. This way, if the main worker provider runs out of credits, the monitoring agents can still report.

### Option B: No-agent sentinel cron

Create a lightweight no-agent script cron that checks `hermes cron list` for error statuses on critical agent-based jobs and alerts if any have failed on the last run. This runs on zero LLM credits:

```bash
# ~/.hermes/scripts/monitor-sentinel.sh
#!/usr/bin/env bash
# Alert if any critical cron jobs failed on their last run
for job in "Chief of Staff" "PMO Board Monitor" "COO.*Review" "CEO.*Strategy"; do
    status=$(hermes cron list 2>&1 | grep -A 3 "$job" | grep 'Last run')
    if echo "$status" | grep -q 'error'; then
        echo "⚠️ CRITICAL: $job cron failed: $status"
    fi
done
```

Register with:
```bash
hermes cron create "Sentinel — Monitor Cron Health" \
  --schedule "*/15 * * * *" \
  --script monitor-sentinel.sh \
  --deliver origin \
  --no-agent
```

### Option C: Budget pre-payment and reserve pool

Maintain a separate API key with a dedicated balance reserve that's only used for monitoring crons. When the main pool depletes, monitoring is still operational to alert the team.

## Real session data (2026-05-17)

**Time window:** 09:00–15:35 SAST (~6.5 hours of intermittent failures)
**Affected crons:** CoS (failed at 12:29), COO (failed at 09:00), CEO (failed at 09:25), PMO (failed at 15:31), Review Router (failed at 15:35)
**Unaffected crons:** Dispatcher Watchdog (every 30m, all runs ok), Git Health Check (09:00 ok), Domain Check (08:45 ok), Kanban GC (15:41 ok)
**Resolution:** DeepSeek balance appears to have been refreshed/recharged by ~15:35; subsequent runs succeeded
**Board impact:** None — the board was fully stable with no ready/todo tasks and 3 blocked human-gated tasks

The key learning: the only reason we know the 402 outage happened is because this CoS run (at 15:42) succeeded. If the balance hadn't been replenished, the board would have gone entirely unattended without anyone noticing — all monitoring agents would be dead, script crons would show "ok", and the founder would see no new messages.
