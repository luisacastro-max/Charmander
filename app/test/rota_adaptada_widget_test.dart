// Rota adaptada à forma de circular (pedido do mentor): comparação com a
// rota mais usada, simulação de elevador em manutenção e o atalho
// "Como você vai circular hoje?".
// Cenários BDD: docs/qa/rota-adaptada.feature

import 'package:acessa_plus/app/app.dart';
import 'package:acessa_plus/app/i18n/i18n.dart';
import 'package:acessa_plus/data/repositories/json_repositorios.dart';
import 'package:acessa_plus/data/shopping_data.dart';
import 'package:acessa_plus/domain/rules/rota_adaptada.dart';
import 'package:acessa_plus/domain/rules/rotas.dart';
import 'package:acessa_plus/features/ajuda/ajuda_screen.dart';
import 'package:acessa_plus/features/navegacao/mapa_interativo.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'destino_test.dart' as d;

/// Abre as preferências (primeiro uso: "Começar").
Future<PreferencesController> abrirPreferencias(
  WidgetTester t, {
  Preferences prefs = const Preferences(),
}) async {
  t.view.physicalSize = const Size(1080, 9000);
  t.view.devicePixelRatio = 2.5;
  addTearDown(t.view.reset);
  final dados = await t.runAsync(() => ShoppingData.carregar());
  final ctrl = PreferencesController(prefs);
  await t.pumpWidget(AcessaApp(controller: ctrl, dados: dados));
  await t.pumpAndSettle();
  await t.tap(find.text('Começar'));
  await t.pumpAndSettle();
  return ctrl;
}

const _semEscadas = Preferences(avoidStairs: true);

