import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/utils/secure_logger.dart';

class AdminApiService {
  static Future<bool> reindexKB() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/admin/kb/reindex'),
        headers: {'X-TripMe-Key': AppConfig.tripMeApiKey},
      );
      return response.statusCode == 200;
    } catch (e) {
      SecureLogger.error("KB Re-indexing failed", e);
      return false;
    }
  }

  static Future<bool> upsertPlace(Map<String, dynamic> place) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/admin/discovery/places'),
        headers: {
          'Content-Type': 'application/json',
          'X-TripMe-Key': AppConfig.tripMeApiKey,
        },
        body: json.encode(place),
      );
      return response.statusCode == 200;
    } catch (e) {
      SecureLogger.error("Place upsert failed", e);
      return false;
    }
  }

  static Future<bool> deletePlace(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/admin/discovery/places/$id'),
        headers: {'X-TripMe-Key': AppConfig.tripMeApiKey},
      );
      return response.statusCode == 200;
    } catch (e) {
      SecureLogger.error("Place delete failed", e);
      return false;
    }
  }

  static Future<bool> upsertEvent(Map<String, dynamic> event) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/admin/discovery/events'),
        headers: {
          'Content-Type': 'application/json',
          'X-TripMe-Key': AppConfig.tripMeApiKey,
        },
        body: json.encode(event),
      );
      return response.statusCode == 200;
    } catch (e) {
      SecureLogger.error("Event upsert failed", e);
      return false;
    }
  }

  static Future<bool> deleteEvent(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/admin/discovery/events/$id'),
        headers: {'X-TripMe-Key': AppConfig.tripMeApiKey},
      );
      return response.statusCode == 200;
    } catch (e) {
      SecureLogger.error("Event delete failed", e);
      return false;
    }
  }
}
