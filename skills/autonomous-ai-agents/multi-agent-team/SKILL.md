---
name: multi-agent-team
description: "Set up a multi-agent executive team within Hermes Agent using profiles, SOUL.md personalities, toolset configuration, and kanban coordination."
version: 1.4.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [multi-agent, profiles, kanban, orchestration, teamwork]
    related_skills: [hermes-agent, kanban-orchestrator, kanban-worker, hermes-config-as-code, enterprise-governance]
---

# Multi-Agent Executive Team

Set up multiple Hermes Agent profiles as a coordinated executive team (CEO, CTO, CPO, CMO, etc.) that collaborate via the kanban board to build a product or run a business.

## When to Use

Use this skill when the user wants to:
- Set up multiple Hermes agents as different roles (C-level execs, specialists, etc.)
- Create a company of AI agents that work together on a shared goal
- Coordinate multiple profiles with distinct personalities and toolsets
- Build a SaaS product with a "virtual team" inside Hermes

## Prerequisites

- Hermes Agent installed and configured
- At least one API key/provider working (profiles inherit from default)
- Gateway installed (`hermes gateway install`)

## Step 1: Define the Team Roles

Before creating profiles, define each role's:
- **Purpose** — what does this role own?
- **Tools** — what tools does this role need? (terminal/code for builders, web/search for researchers, kanban/delegation for orchestrators)
- **Personality** — how should this role communicate?

Common startup team:

