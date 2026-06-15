import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/meal.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Title ──────────────────────────────────────────────────────────
          SliverAppBar.large(
            backgroundColor: AppColors.background,
            automaticallyImplyLeading: false,
            title: Text(
              'Your Matches',
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // ── Subtitle ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Text(
                state.matches.isEmpty
                    ? 'Meals you both liked will appear here.'
                    : 'You both said yes to these. Tap a meal for details.',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────────
          if (state.matches.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(hasHousehold: state.hasHousehold),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MatchRow(meal: state.matches[i]),
                    if (i < state.matches.length - 1)
                      const Divider(
                          height: 1, indent: 116, endIndent: 24),
                  ],
                ),
                childCount: state.matches.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ── Match row (image left, text right) ────────────────────────────────────────

class _MatchRow extends StatelessWidget {
  final Meal meal;
  const _MatchRow({required this.meal});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDetail(context),
      splashColor: AppColors.primary.withOpacity(0.05),
      highlightColor: AppColors.primary.withOpacity(0.03),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Thumbnail ────────────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 92,
                height: 92,
                child: meal.imageUrl.isEmpty
                    ? _placeholder()
                    : Image.network(
                        meal.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // ── Info ─────────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Cuisine prominently in coral
                  Text(
                    meal.cuisine,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tags row (first 2 tags) + stats
                  if (meal.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: meal.tags.take(2).map((t) => _tag(t)).toList(),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _chip(Icons.timer_outlined, '${meal.prepTime} min'),
                      const SizedBox(width: 16),
                      _chip(Icons.star_rounded,
                          meal.rating.toStringAsFixed(1)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Chevron ───────────────────────────────────────────────────────
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    final palettes = [
      [const Color(0xFF2D5F75), const Color(0xFF1A3A4A)],
      [const Color(0xFFE8735A), const Color(0xFFB85540)],
      [const Color(0xFFD4A853), const Color(0xFFAA803A)],
    ];
    final pair = palettes[meal.id.hashCode.abs() % palettes.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: pair,
        ),
      ),
      child: Center(
        child: Text(
          meal.name.isNotEmpty ? meal.name[0] : '🍽',
          style: const TextStyle(fontSize: 32, color: Colors.white),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: ctrl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (meal.imageUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        meal.imageUrl,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.restaurant_rounded,
                              size: 56, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.cuisine,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meal.name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        meal.description,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _detailPill(Icons.timer_outlined,
                              '${meal.prepTime} min', AppColors.primary),
                          _detailPill(Icons.local_fire_department_outlined,
                              '${meal.calories} cal', AppColors.secondary),
                          _detailPill(Icons.star_rounded,
                              meal.rating.toStringAsFixed(1), AppColors.gold),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: meal.tags
                            .map(
                              (t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  t,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasHousehold;
  const _EmptyState({required this.hasHousehold});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text(
              hasHousehold ? 'No matches yet' : 'Pair up first',
              style: GoogleFonts.playfairDisplay(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasHousehold
                  ? 'Go to the Swipe tab and say Yes to meals you like. When you both like the same meal it appears here.'
                  : 'Go to the Household tab, enter both names, then start swiping.',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
