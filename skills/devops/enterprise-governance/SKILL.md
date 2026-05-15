---
name: enterprise-governance
description: "Governance rules for the autonomous enterprise — where skills, scripts, and configs must live, what must never leak, and how changes flow."
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

Before committing to the framework, audit for:
- Company/product names (Yethu, etc.)
- Founder names
- Pricing (R20, R150, $0.0226)
- Market-specific terms (CAPS, WhatsApp, Paystack)
- Domain names
- Specific tech stack (Rust + Axum, unless it's a generic example)

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

## RULE 5: Scripts are canonical in the framework

Framework scripts in `framework/scripts/` are the canonical source. `~/.hermes/scripts/` contains **shunts** — tiny shell scripts that `source env.sh` and `exec` the framework version.

```
~/.hermes/scripts/git-health-check.sh  ← shunt (real file)
Framework/scripts/git-health-check.sh  ← canonical (real logic)
~/.hermes/scripts/env.sh               ← symlink to overlay/scripts/env.sh
```

Never edit a script in `~/.hermes/scripts/` directly. Edit the framework version. The shunt exec's it so changes take effect immediately.

## RULE 6: Cron prompt templates are in the skill, not the cron job

Cron prompts that define enterprise behavior belong in the skill's `templates/prompts/` directory:

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

## When Loading This Skill

This skill should be loaded by ALL enterprise agents. Add it to the `hermes-agent` skill's related_skills or configure cron jobs to preload it. The daily git-health-check already enforces compliance — but prevention is better than detection.
