# Hermes Autonomous Enterprise Framework

A modular, open-source framework for running **autonomous AI enterprises** with [Hermes Agent](https://hermes-agent.nousresearch.com).

## The Concept

This repo provides the **structural layer** — role definitions, team hierarchies, escalation protocols, and workflow patterns for 25 agent roles that can run an autonomous enterprise. It contains **zero product-specific data**.

You combine it with a **private product overlay** that holds your company's specific context — product description, market, tech stack, founder details. The two never merge; they stay separate.

```
hermes-autonomous-enterprise/         ← This repo (public, open source)
├── framework/roles/               ← Role definitions (SOUL.md + config.yaml)
│   ├── ceo/                       # Strategy, team leadership
│   ├── cto/                       # Architecture, technology decisions
│   ├── engineer/                  # Implementation, code
│   ├── cmo/                       # Marketing, growth
│   ├── coo/                       # Operations, governance
│   └── ... (25 roles)
│
├── examples/minimal-overlay/      ← Example: Acme Corp (todo list app)
│   ├── product-context.yaml       # Shows the pattern with a simple product
│   ├── roles/ceo/                 # 8 roles with example context (ceo, cfo,
│   │   ...                        # cmo, cpo, cto, designer, engineer,
│   └── scripts/env.sh             # tech-lead, cfo)
│
├── skills/                        ← Reusable cron skills for the enterprise
│   └── sync-autonomous-enterprise # Enterprise sync, kanban monitoring
│
└── bootstrap.sh                   # Wires everything together

your-product-overlay/              ← Your repo (private, copy from example)
├── product-context.yaml           # Your company, market, tech stack
├── roles/*/context.md             # Your per-role specifics
└── scripts/env.sh                 # Your env vars
```

## Quick Start

```bash
# 1. Install Hermes Agent
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash

# 2. Clone this repo
git clone https://github.com/danieldonaldson/hermes-autonomous-enterprise ~/Work/hermes-autonomous-enterprise

# 3. Create your product overlay
#    Start from the example:
cp -r hermes-autonomous-enterprise/examples/minimal-overlay ~/Work/my-product-overlay
#    Then edit product-context.yaml with your company details

# 4. Run bootstrap
cd ~/Work/hermes-autonomous-enterprise
./bootstrap.sh ~/Work/my-product-overlay

# 5. Start using your company
hermes --profile ceo
```

## How It Works

### Three Layers

| Layer | Location | Contents | Version Control |
|-------|----------|----------|-----------------|
| **Structure** | `framework/roles/*/SOUL.md` | Role definitions, workflows, protocols | Open source |
| **Config** | `framework/roles/*/config.yaml` | Profile settings (tools, model) | Open source |
| **Product context** | Your overlay | Company name, market, tech stack, founder | **Private** |

### At Runtime

Each profile in `~/.hermes/profiles/<role>/` has:

```
~/.hermes/profiles/engineer/
├── SOUL.md              → symlink → framework/roles/engineer/SOUL.md
├── config.yaml          → symlink → framework/roles/engineer/config.yaml
├── product-context.yaml  → symlink → product-overlay/product-context.yaml
├── context.md           → symlink → product-overlay/roles/engineer/context.md (if exists)
├── sessions/            ← real (Hermes writes here)
├── logs/                ← real
├── state.db             ← real
└── ...
```

The agent reads `SOUL.md` for its role structure, then reads `product-context.yaml` and `context.md` for company details. The two are never mixed in the same file.

### Symlinks Explained

Because `bootstrap.sh` creates **symlinks** from `~/.hermes/profiles/` into this repo and your overlay, editing a runtime profile file actually edits the source file:

| Runtime path | Actually edits | Repo |
|---|---|---|
| `~/.hermes/profiles/ceo/SOUL.md` | `framework/roles/ceo/SOUL.md` | Open source |
| `~/.hermes/profiles/engineer/config.yaml` | `framework/roles/engineer/config.yaml` | Open source |
| `~/.hermes/profiles/ceo/product-context.yaml` | `product-overlay/product-context.yaml` | **Private** |
| `~/.hermes/profiles/engineer/context.md` | `product-overlay/roles/engineer/context.md` | **Private** |

This is transparent to any tool — `write_file`, `patch`, `sed`, or a text editor all follow the symlink to the real file. Just stay aware which layer you're editing.

**On a fresh machine**, bootstrap creates all symlinks in one command. After that, `git pull` in either repo propagates changes instantly — no re-running bootstrap unless you add new roles.

## Platform Support

Linux and macOS (both x86_64 and Apple Silicon). Requires **bash 3.2+** (pre-installed on both platforms).

| Dependency | Linux | macOS |
|---|---|---|
| bash | Built-in | Built-in (3.2) |
| `whois` (optional, for domain check script) | `apt install whois` / `pacman -S whois` | Built-in |
| git | Built-in / package manager | Built-in / Xcode |
| Hermes Agent | `curl ... | bash` | Same installer |

### Updating

- **Structural improvements** → edit `framework/roles/*/SOUL.md` → `git push` → PR upstream
- **Product changes** → edit your overlay files (private repo)
- **Pull structural updates** → `git pull` in this repo → symlinks update instantly

No rendering. No merge conflicts. Just symlinks.

## Included Roles

| Role | Reports To | Purpose |
|------|-----------|---------|
| CEO (Chief Executive Officer) | Founder | Strategy, vision, company reviews |
| CPO (Chief Product Officer) | CEO | Product definition, user stories, specs |
| Designer | CPO | UI/UX design, prototypes |
| CTO (Chief Technology Officer) | CEO | Architecture, technology decisions |
| Tech Lead | CTO | Code review, ADRs, pre-build review |
| Engineer | Tech Lead | Implementation (fullstack) |
| Head of Data | CTO | Data tracking, analytics |
| Head of Quality | CTO | QA standards, testing |
| Security Reviewer | CTO | Threat modelling, security review |
| CMO (Chief Marketing Officer) | CEO | Marketing, brand, go-to-market |
| Community Manager | CMO | Support, community engagement |
| Growth Lead | CMO | A/B testing, activation, retention |
| Customer Success | CMO | Onboarding, support triage |
| User Research | CMO | User interviews, competitive intel |
| Sales/BD (Business Development) | CMO | Partnerships, bulk licensing |
| Content Marketing | CMO | SEO, blog, content distribution |
| COO (Chief Operating Officer) | CEO | Operations, coordination, governance |
| PMO (Project Management Office) | COO | Kanban board, daily ops, workflow |
| RMO (Results Management Office) | COO | KPI setting, OKR tracking |
| Operations Analyst | COO | Metrics, dashboards, cost tracking |
| Audit & Governance | COO | Decision logs, protocol compliance |
| Legal | CEO | Terms, compliance, IP |
| CFO (Chief Financial Officer) | CEO | Unit economics, payroll, tax |
| Chief of Staff | Founder | Strategy sounding board, accountability |
| Management Consultant | CEO (indirect) | Independent strategic review |

## Included Skills

The `skills/` directory ships reusable cron-job templates that integrate with the enterprise:

- **sync-autonomous-enterprise** — Cron prompts for enterprise sync (Chief of Staff produces reviews, COO runs operational scans, PMO monitors kanban). See the skill's SKILL.md for setup.

## Customisation

### Add a New Role

1. Create `framework/roles/<name>/SOUL.md` with role definition and protocol
2. Create `framework/roles/<name>/config.yaml` with profile settings
3. Optionally add `product-overlay/roles/<name>/context.md` for product-specific instructions

### Adapt the Structure

Edit any SOUL.md to change workflows, team hierarchy, or escalation rules. Since product context is external, structural changes never carry risk of leaking private data.

## Requirements

- [Hermes Agent](https://hermes-agent.nousresearch.com/) installed
- A product overlay with `product-context.yaml`
- API keys in `~/.hermes/.env` (not committed)

> **Provider/model:** `framework/roles/*/config.yaml` defaults to `deepseek-v4-flash` via DeepSeek. Edit `provider`, `model`, and `base_url` in any role's `config.yaml` to use a different provider (e.g. Anthropic, OpenAI).

## License

MIT — use freely, fork openly, contribute back.
