import 'package:flutter/material.dart';
import '../services/favorite_service.dart';
import '../services/place_service.dart';
import '../models/place.dart';
import 'place_details_screen.dart';
import 'privacy_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Place> _favoritePlaces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final favoriteIds = await FavoriteService.getFavorites();
    final allPlaces = await PlaceService.loadPlaces();
    
    setState(() {
      _favoritePlaces = allPlaces.where((p) => favoriteIds.contains(p.id)).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacySettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProfileHeader(),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Favorite Gems",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: _favoritePlaces.isEmpty
                      ? _buildEmptyState()
                      : _buildFavoritesList(),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            "Explorer",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            "Sri Lanka Traveler",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No favorites yet. Start exploring!"),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _favoritePlaces.length,
      itemBuilder: (context, index) {
        final place = _favoritePlaces[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.place)),
            title: Text(place.name),
            subtitle: Text(place.district),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PlaceDetailsScreen(place: place)),
              );
              _loadFavorites(); // Refresh after returning
            },
          ),
        );
      },
    );
  }
}
