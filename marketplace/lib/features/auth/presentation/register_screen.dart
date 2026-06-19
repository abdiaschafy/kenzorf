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

/// Écran d'inscription (crée un compte `Customer`).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
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
          .register(
            email: _email.text.trim(),
            password: _password.text,
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
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
    final v = Validators(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('auth.register.title'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.t('auth.register.subtitle'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.stone),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: l10n.t('auth.field.firstName'),
                  controller: _firstName,
                  textInputAction: TextInputAction.next,
                  validator: v.required(),
                  autofillHints: const [AutofillHints.givenName],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: l10n.t('auth.field.lastName'),
                  controller: _lastName,
                  textInputAction: TextInputAction.next,
                  validator: v.required(),
                  autofillHints: const [AutofillHints.familyName],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: l10n.t('auth.field.email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: v.email(),
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label:
                      '${l10n.t('auth.field.phone')} (${l10n.t('common.optional')})',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: l10n.t('auth.field.password'),
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  validator: v.password(),
                  onFieldSubmitted: (_) => _submit(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: l10n.t('auth.register.submit'),
                  loading: _submitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.t('auth.register.hasAccount'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _submitting ? null : () => context.pop(),
                      child: Text(l10n.t('auth.register.toLogin')),
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
