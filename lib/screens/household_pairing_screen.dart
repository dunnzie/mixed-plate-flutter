import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class HouseholdPairingScreen extends StatefulWidget {
  const HouseholdPairingScreen({super.key});

  @override
  State<HouseholdPairingScreen> createState() => _HouseholdPairingScreenState();
}

class _HouseholdPairingScreenState extends State<HouseholdPairingScreen> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return state.hasHousehold ? _dashboard(state) : _setupScreen(state);
  }

  // ── Dashboard ────────────────────────────────────────────────────────────────

  Widget _dashboard(AppState state) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: AppColors.background,
            automaticallyImplyLeading: false,
            title: Text(
              'Household',
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _pairCard(state),
                const SizedBox(height: 16),

                // ── Invite code card ─────────────────────────────────────────
                if (state.householdCode != null) ...[
                  _inviteCard(state.householdCode!),
                  const SizedBox(height: 16),
                ],

                _statsRow(state),
                const SizedBox(height: 24),
                _nextStep(),
                const SizedBox(height: 36),

                OutlinedButton.icon(
                  onPressed: () => _confirmReset(state),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Start Fresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    side: BorderSide(color: Colors.red.shade200),
                    minimumSize: const Size(double.infinity, 56),
                    textStyle: GoogleFonts.inter(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Sign Out ──────────────────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: () => _confirmSignOut(state),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: Colors.grey.shade300),
                    minimumSize: const Size(double.infinity, 56),
                    textStyle: GoogleFonts.inter(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),

                if (state.userEmail != null) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      'Signed in as ${state.userEmail}',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pairCard(AppState state) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF2D5F75)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.32),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 24),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                ),
                child: Text(
                  'Paired',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            state.householdName ?? 'Our Household',
            style: GoogleFonts.playfairDisplay(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your household',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.62),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inviteCard(String code) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Invite your partner',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Share this code so they can join on their device',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Text(
                    code,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _CopyButton(code: code),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsRow(AppState state) {
    return Row(
      children: [
        _statBox('${state.likedMeals.length}', 'Liked',
            Icons.favorite_rounded, AppColors.secondary),
        const SizedBox(width: 12),
        _statBox('${state.matches.length}', 'Matches',
            Icons.people_rounded, AppColors.gold),
        const SizedBox(width: 12),
        _statBox(
          '${(state.meals.length - state.currentMealIndex).clamp(0, 999)}',
          'To Swipe',
          Icons.restaurant_menu_rounded,
          AppColors.primary,
        ),
      ],
    );
  }

  Widget _statBox(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nextStep() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.arrow_forward_rounded,
              color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Head to the Swipe tab to start rating meals together.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.primary,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Start Fresh?',
            style: GoogleFonts.playfairDisplay(
                fontSize: 22, fontWeight: FontWeight.w700)),
        content: Text(
          'This clears your pairing and all swipe history. You\'ll stay signed in.',
          style: GoogleFonts.inter(
              fontSize: 17, height: 1.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    fontSize: 17, color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              state.leaveHousehold();
            },
            child: Text('Start Fresh',
                style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Sign out?',
            style: GoogleFonts.playfairDisplay(
                fontSize: 22, fontWeight: FontWeight.w700)),
        content: Text(
          'You\'ll need to sign in again to use the app.',
          style: GoogleFonts.inter(
              fontSize: 17, height: 1.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    fontSize: 17, color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              state.logout();
            },
            child: Text('Sign Out',
                style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // ── Setup screen (not in a household yet) ────────────────────────────────────

  Widget _setupScreen(AppState state) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, topPad + 36, 24, bottomPad + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Icon ─────────────────────────────────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_rounded,
                  color: AppColors.primary, size: 38),
            ),
            const SizedBox(height: 24),

            Text(
              'Join a Meal Pair',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 38,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a household or join your partner\'s with their invite code',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 17,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            // ── Error ─────────────────────────────────────────────────────────
            if (state.error != null) ...[
              _errorBanner(state.error!),
              const SizedBox(height: 16),
            ],

            // ── Create card ───────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_home_rounded,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create New Household',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Start fresh and share a code with your partner',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () => state.createHousehold('Our Household'),
                      child: state.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Create New Household'),
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or join existing',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
            ),

            // ── Join card ─────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.vpn_key_rounded,
                            color: AppColors.secondary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Join with Code',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Enter the 6-character code your partner shared',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(
                      hintText: 'ABC123',
                      prefixIcon: Icon(Icons.tag_rounded, size: 22),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    onSubmitted: (_) => _doJoin(state),
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                        null,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : () => _doJoin(state),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Join Household'),
                    ),
                  ),
                ],
              ),
            ),

            if (state.userEmail != null) ...[
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${state.userEmail}  ·  ',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => _confirmSignOut(state),
                    child: Text(
                      'Sign out',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.red.shade400, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: GoogleFonts.inter(
                    color: Colors.red.shade700, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _doJoin(AppState state) {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length < 6) return;
    FocusScope.of(context).unfocus();
    state.joinHousehold(code);
  }
}

// ── Copy button widget ────────────────────────────────────────────────────────

class _CopyButton extends StatefulWidget {
  final String code;
  const _CopyButton({required this.code});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton.icon(
        onPressed: _copy,
        icon: Icon(
          _copied ? Icons.check_rounded : Icons.copy_rounded,
          size: 18,
        ),
        label: Text(_copied ? 'Copied!' : 'Copy'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _copied ? AppColors.like : AppColors.primary,
          minimumSize: const Size(100, 56),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle:
              GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2),
        () => mounted ? setState(() => _copied = false) : null);
  }
}
