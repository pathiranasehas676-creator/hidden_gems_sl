# AdvanceTravel.me — Full MVP Blueprint
> Generated: 2026-02-22 | ANTIGRAVITY PRO

---

## 1. PRODUCT SPEC (MVP)

### Vision
AdvanceTravel.me is a smart, AI-powered travel planning app for Sri Lanka that lets locals and tourists instantly generate a day-by-day itinerary, realistic LKR budget breakdown, rain fallback plan, and map-pinned route — all personalised to their travel style, group type, pace, and budget — with zero manual research required.

### Target Users + 3 Key User Journeys

**Users:**
- Sri Lankan local planning a weekend trip (Sinhala-speaking, budget-conscious)
- Foreign tourist planning 3–7 days (English, comfort or luxury tier)
- Group trip organiser (family/friends, needs itinerary to share)

**Journey 1 — Weekend Local:**
Home → "Plan Trip" → picks Colombo→Ella, 2 days, budget, train → AI generates plan → saves plan offline → shares screenshot with family.

**Journey 2 — First-Time Tourist:**
Onboarding (English) → enters Colombo→Kandy, 4 days, comfort, LKR 80,000 → reviews itinerary + map → reads Plan B for rainy days → upgrades one hotel.

**Journey 3 — Re-Planner:**
Opens Saved Plans → opens existing plan → taps "Regenerate (Change Budget)" → gets new plan within new LKR limit → compares.

### MVP Scope
- AI-generated itinerary (via backend → Gemini)
- Smart trip form (days, budget, style, pace, interests, transport)
- Results: Itinerary / Budget / Map / Plan B / Upgrades / Tips tabs
- Offline saved plans (Hive)
- English + Sinhala UI
- Safety tips per plan

### Out of Scope (Phase 3+)
- Booking integration (hotels, trains)
- Social sharing (trip cards)
- Community reviews
- Real-time pricing APIs
- Auth / user accounts (backend sync)
- Push notifications

### Success Metrics
- Trip plan generated within 8 seconds (p95)
- JSON parse failure rate < 1%
- Form-to-result completion rate > 70%
- Offline plan opens in < 300ms
- 4.2+ star rating in first 30 days post-launch

---

## 2. DESIGN SYSTEM (Flutter-Ready)

### Colors
```dart
// Primary
const Color ceylonBlue   = Color(0xFF003B5C); // Deep Ceylon Blue
const Color sigiriyaOchre = Color(0xFFC19A6B); // Sigiriya Ochre/Gold

// Neutrals
const Color surfaceWhite = Color(0xFFFAFAFA);
const Color backgroundGray = Color(0xFFF2F3F5);
const Color borderGray   = Color(0xFFE0E0E0);
const Color textPrimary  = Color(0xFF1A1A2E);
const Color textSecondary = Color(0xFF6B7280);
const Color textHint     = Color(0xFF9CA3AF);

// Semantic
const Color successGreen = Color(0xFF2E7D32);
const Color warningAmber = Color(0xFFF59E0B);
const Color errorRed     = Color(0xFFDC2626);
const Color infoBlue     = Color(0xFF1D4ED8);

// Dark mode surfaces
const Color darkSurface  = Color(0xFF1A1D1C);
const Color darkCard     = Color(0xFF262B2A);
const Color darkBorder   = Color(0xFF3A3F3E);
```

### Typography
```dart
// Font: Outfit (headings/UI), Noto Sans Sinhala (i18n fallback)
// Use google_fonts + flutter_localizations

TextTheme appTextTheme = GoogleFonts.outfitTextTheme().copyWith(
  displayLarge:  GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700),
  displayMedium: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w600),
  headlineMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
  titleLarge:    GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
  titleMedium:   GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500),
  bodyLarge:     GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400),
  bodyMedium:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
  bodySmall:     GoogleFonts.inter(fontSize: 12, color: textSecondary),
  labelLarge:    GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
);
// Sinhala fallback: wrap with Text widget, use locale-aware font selection
```

### Spacing Scale
```
xs:  4px   — icon padding, tag inner
sm:  8px   — between chips, small gaps
md:  16px  — card padding, section gaps
lg:  24px  — screen horizontal padding
xl:  32px  — section vertical gaps
xxl: 48px  — hero spacing
```

### Radius
```
xs:    4px  — tags, chips
sm:    8px  — small cards
md:    12px — cards
lg:    16px — large cards, bottom sheets
xl:    24px — modals, hero containers
full:  100px — pills, FABs
```

### Shadows
```dart
// Light elevation
BoxShadow cardShadow = BoxShadow(
  color: Colors.black.withValues(alpha: 0.06),
  blurRadius: 12, offset: Offset(0, 4));
BoxShadow elevatedShadow = BoxShadow(
  color: Colors.black.withValues(alpha: 0.10),
  blurRadius: 20, offset: Offset(0, 8));
```

### Core Components
- **PrimaryButton** — filled ceylonBlue, full-width, 56px tall, weight:bold
- **OutlineButton** — bordered ceylonBlue, same size
- **OchreButton** — sigiriyaOchre bg, black text, used for CTA (Generate Plan)
- **FilterChip** — 32px height, 8px h-padding, selected = blue bg 15% opacity
- **TypeChip** — coloured per item type (see ResultsScreen)
- **TripCard** — 16px padding, 12px radius, soft shadow, destination thumbnail placeholder
- **DayHeader** — gradient bar ceylonBlue, day number + theme
- **TimelineItem** — time column + icon dot + expandable card
- **BudgetBar** — horizontal progress with animated fill
- **SkeletonLoader** — shimmer grey block for async states
- **TabRail** — scrollable tabs, ochre indicator
- **BottomNav** — 5 items: Home / Explore / Plan / Saved / Settings

