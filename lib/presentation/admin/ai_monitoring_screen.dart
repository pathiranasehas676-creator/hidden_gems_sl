import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class AIMonitoringScreen extends StatefulWidget {
  const AIMonitoringScreen({super.key});

  @override
  State<AIMonitoringScreen> createState() => _AIMonitoringScreenState();
}

class _AIMonitoringScreenState extends State<AIMonitoringScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("AI Monitoring", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text("Live logs, latency, and hallucination audits.", style: GoogleFonts.inter(color: Colors.white54)),
                ],
              ),
              const Spacer(),
              _filterChip("High Latency", Colors.redAccent),
              const SizedBox(width: 8),
              _filterChip("Low Confidence", Colors.orangeAccent),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.sigiriyaOchre.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.sigiriyaOchre.withOpacity(0.4)),
              ),
              labelColor: AppTheme.sigiriyaOchre,
              unselectedLabelColor: Colors.white38,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: const [
                Tab(icon: Icon(Icons.list_alt_outlined, size: 16), text: "Request Logs"),
                Tab(icon: Icon(Icons.report_gmailerrorred_outlined, size: 16), text: "Hallucination Reports"),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildLogsTab(), _buildHallucinationTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildLogsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ai_logs')
          .orderBy('timestamp', descending: true)
          .limit(25)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.sigiriyaOchre));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text("No AI logs yet.", style: TextStyle(color: Colors.white24)));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            final ts = data['timestamp'] as Timestamp?;
            return _AIRequestLogItem(
              docId: docId,
              id: (data['requestId'] ?? "N/A").toString(),
              dest: data['destination'] ?? "Unknown",
              latency: (data['latencyMs'] ?? 0) as int,
              confidence: (data['confidence'] ?? 0) as int,
              tokens: (data['tokenEstimate'] ?? 0) as int,
              time: ts != null ? _formatTimestamp(ts.toDate()) : "Unknown",
            );
          },
        );
      },
    );
  }

  Widget _buildHallucinationTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hallucination_reports')
          .orderBy('reportedAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.sigiriyaOchre));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 48),
                const SizedBox(height: 16),
                Text("No hallucination reports! 🎉", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Text("Users flag incorrect AI responses from their trip results.", style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final ts = d['reportedAt'] as Timestamp?;
            final severity = d['severity'] as String? ?? 'medium';
            final sevColor = severity == 'high' ? Colors.redAccent
                : severity == 'medium' ? Colors.orangeAccent
                : Colors.yellowAccent;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: sevColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sevColor.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag_rounded, color: sevColor, size: 16),
                      const SizedBox(width: 8),
                      Text(d['destination'] ?? 'Unknown', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: sevColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text(severity.toUpperCase(), style: TextStyle(color: sevColor, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(d['description'] ?? 'No description.', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Request: ${d['requestId'] ?? 'N/A'}', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
                      const Spacer(),
                      Text(ts != null ? _formatTimestamp(ts.toDate()) : 'Unknown', style: GoogleFonts.inter(color: Colors.white24, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) return "${diff.inHours} hrs ago";
    return "${diff.inDays} days ago";
  }

  Widget _filterChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _AIRequestLogItem extends StatelessWidget {
  final String docId;
  final String id;
  final String dest;
  final int latency;
  final int confidence;
  final int tokens;
  final String time;

  const _AIRequestLogItem({
    required this.docId, required this.id, required this.dest,
    required this.latency, required this.confidence,
    required this.tokens, required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final isLowConf = confidence < 70;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLowConf ? Colors.orangeAccent.withOpacity(0.04) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLowConf ? Colors.orangeAccent.withOpacity(0.3) : Colors.white10),
      ),
      child: Row(
        children: [
          _logMetric("REQUEST", id, Colors.white),
          const SizedBox(width: 32),
          _logMetric("DEST", dest, AppTheme.accentOchre),
          const SizedBox(width: 32),
          _logMetric("LATENCY", "${latency}ms", latency > 2000 ? Colors.redAccent : Colors.white70),
          const SizedBox(width: 32),
          _logMetric("CONFIDENCE", "$confidence%", confidence < 70 ? Colors.orangeAccent : Colors.greenAccent),
          const SizedBox(width: 32),
          _logMetric("TOKENS", "$tokens", Colors.white54),
          const Spacer(),
          Text(time, style: const TextStyle(color: Colors.white24, fontSize: 12)),
          const SizedBox(width: 12),
          Tooltip(
            message: "Flag as Hallucination",
            child: IconButton(
              icon: const Icon(Icons.flag_outlined, size: 18, color: Colors.white38),
              onPressed: () => _showFlagDialog(context),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 18, color: Colors.white38),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  void _showFlagDialog(BuildContext context) {
    final controller = TextEditingController();
    String severity = 'medium';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text("Flag Hallucination", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Request: $id • Dest: $dest", style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 16),
              Text("Severity", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'low', label: Text('Low')),
                  ButtonSegment(value: 'medium', label: Text('Medium')),
                  ButtonSegment(value: 'high', label: Text('High')),
                ],
                selected: {severity},
                onSelectionChanged: (s) => setDS(() => severity = s.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: Colors.orangeAccent.withOpacity(0.2),
                  selectedForegroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white38,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Describe the incorrect AI response...",
                  hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white38))),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await FirebaseFirestore.instance.collection('hallucination_reports').add({
                  'requestId': id,
                  'destination': dest,
                  'confidence': confidence,
                  'severity': severity,
                  'description': controller.text.trim().isEmpty ? 'No description' : controller.text.trim(),
                  'reportedAt': FieldValue.serverTimestamp(),
                  'status': 'open',
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text("Flagged for review."), backgroundColor: Colors.orangeAccent.withOpacity(0.8)),
                  );
                }
              },
              icon: const Icon(Icons.flag_rounded, size: 16),
              label: const Text("Submit Report"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logMetric(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}
