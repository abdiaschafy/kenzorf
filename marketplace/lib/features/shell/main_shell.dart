import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../cart/application/cart_controller.dart';

/// Coquille principale avec **barre de navigation custom** (pas le
/// `BottomNavigationBar` Material par défaut) : aplat charbon, libellés en
/// capitales fines, indicateur doré sous l'onglet actif, pastille panier.
///
/// Préserve l'état de chaque onglet via `StatefulNavigationShell`. L'accès aux
/// onglets protégés est géré par la redirection du routeur.
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
    // Lectures dérivées via `select` : la coquille ne se reconstruit que lorsque
    // le compteur (int) ou le booléen d'auth changent réellement. Cela évite le
    // « setState()/markNeedsBuild() called during build » qui survenait quand un
    // changement d'état panier/auth (login, ajout) était propagé pendant la
    // phase de build de `MainShell` — le rebuild est désormais planifié après la
    // frame courante au lieu de ré-entrer dans le build en cours.
    final cartCount = ref.watch(cartCountProvider);
    final isAuth = ref.watch(
      authControllerProvider.select((s) => s.isAuthenticated),
    );

    final items = <_NavItem>[
      _NavItem(Icons.home_outlined, Icons.home, l10n.t('nav.home')),
      _NavItem(Icons.grid_view_outlined, Icons.grid_view, l10n.t('nav.catalog')),
      _NavItem(
        Icons.shopping_bag_outlined,
        Icons.shopping_bag,
        l10n.t('nav.cart'),
        badge: isAuth ? cartCount : 0,
      ),
      _NavItem(
        Icons.receipt_long_outlined,
        Icons.receipt_long,
        l10n.t('nav.orders'),
      ),
      _NavItem(Icons.person_outline, Icons.person, l10n.t('nav.profile')),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _KenzorfNavBar(
        items: items,
        currentIndex: navigationShell.currentIndex,
        onTap: _goBranch,
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label, {this.badge = 0});
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;
}

class _KenzorfNavBar extends StatelessWidget {
  const _KenzorfNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.charcoal,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.goldLight : const Color(0xFF9C9385);

    Widget icon = Icon(
      selected ? item.activeIcon : item.icon,
      color: color,
      size: 24,
    );
    if (item.badge > 0) {
      icon = Badge(
        backgroundColor: AppColors.terracotta,
        textColor: AppColors.paper,
        label: Text('${item.badge}'),
        child: icon,
      );
    }

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indicateur doré au-dessus de l'onglet actif.
            AnimatedContainer(
              duration: AppMotion.micro,
              height: 2,
              width: selected ? 22 : 0,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            icon,
            const SizedBox(height: 5),
            Text(
              item.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                letterSpacing: 0.8,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
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
