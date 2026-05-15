---
name: hermes-config-as-code
description: "Version-control Hermes Agent configuration using symlinked overlays. Separates role structure (open source) from product context (private) for reproducible multi-machine setup."
version: 2.2.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [config, profiles, overlays, bootstrapping, version-control, dotfiles, symlinks]
    related_skills: [multi-agent-team, hermes-agent, enterprise-governance]
---

# Hermes Config as Code

A pattern for managing Hermes Agent configuration in version control: keeping role **structure** (open source) and **product context** (private) in separate repos, joined at runtime by symlinks.

## Core Principle

**Never mix structure and product data in the same file.**

| Layer | What | Where it lives | Version control |
|-------|------|----------------|-----------------|
| **Structure** | Role definitions, workflows, escalation protocols, profile config.yaml | `framework/roles/<name>/SOUL.md` | Open source |
| **Product context** | Company name, market, tech stack, founder details, decisions | `product-overlay/product-context.yaml` | Private |
| **Role extras** | Per-role product context beyond the shared file | `product-overlay/roles/<name>/context.md` | Private |
| **Secrets** | API keys, bot tokens, chat IDs | `~/.hermes/.env` | Never committed |

## When to Use

- You want to replicate your full Hermes setup onto a new machine
- You have project-specific profiles (company roles, product personas) that should stay private while the underlying structure is reusable
- You want others to clone your Hermes setup and adapt it to their own project
- You want `git pull` to update your profile configs instantly — no rendering, no merge conflicts
- You keep over-engineering the approach and need the simplest thing that works

## Architecture

```
# At runtime, each profile dir (~/.hermes/profiles/<role>/) looks like:

~/.hermes/profiles/engineer/
├── SOUL.md              → symlink → hermes-autonomous-enterprise/framework/roles/engineer/SOUL.md
├── config.yaml          → symlink → hermes-autonomous-enterprise/framework/roles/engineer/config.yaml
├── product-context.yaml  → symlink → product-overlay/product-context.yaml
├── context.md           → symlink → product-overlay/roles/engineer/context.md   (if exists)
├── sessions/            ← real dir — Hermes writes runtime state here
├── logs/                ← real dir
├── state.db             ← real file
└── ...
```

## The SOUL.md Convention

Every open-source SOUL.md starts with a `## Product Context` section that tells the agent where to find company details:

```markdown
# CEO Agent Persona

## Product Context
Read `product-context.yaml` in this directory to learn about your company,
its product, market, and key decisions. Role-specific context (if any) is in
`context.md`. Read both before starting work — your company context is not
in this file.

You are the **CEO** of the company.
## Your Personality
- Visionary and decisive — you see the big picture and make clear calls
...
```

The rest of the SOUL.md is pure structure: role definition, personality, team hierarchy, workflow patterns, escalation protocol. No product names, no founder references, no market context.

## Setting It Up

### Before you start: back up your existing Hermes setup

If you already have profiles, config, or skills in `~/.hermes/`, back them up before switching to symlinks:

```bash
mkdir -p ~/Work/hermes-backup-$(date +%Y%m%d)
cp -a ~/.hermes/config.yaml ~/.hermes/.env ~/.hermes/auth.json ~/Work/hermes-backup-$(date +%Y%m%d)/
cp -a ~/.hermes/profiles ~/Work/hermes-backup-$(date +%Y%m%d)/
cp -a ~/.hermes/skills ~/Work/hermes-backup-$(date +%Y%m%d)/
cp -a ~/.hermes/memories ~/Work/hermes-backup-$(date +%Y%m%d)/
cp -a ~/.hermes/kanban.db ~/Work/hermes-backup-$(date +%Y%m%d)/
cp -a ~/.hermes/scripts ~/Work/hermes-backup-$(date +%Y%m%d)/
```

### Structure of the open-source repo

