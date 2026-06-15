import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(28, topPad + 48, 28, bottomPad + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Brand mark ──────────────────────────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.restaurant_rounded,
                  color: Colors.white, size: 38),
            ),
            const SizedBox(height: 24),

            Text(
              'Welcome back',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 38,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sign in to Mixed Plate',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 44),

            // ── Error banner ─────────────────────────────────────────────────
            if (state.error != null) ...[
              _errorBanner(state.error!),
              const SizedBox(height: 16),
            ],

            // ── Fields ───────────────────────────────────────────────────────
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email address',
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.email_outlined, size: 22),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordCtrl,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 22),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _signIn(state),
            ),

            const SizedBox(height: 28),

            // ── Sign In button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isLoading ? null : () => _signIn(state),
                child: state.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Sign In'),
              ),
            ),

            const SizedBox(height: 24),

            // ── Sign up link ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: GoogleFonts.inter(
                      fontSize: 17, color: AppColors.textSecondary),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const SignupScreen()),
                  ),
                  child: Text(
                    'Create one',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
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

  void _signIn(AppState state) {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      // State error is cleared on next login attempt; just show locally
      return;
    }
    FocusScope.of(context).unfocus();
    state.login(email, password);
  }
}
