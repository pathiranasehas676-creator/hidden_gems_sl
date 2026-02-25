import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class AIMonitoringScreen extends StatelessWidget {
  const AIMonitoringScreen({super.key});

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
                  Text("AI Monitoring", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text("Live logs, latency tracking, and hallucination audits.", style: GoogleFonts.inter(color: Colors.white54)),
                ],
              ),
              const Spacer(),
              _filterChip("High Latency", Colors.redAccent),
              const SizedBox(width: 8),
              _filterChip("Low Confidence", Colors.orangeAccent),
              const SizedBox(width: 16),
              const VerticalDivider(color: Colors.white12, width: 1),
              const SizedBox(width: 16),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white54), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 40),
          
          // Log List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 8,
            itemBuilder: (context, index) {
              return _AIRequestLogItem(
                id: "RQ-${1000 + index}",
                dest: index % 2 == 0 ? "Sigiriya" : "Ella",
                latency: 1200 + (index * 150),
                confidence: 92 - (index * 4),
                tokens: 450 + (index * 20),
                time: "${index * 5} mins ago",
              );
            },
          ),
        ],
      ),
    );
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
  final String id;
  final String dest;
  final int latency;
  final int confidence;
  final int tokens;
  final String time;

  const _AIRequestLogItem({
    required this.id, required this.dest, required this.latency,
    required this.confidence, required this.tokens, required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _logMetric("REQUEST", id, Colors.white),
          const SizedBox(width: 40),
          _logMetric("DEST", dest, AppTheme.accentOchre),
          const SizedBox(width: 40),
          _logMetric("LATENCY", "${latency}ms", latency > 2000 ? Colors.redAccent : Colors.white70),
          const SizedBox(width: 40),
          _logMetric("CONFIDENCE", "$confidence%", confidence < 70 ? Colors.orangeAccent : Colors.greenAccent),
          const SizedBox(width: 40),
          _logMetric("TOKENS", "$tokens", Colors.white54),
          const Spacer(),
          Text(time, style: const TextStyle(color: Colors.white24, fontSize: 12)),
          const SizedBox(width: 20),
          IconButton(icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.white), onPressed: () {}),
        ],
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
