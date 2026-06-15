import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _steps = [
    (
      icon: Icons.people_rounded,
      color: AppColors.primary,
      title: 'Pair with your partner',
      body: 'Enter both your names to create your shared household.',
    ),
    (
      icon: Icons.tune_rounded,
      color: AppColors.gold,
      title: 'Set your preferences',
      body: 'Tell us about allergies and your favourite cuisines.',
    ),
    (
      icon: Icons.restaurant_menu_rounded,
      color: AppColors.secondary,
      title: 'Swipe on meals',
      body: 'Swipe right on meals you\'d love, left on ones you wouldn\'t.',
    ),
    (
      icon: Icons.favorite_rounded,
      color: AppColors.like,
      title: 'See your matches',
      body: 'Meals you both liked appear here — tonight\'s dinner is sorted.',
    ),
  ];

  void _start(BuildContext context) {
    context.read<AppState>().markSeenWelcome();
    // _AppRouter rebuilds automatically and routes to LoginScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo mark
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.restaurant_rounded,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                'Mixed Plate',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find meals you both love',
                style: GoogleFonts.inter(
                  fontSize: 19,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 44),
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _steps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (_, i) => _StepCard(
                    number: i + 1,
                    icon: _steps[i].icon,
                    color: _steps[i].color,
                    title: _steps[i].title,
                    body: _steps[i].body,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _start(context),
                  child: const Text('Get Started'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int number;
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _StepCard({
    required this.number,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$number. ',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
