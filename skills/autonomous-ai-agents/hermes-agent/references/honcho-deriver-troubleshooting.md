# Honcho Deriver Troubleshooting

The **deriver** is Honcho's background worker that processes conversation messages into memory (conclusions, representation, summaries). It runs as a separate docker container (`honcho-deriver-1`). When it's stuck or misconfigured, the AI peer's representation never builds and `hermes honcho status` shows "No peer data yet" indefinitely.

## Architecture

```
User messages → API server → Queue (Redis/Postgres) → Deriver worker → Conclusions + Representation
```

The deriver dequeues messages in batches, calls the LLM to extract conclusions, and stores them for future context injection.

## Diagnostics

### 1. Check the Deriver is Running

```bash
docker compose ps deriver
```

Should show `Up` and healthy. If the container keeps restarting, check logs:

```bash
docker logs honcho-deriver-1 --tail 50
```

### 2. Check Queue Status

The queue holds pending work units. If items stay "pending" for more than a minute, something is wrong:

```bash
curl -s "http://localhost:8000/v3/workspaces/default/queue/status"
```

Expected healthy response:
```json
{"total_work_units": 0, "completed_work_units": 0, "in_progress_work_units": 0, "pending_work_units": 0}
```

Stuck queue looks like:
```json
{"total_work_units": 3, "completed_work_units": 0, "in_progress_work_units": 0, "pending_work_units": 3}
```

Items can also be completed-but-failed (no actual conclusions produced) — check deriver logs.

### 3. Check Deriver Logs for LLM Errors

```bash
docker logs honcho-deriver-1 --tail 30
```

Common error patterns:

| Error | Likely Cause |
|-------|-------------|
| `Missing API key for openai model config` | API key not reaching container |
| `Error code: 400 - '...response_format type is unavailable...'` | Model doesn't support `json_object` response format |
| `Error code: 401` | Bad API key |
| `Error code: 429` | Rate limited — reduce `DERIVER_WORKERS` or increase polling interval |
| RetryError after 3 attempts | LLM call consistently failing |

Additional deriver log warnings:
- Failed to parse deriver response as PromptRepresentation — DeepSeek wrapped JSON in markdown code fences, or wrong model, or API key is literal *** placeholder
- Deriver generated zero observations — same root cause; parse failure cascades to zero output

### 4. Check Conclusions Were Actually Built

```bash
curl -s "http://localhost:8000/v3/workspaces/default/conclusions/list" \
  -H 'Content-Type: application/json' -d '{}'
```

If `items` is empty, the deriver processed queue items but the LLM calls failed.

## Common Issues & Fixes

### Issue: API Key Not Reaching the Deriver Container

**Symptoms:**
- Queue has pending items that never get processed
- Deriver logs show `Missing API key for openai model config`
- `curl -s http://localhost:8000/v3/workspaces/default/queue/status` shows `pending != 0`

**Root cause:** The docker-compose.yml passes `LLM_OPENAI_API_KEY=${DEEPSEEK_API_KEY}`. Docker Compose variable interpolation reads from the `.env` file in the project directory (or the shell environment). If `DEEPSEEK_API_KEY` isn't in `.env`, the variable resolves to empty.

**Meanwhile**, Honcho's pydantic-settings looks for `LLM__OPENAI_API_KEY` (double underscore — pydantic-seettings convention for nested settings). The docker-compose `LLM_OPENAI_API_KEY` (single underscore) in the `environment:` section sets the env var literally in the container, but that's different from what pydantic-settings expects.

**Pitfall — placeholder `***` in .env:** The `.env` file may contain `DEEPSEEK_API_KEY=***` literally (three asterisks) — this is a placeholder that was never filled in. The deriver container gets `***` as the actual API key. The deriver will still start and try to make LLM calls, but every call fails with an auth error (or a parse error if DeepSeek returns a non-JSON auth error page). `docker inspect` does NOT catch this — it just shows the variable IS set.

Check whether the key is a placeholder:
```bash
# Quick check — if it says "3 chars" it's ***
docker exec honcho-deriver-1 sh -c 'echo "DEEPSEEK_API_KEY: ${#DEEPSEEK_API_KEY} chars"'
```

**Fix — set both in `.env` with a real key:**

```bash
# ~/Work/honcho/.env — add these lines
DEEPSEEK_API_KEY=sk-your-key-here
LLM__OPENAI_API_KEY=sk-your-key-here
```

