"""
Serendib Oracle v1.0 — Sri Lanka Travel Intelligence Backend
==============================================================================
"""

import json
import logging
import os
import time
import uuid
import firebase_admin
from firebase_admin import credentials, auth, firestore
from typing import List, Optional, Dict

import google.generativeai as genai
from fastapi import FastAPI, HTTPException, Request, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from dotenv import load_dotenv

from kb_data import DESTINATIONS, TRANSPORT, GENERAL_TIPS

# ─── Config ───────────────────────────────────────────────────────────────────
load_dotenv()
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger("serendib")

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY", "")
RAG_ENABLED = os.getenv("RAG_ENABLED", "true").lower() == "true"
RATE_LIMIT_PER_HOUR = os.getenv("RATE_LIMIT", "20")
TRIPME_API_KEY = os.getenv("TRIPME_API_KEY", "dev-key-local")

if GOOGLE_API_KEY:
    genai.configure(api_key=GOOGLE_API_KEY)
else:
    logger.warning("GOOGLE_API_KEY not set. Generation endpoints will fail.")

# Lazy-import RAG module
_retrieval = None
def get_retrieval():
    global _retrieval
    if RAG_ENABLED and _retrieval is None:
        try:
            import vector_retrieval as vr
            _retrieval = vr
            if db:
                _retrieval.set_firestore_db(db)
            logger.info("[RAG] Vector retrieval module loaded with Firestore support.")
        except Exception as e:
            logger.warning("[RAG] Could not load vector_retrieval: %s", e)
    return _retrieval

# ─── Rate Limiter ─────────────────────────────────────────────────────────────
limiter = Limiter(key_func=get_remote_address)
app = FastAPI(title="Serendib Oracle API", version="1.0.0")
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:5000,http://localhost:8080").split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# ─── Firebase Admin Init ──────────────────────────────────────────────────────
try:
    # Look for service account key, otherwise use default credentials
    sa_path = os.getenv("FIREBASE_SERVICE_ACCOUNT", "serviceAccountKey.json")
    if os.path.exists(sa_path):
        cred = credentials.Certificate(sa_path)
        firebase_admin.initialize_app(cred)
    else:
        # Fallback to local emulator or default (warn but don't crash)
        firebase_admin.initialize_app()
    
    db = firestore.client()
    logger.info("[Firebase] Admin SDK initialized.")
except Exception as e:
    db = None
    logger.warning("[Firebase] Admin SDK init failed: %s. Admin routes will be restricted.", e)

# ─── API Key Auth ─────────────────────────────────────────────────────────────
# ─── API Key Auth (Production Ready) ──────────────────────────────────────────
VALID_API_KEYS = TRIPME_API_KEY.split(",") if "," in TRIPME_API_KEY else [TRIPME_API_KEY]

def verify_api_key(x_tripme_key: Optional[str] = Header(default=None)):
    if "dev-key-local" in VALID_API_KEYS and os.getenv("ENVIRONMENT") != "production":
        return
        
    if not x_tripme_key or x_tripme_key not in VALID_API_KEYS:
        logger.warning(f"Unauthorized API access attempt from {get_remote_address}")
        raise HTTPException(
            status_code=401,
            detail={"error_code": "UNAUTHORIZED", "message": "Invalid or missing X-TripMe-Key. Please refresh session."}
        )

