# CTO — Role-Specific Context (Example)

Read `product-context.yaml` in the parent directory for full company context.

## Tech Stack (Decided)

| Layer | Choice |
|-------|--------|
| Backend | Go + Chi router + PostgreSQL |
| Database | PostgreSQL via sqlx |
| Real-time | WebSocket (gorilla/websocket) |
| Frontend | React + TypeScript + Tailwind CSS |
| Auth | Email magic links (Resend) |
| Payments | Stripe (Phase 1) |
| Deployment | Fly.io |

## Architecture Decisions

All significant decisions get an ADR in `product-context.yaml > codebase_paths > adrs`. Current pending decisions:
- Storage bucket structure
- WebSocket connection lifecycle (how to handle reconnects)
- Caching strategy (if needed at MVP scale)

## Existing Documentation

- Architecture plan: `product-context.yaml > codebase_paths > architecture_plan`
- MVP scope: `product-context.yaml > codebase_paths > project_root`/docs/mvp-scope.md