You can extract the real key from `~/.hermes/.env` (where Hermes Agent stores it) and inject it into `~/Work/honcho/.env` — same file, just copy the `DEEPSEEK_API_KEY=...` line over. Then rebuild and restart the deriver:

```bash
cd ~/Work/honcho && docker compose build deriver && docker compose up -d deriver
```

### Issue: Queue Items Complete But No Conclusions

**Symptoms:**
- Queue shows `completed_work_units > 0` but `conclusions/list` returns empty `items`
- Deriver logs show an LLM error

**Root cause:** The deriver's LLM call fails (e.g., response_format issue, bad model name, rate limit, or JSON parse failure). The queue item gets marked as processed/errored but no conclusions are created.

**Common root cause — markdown code fences around JSON output:** Even with the `executor.py` patches that strip `response_format` for DeepSeek, some DeepSeek models (especially `deepseek-chat` / DeepSeek V3) wrap the JSON response in markdown code fences:

```json
{"explicit": [{"content": "observation"}]}
```

The deriver's JSON parser (`deriver.py` ~line 175) calls `json.loads()` directly on the raw string, which fails with a parse error when the string contains markdown fences. The deriver logs show:
```
WARNING - Failed to parse deriver response as PromptRepresentation: raw content follows
WARNING - Deriver generated zero observations for messages X:Y in default/daniel!
```

**Fix — strip code fences in deriver.py AND use a model that outputs clean JSON:**

```python
# In deriver.py ~line 175, replace the bare json.loads with:
import json
import re
raw = _prompt_rep.strip()
if raw.startswith("```"):
    raw = re.sub(r'^```(?:json)?\s*\n?', '', raw)
    raw = re.sub(r'\n?\s*```\s*$', '', raw)
    raw = raw.strip()
_prompt_rep = PromptRepresentation.model_validate(json.loads(raw))
```

Also switch the deriver model to `deepseek-v4-flash` which produces cleaner JSON output without markdown wrapping. In `.env`:

```bash
DERIVER_MODEL_CONFIG__MODEL=deepseek-v4-flash
```

Unlike the misleading section title below, `deepseek-v4-flash` **does** work with the deriver because the executor.py patches already strip `response_format` for all deepseek models. The model itself follows the JSON-only prompt format well when the prompt says "Respond with ONLY valid JSON."

After both changes, rebuild the deriver container:
```bash
cd ~/Work/honcho && docker compose build deriver && docker compose up -d deriver
```

**Diagnosis:** Check the deriver logs for the specific LLM error:
```bash
docker logs honcho-deriver-1 --tail 50 | grep -i "error\|warning"
```

**Fix:** Resolve the specific LLM error (see the error table above), then clear and re-seed:

```bash
# If queue has errored items, they may need manual cleanup
# via the Honcho CLI or API. Alternately, send fresh messages
# to the session to generate new queue items.
curl -s -X POST "http://localhost:8000/v3/workspaces/default/sessions/daniel/messages" \
  -H 'Content-Type: application/json' \
  -d '{
    "messages": [
      {"content": "Seed messages for reprocessing.", "peer_id": "hermes"},
      {"content": "Acknowledged.", "peer_id": "daniel"}
    ]
  }'
