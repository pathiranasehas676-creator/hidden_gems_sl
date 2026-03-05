import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/discovery_service.dart';

class PlaceDetailsScreen extends StatelessWidget {
  final DiscoveryPlace place;

  const PlaceDetailsScreen({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.silkPearl,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeroImage(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(),
                  const SizedBox(height: 24),
                  _buildAIReason(),
                  const SizedBox(height: 24),
                  _buildQuickStats(),
                  const SizedBox(height: 24),
                  _buildDetailsSection(Icons.info_outline, "The Details", _buildDetailsChips()),
                  const SizedBox(height: 24),
                  _buildDetailsSection(Icons.warning_amber_rounded, "Safety & Risks", _buildRiskTags()),
                  const SizedBox(height: 24),
                  _buildDetailsSection(Icons.local_cafe_outlined, "Facilities", _buildFacilities()),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: _buildBottomActions(context),
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              "https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=2078&auto=format&fit=crop",
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent, Colors.black87],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, height: 1.1),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppTheme.accentOchre),
                      const SizedBox(width: 4),
                      Text(place.district, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700)),
                      if (place.distanceKm > 0) ...[
                        const SizedBox(width: 8),
                        Text("•", style: TextStyle(color: Colors.grey.shade400)),
                        const SizedBox(width: 8),
                        Text("\${place.distanceKm.toStringAsFixed(1)} km away", style: GoogleFonts.inter(fontSize: 14, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(place.rating.toString(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAIReason() {
    if (place.aiReason.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentOchre.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentOchre.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.accentOchre, size: 18),
              const SizedBox(width: 8),
              Text("Why this place?", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.accentOchre)),
            ],
          ),
          const SizedBox(height: 8),
          Text(place.aiReason, style: GoogleFonts.inter(color: Colors.black87, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statBox(Icons.access_time_outlined, "Best Time", place.bestTime),
        const SizedBox(width: 12),
        _statBox(Icons.confirmation_number_outlined, "Ticket", place.ticketRange),
      ],
    );
  }

  Widget _statBox(IconData icon, String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryBlue, size: 24),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value.isEmpty ? "N/A" : value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue), textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(IconData icon, String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildDetailsChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (place.category.isNotEmpty) _chip(place.category, Colors.green),
        if (place.roadType.isNotEmpty) _chip("Road: \${place.roadType}", Colors.blueGrey),
        if (place.vehicleAccess.isNotEmpty) _chip("Access: \${place.vehicleAccess}", Colors.orange),
        if (place.parkingRange.isNotEmpty) _chip("Parking: \${place.parkingRange}", Colors.brown),
      ],
    );
  }

  Widget _buildRiskTags() {
    if (place.riskTags.isEmpty) return Text("No major risks noted.", style: TextStyle(color: Colors.grey.shade600));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: place.riskTags.map((t) => _chip(t, Colors.redAccent)).toList(),
    );
  }

  Widget _buildFacilities() {
    if (place.facilities.isEmpty) return Text("Limited facilities.", style: TextStyle(color: Colors.grey.shade600));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: place.facilities.map((t) => _chip(t, Colors.blueAccent)).toList(),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              icon: const Icon(Icons.bookmark_border_rounded, color: AppTheme.primaryBlue),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved to your gems!")));
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                // Mock Add to Plan
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to current plan!")));
              },
              child: Text("Add to my plan", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
