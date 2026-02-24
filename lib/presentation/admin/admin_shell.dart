import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'kb_manager_screen.dart';
import 'ai_monitoring_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  final List<Widget> _modules = [
    const AdminDashboardScreen(),
    const KBManagerScreen(),
    const AIMonitoringScreen(),
    const Center(child: Text("User Management Module")),
    const Center(child: Text("Settings Module")),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0A101D), // Ultra Dark Navy
      body: Row(
        children: [
          // Sidebar
          if (isDesktop)
            Container(
              width: 280,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(right: BorderSide(color: Colors.white12)),
              ),
              child: _buildSidebar(),
            ),
          
          // Content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(30)),
                    child: Container(
                      color: AppTheme.silkPearl.withValues(alpha: 0.02),
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: _modules,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: !isDesktop ? Drawer(child: _buildSidebar()) : null,
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppTheme.accentOchre, size: 20),
          const SizedBox(width: 12),
          Text(
            "TRIPME CONTROL CENTER",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          _statusBadge("SERVER: ONLINE", Colors.green),
          const SizedBox(width: 16),
          const CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=Admin"),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.accentOchre, size: 24),
              const SizedBox(width: 12),
              Text(
                "TripMe.ai",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sidebarItem(0, Icons.dashboard_customize_outlined, "Dashboard"),
        _sidebarItem(1, Icons.auto_stories_outlined, "Knowledge Base"),
        _sidebarItem(2, Icons.analytics_outlined, "AI Monitoring"),
        _sidebarItem(3, Icons.people_outline, "User Management"),
        _sidebarItem(4, Icons.settings_outlined, "System Settings"),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.logout, color: Colors.white54, size: 18),
            label: const Text("Exit Admin", style: TextStyle(color: Colors.white54)),
          ),
        ),
      ],
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentOchre.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.accentOchre : Colors.white54, size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
