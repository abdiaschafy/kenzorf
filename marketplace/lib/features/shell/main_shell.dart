import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/router/routes.dart';
import '../cart/application/cart_controller.dart';

/// Coquille principale avec barre de navigation inférieure (5 onglets).
///
/// Utilise `StatefulNavigationShell` (go_router) pour préserver l'état de
/// chaque onglet. L'accès aux onglets protégés (panier, commandes, profil) est
/// géré par la redirection du routeur ; ici on affiche simplement les onglets.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cartCount = ref.watch(cartCountProvider);
    final isAuth = ref.watch(authControllerProvider).isAuthenticated;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _goBranch,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l10n.t('nav.home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view_outlined),
            activeIcon: const Icon(Icons.grid_view),
            label: l10n.t('nav.catalog'),
          ),
          BottomNavigationBarItem(
            icon: _CartIcon(count: isAuth ? cartCount : 0, filled: false),
            activeIcon: _CartIcon(count: isAuth ? cartCount : 0, filled: true),
            label: l10n.t('nav.cart'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            activeIcon: const Icon(Icons.receipt_long),
            label: l10n.t('nav.orders'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: l10n.t('nav.profile'),
          ),
        ],
      ),
    );
  }
}

/// Icône panier avec pastille de comptage.
class _CartIcon extends StatelessWidget {
  const _CartIcon({required this.count, required this.filled});

  final int count;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      filled ? Icons.shopping_bag : Icons.shopping_bag_outlined,
    );
    if (count <= 0) return icon;
    return Badge(label: Text('$count'), child: icon);
  }
}

/// Helper de redirection : si l'utilisateur n'est pas connecté et tente
/// d'accéder à une route protégée, on l'envoie vers la connexion.
String? guardRedirect({
  required bool isAuthenticated,
  required bool isUnknown,
  required String location,
}) {
  // Pendant le bootstrap, on ne redirige pas (l'écran de démarrage est affiché).
  if (isUnknown) return null;

  final isAuthRoute =
      location == AppRoutes.login || location == AppRoutes.register;

  final isProtected = AppRoutes.protectedPrefixes.any(
    (prefix) => location == prefix || location.startsWith('$prefix/'),
  );

  if (!isAuthenticated && isProtected) {
    return AppRoutes.login;
  }

  // Déjà connecté mais sur un écran d'auth : rediriger vers l'accueil.
  if (isAuthenticated && isAuthRoute) {
    return AppRoutes.home;
  }

  return null;
}
