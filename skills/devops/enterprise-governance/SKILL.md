---
name: enterprise-governance
description: "MANDATORY — Load this BEFORE creating, patching, or moving any skill, script, role config, or profile file. Rules for where enterprise artifacts live, what must never leak into open source, and how changes flow between framework and overlay repos."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [governance, guardrails, enterprise, framework, overlay]
    related_skills: [hermes-config-as-code, multi-agent-team, sync-autonomous-enterprise, kanban-worker]
    load_on: [all-enterprise-profiles]
---

# Enterprise Governance

This skill is the **single source of truth** for how the autonomous enterprise is structured, where things live, and what rules MUST be followed by every agent.

Violating these rules causes drift between the open-source framework and local state — exactly what this governance system prevents.

## Core Architecture

```
Framework repo (open source)     Overlay repo (private)
─────────────────────────────    ────────────────────────
skills/                          product-context.yaml
framework/roles/<name>/          roles/<name>/context.md
  SOUL.md (structure only)       operations/
  config.yaml                    scripts/env.sh
framework/scripts/
bootstrap.sh
```

Runtime symlinks in `~/.hermes/profiles/<role>/` join them.

**Key insight:** Framework = HOW the company runs. Overlay = WHAT the company runs on.

## RULE 1: Skills live in the framework repo (MANDATORY)

When creating, patching, or improving an **enterprise** skill, ALWAYS write to the framework repo:

```
~/Work/hermes-autonomous-enterprise/skills/<category>/<name>/SKILL.md
```

NEVER write enterprise skills to `~/.hermes/skills/`. That directory is for:
- Hub-installed skills (via `hermes skills install`)
- Truly local, personal-only one-offs

Enterprise skills include anything under these categories:
- `autonomous-ai-agents/` — multi-agent-team, hermes-agent, hermes-config-as-code, up-or-out-performance-reviews
- `devops/` — kanban-orchestrator, kanban-worker, sync-autonomous-enterprise, webhook-subscriptions, enterprise-governance

**How to patch a skill properly:**
```bash
# Use skill_manage with the path pointing to the framework repo
# OR edit directly:
cd ~/Work/hermes-autonomous-enterprise
# Edit skills/<category>/<name>/SKILL.md
git add skills/
git commit -m "fix(<name>): describe the change"
git push
```

After patching, the skill is immediately updated (loaded via `external_dirs` in config.yaml).

## RULE 2: Commit and push after every session that changes the enterprise

If a session resulted in ANY of the following, commit and push BOTH repos:
- Skill created or patched
- Script created or modified
- Role SOUL.md or config.yaml changed
- Product context updated
- Operations data added

```bash
# Framework repo
cd ~/Work/hermes-autonomous-enterprise
git add -A && git status
git commit -m "type: description of change"
git push

# Overlay repo
cd ~/Work/hermes-yethu-overlay
git add -A && git status
git commit -m "type: description of change"
git push
```

**Never leave a session with uncommitted changes in either repo.** The daily git-health-check will catch these, but the rule is to prevent accumulation.

## RULE 3: ZERO product data in the framework repo

Before committing to the framework, audit for product-specific terms. The health check scans for terms from `PRODUCT_BLOCKLIST` in the overlay's `env.sh`, but prevention is better than detection.

**Add a PRODUCT_BLOCKLIST to your overlay's env.sh:**
```bash
# Terms that must NEVER appear in the framework repo
export PRODUCT_BLOCKLIST="CompanyName FounderName product-domain.com Paystack WhatsApp R20 R150 CAPS teacher-specific-term another-leaky-term"
```

The git-health-check script uses this blocklist to scan framework files. Keep it updated — whenever you discover a term that leaked, add it to the blocklist so it can't leak again.

**Common leak categories (add yours to the blocklist):**
- Company/product names
- Founder names
- Domain names
- Pricing: currency amounts (R20, R150, $0.0226)
- Tech stack: payment processors, hosting providers, specific libraries
- Market terms: platform names (WhatsApp, Telegram), industry jargon (CAPS, curriculum)
- Chat IDs, bot tokens, API keys

Use `git diff --cached` to review what you're about to commit. Grep for known product terms.

Product context belongs in:
- `product-context.yaml` (shared)
- `roles/<name>/context.md` (per-role)
- `operations/` (dashboards, procedures, actuals)

## RULE 4: Profile SOUL.md and config.yaml MUST be symlinks

