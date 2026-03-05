import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class PlanInspectorScreen extends StatelessWidget {
  const PlanInspectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Plan Library Inspector", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text("Audit the Oracle's logic for hallucinations and inaccuracies.", style: GoogleFonts.inter(color: Colors.white54)),
                ],
              ),
              const Spacer(),
              _statBox("Flagged Plans", "12", Colors.redAccent),
              const SizedBox(width: 16),
              _statBox("Avg. Accuracy", "94.2%", Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 40),
          
          // Hallucination Log List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              return _HallucinationLogCard(
                id: "HL-${500 + index}",
                issue: index % 2 == 0 ? "Fact Mismatch: Ella Train Time" : "Logic Loop: Kandy Itinerary",
                confidence: 68 - (index * 5),
                timestamp: "${index + 1} hr ago",
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white38)),
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _HallucinationLogCard extends StatelessWidget {
  final String id;
  final String issue;
  final int confidence;
  final String timestamp;

  const _HallucinationLogCard({
    required this.id, required this.issue, required this.confidence, required this.timestamp
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(id, style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text(timestamp, style: const TextStyle(color: Colors.white24, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          Text(issue, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            "The Oracle reported low confidence ($confidence%) during this generation. Potentially incorrect city grounding for 'Nuwara Eliya'.",
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text("View Full Trace", style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOchre.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.accentOchre,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text("Fix KB Grounding", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
