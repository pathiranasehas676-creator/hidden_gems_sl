import firebase_admin
from firebase_admin import credentials, firestore
import json
import os
import re

# --- Configuration ---
FIRESTORE_PROJECT_ID = "hidden-gems-sl" # Replace with your project ID
SERVICE_ACCOUNT_PATH = "serviceAccountKey.json" # Ensure this file exists in the backend/ directory

def initialize_db():
    try:
        if os.path.exists(SERVICE_ACCOUNT_PATH):
            cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
            firebase_admin.initialize_app(cred)
        else:
            print(f"WARNING: {SERVICE_ACCOUNT_PATH} not found. Attempting default credentials...")
            firebase_admin.initialize_app()
        return firestore.client()
    except Exception as e:
        print(f"Error initializing Firestore: {e}")
        return None

def migrate_places(db):
    try:
        places_path = os.path.join("..", "assets", "places.json")
        if not os.path.exists(places_path):
            print(f"Places file not found at {places_path}")
            return

        with open(places_path, "r") as f:
            places = json.load(f)

        batch = db.batch()
        for place in places:
            doc_ref = db.collection("places").document(str(place["id"]))
            batch.set(doc_ref, place)
        
        batch.commit()
        print(f"Successfully migrated {len(places)} places to Firestore.")
    except Exception as e:
        print(f"Error migrating places: {e}")

def migrate_events(db):
    try:
        # Since we can't easily parse complex Dart lists in Python without a parser,
        # we'll extract using regex for basic map-like structures.
        events_path = os.path.join("..", "lib", "data", "datasources", "sri_lanka_event_dataset.dart")
        if not os.path.exists(events_path):
            print(f"Events file not found at {events_path}")
            return

        with open(events_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Simple regex to find blocks that look like { "name": ..., ... }
        # Note: This is an approximation for this specific file structure
        matches = re.findall(r'\{[^{}]*?"name":\s*?".+?"[^{}]*?\}', content, re.DOTALL)
        
        migrated_count = 0
        batch = db.batch()
        
        for match in matches:
            # Clean up the match to make it valid JSON-like
            # Replace single quotes or other dart-specifics if any (though these look like JSON in the file)
            # Remove trailing commas inside maps if any
            clean_match = re.sub(r',\s*\}', '}', match)
            try:
                # We need to be careful with property names not being quoted in some dart styles, 
                # but in the provided file they ARE quoted.
                event_data = json.loads(clean_match)
                doc_id = event_data.get("name", "").lower().replace(" ", "-")
                if doc_id:
                    doc_ref = db.collection("events").document(doc_id)
                    batch.set(doc_ref, event_data)
                    migrated_count += 1
            except Exception as pe:
                print(f"Skipping malformed event match: {pe}")

        if migrated_count > 0:
            batch.commit()
        print(f"Successfully migrated {migrated_count} events to Firestore.")
        
    except Exception as e:
        print(f"Error migrating events: {e}")

if __name__ == "__main__":
    db = initialize_db()
    if db:
        print("Starting migration...")
        migrate_places(db)
        migrate_events(db)
        print("Migration complete!")
    else:
        print("Failed to initialize database. check serviceAccountKey.json.")
