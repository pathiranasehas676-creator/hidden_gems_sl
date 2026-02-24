import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';
import '../services/place_service.dart';
import '../services/location_service.dart';
import 'place_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isMapView = false;
  List<Place> _places = [];
  Position? _currentPosition;
  bool _isLoading = true;
  double _radius = 50.0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    final places = await PlaceService.loadPlaces();
    final position = await LocationService.getCurrentLocation();
    
    setState(() {
      _places = places;
      _currentPosition = position;
      if (position != null) {
        _places = PlaceService.filterByDistance(_places, position.latitude, position.longitude, _radius);
      }
      _isLoading = false;
    });
  }

  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    List<Place> filteredPlaces = _places.where((p) => 
      p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      p.district.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hidden Gems SL"),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () => setState(() => _isMapView = !_isMapView),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBar(),
                _buildRadiusFilter(),
                Expanded(
                  child: _isMapView
                      ? _buildMapView(filteredPlaces)
                      : _buildListView(filteredPlaces),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search gems or districts...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildListView(List<Place> places) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(place.category),
              child: Icon(_getCategoryIcon(place.category), color: Colors.white, size: 20),
            ),
            title: Text(place.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${place.district} • ${place.category}"),
                if (place.distance != null)
                  Text("${place.distance!.toStringAsFixed(1)} km away", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlaceDetailsScreen(place: place)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRadiusFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text("Radius: "),
          ...[10.0, 25.0, 50.0, 100.0].map((r) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text("${r.toInt()}km"),
              selected: _radius == r,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _radius = r;
                    _initializeData();
                  });
                }
              },
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildMapView(List<Place> places) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentPosition != null 
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) 
            : const LatLng(7.8731, 80.7718), // Center of SL
        zoom: 7,
      ),
      myLocationEnabled: true,
      markers: places.map((place) => Marker(
        markerId: MarkerId(place.id),
        position: LatLng(place.lat, place.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(place.category)),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: "${place.district} - ${place.category}",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PlaceDetailsScreen(place: place)),
          ),
        ),
      )).toSet(),
    );
  }

  Color _getCategoryColor(String category) {
    if (category.contains("Waterfall")) return Colors.blue;
    if (category.contains("Hiking")) return Colors.green;
    if (category.contains("Coastal")) return Colors.orange;
    if (category.contains("Village")) return Colors.brown;
    return Colors.teal;
  }

  IconData _getCategoryIcon(String category) {
    if (category.contains("Waterfall")) return Icons.water_drop;
    if (category.contains("Hiking")) return Icons.terrain;
    if (category.contains("Coastal")) return Icons.beach_access;
    if (category.contains("Village")) return Icons.home;
    return Icons.place;
  }

  double _getMarkerHue(String category) {
    if (category.contains("Waterfall")) return BitmapDescriptor.hueAzure;
    if (category.contains("Hiking")) return BitmapDescriptor.hueGreen;
    if (category.contains("Coastal")) return BitmapDescriptor.hueOrange;
    if (category.contains("Village")) return BitmapDescriptor.hueRose;
    return BitmapDescriptor.hueViolet;
  }
}
