import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  String? get _checkoutUrl => widget.order.payment?.checkoutUrl;

  @override
  void initState() {
    super.initState();
    final url = _checkoutUrl;
    if (url != null && url.isNotEmpty) {
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
        ..loadRequest(Uri.parse(url));
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

    // Cas dégradé : pas de référence/URL de paiement renvoyée par l'API.
    if (reference == null || _checkoutUrl == null || _checkoutUrl!.isEmpty) {
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
