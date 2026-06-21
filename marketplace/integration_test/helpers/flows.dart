// Étapes de parcours réutilisables (auth, navigation par onglets, ouverture
// d'une fiche produit) pour les tests d'intégration KENZORF.
//
// Pilotage par texte localisé fr + `Semantics` (l'app n'a pas de Key de test).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenzorf_marketplace/core/widgets/primary_button.dart';
import 'package:kenzorf_marketplace/core/widgets/product_card.dart';

import 'test_harness.dart';

/// Index/labels des onglets de la coquille (libellés `Semantics`).
class Tabs {
  static String get home => fr('nav.home'); // Accueil
  static String get catalog => fr('nav.catalog'); // Catalogue
  static String get cart => fr('nav.cart'); // Panier
  static String get orders => fr('nav.orders'); // Commandes
  static String get profile => fr('nav.profile'); // Profil
}

/// Bascule sur un onglet de la barre de navigation.
///
/// La barre `_KenzorfNavBar` rend chaque libellé en MAJUSCULES dans un `Text`
/// toujours présent (indépendant de l'état sélectionné), ce qui en fait une
/// cible stable. On tape l'`InkWell` ancêtre pour garantir le hit-test.
Future<void> goToTab(WidgetTester tester, String label) async {
  final upper = label.toUpperCase();
  final navText = find.text(upper);
  await pumpUntilFound(
    tester,
    navText,
    reason: 'onglet "$label" (texte "$upper") introuvable',
  );
  // Cible l'InkWell ancêtre du libellé (zone tappable de l'onglet).
  final inkwell = find.ancestor(
    of: navText.last,
    matching: find.byType(InkWell),
  );
  final target = inkwell.evaluate().isNotEmpty ? inkwell.first : navText.last;
  await tester.tap(target);
  await pumpUntilSettled(tester);
}

/// Tape le bouton principal (`PrimaryButton`) portant [label]. Ce widget est un
/// `GestureDetector` + `Semantics`, repéré par son libellé.
///
/// On s'assure que le bouton est visible (les formulaires défilants le placent
/// souvent sous la ligne de flottaison) pour éviter un tap hors zone.
Future<void> tapPrimaryButton(WidgetTester tester, String label) async {
  final byType = find.byWidgetPredicate(
    (w) => w is PrimaryButton && w.label == label,
  );
  await pumpUntilFound(tester, byType, reason: 'PrimaryButton "$label"');
  try {
    await tester.ensureVisible(byType.first);
    await tester.pump(const Duration(milliseconds: 150));
  } catch (_) {
    // Pas dans un scrollable : on tape tel quel.
  }
  await tester.tap(byType.first, warnIfMissed: false);
  await pumpUntilSettled(tester);
}

/// Renseigne les deux champs d'un écran d'auth (email, mot de passe).
///
/// `AppTextField` rend le label en majuscules au-dessus du champ ; le champ
/// éditable est un `TextFormField` sans `labelText`. On cible donc les
/// `TextFormField` dans l'ordre d'apparition.
Future<void> login(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  final fields = find.byType(TextFormField);
  await pumpUntilFound(tester, fields);
  // Ordre login : [email, password].
  await enterText(tester, fields.at(0), email);
  await enterText(tester, fields.at(1), password);
  await tapPrimaryButton(tester, fr('auth.login.submit')); // Se connecter
}

/// Remplit le formulaire d'inscription (ordre des champs :
/// prénom, nom, email, téléphone, mot de passe) et soumet.
Future<void> register(
  WidgetTester tester, {
  required String firstName,
  required String lastName,
  required String email,
  required String password,
  String phone = '',
}) async {
  final fields = find.byType(TextFormField);
  await pumpUntilFound(tester, fields);
  await enterText(tester, fields.at(0), firstName);
  await enterText(tester, fields.at(1), lastName);
  await enterText(tester, fields.at(2), email);
  if (phone.isNotEmpty) {
    await enterText(tester, fields.at(3), phone);
  }
  await enterText(tester, fields.at(4), password);
  await tapPrimaryButton(tester, fr('auth.register.submit')); // S'inscrire
}

/// Ouvre la première fiche produit visible dans une liste de `ProductCard`.
/// Retourne le nom du produit ouvert (lu sur la carte) pour assertions.
///
/// On tape la `ProductCard` elle-même (racine tappable `PressableScale`),
/// après s'être assuré qu'elle est visible (les cartes sont révélées via une
/// animation `Reveal`).
Future<String> openFirstProduct(WidgetTester tester) async {
  final cards = find.byType(ProductCard);
  await pumpUntilFound(tester, cards, reason: 'aucune ProductCard visible');
  final firstCard = tester.widget<ProductCard>(cards.first);
  final name = firstCard.product.name;
  await tester.ensureVisible(cards.first);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(cards.first, warnIfMissed: false);
  await pumpUntilSettled(tester);
  return name;
}

/// Filtre le catalogue par [term] (recherche), attend le résultat, puis ouvre
/// la première carte produit correspondante. Retourne le nom du produit ouvert.
Future<String> openProductBySearch(WidgetTester tester, String term) async {
  await openCatalog(tester);
  final searchField = find.byType(TextField);
  await pumpUntilFound(tester, searchField);
  await tester.enterText(searchField.first, term);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await pumpUntilSettled(tester);
  // Attend que la carte du produit recherché soit chargée (réseau).
  await pumpUntilFound(
    tester,
    find.byType(ProductCard),
    reason: 'la recherche "$term" ne renvoie aucune carte',
  );
  return openFirstProduct(tester);
}

/// Va sur l'onglet Catalogue et attend que des cartes produit soient chargées.
Future<void> openCatalog(WidgetTester tester) async {
  await goToTab(tester, Tabs.catalog);
  await pumpUntilFound(
    tester,
    find.byType(ProductCard),
    reason: 'catalogue vide après chargement réseau',
  );
}
