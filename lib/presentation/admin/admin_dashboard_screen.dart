import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import 'package:hidden_gems_sl/l10n/app_localizations.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderText(l10n),
                const SizedBox(height: 24),
                _buildExportButton(),
              ],
            )
          else
            Row(
              children: [
                _buildHeaderText(l10n),
                const Spacer(),
                _buildExportButton(),
              ],
            ),
          const SizedBox(height: 40),
          
          // Stats Row
          if (isMobile)
            Column(
              children: [
                _StatCard(label: l10n.totalUsers, value: "1,240", delta: "+12%", icon: Icons.people_alt_outlined, color: Colors.blueAccent),
                const SizedBox(height: 16),
                _StatCard(label: l10n.plansToday, value: "85", delta: "+5%", icon: Icons.auto_awesome_outlined, color: AppTheme.accentOchre),
                const SizedBox(height: 16),
                _StatCard(label: l10n.avgConfidence, value: "88.5%", delta: "-2%", icon: Icons.verified_user_outlined, color: Colors.purpleAccent),
                const SizedBox(height: 16),
                _StatCard(label: l10n.revenue, value: "42,500", delta: "+18%", icon: Icons.payments_outlined, color: Colors.greenAccent),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _StatCard(label: l10n.totalUsers, value: "1,240", delta: "+12%", icon: Icons.people_alt_outlined, color: Colors.blueAccent)),
                const SizedBox(width: 24),
                Expanded(child: _StatCard(label: l10n.plansToday, value: "85", delta: "+5%", icon: Icons.auto_awesome_outlined, color: AppTheme.accentOchre)),
                const SizedBox(width: 24),
                Expanded(child: _StatCard(label: l10n.avgConfidence, value: "88.5%", delta: "-2%", icon: Icons.verified_user_outlined, color: Colors.purpleAccent)),
                const SizedBox(width: 24),
                Expanded(child: _StatCard(label: l10n.revenue, value: "42,500", delta: "+18%", icon: Icons.payments_outlined, color: Colors.greenAccent)),
              ],
            ),
          
          const SizedBox(height: 40),
          
          // Secondary level
          if (isMobile)
            Column(
              children: [
                _DashboardPanel(
                  title: "API Performance (Latency ms)",
                  child: Container(
                    height: 300,
                    child: const Center(
                      child: Text("Chart Placeholder: Latency Graph", style: TextStyle(color: Colors.white24)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _DashboardPanel(
                  title: "Top Destinations",
                  child: Column(
                    children: [
                      _destinationItem("Ella", 45, 50),
                      _destinationItem("Galle", 38, 50),
                      _destinationItem("Kandy", 32, 50),
                      _destinationItem("Sigiriya", 28, 50),
                      _destinationItem("Mirissa", 15, 50),
                    ],
                  ),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _DashboardPanel(
                    title: "API Performance (Latency ms)",
                    child: Container(
                      height: 300,
                      child: const Center(
                        child: Text("Chart Placeholder: Latency Graph", style: TextStyle(color: Colors.white24)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: _DashboardPanel(
                    title: "Top Destinations",
                    child: Column(
                      children: [
                        _destinationItem("Ella", 45, 50),
                        _destinationItem("Galle", 38, 50),
                        _destinationItem("Kandy", 32, 50),
                        _destinationItem("Sigiriya", 28, 50),
                        _destinationItem("Mirissa", 15, 50),
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

  Widget _buildHeaderText(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFD9E9F2)],
          ).createShader(bounds),
          child: Text(l10n.goodMorningAdmin, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 6),
        Text(l10n.oracleToday, style: GoogleFonts.inter(color: Colors.white60, fontSize: 16)),
      ],
    );
  }

  Widget _buildExportButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: AppTheme.accentOchre.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.download_outlined, size: 20),
        label: const Text("Export Report", style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentOchre,
          foregroundColor: AppTheme.primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _destinationItem(String name, int count, double maxCount) {
    final double percentage = count / maxCount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text("$count plans", style: const TextStyle(color: AppTheme.accentOchre, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
               color: Colors.white10,
               borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.accentOchre, Colors.orangeAccent]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: AppTheme.accentOchre.withOpacity(0.5), blurRadius: 6, spreadRadius: 0)
                  ]
                ),
              ),
            ),
          )
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
  final Color color;

  const _StatCard({required this.label, required this.value, required this.delta, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final bool isPositive = delta.startsWith("+");
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: AppTheme.premiumShadow,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.transparent,
          ],
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
             children: [
               Container(
                 padding: const EdgeInsets.all(10),
                 decoration: BoxDecoration(
                   color: color.withOpacity(0.1),
                   shape: BoxShape.circle,
                   boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12, spreadRadius: 2)],
                 ),
                 child: Icon(icon, color: color, size: 24),
               ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? Colors.greenAccent : Colors.redAccent).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (isPositive ? Colors.greenAccent : Colors.redAccent).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isPositive ? Colors.greenAccent : Colors.redAccent,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
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
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(value, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white54, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.5)),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
