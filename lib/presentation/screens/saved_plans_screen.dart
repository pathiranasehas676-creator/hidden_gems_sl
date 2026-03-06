import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/trip_cache_service.dart';
import '../../data/models/trip_plan_model.dart';
import '../widgets/batik_background.dart';
import 'results_screen.dart';

class SavedPlansScreen extends StatefulWidget {
  const SavedPlansScreen({super.key});

  @override
  State<SavedPlansScreen> createState() => _SavedPlansScreenState();
}

class _SavedPlansScreenState extends State<SavedPlansScreen> {
  late List<({String id, TripPlan plan})> _plans;

  @override
  void initState() {
    super.initState();
    _plans = TripCacheService.getSavedPlans();
  }

  void _deletePlan(String id) async {
    await TripCacheService.deleteSavedPlan(id);
    if (mounted) setState(() => _plans = TripCacheService.getSavedPlans());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Plan removed'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _openPlan(TripPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(plan: plan, cacheState: CacheReadResult.fresh),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
        titleTextStyle: GoogleFonts.outfit(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        actions: [
          if (_plans.isNotEmpty)
            TextButton.icon(
              icon: Icon(Icons.delete_sweep, color: Theme.of(context).colorScheme.error, size: 18),
              label: Text('Clear all',
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: Theme.of(context).cardColor,
                    title: Text('Clear All Saved Plans', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    content: Text('This cannot be undone.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)))),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear', style: TextStyle(color: Colors.redAccent))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await TripCacheService.clearAll();
                  if (mounted) setState(() => _plans = []);
                }
              },
            ),
        ],
      ),
      body: BatikBackground(
        child: _plans.isEmpty ? _buildEmpty() : _buildList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.bookmark_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text('No Saved Journeys',
              style: GoogleFonts.outfit(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 8),
          Text('Tap the 🔖 icon on any plan to save it offline.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 120, 20, 100),
      itemCount: _plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final (:id, :plan) = _plans[i];
        final summary = plan.tripSummary;
        final cachedAgo = plan.cachedAt != null
            ? _timeAgo(plan.cachedAt!)
            : 'Unknown date';

        return Dismissible(
          key: Key(id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) => _deletePlan(id),
          child: GestureDetector(
            onTap: () => _openPlan(plan),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassDecoration(
                color: Theme.of(context).cardColor,
                opacity: Theme.of(context).brightness == Brightness.light ? 0.9 : 0.2,
              ),
              child: Row(
                children: [
                  // Destination Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Icon(Icons.travel_explore, color: Theme.of(context).colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  // Plan Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${summary.fromCity} → ${summary.destinationCity}',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          children: [
                            _chip(Icons.nights_stay_outlined, '${summary.days}d'),
                            _chip(Icons.people_outline, summary.groupType),
                            _chip(Icons.account_balance_wallet_outlined,
                                'Rs. ${_fmt(summary.userBudgetLkr)}'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Saved $cachedAgo',
                          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.sigiriyaOchre),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _chip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  String _fmt(int v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toString();
  }
}
