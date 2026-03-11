import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/auth_service.dart';
import '../widgets/batik_background.dart';
import '../widgets/dynamic_light_wrapper.dart';
import '../../data/datasources/user_preference_service.dart';
import 'home_screen.dart';
import 'terms_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoginMode = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      if (_isLoginMode) {
        await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await _authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
        );
      }
      
      if (mounted) {
        final profile = UserPreferenceService.getProfile();
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => profile.hasAgreedToTerms 
                ? const HomeScreen() 
                : const TermsScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Authentication Failed: ${e.toString().split(']').last}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final user = await _authService.signInWithGoogle();
    setState(() => _isLoading = false);

    if (user != null && mounted) {
      final profile = UserPreferenceService.getProfile();
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => profile.hasAgreedToTerms 
              ? const HomeScreen() 
              : const TermsScreen(),
        ),
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
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.2,
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.4),
                  AppTheme.primaryBlue,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  // Glowing Logo
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: AppTheme.glassDecoration(opacity: 0.05, radius: BorderRadius.circular(40)).copyWith(
                        border: Border.all(color: AppTheme.sigiriyaOchre.withOpacity(0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: AppTheme.sigiriyaOchre.withOpacity(0.15), blurRadius: 40, spreadRadius: 5)
                        ]
                      ),
                      child: const Icon(
                        Icons.explore_rounded,
                        size: 56,
                        color: AppTheme.sigiriyaOchre,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Typography
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 1),
                      children: [
                        const TextSpan(text: "TripMe", style: TextStyle(color: Colors.white)),
                        TextSpan(
                          text: ".ai", 
                          style: TextStyle(
                            color: AppTheme.sigiriyaOchre,
                            shadows: [Shadow(color: AppTheme.sigiriyaOchre.withOpacity(0.6), blurRadius: 15)]
                          )
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Unlock the Secrets of Serendib",
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.6), letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 48),
                  
                  // Login/Register Form (Glass)
                  DynamicLightWrapper(
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: AppTheme.glassDecoration(opacity: 0.08, blur: 25, isDark: true, radius: BorderRadius.circular(30)).copyWith(
                        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (!_isLoginMode) ...[
                              _buildTextField(
                                controller: _nameController,
                                label: "Full Name",
                                icon: Icons.person_outline,
                                validator: (v) => v!.isEmpty ? "Enter your name" : null,
                              ),
                              const SizedBox(height: 16),
                            ],
                            _buildTextField(
                              controller: _emailController,
                              label: "Email Address",
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => !v!.contains("@") ? "Invalid email" : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _passwordController,
                              label: "Password",
                              icon: Icons.lock_outline,
                              isPassword: true,
                              validator: (v) => v!.length < 6 ? "Minimum 6 characters" : null,
                            ),
                            const SizedBox(height: 32),
                            // Primary Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.modernGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 10,
                                  shadowColor: AppTheme.modernGreen.withOpacity(0.4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: _isLoading 
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : Text(
                                        _isLoginMode ? "LOGIN" : "CREATE ACCOUNT",
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 15),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                              style: TextButton.styleFrom(foregroundColor: Colors.white70),
                              child: Text(
                                _isLoginMode ? "New traveler? Begin your journey" : "Already an explorer? Login",
                                style: GoogleFonts.inter(fontSize: 13, decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text("OR", style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Google Sign In
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: Image.network(
                        "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png",
                        height: 20,
                      ),
                      label: Text("Continue with Google", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
        prefixIcon: Icon(icon, color: AppTheme.modernGreen.withOpacity(0.8), size: 22),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.modernGreen.withOpacity(0.5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2), // Deep glass insert
      ),
    );
  }
}
