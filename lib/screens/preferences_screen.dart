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
  static const _cuisines = [
    'Italian', 'Mexican', 'Japanese', 'Indian', 'Thai',
    'Chinese', 'Greek', 'American', 'French', 'Korean',
    'Middle Eastern', 'Vietnamese', 'Hawaiian', 'Spanish',
  ];

  static const _dietaryTypes = [
    ('none', 'None'),
    ('vegetarian', 'Vegetarian'),
    ('vegan', 'Vegan'),
    ('pescatarian', 'Pescatarian'),
  ];

  static const _allergies = [
    ('gluten_free', 'Gluten-Free'),
    ('dairy_free', 'Dairy-Free'),
    ('nut_free', 'Nut-Free'),
    ('halal', 'Halal'),
  ];

  final _customAllergiesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _customAllergiesCtrl.text = state.customAllergies;
  }

  @override
  void dispose() {
    _customAllergiesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _saveBar(state),
      body: CustomScrollView(
        slivers: [
          // ── Title ─────────────────────────────────────────────────────────
          SliverAppBar.large(
            backgroundColor: AppColors.background,
            automaticallyImplyLeading: false,
            title: Text(
              'Your Taste Profile',
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
                // ── Instruction ───────────────────────────────────────────────
                Text(
                  'Tell us what you love and we\'ll find meals you\'ll both enjoy.',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 40),

                // ── Favourite Cuisines ─────────────────────────────────────────
                const _SectionHeader(
                  title: 'Favourite Cuisines',
                  subtitle: 'Tap the ones you love — we\'ll show you more.',
                ),
                const SizedBox(height: 16),
                _CuisineGrid(state: state, cuisines: _cuisines),

                const SizedBox(height: 40),

                // ── Dietary Style ──────────────────────────────────────────────
                const _SectionHeader(
                  title: 'Dietary Style',
                  subtitle: 'Pick the one that best describes you.',
                ),
                const SizedBox(height: 14),
                _DietaryToggle(state: state, options: _dietaryTypes),

                const SizedBox(height: 40),

                // ── Allergies ──────────────────────────────────────────────────
                const _SectionHeader(
                  title: 'Allergies & Restrictions',
                  subtitle: 'We\'ll filter out meals that don\'t work for you.',
                ),
                const SizedBox(height: 14),
                _AllergyList(state: state, items: _allergies),

                const SizedBox(height: 16),

                // ── Custom allergies field ─────────────────────────────────────
                TextField(
                  controller: _customAllergiesCtrl,
                  onChanged: state.setCustomAllergies,
                  decoration: const InputDecoration(
                    labelText: 'Anything else to avoid?',
                    hintText: 'e.g. shellfish, sesame, mushrooms',
                    prefixIcon: Icon(Icons.edit_outlined, size: 22),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 1,
                ),

                if (!state.hasHousehold) ...[
                  const SizedBox(height: 20),
                  _warnBanner(),
                ],

                const SizedBox(height: 28),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveBar(AppState state) {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.paddingOf(context).bottom + 16),
      child: ElevatedButton(
        onPressed: (state.hasHousehold && !_saving) ? () => _save(state) : null,
        child: _saving
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Text('Save Taste Profile'),
      ),
    );
  }

  Widget _warnBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: Colors.amber.shade700, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pair up first on the Household tab to save your profile.',
              style: GoogleFonts.inter(
                  fontSize: 16, color: Colors.amber.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(AppState state) async {
    state.setCustomAllergies(_customAllergiesCtrl.text);
    setState(() => _saving = true);
    await state.savePreferences();
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Taste profile saved!'),
          backgroundColor: AppColors.like,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Cuisine tag grid ──────────────────────────────────────────────────────────

class _CuisineGrid extends StatelessWidget {
  final AppState state;
  final List<String> cuisines;
  const _CuisineGrid({required this.state, required this.cuisines});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: cuisines.map((c) {
        final selected = state.favoriteCuisines.contains(c);
        return GestureDetector(
          onTap: () => state.toggleCuisine(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: selected ? AppColors.primary : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Text(
              c,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Dietary type toggle ───────────────────────────────────────────────────────

class _DietaryToggle extends StatelessWidget {
  final AppState state;
  final List<(String, String)> options;
  const _DietaryToggle({required this.state, required this.options});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: options.map((opt) {
          final (key, label) = opt;
          final selected = state.dietaryType == key;
          return Expanded(
            child: GestureDetector(
              onTap: () => state.setDietaryType(key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Allergy checklist ─────────────────────────────────────────────────────────

class _AllergyList extends StatelessWidget {
  final AppState state;
  final List<(String, String)> items;
  const _AllergyList({required this.state, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final (key, label) = items[i];
          final checked = state.dietaryPreferences[key] ?? false;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => state.updateDietaryPref(key, !checked),
                borderRadius: BorderRadius.only(
                  topLeft: i == 0 ? const Radius.circular(20) : Radius.zero,
                  topRight: i == 0 ? const Radius.circular(20) : Radius.zero,
                  bottomLeft: i == items.length - 1
                      ? const Radius.circular(20)
                      : Radius.zero,
                  bottomRight: i == items.length - 1
                      ? const Radius.circular(20)
                      : Radius.zero,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                  child: Row(
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: checked ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: checked
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: checked
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  indent: 22,
                  endIndent: 22,
                  color: Colors.grey.shade100,
                ),
            ],
          );
        }),
      ),
    );
  }
}
