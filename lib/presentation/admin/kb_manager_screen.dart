import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class KBManagerScreen extends StatefulWidget {
  const KBManagerScreen({super.key});

  @override
  State<KBManagerScreen> createState() => _KBManagerScreenState();
}

class _KBManagerScreenState extends State<KBManagerScreen> {
  final List<Map<String, dynamic>> _destinations = [
    {"name": "Ella", "category": "Nature", "trust": 0.95, "lastSync": "2 hrs ago"},
    {"name": "Galle", "category": "Cultural", "trust": 0.92, "lastSync": "5 hrs ago"},
    {"name": "Kandy", "category": "Religious", "trust": 0.88, "lastSync": "1 day ago"},
    {"name": "Sigiriya", "category": "History", "trust": 0.98, "lastSync": "10 mins ago"},
  ];

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
                  Text("Knowledge Base", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text("Curate the Oracle's ground-truth intelligence.", style: GoogleFonts.inter(color: Colors.white54)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text("New Destination"),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOchre, foregroundColor: AppTheme.primaryBlue),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.sync, size: 18),
                label: const Text("Re-index Vector DB"),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.accentOchre), foregroundColor: AppTheme.accentOchre),
              ),
            ],
          ),
          const SizedBox(height: 40),
          
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: DataTable(
              headingTextStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
              dataTextStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
              columns: const [
                DataColumn(label: Text("DESTINATION")),
                DataColumn(label: Text("CATEGORY")),
                DataColumn(label: Text("TRUST SCORE")),
                DataColumn(label: Text("LAST SYNC")),
                DataColumn(label: Text("ACTIONS")),
              ],
              rows: _destinations.map((dest) {
                return DataRow(cells: [
                  DataCell(Text(dest['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  DataCell(Text(dest['category'])),
                  DataCell(_trustChip(dest['trust'])),
                  DataCell(Text(dest['lastSync'])),
                  DataCell(Row(
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white54), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), onPressed: () {}),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trustChip(double score) {
    Color color = score > 0.9 ? Colors.greenAccent : (score > 0.8 ? AppTheme.accentOchre : Colors.orangeAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Text("${(score * 100).toInt()}%", style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
