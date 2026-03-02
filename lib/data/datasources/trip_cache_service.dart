import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/trip_plan_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cache Read Result
// ─────────────────────────────────────────────────────────────────────────────

enum CacheReadResult { fresh, stale, miss }

class CachedPlanResult {
  final TripPlan? plan;
  final CacheReadResult state;
  const CachedPlanResult({required this.state, this.plan});

  bool get hasData => plan != null;
}

// ─────────────────────────────────────────────────────────────────────────────
// TripMe.ai Offline Cache Service
//
// Privacy guarantee:
//   • ONLY stores: origin city (string), destination city (string), days (int),
//     budget (int), style (string), interests (list), transport (string), date (string).
//   • NEVER stores: raw GPS coordinates, device ID, account info, or any PII.
//   • Saved plans are user-initiated only (explicit bookmark action).
// ─────────────────────────────────────────────────────────────────────────────

class TripCacheService {
  static const String _lastPlanBox = 'tripme_last_plans';
  static const String _savedPlansBox = 'tripme_saved_plans';
  static const Duration _cacheTtl = Duration(days: 7);

  // ─── Initialisation ─────────────────────────────────────────────────────

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_lastPlanBox);
    await Hive.openBox<String>(_savedPlansBox);
  }

  // ─── Deterministic Cache Key ─────────────────────────────────────────────
  // Hash of all request params so different trips never collide.

  static String buildCacheKey({
    required String origin,
    required String destination,
    required int days,
    required int budgetLkr,
    required String style,
    required List<String> interests,
    required String transport,
    required String startDate,
  }) {
    final raw =
        '${origin.toLowerCase()}|${destination.toLowerCase()}|$days|$budgetLkr|${style.toLowerCase()}|${interests.join(",").toLowerCase()}|${transport.toLowerCase()}|$startDate';
    // Lightweight deterministic hash using dart:convert only (no external dep)
    final bytes = utf8.encode(raw);
    int hash = 0;
    for (final b in bytes) {
      hash = ((hash << 5) - hash + b) & 0xFFFFFFFF;
    }
    return base64Url.encode(utf8.encode(hash.toString())).replaceAll('=', '').substring(0, 12);
  }

  // ─── Last-Plan Cache (auto TTL + schema versioning) ──────────────────────

  static Future<void> cacheLastPlan(TripPlan plan, String cacheKey) async {
    try {
      final box = Hive.box<String>(_lastPlanBox);
      final payload = json.encode(plan.toJson());
      await box.put(cacheKey, payload);
    } catch (e) {
      debugPrint('[TripCache] Write error (non-fatal): $e');
    }
  }

  static CachedPlanResult getLastPlan(String cacheKey) {
    try {
      final box = Hive.box<String>(_lastPlanBox);
      final raw = box.get(cacheKey);
      if (raw == null) return const CachedPlanResult(state: CacheReadResult.miss);

      final data = json.decode(raw) as Map<String, dynamic>;
      final plan = TripPlan.fromJson(data);

      // Schema version check
      if (plan.schemaVersion < TripPlan.currentSchemaVersion) {
        box.delete(cacheKey); // evict incompatible schema
        return const CachedPlanResult(state: CacheReadResult.stale);
      }

      // TTL check
      if (plan.cachedAt != null &&
          DateTime.now().difference(plan.cachedAt!) > _cacheTtl) {
        box.delete(cacheKey);
        return const CachedPlanResult(state: CacheReadResult.stale);
      }

      return CachedPlanResult(state: CacheReadResult.fresh, plan: plan);
    } catch (e) {
      debugPrint('[TripCache] Read error (non-fatal): $e');
      return const CachedPlanResult(state: CacheReadResult.miss);
    }
  }

  // ─── Saved Plans (user-explicit, no TTL) ─────────────────────────────────

  static Future<String> savePlan(TripPlan plan) async {
    try {
      final box = Hive.box<String>(_savedPlansBox);
      final id = '${plan.destination}_${DateTime.now().millisecondsSinceEpoch}';
      final payload = json.encode(plan.toJson());
      await box.put(id, payload);
      return id;
    } catch (e) {
      debugPrint('[TripCache] Save error (non-fatal): $e');
      return '';
    }
  }

  static List<TripPlan> getAllTrips() {
    try {
      final box = Hive.box<String>(_lastPlanBox);
      final plans = <TripPlan>[];
      for (final key in box.keys) {
        final raw = box.get(key);
        if (raw != null) {
          try {
            plans.add(TripPlan.fromJson(json.decode(raw)));
          } catch (_) {}
        }
      }
      // Newest first
      plans.sort((a, b) => (b.cachedAt ?? DateTime(0)).compareTo(a.cachedAt ?? DateTime(0)));
      return plans;
    } catch (e) {
      debugPrint('[TripCache] GetAll error (non-fatal): $e');
      return [];
    }
  }

  static List<({String id, TripPlan plan})> getSavedPlans() {
    try {
      final box = Hive.box<String>(_savedPlansBox);
      final entries = <({String id, TripPlan plan})>[];
      for (final key in box.keys) {
        final raw = box.get(key as String);
        if (raw == null) continue;
        try {
          entries.add((id: key, plan: TripPlan.fromJson(json.decode(raw))));
        } catch (_) {}
      }
      // Newest first
      entries.sort((a, b) =>
          (b.plan.cachedAt ?? DateTime(0)).compareTo(a.plan.cachedAt ?? DateTime(0)));
      return entries;
    } catch (e) {
      debugPrint('[TripCache] List error (non-fatal): $e');
      return [];
    }
  }

  static Future<void> deleteSavedPlan(String id) async {
    try {
      await Hive.box<String>(_savedPlansBox).delete(id);
    } catch (e) {
      debugPrint('[TripCache] Delete error (non-fatal): $e');
    }
  }

  // ─── Stats ───────────────────────────────────────────────────────────────

  static int get savedPlanCount {
    try {
      return Hive.box<String>(_savedPlansBox).length;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> clearAll() async {
    try {
      await Hive.box<String>(_lastPlanBox).clear();
      await Hive.box<String>(_savedPlansBox).clear();
    } catch (e) {
      debugPrint('[TripCache] ClearAll error (non-fatal): $e');
    }
  }
}
