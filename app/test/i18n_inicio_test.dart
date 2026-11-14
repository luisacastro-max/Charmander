// Idioma nas Boas-vindas (T01) e nas Preferências (T02): os textos seguem
// o idioma escolhido e a voz confirma as escolhas quando o áudio está ligado.

import 'package:acessa_plus/app/app.dart';
import 'package:acessa_plus/core/voz/voz.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<PreferencesController> abrirApp(
  WidgetTester t, [
  Preferences prefs = const Preferences(),
]) async {
  t.view.physicalSize = const Size(1080, 9000);
  t.view.devicePixelRatio = 2.5;
  addTearDown(t.view.reset);
  final ctrl = PreferencesController(prefs);
  await t.pumpWidget(AcessaApp(controller: ctrl));
  await t.pumpAndSettle();
  return ctrl;
}

Future<void> tocar(WidgetTester t, Finder f) async {
  await t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).last);
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  setUp(Voz.historico.clear);

  testWidgets('Boas-vindas em inglês', (t) async {
    await abrirApp(t, const Preferences(language: AppLanguage.en));
    expect(find.bySemanticsLabel('Acessa plus'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Accessibility that connects people.'),
      findsOneWidget,
    );
    expect(find.text('connects'), findsOneWidget);
    for (final p in ['Universal Communication', 'Live Navigation', 'Ajuda+']) {
      expect(find.text(p), findsOneWidget);
    }
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Set up later'), findsOneWidget);
    expect(find.textContaining('simulated'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('by elevator')), findsOneWidget);
    expect(find.text('Começar'), findsNothing);
  });

  testWidgets('Boas-vindas em espanhol', (t) async {
    await abrirApp(t, const Preferences(language: AppLanguage.es));
    expect(find.text('Comunicación Universal'), findsOneWidget);
    expect(find.text('Navegación Viva'), findsOneWidget);
    expect(find.text('Empezar'), findsOneWidget);
  });

  testWidgets('Trocar o idioma nas preferências muda a tela na hora', (
    t,
  ) async {
    final ctrl = await abrirApp(t);
    await t.tap(find.text('Começar'));
    await t.pumpAndSettle();
    expect(find.text('Minha acessibilidade'), findsOneWidget);
    expect(
      find.text('Muda os textos do app, a voz e as frases prontas.'),
      findsOneWidget,
    );

    await tocar(t, find.text('English'));
    expect(ctrl.prefs.language, AppLanguage.en);
    await t.scrollUntilVisible(
      find.text('My accessibility'),
      -300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('My accessibility'), findsOneWidget);
    expect(find.text('Larger text'), findsOneWidget);
    expect(find.bySemanticsLabel('No features on'), findsOneWidget);
    expect(find.text('Minha acessibilidade'), findsNothing);
    // Sem áudio ligado, a troca não fala nada.
    expect(Voz.historico, isEmpty);

    await tocar(t, find.text('Español'));
    expect(find.text('Texto ampliado'), findsOneWidget);
    expect(find.text('Rutas sin escaleras'), findsOneWidget);

    await tocar(t, find.text('Português'));
    expect(find.text('Rotas sem escadas'), findsOneWidget);
  });

  testWidgets('Ligar o áudio confirma em voz, no idioma escolhido', (t) async {
    final ctrl = await abrirApp(t, const Preferences(language: AppLanguage.en));
    await t.tap(find.text('Start'));
    await t.pumpAndSettle();
    await tocar(t, find.text('Audio guidance'));
    expect(ctrl.prefs.audioGuidance, isTrue);
    expect(Voz.historico, contains('Audio guidance on.'));

    // Desligar não fala.
    Voz.historico.clear();
    await tocar(t, find.text('Audio guidance'));
    expect(ctrl.prefs.audioGuidance, isFalse);
    expect(Voz.historico, isEmpty);
  });

  testWidgets('Com áudio ligado, trocar o idioma confirma no novo idioma', (
    t,
  ) async {
    await abrirApp(t, const Preferences(audioGuidance: true));
    await t.tap(find.text('Começar'));
    await t.pumpAndSettle();
    await tocar(t, find.text('Español'));
    expect(Voz.historico, contains('Idioma: Español.'));
    await tocar(t, find.text('English'));
    expect(Voz.historico, contains('Language: English.'));
  });
}
