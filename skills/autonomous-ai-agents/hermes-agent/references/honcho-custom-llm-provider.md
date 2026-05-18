# Honcho with Custom / OpenAI-Compatible LLM Providers

Honcho's default config uses OpenAI, Gemini, and Anthropic for different
subsystems. But Honcho speaks the **OpenAI-compatible transport** — so any
provider that offers an OpenAI-compatible API (DeepSeek, OpenRouter,
Together, vLLM, Ollama, LiteLLM, Groq, etc.) works with a few config
overrides.

## Architecture Overview

Honcho runs as **two cooperating processes**:

| Process | Role |
|---------|------|
| **API server** (`src/main.py`) | FastAPI HTTP server. Handles chat requests, enqueues background work. Hosts the Dialectic agent inline. |
| **Deriver worker** (`python -m src.deriver`) | Background queue consumer. Runs the Deriver (memory formation), Summarizer, and Dreamer off the queue. |

Both need LLM access. The API server needs it for Dialectic (synchronous,
tool-using reasoning). The Deriver needs it for memory extraction
(background, batch-processed).

## Subsystems That Need LLM Configuration

| Subsystem | Env prefix | What it does | Default transport |
|-----------|-----------|--------------|-------------------|
| **Deriver** | `DERIVER_MODEL_CONFIG__` | Memory formation from messages | openai (gpt-5.4-mini) |
| **Dialectic** (5 levels) | `DIALECTIC_LEVELS__{level}__MODEL_CONFIG__` | Reasoning engine — answers queries about users | openai (gpt-5.4-mini) |
| **Summary** | `SUMMARY_MODEL_CONFIG__` | Session summaries | openai (gpt-5.4-mini) |
| **Dream** | `DREAM_DEDUCTION_MODEL_CONFIG__` / `DREAM_INDUCTION_MODEL_CONFIG__` | Advanced consolidation (optional) | openai (gpt-5.4-mini) |
| **Embeddings** | `EMBEDDING_MODEL_CONFIG__` | Vector embeddings for semantic search | openai (text-embedding-3-small) |

## Universal Config Pattern

Each subsystem uses a `MODEL_CONFIG` with the same structure:

```env
{SUBSYSTEM_PREFIX}_MODEL_CONFIG__TRANSPORT=openai            # Always "openai" for OpenAI-compatible APIs
{SUBSYSTEM_PREFIX}_MODEL_CONFIG__MODEL=your-model-name        # e.g. deepseek-v4-flash, openrouter/...
{SUBSYSTEM_PREFIX}_MODEL_CONFIG__OVERRIDES__BASE_URL=...      # e.g. https://api.deepseek.com
```

The `TRANSPORT=openai` means "use the OpenAI-compatible HTTP client".
The `OVERRIDES__BASE_URL` makes it point at your provider instead of
api.openai.com.

## Configuration File (.env)

### Minimal — override everything to one provider

