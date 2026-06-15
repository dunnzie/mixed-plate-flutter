import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/meal.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class SwipeScreen extends StatelessWidget {
  const SwipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (!state.hasHousehold) return _gate();
    if (state.meals.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (state.swipingDone) return _done(context, state);

    return _MealView(
      key: ValueKey(state.currentMealIndex),
      meal: state.meals[state.currentMealIndex],
      index: state.currentMealIndex,
      total: state.meals.length,
      onYes: () => state.swipe(true),
      onNo: () => state.swipe(false),
    );
  }

  Widget _gate() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people_outline_rounded,
                    color: AppColors.primary, size: 44),
              ),
              const SizedBox(height: 28),
              Text(
                'Pair up first',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Go to the Household tab, enter both names, then come back here to start swiping.',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _done(BuildContext context, AppState state) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: AppColors.like.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.like, size: 56),
              ),
              const SizedBox(height: 28),
              Text(
                'All Done!',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You've rated all the meals. Check Matches to see what you both agreed on.",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => state.loadMeals(),
                  child: const Text('Start Over'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Full-screen meal view with swipe animation ────────────────────────────────

class _MealView extends StatefulWidget {
  final Meal meal;
  final int index;
  final int total;
  final VoidCallback onYes;
  final VoidCallback onNo;

  const _MealView({
    super.key,
    required this.meal,
    required this.index,
    required this.total,
    required this.onYes,
    required this.onNo,
  });

  @override
  State<_MealView> createState() => _MealViewState();
}

class _MealViewState extends State<_MealView>
    with SingleTickerProviderStateMixin {
  Offset _drag = Offset.zero;
  late final AnimationController _animCtrl;
  Animation<Offset>? _anim;
  bool? _pendingLiked;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this)
      ..addListener(_onTick)
      ..addStatusListener(_onStatus);
  }

  @override
  void dispose() {
    _animCtrl
      ..removeListener(_onTick)
      ..removeStatusListener(_onStatus)
      ..dispose();
    super.dispose();
  }

  void _onTick() {
    if (_anim != null && mounted) setState(() => _drag = _anim!.value);
  }

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed && _pendingLiked != null) {
      final liked = _pendingLiked!;
      _pendingLiked = null;
      if (mounted) liked ? widget.onYes() : widget.onNo();
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_animCtrl.isAnimating) return;
    setState(() => _drag += Offset(d.delta.dx, d.delta.dy * 0.25));
  }

  void _onPanEnd(DragEndDetails _) {
    if (_animCtrl.isAnimating) return;
    final sw = MediaQuery.sizeOf(context).width;
    if (_drag.dx.abs() > sw * 0.33) {
      _flyOut(_drag.dx > 0);
    } else {
      _snapBack();
    }
  }

  void _tapBtn(bool liked) => _flyOut(liked);

  void _flyOut(bool liked) {
    final sw = MediaQuery.sizeOf(context).width;
    final end = Offset(liked ? sw * 1.7 : -sw * 1.7, _drag.dy - 50);
    _pendingLiked = liked;
    _animCtrl.duration = const Duration(milliseconds: 300);
    _anim = Tween<Offset>(begin: _drag, end: end)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _animCtrl.forward(from: 0);
  }

  void _snapBack() {
    _pendingLiked = null;
    _animCtrl.duration = const Duration(milliseconds: 420);
    _anim = Tween<Offset>(begin: _drag, end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut));
    _animCtrl.forward(from: 0);
  }

  double get _rotation => (_drag.dx / 20) * 0.05;
  double get _likeOpacity => (_drag.dx / 90).clamp(0.0, 1.0);
  double get _nopeOpacity => (-_drag.dx / 90).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final imageH = size.height * 0.60;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Swipeable card area ─────────────────────────────────────────────
          Expanded(
            child: ClipRect(
              child: GestureDetector(
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.identity()
                    ..translate(_drag.dx, _drag.dy)
                    ..rotateZ(_rotation),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Hero image with overlays ──────────────────────────
                      SizedBox(
                        height: imageH,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _HeroImage(meal: widget.meal, height: imageH),
                            // Counter at top center
                            Positioned(
                              top: topPad + 14,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: _CounterPill(
                                  current: widget.index + 1,
                                  total: widget.total,
                                ),
                              ),
                            ),
                            // YES badge (right swipe)
                            Positioned(
                              top: topPad + 56,
                              left: 20,
                              child: Opacity(
                                opacity: _likeOpacity,
                                child: const _SwipeBadge(
                                  label: 'YES',
                                  color: AppColors.like,
                                ),
                              ),
                            ),
                            // NOPE badge (left swipe)
                            Positioned(
                              top: topPad + 56,
                              right: 20,
                              child: Opacity(
                                opacity: _nopeOpacity,
                                child: const _SwipeBadge(
                                  label: 'NOPE',
                                  color: AppColors.dislike,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Meal info ─────────────────────────────────────────
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CuisineBadge(label: widget.meal.cuisine),
                              const SizedBox(height: 10),
                              Text(
                                widget.meal.name,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  height: 1.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _MetaItem(Icons.timer_outlined,
                                      '${widget.meal.prepTime} min'),
                                  const SizedBox(width: 20),
                                  _MetaItem(
                                      Icons.local_fire_department_outlined,
                                      '${widget.meal.calories} cal'),
                                  const SizedBox(width: 20),
                                  _MetaItem(Icons.star_rounded,
                                      widget.meal.rating.toStringAsFixed(1)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── YES / NO buttons — full width, no padding ─────────────────────
          _YesNoBar(
            onYes: () => _tapBtn(true),
            onNo: () => _tapBtn(false),
          ),
          SizedBox(height: bottomPad > 0 ? bottomPad : 0),
        ],
      ),
    );
  }
}

// ── Hero image ────────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  final Meal meal;
  final double height;

  const _HeroImage({required this.meal, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: meal.imageUrl.isEmpty
          ? _placeholder()
          : Image.network(
              meal.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : _placeholder(),
              errorBuilder: (_, __, ___) => _placeholder(),
            ),
    );
  }

  Widget _placeholder() {
    final palettes = [
      [const Color(0xFF2D5F75), const Color(0xFF1A3A4A)],
      [const Color(0xFFE8735A), const Color(0xFFB85540)],
      [const Color(0xFFD4A853), const Color(0xFFAA803A)],
      [const Color(0xFF4CAF78), const Color(0xFF2E8A55)],
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
          style: const TextStyle(fontSize: 96, color: Colors.white),
        ),
      ),
    );
  }
}