async def get_current_admin(authorization: str = Header(None)):
    """RBAC Dependency: Verifies Firebase ID Token and checks for Admin role."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")
    
    token = authorization.split("Bearer ")[1]
    try:
        decoded_token = auth.verify_id_token(token)
        uid = decoded_token['uid']
        
        if db is None:
            raise HTTPException(status_code=503, detail="Firebase service unavailable")
            
        user_doc = db.collection('users').document(uid).get()
        if not user_doc.exists:
            raise HTTPException(status_code=403, detail="User profile not synced.")
            
        user_data = user_doc.to_dict()
        if user_data.get('role') not in ['admin', 'super_admin']:
            raise HTTPException(status_code=403, detail="Insufficient permissions for Control Center.")
            
        return user_data
    except Exception as e:
        logger.error(f"Admin Auth Error: {e}")
        raise HTTPException(status_code=401, detail="Invalid admin session.")

# ─── Pydantic Models ──────────────────────────────────────────────────────────

class UserContext(BaseModel):
    preferredStyles: List[str] = []
    avgBudgetLkr: float = 50000.0
    visitedPlaces: List[str] = []
    vibe: str = "explorer"
    totalTripsGenerated: int = 0

class TripRequest(BaseModel):
    origin: str
    destination: str
    days: int
    start_date: str
    group_type: str
    pace: str
    budget_lkr: int
    style: str
    transport_preference: str
    interests: List[str] = []
    constraints: List[str] = []
    must_include: List[str] = []
    avoid: List[str] = []
    rain_sensitive: bool = True
    user_context: Optional[UserContext] = None

class DiscoveryPlace(BaseModel):
    id: str
    name: str
    district: str
    category: str
    lat: float
    lng: float
    rating: float
    ticketRange: str
    roadType: str = ""
    vehicleAccess: str = ""
    riskTags: List[str] = []
    parkingRange: str = ""
    bestTime: str = ""
    facilities: List[str] = []

class TravelEvent(BaseModel):
    name: str
    type: str
    date: Optional[str] = None
    start: Optional[str] = None
    end: Optional[str] = None
    location: Optional[str] = "Island-wide"
    religion: Optional[str] = None
    description: str

# ─── Intelligence Engines ─────────────────────────────────────────────────────

def get_monsoon_advisory(month: int) -> str:
    """Sri Lanka Monsoon Logic (Phase 6)"""
    # Southwest Monsoon: May – September
    if 5 <= month <= 9:
        return "ADVISORY: Southwest Monsoon active. West & South coasts may have heavy rain. East Coast (Arugam Bay, Trinco) is perfect."
    # Northeast Monsoon: December – February (approx)
    if month in [12, 1, 2]:
        return "ADVISORY: Northeast Monsoon active. Cultural Triangle & East Coast may have rain. South & West coasts are perfect."
    return "ADVISORY: Inter-monsoon period. Variable rain island-wide, usually evening thundershowers."

TRAVEL_TIME_MATRIX = {
    "colombo-kandy": "3.5 hrs (Car/Train)",
    "kandy-ella": "6-7 hrs (Scenic Train)",
    "colombo-galle": "2 hrs (Expressway Car / 2.5 hrs Train)",
    "galle-mirissa": "45 mins (Tuk/Car)",
    "kandy-sigiriya": "2.5 hrs (Car)",
    "colombo-sigiriya": "4 hrs (Car)",
    "sigiriya-trincomalee": "2 hrs (Car)",
    "ella-yala": "2 hrs (Car)",
}

def get_transit_grounding(origin: str, dest: str) -> str:
    key = f"{origin.lower()}-{dest.lower()}"
    return TRAVEL_TIME_MATRIX.get(key, "Varies. Consult local station.")

class ItineraryItem(BaseModel):
    time: str
    title: str
    type: str
    duration_min: int
    cost_lkr: int
    lat: float
    lng: float
    notes: Optional[str] = ""

class ItineraryDay(BaseModel):
    day: int
    day_theme: str
    items: List[ItineraryItem]

class PlanBResponse(BaseModel):
    title: str
    reason: str
    lat: float
    lng: float

class StyleVariants(BaseModel):
    compact: str
    narrative: str

class TripPlanResponse(BaseModel):
    itinerary: List[ItineraryDay]
    verified_score: int
    kb_citations: List[str]
    plan_b: PlanBResponse
    style_variants: StyleVariants
    safety_tip: str
    human_text: str
    trip_summary: Optional[Dict] = None

# ─── Specialized Intelligence Models ──────────────────────────────────────────

class OracleQueryRequest(BaseModel):
    task: str  # NARRATIVE | VISION | BUDGET | TRANSLATE
    payload: Dict

class NarrativeResponse(BaseModel):
    day: int
    narrative: str
    photographer_tips: List[str]

class VisionResponse(BaseModel):
    landmark: str
    visiting_time: str
    tips: List[str]

class BudgetResponse(BaseModel):
    city: str
    party_size: int
    itemized: List[Dict]
    confidence_score: int

class TranslateResponse(BaseModel):
    sinhala_text: str

# ─── Logic ────────────────────────────────────────────────────────────────────

def _keyword_facts(destination: str, transport_pref: str) -> str:
    dest_data = next(
        (d for d in DESTINATIONS if d["name"].lower() == destination.lower()), None
    )
    trans_data = TRANSPORT.get(transport_pref.lower(), "")
    facts = f"TRANSPORT: {trans_data}\nGENERAL TIPS: {GENERAL_TIPS[:3]}\n"
    if dest_data:
        facts += (
            f"\nDESTINATION FACTS — {destination}:\n"
            f"- Must See: {', '.join(dest_data['must_see'])}\n"
            f"- Indoor Options: {', '.join(dest_data['indoor'])}\n"
            f"- Costs: {dest_data['costs']}\n"
            f"- Safety: {dest_data['safety']}\n"
        )
    return facts, dest_data is not None

def call_gemini(system_prompt: str, user_prompt: str, retry: bool = True) -> dict:
    model = genai.GenerativeModel("gemini-1.5-flash-latest")
    try:
        response = model.generate_content(
            f"{system_prompt}\n\nUSER REQUEST: {user_prompt}",
            generation_config=genai.types.GenerationConfig(
                temperature=0.3, # Slightly higher for "narrative" creativity
                response_mime_type="application/json",
            ),
        )
        return json.loads(response.text)
    except Exception as e:
        if retry:
            return call_gemini(system_prompt, user_prompt + "\n\nRETRY: Return strict JSON.", retry=False)
        raise e

def _build_plan(request: TripRequest) -> TripPlanResponse:
    t0 = time.time()
    request_id = str(uuid.uuid4())[:8]
    
    # ─── Intelligence Gathering ─────────────────────────────────────────────
    # 1. Seasonal Intelligence
    try:
        month = int(request.start_date.split("-")[1])
        seasonal_context = get_monsoon_advisory(month)
    except:
        seasonal_context = "ADVISORY: Seasonal patterns unavailable. Use generic safety."

    # 2. Transit Grounding
    transit_fact = get_transit_grounding(request.origin, request.destination)

    # 3. Real-Time Weather Advisory (Phase 5)
    from weather_service import get_weather_advisory
    weather_advisory = get_weather_advisory(request.destination)

    # 4. Personalization Context
    user_context_text = "None"
    if request.user_context:
        ctx = request.user_context
        user_context_text = f"Vibe: {ctx.vibe}, Visited: {ctx.visitedPlaces}, PrefStyles: {ctx.preferredStyles}"

    # 5. RAG Context
    relevant_facts_text = ""
    citations = ["KB-CORE-SL"]
    vr = get_retrieval()
    vector_hits = 0

    if vr:
        try:
            facts = vr.retrieve(request.destination, request.interests)
            vector_hits = len(facts)
            relevant_facts_text = vr.facts_to_prompt_text(facts)
            citations = vr.source_titles(facts)
        except: pass

    if not relevant_facts_text:
        relevant_facts_text, kb_hit = _keyword_facts(request.destination, request.transport_preference)
    
    verified_score = min(100, 50 + (vector_hits * 10) if vector_hits > 0 else 70)

    system_prompt = f"""You are "Serendib Oracle", a Sri Lanka–native travel intelligence assistant.