### Accessibility
- All interactive elements: min 48×48px tap target
- Color contrast: all text ≥ 4.5:1 against background
- Sinhala fallback font via `TextStyle.fontFamilyFallback: ['NotoSansSinhala']`
- Semantic labels on all icon buttons
- Dynamic text size: use `sp` scaling pattern or `textScaler`

---

## 3. SCREEN LIST + WIREFRAME-LEVEL LAYOUT

### Screen 1 — Onboarding (Language Select)
```
[Logo: travel_explore icon, 100px]
[Title: "AdvanceTravel.me"]
[Subtitle: "Plan like a local. Explore like a pro."]
[Spacer]
[Button: "Continue in English"] ← primary
[Button: "සිංහල දිගටම" ]         ← ochre
[TextButton: "Skip"]
```
- States: only one (static)
- Saves language preference to Hive
- On "Skip": defaults to system locale

### Screen 2 — Home
```
[AppBar: "Where to next?" + Avatar/Settings icon]
[HeroCard: gradient, quick stats: X plans saved]
[Section: "Start a New Trip"]
  [OchreButton: "✨ Plan New Trip"]
[Section: "Recent Plans"]
  [TripCard × 3 (shimmer if loading)]
[Section: "Saved Tips"]
  [HorizontalList: tip chips]
[FAB: camera icon (Phase 3)]
```
- States: empty (no plans), loading (shimmer), populated
- Empty state: illustrated traveller SVG + "Plan your first trip"

### Screen 3 — Smart Trip Form
```
[AppBar: "Plan Your Trip"]
[Section: "Destination"]
  [TextField: "Starting From" + my_location icon]
  [TextField: "Going To" + flag icon]
[Section: "Dates & Duration"]
  [DatePicker tile: Start Date]
  [Slider: 1–14 days]
[Section: "Group & Pace"]
  [ChoiceChip row: Solo / Couple / Family / Friends]
  [ChoiceChip row: Relaxed / Balanced / Packed]
[Section: "Budget"]
  [TextField (numeric): LKR amount]
  [ChoiceChip row: Budget / Comfort / Luxury]
[Section: "Transport"]
  [ChoiceChip row: Any / Train / Bus / Car / Tuk-tuk]
[Section: "Interests"]
  [FilterChip wrap: Nature / Beaches / History / Culture / Adventure / Food / Wildlife / Photography]
[Section: "Must Include (optional)"]
  [TagInput + chip list]
[Section: "Avoid (optional)"]
  [TagInput + chip list]
[GenerateButton: "GENERATE MY ITINERARY" — full width ochre]
```
- Validation: budget > LKR 1,000, destination non-empty
- Error state: inline field errors, red border

### Screen 4 — Loading (Step-Based Progress)
```
[Dark blue background]
[Animated Icon: travel_explore pulsing]
[LinearProgressIndicator: animated step]
[Text: rotating step messages]
[Summary chips: destination, days, budget]
[Tip: rotating local tips]
```
- Steps: Connect → Analysing route → Clustering gems → Budget calc → Plan B → Finalising
- Timeout: after 30s, show "Taking longer than usual..." with Cancel option

### Screen 5 — Results (5 tabs)
```
[AppBar: "Negombo → Kandy" + Share icon]
[TabBar: Itinerary | Budget | Map | Plan B | Tips]

TAB 1 Itinerary:
  [DayHeader: Day 1 — "Scenic Train Journey Day"]
  [TimelineItem: 07:00 | transport | Train to Kandy | 240min | LKR 350]
  [TimelineItem: 12:00 | food     | Local rice & curry | 30min | LKR 350]
  ...

TAB 2 Budget:
  [HeroBudgetCard: Total LKR X / Budget LKR Y — progress bar]
  [BudgetRow: Transport / Stay / Food / Tickets / Misc / Buffer]
  [Info notice]

TAB 3 Map:
  [GoogleMap or fallback list if no API key]
  [Markers: clustered by day, colour-coded by type]
  [DayFilter chips at top]
  [BottomSheet: tapped marker details]

TAB 4 Plan B:
  [Banner: "If it rains..."]
  [PlanBCard × n: indoor alternatives with location]

TAB 5 Tips:
  [TipCard: safety (orange), budgeting (blue), etiquette (green)]
  [Upgrade suggestions at bottom: star icon + extra cost]

[FAB: "Save Plan"]
```

### Screen 6 — Saved Plans
```
[AppBar: "My Saved Plans"]
[SearchBar]
[ListView: TripCard (date, destination, budget, days)]
[SwipeToDelete with undo snackbar]
[FAB: Plan New Trip]
```
- Empty: illustrated art + "No saved plans yet"

### Screen 7 — Settings
```
[ListTile: Language (English / සිංහල)]
[ListTile: Privacy Policy]
[ListTile: Location Permission (toggle)]
[ListTile: Analytics (toggle)]
[ListTile: Clear Saved Plans]
[ListTile: App Version]
```

---

## 4. FLUTTER TECH ARCHITECTURE

