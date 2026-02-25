import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/auth_service.dart';
import '../widgets/batik_background.dart';
import '../widgets/dynamic_light_wrapper.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final user = await _authService.signInWithGoogle();
    setState(() => _isLoading = false);

    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google Sign-In failed. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: BatikBackground(
        opacity: 0.05,
        child: Stack(
          children: [
            // Background Image/Gradient
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.8),
                    AppTheme.primaryBlue,
                  ],
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
  
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOchre.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.accentOchre.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentOchre.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 64,
                        color: AppTheme.accentOchre,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Welcome Text
                    Text(
                      "TripMe.ai".toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "The Serendib Oracle Awaits",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white70,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 80),
                    
                    // Login Card
                    DynamicLightWrapper(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: AppTheme.glassDecoration(opacity: 0.1, radius: BorderRadius.circular(30)),
                        child: Column(
                          children: [
                            Text(
                              "Begin Your Journey",
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _handleGoogleSignIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primaryBlue,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                icon: _isLoading 
                                    ? const SizedBox(
                                        width: 20, 
                                        height: 20, 
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                                      )
                                    : Image.network(
                                        "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png",
                                        height: 20,
                                      ),
                                label: Text(
                                  _isLoading ? "CONSULTING..." : "Continue with Google",
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Time-Aware Overlay (reusing the logic from AppTheme)
            IgnorePointer(
              child: Container(
                color: AppTheme.getDynamicOverlay(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
