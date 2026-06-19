import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/catalog/presentation/catalog_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/checkout/presentation/payment_webview_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/product/presentation/product_detail_screen.dart';
import '../../features/profile/presentation/addresses_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/shell/splash_screen.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../models/order.dart';
import 'routes.dart';

/// Pont entre Riverpod et `GoRouter.refreshListenable` : notifie le routeur à
/// chaque changement d'état d'authentification pour ré-évaluer les redirections.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (_, _) => notifyListeners());
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Fournit le `GoRouter` de l'application (redirections selon l'auth).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      return guardRedirect(
        isAuthenticated: auth.isAuthenticated,
        isUnknown: auth.isUnknown,
        location: state.matchedLocation,
      );
    },
    routes: [
      // --- Authentification ---
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // --- Coquille à onglets (home/catalog/cart/orders/profile) ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.catalog,
                builder: (context, state) => const CatalogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (context, state) => const OrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // --- Routes de détail (au-dessus de la coquille) ---
      GoRoute(
        path: AppRoutes.product,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ProductDetailScreen(slug: state.pathParameters['slug'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.orderDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.payment,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final order = state.extra as Order?;
          if (order == null) {
            // Garde-fou : sans commande en `extra`, retour au panier.
            return const CartScreen();
          }
          return PaymentWebViewScreen(order: order);
        },
      ),
      GoRoute(
        path: AppRoutes.addresses,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddressesScreen(),
      ),
    ],
  );
});

/// Écran de démarrage exposé pour l'état `unknown`.
const splashScreen = SplashScreen();