```

### Issue: Queue Items Sit at "Pending" Forever

**Symptoms:**
- Queue status shows `pending > 0` for minutes
- Deriver is running (no crash loop)
- No error in deriver logs

**Root cause:** The deriver's `REPRESENTATION_BATCH_MAX_TOKENS` default is 1024 tokens. It won't process representation work units until the accumulated tokens in the batch reach that threshold. Small seed messages (a few hundred tokens total) sit waiting.

**Fix — enable flush mode:** Add to `.env`:
```bash
DERIVER_FLUSH_ENABLED=true
REPRESENTATION_BATCH_MAX_TOKENS=512   # optional: lower threshold
```

Then restart the deriver:
```bash
cd ~/Work/honcho && docker compose down deriver && docker compose up -d deriver
```

### Issue: DeepSeek `response_format` Incompatibility (Already Patched)

**Background:** Honcho's deriver historically passed `response_format: {type: "json_object"}` in the LLM request. DeepSeek models (all of them) do not support this parameter. The `executor.py` patches (already in the codebase) strip `response_format` for all deepseek models and force `json_mode=False`.

**This is already fixed in source.** If you're seeing `Failed to parse deriver response as PromptRepresentation` in deriver logs despite having the executor.py patches, the problem is either:

1. **Model choice** — `deepseek-chat` (DeepSeek V3) wraps JSON in markdown code fences. Switch to `deepseek-v4-flash` in `.env`:
   ```bash
   DERIVER_MODEL_CONFIG__MODEL=deepseek-v4-flash
   ```

2. **JSON parser** — `deriver.py` needs the markdown code fence stripping fix (see "Queue Items Complete But No Conclusions" section above).

3. **API key** — Check it's not the literal placeholder `***` (see API Key section above).

**Preferred model:** `deepseek-v4-flash` (not `deepseek-chat`). V4 Flash produces cleaner JSON output, follows the "Respond with ONLY valid JSON" prompt instruction reliably, and has the same API endpoint. The executor.py patches handle the response_format stripping for any model name containing "deepseek".

## Rebuilding the Deriver After Source Patches

After any source change under `~/Work/honcho/src/`, rebuild the Docker image:

```bash
cd ~/Work/honcho
docker compose down deriver         # stop + remove old container
docker compose build deriver        # rebuild with new source
docker compose up -d deriver        # start fresh
```

The image build caches well — only the `COPY src/` layer needs rebuilding since dependencies (`uv sync`) are cached separately. Expect ~1-2 seconds for the build after the initial run.

### Verifying the Patch Took Effect

```bash
# Check the patch is in the running container
docker exec honcho-deriver-1 grep -n "deepseek\|json_mode" /app/src/llm/executor.py | head -5

# Send test messages to trigger deriver processing
curl -s -X POST "http://localhost:8000/v3/workspaces/default/sessions/daniel/messages" \
  -H 'Content-Type: application/json' \
  -d '{"messages": [{"content": "Test message for deriver verification.", "peer_id": "hermes"}]}'

# Wait 20-30 seconds, then check
docker logs honcho-deriver-1 --tail 20
# No 400 errors expected
curl -s -X POST "http://localhost:8000/v3/workspaces/default/conclusions/list" \
  -H 'Content-Type: application/json' -d '{}'
```

**Note:** This only affects the deriver. The dialectic chat endpoint (`/chat` with `reasoning_level`) works fine with DeepSeek V4 Flash because it doesn't force `json_object` mode. The API server and peer card are fully functional.

## Restarting the Deriver Cleanly

If the container is in a bad state (e.g., "container is marked for removal"):

```bash
cd ~/Work/honcho
docker compose down deriver
docker compose up -d deriver
```

The `docker compose down` removes the old container. `up -d` creates a fresh one with the latest `.env` values.

To verify the env vars reached the container:
```bash
docker inspect honcho-deriver-1 --format '{{range .Config.Env}}{{println .}}{{end}}' | grep -i key
```

### Issue: DeepSeek V4 Flash Thinking Mode Breaks Dialectic Tool Loops

**Symptoms:**
- `hermes honcho status` connects successfully but shows "No peer data yet"
- Honcho API logs show: `Error code: 400 - 'The reasoning_content in the thinking mode must be passed back to the API.'`
- The error only appears on multi-turn dialogic queries (reasoning levels above `minimal`)
- Deriver runs fine and generates observations

**Root cause:** DeepSeek V4 Flash has a thinking/reasoning mode that returns `reasoning_content` in the response body. When Honcho's dialectic engine makes multiple tool calls in a loop (e.g., `MAX_TOOL_ITERATIONS > 1`), the second and subsequent calls include the assistant message from the previous turn — including `reasoning_content`. The OpenAI-compatible client doesn't echo `reasoning_content` back, and DeepSeek rejects the call with a 400 error requiring it to be passed back.

**Fix — use different models for deriver vs dialectic:**

```bash
# ~/Work/honcho/.env

# Deriver — single LLM call, no tool loop → can use deepseek-v4-flash
DERIVER_MODEL_CONFIG__MODEL=deepseek-v4-flash

