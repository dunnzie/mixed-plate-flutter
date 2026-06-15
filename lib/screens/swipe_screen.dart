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

    if (!state.hasHousehold) {
      return _empty(
        'Join a Household First',
        'Create or join a household on the Household tab to start swiping.',
        Icons.people_outline_rounded,
      );
    }

    if (state.meals.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.swipingDone) return _doneState(context, state);

    return _swipeUI(context, state);
  }

  Widget _swipeUI(BuildContext context, AppState state) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(state),
            _progressBar(state),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (state.currentMealIndex + 2 < state.meals.length)
                      _BackCard(
                          meal: state.meals[state.currentMealIndex + 2],
                          scale: 0.88,
                          yOffset: -22),
                    if (state.currentMealIndex + 1 < state.meals.length)
                      _BackCard(
                          meal: state.meals[state.currentMealIndex + 1],
                          scale: 0.94,
                          yOffset: -11),
                    _DraggableMealCard(
                      key: ValueKey(state.currentMealIndex),
                      meal: state.meals[state.currentMealIndex],
                      onLike: () => state.swipe(true),
                      onDislike: () => state.swipe(false),
                    ),
                  ],
                ),
              ),
            ),
            _actionRow(state),
          ],
        ),
      ),
    );
  }

  Widget _header(AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          Text(
            'Discover',
            style: GoogleFonts.playfairDisplay(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '${state.currentMealIndex + 1} / ${state.meals.length}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar(AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: LinearProgressIndicator(
          value: state.currentMealIndex / state.meals.length,
          backgroundColor: Colors.grey.shade200,
          color: AppColors.primary,
          minHeight: 4,
        ),
      ),
    );
  }

  Widget _actionRow(AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ActionBtn(
            onTap: () => state.swipe(false),
            icon: Icons.close_rounded,
            color: AppColors.dislike,
            size: 56,
          ),
          const SizedBox(width: 28),
          _ActionBtn(
            onTap: () => state.swipe(true),
            icon: Icons.favorite_rounded,
            color: AppColors.like,
            size: 68,
            filled: true,
          ),
          const SizedBox(width: 28),
          _ActionBtn(
            onTap: () => state.swipe(false),
            icon: Icons.skip_next_rounded,
            color: AppColors.gold,
            size: 56,
          ),
        ],
      ),
    );
  }

  Widget _doneState(BuildContext context, AppState state) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Color(0x1A4CAF78),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.like, size: 52),
              ),
              const SizedBox(height: 24),
              Text(
                'All Done!',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "You've rated all meals. Check the Matches tab to see what your household agrees on.",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: () => state.loadMeals(),
                child: const Text('Start Over'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(String title, String body, IconData icon) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Back cards (peeking behind) ───────────────────────────────────────────────

class _BackCard extends StatelessWidget {
  final Meal meal;
  final double scale;
  final double yOffset;

  const _BackCard(
      {required this.meal, required this.scale, required this.yOffset});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, yOffset),
      child: Transform.scale(
        scale: scale,
        child: MealCard(meal: meal),
      ),
    );
  }
}

// ── Draggable top card ────────────────────────────────────────────────────────

class _DraggableMealCard extends StatefulWidget {
  final Meal meal;
  final VoidCallback onLike;
  final VoidCallback onDislike;

  const _DraggableMealCard({
    super.key,
    required this.meal,
    required this.onLike,
    required this.onDislike,
  });

  @override
  State<_DraggableMealCard> createState() => _DraggableMealCardState();
}

class _DraggableMealCardState extends State<_DraggableMealCard>
    with SingleTickerProviderStateMixin {
  Offset _pos = Offset.zero;
  late AnimationController _ctrl;
  Animation<Offset>? _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this)
      ..addListener(() {
        if (_anim != null && mounted) setState(() => _pos = _anim!.value);
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _rotation => _pos.dx * 0.0007;
  double get _likeOpacity => (_pos.dx / 130).clamp(0.0, 1.0);
  double get _nopeOpacity => (-_pos.dx / 130).clamp(0.0, 1.0);

  void _onPanStart(DragStartDetails _) => _ctrl.stop();

  void _onPanUpdate(DragUpdateDetails d) =>
      setState(() => _pos += d.delta);

  void _onPanEnd(DragEndDetails _) {
    final sw = MediaQuery.of(context).size.width;
    if (_pos.dx > sw * 0.33) {
      _fly(true);
    } else if (_pos.dx < -sw * 0.33) {
      _fly(false);
    } else {
      _snapBack();
    }
  }

  void _fly(bool liked) {
    final sw = MediaQuery.of(context).size.width;
    _ctrl.duration = const Duration(milliseconds: 280);
    _anim = Tween<Offset>(
      begin: _pos,
      end: Offset(liked ? sw * 1.6 : -sw * 1.6, _pos.dy - 80),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward(from: 0).then((_) {
      if (liked) {
        widget.onLike();
      } else {
        widget.onDislike();
      }
    });
  }

  void _snapBack() {
    _ctrl.duration = const Duration(milliseconds: 500);
    _anim = Tween<Offset>(begin: _pos, end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _pos,
        child: Transform.rotate(
          angle: _rotation,
          child: Stack(
            children: [
              MealCard(meal: widget.meal),
              Positioned(
                top: 36,
                left: 20,
                child: Opacity(
                  opacity: _likeOpacity,
                  child: const _SwipeBadge(label: 'LIKE', color: AppColors.like, tilt: -0.25),
                ),
              ),
              Positioned(
                top: 36,
                right: 20,
                child: Opacity(
                  opacity: _nopeOpacity,
                  child: const _SwipeBadge(label: 'NOPE', color: AppColors.dislike, tilt: 0.25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double tilt;

  const _SwipeBadge(
      {required this.label, required this.color, required this.tilt});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 3),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final double size;
  final bool filled;

  const _ActionBtn({
    required this.onTap,
    required this.icon,
    required this.color,
    required this.size,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color : Colors.white,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(filled ? 0.4 : 0.18),
              blurRadius: filled ? 24 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: filled ? Colors.white : color, size: size * 0.44),
      ),
    );
  }
}

// ── Meal card (shared) ────────────────────────────────────────────────────────

class MealCard extends StatelessWidget {
  final Meal meal;

  const MealCard({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _image(),
            _gradient(),
            _info(),
          ],
        ),
      ),
    );
  }

  Widget _image() {
    if (meal.imageUrl.isEmpty) return _placeholder();
    return Image.network(
      meal.imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : _placeholder(),
      errorBuilder: (_, __, ___) => _placeholder(),
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
          style: const TextStyle(fontSize: 80, color: Colors.white),
        ),
      ),
    );
  }

  Widget _gradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.4, 1.0],
          colors: [Colors.transparent, Colors.black.withOpacity(0.88)],
        ),
      ),
    );
  }

  Widget _info() {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _chip(meal.cuisine, AppColors.secondary),
              const SizedBox(width: 8),
              const Icon(Icons.star_rounded, color: AppColors.gold, size: 15),
              const SizedBox(width: 3),
              Text(
                meal.rating.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            meal.name,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            meal.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withOpacity(0.78),
              height: 1.45,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _infoChip(Icons.local_fire_department_rounded, '${meal.calories} cal'),
              const SizedBox(width: 8),
              _infoChip(Icons.timer_outlined, '${meal.prepTime}m'),
              const Spacer(),
              ...meal.tags.take(2).map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _outline(t),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _outline(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Text(label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.white)),
    );
  }
}
