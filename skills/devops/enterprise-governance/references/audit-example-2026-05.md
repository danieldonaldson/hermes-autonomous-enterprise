# Real-World Audit: May 2026 Enterprise Governance Cleanup

This reference captures a concrete governance audit and remediation session. Use it as a template for future audits.

## What Was Found (Pre-Audit State)

### Problem 1: Enterprise skills trapped in ~/.hermes/skills/
Six enterprise skills existed only locally — not in the framework repo:
- `multi-agent-team`, `up-or-out-performance-reviews`, `hermes-agent`,
  `hermes-config-as-code`, `kanban-orchestrator`, `webhook-subscriptions`

Only 2 were in the framework (`kanban-worker`, `sync-autonomous-enterprise`).
Any agent patching these skills wrote to the local copy. Nobody cloning the
framework got the improvements.

### Problem 2: Accumulated uncommitted changes
- Framework repo: 2 commits ahead of origin, 2 files modified (engineer + tech-lead config.yaml)
- Overlay repo: 1 commit ahead of origin, 1 file modified (KPI framework), 10+ untracked files
- No daily check — drift accumulated silently

### Problem 3: Broken symlinks and profile mismatches
- `mckinsey-consultant/config.yaml` → broken symlink (target `framework/roles/mckinsey-consultant/` didn't exist; framework had `management-consultant`)
- `mckinsey-consultant/SOUL.md` → real file, not a symlink (frozen, no framework updates)
- `finance` profile had no SOUL.md at all and a local config.yaml (not symlinked)

### Problem 4: Product leaks in skill about to go open-source
`multi-agent-team/SKILL.md` had 6+ Yethu-specific references. 11 of 17 reference files contained product data (company name, pricing, founder, market terms).

## What Was Done

### 1. Moved skills to framework
- Copied all 6 enterprise skills to `framework/skills/` (loaded via `external_dirs`)
- Sanitized `multi-agent-team/SKILL.md`: replaced Yethu/Daniel/home-path references with generics
- Moved 11 product-specific reference files to overlay `operations/team/`
- Removed local copies from `~/.hermes/skills/`

### 2. Fixed symlinks
- `mckinsey-consultant` → symlinked both SOUL.md and config.yaml to `framework/roles/management-consultant/`
- `finance` → symlinked both SOUL.md and config.yaml to `framework/roles/cfo/` (finance IS the CFO)
- Verified zero broken symlinks across all 25 profiles

### 3. Created daily git-health-check
- Script: `framework/scripts/git-health-check.sh`
- Cron: daily at 09:00, no_agent, deliver to origin
- Checks: uncommitted changes, unpushed commits, broken symlinks, local-only enterprise skills, real files where symlinks should be, product leaks in framework

### 4. Created enterprise-governance skill
- Single source of truth for all governance rules
- 7 mandatory rules covering skills, commits, product data, symlinks, scripts, cron prompts, and bootstrap

### 5. Baked guardrails into agent SOUL.md files
- CEO, Chief of Staff, and Engineer all got explicit governance sections
- Chief of Staff designated as "Enterprise Governance Guardian"

### 6. Committed and pushed both repos
- Framework: 30 files changed, pushed to `danieldonaldson/hermes-autonomous-enterprise`
- Overlay: 31 files changed, pushed to `danieldonaldson/hermes-yethu-overlay`
- Post-commit health check: silent (clean)

## Key Patterns to Reuse

### When moving a skill to the framework

```bash
# 1. Audit for product leaks
grep -rn -i 'company-name\|founder-name\|product-term' ~/.hermes/skills/<category>/<name>/

# 2. Move product-specific references to the overlay
mkdir -p ~/Work/<overlay>/operations/team/
cp ~/.hermes/skills/<category>/<name>/references/<leaky-file>.md ~/Work/<overlay>/operations/team/

# 3. Sanitize the SKILL.md (replace product terms with generics)
# Edit, then copy to framework
cp -a ~/.hermes/skills/<category>/<name> ~/Work/<framework>/skills/<category>/<name>

# 4. Remove local copy
rm -rf ~/.hermes/skills/<category>/<name>

# 5. Commit the framework
cd ~/Work/<framework> && git add skills/ && git commit -m "feat: move <name> skill to framework"
```

### When fixing a profile naming mismatch

If the profile name is a synonym of a framework role:
```bash
rm ~/.hermes/profiles/<profile>/SOUL.md ~/.hermes/profiles/<profile>/config.yaml
ln -sf <framework>/roles/<matching-role>/SOUL.md ~/.hermes/profiles/<profile>/SOUL.md
ln -sf <framework>/roles/<matching-role>/config.yaml ~/.hermes/profiles/<profile>/config.yaml
```

Only create real files if the profile genuinely has no framework equivalent.

### The shunt-script pattern for cron scripts

Cron scheduler requires real files in `~/.hermes/scripts/` (symlinks to targets outside the scripts dir are rejected). Use a shunt:

```bash
#!/usr/bin/env bash
# Shunt — ~/.hermes/scripts/git-health-check.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SCRIPT_DIR/env.sh" ] && source "$SCRIPT_DIR/env.sh"
exec /path/to/framework/scripts/git-health-check.sh "$@"
```

The framework script is the canonical source. The shunt exec's it. Edit the framework version — changes take effect immediately.
