import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/discovery_service.dart';
import '../widgets/batik_background.dart';
import '../widgets/standard_card.dart';
import '../widgets/skeleton_loaders.dart';
import 'place_details_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  Position? _currentPosition;
  String _currentDistrict = "Colombo"; // Default/Fallback
  
  List<DiscoveryPlace> _allPlaces = [];
  List<DiscoveryPlace> _oraclePicks = [];
  List<DiscoveryPlace> _naturePicks = [];
  List<DiscoveryPlace> _culturePicks = [];
  List<DiscoveryPlace> _filteredList = [];
  
  bool _isLoading = true;
  String _selectedFilter = "All";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    "All", "Nature 🌿", "Waterfall 🌊", "Hiking 🥾", "Culture 🏛️", "Coastal 🌊", "Family 👨‍👩‍👧‍👦", "Budget 💸"
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initDiscovery();
  }

  Future<void> _initDiscovery() async {
    setState(() => _isLoading = true);
    
    _currentPosition = await DiscoveryService.getCurrentLocation();
    if (_currentPosition != null) {
      _currentDistrict = "Near You"; // Ideally reverse geocode here
    }

    _allPlaces = await DiscoveryService.loadAndSortPlaces(
      userLat: _currentPosition?.latitude,
      userLng: _currentPosition?.longitude,
    );

    _oraclePicks = await DiscoveryService.getAiRecommendations(_allPlaces);
    
    _naturePicks = _allPlaces.where((p) => 
      p.category.toLowerCase().contains("nature") || 
      p.category.toLowerCase().contains("waterfall") ||
      p.category.toLowerCase().contains("hiking")
    ).toList();
    
    _culturePicks = _allPlaces.where((p) => 
      p.category.toLowerCase().contains("culture") || 
      p.category.toLowerCase().contains("historical") ||
      p.category.toLowerCase().contains("village")
    ).toList();

    _applyFilter();
  }

  void _applyFilter() {
    // Clean the filter text (remove emojis and trim)
    final cleanFilter = _selectedFilter.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();
    
    if (cleanFilter == "all") {
      setState(() {
        _filteredList = _allPlaces;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      
      final List<DiscoveryPlace> results = _allPlaces.where((p) {
        final cat = p.category.toLowerCase();
        final name = p.name.toLowerCase();
        final district = p.district.toLowerCase();
        
        if (cleanFilter == "nature") {
          return cat.contains("nature") || cat.contains("hiking") || cat.contains("waterfall") || cat.contains("park") || cat.contains("village");
        }
        if (cleanFilter == "waterfall") {
          return cat.contains("waterfall") || name.contains("waterall") || name.contains("ella");
        }
        if (cleanFilter == "hiking") {
          return cat.contains("hiking") || cat.contains("mountain") || cat.contains("peak") || name.contains("peak");
        }
        if (cleanFilter == "culture") {
          return cat.contains("culture") || cat.contains("histor") || cat.contains("temple") || cat.contains("village");
        }
        if (cleanFilter == "coastal") {
          return cat.contains("coast") || cat.contains("beach") || cat.contains("ocean") || district.contains("galle") || district.contains("jaffna");
        }
        if (cleanFilter == "budget") {
          return p.ticketRange.toLowerCase().contains("free") || p.ticketRange.contains("50") || p.ticketRange.contains("100");
        }
        if (cleanFilter == "family") {
          return p.vehicleAccess.toLowerCase().contains("all vehicles") || p.roadType.toLowerCase().contains("paved");
        }
        
        return cat.contains(cleanFilter) || name.contains(cleanFilter) || district.contains(cleanFilter);
      }).toList();

      setState(() {
        _filteredList = results;
        _isLoading = false;
      });
    });
  }

  void _onFilterChanged(String filter) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedFilter == filter) {
        _selectedFilter = "All"; // Toggle off back to All
      } else {
        _selectedFilter = filter;
      }
      _searchQuery = "";
      _searchController.clear();
    });
    _applyFilter();
  }

  void _onSearchSubmitted(String query) async {
    if (query.trim().isEmpty) {
      if (_searchQuery.isNotEmpty) {
        setState(() {
          _searchQuery = "";
          _selectedFilter = "All";
        });
        _applyFilter();
      }
      return;
    }
    
    HapticFeedback.selectionClick();
    setState(() {
      _searchQuery = query;
      _selectedFilter = ""; // Unselect choice chips
      _isLoading = true;
    });
    
    final aiResults = await DiscoveryService.getAiRecommendations(_allPlaces, customQuery: query);
    
    if (mounted) {
      setState(() {
        _filteredList = aiResults;
        _isLoading = false;
      });
    }
  }

  void _openPlaceDetails(DiscoveryPlace place) {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: place)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by BatikBackground
      body: BatikBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
        slivers: [
          _buildLocationHeader(),
          SliverToBoxAdapter(
            child: _buildFilters(l10n),
          ),
          if (_isLoading)
            SliverPadding(
              padding: const EdgeInsets.only(top: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const DiscoveryCardSkeleton(),
                  childCount: 3,
                ),
              ),
            )
          else if (_searchQuery.isNotEmpty)
            _buildListView(l10n)
          else if (_selectedFilter == "All")
            _buildExploreView(l10n)
          else
            _buildListView(l10n),
        ],
        ),
      ),
    );
  }

  Widget _buildLocationHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Discover",
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: AppTheme.glassDecoration(
                  opacity: 0.05,
                  blur: 30,
                  isDark: true,
                  radius: BorderRadius.circular(27),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppTheme.sigiriyaOchre, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: _onSearchSubmitted,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: "Search destinations...",
                          hintStyle: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Icon(Icons.tune, color: Colors.white.withOpacity(0.6), size: 20),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(AppLocalizations l10n) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => _onFilterChanged(filter),
              selectedColor: AppTheme.sigiriyaOchre,
              backgroundColor: Colors.white.withOpacity(0.05),
              labelStyle: GoogleFonts.inter(
                color: isSelected ? Colors.black : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.sigiriyaOchre : Colors.white.withOpacity(0.1),
                width: 1,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExploreView(AppLocalizations l10n) {
    return SliverList(
      delegate: SliverChildListDelegate([
        if (_oraclePicks.isNotEmpty) ...[
          _buildSectionTitle("TripMe Picks for you", Icons.auto_awesome),
          _buildHorizontalCards(_oraclePicks, l10n, isOracle: true),
          const SizedBox(height: 32),
        ],
        if (_naturePicks.isNotEmpty) ...[
          _buildSectionTitle("Best Nature nearby", Icons.park_outlined),
          _buildHorizontalCards(_naturePicks, l10n),
          const SizedBox(height: 32),
        ],
        if (_culturePicks.isNotEmpty) ...[
          _buildSectionTitle("Top Culture spots", Icons.temple_buddhist_outlined),
          _buildHorizontalCards(_culturePicks, l10n),
          const SizedBox(height: 32),
        ],
      ]),
    );
  }

  Widget _buildListView(AppLocalizations l10n) {
    if (_filteredList.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Icon(Icons.search_off, size: 40, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 16),
              Text(
                "No matches nearby", 
                style: GoogleFonts.outfit(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Try increasing distance or removing filters.", 
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), 
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final place = _filteredList[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 500),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildListCard(place, l10n),
                  ),
                ),
              ),
            );
          },
          childCount: _filteredList.length,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title, 
            style: GoogleFonts.outfit(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCards(List<DiscoveryPlace> places, AppLocalizations l10n, {bool isOracle = false}) {
    return SizedBox(
      height: isOracle ? 280 : 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: places.length,
        itemBuilder: (context, index) {
          final place = places[index];
          return GestureDetector(
            onTap: () => _openPlaceDetails(place),
            child: Container(
              width: isOracle ? 240 : 160,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: isOracle 
                ? AppTheme.glassDecoration(color: Theme.of(context).cardColor, opacity: 0.05, blur: 30).copyWith(
                    border: Border.all(color: AppTheme.sigiriyaOchre.withOpacity(0.5), width: 1.5),
                  )
                : AppTheme.glassDecoration(color: Theme.of(context).cardColor, opacity: 0.05, blur: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: CachedNetworkImage(
                        imageUrl: "https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=2078&auto=format&fit=crop",
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                        errorWidget: (context, url, error) => Icon(Icons.error, color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: isOracle ? 5 : 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name, 
                            style: GoogleFonts.outfit(
                              fontSize: isOracle ? 16 : 14, 
                              fontWeight: FontWeight.bold, 
                              color: Theme.of(context).colorScheme.onSurface,
                            ), 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 12, color: AppTheme.accentOchre),
                              const SizedBox(width: 4),
                              Text("${place.distanceKm.toStringAsFixed(1)}km", style: GoogleFonts.inter(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text(place.ticketRange, style: GoogleFonts.inter(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                          if (isOracle && place.aiReason.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.modernGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.modernGreen.withOpacity(0.3)),
                                ),
                                child: Text(
                                  place.aiReason,
                                  style: GoogleFonts.inter(
                                    fontSize: 10, 
                                    fontStyle: FontStyle.italic, 
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListCard(DiscoveryPlace place, AppLocalizations l10n) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.glassDecoration(
        opacity: Theme.of(context).brightness == Brightness.dark ? 0.05 : 0.4,
        blur: 30,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
      child: InkWell(
        onTap: () => _openPlaceDetails(place),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // Image Left
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: CachedNetworkImage(
                imageUrl: "https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=2078&auto=format&fit=crop",
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            // Content Right
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      place.name,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.category,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppTheme.sigiriyaOchre),
                        const SizedBox(width: 4),
                        Text(
                          "${place.distanceKm.toStringAsFixed(1)} km",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          place.ticketRange,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.modernGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
