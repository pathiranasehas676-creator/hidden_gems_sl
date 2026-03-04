import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/trip_cache_service.dart';
import '../../data/models/trip_plan_model.dart';
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
        const SnackBar(
          content: Text('Plan removed'),
          behavior: SnackBarBehavior.floating,
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
      backgroundColor: AppTheme.primaryBlue, // Base Oceanic Background
      appBar: AppBar(
        title: const Text('Saved Plans', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_plans.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep, color: Colors.white70, size: 18),
              label: const Text('Clear all',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Clear All Saved Plans'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear',
                              style: TextStyle(color: Colors.red))),
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
      body: _plans.isEmpty ? _buildEmpty() : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bookmark_border,
              size: 72, color: Colors.white54),
          const SizedBox(height: 16),
          const Text('No saved plans yet',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('Tap the  🔖  icon on any plan to save it offline.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) => _deletePlan(id),
          child: GestureDetector(
            onTap: () => _openPlan(plan),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassDecoration(),
              child: Row(
                children: [
                  // Destination icon chip
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.travel_explore,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  // Plan info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${summary.fromCity} → ${summary.destinationCity}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: [
                            _chip(Icons.nights_stay_outlined,
                                '${summary.days}d'),
                            _chip(Icons.people_outline, summary.groupType),
                            _chip(Icons.account_balance_wallet_outlined,
                                'LKR ${_fmt(summary.userBudgetLkr)}'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Saved $cachedAgo',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: Colors.white54),
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
        Icon(icon, size: 11, color: Colors.white70),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
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
