// Testes da Etapa 1 — Boas-vindas (T01) e Preferências (T02).
// Cenários BDD correspondentes: docs/qa/etapa-1-preferencias.feature

import 'package:acessa_plus/app/app.dart';
import 'package:acessa_plus/app/theme/app_theme.dart';
import 'package:acessa_plus/app/theme/tokens.dart';

import 'dart:ui' show Tristate;

import 'package:acessa_plus/features/welcome_preferences/preferences.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences_scope.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<PreferencesController> abrirApp(
  WidgetTester t, {
  bool reduzirMovimento = false,
}) async {
  t.view.physicalSize = const Size(1080, 9000);
  t.view.devicePixelRatio = 2.5;
  addTearDown(t.view.reset);
  final ctrl = PreferencesController();
  await t.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduzirMovimento),
      child: AcessaApp(controller: ctrl),
    ),
  );
  await t.pumpAndSettle();
  return ctrl;
}

Future<void> irParaPreferencias(WidgetTester t) async {
  await t.tap(find.text('Começar'));
  await t.pumpAndSettle();
}

Future<void> tocar(WidgetTester t, String titulo) async {
  final f = find.text(titulo);
  await t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).last);
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  testWidgets('RF01: boas-vindas apresenta nome, proposta e três pilares', (
    t,
  ) async {
    await abrirApp(t);
    expect(find.bySemanticsLabel('Acessa mais'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Acessibilidade que conecta pessoas.'),
      findsOneWidget,
    );
    for (final p in ['Comunicação Universal', 'Navegação Viva', 'Ajuda+']) {
      expect(find.text(p), findsOneWidget);
    }
    expect(find.textContaining('simulados'), findsOneWidget);
  });

  testWidgets('Mapa vivo tem descrição em texto para leitor de tela (RNF04)', (
    t,
  ) async {
    await abrirApp(t);
    expect(
      find.bySemanticsLabel(RegExp('desvia pelo elevador')),
      findsOneWidget,
    );
  });

  testWidgets('Título inteiro em tela estreita (360 dp), sem quebrar palavra', (
    t,
  ) async {
    t.view.physicalSize = const Size(360 * 3, 5000);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(AcessaApp(controller: PreferencesController()));
    await t.pumpAndSettle();
    expect(find.text('Acessibilidade'), findsOneWidget);
    expect(find.text('conecta'), findsOneWidget);
    expect(t.getSize(find.text('conecta')).width, greaterThan(0));
    expect(t.takeException(), isNull);
  });

  testWidgets('Prévia ao vivo reflete as preferências', (t) async {
    await abrirApp(t);
    await irParaPreferencias(t);
    expect(find.text('Rota mais curta'), findsOneWidget);
    await tocar(t, 'Rotas sem escadas');
    expect(find.text('Sem escadas'), findsOneWidget);
    expect(find.text('Rota mais curta'), findsNothing);
  });

  testWidgets('RN01: preferências não pedem deficiência nem diagnóstico', (
    t,
  ) async {
    await abrirApp(t);
    await irParaPreferencias(t);
    expect(find.textContaining('Não é preciso declarar'), findsOneWidget);
    expect(find.textContaining('diagnóstico'), findsNothing);
  });

  testWidgets('Preferências começam desativadas', (t) async {
    final ctrl = await abrirApp(t);
    expect(ctrl.prefs.activeCount, 0);
    await irParaPreferencias(t);
    expect(find.bySemanticsLabel('Nenhum recurso ativo'), findsOneWidget);
  });

  testWidgets(
    'RNF04: estado do interruptor aparece em texto e para leitor de tela',
    (t) async {
      final ctrl = await abrirApp(t);
      await irParaPreferencias(t);
      await tocar(t, 'Texto ampliado');
      expect(ctrl.prefs.largeText, isTrue);
      expect(find.text('Ativado'), findsOneWidget);
      expect(find.bySemanticsLabel('1 recurso ativo'), findsOneWidget);
      final node = t.getSemantics(find.bySemanticsLabel('Texto ampliado'));
      expect(node.flagsCollection.isToggled, Tristate.isTrue);
    },
  );

  testWidgets('Texto ampliado aumenta a escala do texto em todo o app', (
    t,
  ) async {
    await abrirApp(t);
    await irParaPreferencias(t);
    final ctx = t.element(find.text('Minha acessibilidade'));
    expect(MediaQuery.textScalerOf(ctx).scale(10), closeTo(10, .01));
    await tocar(t, 'Texto ampliado');
    final ctx2 = t.element(find.text('Minha acessibilidade'));
    expect(MediaQuery.textScalerOf(ctx2).scale(10), closeTo(13, .01));
  });

  testWidgets('Alto contraste troca o tema na hora', (t) async {
    await abrirApp(t);
    await irParaPreferencias(t);
    await tocar(t, 'Alto contraste');
    final ctx = t.element(find.text('Alto contraste'));
    expect(
      AcessaTheme.of(ctx).colors.background,
      AcessaColors.highContrast.background,
    );
  });

  testWidgets('RN02: comunicação e mobilidade são independentes', (t) async {
    final ctrl = await abrirApp(t);
    await irParaPreferencias(t);
    await tocar(t, 'Comunicação por texto');
    expect(ctrl.prefs.textCommunication, isTrue);
    expect(ctrl.prefs.avoidStairs, isFalse);
    expect(ctrl.prefs.preferElevators, isFalse);
    await tocar(t, 'Rotas sem escadas');
    expect(ctrl.prefs.avoidStairs, isTrue);
    expect(ctrl.prefs.textCommunication, isTrue);
    expect(ctrl.prefs.preferElevators, isFalse);
  });

  testWidgets('RF44/CA14: apagar preferências pede confirmação e limpa o '
      'que foi salvo', (t) async {
    t.view.physicalSize = const Size(1080, 9000);
    t.view.devicePixelRatio = 2.5;
    addTearDown(t.view.reset);
    final store = MemoryPreferencesStore();
    final ctrl = PreferencesController(const Preferences(), store);
    await t.pumpWidget(AcessaApp(controller: ctrl));
    await t.pumpAndSettle();
    await irParaPreferencias(t);
    await tocar(t, 'Alto contraste');
    await tocar(t, 'Rotas sem escadas');
    expect((await store.load()).activeCount, 2, reason: 'salvo ao mudar');

    // Cancelar não apaga nada.
    await tocar(t, 'Apagar minhas preferências');
    expect(find.text('Apagar suas preferências?'), findsOneWidget);
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(ctrl.prefs.activeCount, 2);

    // Confirmar apaga e avisa.
    await tocar(t, 'Apagar minhas preferências');
    await t.tap(find.text('Apagar'));
    await t.pumpAndSettle();
    expect(ctrl.prefs.activeCount, 0);
    expect((await store.load()).activeCount, 0);
    expect(find.text('Preferências apagadas deste aparelho.'), findsOneWidget);
  });

  testWidgets('Movimento reduzido do sistema: telas aparecem sem animação', (
    t,
  ) async {
    await abrirApp(t, reduzirMovimento: true);
    // Sem animação, um único quadro já mostra tudo opaco.
    await t.tap(find.text('Começar'));
    await t.pump();
    await t.pump();
    final opacidades = t
        .widgetList<Opacity>(
          find.descendant(
            of: find.byType(Scaffold).last,
            matching: find.byType(Opacity),
          ),
        )
        .map((o) => o.opacity);
    expect(opacidades.every((o) => o == 1), isTrue);
  });

  testWidgets('Alvos de toque têm pelo menos 48 dp', (t) async {
    await abrirApp(t);
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await irParaPreferencias(t);
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
  });

  testWidgets('Controles têm rótulo para leitor de tela', (t) async {
    await abrirApp(t);
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    await irParaPreferencias(t);
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
  });

  testWidgets('Contraste de texto (padrão e alto contraste)', (t) async {
    await abrirApp(t);
    await irParaPreferencias(t);
    await expectLater(t, meetsGuideline(textContrastGuideline));
    await tocar(t, 'Alto contraste');
    await t.scrollUntilVisible(
      find.text('Minha acessibilidade'),
      -300,
      scrollable: find.byType(Scrollable).last,
    );
    await expectLater(t, meetsGuideline(textContrastGuideline));
  });
}