### State Management: Riverpod
**Why:** Code-gen friendly, testable, zero context threading issues, plays well with async, compatible with freezed models. BLoC adds too much boilerplate for this scope.

### Folder Structure (Clean Architecture)
```
lib/
├── core/
│   ├── theme/           app_theme.dart
│   ├── constants/       api_constants.dart, app_constants.dart
│   ├── errors/          failures.dart, exceptions.dart
│   ├── network/         dio_client.dart, interceptors/
│   └── utils/           extensions.dart, validators.dart
├── data/
│   ├── datasources/
│   │   ├── remote/      trip_remote_datasource.dart
│   │   └── local/       trip_local_datasource.dart    (Hive)
│   ├── models/          trip_plan_model.dart (freezed)
│   └── repositories/    trip_repository_impl.dart
├── domain/
│   ├── entities/        trip_plan.dart (pure Dart)
│   ├── repositories/    trip_repository.dart (abstract)
│   └── usecases/        generate_trip.dart, get_saved_plans.dart
├── presentation/
│   ├── screens/         home, form, loading, results, saved, settings, onboarding
│   ├── widgets/         shared UI components
│   └── providers/       trip_provider.dart, saved_plans_provider.dart
├── l10n/                app_en.arb, app_si.arb
└── main.dart
```

### Networking (Dio)
```dart
// dio_client.dart
class DioClient {
  static Dio create() => Dio(BaseOptions(
    baseUrl: AppConstants.backendBaseUrl, // from .env / build args
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 45),
    headers: {'Content-Type': 'application/json'},
  ))
    ..interceptors.add(LogInterceptor(responseBody: false))
    ..interceptors.add(RetryInterceptor(dio, retries: 1));
}
```
- Backend URL: injected via `--dart-define=BACKEND_URL=https://api.advancetravel.me`
- Never hardcode keys in Flutter

### Local Storage (Hive)
```dart
// Boxes
Box<String> savedPlansBox; // key = planId, value = JSON string
Box<String> settingsBox;   // key = 'language', 'analytics_opt_in', etc.

// Adapter via json_serializable or manual JSON encode/decode
```

### JSON Parsing Strategy
Use **`freezed` + `json_serializable`** for models. Auto-generates `fromJson`, `copyWith`, equality, `toString`. Use `build_runner` in CI.

```yaml
dependencies:
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  dio: ^5.4.0
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.4
dev_dependencies:
  freezed: ^2.5.2
  json_serializable: ^6.7.1
  build_runner: ^2.4.8
  hive_generator: ^2.0.1
```

### i18n Plan
```
lib/l10n/app_en.arb  — English strings
lib/l10n/app_si.arb  — Sinhala strings
```
Wrap MaterialApp with `localizationsDelegates` and `supportedLocales`. Store `Locale` in Hive `settingsBox`. Use `AppLocalizations.of(context).planNewTrip` pattern.

### Maps Plan
- Use `google_maps_flutter` (already in pubspec)
- Add a Google Maps API key to `AndroidManifest.xml` and `AppDelegate.swift`
- Build `Set<Marker>` from itinerary items where `lat != 0 && lng != 0`
- Color markers by type (transport=indigo, food=orange, nature=green, attraction=blue)
- Include `CameraUpdate.newLatLngBounds` to frame all day markers
- Day filter chip row toggles which day's markers are shown

---

## 5. DATA MODELS (JSON SCHEMA + DART)

### Exact JSON Schema (STRICT)
```json
{
  "trip_summary": {
    "from_city": "string",
    "destination_city": "string",
    "days": "integer",
    "start_date": "YYYY-MM-DD",
    "group_type": "solo|couple|family|friends",
    "pace": "relaxed|balanced|packed",
    "style": "budget|comfort|luxury",
    "user_budget_lkr": "integer"
  },
  "itinerary": [
    {
      "day": "integer",
      "day_theme": "string",
      "items": [
        {
          "time": "HH:MM",
          "title": "string",
          "type": "transport|attraction|food|rest|hotel|shopping|nature|culture",
          "duration_min": "integer",
          "cost_lkr": "integer",
          "lat": "float",
          "lng": "float",
          "notes": "string"
        }
      ]
    }
  ],
  "budget_breakdown": {
    "transport": "integer",
    "stay": "integer",
    "food": "integer",
    "tickets": "integer",
    "misc": "integer",
    "buffer_10_percent": "integer",
    "total": "integer"
  },
  "plan_b_rain": [
    {
      "title": "string",
      "reason": "string",
      "lat": "float",
      "lng": "float"
    }
  ],
  "comfort_upgrade_suggestions": [
    {
      "title": "string",
      "extra_cost_lkr": "integer",
      "why": "string"
    }
  ],
  "tips": ["string"]
}
```

### Dart Models (freezed pattern)
```dart
// trip_plan_model.dart — abbreviated, expand with freezed/json_serializable

@freezed
class TripPlan with _$TripPlan {
  const factory TripPlan({
    required TripSummary tripSummary,
    required List<ItineraryDay> itinerary,
    required BudgetBreakdown budgetBreakdown,
    required List<PlanBItem> planBRain,
    required List<ComfortUpgrade> comfortUpgrades,
    required List<String> tips,
  }) = _TripPlan;

  factory TripPlan.fromJson(Map<String, dynamic> json) => _$TripPlanFromJson(json);
}

@freezed
class ItineraryItem with _$ItineraryItem {
  const factory ItineraryItem({
    required String time,
    required String title,
    required String type,
    required int durationMin,
    required int costLkr,
    required double lat,
    required double lng,
    required String notes,
  }) = _ItineraryItem;

  factory ItineraryItem.fromJson(Map<String, dynamic> json) => _$ItineraryItemFromJson(json);
}
```

