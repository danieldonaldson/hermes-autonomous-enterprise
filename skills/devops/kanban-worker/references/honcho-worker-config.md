# Honcho Per-Worker Memory Configuration

Discovered during the Honcho migration session (2026-05-18).

## How it's set up

`~/.hermes/honcho.json` has the global config plus a `hosts` section with an entry for every enterprise profile. Each host entry sets:

```json
"hermes.engineer": {
  "aiPeer": "engineer",
  "peerName": "daniel",
  "workspace": "default",
  "recallMode": "hybrid",
  "sessionStrategy": "per-directory",
  "dialecticCadence": 2,
  "dialecticReasoningLevel": "low",
  "saveMessages": true,
  "writeFrequency": "async",
  "observationMode": "directional",
  "enabled": true
}
```

## Key design parameters

- **`aiPeer` matches the profile name** — every role (engineer, tech-lead, CTO, etc.) gets its own Honcho peer identity
- **`peerName: daniel`** — all workers serve the same user (Daniel)
- **`sessionStrategy: per-directory`** — each profile's working directory gets its own Honcho session
- **`recallMode: hybrid`** — context auto-injected AND Honcho tools available
- **`saveMessages: true`** — every conversation saved as observations for the deriver
- **`writeFrequency: async`** — writes are batched, not blocking the agent loop
- **`dialecticCadence: 2`** — dialectic reasoning runs every 2 turns (not every turn)
- **`dialecticReasoningLevel: low`** — cheaper/less-depth reasoning by default
- **`observationMode: directional`** — observations have directional metadata

## 25 profiles all get the same treatment

Every enterprise profile (engineer, tech-lead, ceo, cto, cpo, cmo, coo, finance, legal, pmo, rmo, chief-of-staff, designer, community-manager, content-marketing, growth-lead, sales-bd, customer-success, operations-analyst, user-research, head-of-data, head-of-quality, security-reviewer, audit-governance, mckinsey-consultant) has an identical host entry with its own aiPeer name.

## How workers access Honcho

The Honcho tools (honcho_profile, honcho_search, honcho_reasoning, honcho_context, honcho_conclude) are built into Hermes Agent and available to all profiles. Workers call them with `peer=<profile-name>`:

```python
# Recall what you've learned
honcho_reasoning(peer='engineer', query="project conventions")

# Save a durable fact
honcho_conclude(peer='engineer', conclusion="Prefer async/await over callback patterns")

# Cheap lookup
honcho_search(peer='engineer', query="deployment steps")
```

## Peer card seeding

All 25 role peer cards were seeded during the migration with role definitions. Each card contains 3-5 facts about the role. If a `honcho_profile(peer='engineer')` call returns empty, that's because the self-hosted Honcho peer card read path doesn't support arbitrary peer names in some versions — the data IS in Honcho and `honcho_reasoning`/`honcho_search` will find it.

## Built-in memory cleaned

The global `~/.hermes/memories/MEMORY.md` was reduced from 2,044 chars (92%) to 273 chars (12%). The `memory.provider: honcho` config means the `memory()` tool writes through to Honcho. Individual profiles have no separate memory files.
