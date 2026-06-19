/// Formatage des montants en FCFA (XOF).
///
/// KENZORF utilise la devise **FCFA (XOF)** avec des montants **entiers**
/// (pas de centimes). Le séparateur de milliers est une **espace simple**,
/// indépendamment de la locale. Exemple : `12000` -> `12 000 FCFA`.
class PriceFormatter {
  const PriceFormatter._();

  /// Formate un montant entier (ou arrondi) avec le suffixe ` FCFA`.
  ///
  /// `12000` -> `"12 000 FCFA"`.
  static String format(num amount, {String currency = 'FCFA'}) {
    return '${formatAmount(amount)} $currency';
  }

  /// Variante sans suffixe de devise (pour champs/labels compacts).
  /// Groupe les milliers par espace : `1234567` -> `"1 234 567"`.
  static String formatAmount(num amount) {
    final rounded = amount.round();
    final negative = rounded < 0;
    final digits = rounded.abs().toString();

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return negative ? '-${buffer.toString()}' : buffer.toString();
  }
}