# Dialectic — multi-turn tool loop → MUST use deepseek-chat (no thinking mode)
DIALECTIC_LEVELS__minimal__MODEL_CONFIG__MODEL=deepseek-chat
DIALECTIC_LEVELS__low__MODEL_CONFIG__MODEL=deepseek-chat
# ... repeat for medium, high, max levels
```

Restart the API container after changing:
```bash
docker compose -f ~/Work/honcho/docker-compose.yml restart api
```

**Why different models work:** The deriver makes a **single** LLM call (no tool loop, no conversation history to echo back), so `deepseek-v4-flash` works fine. The dialectic engine makes **multiple** tool calls in a loop, appending previous responses as conversation history. With `deepseek-v4-flash`, the `reasoning_content` from earlier calls contaminates the request for later calls. `deepseek-chat` (DeepSeek V3) has no thinking mode, so it doesn't return `reasoning_content` and doesn't require it to be echoed back.

**Diagnosis:** Check the API container logs for the `reasoning_content` error:
```bash
docker compose logs api 2>/dev/null | grep "reasoning_content"
```

### Issue: Embedding API Returns 404 (DeepSeek Has No Embedding API)

**Symptoms:**
- Deriver generates observations but fails to save them
- Deriver logs show: `Error code: 404` during `save_representation`
- The embedding client output contains `Embedding API unavailable (Error code: 404)`

**Root cause:** DeepSeek does not offer an embedding API. The Honcho `.env` is configured with `EMBEDDING_MODEL_CONFIG__MODEL=deepseek-embedding` and `EMBEDDING_MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.deepseek.com`, but the endpoint `POST /v1/embeddings` returns 404 because it doesn't exist.

**Fix options (choose one):**

**Option A — Use Gemini free tier (recommended):** Google's Gemini API offers `gemini-embedding-001` with a generous free tier. Honcho natively supports Gemini transport.

```bash
# ~/Work/honcho/.env — replace the embedding section
EMBEDDING_MODEL_CONFIG__TRANSPORT=gemini
EMBEDDING_MODEL_CONFIG__MODEL=gemini-embedding-001
# No base_url override needed — uses Google's default endpoint
# Must set GOOGLE_API_KEY in the .env
GOOGLE_API_KEY=your-gemini-api-key
```

Then restart all containers:
```bash
docker compose -f ~/Work/honcho/docker-compose.yml restart
```

### pgvector Dimension Mismatch After Switching Embedding Providers

**Symptoms:**
- API container fails to start with: `public.documents.embedding dim (1536) does not match EMBEDDING_VECTOR_DIMENSIONS (768)`
- Deriver container crashes with the same error
- `docker compose logs api` shows `StartupValidationError`
- The health endpoint returns nothing / connection refused

**Root cause:** Honcho's startup validator (`src/startup/embedding_validator.py`) checks that the pgvector column dimension matches `EMBEDDING_VECTOR_DIMENSIONS` in the `.env`. Different embedding models produce different vector dimensions:
- `text-embedding-3-small` (OpenAI) → 1536 dims
- `deepseek-embedding` (DeepSeek, non-existent) → configured as 1536
- `gemini-embedding-001` (Google) → 768 dims
- `text-embedding-3-large` (OpenAI) → 3072 dims

When you switch providers, the stored data has the old dimension but the config has the new one. The validator refuses to start until they match.

**Fix — migrate the pgvector columns before starting the containers:**

```bash
# 1. Drop FK constraint that prevents ALTER on documents table
docker compose -f ~/Work/honcho/docker-compose.yml exec -T database psql -U postgres -c "
ALTER TABLE documents DROP CONSTRAINT fk_documents_observer_observed_workspace_name_collections;
"

# 2. Delete old data (must be empty for ALTER TYPE to work)
docker compose -f ~/Work/honcho/docker-compose.yml exec -T database psql -U postgres -c "
DELETE FROM documents;
DELETE FROM message_embeddings;
"

# 3. Change column types to the new dimension
docker compose -f ~/Work/honcho/docker-compose.yml exec -T database psql -U postgres -c "
ALTER TABLE documents ALTER COLUMN embedding TYPE vector(768);
ALTER TABLE message_embeddings ALTER COLUMN embedding TYPE vector(768);
"

# 4. Re-add the FK constraint
docker compose -f ~/Work/honcho/docker-compose.yml exec -T database psql -U postgres -c "
ALTER TABLE documents ADD CONSTRAINT fk_documents_observer_observed_workspace_name_collections
    FOREIGN KEY (observer, observed, workspace_name) REFERENCES collections(observer, observed, workspace_name);
"

