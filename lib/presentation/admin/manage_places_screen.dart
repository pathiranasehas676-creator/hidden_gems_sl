import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/batik_background.dart';
import '../../data/datasources/discovery_service.dart';
import '../../data/datasources/admin_api_service.dart';

class ManagePlacesScreen extends StatefulWidget {
  const ManagePlacesScreen({super.key});

  @override
  State<ManagePlacesScreen> createState() => _ManagePlacesScreenState();
}

class _ManagePlacesScreenState extends State<ManagePlacesScreen> {
  List<DiscoveryPlace> _places = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    setState(() => _isLoading = true);
    final places = await DiscoveryService.loadAndSortPlaces();
    setState(() {
      _places = places;
      _isLoading = false;
    });
  }

  void _showPlaceForm({DiscoveryPlace? place}) {
    final nameController = TextEditingController(text: place?.name ?? "");
    final districtController = TextEditingController(text: place?.district ?? "");
    final categoryController = TextEditingController(text: place?.category ?? "");
    final latController = TextEditingController(text: place?.lat.toString() ?? "");
    final lngController = TextEditingController(text: place?.lng.toString() ?? "");
    final ratingController = TextEditingController(text: place?.rating.toString() ?? "4.5");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(place == null ? "Add Hidden Gem" : "Edit Hidden Gem", style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField("Name", nameController),
              _buildField("District", districtController),
              _buildField("Category", categoryController),
              _buildField("Latitude", latController, isNumber: true),
              _buildField("Longitude", lngController, isNumber: true),
              _buildField("Rating", ratingController, isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final Map<String, dynamic> newPlace = {
                "id": place?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                "name": nameController.text,
                "district": districtController.text,
                "category": categoryController.text,
                "lat": double.tryParse(latController.text) ?? 0.0,
                "lng": double.tryParse(lngController.text) ?? 0.0,
                "rating": double.tryParse(ratingController.text) ?? 4.5,
                "ticketRange": "Free",
                "roadType": "Paved",
                "vehicleAccess": "All",
                "riskTags": [],
                "parkingRange": "Free",
                "bestTime": "Morning",
                "facilities": [],
              };
              
              final success = await AdminApiService.upsertPlace(newPlace);
              if (success && context.mounted) {
                Navigator.pop(context);
                _loadPlaces();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOchre, foregroundColor: Colors.black),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentOchre)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      appBar: AppBar(
        title: Text("Manage Hidden Gems", style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadPlaces, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: BatikBackground(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentOchre))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _places.length,
              itemBuilder: (context, index) {
                final place = _places[index];
                return Card(
                  color: Colors.white.withValues(alpha: 0.05),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(place.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text("${place.category} • ${place.district}", style: const TextStyle(color: Colors.white60)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.white54), onPressed: () => _showPlaceForm(place: place)),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent), 
                          onPressed: () async {
                             final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E293B),
                                  title: const Text("Delete Place?", style: TextStyle(color: Colors.white)),
                                  content: Text("Are you sure you want to delete ${place.name}?", style: const TextStyle(color: Colors.white70)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Keep")),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.redAccent))),
                                  ],
                                ),
                             );
                             if (confirm == true) {
                               final success = await AdminApiService.deletePlace(place.id);
                               if (success) _loadPlaces();
                             }
                          }
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlaceForm(),
        backgroundColor: AppTheme.accentOchre,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
