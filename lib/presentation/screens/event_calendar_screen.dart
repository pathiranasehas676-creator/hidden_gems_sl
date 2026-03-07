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
  EventCategory? _selectedCategory;
  final _userProfile = UserPreferenceService.getProfile();
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _updateEvents();
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
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCategoryFilters(),
                      const SizedBox(height: 24),
                      _buildCalendarCard(),
                      const SizedBox(height: 32),
                      _buildEventList(),
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
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Text(
          "Event Discovery",
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
          onPressed: _shareScreen,
          icon: const Icon(Icons.ios_share, color: Colors.white),
        ),
        const SizedBox(width: 8),
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
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryBlue : Colors.white10),
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
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
          weekdayStyle: TextStyle(color: Colors.white70, fontSize: 13),
          weekendStyle: TextStyle(color: AppTheme.accentOchre, fontSize: 13),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
          weekendTextStyle: const TextStyle(color: Colors.white70, fontSize: 14),
          outsideTextStyle: const TextStyle(color: Colors.white24, fontSize: 14),
          todayDecoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppTheme.primaryBlue,
            shape: BoxShape.circle,
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
                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                  width: 6,
                  height: 6,
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
    if (_selectedEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.calendar_today_outlined, size: 48, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text(
                "No events found for this filter",
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
          "TODAY'S LINEUP",
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
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _buildEventCard(_selectedEvents[index]),
        ),
      ],
    );
  }

  Widget _buildEventCard(EventModel event) {
    final isRecommended = _isRecommended(event);
    final isPinned = TripCacheService.isEventPinned(event.name);

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          decoration: AppTheme.glassDecoration(opacity: 0.1).copyWith(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRecommended ? AppTheme.accentOchre.withValues(alpha: 0.5) : event.categoryColor.withValues(alpha: 0.3),
              width: isRecommended ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: event.categoryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                event.category.name.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: event.categoryColor,
                                ),
                              ),
                            ),
                            if (isRecommended) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentOchre.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.auto_awesome, color: AppTheme.accentOchre, size: 10),
                                    const SizedBox(width: 4),
                                    Text(
                                      "ORACLE'S CHOICE",
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentOchre,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          event.name,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildActionButtons(event, isPinned),
                ],
              ),
              if (event.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      event.location!,
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Text(
                event.description,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              if (event.lineup.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  "ARTISTS",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white54,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: event.lineup.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final artist = event.lineup[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          artist.name,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _buildBigActionButton(event),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(EventModel event, bool isPinned) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (event.lat != null && event.lng != null)
          IconButton(
            onPressed: () => _openInMaps(event.lat!, event.lng!, event.name),
            icon: const Icon(Icons.map_outlined, color: Colors.white70),
            tooltip: "Open in Maps",
          ),
        IconButton(
          onPressed: () => _togglePin(event),
          icon: Icon(
            isPinned ? Icons.bookmark : Icons.bookmark_border,
            color: isPinned ? AppTheme.accentOchre : Colors.white70,
          ),
          tooltip: isPinned ? "Remove from Trip" : "Add to Trip",
        ),
      ],
    );
  }

  Widget _buildBigActionButton(EventModel event) {
    if (event.ticketUrl != null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => LiveEventsService.launchTicketUrl(event.ticketUrl!),
          icon: const Icon(Icons.confirmation_num_outlined),
          label: Text(
            "BOOK TICKETS",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: event.categoryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _openInMaps(double lat, double lng, String label) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _togglePin(EventModel event) async {
    final isPinned = TripCacheService.isEventPinned(event.name);
    await TripCacheService.toggleInterestedEvent(event.name, json.encode(event.toJson()));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPinned ? "Removed from trip" : "Added to your upcoming trip!",
            style: GoogleFonts.inter(),
          ),
          backgroundColor: isPinned ? Colors.redAccent : AppTheme.modernGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {}); // Refresh UI for bookmark icon
    }
  }

  Future<void> _shareScreen() async {
    try {
      final Uint8List? image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = await File('${directory.path}/event_discovery.png').create();
        await imagePath.writeAsBytes(image);

        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: "Check out these amazing events in Sri Lanka with HiddenGems SL! 🇱🇰🎉",
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to share: $e")),
        );
      }
    }
  }
}
