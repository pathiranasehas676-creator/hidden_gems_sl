import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:lottie/lottie.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/live_events_service.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/datasources/trip_cache_service.dart';
import '../../data/models/event_model.dart';
import '../widgets/batik_background.dart';
import '../widgets/skeleton_loaders.dart';

class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({super.key});

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _ProfileHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  _ProfileHeader({required this.child});
  @override
  double get minExtent => 120;
  @override
  double get maxExtent => 120;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class _EventCalendarScreenState extends State<EventCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<EventModel> _selectedEvents = [];
  List<EventModel> _upcomingEvents = [];
  List<EventModel> _topPicks = [];
  EventCategory? _selectedCategory;
  bool _isLoading = true;
  final _userProfile = UserPreferenceService.getProfile();
  final ScreenshotController _screenshotController = ScreenshotController();

  final List<String> _musicGenres = [
    "Techno", "House", "Acoustic", "Jazz", "Traditional", "Rock", "Electronic"
  ];
  List<String> _selectedMusicPreferences = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedMusicPreferences = List<String>.from(_userProfile.preferredStyles.where((i) => _musicGenres.contains(i)));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200)); 
    _updateEvents();
    _upcomingEvents = LiveEventsService.getUpcomingEvents();
    _topPicks = LiveEventsService.getPersonalizedEvents(
      _userProfile.vibe, 
      [..._userProfile.preferredStyles, ..._selectedMusicPreferences],
    );
    setState(() => _isLoading = false);
  }

  void _updateEvents() {
    final allEvents = LiveEventsService.getEventsForTrip(_selectedDay!, 1);
    setState(() {
      if (_selectedCategory == null) {
        _selectedEvents = allEvents;
      } else {
        _selectedEvents = allEvents.where((e) => e.category == _selectedCategory).toList();
      }
    });
  }

  bool _isRecommended(EventModel event) {
    if (_topPicks.any((p) => p.name == event.name)) return true;
    final vibe = _userProfile.vibe.toLowerCase();
    if (vibe == 'party' || vibe == 'luxury') {
      return event.category == EventCategory.party;
    } else if (vibe == 'explorer' || vibe == 'nature') {
      return event.category == EventCategory.cultural || event.category == EventCategory.festival;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BatikBackground(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildComingSoonSection(),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildCategoryFilters(),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildCalendarCard(),
                      ),
                      const SizedBox(height: 32),
                      _buildTopPicksSection(),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildEventList(),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Text(
          "Serendib Events",
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryBlue.withOpacity(0.8),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _showPreferenceDialog,
          icon: Icon(Icons.tune_rounded, color: Theme.of(context).colorScheme.onSurface),
          tooltip: "Personalize Vibe",
        ),
        IconButton(
          onPressed: _shareScreen,
          icon: Icon(Icons.ios_share, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildComingSoonSection() {
    if (_isLoading) return _buildComingSoonShimmer();
    if (_upcomingEvents.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Icon(Icons.bolt, color: AppTheme.accentOchre, size: 18),
              const SizedBox(width: 8),
              Text(
                "COMING UP SOON",
                style: AppTheme.labelStyle(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: _upcomingEvents.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _buildUpcomingCard(_upcomingEvents[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComingSoonShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModernTracerShimmer.box(context, width: 150, height: 16),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ModernTracerShimmer(
                  child: Container(
                    width: 250,
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(EventModel event) {
    return _buildEventCard(event, isWide: true);
  }

  Widget _buildEventCard(EventModel event, {bool isWide = false}) {
    final isPinned = TripCacheService.isEventPinned(event.name);
    final isRecommended = _isRecommended(event);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildEventDetailsModal(event, isPinned, isRecommended),
        );
      },
      child: Container(
        width: isWide ? 280 : double.infinity,
        decoration: AppTheme.glassDecoration(
          opacity: Theme.of(context).brightness == Brightness.dark ? 0.1 : 0.8,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ).copyWith(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isRecommended 
                ? AppTheme.sigiriyaOchre 
                : event.categoryColor.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.4),
            width: isRecommended ? 2.0 : 1.0,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: event.categoryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    event.category.name.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: event.categoryColor),
                  ),
                ),
                if (isRecommended)
                  const Icon(Icons.auto_awesome, color: AppTheme.accentOchre, size: 16),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              event.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  event.location ?? "Sri Lanka",
                  style: GoogleFonts.inter(
                    fontSize: 12, 
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const Spacer(),
                if (isPinned)
                  const Icon(Icons.bookmark, size: 14, color: AppTheme.accentOchre),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetailsModal(EventModel event, bool isPinned, bool isRecommended) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: AppTheme.glassDecoration(
          opacity: 0.95, 
          blur: 40,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ).copyWith(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(32),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: event.categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    event.category.name.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: event.categoryColor),
                  ),
                ),
                _buildActionButtons(event, isPinned),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              event.name,
              style: GoogleFonts.outfit(
                fontSize: 28, 
                fontWeight: FontWeight.bold, 
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                const SizedBox(width: 6),
                Text(
                  event.location ?? "Sri Lanka",
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), 
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              event.description,
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), 
                fontSize: 15, 
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            if (event.lineup.isNotEmpty) ...[
              Text("LINEUP", style: AppTheme.labelStyle(context)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: event.lineup.map((artist) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                  ),
                  child: Text(
                    artist.name,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface, 
                      fontSize: 13, 
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 32),
            ],
            _buildBigActionButton(event),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPicksSection() {
    if (!_isLoading && _topPicks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Icon(Icons.star_rounded, color: AppTheme.sigiriyaOchre, size: 20),
              const SizedBox(width: 8),
              Text(
                "CURATED FOR YOU",
                style: AppTheme.labelStyle(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: _isLoading 
            ? ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: 3,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: ModernTracerShimmer(
                    child: Container(
                      width: 170,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: _topPicks.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return _buildEventCard(_topPicks[index], isWide: true);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip("All", null),
          ...EventCategory.values.map((cat) => _filterChip(cat.name.toUpperCase(), cat)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, EventCategory? category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _updateEvents();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryBlue 
              : Theme.of(context).cardColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryBlue 
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected 
                  ? Colors.white 
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: AppTheme.glassDecoration(
        opacity: 0.1, 
        blur: 20,
        isDark: isDark,
      ),
      padding: const EdgeInsets.all(8),
      child: TableCalendar<EventModel>(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            _updateEvents();
          });
        },
        calendarFormat: CalendarFormat.month,
        headerStyle: HeaderStyle(
          titleTextStyle: GoogleFonts.outfit(
            color: colorScheme.onSurface, 
            fontSize: 18, 
            fontWeight: FontWeight.bold,
          ),
          formatButtonVisible: false,
          leftChevronIcon: Icon(Icons.chevron_left, color: colorScheme.onSurface.withOpacity(0.6)),
          rightChevronIcon: Icon(Icons.chevron_right, color: colorScheme.onSurface.withOpacity(0.6)),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 13),
          weekendStyle: const TextStyle(color: AppTheme.sigiriyaOchre, fontSize: 13),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: TextStyle(color: colorScheme.onSurface, fontSize: 14),
          outsideTextStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.2), fontSize: 14),
          todayDecoration: BoxDecoration(
            color: AppTheme.sigiriyaOchre.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppPalette.ceylonBlue,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppPalette.ceylonBlue, blurRadius: 15, spreadRadius: 0)],
          ),
        ),
        eventLoader: (day) {
          final events = LiveEventsService.getEventsForTrip(day, 1);
          if (_selectedCategory == null) return events;
          return events.where((e) => e.category == _selectedCategory).toList();
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return const SizedBox();
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: events.take(3).map((event) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: event.categoryColor,
                    shape: BoxShape.circle,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventList() {
    if (_isLoading) return _buildSkeletonList();
    if (_selectedEvents.isEmpty) return _buildEmptyState();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "AVAILABLE EVENTS",
          style: AppTheme.labelStyle(context),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selectedEvents.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final event = _selectedEvents[index];
            return _buildEventCard(event);
          },
        ),
      ],
    );
  }

  Widget _buildSkeletonList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModernTracerShimmer.box(context, width: 120, height: 16),
        const SizedBox(height: 20),
        ...List.generate(3, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ModernTracerShimmer(
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: AppTheme.glassDecoration(opacity: 0.05),
      child: Column(
        children: [
          Lottie.network(
            'https://assets9.lottiefiles.com/packages/lf20_m6reunre.json', 
            height: 150,
            errorBuilder: (_, __, ___) => Icon(Icons.event_busy, size: 60, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
          ),
          const SizedBox(height: 24),
          Text(
            "No events discovered",
            style: GoogleFonts.outfit(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your filters or selecting a different date",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14, 
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = null;
                _updateEvents();
              });
            },
            child: Text(
              "CLEAR ALL FILTERS",
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.sigiriyaOchre),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(EventModel event, bool isPinned) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (event.lat != null && event.lng != null)
          IconButton(
            onPressed: () => _openInMaps(event.lat!, event.lng!, event.name),
            icon: Icon(Icons.map_outlined, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          ),
        IconButton(
          onPressed: () => _togglePin(event),
          icon: Icon(
            isPinned ? Icons.bookmark : Icons.bookmark_border,
            color: isPinned ? AppTheme.accentOchre : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildBigActionButton(EventModel event, {bool isCompact = false}) {
    if (event.ticketUrl != null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => LiveEventsService.launchTicketUrl(event.ticketUrl!),
          icon: const Icon(Icons.confirmation_num_outlined, size: 18),
          label: Text(
            "BOOK TICKETS",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: event.categoryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showPreferenceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: AppTheme.glassDecoration(opacity: 0.9, blur: 30).copyWith(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Customize Your Vibe",
                style: GoogleFonts.outfit(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Tell us what music gets you moving.",
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), 
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _musicGenres.map((genre) {
                  final isSelected = _selectedMusicPreferences.contains(genre);
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        if (isSelected) {
                          _selectedMusicPreferences.remove(genre);
                        } else {
                          _selectedMusicPreferences.add(genre);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.accentOchre 
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        genre,
                        style: GoogleFonts.inter(
                          color: isSelected 
                              ? Colors.black 
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _loadData();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text("APPLY PREFERENCES", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInMaps(double lat, double lng, String label) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _togglePin(EventModel event) async {
    await TripCacheService.toggleInterestedEvent(event.name, json.encode(event.toJson()));
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _shareScreen() async {
    try {
      final Uint8List? image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = await File('${directory.path}/serendib_events.png').create();
        await imagePath.writeAsBytes(image);
        await Share.shareXFiles([XFile(imagePath.path)], text: "Exploring the best of Sri Lanka! 🇱🇰🌌");
      }
    } catch (_) {}
  }
}