```env
# API key (used by all subsystems with TRANSPORT=openai)
LLM_OPENAI_API_KEY=sk-your-deepseek-or-openrouter-key

# --- Deriver ---
DERIVER_MODEL_CONFIG__TRANSPORT=openai
DERIVER_MODEL_CONFIG__MODEL=deepseek-v4-flash
DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.deepseek.com
DERIVER_WORKERS=2

# --- Dialectic (all 5 reasoning levels) ---
DIALECTIC_LEVELS__minimal__MODEL_CONFIG__TRANSPORT=openai
DIALECTIC_LEVELS__minimal__MODEL_CONFIG__MODEL=deepseek-v4-flash
DIALECTIC_LEVELS__minimal__MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.deepseek.com
DIALECTIC_LEVELS__minimal__MAX_TOOL_ITERATIONS=1

DIALECTIC_LEVELS__low__MODEL_CONFIG__TRANSPORT=openai
DIALECTIC_LEVELS__low__MODEL_CONFIG__MODEL=deepseek-v4-flash
DIALECTIC_LEVELS__low__MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.deepseek.com
DIALECTIC_LEVELS__low__MAX_TOOL_ITERATIONS=3

DIALECTIC_LEVELS__medium__MODEL_CONFIG__TRANSPORT=openai
DIALECTIC_LEVELS__medium__MODEL_CONFIG__MODEL=deepseek-v4-flash
DIALECTIC_LEVELS__medium__MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.deepseek.com
DIALECTIC_LEVELS__medium__MAX_TOOL_ITERATIONS=5

DIALECTIC_LEVELS__high__MODEL_CONFIG__TRANSPORT=openai
DIALECTIC_LEVELS__high__MODEL_CONFIG__MODEL=deepseek-v4-flash
DIALECTIC_LEVELS__high__MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.deepseek.com
DIALECTIC_LEVELS__high__MAX_TOOL_ITERATIONS=8

DIALECTIC_LEVELS__max__MODEL_CONFIG__TRANSPORT=openai
DIALECTIC_LEVELS__max__MODEL_CONFIG__MODEL=deepseek-v4-flash
DIALECTIC_LEVELS__max__MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.deepseek.com
DIALECTIC_LEVELS__max__MAX_TOOL_ITERATIONS=12

# --- Summary ---
SUMMARY_MODEL_CONFIG__TRANSPORT=openai
SUMMARY_MODEL_CONFIG__MODEL=deepseek-v4-flash
SUMMARY_MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.deepseek.com

# --- Embeddings ---
EMBED_MESSAGES=true
EMBEDDING_MODEL_CONFIG__TRANSPORT=gemini
EMBEDDING_MODEL_CONFIG__MODEL=gemini-embedding-001
LLM__GEMINI_API_KEY=your-gemini-api-key
# Note: Honcho reads LLM__GEMINI_API_KEY (double underscore, LLM_ prefix),
# NOT GOOGLE_API_KEY. The env var name is derived from LLMSettings.GEMINI_API_KEY.

# --- Auth (local dev only) ---
AUTH_USE_AUTH=false
```

### Dialectic-only override (save tokens — use cheap model for routine, expensive for deep)

```env
# Cheap for routine context injection
DIALECTIC_LEVELS__minimal__MODEL_CONFIG__MODEL=deepseek-v4-flash
DIALECTIC_LEVELS__low__MODEL_CONFIG__MODEL=deepseek-v4-flash

# Better model for deep reasoning
DIALECTIC_LEVELS__high__MODEL_CONFIG__MODEL=deepseek-v4-pro
DIALECTIC_LEVELS__max__MODEL_CONFIG__MODEL=deepseek-v4-pro
```

### Using OpenRouter (one API key, many models)

```env
LLM_OPENAI_API_KEY=sk-or-your-openrouter-key
DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL=https://openrouter.ai/api/v1
DERIVER_MODEL_CONFIG__MODEL=deepseek/deepseek-v4-flash

# Same pattern for dialectic/summary/embeddings — just swap the model name
```

## Docker Compose with Deriver

The stock `docker-compose.yml.example` only defines the `api` service.
You need to add a `deriver` service for background memory processing:

```yaml
services:
  api:
    build: .
    entrypoint: ["sh", "docker/entrypoint.sh"]
    depends_on:
      database: { condition: service_healthy }
      redis: { condition: service_healthy }
    ports: ["127.0.0.1:8000:8000"]
    environment:
      - DB_CONNECTION_URI=postgresql+psycopg://postgres:postgres@database:5432/postgres
      - CACHE_URL=redis://redis:6379/0?suppress=true
      - CACHE_ENABLED=true
      - LLM_OPENAI_API_KEY=${YOUR_API_KEY_ENV_VAR}   # pass from host env
    env_file:
      - path: .env
        required: true
    restart: unless-stopped

  deriver:
    build: .
    entrypoint: ["/app/.venv/bin/python", "-m", "src.deriver"]
    depends_on:
      api: { condition: service_started }
      database: { condition: service_healthy }
      redis: { condition: service_healthy }
    environment:
      - DB_CONNECTION_URI=postgresql+psycopg://postgres:postgres@database:5432/postgres
      - CACHE_URL=redis://redis:6379/0?suppress=true
      - CACHE_ENABLED=true
      - LLM_OPENAI_API_KEY=${YOUR_API_KEY_ENV_VAR}   # pass from host env
    env_file:
      - path: .env
        required: true
    restart: unless-stopped
```

