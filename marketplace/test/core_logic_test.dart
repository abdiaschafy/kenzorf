// Tests unitaires de la logique pure de KENZORF Marketplace.
//
// On évite tout appel réseau : ces tests valident le formatage FCFA, le
// mapping des enums (string <-> Dart), la parité i18n fr/en et le parsing des
// DTOs clés.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenzorf_marketplace/core/api/api_exception.dart';
import 'package:kenzorf_marketplace/core/config/app_config.dart';
import 'package:kenzorf_marketplace/core/l10n/app_strings.dart';
import 'package:kenzorf_marketplace/core/models/cart.dart';
import 'package:kenzorf_marketplace/core/models/enums.dart';
import 'package:kenzorf_marketplace/core/models/product.dart';
import 'package:kenzorf_marketplace/core/utils/price_formatter.dart';

DioException _dioError({required int status, required Object data}) {
  final req = RequestOptions(path: '/cart/items');
  return DioException(
    requestOptions: req,
    response: Response<Object>(
      requestOptions: req,
      statusCode: status,
      data: data,
    ),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  // P1 — robustesse WebView paiement : `checkoutUrl` résolu en URL absolue.
  // En test, `AppConfig.apiBaseUrl` vaut la valeur par défaut compile-time
  // (`http://10.0.2.2:8080/api`) -> origine attendue `http://10.0.2.2:8080`.
  group('AppConfig.resolveCheckoutUrl (P1)', () {
    test('origine = schéma + hôte + port, sans /api ni délimiteurs parasites',
        () {
      expect(AppConfig.apiOrigin, 'http://10.0.2.2:8080');
    });

    test('URL relative enracinée -> résolue contre l’origine (hors /api)', () {
      expect(
        AppConfig.resolveCheckoutUrl('/dev/checkout.html?reference=abc'),
        'http://10.0.2.2:8080/dev/checkout.html?reference=abc',
      );
    });

    test('URL absolue -> renvoyée telle quelle', () {
      expect(
        AppConfig.resolveCheckoutUrl('https://kpay.site/pay/xyz'),
        'https://kpay.site/pay/xyz',
      );
    });

    test('URL relative sans slash initial -> résolue contre l’origine', () {
      expect(
        AppConfig.resolveCheckoutUrl('dev/checkout.html'),
        'http://10.0.2.2:8080/dev/checkout.html',
      );
    });

    test('null / vide / espaces -> null (cas dégradé géré par l’écran)', () {
      expect(AppConfig.resolveCheckoutUrl(null), isNull);
      expect(AppConfig.resolveCheckoutUrl(''), isNull);
      expect(AppConfig.resolveCheckoutUrl('   '), isNull);
    });

    test('la valeur résolue est toujours absolue (schéma présent)', () {
      final resolved = AppConfig.resolveCheckoutUrl('/dev/checkout.html');
      expect(resolved, isNotNull);
      expect(Uri.parse(resolved!).hasScheme, isTrue);
    });
  });

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

    test('les clés d\'erreur panier sont traduites (fr + en)', () {
      for (final key in const [
        'cart.quantity.max',
        'cart.quantity.min',
        'cart.productVariantId.required',
        'common.validationFailed',
        'variant.outOfStock',
      ]) {
        expect(kStringsFr.containsKey(key), isTrue, reason: 'fr manque $key');
        expect(kStringsEn.containsKey(key), isTrue, reason: 'en manque $key');
      }
    });
  });

  group('ApiException — extraction des clés de validation (bug panier)', () {
    test('422 FluentValidation : remonte la clé de champ (cart.quantity.max)',
        () {
      final ex = ApiException.fromDio(
        _dioError(
          status: 422,
          data: {
            'code': 'common.validationFailed',
            'messageKey': 'common.validationFailed',
            'params': <String, dynamic>{},
            'status': 422,
            'errors': {
              'quantity': ['cart.quantity.max'],
            },
          },
        ),
      );
      // La clé de champ est préférée au messageKey générique : message précis.
      expect(ex.messageKey, 'cart.quantity.max');
      expect(ex.status, 422);
    });

    test('ProblemDetails ASP.NET (400) sans code : ignore les phrases brutes',
        () {
      final ex = ApiException.fromDio(
        _dioError(
          status: 400,
          data: {
            'title': 'One or more validation errors occurred.',
            'status': 400,
            'errors': {
              'request': ['The request field is required.'],
            },
          },
        ),
      );
      // "The request field is required." n'est pas une clé i18n -> repli.
      expect(ex.messageKey, 'error.unknown');
      expect(ex.status, 400);
    });

    test('erreur métier standard : conserve le messageKey', () {
      final ex = ApiException.fromDio(
        _dioError(
          status: 409,
          data: {
            'code': 'variant.outOfStock',
            'messageKey': 'variant.outOfStock',
            'status': 409,
          },
        ),
      );
      expect(ex.messageKey, 'variant.outOfStock');
    });
  });

  group('Cart parsing — montants FCFA en double (contrat API)', () {
    test('parse des prix renvoyés en float (12000.0) sans erreur', () {
      final cart = Cart.fromJson({
        'id': 'cart1',
        'subtotal': 24000.0,
        'totalQuantity': 2,
        'currency': 'XOF',
        'items': [
          {
            'id': 'it1',
            'productVariantId': 'v1',
            'productId': 'p1',
            'productName': 'Bonnet',
            'productSlug': 'bonnet',
            'size': 'Taille unique',
            'color': 'Gris',
            'unitPrice': 12000.0,
            'quantity': 2,
            'lineTotal': 24000.0,
            'stockQuantity': 20,
          },
        ],
      });
      expect(cart.subtotal, 24000);
      expect(cart.items.first.unitPrice, 12000);
      expect(cart.items.first.lineTotal, 24000);
      expect(cart.items.first.stockQuantity, 20);
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
