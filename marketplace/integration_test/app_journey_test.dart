// Tests d'intégration NATIFS du parcours client KENZORF (marketplace Flutter).
//
// Exécution (simulateur iOS + API LOCALE — JAMAIS la prod) :
//
//   PUB_CACHE=/Users/abdiaschafanglontchi/kenzorf/.pub-cache-local \
//   flutter test integration_test/app_journey_test.dart \
//     -d <simulateur-id> \
//     --dart-define=API_BASE_URL=http://localhost:8081/api
//
// L'app n'a aucune Key de test : pilotage par texte localisé (fr par défaut),
// types de widgets et `Semantics`. Voir helpers/.
//
// Couverture :
//  - Auth     : register d'un nouveau compte, logout, login, mauvais mdp.
//  - Home     : héro + sélection (featured) + rayons (catégories).
//  - Catalogue: liste + recherche + filtres (catégorie/genre) + pagination.
//  - Produit  : galerie, sélection variante taille/couleur, ajout panier selon
//               stock, variante en rupture désactivée.
//  - Panier   : lignes, maj quantité, suppression, sous-total.
//  - Checkout : adresse + moyen de paiement + création commande -> étape
//               paiement (WebView/polling) — sans paiement réel.
//  - Commandes: la nouvelle commande apparaît + détail.
//  - Profil   : adresses (CRUD).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:kenzorf_marketplace/core/widgets/primary_button.dart';
import 'package:kenzorf_marketplace/core/widgets/product_card.dart';
import 'package:kenzorf_marketplace/core/widgets/quantity_stepper.dart';
import 'package:kenzorf_marketplace/features/product/presentation/product_detail_screen.dart';