Start with:
```bash
export YOUR_API_KEY_ENV_VAR=sk-... && docker compose up -d
```

## Hermes Connection Config

After Honcho is running, wire Hermes to it:

```bash
hermes config set memory.provider honcho
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
  "sessionStrategy": "per-directory",
  "contextCadence": 1,
  "dialecticCadence": 2,
  "dialecticDepth": 1,
  "dialecticReasoningLevel": "low",
  "injectionFrequency": "every-turn",
  "observationMode": "directional"
}
```

Verify:
```bash
hermes honcho status
```

## Pitfalls

- **`AUTH_USE_AUTH=false` is essential for local dev** — without it, Honcho
  requires a JWT and the client won't connect.
- **Model must support tool/function calling** — the Dialectic subsystem
  uses tool loops internally. If your model doesn't support tools, Dialectic
  (`honcho_reasoning`) will fail silently.
- **DeepSeek `json_object` response format** — DeepSeek V4 Flash does NOT
  support `response_format: {type: "json_object"}` that Honcho's deriver
  sends. The deriver LLM call fails with `"This response_format type is
  unavailable now"`. Either switch the deriver to a model that supports it
  (e.g., `deepseek-chat`) or see `references/honcho-deriver-troubleshooting.md`
  for full diagnosis and workarounds.
- **Batch token threshold stalls the deriver** — the deriver won't process
  representation work units until accumulated tokens reach
  `REPRESENTATION_BATCH_MAX_TOKENS` (default 1024). Small seed messages sit
  pending. See `references/honcho-deriver-troubleshooting.md` for flush mode
  and diagnosis.
- **Docker Compose variable interpolation** — `LLM_OPENAI_API_KEY=${DEEPSEEK_API_KEY}`
  in `docker-compose.yml` reads from `.env`. If `DEEPSEEK_API_KEY` isn't in
  `.env`, the env var is empty. Also, pydantic-settings needs
  `LLM__OPENAI_API_KEY` (double underscore). See the troubleshooting reference
  for the exact `.env` lines needed.
- **pgvector dimension mismatch when switching embedding providers** —
  Different embedding models produce different vector dimensions. Honcho's
  startup validator (`src/startup/embedding_validator.py`) crashes the API
  and deriver if the pgvector column dimension doesn't match
  `EMBEDDING_VECTOR_DIMENSIONS`. Before starting containers with a new
  embedding model, migrate the pgvector columns. Common dimensions: OpenAI
  `text-embedding-3-small` = 1536, Gemini `gemini-embedding-001` = 768.
  Migration recipe (requires deleting existing observations):
  `references/honcho-deriver-troubleshooting.md` (the "pgvector Dimension
  Mismatch" section).
- **DeepSeek embeddings** — DeepSeek has a `deepseek-embedding` model listed in docs but does NOT actually host an embeddings endpoint. The API call to `POST /v1/embeddings` returns HTTP 404. Use Gemini (`gemini-embedding-001`) via `LLM__GEMINI_API_KEY` (not `GOOGLE_API_KEY` — Honcho reads `LLMSettings.GEMINI_API_KEY` from the `LLM_`-prefixed env var), or use a different provider with a real embedding API. See `honcho-deriver-troubleshooting.md` for the Gemini setup recipe and pgvector migration.
- **`hermes honcho` subcommand only appears** after `memory.provider: honcho`
  is set and you start a new Hermes session (or the current session is reset).
- **Only one external provider at a time** — Honcho and Mem0 can't run
  simultaneously. Built-in memory always stays active alongside.
- **Model catalog doesn't matter here** — Honcho routes LLM calls on the
  server side, not through Hermes's model catalog. The `MODEL_CONFIG` env
  vars are what control routing.
