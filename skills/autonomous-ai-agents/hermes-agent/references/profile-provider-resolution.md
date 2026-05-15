# Profile Provider Resolution — Diagnosis Recipe

> How to diagnose and fix a profile that silently routes through the wrong provider.

## The scenario

A kanban worker (or any profile-based agent) is configured with `provider: deepseek` and `model: deepseek-v4-flash`, but the agent logs show `provider=minimax`. API calls succeed but the routing is wrong.

## Step-by-step diagnosis

### 1. Check the agent log

```bash
tail -20 ~/.hermes/profiles/<profile-name>/logs/agent.log
```

Look for lines like:

```
[20260513_111042_d3f23a] run_agent: API call #1: model=deepseek-v4-flash provider=minimax in=16270 out=31 total=16301 latency=4.2s
```

The `provider=minimax` despite the config saying `provider: deepseek` is the tell.

### 2. Check the model catalog

```bash
cat ~/.hermes/profiles/<profile-name>/models_dev_cache.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
# Check the deepseek provider
deepseek = data.get('deepseek', {})
print('DeepSeek models:', list(deepseek.get('models', {}).keys()))
# Check all providers to understand fallback
for pid, p in data.items():
    models = list(p.get('models', {}).keys())
    if models:
        print(f'{pid}: {models[:5]}...' if len(models) > 5 else f'{pid}: {models}')
"
```

If the model (`deepseek-v4-flash`) isn't listed under the `deepseek` provider's models, the catalog can't resolve it. The system falls back to the cached "main provider".

### 3. Check the profile config

```bash
grep -E "provider:|model:|base_url:" ~/.hermes/profiles/<profile-name>/config.yaml
```

Expected output for a properly pinned profile:

```yaml
provider: deepseek
model: deepseek-v4-flash
base_url: https://api.deepseek.com
```

If `base_url` is missing, the catalog fallback can happen.

### 4. Check all profiles at once

```bash
for p in ~/.hermes/profiles/*/; do
  name=$(basename "$p")
  echo "=== $name ==="
  grep -E "provider:|model:|base_url:" "$p/config.yaml" 2>/dev/null || echo "(no provider/model/base_url)"
done
```

## The fix

### Per-profile fix

Add these three lines to each profile's `config.yaml`:

```yaml
provider: deepseek
model: deepseek-v4-flash
base_url: https://api.deepseek.com
```

The `base_url` is the critical piece — it bypasses the model catalog lookup entirely and forces direct routing to the provider's API endpoint.

### Patch command

```bash
hermes config set --profile <name> model.deepseek-v4-flash  # won't work for profiles
# Instead, edit the file directly:
sed -i '/^provider: deepseek/a model: deepseek-v4-flash\nbase_url: https://api.deepseek.com' ~/.hermes/profiles/<name>/config.yaml
```

Or use the `patch` tool programmatically.

### Clear stale cache

```bash
rm -f ~/.hermes/models_dev_cache.json ~/.hermes/profiles/*/models_dev_cache.json
hermes gateway restart
```

## Why profiles don't inherit from main config

The main `~/.hermes/config.yaml` has a `model:` block:

```yaml
model:
  default: deepseek-v4-flash
  provider: deepseek
  base_url: https://api.deepseek.com
```

Profiles have a flat structure:

```yaml
provider: deepseek
model: deepseek-v4-flash
```

Profiles resolve provider + model independently through the model catalog. The main config's `model.base_url` is NOT inherited — profiles either need `base_url` explicitly or they go through catalog lookup.

## When to use this reference

- A kanban worker or spawned agent seems to be using the wrong provider
- API calls succeed but the provider label in logs doesn't match the profile config
- After switching a profile from one provider to another, changes don't seem to take effect
- Setting up new profiles and wanting deterministic provider routing
