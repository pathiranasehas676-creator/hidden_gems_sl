import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/discovery_service.dart';
import '../widgets/batik_background.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  Position? _currentPosition;
  List<DiscoveryPlace> _places = [];
  bool _isLoading = true;
  String _selectedFilter = "All";

  final List<String> _filters = ["All", "Nature", "Culture", "Waterfall", "Hiking", "Historical"];

  @override
  void initState() {
    super.initState();
    _initDiscovery();
  }

  Future<void> _initDiscovery() async {
    setState(() => _isLoading = true);
    
    _currentPosition = await DiscoveryService.getCurrentLocation();
    
    List<DiscoveryPlace> basePlaces = await DiscoveryService.loadAndSortPlaces(
      userLat: _currentPosition?.latitude,
      userLng: _currentPosition?.longitude,
      filterCategory: _selectedFilter,
    );

    _places = await DiscoveryService.getAiRecommendations(basePlaces);

    if (mounted) setState(() => _isLoading = false);
  }

  void _onFilterChanged(String filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
    });
    _initDiscovery();
  }

  void _openMapModal(DiscoveryPlace place, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(place.lat, place.lng),
                  zoom: 14,
                ),
                markers: {
                  Marker(
                    markerId: MarkerId(place.id),
                    position: LatLng(place.lat, place.lng),
                    infoWindow: InfoWindow(title: place.name),
                  )
                },
              ),
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                bottom: 32,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(place.name, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(place.district, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.silkPearl,
      body: BatikBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: AppTheme.primaryBlue,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  _currentPosition != null ? "\${l10n.nearYou}" : l10n.discovery,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildFilters(l10n),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppTheme.accentOchre)),
              )
            else if (_places.isEmpty)
              SliverFillRemaining(
                child: Center(child: Text("No places found.", style: GoogleFonts.inter(color: Colors.grey))),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final place = _places[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildPlaceCard(place, l10n),
                          ),
                        ),
                      );
                    },
                    childCount: _places.length,
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(AppLocalizations l10n) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter == 'All' ? "All" : filter),
              selected: isSelected,
              onSelected: (_) => _onFilterChanged(filter),
              selectedColor: AppTheme.accentOchre.withOpacity(0.2),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.accentOchre : Colors.black54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.accentOchre : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceCard(DiscoveryPlace place, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Image (placeholder)
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              image: const DecorationImage(
                image: NetworkImage("https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=2078&auto=format&fit=crop"),
                fit: BoxFit.cover,
              )
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(place.rating.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        place.name,
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                      ),
                    ),
                    if (place.distanceKm > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "\${place.distanceKm.toStringAsFixed(1)} km",
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(place.district, style: GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
                
                if (place.aiReason.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOchre.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentOchre.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome, color: AppTheme.accentOchre, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.aiReason, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentOchre)),
                              const SizedBox(height: 4),
                              Text(
                                place.aiReason,
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],

                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _openMapModal(place, l10n),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(l10n.openOnMap),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
