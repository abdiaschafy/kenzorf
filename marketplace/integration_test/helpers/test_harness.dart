// Harnais commun aux tests d'intégration KENZORF (parcours client réel).
//
// Démarre l'application complète (`KenzorfApp` dans un `ProviderScope`) contre
// l'API LOCALE passée via `--dart-define=API_BASE_URL`. Aucun mock : on exerce
// le vrai chemin Dio + Riverpod + go_router + parsing des DTOs.
//
// L'app n'expose AUCUNE `Key` de test : on pilote par texte localisé (locale
// par défaut = fr), types de widgets et `Semantics`. Les helpers ci-dessous
// encapsulent l'attente réseau (pump en boucle jusqu'à apparition d'un finder).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenzorf_marketplace/core/l10n/app_strings.dart';
import 'package:kenzorf_marketplace/main.dart';

/// Délai maximal d'attente d'un appel réseau local (large pour absorber la
/// latence du simulateur + API locale).
const Duration kNetworkTimeout = Duration(seconds: 30);

/// Libellé français d'une clé i18n (l'app démarre en fr par défaut).
String fr(String key) => kStringsFr[key] ?? key;

/// Variante MAJUSCULES d'un libellé : de nombreux titres de section sont rendus
/// via `Text(label.toUpperCase())` (ex. `_AttributeLabel`, `_SectionTitle`,
/// titres de `_Card`). Les finders doivent alors cibler la version capitalisée.
String frU(String key) => fr(key).toUpperCase();

/// Compteur des « setState()/markNeedsBuild() called during build » émis par
/// `MainShell` (bug P2 — CORRIGÉ). Désormais asserté **à zéro** via
/// [expectNoKnownBugs].
int shellBuildErrorCount = 0;

/// Compteur des « Missing scheme in uri » émis par `PaymentWebViewScreen`
/// lorsqu'il chargeait un `checkoutUrl` RELATIF (bug P1 — CORRIGÉ). Désormais
/// asserté **à zéro** via [expectNoKnownBugs].
int webViewUriErrorCount = 0;

/// Signature P2 : `MainShell.build` déclenche un `setState/markNeedsBuild`
/// pendant la phase de build (lecture du compteur panier).
bool _isShellBuildError(FlutterErrorDetails details) {
  final text = details.exceptionAsString();
  final stack = details.stack?.toString() ?? '';
  return text.contains('setState() or markNeedsBuild() called during build') &&
      (text.contains('MainShell') || stack.contains('MainShell.build'));
}

/// Signature P1 : `PaymentWebViewScreen.initState` chargeait une URL RELATIVE
/// (sans schéma/hôte) -> `ArgumentError: Missing scheme in uri`.
bool _isWebViewUriError(FlutterErrorDetails details) {
  final text = details.exceptionAsString();
  final stack = details.stack?.toString() ?? '';
  return text.contains('Missing scheme in uri') ||
      (text.contains('Invalid argument') &&
          stack.contains('PaymentWebViewScreen'));
}

/// Exécute [body] en surveillant les deux régressions P1/P2 désormais corrigées
/// (« setState during build » de `MainShell`, « Missing scheme in uri » de
/// `PaymentWebViewScreen`). Toute occurrence est **comptée ET propagée** comme
/// erreur fatale (le test échoue) : ces défauts ne doivent plus jamais survenir.
/// Les compteurs sont remis à zéro à l'entrée pour permettre une assertion
/// explicite `== 0` en fin de scénario (voir [expectNoKnownBugs]).
Future<void> guardAgainstRegressions(Future<void> Function() body) async {
  shellBuildErrorCount = 0;
  webViewUriErrorCount = 0;
  final previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (_isShellBuildError(details)) shellBuildErrorCount++;
    if (_isWebViewUriError(details)) webViewUriErrorCount++;
    // On NE swallow PLUS : l'erreur reste fatale (handler par défaut -> échec).
    (previous ?? FlutterError.presentError)(details);
  };
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
}

/// Assertion explicite : aucun des deux défauts corrigés (P1/P2) n'a été observé
/// pendant le scénario courant. À appeler en fin de chaque scénario enveloppé
/// par [guardAgainstRegressions].
void expectNoKnownBugs() {
  expect(
    shellBuildErrorCount,
    0,
    reason: 'Régression P2 : « setState during build » de MainShell observé '
        '($shellBuildErrorCount). La lecture du compteur panier ne doit jamais '
        'déclencher de rebuild pendant la phase de build.',
  );
  expect(
    webViewUriErrorCount,
    0,
    reason: 'Régression P1 : « Missing scheme in uri » de PaymentWebViewScreen '
        'observé ($webViewUriErrorCount). Le checkoutUrl doit être résolu en '
        'URL absolue avant chargement de la WebView.',
  );
}

/// Démarre l'application réelle après avoir purgé le stockage sécurisé pour
/// garantir un état déconnecté + locale fr déterministe à chaque run.
Future<void> launchApp(WidgetTester tester) async {
  // Purge la session / la préférence de langue persistées d'un run précédent.
  await const FlutterSecureStorage().deleteAll();

  await tester.pumpWidget(const ProviderScope(child: KenzorfApp()));
  // Laisse le bootstrap d'auth se résoudre (splash -> écran).
  await pumpUntilSettled(tester);
}

