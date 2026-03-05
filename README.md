# 🇱🇰 Hidden Gems Sri Lanka (AdvanceTravel.me)

An intelligent, AI-powered travel companion tailored specifically for exploring the beautiful island of Sri Lanka. 
This application leverages Google's Gemini AI, real-time fetching, and a stunning custom UI to deliver highly personalized itineraries, cultural immersion, and local secrets ("hidden gems") that most tourists miss.

---

## ✨ Features

### 🧳 AI-Powered Itinerary Generation
- **Intelligent Routing**: Uses **Gemini AI** to create perfectly optimized day-by-day travel plans.
- **Contextual Memory**: Remembers your last 5 destinations (`trip_history`) to prevent redundant recommendations.
- **Drag & Drop Timeline**: Reorder your itinerary interactively with the custom `ItineraryTimelineWidget`.
- **Skeleton Loading**: Enjoy smooth "Golden Tracer" shimmer effects while the AI computes your route.

### 🎨 Cinematic Sri Lankan Aesthetics
- **Batik Themes**: Choose from 6 stunning, Sri Lankan-nature inspired `VibeTheme` presets (e.g., Ceylon Blue 🌊, Lotus Pink 🌸, Sigiriya Gold ✨).
- **Global Light/Dark Mode**: Fully supports explicit Light and Dark modes along with system preference, switching entire app palettes dynamically.
- **Glassmorphism UI**: Beautiful floating navigation bars, transparent headers, and blurred backgrounds. 

### 🛡️ Safety & Practicality First
- **Offline Maps**: Save a static Google Map snapshot of your route for when you venture out of service areas.
- **Emergency Kit Screen**: One-tap access to 119/1990 and a local directory of police stations and hospitals.
- **LKR Budget Tracker**: Log localized daily expenses (Food, Transport, Tickets) against your originally planned budget directly inside the itinerary.

### 📅 Live Events & Culture
- **SriLankaEvents Dataset**: Integrated with a rich subset of 450+ curated local festivals and cultural events.
- **Interactive Calendar**: See exactly what is happening during your travel dates.
- **Multi-lingual Context**: Supports English (en), Sinhala (si), Tamil (ta), Japanese (ja), Russian (ru), and Korean (ko).

### 🛠️ Admin & Telemetry Tools
- **AI Hallucination Reporting**: Built-in Admin dashboard to view backend logs, latency, token usage, and user-flagged "hallucination" reports.
- **Remote Config**: Core architecture designed for over-the-air dynamically feature flagging.
- **Strict Firestore Rules**: User scopes enforce total privacy over personal trip data.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (v3.24.0 or higher recommended)
- Dart SDK
- Android SDK / Xcode for iOS
- A Firebase Project (with Firestore and Auth enabled)
- A local or remote Python environment for `backend/main.py` (FastAPI + SlowAPI)

### 1. Setup Firebase

1. Create a Firebase project.
2. Register your Android / iOS app within Firebase. Ensure the namespace matches `com.hidden.gems.hidden_gems_sl`.
3. Download the `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) and place them in their respective native directories.
4. Deploy the Security Rules located in `firestore.rules`.

### 2. Setup the AI Backend

The Flutter app communicates with a FastAPI Python layer that securely stores your Gemini API keys.
1. Navigate to the `backend/` directory.
2. Create a `.env` file and insert your `GEMINI_API_KEY`.
3. Install dependencies: `pip install -r requirements.txt` (including `slowapi`, `google-generativeai`).
4. Run the server: `python main.py`.

### 3. Run the App

1. In the project root, run `flutter pub get` to fetch dependencies.
2. *(Optional)* Run `flutter analyze --no-pub` to ensure your environment aligns with strict pedantic rules.
3. Start the app: `flutter run`.

---

## 🏗️ Architecture Architecture

### Vector Retrieval & Data
- `places.json` & `events.json` are streamed down or queried from Firestore.
- Uses **Hive** (`TripCacheService`) for ultra-fast, offline-capable local storage of cached plans and profiles.

### Provider State Management
- `AppModeProvider`: Controls Light/Dark/System level aesthetics.
- `VibeThemeProvider`: Controls the Batik gradient logic across the `MaterialApp`.
- `LocaleProvider`: Handles hot-swapping 6 different international languages.

## 🤝 Contributing
Features, bug fixes, and data expansions (particularly deep "Hidden Gem" coordinates) are highly welcome! Make sure to follow the `AppTheme` aesthetic guidelines when building new UI elements.

---
*Built for the magic of Sri Lanka.* 🌴
