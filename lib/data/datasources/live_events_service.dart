import 'sri_lanka_event_dataset.dart';

class LiveEventsService {
  /// Returns a list of structured events happening during a specific trip window
  static List<Map<String, dynamic>> getEventsForTrip(DateTime startDate, int durationDays, {List<Map<String, dynamic>>? dynamicEvents}) {
    DateTime endDate = startDate.add(Duration(days: durationDays));
    List<Map<String, dynamic>> results = [];
    
    // Prioritize dynamic events from backend, fallback to local dataset
    final sourceEvents = dynamicEvents ?? SriLankaEvents.events;

    for (var event in sourceEvents) {
      if (event.containsKey("date")) {
        // Single Day Event
        final parts = event["date"].split("-");
        try {
          DateTime eventDate = DateTime(startDate.year, int.parse(parts[0]), int.parse(parts[1]));

          // Check if event falls within trip dates (inclusive padding)
          if (eventDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
              eventDate.isBefore(endDate.add(const Duration(days: 1)))) {
            results.add(event);
          }
        } catch (_) {}
      } else if (event.containsKey("start") && event.containsKey("end")) {
        // Multi-Day or Seasonal Event
        try {
          final s = event["start"].split("-");
          final e = event["end"].split("-");

          DateTime eventStart = DateTime(startDate.year, int.parse(s[0]), int.parse(s[1]));
          DateTime eventEnd = DateTime(startDate.year, int.parse(e[0]), int.parse(e[1]));

          // Handle seasons crossing the year mark (e.g., Dec 15 to May 23)
          if (eventEnd.isBefore(eventStart)) {
            DateTime endOfYear = DateTime(startDate.year, 12, 31);
            DateTime startOfYear = DateTime(startDate.year, 1, 1);
            
            bool overlapSegment1 = startDate.isBefore(endOfYear.add(const Duration(days: 1))) && 
                                   endDate.isAfter(eventStart.subtract(const Duration(days: 1)));
                                   
            bool overlapSegment2 = startDate.isBefore(eventEnd.add(const Duration(days: 1))) && 
                                   endDate.isAfter(startOfYear.subtract(const Duration(days: 1)));
                                   
            if (overlapSegment1 || overlapSegment2) {
              results.add(event);
            }
          } else {
            bool overlap = startDate.isBefore(eventEnd.add(const Duration(days: 1))) && 
                           endDate.isAfter(eventStart.subtract(const Duration(days: 1)));
            
            if (overlap) {
              results.add(event);
            }
          }
        } catch (_) {}
      }
    }

    return results;
  }

  /// Convenience wrapper for AI payload injection specifically
  static List<String> getEventsForDates(String startDateStr, int durationDays, {List<Map<String, dynamic>>? dynamicEvents}) {
    try {
      final start = DateTime.parse(startDateStr);
      final events = getEventsForTrip(start, durationDays, dynamicEvents: dynamicEvents);
      
      return events.map((e) {
        String base = "${e['name']} (${e['type']})";
        if (e.containsKey('location')) base += " in ${e['location']}";
        base += ": ${e['description']}";
        return base;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns today's active events
  static List<Map<String, dynamic>> getTodayEvents({List<Map<String, dynamic>>? dynamicEvents}) {
    DateTime today = DateTime.now();
    return getEventsForTrip(today, 1, dynamicEvents: dynamicEvents);
  }
}
