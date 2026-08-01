import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/language_menu_button.dart';
import '../../state/auth_controller.dart';

/// Combined sign-in / sign-up screen shown when no session exists.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  String _role = 'member'; // 'member' or 'trainer'

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() => _isSignUp = !_isSignUp);
    context.read<AuthController>().clearError();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthController>();
    if (_isSignUp) {
      await auth.signUp(_name.text, _email.text, _password.text, role: _role);
    } else {
      await auth.signIn(_email.text, _password.text);
    }
    // On success the AuthGate swaps this screen out automatically.
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final p = context.palette;
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Language switcher — top corner (follows text direction).
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: 4, end: 4),
                child: LanguageMenuButton(color: p.muted),
              ),
            ),
            Expanded(
              child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand mark
                    Column(
                      children: [
                        Image.asset(
                          'assets/branding/arete_mark.png',
                          width: 84,
                          height: 84,
                          filterQuality: FilterQuality.high,
                        ),
                        const SizedBox(height: 10),
                        Text('ARETE',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 6,
                                color: p.text)),
                        Text(l.appTagline,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                                color: AppColors.brandGreen)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(_isSignUp ? l.authCreateAccount : l.authWelcomeBack,
                        textAlign: TextAlign.center,
                        style: context.textStyles.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      _isSignUp ? l.authSignUpSubtitle : l.authSignInSubtitle,
                      textAlign: TextAlign.center,
                      style: context.textStyles.bodyMedium
                          ?.copyWith(color: p.muted),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    if (_isSignUp) ...[
                      Text(l.authIAmA, style: context.textStyles.labelSmall),
                      const SizedBox(height: AppSpacing.sm),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                              value: 'member',
                              label: Text(l.roleTrainee),
                              icon: const Icon(Icons.directions_run)),
                          ButtonSegment(
                              value: 'trainer',
                              label: Text(l.roleTrainer),
                              icon: const Icon(Icons.sports_gymnastics)),
                        ],
                        selected: {_role},
                        onSelectionChanged: (s) =>
                            setState(() => _role = s.first),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                            labelText: l.fieldFullName,
                            prefixIcon: const Icon(Icons.person_outline)),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l.validatorEnterName
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                          labelText: l.fieldEmail,
                          prefixIcon: const Icon(Icons.mail_outline)),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return l.validatorEnterEmail;
                        if (!t.contains('@') || !t.contains('.')) {
                          return l.validatorValidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: l.fieldPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? l.passwordShow
                              : l.passwordHide,
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? l.validatorPasswordLength
                          : null,
                    ),

                    if (auth.error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.danger, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(auth.error!,
                                  style: context.textStyles.bodySmall
                                      ?.copyWith(color: AppColors.danger)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: auth.busy ? null : _submit,
                      child: auth.busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(_isSignUp
                              ? l.actionCreateAccount
                              : l.actionSignIn),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignUp ? l.authHaveAccount : l.authNewToArete,
                          style: context.textStyles.bodySmall
                              ?.copyWith(color: p.muted),
                        ),
                        TextButton(
                          onPressed: auth.busy ? null : _switchMode,
                          child: Text(_isSignUp
                              ? l.actionSignIn
                              : l.actionCreateAccount),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
              ),
          ],
        ),
      ),
    );
  }
}
