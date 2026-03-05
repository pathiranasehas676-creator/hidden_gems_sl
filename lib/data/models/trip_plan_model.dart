// ignore_for_file: non_constant_identifier_names

class TripPlan {
  static const int currentSchemaVersion = 6;

  final int schemaVersion;
  final TripSummary tripSummary;
  final List<ItineraryDay> itinerary;
  final PlanBItem planB;
  final StyleVariants styleVariants;
  final String safetyTip;
  final String humanText;
  final int verifiedScore;
  final List<String> kbCitations;
  final DateTime? cachedAt;
  String? offlineMapPath;
  final List<Expense> realizedExpenses;

  TripPlan({
    this.schemaVersion = TripPlan.currentSchemaVersion,
    required this.tripSummary,
    required this.itinerary,
    required this.planB,
    required this.styleVariants,
    required this.safetyTip,
    required this.humanText,
    required this.verifiedScore,
    required this.kbCitations,
    this.cachedAt,
    this.offlineMapPath,
    List<Expense>? realizedExpenses,
  }) : realizedExpenses = realizedExpenses ?? [];

  // Convenience getters for backward compatibility
  String get origin => tripSummary.fromCity;
  String get destination => tripSummary.destinationCity;
  List<ItineraryDay> get days => itinerary;
  double get confidence => verifiedScore / 100.0;
  List<String> get sources => kbCitations;
  List<PlanBItem> get planBRain => [planB];
  List<String> get tips => [safetyTip];

  factory TripPlan.fromJson(Map<String, dynamic> json) {
    return TripPlan(
      tripSummary: TripSummary.fromJson(json['trip_summary'] ?? {}),
      itinerary: (json['itinerary'] as List? ?? [])
          .map((d) => ItineraryDay.fromJson(d))
          .toList(),
      planB: PlanBItem.fromJson(json['plan_b'] ?? json['plan_b_rain']?[0] ?? {}),
      styleVariants: StyleVariants.fromJson(json['style_variants'] ?? {}),
      safetyTip: json['safety_tip'] ?? (json['tips'] as List?)?.first ?? '',
      humanText: json['human_text'] ?? '',
      verifiedScore: json['verified_score'] ?? ((json['confidence'] ?? 0.0) * 100).toInt(),
      kbCitations: List<String>.from(json['kb_citations'] ?? json['sources'] ?? []),
      cachedAt: json['cached_at'] != null
          ? DateTime.tryParse(json['cached_at'])
          : DateTime.now(),
      schemaVersion: json['schema_version'] as int? ?? 1,
      offlineMapPath: json['offline_map_path'] as String?,
      realizedExpenses: (json['realized_expenses'] as List? ?? [])
          .map((e) => Expense.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_summary': tripSummary.toJson(),
      'itinerary': itinerary.map((d) => d.toJson()).toList(),
      'plan_b': planB.toJson(),
      'style_variants': styleVariants.toJson(),
      'safety_tip': safetyTip,
      'human_text': humanText,
      'verified_score': verifiedScore,
      'kb_citations': kbCitations,
      'cached_at': cachedAt?.toIso8601String(),
      'schema_version': schemaVersion,
      'offline_map_path': offlineMapPath,
      'realized_expenses': realizedExpenses.map((e) => e.toJson()).toList(),
    };
  }
}

class StyleVariants {
  final String compact;
  final String narrative;

  StyleVariants({required this.compact, required this.narrative});

