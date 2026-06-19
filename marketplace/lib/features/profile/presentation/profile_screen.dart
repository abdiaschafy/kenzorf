import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';

/// Profil : informations du compte, langue, accès aux adresses, déconnexion.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final locale = ref.watch(localeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('profile.title'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // En-tête utilisateur
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.ink,
                child: Text(
                  _initials(user?.firstName, user?.lastName),
                  style: const TextStyle(
                    color: AppColors.paper,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? '',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (user != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.stone,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Adresses
          _Tile(
            icon: Icons.location_on_outlined,
            label: l10n.t('profile.addresses'),
            onTap: () => context.push(AppRoutes.addresses),
          ),
          const Divider(height: 1),

          // Langue
          _LanguageTile(currentCode: locale.languageCode),
          const SizedBox(height: 28),

          // Déconnexion
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout),
            label: Text(l10n.t('auth.logout')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String? first, String? last) {
    final a = (first != null && first.isNotEmpty) ? first[0] : '';
    final b = (last != null && last.isNotEmpty) ? last[0] : '';
    final res = '$a$b'.toUpperCase();
    return res.isEmpty ? '?' : res;
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('auth.logout')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('auth.logout')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) context.go(AppRoutes.home);
    }
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _LanguageTile extends ConsumerWidget {
  const _LanguageTile({required this.currentCode});
  final String currentCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.language),
      title: Text(l10n.t('profile.language')),
      trailing: SegmentedButton<String>(
        segments: [
          ButtonSegment(
            value: 'fr',
            label: Text(l10n.t('profile.language.fr')),
          ),
          ButtonSegment(
            value: 'en',
            label: Text(l10n.t('profile.language.en')),
          ),
        ],
        selected: {currentCode},
        showSelectedIcon: false,
        onSelectionChanged: (selection) {
          ref
              .read(localeControllerProvider.notifier)
              .setLocale(Locale(selection.first));
        },
      ),
    );
  }
}
