import 'package:flutter/material.dart';
import '../services/itinerary_service.dart';
import '../services/place_service.dart';
import '../models/place.dart';
import 'budget_screen.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  double _hoursAvailable = 8.0;
  String _transportMode = 'Car';
  List<Map<String, dynamic>> _itinerary = [];
  bool _isLoading = true;
  List<Place> _allPlaces = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final places = await PlaceService.loadPlaces();
    setState(() {
      _allPlaces = places;
      _isLoading = false;
      _generateItinerary();
    });
  }

  void _generateItinerary() {
    setState(() {
      _itinerary = ItineraryService.generateItinerary(
        places: _allPlaces,
        hoursAvailable: _hoursAvailable,
        transportMode: _transportMode,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Plan Your Trip"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildControls(),
                Expanded(
                  child: _itinerary.isEmpty
                      ? const Center(child: Text("No places fit your schedule."))
                      : _buildItineraryList(),
                ),
              ],
            ),
      floatingActionButton: _itinerary.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                final List<Place> selectedPlaces =
                    _itinerary.map((e) => e['placeObj'] as Place).toList();
                
                // Estimate total distance based on travel hours (backwards calculation for now)
                double totalDistance = 0;
                for (var item in _itinerary) {
                  totalDistance += (item['placeObj'] as Place).distance ?? 0;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BudgetScreen(
                      selectedPlaces: selectedPlaces,
                      totalDistance: totalDistance,
                      transportMode: _transportMode,
                    ),
                  ),
                );
              },
              label: const Text("View Budget"),
              icon: const Icon(Icons.account_balance_wallet_outlined),
            )
          : null,
    );
  }

  Widget _buildControls() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 8),
                const Text("Hours Available:"),
                Expanded(
                  child: Slider(
                    value: _hoursAvailable,
                    min: 1,
                    max: 24,
                    divisions: 23,
                    label: _hoursAvailable.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _hoursAvailable = value;
                      });
                      _generateItinerary();
                    },
                  ),
                ),
                Text("${_hoursAvailable.round()}h"),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.directions_car),
                const SizedBox(width: 8),
                const Text("Transport Mode:"),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _transportMode,
                  items: ['Car', 'Bike', 'Tuk-Tuk', 'Bus'].map((mode) {
                    return DropdownMenuItem(value: mode, child: Text(mode));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _transportMode = value;
                      });
                      _generateItinerary();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItineraryList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), // Extra bottom padding for FAB
      itemCount: _itinerary.length,
      itemBuilder: (context, index) {
        final item = _itinerary[index];
        final isLast = index == _itinerary.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 80,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['place'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        "Visit: ${item['spendTime']}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.drive_eta_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        "Travel: ${item['travelTime']}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
