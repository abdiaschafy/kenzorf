// Enums du domaine KENZORF, alignés à l'identique sur les enums .NET
// (spec §2). Sérialisés en **string** dans le JSON de l'API.

/// Rayon / public visé par un article.
enum Gender {
  men('Men'),
  women('Women'),
  unisex('Unisex'),
  kids('Kids');

  const Gender(this.wire);

  /// Valeur exacte échangée avec l'API (`"Men"`, `"Women"`, …).
  final String wire;

  static Gender fromWire(String? value) => Gender.values.firstWhere(
    (g) => g.wire == value,
    orElse: () => Gender.unisex,
  );

  /// Clé de traduction (`gender.Men`, …).
  String get l10nKey => 'gender.$wire';
}

/// Cycle de vie d'une commande.
enum OrderStatus {
  pending('Pending'),
  paid('Paid'),
  processing('Processing'),
  shipped('Shipped'),
  delivered('Delivered'),
  cancelled('Cancelled'),
  refunded('Refunded');

  const OrderStatus(this.wire);

  final String wire;

  static OrderStatus fromWire(String? value) => OrderStatus.values.firstWhere(
    (s) => s.wire == value,
    orElse: () => OrderStatus.pending,
  );

  String get l10nKey => 'orderStatus.$wire';

  /// Une commande `Pending` peut encore être annulée par le client.
  bool get isCancellable => this == OrderStatus.pending;

  /// Une commande `Pending` reste payable (relance du checkout).
  bool get isPayable => this == OrderStatus.pending;

  /// Statut terminal négatif (annulée / remboursée) — hors timeline normale.
  bool get isTerminalNegative =>
      this == OrderStatus.cancelled || this == OrderStatus.refunded;

  /// Étapes nominales d'une commande, dans l'ordre, pour la timeline de suivi.
  static const List<OrderStatus> timeline = [
    OrderStatus.pending,
    OrderStatus.paid,
    OrderStatus.processing,
    OrderStatus.shipped,
    OrderStatus.delivered,
  ];

  /// Position (0-based) dans la timeline nominale ; -1 si hors timeline.
  int get timelineIndex => timeline.indexOf(this);
}

/// État d'une transaction de paiement (KPay).
enum PaymentStatus {
  pending('Pending'),
  initiated('Initiated'),
  succeeded('Succeeded'),
  failed('Failed'),
  cancelled('Cancelled'),
  refunded('Refunded');

  const PaymentStatus(this.wire);

  final String wire;

  static PaymentStatus fromWire(String? value) => PaymentStatus.values
      .firstWhere((s) => s.wire == value, orElse: () => PaymentStatus.pending);

  String get l10nKey => 'paymentStatus.$wire';

  /// Statut terminal : le polling peut s'arrêter.
  bool get isFinal =>
      this == PaymentStatus.succeeded ||
      this == PaymentStatus.failed ||
      this == PaymentStatus.cancelled ||
      this == PaymentStatus.refunded;
}

/// Moyens de paiement KPay acceptés (spec §5 `CreateOrderRequest.paymentMethod`).
enum PaymentMethod {
  orangeMoney('orange_money'),
  mtn('mtn'),
  wave('wave'),
  moov('moov'),
  card('card');

  const PaymentMethod(this.wire);

  /// Valeur exacte attendue par l'API (`"orange_money"`, …).
  final String wire;

  static PaymentMethod? fromWire(String? value) {
    if (value == null) return null;
    for (final m in PaymentMethod.values) {
      if (m.wire == value) return m;
    }
    return null;
  }

  /// Clé de traduction (`payment.orange_money`, …).
  String get l10nKey => 'payment.$wire';
}