```
hermes-autonomous-enterprise/
├── README.md
├── bootstrap.sh                      # One-time symlink setup
├── .gitignore
├── framework/
│   └── roles/                        # 25 roles, each with:
│       ├── ceo/
│       │   ├── config.yaml           # Profile config (model, disabled toolsets)
│       │   └── SOUL.md               # Structural persona — no product data
│       ├── engineer/
│       ├── cto/
│       └── ...
└── examples/
    └── minimal-overlay/              # For newcomers to copy

### Scripts & Cron Are Structural Too

Scripts (daily standup, domain checks, board monitors) and cron job patterns belong in the **framework**, not the overlay. They define *how* the company runs, not *what* it runs on.

**Framework scripts are parameterized** — they source `env.sh` from their own directory at runtime. At deployment time, `bootstrap.sh` generates **shunt scripts** in `~/.hermes/scripts/` — real files (not symlinks) that source `env.sh` then `exec` the framework canonical version. Shunts are mandatory because the cron scheduler rejects symlinks resolving outside `~/.hermes/scripts/`:

```bash
#!/bin/bash
# framework/scripts/check-domain-available.sh — structural, no product data
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SCRIPT_DIR/env.sh" ] && source "$SCRIPT_DIR/env.sh"

DOMAIN="${PRODUCT_DOMAIN:?PRODUCT_DOMAIN not set — set in env.sh}"
# ... rest of the script
```

**The overlay provides the values** in a single `env.sh` file:

```bash
# product-overlay/scripts/env.sh — the only product-specific part
export COMPANY_NAME="Your Company"
export PRODUCT_DOMAIN="example.com"
export FOUNDER_NAME="Alice"
export TELEGRAM_CHAT_ID="123456789"
export TIMEZONE="UTC"
```

**The overlay's scripts directory** is a mix of symlinks to framework scripts and the real `env.sh`:

```
product-overlay/scripts/
├── env.sh                          # ← real file (product values)
├── check-domain-available.sh       # → symlink to framework/scripts/check-domain-available.sh
└── daily-standup.sh                # → symlink to framework/scripts/daily-standup.sh
```

This means `git pull` in the framework repo updates scripts instantly. You never edit scripts in the overlay — only `env.sh`.

### Structure of the overlay (private)

```
product-overlay/
├── product-context.yaml              # Shared across all roles
├── roles/
│   ├── ceo/context.md                # Per-role extras (optional)
│   ├── engineer/context.md
│   └── ...
├── env.sh                            # Product-specific env vars sourced by framework scripts
└── scripts/                          # Symlinks to framework scripts + real env.sh
    ├── env.sh                        # ← real file (product values)
    ├── check-domain-available.sh     # → symlink to framework/scripts/
    └── daily-standup.sh              # → symlink to framework/scripts/
```

### The bootstrap script

A minimal shell script that creates all the symlinks:

```bash
#!/usr/bin/env bash
# bootstrap.sh — Set up Hermes profiles from framework + overlay

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
OVERLAY_DIR="$1"
FRAMEWORK_DIR="$REPO_DIR/framework"

for role_dir in "$FRAMEWORK_DIR/roles/"*/; do
  role="$(basename "$role_dir")"
  profile_dir="$HOME/.hermes/profiles/$role"
  mkdir -p "$profile_dir"

  ln -sf "$role_dir/SOUL.md"          "$profile_dir/SOUL.md"
  ln -sf "$role_dir/config.yaml"      "$profile_dir/config.yaml"
  ln -sf "$OVERLAY_DIR/product-context.yaml" "$profile_dir/product-context.yaml"

  if [ -f "$OVERLAY_DIR/roles/$role/context.md" ]; then
    ln -sf "$OVERLAY_DIR/roles/$role/context.md" "$profile_dir/context.md"
  fi
done

# Create shunt scripts — real files that source env.sh + exec framework script
# (shunts, not symlinks — cron rejects symlinks resolving outside ~/.hermes/scripts/)
mkdir -p "$HOME/.hermes/scripts"
for script in "$FRAMEWORK_DIR/scripts/"*; do
  [ -f "$script" ] || continue
  name="$(basename "$script")"
  cat > "$HOME/.hermes/scripts/$name" << SHUNTEOF
#!/usr/bin/env bash
# Shunt — generated by bootstrap.sh. Do not edit.
set -e
SCRIPT_DIR="\$(cd "\$(dirname "\$0")" && pwd)"
[ -f "\$SCRIPT_DIR/env.sh" ] && source "\$SCRIPT_DIR/env.sh"
exec "$script" "\$@"
SHUNTEOF
  chmod +x "$HOME/.hermes/scripts/$name"
done
if [ -f "$OVERLAY_DIR/scripts/env.sh" ]; then
  ln -sf "$OVERLAY_DIR/scripts/env.sh" "$HOME/.hermes/scripts/env.sh"
