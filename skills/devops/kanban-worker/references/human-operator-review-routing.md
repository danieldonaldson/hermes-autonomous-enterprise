# Human Operator: Quick Review Routing & Profile Model Changes

This reference covers two operational patterns for a human operator (or chat agent) working at the CLI — not an automated cron router.

## Pattern 1: Route a review-required block to Tech Lead

When you find an engineer task blocked with `review-required:` on the kanban board, the fastest unblock sequence is a three-command chain:

```bash
# 1. Reassign the blocked task to the reviewer
hermes kanban reassign <task_id> tech-lead

# 2. Unblock it (transitions from blocked → ready)
hermes kanban unblock <task_id>

# 3. Force dispatch so it spawns immediately (not waiting 60s gateway cycle)
hermes kanban dispatch
```

The dispatcher output should show `Spawned: 1 - <task_id> -> tech-lead`. The Tech Lead's worker then reviews the code and either approves (`kanban_unblock`) or requests changes (creates fix tasks and re-blocks with `changes-required`).

**Why this works:** The task is still assigned to the original engineer. `reassign` moves it to tech-lead. `unblock` transitions it to ready. `dispatch` skips the 60s gateway polling interval and spawns a worker immediately.

**Pitfall:** Do NOT do this for tasks blocked with a system-generated reason (e.g. `gave_up`, `timed_out`, `crashed`) — those are dead tasks that need root cause diagnosis, not routing. Only route tasks blocked by a worker's `kanban_block(reason="review-required:...")` call.

## Pattern 2: Check what model/provider a profile is running on

A profile has three layers of configuration that can diverge:

```bash
# Layer 1 — config.yaml (what the profile is configured to use)
grep -E '^(provider:|model:|base_url:)' ~/.hermes/profiles/<profile>/config.yaml

# Layer 2 — agent.log (what it's actually using at runtime)
grep -oP 'provider=\S+' ~/.hermes/profiles/<profile>/logs/agent.log | tail -3

# Layer 3 — .env (which API keys are actually available)
grep -oP '^[A-Z_]+_API_KEY' ~/.hermes/profiles/<profile>/.env
```

**Config = Runtime:** Profile is working as configured. No action needed.

**Config says deepseek, runtime says minimax (or other):** The configured provider's API key is likely missing from `.env`. The routing layer falls back to whichever provider DOES have a key. Diagnosis:

```bash
# Check if the configured provider's key exists
grep 'DEEPSEEK_API_KEY' ~/.hermes/profiles/<profile>/.env
# If empty -> missing key is the root cause
```

Fix: Add the missing key (preferred — keeps config correct):
```bash
echo "DEEPSEEK_API_KEY=sk-..." >> ~/.hermes/profiles/<profile>/.env
```

## Pattern 3: Change a running profile's model

Use `hermes config set` — no file editing needed:

```bash
hermes config set --profile <profile> model <model-name>
```

Find available model names from the model catalog:
```bash
curl -s https://hermes-agent.nousresearch.com/docs/api/model-catalog.json | \
  python3 -c "import json,sys; d=json.load(sys.stdin); prov=d.get('providers',{}); \
  [print(f'{p}: {m[\"id\"]}') for p in prov for m in prov[p].get('models',[]) if 'deep' in m.get('id','').lower()]"
```

**Key gotcha: already-spawned workers won't pick up the change.** The model config is read at spawn time. If a worker was already dispatched under the old model (`deepseek-v4-flash`), it finishes under that model. Only NEW dispatches use the new model (`deepseek-v4-pro`). To make an already-running task use the new model, you'd need to reclaim it and let it re-spawn.

**Direct provider vs OpenRouter model naming:**
- Direct deepseek: `deepseek-v4-pro`, `deepseek-v4-flash`
- Via OpenRouter: `deepseek/deepseek-v4-pro`, `deepseek/deepseek-v4-flash`
- Via nous: `deepseek/deepseek-v4-pro`

Use the direct short name when the profile's `provider:` is `deepseek`. Use the OpenRouter-prefixed form when `provider:` is `openrouter`.

## Pattern 4: Quick board scan for blocked tasks

```bash
# All blocked tasks
hermes kanban list | grep '⊘'

# Show details — first check if block reason is review-required or system-generated
hermes kanban show <task_id> | grep -A 2 'block reason\|reason:'
```

A worker-set block reason looks like:
```
→ review-required: <summary of work done>
```

A system-generated block looks like:
```
→ worker exited cleanly (rc=0) without calling kanban_complete or kanban_block
→ elapsed <time> > limit <time>
```

Only the former is routable via Pattern 1 above. System-generated blocks need root cause diagnosis first.
