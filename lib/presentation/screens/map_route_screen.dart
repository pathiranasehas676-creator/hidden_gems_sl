import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/trip_plan_model.dart';

class MapRouteScreen extends StatefulWidget {
  final TripPlan plan;

  const MapRouteScreen({super.key, required this.plan});

  @override
  State<MapRouteScreen> createState() => _MapRouteScreenState();
}

class _MapRouteScreenState extends State<MapRouteScreen> {
  late GoogleMapController _controller;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initMarkersAndRoutes();
  }

  void _initMarkersAndRoutes() {
    List<LatLng> points = [];
    int counter = 1;

    for (var day in widget.plan.itinerary) {
      for (var item in day.items) {
        if (item.lat != 0 && item.lng != 0) {
          final pos = LatLng(item.lat, item.lng);
          points.add(pos);
          
          _markers.add(
            Marker(
              markerId: MarkerId("${item.title}_$counter"),
              position: pos,
              infoWindow: InfoWindow(
                title: item.title, 
                snippet: "Day ${day.day} • ${item.time}",
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                item.isHotel ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueOrange
              ),
            ),
          );
          counter++;
        }
      }
    }

    if (points.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId("trip_route"),
          points: points,
          color: AppTheme.accentOchre,
          width: 4,
          geodesic: true,
        ),
      );
    }
  }

  void _fitBounds() {
    if (_markers.isEmpty) return;

    double? minLat, maxLat, minLng, maxLng;

    for (var marker in _markers) {
      if (minLat == null || marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (maxLat == null || marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (minLng == null || marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (maxLng == null || marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }

    _controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat!, minLng!),
          northeast: LatLng(maxLat!, maxLng!),
        ),
        70.0, // Padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Visual Route", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black54, Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(7.8731, 80.7718), zoom: 7),
            onMapCreated: (controller) {
              _controller = controller;
              Future.delayed(const Duration(milliseconds: 500), _fitBounds);
            },
            markers: _markers,
            polylines: _polylines,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: true,
            style: _mapStyle,
          ),
          
          // Bottom Info Card
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.premiumShadow,
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.explore_outlined, color: AppTheme.accentOchre),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Journey Visualizer",
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${widget.plan.itinerary.length} Days across ${widget.plan.destination}",
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _fitBounds,
                    icon: const Icon(Icons.center_focus_strong, size: 18),
                    label: const Text("FOCUS"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOchre,
                      foregroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Minimalist Travel Map Style (optional JSON string for Google Maps)
  final String? _mapStyle = null; 
}