/// Pompe en boucle jusqu'à ce que [finder] trouve au moins un widget, ou que
/// [timeout] expire. Utile après une action réseau (l'UI se met à jour quand la
/// réponse arrive). Lève une `TestFailure` explicite en cas d'expiration.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = kNetworkTimeout,
  String? reason,
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 120));
    if (finder.evaluate().isNotEmpty) return;
  }
  // Dernière chance après un settle complet.
  await tester.pump(const Duration(milliseconds: 250));
  if (finder.evaluate().isNotEmpty) return;
  // Aide au diagnostic : liste les textes visibles à l'écran au moment du
  // timeout (commenter en exploitation normale).
  // ignore: avoid_print
  print('DEBUG visible texts on timeout: ${_visibleTexts(tester)}');
  throw TestFailure(
    'pumpUntilFound a expiré (${timeout.inSeconds}s) pour: $finder'
    '${reason != null ? '\nRaison: $reason' : ''}',
  );
}

/// Liste (debug) les libellés `Text` actuellement montés, pour comprendre
/// quel écran est affiché quand un finder n'aboutit pas.
List<String> _visibleTexts(WidgetTester tester) {
  final out = <String>[];
  for (final e in find.byType(Text).evaluate()) {
    final w = e.widget;
    if (w is Text && w.data != null && w.data!.trim().isNotEmpty) {
      out.add(w.data!);
    }
  }
  return out.take(40).toList();
}

/// Pompe jusqu'à ce que [finder] disparaisse (utile pour attendre la fin d'un
/// chargement / la fermeture d'un toast), ou que [timeout] expire.
Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 120));
    if (finder.evaluate().isEmpty) return;
  }
}

/// `pumpAndSettle` tolérant : si une animation/poll tourne en continu (ex.
/// indicateur de paiement), `pumpAndSettle` lèverait après son timeout. On
/// retombe alors sur des pumps fixes pour ne pas faire échouer le test.
Future<void> pumpUntilSettled(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 12),
}) async {
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      timeout,
    );
  } on FlutterError {
    // Animation persistante : on pompe un peu pour stabiliser l'écran visible.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }
}

/// Tape sur le premier widget trouvé par [finder] (après s'être assuré qu'il
/// est présent), puis laisse l'UI se stabiliser.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  expect(finder, findsWidgets, reason: 'cible de tap introuvable: $finder');
  await tester.tap(finder.first);
  await pumpUntilSettled(tester);
}

/// Saisit [text] dans le champ [field] et stabilise.
Future<void> enterText(
  WidgetTester tester,
  Finder field,
  String text,
) async {
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 200));
}

/// Tape l'`InkWell` ancêtre du texte [label] (zone tappable réelle d'une
/// pastille / tuile dont le `Text` est centré dans un conteneur plus grand).
/// Plus fiable que taper le `Text` (souvent plus petit que la cible tactile).
Future<void> tapInkByText(WidgetTester tester, String label) async {
  final text = find.text(label);
  await pumpUntilFound(tester, text, reason: 'texte "$label" introuvable');
  final ink = find.ancestor(of: text.first, matching: find.byType(InkWell));
  final target = ink.evaluate().isNotEmpty ? ink.first : text.first;
  await tester.ensureVisible(target);
  await tester.pump(const Duration(milliseconds: 120));
  await tester.tap(target);
  await pumpUntilSettled(tester);
}

/// Lit l'état `onTap` de l'`InkWell` ancêtre du texte [label] : `null` => la
/// cible est désactivée (cas d'une variante en rupture).
bool isInkEnabledByText(WidgetTester tester, String label) {
  final text = find.text(label);
  final ink = find.ancestor(of: text.first, matching: find.byType(InkWell));
  if (ink.evaluate().isEmpty) return false;
  return tester.widget<InkWell>(ink.first).onTap != null;
}

/// Fait défiler le premier `Scrollable` (ou [scrollable]) jusqu'à rendre
/// visible le `Text` [label], dans une liste paresseuse (`ListView`) où les
/// éléments hors écran ne sont pas encore montés. Sans effet si déjà visible.
Future<void> scrollUntilTextVisible(
  WidgetTester tester,
  String label, {
  Finder? scrollable,
  double delta = 250,
  int maxScrolls = 25,
}) async {
  if (find.text(label).evaluate().isNotEmpty) return;
  final view = scrollable ?? find.byType(Scrollable).first;
  try {
    await tester.scrollUntilVisible(
      find.text(label),
      delta,
      scrollable: view,
      maxScrolls: maxScrolls,
    );
  } catch (_) {
    // Repli : quelques drags manuels si scrollUntilVisible n'aboutit pas.
    for (var i = 0; i < 8 && find.text(label).evaluate().isEmpty; i++) {
      await tester.drag(view, Offset(0, -delta));
      await tester.pump(const Duration(milliseconds: 200));
    }
  }
  await tester.pump(const Duration(milliseconds: 200));
}

/// Masque immédiatement tout SnackBar affiché.
///
/// Les SnackBars (ex. « Article ajouté au panier ») sont rendus par le
/// `ScaffoldMessenger` global (au-dessus du navigateur) et recouvrent les barres
/// d'action basses (checkout) — ils intercepteraient alors les taps. On force
/// leur retrait via l'état du messenger plutôt que d'attendre l'expiration.
Future<void> clearSnackBars(WidgetTester tester) async {
  final messengerFinder = find.byType(ScaffoldMessenger);
  if (messengerFinder.evaluate().isNotEmpty) {
    final messenger =
        tester.state<ScaffoldMessengerState>(messengerFinder.first);
    messenger.clearSnackBars();
    await tester.pump(const Duration(milliseconds: 350));
  }
}
