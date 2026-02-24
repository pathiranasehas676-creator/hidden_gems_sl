# TripMe.ai — Backend README

## Quick Start (Local Dev)

```bash
# 1. Create venv and install deps
python -m venv .venv
.venv\Scripts\activate        # Windows
# source .venv/bin/activate  # macOS/Linux

pip install fastapi uvicorn google-generativeai slowapi \
            qdrant-client sentence-transformers

# 2. Set env vars (copy and edit)
copy .env.example .env

# 3. Start Qdrant (Docker required)
docker compose up -d

# 4. Ingest KB into Qdrant (run once, or after KB changes)
python ingest_kb.py

# 5. Start API server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `GOOGLE_API_KEY` | *(required)* | Gemini API key |
| `QDRANT_URL` | `http://localhost:6333` | Qdrant REST endpoint |
| `RAG_ENABLED` | `true` | Set `false` to disable vector retrieval |
| `TRIPME_TOP_K` | `8` | Number of KB chunks to retrieve per request |
| `RATE_LIMIT` | `20` | Requests/hour/IP (set `5` in production) |
| `TRIPME_API_KEY` | `dev-key-local` | X-TripMe-Key header value (skip auth if default) |

---

## API Endpoints

### `POST /api/trip/plan`
Generate a new trip plan.

**Headers:** `X-TripMe-Key: <your-key>` (skip in dev with default key)

**Body (snake_case):**
```json
{
  "origin": "Colombo",
  "destination": "Ella",
  "days": 3,
  "start_date": "2026-03-01",
  "group_type": "couple",
  "pace": "balanced",
  "budget_lkr": 45000,
  "style": "comfort",
  "transport_preference": "train",
  "interests": ["hiking", "photography"],
  "rain_sensitive": true
}
```

### `POST /api/trip/regenerate`
Same as `/plan` but hints the model to generate a meaningfully different itinerary.

### `GET /health`
Returns `{ "status": "ok", "rag_enabled": true, "version": "3.0.0" }`.

---

## Observability Log Format

One JSON line per request to stdout (no PII):
```json
{"request_id":"a1b2c3d4","rag_enabled":true,"kb_fallback":false,"vector_hits":7,"retry_count":0,"latency_ms":2341}
```

---

## Cache TTL + Schema Version Migration

### Flutter Cache TTL
- Plans are cached in Hive with a 7-day TTL.
- After 7 days, `getLastPlan()` evicts the entry and returns `CacheReadResult.stale`.
- The UI shows 🟡 "Stale Cache" badge; users can regenerate.

### Schema Version Migration
- All cached plans contain `"schema_version": 3`.
- If a cached plan has `schema_version < 3`, it is evicted on read (treated as stale).
- To bump schema version: increment `TripPlan.currentSchemaVersion` in `trip_plan_model.dart`.
- Old plans will be auto-evicted on first read after the app update.

### Cache Key Strategy
The cache key is a 12-character hash of:
`origin | destination | days | budgetLkr | style | interests | transport | startDate`

This ensures different request combinations never collide.

---

## How to Ingest KB into Qdrant

```bash
# After Qdrant is running:
python ingest_kb.py
```

The ingestion pipeline:
1. Reads `DESTINATIONS`, `TRANSPORT`, `GENERAL_TIPS` from `kb_data.py`.
2. Chunks each destination into typed documents: `outdoor`, `indoor`, `costs_safety`.
3. Embeds with `all-MiniLM-L6-v2` (384-dim, runs locally, no API cost).
4. Upserts to Qdrant using MD5-based stable IDs (idempotent — re-running is safe).

---

## Golden QA Scenarios

| # | Route | Style | Expected |
|---|---|---|---|
| 1 | Colombo → Kandy (3d, budget) | budget | Temple of the Tooth, plan_b indoor |
| 2 | Colombo → Ella (4d, comfort) | comfort | Nine Arch Bridge, train booking tip |
| 3 | Any dest (offline) | any | Cached plan served, amber badge |
| 4 | Colombo → Sigiriya (2d, solo) | budget | Wasps safety tip, Pidurangala |
| 5 | Colombo → Mirissa (3d, couple) | comfort | Whale watching, Nov–Apr note |

---

## Confidence Score Formula

| KB Hits | Confidence Range |
|---|---|
| 0–2 | 0.40 – 0.58 |
| 3–5 | 0.65 – 0.80 |
| 6+ | 0.85 – 0.97 |

Max confidence is capped at **0.97** (never 1.0 — acknowledges model uncertainty).

---

## Rate Limiting

- Default: **20 req/hour/IP** (local dev)
- Production: set `RATE_LIMIT=5` in `.env`
- Returns HTTP `429` with `{"error_code":"RATE_LIMITED","message":"..."}`
- Flutter shows: *"You've planned a lot today! Try again soon. 🕐"*
