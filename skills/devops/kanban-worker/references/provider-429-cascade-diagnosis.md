# Provider HTTP 429 Cascade Diagnosis

> Reference file for `kanban-worker` skill — Board Health Scan procedure.
> Captures the specific error patterns, diagnostic commands, and resolution steps for a bulk cascade caused by provider rate limiting.

## The Cascade Signature

A **bulk cascade failure** due to provider rate limiting produces these synchronized symptoms across all affected profiles:

1. Multiple tasks (10-70+) blocked at nearly the same timestamp
2. All show `protocol_violation` with the identical message: *"worker exited cleanly (rc=0) without calling kanban_complete or kanban_block"*
3. No successful API calls in any profile's agent.log during the failure window
4. All 3 retries exhausted on every attempt

## Cannonical Agent Log Error (May 2026)

The exact error from a MiniMax Token Plan rate limit:

```
2026-05-14 15:54:31,450 WARNING run_agent: API call failed (attempt 3/3)
    error_type=RateLimitError
    provider=minimax base_url=https://api.minimax.io/anthropic
    model=deepseek-v4-flash
    summary=HTTP 429: {
      'type': 'error',
      'error': {
        'type': 'rate_limit_error',
        'message': 'The Token Plan is designed for individual, interactive developer workflows. Traffic is currently high—please retry shortly. For higher concurrency or automated workloads, consider upgrading to a higher-tier plan or using the pay-as-you-go API. (2062)'
      }
    }

2026-05-14 15:54:31,819 ERROR root: API call failed after 3 retries.
    HTTP 429: ... | provider=minimax model=deepseek-v4-flash
    msgs=7 tokens=~11,787
```

Coupled with credential pool exhaustion:

```
2026-05-14 15:54:35,504 INFO agent.credential_pool:
    credential pool: no available entries (all exhausted or empty)
```

## Diagnostic Commands

### Quick cascade confirmation

```bash
# Check how many unique error patterns across all profiles
grep -h 'ERROR\|gave_up\|protocol_violation' ~/.hermes/profiles/*/logs/agent.log \
  | sort | uniq -c | sort -rn | head -10
```

A single error dominating (e.g. 50+ occurrences of HTTP 429) = confirmed cascade.

### Count affected tasks

```bash
# Blocked tasks total
hermes kanban list 2>&1 | grep -c '⊘'

# Among them, how many have gave_up in their event log
# (requires iteration - see Board Health Scan Step 2)
```

### Check the credential pool

```bash
# No credential pool file exists by default; if it does:
cat ~/.hermes/credential_pool.yaml 2>/dev/null
# Or check the config for pool strategies:
grep -A 5 'credential_pool' ~/.hermes/config.yaml
```

### Compare profile config vs runtime behavior

Profiles may claim one provider in `config.yaml` but route through another at runtime. A credential pool or gateway routing layer can remap providers without the profile config reflecting it.

```bash
# Check what the profile thinks it's using:
grep -E '^provider:|^model:|^base_url:' ~/.hermes/profiles/<name>/config.yaml

# Check what actually happens at runtime (the agent.log is the source of truth):
grep 'provider=' ~/.hermes/profiles/<name>/logs/agent.log | tail -3
```

Example mismatch detected May 2026: profiles configured `provider: deepseek` with `base_url: https://api.deepseek.com` but agent.log showed `provider=minimax base_url=https://api.minimax.io/anthropic` — the credential pool/gateway was routing DeepSeek traffic through MiniMax.

### Check if kanban is in disabled_toolsets (Cause A)

```bash
for profile in engineer cpo cto cmo coo legal finance designer; do
    grep -A 5 'disabled_toolsets' ~/.hermes/profiles/$profile/config.yaml 2>/dev/null \
      | grep -q kanban && echo "$profile: Cause A (kanban disabled)"
done
```

## Root Cause Resolution

### Short-term: Switch provider on affected profiles

```bash
hermes config set --profile <name> provider deepseek
hermes config set --profile <name> model deepseek-v4-flash
hermes config set --profile <name> base_url https://api.deepseek.com
```

### Medium-term: Increase retries and runtime on new tasks

The `--max-retries` flag on `hermes kanban create` overrides the dispatcher's `kanban.failure_limit`:

```bash
hermes kanban create "task title" \
  --assignee engineer \
  --max-runtime 1800 \
  --max-retries 3
```

### Recovery: Reclaim gave_up tasks

After the provider fix is verified working on a test dispatch:

```bash
# Reclaim all gave_up tasks in bulk
hermes kanban list --status blocked 2>&1 | grep '⊘' | awk '{print $2}' \
  | while read tid; do
      hermes kanban reclaim "$tid"
    done
```

## Prevention: Monitor for cascade precursors

Track these leading indicators to catch a cascade before it hits:

1. **Dispatcher stats** — if the gateway log shows `spawned=N crashed=N timed_out=N` with N>0 on consecutive ticks, investigate immediately
2. **Agent log 429 count** — grep for `HTTP 429` across all profile logs
3. **Credential pool health** — check if pool entries have distinct, non-expired API keys
