import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';
import 'home_shell.dart';
import 'menu_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context);
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = l10n.enterBothCredentials);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _apiService.fetchGrades(username, password, forceRefresh: false);

      await _storage.write(key: 'username', value: username);
      await _storage.write(key: 'password', value: password);
      TextInput.finishAutofillContext();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeShell()),
      );
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => _error = l10n.loginFailed(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.coral.withValues(
                              alpha:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? 0
                                  : 0.3,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset('assets/logo/app_icon_1024.png'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.loginHeroTitle,
                    textAlign: TextAlign.center,
                    style: AppText.largeTitle.copyWith(
                      color: p.label,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.loginHeroSubtitle,
                    textAlign: TextAlign.center,
                    style: AppText.subheadline.copyWith(
                      color: p.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AutofillGroup(
                    child: Container(
                      decoration: BoxDecoration(
                        color: p.card,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        children: [
                          _Field(
                            controller: _usernameController,
                            hint: l10n.usernameLabel,
                            icon: CupertinoIcons.person,
                            autofillHints: const [AutofillHints.username],
                            textInputAction: TextInputAction.next,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 48),
                            child: Container(height: 0.5, color: p.separator),
                          ),
                          _Field(
                            controller: _passwordController,
                            hint: l10n.password,
                            icon: CupertinoIcons.lock,
                            obscure: _obscure,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _login(),
                            suffix: GestureDetector(
                              onTap: () => setState(() => _obscure = !_obscure),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Icon(
                                  _obscure
                                      ? CupertinoIcons.eye_slash
                                      : CupertinoIcons.eye,
                                  size: 20,
                                  color: p.secondaryLabel,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _error == null
                        ? const SizedBox(width: double.infinity, height: 20)
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                            child: Text(
                              _error!,
                              style: AppText.footnote.copyWith(color: p.danger),
                            ),
                          ),
                  ),
                  PrimaryButton(
                    label: l10n.logIn,
                    loading: _isLoading,
                    onTap: _login,
                  ),
                  const SizedBox(height: 8),
                  PlainButton(
                    label: l10n.browseDiningMenus,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RestaurantMenuScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Iterable<String> autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.autofillHints,
    required this.textInputAction,
    this.obscure = false,
    this.onSubmitted,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 10),
          child: Icon(icon, size: 22, color: p.secondaryLabel),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            autocorrect: false,
            enableSuggestions: !obscure,
            autofillHints: autofillHints,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: AppText.body.copyWith(color: p.label),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppText.body.copyWith(color: p.tertiaryLabel),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              isDense: true,
            ),
          ),
        ),
        ?suffix,
      ],
    );
  }
}
