import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/place.dart';
import '../services/favorite_service.dart';
import 'safety_screen.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Place place;
  const PlaceDetailsScreen({super.key, required this.place});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final status = await FavoriteService.isFavorite(widget.place.id);
    setState(() {
      _isFavorite = status;
    });
  }

  Future<void> _toggleFavorite() async {
    await FavoriteService.toggleFavorite(widget.place.id);
    _checkFavoriteStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? "Removed from favorites" : "Added to favorites"),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _launchMap(String mode) async {
    final url = 'google.navigation:q=${widget.place.lat},${widget.place.lng}&mode=$mode';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final webUrl = 'https://www.google.com/maps/dir/?api=1&destination=${widget.place.lat},${widget.place.lng}&travelmode=${mode == "d" ? "driving" : mode == "b" ? "bicycling" : "walking"}';
      await launchUrl(Uri.parse(webUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
                color: _isFavorite ? Colors.red : Colors.white,
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.place.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10, color: Colors.black)])),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                  ),
                ),
                child: const Icon(Icons.image, size: 100, color: Colors.white24),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoChip(Icons.star, widget.place.rating.toString(), Colors.amber),
                      _buildInfoChip(Icons.category, widget.place.category, Colors.blueGrey),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text("Quick Info", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.terrain, "Road Type", widget.place.roadType),
                  _buildDetailRow(Icons.directions_car, "Access", widget.place.vehicleAccess),
                  _buildDetailRow(Icons.access_time, "Best Time", widget.place.bestTime),
                  _buildDetailRow(Icons.attach_money, "Tickets", widget.place.ticketRange),
                  
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Safety & Risks", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SafetyScreen(district: "Colombo"), // Default or parse from address
                            ),
                          );
                        },
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text("Regional Info"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: widget.place.riskTags.map((tag) => Chip(
                      label: Text(tag, style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.redAccent.withOpacity(0.8),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text("Get Directions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTransportBtn(Icons.drive_eta, "Car", "d")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTransportBtn(Icons.electric_bike, "Bike", "b")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTransportBtn(Icons.directions_walk, "Walk", "w")),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text("$title: ", style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildTransportBtn(IconData icon, String label, String mode) {
    return ElevatedButton.icon(
      onPressed: () => _launchMap(mode),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
