import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

/// Screen 1 — Welcome / Onboarding.
/// "Get Started" -> Sign Up Screen (per spec navigation).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.heroGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // App logo mark
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                  ),
                  child: const Icon(Icons.eco_rounded, color: Colors.white, size: 60),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
                const SizedBox(height: 28),
                Text(
                  'CropLens',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 12),
                Text(
                  'Scan your crops. Detect disease instantly.\nGrow with confidence.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withOpacity(0.9)),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                const Spacer(flex: 1),
                const _FeatureChip(icon: Icons.camera_alt_outlined, label: 'Scan any crop with your camera'),
                const SizedBox(height: 12),
                const _FeatureChip(icon: Icons.bolt_outlined, label: 'Get instant AI diagnosis'),
                const SizedBox(height: 12),
                const _FeatureChip(icon: Icons.spa_outlined, label: 'Treatment & prevention tips'),
                const Spacer(flex: 2),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.goNamed('signup'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryDark,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.3, end: 0),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.goNamed('login'),
                  child: Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: Colors.white.withOpacity(0.85)),
                      children: const [
                        TextSpan(text: 'Log In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 550.ms),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14.5)),
        ),
      ],
    );
  }
}
