# Two-Wave 429 Cascade → "pid not alive" on Retry

> Reference file for `kanban-worker` skill.
> Real-world trace of a bulk cascade where Wave 1 fails with 429 protocol_violation,
> Wave 2 (after unblock) fails with "pid not alive" due to credential pool exhaustion.

## The Cascade (2026-05-14)

**Board:** 71 blocked tasks across 14 assignees
**Provider:** All profiles configured `deepseek/deepseek-v4-flash`, runtime routed through `minimax@api.minimax.io/anthropic`

### Wave 1 (15:48–15:50 UTC) — Protocol Violation

71 tasks dispatched simultaneously. Every worker starts, hits MiniMax HTTP 429 immediately (zero successful API calls), exits without calling `kanban_complete` or `kanban_block`. All show:

```
[run N] spawned {'pid': XXXXXX}
[run N] protocol_violation {'pid': XXXXXX, 'exit_code': 0}
gave_up {'failures': 1, 'error': 'worker exited cleanly (rc=0) without calling
         kanban_complete or kanban_block — protocol violation'}
```

Agent logs show:

```
ERROR API call failed after 3 retries.
  HTTP 429: The Token Plan is designed for individual, interactive developer
  workflows. Traffic is currently high—please retry shortly. ...
  provider=minimax base_url=https://api.minimax.io/anthropic model=deepseek-v4-flash
```

Followed by credential pool exhaustion:

```
INFO agent.credential_pool: credential pool: no available entries (all exhausted or empty)
```

### Unblock (16:44 UTC)

~40+ tasks unblocked in bulk. The root cause (MiniMax 429 / credential pool exhaustion) was NOT fixed before unblocking.

### Wave 2 (16:45–16:46 UTC) — "pid not alive"

Workers spawn again but immediately crash — the credential pool has no entries available:

```
[run N] claimed {'lock': '...', 'expires': 1778770845, 'run_id': N}
[run N] spawned {'pid': 20787XX}
[run N] crashed {'pid': 20787XX, 'claimer': '...'}
gave_up {'failures': 2, 'error': 'pid 20787XX not alive'}
```

Note the **different error from Wave 1**: protocol_violation → "pid not alive". A monitoring agent that only checks for `protocol_violation` on retry would miss this signal.

### Outcome

All 71 tasks are now `gave_up` with 2 failures each. The board is fully stalled.

## Key Diagnostic Signals

| Signal | What it means |
|---|---|
| ~70 tasks blocked at same timestamp | Bulk cascade, not isolated failures |
| Wave 1 all have same error (429) | Shared exhausted resource |
| Wave 2 error differs from Wave 1 ("pid not alive") | **Credential pool is bone-dry** — unblock was premature |
| `credential pool: no available entries` in agent.log | Pool exhaustion confirmed |

## Timeline Verification

```bash
# Check which tasks have both protocol_violation AND pid-not-alive
for tid in $(hermes kanban list --status blocked 2>&1 | grep '⊘' | awk '{print $2}'); do
    show=$(hermes kanban show "$tid" 2>&1)
    pv=$(echo "$show" | grep -c 'protocol_violation')
    pna=$(echo "$show" | grep -c 'not alive')
    echo "$tid: protocol_violation=$pv pid_not_alive=$pna"
done | grep -v '0.*0'
```

## Correct Recovery Sequence

```bash
# 1. Fix the provider routing first (this is what should have happened at 16:44)
#    Check: is routing happening at credential pool layer or profile level?
grep -A 5 'credential_pool' ~/.hermes/config.yaml

# 2. Explicitly set base_url to bypass MiniMax routing
hermes config set --profile engineer provider deepseek
hermes config set --profile engineer model deepseek-v4-flash
hermes config set --profile engineer base_url https://api.deepseek.com

# 3. Test one task before bulk reclaim
hermes kanban dispatch

# 4. Reclaim all tasks
hermes kanban list --status blocked 2>&1 | grep '⊘' | awk '{print $2}' \
  | while read tid; do hermes kanban reclaim "$tid"; done
```
