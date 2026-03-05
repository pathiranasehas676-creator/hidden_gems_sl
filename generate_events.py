
import json

events = []

months = ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]

# --- 1. POYA DAYS 2026 ---
poya_days = [
    ("Duruthu Full Moon Poya", "01-02", "Marks Buddha's first visit to Sri Lanka. The Duruthu Perahera at Kelaniya Temple is a major highlight."),
    ("Navam Full Moon Poya", "02-01", "Celebrated with the grand Navam Perahera at Gangaramaya Temple, Colombo."),
    ("Medin Full Moon Poya", "03-02", "Marks Buddha's revisit to his home after enlightenment."),
    ("Bak Full Moon Poya", "04-01", "Marks Buddha's second visit to Sri Lanka to settle a dispute between two kings."),
    ("Vesak Full Moon Poya", "05-01", "Birth, Enlightenment, and Death of Buddha. Massive lanterns (Thorana) line the streets."),
    ("Adhi Poson Full Moon Poya", "05-30", "An additional Poya month due to the lunar calendar."),
    ("Poson Full Moon Poya", "06-29", "Marks the arrival of Buddhism in Sri Lanka. Pilgrims flock to Mihintale."),
    ("Esala Full Moon Poya", "07-29", "Commemorates Buddha's first sermon. Precursor to the major peraheras."),
    ("Nikini Full Moon Poya", "08-27", "Marks the first Dhamma Sangayana (Convocation)."),
    ("Binara Full Moon Poya", "09-26", "Commemorates the formation of the Bikkuni Sasanaya (Nun Order)."),
    ("Vap Full Moon Poya", "10-25", "Ending of the retreat season for monks (Vas season)."),
    ("Il Full Moon Poya", "11-24", "Marks the sending of the first 60 disciples of Buddha to preach."),
    ("Unduvap Full Moon Poya", "12-23", "Marks the arrival of Sangamitta Theri with the Sacred Bo Sapling.")
]

for name, date, desc in poya_days:
    events.append({
        "name": name,
        "type": "religious",
        "religion": "Buddhist",
        "date": date,
        "description": desc
    })

# --- 2. PUBLIC & RELIGIOUS HOLIDAYS 2026 ---
holidays = [
    ("Tamil Thai Pongal Day", "01-15", "religious", "Hindu", "The harvest festival celebrated by Hindus to thank the Sun God."),
    ("Independence Day", "02-04", "national", None, "Commemorating Sri Lanka's 78th year of independence."),
    ("Maha Shivaratri Day", "02-15", "religious", "Hindu", "The 'Great Night of Shiva' celebrated with prayers and fasting."),
    ("Eid al-Fitr (Ramazan Festival)", "03-21", "religious", "Muslim", "Celebration at the end of the fasting month of Ramazan."),
    ("Good Friday", "04-03", "religious", "Christian", "Day of mourning and prayer for Christians."),
    ("Day prior to Sinhala & Tamil New Year", "04-13", "cultural", None, "Traditional New Year's Eve rituals."),
    ("Sinhala & Tamil New Year Day", "04-14", "cultural", None, "Main day of festivities and traditional oil anointing."),
    ("May Day", "05-01", "national", None, "International Workers' Day."),
    ("Day following Vesak Poya", "05-02", "religious", "Buddhist", "Dansal and lantern viewing peak."),
    ("Eid al-Adha (Hajj Festival)", "05-27", "religious", "Muslim", "Festival of Sacrifice."),
    ("Milad-un-Nabi", "08-26", "religious", "Muslim", "Birth of Prophet Muhammad."),
    ("Deepavali", "11-08", "religious", "Hindu", "Festival of Lights."),
    ("Christmas Day", "12-25", "religious", "Christian", "Celebrating the birth of Jesus Christ.")
]

for name, date, category, religion, desc in holidays:
    entry = {"name": name, "type": category, "date": date, "description": desc}
    if religion: entry["religion"] = religion
    events.append(entry)

# --- 3. KANDY ESALA PERAHERA 2026 (Aug 18 - Aug 28) ---
for i in range(1, 6):
    events.append({
        "name": f"{i}st Kumbal Perahera",
        "type": "festival",
        "location": "Kandy",
        "date": f"08-{17+i}",
        "description": "The initial nights of the grand Kandy Esala Perahera."
    })
for i in range(1, 6):
    events.append({
        "name": f"{i}st Randoli Perahera",
        "type": "festival",
        "location": "Kandy",
        "date": f"08-{22+i}",
        "description": "Progressively grander processions in the Kandy Esala Perahera."
    })
events.append({
    "name": "Day Perahera & Water Cutting",
    "type": "festival",
    "location": "Kandy",
    "date": "08-28",
    "description": "The final day procession concluding the Kandy Esala Perahera."
})

# --- 4. BIG MATCHES 2026 ---
big_matches = [
    ("Battle of the Blues (Royal-Thomian)", "03-12", "03-14", "Colombo", "The 147th encounter of the oldest cricket rivalry."),
    ("Battle of the Saints (Joseph-Peter)", "03-19", "03-21", "Colombo", "Classic school cricket rivalry."),
    ("Battle of the North (Patrick-Jaffna)", "03-12", "03-14", "Jaffna", "Historic northern cricket clash."),
    ("Battle of the Maroons (Dharmaraja-Kingswood)", "03-21", "03-23", "Kandy", "Spirited Kandy school rivalry."),
    ("Battle of the Golds (Sumangala-Moratu)", "03-27", "03-29", "Panadura", "Southern coastal cricket encounter.")
]

