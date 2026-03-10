import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/batik_background.dart';
import '../../data/datasources/user_preference_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _agreedToTerms = false;
  bool _agreedToAiPolicy = false;

  void _completeOnboarding() async {
    if (_agreedToTerms && _agreedToAiPolicy) {
      await UserPreferenceService.updateTermsAgreement(true);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      if (FirebaseAuth.instance.currentUser != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BatikBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Text(
                  "Terms & Privacy",
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.glassDecoration(opacity: 0.1),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle("1. Privacy & Data Usage"),
                        _sectionBody("Hidden Gems Sri Lanka respects your privacy. We securely store your profile preferences and saved trips locally. We do not sell your personal data to third parties."),
                        const SizedBox(height: 24),
                        _sectionTitle("2. AI Oracle Usage Guidelines"),
                        _sectionBody("The AI Oracle is an automated tool designed to provide travel recommendations. While we strive for accuracy, the Oracle's suggestions may not always reflect real-time conditions. You must verify critical information (like visa requirements and safety advisories) independently.\n\nBy using the AI Oracle, you strictly agree:\n• Not to use the AI to generate harmful, illegal, or malicious itineraries.\n• Not to attempt to exploit or manipulate the AI's prompts.\n• To accept that AI suggestions are provided 'as is' without warranties."),
                        const SizedBox(height: 24),
                        _sectionTitle("3. User Conduct"),
                        _sectionBody("You agree to use the application respectfully and avoid any actions that could harm the application's infrastructure or other users' experiences."),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildCheckbox(
                      value: _agreedToTerms,
                      label: "I agree to the Privacy Policy and Terms of Service",
                      onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                    ),
                    const SizedBox(height: 12),
                    _buildCheckbox(
                      value: _agreedToAiPolicy,
                      label: "I agree to the AI Oracle Usage Rules and understand its limitations",
                      onChanged: (val) => setState(() => _agreedToAiPolicy = val ?? false),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_agreedToTerms && _agreedToAiPolicy) ? _completeOnboarding : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.modernGreen,
                          disabledBackgroundColor: AppTheme.modernGreen.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          "ACCEPT & CONTINUE",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: (_agreedToTerms && _agreedToAiPolicy) ? Colors.white : Colors.white54,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.modernGreen,
      ),
    );
  }

  Widget _sectionBody(String body) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        body,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white70,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildCheckbox({required bool value, required String label, required Function(bool?) onChanged}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              onChanged(val);
            },
            activeColor: AppTheme.modernGreen,
            checkColor: Colors.white,
            side: BorderSide(color: Colors.white.withOpacity(0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppTheme.modernGreen;
              return Colors.transparent;
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(!value);
            },
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
