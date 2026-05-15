# MiniMax HTTP 429 Bulk Cascade Pattern

## The pattern

When all (or many) profiles are configured with `provider: deepseek` / `model: deepseek-v4-flash` but the runtime shows `provider=minimax` with `base_url=https://api.minimax.io/anthropic`, the credential pool or model router is mapping the model to **MiniMax's Anthropic API-compatible endpoint** (`api.minimax.io/anthropic`). This is not a per-profile config bug — it's a routing-layer decision.

## Symptom

Every worker across **every profile** fails identically:

```
worker exited cleanly (rc=0) without calling kanban_complete or kanban_block — protocol violation
```

Agent logs show:

```
ERROR API call failed after 3 retries.
HTTP 429: The Token Plan is designed for individual, interactive developer workflows.
Traffic is currently high—please retry shortly. For higher concurrency or automated
workloads, consider upgrading to a higher-tier plan or using the pay-as-you-go API.
(2062)
provider=minimax base_url=https://api.minimax.io/anthropic model=deepseek-v4-flash
```

Followed by:

```
WARNING run_agent: credential pool: no available entries (all exhausted or empty)
```

## Diagnosis script

```bash
# 1. Check config vs runtime across ALL profiles
for p in ~/.hermes/profiles/*/config.yaml; do
    profile=$(basename $(dirname $p))
    config_provider=$(grep -E '^provider:' $p 2>/dev/null | awk '{print $2}')
    config_model=$(grep -E '^model:' $p 2>/dev/null | awk '{print $2}')
    runtime=$(grep -m1 'provider=' ~/.hermes/profiles/$profile/logs/agent.log 2>/dev/null \
      | grep -oP 'provider=\S+' | head -1)
    echo "$profile: config=$config_provider/$config_model runtime=$runtime"
done

# 2. Count error types
grep -h 'ERROR\|gave_up\|protocol_violation' ~/.hermes/profiles/*/logs/agent.log \
  | sort | uniq -c | sort -rn | head -10

# 3. Count total 429s
grep -h 'HTTP 429.*minimax' ~/.hermes/profiles/*/logs/agent.log | wc -l

# 4. Check which profiles have minimax in .env
for f in ~/.hermes/profiles/*/.env; do
    p=$(basename $(dirname $f))
    k=$(grep -o 'MINIMAX_API_KEY' $f 2>/dev/null)
    [ -n "$k" ] && echo "$p: has MINIMAX_API_KEY"
done
```

## What "config=deepseek runtime=minimax" means

This is NOT a misconfigured profile — the global credential pool or model router is redirecting `deepseek-v4-flash` through MiniMax's Anthropic-compatible API (`api.minimax.io/anthropic`). Changing each profile's `provider:` won't fix it if the routing is enforced at the credential-pool layer.

Root cause candidates:
1. **Shared credential pool** routes all models through MiniMax (check `~/.hermes/config.yaml` for `credential_pool_strategies`)
2. **Model catalog** maps `deepseek-v4-flash` to a MiniMax provider (check model catalog URL)
3. **Gateway config** overrides the provider at dispatch time (check `~/.hermes/gateway.yaml`)

## Fix

```bash
# Option A: Bypass MiniMax entirely by switching profiles to a direct provider
hermes config set --profile <name> provider deepseek
hermes config set --profile <name> model deepseek-v4-flash
# Also ensure base_url is set explicitly:
hermes config set --profile <name> base_url https://api.deepseek.com

# Option B: Upgrade the MiniMax plan from Token Plan to a paid tier
# (manual — visit MiniMax console)

# Option C: Fix the credential pool / model routing if it's enforced globally
# Check ~/.hermes/config.yaml credential_pool_strategies
```

After the fix, reclaim tasks. Start with the 3+ gave_up tasks first, then the 1-failure tasks:

```bash
hermes kanban reclaim t_396a6020 t_72686527 t_bd86f787
hermes kanban reclaim $(hermes kanban list --status blocked | grep '⊘' | awk '{print $2}')
```