### TripRequest Model
```dart
@freezed
class TripRequest with _$TripRequest {
  const factory TripRequest({
    required String fromCity,
    required double fromLat,
    required double fromLng,
    required String destinationCity,
    required int days,
    required String startDate,
    required String groupType,
    required String pace,
    required int userBudgetLkr,
    required String style,
    required List<String> interests,
    required String transportPreference,
    @Default([]) List<String> constraints,
    @Default([]) List<String> mustInclude,
    @Default([]) List<String> avoid,
  }) = _TripRequest;

  factory TripRequest.fromJson(Map<String, dynamic> json) => _$TripRequestFromJson(json);
}
```

---

## 6. BACKEND PLAN (FastAPI)

### Endpoints

#### POST /api/trip/plan
Request:
```json
{
  "from_city": "Negombo",
  "from_lat": 7.2094,
  "from_lng": 79.8357,
  "destination_city": "Kandy",
  "days": 2,
  "start_date": "2026-03-01",
  "group_type": "couple",
  "pace": "balanced",
  "user_budget_lkr": 25000,
  "style": "budget",
  "interests": ["food", "culture"],
  "transport_preference": "train",
  "constraints": [],
  "must_include": [],
  "avoid": []
}
```
Response: `TripPlan JSON` (schema above)
Headers: `X-Plan-ID: uuid4`, `X-Generated-At: ISO8601`

#### POST /api/trip/regenerate
Same request body + `plan_id` (to log version).
Optional extra field: `{ "regenerate_reason": "change_budget", "new_budget_lkr": 20000 }`

#### GET /api/trip/plan/{plan_id}
Returns cached plan (Redis, 24h TTL) or 404.

### Validation Rules (Pydantic + backend)
```python
# validators.py
def validate_trip_plan(plan: dict, request: TripRequest) -> list[str]:
    errors = []
    bd = plan.get("budget_breakdown", {})
    total = bd.get("total", 0)
    budget = request.user_budget_lkr

    if total > budget:
        errors.append(f"total {total} exceeds user_budget_lkr {budget}")
    expected_buffer = round(total * 0.09)  # allow ~9–11%
    if bd.get("buffer_10_percent", 0) < expected_buffer * 0.5:
        errors.append("buffer_10_percent is too low")
    itinerary = plan.get("itinerary", [])
    if len(itinerary) != request.days:
        errors.append(f"itinerary has {len(itinerary)} days, expected {request.days}")
    for day in itinerary:
        types = [i["type"] for i in day.get("items", [])]
        if "food" not in types:
            errors.append(f"Day {day['day']} missing food block")
        if "rest" not in types and "hotel" not in types:
            errors.append(f"Day {day['day']} missing rest/hotel block")
    if len(plan.get("plan_b_rain", [])) < 2:
        errors.append("plan_b_rain must have >= 2 items")
    if len(plan.get("tips", [])) < 3:
        errors.append("tips must have >= 3 items")
    return errors
```

### Error Format Standard
```json
{
  "error_code": "VALIDATION_FAILED",
  "message": "Generated plan failed validation after 2 attempts",
  "details": {
    "failed_rules": ["total exceeds budget", "Day 2 missing food block"],
    "attempts": 2
  }
}
```

Error codes: `VALIDATION_FAILED`, `AI_TIMEOUT`, `INVALID_INPUT`, `RATE_LIMITED`, `INTERNAL_ERROR`

---

## 7. GEMINI PROMPT PACK

### System Prompt (Strict JSON)
```
You are AdvanceTravel.me Smart Travel Planner AI for Sri Lanka.

OUTPUT RULES (MANDATORY):
- Output ONLY valid JSON. No markdown. No explanation. No preamble.
- JSON must EXACTLY match the provided schema keys and types.
- Use realistic Sri Lanka travel times, costs (LKR), and road conditions.
- budget_breakdown.total MUST be <= user_budget_lkr.
- Include 10% buffer in buffer_10_percent. This MUST be part of total.
- Every itinerary item MUST have: time, title, type, duration_min, cost_lkr, lat, lng, notes.
- Each day MUST include at least 1 food item and 1 rest or hotel item.
- plan_b_rain MUST have at least 2 indoor alternatives.
- tips MUST have at least 3 items: 1 safety, 1 budgeting, 1 local etiquette.
- Max 6 main activities per day (excluding food/rest/hotel).
- Cluster activities geographically per day. Avoid late-night travel.
- Prefer outdoor activities 08:00–17:30.
- If uncertain about costs, use conservative estimates. Mention uncertainty in notes field only.
- Use simple English. No Sinhala in field values unless specifically a tip.
- lat/lng must be real Sri Lanka coordinates. Non-zero.
```

### User Prompt Template
```
Generate a Sri Lanka trip plan.

USER INPUT:
from_city: {{from_city}}
from_lat: {{from_lat}}
from_lng: {{from_lng}}
destination_city: {{destination_city}}
days: {{days}}
start_date: {{start_date}}
group_type: {{group_type}}
pace: {{pace}}
user_budget_lkr: {{user_budget_lkr}}
style: {{style}}
interests: {{interests}}
transport_preference: {{transport_preference}}
constraints: {{constraints}}
must_include: {{must_include}}
avoid: {{avoid}}

Return ONLY the JSON object matching this schema exactly:
{{SCHEMA_INJECTED_HERE}}
```