// ── Swipe badge (YES / NOPE overlay) ─────────────────────────────────────────

class _SwipeBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _SwipeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ── Counter pill ──────────────────────────────────────────────────────────────

class _CounterPill extends StatelessWidget {
  final int current;
  final int total;

  const _CounterPill({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.52),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$current of $total meals',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Cuisine badge ─────────────────────────────────────────────────────────────

class _CuisineBadge extends StatelessWidget {
  final String label;
  const _CuisineBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.secondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Meta item ─────────────────────────────────────────────────────────────────

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaItem(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 16, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── YES / NO bar — edge-to-edge ───────────────────────────────────────────────

class _YesNoBar extends StatelessWidget {
  final VoidCallback onYes;
  final VoidCallback onNo;
  const _YesNoBar({required this.onYes, required this.onNo});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      height: 82,
      child: Row(
        children: [
          // NO — left half
          Expanded(
            child: GestureDetector(
              onTap: onNo,
              child: Container(
                color: AppColors.dislikeLight,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.close_rounded,
                        color: AppColors.dislike, size: 32),
                    const SizedBox(width: 10),
                    Text(
                      'No',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dislike,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Divider
          Container(width: 1, color: Colors.grey.shade200),
          // YES — right half
          Expanded(
            child: GestureDetector(
              onTap: onYes,
              child: Container(
                color: AppColors.like,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded,
                        color: Colors.white, size: 32),
                    const SizedBox(width: 10),
                    Text(
                      'Yes',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
