import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/order.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../application/payment_status_controller.dart';
import 'payment_result_view.dart';

/// Affiche la page de paiement KPay (`checkoutUrl`) en WebView tout en sondant
/// le statut serveur. Bascule automatiquement vers un écran de résultat
/// (succès / échec) dès qu'un statut terminal est confirmé côté serveur.
class PaymentWebViewScreen extends ConsumerStatefulWidget {
  const PaymentWebViewScreen({super.key, required this.order});

  final Order order;

  @override
  ConsumerState<PaymentWebViewScreen> createState() =>
      _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends ConsumerState<PaymentWebViewScreen> {
  WebViewController? _webController;
  bool _pageLoading = true;

  String? get _reference => widget.order.payment?.reference;

  /// `checkoutUrl` rendu **absolu** : l'API renvoie désormais une URL absolue,
  /// mais on reste défensif — une URL relative (ex. `/dev/checkout.html?...`
  /// émise par la passerelle factice) est résolue contre l'origine de l'API
  /// avant chargement, au lieu de planter (`Missing scheme in uri`).
  late final String? _checkoutUrl = AppConfig.resolveCheckoutUrl(
    widget.order.payment?.checkoutUrl,
  );

  @override
  void initState() {
    super.initState();
    final url = _checkoutUrl;
    // `resolveCheckoutUrl` garantit une URL absolue valide (avec schéma) ou
    // `null` ; on parse donc sans risque d'`ArgumentError`.
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri != null && uri.hasScheme) {
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _pageLoading = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _pageLoading = false);
            },
          ),
        )
        ..loadRequest(uri);
    }
  }

  Future<bool> _confirmLeave() async {
    final l10n = context.l10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('checkout.payment.waiting')),
        content: Text(l10n.t('checkout.pending.message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('common.continue')),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  void _goToOrder(String? orderId) {
    final id = orderId ?? widget.order.id;
    // Remplace la pile par l'accueil puis le détail de la commande.
    context.go(AppRoutes.orders);
    context.push(AppRoutes.orderDetailPath(id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reference = _reference;

    // Cas dégradé : pas de référence, ou `checkoutUrl` absent / non résoluble
    // en URL absolue (`resolveCheckoutUrl` renvoie alors `null`).
    if (reference == null || _checkoutUrl == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.t('checkout.title'))),
        body: ErrorView(
          icon: Icons.money_off_outlined,
          title: l10n.t('checkout.failure.title'),
          message: l10n.t('checkout.failure.message'),
          onRetry: () => context.go(AppRoutes.cart),
        ),
      );
    }

    final tracking = ref.watch(paymentStatusControllerProvider(reference));

    // Bascule vers l'écran de résultat dès qu'un statut terminal est atteint.
    if (tracking.isFinal) {
      return PaymentResultView(
        succeeded: tracking.isSucceeded,
        orderId: tracking.orderId ?? widget.order.id,
        onViewOrder: () => _goToOrder(tracking.orderId),
        onRetry: () => context.go(AppRoutes.cart),
      );
    }

    if (tracking.timedOut) {
      return PaymentResultView.pending(
        orderId: tracking.orderId ?? widget.order.id,
        onViewOrder: () => _goToOrder(tracking.orderId),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmLeave();
        if (leave && mounted) {
          ref.read(paymentStatusControllerProvider(reference).notifier).stop();
          _goToOrder(widget.order.id);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.t('checkout.payment.title')),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(2),
            child: _PollingIndicator(),
          ),
        ),
        body: Stack(
          children: [
            if (_webController != null)
              WebViewWidget(controller: _webController!),
            if (_pageLoading)
              const ColoredBox(color: AppColors.cream, child: LoadingView()),
            // Bandeau d'attente de confirmation serveur.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _WaitingBanner(
                message: l10n.t('checkout.payment.waiting'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PollingIndicator extends StatelessWidget {
  const _PollingIndicator();

  @override
  Widget build(BuildContext context) {
    return const LinearProgressIndicator(minHeight: 2);
  }
}

class _WaitingBanner extends StatelessWidget {
  const _WaitingBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.ink,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.paper),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.paper, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