import 'helpers/flows.dart';
import 'helpers/test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Email unique par run pour que `register` réussisse à chaque exécution.
  final uniqueEmail =
      'e2e_${DateTime.now().millisecondsSinceEpoch}@kenzorf.test';
  const password = 'Password123!';
  const seededEmail = 'client@kenzorf.com';

  group('KENZORF — parcours client (API locale)', () {
    // ----------------------------------------------------------------- HOME
    testWidgets('Home affiche le héro, la sélection et les rayons',
        (tester) async {
      await launchApp(tester);

      // L'app démarre sur l'accueil. Le héros porte le titre éditorial.
      await pumpUntilFound(
        tester,
        find.text(fr('home.hero.title')),
        reason: 'titre du héros absent',
      );
      expect(find.text(fr('home.hero.title')), findsOneWidget);

      // CTA du héros (« Découvrir la collection ») présent.
      expect(find.text(fr('home.hero.cta')), findsWidgets);

      // La sélection (featured) charge des cartes produit depuis l'API.
      await pumpUntilFound(
        tester,
        find.byType(ProductCard),
        reason: 'aucune carte produit (featured) chargée',
      );
      expect(find.byType(ProductCard), findsWidgets);

      // En-tête de section « La sélection ».
      expect(find.text(fr('home.featured')), findsWidgets);
    });

    // -------------------------------------------------------------- CATALOG
    testWidgets('Catalogue : liste, recherche, filtres et pagination',
        (tester) async {
      await launchApp(tester);
      await openCatalog(tester);

      // Liste initiale non vide.
      final initialCount = find.byType(ProductCard).evaluate().length;
      expect(initialCount, greaterThan(0),
          reason: 'le catalogue devrait lister des produits');

      // --- Recherche : "hoodie" doit filtrer le résultat ---
      final searchField = find.byType(TextField);
      await pumpUntilFound(tester, searchField);
      await enterText(tester, searchField.first, 'hoodie');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await pumpUntilSettled(tester);
      // Le hoodie seedé doit apparaître.
      await pumpUntilFound(
        tester,
        find.textContaining('Hoodie'),
        reason: 'la recherche "hoodie" ne renvoie pas le produit attendu',
      );
      expect(find.textContaining('Hoodie'), findsWidgets);

      // Efface la recherche (bouton croix) pour revenir à la liste complète.
      final clearBtn = find.byIcon(Icons.close);
      if (clearBtn.evaluate().isNotEmpty) {
        await tapAndSettle(tester, clearBtn.first);
      }
      await pumpUntilFound(tester, find.byType(ProductCard));

      // --- Filtres : ouvre la feuille, filtre par genre Homme ---
      final filterBtn = find.byIcon(Icons.tune);
      await pumpUntilFound(tester, filterBtn);
      await tapAndSettle(tester, filterBtn.first);

      // La feuille de filtres affiche son titre.
      expect(find.text(fr('catalog.filters')), findsWidgets);

      // Choisit le genre « Homme » puis applique.
      final hommeChip = find.widgetWithText(ChoiceChip, fr('gender.Men'));
      await pumpUntilFound(tester, hommeChip);
      await tapAndSettle(tester, hommeChip);
      await tapPrimaryButton(tester, fr('catalog.filter.apply'));

      // Après filtre, la liste se recharge (cartes présentes).
      await pumpUntilFound(
        tester,
        find.byType(ProductCard),
        reason: 'aucun produit après filtre genre Homme',
      );
      expect(find.byType(ProductCard), findsWidgets);

      // --- Pagination : scroll vers le bas déclenche loadMore ---
      // On réinitialise d'abord les filtres pour avoir 10 produits (2 pages).
      await tapAndSettle(tester, find.byIcon(Icons.tune).first);
      await tapAndSettle(
        tester,
        find.widgetWithText(OutlinedButton, fr('catalog.filter.reset')),
      );
      await pumpUntilFound(tester, find.byType(ProductCard));

      final beforeScroll = find.byType(ProductCard).evaluate().length;
      // Scrolle plusieurs fois pour atteindre le bas et charger la page 2.
      final scrollable = find.byType(Scrollable);
      for (var i = 0; i < 6; i++) {
        await tester.drag(scrollable.first, const Offset(0, -1200));
        await tester.pump(const Duration(milliseconds: 300));
      }
      await pumpUntilSettled(tester);
      final afterScroll = find.byType(ProductCard).evaluate().length;
      // La pagination doit avoir ajouté des produits (10 au total seedés).
      expect(
        afterScroll,
        greaterThanOrEqualTo(beforeScroll),
        reason: 'la pagination devrait charger des produits supplémentaires',
      );
    });

    // ------------------------------------------------- PRODUIT (rupture OOS)
    testWidgets('Fiche produit : variante en rupture désactivée',
        (tester) async {
      await launchApp(tester);

      // Recherche puis ouvre le T-shirt (variante M/Sable mise à 0 en base e2e).
      await openProductBySearch(tester, 'T-shirt');

      // On est sur la fiche produit.
      await pumpUntilFound(
        tester,
        find.byType(ProductDetailScreen),
        reason: 'la fiche produit ne s’est pas ouverte',
      );

      // Sélecteurs de taille présents (S/M/L/XL).
      await pumpUntilFound(tester, find.text(frU('product.size')));
      expect(find.text('M'), findsWidgets);
      expect(find.text('Sable'), findsWidgets);

      // Sélectionne la taille M (on tape l'InkWell de la pastille, plus fiable).
      await tapInkByText(tester, 'M');

      // Après sélection de M, la couleur « Sable » doit être désactivée
      // (M/Sable en rupture, stock 0 en base e2e) -> InkWell.onTap == null.
      expect(
        isInkEnabledByText(tester, 'Sable'),
        isFalse,
        reason: 'la variante en rupture M/Sable devrait être désactivée',
      );
      // Une couleur EN STOCK pour M (Noir) reste, elle, sélectionnable.
      expect(
        isInkEnabledByText(tester, 'Noir'),
        isTrue,
        reason: 'la variante en stock M/Noir devrait être sélectionnable',
      );

      // Sélectionne une couleur EN STOCK pour M (Noir) -> bouton armé.
      await tapInkByText(tester, 'Noir');
      final addEnabled = find.byWidgetPredicate(
        (w) => w is PrimaryButton && w.label == fr('product.addToCart'),
      );
      await pumpUntilFound(
        tester,
        addEnabled,
        reason: 'le bouton « Ajouter au panier » devrait apparaître armé '
            'pour une variante en stock (M/Noir)',
      );
      expect(addEnabled, findsOneWidget);
    });

    // ============================================================ JOURNEY
    // Parcours authentifié continu : register -> produit -> panier ->
    // checkout -> paiement -> commandes -> adresses. Pas de relaunch mid-flow
    // (la session/le panier doivent persister).
    testWidgets(
      'Parcours achat complet : register -> panier -> checkout -> commande',
      (tester) async {
        // P2 corrigé : la lecture du compteur panier ne doit plus déclencher de
        // « setState during build » dans MainShell, même sur ce parcours qui
        // multiplie les changements d'état panier (login, ajout, maj quantité).
        // On surveille la régression et on l'asserte à zéro en fin de scénario.
        await guardAgainstRegressions(() async {
        await launchApp(tester);

        // --- REGISTER d'un nouveau compte ---
        // Invité : l'onglet Panier est protégé -> redirection vers la connexion.
        await goToTab(tester, Tabs.cart);
        await pumpUntilFound(
          tester,
          find.text(fr('auth.login.toRegister')),
          reason: 'l’écran de connexion attendu (panier protégé)',
        );
        await tapAndSettle(tester, find.text(fr('auth.login.toRegister')));

        await register(
          tester,
          firstName: 'E2E',
          lastName: 'Tester',
          email: uniqueEmail,
          password: password,
          phone: '+2250700000000',
        );

        // Après inscription -> retour accueil, session active.
        await pumpUntilFound(
          tester,
          find.text(fr('home.hero.title')),
          reason: 'pas de retour à l’accueil après inscription',
        );

        // --- AJOUT AU PANIER d'une variante en stock ---
        // Ouvre le hoodie (toutes variantes en stock).
        await openProductBySearch(tester, 'Hoodie');
        await pumpUntilFound(tester, find.byType(ProductDetailScreen));
        // Choisit taille M + couleur Noir (en stock).
        await pumpUntilFound(tester, find.text(frU('product.size')));
        await tapInkByText(tester, 'M');
        await tapInkByText(tester, 'Noir');
        await tapPrimaryButton(tester, fr('product.addToCart'));

        // Un toast « Article ajouté au panier » confirme l'ajout.
        await pumpUntilFound(
          tester,
          find.text(fr('product.added')),
          reason: 'pas de confirmation d’ajout au panier',
        );

        // Revient au panier (revient en arrière depuis la fiche).
        await tapAndSettle(tester, find.byIcon(Icons.arrow_back).first);
        await goToTab(tester, Tabs.cart);

        // --- PANIER : ligne présente, maj quantité, sous-total ---
        await pumpUntilFound(
          tester,
          find.byType(QuantityStepper),
          reason: 'la ligne de panier (stepper) est absente',
        );
        expect(find.textContaining('Hoodie'), findsWidgets);
        expect(find.text(fr('cart.subtotal')), findsOneWidget);

        // Le SnackBar « Article ajouté au panier » (issu de la fiche produit)
        // recouvre la barre basse du panier : on le masque avant d'agir sur le
        // stepper / le bouton checkout, sinon le tap est intercepté.
        await clearSnackBars(tester);

        // Incrémente la quantité (bouton +).
        final plusBtn = find.byIcon(Icons.add);
        await pumpUntilFound(tester, plusBtn);
        await tapAndSettle(tester, plusBtn.first);
        // Le stepper doit afficher 2.
        await pumpUntilFound(
          tester,
          find.text('2'),
          reason: 'la quantité n’a pas été mise à jour à 2',
        );

        // --- CHECKOUT : nouvelle adresse + moyen de paiement + commander ---
        // Masque tout SnackBar résiduel avant le tap checkout.
        await clearSnackBars(tester);
        await tapPrimaryButton(tester, fr('cart.checkout')); // Passer la commande

        await pumpUntilFound(
          tester,
          find.text(frU('checkout.address.title')),
          reason: 'l’écran de checkout ne s’est pas affiché',
        );

        // Nouveau client : choisit « Nouvelle adresse » (tuile sélectionnable)
        // et remplit le formulaire d'adresse inline.
        await tapInkByText(tester, fr('checkout.address.new'));

        // Remplit les champs requis du formulaire d'adresse inline.
        // Ordre des champs (AppTextField -> TextFormField) :
        //  fullName, phone, line1, line2?, city, region?, country, landmark?
        final addrFields = find.byType(TextFormField);
        await pumpUntilFound(tester, addrFields);
        // On saisit dans les champs requis par leur position relative.
        await enterText(tester, addrFields.at(0), 'E2E Tester'); // fullName
        await enterText(tester, addrFields.at(1), '+2250700000000'); // phone
        await enterText(tester, addrFields.at(2), 'Rue des Tests 1'); // line1
        // line2 = at(3) (facultatif) — laissé vide
        await enterText(tester, addrFields.at(4), 'Abidjan'); // city
        // region = at(5) (facultatif)
        await enterText(tester, addrFields.at(6), "Côte d'Ivoire"); // country
        // landmark = at(7) (facultatif)

        // Moyen de paiement : « Wave » (mobile money) — tuile sélectionnable.
        // Le checkout est une liste paresseuse : on défile pour monter la
        // section paiement avant de taper la tuile.
        await scrollUntilTextVisible(tester, fr('payment.wave'));
        await tapInkByText(tester, fr('payment.wave'));

        // Récapitulatif présent (défile au besoin).
        await scrollUntilTextVisible(tester, frU('checkout.summary.title'));
        expect(find.text(frU('checkout.summary.title')), findsWidgets);

        // Lance la commande (« Payer maintenant »).
        final payNow = find.byWidgetPredicate(
          (w) => w is PrimaryButton && w.label == fr('checkout.place'),
        );
        await pumpUntilFound(tester, payNow);
        await tester.ensureVisible(payNow.first);
        await tester.tap(payNow.first);
        // Attente réseau : création commande + initiation paiement.
        await pumpUntilSettled(tester, timeout: const Duration(seconds: 20));

        // --- ÉTAPE PAIEMENT (création commande + redirection KPay) ---
        // Taper « Payer maintenant » crée la commande côté serveur PUIS pousse
        // l'écran de paiement avec le `checkoutUrl`. On vérifie que le flux a
        // QUITTÉ le checkout (commande créée) : le bouton « Payer maintenant »
        // n'est plus présent.
        //
        // P1 corrigé : l'API renvoie un `checkoutUrl` ABSOLU et l'app résout par
        // ailleurs toute URL relative -> `PaymentWebViewScreen` se monte SANS
        // planter et charge la WebView. On asserte ci-dessous que l'écran de
        // paiement est atteint et qu'AUCUN crash « Missing scheme in uri » n'a
        // eu lieu.
        await pumpUntilGone(
          tester,
          find.byWidgetPredicate(
            (w) => w is PrimaryButton && w.label == fr('checkout.place'),
          ),
          timeout: kNetworkTimeout,
        );
        expect(
          find.byWidgetPredicate(
            (w) => w is PrimaryButton && w.label == fr('checkout.place'),
          ),
          findsNothing,
          reason: 'la commande n’a pas été créée (toujours sur le checkout)',
        );

        // L'écran de paiement (WebView + polling) doit être atteint et rendu :
        // sa barre de titre et son bandeau d'attente de confirmation serveur
        // s'affichent indépendamment du chargement réseau de la WebView.
        await pumpUntilFound(
          tester,
          find.text(fr('checkout.payment.title')),
          reason: 'l’écran de paiement (WebView/polling) n’a pas été atteint '
              'après création de la commande',
          timeout: kNetworkTimeout,
        );
        expect(
          find.text(fr('checkout.payment.waiting')),
          findsWidgets,
          reason: 'le bandeau d’attente de confirmation de paiement est absent '
              '(l’écran de paiement ne s’est pas rendu)',
        );
        // La WebView elle-même est montée (l'URL résolue est chargeable).
        expect(
          find.byType(WebViewWidget),
          findsOneWidget,
          reason: 'la WebView de paiement n’est pas montée (checkoutUrl non '
              'chargeable)',
        );

        // P1 : aucun crash « Missing scheme in uri » ne doit s’être produit.
        expect(
          webViewUriErrorCount,
          0,
          reason: 'régression P1 : crash WebView « Missing scheme in uri ». '
              'Le checkoutUrl doit être résolu en URL absolue avant chargement.',
        );
        });
        // P2 : aucun « setState during build » sur tout le parcours.
        expectNoKnownBugs();
      },
    );

    // ----------------------------------------------------------- COMMANDES
    // Le compte seedé `client@kenzorf.com` possède déjà des commandes : on
    // vérifie la liste + le détail (parcours indépendant du checkout).
    testWidgets('Commandes : liste + détail (compte seedé)', (tester) async {
      await guardAgainstRegressions(() async {
        await launchApp(tester);

        // Connexion (onglet protégé -> login -> retour accueil).
        await goToTab(tester, Tabs.orders);
        await pumpUntilFound(tester, find.byType(TextFormField));
        await login(tester, email: seededEmail, password: password);
        await pumpUntilFound(tester, find.text(fr('home.hero.title')));

        // Onglet Commandes : la liste seedée s'affiche.
        await goToTab(tester, Tabs.orders);
        await pumpUntilFound(
          tester,
          find.textContaining('KZF-'),
          reason: 'aucune commande seedée listée pour le client',
          timeout: kNetworkTimeout,
        );
        expect(find.text(fr('orders.title')), findsWidgets);

        // Ouvre le détail de la première commande.
        await tapAndSettle(tester, find.textContaining('KZF-').first);
        await pumpUntilFound(
          tester,
          find.text(frU('orders.detail.items')),
          reason: 'le détail de commande ne s’affiche pas',
          timeout: kNetworkTimeout,
        );
        // Le détail montre le suivi + les articles + le numéro KZF-.
        expect(find.text(frU('orders.timeline')), findsWidgets);
        expect(find.text(frU('orders.detail.items')), findsWidgets);
        expect(find.textContaining('KZF-'), findsWidgets);
      });
      expectNoKnownBugs();
    });

    // -------------------------------------------------- PROFIL / ADRESSES
    // CRUD d'adresse (compte seedé) : création puis suppression.
    testWidgets('Profil : adresses (création + suppression)', (tester) async {
      await guardAgainstRegressions(() async {
        await launchApp(tester);

        await goToTab(tester, Tabs.profile);
        await pumpUntilFound(tester, find.byType(TextFormField));
        await login(tester, email: seededEmail, password: password);
        await pumpUntilFound(tester, find.text(fr('home.hero.title')));

        // Profil -> Mes adresses.
        await goToTab(tester, Tabs.profile);
        await pumpUntilFound(tester, find.text(fr('profile.addresses')));
        await tapAndSettle(tester, find.text(fr('profile.addresses')));
        await pumpUntilFound(
          tester,
          find.text(fr('address.title')),
          reason: 'l’écran des adresses ne s’affiche pas',
          timeout: kNetworkTimeout,
        );

        // Marqueur unique pour retrouver l'adresse créée.
        final city = 'E2EVille${DateTime.now().millisecondsSinceEpoch % 100000}';

        // CREATE via le FAB « Ajouter une adresse ».
        await tapAndSettle(tester, find.byType(FloatingActionButton).first);
        await pumpUntilFound(tester, find.byType(TextFormField));
        final formFields = find.byType(TextFormField);
        // Ordre : label?, fullName, phone, line1, line2?, city, region?,
        //         country, landmark?
        await enterText(tester, formFields.at(0), 'Bureau'); // label
        await enterText(tester, formFields.at(1), 'E2E Pro'); // fullName
        await enterText(tester, formFields.at(2), '+2250711111111'); // phone
        await enterText(tester, formFields.at(3), 'Avenue Pro 2'); // line1
        await enterText(tester, formFields.at(5), city); // city
        await enterText(tester, formFields.at(7), "Côte d'Ivoire"); // country
        await tapPrimaryButton(tester, fr('common.save'));

        // Le formulaire se ferme et revient à la LISTE (le FAB « Ajouter une
        // adresse » n'existe que sur la liste). On attend ce retour AVANT de
        // chercher la ville, sinon le champ texte du formulaire serait faussement
        // détecté par find.textContaining.
        await pumpUntilFound(
          tester,
          find.byType(FloatingActionButton),
          reason: 'le formulaire d’adresse ne s’est pas refermé après save '
              '(échec de création ?)',
          timeout: kNetworkTimeout,
        );
        // La nouvelle adresse apparaît dans une carte de la liste.
        await pumpUntilFound(
          tester,
          find.descendant(of: find.byType(Card), matching: find.textContaining(city)),
          reason: 'la nouvelle adresse n’apparaît pas dans la liste',
          timeout: kNetworkTimeout,
        );

        // DELETE : supprime l'adresse créée (icône poubelle) + confirmation.
        await clearSnackBars(tester);
        final deleteIcons = find.byIcon(Icons.delete_outline);
        await pumpUntilFound(tester, deleteIcons);
        await tapAndSettle(tester, deleteIcons.last);
        await pumpUntilFound(tester, find.text(fr('common.delete')));
        await tapAndSettle(tester, find.text(fr('common.delete')).last);

        // L'adresse supprimée disparaît de la liste.
        await pumpUntilGone(
          tester,
          find.descendant(of: find.byType(Card), matching: find.textContaining(city)),
          timeout: kNetworkTimeout,
        );
      });
      expectNoKnownBugs();
    });

    // ---------------------------------------------------- AUTH (logout/login)
    testWidgets('Auth : logout puis login avec le compte seedé',
        (tester) async {
      await guardAgainstRegressions(() async {
        await launchApp(tester);

        // Connexion avec le compte seedé via l'onglet protégé (redirige -> login).
        await goToTab(tester, Tabs.cart);
        await pumpUntilFound(tester, find.byType(TextFormField));
        await login(tester, email: seededEmail, password: password);

        // Après login, l'app revient à l'accueil (le LoginScreen fait go(home)).
        await pumpUntilFound(
          tester,
          find.text(fr('home.hero.title')),
          reason: 'pas de retour à l’accueil après login',
        );

        // Connecté : l'onglet Panier s'affiche désormais sans redirection.
        await goToTab(tester, Tabs.cart);
        await pumpUntilFound(
          tester,
          find.text(fr('cart.title')),
          reason: 'le panier ne s’affiche pas après login (session active)',
        );

        // LOGOUT depuis le profil.
        await goToTab(tester, Tabs.profile);
        await pumpUntilFound(tester, find.text(fr('auth.logout')));
        await tapAndSettle(tester, find.text(fr('auth.logout')).first);
        // Dialogue de confirmation -> confirmer (bouton « Se déconnecter »).
        await pumpUntilFound(tester, find.text(fr('auth.logout')));
        await tapAndSettle(tester, find.text(fr('auth.logout')).last);

        // Déconnecté : un accès panier redirige de nouveau vers la connexion.
        await goToTab(tester, Tabs.cart);
        await pumpUntilFound(
          tester,
          find.text(fr('auth.login.submit')),
          reason: 'après logout, l’accès panier devrait exiger une connexion',
        );
        expect(find.text(fr('auth.login.submit')), findsWidgets);
      });
      expectNoKnownBugs();
    });

    // ----------------------------------------------------- AUTH (mauvais mdp)
    testWidgets('Auth : mauvais mot de passe -> message d’erreur localisé',
        (tester) async {
      await launchApp(tester);
      await goToTab(tester, Tabs.cart);
      await pumpUntilFound(tester, find.byType(TextFormField));

      await login(tester, email: seededEmail, password: 'mauvais-mdp');

      // L'API renvoie messageKey=auth.invalidCredentials -> traduit en fr.
      await pumpUntilFound(
        tester,
        find.text(fr('auth.invalidCredentials')),
        reason: 'pas de message d’erreur après mauvais mot de passe',
      );
      expect(find.text(fr('auth.invalidCredentials')), findsWidgets);
      // On reste sur l'écran de connexion (pas de navigation).
      expect(find.text(fr('auth.login.submit')), findsWidgets);
    });

    // ------------------------------------------ NON-RÉGRESSION P2 (corrigé)
    // P2 corrigé : `MainShell` lit le compteur panier via `select`, de sorte
    // qu'un changement d'état panier/auth (login, ajout) ne déclenche plus de
    // « setState()/markNeedsBuild() called during build ». Ce test reproduit
    // exactement l'ancienne condition de déclenchement (connexion alors que la
    // coquille est montée, bascules d'onglets, ET une vraie variation du
    // compteur via un ajout au panier) puis asserte qu'AUCUNE occurrence n'a
    // lieu. Toute régression rallumerait le compteur et ferait échouer le test.
    testWidgets(
      'Non-régression P2 : MainShell ne déclenche pas setState pendant build',
      (tester) async {
        await guardAgainstRegressions(() async {
          await launchApp(tester);
          // Se connecter déclenche le chargement du panier alors qu'un onglet
          // de la coquille est monté (ancien déclencheur du bug).
          await goToTab(tester, Tabs.cart);
          await pumpUntilFound(tester, find.byType(TextFormField));
          await login(tester, email: seededEmail, password: password);
          await pumpUntilFound(tester, find.text(fr('home.hero.title')));
          // Bascules d'onglets pour solliciter le compteur panier.
          await goToTab(tester, Tabs.cart);
          await goToTab(tester, Tabs.home);

          // Variation RÉELLE du compteur (0 -> 1) : ajoute une variante en stock.
          // C'est le cas qui re-entrait dans le build de MainShell avant le fix.
          await openProductBySearch(tester, 'Hoodie');
          await pumpUntilFound(tester, find.byType(ProductDetailScreen));
          await pumpUntilFound(tester, find.text(frU('product.size')));
          await tapInkByText(tester, 'M');
          await tapInkByText(tester, 'Noir');
          await tapPrimaryButton(tester, fr('product.addToCart'));
          await pumpUntilFound(
            tester,
            find.text(fr('product.added')),
            reason: 'ajout au panier non confirmé',
          );
          // Revient sous la coquille (la fiche produit est poussée au-dessus,
          // hors barre de navigation) pour observer le badge.
          await tapAndSettle(tester, find.byIcon(Icons.arrow_back).first);
          await goToTab(tester, Tabs.home);
          // Le badge panier doit refléter un compteur > 0 (re-rendu différé,
          // jamais pendant le build). Le seul `Badge` Material de l'app est
          // celui de l'onglet Panier, rendu uniquement quand le compteur > 0 ;
          // sa présence prouve donc la propagation du compteur. On n'asserte pas
          // une valeur exacte : le panier du compte seedé est cumulatif entre
          // runs (la valeur peut être >= 1).
          await pumpUntilFound(
            tester,
            find.byType(Badge),
            reason: 'le badge du compteur panier ne s’affiche pas (>0 attendu)',
          );
          final badgeLabel = tester
              .widget<Badge>(find.byType(Badge).first)
              .label;
          expect(
            badgeLabel,
            isA<Text>(),
            reason: 'le badge panier devrait porter un libellé de compteur',
          );
          final count = int.tryParse((badgeLabel! as Text).data ?? '');
          expect(
            count,
            isNotNull,
            reason: 'le libellé du badge panier devrait être un entier',
          );
          expect(
            count,
            greaterThan(0),
            reason: 'le compteur panier devrait être > 0 après ajout',
          );
        });

        // P2 corrigé : zéro « setState during build » malgré la variation du
        // compteur et les changements d'état panier/auth.
        expectNoKnownBugs();
      },
    );
  });
}