### Invalid JSON Retry Prompt
```
Your previous response was not valid JSON or did not match the required schema.

PREVIOUS RESPONSE EXCERPT (truncated):
{{previous_response_excerpt}}

VALIDATION ERRORS:
{{validation_errors}}

Rules reminder:
- Output ONLY a raw JSON object. No markdown, no code fences, no explanation.
- All keys must exactly match the schema.
- budget_breakdown.total must be <= {{user_budget_lkr}}.
- itinerary must have exactly {{days}} day objects.

Try again. Output ONLY the corrected JSON:
```

### Regenerate (Keep Constraints) Prompt
```
Regenerate the following trip plan with these changes:
CHANGE: {{regenerate_reason}}
{{#if new_budget_lkr}}New budget: {{new_budget_lkr}} LKR{{/if}}
{{#if new_pace}}New pace: {{new_pace}}{{/if}}

Original constraints to preserve:
- from_city: {{from_city}}
- destination_city: {{destination_city}}
- days: {{days}}
- group_type: {{group_type}}
- interests: {{interests}}
- transport_preference: {{transport_preference}}
- must_include: {{must_include}}
- avoid: {{avoid}}

Return ONLY a corrected JSON object matching the same schema. No markdown.
```

---

## 8. SERVER-SIDE JSON VALIDATION + AUTO-RETRY

### Flow
```python
# trip_service.py
MAX_RETRIES = 2

async def generate_trip(request: TripRequest) -> dict:
    prompt = build_user_prompt(request)
    
    for attempt in range(MAX_RETRIES):
        raw = await call_gemini(SYSTEM_PROMPT, prompt)
        
        # Step 1: Extract JSON
        json_str = extract_json(raw)
        
        # Step 2: Parse
        try:
            plan = json.loads(json_str)
        except json.JSONDecodeError as e:
            if attempt < MAX_RETRIES - 1:
                prompt = build_retry_prompt(raw, str(e), request)
                continue
            raise AIError("INVALID_JSON", str(e))
        
        # Step 3: Pydantic validation
        try:
            validated = TripPlanSchema(**plan)
        except ValidationError as e:
            if attempt < MAX_RETRIES - 1:
                errors = format_pydantic_errors(e)
                prompt = build_retry_prompt(raw, errors, request)
                continue
            raise AIError("VALIDATION_FAILED", str(e))
        
        # Step 4: Business rules
        rule_errors = validate_trip_plan(plan, request)
        if rule_errors:
            if attempt < MAX_RETRIES - 1:
                prompt = build_retry_prompt(raw, "\n".join(rule_errors), request)
                continue
            raise AIError("VALIDATION_FAILED", rule_errors)
        
        return plan
    
    raise AIError("MAX_RETRIES_EXCEEDED", "Plan could not be generated after 2 attempts")

def extract_json(text: str) -> str:
    """Strip markdown fences and extract first {} block."""
    text = re.sub(r'^```json?\s*', '', text.strip(), flags=re.MULTILINE)
    text = re.sub(r'```\s*$', '', text.strip(), flags=re.MULTILINE)
    start = text.find('{')
    end = text.rfind('}')
    if start != -1 and end != -1:
        return text[start:end+1]
    return text
```

### Rate Limiting
```python
# Use slowapi (FastAPI rate limiting)
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.post("/api/trip/plan")
@limiter.limit("5/minute;20/hour")
async def plan_trip(request: Request, body: TripRequest):
    ...