fi
```

Usage:
```bash
git clone https://github.com/you/hermes-autonomous-enterprise ~/Work/hermes-autonomous-enterprise
cd ~/Work/hermes-autonomous-enterprise
./bootstrap.sh ~/Work/product-overlay
```

### Full New Machine Flow

```bash
# 1. Install Hermes
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash

# 2. Clone the framework
git clone https://github.com/you/hermes-autonomous-enterprise ~/Work/hermes-autonomous-enterprise

# 3. Create your product overlay from the example
cp -r ~/Work/hermes-autonomous-enterprise/examples/minimal-overlay ~/Work/my-product-overlay
# Edit product-context.yaml and roles/*/context.md with your company details

# 4. Run bootstrap (stops gateway, creates symlinks, restarts gateway)
cd ~/Work/hermes-autonomous-enterprise
./bootstrap.sh ~/Work/my-product-overlay

# 5. Clean up the kanban board (old tasks from template or prior setup)
hermes kanban list | grep '^✓' | awk '{print $2}' | xargs hermes kanban archive
hermes kanban gc

# 6. Verify
hermes doctor
hermes gateway status
hermes --profile ceo    # start a test session
```

## How Updates Flow

| What changes | Where you edit | Push target |
|-------------|---------------|-------------|
| Role structure, workflow patterns | `framework/roles/*/SOUL.md` | **Open source** git push |
| Product context (company, market, decisions) | `product-overlay/product-context.yaml` | **Private** git push |
| Per-role product details | `product-overlay/roles/*/context.md` | **Private** git push |
| Script improvements (standup format, domain check logic) | `framework/scripts/*.sh` | **Open source** git push |
| Script parameters (company name, domain) | `product-overlay/scripts/env.sh` | **Private** git push |
| Profile config (disabled tools, model) | `framework/roles/*/config.yaml` | **Open source** git push |

**To pull structural updates:**
```bash
cd ~/Work/hermes-autonomous-enterprise
git pull
# Symlinks resolve instantly — no script needed
```

## What the product-context.yaml Contains

All shared company/product data that every role needs:

```yaml
company:
  name: YourCompany
  description: what your company does
  founder: Founder name
  domain: example.com
  timezone: SAST

status:
  phase: pre-build  # or build, launch, growth
  current_focus: "what the team is working on right now"

market:
  description: market description
  primary_users: who uses your product
  distribution: how you reach them
  revenue_model: how you make money
  competitor_landscape:
    - Competitor A
    - Competitor B

confirmed_decisions:
  - Key decision 1
  - Key decision 2

tech_stack:
  backend: Rust + Axum
  frontend: TypeScript + Svelte
  payments: Paystack
  # ...

codebase_paths:
  project_root: ~/Work/project/
  # ...
