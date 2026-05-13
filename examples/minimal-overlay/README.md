# Example Product Overlay — Acme Corp

This is a **working example** of a product overlay for the Hermes Autonomous Enterprise Framework. It shows the pattern using a fictional company (Acme Corp) building a simple todo list app.

## How to use this

1. **Copy** this entire directory:
   ```bash
   cp -r hermes-autonomous-enterprise/examples/minimal-overlay ~/Work/my-product-overlay
   ```

2. **Edit `product-context.yaml`** — replace the Acme Corp values with your own company's data (name, market, tech stack, decisions, etc.)

3. **Add or edit `roles/<name>/context.md`** — each role that needs product-specific context beyond what's in `product-context.yaml` gets a file here. Only create files for roles you use — the framework has 25 roles but you don't need context for all of them.

4. **Edit `scripts/env.sh`** — set your company name, domain, and any other env vars your scripts need.

5. **Run bootstrap** and your profiles will be wired up.

## What's included

| File | What it shows |
|------|---------------|
| `product-context.yaml` | Company info, market, tech stack, decisions, MVP scope — the core pattern |
| `roles/ceo/context.md` | CEO-specific context (company review process) |
| `roles/cmo/context.md` | Market positioning, distribution channels |
| `roles/cpo/context.md` | Product vision, MVP scope, competitive landscape |
| `roles/cto/context.md` | Tech stack table, ADR topics, existing docs |
| `roles/designer/context.md` | Design principles, brand palette |
| `roles/engineer/context.md` | Tech stack paths, handoff pattern |
| `roles/tech-lead/context.md` | Pre-build review focus, ADR enforcement |
| `roles/cfo/context.md` | Revenue model, unit economics |
| `scripts/env.sh` | Environment variables for cron scripts |

Not every role needs a `context.md` — only add one when the role needs specific instructions beyond what `product-context.yaml` provides.
