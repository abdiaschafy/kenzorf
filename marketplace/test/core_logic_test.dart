// Tests unitaires de la logique pure de KENZORF Marketplace.
//
// On évite tout appel réseau : ces tests valident le formatage FCFA, le
// mapping des enums (string <-> Dart), la parité i18n fr/en et le parsing des
// DTOs clés.

import 'package:flutter_test/flutter_test.dart';
import 'package:kenzorf_marketplace/core/l10n/app_strings.dart';
import 'package:kenzorf_marketplace/core/models/enums.dart';
import 'package:kenzorf_marketplace/core/models/product.dart';
import 'package:kenzorf_marketplace/core/utils/price_formatter.dart';

void main() {
  group('PriceFormatter (FCFA, montants entiers)', () {
    test('formate avec séparateur de milliers et suffixe FCFA', () {
      expect(PriceFormatter.format(12000), '12 000 FCFA');
      expect(PriceFormatter.format(1500), '1 500 FCFA');
      expect(PriceFormatter.format(0), '0 FCFA');
    });

    test('arrondit les montants non entiers', () {
      expect(PriceFormatter.format(12000.4), '12 000 FCFA');
    });
  });

  group('Enums (sérialisation string identique au contrat)', () {
    test('Gender round-trip', () {
      expect(Gender.men.wire, 'Men');
      expect(Gender.fromWire('Women'), Gender.women);
      expect(Gender.fromWire('inconnu'), Gender.unisex);
    });

    test('OrderStatus mapping + helpers', () {
      expect(OrderStatus.fromWire('Paid'), OrderStatus.paid);
      expect(OrderStatus.pending.isCancellable, isTrue);
      expect(OrderStatus.shipped.isCancellable, isFalse);
    });

    test('PaymentStatus terminal', () {
      expect(PaymentStatus.succeeded.isFinal, isTrue);
      expect(PaymentStatus.initiated.isFinal, isFalse);
    });

    test('PaymentMethod wire values', () {
      expect(PaymentMethod.orangeMoney.wire, 'orange_money');
      expect(PaymentMethod.fromWire('wave'), PaymentMethod.wave);
      expect(PaymentMethod.fromWire(null), isNull);
    });
  });

  group('i18n parité fr/en', () {
    test('mêmes clés dans les deux dictionnaires', () {
      final frKeys = kStringsFr.keys.toSet();
      final enKeys = kStringsEn.keys.toSet();
      expect(
        frKeys.difference(enKeys),
        isEmpty,
        reason: 'Clés présentes en fr mais absentes en en',
      );
      expect(
        enKeys.difference(frKeys),
        isEmpty,
        reason: 'Clés présentes en en mais absentes en fr',
      );
    });
  });

  group('ProductDetail parsing & variantes', () {
    test('extrait tailles/couleurs et trouve une variante', () {
      final product = ProductDetail.fromJson({
        'id': 'p1',
        'name': 'T-shirt KENZORF',
        'slug': 't-shirt-kenzorf',
        'description': 'Coton bio',
        'basePrice': 12000,
        'currency': 'XOF',
        'gender': 'Men',
        'category': {'id': 'c1', 'name': 'Homme', 'slug': 'homme'},
        'images': [
          {
            'id': 'i1',
            'url': 'https://x/img.jpg',
            'isPrimary': true,
            'displayOrder': 0,
          },
        ],
        'variants': [
          {
            'id': 'v1',
            'sku': 'TS-M-NOIR',
            'size': 'M',
            'color': 'Noir',
            'price': 12000,
            'stockQuantity': 3,
            'inStock': true,
          },
          {
            'id': 'v2',
            'sku': 'TS-L-NOIR',
            'size': 'L',
            'color': 'Noir',
            'price': 12000,
            'stockQuantity': 0,
            'inStock': false,
          },
        ],
      });

      expect(product.sizes, ['M', 'L']);
      expect(product.colors, ['Noir']);
      expect(product.inStock, isTrue);

      final v = product.variantFor(size: 'M', color: 'Noir');
      expect(v?.id, 'v1');
      expect(v?.isLowStock, isTrue);

      final out = product.variantFor(size: 'L', color: 'Noir');
      expect(out?.inStock, isFalse);
    });
  });
}