# 5. Verify the change
docker compose -f ~/Work/honcho/docker-compose.yml exec -T database psql -U postgres -c "
SELECT attrelid::regclass::text as table_name,
       format_type(atttypid, atttypmod) as data_type
FROM pg_attribute
WHERE attrelid IN ('documents'::regclass, 'message_embeddings'::regclass)
AND attname = 'embedding' AND NOT attisdropped;
"

# 6. Start the containers
docker compose -f ~/Work/honcho/docker-compose.yml up -d api deriver
```

The ALTER TYPE only works on empty tables — pgvector won't cast existing 1536-dim vectors to 768. You must delete the old data first. Replace `vector(768)` with your target dimension.

**Alternative — set VECTOR_DIMENSIONS to match existing data:** If you want to keep the existing observations, don't change the dimension. Set `EMBEDDING_VECTOR_DIMENSIONS=1536` (or whatever the column currently holds) and use an embedding model that matches.

Pitfall — the env var is `LLM__GEMINI_API_KEY`, not `GOOGLE_API_KEY`. Honcho's `LLMSettings` class reads this from `LLM_`-prefixed env vars, so `LLM__GEMINI_API_KEY=...` (double underscore) is correct. `GOOGLE_API_KEY` is not read by Honcho.

**Option B — Zero-vector fallback (for development):** Patch `embedding_client.py` to catch the 404 and return zero-vectors. Observations are saved to the database with zero-vector embeddings, so they appear in the conclusions list and `honcho_search`/`honcho_context` work. However, **semantic search is broken** — the dialectic engine (`honcho_reasoning`, `honcho_profile`) can't find observations, and peer cards stay empty.

Required changes to `embedding_client.py`:
1. In `embed()` (single query) — wrap the `try:` block around the API call, catch `Exception`, log a warning, and return `[0.0] * self.vector_dimensions`
2. In `simple_batch_embed()` (batch) — same pattern, return `[0.0] * self.vector_dimensions` for each text in the batch

After patching, rebuild and restart the deriver container:
```bash
cd ~/Work/honcho && docker compose build deriver && docker compose up -d deriver
```

**Option C — Use a different embedding provider:** Any OpenAI-compatible embedding API can work:
- OpenAI `text-embedding-3-small` (paid, cheap)
- Voyage AI (free tier available)
- Nomic AI (free tier)
- A local embedding model via a compatible server

Set the model and base URL in `.env`:
```bash
EMBEDDING_MODEL_CONFIG__TRANSPORT=openai
EMBEDDING_MODEL_CONFIG__MODEL=text-embedding-3-small
EMBEDDING_MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.openai.com/v1
# Plus the API key
OPENAI_API_KEY=sk-...
```

## Honcho API Diagnostic Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v3/workspaces/default/queue/status` | GET | Check queue health |
| `/v3/workspaces/default/conclusions/list` | POST `{}` | List stored observations |
| `/v3/workspaces/default/peers/hermes/representation` | POST `{}` | Get AI peer representation |
| `/v3/workspaces/default/peers/hermes/card` | GET `?target=daniel` | Get peer card for a target |
| `/v3/workspaces/default/peers/hermes/card` | PUT `{"peer_card": [...]}` | Set peer card directly |
| `/v3/workspaces/default/sessions/daniel/messages` | POST `{"messages": [...]}` | Send test messages |
| `/v3/workspaces/default/sessions/daniel/messages/list` | POST `{}` | List session messages |

## Full Recovery Sequence

When the deriver is completely stuck and you need to reset:

1. Check current state:
   ```bash
   curl -s "http://localhost:8000/v3/workspaces/default/queue/status"
   docker logs honcho-deriver-1 --tail 30
   ```

2. Fix the root cause (API key, batch threshold, model incompatibility)

3. Restart the deriver:
   ```bash
   cd ~/Work/honcho && docker compose down deriver && docker compose up -d deriver
   ```

4. Wait 15-30 seconds, verify:
   ```bash
   curl -s "http://localhost:8000/v3/workspaces/default/queue/status"
   # Should show pending → 0 as items process
   ```

5. Check conclusions appeared:
   ```bash
   curl -s "http://localhost:8000/v3/workspaces/default/conclusions/list" \
     -H 'Content-Type: application/json' -d '{}'
   ```

6. Verify identity:
   ```bash
   hermes honcho identity --show
   hermes honcho status
   ```
