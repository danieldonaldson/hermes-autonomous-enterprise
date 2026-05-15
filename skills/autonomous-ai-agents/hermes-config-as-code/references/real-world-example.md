# Real-World Example: Yethu Product Overlay

This shows what a finished product overlay looks like for an actual autonomous enterprise. The framework's `examples/minimal-overlay/` directory provides a starting template (Acme Corp todo list app) — this is what a production overlay looks like after adapting it to a real product.

## Directory Structure

```
yethu-overlay/                           # Private repo, not in the framework
├── product-context.yaml                 # 80 lines of company context
├── roles/
│   ├── ceo/context.md                   # CEO-specific: company review process
│   ├── engineer/context.md              # Tech stack details, codebase paths, handoff pattern
│   ├── tech-lead/context.md             # Pre-build review criteria, re-review cycle
│   ├── security-reviewer/context.md     # Specific threat model areas by tech stack
│   ├── chief-of-staff/context.md        # YC defensibility thesis, North Star strategy
│   ├── cpo/context.md                   # Key product decisions, MVP scope
│   ├── cmo/context.md                   # Competitive positioning
│   ├── cto/context.md                   # Architecture plan, user stories, MVP scope docs
│   ├── designer/context.md              # Design system, landing page, design docs path
│   ├── content-marketing/context.md     # SEO keywords, content distribution channels
│   ├── customer-success/context.md      # Support triage tiers, user profile
│   ├── growth-lead/context.md           # Growth channels, viral loops
│   ├── user-research/context.md         # User segments, research methods
│   ├── legal/context.md                 # Jurisdiction-specific compliance (POPIA)
│   ├── finance/context.md               # Revenue model specifics, known costs
│   ├── community-manager/context.md     # Support channels, community spaces, user stories
│   └── sales-bd/context.md              # Sales focus, decision-maker personas
├── scripts/
│   └── env.sh                           # Script parameters: PRODUCT_DOMAIN, COMPANY_NAME, etc
```

Note: `yethu-overlay/roles/` has 17 context files — not every role needs one. Only create context.md for roles whose product context extends beyond what `product-context.yaml` covers. The remaining 8 roles get all their context from the shared file.

## How the SOUL.md References Context

Every structural SOUL.md in the framework starts with:

```markdown
## Product Context
Read `product-context.yaml` in this directory to learn about your company,
its product, market, and key decisions. Role-specific context (if any) is in
`context.md`. Read both before starting work — your company context is not
in this file.
```

## How Scripts Are Wired

Scripts live in the framework as parameterized templates. The overlay provides the values:

```bash
# framework/scripts/check-domain-available.sh — structural, no product data
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SCRIPT_DIR/env.sh" ] && source "$SCRIPT_DIR/env.sh"
DOMAIN="${PRODUCT_DOMAIN:?not set}"
```

```bash
# yethu-overlay/scripts/env.sh — the only product-specific part
export COMPANY_NAME="Yethu"
export PRODUCT_DOMAIN="yethu.co.za"
export FOUNDER_NAME="Daniel"
export TELEGRAM_CHAT_ID="8691615307"
export TIMEZONE="SAST"
```

The overlay's scripts directory contains symlinks to the framework scripts plus the real `env.sh`:

```
yethu-overlay/scripts/
├── env.sh                            # ← real file
├── check-domain-available.sh         # → symlink to framework/scripts/
└── daily-standup.sh                  # → symlink to framework/scripts/
```

## Result

- **Open-source framework** — 25 role directories (SOUL.md + config.yaml), 2 structural scripts, README, bootstrap.sh, example overlay
- **Private overlay** — product-context.yaml, 17 per-role context files, 1 env.sh
- **Backup** — original full ~/.hermes/ archived before restructuring
- **The two never merge** — agent reads two files at startup from different repos
