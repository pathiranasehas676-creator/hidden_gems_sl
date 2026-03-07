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
import '../../core/theme/app_theme.dart';
import '../../data/datasources/live_events_service.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/datasources/trip_cache_service.dart';
import '../../data/models/event_model.dart';
import '../widgets/batik_background.dart';

class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({super.key});

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<EventModel> _selectedEvents = [];
  List<EventModel> _upcomingEvents = [];
  List<EventModel> _topPicks = [];
  EventCategory? _selectedCategory;
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

  void _loadData() {
    _updateEvents();
    _upcomingEvents = LiveEventsService.getUpcomingEvents();
    _topPicks = LiveEventsService.getPersonalizedEvents(
      _userProfile.vibe, 
      [..._userProfile.preferredStyles, ..._selectedMusicPreferences],
    );
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
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryBlue.withValues(alpha: 0.8),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _showPreferenceDialog,
          icon: const Icon(Icons.tune_rounded, color: Colors.white),
          tooltip: "Personalize Vibe",
        ),
        IconButton(
          onPressed: _shareScreen,
          icon: const Icon(Icons.ios_share, color: Colors.white),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildComingSoonSection() {
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
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
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
              final event = _upcomingEvents[index];
              return _buildUpcomingCard(event);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingCard(EventModel event) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = DateTime.now().add(Duration(days: indexDifference(DateTime.now(), event)));
          _updateEvents();
        });
      },
      child: Container(
        width: 280,
        decoration: AppTheme.glassDecoration(opacity: 0.2).copyWith(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              event.categoryColor.withValues(alpha: 0.3),
              Colors.white.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.date ?? "SOON",
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white38),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  event.location ?? "Sri Lanka",
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
                ),
              ],
            ),
            Row(
              children: [
                ...event.tags.take(2).map((tag) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text("#$tag", style: GoogleFonts.inter(fontSize: 10, color: event.categoryColor)),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int indexDifference(DateTime start, EventModel event) {
    if (event.date == null) return 0;
    try {
      final parts = event.date!.split("-");
      final eventDate = DateTime(start.year, int.parse(parts[0]), int.parse(parts[1]));
      return eventDate.difference(start).inDays;
    } catch (_) { return 0; }
  }

  Widget _buildTopPicksSection() {
    if (_topPicks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.accentOchre, size: 18),
              const SizedBox(width: 8),
              Text(
                "TOP PICKS FOR YOU",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: _topPicks.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final event = _topPicks[index];
              return _buildTopPickCard(event);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopPickCard(EventModel event) {
    return Container(
      width: 300,
      decoration: AppTheme.glassDecoration(opacity: 0.15).copyWith(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.accentOchre.withValues(alpha: 0.3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child: Image.network(
                  "https://source.unsplash.com/featured/?sri-lanka,party,${event.tags.isNotEmpty ? event.tags.first : 'event'}",
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.black26),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOchre.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "98% MATCH",
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentOchre),
                        ),
                      ),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white10,
                        child: Icon(Icons.favorite_border, size: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        maxLines: 2,
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                  _buildBigActionButton(event, isCompact: true),
                ],
              ),
            ),
          ],
        ),
      ),
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
          color: isSelected ? AppTheme.primaryBlue : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.5) : Colors.white10),
          boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.3), blurRadius: 10, offset: Offset(0, 4))] : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      decoration: AppTheme.glassDecoration(opacity: 0.15, blur: 20).copyWith(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
          titleTextStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          formatButtonVisible: false,
          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white70),
          rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white70),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.white60, fontSize: 13),
          weekendStyle: TextStyle(color: AppTheme.accentOchre, fontSize: 13),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
          weekendTextStyle: const TextStyle(color: Colors.white70, fontSize: 14),
          outsideTextStyle: const TextStyle(color: Colors.white24, fontSize: 14),
          todayDecoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppTheme.primaryBlue,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppTheme.primaryBlue, blurRadius: 15, spreadRadius: 2)],
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
                    boxShadow: [BoxShadow(color: event.categoryColor.withValues(alpha: 0.5), blurRadius: 4)],
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
    if (_selectedEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.calendar_today_outlined, size: 48, color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              Text(
                "No events for this date",
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "DAILY LINEUP",
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selectedEvents.length,
          separatorBuilder: (context, index) => const SizedBox(height: 20),
          itemBuilder: (context, index) => _buildEventCard(_selectedEvents[index]),
        ),
      ],
    );
  }

  Widget _buildEventCard(EventModel event) {
    final isRecommended = _isRecommended(event);
    final isPinned = TripCacheService.isEventPinned(event.name);

    return Hero(
      tag: "event_${event.name}",
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: AppTheme.glassDecoration(opacity: 0.1).copyWith(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isRecommended ? AppTheme.accentOchre.withValues(alpha: 0.4) : event.categoryColor.withValues(alpha: 0.2),
                  width: isRecommended ? 1.5 : 1,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: event.categoryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    event.category.name.toUpperCase(),
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: event.categoryColor),
                                  ),
                                ),
                                if (isRecommended) ...[
                                  const SizedBox(width: 10),
                                  const Icon(Icons.auto_awesome, color: AppTheme.accentOchre, size: 14),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              event.name,
                              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      _buildActionButtons(event, isPinned),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        event.location ?? "Sri Lanka",
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                      ),
                      const Spacer(),
                      if (event.priceLkr != null)
                        Text(
                          event.priceLkr! == 0 ? "FREE" : "Rs. ${event.priceLkr}",
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentOchre),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.description,
                    style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.6),
                  ),
                  if (event.lineup.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      "WHO'S PLAYING",
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: event.lineup.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final artist = event.lineup[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  artist.name,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                if (artist.musicGenre != null)
                                  Text(
                                    artist.musicGenre!,
                                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 9),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _buildBigActionButton(event),
                ],
              ),
            ),
          ],
        ),
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
            icon: const Icon(Icons.map_outlined, color: Colors.white54),
          ),
        IconButton(
          onPressed: () => _togglePin(event),
          icon: Icon(
            isPinned ? Icons.bookmark : Icons.bookmark_border,
            color: isPinned ? AppTheme.accentOchre : Colors.white54,
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
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                "Tell us what music gets you moving.",
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
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
                        color: isSelected ? AppTheme.accentOchre : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        genre,
                        style: GoogleFonts.inter(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text("APPLY PREFERENCES", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
      await Share.shareXFiles([XFile(imagePath.path)], text: "Uncovering Hidden Sri Lanka's Party Scene with HiddenGems SL! 🇱🇰🌌");
    }
    } catch (_) {}
  }
}