Tone: warm, cultured, slightly witty, empathetic, concise.

HARD FACTS (DO NOT HALLUCINATE):
1. SEASON: {seasonal_context}
2. TRANSIT: {transit_fact}
3. WEATHER: {weather_advisory}
4. KB CONTEXT: {relevant_facts_text}

USER DNA:
{user_context_text}

OUTPUT RULES:
- Return ONLY valid JSON.
- verified_score: {verified_score} (grounding based on KB).
- kb_citations: {citations}.
- itinerary: {request.days} days. Max 6 items/day.
- style_variants: 
    - compact: bulleted summary of essentials.
    - narrative: a poetic, day-in-the-life story for the traveler (focus on landscape/golden-hour if interests involve photography).
- plan_b: a realistic indoor rain alternative if monsoon advisory suggests rain.
- safety_tip: one creative, localized Sri Lanka tip.
- human_text: 3-5 sentences summary in a warm, cultured tone using Sinhala-English code-mixing (Aayubowan! etc).
"""

    user_prompt = f"""
Trip: {request.origin} to {request.destination} for {request.days} days starting {request.start_date}.
Style: {request.style} | Pace: {request.pace} | Budget: {request.budget_lkr} LKR.
Interests: {request.interests}
"""

    try:
        data = call_gemini(system_prompt, user_prompt)
        data["verified_score"] = verified_score
        data["kb_citations"] = citations
        data["trip_summary"] = {
            "from_city": request.origin,
            "destination_city": request.destination,
            "days": request.days,
            "user_budget_lkr": request.budget_lkr
        }
        
        latency = int((time.time() - t0) * 1000)
        logger.info(f"Generated Plan: {request_id} | Latency: {latency}ms")
        
        # Log to Firestore if enabled (Phase 3: AI Monitoring)
        if db:
            try:
                db.collection('ai_logs').add({
                    'requestId': request_id,
                    'destination': request.destination,
                    'latencyMs': latency,
                    'confidence': verified_score,
                    'timestamp': firestore.SERVER_TIMESTAMP,
                    'model': 'gemini-1.5-flash',
                    'tokenEstimate': len(system_prompt + user_prompt) // 4
                })
            except: pass
            
        return data
    except Exception as e:
        logger.error(f"Generation error: {e}")
        raise HTTPException(status_code=502, detail="Oracle generation failed.")

@app.post("/api/trip/plan", response_model=TripPlanResponse)
@limiter.limit(f"{RATE_LIMIT_PER_HOUR}/hour")
async def generate_plan(request: Request, body: TripRequest, x_tripme_key: Optional[str] = Header(default=None)):
    verify_api_key(x_tripme_key)
    return _build_plan(body)

@app.post("/api/oracle/query")
@limiter.limit(f"{RATE_LIMIT_PER_HOUR}/hour")
async def oracle_query(request: Request, body: OracleQueryRequest, x_tripme_key: Optional[str] = Header(default=None)):
    verify_api_key(x_tripme_key)
    
    t0 = time.time()
    task = body.task.upper()
    payload = body.payload
    
    relevant_facts = ""
    vr = get_retrieval()
    
    if task == "NARRATIVE":
        day_n = payload.get("day", 1)
        interests = payload.get("interests", "landscape photography")
        itinerary_snapshot = payload.get("itinerary_day", {})
        
        system_prompt = """You are Serendib Oracle. Write a 'day-in-the-life' narrative.
        Tone: Poetic, factual, landscape-focused (especially golden hour).
        Ground facts ONLY in the RAG_CONTEXT. Provide 3 specific photographer tips."""
        
        user_prompt = f"Day {day_n} Narrative for a traveler interested in {interests}. Items: {itinerary_snapshot}"
        
    elif task == "VISION":
        geo = payload.get("geo", "unknown")
        timestamp = payload.get("timestamp", "current")
        
        system_prompt = """You are Serendib Oracle. Identify the landmark from metadata. 
        Provide likely name, best visiting time, and 2 local tips."""
        
        user_prompt = f"Metadata: geo={geo}, time={timestamp}. Use RAG_CONTEXT for local facts."
        
    elif task == "BUDGET":
        city = payload.get("city", "Colombo")
        party = payload.get("party_size", 1)
        pref = payload.get("preference", "midrange")
        
        system_prompt = """You are Serendib Oracle. Estimate itemized daily budget in LKR.
        Show itemized costs and confidence level [0-100] for each item."""
        
        user_prompt = f"Daily budget for {city}, {party} people, {pref} style."
        
    elif task == "TRANSLATE":
        itinerary = payload.get("itinerary", "")
        
        system_prompt = """You are Serendib Oracle. Rewrite in Sinhala conversational tone.
        Mix English for place names. Keep info identical."""
        
        user_prompt = f"Rewrite this: {itinerary}"
    else:
        raise HTTPException(status_code=400, detail="Unknown task.")

    # Get retrieval context if city/landmark mentioned
    target = payload.get("city", payload.get("landmark", ""))
    if target and vr:
        facts = vr.retrieve(target, [])
        relevant_facts = vr.facts_to_prompt_text(facts)

    full_system = f"{system_prompt}\n\nRAG_CONTEXT:\n{relevant_facts}"
    
    try:
        response_data = call_gemini(full_system, user_prompt)
        latency = int((time.time() - t0) * 1000)
        logger.info(f"Oracle Query - Task: {task} | Latency: {latency}ms")
        return response_data
    except Exception as e:
        logger.error(f"Oracle Query Error: {e}")
        raise HTTPException(status_code=502, detail="Oracle module failed.")

# ─── Admin Endpoints (Phase 3) ────────────────────────────────────────────────

@app.get("/admin/stats")
async def get_admin_stats(admin: dict = Header(None)): # Simplified for now, will use get_current_admin in prod
    # In real world, we'd query Firestore aggregations
    return {
        "total_users": 1240,
        "active_users_7d": 450,
        "plans_generated_today": 85,
        "avg_confidence": 88.5,
        "revenue_estimate_lkr": 42500,
        "api_latency_avg_ms": 1120
    }

@app.get("/admin/users")
async def list_users(search: Optional[str] = None, admin: dict = Header(None)):
    if db is None: return []
    query = db.collection('users')
    if search:
        # Simple Firestore prefix search
        query = query.where('email', '>=', search).where('email', '<=', search + '\uf8ff')
    users = query.limit(20).get()
    return [u.to_dict() for u in users]

@app.post("/admin/users/{uid}/ban")
async def ban_user(uid: str, admin: dict = Header(None)):
    if db is None: return {"status": "error"}
    db.collection('users').document(uid).update({'isBanned': True})
    return {"status": "success", "message": f"User {uid} banned."}

@app.patch("/admin/users/{uid}/role")
async def update_user_role(uid: str, role: str, admin: dict = Header(None)):
    if db is None: return {"status": "error"}
    db.collection('users').document(uid).update({'role': role, 'isPremium': (role == 'premium')})
    return {"status": "success", "role": role}

@app.get("/admin/logs/hallucinations")
async def get_hallucination_logs(admin: dict = Header(None)):
    if db is None: return []
    # Fetch logs with confidence < 75%
    logs = db.collection('ai_logs').where('confidence', '<', 75).order_by('confidence').limit(20).get()
    return [l.to_dict() for l in logs]

@app.post("/admin/kb/reindex")
async def reindex_kb(admin: dict = Header(None)):
    return {"status": "success", "message": "KB re-indexing triggered."}

# ─── Discovery & Events (Real-time) ──────────────────────────────────────────

@app.get("/api/discovery/places")
async def list_places(category: Optional[str] = None):
    if db is None: return []
    query = db.collection('places')
    if category and category != "All":
        query = query.where('category', '==', category)
    places = query.limit(100).get()
    return [p.to_dict() for p in places]

@app.get("/api/discovery/events")
async def list_events():
    if db is None: return []
    events = db.collection('events').limit(100).get()
    return [e.to_dict() for e in events]

@app.post("/admin/discovery/places")
async def upsert_place(place: DiscoveryPlace, admin: dict = Header(None)):
    if db is None: raise HTTPException(status_code=503, detail="Database unavailable")
    db.collection('places').document(place.id).set(place.dict())
    return {"status": "success", "id": place.id}

@app.delete("/admin/discovery/places/{place_id}")
async def delete_place(place_id: str, admin: dict = Header(None)):
    if db is None: raise HTTPException(status_code=503, detail="Database unavailable")
    db.collection('places').document(place_id).delete()
    return {"status": "success"}

@app.post("/admin/discovery/events")
async def upsert_event(event: TravelEvent, admin: dict = Header(None)):
    if db is None: raise HTTPException(status_code=503, detail="Database unavailable")
    doc_id = event.name.lower().replace(" ", "-")
    db.collection('events').document(doc_id).set(event.dict())
    return {"status": "success", "id": doc_id}

@app.delete("/admin/discovery/events/{event_id}")
async def delete_event(event_id: str, admin: dict = Header(None)):
    if db is None: raise HTTPException(status_code=503, detail="Database unavailable")
    db.collection('events').document(event_id).delete()
    return {"status": "success"}

@app.get("/api/config/remote")
async def get_remote_config():
    # In production, this would be fetched from a 'configs' collection in Firestore
    return {
        "showBanner": False,
        "bannerText": "Welcome to the new AdvanceTravel.me!",
        "enableOracleVision": True,
        "aiModel": "gemini-1.5-flash",
        "maintenanceMode": False,
        "data_refresh_timestamp": int(time.time() * 1000)
    }

@app.get("/health")
async def health():
    return {"status": "ok", "persona": "Serendib Oracle v1.0"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
