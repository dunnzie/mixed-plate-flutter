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

class _HouseholdPairingScreenState extends State<HouseholdPairingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return state.hasHousehold ? _householdDashboard(state) : _setupScreen(state);
  }

  // ── Dashboard (already in a household) ──────────────────────────────────────

  Widget _householdDashboard(AppState state) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: AppColors.background,
            automaticallyImplyLeading: false,
            title: Text(
              'Mixed Plate',
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _householdCard(state),
                const SizedBox(height: 20),
                _inviteCard(state),
                const SizedBox(height: 20),
                _statsRow(state),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () => _confirmLeave(state),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Leave Household'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _householdCard(AppState state) {
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
            color: AppColors.primary.withOpacity(0.35),
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
                  borderRadius: BorderRadius.circular(16),
                ),
                child:
                    const Icon(Icons.home_rounded, color: Colors.white, size: 26),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                ),
                child: Text(
                  'Active',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your household',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inviteCard(AppState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INVITE CODE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  state.householdCode ?? '------',
                  style: GoogleFonts.robotoMono(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 6,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: state.householdCode ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invite code copied!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Share this code so others can join your household.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(AppState state) {
    return Row(
      children: [
        _statBox(
          '${state.likedMeals.length}',
          'Liked',
          Icons.favorite_rounded,
          AppColors.secondary,
        ),
        const SizedBox(width: 12),
        _statBox(
          '${state.matches.length}',
          'Matches',
          Icons.people_rounded,
          AppColors.gold,
        ),
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

  Widget _statBox(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
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
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLeave(AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Leave Household?',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        content: const Text('Your swipe history will be cleared locally.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              state.leaveHousehold();
            },
            child: Text('Leave', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  // ── Setup (create or join) ───────────────────────────────────────────────────

  Widget _setupScreen(AppState state) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _heroSection(),
              const SizedBox(height: 40),
              _tabBar(),
              const SizedBox(height: 24),
              if (state.error != null) _errorBanner(state.error!),
              SizedBox(
                height: 220,
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _createTab(state),
                    _joinTab(state),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mixed\nPlate',
          style: GoogleFonts.playfairDisplay(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Swipe together, eat together.',
          style: GoogleFonts.inter(
            fontSize: 17,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _tabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabs,
        labelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Create Household'),
          Tab(text: 'Join with Code'),
        ],
      ),
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _createTab(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Household Name',
            hintText: 'e.g. The Smiths',
            prefixIcon: Icon(Icons.home_outlined),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => _doCreate(state),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: state.isLoading ? null : () => _doCreate(state),
          child: state.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text('Create Household'),
        ),
      ],
    );
  }

  Widget _joinTab(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            labelText: 'Invite Code',
            hintText: 'Enter 6-character code',
            prefixIcon: Icon(Icons.vpn_key_outlined),
          ),
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          onSubmitted: (_) => _doJoin(state),
        ),
        ElevatedButton(
          onPressed: state.isLoading ? null : () => _doJoin(state),
          child: state.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text('Join Household'),
        ),
      ],
    );
  }

  void _doCreate(AppState state) {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    state.createHousehold(name);
  }

  void _doJoin(AppState state) {
    final code = _codeController.text.trim();
    if (code.length < 6) return;
    state.joinHousehold(code);
  }
}
