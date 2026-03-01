import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'kb_manager_screen.dart';
import 'ai_monitoring_screen.dart';
import 'user_management_screen.dart';
import 'plan_inspector_screen.dart';

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
    const UserManagementScreen(),
    const PlanInspectorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.5,
          colors: [
            Color(0xFF1A2235), // Subtle glow
            Color(0xFF0F172A), // Slate Navy
            Color(0xFF0A101D), // Ultra Dark Navy
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            // Sidebar
            if (isDesktop)
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.6),
                      border: const Border(right: BorderSide(color: Colors.white10)),
                    ),
                    child: _buildSidebar(),
                  ),
                ),
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
                        color: AppTheme.silkPearl.withOpacity(0.015),
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
      ),
    );
  }

  Widget _buildTopBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.5),
            border: const Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentOchre.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentOchre.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(color: AppTheme.accentOchre.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)
                  ],
                ),
                child: const Icon(Icons.shield_outlined, color: AppTheme.accentOchre, size: 20),
              ),
              const SizedBox(width: 16),
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
              _statusBadge("SERVER: ONLINE", Colors.greenAccent),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=Admin&background=random"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ],
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
        _sidebarItem(4, Icons.fact_check_outlined, "Plan Inspector"),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppTheme.accentOchre.withOpacity(0.2), Colors.transparent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? const Border(left: BorderSide(color: AppTheme.accentOchre, width: 3)) : null,
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