```

## What per-role context.md Files Contain

Only what's role-specific and doesn't fit the shared file:

- **Engineer** — specific tech stack details, build commands, codebase paths
- **Security Reviewer** — specific threats from the tech stack
- **Chief of Staff** — strategic framework, defensibility thesis
- **Legal** — jurisdiction-specific compliance requirements

If a role's product context is entirely covered by `product-context.yaml`, don't create a `context.md` for it.

## Auditing SOUL.md for Product Leaks

Before releasing a framework repo publicly, audit every SOUL.md for product-specific content. Use a systematic multi-pass approach.

### Pass 1: Broad grep for obvious leaks

Search for: company/product names, founder names, trademarks, domain names, registered addresses, currency symbols with amounts (R20, $0.0226).

```bash
grep -rn 'company-name\|founder-name\|product-name' framework/roles/ --include='*.md' --include='*.yaml'
```

### Pass 2: Industry-specific terminology

Every framework inevitably reflects the project it was built for. Search for terms specific to your product's domain and extract them to the overlay:

```bash
# Examples from a teacher marketplace cleanup:
grep -rn 'teacher\|school\|curriculum\|worksheets\|telco\|publisher\|CAPS' framework/roles/ --include='*.md'
```

Each match is either:
- **A genuine leak** — move to the overlay's `roles/<name>/context.md` and replace with generic text in the framework
- **A false positive** — verify it's a genuinely general concept (e.g. "Teacher of mindset" means "educator personality trait", not a school teacher)

### Pass 3: Tech stack specifics

Check for hardcoded language names, frameworks, or services that belong in the overlay:

```bash
grep -rn 'Rust\|Python\|Go\|React\|PostgreSQL\|SQLx\|Axum\|Stripe\|Paystack\|Meta Cloud\|WhatsApp\|cargo\|npm\|yarn' framework/roles/ --include='*.md'
```

Technical roles (Engineer, Tech Lead, CTO) are the most common offenders. Replace with `See product-context.yaml > tech_stack` references.

### Pass 4: Personality traits and user references

Personality sections and market context are common leak vectors:

```bash
grep -rn 'teacher-first\|teacher-focused\|SA-savvy\|SA-aware\|load shedding\|provinces\|grades\|subjects' framework/roles/ --include='*.md'
```

Replace with generic equivalents: "teacher-first" → "user-first", "teacher-focused" → "audience-focused", "SA-savvy" → "market-savvy", "subjects/grades/provinces" → "segments/verticals".

### Pass 5: Market/competitor context

CMO, CPO, and Sales/BD roles often have hardcoded competitor names, pricing details, and target segments. These belong in the overlay's `context.md` files. Also check team description lines (e.g. "bulk licensing pipeline to schools/districts") which encode industry assumptions.

### Pass 6: Config files — keep them compact

A 500-line config dump in any role is a red flag — the framework should have compact configs (~25 lines) with sensible defaults. Product-specific provider choices, model names, and detailed tool configs belong in the user's local `~/.hermes/config.yaml`, not the role config. All role configs should be consistent in format (2-space YAML indent) and always include `profiles_list_cache: 2` and an `onboarding:` section.

### After cleanup: verify with a zero-tolerance grep

```bash
# Be thorough — scan both md and yaml
grep -rn 'company-name\|founder-name\|product-name\|your-specific-term' framework/ --include='*.md' --include='*.yaml' 2>/dev/null
# If anything shows, it's still leaking — fix before push
```

### Commit strategy for cleanup

When cleaning a repo that already has product data in its history:
- **Single-commit repos** (only 1 commit): `git add -A && git commit --amend` replaces the entire history. Then `git push --force-with-lease`.
- **Multi-commit repos**: `git reset --soft <initial-commit-hash>` to squash all changes into the initial commit, then `git commit --amend`. This rewrites history cleanly without needing filter-branch.
- Before force-pushing a cleaned public repo, confirm with the user: "This rewrites history — the old commit will be gone from GitHub. Proceed?"

## README Best Practices

An open-source framework repo should make its structure immediately accessible:

- **Expand acronyms in the roles table** — not everyone knows RMO (Results Management Office), PMO (Project Management Office), BD (Business Development), CPO (Chief Product Officer). List the full name alongside the acronym in the README roles table.
- **Include a working example overlay** — the example overlay should demonstrate context.md files for the key roles (CEO, CPO, CTO, Designer, Engineer, Tech Lead, Finance, CMO) so newcomers can see the pattern. Include product-context.yaml, scripts/env.sh, and a README explaining how to copy and adapt it.
- **The example should be self-contained** — a fictional company (like Acme Corp building a todo list) with enough detail to show the pattern but generic enough to not confuse.

## Common Pitfalls

1. **Over-engineering the approach.** Do NOT build a template rendering engine with `{{PLACEHOLDER}}` substitution. Do NOT create an onboarding agent that generates files. Do NOT write a sync agent. Do NOT build a rendering pipeline. Just symlink real files and tell the agent to read them from its profile directory. The simplest approach that works is the right one — the user will correct you if you build complexity they didn't ask for. Real signals from one session: "why cant we just tell the agents to refer to product specific files?" -> killed template rendering. "i dont think we need the sync anymore then?" -> killed sync agent. "why are scripts and cron product specific?" -> moved scripts to framework, parameterized via env.sh. Each correction pointed toward less machinery, not more.

1.5. **Profile name doesn't match any framework role name.** The bootstrap script creates symlinks for every role in `framework/roles/`. If a profile's name has no matching role directory in the framework, the symlinks point to a non-existent path — they're **broken**. Hermes falls back to default config and the profile has no SOUL.md.

   **Concrete examples seen in the wild:**
   - Profile `mckinsey-consultant` but framework role is `management-consultant`. Fix: symlink profile SOUL.md + config.yaml directly to `framework/roles/management-consultant/`.
   - Profile `finance` but framework role is `cfo`. Fix: symlink profile SOUL.md + config.yaml directly to `framework/roles/cfo/`. No need to create a new framework role — finance IS the CFO.

   **Better fix (when the profile name is a synonym of a framework role):** Don't create real files. Just point the profile symlinks directly to the framework role that represents the same function:

   ```bash
   rm ~/.hermes/profiles/<profile-name>/SOUL.md ~/.hermes/profiles/<profile-name>/config.yaml
   ln -sf /path/to/framework/roles/<framework-role>/SOUL.md ~/.hermes/profiles/<profile-name>/SOUL.md
   ln -sf /path/to/framework/roles/<framework-role>/config.yaml ~/.hermes/profiles/<profile-name>/config.yaml
   ```

   The overlay's per-role `context.md` handles product-specific content — the profile gets the structural persona from the framework role it maps to.

   **Fallback fix (when the profile genuinely has no framework equivalent):** Remove the broken symlinks and create real files in the profile directory, adapted from the closest matching framework role:

   **Detection:** Find all broken symlinks across profiles:
   ```bash
   find ~/.hermes/profiles/ -type l -xtype l
   ```

   These are symlinks whose target doesn't exist. Each needs investigation — either the framework role was renamed/removed, or the profile name was customized and needs real files.

2. **Putting product data in the SOUL.md.** If the SOUL.md mentions your company name, tech stack, or founder — that's product data leaking into the structure. Move it to `product-context.yaml`. A systematic audit (see "Auditing SOUL.md for Product Leaks" above) catches all of these before release. Common oversight: founder name in escalation-to notes ("Present the memo to Daniel via Telegram"), market context in CMO/CPO role descriptions, hardcoded tech stacks in Engineer/CTO SOUL.md files, and document-format assumptions (PDF, watermarking) that don't apply to all products.

3. **Forgetting the `## Product Context` section.** Without it, the agent doesn't know to look for product info. Every structural SOUL.md needs this at the top.

