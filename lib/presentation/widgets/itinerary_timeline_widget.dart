import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/trip_plan_model.dart';

/// Interactive drag-and-drop timeline for an itinerary day.
/// Users can long-press and reorder items within the day.
class ItineraryTimelineWidget extends StatefulWidget {
  final ItineraryDay day;
  final Function(List<ItineraryItem>)? onReorder;

  const ItineraryTimelineWidget({
    super.key,
    required this.day,
    this.onReorder,
  });

  @override
  State<ItineraryTimelineWidget> createState() => _ItineraryTimelineWidgetState();
}

class _ItineraryTimelineWidgetState extends State<ItineraryTimelineWidget> {
  late List<ItineraryItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.day.items);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.modernGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.modernGreen.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Text(
                  'Day ${widget.day.day}',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.day.dayTheme,
                  style: GoogleFonts.outfit(
                    color: AppTheme.darkText,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${_items.length} stops',
                style: AppTheme.labelStyle.copyWith(color: AppTheme.darkText.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
        // Draggable list
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _items.length,
          onReorder: (oldIndex, newIndex) {
            HapticFeedback.mediumImpact();
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final item = _items.removeAt(oldIndex);
              _items.insert(newIndex, item);
            });
            widget.onReorder?.call(_items);
          },
          proxyDecorator: (child, index, animation) {
            return Material(
              color: Colors.transparent,
              child: ScaleTransition(
                scale: animation.drive(
                  Tween<double>(begin: 1.0, end: 1.04)
                      .chain(CurveTween(curve: Curves.easeOut)),
                ),
                child: child,
              ),
            );
          },
          itemBuilder: (context, index) {
            final item = _items[index];
            final isLast = index == _items.length - 1;
            return _TimelineItem(
              key: ValueKey('${widget.day.day}-$index-${item.title}'),
              item: item,
              index: index,
              isLast: isLast,
            );
          },
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final ItineraryItem item;
  final int index;
  final bool isLast;

  const _TimelineItem({
    super.key,
    required this.item,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final typeInfo = _typeInfo(item.type);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail
          SizedBox(
            width: 40,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: typeInfo.$2.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: typeInfo.$2.withValues(alpha: 0.5)),
                  ),
                  child: Icon(typeInfo.$1, size: 16, color: typeInfo.$2),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 48,
                    color: AppTheme.modernGreen.withValues(alpha: 0.2),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time
                        Text(
                          item.time,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppTheme.modernBlue,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Title
                        Text(
                          item.title,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppTheme.darkText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.notes,
                            style: AppTheme.bodyStyle.copyWith(fontSize: 12, color: AppTheme.darkText.withValues(alpha: 0.6)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        // Tags
                        Wrap(
                          spacing: 8,
                          children: [
                            if (item.durationMin > 0)
                              _tag(Icons.timer_outlined, '${item.durationMin}min'),
                            if (item.costLkr > 0)
                              _tag(Icons.payments_outlined, 'Rs.${_fmt(item.costLkr)}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Drag handle
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: AppTheme.darkText.withValues(alpha: 0.2),
                        size: 20,
                      ),
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

  Widget _tag(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: AppTheme.darkText.withValues(alpha: 0.4)),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, color: AppTheme.darkText.withValues(alpha: 0.4))),
      ],
    );
  }

  String _fmt(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}K' : '$v';

  (IconData, Color) _typeInfo(String type) {
    switch (type) {
      case 'food': return (Icons.restaurant_outlined, Colors.orangeAccent);
      case 'hotel': return (Icons.hotel_outlined, Colors.purpleAccent);
      case 'transport': return (Icons.directions_car_outlined, Colors.blueAccent);
      case 'rest': return (Icons.self_improvement_outlined, Colors.greenAccent);
      case 'nature': return (Icons.park_outlined, const Color(0xFF4CAF50));
      case 'culture': return (Icons.temple_buddhist_outlined, const Color(0xFFFF9800));
      case 'shopping': return (Icons.shopping_bag_outlined, Colors.pinkAccent);
      default: return (Icons.place_outlined, AppTheme.modernGreen);
    }
  }
}