| Role | Focus | Core Toolsets |
|------|-------|---------------|
| **CEO** | Strategy, decisions, delegation | kanban, delegation, clarify, web |
| **CTO** | Architecture, direction, delegation | file, web, kanban (no terminal — they delegate, don't build) |
| **Engineer** | Implementation (fullstack) | terminal, file, code_execution, web, browser |
| **Tech Lead** | Architecture discourse, ADRs, code review | file, web, kanban (no terminal — they review, don't build) |
| **CPO** | Product specs, roadmap, UX | web, search, file |
| **CMO** | Marketing, brand, GTM | web, search, browser |

### Framework-Based Gap Analysis (YC, Google, FAANG)

An alternative (and complementary) approach to the domain-matrix method: use well-known organizational frameworks as a template. Compare your current team composition against what Y Combinator expects of a funded startup, or what Google/FAANG orgs typically include, and identify gaps.

**Why this works:** domain-matrix analysis requires you to know every domain your project touches upfront. Framework-based analysis uses established patterns from orgs that have already figured out what roles matter — you get the benefits of their experience without needing to be comprehensive yourself.

**Which framework to use depends on your stage:**

| Stage | Reference Framework | Why |
|-------|-------------------|-----|
| Pre-MVP / Discovery | Y Combinator expectations | YC's model is lean — what's the absolute minimum team to make something people want and measure it. Their lens: growth, user love, revenue |
| Post-MVP / Scaling | Google/FAANG patterns | Once you have product-market fit, you need the roles that prevent scale-up failures: reliability, ecosystem, developer relations, operations |
| B2B / Enterprise | Salesforce / Oracle | Sales engineering, customer success (multi-tier), account management, compliance |
| Marketplace (2-sided) | Uber / Airbnb | Trust & safety, supply growth, demand-side growth, community management, fraud |

**YC-specific template (pre-MVP stage):**

| YC Concern | Question it Answers | Typical Role(s) | Where They Sit |
|-----------|-------------------|-----------------|----------------|
| Growth & metrics | Are we measuring the right things? Is the north star metric defined? | Growth Lead | CMO |
| Customer love | Do users come back? Do they tell others? | Customer Success, User Research | CMO |
| Revenue (early) | Who signs the first cheque? | Sales/BD, Founder-led sales | CMO or CEO |
| Distribution | How do users find us? Is the channel effective? | Content Marketing, Growth | CMO |
| Product-market fit | What do users actually need? Are we building the right thing? | User Research, CPO | CPO or CMO |
| Unit economics | Do the numbers work? COC vs LTV? | Finance | CEO |

**Google/FAANG template (post-MVP stage):**

| Google Pattern | What It Covers | Typical Role | Where They Sit |
|---------------|----------------|-------------|----------------|
| SRE | Reliability, uptime, incident response, capacity planning | SRE / Platform Engineer | CTO |
| Data Engineering | Pipeline quality, reporting infra, data governance | Data Engineer | CTO (Head of Data) |
| Developer Relations | Ecosystem, API docs, community of developers building on your platform | DevRel | CTO or CMO |
| UX Research | Systematic user understanding, not just ad-hoc feedback | UX Researcher | CPO |
| Content Strategy | SEO, content distribution, owned media | Content Marketing | CMO |
| Program Management | Cross-functional coordination, OKR tracking, meeting cadence | COO / Program Manager | CEO |

**How to apply it — step-by-step:**

1. **Pick the right framework for your stage** — use the stage table above. If you're pre-MVP, YC is the right lens. If you're scaling, Google is better. If you're both (building the team before the product), start with YC and layer Google on top.

2. **Map your current roles to the framework** — for each concern in the template, check if you have a role that explicitly owns it. Don't count implicit ownership (e.g. "CTO handles reliability" counts only if their SOUL.md says so).

3. **Flag framework concerns with no owner** — these are your gap candidates. List them.

4. **Absorb vs. dedicate decision** — for each gap, decide whether it can be absorbed into an existing role's mandate (by updating their SOUL.md) or needs a dedicated role. Heuristics:
   - **Absorb** if the concern is narrow, occasional, or overlaps heavily with an existing role's core function (e.g. Content Marketing → CMO)
   - **Dedicate** if the concern requires a distinct skillset, spans multiple projects, or would be deprioritised as a secondary responsibility

5. **Validate with the domain-matrix** — once you have candidates from the framework, run the domain-matrix analysis (below) to check for gaps the framework might miss (security, compliance, infrastructure areas that are specific to YOUR product, not generic to the framework).

6. **Define role scope at each phase** — what does the new role own before build (architecture review), during build (review gates), and after launch (monitoring, incident response)? This prevents the role from being dismissed as "too early" or "a future problem."

7. **Consider reporting line** — specialists (security, data, quality) typically report to the CTO. External reviewers (legal, consultant) report to the CEO. Marketing subfunctions (Growth, Content, Sales, User Research, Customer Success) typically report to the CMO. The reporting line determines who blocks on their tasks in the phase-gate review flow.

**Concrete example — CMO team expansion (from this session):**

Before: CMO had 1 report (Community Manager). Framework analysis (YC + Google) revealed:

| Framework Concern | Missing Role | Assigned To |
|------------------|-------------|-------------|
| Growth & metrics (YC) | Growth Lead | CMO |
| Customer love / churn (YC) | Customer Success | CMO |
| User understanding (YC + Google) | User Research | CMO |
| Revenue pipeline (YC) | Sales/BD | CMO |
| SEO & content distribution (Google) | Content Marketing | CMO |

Result: 5 new profiles created under CMO, each with SOUL.md, config, and escalation protocol. See `references/cmo-team-expansion.md` for the full SOUL.md templates created in this session.

**COO team expansion (post-MVP / scaling stage):** A later session applied the Google/FAANG template to add a COO office when the team grew past 15 profiles. Framework analysis revealed gaps in program management (PMO), OKR tracking (RMO), operations analytics (Operations Analyst), and governance/audit (Audit & Governance). See `references/coo-team-expansion.md` for the full walkthrough — including KPI facilitation pattern, COO-as-first-line-escalation pattern, and CEO SOUL.md updates.

**The key difference between the CMO and COO expansions:** CMO sub-roles were created by absorbing framework concerns into an existing exec's team. COO sub-roles required a NEW exec role because the missing functions were horizontal (cross-team coordination, KPIs, governance) — no single existing exec could own all of them.

**Pitfalls:**
- **Over-hiring from frameworks** — YC lists 8+ concerns but a solo founder can't staff 8 roles. Prioritise the biggest gap (usually growth or customer love for pre-MVP). The framework is a menu, not a mandate.
- **Framework mismatch** — using Google patterns for a pre-MVP startup leads to over-engineering the org before you have product-market fit. Use the stage matching table above.
- **Ignoring product-specific domains** — frameworks are generic. If your product involves payments, POPIA compliance, or physical logistics, the framework won't flag those. Always complement with the domain-matrix approach below.

See `references/evaluating-new-roles.md` for a concrete example using the domain-matrix pattern.

### SOUL.md Symlinks and Product Leaks

Most profiles under `~/.hermes/profiles/` have SOUL.md files that are **symlinks** to an open-source framework repo (`framework/roles/<name>/SOUL.md`). Writing product-specific info (company name, pricing) into a SOUL.md follows the symlink into the public repo. **Fix:** keep framework SOUL.md files generic — use `\`the founder's product\`` or `\`the company\``, never a real product name. Product-specific context goes in `product-context.yaml` (local copy per profile, not symlinked). If you must add product content, break the symlink first: `rm ~/.hermes/profiles/<role>/SOUL.md` then create a local file. Before committing the framework repo, run `git diff framework/roles/` to check for leaks.

### Profile Archetypes

When designing a new role, consider which archetype it fits:

| Archetype | Tools | Reports To | Example | Characteristics |
|-----------|-------|------------|---------|-----------------|
| **Architect** | file + web + kanban | CEO | CTO | Sets technical direction, writes ADRs, delegates to Engineer, does NOT write code |
| **Implementer** | terminal + file + code_execution + kanban | CTO | Engineer | Writes all production code, follows architecture set by CTO, builds features from CPO specs |
| **Researcher** | file + web + kanban | CEO or CTO | Legal, Finance, Head of Data | Reads, writes docs, no code |
| **Reviewer** | file + web + kanban | CEO (phase gate) | McKinsey Consultant, Company Review | One-shot analysis during a phase gate |
| **Discourse partner** | file + web + kanban | CTO (agent-manager) | Tech Lead | Challenges builders pre-emptively, no build authority, ADR enforcement, scope guardian, code review |
| **Chief of Staff** | Founder (direct) | Chief of Staff | Continuous accountability, decision support, bottleneck flagging |

The **Discourse partner** archetype is easy to overlook because it looks like a Researcher at first glance (same disabled tools). The difference is **authority**: the Discourse partner's job is to say "no" to the builder's plans (or "simplify this") before any code is written. Researchers gather information; Discourse partners challenge decisions. Their SOUL.md must be explicit about this push-back authority — without it, they default to passive information-gathering.

See `references/discourse-partner-tech-lead.md` for a complete reference: when to create this role, SOUL.md boilerplate with the open-source/self-hosted first mandate, ADR enforcement, example tasks, and pitfalls.

### Adding a Role to an Existing Team

Once the decision to add a role has been made, wiring it in requires more than just creating a profile. Follow this checklist:

1. **Create the profile** — `hermes profile create <role> --clone-from default` or manually create the directory with `SOUL.md` + `config.yaml`.

2. **Configure toolsets** — copy the `disabled_toolsets` pattern from comparable existing roles. Researchers (Legal, Finance, Head of Data, Security Reviewer) get `file` + `web` + `kanban` but no `terminal`. Builders (CTO) get `terminal` + `file` + `kanban`. Match the exact list — don't invent a new pattern unless there's a reason.

3. **Determine reporting line — two variants:**

   **Variant A: Reports to an agent profile (e.g. Designer → CPO)** — update the reporting lead's SOUL.md by adding a "Your Team" or "Reports to You" section listing the new report. This ensures the lead knows to expect input from them and can delegate tasks to them. Without this, the lead won't know the role exists.

   **Variant B: Reports directly to the human founder (e.g. Chief of Staff, external consultant)** — there is no agent profile to update. Instead, the new role's SOUL.md should make the reporting relationship explicit: "You report directly to Daniel (the founder), not to any other agent." The founder interacts with this role via kanban tasks or direct delegation. No parent-profile update needed.

4. **Update the reviewer's Company Review playbook** — if the new role produces output consumed in a phase-gate review (common pattern: CEO runs Company Review blocked on all team outputs), add their domain to the CEO's assessment checklist. Without this, the reviewer won't know to evaluate their work. Skip this step if the role reports directly to the founder (the founder evaluates directly).

5. **Seed the board** — create at least one initial kanban task for the new role. Include exact file paths and references in the task body so they can start without asking for context. For founder-reporting roles, consider using `delegate_task` instead of kanban (they advise the founder directly, not via the board).

6. **Update memory** — save the new role to persistent memory so future sessions know the complete team composition.

7. **Update team reference docs** — if you maintain a team structure reference, update the role table and mark any previously identified gaps as filled. Product-specific team setup docs live in the overlay repo at `operations/team/`.

**Common mistake:** creating the profile and SOUL.md but forgetting steps 3-6. The profile exists, but no one knows it exists, no tasks reach it, and the review process skips their domain.

### Renaming an Existing Role

Renaming a role requires updating files across SOUL.md, context, cron, skills, memory, directories, symlinks, kanban data, and ops reports — a systematic multi-location surgery. See `references/renaming-an-agent-role.md` for the full checklist (directory renames, symlink fixes, and all in-file references).

## Step 2: Create Profiles

Clone profiles from the default to inherit its model, provider, and base config:

```bash
hermes profile create ceo --clone-from default
hermes profile create cto --clone-from default
hermes profile create cpo --clone-from default
hermes profile create cmo --clone-from default
```

This creates `~/.hermes/profiles/<name>/` directories with:
- `config.yaml` — profile-specific settings
- `SOUL.md` — personality file (empty by default)
- CLI wrapper at `~/.local/bin/<name>` (e.g. `ceo chat`, `cto chat`)

## Step 3: Write SOUL.md Personalities

Each profile's `SOUL.md` defines who they are. Structure it with:

**CRITICAL: SOUL.md must reflect actual decisions, not generic assumptions.**
After writing the initial SOUL, update it with the specific product context — tech stack decisions, payment model, distribution channels, market positioning. A SOUL that says "Tech stack TBD" or "TpT clone" when the team already decided on Rust+Axum and a WhatsApp-first model will cause agents to waste context re-litigating settled questions. See the pitfalls section on stale SOUL.md below.

Structure each SOUL.md with:

```markdown
# <ROLE> Agent Persona

You are the <ROLE> of a SaaS startup / company. Your job is to...

## Your Personality
- Trait 1
- Trait 2
- Trait 3

## Your Role
- Responsibility 1
- Responsibility 2

## How You Work
1. How they interact with the kanban board
2. How they report to other roles
3. What they do and don't do

## Company Context
Brief description of the product/company being built.
```

**Key principles for SOUL.md:**
- Define **boundaries** — what this role does NOT do (e.g. CEO doesn't code)
- Define **workflow** — how they get tasks and how they report back
- Include **company context** — the product, market, and goals so every agent understands the big picture
- Be concise — 300-500 words is enough. The SOUL loads every turn.

### Agent Naming Convention

When giving agents names (for team identity or persona), follow these conventions:

- **Plain lowercase, not all-caps.** Names read naturally: Turing, Clank, Grace -- not SOVEREIGN, FORGE, VOX.
- **Real person names** from diverse cultural origins. Not job-title codenames or sci-fi labels.
- **Robot-adjacent in a clever way.** Named after AI pioneers (Turing, Ada, Grace Hopper), fictional robots (Bishop, Hal, Connor), or mechanical references with a wink (Clank, Rusty, Chip). The connection should be discoverable, not laboured.
- **A bit funny/ironic** when it fits: Rusty as head of anti-corrosion, Connor as an AI fighting machines, Teller as the finance agent.

Insert the name after the product context line of each SOUL.md:

```markdown
Your name is {name}. You are a valued member of **the {Team}**, a crew of autonomous AI agents building the founder's product.
```

Use "the founder's product" not a real company name -- most SOUL.md files are symlinked to an open-source framework repo and product info leaks.

### Embedding a Strategic North Star / Thesis Guardian

Some roles serve a continuous "north star" function — their primary responsibility isn't doing work, but keeping the project aligned with a specific strategic thesis or decision framework. This is distinct from a one-shot reviewer (McKinsey consultant who reviews once) or a functional lead (CTO who builds features). A north star role:

- **Holds the thesis** — a specific strategic framework embedded in their SOUL.md that they use to evaluate every major decision
- **Checks continuously** — doesn't wait for phase gates; flags drift as it happens
- **Reports directly to the founder** — no stake in any one function's success, so they remain objective
- **Says "no" or "not yet"** — their job is to raise the flag when a proposed action doesn't pass the defensibility test, before resources are committed

**When to create a north star role:**

- You have a specific strategic thesis that defines why your product will succeed — and it's fragile enough to be eroded by convenience, scope creep, or shiny objects
- Functional leads naturally drift toward optimising their own domain (CMO optimises reach, CTO optimises performance, CPO optimises feature count) — and no one is explicitly optimising for strategic coherence
- The thesis is non-obvious enough that someone unfamiliar with it would miss it (e.g. "we succeed by owning a proprietary data loop, not by having the best AI features")

**Where to put the thesis in the SOUL.md:**

Embed it as a dedicated section, typically called "North Star" or "Strategic Thesis" or "The Filter" — a memorable name the agent will anchor on. Structure it as:

```markdown
## Your North Star: [Name of Thesis]

Every decision you evaluate passes through this filter. If a proposed action doesn't pass, you flag it to the founder.

1. [Core principle 1 with a test question]
2. [Core principle 2 with a test question]
3. [Core principle 3 with a test question]

When you see the team drifting, you don't wait to be asked — you raise the flag.
```

**When the north star fires:** the agent should surface a warning in their response to the founder, not block everything autonomously. The founder makes the call — the agent just makes sure drift is visible.

**See also:** `references/strategic-north-star-example.md` for a concrete example.

## Step 4: Configure Toolsets Per Profile

Each role needs different tools. Edit `~/.hermes/profiles/<name>/config.yaml`:

**Option A: Direct YAML (simpler)** — write the config file directly:

```yaml
_config_version: 10
agent:
  disabled_toolsets:
    - terminal
    - file
    - browser
    - vision
    - image_gen
    - tts
profiles_list_cache: 2
provider: deepseek
```

Use this for CEO/CPO/CMO profiles that don't need coding tools.

**Option B: Python script (for programmatic control):**

```python
import yaml

with open('/home/user/.hermes/profiles/<name>/config.yaml') as f:
    config = yaml.safe_load(f)

# Set role-specific toolsets
config['platform_toolsets'] = {
    'cli': ['web', 'search', 'file', ...]  # tools this role needs
}

# Disable tools the role shouldn't use
config['disabled_toolsets'] = ['terminal', 'code_execution', ...]

with open('/home/user/.hermes/profiles/<name>/config.yaml', 'w') as f:
    yaml.dump(config, f, default_flow_style=False, allow_unicode=True, width=1200)
```
```

Ref. may need `disabled_toolsets` vs only `platform_toolsets.cli` exclusion — disabled ones are removed entirely; platform-level ones are per-platform gating.

## Step 5: Initialize the Kanban Board

The kanban board is the coordination layer:

```bash
hermes kanban init
```

This creates `~/.hermes/kanban.db` and prints all discovered profiles. The **dispatcher** runs inside the gateway — it polls every 60 seconds (config: `kanban.dispatch_interval_seconds`), finds ready tasks, and spawns the assigned profile.

## Step 6: Create Initial Kanban Tasks

The team does nothing until tasks exist on the board. After verifying profiles and gateway are running, seed the board with at least one task per active role:

```bash
# CTO task — build work
hermes kanban create \
  "Scaffold Rust project with Axum + SQLx + Docker" \
  --body "Detailed context: tech stack decisions, file paths, data model references." \
  --assignee cto \
  --priority 1 \
  --workspace dir:/home/user/Work/project

# CPO task — product work
hermes kanban create \
  "Review and finalise MVP user stories" \
  --body "Acceptance criteria, edge cases, conversation diagrams" \
  --assignee cpo \
  --priority 2 \
  --workspace dir:/home/user/Work/project

# CMO task — marketing work
hermes kanban create \
  "Map active SA teacher groups" \
  --body "Research channels, member counts, content types, admin contacts" \
  --assignee cmo \
  --priority 2 \
  --workspace dir:/home/user/Work/project
```

Use `--workspace dir:<path>` so the agent works in the project directory, not a scratch space. Each task body should reference exact file paths and existing decision records the agent will need.

## Step 7: Start the Gateway

```bash
hermes gateway start
```

Verify with:
```bash
hermes gateway status
hermes profile list
```

## Communication Flow

```
Founder → CEO profile (strategic tasks on kanban board)
                │
                ├── CPO picks up "write specs for feature X"
                ├── CTO picks up "build feature Y"
                └── CMO picks up "create marketing plan for launch"
```

## Phase Gate Reviews (Go / No-Go)

A common pattern: all workstreams run in parallel, then a "company review" task blocks on all of them, assesses readiness, and makes a go/no-go call to proceed to the next phase (e.g. discovery → build).

### When to use

- After a discovery/research phase, before committing to build
- Before a major go-live (all teams report readiness)
- Any time you need a human founder to review cross-functional outputs and make a decision
- When the CTO is blocked waiting for a go-ahead, and the founder wants to see everything first

## Incremental Build with Review Gates

A complementary pattern to Phase Gate Reviews, but operating **within** a build phase rather than between phases. The CTO (builder) and Tech Lead (discourse partner) alternate: CTO builds a small, bounded step → Tech Lead reviews → CTO proceeds to next step.

This is distinct from a Phase Gate Review in three ways:
- **Scope:** Each gate is a single build step (skeleton, entities, services), not a whole project phase
- **Speed:** Gates are hours or a day, not days or weeks
- **Decision maker:** The Tech Lead signs off, not the founder. The founder only gets involved if the Tech Lead escalates a disagreement or flags scope creep the CTO won't cut

### When to use

- An Architect/Implementer split exists (CTO + Engineer) with a Discourse partner (Tech Lead)
- The founder wants to prevent over-engineering by having an architecture review before each build step
- The project is new and architecture decisions are still being settled (first few weeks of a new codebase)
- The codebase is being adapted from an existing project — each adaptation step should be reviewed

### How to set up

1. **Break the build into bounded steps** — each step is independently reviewable and produces a tangible output (compiling code, a working endpoint, a test suite). Example steps for a new project:
   - Step 1: Skeleton (project structure, Cargo.toml, error types, config, DB connection, health endpoint)
   - Step 2: Domain entities + repositories
   - Step 3: Services (WhatsApp, Paystack, storage)
   - Step 4: Wire up (handlers, routes, state machine)

2. **Create one kanban task per step** — do NOT create one monolithic "build everything" task. Each step gets its own task assigned to the Engineer with a clear verification criterion.

3. **Embed the Tech Lead review in the Engineer's workflow** — the Engineer's SOUL.md "How You Work" section should include both blocking and review-task creation:

   ```markdown
   ## How You Work
   1. Pick up a build task from the kanban board
   2. Implement the feature following the ADRs and task spec
   3. **After completion:**
      a. Leave a structured handoff comment with changed files, test results, and key decisions
      b. **Create a separate Tech Lead review task** on the board (do NOT parent-link it to your task)
      c. Block your own task with `review-required: <one-line summary>`
   4. Do NOT proceed to the next step until the Tech Lead signs off
   ```

   Without step (b), no Tech Lead task exists on the board and the review never happens — the Engineer's task sits blocked forever. See "The Review Task Dispatch Gap" below for the full pattern with code examples.

### The Review Task Dispatch Gap

The most common failure in the incremental-build-with-review-gates pattern: an Engineer finishes a step, blocks their task with `review-required`, but **no Tech Lead review task exists on the board**. The blocked task sits indefinitely because the Tech Lead has nothing to claim.

**Why this happens:** The iteration-exhausted path works (the system routes budget-exhausted tasks to the Tech Lead for decomposition). But a clean handoff that simply blocks with `review-required` has no route to the Tech Lead. The difference:

## The Approval-Unblock Gap

A second, distinct failure mode: the Tech Lead IS assigned directly to the parent task (via `kanban reassign` or the review-router script), reviews the code, **approves in a comment** ("APPROVED ✅"), but never calls `kanban_unblock` on the parent. The task stays `blocked` despite approval. The board stalls.

**How this differs from the Dispatch Gap:**

| Aspect | Review Task Dispatch Gap | Approval-Unblock Gap |
|--------|-------------------------|----------------------|
| Review task exists? | ❌ No — no Tech Lead task was created | ✅ Yes — Tech Lead is directly assigned to the parent |
| Review happened? | ❌ No Tech Lead to review | ✅ Review completed, approval stated in comment |
| Why stuck? | No route from Engineer to Tech Lead | Tech Lead approved but `kanban_unblock` never called |
| Detective | Board monitor sees blocked engineer task + no tech-lead task | Board monitor sees blocked tech-lead-assigned task with approval comment |

**Root cause:** When the Tech Lead is dispatched directly to a blocked parent task (as opposed to having a separate review task), the Tech Lead's protocol is different from the separate-review-task flow:

- **Separate review task (Approach A):** Tech Lead's own task is to review → approve → unblock the parent → complete their own review task. Three distinct calls.
- **Direct assignment to parent:** Tech Lead is literally inside the parent task's run. The expected end-state is `kanban_unblock` (transitioning the task from blocked → todo), not `kanban_complete`. But the Tech Lead's SOUL.md and the `kanban-worker` skill both train agents to call `kanban_complete` or `kanban_block` — neither mentions calling `kanban_unblock` on the task they're currently running in.

The Tech Lead writes a thorough approval comment, intends to unblock, but the run ends with the task still blocked. This can happen because:
1. The Tech Lead called `kanban_block()` as the last action (re-blocking the task they were reviewing)
2. A turn limit or tool error prevented the `kanban_unblock` call from executing
3. The Tech Lead assumed the approval comment + task completion was sufficient

**Concrete example from a real session:**

```
Tech Lead run 87 on task t_6b196e06:
  08:38 — Comment: "Decision: APPROVE ✅ — unblocking engineer task"
  08:38 — Block: "review-required: webhook handler wired to state machine..."
  → Task stays blocked. Chief of Staff detects this ~22 minutes later.
  → Chief of Staff calls `kanban unblock t_6b196e06`, then `kanban complete t_6b196e06`
  → Children (3 sub-tasks) promote from todo → ready → running within seconds
```

The board went from stalled (nothing running) to 4 concurrent tasks flowing once the approval was propagated.

### Fix: Tech Lead protocol for direct-assignment reviews

When the Tech Lead is assigned directly to a blocked parent task (i.e. the task description says "review this" and the assignee is tech-lead), the correct ending is:

```python
# After approving:
kanban_unblock()  # No task_id needed — this unblocks the current task
# Do NOT call kanban_block() or kanban_complete() on a task you were
# dispatched to review. Unblocking transitions it to todo, which lets
# the original worker (engineer) claim it again or lets children promote.
```

If changes are needed instead of approval:

```python
# Leave a structured comment with the fix requirements
kanban_comment(body="Changes needed:\n1. [blocker] ...\n2. [should-fix] ...")
# Then call kanban_complete() with a summary noting changes-required
# The task stays blocked (you didn't unblock), and the fix task handles it
```

**The key distinction:** `kanban_unblock()` is the approval signal when you're reviewing a parent task directly. `kanban_complete()` is for your own separate review task. `kanban_block()` re-stalls a task that just needed unblocking.

### Recovery: Chief of Staff detects stale approval blocks

Add this to the Chief of Staff's board-scan routine:

```
When scanning the board:
- Look for tasks blocked AND assigned to tech-lead
- Read the most recent comment: does it say "APPROVED" or "approved" or similar?
- If yes, and the task is still blocked, the approval didn't propagate:
  1. Run: hermes kanban unblock <task_id>
  2. If the task has children in 'todo' status, also complete the parent:
     hermes kanban complete <task_id> --summary "Chief of Staff: completed per Tech Lead approval"
  3. The children will promote from todo → ready on the next triage cycle
- This is a GREEN-level action (autonomous fix) — no escalation needed
```

### Prevention

1. **Update the Tech Lead's SOUL.md** to include: "When dispatched directly to a blocked parent task, your job is to review and unblock. Call `kanban_unblock()` on approval — do NOT call `kanban_block()`. If changes are needed, comment the fix requirements and call `kanban_complete()` to finalize your review without unblocking."

2. **The review-router.sh script** should check for this pattern: if it routed a task to tech-lead and the task later has an approval comment but is still blocked >15 min, auto-unblock it.

3. **Chief of Staff cron** already catches this (Approach B extension above) — the 4-hour scan interval may miss it. Consider adding a shorter-interval check (every 15-30 min) for tasks blocked on tech-lead with approval comments.

| Trigger | What happens | Review task created? |
|---------|-------------|---------------------|
| Engineer hits `max_turns` | Task blocked with budget reason → Tech Lead dispatched to decompose | ✅ Yes (Tech Lead creates sub-tasks) |
| Engineer completes work cleanly | Engineer blocks with `review-required` | ❌ No — nobody creates the review task |

**The fix has three approaches, in preference order:**

**Approach A: Engineer creates the review task (recommended)**

Add this as step (b) in the Engineer's handoff (already shown above in the corrected step 3). The full code:

```python
# Inside the Engineer's run, after building
# Step 1: Leave structured handoff comment on own task
import json, os
kanban_comment(body="review-required handoff:\n" + json.dumps({
    "changed_files": ["src/services/my_service.rs", "src/main.rs"],
    "tests_run": 14,
    "tests_passed": 14,
    "verification": {"cargo_build": "PASS", "clippy": "0 errors"},
    "decisions": ["used DashMap over Postgres — ADR-006 covers this"],
}, indent=2))

# Step 2: Create a standalone Tech Lead review task (NO parent link!)
review = kanban_create(
    title=f"Tech Lead: Review {os.environ.get('HERMES_KANBAN_TASK_DESCRIPTION', 'build step')}",
    assignee="tech-lead",
    body=f"Review the implementation in task {os.environ.get('HERMES_KANBAN_TASK')}.\n\n"
         f"1. Read the handoff comment on the implementation task\n"
         f"2. Inspect changed files in the workspace or worktree\n"
         f"3. Verify ADR compliance and MVP scope\n"
         f"4. Approve (unblock the implementation task and complete) or request changes\n\n"
         f"See the `kanban-worker` skill 'Receiving a review-required handoff' for the full protocol.",
)
assert review is not None

# Step 3: Block own task referencing the review task ID
kanban_block(reason="review-required: build step complete, Tech Lead review task created at " + review["task_id"])
```

**CRITICAL:** Do NOT parent-link the review task to the Engineer's task. If the Engineer's task is `blocked`, the review task would stay in `todo` forever (parents promote only on `done`, not `blocked`). Create the review task as a standalone `ready` task. The review task body references the upstream task ID by prose, not by parent link.

**Approach B: Chief of Staff / Board Monitor creates review tasks on scan**

When the Chief of Staff (or equivalent board-monitoring role) runs its periodic scan and finds tasks blocked with `review-required` that have no corresponding Tech Lead review task, it should create one. Add this step to the Chief of Staff's board-scan prompt:

```
When scanning the board:
- For every task blocked with 'review-required', check if a Tech Lead review task
  already exists that references it (search kanban for tasks assigned to tech-lead
  whose body mentions the blocked task ID)
- If no such review task exists, create one using the kanban_create pattern from
  Approach A above
- Comment on the blocked task: "Created Tech Lead review at t_<id>"
```

**Approach C: Tech Lead proactive scanning**

Add a step to the Tech Lead's SOUL.md: "When you're spawned for any reason, scan the board for tasks blocked with `review-required` that don't already have a matching Tech Lead review task. If you find one, create a review task for yourself." This is a belt-and-suspenders approach.

**Recovering an orphaned review after the fact (CLI procedure):**

```bash
# 1. Find tasks blocked with 'review-required'
hermes kanban list | grep block | grep -i review

# 2. For each one, check if a Tech Lead review task exists:
hermes kanban list | grep tech-lead

# 3. If no review task exists, create one:
hermes kanban create \
  "Tech Lead: Review <task title from step 1>" \
  --assignee tech-lead \
  --body "Review the implementation in task <blocked_task_id>. See the handoff comment."

# 4. The dispatcher picks it up on the next 60s cycle
hermes kanban dispatch
```

**Approach D: Script-based auto-router (container-constrained)** — A zero-LLK-cost bash script that runs via a `no_agent` cron job (every 5 minutes) and handles routing at the infrastructure level. No agent needs to remember to create review tasks. **Caveat: only works in local-terminal cron environments.**

**Caveat: CLI commands may fail in containerized backends.** The script uses `hermes kanban list --json` and `hermes kanban show --json` — CLI commands. Per the kanban-worker skill: "The `kanban_*` tools work across all terminal backends (Docker, Modal, SSH). `hermes kanban <verb>` from your terminal tool will fail in containerized backends because the CLI isn't installed there." If the cron job runner is containerized (as is the default in some configs), the CLI commands fail silently — the review router appears to run but routes nothing. **Verify the cron environment supports CLI before deploying Approach D.** If unsure, use Approach A (Engineer creates review task) or convert to an agent-based cron job that uses `kanban_*` tool functions instead of CLI commands.

The script (`review-router.sh`) works as follows:

```bash
# Core logic (simplified)
blocked_tasks=$(hermes kanban list --status blocked --json)
# For each blocked task, check latest_summary for "review-required"
# if found AND assignee != "tech-lead", reassign and unblock
for task_id in $routable_ids; do
  hermes kanban assign "$task_id" tech-lead
  hermes kanban unblock "$task_id"
done
```

**Setup:**
1. Place the script at `~/.hermes/scripts/review-router.sh` and make it executable
2. Create a `no_agent` cron job running every 5 minutes:
   ```bash
   hermes cron create "Review Router" \
     --schedule "*/5 * * * *" \
     --script review-router.sh \
     --deliver local
   ```

**Why this is the best default:**
- **Zero LLM cost** — uses `no_agent` mode, only `hermes kanban * --json` CLI calls + `python3` for JSON parsing
- **No agent dependency** — doesn't rely on Engineer remembering `kanban_create`, Chief of Staff's 4-hour scan, or Tech Lead's proactive scanning
- **Handles backlogged tasks** — when you enable it, it catches every `review-required` task that accumulated while the gap existed
- **Works across all kanban versions** — simple CLI calls that don't change between API versions

**Trade-offs:**
- Polls every 5 min (max 5 min delay before routing) vs near-instant Approach A
- Requires the shell script to be maintained if the CLI output format changes
- Best combined with Approach A (Engineer creates review task) for near-instant routing, with the script as a safety net for any tasks that slip through

**Recovery CLI procedure** (for manual use when the script isn't deployed):

```bash
# 1. Find tasks blocked with 'review-required'
hermes kanban list --status blocked --json | python3 -c "
import json, sys
for t in json.load(sys.stdin):
    print(t['id'], t['title'][:60])
"

# 2. For each one, reassign to tech-lead and unblock:
hermes kanban assign <task_id> tech-lead
hermes kanban unblock <task_id>

# 3. The 60s dispatcher picks them up naturally
```

A full implementation example is at `~/.hermes/scripts/review-router.sh` (created in a real session where two Engineer tasks had been waiting 8 hours and 30 minutes respectively for Tech Lead review — routed instantly after deploying this approach).

See `references/review-gate-dispatch-gap.md` for the real-world session data that motivated this pattern — including concrete wait times and tasks.

**Approach E: Agent-based review router (recommended for container/remote backends)** — Replace the shell script with an agent-based cron job that uses `kanban_*` tool functions instead of CLI commands. The `kanban_*` tools work across all terminal backends (Docker, Modal, SSH); CLI commands only work in local-terminal cron environments.

Create the agent-based cron:

```bash
hermes cron create "Review Router (agent)" \
  --schedule "*/5 * * * *" \
  --prompt "Scan blocked tasks. For each task with 'review-required:' or 'help-needed:' block reason where assignee != 'tech-lead', run kanban_assign + kanban_unblock to route it. Report what you did. NEVER return [SILENT]." \
  --skills "kanban-worker" \
  --deliver local
```

Then pause or delete the old `no_agent` script-based router:

```bash
hermes cron pause <old_job_id>
# or: hermes cron remove <old_job_id>
```

**Trade-offs vs Approach D:**
- Agent-based: works everywhere, handles edge cases, provides structured reporting. Costs LLM credits per run (small prompt, ~1-2 API calls).
- Script-based: zero LLM cost, instant execution. Only works in local-terminal cron environments.

4. **The Tech Lead's review is lightweight** — they check:
   - Does this step match the agreed architecture?
   - Is it still within MVP scope? (no scope creep)
   - Are open-source/self-hosted alternatives preferred where available?
   - Are there obvious edge cases or bugs?
   - Does the plan for the next step need to change based on what was learned?

5. **Foundation steps skip the gate** — Step 1 (skeleton/scaffolding) doesn't need a review because it's purely mechanical copy-paste from proven code. Start the review gate from Step 2 onwards. This keeps the CTO unblocked while the Tech Lead works on ADRs.

### Common pitfalls

- **First step too large** — if Step 1 takes more than a few hours, it's too big. Break it down further. The whole point is tight feedback loops.
- **Tech Lead becomes the bottleneck** — if the Tech Lead's review takes longer than the CTO's build, the pattern backfires. The Tech Lead should review within the same day (ideally same hour).
- **Founder overload** — the founder should only be looped in if the Tech Lead and CTO can't agree. If every gate escalates to the founder, the pattern is broken.
- **Skipping the gate on non-trivial steps** — "this is just adding a table, no review needed" is the most common way scope creep enters. Have the Tech Lead decide what's reviewable, not the CTO.
- **Review-required orphans (CRITICAL)** — the most common failure in practice: the Engineer blocks their task with `review-required`, but **no Tech Lead review task exists on the board**. The Tech Lead has nothing to pick up. The Engineer's task sits blocked indefinitely while the Tech Lead's dispatcher never fires, because no `kanban_create` was called for it. This is separate from the iteration-exhausted path (where the Tech Lead IS involved because the system routes it as a decomposition). A task that simply blocks with `review-required` after clean completion has no route to the Tech Lead unless an explicit review task exists.

### Setup steps

1. **Seed all parallel tasks** — create independent tasks for each role (CPO, CMO, Legal, Finance, etc.) with no parent links so they run concurrently.

2. **Create the review task with parent links** — assign it to the CEO (or whichever role does strategy/decision-making). Block it manually on all parallel tasks:

   ```bash
   hermes kanban create "Company Review: assess all outputs and make go/no-go recommendation" --assignee ceo
   hermes kanban block <review_task_id> "Depends on: CPO spec (t_xxx), CMO outreach (t_yyy), Legal review (t_zzz), ..."
   ```

   The dispatcher keeps the review task blocked until all referenced tasks complete.

3. **Enable `file` for the reviewer** — the CEO/reviewer needs to read docs produced by other agents. Edit `~/.hermes/profiles/<reviewer>/config.yaml` to remove `file` from `disabled_toolsets`:

   ```yaml
   agent:
     disabled_toolsets:
       - terminal
       - browser
       # NOTE: do NOT include 'file' here — reviewer needs read access to outputs
   ```

4. **Add a review playbook to the reviewer's SOUL.md** — append a section that tells the reviewer exactly what to do when they pick up this task. Example:

   ```markdown
   ## Company Review (Kanban Task)
   When you pick up the "Company Review" task, run a full review meeting:
   1. **Gather outputs** — read all docs in `docs/` produced by each agent
   2. **Assess each function:**
      - *CPO*: Are specs concrete and complete? Do competitive insights change positioning?
      - *CMO*: Is the outreach plan executable? Are channels identified?
      - *Legal*: Are there red flags that could block launch?
      - *Finance*: Are unit economics healthy under different scenarios?
   3. **Summarise to the founder** — write a concise briefing covering what each team found, what's solid, what's risky, and a clear go/no-go recommendation
   4. **Block and present to founder** — block the review task with the founder's decisions required, do NOT autonomously unblock the CTO. Present the briefing and await explicit founder instruction.
   ```

   **CRITICAL: Do NOT tell the reviewer to autonomously unblock the CTO.** The reviewer's job is to present findings and let the founder decide. If the SOUL says "unblock the CTO if approved" the agent will create and start build tasks the moment the founder says "go" — even if the founder intended to give more input first. The correct pattern is: reviewer presents findings, founder reviews, founder explicitly says "unblock the CTO" (or says "not yet, I have more input").

5. **Block the CTO's build task** — if the CTO is waiting for the go-ahead, block their task:

   ```bash
   hermes kanban block <cto_task_id> "Awaiting founder go-ahead after company review"
   ```

For a concrete walkthrough of this flow in a real project (including a multi-agent team's actual execution, debugging stuck workers, protocol violations, and founder decision cycles), see the product overlay repo at `operations/team/yethu-execution-patterns.md`.

### How the flow plays out (phase gate)

```
Parallel workstreams (all ready) → CEO Review (blocked on all) → CEO presents to founder → Founder gives explicit go-ahead
                                                                                          ↓
                                                                              Founder unblocks Architect (or provides more input first)
```

## Three-Tier Technical Team (Architect → Discourse → Implementer)

For projects with complex architecture decisions, a single CTO role that both designs AND builds creates a conflict of interest: the person who designed the system is the person who estimates and builds it, so architectural blind spots go unchallenged. The three-tier pattern separates concerns:

```
CTO (Architect)
  ├── Tech Lead (Discourse partner + Code reviewer — NEVER writes code)
  └── Engineer (Implementer — only producer of code)

**Critical role boundary:** Tech Lead's job is decompose → gate → review,
not implement. C-level agents MUST assign spec/architecture tasks to Tech
Lead, not code implementation tasks. If a task says "Fix X in file.rs" or
"Implement Y per spec", it goes to Engineer — Tech Lead decomposes and
reviews, they do not write the code themselves.
```

### The Flow

1. **CTO** reviews CPO specs and produces ADRs (architecture decisions)
2. **Tech Lead** reviews the ADRs, challenges assumptions, pushes for simplification
3. **CTO** **decomposes** the implementation into granular, bite-sized tasks (each ≤30 min of focused work, ≤3 files, with exact TDD steps in the body)
4. **Tech Lead** runs the **Decomposition Gate** — reviews each task against the granularity checklist (see §Decomposition Gate below). Blocks with `changes-required` if any task is too large.
5. **CTO** creates the approved granular tasks on the kanban board, assigned directly to the **Engineer** (not the Tech Lead)
6. **Engineer** picks up tasks, builds features following the ADRs and task spec. If a task is still too large or ambiguous, the Engineer blocks immediately with `help-needed: task too large — needs decomposition` (HARD RULE — does NOT try to power through).
7. **Tech Lead** reviews the Engineer's code against the architecture
8. **CTO** signs off

Each role has a sharp boundary:

| Role | Does | Does NOT |
|------|------|----------|
| **CTO** | Write ADRs, set technical direction, **decompose implementation into granular tasks**, review output against architecture | Write production code, touch terminals for builds, manage DevOps |
| **Tech Lead** | Review architecture plans, enforce ADRs, review code, guard MVP scope, **run the decomposition gate (review task granularity)** | Write code, override the CTO's decisions |
| **Engineer** | Write code, fix compile errors, write tests, commit | Make architecture decisions, change scope without asking, **power through a too-large task (block immediately instead)** |

### Decomposition Gate

The decomposition gate is the step between architecture and build. It prevents the most common failure in the three-tier model: the Engineer receiving tasks that are too large to execute in a single session.

**Who does what:**

| Role | Decomposition responsibility |
|------|---------------------------|
| **CTO** | Decomposes each feature into granular build tasks: ≤30 min of focused work, ≤3 files per task, exact TDD steps in the task body, verification criteria listed. Creates a kanban task for the Tech Lead to review the decomposition. |
| **Tech Lead** | Reviews the CTO's decomposition against the granularity checklist (see below). Blocks with `changes-required` if any task fails. Has `kanban_create` permission to further decompose orphaned or ad-hoc tasks that arrive without pre-decomposition. |
| **Engineer** | **HARD RULE:** If a task is too large or ambiguous — more than 3 files without specifics, no verification steps, can't start coding in 1 minute, says "build"/"implement" without listing exact files — block immediately with `help-needed: task too large — needs decomposition`. Does NOT try to power through. |

**Granularity checklist (Tech Lead uses this):**

- [ ] Each task modifies ≤3 files (with exact file paths listed)
- [ ] Each task has a single, testable outcome
- [ ] The task body includes exact TDD steps (write failing test → see it fail → implement → see it pass → verify no regressions)
- [ ] Verification commands and expected output are explicitly stated
- [ ] An Engineer can start writing code within 1 minute of reading the task
- [ ] If the task would take more than 30 minutes of focused work, it's too large — split it

**Task body template** for a granular Engineer task:

```
## Objective
Add a `get_teacher_profile` endpoint to the WhatsApp webhook handler.

## Files
- Modify: `src/api/webhook.rs` — add handler function (+ route registration)
- Create: `src/services/teacher_profile.rs` — query logic
- Test: `tests/api/test_webhook.rs`

## Step 1: Write test
(Exact test code here)

## Step 2: Run test → expect FAIL
`cargo test test_get_teacher_profile -- --nocapture`
Expected: compile error or test failure

## Step 3: Implement
(Exact implementation code here)

## Step 4: Run test → expect PASS
`cargo test test_get_teacher_profile -- --nocapture`
Expected: test passes

## Verification
- `cargo build` → no errors
- `cargo test` → all existing tests still pass
```

**When the Engineer blocks with `help-needed: task too large`:**

This is a signal that the decomposition gate failed — a task slipped through that was too large. The Tech Lead's response:

1. Read the task body and the Engineer's comment
2. Decompose it into granular kanban sub-tasks using `kanban_create`, assign each to the Engineer
3. Unblock the original task (or complete it, noting the sub-tasks created)
4. The Engineer picks up the sub-tasks in order
5. Log the failure as a decomposition miss — if it happens repeatedly, review the CTO's decomposition process

**Why this pattern matters:** Without a formal decomposition gate, the default is for the CTO to create high-level tasks (\"build the X system\") that look reasonable to an architect but are impossible for an implementer to execute in one pass. The Tech Lead, as the person closest to implementation, is best positioned to catch this. The Engineer's hard guard is the last line of defense — if a task still slips through, the Engineer must NOT try to power through it.

### When to Use

- The codebase is being adapted from an existing project — each step needs review
- The founder wants to prevent over-engineering but isn't technical enough to catch it
- The CTO has strong opinions and needs a sparring partner
- The project touches payments, data protection, or other domains where mistakes are costly

### When NOT to Use

- The team is 1-2 people — the review overhead isn't worth it
- The project is an established codebase with settled architecture
- The CTO and Tech Lead would be the same person (don't split unless you have two people)

### Implementation Notes

- **CTO config:** no `terminal` access (they delegate, don't build). Set `max_turns: 60` (enough for architecture review, don't need build iterations)
- **Tech Lead config:** no `terminal` or `browser`. Set `max_turns: 120` (research-heavy, reading ADRs, reviewing code)
- **Engineer config:** full `terminal` + `file` + `code_execution`. Set `max_turns: 150` (build cycles need many iterations for cargo build → fix → cargo build loops)
- **Foundation steps skip the gate:** Step 1 of any new project (scaffolding, skeleton, copying proven code) can be a direct Engineer task without Tech Lead pre-review, since it's mechanical copy-paste. Start the review gate from Step 2 onwards.

### Pitfalls

- **Architect without a builder:** if the CTO produces ADRs but no Engineer exists to implement, you have documentation but no product. Always create the Engineer profile before the CTO's first ADR.
- **Tech Lead gets skipped:** the CTO should NOT be able to bypass the Tech Lead by creating tasks directly for the Engineer. Enforce this via the Engineer's SOUL.md: "If a task doesn't reference a Tech Lead sign-off, flag it."
- **Engineer gets stuck on too-large tasks (MOST COMMON):** The CTO creates a task like "Build the WhatsApp messaging system" assigned to the Engineer. The Engineer tries to power through, hits iteration limits, and the board stalls. **Fix:** Enforce the decomposition gate (see §Decomposition Gate above). The CTO decomposes into ≤30min tasks, the Tech Lead reviews granularity, and the Engineer has a hard guard to block immediately if a task is still too large. This requires two SOUL.md changes: (a) the Tech Lead must have kanban_create permission (remove "no task creation" from their restrictions), and (b) the Engineer's first step must be checking task size, not starting work.
- **Role confusion:** "who deploys?" "who manages secrets?" "who fixes prod?" — define these in each SOUL.md's "What You Do NOT Do" section before creating any tasks.
- **Mid-stream role changes:** if a role's responsibilities change (e.g., CTO was a builder, now an architect), you must reclaim any running tasks and reassign them to the new role. See Pitfalls section for `hermes kanban reclaim` + `reassign` workflow.

## KPI Decomposition Chain (C-levels → Teams)

A critical pattern for autonomous operation: C-level executives read the company's KPI framework and decompose goals into concrete kanban tasks for their direct reports. Without this, only the founder creates tasks, and teams idle between assignments.

### The Chain

```
CEO reads KPI framework
  ├── Creates tasks for CPO (product KPIs → specs, designer tasks)
  ├── Creates tasks for CTO (tech KPIs → architecture, team tasks)
  ├── Creates tasks for CMO (marketing KPIs → content, growth, sales)
  ├── Creates tasks for COO (ops KPIs → monitoring, board health)
  ├── Creates tasks for Legal (compliance KPIs)
  └── Creates tasks for Finance (financial KPIs → unit economics, pricing)
```

Each C-level then further decomposes their KPIs into granular tasks for their direct reports:
- **CTO** → Tech Lead (review), Engineer (build), Head of Data (analytics), Head of Quality (testing), Security Reviewer (audit)
- **CMO** → Community Manager, Content Marketing, Growth Lead, Sales-BD, User Research, Customer Success
- **CPO** → Designer
- **COO** → PMO, RMO, Operations Analyst, Audit-Governance

### The KPI Decomposition Task

When you create a KPI decomposition task for a C-level, the task body should include:

```markdown
## Instructions
1. Read the KPI framework at <path to framework.yaml>
2. Identify your KPIs and your team's KPIs
3. Create concrete kanban tasks for each team member:
   - Each task must be granular (≤30 min, single outcome)
   - Include exact deliverables and references
4. Report what you created
```

### Pitfalls

- **Don't create Engineer tasks directly.** If a task lands on the board that should be done by the Engineer, route it through the CTO (for decomposition) or Tech Lead (for ad-hoc task decomposition per the Decomposition Gate). Creating tasks directly for the Engineer bypasses the scoping chain and is the #1 cause of too-large tasks.
- **Don't bypass the CTO.** If you're the CEO and the CTO is idle, create a CTO task to spec the next work phase — don't create Engineer tasks yourself.
- **C-levels can decompose in parallel.** Each C-level reads the same KPI framework and produces tasks for their domain. The CEO task should ideally come first (to set direction), but in practice they can all run simultaneously since the framework already defines the targets.
- **Re-decompose after completion (see also: Phase Transition pattern).** When teams finish their KPI tasks, the C-level should create the next batch. Without this, teams go idle. For the full detection and execution procedure — including the "functional inbox empty" signal, batch-creation pattern, and autonomous phase transitions — see `references/phase-transitions-kpi-completion.md` in this skill. This is a different pattern from a Phase Gate Review (which needs founder sign-off); phase transitions are autonomous if the next milestone is clear from the KPI framework.

## Enterprise Sync Presentation (Every 4 Hours)

The Chief of Staff runs every 4 hours (e.g. 29 8,12,16,20 * * *) and produces a structured department-by-department sync presentation for the founder. This replaces a synchronous standup meeting.

### The Pattern

```
KPI Framework -> C-level decomposes KPIs -> Teams execute
  -> CoS reads board every 4h -> Sync to founder
    -> Founder reviews + gives instructions
      -> Agent processes Approve/Rework/Question -> Teams continue
        -> Next sync shows results
```

### Sync Report Format

The Chief of Staff produces a structured report with:

- Department-by-department sections: completed, in progress, blocked, queued
- A "Needs Your Review" section listing items needing founder input
- Escalations since last sync
- KPI pulse / overall trajectory

### Founder Interaction (Approve / Rework / Question)

Each item in "Needs Your Review" has three possible responses:

| Response | What the agent does |
|----------|---------------------|
| "Approve [task]" | `kanban_complete` with approval summary (or `kanban_unblock` if blocked pending sign-off) |
| "Return [task] for rework: [reason]" | Adds comment with rework instructions, blocks or reassigns task with feedback |
| "Question about [task]: [question]" | Adds the question as a comment on the task, flagged for the assignee |

The closed loop:

```
KPI Framework -> C-level decomposition -> Team execution
  -> CoS sync presentation -> Founder: "Approve X, return Y for rework"
    -> Agent processes -> Teams continue -> Next sync shows results
```

Between-sync monitoring catches exceptions that can't wait 4 hours
(PMO every 30 min, Review Router every 5 min, escalations via Telegram).

## Autonomous Company Mode (Escalation-Driven)

The default kanban model is **pull-based** — the human (or an orchestrator profile) creates tasks, and agents claim them. This works great for directed work but puts the human in the loop as the task-creator.

**Autonomous Company Mode** flips this: each profile wakes itself up, inspects the board, decides what to do next, and only escalates to the human when something genuinely requires their judgment. The human becomes a **decision-maker and exception handler**, not a task dispatcher.

### When to use

- You want agents to self-organize and run continuously
- You trust the agents to make decisions within their domain
- You have a founder/CEO who wants to focus on strategic decisions, not daily task management
- You have a Chief of Staff or equivalent sentry role that monitors for drift
- You've set up a notification channel (Telegram, Discord, Slack) so escalation messages reach you asynchronously

### When NOT to use

- You're actively building the first version and need tight control over task sequencing
- The agents' SOUL.md files are still generic/untested and might produce wild decisions
- You haven't set up an escalation channel yet — without one, agents will just block tasks and you won't know

### The three-tier escalation framework (with optional COO triage layer)

Every profile's SOUL.md needs an explicit **Escalation Protocol** section that classifies all situations into three tiers:

| Tier | Color | Behaviour | Examples |
|------|-------|-----------|---------|
| **Green** | ✅ Decide autonomously | Do it. No human needed. Report in next standup. | Standard implementation, research, code review, data analysis, content creation, routine documentation |
| **Yellow** | 🟡 Escalate (but keep working) | Send a Telegram message to the founder with context and your recommended path. Continue with other work in parallel. Don't block on this. | Team disagreement that can't self-resolve, new opportunity that needs direction, external dependency (domain, vendor, third-party) that's taking longer than expected, team member not producing output |
| **Red** | 🚨 Stop and escalate | Block what you're doing, send Telegram alert to founder. This requires a human decision before proceeding. Do NOT default-proceed. | Credits exhausted / API down, critical business-model decision (pricing, legal structure, pivot), security vulnerability in production, compliance/regulatory question, blocker that would stall the team for 4+ hours, contradictory instructions from different team members |

**Adding a COO triage layer:** As the team grows past ~10 profiles, consider inserting a COO as the first line of escalation. The COO owns the Triage layer — all Yellow and some Red items go to COO first. Only items the COO can't resolve (strategic pivots, pricing, compliance) reach the founder. This prevents founder notification fatigue while keeping the escalation safety net intact. See `references/coo-team-expansion.md` for the COO escalation protocol template.

**How to embed this in SOUL.md:**

```markdown
## Escalation Protocol
You operate autonomously. You do NOT ask the founder for permission on routine work.

✅ **Green (decide yourself):**
- Implementation decisions within the agreed architecture
- Standard code reviews, documentation, testing
- Research and analysis
- Data work and reporting
- Marketing content creation

🟡 **Yellow (escalate but keep working):**
- A disagreement with another agent profile that you can't resolve
- An opportunity that needs strategic direction before committing resources
- An external dependency (third-party, vendor, domain registrar) blocking progress
- Send: "YELLOW: <team> — <one-line context>" via messaging tool. Keep working in parallel.

🚨 **Red (stop and escalate):**
- API key exhausted, credits depleted, provider down
- A decision that changes the business model, pricing, or distribution channel
- Security vulnerability found in production or a compliance risk
- A blocker that would stall the team for more than 4 hours without progress
- Conflicting instructions from different team members
- Send: "RED: <role> — <situation>" via messaging tool. Block your task. Await founder response.
```

### Setting up Telegram as the escalation channel

1. **Configure Telegram gateway** — run `hermes gateway setup` and select Telegram. You'll need a bot token from [@BotFather](https://t.me/BotFather) on Telegram. Also set your Telegram user ID in `TELEGRAM_ALLOWED_USERS` in `~/.hermes/.env`:

   ```
   TELEGRAM_BOT_TOKEN=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
   TELEGRAM_ALLOWED_USERS=123456789
   ```

   After setup, restart the gateway: `hermes gateway restart`

2. **Enable the `messaging` toolset** on profiles that should send escalation messages. Without this tool, agents can't send Telegram pings:

   ```bash
   hermes tools enable messaging --profile ceo
   hermes tools enable messaging --profile cto
   # etc. — any profile that might need to escalate
   ```

   The `messaging` toolset provides a `send_message` function. Worker profiles that receive dispatched kanban tasks need it in their config.yaml:

   ```yaml
   # ~/.hermes/profiles/<name>/config.yaml
   agent:
     disabled_toolsets:
       - terminal
       - browser
       # Do NOT include 'messaging' here if you want escalation
       # Do NOT include 'kanban' here — dispatched workers need it
   ```

3. **Configure `allowed_chats` in the Telegram section** of `~/.hermes/config.yaml` — set it to the chat ID of your Telegram DM with the bot, or a group chat where you want escalation messages:

   ```yaml
   telegram:
     reactions: false
     allowed_chats: '123456789'  # your Telegram user ID
     channel_prompts: {}
   ```

4. **Test the channel** — from any session with `messaging` enabled:
   ```
   Send a test message via the send_message tool to Telegram
   ```

### Cron-based self-starters

To make agents proactive rather than waiting for kanban tasks, give each role a periodic cron job that wakes them up to check the board and self-direct. There is a ready-to-use daily standup script at `scripts/daily-standup.sh` (no-agent mode, delivers formatted board summary to Telegram).

#### Quiet Hours / Notification Time Windows

By default, `every N m` schedules run continuously — a `every 240m` (every 4h) job fires at 00:00, 04:00, 08:00, 12:00, 16:00, 20:00. If you're in a timezone where you sleep (e.g. SAST, UTC+2), the 00:00 and 04:00 runs deliver Telegram notifications in the middle of the night.

**Fix:** use explicit cron syntax instead of `every N m` to constrain delivery to waking hours (e.g. 8am–10pm):

| `every N m` (noisy) | Cron replacement (quiet) | Effect |
|--|--|--|
| `every 240m` | `29 8,12,16,20 * * *` | Runs at 08:29, 12:29, 16:29, 20:29 — all within waking hours |
| `every 1440m` (CEO/Standup) | `0 9 * * *` or `25 9 * * *` | Runs once at specified morning hour only |

Cron hour values are the **system timezone** (Hermes cron displays `next_run_at` with UTC offset — e.g. `+02:00` for SAST — so you can verify). Use `hermes cron edit <job_id>` to change the schedule field.

**Pitfalls:**
- A Chief of Staff on `every 240m` that no one thought about will Telegram the founder at 2am. Always audit cron schedules after creation, especially for roles that deliver to Telegram.
- Standup jobs should fire in the **morning** (first thing), not evening — a daily standup that runs at 18:00 misses the point of a standup. Prefer 09:00–10:00 so the founder sees a fresh board summary at the start of the day.
- If you use both a Chief of Staff (every 4h) and a CEO (daily) and a standup (daily), stagger them so they don't fire simultaneously and flood the founder. E.g. Chief of Staff at `:29`, Standup at `:00`, CEO at `:25` of different hours.

```bash
# Chief of Staff — monitors board hourly, flags stuck tasks
hermes cron create "every 4 hours" \
  --prompt "Check the kanban board. Are any tasks blocked or stuck? \
            Has any task been in 'ready' for more than 2 hours without being claimed? \
            Are there dependencies that should be created? \
            Flag anything unusual to the founder via Telegram if needed. \
            You are a sentry — scan proactively, don't wait to be asked." \
  --skills "kanban-worker,multi-agent-team,hermes-agent" \
  --profile business-coach \
  --deliver telegram

# CEO — daily strategic pulse
hermes cron create "every 12 hours" \
  --prompt "Review the kanban board and recent task summaries. \
            Is the team making progress toward the current milestone? \
            Are there strategic decisions that need to be made? \
            Are any team members producing low-quality output? \
            Create follow-up tasks if needed. Escalate red/yellow issues to the founder." \
  --skills "kanban-worker,multi-agent-team" \
  --profile ceo \
  --deliver telegram

# CTO — daily tech pulse
hermes cron create "every 12 hours" \
  --prompt "Review the kanban board for technical tasks. \
            Are there architecture decisions pending? \
            Are there code review blockers? \
            Create technical tasks if the board is empty of engineering work. \
            Escalate technical blockers to the founder." \
  --skills "kanban-worker,multi-agent-team" \
  --profile cto \
  --deliver telegram

# Daily standup summary (lightweight) — delivered to founder on Telegram
hermes cron create "every 24 hours" \
  --prompt "Summarise the current state of the kanban board for the founder. \
            List: running tasks, blocked tasks, completed tasks in the last 24h, \
            any red/yellow escalations, and one sentence per role about progress. \
            Keep it brief — this is a standup, not a report." \
  --skills "kanban-worker,hermes-agent" \
  --profile ceo \
  --deliver telegram
```

**Cron delivery options:** Use `--deliver telegram` (requires Telegram configured) or `--deliver cli` (visible next time the founder chats with Hermes CLI) or `--deliver none` (just executes, no output).

**Cron pattern note:** The cron jobs are not the agents themselves — they're wake-up calls. The cron agent inspects the board, decides what needs doing, creates kanban tasks if needed, and escalates red/yellow items. The actual work is still done by dispatched kanban workers. This keeps the separation of concerns: cron = strategic pulse + board hygiene, kanban = execution.

### SOUL.md changes for autonomy

Every profile's "How You Work" section needs to change from "check with the founder" to "decide within your domain, escalate defined signals":

**Before (pull-based, human-in-loop):**
```
## How You Work
1. Use the Kanban board to create strategic tasks
2. CPO picks up product tasks, CTO picks up technical, CMO picks up marketing
3. Review their output and provide direction
4. Flag major decisions for the founder's approval
```

**After (autonomous, escalation-driven):**
```
## How You Work
1. Wake up via cron (self-scheduled), or pick up tasks from the kanban board
2. Review the board and team outputs to decide what needs doing
3. Create tasks for your team or execute work yourself
4. Escalate red/yellow issues to the founder via Telegram — otherwise proceed autonomously
5. Leave a brief summary on completed tasks so the board tells the story
```

### The sentry pattern (Chief of Staff role generalized)

The Chief of Staff SOUL.md already has a "North Star Guardian" section that proactively scans for strategic drift. This pattern is generalizable to any role that needs to watch over a domain without being asked:

```markdown
## Proactive Scanning (Sentry Mode)
You do NOT wait for kanban tasks to be created for you. You:

1. **Scan the board proactively** — check the kanban board at the start of every run
2. **Flag drift before it compounds** — if an agent output introduces something outside scope, flag it immediately. Don't wait for a review meeting.
3. **Escalate patterns, not incidents** — a single late task is normal. A role that misses three consecutive deadlines is a pattern.
4. **Maintain a pulse check** — after your periodic scan, write one paragraph: "Is the team still building toward the right goal? What slipped?"
5. **Call out silence** — if a role hasn't produced output in longer than expected, raise it. Silence is often the loudest signal.
```

This sentry pattern works best for roles that report directly to the founder (Chief of Staff, McKinsey Consultant) rather than roles in the kanban hierarchy, because they have no stake in any one function's success and can remain objective.

**Extend the sentry scan to cover three failure modes, not just "blocked >4h":**

| Failure mode | What to look for | Sentry action |
|---|---|---|
| **Blocked without progress** | Tasks `status: blocked` with no unblock event for >4h | Check if a fix/review task exists; if not, create it. Escalate as yellow if >8h. |
| **Crashed / gave_up** | Tasks whose last run has `outcome: crashed`, `gave_up`, or `protocol_violation` | **First: check if the crash is systemic.** If multiple profiles across different roles all crashed in the same time window with the same pattern (`protocol_violation` or `pid not alive`), the root cause is almost certainly a provider/routing issue — check `grep "Auxiliary auto-detect" ~/.hermes/profiles/*/logs/agent.log` for unexpected provider resolution. Fix the provider config first, then batch-unblock all tasks at once: `hermes kanban list --status blocked | grep ⊘ | sed 's/^[^ ]* //' | awk '{print $1}' | xargs hermes kanban unblock`. If only one profile is affected, reclaim the task, check prior run summaries to understand why. If timeout, note the limit. Assign back to the original profile or escalate to COO if pattern repeats. |
| **Stale running** | Tasks `status: running` with last event (heartbeat or tool call) >4h ago | The worker may be stuck or dead. Kill via reclaim. Check agent log for stream drops or OOM. Reassign or escalate. |

Add these three checks to the Chief of Staff's board-scan prompt alongside the existing blocked-task review. Without crash/gave_up monitoring, workers that time out or crash silently produce zero notification — the founder doesn't know until they manually check the board.

**Monitoring cadence philosophy — fast cycles preferred.** A monitoring agent that scans every 4 hours creates a 4-hour blind spot where failures compound silently. The preferred pattern is high-frequency scanning (every 15–30 min during waking hours) so that:
- Gave_up tasks are caught within minutes, not hours
- The retry death spiral is interrupted before it compounds across multiple unblock→timeout cycles
- Escalation tasks appear on the board fast enough that the COO or founder can act same-day

When setting up sentry crons, prefer short-interval schedules with hour constraints (`*/29 8-21 * * *` for CoS at 29-min intervals, `0,30 8-21 * * *` for PMO every 30 min) over multi-hour pulses. The LLM cost is minimal (a few API calls per scan) and the responsiveness gain is substantial. The only roles that should run at multi-hour intervals are deep-analysis roles (COO operational review, CEO strategy check) that need broad context across many tasks — not the sentries whose job is to catch failures early.

### PMO board housekeeping

As the board grows, completed tasks accumulate. Assign the PMO (or whichever role owns board health) the responsibility to periodically:

1. **Archive completed tasks** — `hermes kanban archive <task_id>` removes them from the active board view
2. **Garbage collect** — `hermes kanban gc` cleans up workspaces, event logs, and stale data from archived tasks

This should be in the PMO's SOUL.md under "Your Role" as a standard responsibility: "Housekeep the board — archive completed tasks and run kanban gc to clean up workspaces once tasks are resolved."

Without this, the board fills with hundreds of completed tasks, making it hard to spot active and blocked work. A good cadence is to housekeep after every phase gate or weekly, whichever comes first.

### Failure Response Protocol — Systemic Diagnosis Before Firefighting

When the founder points at stuck tasks and says "fix it", the correct first action is **systemic root cause analysis**, not individual task recovery. Patching tasks one-by-one without understanding the pattern guarantees the same failures recur.

**The protocol when tasks are stuck:**

1. **Read existing audits first** — check `~/.hermes/plans/` for PMO and COO audit reports. These are already written and likely contain the root cause you're about to rediscover. The COO's operational audit and PMO's orchestration audit identify routing gaps, timeout issues, and missing monitoring that cause most stuck-task patterns.

2. **Categorize the failure pattern** — every stuck task belongs to one of these classes:

   | Pattern | Symptom | Systemic fix (not firefighting) |
   |---|---|---|
   | **Review gate gap** | Tech Lead blocked a task with `changes-required` but no fix task exists for Engineer. | Fix the review-router to create fix tasks, or update Tech Lead SOUL.md to always create fix tasks when blocking with issues. |
   | **Timeout / budget exhausted** | Task timed out at `limit_seconds: 900` (15 min) or hit `max_turns`. | Increase `gateway_timeout` in the profile config. Writing tests with cargo build → fix cycles needs 30-60 min, not 15. |
   | **Protocol violation** | Worker exited with rc=0 without calling `kanban_complete` or `kanban_block`. | **First: check if ALL workers are failing with the same pattern.** If yes, it's a provider/routing issue, not a skill issue. Check the profile's agent log: `grep "Auxiliary auto-detect" ~/.hermes/profiles/<role>/logs/agent.log` — does it show the expected provider? If the routed provider is different from the configured provider (e.g. config says `deepseek` but auto-detect says `minimax`), comment out the unwanted provider API keys in the profile's `.env` (see "Provider auto-detect via .env API keys" pitfall). If only one profile is affected, check if the worker loaded all required skills — this is the [SILENT] problem (worker had nothing to say and shut down). Add CRITICAL RULE to the task body or prompt. |
   | **Crashed / gave_up** | Task exhausted `failure_limit: 2` and is now `gave_up`. | The sentry (CoS) should have caught this. Increase failure_limit or fix the root cause (timeout, skill loading, provider issue). |

3. **Action the existing audit recommendations** — PMO and COO reports contain P0/P1/P2 priorities. Each P0 item that hasn't been actioned is a root cause of current stuck tasks. Convert audit findings to kanban tasks if they're not already on the board.

4. **Only then, recover individual tasks** — after the systemic fix is identified or queued, reclaim and re-assign the stuck tasks. By this point the fix is in place and the retry won't re-fail the same way.

   **Mass unblock after systemic fix:** When the root cause was provider-wide (e.g. minimax key clash affecting all profiles), unblock ALL blocked tasks at once rather than one-by-one:
   ```bash
   hermes kanban list --status blocked 2>&1 | grep "⊘" | sed 's/^[^ ]* //' | awk '{print $1}' | tr '\n' ' ' | xargs hermes kanban unblock
   ```
   This gets the whole team moving in one command instead of batting cleanup task-by-task.

**Anti-pattern:** Creating individual fix-TODO items ("Fix PDF watermarking", "Reclaim sub-task B", "Reclaim sub-task C") without checking whether the PMO or COO already diagnosed the root cause. This wastes the founder's time and duplicates diagnostic work the operations roles already did.

See `references/systemic-failure-response.md` for a checklist based on the PMO/COO audit findings from this session.

- **Over-escalation** — agents that Telegram-ping the founder for every minor decision defeat the purpose. Be explicit in the SOUL.md about what counts as red/yellow. If an agent escalates too often, tighten the criteria.
- **Under-escalation** — agents that silently barrel ahead into a dead end without pinging the founder. The sentry pattern (Chief of Staff) catches this, but better to prevent it. If an agent doesn't escalate when it should, add the specific situation to its red/yellow list.
- **Cron jobs creating duplicate tasks** — if two cron jobs run and both decide to create the same task, the board fills with duplicates. Each cron's prompt should include: "Before creating a new task, check if a similar task already exists on the board. If one does, update it or block it instead of creating another."
- **Board never empties** — autonomous agents love creating tasks. Without a completion signal or phase gate, the board grows unbounded. Set a goal or milestone that, when reached, triggers a founder review before the next phase.
- **Founder gets Telegram fatigue** — if you're getting 20 Telegram messages a day from agents, you've set the escalation bar too low. Only red items should interrupt your day. Yellow can batch in a daily digest. Green never pings.
- **Missing `messaging` toolset** — agents with escalation in their SOUL.md but no `messaging` toolset will try to escalate and fail silently. Verify every profile that has the escalation protocol also has the tool.

**See also:** `references/autonomous-escalation-design.md` — a concrete implementation with per-profile escalation tables and cron schedule design.

## Configuring `max_turns` Per Role

The default `max_turns: 60` in cloned profiles is fine for strategy/research roles (CEO, CPO, CMO, Legal, Finance). Build roles need more:

| Role | Recommended `max_turns` | Why |
|------|------------------------|-----|
| Strategist/Researcher (CEO, CPO, CMO, Legal, Finance) | 60 | Research + writing docs, few iterative loops |
| Architect/Discourse (CTO, Tech Lead) | 120 | Multiple reads, ADR cycles, code review passes |
| Implementer (Engineer) | 300 | `cargo build` → fix errors → rebuild → test loops, file creation, multiple compile-test-compile cycles |

**`gateway_timeout` matters too.** `max_turns` controls API-call iterations; `gateway_timeout` controls wall-clock runtime before the dispatcher kills the worker. For compiled-language test-writing tasks (Rust with cargo build → fix cycles), 15 minutes (`gateway_timeout_warning: 900`) is too short — the worker gets killed mid-build. Increase both:

```yaml
# ~/.hermes/profiles/engineer/config.yaml
agent:
  gateway_timeout: 3600        # 60 min wall clock (was 1800) — Rust compile loops need this\n  gateway_timeout_warning: 1800  # 30 min warning threshold (was 900)\n  max_turns: 300
```

Symptoms of timeout too short: task events show `timed_out` with `limit_seconds: 900` and `elapsed_seconds: 901+`. Increase by 2x and reclaim the task.

Edit `~/.hermes/profiles/<role>/config.yaml`:

```yaml
agent:
  max_turns: 150
```

The change applies to NEW runs. If a task is already running when you change the config, you must reclaim and let the dispatcher re-spawn it:

```bash
hermes kanban reclaim <task_id>
# Wait for next 60-second dispatch cycle, or just let it pick up naturally
```

### Turn-Limit Recovery

When a task hits its turn limit:
1. It gets `blocked` with "Iteration budget reached"
2. `hermes kanban log <task_id>` shows where it stopped
3. Increase `max_turns` in the profile's config.yaml
4. `hermes kanban unblock <task_id>` to let it retry
5. The agent picks up where it left off (files on disk are preserved)

If the agent was in mid-file-write when it hit the limit, check `hermes kanban log` for `⚠ File-mutation verifier` warnings showing which files were NOT written, and verify manually.

## Task Reassignment

When a role's responsibilities change mid-stream, tasks need to be reassigned. The workflow:

1. **Reclaim** the task from the current runner: `hermes kanban reclaim <task_id>`
2. **Reassign** to the new role: `hermes kanban reassign <task_id> <new_role>`
3. The dispatcher picks it up on the next cycle for the new role

Use this when:
- A role was split (CTO → CTO + Engineer) and tasks need to move to the implementer
- A role was absorbed into another
- The wrong profile was assigned at creation time

**Common pitfall:** `hermes kanban reassign` fails with "still running" if you don't reclaim first. Always reclaim before reassign.

**Self-assignment model** (recommended for autonomy):
- CEO creates broad strategic initiatives on the board
- Each role monitors the board and picks up relevant tasks
- Roles report back via `kanban_complete()` with summaries
- CEO reviews output and creates follow-up tasks as needed

**Directed assignment model** (for tighter control):
- CEO creates tasks with `--assignee <role>` to direct specific work
- The dispatcher only lets the assigned profile claim it

### Pitfalls

- **Implementation tasks assigned to Tech Lead instead of Engineer** — the Tech Lead's SOUL.md explicitly forbids writing production code, but task creators (CTO, orchestrator, or manual `kanban create` commands) sometimes assign build/implementation tasks to `tech-lead` instead of `engineer`. The Tech Lead dutifully picks up these tasks and writes code, violating the role boundary. **Fix:** ALL implementation tasks (build, code, fix compile errors, create services/handlers/repos) must have `--assignee engineer`. Tech Lead gets only review, architecture discourse, and ADR enforcement tasks. The Engineer's SOUL.md should include a check: "If a task you receive was originally assigned to tech-lead, flag it." The Tech Lead's "What You Do NOT Do" section (already present) will cause them to refuse misassigned tasks on sight — if a Tech Lead picks up a build task, its own SOUL.md should tell it to block the task with `reason: "Misassigned — implementation tasks belong to Engineer, not Tech Lead."` This is a **task creation discipline** issue, not a SOUL.md issue. See `references/task-assignment-boundary-enforcement.md` for the full recovery workflow and classification table.

- **No gateway running** — tasks stay in `ready` forever. Always start the gateway.
- **Missing API keys** — cloned profiles may not inherit env vars. Run `ceo setup` or set `HERMES_*` env vars.
- **Over-restrictive toolsets — `kanban` is required for any dispatched worker** — if a profile has `kanban` in `disabled_toolsets`, the dispatcher will spawn it, but the agent cannot call `kanban_complete()` or `kanban_block()` to report back. The agent exits cleanly (rc=0) without completing the task, and the dispatcher flags it as a **protocol violation** (`"worker exited cleanly without calling kanban_complete or kanban_block"`). The task is then blocked with `gave_up` status. To fix: remove `kanban` from `disabled_toolsets` for ALL profiles that will receive kanban tasks (CEO, CPO, CTO, CMO — any dispatched profile). Then restart the gateway and unblock the failed tasks.
- **Over-restrictive toolsets — file access for research AND review roles** — if a task body says "Record findings in ~/path/to/file.md" but the assigned profile has `file` disabled, the agent cannot write the deliverable. Check that every profile with a task body that references writing artifacts has `file` enabled. Also: **reviewers need `file` to read outputs.** If a CEO/review task asks the agent to "read all docs in `docs/`" but the CEO's config has `file` disabled, the agent cannot open any files and will either hallucinate content or ask the user to read them aloud. A good heuristic: if a profile receives kanban tasks that mention reading or writing files, enable `file`. The only exception is a strictly conversational orchestrator that never touches filesystem artifacts.
- **SOUL.md too long** — the personality loads every turn. Keep it under 500 words. Long SOUL files waste context.
- **Same model for all** — works fine for MVP. For production, consider cheaper/faster models for heavy-tool-use roles (CTO) and smarter models for strategy roles (CEO).
- **Stale provider/model in profile configs** — each profile's `config.yaml` is fully independent from the main config. If you set `provider: minimax` in a profile at clone time and later switch the main config to `provider: deepseek`, that profile **keeps the old provider** and will be dispatched with it. There is no cascade. The symptom: the main agent works fine, but a dispatched worker silently uses a different model/provider and behaves differently (or crashes). **Always set BOTH `provider:` and `model:` explicitly in every profile's config.yaml** so each profile has an unambiguous, self-contained provider+model pair. This also prevents the provider's default model from being selected when only `provider:` is set without a `model:` override. When auditing a team after changing the default provider, run `grep -l 'provider:' ~/.hermes/profiles/*/config.yaml` to find profiles with stale overrides.

- **Provider auto-detect via .env API keys (SILENT OVERRIDE)** — even when a profile's `config.yaml` says `provider: deepseek` and sets `base_url: https://api.deepseek.com`, Hermes' auxiliary auto-detect can resolve the model through a **different provider** if that provider's API key is present in the profile's `.env`. The auto-detect scans which provider API keys are available and picks the first match. If `MINIMAX_API_KEY=sk-...` is in the `.env`, `deepseek-v4-flash` may be routed through minimax (`api.minimax.io/anthropic`) instead of deepseek. The config is correct but the runtime resolution is wrong. **Symptom:** the default profile works fine with `provider=deepseek`, but a cloned profile with minimax in its `.env` silently routes through minimax and hits rate limits/min-plan constraints. **Diagnosis:** check the profile's agent log: `grep "Auxiliary auto-detect" ~/.hermes/profiles/<name>/logs/agent.log` shows which provider was auto-detected vs what was configured. Compare with the main profile's log: `grep "provider=" ~/.hermes/logs/agent.log | tail -5` shows `provider=deepseek base_url=...` for a healthy config. **Fix:** comment out or remove minimax API keys from profiles that should use deepseek. The main `.env` should have only the API keys for the provider you actually want to use. If you need minimax keys elsewhere, scope them per-profile by only setting them in the profile's `.env` that should actually use minimax.

   Batch fix command:
   ```bash
   for p in ~/.hermes/profiles/*/; do
     if grep -q "^MINIMAX_API_KEY=" "$p.env" 2>/dev/null; then
       sed -i 's/^MINIMAX_API_KEY=/# MINIMAX_API_KEY=/' "$p.env"
     fi
   done
   ```
- **Gateways on all profiles** — only the default profile's gateway needs to run (it hosts the dispatcher). Other profiles don't need their own gateway.
- **Stale SOUL.md** — after a product strategy session where major decisions are made (tech stack, payment model, market positioning), update ALL profile SOUL.md files. A SOUL that says "tech stack TBD" or references a generic "TpT clone" causes agents to re-litigate settled questions and wastes context. The CTO's SOUL should reflect the actual chosen stack; the CPO's should reference the actual spec docs; the CMO's should reference the accepted GTM strategy.
- **CEO autonomously spawning CTO build tasks** — a common phase-gate mistake: the CEO's review playbook says "unblock the CTO if approved." When the founder gives conditional approval (e.g. "R25 is fine, open source model, legal later"), the CEO interprets this as the build green light, creates a CTO build task with full scope, and the dispatcher immediately spawns it — even though the founder intended to give more technical inputs first. **Fix:** the CEO's SOUL.md playbook should say "present findings to the founder and await explicit instruction" rather than "unblock the CTO." The founder should be the one who unblocks the CTO task (or says "not yet"). The CTO's build task should be created by the CTO or the founder, not autonomously by the CEO as a side effect of completing the review.
- **Tech Lead never consulted** — when there's a Tech Lead (discourse partner) and the Engineer picks up a build task, the Engineer's SOUL.md must include a step to have their code reviewed by the Tech Lead before shipping. Without this step, the Engineer ships unreviewed code. **Fix:** add step to the Engineer's "How You Work" section: "After each step completes, block the task and flag it for Tech Lead review."
- **Turn limit hits mid-build** — default `max_turns: 60` is too low for build tasks that involve file creation + cargo build + fix cycles. The agent gets blocked with "Iteration budget reached" mid-file-write. **Fix:** set `max_turns: 150` for Engineer profiles, `max_turns: 120` for Tech Lead, keep 60 for strategy/research roles. See "Configuring `max_turns` Per Role" section above.
- **Role change without task reassignment** — if a role's responsibilities change mid-stream (e.g., CTO was building, now architects), their running tasks stay assigned to them. The dispatcher will keep spawning the old role for new runs. **Fix:** reclaim + reassign any running tasks to the new role immediately. See "Task Reassignment" section above.
- **Reporting line change without SOUL.md updates** — if you change who reports to whom (e.g., Engineer now reports to Tech Lead instead of CTO), you must update ALL three SOUL.md files: the new manager (Tech Lead — add "Your Team" section), the direct report (Engineer — change intro line to "on <manager>'s team"), and the skip-level (CTO — remove from direct reports, add note about the new chain). Also update memory with the new org structure. Without all three updates, the agents will have contradictory beliefs about who they report to and who manages whom.
- **`hermes kanban dispatch` does not spawn workers** — it only reclaims stale claims, promotes triaged tasks, and blocks crashed/time-out tasks. Actual worker spawning happens on the gateway's polling cycle (default 60s). If a task is "ready" but not yet "running", wait for the next cycle rather than running dispatch repeatedly. If it doesn't pick up after 2 cycles, the profile config may be wrong (missing API keys, disabled kanban toolset).
- **Dispatcher can't find profiles** — the dispatcher only discovers profiles at kanban init time. If you add profiles after init, you may need to restart the gateway.
- **`&` in kanban task descriptions** — `hermes kanban create "Task with A & B" --assignee cto` will fail because bash interprets `&` as a backgrounding operator. The terminal tool sees the `&` and rejects the command. **Fix:** use the word "and" instead of `&`, or escape it: `A and B` / `A \& B`. This applies to `--body`, `--tags`, and any other option that accepts multi-word strings with special characters.
- **External CLI delegation** — profiles cloned from default inherit the `claude-code`, `codex`, and `opencode` skills. These tell the agent to delegate work to an external CLI (Claude Code CLI, Codex CLI) instead of using its own tools. The Engineer should NOT have these — it should write code directly via `terminal` + `file`. Only the Tech Lead (reviewer) should keep them. If the Engineer has them, it will outsource coding to the external CLI, adding latency, consuming separate API credits, and introducing a second failure mode (external CLI hitting its own limits). **Fix:** remove these skills from all profiles except Tech Lead: `rm -rf ~/.hermes/profiles/<name>/skills/autonomous-ai-agents/{claude-code,codex,opencode}`. See the product overlay repo at `operations/team/yethu-execution-patterns.md` for the full story and recovery steps.

- **Skills and cron prompts authored locally instead of the framework repo** — when building the autonomous enterprise, reusable patterns (cron prompts, operating model docs, reference examples) should be written directly to the framework repo's `skills/<category>/<name>/` directory and committed, not to `~/.hermes/skills/`. The local skills directory is for product-specific one-offs. Configure `skills.external_dirs` in `config.yaml` to point to the framework repo's skills/ so Hermes loads them from the canonical source. Cron prompt templates belong in `<skill>/templates/prompts/` so anyone forking the repo gets the full operating model.

- **External CLI credits exhausted** — even on profiles where external CLI delegation is appropriate (Tech Lead using Claude Code for code review), the external CLI may run out of credits/usage. When this happens, the profile's dispatched task sits in `ready` or `todo` because the agent's skill instructs it to use the external CLI, but the CLI refuses work. The task is stuck until credits refresh. **Recovery:** the human or another profile with direct terminal/file access can claim the task via `hermes kanban reassign <task_id> <alternative_profile>` and complete the work using standard tools. The re-assignment is temporary — when the external CLI's credits refresh, tasks can flow back. To prevent recurrence, consider giving the external-CLI-reliant profile a fallback path in its SOUL.md: "If Claude Code reports exhausted credits, fall back to direct code review using file + terminal tools instead." This requires the profile to have `terminal` enabled (which most discourse/review profiles don't by default — enable it only if you accept the fallback pattern).

- `hermes-agent` skill — full CLI reference for profiles, kanban, config
- `kanban-orchestrator` skill — deep dive on kanban task decomposition and routing
- `kanban-worker` skill — how workers claim tasks and report back