void main() {
  group('textos da comparação (regras puras)', () {
    late MotorRotas motor;
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      motor = MotorRotas(
        await JsonCatalogoRepository().pontos(),
        await JsonPercursoRepository().trechos(),
      );
    });

    test('Praça de Alimentação: evita escada rolante, usa elevador', () {
      final c = motor.compararViagem('ENT_P', [
        'PA',
      ], const CriteriosRota(semEscadas: true)) as ComparacaoViagem;
      expect(c.mudou, isTrue);
      expect(c.nomesEvitados, ['escada rolante']);
      expect(c.nomesSubstitutos, ['elevador']);
      expect(meiosDeTrocaDePiso(c.principal), ['escada rolante']);
      expect(meiosDeTrocaDePiso(c.adaptada), ['elevador']);
      expect(c.extraM, c.adaptada.distanciaM - c.principal.distanciaM);
      expect(c.extraM, greaterThan(0));
    });
  });

  testWidgets('Sem escadas até a Praça: cartão "Rota adaptada para você" '
      'com o que evita, o que usa e o acréscimo', (t) async {
    await d.abrirDestino(t, prefs: _semEscadas);
    await d.tocar(t, find.text('Praça de Alimentação'));

    expect(find.text('Rota adaptada para você'), findsOneWidget);
    expect(find.text('Rota mais usada'), findsOneWidget);
    expect(find.text('Para você'), findsOneWidget);
    expect(find.text('Evita: escada rolante'), findsOneWidget);
    expect(find.text('Usa: elevador'), findsOneWidget);
    expect(find.text('Desvio: +34 m · +1 min'), findsOneWidget);
    expect(find.text('148 m · 3 min'), findsOneWidget);
    expect(find.text('182 m · 4 min'), findsOneWidget);
    expect(find.text('Troca de piso: escada rolante'), findsOneWidget);
    expect(find.text('Troca de piso: elevador'), findsOneWidget);

    // Leitor de tela: uma frase completa, sem depender de cor ou ícone.
    final sem = t.getSemantics(
      find
          .ancestor(
            of: find.text('Rota adaptada para você'),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(sem.label, contains('Evita: escada rolante.'));
    expect(sem.label, contains('Usa: elevador.'));
    expect(sem.label, contains('34 metros e 1 min a mais.'));
  });

  testWidgets('Sem restrição: não há comparação nem "Evita"', (t) async {
    await d.abrirDestino(t);
    await d.tocar(t, find.text('Praça de Alimentação'));
    expect(find.text('Tem degraus'), findsOneWidget);
    expect(find.text('Rota adaptada para você'), findsNothing);
    expect(find.textContaining('Evita:'), findsNothing);
    expect(find.textContaining('Desvio:'), findsNothing);
    // A rota pela escada rolante não usa elevador: sem simulação.
    expect(find.text('Simular elevador em manutenção'), findsNothing);
  });

  testWidgets('Simular elevador em manutenção: sem rota, preferência mantida, '
      'Pedir ajuda abre o Ajuda+; encerrar devolve a rota', (t) async {
    final ctrl = await d.abrirDestino(t, prefs: _semEscadas);
    await d.tocar(t, find.text('Praça de Alimentação'));

    await d.tocar(t, find.text('Simular elevador em manutenção'));
    expect(
      find.textContaining('Simulação: elevador em manutenção'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Não há caminho sem escadas até Praça de Alimentação.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('continua ativa'), findsOneWidget);
    expect(ctrl.prefs.avoidStairs, isTrue);
    // Nenhuma rota com escada é oferecida como "adaptada".
    expect(find.text('Rota adaptada para você'), findsNothing);
    expect(find.text('Iniciar navegação'), findsNothing);
    expect(find.text('Escolher outro destino'), findsOneWidget);
    expect(find.text('Revisar minhas preferências'), findsOneWidget);

    await d.tocar(t, find.text('Pedir ajuda'));
    expect(find.byType(AjudaScreen), findsOneWidget);
    t.state<NavigatorState>(find.byType(Navigator).first).pop();
    await t.pumpAndSettle();

    // Encerrar a simulação: a rota pelo elevador volta.
    await d.tocar(t, find.text('Simular elevador em manutenção'));
    expect(
      find.textContaining('Simulação: elevador em manutenção'),
      findsNothing,
    );
    expect(find.text('Usa elevador'), findsOneWidget);
    expect(find.text('Rota adaptada para você'), findsOneWidget);
    expect(ctrl.prefs.avoidStairs, isTrue);
  });

  testWidgets('Mapa da navegação mostra a rota mais usada tracejada, com '
      'legenda em texto', (t) async {
    await d.abrirDestino(t, prefs: _semEscadas);
    await d.tocar(t, find.text('Praça de Alimentação'));
    await d.tocar(t, find.text('Iniciar navegação'));
    final mapa = t.widget<MapaInterativo>(find.byType(MapaInterativo));
    expect(mapa.rotaMaisUsada, isNotNull);
    expect(find.text('Rota mais usada (tracejada)'), findsOneWidget);
  });

  testWidgets('Atalho "Sobre rodas" liga os dois recursos, sem salvar a '
      'escolha nem mexer na comunicação', (t) async {
    final ctrl = await abrirPreferencias(
      t,
      prefs: const Preferences(textCommunication: true),
    );
    expect(find.text('Como você vai circular hoje?'), findsOneWidget);
    await d.tocar(t, find.text('Sobre rodas'));
    expect(ctrl.prefs.avoidStairs, isTrue);
    expect(ctrl.prefs.preferElevators, isTrue);
    expect(ctrl.prefs.textCommunication, isTrue);
    expect(ctrl.prefs.quickMessages, isFalse);
    expect(find.textContaining('Ativamos "Rotas sem escadas"'), findsOneWidget);

    // Os recursos continuam independentes.
    await d.tocar(t, find.text('Preferência por elevadores'));
    expect(ctrl.prefs.preferElevators, isFalse);
    expect(ctrl.prefs.avoidStairs, isTrue);

    // Nada da escolha vai para o que é salvo.
    final salvo = ctrl.prefs.toMap().toString().toLowerCase();
    expect(salvo, isNot(contains('rodas')));
    expect(salvo, isNot(contains('apoio')));
  });

  testWidgets('Atalho "Com apoio" liga os mesmos recursos', (t) async {
    final ctrl = await abrirPreferencias(t);
    await d.tocar(t, find.text('Com apoio'));
    expect(ctrl.prefs.avoidStairs, isTrue);
    expect(ctrl.prefs.preferElevators, isTrue);
  });

  test('textos novos têm tradução em inglês e espanhol', () {
    const textos = [
      'Rota adaptada para você',
      'Rota mais usada',
      'Para você',
      'Evita:',
      'Usa:',
      'Desvio:',
      'Troca de piso:',
      'escada rolante',
      'elevador',
      'Simular elevador em manutenção',
      'Simulação: elevador em manutenção. Rota recalculada.',
      'Rota mais usada: 148 metros, cerca de 3 minutos.',
      'Para você: 182 metros, cerca de 4 minutos.',
      '34 metros e 1 min a mais.',
      'Como você vai circular hoje?',
      'Sobre rodas',
      'Com apoio',
      'cadeira de rodas, carrinho de bebê, mala',
      'andador, muletas, bengala',
      'Rota mais usada (tracejada)',
    ];
    // Em espanhol, alguns ficam iguais ao português.
    const iguaisEmEs = {'Evita:', 'Usa:'};
    for (final idioma in [AppLanguage.en, AppLanguage.es]) {
      final faltando = [
        for (final s in textos)
          if (traduzir(s, idioma) == s &&
              !(idioma == AppLanguage.es && iguaisEmEs.contains(s)))
            s,
      ];
      expect(faltando, isEmpty, reason: '${idioma.name}: $faltando');
    }
  });
}