  factory StyleVariants.fromJson(Map<String, dynamic> json) {
    return StyleVariants(
      compact: json['compact'] ?? '',
      narrative: json['narrative'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'compact': compact,
        'narrative': narrative,
      };
}

class TripSummary {
  final String fromCity;
  final String destinationCity;
  final int days;
  final String startDate;
  final String groupType;
  final String pace;
  final String style;
  final int userBudgetLkr;

  TripSummary({
    required this.fromCity,
    required this.destinationCity,
    required this.days,
    required this.startDate,
    required this.groupType,
    required this.pace,
    required this.style,
    required this.userBudgetLkr,
  });

  factory TripSummary.fromJson(Map<String, dynamic> json) {
    return TripSummary(
      fromCity: json['from_city'] ?? '',
      destinationCity: json['destination_city'] ?? '',
      days: _toInt(json['days'] ?? 1),
      startDate: json['start_date'] ?? '',
      groupType: json['group_type'] ?? '',
      pace: json['pace'] ?? '',
      style: json['style'] ?? '',
      userBudgetLkr: _toInt(json['user_budget_lkr'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'from_city': fromCity,
        'destination_city': destinationCity,
        'days': days,
        'start_date': startDate,
        'group_type': groupType,
        'pace': pace,
        'style': style,
        'user_budget_lkr': userBudgetLkr,
      };
}

class ItineraryDay {
  final int day;
  final String dayTheme;
  final List<ItineraryItem> items;

  ItineraryDay({
    required this.day,
    required this.dayTheme,
    required this.items,
  });

  factory ItineraryDay.fromJson(Map<String, dynamic> json) {
    return ItineraryDay(
      day: _toInt(json['day'] ?? 1),
      dayTheme: json['day_theme'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((i) => ItineraryItem.fromJson(i))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'day_theme': dayTheme,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

class ItineraryItem {
  final String time;
  final String title;
  final String type; // transport|attraction|food|rest|hotel|shopping|nature|culture
  final int durationMin;
  final int costLkr;
  final double lat;
  final double lng;
  final String notes;

  ItineraryItem({
    required this.time,
    required this.title,
    required this.type,
    required this.durationMin,
    required this.costLkr,
    required this.lat,
    required this.lng,
    required this.notes,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      time: json['time'] ?? '08:00',
      title: json['title'] ?? '',
      type: json['type'] ?? 'attraction',
      durationMin: _toInt(json['duration_min'] ?? 0),
      costLkr: _toInt(json['cost_lkr'] ?? 0),
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time,
        'title': title,
        'type': type,
        'duration_min': durationMin,
        'cost_lkr': costLkr,
        'lat': lat,
        'lng': lng,
        'notes': notes,
      };

  bool get isFood => type == 'food';
  bool get isRest => type == 'rest';
  bool get isTransport => type == 'transport';
  bool get isHotel => type == 'hotel';
}

class BudgetBreakdown {
  final int transport;
  final int stay;
  final int food;
  final int tickets;
  final int misc;
  final int buffer10Percent;
  final int total;

  BudgetBreakdown({
    required this.transport,
    required this.stay,
    required this.food,
    required this.tickets,
    required this.misc,
    required this.buffer10Percent,
    required this.total,
  });

  int get entryFees => tickets;
  int get contingency => buffer10Percent;

  factory BudgetBreakdown.fromJson(Map<String, dynamic> json) {
    return BudgetBreakdown(
      transport: _toInt(json['transport'] ?? 0),
      stay: _toInt(json['stay'] ?? 0),
      food: _toInt(json['food'] ?? 0),
      tickets: _toInt(json['tickets'] ?? 0),
      misc: _toInt(json['misc'] ?? 0),
      buffer10Percent: _toInt(json['buffer_10_percent'] ?? 0),
      total: _toInt(json['total'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'transport': transport,
        'stay': stay,
        'food': food,
        'tickets': tickets,
        'misc': misc,
        'buffer_10_percent': buffer10Percent,
        'total': total,
      };
}

class PlanBItem {
  final String title;
  final String reason;
  final double lat;
  final double lng;

  PlanBItem({
    required this.title,
    required this.reason,
    required this.lat,
    required this.lng,
  });

  factory PlanBItem.fromJson(Map<String, dynamic> json) {
    return PlanBItem(
      title: json['title'] ?? '',
      reason: json['reason'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'reason': reason,
        'lat': lat,
        'lng': lng,
      };
}

class ComfortUpgrade {
  final String title;
  final int extraCostLkr;
  final String why;

  ComfortUpgrade({
    required this.title,
    required this.extraCostLkr,
    required this.why,
  });

  factory ComfortUpgrade.fromJson(Map<String, dynamic> json) {
    return ComfortUpgrade(
      title: json['title'] ?? '',
      extraCostLkr: _toInt(json['extra_cost_lkr'] ?? 0),
      why: json['why'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'extra_cost_lkr': extraCostLkr,
        'why': why,
      };
}

class Expense {
  final String id;
  final String title;
  final int amountLkr;
  final String category; // food, transport, tickets, misc
  final DateTime timestamp;

  Expense({
    required this.id,
    required this.title,
    required this.amountLkr,
    required this.category,
    required this.timestamp,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      amountLkr: _toInt(json['amount_lkr'] ?? 0),
      category: json['category'] ?? 'misc',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount_lkr': amountLkr,
    'category': category,
    'timestamp': timestamp.toIso8601String(),
  };
}

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
