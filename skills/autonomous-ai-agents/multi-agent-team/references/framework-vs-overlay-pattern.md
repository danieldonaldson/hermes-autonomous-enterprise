# Framework vs Overlay Repo Pattern

The autonomous enterprise operating model is split across two repos:

**Framework repo (public open source):**
- Role SOUL.md templates with agent names (Turing, Clank, etc.)
- The `multi-agent-team` skill (this one)
- Cron prompt templates (enterprise sync, review router, PMO monitor, COO review)
- Escalation protocol templates
- All patterns are generic — use "the founder's product" not a real company name

**Overlay repo (private):**
- `product-context.yaml` — actual product context (company name, pricing, market)
- `roles/<name>/context.md` — product-specific context per role
- `operations/kpi/framework.yaml` — actual KPI targets
- `operations/` — dashboards, procedures, actuals
- Anything that would identify the user's real company or product

## Key Rules

1. **SOUL.md symlinks most profile SOUL.md files.** Writing to them follows the symlink into the public repo. Before committing the framework repo, always run `git diff framework/roles/` to check for product info leaks.

2. **Names are fine in the framework.** Turing, Clank, Bishop etc. are generic references to AI history and pop culture — safe for open source. What's NOT safe: real company names, pricing, market details, product-specific URLs.

3. **Cron prompt templates go in the framework repo** under `skills/sync-autonomous-enterprise/templates/prompts/`. The actual cron jobs with their prompts are local-only (`~/.hermes/cron/jobs.json`) and need to be recreated on each deployment using the templates.

4. **Commit operating model improvements to the framework.** Every session that improves the autonomous enterprise pattern (escalation flow, sync cadence, decomposition chain) should result in a framework commit. The framework repo is meant to evolve with use.
