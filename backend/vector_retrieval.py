"""
TripMe.ai — Vector Retrieval Module (RAG v2)
============================================
Uses Qdrant (self-hosted) + sentence-transformers (all-MiniLM-L6-v2, 384-dim).
No OpenAI / Google embedding calls required — fully local.

Setup:
  pip install qdrant-client sentence-transformers
  docker compose up -d       # starts Qdrant on port 6333
  python ingest_kb.py        # populates the collection

Retrieval rules:
  - topK: 8 by default (configurable via TRIPME_TOP_K env)
  - Filter: city must match destination (exact, lowercase)
  - If rain_sensitive=True: ensure >= 1 indoor result
  - Diversity: de-duplicate by 'type' field
  - Returns: List[dict] with title, text, source_id, city, type
"""

import os
import logging
from typing import Optional
from sentence_transformers import SentenceTransformer
from qdrant_client import QdrantClient
from qdrant_client.http.models import Filter, FieldCondition, MatchValue

# Optional: Firebase support for dynamic hot-topics
_db = None

def set_firestore_db(db):
    global _db
    _db = db

logger = logging.getLogger(__name__)

# ─── Configuration ────────────────────────────────────────────────────────────

QDRANT_URL = os.getenv("QDRANT_URL", "http://localhost:6333")
COLLECTION_NAME = "tripme_kb"
EMBEDDING_MODEL = "all-MiniLM-L6-v2"   # 384-dim, MIT licensed, runs fully offline
TOP_K = int(os.getenv("TRIPME_TOP_K", "8"))

# ─── Confidence Score Formula ─────────────────────────────────────────────────
#
# Heuristic based on KB hit count. Formula is stable and documented:
#
#   hits >= 6 → confidence = 0.85 + (hits - 6) * 0.02   (capped at 0.97)
#   hits 3–5  → confidence = 0.65 + (hits - 3) * 0.067
#   hits 0–2  → confidence = 0.40 + hits * 0.083
#
# This ensures:
#   - Zero hits → <= 0.50 (clearly flagged as low-confidence)
#   - Partial hit → 0.60–0.80 (acceptable)
#   - Strong KB match → 0.85+ (high confidence, max 0.97 never 1.0)

def compute_confidence(hit_count: int) -> float:
    if hit_count >= 6:
        raw = 0.85 + (hit_count - 6) * 0.02
    elif hit_count >= 3:
        raw = 0.65 + (hit_count - 3) * 0.067
    else:
        raw = 0.40 + hit_count * 0.083
    return round(min(raw, 0.97), 2)


# ─── Lazy initialization (avoids cold-start on import) ───────────────────────

_model: Optional[SentenceTransformer] = None
_client: Optional[QdrantClient] = None


def _get_model() -> SentenceTransformer:
    global _model
    if _model is None:
        logger.info("[RAG] Loading embedding model: %s", EMBEDDING_MODEL)
        _model = SentenceTransformer(EMBEDDING_MODEL)
    return _model


def _get_client() -> QdrantClient:
    global _client
    if _client is None:
        logger.info("[RAG] Connecting to Qdrant at %s", QDRANT_URL)
        _client = QdrantClient(url=QDRANT_URL, timeout=5)
    return _client


# ─── Retrieval ────────────────────────────────────────────────────────────────

def retrieve(
    destination: str,
    interests: list[str],
    rain_sensitive: bool = False,
    top_k: int = TOP_K,
) -> list[dict]:
    """
    Retrieve relevant KB facts for a destination.

    Returns a list of dicts, each with:
      { title, text, source_id, city, type, cost_range }

    Falls back to an empty list if Qdrant is unreachable
    (the system will generate with zero grounding rather than crash).
    """
    try:
        model = _get_model()
        client = _get_client()

        query_text = f"{destination} travel tips {' '.join(interests)}"
        if rain_sensitive:
            query_text += " indoor rainy day alternatives"

        vector = model.encode(query_text).tolist()

        # Mandatory filter: city must match destination
        city_filter = Filter(
            must=[
                FieldCondition(
                    key="city",
                    match=MatchValue(value=destination.lower()),
                )
            ]
        )

        results = client.search(
            collection_name=COLLECTION_NAME,
            query_vector=vector,
            query_filter=city_filter,
            limit=top_k + 4,   # fetch extra for diversity post-processing
        )

        hits = [r.payload for r in results if r.payload]

        # ── Diversity: cap each 'type' at 2 results ──────────────────────────
        type_count: dict[str, int] = {}
        diverse_hits = []
        for hit in hits:
            t = hit.get("type", "general")
            if type_count.get(t, 0) < 2:
                diverse_hits.append(hit)
                type_count[t] = type_count.get(t, 0) + 1
            if len(diverse_hits) >= top_k:
                break

        # ── Rain-sensitivity: ensure at least 1 indoor result ─────────────────
        if rain_sensitive:
            has_indoor = any(h.get("type") == "indoor" for h in diverse_hits)
            if not has_indoor:
                # Fetch specifically an indoor result
                indoor_filter = Filter(
                    must=[
                        FieldCondition(key="city", match=MatchValue(value=destination.lower())),
                        FieldCondition(key="type", match=MatchValue(value="indoor")),
                    ]
                )
                indoor_results = client.search(
                    collection_name=COLLECTION_NAME,
                    query_vector=vector,
                    query_filter=indoor_filter,
                    limit=1,
                )
                if indoor_results:
                    diverse_hits.insert(0, indoor_results[0].payload)
                    diverse_hits = diverse_hits[:top_k]  # keep at topK

        # ── Dynamic Backfill: Fetch "Hot Topics" from Firestore ───────────────
        if _db:
            try:
                hot_docs = _db.collection('hot_topics').where('city', '==', destination.lower()).limit(3).get()
                for doc in hot_docs:
                    diverse_hits.insert(0, doc.to_dict())
            except Exception as e:
                logger.warning("[RAG] Firestore hot_topics lookup failed: %s", e)

        return diverse_hits[:top_k]

    except Exception as e:
        logger.warning("[RAG] Retrieval failed (non-fatal, falling back to zero-shot): %s", e)
        return []


def facts_to_prompt_text(facts: list[dict]) -> str:
    """
    Format retrieved facts for injection into the LLM prompt.
    Returns an empty string if no facts (zero-shot path).
    """
    if not facts:
        return ""
    lines = ["## TripMe Knowledge Base — Verified Facts"]
    for i, f in enumerate(facts, 1):
        title = f.get("title", "Fact")
        text = f.get("text", "")
        source_id = f.get("source_id", "kb")
        lines.append(f"{i}. [{source_id}] **{title}**: {text}")
    lines.append("\nInstructions: Use the above facts to ground your answer. "
                 "Do NOT invent exact prices — use the ranges provided. "
                 "Cite source_ids in the sources[] field of your JSON response.")
    return "\n".join(lines)


def source_titles(facts: list[dict]) -> list[str]:
    """Extract source titles for the response sources[] field."""
    seen = set()
    out = ["TripMe Knowledge Base v1"]
    for f in facts:
        sid = f.get("source_id", "")
        title = f.get("title", "")
        label = f"{sid}: {title}" if sid and title else title or sid
        if label and label not in seen:
            seen.add(label)
            out.append(label)
    return out