4. **Forgetting that scripts are structural, not product data.** The daily standup script, domain checker, board monitor — these define *how* the company runs. They belong in the framework, parameterized via env vars. Only the env.sh values are product-specific. Putting scripts in the overlay means structural changes require editing both repos.

5. **Making the overlay repo a clone of the framework.** The overlay only needs `product-context.yaml` and optional context files — not a full copy of every profile.

6. **Committing product data to the wrong repo.** If you're pushing the open-source repo, grep for company names and founder references first. The symlink approach makes this safe by design — product data is physically in a different directory tree.

7. **Profile has kanban in disabled_toolsets -> protocol violation.** If a profile that receives kanban dispatcher tasks has `kanban` in `disabled_toolsets`, the spawned worker cannot call `kanban_complete()` or `kanban_block()` — it exits cleanly without reporting, flagged as a **protocol violation**. Fix: remove `kanban` from `disabled_toolsets` for ALL profiles that are assigned kanban tasks. See the `kanban-worker` skill's pitfalls section for full detail.

8. **Using symlinks for cron scripts → silent failures.** The cron scheduler (`cron/scheduler.py`) calls `path.resolve()` on script paths and rejects any target outside `~/.hermes/scripts/`. Symlinks to framework scripts resolve outside the scripts directory and are blocked. **Fix:** use shunt scripts — real files in `~/.hermes/scripts/` that `source env.sh` then `exec` the framework canonical version. `bootstrap.sh` generates these automatically. The only symlink in `~/.hermes/scripts/` should be `env.sh` (sourced, not exec'd).

## Restore from Backup

If something goes wrong after switching to symlinks:

```bash
# Assuming you backed up profiles/, config.yaml, .env, auth.json, skills/ etc.
cp -a ~/Work/backup-<timestamp>/* ~/.hermes/
hermes gateway start
```

## Comparison With Alternatives

| Approach | Complexity | Product/Structure Separation | git pull updates | Multi-machine |
|----------|-----------|------------------------------|------------------|---------------|
| **Symlinks + context files** (this skill) | Low | Clean — different directories | Instant | ✓ |
| Template rendering with {{PLACEHOLDERS}} | High | Clean — templates are pure | Needs re-render | ✓ |
| Single monolithic profile with inline context | None | None — all mixed | N/A | Manual copy |
| `hermes profile export/import` per profile | Medium | None — exports everything | N/A | Works but per-profile |
