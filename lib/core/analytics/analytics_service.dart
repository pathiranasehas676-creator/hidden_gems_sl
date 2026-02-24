import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    await _analytics.logEvent(name: name, parameters: parameters);
    debugPrint("[Analytics] Logged Event: $name | Params: $parameters");
  }

  Future<void> logPlanGenerated({
    required String destination,
    required String style,
    required int days,
    required int verifiedScore,
  }) async {
    await logEvent('plan_generated', parameters: {
      'destination': destination,
      'style': style,
      'days': days,
      'verified_score': verifiedScore,
    });
  }

  Future<void> logPremiumPurchased(String productId) async {
    await logEvent('premium_purchased', parameters: {
      'product_id': productId,
    });
  }

  Future<void> logLandmarkScanUsed(String landmark) async {
    await logEvent('landmark_scan_used', parameters: {
      'landmark_name': landmark,
    });
  }

  Future<void> logPlanBTriggered(String city) async {
    await logEvent('plan_b_clicked', parameters: {
      'city': city,
    });
  }

  Future<void> setUserProperties({required String userId, required String role}) async {
    await _analytics.setUserId(id: userId);
    await _analytics.setUserProperty(name: 'user_role', value: role);
  }
}
