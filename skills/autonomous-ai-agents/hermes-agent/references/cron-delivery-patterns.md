# Cron Delivery Patterns — Hardcoded Platform IDs vs `origin`

Cron jobs can deliver to specific platform endpoints or let the system resolve delivery automatically.

## Delivery options

| Value | Behavior | When to use |
|-------|----------|-------------|
| `origin` | Delivers to the platform that created the cron job (CLI → Telegram, gateway → same gateway chat) | **Default for all user-facing crons** — auto-adapts if you switch platforms |
| `telegram:<chat_id>` | Delivers to a specific Telegram chat (group, channel, or DM) | Legacy/external cron jobs whose recipient doesn't match the origin platform |
| `local` | Stores the response in the local log only — no external delivery | Monitors and housekeeping jobs (PMO Board Monitor, GC) |
| `discord:<channel_id>` | Delivers to a specific Discord channel | Multi-platform setups |

## Why standardize on `origin`

Switching from hardcoded `telegram:<your-chat-id>` to `origin` is a one-time change that future-proofs delivery:

- **Platform migration** — if you ever switch from Telegram to Discord/Slack/Matrix, crons with hardcoded `telegram:` IDs go dark. `origin` follows whatever platform you're using at fire time.
- **Gateway restart** — after a gateway restart or re-auth, hardcoded `telegram:` IDs can error if the platform connection renegotiates. `origin` resolves fresh each run.
- **Multi-machine** — if your cron setup runs from a CI/CD pipeline or a different machine, `origin` resolves to the session that created the cron, wherever that originated.

## Migrating crons to origin

```bash
# For each cron, update delivery
hermes cron edit <job_id> --deliver origin
```

Target crons that deliver to a user (Chief of Staff board monitor, CEO strategy check, domain checks). Keep housekeeping crons (PMO board monitor, kanban GC) on `local` — they generate logs, not notifications.

**Don't migrate:** Crons that intentionally deliver to a different platform or recipient than the creator (e.g., a cron that sends weekly reports to a public channel while your CLI session is a private DM).

## Check current delivery settings

```bash
hermes cron list | grep -E 'deliver|telegram|discord|slack'
```