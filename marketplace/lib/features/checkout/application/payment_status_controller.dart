import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/enums.dart';
import '../data/payment_repository.dart';

/// État du suivi de paiement.
class PaymentTracking {
  const PaymentTracking({
    required this.status,
    this.orderId,
    this.orderStatus,
    this.attempts = 0,
    this.timedOut = false,
    this.error,
  });

  final PaymentStatus status;
  final String? orderId;
  final String? orderStatus;
  final int attempts;
  final bool timedOut;
  final Object? error;

  bool get isFinal => status.isFinal;
  bool get isSucceeded => status == PaymentStatus.succeeded;
  bool get isFailedOrCancelled =>
      status == PaymentStatus.failed || status == PaymentStatus.cancelled;

  PaymentTracking copyWith({
    PaymentStatus? status,
    String? orderId,
    String? orderStatus,
    int? attempts,
    bool? timedOut,
    Object? error,
  }) => PaymentTracking(
    status: status ?? this.status,
    orderId: orderId ?? this.orderId,
    orderStatus: orderStatus ?? this.orderStatus,
    attempts: attempts ?? this.attempts,
    timedOut: timedOut ?? this.timedOut,
    error: error,
  );
}

/// Sonde périodiquement `GET /payments/{reference}/status` jusqu'à un statut
/// terminal (succès/échec/annulé) ou l'épuisement des tentatives.
///
/// **Important (spec §7)** : le passage `Paid` provient UNIQUEMENT du webhook
/// serveur reflété par ce statut, jamais du retour navigateur de la WebView.
///
/// Famille indexée par la `reference` du paiement (fournie à `build`).
class PaymentStatusController extends Notifier<PaymentTracking> {
  PaymentStatusController(this._reference);

  final String _reference;
  Timer? _timer;

  PaymentRepository get _repo => ref.read(paymentRepositoryProvider);

  @override
  PaymentTracking build() {
    ref.onDispose(() => _timer?.cancel());
    // Démarre le polling après initialisation.
    Future.microtask(start);
    return const PaymentTracking(status: PaymentStatus.pending);
  }

  /// (Re)lance le polling depuis zéro.
  void start() {
    _timer?.cancel();
    state = const PaymentTracking(status: PaymentStatus.pending);
    _poll();
    _timer = Timer.periodic(
      const Duration(milliseconds: AppConfig.paymentPollIntervalMs),
      (_) => _poll(),
    );
  }

  Future<void> _poll() async {
    if (state.isFinal) {
      _timer?.cancel();
      return;
    }
    if (state.attempts >= AppConfig.paymentPollMaxAttempts) {
      _timer?.cancel();
      state = state.copyWith(timedOut: true);
      return;
    }

    final attempt = state.attempts + 1;
    try {
      final result = await _repo.status(_reference);
      state = PaymentTracking(
        status: result.status,
        orderId: result.orderId,
        orderStatus: result.orderStatus,
        attempts: attempt,
      );
      if (result.status.isFinal) {
        _timer?.cancel();
      }
    } catch (e) {
      // On garde le polling actif malgré une erreur transitoire, mais on
      // mémorise la dernière erreur (utile si on finit par timeout).
      state = state.copyWith(attempts: attempt, error: e);
    }
  }

  void stop() => _timer?.cancel();
}

/// Provider famille indexé par la `reference` du paiement.
final paymentStatusControllerProvider =
    NotifierProvider.family<PaymentStatusController, PaymentTracking, String>(
      PaymentStatusController.new,
    );
