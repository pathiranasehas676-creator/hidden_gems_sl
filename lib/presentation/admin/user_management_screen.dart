import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final List<Map<String, dynamic>> _users = [
    {"name": "Sehas Hansaka", "email": "sehas@example.com", "role": "super_admin", "status": "Active"},
    {"name": "Kasun Perera", "email": "kasun@gmail.com", "role": "premium", "status": "Active"},
    {"name": "Nimal Siri", "email": "nimal@outlook.com", "role": "user", "status": "Active"},
    {"name": "Kamal Silva", "email": "kamal@dev.com", "role": "user", "status": "Banned"},
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
                  Text("User Management", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text("Govern the citizen base of TripMe.ai.", style: GoogleFonts.inter(color: Colors.white54)),
                ],
              ),
              const Spacer(),
              _searchBar(),
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
                DataColumn(label: Text("USER")),
                DataColumn(label: Text("ROLE")),
                DataColumn(label: Text("STATUS")),
                DataColumn(label: Text("ACTIONS")),
              ],
              rows: _users.map((user) {
                return DataRow(cells: [
                  DataCell(Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(user['email'], style: const TextStyle(fontSize: 11, color: Colors.white38)),
                    ],
                  )),
                  DataCell(_roleChip(user['role'])),
                  DataCell(_statusChip(user['status'])),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.star_outline, size: 18, color: AppTheme.accentOchre),
                        onPressed: () {}, // Upgrade to Premium
                        tooltip: "Upgrade to Premium",
                      ),
                      IconButton(
                        icon: Icon(
                          user['status'] == "Banned" ? Icons.security_outlined : Icons.block_flipped,
                          size: 18,
                          color: user['status'] == "Banned" ? Colors.greenAccent : Colors.redAccent,
                        ),
                        onPressed: () {}, // Ban/Unban
                        tooltip: user['status'] == "Banned" ? "Unban User" : "Ban User",
                      ),
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

  Widget _searchBar() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: "Search by email...",
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _roleChip(String role) {
    Color color = role == 'super_admin' ? Colors.purpleAccent : (role == 'premium' ? AppTheme.accentOchre : Colors.white54);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(role.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _statusChip(String status) {
    Color color = status == 'Active' ? Colors.greenAccent : Colors.redAccent;
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(status, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