```
- Per IP: 5 req/min, 20 req/hour
- Return `429 Too Many Requests` with `Retry-After` header
- For production: add device fingerprint or Firebase Auth UID

---

## 9. SRI LANKA STARTER DATASET

### Strategy
Store as a `grounding_context.json` file loaded into the backend prompt builder (not sent to Gemini directly unless RAG is active). Ground prompts by injecting top 10 relevant places from the dataset.

### Dataset Fields (per destination)
```json
{
  "id": "kandy-01",
  "name": "Temple of the Tooth Relic",
  "city": "Kandy",
  "district": "Kandy",
  "category": "culture",
  "lat": 7.2936,
  "lng": 80.6413,
  "ticket_lkr": { "local": 250, "foreign": 1500 },
  "avg_food_nearby_lkr": 400,
  "best_time": "06:00–08:30 or 18:00–20:00 (puja)",
  "duration_min": 90,
  "indoor": false,
  "indoor_alternative": "Kandy National Museum (closed Mon)",
  "rain_fallback": true,
  "risk_tags": ["crowded_weekends", "shoe_removal_required"],
  "road_access": "paved",
  "parking": "limited",
  "facilities": ["restrooms", "cafe_nearby", "guide_available"]
}
```

### Top 20 Destinations (MVP seed)
1. Temple of the Tooth — Kandy (culture)
2. Sigiriya Rock Fortress (adventure, history)
3. Dambulla Cave Temple (culture, history)
4. Yala National Park (wildlife)
5. Mirissa Beach (beach)
6. Galle Fort (history, culture)
7. Ella Rock Hike (nature, adventure)
8. Nine Arches Bridge (nature, photography)
9. Horton Plains (nature)
10. Adam's Peak (Sri Pada) (adventure, culture)
11. Polonnaruwa Ancient City (history)
12. Anuradhapura Sacred City (history, culture)
13. Unawatuna Beach (beach)
14. Pinnawala Elephant Orphanage (wildlife)
15. Nuwara Eliya Tea Estates (nature, food)
16. Minneriya National Park (wildlife)
17. Udawalawe National Park (wildlife)
18. Arugam Bay (beach, adventure)
19. Trincomalee Beach (beach)
20. Negombo Fish Market + Lagoon (food, culture)

### RAG Plan (Phase 3)
- Embed dataset into a vector store (Supabase pgvector or Chroma)
- On request: embed destination query → retrieve top 10 similar places
- Inject as grounding context in the Gemini prompt
- Reduces hallucinated coordinates/costs

---

## 10. STEP-BY-STEP BUILD ROADMAP (4 WEEKS)

### Week 1 — UI + Dummy JSON + Storage
- [ ] Finalise design system (theme, tokens)
- [ ] Build all screens: Onboarding, Home, TripForm, Loading, Results (5 tabs)
- [ ] Wire navigation (GoRouter)
- [ ] Use hardcoded sample TripPlan JSON to populate Results
- [ ] Hive setup: SavedPlansBox, SettingsBox
- [ ] Implement Save Plan (Hive) + Saved Plans screen
- [ ] i18n scaffolding: en/si ARB files + MaterialApp localizations
- [ ] Test on Android emulator + Chrome

### Week 2 — Backend + Gemini + Validation
- [ ] FastAPI project: endpoints, Pydantic schemas, env config
- [ ] Implement Gemini call with system + user prompt
- [ ] JSON extraction + 2-attempt retry logic
- [ ] Business rule validation (budget, days, meals, plan_b_rain)
- [ ] Docker Compose (FastAPI + Redis)
- [ ] Rate limiting (slowapi)
- [ ] Flutter: DioClient pointing to backend
- [ ] Flutter: TripRepository (remote datasource)
- [ ] End-to-end test: form → loading → results from real AI

### Week 3 — Maps + GPS + Offline + Regenerate
- [ ] Google Maps API key setup (Android + iOS + Web)
- [ ] Map tab: markers from itinerary items, day filter
- [ ] GPS: geolocator → auto-fill from_city if user grants permission
- [ ] Offline: load saved plans from Hive offline (no network needed)
- [ ] Regenerate: backend endpoint + Flutter UI (bottom sheet prompt)
- [ ] Error handling: timeout, network, AI failure → error screen + retry
- [ ] Settings screen: language switch, permissions toggle

### Week 4 — Polish + Testing + Release
- [ ] Skeleton loaders for all async states
- [ ] Accessibility audit (48px targets, contrast, semantic labels)
- [ ] Sinhala UI pass (ARB translation review)
- [ ] Widget tests (form validation, results rendering)
- [ ] Integration test (mock backend)
- [ ] Backend: deploy to Fly.io or Render free tier
- [ ] Android release build (signing + keystore)
- [ ] iOS build (if Mac available)
- [ ] Web build: `flutter build web` for Chrome preview deployment
- [ ] Release checklist: permissions, privacy policy URL, store listing draft

---

## 11. SECURITY + PRIVACY

### Location Permissions
- Request permission only when user taps "Use My Location" (never on app open)
- Use `geolocator` with `LocationPermission.whileInUse` (not `always`)
- On denial: gracefully fallback to manual text entry
- Never store raw GPS coordinates to server — only city name resolved locally
- Never log coordinates to analytics

### Data Stored Locally vs Server
| Data | Local (Hive) | Server |
|------|-------------|--------|
| Saved trip plans | ✅ JSON string | ❌ never |
| User language preference | ✅ | ❌ |
| Last GPS coords | ✅ (session only, cleared on app close) | ❌ |
| Trip form inputs | ✅ (last values for convenience) | ❌ |
| Plan ID | ✅ | ✅ (for regenerate) |
| Raw query params | ❌ | ✅ (for AI call, no PII) |

### Privacy Notice
- Show on first launch before any data processing
- Plain language: "We don't store your location. Your trip plans are saved only on your device."
- Link to privacy policy (advancetravel.me/privacy)
- Analytics opt-in toggle in Settings (default: OFF for now)

### API Key Protection
```
# Backend .env (NEVER in Flutter app)
GEMINI_API_KEY=AIza...
REDIS_URL=redis://localhost:6379

