# dispatch_in_gateway Override Pattern — 24-Profile MiniMax Cascade

## Overview

When `kanban.dispatch_in_gateway: true` in `~/.hermes/config.yaml`, the gateway controls provider routing for all dispatched kanban workers. This means the profile's configured `provider:` / `model:` settings may be **overridden** by the gateway's internal model-to-provider mapping.

This file documents a real-world cascade where this caused a 69-task board-wide failure.

## Cascade Timeline

| Time | Event |
|------|-------|
| 15:48–15:49 | CMO dispatches ~20 marketing tasks (CM, GL, CMM, SB, CS) |
| 15:49–15:54 | **Wave 1:** All workers spawn, all hit MiniMax HTTP 429 on first API call. Protocol violation across ALL profiles. Credential pool exhausts MINIMAX_API_KEY. |
| 16:44 | Human operator unblocks tasks (prematurely — no root cause fix) |
| 16:45–17:58 | **Wave 2:** Workers respawn but credential pool has "no available entries" → immediate `pid not alive` crash. Engineer tasks (t_d6c5faf9, t_85581be7) get 3 gave_up events. |
| 17:48 | Another unblock attempt — same result |
| 18:00 | t_85581be7 (engineer) gets a 4th attempt that actually succeeds through MiniMax (partial recovery) |

## Diagnostics (what was found)

### 1. Profile sweep — universal mismatch

```
audit-governance:    config=deepseek/deepseek-v4-flash runtime=provider=minimax
ceo:                 config=deepseek/deepseek-v4-flash runtime=provider=minimax
cmo:                 config=deepseek/deepseek-v4-flash runtime=provider=minimax
community-manager:   config=deepseek/deepseek-v4-flash runtime=provider=minimax
engineer:            config=deepseek/deepseek-v4-flash runtime=provider=minimax
...
mckinsey-consultant: config=/ runtime=provider=deepseek   ← EXCEPTION
```

Every profile (24/25) shows `config=deepseek` but `runtime=minimax`. The **mckinsey-consultant** exception proves the routing layer is the issue — it has no explicit config but routes correctly to deepseek because it's not dispatched through the gateway.

### 2. DEEPSEEK_API_KEY is present

```
$ grep -oP '^[A-Z_]+_API_KEY' ~/.hermes/profiles/engineer/.env
OPENROUTER_API_KEY GLM_API_KEY KIMI_API_KEY MINIMAX_API_KEY ...
MINIMAX_CN_API_KEY ... DEEPSEEK_API_KEY
```

All 24 profiles have DEEPSEEK_API_KEY in `.env`. This rules out the classic "missing key" diagnosis.

### 3. Supporting config — all empty/disabled

```yaml
# ~/.hermes/config.yaml
credential_pool_strategies: {}    # No provider routing override
fallback_providers: []             # No fallback list
smart_model_routing:
  enabled: false                   # Smart routing disabled
kanban:
  dispatch_in_gateway: true        # WINNER — gateway controls routing
```

No gateway.yaml exists. The model catalog is remote (`model_catalog.url: https://hermes-agent.nousresearch.com/docs/api/model-catalog.json`) and has `deepseek/deepseek-v4-pro` under OpenRouter but no explicit `deepseek-v4-flash` entry. The gateway's internal mapping sends `deepseek-v4-flash` to MiniMax.

### 4. Error transcript

```
WARNING run_agent: API call failed (attempt 3/3) error_type=RateLimitError
  provider=minimax base_url=https://api.minimax.io/anthropic
  model=deepseek-v4-flash
  summary=HTTP 429: The Token Plan is designed for individual, interactive
  developer workflows. Traffic is currently high—please retry shortly.
  For higher concurrency or automated workloads, consider upgrading
  to a higher-tier plan or using the pay-as-you-go API. (2062)
```

Key detail: `base_url=https://api.minimax.io/anthropic` — MiniMax's Anthropic-compatible endpoint. The model name `deepseek-v4-flash` is passed through to MiniMax as-is.

## Root Cause

`dispatch_in_gateway: true` + the gateway routes `deepseek-v4-flash` through MiniMax instead of DeepSeek. The single MINIMAX_API_KEY in the credential pool gets rate-limited by MiniMax's "Token Plan" limit after ~5-10 concurrent requests. All workers spawn under the same dispatch cycle, hit the limit simultaneously, and the pool exhausts the single key.

## Fix Options (used in this session)

**Option A — Disable dispatch_in_gateway (recommended):**
```bash
hermes config set kanban.dispatch_in_gateway false
```
This lets each profile use its own `provider: deepseek` and DEEPSEEK_API_KEY directly. No gateway routing layer.

**Option B — Fix model catalog routing:**
Add a local override in `~/.hermes/config.yaml`:
```yaml
model_catalog:
  enabled: true
  url: https://hermes-agent.nousresearch.com/docs/api/model-catalog.json
  ttl_hours: 24
  providers:
    deepseek-v4-flash:
      provider: deepseek
      base_url: https://api.deepseek.com
```

**Option C — Route through OpenRouter:**
```bash
hermes config set --profile <name> provider openrouter
hermes config set --profile <name> model openrouter/deepseek/deepseek-v4-flash
```

## Partial Recovery Signal

At 18:00, run #318 on `t_85581be7` (engineer, webhook verify_signature tests) was dispatched and **succeeded** through MiniMax despite the credential pool showing "no available entries" 7 seconds earlier. The agent.log showed:

```
API call #8: model=deepseek-v4-flash provider=minimax in=51920 out=103
  total=52023 latency=4.2s cache=45440/51920 (88%)
API call #9: model=deepseek-v4-flash provider=minimax in=52415 out=392
  total=52807 latency=12.0s cache=51904/52415 (99%)
```

This indicates that MiniMax's rate limit is per-IP or per-key with a rolling window — individual requests can succeed if spaced out, but concurrent bursts (5+ simultaneous) all get 429. The credential pool marks the key exhausted on first 429 and doesn't retry until the next dispatch cycle.

**Monitoring insight:** When the credential pool shows "no available entries" but individual runs are succeeding, the pool's cooldown timer has expired but concurrent bursts still fail. This is NOT a true recovery — the constraint is throughput, not availability.

## Board Stats at Scan Time (18:00)

| Metric | Value |
|--------|-------|
| Total tasks | 134 |
| Done | 64 |
| Blocked | **69** (51.5%) |
| Running | 1 |
| Ready | 0 |
| Profiles affected | 24 |
| Blocked tasks per profile | community-manager(9), growth-lead(9), engineer(9), content-marketing(7), customer-success(6), operations-analyst(6), sales-bd(5), pmo(4), user-research(4), cpo(4), rmo(3), audit-governance(3), designer(2), tech-lead(1), community-manager-additional(2) |

## What NOT to Do

- **Do NOT add DEEPSEEK_API_KEY** — it's already there. The routing layer ignores it when dispatch_in_gateway is true.
- **Do NOT change profile provider settings** — they're correct (`provider: deepseek`). The gateway overrides them.
- **Do NOT bulk-unblock without fixing the gateway** — this creates the retry death spiral documented in the main skill (unblock → spawn → gave_up → repeat).
- **Do NOT assume the mckinsey-consultant profile's success means anything** — it routes directly to deepseek because it's not in the gateway dispatch pool.