Every profile's SOUL.md and config.yaml must be symlinks to the framework:

```bash
~/.hermes/profiles/<role>/SOUL.md    → framework/roles/<role>/SOUL.md
~/.hermes/profiles/<role>/config.yaml → framework/roles/<role>/config.yaml
```

If a profile has a real file instead of a symlink, it's frozen — framework updates won't reach it.

Run this to detect violations:
```bash
find ~/.hermes/profiles/ -maxdepth 2 -name 'SOUL.md' ! -type l
find ~/.hermes/profiles/ -maxdepth 2 -name 'config.yaml' ! -type l
```

## RULE 5: Scripts use shunt pattern (bootstrap.sh generates them)

Framework scripts in `framework/scripts/` are canonical. `~/.hermes/scripts/` contains **shunts** — tiny shell scripts generated by `bootstrap.sh`:

```bash
#!/usr/bin/env bash
# Shunt — generated by bootstrap.sh. Do not edit.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SCRIPT_DIR/env.sh" ] && source "$SCRIPT_DIR/env.sh"
exec /absolute/path/to/framework/scripts/script-name.sh "$@"
```

Every shunt:
1. Sources `env.sh` for product-specific variables
2. `exec`s the framework script with all arguments

**Why shunts, not symlinks:** The cron scheduler follows symlinks and rejects targets outside `~/.hermes/scripts/`. Shunts are real files that stay within the scripts directory.

**Adding a new script:**
1. Create it in `framework/scripts/`
2. Re-run `bootstrap.sh` to generate the shunt
3. Commit both the framework script and the updated bootstrap output

**env.sh** is the ONLY symlink in `~/.hermes/scripts/` — it points to `overlay/scripts/env.sh` and is sourced (not exec'd), so cron's symlink check doesn't apply.

## RULE 6: Cron prompt templates are in the skill, not the cron job

Cron prompts that define enterprise behavior belong in the skill's `templates/prompts/` directory. See `references/product-blocklist-patterns.md` for how to construct a safe PRODUCT_BLOCKLIST in env.sh — especially the grep -E `\d` pitfall that caused a massive false-positive cascade.

```
skills/devops/sync-autonomous-enterprise/templates/prompts/
├── enterprise-sync.md
├── coo-review.md
├── pmo-monitor.md
└── review-router.md
```

This way anyone forking the framework repo gets the full operating model. Cron job definitions (~/.hermes/cron/jobs.json) are local state and must be recreated on each deployment.

## RULE 7: Bootstrap.sh creates the link structure

The `bootstrap.sh` in the framework repo creates ALL symlinks. When adding a new role or script:
1. Add it to the framework
2. Update `bootstrap.sh` to include the new symlink
3. Run `bootstrap.sh` to apply

Never manually create symlinks that bootstrap.sh should manage.

## Daily Health Check

A cron job runs `git-health-check.sh` daily at 09:00. It reports:
- Uncommitted changes in either repo
- Unpushed commits
- Broken symlinks in profiles
- Local-only enterprise skills
- Missing SOUL.md/config.yaml in profiles

When you receive a health check report, fix the issues immediately — don't let them accumulate.

## Quick Audit Commands

```bash
# Check for broken symlinks
find ~/.hermes/profiles/ -xtype l

# Check for real files where symlinks should be
find ~/.hermes/profiles/ -maxdepth 2 \( -name 'SOUL.md' -o -name 'config.yaml' \) ! -type l

# Check for local-only enterprise skills
for cat in autonomous-ai-agents devops; do
  for d in ~/.hermes/skills/$cat/*/; do
    name=$(basename "$d")
    [ ! -d ~/Work/hermes-autonomous-enterprise/skills/$cat/$name ] && echo "LOCAL ONLY: $cat/$name"
  done
done

# Check git status of both repos
cd ~/Work/hermes-autonomous-enterprise && git status --short
cd ~/Work/hermes-yethu-overlay && git status --short
```

See `references/product-leak-detection.md` for grep -E compatibility notes (the `\d` pitfall), PRODUCT_BLOCKLIST format, and testing procedure.

## When Loading This Skill

This skill should be loaded by ALL enterprise agents. Add it to the `hermes-agent` skill's related_skills or configure cron jobs to preload it. The daily git-health-check already enforces compliance — but prevention is better than detection.

See `references/audit-example-2026-05.md` for a concrete walkthrough of an audit and remediation session.