# Flutter (safe): only backend URL
# --dart-define=BACKEND_URL=https://api.advancetravel.me
# NEVER: --dart-define=GEMINI_API_KEY=...
```
- Gemini key stays on backend only
- Backend validates `Content-Type: application/json` + rate limits
- For Phase 2: add Firebase Auth → JWT → backend validates Bearer token

### Abuse Prevention
- Rate limit: 5 req/min per IP (slowapi)
- Request size limit: 10KB max body
- Input sanitisation: strip HTML, max 200-char strings
- Log abusive IPs (no PII) for ban list
- Phase 2: device fingerprint + Cloudflare WAF

---

## 12. MVP EXAMPLE OUTPUT

### Input: Negombo → Kandy | 2 days | LKR 25,000 | budget | food + culture | train

```json
{
  "trip_summary": {
    "from_city": "Negombo",
    "destination_city": "Kandy",
    "days": 2,
    "start_date": "2026-03-01",
    "group_type": "couple",
    "pace": "balanced",
    "style": "budget",
    "user_budget_lkr": 25000
  },
  "itinerary": [
    {
      "day": 1,
      "day_theme": "Train Journey + Kandy Arrival + Temple Evening",
      "items": [
        {
          "time": "06:30",
          "title": "Travel to Negombo Railway Station",
          "type": "transport",
          "duration_min": 20,
          "cost_lkr": 200,
          "lat": 7.2094,
          "lng": 79.8357,
          "notes": "Take a tuk-tuk or walk from your guesthouse. Station is small — arrive 20 min early."
        },
        {
          "time": "07:05",
          "title": "Negombo to Kandy by Train (2nd Class)",
          "type": "transport",
          "duration_min": 210,
          "cost_lkr": 320,
          "lat": 7.2936,
          "lng": 80.6413,
          "notes": "Take train via Colombo Fort (change at Fort). Total approx 3.5 hrs. Purchase ticket at counter — no advance booking for 2nd class. Scenic hill route."
        },
        {
          "time": "10:45",
          "title": "Breakfast at Kandy Station Canteen",
          "type": "food",
          "duration_min": 30,
          "cost_lkr": 350,
          "lat": 7.2934,
          "lng": 80.6411,
          "notes": "String hoppers or roti with curry. Budget LKR 150–200 per person. Tea included."
        },
        {
          "time": "11:30",
          "title": "Check-in at Budget Guesthouse near Town Hall",
          "type": "hotel",
          "duration_min": 30,
          "cost_lkr": 0,
          "lat": 7.2910,
          "lng": 80.6340,
          "notes": "Pre-arranged guesthouse. Cost included in stay budget. Typical rate: LKR 2,500–3,500/night for a double room in budget tier."
        },
        {
          "time": "12:00",
          "title": "Lunch — Rice & Curry at Local Restaurant",
          "type": "food",
          "duration_min": 45,
          "cost_lkr": 700,
          "lat": 7.2912,
          "lng": 80.6350,
          "notes": "Plenty of local rice & curry spots around Kandy market area. Approx LKR 300–400 per person. Avoid tourist restaurants near lake — 2× price."
        },
        {
          "time": "13:00",
          "title": "Explore Kandy City Market",
          "type": "culture",
          "duration_min": 60,
          "cost_lkr": 300,
          "lat": 7.2931,
          "lng": 80.6374,
          "notes": "Walk through the Kandy Municipal Market for spices, local produce, and handicrafts. Great for food lovers. Budget LKR 300 for purchases."
        },
        {
          "time": "14:15",
          "title": "Kandy Lake Walk",
          "type": "nature",
          "duration_min": 45,
          "cost_lkr": 0,
          "lat": 7.2924,
          "lng": 80.6394,
          "notes": "Free, scenic lakeside walk. Clockwise route (about 3.4 km) passes Cloud Wall, Tooth Temple east entrance. Pleasant in afternoon shade."
        },
        {
          "time": "15:30",
          "title": "Sri Dalada Maligawa (Temple of the Tooth)",
          "type": "culture",
          "duration_min": 90,
          "cost_lkr": 1500,
          "lat": 7.2936,
          "lng": 80.6413,
          "notes": "Foreign tourist ticket LKR 1,500; locals LKR 250/couple. Visit during evening puja (18:00) if possible — more atmospheric. Remove shoes, cover shoulders."
        },
        {
          "time": "17:30",
          "title": "Rest at Guesthouse",
          "type": "rest",
          "duration_min": 60,
          "cost_lkr": 0,
          "lat": 7.2910,
          "lng": 80.6340,
          "notes": "Freshen up before evening. Avoid walking alone after 21:00 in less-lit areas."
        },
        {
          "time": "19:00",
          "title": "Dinner — Kandy Town Area Local Eatery",
          "type": "food",
          "duration_min": 45,
          "cost_lkr": 800,
          "lat": 7.2930,
          "lng": 80.6360,
          "notes": "Kottu roti or devilled dishes. Budget LKR 400–450 per person. Many spots open until 22:00 near Dalada Veediya street."
        }
      ]
    },
    {
      "day": 2,
      "day_theme": "Royal Botanical Gardens + Peradeniya + Train Home",
      "items": [
        {
          "time": "07:00",
          "title": "Early Breakfast at Guesthouse or Nearby Bakery",
          "type": "food",
          "duration_min": 30,
          "cost_lkr": 350,
          "lat": 7.2910,
          "lng": 80.6340,
          "notes": "Most budget guesthouses offer simple breakfast (bread, egg, tea) for LKR 200–300. Confirm with host the night before."
        },
        {
          "time": "07:45",
          "title": "Bus to Peradeniya Royal Botanical Gardens",
          "type": "transport",
          "duration_min": 20,
          "cost_lkr": 50,
          "lat": 7.2675,
          "lng": 80.5960,
          "notes": "Take bus No. 594 from Kandy bus stand. Fare LKR 25–35 each. Easy frequent service from 07:00."
        },
        {
          "time": "08:15",
          "title": "Peradeniya Royal Botanical Gardens",
          "type": "nature",
          "duration_min": 150,
          "cost_lkr": 1500,
          "lat": 7.2675,
          "lng": 80.5960,
          "notes": "Foreign entry LKR 1,500 per person; locals LKR 200. One of Asia's best botanical gardens. Orchid house + Java fig tree. Bring water — no shade in central area."
        },
        {
          "time": "11:00",
          "title": "Snack Break — Garden Vendors",
          "type": "food",
          "duration_min": 20,
          "cost_lkr": 200,
          "lat": 7.2675,
          "lng": 80.5960,
          "notes": "Vendors sell king coconut (thambili) and biscuits near the main gate. LKR 100–150 each."
        },
        {
          "time": "11:30",
          "title": "Return to Kandy by Bus",
          "type": "transport",
          "duration_min": 25,
          "cost_lkr": 50,
          "lat": 7.2934,
          "lng": 80.6411,
          "notes": "Same route back. Alight at Kandy bus stand."
        },
        {
          "time": "12:00",
          "title": "Lunch & Checkout",
          "type": "food",
          "duration_min": 60,
          "cost_lkr": 700,
          "lat": 7.2930,
          "lng": 80.6360,
          "notes": "Last lunch in Kandy. Try Ele House or similar local restaurant near market. Check out from guesthouse by 12:00 (confirm with host)."
        },
        {
          "time": "13:30",
          "title": "Train: Kandy to Colombo Fort",
          "type": "transport",
          "duration_min": 180,
          "cost_lkr": 230,
          "lat": 7.2934,
          "lng": 80.6411,
          "notes": "Intercity or regular express. 2nd class LKR 115–200 each. Arrive Colombo Fort by ~16:30. Change at Fort for Negombo line."
        },
        {
          "time": "16:45",
          "title": "Train: Colombo Fort to Negombo",
          "type": "transport",
          "duration_min": 60,
          "cost_lkr": 120,
          "lat": 7.2094,
          "lng": 79.8357,
          "notes": "Northern line train. Departs Fort approx 17:00. Budget LKR 60 per person. Arrives Negombo ~18:00. Evening rush — expect standing."
        },
        {
          "time": "18:00",
          "title": "Arrive Home — Negombo",
          "type": "rest",
          "duration_min": 0,
          "cost_lkr": 0,
          "lat": 7.2094,
          "lng": 79.8357,
          "notes": "Trip complete! Total travel time Day 2: ~5.5 hrs. Plan is designed to be relaxing with no rushing."
        }
      ]
    }
  ],
  "budget_breakdown": {
    "transport": 970,
    "stay": 3000,
    "food": 3100,
    "tickets": 4200,
    "misc": 800,
    "buffer_10_percent": 1207,
    "total": 13277
  },
  "plan_b_rain": [
    {
      "title": "Kandy National Museum",
      "reason": "Indoor, air-conditioned. Covers Kandyan Kingdom history, royal regalia. Entry LKR 250 locals / LKR 500 foreign. Closed Mondays.",
      "lat": 7.2944,
      "lng": 80.6391
    },
    {
      "title": "Arts & Crafts Center (Laksala — Kandy Branch)",
      "reason": "Indoor shopping and demonstration of traditional Sri Lankan crafts. Free to browse. Great for food & culture lovers — local spices, batik, lacquerware.",
      "lat": 7.2928,
      "lng": 80.6365
    },
    {
      "title": "Kandy City Centre Mall Food Court",
      "reason": "Indoor food court with local and international options. Good backup for a rainy afternoon — sheltered, central location near the lake.",
      "lat": 7.2912,
      "lng": 80.6367
    }
  ],
  "comfort_upgrade_suggestions": [
    {
      "title": "Upgrade to 1st Class Train (Negombo → Kandy)",
      "extra_cost_lkr": 1200,
      "why": "Reserved seats, air conditioning, significantly more comfortable for 3.5 hr journey. Book 1 day ahead at Colombo Fort station or via sri_lanka_railway website."
    },
    {
      "title": "Stay at a 3-star Hotel (e.g., Earl's Regency area)",
      "extra_cost_lkr": 4500,
      "why": "Better breakfast included, pool access, proper AC. Adds ~LKR 4,500–6,000 for 1 night vs budget guesthouse. Highly worth it for a special trip."
    },
    {
      "title": "Hire a Tuk-tuk for City Tour (Day 2 afternoon)",
      "extra_cost_lkr": 800,
      "why": "Negotiate LKR 1,200–1,500 for a 2hr city loop (Bahirava Kanda, Udawatta Forest, Arts Centre). Saves time and effort on a hot afternoon."
    }
  ],
  "tips": [
    "SAFETY: Avoid walking alone after 21:00 in Kandy's less-lit backstreets. Keep valuables (passport, phone) in your guesthouse safe. Use tuk-tuks metered via PickMe or Uber for fairness.",
    "BUDGETING: This plan uses only LKR 13,277 of your LKR 25,000 budget, leaving LKR 11,723 as genuine savings or for extras. Your 10% buffer (LKR 1,207) is already included in the total.",
    "LOCAL ETIQUETTE: Remove shoes before entering the Temple of the Tooth and any Buddhist temple. Dress modestly (cover shoulders and knees). Carrying a light shawl is useful for both rain and temple dress codes.",
    "TRAIN TIP: Sri Lanka's trains are beloved but often delayed 20–45 minutes. Don't book tight onwards connections. Morning trains (07:00–09:00) are most reliable.",
    "FOOD: The best rice & curry is found in local 'hotels' (not accommodation — that's what Sri Lankans call small eateries). Look for places full of local workers — that's your quality signal."
  ]
}
```

---
*End of Blueprint — AdvanceTravel.me MVP v1.0*
*Next: Implement Week 1 roadmap items starting with GoRouter setup + Riverpod providers.*