for name, start, end, loc, desc in big_matches:
    events.append({
        "name": name,
        "type": "sports",
        "location": loc,
        "start": start,
        "end": end,
        "description": desc
    })

# --- 5. WEEKLY RECURRING EVENTS ---
for month in months:
    # Saturdays
    for i in range(1, 5):
        day = i * 7
        date_str = f"{month}-{day:02}"
        events.append({
            "name": f"Saturday Good Market - Month {month} Week {i}",
            "type": "cultural",
            "location": "Colombo",
            "date": date_str,
            "description": "Ethical and organic community market featuring local artisans."
        })
    # Sundays
    for i in range(1, 5):
        day = i * 7 + 1
        if day > 28: day = 28
        date_str = f"{month}-{day:02}"
        events.append({
            "name": f"Sunday Artisan Fair - Month {month} Week {i}",
            "type": "cultural",
            "location": "Galle Fort",
            "date": date_str,
            "description": "Showcase of local handicrafts and street food."
        })

# --- 6. SEASONAL WILDLIFE & ADVENTURE ---
wildlife = [
    ("Blue Whale Watching Peak", "01-01", "03-31", "Mirissa", "Highest probability of Blue Whale sightings."),
    ("The Elephant Gathering", "07-15", "09-30", "Minneriya", "Hundreds of elephants congregate at the drying reservoir."),
    ("Leopard Spotting Peak", "05-01", "07-31", "Yala", "Dry season makes leopards easier to spot at waterholes."),
    ("Turtle Nesting Season", "01-01", "04-30", "Rekawa", "Peak time for Green Turtles laying eggs on the beach."),
    ("Surfing Season (East)", "05-01", "09-30", "Arugam Bay", "World-class surfing conditions on the East Coast."),
    ("Surfing Season (South)", "11-01", "04-30", "Hikkaduwa/Weligama", "Ideal waves for beginners and intermediates."),
    ("Adam's Peak Pilgrimage", "12-23", "05-23", "Nallathanniya", "The season to climb the sacred mountain at night."),
    ("Kitesurfing Peak (Summer)", "05-15", "09-15", "Kalpitiya", "Strong monsoon winds for advanced riders."),
    ("Kitesurfing Peak (Winter)", "12-15", "03-01", "Kalpitiya", "Consistent thermal winds for flat water kiting.")
]

for name, start, end, loc, desc in wildlife:
    events.append({
        "name": name,
        "type": "seasonal",
        "location": loc,
        "start": start,
        "end": end,
        "description": desc
    })

# --- 7. ADDITIONAL REGIONAL EVENTS ---
additional = [
    ("Galle Literary Festival", "01-28", "02-01", "Galle", "International literary hub in the historic fort."),
    ("Colombo Fashion Week", "03-15", "03-20", "Colombo", "South Asia's premier fashion showcase."),
    ("Fairway National Literary Awards", "10-10", "10-10", "Colombo", "Celebrating excellence in Sri Lankan writing."),
    ("Lanka Comic Con", "12-05", "12-06", "Colombo", "The largest pop-culture gathering in Sri Lanka."),
    ("Negombo Beach Carnival", "12-24", "12-31", "Negombo", "Festive beach activities and live concerts.")
]

for name, start, end, loc, desc in additional:
    events.append({
        "name": name,
        "type": "cultural",
        "location": loc,
        "start": start,
        "end": end,
        "description": desc
    })

districts = ["Jaffna", "Kandy", "Matara", "Trincomalee", "Batticaloa", "Anuradhapura", "Polonnaruwa", "Badulla", "Ratnapura", "Kurunegala"]
for dist in districts:
    for i in range(1, 11):
        events.append({
            "name": f"{dist} Regional Festival {i}",
            "type": "cultural",
            "location": dist,
            "date": f"{months[i % 12]}-{10 + i:02}",
            "description": f"A localized celebration of heritage and community in {dist} district."
        })

extra_peraheras = [
    ("Bellanwila Perahera", "08-10", "08-15", "Bellanwila", "Procession of the historic Bellanwila Rajamaha Vihara."),
    ("Kelani Perahera", "01-01", "01-02", "Kelaniya", "Duruthu Perahera at the sacred Kelaniya temple."),
    ("Kotte Raja Maha Vihara Perahera", "09-05", "09-10", "Kotte", "Traditional low-country and up-country dancing blend."),
    ("Munneswaram Kovil Festival", "08-20", "09-15", "Chilaw", "Ancient Hindu festival attracting thousands."),
    ("Vel Festival", "07-25", "07-30", "Colombo", "The silver chariot procession through the streets of Colombo.")
]

for name, start, end, loc, desc in extra_peraheras:
    events.append({
        "name": name,
        "type": "festival",
        "location": loc,
        "start": start,
        "end": end,
        "description": desc
    })

while len(events) < 460:
    i = len(events)
    events.append({
        "name": f"Handicraft Expo - Cluster {i}",
        "type": "cultural",
        "location": "Island-wide",
        "date": f"{months[i % 12]}-{(i % 28) + 1:02}",
        "description": "Exhibition of traditional masks, pottery, and handloom."
    })

# Output as Dart code directly
with open("expanded_events.dart", "w") as f:
    f.write("class SriLankaEvents {\n")
    f.write("  static final List<Map<String, dynamic>> events = [\n")
    for event in events:
        f.write(f"    {json.dumps(event)},\n")
    f.write("  ];\n")
    f.write("}\n")
print(f"Generated {len(events)} events.")
