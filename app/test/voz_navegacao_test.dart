// Orientações por áudio na navegação: a voz fala cada instrução, a parada
// e a chegada, no idioma do visitante, e só com a preferência ligada.

import 'package:acessa_plus/app/app.dart';
import 'package:acessa_plus/app/i18n/i18n.dart';
import 'package:acessa_plus/core/voz/voz.dart';
import 'package:acessa_plus/data/shopping_data.dart';
import 'package:acessa_plus/domain/rules/rotas.dart';
import 'package:acessa_plus/domain/rules/viagem.dart';
import 'package:acessa_plus/features/navegacao/navegacao_screen.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'navegacao_test.dart' show abrirDestino, simularAte, tocar;

/// Mesma rota de `montarRotaComParada`, com preferências escolhidas.
Future<void> iniciarRotaComParada(WidgetTester t, Preferences prefs) async {
  await abrirDestino(t, prefs: prefs);
  await tocar(t, find.text('Elevadores — Térreo'));
  await tocar(t, find.text('Adicionar outra parada'));
  await tocar(t, find.text('Praça de Alimentação'));
  await tocar(t, find.text('Iniciar navegação'));
}

/// Abre a navegação direto (sem passar pelas telas de boas-vindas e
/// destino, que têm os próprios textos traduzidos).
Future<ShoppingData> abrirNavegacao(WidgetTester t, Preferences prefs) async {
  t.view.physicalSize = const Size(1080, 9000);
  t.view.devicePixelRatio = 2.5;
  addTearDown(t.view.reset);
  final dados = (await t.runAsync(() => ShoppingData.carregar()))!;
  await t.pumpWidget(
    AcessaApp(controller: PreferencesController(prefs), dados: dados),
  );
  await t.pumpAndSettle();
  final viagem = dados.motor.calcularViagem('ENT_P', [
    'ELV_T',
    'PA',
  ], const CriteriosRota(semEscadas: true)) as Viagem;
  t
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(
        MaterialPageRoute<void>(
          builder: (_) => NavegacaoScreen(viagem: viagem, dados: dados),
        ),
      );
  await t.pumpAndSettle();
  return dados;
}

void main() {
  setUp(Voz.historico.clear);

  testWidgets('Com áudio ligado, fala a instrução inicial, cada novo passo, '
      'a parada e a chegada', (t) async {
    await iniciarRotaComParada(
      t,
      const Preferences(avoidStairs: true, audioGuidance: true),
    );
    // Primeira instrução, falada assim que a navegação abre.
    expect(Voz.historico, isNotEmpty);
    expect(Voz.historico.last, startsWith('Siga '));
    final primeira = Voz.historico.last;
    final n = Voz.historico.length;

    // Rebuild (zoom no mapa) não fala de novo.
    await tocar(t, find.byTooltip('Aproximar o mapa'));
    expect(Voz.historico.length, n);

    // "Repetir instrução" fala de novo a mesma orientação.
    await tocar(t, find.text('Repetir instrução'));
    expect(Voz.historico.length, n + 1);
    expect(Voz.historico.last, primeira);

    // Próximo passo após "Simular chegada".
    await tocar(t, find.textContaining('Simular chegada'));
    expect(Voz.historico.length, greaterThan(n + 1));

    await simularAte(t, find.text('Você chegou à parada 1'));
    expect(
      Voz.historico.last,
      startsWith('Você chegou à parada 1: Elevadores — Térreo.'),
    );

    await tocar(t, find.text('Seguir para Praça de Alimentação'));
    expect(Voz.historico.last, contains('Pegue o elevador até o 2º piso.'));

    await simularAte(t, find.text('Você chegou!'));
    expect(
      Voz.historico.last,
      'Você chegou! Você está em Praça de Alimentação, 2º piso.',
    );
    // Ao sair do elevador, avisa a troca de piso.
    expect(
      Voz.historico.any((f) => f.startsWith('Você chegou ao 2º piso.')),
      isTrue,
    );
  });

  testWidgets('Com áudio desligado, nada é falado e não há "Repetir"', (
    t,
  ) async {
    await iniciarRotaComParada(t, const Preferences(avoidStairs: true));
    expect(find.text('Repetir instrução'), findsNothing);
    await simularAte(t, find.text('Você chegou à parada 1'));
    await tocar(t, find.text('Seguir para Praça de Alimentação'));
    await simularAte(t, find.text('Você chegou!'));
    expect(Voz.historico, isEmpty);
  });

  testWidgets('Em inglês, a instrução falada e o cartão ficam em inglês', (
    t,
  ) async {
    await abrirNavegacao(
      t,
      const Preferences(
        avoidStairs: true,
        audioGuidance: true,
        language: AppLanguage.en,
      ),
    );
    expect(Voz.historico, isNotEmpty);
    final falada = Voz.historico.last;
    expect(falada, startsWith('Walk '));
    expect(falada, isNot(contains('Siga')));
    // O cartão mostra a mesma instrução em inglês.
    expect(find.textContaining(RegExp(r'^Walk \d+ meters to ')), findsWidgets);
    expect(find.text('Repeat instruction'), findsOneWidget);
    expect(find.textContaining('Simulate arrival'), findsOneWidget);

    // Tocar no cartão fala de novo.
    final n = Voz.historico.length;
    await t.tap(find.textContaining(RegExp(r'^Walk \d+ meters to ')).first);
    await t.pump();
    expect(Voz.historico.length, n + 1);

    // Segue até o elevador: instrução em inglês com o piso traduzido.
    for (
      var i = 0;
      i < 20 && find.text('You reached stop 1').evaluate().isEmpty;
      i++
    ) {
      await tocar(t, find.textContaining('Simulate arrival'));
    }
    expect(Voz.historico.last, startsWith('You reached stop 1:'));
    await tocar(t, find.text('Continue to Praça de Alimentação'));
    expect(Voz.historico.last, contains('Take the elevator to the 2nd floor.'));
    expect(find.text('Take the elevator to the 2nd floor.'), findsOneWidget);
  });

  testWidgets('Mensagens rápidas aparecem na navegação só com a preferência', (
    t,
  ) async {
    await abrirNavegacao(t, const Preferences(quickMessages: true));
    expect(find.text('Mensagens rápidas'), findsOneWidget);
  });

  testWidgets('Sem a preferência, não há botão de mensagens rápidas', (
    t,
  ) async {
    await abrirNavegacao(t, const Preferences());
    expect(find.text('Mensagens rápidas'), findsNothing);
  });

  test('traduz as instruções geradas pelo motor de rotas', () {
    expect(
      traduzir('Siga 30 metros até o Corredor Oeste.', AppLanguage.en),
      'Walk 30 meters to the Corredor Oeste.',
    );
    expect(
      traduzir(
        'Use a escada até o Mezanino. Atenção: trecho com degraus.',
        AppLanguage.es,
      ),
      'Usa la escalera hasta Entrepiso. Atención: tramo con escalones.',
    );
    expect(
      traduzir(
        'Siga 12 metros até Livraria Página. Atenção: trecho com degraus. '
        'Trecho com mais movimento de pessoas.',
        AppLanguage.en,
      ),
      'Walk 12 meters to Livraria Página. Caution: this stretch has steps. '
      'This stretch is busier.',
    );
    expect(
      traduzir('Seta à direita no mapa.', AppLanguage.en),
      'Arrow to the right on the map.',
    );
  });
}
