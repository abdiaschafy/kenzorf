import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_localizer.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';

/// Écran de connexion (email + mot de passe).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.describeError(e))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final validators = Validators(l10n);

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.t('app.name'),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.t('auth.login.subtitle'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.stone),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  label: l10n.t('auth.field.email'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: validators.email(),
                  autofillHints: const [AutofillHints.email],
                  prefixIcon: const Icon(Icons.mail_outline),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: l10n.t('auth.field.password'),
                  controller: _passwordController,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  validator: validators.password(),
                  onFieldSubmitted: (_) => _submit(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: l10n.t('auth.login.submit'),
                  loading: _submitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.t('auth.login.noAccount'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => context.push(AppRoutes.register),
                      child: Text(l10n.t('auth.login.toRegister')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
