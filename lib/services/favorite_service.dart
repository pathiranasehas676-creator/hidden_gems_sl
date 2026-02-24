import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static const String _key = 'favorite_places';

  static Future<bool> isFavorite(String placeId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites = prefs.getStringList(_key) ?? [];
    return favorites.contains(placeId);
  }

  static Future<void> toggleFavorite(String placeId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_key) ?? [];
    
    if (favorites.contains(placeId)) {
      favorites.remove(placeId);
    } else {
      favorites.add(placeId);
    }
    
    await prefs.setStringList(_key, favorites);
  }

  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }
}
