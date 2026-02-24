import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

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
                  Text("Good Morning, Admin", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text("Here is what's happening with the Oracle today.", style: GoogleFonts.inter(color: Colors.white54)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text("Export Report"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOchre,
                  foregroundColor: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          
          // Stats Row
          const Row(
            children: [
              Expanded(child: _StatCard(label: "TOTAL USERS", value: "1,240", delta: "+12%", icon: Icons.people_alt_outlined)),
              SizedBox(width: 24),
              Expanded(child: _StatCard(label: "PLANS TODAY", value: "85", delta: "+5%", icon: Icons.auto_awesome_outlined)),
              SizedBox(width: 24),
              Expanded(child: _StatCard(label: "AVG CONFIDENCE", value: "88.5%", delta: "-2%", icon: Icons.verified_user_outlined)),
              SizedBox(width: 24),
              Expanded(child: _StatCard(label: "REVENUE (LKR)", value: "42,500", delta: "+18%", icon: Icons.payments_outlined)),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Secondary level
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Latency Chart Placeholder
              Expanded(
                flex: 2,
                child: _DashboardPanel(
                  title: "API Performance (Latency ms)",
                  child: Container(
                    height: 300,
                    child: Center(
                      child: Text("Chart Placeholder: Latency Graph", style: TextStyle(color: Colors.white24)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Top Destinations
              Expanded(
                flex: 1,
                child: _DashboardPanel(
                  title: "Top Destinations",
                  child: Column(
                    children: [
                      _destinationItem("Ella", 45),
                      _destinationItem("Galle", 38),
                      _destinationItem("Kandy", 32),
                      _destinationItem("Sigiriya", 28),
                      _destinationItem("Mirissa", 15),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _destinationItem(String name, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(name, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Text("$count plans", style: const TextStyle(color: AppTheme.accentOchre, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.delta, required this.icon});

  @override
  Widget build(BuildContext context) {
    final bool isPositive = delta.startsWith("+");
    return Container(
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
              Icon(icon, color: AppTheme.accentOchre.withValues(alpha: 0.5), size: 20),
              const Spacer(),
              Text(
                delta,
                style: TextStyle(
                  color: isPositive ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white54, letterSpacing: 1, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _DashboardPanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.5)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
