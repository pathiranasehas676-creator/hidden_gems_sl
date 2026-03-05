import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/locale_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/batik_background.dart';
import '../widgets/custom_buttons.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BatikBackground(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: AppTheme.ceylonBlue,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.premiumShadow,
                ),
                child: const Icon(
                  Icons.travel_explore,
                  size: 64,
                  color: AppTheme.sigiriyaOchre,
                ),
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                "AdvanceTravel.me",
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.ceylonBlue,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                "Plan like a local. Explore like a pro.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              // English Button
              PrimaryButton(
                label: "Continue in English",
                onPressed: () {
                  context.read<LocaleProvider>().setLocale('en');
                },
              ),
              const SizedBox(height: 16),
              // Sinhala Button
              OchreButton(
                label: "සිංහල දිගටම",
                onPressed: () {
                  context.read<LocaleProvider>().setLocale('si');
                },
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  // Default behavior
                },
                child: Text(
                  "SKIP",
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

