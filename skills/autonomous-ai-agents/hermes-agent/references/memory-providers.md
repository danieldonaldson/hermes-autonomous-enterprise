# Memory Providers — Comparison & Setup

## Architecture

Hermes has a two-layer memory system:

1. **Built-in** (always active) — `MEMORY.md` + `USER.md` files, SQLite-backed, injected into system prompt. Max ~2,200 chars per file.
2. **External provider** (optional, one at a time) — pluggable plugin that augments the built-in with semantic retrieval, vector search, dialectic reasoning, etc.

Built-in runs alongside whichever external provider is active.

## Provider Comparison

| Provider | Auth | Latency | Best for |
|----------|------|---------|----------|
| **Built-in** | None | Instant | Simple cross-session context, no dependencies |
| **Holographic** | None (local) | Low | Zero-infrastructure vector memory |
- **Honcho** — API key or self-host | Medium | Dialectic reasoning, multi-peer user modeling, peer card API for structured facts — see `references/honcho-peer-card-seeding.md` |
| **Mem0** | API key or self-host | Medium | Popular third-party memory layer |
| **OpenViking** | API key or self-host | Medium | Alternative vector backend |
| **Hindsight** | API key or local | Medium | Retrospective session re-indexing |
| **RetainDB** | API key or self-host | Medium | Persistent DB backend |
| **ByteRover** | API key | Medium | Dedicated memory service |
| **Supermemory** | API key | Medium | Alternative managed service |

## Built-in Memory Limits

- `memory_char_limit` (default: 2200) — MEMORY.md notes
- `user_char_limit` (default: 1375) — USER.md profile
- When full, oldest entries are silently truncated from the top
- Flush cadence: `flush_min_turns` (default: 6) — writes to file every N turns
- Nudge interval: `nudge_interval` (default: 10) — agent is reminded of memory tools

## CLI Commands

```bash
hermes memory               # list available providers
hermes memory setup         # interactive provider selection + config
hermes memory status        # show current provider and config
hermes memory off           # disable external provider (back to built-in only)
hermes memory reset         # erase all built-in memory
```

## Honcho Self-Hosting (Detailed)

### Docker (recommended)

```bash
git clone https://github.com/plastic-labs/honcho.git
cd honcho
cp docker-compose.yml.example docker-compose.yml
cp .env.template .env
```

Required `.env` variables:
- `DB_CONNECTION_URI` — Postgres with pgvector (`postgresql+psycopg://...`)
- At least one LLM key:
  - `LLM_GEMINI_API_KEY` — used for deriver/summary/dialectic (minimal/low) by default
  - `LLM_ANTHROPIC_API_KEY` — used for dialectic medium/high/max and dreaming
  - `LLM_OPENAI_API_KEY` — used for embeddings when `EMBED_MESSAGES=true`

Optional (for local dev):
- `AUTH_USE_AUTH=false` — disable JWT auth
- `SENTRY_ENABLED=false` — disable Sentry

```bash
docker compose up
```

Server runs at `http://localhost:8000`.

**Using an alternative LLM provider** (DeepSeek, OpenRouter, Ollama, etc.):
→ See `references/honcho-custom-llm-provider.md` — full guide for configuring
Honcho with any OpenAI-compatible endpoint, including model overrides for
all subsystems (deriver, dialectic levels, summary, embeddings) and a
docker-compose.yml with the deriver service.

### Local Dev (no Docker)

```bash
git clone https://github.com/plastic-labs/honcho.git
cd honcho
uv sync
# Run Postgres separately (e.g. docker compose up -d database)
cp .env.template .env
uv run alembic upgrade head

# Terminal 1: API server
uv run fastapi dev src/main.py

# Terminal 2: Background worker (deriver)
uv run python -m src.deriver
```

### Connect Hermes to Self-Hosted Honcho

```bash
hermes honcho setup
# Select "local" → enter base URL: http://localhost:8000
```

Or manual:
```yaml
# config.yaml
memory:
  provider: honcho
```

Create `~/.hermes/honcho.json`:
```json
{
  "baseUrl": "http://localhost:8000",
  "workspace": "default",
  "peerName": "daniel",
  "aiPeer": "hermes",
  "recallMode": "hybrid",
  "writeFrequency": "async",
  "saveMessages": true,
  "sessionStrategy": "per-directory"
}
```

Verify: `hermes honcho status`

## Holographic — Local-Only Option

Runs fully local — no API keys, no cloud dependencies, no Postgres. Uses associative vector memory. Good for low-friction memory improvement.

Select via `hermes memory setup` → pick "holographic".

## Pitfalls

- **Built-in truncation** — at 95%+ capacity, old memories silently drop. Monitor `hermes memory status` periodically.
- **External provider downtime** — if the external service is unreachable, falls back to built-in. No data loss, but the richer context disappears.
- **Multiple profiles** — each profile has its own memory scope. With Honcho, each profile gets its own AI peer.
- **Only one external provider** — you cannot run Honcho + Mem0 simultaneously. Built-in always runs alongside.
- **`hermes honcho` subcommand only appears** when `memory.provider: honcho` is set — it's not a standalone command.
- **Memory changes need `/reset`** — provider changes take effect on next session start.
