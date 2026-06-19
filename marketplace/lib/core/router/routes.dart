/// Chemins et noms de routes centralisés (go_router).
class AppRoutes {
  const AppRoutes._();

  // Auth
  static const String login = '/login';
  static const String register = '/register';

  // Onglets principaux (dans le ShellRoute)
  static const String home = '/home';
  static const String catalog = '/catalog';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String profile = '/profile';

  // Détails
  static const String product = '/product/:slug';
  static String productPath(String slug) => '/product/$slug';

  static const String orderDetail = '/orders/:id';
  static String orderDetailPath(String id) => '/orders/$id';

  static const String checkout = '/checkout';

  // Paiement (WebView KPay + suivi) — passe la commande en `extra`.
  static const String payment = '/payment';

  // Adresses
  static const String addresses = '/addresses';
  static const String addressForm = '/addresses/form';

  /// Routes nécessitant une authentification (sinon redirection vers login).
  static const Set<String> protectedPrefixes = {
    cart,
    orders,
    profile,
    checkout,
    payment,
    addresses,
  };
}
