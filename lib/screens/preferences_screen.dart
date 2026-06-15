import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  static const _dietary = [
    {'key': 'vegetarian', 'label': 'Vegetarian', 'emoji': '🥗'},
    {'key': 'vegan', 'label': 'Vegan', 'emoji': '🌱'},
    {'key': 'gluten_free', 'label': 'Gluten-Free', 'emoji': '🌾'},
    {'key': 'dairy_free', 'label': 'Dairy-Free', 'emoji': '🥛'},
    {'key': 'nut_free', 'label': 'Nut-Free', 'emoji': '🥜'},
    {'key': 'halal', 'label': 'Halal', 'emoji': '☪'},
  ];

  static const _cuisines = [
    'Italian', 'Mexican', 'Japanese', 'Indian', 'Thai',
    'Chinese', 'Greek', 'American', 'French', 'Korean',
    'Middle Eastern', 'Vietnamese', 'Hawaiian', 'Spanish',
  ];

  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: AppColors.background,
            automaticallyImplyLeading: false,
            title: Text(
              'Preferences',
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _sectionHeader('Dietary Restrictions'),
                const SizedBox(height: 16),
                _dietaryGrid(state),
                const SizedBox(height: 32),
                _sectionHeader('Favorite Cuisines'),
                const SizedBox(height: 6),
                Text(
                  'We\'ll prioritise these when swiping.',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                _cuisineWrap(state),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        (state.hasHousehold && !_saving) ? () => _save(state) : null,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Save Preferences'),
                  ),
                ),
                if (!state.hasHousehold) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Join a household to sync preferences.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _dietaryGrid(AppState state) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.9,
      ),
      itemCount: _dietary.length,
      itemBuilder: (context, i) {
        final opt = _dietary[i];
        final key = opt['key']!;
        final selected = state.dietaryPreferences[key] ?? false;

        return GestureDetector(
          onTap: () => state.updateDietaryPref(key, !selected),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : Colors.grey.shade200,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Text(opt['emoji']!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    opt['label']!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cuisineWrap(AppState state) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _cuisines.map((c) {
        final selected = state.favoriteCuisines.contains(c);
        return GestureDetector(
          onTap: () => state.toggleCuisine(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.secondary : Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: selected
                    ? AppColors.secondary
                    : Colors.grey.shade200,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(
              c,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _save(AppState state) async {
    setState(() => _saving = true);
    await state.savePreferences();
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved!'),
          backgroundColor: AppColors.like,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
