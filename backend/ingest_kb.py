"""
TripMe.ai — KB Ingestion Pipeline
===================================
Reads kb_data.py → chunks → embeds → upserts into Qdrant.
Run once before starting the server, and re-run whenever KB changes.

Usage:
  python ingest_kb.py

Requirements:
  pip install qdrant-client sentence-transformers
  docker compose up -d   # Qdrant must be running

Idempotent: uses source_id as the Qdrant point ID (hash-based).
Re-running will upsert (update) existing points without duplicates.
"""

import hashlib
import logging
import os
from qdrant_client import QdrantClient
from qdrant_client.http.models import (
    Distance,
    VectorParams,
    PointStruct,
    CollectionInfo,
)
from sentence_transformers import SentenceTransformer

from kb_data import DESTINATIONS, TRANSPORT, GENERAL_TIPS

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

QDRANT_URL = os.getenv("QDRANT_URL", "http://localhost:6333")
COLLECTION_NAME = "tripme_kb"
MODEL_NAME = "all-MiniLM-L6-v2"
VECTOR_DIM = 384


def stable_id(text: str) -> int:
    """Generate a stable int ID from text (for idempotent upserts)."""
    h = hashlib.md5(text.encode()).hexdigest()
    return int(h[:8], 16)


def chunk_destination(dest: dict) -> list[dict]:
    """
    Chunk one destination entry into multiple documents.
    Each chunk gets: title, text, city, type, source_id, cost_range.
    """
    city = dest["name"]
    city_lower = city.lower()
    chunks = []

    # 1. Must-see items — one chunk per attraction
    for attraction in dest.get("must_see", []):
        source_id = f"{city_lower}_must_{stable_id(attraction)}"
        text = (
            f"{attraction} is a must-see in {city}. "
            f"Costs: accommodation {dest['costs'].get('hotel', 'N/A')} LKR/night, "
            f"meals {dest['costs'].get('meal', 'N/A')} LKR. "
            f"Safety: {dest.get('safety', '')}"
        )
        chunks.append({
            "title": attraction,
            "text": text,
            "city": city_lower,
            "type": "outdoor",
            "source_id": source_id,
            "cost_range": dest["costs"].get("meal", "N/A"),
        })

    # 2. Indoor / rainy-day options — combined chunk
    indoor_items = dest.get("indoor", [])
    if indoor_items:
        source_id = f"{city_lower}_indoor"
        text = (
            f"Rainy day / indoor options in {city}: {', '.join(indoor_items)}. "
            f"Great alternatives when weather is bad."
        )
        chunks.append({
            "title": f"{city} Indoor Activities",
            "text": text,
            "city": city_lower,
            "type": "indoor",
            "source_id": source_id,
            "cost_range": dest["costs"].get("meal", "N/A"),
        })

    # 3. Costs + safety combined chunk
    source_id = f"{city_lower}_costs_safety"
    cost_text = (
        f"In {city}: meals cost {dest['costs'].get('meal', 'N/A')} LKR, "
        f"tuk-tuks {dest['costs'].get('tuk', 'N/A')} LKR, "
        f"hotels {dest['costs'].get('hotel', 'N/A')} LKR/night. "
        f"Safety note: {dest.get('safety', 'None.')}"
    )
    chunks.append({
        "title": f"{city} — Costs & Safety",
        "text": cost_text,
        "city": city_lower,
        "type": "costs_safety",
        "source_id": source_id,
        "cost_range": dest["costs"].get("hotel", "N/A"),
    })

    return chunks


def chunk_transport() -> list[dict]:
    chunks = []
    for mode, info in TRANSPORT.items():
        source_id = f"transport_{mode}"
        chunks.append({
            "title": f"Transport: {mode.title()}",
            "text": info,
            "city": "general",
            "type": "transport",
            "source_id": source_id,
            "cost_range": "varies",
        })
    return chunks


def chunk_general_tips() -> list[dict]:
    chunks = []
    for i, tip in enumerate(GENERAL_TIPS):
        source_id = f"tip_{i:03d}"
        chunks.append({
            "title": f"TripMe Tip #{i+1}",
            "text": tip,
            "city": "general",
            "type": "tips",
            "source_id": source_id,
            "cost_range": "N/A",
        })
    return chunks


def main():
    logger.info("Connecting to Qdrant at %s ...", QDRANT_URL)
    client = QdrantClient(url=QDRANT_URL, timeout=10)

    # Create collection if it doesn't exist
    existing = [c.name for c in client.get_collections().collections]
    if COLLECTION_NAME not in existing:
        logger.info("Creating collection '%s' ...", COLLECTION_NAME)
        client.create_collection(
            collection_name=COLLECTION_NAME,
            vectors_config=VectorParams(size=VECTOR_DIM, distance=Distance.COSINE),
        )
    else:
        logger.info("Collection '%s' already exists — upserting.", COLLECTION_NAME)

    # Load embedding model
    logger.info("Loading embedding model: %s ...", MODEL_NAME)
    model = SentenceTransformer(MODEL_NAME)

    # Build all chunks
    all_chunks: list[dict] = []
    for dest in DESTINATIONS:
        all_chunks.extend(chunk_destination(dest))
    all_chunks.extend(chunk_transport())
    all_chunks.extend(chunk_general_tips())

    logger.info("Total chunks to ingest: %d", len(all_chunks))

    # Embed + upsert in batches of 64
    batch_size = 64
    for i in range(0, len(all_chunks), batch_size):
        batch = all_chunks[i:i + batch_size]
        texts = [c["text"] for c in batch]
        vectors = model.encode(texts, show_progress_bar=False).tolist()

        points = [
            PointStruct(
                id=stable_id(c["source_id"]),
                vector=vec,
                payload={k: v for k, v in c.items()},
            )
            for c, vec in zip(batch, vectors)
        ]

        client.upsert(collection_name=COLLECTION_NAME, points=points)
        logger.info("  Upserted batch %d–%d", i + 1, i + len(batch))

    count = client.count(collection_name=COLLECTION_NAME).count
    logger.info("✅ Ingestion complete. Total points in collection: %d", count)


if __name__ == "__main__":
    main()
